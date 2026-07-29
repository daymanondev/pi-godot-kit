extends CharacterBody2D
class_name CozyMultiDir
## Top-down multi-direction chibi character (Stardew/DST-style).
## Picks one of 3 walk animations (front / back / side) by velocity direction,
## flips the side animation for leftward movement. SpriteFrames are built at
## runtime from the 12 frames produced by docs/character-sprite-pipeline.md.
##
## `--demo` auto-cycles directions (for headless capture/verify); otherwise
## driven by move_left/right/up/down input.

const SPEED := 150.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _demo := false
var _demo_t := 0.0
var _facing := "side"   # current direction bucket: front / back / side

# headless frame capture
var _cap := false
var _f := 0
const CAP_N := 360
const CAP_DIR := "/tmp/play_frames"


func _ready() -> void:
	for a in OS.get_cmdline_args():
		if a == "--demo":
			_demo = true
		if a == "--capture":
			_cap = true
			DirAccess.make_dir_recursive_absolute(CAP_DIR)
	_sprite.sprite_frames = _build_frames()
	_sprite.animation = "walk_side"
	_sprite.play()


func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	var dirs := {"front": "front_3q", "back": "back", "side": "side_right"}
	for d in dirs:
		sf.add_animation("walk_" + d)
		# play all 4 frames in order. front/back come from multidir_v4 (straight +
		# truly alternating opposite legs); side from a dedicated sheet (has a
		# passing pose for motion, since agy won't draw 2 distinct side strides).
		for i in 4:
			sf.add_frame("walk_" + d, load("res://character_frames/%s_%d.png" % [dirs[d], i]))
		sf.set_animation_speed("walk_" + d, 8.0)
		sf.set_animation_loop("walk_" + d, true)
	return sf


func _physics_process(delta: float) -> void:
	var vx := 0.0
	var vy := 0.0
	if _demo:
		_demo_t += delta
		match int(_demo_t / 1.5) % 4:
			0: vx = 1.0
			1: vy = 1.0
			2: vx = -1.0
			3: vy = -1.0
	else:
		vx = Input.get_axis("move_left", "move_right")
		vy = Input.get_axis("move_up", "move_down")
	velocity = Vector2(vx, vy).normalized() * SPEED
	move_and_slide()

	# choose facing bucket from velocity
	if velocity.length() < 5.0:
		_facing = _facing  # keep last facing
		_sprite.animation = "walk_" + _facing
		_sprite.stop()     # idle on frame 0 (standing) of the current direction
	else:
		if absf(velocity.x) > absf(velocity.y):
			_facing = "side"
			_sprite.flip_h = velocity.x < 0.0
		elif velocity.y > 0.0:
			_facing = "front"
		else:
			_facing = "back"
		_sprite.animation = "walk_" + _facing
		if not _sprite.is_playing():
			_sprite.play()

	if _cap:
		if _f >= CAP_N:
			get_tree().quit()
			return
		var img := get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("%s/f%04d.png" % [CAP_DIR, _f])
		_f += 1
