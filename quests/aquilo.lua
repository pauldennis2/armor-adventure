-- Quest: Aquilo
--
-- Phase 1 — EM Scanning Array:
--   Build powered radars on Aquilo while on-planet. Progress = sum of active-radar
--   counts across ~59-tick polls. 1 radar ≈ 20 min, 20 radars ≈ 1 min.
--   At 50%: halfway message. At 100%: aquilo-signal-source entity spawns; mining
--   it fires the "aquilo-scanning-complete" research trigger.
--
-- Phase 2 — Elevator Construction:
--   Player builds aquilo-elevator-shaft (assembling machine, aquilo-elevator-construction
--   category). It runs the aquilo-elevator-dig recipe automatically. Script polls
--   products_finished every ~59 ticks and shows a [item=concrete] X/100 counter.
--   At 100 cycles: shaft is replaced by aquilo-elevator-complete placeholder.

local aquilo = {}

-- Phase 1 constants
local SCAN_TOTAL           = 1200  -- accumulation steps at ~59 ticks each
-- 1 radar:  1200 × 59 = 70800 ticks ≈ 19.7 min
-- 20 radars:  60 × 59 =  3540 ticks ≈ 59 s
local SIGNAL_SOURCE_RADIUS = 120   -- tiles from Aquilo origin

-- Phase 2 constants
local ELEVATOR_CYCLES = 100

-- ─── helpers ─────────────────────────────────────────────────────────────────

local function get_aquilo_surface()
    for _, s in pairs(game.surfaces) do
        if s.planet and s.planet.name == "aquilo" then return s end
    end
    return game.surfaces["aquilo"]
end

-- ─── Phase 1: scanning ───────────────────────────────────────────────────────

local function init_scanning()
    if not storage.aquilo_scanning then
        storage.aquilo_scanning = {progress = 0, notified_half = false}
    end
end

local function spawn_signal_source(surface)
    local anchor = {x = 0, y = 0}
    for _, p in pairs(game.players) do
        if p.character and p.character.valid and p.surface == surface then
            anchor = p.position
            break
        end
    end

    local angle = math.random() * 2 * math.pi
    local dist  = 60 + math.random() * 20
    local pos   = {
        x = anchor.x + math.cos(angle) * dist,
        y = anchor.y + math.sin(angle) * dist,
    }
    local valid = surface.find_non_colliding_position("aquilo-signal-source", pos, 30, 1) or pos
    local ent   = surface.create_entity({name = "aquilo-signal-source", position = valid, force = "neutral"})

    if not (ent and ent.valid) then
        game.print("[color=red][armor-adventure] ERROR: failed to spawn aquilo-signal-source — report this bug.[/color]")
        return
    end

    rendering.draw_text{
        text          = "★ Signal Source Detected",
        surface       = surface,
        target        = ent.position,
        target_offset = {0, -3},
        color         = {r = 0.4, g = 0.8, b = 1.0, a = 1},
        scale         = 1.5,
        alignment     = "center",
        time_to_live  = 36000,
    }
end

local function complete_scanning(state)
    local surface = get_aquilo_surface()
    if surface then spawn_signal_source(surface) end
    state.complete = true
    game.print("[color=cyan]Scanning complete — the signal source has been pinpointed. Go investigate it.[/color]")
end

local function on_tick_59_scanning()
    init_scanning()
    local state = storage.aquilo_scanning
    if state.complete then return end

    local done = game.forces["player"].technologies["aquilo-scanning-complete"]
    if done and done.researched then
        state.complete = true
        return
    end

    local surface = get_aquilo_surface()
    if not surface then return end

    local radars = surface.find_entities_filtered({type = "radar", force = "player"})
    local count  = 0
    for _, r in pairs(radars) do
        if r.valid and r.status == defines.entity_status.working then
            count = count + 1
        end
    end
    if count == 0 then return end

    state.progress = state.progress + count

    if state.progress >= SCAN_TOTAL then
        complete_scanning(state)
    elseif state.progress >= SCAN_TOTAL * 0.5 and not state.notified_half then
        state.notified_half = true
        game.print("[color=cyan]Signal zone isolated, continuing to pinpoint location...[/color]")
    end
