# Character Sprite Pipeline (agy → multi-direction walk → Godot)

**Status: LOCKED + validated (vision QC 10/10).**

## Approach

2D chibi character animation via **sprite-sheet walk cycles** — how Stardew
Valley and Don't Starve Together actually do it. Generate a multi-frame,
multi-direction sheet in **one agy call** → split → mirror → `AnimatedSprite2D`
in Godot. **No rigging, no joints, no mesh deformation, no manual painting.**

## Why this (not the alternatives we tried)

| Approach | Verdict |
|---|---|
| AnimatedDrawings (mesh-warp 1 image) | rubbery / uncanny |
| Cut-out (separate parts + Skeleton2D) | grotesque poking joints; needs an artist to paint overlaps |
| Squash-stretch (single sprite) | clean but NO articulated walk (just bounces) |
| **Sprite-sheet walk cycle** ✅ | clean + articulated + artist-free |

## Standardized master prompt (reusable — swap `{{character}}`)

```
A character walk-cycle sprite sheet as a clean GRID of 3 rows by 4 columns
(12 cells) with thin black gridlines separating cells. All 12 cells show the
EXACT SAME {{character}} — identical proportions, colors, clean cel-shaded
vector style, warm palette, NOT pixelated.

Within each row ALL 4 frames share the EXACT SAME body angle — the body and
head never rotate between frames, ONLY the arms and legs move into stride
positions.

ROW 1 (TOP): a consistent 3/4 FRONT-RIGHT view (body angled ~30°, facing
toward viewer and right) for ALL 4 frames, INCLUDING standing — the standing
pose is also at this same 3/4 front-right angle, NOT straight-on. 4-frame
walk: stand, step, stand, step.
ROW 2 (MIDDLE): a consistent straight-on BACK view (facing away) for all 4 frames.
ROW 3 (BOTTOM): a consistent side PROFILE facing right for all 4 frames,
arms swinging opposite legs.

Super-deformed chibi, big round head ~40% of height, short stubby limbs.
Solid white background, each cell a centered complete full-body drawing.
```

`{{character}}` example: *"chibi farmer (straw hat with brown ribbon, red
long-sleeve shirt, blue overalls with front pocket and yellow buttons, brown boots)"*.

## Multi-direction optimization (DST-style angled view)

- **3 UNIQUE directions** (the ones agy draws consistently): **3/4-front-right,
  straight-back, side-right**.
  - Key insight: agy draws walk-forward at 3/4 even when asked for straight-on →
    the straight-front row "pops" between standing (straight) and walking (3/4).
    **Embrace 3/4** for the front row → no pop.
- **Mirror to expand to 4–6 directions** (free, no extra generation):
  - `side-left` = flip(`side-right`)
  - `3/4-front-left` = flip(`3/4-front-right`)
  - (back is usually near-symmetric)
- **One agy call = 12 cells** → character is consistent across every direction
  and frame (no cross-call drift).

## Processing pipeline (split → mirror → align)

1. agy generate the 3×4 sheet (master prompt).
2. Split into 12 cells (even 4-col × 3-row division, ~8px inset to skip gridlines).
3. bg-remove each cell (flood-fill from borders through near-white).
4. Per direction, build the 4-frame cycle: `[stand, step, stand, mirror(step)]`.
   - agy outputs cols 2 & 4 as duplicates (same leg) → mirroring col 2 creates
     the opposite-leg step → proper alternating walk.
5. Align frames (upper-body centroid x + feet-bottom y) so the character
   doesn't jitter between frames.
6. → frames per direction → Godot.

## Godot integration

- `AnimatedSprite2D` + `SpriteFrames`: one animation per direction
  (`walk_front`, `walk_back`, `walk_side`); use `flip_h = true` for the left
  variants.
- The scaffold's `CharacterBody2D` + input controller (#4) selects the
  animation from `velocity` direction.

## Validated results (vision QC via image-reader)

- Character consistent across all 12 cells ✓
- Legs alternate (frame 2 vs 4 opposite legs, via mirror) ✓
- Angle consistent within each row (no pop) ✓
- 3 distinct directions ✓
- Rating: **10/10** — "fully ready for sliced sprite-sheet animation."

## Known limits / tunables

- agy draws walk-forward at 3/4 (embraced; do not fight it).
- Minor frame-to-frame detail "boiling" (agy variance) — subtle at speed.
- For smoother walks, request **6 columns** instead of 4 (more stride frames).

## Assets

- Master sheet: `prototype/cozy-character-real/farmer_multidir/multidir_v3.jpg`
- Frames: `prototype/cozy-character-real/farmer_multidir/frames/`
- Walk GIFs: `walk_front_3q.gif`, `walk_back.gif`, `walk_side_right.gif`, `walk_all_dirs.gif`
