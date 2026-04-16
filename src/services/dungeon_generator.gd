class_name DungeonGeneratorService
extends RefCounted
## Deterministic procedural dungeon generator that transforms SeedData into DungeonData.
##
## Implements the seven-stage generation pipeline from GDD §5.3:
## 1. Seed Parsing — extract seed properties
## 2. Parameter Calculation — compute room count, branching, difficulty
## 3. Room Graph Generation — place rooms, build MST, add shortcuts
## 4. Room Type Assignment — distribute room types with element bias
## 5. Difficulty Assignment — scale difficulty by depth and type
## 6. Loot Bias Assignment — set currency weights per room
## 7. Validation — verify connectivity and critical path
##
## All randomness flows through DeterministicRNG seeded from seed_id + phase.
## Same seed input → same dungeon output (byte-identical).


# ---------------------------------------------------------------------------
# Constants — Vigor Scaling Tables (GDD §5.4)
# ---------------------------------------------------------------------------

## Room count base by phase
const ROOM_COUNT_BASE: Dictionary = {
	Enums.SeedPhase.SPORE: 3,
	Enums.SeedPhase.SPROUT: 5,
	Enums.SeedPhase.BUD: 8,
	Enums.SeedPhase.BLOOM: 12,
}

## Room count bonus by rarity
const ROOM_COUNT_BONUS: Dictionary = {
	Enums.SeedRarity.COMMON: 0,
	Enums.SeedRarity.UNCOMMON: 1,
	Enums.SeedRarity.RARE: 2,
	Enums.SeedRarity.EPIC: 3,
	Enums.SeedRarity.LEGENDARY: 3,
}

## Branching factor interpolation by vigor (linear)
const BRANCHING_FACTOR_TABLE: Array[Vector2] = [
	Vector2(1.0, 0.1),
	Vector2(25.0, 0.2),
	Vector2(50.0, 0.3),
	Vector2(75.0, 0.4),
	Vector2(100.0, 0.5),
]

## Room count clamps by vigor
const ROOM_COUNT_CLAMP: Array[Vector3] = [
	Vector3(1.0, 5.0, 7.0),
	Vector3(25.0, 8.0, 12.0),
	Vector3(50.0, 12.0, 16.0),
	Vector3(75.0, 16.0, 22.0),
	Vector3(100.0, 20.0, 28.0),
]

## Biome difficulty multipliers by element
const ELEMENT_DIFFICULTY: Dictionary = {
	Enums.Element.TERRA: 1.0,
	Enums.Element.FLAME: 1.1,
	Enums.Element.FROST: 1.05,
	Enums.Element.ARCANE: 1.15,
	Enums.Element.SHADOW: 1.3,
	Enums.Element.NONE: 1.0,
}

## Room type base weights (out of 100)
const ROOM_TYPE_WEIGHTS: Dictionary = {
	Enums.RoomType.COMBAT: 40.0,
	Enums.RoomType.TREASURE: 20.0,
	Enums.RoomType.TRAP: 15.0,
	Enums.RoomType.PUZZLE: 15.0,
	Enums.RoomType.REST: 10.0,
}

## Element bias modifiers (additive to base weights)
const ELEMENT_BIASES: Dictionary = {
	Enums.Element.TERRA: {},
	Enums.Element.FLAME: {Enums.RoomType.COMBAT: 15.0},
	Enums.Element.FROST: {Enums.RoomType.TRAP: 15.0},
	Enums.Element.ARCANE: {Enums.RoomType.PUZZLE: 10.0, Enums.RoomType.TREASURE: 5.0},
	Enums.Element.SHADOW: {Enums.RoomType.TRAP: 10.0, Enums.RoomType.COMBAT: 5.0},
	Enums.Element.NONE: {},
}

## Room type difficulty modifiers
const ROOM_TYPE_DIFFICULTY_MODIFIER: Dictionary = {
	Enums.RoomType.COMBAT: 1.0,
	Enums.RoomType.TREASURE: 0.7,
	Enums.RoomType.TRAP: 0.9,
	Enums.RoomType.PUZZLE: 0.6,
	Enums.RoomType.REST: 0.0,
	Enums.RoomType.BOSS: 1.5,
	Enums.RoomType.ENTRANCE: 0.0,
	Enums.RoomType.SECRET: 1.2,
}

