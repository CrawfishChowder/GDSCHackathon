# Step 3 handoff: Must items (instant fail + mission log, shift + astronaut stats, DO NOT PRESS, voices)

Branch: `step-2-malfunctions`. Godot 4.7. Project root `red-alert/` (all `res://` paths relative to it).

Pitch: a first-person survival game in a habitat module. You keep yourself and the base alive through one 5-minute shift. Systems fail and you fix them with short minigames. **One mistake kills you instantly**, and the mission log tells you which real spaceflight disaster that mistake mirrors. Goal: players leave thinking "astronauts really put their lives on the line."
Cast: **HAL**, the habitat computer (cold, clipped, formal), handles the alarms. **Sam** is a crewmate stuck in another module (warm, encouraging, a little funny) and guides you over the radio.

Hackathon rules (Geaux Hack), apply to every task:
- No AI-generated images, video or art. Use Godot primitives/UI built in code only.
- Do not paste or reference external source code.
- Keep code simple, typed, and commented where non-obvious. Each script ≤ 150 lines.
- **Historical facts:** use ONLY the text given in this file. Do not add dates, names or numbers of your own.

Rules for every task:
- Typed GDScript, tabs, match the style of `red-alert/scripts/systems/save_data.gd`.
- Touch ONLY the files listed in your task. Other agents edit other files at the same time. Do not edit `docs/`.
- You cannot run shell commands. Do not try. Do NOT create `.uid` files.
- Build UI and meshes in code inside `_ready()`. Each `.tscn` is a root node plus its script only.
- Tests: `extends SceneTree`, `add_child` then `await process_frame` before touching nodes, print `PASS` or `FAIL: <reason>`, `quit(0/1)`. Copy the pattern of `tests/test_manager_shift.gd`.
- **Tests must NOT use autoload names as identifiers** (`MalfunctionManager.x` fails to compile in a test script). Look them up instead: `var mm: Node = root.get_node("MalfunctionManager")`, and the same for `SaveData`, `MissionLog`, `Voice` and `MinigameHost`. For the same reason, never type or cast test variables as `FixStation`, `GameOver` or any class whose script uses an autoload; use `Node`. See `tests/test_stage2_flow.gd`. (Game scripts may use autoload names normally.)
- Do NOT commit.
- Finish with a summary of at most 10 lines: files changed, anything unresolved, any deviation. Do not paste file contents.

All four tasks run in parallel.

---

## Existing contract (already implemented; read, don't change)

`MalfunctionManager` (autoload, `scripts/systems/malfunction_manager.gd`):
- Signals: `malfunction_started(id, display_name, time_limit)`, `malfunction_fixed(id)`, `player_died(cause_id, display_name)`, `shift_completed`, `run_started`.
- Members: `running`, `active_id`, `time_left`, `survived_seconds`, `fixes_count`, `death_kind` (`"timeout"`, `"mistake"` or `"button"`), `death_detail`, `SHIFT_LENGTH` (300).
- Methods: `start_run()`, `trigger(id)`, `fix(id)`, `kill(cause_id, kind, detail)`, `shift_time_left()`, `display_name(id)`.
- Cause ids: `"reactor"`, `"power"`, `"o2"`, `"do_not_press"`.

`SaveData` (autoload): `get_value(key, default)`, `set_value(key, value)`, `increment(key) -> int`. Persists to `user://save.json`.

`MinigameHost` (autoload): `current`, `open(scene, id)`, `close()`, `is_open()`.

`Minigame` (`scripts/minigames/minigame.gd`): signals `completed`, `cancelled`; `complete()`, `cancel()`, `make_panel(title)`.

`MissionLog` (autoload, `scripts/systems/mission_log.gd`): a stub with fixed signatures. T3a implements it.

`Voice` (autoload, `scripts/systems/voice.gd`): a stub with fixed signatures (`say(line_id)`, `is_speaking()`). T3d implements it.

---

## T3a — Instant fail + mission log (gemini-3.8-flash-high)

