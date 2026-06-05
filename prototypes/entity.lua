local function scale_graphics(t, factor)
  if type(t) ~= "table" then return end
  if t.scale ~= nil then t.scale = t.scale * factor end
  for _, v in pairs(t) do scale_graphics(v, factor) end
end

-- Like scale_graphics but also handles sprite layers with no explicit scale.
-- Sprite layers are identified by having a filename field; Factorio HR sprites
-- default to scale=0.5 when unset, so we use that as the starting value.
local function force_scale_graphics(t, factor)
  if type(t) ~= "table" then return end
  if t.filename ~= nil then
    t.scale = (t.scale or 0.5) * factor
  end
  for _, v in pairs(t) do force_scale_graphics(v, factor) end
end

local function shift_layers(anim, dx, dy)
  if not anim or not anim.layers then return end
  for _, layer in pairs(anim.layers) do
    local s = layer.shift or {0, 0}
    layer.shift = {s[1] + dx, s[2] + dy}
  end
end

local function apply_fixed_tint(t, tint_color)
  if type(t) ~= "table" then return end
  if t.apply_runtime_tint then
    t.apply_runtime_tint = nil
    t.tint = tint_color
  end
  for _, v in pairs(t) do
    apply_fixed_tint(v, tint_color)
  end
end

local function scale_box(box, f)
  if box[1] then
    return {{box[1][1] * f, box[1][2] * f}, {box[2][1] * f, box[2][2] * f}}
  end
  return {
    left_top     = {x = box.left_top.x * f,     y = box.left_top.y * f},
    right_bottom = {x = box.right_bottom.x * f, y = box.right_bottom.y * f},
  }
end

local hot_rod_red = {r=1, g=0.15, b=0.15, a=1}
-- Personal Beacon: one entity per quality tier, each with a hardcoded distribution_effectivity.
-- Normal keeps the base name for backward compatibility with existing saves.
local PERSONAL_BEACON_TIERS = {
  {suffix = "",           effectivity = 1.5},
  {suffix = "-uncommon",  effectivity = 1.75},
  {suffix = "-rare",      effectivity = 2.0},
  {suffix = "-epic",      effectivity = 2.25},
  {suffix = "-legendary", effectivity = 2.5},
}
for _, tier in ipairs(PERSONAL_BEACON_TIERS) do
  local pb = table.deepcopy(data.raw["beacon"]["beacon"])
  pb.name                          = "personal-beacon" .. tier.suffix
  pb.next_upgrade                  = nil
  pb.distribution_effectivity      = tier.effectivity
  pb.minable                       = nil
  pb.allow_copy_paste              = false
  pb.collision_box                 = {{-0.01, -0.01}, {0.01, 0.01}}
  pb.collision_mask                = {layers = {}}
  pb.selection_box                 = {{-0.5, -0.5}, {0.5, 0.5}}
  pb.supply_area_distance          = 4
  pb.is_military_target            = false
  pb.flags = {"not-on-map", "not-blueprintable", "not-deconstructable", "not-repairable"}
  pb.energy_source                 = {type = "void"}
  pb.graphics_set                  = {module_icons_suppressed = false}
  pb.radius_visualisation_picture  = nil
  data:extend({pb})
end

-- Harvester: assembling-machine deepcopy restricted to the "harvesting" crafting category.
-- Script auto-sets the recipe and feeds enemy-biomass into the input inventory.
local harvester = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-3"])
harvester.name                      = "harvester"
harvester.minable                   = {mining_time = 0.5, result = "harvester"}
harvester.crafting_categories       = {"harvesting"}
harvester.crafting_speed            = 1.0
harvester.module_slots              = 4
harvester.allowed_effects           = {"speed", "consumption", "pollution", "quality", "productivity"}
harvester.allowed_module_categories = {"speed", "efficiency", "quality", "productivity"}
harvester.fluid_boxes               = nil
harvester.fluid_boxes_off_when_no_fluid_recipe = nil
harvester.factoriopedia_simulation = nil
harvester.collision_box            = {{-2.4, -2.4}, {2.4, 2.4}}
harvester.selection_box            = {{-2.5, -2.5}, {2.5, 2.5}}
harvester.next_upgrade             = nil
harvester.icon                     = "__armor-adventure__/graphics/entity/the-harvester/the-harvester-icon.png"
harvester.icon_size                = 64
-- frame_count=64 and scale=0.25 are estimated from the 4000×4000 sheet (8 cols × 8 rows × 500px).
-- Adjust if the animation looks wrong in-game.
-- color and frozen sprites exist but are not yet wired.
harvester.graphics_set = {
  animation = {
    layers = {
      {
        filename        = "__armor-adventure__/graphics/entity/the-harvester/the-harvester-hr-animation-1.png",
        priority        = "high",
        width           = 500,
        height          = 500,
        frame_count     = 58,
        line_length     = 8,
        scale           = 0.32,
        animation_speed = 0.3,
      },
      {
        filename        = "__armor-adventure__/graphics/entity/the-harvester/the-harvester-hr-shadow.png",
        priority        = "high",
        width           = 900,
        height          = 700,
        repeat_count    = 58,
        draw_as_shadow  = true,
        animation_speed = 0.3,
        scale           = 0.25,
      },
      {
        filename        = "__armor-adventure__/graphics/entity/the-harvester/the-harvester-emission-1.png",
        priority        = "high",
        width           = 500,
        height          = 500,
        frame_count     = 58,
        line_length     = 8,
        scale           = 0.32,
        animation_speed = 0.3,
        draw_as_glow    = true,
        blend_mode      = "additive",
      },
    }
  }
}
data:extend({harvester})

