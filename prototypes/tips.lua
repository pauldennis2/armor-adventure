data:extend({
  {
    type = "tips-and-tricks-item-category",
    name = "armor-adventure",
    order = "z-[armor-adventure]",
  },
  {
    type = "tips-and-tricks-item",
    name = "armor-adventure-welcome",
    category = "armor-adventure",
    order = "a",
    trigger = {
      type = "time-elapsed",
      ticks = 1,
    },
    skip_trigger = {
      type = "research",
      technology = "mech-armor-mk2",
    },
  },
  {
    type = "tips-and-tricks-item",
    name = "armor-adventure-welcome-ready",
    category = "armor-adventure",
    order = "a",
    trigger = {
      type = "research",
      technology = "mech-armor-mk2",
    },
  },
})
