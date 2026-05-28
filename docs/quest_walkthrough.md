# Armor Adventure — Quest Walkthrough

*Author: Claude Sonnet 4.6*

> **TODO for author:** Review and edit this document before publishing. Verify all item names, quest step details, and companion mod sections against the current implementation. Add any missing steps, clarify any confusing phrasing, and decide how much to reveal in the "getting started" section.

This document describes every quest in explicit detail. If you want hints only, see [hints.md](hints.md).

---

## Getting Started

You need to reach **promethium science** in the base Space Age tech tree before anything here is accessible. Once you have promethium science packs, research **Armor Forging Station** (all 12 science packs, 50,000 units). This unlocks the Armor Forging Station recipe and building.

Build at least one Armor Forging Station. It is the crafting machine for almost all Promethium Armor components. It does not accept quality modules.

From the Armor Forging Station unlock, five planetary investigation technologies become available simultaneously — one for each Space Age planet. They can be researched and completed in any order. All five must be completed to unlock the final **Forge Promethium Armor** technology.

---

## Nauvis: Biter Investigation

**Technology:** Nauvis Biter Investigation (all science packs, 10,000 units)

**Unlocks:** Pheromone Emitter recipe

**Goal:** Collect a Gigantic Chitinous Shell

### Steps

1. Research **Nauvis Biter Investigation**.
2. Craft a **Pheromone Emitter** (Armor Forging Station recipe). Higher quality emitters may attract a higher quality boss.
3. Go to Nauvis and place the Pheromone Emitter somewhere you can defend. The emitter must be placed on Nauvis — it will be returned to you if placed elsewhere.
4. On placement, four **Pheromone Emitter Nests** appear at cardinal directions about 70 tiles away. These are neutral structures and cannot be damaged. Waves of biters will stream from them.
5. Defend the emitter for **60 seconds**. Surge waves hit at 25%, 50%, and 75% charge. The biter mix escalates from big biters toward behemoths and spitters as the charge climbs.
6. When the emitter reaches full charge, it explodes and a **Gigantoid Spitter** spawns nearby. Kill it.
7. The Gigantoid drops a **Gigantic Chitinous Shell** in a nearby chest. Collect it.
8. The **Nauvis Defense Complete** technology auto-researches when the Gigantoid dies, unlocking the **Ablative Chitocarbon Shell** recipe.
9. Craft the **Ablative Chitocarbon Shell** (Armor Forging Station) using the Chitinous Shell. This is one of the five armor components.

**Note:** Big worms also drop Chitinous Shells, but these are non-quality and are not the component you need for the armor itself — they're a secondary byproduct if you happen to be clearing worms.

---

## Vulcanus: Demolisher Anatomy Investigation

**Technology:** Vulcanus Demolisher Anatomy Investigation (all science packs + metallurgic, 10,000 units)

**Unlocks:** Split Demolisher Heart recipe, Compress Heart Fragments recipe, Promethium Armor Chassis recipe

**Goal:** Craft a Promethium Armor Chassis

### Steps

1. Research **Vulcanus Demolisher Anatomy Investigation**.
2. Go to Vulcanus and kill a **Big Demolisher**. You must be within 50 tiles of it when it dies — if no player character is nearby, no drop occurs.
3. Collect the **Demolisher Heart** from the ground.
4. Use the **Split Demolisher Heart** recipe to split it into **Large Demolisher Heart Fragments**.
5. Use the **Compress Heart Fragments** recipe to compress fragments into the refined form needed for the chassis.
6. Craft the **Promethium Armor Chassis** at the Armor Forging Station using the processed heart material and other components.

The chassis is one of the five armor components and also equippable as a passive 1×1 module in any modular armor.

---

## Gleba: Pentapod Investigation

**Technology:** Gleba Pentapod Investigation (all science packs + agricultural, 10,000 units)

**Unlocks:** Harvester recipe, Mind Control Rocket recipe, Bio Interface recipe

**Goal:** Craft a Bio Interface

### Steps

1. Research **Gleba Pentapod Investigation**.
2. Craft **Mind Control Rockets** (unlocked by the research). These are fired from a regular rocket launcher or rocket turret.
3. Go to Gleba and fire Mind Control Rockets at **enemy pentapods** (units and spider-units only — the rockets have no effect on structures or other entity types). Successfully hit enemies will switch to neutral force and begin wandering.
4. Build a **Harvester** near where the mind-controlled enemies are roaming. The Harvester must be powered. It automatically searches a 10-tile radius, consumes any mind-controlled enemies it finds, and converts their health into **Enemy Biomass** (1 biomass per 1000 HP consumed). It runs the "Gleba Parts from Biomass" recipe automatically.
5. Collect **Gleba Parts** from the Harvester's output.
6. Craft a **Bio Interface** at the Armor Forging Station using Gleba Parts and other components.