-- Mind Control Rocket: deepcopy of vanilla rocket projectile, damage replaced with
-- a script trigger that reassigns the hit entity's force to "player".
-- Area action (not direct) is required so target_entity is populated in
-- on_script_trigger_effect — direct actions on terrain-landing projectiles
-- produce nil target_entity, silently swallowed by the event handler.
local mc_proj = table.deepcopy(data.raw["projectile"]["rocket"])
mc_proj.name   = "neural-override-dart-projectile"
mc_proj.action = {
    type   = "area",
    radius = 2.5,
    action_delivery = {
        type = "instant",
        target_effects = {
            {type = "script", effect_id = "mind-control-hit"},
        }
    }
}
data:extend({mc_proj})

-- Massive Lightning Collector: 10× attraction range, 4×4 footprint, no grid output.
local massive_lc = table.deepcopy(data.raw["lightning-attractor"]["lightning-collector"])
massive_lc.name                           = "massive-lightning-collector"
massive_lc.minable                        = {mining_time = 0.5, result = "massive-lightning-collector"}
massive_lc.max_health                     = 2000
massive_lc.range_elongation               = 250.0
massive_lc.collision_box                  = {{-1.7, -1.7}, {1.7, 1.7}}
massive_lc.selection_box                  = {{-2, -2}, {2, 2}}
massive_lc.drawing_box_vertical_extension = 9.0
massive_lc.lightning_strike_offset        = {0, -9.6}
massive_lc.energy_source = {
    type                   = "electric",
    buffer_capacity        = "1000GJ",
    usage_priority         = "primary-output",
    output_flow_limit      = "0W",
    drain                  = "0W",
    render_no_power_icon   = false,
    render_no_network_icon = false,
}
massive_lc.factoriopedia_simulation = nil
scale_graphics(massive_lc.chargable_graphics, 2)
local cg = massive_lc.chargable_graphics
shift_layers(cg.picture,             0, -2)
shift_layers(cg.charge_animation,    0, -2)
shift_layers(cg.discharge_animation, 0, -2)
data:extend({massive_lc})

