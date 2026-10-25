# Step 12 handoff: title polish, display settings, focus pause, shift timeline

Branch: `step-12-polish`. Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first. Paths are relative to `red-alert/`.

Rules (same as earlier steps):
- Touch ONLY the files listed in your task. Other agents edit other files at the same time. Do not edit `docs/`, `CLAUDE.md`, `AGENTS.md` or any `.tscn` file.
- **Scott's code wins:** make only small, guarded additions to his files and never restructure them.
- You cannot run shell commands. Do NOT create `.uid` or `.import` files. Do NOT commit.
- UI and shaders are built in code; no image files. Reach autoloads with `get_node_or_null("/root/Name")`. Never signal state with color alone. Audio follows the headless rule (don't call `play()` when headless).
- Tests: `extends SceneTree`; `await process_frame` first; look up autoloads with `root.get_node("Name")`; no casts to autoload-using classes; record signals into a shared `var got := {}`. Type every `var` explicitly when the value comes from a Variant (`var x: bool = ...`). Print `PASS` / `FAIL: <reason>`, then `quit(0/1)`. Set `paused = false` (on the SceneTree, not on root) before quitting.
- Finish with a summary of at most 10 lines: files changed, anything unresolved, any deviation. Do not paste file contents.

All four tasks run in parallel.

---

## T12a — Title screen polish

Files: `scripts/ui/title_screen.gd`, NEW `scripts/ui/title_background.gd`, NEW `tests/test_title_polish.gd`.

1. `title_background.gd`: `extends ColorRect`, full-rect, `mouse_filter` IGNORE. It uses a canvas_item `ShaderMaterial` written in code: a Mars horizon based on the sky and dune ideas in `scripts/stage1/mars_window.gd` (read its `SHADER_SRC` for reference and port it to `shader_type canvas_item;`, using UV instead of world coordinates). Add slow parallax drift of the dune layers using `TIME` and a darkening vignette, so the menu text stays readable.
2. `title_screen.gd`:
   - Add a TitleBackground as the first (back-most) child.
   - Put the existing menu inside a semi-transparent dark panel, so contrast stays high.
   - Add a footer: "Team TBD · LSU Geaux Hack 2026 · Godot 4.7", grey, font 14, bottom center.
   - Add an ambient drone: an AudioStreamPlayer on bus "SFX" (if present) with a procedural looping AudioStreamWAV, 4 s at 22050 Hz, two detuned low sines (55 Hz and 55.4 Hz) plus faint noise, at -18 dB. Follow the headless rule.
   - When any start button is pressed, fade a black ColorRect from 0 to 1 over 0.35 s, then change scene. The fade must not block the existing `_start_shift` logic (call it at the end of the tween).
   - Keep every existing button and behavior.
3. Test: instance the title screen and wait 2 frames. Assert a TitleBackground child exists with a ShaderMaterial, that the "Start shift" button still exists, and that the footer text contains "Geaux Hack".

## T12b — Display settings: fullscreen, VSync, FPS counter, UI scale

Files: `scripts/systems/settings.gd`, `scripts/ui/settings_panel.gd`, NEW `tests/test_display_settings.gd`.

1. `Settings.DEFAULTS`: add `"fullscreen": false`, `"vsync": true`, `"show_fps": false`, `"ui_scale": 1.0`. Apply each in `_ready` and whenever it changes:
   - `fullscreen` → `DisplayServer.window_set_mode(WINDOW_MODE_FULLSCREEN or WINDOW_MODE_WINDOWED)`. Skip this when headless.
   - `vsync` → `DisplayServer.window_set_vsync_mode(VSYNC_ENABLED or VSYNC_DISABLED)`. Skip when headless.
   - `ui_scale` (0.8–1.5) → `get_tree().root.content_scale_factor = value`.
   - `show_fps` → Settings owns a small CanvasLayer (layer 40) with a top-right Label `"%d FPS" % Engine.get_frames_per_second()`, updated every 0.5 s and visible only when on.
2. F11 (physical, non-echo) in `Settings._unhandled_input` toggles `fullscreen`.
3. `settings_panel.gd`: add these rows, matching the existing style:
   - "Fullscreen (F11)": CheckButton
   - "VSync": CheckButton
   - "Show FPS": CheckButton
   - "Text / UI size": slider from 0.8 to 1.5, step 0.05, showing `"%.2fx"`
4. Test: set `show_fps` to true and assert the FPS label is visible, then reset it. Set `ui_scale` to 1.25 and assert `root.content_scale_factor` is 1.25 (±0.01), then reset it to 1.0.

## T12c — Auto-pause on focus loss

Files: `scripts/ui/pause_menu.gd`, NEW `tests/test_focus_pause.gd`.

1. `pause_menu.gd`: in `_notification(what)`, on `NOTIFICATION_APPLICATION_FOCUS_OUT` (or `NOTIFICATION_WM_WINDOW_FOCUS_OUT`), open the pause menu exactly as Esc does. Use the same guards: not while `MinigameHost.is_open()`, not while GameOver or ShiftComplete is showing, and not if already open or the tree is already paused.
   - Refactor the Esc-open code into `func open_menu()` and use it in both places.
   - Keep Resume calling the player's `resume_mouse_look()` (already present).
   - Expose `func is_open_menu() -> bool`.
2. Test: instance `hud.tscn` and wait 2 frames. Call the pause menu's `_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)` and assert it's open and the tree is paused. Call its resume function and assert the tree is unpaused.

## T12e — Shift timeline report

Files: `scripts/systems/malfunction_manager.gd`, `scripts/ui/shift_complete.gd`, `scripts/ui/game_over.gd`, NEW `tests/test_shift_timeline.gd`.

1. Manager: add `var history: Array[Dictionary] = []`, reset in `start_run()`. Add records like this:
   - In `trigger()`: append `{"id": id, "name": display_name(id), "start": survived_seconds, "end": -1.0, "outcome": "active"}`.
   - In `fix()`: set the last record's `"end"` and `"outcome": "fixed"`.
   - In `kill()`, when it actually kills: if the last record is active, set its `"end"` and `"outcome": "fatal"`.
   - In the practice branch of `kill()`: append a note `{"id": cause_id, "name": display_name(cause_id), "start": survived_seconds, "end": survived_seconds, "outcome": "practice_mistake"}`.

   Change nothing else.
2. `shift_complete.gd` and `game_over.gd`: add a "SHIFT TIMELINE" section (font 14) under the existing stats, one line per record:
   - `"%d:%02d  %s  fixed in %ds"` for fixed records
   - `"... FATAL"` for fatal ones
   - `"... practice mistake"` for practice mistakes

   Show at most 8 lines, the latest last. Fill it in when the screen shows. Keep everything else.
3. Test: use a fresh manager via `load(...).new()`. `start_run()`, `trigger("o2")`, set `survived_seconds = 30`, `fix("o2")`. Assert the history has 1 record with outcome "fixed" and end 30. Then `trigger("reactor")` and `kill("reactor", "mistake")`, and assert the last record's outcome is "fatal".
