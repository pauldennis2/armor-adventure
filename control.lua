local quests       = require("quests.quests")
local aquilo_quest = require("quests.aquilo")

local ARMOR_NAME = "mech-armor-mk2"

-- Forward declarations for personal beacon functions defined later in this file.
local create_personal_beacon
local destroy_personal_beacon
local sync_personal_beacon

local HAS_RABBASCA    = script.active_mods["planet-rabbasca"] ~= nil
local HAS_CASTRA      = script.active_mods["castra-prime"]    ~= nil
local HAS_MOSHINE     = script.active_mods["Moshine"]         ~= nil
local HAS_PANGLIA     = script.active_mods["panglia_planet"]  ~= nil
local HAS_METAL_STARS = script.active_mods["metal-and-stars"] ~= nil
local PERSONAL_WARP_PYLON_EQUIP  = "personal-warp-pylon-equipment"
local PERSONAL_WARP_PYLON_ENTITY = "armor-adventure-personal-warp-pylon"
local create_personal_warp_pylon
local destroy_personal_warp_pylon
local sync_personal_warp_pylon

local activate_time_stopper
local deactivate_time_stopper
local draw_time_stopper_aura

local QUALITY_GATE_ENABLED = settings.startup["armor-adventure-quality-gate"].value
local EXPLORATION_MODE     = settings.startup["armor-adventure-exploration-mode"].value
local enforce_quality_gates_all_players

-- Shadow-to-real tech mapping for exploration mode.
local COVERED_TECHS
if EXPLORATION_MODE then
  COVERED_TECHS = {
    ["packable-forge-covered"]           = "packable-forge",
    ["armor-adventure-nauvis-covered"]   = "armor-adventure-nauvis",
    ["nauvis-defense-complete-covered"]  = "nauvis-defense-complete",
    ["big-demolisher-hunt-covered"]      = "big-demolisher-hunt",
    ["armor-adventure-vulcanus-covered"] = "armor-adventure-vulcanus",
    ["armor-adventure-gleba-covered"]    = "armor-adventure-gleba",
    ["armor-adventure-fulgora-covered"]  = "armor-adventure-fulgora",
    ["armor-adventure-aquilo-covered"]   = "armor-adventure-aquilo",
    ["aquilo-scanning-complete-covered"] = "aquilo-scanning-complete",
    ["cryo-core-acquired-covered"]       = "cryo-core-acquired",
    ["forge-promethium-armor-covered"]         = "forge-promethium-armor",
    ["regenerative-armor-covered"]             = "regenerative-armor",
    ["dissection-analysis-complete-covered"]   = "dissection-analysis-complete",
  }
  if HAS_MOSHINE     then COVERED_TECHS["personal-tesla-turret-covered"]          = "personal-tesla-turret" end
  if HAS_PANGLIA     then COVERED_TECHS["time-fracking-covered"]                  = "time-fracking" end
  if HAS_PANGLIA     then COVERED_TECHS["personal-time-stopper-covered"]          = "personal-time-stopper" end
  if HAS_RABBASCA    then COVERED_TECHS["personal-warp-pylon-covered"]            = "personal-warp-pylon" end
  if HAS_CASTRA      then COVERED_TECHS["core-hunt-covered"]                      = "core-hunt" end
  if HAS_CASTRA      then COVERED_TECHS["personal-combat-roboport-covered"]       = "personal-combat-roboport" end
  if HAS_METAL_STARS then COVERED_TECHS["armor-adventure-metal-and-stars-covered"] = "armor-adventure-metal-and-stars" end
  if HAS_METAL_STARS then COVERED_TECHS["pocket-dimension-covered"]               = "pocket-dimension" end
  if HAS_METAL_STARS then COVERED_TECHS["pocket-dimension-roboport-covered"]      = "pocket-dimension-roboport" end
end

