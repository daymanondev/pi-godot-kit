extends Node
## Autoload: registers movement input actions at runtime.
## Top-down 4-directional (wasd / arrows) for the multi-direction chibi.

func _ready() -> void:
	_ensure("move_left", [KEY_A, KEY_LEFT])
	_ensure("move_right", [KEY_D, KEY_RIGHT])
	_ensure("move_up", [KEY_W, KEY_UP])
	_ensure("move_down", [KEY_S, KEY_DOWN])
	# use_tool: the one-shot hoe swing (#23). Space or J.
	_ensure("use_tool", [KEY_SPACE, KEY_J])


func _ensure(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		if not _has(action, ev):
			InputMap.action_add_event(action, ev)


func _has(action: String, ev: InputEventKey) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and (e as InputEventKey).physical_keycode == ev.physical_keycode:
			return true
	return false
