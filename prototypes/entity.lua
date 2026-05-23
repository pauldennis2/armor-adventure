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
-- Personal Beacon: a real beacon entity that follows the player.
-- No collision so it doesn't block building; small selection box so player can click it.
-- Placed 1 tile above the player so it's distinguishable from the character.
local personal_beacon = table.deepcopy(data.raw["beacon"]["beacon"])
personal_beacon.name                 = "personal-beacon"
personal_beacon.minable              = nil
personal_beacon.allow_copy_paste     = false
personal_beacon.collision_box        = {{-0.01, -0.01}, {0.01, 0.01}}
personal_beacon.collision_mask       = {layers = {}}
personal_beacon.selection_box        = {{-0.5, -0.5}, {0.5, 0.5}}
personal_beacon.supply_area_distance = 4
personal_beacon.is_military_target   = false
personal_beacon.flags = {
  "not-on-map", "not-blueprintable", "not-deconstructable", "not-repairable",
}
-- Void energy source: beacon is always powered, no external network required.
personal_beacon.energy_source = {type = "void"}
-- Strip body/animation graphics; keep module icons so the player can see what's loaded.
personal_beacon.graphics_set = {module_icons_suppressed = false}
personal_beacon.radius_visualisation_picture = nil
data:extend({personal_beacon})

-- Harvester: assembling-machine deepcopy restricted to the "harvesting" crafting category.
-- Script auto-sets the recipe and feeds enemy-biomass into the input inventory.
local harvester = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-1"])
harvester.name                     = "harvester"
harvester.minable                  = {mining_time = 0.5, result = "harvester"}
harvester.crafting_categories      = {"harvesting"}
harvester.crafting_speed           = 1.0
harvester.factoriopedia_simulation = nil
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
forging_station.name                     = "armor-forging-station"
forging_station.minable                  = {mining_time = 0.5, result = "armor-forging-station"}
forging_station.crafting_categories      = {"armor-forging"}
forging_station.allowed_effects          = {"speed", "consumption", "pollution"}
forging_station.allowed_module_categories = {"speed", "efficiency"}
forging_station.factoriopedia_simulation = nil
data:extend({forging_station})

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