local function reveal_all_exploration_techs(force)
  if not EXPLORATION_MODE then return end
  for shadow_name, real_name in pairs(COVERED_TECHS) do
    local shadow = force.technologies[shadow_name]
    local real   = force.technologies[real_name]
    if shadow and real and shadow.enabled then
      local all_done = true
      for _, prereq_tech in pairs(real.prerequisites) do
        if not prereq_tech.researched then all_done = false; break end
      end
      if all_done then
        real.enabled   = true
        shadow.enabled = false
      end
    end
  end
end

local QUANTUM_COIL_ITEM  = "quantum-coil"
local QUANTUM_COIL_EQUIP = "quantum-coil-equipment"

local ACS_EQUIP = "armor-forging-station-equipment"
local ACS_CRAFTING_BONUS = 1.0
local sync_acs_crafting_bonus

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
  storage.aquilo_depot_return     = storage.aquilo_depot_return or {}
  storage.aquilo_depot            = storage.aquilo_depot or {solved = {false, false, false, false}}
  storage.personal_warp_pylons    = storage.personal_warp_pylons or {}
  storage.personal_warp_pylon_pos = storage.personal_warp_pylon_pos or {}
  storage.time_stopper_active     = storage.time_stopper_active or {}
  storage.time_stopper_cooldown   = storage.time_stopper_cooldown or {}
  storage.acs_crafting_bonus      = storage.acs_crafting_bonus or {}
  storage.simulac_awaken_meter    = storage.simulac_awaken_meter or 0
  storage.time_stopper_render     = storage.time_stopper_render or {}
  storage.spark_last_pos          = storage.spark_last_pos or {}
  storage.panglia_pending_essence = storage.panglia_pending_essence or {}
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
  storage.aquilo_depot_return     = {}
  storage.aquilo_depot            = {solved = {false, false, false, false}}
  storage.personal_warp_pylons    = {}
  storage.time_stopper_active     = {}
  storage.time_stopper_cooldown   = {}
  storage.acs_crafting_bonus      = {}
  storage.personal_warp_pylon_pos = {}
  storage.simulac_awaken_meter    = 0
  storage.time_stopper_render     = {}
  storage.spark_last_pos          = {}
  if EXPLORATION_MODE then
    for _, force in pairs(game.forces) do reveal_all_exploration_techs(force) end
  end
  quests.refresh()
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
        -- Salvage items from pocket chests before wiping the surface.
        for _, chest in pairs(surface.find_entities_filtered({name = PD_CHEST})) do
          local inv = chest.get_inventory(defines.inventory.chest)
          if inv then
            for i = 1, #inv do
              local stack = inv[i]
              if stack.valid_for_read then
                local inserted = player.insert({name = stack.name, count = stack.count, quality = stack.quality.name})
                if inserted < stack.count then
                  safe_surface.spill_item_stack(
                    player.position,
                    {name = stack.name, count = stack.count - inserted, quality = stack.quality.name},
                    true
                  )
                end
              end
            end
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
    sync_acs_crafting_bonus(player)
  end
  if QUALITY_GATE_ENABLED then enforce_quality_gates_all_players() end
  if EXPLORATION_MODE then
    for _, force in pairs(game.forces) do reveal_all_exploration_techs(force) end
  end
  -- LuaRenderObjects are not saved; wipe and recreate for any active time stoppers.
  storage.time_stopper_render = {}
  for _, player in pairs(game.players) do
    if storage.time_stopper_active[player.index] then
      storage.time_stopper_render[player.index] = draw_time_stopper_aura(player)
    end
  end
  -- Migrate puzzle state and initial signals for existing depot surfaces.
  if game.surfaces["aquilo-fulgoran-depot"] then
    aquilo_quest.migrate_depot_puzzles()
  end
  quests.refresh()
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
  storage.time_stopper_render[event.player_index]     = nil
  storage.spark_last_pos[event.player_index]          = nil
end)

script.on_event(defines.events.on_player_armor_inventory_changed, function(event)
  local player = game.players[event.player_index]
  storage.mk2_penalties[player.index] = storage.mk2_penalties[player.index] or {}
  sync_player_bonuses(player)
  sync_personal_beacon(player)
  if HAS_RABBASCA then sync_personal_warp_pylon(player) end
  sync_acs_crafting_bonus(player)
end)

