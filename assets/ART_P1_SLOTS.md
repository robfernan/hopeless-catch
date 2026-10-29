# P1 art slots

Paths match `scripts/fish_database.gd` and `scripts/tackle_box.gd`. No `_icon` suffix.

Drop-in source: pull request #8, `cursor/hc-p1-dropins-43e2` @ `7df4db8`. Those files were copied as-is.

| Path | Target | Status |
| --- | --- | --- |
| `assets/bait/worms.png` | 64×64 | LANDED from #8. Measured 64×64. |
| `assets/bait/corn.png` | 64×64 | LANDED from #8. Measured 64×64. |
| `assets/bait/minnows.png` | 64×64 | LANDED from #8. Measured 64×64. |
| `assets/bait/cheese.png` | 64×64 | LANDED from #8. Measured 64×64. |
| `assets/bait/rotten_meat.png` | 64×64 | LANDED earlier (P0). Wired as Offal. |
| `assets/ui/catch_card.png` | 420×520, fish slot 256×128 | LANDED from #8. Measured 420×520. Catch card uses this texture, nearest filter. |
| `models/bobber.glb` | lure, tip `#F0C060` | LANDED from #8. `scripts/lure.gd` instances it and hides the UV sphere. |
| `models/buoy_red.glb` | buoy, stripe `#D1453A` | LANDED from #8. `scripts/player_controller.gd` instances it instead of the cylinder. |
| `assets/vfx/rain_ripples.png` | 128×128 | LANDED from #8. Measured 128×128. Assigned to the existing water shader `_foam` sample. Linear filter. |
| `assets/fish/sunfish.png` | portrait | Already in tree, 64×64. Not part of #8. |
| `assets/fish/bass.png` | portrait | Already in tree, 64×64. |
| `assets/fish/trout.png` | portrait | Already in tree, 64×64. |
| `assets/fish/catfish.png` | portrait | Already in tree, 64×64. |
| `assets/fish/golden_carp.png` | portrait | Already in tree, 64×64. |
| `assets/fish/pale_crawler.png` | night portrait | File exists. Catalog line still commented out. Night mesh waiting. |
| `assets/fish/bleeding_carp.png` | night portrait | File exists. Catalog line still commented out. Night mesh waiting. |
| `assets/fish/whispering_eel.png` | night portrait | File exists. Catalog line still commented out. Night mesh waiting. |
| `assets/fish/fishman.png` | night portrait | File exists. Catalog line still commented out. Night mesh waiting. |

No SFX in the #8 batch.

Sibling notes from that drop-in: `assets/ART_P1_README.md`, `assets/p1-prompt-sheets.md`.
