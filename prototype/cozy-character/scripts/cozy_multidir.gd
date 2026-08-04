extends CharacterBody2D
class_name CozyMultiDir
## Top-down multi-direction chibi character (Stardew/DST-style).
## Picks one of 3 directions (front / back / side) by velocity, flips the side
## animation for leftward movement. SpriteFrames are built at runtime from the
## per-action frame cycles produced by docs/character-sprite-pipeline.md:
##   - walk_* : the walk stride cycle (split + mirror of the walk sheet)
##   - idle_* : a subtle breathing cycle (per-action sheet, ADR 0002)
## Standing still plays the idle (breathing) loop for the last-moved facing,
## instead of freezing on a single frame.
##
## Modes (argv):
##   (none)  driven by move_left/right/up/down input
##   --demo  auto-cycles walk directions with idle pauses (for eyeball capture)
##   --capture  also dump viewport frames to /tmp/play_frames
##   --selftest  headless Seam-2 assertion (SpriteFrames + animation selection),
##               prints PASS/FAIL and exits 0/1

const SPEED := 150.0
const IDLE_SPEED := 5.0   # fps for the breathing loop (slower than walk)

# direction bucket -> the directory prefix used for that direction's frame files.
const DIRS := {"front": "front_3q", "back": "back", "side": "side_right"}
# velocity below this (px/s) counts as "standing still" -> idle.
const IDLE_VEL := 5.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _demo := false
var _demo_t := 0.0
var _facing := "side"   # current direction bucket: front / back / side

# headless frame capture
var _cap := false
var _f := 0
const CAP_N := 600   # ~1 full demo cycle (8 phases x 1.2s @ 60fps = 576)
const CAP_DIR := "/tmp/play_frames"

# headless Seam-2 selftest
var _selftest := false


func _ready() -> void:
	# Godot 4 splits args after `--` into get_cmdline_user_args(); read both so
	# flags work whether or not the caller used the `--` separator.
	var args := PackedStringArray()
	args.append_array(OS.get_cmdline_args())
	args.append_array(OS.get_cmdline_user_args())
	for a in args:
		match a:
			"--demo": _demo = true
			"--capture":
				_cap = true
				DirAccess.make_dir_recursive_absolute(CAP_DIR)
			"--selftest": _selftest = true
	_sprite.sprite_frames = _build_frames()
	_sprite.animation = "idle_side"
	_sprite.play()
	if _selftest:
		_run_selftest()


func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	# walk frames live at character_frames/<dir>_<i>.png; every other action at
	# character_frames/<action>/<dir>_<i>.png.
	_add_cycle(sf, "walk", "", 8.0)
	_add_cycle(sf, "idle", "idle", IDLE_SPEED)
	return sf


## Add a 4-frame looping animation per direction under `prefix`. `subdir` selects
## the asset folder ("" = character_frames/, else character_frames/<subdir>/).
func _add_cycle(sf: SpriteFrames, prefix: String, subdir: String, fps: float) -> void:
	var folder := "res://character_frames/" + (subdir + "/" if subdir != "" else "")
	for d in DIRS:
		var anim: String = prefix + "_" + d
		sf.add_animation(anim)
		for i in 4:
			sf.add_frame(anim, load("%s%s_%d.png" % [folder, DIRS[d], i]))
		sf.set_animation_speed(anim, fps)
		sf.set_animation_loop(anim, true)


## Choose facing, flip, and animation from the current velocity. Extracted from
## _physics_process so the headless selftest can exercise it deterministically.
func _select_animation() -> void:
	if velocity.length() < IDLE_VEL:
		# standing still -> idle (breathing) for the last-moved facing.
		# _facing and flip_h are retained, so idle faces the last move direction.
		_set_anim("idle_" + _facing)
	else:
		if absf(velocity.x) > absf(velocity.y):
			_facing = "side"
			_sprite.flip_h = velocity.x < 0.0
		elif velocity.y > 0.0:
			_facing = "front"
		else:
			_facing = "back"
		_set_anim("walk_" + _facing)


