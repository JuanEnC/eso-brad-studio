extends Control

const BLUE := Color("70b8ff")
const MINT := Color("75f6d0")
const INK := Color("0b1521")
const TEXT := Color("e0eaf4")
const MUTED := Color("8da3b7")
const DANGER := Color("ff8da3")
const AURA_COLOR := Color("f8cc89")
var arena: Node2D
var health_label: Label
var hope_bar: ProgressBar
var aura_label: Label
var mode_label: Label
var dash_label: Label
var parry_label: Label
var dash_bar: ProgressBar
var parry_bar: ProgressBar
var boss_panel: Panel
var boss_title: Label
var boss_health: ProgressBar
var boss_frac: ProgressBar
var boss_status: Label
var overlay: Panel
var overlay_card: Panel
var overlay_title: Label
var overlay_body: Label
var overlay_button: Button
var overlay_motion: Tween
var run_finished: bool = false
var title_screen: bool = false
var shop_overlay: Panel
var shop_card: Panel
var shop_balance: Label
var shop_continue: Button
var shop_choices: VBoxContainer
var shop_rows: Dictionary = {}

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
	aura_label = _label("AURA  0", Rect2(24, 94, 180, 26), 17, AURA_COLOR)
	mode_label = _label("", Rect2(0, 24, 190, 20), 12, MUTED)
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dash_label = _label("DASH", Rect2(24, 0, 96, 20), 12, BLUE)
	parry_label = _label("PARRY", Rect2(144, 0, 96, 20), 12, MINT)
	dash_bar = _bar(Rect2(24, 0, 96, 5), BLUE)
	parry_bar = _bar(Rect2(144, 0, 96, 5), MINT)
	boss_panel = _panel(Rect2(0, 18, 488, 100))
	boss_title = _label("", Rect2(20, 8, 448, 25), 15, TEXT, boss_panel)
	boss_health = _bar(Rect2(20, 38, 448, 16), Color("d86179"), boss_panel)
	boss_frac = _bar(Rect2(20, 62, 448, 5), Color("ffba69"), boss_panel)
	boss_status = _label("", Rect2(20, 72, 448, 20), 13, MUTED, boss_panel)
	boss_panel.hide()
	overlay = _panel(Rect2())
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := StyleBoxFlat.new()
	shade.bg_color = Color(0.012, 0.018, 0.03, 0.88)
	overlay.add_theme_stylebox_override("panel", shade)
	overlay_card = _panel(Rect2(0, 0, 650, 376), overlay)
	overlay_title = _label("", Rect2(42, 31, 566, 84), 44, TEXT, overlay_card)
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_body = _label("", Rect2(54, 121, 542, 151), 17, TEXT, overlay_card)
	overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_body.add_theme_constant_override("line_spacing", 8)
	overlay_button = _button("", Rect2(158, 293, 334, 48), resume_or_restart, overlay_card)
	overlay_button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, MINT))
	overlay.hide()
	_build_shop(shade)

func _build_shop(shade: StyleBoxFlat) -> void:
	shop_overlay = _panel(Rect2())
	shop_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_overlay.add_theme_stylebox_override("panel", shade)
	shop_card = _panel(Rect2(0, 0, 810, 492), shop_overlay)
	shop_card.add_theme_stylebox_override("panel", _style(Color("0c1522"), Color("715942")))
	_label("MEJORAS DE AURA", Rect2(30, 21, 470, 47), 32, TEXT, shop_card)
	shop_balance = _label("", Rect2(566, 28, 214, 36), 22, AURA_COLOR, shop_card)
	shop_balance.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label("El AURA restante se conserva para las siguientes salas.", Rect2(32, 72, 670, 26), 15, MUTED, shop_card)
	shop_choices = VBoxContainer.new()
	shop_choices.position = Vector2(30, 115)
	shop_choices.add_theme_constant_override("separation", 8)
	shop_choices.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shop_card.add_child(shop_choices)
	shop_continue = _button("ABRIR COMPUERTAS", Rect2(532, 429, 248, 40), _finish_shop, shop_card)
	shop_continue.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, MINT))
	shop_overlay.hide()

