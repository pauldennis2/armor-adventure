local function apply_fixed_tint(t, tint_color)
  if type(t) ~= "table" then return end
  if t.apply_runtime_tint then
    t.apply_runtime_tint = nil
    t.tint = tint_color
  end
  for _, v in pairs(t) do
    apply_fixed_tint(v, tint_color)
  end
end

local hot_rod_red = {r=1, g=0.15, b=0.15, a=1}
-- Personal Beacon: a real beacon entity that follows the player.
-- No collision so it doesn't block building; small selection box so player can click it.
-- Placed 1 tile above the player so it's distinguishable from the character.
local personal_beacon = table.deepcopy(data.raw["beacon"]["beacon"])
personal_beacon.name                 = "personal-beacon"
personal_beacon.minable              = nil
personal_beacon.allow_copy_paste     = false
personal_beacon.collision_box        = {{-0.01, -0.01}, {0.01, 0.01}}
personal_beacon.collision_mask       = {layers = {}}
personal_beacon.selection_box        = {{-0.5, -0.5}, {0.5, 0.5}}
personal_beacon.supply_area_distance = 4
personal_beacon.is_military_target   = false
personal_beacon.flags = {
  "not-on-map", "not-blueprintable", "not-deconstructable", "not-repairable",
}
-- Void energy source: beacon is always powered, no external network required.
personal_beacon.energy_source = {type = "void"}
-- Strip body/animation graphics; keep module icons so the player can see what's loaded.
personal_beacon.graphics_set = {module_icons_suppressed = false}
personal_beacon.radius_visualisation_picture = nil
data:extend({personal_beacon})

local char_anims = data.raw.character.character.animations
for _, entry in ipairs(char_anims) do
  if entry.armors then
    for _, name in ipairs(entry.armors) do
      if name == "mech-armor" then
        local mk2_anim = table.deepcopy(entry)
        mk2_anim.armors = {"mech-armor-mk2"}
        apply_fixed_tint(mk2_anim, hot_rod_red)
        table.insert(char_anims, mk2_anim)
        break
      end
    end
  end
end
