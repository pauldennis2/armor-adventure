-- Quest: Nauvis (Pheromone Emitter — biter defence challenge)
-- On placement: 4 invulnerable nests appear at NEST_RADIUS tiles (cardinal directions).
-- Constant trickle: every 300 ticks, TRICKLE_PER_NEST biters spawned at each nest.
-- Surge waves at 25 / 50 / 75 % charged (escalating count).
-- Three phases shift the biter type mix from mostly-big to mostly-behemoth+spitter.
-- On completion: purge pulse, reward drop, nests removed.

local nauvis = {}

local CHARGE_TICKS     = 3600   -- 1 minute (testing; production: 7200–10800)
local NEST_RADIUS      = 70     -- tiles from emitter to each nest spawn point
local TRICKLE_PER_NEST = 2      -- units per nest per 300-tick trickle
local KILL_RADIUS      = 50     -- tiles: purge radius on completion

local PHASE2_START = 0.33
local PHASE3_START = 0.66

-- Cumulative probability pools per phase.
-- Phase 1 (0–33%):  mostly big biters, a few behemoths
-- Phase 2 (33–66%): even mix, spitters begin to appear
-- Phase 3 (66–100%): behemoths dominate, heavy spitter presence
local UNIT_POOLS = {
    {{"big-biter", 0.80}, {"behemoth-biter", 1.00}},
    {{"big-biter", 0.30}, {"behemoth-biter", 0.80}, {"behemoth-spitter", 1.00}},
    {{"big-biter", 0.20}, {"behemoth-biter", 0.50}, {"behemoth-spitter", 1.00}},
}

local NEST_DIRS = {{1,0}, {-1,0}, {0,1}, {0,-1}}  -- E, W, S, N

