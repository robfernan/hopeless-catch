# Archived LÖVE build

This folder is the previous Hopeless Catch, kept so the Godot 4.7 project can own the repository root. It is not the game to run or ship.

| Path | What it was |
| --- | --- |
| `Love2dVersion/` | LÖVE 11.4 source, the `.love` package, and the Windows build. The old path was `Love2d Version/`. |
| `Love2d_Web/` | Separate 800×600 browser scene and the love.js notes. |
| `pages/` | The old GitHub Pages bundle (`index.html`, `love.wasm`, `game.data`). It lived at `dist/`. |
| `Screenshots/` | itch.io and early browser screenshots of the LÖVE game. |

The live page is still https://mungdaal321.itch.io/hopeless-catch. Those builds can keep serving until a Godot export is published by hand.

To run the archived desktop game, install [LÖVE 11.5](https://love2d.org/) and open `Love2dVersion/HopelessCatch_Source` or `Love2dVersion/HopelessCatch.love`. The web scene's local server is `Love2d_Web/serve.py`.
