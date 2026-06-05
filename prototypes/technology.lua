data:extend({
  {
    type = "technology",
    name = "mech-armor-mk2",
    icon = "__armor-adventure__/graphics/entity/armor-crafting-station/base/armor-crafting-station-icon.png",
    icon_size = 640,
    prerequisites = {"mech-armor", "promethium-science-pack"},
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
    hidden = true,
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
    prerequisites = {"mech-armor-mk2"},
    unit = {
      count       = 1000,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack",   1},
        {"chemical-science-pack",   1},
        {"promethium-science-pack", 1},
      },
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
    hidden = true,
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
    hidden = true,
    enabled = false,
    visible_when_disabled = false,
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
    hidden = true,
    enabled = false,
    visible_when_disabled = false,
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
  {
    type = "technology",
    name = "pocket-dimension-roboport",
    icon = "__base__/graphics/technology/construction-robotics.png",
    icon_size = 256,
    hidden = true,
    enabled = false,
    visible_when_disabled = false,
    prerequisites = {"pocket-dimension"},
    unit = {
      count = 10,
      ingredients = {{"logistic-science-pack", 1}},
      time = 60,
    },
  },
})

if mods["Moshine"] then
  data:extend({
    {
      type = "technology",
      name = "magnetic-data-agitation",
      icon = "__space-age__/graphics/icons/teslagun.png",
      icon_size = 64,
      prerequisites = {"forge-promethium-armor"},
      unit = {
        count = 30,
        ingredients = {
          {"datacell-raw-data",      1},
          {"datacell-ai-model-data", 1},
        },
        time = 400000,
      },
      effects = {
        {type = "unlock-recipe", recipe = "unstable-magnetized-data-core"},
        {type = "unlock-recipe", recipe = "vortex-data-card"},
      },
    },
    {
      type             = "technology",
      name             = "personal-tesla-turret",
      icon             = "__space-age__/graphics/icons/teslagun.png",
      icon_size        = 64,
      prerequisites    = {"magnetic-data-agitation"},
      research_trigger = {type = "craft-item", item = "vortex-data-card", count = 1},
      effects = {
        {type = "unlock-recipe", recipe = "personal-tesla-turret"},
      },
    },
  })
end

if mods["panglia_planet"] then
  data:extend({
    {
      type             = "technology",
      name             = "time-fracking",
      icon             = "__base__/graphics/technology/battery-mk2-equipment.png",
      icon_size        = 256,
      prerequisites    = {"forge-promethium-armor"},
      research_trigger = {type = "mine-entity", entity = "panglia-essence-node"},
      effects = {
        {type = "unlock-recipe", recipe = "panglia-seed-of-speedy-universe"},
        {type = "unlock-recipe", recipe = "panglia-speed-incubation"},
      },
    },
    {
      type = "technology",
      name = "personal-time-stopper",
      icon = "__base__/graphics/technology/battery-mk2-equipment.png",
      icon_size = 256,
      prerequisites = {"time-fracking"},
      unit = {
        count = 30,
        ingredients = {
          {"datacell-raw-data",       1},
          {"datacell-ai-model-data",  1},
          {"datacell-solved-equation", 1},
          {"datacell-dna-sequenced",  1},
        },
        time = 400000,
      },
      effects = {
        {type = "unlock-recipe", recipe = "personal-time-stopper"},
      },
    },
  })
end

data:extend({
  {
    type = "technology",
    name = "personal-fridge",
    hidden = true,
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
    type             = "technology",
    name             = "big-demolisher-hunt",
    icon             = "__base__/graphics/icons/heavy-armor.png",
    icon_size        = 64,
    prerequisites    = {"mech-armor-mk2"},
    research_trigger = {type = "mine-entity", entity = "big-demolisher-remains"},
    effects = {},
  },
  {
    type = "technology",
    name = "armor-adventure-vulcanus",
    icon = "__space-age__/graphics/icons/metallurgic-science-pack.png",
    icon_size = 64,
    prerequisites = {"big-demolisher-hunt"},
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
      {type = "unlock-recipe", recipe = "demolisher-heart-split"},
      {type = "unlock-recipe", recipe = "demolisher-heart-fragment-compress"},
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
      {type = "unlock-recipe", recipe = "neural-override-dart"},
    },
  },
  {
    type             = "technology",
    name             = "dissection-analysis-complete",
    icon             = "__space-age__/graphics/technology/agriculture.png",
    icon_size        = 256,
    prerequisites    = {"armor-adventure-gleba"},
    research_trigger = {type = "craft-item", item = "pentapod-tissue-samples"},
    effects = {
      {type = "unlock-recipe", recipe = "bio-interface"},
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
    effects = {},
  },
  {
    type             = "technology",
    name             = "aquilo-scanning-complete",
    icon             = "__base__/graphics/technology/radar.png",
    icon_size        = 256,
    prerequisites    = {"armor-adventure-aquilo"},
    research_trigger = {type = "mine-entity", entity = "aquilo-signal-source"},
    effects          = {
      {type = "unlock-recipe", recipe = "aquilo-elevator-shaft"},
    },
  },
  {
    type             = "technology",
    name             = "nauvis-defense-complete",
    icon             = "__base__/graphics/technology/military.png",
    icon_size        = 256,
    prerequisites    = {"armor-adventure-nauvis"},
    research_trigger = {type = "mine-entity", entity = "gigantoid-remains"},
    effects = {
      {type = "unlock-recipe", recipe = "nauvis-armor-piece"},
    },
  },
  {
    type     = "technology",
    name     = "armor-adventure-nauvis",
    icon     = "__base__/graphics/technology/military.png",
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
        {"promethium-science-pack",      1},
      },
      time = 60,
    },
    effects = {
      {type = "unlock-recipe", recipe = "pheromone-emitter"},
    },
  },
  {
    type             = "technology",
    name             = "cryo-core-acquired",
    icon             = "__space-age__/graphics/icons/cryogenic-science-pack.png",
    icon_size        = 64,
    prerequisites    = {"aquilo-scanning-complete"},
    research_trigger = {type = "mine-entity", entity = "vault-card-reader"},
    effects          = {
      {type = "unlock-recipe", recipe = "cryovault-access-card"},
      {type = "unlock-recipe", recipe = "thermodynamic-regulator"},
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
      "cryo-core-acquired",
      "nauvis-defense-complete",
      "dissection-analysis-complete",
    },
    unit = {
      count = 100000,
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
  data:extend({
    {
      type = "technology",
      name = "armor-adventure-rabbasca",
      icon = "__base__/graphics/technology/radar.png",
      icon_size = 256,
      prerequisites = {"forge-promethium-armor"},
      unit = {
        count = 5000,
        ingredients = {
          {"automation-science-pack",  1},
          {"logistic-science-pack",    1},
          {"chemical-science-pack",    1},
          {"military-science-pack",    1},
          {"production-science-pack",  1},
          {"utility-science-pack",     1},
          {"space-science-pack",       1},
          {"athletic-science-pack",    1},
          {"promethium-science-pack",  1},
        },
        time = 60,
      },
      effects = {
        {type = "unlock-recipe", recipe = "vault-excavation-key"},
        {type = "unlock-recipe", recipe = "vault-entry-extraction"},
      },
    },
    {
      type             = "technology",
      name             = "conquer-the-vault",
      icon             = "__base__/graphics/technology/military.png",
      icon_size        = 256,
      prerequisites    = {"armor-adventure-rabbasca"},
      research_trigger = {type = "mine-entity", entity = "ancient-rabbits-foote"},
      effects          = {},
    },
    {
      type = "technology",
      name = "personal-warp-pylon",
      icon = "__base__/graphics/technology/personal-roboport-equipment.png",
      icon_size = 256,
      prerequisites = {"conquer-the-vault", "interplanetary-construction-1"},
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
          {"athletic-science-pack",    1},
          {"promethium-science-pack",  1},
        },
        time = 60,
      },
      effects = {
        {type = "unlock-recipe", recipe = "personal-warp-pylon-equipment"},
      },
    },
  })
end

if mods["castra-prime"] then
  data:extend({
    {
      type = "technology",
      name = "castra-simulac-investigation",
      icon = "__armor-adventure__/graphics/icons/pcr-destroyer.png",
      icon_size = 64,
      prerequisites = {"forge-promethium-armor"},
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
        {type = "unlock-recipe", recipe = "simulac-data-tap"},
      },
    },
    {
      type             = "technology",
      name             = "operation-data-tap",
      icon             = "__base__/graphics/technology/uranium-ammo.png",
      icon_size        = 256,
      prerequisites    = {"castra-simulac-investigation"},
      research_trigger = {type = "mine-entity", entity = "simulac-core-remains"},
      effects = {
        {type = "unlock-recipe", recipe = "personal-combat-roboport"},
        {type = "unlock-recipe", recipe = "personal-combat-roboport-distractor"},
        {type = "unlock-recipe", recipe = "personal-combat-roboport-destroyer"},
      },
    },
  })
