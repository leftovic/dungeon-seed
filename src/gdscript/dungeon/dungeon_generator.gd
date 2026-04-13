extends Reference

class_name DungeonGenerator

# Generates a simple deterministic dungeon layout as a 2D array of ints (0=wall, 1=floor)
# Uses RNGWrapperImpl for deterministic random generation
# Params:
#   width: int - dungeon width
#   height: int - dungeon height
#   seed: int - seed for deterministic generation
# Returns: 2D Array of ints
func generate(width: int, height: int, room_count: int, seed) -> Dictionary:
	# Simple room placement with non-overlap attempts and straight corridors
	var rng = _new_rng(seed)
	var rooms := []
	var max_attempts := room_count * 5
	var attempts := 0
	while rooms.size() < room_count and attempts < max_attempts:
		attempts += 1
		var rw = int(4 + rng.randi(8))
		var rh = int(4 + rng.randi(8))
		var rx = int(rng.randi(max(1, width - rw - 1)))
		var ry = int(rng.randi(max(1, height - rh - 1)))
		var candidate = {"x": rx, "y": ry, "w": rw, "h": rh}
		var ok = true
		for r in rooms:
			if _rects_overlap(candidate, r, 1):
				ok = false
				break
		if ok:
			rooms.append(candidate)

	# If couldn't place enough, continue attempting with higher attempts
	if rooms.size() < room_count:
		# try relaxed placement
		while rooms.size() < room_count and attempts < max_attempts * 4:
			attempts += 1
			var rw2 = int(3 + rng.randi(10))
			var rh2 = int(3 + rng.randi(10))
			var rx2 = int(rng.randi(max(1, width - rw2 - 1)))
			var ry2 = int(rng.randi(max(1, height - rh2 - 1)))
			var cand2 = {"x": rx2, "y": ry2, "w": rw2, "h": rh2}
			var ok2 = true
			for r in rooms:
				if _rects_overlap(cand2, r, 0):
					ok2 = false; break
			if ok2:
				rooms.append(cand2)

	# Build corridors by connecting room centers using a simple minimum spanning via greedy nearest
	var centers := []
	for r in rooms:
		var cx = r.x + int(r.w / 2)
		var cy = r.y + int(r.h / 2)
		centers.append({"x": cx, "y": cy})

	var corridors := []
	if centers.size() > 1:
		var connected := [centers[0]]
		var remaining := centers.duplicate()
		remaining.remove(0)
		while remaining.size() > 0:
			# find nearest
			var best_i = -1
			var best_d = 1e18
			for i in range(remaining.size()):
				for j in range(connected.size()):
					var dx = remaining[i].x - connected[j].x
					var dy = remaining[i].y - connected[j].y
					var d = dx * dx + dy * dy
					if d < best_d:
						best_d = d; best_i = i
			# connect best to nearest connected
			var target = remaining[best_i]
			# find nearest connected index
			var best_c = connected[0]
			var best_cd = 1e18
			for c in connected:
				var dx2 = c.x - target.x
				var dy2 = c.y - target.y
				var d2 = dx2 * dx2 + dy2 * dy2
				if d2 < best_cd:
					best_cd = d2; best_c = c
			# corridor: L-shaped
			corridors.append([best_c.x, best_c.y, target.x, target.y])
			connected.append(target)
			remaining.remove(best_i)

	# Clean up
	rng.free()

	return {"width": width, "height": height, "rooms": rooms, "corridors": corridors}

func _rects_overlap(a: Dictionary, b: Dictionary, pad: int) -> bool:
	if a.x + a.w + pad <= b.x:
		return false
	if b.x + b.w + pad <= a.x:
		return false
	if a.y + a.h + pad <= b.y:
		return false
	if b.y + b.h + pad <= a.y:
		return false
	return true