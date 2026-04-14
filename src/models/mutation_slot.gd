class_name MutationSlot
extends RefCounted
## Represents a single reagent slot on a seed.
##
## Each seed has a number of mutation slots determined by its rarity.
## Slots can be filled with reagents to modify the dungeon generated
## from the seed. An empty slot has reagent_id == "" and effect == {}.


## The position of this slot in the seed's mutation_slots array.
var slot_index: int = 0

## The ID of the reagent applied to this slot. Empty string if unused.
var reagent_id: String = ""

## A dictionary of stat modifiers applied to dungeon generation when
## the seed blooms. Keys are dungeon trait names (e.g., "room_variety"),
## values are numeric modifiers (positive = increase, negative = decrease).
var effect: Dictionary = {}


## Returns true if this slot has no reagent applied.
func is_empty() -> bool:
	return reagent_id == ""


## Serializes this slot to a plain Dictionary for save/load.
func to_dict() -> Dictionary:
	return {
		"slot_index": slot_index,
		"reagent_id": reagent_id,
		"effect": effect.duplicate(),
	}


## Reconstructs a MutationSlot from a serialized Dictionary.
## Uses defensive get() with defaults for all fields.
static func from_dict(data: Dictionary) -> MutationSlot:
	var slot := MutationSlot.new()
	slot.slot_index = data.get("slot_index", 0) as int
	slot.reagent_id = data.get("reagent_id", "") as String
	var raw_effect: Variant = data.get("effect", {})
	if raw_effect is Dictionary:
		slot.effect = (raw_effect as Dictionary).duplicate()
	else:
		slot.effect = {}
	return slot
