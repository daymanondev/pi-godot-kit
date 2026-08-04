# CONTEXT — pi-godot-kit (cozy character)

A single-context repo for building a cozy farming character in Godot 4 via
AI-generated sprite sheets. This file is a glossary only — no implementation
details, no specs. Architectural decisions live in `docs/adr/`.

## Language

**Action**:
A distinct character behavior animated as its own sprite sheet (e.g. walk, idle, wave, hoe-use). The atomic unit of one coherent agy generation — a single action can never double because it is one drawing.
_Avoid_: animation, state, move

**Sprite sheet**:
The grid image agy produces for one action — frames × directions, split into cells. The walk sheet is 3 rows × 4 columns.
_Avoid_: spritesheet, texture atlas, tile sheet

**Direction**:
One facing angle in a sheet. agy draws 3 unique directions consistently (3/4-front-right, straight-back, side-right); the rest are obtained by mirroring.
_Avoid_: facing, view

**Frame**:
A single cell of a sprite sheet; one pose.
_Avoid_: cell, pose (when referring to the image)

**Cycle**:
The ordered frame sequence that loops for one action×direction. Walk cycle = `[stand, step, stand, mirror(step)]`.
_Avoid_: loop, sequence

**Cycle-logic**:
The per-action meaning of a sheet's 4 columns — what each frame is and whether mirroring is applied. Walk = `[stand, step, stand, mirror(step)]`; idle = 4 breathing phases; hoe = 4 asymmetric swing phases (no mirror). One universal 3×4 grid, different cycle-logic per action.
_Avoid_: animation spec

**Style-ref (frame)**:
The canonical "stand" frame, passed as a file path inside every agy prompt, that keeps the character consistent across actions and across separate agy calls (cross-call drift control). Validated 10/10.
_Avoid_: reference frame, base frame, anchor

**Re-roll (to convergence)**:
Regenerate an agy sheet, QC it, repeat until it passes — the drift-management loop for both character and prop consistency.
_Avoid_: regenerate, retry, re-generate

**Prop drift**:
A small held object (e.g. hoe) varying or deforming across frames; the hardest agy-consistency risk, harder than whole-body drift.

**Doubling**:
The failure mode where two full-body renderings composite into a ghosted/stacked figure. Inherent to overlay rigs; impossible in a single coherent action sheet. (See ADR 0001.)
_Avoid_: ghosting, stacking (when naming the cause)

**Fragility trap**:
Compositing two renderings (overlay rig, prop layer) so doubling/ghosting becomes inherent and depends on an exact proportion/pose match across separate generations. Rejected by ADR 0001; avoided by generating each action as one coherent sheet.
