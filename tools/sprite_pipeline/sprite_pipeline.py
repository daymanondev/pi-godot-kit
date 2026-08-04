"""sprite_pipeline — turn an agy sprite sheet into per-direction frame cycles.

The LOCKED pipeline (docs/character-sprite-pipeline.md + ADR 0002):
  split a rows x cols sheet into cells -> bg-remove -> per-direction cycle
  (select columns + optional mirror) -> align onto a fixed canvas.

This module is the reusable tool that the walk frames were produced from ad-hoc
but was never committed (issue #21). Pure Pillow only.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw

__all__ = [
    "FrameSpec",
    "split_grid",
    "build_cycle",
    "remove_bg",
    "align_frames",
    "sheet_to_cycles",
    "CYCLES",
]


def split_grid(
    sheet: Image.Image, rows: int, cols: int, inset: int = 0
) -> list[list[Image.Image]]:
    """Split a sheet into `rows` rows of `cols` cell images.

    Cell size is derived from the sheet (even division); `inset` trims that many
    pixels off each cell edge to skip gridlines/borders. Returns rows of cells
    in reading order (row 0 left-to-right, then row 1, ...).
    """
    w, h = sheet.size
    cw, ch = w // cols, h // rows
    if cw == 0 or ch == 0:
        raise ValueError(
            f"sheet {w}x{h} too small for {rows}x{cols} grid (cell {cw}x{ch})"
        )
    result: list[list[Image.Image]] = []
    for r in range(rows):
        row: list[Image.Image] = []
        for c in range(cols):
            x0 = c * cw + inset
            y0 = r * ch + inset
            row.append(sheet.crop((x0, y0, x0 + cw - 2 * inset, y0 + ch - 2 * inset)))
        result.append(row)
    return result


@dataclass(frozen=True)
class FrameSpec:
    """One output frame of a cycle: which source column it comes from, and
    whether to mirror it horizontally."""

    col: int
    mirror: bool = False


def build_cycle(
    row_cells: list[Image.Image], spec: list[FrameSpec]
) -> list[Image.Image]:
    """Assemble an ordered frame cycle from one direction's source columns.

    `row_cells` are the columns of a single direction's row (left-to-right).
    `spec` selects columns (and optionally mirrors them) to build the looping
    cycle — e.g. walk = [stand, step, stand, mirror(step)]; hoe = 4 distinct
    asymmetric phases (no mirror).
    """
    frames: list[Image.Image] = []
    for fs in spec:
        if not (0 <= fs.col < len(row_cells)):
            raise IndexError(
                f"FrameSpec col {fs.col} out of range for {len(row_cells)} columns"
            )
        cell = row_cells[fs.col]
        frames.append(
            cell.transpose(Image.Transpose.FLIP_LEFT_RIGHT) if fs.mirror else cell.copy()
        )
    return frames


def remove_bg(cell: Image.Image, thresh: int = 16) -> Image.Image:
    """Flood-fill near-white background from the borders to transparent.

    Returns RGBA. Seeds all four corners so any background connected to an
    edge is cleared; the interior character (differing by more than `thresh` per
    channel) is left opaque.
    """
    rgba = cell.convert("RGBA")
    w, h = rgba.size
    fill = (0, 0, 0, 0)
    for seed in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]:
        ImageDraw.floodfill(rgba, seed, fill, thresh=thresh)
    return rgba


def _upper_centroid_x(alpha: Image.Image) -> int:
    """Mean x of opaque pixels in the top half of the alpha channel."""
    w, h = alpha.size
    data = alpha.tobytes()  # 'L' mode: one byte per pixel, indexing yields int
    top = h // 2
    sx = 0
    n = 0
    for y in range(top):
        base = y * w
        for x in range(w):
            if data[base + x] > 0:
                sx += x
                n += 1
    return sx // n if n else w // 2


def _feet_bottom(alpha: Image.Image) -> int:
    """Lowest y (max row) containing any opaque pixel — the feet line."""
    w, h = alpha.size
    data = alpha.tobytes()
    for y in range(h - 1, -1, -1):
        base = y * w
        for x in range(w):
            if data[base + x] > 0:
                return y
    return h // 2


def align_frames(
    frames: list[Image.Image], canvas: tuple[int, int], feet_margin: int = 4
) -> list[Image.Image]:
    """Normalise each frame onto a fixed canvas by upper-body centroid x and
    feet-bottom y, so the character doesn't jitter between frames."""
    w, h = canvas
    feet_line = h - feet_margin
    out: list[Image.Image] = []
    for fr in frames:
        rgba = fr.convert("RGBA")
        alpha = rgba.getchannel("A")
        cx = _upper_centroid_x(alpha)
        fy = _feet_bottom(alpha)
        offset = (w // 2 - cx, feet_line - fy)
        sheet = Image.new("RGBA", canvas, (0, 0, 0, 0))
        sheet.paste(rgba, offset, rgba)  # mask by the frame's own alpha
        out.append(sheet)
    return out


def sheet_to_cycles(
    sheet: Image.Image,
    directions: tuple[str, ...],
    cycle: list[FrameSpec],
    canvas: tuple[int, int],
    *,
    rows: int = 3,
    cols: int = 4,
    inset: int = 0,
    bg_thresh: int = 16,
    feet_margin: int = 18,
) -> dict[str, list[Image.Image]]:
    """Full pipeline: split a sheet into per-direction aligned frame cycles.

    `directions[i]` names row i (top-to-bottom). Each row is bg-removed, then
    assembled into the same `cycle` (selection + mirroring), then aligned onto
    `canvas`. Returns {direction: [frames]}.
    """
    grid = split_grid(sheet, rows, cols, inset)
    if len(grid) != len(directions):
        raise ValueError(
            f"sheet has {len(grid)} rows but {len(directions)} directions given"
        )
    result: dict[str, list[Image.Image]] = {}
    for row_cells, direction in zip(grid, directions):
        cleaned = [remove_bg(c, bg_thresh) for c in row_cells]
        frames = build_cycle(cleaned, cycle)
        result[direction] = align_frames(frames, canvas, feet_margin)
    return result


# ---- cycle-logic presets (ADR 0002 / CONTEXT.md) ----

CYCLES: dict[str, list[FrameSpec]] = {
    # walk: stand, step, stand, mirror(step) — mirror creates the opposite-leg stride
    "walk": [FrameSpec(0), FrameSpec(1), FrameSpec(2), FrameSpec(1, mirror=True)],
    # idle: 4 breathing phases, no mirror
    "idle": [FrameSpec(0), FrameSpec(1), FrameSpec(2), FrameSpec(3)],
    # hoe: 4 asymmetric swing phases, no mirror
    "hoe": [FrameSpec(0), FrameSpec(1), FrameSpec(2), FrameSpec(3)],
}


def _canvas_type(value: str) -> tuple[int, int]:
    """argparse type: parse 'WxH' into a (w, h) int tuple, or fail cleanly."""
    try:
        w_str, h_str = value.lower().split("x")
        return int(w_str), int(h_str)
    except ValueError as exc:
        raise argparse.ArgumentTypeError("expected WxH, e.g. 340x340") from exc


def _load_sheet(path: Path) -> Image.Image:
    """Open the input sheet, with a clean error on a missing file."""
    if not path.is_file():
        raise SystemExit(f"sprite_pipeline: sheet not found: {path}")
    return Image.open(path).convert("RGB")


def _main() -> None:
    """CLI: split an agy sheet into per-direction frame cycles.

    Usage:
      python3 tools/sprite_pipeline/sprite_pipeline.py \
          --sheet multidir_v4.jpg --cycle walk --out character_frames
    Writes <out>/<direction>_<i>.png per frame (matches the Godot controller's
    expected naming: front_3q_0.png, back_0.png, side_right_0.png, ...).
    """
    p = argparse.ArgumentParser(description="agy sprite sheet -> per-direction frame cycles")
    p.add_argument("--sheet", required=True, type=Path, help="input rows x cols sheet image")
    p.add_argument("--cycle", required=True, choices=sorted(CYCLES), help="cycle-logic preset")
    p.add_argument("--out", required=True, type=Path, help="output directory for frames")
    p.add_argument("--directions", default="front_3q,back,side_right",
                   help="comma list naming rows top-to-bottom")
    p.add_argument("--rows", type=int, default=3)
    p.add_argument("--cols", type=int, default=4)
    p.add_argument("--inset", type=int, default=4, help="px trimmed per cell edge to skip gridlines")
    p.add_argument("--canvas", type=_canvas_type, default=(340, 340), help="output frame canvas, e.g. 340x340")
    p.add_argument("--feet-margin", type=int, default=18, help="px between feet and canvas bottom")
    p.add_argument("--bg-thresh", type=int, default=16, help="flood-fill near-white tolerance")
    args = p.parse_args()

    directions = tuple(d.strip() for d in args.directions.split(",") if d.strip())
    sheet = _load_sheet(args.sheet)
    cycles = sheet_to_cycles(
        sheet, directions, CYCLES[args.cycle], args.canvas,
        rows=args.rows, cols=args.cols, inset=args.inset,
        bg_thresh=args.bg_thresh, feet_margin=args.feet_margin,
    )
    args.out.mkdir(parents=True, exist_ok=True)
    for direction, frames in cycles.items():
        for i, fr in enumerate(frames):
            fr.save(args.out / f"{direction}_{i}.png")
    n = sum(len(v) for v in cycles.values())
    print(f"wrote {n} frames ({len(cycles)} directions x {len(next(iter(cycles.values())))}) to {args.out}")


if __name__ == "__main__":
    _main()
