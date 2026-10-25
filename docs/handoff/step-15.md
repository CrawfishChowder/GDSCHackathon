# Step 15 handoff: minigame variants, more history, performance mode

Branch: `step-15-overnight`. Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first. Paths are relative to `red-alert/`.

**Take as long as you need, and be thorough.** Readability beats line count: one statement per line, never join statements with `;`, and never one-line `if a: b() else: c()`.

Rules (same as earlier steps):
- Touch ONLY the files listed in your task. Other agents edit other files at the same time. Do not edit `docs/`, `CLAUDE.md`, `AGENTS.md` or any `.tscn` file except a NEW minigame `.tscn` of your own (root `Control` named after the minigame, plus its script; nothing else).
- **Scott's code wins:** only small, guarded, setting-gated additions to his files.
- You cannot run shell commands. Do NOT create `.uid` or `.import` files. Do NOT commit.
- Type every `var` explicitly when the value comes from a Variant.
- Tests: `extends SceneTree`; `await process_frame` first; look up autoloads with `root.get_node("Name")`; no casts to autoload-using classes; record signals into a shared `var got := {}`. Set `paused = false` (on the SceneTree) before quitting. Print `PASS` / `FAIL: <reason>`, then `quit(0/1)`.
- Facts and fail messages: use ONLY the text given here.
- Finish with a summary of at most 10 lines: files changed, anything unresolved, any deviation. Do not paste file contents.

**Minigame contract** (all new variants): `extends Minigame`. Call `make_panel(title)` and `add_instruction(content, text)`. Call `complete()` on success, and `fail(reason)` on the first mistake (instant fail). Respect the base-class `_done` flag: ignore input after completion or failure. Provide keyboard shortcuts, shown in [brackets] on the buttons. Follow the style of `scripts/minigames/o2_keypad.gd` and `co2_adapter.gd`.

All seven tasks run in parallel.

---

## T15a — Minigame catalog (random variant per crisis)

Files: NEW `scripts/minigames/catalog.gd`, `scripts/interaction/fix_station.gd`, NEW `tests/test_minigame_catalog.gd`.

1. `catalog.gd`: `class_name MinigameCatalog extends RefCounted`.
   - `const VARIANTS := {"reactor": ["res://scenes/minigames/reactor_sequence.tscn", "res://scenes/minigames/reactor_valves.tscn"], "o2": ["res://scenes/minigames/o2_keypad.tscn", "res://scenes/minigames/o2_leak_seal.tscn"], "co2": ["res://scenes/minigames/co2_adapter.tscn", "res://scenes/minigames/co2_beds.tscn"], "dust_storm": ["res://scenes/minigames/dust_storm_power.tscn", "res://scenes/minigames/dust_panel_align.tscn"]}`
   - `static func pick(id: String, last_path: String) -> String`: return a random path for `id` that's different from `last_path` when there's more than one, skipping any path where `not ResourceLoader.exists(path)`. Return "" for an unknown id.
2. `fix_station.gd`: in `interact()`, if `MinigameCatalog.pick(malfunction_id, _last_path)` returns a path, load it and open that scene (remember it in `_last_path`); otherwise use `minigame_scene` as before. Keep everything else.
3. Test: `pick("reactor", "")` returns one of the two paths. With `last` set to the first path, `pick` returns the second. `pick("unknown", "")` returns "".

## T15b — Reactor variant: balance the coolant loops

Files: NEW `scripts/minigames/reactor_valves.gd`, NEW `scenes/minigames/reactor_valves.tscn`, NEW `tests/test_minigame_reactor_valves.gd`.

- Title "REACTOR: BALANCE THE COOLANT LOOPS". Instruction: "Open and close valves to keep all three loops in the green band for 3 seconds. Any loop in the red is fatal."
- 3 loops. Each has a ProgressBar for pressure (0–100), a text status ("LOW", "OK" or "HIGH"/"CRITICAL"), and a toggle button "Valve N [N]" (keys 1–3).
- Simulation in `_process` (paused-safe; the tree is paused while a minigame is open, so set `process_mode = ALWAYS`). The pressure starts at 55. The rate is `inflow[i] - (outflow[i] if valve_open[i] else 0.0)` per second, with `inflow = [6, 9, 4]` and `outflow = [10, 14, 12]`.
  - The green band is 40–70. Above 90 → `fail("A coolant loop over-pressurized and ruptured. The core lost cooling.")`.
  - All three in the green continuously for 3.0 s → `complete()`.
