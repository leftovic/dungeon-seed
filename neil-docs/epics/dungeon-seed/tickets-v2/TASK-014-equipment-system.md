# TASK-014: Equipment System (Equip/Unequip/Stat Calc)

---

## Section 1 · Header

| Field              | Value                                                                 |
|--------------------|-----------------------------------------------------------------------|
| **Task ID**        | TASK-014                                                              |
| **Title**          | Equipment System (Equip/Unequip/Stat Calculation)                    |
| **Priority**       | 🟡 P1 — Important (enables gear progression for adventurers)         |
| **Tier**           | Core Mechanic                                                         |
| **Complexity**     | 5 points (Moderate)                                                   |
| **Phase**          | Phase 3 — Domain Services                                             |
| **Wave**           | Wave 3 (depends on TASK-006, TASK-007)                                |
| **Stream**         | 🔴 MCH (Mechanics) — Primary                                          |
| **Cross-Stream**   | 🔵 VIS (equipment UI, paper doll), 🟣 NAR (item descriptions)        |
| **GDD Reference**  | GDD-v3.md §10 Items & Equipment, §6.4 Stat Definitions               |
| **Milestone**      | M3 — Playable Expedition Loop                                         |
| **Dependencies**   | TASK-006 (AdventurerData model), TASK-007 (ItemData model)            |
| **Critical Path**  | ❌ No — off critical path (enhances adventurer power curve)           |
| **Estimated Effort** | 4–6 hours for an experienced GDScript developer                      |
| **Assignee**       | Unassigned                                                            |

---

## Section 2 · Description

### 2.1 What This Feature IS

TASK-014 implements the **Equipment System** — the service layer that allows adventurers to equip weapons, armor, and accessories, and recalculates effective stats based on base stats + equipment bonuses. This is the progression layer that makes loot drops meaningful and gives players tangible power growth.

The deliverables are:

1. **EquipmentManager service** — a RefCounted domain service that manages equipping/unequipping items to adventurers, validates slot compatibility, and triggers stat recalculation.
2. **Slot-based equipment system** — each adventurer has 3 equipment slots:
   - **Weapon** (provides ATK bonuses, elemental damage, skill unlocks)
   - **Armor** (provides DEF/HP bonuses, elemental resistances)
   - **Accessory** (provides utility bonuses: SPD/PER/MP, special effects)
3. **Stat aggregation** — recalculates `AdventurerData.effective_stats` by summing:
   - Base stats (from class + level)
   - Equipment stat bonuses (flat + percentage modifiers)
   - Condition modifiers (Fatigued = −10%, Injured = −25%, Exhausted = −40%)
4. **Slot validation** — prevents equipping a Bow on a Warrior (weapon type restrictions), prevents equipping Heavy Armor on a Mage (armor type restrictions).
5. **Unequipping** — removes an item from a slot, returns it to inventory (future task), recalculates stats.
6. **EventBus integration** — emits `equipment_changed` when an adventurer's gear changes, triggering UI updates.

### 2.2 Player Experience Impact

This task enables **loot-driven progression** — the third pillar of the game loop (Plant → Explore → **Loot** → Upgrade → Repeat).

**Engagement delta:**
- **Tangible power growth**: Every equipment upgrade makes the adventurer visibly stronger. HP bar gets longer, ATK number gets bigger. Players *see* progress.
- **Build diversity**: A Warrior with a Flame Axe + Frost Armor plays differently than one with Terra Hammer + Heavy Plate. Equipment drives strategic variety.
- **Loot anticipation**: Opening a treasure chest after a hard boss creates anticipation: "Is this the Rare sword I need? Or another Common helm?"

**Session time impact:**
- **Quick equip** (15 seconds): "I just got a better sword — equip to my Warrior."
- **Deep optimization** (5–15 minutes): "Do I give the Frost Staff to my Mage for +25 ATK, or keep her current Arcane Tome for +15% MP regen? Let me run the numbers..."

**Retention impact:**
- Equipment creates **horizontal progression**. Even at max level, players chase better gear (Rare → Epic → Legendary).
- Equipment creates **goal clarity**: "I need 3 more boss kills to craft the Legendary Emberforged Axe."

### 2.3 Development Cost

| Metric                     | Target          |
|----------------------------|-----------------|
| Lines of production code   | 350–500         |
| Lines of test code         | 200–300         |
| New files created          | 2–3             |
| Existing files modified    | 2 (AdventurerData, EventBus) |
| Risk level                 | Medium (complex stat calculation logic) |

### 2.4 Technical Architecture

#### Class Diagram

