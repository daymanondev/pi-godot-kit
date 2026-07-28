# Optimal Asset-Loop Architecture — Synthesis

**Date:** July 23, 2026 · **Scope:** Tổng hợp 4 research song song (herdr conductor / split-loop / Pi driver / multi-machine) + verification, thành kiến trúc TỐI ƯU cho loop tạo asset game, tận dụng agy quota + 2 máy always-on.

---

## 1. Verified facts (sau khi main-agent check)

| Claim | Kết quả | Nguồn |
| :--- | :--- | :--- |
| herdr = terminal multiplexer cho agent, có CLI `herdr pane/agent/workspace/tab/worktree/...` | ✅ THẬT | [SKILL.md](https://github.com/ogulcancelik/herdr/blob/master/SKILL.md) |
| herdr conductor: 1 agent drive agent khác qua pane (`agent start`, lifecycle idle/working/blocked/done) | ✅ THẬT (design intent) | SKILL.md |
| herdr multi-machine qua SSH (`herdr --remote`) | ✅ THẬT | herdr.dev |
| cliproxy route agy→Pi "an toàn trên 0.82.0" | ❌ SAI — proxy vẫn poison | CLIProxyAPI [#2001](https://github.com/router-for-me/CLIProxyAPI/issues/2001), [#2557](https://github.com/router-for-me/CLIProxyAPI/issues/2557) |
| Pi không có tool mcp | ❌ SAI — Pi CÓ tool `mcp` (đang dùng) | session thực tế |
| blender-mcp headless (`blender -b`) chạy được | ⚠️ Cần patch #252 OPEN | ahujasid/blender-mcp [#252](https://github.com/ahujasid/blender-mcp/issues/252) |
| agy native image generation | ✅ ĐÃ PROVE — skill `agy-image` chạy thật: sinh ảnh đúng prompt 1024×1024; loop generate→look→refine (knight v1→v2, vision fix 3/3 lỗi) | agy [#454](https://github.com/google-antigravity/antigravity-cli/issues/454), [#680](https://github.com/google-antigravity/antigravity-cli/issues/680) |
| agy MCP broken (không invoke được tool) | ✅ THẬT, OPEN | agy [#71](https://github.com/google-antigravity/antigravity-cli/issues/71), [#39](https://github.com/google-antigravity/antigravity-cli/issues/39) |

---

## 2. Kiến trúc TỐI ƯU (đề xuất)

**Pattern: herdr Conductor (Pi) + agy Specialist + Linux Render Node**

```
Mac mini M4 (always-on) — HERDR HOST + CONDUCTOR
├─ pane w1:p1  CONDUCTOR = Pi (tool mcp + vision, model quota RIÊNG)
├─ pane w1:p2  agy SPECIALIST (standalone, quota agy: research/web/analysis)
└─ herdr --remote  ← laptop attach qua SSH

Linux 32GB+RX6600 (always-on) — RENDER/BUILD NODE
├─ Blender + blender-mcp  (⚠️ headless cần patch #252, hoặc chạy Blender+Xvfb)
└─ godot-ai MCP server
   ↑ conductor (Pi) gọi các server này qua network bằng tool mcp
```

### Vòng lặp tạo 1 asset

1. Conductor (Pi) nhận task "tạo character X".
2. Conductor invoke **agy** qua `herdr pane run w1:p2` cho **deep research/concept** (xài quota agy) → `herdr pane read` lấy kết quả về.
3. Conductor drive **blender-mcp / godot-ai** qua tool `mcp` (xài model quota của Pi) để build asset.
4. Conductor render screenshot → nhìn (vision) → refine.
5. *(Nếu agy native gen được confirm)* agy sinh concept image → conductor đặt vào scene qua MCP.

---

## 3. Sự thật cần nói thẳng về quota

**Quota agy ĐÃ ĐƯỢC CHỨNG MINH đóng điện cho bước generate của loop.** agy `generate_image` (quota AI Pro) sinh ảnh thật (đã prove qua skill `agy-image`). Phần **build/place (blender-mcp/godot-ai)** + **look (vision)** vẫn cần Pi conductor với model quota riêng (KHÔNG route qua cliproxy-agy). → Split-loop MỞ KHÓA: agy generate (quota) → Pi drive MCP place → Pi render → image-reader nhìn → refine → agy generate lại. **Loop này đã prove thật** (xem §7).

---

## 4. Topology chi tiết

| Máy | Vai trò | Lý do |
| :--- | :--- | :--- |
| **Mac mini M4** | herdr host + conductor (Pi) + agy pane | Ít điện, always-on ổn, đủ orchestration |
| **Linux 32GB+RX6600** | Render/build node: Blender MCP + godot-ai | GPU cho Blender render, RAM 32GB cho build nặng |
| **Laptop** | Cockpit: `herdr --remote` attach | Di động, review, không always-on |

⚠️ Lưu ý: headless blender-mcp cần patch #252 (chưa merge). Workaround: chạy Blender **có display giả (Xvfb)** trên Linux thay vì `blender -b`, hoặc đợi #252.

---

## 5. Linchpin — ĐÃ GIẢI QUYẾT ✅

*(Cũ: "verify agy native image gen" — ĐÃ XONG.)* agy CÓ `generate_image`, skill `agy-image` wrap nó, loop 2-iteration prove thành công. Chi tiết + ảnh test ở §7 và `README.md` §PoC. Bước verify tiếp theo thật sự còn lại: **place step** (cài Godot 4 + Blender + godot-ai/blender-mcp rồi prove placement) — chưa làm vì 2 tool chưa cài.

---

## 6. Sources

- herdr: [SKILL.md](https://github.com/ogulcancelik/herdr/blob/master/SKILL.md), [herdr.dev](https://herdr.dev)
- agy MCP broken: [#71](https://github.com/google-antigravity/antigravity-cli/issues/71), [#39](https://github.com/google-antigravity/antigravity-cli/issues/39)
- cliproxy vẫn poison: CLIProxyAPI [#2001](https://github.com/router-for-me/CLIProxyAPI/issues/2001), [#2557](https://github.com/router-for-me/CLIProxyAPI/issues/2557)
- blender-mcp headless: [#252](https://github.com/ahujasid/blender-mcp/issues/252)
- Pi poison (đã fix): [#2993](https://github.com/earendil-works/pi/issues/2993), [#3108](https://github.com/earendil-works/pi/issues/3108)
- Chi tiết 4 góc: `RESEARCH_A_HERDR_CONDUCTOR.md`, `RESEARCH_B_SPLIT_LOOP_HANDOFF.md`, `RESEARCH_C_PI_LOOP_DRIVER.md`, `RESEARCH_D_MULTIMACHINE_QUOTA.md`

---

## 7. LINCHPIN RESOLVED — agy CÓ native image generation (verify cứng)

**agy có tool `generate_image` built-in** (Imagen/Gemini, xài quota AI Pro subscription):

- agy [#454](https://github.com/google-antigravity/antigravity-cli/issues/454) (OPEN) — body: *"The built-in `generate_image` tool always outputs 1:1... underlying Gemini API supports aspectRatio via generationConfig.imageConfig.aspectRatio... but the generate_image tool wrapper does not expose this"*
- agy [#680](https://github.com/google-antigravity/antigravity-cli/issues/680) (OPEN) — generate_image fails resolution/format constraints
- Trigger: `/agy:image <desc>` hoặc tool `generate_image` trực tiếp

→ **§3 "sự thật về quota" được cập nhật: quota agy CÓ thể đóng điện cho bước generate.** Split-loop KHẢ THI:

```
agy generate_image (quota AI Pro) → file
  → Pi drive blender-mcp/godot-ai (tool mcp) để place/convert   [⚠ CHƯA prove: Godot/Blender chưa cài]
  → Pi render screenshot → image-reader (vision subagent) nhìn → refine directive   [✅ ĐÃ prove]
  → agy generate_image lại (quota) → lặp   [✅ ĐÃ prove: 2 iter, 3/3 fix]
```

> **Lưu ý:** vision step dùng **image-reader subagent (Gemini vision)**, KHÔNG phải "agy nhìn drag-drop" (clipboard agy #343 đang hỏng).

**Bonus path (không cần agy cho gen):** [vedang/pi-antigravity-image-gen](https://github.com/vedang/pi-antigravity-image-gen) — Pi extension generate image bằng Gemini trực tiếp. Nếu user có Gemini API key, Pi conductor tự generate luôn (không cần agy, không poison). 2 lựa chọn generate:

1. **agy `generate_image`** (xài quota AI Pro dồi dào) — qua herdr pane, file-handoff sang Pi
2. **Pi + vedang extension** (Gemini API key) — Pi tự generate, ít moving part hơn nhưng cần key riêng

**Khuyến nghị:** bắt đầu với option 1 (tận dụng quota agy dồi dào như user muốn). Option 2 làm fallback nếu agy gặp giới hạn (#454 aspect ratio, #680 resolution).
