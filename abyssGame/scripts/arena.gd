extends Node2D

const ENEMY := preload("res://scenes/enemy.tscn")
const PROJECTILE := preload("res://scenes/projectile.tscn")
const TUNING := preload("res://resources/default_tuning.tres")
const BASE_SIZE := Vector2(1280.0, 800.0)
const WALL_THICKNESS := 20.0
const DOOR_SPAN := 116.0
const DOOR_THICKNESS := 24.0

var floor_bounds := Rect2(Vector2.ZERO, BASE_SIZE)
var player: AbyssPlayer
var enemies: Array[PracticeEnemy] = []
var navigation := RoomNavigation.new()
var feedback_layer: CombatFeedback
var practice_mode: bool = false
var current_room: int = 0
var room_cleared: Dictionary = {0: true, 1: false, 2: true}
var current_pillars: Array[Rect2] = []
var doors: Array[Dictionary] = []
var transitioning: bool = false
var transition_fade: ColorRect
var door_clock: float = 0.0

func _ready() -> void:
	player = $Actors/Player
	player.practice_invulnerable = false
	feedback_layer = $Feedback
	player.fired.connect(_shoot)
	player.feedback.connect(_feedback)
	player.died.connect(_on_death)
	_create_transition_fade()
	floor_bounds = get_viewport_rect()
	_load_room(0, "start")
	get_viewport().size_changed.connect(_resize_arena)

func _create_transition_fade() -> void:
	transition_fade = ColorRect.new()
	transition_fade.color = Color(0.02, 0.04, 0.07, 0.0)
	transition_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$CanvasLayer.add_child(transition_fade)

func _scaled(value: Vector2) -> Vector2:
	return Vector2(value.x * floor_bounds.size.x / BASE_SIZE.x, value.y * floor_bounds.size.y / BASE_SIZE.y)

func _point(x: float, y: float) -> Vector2:
	return floor_bounds.position + _scaled(Vector2(x, y))

func _room_rect(x: float, y: float, width: float, height: float) -> Rect2:
	return Rect2(_point(x, y), _scaled(Vector2(width, height)))

func _room_pillars(room_id: int) -> Array[Rect2]:
	match room_id:
		0:
			return [_room_rect(570, 294, 44, 86), _room_rect(570, 496, 44, 86)]
		1:
			return [_room_rect(476, 216, 44, 132), _room_rect(476, 452, 44, 132), _room_rect(760, 334, 44, 132)]
		2:
			return [_room_rect(596, 292, 48, 216)]
	return []

func _room_enemy_spawns(room_id: int) -> Array[Vector2]:
	if room_id != 1 or bool(room_cleared.get(room_id, true)):
		return []
	return [_point(760, 230), _point(928, 400), _point(760, 594)]

func _room_exits(room_id: int) -> Array[Dictionary]:
	match room_id:
		0:
			return [{"side": "right", "target": 1, "entry": "left"}]
		1:
			return [{"side": "left", "target": 0, "entry": "right"}, {"side": "right", "target": 2, "entry": "left"}]
		2:
			return [{"side": "left", "target": 1, "entry": "right"}]
	return []

func _room_needs_clear() -> bool:
	return current_room == 1 and not bool(room_cleared.get(current_room, true))

func _door_rect(side: String) -> Rect2:
	var start := floor_bounds.position
	var end := floor_bounds.end
	match side:
		"left":
			return Rect2(start.x, floor_bounds.get_center().y - DOOR_SPAN * 0.5, DOOR_THICKNESS, DOOR_SPAN)
		"right":
			return Rect2(end.x - DOOR_THICKNESS, floor_bounds.get_center().y - DOOR_SPAN * 0.5, DOOR_THICKNESS, DOOR_SPAN)
		"top":
			return Rect2(floor_bounds.get_center().x - DOOR_SPAN * 0.5, start.y, DOOR_SPAN, DOOR_THICKNESS)
		"bottom":
			return Rect2(floor_bounds.get_center().x - DOOR_SPAN * 0.5, end.y - DOOR_THICKNESS, DOOR_SPAN, DOOR_THICKNESS)
	return Rect2()

func _configure_doors() -> void:
	doors.clear()
	var open := not _room_needs_clear()
	for exit_data in _room_exits(current_room):
		var door := exit_data.duplicate()
		door["rect"] = _door_rect(str(door["side"]))
		door["open"] = open
		doors.append(door)

