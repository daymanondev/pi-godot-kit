# 2D Animation Tool Findings — "1 ảnh → nhân vật cử động" (July 2026)

## 🎯 Câu hỏi gốc

Pipeline tạo asset game có thể tự động hóa bước "1 ảnh phẳng → nhân vật rigged + cử động" bằng agent (headless) được không?

## ❌ Kết luận: KHÔNG có tool nào sạch + headless + agent-drive được trong 2026

| Tool | Trạng thái | Headless/agent-drive? | Verdict |
| :--- | :--- | :--- | :--- |
| **Meta AnimatedDrawings** | 🗄️ **Archived 9/3/2025**, không maintain | ✅ CÓ CLI thật (`image_to_animation.py img out → video.gif`) | ⛔ **Install HELL trên Mac M4** — proven 4 lần fail (numpy chicken-egg, xtcocoapi C++ build fail, torch 1.13 timeout, mmcv-full 1.7.0 chưa thử vì chưa qua nổi phase 1). Stack 2022 (py3.8, torch 1.13, mmcv-full 1.7.0) break trên môi trường 2026. |
| **Stretchy Studio** (MangoLion) | ✅ OSS, maintain, Spine 4.0 export | ❌ **GUI web editor only** (React/Vite, `pnpm dev`). "No CLI for headless auto-rigging or export." Cần input = layered PSD từ model See-Through, không phải ảnh phẳng. | Tool hay nhưng **không agent-drive** trừ browser-automation. |
| **sketch.metademolab.com** (Meta hosted) | ✅ Free, **vẫn chạy 2026** | ❌ GUI web (drag-drop, wizard) | Nhanh nhất prove capability, nhưng GUI. |
| **Charios** | ✅ | ❌ GUI browser-native | Giống Stretchy. |
| **ComfyUI 2D character pipeline** (mor-o) | ✅ OSS | ✅ **ComfyUI-API drivable** (headless được) | Lựa chọn MỚI duy nhất headless — nhưng setup nặng: cần ComfyUI + model See-Through + DWPose. Chưa test. |

## 🔑 Phát hiện kiến trúc (quan trọng cho game-skills repo)

**Bước "rig + animate 1 ảnh" KHÔNG có tool headless sạch trong 2026.** Pipeline agent phải chọn 1 trong 3 pattern:

1. **Browser-automation của GUI tool** (metademolab / Stretchy) — Pi dùng cmux-browser skill drive GUI. Hợp lệ, nhưng fiddly (file upload dialog, wait, multi-step wizard).
2. **ComfyUI 2D pipeline** — headless thật, fit stack agy/ComfyUI, nhưng setup nặng (chưa validate).
3. **Chấp nhận semi-manual** — agent generate sprite (agy-image, đã prove), human rig/animate trong Stretchy/Spine, export .json vào Godot.

→ **Khuyến nghị tạm**: để bước rig/animate ở Lớp "semi-manual + browser-auto", KHÔNG cố fully-automate như bước generate (đã prove). Ưu tiên ComfyUI 2D pipeline nếu muốn headless full.

## 🧪 Bằng chứng install hell (Meta AnimatedDrawings trên Mac M4, 2026-07)

Thử native install (uv venv py3.8 + pip pin theo setup_macos.sh):

