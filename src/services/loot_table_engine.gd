extends RefCounted
class_name LootTableEngine
## Deterministic loot table engine for weighted drop resolution.
##
## Manages loot table registration, weighted random selection, rarity filtering,
## and currency drop calculation. All randomness flows through DeterministicRNG
## to ensure reproducibility.
##
## Usage:
##   var engine := LootTableEngine.new()
##   engine.register_table("combat_common", COMBAT_COMMON_ENTRIES)
##   var drops: Array[Dictionary] = engine.roll("combat_common", rng, 2)
##   var currency: Dictionary = engine.roll_currency(Enums.RoomType.COMBAT, 5, rng)
##
## Depends on: DeterministicRNG, Enums, ItemDatabase

## Maximum number of items that can be rolled in a single call
const MAX_ROLL_COUNT: int = 100

## Maximum number of retries for rarity-filtered rolls
const MAX_RARITY_RETRIES: int = 100

## Base gold amount before multipliers
const BASE_GOLD: int = 10

## Difficulty scaling factor per level
const DIFFICULTY_SCALE: float = 0.15

## Variance range for currency rolls (±20%)
const VARIANCE_RANGE: float = 0.2

## Base essence multiplier
const ESSENCE_BASE_MULT: float = 0.5

## Boss room essence multiplier
const BOSS_ESSENCE_MULT: float = 2.0

## Treasure room essence multiplier
const TREASURE_ESSENCE_MULT: float = 1.0

## Room type currency multipliers
const ROOM_CURRENCY_MULT: Dictionary = {
	Enums.RoomType.COMBAT: 1.0,
	Enums.RoomType.TREASURE: 2.5,
	Enums.RoomType.TRAP: 0.3,
	Enums.RoomType.PUZZLE: 1.5,
	Enums.RoomType.REST: 0.0,
	Enums.RoomType.BOSS: 3.0,
	Enums.RoomType.ENTRANCE: 0.0,
	Enums.RoomType.SECRET: 2.0,
}

## Internal storage for registered loot tables
## Format: { table_id: String -> Array[Dictionary] }
var _tables: Dictionary = {}


## Registers a loot table for later retrieval.
## Each entry must contain: item_id (String), weight (int > 0),
## min_qty (int >= 1), max_qty (int >= min_qty).
## Invalid entries are skipped with a warning.
## Overwrites any previously registered table with the same ID.
func register_table(table_id: String, entries: Array[Dictionary]) -> void:
	var valid_entries: Array[Dictionary] = []
	
	for entry: Dictionary in entries:
		if not _validate_entry(entry):
			continue
		valid_entries.append(entry)
	
	_tables[table_id] = valid_entries


## Returns a copy of the registered table entries, or empty array if not found.
func get_table(table_id: String) -> Array[Dictionary]:
	if not _tables.has(table_id):
		return []
	
	var result: Array[Dictionary] = []
	for entry: Dictionary in _tables[table_id]:
		result.append(entry.duplicate())
	return result


## Returns true if the table is registered.
func has_table(table_id: String) -> bool:
	return _tables.has(table_id)


## Rolls N items from the specified table using weighted selection.
## Returns an array of { "item_id": String, "qty": int } dictionaries.
## Returns empty array if table doesn't exist or is empty.
## Count is clamped to [1, MAX_ROLL_COUNT].
func roll(table_id: String, rng: DeterministicRNG, count: int = 1) -> Array[Dictionary]:
	if rng == null:
		push_error("LootTableEngine.roll: rng parameter is null")
		return []
	
	if not _tables.has(table_id):
		push_warning("LootTableEngine.roll: table '%s' not found" % table_id)
		return []
	
	var entries: Array[Dictionary] = _tables[table_id]
	if entries.is_empty():
		return []
	
	# Clamp count to valid range
	var clamped_count: int = clampi(count, 1, MAX_ROLL_COUNT)
	
	var drops: Array[Dictionary] = []
	for i in range(clamped_count):
		var entry: Dictionary = _weighted_pick_entry(entries, rng)
		if entry.is_empty():
			continue
		
		var qty: int = _resolve_quantity(entry, rng)
		drops.append({
			"item_id": entry.item_id,
			"qty": qty
		})
	
	return drops


## Rolls items from the table, filtering by minimum rarity.
## Retries up to MAX_RARITY_RETRIES times until a qualifying item is found.
## Returns a single-element array with the drop, or empty array if no qualifying item found.
## Requires ItemDatabase to check item rarities.
func roll_with_rarity_filter(
	table_id: String,
	rng: DeterministicRNG,
	min_rarity: Enums.ItemRarity,
	item_db: ItemDatabase
) -> Array[Dictionary]:
	if rng == null:
		push_error("LootTableEngine.roll_with_rarity_filter: rng parameter is null")
		return []
	
	if item_db == null:
		push_error("LootTableEngine.roll_with_rarity_filter: item_db parameter is null")
		return []
	
	if not _tables.has(table_id):
		push_warning("LootTableEngine.roll_with_rarity_filter: table '%s' not found" % table_id)
		return []
	
	for attempt in range(MAX_RARITY_RETRIES):
		var drops: Array[Dictionary] = roll(table_id, rng, 1)
		if drops.is_empty():
			return []
		
		var drop: Dictionary = drops[0]
		var item: ItemData = item_db.get_item(drop.item_id)
		
		# If item not found, count as failed retry
		if item == null:
			continue
		
		# Check if rarity meets threshold
		if item.rarity >= min_rarity:
			return [drop]
	
	# Max retries exceeded
	return []


