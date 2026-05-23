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
