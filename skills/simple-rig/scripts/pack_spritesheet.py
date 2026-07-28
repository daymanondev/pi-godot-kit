#!/usr/bin/env python3
"""
pack_spritesheet.py — pack an animated GIF or video into a Godot-ready grid
sprite sheet + JSON sidecar.

Part of the `simple-rig` skill: the "pipeline glue" step that turns a Meta
AnimatedDrawings render (animated GIF/MP4 of a rigged character) into a grid
sprite sheet that Godot 4's AnimatedSprite2D can consume via SpriteFrames.

Input  : an animated .gif (alpha preserved) or a video .mp4/.webm/.mov
Output : <prefix>.png  — grid sprite sheet (RGBA, transparent cells)
         <prefix>.json — {frame_width, frame_height, columns, rows, frame_count, fps, source, sheet}

Frames are padded (centered on a transparent max-canvas) so every cell is the
same size — required for clean Godot slicing. The grid auto-targets a near-square
sheet; override with --cols.

Usage:
    python3 pack_spritesheet.py walk.gif --out assets/sprites/farmer_walk
    python3 pack_spritesheet.py jump.mp4 --out assets/sprites/farmer_jump --fps 24
"""
from __future__ import annotations

import argparse
import json
import math
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import NoReturn

from PIL import Image, ImageSequence

DEFAULT_FPS = 12
VIDEO_EXTS = {".mp4", ".webm", ".mov", ".m4v", ".mkv", ".avi"}


def die(msg: str, code: int = 1) -> NoReturn:
    print(f"pack_spritesheet: error: {msg}", file=sys.stderr)
    raise SystemExit(code)


def load_gif_frames(path: Path) -> tuple[list[Image.Image], list[float]]:
    """Extract RGBA frames + per-frame durations (ms) from a GIF."""
    im = Image.open(path)
    frames: list[Image.Image] = []
    durations: list[float] = []
    for fr in ImageSequence.Iterator(im):
        frames.append(fr.convert("RGBA").copy())
        raw = fr.info.get("duration")
        # Pillow stores GIF frame duration in ms as int; fall back to 0 otherwise.
        durations.append(float(raw) if isinstance(raw, (int, float)) else 0.0)
    return frames, durations


def load_video_frames(path: Path) -> list[Image.Image]:
    """Extract RGBA frames from a video via ffmpeg (to temp PNGs)."""
    if not shutil.which("ffmpeg"):
        die("video input needs ffmpeg in PATH (only Pillow is installed)")
    with tempfile.TemporaryDirectory() as tmp:
        pattern = str(Path(tmp) / "f%05d.png")
        # -fps_mode passthrough: 1:1 frame extraction, no dup/drop (ffmpeg >=5)
        cmd = ["ffmpeg", "-y", "-i", str(path), "-fps_mode", "passthrough", pattern]
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            die(f"ffmpeg failed:\n{proc.stderr.strip()}")
        files = sorted(Path(tmp).glob("f*.png"))
        if not files:
            die("ffmpeg produced no frames")
        return [Image.open(f).convert("RGBA") for f in files]


def probe_video_fps(path: Path, default: float) -> float:
    """Best-effort fps via ffprobe r_frame_rate (e.g. '30/1'); else default."""
    if not shutil.which("ffprobe"):
        return default
    cmd = [
        "ffprobe", "-v", "0", "-select_streams", "v:0",
        "-print_format", "json", "-show_entries", "stream=r_frame_rate", str(path),
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        return default
    try:
        rate = json.loads(proc.stdout)["streams"][0]["r_frame_rate"]
        num, den = rate.split("/")
        den_f = float(den) or 1.0
        return float(num) / den_f
    except (ValueError, KeyError, IndexError, ZeroDivisionError):
        return default


def compute_grid(n: int, force_cols: int | None) -> tuple[int, int]:
    cols = force_cols or max(1, math.ceil(math.sqrt(n)))
    rows = max(1, math.ceil(n / cols))
    return cols, rows


def normalize(frames: list[Image.Image]) -> tuple[list[Image.Image], int, int]:
    """Pad every frame to the max frame size, centered on transparent canvas."""
    fw = max(f.width for f in frames)
    fh = max(f.height for f in frames)
    out = []
    for f in frames:
        if f.width == fw and f.height == fh:
            out.append(f)
            continue
        canvas = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
        canvas.paste(f, ((fw - f.width) // 2, (fh - f.height) // 2), f)
        out.append(canvas)
    return out, fw, fh


def main() -> None:
    ap = argparse.ArgumentParser(description="Pack an animation into a grid sprite sheet + JSON sidecar.")
    ap.add_argument("input", help="animated .gif or video file")
    ap.add_argument("--out", help="output prefix (default: input stem, in same dir)")
    ap.add_argument("--fps", type=float, help="override fps (default: from GIF duration, ffprobe, or 12)")
    ap.add_argument("--cols", type=int, help="force grid columns (default: auto near-square)")
    args = ap.parse_args()

    src = Path(args.input).expanduser().resolve()
    if not src.is_file():
        die(f"input not found: {src}")
    ext = src.suffix.lower()

    # --- load frames + fps ---
    if ext == ".gif":
        frames, durations = load_gif_frames(src)
        if args.fps:
            fps = args.fps
        else:
            ds = [d for d in durations if d > 0]
            fps = 1000.0 / (sum(ds) / len(ds)) if ds else DEFAULT_FPS
    elif ext in VIDEO_EXTS:
        frames = load_video_frames(src)
        fps = args.fps if args.fps else probe_video_fps(src, DEFAULT_FPS)
    else:
        die(f"unsupported input type '{ext}' (use .gif or a video: {', '.join(sorted(VIDEO_EXTS))})")

    n = len(frames)
    if n < 2:
        die(f"need >=2 frames, got {n}")

    # --- normalize + grid ---
    frames, fw, fh = normalize(frames)
    cols, rows = compute_grid(n, args.cols)

    # --- compose sheet ---
    sheet = Image.new("RGBA", (cols * fw, rows * fh), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        c, r = i % cols, i // cols
        sheet.paste(f, (c * fw, r * fh), f)

    # --- write outputs ---
    out_prefix = Path(args.out) if args.out else src.with_suffix("")
    if out_prefix.is_dir():
        out_prefix = out_prefix / src.stem
    png_path = out_prefix.with_suffix(".png")
    json_path = out_prefix.with_suffix(".json")
    png_path.parent.mkdir(parents=True, exist_ok=True)

    sheet.save(png_path, "PNG")
    meta = {
        "source": src.name,
        "sheet": png_path.name,
        "frame_width": fw,
        "frame_height": fh,
        "columns": cols,
        "rows": rows,
        "frame_count": n,
        "fps": round(fps, 3),
    }
    json_path.write_text(json.dumps(meta, indent=2) + "\n")

    print(f"frames: {n}  cell: {fw}x{fh}  grid: {cols}x{rows}  fps: {fps:.1f}")
    print(f"sheet:  {png_path}")
    print(f"meta:   {json_path}")


if __name__ == "__main__":
    main()
