# TASK-007: Item, Equipment & Inventory Data Models

| Field               | Value                                                        |
|---------------------|--------------------------------------------------------------|
| **Task ID**         | TASK-007                                                     |
| **Title**           | Item, Equipment & Inventory Data Models                      |
| **Epic**            | Dungeon Seed                                                 |
| **Engine**          | Godot 4.6 — GDScript                                        |
| **Complexity**      | 5 points (Moderate)                                          |
| **Wave**            | 2                                                            |
| **Dependencies**    | TASK-003 (Core Enums & Constants)                            |
| **Dependents**      | TASK-011 (Loot Table Engine), TASK-014 (Equipment System)    |
| **Critical Path**   | ❌ No                                                        |
| **Stream (Primary)**| 🔴 MCH — Mechanics                                          |
| **Cross-Streams**   | 🔵 VIS (item icons, rarity colors), 🟣 NAR (item descriptions/lore), ⚪ TCH (serialization) |
| **Status**          | 📋 Ready for Implementation                                 |
| **Created**         | 2025-07-10                                                   |
| **Author**          | Game Ticket Writer Agent                                     |

---

## 1. Header

**Summary:** Implement three foundational data models — `ItemData`, `ItemDatabase`, and `InventoryData` — that together form the complete item/equipment/inventory data layer for Dungeon Seed. These pure-data RefCounted classes define what items exist in the game world, how they are catalogued for lookup, and how player-owned quantities are tracked. All three models live in `src/models/`, depend exclusively on TASK-003 enums (`Enums.ItemRarity`, `Enums.EquipSlot`, `Enums.Currency`), and expose serialization methods (`to_dict()` / `from_dict()`) for save/load integration.

**Why this matters:** Every downstream system that touches loot, shops, crafting, rewards, or equipment depends on a stable, well-typed item data layer. Without TASK-007, TASK-011 (Loot Table Engine) cannot reference item definitions, TASK-014 (Equipment System) cannot resolve stat bonuses, and the save system cannot persist player inventories. This ticket is the single source of truth for "what is an item?" across the entire project.

**Deliverables:**
- `src/models/item_data.gd` — Single item definition (class_name `ItemData`)
- `src/models/item_database.gd` — Static registry of all item definitions (class_name `ItemDatabase`)
- `src/models/inventory_data.gd` — Player inventory with quantity tracking (class_name `InventoryData`)
- `tests/models/test_item_data.gd` — GUT test suite for `ItemData`
- `tests/models/test_item_database.gd` — GUT test suite for `ItemDatabase`
- `tests/models/test_inventory_data.gd` — GUT test suite for `InventoryData`

---

## 2. Description

### 2.1 Context & Motivation

Dungeon Seed is a dungeon-management roguelite where players cultivate sentient dungeon seeds, grow rooms, and harvest loot. The economy revolves around five currency types (Gold, Essence, Fragments, Artifacts, Tokens) and five rarity tiers (Common, Uncommon, Rare, Epic, Legendary). Equipment slots — Weapon, Armor, and Accessory — allow adventurers and player-controlled heroes to power up through gear progression.

Before any loot table can roll drops, before any shop can list merchandise, before any equipment screen can render stat bonuses, the game needs a clean, authoritative data layer that answers three questions:

1. **What is an item?** — `ItemData` holds the immutable definition of a single item: its id, display name, rarity, equip slot, stat bonuses, sell value, and flavor text.
2. **Where do I find all items?** — `ItemDatabase` is the static registry that indexes every item definition and supports filtered queries by rarity, slot, or arbitrary predicate.
3. **How many items does the player own?** — `InventoryData` is the mutable container that tracks item quantities, supports add/remove/query operations, and serializes for save/load.

These three classes are intentionally simple — they hold data and expose accessors, nothing more. They contain no UI logic, no signals (beyond what downstream consumers emit), no Node dependencies, and no file-system access. This purity makes them trivially testable and safe to reference from any thread or context.

### 2.2 Model: ItemData

`ItemData` is a RefCounted resource that represents a single item definition. It is immutable after construction — fields are set once via the constructor or `from_dict()` and never mutated at runtime. This immutability guarantee allows `ItemDatabase` to hand out direct references without defensive copies.

**Fields:**

| Field            | Type                    | Description                                                                                     |
|------------------|-------------------------|-------------------------------------------------------------------------------------------------|
| `id`             | `String`                | Unique snake_case identifier, e.g. `"iron_sword"`, `"leather_helm"`, `"ruby_ring"`              |
| `display_name`   | `String`                | Human-readable name shown in UI, e.g. `"Iron Sword"`, `"Leather Helm"`                         |
| `rarity`         | `Enums.ItemRarity`      | One of COMMON, UNCOMMON, RARE, EPIC, LEGENDARY                                                 |
| `slot`           | `Enums.EquipSlot`       | One of WEAPON, ARMOR, ACCESSORY, or -1 (NONE) if not equippable                                |
| `is_equippable`  | `bool`                  | Convenience flag — `true` when `slot != Enums.EquipSlot.NONE`                                  |
| `stat_bonuses`   | `Dictionary`            | Stat key → int value map, e.g. `{ "attack": 5, "defense": 3 }`                                 |
| `sell_value`     | `Dictionary`            | Currency enum → int amount, e.g. `{ Enums.Currency.GOLD: 10 }`                                 |
| `description`    | `String`                | Flavor text / lore description                                                                  |

**Key behaviors:**
- Constructor accepts a Dictionary with all fields and performs validation.
- `to_dict() -> Dictionary` serializes all fields to a plain Dictionary for JSON/save.
- `from_dict(data: Dictionary) -> ItemData` is a static factory that reconstructs from serialized form.
- `get_stat_bonus(stat_name: String) -> int` returns the bonus for a specific stat, defaulting to 0.
- `get_sell_value(currency: Enums.Currency) -> int` returns the sell value in a specific currency, defaulting to 0.
- `get_rarity_color() -> Color` returns the rarity color from `GameConfig.RARITY_COLORS`.

### 2.3 Model: ItemDatabase

`ItemDatabase` is a RefCounted singleton-pattern class that holds a Dictionary of `ItemData` instances keyed by item id. It is the authoritative registry — any system that needs an item definition queries the database rather than constructing `ItemData` directly.

**Responsibilities:**
- Load item definitions from a Dictionary literal (hardcoded starter items) or from a JSON file path.
- Index items by id for O(1) lookup.
- Provide filtered query methods that return typed arrays.
- Pre-populate with approximately 20 starter items spanning all rarity tiers and equipment slots.

**Starter Item Categories (≈20 items):**

*Weapons (7):*
- `wooden_sword` — Common, ATK +2
- `iron_sword` — Uncommon, ATK +5
- `steel_blade` — Rare, ATK +9, CRIT +2
- `crystal_saber` — Epic, ATK +14, CRIT +5, SPEED +2
- `wooden_staff` — Common, ATK +1, MAGIC +3
- `iron_staff` — Uncommon, ATK +2, MAGIC +6
- `arcane_rod` — Rare, MAGIC +12, CRIT +3

*Armor (7):*
- `cloth_tunic` — Common, DEF +2
- `leather_vest` — Uncommon, DEF +5
- `chainmail` — Rare, DEF +10, HP +15
- `dragon_plate` — Epic, DEF +18, HP +30, SPEED -3
- `cloth_robe` — Common, DEF +1, MAGIC_DEF +3
- `silk_robe` — Uncommon, DEF +2, MAGIC_DEF +6
- `enchanted_mail` — Rare, DEF +8, MAGIC_DEF +8, HP +10

*Accessories (6):*
- `copper_ring` — Common, HP +5
- `silver_ring` — Uncommon, HP +12, MAGIC_DEF +2
- `ruby_amulet` — Rare, ATK +4, CRIT +5
- `sapphire_pendant` — Rare, MAGIC +6, MAGIC_DEF +4
- `emerald_brooch` — Epic, HP +25, DEF +5, MAGIC_DEF +5
- `obsidian_charm` — Legendary, ATK +8, MAGIC +8, CRIT +8, SPEED +5

**API:**
- `get_item(id: String) -> ItemData` — Returns the item or `null` if not found.
- `has_item(id: String) -> bool` — Check existence without retrieval.
- `get_items_by_rarity(rarity: Enums.ItemRarity) -> Array[ItemData]` — All items of a given rarity.
- `get_items_by_slot(slot: Enums.EquipSlot) -> Array[ItemData]` — All items that equip to a slot.
- `get_equippable_items() -> Array[ItemData]` — All items where `is_equippable == true`.
- `get_all_items() -> Array[ItemData]` — Every registered item.
- `get_item_count() -> int` — Total number of registered items.
- `register_item(item: ItemData) -> void` — Add a new item definition at runtime (for mods/DLC).
- `load_from_dict(data: Dictionary) -> void` — Bulk-load item definitions from a Dictionary.

### 2.4 Model: InventoryData

`InventoryData` is a mutable RefCounted container that maps item ids to owned quantities. It is the runtime representation of "what the player has in their bag."

**Fields:**

| Field   | Type         | Description                                   |
|---------|--------------|-----------------------------------------------|
| `items` | `Dictionary` | `{ item_id: String -> quantity: int }` mapping |

**API:**
- `add_item(item_id: String, qty: int) -> void` — Adds quantity. Creates entry if absent. Asserts `qty > 0`.
- `remove_item(item_id: String, qty: int) -> bool` — Removes quantity. Returns `false` if insufficient. Removes key when quantity reaches zero.
- `has_item(item_id: String, qty: int) -> bool` — Returns `true` if owned quantity >= requested.
- `get_quantity(item_id: String) -> int` — Returns current quantity, 0 if not owned.
- `list_all() -> Array[Dictionary]` — Returns `[{ "item_id": id, "qty": n }, ...]` for every owned item.
- `get_unique_item_count() -> int` — Number of distinct item ids owned.
- `get_total_item_count() -> int` — Sum of all quantities.
- `clear() -> void` — Removes all items.
- `to_dict() -> Dictionary` — Serializes to `{ "items": { id: qty, ... } }`.
- `from_dict(data: Dictionary) -> void` — Restores from serialized form. Clears existing data first.
- `merge(other: InventoryData) -> void` — Combines another inventory into this one (additive).

### 2.5 Serialization Contract

All three models support `to_dict()` / `from_dict()` for JSON-compatible serialization. The contract guarantees:

- `to_dict()` returns a plain `Dictionary` containing only primitive types (String, int, float, bool) and nested Dictionaries/Arrays of primitives. No Godot objects, no Resources, no Nodes.
- `from_dict()` accepts the exact output of `to_dict()` and perfectly reconstructs the object state.
- Round-trip identity: for any valid object `x`, `Type.new().from_dict(x.to_dict())` produces an equivalent object.
- Invalid or missing keys in `from_dict()` input produce sensible defaults rather than crashes.

### 2.6 Enum Dependencies (from TASK-003)

This ticket assumes the following enums exist in `src/core/enums.gd`:

```gdscript
class_name Enums

enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum EquipSlot { NONE = -1, WEAPON = 0, ARMOR = 1, ACCESSORY = 2 }
enum Currency { GOLD, ESSENCE, FRAGMENTS, ARTIFACTS, TOKENS }
```

And the following constant in `src/core/game_config.gd`:

```gdscript
class_name GameConfig

const RARITY_COLORS: Dictionary = {
    Enums.ItemRarity.COMMON: Color(0.78, 0.78, 0.78),
    Enums.ItemRarity.UNCOMMON: Color(0.18, 0.80, 0.25),
    Enums.ItemRarity.RARE: Color(0.25, 0.52, 0.96),
    Enums.ItemRarity.EPIC: Color(0.66, 0.27, 0.86),
    Enums.ItemRarity.LEGENDARY: Color(1.0, 0.64, 0.0),
}
```

### 2.7 File Layout

```
src/
  models/
    item_data.gd          # ItemData — single item definition
    item_database.gd      # ItemDatabase — static registry
    inventory_data.gd     # InventoryData — player inventory
tests/
  models/
    test_item_data.gd     # GUT tests for ItemData
    test_item_database.gd # GUT tests for ItemDatabase
    test_inventory_data.gd# GUT tests for InventoryData
```

### 2.8 Integration Points

| Consumer System          | What It Reads                                 | TASK     |
|--------------------------|-----------------------------------------------|----------|
| Loot Table Engine        | `ItemDatabase.get_items_by_rarity()`          | TASK-011 |
| Equipment System         | `ItemData.stat_bonuses`, `ItemData.slot`      | TASK-014 |
| Shop / Merchant UI       | `ItemData.sell_value`, `ItemData.display_name` | Future   |
| Save/Load System         | `InventoryData.to_dict()` / `from_dict()`     | Future   |
| Tooltip / UI Renderer    | `ItemData.get_rarity_color()`, `description`  | Future   |
| Crafting System          | `InventoryData.has_item()`, `remove_item()`   | Future   |