-- Armor Forging Station: assembling-machine-3 restricted to armor-forging category.
-- Quality and productivity effects/modules are intentionally blocked.
local forging_station = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-3"])
forging_station.name                      = "armor-forging-station"
forging_station.minable                   = {mining_time = 0.5, result = "armor-forging-station"}
forging_station.crafting_categories       = {"armor-forging"}
forging_station.allowed_effects           = {"speed", "consumption", "pollution"}
forging_station.allowed_module_categories = {"speed", "efficiency"}
forging_station.factoriopedia_simulation  = nil
forging_station.collision_box             = {{-1.9, -1.9}, {1.9, 1.9}}
forging_station.selection_box             = {{-2.0, -2.0}, {2.0, 2.0}}
forging_station.fluid_boxes = {
  {
    production_type = "input",
    filter          = "fluoroketone-cold",
    volume          = 1000,
    pipe_connections = {
      {flow_direction = "input", direction = defines.direction.north, position = {0, -1}},
    },
  },
}
forging_station.fluid_boxes_off_when_no_fluid_recipe = true
forging_station.icon                      = "__armor-adventure__/graphics/entity/armor-crafting-station/base/armor-crafting-station-icon.png"
forging_station.icon_size                 = 640
-- frame_count=64 estimated from the 4000×3840 sheet (8 cols × 500px, 8 rows × 480px).
-- color1 tint mask and frozen sprites exist but are not yet wired.
-- scale=0.33 matches the 4×4 collision box (was 0.5 for the original 6×6 footprint).
-- Rule: always scale collision box AND sprite together.
forging_station.graphics_set = {
  animation = {
    layers = {
      {
        filename        = "__armor-adventure__/graphics/entity/armor-crafting-station/base/armor-crafting-station-shadow.png",
        priority        = "high",
        width           = 900,
        height          = 500,
        frame_count     = 1,
        line_length     = 1,
        repeat_count    = 64,
        draw_as_shadow  = true,
        animation_speed = 0.3,
        scale           = 0.33,
        shift           = {0, -1},
      },
      {
        filename        = "__armor-adventure__/graphics/entity/armor-crafting-station/base/armor-crafting-station-animation.png",
        priority        = "high",
        width           = 400,
        height          = 480,
        frame_count     = 64,
        line_length     = 10,
        animation_speed = 0.3,
        scale           = 0.33,
        shift           = {0, -1},
      },
      {
        filename        = "__armor-adventure__/graphics/entity/armor-crafting-station/base/armor-crafting-station-emission1.png",
        priority        = "high",
        width           = 400,
        height          = 480,
        frame_count     = 64,
        line_length     = 10,
        animation_speed = 0.3,
        scale           = 0.33,
        shift           = {0, -1},
        draw_as_glow    = true,
        blend_mode      = "additive",
      },
      {
        filename        = "__armor-adventure__/graphics/entity/armor-crafting-station/base/armor-crafting-station-emission2.png",
        priority        = "high",
        width           = 400,
        height          = 480,
        frame_count     = 64,
        line_length     = 10,
        animation_speed = 0.3,
        scale           = 0.33,
        shift           = {0, -1},
        draw_as_glow    = true,
        blend_mode      = "additive",
      },
    }
  },
  reset_animation_when_frozen = true,
}
data:extend({forging_station})

-- Quantum Coil: hybrid item — laser turret when placed, laser defense when equipped
local quantum_coil_turret = table.deepcopy(data.raw["electric-turret"]["laser-turret"])
quantum_coil_turret.name         = "quantum-coil-turret"
quantum_coil_turret.minable      = {mining_time = 0.5, result = "quantum-coil"}
quantum_coil_turret.next_upgrade = nil
data:extend({quantum_coil_turret})


local ts_slow = table.deepcopy(data.raw["sticker"]["tesla-turret-slow"])
ts_slow.name                     = "time-stopper-slow"
ts_slow.duration_in_ticks        = 180
ts_slow.target_movement_modifier = 0.1
ts_slow.vehicle_speed_modifier   = 0.1
data:extend({ts_slow})

-- Simulac Mobile Fortress: scaled-up blue tank vehicle used as a Castra boss.
-- Not gated on castra-prime because the vanilla tank prototype is always present.
do
  local SMF_SCALE = 3.0
  local smf_blue  = {r = 0.05, g = 0.55, b = 1.0, a = 1}

  local smf = table.deepcopy(data.raw["car"]["tank"])
  smf.name             = "simulac-mobile-fortress"
  smf.color            = smf_blue
  smf.minable          = nil
  smf.next_upgrade     = nil
  smf.collision_mask   = {layers = {}}
  smf.max_health       = 200000
  smf.healing_per_tick = 400 / 60
  smf.resistances = {
    {type = "electric",  decrease = 20,  percent = 75},
    {type = "explosion", decrease = 50,  percent = 50},
    {type = "laser",     decrease = 100, percent = 85},
    {type = "physical",  decrease = 25,  percent = 60},
    {type = "poison",                    percent = 99},
    {type = "fire",      decrease = 25,  percent = 85},
  }

  -- Collision box not scaled: mask is empty so it's irrelevant for physics,
  -- and a large box caused shells to spawn inside the entity's zone.
  smf.selection_box = scale_box(smf.selection_box, SMF_SCALE)
  if smf.drawing_box_vertical_extension then
    smf.drawing_box_vertical_extension = smf.drawing_box_vertical_extension * SMF_SCALE
  end
  force_scale_graphics(smf.graphics_set, SMF_SCALE)
  apply_fixed_tint(smf.graphics_set, smf_blue)

  -- Custom grid that also accepts armor-adventure-mk2 equipment (e.g. personal-combat-roboport).
  local tank_grid_name = data.raw["car"]["tank"].equipment_grid
  if tank_grid_name and data.raw["equipment-grid"][tank_grid_name] then
    local smf_grid = table.deepcopy(data.raw["equipment-grid"][tank_grid_name])
    smf_grid.name = "simulac-mobile-fortress-grid"
    smf_grid.equipment_categories = {"armor", "armor-adventure-mk2"}
    data:extend({smf_grid})
    smf.equipment_grid = "simulac-mobile-fortress-grid"
  end

  data:extend({smf})
