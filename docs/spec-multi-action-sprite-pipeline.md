# Spec: Multi-action sprite-sheet pipeline (idle + hoe-use)

> Published as GitHub issue (label `ready-for-agent`). Source of truth = the
> issue; this doc is the repo record. Required reading: ADR 0001 (why the rig
> was abandoned), ADR 0002 (the chosen per-action + style-ref direction).

## Problem Statement

The cozy character can walk in four directions but has no real idle animation
(it freezes on the walk stand frame) and no tool-use action. To feel alive and
to support the core farming loop, the character needs more **actions** — but
each new action must stay visually consistent with the existing walk character,
without re-introducing the compositing/doubling fragility that killed the rig
(ADR 0001).

## Solution

Extend the validated **sprite-sheet-per-action** pipeline (ADR 0002) to two new
actions — **idle** and **hoe-use** — each generated as one coherent sprite sheet
via agy, with cross-action character consistency held by a **style-ref** +
**re-roll** loop. Build the reusable pipeline tooling (split → bg-remove →
mirror → align → cycle) that was never committed, parameterized by grid dims
and **cycle-logic**. Wire the new animations into the top-down controller so
idle plays a breathing loop and hoe-use plays on an action key.

## User Stories

1. As a player, I want the character to breathe subtly when standing still, so it looks alive rather than frozen.
2. As a player, I want the idle to face the last-moved direction, so it matches my movement in a top-down world.
3. As a player, I want the character to swing a hoe when I press an action key, so I can till soil (the core farm action).
4. As a player, I want the hoe swing to face my current direction, so the action reads correctly from any angle.
5. As a player, I want the character to look like the SAME character across walk, idle, and hoe-use, so it doesn't read as a different person each action.
6. As a player, I want the hoe to look like the same hoe in every swing frame, so the tool doesn't morph mid-swing (prop drift).
7. As a dev, I want a single reusable pipeline tool that turns any agy 3×4 sheet into per-direction frame cycles, so adding an action doesn't require hand-rolling image code each time.
8. As a dev, I want the pipeline tool to accept a cycle-logic per action (mirror vs no-mirror), so walk, idle, and hoe-use share one grid shape but differ correctly in frame assembly.
9. As a dev, I want automated tests on the pipeline's split/cycle logic, so I can refactor the tool without breaking frame output.
10. As a dev, I want automated headless tests on the controller's animation selection, so I can wire new animations without regressing walk/idle/hoe selection.
11. As a dev, I want each action verified against the running demo, so I catch in-motion doubling/drift that static sheets hide (ADR 0001 lesson).
12. As a dev, I want the walk "stand" frame reusable as a style-ref in every agy prompt, so new actions match the existing character without a mega-sheet.
13. As a player, I want the character to return to idle (not freeze) after a hoe swing completes, so transitions feel natural.
14. As a player, I want walk to take over sensibly from idle and back, so movement feels responsive.

## Implementation Decisions

- **One agy call per action**; each action is one coherent 3×4 sheet (3 directions × 4 frames). (ADR 0002.)
- **Cross-action consistency via style-ref**: the walk "stand" frame is passed as a file path inside every action's agy prompt; drift is managed by **re-roll to convergence**, never by compositing.
- **Universal 3×4 grid; per-action variation in cycle-logic only**: walk = `[stand, step, stand, mirror(step)]`; idle = 4 breathing phases; hoe = 4 asymmetric swing phases (no mirror).
- **Idle** = a real agy breathing sheet. Procedural bob on the walk stand frame is a documented fallback only if agy boiling proves unacceptable.
- **Hoe-use** = agy draws farmer+hoe coherently in every frame. Prop-layer compositing (farmer-only sheet + overlaid hoe) is **explicitly rejected** — it is the fragility trap of ADR 0001. Hoe drift is managed like character drift: style-ref + re-roll + QC.
- **Build a reusable Python pipeline tool** (pure Pillow) parameterized by grid dims (rows×cols) and a cycle-logic spec, producing per-direction frame sequences with optional mirroring and alignment. The walk frames were produced ad-hoc; the tool was never committed — it is a prerequisite to the first new action.
- **Extend the top-down controller** (the multidir controller the play scene currently uses) to: play a real idle animation per direction when velocity≈0 (replacing the current freeze-on-stand); play a hoe animation per direction on an action-key input, then return to idle/walk.
- The 3 unique directions (3/4-front-right, straight-back, side-right) + mirroring remain the direction strategy; idle and hoe reuse the same direction set.
- agy forces 1:1 (1024²) regardless of prompt; state size in the prompt and expect variance.

## Testing Decisions

- **What makes a good test here:** assert external behaviour (frame sequences, animation selection by state), never implementation details. Perceptual qualities (coherence, drift, no doubling) are **not** unit-tested — they are verified by the vision QC + live-demo eyeball, because they are inherently perceptual judgements (ADR 0001's key lesson).
- **Seam 1 — pipeline tool (Python, pure-function):** given a synthetic 3×4 grid + a cycle-logic spec, assert split cell count/dims and that the assembled cycle (including mirroring) matches the expected frame sequence. No prior art in-repo yet (first Python tests); pattern = plain runnable asserts.
- **Seam 2 — controller (GDScript, headless):** extend the existing `--demo`/`--capture` headless seam — assert SpriteFrames contains `walk_*`/`idle_*`/`hoe_*` and the controller selects idle (breathing) when velocity≈0, walk when moving, hoe on the action key. Prior art: the scaffold's headless selftest.
- **Visual QC loop (per action, perceptual):** agy generate → pipeline split → contact sheet → image-reader rating → wire into Godot → eyeball the running demo → re-roll if doubling/drift. **The live demo is the acceptance bar** (ADR 0001).

## Out of Scope

- Wave, watering-can, harvest, pickup, and any action beyond idle + hoe-use (deferred; this spec proves the approach on two actions).
- A multi-tool swap layer (one body pose reused across hoe/watering-can/axe) — a future compositing question to re-evaluate against the fragility lesson; explicitly not now.
- A mega multi-action sheet (rejected; see ADR 0002 considered options).
- 6-column smoother sheets (documented tunable; not needed for MVP).
- Re-attempting the rig (abandoned, ADR 0001).
- Closing the stale rig issues #14–#19 (separate housekeeping; the token lacks close permission).

## Further Notes

- ADR 0001 records why the rig was abandoned; ADR 0002 records the chosen per-action + style-ref direction. Both are required reading.
- The walk pipeline's split/mirror/align tooling was never committed — only its 12 output frames exist. Building the reusable tool is a prerequisite to the first new action.
- agy cross-call drift is the central ongoing risk; idle is sequenced first partly because it is the cleanest drift probe (pose ≈ walk stand).
- image-reader subagent (vision via Gemini) is the QC seam; it may need `npm install undici` in the pi-coding-agent global node_modules if it crashes (known issue).
- Pure Pillow only — no numpy / scipy / rembg / imagemagick available.
