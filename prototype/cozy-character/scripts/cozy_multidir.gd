extends CharacterBody2D
class_name CozyMultiDir
## Top-down multi-direction chibi character (Stardew/DST-style).
## Picks one of 3 directions (front / back / side) by velocity, flips the side
## animation for leftward movement. SpriteFrames are built at runtime from the
## per-action frame cycles produced by docs/character-sprite-pipeline.md:
##   - walk_* : the walk stride cycle (split + mirror of the walk sheet)
##   - idle_* : a subtle breathing cycle (per-action sheet, ADR 0002)
##   - hoe_*  : a one-shot hoe swing (per-action sheet, ADR 0002 / #23)
## Standing still plays the idle (breathing) loop for the last-moved facing,
## instead of freezing on a single frame. Pressing the `use_tool` action
## (Space / J) plays the hoe swing once for the current facing, then returns
## to the real idle (#23).
##
## Modes (argv):
##   (none)  driven by move_left/right/up/down input
##   --demo  auto-cycles walk directions with idle pauses (for eyeball capture)
##   --capture  also dump viewport frames to /tmp/play_frames
##   --selftest  headless Seam-2 assertion (SpriteFrames + animation selection),
##               prints PASS/FAIL and exits 0/1

const SPEED := 150.0
const IDLE_SPEED := 5.0   # fps for the breathing loop (slower than walk)
const HOE_SPEED := 10.0   # fps for the one-shot hoe swing (4 frames ≈ 0.4s)
const DEMO_PHASE_LEN := 1.2
const DEMO_PHASES := 12   # 4 facing-states (3 dirs + flipped side) x {walk, idle, hoe}

# direction bucket -> the directory prefix used for that direction's frame files.
const DIRS := {"front": "front_3q", "back": "back", "side": "side_right"}
# velocity below this (px/s) counts as "standing still" -> idle.
const IDLE_VEL := 5.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _demo := false
var _demo_t := 0.0
var _last_phase := -1
var _facing := "side"   # current direction bucket: front / back / side
var _hoeing := false    # true while the one-shot hoe swing is playing

# headless frame capture
var _cap := false
var _f := 0
const CAP_N := 900   # ~1 full demo cycle (12 phases x 1.2s @ 60fps = 864)
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
	_sprite.animation_finished.connect(_on_animation_finished)
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
	# hoe plays once (non-looping); _on_animation_finished returns it to idle.
	_add_cycle(sf, "hoe", "hoe", HOE_SPEED, false)
	return sf


## Add a 4-frame animation per direction under `prefix`. `subdir` selects the
## asset folder ("" = character_frames/, else character_frames/<subdir>/).
## `loop` defaults true (walk/idle); the one-shot hoe swing passes false.
func _add_cycle(sf: SpriteFrames, prefix: String, subdir: String, fps: float, loop: bool = true) -> void:
	var folder := "res://character_frames/" + (subdir + "/" if subdir != "" else "")
	for d in DIRS:
		var anim: String = prefix + "_" + d
		sf.add_animation(anim)
		for i in 4:
			sf.add_frame(anim, load("%s%s_%d.png" % [folder, DIRS[d], i]))
		sf.set_animation_speed(anim, fps)
		sf.set_animation_loop(anim, loop)


## Choose facing, flip, and animation from the current velocity. Extracted from
## _physics_process so the headless selftest can exercise it deterministically.
func _select_animation() -> void:
	if _hoeing:
		# the one-shot hoe swing plays to completion; don't override it with
		# walk/idle until _on_animation_finished clears _hoeing.
		_set_anim("hoe_" + _facing)
		return
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


## Begin the one-shot hoe swing for the current facing (#23). _select_animation
## then plays hoe_<dir>; _on_animation_finished clears _hoeing and returns to idle.
func _start_hoe() -> void:
	_hoeing = true
	_select_animation()


## animation_finished handler: when a non-looping hoe swing ends, drop back to
## the real idle (or walk if still moving) for the retained facing.
## NOTE: AnimatedSprite2D.animation_finished passes NO args (unlike
## AnimationPlayer); the finished anim is read from _sprite.animation.
func _on_animation_finished() -> void:
	if _hoeing and _sprite.animation.begins_with("hoe_"):
		_hoeing = false
		_select_animation()


