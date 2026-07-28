# Research: Tier Simple 2D Character Rig Tools

## Summary

For the Tier Simple cozy pipeline, Meta AnimatedDrawings is the strongly recommended tool. It offers a fully automated, free workflow that natively complements `agy-image`, and its soft-warp animation suits a soft, hand-drawn aesthetic while bypassing the manual labor and licensing constraints of traditional skeletal tools.

## Comparison Table

| Tool | Cost / License | Godot 4 Support | Export Format | Rig Workflow | Animation Quality | Maintenance (2026) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Meta AnimatedDrawings** | Free, MIT license | N/A (Use standard sprite nodes) | GIF, MP4, GLTF | Auto-rig (1 image → joints) | Soft-warp (Cozy / Toy Tier) | Maintained (Open Source) |
| **Spine** | Paid ($69-$379+) | Official (`spine-godot`) | Spine JSON/Binary | Manual bone setup | Rigid / Skeletal (Prod Tier)| Highly Active |
| **DragonBones** | Free, Open Source | Community only | DragonBones JSON | Manual bone setup | Rigid / Skeletal (Prod Tier)| Effectively Abandoned |

## Findings

1. **MetaDemoLab AnimatedDrawings** — The open-source repository is MIT licensed, allowing commercial use. It auto-detects joints from a single image and produces soft-warp animation. While "toy tier" for rigid assets, this rubbery look is acceptable for soft cozy characters. It can export GLTF or transparent GIFs which can be converted to sprite sheets for native Godot 4 `AnimatedSprite2D`. [Source: Meta FAIR GitHub](https://github.com/facebookresearch/AnimatedDrawings)
2. **Spine (Esoteric Software)** — It costs $69 (Essential) to $379 (Professional) for perpetual licenses, with an Enterprise tier for large studios. It requires manual bone setup. It has excellent official Godot 4 GDExtension support (`spine-godot`), but the manual workflow and paid license violate the simple/low-barrier goals of Tier Simple. [Source: Spine Purchase](https://esotericsoftware.com/spine-purchase)
3. **DragonBones** — While DragonBones is open-source (free) and provides similar skeletal rigging to Spine, it still requires manual bone placement and the core editor is largely abandoned. Godot 4 support relies on community GDExtensions (like `Daylily-Zeleen/Godot-DragonBones`), which introduces long-term maintenance risks. [Source: Godot-DragonBones](https://github.com/Daylily-Zeleen/Godot-DragonBones)

## Sources

- Kept: [Meta FAIR AnimatedDrawings GitHub](https://github.com/facebookresearch/AnimatedDrawings) — Confirms MIT license, export formats, and automated workflow.
- Kept: [Spine Store](https://esotericsoftware.com/spine-purchase) — Confirms pricing and license restrictions.
- Kept: [Spine-Godot Runtime Docs](https://esotericsoftware.com/spine-godot) — Confirms official Godot 4 support.
- Kept: [Godot-DragonBones GitHub](https://github.com/Daylily-Zeleen/Godot-DragonBones) — Confirms Godot 4 support is community-driven and the ecosystem is mostly sustained by volunteers rather than active official development.
- Dropped: SEO-heavy listicles on "Top 2D animation tools" — Too generic and lack specific Godot 4 integration context.

## Recommendation

**Meta AnimatedDrawings** is the best fit for Tier Simple.
It integrates seamlessly after `agy-image`, requires zero manual bone placement, and is completely free. By processing its outputs into traditional sprite sheets, the game can use Godot's built-in `AnimatedSprite2D`. This entirely avoids the overhead of integrating and compiling GDExtension runtimes (which are required by Spine and DragonBones) and keeps the engine footprint minimal.

## Open Questions / Risks

- **Custom Animations**: AnimatedDrawings relies on retargeting BVH motion capture files. It is not entirely clear how easy it is to source or generate custom cozy actions (e.g., watering plants, chopping wood) as BVH files versus relying on its default motion library. *Risk Mitigation: Test injecting a custom BVH into the AnimatedDrawings pipeline early.*
- **Pipeline Glue**: A script will be needed to automatically convert the transparent GIF/MP4 outputs into optimized sprite sheets for Godot, as direct import of its outputs might not be optimal for game memory. *Risk Mitigation: Prototype a Python script to slice/pack the frames.*
