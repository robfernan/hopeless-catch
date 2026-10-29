# Hopeless Catch

A cozy fishing game with a dark secret. This repository is the **Godot 4.7** source of truth, the fishing twin of [Sportsman's Quest](https://mungdaal321.itch.io/sportsman-quest) (hunting). Both games target **Godot 4.7** stable. Do not open this project in a later major or minor line.

**[Play in the browser](https://mungdaal321.itch.io/hopeless-catch)** · [Robert Fernandez](https://robertfernandez.dev)

The itch page is still the live build. It can lag behind this tree until Robert publishes a new Godot export. This repo does not replace that page.

You stand on a dock, pick a bait, charge a cast, and fight the fish on the line. The clock runs from day into night. The LÖVE game that used to live at the repo root is archived under [`archive/love2d/`](archive/love2d/README.md). Git history still has it.

## Run it

Install [Godot 4.7.x stable](https://godotengine.org/download/archive/4.7-stable/) (4.7 through 4.7.2). `project.godot` sets `config/features` to `4.7` and Forward+. The main scene is `res://scenes/main_lake.tscn`.

Open this folder in the Godot 4.7 editor and press F5, or from the repo root:

```bash
godot --path .
```

The window is 1280×720. Click the view once so the mouse is captured. Esc releases it.

| Action | Input |
| --- | --- |
| Look | Mouse (click the view first) |
| Walk | W A S D |
| Cast | Hold left-click, release to throw |
| Set the hook | Left-click when the bite warning shows |
| Reel | Hold right-click |
| Baitcaster thumb brake | Hold Space while the lure is in the air |
| Untangle a backlash | Tap Space |
| Tackle box | B or Tab (only while idle or waiting on a bite) |
| Flashlight | F |
| PS1-style dither | P |
| Reel discipline | 1 spinning, 2 baitcaster, 3 spincast, 4 fly (only while idle) |
| Keep / release a catch | Left-click or Space keeps. Right-click releases. |

Gamepad is claimed for this build. Left stick or the d-pad walks. South button casts and sets the hook. Right trigger reels. Left trigger is the thumb brake. North button opens the tackle box.

## Export

Presets live in [`export_presets.cfg`](export_presets.cfg). Template paths are empty on purpose, so Godot uses the export templates installed for that editor. Do not commit a machine-local `custom_template` path.

Install templates that match the editor (Editor → Manage Export Templates, or the 4.7.x `export_templates.tpz` from the same download page). Then, from the repo root:

| Target | Preset name | Output | Command |
| --- | --- | --- | --- |
| Windows x86_64 | `Windows Desktop` | `build/windows/HopelessCatch.exe` | `godot --headless --export-release "Windows Desktop" build/windows/HopelessCatch.exe` |
| Linux x86_64 | `Linux` | `build/linux/HopelessCatch.x86_64` | `godot --headless --export-release "Linux" build/linux/HopelessCatch.x86_64` |
| macOS universal | `macOS` | `build/macos/HopelessCatch.zip` | `godot --headless --export-release "macOS" build/macos/HopelessCatch.zip` |
| Web | `Web` | `build/web/index.html` | `godot --headless --export-release "Web" build/web/index.html` |

`build/` is gitignored. Step-by-step notes, including why the web preset ships with threads off, are in [docs/EXPORTING.md](docs/EXPORTING.md).

## What is in this tree

| | |
| --- | --- |
| Engine | Godot 4.7, Forward+ |
| Playable scene | Dock, primitive water, cast, bite, reel, four reel disciplines, tackle box, day/night, flashlight |
| Fish in the catalog | Sunfish, bass, trout, catfish, golden carp. Night cryptids are still commented out in `scripts/fish_database.gd`. |
| Models used by the scene | `models/hands.glb`, `models/rocks.glb`, `models/tree.glb`. Fish glbs are spawned from script when a fish is hooked. |
| Audio on disk | One chunk only. See blockers. |
| Old LÖVE game | `archive/love2d/` |

## Art gaps (for the Game Art Director)

No new art direction is proposed here. The playable scene is still mostly primitive meshes. Full paths and pixel sizes are in [docs/ART_GAPS.md](docs/ART_GAPS.md).

- P0 sheets from `art/hc-p0-dropins` are in `assets/` and wired: splash, tackle box, HUD bar, rotten offal. Bait icons besides offal are still 32×32 (`assets/bait/`, 334–431 bytes).
- Catch-card fish portraits are 64×64, except `assets/fish/fishman.png` at 128×128. They are a few kilobytes each.
- `models/lake.glb` and `models/World.glb` are instanced in `scenes/main_lake.tscn`. Their imported collision is off so the dock and the water-height test still own play. The dock, water, rod, and lure primitives are still there. `World.glb` is the store mesh, placed on the shore. There is no `models/dock.glb`.
- The HUD uses the default Godot font. There is no title screen, content note, or field journal art. The LÖVE game had those. Screenshots of that build are in `archive/love2d/Screenshots/`.

## Blockers

- **The six player cues are on disk.** Cast, bite, reel, splash, fight, and flap use `whip.ogg`, `sfx_fish_bite_1.ogg`, `reel1.ogg`, `thrash.ogg`, `fighting_loop.ogg`, and `flapping.ogg` on the SFX bus. `AudioSynth` plays only when `ResourceLoader.exists` fails for one of those paths. Snap, a missed hook, dock steps, flashlight and tackle clicks, the catch chime, and the night wrong-splash are procedural. Fight and flap loop. Bus trims relative to Master are Music −12 dB, Ambience −16 dB, SFX −6 dB, and UI −10 dB. Web audio waits for a click or key, and losing window focus mutes Master. The dock bed is `ambience_lake_V4` by day and `ambience_lake_V5` at night, with `birds/BirdsAmbience` on the day side. Apartment day/night are the optimized cabin beds only (`AudioDirector.set_cabin_interior()`); the lake does not play them, and church loops are not the lake. A fight ducks Ambience 4 dB, lifts SFX, and raises the fight-loop pitch with tension. Snap, a missed hook, the catch chime, dock steps, and UI clicks are procedural. Night adds a quieter ambience floor and a rare distant wrong-splash. Nothing in the lake scene turns rain on; `AudioDirector.set_raining()` uses `weather/rain_loop.ogg`.
- **Shore casts** can be reeled back. A missed hook and a snapped line leave a message. Fish stamina changes how hard the line pulls and how fast it comes in.
- **P1 art slots** are listed in `assets/ART_P1_SLOTS.md`. Those files were not invented. `models/bobber.glb` and `models/buoy_red.glb` are not in the tree.
- **No shop.** Money is counted and nothing spends it.
- **Cryptid fish** (pale crawler, bleeding carp, whispering eel, fishman) have portraits and are commented out on purpose in `scripts/fish_database.gd`.
- **Web and desktop builds are not published.** Export locally with the table above. Do not upload over the live itch page from this repo.

## License

[MIT](LICENSE). Copyright MungDaal321 / robfernan.

[Robert Fernandez](https://robertfernandez.dev) ([robfernan](https://github.com/robfernan)). The itch page is [MungDaal321](https://mungdaal321.itch.io/hopeless-catch). The hunting twin is [Sportsman's Quest](https://mungdaal321.itch.io/sportsman-quest).

Bugs and ideas: [CONTRIBUTING.md](CONTRIBUTING.md).
