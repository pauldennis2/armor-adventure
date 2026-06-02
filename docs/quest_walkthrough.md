# Armor Adventure — Quest Walkthrough

*Author: Claude Sonnet 4.6*

> **TODO for author:** Review and edit this document before publishing. Verify all item names, quest step details, and companion mod sections against the current implementation. Add any missing steps, clarify any confusing phrasing, and decide how much to reveal in the "getting started" section.

This document describes every quest in explicit detail. If you want hints only, see [hints.md](hints.md).

---

## Getting Started

You need to reach **promethium science** in the base Space Age tech tree before anything here is accessible. Once you have promethium science packs, research **Armor Forging Station**. This unlocks the Armor Forging Station recipe and building.

In order to get the most out of the armor you will need to be able to craft high-quality versions of most of the equipment. If you don't have plenty of epic/legendary materials to craft with, it's better to work towards that first. Also, because of the high research costs involved, pursuing this tech is not recommended when you first unlock Research Prod. 

Build at least one Armor Forging Station. It is the crafting machine for almost all Promethium Armor components. It does not accept quality modules. If you want to craft a legendary armor, you will need legendary components.

There are five components crafted by various "quests" on the original planets of Nauvis, Fulgora, Vulcanus, Gleba, and Aquilo. All five must be completed to forge your armor. You can complete them in any order, and the components can be stored in your armor for convenient travel between planets. The AFS can also be "packed".

Note: Almost all planetary quests require or strongly encourage their components to be crafted on that planet with the player present. You cannot handle this challenge remotely.

---

## Nauvis: Biter Investigation

**Technology:** Nauvis Biter Investigation

**Unlocks:** Pheromone Emitter recipe

**Goal:** Collect a Gigantic Chitinous Shell

### Steps

1. Research **Nauvis Biter Investigation**.
2. Craft a **Pheromone Emitter** (Armor Forging Station recipe). Higher quality emitters attract a higher quality boss.
3. Place the Pheromone Emitter on Nauvis, somewhere you can defend.
4. On placement, waves of big and behemoth biters will attack. Defend the emitter for **60 seconds** and a **Gigantoid Spitter** will emerge.
5. Kill the Gigantoid and pick up the shell it drops - this will allow you to craft the **Ablative Chitocarbon Shell**.

---

## Vulcanus: Demolisher Anatomy Investigation

**Technology:** Vulcanus Demolisher Anatomy Investigation (all science packs + metallurgic, 10,000 units)

**Unlocks:** Split Demolisher Heart recipe, Compress Heart Fragments recipe, Promethium Armor Chassis recipe

**Goal:** Craft a Promethium Armor Chassis

### Steps


1. Go to Vulcanus and kill a **Big Demolisher**. You must be nearby to receive credit. Loot the heart.
2. Research **Vulcanus Demolisher Anatomy Investigation**.
3. Use the **Split Demolisher Heart** recipe to split it into **Large Demolisher Heart Fragments**.
5. Use the **Compress Heart Fragments** recipe to compress fragments into the refined form needed for the chassis.
6. Craft the **Promethium Armor Chassis** at the Armor Forging Station using the processed heart material and other components.

---

## Gleba: Pentapod Investigation

**Technology:** Gleba Pentapod Investigation

**Unlocks:** Harvester recipe, Neural Override Dart recipe, Bio Interface recipe

**Goal:** Craft a Bio Interface

### Steps

1. Research **Gleba Pentapod Investigation**.
2. Craft **Neural Override Darts** (unlocked by the research). These are fired from a regular rocket launcher or rocket turret.
3. Fire the darts at **enemy pentapods**. Successfully hit enemies will switch to follow the player, although they may wander a bit.
4. Build a **Harvester**. It automatically consumes any nearby mind-controlled enemies it finds, and converts their health into **Enemy Biomass** (1 biomass per 1000 HP consumed).
5. The Harvester further converts biomass to Pentapod Tissue Samples. Combine these with circuits to craft the **Bio Interface**.

---

## Fulgora: Climate Investigation

**Technology:** Fulgora Climate Investigation

**Unlocks:** Massive Lightning Funnel recipe, Superconducting Telemetry Core recipe

**Goal:** Craft a Superconducting Telemetry Core

### Steps

1. Research **Fulgora Climate Investigation**.
2. Craft a **Massive Lightning Funnel**. A high-quality funnel will work much better for this quest.
3. Place it on Fulgora **far from your base**. It draws in lightning from a wide area but does not connect to the power grid — the energy goes somewhere else. Having it near your base disrupts your power supply.
4. Wait for the funnel to accumulate 1 TJ (1,000,000,000,000 J) of energy from lightning strikes. When this threshold is reached, it converts the stored energy into a **Charged Lightning Gem** that drops on the ground nearby.
5. Craft a **Superconducting Telemetry Core** at the Armor Forging Station using the Charged Lightning Gem and other components.

---

## Aquilo: Signal Investigation

**Technology:** Aquilo Signal Investigation (all science packs + cryogenic, 10,000 units)

**Unlocks:** Thermodynamic Regulator recipe

This quest has three sub-phases.

### Phase 1: EM Scanning

