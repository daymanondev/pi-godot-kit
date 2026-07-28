# Asset Complexity Scoping — tooling theo độ phức tạp character (July 2026)

## 💡 Insight chiến lược

**Độ phức tạp character là cost driver lớn nhất của asset pipeline.** Chọn character nhỏ / hand-drawn (style cozy/indie, Don't Starve / Animal Crossing / Stardew aesthetic) là quyết định chiến lược khiến toàn bộ pipeline **feasible trên free tools + agy quota** — không cần ML decomposition (See-Through), không cần 3D, không cần Spine phức tạp.

Style cụ thể (sáng/tối/watercolor/pixel) là **per-game dial-in** qua prompt agy-image — không lock sớm. agy-image handle mọi style.

## 📊 Complexity → tooling matrix

| Tier | Ví dụ | Generate | Rig/Animate | Effort |
| :--- | :--- | :--- | :--- | :--- |
| **Simple** (nhỏ, hand-drawn, cozy) | farmer A/B, char Don't Starve, Animal Crossing | agy-image ✅ | flat-rig (metademolab) hoặc Spine đơn giản | **THẤP — xong** |
| **Medium** (vài layer/phụ kiện) | char có cape, vũ khí tách riêng | agy-image | See-Through decomp → Stretchy/Spine layer rig | TRUNG BÌNH — semi-manual |
| **Complex** (giáp, realistic, nhiều rigid part) | knight lúc nãy | agy-image hoặc 3D model | 3D pipeline (image→3D→Mixamo) HOẶC Spine manual nặng | CAO |

## 🎯 Hệ quả cho game-skills pipeline

- **Game cozy/indie 2D (target user) = Tier Simple**: agy-image + flat-rig/Spine-đơn-giản **ĐỦ**. Không cần Stretchy/See-Through/3D.
- Toàn bộ research nặng (See-Through, Stretchy, 3D pipeline) **chỉ relevant** nếu game cần character Tier Medium/Complex.
- → `game-skills` repo cho game cozy **lean**: skill `agy-image` (đã prove) + 1 skill `simple-rig` (flat-rig hoặc Spine skeleton cơ bản) + asset list. Bỏ qua phase ML-decomp/3D.

## ✅ Validated

- agy-image gen cozy character sạch, đáng tin (farmer A chibi flat + farmer B watercolor storybook — image-reader verify cả 2 clean, đúng vibe).
- Character nhỏ/đơn giản → rig distortion cực thấp (soft-warp metademolab trông **cute**, không "hỏng" như knight giáp).

## 🔗 Liên kết

- Chi tiết animation tool & soft-warp vs skeletal: `ANIMATION_TOOL_FINDINGS.md`
- Design repo game-skills: `GAME_SKILLS_REPO_DESIGN.md`
- Loop generate→look→refine (prove): `OPTIMAL_ASSET_LOOP_ARCHITECTURE.md` + `README.md` §PoC