script.on_event(defines.events.on_research_finished, function(event)
  if EXPLORATION_MODE then
    reveal_all_exploration_techs(event.research.force)
  end
  if event.research.name == "pocket-dimension-roboport" then
    for _, p in pairs(event.research.force.players) do
      local surf = game.surfaces["pocket-dimension-" .. p.index]
      if surf then surf.set_property("pocket-construction-access", 1) end
    end
  end
  for _, bonus in pairs(ARMOR_BONUSES) do
    if event.research.name == bonus.tech then
      for _, player in pairs(event.research.force.players) do
        sync_player_bonuses(player)
      end
      return
    end
  end
  quests.refresh()
end)

script.on_event(defines.events.on_player_respawned, function(event)
  local player = game.players[event.player_index]
  sync_player_bonuses(player)
  sync_personal_beacon(player)
  if HAS_RABBASCA then sync_personal_warp_pylon(player) end
  -- New character has clean modifiers; clear time stopper state without removal.
  storage.time_stopper_active[player.index] = nil
  player.set_shortcut_toggled("time-stopper-activate", false)
  -- New character starts at modifier=0; treat storage as unset so sync reapplies from grid.
  storage.acs_crafting_bonus[player.index] = nil
  sync_acs_crafting_bonus(player)
  local render = storage.time_stopper_render and storage.time_stopper_render[player.index]
  if render and render.valid then render.destroy() end
  storage.time_stopper_render[player.index] = nil
  storage.spark_last_pos[player.index]      = nil
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
  [ACS_EQUIP]                             = ACS_EQUIP,
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
  [ACS_EQUIP]                     = {"item-name.armor-forging-station"},
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

sync_acs_crafting_bonus = function(player)
  if not (player and player.valid and player.character and player.character.valid) then return end
  local prev = storage.acs_crafting_bonus[player.index] or 0
  local current = 0
  local inv = player.character.get_inventory(defines.inventory.character_armor)
  local armor = inv and inv[1]
  if armor and armor.valid_for_read and armor.grid then
    for _, eq in pairs(armor.grid.equipment) do
      if eq.name == ACS_EQUIP then current = current + ACS_CRAFTING_BONUS end
    end
  end
  local delta = current - prev
  if delta ~= 0 then
    player.character.character_crafting_speed_modifier =
      player.character.character_crafting_speed_modifier + delta
    storage.acs_crafting_bonus[player.index] = current
  end
end

script.on_event(defines.events.on_equipment_inserted, function(event)
  local eq_name = event.equipment.name
  local group   = UNIQUE_EQUIPMENT[eq_name]
  local grid    = event.grid or event.equipment.grid

  -- Tech gate: ACS requires packable-forge research before it can be equipped
  if eq_name == ACS_EQUIP then
    local player = find_player_for_grid(grid)
    local tech   = player and player.force.technologies["packable-forge"]
    if not (tech and tech.researched) then
      local quality = event.equipment.quality
      local taken   = grid.take({equipment = event.equipment})
      if player and taken then
        player.insert({name = taken.name, count = 1, quality = quality.name})
        player.print({"armor-adventure.acs-pack-locked"})
      end
      return
    end
  end

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

  -- Apply crafting speed bonus when ACS equipment is inserted
  if eq_name == ACS_EQUIP then
    local player = find_player_for_grid(grid)
    if player then sync_acs_crafting_bonus(player) end
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
  if name == ACS_EQUIP then
    local player = find_player_for_grid(event.grid)
    if player then sync_acs_crafting_bonus(player) end
  end
end)

-- Regenerative Plating Hit Effect --

local REGEN_HIT_THRESHOLD = 100

local function has_regen_plating(player)
  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  if not armor_inv then return false end
  local armor = armor_inv[1]
  if not armor or not armor.valid_for_read then return false end
  local grid = armor.grid
  if not grid then return false end
  for _, eq in pairs(grid.equipment) do
    if eq.name == "regenerative-plating" then return true end
  end
  return false
end

script.on_event(defines.events.on_entity_damaged, function(event)
  if event.final_damage_amount < REGEN_HIT_THRESHOLD then return end
  local player = event.entity.player
  if not player then return end
  if not is_wearing_mk2(player) then return end
  if not has_regen_plating(player) then return end
  local pos     = event.entity.position
  local surface = event.entity.surface
  for _ = 1, 4 do
    surface.create_entity({
      name     = "explosion",
      position = {
        x = pos.x + (math.random() * 3 - 1.5),
        y = pos.y + (math.random() * 3 - 1.5),
      },
    })
  end
end, {{filter = "type", type = "character"}})

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

-- Running Spark Trail --
-- Generates spark particles trailing from the player's feet when running with
-- the Mk2: Overcharged Actuators tech. Spark count scales with movement speed.

local SPARK_ENTITY    = "spark-explosion"
local SPARK_THRESHOLD = 0.3  -- minimum dist per poll before sparks appear
local SPARK_MAX       = 5    -- max sparks spawned per poll

script.on_nth_tick(4, function()
  storage.spark_last_pos = storage.spark_last_pos or {}
  for _, player in pairs(game.players) do
    if not player.character then goto continue end
    if not is_wearing_mk2(player) then goto continue end
    if not has_tech(player, "mech-armor-mk2-running-speed") then goto continue end

    local pos  = player.position
    local last = storage.spark_last_pos[player.index]
    storage.spark_last_pos[player.index] = {x = pos.x, y = pos.y}
    if not last then goto continue end

    local dx   = pos.x - last.x
    local dy   = pos.y - last.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < SPARK_THRESHOLD then goto continue end

    local count = math.min(SPARK_MAX, math.max(1, math.floor(dist * 2)))

    -- Unit vector pointing backward (opposite movement) for the trailing offset,
    -- and perpendicular vector for sideways spread.
    local nx     = -dx / dist
    local ny     = -dy / dist
    local px     = -ny
    local py     =  nx
    local surface = player.surface
    for _ = 1, count do
      local spread = math.random() * 0.6 - 0.3
      local back   = math.random() * 0.4
      surface.create_entity({
        name     = SPARK_ENTITY,
        position = {
          x = pos.x + nx * back + px * spread,
          y = pos.y + ny * back + py * spread,
        },
      })
    end

    ::continue::
  end
end)

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
local PD_CHEST  = "pocket-dimension-chest"
-- Ordered uncommon→legendary. Positions form a 20×20 square around the centre.
local PD_CHEST_TIERS = {
  {pos = {-10, -10}, quality = "uncommon"},
  {pos = { 10, -10}, quality = "rare"},
  {pos = {-10,  10}, quality = "epic"},
  {pos = { 10,  10}, quality = "legendary"},
}

-- Maps PDG quality level to interior half-width in tiles.
-- quality.level is 0-indexed: normal=0, uncommon=1, rare=2, epic=3, legendary=4.
-- Normal→22×22, Uncommon→32×32, Rare→40×40, Epic→50×50, Legendary→64×64.
local QUALITY_HALVES = {[0]=11, 16, 20, 25, 32}
local function quality_to_half(q_level)
  return QUALITY_HALVES[q_level] or 32
end
-- The four non-legendary boundary half-widths; used by apply_pocket_area to
-- clear stale rings left by earlier entries at different quality levels.
local ALL_BOUNDARY_HALVES = {11, 16, 20, 25}

-- Update the pocket dimension's walkable area for the current PDG quality.
-- Uses a 1-tile-thick boundary ring rather than filling the outer zone with
-- out-of-map, so entities the player built at a higher quality level are
-- preserved on lab-dark-2 tiles and become reachable again when quality rises.
local function apply_pocket_area(surface, q_level)
  local H  = PD_HALF
  local HQ = quality_to_half(q_level)

  -- Pass 1: clear all possible interior quality boundary rings back to lab-dark-2.
  -- This removes the ring left by any previous entry at a different quality level.
  local clear = {}
  for _, bh in ipairs(ALL_BOUNDARY_HALVES) do
    for x = -(bh + 1), bh do
      clear[#clear + 1] = {name = "lab-dark-2", position = {x,       bh}}
      clear[#clear + 1] = {name = "lab-dark-2", position = {x, -bh - 1}}
    end
    for y = -bh, bh - 1 do
      clear[#clear + 1] = {name = "lab-dark-2", position = { bh,     y}}
      clear[#clear + 1] = {name = "lab-dark-2", position = {-bh - 1, y}}
    end
    -- Clear tutorial-grid markers for this boundary level
    clear[#clear + 1] = {name = "lab-dark-2", position = {-1, bh - 1}}
    clear[#clear + 1] = {name = "lab-dark-2", position = { 0, bh - 1}}
  end
  -- Also clear the legendary tutorial marker (y = H-1, not in ALL_BOUNDARY_HALVES)
  clear[#clear + 1] = {name = "lab-dark-2", position = {-1, H - 1}}
  clear[#clear + 1] = {name = "lab-dark-2", position = { 0, H - 1}}
  surface.set_tiles(clear)

  -- Pass 2: place the current quality boundary ring and exit markers.
  -- For legendary (HQ = H) the permanent outer walls already serve as the boundary.
  local ring = {}
  if HQ < H then
    -- South row with exit gap
    for x = -(HQ + 1), HQ do
      ring[#ring + 1] = {name = (x == -1 or x == 0) and "lab-dark-2" or "out-of-map", position = {x, HQ}}
    end
    -- North row
    for x = -(HQ + 1), HQ do
      ring[#ring + 1] = {name = "out-of-map", position = {x, -HQ - 1}}
    end
    -- East column (between north/south rows)
    for y = -HQ, HQ - 1 do
      ring[#ring + 1] = {name = "out-of-map", position = {HQ,     y}}
    end
    -- West column
    for y = -HQ, HQ - 1 do
      ring[#ring + 1] = {name = "out-of-map", position = {-HQ - 1, y}}
    end
  end
  -- Exit approach markers just inside the current boundary
  ring[#ring + 1] = {name = "tutorial-grid", position = {-1, HQ - 1}}
  ring[#ring + 1] = {name = "tutorial-grid", position = { 0, HQ - 1}}
  surface.set_tiles(ring)

  return HQ
end

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

local function get_pdg_quality_level(player)
  local armor_inv = player.get_inventory(defines.inventory.character_armor)
  if not armor_inv then return 0 end
  local armor = armor_inv[1]
  if not armor or not armor.valid_for_read then return 0 end
  local grid = armor.grid
  if not grid then return 0 end
  for _, eq in pairs(grid.equipment) do
    if eq.name == PDG_EQUIP then return eq.quality.level end
  end
  return 0
end

local function pocket_surface_name(player)
  return "pocket-dimension-" .. player.index
end

local function is_in_pocket_dimension(player)
  return player.surface.name == pocket_surface_name(player)
end

local function is_pocket_dim_surface(surface)
  return surface.name:match("^pocket%-dimension%-%d+$") ~= nil
end

local function setup_pocket_surface(surface)
  local H = PD_HALF

  -- set_tiles only works on already-generated chunks. Force-generate the
  -- 4×4 chunk area that covers our ±(H+2) tile boundary before writing tiles.
  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()

  local tiles = {}

  -- Full interior: lab-dark-2 for all 64×64 tiles (one-time init on new surfaces).
  -- apply_pocket_area then places a thin ring wall at the quality boundary on each
  -- entry, leaving tiles in the outer zone untouched so entities there survive.
  for x = -H, H - 1 do
    for y = -H, H - 1 do
      tiles[#tiles + 1] = {name = "lab-dark-2", position = {x, y}}
    end
  end

  -- Permanent outer walls on all four sides.
  -- South row: permanent exit gap at x = -1 and x = 0
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

  -- Four quality-tiered storage chests in a square, ±10 tiles from centre.
  -- No other containers are permitted (enforced via surface_conditions on pocket-magnitude).
  for _, tier in ipairs(PD_CHEST_TIERS) do
    surface.create_entity({name = PD_CHEST, position = tier.pos, quality = tier.quality, force = "player"})
  end
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
  else
    -- Migrate if chests are missing or are the old normal-quality configuration.
    local chests = surface.find_entities_filtered({name = PD_CHEST})
    local needs_migration = #chests ~= 4
    if not needs_migration then
      for _, chest in pairs(chests) do
        if chest.quality.name == "normal" then needs_migration = true break end
      end
    end
    if needs_migration then
      for _, chest in pairs(chests) do
        local inv = chest.get_inventory(defines.inventory.chest)
        if inv then
          for i = 1, #inv do
            local stack = inv[i]
            if stack.valid_for_read then
              local inserted = player.insert({name = stack.name, count = stack.count, quality = stack.quality.name})
              if inserted < stack.count then
                surface.spill_item_stack(chest.position, {name = stack.name, count = stack.count - inserted, quality = stack.quality.name}, true)
              end
            end
          end
        end
        chest.destroy()
      end
      for _, tier in ipairs(PD_CHEST_TIERS) do
        surface.create_entity({name = PD_CHEST, position = tier.pos, quality = tier.quality, force = "player"})
      end
    end
  end
  surface.set_property("pocket-magnitude", 1)
  local pd_roboport_tech = player.force.technologies["pocket-dimension-roboport"]
  surface.set_property("pocket-construction-access", (pd_roboport_tech and pd_roboport_tech.researched) and 1 or 0)
  return surface
end

local function exit_pocket_dimension(player)
  if not is_in_pocket_dimension(player) then return end
  if not has_pocket_generator(player) then
    player.print({"armor-adventure.pocket-dimension-no-generator"})
    local ret = storage.pocket_dim_return[player.index]
    player.teleport({0, (ret and ret.hq or PD_HALF) - 2}, player.surface)
    return
  end
  local ret = storage.pocket_dim_return[player.index]
  if not ret then return end
  local pd_surface = player.surface
  local pd_pos     = {x = player.position.x, y = player.position.y}
  player.teleport(ret.position, ret.surface)
  pd_surface.create_entity({name = "big-explosion", position = pd_pos})
  ret.surface.create_entity({name = "big-explosion", position = ret.position})
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

  local q_level      = get_pdg_quality_level(player)
  local hq           = quality_to_half(q_level)
  local origin_surface = player.surface
  local origin_pos     = {x = player.position.x, y = player.position.y}
  storage.pocket_dim_return[player.index] = {
    position = {x = origin_pos.x, y = origin_pos.y},
    surface  = origin_surface,
    hq       = hq,
  }
  local surface  = get_or_create_pocket_surface(player)
  apply_pocket_area(surface, q_level)
  local dest_pos = {0, hq - 4}
  origin_surface.create_entity({name = "big-explosion", position = origin_pos})
  player.teleport(dest_pos, surface)
  surface.create_entity({name = "big-explosion", position = dest_pos})
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

-- ─── Elevator / depot GUI helpers ────────────────────────────────────────────

local function open_elevator_gui(player)
  if player.gui.screen["aquilo-elevator-gui"] then return end
  local frame = player.gui.screen.add{
    type      = "frame",
    name      = "aquilo-elevator-gui",
    caption   = {"armor-adventure.elevator-gui-title"},
    direction = "vertical",
  }
  frame.auto_center = true
  frame.add{
    type    = "button",
    name    = "aquilo-elevator-descend",
    caption = {"armor-adventure.elevator-descend"},
    style   = "confirm_button",
  }
  player.opened = frame
end

local function close_elevator_gui(player)
  local frame = player.gui.screen["aquilo-elevator-gui"]
  if frame and frame.valid then frame.destroy() end
end

local function open_depot_gui(player)
  if player.gui.screen["aquilo-depot-gui"] then return end
  local frame = player.gui.screen.add{
    type      = "frame",
    name      = "aquilo-depot-gui",
    caption   = {"armor-adventure.depot-gui-title"},
    direction = "vertical",
  }
  frame.auto_center = true
  frame.add{
    type    = "button",
    name    = "aquilo-depot-ascend",
    caption = {"armor-adventure.depot-ascend"},
    style   = "confirm_button",
  }
  player.opened = frame
end

local function close_depot_gui(player)
  local frame = player.gui.screen["aquilo-depot-gui"]
  if frame and frame.valid then frame.destroy() end
end

-- ─────────────────────────────────────────────────────────────────────────────

-- Block access to tiered pocket chests whose quality exceeds the player's PDG quality.
-- Also intercepts the elevator and depot ascent entities to show custom GUIs.
script.on_event(defines.events.on_gui_opened, function(event)
  if event.gui_type ~= defines.gui_type.entity then return end
  local entity = event.entity
  if not entity then return end
  local player = game.players[event.player_index]

  if entity.name == PD_CHEST then
    if get_pdg_quality_level(player) < entity.quality.level then
      player.opened = nil
      player.print({"armor-adventure.pocket-dimension-chest-locked"})
    end
  elseif entity.name == "cryovault-chest" then
    if not (storage.aquilo_depot and storage.aquilo_depot.vault_unlocked) then
      player.opened = nil
      player.print({"armor-adventure.cryovault-locked"})
    end
  elseif entity.name == "aquilo-elevator-complete" then
    player.opened = nil
    open_elevator_gui(player)
  elseif entity.name == "aquilo-depot-ascent" then
    player.opened = nil
    open_depot_gui(player)
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local player = game.players[event.player_index]
  local name   = event.element.name
  if name == "aquilo-elevator-descend" then
    close_elevator_gui(player)
    aquilo_quest.descend_to_depot(player)
  elseif name == "aquilo-depot-ascend" then
    close_depot_gui(player)
    aquilo_quest.ascend_from_depot(player)
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  if event.element then
    local n = event.element.name
    if n == "aquilo-elevator-gui" or n == "aquilo-depot-gui" then
      if event.element.valid then event.element.destroy() end
    end
    return
  end
  if event.gui_type == defines.gui_type.entity and event.entity then
    local ent = event.entity
    if not ent.valid then return end
    if ent.name == "constant-combinator"
       and ent.surface.name == "aquilo-fulgoran-depot" then
      aquilo_quest.check_combinator_puzzle(ent)
    elseif ent.name == "vault-card-reader" then
      local inv = ent.get_inventory(defines.inventory.chest)
      if inv then
        for i = 1, #inv do
          local stack = inv[i]
          if stack.valid_for_read and stack.name == "cryovault-access-card" then
            local quality_name = stack.quality.name
            stack.clear()
            local player = game.players[event.player_index]
            if player and player.valid then
              player.insert({name = "cryo-core", count = 1, quality = quality_name})
              player.print("[color=cyan]Cryovault access card accepted. Cryo Core extracted.[/color]")
              local tech = player.force.technologies["cryo-core-acquired"]
              if tech and not tech.researched then
                tech.researched = true
              end
            end
          end
        end
      end
    end
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
  local pd_ret = storage.pocket_dim_return[player.index]
  if pd_ret and player.surface.name == "pocket-dimension-" .. player.index then
    local pos = player.position
    if pos.y >= (pd_ret.hq or PD_HALF) and math.abs(pos.x) < 1.5 then
      exit_pocket_dimension(player)
    end
  end
end)

script.on_event(defines.events.on_player_changed_surface, function(event)
  local player = game.players[event.player_index]
  storage.spark_last_pos[player.index] = nil
  if player.surface.name == "aquilo-fulgoran-depot" then
    aquilo_quest.rebuild_depot_renders()
  end
  if not (storage.time_stopper_active and storage.time_stopper_active[player.index]) then
    quests.refresh()
    return
  end
  local render = storage.time_stopper_render and storage.time_stopper_render[player.index]
  if render and render.valid then render.destroy() end
  storage.time_stopper_render[player.index] = draw_time_stopper_aura(player)
  quests.refresh()
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

draw_time_stopper_aura = function(player)
  if not (player.character and player.character.valid) then return nil end
  return rendering.draw_circle({
    color   = {r = 0.1, g = 0.7, b = 1.0, a = 0.6},
    radius  = PTS_SLOW_RADIUS,
    width   = 3,
    filled  = false,
    target  = player.character,
    surface = player.surface,
    players = {player},
  })
end

deactivate_time_stopper = function(player)
  if not storage.time_stopper_active[player.index] then return end
  storage.time_stopper_active[player.index] = nil
  local render = storage.time_stopper_render and storage.time_stopper_render[player.index]
  if render and render.valid then render.destroy() end
  storage.time_stopper_render[player.index] = nil
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

  -- Activation shockwave: ring of explosions expanding from the player
  for i = 1, 8 do
    local angle = (i - 1) * (math.pi * 2 / 8)
    player.surface.create_entity({
      name     = "medium-explosion",
      position = {
        x = player.position.x + math.cos(angle) * 6,
        y = player.position.y + math.sin(angle) * 6,
      },
    })
  end
  storage.time_stopper_render[player.index] = draw_time_stopper_aura(player)

  apply_time_stopper_slow(player)
  player.set_shortcut_toggled("time-stopper-activate", true)
end

script.on_event("time-stopper-activate", function(event)
  activate_time_stopper(game.players[event.player_index])
end)

-- Every second: time stopper, personal fridge, warp pylon re-registration.
-- Planet quest work runs on tick 59 (registered dynamically by quests.lua).
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

  -- Personal Fridge: extend spoil_tick by 30 every 60 ticks = 50% slower spoilage.
  for _, player in pairs(game.players) do
    if player.character
       and player.force.technologies["personal-fridge"].researched
    then
      local armor_inv = player.get_inventory(defines.inventory.character_armor)
      local armor = armor_inv and armor_inv[1]
      if armor and armor.valid_for_read and armor.name == ARMOR_NAME then
        local inv = player.get_main_inventory()
        if inv then
          for i = 1, #inv do
            local stack = inv[i]
            if stack.valid_for_read and stack.spoil_tick > 0 then
              stack.spoil_tick = stack.spoil_tick + 30
            end
          end
        end
      end
    end
  end

  -- Warp pylon: re-register with Rabbasca when the pylon has moved > 20 tiles.
  if remote.interfaces["rabbasca_warp_pylons"] and storage.personal_warp_pylons then
    for _, player in pairs(game.players) do
      local pylon = storage.personal_warp_pylons[player.index]
      if pylon and pylon.valid then
        local last = storage.personal_warp_pylon_pos and storage.personal_warp_pylon_pos[player.index]
        local pp = pylon.position
        if not last or (pp.x - last.x)^2 + (pp.y - last.y)^2 > 400 then
          remote.call("rabbasca_warp_pylons", "unregister_pylon", pylon.unit_number)
          remote.call("rabbasca_warp_pylons", "register_pylon",   pylon)
          storage.personal_warp_pylon_pos[player.index] = {x = pp.x, y = pp.y}
        end
      end
    end
  end

  -- Moshine debug: floating speed label over every train stop on the Moshine surface.
  -- Shows the speed (tiles/tick) of the first train found on the surface.
  -- TTL of 70 ticks auto-expires the label before the next redraw, so no storage needed.
  if HAS_MOSHINE then
    local moshine = game.surfaces["moshine"]
    if moshine then
      local locos  = moshine.find_entities_filtered({type = "locomotive"})
      local first  = locos[1] and locos[1].train
      local speed_text = first and string.format("%.3f t/t", math.abs(first.speed)) or "no trains"
      for _, stop in pairs(moshine.find_entities_filtered({type = "train-stop"})) do
        rendering.draw_text({
          text          = speed_text,
          surface       = moshine,
          target        = stop,
          target_offset = {0, -2},
          color         = {r = 1, g = 1, b = 0.2},
          scale         = 1.5,
          alignment     = "center",
          time_to_live  = 70,
        })
      end
    end
  end
end)

