local ARMOR_NAME = "mech-armor-mk2"

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
  storage.mk2_penalties = storage.mk2_penalties or {}
  storage.roboport_cooldowns = storage.roboport_cooldowns or {}
  for _, player in pairs(game.players) do
    storage.mk2_penalties[player.index]    = storage.mk2_penalties[player.index] or {}
    storage.roboport_cooldowns[player.index] = storage.roboport_cooldowns[player.index] or {}
  end
end

script.on_init(function()
  storage.mk2_penalties    = {}
  storage.roboport_cooldowns = {}
end)

script.on_configuration_changed(function()
  init_storage()
  for _, player in pairs(game.players) do
    sync_player_bonuses(player)
  end
end)

script.on_event(defines.events.on_player_created, function(event)
  storage.mk2_penalties[event.player_index]    = {}
  storage.roboport_cooldowns[event.player_index] = {}
end)

script.on_event(defines.events.on_player_armor_inventory_changed, function(event)
  local player = game.players[event.player_index]
  storage.mk2_penalties[player.index] = storage.mk2_penalties[player.index] or {}
  sync_player_bonuses(player)
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
  sync_player_bonuses(game.players[event.player_index])
end)

-- Unique equipment enforcement --

-- Maps equipment name to a uniqueness group. Only one item per group may be equipped.
local UNIQUE_EQUIPMENT = {
  ["regenerative-plating"]                = "regenerative-plating",
  ["personal-combat-roboport"]            = "combat-roboport",
  ["personal-combat-roboport-distractor"] = "combat-roboport",
  ["personal-combat-roboport-destroyer"]  = "combat-roboport",
}

-- Display name used in the rejection message, keyed by group.
local UNIQUE_GROUP_LABEL = {
  ["regenerative-plating"] = {"item-name.regenerative-plating"},
  ["combat-roboport"]      = {"armor-adventure.group-combat-roboport"},
}

script.on_event(defines.events.on_equipment_inserted, function(event)
  local group = UNIQUE_EQUIPMENT[event.equipment.name]
  if not group then return end

  local grid = event.grid or event.equipment.grid
  local count = 0
  for _, eq in pairs(grid.equipment) do
    if UNIQUE_EQUIPMENT[eq.name] == group then count = count + 1 end
  end
  if count <= 1 then return end

  local quality = event.equipment.quality
  local item_name = event.equipment.name
  grid.take({equipment = event.equipment})

  for _, player in pairs(game.players) do
    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if armor_inv then
      local armor = armor_inv[1]
      if armor and armor.valid_for_read and armor.grid == grid then
        player.insert({name = item_name, count = 1, quality = quality.name})
        player.print({"armor-adventure.unique-equipment-limit", UNIQUE_GROUP_LABEL[group]})
        return
      end
    end
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
