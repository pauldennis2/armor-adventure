-- Quest: Massive Lightning Collector (Fulgora)

local fulgora = {}

local MLC_NAME           = "massive-lightning-collector"
local MLC_THRESHOLD      = 1000e9
local MLC_DRAIN_RATE     = 5e9
local MLC_DRAIN_PER_TICK = MLC_DRAIN_RATE / 60

function fulgora.on_tick_1()
    local entity = storage.mlc_entity
    if not entity or not entity.valid then return end

    if entity.energy >= MLC_THRESHOLD then
        local pos = entity.position
        entity.surface.spill_item_stack{
            position      = {
                x = pos.x + math.random(-4, 4),
                y = pos.y + math.random(-4, 4),
            },
            stack         = {name = "charged-lightning-gem", count = 1},
            enable_looted = true,
        }
        entity.energy = 0
        return
    end

    entity.energy = math.max(0, entity.energy - MLC_DRAIN_PER_TICK)
end

function fulgora.on_tick_300()
    if storage.mlc_entity and storage.mlc_entity.valid then return end
    storage.mlc_entity = nil
    for _, surface in pairs(game.surfaces) do
        local found = surface.find_entities_filtered({name = MLC_NAME, limit = 1})
        if found[1] then storage.mlc_entity = found[1]; return end
    end
end

return fulgora
