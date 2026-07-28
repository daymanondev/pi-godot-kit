extends Node
## Autoload: registers movement input actions at runtime.
##
## PROTOTYPE NOTE: a real template would put these in project.godot's [input]
## section (Godot editor: Project > Project Settings > Input Map). We register
## them in code here to avoid the brittle project.godot input serialization and
## to guarantee the actions exist for the headless self-test (Input.action_press).

func _ready() -> void:
	_ensure("move_left", [KEY_A, KEY_LEFT])
	_ensure("move_right", [KEY_D, KEY_RIGHT])
	_ensure("jump", [KEY_SPACE, KEY_W, KEY_UP])


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
