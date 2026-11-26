extends Node2D

const ENEMY := preload("res://scenes/enemy.tscn")
const LASER := preload("res://scenes/laser_enemy.tscn")
const BOSS := preload("res://scenes/boss.tscn")
const PROJECTILE := preload("res://scenes/projectile.tscn")
const TUNING := preload("res://resources/default_tuning.tres")
const ROOMS := preload("res://scripts/level_catalog.gd").ROOMS
const BASE_SIZE := Vector2(1280.0, 800.0)
const WALL_THICKNESS := 20.0
const DOOR_SPAN := 116.0
const DOOR_THICKNESS := 24.0
const UPGRADES := [
	{"id": "move", "title": "MOVILIDAD", "description": "+25 de velocidad de movimiento por nivel.", "price": 4, "max_rank": 3},
	{"id": "rate", "title": "CADENCIA", "description": "Reduce el intervalo entre disparos en 2 ticks por nivel.", "price": 5, "max_rank": 3},
	{"id": "power", "title": "POTENCIA", "description": "+1 de daño y más FRAC por impacto por nivel.", "price": 6, "max_rank": 3},
	{"id": "bounce", "title": "REBOTE", "description": "Permite hasta 2 rebotes. Estos impactos suman más FRAC.", "price": 6, "max_rank": 1},
	{"id": "armor", "title": "PARRY BLINDADO", "description": "Un PARRY exitoso te protege durante 0,4 segundos.", "price": 7, "max_rank": 1},
	{"id": "critical", "title": "CADENCIA CRÍTICA", "description": "Cada tercer disparo suma +2 de daño, FRAC y aturde.", "price": 8, "max_rank": 1},
]

var floor_bounds := Rect2(Vector2.ZERO, BASE_SIZE)
var player: AbyssPlayer
var enemies: Array[PracticeEnemy] = []
var boss: PracticeEnemy
var navigation := RoomNavigation.new()
var feedback_layer: CombatFeedback
var current_room: int = 0
var room_cleared: Dictionary = {}
var current_pillars: Array[Rect2] = []
var doors: Array[Dictionary] = []
var transitioning: bool = false
var aura: int = 0
var shop_pending: bool = false
var transition_fade: ColorRect
var door_clock: float = 0.0

func _ready() -> void:
	player = $Actors/Player
	feedback_layer = $Feedback
	player.fired.connect(_shoot)
	player.feedback.connect(_feedback)
	player.died.connect(_on_death)
	_create_transition_fade()
	floor_bounds = get_viewport_rect()
	_load_room(0, "start")
	if not get_tree().has_meta("abyss_retry"):
		$CanvasLayer/HUD.show_start()
	else:
		get_tree().remove_meta("abyss_retry")
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

func _room_pillars(room_id: int) -> Array[Rect2]:
	var pillars: Array[Rect2] = []
	for rect: Rect2 in ROOMS[room_id]["cover"]:
		pillars.append(Rect2(_point(rect.position.x, rect.position.y), _scaled(rect.size)))
	return pillars

func room_name() -> String:
	return ROOMS[current_room]["name"]

func _is_boss_room() -> bool:
	return ROOMS[current_room].get("boss", false)

func _room_exits(room_id: int) -> Array[Dictionary]:
	var exits: Array[Dictionary] = []
	if room_id > 0:
		exits.append({"side": "left", "target": room_id - 1, "entry": "right"})
	if room_id < ROOMS.size() - 1:
		exits.append({"side": "right", "target": room_id + 1, "entry": "left"})
	return exits

func _room_needs_clear() -> bool:
	var room: Dictionary = ROOMS[current_room]
	return not room_cleared.has(current_room) and (not room["spawns"].is_empty() or not room.get("laser_spawns", []).is_empty())

func _door_rect(side: String) -> Rect2:
	var start := floor_bounds.position
	var end := floor_bounds.end
	match side:
		"left":
			return Rect2(start.x, floor_bounds.get_center().y - DOOR_SPAN * 0.5, DOOR_THICKNESS, DOOR_SPAN)
		"right":
			return Rect2(end.x - DOOR_THICKNESS, floor_bounds.get_center().y - DOOR_SPAN * 0.5, DOOR_THICKNESS, DOOR_SPAN)
	return Rect2()