end

-- SMF projectile: passes through enemy buildings (collision = player layer only).
do
  local smf_shell = table.deepcopy(data.raw["projectile"]["cannon-projectile"])
  smf_shell.name           = "simulac-mobile-fortress-shell"
  smf_shell.collision_mask = {layers = {player = true}}
  data:extend({smf_shell})
end

-- SIMULAC Commander: a gold-tinted heavyweight version of the Castra enemy tank.
-- Only defined when castra-prime is loaded (provides castra-enemy-tank prototype).
if mods["castra-prime"] then
  local SIMULAC_SCALE = 3.0

  -- Ballistic cannon shell (direction_only = true, no homing).
  -- Deepcopy of vanilla cannon-projectile which is already non-tracking.
  local simulac_shell = table.deepcopy(data.raw["projectile"]["cannon-projectile"])
  simulac_shell.name           = "simulac-commander-shell"
  simulac_shell.starting_speed = 0.35
  simulac_shell.animation.scale = 4.0   -- visually larger shell
  simulac_shell.action = {
    type = "direct",
    action_delivery = {
      type = "instant",
      target_effects = {
        {type = "create-entity", entity_name = "big-explosion"},
        {type = "damage", damage = {amount = 2000, type = "explosion"}},
      },
    },
  }
  data:extend({simulac_shell})

  local commander = table.deepcopy(data.raw["unit"]["castra-enemy-tank"])
  commander.name            = "simulac-commander"
  commander.max_health      = 200000
  -- ~25 km/h; character run speed is 0.15, so this is slightly below sprint pace for a huge tank
  commander.movement_speed  = 0.12
  commander.healing_per_tick = 400 / 60

  commander.resistances = {
    {type = "electric",  decrease = 20,  percent = 75},
    {type = "explosion", decrease = 50,  percent = 50},
    {type = "laser",     decrease = 100, percent = 85},
    {type = "physical",  decrease = 25,  percent = 60},
    {type = "poison",                    percent = 99},
    {type = "fire",      decrease = 25,  percent = 85},
  }

  -- Scale the vertical drawing budget so the engine doesn't cull the top of the 3× sprite.
  if commander.drawing_box_vertical_extension then
    commander.drawing_box_vertical_extension = commander.drawing_box_vertical_extension * SIMULAC_SCALE
  end

  local gold = {r = 1, g = 0.8, b = 0, a = 1}
  if commander.run_animation then
    commander.run_animation.tint = gold
    scale_graphics(commander.run_animation, SIMULAC_SCALE)
  end

  -- Main cannon: traveling projectile (dodgeable), range 52, 2 rounds/s.
  -- The shell physically flies through the air; a moving player can outrun it.
  commander.attack_parameters = {
    type               = "projectile",
    range              = 52,
    cooldown           = 30,
    cooldown_deviation = 0.0,
    ammo_category      = "cannon-shell",
    ammo_type = {
      target_type = "entity",
      action = {
        type = "direct",
        action_delivery = {
          type           = "projectile",
          projectile     = "simulac-commander-shell",
          starting_speed = 0.35,
        },
      },
    },
    animation  = commander.run_animation,
    range_mode = "bounding-box-to-bounding-box",
  }

  commander.collision_box = scale_box(commander.collision_box, SIMULAC_SCALE)
  -- Selection box is hardcoded: the vanilla tank's box (~0.9×1.3) scaled 3× is still tiny
  -- relative to the enlarged sprite, so we set it explicitly to match the visual footprint.
  commander.selection_box = {{-4, -4}, {4, 4}}

  data:extend({commander})

  -- Mineable remains left by a dead SIMULAC Commander.
  -- The mine-entity research trigger on "operation-data-tap" fires when a player mines this.
  -- The filled data tap is given by script (quests/quests.lua); no native item drop needed.
  data:extend({{
    type          = "simple-entity",
    name          = "simulac-core-remains",
    icon          = "__base__/graphics/icons/uranium-235.png",
    icon_size     = 64,
    flags         = {"placeable-neutral", "not-blueprintable", "not-deconstructable"},
    render_layer  = "object",
    destructible  = false,
    minable = {
      mining_time = 2,
      results     = {},
    },
    picture = {
      filename = "__base__/graphics/icons/uranium-235.png",
      width    = 64,
      height   = 64,
      scale    = 3,
    },
    collision_box = {{-0.9, -0.9}, {0.9, 0.9}},
    selection_box = {{-1.2, -1.2}, {1.2, 1.2}},
  }})
end