end

-- Exploration mode: cover all quest techs (except mech-armor-mk2) with ??? shadow
-- techs until their prerequisites are researched. The shadow has the same position
-- in the tree but an impossibly large cost so it can never be researched normally.
-- Runtime logic in control.lua swaps shadow → real when all prereqs are met.
if settings.startup["armor-adventure-exploration-mode"].value then
  local to_cover = {
    "packable-forge",
    "armor-adventure-nauvis",
    "nauvis-defense-complete",
    "big-demolisher-hunt",
    "armor-adventure-vulcanus",
    "armor-adventure-gleba",
    "armor-adventure-fulgora",
    "armor-adventure-aquilo",
    "aquilo-scanning-complete",
    "cryo-core-acquired",
    "forge-promethium-armor",
    "dissection-analysis-complete",
  }
  if mods["Moshine"]         then table.insert(to_cover, "magnetic-data-agitation") end
  if mods["Moshine"]         then table.insert(to_cover, "personal-tesla-turret") end
  if mods["panglia_planet"]  then table.insert(to_cover, "time-fracking") end
  if mods["panglia_planet"]  then table.insert(to_cover, "personal-time-stopper") end
  if mods["planet-rabbasca"] then
    table.insert(to_cover, "armor-adventure-rabbasca")
    table.insert(to_cover, "conquer-the-vault")
    table.insert(to_cover, "personal-warp-pylon")
  end
  if mods["castra-prime"]    then table.insert(to_cover, "castra-simulac-investigation") end
  if mods["castra-prime"]    then table.insert(to_cover, "operation-data-tap") end

  local shadows = {}
  for _, tech_name in ipairs(to_cover) do
    local real = data.raw.technology[tech_name]
    if real then
      real.enabled               = false
      real.visible_when_disabled = false
      shadows[#shadows + 1] = {
        type                  = "technology",
        name                  = tech_name .. "-covered",
        icon                  = real.icon,
        icon_size             = real.icon_size,
        localised_name        = {"", "???"},
        localised_description = {"", "Complete the prerequisites to reveal the details of this research."},
        prerequisites         = real.prerequisites,
        unit = {
          count       = 100000000,
          ingredients = {{"promethium-science-pack", 1}},
          time        = 60,
        },
        effects = {},
      }
    end
  end
  if #shadows > 0 then data:extend(shadows) end
end
