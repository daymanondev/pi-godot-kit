extends Node2D
## Cut-out rig built from separated part PNGs + pivots.json.
## Procedural walk (stylized front-view): legs/arms swing in opposition + torso bob.
## No manual image editing anywhere — parts come pre-separated from agy.

const PARTS_DIR := "res://farmer_parts/"

var pivots: Dictionary = {}
var bones: Dictionary = {}  # part name -> Node2D (rotates around its joint)

@export var walk_speed: float = 7.0   # stride cadence (rad/s of the cycle phase)
@export var leg_amp: float = 0.40     # leg swing amplitude (radians)
@export var arm_amp: float = 0.28     # arm swing amplitude
@export var bob_amp: float = 4.0      # vertical torso bob (px)
@export var walking: bool = true

var _t: float = 0.0

# --- headless frame capture (render rig -> PNGs -> GIF), gated by --capture arg ---
var _cap := false
var _f := 0
const CAP_N := 96
const CAP_DIR := "/tmp/rig_frames"


func _ready() -> void:
	for a in OS.get_cmdline_args():
		if a == "--capture":
			_cap = true
			DirAccess.make_dir_recursive_absolute(CAP_DIR)
	_load_pivots()
	_build()


func _process(_delta: float) -> void:
	if not _cap:
		return
	if _f >= CAP_N:
		get_tree().quit()
		return
	var img := get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("%s/f%04d.png" % [CAP_DIR, _f])
	_f += 1


func _load_pivots() -> void:
	var f := FileAccess.open(PARTS_DIR + "pivots.json", FileAccess.READ)
	assert(f != null, "pivots.json not found at " + PARTS_DIR)
	pivots = JSON.parse_string(f.get_as_text())
	assert(pivots.size() == 6, "expected 6 parts in pivots.json, got %d" % pivots.size())


static func _vec(a) -> Vector2:
	return Vector2(a[0], a[1])


func _add(part_name: String, parent: Node, origin: Vector2) -> Node2D:
	var p: Dictionary = pivots[part_name]
	var node := Node2D.new()
	node.name = part_name
	node.position = origin
	parent.add_child(node)
	node.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else self

	var tex := load(PARTS_DIR + part_name + ".png")
	var spr := Sprite2D.new()
	spr.name = part_name + "_sprite"
	spr.texture = tex
	spr.centered = true
	var sz: Array = p["size"]
	var joint_local := _vec(p["joint"])
	# offset so the part's joint sits at this node's origin => rotation pivots on the joint
	spr.offset = Vector2(sz[0] / 2.0 - joint_local.x, sz[1] / 2.0 - joint_local.y)
	node.add_child(spr)
	bones[part_name] = node
	return node


func _build() -> void:
	# Torso-local extents (torso node at origin, hip joint at origin).
	var torso_joint_local := _vec(pivots["torso"]["joint"])
	var tsz: Array = pivots["torso"]["size"]
	var top_y := -torso_joint_local.y
	var bottom_y := float(tsz[1]) - torso_joint_local.y
	var left_x := -torso_joint_local.x
	var right_x := float(tsz[0]) - torso_joint_local.x
	# Snap each part's joint onto a torso anchor so parts CONNECT (close the
	# pre-separated gaps from the source art) instead of floating apart.
	# Push limbs ~40px INTO the torso so visible content overlaps (z-order hides seams).
	var anchors := {
		"head": Vector2(0, top_y + 40),                       # neck sunk into torso top
		"left_arm": Vector2(left_x + 80, top_y + 60),        # left shoulder, pushed in
		"right_arm": Vector2(right_x - 80, top_y + 60),      # right shoulder, pushed in
		"left_leg": Vector2(left_x + 145, bottom_y - 40),    # left hip, pushed up/in
		"right_leg": Vector2(right_x - 145, bottom_y - 40),  # right hip, pushed up/in
	}
	_add("torso", self, Vector2.ZERO)
	for n in ["head", "left_arm", "right_arm", "left_leg", "right_leg"]:
		_add(n, bones["torso"], anchors[n])
	_set_draw_order()


func _set_draw_order() -> void:
	# back-side limbs behind torso, head + front limbs in front
	bones["right_arm"].z_index = -1
	bones["right_leg"].z_index = -1
	bones["torso"].z_index = 0
	bones["head"].z_index = 1
	bones["left_arm"].z_index = 1
	bones["left_leg"].z_index = 1


func _dump() -> void:
	print("--- rig build dump ---")
	for n in ["torso", "head", "left_arm", "right_arm", "left_leg", "right_leg"]:
		var b: Node2D = bones[n]
		var s: Sprite2D = b.get_child(0)
		print("%-10s pos=%-22s rot=%.2f offset=%-18s tex=%s" % [n, str(b.position), b.rotation, str(s.offset), "" if s.texture == null else s.texture.resource_path])


func _physics_process(delta: float) -> void:
	if not walking:
		_t += delta * 2.0
		var breathe := sin(_t) * 0.01
		bones["torso"].scale = Vector2(1.0 + breathe, 1.0 - breathe)
		bones["torso"].position = Vector2.ZERO
		return
	_t += delta * walk_speed
	var s := sin(_t)
	bones["left_leg"].rotation = s * leg_amp
	bones["right_leg"].rotation = -s * leg_amp
	bones["left_arm"].rotation = -s * arm_amp
	bones["right_arm"].rotation = s * arm_amp
	# body dips twice per stride; net offset keeps feet near ground
	bones["torso"].position = Vector2(0.0, (1.0 - abs(cos(_t))) * bob_amp)