Files:
- `scripts/minigames/minigame.gd`
- `scripts/ui/minigame_host.gd`
- `scripts/minigames/reactor_sequence.gd`, `power_switches.gd`, `o2_keypad.gd`
- `tests/test_minigame_reactor.gd`, `test_minigame_power.gd`, `test_minigame_o2.gd`
- `scripts/systems/mission_log.gd`
- `scripts/ui/game_over.gd`
- NEW `tests/test_mission_log.gd`

1. `minigame.gd`: add `signal failed(reason: String)` and `func fail(reason: String) -> void` (emits it).
2. `minigame_host.gd`: in `open`, connect `current.failed` so that it frees the minigame (same as the existing `_on_player_died` path, with no mouse recapture), then calls `MalfunctionManager.kill(malfunction_id, "mistake", reason)`.
3. Change the minigames so that a mistake is an instant `fail()` with no retry:
   - **Reactor:** a wrong `press()` → `fail("You pressed the wrong control in the sequence and pulled the core out of safe limits.")`. Remove the replay-on-wrong logic.
   - **Power:** `toggle(i)` leaving `switches[i] != target[i]` (flipping a breaker that should stay off, or turning one off that is already correct) → `fail("You energized the wrong circuit in an oxygen-rich cabin.")`.
   - **O2:** ENTER with a wrong code → `fail("You entered the wrong code and vented the oxygen supply.")`.
   - Update each minigame's test: keep the success path, and add a check that a wrong input emits `failed` (and not `completed`).
4. `mission_log.gd`: implement the stub (keep the signatures). Use exactly this INCIDENTS text:
   ```
   "reactor": title "SL-1 reactor accident", year "1961",
     summary "At the SL-1 test reactor in Idaho, a control rod was withdrawn too far during maintenance. The reactor went prompt critical in milliseconds and all three operators were killed.",
     lesson "Reactor procedures exist because a single wrong movement is unrecoverable."
   "power": title "Apollo 1 fire", year "1967",
     summary "During a launch rehearsal, a spark from damaged wiring ignited the pure-oxygen cabin of Apollo 1. Gus Grissom, Ed White and Roger Chaffee died within seconds.",
     lesson "In oxygen-rich air, one electrical fault can become a fire faster than anyone can react."
   "o2": title "Soyuz 11 depressurization", year "1971",
     summary "As Soyuz 11 separated for re-entry, a valve opened and vented the cabin's air into space. Georgy Dobrovolsky, Vladislav Volkov and Viktor Patsayev are the only people to have died in space.",
     lesson "Breathable air is the thinnest margin a crew has."
   "do_not_press": title "The Button", year "",
     summary "There is no real-world precedent. Every astronaut ever flown has managed not to press it.",
     lesson "Spaceflight checklists exist so nobody touches a control just to see what happens."
   ```
   - In `_ready`: `process_mode = PROCESS_MODE_ALWAYS`, load `entries` from `SaveData.get_value("mission_log", [])`, and connect `MalfunctionManager.player_died` → `record_death(cause_id, MalfunctionManager.death_kind, MalfunctionManager.death_detail)`.
   - Entry keys: `cause_id`, `kind`, `detail`, `title`, `year`, `summary`, `lesson`, `survived_seconds`, `fixes`, `unix_time` (`Time.get_unix_time_from_system()`).
   - Keep at most 50 entries.
