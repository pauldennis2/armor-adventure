require("quests")

local ARMOR_NAME = "mech-armor-mk2"

-- Forward declarations for personal beacon functions defined later in this file.
local create_personal_beacon
local destroy_personal_beacon
local sync_personal_beacon

-- Tech effects apply to the whole force. When the armor is NOT worn, we apply
-- an equal and opposite penalty per-character so the net bonus is zero.
-- When the armor IS worn, no penalty — the player gets the full tech bonus.
local ARMOR_BONUSES = {
  {tech = "mech-armor-mk2-running-speed", prop = "character_running_speed_modifier", value = 1.0},
}

local function has_tech(player, tech_name)
  local tech = player.force.technologies[tech_name]
  return tech ~= nil and tech.researched
end

local function is_wearing_mk2(player)
  local inv = player.get_inventory(defines.inventory.character_armor)
  if not inv then return false end
  local slot = inv[1]
  return slot and slot.valid_for_read and slot.name == ARMOR_NAME
end

local function sync_player_bonuses(player)
  if not player or not player.valid or not player.character then return end
  local wearing = is_wearing_mk2(player)
  local penalties = storage.mk2_penalties[player.index]

  for _, bonus in pairs(ARMOR_BONUSES) do
    local should_penalize = has_tech(player, bonus.tech) and not wearing
    local is_penalized = penalties[bonus.tech]

    if should_penalize and not is_penalized then
      player.character[bonus.prop] = player.character[bonus.prop] - bonus.value
      penalties[bonus.tech] = true
    elseif not should_penalize and is_penalized then
      player.character[bonus.prop] = player.character[bonus.prop] + bonus.value
      penalties[bonus.tech] = nil
    end
  end
end

local function init_storage()
  storage.mk2_penalties      = storage.mk2_penalties or {}
  storage.roboport_cooldowns = storage.roboport_cooldowns or {}
  storage.personal_beacons   = storage.personal_beacons or {}
  storage.pocket_dim_return  = storage.pocket_dim_return or {}
  for _, player in pairs(game.players) do
    storage.mk2_penalties[player.index]      = storage.mk2_penalties[player.index] or {}
    storage.roboport_cooldowns[player.index] = storage.roboport_cooldowns[player.index] or {}
    storage.personal_beacons[player.index]   = storage.personal_beacons[player.index]
    storage.pocket_dim_return[player.index]  = storage.pocket_dim_return[player.index]
  end
end

script.on_init(function()
  storage.mk2_penalties      = {}
  storage.roboport_cooldowns = {}
  storage.personal_beacons   = {}
  storage.pocket_dim_return  = {}
end)

script.on_configuration_changed(function(data)
  init_storage()

  -- When our mod itself changes, wipe existing pocket dimension surfaces so they
  -- get rebuilt with the corrected map-gen settings on next entry.
  if data and data.mod_changes and data.mod_changes["armor-adventure"] then
    local safe_surface = game.surfaces["nauvis"] or game.surfaces[1]
    for _, player in pairs(game.players) do
      local name = "pocket-dimension-" .. player.index
      local surface = game.surfaces[name]
      if surface then
        for _, p in pairs(game.players) do
          if p.surface == surface then
            p.teleport({0, 0}, safe_surface)
          end
        end
        game.delete_surface(surface)
        storage.pocket_dim_return[player.index] = nil
      end
    end
  end

  for _, player in pairs(game.players) do
    sync_player_bonuses(player)
    sync_personal_beacon(player)
  end
end)

script.on_event(defines.events.on_player_created, function(event)
  storage.mk2_penalties[event.player_index]      = {}
  storage.roboport_cooldowns[event.player_index] = {}
  storage.personal_beacons[event.player_index]   = nil
  storage.pocket_dim_return[event.player_index]  = nil
end)

script.on_event(defines.events.on_player_armor_inventory_changed, function(event)
  local player = game.players[event.player_index]
  storage.mk2_penalties[player.index] = storage.mk2_penalties[player.index] or {}
  sync_player_bonuses(player)
  sync_personal_beacon(player)
end)

script.on_event(defines.events.on_research_finished, function(event)
  for _, bonus in pairs(ARMOR_BONUSES) do
    if event.research.name == bonus.tech then
      for _, player in pairs(event.research.force.players) do
        sync_player_bonuses(player)
      end
      return
    end
  end
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.players[event.player_index]
  sync_player_bonuses(player)
  sync_personal_beacon(player)
end)

