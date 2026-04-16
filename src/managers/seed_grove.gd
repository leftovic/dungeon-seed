class_name SeedGrove
extends Node
## Central seed management system for Dungeon Seed.
##
## Manages all planted and unplanted seeds, advances growth every tick,
## handles mutation application, and exposes query methods for downstream
## systems (Core Loop Orchestrator, Seed Grove UI, Expedition Launcher).
##
## Key responsibilities:
## - Seed inventory (add, remove, query by ID)
## - Planting/uprooting with grove slot limits
## - Growth tick loop advancing all planted seeds
## - Spontaneous mutation rolls on phase transitions
## - Reagent application to mutation slots
## - Expedition readiness checks
## - Serialization for save/load
##
## Usage:
##   var grove := SeedGrove.new()
##   grove.rng = DeterministicRNG.new()
##   grove.rng.seed_string("test-grove")
##   var seed := grove.create_seed(Enums.SeedRarity.COMMON, Enums.Element.TERRA, grove.rng)
##   grove.add_seed(seed)
##   grove.plant_seed(seed)
##   var events := grove.tick(60.0)
##
## @file src/managers/seed_grove.gd
## @brief Central seed management system
## @task TASK-012


# ---------------------------------------------------------------------------
# Properties
# ---------------------------------------------------------------------------

## All seeds managed by this grove (planted + unplanted inventory).
var seeds: Array[SeedData] = []

## Maximum number of concurrently planted seeds. Expandable via upgrades.
var max_grove_slots: int = 3

## Deterministic RNG for mutation rolls. Injected externally.
var rng: DeterministicRNG = null


# ---------------------------------------------------------------------------
# Computed Properties
# ---------------------------------------------------------------------------

## Number of currently planted seeds. Computed from seeds array.
var planted_count: int:
	get:
		return get_planted_seeds().size()


# ---------------------------------------------------------------------------
# Inventory Management
# ---------------------------------------------------------------------------

## Adds a seed to the grove inventory (unplanted).
## Does NOT automatically plant the seed.
##
## @param seed: The SeedData instance to add.
func add_seed(seed: SeedData) -> void:
	seeds.append(seed)


## Finds and returns a seed by its unique ID.
## Returns null if no seed with the given ID exists.
##
## @param seed_id: The unique identifier of the seed.
## @return: The SeedData instance, or null if not found.
func get_seed_by_id(seed_id: String) -> SeedData:
	for seed in seeds:
		if seed.id == seed_id:
			return seed
	return null


## Removes a seed from the grove by ID.
## If the seed is planted, it is uprooted first.
## Returns the removed seed, or null if not found.
##
## @param seed_id: The unique identifier of the seed to remove.
## @return: The removed SeedData instance, or null if not found.
func remove_seed(seed_id: String) -> SeedData:
	var seed := get_seed_by_id(seed_id)
	if seed == null:
		return null
	
	# Uproot first if planted
	if seed.is_planted:
		uproot_seed(seed_id)
	
	seeds.erase(seed)
	return seed


## Returns the total number of seeds in the grove (planted + unplanted).
##
## @return: The count of all seeds.
func get_seed_count() -> int:
	return seeds.size()


# ---------------------------------------------------------------------------
# Planting and Uprooting
# ---------------------------------------------------------------------------

## Plants a seed in an available grove slot.
## Returns true on success, false if planting failed.
##
## Failure conditions:
## - All grove slots are full (planted_count >= max_grove_slots)
## - Seed is already planted (is_planted == true)
## - Seed is not in this grove's inventory
##
## On success:
## - Sets seed.is_planted = true
## - Sets seed.planted_at to current engine time
## - Resets seed.phase to SPORE
## - Resets seed.growth_progress to 0.0
## - Emits EventBus.seed_planted signal
##
## @param seed: The SeedData instance to plant.
## @return: True if planting succeeded, false otherwise.
func plant_seed(seed: SeedData) -> bool:
	# Guard: grove full
	if planted_count >= max_grove_slots:
		return false
	
	# Guard: already planted
	if seed.is_planted:
		return false
	
	# Guard: seed not in grove
	if not seeds.has(seed):
		return false
	
	# Plant the seed
	var slot_index: int = planted_count
	var timestamp: float = Time.get_ticks_msec() / 1000.0
	seed.plant(timestamp)
	seed.phase = Enums.SeedPhase.SPORE
	seed.growth_progress = 0.0
	
	# Emit signal (check if EventBus exists and has the signal)
	if EventBus != null and EventBus.has_signal("seed_planted"):
		EventBus.seed_planted.emit(seed.id, slot_index)
	
	return true