## Default loot bias by room type
const DEFAULT_LOOT_BIAS: Dictionary = {
	Enums.RoomType.COMBAT: {Enums.Currency.GOLD: 0.6, Enums.Currency.ESSENCE: 0.3, Enums.Currency.FRAGMENTS: 0.1},
	Enums.RoomType.TREASURE: {Enums.Currency.GOLD: 0.5, Enums.Currency.ESSENCE: 0.2, Enums.Currency.FRAGMENTS: 0.2, Enums.Currency.ARTIFACTS: 0.1},
	Enums.RoomType.TRAP: {Enums.Currency.FRAGMENTS: 0.5, Enums.Currency.GOLD: 0.3, Enums.Currency.ESSENCE: 0.2},
	Enums.RoomType.PUZZLE: {Enums.Currency.ESSENCE: 0.5, Enums.Currency.FRAGMENTS: 0.3, Enums.Currency.GOLD: 0.2},
	Enums.RoomType.REST: {},
	Enums.RoomType.BOSS: {Enums.Currency.ARTIFACTS: 0.4, Enums.Currency.GOLD: 0.3, Enums.Currency.ESSENCE: 0.2, Enums.Currency.FRAGMENTS: 0.1},
	Enums.RoomType.ENTRANCE: {},
	Enums.RoomType.SECRET: {Enums.Currency.ARTIFACTS: 0.3, Enums.Currency.GOLD: 0.3, Enums.Currency.ESSENCE: 0.2, Enums.Currency.FRAGMENTS: 0.2},
}

## Grid spacing for room placement (abstract units)
const GRID_SPACING: float = 3.0


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Generates a dungeon from a SeedData instance.
## Returns a fully populated DungeonData with rooms, edges, types, difficulties, and loot biases.
##
## @param seed_data: The seed to generate from.
## @return: A validated DungeonData instance.
func generate(seed_data: SeedData) -> DungeonData:
	if seed_data == null:
		push_error("DungeonGeneratorService.generate: seed_data is null")
		return _create_fallback_dungeon()
	
	# Extract seed properties
	var seed_id: String = seed_data.id
	var rarity: Enums.SeedRarity = seed_data.rarity
	var element: Enums.Element = seed_data.element
	var phase: Enums.SeedPhase = seed_data.phase
	
	# Use rarity as vigor proxy (1-100 scale based on rarity)
	var vigor: int = _rarity_to_vigor(rarity)
	
	# Get dungeon traits with defaults
	var traits: Dictionary = seed_data.dungeon_traits.duplicate() if not seed_data.dungeon_traits.is_empty() else {}
	if not traits.has("room_variety"):
		traits["room_variety"] = 0.5
	if not traits.has("loot_bias"):
		traits["loot_bias"] = "gold"
	if not traits.has("hazard_frequency"):
		traits["hazard_frequency"] = 0.2
	
	return generate_from_params(seed_id, rarity, element, phase, vigor, traits)


