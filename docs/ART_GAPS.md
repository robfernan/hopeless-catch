# Art gaps for the Game Art Director

Inventory of what the Godot 4.7 scene actually shows, versus files that are only sitting in the tree. This is a gap list. It does not pick a new style.

The playable scene is `scenes/main_lake.tscn`.

## What the player sees today

These are generated primitives inside the scene, not authored models:

| Piece | Scene node | Mesh |
| --- | --- | --- |
| Water | `WaterPlane` | 300×300 plane, shader `shaders/about_fishing_water.gdshader` |
| Lake bed | `LakeBed` | 350×350 plane, flat color |
| Mainland | `MainlandCoast` | Box 160×2.5×90, sand color. Texture `materials/sand.png` (582 KB) is not assigned to this mesh. |
| Dock | `Dock/Planks` | Box 3.5×0.35×16 |
| Pilings | `Dock/Piling1`–`Piling4` | Cylinders |
| Rod | `Player/Camera3D/RodPivot/RodMesh` | Cylinder |
| Lure | `Lure/MeshInstance3D` | Red sphere |

Instanced models:

| File | Bytes | Where |
| --- | --- | --- |
| `models/hands.glb` | 397440 | On the rod pivot |
| `models/rocks.glb` | 26604 | Two instances, left and right of the dock |
| `models/tree.glb` | 28988 | Two instances on the shore |

Fish meshes are not placed in the lake. `scripts/fish_database.gd` points at them and `scripts/player_controller.gd` instances one when a hook is set, then again as the trophy pose.

| File | Bytes | Catalog name |
| --- | --- | --- |
| `models/fish/bluegill.glb` | 404852 | Sunfish |
| `models/fish/large_mouth_bass.glb` | 442048 | Bass |
| `models/fish/rainbow_trout.glb` | 448368 | Trout |
| `models/fish/catfish.glb` | 194056 | Catfish |
| `models/fish/Carp.glb` | 209328 | Golden Carp |

## Environment meshes not in the scene

These import and then nothing references them from `scenes/main_lake.tscn`:

| File | Bytes |
| --- | --- |
| `models/lake.glb` | 4530796 |
| `models/World.glb` | 3035108 |

A large set of loose textures sits beside them under `models/` (`World_*.png`, `lake_*.png`, `Trees_*.png`, pine and leaf sheets). They are the source textures for those glbs or for meshes that were never dropped into the dock scene. The bait-shop sheet `models/World_bait_shop_exterior.png` (769 KB) has no shop in the playable scene.

## UI and portrait files

Catch card and tackle box read these at runtime. They are tiny:

| File | Size | Bytes |
| --- | --- | --- |
| `assets/bait/worms.png` | 32×32 | 414 |
| `assets/bait/corn.png` | 32×32 | 334 |
| `assets/bait/minnows.png` | 32×32 | 431 |
| `assets/bait/cheese.png` | 32×32 | 369 |
| `assets/fish/sunfish.png` | 64×64 | 1922 |
| `assets/fish/bass.png` | 64×64 | 1236 |
| `assets/fish/trout.png` | 64×64 | 1198 |
| `assets/fish/catfish.png` | 64×64 | 1294 |
| `assets/fish/golden_carp.png` | 64×64 | 1474 |

Portraits for fish that are commented out of the catalog (still on disk, not shown):

| File | Size | Bytes |
| --- | --- | --- |
| `assets/fish/pale_crawler.png` | 64×64 | 1205 |
| `assets/fish/bleeding_carp.png` | 64×64 | 1386 |
| `assets/fish/whispering_eel.png` | 64×64 | 1349 |
| `assets/fish/fishman.png` | 128×128 | 3344 |

The HUD labels (`DisciplineLabel`, `StatusLabel`, `WarningLabel`, catch card, tackle box) use the engine default font. There is no theme resource.

`icon.svg` (92 KB) is the project icon.

## Not ported from the LÖVE game

The archived game in `archive/love2d/` had a title menu, a horror-jam content note, a field journal, and the dock screenshots under `archive/love2d/Screenshots/Itch_io/`. None of those screens exist in the Godot scene. The Godot tackle box also has no rotten-offal bait. The LÖVE bait list included it.

## Audio that is not the lake bed

Apartment day and night loops are the optimized cabin beds. `AudioDirector.set_cabin_interior()` can start them later. The lake scene does not call it. Fishtank, outside-apartment, and church files are not the dock bed. The dock bed is `ambience_lake_V4` / `ambience_lake_V5` and `birds/BirdsAmbience`. Rain is not running; the hook is `AudioDirector.set_raining()` and the file is `weather/rain_loop.ogg`. Cast, bite, reel, splash, fight, and flap are the six oggs already in `audio/sfx/`. `AudioSynth` runs only if one of those files is absent.
