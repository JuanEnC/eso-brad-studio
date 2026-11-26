extends Node2D

signal parried

var direction := Vector2.LEFT
var speed: float = 425.0
var tint := Color("ffbd80")
var life := 1.8

func _ready() -> void:
	top_level = true
	z_index = 1

func _physics_process(delta: float) -> void:
	if is_queued_for_deletion() or get_parent().is_queued_for_deletion():
		return
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var end := global_position + direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, end, 1 | 2)
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = end
		return
	var player := hit.collider as AbyssPlayer
	if player != null and player.receive_attack(hit.position) == "parried":
		parried.emit()
	queue_free()

func _draw() -> void:
	draw_line(-direction * 20.0, Vector2.ZERO, Color(tint, 0.5), 5, true)
	draw_circle(Vector2.ZERO, 9.0, Color(tint, 0.25), true, -1.0, true)
	draw_circle(Vector2.ZERO, 5.0, tint, true, -1.0, true)
	draw_circle(Vector2.ZERO, 2.0, Color("fff1ed"), true, -1.0, true)
