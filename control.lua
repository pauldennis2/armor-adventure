require("quests")

local ARMOR_NAME = "mech-armor-mk2"

-- Forward declarations for personal beacon functions defined later in this file.
local create_personal_beacon
local destroy_personal_beacon
local sync_personal_beacon

local HAS_RABBASCA = script.active_mods["planet-rabbasca"] ~= nil
local PERSONAL_WARP_PYLON_EQUIP  = "personal-warp-pylon-equipment"
local PERSONAL_WARP_PYLON_ENTITY = "armor-adventure-personal-warp-pylon"
local create_personal_warp_pylon
local destroy_personal_warp_pylon
local sync_personal_warp_pylon

local activate_time_stopper
local deactivate_time_stopper

local QUALITY_GATE_ENABLED = settings.startup["armor-adventure-quality-gate"].value
local enforce_quality_gates_all_players

local QUANTUM_COIL_ITEM  = "quantum-coil"
local QUANTUM_COIL_EQUIP = "quantum-coil-equipment"

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
  storage.mk2_penalties           = storage.mk2_penalties or {}
  storage.roboport_cooldowns      = storage.roboport_cooldowns or {}
  storage.personal_beacons        = storage.personal_beacons or {}
  storage.pocket_dim_return       = storage.pocket_dim_return or {}
  storage.personal_warp_pylons    = storage.personal_warp_pylons or {}
  storage.personal_warp_pylon_pos = storage.personal_warp_pylon_pos or {}
  storage.time_stopper_active     = storage.time_stopper_active or {}
  storage.time_stopper_cooldown   = storage.time_stopper_cooldown or {}
  for _, player in pairs(game.players) do
    storage.mk2_penalties[player.index]      = storage.mk2_penalties[player.index] or {}
    storage.roboport_cooldowns[player.index] = storage.roboport_cooldowns[player.index] or {}
    storage.personal_beacons[player.index]   = storage.personal_beacons[player.index]
    storage.pocket_dim_return[player.index]  = storage.pocket_dim_return[player.index]
  end
end

script.on_init(function()
  storage.mk2_penalties           = {}
  storage.roboport_cooldowns      = {}
  storage.personal_beacons        = {}
  storage.pocket_dim_return       = {}
  storage.personal_warp_pylons    = {}
  storage.time_stopper_active     = {}
  storage.time_stopper_cooldown   = {}
  storage.personal_warp_pylon_pos = {}
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
  if QUALITY_GATE_ENABLED then enforce_quality_gates_all_players() end
end)

script.on_event(defines.events.on_player_created, function(event)
  storage.mk2_penalties[event.player_index]      = {}
  storage.roboport_cooldowns[event.player_index] = {}
  storage.personal_beacons[event.player_index]        = nil
  storage.pocket_dim_return[event.player_index]       = nil
  storage.personal_warp_pylons[event.player_index]    = nil
  storage.time_stopper_active[event.player_index]     = nil
  storage.time_stopper_cooldown[event.player_index]   = nil
  storage.personal_warp_pylon_pos[event.player_index] = nil
end)

script.on_event(defines.events.on_player_armor_inventory_changed, function(event)
  local player = game.players[event.player_index]
  storage.mk2_penalties[player.index] = storage.mk2_penalties[player.index] or {}
  sync_player_bonuses(player)
  sync_personal_beacon(player)
  if HAS_RABBASCA then sync_personal_warp_pylon(player) end
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
  if HAS_RABBASCA then sync_personal_warp_pylon(player) end
  -- New character has clean modifiers; clear time stopper state without removal.
  storage.time_stopper_active[player.index] = nil
  player.set_shortcut_toggled("time-stopper-activate", false)
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
  ["personal-time-stopper"]               = "personal-time-stopper",
  [QUANTUM_COIL_EQUIP]                    = "quantum-coil",
}
if HAS_RABBASCA then
  UNIQUE_EQUIPMENT[PERSONAL_WARP_PYLON_EQUIP] = "personal-warp-pylon"