-- Unique equipment enforcement --

local PERSONAL_BEACON_EQUIP  = "personal-beacon-equipment"
local PERSONAL_BEACON_ENTITY = "personal-beacon"

-- Maps equipment name to a uniqueness group. Only one item per group may be equipped.
local UNIQUE_EQUIPMENT = {
  ["regenerative-plating"]                = "regenerative-plating",
  ["personal-combat-roboport"]            = "combat-roboport",
  ["personal-combat-roboport-distractor"] = "combat-roboport",
  ["personal-combat-roboport-destroyer"]  = "combat-roboport",
  [PERSONAL_BEACON_EQUIP]                 = PERSONAL_BEACON_EQUIP,
  ["pocket-dimension-generator"]          = "pocket-dimension-generator",
  ["personal-tesla-turret"]               = "personal-tesla-turret",
}

-- Display name used in the rejection message, keyed by group.
local UNIQUE_GROUP_LABEL = {
  ["regenerative-plating"]        = {"item-name.regenerative-plating"},
  ["combat-roboport"]             = {"armor-adventure.group-combat-roboport"},
  [PERSONAL_BEACON_EQUIP]         = {"item-name." .. PERSONAL_BEACON_EQUIP},
  ["pocket-dimension-generator"]  = {"item-name.pocket-dimension-generator"},
  ["personal-tesla-turret"]       = {"item-name.personal-tesla-turret"},
}

local function find_player_for_grid(grid)
  for _, player in pairs(game.players) do
    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if armor_inv then
      local armor = armor_inv[1]
      if armor and armor.valid_for_read and armor.grid == grid then
        return player
      end
    end
  end
end

script.on_event(defines.events.on_equipment_inserted, function(event)
  local eq_name = event.equipment.name
  local group   = UNIQUE_EQUIPMENT[eq_name]
  local grid    = event.grid or event.equipment.grid

  -- Enforce uniqueness group
  if group then
    local count = 0
    for _, eq in pairs(grid.equipment) do
      if UNIQUE_EQUIPMENT[eq.name] == group then count = count + 1 end
    end
    if count > 1 then
      local quality = event.equipment.quality
      grid.take({equipment = event.equipment})
      local player = find_player_for_grid(grid)
      if player then
        player.insert({name = eq_name, count = 1, quality = quality.name})
        player.print({"armor-adventure.unique-equipment-limit", UNIQUE_GROUP_LABEL[group]})
      end
      return
    end
  end

  -- Spawn personal beacon when its equipment is inserted
  if eq_name == PERSONAL_BEACON_EQUIP then
    local player = find_player_for_grid(grid)
    if player then create_personal_beacon(player) end
  end
end)

script.on_event(defines.events.on_equipment_removed, function(event)
  local eq = event.equipment
  local name = type(eq) == "string" and eq or eq.name
  if name ~= PERSONAL_BEACON_EQUIP then return end
  local player = find_player_for_grid(event.grid)
  if player then sync_personal_beacon(player) end
end)

-- Personal Combat Roboport --

local COMBAT_ROBOPORT_TECH    = "personal-combat-roboport"
local ROBOPORT_COOLDOWN_TICKS = 1800  -- 30s after a spawn
local ROBOPORT_RETRY_TICKS    = 300   -- 5s after a check that found nothing

-- Maps equipment name to the bot entity it spawns
local COMBAT_ROBOPORT_BOTS = {
  ["personal-combat-roboport"]            = "defender",
  ["personal-combat-roboport-distractor"] = "distractor",
  ["personal-combat-roboport-destroyer"]  = "destroyer",
}

local ROBOPORT_STATS = {
  normal    = {count = 2, range = 20, duration = 20 * 60},
  uncommon  = {count = 3, range = 26, duration = 26 * 60},
  rare      = {count = 4, range = 32, duration = 32 * 60},
  epic      = {count = 5, range = 38, duration = 38 * 60},
  legendary = {count = 7, range = 50, duration = 50 * 60},
}

local function spawn_bots(player, bot_name, quality_name)
  local surface = player.surface
  local count   = ROBOPORT_STATS[quality_name].count
  for i = 1, count do
    local pos = {
      x = player.position.x + math.random(-2, 2),
      y = player.position.y + math.random(-2, 2),
    }
    local robot = surface.create_entity({
      name = bot_name, position = pos, force = player.force, quality = quality_name,
    })
    if robot and robot.valid then
      robot.time_to_live = ROBOPORT_STATS[quality_name].duration
      robot.combat_robot_owner = player.character
    end
  end
