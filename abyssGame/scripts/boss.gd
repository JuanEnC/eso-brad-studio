class_name FinalBoss
extends PracticeEnemy

const BODY_RADIUS := 36.0
const WAVE_RADIUS := 154.0
const BOLT_RANGE := 365.0
const SPREAD_ANGLE := 0.29
const BOLT := preload("res://scripts/boss_bolt.gd")
const SILVER := Color("c2c5d7")
const EMBER := Color("f28ba4")
const MINT := Color("75f6d0")
const SHIELD_COLOR := Color("beb3f5")

enum Attack { BOLT, SLASH, SPREAD, PULSE }

var shield_points: int = 2
var shield_max: int = 2
var enraged := false
var pattern := Attack.BOLT

var armor_outline := PackedVector2Array([
	Vector2(-15, -34), Vector2(15, -34), Vector2(32, -15), Vector2(32, 15),
	Vector2(15, 33), Vector2(-15, 33), Vector2(-32, 15), Vector2(-32, -15),
])
var crest := PackedVector2Array([
	Vector2(0, -26), Vector2(23, 0), Vector2(0, 27), Vector2(-23, 0),
])

func _can_attack() -> bool:
	var ranged := enraged or attacks % 2 == 0
	var reach := BOLT_RANGE if ranged else tuning.enemy_attack_range - 8.0
	return global_position.distance_to(player.global_position) <= reach and has_line_of_sight()

func begin_attack() -> void:
	super.begin_attack()
	if not attacking:
		return
	match _next_attack():
		Attack.BOLT:
			_set_pattern(Attack.BOLT, 41, 8, 44)
		Attack.SLASH:
			_set_pattern(Attack.SLASH, 34, 6, 40)
		Attack.SPREAD:
			_set_pattern(Attack.SPREAD, 29, 7, 28)
	if strike_direction.is_zero_approx():
		strike_direction = Vector2.LEFT

func _next_attack() -> Attack:
	if enraged:
		return Attack.SPREAD
	return Attack.BOLT if attacks % 2 == 0 else Attack.SLASH

func _set_pattern(attack: Attack, prepare: int, telegraph: int, recovery: int) -> void:
	pattern = attack
	tuning.enemy_prepare_frames = prepare
	tuning.enemy_telegraph_frames = telegraph
	tuning.enemy_recovery_frames = recovery
	remaining = prepare

func resolve_attack() -> void:
	if pattern == Attack.SLASH or pattern == Attack.PULSE:
		super.resolve_attack()
		return
	if not _begin_recovery():
		return
	_launch_bolt(strike_direction)
	if pattern == Attack.SPREAD:
		_launch_bolt(strike_direction.rotated(-SPREAD_ANGLE))
		_launch_bolt(strike_direction.rotated(SPREAD_ANGLE))
		_set_pattern(Attack.PULSE, 26, 7, 28)
		state = State.PREPARE
		attacking = true
		feedback.emit("prepare", global_position)

func _launch_bolt(heading: Vector2) -> void:
	var bolt := BOLT.new()
	bolt.direction = heading
	bolt.speed = 490.0 if enraged else 425.0
	bolt.tint = EMBER if enraged else Color("ffbd80")
	bolt.parried.connect(_on_attack_parried)
	add_child(bolt)
	bolt.global_position = global_position

func _attack_radius() -> float:
	return WAVE_RADIUS if pattern == Attack.PULSE else super._attack_radius()

func _attack_source() -> Vector2:
	# Measure the parry from the closest point of the larger body.
	return global_position.move_toward(player.global_position, BODY_RADIUS)

func _on_attack_parried() -> void:
	if not active:
		return
	if shield_points > 0:
		_damage_shield(shield_points)
	super._on_attack_parried()

func _damage_shield(amount: int) -> void:
	shield_points = maxi(0, shield_points - amount)
	feedback.emit("shield_break" if shield_points == 0 else "armor", global_position)

func take_damage(amount: int, banked: bool = false, critical: bool = false) -> void:
	if not active or amount <= 0:
		return
	if shield_points > 0:
		if critical:
			_damage_shield(1)
			if state != State.STUNNED or remaining < 18:
				_stun(18)
		else:
			flash = 0.35
			feedback.emit("armor", global_position)
		return
	super.take_damage(amount, banked, critical)
	if active and not enraged and health * 2 <= max_health:
		_enter_second_phase()

