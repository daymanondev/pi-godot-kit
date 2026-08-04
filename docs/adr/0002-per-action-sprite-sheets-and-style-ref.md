# ADR 0002: Per-action sprite sheets + style-ref for cross-action consistency

- **Date:** 2026-07-30
- **Status:** Accepted
- **Relates:** ADR 0001 (records the rig abandonment that motivates this), #6 (the validated walk pipeline)

## Context

ADR 0001 abandoned the CozyCharacter overlay rig and named "extend the
sprite-sheet-per-action pipeline" as the new direction — but it only recorded
the *abandonment*, not the chosen approach. The open question is how to hold
**one consistent character across separate action sheets** (walk, idle, hoe-use,
…), now that each action is its own agy call and therefore subject to
**cross-call drift**. A second question is how tool-use (the hoe) is sourced,
given ADR 0001's lesson that compositing two renderings is a structural
fragility trap.

## Decision

**Generate each action as one coherent sprite sheet, and hold cross-action
consistency with a style-ref.**

1. **One agy call per action.** Each action is a single coherent 3×4 sheet
   (3 directions × 4 frames) produced by the LOCKED map-#6 master prompt.
   A single action cannot double, because it is one drawing.
2. **Style-ref for cross-action consistency.** The walk "stand" frame is passed
   as a file path inside every action's prompt — the technique that already
   scored 10/10 for the walk. Cross-call drift is managed by **re-roll to
   convergence** (regenerate → QC → repeat), not by compositing.
3. **Universal 3×4 grid; per-action variation lives in cycle-logic**, not the
   grid. Walk = `[stand, step, stand, mirror(step)]` (mirror trick); idle = 4
   breathing phases; hoe = 4 asymmetric swing phases (no mirror). agy reliably
   draws 3×4 (proven 10/10); 6 columns remains a documented smoother tunable.
4. **Tool-use is drawn coherently with the tool in every frame.** The hoe is
   part of the farmer drawing in all 12 cells. Prop-layer compositing (agy
   farmer + overlaid hoe) is **rejected** — it is the same fragility trap as the
   abandoned rig (ADR 0001). Hoe drift is managed like character drift:
   style-ref + re-roll + image-reader QC + live-demo eyeball.

## Considered options

- **One mega multi-action sheet** (rows = walk/idle/wave/hoe, single call) —
  zero cross-call drift, but an enormous prompt, no proof agy can hold an
  N×M grid with action semantics, and every new action regenerates the whole
  sheet. Rejected.
- **Per-action sheet + style-ref** ✅ — reuses the validated pipeline, keeps each
  action independently iterable, and cannot double. Chosen.
- **Procedural idle (reuse walk-stand + Godot bob)** — zero drift and zero cost,
  but it sidesteps the cross-call-drift test entirely (so hoe-use would become
  the gate, a dirtier probe). Kept as a **documented fallback for idle only** if
  agy-generated breathing boils unacceptably.

## Consequences

- **Cross-action drift is the central ongoing risk**, owned by the style-ref +
  re-roll loop, not by compositing.
- **The acceptance bar is the live demo, not static contact-sheet QC** — ADR
  0001's key lesson: the rig scored 9/10 on a static sheet yet still doubled in
  motion. Each action is eyeballed running in Godot before it is accepted.
- **Prerequisite:** the walk pipeline's split → bg-remove → mirror → align
  tooling was never committed (only its output frames exist). A reusable,
  parameterized pipeline tool (grid dims + cycle-logic as inputs) must be built
  and committed before/alongside the first new action.
- **Sequencing:** idle is the first new action and doubles as the drift-
  validation gate (the cheapest, cleanest probe — ≈ walk-stand). hoe-use is the
  highest-coherence-risk action (small prop, asymmetric swing) and is sequenced
  second, once the approach is proven.
- **Reversibility:** if cross-call drift proves unmanageable as the action set
  grows, the mega-sheet option (or, less likely, a re-attempt at rigging) can be
  revisited; ADR 0001 and #13 remain valid reference.