func _wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	body.add_child(shape)
	$Geometry.add_child(body)

func _doors_on_side(side: String) -> Array[Rect2]:
	var openings: Array[Rect2] = []
	for door in doors:
		if str(door["side"]) == side:
			openings.append(door["rect"])
	return openings

func _vertical_boundary(x: float, openings: Array[Rect2]) -> void:
	var cursor := floor_bounds.position.y
	var end_y := floor_bounds.end.y
	for opening in openings:
		if opening.position.y > cursor:
			_wall(Rect2(x, cursor, WALL_THICKNESS, opening.position.y - cursor))
		cursor = maxf(cursor, opening.end.y)
	if cursor < end_y:
		_wall(Rect2(x, cursor, WALL_THICKNESS, end_y - cursor))

func _clear_geometry() -> void:
	for node in $Geometry.get_children():
		node.queue_free()

func _build_geometry() -> void:
	_clear_geometry()
	var start := floor_bounds.position
	var end := floor_bounds.end
	_wall(Rect2(start.x - WALL_THICKNESS, start.y - WALL_THICKNESS, floor_bounds.size.x + WALL_THICKNESS * 2.0, WALL_THICKNESS))
	_wall(Rect2(start.x - WALL_THICKNESS, end.y, floor_bounds.size.x + WALL_THICKNESS * 2.0, WALL_THICKNESS))
	_vertical_boundary(start.x - WALL_THICKNESS, _doors_on_side("left"))
	_vertical_boundary(end.x, _doors_on_side("right"))
	for pillar in current_pillars:
		_wall(pillar)
	var obstacles: Array[Rect2] = current_pillars.duplicate()
	for door in doors:
		if not bool(door["open"]):
			var door_rect: Rect2 = door["rect"]
			_wall(door_rect)
			obstacles.append(door_rect.grow(18.0))
	navigation.configure(floor_bounds, obstacles)

func _clear_room_content() -> void:
	for actor in $Actors.get_children():
		if actor != player:
			actor.queue_free()
	enemies.clear()
	for projectile in $Projectiles.get_children():
		projectile.queue_free()

func _place_player(entry: String) -> void:
	match entry:
		"left":
			player.global_position = _point(116, 400)
		"right":
			player.global_position = _point(1164, 400)
		_:
			player.global_position = _point(208, 400)
	player.velocity = Vector2.ZERO

func _load_room(room_id: int, entry: String) -> void:
	_clear_room_content()
	current_room = room_id
	current_pillars = _room_pillars(room_id)
	_configure_doors()
	_build_geometry()
	_place_player(entry)
	for spawn_point in _room_enemy_spawns(room_id):
		_spawn_enemy(spawn_point)
	queue_redraw()

func _resize_arena() -> void:
	var new_bounds := get_viewport_rect()
	if new_bounds == floor_bounds:
		return
	floor_bounds = new_bounds
	current_pillars = _room_pillars(current_room)
	_configure_doors()
	_build_geometry()
	var safe := floor_bounds.grow(-48.0)
	player.global_position = player.global_position.clamp(safe.position, safe.end)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.global_position = enemy.global_position.clamp(safe.position, safe.end)
	queue_redraw()

func _spawn_enemy(where: Vector2) -> PracticeEnemy:
	var enemy := ENEMY.instantiate() as PracticeEnemy
	enemy.global_position = where
	enemy.player = player
	enemy.dummy = false
	enemy.navigation = navigation
	enemy.feedback.connect(_feedback)
	enemy.destroyed.connect(_on_enemy_destroyed.bind(enemy))
	$Actors.add_child(enemy)
	enemies.append(enemy)
	return enemy

func _active_enemy_count() -> int:
	var count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.active:
			count += 1
	return count

func _on_enemy_destroyed(where: Vector2, _enemy: PracticeEnemy) -> void:
	_feedback("destroyed", where)
	if _room_needs_clear() and _active_enemy_count() == 0:
		room_cleared[current_room] = true
		_refresh_doors()

func _refresh_doors() -> void:
	var open := not _room_needs_clear()
	for index in doors.size():
		var door := doors[index]
		door["open"] = open
		doors[index] = door
	_build_geometry()
	queue_redraw()

