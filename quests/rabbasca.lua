-- Quest: Rabbasca (Vault Tunnels)
-- Entry: player places a vault-entry-pass item (place_result = vault-entry-portal).
-- on_built_entity for vault-entry-portal (in quests.lua) calls enter_tunnel(player, quality_name).
-- Exit: vault-tunnel-exit entity in the tunnel opens a GUI with a "Return" button
-- handled in control.lua, which calls exit_tunnel().

local rabbasca = {}

local TUNNEL_SURFACE = "rabbasca-vault-tunnels"
local TUNNEL_HW      = 10   -- half-width; corridor spans x in [-10, 9]
local TUNNEL_L       = 60   -- length; floor spans y in [-59, 0]
local ROOM_HW        = 16   -- room half-width; room spans x in [-16, 15]
local ROOM_DEPTH     = 24   -- room depth (tiles north of tunnel end)

local TUNNEL_Y_NORTH = -(TUNNEL_L - 1)                   -- -59
local ROOM_Y_SOUTH   = -TUNNEL_L                          -- -60: gate row
local ROOM_Y_NORTH   = -(TUNNEL_L + ROOM_DEPTH - 1)       -- -83

local SPAWN_POS    = {x = 0, y = -3}
local EXIT_POS     = {x = 2, y = -3}
local MCGUFFIN_POS = {x = 0, y = ROOM_Y_NORTH + 3}       -- y = -80

local TURRET_POSITIONS = {
  {x = -12, y = ROOM_Y_SOUTH -  5},   -- y = -65, SW
  {x =  12, y = ROOM_Y_SOUTH -  5},   -- y = -65, SE
  {x = -12, y = ROOM_Y_SOUTH - 15},   -- y = -75, NW
  {x =  12, y = ROOM_Y_SOUTH - 15},   -- y = -75, NE
}

-- Reset the gate, turrets, and mcguffin for a new run at the given quality.
-- Called every entry so difficulty and reward always reflect the key used.
local function setup_challenge_room(surface, quality_name)
  quality_name = quality_name or "normal"

  -- Clear old turrets inside the room
  for _, e in ipairs(surface.find_entities_filtered({
    type = "gun-turret",
    area = {{-ROOM_HW - 2, ROOM_Y_NORTH - 2}, {ROOM_HW + 2, ROOM_Y_SOUTH + 2}},
  })) do
    if e.valid then e.destroy() end
  end

  -- Clear the old mcguffin
  for _, e in ipairs(surface.find_entities_filtered({name = "rabbit-mcguffin"})) do
    if e.valid then e.destroy() end
  end

  -- Remove and replace gate walls (restores walls breached in a prior run)
  for _, e in ipairs(surface.find_entities_filtered({
    name = "stone-wall",
    area = {{-ROOM_HW - 1, ROOM_Y_SOUTH - 1}, {ROOM_HW + 1, ROOM_Y_SOUTH + 1}},
  })) do
    if e.valid then e.destroy() end
  end
  for x = -ROOM_HW, ROOM_HW - 1 do
    surface.create_entity({name = "stone-wall", position = {x + 0.5, ROOM_Y_SOUTH + 0.5}, force = "neutral"})
  end

  -- Place quality-scaled turrets
  for _, pos in ipairs(TURRET_POSITIONS) do
    local turret = surface.create_entity({name = "gun-turret", position = pos, force = "enemy", quality = quality_name})
    if turret then
      local inv = turret.get_inventory(defines.inventory.turret_ammo)
      if inv then inv.insert({name = "firearm-magazine", count = 100}) end
    end
  end

  -- Mcguffin entity (reward quality is set by the mining handler in quests.lua)
  surface.create_entity({name = "rabbit-mcguffin", position = MCGUFFIN_POS, force = "neutral"})
end

local function setup_tunnel_surface(surface)
  surface.request_to_generate_chunks({0, 0}, 5)
  surface.force_generate_chunk_requests()

  -- Pass 1: fill bounding box with out-of-map
  local background = {}
  for x = -(ROOM_HW + 2), ROOM_HW + 1 do
    for y = ROOM_Y_NORTH - 2, 2 do
      background[#background + 1] = {name = "out-of-map", position = {x, y}}
    end
  end
  surface.set_tiles(background)

  -- Pass 2: carve out playable floor
  local floor = {}
  for x = -TUNNEL_HW, TUNNEL_HW - 1 do
    for y = TUNNEL_Y_NORTH, 0 do
      floor[#floor + 1] = {name = "refined-concrete", position = {x, y}}
    end
  end
  for x = -ROOM_HW, ROOM_HW - 1 do
    for y = ROOM_Y_NORTH, ROOM_Y_SOUTH do
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
  end
  -- Freeze at night for a dark underground look. Applied every call so saves
  -- created before this setting was added are migrated automatically.
  surface.freeze_daytime = true
  surface.daytime = 0
  return surface
end

function rabbasca.enter_tunnel(player, quality_name)
  quality_name = quality_name or "normal"
  if not (player and player.valid and player.character) then return end
  local surface = get_or_create_tunnel_surface()
  storage.vault_tunnel_return[player.index] = {
    position = {x = player.position.x, y = player.position.y},
    surface  = player.surface,
    quality  = quality_name,
  }
  setup_challenge_room(surface, quality_name)
  player.teleport(SPAWN_POS, surface)
  player.print("[color=cyan]You descend into the vault tunnels. The exit elevator is just to your right. Breach the gate at the far end to claim your prize.[/color]")
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
end

-- Fill any newly generated chunk on the tunnel surface with out-of-map to
-- prevent Nauvis terrain from appearing beyond the handcrafted layout.
function rabbasca.on_chunk_generated(event)
  if event.surface.name ~= TUNNEL_SURFACE then return end
  local area = event.area
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