1. Research **Aquilo Signal Investigation**.
2. Go to Aquilo and build powered **Radars** on the surface. The scanning scales with the number of radars scanning, and takes about 20 minutes with only one going.
3. When scanning is complete, an **Anomalous Signal Source** spawns within 60–80 tiles of your current position.
4. Loot the Anomalous Signal Source, which should trigger the **Signal Triangulation**.
5. Craft an **Aquilo Elevator Shaft** (Armor Forging Station recipe, requires concrete and steel among other things).
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
4. The cryovault contains a **Cryovault Access Card**. Pick it up, then insert it into the **Vault Card Reader** (the chest to the right of the cryovault). This triggers the **Cryo-core Acquired** technology.
5. The Cryo-core Acquired tech unlocks the **Cryovault Access Card** crafting recipe (so you can make quality cards) — but for now, the one from the chest is all you need.
6. Use the depot elevator to ascend back to Aquilo.
7. Craft a **Thermodynamic Regulator** at the Armor Forging Station using the Cryo Core and other components.

---

## Forging the Promethium Armor

Once all five investigations are complete (**Vulcanus**, **Gleba**, **Fulgora**, **Cryo-core Acquired**, **Nauvis Defense Complete**), the **Forge Promethium Armor** technology becomes available (all 12 science packs, 10,000 units). Researching it unlocks the Promethium Armor recipe and the Superconducting Telemetry Core crafting recipe.

Craft the **Promethium Armor** at the Armor Forging Station. You will need all five planetary components among the ingredients:
- Ablative Chitocarbon Shell (Nauvis)
- Promethium Armor Chassis (Vulcanus)
- Bio Interface (Gleba)
- Superconducting Telemetry Core (Fulgora)
- Thermodynamic Regulator (Aquilo)

---

## Planetary Mods

Some planet mods will offer additional content if they are installed. These quests will enable you to craft special equipment that can only be used in your new armor. Unless otherwise specified, these items are "unique-equipped" meaning you can only use one at a time. This additional content will only be available if the planet mods are enabled.

### Castra Prime - Personal Combat Roboport

Castra is a battlefield world. Enemy **data-collector bases** (destroyable buildings on Castra) fill a hidden meter when destroyed. Higher quality buildings contribute more points (1–5 per building). A warning fires at 30 points. At 50 points, a **SIMULAC Commander** spawns near you.

1. Go to Castra and destroy enemy data-collector bases. Watch for the warning message.
2. When the SIMULAC Commander spawns, destroy it. It is a tough enemy that moves toward you aggressively. The game prints a warning when it spawns.
3. When the Commander dies, it leaves **SIMULAC Core Remains**. Mine the remains — this triggers the **The Core Hunt** technology automatically.
4. Core Hunt unlocks the **SIMULAC Core** refinement recipe. Use this to refine the raw cores you find.
5. Once Core Hunt is researched, **Personal Combat Roboport** becomes visible in the tech tree. Research it using battlefield science packs and other packs. It unlocks three roboport module variants (Defender, Distractor, Destroyer). These are Promethium Armor only.

---

### Moshine - Personal Tesla Turret

To craft the "Vortex Data Card", you will need a specialized train setup. You will need to craft "Deosil Motion Data" (clockwise) and "Widdershins Motion Data" (counter-clockwise) simultaneously, as both items have a short spoil time and must be combined.

There are a number of ways you can achieve this; we'll describe the simplest. You should read all steps before getting started.

1. Research the **Personal Tesla Turret**.
2. Build a circular train loop. Place a locomotive and cargo wagon on it, load the cargo wagon with a **Magnet**, and start the train running. The train must reach a minimum speed to be tracked. In order to automate this, you will need to have two "flat" sections of the circle that can support train stops.
3. You will need to either construct your loops around one of the Moshine training data sources or add an elevated rail segment to allow data to be "piped in". 
4. Place a **Data Processor** inside the loop. Set the processor to either the **Deosil Motion Data Capture** and set the train to go in a clockwise loop.
5. If you have correctly set everything up, you will see "Scan tokens" appearing in the data processor.
6. Construct a larger loop around the first one with the same setup, but this time going counter-clockwise. Add a Data Processor for "Widdershins Data Capture". 
7. Add a third data processor to produce **Vortex Data Cards**.
8. Craft the equipment using the Vortex card and other items.

---

### Panglia - Personal Time Stopper

Panglia's surface has large **speed zones**  that grant movement speed while inside. These zones can be destroyed with atomic weapons.

1. Go to Panglia and locate a speed zone. The entire zone will be destroyed, so pick one you don't need.
2. Fire an **atomic rocket** into the zone. After the blast settles (about 5 seconds), **Speed Zone Residue** nodes appear. Mine them, which will trigger the **Time Fracking** technology. Note: Armor Adventure, Inc. cannot be held liable for death or injury from engineers standing too close to their own nuclear blasts.
3. "Plant" the essence of speed in a compute data farm. It will be processed into **Refined Speed**.
4. Research **Personal Time Stopper** and craft the item using Refined Speed and other components.
7. Press **Alt+T** to activate the time distortion. Your movement and crafting speed surge while nearby enemies are slowed to a crawl.
