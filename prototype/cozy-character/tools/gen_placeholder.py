#!/usr/bin/env python3
"""PROTOTYPE ART GENERATOR — throwaway.

Draws a simple cozy "blob farmer" (terracotta body, cream belly, sprout)
as transparent animated GIFs, then packs each into a grid sprite sheet +
JSON sidecar via skills/simple-rig/scripts/pack_spritesheet.py (#5).

This is NOT real character art. It exists so the Godot scaffold (#4) has
something to display/animate while validating the input->movement->anim
pipeline end-to-end. Replace with real agy-image -> AnimatedDrawings -> pack
art when the pipeline is wired.

Usage:  python3 tools/gen_placeholder.py
"""
from __future__ import annotations
import os, subprocess, sys
from pathlib import Path
from PIL import Image, ImageDraw

SIZE = 64
BODY = (193, 111, 74, 255)
OUTLINE = (120, 62, 40, 255)
BELLY = (244, 228, 193, 255)
EYE = (38, 28, 28, 255)
LEAF = (124, 176, 80, 255)


def draw_char(dx: int = 0, dy: int = 0, step: int = 0) -> Image.Image:
    """Draw one frame of the blob. dx/dy = sway/bob offset; step = foot phase."""
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx, cy = SIZE // 2 + dx, 38 + dy

    # sprout on top (reads as a plant-y cozy creature)
    d.ellipse([cx - 6, cy - 22, cx + 1, cy - 15], fill=LEAF)
    d.ellipse([cx - 1, cy - 23, cx + 6, cy - 16], fill=LEAF)
    # body
    d.ellipse([cx - 15, cy - 16, cx + 15, cy + 12], fill=BODY, outline=OUTLINE, width=2)
    # belly
    d.ellipse([cx - 7, cy - 6, cx + 7, cy + 10], fill=BELLY)
    # eyes
    d.ellipse([cx - 6, cy - 9, cx - 3, cy - 6], fill=EYE)
    d.ellipse([cx + 3, cy - 9, cx + 6, cy - 6], fill=EYE)
    # feet — alternate with step to fake a walk
    fl = 0 if step == 0 else -2
    fr = -2 if step == 0 else 0
    d.ellipse([cx - 9, cy + 11 + fl, cx - 3, cy + 16 + fl], fill=OUTLINE)
    d.ellipse([cx + 3, cy + 11 + fr, cx + 9, cy + 16 + fr], fill=OUTLINE)
    return im


def main() -> None:
    here = Path(__file__).resolve().parent
    proto = here.parent
    sprites = proto / "assets" / "sprites"
    sprites.mkdir(parents=True, exist_ok=True)

    # idle: gentle vertical bob (4 frames, slow)
    idle = [draw_char(dy=(-2 if i % 2 else 2)) for i in range(4)]
    # walk: horizontal sway + alternating feet (6 frames, faster)
    walk = [draw_char(dx=(2 if i % 2 else -2), step=i % 2) for i in range(6)]

    idle_gif = sprites / "farmer_idle.gif"
    walk_gif = sprites / "farmer_walk.gif"
    idle[0].save(idle_gif, save_all=True, append_images=idle[1:], duration=160, loop=0, disposal=2)
    walk[0].save(walk_gif, save_all=True, append_images=walk[1:], duration=95, loop=0, disposal=2)

    # pack each via the real packer (#5)
    packer = proto.parents[1] / "skills" / "simple-rig" / "scripts" / "pack_spritesheet.py"
    for gif in (idle_gif, walk_gif):
        out = gif.with_suffix("")  # farmer_idle / farmer_walk
        r = subprocess.run([sys.executable, str(packer), str(gif), "--out", str(out)],
                           capture_output=True, text=True)
        print(r.stdout.strip())
        if r.returncode != 0:
            print(r.stderr, file=sys.stderr)
            raise SystemExit(r.returncode)

    print("\n✅ placeholder sheets generated:")
    for f in sorted(sprites.iterdir()):
        print("  ", f.relative_to(proto))


if __name__ == "__main__":
    main()