The Bio Interface is one of the five armor components and also equippable as a passive 1×1 module in any modular armor.

---

## Fulgora: Climate Investigation

**Technology:** Fulgora Climate Investigation (all science packs + electromagnetic, 10,000 units)

**Unlocks:** Massive Lightning Funnel recipe, Superconducting Telemetry Core recipe

**Goal:** Craft a Superconducting Telemetry Core

### Steps

1. Research **Fulgora Climate Investigation**.
2. Craft a **Massive Lightning Funnel** (the item is called "Massive Lightning Funnel" in your inventory).
3. Place it on Fulgora **far from your base**. It draws in lightning from a wide area but does not connect to the power grid — the energy goes somewhere else. Having it near your base disrupts your power supply.
4. Wait for the funnel to accumulate 1 TJ (1,000,000,000,000 J) of energy from lightning strikes. When this threshold is reached, it converts the stored energy into a **Charged Lightning Gem** that drops on the ground nearby.
5. Collect the Charged Lightning Gem. The funnel resets and begins accumulating again, so you can farm multiple gems over time.
6. Craft a **Superconducting Telemetry Core** at the Armor Forging Station using the Charged Lightning Gem and other components.

The Telemetry Core is one of the five armor components and also equippable as a passive 1×1 module in any modular armor.

---

## Aquilo: Signal Investigation

**Technology:** Aquilo Signal Investigation (all science packs + cryogenic, 10,000 units)

**Unlocks:** Thermodynamic Regulator recipe

This quest has three sub-phases.

### Phase 1: EM Scanning

1. Research **Aquilo Signal Investigation**.
2. Go to Aquilo and build powered **Radars** on the surface. The scanning progress accumulates based on the number of active radars each ~59 ticks. With 1 radar it takes roughly 20 minutes; with 20 radars it takes about 1 minute.
3. At 50% you receive a notification. At 100%, an **Anomalous Signal Source** entity spawns 60–80 tiles from your current position on Aquilo.
4. Go find and **mine** the Anomalous Signal Source. Mining it triggers the **Signal Triangulation** technology automatically (no research cost — it fires the moment you mine the entity).
5. Signal Triangulation unlocks the **Aquilo Elevator Shaft** recipe.

### Phase 2: Elevator Construction

1. Craft an **Aquilo Elevator Shaft** (Armor Forging Station recipe, requires concrete and steel among other things).
2. Place it on Aquilo. It runs the **Excavate Elevator Segment** recipe automatically — you need to feed it **concrete** and **steel plate**. It produces **stone** and **iron ore** as byproducts; route these away to keep it running.
3. The shaft must complete **100 cycles**. A counter above the machine tracks progress.
4. At 100 cycles, the shaft is replaced by an **Aquilo Elevator** placeholder. You will see a notification.

### Phase 3: The Fulgoran Depot

1. Interact with the completed Aquilo Elevator to descend to the **Fulgoran Depot** — a small underground chamber.
2. The depot contains four **constant combinators** at the corners of the room, each displaying a puzzle clue. The answers:
   - **Southeast puzzle** — Fibonacci: 1, 1, 2, ?, 5, 8. Set signal [A] = **3**.
   - **Southwest puzzle** — Powers of two: 2, 4, ?, 16, 32. Set signal [A] = **8**.
   - **Northeast puzzle** — The Answer to Life, the Universe, and Everything. Set signal [A] = **42**.
   - **Northwest puzzle** — "The kind of thing an idiot would have on his luggage" (5 digits). Set signals [1] through [5] each to a positive value (any positive number works — the answer is **1-2-3-4-5**, from *Spaceballs*).
3. When all four puzzles are solved (indicators turn green), the **Cryovault** chest in the north wall unlocks.
4. The cryovault contains a **Cryovault Access Card**. Pick it up, then insert it into the **Vault Card Reader** (the entity to the right of the cryovault). This triggers the **Cryo-core Acquired** technology.
5. The Cryo-core Acquired tech unlocks the **Cryovault Access Card** crafting recipe (so you can make quality cards) — but for now, the one from the chest is all you need.
6. Use the depot elevator to ascend back to Aquilo.
7. Craft a **Thermodynamic Regulator** at the Armor Forging Station using the Cryo Core and other components.

The Thermodynamic Regulator is one of the five armor components and also equippable as a passive 1×1 module in any modular armor.

