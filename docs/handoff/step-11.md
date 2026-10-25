# Step 11 handoff: story shift, Mars window, first-encounter briefings, achievements

Branch: `step-11-features`. Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first. Paths are relative to `red-alert/`.

Rules (same as earlier steps):
- Touch ONLY the files listed in your task. Other agents edit other files at the same time. Do not edit `docs/`, `CLAUDE.md` or `AGENTS.md`. **Do not edit any `.tscn` file in this step.**
- **Scott's code wins:** make small, guarded additions to his files (controller, consoles, monitors, `normal_operations.gd`) and never restructure them.
- You cannot run shell commands. Do NOT create `.uid` or `.import` files. Do NOT commit.
- UI, meshes and shaders are built in code; no image files. Reach autoloads with `get_node_or_null("/root/Name")`. Never signal state with color alone. Audio follows the headless rule (don't call `play()` when headless).
- Tests: `extends SceneTree`; `await process_frame` first; look up autoloads with `root.get_node("Name")`; no casts to autoload-using classes; record signals into a shared `var got := {}`. Print `PASS` / `FAIL: <reason>`, then `quit(0/1)`. Unpause the tree before quitting.
- Facts: use ONLY the text given here.
- Finish with a summary of at most 10 lines: files changed, anything unresolved, any deviation. Do not paste file contents.

All four tasks run in parallel.

---

## T11a — Story shift (authored arc)

Files: `scripts/systems/malfunction_manager.gd`, NEW `scripts/stage1/story_director.gd`, `scripts/stage1/stage1_controller.gd`, `scripts/ui/title_screen.gd`, `data/voice_lines.json`, NEW `tests/test_story_shift.gd`.

1. Manager: add `var scripted: bool = false`. While it's true, the random scheduler never triggers anything (`_next_in` is ignored). In `start_run()`, set `scripted = (mode == "story")`. A `mode` of `"story"` otherwise behaves like `"normal"`. Change nothing else.
2. `story_director.gd` (`extends Node`, `process_mode = ALWAYS`). `stage1_controller.gd` creates it in `_ready` with `add_child(load(...).new())` when `mode == "story"`.
   It polls `MalfunctionManager.survived_seconds`. Each beat fires once and only if nothing is active; if something is active, it waits until it's clear. The beats:
   - **20 s:** `trigger("o2")`, then `Voice.say("story_o2")`
   - **70 s:** `Voice.say("story_flare")`, then `trigger("power")`
   - **120 s:** `trigger("co2")`, then `Voice.say("story_co2")`
   - **165 s:** `trigger("dust_storm")`, then `Voice.say("story_dust")`
   - **215 s:** `trigger("reactor")`, then set `time_left *= 0.8`, then `Voice.say("story_reactor")`
   - **270 s:** `Voice.say("story_approach")`
   - The 300 s relief ending already exists.

   Expose `func next_beat_index() -> int`.
3. `title_screen.gd`: add a first button, **"Story shift (best first play)"**, which calls `_start_shift("story")`. Keep the others.
4. `voice_lines.json`, add exactly:
   - `story_o2` (crew): "Okay, first problem of the day. Oxygen filter is clogging. Left console, you know the drill."
   - `story_flare` (hal): "Solar particle event detected by NASA space weather monitoring. Expect electrical failures."
   - `story_co2` (crew): "CO2 is creeping up. This is exactly what happened on Apollo 13. Right console, follow the checklist."
   - `story_dust` (hal): "Dust storm front arriving. Solar array output dropping. Rebalance power at the east wall."
   - `story_reactor` (hal): "Reactor coolant failure. This is the big one. Countdown shortened."
   - `story_approach` (crew): "Relief crew is thirty seconds out. Hang on, you're almost there."
5. Test: use a fresh manager via `load(...).new()` with `mode = "story"`, call `start_run()`, and assert `scripted`. Set `_next_in = 0.0` and wait 0.2 s: nothing should become active. Then create a story director under root, set `survived_seconds = 21`, and wait 0.3 s: assert `is_active("o2")`.

## T11b — Mars window

Files: `scripts/stage1/doorways.gd`, NEW `scripts/stage1/mars_window.gd`, NEW `tests/test_mars_window.gd`.

1. `mars_window.gd` (`extends Node3D`, `process_mode = ALWAYS`). It builds a window frame (4 dark steel boxes, a 1.8 × 1.1 opening) and a QuadMesh behind it, using a `ShaderMaterial` with a spatial shader written in code (`render_mode unshaded;`). The shader:
   - sky gradient from butterscotch `vec3(0.85, 0.6, 0.4)` at the top to a pale haze at the horizon
   - small pale sun disk
   - 2–3 layers of dune silhouettes from sine/fbm noise, in rust tones `vec3(0.55, 0.25, 0.12)` and darker
   - faint drifting dust (noise scrolled by `TIME`)
   - uniform `storm` (0–1), which blends everything toward brown `vec3(0.45, 0.3, 0.2)`, hides the sun and adds fast-moving dust

   It also adds a Label3D below the window: "MARS · JEZERO REGION · LIVE EXTERIOR FEED" (font 32, grey).
   `storm` eases toward 1 while `MalfunctionManager.active_id == "dust_storm"`, and back to 0 otherwise. Expose `func storm_level() -> float`.
2. `doorways.gd`: in the east (AIRLOCK) corridor, move the existing end-wall Label3D up to y = 2.3. Add a MarsWindow on the end wall at `(8.95, 1.3, 0.0)`, facing the room (the same rotation as that label). Change nothing else.
3. Test: instance the room and wait 2 frames. Find a node named `MarsWindow` (recursive). Call `trigger("dust_storm")`, wait 2.0 s, and assert `storm_level() > 0.5`.

## T11c — First-encounter crisis briefings

Files: NEW `scripts/ui/crisis_brief.gd`, `scripts/ui/hud.gd`, NEW `tests/test_crisis_brief.gd`.

1. `crisis_brief.gd` (`extends CanvasLayer`, `layer = 13`, `process_mode = ALWAYS`). On `MalfunctionManager.malfunction_started(id)`, if `SaveData.get_value("seen_" + id, false)` is false:
   - set it to true
   - add 15 s to `MalfunctionManager.time_left` (first-time grace)
   - show a top-center card for 8 s: "NEW CRISIS: <DISPLAY NAME>" (amber, font 24), then the "how to fix" line below, then "+15 s first-time grace" (grey)

   The how-to lines, exactly:
   - reactor: "Center console. Watch the light sequence, then repeat it. Keys 1-4."
   - o2: "Left console. Type the filter code shown on screen, then Enter."
   - co2: "Right console. Press the adapter steps in checklist order. Keys 1-4."
   - power: "Breaker box by the north door. Open the cover, main breaker OFF, then ON."
   - dust_storm: "East-wall solar array. Keep every system at its minimum, total 90 or less, then Engage."

   Expose `func is_showing() -> bool` and `func current_text() -> String`. Skip the brief entirely when the tutorial is running (the tutorial already covers O2): check `/root/` for nothing, but skip when `MalfunctionManager.countdown_frozen` is true.
2. `hud.gd`: instance a CrisisBrief in `_ready` (`add_child(load(...).new())`). Change nothing else.
3. Test: `SaveData.set_value("seen_co2", false)`, instance `hud.tscn`, `start_run()`, `trigger("co2")`, and wait 2 frames. Assert the brief is showing and contains "checklist order", and that `time_left > 45`. Trigger again after a fix: no grace the second time.

## T11d — Achievements

Files: NEW `scripts/systems/achievements.gd`, `project.godot` (register the autoload only), `scripts/ui/mission_log_screen.gd`, NEW `tests/test_achievements.gd`.

1. Autoload `Achievements` (`process_mode = ALWAYS`), registered after `Sfx` in `project.godot`. Unlocked ids are persisted in `SaveData` key `"achievements"` (an Array).
   - `signal unlocked(id: String, title: String)`
   - `const LIST := {id: {"title", "desc"}}`, exactly:
     - `first_shift`: "First Shift" / "Survive a full shift."
     - `steady_hands`: "Steady Hands" / "Survive a shift without your heart rate passing 120."
     - `by_the_book`: "By the Book" / "Survive a shift on Hard."
     - `curiosity`: "Curiosity" / "Press the button you were told not to press."
     - `calm`: "Calm Under Pressure" / "Hold your breath steady (B) for 10 seconds in one shift."
     - `historian`: "Historian" / "Learn every incident in the mission log."
   - Track these:
     - the max `Stress.heart_rate` in the current run (reset on `run_started`)
     - the seconds `Stress.is_breathing()` is true in the current run
   - Unlock rules:
     - on `shift_completed`: `first_shift`; `steady_hands` if the max BPM stayed at 120 or below; `by_the_book` if `mode == "hard"`
     - on `player_died` with `death_kind == "button"`: `curiosity`
     - `calm`: once breathing time reaches 10 s
     - `historian`: when `MissionLog.entries` covers every key of `MissionLog.INCIDENTS`
   - Expose `func unlock(id)` (no-op if already unlocked), `func is_unlocked(id) -> bool` and `func all_ids() -> Array`.
   - Toast: its own CanvasLayer (layer 26). A bottom-right panel slides in for 3 s: "ACHIEVEMENT UNLOCKED" (cyan), then the title (font 20), then the desc. Queue multiple toasts. Use tweens with TWEEN_PAUSE_PROCESS, since end screens pause the tree.
2. `mission_log_screen.gd`: add an "ACHIEVEMENTS (n/6)" section above the entries. List each achievement as "✓ title: desc" or "○ title: desc", with unlocked ones in cyan and locked ones in grey, so text distinguishes them as well as color. Change nothing else.
3. Test: clear `"achievements"` in SaveData. `unlock("curiosity")` fires the `unlocked` signal and makes `is_unlocked` true, and a second unlock doesn't fire again. Then a fresh manager-independent check: emit `MalfunctionManager.shift_completed` after `start_run()` and assert `first_shift` is unlocked.
