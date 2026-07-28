# game-skills Repo Design (Lớp 2 — Game Vertical)

**Date:** July 23, 2026 · **Layer:** 2 (vertical-specific skill pack) · **Depends on:** harness-core (Lớp 1), Pi agent, agy CLI.

---

## 1. Mục đích

`game-skills` là skill pack **dọc game** chạy trên nền Harness (Lớp 1) + Pi. Chứa: tool tạo asset (agy-image), pipeline animation, và cấu hình/doc cho MCP servers game (blender-mcp, godot-ai). Vertical-agnostic harness phục vụ nhiều dọc; repo này gói riêng phần game.

> Nguyên tắc Pi: ưu tiên **Skills** (CLI + README) hơn MCP. agy-image = Skill (đã prove). blender-mcp/godot-ai vốn là MCP server → dùng global mcp.json, **document** ở đây.

---

## 2. Cấu trúc repo đề xuất

```
game-skills/
├── README.md                          # index + cách dùng
├── .agents/skills/
│   ├── agy-image/                     # ✅ đã build (move từ pi-auto-pilot)
│   │   ├── SKILL.md
│   │   └── scripts/agy-image.sh
│   ├── asset-pipeline/                # orchestrate generate→separate→rig→animate→export
│   │   ├── SKILL.md
│   │   └── scripts/
│   │       ├── separate-bg.sh         # rembg lột nền trong suốt
│   │       └── animated-drawings.sh   # Meta AnimatedDrawings (2D rig+anim)
│   └── godot-scaffold/                # tạo/cấu trúc Godot project + GUT test
│       └── SKILL.md
├── mcp/                               # doc + config templates (KHÔNG phải runtime)
│   ├── README.md                      # list MCP servers game cần + cách add
│   ├── blender-mcp.md                 # cách cài blender-mcp (cần Blender + patch #252 headless)
│   └── godot-ai.md                    # cách cài godot-ai MCP plugin
├── pipelines/
│   └── character-2d.md                # recipe: ảnh → AnimatedDrawings → sprite sheet → Godot
│   └── character-3d.md                # recipe: ảnh → image-to-3D → Mixamo → .glb → Godot
└── docs/
    ├── asset-loop.md                  # symlink/tóm tắt OPTIMAL_ASSET_LOOP_ARCHITECTURE.md
    └── limitations.md                 # agy #454 (1:1), #71 (MCP broken), blender #252 (headless)
```

---

## 3. Các thành phần

### A. `agy-image` (đã prove) — bước GENERATE

Skill chạy agy headless sinh ảnh, xài quota AI Pro. Đã work. Move nguyên folder từ `pi-auto-pilot/.agents/skills/agy-image/`.

### B. `asset-pipeline` — bước SEPARATE + RIG + ANIMATE

- `separate-bg.sh`: `rembg -i input.png output/` (lột nền → sprite trong suốt).
- `animated-drawings.sh`: wrap Meta `AnimatedDrawings` (ảnh 2D → detect khớp → rig → walk/jump/dance). Đây là "1 ảnh → animate di chuyển".
- Reference pipeline trong `AI_CHARACTER_ANIMATION_TOOLS.md`.

### C. `godot-scaffold` — bước EXPORT/PLACE

Skill tạo Godot project structure (scenes/scripts/tests) theo `RESEARCH_GAME_ENGINE_AI_AGENTS.md`. Khi có godot-ai MCP, Pi drive placement; chưa có thì skill scaffold file `.tscn`/`.gd` text-based.

### D. `mcp/` — doc MCP servers (không runtime)

- `blender-mcp.md`: cài Blender + blender-mcp addon. ⚠️ Headless cần patch [#252](https://github.com/ahujasid/blender-mcp/issues/252) (OPEN). Workaround: Blender + Xvfb.
- `godot-ai.md`: cài [hi-godot/godot-ai](https://github.com/hi-godot/godot-ai) plugin + add vào `~/.pi/agent/mcp.json`:

  ```json
  "godot-ai": { "command": "npx", "args": ["-y", "@hi-godot/godot-ai-mcp"] }
  ```

  (verify exact package khi cài thực tế)

### E. `pipelines/` — recipe end-to-end

`character-2d.md` / `character-3d.md`: пошаговый recipe từ concept → asset anim ready cho Godot.

---

## 4. Loop architecture (reference)

```
[Pi = conductor, model riêng]
   │
   ├─ Skill agy-image ──► agy generate (quota AI Pro) ──► file ảnh
   ├─ Skill asset-pipeline ──► rembg + AnimatedDrawings / Mixamo ──► rigged/animated asset
   ├─ MCP blender-mcp ──► (cần Blender) 3D/rig/keyframe/export .glb
   └─ MCP godot-ai ──► (cần Godot) place scene, run GUT test, render screenshot
          │
          ▼
   image-reader (vision) nhìn screenshot ──► refine prompt ──► lặp
```

Full detail: `OPTIMAL_ASSET_LOOP_ARCHITECTURE.md`.

---

## 5. Phân vai máy (tái khẳng định)

| Máy | Vai trò game |
| :--- | :--- |
| Mac mini (always-on) | Pi conductor + agy-image (generate) |
| Linux (always-on) | Blender headless render + build (khi có blender-mcp) |
| Laptop | review, herdr attach |

---

## 6. Việc cần làm (khi tạo repo thật)

1. `git init game-skills`, cấu trúc thư mục như §2.
2. Move `agy-image/` từ pi-auto-pilot sang.
3. Viết `asset-pipeline/separate-bg.sh` (rembg) + test.
4. Wrap `animated-drawings.sh` (cài Meta AnimatedDrawings — Python).
5. Cài Godot 4 + blender + plugin, cấu hình MCP, prove placement step.
6. Viết README index cho repo.

**Chưa làm ngay** (research-only repo): đây chỉ là design. Khi bạn sẵn sàng build, tạo repo `game-skills` rồi áp dụng.