-- Aquilo elevator shaft: assembling-machine-3 deepcopy restricted to the
-- aquilo-elevator-construction category so it only accepts the dig recipe.
local elevator_shaft = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-3"])
elevator_shaft.name                = "aquilo-elevator-shaft"
elevator_shaft.next_upgrade        = nil
elevator_shaft.minable             = {mining_time = 0.5, result = "aquilo-elevator-shaft"}
elevator_shaft.crafting_categories = {"aquilo-elevator-construction"}
elevator_shaft.crafting_speed      = 1.0
elevator_shaft.surface_conditions  = {{property = "aquilo-native", min = 1}}
data:extend({elevator_shaft})

-- Placeholder completed elevator (surface side) — chemical plant with no valid recipes.
-- Intentionally terrible so it gets replaced with real art.
local elevator_complete = table.deepcopy(data.raw["assembling-machine"]["chemical-plant"])
elevator_complete.name                = "aquilo-elevator-complete"
elevator_complete.next_upgrade        = nil
elevator_complete.minable             = {mining_time = 5.0, result = "aquilo-elevator-shaft"}
elevator_complete.flags               = {"placeable-neutral", "not-blueprintable", "not-deconstructable"}
elevator_complete.crafting_categories = {"aquilo-elevator-dummy"}
elevator_complete.destructible        = false
elevator_complete.energy_source       = {type = "void"}
data:extend({elevator_complete})

-- Placeholder ascent elevator (depot side) — same chemical plant hack.
local depot_ascent = table.deepcopy(data.raw["assembling-machine"]["chemical-plant"])
depot_ascent.name                = "aquilo-depot-ascent"
depot_ascent.next_upgrade        = nil
depot_ascent.minable             = nil
depot_ascent.flags               = {"placeable-neutral", "not-blueprintable", "not-deconstructable"}
depot_ascent.crafting_categories = {"aquilo-elevator-dummy"}
depot_ascent.destructible        = false
depot_ascent.energy_source       = {type = "void"}
data:extend({depot_ascent})

-- Remains entity spawned at a Big Demolisher's death position.
-- Mining it gives the Demolisher Heart and triggers "big-demolisher-hunt" research.
-- collision_mask empty so it can be placed on any tile.
data:extend({{
  type           = "simple-entity",
  name           = "big-demolisher-remains",
  icon           = "__base__/graphics/icons/heavy-armor.png",
  icon_size      = 64,
  flags          = {"placeable-neutral", "not-blueprintable", "not-deconstructable"},
  render_layer   = "object",
  destructible   = false,
  collision_mask = {layers = {}},
  minable = {
    mining_time = 2,
    results     = {{type = "item", name = "demolisher-heart", amount = 1}},
  },
  picture = {
    filename = "__base__/graphics/icons/heavy-armor.png",
    width    = 64,
    height   = 64,
    scale    = 4,
  },
  collision_box = {{-0.9, -0.9}, {0.9, 0.9}},
  selection_box = {{-1.2, -1.2}, {1.2, 1.2}},
}})

-- Remains entity spawned at the Gigantoid Spitter's death position.
-- Mining it triggers the "nauvis-defense-complete" research.
-- collision_mask empty so it can be placed on any tile.
data:extend({{
  type           = "simple-entity",
  name           = "gigantoid-remains",
  icon           = "__base__/graphics/icons/medium-biter.png",
  icon_size      = 64,
  flags          = {"placeable-neutral", "not-blueprintable", "not-deconstructable"},
  render_layer   = "object",
  destructible   = false,
  collision_mask = {layers = {}},
  minable = {
    mining_time = 2,
    results     = {{type = "item", name = "iron-plate", amount = 1}},
  },
  picture = {
    filename = "__base__/graphics/icons/medium-biter.png",
    width    = 64,
    height   = 64,
    scale    = 3,
  },
  collision_box = {{-0.9, -0.9}, {0.9, 0.9}},
  selection_box = {{-1.2, -1.2}, {1.2, 1.2}},
}})

-- Signal source entity spawned by script when Aquilo scanning completes.
-- Mining it triggers the "aquilo-scanning-complete" research.
-- collision_mask empty so it can be placed on any tile (ice, void edge, etc.).
data:extend({{
  type           = "simple-entity",
  name           = "aquilo-signal-source",
  icon           = "__base__/graphics/icons/radar.png",
  icon_size      = 64,
  flags          = {"placeable-neutral", "not-blueprintable", "not-deconstructable"},
  render_layer   = "object",
  destructible   = false,
  collision_mask = {layers = {}},
  minable = {
    mining_time = 3,
    results     = {{type = "item", name = "iron-plate", amount = 1}},
  },
  picture = {
    filename = "__base__/graphics/icons/radar.png",
    width    = 64,
    height   = 64,
    scale    = 3,
  },
  collision_box = {{-0.9, -0.9}, {0.9, 0.9}},
  selection_box = {{-1.2, -1.2}, {1.2, 1.2}},
}})

