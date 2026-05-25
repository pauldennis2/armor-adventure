-- Quest system dispatcher.
-- Manages all quest event registrations. on_nth_tick(59) is registered
-- dynamically based on the active player's current surface and tech state,
-- using Factorio's overwrite behavior as an intentional design: only one
-- planet quest runs at a time (multiplayer: last surface-change wins).

local HAS_CASTRA = script.active_mods["castra-prime"] ~= nil

local fulgora = require("quests.fulgora")
local gleba   = require("quests.gleba")
local castra  = HAS_CASTRA and require("quests.castra") or nil

local M = {}

-- Returns the 59-tick handler for the given surface, or nil to deregister.
local function make_handler(surface_name)
    if surface_name == "gleba" then
        local tech = game.forces["player"].technologies["armor-adventure-gleba"]
        if tech and tech.researched then
            return function() gleba.on_tick_59() end
        end
    elseif surface_name == "castra" and castra then
        return function() castra.on_tick_59() end
    end
    return nil
end

-- Register or deregister the 59-tick quest handler based on this player's surface.
-- In multiplayer, the most recently surface-changed player's planet wins.
function M.on_player_surface_changed(player)
    if not (player and player.character and player.character.valid) then return end
    script.on_nth_tick(59, make_handler(player.surface.name))
end

-- Called from control.lua's on_research_finished.
-- Re-evaluates the 59-tick handler if the new tech unlocks a quest planet.
local QUEST_TECH_SURFACES = {
    ["armor-adventure-gleba"] = "gleba",
}

function M.on_research_finished(tech_name)
    local planet = QUEST_TECH_SURFACES[tech_name]
    if not planet then return end
    for _, player in pairs(game.players) do
        if player.character and player.character.valid
           and player.surface.name == planet then
            script.on_nth_tick(59, make_handler(planet))
            return
        end
    end
end

-- Called from control.lua's on_configuration_changed.
-- Restores the correct 59-tick handler after a mod update.
function M.init()
    for _, player in pairs(game.players) do
        if player.character and player.character.valid then
            local h = make_handler(player.surface.name)
            if h then
                script.on_nth_tick(59, h)
                return
            end
        end
    end
end

-- Surface change drives the 59-tick registration.
script.on_event(defines.events.on_player_changed_surface, function(event)
    M.on_player_surface_changed(game.players[event.player_index])
end)

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
