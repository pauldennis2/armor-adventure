data:extend({
  {type = "equipment-category", name = "armor-adventure-mk2"},
})

data:extend({
  {
    type       = "item",
    name         = "enemy-biomass",
    icon         = "__base__/graphics/icons/iron-plate.png",
    hidden       = true,
    subgroup     = "armor-adventure-materials",
    order        = "z[enemy-biomass]",
    stack_size   = 500,
    spoil_ticks  = 7200,
    spoil_result = "spoilage",
  },
  {
    type         = "item",
    name       = "pentapod-tissue-samples",
    icon       = "__base__/graphics/icons/behemoth-biter.png",
    subgroup   = "armor-adventure-materials",
    order      = "z[pentapod-tissue-samples]",
    stack_size = 50,
  },
  {
    type         = "item",
    name         = "harvester",
    icon         = "__armor-adventure__/graphics/entity/the-harvester/the-harvester-icon.png",
    place_result = "harvester",
    subgroup     = "armor-adventure-machines",
    order        = "z[harvester]",
    stack_size   = 10,
  },
  {
    type         = "item",
    name         = "aquilo-elevator-shaft",
    icon         = "__base__/graphics/icons/assembling-machine-3.png",
    icon_size    = 64,
    place_result = "aquilo-elevator-shaft",
    subgroup     = "armor-adventure-machines",
    order        = "z[aquilo-elevator-shaft]",
    stack_size   = 1,
  },
})

data:extend({
  {
    type          = "ammo",
    name          = "neural-override-dart",
    icon          = "__base__/graphics/icons/rocket.png",
    ammo_category = "rocket",
    ammo_type = {
      action = {
        type = "direct",
        action_delivery = {
          type           = "projectile",
          projectile     = "neural-override-dart-projectile",
          starting_speed = 0.1,
        }
      }
    },
    subgroup   = "armor-adventure-materials",
    order      = "d[rocket-launcher]-b[neural-override]",
    stack_size = 20,
    weight     = 10 * tons,
  },
})

data:extend({
  {
    type       = "item",
    name       = "charged-lightning-gem",
    icon       = "__armor-adventure__/graphics/icons/charged-lightning-gem.png",
    subgroup   = "armor-adventure-materials",
    order      = "z[charged-lightning-gem]",
    stack_size = 10,
  },
  {
    type         = "item",
    name         = "massive-lightning-collector",
    icon         = "__space-age__/graphics/icons/lightning-collector.png",
    place_result = "massive-lightning-collector",
    subgroup     = "armor-adventure-machines",
    order        = "f[massive-lightning-collector]",
    stack_size   = 5,
  },
})

data:extend({
  {
    type                      = "item",
    name                      = "armor-forging-station",
    icon                      = "__armor-adventure__/graphics/entity/armor-crafting-station/base/armor-crafting-station-icon.png",
    icon_size                 = 640,
    place_result              = "armor-forging-station",
    place_as_equipment_result = "armor-forging-station-equipment",
    subgroup                  = "armor-adventure-machines",
    order                     = "z[armor-forging-station]",
    stack_size                = 5,
  },
  {
    type       = "item",
    name                      = "bio-interface",
    icon                      = "__base__/graphics/icons/electronic-circuit.png",
    subgroup                  = "armor-adventure-materials",
    order                     = "z[bio-interface]",
    stack_size                = 50,
    place_as_equipment_result = "bio-interface-equipment",
  },
{
    type       = "item",
    name       = "demolisher-heart",
    icon       = "__base__/graphics/icons/heavy-armor.png",
    subgroup   = "armor-adventure-materials",
    order      = "z[demolisher-heart]",
    stack_size = 5,
  },
  {
    type       = "item",
    name       = "demolisher-heart-fragment-large",
    icon       = "__base__/graphics/icons/heavy-armor.png",
    subgroup   = "armor-adventure-materials",
    order      = "z[demolisher-heart-fragment-a]",
    stack_size = 10,
  },
  {
    type       = "item",
    name       = "demolisher-heart-fragment-small",
    icon       = "__base__/graphics/icons/medium-biter.png",
    subgroup   = "armor-adventure-materials",
    order      = "z[demolisher-heart-fragment-b]",
    stack_size = 50,
  },
  {
    type       = "item",
    name                      = "promethium-armor-chassis",
    icon                      = "__space-age__/graphics/icons/tungsten-plate.png",
    subgroup                  = "armor-adventure-materials",
    order                     = "z[promethium-armor-chassis]",
    stack_size                = 10,
    place_as_equipment_result = "promethium-armor-chassis-equipment",
  },
  {
    type       = "item",
    name                      = "promethium-armor-electronics",
    icon                      = "__base__/graphics/icons/processing-unit.png",
    subgroup                  = "armor-adventure-materials",
    order                     = "z[promethium-armor-electronics]",
    stack_size                = 10,
    place_as_equipment_result = "promethium-armor-electronics-equipment",
  },
  {
    type                    = "item",
    name                    = "quantum-coil",
    icon                    = "__base__/graphics/icons/personal-laser-defense-equipment.png",
    place_result            = "quantum-coil-turret",
    place_as_equipment_result = "quantum-coil-equipment",
    subgroup                = "armor-adventure-equipment",
    order                   = "z[quantum-coil]",
    stack_size              = 5,
    hidden                  = true,
  },

})

