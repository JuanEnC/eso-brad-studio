class_name LaserEnemy
extends PracticeEnemy

const BEAM_LENGTH := 1800.0
const BEAM_RADIUS := 10.0
const BEAM_FLASH := 0.13
const BEAM_COLOR := Color("f181b2")
const PARRY_COLOR := Color("75f6d0")

var beam_time := 0.0
var beam_parried := false
var charge_frames := 1

func _physics_process(delta: float) -> void:
	beam_time = maxf(0.0, beam_time - delta)
	if state == State.PREPARE and remaining > charge_frames * 0.72 and is_instance_valid(player):
		var target_direction := global_position.direction_to(player.global_position)
		if not target_direction.is_zero_approx():
			strike_direction = target_direction
	super._physics_process(delta)

func _can_attack() -> bool:
	return global_position.distance_squared_to(player.global_position) <= tuning.enemy_attack_range * tuning.enemy_attack_range

func begin_attack() -> void:
	super.begin_attack()
	if not attacking:
		return
	charge_frames = maxi(1, remaining)
	if strike_direction.is_zero_approx():
		strike_direction = Vector2.LEFT

func resolve_attack() -> void:
	if not _begin_recovery():
		return
	beam_time = BEAM_FLASH
	beam_parried = false
	feedback.emit("laser_fire", global_position)
	var end := global_position + strike_direction * BEAM_LENGTH
	var beam := CapsuleShape2D.new()
	beam.radius = BEAM_RADIUS
	beam.height = BEAM_LENGTH + BEAM_RADIUS * 2.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = beam
	query.transform = Transform2D(strike_direction.angle() - PI * 0.5, (global_position + end) * 0.5)
	query.collision_mask = 2
	for hit in get_world_2d().direct_space_state.intersect_shape(query):
		if hit.collider == player:
			var contact := Geometry2D.get_closest_point_to_segment(player.global_position, global_position, end)
			if player.receive_attack(contact) == "parried":
				beam_parried = true
				_on_attack_parried()
			break

func _draw() -> void:
	var end := strike_direction * BEAM_LENGTH
	if beam_time > 0.0:
		var fade := beam_time / BEAM_FLASH
		var beam_color := PARRY_COLOR if beam_parried else BEAM_COLOR
		draw_line(Vector2.ZERO, end, Color(beam_color, fade * 0.42), BEAM_RADIUS * 2.0, true)
		draw_line(Vector2.ZERO, end, Color(beam_color.lerp(Color.WHITE, 0.62), fade), 4.0, true)
	elif state == State.PREPARE or state == State.TELEGRAPH:
		var imminent := state == State.TELEGRAPH
		var warning := Color("ffe2ef") if imminent else BEAM_COLOR
		draw_line(Vector2.ZERO, end, Color(warning, 0.14 if imminent else 0.09), BEAM_RADIUS * 2.0, true)
		draw_dashed_line(Vector2.ZERO, end, warning, 2.5 if imminent else 1.5, 10.0, true, true)
		var charge := 1.0 if imminent else clampf(1.0 - float(remaining) / charge_frames, 0.0, 1.0)
		draw_arc(Vector2.ZERO, 27.0, -PI * 0.5, -PI * 0.5 + TAU * charge, 40, warning, 2.5, true)

	var accent := PARRY_COLOR if state == State.STUNNED else BEAM_COLOR
	draw_circle(Vector2(0, 5), 23, Color(0.0, 0.0, 0.0, 0.35))
	draw_rect(Rect2(-18, -18, 36, 36), Color("322238"))
	draw_rect(Rect2(-18, -18, 36, 36), Color(accent, 0.58), false, 2)
	draw_rect(Rect2(-13, -13, 26, 26), Color("674060").lerp(accent, flash * 0.65))
	draw_line(strike_direction * 5, strike_direction * 21, Color("221626"), 9, true)
	draw_circle(strike_direction * 21, 4, accent)
	_draw_status()
