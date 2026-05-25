data:extend({
  {
    type = "technology",
    name = "mech-armor-mk2",
    icon = "__space-age__/graphics/technology/mech-armor.png",
    icon_size = 256,
    prerequisites = {"mech-armor"},
    unit = {
      count = 50000,
      ingredients = {
        {"automation-science-pack",      1},
        {"logistic-science-pack",        1},
        {"chemical-science-pack",        1},
        {"military-science-pack",        1},
        {"production-science-pack",      1},
        {"utility-science-pack",         1},
        {"space-science-pack",           1},
        {"metallurgic-science-pack",     1},
        {"agricultural-science-pack",    1},
        {"electromagnetic-science-pack", 1},
        {"cryogenic-science-pack",       1},
        {"promethium-science-pack",      1},
      },
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "armor-forging-station"},
    },
  },
  {
    type = "technology",
    name = "mech-armor-mk2-running-speed",
    icon = "__base__/graphics/technology/exoskeleton-equipment.png",
    icon_size = 256,
    prerequisites = {"forge-promethium-armor"},
    unit = {
      count = 10,
      ingredients = {{"electromagnetic-science-pack", 1}},
      time = 60,
    },
    effects = {
      {type = "character-running-speed", modifier = 1.0},
    },
  },
  {
    type          = "technology",
    name          = "packable-forge",
    icon          = "__armor-adventure__/graphics/entity/armor-crafting-station/base/armor-crafting-station-icon.png",
    icon_size     = 640,
    prerequisites = {"forge-promethium-armor"},
    unit = {
      count       = 10,
      ingredients = {{"logistic-science-pack", 1}},
      time        = 60,
    },
    effects = {},
  },
})

data:extend({
  {
    type = "technology",
    name = "personal-robot-stash",
    hidden = true,
    icon = "__base__/graphics/technology/personal-roboport-equipment.png",
    icon_size = 256,
    prerequisites = {"forge-promethium-armor"},
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
    prerequisites = {"forge-promethium-armor"},
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
    prerequisites = {"forge-promethium-armor"},
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
    prerequisites = {"forge-promethium-armor"},
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
    prerequisites = {"forge-promethium-armor", "tesla-weapons"},
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
    prerequisites = {"forge-promethium-armor"},
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
    prerequisites = {"forge-promethium-armor"},
    unit = {
      count = 10,
      ingredients = {{"agricultural-science-pack", 1}},
      time = 60,
    },
  },
})

data:extend({
  {
    type = "technology",
    name = "armor-adventure-vulcanus",
    icon = "__space-age__/graphics/icons/metallurgic-science-pack.png",
    icon_size = 64,
    prerequisites = {"mech-armor-mk2"},
    unit = {
      count = 10000,
      ingredients = {
        {"automation-science-pack",      1},
        {"logistic-science-pack",        1},
        {"chemical-science-pack",        1},
        {"military-science-pack",        1},
        {"production-science-pack",      1},
        {"utility-science-pack",         1},
        {"space-science-pack",           1},
        {"metallurgic-science-pack",     1},
        {"promethium-science-pack",      1},
      },
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "promethium-armor-chassis"},
    },
  },
  {
    type = "technology",
    name = "armor-adventure-gleba",
    icon = "__space-age__/graphics/technology/agriculture.png",
    icon_size = 256,
    prerequisites = {"mech-armor-mk2"},
    unit = {
      count = 10000,
      ingredients = {
        {"automation-science-pack",      1},
        {"logistic-science-pack",        1},
        {"chemical-science-pack",        1},
        {"military-science-pack",        1},
        {"production-science-pack",      1},
        {"utility-science-pack",         1},
        {"space-science-pack",           1},
        {"agricultural-science-pack",    1},
        {"promethium-science-pack",      1},
      },
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "harvester"},
      {type = "unlock-recipe", recipe = "mind-control-rocket"},
    },
  },
  {
    type = "technology",
    name = "armor-adventure-fulgora",
    icon = "__space-age__/graphics/icons/electromagnetic-science-pack.png",
    icon_size = 64,
    prerequisites = {"mech-armor-mk2"},
    unit = {
      count = 10000,
      ingredients = {
        {"automation-science-pack",      1},
        {"logistic-science-pack",        1},
        {"chemical-science-pack",        1},
        {"military-science-pack",        1},
        {"production-science-pack",      1},
        {"utility-science-pack",         1},
        {"space-science-pack",           1},
        {"electromagnetic-science-pack", 1},
        {"promethium-science-pack",      1},
      },
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "massive-lightning-collector"},
      {type = "unlock-recipe", recipe = "promethium-armor-electronics"},
    },
  },
  {
    type = "technology",
    name = "armor-adventure-aquilo",
    icon = "__space-age__/graphics/icons/cryogenic-science-pack.png",
    icon_size = 64,
    prerequisites = {"mech-armor-mk2"},
    unit = {
      count = 10000,
      ingredients = {
        {"automation-science-pack",      1},
        {"logistic-science-pack",        1},
        {"chemical-science-pack",        1},
        {"military-science-pack",        1},
        {"production-science-pack",      1},
        {"utility-science-pack",         1},
        {"space-science-pack",           1},
        {"cryogenic-science-pack",       1},
        {"promethium-science-pack",      1},
      },
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "aquilo-prom-suit-component"},
    },
  },
  {
    type = "technology",
    name = "forge-promethium-armor",
    icon = "__armor-adventure__/graphics/entity/armor-crafting-station/base/armor-crafting-station-icon.png",
    icon_size = 640,
    prerequisites = {
      "armor-adventure-vulcanus",
      "armor-adventure-gleba",
      "armor-adventure-fulgora",
      "armor-adventure-aquilo",
    },
    unit = {
      count = 10000,
      ingredients = {
        {"automation-science-pack",      1},
        {"logistic-science-pack",        1},
        {"chemical-science-pack",        1},
        {"military-science-pack",        1},
        {"production-science-pack",      1},
        {"utility-science-pack",         1},
        {"space-science-pack",           1},
        {"metallurgic-science-pack",     1},
        {"agricultural-science-pack",    1},
        {"electromagnetic-science-pack", 1},
        {"cryogenic-science-pack",       1},
        {"promethium-science-pack",      1},
      },
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "mech-armor-mk2"},
    },
  },
})

