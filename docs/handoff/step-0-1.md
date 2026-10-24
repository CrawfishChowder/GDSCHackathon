# Step 0–1 handoff: Red Alert interaction foundation

Branch: `step-0-1-interaction` (already created). Godot 4.7, binary at `/usr/local/bin/godot`.
Project root is `red-alert/` (all `res://` paths are relative to it).

Game: first-person survival game on a spaceship, Among Us style but solo. Systems break down (O2, power, reactor, doors), alarms go off, and the player runs to stations and completes quick fix-it minigames before a countdown kills them.

Hackathon rules that apply to every task (Geaux Hack):
- No AI-generated images, video or art assets. Use primitives/procedural meshes or human-made/CC0 assets only.
- Do not paste or reference external source code (tutorials, GitHub repos) while generating code.
- Keep code simple and commented where non-obvious: every team member must be able to explain it.
- Code freeze: 12:00 PM CDT Sunday Oct 25.

Run order:
- **Wave 1** (parallel, no shared files): T0a, T0b, T1a, T1b
- **Wave 2** (after wave 1 is reviewed): T1c

Rules for every task:
- Typed GDScript, tabs, match the style of `red-alert/scripts/player/first_person_controller.gd`.
- Touch ONLY the files listed in the task. Do not edit this handoff file.
- Do NOT commit. Leave changes in the working tree for review.
- After adding any new `.gd` file, run `godot --headless --path red-alert --import` so Godot generates its `.gd.uid` file; keep the `.uid` file.
- Smoke check (must print nothing):
  `godot --headless --path red-alert --quit-after 120 2>&1 | grep -E "ERROR|SCRIPT ERROR|WARNING"`
- Finish with a summary of at most 10 lines: files changed, commands run, test results, anything unresolved. Do not paste file contents.

---

## T0a — Repo hygiene (model: gemini-3.8-flash-low, mode: accept-edits)

Files: `.gitignore` (repo root), `README.md` (repo root).

1. Replace the entire root `.gitignore` (currently a Rust/Cargo template) with Godot 4 ignores:
   `.godot/`, `/android/`, `export/`, `*.tmp`, `.env`, `.DS_Store`, `Thumbs.db`. Do NOT ignore `*.import` or `*.uid`.
2. Rewrite `README.md`. Keep the existing team member list exactly. Add:
   - Title: "Red Alert"
   - Concept (1–2 sentences): a first-person survival game aboard a failing spaceship. Systems keep breaking, alarms blare, and you race between stations to complete fix-it minigames before a malfunction kills you (think Among Us tasks and sabotages, solo).
   - How to run: install Godot 4.7, open `red-alert/project.godot`, press F5. Controls: WASD move, Space jump, mouse look, E interact, Esc release mouse.
   - Folder map: `red-alert/scenes/`, `red-alert/scripts/`, `red-alert/tests/`, `docs/`.
   - Section "AI Use Disclosure": "Parts of this codebase were written with AI assistance (Claude Code for planning/review, Gemini in Antigravity for implementation). No AI-generated images, video or art assets are used. Per-change notes: see commit history." 
   - Section "Credits": "No external assets yet." (placeholder).

Acceptance: `git diff --stat` shows only these 2 files; team names unchanged; both new sections present.

---

## T0b — Extract main console into its own scene (model: gemini-3.8-flash-high, mode: accept-edits)

Files: `red-alert/scenes/stage1/stage_1_room.tscn`, NEW `red-alert/scenes/stage1/components/main_console.tscn`.

Why: every feature would otherwise edit the 590-line room scene and cause merge conflicts.

1. Create `main_console.tscn` (`[gd_scene format=3]`, no uid needed) whose root is
   `[node name="MainConsole" type="Node3D"]`.
2. Move every node whose `parent=` is `"MainConsole"` or starts with `"MainConsole/"` (91 nodes) into the new file, in the same order, rewriting parents:
   `parent="MainConsole"` → `parent="."`, `parent="MainConsole/X/Y"` → `parent="X/Y"`.
   Keep each node's properties (position/rotation/scale/mesh/shape) unchanged. MainConsole has an identity transform, so no coordinate changes are needed.