## Generates a dungeon from explicit parameters (for testing).
## Same output as generate() when given equivalent parameters.
##
## @param seed_id: Unique seed identifier for RNG seeding.
## @param rarity: Seed rarity tier.
## @param element: Elemental affinity.
## @param phase: Growth phase.
## @param vigor: Difficulty scaling (1-100).
## @param traits: Dungeon traits dictionary.
## @return: A validated DungeonData instance.
func generate_from_params(
	seed_id: String,
	rarity: Enums.SeedRarity,
	element: Enums.Element,
	phase: Enums.SeedPhase,
	vigor: int,
	traits: Dictionary
) -> DungeonData:
	# Create deterministic RNG seeded from seed_id + phase
	var rng := DeterministicRNG.new()
	var seed_string: String = "%s-%d" % [seed_id, int(phase)]
	rng.seed_string(seed_string)
	
	# Stage 2: Parameter Calculation
	var room_count: int = _calc_room_count(phase, rarity, vigor)
	var branching_factor: float = _calc_branching_factor(vigor)
	var base_difficulty: float = _calc_base_difficulty(vigor, element)
	
	# Stage 3: Room Graph Generation
	var positions: Array[Vector2] = _place_rooms_on_grid(room_count, rng)
	var mst_edges: Array[Vector2i] = _build_mst_prim(positions, rng)
	var all_edges: Array[Vector2i] = _add_shortcut_edges(mst_edges, positions, branching_factor, room_count, rng)
	
	# Create dungeon data
	var dungeon := DungeonData.new()
	dungeon.seed_id = seed_id
	dungeon.element = element
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = room_count - 1
	dungeon.edges = all_edges
	
	# Create rooms with positions
	for i in range(room_count):
		var room := RoomData.new()
		room.index = i
		room.position = positions[i]
		room.is_cleared = false
		dungeon.rooms.append(room)
	
	# Stage 4: Room Type Assignment
	_assign_room_types(dungeon, element, traits, rng)
	
	# Stage 5: Difficulty Assignment
	_assign_difficulties(dungeon, base_difficulty)
	
	# Stage 6: Loot Bias Assignment
	_assign_loot_biases(dungeon, traits)
	
	# Stage 7: Validation
	var is_valid: bool = dungeon.validate()
	if not is_valid:
		push_error("DungeonGeneratorService.generate_from_params: validation failed")
		# Debug: detailed failure analysis
		push_warning("Room count: %d" % dungeon.get_room_count())
		push_warning("Edge count: %d" % dungeon.get_edge_count())
		push_warning("Entry index: %d" % dungeon.entry_room_index)
		push_warning("Boss index: %d" % dungeon.boss_room_index)
		
		# Check each edge
		for i in range(dungeon.edges.size()):
			var edge: Vector2i = dungeon.edges[i]
			if edge.x >= edge.y:
				push_warning("Edge %d is not canonical: (%d, %d)" % [i, edge.x, edge.y])
		
		# Check connectivity
		var visited: Dictionary = {}
		var queue: Array[int] = []
		if dungeon.get_room_count() > 0:
			queue.append(dungeon.entry_room_index)
			visited[dungeon.entry_room_index] = true
			while queue.size() > 0:
				var current: int = queue[0]
				queue.remove_at(0)
				var neighbors: Array[int] = dungeon.get_adjacent(current)
				for neighbor in neighbors:
					if not visited.has(neighbor):
						visited[neighbor] = true
						queue.append(neighbor)
		push_warning("Connectivity: %d/%d rooms reachable" % [visited.size(), dungeon.get_room_count()])
		
		return _create_fallback_dungeon()
	
	return dungeon


# ---------------------------------------------------------------------------
# Stage 2: Parameter Calculation
# ---------------------------------------------------------------------------

## Calculates room count from phase, rarity, and vigor.
func _calc_room_count(phase: Enums.SeedPhase, rarity: Enums.SeedRarity, vigor: int) -> int:
	var base: int = ROOM_COUNT_BASE.get(phase, 3)
	var rarity_bonus: int = ROOM_COUNT_BONUS.get(rarity, 0)
	var vigor_bonus: int = floori(float(vigor) / 33.0)
	vigor_bonus = clampi(vigor_bonus, 0, 3)
	
	var count: int = base + rarity_bonus + vigor_bonus
	
	# Clamp to vigor-scaled range
	var clamp_min: int = 3
	var clamp_max: int = 28
	for entry in ROOM_COUNT_CLAMP:
		if vigor <= entry.x:
			clamp_min = int(entry.y)
			clamp_max = int(entry.z)
			break
	
	return clampi(count, clamp_min, clamp_max)


## Calculates branching factor from vigor (linear interpolation).
func _calc_branching_factor(vigor: int) -> float:
	return _lerp_table(BRANCHING_FACTOR_TABLE, float(vigor))


## Calculates base difficulty from vigor and element.
func _calc_base_difficulty(vigor: int, element: Enums.Element) -> float:
	var multiplier: float = ELEMENT_DIFFICULTY.get(element, 1.0)
	return (float(vigor) / 100.0) * multiplier


## Linear interpolation helper for vigor tables.
func _lerp_table(table: Array[Vector2], vigor: float) -> float:
	if table.is_empty():
		return 0.0
	if vigor <= table[0].x:
		return table[0].y
	if vigor >= table[-1].x:
		return table[-1].y
	
	for i in range(table.size() - 1):
		var p0: Vector2 = table[i]
		var p1: Vector2 = table[i + 1]
		if vigor >= p0.x and vigor <= p1.x:
			var t: float = (vigor - p0.x) / (p1.x - p0.x)
			return lerpf(p0.y, p1.y, t)
	
	return table[-1].y


## Converts rarity to vigor proxy (for when SeedData has no vigor field).
func _rarity_to_vigor(rarity: Enums.SeedRarity) -> int:
	match rarity:
		Enums.SeedRarity.COMMON:
			return 20
		Enums.SeedRarity.UNCOMMON:
			return 40
		Enums.SeedRarity.RARE:
			return 60
		Enums.SeedRarity.EPIC:
			return 80
		Enums.SeedRarity.LEGENDARY:
			return 100
		_:
			return 50