end

-- ─── Depot surface ───────────────────────────────────────────────────────────

local DEPOT_SURFACE_NAME = "aquilo-fulgoran-depot"
local DEPOT_ROOM_HALF    = 12  -- 24×24 interior floor
local DEPOT_WALL_HALF    = 128 -- must cover all generated chunks (radius 4 × 32 = ±128 tiles)
local DEPOT_CORNER_INSET = DEPOT_ROOM_HALF - 2  -- = 10

-- ─── Depot puzzle configuration ───────────────────────────────────────────────

local PUZZLE_CONFIGS = {
    {
        pos        = {x =  DEPOT_CORNER_INSET, y =  DEPOT_CORNER_INSET},
        clue_lines = {"Sequence: 1, 1, 2, ?, 5, 8", "Enter the missing number as signal [A]."},
        check      = function(s) return (s["signal-A"] or 0) == 3 end,
        initial    = {{value = {type = "virtual", name = "signal-A"}, min = 1}},
    },
    {
        pos        = {x = -DEPOT_CORNER_INSET, y =  DEPOT_CORNER_INSET},
        clue_lines = {"Sequence: 2, 4, ?, 16, 32", "Enter the missing number as signal [A]."},
        check      = function(s) return (s["signal-A"] or 0) == 8 end,
        initial    = {{value = {type = "virtual", name = "signal-A"}, min = 1}},
    },
    {
        pos        = {x =  DEPOT_CORNER_INSET, y = -DEPOT_CORNER_INSET},
        clue_lines = {"What is the Answer to Life,", "the Universe, and Everything?", "Enter as signal [A]."},
        check      = function(s) return (s["signal-A"] or 0) == 42 end,
        initial    = {{value = {type = "virtual", name = "signal-A"}, min = 1}},
    },
    {
        pos        = {x = -DEPOT_CORNER_INSET, y = -DEPOT_CORNER_INSET},
        clue_lines = {"The kind of thing an idiot", "would have on his luggage.", "(5 digits)"},
        check      = function(s)
            for _, n in ipairs({"signal-1","signal-2","signal-3","signal-4","signal-5"}) do
                if (s[n] or 0) <= 0 then return false end
            end
            return true
        end,
        initial = {
            {value = {type = "virtual", name = "signal-9"}, min = 1},
            {value = {type = "virtual", name = "signal-8"}, min = 1},
            {value = {type = "virtual", name = "signal-3"}, min = 1},
        },
    },
}

local depot_renders = {}  -- module-level; not in storage; rebuilt on depot entry

local function set_combinator_signals(entity, signals)
    local cb      = entity.get_or_create_control_behavior()
    local section = cb.get_section(1) or cb.add_section()
    for i, sig in ipairs(signals) do
        section.set_slot(i, sig)
    end
end

local function read_combinator_signals(entity)
    local result = {}
    local cb = entity.get_or_create_control_behavior()
    for si = 1, cb.sections_count do
        local section = cb.get_section(si)
        if section then
            for fi = 1, section.filters_count do
                local f = section.get_slot(fi)
                if f and f.value and f.value.name then
                    result[f.value.name] = (result[f.value.name] or 0) + (f.min or 0)
                end
            end
        end
    end
    return result
end

local function puzzle_index_for(entity)
    local pos = entity.position
    for i, cfg in ipairs(PUZZLE_CONFIGS) do
        local dx = pos.x - cfg.pos.x
        local dy = pos.y - cfg.pos.y
        if dx * dx + dy * dy < 1 then return i end
    end
end

