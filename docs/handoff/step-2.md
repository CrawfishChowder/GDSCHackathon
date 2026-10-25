# Step 2 handoff: malfunctions, minigames, alarm, game over

Branch: `step-2-malfunctions`. Godot 4.7. Project root is `red-alert/` (all `res://` paths are relative to it).

Game: first-person survival on a failing spaceship, Among Us style but solo. Every so often a system breaks (reactor, power, O2). An alarm sounds and a countdown starts. The player runs to that system's station, presses E, and solves a short minigame to fix it. If the countdown hits zero, the player dies.

Hackathon rules (Geaux Hack), apply to every task:
- No AI-generated images, video or art. Build visuals from Godot primitives/UI nodes; generate sound procedurally in code.
- Do not paste or reference external source code (tutorials, repos).
- Keep code simple, typed, and commented where non-obvious: every team member must be able to explain it. Each script ≤ 150 lines.
- Code freeze 12:00 PM CDT Sunday Oct 25.

Rules for every task:
- Typed GDScript, tabs, match the style of `red-alert/scripts/player/interactor.gd`.
- Touch ONLY the files listed in your task. Other agents are editing other files at the same time. Do not edit `docs/`.
- You cannot run shell commands in this environment. Do not try. Do NOT create `.uid` files (the reviewer generates them).
- Build UI in code inside `_ready()`. Keep each `.tscn` minimal: a root node plus its script, with no hand-written child UI nodes.
- Do NOT commit.
- Finish with a summary of at most 10 lines: files changed, anything unresolved, any deviation from the contract. Do not paste file contents.

Run order:
- **Wave 1** (parallel): T2a, T2b, T2c1, T2c2, T2c3, T2d
- **Wave 2** (after review): T2e

---

## Shared contract (all tasks code against this; do not change it)

### `MalfunctionManager` (autoload, `res://scripts/systems/malfunction_manager.gd`, extends Node)
```gdscript
signal malfunction_started(id: String, display_name: String, time_limit: float)
signal malfunction_fixed(id: String)
signal player_died(cause_id: String, display_name: String)

const MALFUNCTIONS := {
	"reactor": {"name": "Reactor meltdown", "time_limit": 45.0},
	"power": {"name": "Power failure", "time_limit": 40.0},
	"o2": {"name": "O2 depletion", "time_limit": 50.0},
}

var running: bool = false        # true between start_run() and death/stop_run()
var active_id: String = ""       # "" when nothing is broken
var time_left: float = 0.0       # seconds left on the active malfunction
var survived_seconds: float = 0.0
var fixes_count: int = 0

func start_run() -> void          # reset stats, running = true, first malfunction in 10 s
func stop_run() -> void           # running = false, active_id = "", no more malfunctions
func trigger(id: String) -> void  # start this malfunction now; no-op if one is already active or not running
func fix(id: String) -> void      # no-op unless id == active_id
func is_active(id: String) -> bool
static func display_name(id: String) -> String
```

### `MinigameHost` (autoload scene, `res://scenes/ui/minigame_host.tscn`, root CanvasLayer)
```gdscript
var current: Minigame = null
func open(scene: PackedScene, malfunction_id: String) -> void
func close() -> void
func is_open() -> bool
```

### `Minigame` base class (`res://scripts/minigames/minigame.gd`)
```gdscript
class_name Minigame
extends Control
signal completed
signal cancelled
func complete() -> void   # emits completed
func cancel() -> void     # emits cancelled
```

### `FixStation` (`res://scripts/interaction/fix_station.gd`)
`class_name FixStation extends Interactable` with `@export var malfunction_id: String` and `@export var minigame_scene: PackedScene`. It is enabled only while its malfunction is active, and its interact() opens the minigame.

Minigame scenes: `res://scenes/minigames/reactor_sequence.tscn`, `power_switches.tscn`, `o2_keypad.tscn`.

---

## T2a — MalfunctionManager (gemini-3.8-flash-high)

Files: NEW `red-alert/scripts/systems/malfunction_manager.gd`, NEW `red-alert/tests/test_malfunction_manager.gd`, `red-alert/project.godot`.

1. Implement the contract above exactly.
   - In `_ready`, set `process_mode = Node.PROCESS_MODE_ALWAYS`, so countdowns keep running while a minigame pauses the tree.
   - Drive time in `_process(delta)`; do not use Timer nodes. While `running`, add to `survived_seconds`. Track a `_next_in: float` countdown to the next malfunction while none is active.
   - When `_next_in` reaches 0, trigger a random malfunction id.
   - While one is active, decrease `time_left`. At ≤ 0, set `running = false`, emit `player_died(active_id, name)`, then clear `active_id`.
   - `fix(id)`: increment `fixes_count`, clear `active_id`, emit `malfunction_fixed`, and set `_next_in = max(8.0, randf_range(15.0, 30.0) * pow(0.9, fixes_count))` (gaps shrink as you survive).
   - `start_run()` sets `_next_in = 10.0`.
