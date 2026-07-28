extends CharacterBody2D
class_name CozyCharacter
## Tier-Simple cozy character: gravity + move + jump, flips sprite, swaps
## idle<->walk animation. The SpriteFrames are built at runtime from the
## pack_spritesheet.py (#5) output (PNG + JSON sidecar) — this file is the
## Godot consumer for skills/simple-rig.

const SPEED := 120.0
const JUMP_VELOCITY := -320.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
var _gravity: float = 980.0


func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0))
	_sprite.sprite_frames = _build_frames()
	_sprite.play("idle")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		velocity.x = dir * SPEED
		_sprite.flip_h = dir < 0.0
		if _sprite.animation != "walk":
			_sprite.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		if _sprite.animation != "idle":
			_sprite.play("idle")

	move_and_slide()


func current_anim() -> String:
	return _sprite.animation


# ---- SpriteFrames from pack_spritesheet.py output (the #5 -> Godot glue) ----

func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation("idle")
	sf.add_animation("walk")
	_load_pack(sf, "idle", "res://assets/sprites/farmer_idle")
	_load_pack(sf, "walk", "res://assets/sprites/farmer_walk")
	return sf


func _load_pack(sf: SpriteFrames, anim: String, prefix: String) -> void:
	var tex: Texture2D = load(prefix + ".png")
	var f := FileAccess.open(prefix + ".json", FileAccess.READ)
	assert(f != null, "missing sprite sidecar: %s.json" % prefix)
	var meta: Dictionary = JSON.parse_string(f.get_as_text())
	var fw := int(meta["frame_width"])
	var fh := int(meta["frame_height"])
	var cols := int(meta["columns"])
	var count := int(meta["frame_count"])
	var fps := float(meta["fps"])
	for i in count:
		var col := i % cols
		var row := i / cols
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(col * fw, row * fh, fw, fh)
		sf.add_frame(anim, at)
	sf.set_animation_speed(anim, fps)
	sf.set_animation_loop(anim, true)
