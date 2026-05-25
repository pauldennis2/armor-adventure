# Coding Patterns

## Quest Module Structure

Quest logic lives in `quests/` and is split by planet:

```
quests/
  quests.lua    — dispatcher: owns all event registrations, manages tick-59 lifecycle
  castra.lua    — SIMULAC Commander quest
  gleba.lua     — Harvester, mind control, tesla turret, demolisher heart
  fulgora.lua   — Massive Lightning Collector
```

`control.lua` owns all equipment/armor behavior and requires `quests.quests` once at the top.

---

## Surface-Driven Tick Registration

Planet quest work runs on `on_nth_tick(59)`. This handler is **registered and deregistered dynamically** rather than running a surface check inside a permanent handler.

**Why 59?** It's a dedicated slot used only by planet quests. `on_nth_tick(60)` belongs to `control.lua` (time stopper, personal fridge, warp pylon). Using different N values avoids Factorio's last-registration-wins overwrite.

**How it works:**

`quests.refresh()` is called whenever relevant state changes:
- A player changes surface (`on_player_changed_surface`)
- A tech is researched (`on_research_finished`)
- The mod configuration changes (`on_configuration_changed`)

`refresh()` scans all players and calls `script.on_nth_tick(59, handler_or_nil)`:
- No player on a quest surface → `nil` (deregistered, zero UPS cost)
- Players all on the same quest surface + tech researched → register that planet's handler
- Players on **different** quest surfaces → `nil` (split-party rule, see below)

Adding a new planet quest means:
1. Create `quests/<planet>.lua` with an `on_tick_59()` function
2. Add a `make_handler("surfacename")` branch in `quests/quests.lua`
3. Add the tech name to `QUEST_TECH_SURFACES` if there's a research gate

---

## The Split-Party Rule

In multiplayer, `on_nth_tick(N)` is global — there is no per-player handler. If player A is on Castra and player B is on Gleba simultaneously, whichever surface-change event fires last would overwrite the other player's quest handler, causing undefined behavior (e.g., the SIMULAC Commander losing its tick loop mid-fight).

**Rule: if any two players are on different quest surfaces, all quest handlers are disabled.**

This is intentional. Planet quests are cooperative. Never split the party.

---

## Factorio Event Ownership Rules

Each event type can only have **one handler per mod**. A second `script.on_event(...)` or `script.on_nth_tick(N, ...)` for the same event/N silently replaces the first — no error, no warning.

Current ownership:
| Handler | Owner |
|---|---|
| `on_nth_tick(1)` | `quests.lua` (MLC drain) |
| `on_nth_tick(20)` | `quests.lua` (Castra laser attack) |
| `on_nth_tick(30)` | `control.lua` (combat roboport) |
| `on_nth_tick(59)` | `quests.lua` (dynamic — planet quest) |
| `on_nth_tick(60)` | `control.lua` (time stopper, fridge, warp pylon) |
| `on_nth_tick(300)` | `quests.lua` (MLC rescan) |
| `on_nth_tick(3600)` | `quests.lua` (Castra meter drain) |
| `on_entity_died` | `quests.lua` |
| `on_script_trigger_effect` | `quests.lua` |
| `on_player_changed_surface` | `quests.lua` |
| All others | `control.lua` |

When adding a new event registration, check this table first.