2. Edit `project.godot`: add an `[autoload]` section (place it after `[application]`):
   ```
   MalfunctionManager="*res://scripts/systems/malfunction_manager.gd"
   MinigameHost="*res://scenes/ui/minigame_host.tscn"
   ```
3. Write `tests/test_malfunction_manager.gd` (`extends SceneTree`, same PASS/FAIL + quit pattern as `tests/test_bulkhead_door.gd`). It must use a fresh instance: `var m = load("res://scripts/systems/malfunction_manager.gd").new()`, added to root. Assert:
   - `trigger("o2")` emits `malfunction_started` and sets `is_active("o2")`.
   - A second `trigger("reactor")` is a no-op.
   - `fix("reactor")` is a no-op, and `fix("o2")` clears the malfunction and makes `fixes_count == 1`.
   - Triggering again, setting `time_left = 0.05` and waiting 0.2 s emits `player_died` with `running == false`.

---

## T2b — Minigame framework: base class, host, fix station (gemini-3.8-flash-high)

Files: NEW `red-alert/scripts/minigames/minigame.gd`, NEW `red-alert/scripts/ui/minigame_host.gd`, NEW `red-alert/scenes/ui/minigame_host.tscn`, NEW `red-alert/scripts/interaction/fix_station.gd`.
Read (don't edit) `red-alert/scripts/interaction/interactable.gd`.

1. `minigame.gd`: implement the contract. Also give it a helper for subclasses: `func make_panel(title: String) -> VBoxContainer`. It sets this Control to full-rect anchors, adds a centered dark `PanelContainer` (about 640×420, StyleBoxFlat with bg `Color(0.04, 0.06, 0.08, 0.95)`, a 2 px cyan border and 8 px rounded corners), a title Label (font size 26), and a hint Label "Esc to close" (font size 14, grey). It returns a VBoxContainer inside the panel for the minigame's content.
2. `minigame_host.tscn`: root `CanvasLayer` named `MinigameHost`, `layer = 10`, script `minigame_host.gd`.
3. `minigame_host.gd` (implements the contract):
   - `_ready`: `process_mode = PROCESS_MODE_ALWAYS`; connect `MalfunctionManager.player_died` → close the minigame without recapturing the mouse.
   - `open(scene, id)`: ignore the call if one is already open. Instantiate `scene` as `current` and add it as a child. Connect `completed` → `MalfunctionManager.fix(id)` then `close()`, and `cancelled` → `close()`. Set `get_tree().paused = true` and `Input.mouse_mode = Input.MOUSE_MODE_VISIBLE`.
   - `close()`: free `current`, set it to null, unpause, and set `Input.mouse_mode = Input.MOUSE_MODE_CAPTURED`.
   - `_unhandled_input`: if a minigame is open and `ui_cancel` is pressed → `close()` and mark the input handled.
   - Also close automatically if the malfunction gets fixed or ends while open (connect `malfunction_fixed`).
4. `fix_station.gd`: `class_name FixStation`, `extends Interactable`.
   - `_ready`: call `super()`, set `enabled = false`, and set `prompt_text = "Fix: " + MalfunctionManager.display_name(malfunction_id)`. Connect `malfunction_started` → `enabled = (id == malfunction_id)`, and `malfunction_fixed` / `player_died` → `enabled = false`.
   - Override `interact(by)`: if `enabled` and `minigame_scene` is set → emit `interacted(by)`, then `MinigameHost.open(minigame_scene, malfunction_id)`.

---

## T2c1 — Reactor minigame: repeat the sequence (gemini-3.8-flash-high)

Files: NEW `red-alert/scripts/minigames/reactor_sequence.gd`, NEW `red-alert/scenes/minigames/reactor_sequence.tscn`, NEW `red-alert/tests/test_minigame_reactor.gd`.

- `.tscn`: root `Control` named `ReactorSequence` with the script; nothing else.
- The script `extends Minigame` (base class: see contract; it will exist when T2b lands). In `_ready`, call `make_panel("REACTOR: STABILIZE CORE")` and build a row of 4 big square Buttons (red, amber, blue, green, about 110 px each, colored via StyleBoxFlat), plus a status Label.
- `var sequence: Array[int]` holds 4 random indices 0–3. `var accepting_input: bool = false`.
- Playback: flash each button in order (brighten it for 0.4 s, 0.15 s gap) using `await get_tree().create_timer(t, true, false, true).timeout`. The last argument `ignore_time_scale` and the `process_always = true` argument matter, because the tree is paused. Then set `accepting_input = true` and status "Repeat the pattern".
- `func press(index: int) -> void`: ignore it unless `accepting_input`. On the correct next step, advance. On a wrong press, show status "Wrong: watch again", reset progress and replay. After all 4 are correct → `complete()`.
- The test (`extends SceneTree`): instance the scene, add it to root, wait until `accepting_input` (poll every 0.1 s, give up after 5 s), connect `completed`, call `press()` for each index in `sequence`, and assert `completed` fired. Then PASS or FAIL.

---

## T2c2 — Power minigame: match the switches (gemini-3.8-flash-high)

Files: NEW `red-alert/scripts/minigames/power_switches.gd`, NEW `red-alert/scenes/minigames/power_switches.tscn`, NEW `red-alert/tests/test_minigame_power.gd`.

- `.tscn`: root `Control` named `PowerSwitches` with the script; nothing else.
- The script `extends Minigame`. In `_ready`, call `make_panel("POWER: REROUTE BREAKERS")`. Build 6 columns, each with a target lamp on top (a 40×40 ColorRect: lit `Color(1, 0.75, 0.1)`, unlit `Color(0.15, 0.12, 0.05)`) and a toggle Button below (`toggle_mode = true`, text "ON"/"OFF").
- `var target: Array[bool]` holds 6 random values, rerolled until at least 2 are true and at least 2 are false. `var switches: Array[bool]` starts all false.
- `func toggle(i: int) -> void`: flip `switches[i]`, update the button text, and check: if `switches == target` → a status Label shows "Power restored", then call `complete()` after 0.3 s (same pausable-safe `create_timer` call as T2c1: `create_timer(0.3, true, false, true)`).
- Button `pressed` → `toggle(i)`.
- The test: instance the scene, connect `completed`, call `toggle(i)` for every i where `target[i]` is true, wait 0.5 s, and assert `completed` fired.

---

## T2c3 — O2 minigame: keypad code (gemini-3.8-flash-high)

Files: NEW `red-alert/scripts/minigames/o2_keypad.gd`, NEW `red-alert/scenes/minigames/o2_keypad.tscn`, NEW `red-alert/tests/test_minigame_o2.gd`.

- `.tscn`: root `Control` named `O2Keypad` with the script; nothing else.
- The script `extends Minigame`. In `_ready`, call `make_panel("O2: RESET FILTER")`. Build:
  - a Label "FILTER CODE: 48213" showing a random 5-digit `var code: String`
  - a display Label showing the entered digits
  - a 4×3 GridContainer of Buttons: 1–9, CLR, 0, ENTER
- `func press_key(key: String) -> void`, where key is one of "0"–"9", "CLR", "ENTER":
  - Digits append (max 5) to `var entered: String`.
  - CLR clears.
  - ENTER: if `entered == code` → `complete()`; otherwise show "ERROR" in the display and clear.
- The test: instance the scene, connect `completed`, press a wrong code + ENTER and assert not completed, then press each digit of `code` + ENTER and assert completed.

---

## T2d — Alarm, HUD alert banner, game over screen (gemini-3.8-flash-high)

Files: NEW `red-alert/scripts/stage1/alarm_controller.gd`, `red-alert/scripts/ui/hud.gd`, `red-alert/scenes/ui/hud.tscn`, NEW `red-alert/scripts/ui/game_over.gd`, NEW `red-alert/scenes/ui/game_over.tscn`.

1. `alarm_controller.gd` (`extends Node3D`; T2e adds it to the room, so don't edit any room scene):
   - `_ready`: `process_mode = PROCESS_MODE_ALWAYS`. Create 4 red `OmniLight3D`s (color `Color(1, 0.08, 0.04)`, range 7, energy 0) at `(±4.5, 3.0, ±3.5)`. Create an `AudioStreamPlayer` whose stream is a klaxon `AudioStreamWAV` generated in code: 16-bit mono, mix_rate 22050, 1.6 s long, alternating 0.4 s square-wave segments of 620 Hz and 460 Hz at amplitude about 0.35, `loop_mode = LOOP_FORWARD`, `loop_end` = sample count, volume -10 dB.
   - Connect `MalfunctionManager.malfunction_started` → alarm on (play the klaxon), and `malfunction_fixed` / `player_died` → alarm off (stop, energy 0).
   - `_process`: while on, light energy = `3.0 * (0.5 + 0.5 * sin(t * 6.0))`.
2. HUD (`hud.tscn` keeps its existing nodes; set root `process_mode = 3`, i.e. always). In `hud.gd`'s `_ready`, create in code:
   - an `AlertLabel`, top-center, font size 30, red, hidden by default
   - a `StatsLabel`, top-left at a 16 px margin, font size 16, light grey

   In `_process`, read MalfunctionManager:
   - If `active_id != ""`, AlertLabel shows `"!! %s  %d:%02d !!" % [display_name.to_upper(), mins, secs]` of `time_left`, and blinks (visible toggles every 0.5 s) when `time_left < 10`. Otherwise it's hidden.
   - StatsLabel shows `"SURVIVED %d:%02d   FIXES %d"`.

   Keep the existing `set_prompt` working.
3. `game_over.tscn`: root `CanvasLayer` named `GameOver`, `layer = 20`, script `game_over.gd`. Instance it as a child of the root in `hud.tscn` (that's the only `.tscn` child edit allowed).
4. `game_over.gd`: `process_mode = ALWAYS`, hidden on start.
   - On `MalfunctionManager.player_died(cause_id, display_name)`: show it, set `get_tree().paused = true` and `Input.mouse_mode = VISIBLE`.
   - Build in code: a full-screen ColorRect `Color(0.25, 0, 0, 0.85)`, a centered VBox with "YOU DIED" (font size 56), "Cause: <display_name>", "Survived m:ss  ·  Fixes n", and a "Restart [R]" Button.
   - Restart (button or the R key while visible): unpause, then `get_tree().reload_current_scene()`.
   - Expose `func is_showing() -> bool`.

---

## T2e — Wire everything into Stage 1 (WAVE 2, gemini-3.8-flash-high)

Requires all of Wave 1. Files: `red-alert/scenes/stage1/components/main_console.tscn`, `red-alert/scenes/stage1/components/breaker_box.tscn`, `red-alert/scripts/stage1/breaker_box.gd`, `red-alert/scenes/stage1/stage_1_room.tscn`, `red-alert/scripts/stage1/stage1_controller.gd`, NEW `red-alert/tests/test_stage2_flow.gd`.

1. `main_console.tscn`: add two `FixStation` Area3D nodes (script `res://scripts/interaction/fix_station.gd`), each with a child CollisionShape3D and BoxShape3D:
   - `CenterStation/ReactorStation`: position `(0, 1.2, 3.94)`, rotation `(-0.18, 0, 0)`, box `(1.0, 0.15, 0.35)`, `malfunction_id = "reactor"`, minigame `reactor_sequence.tscn`.
   - `LeftStation/O2Station`: position `(-2.13, 1.17, 3.94)`, same rotation, box `(0.9, 0.15, 0.35)`, `"o2"`, `o2_keypad.tscn`.
2. Breaker box:
   - Add a `PowerStation` FixStation child to the root of `breaker_box.tscn`, with NO collision shape (it is reached through the box), `"power"`, `power_switches.tscn`.
   - In `breaker_box.gd`, add `@onready var fix_station: FixStation = get_node_or_null("PowerStation")`. In `interact`: if `is_open and fix_station and fix_station.enabled` → `fix_station.interact(_interactor)` and return; otherwise toggle the cover as now.
   - The `prompt_text` getter returns `"Fix: Power failure"` in that case.
3. `stage_1_room.tscn`: add an `AlarmController` Node3D child of the root with script `res://scripts/stage1/alarm_controller.gd`.
4. `stage1_controller.gd`:
   - In `_ready`, call `MalfunctionManager.start_run()` (keep the existing emergency-key wiring).
   - Add demo hotkeys in `_unhandled_input`: physical F1/F2/F3 → `MalfunctionManager.trigger("reactor"/"power"/"o2")`.
5. `tests/test_stage2_flow.gd`:
   - Load and instance the room and wait one frame. Assert `MalfunctionManager.running`.
   - Call `trigger("o2")`. Assert O2Station is enabled and ReactorStation is not.
   - Call `O2Station.interact(null)`. Assert `MinigameHost.is_open()` and `get_tree().paused`.
   - Call `MinigameHost.current.complete()`. Assert `active_id == ""`, `fixes_count == 1`, and the tree is not paused.
   - Call `trigger("reactor")`, set `MalfunctionManager.time_left = 0.05`, and wait 0.3 s (timer with `process_always = true`). Assert the HUD's GameOver `is_showing()`.
   - Print PASS or FAIL.
