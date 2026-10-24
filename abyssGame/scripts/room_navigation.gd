class_name RoomNavigation
extends RefCounted

const CELL := 20.0
var grid := AStarGrid2D.new()
var obstacles: Array[Rect2] = []

func configure(bounds: Rect2, pillars: Array[Rect2], clearance: float = 22.0) -> void:
	var usable := bounds.grow(-clearance)
	grid.region = Rect2i(Vector2i.ZERO, Vector2i(floori(usable.size.x / CELL) + 1, floori(usable.size.y / CELL) + 1))
	grid.cell_size = Vector2(CELL, CELL)
	grid.offset = usable.position
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	obstacles.clear()
	for pillar in pillars:
		obstacles.append(pillar.grow(clearance))
	for x in range(grid.region.size.x):
		for y in range(grid.region.size.y):
			var cell := Vector2i(x, y)
			var point := grid.get_point_position(cell)
			for obstacle in obstacles:
				if obstacle.grow(CELL * 0.5).has_point(point):
					grid.set_point_solid(cell)

func can_travel(start: Vector2, end: Vector2) -> bool:
	for rect in obstacles:
		if rect.has_point(start) or rect.has_point(end):
			return false
		var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for i in range(4):
			if Geometry2D.segment_intersects_segment(start, end, corners[i], corners[(i + 1) % 4]) != null:
				return false
	return true

func _nearest_walkable(point: Vector2) -> Vector2i:
	var raw := Vector2i(((point - grid.offset) / CELL).round())
	var cell := Vector2i(clampi(raw.x, 0, grid.region.size.x - 1), clampi(raw.y, 0, grid.region.size.y - 1))
	if not grid.is_point_solid(cell):
		return cell
	var closest := Vector2i(-1, -1)
	var best := INF
	for x in range(grid.region.size.x):
		for y in range(grid.region.size.y):
			var candidate := Vector2i(x, y)
			if not grid.is_point_solid(candidate):
				var distance := point.distance_squared_to(grid.get_point_position(candidate))
				if distance < best:
					best = distance
					closest = candidate
	return closest

func find_path(start: Vector2, end: Vector2) -> PackedVector2Array:
	var first := _nearest_walkable(start)
	var last := _nearest_walkable(end)
	if first.x < 0 or last.x < 0:
		return PackedVector2Array()
	return grid.get_point_path(first, last)
