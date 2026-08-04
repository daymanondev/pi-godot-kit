"""Regression: the pipeline reproduces the walk frames from the real sheet.

Integration test on the validated walk asset (issue #21 acceptance: "reproduce
output equivalent to the 12 committed walk frames"). Exercises the tool through
its PUBLIC INTERFACE — the CLI — rather than importing internals, which also
keeps it free of the sibling-module import quirk. NOT pixel-identical: the
original ad-hoc script was never committed, so we assert STRUCTURAL equivalence:
12 frames, correct canvas, background cleared (tight character bbox, not
full-frame), character present, feet near the bottom. A contact sheet is
written to /tmp for the eyeball step.

Run: python3 tools/sprite_pipeline/test_walk_regression.py
Skips cleanly if the real sheet asset is absent.
"""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
SHEET = REPO / "prototype/cozy-character-real/farmer_multidir/multidir_v4.jpg"
TOOL = HERE / "sprite_pipeline.py"

CANVAS = (340, 340)
DIRECTIONS = ("front_3q", "back", "side_right")


def _contact_sheet(frames_by_dir: dict[str, list[Image.Image]], path: Path) -> None:
    rows = len(frames_by_dir)
    cols = max(len(v) for v in frames_by_dir.values())
    sheet = Image.new("RGBA", (cols * CANVAS[0], rows * CANVAS[1]), (0, 0, 0, 0))
    for r, frames in enumerate(frames_by_dir.values()):
        for c, fr in enumerate(frames):
            sheet.paste(fr, (c * CANVAS[0], r * CANVAS[1]))
    sheet.save(path)


def main() -> int:
    if not SHEET.is_file():
        print(f"skip: real sheet not present at {SHEET}")
        return 0

    out = Path("/tmp/walk_repro")
    if out.exists():
        shutil.rmtree(out)
    res = subprocess.run(
        [sys.executable, str(TOOL),
         "--sheet", str(SHEET), "--cycle", "walk", "--inset", "4",
         "--out", str(out)],
        capture_output=True, text=True, check=True,
    )
    print(res.stdout.strip())

    frames_by_dir: dict[str, list[Image.Image]] = {}
    for d in DIRECTIONS:
        frames_by_dir[d] = [Image.open(out / f"{d}_{i}.png").convert("RGBA") for i in range(4)]

    for d, frames in frames_by_dir.items():
        assert len(frames) == 4, f"{d}: {len(frames)} frames"
        for fr in frames:
            assert fr.size == CANVAS, f"{d}: frame {fr.size} != {CANVAS}"
            assert fr.mode == "RGBA"
            bb = fr.getchannel("A").getbbox()
            assert bb is not None, f"{d}: empty frame"
            w = bb[2] - bb[0]
            h = bb[3] - bb[1]
            assert w < 250 and h < 320, f"{d}: bbox {bb} too wide (bg not cleared?)"
            assert w > 80 and h > 150, f"{d}: bbox {bb} too small (no character?)"
            assert 310 <= bb[3] <= 328, f"{d}: feet at y={bb[3]}, expected ~322"

    _contact_sheet(frames_by_dir, Path("/tmp/walk_regression_contact.png"))
    print(f"ok: reproduced {sum(len(v) for v in frames_by_dir.values())} walk frames, "
          f"structurally equivalent (contact sheet -> /tmp/walk_regression_contact.png)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
