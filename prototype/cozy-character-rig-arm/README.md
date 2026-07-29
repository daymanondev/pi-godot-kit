# PROTOTYPE — rigid cut-out upper body (throwaway)

> Throwaway prototype that answers ONE design question. Not production.
> Built from `docs/research-artist-free-2d-skeletal-rig.md` (#13).

## Question

Does a **rigid cut-out upper body** (head + torso + 2 one-piece sleeved arms on
shoulder pivots) look acceptable on our chibi farmer **without any manual
painting**?

## Setup

- Parts: agy-generated 1×4 sheet → split (saturation-mask bg removal) →
  `parts/{head,torso,arm_l,arm_r}.png`.
- Rig (code, `scripts/rig.gd`): Node2D pivots, z-order overlap hide —
  arms **z=0** (behind torso), torso **z=1**, head **z=2** (hides neck cut).
- Test: right arm swept -60°→+110° (`rig_wave_demo.gif`), 90 frames captured.

## Verdict — YES, viable artist-free (7/10)

- **Shoulder joint: hidden across the whole sweep** (arm top sits behind torso).
  No gaps / exposed joints at any angle. Zero painting.
- **Neck: hidden** — head overlays the torso's neck cut in all frames.
- **Coherent character** — no floating/detached parts.

## The one flaw (and the known fix)

The arm **vanishes behind the torso** when it points inward/downward across the
front → looks one-armed at those angles.
**Fix = angle-based z-swap** (standard 2D cut-out technique): render the arm
**in front** of the torso when it points across the front half, **behind** when
it points back. Cheap, well-understood.

## Decision

Rigid cut-out upper body is the viable artist-free rig path. Next step for the
real build = **hybrid**: sprite-sheet 4-dir walk (lower body, done in map #6) +
rigid cut-out upper body (head/arms/tools) with angle-based z-swap. Take this
into the main flow at `/to-spec`.

## Run

```
godot --path prototype/cozy-character-rig-arm     # sweeps + captures to /tmp/rig_frames
```

(non-headless — headless uses the dummy renderer and viewport capture returns null.)