# ---------------------------------------------------------------------------
# Stage 3: Room Graph Generation
# ---------------------------------------------------------------------------

## Places rooms at random non-overlapping grid positions.
func _place_rooms_on_grid(room_count: int, rng: DeterministicRNG) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var occupied: Dictionary = {}
	var grid_size: int = ceili(sqrt(float(room_count)) * 2.0)
	
	for i in range(room_count):
		var attempts: int = 0
		var pos: Vector2
		while attempts < 100:
			var gx: int = rng.randi(grid_size)
			var gy: int = rng.randi(grid_size)
			var key: Vector2i = Vector2i(gx, gy)
			if not occupied.has(key):
				pos = Vector2(float(gx) * GRID_SPACING, float(gy) * GRID_SPACING)
				occupied[key] = true
				break
			attempts += 1
		
		if attempts >= 100:
			# Fallback: place at sequential position
			pos = Vector2(float(i % grid_size) * GRID_SPACING, float(i / grid_size) * GRID_SPACING)
		
		positions.append(pos)
	
	return positions


## Builds a minimum spanning tree using Prim's algorithm.
func _build_mst_prim(positions: Array[Vector2], rng: DeterministicRNG) -> Array[Vector2i]:
	var room_count: int = positions.size()
	if room_count < 2:
		return []
	
	var edges: Array[Vector2i] = []
	var in_tree: Array[bool] = []
	in_tree.resize(room_count)
	for i in range(room_count):
		in_tree[i] = false
	
	# Start from room 0
	in_tree[0] = true
	var tree_size: int = 1
	
	# Add edges until all rooms are in tree
	while tree_size < room_count:
		var best_a: int = -1
		var best_b: int = -1
		var best_dist: float = INF
		
		# Find cheapest edge from tree to non-tree
		for a in range(room_count):
			if not in_tree[a]:
				continue
			for b in range(room_count):
				if in_tree[b]:
					continue
				var dist: float = positions[a].distance_to(positions[b])
				if dist < best_dist:
					best_dist = dist
					best_a = a
					best_b = b
		
		if best_a >= 0 and best_b >= 0:
			var edge: Vector2i = _canonical_edge(best_a, best_b)
			edges.append(edge)
			in_tree[best_b] = true  # Mark the non-tree node
			tree_size += 1
		else:
			# No more edges found - shouldn't happen
			break
	
	return edges


## Adds random shortcut edges beyond the MST.
func _add_shortcut_edges(
	mst_edges: Array[Vector2i],
	positions: Array[Vector2],
	branching_factor: float,
	room_count: int,
	rng: DeterministicRNG
) -> Array[Vector2i]:
	var all_edges: Array[Vector2i] = mst_edges.duplicate()
	var max_shortcuts: int = floori(branching_factor * float(room_count))
	
	if max_shortcuts <= 0:
		return all_edges
	
	# Build list of possible edges not in MST
	var possible: Array[Vector2i] = []
	for a in range(room_count):
		for b in range(a + 1, room_count):
			var edge: Vector2i = Vector2i(a, b)
			if not _edge_exists(all_edges, a, b):
				possible.append(edge)
	
	# Shuffle and add shortcuts
	rng.shuffle(possible)
	var added: int = 0
	for edge in possible:
		if added >= max_shortcuts:
			break
		all_edges.append(edge)
		added += 1
	
	return all_edges


## Returns true if edge (a,b) exists in the edge list (either direction).
func _edge_exists(edges: Array[Vector2i], a: int, b: int) -> bool:
	var canonical: Vector2i = _canonical_edge(a, b)
	for edge in edges:
		if edge == canonical:
			return true
	return false


## Returns canonical edge with smaller index first.
func _canonical_edge(a: int, b: int) -> Vector2i:
	if a < b:
		return Vector2i(a, b)
	else:
		return Vector2i(b, a)


# ---------------------------------------------------------------------------
# Stage 4: Room Type Assignment
# ---------------------------------------------------------------------------

