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
    name = "personal-robot-stash",
    hidden = true,
    icon = "__base__/graphics/technology/personal-roboport-equipment.png",
    icon_size = 256,
    prerequisites = {"mech-armor-mk2"},
    unit = {
      count = 10,
      ingredients = {{"automation-science-pack", 1}},
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "personal-robot-stash"},
    },
  },
})

data:extend({
  {
    type = "technology",
    name = "personal-beacon",
    icon = "__base__/graphics/technology/personal-roboport-equipment.png",
    icon_size = 256,
    prerequisites = {"mech-armor-mk2"},
    unit = {
      count = 20,
      ingredients = {{"electromagnetic-science-pack", 1}},
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "personal-beacon-equipment"},
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

data:extend({
  {
    type = "technology",
    name = "pocket-dimension",
    icon = "__base__/graphics/technology/personal-roboport-equipment.png",
    icon_size = 256,
    prerequisites = {"mech-armor-mk2"},
    unit = {
      count = 10,
      ingredients = {{"automation-science-pack", 1}},
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "pocket-dimension-generator"},
    },
  },
})

data:extend({
  {
    type = "technology",
    name = "personal-tesla-turret",
    icon = "__base__/graphics/technology/personal-laser-defense-equipment.png",
    icon_size = 256,
    prerequisites = {"mech-armor-mk2", "tesla-weapons"},
    unit = {
      count = 20,
      ingredients = {{"electromagnetic-science-pack", 1}},
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "personal-tesla-turret"},
    },
  },
})

data:extend({
  {
    type = "technology",
    name = "personal-time-stopper",
    icon = "__base__/graphics/technology/battery-mk2-equipment.png",
    icon_size = 256,
    prerequisites = {"mech-armor-mk2"},
    unit = {
      count = 20,
      ingredients = {{"electromagnetic-science-pack", 1}},
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "personal-time-stopper"},
    },
  },
})

data:extend({
  {
    type = "technology",
    name = "personal-fridge",
    icon = "__space-age__/graphics/technology/agriculture.png",
    icon_size = 256,
    prerequisites = {"mech-armor-mk2"},
    unit = {
      count = 10,
      ingredients = {{"agricultural-science-pack", 1}},
      time = 60,
    },
  },
})

if mods["planet-rabbasca"] then
  data:extend({{
    type = "technology",
    name = "personal-warp-pylon",
    icon = "__base__/graphics/technology/personal-roboport-equipment.png",
    icon_size = 256,
    prerequisites = {"mech-armor-mk2", "interplanetary-construction-1"},
    unit = {
      count = 20,
      ingredients = {{"athletic-science-pack", 1}},
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "personal-warp-pylon-equipment"},
    },
  }})
end

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