---

## 3. Use Cases

### UC-01: Adventurer Loots a Chest After Clearing a Room

**Actor:** Player (via Loot Table Engine)
**Precondition:** Player's adventurer has defeated all enemies in a dungeon room. The loot table has rolled a drop list.
**Flow:**
1. Loot Table Engine calls `ItemDatabase.get_items_by_rarity(Enums.ItemRarity.UNCOMMON)` to get the candidate pool for this dungeon tier.
2. Engine selects `"iron_sword"` from the filtered array based on weighted random roll.
3. Engine calls `ItemDatabase.get_item("iron_sword")` to retrieve the full `ItemData` definition.
4. Engine calls `player_inventory.add_item("iron_sword", 1)` to deposit the item.
5. UI reads `item.display_name`, `item.rarity`, and `item.get_rarity_color()` to render the loot popup.
6. Player sees: **"Iron Sword"** (green/Uncommon) — ATK +5 — added to inventory.
**Postcondition:** `player_inventory.get_quantity("iron_sword")` returns previous value + 1.

### UC-02: Player Sells Items to a Merchant

**Actor:** Player (via Shop UI)
**Precondition:** Player has at least 3 `"copper_ring"` in their inventory and opens the shop.
**Flow:**
1. Shop UI calls `player_inventory.list_all()` to populate the sell panel.
2. For each entry, Shop UI calls `ItemDatabase.get_item(entry.item_id)` to get display data.
3. Player selects `"copper_ring"` and sets sell quantity to 2.
4. Shop UI calls `item_data.get_sell_value(Enums.Currency.GOLD)` to calculate payment (e.g., 3 Gold × 2 = 6 Gold).
5. Shop UI calls `player_inventory.has_item("copper_ring", 2)` to verify stock — returns `true`.
6. Shop UI calls `player_inventory.remove_item("copper_ring", 2)` — returns `true`.
7. Player's gold increases by 6. Inventory now shows 1 remaining copper ring.
**Postcondition:** `player_inventory.get_quantity("copper_ring")` returns 1.

### UC-03: Equipment System Resolves Stat Bonuses

**Actor:** Equipment System (TASK-014)
**Precondition:** Player equips `"crystal_saber"` into the WEAPON slot.
**Flow:**
1. Equipment System calls `ItemDatabase.get_item("crystal_saber")` to retrieve definition.
2. System checks `item.is_equippable` — returns `true`.
3. System checks `item.slot == Enums.EquipSlot.WEAPON` — returns `true` (matches target slot).
4. System reads `item.stat_bonuses` — `{ "attack": 14, "crit": 5, "speed": 2 }`.
5. System iterates each bonus and adds to character's computed stats.
6. Character sheet UI updates to show new ATK, CRIT, SPEED values.
**Postcondition:** Character's attack increased by 14, crit by 5, speed by 2.

### UC-04: Save System Persists Player Inventory

**Actor:** Save System (future task)
**Precondition:** Player has accumulated various items during a play session.
**Flow:**
1. Save System calls `player_inventory.to_dict()` which returns `{ "items": { "iron_sword": 1, "copper_ring": 3, "leather_vest": 1 } }`.
2. Save System writes this dictionary into the save file JSON blob.
3. On load, Save System reads the dictionary and calls `player_inventory.from_dict(saved_data)`.
4. `from_dict()` clears any existing inventory state, then repopulates from the saved dictionary.
5. `player_inventory.get_quantity("iron_sword")` returns 1 — state perfectly restored.
**Postcondition:** Inventory state is identical to the moment of save.

### UC-05: Designer Adds a New Item to the Database

**Actor:** Game Designer (via item_database.gd)
**Precondition:** Designer wants to add a new Legendary weapon.
**Flow:**
1. Designer opens `item_database.gd` and adds a new entry to the `_STARTER_ITEMS` dictionary.
2. Entry includes: `"void_blade": { "display_name": "Void Blade", "rarity": Enums.ItemRarity.LEGENDARY, "slot": Enums.EquipSlot.WEAPON, "stat_bonuses": { "attack": 22, "crit": 10, "speed": 5 }, "sell_value": { Enums.Currency.GOLD: 500, Enums.Currency.ARTIFACTS: 2 }, "description": "Forged from the abyss between dungeon floors." }`
3. On next run, `ItemDatabase` loads the new item and it becomes queryable.
4. `get_items_by_rarity(LEGENDARY)` now includes Void Blade.
**Postcondition:** New item is available to all downstream systems without code changes outside the data definition.

---

## 4. Glossary

| #  | Term                    | Definition                                                                                                           |
|----|-------------------------|----------------------------------------------------------------------------------------------------------------------|
| 1  | **ItemData**            | A RefCounted class representing the immutable definition of a single game item — its stats, rarity, slot, and value. |
| 2  | **ItemDatabase**        | A RefCounted registry that indexes all `ItemData` definitions and provides filtered query methods.                   |
| 3  | **InventoryData**       | A RefCounted mutable container mapping item ids to owned quantities for a single entity (player, chest, shop).       |
| 4  | **RefCounted**          | Godot's base class for reference-counted objects. Freed automatically when no references remain. No Node overhead.   |
| 5  | **class_name**          | GDScript keyword that registers a class globally, allowing `ClassName.new()` without preloading the script.          |
| 6  | **ItemRarity**          | Enum (TASK-003): COMMON=0, UNCOMMON=1, RARE=2, EPIC=3, LEGENDARY=4. Drives drop rates, sell values, and UI color.   |
| 7  | **EquipSlot**           | Enum (TASK-003): NONE=-1, WEAPON=0, ARMOR=1, ACCESSORY=2. Determines which character slot an item occupies.          |
| 8  | **Currency**            | Enum (TASK-003): GOLD, ESSENCE, FRAGMENTS, ARTIFACTS, TOKENS. The five economic resource types in Dungeon Seed.      |
| 9  | **stat_bonuses**        | A Dictionary on `ItemData` mapping stat name strings (e.g. `"attack"`) to integer bonus values.                      |
| 10 | **sell_value**          | A Dictionary on `ItemData` mapping `Enums.Currency` keys to integer amounts — what the item is worth when sold.      |
| 11 | **Serialization**       | The process of converting an object to a plain Dictionary for JSON persistence, and back via `to_dict()`/`from_dict()`. |
| 12 | **Round-trip identity** | The guarantee that serializing then deserializing an object produces an equivalent copy with no data loss.            |
| 13 | **Starter items**       | The ~20 hardcoded item definitions that ship with the base game, spanning all rarity tiers and equipment slots.       |
| 14 | **Rarity color**        | A `Color` value from `GameConfig.RARITY_COLORS` used to tint item names, borders, and particle effects in UI.       |
| 15 | **Quantity tracking**   | The core mechanic of `InventoryData` — each item id maps to an integer count, not individual object instances.       |
| 16 | **Equippable**          | An item whose `slot` is not `NONE` (-1). These items can be placed into a character's equipment slots.               |
| 17 | **GUT**                 | Godot Unit Test framework. The project's standard for automated testing. Test files prefix with `test_`.             |
| 18 | **Loot Table Engine**   | TASK-011. Consumes `ItemDatabase` to roll randomized drops weighted by rarity and dungeon difficulty.                 |
| 19 | **Equipment System**    | TASK-014. Reads `ItemData.stat_bonuses` and `slot` to apply gear stats to characters.                                |
| 20 | **Dungeon Seed**        | The game's core entity — a sentient seed that grows into a dungeon. Loot fuels its progression.                      |

---

## 5. Out of Scope

The following items are explicitly **NOT** part of this ticket. They are handled by other tasks or deferred to future work.

| #  | Exclusion                                      | Reason / Owner                                                                  |
|----|------------------------------------------------|---------------------------------------------------------------------------------|
| 1  | Loot drop probability / weighted rolling       | TASK-011 (Loot Table Engine) owns drop logic.                                   |
| 2  | Equipment slot assignment on characters        | TASK-014 (Equipment System) owns equip/unequip flow.                            |
| 3  | UI rendering of items, tooltips, or icons      | Future UI tasks. `ItemData` provides data; rendering is a separate concern.     |
| 4  | Item crafting or recipe definitions             | Future crafting system. Inventory provides `has_item`/`remove_item` hooks only. |
| 5  | Item stacking limits or weight systems          | Not in current GDD scope. `InventoryData` allows unlimited stacking.            |
| 6  | Item durability or degradation                  | Not in current GDD scope. Items do not wear out.                                |
| 7  | Procedural item generation / random affixes     | Future advanced loot system. All items are designer-defined for now.             |
| 8  | Item trading between players                    | No multiplayer in current scope.                                                |
| 9  | Item sorting or filtering in inventory UI       | UI-layer concern. `list_all()` returns raw data; UI sorts as needed.            |
| 10 | Animated item icons or 3D item previews         | Art pipeline task. `ItemData` stores no visual assets.                           |
| 11 | Consumable items (potions, food, scrolls)       | Future item-type expansion. Current model supports only equippable + inert items.|
| 12 | Set bonuses (wearing N items of same set)       | TASK-014 or future. `ItemData` has no set affiliation field yet.                |
| 13 | Inventory capacity limits (bag size)            | Not in current GDD. `InventoryData` is unbounded.                               |
| 14 | Item level requirements or class restrictions   | Future gating system. `ItemData` has no `required_level` field.                 |
| 15 | Localization of item names and descriptions     | Future i18n task. All strings are English literals for now.                      |

---

## 6. Functional Requirements

### 6.1 ItemData — Core Fields

| ID      | Requirement                                                                                                    | Priority |
|---------|---------------------------------------------------------------------------------------------------------------|----------|
| FR-001  | `ItemData` SHALL extend `RefCounted` and register `class_name ItemData`.                                       | P0       |
| FR-002  | `ItemData.id` SHALL be a non-empty `String` using snake_case format.                                           | P0       |
| FR-003  | `ItemData.display_name` SHALL be a non-empty `String` for UI display.                                          | P0       |
| FR-004  | `ItemData.rarity` SHALL be a valid `Enums.ItemRarity` enum value.                                              | P0       |
| FR-005  | `ItemData.slot` SHALL be a valid `Enums.EquipSlot` enum value, defaulting to `Enums.EquipSlot.NONE` (-1).      | P0       |
| FR-006  | `ItemData.is_equippable` SHALL return `true` if and only if `slot != Enums.EquipSlot.NONE`.                    | P0       |
| FR-007  | `ItemData.stat_bonuses` SHALL be a `Dictionary` mapping `String` stat names to `int` values.                   | P0       |
| FR-008  | `ItemData.sell_value` SHALL be a `Dictionary` mapping `Enums.Currency` keys to `int` amounts.                  | P0       |
| FR-009  | `ItemData.description` SHALL be a `String` (may be empty for items without lore).                              | P1       |

### 6.2 ItemData — Methods

| ID      | Requirement                                                                                                    | Priority |
|---------|---------------------------------------------------------------------------------------------------------------|----------|
| FR-010  | `get_stat_bonus(stat_name: String) -> int` SHALL return the bonus value or `0` if the stat is absent.          | P0       |
| FR-011  | `get_sell_value(currency: Enums.Currency) -> int` SHALL return the sell amount or `0` if the currency is absent.| P0       |
| FR-012  | `get_rarity_color() -> Color` SHALL return the color from `GameConfig.RARITY_COLORS` for this item's rarity.  | P1       |
| FR-013  | `to_dict() -> Dictionary` SHALL serialize all fields to a JSON-compatible Dictionary.                          | P0       |
| FR-014  | `to_dict()` SHALL convert enum values to their integer representation for portability.                         | P0       |
| FR-015  | `from_dict(data: Dictionary) -> ItemData` SHALL be a static method that constructs an `ItemData` from a dict.  | P0       |
| FR-016  | `from_dict()` SHALL handle missing optional keys by applying sensible defaults (empty string, empty dict, 0).  | P1       |

### 6.3 ItemDatabase — Registry

