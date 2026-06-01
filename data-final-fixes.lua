-- Parses Factorio energy strings like "240kW", "20kJ", or bare numbers.
local function parse_energy(val)
  if type(val) == "number" then return val end
  if type(val) ~= "string" then return 0 end
  if val == "infinite" then return math.huge end
  local num = tonumber(val:match("^([%d%.]+)")) or 0
  local prefix = val:match("^[%d%.]+([kMGTP]?)")
  local mult = {k=1e3, K=1e3, M=1e6, G=1e9, T=1e12, P=1e15}
  return num * (mult[prefix] or 1)
end

-- Poll all energy-shield-equipment prototypes (excluding our own) for the best stats.
local best_hp    = 0
local best_regen = 0  -- HP/second

for name, eq in pairs(data.raw["energy-shield-equipment"] or {}) do
  if name ~= "regenerative-plating" then
    best_hp = math.max(best_hp, eq.max_shield_value or 0)

    local cost = parse_energy(eq.energy_per_shield or 0)
    local flow = (eq.energy_source and parse_energy(eq.energy_source.input_flow_limit or 0)) or 0
    if cost > 0 and flow > 0 and flow ~= math.huge then
      best_regen = math.max(best_regen, flow / cost)
    end
  end
end

-- Fallback to vanilla mk1 baseline (50 HP, 240kW/20kJ = 12 HP/sec)
if best_hp    == 0 then best_hp    = 50 end
if best_regen == 0 then best_regen = 12 end

local REGEN_SECONDS = 900

local our_hp    = math.floor(best_hp * 10)
local our_regen = math.max(1, math.ceil(our_hp / REGEN_SECONDS))

-- Minimum-cost energy source: 1J per HP, buffer just large enough to fill the shield,
-- flow limit set to exactly what the target regen rate requires.
local regen = data.raw["energy-shield-equipment"]["regenerative-plating"]
if regen then
  regen.max_shield_value = our_hp
  regen.energy_per_shield = "1J"
  regen.energy_source = {
    type = "electric",
    buffer_capacity = our_hp .. "J",
    input_flow_limit = our_regen .. "W",
    usage_priority = "secondary-input",
  }
end

-- Pocket Dimension Generator: power = best other generator-equipment * 1.5.
-- Scanned here so it automatically scales if other mods add stronger generators.
local best_gen = 0
for name, eq in pairs(data.raw["generator-equipment"] or {}) do
  if name ~= "pocket-dimension-generator" then
    best_gen = math.max(best_gen, parse_energy(eq.power or 0))
  end
end
if best_gen == 0 then best_gen = 2500000 end  -- 2.5 MW fallback (vanilla fusion reactor)

local pdg = data.raw["generator-equipment"]["pocket-dimension-generator"]
if pdg then
  pdg.power = math.floor(best_gen * 1.5 / 1000) .. "kW"
end

