local regen_plating = table.deepcopy(data.raw["energy-shield-equipment"]["energy-shield-equipment"])
regen_plating.name        = "regenerative-plating"
regen_plating.take_result = "regenerative-plating"
data:extend({ regen_plating })

local combat_roboport = table.deepcopy(data.raw["roboport-equipment"]["personal-roboport-equipment"])
combat_roboport.name               = "personal-combat-roboport"
combat_roboport.take_result        = "personal-combat-roboport"
combat_roboport.robot_limit        = 0
combat_roboport.construction_radius = 0

data:extend({ combat_roboport })