local function make_depot_renders(surface, idx, solved)
    local cfg   = PUZZLE_CONFIGS[idx]
    local r     = {lines = {}}
    local y_dir = (cfg.pos.y >= 0) and -1 or 1
    for j, line in ipairs(cfg.clue_lines) do
        r.lines[j] = rendering.draw_text{
            text          = line,
            surface       = surface,
            target        = {x = cfg.pos.x, y = cfg.pos.y + y_dir * (2.0 + (j - 1) * 0.8)},
            color         = {r = 0.9, g = 0.9, b = 1.0, a = 1},
            scale         = 0.8,
            alignment     = "center",
            use_rich_text = false,
        }
    end
    r.indicator = rendering.draw_circle{
        color   = solved and {r = 0.2, g = 1.0, b = 0.2, a = 0.9}
                        or  {r = 1.0, g = 0.2, b = 0.2, a = 0.9},
        radius  = 0.35,
        width   = 0,
        filled  = true,
        surface = surface,
        target  = {x = cfg.pos.x, y = cfg.pos.y + y_dir * 1.2},
    }
    return r
end

local function destroy_depot_render(r)
    for _, lr in pairs(r.lines or {}) do
        if lr and lr.valid then lr.destroy() end
    end
    if r.indicator and r.indicator.valid then r.indicator.destroy() end
end

local function setup_depot_puzzles(surface)
    if not storage.aquilo_depot then
        storage.aquilo_depot = {solved = {false, false, false, false}}
    end
    for i, cfg in ipairs(PUZZLE_CONFIGS) do
        local combs = surface.find_entities_filtered({name = "constant-combinator", position = cfg.pos, radius = 0.5})
        if combs[1] and combs[1].valid then
            set_combinator_signals(combs[1], cfg.initial)
        end
        depot_renders[i] = make_depot_renders(surface, i, storage.aquilo_depot.solved[i] or false)
    end
end

function aquilo.migrate_depot_puzzles()
    local surface = game.surfaces[DEPOT_SURFACE_NAME]
    if not surface then return end
    if not storage.aquilo_depot then
        storage.aquilo_depot = {solved = {false, false, false, false}}
    end
    for i, cfg in ipairs(PUZZLE_CONFIGS) do
        local combs = surface.find_entities_filtered({name = "constant-combinator", position = cfg.pos, radius = 0.5})
        if combs[1] and combs[1].valid then
            local cb      = combs[1].get_or_create_control_behavior()
            local section = cb.get_section(1)
            -- Only overwrite if the combinator has no signals set (freshly placed)
            if not section or section.filters_count == 0 then
                set_combinator_signals(combs[1], cfg.initial)
            end
        end
    end
end

function aquilo.rebuild_depot_renders()
    local surface = game.surfaces[DEPOT_SURFACE_NAME]
    if not surface then return end
    for _, r in pairs(depot_renders) do destroy_depot_render(r) end
    depot_renders = {}
    local solved = (storage.aquilo_depot and storage.aquilo_depot.solved) or {}
    for i = 1, #PUZZLE_CONFIGS do
        depot_renders[i] = make_depot_renders(surface, i, solved[i] or false)
    end
end

function aquilo.check_combinator_puzzle(entity)
    if not (entity and entity.valid) then return end
    local idx = puzzle_index_for(entity)
    if not idx then return end
    if not storage.aquilo_depot then
        storage.aquilo_depot = {solved = {false, false, false, false}}
    end
    local solved = storage.aquilo_depot.solved
    if solved[idx] then return end
    if not PUZZLE_CONFIGS[idx].check(read_combinator_signals(entity)) then return end

    solved[idx] = true
    game.print("[color=cyan]System " .. idx .. " unlocked.[/color]")

    local r = depot_renders[idx]
    if r then
        if r.indicator and r.indicator.valid then r.indicator.destroy() end
        local cfg   = PUZZLE_CONFIGS[idx]
        local y_dir = (cfg.pos.y >= 0) and -1 or 1
        r.indicator = rendering.draw_circle{
            color   = {r = 0.2, g = 1.0, b = 0.2, a = 0.9},
            radius  = 0.35,
            width   = 0,
            filled  = true,
            surface = entity.surface,
            target  = {x = cfg.pos.x, y = cfg.pos.y + y_dir * 1.2},
        }
    end

    local all_done = true
    for i = 1, #PUZZLE_CONFIGS do
        if not solved[i] then all_done = false; break end
    end
    if all_done then
        storage.aquilo_depot.vault_unlocked = true
        game.print("[color=cyan]All Fulgoran systems online. The cryovault has been unsealed.[/color]")
    end