-- personal-beacon variants are non-minable and must not have next_upgrade (other mods, e.g. Bob's, set it on all beacons).
for _, suffix in ipairs({"", "-uncommon", "-rare", "-epic", "-legendary"}) do
  local pb = data.raw["beacon"]["personal-beacon" .. suffix]
  if pb then pb.next_upgrade = nil end
end

-- Pocket dimension: disallow containers and solar panels on any surface with pocket-magnitude > 0.
-- Uses the native surface_conditions system so placement is blocked before it happens.
local pocket_condition = {property = "pocket-magnitude", max = 0}
for _, type_name in ipairs({"container", "logistic-container", "solar-panel"}) do
  for _, proto in pairs(data.raw[type_name] or {}) do
    proto.surface_conditions = proto.surface_conditions or {}
    proto.surface_conditions[#proto.surface_conditions + 1] = pocket_condition
  end
end

local roboport_condition = {property = "pocket-construction-access", min = 1}
for _, proto in pairs(data.raw["roboport"] or {}) do
  proto.surface_conditions = proto.surface_conditions or {}
  proto.surface_conditions[#proto.surface_conditions + 1] = roboport_condition
end

-- Pentapod tissue samples: recycle into themselves instead of enemy-biomass.
local pts_r = data.raw["recipe"]["pentapod-tissue-samples-recycling"]
if pts_r then
  pts_r.results = {{type = "item", name = "pentapod-tissue-samples", amount = 1, probability = 0.25}}
end

-- Flag each planet as its native surface so surface_conditions can gate entity placement.
local nauvis_planet = data.raw["planet"]["nauvis"]
if nauvis_planet then
  nauvis_planet.surface_properties = nauvis_planet.surface_properties or {}
  nauvis_planet.surface_properties["nauvis-native"] = 1
end

local aquilo_planet = data.raw["planet"]["aquilo"]
if aquilo_planet then
  aquilo_planet.surface_properties = aquilo_planet.surface_properties or {}
  aquilo_planet.surface_properties["aquilo-native"] = 1
end

-- Moshine: add raw-data (optical cable) fluid input on the east face of the foundry.
-- The foundry's existing fluid boxes use the default connection category; this one uses
-- "data" so optical cable can connect without conflicting with normal pipes.
-- fluid_boxes_off_when_no_fluid_recipe means this port is invisible until a matching
-- recipe is selected — no pollution to normal foundry use.
if mods["Moshine"] then
  local foundry = data.raw["assembling-machine"]["foundry"]
  if foundry and data.raw["fluid"]["raw-data"] then
    table.insert(foundry.fluid_boxes, {
      production_type  = "input",
      filter           = "raw-data",
      volume           = 10000,
      pipe_connections = {
        {flow_direction = "input", direction = defines.direction.east, position = {2, 0}, connection_category = "data"}
      },
    })
  end
end

-- Panglia: allow essence-of-speed to be planted in Moshine's compute farm.
if mods["panglia_planet"] and mods["Moshine"] then
    local pg = data.raw["agricultural-tower"]["processing-grid"]
    if pg and pg.accepted_seeds then
        table.insert(pg.accepted_seeds, "panglia-essence-of-speed")
    end
end

-- Panglia: inject a script trigger as the first effect on the atomic-rocket so we
-- can detect nuke detonations before area damage fires (beacons still alive at that point).
if mods["panglia_planet"] then
    local rocket = data.raw["projectile"]["atomic-rocket"]
    if rocket and rocket.action and rocket.action.action_delivery then
        table.insert(rocket.action.action_delivery.target_effects, 1, {
            type      = "script",
            effect_id = "armor_adventure_nuke_on_panglia",
        })
    end
end

-- Lightweight textures: when custom textures are disabled, replace the AFS and Harvester
-- graphics_set with sprites from already-loaded companion mods (zero extra VRAM cost).
-- Falls back to vanilla assembling-machine-3 if neither companion mod is present.
if not settings.startup["armor-adventure-custom-textures"].value then
  local function am3_graphics()
    local am3 = data.raw["assembling-machine"]["assembling-machine-3"]
    return am3 and {icon = am3.icon, icon_size = am3.icon_size, graphics_set = am3.graphics_set}
  end

  local afs = data.raw["assembling-machine"]["armor-forging-station"]
  if afs then
    if mods["castra-prime-assets"] then
      local CP = "__castra-prime-assets__/graphics/atom-forge/"
      afs.icon      = CP .. "atom-forge-icon.png"
      afs.icon_size = 64
      afs.graphics_set = {
        reset_animation_when_frozen = true,
        animation = { layers = {
          { filename = CP.."atom-forge-hr-shadow.png",
            width = 900, height = 500, frame_count = 1, repeat_count = 64,
            draw_as_shadow = true, animation_speed = 0.3, scale = 0.33, shift = {0,-1} },
          { filename = CP.."atom-forge-hr-animation-1.png",
            width = 400, height = 480, frame_count = 64, line_length = 8,
            animation_speed = 0.3, scale = 0.33, shift = {0,-1} },
          { filename = CP.."atom-forge-hr-emission-1.png",
            width = 400, height = 480, frame_count = 64, line_length = 8,
            animation_speed = 0.3, scale = 0.33, shift = {0,-1},
            draw_as_glow = true, blend_mode = "additive" },
        }},
      }
    else
      local fb = am3_graphics()
      if fb then afs.icon = fb.icon; afs.icon_size = fb.icon_size; afs.graphics_set = fb.graphics_set end
    end
  end

  local harvester = data.raw["assembling-machine"]["harvester"]
  if harvester then
    if mods["apia"] then
      local AP = "__apia__/graphics/entity/biosynthesizer/"
      harvester.icon      = "__apia__/graphics/icons/biosynthesizer-apia.png"
      harvester.icon_size = 64
      harvester.graphics_set = {
        animation = { layers = {
          { filename = AP.."biosynthesizer-animation.png",
            width = 500, height = 500, frame_count = 60, line_length = 8,
            animation_speed = 0.3, scale = 0.32, shift = {0,-0.35} },
          { filename = AP.."biosynthesizer-shadow.png",
            width = 900, height = 700, frame_count = 1, repeat_count = 60,
            draw_as_shadow = true, animation_speed = 0.3, scale = 0.32, shift = {0,-0.35} },
        }},
        frozen_patch = {
          filename = AP.."biosynthesizer-frozen.png",
          width = 500, height = 500, frame_count = 60, line_length = 8,
          animation_speed = 0.3, scale = 0.32, shift = {0,-0.35},
        },
        working_visualisations = {{
          fadeout = true, effect = "flicker",
          animation = {
            filename = AP.."biosynthesizer-emission.png",
            width = 500, height = 500, frame_count = 60, line_length = 8,
            animation_speed = 0.3, priority = "extra-high",
            blend_mode = "additive", draw_as_glow = true,
            scale = 0.32, shift = {0,-0.35},
          },
        }},
      }
    else
      local fb = am3_graphics()
      if fb then harvester.icon = fb.icon; harvester.icon_size = fb.icon_size; harvester.graphics_set = fb.graphics_set end
    end
  end
end

-- Personal Warp Pylon: invisible assembling-machine deepcopy of rabbasca-warp-pylon.
-- Must be a crafting machine so Rabbasca's warp dispatch cycle (awake → trigger item → attempt_build_ghost) works.
-- Graphics stripped via empty graphics_set so nothing is rendered.
if mods["planet-rabbasca"] then
  -- vault-entry-portal: restrict placement to Rabbasca using its own surface-condition API.
  local portal = data.raw["container"]["vault-entry-portal"]
  if portal then Rabbasca.only_on_harenic_surface(portal) end

  local src = data.raw["assembling-machine"]["rabbasca-warp-pylon"]
  if src then
    local personal_pylon                    = table.deepcopy(src)
    personal_pylon.name                     = "armor-adventure-personal-warp-pylon"
    personal_pylon.next_upgrade             = nil
    personal_pylon.minable                  = nil
    personal_pylon.allow_copy_paste         = false
    personal_pylon.collision_box            = {{-0.01, -0.01}, {0.01, 0.01}}
    personal_pylon.collision_mask           = {layers = {}}
    personal_pylon.selection_box            = {{-0.01, -0.01}, {0.01, 0.01}}
    personal_pylon.factoriopedia_simulation = nil
    personal_pylon.graphics_set             = {}
    personal_pylon.flags = {
      "not-on-map", "not-blueprintable", "not-deconstructable", "not-repairable",
    }
    data:extend({personal_pylon})
  end
end
