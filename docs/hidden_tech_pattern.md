# Hidden Tech Pattern (Exploration Mode)

The exploration mode system hides quest tech details behind `???` placeholder techs until the player has completed all prerequisites. Controlled by the `armor-adventure-exploration-mode` startup setting.

---

## Data Stage: Shadow Techs (`prototypes/technology.lua`)

At the end of `technology.lua`, if the setting is enabled, each quest tech gets a paired **shadow tech** named `<tech>-covered`:

```lua
-- Real tech is suppressed:
real.enabled               = false
real.visible_when_disabled = false

-- Shadow tech takes its place in the tree:
{
  name                  = tech_name .. "-covered",
  icon                  = real.icon,        -- same icon as real
  localised_name        = {"", "???"},
  localised_description = {"", "Complete the prerequisites..."},
  prerequisites         = real.prerequisites,  -- same position in tree
  unit = {count = 100000000, ingredients = {{"promethium-science-pack", 1}}, time = 60},
  effects = {},
}
```

Key properties of the shadow:
- **Same prerequisites** as the real tech → appears at the correct position in the tree
- **Impossible cost** (100M promethium packs) → can never be manually researched
- **No effects** → researching it (somehow) would do nothing
- The real tech is invisible while disabled, so only one appears at a time

`mech-armor-mk2` (the Armor Forging Station) is **explicitly exempt** — it always shows normally as the entry point to the whole system.

---

## Runtime Stage: Reveal Logic (`control.lua`)

`COVERED_TECHS` is a `{shadow_name → real_name}` lookup table built at load time:

```lua
local COVERED_TECHS = {
  ["packable-forge-covered"] = "packable-forge",
  ["big-demolisher-hunt-covered"] = "big-demolisher-hunt",
  -- ...
}
```

`reveal_all_exploration_techs(force)` iterates the table and enables the real tech whenever all prerequisites are researched:

```lua
for shadow_name, real_name in pairs(COVERED_TECHS) do
  local shadow = force.technologies[shadow_name]
  local real   = force.technologies[real_name]
  if shadow and real and shadow.enabled then
    local all_done = true
    for _, prereq_tech in pairs(real.prerequisites) do
      if not prereq_tech.researched then all_done = false; break end
    end
    if all_done then
      real.enabled   = true
      shadow.enabled = false
    end
  end
end
```

This is called from three hooks:
- `on_init` — covers fresh game starts
- `on_configuration_changed` — covers mod updates / saves loaded mid-playthrough
- `on_research_finished` — covers normal play (each completed research may unlock new reveals)

O(n × k) cost on research-finish events only. Zero on-tick cost.

---

## Interaction with `research_trigger` Techs

Several techs use native triggers instead of a manual research cost (e.g. `mine-entity`, `craft-item`). These are safe with the shadow pattern because:

1. A disabled tech **does not fire its trigger**.
2. The reveal runs on `on_research_finished` (prerequisite completed) — which always happens **before** the player can perform the trigger action in normal gameplay.
3. Once the reveal fires and the real tech is enabled, its trigger works normally.

Techs using triggers currently: `big-demolisher-hunt`, `nauvis-defense-complete`, `aquilo-scanning-complete`, `cryo-core-acquired`, `dissection-analysis-complete`, `core-hunt` (Castra), `time-fracking` (Panglia).

---

## Adding a New Covered Tech

1. **`technology.lua`** — add the tech name to the `to_cover` list (inside the `if settings.startup[...]` block at the bottom). Wrap in `if mods["mod-name"]` if it's companion-mod-conditional.

2. **`control.lua`** — add `["<tech>-covered"] = "<tech>"` to `COVERED_TECHS`. Match the same mod guard.

That's it. The shadow tech is generated automatically from the `to_cover` list; no need to write it by hand.

---

## Current Covered Techs

| Tech | Mod gate |
|---|---|
| `packable-forge` | — |
| `armor-adventure-nauvis` | — |
| `nauvis-defense-complete` | — |
| `big-demolisher-hunt` | — |
| `armor-adventure-vulcanus` | — |
| `armor-adventure-gleba` | — |
| `dissection-analysis-complete` | — |
| `armor-adventure-fulgora` | — |
| `armor-adventure-aquilo` | — |
| `aquilo-scanning-complete` | — |
| `cryo-core-acquired` | — |
| `forge-promethium-armor` | — |
| `regenerative-armor` | — |
| `personal-tesla-turret` | `Moshine` |
| `time-fracking` | `panglia_planet` |
| `personal-time-stopper` | `panglia_planet` |
| `personal-warp-pylon` | `planet-rabbasca` |
| `core-hunt` | `castra-prime` |
| `personal-combat-roboport` | `castra-prime` |
| `pocket-dimension` | _(unconditional)_ |
| `pocket-dimension-roboport` | _(unconditional)_ |