func _build_shop_offers(offers: Array[Dictionary]) -> void:
	for row in shop_choices.get_children():
		shop_choices.remove_child(row)
		row.queue_free()
	shop_rows.clear()
	var row: HBoxContainer
	for i in offers.size():
		if i % 2 == 0:
			row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 12)
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shop_choices.add_child(row)
		var offer := offers[i]
		var id: String = offer["id"]
		var button := _button("", Rect2(0, 0, 369, 92), _buy_upgrade.bind(id), row)
		button.custom_minimum_size = Vector2(369, 92)
		button.add_theme_stylebox_override("focus", _style(Color.TRANSPARENT, MINT))
		button.add_theme_stylebox_override("disabled", _style(Color("121d2b")))
		_label(offer["title"], Rect2(15, 7, 339, 23), 17, TEXT, button)
		var description := _label(offer["description"], Rect2(15, 29, 339, 35), 14, MUTED, button)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var status := _label("", Rect2(15, 66, 339, 18), 13, AURA_COLOR, button)
		shop_rows[id] = {"button": button, "status": status}

func _refresh_shop(offers: Array[Dictionary]) -> void:
	shop_balance.text = "%d AURA" % arena.aura
	aura_label.text = "AURA  %d" % arena.aura
	for offer in offers:
		var entry: Dictionary = shop_rows[offer["id"]]
		var button: Button = entry["button"]
		var status: Label = entry["status"]
		var price: int = offer["price"]
		var rank: int = offer["rank"]
		var max_rank: int = offer["max_rank"]
		var maxed := rank >= max_rank
		var can_afford: bool = arena.aura >= price
		var held_focus := button.has_focus()
		button.disabled = maxed or not can_afford
		if maxed:
			status.text = "ADQUIRIDA" if max_rank == 1 else "NIVEL MÁXIMO  %d/%d" % [rank, max_rank]
		else:
			var cost := "%d AURA" % price
			var detail := " · Nivel %d/%d" % [rank, max_rank] if max_rank > 1 else ""
			var shortage := " · Faltan %d" % (price - arena.aura) if not can_afford else ""
			status.text = cost + detail + shortage
		status.add_theme_color_override("font_color", MUTED if button.disabled else AURA_COLOR)
		if held_focus and button.disabled:
			shop_continue.grab_focus()

func show_shop() -> void:
	var offers: Array[Dictionary] = arena.shop_offers()
	_build_shop_offers(offers)
	_refresh_shop(offers)
	get_tree().paused = true
	shop_overlay.show()
	shop_continue.grab_focus()

func _buy_upgrade(id: String) -> void:
	if arena.buy_upgrade(id):
		_refresh_shop(arena.shop_offers())

func _finish_shop() -> void:
	if shop_overlay.visible:
		shop_overlay.hide()
		arena.finish_shop()

func _layout() -> void:
	var view_size := get_viewport_rect().size
	mode_label.position.x = view_size.x - mode_label.size.x - 24
	boss_panel.position.x = (view_size.x - boss_panel.size.x) * 0.5
	dash_label.position.y = view_size.y - 60
	parry_label.position.y = view_size.y - 60
	dash_bar.position.y = view_size.y - 34
	parry_bar.position.y = view_size.y - 34
	overlay.size = view_size
	overlay_card.position = (view_size - overlay_card.size) * 0.5
	shop_overlay.size = view_size
	shop_card.position = (view_size - shop_card.size) * 0.5