data:extend({
  {
    type = "equipment-grid",
    name = "armor-adventure-mech-mk2-grid",
    width = 12,
    height = 12,
    equipment_categories = {"armor", "armor-adventure-mk2"},
  },
})

local mech_mk2 = table.deepcopy(data.raw["armor"]["mech-armor"])
mech_mk2.name                     = "mech-armor-mk2"
mech_mk2.equipment_grid           = "armor-adventure-mech-mk2-grid"
mech_mk2.inventory_size_bonus     = 50
mech_mk2.subgroup                 = "armor-adventure-armor"
mech_mk2.order                    = "f[mech-armor-mk2]"
mech_mk2.factoriopedia_simulation = nil
if settings.startup["armor-adventure-buffed-resistances"].value then
  mech_mk2.resistances = {
    { type = "physical",  decrease = 25, percent = 60 },
    { type = "acid",      decrease = 10, percent = 85 },
    { type = "explosion", decrease = 70, percent = 60 },
    { type = "fire",      decrease = 20, percent = 85 },
    { type = "laser",     decrease = 10, percent = 50 },
    { type = "poison",    decrease =  5, percent = 80 },
    { type = "electric",  decrease = 10, percent = 50 },
    { type = "impact",    decrease =  0, percent = 50 },
  }
  if mods["bobwarfare"] then
    table.insert(mech_mk2.resistances, { type = "bob-plasma", decrease = 0, percent = 90 })
  end
else
  mech_mk2.resistances = {
    { type = "physical",  decrease = 20, percent = 65 },
    { type = "acid",      decrease = 10, percent = 80 },
    { type = "explosion", decrease = 70, percent = 60 },
    { type = "fire",      decrease = 20, percent = 80 },
    { type = "laser",     decrease = 10, percent = 20 },
    { type = "poison",    decrease =  0, percent = 70 },
  }
end
data:extend({ mech_mk2 })

data:extend({
  {
    type = "item",
    name = "regenerative-plating",
    icon = "__base__/graphics/icons/energy-shield-equipment.png",
    place_as_equipment_result = "regenerative-plating",
    subgroup = "armor-adventure-equipment",
    order = "f[regenerative-plating]",
    stack_size = 5,
  },
  {
    type = "item",
    name = "personal-combat-roboport",
    icon = "__armor-adventure__/graphics/icons/pcr-defender.png",
    place_as_equipment_result = "personal-combat-roboport",
    subgroup = "armor-adventure-equipment",
    order = "f[personal-combat-roboport-a]",
    stack_size = 5,
  },
  {
    type = "item",
    name = "personal-combat-roboport-distractor",
    icon = "__armor-adventure__/graphics/icons/pcr-distractor.png",
    place_as_equipment_result = "personal-combat-roboport-distractor",
    subgroup = "armor-adventure-equipment",
    order = "f[personal-combat-roboport-b]",
    stack_size = 5,
  },
  {
    type = "item",
    name = "personal-combat-roboport-destroyer",
    icon = "__armor-adventure__/graphics/icons/pcr-destroyer.png",
    place_as_equipment_result = "personal-combat-roboport-destroyer",
    subgroup = "armor-adventure-equipment",
    order = "f[personal-combat-roboport-c]",
    stack_size = 5,
  },
  -- TODO: delete personal-robot-stash entirely once confirmed unused
  {
    type = "item",
    name = "personal-robot-stash",
    icon = "__base__/graphics/icons/construction-robot.png",
    place_as_equipment_result = "personal-robot-stash",
    subgroup = "armor-adventure-equipment",
    order = "f[personal-robot-stash]",
    stack_size = 1,
    hidden = true,
  },
  {
    type = "item",
    name = "personal-beacon-equipment",
    icon = "__base__/graphics/icons/beacon.png",
    place_as_equipment_result = "personal-beacon-equipment",
    subgroup = "armor-adventure-equipment",
    order = "f[personal-beacon-equipment]",
    stack_size = 1,
  },
  {
    type = "item",
    name = "pocket-dimension-generator",
    icon = "__base__/graphics/icons/personal-roboport-equipment.png",
    place_as_equipment_result = "pocket-dimension-generator",
    subgroup = "armor-adventure-equipment",
    order = "f[pocket-dimension-generator]",
    stack_size = 1,
  },
  {
    type = "item",
    name = "personal-tesla-turret",
    icon = "__space-age__/graphics/icons/teslagun.png",
    icon_size = 64,
    place_as_equipment_result = "personal-tesla-turret",
    subgroup = "armor-adventure-equipment",
    order = "f[personal-tesla-turret]",
    stack_size = 1,
  },
  {
    type = "item",
    name = "personal-time-stopper",
    icon = "__base__/graphics/icons/battery-mk2-equipment.png",
    place_as_equipment_result = "personal-time-stopper",
    subgroup = "armor-adventure-equipment",
    order = "f[personal-time-stopper]",
    stack_size = 1,
  },
})

