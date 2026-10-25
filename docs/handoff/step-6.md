# Step 6 handoff: menus/settings, survival cards, tutorial, CO2 crisis, judge modes

Branch: `step-6-features`. Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first. Paths are relative to `red-alert/` unless noted.

Rules for every task (on top of CLAUDE.md):
- Touch ONLY the files listed in your task. Other agents edit other files at the same time. Do not edit `docs/`, `CLAUDE.md` or `AGENTS.md`.
- You cannot run shell commands. Do not try. Do NOT create `.uid` files. Do NOT commit.
- Build UI in code in `_ready()`. Each `.tscn` is a root node plus its script only.
- UI style: dark panels like `scripts/minigames/minigame.gd` `make_panel`, with a cyan accent `Color(0.3, 0.8, 1.0)`. Never signal state with color alone. Every reacting script sets `process_mode = PROCESS_MODE_ALWAYS` and reaches autoloads with `get_node_or_null("/root/Name")`.
- Tests: `extends SceneTree`; `await process_frame` first; look up autoloads with `root.get_node("Name")`; never cast to classes whose scripts use autoloads; no network; print `PASS` / `FAIL: <reason>`; `quit(0/1)`.
- **GDScript lambdas capture local variables by value.** In tests, record signal results into a shared `var got := {}` (or an Array), never into a local bool. See `tests/test_manager_modes.gd`.
- Facts: use ONLY the text given here.
- Finish with a summary of at most 10 lines: files changed, anything unresolved, any deviation. Do not paste file contents.

Run order: **Wave 0** (T6-0 alone), then **Wave 1** (T6a, T6b, T6c, T6d in parallel).

---

## T6-0 — Shared plumbing (WAVE 0, gemini-3.8-flash-high)

Files: `scripts/systems/malfunction_manager.gd`, NEW `scripts/systems/settings.gd`, `scripts/systems/space_weather.gd`, `data/voice_lines.json`, `project.godot`, `scenes/ui/hud.tscn`, `scenes/stage1/stage_1_room.tscn`, and these NEW stubs: `scripts/ui/pause_menu.gd`, `scripts/ui/survival_card.gd`, `scripts/stage1/tutorial_director.gd`, `scripts/ui/title_screen.gd`, `scenes/ui/title_screen.tscn`. Also NEW `tests/test_manager_modes.gd`.