-- Pocket dimension chest: unminable, indestructible container spawned by script
-- into each player's pocket surface. Never craftable or placeable by the player.
local pd_chest = table.deepcopy(data.raw["container"]["steel-chest"])
pd_chest.name           = "pocket-dimension-chest"
pd_chest.next_upgrade   = nil
pd_chest.minable        = nil
pd_chest.destructible   = false
pd_chest.flags          = {"not-blueprintable", "not-deconstructable"}
pd_chest.inventory_size = 40
data:extend({pd_chest})

-- Cryovault chest: locked story chest in the Fulgoran depot room.
-- Player cannot open it (blocked in control.lua) until all puzzles are solved.
local cryovault_chest = table.deepcopy(data.raw["container"]["steel-chest"])
cryovault_chest.name           = "cryovault-chest"
cryovault_chest.next_upgrade   = nil
cryovault_chest.minable        = nil
cryovault_chest.destructible   = false
cryovault_chest.flags          = {"not-blueprintable", "not-deconstructable"}
cryovault_chest.inventory_size = 10
data:extend({cryovault_chest})

-- Vault card reader: player inserts an access card and closes the chest;
-- script detects it via on_gui_closed and swaps it for a quality-matched cryo core.
local vault_reader = table.deepcopy(data.raw["container"]["iron-chest"])
vault_reader.name           = "vault-card-reader"
vault_reader.next_upgrade   = nil
vault_reader.minable        = nil
vault_reader.destructible   = false
vault_reader.flags          = {"not-blueprintable", "not-deconstructable"}
vault_reader.inventory_size = 5
data:extend({vault_reader})

data:extend({
  {
    type          = "surface-property",
    name          = "pocket-magnitude",
    default_value = 0,
  },
  {
    -- Default 1 so normal surfaces satisfy roboport surface_conditions without explicit override.
    -- Pocket dim surfaces are set to 0 until the pocket-dimension-roboport tech is researched.
    type          = "surface-property",
    name          = "pocket-construction-access",
    default_value = 1,
  },
})

local char_anims = data.raw.character.character.animations
for _, entry in ipairs(char_anims) do
  if entry.armors then
    for _, name in ipairs(entry.armors) do
      if name == "mech-armor" then
        local mk2_anim = table.deepcopy(entry)
        mk2_anim.armors = {"mech-armor-mk2"}
        table.insert(char_anims, mk2_anim)
        break
      end
    end
  end
end

-- Actuator spark burst: streaking sparks emitted when running with Overcharged Actuators.
-- Uses vanilla spark-particle but with tails, high repeat count, and fast outward spread so
-- each burst leaves visible glowing streaks rather than static dots.
data:extend({{
  type       = "explosion",
  name       = "actuator-spark-burst",
  flags      = {"not-on-map"},
  hidden     = true,
  animations = {{
    filename        = "__core__/graphics/empty.png",
    priority        = "extra-high",
    width           = 1,
    height          = 1,
    frame_count     = 1,
    animation_speed = 1,
  }},
  created_effect = {
    type             = "direct",
    action_delivery  = {
      type           = "instant",
      target_effects = {{
        type                          = "create-particle",
        repeat_count                  = 8,
        particle_name                 = "spark-particle",
        offset_deviation              = {{-0.2, -0.2}, {0.2, 0.2}},
        initial_height                = 0.1,
        initial_height_deviation      = 0.05,
        initial_vertical_speed        = 0.0,
        initial_vertical_speed_deviation = 0.01,
        speed_from_center             = 0.07,
        speed_from_center_deviation   = 0.05,
        frame_speed                   = 1,
        tail_length                   = 12,
        tail_length_deviation         = 6,
        tail_width                    = 4,
      }},
    },
  },
}})

-- nauvis-native / aquilo-native surface properties: set to 1 on their respective planets
-- (in data-final-fixes.lua). Used by surface_conditions to restrict entity placement.
data:extend({
  {type = "surface-property", name = "nauvis-native", default_value = 0},
  {type = "surface-property", name = "aquilo-native", default_value = 0},
})