func _configure_doors() -> void:
	doors.clear()
	var open := not shop_pending and not _room_needs_clear()
	for exit_data in _room_exits(current_room):
		var door := exit_data.duplicate()
		door["rect"] = _door_rect(str(door["side"]))
		door["open"] = open
		doors.append(door)

func _wall(rect: Rect2) -> StaticBody2D:
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
	return body

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
		$Geometry.remove_child(node)
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
	for door in doors:
		if not bool(door["open"]):
			door["body"] = _wall(door["rect"])
	navigation.configure(floor_bounds, current_pillars, 42.0 if _is_boss_room() else 22.0)

func _clear_room_content() -> void:
	for actor in $Actors.get_children():
		if actor != player:
			$Actors.remove_child(actor)
			actor.queue_free()
	enemies.clear()
	boss = null
	for projectile in $Projectiles.get_children():
		$Projectiles.remove_child(projectile)
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
	if _room_needs_clear():
		var scene := BOSS if _is_boss_room() else ENEMY
		for spawn_point: Vector2 in ROOMS[room_id]["spawns"]:
			_spawn_enemy(_point(spawn_point.x, spawn_point.y), scene)
		for spawn_point: Vector2 in ROOMS[room_id].get("laser_spawns", []):
			_spawn_enemy(_point(spawn_point.x, spawn_point.y), LASER)
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

func _spawn_enemy(where: Vector2, scene: PackedScene) -> PracticeEnemy:
	var enemy := scene.instantiate() as PracticeEnemy
	if scene == BOSS:
		boss = enemy
	enemy.global_position = where
	enemy.player = player
	enemy.speed_scale = ROOMS[current_room].get("speed_scale", 1.0)
	enemy.attack_delay_scale = ROOMS[current_room].get("attack_delay_scale", 1.0)
	enemy.dummy = false
	enemy.navigation = navigation
	enemy.feedback.connect(_feedback)
	var reward := 10 if scene == BOSS else (5 if scene == LASER else 3)
	enemy.destroyed.connect(_on_enemy_destroyed.bind(reward))
	$Actors.add_child(enemy)
	enemies.append(enemy)
	return enemy

func _active_enemy_count() -> int:
	var count := 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.active:
			count += 1
	return count

func _on_enemy_destroyed(where: Vector2, earned: int) -> void:
	_feedback("destroyed", where)
	aura += earned
	feedback_layer.burst(where, Color("ffd487"), 28.0, "+%d AURA" % earned)
	if _room_needs_clear() and _active_enemy_count() == 0:
		room_cleared[current_room] = true
		if _is_boss_room():
			boss = null
			_on_victory.call_deferred()
		else:
			shop_pending = true
			player.velocity = Vector2.ZERO
			player.dash_until = -1
			player.parry_until = -1
			$CanvasLayer/HUD.show_shop()

func shop_offers() -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	for upgrade in UPGRADES:
		var offer: Dictionary = upgrade.duplicate()
		var rank := player.upgrade_rank(offer["id"])
		offer["rank"] = rank
		offer["price"] += rank * 2
		offers.append(offer)
	return offers

func buy_upgrade(id: String) -> bool:
	if not shop_pending:
		return false
	for offer in shop_offers():
		if offer["id"] == id and offer["rank"] < offer["max_rank"] and aura >= offer["price"]:
			aura -= offer["price"]
			player.upgrade_ranks[id] = offer["rank"] + 1
			return true
	return false

func finish_shop() -> void:
	if not shop_pending:
		return
	shop_pending = false
	_refresh_doors()
	get_tree().paused = false

func _refresh_doors() -> void:
	for door in doors:
		door["open"] = true
		door["body"].queue_free()
		door.erase("body")
	queue_redraw()

