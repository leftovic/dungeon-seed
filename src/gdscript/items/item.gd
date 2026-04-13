extends Reference
class_name Item

var id: String = ""
var name: String = ""
var slot: String = "" # e.g., "head", "body", "weapon", "ring"
var stats := {}

func _init(_id: String = "", _name: String = "", _slot: String = "", _stats := {}):
	id = _id
	name = _name
	slot = _slot
	stats = _stats.duplicate()

func to_dict() -> Dictionary:
	return {"id": id, "name": name, "slot": slot, "stats": stats.duplicate()}

static func from_dict(d: Dictionary) -> Item:
	var it = Item.new()
	it.id = str(d.get("id", ""))
	it.name = str(d.get("name", ""))
	it.slot = str(d.get("slot", ""))
	it.stats = d.get("stats", {}).duplicate()
	return it
