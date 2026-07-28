# pi-godot-kit

**Pi package** — skills + tools cho phát triển game Godot (cozy / 2D-first). Đây là **Lớp 2 vertical** trong kiến trúc 3 lớp (xem [`../pi-auto-pilot/ARCHITECTURE_HARNESS_VS_PACKAGE.md`](../pi-auto-pilot/ARCHITECTURE_HARNESS_VS_PACKAGE.md)).

## Cài đặt

```bash
pi install ./pi-godot-kit        # local
# sau khi push git:
pi install git:github.com/<user>/pi-godot-kit
```

Pi load package → skill `agy-image` (+ sau: extension tools) available trong session.

## Cấu trúc

```text
pi-godot-kit/
├── package.json          # Pi package manifest (khóa `pi`)
├── skills/
│   └── agy-image/        # ✅ ĐÃ PROVE — sinh ảnh qua agy (quota AI Pro)
│       ├── SKILL.md
│       └── scripts/agy-image.sh
├── extensions/           # (sau) asset-pipeline tools dạng Pi extension
└── docs/                 # research game
```

## Pipeline (cozy / 2D-first — Tier Simple)

```text
agy-image (gen, agy quota) → image-reader (look) → refine → simple-rig → Godot
```

Character nhỏ / hand-drawn (Don't Starve / Stardew / Animal Crossing aesthetic) → agy-image + flat-rig / simple-Spine **ĐỦ**. Không cần See-Through / Stretchy / 3D (chỉ cho Tier Medium/Complex). Chi tiết: [`docs/ASSET_COMPLEXITY_SCOPING.md`](docs/ASSET_COMPLEXITY_SCOPING.md).

## Docs index (trong `docs/`)

| File | Tóm tắt |
| :--- | :--- |
| [ASSET_COMPLEXITY_SCOPING.md](docs/ASSET_COMPLEXITY_SCOPING.md) | **Keystone**: complexity → tooling tier. Cozy = Tier Simple. |
| [ANIMATION_TOOL_FINDINGS.md](docs/ANIMATION_TOOL_FINDINGS.md) | 2D rig tools 2026, soft-warp "squishy", loop 4-iter knight. |
| [OPTIMAL_ASSET_LOOP_ARCHITECTURE.md](docs/OPTIMAL_ASSET_LOOP_ARCHITECTURE.md) | Loop asset tối ưu (Pi conductor + agy). ĐÃ PROVE. |
| [GAME_SKILLS_REPO_DESIGN.md](docs/GAME_SKILLS_REPO_DESIGN.md) | (historical) design ban đầu — nay realized thành Pi package này. |
| [RESEARCH_GAME_ENGINE_AI_AGENTS.md](docs/RESEARCH_GAME_ENGINE_AI_AGENTS.md) | Engine = Godot 4 (text-based, headless, MCP). |
| [AI_GAME_ASSET_GENERATION_RESEARCH.md](docs/AI_GAME_ASSET_GENERATION_RESEARCH.md) | Pipeline 2D/3D/audio. |
| [AI_CHARACTER_ANIMATION_TOOLS.md](docs/AI_CHARACTER_ANIMATION_TOOLS.md) | Animation tools overview. |
| [AGY_MCP_VISION_LOOP_RESEARCH.md](docs/AGY_MCP_VISION_LOOP_RESEARCH.md) | agy MCP broken, loop driver = Pi. |
| [PRICING_AND_HARDWARE_RESOURCES.md](docs/PRICING_AND_HARDWARE_RESOURCES.md) | Pricing free-first, RX6600 = AMD. |

## Status

- ✅ Skill `agy-image` proven (loop generate→look→refine: knight v1→v4 + cozy farmer A/B).
- ⏭ Tiếp: skill `simple-rig`, extension asset-pipeline tools, scaffold Godot project.
- Harness (Lớp 1) ở repo [`../pi-auto-pilot/`](../pi-auto-pilot/).
