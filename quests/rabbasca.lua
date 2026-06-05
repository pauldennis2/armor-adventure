-- Quest: Rabbasca (Vault Tunnels)
-- Three randomised challenge designs; selected on each entry.
-- Entry: player places vault-entry-pass → on_built_entity calls enter_tunnel(player, quality).
-- Exit:  vault-tunnel-exit GUI → exit_tunnel() returns player to surface.

local rabbasca = {}

-- ── Layout constants ──────────────────────────────────────────────────────────

local TUNNEL_SURFACE = "rabbasca-vault-tunnels"
local TUNNEL_HW      = 10    -- half-width; corridor x ∈ [-10, 9]
local TUNNEL_L       = 60    -- length; corridor y ∈ [-59, 0]
local ROOM_HW        = 16    -- room half-width; room x ∈ [-16, 15]
local ROOM_DEPTH     = 24    -- room y ∈ [-83, -60]
local NORTH_HW       = 4     -- prize corridor half-width
local NORTH_L        = 16    -- prize corridor length

local TUNNEL_Y_NORTH = -(TUNNEL_L - 1)                   -- -59
local ROOM_Y_SOUTH   = -TUNNEL_L                          -- -60  (gate row)
local ROOM_Y_NORTH   = -(TUNNEL_L + ROOM_DEPTH - 1)       -- -83
local BARRIER_Y      = ROOM_Y_NORTH - 1                   -- -84
local NORTH_Y_NORTH  = BARRIER_Y - NORTH_L                -- -100

local SPAWN_POS    = {x = 0, y = -3}
local EXIT_POS     = {x = 2, y = -3}
local MCGUFFIN_POS = {x = 0, y = NORTH_Y_NORTH + 3}      -- -97

-- Design A alcoves: 8 tiles deep into each side wall
local DA_ALCOVE_DEPTH = 8
local DA_ALCOVE_Y1    = ROOM_Y_SOUTH - 10   -- -70: south alcove pair
local DA_ALCOVE_Y2    = ROOM_Y_SOUTH - 20   -- -80: north alcove pair
local DA_LEFT_TX      = -(ROOM_HW + DA_ALCOVE_DEPTH - 1)  -- x = -23
local DA_RIGHT_TX     =   ROOM_HW - 2 + DA_ALCOVE_DEPTH   -- x =  22

-- Clearance area: covers main room + Design A alcoves
local CLEAR_X    = ROOM_HW + DA_ALCOVE_DEPTH + 2  -- 26
local CLEAR_AREA = {{-CLEAR_X, ROOM_Y_NORTH - 2}, {CLEAR_X, ROOM_Y_SOUTH + 2}}

-- ── Quality tables ────────────────────────────────────────────────────────────

local QUALITY_TIER = {normal = 1, uncommon = 2, rare = 3, epic = 4, legendary = 5}

-- For Design A gun turrets (bullet ammo category)
local VAULT_AMMO_MODIFIER = {normal = 0.0, uncommon = 0.75, rare = 1.5, epic = 2.25, legendary = 3.0}
-- For Design B laser turrets (per-entity turret modifier)
local VAULT_TURRET_MODIFIER = {normal = 0.0, uncommon = 0.75, rare = 1.5, epic = 2.25, legendary = 3.0}

-- ── Design definitions ────────────────────────────────────────────────────────

-- Shield drain = QUALITY_TIER[q] * 0.01 * design.drain_mult  (fraction of max_shield / second)
local DESIGNS = {
  A = {
    drain_mult = 1,
    entry_msg  = "[color=cyan]You enter Design A: The Bunker. Gun emplacements are dug into the side walls. Heavy support covers the far end. Shields lightly disrupted.[/color]",
  },
  B = {
    drain_mult = 3,
    entry_msg  = "[color=cyan]You enter Design B: The Laser Gauntlet. Laser turrets cover every lane in overlapping fields of fire. Severe electromagnetic interference is rapidly draining your shields.[/color]",
  },
  C = {
    drain_mult = 0,
    entry_msg  = "[color=cyan]You enter Design C: The Minefield. The floor is seeded with quality-scaled charges. Guard turrets watch the far wall. Watch your step.[/color]",
  },
  D = {
    drain_mult = 2,
    entry_msg  = "[color=cyan]Three laser clusters sweep the chamber. Their invulnerability fields cycle — only one cluster can be harmed at a time. Artillery covers the far wall. Shields moderately disrupted.[/color]",
  },
}
local DESIGN_KEYS = {"A", "B", "C", "D"}

