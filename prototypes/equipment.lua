local MK2_CATEGORY = {"armor-adventure-mk2"}

local regen_plating = table.deepcopy(data.raw["energy-shield-equipment"]["energy-shield-equipment"])
regen_plating.name        = "regenerative-plating"
regen_plating.take_result = "regenerative-plating"
regen_plating.categories  = MK2_CATEGORY
data:extend({ regen_plating })

local combat_roboport = table.deepcopy(data.raw["roboport-equipment"]["personal-roboport-equipment"])
combat_roboport.name                = "personal-combat-roboport"
combat_roboport.take_result         = "personal-combat-roboport"
combat_roboport.robot_limit         = 0
combat_roboport.construction_radius = 0
combat_roboport.categories          = MK2_CATEGORY

local combat_roboport_distractor = table.deepcopy(data.raw["roboport-equipment"]["personal-roboport-equipment"])
combat_roboport_distractor.name                = "personal-combat-roboport-distractor"
combat_roboport_distractor.take_result         = "personal-combat-roboport-distractor"
combat_roboport_distractor.robot_limit         = 0
combat_roboport_distractor.construction_radius = 0
combat_roboport_distractor.categories          = MK2_CATEGORY

local combat_roboport_destroyer = table.deepcopy(data.raw["roboport-equipment"]["personal-roboport-equipment"])
combat_roboport_destroyer.name                = "personal-combat-roboport-destroyer"
combat_roboport_destroyer.take_result         = "personal-combat-roboport-destroyer"
combat_roboport_destroyer.robot_limit         = 0
combat_roboport_destroyer.construction_radius = 0
combat_roboport_destroyer.categories          = MK2_CATEGORY

local robot_stash = table.deepcopy(data.raw["roboport-equipment"]["personal-roboport-equipment"])
robot_stash.name                = "personal-robot-stash"
robot_stash.take_result         = "personal-robot-stash"
robot_stash.robot_limit         = 5
robot_stash.construction_radius = 20
robot_stash.categories          = MK2_CATEGORY

local personal_beacon_eq = table.deepcopy(data.raw["roboport-equipment"]["personal-roboport-equipment"])
personal_beacon_eq.name                = "personal-beacon-equipment"
personal_beacon_eq.take_result         = "personal-beacon-equipment"
personal_beacon_eq.robot_limit         = 0
personal_beacon_eq.construction_radius = 0
personal_beacon_eq.charging_energy     = "0W"
personal_beacon_eq.categories          = MK2_CATEGORY

data:extend({ combat_roboport, combat_roboport_distractor, combat_roboport_destroyer, robot_stash, personal_beacon_eq })

local pdg = table.deepcopy(data.raw["generator-equipment"]["fusion-reactor-equipment"])
pdg.name        = "pocket-dimension-generator"
pdg.take_result = "pocket-dimension-generator"
pdg.categories  = MK2_CATEGORY
-- Power is set to the correct value in data-final-fixes.lua.
data:extend({pdg})

-- Start beam: fires at the primary target, applies damage + push-back + stickers.
local ptb = table.deepcopy(data.raw["beam"]["chain-tesla-turret-beam-start"])
ptb.name = "personal-tesla-turret-beam"
ptb.action.action_delivery.target_effects[1].damage.amount = 50
data:extend({ptb})

-- Bounce beam: same effects, used for each chain jump.
local ptbb = table.deepcopy(data.raw["beam"]["chain-tesla-turret-beam-bounce"])
ptbb.name = "personal-tesla-turret-beam-bounce"
ptbb.action.action_delivery.target_effects[1].damage.amount = 2
data:extend({ptbb})

-- Chain trigger: 5 jumps, 12-tile range per jump, references our bounce beam.
local ptc = table.deepcopy(data.raw["chain-active-trigger"]["chain-tesla-turret-chain"])
ptc.name      = "personal-tesla-turret-chain"
ptc.max_jumps = 5
ptc.action.action_delivery.beam = "personal-tesla-turret-beam-bounce"
data:extend({ptc})

local ptt = table.deepcopy(data.raw["active-defense-equipment"]["personal-laser-defense-equipment"])
ptt.name        = "personal-tesla-turret"
ptt.take_result = "personal-tesla-turret"
ptt.sprite      = {
  filename = "__space-age__/graphics/icons/teslagun.png",
  width    = 120,
  height   = 64,
  scale    = 0.5,
}
ptt.shape      = {width = 2, height = 2, type = "full"}
ptt.categories = MK2_CATEGORY
ptt.energy_source = {
  type            = "electric",
  usage_priority  = "secondary-input",
  buffer_capacity = "500kJ",
}
ptt.attack_parameters = {
  type            = "beam",
  cooldown        = 120,
  range           = 15,
  range_mode      = "center-to-bounding-box",
  damage_modifier = 1,
  ammo_category   = "tesla",
  ammo_type = {
    energy_consumption = "300kJ",
    action = {
      type = "direct",
      action_delivery = {
        type = "instant",
        target_effects = {
          -- Chain must go first so it fires before the primary target may die.
          {
            type = "nested-result",
            action = {
              type = "direct",
              action_delivery = {type = "chain", chain = "personal-tesla-turret-chain"},
            },
          },
          {
            type = "nested-result",
            action = {
              type = "direct",
              action_delivery = {
                type          = "beam",
                beam          = "personal-tesla-turret-beam",
                max_length    = 15,
                duration      = 30,
                add_to_shooter = false,
                destroy_with_source_or_target = false,
                source_offset = {0, -1.31439},
              },
            },
          },
        },
      },
    },
  },
}
data:extend({ptt})
