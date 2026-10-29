# Hopeless Catch

A cozy fishing game with a dark secret.

**[Play in the browser](https://mungdaal321.itch.io/hopeless-catch)** · [Robert Fernandez](https://robertfernandez.dev)

![A pixel fisherman on a wooden dock, line in a blue lake, with mountains and a pale sun behind the clouds](Screenshots/Itch_io/Game.png)

You spend the day on the dock at Lake Acheron. Pick a bait, cast, wait on the bobber, and reel the fish in before the line snaps. The clock runs. Rest in the cabin and the next morning starts on the same pier, with different weather.

The first screen is a content note for the [Horror Fishing Game Jam](https://itch.io/jam/the-fishing-horror-jam). The field journal keeps another line on every fish you land, and it tells you to leave the water past the red buoy alone after midnight.

## How to play

On the title menu, choose **Begin Fishing**. Up and Down, or W and S, move the cursor. Space or Enter selects. Space also skips the opening note.

1. Hold **Space** to charge the cast. Release to throw. A longer hold drops the bobber farther out.
2. Wait. Hold Space while the lure sits if you want it back.
3. When the bobber dives, press **Space** to set the hook.
4. Hold **Space** to reel. Release when line tension flashes danger. A full bar snaps the line.
5. Space closes the catch card. Tab opens the journal, where the catch is written down.
6. **H** rests in the cabin and starts the next day. Day one is clear. Later days bring rain, fog, and storms.

| Action | Key |
| --- | --- |
| Walk the dock | A / D, or Left / Right |
| Cast, hook, and reel | Space (Enter does the same) |
| Bait box | B |
| Field journal | Tab |
| Rest in the cabin | H |
| Pause | Esc |
| Restart | F5 |

The hint bar along the bottom says WASD. On the dock, left and right are what move you. W and S are for menus.

The bait box starts with fat worms, sweet corn, live minnows, pungent cheese, and rotten offal. Click a compartment, or choose one with the arrow keys and Enter. Daylight fish include sunfish, bass, trout, catfish, and a rare golden carp. Some of them prefer a specific bait.

## Run it

**Browser.** [mungdaal321.itch.io/hopeless-catch](https://mungdaal321.itch.io/hopeless-catch). Click the game once so the keys and audio focus. The page lists the project as in development, with HTML5 and Windows builds. Fullscreen is the 16:9 view.

**LÖVE, from this repo.** `Love2d Version/HopelessCatch_Source/conf.lua` targets LÖVE 11.4 at 1280×720. The itch.io page recommends [LÖVE 11.5](https://love2d.org/). 11.4 and 11.5 both match this project:

```bash
cd "Love2d Version/HopelessCatch_Source"
love .
```

The packaged game file is `Love2d Version/dist/love/HopelessCatch.love`. Open it with LÖVE, or from the repo root:

```bash
love "Love2d Version/dist/love/HopelessCatch.love"
```

**Windows, without installing LÖVE.** Run `Love2d Version/dist/windows/HopelessCatch.exe` from that folder, so it sits next to its DLLs. The same build is zipped at `Love2d Version/dist/HopelessCatch-Windows.zip`.

**Earlier browser build in the repo.** `Love2d_Web/` is a separate 800×600 scene. From the repository root:

```bash
python3 Love2d_Web/serve.py
```

Open [http://localhost:3000/](http://localhost:3000/) and click the canvas before using the keyboard. That server sends the `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` headers the WebAssembly build needs. GitHub Pages does not send those headers, so the playable page is the itch.io link above. Ctrl+C stops the server.

## What ships

| | |
| --- | --- |
| Playable today | Browser build on itch.io. A Windows `.exe` and a `.love` file are in this repo and on that page. |
| Source | LÖVE / Lua in `Love2d Version/HopelessCatch_Source` |
| macOS, Linux, Steam Deck | LÖVE with the source folder or the `.love` file. This repo has no separate app bundle for those systems. |
| Status | In development, as listed on itch.io. The current source has the dock, cast, reel, journal, bait box, day and night cycle, and weather. |
| Screenshots | `Screenshots/Itch_io/` is the dock game. `Screenshots/Love2D_Web/` is the earlier browser scene. |

## Also on the dock

![Title menu over a night lake, with Begin Fishing selected](Screenshots/Itch_io/StartMenu.png)

![Tackle tray listing fat worms, sweet corn, live minnows, pungent cheese, and rotten offal](Screenshots/Itch_io/tacklebox.png)

## Star

If you would send someone to this dock, star the repository. That is the whole ask.

## License and credits

[MIT](LICENSE). Copyright MungDaal321 / robfernan.

[Robert Fernandez](https://robertfernandez.dev) ([robfernan](https://github.com/robfernan)). The itch.io page is published as [MungDaal321](https://mungdaal321.itch.io/hopeless-catch).

Built with [LÖVE](https://love2d.org/). The itch.io page credits Aseprite for the pixel art. The in-repo browser port uses [love.js](https://github.com/Davidobot/love.js). Made for the [Horror Fishing Game Jam](https://itch.io/jam/the-fishing-horror-jam).

Bugs and ideas: [CONTRIBUTING.md](CONTRIBUTING.md). Notes on the browser port: [Love2d_Web/README.md](Love2d_Web/README.md).