local function pick_unit(phase)
    local r = math.random()
    for _, entry in ipairs(UNIT_POOLS[phase]) do
        if r < entry[2] then return entry[1] end
    end
    return UNIT_POOLS[phase][#UNIT_POOLS[phase]][1]
end

local function get_phase(ticks_charged)
    local pct = ticks_charged / CHARGE_TICKS
    if pct < PHASE2_START then return 1
    elseif pct < PHASE3_START then return 2
    else return 3
    end
end

-- Spawn a single biter within natural attack-detection range of the emitter.
-- set_command does not exist on LuaEntity in Factorio 2.0, so we rely on biter
-- AI to detect and attack the nearest enemy building once they're close enough.
local function spawn_unit_near(surface, emitter_pos, unit_name)
    local angle = math.random() * 2 * math.pi
    local r     = 8 + math.random() * 7   -- 8–15 tiles from emitter
    local pos   = {
        x = emitter_pos.x + math.cos(angle) * r,
        y = emitter_pos.y + math.sin(angle) * r,
    }
    local p = surface.find_non_colliding_position(unit_name, pos, 5, 0.5)
    if p then
        surface.create_entity({name = unit_name, position = p, force = "enemy"})
    end
end

local function spawn_wave(entry, count)
    local emitter = entry.entity
    if not emitter.valid then return end
    local phase = get_phase(entry.ticks_charged)
    for _ = 1, count do
        spawn_unit_near(emitter.surface, emitter.position, pick_unit(phase))
    end
end

local function spawn_nests(surface, emitter_pos)
    local nests = {}
    for _, dir in ipairs(NEST_DIRS) do
        local pos = {
            x = emitter_pos.x + dir[1] * NEST_RADIUS,
            y = emitter_pos.y + dir[2] * NEST_RADIUS,
        }
        local valid = surface.find_non_colliding_position("pheromone-emitter-nest", pos, 15, 1)
        if valid then
            local nest = surface.create_entity({
                name     = "pheromone-emitter-nest",
                position = valid,
                -- Neutral force: player turrets won't auto-target the nests,
                -- and enemy biters won't protect them. Purely decorative.
                force    = "neutral",
            })
            if nest and nest.valid then
                table.insert(nests, nest)
            end
        end
    end
    return nests
end

local function cleanup_nests(entry)
    for _, nest in ipairs(entry.nests or {}) do
        if nest.valid then nest.destroy() end
    end
end

local function complete_emitter(uid, entry)
    local entity = entry.entity
    if not entity.valid then
        cleanup_nests(entry)
        storage.pheromone_emitters[uid] = nil
        return
    end
    local pos     = entity.position
    local surface = entity.surface

    for i = 0, 7 do
        local a = i * math.pi / 4
        surface.create_entity({
            name     = "big-explosion",
            position = {pos.x + math.cos(a) * 10, pos.y + math.sin(a) * 10},
            force    = "neutral",
        })
    end
    surface.create_entity({name = "big-explosion", position = pos, force = "neutral"})

    local enemies = surface.find_entities_filtered({
        force = "enemy", position = pos, radius = KILL_RADIUS,
    })
    for _, e in pairs(enemies) do
        if e.valid then e.die() end
    end

    surface.spill_item_stack{position = pos, stack = {name = "nauvis-armor-piece", count = 1}, enable_looted = true}
    game.print("[color=yellow]Pheromone Emitter fully charged! The pulse has cleared the area — collect the Nauvis Armor Piece.[/color]")

    cleanup_nests(entry)
    entity.destroy()
    storage.pheromone_emitters[uid] = nil
end

function nauvis.register_emitter(entity, player_index)
    -- Surface_conditions on the prototype handles this at placement time,
    -- but guard here against console / script-raised placement on other surfaces.
    if entity.surface.name ~= "nauvis" then
        local p = player_index and game.players[player_index]
        if p and p.valid then
            p.insert({name = "pheromone-emitter", count = 1})
            p.print("[color=red]The Pheromone Emitter can only be deployed on Nauvis.[/color]")
        end
        entity.destroy()
        return
    end

    storage.pheromone_emitters = storage.pheromone_emitters or {}
    local nests = spawn_nests(entity.surface, entity.position)
    local entry = {
        entity        = entity,
        ticks_charged = 0,
        nests         = nests,
    }
    storage.pheromone_emitters[entity.unit_number] = entry

    -- Opening wave (phase 1: 12 big biters)
    spawn_wave(entry, 12)

    local msg = string.format(
        "[color=cyan]Pheromone Emitter placed. Defend it for %ds — biters are converging from all sides.[/color]",
        CHARGE_TICKS / 60
    )
    if player_index then
        local p = game.players[player_index]
        if p and p.valid then p.print(msg) end
    else
        game.print(msg)
    end
end

function nauvis.unregister_emitter(entity)
    if not storage.pheromone_emitters then return end
    local entry = storage.pheromone_emitters[entity.unit_number]
    if entry then
        cleanup_nests(entry)
        storage.pheromone_emitters[entity.unit_number] = nil
    end
end

function nauvis.on_emitter_destroyed(entity)
    if not storage.pheromone_emitters then return end
    local entry = storage.pheromone_emitters[entity.unit_number]
    if entry then
        cleanup_nests(entry)
        storage.pheromone_emitters[entity.unit_number] = nil
        game.print("[color=red]Pheromone Emitter destroyed — the charge has dissipated.[/color]")
    end
end

-- Called every 59 ticks by quests.lua when a player is on Nauvis and
-- armor-adventure-nauvis is researched. Zero UPS cost otherwise.
-- Trickle spawns every 5 calls (~295 ticks ≈ 5s) via per-entry spawn_counter.
function nauvis.on_tick_59()
    if not storage.pheromone_emitters or not next(storage.pheromone_emitters) then return end
    for uid, entry in pairs(storage.pheromone_emitters) do
        if not entry.entity.valid then
            cleanup_nests(entry)
            storage.pheromone_emitters[uid] = nil
        else
            entry.ticks_charged = entry.ticks_charged + 59

            entry.spawn_counter = (entry.spawn_counter or 0) + 1
            if entry.spawn_counter >= 5 then
                entry.spawn_counter = 0
                spawn_wave(entry, TRICKLE_PER_NEST * 4)
            end

            local pct = entry.ticks_charged / CHARGE_TICKS
            if pct >= 1.0 then
                complete_emitter(uid, entry)
            elseif pct >= 0.75 and not entry.notified_75 then
                entry.notified_75 = true
                spawn_wave(entry, 32)
                game.print("[color=orange]Pheromone Emitter: 75% — final wave incoming![/color]")
            elseif pct >= 0.50 and not entry.notified_50 then
                entry.notified_50 = true
                spawn_wave(entry, 24)
                game.print("[color=orange]Pheromone Emitter: halfway — hold the line![/color]")
            elseif pct >= 0.25 and not entry.notified_25 then
                entry.notified_25 = true
                spawn_wave(entry, 16)
                game.print("[color=orange]Pheromone Emitter: 25% charged — biters are swarming.[/color]")
            end
        end
    end
end

return nauvis
