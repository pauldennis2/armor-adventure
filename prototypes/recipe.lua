data:extend({
  {type = "recipe-category", name = "harvesting"},
  {type = "recipe-category", name = "armor-forging"},
  {type = "recipe-category", name = "aquilo-elevator-construction"},
  {type = "recipe-category", name = "aquilo-elevator-dummy"},
})

data:extend({
  {
    type            = "recipe",
    name            = "mech-armor-mk2",
    enabled         = false,
    energy_required = 10,
    category        = "armor-forging",
    ingredients = {
      {type = "item", name = "mech-armor",                   amount = 1},
      {type = "item", name = "steel-plate",                  amount = 5},
      {type = "item", name = "bio-interface",                amount = 1},
      {type = "item", name = "thermodynamic-regulator",       amount = 1},
      {type = "item", name = "promethium-armor-chassis",     amount = 1},
      {type = "item", name = "promethium-armor-electronics", amount = 1},
      {type = "item", name = "nauvis-armor-piece",           amount = 1},
    },
    results = {{type = "item", name = "mech-armor-mk2", amount = 1}},
  },
  {
    type            = "recipe",
    name            = "promethium-armor-chassis",
    enabled         = false,
    energy_required = 30,
    category        = "armor-forging",
    ingredients = {
      {type = "item", name = "demolisher-heart-fragment-large", amount = 3},
      {type = "item", name = "steel-plate",                     amount = 200},
      {type = "item", name = "low-density-structure",           amount = 50},
      {type = "item", name = "tungsten-plate",                  amount = 200},
      {type = "item", name = "tungsten-carbide",                amount = 100},
      {type = "item", name = "promethium-asteroid-chunk",       amount = 100},
    },
    results = {{type = "item", name = "promethium-armor-chassis", amount = 1}},
  },
  -- Split one demolisher heart into a random yield of large and small fragments.
  -- Allows all modules so quality modules can improve the fragment output.
  {
    type               = "recipe",
    name               = "demolisher-heart-split",
    icon               = "__base__/graphics/icons/heavy-armor.png",
    icon_size          = 64,
    enabled            = false,
    energy_required    = 30,
    allow_productivity = true,
    ingredients = {
      {type = "item", name = "demolisher-heart", amount = 1},
    },
    results = {
      {type = "item", name = "demolisher-heart-fragment-large", amount_min = 1, amount_max = 3},
      {type = "item", name = "demolisher-heart-fragment-small", amount_min = 2, amount_max = 6},
    },
  },
  -- Compress 5 small fragments into 1 large fragment.
  {
    type               = "recipe",
    name               = "demolisher-heart-fragment-compress",
    enabled            = false,
    energy_required    = 10,
    allow_productivity = true,
    ingredients = {
      {type = "item", name = "demolisher-heart-fragment-small", amount = 5},
    },
    results = {{type = "item", name = "demolisher-heart-fragment-large", amount = 1}},
  },
  -- Recycling: large fragment → itself at 25%.
  {
    type                = "recipe",
    name                = "demolisher-heart-fragment-large-recycling",
    category            = "recycling",
    enabled             = true,
    hidden              = true,
    energy_required     = 0.1,
    allow_decomposition = false,
    ingredients         = {{type = "item", name = "demolisher-heart-fragment-large", amount = 1}},
    results             = {{type = "item", name = "demolisher-heart-fragment-large", amount = 1, probability = 0.25}},
  },
  -- Recycling: small fragment → itself at 25%.
  {
    type                = "recipe",
    name                = "demolisher-heart-fragment-small-recycling",
    category            = "recycling",
    enabled             = true,
    hidden              = true,
    energy_required     = 0.1,
    allow_decomposition = false,
    ingredients         = {{type = "item", name = "demolisher-heart-fragment-small", amount = 1}},
    results             = {{type = "item", name = "demolisher-heart-fragment-small", amount = 1, probability = 0.25}},
  },
  {
    type            = "recipe",
    name            = "promethium-armor-electronics",
    enabled         = false,
    energy_required = 60,
    category        = "armor-forging",
    ingredients = {
      {type = "item", name = "charged-lightning-gem",  amount = 1},
      {type = "item", name = "superconductor",         amount = 100},
      {type = "item", name = "speed-module-3",         amount = 3},
      {type = "item", name = "efficiency-module-3",    amount = 3},
      {type = "item", name = "productivity-module-3",  amount = 3},
      {type = "item", name = "quality-module-3",       amount = 3},
    },
    results = {{type = "item", name = "promethium-armor-electronics", amount = 1}},
  },
  {
    type            = "recipe",
    name            = "regenerative-plating",
    enabled         = false,
    energy_required = 10,
    category        = "armor-forging",
    ingredients = {
      {type = "item", name = "energy-shield-equipment", amount = 1},
      {type = "item", name = "steel-plate", amount = 10},
    },
    results = {{type = "item", name = "regenerative-plating", amount = 1}},
  },
  {
    type            = "recipe",
    name            = "personal-robot-stash",
    hidden          = true,
    enabled         = false,
    energy_required = 10,
    category        = "armor-forging",
    ingredients = {
      {type = "item", name = "construction-robot", amount = 5},
      {type = "item", name = "steel-chest",        amount = 1},
    },
    results = {{type = "item", name = "personal-robot-stash", amount = 1}},
  },
  {
    type            = "recipe",
    name            = "personal-beacon-equipment",
    enabled         = false,
    energy_required = 10,
    category        = "armor-forging",
    ingredients = {
      {type = "item", name = "beacon",      amount = 1},
      {type = "item", name = "steel-plate", amount = 10},
    },
    results = {{type = "item", name = "personal-beacon-equipment", amount = 1}},
  },
  {
    type            = "recipe",
    name            = "pocket-dimension-generator",
    enabled         = false,
    energy_required = 10,
    category        = "armor-forging",
    ingredients = {
      {type = "item", name = "fusion-reactor-equipment", amount = 1},
      {type = "item", name = "steel-plate",              amount = 5},
    },
    results = {{type = "item", name = "pocket-dimension-generator", amount = 1}},
  },
  {
    type            = "recipe",
    name            = "armor-forging-station",
    enabled         = false,
    energy_required = 10,
    ingredients = {
      {type = "item", name = "chemical-plant",      amount = 1},
      {type = "item", name = "steel-plate",         amount = 100},
      {type = "item", name = "processing-unit",     amount = 200},
      {type = "item", name = "advanced-circuit",    amount = 100},
      {type = "item", name = "tungsten-carbide",    amount = 100},
      {type = "item", name = "low-density-structure", amount = 50},
    },
    results = {{type = "item", name = "armor-forging-station", amount = 1}},
  },
  {
    type            = "recipe",
    name            = "bio-interface",
    enabled         = false,
    energy_required = 10,
    category        = "armor-forging",
    ingredients = {
      {type = "item", name = "pentapod-tissue-samples", amount = 20},
      {type = "item", name = "electronic-circuit", amount = 50},
      {type = "item", name = "advanced-circuit",   amount = 50},
      {type = "item", name = "processing-unit",    amount = 20},
    },
    results = {{type = "item", name = "bio-interface", amount = 1}},
  },
  {
    type            = "recipe",
    name            = "pentapod-tissue-samples-from-biomass",
    hidden          = true,
    enabled         = true,
    energy_required = 1,
    category        = "harvesting",
    ingredients     = {{type = "item", name = "enemy-biomass",          amount = 1}},
    results         = {{type = "item", name = "pentapod-tissue-samples", amount = 1}},
  },
  {
    type            = "recipe",
    name            = "quantum-coil",
    hidden          = true,
    enabled         = false,
    energy_required = 5,
    category        = "armor-forging",
    ingredients = {
      {type = "item", name = "iron-plate", amount = 1},
    },
    results = {{type = "item", name = "quantum-coil", amount = 1}},
  },

  {
    type            = "recipe",
    name            = "harvester",
    enabled         = false,
    energy_required = 10,
    ingredients = {
      {type = "item", name = "fast-inserter",       amount = 5},
      {type = "item", name = "biolab",              amount = 2},
      {type = "item", name = "assembling-machine-3", amount = 1},
    },
    results = {{type = "item", name = "harvester", amount = 1}},
  },
  {
    type            = "recipe",
    name            = "neural-override-dart",
    enabled         = false,
    energy_required = 5,
    ingredients = {
      {type = "item", name = "steel-plate",  amount = 2},
      {type = "item", name = "explosives",   amount = 2},
      {type = "item", name = "rocket",       amount = 1},
      {type = "item", name = "bioflux",      amount = 10},
      {type = "item", name = "yumako",       amount = 2},
    },
    results = {{type = "item", name = "neural-override-dart", amount = 1}},
  },
  {
    type             = "recipe",
    name             = "massive-lightning-collector",
    enabled          = false,
    energy_required  = 10,
    ingredients = {
      {type = "item", name = "lightning-collector",   amount = 10},
      {type = "item", name = "steel-plate",           amount = 100},
      {type = "item", name = "processing-unit",       amount = 50},
      {type = "item", name = "low-density-structure", amount = 20},
      {type = "item", name = "speed-module-3",        amount = 2},
      {type = "item", name = "accumulator",           amount = 50},
    },
    results = {{type = "item", name = "massive-lightning-collector", amount = 1}},
  },
})

