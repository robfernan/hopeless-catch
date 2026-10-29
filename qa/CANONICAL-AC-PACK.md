# Hopeless Catch acceptance criteria

Shapes A–E live in `qa/fixtures.json`. Status is PENDING. Every measured value in that file is null except Shape C’s `input.control_claim.gamepad`, which stays `true`. There is no preview URL.

Gamepad is claimed for this build. AC-HC-002 is in scope. It is not N/A.

## AC-HC-001 — KB/M

Keyboard and mouse must be able to run the dock loop: walk, cast, set the hook, reel, and open the tackle box. A shore cast can be reeled back. A missed hook and a snapped line each leave a message.

## AC-HC-002 — gamepad

Claimed. The same loop is on the pad:

| Verb | Pad |
| --- | --- |
| Move | Left stick, or d-pad |
| Cast / set hook / keep fish | South button (A / Cross) |
| Reel / release fish | Right trigger |
| Thumb brake | Left trigger |
| Tackle box | North button (Y / Triangle). Left/right on the d-pad moves the slot. South confirms. |

Shape C is the gamepad fixture. `gamepad` stays true.

## AC-HC-003 — WEB focus

Web export, threads off. Audio stays muted until the first click or key. Leaving the window mutes Master. Coming back unmutes after that gesture. Shapes A and D cover this. No preview URL yet.

## AC-HC-004 — Desktop boot

Godot 4.7.x. `project.godot` at the repo root, main scene `res://scenes/main_lake.tscn`, window 1280×720. `godot --path .` or F5 reaches the dock. Shapes B and E. No preview URL yet.
