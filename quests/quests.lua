-- Quest system dispatcher.
-- on_nth_tick(59) is registered dynamically via M.refresh(), called whenever
-- the relevant game state changes (surface change, research, mod load).
--
-- Split-party rule: if any two players are simultaneously on different quest
-- surfaces, all quest handlers are disabled. Quests are cooperative — one
-- planet at a time.

local HAS_CASTRA = script.active_mods["castra-prime"] ~= nil

local fulgora = require("quests.fulgora")
local gleba   = require("quests.gleba")
local nauvis  = require("quests.nauvis")
local castra  = HAS_CASTRA and require("quests.castra") or nil

local M = {}

-- Returns the 59-tick handler for a surface name, or nil if not a quest surface
-- or the required tech has not been researched.
local function make_handler(surface_name)
    if surface_name == "nauvis" then
        local tech = game.forces["player"].technologies["armor-adventure-nauvis"]
        if tech and tech.researched then
            return function() nauvis.on_tick_59() end
        end
    elseif surface_name == "gleba" then
        local tech = game.forces["player"].technologies["armor-adventure-gleba"]
        if tech and tech.researched then
            return function() gleba.on_tick_59() end
        end
    elseif surface_name == "castra" and castra then
        return function() castra.on_tick_59() end
    end
    return nil
end

-- Re-registers tick 59 from storage alone (no game access) — safe for on_load.
local function make_handler_from_storage()
    local surface = storage.active_quest_surface
    if surface == "nauvis" then
        return function() nauvis.on_tick_59() end
    elseif surface == "gleba" then
        return function() gleba.on_tick_59() end
    elseif surface == "castra" and castra then
        return function() castra.on_tick_59() end
    end
    return nil
end

-- Scans all players and registers the correct 59-tick handler:
--   * No players on a quest surface  → deregister (nil)
--   * All quest-surface players on the same planet → register that planet's handler
--   * Players on different quest surfaces → deregister (split-party rule)
local function refresh()
    local active_surface = nil
    local active_handler = nil
    for _, player in pairs(game.players) do
        if not (player.character and player.character.valid) then goto continue end
        local name = player.surface.name
        local h    = make_handler(name)
        if h then
            if active_surface and active_surface ~= name then
                storage.active_quest_surface = nil
                script.on_nth_tick(59, nil)
                return
            end
            active_surface = name
            active_handler = h
        end
        ::continue::
    end
    storage.active_quest_surface = active_surface
    script.on_nth_tick(59, active_handler)
end

-- Called from control.lua whenever state that affects quest activation changes:
-- on_configuration_changed, on_research_finished, and on_player_changed_surface.
function M.refresh()
    refresh()
end

-- Re-register tick 59 on every game load (game is nil here; use storage only).
script.on_load(function()
    script.on_nth_tick(59, make_handler_from_storage())
end)

-- Surface change is the primary trigger; registered here since control.lua
-- has no on_player_changed_surface handler to conflict with.
script.on_event(defines.events.on_player_changed_surface, function(_)
    refresh()
end)

-- MLC: drain every tick, rescan every 5s.
-- Nauvis emitter: charge every 60 ticks, attract biters every 300 ticks.
-- NOTE: each interval has one combined handler — on_nth_tick(N, fn) replaces the
-- previous registration for that N, so all callers for a given interval are merged here.
script.on_nth_tick(1, function()
    fulgora.on_tick_1()
    if castra then castra.on_tick_smf() end
end)
script.on_nth_tick(20, function()
    if castra then castra.on_tick_laser() end
end)
-- on_nth_tick(60) is owned by control.lua; nauvis charging is dispatched via M.on_tick_60().
script.on_nth_tick(300, function() fulgora.on_tick_300() end)
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

-- Pheromone Emitter built/mined/destroyed.
local EMITTER_FILTER = {{filter = "name", name = "pheromone-emitter"}}
local function on_emitter_built(event)
    nauvis.register_emitter(event.entity, event.player_index)
end
local function on_emitter_mined(event)
    nauvis.unregister_emitter(event.entity)
end

script.on_event(defines.events.on_built_entity,        on_emitter_built,  EMITTER_FILTER)
script.on_event(defines.events.on_robot_built_entity,  on_emitter_built,  EMITTER_FILTER)
script.on_event(defines.events.script_raised_built,    on_emitter_built,  EMITTER_FILTER)
script.on_event(defines.events.on_player_mined_entity, on_emitter_mined,  EMITTER_FILTER)
script.on_event(defines.events.on_robot_mined_entity,  on_emitter_mined,  EMITTER_FILTER)

-- Entity died: dispatch to the module that owns each entity name.
local entity_died_filter = {
    {filter = "name", name = "harvester"},
    {filter = "name", name = "big-demolisher"},
    {filter = "name", name = "pheromone-emitter"},
}
if HAS_CASTRA then
    table.insert(entity_died_filter, {filter = "name", name = "data-collector"})
    table.insert(entity_died_filter, {filter = "name", name = "simulac-commander"})
    table.insert(entity_died_filter, {filter = "name", name = "simulac-mobile-fortress"})
end

script.on_event(defines.events.on_entity_died, function(event)
    local name = event.entity.name
    if name == "harvester" or name == "big-demolisher" then
        gleba.on_entity_died(event)
    elseif name == "pheromone-emitter" then
        nauvis.on_emitter_destroyed(event.entity)
    elseif castra and (name == "data-collector" or name == "simulac-commander" or name == "simulac-mobile-fortress") then
        castra.on_entity_died(event)
    end
end, entity_died_filter)

return M
