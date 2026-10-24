class_name PracticeEnemy
extends CharacterBody2D

signal feedback(kind: String, where: Vector2)
signal destroyed(where: Vector2)
signal frequency_changed(current: float, maximum: float)

enum State { CHASE, PREPARE, TELEGRAPH, RECOVER, STUNNED }
@export var tuning: CombatTuning
@export var dummy: bool = false
var player: AbyssPlayer
var navigation: RoomNavigation
var state: State = State.CHASE
var remaining: int = 0
var health: int = 5
var max_health: int = 5
var active: bool = true
var attacking: bool = false
var strike_direction := Vector2.LEFT
var flash: float = 0.0
var attacks: int = 0
var frequency: float = 0.0
var frequency_broken: bool = false
var frequency_delay: int = 0
var path := PackedVector2Array()
var path_index: int = 0
var repath_remaining: int = 0
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	max_health = tuning.dummy_health if dummy else tuning.enemy_health
	health = max_health

func _physics_process(delta: float) -> void:
	flash = maxf(0.0, flash - delta * 5.0)
	velocity = Vector2.ZERO
	if not active or not is_instance_valid(player) or not player.active:
		queue_redraw()
		return
	_update_frequency(delta)
	if dummy and state != State.STUNNED:
		queue_redraw()
		return
	remaining -= 1
	match state:
		State.CHASE:
			var distance := player.global_position.distance_to(global_position)
			if distance <= tuning.enemy_attack_range - 8.0 and has_line_of_sight():
				begin_attack()
			else:
				_chase()
		State.PREPARE:
			if remaining <= 0:
				state = State.TELEGRAPH
				remaining = tuning.enemy_telegraph_frames
				feedback.emit("warning", global_position)
		State.TELEGRAPH:
			if remaining <= 0:
				resolve_attack()
		State.RECOVER:
			if remaining <= 0:
				state = State.CHASE
		State.STUNNED:
			if remaining <= 0:
				if frequency_broken:
					frequency_broken = false
					frequency = 0.0
					frequency_changed.emit(frequency, tuning.frequency_max)
				state = State.CHASE
	move_and_slide()
	queue_redraw()

func _chase() -> void:
	var target := player.global_position
	repath_remaining -= 1
	if navigation != null and not navigation.can_travel(global_position, target):
		if repath_remaining <= 0:
			path = navigation.find_path(global_position, target)
			path_index = 1 if path.size() > 1 else 0
			repath_remaining = tuning.enemy_repath_frames
		while path_index < path.size() and global_position.distance_to(path[path_index]) < 6.0:
			path_index += 1
		if path_index >= path.size():
			return
		target = path[path_index]
	velocity = (target - global_position).normalized() * tuning.enemy_speed

func has_line_of_sight() -> bool:
	if not is_instance_valid(player):
		return false
	var ray := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
	ray.hit_from_inside = true
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func begin_attack() -> void:
	if not active or dummy or state == State.STUNNED or not is_instance_valid(player) or not player.active:
		return
	state = State.PREPARE
	remaining = tuning.enemy_prepare_frames
	strike_direction = (player.global_position - global_position).normalized()
	attacking = true
	velocity = Vector2.ZERO

func resolve_attack() -> void:
	if not active or not attacking or not is_instance_valid(player) or not player.active:
		return
	attacking = false
	attacks += 1
	state = State.RECOVER
	remaining = tuning.enemy_recovery_frames
	feedback.emit("strike", global_position)
	if not has_line_of_sight():
		return
	var shape := CircleShape2D.new()
	shape.radius = tuning.enemy_attack_range
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = 2
	for hit in get_world_2d().direct_space_state.intersect_shape(query):
		if hit.collider == player:
			var result := player.receive_attack(global_position)
			if result == "parried":
				add_frequency(tuning.frequency_per_parry)
				if not frequency_broken:
					_stun(tuning.stun_frames)
			break

