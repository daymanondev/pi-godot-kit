# Cozy Character Scaffold (prototype #4)

Throwaway prototype validating the Godot 4 end of the cozy pipeline:
`pack_spritesheet.py` output (#5) → `AnimatedSprite2D` + `CharacterBody2D`
input controller. Art is a **placeholder** blob, not real agy-image art.

## Run it (editor)

```bash
godot --path prototype/cozy-character           # open editor
godot --path prototype/cozy-character main.tscn # run immediately
```

Controls (registered at runtime by `scripts/input_setup.gd`):

- **A / ←** **D / →** — walk
- **Space / W / ↑** — jump

## Headless self-test (no GUI needed)

Builds the SpriteFrames from the JSON sidecars, then a scripted input sequence
presses move_right and jump and prints the character state at each step:

```bash
cd prototype/cozy-character
python3 tools/gen_placeholder.py     # (re)generate placeholder sheets
godot --headless --import            # import assets
godot --headless main.tscn           # run self-test, prints PASS, quits
```

## How the #5 → Godot glue works

`cozy_character.gd::_build_frames()` loads each `assets/sprites/farmer_*.json`,
reads `frame_width/height/columns/frame_count/fps`, slices the paired PNG into
`AtlasTexture` regions, and packs them into a `SpriteFrames` resource with two
animations (`idle`, `walk`). Replace the placeholder sheets with real
agy-image → AnimatedDrawings → pack output and the scaffold animates the real
character unchanged.

## Layout

```
prototype/cozy-character/
├── project.godot              # Godot 4.7 project (autoload InputSetup)
├── main.tscn / main.gd        # root: floor + character instance + self-test
├── scenes/cozy_character.tscn # CharacterBody2D + AnimatedSprite2D + camera
├── scripts/
│   ├── input_setup.gd         # autoload: registers move/jump input actions
│   └── cozy_character.gd      # gravity/move/jump + builds SpriteFrames from JSON
├── assets/sprites/            # gen_placeholder.py output (.gif .png .json)
└── tools/gen_placeholder.py   # throwaway blob-art generator
```