3. Move every `[sub_resource]` used by those nodes (console materials, `Mesh_*`, `Shape_console_*`) into the new file. Leave `Environment_stage1` and anything still used by the room in the room file. No sub_resource may be duplicated or left unused in either file.
4. In `stage_1_room.tscn`: add `[ext_resource type="PackedScene" path="res://scenes/stage1/components/main_console.tscn" id="4_console"]`, and put `[node name="MainConsole" parent="." instance=ExtResource("4_console")]` where the old MainConsole node was (before `SpawnPoints`). Remove the `load_steps=` attribute from the header (Godot recomputes it).

Acceptance:
- `grep -c 'parent="MainConsole' red-alert/scenes/stage1/stage_1_room.tscn` → `0`
- `grep -c 'type="MeshInstance3D"' red-alert/scenes/stage1/components/main_console.tscn` → `80`
- Smoke check prints nothing.

---

## T1a — Interaction system (model: gemini-3.8-flash-high, mode: accept-edits)

Files: `red-alert/project.godot`, `red-alert/scenes/player/first_person_player.tscn`,
NEW `red-alert/scripts/interaction/interactable.gd`, NEW `red-alert/scripts/player/interactor.gd`,
NEW `red-alert/scenes/ui/hud.tscn`, NEW `red-alert/scripts/ui/hud.gd`.
Do NOT modify `first_person_controller.gd`.

1. `project.godot` `[input]`: add action `interact` bound to key E (physical_keycode 69, unicode 101), copying the exact format of the existing `jump` entry. Also add a `[layer_names]` section with `3d_physics/layer_1="world"` and `3d_physics/layer_2="interactable"`.
2. `interactable.gd`:
   ```
   class_name Interactable
   extends Area3D
   signal interacted(by: Node)
   @export var prompt_text: String = "Interact"
   @export var enabled: bool = true
   func _ready() -> void: collision_layer = 2; collision_mask = 0; monitoring = false
   func interact(by: Node) -> void  # emits interacted only if enabled
   ```
   An Interactable needs a CollisionShape3D child, added by whoever uses it.
3. `interactor.gd` (extends RayCast3D):
   - `signal target_changed(prompt: String)` (empty string = nothing targeted)
   - In `_ready`: `target_position = Vector3(0, 0, -2.2)`, `collide_with_areas = true`, `collide_with_bodies = true`, `collision_mask = 3`, `add_exception(owner)` (owner is the CharacterBody3D player).
   - `_physics_process`: resolve `get_collider()`. If it is an `Interactable` with `enabled`, that is the current target, otherwise null. Emit `target_changed` only when the target or its prompt changes.
   - `_unhandled_input`: on `interact` pressed with a current target → `target.interact(owner)` and mark the input handled.
4. `hud.tscn` + `hud.gd`: root `CanvasLayer` named `HUD` with script `hud.gd`. Children: a centered `Crosshair` (6×6 `ColorRect`, light grey, anchored to the screen center) and a `PromptLabel` (`Label`, centered horizontally, about 40px below center, hidden by default). `hud.gd` exposes `func set_prompt(text: String) -> void`: empty → hide; else show `"[E] " + text`. Both UI nodes must use `mouse_filter = MOUSE_FILTER_IGNORE`.
5. `first_person_player.tscn`: add `Interactor` (RayCast3D, script `interactor.gd`) as a child of `Head/Camera3D`, instance `hud.tscn` as a child of the root, and add
   `[connection signal="target_changed" from="Head/Camera3D/Interactor" to="HUD" method="set_prompt"]`.

Acceptance:
- `godot --headless --path red-alert --check-only --script res://scripts/player/interactor.gd` and the same for the other two new scripts print no errors.
- Smoke check prints nothing.

---

## T1b — Bulkhead door behaviour (model: gemini-3.8-flash-high, mode: accept-edits)

Files: `red-alert/scenes/stage1/components/sealed_bulkhead_door.tscn`, NEW `red-alert/scripts/stage1/bulkhead_door.gd`, NEW `red-alert/tests/test_bulkhead_door.gd`.

