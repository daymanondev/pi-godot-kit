# Research: 2D Animation Cut-out vs Mesh-Warp

## Summary

Animating a single generated character image using mesh deformation (AnimatedDrawings) often results in a "rubbery" look for full-body locomotion because limbs stretch rather than pivot naturally. Separating the character into individual body parts and rigging them on a 2D skeletal hierarchy (cut-out animation) is the industry standard for smooth 2D game characters and prevents this stretching. For a solo dev using a generative tool like agy, the biggest bottleneck is obtaining clean, separated body parts, though Godot 4 supports native 2D cut-out animation out of the box using `Skeleton2D` with separate sprites attached to bones.

## Findings

1. **Technique Comparison: Mesh Warp vs Cut-out**
   - **Mesh Deformation (Single Image)**: Tools like Live2D or AnimatedDrawings apply a mesh to a single flat image and deform it to create movement. This is excellent for expressive facial movements (VTubing, visual novels) but causes "rubbery" artifacts when limbs need to cross over each other or swing widely (e.g., walking/running). [Source](https://www.saashub.com/compare-spine-vs-live2d-cubism)
   - **Cut-out / Skeletal 2D (Segmented Parts)**: Tools like Spine, DragonBones, or native Godot `Skeleton2D` use separate rigid or semi-rigid sprites (head, torso, upper arm, lower arm) parented to a bone hierarchy. This is the industry standard for 2D game locomotion (e.g., *Hollow Knight*, *Rayman Origins*) because it allows limbs to pivot cleanly on joints and layer dynamically via Z-indexing. [Source](https://www.armanimation.com/post/best-2d-skeletal-animation-software-in-2026-free-paid-options-compared)

2. **Godot 4 Native 2D Skeletal Animation**
   - Godot 4 natively supports 2D skeletal animation using `Skeleton2D` and `Bone2D` nodes. [Source](https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html)
   - **No Spritesheet Bake Required**: You do not need to bake animations to a sprite sheet or use `Polygon2D` mesh deformation. You can achieve pure rigid cut-out animation by parenting individual `Sprite2D` nodes directly to `Bone2D` nodes, or by using `RemoteTransform2D` to link a separate sprite hierarchy to the bone hierarchy. [Source](https://github.com/godotengine/godot-docs/issues/6388)
   - Godot 4 supports Inverse Kinematics (IK) via `SkeletonModificationStack2D`, which is vital for planting feet firmly during a walk cycle. [Source](https://docs.godotengine.org/en/stable/classes/class_skeleton2d.html)

3. **Obtaining Separate Body Parts from agy (Single Image)**
   - **AI Auto-segmentation**: Standard foundation models like SAM 2 excel at general segmentation but lack specific human-body semantic understanding. Meta's **Sapiens2** (specialized Vision Transformer) is highly capable of per-pixel body-part segmentation (28 body parts) and runs locally. [Source](https://huggingface.co/facebook/sapiens2-seg-1b)
   - **Prompting for a Parts-Sheet**: Prompting an image generator (agy/Midjourney/Gemini) to emit a clean, pre-disassembled character parts-sheet is highly unreliable. Generations often lack consistency, miss parts, or merge limbs.
   - **Manual Cut (Aseprite/Photoshop)**: The most reliable method for a solo dev. You manually cut the agy image, paint in the hidden overlapping areas (e.g., the shoulder behind the arm), and export the PNGs.

4. **Auto-Rigging Tools for Cut-out**
   - **Spine Animation AI**: An open-source Python pipeline that takes separated PNG body parts, uses SIFT/RANSAC to calculate bone positions/draw order, and automatically builds a Spine JSON skeleton with basic animation presets (idle, walk). [Source](https://github.com/genielabsopensource/spine-animation-ai)
   - Native Godot and Spine do not automatically rig separated images out-of-the-box; they require manual bone placement and weight painting/parenting.

5. **Cost, Licensing, and Integration**
   - **Godot 4 Native**: Free, open-source. No external integration required.
   - **DragonBones**: Free, but effectively abandoned by its original creators. A community-maintained GDExtension plugin for Godot 4 (by Daylily) exists and was updated in 2025. [Source](https://github.com/Daylily-Zeleen/Godot-DragonBones)
   - **Spine 2D**: The industry standard but requires a paid license (Essential $69 for rigid cut-out; Professional $329 for mesh/weights). To legally use the official `spine-godot` runtime in a distributed game, you must own a Spine Editor license. [Source](https://github.com/EsotericSoftware/spine-runtimes/blob/4.3/README.md)

## Recommendation

For a solo developer using a single generated agy image, targeting Godot 4, needing smooth locomotion, and operating on a tight effort/cost budget:

| Option | Smoothness | Effort | Cost | Godot Fit |
| :--- | :--- | :--- | :--- | :--- |
| **(a) Keep AnimatedDrawings** | Poor (Rubbery) | Very Low | Free | Baked Spritesheet |
| **(b) Manual Cut -> Native Godot Cut-out** | Excellent | High | Free | Native |
| **(c) Sapiens2 AI Cut -> Native Godot** | Good | Medium-High | Free | Native |
| **(d) Spine Animation AI -> Spine -> Godot** | Excellent | Medium | $69 (Spine Ess) | Native Runtime |

**Recommended Path**: **(b) Manual Cut -> Native Godot Cut-out**
Take the single agy image into an image editor, manually cut it into ~8-12 parts (head, torso, upper/lower arms, upper/lower legs), paint the hidden overlaps, and rig them directly onto a `Skeleton2D` using `Sprite2D` attachments in Godot.
*Reasoning*: It requires no paid licenses (Spine), avoids the maintenance risks of abandoned software (DragonBones), and bypasses the steep technical overhead/unreliability of setting up custom AI segmentation pipelines. While manual cutting takes time, it guarantees perfectly clean parts with painted-in overlaps, ensuring flawless pivots for a walk cycle. Godot's native `Skeleton2D` is more than capable of handling rigid sprite cut-outs.

**Second Choice**: **(c) AI Segmentation (Sapiens2) -> Native Godot**
If manual cutting is a total blocker, use Meta's Sapiens2 to generate the masks to slice the agy image into parts, then rig in Godot.
*Biggest Risk*: AI segmentation cannot paint the "hidden" areas behind limbs. When the rigged limbs rotate, hard, unpainted edges will be visible at the joints. You will likely have to do manual clean-up painting anyway.

## Gaps

- **Hidden Overlap Inpainting**: If using AI to segment the body parts (Sapiens2), the AI does not inherently fill in the background pixels behind the limb (e.g., completing the torso behind the arm). A secondary generative inpainting step would be required to make the parts viable for rotation.
- **Workflow automation**: Moving from a manually cut PSD to an assembled Godot `Skeleton2D` requires manual bone placement. Further research into Godot importer scripts (e.g., importing a PSD directly into a `Skeleton2D` node tree) could reduce this friction.
