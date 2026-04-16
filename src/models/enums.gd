## src/models/enums.gd
## Centralized game-wide enumerations for Dungeon Seed.
## All enums are drawn directly from GDD-v2.md.
## This file is the single source of truth for every named constant in the game.
##
## Usage: Enums.SeedRarity.COMMON, Enums.Element.TERRA, etc.
## No instantiation needed — access via class_name static reference.
class_name Enums


# ---------------------------------------------------------------------------
# §4.1 — Seed System Enums
# ---------------------------------------------------------------------------

## Seed rarity tiers determine growth time, mutation slots, and loot quality.
## Values: COMMON=0, UNCOMMON=1, RARE=2, EPIC=3, LEGENDARY=4
## GDD Reference: §4.1 (Seed System — Rarity Tiers)
enum SeedRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

## Elemental affinity of a seed. Affects dungeon generation and combat bonuses.
## Values: TERRA=0, FLAME=1, FROST=2, ARCANE=3, SHADOW=4, NONE=5
## NONE = 5 is the sentinel value for seeds/items with no elemental affinity.
## GDD Reference: §4.1 (Seed System — Elemental Affinity)
enum Element { TERRA, FLAME, FROST, ARCANE, SHADOW, NONE }

## Growth phases a seed passes through from planting to harvest.
## Values: SPORE=0, SPROUT=1, BUD=2, BLOOM=3
## GDD Reference: §4.1 (Seed System — Growth Phases)
enum SeedPhase { SPORE, SPROUT, BUD, BLOOM }


# ---------------------------------------------------------------------------
# §4.2 — Dungeon System Enums
# ---------------------------------------------------------------------------

## Types of rooms that can appear in a dungeon layout.
## Values: COMBAT=0, TREASURE=1, TRAP=2, PUZZLE=3, REST=4, BOSS=5, ENTRANCE=6, SECRET=7
## GDD Reference: §4.2 (Dungeon Generation — Room Types)
enum RoomType { COMBAT, TREASURE, TRAP, PUZZLE, REST, BOSS, ENTRANCE, SECRET }

## Status of an expedition (adventurer party sent into a dungeon).
## Values: PREPARING=0, IN_PROGRESS=1, COMPLETED=2, FAILED=3
## GDD Reference: §4.2 (Dungeon Generation — Expedition Flow)
enum ExpeditionStatus { PREPARING, IN_PROGRESS, COMPLETED, FAILED }


# ---------------------------------------------------------------------------
# §4.3 — Adventurer System Enums
# ---------------------------------------------------------------------------

## Adventurer class archetypes with distinct stat distributions.
## Values: WARRIOR=0, RANGER=1, MAGE=2, ROGUE=3, ALCHEMIST=4, SENTINEL=5
## GDD Reference: §4.3 (Adventurer System — Classes)
enum AdventurerClass { WARRIOR, RANGER, MAGE, ROGUE, ALCHEMIST, SENTINEL }

## Adventurer experience/progression tiers.
## Values: NOVICE=0, SKILLED=1, VETERAN=2, ELITE=3
## GDD Reference: §4.3 (Adventurer System — Level Tiers)
enum LevelTier { NOVICE, SKILLED, VETERAN, ELITE }

## Equipment slots available on each adventurer.
## Values: NONE=-1, WEAPON=0, ARMOR=1, ACCESSORY=2
## NONE = -1 is a sentinel value for non-equippable items (quest items, materials).
## GDD Reference: §4.3 (Adventurer System — Equipment)
enum EquipSlot { NONE = -1, WEAPON = 0, ARMOR = 1, ACCESSORY = 2 }


# ---------------------------------------------------------------------------
# §4.4 — Loot & Economy Enums
# ---------------------------------------------------------------------------

## Loot/item rarity tiers. Mirrors SeedRarity values but is a separate type
## to avoid coupling seed systems with item systems.
## Values: COMMON=0, UNCOMMON=1, RARE=2, EPIC=3, LEGENDARY=4
## GDD Reference: §4.4 (Loot & Economy — Item Rarity)
enum ItemRarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