if mods["Moshine"] then
  data:extend({{
    type            = "recipe",
    name            = "personal-tesla-turret",
    enabled         = false,
    energy_required = 10,
    category        = "armor-forging",
    ingredients = {
      {type = "item", name = "personal-laser-defense-equipment", amount =  1},
      {type = "item", name = "tesla-turret",                     amount =  1},
      {type = "item", name = "vortex-data-card",                 amount = 10},
      {type = "item", name = "rail-minimal",                      amount = 10},
      {type = "item", name = "processing-unit",                  amount = 50},
    },
    results = {{type = "item", name = "personal-tesla-turret", amount = 1}},
  }})
end

if mods["panglia_planet"] and mods["Moshine"] then
  data:extend({{
    type               = "recipe",
    name               = "panglia-essence-of-speed",
    category           = "data-processing",
    enabled            = false,
    energy_required    = 1000,
    allow_productivity = false,
    auto_recycle       = false,
    ingredients = {
      {type = "item", name = "panglia-essence-of-speed", amount = 1},
    },
    results = {
      {type = "item", name = "panglia-refined-speed", amount = 1},
    },
  }})
end

if mods["panglia_planet"] then
  data:extend({{
    type            = "recipe",
    name            = "personal-time-stopper",
    enabled         = false,
    energy_required = 10,
    category        = "armor-forging",
    ingredients = {
      {type = "item", name = "battery-mk2-equipment", amount = 2},
      {type = "item", name = "panglia-refined-speed", amount = 3},
      {type = "item", name = "efficiency-module-3",   amount = 2},
      {type = "item", name = "speed-module-3",        amount = 4},
    },
    results = {{type = "item", name = "personal-time-stopper", amount = 1}},
  }})