func _set_anim(anim: String) -> void:
	# only (re)start when the animation actually changes, so a sustained walk or
	# idle doesn't reset to frame 0 every physics tick.
	if _sprite.animation != anim:
		_sprite.animation = anim
	if not _sprite.is_playing():
		_sprite.play()


func _physics_process(delta: float) -> void:
	var vx := 0.0
	var vy := 0.0
	if _demo:
		_demo_t += delta
		# 8-phase cycle: walk each cardinal direction, idling between each so the
		# demo shows walk<->idle transitions and idle in every facing.
		match int(_demo_t / 1.2) % 8:
			0: vx = 1.0    # walk right (side)
			1: pass        # idle (last: side, flipped none)
			2: vy = 1.0    # walk down (front)
			3: pass        # idle (front)
			4: vx = -1.0   # walk left (side, flipped)
			5: pass        # idle (side, flipped)
			6: vy = -1.0   # walk up (back)
			7: pass        # idle (back)
	else:
		vx = Input.get_axis("move_left", "move_right")
		vy = Input.get_axis("move_up", "move_down")
	velocity = Vector2(vx, vy).normalized() * SPEED
	move_and_slide()
	_select_animation()

	if _cap:
		if _f >= CAP_N:
			get_tree().quit()
			return
		var img := get_viewport().get_texture().get_image()
		if img != null:
			img.save_png("%s/f%04d.png" % [CAP_DIR, _f])
		_f += 1


# ---- Seam-2 headless selftest (spec #20 testing decisions) ----
# Asserts SpriteFrames contains walk_*/idle_* and the controller selects idle at
# rest and walk when moving, retaining the last facing + flip into idle.
func _run_selftest() -> void:
	var sf: SpriteFrames = _sprite.sprite_frames
	for a in ["walk_front", "walk_back", "walk_side", "idle_front", "idle_back", "idle_side"]:
		if not sf.has_animation(a):
			return _fail("SpriteFrames missing animation: %s" % a)
		if sf.get_frame_count(a) != 4:
			return _fail("animation %s has %d frames, expected 4" % [a, sf.get_frame_count(a)])

	# start from rest -> idle in the default facing (side)
	_facing = "side"
	_sprite.flip_h = false
	if not _expect(Vector2.ZERO, "idle_side", "at rest"): return

	# move right -> walk_side, not flipped
	if not _expect(Vector2(SPEED, 0.0), "walk_side", "move right"): return
	if _sprite.flip_h:
		return _fail("move right: flip_h should be false")

	# move left -> walk_side, flipped; last facing = side
	if not _expect(Vector2(-SPEED, 0.0), "walk_side", "move left"): return
	if not _sprite.flip_h:
		return _fail("move left: flip_h should be true")

	# stop -> idle_side, flip retained (idle faces last move = left)
	if not _expect(Vector2.ZERO, "idle_side", "stop after left"): return
	if not _sprite.flip_h:
		return _fail("idle should retain last flip_h (true)")

	# down -> front, then idle front
	if not _expect(Vector2(0.0, SPEED), "walk_front", "move down"): return
	if not _expect(Vector2.ZERO, "idle_front", "stop (front)"): return

	# up -> back, then idle back
	if not _expect(Vector2(0.0, -SPEED), "walk_back", "move up"): return
	if not _expect(Vector2.ZERO, "idle_back", "stop (back)"): return

	print("[selftest] PASS — 6 animations (walk_*/idle_*), idle@rest, walk when moving, facing+flip retained into idle")
	get_tree().quit(0)


## Drive selection with `vel` and assert the resulting animation. Returns false
## (after reporting) if it doesn't match, so callers can early-return.
func _expect(vel: Vector2, expected_anim: String, label: String) -> bool:
	velocity = vel
	_select_animation()
	if _sprite.animation != expected_anim:
		_fail("%s: expected %s, got %s" % [label, expected_anim, _sprite.animation])
		return false
	return true


func _fail(msg: String) -> void:
	push_error("[selftest] FAIL — %s" % msg)
	print("[selftest] FAIL — %s" % msg)
	get_tree().quit(1)
