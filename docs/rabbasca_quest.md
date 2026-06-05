# Rabbasca Quest: Vault Tunnels

## Quest Goal

Descend into the ancient tunnel system beneath a Rabbascan vault, claim a mysterious artifact (the **Ancient Rabbit's Foote**), and return to the surface. Completing the quest unlocks the **Personal Warp Pylon** equipment.

---

## Tech Chain

```
forge-promethium-armor
  └─ armor-adventure-rabbasca  (5k each: automation/logistic/chemical/military/production/utility/space + athletic + promethium)
       └─ conquer-the-vault    (research_trigger: mine-entity "ancient-rabbits-foote")
            └─ personal-warp-pylon  (also requires interplanetary-construction-1)
```

`armor-adventure-rabbasca` is the investigation tech that starts the chain. It replaces `personal-warp-pylon` as the first visible Rabbasca node in the tech tree. `conquer-the-vault` is a triggered tech — it fires automatically when the player mines the ancient-rabbits-foote entity; it has no unit cost and cannot be manually queued.

---

## Player Flow

1. Research **Rabbasca Investigation is Hoppin'** (`armor-adventure-rabbasca`).
2. Craft a **Vault Excavation Key** at the Armor Forging Station.
3. Hack a vault spawner (using a normal `vault-access-key` from planet-rabbasca) to create an active `rabbasca-vault-console`.
4. While the hack is live, set the **vault-crafter** (`rabbasca-vault-crafter`) to the **Vault Entry Protocol** recipe and feed it the excavation key. After 60 seconds the crafter produces a **Vault Entry Pass**.
5. Pick up the Vault Entry Pass and **place it on the ground** anywhere. This acts as the entry trigger — it teleports the player to the `rabbasca-vault-tunnels` surface and destroys the placed entity.
6. Inside the tunnel: an **exit elevator** (`vault-tunnel-exit`) is placed immediately to the right of the spawn point. The **Ancient Rabbit's Foote** entity is at the far end of the room past the gate.
7. Blast through the stone-wall gate, fight through to the **Ancient Rabbit's Foote**, and mine it (2s). The **Conquer the Vault** tech triggers automatically.
8. Right-click the exit elevator → **Return to Surface** GUI button → teleports back to the exact position and surface where the player entered.

---

## Quality Scaling

The quality of the **Vault Entry Pass** item used for entry determines the difficulty and reward of the run:

- **Turret quality** scales with the key: a legendary key spawns legendary gun-turrets.
- **Foote item quality** scales with the key: the ancient-rabbits-foote item given on mining matches the key quality.
- The gate is **fully restored** on every entry — breached walls are replaced so each run starts fresh.
- The challenge room (gate + turrets + foote entity) is reset by `setup_challenge_room` in `quests/rabbasca.lua` at the start of every `enter_tunnel` call.

---

## Items

All items are defined inside `if mods["planet-rabbasca"] then` in `prototypes/item.lua`.

| Item | Stack | Notes |
|---|---|---|
| `vault-excavation-key` | 10 | `type = "ammo"` with private category `armor-adventure-vault-key` (no gun accepts it, so it cannot be fired); `ammo_category` is a top-level item field in Factorio 2.0; crafted at AFS; consumed by vault-entry-extraction recipe |
| `vault-entry-pass` | 1 | `place_result = "vault-entry-portal"`; placing it triggers entry; key quality is read from the placed entity |
| `ancient-rabbits-foote` | 1 | Trophy item; quality given manually by script at mining time to match the key used |

---

## Recipes

All recipes are inside `if mods["planet-rabbasca"] then` in `prototypes/recipe.lua`. Both are in `castra_prime_ignore`.

| Recipe | Category | Time | Ingredients | Result |
|---|---|---|---|---|
| `vault-excavation-key` | `armor-forging` | 30s | vault-security-key ×5, processing-unit ×10, low-density-structure ×20 | vault-excavation-key ×1 |
| `vault-entry-extraction` | `rabbasca-vault-extraction` | 60s | vault-excavation-key ×1 | vault-entry-pass ×1 |

`vault-excavation-key` is unlocked by `armor-adventure-rabbasca`. `vault-entry-extraction` runs in the `rabbasca-vault-crafter` (the vault entity itself), so the player must have an active hack before they can run it.

---

## Entities

All entities are defined inside `if mods["planet-rabbasca"] then` in `prototypes/entity.lua`.

| Entity | Type | Placed by | Notes |
|---|---|---|---|
| `vault-entry-portal` | container (iron-chest deepcopy) | Player (via vault-entry-pass item) | Destroyed immediately in `on_built_entity`; only exists long enough to read quality and fire the event |
| `vault-tunnel-exit` | assembling-machine (chemical-plant deepcopy) | Script (surface setup) | `crafting_categories = {"aquilo-elevator-dummy"}`, destructible = false; `on_gui_opened` intercepts it to show the Return GUI |
| `ancient-rabbits-foote` | simple-entity | Script (`setup_challenge_room`) | `minable = {mining_time = 2, results = {}}`; `destructible = false`; no auto-drop — item is given by script with correct quality; mining triggers `conquer-the-vault` research |

---

## The Tunnel Surface (`rabbasca-vault-tunnels`)

**File:** `quests/rabbasca.lua`

A single shared surface (not per-player). Created on first entry via `game.create_surface()` with all autoplace disabled. Layout:

- **Tunnel floor:** `refined-concrete`, 20 tiles wide (x ∈ [−10, 9]), 60 tiles long (y ∈ [−59, 0])
- **Room floor:** `refined-concrete`, 32 tiles wide (x ∈ [−16, 15]), 24 tiles deep (y ∈ [−83, −60])
- **Walls:** `out-of-map` inside the generation area; any chunk generated outside the initial layout is also filled by `on_chunk_generated`
- **Spawn point:** `{0, −3}` — where the player arrives
- **Exit elevator:** `{2, −3}` — immediately visible on arrival
- **Gate:** row of 32 stone walls (neutral force) across y = −60; restored on each entry
- **Turrets:** 4 gun-turrets (enemy force, quality-scaled) inside the room at SW/SE/NW/NE positions
- **Ancient Rabbit's Foote:** `{0, −80}` — at the far (north) end of the room
- **Daytime:** frozen at 0 (midnight) for a dark underground appearance; applied on every entry so old saves are migrated automatically

---

## Script Integration

**Entry** (`quests/quests.lua` → `on_built_entity` filter):

```lua
-- vault-entry-portal built → read quality → enter tunnel → destroy portal
if name == "vault-entry-portal" and rabbasca then
    local player = event.player_index and game.players[event.player_index]
    if player then
        local quality_name = event.entity.quality and event.entity.quality.name or "normal"
        rabbasca.enter_tunnel(player, quality_name)
    end
    if event.entity.valid then event.entity.destroy() end
end
```

`rabbasca.enter_tunnel(player, quality_name)` saves the player's position/surface/quality to `storage.vault_tunnel_return[player.index]`, resets the challenge room via `setup_challenge_room(surface, quality_name)`, then teleports to `SPAWN_POS`.

**Challenge room reset** (`quests/rabbasca.lua` → `setup_challenge_room`):

Called every entry. Clears old turrets (by type+area), old mcguffin (by name), and old gate walls (by name+area), then re-places all three with the new quality. Gate restoration means breached runs don't carry over.

**Exit** (`control.lua` → `on_gui_opened` + `on_gui_click`):

Opening `vault-tunnel-exit` closes the assembler GUI and shows a custom frame ("Vault Exit" / "Return to Surface" button). Clicking calls `rabbasca_quest.exit_tunnel(player)`, which reads the saved return data, teleports back, and clears storage.

**Research trigger + quality reward** (`quests/quests.lua` → `on_player_mined_entity`):

Mining `ancient-rabbits-foote` reads `storage.vault_tunnel_return[player.index].quality`, inserts a `ancient-rabbits-foote` item of that quality into the player's inventory (spills to ground if full), and prints a completion message. The entity's `minable.results` is empty so no duplicate normal-quality item is auto-given. The `conquer-the-vault` research fires via Factorio's built-in `research_trigger` system.

**Background** (`control.lua` → `on_chunk_generated`):

Any chunk generated on `rabbasca-vault-tunnels` is immediately filled with `out-of-map` tiles to prevent Nauvis terrain from appearing outside the handcrafted layout. Registered once at module load when `HAS_RABBASCA` is true.

**Storage key:** `storage.vault_tunnel_return[player_index]` — `{position, surface, quality}` table. Initialized in `on_init` and `init_storage`; cleared per-player in `on_player_created` and on exit.

---

## Exploration Mode

Three Rabbasca techs are covered in exploration mode (shown as `???` until prerequisites are met):

```lua
-- prototypes/technology.lua
table.insert(to_cover, "armor-adventure-rabbasca")
table.insert(to_cover, "conquer-the-vault")
table.insert(to_cover, "personal-warp-pylon")

-- control.lua COVERED_TECHS
COVERED_TECHS["armor-adventure-rabbasca-covered"] = "armor-adventure-rabbasca"
COVERED_TECHS["conquer-the-vault-covered"]        = "conquer-the-vault"
COVERED_TECHS["personal-warp-pylon-covered"]      = "personal-warp-pylon"
```

---

## Known Limitations / Future Work

- **Sky is Nauvis-at-night, not Rabbasca-themed.** A proper Rabbasca LUT/atmosphere requires a data-stage planet prototype with `surface_render_parameters`. The current fix (freeze at midnight + `on_chunk_generated` fill) gives a dark underground look but not Rabbasca color grading.
- **Turret ammo does not scale with quality.** Turrets always receive 100 `firearm-magazine` regardless of quality. Higher-quality ammo types could be inserted at higher quality tiers.
- **Placeholder icons.** All three new items use base-game icons (`electronic-circuit`, `advanced-circuit`, `copper-ore`). Replace with proper art when assets are available.
- **Placeholder tech icon.** `armor-adventure-rabbasca` uses `radar.png`. Should use an athletic-science or Rabbasca-specific icon.
- **Ancient Rabbit's Foote item has no downstream use.** It is a quality-scaled trophy collectible. Future work: use it as an ingredient in follow-up recipes or gate equipment upgrades.
- **Entry requires an active vault hack.** `vault-entry-extraction` is in the `rabbasca-vault-extraction` category, so the vault-crafter must be running (hack active). If the hack expires mid-craft, the recipe is interrupted. Stockpile vault-security-keys to extend the hack long enough to complete the 60s recipe.
- **Robot-built vault-entry-pass.** If a construction robot somehow places the vault-entry-pass, `event.player_index` will be nil and the entry is silently skipped (portal destroyed, nothing happens). This is acceptable since the item is not blueprintable and has stack size 1.
