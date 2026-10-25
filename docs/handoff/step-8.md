# Step 8 handoff: heart rate, dust storm, mission log screen, shift grade, demo helper

Branch: `step-8-features`. Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first. Paths are relative to `red-alert/`.

Rules (same as earlier steps):
- Touch ONLY the files listed in your task. Other agents edit other files at the same time. Do not edit `docs/`, `CLAUDE.md` or `AGENTS.md`.
- You cannot run shell commands. Do not try. Do NOT create `.uid` files. Do NOT commit.
- Build UI and meshes in code in `_ready()`; each `.tscn` is a root node plus its script only. Use only primitives or shaders written in code, never image files.
- Every reacting script uses `process_mode = PROCESS_MODE_ALWAYS` and reaches autoloads with `get_node_or_null("/root/Name")`. Never signal state with color alone.
- Tests: `extends SceneTree`; `await process_frame` first; look up autoloads with `root.get_node("Name")`; never cast to classes whose scripts use autoloads; no network. Record signals into a shared `var got := {}`, not a local bool (lambdas capture by value). Print `PASS` / `FAIL: <reason>`, then `quit(0/1)`.
- Facts: use ONLY the text given here.
- Finish with a summary of at most 10 lines: files changed, anything unresolved, any deviation. Do not paste file contents.

Run order: **Wave 0** (T8-0 alone), then **Wave 1** (T8a–T8e in parallel).

---

## T8-0 — Shared plumbing (WAVE 0)

Files:
- `scripts/systems/malfunction_manager.gd`
- `project.godot`
- `data/voice_lines.json`
- `scenes/ui/hud.tscn`
- `scenes/stage1/stage_1_room.tscn`
- NEW stubs: `scripts/systems/stress.gd`, `scripts/ui/heart_rate_overlay.gd`, `scripts/systems/shift_grade.gd`, `scripts/stage1/demo_helper.gd`, `scripts/stage1/solar_panel_station.gd`, `scripts/ui/mission_log_screen.gd`
- NEW `tests/test_manager_stats.gd`

1. Manager:
   - Add `"dust_storm": {"name": "Dust storm", "time_limit": 50.0}` to `MALFUNCTIONS`.
   - Add `var close_calls: int = 0`, incremented in `fix()` when `time_left < 10` (before clearing it).
   - Add `var practice_mistakes: int = 0`, incremented in the practice branch of `kill()`.
   - Reset both in `start_run()`. Change nothing else.
2. `project.godot`:
   - Add the input action `breathe` bound to key B (physical_keycode 66, unicode 98), in the same format as `interact`.
   - Add the autoload `Stress="*res://scripts/systems/stress.gd"` after `LifeSupport`.
3. `voice_lines.json`, add exactly:
   - `hal_alarm_dust_storm` (hal): "Warning. Regional dust storm detected. Solar array output falling. Power reserves critical in 50 seconds."
   - `crew_hint_dust_storm` (crew): "Dust storm! East wall, solar array panel. Balance the power so nothing drops below its minimum."
   - `crew_fixed_dust_storm` (crew): "Power is balanced. We can ride this storm out."
   - `crew_breathe` (crew): "Hey. Breathe with me. In for four, out for four. Hold B."
4. Stubs. Each one is `extends <type>` plus `# STUB: implemented by T8x, see docs/handoff/step-8.md`:
   - `stress.gd`: Node. Also declare `var heart_rate: float = 72.0` and `func is_breathing() -> bool: return false`.
   - `heart_rate_overlay.gd`: CanvasLayer
   - `shift_grade.gd`: `class_name ShiftGrade extends RefCounted`, with `static func compute(fixes: int, close_calls: int, practice_mistakes: int, survived_seconds: float, completed: bool) -> Dictionary: return {}`
   - `demo_helper.gd`: Node
   - `solar_panel_station.gd`: Node3D
   - `mission_log_screen.gd`: Control
5. `hud.tscn`: add a root child `[node name="HeartRateOverlay" type="CanvasLayer" parent="."]` with script `heart_rate_overlay.gd` and `layer = 9`.
   `stage_1_room.tscn`:
   - add `[node name="SolarPanelStation" type="Node3D" parent="WallFixtures"]` with script `solar_panel_station.gd`, `position = Vector3(5.85, 0, -3.6)` and `rotation = Vector3(0, -1.5708, 0)`
   - add a root child `[node name="DemoHelper" type="Node" parent="."]` with script `demo_helper.gd`
   - give every new ext_resource a unique id
6. `test_manager_stats.gd` (fresh manager via `load(...).new()`):
   - `display_name("dust_storm") == "Dust storm"`
   - trigger o2, set `time_left = 5`, `fix("o2")` → `close_calls == 1`
   - practice `kill("o2", "mistake")` → `practice_mistakes == 1`
   - `start_run()` resets both to 0

