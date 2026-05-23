data:extend({
  {
    type = "recipe",
    name = "mech-armor-mk2",
    enabled = false,
    energy_required = 10,
    ingredients = {
      {type = "item", name = "mech-armor",  amount = 1},
      {type = "item", name = "steel-plate", amount = 5},
    },
    results = {{type = "item", name = "mech-armor-mk2", amount = 1}},
  },
  {
    type = "recipe",
    name = "regenerative-plating",
    enabled = false,
    energy_required = 10,
    ingredients = {
      {type = "item", name = "energy-shield-equipment", amount = 1},
      {type = "item", name = "steel-plate", amount = 10},
    },
    results = {{type = "item", name = "regenerative-plating", amount = 1}},
  },
  {
    type = "recipe",
    name = "personal-combat-roboport",
    enabled = false,
    energy_required = 10,
    ingredients = {
      {type = "item", name = "personal-roboport-equipment", amount = 1},
      {type = "item", name = "steel-plate",                 amount = 10},
      {type = "item", name = "defender-capsule",            amount = 100},
    },
    results = {{type = "item", name = "personal-combat-roboport", amount = 1}},
  },
  {
    type = "recipe",
    name = "personal-combat-roboport-distractor",
    enabled = false,
    energy_required = 10,
    ingredients = {
      {type = "item", name = "personal-roboport-equipment", amount = 1},
      {type = "item", name = "steel-plate",                 amount = 10},
      {type = "item", name = "distractor-capsule",          amount = 100},
    },
    results = {{type = "item", name = "personal-combat-roboport-distractor", amount = 1}},
  },
  {
    type = "recipe",
    name = "personal-combat-roboport-destroyer",
    enabled = false,
    energy_required = 10,
    ingredients = {
      {type = "item", name = "personal-roboport-equipment", amount = 1},
      {type = "item", name = "steel-plate",                 amount = 10},
      {type = "item", name = "destroyer-capsule",           amount = 100},
    },
    results = {{type = "item", name = "personal-combat-roboport-destroyer", amount = 1}},
  },
})
