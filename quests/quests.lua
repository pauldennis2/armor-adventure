-- Quest system dispatcher.
-- Owns all quest-related event registrations except on_nth_tick(60),
-- which is exported as M.on_tick_60() for control.lua to call from its
-- own handler (avoiding a duplicate registration that would silently win).

local HAS_CASTRA = script.active_mods["castra-prime"] ~= nil

local fulgora = require("quests.fulgora")
local gleba   = require("quests.gleba")
local castra  = HAS_CASTRA and require("quests.castra") or nil

local M = {}

-- Personal Fridge: half spoilage rate while wearing Promethium Armor.
local function tick_personal_fridge()
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
end

-- Warp pylon: re-register with Rabbasca when the pylon has moved > 20 tiles.
local function tick_warp_pylon()
    if not (remote.interfaces["rabbasca_warp_pylons"] and storage.personal_warp_pylons) then return end
    for _, player in pairs(game.players) do
        local pylon = storage.personal_warp_pylons[player.index]
        if not (pylon and pylon.valid) then goto continue end
        local last = storage.personal_warp_pylon_pos and storage.personal_warp_pylon_pos[player.index]
        local pp   = pylon.position
        if not last or (pp.x - last.x)^2 + (pp.y - last.y)^2 > 400 then
            remote.call("rabbasca_warp_pylons", "unregister_pylon", pylon.unit_number)
            remote.call("rabbasca_warp_pylons", "register_pylon",   pylon)
            storage.personal_warp_pylon_pos[player.index] = {x = pp.x, y = pp.y}
        end
        ::continue::
    end
end

-- Called by control.lua from its on_nth_tick(60) handler.
function M.on_tick_60()
    gleba.on_tick_60()
    tick_personal_fridge()
    tick_warp_pylon()
    if castra then castra.on_tick_60() end
end

-- MLC: drain every tick, rescan every 5s.
script.on_nth_tick(1,   function() fulgora.on_tick_1() end)
script.on_nth_tick(300, function() fulgora.on_tick_300() end)

-- Castra meter drain: once per minute.
if castra then
    script.on_nth_tick(3600, function() castra.on_tick_3600() end)
end

-- Script trigger effects (mind control hit, tesla turret damage).
script.on_event(defines.events.on_script_trigger_effect, function(event)
    gleba.on_script_trigger_effect(event)
end)

-- Harvester built/removed.
local HARVESTER_FILTER = {{filter = "name", name = "harvester"}}
local function on_harvester_built(event)   gleba.register_harvester(event.entity)   end
local function on_harvester_removed(event) gleba.unregister_harvester(event.entity) end

script.on_event(defines.events.on_built_entity,        on_harvester_built,   HARVESTER_FILTER)
script.on_event(defines.events.on_robot_built_entity,  on_harvester_built,   HARVESTER_FILTER)
script.on_event(defines.events.script_raised_built,    on_harvester_built,   HARVESTER_FILTER)
script.on_event(defines.events.on_player_mined_entity, on_harvester_removed, HARVESTER_FILTER)
script.on_event(defines.events.on_robot_mined_entity,  on_harvester_removed, HARVESTER_FILTER)
script.on_event(defines.events.script_raised_destroy,  on_harvester_removed, HARVESTER_FILTER)

-- Entity died: dispatch to the module that owns each entity name.
local entity_died_filter = {
    {filter = "name", name = "harvester"},
    {filter = "name", name = "big-demolisher"},
}
if HAS_CASTRA then
    table.insert(entity_died_filter, {filter = "name", name = "data-collector"})
    table.insert(entity_died_filter, {filter = "name", name = "simulac-commander"})
end

script.on_event(defines.events.on_entity_died, function(event)
    local name = event.entity.name
    if name == "harvester" or name == "big-demolisher" then
        gleba.on_entity_died(event)
    elseif castra and (name == "data-collector" or name == "simulac-commander") then
        castra.on_entity_died(event)
    end
end, entity_died_filter)

return M
