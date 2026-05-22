data:extend({
  {
    type = "technology",
    name = "mech-armor-mk2",
    icon = "__space-age__/graphics/technology/mech-armor.png",
    icon_size = 256,
    prerequisites = {"mech-armor"},
    unit = {
      count = 10,
      ingredients = {{"automation-science-pack", 1}},
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "mech-armor-mk2"},
    },
  },
})
