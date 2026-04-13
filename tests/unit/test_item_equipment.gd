extends "res://tests/unit/test_base.gd"

func test_equip_and_stats():
	var Item = preload("res://src/gdscript/items/item.gd")
	var EquipmentManager = preload("res://src/gdscript/items/equipment_manager.gd")
	var sword = Item.new("sword-001", "Short Sword", "weapon", {"attack": 5})
	var ring = Item.new("ring-001", "Ring of Might", "ring", {"strength": 2})
	var mgr = EquipmentManager.new()
	mgr.equip(sword)
	mgr.equip(ring)
	var totals = mgr.total_stats()
	assert_eq(totals.get("attack", 0), 5, "Attack should be 5 after equipping sword")
	assert_eq(totals.get("strength", 0), 2, "Strength should be 2 after equipping ring")
	# serialize / deserialize
	var ser = mgr.to_dict()
	var mgr2 = EquipmentManager.new()
	mgr2.from_dict(ser)
	var totals2 = mgr2.total_stats()
	assert_eq(totals2.get("attack", 0), 5, "Deserialized manager attack matches")
	assert_eq(totals2.get("strength", 0), 2, "Deserialized manager strength matches")

func test_equip_slot_swap():
	var Item = preload("res://src/gdscript/items/item.gd")
	var EquipmentManager = preload("res://src/gdscript/items/equipment_manager.gd")
	var sword1 = Item.new("sword-001", "Short Sword", "weapon", {"attack": 5})
	var sword2 = Item.new("sword-002", "Long Sword", "weapon", {"attack": 8})
	var mgr = EquipmentManager.new()
	mgr.equip(sword1)
	var prev = mgr.equip(sword2)
	assert(prev != null, "Previous item should be returned when swapping slots")
	assert_eq(mgr.get_equipped("weapon").id, "sword-002", "Weapon slot should hold the new sword")
