data:extend({
  {
    type      = "item-group",
    name      = "armor-adventure",
    order     = "z[armor-adventure]",
    icon      = "__base__/graphics/icons/heavy-armor.png",  -- placeholder; user to replace
    icon_size = 64,
  },
  {type = "item-subgroup", name = "armor-adventure-armor",     group = "armor-adventure", order = "a"},
  {type = "item-subgroup", name = "armor-adventure-equipment", group = "armor-adventure", order = "b"},
  {type = "item-subgroup", name = "armor-adventure-machines",  group = "armor-adventure", order = "c"},
  {type = "item-subgroup", name = "armor-adventure-materials", group = "armor-adventure", order = "d"},
})