local QUALITY_DRAIN_MSG = {
  normal    = "[color=cyan]Your shields are slowly being drained.[/color]",
  uncommon  = "[color=cyan]Your shields are being drained.[/color]",
  rare      = "[color=cyan]Your shields are quickly being drained.[/color]",
  epic      = "[color=cyan]Your shields are very quickly being drained.[/color]",
  legendary = "[color=cyan]Your shields are draining almost instantly.[/color]",
}

local PHASE_DURATION = 8  -- on_tick_60 calls per phase (= seconds)

-- Design C mine grid: 19 charges spread across the room in rows that leave narrow safe lanes.
-- Mines begin 6 tiles past the gate so the player has a moment to read the situation.
local DC_MINES = {
  {x=-13, y=ROOM_Y_SOUTH- 6}, {x= -5, y=ROOM_Y_SOUTH- 6}, {x=  3, y=ROOM_Y_SOUTH- 6}, {x= 11, y=ROOM_Y_SOUTH- 6},
  {x=-10, y=ROOM_Y_SOUTH-10}, {x= -2, y=ROOM_Y_SOUTH-10}, {x=  6, y=ROOM_Y_SOUTH-10}, {x= 13, y=ROOM_Y_SOUTH-10},
  {x=-14, y=ROOM_Y_SOUTH-14}, {x= -5, y=ROOM_Y_SOUTH-14}, {x=  3, y=ROOM_Y_SOUTH-14}, {x= 11, y=ROOM_Y_SOUTH-14},
  {x=-11, y=ROOM_Y_SOUTH-18}, {x= -3, y=ROOM_Y_SOUTH-18}, {x=  5, y=ROOM_Y_SOUTH-18}, {x= 12, y=ROOM_Y_SOUTH-18},
  {x= -8, y=ROOM_Y_SOUTH-21}, {x=  0, y=ROOM_Y_SOUTH-21}, {x=  8, y=ROOM_Y_SOUTH-21},
}

-- ── Force management ──────────────────────────────────────────────────────────

local function ensure_vault_guards_force()
  local f = game.forces["vault-guards"]
  if not f then
    f = game.create_force("vault-guards")
    game.forces.player.set_cease_fire(f, false)
    f.set_cease_fire(game.forces.player, false)
    game.forces.enemy.set_cease_fire(f, true)
    f.set_cease_fire(game.forces.enemy, true)
    game.forces.neutral.set_cease_fire(f, true)
    f.set_cease_fire(game.forces.neutral, true)
  end
  return f
end

-- ── Barrier ───────────────────────────────────────────────────────────────────