## Calculates currency drops for a room based on type, difficulty, and RNG variance.
## Returns a dictionary of { Enums.Currency -> int } mappings.
## REST rooms return empty dictionary.
## BOSS and TREASURE rooms also grant Essence.
func roll_currency(room_type: Enums.RoomType, difficulty: int, rng: DeterministicRNG) -> Dictionary:
	if rng == null:
		push_error("LootTableEngine.roll_currency: rng parameter is null")
		return {}
	
	# REST and ENTRANCE rooms give no currency
	if room_type == Enums.RoomType.REST or room_type == Enums.RoomType.ENTRANCE:
		return {}
	
	# Clamp difficulty to [1, 10]
	var clamped_difficulty: int = clampi(difficulty, 1, 10)
	
	# Calculate difficulty multiplier: 1.0 + (difficulty - 1) * 0.15
	var difficulty_mult: float = 1.0 + (clamped_difficulty - 1) * DIFFICULTY_SCALE
	
	# Get room type multiplier
	var room_mult: float = _get_room_currency_mult(room_type)
	
	# Calculate base gold
	var base_gold: float = BASE_GOLD * difficulty_mult * room_mult
	
	# Apply variance (±20%)
	var variance: float = 1.0 + (rng.randf() * 2.0 - 1.0) * VARIANCE_RANGE
	var final_gold: int = maxi(0, int(base_gold * variance))
	
	var result: Dictionary = {
		Enums.Currency.GOLD: final_gold
	}
	
	# Add Essence for BOSS and TREASURE rooms
	if room_type == Enums.RoomType.BOSS:
		var essence: int = maxi(0, int(BASE_GOLD * difficulty_mult * BOSS_ESSENCE_MULT * ESSENCE_BASE_MULT))
		result[Enums.Currency.ESSENCE] = essence
	elif room_type == Enums.RoomType.TREASURE:
		var essence: int = maxi(0, int(BASE_GOLD * difficulty_mult * TREASURE_ESSENCE_MULT * ESSENCE_BASE_MULT))
		result[Enums.Currency.ESSENCE] = essence
	
	return result


# ---------------------------------------------------------------------------
# Private Helpers
# ---------------------------------------------------------------------------

## Validates a loot table entry has all required fields with valid values.
func _validate_entry(entry: Dictionary) -> bool:
	# Check required fields exist
	if not entry.has("item_id"):
		push_warning("LootTableEngine: entry missing 'item_id'")
		return false
	
	if not entry.has("weight"):
		push_warning("LootTableEngine: entry missing 'weight'")
		return false
	
	if not entry.has("min_qty"):
		push_warning("LootTableEngine: entry missing 'min_qty'")
		return false
	
	if not entry.has("max_qty"):
		push_warning("LootTableEngine: entry missing 'max_qty'")
		return false
	
	# Validate types and ranges
	var weight: int = int(entry.weight)
	if weight <= 0:
		push_warning("LootTableEngine: entry has weight <= 0")
		return false
	
	var min_qty: int = int(entry.min_qty)
	if min_qty < 1:
		push_warning("LootTableEngine: entry has min_qty < 1")
		return false
	
	var max_qty: int = int(entry.max_qty)
	if max_qty < min_qty:
		push_warning("LootTableEngine: entry has max_qty < min_qty")
		return false
	
	return true


## Performs weighted random selection from entries.
## Uses cumulative weight sum algorithm.
func _weighted_pick_entry(entries: Array[Dictionary], rng: DeterministicRNG) -> Dictionary:
	if entries.is_empty():
		return {}
	
	# Calculate total weight
	var total_weight: float = 0.0
	for entry: Dictionary in entries:
		total_weight += float(entry.weight)
	
	if total_weight <= 0.0:
		return {}
	
	# Roll random value in [0, total_weight)
	var roll: float = rng.randf() * total_weight
	
	# Find first entry where cumulative weight exceeds roll
	var cumulative: float = 0.0
	for entry: Dictionary in entries:
		cumulative += float(entry.weight)
		if roll < cumulative:
			return entry
	
	# Floating-point edge case: return last entry
	return entries[entries.size() - 1]


## Resolves quantity from entry's min_qty/max_qty range.
func _resolve_quantity(entry: Dictionary, rng: DeterministicRNG) -> int:
	var min_qty: int = int(entry.min_qty)
	var max_qty: int = int(entry.max_qty)
	return rng.randi_range(min_qty, max_qty)


## Returns the currency multiplier for the given room type.
func _get_room_currency_mult(room_type: Enums.RoomType) -> float:
	if ROOM_CURRENCY_MULT.has(room_type):
		return ROOM_CURRENCY_MULT[room_type]
	return 1.0