```
┌─────────────────────────────────────────────────────────┐
│           EquipmentManager (RefCounted)                 │
│─────────────────────────────────────────────────────────│
│ (No instance state — all methods are static-like)      │
│─────────────────────────────────────────────────────────│
│ + equip_item(adv, item, slot) → Error                  │
│ + unequip_slot(adv, slot) → ItemData                   │
│ + get_equipped_item(adv, slot) → ItemData              │
│ + get_all_equipped(adv) → Dictionary                   │
│ + recalculate_stats(adv) → void                        │
│ + validate_equipment(adv, item, slot) → Error          │
└─────────────────────────────────────────────────────────┘
         │
         │ operates on
         ▼
┌─────────────────────────────────────────────────────────┐
│          AdventurerData (from TASK-006)                 │
│─────────────────────────────────────────────────────────│
│ + equipped_weapon: StringName (item_id)                │
│ + equipped_armor: StringName                           │
│ + equipped_accessory: StringName                       │
│ + stats: StatBlock (base stats)                        │
│ + effective_stats: StatBlock (base + equipment + cond) │
│ + condition: Enums.AdventurerCondition                  │
└─────────────────────────────────────────────────────────┘
         │
         │ references
         ▼
┌─────────────────────────────────────────────────────────┐
│            ItemData (from TASK-007)                     │
│─────────────────────────────────────────────────────────│
│ + id: StringName                                        │
│ + name: String                                          │
│ + item_type: Enums.ItemType                            │
│ + equipment_slot: Enums.EquipmentSlot                  │
│ + stat_bonuses: Dictionary (e.g., {"atk": 10, "hp": 25})│
│ + rarity: Enums.Rarity                                 │
│ + element: Enums.Element                               │
│ + restrictions: Array[Enums.ClassType] (who can equip) │
└─────────────────────────────────────────────────────────┘
```

#### Stat Calculation Flow

```
┌─────────────────────────────────────────────────────────┐
│          Player equips "Emberforged Axe"                │
│          (Weapon, ATK+15, Flame element)                │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  EquipmentManager.equip_item(warrior, axe, WEAPON)     │
│    1. Validate: Can Warrior equip axes? YES            │
│    2. Unequip current weapon (if any)                  │
│    3. Set warrior.equipped_weapon = "item_axe_001"     │
│    4. Call recalculate_stats(warrior)                  │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  EquipmentManager.recalculate_stats(warrior)            │
│    1. Start with base stats (from class + level)       │
│    2. Add weapon bonuses: ATK +15                      │
│    3. Add armor bonuses: (if equipped)                 │
│    4. Add accessory bonuses: (if equipped)             │
│    5. Apply condition modifier: Fatigued = ×0.9        │
│    6. Store in warrior.effective_stats                 │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│  EventBus.equipment_changed.emit(warrior_id, WEAPON)    │
│    → UI updates to show new ATK value                  │
│    → Combat system uses updated effective_stats        │
└─────────────────────────────────────────────────────────┘
```

### 2.5 System Interaction Map

```
┌──────────────────────┐         ┌──────────────────────┐
│ Inventory UI (future)│────────▶│ EquipmentManager     │
│ Player drags sword   │         │ .equip_item()        │
│ onto Warrior         │         │                      │
└──────────────────────┘         └──────────┬───────────┘
                                            │
                                            │ modifies
                                            ▼
                                 ┌──────────────────────┐
                                 │ AdventurerData       │
                                 │ .equipped_weapon     │
                                 │ .effective_stats     │
                                 └──────────┬───────────┘
                                            │
                                            │ emits
                                            ▼
┌──────────────────────┐         ┌──────────────────────┐
│ Character Sheet UI   │◀────────│ EventBus             │
│ Updates ATK display  │         │ .equipment_changed   │
└──────────────────────┘         └──────────────────────┘

┌──────────────────────┐         ┌──────────────────────┐
│ Expedition Resolver  │────────▶│ AdventurerData       │
│ Reads combat stats   │         │ .effective_stats     │
│ for damage calcs     │         │ (includes equipment) │
└──────────────────────┘         └──────────────────────┘
```

### 2.6 Constraints and Design Decisions