end

-- Poll frequently so the roboport reacts quickly; cooldown is tracked in storage.
script.on_nth_tick(30, function()
  local tick = game.tick
  for _, player in pairs(game.players) do
    if not player.character then goto continue end
    if not has_tech(player, COMBAT_ROBOPORT_TECH) then goto continue end

    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if not armor_inv then goto continue end
    local armor = armor_inv[1]
    if not armor or not armor.valid_for_read then goto continue end
    local grid = armor.grid
    if not grid then goto continue end

    local next_check = storage.roboport_cooldowns[player.index]
    if not next_check then goto continue end

    for _, equipment in pairs(grid.equipment) do
      local bot_name = COMBAT_ROBOPORT_BOTS[equipment.name]
      if not bot_name then goto next_eq end

      if tick < (next_check[equipment.name] or 0) then goto next_eq end

      local quality_name  = equipment.quality.name
      local stats         = ROBOPORT_STATS[quality_name] or ROBOPORT_STATS.normal
      local nearest_enemy = player.surface.find_nearest_enemy({
        position     = player.position,
        max_distance = stats.range,
        force        = player.force,
      })
      if nearest_enemy then
        spawn_bots(player, bot_name, quality_name)
        next_check[equipment.name] = tick + ROBOPORT_COOLDOWN_TICKS
      else
        next_check[equipment.name] = tick + ROBOPORT_RETRY_TICKS
      end

      ::next_eq::
    end

    ::continue::
  end
end)

-- Personal Beacon --

local function has_personal_beacon_equip(player)
  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  if not armor_inv then return false end
  local armor = armor_inv[1]
  if not armor or not armor.valid_for_read then return false end
  local grid = armor.grid
  if not grid then return false end
  for _, eq in pairs(grid.equipment) do
    if eq.name == PERSONAL_BEACON_EQUIP then return true end
  end
  return false
end

destroy_personal_beacon = function(player)
  local beacon = storage.personal_beacons[player.index]
  storage.personal_beacons[player.index] = nil
  if not beacon or not beacon.valid then return end
  local inv = beacon.get_module_inventory()
  if inv then
    for i = 1, #inv do
      local stack = inv[i]
      if stack.valid_for_read then
        player.insert({name = stack.name, count = stack.count, quality = stack.quality.name})
      end
    end
  end
  beacon.destroy()
end

create_personal_beacon = function(player)
  local beacon = player.surface.create_entity({
    name     = PERSONAL_BEACON_ENTITY,
    position = {x = player.position.x, y = player.position.y - 1},
    force    = player.force,
  })
  storage.personal_beacons[player.index] = beacon
end

sync_personal_beacon = function(player)
  if not player or not player.valid then return end
  local has_eq     = player.character and has_personal_beacon_equip(player)
  local beacon     = storage.personal_beacons[player.index]
  local has_beacon = beacon and beacon.valid
  if has_eq and not has_beacon then
    create_personal_beacon(player)
  elseif not has_eq and has_beacon then
    destroy_personal_beacon(player)
  end
end


-- Pocket Dimension --

local PD_HALF   = 32  -- interior half-width; playable area is 64×64 tiles
local PDG_EQUIP = "pocket-dimension-generator"

local function has_pocket_generator(player)
  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  if not armor_inv then return false end
  local armor = armor_inv[1]
  if not armor or not armor.valid_for_read then return false end
  local grid = armor.grid
  if not grid then return false end
  for _, eq in pairs(grid.equipment) do
    if eq.name == PDG_EQUIP then return true end
  end
  return false
end

local function pocket_surface_name(player)
  return "pocket-dimension-" .. player.index
end

local function is_in_pocket_dimension(player)
  return player.surface.name == pocket_surface_name(player)
end

