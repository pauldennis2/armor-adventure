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
        game.print("Charged up!")
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

script.on_event(defines.events.on_script_trigger_effect, function(event)
    if event.effect_id ~= "mind-control-hit" then return end
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