| ID      | Requirement                                                                                                    | Priority |
|---------|---------------------------------------------------------------------------------------------------------------|----------|
| FR-017  | `ItemDatabase` SHALL extend `RefCounted` and register `class_name ItemDatabase`.                               | P0       |
| FR-018  | `ItemDatabase` SHALL store items in an internal `Dictionary` keyed by `ItemData.id`.                           | P0       |
| FR-019  | `ItemDatabase` constructor SHALL pre-populate with approximately 20 starter items.                             | P0       |
| FR-020  | Starter items SHALL span all five `ItemRarity` tiers.                                                          | P0       |
| FR-021  | Starter items SHALL include at least 3 items per `EquipSlot` (WEAPON, ARMOR, ACCESSORY).                      | P0       |
| FR-022  | `get_item(id: String) -> ItemData` SHALL return the matching item or `null` if not found.                      | P0       |
| FR-023  | `has_item(id: String) -> bool` SHALL return `true` if the id exists in the registry.                           | P0       |
| FR-024  | `get_items_by_rarity(rarity: Enums.ItemRarity) -> Array[ItemData]` SHALL return all items of that rarity.      | P0       |
| FR-025  | `get_items_by_slot(slot: Enums.EquipSlot) -> Array[ItemData]` SHALL return all items for that slot.            | P0       |
| FR-026  | `get_equippable_items() -> Array[ItemData]` SHALL return all items where `is_equippable == true`.              | P1       |
| FR-027  | `get_all_items() -> Array[ItemData]` SHALL return every registered item as an array.                           | P0       |
| FR-028  | `get_item_count() -> int` SHALL return the total number of registered items.                                   | P1       |
| FR-029  | `register_item(item: ItemData) -> void` SHALL add a new item, overwriting if id already exists.                | P1       |
| FR-030  | `load_from_dict(data: Dictionary) -> void` SHALL bulk-load items, calling `register_item` for each entry.      | P1       |

### 6.4 InventoryData — State Management

| ID      | Requirement                                                                                                    | Priority |
|---------|---------------------------------------------------------------------------------------------------------------|----------|
| FR-031  | `InventoryData` SHALL extend `RefCounted` and register `class_name InventoryData`.                             | P0       |
| FR-032  | `InventoryData.items` SHALL be a `Dictionary` mapping `String` item ids to `int` quantities.                   | P0       |
| FR-033  | `add_item(item_id: String, qty: int)` SHALL increase the quantity by `qty`. If absent, create with `qty`.      | P0       |
| FR-034  | `add_item()` SHALL assert that `qty > 0` to prevent zero/negative additions.                                   | P0       |
| FR-035  | `remove_item(item_id: String, qty: int) -> bool` SHALL decrease quantity by `qty` and return `true`.           | P0       |
| FR-036  | `remove_item()` SHALL return `false` without modifying state if current quantity < `qty`.                      | P0       |
| FR-037  | `remove_item()` SHALL erase the key entirely when remaining quantity reaches exactly zero.                     | P0       |
| FR-038  | `has_item(item_id: String, qty: int) -> bool` SHALL return `true` if owned quantity >= `qty`.                  | P0       |
| FR-039  | `get_quantity(item_id: String) -> int` SHALL return current quantity, or `0` if item not present.              | P0       |
| FR-040  | `list_all() -> Array[Dictionary]` SHALL return `[{ "item_id": id, "qty": n }]` for every owned item.          | P0       |
| FR-041  | `get_unique_item_count() -> int` SHALL return the number of distinct item ids in the inventory.                | P1       |
| FR-042  | `get_total_item_count() -> int` SHALL return the sum of all item quantities.                                   | P1       |
| FR-043  | `clear() -> void` SHALL remove all items, leaving an empty inventory.                                          | P0       |

### 6.5 InventoryData — Serialization

| ID      | Requirement                                                                                                    | Priority |
|---------|---------------------------------------------------------------------------------------------------------------|----------|
| FR-044  | `to_dict() -> Dictionary` SHALL return `{ "items": { item_id: qty, ... } }`.                                  | P0       |
| FR-045  | `from_dict(data: Dictionary)` SHALL clear existing items, then restore from `data["items"]`.                   | P0       |
| FR-046  | `from_dict()` SHALL handle missing `"items"` key gracefully by resulting in an empty inventory.                | P1       |
| FR-047  | Serialization round-trip SHALL preserve all item ids and quantities exactly.                                   | P0       |

### 6.6 InventoryData — Utility

| ID      | Requirement                                                                                                    | Priority |
|---------|---------------------------------------------------------------------------------------------------------------|----------|
| FR-048  | `merge(other: InventoryData) -> void` SHALL add all items from `other` into `self` additively.                 | P1       |
| FR-049  | `merge()` SHALL NOT modify the `other` inventory.                                                              | P1       |
| FR-050  | After `merge()`, for every item in `other`, `self.get_quantity(id)` SHALL equal previous self qty + other qty. | P1       |

---

## 7. Non-Functional Requirements

| ID       | Category       | Requirement                                                                                                                    |
|----------|----------------|--------------------------------------------------------------------------------------------------------------------------------|
| NFR-001  | Performance    | `ItemDatabase.get_item()` SHALL complete in O(1) via Dictionary lookup.                                                        |
| NFR-002  | Performance    | `ItemDatabase.get_items_by_rarity()` SHALL complete in O(n) where n is total items (linear scan is acceptable for <1000 items).|
| NFR-003  | Performance    | `InventoryData.add_item()` and `get_quantity()` SHALL complete in O(1) via Dictionary operations.                              |
| NFR-004  | Performance    | `InventoryData.list_all()` SHALL complete in O(n) where n is the number of distinct items owned.                               |
| NFR-005  | Memory         | Each `ItemData` instance SHALL consume less than 1 KB of memory.                                                               |
| NFR-006  | Memory         | `ItemDatabase` with 1000 items SHALL consume less than 2 MB of memory.                                                         |
| NFR-007  | Testability    | All three classes SHALL be testable in isolation with no Node tree, no SceneTree, and no autoloads.                            |
| NFR-008  | Testability    | All public methods SHALL be covered by GUT unit tests with at least 95% branch coverage.                                       |
| NFR-009  | Maintainability| Adding a new item to the database SHALL require editing only the data dictionary — no code changes.                             |
| NFR-010  | Maintainability| All public methods SHALL have complete GDScript type hints on parameters and return types.                                      |
| NFR-011  | Portability    | `to_dict()` output SHALL contain only JSON-compatible primitives (String, int, float, bool, Array, Dictionary).                |
| NFR-012  | Portability    | `from_dict()` SHALL not crash on malformed input — missing keys produce defaults, wrong types produce warnings.                |
| NFR-013  | Extensibility  | Adding a new `EquipSlot` or `ItemRarity` enum value SHALL not require changes to `ItemData` or `InventoryData`.                |
| NFR-014  | Extensibility  | `ItemDatabase.register_item()` SHALL allow runtime registration for mod/DLC support.                                            |
| NFR-015  | Reliability    | `InventoryData` SHALL never produce negative quantities under any sequence of valid operations.                                  |
| NFR-016  | Reliability    | `remove_item()` SHALL be atomic — either the full quantity is removed and `true` returned, or nothing changes and `false` returned.|
| NFR-017  | Compatibility  | All classes SHALL be compatible with Godot 4.6 GDScript and require no C# or GDExtension.                                     |
| NFR-018  | Code Quality   | All files SHALL pass GDScript static analysis with zero warnings at the default strictness level.                              |

---

## 8. Designer's Manual

### 8.1 Quick Start: Adding a New Item

To add a new item to the game, you only need to edit one place: the `_build_starter_items()` method in `src/models/item_database.gd`. Here is a complete example of adding a new Rare accessory:

```gdscript
# In item_database.gd, inside _build_starter_items():
_register_from_raw({
    "id": "moonstone_pendant",
    "display_name": "Moonstone Pendant",
    "rarity": Enums.ItemRarity.RARE,
    "slot": Enums.EquipSlot.ACCESSORY,
    "stat_bonuses": {
        "magic_def": 8,
        "hp": 20,
        "magic": 3,
    },
    "sell_value": {
        Enums.Currency.GOLD: 75,
        Enums.Currency.ESSENCE: 5,
    },
    "description": "A pendant carved from moonstone found deep within the Verdant Hollow. It hums softly in darkness.",
})
```

**Rules for new items:**
1. `id` must be unique, snake_case, and descriptive (e.g. `"moonstone_pendant"`, not `"item_47"`).
2. `rarity` must be a valid `Enums.ItemRarity` value.
3. `slot` must be a valid `Enums.EquipSlot` value. Use `Enums.EquipSlot.NONE` for non-equippable items.
4. `stat_bonuses` keys must match the stat names used by the character system (see Stat Names table below).
5. `sell_value` keys must be valid `Enums.Currency` values. Omit currencies the item cannot be sold for.
6. `description` is optional but strongly recommended for items Uncommon and above.

### 8.2 Recognized Stat Names

The following stat name strings are used across the project. Always use these exact strings in `stat_bonuses`:

| Stat Name     | Description                           | Typical Range (Common→Legendary) |
|---------------|---------------------------------------|----------------------------------|
| `"attack"`    | Physical attack power                 | 1–25                             |
| `"defense"`   | Physical damage reduction             | 1–25                             |
| `"magic"`     | Magical attack power                  | 1–25                             |
| `"magic_def"` | Magical damage reduction              | 1–20                             |
| `"hp"`        | Maximum hit points bonus              | 5–50                             |
| `"speed"`     | Turn order / action speed             | 1–10                             |
| `"crit"`      | Critical hit chance bonus (%)         | 1–15                             |

### 8.3 Rarity Guidelines

Each rarity tier has conventions for stat budgets and sell values:

| Rarity    | Stat Budget (sum of all bonuses) | Gold Sell Value | Typical Stat Count |
|-----------|----------------------------------|-----------------|--------------------|
| Common    | 2–5                             | 3–8             | 1 stat             |
| Uncommon  | 5–12                            | 10–25           | 1–2 stats          |
| Rare      | 12–22                           | 40–80           | 2–3 stats          |
| Epic      | 20–40                           | 100–250         | 3–4 stats          |
| Legendary | 30–60+                          | 300–1000        | 4–5 stats          |

These are guidelines, not hard limits. Some items may intentionally break conventions for flavor (e.g., a Legendary with one massive stat instead of many small ones).

### 8.4 Working with the Inventory

**Adding items to a player's inventory:**
```gdscript
var inventory := InventoryData.new()

# Player loots 3 copper rings from a chest
inventory.add_item("copper_ring", 3)

# Player loots 1 iron sword
inventory.add_item("iron_sword", 1)

# Check how many copper rings the player has
var ring_count: int = inventory.get_quantity("copper_ring")  # Returns 3

# Check if the player has at least 2 copper rings to sell
var can_sell: bool = inventory.has_item("copper_ring", 2)  # Returns true

# Sell 2 copper rings
var sold: bool = inventory.remove_item("copper_ring", 2)  # Returns true, qty now 1

# Try to sell 5 more (fails gracefully)
var oversell: bool = inventory.remove_item("copper_ring", 5)  # Returns false, qty still 1
```

**Listing inventory contents for UI:**
```gdscript
var all_items: Array[Dictionary] = inventory.list_all()
for entry in all_items:
    var item_id: String = entry["item_id"]
    var qty: int = entry["qty"]
    var item_def: ItemData = item_database.get_item(item_id)
    if item_def:
        print("%s x%d — %s" % [item_def.display_name, qty, item_def.get_rarity_color()])
```

**Saving and loading inventory:**
```gdscript
# Save
var save_data: Dictionary = inventory.to_dict()
# save_data is now: { "items": { "copper_ring": 1, "iron_sword": 1 } }
# Write save_data to JSON file via your save system

# Load
var loaded_inventory := InventoryData.new()
loaded_inventory.from_dict(save_data)
assert(loaded_inventory.get_quantity("copper_ring") == 1)
```

### 8.5 Querying the Item Database

**Find all Rare items:**
```gdscript
var db := ItemDatabase.new()
var rare_items: Array[ItemData] = db.get_items_by_rarity(Enums.ItemRarity.RARE)
for item in rare_items:
    print("%s — %s" % [item.display_name, item.description])
```

**Find all weapons:**
```gdscript
var weapons: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.WEAPON)
for weapon in weapons:
    var atk: int = weapon.get_stat_bonus("attack")
    print("%s — ATK +%d" % [weapon.display_name, atk])
```

**Get a specific item for tooltip:**
```gdscript
var item: ItemData = db.get_item("crystal_saber")
if item:
    print("Name: %s" % item.display_name)
    print("Rarity: %s" % Enums.ItemRarity.keys()[item.rarity])
    print("Slot: %s" % Enums.EquipSlot.keys()[item.slot])
    print("ATK: +%d" % item.get_stat_bonus("attack"))
    print("CRIT: +%d" % item.get_stat_bonus("crit"))
    print("Sell: %d Gold" % item.get_sell_value(Enums.Currency.GOLD))
    print("Lore: %s" % item.description)
```

### 8.6 Merging Inventories

When a player opens a chest or receives rewards from multiple sources, you may want to merge inventories:

