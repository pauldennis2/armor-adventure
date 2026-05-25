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
        if target.surface.name ~= "gleba" then return end  -- belt: Gleba surface only
        if target.type ~= "unit" then return end            -- suspenders: mobile units only, not spawners/structures
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
    if mc then
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
    end -- if mc

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

    -- SIMULAC Commander: close-range laser pulse + pursuit command refresh.
    if HAS_CASTRA_QUEST then
        local cmd = storage.simulac_commander
        if cmd and cmd.valid then
            -- Undodgeable laser pulse, 15-tile radius, 200 laser/s.
            local nearby = cmd.surface.find_entities_filtered({
                type     = "character",
                position = cmd.position,
                radius   = 15,
            })
            for _, char in ipairs(nearby) do
                if char.valid and char.force.name ~= "enemy" then
                    char.damage(200, "enemy", "laser", cmd)
                    rendering.draw_line{
                        color        = {r = 0.2, g = 0.9, b = 1.0, a = 0.85},
                        width        = 4,
                        from         = cmd.position,
                        to           = char.position,
                        surface      = cmd.surface,
                        time_to_live = 20,
                    }
                end
            end

            -- Re-issue pursuit toward nearest player every second so it tracks movement.
            if cmd.commandable then
                local nearest, dist2 = nil, math.huge
                for _, player in pairs(game.players) do
                    if player.character and player.character.valid
                       and player.surface == cmd.surface then
                        local dx = player.position.x - cmd.position.x
                        local dy = player.position.y - cmd.position.y
                        local d  = dx*dx + dy*dy
                        if d < dist2 then dist2 = d; nearest = player end
                    end
                end
                if nearest then
                    cmd.commandable.set_command{
                        type        = defines.command.go_to_location,
                        destination = nearest.position,
                        distraction = defines.distraction.by_anything,
                    }
                end
            end
        end
    end
end)

-- Quest: SIMULAC Commander (Castra)
-- Killing enemy data-collector bases earns quality-scaled points (1–5).
-- Warning fires when meter crosses SIMULAC_WARN_THRESHOLD. Spawns commander at SIMULAC_KILL_THRESHOLD.
-- Meter drains SIMULAC_DRAIN_PER_MIN points per minute.

local HAS_CASTRA_QUEST       = script.active_mods["castra-prime"] ~= nil
local SIMULAC_KILL_THRESHOLD = 50
local SIMULAC_WARN_THRESHOLD = 30
local SIMULAC_DRAIN_PER_MIN  = 2
local SIMULAC_QUALITY_POINTS = {normal=1, uncommon=2, rare=3, epic=4, legendary=5}
local SIMULAC_COMMANDER_NAME = "simulac-commander"
local SIMULAC_SPAWN_DIST     = 90  -- tiles; off-screen at normal zoom

local function find_player_on_castra(near_position)
    local best, best_d2 = nil, math.huge
    for _, player in pairs(game.players) do
        if player.character and player.character.valid
           and player.surface.name == "castra" then
            local dx = player.position.x - near_position.x
            local dy = player.position.y - near_position.y
            local d2 = dx * dx + dy * dy
            if d2 < best_d2 then best_d2 = d2; best = player end
        end
    end
    return best
end

local function spawn_simulac_commander(near_player)
    local surface = near_player.surface
    local angle   = math.random() * 2 * math.pi
    local base    = {
        x = near_player.position.x + math.cos(angle) * SIMULAC_SPAWN_DIST,
        y = near_player.position.y + math.sin(angle) * SIMULAC_SPAWN_DIST,
    }
    local pos = surface.find_non_colliding_position(SIMULAC_COMMANDER_NAME, base, 20, 1)
    if not pos then pos = base end

    local commander = surface.create_entity({
        name     = SIMULAC_COMMANDER_NAME,
        position = pos,
        force    = "enemy",
    })
    if commander and commander.valid then
        storage.simulac_commander = commander
        if commander.commandable then
            commander.commandable.set_command({
                type        = defines.command.go_to_location,
                destination = near_player.position,
                distraction = defines.distraction.by_anything,
            })
        end
    end
    game.forces["player"].print({"armor-adventure.simulac-commander-spawned"})
end

-- Quest: Demolisher Hunt
-- Drops a Demolisher Heart at the kill site when a big-demolisher dies
-- within HEART_DROP_RANGE tiles of at least one player.