end

-- ─────────────────────────────────────────────────────────────────────────────

function aquilo.get_or_create_depot_surface()
    if game.surfaces[DEPOT_SURFACE_NAME] then
        return game.surfaces[DEPOT_SURFACE_NAME]
    end

    local surface = game.create_surface(DEPOT_SURFACE_NAME, {
        peaceful_mode = true,
        autoplace_settings = {
            entity     = {treat_missing_as_default = false, settings = {}},
            decorative = {treat_missing_as_default = false, settings = {}},
            tile       = {treat_missing_as_default = false, settings = {}},
        },
        cliff_settings = {cliff_elevation_0 = 1024, cliff_elevation_interval = 1024},
    })

    -- Radius 4 covers ±128 tiles, matching DEPOT_WALL_HALF=128.
    surface.request_to_generate_chunks({0, 0}, 4)
    surface.force_generate_chunk_requests()

    surface.freeze_daytime  = true
    surface.min_brightness  = 1

    local tiles = {}
    for x = -DEPOT_WALL_HALF, DEPOT_WALL_HALF - 1 do
        for y = -DEPOT_WALL_HALF, DEPOT_WALL_HALF - 1 do
            tiles[#tiles + 1] = {name = "out-of-map", position = {x, y}}
        end
    end
    for x = -DEPOT_ROOM_HALF, DEPOT_ROOM_HALF - 1 do
        for y = -DEPOT_ROOM_HALF, DEPOT_ROOM_HALF - 1 do
            tiles[#tiles + 1] = {name = "refined-concrete", position = {x, y}}
        end
    end
    surface.set_tiles(tiles, true)

    -- Constant combinators at puzzle corner positions (non-minable, indestructible)
    for _, cfg in ipairs(PUZZLE_CONFIGS) do
        local comb = surface.create_entity({name = "constant-combinator", position = cfg.pos, force = "player"})
        if comb and comb.valid then
            comb.minable_flag  = false
            comb.destructible  = false
        end
    end

    -- Ascent elevator placeholder at center (indestructible)
    local ascent = surface.create_entity({
        name     = "aquilo-depot-ascent",
        position = {0, 0},
        force    = "neutral",
    })
    if ascent and ascent.valid then ascent.destructible = false end

    -- Cryovault chest: locked until all puzzles are solved. Spawned at north wall, left of center.
    local vault = surface.create_entity({
        name     = "cryovault-chest",
        position = {-2, -9},
        force    = "neutral",
    })
    if vault and vault.valid then
        vault.destructible = false
        vault.insert({name = "cryovault-access-card", count = 1})
    end

    -- Vault card reader: player inserts access card, closes chest; script does quality-matched swap.
    local reader = surface.create_entity({
        name     = "vault-card-reader",
        position = {2, -9},
        force    = "neutral",
    })
    if reader and reader.valid then
        reader.destructible = false
    end

    rendering.draw_text{
        text          = "Insert vault access card",
        surface       = surface,
        target        = {2, -9},
        target_offset = {0, -2},
        color         = {r = 0.7, g = 0.9, b = 1.0, a = 1},
        scale         = 0.9,
        alignment     = "center",
        use_rich_text = false,
    }

    setup_depot_puzzles(surface)

    return surface
end

function aquilo.descend_to_depot(player)
    if not (player.character and player.character.valid) then return end
    local depot = aquilo.get_or_create_depot_surface()

    storage.aquilo_depot_return = storage.aquilo_depot_return or {}
    storage.aquilo_depot_return[player.index] = {
        surface  = player.surface,
        position = {x = player.position.x, y = player.position.y},
    }

    local arrival = {x = 0, y = -3}
    local valid = depot.find_non_colliding_position("character", arrival, 5, 0.5) or arrival
    player.teleport(valid, depot)
end

function aquilo.ascend_from_depot(player)
    local ret = storage.aquilo_depot_return and storage.aquilo_depot_return[player.index]
    if not ret then return end

    player.teleport(ret.position, ret.surface)
    storage.aquilo_depot_return[player.index] = nil
end

-- ─── Phase 2: elevator construction ──────────────────────────────────────────

local function complete_elevator(state)
    local ent     = state.entity
    local surface = ent.surface
    local pos     = ent.position

    -- Spill unconsumed inputs so the player doesn't lose materials
    local inv = ent.get_inventory(defines.inventory.assembling_machine_input)
    if inv and inv.valid then
        for _, item in pairs(inv.get_contents()) do
            surface.spill_item_stack{position = pos, stack = item, enable_looted = true}
        end
    end

    if state.render and state.render.valid then state.render.destroy() end
    state.render = nil

    ent.destroy()

    local completed = surface.create_entity({
        name     = "aquilo-elevator-complete",
        position = pos,
        force    = "neutral",
    })
    if completed and completed.valid then
        completed.destructible = false
    end

    state.complete = true
    state.entity   = nil

    rendering.draw_text{
        text          = "★ Elevator Complete",
        surface       = surface,
        target        = pos,
        target_offset = {0, -6},
        color         = {r = 0.4, g = 0.8, b = 1.0, a = 1},
        scale         = 1.5,
        alignment     = "center",
        time_to_live  = 36000,
    }
    game.print("[color=cyan]Elevator shaft construction complete! The Fulgoran depot awaits below.[/color]")
end

local function on_tick_59_elevator()
    local state = storage.aquilo_elevator
    if not state or state.complete then return end

    local ent = state.entity
    if not (ent and ent.valid) then
        if state.render and state.render.valid then state.render.destroy() end
        storage.aquilo_elevator = nil
        return
    end

    -- Recreate render text if invalid (doesn't survive save/load)
    if not (state.render and state.render.valid) then
        state.render = rendering.draw_text{
            text          = "",
            surface       = ent.surface,
            target        = ent,
            target_offset = {0, -4},
            color         = {r = 0.4, g = 0.8, b = 1.0, a = 1},
            scale         = 1.5,
            alignment     = "center",
            use_rich_text = true,
        }
    end

    local done = ent.products_finished
    state.render.text = {"", "[item=concrete] ", done, " / ", ELEVATOR_CYCLES}

    if done >= ELEVATOR_CYCLES then
        complete_elevator(state)
    end
end

function aquilo.register_elevator(entity)
    if storage.aquilo_elevator and not storage.aquilo_elevator.complete then
        -- Second shaft placed while one is already active — refuse and return item
        entity.destroy()
        for _, p in pairs(game.players) do
            if p.surface == entity.surface then
                p.insert({name = "aquilo-elevator-shaft", count = 1})
                break
            end
        end
        game.print("[color=orange]Only one elevator shaft can be active at a time.[/color]")
        return
    end
    storage.aquilo_elevator = {entity = entity, complete = false, render = nil}
    game.print("[color=cyan]Elevator shaft placed. Feed it concrete and steel — 100 segments to dig.[/color]")
end

function aquilo.unregister_elevator(entity)
    local state = storage.aquilo_elevator
    if not state or state.entity ~= entity then return end
    if state.render and state.render.valid then state.render.destroy() end
    storage.aquilo_elevator = nil
    game.print("[color=orange]Elevator shaft removed — construction progress lost.[/color]")
end

-- ─── Dispatcher ──────────────────────────────────────────────────────────────

function aquilo.on_tick_59()
    local scan_done = game.forces["player"].technologies["aquilo-scanning-complete"]
    if not (scan_done and scan_done.researched) then
        on_tick_59_scanning()
    else
        on_tick_59_elevator()
    end
end

return aquilo