```gdscript
var player_inv := InventoryData.new()
player_inv.add_item("iron_sword", 1)
player_inv.add_item("copper_ring", 2)

var chest_loot := InventoryData.new()
chest_loot.add_item("copper_ring", 3)
chest_loot.add_item("leather_vest", 1)

player_inv.merge(chest_loot)

# player_inv now has: iron_sword x1, copper_ring x5, leather_vest x1
# chest_loot is unchanged: copper_ring x3, leather_vest x1
```

### 8.7 Extending the Stat System

When new stats are added to the character system (e.g., `"luck"`, `"stamina"`), no changes to `ItemData` are needed. Simply use the new stat name string in `stat_bonuses`:

```gdscript
{
    "id": "lucky_charm",
    "display_name": "Lucky Charm",
    "rarity": Enums.ItemRarity.UNCOMMON,
    "slot": Enums.EquipSlot.ACCESSORY,
    "stat_bonuses": { "luck": 8 },
    "sell_value": { Enums.Currency.GOLD: 20 },
    "description": "Smells faintly of four-leaf clovers.",
}
```

The `stat_bonuses` Dictionary is schema-free — it accepts any string key. The consuming system (Equipment System, TASK-014) is responsible for recognizing and applying the stat names it cares about.

### 8.8 Non-Equippable Items

Not all items go into equipment slots. Quest items, crafting materials, and currency tokens use `slot: Enums.EquipSlot.NONE`:

```gdscript
{
    "id": "dungeon_key",
    "display_name": "Dungeon Key",
    "rarity": Enums.ItemRarity.COMMON,
    "slot": Enums.EquipSlot.NONE,
    "stat_bonuses": {},
    "sell_value": {},
    "description": "A rusted iron key. It opens something, somewhere.",
}
```

For such items, `is_equippable` returns `false`, and they will not appear in equipment slot queries.

---

## 9. Assumptions

| #  | Assumption                                                                                                             |
|----|------------------------------------------------------------------------------------------------------------------------|
| 1  | TASK-003 (Core Enums & Constants) is complete. `Enums.ItemRarity`, `Enums.EquipSlot`, and `Enums.Currency` exist.     |
| 2  | `GameConfig.RARITY_COLORS` exists as a Dictionary mapping `Enums.ItemRarity` to `Color` values.                        |
| 3  | The project uses GUT (Godot Unit Test) framework for all automated testing.                                            |
| 4  | Items are not instanced — there is one `ItemData` definition per item id, shared by all references.                    |
| 5  | Inventory quantities are simple integers with no upper bound. Stacking limits are deferred.                            |
| 6  | Item ids are globally unique strings. No two items share the same id, even across categories.                          |
| 7  | All stat bonus values are integers. Floating-point stat bonuses are not needed in the current design.                  |
| 8  | The starter item set (~20 items) is hardcoded in GDScript, not loaded from external JSON files.                        |
| 9  | `InventoryData` represents a single entity's inventory. Multiple entities each have their own instance.                |
| 10 | Sell values are fixed per item definition. Dynamic pricing (merchant haggling) is a future system.                      |
| 11 | The `description` field is plain text. Rich text / BBCode formatting is a UI-layer concern, not a data concern.        |
| 12 | No signals are emitted from these models. Event notification is the responsibility of the consuming system.             |
| 13 | `from_dict()` is tolerant of missing keys but not tolerant of wrong types (e.g., passing a String where int expected). |
| 14 | The Equipment System (TASK-014) will handle equip validation. `ItemData` only declares slot compatibility.              |
| 15 | Currency enum values are stable and will not be renumbered. Serialization stores integer enum values.                   |

---

## 10. Security & Anti-Cheat

| #  | Concern                              | Mitigation                                                                                                                           |
|----|--------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|
| 1  | **Inventory quantity tampering**     | `InventoryData` validates that `qty > 0` on `add_item()` and prevents negative quantities via `remove_item()` returning `false`. No public setter allows direct quantity assignment. All mutations go through validated methods. |
| 2  | **Item id injection**                | `ItemDatabase.get_item()` returns `null` for unknown ids. Consuming systems MUST null-check before using an `ItemData` reference. No item can be created purely by inventing an id string — it must exist in the database.       |
| 3  | **Save file manipulation**           | `from_dict()` validates that quantity values are positive integers. If a save file contains `"iron_sword": -99`, the negative value is clamped to 0 or the entry is skipped. Item ids not present in `ItemDatabase` are preserved in inventory but produce warnings when accessed. |
| 4  | **Stat bonus overflow**              | `stat_bonuses` values are standard GDScript `int` (64-bit). No practical overflow risk. The Equipment System (TASK-014) is responsible for capping applied stats if game design requires stat ceilings.                        |
| 5  | **Duplicate registration**           | `ItemDatabase.register_item()` overwrites existing entries with the same id. This is intentional for mod support but logged with `push_warning()` to alert designers to accidental id collisions during development.            |
| 6  | **Deserialization of untrusted data**| `ItemData.from_dict()` uses `get()` with defaults on all Dictionary accesses. Type mismatches produce logged warnings and fallback values rather than crashes. No `eval()` or dynamic code execution is ever used.               |

---

## 11. Best Practices

| #  | Practice                                                                                                                   |
|----|----------------------------------------------------------------------------------------------------------------------------|
| 1  | **Type everything.** Every variable, parameter, and return type must have a GDScript type hint. No untyped `var x`.        |
| 2  | **Use `class_name`.** All three classes register a `class_name` so they can be instantiated with `ClassName.new()`.        |
| 3  | **Extend RefCounted, not Node.** These are pure data objects. They must not require the SceneTree or process callbacks.    |
| 4  | **Immutable definitions.** `ItemData` fields are set once in the constructor or `from_dict()`. No public setters.          |
| 5  | **Fail gracefully.** `get_item()` returns `null`, not crashes. `remove_item()` returns `false`, not exceptions.            |
| 6  | **Use `get()` with defaults.** All Dictionary reads in `from_dict()` use `data.get("key", default_value)`.                |
| 7  | **Clean up zero-quantity entries.** `remove_item()` erases the key when quantity hits zero. No phantom entries.             |
| 8  | **snake_case for item ids.** All item ids use lowercase snake_case. Enforce this in code review.                           |
| 9  | **Document stat names.** Keep the recognized stat names table (Section 8.2) up to date as new stats are added.             |
| 10 | **Test round-trip serialization.** Every `to_dict()`/`from_dict()` pair must be tested with data equality assertions.      |
| 11 | **No signals in data models.** These classes emit no signals. Event propagation is the consuming system's responsibility.   |
| 12 | **No file I/O in constructors.** `ItemDatabase` populates from hardcoded data in the constructor. File loading is explicit. |
| 13 | **Prefer `Array[ItemData]` over `Array`.** Use typed arrays for all public return types to enable editor autocompletion.    |
| 14 | **Warn on suspicious input.** Use `push_warning()` for non-fatal issues (unknown item id, negative sell value) during load. |
| 15 | **Keep data and logic separate.** These models hold data and provide accessors. Business logic belongs in system classes.   |

---

## 12. Troubleshooting

### Issue 1: `get_item()` returns `null` for an item I just added

**Symptoms:** You added a new item to `_build_starter_items()` but `get_item("my_new_item")` returns `null`.
**Diagnosis:** Check that the `id` field in the item dictionary exactly matches the id you are querying. Item ids are case-sensitive and must be snake_case. A common mistake is using `"my_New_Item"` in the definition but querying `"my_new_item"`.
**Fix:** Ensure the `"id"` field value in the dictionary matches the lookup key exactly. Add a print statement: `print(db.get_all_items().map(func(i): return i.id))` to see all registered ids.

### Issue 2: `remove_item()` always returns `false`

**Symptoms:** Calling `inventory.remove_item("iron_sword", 1)` returns `false` even though you believe the item was added.
**Diagnosis:** Check that `add_item()` was called with the correct item id string. Print `inventory.list_all()` to see current contents. Common causes: typo in item id, or the add was done on a different `InventoryData` instance.
**Fix:** Verify the instance identity. `InventoryData` is RefCounted — passing it to a function passes the reference, but creating `InventoryData.new()` in two places creates two separate inventories.

### Issue 3: Serialization round-trip loses enum values

**Symptoms:** After `to_dict()` then `from_dict()`, rarity or slot values are wrong (e.g., 0 instead of `LEGENDARY`).
**Diagnosis:** `to_dict()` stores enums as their integer values. `from_dict()` must cast them back using `int()`. If `from_dict()` reads the raw value without casting, it may be interpreted as a float in JSON.
**Fix:** Ensure `from_dict()` uses `int(data.get("rarity", 0))` to force integer typing. The implementation in this ticket handles this correctly.

### Issue 4: `get_items_by_rarity()` returns an empty array

**Symptoms:** `db.get_items_by_rarity(Enums.ItemRarity.LEGENDARY)` returns `[]` despite legendary items existing.
**Diagnosis:** Verify that the `rarity` field in the item definition uses the enum value, not an integer literal. `Enums.ItemRarity.LEGENDARY` (value 4) must be stored, not the string `"LEGENDARY"`.
**Fix:** In `_build_starter_items()`, always use `Enums.ItemRarity.LEGENDARY`, never `4` or `"LEGENDARY"`.

### Issue 5: `from_dict()` crashes on malformed save data

**Symptoms:** Loading a save file that was manually edited (or corrupted) causes a crash in `from_dict()`.
**Diagnosis:** The `from_dict()` implementation should use `get()` with defaults for all keys. If it uses direct `data["key"]` access, missing keys will cause a runtime error.
**Fix:** All Dictionary access in `from_dict()` must use `data.get("key", default)`. The implementation in this ticket follows this pattern.

### Issue 6: Inventory merge doubles items unexpectedly

**Symptoms:** After merging two inventories, quantities are higher than expected.
**Diagnosis:** `merge()` is additive — it adds the `other` inventory's quantities to `self`. If you merge the same inventory twice, quantities double. This is by design.
**Fix:** If you only want to merge once, ensure `merge()` is called exactly once per source. Consider clearing the source after merge if it represents a consumed container (e.g., a looted chest).

### Issue 7: Test fails with "Cannot find class ItemData"

**Symptoms:** GUT test file cannot resolve `ItemData`, `ItemDatabase`, or `InventoryData`.
**Diagnosis:** The `class_name` directive requires the file to be saved in the project's `res://` tree and recognized by Godot's script parser. If the file is outside the project or has a syntax error, the class_name is not registered.
**Fix:** Ensure the `.gd` files are in the correct `src/models/` directory within the Godot project root. Restart the editor to force re-scanning of class names.

---

## 13. Acceptance Criteria

Every criterion below must pass before this ticket is considered complete. Test method: **A** = Automated (GUT), **M** = Manual, **R** = Code Review.

### 13.1 ItemData — Structure

| ID     | Criterion                                                                                              | Method |
|--------|--------------------------------------------------------------------------------------------------------|--------|
| AC-001 | `item_data.gd` exists at `src/models/item_data.gd`.                                                   | R      |
| AC-002 | `ItemData` extends `RefCounted` and declares `class_name ItemData`.                                    | R      |
| AC-003 | `ItemData.id` is typed as `String` and is non-empty for all starter items.                             | A      |
| AC-004 | `ItemData.display_name` is typed as `String` and is non-empty for all starter items.                   | A      |
| AC-005 | `ItemData.rarity` is typed as `Enums.ItemRarity`.                                                      | R      |
| AC-006 | `ItemData.slot` is typed as `Enums.EquipSlot` with default `NONE`.                                     | R      |
| AC-007 | `ItemData.is_equippable` returns `true` when slot != NONE and `false` when slot == NONE.               | A      |
| AC-008 | `ItemData.stat_bonuses` is typed as `Dictionary` and contains only String keys and int values.          | A      |
| AC-009 | `ItemData.sell_value` is typed as `Dictionary` and contains only Currency enum keys and int values.     | A      |
| AC-010 | `ItemData.description` is typed as `String`.                                                           | R      |

### 13.2 ItemData — Methods

| ID     | Criterion                                                                                              | Method |
|--------|--------------------------------------------------------------------------------------------------------|--------|
| AC-011 | `get_stat_bonus("attack")` returns the correct bonus for items that have it.                           | A      |
| AC-012 | `get_stat_bonus("nonexistent_stat")` returns `0`.                                                      | A      |
| AC-013 | `get_sell_value(Enums.Currency.GOLD)` returns correct gold sell value.                                  | A      |
| AC-014 | `get_sell_value()` for a currency not in sell_value returns `0`.                                        | A      |
| AC-015 | `get_rarity_color()` returns the correct color from `GameConfig.RARITY_COLORS`.                        | A      |
| AC-016 | `to_dict()` returns a Dictionary containing all fields with correct types.                             | A      |
| AC-017 | `to_dict()` stores rarity and slot as integer values.                                                  | A      |
| AC-018 | `ItemData.from_dict()` reconstructs an equivalent `ItemData` from `to_dict()` output.                  | A      |
| AC-019 | `from_dict()` with missing optional keys produces sensible defaults without crashing.                  | A      |
| AC-020 | Round-trip: `from_dict(to_dict())` produces an object with identical field values.                      | A      |

