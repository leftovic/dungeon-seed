extends Node
class_name EquipmentManager

# Simple equipment manager: slot -> Item
var equipped := {} # Dictionary: slot -> Item

func equip(item: Item) -> Item:
	# returns previous item in slot (or null)
	var prev = null
	if item == null:
		return null
	if equipped.has(item.slot):
		prev = equipped[item.slot]
	equipped[item.slot] = item
	return prev

func unequip(slot: String) -> Item:
	if equipped.has(slot):
		var it = equipped[slot]
		equipped.erase(slot)
		return it
	return null

func get_equipped(slot: String) -> Item:
	return equipped.get(slot, null)

func total_stats() -> Dictionary:
	var totals := {}
	for slot in equipped.keys():
		var it: Item = equipped[slot]
		if it == null:
			continue
		for k in it.stats.keys():
			totals[k] = totals.get(k, 0) + it.stats[k]
	return totals

func to_dict() -> Dictionary:
	var out := {}
	for slot in equipped.keys():
		var it: Item = equipped[slot]
		if it != null:
			out[slot] = it.to_dict()
	return out

func from_dict(d: Dictionary) -> void:
	equipped.clear()
	for slot in d.keys():
		var it = Item.from_dict(d[slot])
		equipped[slot] = it
