extends Node2D
## Squash-and-stretch single-sprite animation — JOINT-FREE, FEET PLANTED.
## Structure: this Node2D is the PIVOT at the feet/ground. A child Sprite2D
## holds the character positioned so its feet sit at this pivot. Scaling the
## pivot squashes/stretches the body DOWN ONTO the feet (feet stay grounded),
## not from the sprite center.

@export var walk_speed: float = 7.0
@export var bob_amp: float = 16.0      # airborne hop height (px)
@export var stretch_amp: float = 0.12  # squash/stretch amount
@export var lean_amp: float = 0.05     # side lean (rad)
@export var walking: bool = true
@export var texture_path: String = "res://character.png"

var _t: float = 0.0
var _sprite: Sprite2D

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
	var tex := load(texture_path) as Texture2D
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.centered = true
	# place the sprite so its FEET (bottom-center) are at this pivot's origin
	_sprite.position = Vector2(0, -tex.get_height() / 2.0)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	if not walking:
		_t += delta * 1.6
		var b := sin(_t) * 0.015
		scale = Vector2(1.0 - b, 1.0 + b)   # subtle breathing, feet stay
		rotation = 0.0
		position = Vector2.ZERO
		return
	_t += delta * walk_speed
	var up := sin(_t * 2.0)            # +airborne, -grounded
	# hop: whole pivot lifts when airborne (feet leave ground briefly = a hop)
	position.y = -max(0.0, up) * bob_amp
	# squash/stretch the pivot => body deforms onto planted feet
	var s := up * stretch_amp
	scale = Vector2(1.0 - s * 0.6, 1.0 + s)   # tall+thin airborne, short+wide grounded
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