### 13.3 ItemDatabase — Registry

| ID     | Criterion                                                                                              | Method |
|--------|--------------------------------------------------------------------------------------------------------|--------|
| AC-021 | `item_database.gd` exists at `src/models/item_database.gd`.                                           | R      |
| AC-022 | `ItemDatabase` extends `RefCounted` and declares `class_name ItemDatabase`.                            | R      |
| AC-023 | Constructor pre-populates with at least 20 starter items.                                              | A      |
| AC-024 | Starter items include at least 3 weapons.                                                              | A      |
| AC-025 | Starter items include at least 3 armors.                                                               | A      |
| AC-026 | Starter items include at least 3 accessories.                                                          | A      |
| AC-027 | Starter items span all 5 rarity tiers (at least 1 item per tier).                                      | A      |
| AC-028 | `get_item("iron_sword")` returns an `ItemData` with correct fields.                                    | A      |
| AC-029 | `get_item("nonexistent_item_xyz")` returns `null`.                                                     | A      |
| AC-030 | `has_item("iron_sword")` returns `true`.                                                               | A      |
| AC-031 | `has_item("nonexistent_item_xyz")` returns `false`.                                                    | A      |
| AC-032 | `get_items_by_rarity(COMMON)` returns only Common items.                                               | A      |
| AC-033 | `get_items_by_rarity(LEGENDARY)` returns only Legendary items.                                         | A      |
| AC-034 | `get_items_by_slot(WEAPON)` returns only weapon-slot items.                                            | A      |
| AC-035 | `get_items_by_slot(ACCESSORY)` returns only accessory-slot items.                                      | A      |
| AC-036 | `get_equippable_items()` returns all items where `is_equippable == true`.                              | A      |
| AC-037 | `get_all_items()` returns all registered items.                                                        | A      |
| AC-038 | `get_item_count()` equals the number of registered items.                                              | A      |
| AC-039 | `register_item()` adds a new item accessible via `get_item()`.                                         | A      |
| AC-040 | `register_item()` with an existing id overwrites the previous definition.                              | A      |

### 13.4 InventoryData — Operations

| ID     | Criterion                                                                                              | Method |
|--------|--------------------------------------------------------------------------------------------------------|--------|
| AC-041 | `inventory_data.gd` exists at `src/models/inventory_data.gd`.                                         | R      |
| AC-042 | `InventoryData` extends `RefCounted` and declares `class_name InventoryData`.                          | R      |
| AC-043 | `add_item("iron_sword", 1)` creates entry with quantity 1.                                             | A      |
| AC-044 | `add_item("iron_sword", 3)` on existing entry increases quantity to 4.                                 | A      |
| AC-045 | `remove_item("iron_sword", 2)` returns `true` and reduces quantity to 2.                               | A      |
| AC-046 | `remove_item("iron_sword", 99)` returns `false` when insufficient quantity, state unchanged.           | A      |
| AC-047 | `remove_item()` erases the key when quantity reaches exactly zero.                                      | A      |
| AC-048 | `has_item("iron_sword", 1)` returns `true` when quantity >= 1.                                         | A      |
| AC-049 | `has_item("iron_sword", 999)` returns `false` when insufficient.                                       | A      |
| AC-050 | `has_item("nonexistent", 1)` returns `false`.                                                          | A      |
| AC-051 | `get_quantity("iron_sword")` returns current quantity.                                                  | A      |
| AC-052 | `get_quantity("nonexistent")` returns `0`.                                                             | A      |
| AC-053 | `list_all()` returns correct array of `{ "item_id", "qty" }` dictionaries.                             | A      |
| AC-054 | `get_unique_item_count()` returns number of distinct item ids.                                         | A      |
| AC-055 | `get_total_item_count()` returns sum of all quantities.                                                | A      |
| AC-056 | `clear()` removes all items; `get_unique_item_count()` returns 0.                                      | A      |

### 13.5 InventoryData — Serialization & Utility

| ID     | Criterion                                                                                              | Method |
|--------|--------------------------------------------------------------------------------------------------------|--------|
| AC-057 | `to_dict()` returns `{ "items": { id: qty } }` format.                                                | A      |
| AC-058 | `from_dict()` restores exact state from `to_dict()` output.                                            | A      |
| AC-059 | `from_dict()` with missing `"items"` key results in empty inventory.                                   | A      |
| AC-060 | `from_dict()` clears existing items before restoring.                                                  | A      |
| AC-061 | Serialization round-trip preserves all item ids and quantities.                                        | A      |
| AC-062 | `merge()` combines two inventories additively.                                                         | A      |
| AC-063 | `merge()` does not modify the source inventory.                                                        | A      |
| AC-064 | `merge()` with overlapping items sums quantities correctly.                                            | A      |

### 13.6 Code Quality

| ID     | Criterion                                                                                              | Method |
|--------|--------------------------------------------------------------------------------------------------------|--------|
| AC-065 | All public methods have complete type hints on parameters and return values.                            | R      |
| AC-066 | All three files pass GDScript static analysis with zero errors.                                        | A      |
| AC-067 | All three test files exist and pass with zero failures.                                                 | A      |
| AC-068 | No `class_name` conflicts with existing project classes.                                                | R      |
| AC-069 | No hardcoded magic numbers — constants are named or derived from enums.                                 | R      |
| AC-070 | Code follows project snake_case naming convention throughout.                                           | R      |

---

## 14. Testing

All tests use the GUT (Godot Unit Test) framework. Each test file is standalone — no SceneTree, no autoloads, no external dependencies beyond the class under test and the TASK-003 enums.

### 14.1 Test File: `tests/models/test_item_data.gd`

```gdscript
extends GutTest

class_name TestItemData


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_sword_data() -> Dictionary:
    return {
        "id": "test_iron_sword",
        "display_name": "Iron Sword",
        "rarity": Enums.ItemRarity.UNCOMMON,
        "slot": Enums.EquipSlot.WEAPON,
        "stat_bonuses": { "attack": 5, "crit": 1 },
        "sell_value": { Enums.Currency.GOLD: 15, Enums.Currency.ESSENCE: 2 },
        "description": "A sturdy blade forged from common iron.",
    }


func _make_ring_data() -> Dictionary:
    return {
        "id": "test_copper_ring",
        "display_name": "Copper Ring",
        "rarity": Enums.ItemRarity.COMMON,
        "slot": Enums.EquipSlot.ACCESSORY,
        "stat_bonuses": { "hp": 5 },
        "sell_value": { Enums.Currency.GOLD: 3 },
        "description": "A simple copper band.",
    }


func _make_quest_item_data() -> Dictionary:
    return {
        "id": "test_dungeon_key",
        "display_name": "Dungeon Key",
        "rarity": Enums.ItemRarity.COMMON,
        "slot": Enums.EquipSlot.NONE,
        "stat_bonuses": {},
        "sell_value": {},
        "description": "Opens a sealed dungeon door.",
    }


# ---------------------------------------------------------------------------
# Construction Tests
# ---------------------------------------------------------------------------

func test_construction_sets_all_fields() -> void:
    var data: Dictionary = _make_sword_data()
    var item: ItemData = ItemData.new(data)
    assert_eq(item.id, "test_iron_sword")
    assert_eq(item.display_name, "Iron Sword")
    assert_eq(item.rarity, Enums.ItemRarity.UNCOMMON)
    assert_eq(item.slot, Enums.EquipSlot.WEAPON)
    assert_eq(item.stat_bonuses["attack"], 5)
    assert_eq(item.stat_bonuses["crit"], 1)
    assert_eq(item.sell_value[Enums.Currency.GOLD], 15)
    assert_eq(item.sell_value[Enums.Currency.ESSENCE], 2)
    assert_eq(item.description, "A sturdy blade forged from common iron.")


func test_is_equippable_true_for_weapon() -> void:
    var item: ItemData = ItemData.new(_make_sword_data())
    assert_true(item.is_equippable)


func test_is_equippable_true_for_accessory() -> void:
    var item: ItemData = ItemData.new(_make_ring_data())
    assert_true(item.is_equippable)


func test_is_equippable_false_for_none_slot() -> void:
    var item: ItemData = ItemData.new(_make_quest_item_data())
    assert_false(item.is_equippable)


# ---------------------------------------------------------------------------
# Stat Bonus Tests
# ---------------------------------------------------------------------------

func test_get_stat_bonus_existing_stat() -> void:
    var item: ItemData = ItemData.new(_make_sword_data())
    assert_eq(item.get_stat_bonus("attack"), 5)
    assert_eq(item.get_stat_bonus("crit"), 1)


func test_get_stat_bonus_missing_stat_returns_zero() -> void:
    var item: ItemData = ItemData.new(_make_sword_data())
    assert_eq(item.get_stat_bonus("defense"), 0)
    assert_eq(item.get_stat_bonus("nonexistent"), 0)


func test_get_stat_bonus_empty_bonuses() -> void:
    var item: ItemData = ItemData.new(_make_quest_item_data())
    assert_eq(item.get_stat_bonus("attack"), 0)


# ---------------------------------------------------------------------------
# Sell Value Tests
# ---------------------------------------------------------------------------

func test_get_sell_value_existing_currency() -> void:
    var item: ItemData = ItemData.new(_make_sword_data())
    assert_eq(item.get_sell_value(Enums.Currency.GOLD), 15)
    assert_eq(item.get_sell_value(Enums.Currency.ESSENCE), 2)


func test_get_sell_value_missing_currency_returns_zero() -> void:
    var item: ItemData = ItemData.new(_make_sword_data())
    assert_eq(item.get_sell_value(Enums.Currency.FRAGMENTS), 0)
    assert_eq(item.get_sell_value(Enums.Currency.ARTIFACTS), 0)


func test_get_sell_value_empty_sell_dict() -> void:
    var item: ItemData = ItemData.new(_make_quest_item_data())
    assert_eq(item.get_sell_value(Enums.Currency.GOLD), 0)


# ---------------------------------------------------------------------------
# Rarity Color Tests
# ---------------------------------------------------------------------------

func test_get_rarity_color_common() -> void:
    var item: ItemData = ItemData.new(_make_ring_data())
    var expected: Color = GameConfig.RARITY_COLORS[Enums.ItemRarity.COMMON]
    assert_eq(item.get_rarity_color(), expected)


func test_get_rarity_color_uncommon() -> void:
    var item: ItemData = ItemData.new(_make_sword_data())
    var expected: Color = GameConfig.RARITY_COLORS[Enums.ItemRarity.UNCOMMON]
    assert_eq(item.get_rarity_color(), expected)


# ---------------------------------------------------------------------------
# Serialization Tests
# ---------------------------------------------------------------------------

func test_to_dict_contains_all_fields() -> void:
    var item: ItemData = ItemData.new(_make_sword_data())
    var d: Dictionary = item.to_dict()
    assert_true(d.has("id"))
    assert_true(d.has("display_name"))
    assert_true(d.has("rarity"))
    assert_true(d.has("slot"))
    assert_true(d.has("stat_bonuses"))
    assert_true(d.has("sell_value"))
    assert_true(d.has("description"))


func test_to_dict_stores_enums_as_ints() -> void:
    var item: ItemData = ItemData.new(_make_sword_data())
    var d: Dictionary = item.to_dict()
    assert_eq(typeof(d["rarity"]), TYPE_INT)
    assert_eq(typeof(d["slot"]), TYPE_INT)
    assert_eq(d["rarity"], int(Enums.ItemRarity.UNCOMMON))
    assert_eq(d["slot"], int(Enums.EquipSlot.WEAPON))


func test_to_dict_sell_value_keys_are_ints() -> void:
    var item: ItemData = ItemData.new(_make_sword_data())
    var d: Dictionary = item.to_dict()
    for key in d["sell_value"].keys():
        assert_eq(typeof(key), TYPE_INT)


func test_from_dict_reconstructs_item() -> void:
    var original: ItemData = ItemData.new(_make_sword_data())
    var d: Dictionary = original.to_dict()
    var restored: ItemData = ItemData.from_dict(d)
    assert_eq(restored.id, original.id)
    assert_eq(restored.display_name, original.display_name)
    assert_eq(restored.rarity, original.rarity)
    assert_eq(restored.slot, original.slot)
    assert_eq(restored.is_equippable, original.is_equippable)
    assert_eq(restored.stat_bonuses, original.stat_bonuses)
    assert_eq(restored.description, original.description)


func test_from_dict_round_trip_identity() -> void:
    var original: ItemData = ItemData.new(_make_sword_data())
    var restored: ItemData = ItemData.from_dict(original.to_dict())
    assert_eq(restored.to_dict(), original.to_dict())


func test_from_dict_missing_optional_keys_uses_defaults() -> void:
    var minimal: Dictionary = { "id": "bare_item", "display_name": "Bare" }
    var item: ItemData = ItemData.from_dict(minimal)
    assert_eq(item.id, "bare_item")
    assert_eq(item.display_name, "Bare")
    assert_eq(item.rarity, Enums.ItemRarity.COMMON)
    assert_eq(item.slot, Enums.EquipSlot.NONE)
    assert_false(item.is_equippable)
    assert_eq(item.stat_bonuses, {})
    assert_eq(item.sell_value, {})
    assert_eq(item.description, "")


func test_from_dict_quest_item_round_trip() -> void:
    var original: ItemData = ItemData.new(_make_quest_item_data())
    var restored: ItemData = ItemData.from_dict(original.to_dict())
    assert_eq(restored.id, original.id)
    assert_false(restored.is_equippable)
    assert_eq(restored.stat_bonuses, {})
```

