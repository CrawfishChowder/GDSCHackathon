# Step 10 handoff: refinement pass

Branch: `step-10-refine`. Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first. Paths are relative to `red-alert/`.

Rules (same as earlier steps):
- Touch ONLY the files listed in your task. Other agents edit other files at the same time. Do not edit `docs/`, `CLAUDE.md` or `AGENTS.md`.
- You cannot run shell commands. Do NOT create `.uid` or `.import` files. Do NOT commit.
- UI is built in code. Reach autoloads with `get_node_or_null("/root/Name")`. Never signal state with color alone. Audio follows the headless rule: create players, but don't call `play()` when `DisplayServer.get_name() == "headless"`.
- Tests: `extends SceneTree`; `await process_frame` first; look up autoloads with `root.get_node("Name")`; no casts to autoload-using classes; record signals into a shared `var got := {}`. Print `PASS` / `FAIL: <reason>`, then `quit(0/1)`. Unpause the tree before quitting.
- **Prefer small, surgical edits to existing files.** Scott and Eddie own the scene and controller code, so keep their structure and only add what the task needs.
- Finish with a summary of at most 10 lines: files changed, anything unresolved, any deviation. Do not paste file contents.

All four tasks run in parallel.

---

## T10a — Reduce motion, volume sliders, graphics quality

Files: `scripts/systems/settings.gd`, `scripts/ui/settings_panel.gd`, `scripts/player/first_person_controller.gd`, `scripts/stage1/industrial_room_shell.gd`, NEW `tests/test_settings_refine.gd`.

1. Add to `Settings.DEFAULTS`: `"reduce_motion": false`, `"sfx_volume": 1.0`, `"voice_volume": 1.0`, `"shadows": true`. Apply the volumes to the audio buses "SFX" and "Voice"/"Radio" (both voice buses share `voice_volume`) with `linear_to_db(max(v, 0.0001))`, in `_ready` (deferred, because Sfx creates the buses) and whenever the setting changes. Skip any bus that doesn't exist (`AudioServer.get_bus_index(name) == -1`).
2. `settings_panel.gd`: add these rows, each with a visible text label and value text, in the same style as the existing rows:
   - "Reduce motion (no head bob or camera shake)": CheckButton
   - "Sound effects volume": slider showing `%d%%`
   - "Voice volume": slider showing `%d%%`
   - "Shadows (turn off on slow machines)": CheckButton
3. `first_person_controller.gd`: when `reduce_motion` is on, skip the head-bob offset (keep the camera position at 0) and make `shake()` a no-op. Read the setting once per frame through `/root/Settings`. That's all; change nothing else.
4. `industrial_room_shell.gd`: the center light's `shadow_enabled` follows the `shadows` setting. Read it when the lights are built, and listen to `settings_changed` for live updates. Keep the existing "only the center light casts shadows" logic.
5. Test: set `reduce_motion` true, instance the player scene, call `shake(1.0, 0.5)`, wait 1 frame, and assert the camera rotation is zero. Reset the setting to false. Set `sfx_volume` to 0.5 and assert the "SFX" bus volume is about -6 dB (±0.5), if that bus exists. Reset it to 1.0.

## T10b — Minigame clarity, keyboard shortcuts, controls hint

Files: `scripts/minigames/minigame.gd`, `o2_keypad.gd`, `reactor_sequence.gd`, `co2_adapter.gd`, `dust_storm_power.gd`, `scripts/ui/hud.gd`, NEW `tests/test_minigame_keys.gd`.

1. `minigame.gd`: add `func add_instruction(content: VBoxContainer, text: String) -> void`, which adds an amber Label (font 18, autowrap) at the top of the content box. Also update the hint label text to "Esc to close · keyboard shortcuts shown in [brackets]".
2. Each minigame calls `add_instruction` and handles keys in `_unhandled_input`, ignoring echoes. Show the shortcut in brackets on each button.
   - **O2 keypad:** "Type the filter code shown above, then press ENTER. One wrong code is fatal." Keys 0–9 and the numpad digits map to the digits, Backspace to CLR, Enter / KP Enter to ENTER.
   - **Reactor:** "Watch the sequence, then repeat it. A single wrong press is fatal." Keys 1–4 press buttons 0–3, and only while `accepting_input`.
   - **CO2 adapter:** "Follow the radio procedure on the left, in order. Skipping a step is fatal." Keys 1–4 press the *displayed* buttons left to right; map them through `order` to the correct-order step index.
   - **Dust storm:** "Drag the sliders so every system is at or above its minimum and the total is 90 or less, then ENGAGE." Enter engages. Tab moves focus between the sliders, which is Godot's default, so just make sure the sliders are focusable.

   Call `get_viewport().set_input_as_handled()` for every key you consume.