local function unlock_barrier(surface)
  local tiles = {}
  for x = -NORTH_HW, NORTH_HW - 1 do
    tiles[#tiles + 1] = {name = "refined-concrete", position = {x, BARRIER_Y}}
  end
  surface.set_tiles(tiles)
  for _, p in pairs(game.connected_players) do
    if p.surface.name == TUNNEL_SURFACE then
      p.print("[color=#FFD700]The vault barrier has fallen. Your prize awaits.[/color]")
    end
  end
end

-- ── Room management ───────────────────────────────────────────────────────────

local function clear_room_entities(surface)
  -- Turrets: gun (ammo-turret), laser/tesla (electric-turret), artillery (artillery-turret)
  for _, e in ipairs(surface.find_entities_filtered({
    type = {"ammo-turret", "electric-turret", "artillery-turret"},
    area = CLEAR_AREA,
  })) do
    if e.valid then e.destroy() end
  end
  -- Land mines
  for _, e in ipairs(surface.find_entities_filtered({name = "land-mine", area = CLEAR_AREA})) do
    if e.valid then e.destroy() end
  end
  -- Ancient Rabbit's Foote
  for _, e in ipairs(surface.find_entities_filtered({name = "ancient-rabbits-foote"})) do
    if e.valid then e.destroy() end
  end
  -- All stone walls in the clear area (gate + any bunker walls); re-placed per design
  for _, e in ipairs(surface.find_entities_filtered({name = "stone-wall", area = CLEAR_AREA})) do
    if e.valid then e.destroy() end
  end
end

local function place_gate(surface)
  for x = -ROOM_HW, ROOM_HW - 1 do
    surface.create_entity({name = "stone-wall", position = {x + 0.5, ROOM_Y_SOUTH + 0.5}, force = "neutral"})
  end
end

-- ── Per-design setup ──────────────────────────────────────────────────────────

-- Design A: four gun turrets dug into very deep side-wall alcoves, each guarded by a
-- stone-wall fire slit (1-tile gap at the turret's y). Two heavy turrets cover the back wall.
local function setup_design_A(surface, quality_name)
  local vf = ensure_vault_guards_force()
  vf.set_ammo_damage_modifier("bullet", VAULT_AMMO_MODIFIER[quality_name] or 0)

  local alcove_turrets = {
    {x = DA_LEFT_TX,  y = DA_ALCOVE_Y1},  -- x=-23, y=-70, left-south
    {x = DA_RIGHT_TX, y = DA_ALCOVE_Y1},  -- x= 22, y=-70, right-south
    {x = DA_LEFT_TX,  y = DA_ALCOVE_Y2},  -- x=-23, y=-80, left-north
    {x = DA_RIGHT_TX, y = DA_ALCOVE_Y2},  -- x= 22, y=-80, right-north
  }
  for _, pos in ipairs(alcove_turrets) do
    local t = surface.create_entity({name = "gun-turret", position = pos, force = vf, quality = quality_name})
    if t then
      local inv = t.get_inventory(defines.inventory.turret_ammo)
      if inv then inv.insert({name = "uranium-rounds-magazine", count = 200, quality = quality_name}) end
    end
  end

  -- Stone-wall fire slits at the alcove entrances (x = ±room-boundary).
  -- Two walls above and two below each turret y leave a 1-tile gap to fire through.
  for _, sx in ipairs({-ROOM_HW, ROOM_HW - 1}) do
    for _, cy in ipairs({DA_ALCOVE_Y1, DA_ALCOVE_Y2}) do
      for _, dy in ipairs({-2, -1, 1, 2}) do
        surface.create_entity({name = "stone-wall", position = {sx + 0.5, cy + dy + 0.5}, force = "neutral"})
      end
    end
  end

  -- Back-wall support turrets
  local back_turrets = {
    {x = -8, y = ROOM_Y_NORTH + 2},  -- -81
    {x =  8, y = ROOM_Y_NORTH + 2},
  }
  for _, pos in ipairs(back_turrets) do
    local t = surface.create_entity({name = "gun-turret", position = pos, force = vf, quality = quality_name})
    if t then
      local inv = t.get_inventory(defines.inventory.turret_ammo)
      if inv then inv.insert({name = "uranium-rounds-magazine", count = 200, quality = quality_name}) end
    end
  end

  storage.vault_turret_count = #alcove_turrets + #back_turrets  -- 6
end

-- Design B: six vault-laser-turrets (void-powered) in two staggered rows, creating
-- overlapping lanes of fire across the full room width. Heavy shield drain (×3).
local function setup_design_B(surface, quality_name)
  local vf = ensure_vault_guards_force()
  vf.set_turret_attack_modifier("vault-laser-turret", VAULT_TURRET_MODIFIER[quality_name] or 0)

  local laser_turrets = {
    -- Row 1 (y = -68): three turrets spread across the room
    {x = -11, y = ROOM_Y_SOUTH -  8},
    {x =  -2, y = ROOM_Y_SOUTH -  8},
    {x =   9, y = ROOM_Y_SOUTH -  8},
    -- Row 2 (y = -76): offset from row 1 to create overlapping crossfire
    {x = -14, y = ROOM_Y_SOUTH - 16},
    {x =   1, y = ROOM_Y_SOUTH - 16},
    {x =  12, y = ROOM_Y_SOUTH - 16},
  }
  local count = 0
  for _, pos in ipairs(laser_turrets) do
    local t = surface.create_entity({name = "vault-laser-turret", position = pos, force = vf, quality = quality_name})
    if t then count = count + 1 end
  end
  storage.vault_turret_count = count
end

-- Design C: the room is mined. 19 quality-scaled land charges are laid in a
-- navigable-but-dangerous grid. Two gun turrets at the back wall are the actual
-- barrier-unlock condition — killing them opens the prize corridor.
local function setup_design_C(surface, quality_name)
  local vf = ensure_vault_guards_force()
  vf.set_ammo_damage_modifier("bullet", VAULT_AMMO_MODIFIER[quality_name] or 0)

  for _, pos in ipairs(DC_MINES) do
    surface.create_entity({name = "land-mine", position = pos, force = vf, quality = quality_name})
  end

  local back_turrets = {
    {x = -8, y = ROOM_Y_NORTH + 2},
    {x =  8, y = ROOM_Y_NORTH + 2},
  }
  local count = 0
  for _, pos in ipairs(back_turrets) do
    local t = surface.create_entity({name = "gun-turret", position = pos, force = vf, quality = quality_name})
    if t then
      local inv = t.get_inventory(defines.inventory.turret_ammo)
      if inv then inv.insert({name = "uranium-rounds-magazine", count = 200, quality = quality_name}) end
      count = count + 1
    end
  end
  storage.vault_turret_count = count
end

-- Design D: three pairs of vault-laser-turrets arranged in left/center/right columns.
-- A rotating invulnerability field cycles through each pair every PHASE_DURATION seconds —
-- only the currently exposed cluster has destructible=true; the others ignore all damage.
-- An artillery turret at the back wall provides constant long-range pressure.
-- Killing all 6 laser turrets opens the barrier; the artillery turret does not count.
local function setup_design_D(surface, quality_name)
  local vf = ensure_vault_guards_force()
  vf.set_turret_attack_modifier("vault-laser-turret", VAULT_TURRET_MODIFIER[quality_name] or 0)

  -- Three columns (left / center / right), two turrets each (front and mid row)
  local group_positions = {
    {{x = -10, y = ROOM_Y_SOUTH -  8}, {x = -10, y = ROOM_Y_SOUTH - 16}},  -- left
    {{x =   0, y = ROOM_Y_SOUTH -  8}, {x =   0, y = ROOM_Y_SOUTH - 16}},  -- center
    {{x =  10, y = ROOM_Y_SOUTH -  8}, {x =  10, y = ROOM_Y_SOUTH - 16}},  -- right
  }

  local stored_groups = {}
  local total_count   = 0

  for _, positions in ipairs(group_positions) do
    local group = {}
    for _, pos in ipairs(positions) do
      local t = surface.create_entity({name = "vault-laser-turret", position = pos, force = vf, quality = quality_name})
      if t then
        t.destructible    = false  -- invulnerable until its phase
        group[#group + 1] = t
        total_count       = total_count + 1
      end
    end
    stored_groups[#stored_groups + 1] = group
  end

  -- Phase 1 (left cluster) is exposed from the start
  for _, e in ipairs(stored_groups[1]) do
    if e.valid then e.destructible = true end
  end

  -- Artillery at back wall center; does not count toward barrier condition
  local art = surface.create_entity({
    name     = "vault-artillery-turret",
    position = {x = 0, y = ROOM_Y_NORTH + 3},
    force    = vf,
    quality  = quality_name,
  })
  if art then
    local inv = art.get_inventory(defines.inventory.artillery_turret_ammo)
    if inv then inv.insert({name = "artillery-shell", count = 200}) end
  end

  storage.vault_turret_count = total_count
  storage.vault_phase_groups = stored_groups
  storage.vault_phase        = 1
  storage.vault_phase_timer  = 0
end

local function setup_challenge_room(surface, quality_name, design)
  quality_name = quality_name or "normal"
  design       = design or "A"

  -- Clear Design D phase state from any previous run
  storage.vault_phase_groups = nil
  storage.vault_phase        = nil
  storage.vault_phase_timer  = nil

  -- Lock barrier for new run
  local barrier_tiles = {}
  for x = -NORTH_HW, NORTH_HW - 1 do
    barrier_tiles[#barrier_tiles + 1] = {name = "out-of-map", position = {x, BARRIER_Y}}
  end
  surface.set_tiles(barrier_tiles)

  clear_room_entities(surface)
  place_gate(surface)

  if     design == "A" then setup_design_A(surface, quality_name)
  elseif design == "B" then setup_design_B(surface, quality_name)
  elseif design == "D" then setup_design_D(surface, quality_name)
  else                       setup_design_C(surface, quality_name)
  end

  surface.create_entity({name = "ancient-rabbits-foote", position = MCGUFFIN_POS, force = "neutral"})
end

-- ── Surface management ────────────────────────────────────────────────────────

local function setup_tunnel_surface(surface)
  surface.request_to_generate_chunks({0, 0}, 5)
  surface.force_generate_chunk_requests()

  -- Pass 1: fill bounding box with out-of-map (includes room + DA alcoves + prize corridor)
  local background = {}
  for x = -(ROOM_HW + DA_ALCOVE_DEPTH + 2), ROOM_HW - 1 + DA_ALCOVE_DEPTH + 2 do
    for y = NORTH_Y_NORTH - 2, 2 do
      background[#background + 1] = {name = "out-of-map", position = {x, y}}
    end
  end
  surface.set_tiles(background)

  -- Pass 2: carve out playable floor
  local floor = {}
  -- Tunnel
  for x = -TUNNEL_HW, TUNNEL_HW - 1 do
    for y = TUNNEL_Y_NORTH, 0 do
      floor[#floor + 1] = {name = "refined-concrete", position = {x, y}}
    end
  end
  -- Main room
  for x = -ROOM_HW, ROOM_HW - 1 do
    for y = ROOM_Y_NORTH, ROOM_Y_SOUTH do
      floor[#floor + 1] = {name = "refined-concrete", position = {x, y}}
    end
  end
  -- Design A side-wall alcoves (always present; unused by B/C)
  for _, yc in ipairs({DA_ALCOVE_Y1, DA_ALCOVE_Y2}) do
    for depth = 1, DA_ALCOVE_DEPTH do
      for dy = -2, 2 do
        floor[#floor + 1] = {name = "refined-concrete", position = {-ROOM_HW - depth,    yc + dy}}
        floor[#floor + 1] = {name = "refined-concrete", position = { ROOM_HW - 1 + depth, yc + dy}}
      end
    end
  end
  -- Prize corridor (BARRIER_Y row stays out-of-map until unlocked)
  for x = -NORTH_HW, NORTH_HW - 1 do
    for y = NORTH_Y_NORTH, BARRIER_Y - 1 do
      floor[#floor + 1] = {name = "refined-concrete", position = {x, y}}
    end
  end
  surface.set_tiles(floor)

  surface.create_entity({name = "vault-tunnel-exit", position = EXIT_POS, force = "player"})
end

local function get_or_create_tunnel_surface()
  local surface = game.surfaces[TUNNEL_SURFACE]
  if not surface then
    surface = game.create_surface(TUNNEL_SURFACE, {
      peaceful_mode = true,
      autoplace_settings = {
        entity     = {treat_missing_as_default = false, settings = {}},
        decorative = {treat_missing_as_default = false, settings = {}},
        tile       = {treat_missing_as_default = false, settings = {}},
      },
      cliff_settings = {cliff_elevation_0 = 1024, cliff_elevation_interval = 1024},
    })
    setup_tunnel_surface(surface)
  else
    -- Migrate: north prize corridor
    if surface.get_tile(0, NORTH_Y_NORTH + 1).name ~= "refined-concrete" then
      local floor = {}
      for x = -NORTH_HW, NORTH_HW - 1 do
        for y = NORTH_Y_NORTH, BARRIER_Y - 1 do
          floor[#floor + 1] = {name = "refined-concrete", position = {x, y}}
        end
      end
      surface.set_tiles(floor)
    end
    -- Migrate: Design A deep alcoves
    if surface.get_tile(-ROOM_HW - DA_ALCOVE_DEPTH, DA_ALCOVE_Y1).name ~= "refined-concrete" then
      local alcove_tiles = {}
      for _, yc in ipairs({DA_ALCOVE_Y1, DA_ALCOVE_Y2}) do
        for depth = 1, DA_ALCOVE_DEPTH do
          for dy = -2, 2 do
            alcove_tiles[#alcove_tiles + 1] = {name = "refined-concrete", position = {-ROOM_HW - depth,    yc + dy}}
            alcove_tiles[#alcove_tiles + 1] = {name = "refined-concrete", position = { ROOM_HW - 1 + depth, yc + dy}}
          end
        end
      end
      surface.set_tiles(alcove_tiles)
    end
  end
  surface.freeze_daytime = true
  surface.daytime = 0
  return surface
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- origin_surface / origin_position come from the portal entity, not the player.
-- Using the entity's surface/position ensures the player is returned to where they
-- placed the portal (Rabbasca), even if their LuaPlayer.surface hasn't updated yet
-- (e.g. a warp was in progress when the portal was placed).
function rabbasca.enter_tunnel(player, quality_name, origin_surface, origin_position)
  quality_name = quality_name or "normal"
  if not (player and player.valid and player.character) then return end
  local surface = get_or_create_tunnel_surface()

  local design = "D"
  storage.vault_tunnel_return[player.index] = {
    position = origin_position or {x = player.position.x, y = player.position.y},
    surface  = origin_surface  or player.surface,
    quality  = quality_name,
    design   = design,
  }
  setup_challenge_room(surface, quality_name, design)
  player.teleport(SPAWN_POS, surface)

  local d = DESIGNS[design]
  player.print(d.entry_msg)
  if d.drain_mult > 0 then
    player.print(QUALITY_DRAIN_MSG[quality_name] or QUALITY_DRAIN_MSG.normal)
  end
end

function rabbasca.exit_tunnel(player)
  if not (player and player.valid) then return end
  local ret = storage.vault_tunnel_return and storage.vault_tunnel_return[player.index]
  if not ret then
    player.teleport({0, 0}, game.surfaces["nauvis"] or game.surfaces[1])
    return
  end
  local ret_surface = ret.surface
  if not (ret_surface and ret_surface.valid) then
    ret_surface = game.surfaces["nauvis"] or game.surfaces[1]
  end
  player.teleport(ret.position, ret_surface)
  storage.vault_tunnel_return[player.index] = nil

  -- Restore shields to full — the vault drained them, the least we can do
  if player.character and player.character.grid then
    for _, equip in pairs(player.character.grid.equipment) do
      if equip.type == "energy-shield-equipment" then
        equip.shield = equip.max_shield
      end
    end
  end
end

-- Called from quests.lua on_entity_died for gun-turret and vault-laser-turret.
function rabbasca.on_turret_died(entity)
  if entity.surface.name ~= TUNNEL_SURFACE then return end
  if not storage.vault_turret_count or storage.vault_turret_count <= 0 then return end
  storage.vault_turret_count = storage.vault_turret_count - 1
  if storage.vault_turret_count <= 0 then
    unlock_barrier(entity.surface)
  end
end

-- Called from control.lua on_nth_tick(60).
-- Drain rate = quality_tier * 1% * design.drain_mult  per second.
-- Also advances the Design D phase rotation every PHASE_DURATION calls.
function rabbasca.on_tick_60()
  local surface = game.surfaces[TUNNEL_SURFACE]
  if not (surface and surface.valid) then return end

  -- Shield drain
  for _, player in pairs(game.connected_players) do
    if player.surface == surface and player.character then
      local ret        = storage.vault_tunnel_return and storage.vault_tunnel_return[player.index]
      local quality    = ret and ret.quality or "normal"
      local design     = ret and ret.design  or "A"
      local tier       = QUALITY_TIER[quality] or 1
      local mult       = DESIGNS[design] and DESIGNS[design].drain_mult or 1
      local drain_pct  = tier * 0.01 * mult
      if drain_pct > 0 then
        local grid = player.character.grid
        if grid then
          for _, equip in pairs(grid.equipment) do
            if equip.type == "energy-shield-equipment" then
              equip.shield = math.max(0, equip.shield - equip.max_shield * drain_pct)
            end
          end
        end
      end
    end
  end

  -- Design D phase rotation: only runs while turrets remain and phase state is set
  if storage.vault_phase_groups and (storage.vault_turret_count or 0) > 0 then
    storage.vault_phase_timer = (storage.vault_phase_timer or 0) + 1
    if storage.vault_phase_timer >= PHASE_DURATION then
      storage.vault_phase_timer = 0
      local groups   = storage.vault_phase_groups
      local n_phases = #groups

      -- Lock all groups
      for _, group in ipairs(groups) do
        for _, e in ipairs(group) do
          if e.valid then e.destructible = false end
        end
      end

      -- Advance to next phase, wrapping around
      storage.vault_phase = (storage.vault_phase % n_phases) + 1

      -- Unlock the new phase's living turrets
      for _, e in ipairs(groups[storage.vault_phase]) do
        if e.valid then e.destructible = true end
      end

      -- Announce phase to any player in the vault
      local phase_labels = {
        "[color=#FF6666]Left cluster vulnerable.[/color]",
        "[color=#FF6666]Center cluster vulnerable.[/color]",
        "[color=#FF6666]Right cluster vulnerable.[/color]",
      }
      local msg = phase_labels[storage.vault_phase] or "[color=#FF6666]Phase shift.[/color]"
      for _, p in pairs(game.connected_players) do
        if p.surface and p.surface.name == TUNNEL_SURFACE then
          p.print(msg)
        end
      end
    end
  end
end

-- Fill newly generated chunks with out-of-map to prevent Nauvis terrain bleeding in.
function rabbasca.on_chunk_generated(event)
  if event.surface.name ~= TUNNEL_SURFACE then return end
  local area  = event.area
  local tiles = {}
  for x = area.left_top.x, area.right_bottom.x - 1 do
    for y = area.left_top.y, area.right_bottom.y - 1 do
      tiles[#tiles + 1] = {name = "out-of-map", position = {x, y}}
    end
  end
  if #tiles > 0 then
    event.surface.set_tiles(tiles, true)
  end
end

return rabbasca