local HEART_DROP_RANGE = 50

-- Consolidated on_entity_died handler.
-- Factorio allows only one on_entity_died registration per mod; all cases dispatch here.
local entity_died_filter = {
    {filter = "name", name = "harvester"},
    {filter = "name", name = "big-demolisher"},
}
if HAS_CASTRA_QUEST then
    table.insert(entity_died_filter, {filter = "name", name = "data-collector"})
    table.insert(entity_died_filter, {filter = "name", name = SIMULAC_COMMANDER_NAME})
end

script.on_event(defines.events.on_entity_died, function(event)
    local ent  = event.entity
    local name = ent.name

    if name == "harvester" then
        on_harvester_removed(event)

    elseif HAS_CASTRA_QUEST and name == "data-collector" then
        if ent.surface.name ~= "castra" then return end
        if ent.force.name  ~= "enemy"   then return end
        -- Only credit kills made by a player character physically on Castra.
        local cause = event.cause
        if not (cause and cause.valid and cause.type == "character") then return end
        if cause.surface.name ~= "castra" then return end
        local quality   = ent.quality and ent.quality.name or "normal"
        local pts       = SIMULAC_QUALITY_POINTS[quality] or 1
        local old_meter = storage.simulac_awaken_meter or 0
        local new_meter = old_meter + pts
        storage.simulac_awaken_meter = new_meter
        game.forces["player"].print(
            "Killed a " .. quality .. " base, +" .. pts .. " castra points, you now have " .. new_meter)
        if old_meter < SIMULAC_WARN_THRESHOLD and new_meter >= SIMULAC_WARN_THRESHOLD then
            game.forces["player"].print({"armor-adventure.simulac-warning"})
        end
        if new_meter >= SIMULAC_KILL_THRESHOLD then
            storage.simulac_awaken_meter = 0
            game.forces["player"].print("Castra meter reset to 0 (commander spawned).")
            local trigger_player = nil
            if event.cause and event.cause.valid and event.cause.type == "character" then
                trigger_player = event.cause.player
            end
            if not trigger_player then
                trigger_player = find_player_on_castra(ent.position)
            end
            if trigger_player then
                spawn_simulac_commander(trigger_player)
            end
        end

    elseif HAS_CASTRA_QUEST and name == SIMULAC_COMMANDER_NAME then
        storage.simulac_commander = nil
        local surf      = ent.surface
        local pos       = ent.position
        local place_pos = surf.find_non_colliding_position("steel-chest", pos, 5, 0.5) or pos
        local chest     = surf.create_entity({name = "steel-chest", position = place_pos, force = "neutral"})
        if chest and chest.valid then
            chest.get_inventory(defines.inventory.chest).insert({name = "unrefined-simulac-core", count = 1})
            rendering.draw_text{
                text          = "★ SIMULAC Core",
                surface       = surf,
                target        = place_pos,
                target_offset = {0, -2.5},
                color         = {r = 1, g = 0.8, b = 0, a = 1},
                scale         = 1.5,
                alignment     = "center",
                time_to_live  = 600,
            }
        else
            surf.spill_item_stack{position = pos, stack = {name = "unrefined-simulac-core", count = 1}, enable_looted = true}
        end

    elseif name == "big-demolisher" then
        local surface  = ent.surface
        local position = ent.position
        local nearby   = surface.find_entities_filtered({
            type     = "character",
            position = position,
            radius   = HEART_DROP_RANGE,
        })
        if #nearby == 0 then return end
        surface.spill_item_stack{
            position      = position,
            stack         = {name = "demolisher-heart", count = 1},
            enable_looted = true,
        }
    end
end, entity_died_filter)

-- Drain the Castra meter by SIMULAC_DRAIN_PER_MIN every minute.
if HAS_CASTRA_QUEST then
    script.on_nth_tick(3600, function()
        local meter = storage.simulac_awaken_meter or 0
        if meter <= 0 then return end
        local drained = math.min(meter, SIMULAC_DRAIN_PER_MIN)
        storage.simulac_awaken_meter = meter - drained
        game.forces["player"].print(
            "Castra meter drain: -" .. drained .. " points, now at " .. storage.simulac_awaken_meter)
    end)
end
