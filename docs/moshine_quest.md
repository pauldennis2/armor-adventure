# Moshine Quest: Vortex Data Collection

## Quest Goal

Produce **Vortex Data Cards** by simultaneously capturing deosil (clockwise) and widdershins (counterclockwise) motion data from high-speed trains circling on Moshine's neodymium rail network.

---

## How the Detection Script Works

**File:** `quests/moshine.lua` — called via `on_nth_tick(3)` (20×/sec), registered in `quests/quests.lua`.

The script watches every locomotive on the Moshine surface and builds a position history per train using **distance-adaptive sampling**: a new history point is only recorded when the train's `front_stock` has moved ≥ 10 tiles from the last recorded position. This makes the history arc-length-based rather than time-based, so it's valid across the wide speed range present on Moshine (trains can do ~900 kph).

Once a train has 8 history points and carries at least one magnet (any quality) in a cargo wagon, it computes:

1. **`cross_sum`** — sums the 2D cross-product across all 6 consecutive triplets in the history. Straight track segments contribute ~0; corners accumulate a sign that reveals rotation direction. In Factorio's coordinate system (Y increases downward): **positive = clockwise = deosil**, **negative = counterclockwise = widdershins**.

2. **`fit_circle`** — fits the unique circumscribed circle through `history[1]`, `history[4]`, `history[8]` (spread across the history for stability). Returns center (cx, cy) and radius.

3. If `|cross_sum| > CROSS_THRESHOLD` and `radius >= MIN_RADIUS`, a **scan token** (hidden item) is inserted into any `data-processor` within `radius × INSIDE_FACTOR` of the circle center. This means the machine must be **inside the loop**, not merely nearby.

The scan token combined with 100 raw-data fluid in the data-processor produces one motion-data item (1-second craft). Scan tokens spoil in 1 second; motion data spoils in 2 seconds. `reset_freshness_on_craft = true` on both recipes ensures output always starts at full freshness regardless of token age.

### Key Constants (easy to tune)

| Constant | Value | Purpose |
|---|---|---|
| `SPEED_MIN` | 2.0 tiles/tick (~432 kph) | Ignores slow/stopped trains |
| `MIN_SAMPLE_DISTANCE` | 10 tiles | Arc-length between history samples |
| `HISTORY_SIZE` | 8 | Samples kept per train |
| `CROSS_THRESHOLD` | 0.5 | Min cross-sum to commit to a direction |
| `MIN_RADIUS` | 8 tiles | Fitted circle must be at least this big |
| `INSIDE_FACTOR` | 0.6 | Data-proc must be within 60% of radius from center |

---

## Items and Recipes

All Moshine-gated items/recipes live inside `if mods["Moshine"] then` blocks.

| Item | Spoil | Notes |
|---|---|---|
| `deosil-scan-token` | 60 ticks (1s) | Hidden; inserted by script |
| `widdershins-scan-token` | 60 ticks (1s) | Hidden; inserted by script |
| `deosil-motion-data` | 120 ticks (2s) | Output of data-processor |
| `widdershins-motion-data` | 120 ticks (2s) | Output of data-processor |
| `vortex-data-card` | None | Final output; uses `datacell-solved-equation.png` |

**Motion-data recipes** (`data-processing` category, 1s craft, `reset_freshness_on_craft = true`):
- 100 raw-data fluid + 1 scan token → 1 motion-data item

**Vortex recipe** (`data-processing` category, 1s craft):
- 5 deosil-motion-data + 5 widdershins-motion-data + 1 `datacell-empty` → 1 vortex-data-card

---

## What the Player Needs to Build

The core constraint: **deosil and widdershins data must be produced simultaneously** because motion-data spoils in 2 seconds. The vortex recipe needs 5 of each, meaning both directions must be flowing in parallel.

**Minimum working setup:**
- One circular (or figure-8) high-speed train loop on Moshine
- Train carrying magnets (any quality), running at ≥ 432 kph
- Data-processors placed **inside the loop** (center region, within 60% of the loop radius from center)
- One data-processor set to `deosil-motion-data` recipe, one set to `widdershins-motion-data`
- A third data-processor set to `vortex-data-card` recipe, fed by the first two and stocked with `datacell-empty` cards and raw-data

**For normal-quality data-processors** (1 craft/sec): you need 5 of each type running simultaneously to fill the vortex machine fast enough. This is the "inner and outer ring" design — deosil processors on one ring, widdershins on the other, vortex in the center.

**With legendary data-processors** (2.5 crafts/sec): a single deosil + single widdershins processor is sufficient.

### Figure-8 note

A figure-8 track works elegantly: the two loops naturally enforce opposite rotation directions, so a single train provides both signals depending on which loop it's currently traversing. The data-processors must be placed inside the correct sub-loop for each recipe.

---

## Known Limitations / Future Work

- If the train is fast enough to complete a full lap within `MIN_SAMPLE_DISTANCE` tiles of travel (circumference < 10 tiles), the circle fit degenerates. Not possible on any real Factorio loop.
- Potential future gate: **require neodymium rails** and/or a **maglev locomotive**. Both are feasible — maglev check is free (`train.locomotives.front_movers[1].name`); neodymium rail check is one `find_entities_filtered` per sample at the locomotive position. Exact Moshine entity names would need to be confirmed from the mod's entity prototypes before implementing.
- Motion-data recipes currently `enabled = true` for testing. Should be locked behind a Moshine-specific tech when the questline is designed.
- Vortex data card has no downstream use yet — placeholder for the next stage of the Moshine questline.