- ❌ uv resolver strict → reject (xtcocoapi không trên PyPI).
- ❌ pip lenient nhưng `xtcocotools` C++ build fail (cần numpy trước — chicken-egg).
- ❌ staged install (numpy→cython→setuptools trước): xtcocoapi còn fail do stale `.egg` artifact; torch 1.13 + deps timeout 600s.
- ⛔ Chưa tới được `mim install mmcv-full==1.7.0` (risk point lớn nhất, issue #210) vì phase 1 chưa qua.

Khớp với GitHub issues #210 (mmpose install fail M1), #240 (mmcv-full build fail), #310 (torchserve treo).

## 💡 Fastest "see it move" payoff (nếu user muốn xem ngay)

`https://sketch.metademolab.com` → upload `knight-v2.jpg` → mask → joints → pick motion (dab/dance/jump) → download gif. ~2 phút, free, guaranteed work. (Manual, không agent — nhưng prove capability trên asset thật của mình.)

## 🧬 Bằng chứng thực tế (user test, 2026-07)

**User chạy knight-v2 qua metademolab → animation CHẠY được NHƯNG cape + sword bị MÉO khi cử động.**

**Root cause:** flat-rig tool (metademolab & mọi tool "1 ảnh phẳng → rig") xử lý toàn bộ ảnh như **1 mesh deformable duy nhất**. Xương cử động → mesh quanh đó warp theo → phụ kiện (cape = vải bay, sword = vật ríg) bị kéo méo vì dán vào mesh thân, KHÔNG có layer riêng.

**Fix = layered decomposition**: tách character thành layer (thân / cape / sword / tay trước-sau), rig từng layer độc lập. ĐÓ là lý do pipeline **See-Through → Stretchy Studio** tồn tại:

- See-Through: 1 ảnh → layered PSD inpainted (mỗi body-part 1 layer).
- Stretchy: rig từng layer → cape/sword di chuyển độc lập, không méo.

### Hệ quả cho pipeline generate (quan trọng!)

Bước GENERATE (agy-image, đã prove) cần **tối ưu cho riggability** khi sprite sẽ được animate:

- Ít phụ kiện floppy (cape dài, vải bay) → flat-rig OK.
- Vũ khí tách rời rõ (không chồng body) → dễ rig riêng.
- Silhouette sạch, full-body không clipped.

→ **Feed-back vào vision loop**: refinement prompt cho sprite-dùng-anim phải thêm ràng buộc riggability. Đây là mở rộng loop generate→look→refine đã prove: thêm 1 bước "rig-test" (metademolab manual hoặc Stretchy) → distortion feedback → regenerate sprite riggable hơn.

### Verdict cuối (cập nhật)

- Character ĐƠN GIẢN (humanoid trơn, ít phụ kiện): flat-rig (metademolab/manual) **đủ dùng**.
- Character PHỨC TẠP (cape/áo choàng/kiếm/nhiều layer): **bắt buộc** pipeline See-Through → Stretchy (layered), hoặc accept semi-manual rig trong Spine.

## 🔁 Bằng chứng loop generate→rig-test→refine (2026-07)

Chạy thật 4 iteration trên knight, feed rig-feedback ngược vào generate:

| Ver | Prompt goal | Kết quả (image-reader verify) |
| :-- | :-- | :-- |
| v1 | knight thường | tốt nhưng có bục đá + kiếm chồng chân + 3 huy hiệu |
| v2 | fix 3 lỗi v1 | ✅ 3/3 fixed — nhưng **rig-test metademolab: cape+kiếm bị MÉO** khi cử động |
| v3 | rig-friendly "separable parts" | agy hiểu lầm → vẽ **"exploded puppet kit"** (parts tản rác). SAI cho flat-rig (cần 1 figure) NHƯNG thú vị cho pipeline layered (agy tự decompose!) |
| v4 | SINGLE assembled A-pose, no cape, sword aside | ✅ 1 figure nguyên vẹn, không cape, kiếm tách, A-pose sạch → rig-ready cho metademolab |

**Hai insight mới từ loop này:**

1. **agy có thể generate pre-decomposed puppet kit** (v3) — shortcut tiềm năng, bỏ qua bước See-Through cho pipeline layered (cần validate thêm: parts có scale/foreshortening nhất quán không?).
2. **Riggability là ràng buộc generate riêng biệt** — prompt cho sprite-dùng-anim phải khác sprite-dùng-tĩnh (A-pose, không floppy, vũ khí tách). Loop generate→look→refine mở rộng thêm nhánh rig-test.

## 🫠 "Squishy / boneless" = soft-warp signature (insight cốt lõi)

User report animation metademolab trông "dẹo dẹo, không có xương" dù static character đẹp. **Root cause = soft mesh warp, KHÔNG phải skeletal rig thật:**

- metademolab/flat-rig: detect joint 2D → cắt ảnh thành vùng → xoay region warp theo = **cao su kéo dẹt**, không có độ cứng. Không biết "giáp=cứng". Mọi thứ deform như vải.
- Character đẹp static vì là ảnh đẹp (agy gen giỏi); chất lượng RIG chỉ lộ khi cử động → soft-warp luôn ra kiểu cao su.

**Fix duy nhất = skeletal LAYER rig** (mỗi part 1 rigid layer xoay quanh pivot, mesh skinning ở khớp): **Spine / DragonBones / Stretchy Studio** (See-Through tách layer → Stretchy rig → Spine export → Godot runtime). metademolab = tier toy; Spine/Stretchy = tier production.

**Đặc biệt với knight giáp** (rigid by nature): soft-warp là tệ nhất case. 2 hướng đẹp thật sự: (a) See-Through+Stretchy 2D layer rig, hoặc (b) **3D** — giáp rigid tự nhiên trong 3D + mocap Mixamo → case LÝ TƯỞNG cho 3D pipeline (Hunyuan3D/TripoSR, chưa research).
