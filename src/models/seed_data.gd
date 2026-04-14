class_name SeedData
extends RefCounted
## The primary data model for a plantable seed in Dungeon Seed.
##
## Encapsulates all GDD §4.1 seed attributes: rarity, elemental affinity,
## growth phase, growth progress, growth rate, mutation slots, mutation
## potential, dungeon generation traits, and planting status.
##
## Includes a pull-based maturation state machine that advances through
## four phases: SPORE → SPROUT → BUD → BLOOM. The state machine is
## advanced externally by calling advance_growth(delta_seconds).


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const TRAIT_ROOM_VARIETY := "room_variety"
const TRAIT_HAZARD_FREQUENCY := "hazard_frequency"
const TRAIT_LOOT_BIAS := "loot_bias"

const MUTATION_POTENTIAL_BY_RARITY: Dictionary = {
	Enums.SeedRarity.COMMON: 0.1,
	Enums.SeedRarity.UNCOMMON: 0.2,
	Enums.SeedRarity.RARE: 0.4,
	Enums.SeedRarity.EPIC: 0.6,
	Enums.SeedRarity.LEGENDARY: 0.8,
}

const LOOT_BIAS_BY_RARITY: Array[String] = [
	"gold",       # COMMON (0)
	"crafting",   # UNCOMMON (1)
	"artifacts",  # RARE (2)
	"balanced",   # EPIC (3)
	"balanced",   # LEGENDARY (4)
]


# ---------------------------------------------------------------------------
# Properties
# ---------------------------------------------------------------------------

## Unique identifier for this seed instance.
var id: String = ""

## The rarity tier of this seed, determining growth time and slot count.
var rarity: Enums.SeedRarity = Enums.SeedRarity.COMMON

## The elemental affinity, determining dungeon theme and enemy types.
var element: Enums.Element = Enums.Element.TERRA

## Current maturation phase in the state machine.
var phase: Enums.SeedPhase = Enums.SeedPhase.SPORE

## Completion percentage within the current phase, range [0.0, 1.0].
var growth_progress: float = 0.0

## Base seconds per phase. Set from GameConfig at creation time.
var growth_rate: float = 60.0

## Array of mutation slots available for reagent application.
var mutation_slots: Array[MutationSlot] = []

## Probability [0.0, 1.0] that a reagent produces a beneficial mutation.
var mutation_potential: float = 0.1

## Dungeon generation parameters derived from rarity and element.
var dungeon_traits: Dictionary = {}

## Engine timestamp when this seed was planted. 0.0 if unplanted.
var planted_at: float = 0.0

## Whether this seed is currently planted in a grove plot.
var is_planted: bool = false


# ---------------------------------------------------------------------------
# Static ID Generator
# ---------------------------------------------------------------------------

## Internal counter for generating unique IDs within a session.
static var _id_counter: int = 0


## Generates a unique string identifier for a seed.
## Uses a combination of timestamp hash and an incrementing counter.
static func generate_id() -> String:
	_id_counter += 1
	var time_hash: int = Time.get_ticks_usec()
	return "seed_%s_%d" % [String.num_int64(time_hash, 16), _id_counter]


# ---------------------------------------------------------------------------
# Factory Method
# ---------------------------------------------------------------------------

## Creates a fully initialized SeedData instance with all properties
## derived from the given rarity and element.
##
## @param p_rarity: The rarity tier of the seed.
## @param p_element: The elemental affinity of the seed.
## @param custom_id: Optional custom ID. If empty, one is generated.
## @return: A new SeedData instance ready for planting.
static func create_seed(
	p_rarity: Enums.SeedRarity,
	p_element: Enums.Element,
	custom_id: String = ""
) -> SeedData:
	var seed := SeedData.new()

	# Identity
	if custom_id.is_empty():
		seed.id = generate_id()
	else:
		seed.id = custom_id

	# Core attributes
	seed.rarity = p_rarity
	seed.element = p_element

	# Growth configuration from GameConfig
	seed.growth_rate = float(GameConfig.BASE_GROWTH_SECONDS[p_rarity])

	# Mutation slots — count determined by rarity
	var slot_count: int = GameConfig.MUTATION_SLOTS[p_rarity]
	seed.mutation_slots = []
	for i in range(slot_count):
		var slot := MutationSlot.new()
		slot.slot_index = i
		seed.mutation_slots.append(slot)

	# Mutation potential — scaled by rarity
	seed.mutation_potential = MUTATION_POTENTIAL_BY_RARITY.get(p_rarity, 0.1)

	# Dungeon traits — base values scale with rarity
	var rarity_index: int = int(p_rarity)
	seed.dungeon_traits = {
		TRAIT_ROOM_VARIETY: 0.3 + (rarity_index * 0.15),
		TRAIT_HAZARD_FREQUENCY: 0.2 + (rarity_index * 0.1),
		TRAIT_LOOT_BIAS: LOOT_BIAS_BY_RARITY[mini(rarity_index, LOOT_BIAS_BY_RARITY.size() - 1)],
	}

	# Initial state
	seed.phase = Enums.SeedPhase.SPORE
	seed.growth_progress = 0.0
	seed.planted_at = 0.0
	seed.is_planted = false

	return seed


