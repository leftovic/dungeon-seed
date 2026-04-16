## src/ui/adventurer_ui.gd
## Logic controller for Adventurer Hall & Inventory UI screens.
## Provides headless-testable data formatting for roster grid, adventurer detail,
## inventory list, equip validation, and stat comparison views.
##
## Depends on: AdventurerRoster, EquipmentManager, InventoryData, Wallet, ItemDatabase
extends RefCounted


# ---------------------------------------------------------------------------
# Name Lookup Tables
# ---------------------------------------------------------------------------

## Maps AdventurerClass enum int values to display strings.
const CLASS_NAMES: Dictionary = {
	0: "Warrior",   # AdventurerClass.WARRIOR
	1: "Ranger",    # AdventurerClass.RANGER
	2: "Mage",      # AdventurerClass.MAGE
	3: "Rogue",     # AdventurerClass.ROGUE
	4: "Alchemist", # AdventurerClass.ALCHEMIST
	5: "Sentinel",  # AdventurerClass.SENTINEL
}

## Maps AdventurerCondition int values to display strings.
## Condition enum may not exist on all AdventurerData instances yet — defaults to 0.
const CONDITION_NAMES: Dictionary = {
	0: "Healthy",
	1: "Fatigued",
	2: "Injured",
	3: "Exhausted",
}

## Maps Element enum int values to display strings.
const ELEMENT_NAMES: Dictionary = {
	0: "Terra",
	1: "Flame",
	2: "Frost",
	3: "Arcane",
	4: "Shadow",
	5: "None",
}

## Maps EquipSlot enum int values to AdventurerData.equipment dictionary keys.
const SLOT_KEYS: Dictionary = {
	0: "weapon",    # EquipSlot.WEAPON
	1: "armor",     # EquipSlot.ARMOR
	2: "accessory", # EquipSlot.ACCESSORY
}


# ---------------------------------------------------------------------------
# Internal State
# ---------------------------------------------------------------------------

var _roster: RefCounted
var _equipment_mgr: RefCounted
var _inventory: RefCounted
var _wallet: RefCounted
var _item_db: RefCounted
var _initialized: bool = false


# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------

## Stores references to all required services.
## item_db is optional but required for inventory display names, can_equip,
## and stat comparison features.
func initialize(
	roster: RefCounted,
	equipment_mgr: RefCounted,
	inventory: RefCounted,
	wallet: RefCounted,
	item_db: RefCounted = null
) -> void:
	_roster = roster
	_equipment_mgr = equipment_mgr
	_inventory = inventory
	_wallet = wallet
	_item_db = item_db
	_initialized = true


# ---------------------------------------------------------------------------
# Roster Display (grid view)
# ---------------------------------------------------------------------------

## Returns an Array of display-ready dictionaries for every adventurer in the roster.
## Each entry contains: id, name, class, class_name, level, condition, condition_name,
## element, element_name, is_available.
func get_roster_display() -> Array:
	if not _initialized or _roster == null:
		return []
	var result: Array = []
	var adventurers: Array = _roster.get_all_adventurers()
	for adv in adventurers:
		if adv == null:
			continue
		var cls_val: int = int(adv.adventurer_class)
		var cond_val: int = _read_condition(adv)
		var elem_val: int = _read_element(adv)
		result.append({
			"id": str(adv.id),
			"name": str(adv.display_name),
			"class": cls_val,
			"class_name": get_class_name_str(cls_val),
			"level": int(adv.level),
			"condition": cond_val,
			"condition_name": get_condition_name_str(cond_val),
			"element": elem_val,
			"element_name": get_element_name_str(elem_val),
			"is_available": bool(adv.is_available),
		})
	return result


# ---------------------------------------------------------------------------
# Adventurer Detail (full info panel)
# ---------------------------------------------------------------------------

## Returns a comprehensive detail dictionary for one adventurer, or {} if not found.
## Stats include equipment bonuses when EquipmentManager + ItemDatabase are available.
func get_adventurer_detail(id: String) -> Dictionary:
	if not _initialized or _roster == null:
		return {}
	var adv = _roster.get_adventurer(id)
	if adv == null:
		return {}

	var cls_val: int = int(adv.adventurer_class)
	var cond_val: int = _read_condition(adv)
	var elem_val: int = _read_element(adv)

	# Effective stats — base + equipment bonuses when possible
	var stats: Dictionary = {}
	if _equipment_mgr != null and _item_db != null:
		stats = _equipment_mgr.calculate_effective_stats(adv, _item_db)
	else:
		stats = adv.get_effective_stats()

	# Equipment summary — slot keys to item_id or null
	var equipment: Dictionary = {"weapon": null, "armor": null, "accessory": null}
	if _equipment_mgr != null:
		equipment = _equipment_mgr.get_equipment_summary(adv)

	return {
		"id": str(adv.id),
		"name": str(adv.display_name),
		"class": cls_val,
		"class_name": get_class_name_str(cls_val),
		"level": int(adv.level),
		"xp": int(adv.xp),
		"xp_to_next": int(adv.xp_to_next_level()),
		"condition": cond_val,
		"condition_name": get_condition_name_str(cond_val),
		"element": elem_val,
		"element_name": get_element_name_str(elem_val),
		"stats": stats,
		"equipment": equipment,
	}


# ---------------------------------------------------------------------------
# Inventory Display
# ---------------------------------------------------------------------------

## Returns an Array of display-ready dictionaries for every item stack in the inventory.
## Each entry: item_id, quantity, display_name (resolved from ItemDatabase or raw id).
func get_inventory_display() -> Array:
	if not _initialized or _inventory == null:
		return []
	var result: Array = []
	var entries: Array = _inventory.list_all()
	for entry in entries:
		var item_id: String = str(entry.get("item_id", ""))
		var qty: int = int(entry.get("qty", 0))
		var display_name: String = _resolve_item_name(item_id)
		result.append({
			"item_id": item_id,
			"quantity": qty,
			"display_name": display_name,
		})
	return result