### 14.2 Test File: `tests/models/test_item_database.gd`

```gdscript
extends GutTest

class_name TestItemDatabase

var db: ItemDatabase


func before_each() -> void:
    db = ItemDatabase.new()


# ---------------------------------------------------------------------------
# Starter Item Population Tests
# ---------------------------------------------------------------------------

func test_database_has_at_least_20_items() -> void:
    assert_gte(db.get_item_count(), 20)


func test_database_has_items_in_all_rarity_tiers() -> void:
    for rarity_value in Enums.ItemRarity.values():
        var items: Array[ItemData] = db.get_items_by_rarity(rarity_value)
        assert_gt(items.size(), 0, "Missing items for rarity %d" % rarity_value)


func test_database_has_at_least_3_weapons() -> void:
    var weapons: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.WEAPON)
    assert_gte(weapons.size(), 3)


func test_database_has_at_least_3_armors() -> void:
    var armors: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.ARMOR)
    assert_gte(armors.size(), 3)


func test_database_has_at_least_3_accessories() -> void:
    var accessories: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.ACCESSORY)
    assert_gte(accessories.size(), 3)


# ---------------------------------------------------------------------------
# Lookup Tests
# ---------------------------------------------------------------------------

func test_get_item_returns_correct_item() -> void:
    var item: ItemData = db.get_item("iron_sword")
    assert_not_null(item)
    assert_eq(item.id, "iron_sword")
    assert_eq(item.display_name, "Iron Sword")
    assert_eq(item.rarity, Enums.ItemRarity.UNCOMMON)
    assert_eq(item.slot, Enums.EquipSlot.WEAPON)


func test_get_item_nonexistent_returns_null() -> void:
    var item: ItemData = db.get_item("nonexistent_item_xyz")
    assert_null(item)


func test_has_item_existing() -> void:
    assert_true(db.has_item("iron_sword"))
    assert_true(db.has_item("copper_ring"))


func test_has_item_nonexistent() -> void:
    assert_false(db.has_item("nonexistent_item_xyz"))
    assert_false(db.has_item(""))


# ---------------------------------------------------------------------------
# Filter Tests
# ---------------------------------------------------------------------------

func test_get_items_by_rarity_common() -> void:
    var items: Array[ItemData] = db.get_items_by_rarity(Enums.ItemRarity.COMMON)
    for item in items:
        assert_eq(item.rarity, Enums.ItemRarity.COMMON)


func test_get_items_by_rarity_legendary() -> void:
    var items: Array[ItemData] = db.get_items_by_rarity(Enums.ItemRarity.LEGENDARY)
    for item in items:
        assert_eq(item.rarity, Enums.ItemRarity.LEGENDARY)
    assert_gt(items.size(), 0)


func test_get_items_by_slot_weapon() -> void:
    var items: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.WEAPON)
    for item in items:
        assert_eq(item.slot, Enums.EquipSlot.WEAPON)
        assert_true(item.is_equippable)


func test_get_items_by_slot_armor() -> void:
    var items: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.ARMOR)
    for item in items:
        assert_eq(item.slot, Enums.EquipSlot.ARMOR)


func test_get_items_by_slot_accessory() -> void:
    var items: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.ACCESSORY)
    for item in items:
        assert_eq(item.slot, Enums.EquipSlot.ACCESSORY)


func test_get_equippable_items_excludes_none_slot() -> void:
    var equippable: Array[ItemData] = db.get_equippable_items()
    for item in equippable:
        assert_true(item.is_equippable)
        assert_ne(item.slot, Enums.EquipSlot.NONE)


func test_get_all_items_count_matches() -> void:
    var all_items: Array[ItemData] = db.get_all_items()
    assert_eq(all_items.size(), db.get_item_count())


# ---------------------------------------------------------------------------
# Registration Tests
# ---------------------------------------------------------------------------

func test_register_new_item() -> void:
    var new_item: ItemData = ItemData.new({
        "id": "test_custom_blade",
        "display_name": "Custom Blade",
        "rarity": Enums.ItemRarity.EPIC,
        "slot": Enums.EquipSlot.WEAPON,
        "stat_bonuses": { "attack": 20 },
        "sell_value": { Enums.Currency.GOLD: 200 },
        "description": "A custom test weapon.",
    })
    var count_before: int = db.get_item_count()
    db.register_item(new_item)
    assert_eq(db.get_item_count(), count_before + 1)
    assert_not_null(db.get_item("test_custom_blade"))
    assert_eq(db.get_item("test_custom_blade").display_name, "Custom Blade")


func test_register_item_overwrites_existing() -> void:
    var original: ItemData = db.get_item("iron_sword")
    assert_not_null(original)
    var replacement: ItemData = ItemData.new({
        "id": "iron_sword",
        "display_name": "Iron Sword MK II",
        "rarity": Enums.ItemRarity.RARE,
        "slot": Enums.EquipSlot.WEAPON,
        "stat_bonuses": { "attack": 99 },
        "sell_value": { Enums.Currency.GOLD: 999 },
        "description": "An upgraded iron sword.",
    })
    var count_before: int = db.get_item_count()
    db.register_item(replacement)
    assert_eq(db.get_item_count(), count_before)
    assert_eq(db.get_item("iron_sword").display_name, "Iron Sword MK II")
    assert_eq(db.get_item("iron_sword").get_stat_bonus("attack"), 99)


# ---------------------------------------------------------------------------
# Starter Item Validation
# ---------------------------------------------------------------------------

func test_all_starter_items_have_nonempty_id() -> void:
    for item in db.get_all_items():
        assert_ne(item.id, "", "Item has empty id")


func test_all_starter_items_have_nonempty_display_name() -> void:
    for item in db.get_all_items():
        assert_ne(item.display_name, "", "Item %s has empty display_name" % item.id)


func test_all_equippable_items_have_stat_bonuses() -> void:
    for item in db.get_equippable_items():
        assert_gt(item.stat_bonuses.size(), 0, "Equippable item %s has no stat bonuses" % item.id)


func test_all_starter_items_have_valid_rarity() -> void:
    var valid_rarities: Array = Enums.ItemRarity.values()
    for item in db.get_all_items():
        assert_has(valid_rarities, item.rarity, "Item %s has invalid rarity" % item.id)
```


func test_get_items_by_slot_accessory() -> void:
    var items: Array[ItemData] = db.get_items_by_slot(Enums.EquipSlot.ACCESSORY)
    for item in items:
        assert_eq(item.slot, Enums.EquipSlot.ACCESSORY)


func test_get_equippable_items_excludes_none_slot() -> void:
    var equippable: Array[ItemData] = db.get_equippable_items()
    for item in equippable:
        assert_true(item.is_equippable)
        assert_ne(item.slot, Enums.EquipSlot.NONE)


func test_get_all_items_count_matches() -> void:
    var all_items: Array[ItemData] = db.get_all_items()
    assert_eq(all_items.size(), db.get_item_count())


# ---------------------------------------------------------------------------
# Registration Tests
# ---------------------------------------------------------------------------

func test_register_new_item() -> void:
    var new_item: ItemData = ItemData.new({
        "id": "test_custom_blade",
        "display_name": "Custom Blade",
        "rarity": Enums.ItemRarity.EPIC,
        "slot": Enums.EquipSlot.WEAPON,
        "stat_bonuses": { "attack": 20 },
        "sell_value": { Enums.Currency.GOLD: 200 },
        "description": "A custom test weapon.",
    })
    var count_before: int = db.get_item_count()
    db.register_item(new_item)
    assert_eq(db.get_item_count(), count_before + 1)
    assert_not_null(db.get_item("test_custom_blade"))
    assert_eq(db.get_item("test_custom_blade").display_name, "Custom Blade")


func test_register_item_overwrites_existing() -> void:
    var original: ItemData = db.get_item("iron_sword")
    assert_not_null(original)
    var replacement: ItemData = ItemData.new({
        "id": "iron_sword",
        "display_name": "Iron Sword MK II",
        "rarity": Enums.ItemRarity.RARE,
        "slot": Enums.EquipSlot.WEAPON,
        "stat_bonuses": { "attack": 99 },
        "sell_value": { Enums.Currency.GOLD: 999 },
        "description": "An upgraded iron sword.",
    })
    var count_before: int = db.get_item_count()
    db.register_item(replacement)
    assert_eq(db.get_item_count(), count_before)
    assert_eq(db.get_item("iron_sword").display_name, "Iron Sword MK II")
    assert_eq(db.get_item("iron_sword").get_stat_bonus("attack"), 99)


# ---------------------------------------------------------------------------
# Starter Item Validation
# ---------------------------------------------------------------------------

func test_all_starter_items_have_nonempty_id() -> void:
    for item in db.get_all_items():
        assert_ne(item.id, "", "Item has empty id")


func test_all_starter_items_have_nonempty_display_name() -> void:
    for item in db.get_all_items():
        assert_ne(item.display_name, "", "Item %s has empty display_name" % item.id)


func test_all_equippable_items_have_stat_bonuses() -> void:
    for item in db.get_equippable_items():
        assert_gt(item.stat_bonuses.size(), 0, "Equippable item %s has no stat bonuses" % item.id)


func test_all_starter_items_have_valid_rarity() -> void:
    var valid_rarities: Array = Enums.ItemRarity.values()
    for item in db.get_all_items():
        assert_has(valid_rarities, item.rarity, "Item %s has invalid rarity" % item.id)
```

### 14.3 Test File: `tests/models/test_inventory_data.gd`

```gdscript
extends GutTest

class_name TestInventoryData

var inv: InventoryData


func before_each() -> void:
    inv = InventoryData.new()


# ---------------------------------------------------------------------------
# Add Item Tests
# ---------------------------------------------------------------------------

func test_add_item_creates_entry() -> void:
    inv.add_item("iron_sword", 1)
    assert_eq(inv.get_quantity("iron_sword"), 1)


func test_add_item_stacks_quantity() -> void:
    inv.add_item("iron_sword", 1)
    inv.add_item("iron_sword", 3)
    assert_eq(inv.get_quantity("iron_sword"), 4)


func test_add_item_multiple_different_items() -> void:
    inv.add_item("iron_sword", 2)
    inv.add_item("copper_ring", 5)
    assert_eq(inv.get_quantity("iron_sword"), 2)
    assert_eq(inv.get_quantity("copper_ring"), 5)


# ---------------------------------------------------------------------------
# Remove Item Tests
# ---------------------------------------------------------------------------

func test_remove_item_success() -> void:
    inv.add_item("iron_sword", 5)
    var result: bool = inv.remove_item("iron_sword", 3)
    assert_true(result)
    assert_eq(inv.get_quantity("iron_sword"), 2)


func test_remove_item_insufficient_returns_false() -> void:
    inv.add_item("iron_sword", 2)
    var result: bool = inv.remove_item("iron_sword", 5)
    assert_false(result)
    assert_eq(inv.get_quantity("iron_sword"), 2)


func test_remove_item_nonexistent_returns_false() -> void:
    var result: bool = inv.remove_item("nonexistent", 1)
    assert_false(result)


func test_remove_item_exact_quantity_erases_key() -> void:
    inv.add_item("iron_sword", 3)
    var result: bool = inv.remove_item("iron_sword", 3)
    assert_true(result)
    assert_eq(inv.get_quantity("iron_sword"), 0)
    assert_false(inv.has_item("iron_sword", 1))


func test_remove_item_zero_quantity_not_in_list() -> void:
    inv.add_item("iron_sword", 1)
    inv.remove_item("iron_sword", 1)
    var all_items: Array[Dictionary] = inv.list_all()
    for entry in all_items:
        assert_ne(entry["item_id"], "iron_sword")


