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
  for _, player in pairs(game.players) do
    storage.mk2_penalties[player.index] = storage.mk2_penalties[player.index] or {}
  end
end

script.on_init(function()
  storage.mk2_penalties = {}
end)

script.on_configuration_changed(function()
  init_storage()
  for _, player in pairs(game.players) do
    sync_player_bonuses(player)
  end
end)

script.on_event(defines.events.on_player_created, function(event)
  storage.mk2_penalties[event.player_index] = {}
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

script.on_event(defines.events.on_equipment_inserted, function(event)
  if event.equipment.name ~= "regenerative-plating" then return end

  local grid = event.grid or event.equipment.grid
  local count = 0
  for _, eq in pairs(grid.equipment) do
    if eq.name == "regenerative-plating" then count = count + 1 end
  end
  if count <= 1 then return end

  local quality = event.equipment.quality
  grid.take({equipment = event.equipment})

  for _, player in pairs(game.players) do
    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if armor_inv then
      local armor = armor_inv[1]
      if armor and armor.valid_for_read and armor.grid == grid then
        player.insert({name = "regenerative-plating", count = 1, quality = quality.name})
        player.print("Only one Regenerative Plating can be equipped at a time.")
        return
      end
    end
  end
end)

-- Personal Combat Roboport --

local COMBAT_ROBOPORT_ITEM = "personal-combat-roboport"
local COMBAT_ROBOPORT_TECH = "personal-combat-roboport"
local COMBAT_ROBOPORT_RANGE = 20
local COMBAT_ROBOPORT_SPAWN_COUNT = 5

local function has_combat_roboport_equipped(player)
  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  if not armor_inv then return false end
  local armor = armor_inv[1]
  if not armor or not armor.valid_for_read then return false end
  local grid = armor.grid
  if not grid then return false end
  for _, equipment in pairs(grid.equipment) do
    if equipment.name == COMBAT_ROBOPORT_ITEM then return true end
  end
  return false
end

local function spawn_defenders(player)
  local surface = player.surface
  for i = 1, COMBAT_ROBOPORT_SPAWN_COUNT do
    local pos = {
      x = player.position.x + math.random(-2, 2),
      y = player.position.y + math.random(-2, 2),
    }
    local robot = surface.create_entity({name = "defender", position = pos, force = player.force})
    if robot and robot.valid then
      robot.combat_robot_owner = player.character
    end
  end
end

script.on_nth_tick(300, function()
  for _, player in pairs(game.players) do
    if not player.character then goto continue end
    if not has_tech(player, COMBAT_ROBOPORT_TECH) then goto continue end
    if not has_combat_roboport_equipped(player) then goto continue end

    local nearest_enemy = player.surface.find_nearest_enemy({
      position = player.position,
      max_distance = COMBAT_ROBOPORT_RANGE,
      force = player.force,
    })
    if nearest_enemy then
      spawn_defenders(player)
    end

    ::continue::
  end
end)