end

if mods["Moshine"] then
  data:extend({{
    type            = "recipe",
    name            = "unstable-magnetized-data-core",
    enabled         = true,  -- TODO: lock behind armor-adventure-moshine tech
    energy_required = 120,
    category        = "metallurgy",
    ingredients = {
      {type = "fluid", name = "raw-data",    amount = 5000},
      {type = "fluid", name = "molten-iron", amount = 500},
      {type = "item",  name = "magnet",      amount = 50},
    },
    results = {{type = "item", name = "unstable-magnetized-data-core", amount = 1}},
  }})

  -- Motion-data recipes for the data-processor.
  -- The scan tokens are the "scripted ingredient" — quests/moshine.lua inserts
  -- them when a qualifying train (carrying magnets, rotating in the right direction)
  -- is detected within TOKEN_RADIUS tiles of the machine.
  data:extend({
    {
      type                      = "recipe",
      name                      = "deosil-motion-data",
      category                  = "data-processing",
      hide_from_player_crafting = true,
      enabled                   = true,
      energy_required           = 1,
      allow_productivity        = false,
      auto_recycle              = false,
      reset_freshness_on_craft  = true,
      ingredients = {
        {type = "fluid", name = "raw-data",          amount = 100},
        {type = "item",  name = "deosil-scan-token", amount = 1},
      },
      results = {{type = "item", name = "deosil-motion-data", amount = 1}},
    },
    {
      type                      = "recipe",
      name                      = "widdershins-motion-data",
      category                  = "data-processing",
      hide_from_player_crafting = true,
      enabled                   = true,
      energy_required           = 1,
      allow_productivity        = false,
      auto_recycle              = false,
      reset_freshness_on_craft  = true,
      ingredients = {
        {type = "fluid", name = "raw-data",               amount = 100},
        {type = "item",  name = "widdershins-scan-token", amount = 1},
      },
      results = {{type = "item", name = "widdershins-motion-data", amount = 1}},
    },
    -- Combines simultaneous deosil + widdershins motion data onto a blank datacell.
    -- Requires both data types to arrive within their 1-second spoil window,
    -- enforcing the inner/outer ring setup.
    {
      type                      = "recipe",
      name                      = "vortex-data-card",
      category                  = "data-processing",
      hide_from_player_crafting = true,
      enabled                   = true,
      energy_required           = 1,
      allow_productivity        = false,
      auto_recycle              = false,
      ingredients = {
        {type = "item", name = "deosil-motion-data",    amount = 5},
        {type = "item", name = "widdershins-motion-data", amount = 5},
        {type = "item", name = "datacell-empty",          amount = 1},
      },
      results = {{type = "item", name = "vortex-data-card", amount = 1}},
    },
  })