- Expose `func step_sim(delta: float)` (used by `_process` and by tests), `var pressure: Array[float]` and `func set_valve(i: int, open: bool)`.
- Test:
  - Set all valves closed and step 0.1 s at a time until fail. Assert `failed` fired with that reason.
  - A fresh instance: alternate valves to hold the band (a simple controller in the test: open a valve when it's above 60, close it below 50), stepping up to 20 s. Assert completed.

## T15c — O2 variant: find and seal the leak

Files: NEW `scripts/minigames/o2_leak_seal.gd`, NEW `scenes/minigames/o2_leak_seal.tscn`, NEW `tests/test_minigame_o2_leak.gd`.

- Title "O2: SEAL THE LEAKING JOINT". Instruction: "Every joint shows its line pressure. The leaking joint reads lowest. Seal it. Sealing a healthy joint vents the line."
- A 3×3 grid of joint buttons labeled "J1"–"J9" (keys 1–9), each showing a pressure such as "101.2 kPa".
  - The leak is a random index. Healthy joints read 99.0–102.0 (random). The leak reads 82.0–90.0 and drops 0.4 kPa/s while open.
- `func seal(i: int)`: correct → `complete()`; wrong → `fail("You sealed a healthy joint and vented the oxygen line instead.")`.
- Expose `var leak_index: int`.
- Test: `seal(leak_index)` gives completed. A fresh instance: `seal((leak_index + 1) % 9)` gives failed with that reason.

## T15d — CO2 variant: switch scrubber beds

Files: NEW `scripts/minigames/co2_beds.gd`, NEW `scenes/minigames/co2_beds.tscn`, NEW `tests/test_minigame_co2_beds.gd`.

- Title "CO2: SWITCH SCRUBBER BEDS". Instruction: "Switch the air flow to the bed that is regenerated (low saturation) AND cooled below 60 °C."
- 3 beds, A, B and C, each showing "Saturation %d%%" and "Temp %d °C", with buttons "Use bed A [1]" through "[3]".
  - Exactly one bed is valid: saturation ≤ 30 and temp ≤ 60.
  - One decoy has low saturation but temp 85–110, because it's still regenerating.
  - One decoy has saturation 80–98 and normal temp.
  - Shuffle their positions.
- `func choose(i: int)`:
  - the valid bed → `complete()`
  - the hot bed → `fail("You switched to a bed that was still venting hot carbon dioxide.")`
  - the saturated bed → `fail("You switched to a saturated bed and carbon dioxide kept rising.")`
- Expose `var valid_index: int`, `var hot_index: int` and `var saturated_index: int`.
- Test: choosing the valid bed completes; on fresh instances, choosing the hot bed fails with the hot reason, and the saturated bed fails with the saturated reason.

## T15e — Dust storm variant: tilt the array

Files: NEW `scripts/minigames/dust_panel_align.gd`, NEW `scenes/minigames/dust_panel_align.tscn`, NEW `tests/test_minigame_dust_align.gd`.

- Title "DUST STORM: TILT THE SOLAR ARRAY". Instruction: "Through the dust, the sun bearing flickers on the readout. Rotate the array to within 5 degrees of it, then LOCK. Locking far off target drains the batteries."
- A "SUN BEARING: %d°" readout (random 20–160) that flickers: its visibility toggles every 0.3–0.6 s.
- An "ARRAY: %d°" readout, with ◀ / ▶ buttons stepping 1° ([A]/[D] or the arrow keys, holding repeats) and a "LOCK [Enter]" button.
- `func set_array(deg: int)` and `func lock()`:
  - within ±5° → `complete()`
  - otherwise → `fail("The array locked away from the sun and the batteries drained in the storm.")`
- Expose `var sun_bearing: int`.
- Test: `set_array(sun_bearing + 3)`, then `lock()`, completes. A fresh instance: `set_array(sun_bearing + 20)`, then `lock()`, fails with that reason.

## T15f — More history: second incidents + spoken incident reference

Files: `scripts/systems/mission_log.gd`, NEW `tests/test_history_variety.gd`.

1. Allow a cause to have several incidents. Keep `INCIDENTS` (one dict per key, used elsewhere), and add `const MORE_INCIDENTS := {...}` with these, exactly:
   - `"reactor"`: title "Chernobyl reactor 4", year "1986". Summary: "During a safety test, operators ran Chernobyl's reactor 4 outside its safe limits. A power surge blew the reactor apart and started a fire, the worst nuclear accident in history." Lesson: "Safety tests are only safe when the procedure's limits are respected."
   - `"power"`: title "Soyuz T-10-1 launch pad fire", year "1983". Summary: "Fuel spilled and caught fire at the base of a Soyuz rocket seconds before launch. Ground controllers fired the escape tower, which pulled Vladimir Titov and Gennady Strekalov clear just before the rocket exploded." Lesson: "Escape systems exist because fires spread faster than people can react."
   - `"o2"`: title "Apollo 13 oxygen tank", year "1970". Summary: "Damaged wiring inside oxygen tank 2 sparked an explosion on the way to the Moon. The crew survived only by using the lunar module as a lifeboat." Lesson: "One damaged wire in an oxygen system can end a mission."
   - `"dust_storm"`: title "Spirit rover stranded", year "2010". Summary: "Spirit became stuck in soft sand and could not tilt its solar panels toward the winter sun. NASA last heard from it in March 2010." Lesson: "On Mars, losing your angle to the sun can be fatal."
2. `incident_for(cause_id)` returns a random choice between `INCIDENTS[cause]` and any `MORE_INCIDENTS[cause]` (never the same title twice in a row for that cause). `record_death` uses it. Achievements' Historian still checks `INCIDENTS` keys (unchanged).
3. After recording an entry, call `Voice.say_text("hal", "Incident reference: %s, %s." % [title, year])`, or `"Incident reference: %s." % title` when the year is empty.
4. Test: calling `incident_for("power")` twice gives two different titles from {Apollo 1 fire, Soyuz T-10-1 launch pad fire}; `incident_for("co2")` returns the Apollo 13 CO2 entry; `record_death` makes `Voice.is_speaking()` true.

## T15g — Performance mode (opt-in, plus an automatic suggestion)

Target hardware: the demo runs on an HP ProBook 435 G7 (Windows, AMD Ryzen with integrated Radeon graphics) using the Compatibility renderer. **Target: a steady 60 FPS at 1920×1080 fullscreen.** Keep the default look intact; make the cheap path one toggle away, and suggest it automatically if FPS drops below 55.

Extra items (in addition to the list below), all gated on `performance_mode` unless marked "always":
- **Always:** the monitor SubViewports should not exceed the screen's on-screen size. Cap each viewport's resolution at 512×288. Do this in YOUR files only. For Scott's `normal_operations.gd`, a single guarded clamp where the viewport size is set is acceptable.
- **Always:** in Settings `_ready` (deferred), make sure `get_tree().root.msaa_3d = Viewport.MSAA_DISABLED`, and keep `scaling_3d_scale` at 1.0 unless performance mode is on. Runtime ProjectSettings changes don't affect the live viewport, so set the viewport properties. Don't edit `project.godot`.
- In performance mode, render 3D at 0.75 scale (`get_viewport().scaling_3d_scale = 0.75`), with the UI staying sharp.
- The FPS warning threshold is 55 (not 40).

Files: `scripts/systems/settings.gd`, `scripts/ui/settings_panel.gd`, `scripts/stage1/normal_operations.gd` (Scott's: one small guarded hook only), `scripts/stage1/lighting_director.gd`, NEW `tests/test_performance_mode.gd`.

1. `Settings.DEFAULTS`: add `"performance_mode": false`. When it's on:
   - the shadows setting is forced off
   - monitor viewports refresh at 15 Hz instead of every frame
   - the lighting director disables fog and glow
2. `normal_operations.gd`: add ONE guarded hook. While `performance_mode` is on, set each monitor SubViewport to `UPDATE_ONCE` on a 1/15 s timer; otherwise leave Scott's `UPDATE_ALWAYS` untouched. Read the setting through `/root/Settings` and react to `settings_changed`. Do not restructure his file.
3. `lighting_director.gd`: react to `performance_mode`, toggling `fog_enabled` and `glow_enabled`.
4. Settings: if FPS stays under 40 for 5 s while performance mode is off, show a one-time toast on the Settings layer: "Low FPS: try Performance mode in Settings". Skip this when headless.
   `settings_panel.gd`: add a "Performance mode (slow laptops / remote desktop)" CheckButton row.
5. Test: set `performance_mode` true, instance the room and wait 2 frames. Assert the WorldEnvironment has `fog_enabled == false`. Reset the setting.