3. `hud.gd`: when `MalfunctionManager.run_started` fires, show a controls hint for 7 s and then fade it out over 0.5 s. It's a bottom-left panel, font 16: "WASD move · Mouse look · E interact · Hold B breathe · Esc pause". Build it in code, `mouse_filter` IGNORE.
4. Test: instance the O2 keypad. Send `InputEventKey` presses for each digit of `code` (keycode `KEY_0 + digit`, `pressed = true`), then `KEY_ENTER`, through `minigame._unhandled_input(event)`. Assert `completed` fired. Then instance the reactor, wait until `accepting_input`, send keys `KEY_1 + index` for the sequence, and assert completed.

## T10c — Relief-crew ending (reuse the emergency key's door)

Files: `scripts/stage1/stage1_controller.gd`, `scripts/ui/shift_complete.gd`, `data/voice_lines.json`, `tests/test_stage1_flow.gd`.

1. `stage1_controller.gd`: remove the emergency-key wiring. Remove the key's `@onready`, its `connect` and its handler. Set the key's `enabled = false` in `_ready` via `get_node_or_null("MainConsole/CenterStation/EmergencyReleaseKey")`, so it no longer shows a prompt. Leave the node in the scene.
   - Instead, on `MalfunctionManager.shift_completed`: call `$BulkheadDoors/NorthBulkheadDoor.unseal()`, `Voice.say("hal_relief")` and `Voice.say("crew_relief")`.
   - Keep the F1–F3 hotkeys.
2. `shift_complete.gd`: on `shift_completed`, wait 4.0 s *before* showing and pausing (`await get_tree().create_timer(4.0).timeout`), so the player sees the north door open and hears the lines. Skip the wait when `DisplayServer.get_name() == "headless"` (so the tests stay fast). Change nothing else.
3. `voice_lines.json`, add exactly:
   - `hal_relief` (hal): "Shift complete. Relief crew docking at the north airlock. You may stand down."
   - `crew_relief` (crew): "That's the relief crew! You did it. Go get some sleep, I've got it from here."
4. `test_stage1_flow.gd`: replace the emergency-key test with: instance the room, call `MalfunctionManager.start_run()`, set `survived_seconds = SHIFT_LENGTH - 0.05`, wait 0.3 s, and assert the north door `is_sealed()` is false while the east and west doors stay sealed. Unpause before quitting.

## T10d — Credits screen

Files: NEW `scripts/ui/credits_screen.gd`, `scripts/ui/title_screen.gd`, NEW `tests/test_credits.gd`.

1. `credits_screen.gd`: a full-rect Control with a dark background, a "CREDITS" title, a ScrollContainer and a "Back" button that emits `signal closed`. Expose `func full_text() -> String`, returning all of the content joined. The content, exactly:
   - **TEAM:** Calvin Gavin · Gerald Lê · Scott Sonnier · Eddie Summitt · Brandon Braswell
   - **SOUND EFFECTS:** Sonniss GDC 2015 Game Audio Bundle (sonniss.com): Coll Anderson (Metal Plate, Traditional Sirens) · Detunized (HumBuzz) · Eiravaein Works (Start Select) · Kpow Sounds (UI Soundpacks) · RDGSFX (The Metal Shelf) · SoundMorph (Solar Sky, Users of Tomorrow) · Timothy McHugh (Barefoot on Metal)
   - **VOICES:** HAL and Sam voiced with ElevenLabs (sponsor), from lines written by the team
   - **LIVE DATA:** NASA DONKI space weather API · Open Notify people-in-space API
   - **HISTORY:** incident summaries written by the team from public NASA and historical records
   - **ENGINE:** Godot Engine 4.7
   - **AI ASSISTANCE:** planning and review by Claude (Anthropic); implementation help by Gemini (Google Antigravity). No AI-generated images or video.
2. `title_screen.gd`: add a "Credits" button just above "Quit". It opens a CreditsScreen on top and closes it on `closed`, the same way the Mission log button works. Change nothing else.
3. Test: instance the credits screen. Assert `full_text()` contains "Sonniss", "Godot" and "Brandon Braswell". Then instance the title screen and assert a button containing "Credits" exists.
