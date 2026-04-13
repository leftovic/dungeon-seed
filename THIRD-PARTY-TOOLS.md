# Game Dev Pipeline — Third-Party CLI Tools & Environments

> **Purpose**: Catalog every CLI tool agents need, installation instructions, and Docker container strategy
> **Status**: Planning

---

## Required CLI Tools

### Tier 1: Core (Required by 80%+ of agents)

| Tool | Purpose | Install | License | Used By |
|------|---------|---------|---------|---------|
| **Blender 4.x** | 3D modeling, sculpting, rigging, rendering, Python scripting | `choco install blender` / `apt install blender` / [blender.org](https://blender.org) | GPL | ALL sculptors, Procedural Asset Gen, Scene Compositor, Animation agents |
| **ImageMagick 7** | Image manipulation, sprite sheets, palette ops, compositing | `choco install imagemagick` / `apt install imagemagick` | Apache 2.0 | ALL 2D agents, icon generation, texture work |
| **Python 3.11+** | Scripting, code generation, validation, automation | `choco install python` / `apt install python3` | PSF | ALL agents (universal scripting) |
| **ffmpeg** | Video/audio processing, GIF preview generation, format conversion | `choco install ffmpeg` / `apt install ffmpeg` | LGPL/GPL | VFX, Audio, Animation preview, any video output |
| **Node.js 20+** | JSON processing, manifest generation, tooling scripts | `choco install nodejs` / `apt install nodejs` | MIT | Manifest generation, validation scripts |
| **Git** | Version control for all generated assets | Pre-installed | GPL | ALL agents |

### Tier 2: Domain-Specific (Required by specific agent clusters)

| Tool | Purpose | Install | License | Used By |
|------|---------|---------|---------|---------|
| **Godot 4.x CLI** | Game engine headless mode, scene validation, export | `choco install godot` / [godotengine.org](https://godotengine.org) | MIT | Game Code Executor, scene validation, all engine-output agents |
| **Aseprite CLI** | Pixel art creation, animation frames, palette management | `choco install aseprite` / [aseprite.org](https://aseprite.org) ($20) | Proprietary | Sprite Generator, 2D Asset Renderer, pixel art agents |
| **gdtoolkit** | GDScript linter/formatter | `pip install gdtoolkit` | MIT | Game Code Executor, Code Style Enforcer |
| **Tiled CLI** | Tilemap editor, TMX format export | `choco install tiled` / [mapeditor.org](https://mapeditor.org) | GPL | Tilemap Level Designer |
| **sox** | Audio processing, effects, format conversion | `choco install sox` / `apt install sox` | GPL | Audio Composer, Game Audio Director |
| **SuperCollider** | Algorithmic music composition, sound synthesis | [supercollider.github.io](https://supercollider.github.io) | GPL | Audio Composer |
| **LMMS** | Music production (limited CLI) | `choco install lmms` / `apt install lmms` | GPL | Audio Composer |
| **Inkscape CLI** | SVG vector art generation/manipulation | `choco install inkscape` / `apt install inkscape` | GPL | 2D Asset Renderer, UI Designer, vector art |
| **GIMP CLI** | Advanced image editing via Script-Fu | `choco install gimp` / `apt install gimp` | GPL | Texture Artist, 2D Asset Renderer |

### Tier 3: Validation & Pipeline (Build/test/validate)

| Tool | Purpose | Install | License | Used By |
|------|---------|---------|---------|---------|
| **gltf-pipeline** | glTF optimization, Draco compression | `npm install -g gltf-pipeline` | Apache 2.0 | 3D Pipeline Specialist, all 3D export |
| **gltf-validator** | glTF format validation | `npm install -g gltf-validator` | Apache 2.0 | 3D Pipeline Specialist |
| **meshoptimizer** | Mesh optimization, LOD generation | Build from source / `vcpkg install meshoptimizer` | MIT | 3D Pipeline Specialist |
| **PVRTexTool** | Texture compression (PVRTC, ASTC, ETC) | [imaginationtech.com](https://imaginationtech.com) | Free | VR/Mobile optimization |
| **texconv** | DirectX texture conversion | [github.com/microsoft/DirectXTex](https://github.com/microsoft/DirectXTex) | MIT | Texture Artist |
| **Docker** | Containerized agent environments | `choco install docker-desktop` | Apache 2.0 | ALL agents (optional) |
| **Pillow (Python)** | Image processing library | `pip install Pillow` | MIT | Most visual agents |
| **numpy** | Numerical operations for procedural generation | `pip install numpy` | BSD | Procedural generation agents |
| **noise** | Perlin/simplex noise for terrain/textures | `pip install noise` | MIT | Terrain, Texture, World agents |
| **trimesh** | Mesh analysis and validation | `pip install trimesh` | MIT | 3D validation |

---

## Python Package Requirements

```
# requirements-gamedev.txt
Pillow>=10.0
numpy>=1.24
noise>=1.2.2
trimesh>=4.0
scipy>=1.11
networkx>=3.1        # Graph algorithms for level connectivity
pydub>=0.25          # Audio manipulation
mido>=1.3            # MIDI processing
svgwrite>=1.4        # SVG generation
lxml>=4.9            # XML processing for Tiled TMX
jsonschema>=4.19     # Asset manifest validation
```

---

## Docker Container Strategy

### Why Docker?
Agents need consistent environments with ALL tools pre-installed. Rather than requiring every developer/machine to have Blender, Godot, Aseprite, etc., we provide Docker images where agents "hop in and go."

### Container Tiers

#### `gamedev-base` — Foundation layer
```dockerfile
FROM ubuntu:24.04
# Core tools every agent needs
RUN apt-get update && apt-get install -y \
    python3 python3-pip nodejs npm git \
    imagemagick ffmpeg sox inkscape gimp \
    && pip3 install -r requirements-gamedev.txt
```

#### `gamedev-3d` — 3D modeling agents (extends base)
```dockerfile
FROM gamedev-base
# Blender + 3D pipeline tools
RUN apt-get install -y blender \
    && npm install -g gltf-pipeline gltf-validator \
    && pip3 install trimesh meshio
# Pre-install Blender addons: sapling-tree-gen, auto-rig-pro (if licensed)
```

#### `gamedev-2d` — 2D art agents (extends base)
```dockerfile
FROM gamedev-base
# Aseprite (must provide own binary — commercial license)
# Tiled map editor
RUN apt-get install -y tiled \
    && pip3 install Pillow svgwrite
# Mount point for Aseprite binary: /opt/aseprite/
```

#### `gamedev-audio` — Audio agents (extends base)
```dockerfile
FROM gamedev-base
# Audio synthesis and processing
RUN apt-get install -y supercollider lmms \
    && pip3 install pydub mido
```

#### `gamedev-engine` — Godot runtime (extends 3d)
```dockerfile
FROM gamedev-3d
# Godot headless for scene validation and export
RUN wget https://github.com/godotengine/godot/releases/download/4.x/Godot_v4.x_linux.x86_64.zip \
    && unzip -d /opt/godot/ && ln -s /opt/godot/Godot_* /usr/local/bin/godot
RUN pip3 install gdtoolkit
```

#### `gamedev-full` — Everything (for Game Orchestrator)
```dockerfile
FROM gamedev-engine
# Audio tools on top of engine
RUN apt-get install -y supercollider lmms
# This is the "kitchen sink" — only for orchestrator/testing
```

### Container Usage Pattern
```bash
# Agent runs inside container with project mounted
docker run --rm -v $(pwd)/game-project:/project gamedev-3d \
    blender --background --python /project/scripts/generate-character.py

# Or interactive session for debugging
docker run -it -v $(pwd)/game-project:/project gamedev-full bash
```

### Container Registry
Images pushed to project container registry (GitHub Container Registry or ACR):
- `ghcr.io/{org}/gamedev-base:latest`
- `ghcr.io/{org}/gamedev-3d:latest`
- `ghcr.io/{org}/gamedev-2d:latest`
- `ghcr.io/{org}/gamedev-audio:latest`
- `ghcr.io/{org}/gamedev-engine:latest`
- `ghcr.io/{org}/gamedev-full:latest`

---

## Agent → Container Mapping

| Agent Cluster | Container | Key Tools |
|--------------|-----------|-----------|
| ALL Sculptors (11) | `gamedev-3d` | Blender, ImageMagick, glTF tools |
| 2D Asset Renderer | `gamedev-2d` | Aseprite, ImageMagick, Inkscape, GIMP |
| Sprite Generator | `gamedev-2d` | Aseprite, ImageMagick |
| Animation Sequencer | `gamedev-2d` + `gamedev-engine` | Aseprite, Godot (for .tres generation) |
| 3D Pipeline Specialist | `gamedev-3d` | Blender, glTF tools, meshoptimizer |
| VR XR Asset Optimizer | `gamedev-3d` | Blender, PVRTexTool, performance tools |
| Texture & Material Artist | `gamedev-3d` | Blender (shader nodes), GIMP, ImageMagick |
| Audio Composer | `gamedev-audio` | SuperCollider, sox, ffmpeg, LMMS |
| Game Code Executor | `gamedev-engine` | Godot, gdtoolkit, Python |
| Tilemap Level Designer | `gamedev-2d` + `gamedev-engine` | Tiled, Godot, Python |
| VFX Designer | `gamedev-engine` | Godot (particles), ImageMagick, ffmpeg |
| Game UI Designer | `gamedev-engine` | Godot, Inkscape, ImageMagick |
| HUD Engineer | `gamedev-engine` | Godot, Python |
| Scene Compositor | `gamedev-full` | Everything |
| Game Orchestrator | `gamedev-full` | Everything (coordination) |

---

## Artificer Tasks

1. **Build Dockerfiles** for all 6 container tiers
2. **Build `requirements-gamedev.txt`** with pinned versions
3. **Build `install-gamedev-tools.ps1`** for local (non-Docker) setup on Windows
4. **Build `install-gamedev-tools.sh`** for local setup on Linux/Mac
5. **Build `validate-environment.py`** — checks all tools are installed and correct versions
6. **Build container CI/CD** — GitHub Actions to build/push images on tool version updates