| # | Decision | Rationale | Trade-off |
|---|----------|-----------|-----------|
| 1 | **3 equipment slots only (Weapon/Armor/Accessory)** | MVP simplicity. Fewer slots = less UI complexity, less stat bloat. | Less granularity than full RPGs (no gloves, boots, rings, amulets separately). Post-MVP can expand. |
| 2 | **Equipment stored as item IDs, not item copies** | Single source of truth in Inventory (future). Equipment slots reference items, don't duplicate them. | Must dereference ID to get item data. Requires Inventory service to exist. For MVP, items are stored externally. |
| 3 | **Stat bonuses are additive, then conditional multipliers apply** | Formula: `effective = (base + equipment_flat) × condition_modifier`. Clear, predictable scaling. | Percentage bonuses from equipment would require `(base × equipment_%) × condition_modifier`. Deferred to post-MVP. |
| 4 | **Weapon type restrictions by class** | GDD §10: Warriors use swords/axes/hammers, Mages use staves/wands/tomes. Prevents nonsensical gear (Mage with greataxe). | Reduces flexibility. Mitigated by each class having 3+ compatible weapon types. |
| 5 | **Armor type restrictions by class** | Heavy armor for Warrior/Sentinel, Medium for Ranger/Alchemist, Light for Mage/Rogue. Reinforces class identity. | No "off-meta" builds like Mage in plate mail. Intentional design choice. |
| 6 | **Effective stats recalculated eagerly, not lazily** | Every equip/unequip triggers immediate recalc. Combat reads pre-computed `effective_stats`, not base stats. | Small performance cost on equip (negligible). Massive performance gain in combat (no per-attack recalc). |
| 7 | **Condition modifiers apply AFTER equipment** | Fatigued = 90% of (base + equipment). Equipment bonuses are also reduced by condition. | Harsh but fair: injuries reduce effectiveness uniformly. Encourages keeping adventurers Healthy. |
| 8 | **No "unbreakable" equipment durability in MVP** | Equipment never breaks, never needs repair. Simplifies economy and reduces player frustration. | Less realism. Mitigated by loot treadmill (replace gear with better drops, not repair degraded gear). |

---

## Section 3 · Use Cases

### UC-01: Kai the Speedrunner — Quick Gear Swap Before Expedition

**Archetype:** Kai just looted a Rare Frost Staff from a boss. He wants to immediately equip it to his Mage before the next dungeon run.

**Scenario:**
1. Kai's Mage (Lira) currently has an Uncommon Arcane Tome equipped (ATK +8).
2. He opens the inventory (future UI), clicks the Frost Staff, and drags it to Lira's Weapon slot.
3. The UI calls `EquipmentManager.equip_item(lira, frost_staff, WEAPON)`.
4. EquipmentManager validates: Is Lira a Mage? Yes. Can Mages equip staves? Yes. Validation passes.
5. EquipmentManager unequips the current Arcane Tome (returns it to inventory).
6. EquipmentManager sets `lira.equipped_weapon = &"item_staff_frost_rare_001"`.
7. EquipmentManager calls `recalculate_stats(lira)`:
   - Base ATK (level 10 Mage): 10 + 10×3 = 40
   - Frost Staff bonus: +15 ATK
   - Condition (Healthy): ×1.0
   - **Effective ATK = 55**
8. EventBus emits `equipment_changed.emit(lira.id, WEAPON)`.
9. Character sheet UI updates: "ATK: 40 → 55 (+15 from Frost Staff)".
10. Kai launches the expedition. Lira's spells now deal 37% more damage (55 vs 40 base).

**Success Criteria:** Equip completes in <100ms, stat update is visible in UI, combat uses new stats.

### UC-02: Luna the Completionist — Optimizing Stat Distribution

**Archetype:** Luna has 3 accessories and wants to decide which adventurer benefits most from each.

**Scenario:**
1. Luna has:
   - **Moonstone Ring** (PER +5, crit chance +2%)
   - **Fleet Boots** (SPD +10, evasion +3%)
   - **Scholar's Charm** (MP +20, skill cost −5%)
2. She has 3 adventurers in her party: Warrior (Kira), Ranger (Thane), Mage (Lira).
3. She opens a spreadsheet (or in-game comparison tool, future) and calculates:
   - Kira (Warrior): High HP, low PER. **Moonstone Ring** would increase her crit from 7% to 9%.
   - Thane (Ranger): Already high PER (14). **Fleet Boots** synergize with his hit-and-run playstyle.
   - Lira (Mage): Low MP regen, spends MP fast. **Scholar's Charm** extends her spell usage.
4. Luna equips each item:
   - `EquipmentManager.equip_item(kira, moonstone_ring, ACCESSORY)`
   - `EquipmentManager.equip_item(thane, fleet_boots, ACCESSORY)`
   - `EquipmentManager.equip_item(lira, scholars_charm, ACCESSORY)`
5. Each equip triggers `recalculate_stats()` and emits `equipment_changed`.
6. Luna reviews the party: Kira now has 9% crit, Thane has 24 SPD, Lira has 110 MP.
7. She feels confident this is the optimal setup and launches the expedition.

**Success Criteria:** All 3 equips succeed, stats update correctly, Luna can see effective stats in UI.

### UC-03: Sam the Casual Parent — Accidental Invalid Equip Attempt

**Archetype:** Sam tries to equip a Greatsword (Heavy weapon) to his Rogue (Light weapons only). The system prevents the invalid action.

**Scenario:**
1. Sam just looted a Rare Greatsword (Heavy weapon, Warriors/Sentinels only).
2. He tries to equip it to his Rogue (Shade) without reading the item restrictions.
3. UI calls `EquipmentManager.equip_item(shade, greatsword, WEAPON)`.
4. EquipmentManager validates:
   - Is Shade a Rogue? Yes.
   - Can Rogues equip Greatswords? **No** (Rogues use Daggers/Short Swords only).
   - Validation returns `ERR_INVALID_PARAMETER`.
