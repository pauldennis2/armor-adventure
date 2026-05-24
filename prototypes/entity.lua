local function scale_graphics(t, factor)
  if type(t) ~= "table" then return end
  if t.scale ~= nil then t.scale = t.scale * factor end
  for _, v in pairs(t) do scale_graphics(v, factor) end
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
