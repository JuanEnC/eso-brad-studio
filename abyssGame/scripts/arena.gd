extends Node2D

const ENEMY := preload("res://scenes/enemy.tscn")
const PROJECTILE := preload("res://scenes/projectile.tscn")
const TUNING := preload("res://resources/default_tuning.tres")
const FLOOR := Rect2(0, 0, 1280, 800)
const PILLARS: Array[Rect2] = [Rect2(605, 275, 38, 76), Rect2(605, 508, 38, 76)]
var floor_bounds := FLOOR
var player: AbyssPlayer
var enemies: Array[PracticeEnemy] = []
var navigation := RoomNavigation.new()
var feedback_layer: CombatFeedback
var practice_mode: bool = true:
	set(value):
		practice_mode = value
		if is_instance_valid(player):
			player.practice_invulnerable = value
var kills: int = 0
var last_event: String = "Encuentra tu ritmo."
var event_time: float = 0.0
var mode_name: String = "PRÁCTICA SEGURA"
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	player = $Actors/Player
	player.practice_invulnerable = practice_mode
	feedback_layer = $Feedback
	player.fired.connect(_shoot)
	player.feedback.connect(_feedback)
	player.died.connect(_on_death)
	_build_geometry()
	navigation.configure(FLOOR, PILLARS)
	_spawn_targets()
	get_viewport().size_changed.connect(_resize_arena)
	_resize_arena()

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

func _build_geometry() -> void:
	var start := floor_bounds.position
	var end := floor_bounds.end
	_wall(Rect2(start.x - 20, start.y - 20, floor_bounds.size.x + 40, 20))
	_wall(Rect2(start.x - 20, end.y, floor_bounds.size.x + 40, 20))
	_wall(Rect2(start.x - 20, start.y, 20, floor_bounds.size.y))
	_wall(Rect2(end.x, start.y, 20, floor_bounds.size.y))
	for pillar in PILLARS:
		_wall(pillar)

func _resize_arena() -> void:
	var bounds := get_viewport_rect()
	if bounds == floor_bounds:
		return
	floor_bounds = bounds
	for wall in $Geometry.get_children():
		$Geometry.remove_child(wall)
		wall.queue_free()
	_build_geometry()
	navigation.configure(floor_bounds, PILLARS)
	var safe := floor_bounds.grow(-24)
	player.position = player.position.clamp(safe.position, safe.end)
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.position = enemy.position.clamp(safe.position, safe.end)
	queue_redraw()

func _spawn_targets() -> void:
	_spawn_enemy(Vector2(825, 267), true)
	_spawn_enemy(Vector2(825, 427), true)
	_spawn_enemy(Vector2(825, 587), true)
	_spawn_enemy(Vector2(260, 410), false)

func _spawn_enemy(where: Vector2, dummy: bool) -> PracticeEnemy:
	enemies = enemies.filter(func(enemy): return is_instance_valid(enemy) and enemy.active)
	var enemy := ENEMY.instantiate() as PracticeEnemy
	enemy.position = where
	enemy.player = player
	enemy.dummy = dummy
	enemy.navigation = navigation
	enemy.feedback.connect(_feedback)
	enemy.destroyed.connect(_destroyed.bind(enemy))
	$Actors.add_child(enemy)
	enemies.append(enemy)
	return enemy

func _physics_process(delta: float) -> void:
	if player.active and not practice_mode:
		player.hope = maxf(1.0, player.hope - TUNING.hope_drain_per_second * delta)
	if practice_mode and player.active:
		player.hope = 100.0
	event_time = maxf(0.0, event_time - delta)
	queue_redraw()

func _shoot(origin: Vector2, direction: Vector2) -> void:
	var bullet := PROJECTILE.instantiate() as BasicProjectile
	bullet.position = origin
	bullet.direction = direction
	bullet.speed = TUNING.projectile_speed
	bullet.damage = TUNING.projectile_damage
	bullet.impact.connect(func(where: Vector2): _effect(where, Color("75f6d0"), 12.0))
	$Projectiles.add_child(bullet)

func _destroyed(where: Vector2, enemy: PracticeEnemy) -> void:
	kills += 1
	_feedback("destroyed", where)
	var spawn_point := where if enemy.dummy else Vector2(260, 410)
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 2.0
	add_child(timer)
	timer.timeout.connect(_respawn.bind(timer, spawn_point, enemy.dummy))
	timer.start()

func _respawn(timer: Timer, where: Vector2, dummy: bool) -> void:
	if player.active:
		_spawn_enemy(where, dummy)
	timer.queue_free()

func _effect(where: Vector2, color: Color, radius: float = 50.0) -> void:
	feedback_layer.burst(where, color, radius)

func _feedback(kind: String, where: Vector2) -> void:
	match kind:
		"parry_success":
			last_event = "RESONANCIA PERFECTA · +18 Esperanza"
			event_time = 2.0
		"frequency_break":
			last_event = "RUPTURA DE FRECUENCIA · 3 s de aturdimiento · daño x2"
			event_time = 3.0
		"hurt":
			last_event = "Impacto recibido · observa el anillo blanco"
			event_time = 1.5
		"destroyed":
			last_event = "Blanco destruido · reaparece en 2 s"
			event_time = 1.5
	feedback_layer.trigger(kind, where)

func toggle_practice() -> void:
	if not player.active:
		return
	practice_mode = not practice_mode
	mode_name = "PRÁCTICA SEGURA" if practice_mode else "COMBATE · 3 GOLPES"
	player.reset_integrity()
	player.hope = 100.0
	last_event = "Práctica: salud protegida, impactos registrados" if practice_mode else "Combate: el tercer golpe termina la prueba"
	event_time = 2.0

func _on_death() -> void:
	if practice_mode:
		player.reset_integrity()
	else:
		$CanvasLayer/HUD.show_overlay("FIN DE LA PRUEBA", "Recibiste 3 golpes. Reinicia y prueba otra vez.", true)

func _draw() -> void:
	draw_rect(floor_bounds, Color("0c1724"))
	for x in range(0, ceili(floor_bounds.end.x), 40):
		draw_line(Vector2(x, 0), Vector2(x, floor_bounds.end.y), Color("132231"), 1)
	for y in range(0, ceili(floor_bounds.end.y), 40):
		draw_line(Vector2(0, y), Vector2(floor_bounds.end.x, y), Color("132231"), 1)
	for rect in PILLARS:
		draw_rect(Rect2(rect.position + Vector2(5, 6), rect.size), Color(0, 0, 0, 0.3))
		draw_rect(rect, Color("2e3e4f"))
		draw_rect(rect.grow(-5), Color("3a4e61"), false, 1)
	for point in [Vector2(825, 267), Vector2(825, 427), Vector2(825, 587)]:
		draw_arc(point, 44, 0, TAU, 48, Color("3c2d3d"), 1)
		draw_line(point - Vector2(54, 0), point + Vector2(54, 0), Color("302635"), 1)