5. The equip fails. The UI displays a tooltip: "Shade cannot equip Greatsword (Rogues use Daggers/Short Swords)."
6. Sam realizes the mistake, checks his inventory for daggers, finds a Common Dagger, equips that instead.
7. The dagger equips successfully. Sam continues playing.

**Success Criteria:** Invalid equip is rejected gracefully, clear error message, no crash, no corrupt state.

---

## Section 4 · Glossary

| Term | Definition |
|------|------------|
| **Equipment** | Items that can be equipped to adventurers to provide stat bonuses and special effects. Includes weapons, armor, and accessories. |
| **Equipment Slot** | One of 3 slots on an adventurer: Weapon, Armor, Accessory. Each slot can hold one item at a time. |
| **Weapon** | Equipment that provides ATK bonuses, elemental damage types, and sometimes skill unlocks. Equipped in the Weapon slot. |
| **Armor** | Equipment that provides DEF/HP bonuses and elemental resistances. Equipped in the Armor slot. |
| **Accessory** | Equipment that provides utility bonuses: SPD, PER, MP, crit chance, evasion, etc. Equipped in the Accessory slot. |
| **Stat Bonuses** | Numerical modifiers provided by equipment. Examples: ATK +15, HP +25, SPD +5. |
| **Base Stats** | The stats an adventurer has from class + level, before equipment or condition modifiers. Calculated in TASK-006. |
| **Effective Stats** | The final combat stats after applying: base stats + equipment bonuses + condition modifiers. Used in combat calculations. |
| **Condition Modifier** | A multiplier applied to effective stats based on adventurer condition. Healthy = ×1.0, Fatigued = ×0.9, Injured = ×0.75, Exhausted = ×0.6. |
| **Slot Validation** | The process of checking whether an item can be equipped to a specific slot on a specific adventurer (class restrictions, slot type matching). |
| **Weapon Type** | A category of weapons: Swords, Axes, Hammers, Bows, Crossbows, Staves, Wands, Tomes, Daggers, Short Swords, Shields, Maces. |
| **Armor Type** | A category of armor: Heavy (plate), Medium (chain/leather), Light (robes/cloth). Determines which classes can equip. |
| **Class Restrictions** | Rules defining which classes can equip which equipment types. E.g., Warriors can use swords/axes/hammers but not bows. |
| **EquipmentManager** | A RefCounted service class (not autoload, not Node) that provides static-like methods for equipping, unequipping, and stat calculation. |
| **ItemData** | A data class (from TASK-007) representing a single item/equipment with properties: name, type, slot, bonuses, rarity, element. |
| **StatBlock** | A data structure holding 6 stats: HP, MP, ATK, DEF, SPD, PER. Used for both base and effective stats. |
| **Equip** | The act of assigning an item to an adventurer's equipment slot, triggering stat recalculation. |
| **Unequip** | The act of removing an item from an adventurer's equipment slot, returning it to inventory (future), and recalculating stats without that item. |
| **EventBus.equipment_changed** | A signal emitted when an adventurer's equipment changes. Parameters: adventurer_id (StringName), slot (Enums.EquipmentSlot). |

---

## Section 5 · Out of Scope

- [ ] **OOS-001:** Inventory management system (where unequipped items are stored) — handled by future Inventory task.
- [ ] **OOS-002:** Equipment drops from combat — handled by TASK-011 (Loot Table Engine).
- [ ] **OOS-003:** Equipment crafting — handled by future Crafting task.
- [ ] **OOS-004:** Equipment upgrading/enhancement — post-MVP feature.
- [ ] **OOS-005:** Equipment set bonuses (equipping 3/5 pieces of a set grants bonus) — post-MVP.
- [ ] **OOS-006:** Equipment durability and repair — explicitly excluded from MVP per GDD design.
- [ ] **OOS-007:** Equipment visual appearance on adventurer sprites — handled by future sprite customization task.
- [ ] **OOS-008:** Equipment comparison tooltips (compare new item vs equipped) — UI feature, post-MVP.
- [ ] **OOS-009:** Equipment sorting/filtering in inventory UI — UI feature, TASK-020.
- [ ] **OOS-010:** Equipment quick-swap presets (save/load equipment loadouts) — QoL feature, post-MVP.
- [ ] **OOS-011:** Equipment transmogrification (change appearance while keeping stats) — cosmetic system, post-MVP.
- [ ] **OOS-012:** Equipment selling/salvaging for materials — economy feature, future task.
- [ ] **OOS-013:** Legendary equipment with unique active abilities — MVP has passive stat bonuses only.
- [ ] **OOS-014:** Equipment rarity visual effects (glowing Legendary items) — VFX task, post-MVP.
- [ ] **OOS-015:** Equipment binding (soulbound, account-bound) — not needed in single-player MVP.

---

## Section 6 · Functional Requirements