func _physics_process(delta: float) -> void:
	var vx := 0.0
	var vy := 0.0
	if _demo:
		_demo_t += delta
		# 12-phase cycle: for each of 3 facings, walk in -> idle -> hoe. The hoe
		# phase starts the one-shot swing on entry (velocity 0) so the demo shows
		# the swing + return-to-idle in every facing, incl. the flipped side.
		var phase := int(_demo_t / DEMO_PHASE_LEN) % DEMO_PHASES
		if phase != _last_phase:
			_last_phase = phase
			if phase % 3 == 2:
				_start_hoe()
		match phase:
			0: vx = 1.0    # walk right (side)
			1: pass        # idle (side)
			2: pass        # hoe (side)
			3: vy = 1.0    # walk down (front)
			4: pass        # idle (front)
			5: pass        # hoe (front)
			6: vx = -1.0   # walk left (side, flipped)
			7: pass        # idle (side, flipped)
			8: pass        # hoe (side, flipped)
			9: vy = -1.0   # walk up (back)
			10: pass       # idle (back)
			11: pass       # hoe (back)
	else:
		if Input.is_action_just_pressed("use_tool") and not _hoeing:
			_start_hoe()
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

	# ---- hoe action (#23): hoe_* present, 4 frames, non-looping ----
	for a in ["hoe_front", "hoe_back", "hoe_side"]:
		if not sf.has_animation(a):
			return _fail("SpriteFrames missing hoe animation: %s" % a)
		if sf.get_frame_count(a) != 4:
			return _fail("hoe %s has %d frames, expected 4" % [a, sf.get_frame_count(a)])
		if sf.get_animation_loop(a):
			return _fail("hoe animation %s must NOT loop (plays once then idle)" % a)

	# at rest, facing side -> start hoe -> hoe_side; finish -> back to idle_side
	_facing = "side"
	_sprite.flip_h = false
	velocity = Vector2.ZERO
	_start_hoe()
	if _sprite.animation != "hoe_side":
		return _fail("start_hoe (side): expected hoe_side, got %s" % _sprite.animation)
	if not _hoeing:
		return _fail("start_hoe (side): _hoeing should be true")
	_on_animation_finished()  # simulate the swing completing
	if _hoeing:
		return _fail("after hoe finish (side): _hoeing should be false")
	if _sprite.animation != "idle_side":
		return _fail("after hoe finish (side): expected idle_side, got %s" % _sprite.animation)

	# facing front -> hoe_front -> idle_front
	_facing = "front"
	_start_hoe()
	if _sprite.animation != "hoe_front":
		return _fail("start_hoe (front): expected hoe_front, got %s" % _sprite.animation)
	_on_animation_finished()
	if _sprite.animation != "idle_front":
		return _fail("after hoe finish (front): expected idle_front, got %s" % _sprite.animation)

	# facing back -> hoe_back -> idle_back
	_facing = "back"
	_start_hoe()
	if _sprite.animation != "hoe_back":
		return _fail("start_hoe (back): expected hoe_back, got %s" % _sprite.animation)
	_on_animation_finished()
	if _sprite.animation != "idle_back":
		return _fail("after hoe finish (back): expected idle_back, got %s" % _sprite.animation)

	# while hoeing, _select_animation must stay on hoe even if moving; on finish
	# it falls through to walk (velocity still set).
	_facing = "side"
	velocity = Vector2.ZERO
	_start_hoe()
	velocity = Vector2(SPEED, 0.0)  # now moving mid-swing
	_select_animation()
	if _sprite.animation != "hoe_side":
		return _fail("while hoeing + moving: should stay hoe_side, got %s" % _sprite.animation)
	_on_animation_finished()  # swing ends
	_select_animation()
	if _sprite.animation != "walk_side":
		return _fail("hoe finished while moving: expected walk_side, got %s" % _sprite.animation)

	print("[selftest] PASS — 9 animations (walk_*/idle_*/hoe_*), idle@rest, walk when moving, facing+flip retained into idle, use_tool -> hoe then idle")
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
