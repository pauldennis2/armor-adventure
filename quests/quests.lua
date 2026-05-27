-- Quest system dispatcher.
-- on_nth_tick(59) is registered dynamically via M.refresh(), called whenever
-- the relevant game state changes (surface change, research, mod load).
--
-- Split-party rule: if any two players are simultaneously on different quest
-- surfaces, all quest handlers are disabled. Quests are cooperative — one
-- planet at a time.

local HAS_CASTRA = script.active_mods["castra-prime"] ~= nil

local aquilo  = require("quests.aquilo")
local fulgora = require("quests.fulgora")
local gleba   = require("quests.gleba")
local nauvis  = require("quests.nauvis")
local castra  = HAS_CASTRA and require("quests.castra") or nil

local M = {}

-- Always-on handler: call every quest module's tick-59 function unconditionally.
-- Each module guards its own work with early-return when nothing is active, so
-- this is safe and cheap when quests are idle.
--
-- Previously the handler was registered dynamically only when a player was present
-- on the relevant planet surface (UPS-friendly, see git history). That approach
-- breaks when surface-change events are suppressed (e.g. bunnyhop engine), so we
-- run all modules unconditionally until a more robust trigger is available.
local function make_always_handler()
    return function()
        aquilo.on_tick_59()
        nauvis.on_tick_59()
        gleba.on_tick_59()
        if castra then castra.on_tick_59() end
    end
end

-- Called from control.lua whenever state that affects quest activation changes.
local function refresh()
    script.on_nth_tick(59, make_always_handler())
    storage.active_quest_surface = "active"
end

function M.refresh()
    refresh()
end

-- Re-register tick 59 on every game load (game is nil here; closures are valid).
script.on_load(function()
    script.on_nth_tick(59, make_always_handler())
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

-- Elevator shaft built/removed.
local ELEVATOR_FILTER = {{filter = "name", name = "aquilo-elevator-shaft"}}
local function on_elevator_built(event)
    aquilo.register_elevator(event.entity)
    refresh()
end
local function on_elevator_removed(event)
    aquilo.unregister_elevator(event.entity)
    refresh()
end

script.on_event(defines.events.on_built_entity,        on_elevator_built,   ELEVATOR_FILTER)
script.on_event(defines.events.on_robot_built_entity,  on_elevator_built,   ELEVATOR_FILTER)
script.on_event(defines.events.script_raised_built,    on_elevator_built,   ELEVATOR_FILTER)
script.on_event(defines.events.on_player_mined_entity, on_elevator_removed, ELEVATOR_FILTER)
script.on_event(defines.events.on_robot_mined_entity,  on_elevator_removed, ELEVATOR_FILTER)

-- Entity died: dispatch to the module that owns each entity name.
local entity_died_filter = {
    {filter = "name", name = "harvester"},
    {filter = "name", name = "big-demolisher"},
    {filter = "name", name = "pheromone-emitter"},
    {filter = "name", name = "gigantoid-spitter"},
    {filter = "name", name = "big-worm-turret"},
    {filter = "name", name = "aquilo-elevator-shaft"},
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
    elseif name == "aquilo-elevator-shaft" then
        aquilo.unregister_elevator(event.entity)
        refresh()
    elseif name == "gigantoid-spitter" then
        nauvis.on_gigantoid_died(event.entity)
    elseif name == "big-worm-turret" then
        nauvis.on_big_worm_died(event.entity)
    elseif castra and (name == "data-collector" or name == "simulac-commander" or name == "simulac-mobile-fortress") then
        castra.on_entity_died(event)
    end
end, entity_died_filter)

return M
