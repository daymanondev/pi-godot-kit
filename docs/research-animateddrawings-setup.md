# Research: AnimatedDrawings Setup on macOS arm64

**Issue:** [#7](https://github.com/daymanondev/pi-godot-kit/issues/7) — gates map #6 (real cozy character).
**Verdict:** **FEASIBLE-WITH-CAVEATS** — proceed via the **ML-bypass** path (manual annotation), not the full auto-rig pipeline.

## TL;DR

Meta's AnimatedDrawings can rig + animate a 2D character on macOS arm64, but the
**repo is archived (Sep 2024)** and the heavy ML auto-annotation path (PyTorch 1.13 +
OpenMMLab + 670 MB models) is brittle on Apple Silicon. The smart route for our
pipeline is to **bypass the ML phase entirely**: generate the character via
`agy-image`, hand/programmatically build `mask.png` + `char_cfg.yaml`, and run only
the animation phase (a plain `pip install -e .`, no torchserve, no model download).

The remaining real risk is **headless rendering on macOS** (OSMesa is hard on arm64);
the renderer may need a brief GUI window flash to emit a GIF/MP4. That must be
verified by an install+sample task.

## Findings

### 1. Install method on macOS arm64

Two routes ship: Docker and Local Conda. **Docker is broken on M-series** (image is
linux/amd64; `mim install mmcv-full` and `pip install mmpose` fail without hacking
the Dockerfile to CPU wheels + pinned PyTorch).

**Recommended: Local Conda, ML-bypassed** (see Recommendation). If the full ML
pipeline were wanted, the README's `torchserve/setup_macos.sh` is the path — but we
skip it.

- *Citations: [README](https://github.com/facebookresearch/AnimatedDrawings/blob/main/README.md),
  [issue #210](https://github.com/facebookresearch/AnimatedDrawings/issues/210),
  [issue #266](https://github.com/facebookresearch/AnimatedDrawings/issues/266).*

### 2. Dependencies & footprint (full ML path — what we AVOID)

- Python **3.8.13** (strict).
- OpenMMLab stack — **not** Detectron2: `mmdet==2.27.0`, `mmpose==0.29.0`,
  `mmcv-full==1.7.0` on `torch==1.13.0` + `torchserve`.
- Model downloads via `wget`: `drawn_humanoid_detector.mar` (~312 MB) +
  `drawn_humanoid_pose_estimator.mar` (~357 MB) ≈ **~669 MB**.
- **The ML models only generate annotations.** Supply `mask.png` + `char_cfg.yaml`
  yourself and you bypass torchserve + all ML deps + the 669 MB download.

- *Citations: [setup_macos.sh](https://github.com/facebookresearch/AnimatedDrawings/blob/main/torchserve/setup_macos.sh),
  [setup.py](https://github.com/facebookresearch/AnimatedDrawings/blob/main/setup.py),
  [issue #238](https://github.com/facebookresearch/AnimatedDrawings/issues/238).*

### 3. Hardware

- **No CUDA needed.** Runs on CPU (default on the macOS script).
- No out-of-the-box Metal/MPS; runs CPU.
- Rig + animate of one small image: **seconds**, not minutes (torchserve JVM startup
  adds a moment — irrelevant once ML is bypassed).

- *Citations: [setup_macos.sh](https://github.com/facebookresearch/AnimatedDrawings/blob/main/torchserve/setup_macos.sh),
  [issue #310](https://github.com/facebookresearch/AnimatedDrawings/issues/310).*

### 4. Pipeline steps

Two phases:

1. **Annotation** — `image_to_annotations.py`: ML models produce bounding box,
   `mask.png`, `texture.png`, and joint keypoints in `char_cfg.yaml`. (The torchserve
   step — skipped in ML-bypass.)
2. **Animation** — `annotations_to_animation.py` / `render.start()`: reads
   `char_cfg.yaml`, loads a motion config, retargets a BVH motion, deforms a 2D mesh
   via As-Rigid-As-Possible (ARAP), renders output.

- **Automatic:** `python image_to_animation.py drawing.png out_dir` runs both.
- **Manual (our path):** hand-author `mask.png` + `char_cfg.yaml`, jump to phase 2.
  `python fix_annotations.py` gives a web UI to visually fix joints before animating.

- *Citations: [README — Animating Your Own Drawing](https://github.com/facebookresearch/AnimatedDrawings/blob/main/README.md#animating-your-own-drawing).*

### 5. Input requirements (what feeds the animation phase)

A directory containing:

1. `texture.png` — the character image (transparent or solid bg).
2. `mask.png` — black/white mask matching character bounds (= alpha channel of a
   transparent texture).
3. `char_cfg.yaml` — texture width/height + skeletal joints with pixel `loc` and
   `parent` hierarchy (head, shoulders, elbows, wrists, hips, knees, ankles, root).

For the auto ML path: a clear, frontal, bipedal drawing on a plain background works
best; resolution flexible, typically <1080p.

- *Citations: [examples/config/README.md — character config file](https://github.com/facebookresearch/AnimatedDrawings/blob/main/examples/config/README.md#character-config-file).*

### 6. Motions & BVH

- Default BVH motions ship: **walk, dance, jump** (in `examples/bvh/`, configs in
  `examples/config/`).
- **Custom BVH supported.** A different skeleton (e.g. Mixamo/Rokoko) needs a new
  motion config + retarget config mapping the rig.

- *Citations: [README — Using BVH Files with Different Skeletons](https://github.com/facebookresearch/AnimatedDrawings/blob/main/README.md#using-bvh-files-with-different-skeletons).*

### 7. Known issues & maintenance

- **Archived 2024-09-03** — no maintenance by Meta/author. Frozen at PyTorch 1.13 /
  Python 3.8 era.
- **macOS headless rendering**: `USE_MESA: True` relies on OSMesa, hard to configure on
  Apple Silicon → server/CLI render to MP4/GIF is unreliable; renderer tends to open a
  GUI window. **(Risk for our GIF export — must verify.)**
- Docker build broken for M1 without manual patching.

- *Citations: [README](https://github.com/facebookresearch/AnimatedDrawings/blob/main/README.md),
  [issue #100](https://github.com/facebookresearch/AnimatedDrawings/issues/100).*

## Recommendation for our pipeline

**Proceed, ML-bypassed.** Because `agy-image` generates the character, we control the
output: transparent PNG in a frontal A-pose. We derive `mask.png` from the alpha
channel and build `char_cfg.yaml` (static template if the pose is tightly constrained,
or a manual/`fix_annotations.py` step otherwise). This **eliminates the 669 MB model
download, Java/torchserve, and the brittle PyTorch 1.13 + OpenMMLab stack** — leaving
a plain `pip install -e .`.

### Concrete install (macOS arm64, ML-bypassed)

```bash
CONDA_SUBDIRS=osx-arm64 conda create --name animated_drawings python=3.8.13 -y
conda activate animated_drawings
conda env config vars set CONDA_SUBDIRS=osx-arm64
git clone https://github.com/facebookresearch/AnimatedDrawings.git
cd AnimatedDrawings
pip install -e .
# Do NOT run torchserve/setup_macos.sh — we skip the ML phase.
```

### What `agy-image` must output

1. **Transparent PNG**, frontal or slight-angle **A-pose** (arms slightly away from
   body so joints are visible — better for ARAP mesh + joint annotation).
2. We extract the alpha channel → `mask.png`.
3. We supply `char_cfg.yaml` joint pixel coords (template for a constrained A-pose, or
   manual via `fix_annotations.py`).
4. Render target: **GIF** (via the MVC render config). If headless render fails on
   macOS, accept a brief GUI window flash, or render to MP4 and convert.

### Next step (graduates from this research)

An **install + sample-animate task**: run the ML-bypassed install above, then animate a
**sample character from the repo's own examples** (no agy yet) to a GIF on macOS arm64.
This de-risks the two open questions in one shot: (a) does the lightweight install
actually work, and (b) can macOS produce a GIF file (the OSMesa risk). If yes, the
route to a real cozy character is clear; if the GIF export is blocked on macOS, we
re-evaluate (DragonBones runtime, a cloud/Colab render, or accept the existing Godot
scaffold's placeholder demo as the destination).
