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
})