## Uproots a planted seed, resetting its growth to SPORE phase.
## Returns the seed instance, or null if not found or not planted.
##
## The seed remains in the grove inventory after uprooting (not removed).
##
## Effects:
## - Resets seed.is_planted to false
## - Resets seed.phase to SPORE
## - Resets seed.growth_progress to 0.0
## - Does NOT emit a signal
##
## @param seed_id: The unique identifier of the seed to uproot.
## @return: The uprooted SeedData instance, or null if not found/unplanted.
func uproot_seed(seed_id: String) -> SeedData:
	var seed := get_seed_by_id(seed_id)
	if seed == null:
		return null
	
	if not seed.is_planted:
		return null
	
	# Uproot the seed
	seed.is_planted = false
	seed.phase = Enums.SeedPhase.SPORE
	seed.growth_progress = 0.0
	seed.planted_at = 0.0
	
	return seed


## Returns all planted seeds in the grove.
##
## @return: Array of SeedData instances where is_planted == true.
func get_planted_seeds() -> Array[SeedData]:
	var result: Array[SeedData] = []
	for seed in seeds:
		if seed.is_planted:
			result.append(seed)
	return result


## Returns all unplanted seeds in the grove inventory.
##
## @return: Array of SeedData instances where is_planted == false.
func get_unplanted_seeds() -> Array[SeedData]:
	var result: Array[SeedData] = []
	for seed in seeds:
		if not seed.is_planted:
			result.append(seed)
	return result


## Returns the number of available grove slots for planting.
##
## @return: The number of free slots (max_grove_slots - planted_count).
func get_available_slots() -> int:
	return max_grove_slots - planted_count


# ---------------------------------------------------------------------------
# Growth Tick
# ---------------------------------------------------------------------------

## Advances growth for all planted seeds by delta seconds.
## Detects phase transitions, performs spontaneous mutation rolls,
## emits signals, and returns an array of event dictionaries.
##
## Event dictionary format:
##   {
##     "seed_id": String,
##     "event": String,  # "phase_changed", "bloom_reached", "mutated"
##     "data": Dictionary
##   }
##
## @param delta: Time in seconds to advance growth.
## @return: Array of event dictionaries describing what happened.
func tick(delta: float) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	
	if delta <= 0.0:
		return events
	
	var planted := get_planted_seeds()
	for seed in planted:
		# Skip seeds already in BLOOM
		if seed.phase == Enums.SeedPhase.BLOOM:
			continue
		
		# Store old phase and advance
		var old_phase: Enums.SeedPhase = seed.phase
		var new_phase: Enums.SeedPhase = seed.advance_growth(delta)
		
		# Check if phase changed
		if new_phase != old_phase:
			# Create phase_changed event
			events.append({
				"seed_id": seed.id,
				"event": "phase_changed",
				"data": {
					"old_phase": int(old_phase),
					"new_phase": int(new_phase)
				}
			})
			
			# Emit signal (check if EventBus exists and has the signal)
			if EventBus != null and EventBus.has_signal("seed_phase_changed"):
				EventBus.emit_signal("seed_phase_changed", seed.id, seed.phase)
			
			# Check for BLOOM
			if new_phase == Enums.SeedPhase.BLOOM:
				events.append({
					"seed_id": seed.id,
					"event": "bloom_reached",
					"data": {}
				})
				
				if EventBus != null and EventBus.has_signal("seed_matured"):
					var slot_idx: int = get_planted_seeds().find(seed)
					EventBus.seed_matured.emit(seed.id, slot_idx)
			
			# Spontaneous mutation roll (not on BLOOM)
			if new_phase != Enums.SeedPhase.BLOOM and rng != null:
				if seed.mutation_potential > 0.0 and rng.randf() < seed.mutation_potential:
					_apply_random_mutation(seed)
					events.append({
						"seed_id": seed.id,
						"event": "mutated",
						"data": {}
					})
	
	return events


## Applies a random mutation to a seed's dungeon traits.
## Internal helper for spontaneous mutations during phase transitions.
##
## @param seed: The SeedData to mutate.
func _apply_random_mutation(seed: SeedData) -> void:
	if rng == null:
		return
	
	# Pick a random trait to modify
	var trait_keys: Array = [
		SeedData.TRAIT_ROOM_VARIETY,
		SeedData.TRAIT_HAZARD_FREQUENCY,
	]
	
	var key: String = rng.pick(trait_keys) as String
	var modifier: float = rng.randf() * 0.4 - 0.2  # -0.2 to +0.2
	
	if seed.dungeon_traits.has(key):
		var current: float = seed.dungeon_traits[key] as float
		seed.dungeon_traits[key] = clampf(current + modifier, 0.0, 1.0)


# ---------------------------------------------------------------------------
# Mutation and Reagent Application
# ---------------------------------------------------------------------------