func _check_doors() -> void:
	if transitioning or not player.active:
		return
	for door in doors:
		if not bool(door["open"]):
			continue
		var door_rect: Rect2 = door["rect"]
		var position_in_room := player.global_position
		var near_edge := position_in_room.x <= door_rect.end.x if door["side"] == "left" else position_in_room.x >= door_rect.position.x
		if near_edge and absf(position_in_room.y - door_rect.get_center().y) <= DOOR_SPAN * 0.5 - 14.0:
			_begin_room_transition(int(door["target"]), str(door["entry"]))
			return

func _begin_room_transition(target: int, entry: String) -> void:
	if transitioning:
		return
	transitioning = true
	player.active = false
	player.velocity = Vector2.ZERO
	player.dash_until = -1
	player.parry_until = -1
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
	transitioning = false

func _physics_process(delta: float) -> void:
	door_clock += delta
	if player.active and not transitioning:
		if _room_needs_clear():
			player.hope = maxf(1.0, player.hope - TUNING.hope_drain_per_second * delta)
		_check_doors()
	queue_redraw()

func _shoot(origin: Vector2, direction: Vector2, critical: bool = false) -> void:
	var bullet := PROJECTILE.instantiate() as BasicProjectile
	bullet.global_position = origin
	bullet.direction = direction
	bullet.speed = TUNING.projectile_speed
	bullet.damage = player.projectile_damage() + (2 if critical else 0)
	bullet.critical = critical
	if player.upgrade_rank("bounce") > 0:
		bullet.bounces_left = BasicProjectile.MAX_BOUNCES
	bullet.impact.connect(func(where: Vector2): _effect(where, Color("75f6d0"), 12.0))
	bullet.ricochet.connect(func(where: Vector2): _feedback("ricochet", where))
	$Projectiles.add_child(bullet)

func _effect(where: Vector2, color: Color, radius: float = 50.0) -> void:
	feedback_layer.burst(where, color, radius)

func _feedback(kind: String, where: Vector2) -> void:
	feedback_layer.trigger(kind, where)

func _on_death() -> void:
	$CanvasLayer/HUD.show_result(false)

func _on_victory() -> void:
	player.active = false
	player.velocity = Vector2.ZERO
	$CanvasLayer/HUD.show_result(true)

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
	if open:
		var direction := 1.0 if door["side"] == "right" else -1.0
		draw_polyline(PackedVector2Array([
			center + Vector2(-5.0 * direction, -12),
			center + Vector2(5.0 * direction, 0),
			center + Vector2(-5.0 * direction, 12),
		]), color, 2.0, true)
	else:
		draw_line(center - Vector2(6, 9), center + Vector2(6, 9), color, 2.0, true)
		draw_line(center - Vector2(6, -9), center + Vector2(6, -9), color, 2.0, true)

func _draw() -> void:
	var floor_color: Color = ROOMS[current_room]["color"]
	draw_rect(floor_bounds, floor_color)
	var grid_color := floor_color.lightened(0.028)
	for x in range(floori(floor_bounds.position.x), ceili(floor_bounds.end.x), 48):
		draw_line(Vector2(x, floor_bounds.position.y), Vector2(x, floor_bounds.end.y), grid_color, 1.0)
	for y in range(floori(floor_bounds.position.y), ceili(floor_bounds.end.y), 48):
		draw_line(Vector2(floor_bounds.position.x, y), Vector2(floor_bounds.end.x, y), grid_color, 1.0)
	draw_rect(floor_bounds.grow(-16), Color("314153"), false, 1.0)
	if _is_boss_room():
		var center := floor_bounds.get_center()
		draw_arc(center, 180, 0, TAU, 96, Color("3b273d"), 2.0, true)
		draw_arc(center, 199, 0, TAU, 96, Color("322338"), 1.0, true)
	for pillar in current_pillars:
		draw_rect(Rect2(pillar.position + Vector2(5, 6), pillar.size), Color(0, 0, 0, 0.3))
		draw_rect(pillar, Color("2e3e4f"))
		draw_rect(pillar.grow(-5), Color("3a4e61"), false, 1.0)
	for door in doors:
		_draw_door(door)