## Assigns room types based on element bias and traits.
func _assign_room_types(dungeon: DungeonData, element: Enums.Element, traits: Dictionary, rng: DeterministicRNG) -> void:
	var room_count: int = dungeon.rooms.size()
	
	# Fixed assignments - ENTRANCE at start, BOSS at end
	if room_count > 0:
		dungeon.rooms[0].type = Enums.RoomType.ENTRANCE
	if room_count > 1:
		dungeon.rooms[room_count - 1].type = Enums.RoomType.BOSS
	
	# Calculate critical path for REST and SECRET placement
	var critical_path: Array[int] = dungeon.get_path_to_boss()
	var critical_set: Dictionary = {}
	for idx in critical_path:
		critical_set[idx] = true
	
	# Place REST rooms on critical path
	var rest_count: int = 0
	if room_count >= 4:
		rest_count = 1
	if room_count >= 8:
		rest_count = 2
	
	if rest_count > 0 and critical_path.size() > 2:
		var rest_positions: Array[int] = []
		if rest_count >= 1:
			var idx_40: int = floori(float(critical_path.size()) * 0.4)
			rest_positions.append(critical_path[idx_40])
		if rest_count >= 2:
			var idx_70: int = floori(float(critical_path.size()) * 0.7)
			rest_positions.append(critical_path[idx_70])
		
		for idx in rest_positions:
			if idx > 0 and idx < room_count - 1:
				dungeon.rooms[idx].type = Enums.RoomType.REST
	
	# Place SECRET rooms on non-critical-path branch rooms
	var secret_count: int = _calc_secret_room_count(room_count)
	if secret_count > 0:
		var branch_rooms: Array[int] = []
		for i in range(1, room_count - 1):
			if not critical_set.has(i) and dungeon.rooms[i].type != Enums.RoomType.REST:
				branch_rooms.append(i)
		# Shuffle branch rooms deterministically and pick up to secret_count
		if branch_rooms.size() > 1:
			for j in range(branch_rooms.size() - 1, 0, -1):
				var k: int = rng.randi_range(0, j)
				var temp: int = branch_rooms[j]
				branch_rooms[j] = branch_rooms[k]
				branch_rooms[k] = temp
		var assigned: int = mini(secret_count, branch_rooms.size())
		for s in range(assigned):
			dungeon.rooms[branch_rooms[s]].type = Enums.RoomType.SECRET
	
	# Build modified weights with element bias
	var weights: Dictionary = ROOM_TYPE_WEIGHTS.duplicate()
	var element_mods: Dictionary = ELEMENT_BIASES.get(element, {})
	for room_type in element_mods:
		weights[room_type] = weights.get(room_type, 0.0) + element_mods[room_type]
	
	# Apply hazard frequency trait
	var hazard_freq: float = float(traits.get("hazard_frequency", 0.2))
	weights[Enums.RoomType.TRAP] = weights.get(Enums.RoomType.TRAP, 15.0) + (hazard_freq * 20.0)
	
	# Apply room_variety trait modulation
	var room_variety: float = float(traits.get("room_variety", 0.5))
	if room_variety > 0.5:
		# High variety: flatten weights toward equal distribution
		var avg_weight: float = 0.0
		for w in weights.values():
			avg_weight += float(w)
		avg_weight /= float(weights.size()) if weights.size() > 0 else 1.0
		var flatten_factor: float = (room_variety - 0.5) * 2.0  # 0.0 to 1.0
		for room_type in weights:
			var current: float = float(weights[room_type])
			weights[room_type] = current + (avg_weight - current) * flatten_factor
	elif room_variety < 0.5:
		# Low variety: amplify the dominant weight
		var max_weight: float = 0.0
		for w in weights.values():
			max_weight = maxf(max_weight, float(w))
		var amplify_factor: float = (0.5 - room_variety) * 2.0  # 0.0 to 1.0
		for room_type in weights:
			var current: float = float(weights[room_type])
			if current >= max_weight - 0.01:
				weights[room_type] = current * (1.0 + amplify_factor * 0.5)
			else:
				weights[room_type] = current * (1.0 - amplify_factor * 0.3)
	
	# Assign remaining rooms via weighted pick
	for i in range(1, room_count - 1):
		if dungeon.rooms[i].type == Enums.RoomType.REST or dungeon.rooms[i].type == Enums.RoomType.SECRET:
			continue
		
		# Weighted pick
		var items: Array = []
		var weight_vals: Array[float] = []
		for room_type in weights:
			items.append(room_type)
			weight_vals.append(float(weights[room_type]))
		
		var picked: Variant = rng.weighted_pick(items, weight_vals)
		if picked != null:
			dungeon.rooms[i].type = picked as Enums.RoomType
		else:
			dungeon.rooms[i].type = Enums.RoomType.COMBAT


## Calculates the number of SECRET rooms based on total room count.
func _calc_secret_room_count(room_count: int) -> int:
	if room_count <= 5:
		return 0
	elif room_count <= 10:
		return 1
	elif room_count <= 18:
		return 2
	else:
		return 3