func add_frequency(amount: float) -> void:
	if not active or frequency_broken or amount <= 0:
		return
	frequency = minf(tuning.frequency_max, frequency + amount)
	frequency_delay = tuning.frequency_decay_delay_frames
	frequency_changed.emit(frequency, tuning.frequency_max)
	if frequency >= tuning.frequency_max:
		frequency_broken = true
		_stun(tuning.frequency_break_frames)
		feedback.emit("frequency_break", global_position)

func _update_frequency(delta: float) -> void:
	if frequency_broken or state == State.STUNNED:
		return
	if frequency_delay > 0:
		frequency_delay -= 1
	elif frequency > 0:
		frequency = maxf(0.0, frequency - tuning.frequency_decay_per_second * delta)
		frequency_changed.emit(frequency, tuning.frequency_max)

func _stun(frames: int) -> void:
	state = State.STUNNED
	remaining = frames
	attacking = false
	velocity = Vector2.ZERO
	flash = 1.0

func take_damage(amount: int) -> void:
	if not active or amount <= 0:
		return
	var effective := amount * (tuning.broken_damage_multiplier if frequency_broken else 1)
	health = maxi(0, health - effective)
	flash = 1.0
	feedback.emit("hit", global_position)
	if health <= 0:
		active = false
		attacking = false
		velocity = Vector2.ZERO
		destroyed.emit(global_position)
		queue_free()
	else:
		add_frequency(tuning.frequency_per_shot * amount)

func state_text() -> String:
	if frequency_broken:
		return "RUPTURA · daño x2"
	return ["Persiguiendo", "Preparando golpe", "¡DESVÍA AHORA!", "Recuperándose", "ATURDIDO · 1.5 s"][state]

func _draw() -> void:
	if state == State.PREPARE or state == State.TELEGRAPH:
		var warning := Color("ffba69") if state == State.PREPARE else Color.WHITE
		draw_circle(Vector2.ZERO, tuning.enemy_attack_range, Color(warning, 0.07))
		draw_arc(Vector2.ZERO, tuning.enemy_attack_range, 0, TAU, 48, warning, 2, true)
		var progress := 1.0 if state == State.TELEGRAPH else 1.0 - float(remaining) / maxf(1.0, tuning.enemy_prepare_frames)
		draw_arc(Vector2.ZERO, 28, -PI / 2, -PI / 2 + TAU * clampf(progress, 0, 1), 40, warning, 3, true)
	draw_circle(Vector2(0, 7), 24, Color(0, 0, 0, 0.3))
	var color := Color("d86179") if not dummy else Color("a86c7c")
	if state == State.STUNNED:
		color = Color("75f6d0")
	color = color.lerp(Color.WHITE, flash)
	draw_circle(Vector2.ZERO, 20, Color("391e2b"))
	draw_circle(Vector2.ZERO, 16, color)
	draw_arc(Vector2.ZERO, 22, 0, TAU, 32, Color(color, 0.4), 1, true)
	draw_line(Vector2(-7, 0), Vector2(7, 0), Color("301c28"), 3, true)
	draw_line(Vector2(0, -7), Vector2(0, 7), Color("301c28"), 3, true)
	draw_rect(Rect2(-35, -34, 70, 4), Color("312735"))
	draw_rect(Rect2(-35, -34, 70.0 * health / maxi(1, max_health), 4), Color("d86179"))
	var posture_color := Color("75f6d0") if frequency_broken else Color("ffba69")
	draw_rect(Rect2(-35, -45, 70, 6), Color("253346"))
	draw_rect(Rect2(-35, -45, 70.0 * frequency / tuning.frequency_max, 6), posture_color)
	for i in range(1, 4):
		draw_line(Vector2(-35 + i * 17.5, -45), Vector2(-35 + i * 17.5, -39), Color("101e2d"), 1)
	var label := "RUPTURA" if frequency_broken else "FREC %d%%" % roundi(100.0 * frequency / tuning.frequency_max)
	draw_string(font, Vector2(-35, -51), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, posture_color)
	if state == State.STUNNED:
		draw_arc(Vector2.ZERO, 27, 0, TAU * clampf(float(remaining) / (tuning.frequency_break_frames if frequency_broken else tuning.stun_frames), 0, 1), 40, Color("75f6d0"), 2, true)
