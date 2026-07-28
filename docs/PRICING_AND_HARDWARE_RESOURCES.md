# Pricing, Licensing & Hardware Resource Guide for Game Dev AI Tools

**Date:** July 23, 2026  
**Target:** Cost Breakdown & System Requirements for Antigravity & Pi Agent Game Dev Stack

---

## 1. Executive Cost Summary

The vast majority of the core stack (Godot 4, Blender, Blender MCP, Meta AnimatedDrawings, Mixamo, GUT Testing, and Python SFX) is **100% FREE and Open-Source**. 

You can build a complete game from scratch with **$0 upfront cost**. Optional paid cloud APIs (like Meshy, ElevenLabs, or Replicate) are only needed if you want fast cloud-hosted 3D generation instead of local generation.

---

## 2. Detailed Tool Pricing & License Breakdown

| Tool / Framework | Category | Cost / Pricing Model | License | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Godot 4.x Engine** | Game Engine | **100% FREE** | MIT License | Zero royalties, zero subscription. Completely free for commercial use. |
| **`hi-godot/godot-ai` & GUT** | MCP & Testing | **100% FREE** | MIT License | Open-source agent plugins & testing framework. |
| **Blender & Blender MCP** | 3D Engine & MCP | **100% FREE** | GPL License | Full 3D modeling, rigging, keyframing, and MCP bridge. |
| **Meta `AnimatedDrawings`** | 2D AI Rigging | **100% FREE** | MIT License | Open-source Meta research project for local 2D image animation. |
| **Adobe Mixamo** | 3D Auto-Rigging | **100% FREE** | Adobe Free | Requires free Adobe login. Commercial game export allowed. |
| **Aseprite CLI** | 2D Pixel Art | **$20 One-time** (or **FREE** if compiled from source) | Educational / Source-Available | Industry standard for pixel art animation. |
| **`python-sfxr` / `jsfxr`** | Audio SFX | **100% FREE** | MIT License | Code-first retro sound synthesizer. |
| **Meshy API** (Optional) | Cloud 3D Generation | **Freemium** (~20 free credits/mo, then $20/mo) | Commercial API | Cloud text-to-3D / image-to-3D mesh generation. |
| **Replicate API** (Optional) | Cloud AI Models | **Pay-as-you-go** (~$0.01 - $0.05 per 3D model) | Per-second GPU cost | Hosts Hunyuan3D, Stable Diffusion, and TripoSR APIs. |
| **ElevenLabs SFX** (Optional) | Cloud AI Audio | **Freemium** (10,000 chars free/mo, then $5/mo) | Commercial API | High-fidelity text-to-sound-effects. |

---

## 3. Hardware System Requirements & Resource Overhead

### A. Low-Resource Local Stack (Runs on ANY Standard Mac or Laptop)
* **Tools Used:** Godot 4, Blender CLI, Meta `AnimatedDrawings`, Mixamo API, `python-sfxr`, GUT testing.
* **CPU:** Apple Silicon (M1/M2/M3/M4) or Intel Core i5/i7/AMD Ryzen.
* **RAM / Memory:** 8 GB – 16 GB RAM.
* **GPU / VRAM:** Integrated Graphics (Apple Silicon GPU or Intel Xe / AMD Radeon).
* **Disk Space:** ~5 GB storage total (Godot is ~100MB, Blender is ~500MB).
* **Verdict:** Highly lightweight. Your Mac can run this stack with zero lag.

---

### B. Heavy Local AI Model Stack (Self-Hosting Local Hunyuan3D / ComfyUI)
* **Tools Used:** Self-hosted local Hunyuan3D-2.0, local Stable Diffusion / ComfyUI, local TripoSR.
* **CPU:** Modern 8-core CPU.
* **RAM / Memory:** 16 GB – 32 GB RAM (or Apple Silicon 24GB+ Unified Memory).
* **GPU / VRAM:** NVIDIA GPU with **8 GB – 16 GB+ VRAM** (e.g. RTX 3080/4070/4080) OR Apple Silicon M-series with 24GB+ Unified Memory.
* **Disk Space:** 50 GB – 100 GB (for AI model checkpoints).
* **Verdict:** Only needed if you want to generate complex 3D meshes locally offline without paying cloud API fees.

---

## 4. Recommended Setup for Antigravity & Pi Agent

### **Option 1: The $0 100% Free Stack (Recommended to Start)**
* **Engine:** Godot 4.3+ (Free)
* **2D Assets & UI:** Built-in `generate_image` + `python-sfxr` (Free)
* **2D Character Animation:** Meta `AnimatedDrawings` Python CLI (Free)
* **3D Character Rigging & Mocap:** Blender + Mixamo Automation API (Free)
* **Testing:** GUT (Godot Unit Test) (Free)
* **Total Cost:** **$0.00**
* **Hardware Needed:** Standard Mac/PC (no heavy GPU required).

### **Option 2: Cloud-Enhanced Stack (Fastest High-Fidelity Pipeline)**
* **Option 1 Stack** plus:
* **3D Mesh Generation:** Meshy API ($20/mo or pay-per-credit) or Replicate API (~$2-$5 total for an entire game).
* **Audio SFX:** ElevenLabs SFX API (Free tier or $5/mo).
* **Total Cost:** **~$5 – $20 total**
* **Hardware Needed:** Standard Mac/PC (cloud handles heavy AI compute).
