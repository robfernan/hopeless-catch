# P1 art slots

Paths match `scripts/fish_database.gd` and `scripts/tackle_box.gd`. No `_icon` suffix. No new PNGs or meshes were generated for these slots.

| Path | Target | On disk now |
| --- | --- | --- |
| `assets/bait/worms.png` | 64×64 | Yes, still 32×32 (414 bytes). Keep until Art upgrades it. |
| `assets/bait/corn.png` | 64×64 | Yes, still 32×32 (334 bytes). |
| `assets/bait/minnows.png` | 64×64 | Yes, still 32×32 (431 bytes). |
| `assets/bait/cheese.png` | 64×64 | Yes, still 32×32 (369 bytes). |
| `assets/bait/rotten_meat.png` | 64×64 | Yes. P0 sheet, wired as Offal. |
| `assets/fish/sunfish.png` | portrait | Yes, 64×64. Catalog texture path. |
| `assets/fish/bass.png` | portrait | Yes, 64×64. |
| `assets/fish/trout.png` | portrait | Yes, 64×64. |
| `assets/fish/catfish.png` | portrait | Yes, 64×64. |
| `assets/fish/golden_carp.png` | portrait | Yes, 64×64. |
| `assets/fish/pale_crawler.png` | portrait | File exists. Night catalog entry is still commented out, so it does not spawn. |
| `assets/fish/bleeding_carp.png` | portrait | File exists. Night entry commented out. |
| `assets/fish/whispering_eel.png` | portrait | File exists. Night entry commented out. |
| `assets/fish/fishman.png` | portrait | File exists. Night entry commented out. |
| `assets/ui/catch_card.png` | 420×520, fish slot 256×128 | No. Brass panel placeholder is in the catch card until this drops in. |
| `assets/vfx/rain_ripples.png` | 128 | No. Not stubbed in this pass. |
| `models/bobber.glb` | lure mesh | No. UV-sphere placeholder, tint `#F0C060`. `scripts/lure.gd` swaps to this path when the file exists. |
| `models/buoy_red.glb` | buoy | No. Cylinder placeholder, tint `#D1453A`, off the cast lane. Swap is in `scripts/player_controller.gd`. |

P0 files that are wired are listed in `assets/ART_P0_README.md`.
