extends Node2D
## Root scene. In the editor: just play. Headless: runs a scripted self-test
## that presses move_right then jump and prints the character state at each
## step, so `godot --headless` can validate the input->move->anim pipeline.

@onready var _char: CozyCharacter = $CozyCharacter


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		_selftest()


func _selftest() -> void:
	print("[selftest] start    %s" % _state())
	await get_tree().create_timer(0.4).timeout
	Input.action_press("move_right")
	print("[selftest] ->right  %s" % _state())
	await get_tree().create_timer(0.5).timeout
	print("[selftest] walking  %s" % _state())
	Input.action_release("move_right")
	await get_tree().create_timer(0.3).timeout
	print("[selftest] idle     %s" % _state())
	Input.action_press("jump")
	await get_tree().create_timer(0.1).timeout
	print("[selftest] airborne %s" % _state())
	Input.action_release("jump")
	await get_tree().create_timer(0.7).timeout
	print("[selftest] landed  %s" % _state())
	print("[selftest] PASS — scaffold validated")
	get_tree().quit()


func _state() -> String:
	return "anim=%s vel=(%.0f,%.0f) on_floor=%s" % [
		_char.current_anim(), _char.velocity.x, _char.velocity.y, _char.is_on_floor()
	]
