---
name: simple-rig
description: Turn a single 2D character image into an animated sprite sheet for Godot, using Meta AnimatedDrawings (free, auto-rig, soft-warp) then packing frames into a grid sprite sheet. Use after `agy-image` to make a cozy character walk/idle, or when the user says "rig this character" / "animate the sprite" / "make a sprite sheet".
---

# simple-rig

The **rig + animate** step of the Tier Simple cozy pipeline. Takes one character image (from `agy-image`), runs it through [Meta AnimatedDrawings](https://github.com/facebookresearch/AnimatedDrawings) (auto-detects joints → retargets BVH mocap → renders an animated GIF/MP4), then packs the frames into a Godot-ready grid sprite sheet.

## Why this tool (decision #2)

Tier Simple (cozy / hand-drawn — farmer, Don't Starve, Animal Crossing) only needs soft-warp animation. AnimatedDrawings is free (MIT), fully auto-rig (no manual bones), and its soft-warp look fits soft cozy characters. Spine ($commercial, manual) and DragonBones (abandoned, community Godot runtime) over-engineer this tier. See `docs/research-rig-tool.md`.

## Pipeline

```
agy-image (single character PNG)
  → AnimatedDrawings (auto-rig + BVH retarget → animated GIF/MP4)
  → pack_spritesheet.py (this skill) → grid sprite sheet PNG + JSON sidecar
  → Godot 4 AnimatedSprite2D (consume in scene)
```

## Quick start

```bash
# 1. (in AnimatedDrawings) render a walk animation → walk.gif
# 2. pack frames into a sprite sheet + metadata
python3 skills/simple-rig/scripts/pack_spritesheet.py walk.gif --out assets/sprites/farmer_walk
# → assets/sprites/farmer_walk.png      (grid sprite sheet, RGBA)
# → assets/sprites/farmer_walk.json     ({frame_width, frame_height, columns, rows, frame_count, fps, source})
```

### Consume in Godot 4 (#4 scaffold)

`AnimatedSprite2D` plays a `SpriteFrames` resource. Build it from the JSON sidecar:

```gdscript
# frame_w/h, cols, rows, count, fps read from farmer_walk.json
var tex: Texture2D = load("res://assets/sprites/farmer_walk.png")
var atlas := AtlasTexture.new()
atlas.atlas = tex
atlas.region = Rect2(col * frame_w, row * frame_h, frame_w, frame_h)  # per frame
# add each AtlasTexture to SpriteFrames, set animation fps from JSON
```

## Scripts

| Script | Purpose |
|:--|:--|
| `scripts/pack_spritesheet.py` | AnimatedDrawings GIF/MP4 → grid sprite sheet PNG + JSON sidecar. |

## Requirements

- `python3` with **Pillow** (GIF input + packing).
- `ffmpeg` in `PATH` (for MP4/WebM/MOV input — GIF needs no ffmpeg).
- AnimatedDrawings installed (separate setup) to *produce* the input. The packing script itself only needs Pillow + ffmpeg.

## Notes & limits

- **Alpha:** GIF and WebM(VP9 alpha) preserve transparency. Plain MP4 (H.264) has no alpha channel — use GIF/WebM if you need a transparent background.
- **Custom motions:** AnimatedDrawings retargets BVH mocap. Default library has walk/jump/dance; sourcing custom cozy actions (watering, chopping) is open fog — test defaults first.
- **Non-uniform frames** are padded (centered on transparent max-canvas) so every cell is identical size — required for clean Godot slicing.
- This skill is **WIP**: the AnimatedDrawings drive step (image → rigged GIF) is not yet scripted here; only the packing/glue step is implemented.
