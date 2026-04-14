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


## Removes all items from the registry.
func clear() -> void:
	_items.clear()


## Serializes this ItemDatabase to a JSON-compatible Dictionary.
func to_dict() -> Dictionary:
	var items_dict: Dictionary = {}
	for item_id: String in _items:
		items_dict[item_id] = _items[item_id].to_dict()
	return {
		"items": items_dict
	}


## Constructs an ItemDatabase from a serialized Dictionary. Static factory method.
static func from_dict(data: Dictionary) -> ItemDatabase:
	var db := new()
	db.clear()  # Remove starter items
	if data.has("items"):
		var items_dict: Dictionary = data["items"]
		for item_id: String in items_dict:
			var item_data: Dictionary = items_dict[item_id]
			db.register_item(ItemData.from_dict(item_data))
	return db


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