end

if mods["castra-prime"] then
  data:extend({
    {
      type            = "recipe",
      name            = "personal-combat-roboport",
      enabled         = false,
      energy_required = 10,
      category        = "armor-forging",
      ingredients = {
        {type = "item", name = "defender-capsule",               amount = 200},
        {type = "item", name = "combat-roboport",                amount = 1},
        {type = "item", name = "personal-roboport-mk2-equipment", amount = 1},
        {type = "item", name = "speed-module-3",                 amount = 2},
        {type = "item", name = "efficiency-module-3",            amount = 2},
        {type = "item", name = "gun-turret",                     amount = 5},
        {type = "item", name = "simulac-core",                   amount = 1},
      },
      results = {{type = "item", name = "personal-combat-roboport", amount = 1}},
    },
    {
      type            = "recipe",
      name            = "personal-combat-roboport-distractor",
      enabled         = false,
      energy_required = 10,
      category        = "armor-forging",
      ingredients = {
        {type = "item", name = "distractor-capsule",             amount = 200},
        {type = "item", name = "combat-roboport",                amount = 1},
        {type = "item", name = "personal-roboport-mk2-equipment", amount = 1},
        {type = "item", name = "speed-module-3",                 amount = 2},
        {type = "item", name = "efficiency-module-3",            amount = 2},
        {type = "item", name = "laser-turret",                   amount = 5},
        {type = "item", name = "simulac-core",                   amount = 1},
      },
      results = {{type = "item", name = "personal-combat-roboport-distractor", amount = 1}},
    },
    {
      type            = "recipe",
      name            = "personal-combat-roboport-destroyer",
      enabled         = false,
      energy_required = 10,
      category        = "armor-forging",
      ingredients = {
        {type = "item", name = "destroyer-capsule",              amount = 200},
        {type = "item", name = "combat-roboport",                amount = 1},
        {type = "item", name = "personal-roboport-mk2-equipment", amount = 1},
        {type = "item", name = "speed-module-3",                 amount = 2},
        {type = "item", name = "efficiency-module-3",            amount = 2},
        {type = "item", name = "tesla-turret",                   amount = 2},
        {type = "item", name = "simulac-core",                   amount = 1},
      },
      results = {{type = "item", name = "personal-combat-roboport-destroyer", amount = 1}},
    },
  })

  data:extend({{
    type            = "recipe",
    name            = "simulac-core",
    enabled         = false,
    energy_required = 30,
    category        = "armor-forging",
    ingredients = {
      {type = "item", name = "unrefined-simulac-core", amount = 1},
      {type = "item", name = "nickel-plate",           amount = 100},
      {type = "item", name = "gunpowder",              amount = 50},
      {type = "item", name = "uranium-235",            amount = 10},
    },
    results = {{type = "item", name = "simulac-core", amount = 1}},
  }})
