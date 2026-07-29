# Research: 2D Skeletal Rigs vs Sprite Sheets for Small Chibi Characters

## Summary

An artist-free 2D skeletal rig is viable for small chibi characters if the design fundamentally avoids joint exposure through clothing (overalls, robes, long sleeves) or by using separated "floating" limbs. However, true vertex-deformed skeletal rigs (like Godot's Skeleton2D + Polygon2D) without artist weight-painting are prone to ugly overlaps and tearing, making "rigid cut-out" or hybrid approaches significantly more practical than continuous-mesh skinning.

## Findings

1. **Joint Hiding (Artist-Free Techniques)**
   - **Continuous Mesh/Deformation fails without manual weights:** Automatically binding a single character mesh to a skeleton in Godot creates tearing or "candy-wrapper" twisting at joints unless an artist carefully normalizes the vertex weights. [Source](https://github.com/godotengine/godot-proposals/issues/14110)
   - **Overlap by Design:** The most successful zero-artist approach is rigid cut-out animation where joints are intentionally hidden by clothing (e.g., long sleeves, gloves that overlap the forearm, or boots covering the knee). [Source](https://tahoma2d.readthedocs.io/en/latest/creating_cutout_animation.html)
   - **Overlap Margins:** Adding a 1-2 pixel inward margin on cut parts prevents gaps during rotation. [Source](https://www.haotianblog.com/en/linear-blend-skinning-2d-animation-en/)
   - **Rayman-style (Floating Limbs):** Using floating hands and feet with no visible arms/legs completely eliminates the need for joint management.

2. **What Real Games Use**
   - **Stardew Valley:** Pure sprite sheets. They use rigid grid layouts for cardinal directions and specific actions. No skeletal rigs are used. [Source](https://stardewmodding.wiki.gg/wiki/Sprite_Sheet:_NPC)
   - **Don't Starve:** Custom cut-out skeletal engine. Animators build symbols in Flash, which are exported as separate PNG body parts and reassembled via internal binary formats for skeletal-like sprite swapping at runtime. [Source](https://qastack.com.br/gamedev/44319/what-animation-technique-is-used-in-dont-starve)
   - **Core Keeper:** Skeletal and sprite hybrid system utilizing a custom animation conversion library to render into the engine. [Source](https://fixdlls.com/animation.converters.dll)
   - **Dave the Diver:** Hybrid 2D/3D approach. 2D sprites in a 3D environment using Unity URP, heavily relying on sprite animation rather than complex 2D bone deformation. [Source](https://80.lv/articles/dave-the-diver-developer-on-mixing-2d-3d-using-unity-urp)

3. **Godot 4 Skeleton2D Reality**
   - **No Auto-Weighting:** Godot 4 does not have heat-map binding or automated smooth weight generation for Polygon2D. It is highly manual. [Source](https://github.com/godotengine/godot-proposals/issues/14110)
   - **Zero-Weight Disappearance:** If you sync a Skeleton2D to a Polygon2D and it vanishes, it's because the default weights are 0. You must manually paint weights for it to render. [Source](https://github.com/godotengine/godot/issues/111436)
   - **Limitations for Artist-Free:** Due to the lack of auto-weights, doing smooth, single-mesh deformation (Skinning) without an artist is currently a non-starter in Godot. Rigid cut-outs (Sprite2D parented to Bone2D) are the only automated path.

4. **Auto-Rig / Part-Separation (Artist-Free)**
   - **Spine Animation AI:** Experimental ML workflows exist (like Spine Animation AI via Claude) that attempt to segment a single image into parts and build a skeleton JSON, but these are largely conceptual or require clean input. [Source](https://github.com/GenielabsOpenSource/spine-animation-ai)
   - **Charios & Proscenio:** Tools like Charios can import layered PNGs and output Godot scenes with AnimationPlayers. [Source](https://charios.com/blog/exporting-to-godot-from-a-2d-character-rig)
   - **Verdict:** True "single image -> auto-cut -> auto-rig" without human cleanup produces visible seams. The asset must be generated with separated layers (PSD/layered PNG) from the start.

5. **Hybrid Pattern**
   - **Sprite Walk + Rigged Upper Body:** This is a recognized and powerful pattern for top-down/isometric games. The lower body uses baked sprite sheets for complex perspective shifts (like a 4-directional walk cycle), while the upper body uses cut-out nodes or IK to aim tools, carry items, or wave independently of the leg animation. [Source](https://assetstore.unity.com/packages/tools/animation/anyportrait-2d-character-animation-111584)

## Sources

- Kept: [Stardew Valley Modding Wiki: NPC Sprite Sheet](https://stardewmodding.wiki.gg/wiki/Sprite_Sheet:_NPC) — Confirms pure sprite sheet usage in a leading genre title.
- Kept: [Godot Proposals #14110: Add Brush-based Weight Painting](https://github.com/godotengine/godot-proposals/issues/14110) — Proves Godot lacks the auto-weighting necessary for artist-free smooth skinning.
- Kept: [Godot GitHub Issue #111436: Polygon disappears](https://github.com/godotengine/godot/issues/111436) — Highlights a critical Godot 4 workflow gotcha for Polygon2D.
- Kept: [Don't Starve Animation Technique](https://qastack.com.br/gamedev/44319/what-animation-technique-is-used-in-dont-starve) — Details a highly successful cut-out approach.
- Dropped: Various Unity Asset Store links (e.g., Character Creator Modern 2D) — Not relevant to Godot implementation details.

## Gaps

- **Godot Auto-Rigger Scripts:** While scripts like `automatic-rigging` exist for Godot, their stability and visual quality on AI-generated chibi art is untested.
- **Top-Down Perspective Rigging:** Most cut-out tutorials focus on side-scrolling profiles. Hiding joints in a 3/4 top-down perspective (like Stardew) using only rigid cut-outs is significantly harder to automate.

## Verdict

**An artist-free rig is viable, but ONLY if we abandon continuous mesh deformation (Polygon2D/Skinning) and use a Rigid Cut-out approach (Sprite2Ds attached to Bone2Ds) combined with a clothing-hide design.**

Godot 4's lack of auto-weighting makes single-mesh deformation impossible without manual artist intervention. To scale for many actions without blowing up image-gen limits, the most promising prototype is a **Hybrid Pattern**: use generated sprite-sheets for the core 4-directional walk cycles (lower body), and a rigid cut-out rig for the upper body (head, arms, tools) where joints are hidden by sleeves or a "floating hands" (Rayman) style design.
