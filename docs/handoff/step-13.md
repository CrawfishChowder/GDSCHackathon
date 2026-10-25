# Step 13 handoff: overnight robustness + readability pass

Branch: `step-13-overnight`. Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first. Paths are relative to `red-alert/`.

**Take as long as you need, and be thorough.** Quality matters more than speed tonight. Read every file in your scope fully before changing it.

Rules (same as earlier steps):
- Touch ONLY the files listed in your task. Other agents edit other files at the same time. Do not edit `docs/`, `CLAUDE.md`, `AGENTS.md` or any `.tscn` file.
- **Never touch Scott's or Eddie's files:** `industrial_room_shell.gd`, `normal_operations.gd`, `monitor_display.gd`, `console_displays.gd`, `door_display.gd`, `console_chair.gd`, `first_person_controller.gd`, `scripts/displays/*`, `breaker_box.gd`, `breaker_handle_interactable.gd`, `power_failure_event.gd`, `event_director.gd`.
- **Behavior must not change** unless your task says so. No renamed public functions, signals or properties; other scripts and tests depend on them.
- You cannot run shell commands. Do NOT create `.uid` or `.import` files. Do NOT commit.
- Type every `var` explicitly when the value comes from a Variant (`var x: String = ...`). Do not use one-line `if a: b() else: c()`; write if/else on separate lines.
- Tests: `extends SceneTree`; `await process_frame` first; look up autoloads with `root.get_node("Name")`; no casts to autoload-using classes; record signals into a shared `var got := {}`. Print `PASS` / `FAIL: <reason>`, then `quit(0/1)`, and set `paused = false` before quitting.
- Finish with a summary of at most 15 lines: files changed, the issues found and fixed, anything unresolved. Do not paste file contents.

All four tasks run in parallel.

---

## T13a — Readability and robustness: `scripts/systems/`

Files: every `.gd` in `scripts/systems/` (`save_data`, `settings`, `malfunction_manager`, `mission_log`, `voice`, `life_support`, `stress`, `space_weather`, `people_in_space`, `sfx`, `achievements`, `shift_grade`), plus NEW `tests/test_systems_robustness.gd`.

1. **Readability:** give each file a 2–4 line header comment saying what it does and who listens to it. Add a short comment above each non-obvious function. Don't add comments that only restate the code. A teammate should be able to explain each file to a judge after reading it.
2. **Robustness:** after every `await`, re-check that `self` is still valid and inside the tree (`if not is_inside_tree(): return`) before touching nodes. Guard every `get_node_or_null` result before use. Make every JSON parse use `JSON.new().parse()` and handle failure silently.
3. Write a test that exercises an edge case per autoload. For example: `Voice.say` with an unknown id is a no-op; `Settings.get_setting` with an unknown key returns null without crashing; `MissionLog.record_death` with an unknown cause still records; `fix()` with no active malfunction is a no-op; `ShiftGrade.compute` with negative values clamps to 0.

## T13b — Readability and robustness: `scripts/ui/`

Files: every `.gd` in `scripts/ui/`, plus NEW `tests/test_ui_robustness.gd`.

1. Readability: the same as T13a.
2. **Robustness:** every screen that pauses the tree must also be able to unpause: Restart, Quit and Resume always restore `paused = false`. Tweens that run while paused must use `TWEEN_PAUSE_PROCESS`. Re-check validity after each `await`. Pressing R or a button twice must not double-reload the scene: add a `_leaving` guard.
3. Test: instance `hud.tscn`, show GameOver via `MissionLog.record_death`, then call its restart path twice quickly; it must not error. Open and close the pause menu 3 times and check that the tree ends unpaused.

## T13c — Readability and robustness: non-Scott gameplay scripts

Files: `scripts/stage1/` EXCEPT Scott's and Eddie's files listed above. That's `alarm_controller`, `bulkhead_door`, `do_not_press_button`, `doorways`, `lighting_director`, `room_props`, `solar_panel_station`, `stage1_controller`, `station_signage`, `story_director`, `tutorial_director`, `demo_helper`, `mars_window`. Also `scripts/interaction/*.gd`, `scripts/player/interactor.gd`, and NEW `tests/test_gameplay_robustness.gd`.

1. Readability: the same as T13a.
2. **Robustness:**
   - Re-check validity after `await`. In particular, `do_not_press_button` waits 2 s before killing; if the scene reloads during that wait, it must not error.
   - Make the tutorial and story directors survive the player dying mid-beat (stop cleanly on `player_died`).
   - The demo helper must ignore keys while the tree is paused.
3. Test: press the DO NOT PRESS button (`interact(null)`), then free the room immediately and wait 2.5 s: there must be no error and no crash. Also: in story mode, kill the run at 25 s and check that the director stops triggering.

## T13d — Readability and robustness: minigames

Files: every `.gd` in `scripts/minigames/`, plus NEW `tests/test_minigame_robustness.gd`.

1. Readability: the same as T13a.
2. **Robustness:**
   - The reactor playback awaits timers. If the minigame is closed (freed) mid-playback, nothing may error: check `is_inside_tree()` after each await.
   - Input after `complete()` or `fail()` must be ignored (add a `_done` flag in the base class and have each minigame respect it). No double `completed` / `failed` emits.
   - Rapid repeated key or button presses must not skip states.
3. Test:
   - Open the reactor through `MinigameHost.open` and close it during playback (after 0.3 s). Wait 2 s: no errors.
   - Complete the O2 keypad, then press ENTER again: `completed` must have fired exactly once.
   - On the CO2 adapter, press a wrong step twice: `failed` must have fired exactly once.
