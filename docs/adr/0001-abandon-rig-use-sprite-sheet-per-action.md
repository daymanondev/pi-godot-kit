# ADR 0001: Abandon the CozyCharacter rig — sprite-sheet-per-action instead

- **Date:** 2026-07-30
- **Status:** Accepted
- **Supersedes:** spec `docs/spec-rig-foundation.md` (#14)
- **Relates:** #14, #15, #16, #17, #18, #19 (all closed not-planned)

## Context

The Cozy Character Rig Foundation spec (#14) proposed a hybrid rig to avoid
per-action sprite-sheet generation: sprite-sheet walk for the lower body + a
rigid cut-out (head/torso/arms) for the upper body, composited in one drop-in
Godot scene. #15 shipped the mechanism (angle-based z-swap, 18/18 unit tests,
capture → contact-sheet → image-reader loop); #19 regenerated the cut-out parts
to match the walk sheet's art generation (the image-reader rated the **static**
overlay 9/10, up from a 2/10 "two overlapping characters" baseline).

## Decision

**Abandon the rig. Extend the proven sprite-sheet-per-action pipeline instead.**

Despite the static contact-sheet rating, the running demo still reads as two
stacked/doubled bodies. The root cause is **structural, not a tuning problem**:
the overlay composites two full-body renderings (the sheet's full body + the
cut-out upper body), so doubling/ghosting is inherent whenever the two don't
occlude perfectly — and they can't, because the sheet's front frames are posed
full-body drawings. Masking the sheet to legs-only (tried in #19) removes the
doubling but leaves a fragile, tightly-coupled composite that depends on exact
proportion/pose matching across separate generations.

The sprite-sheet-per-action approach (the map #6 pipeline, rated **10/10** for
the walk) generates each action as **one coherent drawing**, so it cannot
double. The cost #14 set out to avoid — regenerating a sheet per action — is
**accepted**: for a small action set, coherence and simplicity beat the
overlay's structural fragility, and the per-action generation limits (frame
consistency) are already managed by the existing pipeline.

## Consequences

- **Reverted** the rig implementation: commits `1684362` (#15 mechanism) and
  `0274cd7` (#19 parts). Both were unpushed; preserved in the reflog if ever
  needed for retrieval. `master` is back to the sprite-sheet (map #6) state.
- Closed #14, #15, #16, #17, #18, #19 as **not-planned**.
- The spec doc `docs/spec-rig-foundation.md` is **kept** as the record of the
  explored alternative (not deleted).
- **New direction:** agy-generate each action (idle variants, wave, tool-use, …)
  as a coherent sprite sheet via the map #6 pipeline; wire each into Godot as an
  `AnimatedSprite2D` animation.
- **Reversibility:** if per-action generation proves too costly at scale, the
  rig approach (and this ADR) can be revisited — the research (#13) and the
  arm-rig prototype findings remain valid reference.
