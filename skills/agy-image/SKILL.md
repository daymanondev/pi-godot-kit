---
name: agy-image
description: Generate images via Google Antigravity CLI (agy) running headless, billed to your existing agy / AI Pro quota — no separate API key. Use when creating game assets (sprites, concept art, textures, icons, backgrounds) and you want to leverage abundant agy quota instead of a paid image API, or when the user says "generate image/sprite/texture with agy".
---

# agy-image

Generate an image with `agy` (Antigravity CLI) headless, using your **agentic AI Pro quota**. Returns the absolute path of the saved file. Pi stays the brain; agy is only the image drawer — no model routing, no session-poisoning risk.

## Quick start

```bash
bash .agents/skills/agy-image/scripts/agy-image.sh \
  "a 1024x1024 fantasy knight sprite, full body, clean flat background" \
  ./assets/sprites
# → prints absolute path, e.g. /abs/path/to/assets/sprites/knight.jpg
```

## Usage

```bash
bash scripts/agy-image.sh "<prompt>" <output-dir-or-path> [timeout_seconds]
```

- `<prompt>` — describe the image. State size/aspect explicitly (agy defaults to **1024×1024 / 1:1**).
- `<output-dir-or-path>` — a dir (agy names the file) or an exact file path (requested).
- `[timeout_seconds]` — default `180`.

## How it works

1. Runs `agy --print` headless with `--dangerously-skip-permissions` (auto-approves agy's built-in `generate_image` tool — required for non-interactive use).
2. agy calls `generate_image` (Imagen / Gemini image model), saves the file, and prints the absolute path on the final line.
3. The wrapper script scans agy's output for the last line that is an **existing file** and returns it.

## Requirements

- `agy` ≥ 1.0.15 installed and **authenticated** in `PATH` (run `agy` once interactively to log in if needed).
- Works offline of any MCP — pure CLI wrapper.

## Notes & limits

- agy `generate_image` currently forces **1:1 (1024×1024)** regardless of prompt (see [agy #454](https://github.com/google-antigravity/antigravity-cli/issues/454)). Request other ratios in the prompt but expect variance.
- File format is auto-detected by agy (`.jpg` / `.png` / `.webp`).
- For transparent backgrounds or precise pixel art, post-process (e.g. `rembg`) or drive Aseprite via MCP separately.
- **Arg order matters:** flags first (`--dangerously-skip-permissions`, `--print-timeout=Ns`), then `--print "<prompt>"` last — otherwise agy treats a flag as the prompt.

## Pipeline context

This skill is the **generate** step of the asset loop:

```
agy-image (this)  →  blender-mcp / godot-ai (place, rig, animate)  →  render  →  look  →  refine
```

See `OPTIMAL_ASSET_LOOP_ARCHITECTURE.md` for the full loop.