if mods["Moshine"] then
  data:extend({{
    type        = "item",
    name        = "unstable-magnetized-data-core",
    icon        = "__base__/graphics/icons/uranium-fuel-cell.png",
    icon_size   = 64,
    subgroup    = "armor-adventure-materials",
    order       = "z[unstable-magnetized-data-core]",
    stack_size  = 1,
  }})

  -- Moshine quest: motion-data outputs and their hidden scripted-ingredient tokens.
  -- Tokens are inserted by quests/moshine.lua when a qualifying train is detected;
  -- the data-processor recipe consumes one token + 100 raw-data per craft.
  data:extend({
    {
      type        = "item",
      name        = "deosil-motion-data",
      icon        = "__base__/graphics/icons/iron-plate.png",
      icon_size   = 64,
      subgroup    = "moshine-processes",
      order       = "z[deosil-motion-data]",
      stack_size  = 50,
      spoil_ticks = 120,  -- 2 seconds
    },
    {
      type        = "item",
      name        = "widdershins-motion-data",
      icon        = "__base__/graphics/icons/copper-plate.png",
      icon_size   = 64,
      subgroup    = "moshine-processes",
      order       = "z[widdershins-motion-data]",
      stack_size  = 50,
      spoil_ticks = 120,  -- 2 seconds
    },
    {
      type                    = "item",
      name                    = "deosil-scan-token",
      icon                    = "__base__/graphics/icons/green-wire.png",
      icon_size               = 64,
      hidden                  = true,
      hidden_in_factoriopedia = true,
      subgroup                = "moshine-processes",
      order                   = "z[deosil-scan-token]",
      stack_size              = 1,
      spoil_ticks             = 60,
    },
    {
      type                    = "item",
      name                    = "widdershins-scan-token",
      icon                    = "__base__/graphics/icons/red-wire.png",
      icon_size               = 64,
      hidden                  = true,
      hidden_in_factoriopedia = true,
      subgroup                = "moshine-processes",
      order                   = "z[widdershins-scan-token]",
      stack_size              = 1,
      spoil_ticks             = 60,
    },
    {
      type       = "item",
      name       = "vortex-data-card",
      icon       = "__Moshine__/graphics/icons/datacell-solved-equation.png",
      icon_size  = 64,
      subgroup   = "moshine-processes",
      order      = "z[vortex-data-card]",
      stack_size = 20,
    },
  })
end

if mods["panglia_planet"] then
  if mods["Moshine"] then
    -- tool type so agricultural-tower (compute farm) can plant it; durability=1 = one use per seed
    data:extend({{
      type         = "tool",
      name         = "panglia-essence-of-speed",
      icon         = "__base__/graphics/icons/speed-module-3.png",
      subgroup     = "armor-adventure-materials",
      order        = "z[panglia-essence-of-speed]",
      stack_size   = 50,
      durability   = 1,
      plant_result = "processing-grid-process-essence-of-speed",
    }})
  else
    data:extend({{
      type       = "item",
      name       = "panglia-essence-of-speed",
      icon       = "__base__/graphics/icons/speed-module-3.png",
      subgroup   = "armor-adventure-materials",
      order      = "z[panglia-essence-of-speed]",
      stack_size = 50,
    }})
  end
  data:extend({{
    type       = "item",
    name       = "panglia-refined-speed",
    icon       = "__panglia_planet__/graphics/icons/panglia_hidden_beacon.png",
    subgroup   = "armor-adventure-materials",
    order      = "z[panglia-refined-speed]",
    stack_size = 50,
  }})
