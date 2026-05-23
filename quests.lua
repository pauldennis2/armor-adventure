-- Quest: Massive Lightning Collector

local MLC_NAME           = "massive-lightning-collector"
local MLC_THRESHOLD      = 1000e9      -- joules; matches buffer_capacity in entity prototype
local MLC_DRAIN_RATE     = 5e9         -- watts; 5 GW = 5 GJ/s
local MLC_DRAIN_PER_TICK = MLC_DRAIN_RATE / 60  -- joules per tick

-- Drain the cached entity every tick — O(1), no surface scan.
script.on_nth_tick(1, function()
    local entity = storage.mlc_entity
    if not entity or not entity.valid then return end

    if entity.energy >= MLC_THRESHOLD then
        local pos = entity.position
        entity.surface.spill_item_stack{
            position     = {
                x = pos.x + math.random(-4, 4),
                y = pos.y + math.random(-4, 4),
            },
            stack        = {name = "charged-lightning-gem", count = 1},
            enable_looted = true,
        }
        entity.energy = 0
        return
    end

    entity.energy = math.max(0, entity.energy - MLC_DRAIN_PER_TICK)
end)

-- Slow scan to (re)discover the entity every 5s.
-- Handles existing saves and cases where the fast cache is stale.
script.on_nth_tick(300, function()
    if storage.mlc_entity and storage.mlc_entity.valid then return end
    storage.mlc_entity = nil
    for _, surface in pairs(game.surfaces) do
        local found = surface.find_entities_filtered({name = MLC_NAME, limit = 1})
        if found[1] then storage.mlc_entity = found[1]; return end
    end
end)

-- Quest: Mind Control Rocket
-- When the projectile hits an enemy entity, reassign its force to the player's.

-- Personal Tesla Turret: quality-scaled damage.
-- The beam prototypes deal 0 damage; script applies the real amount based on equipment quality.

local TESLA_PRIMARY_DAMAGE = {
    normal    = 25,
    uncommon  = 75,
    rare      = 150,
    epic      = 225,
    legendary = 400,
}
local TESLA_CHAIN_DAMAGE = {
    normal    = 2,
    uncommon  = 5,
    rare      = 15,
    epic      = 25,
    legendary = 75,
}

-- Returns (player, quality_name) for whoever currently has the tesla turret equipped.
-- Tries event.cause and event.source_entity first (one of these is the player character for
-- the primary hit; chain hits may route differently so we fall back to a full player scan).
local function get_tesla_player_and_quality(event)
    local function check(player)
        if not (player and player.character and player.character.valid) then return end
        local inv = player.get_inventory(defines.inventory.character_armor)
        if not inv then return end
        local item = inv[1]
        if not (item and item.valid_for_read and item.grid) then return end
        for _, eq in ipairs(item.grid.equipment) do
            if eq.name == "personal-tesla-turret" then return player, eq.quality.name end
        end
    end
    local p, q
    if event.cause and event.cause.valid and event.cause.type == "character" then
        p, q = check(event.cause.player)
        if p then return p, q end
    end
    if event.source_entity and event.source_entity.valid and event.source_entity.type == "character" then
        p, q = check(event.source_entity.player)
        if p then return p, q end
    end
    for _, player in pairs(game.connected_players) do
        p, q = check(player)
        if p then return p, q end
    end
end

script.on_event(defines.events.on_script_trigger_effect, function(event)
    local id = event.effect_id

    if id == "mind-control-hit" then
        local target = event.target_entity
        if not target or not target.valid then return end
        if target.force.name ~= "enemy" then return end
        target.force = "player"
        if target.commandable then
            target.commandable.set_command{type = defines.command.wander, distraction = defines.distraction.none}
        end
        storage.mind_controlled = storage.mind_controlled or {}
        storage.mind_controlled[target.unit_number] = target
        rendering.draw_text{
            text          = "★ Mind Controlled",
            surface       = target.surface,
            target        = target,
            target_offset = {0, -2.5},
            color         = {r = 0.7, g = 0.2, b = 1.0},
            scale         = 1.2,
            alignment     = "center",
        }

    elseif id == "personal-tesla-turret-hit" or id == "personal-tesla-turret-chain-hit" then
        local target = event.target_entity
        if not (target and target.valid) then return end
        local player, quality = get_tesla_player_and_quality(event)
        if not player then return end
        quality = quality or "normal"
        local dmg_table = (id == "personal-tesla-turret-hit") and TESLA_PRIMARY_DAMAGE or TESLA_CHAIN_DAMAGE
        target.damage(dmg_table[quality] or dmg_table.normal, player.force, "electric", player.character)
    end
end)

-- Harvester

local HARVESTER_RANGE = 10   -- tiles; how close a mind-controlled entity must be to get consumed
local HP_PER_PART     = 1000 -- enemy HP required to produce one enemy-biomass item

local HARVESTER_FILTER = {{filter = "name", name = "harvester"}}

local function register_harvester(entity)
    storage.harvesters    = storage.harvesters    or {}
    storage.harvester_hp  = storage.harvester_hp  or {}
    local uid = entity.unit_number
    storage.harvesters[uid]   = entity
    storage.harvester_hp[uid] = storage.harvester_hp[uid] or 0
    entity.set_recipe("gleba-parts-from-biomass")
end

local function unregister_harvester(entity)
    if not storage.harvesters then return end
    local uid = entity.unit_number
    storage.harvesters[uid]  = nil
    if storage.harvester_hp then storage.harvester_hp[uid] = nil end
end

local function on_harvester_built(event) register_harvester(event.entity) end
local function on_harvester_removed(event) unregister_harvester(event.entity) end