### FR Group 1: Equipment Core

- [ ] **FR-001:** `EquipmentManager` MUST be a RefCounted class (not Node, not autoload).
- [ ] **FR-002:** `EquipmentManager.equip_item(adventurer: AdventurerData, item: ItemData, slot: Enums.EquipmentSlot) -> Error` MUST:
  - Validate the item can be equipped to the slot on this adventurer (via `validate_equipment()`).
  - If validation fails, return an error code and do NOT modify state.
  - If the slot is already occupied, unequip the current item first.
  - Set the appropriate equipped slot property (`equipped_weapon`, `equipped_armor`, or `equipped_accessory`) to the item's ID.
  - Call `recalculate_stats(adventurer)`.
  - Emit `EventBus.equipment_changed.emit(adventurer.id, slot)`.
  - Return `OK`.
- [ ] **FR-003:** `EquipmentManager.unequip_slot(adventurer: AdventurerData, slot: Enums.EquipmentSlot) -> ItemData` MUST:
  - If the slot is empty (null ID), return null.
  - Get the ItemData for the currently equipped item (lookup from global item registry, future).
  - Set the slot property to null (clear the slot).
  - Call `recalculate_stats(adventurer)`.
  - Emit `EventBus.equipment_changed.emit(adventurer.id, slot)`.
  - Return the unequipped ItemData (for returning to inventory).
- [ ] **FR-004:** `EquipmentManager.get_equipped_item(adventurer: AdventurerData, slot: Enums.EquipmentSlot) -> ItemData` MUST:
  - Return the ItemData for the item in the specified slot, or null if slot is empty.
- [ ] **FR-005:** `EquipmentManager.get_all_equipped(adventurer: AdventurerData) -> Dictionary` MUST:
  - Return a Dictionary mapping slot enum to ItemData: `{WEAPON: item_data, ARMOR: item_data, ACCESSORY: item_data}`.
  - Slots with no equipment map to null.

### FR Group 2: Validation