end

if mods["planet-rabbasca"] then
  data:extend({
    {
      type            = "recipe",
      name            = "personal-warp-pylon-equipment",
      enabled         = false,
      energy_required = 10,
      category        = "armor-forging",
      ingredients = {
        {type = "item", name = "rabbasca-warp-pylon",  amount = 2},
        {type = "item", name = "speed-module-3",       amount = 2},
        {type = "item", name = "efficiency-module-3",  amount = 2},
      },
      results = {{type = "item", name = "personal-warp-pylon-equipment", amount = 1}},
    },
    -- Crafted at the Armor Forging Station after researching armor-adventure-rabbasca.
    -- Consumed by the vault-entry-extraction recipe in the vault-crafter.
    {
      type            = "recipe",
      name            = "vault-excavation-key",
      enabled         = false,
      energy_required = 30,
      category        = "armor-forging",
      ingredients = {
        {type = "item", name = "vault-security-key",    amount = 5},
        {type = "item", name = "processing-unit",       amount = 10},
        {type = "item", name = "low-density-structure", amount = 20},
      },
      results = {{type = "item", name = "vault-excavation-key", amount = 1}},
    },
    -- Run in the vault-crafter (rabbasca-vault-extraction category) while a hack is active.
    -- Consumes the vault-excavation-key and produces a vault-entry-pass the player places to enter.
    {
      type            = "recipe",
      name            = "vault-entry-extraction",
      category        = "rabbasca-vault-extraction",
      enabled         = false,
      energy_required = 60,
      ingredients = {
        {type = "item", name = "vault-excavation-key", amount = 1},
      },
      results = {{type = "item", name = "vault-entry-pass", amount = 1}},
    },
  })
end

data:extend({{
  type            = "recipe",
  name            = "pheromone-emitter",
  enabled         = false,
  energy_required = 5,
  ingredients = {
    {type = "item", name = "beacon",                  amount = 1},
    {type = "item", name = "steel-plate",             amount = 20},
    {type = "item", name = "electronic-circuit",      amount = 20},
    {type = "item", name = "captive-biter-spawner",   amount = 4},
  },
  results = {{type = "item", name = "pheromone-emitter", amount = 1}},
}})

-- Ablative Chitocarbon Shell: processed from Gigantic Chitinous Shell dropped by big worms.
data:extend({{
  type               = "recipe",
  name               = "nauvis-armor-piece",
  enabled            = false,
  energy_required    = 30,
  category           = "armor-forging",
  allow_productivity = true,
  ingredients = {
    {type = "item", name = "gigantic-chitinous-shell", amount = 1},
    {type = "item", name = "carbon",                   amount = 100},
  },
  results = {{type = "item", name = "nauvis-armor-piece", amount = 1}},
}})

-- Cryovault Access Card: unlocked by cryo-core-acquired tech. Craftable in AFS, assembler 2/3, EM plant.
-- Warm fluoro is a byproduct and must not be boosted by productivity modules.
data:extend({{
  type               = "recipe",
  name               = "cryovault-access-card",
  enabled            = false,
  energy_required    = 300,
  category           = "advanced-crafting",
  allow_productivity = true,
  icon               = "__base__/graphics/icons/electronic-circuit.png",
  icon_size          = 64,
  ingredients = {
    {type = "item",  name = "electronic-circuit", amount = 20},
    {type = "item",  name = "advanced-circuit",   amount = 20},
    {type = "item",  name = "processing-unit",    amount = 30},
    {type = "fluid", name = "fluoroketone-cold",  amount = 1000},
  },
  results = {
    {type = "item",  name = "cryovault-access-card", amount = 1},
    {type = "fluid", name = "fluoroketone-hot",      amount = 500, ignore_productivity = true},
  },
}})

