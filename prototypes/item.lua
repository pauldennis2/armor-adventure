data:extend({
  {
    type = "equipment-grid",
    name = "armor-adventure-mech-mk2-grid",
    width = 12,
    height = 14,
    equipment_categories = {"armor"},
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
