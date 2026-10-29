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

- Bait icons are 32×32 placeholders (`assets/bait/`, 334–431 bytes each).
- Catch-card fish portraits are 64×64, except `assets/fish/fishman.png` at 128×128. They are a few kilobytes each.
- `models/lake.glb` (4.5 MB) and `models/World.glb` (3.0 MB) are in the repo and are not instanced in `scenes/main_lake.tscn`. The dock, water, rod, and lure are a box, a plane, a cylinder, and a sphere.
- The HUD uses the default Godot font. There is no title screen, content note, or field journal art. The LÖVE game had those. Screenshots of that build are in `archive/love2d/Screenshots/`.

## Blockers

- **Audio is incomplete.** Chunk 1 is merged. The scripts look for `audio/sfx/whip.ogg`, `sfx_fish_bite_1.ogg`, `reel1.ogg`, `thrash.ogg`, `fighting_loop.ogg`, and `flapping.ogg`. Those files are not in this tree, and the game stays silent when they are missing. What did arrive is `audio/sfx/ambience_apartment_day_loop.ogg` (4.6 MB), `audio/sfx/ambience_apartment_night_loop.ogg` (5.8 MB), and `audio/sfx/weather/592482__baconation__medium-light-rain.mp3` (7.5 MB). The apartment loops are not playing, because they are interior beds and this scene is a lake. There is no rain system to use the rain file. More audio parts are still expected.
- **Shore casts can stick.** A lure that lands on the mainland box never reaches the scripted water plane, so the state can sit on "lure in the air." That is the next fishing-loop fix.
- **Line snap and a missed hook-set** return to idle with no lasting message.
- **The fight does not change as the fish tires.** Stamina drains on the lure and does not yet change reel speed or tension.
- **No shop.** Money is counted and nothing spends it.
- **Cryptid fish** (pale crawler, bleeding carp, whispering eel, fishman) have portraits and are commented out on purpose in `scripts/fish_database.gd`.
- **Web and desktop builds are not published.** Export locally with the table above. Do not upload over the live itch page from this repo.

## License

[MIT](LICENSE). Copyright MungDaal321 / robfernan.

[Robert Fernandez](https://robertfernandez.dev) ([robfernan](https://github.com/robfernan)). The itch page is [MungDaal321](https://mungdaal321.itch.io/hopeless-catch). The hunting twin is [Sportsman's Quest](https://mungdaal321.itch.io/sportsman-quest).

Bugs and ideas: [CONTRIBUTING.md](CONTRIBUTING.md).