-- Thermodynamic Regulator: Aquilo field component. Cryo Core (from vault card reader) + lithium plates.
data:extend({{
  type               = "recipe",
  name               = "thermodynamic-regulator",
  enabled            = false,
  energy_required    = 30,
  category           = "armor-forging",
  allow_productivity = true,
  ingredients = {
    {type = "item", name = "cryo-core",     amount = 1},
    {type = "item", name = "lithium-plate", amount = 10},
  },
  results = {{type = "item", name = "thermodynamic-regulator", amount = 1}},
}})

-- Aquilo elevator shaft construction machine (item recipe, unlocked by aquilo-scanning-complete).
data:extend({{
  type            = "recipe",
  name            = "aquilo-elevator-shaft",
  enabled         = false,
  energy_required = 10,
  ingredients = {
    {type = "item", name = "concrete",          amount = 100},
    {type = "item", name = "steel-plate",       amount = 100},
    {type = "item", name = "tungsten-plate",    amount = 50},
    {type = "item", name = "electronic-circuit", amount = 50},
    {type = "item", name = "big-mining-drill",  amount = 5},
  },
  results = {{type = "item", name = "aquilo-elevator-shaft", amount = 1}},
}})

-- One excavation cycle for the elevator shaft machine.
-- ignored_by_productivity on both outputs: productivity modules speed up cycle
-- count but never produce extra stone or iron ore per cycle.
data:extend({{
  type            = "recipe",
  name            = "aquilo-elevator-dig",
  icon            = "__base__/graphics/icons/concrete.png",
  icon_size       = 64,
  category        = "aquilo-elevator-construction",
  enabled         = true,
  energy_required = 60,
  ingredients = {
    {type = "item", name = "concrete",    amount = 50},
    {type = "item", name = "steel-plate", amount = 25},
  },
  results = {
    {type = "item", name = "stone",    amount = 100, ignored_by_productivity = 100},
    {type = "item", name = "iron-ore", amount = 5,   ignored_by_productivity = 5},
  },
  allow_productivity = true,
}})

-- Prevent Castra Prime's Forge from re-categorizing our recipes.
-- Must be set here (data.lua stage) — Castra reads this flag in data-updates.lua,
-- before data-final-fixes.lua runs, so setting it there is always too late.
do
  local our_recipes = {
    "mech-armor-mk2", "promethium-armor-chassis", "promethium-armor-electronics",
    "demolisher-heart-split", "demolisher-heart-fragment-compress",
    "regenerative-plating", "personal-robot-stash", "personal-beacon-equipment",
    "pocket-dimension-generator", "armor-forging-station", "bio-interface",
    "pentapod-tissue-samples-from-biomass", "quantum-coil",
    "harvester", "neural-override-dart", "massive-lightning-collector",
    "pheromone-emitter", "nauvis-armor-piece", "cryovault-access-card",
    "thermodynamic-regulator", "aquilo-elevator-shaft", "aquilo-elevator-dig",
    "personal-tesla-turret", "unstable-magnetized-data-core",
    "deosil-motion-data", "widdershins-motion-data", "vortex-data-card",
    "personal-time-stopper", "panglia-essence-of-speed",
    "personal-combat-roboport", "personal-combat-roboport-distractor",
    "personal-combat-roboport-destroyer", "simulac-core",
    "personal-warp-pylon-equipment",
    "vault-excavation-key",
    "vault-entry-extraction",
  }
  for _, name in ipairs(our_recipes) do
    local r = data.raw["recipe"][name]
    if r then r.castra_prime_ignore = true end
  end
end
