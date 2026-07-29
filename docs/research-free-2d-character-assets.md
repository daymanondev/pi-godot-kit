# Research: Free 2D Character Assets & Tools for Godot 4 Cut-Out Animation

## Summary

The "free, pre-rigged, ready-to-restyle Godot Skeleton2D character" is largely a myth in the open ecosystem; most 2D assets are either pre-rendered frame-by-frame spritesheets or raw parts intended for proprietary tools like Spine. However, you can achieve a reskin-ready pipeline by downloading raw CC0/CC-BY sprite parts (e.g., Kenney's packs or Mana Seed) and rigging them yourself using the official Godot "GBot" template or a helper plugin like `godot-skeleton2d-helper`. Ultimately, while you cannot skip the initial rigging step using purely free assets, setting up a proper Skeleton2D rig once allows infinite texture swapping (restyling) for future characters.

## Findings

1. **Free cut-out rigged 2D character assets for Godot 4 are virtually non-existent.**
   OpenGameArt and itch.io are flooded with frame-by-frame spritesheets. Assets labeled "skeleton" or "cut-out" are either raw image folders (like Kenney's Toon Characters) or source files for external software like Spriter or Spine. There are no high-quality, free `.tscn` native Godot 4 Skeleton2D humanoid rigs with pre-made walk cycles available out of the box. [Source: Itch.io/OpenGameArt Search]
2. **Standard part structure & overlap.**
   A standard 2D humanoid rig consists of: Head, Torso, Upper Arm (L/R), Forearm (L/R), Hand (L/R), Thigh (L/R), Shin (L/R), Foot (L/R) (approx. 14-15 parts). Free assets usually ship as PNG folders or packed atlases. Crucially, pre-made parts *often do not* include painted hidden-overlap areas (the rounded joints that slide under other limbs). When restyling, you will likely need to paint these overlaps yourself to prevent gaps when joints rotate. [Source: Kenney Assets / Godot Docs]
3. **Open-source cut-out tools.**
   - **DragonBones:** The Daylily-Zeleen Godot-DragonBones GDExtension is actively maintained for Godot 4.2+ (v2.0.2 in 2024/2025). It requires a `.dbfactory` import process.
   - **OpenToonz / Synfig:** These offer powerful external cut-out workflows but do not export natively to Godot Skeleton2D format seamlessly; they render to spritesheets or use custom runtimes.
   - **Godot Skeleton2D Helper:** A very useful active Godot 4.3+ editor addon (`folt-a/godot-skeleton2d-helper`) that massively simplifies bone creation and Polygon2D vertex generation within Godot. [Source: folt-a/godot-skeleton2d-helper GitHub, Daylily-Zeleen/Godot-DragonBones GitHub]
4. **The Restyle / Reskin Strategy in Godot.**
   Texture swapping is a fully supported and documented workflow in Godot. By assigning `Polygon2D` or `Sprite2D` nodes to `Bone2D` bones, you can swap the `.texture` property at runtime. If the new art matches the dimensions and pivot points of the original, the skeleton and animations (walk cycle) remain perfectly intact. Because a free, high-quality, pre-rigged Godot template doesn't exist, you must build the "base rig" yourself using your art (or Kenney's), but once built, you can reskin it endlessly. [Source: Godot 2D Skeletons Documentation, Godot Forums]
5. **The best starting point.**
   The official Godot documentation provides a starter pack containing a "GBot" character with separated PNGs to learn the exact hierarchy. For actual game implementation, installing the `godot-skeleton2d-helper` plugin and rigging your own `agy` character art is the most efficient path.

## Sources

- **Kept: Godot Docs - 2D Skeletons** (<https://docs.godotengine.org/en/4.3/tutorials/animation/2d_skeletons.html>) — The official source of truth for rigging in Godot 4.
- **Kept: godot-skeleton2d-helper** (<https://github.com/folt-a/godot-skeleton2d-helper>) — Active Godot 4.3+ plugin that solves the biggest pain point (tedious Polygon2D creation).
- **Kept: Daylily-Zeleen/Godot-DragonBones** (<https://github.com/Daylily-Zeleen/Godot-DragonBones>) — Maintained GDExtension for DragonBones in Godot 4.
- **Kept: Kenney Toon Characters 1** (<https://kenney.nl/assets/toon-characters>) — CC0 example of how standard 2D parts are packaged (PNG folders without pre-made Godot rigs).
- **Dropped: Spine / Spriter assets** — Excluded due to project constraints (no paid tools/runtimes).

## Gaps

We do not have a pre-made, free `.tscn` file containing a fully rigged and animated humanoid that fits the "cozy farmer" vibe. The closest is the official Godot "GBot" tutorial asset, which is a robot.

## Recommendation

| Option | Effort | Quality | License | Godot-Fit |
| :--- | :--- | :--- | :--- | :--- |
| **(a) DIY rig of `agy` (Native Godot)** | High initially, Low later | Highest (perfect fit) | N/A (Own Art) | Native Skeleton2D |
| **(b) Restyle free rigged Godot asset** | N/A | N/A | N/A | **Does not exist** |
| **(c) DragonBones GDExtension** | Medium | High | MIT (Tool) | Requires plugin/external UI |

**Decision:** Go with **(a) DIY manual cut+rig** natively in Godot using your existing `agy` art. The "free pre-rigged restyle-able template" does not exist in the wild.

**Single Best Tool/Starting Point:** Install the [godot-skeleton2d-helper](https://github.com/folt-a/godot-skeleton2d-helper) plugin. It removes the worst part of native Godot rigging (manual Polygon2D vertex clicking) while keeping you strictly within native Godot 4 nodes (`Skeleton2D`, `Bone2D`, `Polygon2D`). Build the rig once for `agy`, animate it, and you'll have your own reskin-ready template forever.
