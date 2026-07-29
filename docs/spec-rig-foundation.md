# Spec: Cozy Character Rig Foundation (hybrid sheet-walk + rigid cut-out upper body)

## Problem Statement

As a solo dev who cannot paint or edit art, I have a playable chibi farmer that
walks in 4 directions via sprite-sheets (map #6). But sprite-sheets do not scale
to a character that **does many actions** — farming, picking up, waving, idling.
Each new action means generating a fresh sheet and re-fighting the image-gen
limits we already hit (frame consistency, distinct strides, side-walk). I need a
reusable **rig** so one set of character parts can perform unlimited actions
without an artist.

## Solution

A reusable Godot character rig that combines two proven, artist-free techniques:

- **Lower body**: the existing 4-direction sprite-sheet walk (keeps the quality
  already validated in map #6).
- **Upper body**: a **rigid cut-out** (head + two one-piece sleeved arms on
  shoulder pivots + a tool attachment point), with joints hidden by z-order
  overlap (arms behind torso hide the shoulder; head in front hides the neck).

Joints stay hidden without any painting (validated by the arm-rig prototype,
7/10 → fixable to 9-10 with angle-based z-swap). The rig exposes a small set of
**actions** (idle, walk, wave, tool-swing) so game code can trigger them, and it
is one scene that drops into any level.

## User Stories

1. As a solo dev, I want a reusable character rig, so that I can animate many actions without regenerating sprite sheets for each one.
2. As a solo dev, I want the rig to walk in 4 directions, so that movement matches the existing playable feel.
3. As a solo dev, I want the rig to wave with one arm, so that I can verify upper-body articulation works artist-free.
4. As a solo dev, I want the rig to swing a tool (hoe), so that a farming action is possible.
5. As a solo dev, I want the rig to idle (subtle motion) when standing, so that the character looks alive.
6. As a player, I want the character's arms to never vanish behind the torso, so that it never looks one-armed.
7. As a solo dev, I want joints hidden without painting, so that the pipeline stays artist-free.
8. As a solo dev, I want the arm z-order to swap automatically by angle, so that I never manually layer arms per frame.
9. As a solo dev, I want walk to keep using the proven sprite-sheet, so that multi-direction walk quality is preserved.
10. As a solo dev, I want the upper body to face front when performing an action, so that the front-facing cut-out parts always look correct.
11. As a game dev, I want to select an action from code (idle/walk/wave/tool), so that gameplay can trigger animations.
12. As a solo dev, I want the rig to reuse the existing chibi farmer art, so that visual consistency with the walk holds.
13. As a level builder, I want the rig to be a single drop-in scene, so that I can place the character anywhere.
14. As a game dev, I want a tool attachment point on the rig, so that different tools could plug in later without rework.
15. As a solo dev, I want to visually verify that no joints ever show, so that I trust the artist-free claim across all actions.
16. As a player, I want arms to swing during walk, so that walking reads as walking (legs + arms together).
17. As a solo dev, I want the rig documented, so that I can extend it (more actions, more directions) later.
18. As a player, I want idle and walk to transition smoothly, so that starting/stopping looks natural.

## Implementation Decisions

- **Module — CozyCharacter rig scene.** One Godot scene composed of a lower-body
  `AnimatedSprite2D` (the 4-dir walk frames from map #6) and an upper-body
  rigid cut-out: head sprite + two arm `Node2D` pivots at the shoulders + a tool
  `Sprite2D` attachment point. The rig is the single drop-in unit.
- **Joint-hide by z-order overlap (no painting).** Arms render behind the torso
  (shoulder hidden); head renders in front of the torso (neck cut hidden). This
  is the artist-free technique validated by the prototype.
- **Angle-based z-swap (the key mechanism).** A pure function decides each arm's
  z-order from its rotation angle: when the arm points across the **front** half
  of the body it renders **in front** of the torso; when it points to the
  **back** half it renders **behind**. This eliminates the "arm vanishes behind
  torso" flaw found in the prototype. Decision-encoded snippet from the
  prototype finding:

  ```
  # arm angle convention: 0° = hanging straight down; + = swinging out/front
  # front half (visible across body) -> in front of torso (z = 2)
  # back half (pointing away/behind) -> behind torso (z = 0)
  func arm_z_index(angle_deg: float, facing_front: bool) -> int:
      return 2 if angle_in_front_half(angle_deg) else 0
  ```

- **Actions = pose presets.** Each action is a set of upper-body values (arm
  angles, tool visibility, head bob) plus a lower-body choice (walk anim vs.
  stand frame). `idle` = arms at rest + stand frame + subtle sway; `walk` = arms
  swinging opposite-phase + walk anim; `wave` = one arm raised and oscillating +
  stand frame; `tool` = both arms hold the hoe and swing it + stand frame.
- **Direction handling (MVP).** The cut-out upper body is **front-facing only**.
  During walk, the lower-body sheet carries direction. When an action triggers,
  the character faces front (the direction in which the front-view cut-out parts
  are correct). Multi-direction cut-out is explicitly a follow-up.
- **Parts pipeline (reuse).** Parts come from an agy 1×4 parts sheet (head,
  torso, arm-L, arm-R), split with the saturation-mask background removal and
  size-normalization already proven in map #6 and the prototype. Long sleeves on
  the shirt are part of the design (they justify one-piece arms with no elbow
  joint).
- **Artist-free constraint preserved.** No manual painting, no mesh/skinning
  weight-painting (research #13 ruled Polygon2D skinning artist-gated). Only
  rigid Sprite2D-on-pivot cut-outs.

## Testing Decisions

- **What makes a good test here:** assert external behaviour only, never
  implementation details. Two seams:
  1. **Z-swap logic (pure function, unit-testable).** `arm_z_index(angle)` and
     `angle_in_front_half(angle)` are pure — test them at the boundary: arm
     hanging down and swinging slightly across the front → front; arm swung
     behind the body plane → behind; the threshold angle flips the result once.
     This is the first GDScript unit test in the repo and the cleanest code
     seam; it should live next to the rig logic.
  2. **Visual behaviour (image-reader, the established seam).** Capture the rig
     in each action (idle, walk, wave, tool-swing) and across the full arm-angle
     range, then have the vision agent verify: shoulder joint always hidden, arm
     never fully vanishes, neck hidden, coherent single character, same chibi
     farmer as the walk. Prior art: the map #6 walk verification
     (`cozy_multidir` capture → contact sheet → image-reader) is the pattern to
     reuse.
- **Not tested:** internal node layout names, exact pixel offsets (those are
  visual, covered by the image-reader seam).

## Out of Scope

- **Multi-direction cut-out upper body** (4 sets of parts or a neutral 3/4
  approach). Research #13 flagged 3/4 cut-out as hard to automate; the prototype
  proved front only. Follow-up ticket.
- **Mesh / skinning deformation** (Polygon2D vertex weights, Skeleton2D
  skinning). Research ruled this artist-gated.
- **Character roster** (NPCs, merchant, etc.). Template reuse is a later map.
- **Tool variety / inventory.** One tool (hoe) for the swing demo; the
  attachment point is built so more can plug in later.
- **Elbow joints.** Arms are one-piece (sleeve hides where an elbow would be);
  articulated elbows are a later refinement if needed.

## Further Notes

- Builds directly on: map #6 (sheet-walk playable), research #13 (rigid cut-out
  only, hybrid is the path), and the arm-rig prototype (front cut-out viable
  artist-free, z-swap is the fix).
- The rig is the **foundation**: once it exists, adding actions is cheap (a new
  pose preset), which is the whole point of choosing a rig over per-action
  sheets.
- Next main-flow step after this spec: `/to-tickets` splits it into
  tracer-bullet tickets worked blockers-first.