5. `game_over.gd`: show the screen on `MissionLog.entry_added(entry)` instead of on `player_died`, so the entry is always ready. Add these to the screen:
   - a "MISSION LOG" heading
   - `detail`
   - `title` with the year in parentheses (when year isn't empty)
   - `summary` (autowrap, max width about 700 px)
   - `lesson` in italics or grey
   - "Crew lost on this station: N" (`MissionLog.entries.size()`)

   Keep Restart and R working.
6. `test_mission_log.gd`: use a fresh `MalfunctionManager`-independent call: `MissionLog.record_death("power", "mistake", "x")`. Assert the returned entry's title is "Apollo 1 fire", `last_entry == entry`, that `entry_added` fired, and that `entries` grew by 1.

---

## T3b — 5-minute shift + end-of-shift astronaut comparison (gemini-3.8-flash-high)

Files: NEW `scenes/ui/shift_complete.tscn`, NEW `scripts/ui/shift_complete.gd`, `scripts/ui/hud.gd`, `scenes/ui/hud.tscn`, NEW `tests/test_shift_complete.gd`.

1. `shift_complete.tscn`: root `CanvasLayer` named `ShiftComplete`, `layer = 20`, script `shift_complete.gd`. Instance it as a child of the root in `hud.tscn`, next to GameOver.
2. `shift_complete.gd`: `process_mode = ALWAYS`, hidden at start. On `MalfunctionManager.shift_completed`, show it, pause the tree and make the mouse visible. Build in code:
   - a full-screen ColorRect `Color(0, 0.08, 0.12, 0.92)`
   - a centered VBox (autowrap labels, max width about 760 px) with:
     - "SHIFT COMPLETE" (font size 52, cyan)
     - "You kept the habitat alive for %d:%02d and fixed %d failures."
     - "You breathed about %.1f g of oxygen. NASA plans for about 0.82 kg per crew member per day.", where grams = `820.0 * survived_seconds / 86400.0`
     - a "HOW REAL CREWS COMPARE" heading, followed by exactly these three lines:
       - "Scott Kelly: 340 consecutive days aboard the International Space Station (2015–2016)."
       - "Valeri Polyakov: about 437 days aboard Mir (1994–1995), the longest single spaceflight."
       - "Apollo 13: after an oxygen tank exploded (1970), the crew survived nearly four days in a crippled spacecraft and made it home."
     - "Crew lost on this station before you: N" (`MissionLog.entries.size()`)
     - a "New shift [R]" Button
   - Restart works like `game_over.gd`: unpause, then `reload_current_scene()`. Expose `is_showing()`.
3. `hud.gd`: change StatsLabel to `"SHIFT %d:%02d LEFT   FIXES %d"` using `MalfunctionManager.shift_time_left()`. Leave everything else alone.
4. Test: instance `hud.tscn` under root, call `MalfunctionManager.start_run()`, set `survived_seconds = SHIFT_LENGTH`, wait 0.2 s, and assert ShiftComplete `is_showing()`. Before quitting, unpause the tree.

---

## T3c — DO NOT PRESS button (gemini-3.8-flash-high)

Files: NEW `scenes/stage1/components/do_not_press_button.tscn`, NEW `scripts/stage1/do_not_press_button.gd`, `scenes/stage1/stage_1_room.tscn`, NEW `tests/test_do_not_press.gd`.

1. `.tscn`: root `Node3D` named `DoNotPressButton` with the script.
2. Script (extends Node3D). In `_ready`, build in code:
   - a `StaticBody3D` with a BoxShape3D 0.5 × 1.1 × 0.5 centered at y = 0.55, for the raycast
   - a pedestal MeshInstance3D (BoxMesh 0.45 × 1.0 × 0.45 at y = 0.5, dark yellow-black `Color(0.2, 0.17, 0.02)`)
   - a red button: a CylinderMesh (radius 0.12, height 0.08) at y = 1.04, emissive red
   - a `Label3D` "DO NOT PRESS" (billboard, font size 48, red, y = 1.45)
   - a second `Label3D` (font size 28, grey, y = 1.3) showing `"Pressed %d times" % count` when the saved count is above 0, hidden otherwise

   Members:
   - `var prompt_text: String = "DO NOT PRESS"`
   - `var enabled: bool = true`
   - `func interact(_by: Node = null) -> void` (the Interactor already finds nodes with `interact()` by walking up from the StaticBody)

   On interact (only once per run):
   - set `enabled = false`
   - tween the button mesh down 0.03 m
   - `count := SaveData.increment("do_not_press_count")`, then update the label
   - `Voice.say("hal_button_%d" % mini(count, 3))`
   - wait 2.0 s (`get_tree().create_timer(2.0)`)
   - `MalfunctionManager.kill("do_not_press", "button", "You pressed the button. Total presses on record: %d." % count)`
3. Room: add a `DoNotPressButton` instance under `WallFixtures` at position `(4.8, 0, 3.8)`. That's the south-east corner: clear of the console, which ends at x = 3.2, and of the east door, which spans z from -2 to 2.
4. Test: instance the room, call `MalfunctionManager.start_run()`, then find the button. Read the count first, call `interact(null)`, wait 2.3 s, and assert that the count went up by 1, that `MalfunctionManager.death_kind == "button"` and that `running == false`. Then unpause the tree.

---

## T3d — Voice lines, captions, ElevenLabs generator (gemini-3.8-flash-high)

Files: `scripts/systems/voice.gd`, NEW `data/voice_lines.json` (`res://data/voice_lines.json`), NEW `assets/voice/.gitkeep`, NEW repo-root `tools/generate_voices.py`, NEW repo-root `.env.example`, NEW `tests/test_voice.gd`.

1. `voice_lines.json`: `{ "<id>": {"speaker": "hal" | "crew", "text": "..."} }`. Write every one of these ids, each line 1–2 short sentences:
   - **HAL** (cold, formal, never uses contractions, states numbers):
     - `hal_wake`: shift start
     - `hal_welcome_back`: the player has pressed the button before
     - `hal_alarm_reactor`, `hal_alarm_power`, `hal_alarm_o2`: failure announced, with its time limit (45, 40 and 50 seconds)
     - `hal_warning_10`: ten seconds left
     - `hal_death`
     - `hal_button_1`, `hal_button_2`, `hal_button_3`: escalating disappointment after pressing the button
   - **Sam** (warm, encouraging):
     - `crew_wake`: introduces themself, stuck in the other module, will guide you over the radio
     - `crew_hint_reactor`: "center console"
     - `crew_hint_power`: "breaker box beside the north door, open the cover first"
     - `crew_hint_o2`: "left console"
     - `crew_fixed_reactor`, `crew_fixed_power`, `crew_fixed_o2`
     - `crew_shift_done`
2. `voice.gd`: implement the stub (keep the signatures).
   - `process_mode = ALWAYS`. Load the JSON in `_ready`.
   - Build a caption CanvasLayer (layer 15) in code: a bottom-center Label, font size 22, a dark semi-transparent PanelContainer behind it, and autowrap with a max width of about 900 px.
     - Show `"HAL: <text>"` in `Color(0.55, 0.85, 1.0)`, or `"SAM (radio): <text>"` in `Color(1.0, 0.8, 0.45)`.
     - Captions always show. That's the accessibility feature.
   - Queue lines and play them one at a time. If `ResourceLoader.exists("res://assets/voice/%s.mp3" % id)`, play it on an AudioStreamPlayer and wait for `finished`. Otherwise, wait `1.2 + 0.06 * text.length()` seconds. Use `create_timer(t, true)` so it still runs while paused. Hide the caption when the queue is empty.
   - Director logic: connect MalfunctionManager signals:
     - `run_started` → `hal_wake`, then `crew_wake`, then `hal_welcome_back` if `SaveData.get_value("do_not_press_count", 0) > 0`
     - `malfunction_started(id)` → `hal_alarm_<id>`, then `crew_hint_<id>`
     - `malfunction_fixed(id)` → `crew_fixed_<id>`
     - `player_died` → clear the queue, stop audio, say `hal_death`
     - `shift_completed` → `crew_shift_done`
   - In `_process`, say `hal_warning_10` once per malfunction when `time_left < 10`.
3. `tools/generate_voices.py` (Python 3, standard library only):
   - Read `red-alert/data/voice_lines.json`.
   - Read `ELEVENLABS_API_KEY`, `ELEVENLABS_VOICE_HAL` and `ELEVENLABS_VOICE_CREW` from the environment, or from a repo-root `.env` file (simple KEY=VALUE parsing).
   - For each line, POST to `https://api.elevenlabs.io/v1/text-to-speech/<voice_id>` with header `xi-api-key` and JSON `{"text": ..., "model_id": "eleven_multilingual_v2"}`.
   - Write the response bytes to `red-alert/assets/voice/<id>.mp3`. Skip files that already exist unless `--force` is passed. Also support `--only <id>`.
   - Print one line per file. Exit non-zero with a clear message if the key is missing.
4. `.env.example`: those three keys with empty values and a comment saying "never commit .env".
5. `test_voice.gd`: call `Voice.say("hal_wake")` and wait 0.2 s. Assert `is_speaking()` and that the caption label text starts with "HAL:". Also assert that every id listed above exists in the loaded JSON.
