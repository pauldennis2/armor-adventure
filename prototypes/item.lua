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
    name         = "gleba-parts",
    icon         = "__base__/graphics/icons/behemoth-biter.png",
    subgroup     = "armor-adventure-materials",
    order        = "z[gleba-parts]",
    stack_size   = 50,
    spoil_ticks  = 7200,
    spoil_result = "spoilage",
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
    name          = "mind-control-rocket",
    icon          = "__base__/graphics/icons/rocket.png",
    ammo_category = "rocket",
    ammo_type = {
      action = {
        type = "direct",
        action_delivery = {
          type           = "projectile",
          projectile     = "mind-control-rocket-projectile",
          starting_speed = 0.1,
        }
      }
    },
    subgroup   = "armor-adventure-materials",
    order      = "d[rocket-launcher]-b[mind-control]",
    stack_size = 20,
  },
})

data:extend({
  {
    type       = "item",
    name       = "charged-lightning-gem",
    icon       = "__space-age__/graphics/icons/lightning-collector.png",
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
    name       = "bio-interface",
    icon       = "__base__/graphics/icons/electronic-circuit.png",
    subgroup   = "armor-adventure-materials",
    order      = "z[bio-interface]",
    stack_size = 50,
  },
  {
    type       = "item",
    name       = "aquilo-prom-suit-component",
    icon       = "__base__/graphics/icons/heavy-armor.png",
    subgroup   = "armor-adventure-materials",
    order      = "z[aquilo-prom-suit-component]",
    stack_size = 50,
  },
  {
    type       = "item",
    name       = "demolisher-heart",
    icon       = "__base__/graphics/icons/heavy-armor.png",
    subgroup   = "armor-adventure-materials",
    order      = "z[demolisher-heart]",
    stack_size = 1,
  },
  {
    type       = "item",
    name       = "promethium-armor-chassis",
    icon       = "__space-age__/graphics/icons/tungsten-plate.png",
    subgroup   = "armor-adventure-materials",
    order      = "z[promethium-armor-chassis]",
    stack_size = 10,
  },
  {
    type       = "item",
    name       = "promethium-armor-electronics",
    icon       = "__base__/graphics/icons/processing-unit.png",
    subgroup   = "armor-adventure-materials",
    order      = "z[promethium-armor-electronics]",
    stack_size = 10,
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
  },
  {
    type         = "item",
    name         = "legochest",
    icon         = "__base__/graphics/icons/steel-chest.png",
    place_result = "legochest",
    subgroup     = "armor-adventure-machines",
    order        = "z[legochest]",
    stack_size   = 10,
  },
})

data:extend({
  {
    type = "equipment-grid",
    name = "armor-adventure-mech-mk2-grid",
    width = 12,
    height = 14,
    equipment_categories = {"armor", "armor-adventure-mk2"},
  },
})

local mech_mk2 = table.deepcopy(data.raw["armor"]["mech-armor"])
mech_mk2.name                     = "mech-armor-mk2"
mech_mk2.equipment_grid           = "armor-adventure-mech-mk2-grid"
mech_mk2.inventory_size_bonus     = 60
mech_mk2.subgroup                 = "armor-adventure-armor"
mech_mk2.order                    = "f[mech-armor-mk2]"
mech_mk2.factoriopedia_simulation = nil
mech_mk2.resistances = {
  { type = "physical",  decrease = 20, percent = 65 },
  { type = "acid",      decrease = 10, percent = 80 },
  { type = "explosion", decrease = 70, percent = 60 },
  { type = "fire",      decrease = 20, percent = 80 },
  { type = "laser",     decrease = 10, percent = 20 },
}
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
    icon = "__base__/graphics/icons/personal-roboport-equipment.png",
    place_as_equipment_result = "personal-combat-roboport",
    subgroup = "armor-adventure-equipment",
    order = "f[personal-combat-roboport-a]",
    stack_size = 5,
  },
  {
    type = "item",
    name = "personal-combat-roboport-distractor",
    icon = "__base__/graphics/icons/distractor-capsule.png",
    place_as_equipment_result = "personal-combat-roboport-distractor",
    subgroup = "armor-adventure-equipment",
    order = "f[personal-combat-roboport-b]",
    stack_size = 5,
  },
  {
    type = "item",
    name = "personal-combat-roboport-destroyer",
    icon = "__base__/graphics/icons/destroyer-capsule.png",
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

if mods["planet-rabbasca"] then
  data:extend({{
    type = "item",
    name = "personal-warp-pylon-equipment",
    icon = "__base__/graphics/icons/roboport.png",
    place_as_equipment_result = "personal-warp-pylon-equipment",
    subgroup = "armor-adventure-equipment",
    order = "f[personal-warp-pylon-equipment]",
    stack_size = 1,
  }})
end

if mods["castra-prime"] then
  data:extend({
    {
      type       = "item",
      name       = "unrefined-simulac-core",
      icon       = "__base__/graphics/icons/tank.png",
      subgroup   = "armor-adventure-materials",
      order      = "z[simulac-core-a]",
      stack_size = 1,
    },
    {
      type       = "item",
      name       = "simulac-core",
      icon       = "__base__/graphics/icons/uranium-235.png",
      subgroup   = "armor-adventure-materials",
      order      = "z[simulac-core-b]",
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
    name       = "nauvis-armor-piece",
    icon       = "__base__/graphics/icons/medium-biter.png",
    icon_size  = 64,
    subgroup   = "armor-adventure-materials",
    order      = "n[nauvis-armor-piece]",
    stack_size = 10,
  },
})