---

## T8a — Heart rate + breathing (WAVE 1)

Files: `scripts/systems/stress.gd`, `scripts/ui/heart_rate_overlay.gd`, `scripts/minigames/minigame.gd`, NEW `tests/test_stress.gd`.

1. `stress.gd` (autoload `Stress`, ALWAYS). `heart_rate` moves toward a target at 6 BPM/s going up and 4 BPM/s going down (8 BPM/s down while breathing). The target:
   - 72 base
   - 95 while any malfunction is active
   - 125 when `time_left < 15`
   - each `practice_mistake` adds a +20 spike that decays over 5 s
   - while `Input.is_action_pressed("breathe")`, the target is lowered by 35, with a floor of 65

   Also:
   - Clamp to 55–170.
   - Add `var external_heart_rate: float = -1.0`: when ≥ 0 it overrides (a hook for a future real sensor).
   - Emit `signal heart_rate_changed(bpm: float)` at most 4 times a second.
   - Once per malfunction, when the rate crosses 120, call `Voice.say("crew_breathe")`.
   - `is_breathing()` returns the input state.
   - On `run_started`, reset to 72.
2. `heart_rate_overlay.gd`:
   - Top-left, below the HUD stats (y about 44): a small heart (two ColorRect squares rotated 45°, or a Label "♥" if the font supports it, otherwise "HR") that pulses scale at the current BPM, plus the text `"%d BPM"`. Add "  ELEVATED" when above 110 and "  CRITICAL" when above 135.
   - When above 110, a centered hint "Hold B to breathe" (font 18).
   - A full-screen red vignette ColorRect with a small shader written in code (radial alpha: transparent at the center, edges up to 0.45). Its strength is `clamp((bpm - 110) / 50, 0, 1)`, and while breathing it's reduced. `mouse_filter = IGNORE`.
   - Expose `func vignette_strength() -> float`.
3. `minigame.gd`: in `_process`, if `Stress.heart_rate > 120`, offset the content panel by a random ±`(bpm - 120) / 8` px each frame (shaky hands); otherwise reset the offset to 0. Keep everything else.
4. Test: get the Stress autoload, `start_run()`, `trigger("reactor")`, set `time_left = 5`, and wait 3 s. Assert `heart_rate > 90`. Then set `external_heart_rate = 150` and wait a frame: assert `heart_rate == 150`. Reset it to -1.

---

## T8b — Dust storm crisis (WAVE 1)

Files:
- `scripts/stage1/solar_panel_station.gd`
- NEW `scripts/minigames/dust_storm_power.gd`, NEW `scenes/minigames/dust_storm_power.tscn`
- `scripts/stage1/station_signage.gd`
- `scripts/stage1/console_displays.gd`
- `scripts/systems/life_support.gd`
- `scripts/systems/mission_log.gd`
- `scripts/ui/survival_card.gd`
- NEW `tests/test_minigame_dust.gd`

1. `solar_panel_station.gd` (node at the east wall, local −Z faces into the room). Build in code:
   - a wall panel (BoxMesh 1.2 × 1.0 × 0.12 at local y = 1.5, dark steel) with three amber "solar cell" strips
   - a Label3D "SOLAR ARRAY" above it (font 64, pixel_size 0.004, cyan)
   - a `FixStation` child Area3D (`malfunction_id = "dust_storm"`, `minigame_scene` = `dust_storm_power.tscn`) with a BoxShape3D of 1.2 × 1.0 × 0.3 over the panel

   Load the FixStation script via `load("res://scripts/interaction/fix_station.gd")`, and set the exported fields BEFORE `add_child`.
2. Minigame (`extends Minigame`, `make_panel("DUST STORM: BALANCE SOLAR POWER")`):
   - The budget is 90 units: "Storm has cut solar output to 90%".
   - Three rows, each with a label, an HSlider (0–60, step 1) and value text with OK or LOW:
     - "LIFE SUPPORT (min 40)"
     - "HEATERS (min 25)"
     - "COMMS (min 15)"
   - Start every slider at 33.
   - A live total `"TOTAL %d / 90"`, with "OVER BUDGET" when above 90.
   - An "ENGAGE" button.
   - `func set_allocation(i: int, value: int)` and `func engage()`:
     - valid → `complete()`
     - over budget → `fail("You drew more power than the panels could give and the batteries collapsed.")`
     - life support low → `fail("You starved life support of power and the air stopped cycling.")`
     - heaters low → `fail("The heaters lost power and the water lines froze.")`
     - comms low → `fail("Comms went dark and nobody heard the distress call.")`
