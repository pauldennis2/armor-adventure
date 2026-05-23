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
