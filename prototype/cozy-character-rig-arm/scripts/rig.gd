extends Node2D
## PROTOTYPE (throwaway) — answers ONE question:
## Does a rigid cut-out UPPER BODY (head + torso + 2 one-piece sleeved arms on
## shoulder pivots) look acceptable on our chibi farmer WITHOUT painting?
## Joint-hide technique under test: z-order overlap (arms behind torso hide the
## shoulder; head in front of torso hides the neck cut).

const CAP_DIR := "/tmp/rig_frames"
const CAPTURE := true
const CAP_N := 90

var tex_head := preload("res://parts/head.png")
var tex_torso := preload("res://parts/torso.png")
var tex_arm_l := preload("res://parts/arm_l.png")
var tex_arm_r := preload("res://parts/arm_r.png")

var root: Node2D
var arm_r_pivot: Node2D
var arm_l_pivot: Node2D
var frame := 0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(CAP_DIR)
	root = Node2D.new()
	root.position = Vector2(300, 270)
	add_child(root)

	# target heights (px) and derived scales (source h: torso 300, head 300, arm 512)
	var torso_h := 200.0
	var head_h := 150.0
	var arm_h := 175.0
	var s_torso := torso_h / 300.0
	var s_head := head_h / 300.0
	var s_arm := arm_h / 512.0
	var torso_w := 213.0 * s_torso  # source torso w 213

	# torso (z=1)
	var torso := Sprite2D.new()
	torso.texture = tex_torso
	torso.centered = true
	torso.scale = Vector2(s_torso, s_torso)
	torso.z_index = 1
	root.add_child(torso)

	# head (z=2) — overlaps torso top so the neck cut is hidden
	var head := Sprite2D.new()
	head.texture = tex_head
	head.centered = true
	head.scale = Vector2(s_head, s_head)
	head.position = Vector2(0, -130)
	head.z_index = 2
	root.add_child(head)

	# shoulders sit on the upper torso
	var sh_y := -torso_h * 0.30
	var sh_x := torso_w * 0.34

	# LEFT arm pivot (z=0 -> behind torso)
	arm_l_pivot = _make_arm(tex_arm_l, s_arm, arm_h)
	arm_l_pivot.position = Vector2(-sh_x, sh_y)
	root.add_child(arm_l_pivot)

	# RIGHT arm pivot (z=0)
	arm_r_pivot = _make_arm(tex_arm_r, s_arm, arm_h)
	arm_r_pivot.position = Vector2(sh_x, sh_y)
	root.add_child(arm_r_pivot)

func _make_arm(tex: Texture2D, s: float, arm_h: float) -> Node2D:
	var pivot := Node2D.new()
	pivot.z_index = 0
	var arm := Sprite2D.new()
	arm.texture = tex
	arm.centered = true
	arm.scale = Vector2(s, s)
	arm.position = Vector2(0, arm_h * 0.5)  # top of arm at the pivot; hangs down
	pivot.add_child(arm)
	return pivot

func _process(_dt: float) -> void:
	frame += 1
	var t := float(frame) / float(CAP_N)
	# RIGHT arm: wide sweep -60deg -> +110deg (stress-tests shoulder hide)
	arm_r_pivot.rotation = deg_to_rad(-60.0 + 170.0 * t)
	# LEFT arm: gentle sway
	arm_l_pivot.rotation = deg_to_rad(12.0 + 10.0 * sin(frame * 0.18))
	if CAPTURE:
		var img := get_viewport().get_texture().get_image()
		img.save_png("%s/f%03d.png" % [CAP_DIR, frame])
	if frame >= CAP_N:
		get_tree().quit()