# ---------------------------------------------------------------------------
# Equip Validation
# ---------------------------------------------------------------------------

## Checks whether the adventurer can equip the given item.
## Returns { "can_equip": bool, "reason": String }.
func can_equip(adventurer_id: String, item_id: String) -> Dictionary:
	if not _initialized:
		return {"can_equip": false, "reason": "Not initialized"}
	if _roster == null:
		return {"can_equip": false, "reason": "No roster"}

	var adv = _roster.get_adventurer(adventurer_id)
	if adv == null:
		return {"can_equip": false, "reason": "Adventurer not found"}

	if _item_db == null:
		return {"can_equip": false, "reason": "No item database"}

	var item = _item_db.get_item(item_id)
	if item == null:
		return {"can_equip": false, "reason": "Item not found"}

	if not item.is_equippable:
		return {"can_equip": false, "reason": "Item is not equippable"}

	# Check inventory ownership when inventory is available
	if _inventory != null and not _inventory.has_item(item_id, 1):
		return {"can_equip": false, "reason": "Item not in inventory"}

	return {"can_equip": true, "reason": ""}


# ---------------------------------------------------------------------------
# Stat Comparison
# ---------------------------------------------------------------------------

## Computes a before/after stat comparison for equipping an item.
## Temporarily swaps equipment to calculate projected stats, then restores.
## Returns { "current_stats": Dict, "new_stats": Dict, "changes": Dict }.
func get_stat_comparison(adventurer_id: String, item_id: String) -> Dictionary:
	var empty: Dictionary = {"current_stats": {}, "new_stats": {}, "changes": {}}
	if not _initialized or _roster == null or _item_db == null or _equipment_mgr == null:
		return empty

	var adv = _roster.get_adventurer(adventurer_id)
	if adv == null:
		return empty

	var item = _item_db.get_item(item_id)
	if item == null or not item.is_equippable:
		return empty

	var slot_key: String = SLOT_KEYS.get(int(item.slot), "")
	if slot_key.is_empty():
		return empty

	# Snapshot current effective stats
	var current_stats: Dictionary = _equipment_mgr.calculate_effective_stats(adv, _item_db)

	# Temporarily swap equipment to compute projected stats
	var saved_item = adv.equipment.get(slot_key)
	adv.equipment[slot_key] = item_id
	var new_stats: Dictionary = _equipment_mgr.calculate_effective_stats(adv, _item_db)
	adv.equipment[slot_key] = saved_item  # Restore original

	# Compute deltas for every stat that appears in either dictionary
	var changes: Dictionary = {}
	var all_keys: Dictionary = {}
	for k in current_stats:
		all_keys[k] = true
	for k in new_stats:
		all_keys[k] = true
	for k in all_keys:
		var cur: int = int(current_stats.get(k, 0))
		var nxt: int = int(new_stats.get(k, 0))
		if nxt != cur:
			changes[k] = nxt - cur

	return {"current_stats": current_stats, "new_stats": new_stats, "changes": changes}


# ---------------------------------------------------------------------------
# Enum Display Helpers
# ---------------------------------------------------------------------------

## Returns the human-readable name for an AdventurerClass int value.
func get_class_name_str(cls: int) -> String:
	return CLASS_NAMES.get(cls, "Unknown")


## Returns the human-readable name for a condition int value.
func get_condition_name_str(condition: int) -> String:
	return CONDITION_NAMES.get(condition, "Unknown")


## Returns the human-readable name for an Element int value.
func get_element_name_str(element: int) -> String:
	return ELEMENT_NAMES.get(element, "Unknown")


# ---------------------------------------------------------------------------
# XP Bar Data
# ---------------------------------------------------------------------------

## Returns XP progress data for rendering XP bars.
## Returns { "current_xp": int, "xp_to_next": int, "progress": float 0.0-1.0, "level": int }.
func get_xp_bar_data(adventurer_id: String) -> Dictionary:
	var fallback: Dictionary = {"current_xp": 0, "xp_to_next": 0, "progress": 0.0, "level": 0}
	if not _initialized or _roster == null:
		return fallback

	var adv = _roster.get_adventurer(adventurer_id)
	if adv == null:
		return fallback

	var xp_needed: int = int(adv.xp_to_next_level())
	var progress: float = 0.0
	if xp_needed > 0:
		progress = float(adv.xp) / float(xp_needed)

	return {
		"current_xp": int(adv.xp),
		"xp_to_next": xp_needed,
		"progress": progress,
		"level": int(adv.level),
	}


# ---------------------------------------------------------------------------
# Private Helpers
# ---------------------------------------------------------------------------

## Reads the condition property from an adventurer, defaulting to 0 (Healthy).
## AdventurerData may not have this property yet; Object.get() returns null if absent.
func _read_condition(adv: RefCounted) -> int:
	var val = adv.get("condition")
	if val != null:
		return int(val)
	return 0


## Reads the element property from an adventurer, defaulting to 5 (Element.NONE).
## AdventurerData may not have this property yet; Object.get() returns null if absent.
func _read_element(adv: RefCounted) -> int:
	var val = adv.get("element")
	if val != null:
		return int(val)
	return 5


## Resolves an item_id to its display name via the item database.
## Falls back to the raw item_id string if the database is unavailable or the item unknown.
func _resolve_item_name(item_id: String) -> String:
	if _item_db != null:
		var item = _item_db.get_item(item_id)
		if item != null:
			return str(item.display_name)
	return item_id