if mods["planet-rabbasca"] then
  data:extend({{
    type = "technology",
    name = "personal-warp-pylon",
    icon = "__base__/graphics/technology/personal-roboport-equipment.png",
    icon_size = 256,
    prerequisites = {"forge-promethium-armor", "interplanetary-construction-1"},
    unit = {
      count = 10000,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack",   1},
        {"chemical-science-pack",   1},
        {"military-science-pack",   1},
        {"production-science-pack", 1},
        {"utility-science-pack",    1},
        {"space-science-pack",      1},
        {"athletic-science-pack",   1},
        {"promethium-science-pack", 1},
      },
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
      -- Shadow tech: visible "???" placeholder in the tree occupying the same slot as PCR.
      -- Script (sync_pcr_visibility) manages which is enabled: shadow shown before core-hunt,
      -- real PCR shown after. The unit cost is astronomically high so it can never be
      -- researched normally.
      type          = "technology",
      name          = "simulac-pcr-unknown",
      icon          = "__base__/graphics/technology/military.png",
      icon_size     = 256,
      localised_name        = {"", "???"},
      localised_description = {"", "Something awaits on Castra..."},
      prerequisites = {"forge-promethium-armor", "core-hunt"},
      unit = {
        count       = 100000000,
        ingredients = {{"promethium-science-pack", 1}},
        time        = 60,
      },
      effects = {},
    },
    {
      type             = "technology",
      name             = "core-hunt",
      icon             = "__base__/graphics/technology/uranium-ammo.png",
      icon_size        = 256,
      prerequisites    = {"forge-promethium-armor"},
      research_trigger = {type = "mine-entity", entity = "simulac-core-remains"},
      effects = {
        {type = "unlock-recipe", recipe = "simulac-core"},
      },
    },
    {
      type = "technology",
      name = "personal-combat-roboport",
      icon = "__base__/graphics/technology/personal-roboport-equipment.png",
      icon_size = 256,
      enabled               = false,
      visible_when_disabled = false,
      prerequisites = {"forge-promethium-armor", "core-hunt"},
      unit = {
        count = 10000,
        ingredients = {
          {"automation-science-pack",  1},
          {"logistic-science-pack",    1},
          {"chemical-science-pack",    1},
          {"military-science-pack",    1},
          {"production-science-pack",  1},
          {"utility-science-pack",     1},
          {"space-science-pack",       1},
          {"battlefield-science-pack", 1},
          {"promethium-science-pack",  1},
        },
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