1. `malfunction_manager.gd`:
   - Add `"co2": {"name": "CO2 buildup", "time_limit": 45.0}` to `MALFUNCTIONS`.
   - Add `signal practice_mistake(cause_id: String, detail: String)`.
   - Add `var mode: String = "normal"` (`"practice" | "normal" | "hard"`) and `var countdown_frozen: bool = false`.
   - `start_run()` resets `countdown_frozen = false` (it does NOT reset `mode`).
   - `trigger()`: after the solar multiplier, if `mode == "hard"` multiply the limit by 0.5.
   - `_process`: don't decrease `time_left` while `countdown_frozen`.
   - Practice mode (no deaths, except the button):
     - In `kill()`, if `mode == "practice"` and `kind != "button"`: emit `practice_mistake(cause_id, detail)`. If `kind == "timeout"`, restart the countdown (`time_left` = that malfunction's limit). Then return without killing; `active_id` stays set, so the player can retry.
   - Change nothing else.
2. `settings.gd` (autoload `Settings`, `process_mode = ALWAYS`):
   - `signal settings_changed(key: String, value: Variant)`
   - `const DEFAULTS := {"mouse_sensitivity": 1.0, "invert_y": false, "master_volume": 0.8, "captions": true, "high_contrast": false}`
   - `func get_setting(key: String) -> Variant` reads from `SaveData` key `"settings"` (a Dictionary), falling back to DEFAULTS.
   - `func set_setting(key: String, value: Variant) -> void` saves to SaveData and emits `settings_changed`.
   - Apply `master_volume` with `AudioServer.set_bus_volume_db(0, linear_to_db(max(v, 0.0001)))` in `_ready` and whenever it changes.
3. `space_weather.gd`, flare cache: on a successful live flare, `SaveData.set_value("last_flare", flare)`. In `_set_offline()`, if SaveData has a non-empty `"last_flare"`, use that dict with `"source": "cached"` instead of the offline dict.
   - In `_report_wake`, cached → `"NASA DONKI feed unreachable. Last recorded solar flare: class %s, peaking %s UTC."`. Keep live and offline as they are.
   - `difficulty_multiplier` works for cached flares too.
4. `voice_lines.json`, add exactly:
   - `hal_alarm_co2` (hal): "Warning. Carbon dioxide concentration rising. Crew impairment in 45 seconds."
   - `crew_hint_co2` (crew): "CO2 is climbing! Right console. Build the scrubber adapter and follow the checklist in order."
   - `crew_fixed_co2` (crew): "Scrubber is pulling the CO2 down. That was an Apollo 13 move right there."
   - `crew_tutorial_1` (crew): "Something is wrong with the oxygen. Do not panic, I will walk you through it. Follow the flashing marker to the left console."
   - `crew_tutorial_2` (crew): "That is it. Look at the keyboard and press E."
   - `crew_tutorial_3` (crew): "Read the filter code and type it in. Careful. One wrong digit vents the air."
   - `crew_tutorial_done` (crew): "Perfect. From now on HAL runs a countdown, so be quick."
5. Stubs. Each is `extends <type>` plus a comment line `# STUB: implemented by T6x, see docs/handoff/step-6.md`, and nothing else:
   - `pause_menu.gd` and `survival_card.gd` extend CanvasLayer
   - `tutorial_director.gd` extends Node
   - `title_screen.gd` extends Control
   - `title_screen.tscn`: root `Control` named `TitleScreen` with that script
6. `hud.tscn`: add root children `[node name="PauseMenu" type="CanvasLayer" parent="."]` (script `pause_menu.gd`, `layer = 25`) and `[node name="SurvivalCard" type="CanvasLayer" parent="."]` (script `survival_card.gd`, `layer = 12`).
   `stage_1_room.tscn`: add a root child `[node name="TutorialDirector" type="Node" parent="."]` with script `tutorial_director.gd`. Add ext_resources with unique ids.
7. `project.godot`:
   - Add `Settings="*res://scripts/systems/settings.gd"` to `[autoload]`, right after `SaveData`.
   - Set `run/main_scene="res://scenes/ui/title_screen.tscn"`.
8. `test_manager_modes.gd` uses a fresh manager via `load(...).new()` added to root:
   - **hard:** `trigger("o2")` makes `time_left` 25 or less.
   - **practice:** `kill("o2", "mistake")` keeps `running` and `active_id == "o2"`, and emits `practice_mistake`.
   - **frozen:** `time_left` unchanged after 0.3 s.
   - **co2:** `display_name("co2") == "CO2 buildup"`.

---

## T6a — Title screen, pause menu, settings (WAVE 1, gemini-3.8-flash-high)

Files: `scripts/ui/title_screen.gd`, `scripts/ui/pause_menu.gd`, NEW `scripts/ui/settings_panel.gd`, `scripts/player/first_person_controller.gd`, `scripts/systems/voice.gd`, `scripts/ui/hud.gd`, NEW `tests/test_menus.gd`.

1. `settings_panel.gd`: `class_name SettingsPanel extends VBoxContainer`. Built in `_ready`, it reads and writes `Settings`. Each control has a visible text label:
   - Mouse sensitivity: an HSlider from 0.3 to 2.5 (step 0.05), showing its value as `"%.2fx"`
   - Invert Y: CheckButton
   - Master volume: an HSlider from 0 to 1, showing `"%d%%"`
   - Captions: CheckButton
   - High contrast: CheckButton
2. `title_screen.gd` (`process_mode = ALWAYS`, full-rect, dark background). Content:
   - Big title "RED ALERT" in red, font size 72
   - Subtitle "Keep the habitat alive for one shift. Every failure is based on a real spaceflight emergency."
   - A grey line with `PeopleInSpace.summary_line()`, refreshed when its `loaded` signal fires
   - Buttons:
     - "Start shift" → mode `normal`
     - "Practice (no deaths)" → `practice`
     - "Hard (half the time)" → `hard`
     - "Settings" toggles an inline SettingsPanel
     - "Quit" → `get_tree().quit()`

   Starting: set `MalfunctionManager.mode`, unpause, then `get_tree().change_scene_to_file("res://scenes/stage1/stage_1_room.tscn")`. Show the mouse (`MOUSE_MODE_VISIBLE`) in `_ready`.
3. `pause_menu.gd` (CanvasLayer, `process_mode = ALWAYS`, hidden at first).
   - On `ui_cancel` in `_unhandled_input`: ignore it if `MinigameHost.is_open()`, if the tree is already paused by something else, or if a GameOver or ShiftComplete sibling `is_showing()`.
   - Otherwise toggle the menu: pause the tree, show the mouse, and mark the input handled.
   - The panel holds: "PAUSED", a mode label (`"Mode: %s" % mode`), and the buttons "Resume", "Settings" (inline SettingsPanel), "Restart shift" (unpause + `reload_current_scene()`) and "Quit to title" (unpause + `change_scene_to_file` the title). Resume unpauses and recaptures the mouse.
4. `first_person_controller.gd`: in `_apply_look_delta`, multiply sensitivity by `Settings.get_setting("mouse_sensitivity")` and negate pitch when `invert_y`. Read through `get_node_or_null("/root/Settings")` and default to 1.0 and false. Change nothing else.
5. `voice.gd`: when `captions` is false, never show the caption panel (audio still plays). When `high_contrast` is true, make the caption background opaque black and the font size 28. React to `settings_changed`.
6. `hud.gd`: when `high_contrast` is true, give the alert and stats labels a black outline (`outline_size` 8) and make them 25% larger. React to `settings_changed`.
7. Test:
   - Instance `title_screen.tscn` and assert it has buttons whose text contains "Start shift", "Practice" and "Hard".
   - Call `Settings.set_setting("mouse_sensitivity", 1.5)` and assert `get_setting` returns 1.5, then reset it to 1.0.
   - Instance `hud.tscn` and assert a `PauseMenu` child exists with `visible == false`.

---

## T6b — Survival cards + practice "this would have killed you" card (WAVE 1, gemini-3.8-flash-high)

Files: `scripts/ui/survival_card.gd`, NEW `tests/test_survival_card.gd`.

1. `survival_card.gd` (CanvasLayer, `process_mode = ALWAYS`). It's a left-middle panel, about 380 px wide, 24 px from the left edge, vertically centered, autowrap. Hidden by default.
   - On `MalfunctionManager.malfunction_fixed(id)`, show a "REAL CREWS SURVIVED THIS" card for 7 s: a cyan heading, a title (bold, font size 22) and the story (font size 16). Fade in and out over 0.3 s with a tween that runs while paused (`set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)`).
   - Use exactly these cards:
     - **reactor** — "Kilopower KRUSTY test (2018)": "NASA and the Department of Energy ran a small fission reactor at full power for 28 hours in Nevada, a step toward powering future bases on Mars."
     - **power** — "Apollo 12 (1969)": "Lightning struck Apollo 12 twice during launch and knocked its fuel cells offline. Flight controller John Aaron called \"SCE to AUX\", the crew flipped one obscure switch, and the mission flew on."
     - **o2** — "Apollo 13 (1970)": "An oxygen tank exploded on the way to the Moon. The crew used the lunar module as a lifeboat for nearly four days and made it home."
     - **co2** — "Apollo 13 scrubber adapter (1970)": "With carbon dioxide rising, engineers improvised an adapter from plastic bags, cardboard and duct tape so square scrubber cartridges could fit a round socket. The crew built it from instructions read over the radio."
   - On `MalfunctionManager.practice_mistake(cause_id, detail)`, show a red-bordered card for 7 s: the heading "PRACTICE: THIS WOULD HAVE KILLED YOU", then `detail`, then the real incident title and its lesson from `MissionLog.incident_for(cause_id)`.
   - Expose `func current_title() -> String` and `func is_showing() -> bool`.
2. Test: instance `hud.tscn` and get its `SurvivalCard`. Call `MalfunctionManager.start_run()`, `trigger("power")` and `fix("power")`, then wait 0.5 s. Assert `is_showing()` and that `current_title()` contains "Apollo 12".

---

## T6c — First-malfunction tutorial (WAVE 1, gemini-3.8-flash-high)

Files: `scripts/stage1/tutorial_director.gd`, NEW `tests/test_tutorial.gd`.

1. `tutorial_director.gd` (Node, `process_mode = ALWAYS`). It runs when the room loads, but only if `SaveData.get_value("tutorial_done", false)` is false **or** `MalfunctionManager.mode == "practice"`.
   - 6 s after the room's `_ready` (the first random malfunction comes at 10 s), call `trigger("o2")`, set `countdown_frozen = true`, then `Voice.say("crew_tutorial_1")`.
   - Show an objective banner on its own CanvasLayer (layer 11): top-center under the alert, font size 22, cyan, dark background, with the prefix `"TRAINING (no countdown): "`.
   - Steps, polled in `_process`:
     1. "Follow the >> FIX HERE << marker to the LEFT CONSOLE". It advances when the player (the `FirstPersonPlayer` sibling) is within 2.5 m of `MainConsole/LeftStation/O2Station`; then `Voice.say("crew_tutorial_2")`.
     2. "Look at the keyboard and press E". It advances when `MinigameHost.is_open()`; then `Voice.say("crew_tutorial_3")`.
     3. "Type the filter code, then press ENTER. One wrong digit is fatal."
   - On `malfunction_fixed("o2")`: unfreeze, set `SaveData.set_value("tutorial_done", true)`, show "Training complete. Every failure from now on has a countdown." for 4 s, call `Voice.say("crew_tutorial_done")`, then hide.
   - If the player dies, unfreeze and hide.
   - Expose `func current_step() -> int` (0 = inactive, 1–3, 4 = done).
2. Test: set `SaveData.set_value("tutorial_done", false)`, instance the room, and wait 6.5 s. Assert `MalfunctionManager.is_active("o2")`, `countdown_frozen` and `current_step() == 1`. Move the player to within 1 m of O2Station, wait 0.3 s, and assert step 2. Then `fix("o2")`, wait 0.3 s, and assert step 4 and that `countdown_frozen` is false.

---

## T6d — CO2 crisis: scrubber adapter minigame (WAVE 1, gemini-3.8-flash-high)

Files: NEW `scripts/minigames/co2_adapter.gd`, NEW `scenes/minigames/co2_adapter.tscn`, `scenes/stage1/components/main_console.tscn` (add ONE node with its shape), `scripts/stage1/station_signage.gd`, `scripts/stage1/console_displays.gd`, `scripts/systems/life_support.gd`, `scripts/systems/mission_log.gd`, NEW `tests/test_minigame_co2.gd`.

1. Minigame (`extends Minigame`, `make_panel("CO2: BUILD THE SCRUBBER ADAPTER")`):
   - On the left, a "PROCEDURE (read over the radio)" list with these 4 numbered steps, in order:
     1. "Cut the hose"
     2. "Wrap the cartridge in a plastic bag"
     3. "Tape the bag to the hose"
     4. "Seal the edges with duct tape"
   - On the right, 4 big Buttons with the same step texts, in shuffled order (reshuffle until it differs from the correct order).
   - `func press_step(step_index: int)` (0–3, the correct-order index): the right next step greys out that button and ticks it off in the list. A wrong step → `fail("You skipped a step and the adapter leaked. The cabin filled with carbon dioxide.")`. All 4 done → `complete()`.
   - Expose `var order: Array[int]` (the shuffled display order).
2. `main_console.tscn`: add `RightStation/CO2Station`, a FixStation Area3D at `(2.13, 1.17, 3.94)` with rotation `(-0.18, 0, 0)`, `malfunction_id = "co2"`, minigame `co2_adapter.tscn`, and a child CollisionShape3D with a BoxShape3D of `(0.9, 0.15, 0.35)`. Copy how O2Station is defined.
3. `station_signage.gd`: the `Sign_systems` text becomes "CO2 SCRUBBER" and it maps to malfunction `co2`. Add `Cue_co2` at `(2.13, 1.75, 3.7)`.
   `console_displays.gd`: "GO TO" for co2 → "RIGHT CONSOLE".
   `life_support.gd`: while `co2` is active, `co2 = 0.9 * p` and `o2` drifts down to `1 - 0.3 * p`.
4. `mission_log.gd`: add an INCIDENTS entry, exactly:
   `"co2": title "Apollo 13 CO2 crisis", year "1970", summary "After the explosion, carbon dioxide rose toward dangerous levels in the lunar module because its round scrubber sockets could not take the command module's square cartridges. Ground engineers improvised an adapter in time. In your shift, nobody did.", lesson "Without scrubbing, a crew's own breath becomes the threat."`
5. Test: instance the minigame. Press the steps 0, 1, 2, 3 and assert `completed`. Then a new instance: press 0 then 2, and assert `failed`.