script.on_event(defines.events.on_built_entity,         on_harvester_built,   HARVESTER_FILTER)
script.on_event(defines.events.on_robot_built_entity,   on_harvester_built,   HARVESTER_FILTER)
script.on_event(defines.events.script_raised_built,     on_harvester_built,   HARVESTER_FILTER)

script.on_event(defines.events.on_entity_died,          on_harvester_removed, HARVESTER_FILTER)
script.on_event(defines.events.on_player_mined_entity,  on_harvester_removed, HARVESTER_FILTER)
script.on_event(defines.events.on_robot_mined_entity,   on_harvester_removed, HARVESTER_FILTER)
script.on_event(defines.events.script_raised_destroy,   on_harvester_removed, HARVESTER_FILTER)

-- Combined tick: harvest nearby mind-controlled entities, then refresh follow commands.
script.on_nth_tick(60, function()
    local mc = storage.mind_controlled

    -- Harvest pass
    local harvesters = storage.harvesters
    if harvesters and mc then
        for h_uid, harvester in pairs(harvesters) do
            if not harvester.valid then
                harvesters[h_uid] = nil
                if storage.harvester_hp then storage.harvester_hp[h_uid] = nil end
            elseif harvester.status == defines.entity_status.no_power
                or harvester.status == defines.entity_status.low_power then
                -- unpowered: don't consume enemies
            else
                local hx, hy = harvester.position.x, harvester.position.y
                local r2     = HARVESTER_RANGE * HARVESTER_RANGE
                for m_uid, mc_entity in pairs(mc) do
                    if mc_entity.valid and mc_entity.surface == harvester.surface then
                        local dx = mc_entity.position.x - hx
                        local dy = mc_entity.position.y - hy
                        if dx*dx + dy*dy <= r2 then
                            local hp = mc_entity.health
                            mc_entity.die()
                            mc[m_uid] = nil
                            storage.harvester_hp[h_uid] = (storage.harvester_hp[h_uid] or 0) + hp
                            local biomass = math.floor(storage.harvester_hp[h_uid] / HP_PER_PART)
                            if biomass > 0 then
                                storage.harvester_hp[h_uid] = storage.harvester_hp[h_uid] % HP_PER_PART
                                local inv = harvester.get_inventory(defines.inventory.assembling_machine_input)
                                if inv then inv.insert({name = "enemy-biomass", count = biomass}) end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Follow pass
    if not mc then return end
    for uid, entity in pairs(mc) do
        if not entity.valid then
            mc[uid] = nil
        else
            local nearest, dist2 = nil, math.huge
            for _, player in pairs(game.players) do
                if player.character and player.surface == entity.surface then
                    local dx = player.position.x - entity.position.x
                    local dy = player.position.y - entity.position.y
                    local d  = dx*dx + dy*dy
                    if d < dist2 then dist2 = d; nearest = player end
                end
            end
            if nearest and entity.commandable then
                entity.commandable.set_command{
                    type        = defines.command.go_to_location,
                    destination = nearest.position,
                    distraction = defines.distraction.by_enemy,
                }
            end
        end
    end

    -- Personal Fridge: add 30 ticks every 60 ticks = 50% slower spoilage while
    -- wearing mech-armor-mk2 and personal-fridge is researched.
    for _, player in pairs(game.players) do
        if not player.character then goto continue end
        if not player.force.technologies["personal-fridge"].researched then goto continue end
        local armor_inv = player.get_inventory(defines.inventory.character_armor)
        if not armor_inv or not armor_inv[1].valid_for_read then goto continue end
        if armor_inv[1].name ~= "mech-armor-mk2" then goto continue end
        local inv = player.get_main_inventory()
        if inv then
            for i = 1, #inv do
                local stack = inv[i]
                if stack.valid_for_read and stack.spoil_tick > 0 then
                    stack.spoil_tick = stack.spoil_tick + 30
                end
            end
        end
        ::continue::
    end

    -- Re-register personal warp pylons with Rabbasca when they've moved > 20 tiles
    -- from their last registered position, so covered chunks stay current.
    if remote.interfaces["rabbasca_warp_pylons"] and storage.personal_warp_pylons then
        for _, player in pairs(game.players) do
            local pylon = storage.personal_warp_pylons[player.index]
            if pylon and pylon.valid then
                local last = storage.personal_warp_pylon_pos and storage.personal_warp_pylon_pos[player.index]
                local pp   = pylon.position
                if not last or (pp.x - last.x)^2 + (pp.y - last.y)^2 > 400 then
                    remote.call("rabbasca_warp_pylons", "unregister_pylon", pylon.unit_number)
                    remote.call("rabbasca_warp_pylons", "register_pylon",   pylon)
                    storage.personal_warp_pylon_pos[player.index] = {x = pp.x, y = pp.y}
                end
            end
        end
    end
end)

-- Quest: Demolisher Hunt
-- Drops a Demolisher Heart at the kill site when a big-demolisher dies
-- within HEART_DROP_RANGE tiles of at least one player.

local HEART_DROP_RANGE = 50

script.on_event(defines.events.on_entity_died, function(event)
    local surface  = event.entity.surface
    local position = event.entity.position

    local nearby = surface.find_entities_filtered({
        type     = "character",
        position = position,
        radius   = HEART_DROP_RANGE,
    })
    if #nearby == 0 then return end

    surface.spill_item_stack{
        position     = position,
        stack        = {name = "demolisher-heart", count = 1},
        enable_looted = true,
    }
end, {{filter = "name", name = "big-demolisher"}})