func _process(_delta: float) -> void:
	if not is_instance_valid(arena.player):
		return
	var player: AbyssPlayer = arena.player
	health_label.text = "INTEGRIDAD  " + "◆ ".repeat(maxi(0, player.health)) + "◇ ".repeat(maxi(0, player.max_health - player.health))
	health_label.add_theme_color_override("font_color", DANGER if player.health <= 1 else BLUE)
	hope_bar.value = player.hope
	aura_label.text = "AURA  %d" % arena.aura
	mode_label.text = arena.room_name()
	var boss := arena.boss as FinalBoss
	boss_panel.visible = is_instance_valid(boss) and boss.active
	if boss_panel.visible:
		boss_title.text = "EL GUARDIÁN  ·  FASE " + ("II" if boss.enraged else "I")
		boss_health.max_value = boss.max_health
		boss_health.value = boss.health
		var shield_up := boss.shield_points > 0
		boss_frac.max_value = boss.shield_max if shield_up else boss.tuning.frequency_max
		boss_frac.value = boss.shield_points if shield_up else boss.frequency
		var fill: StyleBoxFlat = boss_frac.get_theme_stylebox("fill")
		fill.bg_color = BLUE if shield_up else (MINT if boss.frequency_broken else Color("ffba69"))
		fill.border_color = fill.bg_color
		if shield_up:
			boss_status.text = "ESCUDO %d/%d · Usa PARRY o disparos críticos" % [boss.shield_points, boss.shield_max]
		else:
			boss_status.text = "RUPTURA · DAÑO ×2" if boss.frequency_broken else "ESCUDO ROTO · FRAC %d%%" % roundi(100.0 * boss.frequency / boss.tuning.frequency_max)
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

func show_start() -> void:
	show_overlay("ABYSS", "Despeja tres capas y derrota al Guardián.\n\nWASD para moverte · Ratón y clic para disparar\nEspacio para DASH · Q para PARRY · F1 para ver los controles", "JUGAR  [ENTER]", MINT)
	title_screen = true
	overlay_title.add_theme_font_size_override("font_size", 68)

func show_result(victory: bool) -> void:
	if victory:
		show_overlay("VICTORIA", "El Guardián ha caído. Atravesaste las tres capas y liberaste el Núcleo.\nAURA restante  %d" % arena.aura, "VOLVER A JUGAR  [ENTER / R]", MINT, true)
	else:
		show_overlay("DERROTA", "Perdiste toda tu Integridad. La siguiente expedición empieza en el Umbral.", "REINTENTAR  [ENTER / R]", DANGER, true)

func show_overlay(title: String, body: String, action: String = "CONTINUAR  [ENTER / ESC]", accent: Color = BLUE, finished: bool = false) -> void:
	title_screen = false
	run_finished = finished
	overlay_title.text = title
	overlay_title.add_theme_color_override("font_color", accent)
	overlay_title.add_theme_font_size_override("font_size", 44)
	overlay_body.text = body
	overlay_button.text = action
	var card_style := _style(Color("0c1522"), Color(accent, 0.45))
	card_style.shadow_color = Color(0, 0, 0, 0.4)
	card_style.shadow_size = 14
	overlay_card.add_theme_stylebox_override("panel", card_style)
	overlay.show()
	get_tree().paused = true
	if overlay_motion:
		overlay_motion.kill()
	overlay_card.modulate.a = 0.18
	overlay_motion = create_tween()
	overlay_motion.tween_property(overlay_card, "modulate:a", 1.0, 0.16)
	overlay_button.grab_focus()

func resume_or_restart() -> void:
	if run_finished:
		restart()
	else:
		title_screen = false
		overlay.hide()
		get_tree().paused = false
		get_viewport().set_input_as_handled()

func restart() -> void:
	get_tree().set_meta("abyss_retry", true)
	get_tree().paused = false
	get_tree().reload_current_scene()

func help_menu() -> void:
	if not arena.player.active:
		return
	show_overlay("CONTROLES", "WASD / stick izq. mueve · Ratón / stick der. apunta\nClic izq. / J / RT dispara · Flechas apuntan y disparan\nEspacio / Shift / A hace DASH · Q / clic der. / LB hace PARRY\n\nGasta AURA al despejar salas. El PARRY recupera Esperanza.\nAl 100 % de FRAC, los enemigos reciben el doble de daño.")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var viewport := get_viewport()
	if event.is_action_pressed("restart") and not title_screen:
		restart()
	elif shop_overlay.visible:
		return
	elif overlay.visible:
		if event.is_action_pressed("start_game") or (not title_screen and not run_finished and event.is_action_pressed("pause_game")):
			resume_or_restart()
		else:
			return
	elif event.is_action_pressed("pause_game"):
		show_overlay("PAUSA", "Continúa cuando estés listo.")
	elif event.is_action_pressed("help"):
		help_menu()
	else:
		return
	viewport.set_input_as_handled()
