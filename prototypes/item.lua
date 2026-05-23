data:extend({
  {type = "equipment-category", name = "armor-adventure-mk2"},
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
    subgroup = "utility-equipment",
    order = "f[regenerative-plating]",
    stack_size = 5,
  },
  {
    type = "item",
    name = "personal-combat-roboport",
    icon = "__base__/graphics/icons/personal-roboport-equipment.png",
    place_as_equipment_result = "personal-combat-roboport",
    subgroup = "utility-equipment",
    order = "f[personal-combat-roboport-a]",
    stack_size = 5,
  },
  {
    type = "item",
    name = "personal-combat-roboport-distractor",
    icon = "__base__/graphics/icons/distractor-capsule.png",
    place_as_equipment_result = "personal-combat-roboport-distractor",
    subgroup = "utility-equipment",
    order = "f[personal-combat-roboport-b]",
    stack_size = 5,
  },
  {
    type = "item",
    name = "personal-combat-roboport-destroyer",
    icon = "__base__/graphics/icons/destroyer-capsule.png",
    place_as_equipment_result = "personal-combat-roboport-destroyer",
    subgroup = "utility-equipment",
    order = "f[personal-combat-roboport-c]",
    stack_size = 5,
  },
  {
    type = "item",
    name = "personal-robot-stash",
    icon = "__base__/graphics/icons/construction-robot.png",
    place_as_equipment_result = "personal-robot-stash",
    subgroup = "utility-equipment",
    order = "f[personal-robot-stash]",
    stack_size = 1,
  },
  {
    type = "item",
    name = "personal-beacon-equipment",
    icon = "__base__/graphics/icons/beacon.png",
    place_as_equipment_result = "personal-beacon-equipment",
    subgroup = "utility-equipment",
    order = "f[personal-beacon-equipment]",
    stack_size = 1,
  },
})