## Currency types in the game economy.
## Values: GOLD=0, ESSENCE=1, FRAGMENTS=2, ARTIFACTS=3
## GDD Reference: §4.4 (Loot & Economy — Currency Types)
enum Currency { GOLD, ESSENCE, FRAGMENTS, ARTIFACTS }


# ---------------------------------------------------------------------------
# Helper Methods
# ---------------------------------------------------------------------------

## Returns the human-readable display name for a SeedRarity value.
## Example: Enums.seed_rarity_name(Enums.SeedRarity.EPIC) -> "Epic"
## Returns "Unknown" with a push_warning() for invalid values.
static func seed_rarity_name(rarity: Enums.SeedRarity) -> String:
	match rarity:
		SeedRarity.COMMON:
			return "Common"
		SeedRarity.UNCOMMON:
			return "Uncommon"
		SeedRarity.RARE:
			return "Rare"
		SeedRarity.EPIC:
			return "Epic"
		SeedRarity.LEGENDARY:
			return "Legendary"
		_:
			push_warning("Unknown SeedRarity value: %d" % rarity)
			return "Unknown"


## Returns the human-readable display name for an ItemRarity value.
## Example: Enums.item_rarity_name(Enums.ItemRarity.RARE) -> "Rare"
## Returns "Unknown" with a push_warning() for invalid values.
static func item_rarity_name(rarity: Enums.ItemRarity) -> String:
	match rarity:
		ItemRarity.COMMON:
			return "Common"
		ItemRarity.UNCOMMON:
			return "Uncommon"
		ItemRarity.RARE:
			return "Rare"
		ItemRarity.EPIC:
			return "Epic"
		ItemRarity.LEGENDARY:
			return "Legendary"
		_:
			push_warning("Unknown ItemRarity value: %d" % rarity)
			return "Unknown"


## Returns the human-readable display name for an AdventurerClass value.
## Example: Enums.adventurer_class_name(Enums.AdventurerClass.MAGE) -> "Mage"
## Returns "Unknown" with a push_warning() for invalid values.
static func adventurer_class_name(cls: Enums.AdventurerClass) -> String:
	match cls:
		AdventurerClass.WARRIOR:
			return "Warrior"
		AdventurerClass.RANGER:
			return "Ranger"
		AdventurerClass.MAGE:
			return "Mage"
		AdventurerClass.ROGUE:
			return "Rogue"
		AdventurerClass.ALCHEMIST:
			return "Alchemist"
		AdventurerClass.SENTINEL:
			return "Sentinel"
		_:
			push_warning("Unknown AdventurerClass value: %d" % cls)
			return "Unknown"


## Returns the human-readable display name for an Element value.
## Example: Enums.element_name(Enums.Element.FROST) -> "Frost"
## Returns "Unknown" with a push_warning() for invalid values.
static func element_name(element: Enums.Element) -> String:
	match element:
		Element.TERRA:
			return "Terra"
		Element.FLAME:
			return "Flame"
		Element.FROST:
			return "Frost"
		Element.ARCANE:
			return "Arcane"
		Element.SHADOW:
			return "Shadow"
		Element.NONE:
			return "None"
		_:
			push_warning("Unknown Element value: %d" % element)
			return "Unknown"


## Returns the human-readable display name for an EquipSlot value.
## Example: Enums.equip_slot_name(Enums.EquipSlot.WEAPON) -> "Weapon"
## Returns "Unknown" with a push_warning() for invalid values.
static func equip_slot_name(slot: Enums.EquipSlot) -> String:
	match slot:
		EquipSlot.NONE:
			return "None"
		EquipSlot.WEAPON:
			return "Weapon"
		EquipSlot.ARMOR:
			return "Armor"
		EquipSlot.ACCESSORY:
			return "Accessory"
		_:
			push_warning("Unknown EquipSlot value: %d" % slot)
			return "Unknown"
