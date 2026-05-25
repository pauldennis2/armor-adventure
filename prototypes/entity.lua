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
local harvester = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"])
harvester.name                     = "harvester"
harvester.minable                  = {mining_time = 0.5, result = "harvester"}
harvester.crafting_categories      = {"harvesting"}
harvester.crafting_speed           = 1.0
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
local mc_proj = table.deepcopy(data.raw["projectile"]["rocket"])
mc_proj.name   = "mind-control-rocket-projectile"
mc_proj.action = {
    type = "direct",
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
forging_station.collision_box             = {{-2.9, -2.9}, {2.9, 2.9}}
forging_station.selection_box             = {{-3.0, -3.0}, {3.0, 3.0}}
forging_station.fluid_boxes               = nil
forging_station.fluid_boxes_off_when_no_fluid_recipe = nil
forging_station.icon                      = "__armor-adventure__/graphics/entity/armor-crafting-station/base/armor-crafting-station-icon.png"
forging_station.icon_size                 = 640
-- frame_count=64 estimated from the 4000×3840 sheet (8 cols × 500px, 8 rows × 480px).
-- color1 tint mask and frozen sprites exist but are not yet wired.
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
        scale           = 0.5,
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
        scale           = 0.5,
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
        scale           = 0.5,
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
        scale           = 0.5,
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
quantum_coil_turret.name    = "quantum-coil-turret"
quantum_coil_turret.minable = {mining_time = 0.5, result = "quantum-coil"}
data:extend({quantum_coil_turret})

-- Legochest: concept-test for quality-gated recipe ingredients
local legochest = table.deepcopy(data.raw["container"]["steel-chest"])
legochest.name           = "legochest"
legochest.minable        = {mining_time = 0.5, result = "legochest"}
legochest.inventory_size = 100
data:extend({legochest})

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
  -- The mine-entity research trigger on "core-hunt" fires when a player mines this.
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
      results     = {{type = "item", name = "unrefined-simulac-core", amount = 1}},
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

local char_anims = data.raw.character.character.animations
for _, entry in ipairs(char_anims) do
  if entry.armors then
    for _, name in ipairs(entry.armors) do
      if name == "mech-armor" then
        local mk2_anim = table.deepcopy(entry)
        mk2_anim.armors = {"mech-armor-mk2"}
        apply_fixed_tint(mk2_anim, hot_rod_red)
        table.insert(char_anims, mk2_anim)
        break
      end
    end
  end
end