---

## Forging the Promethium Armor

Once all five investigations are complete (**Vulcanus**, **Gleba**, **Fulgora**, **Cryo-core Acquired**, **Nauvis Defense Complete**), the **Forge Promethium Armor** technology becomes available (all 12 science packs, 10,000 units). Researching it unlocks the Promethium Armor recipe and the Superconducting Telemetry Core crafting recipe.

Craft the **Promethium Armor** at the Armor Forging Station. You will need all five planetary components among the ingredients:
- Ablative Chitocarbon Shell (Nauvis)
- Promethium Armor Chassis (Vulcanus)
- Bio Interface (Gleba)
- Superconducting Telemetry Core (Fulgora)
- Thermodynamic Regulator (Aquilo)

Wear it. It has a 12×14 equipment grid.

---

## Post-Game: Castra Prime (requires castra-prime mod)

**Goal:** Research Personal Combat Roboport

Castra is a battlefield world. Enemy **data-collector bases** (destroyable buildings on Castra) fill a hidden meter when destroyed. Higher quality buildings contribute more points (1–5 per building). A warning fires at 30 points. At 50 points, a **SIMULAC Commander** spawns near you.

1. Go to Castra and destroy enemy data-collector bases. Watch for the warning message.
2. When the SIMULAC Commander spawns, destroy it. It is a tough enemy that moves toward you aggressively. The game prints a warning when it spawns.
3. When the Commander dies, it leaves **SIMULAC Core Remains**. Mine the remains — this triggers the **The Core Hunt** technology automatically.
4. Core Hunt unlocks the **SIMULAC Core** refinement recipe. Use this to refine the raw cores you find.
5. Once Core Hunt is researched, **Personal Combat Roboport** becomes visible in the tech tree. Research it using battlefield science packs and other packs. It unlocks three roboport module variants (Defender, Distractor, Destroyer). These are Promethium Armor only.

---

## Post-Game: Moshine (requires Moshine mod)

**Goal:** Research Personal Tesla Turret and collect Vortex Data Cards

Moshine involves **train-direction data collection**. The planet has trains running circular loops, and some loops run clockwise (deosil) while others run counterclockwise (widdershins).

1. On Moshine, build a circular train loop. Place a locomotive and cargo wagon on it, load the cargo wagon with a **Magnet**, and start the train running. The train must reach a minimum speed to be tracked.
2. Place a **Data Processor** building inside the loop (within the circle the train traces). Set the processor to either the **Deosil Motion Data Capture** or **Widdershins Motion Data Capture** recipe, depending on which direction you want to detect.
3. The mod tracks the train's position history. When it confirms the loop direction matches the recipe, it inserts a **Scan Token** into the data processor's input inventory automatically. The processor then runs the recipe and produces the motion data item.
4. Collect **Deosil Motion Data** and **Widdershins Motion Data** from the processors.
5. Use these at the Moshine data-processing infrastructure to produce **Vortex Data Cards**.
6. Research **Personal Tesla Turret** using Training Data datacells and AI Model Data datacells (×30, 400,000 second research time). The tech also unlocks the Vortex Data Card recipe. Craft the turret using the recipe and slot it into your Promethium Armor.

---

## Post-Game: Panglia (requires Panglia Planet mod)

**Goal:** Research Personal Time Stopper

Panglia's surface has large **speed zones** — fields of hidden beacons that grant movement speed while inside. These zones can be destroyed with atomic weapons.

1. Go to Panglia and locate a speed zone.
2. Fire an **atomic rocket** into the zone. The explosion triggers a script that detects the entire contiguous zone you hit and destroys all the hidden beacons in it after the blast.
3. After the blast settles (about 5 seconds), **Speed Zone Residue** nodes (panglia-essence-node) appear at intervals across the former zone. These are harmless entities that stay in place.
4. **Mine** the Speed Zone Residue nodes. The first time you mine one, the **Time Fracking** technology researches automatically (no cost — triggered by the mining act).
5. Time Fracking unlocks the **Essence of Speed** recipe in Moshine's data-processing machines. Run this recipe to convert Essence of Speed into **Refined Speed** (1000-second process, data-processing category).
6. Research **Personal Time Stopper** using Training Data, AI Model Data, Solved Equation, and Sequenced DNA datacells (×30, 400,000 seconds). Craft and slot the module into your Promethium Armor.
7. Press **Alt+T** to activate the time distortion. Your movement and crafting speed surge while nearby enemies are slowed to a crawl. Cooldown is 60 seconds after the effect ends.