1. In the door scene, reparent `CenterSeam`, `LowerPanelSeam`, `UpperPanelSeam`, `LeftBrace` and `RightBrace` under `DoorSlab`, so they move with the slab. Subtract the slab's position `(0, 1.28, 0)` from each one's `position` so its world placement is unchanged.
2. `bulkhead_door.gd` (`class_name BulkheadDoor`, `extends StaticBody3D`), attached to the scene root:
   - `signal opened`
   - `@export var starts_sealed: bool = true`, `@export var open_duration: float = 1.2`, `@export var slide_height: float = 2.5`
   - Use an enum state `SEALED, OPENING, OPEN`. If `starts_sealed` is false, start OPEN (slab already raised, collision disabled, light green).
   - In `_ready`: duplicate the `SealedIndicator` material and assign it as `material_override`, so each door instance has its own light (the sub_resource is shared between instances).
   - `func unseal() -> void`: no-op unless SEALED. Set OPENING, set the light green (albedo `Color(0.02, 0.3, 0.05)`, emission `Color(0.05, 0.9, 0.2)`), then tween `DoorSlab.position.y` up by `slide_height` over `open_duration` (TRANS_SINE, EASE_IN_OUT). On finish: `DoorCollision.set_deferred("disabled", true)`, state OPEN, emit `opened`.
   - `func is_sealed() -> bool`.
   - Known limitation, do NOT fix: the room walls are solid behind the doors, so an open door shows wall. Openings come later.
3. `tests/test_bulkhead_door.gd`: `extends SceneTree`. In `_initialize`: instance the door scene, add it to root, assert `is_sealed()`, call `unseal()`, wait 1.6 s (`await create_timer(1.6).timeout`), assert not sealed, that `DoorCollision.disabled` is true, and that `opened` fired. Print `PASS` or `FAIL: <reason>`, then `quit(0 or 1)`.

Acceptance:
- `godot --headless --path red-alert --script res://tests/test_bulkhead_door.gd` prints `PASS` and exits 0.
- Smoke check prints nothing.

---

## T1c — Wire a demo: red key opens north door (WAVE 2; model: gemini-3.8-flash-high, mode: accept-edits)

Purpose: end-to-end proof that interaction → fix → world reaction works. This is the template every later "malfunction + fix station" will copy.

Requires T0b, T1a and T1b merged. Files: `red-alert/scenes/stage1/components/main_console.tscn`, `red-alert/scenes/stage1/stage_1_room.tscn`, NEW `red-alert/scripts/stage1/stage1_controller.gd`, NEW `red-alert/tests/test_stage1_flow.gd`.

1. In `main_console.tscn`, add `[node name="EmergencyReleaseKey" type="Area3D" parent="CenterStation"]` with script `res://scripts/interaction/interactable.gd`, `prompt_text = "Emergency release"`, and the same position/rotation as `PortControlKeyRed` (`Vector3(-0.73, 1.17, 3.94)`, rotation `Vector3(-0.18, 0, 0)`, no scale). Give it a child `CollisionShape3D` with a `BoxShape3D` of size `Vector3(0.22, 0.12, 0.22)`.
2. `stage1_controller.gd` (extends Node3D), attached to the room root `Stage1IndustrialRoom`:
   - `@onready` refs to `$MainConsole/CenterStation/EmergencyReleaseKey` and `$BulkheadDoors/NorthBulkheadDoor`.
   - On the key's `interacted` → `north_door.unseal()`, then disable the key (`enabled = false`).
   - Keep it under 40 lines; future puzzles will add more connections here.
3. `tests/test_stage1_flow.gd` (`extends SceneTree`): load and instance `res://scenes/stage1/stage_1_room.tscn`, call `interact(null)` on the key, wait 1.6 s, assert the north door is not sealed and the east/west doors are still sealed. Print `PASS`/`FAIL`, then quit.

Acceptance:
- The test prints `PASS`, and `tests/test_bulkhead_door.gd` still passes.
- Smoke check prints nothing.
- Manual (human): F5, turn around to the console, aim at the left red key on the center station, see "[E] Emergency release", press E, and the north door slides up with a green light.