# ---------------------------------------------------------------------------
# Stage 5: Difficulty Assignment
# ---------------------------------------------------------------------------

## Assigns per-room difficulty based on depth and type.
func _assign_difficulties(dungeon: DungeonData, base_difficulty: float) -> void:
	var critical_path: Array[int] = dungeon.get_path_to_boss()
	var room_count: int = dungeon.rooms.size()
	
	# Build depth map
	var depth_map: Dictionary = {}
	for i in range(critical_path.size()):
		depth_map[critical_path[i]] = float(i) / float(maxi(critical_path.size() - 1, 1))
	
	# Assign depth to non-critical rooms (use nearest neighbor)
	for i in range(room_count):
		if not depth_map.has(i):
			var neighbors: Array[int] = dungeon.get_adjacent(i)
			var best_depth: float = 0.5
			for neighbor in neighbors:
				if depth_map.has(neighbor):
					best_depth = depth_map[neighbor]
					break
			depth_map[i] = best_depth
	
	# Calculate per-room difficulty
	var total_difficulty: float = 0.0
	var non_zero_count: int = 0
	
	for i in range(room_count):
		var room: RoomData = dungeon.rooms[i]
		var depth_factor: float = depth_map.get(i, 0.5)
		var type_modifier: float = ROOM_TYPE_DIFFICULTY_MODIFIER.get(room.type, 1.0)
		var difficulty: float = base_difficulty * (0.3 + 0.7 * depth_factor) * type_modifier
		
		room.difficulty = floori(difficulty * 100.0)  # Convert to integer 0-100
		
		if room.difficulty > 0:
			total_difficulty += float(room.difficulty)
			non_zero_count += 1
	
	# Set dungeon-wide difficulty rating
	if non_zero_count > 0:
		dungeon.difficulty = floori(total_difficulty / float(non_zero_count))
	else:
		dungeon.difficulty = 1


# ---------------------------------------------------------------------------
# Stage 6: Loot Bias Assignment
# ---------------------------------------------------------------------------

## Assigns loot bias to each room based on type and seed traits.
func _assign_loot_biases(dungeon: DungeonData, traits: Dictionary) -> void:
	var loot_trait: String = str(traits.get("loot_bias", "gold")).to_lower()
	for room in dungeon.rooms:
		var base_bias: Dictionary = DEFAULT_LOOT_BIAS.get(room.type, {})
		if base_bias.is_empty():
			room.loot_bias = {}
			continue
		room.loot_bias = base_bias.duplicate()
		# Shift bias based on loot_bias trait
		if loot_trait == "essence" and room.loot_bias.has(Enums.Currency.ESSENCE):
			room.loot_bias[Enums.Currency.ESSENCE] = float(room.loot_bias[Enums.Currency.ESSENCE]) + 0.15
			_normalize_loot_bias(room.loot_bias)
		elif loot_trait == "fragments" and room.loot_bias.has(Enums.Currency.FRAGMENTS):
			room.loot_bias[Enums.Currency.FRAGMENTS] = float(room.loot_bias[Enums.Currency.FRAGMENTS]) + 0.15
			_normalize_loot_bias(room.loot_bias)


## Normalizes loot bias weights to sum to 1.0.
func _normalize_loot_bias(bias: Dictionary) -> void:
	var total: float = 0.0
	for v in bias.values():
		total += float(v)
	if total > 0.0:
		for key in bias:
			bias[key] = float(bias[key]) / total


# ---------------------------------------------------------------------------
# Fallback
# ---------------------------------------------------------------------------

## Creates a minimal valid 3-room dungeon as fallback.
func _create_fallback_dungeon() -> DungeonData:
	var dungeon := DungeonData.new()
	dungeon.seed_id = "fallback"
	dungeon.element = Enums.Element.TERRA
	dungeon.entry_room_index = 0
	dungeon.boss_room_index = 2
	
	for i in range(3):
		var room := RoomData.new()
		room.index = i
		room.position = Vector2(float(i) * GRID_SPACING, 0.0)
		room.difficulty = 1
		room.is_cleared = false
		
		if i == 0:
			room.type = Enums.RoomType.ENTRANCE
		elif i == 1:
			room.type = Enums.RoomType.COMBAT
		else:
			room.type = Enums.RoomType.BOSS
		
		dungeon.rooms.append(room)
	
	dungeon.edges.append(Vector2i(0, 1))
	dungeon.edges.append(Vector2i(1, 2))
	dungeon.difficulty = 1
	
	return dungeon
