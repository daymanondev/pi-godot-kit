"""Seam-1 unit tests for the sprite-sheet pipeline (split -> cycle).

Run: python3 tools/sprite_pipeline/test_sprite_pipeline.py

Tests assert external behaviour through the public functions only — no internal
mocks. Synthetic sheets are painted with an INDEPENDENT ground truth (a known
distinct colour per cell), so assertions can disagree with the code.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

# allow running from repo root without install
sys.path.insert(0, str(Path(__file__).parent))
from sprite_pipeline import (  # noqa: E402
    FrameSpec,
    align_frames,
    build_cycle,
    remove_bg,
    sheet_to_cycles,
    split_grid,
)


def _paint_grid(rows: int, cols: int, cell: int) -> Image.Image:
    """A rows x cols sheet where each cell is a distinct solid colour.

    The colour of cell (r, c) encodes its coordinates, so a correct split
    extracts exactly these colours — an independent ground truth, not derived
    the way the code crops.
    """
    sheet = Image.new("RGB", (cols * cell, rows * cell))
    for r in range(rows):
        for c in range(cols):
            shade = (r * 8 + 40, c * 17 + 10, 200)  # distinct per (r, c)
            cell_img = Image.new("RGB", (cell, cell), shade)
            sheet.paste(cell_img, (c * cell, r * cell))
    return sheet


def test_split_grid_returns_rows_of_cells() -> None:
    """A 3x4 sheet splits into 3 rows of 4 cells."""
    sheet = _paint_grid(rows=3, cols=4, cell=100)

    rows = split_grid(sheet, rows=3, cols=4)

    assert len(rows) == 3, f"expected 3 rows, got {len(rows)}"
    for r, row in enumerate(rows):
        assert len(row) == 4, f"row {r}: expected 4 cells, got {len(row)}"


def test_split_grid_cell_is_correct_region() -> None:
    """Each cell's content matches the coordinates it was painted from — proves
    the split extracts the right region, not just the right count."""
    cell = 100
    sheet = _paint_grid(rows=3, cols=4, cell=cell)
    expected = {
        (r, c): sheet.getpixel((c * cell + cell // 2, r * cell + cell // 2))
        for r in range(3)
        for c in range(4)
    }

    rows = split_grid(sheet, rows=3, cols=4)

    for r, row in enumerate(rows):
        for c, img in enumerate(row):
            centre = img.getpixel((cell // 2, cell // 2))
            assert centre == expected[(r, c)], (
                f"cell ({r},{c}): expected {expected[(r,c)]}, got {centre}"
            )


MARKER = (220, 30, 30)
BASE = (90, 90, 90)


def _row_with_left_marker(cell: int) -> list[Image.Image]:
    """4 cells; cell index 1 carries a marker on its LEFT half.

    Independent ground truth: build_cycle's walk spec mirrors cell 1 into the
    4th frame, so the marker must appear on the RIGHT in frame 3.
    """
    cells = [Image.new("RGB", (cell, cell), BASE) for _ in range(4)]
    dot = Image.new("RGB", (cell // 4, cell // 4), MARKER)
    cells[1].paste(dot, (cell // 8, cell // 2))  # left half
    return cells


def _has_marker(img: Image.Image, half: str) -> bool:
    cell = img.size[0]
    mid = cell // 2
    xs = range(0, mid) if half == "left" else range(mid, cell)
    found = False
    for y in range(cell):
        for x in xs:
            if img.getpixel((x, y)) == MARKER:
                found = True
                break
        if found:
            break
    return found


def test_build_cycle_applies_walk_mirror() -> None:
    """Walk cycle-logic [stand, step, stand, mirror(step)] mirrors col 1 into
    frame 3, so its left-side marker lands on the right."""
    row = _row_with_left_marker(cell=100)
    walk = [FrameSpec(0), FrameSpec(1), FrameSpec(2), FrameSpec(1, mirror=True)]

    frames = build_cycle(row, walk)

    assert len(frames) == 4, f"expected 4 frames, got {len(frames)}"
    assert _has_marker(frames[1], "left") and not _has_marker(frames[1], "right"), (
        "frame 1 (col 1) marker should be on the left"
    )
    assert _has_marker(frames[3], "right") and not _has_marker(frames[3], "left"), (
        "frame 3 (mirror of col 1) marker should be on the right"
    )


def test_build_cycle_hoe_uses_four_distinct_cols() -> None:
    """Hoe cycle-logic uses 4 distinct columns with no mirror: frame i == col i."""
    cell = 100
    row = [Image.new("RGB", (cell, cell), (10 + i * 20, 10, 10)) for i in range(4)]
    hoe = [FrameSpec(0), FrameSpec(1), FrameSpec(2), FrameSpec(3)]

    frames = build_cycle(row, hoe)

    assert [f.getpixel((cell // 2, cell // 2)) for f in frames] == [
        row[i].getpixel((cell // 2, cell // 2)) for i in range(4)
    ], "hoe frames should equal their source columns, in order"


def test_remove_bg_clears_background_keeps_character() -> None:
    """Flood-fill clears the white border background; the interior character
    stays opaque with its colour preserved."""
    cell = Image.new("RGB", (100, 100), (255, 255, 255))
    cell.paste(Image.new("RGB", (30, 30), (220, 30, 30)), (35, 35))

    out = remove_bg(cell)

    assert out.mode == "RGBA"
    assert out.getpixel((0, 0)) == (0, 0, 0, 0), "corner background should be transparent"
    assert out.getpixel((50, 50)) == (220, 30, 30, 255), "character kept opaque+coloured"


def test_align_frames_centers_by_upper_centroid() -> None:
    """Two frames whose opaque block sits at different x end up centred at the
    same x after alignment — no horizontal jitter."""

    def with_block_at(x0: int) -> Image.Image:
        f = Image.new("RGBA", (100, 100), (0, 0, 0, 0))
        f.paste(Image.new("RGBA", (20, 40), (50, 50, 50, 255)), (x0, 30))
        return f

    def left_edge(img: Image.Image) -> int:
        a = img.getchannel("A")
        data = a.tobytes()
        for x in range(100):
            for y in range(100):
                if data[y * 100 + x] > 0:
                    return x
        return -1

    aligned = align_frames([with_block_at(5), with_block_at(60)], (100, 100))

    assert abs(left_edge(aligned[0]) - left_edge(aligned[1])) <= 1, (
        "aligned blocks should share the same left edge (centred)"
    )
    assert aligned[0].size == (100, 100)


def test_sheet_to_cycles_returns_aligned_frames_per_direction() -> None:
    """A 3x4 sheet with a character block in every cell yields 3 directions, each
    a 4-frame walk cycle on the fixed canvas."""
    cell = 80
    sheet = Image.new("RGB", (4 * cell, 3 * cell), (255, 255, 255))
    block = Image.new("RGB", (20, 30), (40, 120, 40))
    for r in range(3):
        for c in range(4):
            sheet.paste(block, (c * cell + 30, r * cell + 25))
    walk = [FrameSpec(0), FrameSpec(1), FrameSpec(2), FrameSpec(1, mirror=True)]

    cycles = sheet_to_cycles(
        sheet, ("front_3q", "back", "side_right"), walk, (cell, cell)
    )

    assert set(cycles) == {"front_3q", "back", "side_right"}
    for d, frames in cycles.items():
        assert len(frames) == 4, f"{d}: expected 4 frames"
        assert all(f.size == (cell, cell) for f in frames), f"{d}: frames not on canvas"


if __name__ == "__main__":
    test_split_grid_returns_rows_of_cells()
    print("ok: split_grid returns 3 rows of 4 cells")
    test_split_grid_cell_is_correct_region()
    print("ok: split_grid extracts the correct region per cell")
    test_build_cycle_applies_walk_mirror()
    print("ok: build_cycle mirrors col 1 into frame 3 (walk)")
    test_build_cycle_hoe_uses_four_distinct_cols()
    print("ok: build_cycle uses 4 distinct cols (hoe, no mirror)")
    test_remove_bg_clears_background_keeps_character()
    print("ok: remove_bg clears background, keeps character")
    test_align_frames_centers_by_upper_centroid()
    print("ok: align_frames centres by upper-body centroid")
    test_sheet_to_cycles_returns_aligned_frames_per_direction()
    print("ok: sheet_to_cycles returns aligned frames per direction")
    print("all tests passed")