-- Pheromone Emitter: placeable device that attracts and spawns biters via script.
-- Based on vanilla beacon with all beacon effects zeroed out and void energy source.
-- surface_conditions restricts placement to Nauvis (nauvis-native = 1).
do
  local emitter = table.deepcopy(data.raw["beacon"]["beacon"])
  emitter.name                     = "pheromone-emitter"
  emitter.minable                  = {mining_time = 0.5, result = "pheromone-emitter"}
  emitter.max_health               = 1200
  emitter.energy_source            = {type = "void"}
  emitter.energy_usage             = "1W"
  emitter.supply_area_distance     = 0
  emitter.distribution_effectivity = 0
  emitter.module_slots             = 0
  emitter.allowed_effects          = {}
  emitter.surface_conditions       = {{property = "nauvis-native", min = 1}}
  data:extend({emitter})
end

-- Pheromone Emitter Nest: decorative invulnerable spawner placed around the emitter.
-- Purely visual — all biter production is scripted. Placed on neutral force so player
-- turrets and enemy AI ignore it. Destroyed by script when the emitter completes/fails.
do
  local nest = table.deepcopy(data.raw["unit-spawner"]["biter-spawner"])
  nest.name                       = "pheromone-emitter-nest"
  nest.destructible               = false
  nest.spawning_cooldown          = {999999, 999999}
  nest.max_count_of_owned_units   = 0
  nest.minable                    = nil
  nest.flags = {"not-blueprintable", "not-deconstructable", "not-repairable", "not-rotatable"}
  data:extend({nest})
end


-- Gigantoid Spitter: boss summoned when the Pheromone Emitter fully charges.
-- 5× visual scale of behemoth-spitter, 10× health and damage.
-- Script-spawned only; no pollution attraction, no spawner list entry.
do
  local VISUAL_SCALE = 8
  local STAT_SCALE   = 10

  local function scale_sprites(t, factor)
    if type(t) ~= "table" then return end
    if type(t.scale)          == "number" then t.scale          = t.scale          * factor end
    if type(t.multiply_shift) == "number" then t.multiply_shift = t.multiply_shift * factor end
    for _, v in pairs(t) do
      if type(v) == "table" then scale_sprites(v, factor) end
    end
  end

  local function scale_box(box, f)
    return {{box[1][1]*f, box[1][2]*f}, {box[2][1]*f, box[2][2]*f}}
  end

  local gs = table.deepcopy(data.raw["unit"]["behemoth-spitter"])
  gs.name        = "gigantoid-spitter"
  gs.hidden      = true
  gs.max_health  = 150000
  gs.collision_box = scale_box(gs.collision_box, VISUAL_SCALE)
  gs.selection_box = scale_box(gs.selection_box, VISUAL_SCALE)
  if gs.sticker_box then gs.sticker_box = scale_box(gs.sticker_box, VISUAL_SCALE) end
  gs.attack_parameters.damage_modifier = gs.attack_parameters.damage_modifier * STAT_SCALE
  scale_sprites(gs.run_animation,      VISUAL_SCALE)
  scale_sprites(gs.attack_parameters,  VISUAL_SCALE)
  if gs.water_reflection then scale_sprites(gs.water_reflection, VISUAL_SCALE) end
  gs.factoriopedia_simulation   = nil
  gs.spawning_time_modifier     = nil
  gs.absorptions_to_join_attack = nil
  data:extend({gs})
end

if mods["panglia_planet"] then
  -- Crystal node spawned at each destroyed beacon position after a nuke.
  -- Mining it drops essence-of-speed and triggers the time-fracking research.
  data:extend({{
    type           = "simple-entity",
    name           = "panglia-essence-node",
    icon           = "__base__/graphics/icons/speed-module-3.png",
    icon_size      = 64,
    flags          = {"placeable-neutral", "not-blueprintable"},
    render_layer   = "object",
    destructible   = false,
    collision_mask = {layers = {}},
    minable = {
      mining_time = 1,
      results     = {{type = "item", name = "panglia-essence-of-speed", amount = 5}},
    },
    picture = {
      filename = "__base__/graphics/icons/speed-module-3.png",
      width    = 64,
      height   = 64,
      scale    = 2,
    },
    collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
    selection_box = {{-0.6, -0.6}, {0.6, 0.6}},
  }})
end