3. Wiring:
   - `station_signage.gd`: add `Cue_dust_storm` at `(5.5, 2.3, -3.6)`.
   - `console_displays.gd`: GO TO dust_storm → "SOLAR ARRAY, EAST WALL".
   - `life_support.gd`: while dust_storm is active, `power = 1 - 0.8 * p`.
4. `mission_log.gd` incident `"dust_storm"`:
   - title "Opportunity rover lost (2018)", year "2018"
   - summary: "In June 2018 a planet-wide dust storm blotted out the sun over the Opportunity rover's solar panels. Its batteries ran down and NASA never heard from it again; the mission was declared over in February 2019, almost 15 years after landing."
   - lesson: "On Mars, power depends on the weather, and a storm can last for months."
5. `survival_card.gd` card `"dust_storm"`:
   - title: "Spirit and Opportunity (2007)"
   - story: "A global dust storm in 2007 sharply cut the twin rovers' solar power. Engineers switched them to a minimum-power routine, and both rovers survived to keep exploring."
6. Test:
   - Set 45/25/15 and engage → completed.
   - A new instance, left at the default 33/33/33 → engage fails with an over-budget reason.
   - A new instance with 30/30/30 → fails with the life-support reason.

---

## T8c — Mission log screen (WAVE 1)

Files: `scripts/ui/mission_log_screen.gd`, `scripts/ui/title_screen.gd`, NEW `tests/test_mission_log_screen.gd`.

1. `mission_log_screen.gd` (a full-rect Control with a dark background):
   - a "MISSION LOG" title
   - a summary line: `"Crew lost: %d   |   DO NOT PRESS presses: %d   |   Best shift grade: %s"` from `MissionLog.entries.size()`, `SaveData` `do_not_press_count` and `SaveData` `best_grade` (or "--")
   - a ScrollContainer with newest-first entries. Each is a small panel showing:
     - the `title` (with the year)
     - `detail`
     - `"Survived %d:%02d, fixes %d"`
     - the local date from `unix_time` (`Time.get_datetime_string_from_unix_time`)
   - "No crew lost yet." when the log is empty
   - a "Back" button that emits `signal closed`
   - Expose `func entry_count_shown() -> int`.
2. `title_screen.gd`: add a "Mission log" button between Hard and Settings. It shows a MissionLogScreen on top and hides it on `closed`. Change nothing else.
3. Test: call `MissionLog.record_death("o2", "mistake", "test")`, then instance a MissionLogScreen. Assert `entry_count_shown() >= 1` and that some Label contains "Soyuz 11".

---

## T8d — Shift grade (WAVE 1)

Files: `scripts/systems/shift_grade.gd`, `scripts/ui/shift_complete.gd`, NEW `tests/test_shift_grade.gd`.

1. `ShiftGrade.compute(...)` returns `{"score": int, "grade": String, "notes": Array[String]}`:
   - score = `fixes * 15 + (40 if completed else 0) - close_calls * 5 - practice_mistakes * 10 + int(survived_seconds / 10)`, clamped to 0–100
   - grade: A ≥ 85, B ≥ 70, C ≥ 55, D ≥ 40, F otherwise
   - notes (strings), e.g. `"%d close calls"` and `"Shift completed"`
2. `shift_complete.gd`: under the stats, show a big grade, `"GRADE %s  (%d/100)"`, plus the notes. Save `best_grade`/`best_score` to SaveData when the score beats the stored best, and show "NEW BEST" in that case. Change nothing else.
3. Test:
   - `compute(6, 0, 0, 300, true)` → A
   - `compute(0, 0, 0, 30, false)` → F
   - clamping at 0 and at 100

---

## T8e — Demo helper (WAVE 1)

Files: `scripts/stage1/demo_helper.gd`, NEW `tests/test_demo_helper.gd`.

1. `demo_helper.gd` (Node, ALWAYS). It handles `_unhandled_input` for physical keys:
   - F4 → `trigger("co2")`
   - F5 → `trigger("dust_storm")`
   - F6 → set `survived_seconds = SHIFT_LENGTH - 10` (skip to the end of the shift)
   - F7 → `kill("reactor", "mistake", "Demo: instant failure.")`
   - F12 toggles an overlay. It's its own CanvasLayer at layer 30: a top-right panel listing all demo keys, including F1 reactor, F2 power and F3 O2, which are handled by `stage1_controller`. Hidden by default.
   - Ignore keys while `MinigameHost.is_open()`.
   - Expose `func overlay_visible() -> bool` and `func handle_key(keycode: Key)`, used by `_unhandled_input` and by the test.
2. Test: instance the room, `start_run()`, `handle_key(KEY_F5)` → `is_active("dust_storm")`. `handle_key(KEY_F12)` → `overlay_visible()`.