local function setup_pocket_surface(surface)
  local H = PD_HALF

  -- set_tiles only works on already-generated chunks. Force-generate the
  -- 4×4 chunk area that covers our ±(H+2) tile boundary before writing tiles.
  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()

  local tiles = {}

  -- Main floor: lab-dark-2, 64×64 centered at origin
  for x = -H, H - 1 do
    for y = -H, H - 1 do
      tiles[#tiles + 1] = {name = "lab-dark-2", position = {x, y}}
    end
  end

  -- Exit approach markers: two bright tiles at the south-center gap,
  -- last row of the interior, so the player can see where to walk out.
  tiles[#tiles + 1] = {name = "tutorial-grid", position = {-1, H - 1}}
  tiles[#tiles + 1] = {name = "tutorial-grid", position = { 0, H - 1}}

  -- Out-of-map boundary (1 tile thick) blocks all four sides.
  -- South row: gap at x = -1 and x = 0 so the player can step through.
  for x = -(H + 2), H + 1 do
    local t = (x == -1 or x == 0) and "lab-dark-2" or "out-of-map"
    tiles[#tiles + 1] = {name = t, position = {x, H}}
  end
  -- North row
  for x = -(H + 2), H + 1 do
    tiles[#tiles + 1] = {name = "out-of-map", position = {x, -(H + 1)}}
  end
  -- West column
  for y = -H, H - 1 do
    tiles[#tiles + 1] = {name = "out-of-map", position = {-(H + 1), y}}
  end
  -- East column
  for y = -H, H - 1 do
    tiles[#tiles + 1] = {name = "out-of-map", position = {H, y}}
  end

  surface.set_tiles(tiles)
end

local function get_or_create_pocket_surface(player)
  local name = pocket_surface_name(player)
  local surface = game.surfaces[name]
  if not surface then
    surface = game.create_surface(name, {
      peaceful_mode = true,
      -- Suppress all resource, decorative, and tile autoplace so the surface
      -- generates clean rather than inheriting planetary terrain.
      autoplace_settings = {
        entity    = {treat_missing_as_default = false, settings = {}},
        decorative = {treat_missing_as_default = false, settings = {}},
        tile      = {treat_missing_as_default = false, settings = {}},
      },
      cliff_settings = {cliff_elevation_0 = 1024, cliff_elevation_interval = 1024},
    })
    setup_pocket_surface(surface)
  end
  return surface
end

local function exit_pocket_dimension(player)
  if not is_in_pocket_dimension(player) then return end
  if not has_pocket_generator(player) then
    player.print({"armor-adventure.pocket-dimension-no-generator"})
    player.teleport({0, PD_HALF - 2}, player.surface)
    return
  end
  local ret = storage.pocket_dim_return[player.index]
  if not ret then return end
  player.teleport(ret.position, ret.surface)
  storage.pocket_dim_return[player.index] = nil
  player.set_shortcut_toggled("pocket-dimension-toggle", false)
end

local function enter_pocket_dimension(player)
  if not player.character then return end
  if not has_tech(player, "pocket-dimension") then
    player.print({"armor-adventure.pocket-dimension-locked"})
    return
  end
  if not has_pocket_generator(player) then
    player.print({"armor-adventure.pocket-dimension-no-generator"})
    return
  end
  if is_in_pocket_dimension(player) then return end

  storage.pocket_dim_return[player.index] = {
    position = {x = player.position.x, y = player.position.y},
    surface  = player.surface,
  }
  local surface = get_or_create_pocket_surface(player)
  player.teleport({0, PD_HALF - 4}, surface)
  player.set_shortcut_toggled("pocket-dimension-toggle", true)
end

local function handle_pocket_dimension_toggle(player)
  if is_in_pocket_dimension(player) then
    exit_pocket_dimension(player)
  else
    enter_pocket_dimension(player)
  end
end

script.on_event("pocket-dimension-toggle", function(event)
  handle_pocket_dimension_toggle(game.players[event.player_index])
end)

script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name == "pocket-dimension-toggle" then
    handle_pocket_dimension_toggle(game.players[event.player_index])
  end
end)

-- Teleport beacon to follow player. Only teleports when player moves more than
-- 1 tile from the beacon's target position to limit beacon recalculation frequency.
-- Surface guard: don't chase the player into the pocket dimension.
script.on_event(defines.events.on_player_changed_position, function(event)
  local player = game.players[event.player_index]

  local beacon = storage.personal_beacons[player.index]
  if beacon and beacon.valid and beacon.surface == player.surface then
    local pp = player.position
    local tx = pp.x
    local ty = pp.y - 1
    local bp = beacon.position
    if (tx - bp.x)^2 + (ty - bp.y)^2 > 1 then
      beacon.teleport({x = tx, y = ty})
    end
  end

  -- Pocket dimension exit: walk south through the gap in the south wall.
  if storage.pocket_dim_return[player.index] and
     player.surface.name == "pocket-dimension-" .. player.index then
    local pos = player.position
    if pos.y >= PD_HALF and math.abs(pos.x) < 1.5 then
      exit_pocket_dimension(player)
    end
  end
end)