func _enter_second_phase() -> void:
	enraged = true
	speed_scale *= 1.20
	shield_max = 1
	shield_points = shield_max
	for child in get_children():
		if child.get_script() == BOLT:
			child.queue_free()
	frequency = 0.0
	frequency_broken = false
	frequency_delay = 0
	frequency_changed.emit(frequency, tuning.frequency_max)
	_stun(24)
	feedback.emit("boss_phase", global_position)

func state_text() -> String:
	if frequency_broken:
		return "RUPTURA · DAÑO ×2"
	if state == State.PREPARE or state == State.TELEGRAPH:
		return ["PROYECTIL", "TAJO", "SALVA TRIPLE", "ONDA EXPANSIVA"][pattern]
	if shield_points > 0:
		return "ESCUDO"
	return "FURIA" if enraged else ""

func _draw() -> void:
	if state == State.PREPARE or state == State.TELEGRAPH:
		_draw_warning()
	elif state == State.RECOVER and (pattern == Attack.SLASH or pattern == Attack.PULSE) and remaining > tuning.enemy_recovery_frames - 8:
		var opacity := float(remaining - tuning.enemy_recovery_frames + 8) / 8.0
		draw_arc(Vector2.ZERO, _attack_radius(), 0, TAU, 72, Color(EMBER, opacity), 4, true)

	draw_circle(Vector2(0, 6), BODY_RADIUS + 4.0, Color(0.0, 0.0, 0.0, 0.36))
	var accent := MINT if frequency_broken else (EMBER if enraged else SILVER)
	var shell := Color("431d2b") if enraged else Color("241b31")
	draw_colored_polygon(armor_outline, shell.lerp(accent, flash * 0.5))
	for i in armor_outline.size():
		draw_line(armor_outline[i], armor_outline[(i + 1) % armor_outline.size()], Color(accent, 0.68), 2, true)
	draw_colored_polygon(crest, Color("47324e").lerp(accent, flash))
	draw_line(Vector2(-23, 0), Vector2(23, 0), Color("171321"), 4, true)
	draw_line(Vector2(0, -26), Vector2(0, 27), Color("171321"), 3, true)
	draw_circle(Vector2.ZERO, 7, accent)
	draw_circle(Vector2.ZERO, 3, Color("fff1f4"))
	if frequency_broken:
		var progress := float(remaining) / tuning.frequency_break_frames
		draw_arc(Vector2.ZERO, 43, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, MINT, 2, true)
	elif shield_points > 0:
		var arc_length := TAU / shield_max
		var shield_tint := SHIELD_COLOR.lerp(Color.WHITE, flash).lerp(EMBER, 0.35 if enraged else 0.0)
		for point in shield_points:
			var start := -PI * 0.5 + point * arc_length
			draw_arc(Vector2.ZERO, 43.0, start + 0.1, start + arc_length - 0.1, 48, shield_tint, 3, true)

func _draw_warning() -> void:
	var ready_to_strike := state == State.TELEGRAPH
	var warning := Color.WHITE if ready_to_strike else (EMBER if enraged else Color("ffba69"))
	if pattern == Attack.BOLT or pattern == Attack.SPREAD:
		_draw_aim_line(strike_direction, warning)
		if pattern == Attack.SPREAD:
			_draw_aim_line(strike_direction.rotated(-SPREAD_ANGLE), warning)
			_draw_aim_line(strike_direction.rotated(SPREAD_ANGLE), warning)
	else:
		var radius := _attack_radius()
		draw_circle(Vector2.ZERO, radius, Color(warning, 0.12), true, -1.0, true)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 72, warning, 3, true)
		if pattern == Attack.PULSE:
			draw_arc(Vector2.ZERO, radius - 9.0, 0, TAU, 72, Color(warning, 0.55), 2, true)
	var progress := 1.0 if ready_to_strike else 1.0 - float(remaining) / tuning.enemy_prepare_frames
	draw_arc(Vector2.ZERO, 47, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, warning, 3, true)
	draw_string(font, Vector2(-90, -53), state_text(), HORIZONTAL_ALIGNMENT_CENTER, 180, 13, warning)

func _draw_aim_line(heading: Vector2, warning: Color) -> void:
	draw_line(heading * 50.0, heading * 156.0, Color(warning, 0.55), 2.0, true)
