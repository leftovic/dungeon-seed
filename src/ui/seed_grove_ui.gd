extends Control
## Seed Grove UI — Garden hub display controller for Dungeon Seed.
##
## Transforms raw game state from SeedGrove and Wallet into structured
## display data dictionaries for garden plots, growth progress, seed cards,
## and resource bars. Designed as a headless-testable logic controller
## that works without scene tree nodes.
##
## Dependencies (duck-typed):
##   grove: get_planted_seeds() -> Array, max_grove_slots: int
##   wallet: get_balance(currency: Enums.Currency) -> int
##
## @file src/ui/seed_grove_ui.gd
## @task TASK-018


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

## Species display names keyed by Enums.Element int value.
const SPECIES_NAMES: Dictionary = {
	0: "Terra Seed",
	1: "Flame Seed",
	2: "Frost Seed",
	3: "Arcane Seed",
	4: "Shadow Seed",
	5: "Wild Seed",
}

## Currency display names keyed by Enums.Currency int value.
const CURRENCY_NAMES: Dictionary = {
	0: "Gold",
	1: "Verdant Essence",
	2: "Materials",
	3: "Guild Favor",
}

## Maximum number of garden plot slots the UI can display.
const MAX_DISPLAY_SLOTS: int = 5


# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _grove = null
var _wallet = null
var _initialized: bool = false


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Initialize with service references.
## @param grove: SeedGrove-compatible (get_planted_seeds(), max_grove_slots)
## @param wallet: Wallet-compatible (get_balance(currency))
func initialize(grove: RefCounted, wallet: RefCounted) -> void:
	_grove = grove
	_wallet = wallet
	_initialized = true


## Build and return full display state for the entire garden.
## Returns dict with "slots" array and "wallet" balances.
func refresh() -> Dictionary:
	if not _initialized or _grove == null or _wallet == null:
		return {"slots": [], "wallet": _empty_wallet()}

	var planted = _grove.get_planted_seeds()
	var max_slots: int = mini(int(_grove.max_grove_slots), MAX_DISPLAY_SLOTS)
	var slots: Array = []

	for i in range(max_slots):
		if i < planted.size():
			slots.append(_seed_to_display(i, planted[i]))
		else:
			slots.append(_empty_slot(i))

	return {
		"slots": slots,
		"wallet": _wallet_display(),
	}


## Get display data for a specific slot index.
func get_slot_display(slot: int) -> Dictionary:
	if not _initialized or _grove == null:
		return _empty_slot(slot)

	var max_slots: int = mini(int(_grove.max_grove_slots), MAX_DISPLAY_SLOTS)
	if slot < 0 or slot >= max_slots:
		return _empty_slot(slot)

	var planted = _grove.get_planted_seeds()
	if slot < planted.size():
		return _seed_to_display(slot, planted[slot])

	return _empty_slot(slot)


## Get the action available for a slot.
## Returns: "plant" (empty valid), "inspect" (growing), "harvest" (bloom), "empty" (invalid)
func get_slot_action(slot: int) -> String:
	if not _initialized or _grove == null:
		return "empty"

	var max_slots: int = mini(int(_grove.max_grove_slots), MAX_DISPLAY_SLOTS)
	if slot < 0 or slot >= max_slots:
		return "empty"

	var planted = _grove.get_planted_seeds()
	if slot >= planted.size():
		return "plant"

	var seed = planted[slot]
	if seed.phase == Enums.SeedPhase.BLOOM:
		return "harvest"

	return "inspect"


## Format seconds remaining into a human-readable timer string.
## Returns: "2h 15m", "45m 30s", "30s", or "Ready!"
func format_timer(seconds_remaining: float) -> String:
	if seconds_remaining <= 0.0:
		return "Ready!"

	var total_sec: int = ceili(seconds_remaining)
	var hours: int = total_sec / 3600
	var minutes: int = (total_sec % 3600) / 60
	var secs: int = total_sec % 60

	if hours > 0:
		return "%dh %dm" % [hours, minutes]
	if minutes > 0:
		return "%dm %ds" % [minutes, secs]
	return "%ds" % secs


## Format a resource amount with its currency display name.
## @param currency: Enums.Currency int value (0=Gold, 1=Essence, 2=Fragments, 3=Artifacts)
## @param amount: The balance amount
func format_resource(currency: int, amount: int) -> String:
	var display_name: String = CURRENCY_NAMES.get(currency, "Unknown")
	return "%s %s" % [_format_number(amount), display_name]


# ---------------------------------------------------------------------------
# Private Helpers
# ---------------------------------------------------------------------------

## Build display dict for an occupied slot.
func _seed_to_display(index: int, seed) -> Dictionary:
	var mutations: Array = []
	for ms in seed.mutation_slots:
		if not ms.is_empty():
			mutations.append(ms.reagent_id)

	return {
		"index": index,
		"occupied": true,
		"seed_species": SPECIES_NAMES.get(int(seed.element), "Unknown Seed"),
		"element": int(seed.element),
		"rarity": int(seed.rarity),
		"vigor": int(seed.mutation_potential * 100),
		"growth_stage": int(seed.phase),
		"growth_progress": seed.get_overall_progress(),
		"mutations": mutations,
		"is_ready": seed.phase == Enums.SeedPhase.BLOOM,
	}


## Build display dict for an empty/invalid slot.
func _empty_slot(index: int) -> Dictionary:
	return {
		"index": index,
		"occupied": false,
		"seed_species": "",
		"element": int(Enums.Element.NONE),
		"rarity": int(Enums.SeedRarity.COMMON),
		"vigor": 0,
		"growth_stage": int(Enums.SeedPhase.SPORE),
		"growth_progress": 0.0,
		"mutations": [],
		"is_ready": false,
	}


## Build wallet display dict from current balances.
func _wallet_display() -> Dictionary:
	if _wallet == null:
		return _empty_wallet()
	return {
		"gold": _wallet.get_balance(Enums.Currency.GOLD),
		"verdant_essence": _wallet.get_balance(Enums.Currency.ESSENCE),
		"materials": _wallet.get_balance(Enums.Currency.FRAGMENTS),
		"guild_favor": _wallet.get_balance(Enums.Currency.ARTIFACTS),
	}


## Default zero-balance wallet display dict.
func _empty_wallet() -> Dictionary:
	return {
		"gold": 0,
		"verdant_essence": 0,
		"materials": 0,
		"guild_favor": 0,
	}


## Format an integer with comma-separated thousands.
## Example: 1500 -> "1,500", 1000000 -> "1,000,000"
func _format_number(value: int) -> String:
	if value < 0:
		return "-" + _format_number(-value)
	var text: String = str(value)
	if text.length() <= 3:
		return text
	var result: String = ""
	var count: int = 0
	for i in range(text.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = text[i] + result
		count += 1
	return result