end

enforce_quality_gates_all_players = function()
  for _, player in pairs(game.players) do
    if not (player.character and player.character.valid) then goto continue end
    local armor_inv = player.character.get_inventory(defines.inventory.character_armor)
    if not armor_inv then goto continue end
    local armor_stack = armor_inv[1]
    if not (armor_stack and armor_stack.valid_for_read) then goto continue end
    local armor_level = armor_stack.quality.level
    local grid = armor_stack.grid
    if not grid then goto continue end
    local to_remove = {}
    for _, eq in pairs(grid.equipment) do
      if UNIQUE_EQUIPMENT[eq.name] and eq.quality.level > armor_level then
        to_remove[#to_remove + 1] = {name = eq.name, quality = eq.quality.name, eq = eq}
      end
    end
    for _, entry in ipairs(to_remove) do
      if entry.eq.valid then
        grid.take({equipment = entry.eq})
        player.insert({name = entry.name, count = 1, quality = entry.quality})
      end
    end
    ::continue::
  end
end

-- Display name used in the rejection message, keyed by group.
local UNIQUE_GROUP_LABEL = {
  ["regenerative-plating"]        = {"item-name.regenerative-plating"},
  ["combat-roboport"]             = {"armor-adventure.group-combat-roboport"},
  [PERSONAL_BEACON_EQUIP]         = {"item-name." .. PERSONAL_BEACON_EQUIP},
  ["pocket-dimension-generator"]  = {"item-name.pocket-dimension-generator"},
  ["personal-tesla-turret"]       = {"item-name.personal-tesla-turret"},
  ["personal-time-stopper"]       = {"item-name.personal-time-stopper"},
  ["personal-warp-pylon"]         = {"item-name." .. PERSONAL_WARP_PYLON_EQUIP},
  ["quantum-coil"]                = {"item-name.quantum-coil"},
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
      local taken   = grid.take({equipment = event.equipment})
      local player  = find_player_for_grid(grid)
      if player and taken then
        player.insert({name = taken.name, count = 1, quality = quality.name})
        player.print({"armor-adventure.unique-equipment-limit", UNIQUE_GROUP_LABEL[group]})
      end
      return
    end
  end

  -- Quality gate: custom equipment quality cannot exceed armor quality
  if QUALITY_GATE_ENABLED and UNIQUE_EQUIPMENT[eq_name] then
    local player = find_player_for_grid(grid)
    if player and player.character then
      local armor_inv = player.character.get_inventory(defines.inventory.character_armor)
      local armor_stack = armor_inv and armor_inv[1]
      if armor_stack and armor_stack.valid_for_read and event.equipment.quality.level > armor_stack.quality.level then
        local quality = event.equipment.quality
        local taken   = grid.take({equipment = event.equipment})
        if taken then player.insert({name = taken.name, count = 1, quality = quality.name}) end
        player.print({"armor-adventure.quality-gate-rejection", {"equipment-name." .. eq_name}})
        return
      end
    end
  end

  -- Spawn personal beacon when its equipment is inserted
  if eq_name == PERSONAL_BEACON_EQUIP then
    local player = find_player_for_grid(grid)
    if player then create_personal_beacon(player) end
  end

  -- Spawn personal warp pylon when its equipment is inserted
  if HAS_RABBASCA and eq_name == PERSONAL_WARP_PYLON_EQUIP then
    local player = find_player_for_grid(grid)
    if player then create_personal_warp_pylon(player) end
  end
end)

script.on_event(defines.events.on_equipment_removed, function(event)
  local eq = event.equipment
  local name = type(eq) == "string" and eq or eq.name
  if name == PERSONAL_BEACON_EQUIP then
    local player = find_player_for_grid(event.grid)
    if player then sync_personal_beacon(player) end
  end
  if HAS_RABBASCA and name == PERSONAL_WARP_PYLON_EQUIP then
    local player = find_player_for_grid(event.grid)
    if player then sync_personal_warp_pylon(player) end
  end
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

local BEACON_ENTITY_BY_QUALITY = {
  normal    = "personal-beacon",
  uncommon  = "personal-beacon-uncommon",
  rare      = "personal-beacon-rare",
  epic      = "personal-beacon-epic",
  legendary = "personal-beacon-legendary",
}

local function get_beacon_equip_quality(player)
  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  if not armor_inv then return "normal" end
  local armor = armor_inv[1]
  if not (armor and armor.valid_for_read and armor.grid) then return "normal" end
  for _, eq in ipairs(armor.grid.equipment) do
    if eq.name == PERSONAL_BEACON_EQUIP then return eq.quality.name end
  end
  return "normal"
end

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
  local quality     = get_beacon_equip_quality(player)
  local entity_name = BEACON_ENTITY_BY_QUALITY[quality] or PERSONAL_BEACON_ENTITY
  local beacon = player.surface.create_entity({
    name     = entity_name,
    position = {x = player.position.x, y = player.position.y - 1},
    force    = player.force,
  })
  if beacon then beacon.destructible = false end
  storage.personal_beacons[player.index] = beacon
end

sync_personal_beacon = function(player)
  if not player or not player.valid then return end
  local has_eq     = player.character and has_personal_beacon_equip(player)
  local beacon     = storage.personal_beacons[player.index]
  local has_beacon = beacon and beacon.valid
  if has_eq and has_beacon then
    local expected = BEACON_ENTITY_BY_QUALITY[get_beacon_equip_quality(player)] or PERSONAL_BEACON_ENTITY
    if beacon.name ~= expected then
      destroy_personal_beacon(player)
      create_personal_beacon(player)
    end
  elseif has_eq and not has_beacon then
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
  elseif event.prototype_name == "time-stopper-activate" then
    activate_time_stopper(game.players[event.player_index])
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

  if HAS_RABBASCA then
    local warp_pylon = storage.personal_warp_pylons[player.index]
    if warp_pylon and warp_pylon.valid and warp_pylon.surface == player.surface then
      local pp = player.position
      local wp = warp_pylon.position
      if (pp.x - wp.x)^2 + (pp.y - wp.y)^2 > 1 then
        warp_pylon.teleport({x = pp.x, y = pp.y})
      end
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

-- Personal Warp Pylon (Rabbasca integration) --

if HAS_RABBASCA then

local function has_personal_warp_pylon_equip(player)
  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  if not armor_inv then return false end
  local armor = armor_inv[1]
  if not armor or not armor.valid_for_read then return false end
  local grid = armor.grid
  if not grid then return false end
  for _, eq in pairs(grid.equipment) do
    if eq.name == PERSONAL_WARP_PYLON_EQUIP then return true end
  end
  return false
end

destroy_personal_warp_pylon = function(player)
  local pylon = storage.personal_warp_pylons[player.index]
  storage.personal_warp_pylons[player.index]    = nil
  storage.personal_warp_pylon_pos[player.index] = nil
  if not pylon or not pylon.valid then return end
  remote.call("rabbasca_warp_pylons", "unregister_pylon", pylon.unit_number)
  pylon.destroy()
end

create_personal_warp_pylon = function(player)
  local pylon = player.surface.create_entity({
    name     = PERSONAL_WARP_PYLON_ENTITY,
    position = player.position,
    force    = player.force,
  })
  if not pylon then return end
  storage.personal_warp_pylons[player.index]    = pylon
  storage.personal_warp_pylon_pos[player.index] = {x = player.position.x, y = player.position.y}
  remote.call("rabbasca_warp_pylons", "register_pylon", pylon)
end

sync_personal_warp_pylon = function(player)
  if not player or not player.valid then return end
  local has_eq    = player.character and has_personal_warp_pylon_equip(player)
  local pylon     = storage.personal_warp_pylons[player.index]
  local has_pylon = pylon and pylon.valid
  if has_eq and not has_pylon then
    create_personal_warp_pylon(player)
  elseif not has_eq and has_pylon then
    destroy_personal_warp_pylon(player)
  end
end

end -- HAS_RABBASCA

-- Personal Time Stopper --

local PTS_EQUIP       = "personal-time-stopper"
local PTS_SPEED_BONUS = 1.5   -- added to character_running_speed_modifier
local PTS_CRAFT_BONUS = 2.0   -- added to character_crafting_speed_modifier
local PTS_SLOW_RADIUS = 15    -- tile radius for enemy slow
local PTS_COOLDOWN    = 60 * 60  -- 60s cooldown after effect ends

local PTS_DURATION_BY_QUALITY = {
  normal    = 10 * 60,
  uncommon  = 12 * 60,
  rare      = 15 * 60,
  epic      = 20 * 60,
  legendary = 30 * 60,
}

local function get_time_stopper_equip(player)
  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  if not armor_inv then return nil end
  local armor = armor_inv[1]
  if not armor or not armor.valid_for_read then return nil end
  local grid = armor.grid
  if not grid then return nil end
  for _, eq in pairs(grid.equipment) do
    if eq.name == PTS_EQUIP then return eq end
  end
  return nil
end

local function apply_time_stopper_slow(player)
  local enemies = player.surface.find_entities_filtered({
    position = player.position,
    radius   = PTS_SLOW_RADIUS,
    force    = "enemy",
    type     = "unit",
  })
  for _, enemy in pairs(enemies) do
    if enemy.valid then
      player.surface.create_entity({
        name     = "time-stopper-slow",
        position = enemy.position,
        target   = enemy,
      })
    end
  end
end

deactivate_time_stopper = function(player)
  if not storage.time_stopper_active[player.index] then return end
  storage.time_stopper_active[player.index] = nil
  if player.character and player.character.valid then
    player.character.character_running_speed_modifier =
      player.character.character_running_speed_modifier - PTS_SPEED_BONUS
    player.character.character_crafting_speed_modifier =
      player.character.character_crafting_speed_modifier - PTS_CRAFT_BONUS
  end
  player.set_shortcut_toggled("time-stopper-activate", false)
end

activate_time_stopper = function(player)
  if not player.character then return end
  if not has_tech(player, "personal-time-stopper") then
    player.print({"armor-adventure.time-stopper-locked"})
    return
  end
  local eq = get_time_stopper_equip(player)
  if not eq then
    player.print({"armor-adventure.time-stopper-no-equipment"})
    return
  end
  local tick = game.tick
  local cooldown_until = storage.time_stopper_cooldown[player.index]
  if cooldown_until and tick < cooldown_until then
    local remaining = math.ceil((cooldown_until - tick) / 60)
    player.print({"armor-adventure.time-stopper-on-cooldown", remaining})
    return
  end
  if storage.time_stopper_active[player.index] then return end

  local quality  = eq.quality.name
  local duration = PTS_DURATION_BY_QUALITY[quality] or PTS_DURATION_BY_QUALITY.normal
  storage.time_stopper_active[player.index]   = tick + duration
  storage.time_stopper_cooldown[player.index] = tick + duration + PTS_COOLDOWN

  player.character.character_running_speed_modifier =
    player.character.character_running_speed_modifier + PTS_SPEED_BONUS
  player.character.character_crafting_speed_modifier =
    player.character.character_crafting_speed_modifier + PTS_CRAFT_BONUS

  apply_time_stopper_slow(player)
  player.set_shortcut_toggled("time-stopper-activate", true)
end

script.on_event("time-stopper-activate", function(event)
  activate_time_stopper(game.players[event.player_index])
end)

-- Every second: deactivate expired effects and re-apply slow to newly entered enemies.
script.on_nth_tick(60, function()
  local tick = game.tick
  for _, player in pairs(game.players) do
    if not storage.time_stopper_active[player.index] then goto continue end
    if tick >= storage.time_stopper_active[player.index] then
      deactivate_time_stopper(player)
    elseif player.character and player.character.valid then
      apply_time_stopper_slow(player)
    end
    ::continue::
  end
end)
