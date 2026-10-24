class_name AbyssPlayer
extends CharacterBody2D

signal feedback(kind: String, where: Vector2)
signal fired(origin: Vector2, direction: Vector2)
signal died
signal health_changed(current: int, maximum: int)

@export var tuning: CombatTuning
var aim := Vector2.RIGHT
var dash_direction := Vector2.RIGHT
var last_move := Vector2.RIGHT
var tick: int = 0
var dash_until: int = -1
var dash_ready: int = 0
var parry_until: int = -1
var parry_ready: int = 0
var shot_ready: int = 0
var invulnerable_until: int = -1
var max_health: int:
	get: return tuning.player_max_health if tuning != null else 3
var health: int = 3:
	set(value):
		var clamped := clampi(value, 0, max_health)
		if health != clamped:
			health = clamped
			health_changed.emit(health, max_health)
var practice_invulnerable: bool = false
var hope: float = 100.0
var shots: int = 0
var parries: int = 0
var dashes: int = 0
var hits_taken: int = 0
var active: bool = true
var mouse_aim: bool = true
var flash: float = 0.0

func _ready() -> void:
	process_physics_priority = -10
	health = max_health
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = tuning.parry_radius
	shape.shape = circle
	$ParryArea.add_child(shape)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.relative.length() > 0.5:
		mouse_aim = true
	elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y] and absf(event.axis_value) > 0.22:
		mouse_aim = false
	elif event is InputEventKey and event.pressed and event.physical_keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]:
		mouse_aim = false

func _physics_process(delta: float) -> void:
	if not active:
		return
	tick += 1
	flash = maxf(0.0, flash - delta * 4.0)
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var arrow_aim := Input.get_vector("fire_left", "fire_right", "fire_up", "fire_down")
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if arrow_aim.length() > 0.1:
		aim = arrow_aim.normalized()
	elif stick.length() > 0.1:
		aim = stick.normalized()
	elif mouse_aim:
		var direction := get_global_mouse_position() - global_position
		if direction.length() > 8.0:
			aim = direction.normalized()
	if movement.length() > 0.1:
		last_move = movement.normalized()
	if Input.is_action_just_pressed("dash"):
		try_dash(movement)
	if Input.is_action_just_pressed("parry"):
		try_parry()
	if Input.is_action_pressed("shoot") or arrow_aim.length() > 0.1:
		try_shoot()
	if is_dashing():
		velocity = dash_direction * tuning.dash_speed
	else:
		var speed := tuning.move_speed * (0.45 if hope <= 1.0 else 1.0)
		velocity = velocity.move_toward(movement * speed, (tuning.acceleration if movement.length() > 0 else tuning.deceleration) * delta)
	move_and_slide()
	queue_redraw()

func is_dashing() -> bool:
	return tick < dash_until

func is_parrying() -> bool:
	return tick < parry_until

func try_dash(movement: Vector2) -> bool:
	if not active or tick < dash_ready or is_parrying():
		return false
	dash_direction = movement.normalized() if movement.length() > 0.1 else aim
	dash_until = tick + tuning.dash_frames
	dash_ready = tick + tuning.dash_cooldown_frames
	dashes += 1
	feedback.emit("dash", global_position)
	return true

func try_parry() -> bool:
	if not active or tick < parry_ready or is_dashing():
		return false
	parry_until = tick + tuning.parry_frames
	parry_ready = tick + tuning.parry_cooldown_frames
	feedback.emit("parry_start", global_position)
	return true

func try_shoot() -> bool:
	if not active or tick < shot_ready or is_dashing() or is_parrying():
		return false
	shot_ready = tick + tuning.shot_cooldown_frames
	shots += 1
	fired.emit(global_position + aim * 22.0, aim)
	feedback.emit("shot", global_position)
	return true

func receive_attack(source: Vector2) -> String:
	if not active:
		return "ignored"
	if is_parrying() and global_position.distance_to(source) <= tuning.parry_radius:
		parries += 1
		hope = minf(100.0, hope + tuning.hope_reward)
		flash = 1.0
		feedback.emit("parry_success", global_position)
		return "parried"
	if is_dashing() or tick < invulnerable_until:
		return "evaded"
	if not practice_invulnerable:
		health -= 1
	hits_taken += 1
	invulnerable_until = tick + tuning.damage_invulnerability_frames
	flash = 1.0
	feedback.emit("hurt", global_position)
	if health <= 0:
		active = false
		velocity = Vector2.ZERO
		died.emit()
	return "damaged"

func heal(amount: int) -> int:
	if not active or amount <= 0:
		return 0
	var before := health
	health += amount
	return health - before

func reset_integrity() -> void:
	active = true
	health = max_health
	invulnerable_until = -1
	dash_until = -1
	parry_until = -1
	velocity = Vector2.ZERO

func _draw() -> void:
	draw_circle(Vector2(0, 8), 21, Color(0, 0, 0, 0.35))
	if is_dashing():
		draw_line(-dash_direction * 44, Vector2.ZERO, Color(0.4, 0.7, 1.0, 0.5), 24, true)
	if is_parrying():
		draw_circle(Vector2.ZERO, tuning.parry_radius, Color(0.36, 0.95, 0.8, 0.10))
		draw_arc(Vector2.ZERO, tuning.parry_radius, 0, TAU, 64, Color("75f6d0"), 3, true)
	var color := Color("70b8ff")
	if tick < invulnerable_until and tick % 6 < 3:
		color = Color("ff728b")
	color = color.lerp(Color.WHITE, flash * 0.6)
	draw_rect(Rect2(-16, -16, 32, 32), Color("192d47"))
	draw_rect(Rect2(-13, -13, 26, 26), color)
	draw_line(aim * 9, aim * 27, Color("daf1ff"), 6, true)
	draw_circle(aim * 31, 3, Color("75f6d0"))