# ---------------------------------------------------------------------------
# Has Item Tests
# ---------------------------------------------------------------------------

func test_has_item_sufficient() -> void:
    inv.add_item("copper_ring", 10)
    assert_true(inv.has_item("copper_ring", 1))
    assert_true(inv.has_item("copper_ring", 5))
    assert_true(inv.has_item("copper_ring", 10))


func test_has_item_insufficient() -> void:
    inv.add_item("copper_ring", 3)
    assert_false(inv.has_item("copper_ring", 4))
    assert_false(inv.has_item("copper_ring", 100))


func test_has_item_nonexistent() -> void:
    assert_false(inv.has_item("nonexistent", 1))


# ---------------------------------------------------------------------------
# Get Quantity Tests
# ---------------------------------------------------------------------------

func test_get_quantity_existing_item() -> void:
    inv.add_item("leather_vest", 7)
    assert_eq(inv.get_quantity("leather_vest"), 7)


func test_get_quantity_nonexistent_returns_zero() -> void:
    assert_eq(inv.get_quantity("nonexistent"), 0)


# ---------------------------------------------------------------------------
# List All Tests
# ---------------------------------------------------------------------------

func test_list_all_empty_inventory() -> void:
    var result: Array[Dictionary] = inv.list_all()
    assert_eq(result.size(), 0)


func test_list_all_returns_correct_entries() -> void:
    inv.add_item("iron_sword", 2)
    inv.add_item("copper_ring", 5)
    var result: Array[Dictionary] = inv.list_all()
    assert_eq(result.size(), 2)
    var ids: Array[String] = []
    for entry in result:
        ids.append(entry["item_id"])
        assert_true(entry.has("item_id"))
        assert_true(entry.has("qty"))
    assert_has(ids, "iron_sword")
    assert_has(ids, "copper_ring")


# ---------------------------------------------------------------------------
# Count Tests
# ---------------------------------------------------------------------------

func test_get_unique_item_count() -> void:
    inv.add_item("iron_sword", 2)
    inv.add_item("copper_ring", 5)
    inv.add_item("leather_vest", 1)
    assert_eq(inv.get_unique_item_count(), 3)


func test_get_total_item_count() -> void:
    inv.add_item("iron_sword", 2)
    inv.add_item("copper_ring", 5)
    inv.add_item("leather_vest", 1)
    assert_eq(inv.get_total_item_count(), 8)


func test_get_unique_item_count_empty() -> void:
    assert_eq(inv.get_unique_item_count(), 0)


func test_get_total_item_count_empty() -> void:
    assert_eq(inv.get_total_item_count(), 0)


# ---------------------------------------------------------------------------
# Clear Tests
# ---------------------------------------------------------------------------

func test_clear_empties_inventory() -> void:
    inv.add_item("iron_sword", 5)
    inv.add_item("copper_ring", 3)
    inv.clear()
    assert_eq(inv.get_unique_item_count(), 0)
    assert_eq(inv.get_total_item_count(), 0)
    assert_eq(inv.list_all().size(), 0)


# ---------------------------------------------------------------------------
# Serialization Tests
# ---------------------------------------------------------------------------

func test_to_dict_format() -> void:
    inv.add_item("iron_sword", 2)
    inv.add_item("copper_ring", 5)
    var d: Dictionary = inv.to_dict()
    assert_true(d.has("items"))
    assert_eq(d["items"]["iron_sword"], 2)
    assert_eq(d["items"]["copper_ring"], 5)


func test_from_dict_restores_state() -> void:
    inv.add_item("iron_sword", 2)
    inv.add_item("copper_ring", 5)
    var saved: Dictionary = inv.to_dict()
    var loaded: InventoryData = InventoryData.new()
    loaded.from_dict(saved)
    assert_eq(loaded.get_quantity("iron_sword"), 2)
    assert_eq(loaded.get_quantity("copper_ring"), 5)
    assert_eq(loaded.get_unique_item_count(), 2)


func test_from_dict_clears_existing() -> void:
    inv.add_item("old_item", 99)
    inv.from_dict({ "items": { "new_item": 1 } })
    assert_eq(inv.get_quantity("old_item"), 0)
    assert_eq(inv.get_quantity("new_item"), 1)


func test_from_dict_missing_items_key_empties_inventory() -> void:
    inv.add_item("iron_sword", 5)
    inv.from_dict({})
    assert_eq(inv.get_unique_item_count(), 0)


func test_serialization_round_trip() -> void:
    inv.add_item("iron_sword", 3)
    inv.add_item("copper_ring", 7)
    inv.add_item("leather_vest", 1)
    var saved: Dictionary = inv.to_dict()
    var loaded: InventoryData = InventoryData.new()
    loaded.from_dict(saved)
    assert_eq(loaded.to_dict(), saved)


func test_serialization_empty_inventory_round_trip() -> void:
    var saved: Dictionary = inv.to_dict()
    var loaded: InventoryData = InventoryData.new()
    loaded.from_dict(saved)
    assert_eq(loaded.get_unique_item_count(), 0)
    assert_eq(loaded.to_dict(), saved)


# ---------------------------------------------------------------------------
# Merge Tests
# ---------------------------------------------------------------------------

func test_merge_combines_inventories() -> void:
    inv.add_item("iron_sword", 1)
    inv.add_item("copper_ring", 2)
    var other: InventoryData = InventoryData.new()
    other.add_item("copper_ring", 3)
    other.add_item("leather_vest", 1)
    inv.merge(other)
    assert_eq(inv.get_quantity("iron_sword"), 1)
    assert_eq(inv.get_quantity("copper_ring"), 5)
    assert_eq(inv.get_quantity("leather_vest"), 1)


func test_merge_does_not_modify_source() -> void:
    inv.add_item("iron_sword", 1)
    var other: InventoryData = InventoryData.new()
    other.add_item("copper_ring", 3)
    inv.merge(other)
    assert_eq(other.get_quantity("copper_ring"), 3)
    assert_eq(other.get_unique_item_count(), 1)


func test_merge_empty_into_populated() -> void:
    inv.add_item("iron_sword", 5)
    var other: InventoryData = InventoryData.new()
    inv.merge(other)
    assert_eq(inv.get_quantity("iron_sword"), 5)
    assert_eq(inv.get_unique_item_count(), 1)


func test_merge_populated_into_empty() -> void:
    var other: InventoryData = InventoryData.new()
    other.add_item("iron_sword", 5)
    inv.merge(other)
    assert_eq(inv.get_quantity("iron_sword"), 5)
```

---

## 15. Playtesting Verification

These manual checks should be performed by a designer or QA tester in the Godot editor to verify the models integrate correctly with the broader game.

| #  | Verification Step                                                                                                         | Expected Result                                                                                   |
|----|---------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| 1  | Open the Godot console and run: `var db = ItemDatabase.new(); print(db.get_item_count())`.                                | Prints a number >= 20.                                                                            |
| 2  | Run: `var item = ItemDatabase.new().get_item("iron_sword"); print(item.display_name, " — ATK +", item.get_stat_bonus("attack"))`. | Prints `"Iron Sword — ATK +5"`.                                                                   |
| 3  | Run: `var db = ItemDatabase.new(); print(db.get_items_by_rarity(Enums.ItemRarity.LEGENDARY).size())`.                     | Prints at least 1 (obsidian_charm is Legendary).                                                   |
| 4  | Run: `var inv = InventoryData.new(); inv.add_item("iron_sword", 3); print(inv.get_quantity("iron_sword"))`.               | Prints `3`.                                                                                       |
| 5  | Run: `var inv = InventoryData.new(); inv.add_item("x", 2); print(inv.remove_item("x", 5))`.                              | Prints `false` (insufficient quantity).                                                           |
| 6  | Run: `var inv = InventoryData.new(); inv.add_item("a", 1); inv.add_item("b", 2); print(inv.list_all())`.                 | Prints array with two entries containing `item_id` and `qty` keys.                                |
| 7  | Run: `var inv = InventoryData.new(); inv.add_item("x", 5); var d = inv.to_dict(); var inv2 = InventoryData.new(); inv2.from_dict(d); print(inv2.get_quantity("x"))`. | Prints `5` (round-trip preservation).                                                             |
| 8  | Run: `var item = ItemDatabase.new().get_item("obsidian_charm"); print(item.get_rarity_color())`.                          | Prints the Legendary color value (orange — approximately `(1, 0.64, 0, 1)`).                      |
| 9  | Run: `var db = ItemDatabase.new(); var weapons = db.get_items_by_slot(Enums.EquipSlot.WEAPON); for w in weapons: print(w.id)`. | Prints all weapon ids. Each is a valid snake_case string.                                         |
| 10 | Run: `var db = ItemDatabase.new(); for item in db.get_all_items(): assert(item.id != ""); assert(item.display_name != "")`. | No assertion failures — all items have non-empty id and display_name.                             |

---

## 16. Implementation Prompt

Below is the complete, production-ready GDScript implementation for all three models. Copy each file verbatim into the specified path.

### 16.1 File: `src/models/item_data.gd`

```gdscript
class_name ItemData
extends RefCounted
## Immutable definition of a single game item.
## Constructed from a Dictionary of fields. Supports serialization via to_dict()/from_dict().

var id: String = ""
var display_name: String = ""
var rarity: Enums.ItemRarity = Enums.ItemRarity.COMMON
var slot: Enums.EquipSlot = Enums.EquipSlot.NONE
var is_equippable: bool = false
var stat_bonuses: Dictionary = {}
var sell_value: Dictionary = {}
var description: String = ""


func _init(data: Dictionary = {}) -> void:
    if data.is_empty():
        return
    id = str(data.get("id", ""))
    display_name = str(data.get("display_name", ""))
    rarity = int(data.get("rarity", Enums.ItemRarity.COMMON)) as Enums.ItemRarity
    slot = int(data.get("slot", Enums.EquipSlot.NONE)) as Enums.EquipSlot
    is_equippable = slot != Enums.EquipSlot.NONE
    stat_bonuses = _parse_dict(data.get("stat_bonuses", {}))
    sell_value = _parse_dict(data.get("sell_value", {}))
    description = str(data.get("description", ""))


## Returns the stat bonus for the given stat name, or 0 if absent.
func get_stat_bonus(stat_name: String) -> int:
    return int(stat_bonuses.get(stat_name, 0))


## Returns the sell value for the given currency, or 0 if absent.
func get_sell_value(currency: Enums.Currency) -> int:
    return int(sell_value.get(currency, 0))


## Returns the rarity color from GameConfig.RARITY_COLORS.
func get_rarity_color() -> Color:
    return GameConfig.RARITY_COLORS.get(rarity, Color.WHITE)


## Serializes this ItemData to a JSON-compatible Dictionary.
func to_dict() -> Dictionary:
    var sell_value_serialized: Dictionary = {}
    for currency_key in sell_value:
        sell_value_serialized[int(currency_key)] = int(sell_value[currency_key])
    return {
        "id": id,
        "display_name": display_name,
        "rarity": int(rarity),
        "slot": int(slot),
        "stat_bonuses": stat_bonuses.duplicate(),
        "sell_value": sell_value_serialized,
        "description": description,
    }


## Constructs an ItemData from a serialized Dictionary. Static factory method.
static func from_dict(data: Dictionary) -> ItemData:
    return ItemData.new(data)


## Internal helper to safely duplicate a Dictionary input.
func _parse_dict(input: Variant) -> Dictionary:
    if input is Dictionary:
        return input.duplicate()
    return {}
```

### 16.2 File: `src/models/item_database.gd`

```gdscript
class_name ItemDatabase
extends RefCounted
## Static registry of all item definitions in the game.
## Pre-populates with starter items on construction. Supports filtered queries.

var _items: Dictionary = {}


func _init() -> void:
    _build_starter_items()


## Returns the ItemData for the given id, or null if not found.
func get_item(id: String) -> ItemData:
    return _items.get(id, null)


## Returns true if the given item id exists in the registry.
func has_item(id: String) -> bool:
    return _items.has(id)


## Returns all items matching the given rarity tier.
func get_items_by_rarity(rarity: Enums.ItemRarity) -> Array[ItemData]:
    var result: Array[ItemData] = []
    for item: ItemData in _items.values():
        if item.rarity == rarity:
            result.append(item)
    return result


## Returns all items that equip to the given slot.
func get_items_by_slot(slot: Enums.EquipSlot) -> Array[ItemData]:
    var result: Array[ItemData] = []
    for item: ItemData in _items.values():
        if item.slot == slot:
            result.append(item)
    return result


## Returns all items where is_equippable is true.
func get_equippable_items() -> Array[ItemData]:
    var result: Array[ItemData] = []
    for item: ItemData in _items.values():
        if item.is_equippable:
            result.append(item)
    return result