## Applies a reagent to the first empty mutation slot on a seed.
## Returns true on success, false if application failed.
##
## Failure conditions:
## - Seed not found
## - No empty mutation slots available
##
## On success:
## - Fills first empty slot with reagent_id
## - Applies effect dictionary to dungeon_traits (stub for now)
##
## @param seed_id: The unique identifier of the seed.
## @param reagent_id: The ID of the reagent to apply.
## @return: True if reagent was applied, false otherwise.
func apply_reagent(seed_id: String, reagent_id: String) -> bool:
	var seed := get_seed_by_id(seed_id)
	if seed == null:
		return false
	
	# Find first empty slot
	var empty_slot: MutationSlot = null
	for slot in seed.mutation_slots:
		if slot.is_empty():
			empty_slot = slot
			break
	
	if empty_slot == null:
		return false
	
	# Apply reagent
	empty_slot.reagent_id = reagent_id
	
	# Stub: Apply a simple effect (future task will pass effect Dictionary)
	# For testing purposes, modify hazard_frequency
	if seed.dungeon_traits.has(SeedData.TRAIT_HAZARD_FREQUENCY):
		var current: float = seed.dungeon_traits[SeedData.TRAIT_HAZARD_FREQUENCY] as float
		seed.dungeon_traits[SeedData.TRAIT_HAZARD_FREQUENCY] = clampf(current + 0.1, 0.0, 1.0)
	
	return true


# ---------------------------------------------------------------------------
# Query Methods
# ---------------------------------------------------------------------------

## Returns all seeds that have reached BLOOM phase.
##
## @return: Array of SeedData instances where phase == BLOOM.
func get_matured_seeds() -> Array[SeedData]:
	var result: Array[SeedData] = []
	for seed in seeds:
		if seed.phase == Enums.SeedPhase.BLOOM:
			result.append(seed)
	return result


## Checks if a seed is ready for expedition.
## Seeds at SPROUT, BUD, or BLOOM can be sent on expeditions.
## SPORE seeds cannot.
##
## @param seed_id: The unique identifier of the seed.
## @return: True if seed is ready (not SPORE), false otherwise.
func is_ready_for_expedition(seed_id: String) -> bool:
	var seed := get_seed_by_id(seed_id)
	if seed == null:
		return false
	
	return seed.phase != Enums.SeedPhase.SPORE


# ---------------------------------------------------------------------------
# Seed Factory
# ---------------------------------------------------------------------------

## Creates a new SeedData instance with the given rarity and element.
## The seed is NOT automatically added to the grove inventory.
##
## Uses the provided RNG to ensure deterministic ID generation.
##
## @param rarity: The seed's rarity tier.
## @param element: The seed's elemental affinity.
## @param p_rng: The RNG instance for ID generation.
## @return: A newly created SeedData instance.
func create_seed(rarity: Enums.SeedRarity, element: Enums.Element, p_rng: DeterministicRNG) -> SeedData:
	# Generate unique ID using RNG
	var unique_id: String = "seed_%d_%d" % [p_rng.next_int(), p_rng.next_int()]
	return SeedData.create_seed(rarity, element, unique_id)


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serializes the grove state to a Dictionary for save/load.
##
## @return: Dictionary containing all grove state.
func serialize() -> Dictionary:
	var seeds_data: Array[Dictionary] = []
	for seed in seeds:
		seeds_data.append(seed.to_dict())
	
	var result: Dictionary = {
		"seeds": seeds_data,
		"max_grove_slots": max_grove_slots,
	}
	
	# Save RNG state if available
	if rng != null:
		result["rng_state"] = rng._state
	
	return result


## Restores the grove state from a serialized Dictionary.
## Validates data and applies safe defaults for missing keys.
##
## @param data: The serialized Dictionary.
func deserialize(data: Dictionary) -> void:
	# Clear current state
	seeds.clear()
	
	# Restore max_grove_slots with clamping
	max_grove_slots = clampi(data.get("max_grove_slots", 3) as int, 1, 20)
	
	# Restore RNG state
	if rng != null and data.has("rng_state"):
		rng._state = data["rng_state"] as int
	
	# Restore seeds with validation
	var seeds_data: Variant = data.get("seeds", [])
	if seeds_data is Array:
		var seen_ids: Dictionary = {}
		for seed_dict in seeds_data:
			if seed_dict is Dictionary:
				var seed := SeedData.from_dict(seed_dict as Dictionary)
				
				# Validate: reject duplicate IDs
				if seen_ids.has(seed.id):
					push_warning("Duplicate seed ID '%s' found during deserialization — skipping" % seed.id)
					continue
				
				seen_ids[seed.id] = true
				seeds.append(seed)