if mods["planet-rabbasca"] then
  -- vault-entry-portal: placed by vault-entry-pass; on_built_entity teleports player and destroys it.
  local vault_portal = table.deepcopy(data.raw["container"]["iron-chest"])
  vault_portal.name           = "vault-entry-portal"
  vault_portal.next_upgrade   = nil
  vault_portal.minable        = {mining_time = 0.5, result = "vault-entry-pass"}
  vault_portal.inventory_size = 1
  vault_portal.flags          = {"not-blueprintable", "not-deconstructable"}
  data:extend({vault_portal})

  -- vault-tunnel-exit: indestructible entity placed in the tunnel; on_gui_opened shows Return GUI.
  local tunnel_exit = table.deepcopy(data.raw["assembling-machine"]["chemical-plant"])
  tunnel_exit.name                = "vault-tunnel-exit"
  tunnel_exit.next_upgrade        = nil
  tunnel_exit.minable             = nil
  tunnel_exit.flags               = {"placeable-neutral", "not-blueprintable", "not-deconstructable"}
  tunnel_exit.crafting_categories = {"aquilo-elevator-dummy"}
  tunnel_exit.destructible        = false
  tunnel_exit.energy_source       = {type = "void"}
  data:extend({tunnel_exit})

  -- ancient-rabbits-foote entity: placed in the tunnel; mining it triggers the conquer-the-vault research.
  data:extend({{
    type           = "simple-entity",
    name           = "ancient-rabbits-foote",
    icon           = "__base__/graphics/icons/copper-ore.png",
    icon_size      = 64,
    flags          = {"placeable-neutral", "not-blueprintable", "not-deconstructable"},
    render_layer   = "object",
    destructible   = false,
    collision_mask = {layers = {}},
    minable = {
      mining_time = 2,
      results     = {},  -- quality item given manually by on_player_mined_entity handler
    },
    picture = {
      filename = "__base__/graphics/icons/copper-ore.png",
      width    = 64,
      height   = 64,
      scale    = 3,
    },
    collision_box = {{-0.9, -0.9}, {0.9, 0.9}},
    selection_box = {{-1.2, -1.2}, {1.2, 1.2}},
  }})

  -- vault-laser-turret: Design B/D entity. Void energy source so it fires without a power grid.
  local laser_src = data.raw["electric-turret"]["laser-turret"]
  if laser_src then
    local vlt         = table.deepcopy(laser_src)
    vlt.name          = "vault-laser-turret"
    vlt.next_upgrade  = nil
    vlt.minable       = nil
    vlt.energy_source = {type = "void"}
    data:extend({vlt})
  end

  -- vault-artillery-turret: Design D entity. Long-range area bombardment from the back wall.
  local art_src = data.raw["artillery-turret"]["artillery-turret"]
  if art_src then
    local vat        = table.deepcopy(art_src)
    vat.name         = "vault-artillery-turret"
    vat.next_upgrade = nil
    vat.minable      = nil
    data:extend({vat})
  end
end

if mods["panglia_planet"] and mods["Moshine"] then
  local minutes = 60 * 60
  data:extend({{
    type    = "plant",
    name    = "processing-grid-process-essence-of-speed",
    icon    = "__base__/graphics/icons/speed-module-3.png",
    flags   = {"placeable-neutral"},
    minable = {
      mining_particle = "wooden-particle",
      mining_time     = 0.2,
      results         = {{type = "item", name = "panglia-refined-speed", amount = 1}},
    },
    growth_ticks    = 4 * minutes,
    max_health      = 50,
    collision_box   = {{-0.3, -0.3}, {0.3, 0.3}},
    selection_box   = {{-1, -1}, {1, 1}},
    sticker_box     = {{-1, -1}, {1, 1}},
    drawing_box_vertical_extension = 0.8,
    impact_category = "tree",
    autoplace       = {probability_expression = 0, tile_restriction = {"webbed_processor_tile"}},
    tile_buildability_rules = {{
      area           = {{-0.5, -0.5}, {0.5, 0.5}},
      required_tiles = {layers = {ground_tile = true}},
    }},
    -- Reuse the Moshine equation-plant glow animation as a placeholder.
    stateless_visualisation_variations = {{
      animation = {
        sheets = {{
          variation_count = 1,
          filenames       = {"__Moshine-assets__/graphics/entity/quantum-computer/plant.png"},
          size            = 128,
          lines_per_file  = 25,
          frame_count     = 100,
          animation_speed = 0.15,
          scale           = 0.5,
          draw_as_glow    = true,
          frame_sequence  = {
            1,2,3,1,4,5,6,1,7,8,9,10,10,11,12,1,1,13,14,15,15,13,16,17,1,18,1,19,19,20,21,22,1,22,23,1,24,25,1,12,5,6,1,15,11,7,1,8,5,4,
            1,1,3,1,11,5,6,1,22,8,9,1,10,1,12,1,1,3,4,1,1,13,16,17,1,16,1,1,1,1,1,22,1,22,7,1,24,6,1,1,1,1,1,1,7,7,1,11,5,1
          },
        }},
      },
    }},
    pictures  = {layers = {{filename = "__core__/graphics/empty.png", width = 1, height = 1}}},
    map_color = {200, 150, 255},
  }})
end
