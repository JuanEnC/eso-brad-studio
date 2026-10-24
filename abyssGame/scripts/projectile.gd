class_name BasicProjectile
extends Node2D

var direction := Vector2.RIGHT
var speed: float = 900.0
var damage: int = 1
var life: float = 1.4
var active: bool = true
signal impact(where: Vector2)

func _physics_process(delta: float) -> void:
	if not active:
		return
	life -= delta
	if life <= 0:
		queue_free()
		return
	var end := global_position + direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, end, 1 | 4)
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		active = false
		global_position = hit.position
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(damage)
		impact.emit(global_position)
		queue_free()
	else:
		global_position = end
	queue_redraw()

func _draw() -> void:
	draw_line(-direction * 15, Vector2.ZERO, Color("75f6d0"), 4, true)
	draw_circle(Vector2.ZERO, 3, Color("edfff9"))
