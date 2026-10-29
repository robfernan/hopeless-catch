# Contributing to Hopeless Catch

The game at the repository root is a Godot 4.7 project. The LÖVE sources are archived under `archive/love2d/` and are not the active target.

## Setup

1. Install Godot 4.7.x stable. Do not use 4.6 or 4.8 for this repo.
2. Open the repository root (`project.godot`) and run the main scene, `scenes/main_lake.tscn`.
3. Export notes are in `docs/EXPORTING.md`. Leave `custom_template` paths empty in `export_presets.cfg`.

## Making a change

1. Branch from `main`.
2. Keep `config/features` on `4.7`.
3. Play the cast, bite, and reel loop in the editor before opening a pull request.
4. If you add or remove art, update `docs/ART_GAPS.md` with the path and the file size. Do not invent a new art direction in code comments.
5. Do not publish over the live itch page from a pull request. That upload is Robert's.

## Reporting issues

Include the Godot version, the platform, and the fishing state you were in (idle, charging, waiting, biting, fighting, caught). Audio files beyond the first chunk may still be missing. Check the README blockers before filing a silence bug.