end

if mods["planet-rabbasca"] then
  -- Private ammo category with no associated gun — the excavation key is ammo by type
  -- (matching the Rabbasca key aesthetic) but cannot be loaded into any weapon.
  data:extend({{type = "ammo-category", name = "armor-adventure-vault-key"}})

  data:extend({
    {
      type                      = "item",
      name                      = "personal-warp-pylon-equipment",
      icon                      = "__base__/graphics/icons/roboport.png",
      place_as_equipment_result = "personal-warp-pylon-equipment",
      subgroup                  = "armor-adventure-equipment",
      order                     = "f[personal-warp-pylon-equipment]",
      stack_size                = 1,
    },
    {
      type      = "ammo",
      name      = "vault-excavation-key",
      icon      = "__base__/graphics/icons/electronic-circuit.png",
      icon_size = 64,
      subgroup  = "armor-adventure-materials",
      order     = "z[vault-excavation-key]",
      stack_size    = 10,
      ammo_category = "armor-adventure-vault-key",
      ammo_type = {
        action = {type = "direct", action_delivery = {type = "instant"}},
      },
    },
    {
      type         = "item",
      name         = "vault-entry-pass",
      icon         = "__base__/graphics/icons/advanced-circuit.png",
      icon_size    = 64,
      subgroup     = "armor-adventure-materials",
      order        = "z[vault-entry-pass]",
      stack_size   = 1,
      place_result = "vault-entry-portal",
    },
    {
      type       = "item",
      name       = "rabbit-mcguffin",
      icon       = "__base__/graphics/icons/copper-ore.png",
      icon_size  = 64,
      subgroup   = "armor-adventure-materials",
      order      = "z[rabbit-mcguffin]",
      stack_size = 1,
    },
  })
end

if mods["castra-prime"] then
  data:extend({
    {
      type       = "item",
      name       = "simulac-data-tap",
      icon       = "__base__/graphics/icons/battery-mk2-equipment.png",
      subgroup   = "armor-adventure-materials",
      order      = "z[simulac-data-tap-a]",
      stack_size = 5,
    },
    {
      type       = "item",
      name       = "simulac-data-tap-filled",
      icon       = "__base__/graphics/icons/uranium-fuel-cell.png",
      subgroup   = "armor-adventure-materials",
      order      = "z[simulac-data-tap-b]",
      stack_size = 1,
    },
  })
end

data:extend({
  {
    type         = "item",
    name         = "pheromone-emitter",
    icon         = "__base__/graphics/icons/poison-capsule.png",
    icon_size    = 64,
    subgroup     = "armor-adventure-machines",
    order        = "p[pheromone-emitter]",
    stack_size   = 1,
    place_result = "pheromone-emitter",
  },
  {
    type       = "item",
    name       = "cryovault-access-card",
    icon       = "__base__/graphics/icons/electronic-circuit.png",
    icon_size  = 64,
    subgroup   = "armor-adventure-materials",
    order      = "n[cryovault-access-card]",
    stack_size = 1,
  },
  {
    type       = "item",
    name       = "cryo-core",
    icon       = "__space-age__/graphics/icons/cryogenic-science-pack.png",
    icon_size  = 64,
    subgroup   = "armor-adventure-materials",
    order      = "n[cryo-core]",
    stack_size = 1,
  },
  {
    type       = "item",
    name                      = "thermodynamic-regulator",
    icon                      = "__base__/graphics/icons/processing-unit.png",
    icon_size                 = 64,
    subgroup                  = "armor-adventure-materials",
    order                     = "n[thermodynamic-regulator]",
    stack_size                = 10,
    place_as_equipment_result = "thermodynamic-regulator-equipment",
  },
  {
    type       = "item",
    name       = "gigantic-chitinous-shell",
    icon       = "__base__/graphics/icons/behemoth-biter.png",
    icon_size  = 64,
    subgroup   = "armor-adventure-materials",
    order      = "n[gigantic-chitinous-shell]",
    stack_size = 10,
  },
  {
    type       = "item",
    name                      = "nauvis-armor-piece",
    icon                      = "__base__/graphics/icons/medium-biter.png",
    icon_size                 = 64,
    subgroup                  = "armor-adventure-materials",
    order                     = "n[nauvis-armor-piece]",
    stack_size                = 10,
    place_as_equipment_result = "nauvis-armor-piece-equipment",
  },
})
