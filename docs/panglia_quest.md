# Panglia Quest — Technical Brief

*Author: Claude Sonnet 4.6*

Quick reference for picking this quest back up. Not exhaustive — read the source for detail.

---

## Mod Guard

All Panglia code is guarded on `mods["panglia_planet"]`. Panglia strictly depends on Moshine (`Moshine`) and both are always installed together, so a Panglia guard is sufficient for code that also touches Moshine APIs. Some double-guards (`mods["panglia_planet"] and mods["Moshine"]`) exist and are fine to leave.

---

## Speed Zones

Panglia's "speed zones" are large fields of `panglia_hidden_beacon` entities placed at 1-tile intervals by the planet mod. They create movement speed bonuses while a player is inside. Our quest uses these as destructible resources.

There is no Factorio API to directly query a zone's shape — we reconstruct it at runtime from the entity list.

---

## Nuke Trigger (`quests/panglia.lua`)

**Entry point:** `on_script_trigger_effect` with `effect_id = "armor_adventure_nuke_on_panglia"`.

The trigger is injected into `atomic-rocket`'s `target_effects` in `data-final-fixes.lua` (guarded by Panglia mod check). The event carries `target_position` (impact point) and possibly `source_position` (launcher) — always prefer `target_position`.

**Algorithm:**
1. Load all `panglia_hidden_beacon` entities on the surface into a `grid[x][y]` lookup table (positions rounded to nearest integer — valid because Panglia uses 1-tile spacing).
2. Find the beacon nearest to the impact point via linear scan.
3. BFS flood-fill from nearest beacon using 8-directional adjacency (dx ∈ {-1,0,1}, dy ∈ {-1,0,1}). This collects the entire contiguous zone touching the impact point.
4. Destroy all beacons in the found set (no loot).
5. Record all beacon positions in `storage.panglia_pending_essence` with a `spawn_tick = game.tick + 300` (5-second delay for blast to settle).

**Spawn (on_tick_59):**
After the delay, for each queued batch:
- Set tile to `panglia-volcanic-ash-dark` at every position.
- Create a `panglia-essence-node` entity at every 200th position (`j % 200 == 1`).
- Remove the entry from the pending list.

**UPS note:** The beacon scan on nuke hit is O(n) over all beacons on the surface — this is acceptable because nukes are rare events. The tick handler is O(pending batches × positions) but only runs while batches are queued.

---

## panglia-essence-node Entity (`prototypes/entity.lua`)

```lua
type           = "simple-entity"
name           = "panglia-essence-node"
destructible   = false
collision_mask = {layers = {}}   -- walkable, doesn't block placement
minable        = {mining_time=1, results={{type="item", name="panglia-essence-of-speed", amount=5}}}
```

Key properties:
- Non-destructible (can't be killed by enemies or explosions) but mineable by the player.
- Zero collision — placed inside existing terrain features, robots can deconstruct it.
- `flags = {"placeable-neutral", "not-blueprintable"}` — no blueprint, can be placed anywhere.
- Drops **5 panglia-essence-of-speed** per node.

---

## Tech Chain

```
nuke speed zone
  → mine panglia-essence-node
  → research_trigger fires: "time-fracking" tech unlocks
  → unlocks recipe: panglia-essence-of-speed (data-processing category, Moshine machine)
  → craft: 1 panglia-essence-of-speed → 1 panglia-refined-speed (1000s, data-processing)
  → personal-time-stopper tech (prereq: time-fracking, x30 datacells, 400k time)
  → unlocks: personal-time-stopper recipe (armor-forging category)
```

### time-fracking Technology
- `research_trigger = {type = "mine-entity", entity = "panglia-essence-node"}` — no unit/cost, fires on first mine.
- Prerequisite: `forge-promethium-armor`.
- Effect: unlocks `panglia-essence-of-speed` recipe.

### personal-time-stopper Technology
- Prerequisite: `time-fracking`.
- Cost: 30× {datacell-raw-data, datacell-ai-model-data, datacell-solved-equation, datacell-dna-sequenced}, 400,000s time.
- Effect: unlocks `personal-time-stopper` recipe.

---

## Personal Time Stopper Equipment

- **Activation:** Alt+T shortcut (`time-stopper-activate`).
- **Duration by quality:** Normal 10s / Uncommon 12s / Rare 15s / Epic 20s / Legendary 30s.
- **Cooldown:** 60 seconds after effect ends.
- **Unique:** only one may be equipped at a time.
- **Storage keys:** `time_stopper_active`, `time_stopper_cooldown`, `time_stopper_render`.
- Runtime in `control.lua` — searches for the equipment in character armor grid, applies slowdown to nearby enemies and speed boost to player.

---

## Storage Key

`storage.panglia_pending_essence` — array of `{surface_index, positions[], spawn_tick}` entries. Initialized in `control.lua:init_storage()`. Consumed and cleared in `quests/panglia.lua:on_tick_59()`.

---

## Files Touched

| File | What's there |
|------|-------------|
| `quests/panglia.lua` | Nuke handler, tick handler for delayed spawning |
| `quests/quests.lua` | Panglia require + dispatch wired into always-handler and on_script_trigger_effect |
| `prototypes/entity.lua` | `panglia-essence-node` and `processing-grid-process-essence-of-speed` plant entity |
| `prototypes/technology.lua` | `time-fracking` (research_trigger) and `personal-time-stopper` techs |
| `prototypes/recipe.lua` | `panglia-essence-of-speed` and `personal-time-stopper` recipes |
| `prototypes/item.lua` | `panglia-essence-of-speed`, `panglia-refined-speed`, `personal-time-stopper` items |
| `data-final-fixes.lua` | Injects nuke script trigger; adds essence-of-speed to processing-grid accepted_seeds |
| `locale/en/armor-adventure.cfg` | All locale strings for the above |
| `control.lua` | `init_storage` includes `panglia_pending_essence`; time-stopper runtime logic |
