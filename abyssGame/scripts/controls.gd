extends Node

func _ready() -> void:
	_bind("move_left", [KEY_A], JOY_AXIS_LEFT_X, -1.0)
	_bind("move_right", [KEY_D], JOY_AXIS_LEFT_X, 1.0)
	_bind("move_up", [KEY_W], JOY_AXIS_LEFT_Y, -1.0)
	_bind("move_down", [KEY_S], JOY_AXIS_LEFT_Y, 1.0)
	_bind("aim_left", [KEY_LEFT], JOY_AXIS_RIGHT_X, -1.0)
	_bind("aim_right", [KEY_RIGHT], JOY_AXIS_RIGHT_X, 1.0)
	_bind("aim_up", [KEY_UP], JOY_AXIS_RIGHT_Y, -1.0)
	_bind("aim_down", [KEY_DOWN], JOY_AXIS_RIGHT_Y, 1.0)
	_bind("fire_left", [KEY_LEFT])
	_bind("fire_right", [KEY_RIGHT])
	_bind("fire_up", [KEY_UP])
	_bind("fire_down", [KEY_DOWN])
	_bind("dash", [KEY_SPACE, KEY_SHIFT], -1, 0.0, MOUSE_BUTTON_NONE, JOY_BUTTON_A)
	_bind("parry", [KEY_Q], -1, 0.0, MOUSE_BUTTON_RIGHT, JOY_BUTTON_LEFT_SHOULDER)
	_bind("shoot", [KEY_J], JOY_AXIS_TRIGGER_RIGHT, 1.0, MOUSE_BUTTON_LEFT, JOY_BUTTON_RIGHT_SHOULDER)
	_bind("restart", [KEY_R], -1, 0.0, MOUSE_BUTTON_NONE, JOY_BUTTON_BACK)
	_bind("practice", [KEY_T], -1, 0.0, MOUSE_BUTTON_NONE, JOY_BUTTON_Y)
	_bind("pause_game", [KEY_ESCAPE, KEY_P], -1, 0.0, MOUSE_BUTTON_NONE, JOY_BUTTON_START)
	_bind("help", [KEY_F1])
	_bind("start_game", [KEY_ENTER], -1, 0.0, MOUSE_BUTTON_NONE, JOY_BUTTON_A)

func _bind(action: String, keys: Array, axis: int = -1, axis_value: float = 0.0, mouse: int = MOUSE_BUTTON_NONE, button: int = -1) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.22)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
	if axis >= 0:
		var event := InputEventJoypadMotion.new()
		event.device = -1
		event.axis = axis
		event.axis_value = axis_value
		InputMap.action_add_event(action, event)
	if mouse != MOUSE_BUTTON_NONE:
		var event := InputEventMouseButton.new()
		event.button_index = mouse
		InputMap.action_add_event(action, event)
	if button >= 0:
		var event := InputEventJoypadButton.new()
		event.device = -1
		event.button_index = button
		InputMap.action_add_event(action, event)