# ---------------------------------------------------------------------------
# Planting
# ---------------------------------------------------------------------------

## Plants this seed at the given timestamp.
## No-op if already planted, or if timestamp is <= 0.0.
##
## @param timestamp: The engine time when planting occurs. Must be > 0.0.
func plant(timestamp: float) -> void:
	if is_planted:
		return
	if timestamp <= 0.0:
		return
	is_planted = true
	planted_at = timestamp


# ---------------------------------------------------------------------------
# Maturation State Machine
# ---------------------------------------------------------------------------

## Advances the seed's growth by the given delta time.
##
## The state machine transitions through phases SPORE → SPROUT → BUD → BLOOM.
## Each phase has a duration of growth_rate * PHASE_GROWTH_MULTIPLIERS[phase].
## At most one phase transition occurs per call.
##
## @param delta_seconds: Elapsed time in seconds. Must be > 0.0.
## @return: The current phase after advancement.
func advance_growth(delta_seconds: float) -> Enums.SeedPhase:
	# Guard: not planted
	if not is_planted:
		return phase

	# Guard: terminal phase
	if phase == Enums.SeedPhase.BLOOM:
		return Enums.SeedPhase.BLOOM

	# Guard: invalid delta
	if delta_seconds <= 0.0:
		return phase

	# Calculate phase duration
	var phase_duration: float = _get_current_phase_duration()
	if phase_duration <= 0.0:
		return phase

	# Advance growth progress
	growth_progress += delta_seconds / phase_duration
	growth_progress = clampf(growth_progress, 0.0, 2.0)  # Allow slight overshoot for detection

	# Check for phase transition
	if growth_progress >= 1.0:
		var next: Enums.SeedPhase = _next_phase(phase)
		phase = next
		growth_progress = 0.0

	return phase


## Returns the next phase in the sequence, clamped to BLOOM.
func _next_phase(current: Enums.SeedPhase) -> Enums.SeedPhase:
	var next_val: int = int(current) + 1
	if next_val > int(Enums.SeedPhase.BLOOM):
		return Enums.SeedPhase.BLOOM
	return next_val as Enums.SeedPhase


## Returns the duration in seconds for the current phase.
func _get_current_phase_duration() -> float:
	if phase == Enums.SeedPhase.BLOOM:
		return 0.0
	return growth_rate * GameConfig.PHASE_GROWTH_MULTIPLIERS[phase]


# ---------------------------------------------------------------------------
# Helper Methods
# ---------------------------------------------------------------------------

## Returns the duration in seconds for the current phase.
## Returns 0.0 if the seed is in BLOOM (terminal phase).
func get_phase_duration() -> float:
	return _get_current_phase_duration()


## Returns the total growth time from SPORE through BUD (in seconds).
## BLOOM is terminal and has no duration.
func get_total_growth_time() -> float:
	var total: float = 0.0
	for p: int in [int(Enums.SeedPhase.SPORE), int(Enums.SeedPhase.SPROUT), int(Enums.SeedPhase.BUD)]:
		var phase_enum: Enums.SeedPhase = p as Enums.SeedPhase
		total += growth_rate * GameConfig.PHASE_GROWTH_MULTIPLIERS[phase_enum]
	return total


## Returns the estimated seconds remaining until BLOOM.
## Based on current phase, progress, and growth rate.
## Returns 0.0 if already in BLOOM.
func get_remaining_time() -> float:
	if phase == Enums.SeedPhase.BLOOM:
		return 0.0

	# Remaining time in current phase
	var current_dur: float = _get_current_phase_duration()
	var remaining: float = current_dur * (1.0 - growth_progress)

	# Add full durations of subsequent phases (excluding BLOOM)
	var phase_val: int = int(phase) + 1
	while phase_val < int(Enums.SeedPhase.BLOOM):
		var future_phase: Enums.SeedPhase = phase_val as Enums.SeedPhase
		remaining += growth_rate * GameConfig.PHASE_GROWTH_MULTIPLIERS[future_phase]
		phase_val += 1

	return maxf(0.0, remaining)


## Returns overall maturation progress as a float in [0.0, 1.0].
## 0.0 = freshly created SPORE, 1.0 = BLOOM.
func get_overall_progress() -> float:
	if phase == Enums.SeedPhase.BLOOM:
		return 1.0

	var total: float = get_total_growth_time()
	if total <= 0.0:
		return 0.0

	# Sum completed phase durations
	var elapsed: float = 0.0
	for p: int in [int(Enums.SeedPhase.SPORE), int(Enums.SeedPhase.SPROUT), int(Enums.SeedPhase.BUD)]:
		var phase_enum: Enums.SeedPhase = p as Enums.SeedPhase
		if p < int(phase):
			elapsed += growth_rate * GameConfig.PHASE_GROWTH_MULTIPLIERS[phase_enum]
		elif p == int(phase):
			elapsed += _get_current_phase_duration() * growth_progress
			break

	return clampf(elapsed / total, 0.0, 1.0)


