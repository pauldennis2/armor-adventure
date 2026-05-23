data:extend({
  {
    type = "custom-input",
    name = "pocket-dimension-toggle",
    key_sequence = "ALT + B",
    consuming = "game-only",
  },
  {
    type = "shortcut",
    name = "pocket-dimension-toggle",
    action = "lua",
    toggleable = true,
    associated_control_input = "pocket-dimension-toggle",
    icon = "__base__/graphics/icons/blueprint.png",
    small_icon = "__base__/graphics/icons/blueprint.png",
    technology_to_unlock = "pocket-dimension",
  },
  {
    type = "custom-input",
    name = "time-stopper-activate",
    key_sequence = "ALT + T",
    consuming = "game-only",
  },
  {
    type = "shortcut",
    name = "time-stopper-activate",
    action = "lua",
    toggleable = true,
    associated_control_input = "time-stopper-activate",
    icon = "__base__/graphics/icons/battery-mk2-equipment.png",
    small_icon = "__base__/graphics/icons/battery-mk2-equipment.png",
    technology_to_unlock = "personal-time-stopper",
  },
})
