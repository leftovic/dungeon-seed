class_name ItemData
extends RefCounted
## Immutable definition of a single game item.
## Constructed from a Dictionary of fields. Supports serialization via to_dict()/from_dict().
##
## Fields are set once in the constructor or from_dict() and never mutated at runtime.
## This immutability guarantee allows ItemDatabase to hand out direct references
## without defensive copies.
##
## Depends on: Enums (ItemRarity, EquipSlot, Currency), GameConfig (RARITY_COLORS)


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
