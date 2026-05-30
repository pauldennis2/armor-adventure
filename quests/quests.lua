-- Quest system dispatcher.
-- on_nth_tick(59) is registered dynamically via M.refresh(), called whenever
-- the relevant game state changes (surface change, research, mod load).
--
-- Split-party rule: if any two players are simultaneously on different quest
-- surfaces, all quest handlers are disabled. Quests are cooperative — one
-- planet at a time.

local HAS_CASTRA   = script.active_mods["castra-prime"]    ~= nil
local HAS_MOSHINE  = script.active_mods["Moshine"]         ~= nil
local HAS_PANGLIA  = script.active_mods["panglia_planet"]  ~= nil
local HAS_RABBASCA = script.active_mods["planet-rabbasca"] ~= nil

local aquilo   = require("quests.aquilo")
local fulgora  = require("quests.fulgora")
local gleba    = require("quests.gleba")
local nauvis   = require("quests.nauvis")
local castra   = HAS_CASTRA   and require("quests.castra")   or nil
local moshine  = HAS_MOSHINE  and require("quests.moshine")  or nil
local panglia  = HAS_PANGLIA  and require("quests.panglia")  or nil
local rabbasca = HAS_RABBASCA and require("quests.rabbasca") or nil

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
        if castra  then castra.on_tick_59()  end
        if panglia then panglia.on_tick_59() end
    end
end

-- Called from control.lua whenever state that affects quest activation changes.
local function refresh()
    script.on_nth_tick(59, make_always_handler())
    storage.active_quest_surface = "active"
    gleba.rescan_harvesters()
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

-- Train-rotation detection for Moshine motion-data recipes (every 3 ticks = 20/s).
-- High frequency needed because the target train completes multiple laps per second;
-- combined with distance-adaptive sampling in moshine.lua this stays cheap.
if moshine then
    script.on_nth_tick(3, function() moshine.on_tick_3() end)
end

-- Script trigger effects (mind control hit, tesla turret damage).
script.on_event(defines.events.on_script_trigger_effect, function(event)
    gleba.on_script_trigger_effect(event)
    if panglia then panglia.on_script_trigger_effect(event) end
end)


-- NOTE: script.on_event replaces the previous handler for the same event id, so
-- all built/mined handlers MUST be merged into a single registration per event type
-- (the same rule that applies to on_nth_tick). One combined filter + dispatch here.
local BUILT_FILTER = {
    {filter = "name", name = "harvester"},
    {filter = "name", name = "pheromone-emitter"},
    {filter = "name", name = "aquilo-elevator-shaft"},
}
if HAS_RABBASCA then
    table.insert(BUILT_FILTER, {filter = "name", name = "vault-entry-portal"})
end
local function on_entity_built(event)
    local name = event.entity.name
    if     name == "harvester"             then gleba.register_harvester(event.entity)
    elseif name == "pheromone-emitter"     then nauvis.register_emitter(event.entity, event.player_index)
    elseif name == "aquilo-elevator-shaft" then aquilo.register_elevator(event.entity); refresh()
    elseif name == "vault-entry-portal" and rabbasca then
        local player = event.player_index and game.players[event.player_index]
        if event.entity.surface.name ~= "rabbasca" then
            -- Wrong surface: refund the item and bail out
            if player then
                player.insert({name = "vault-entry-pass", count = 1, quality = event.entity.quality})
                player.print("[color=#FF6666]The vault portal only functions on Rabbasca.[/color]")
            end
        else
            if player then
                local quality_name = event.entity.quality and event.entity.quality.name or "normal"
                rabbasca.enter_tunnel(player, quality_name, event.entity.surface, event.entity.position)
            end
        end
        if event.entity.valid then event.entity.destroy() end
    end
end
script.on_event(defines.events.on_built_entity,       on_entity_built, BUILT_FILTER)
script.on_event(defines.events.on_robot_built_entity, on_entity_built, BUILT_FILTER)
script.on_event(defines.events.script_raised_built,   on_entity_built, BUILT_FILTER)

local MINED_FILTER = {
    {filter = "name", name = "harvester"},
    {filter = "name", name = "pheromone-emitter"},
    {filter = "name", name = "aquilo-elevator-shaft"},
}
if HAS_RABBASCA then
    table.insert(MINED_FILTER, {filter = "name", name = "rabbit-mcguffin"})
end
local function on_entity_mined(event)
    local name = event.entity.name
    if     name == "harvester"             then gleba.unregister_harvester(event.entity)
    elseif name == "pheromone-emitter"     then nauvis.unregister_emitter(event.entity)
    elseif name == "aquilo-elevator-shaft" then aquilo.unregister_elevator(event.entity); refresh()
    elseif name == "rabbit-mcguffin" then
        local player = event.player_index and game.players[event.player_index]
        if player then
            local ret = storage.vault_tunnel_return and storage.vault_tunnel_return[player.index]
            local quality_name = ret and ret.quality or "normal"
            local inserted = player.insert({name = "rabbit-mcguffin", count = 1, quality = quality_name})
            if inserted == 0 then
                player.surface.spill_item_stack(player.position, {name = "rabbit-mcguffin", count = 1, quality = quality_name}, true)
            end
            player.print("[color=#FFD700]You've claimed the vault's prize. The path to the Warp Pylon is now open.[/color]")
        end
    end
end
script.on_event(defines.events.on_player_mined_entity, on_entity_mined, MINED_FILTER)
script.on_event(defines.events.on_robot_mined_entity,  on_entity_mined, MINED_FILTER)
script.on_event(defines.events.script_raised_destroy,  on_entity_mined, MINED_FILTER)

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
if HAS_RABBASCA then
    table.insert(entity_died_filter, {filter = "name", name = "gun-turret"})
    table.insert(entity_died_filter, {filter = "name", name = "vault-laser-turret"})
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
    elseif (name == "gun-turret" or name == "vault-laser-turret") and rabbasca then
        rabbasca.on_turret_died(event.entity)
    end
end, entity_died_filter)

return M
