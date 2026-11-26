class_name BasicProjectile
extends Node2D

const MAX_BOUNCES := 2

var direction := Vector2.RIGHT
var speed: float = 900.0
var damage: int = 1
var life: float = 1.4
var bounces_left: int = 0
var banked: bool = false
var critical: bool = false
var active: bool = true
signal impact(where: Vector2)
signal ricochet(where: Vector2)

func _physics_process(delta: float) -> void:
	if not active:
		return
	life -= delta
	if life <= 0:
		queue_free()
		return
	var distance_left := speed * delta
	var space := get_world_2d().direct_space_state
	while distance_left > 0.0:
		var end := global_position + direction * distance_left
		var query := PhysicsRayQueryParameters2D.create(global_position, end, 1 | 4)
		query.hit_from_inside = true
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			global_position = end
			break
		var point: Vector2 = hit.position
		var normal: Vector2 = hit.normal
		distance_left -= global_position.distance_to(point) + 0.25
		global_position = point
		if hit.collider is PracticeEnemy:
			hit.collider.take_damage(damage, banked, critical)
		elif bounces_left > 0 and not normal.is_zero_approx():
			bounces_left -= 1
			banked = true
			direction = direction.bounce(normal)
			global_position += normal * 0.25
			ricochet.emit(point)
			continue
		active = false
		impact.emit(point)
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var trail := Color("ffbf82") if banked else Color("75f6d0")
	if critical:
		trail = Color("e7a2ff")
	draw_line(-direction * 22, Vector2.ZERO, Color(trail, 0.17), 8, true)
	draw_line(-direction * 15, Vector2.ZERO, trail, 4, true)
	draw_circle(Vector2.ZERO, 5 if critical else 3, Color("edfff9"))