func _check_doors() -> void:
	if transitioning or not player.active:
		return
	for door in doors:
		if not bool(door["open"]):
			continue
		var door_rect: Rect2 = door["rect"]
		if door_rect.grow(44.0).has_point(player.global_position):
			_begin_room_transition(int(door["target"]), str(door["entry"]))
			return

func _begin_room_transition(target: int, entry: String) -> void:
	if transitioning:
		return
	transitioning = true
	player.active = false
	player.velocity = Vector2.ZERO
	for projectile in $Projectiles.get_children():
		projectile.queue_free()
	var tween := create_tween()
	tween.tween_property(transition_fade, "color:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_switch_room.bind(target, entry))
	tween.tween_property(transition_fade, "color:a", 0.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_room_transition)

func _switch_room(target: int, entry: String) -> void:
	_load_room(target, entry)

func _finish_room_transition() -> void:
	player.active = true
	player.practice_invulnerable = false
	transitioning = false

func _physics_process(delta: float) -> void:
	door_clock += delta
	if player.active and not transitioning:
		player.hope = maxf(1.0, player.hope - TUNING.hope_drain_per_second * delta)
		_check_doors()
	queue_redraw()

func _shoot(origin: Vector2, direction: Vector2) -> void:
	var bullet := PROJECTILE.instantiate() as BasicProjectile
	bullet.global_position = origin
	bullet.direction = direction
	bullet.speed = TUNING.projectile_speed
	bullet.damage = TUNING.projectile_damage
	bullet.impact.connect(func(where: Vector2): _effect(where, Color("75f6d0"), 12.0))
	$Projectiles.add_child(bullet)

func _effect(where: Vector2, color: Color, radius: float = 50.0) -> void:
	feedback_layer.burst(where, color, radius)

func _feedback(kind: String, where: Vector2) -> void:
	feedback_layer.trigger(kind, where)

func toggle_practice() -> void:
	practice_mode = false
	player.practice_invulnerable = false

func _on_death() -> void:
	$CanvasLayer/HUD.show_overlay("FIN DE LA PRUEBA", "Recibiste 3 golpes. Reinicia y prueba otra vez.", true)

func _room_color() -> Color:
	match current_room:
		0:
			return Color("0c1724")
		1:
			return Color("171522")
		2:
			return Color("0d1925")
	return Color("0c1724")

func _draw_door(door: Dictionary) -> void:
	var rect: Rect2 = door["rect"]
	var open := bool(door["open"])
	var pulse := 0.55 + sin(door_clock * 3.0) * 0.25
	var color := Color("75f6d0") if open else Color("d86179")
	var fill := color
	fill.a = 0.12 + pulse * 0.12
	draw_rect(rect, fill)
	draw_rect(rect, color, false, 2.0)
	var center := rect.get_center()
	if str(door["side"]) in ["left", "right"]:
		draw_line(center - Vector2(0, rect.size.y * 0.33), center + Vector2(0, rect.size.y * 0.33), color, 3.0, true)
		if not open:
			draw_line(center - Vector2(18, 0), center + Vector2(18, 0), color, 2.0, true)
	else:
		draw_line(center - Vector2(rect.size.x * 0.33, 0), center + Vector2(rect.size.x * 0.33, 0), color, 3.0, true)
		if not open:
			draw_line(center - Vector2(0, 18), center + Vector2(0, 18), color, 2.0, true)

func _draw() -> void:
	draw_rect(floor_bounds, _room_color())
	for x in range(floori(floor_bounds.position.x), ceili(floor_bounds.end.x), 40):
		draw_line(Vector2(x, floor_bounds.position.y), Vector2(x, floor_bounds.end.y), Color("132231"), 1.0)
	for y in range(floori(floor_bounds.position.y), ceili(floor_bounds.end.y), 40):
		draw_line(Vector2(floor_bounds.position.x, y), Vector2(floor_bounds.end.x, y), Color("132231"), 1.0)
	for pillar in current_pillars:
		draw_rect(Rect2(pillar.position + Vector2(5, 6), pillar.size), Color(0, 0, 0, 0.3))
		draw_rect(pillar, Color("2e3e4f"))
		draw_rect(pillar.grow(-5), Color("3a4e61"), false, 1.0)
	for door in doors:
		_draw_door(door)
