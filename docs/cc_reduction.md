# CC Reduction — Design Spec & Implementation Notes

## Concept

A piece of equipment (or passive item) for the Promethium Armor that reduces the duration of crowd-control effects applied to the player. The primary target is the **stun from land mines**, which most games would call a "root" — movement is locked but the player can still fire weapons. Quality of the equipment scales the reduction percentage.

The goal is mitigation, not nullification. The player should still feel the effect.

---

## How Stuns Work in Factorio 2.x (Base Game)

### Data Stage — Sticker Prototype

The land mine stun is **not** a native engine stun flag. It is implemented as a **sticker entity** created on detonation. From `data/base/prototypes/entity/entities.lua`:

```lua
-- Land mine action (on detonation):
{ type = "create-sticker", sticker = "stun-sticker" }

-- Stun sticker prototype:
{
  type                    = "sticker",
  name                    = "stun-sticker",
  flags                   = {"not-on-map"},
  hidden                  = true,
  duration_in_ticks       = 3 * 60,  -- 180 ticks = 3 seconds
  target_movement_modifier = 0,       -- full immobilization
}
```

Other sources of stun (e.g. `electric-mini-stun`) also use the sticker system with the same pattern.

### Runtime API

| Property | Type | Access | Description |
|---|---|---|---|
| `entity.stickers` | `array[LuaEntity]?` | Read-only | All sticker entities currently attached to this entity |
| `sticker.sticked_to` | `LuaEntity` | Read-only | The entity this sticker is attached to |
| `sticker.time_to_live` | `uint64` | **Read-write** | Remaining ticks before the sticker expires (= stun ends) |
| `sticker.prototype.duration_in_ticks` | `uint` | Read (prototype) | Original max duration baked into the prototype |

**Key facts:**
- `time_to_live` is writable — setting it to 0 removes the sticker immediately
- The original duration is NOT stored as a runtime field, but IS accessible via `sticker.prototype.duration_in_ticks`
- This means we can compute both remaining duration AND fraction elapsed at runtime
- There is no `on_sticker_applied` event — the application cannot be intercepted

---

## Implementation Plan

### Polling Approach

Since there is no application event, the handler must poll. `on_nth_tick(60)` (once per second) is acceptable:
- A 3-second stun will be caught within the first second (~33% of duration elapsed)
- Overhead is negligible: hot path is one `character.stickers` check per player; single-player mod means one iteration

### One-Shot Reduction Logic

The reduction must be applied **once per sticker application**, not every tick. Options:

**Recommended — unit_number tracking:**
```lua
storage.processed_stickers = storage.processed_stickers or {}

for _, sticker in ipairs(character.stickers or {}) do
    if sticker.name == "stun-sticker" then
        local id = sticker.unit_number
        if not storage.processed_stickers[id] then
            storage.processed_stickers[id] = true
            sticker.time_to_live = math.floor(sticker.time_to_live * (1 - reduction))
        end
    end
end

-- Cleanup expired entries (sticker unit_numbers of destroyed stickers):
-- Can be pruned lazily — check valid before use, or sweep periodically.
```

**Alternative — proximity-to-original check:**
Only apply if `time_to_live >= 0.9 * sticker.prototype.duration_in_ticks` (i.e., fired within first 10% of duration). Avoids storage but is fragile if the tick fires late.

Unit number tracking is cleaner.

### Storage Cleanup

`storage.processed_stickers` accumulates dead keys over time. Two approaches:
1. **Lazy**: check `sticker.valid` before using the id; never bother sweeping (memory cost is negligible for rare events)
2. **Active sweep**: on the same `on_nth_tick(60)`, iterate and prune any keys whose associated entity is no longer valid

Lazy is fine given how infrequently players get stunned.

### Quality Scaling

Suggested reduction percentages (open to tuning):

| Quality | Reduction | 3s stun becomes |
|---|---|---|
| Normal | 25% | ~2.25s |
| Uncommon | 35% | ~1.95s |
| Rare | 50% | ~1.5s |
| Epic | 65% | ~1.05s |
| Legendary | 80% | ~0.6s |

Implemented via a `[0]=` indexed table (Factorio quality levels are 0-indexed):
```lua
local CC_REDUCTION = {[0]=0.25, 0.35, 0.50, 0.65, 0.80}
local reduction = CC_REDUCTION[equipment.quality.level] or 0.25
```

### Scope — Other Sticker-Based Effects

The same handler can cover any sticker whose name is on a whitelist, e.g.:
```lua
local CC_STICKERS = {["stun-sticker"] = true, ["electric-mini-stun"] = true}
```
Checking `CC_STICKERS[sticker.name]` before processing means future effects can be opted in cheaply.

---

## Open Design Questions

- **Item or equipment?** Equipment integrates cleanly with quality scaling (grid slot with level).  
  A passive inventory item is simpler to prototype but quality-in-grid is more thematically consistent with the rest of the mod.
- **Equipment category:** `armor-adventure-mk2` (MK2-only), same as other Promethium Armor modules.
- **What to name it?** Candidates: *Neural Dampener*, *Kinetic Dampener*, *Impact Isolator*, *Stasis Breaker*.
- **Should legendary fully break the effect?** 80% leaves ~0.6s which is nearly nothing. Could cap legendary at 75% to keep a token CC.
- **Should it cover non-base-game stickers?** Castra Prime or other mods may apply their own stickers. Opt-in whitelist keeps this safe.

---

## Files to Touch When Implementing

- `prototypes/item.lua` — new item + equipment-grid entry (inside a mod guard if Castra-gated, or unconditional)
- `prototypes/equipment.lua` — equipment prototype
- `prototypes/recipe.lua` — recipe + add to `castra_prime_ignore` list
- `prototypes/technology.lua` — unlock (probably a post-game tech)
- `quests/quests.lua` — register `on_nth_tick(60)` handler (merge with existing tick-60 if one exists; see note below)
- `control.lua` — owns `on_nth_tick(60)` currently via `M.on_tick_60()` dispatch; merge there
- `locale/en/armor-adventure.cfg` — item/equipment/tech names and descriptions
- `storage` key needed: `processed_stickers` (table, unit_number → true)

**Note on tick-60 ownership:** `control.lua` currently owns `on_nth_tick(60)` and dispatches via `M.on_tick_60()`. Do NOT register a second `on_nth_tick(60)` in quests.lua — it would silently replace the existing handler. Add the sticker check to the existing dispatch.
