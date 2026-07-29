extends Sprite2D
## Squash-and-stretch single-sprite animation — JOINT-FREE.
## Uses one polished character image; animates by bob / stretch / lean.
## No rigging, no separated parts, no painted overlaps => no grotesque joints.

@export var walk_speed: float = 7.0
@export var bob_amp: float = 16.0      # bounce height (px)
@export var stretch_amp: float = 0.12  # squash/stretch amount
@export var lean_amp: float = 0.05     # side lean (rad)
@export var walking: bool = true

var _t: float = 0.0

# headless frame capture -> GIF
var _cap := false
var _f := 0
const CAP_N := 96
const CAP_DIR := "/tmp/rig_frames"


func _ready() -> void:
	for a in OS.get_cmdline_args():
		if a == "--capture":
			_cap = true
			DirAccess.make_dir_recursive_absolute(CAP_DIR)
	if texture:
		offset = Vector2(0, -texture.get_height() / 2.0)  # pivot at feet


func _physics_process(delta: float) -> void:
	if not walking:
		# idle: gentle breathing
		_t += delta * 1.6
		var b := sin(_t) * 0.015
		scale = Vector2(1.0 - b, 1.0 + b)
		rotation = 0.0
		position = Vector2.ZERO
		return
	_t += delta * walk_speed
	var up := sin(_t * 2.0)            # +airborne, -grounded (2 bounces/stride)
	position.y = -max(0.0, up) * bob_amp
	var s := up * stretch_amp
	scale = Vector2(1.0 - s * 0.7, 1.0 + s)   # tall+thin airborne, short+wide grounded
	rotation = sin(_t) * lean_amp


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