- [ ] **FR-006:** `EquipmentManager.validate_equipment(adventurer: AdventurerData, item: ItemData, slot: Enums.EquipmentSlot) -> Error` MUST perform the following checks:
  - If `item.equipment_slot != slot`, return `ERR_INVALID_PARAMETER` (item doesn't go in this slot).
  - If `item.restrictions` (array of ClassTypes) is not empty AND `adventurer.class_type` is NOT in the array, return `ERR_UNAVAILABLE` (class cannot equip this item).
  - If `item.item_type == WEAPON` and `item.weapon_type` is not compatible with adventurer's class, return `ERR_UNAVAILABLE`.
  - If `item.item_type == ARMOR` and `item.armor_type` is not compatible with adventurer's class, return `ERR_UNAVAILABLE`.
  - If all checks pass, return `OK`.
- [ ] **FR-007:** Weapon type compatibility MUST follow these rules (from GDD §10):
  - **Warrior**: Can equip Swords, Axes, Hammers.
  - **Ranger**: Can equip Bows, Crossbows.
  - **Mage**: Can equip Staves, Wands, Tomes.
  - **Rogue**: Can equip Daggers, Short Swords.
  - **Alchemist**: Can equip Flasks, Slings.
  - **Sentinel**: Can equip Shields, Maces.
- [ ] **FR-008:** Armor type compatibility MUST follow these rules:
  - **Warrior, Sentinel**: Can equip Heavy armor.
  - **Ranger, Alchemist**: Can equip Medium armor.
  - **Mage, Rogue**: Can equip Light armor.
- [ ] **FR-009:** Accessories MUST have no class restrictions (all classes can equip any accessory).

### FR Group 3: Stat Calculation

- [ ] **FR-010:** `EquipmentManager.recalculate_stats(adventurer: AdventurerData) -> void` MUST:
  - Start with `adventurer.stats` (base stats from class + level).
  - For each equipped item (weapon, armor, accessory):
    - Add the item's `stat_bonuses` to a running total.
  - Apply condition modifier:
    - HEALTHY: ×1.0
    - FATIGUED: ×0.9
    - INJURED: ×0.75
    - EXHAUSTED: ×0.6
  - Store the result in `adventurer.effective_stats`.
- [ ] **FR-011:** Stat calculation formula MUST be:
  ```
  effective_stat = (base_stat + sum(equipment_bonuses)) × condition_modifier
  ```
- [ ] **FR-012:** The calculation MUST update all 6 stats: HP, MP, ATK, DEF, SPD, PER.
- [ ] **FR-013:** The calculation MUST be deterministic (same inputs always produce same output).
- [ ] **FR-014:** If an adventurer has no equipment, `effective_stats` MUST equal `base_stats × condition_modifier`.

### FR Group 4: Integration with AdventurerData

- [ ] **FR-015:** `AdventurerData` MUST have these properties (from TASK-006):
  - `equipped_weapon: StringName` (item ID or null)
  - `equipped_armor: StringName`
  - `equipped_accessory: StringName`
  - `stats: StatBlock` (base stats)
  - `effective_stats: StatBlock` (computed stats)
- [ ] **FR-016:** When an item is equipped, the slot property MUST store the item's `id` (StringName), not the item object.
- [ ] **FR-017:** When an item is unequipped, the slot property MUST be set to an empty StringName `&""` or null.

### FR Group 5: EventBus Integration

- [ ] **FR-018:** EventBus MUST have a signal: `equipment_changed(adventurer_id: StringName, slot: Enums.EquipmentSlot)`.
- [ ] **FR-019:** `equip_item()` MUST emit `equipment_changed` after successful equip.
- [ ] **FR-020:** `unequip_slot()` MUST emit `equipment_changed` after successful unequip.
- [ ] **FR-021:** The signal MUST NOT be emitted if equip/unequip fails (validation error).

---

## Section 13 · Acceptance Criteria

### AC Group 1: Equip Functionality

- [ ] **AC-001:** `EquipmentManager` class exists at `res://src/services/equipment_manager.gd` and extends `RefCounted`.
- [ ] **AC-002:** Equipping a valid Sword to a Warrior's WEAPON slot returns `OK`.
- [ ] **AC-003:** Equipping a valid Sword updates `warrior.equipped_weapon` to the sword's ID.
- [ ] **AC-004:** Equipping a valid Sword triggers `recalculate_stats()` and updates `effective_stats.atk`.
- [ ] **AC-005:** Equipping a Sword to a WEAPON slot that already has a Sword unequips the old one first.
- [ ] **AC-006:** Equipping a Bow to a Warrior's WEAPON slot returns `ERR_UNAVAILABLE` (Warriors cannot use Bows).
- [ ] **AC-007:** Equipping an Armor item to a WEAPON slot returns `ERR_INVALID_PARAMETER` (wrong slot).
- [ ] **AC-008:** `equip_item()` emits `EventBus.equipment_changed` on success.
- [ ] **AC-009:** `equip_item()` does NOT emit `equipment_changed` on failure.

### AC Group 2: Unequip Functionality

- [ ] **AC-010:** Unequipping a WEAPON slot that has a Sword equipped returns the Sword's ItemData.
- [ ] **AC-011:** Unequipping a WEAPON slot clears `adventurer.equipped_weapon` to null or `&""`.
- [ ] **AC-012:** Unequipping triggers `recalculate_stats()` and removes the weapon's stat bonuses.
- [ ] **AC-013:** Unequipping an empty slot returns null.
- [ ] **AC-014:** `unequip_slot()` emits `EventBus.equipment_changed`.

### AC Group 3: Stat Calculation

- [ ] **AC-015:** A level 1 Warrior with base ATK=15 equipping a Sword (ATK+10) has `effective_stats.atk = 25` (Healthy condition).
- [ ] **AC-016:** A level 1 Warrior with base ATK=15, equipped Sword (ATK+10), and FATIGUED condition has `effective_stats.atk = 22.5` (25 × 0.9).
- [ ] **AC-017:** A level 1 Warrior with base ATK=15, equipped Sword (ATK+10), and INJURED condition has `effective_stats.atk = 18.75` (25 × 0.75).
- [ ] **AC-018:** Equipping armor with HP+25 increases `effective_stats.hp` by 25 (before condition modifier).
- [ ] **AC-019:** Equipping an accessory with SPD+5 increases `effective_stats.spd` by 5.
- [ ] **AC-020:** Equipping 3 items (weapon, armor, accessory) applies all stat bonuses cumulatively.

### AC Group 4: Validation

- [ ] **AC-021:** A Warrior can equip a Sword (validation passes).
- [ ] **AC-022:** A Warrior cannot equip a Bow (validation fails with ERR_UNAVAILABLE).
- [ ] **AC-023:** A Mage can equip a Staff (validation passes).
- [ ] **AC-024:** A Mage cannot equip an Axe (validation fails).
- [ ] **AC-025:** A Warrior can equip Heavy armor (validation passes).
- [ ] **AC-026:** A Mage cannot equip Heavy armor (validation fails).
- [ ] **AC-027:** All classes can equip any accessory (validation always passes for accessories).
- [ ] **AC-028:** Equipping an Armor item to a WEAPON slot fails (slot type mismatch).

### Playtesting Acceptance Criteria (PACs)

- [ ] **PAC-001:** Equip a Rare Sword to a Warrior — ATK increases visibly in character sheet.
- [ ] **PAC-002:** Unequip the Sword — ATK returns to base value.
- [ ] **PAC-003:** Equip weapon + armor + accessory to one adventurer — all 3 stat bonuses apply.
- [ ] **PAC-004:** Try to equip a Bow to a Warrior — UI shows error message, equip fails.
- [ ] **PAC-005:** Save game with equipped items, reload — equipment is preserved, stats match.

---

## Section 14 · Testing Requirements

```gdscript
## Unit tests for EquipmentManager service.
extends GutTest

var eq_mgr: EquipmentManager
var warrior: AdventurerData
var sword: ItemData


func before_each() -> void:
	eq_mgr = EquipmentManager.new()
	warrior = AdventurerData.new()
	warrior.id = &"test_warrior"
	warrior.class_type = Enums.ClassType.WARRIOR
	warrior.level = 1
	warrior.condition = Enums.AdventurerCondition.HEALTHY
	warrior.stats = StatBlock.new()
	warrior.stats.atk = 15  # Base ATK
	warrior.effective_stats = StatBlock.new()
	
	sword = ItemData.new()
	sword.id = &"test_sword"
	sword.item_type = Enums.ItemType.WEAPON
	sword.equipment_slot = Enums.EquipmentSlot.WEAPON
	sword.weapon_type = Enums.WeaponType.SWORD
	sword.stat_bonuses = {"atk": 10}


func test_equip_valid_weapon_returns_ok() -> void:
	var result = eq_mgr.equip_item(warrior, sword, Enums.EquipmentSlot.WEAPON)
	assert_eq(result, OK, "Equip valid weapon must return OK")


func test_equip_sets_equipped_slot() -> void:
	eq_mgr.equip_item(warrior, sword, Enums.EquipmentSlot.WEAPON)
	assert_eq(warrior.equipped_weapon, sword.id, "Equipped weapon must be set")


func test_equip_recalculates_stats() -> void:
	eq_mgr.equip_item(warrior, sword, Enums.EquipmentSlot.WEAPON)
	assert_eq(warrior.effective_stats.atk, 25, "ATK must be base(15) + sword(10)")


func test_equip_emits_signal() -> void:
	watch_signals(EventBus)
	eq_mgr.equip_item(warrior, sword, Enums.EquipmentSlot.WEAPON)
	assert_signal_emitted(EventBus, "equipment_changed")


func test_unequip_clears_slot() -> void:
	eq_mgr.equip_item(warrior, sword, Enums.EquipmentSlot.WEAPON)
	eq_mgr.unequip_slot(warrior, Enums.EquipmentSlot.WEAPON)
	assert_eq(warrior.equipped_weapon, &"", "Unequip must clear slot")


func test_unequip_recalculates_stats() -> void:
	eq_mgr.equip_item(warrior, sword, Enums.EquipmentSlot.WEAPON)
	eq_mgr.unequip_slot(warrior, Enums.EquipmentSlot.WEAPON)
	assert_eq(warrior.effective_stats.atk, 15, "ATK must return to base after unequip")


func test_condition_modifier_fatigued() -> void:
	warrior.condition = Enums.AdventurerCondition.FATIGUED
	eq_mgr.equip_item(warrior, sword, Enums.EquipmentSlot.WEAPON)
	# Base 15 + Sword 10 = 25, then × 0.9 = 22.5
	assert_almost_eq(warrior.effective_stats.atk, 22.5, 0.1, "Fatigued must apply 0.9 modifier")
```

---

## Section 16 · Implementation Prompt

```gdscript
## EquipmentManager service — handles equipping/unequipping items and stat recalculation.
class_name EquipmentManager
extends RefCounted

## Equips an item to an adventurer's slot. Returns OK on success, error code on failure.
func equip_item(adventurer: AdventurerData, item: ItemData, slot: Enums.EquipmentSlot) -> Error:
	var validation_result := validate_equipment(adventurer, item, slot)
	if validation_result != OK:
		return validation_result
	
	# Unequip current item if slot occupied
	if _get_slot_value(adventurer, slot) != &"":
		unequip_slot(adventurer, slot)
	
	# Set slot
	_set_slot_value(adventurer, slot, item.id)
	
	# Recalculate stats
	recalculate_stats(adventurer)
	
	# Emit signal
	EventBus.equipment_changed.emit(adventurer.id, slot)
	
	return OK


## Unequips an item from a slot. Returns the ItemData (for inventory return).
func unequip_slot(adventurer: AdventurerData, slot: Enums.EquipmentSlot) -> ItemData:
	var item_id := _get_slot_value(adventurer, slot)
	if item_id == &"":
		return null
	
	# TODO: Get ItemData from global item registry (future task)
	var item_data: ItemData = null  # Placeholder
	
	# Clear slot
	_set_slot_value(adventurer, slot, &"")
	
	# Recalculate stats
	recalculate_stats(adventurer)
	
	# Emit signal
	EventBus.equipment_changed.emit(adventurer.id, slot)
	
	return item_data


## Validates whether an item can be equipped to a slot on this adventurer.
func validate_equipment(adventurer: AdventurerData, item: ItemData, slot: Enums.EquipmentSlot) -> Error:
	# Check slot type matches
	if item.equipment_slot != slot:
		return ERR_INVALID_PARAMETER
	
	# Check class restrictions
	if not item.restrictions.is_empty() and not adventurer.class_type in item.restrictions:
		return ERR_UNAVAILABLE
	
	# Check weapon type compatibility
	if item.item_type == Enums.ItemType.WEAPON:
		if not _can_equip_weapon_type(adventurer.class_type, item.weapon_type):
			return ERR_UNAVAILABLE
	
	# Check armor type compatibility
	if item.item_type == Enums.ItemType.ARMOR:
		if not _can_equip_armor_type(adventurer.class_type, item.armor_type):
			return ERR_UNAVAILABLE
	
	return OK


## Recalculates effective stats from base stats + equipment + condition.
func recalculate_stats(adventurer: AdventurerData) -> void:
	var effective := StatBlock.new()
	effective.hp = adventurer.stats.hp
	effective.mp = adventurer.stats.mp
	effective.atk = adventurer.stats.atk
	effective.def = adventurer.stats.def
	effective.spd = adventurer.stats.spd
	effective.per = adventurer.stats.per
	
	# Add equipment bonuses
	for slot in [Enums.EquipmentSlot.WEAPON, Enums.EquipmentSlot.ARMOR, Enums.EquipmentSlot.ACCESSORY]:
		var item_id := _get_slot_value(adventurer, slot)
		if item_id != &"":
			# TODO: Get ItemData from registry
			# var item := GameManager.item_registry.get_item(item_id)
			# for stat_name in item.stat_bonuses.keys():
			#     effective[stat_name] += item.stat_bonuses[stat_name]
			pass
	
	# Apply condition modifier
	var modifier := _get_condition_modifier(adventurer.condition)
	effective.hp = int(effective.hp * modifier)
	effective.mp = int(effective.mp * modifier)
	effective.atk = int(effective.atk * modifier)
	effective.def = int(effective.def * modifier)
	effective.spd = int(effective.spd * modifier)
	effective.per = int(effective.per * modifier)
	
	adventurer.effective_stats = effective


func _get_condition_modifier(condition: Enums.AdventurerCondition) -> float:
	match condition:
		Enums.AdventurerCondition.HEALTHY: return 1.0
		Enums.AdventurerCondition.FATIGUED: return 0.9
		Enums.AdventurerCondition.INJURED: return 0.75
		Enums.AdventurerCondition.EXHAUSTED: return 0.6
		_: return 1.0


func _can_equip_weapon_type(class_type: Enums.ClassType, weapon_type: Enums.WeaponType) -> bool:
	match class_type:
		Enums.ClassType.WARRIOR: return weapon_type in [Enums.WeaponType.SWORD, Enums.WeaponType.AXE, Enums.WeaponType.HAMMER]
		Enums.ClassType.RANGER: return weapon_type in [Enums.WeaponType.BOW, Enums.WeaponType.CROSSBOW]
		Enums.ClassType.MAGE: return weapon_type in [Enums.WeaponType.STAFF, Enums.WeaponType.WAND, Enums.WeaponType.TOME]
		Enums.ClassType.ROGUE: return weapon_type in [Enums.WeaponType.DAGGER, Enums.WeaponType.SHORT_SWORD]
		Enums.ClassType.ALCHEMIST: return weapon_type in [Enums.WeaponType.FLASK, Enums.WeaponType.SLING]
		Enums.ClassType.SENTINEL: return weapon_type in [Enums.WeaponType.SHIELD, Enums.WeaponType.MACE]
		_: return false


func _can_equip_armor_type(class_type: Enums.ClassType, armor_type: Enums.ArmorType) -> bool:
	match class_type:
		Enums.ClassType.WARRIOR, Enums.ClassType.SENTINEL: return armor_type == Enums.ArmorType.HEAVY
		Enums.ClassType.RANGER, Enums.ClassType.ALCHEMIST: return armor_type == Enums.ArmorType.MEDIUM
		Enums.ClassType.MAGE, Enums.ClassType.ROGUE: return armor_type == Enums.ArmorType.LIGHT
		_: return false


func _get_slot_value(adventurer: AdventurerData, slot: Enums.EquipmentSlot) -> StringName:
	match slot:
		Enums.EquipmentSlot.WEAPON: return adventurer.equipped_weapon
		Enums.EquipmentSlot.ARMOR: return adventurer.equipped_armor
		Enums.EquipmentSlot.ACCESSORY: return adventurer.equipped_accessory
		_: return &""


func _set_slot_value(adventurer: AdventurerData, slot: Enums.EquipmentSlot, value: StringName) -> void:
	match slot:
		Enums.EquipmentSlot.WEAPON: adventurer.equipped_weapon = value
		Enums.EquipmentSlot.ARMOR: adventurer.equipped_armor = value
		Enums.EquipmentSlot.ACCESSORY: adventurer.equipped_accessory = value
```

