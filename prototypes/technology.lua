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
  {
    type = "technology",
    name = "mech-armor-mk2-running-speed",
    icon = "__base__/graphics/technology/exoskeleton-equipment.png",
    icon_size = 256,
    prerequisites = {"mech-armor-mk2"},
    unit = {
      count = 10,
      ingredients = {{"electromagnetic-science-pack", 1}},
      time = 60,
    },
    effects = {
      {type = "character-running-speed", modifier = 1.0},
    },
  },
})

data:extend({
  {
    type = "technology",
    name = "regenerative-armor",
    icon = "__base__/graphics/technology/energy-shield-equipment.png",
    icon_size = 256,
    prerequisites = {"mech-armor-mk2"},
    unit = {
      count = 10,
      ingredients = {{"metallurgic-science-pack", 1}},
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "regenerative-plating"},
    },
  },
})

if mods["castra-prime"] then
  data:extend({
    {
      type = "technology",
      name = "personal-combat-roboport",
      icon = "__base__/graphics/technology/personal-roboport-equipment.png",
      icon_size = 256,
      prerequisites = {"mech-armor-mk2"},
      unit = {
        count = 10,
        ingredients = {{"battlefield-science-pack", 1}},
        time = 60,
      },
      effects = {
        {type = "unlock-recipe", recipe = "personal-combat-roboport"},
        {type = "unlock-recipe", recipe = "personal-combat-roboport-distractor"},
        {type = "unlock-recipe", recipe = "personal-combat-roboport-destroyer"},
      },
    },
  })
end
