extends Control

const BLUE := Color("70b8ff")
const MINT := Color("75f6d0")
const INK := Color("0b1521")
const TEXT := Color("e0eaf4")
const MUTED := Color("8da3b7")
var arena: Node2D
var health_label: Label
var hope_bar: ProgressBar
var mode_label: Label
var dash_label: Label
var parry_label: Label
var dash_bar: ProgressBar
var parry_bar: ProgressBar
var overlay: Panel
var overlay_card: Panel
var overlay_title: Label
var overlay_body: Label
var overlay_button: Button
var death_menu: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	arena = get_parent().get_parent()
	_build()
	get_viewport().size_changed.connect(_layout)
	_layout()

func _style(color: Color, border: Color = Color("253a4d")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style

func _label(text: String, rect: Rect2, size: int = 16, color: Color = TEXT, parent: Node = self) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)
	return label

func _panel(rect: Rect2, parent: Node = self) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _style(INK))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)
	return panel

func _bar(rect: Rect2, color: Color, parent: Node = self) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.position = rect.position
	bar.size = rect.size
	bar.max_value = 100
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _style(Color("203143"), Color("203143")))
	bar.add_theme_stylebox_override("fill", _style(color, color))
	parent.add_child(bar)
	return bar

func _button(text: String, rect: Rect2, callback: Callable, parent: Node = self) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _style(Color("182a3a")))
	button.add_theme_stylebox_override("hover", _style(Color("284458"), MINT))
	button.add_theme_stylebox_override("pressed", _style(Color("344f64"), BLUE))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _build() -> void:
	health_label = _label("", Rect2(24, 20, 250, 28), 20, BLUE)
	_label("ESPERANZA", Rect2(24, 52, 180, 18), 10, MUTED)
	hope_bar = _bar(Rect2(24, 75, 180, 6), MINT)
	mode_label = _label("", Rect2(0, 24, 190, 20), 12, MUTED)
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dash_label = _label("DASH", Rect2(24, 0, 96, 20), 12, BLUE)
	parry_label = _label("PARRY", Rect2(144, 0, 96, 20), 12, MINT)
	dash_bar = _bar(Rect2(24, 0, 96, 5), BLUE)
	parry_bar = _bar(Rect2(144, 0, 96, 5), MINT)
	overlay = _panel(Rect2())
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := StyleBoxFlat.new()
	shade.bg_color = Color(0.015, 0.03, 0.05, 0.78)
	overlay.add_theme_stylebox_override("panel", shade)
	overlay_card = _panel(Rect2(0, 0, 750, 400), overlay)
	overlay_title = _label("", Rect2(36, 22, 678, 60), 32, TEXT, overlay_card)
	overlay_body = _label("", Rect2(36, 95, 678, 220), 17, MUTED, overlay_card)
	overlay_button = _button("CONTINUAR", Rect2(36, 335, 678, 42), resume_or_restart, overlay_card)
	overlay.hide()

func _layout() -> void:
	var view_size := get_viewport_rect().size
	mode_label.position.x = view_size.x - mode_label.size.x - 24
	dash_label.position.y = view_size.y - 60
	parry_label.position.y = view_size.y - 60
	dash_bar.position.y = view_size.y - 34
	parry_bar.position.y = view_size.y - 34
	overlay.size = view_size
	overlay_card.position = (view_size - overlay_card.size) * 0.5

func _process(_delta: float) -> void:
	if not is_instance_valid(arena.player):
		return
	var player: AbyssPlayer = arena.player
	health_label.text = "VIDA   " + "◆ ".repeat(maxi(0, player.health)) + "◇ ".repeat(maxi(0, player.max_health - player.health))
	health_label.add_theme_color_override("font_color", Color("ff728b") if player.health <= 1 else BLUE)
	hope_bar.value = player.hope
	mode_label.text = "PRÁCTICA" if arena.practice_mode else ""
	dash_bar.value = 100.0 * clampf(1.0 - float(player.dash_ready - player.tick) / player.tuning.dash_cooldown_frames, 0, 1)
	parry_bar.value = 100.0 * clampf(1.0 - float(player.parry_ready - player.tick) / player.tuning.parry_cooldown_frames, 0, 1)
	dash_label.add_theme_color_override("font_color", BLUE if dash_bar.value >= 100 else MUTED)
	parry_label.add_theme_color_override("font_color", MINT if parry_bar.value >= 100 else MUTED)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(arena) or not is_instance_valid(arena.feedback_layer):
		return
	var color: Color = arena.feedback_layer.screen_color
	color.a = arena.feedback_layer.screen_flash * 0.3
	if color.a > 0:
		var view_size := get_viewport_rect().size
		draw_rect(Rect2(0, 0, view_size.x, 14), color)
		draw_rect(Rect2(0, view_size.y - 14, view_size.x, 14), color)
		draw_rect(Rect2(0, 14, 14, view_size.y - 28), color)
		draw_rect(Rect2(view_size.x - 14, 14, 14, view_size.y - 28), color)

func show_overlay(title: String, body: String, dead: bool = false) -> void:
	death_menu = dead
	overlay_title.text = title
	overlay_body.text = body
	overlay_button.text = "REINICIAR  [ENTER / R]" if dead else "CONTINUAR  [ENTER / ESC]"
	overlay.visible = true
	get_tree().paused = true
	overlay_button.grab_focus()

func resume_or_restart() -> void:
	if death_menu:
		restart()
	else:
		overlay.hide()
		get_tree().paused = false
		get_viewport().set_input_as_handled()

func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func help_menu() -> void:
	if not arena.player.active:
		return
	show_overlay("CONTROLES Y FRECUENCIA", "WASD mueve · Ratón apunta · Clic izquierdo / J dispara\nFlechas apuntan y disparan automáticamente\nEspacio / Shift hace dash · Q / clic derecho ejecuta parry\nT cambia práctica / combate · R reinicia · Esc / P pausa\n\nMando: sticks L / R, RT / RB dispara, A dash, LB parry.\nY cambia modo · Start pausa · Back reinicia.\nFrecuencia: +12 por disparo, +40 por parry. Al 100%: ruptura.\nParry: 6 frames / 100 ms. Tres impactos terminan el combate.")

func _unhandled_input(event: InputEvent) -> void:
	var viewport := get_viewport()
	if event.is_action_pressed("restart"):
		restart()
	elif overlay.visible:
		if event.is_action_pressed("start_game") or event.is_action_pressed("pause_game"):
			resume_or_restart()
	elif event.is_action_pressed("pause_game"):
		show_overlay("PAUSA", "Continúa cuando estés listo.")
	elif event.is_action_pressed("help"):
		help_menu()
	elif event.is_action_pressed("practice"):
		arena.toggle_practice()
	else:
		return
	viewport.set_input_as_handled()
