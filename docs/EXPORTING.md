# Exporting Hopeless Catch (Godot 4.7)

Desktop and web builds come from the presets in `export_presets.cfg` at the repo root. Those presets do not store an absolute path to an export template. `custom_template/debug` and `custom_template/release` are empty, so the editor uses the templates installed for the Godot 4.7.x binary you are running.

This document does not publish anything. The live page stays [https://mungdaal321.itch.io/hopeless-catch](https://mungdaal321.itch.io/hopeless-catch) until Robert uploads a build himself.

## Editor and templates

1. Install Godot **4.7.x stable**. 4.7.2 is the current 4.7 maintenance release. A 4.6 editor will refuse the project. A 4.8 editor is out of scope.
2. Install the export templates built for that same version.
   - In the editor: **Editor → Manage Export Templates**, then install the templates for 4.7.x.
   - Or download `Godot_v4.7.x-stable_export_templates.tpz` from the [4.7 archive](https://godotengine.org/download/archive/4.7-stable/) (use the 4.7.2 file if that is the editor you installed) and import the `.tpz` from that same dialog.
3. Open this repo. Confirm **Project → Export** lists Windows Desktop, Linux, macOS, and Web, and that each preset's custom template fields are blank.

`build/` is gitignored. Create it by exporting. The commands below also create the subfolders when the export succeeds.

## Commands

Run these from the repository root. `godot` must be the 4.7.x binary.

```bash
mkdir -p build/windows build/linux build/macos build/web

godot --headless --export-release "Windows Desktop" build/windows/HopelessCatch.exe
godot --headless --export-release "Linux" build/linux/HopelessCatch.x86_64
godot --headless --export-release "macOS" build/macos/HopelessCatch.zip
godot --headless --export-release "Web" build/web/index.html
```

The path on the command line overrides the path stored in the preset. Keeping them the same avoids two different output locations.

| Preset | Platform string | Architecture | Output | Notes |
| --- | --- | --- | --- | --- |
| Windows Desktop | `Windows Desktop` | `x86_64` | `build/windows/HopelessCatch.exe` | PCK is embedded. A debug export also writes a console wrapper. |
| Linux | `Linux` | `x86_64` | `build/linux/HopelessCatch.x86_64` | PCK is embedded. Mark the binary executable after copy to another machine if the mode bit is lost. |
| macOS | `macOS` | `universal` (Apple silicon and Intel) | `build/macos/HopelessCatch.zip` | Bundle id `dev.robertfernandez.hopelesscatch`. Not notarized. Codesign identity is empty, so Godot ad-hoc signs when it must. |
| Web | `Web` | — | `build/web/index.html` plus `.wasm`, `.pck`, and the rest of the shell | Threads are **off**. |

## Web, itch, and headers

`variant/thread_support` is false. A threaded Godot web build needs `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` on every response. itch.io and GitHub Pages do not send those headers. The old LÖVE page had the same constraint, which is why `archive/love2d/Love2d_Web/serve.py` existed.

With threads off, a static host can serve `build/web/`. Open `index.html` through a local static server during a test. Some browsers block the wasm file from a `file://` URL.

```bash
python3 -m http.server 8060 --directory build/web
```

Then open `http://localhost:8060/`. Click the canvas before expecting the mouse or audio to lock. Ambience beds are OGG Vorbis. The six fishing cues are the oggs in `audio/sfx/`. `AudioSynth` is the fallback when one of those files is missing, and it also supplies snap, miss, dock steps, UI clicks, and the night splash. Bus trims are Master 0 dB, Music −12, Ambience −16, SFX −6, UI −10. Focus loss still mutes Master.

The project renderer is Forward+. That is what Robert's scene and water shader were authored for. If a browser cannot start the 3D view, that is a web-renderer limit to report, not a reason to switch the whole project to Compatibility in this repo without checking the water shader (`shaders/about_fishing_water.gdshader` reads the depth and screen textures).

Texture compression for web is desktop S3TC/BPTC (`vram_texture_compression/for_desktop=true`). Mobile ETC2/ASTC is off.

## What you get, and what you do not

- Windows, Linux, macOS, and Web each have one preset.
- There is no Android, iOS, or console preset.
- Shader baker is off.
- Nothing in this process uploads to itch. Butler credentials are not stored here.