## Returns the number of mutation slots that have a reagent applied.
func get_filled_slot_count() -> int:
	var count: int = 0
	for slot in mutation_slots:
		if not slot.is_empty():
			count += 1
	return count


## Returns the MutationSlot at the given index, or null if out of bounds.
##
## @param index: The slot index to retrieve.
## @return: The MutationSlot, or null if index is invalid.
func get_slot(index: int) -> MutationSlot:
	if index < 0 or index >= mutation_slots.size():
		return null
	return mutation_slots[index]


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

## Serializes this SeedData to a plain Dictionary suitable for JSON/save.
## Enum values are stored as integers. Mutation slots are stored as an array
## of dictionaries.
func to_dict() -> Dictionary:
	var slots_array: Array[Dictionary] = []
	for slot in mutation_slots:
		slots_array.append(slot.to_dict())

	return {
		"id": id,
		"rarity": int(rarity),
		"element": int(element),
		"phase": int(phase),
		"growth_progress": growth_progress,
		"growth_rate": growth_rate,
		"mutation_slots": slots_array,
		"mutation_potential": mutation_potential,
		"dungeon_traits": dungeon_traits.duplicate(),
		"planted_at": planted_at,
		"is_planted": is_planted,
	}


## Reconstructs a SeedData instance from a serialized Dictionary.
## Uses defensive get() with defaults for all fields to handle
## missing keys gracefully (e.g., loading saves from older versions).
##
## @param data: The serialized Dictionary.
## @return: A reconstructed SeedData instance.
static func from_dict(data: Dictionary) -> SeedData:
	var seed := SeedData.new()

	seed.id = data.get("id", "") as String

	# Restore enums from integer values with clamping
	var rarity_int: int = clampi(data.get("rarity", 0) as int, 0, int(Enums.SeedRarity.LEGENDARY))
	seed.rarity = rarity_int as Enums.SeedRarity

	var element_int: int = clampi(data.get("element", 0) as int, 0, int(Enums.Element.SHADOW))
	seed.element = element_int as Enums.Element

	var phase_int: int = clampi(data.get("phase", 0) as int, 0, int(Enums.SeedPhase.BLOOM))
	seed.phase = phase_int as Enums.SeedPhase

	seed.growth_progress = clampf(data.get("growth_progress", 0.0) as float, 0.0, 1.0)
	seed.growth_rate = maxf(data.get("growth_rate", 60.0) as float, 1.0)
	seed.mutation_potential = clampf(data.get("mutation_potential", 0.1) as float, 0.0, 1.0)
	seed.planted_at = maxf(data.get("planted_at", 0.0) as float, 0.0)
	seed.is_planted = data.get("is_planted", false) as bool

	# Restore dungeon traits with defaults
	var raw_traits: Variant = data.get("dungeon_traits", {})
	if raw_traits is Dictionary:
		seed.dungeon_traits = (raw_traits as Dictionary).duplicate()
	else:
		seed.dungeon_traits = {
			TRAIT_ROOM_VARIETY: 0.3,
			TRAIT_HAZARD_FREQUENCY: 0.2,
			TRAIT_LOOT_BIAS: "gold",
		}

	# Ensure required trait keys exist
	if not seed.dungeon_traits.has(TRAIT_ROOM_VARIETY):
		seed.dungeon_traits[TRAIT_ROOM_VARIETY] = 0.3
	if not seed.dungeon_traits.has(TRAIT_HAZARD_FREQUENCY):
		seed.dungeon_traits[TRAIT_HAZARD_FREQUENCY] = 0.2
	if not seed.dungeon_traits.has(TRAIT_LOOT_BIAS):
		seed.dungeon_traits[TRAIT_LOOT_BIAS] = "gold"

	# Restore mutation slots with truncation to rarity limit
	var max_slots: int = GameConfig.MUTATION_SLOTS.get(seed.rarity, 1) as int
	var raw_slots: Variant = data.get("mutation_slots", [])
	seed.mutation_slots = []

	if raw_slots is Array:
		var slots_data: Array = raw_slots as Array
		var count: int = mini(slots_data.size(), max_slots)
		for i in range(count):
			if slots_data[i] is Dictionary:
				seed.mutation_slots.append(MutationSlot.from_dict(slots_data[i] as Dictionary))
			else:
				var empty_slot := MutationSlot.new()
				empty_slot.slot_index = i
				seed.mutation_slots.append(empty_slot)

	# Pad with empty slots if fewer than allowed
	while seed.mutation_slots.size() < max_slots:
		var pad_slot := MutationSlot.new()
		pad_slot.slot_index = seed.mutation_slots.size()
		seed.mutation_slots.append(pad_slot)

	return seed