## Returns all registered items as an array.
func get_all_items() -> Array[ItemData]:
    var result: Array[ItemData] = []
    for item: ItemData in _items.values():
        result.append(item)
    return result


## Returns the total number of registered item definitions.
func get_item_count() -> int:
    return _items.size()


## Registers a new item definition. Overwrites if id already exists.
func register_item(item: ItemData) -> void:
    if _items.has(item.id):
        push_warning("ItemDatabase: Overwriting existing item '%s'" % item.id)
    _items[item.id] = item


## Bulk-loads item definitions from a Dictionary of { id: { field_data } }.
func load_from_dict(data: Dictionary) -> void:
    for item_id: String in data:
        var item_dict: Dictionary = data[item_id]
        item_dict["id"] = item_id
        register_item(ItemData.new(item_dict))


## Internal helper to register an item from a raw data dictionary.
func _register_from_raw(data: Dictionary) -> void:
    register_item(ItemData.new(data))


## Builds the starter item set (~20 items across all rarity tiers and slots).
func _build_starter_items() -> void:
    # ===================================================================
    # WEAPONS (7)
    # ===================================================================
    _register_from_raw({
        "id": "wooden_sword",
        "display_name": "Wooden Sword",
        "rarity": Enums.ItemRarity.COMMON,
        "slot": Enums.EquipSlot.WEAPON,
        "stat_bonuses": { "attack": 2 },
        "sell_value": { Enums.Currency.GOLD: 3 },
        "description": "A crude wooden blade. Better than bare fists.",
    })
    _register_from_raw({
        "id": "iron_sword",
        "display_name": "Iron Sword",
        "rarity": Enums.ItemRarity.UNCOMMON,
        "slot": Enums.EquipSlot.WEAPON,
        "stat_bonuses": { "attack": 5 },
        "sell_value": { Enums.Currency.GOLD: 15 },
        "description": "A reliable iron blade favored by dungeon delvers.",
    })
    _register_from_raw({
        "id": "steel_blade",
        "display_name": "Steel Blade",
        "rarity": Enums.ItemRarity.RARE,
        "slot": Enums.EquipSlot.WEAPON,
        "stat_bonuses": { "attack": 9, "crit": 2 },
        "sell_value": { Enums.Currency.GOLD: 55 },
        "description": "Folded steel with a razor edge. Catches the light menacingly.",
    })
    _register_from_raw({
        "id": "crystal_saber",
        "display_name": "Crystal Saber",
        "rarity": Enums.ItemRarity.EPIC,
        "slot": Enums.EquipSlot.WEAPON,
        "stat_bonuses": { "attack": 14, "crit": 5, "speed": 2 },
        "sell_value": { Enums.Currency.GOLD: 180, Enums.Currency.ESSENCE: 10 },
        "description": "Grown from crystallized dungeon essence. Hums with latent power.",
    })
    _register_from_raw({
        "id": "wooden_staff",
        "display_name": "Wooden Staff",
        "rarity": Enums.ItemRarity.COMMON,
        "slot": Enums.EquipSlot.WEAPON,
        "stat_bonuses": { "attack": 1, "magic": 3 },
        "sell_value": { Enums.Currency.GOLD: 4 },
        "description": "A gnarled branch channeling faint magical energy.",
    })
    _register_from_raw({
        "id": "iron_staff",
        "display_name": "Iron Staff",
        "rarity": Enums.ItemRarity.UNCOMMON,
        "slot": Enums.EquipSlot.WEAPON,
        "stat_bonuses": { "attack": 2, "magic": 6 },
        "sell_value": { Enums.Currency.GOLD: 18 },
        "description": "Iron-shod staff topped with a focusing crystal.",
    })
    _register_from_raw({
        "id": "arcane_rod",
        "display_name": "Arcane Rod",
        "rarity": Enums.ItemRarity.RARE,
        "slot": Enums.EquipSlot.WEAPON,
        "stat_bonuses": { "magic": 12, "crit": 3 },
        "sell_value": { Enums.Currency.GOLD: 60, Enums.Currency.ESSENCE: 5 },
        "description": "Pulses with arcane sigils that shift when observed directly.",
    })
    # ===================================================================
    # ARMOR (7)
    # ===================================================================
    _register_from_raw({
        "id": "cloth_tunic",
        "display_name": "Cloth Tunic",
        "rarity": Enums.ItemRarity.COMMON,
        "slot": Enums.EquipSlot.ARMOR,
        "stat_bonuses": { "defense": 2 },
        "sell_value": { Enums.Currency.GOLD: 3 },
        "description": "Simple cloth offering minimal protection.",
    })
    _register_from_raw({
        "id": "leather_vest",
        "display_name": "Leather Vest",
        "rarity": Enums.ItemRarity.UNCOMMON,
        "slot": Enums.EquipSlot.ARMOR,
        "stat_bonuses": { "defense": 5 },
        "sell_value": { Enums.Currency.GOLD: 12 },
        "description": "Tough leather that turns aside glancing blows.",
    })
    _register_from_raw({
        "id": "chainmail",
        "display_name": "Chainmail",
        "rarity": Enums.ItemRarity.RARE,
        "slot": Enums.EquipSlot.ARMOR,
        "stat_bonuses": { "defense": 10, "hp": 15 },
        "sell_value": { Enums.Currency.GOLD: 65 },
        "description": "Interlocking iron rings. Heavy but dependable.",
    })
    _register_from_raw({
        "id": "dragon_plate",
        "display_name": "Dragon Plate",
        "rarity": Enums.ItemRarity.EPIC,
        "slot": Enums.EquipSlot.ARMOR,
        "stat_bonuses": { "defense": 18, "hp": 30, "speed": -3 },
        "sell_value": { Enums.Currency.GOLD: 200, Enums.Currency.FRAGMENTS: 8 },
        "description": "Forged from dragon scales. Nearly impenetrable, but cumbersome.",
    })
    _register_from_raw({
        "id": "cloth_robe",
        "display_name": "Cloth Robe",
        "rarity": Enums.ItemRarity.COMMON,
        "slot": Enums.EquipSlot.ARMOR,
        "stat_bonuses": { "defense": 1, "magic_def": 3 },
        "sell_value": { Enums.Currency.GOLD: 4 },
        "description": "A threadbare robe that offers some magical resistance.",
    })
    _register_from_raw({
        "id": "silk_robe",
        "display_name": "Silk Robe",
        "rarity": Enums.ItemRarity.UNCOMMON,
        "slot": Enums.EquipSlot.ARMOR,
        "stat_bonuses": { "defense": 2, "magic_def": 6 },
        "sell_value": { Enums.Currency.GOLD: 16 },
        "description": "Enchanted silk woven with protective wards.",
    })
    _register_from_raw({
        "id": "enchanted_mail",
        "display_name": "Enchanted Mail",
        "rarity": Enums.ItemRarity.RARE,
        "slot": Enums.EquipSlot.ARMOR,
        "stat_bonuses": { "defense": 8, "magic_def": 8, "hp": 10 },
        "sell_value": { Enums.Currency.GOLD: 70, Enums.Currency.ESSENCE: 4 },
        "description": "Chainmail infused with protective enchantments. Warm to the touch.",
    })
    # ===================================================================
    # ACCESSORIES (6)
    # ===================================================================
    _register_from_raw({
        "id": "copper_ring",
        "display_name": "Copper Ring",
        "rarity": Enums.ItemRarity.COMMON,
        "slot": Enums.EquipSlot.ACCESSORY,
        "stat_bonuses": { "hp": 5 },
        "sell_value": { Enums.Currency.GOLD: 3 },
        "description": "A simple copper band. Grants a small measure of vitality.",
    })
    _register_from_raw({
        "id": "silver_ring",
        "display_name": "Silver Ring",
        "rarity": Enums.ItemRarity.UNCOMMON,
        "slot": Enums.EquipSlot.ACCESSORY,
        "stat_bonuses": { "hp": 12, "magic_def": 2 },
        "sell_value": { Enums.Currency.GOLD: 18 },
        "description": "Polished silver etched with tiny protective runes.",
    })
    _register_from_raw({
        "id": "ruby_amulet",
        "display_name": "Ruby Amulet",
        "rarity": Enums.ItemRarity.RARE,
        "slot": Enums.EquipSlot.ACCESSORY,
        "stat_bonuses": { "attack": 4, "crit": 5 },
        "sell_value": { Enums.Currency.GOLD: 50, Enums.Currency.ESSENCE: 3 },
        "description": "A blood-red ruby set in gold. Sharpens the wearer's strikes.",
    })
    _register_from_raw({
        "id": "sapphire_pendant",
        "display_name": "Sapphire Pendant",
        "rarity": Enums.ItemRarity.RARE,
        "slot": Enums.EquipSlot.ACCESSORY,
        "stat_bonuses": { "magic": 6, "magic_def": 4 },
        "sell_value": { Enums.Currency.GOLD: 55, Enums.Currency.ESSENCE: 3 },
        "description": "Deep blue sapphire that amplifies magical resonance.",
    })
    _register_from_raw({
        "id": "emerald_brooch",
        "display_name": "Emerald Brooch",
        "rarity": Enums.ItemRarity.EPIC,
        "slot": Enums.EquipSlot.ACCESSORY,
        "stat_bonuses": { "hp": 25, "defense": 5, "magic_def": 5 },
        "sell_value": { Enums.Currency.GOLD: 150, Enums.Currency.FRAGMENTS: 5 },
        "description": "A brooch containing a flawless emerald. Radiates protective aura.",
    })
    _register_from_raw({
        "id": "obsidian_charm",
        "display_name": "Obsidian Charm",
        "rarity": Enums.ItemRarity.LEGENDARY,
        "slot": Enums.EquipSlot.ACCESSORY,
        "stat_bonuses": { "attack": 8, "magic": 8, "crit": 8, "speed": 5 },
        "sell_value": { Enums.Currency.GOLD: 500, Enums.Currency.ARTIFACTS: 2 },
        "description": "Carved from volcanic glass found at the heart of a dead dungeon. Whispers secrets to its bearer.",
    })
```

### 16.3 File: `src/models/inventory_data.gd`

```gdscript
class_name InventoryData
extends RefCounted
## Mutable inventory container mapping item ids to owned quantities.
## Supports add/remove/query operations and serialization for save/load.

var items: Dictionary = {}


## Adds the given quantity of an item. Creates entry if absent.
func add_item(item_id: String, qty: int) -> void:
    assert(qty > 0, "InventoryData.add_item: qty must be > 0, got %d" % qty)
    if items.has(item_id):
        items[item_id] = items[item_id] + qty
    else:
        items[item_id] = qty


## Removes the given quantity of an item. Returns false if insufficient.
## Erases the key entirely when remaining quantity reaches zero.
func remove_item(item_id: String, qty: int) -> bool:
    if not items.has(item_id):
        return false
    var current: int = items[item_id]
    if current < qty:
        return false
    var remaining: int = current - qty
    if remaining == 0:
        items.erase(item_id)
    else:
        items[item_id] = remaining
    return true


## Returns true if the owned quantity of the item is >= the requested amount.
func has_item(item_id: String, qty: int) -> bool:
    return items.get(item_id, 0) >= qty


## Returns the current quantity of the item, or 0 if not owned.
func get_quantity(item_id: String) -> int:
    return items.get(item_id, 0)


## Returns an array of { "item_id": String, "qty": int } for every owned item.
func list_all() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for item_id: String in items:
        result.append({ "item_id": item_id, "qty": items[item_id] })
    return result


## Returns the number of distinct item ids in the inventory.
func get_unique_item_count() -> int:
    return items.size()


## Returns the sum of all item quantities.
func get_total_item_count() -> int:
    var total: int = 0
    for qty: int in items.values():
        total += qty
    return total


## Removes all items from the inventory.
func clear() -> void:
    items.clear()


## Serializes the inventory to a JSON-compatible Dictionary.
func to_dict() -> Dictionary:
    return { "items": items.duplicate() }


## Restores the inventory from a serialized Dictionary. Clears existing state first.
func from_dict(data: Dictionary) -> void:
    items.clear()
    var loaded_items: Variant = data.get("items", {})
    if loaded_items is Dictionary:
        for item_id: String in loaded_items:
            var qty: int = int(loaded_items[item_id])
            if qty > 0:
                items[item_id] = qty
            else:
                push_warning("InventoryData.from_dict: Skipping non-positive qty for '%s': %d" % [item_id, qty])


## Combines another inventory into this one additively. Does not modify the source.
func merge(other: InventoryData) -> void:
    for item_id: String in other.items:
        add_item(item_id, other.items[item_id])
```

---

*End of TASK-007: Item, Equipment & Inventory Data Models*

