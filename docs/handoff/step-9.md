# Step 9 handoff: sound + game feel (overnight)

Branch: `step-9-overnight`. Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first. Paths are relative to `red-alert/`.

Rules (same as earlier steps):
- Touch ONLY the files listed in your task. Other agents edit other files at the same time. Do not edit `docs/`, `CLAUDE.md` or `AGENTS.md`.
- You cannot run shell commands. Do NOT create `.uid` or `.import` files. Do NOT commit. Do not read or modify the files in `assets/` (just load them by path).
- Every reacting script uses `process_mode = ALWAYS` where it must work while paused, and reaches autoloads with `get_node_or_null("/root/Name")`.
- **Headless safety:** when `DisplayServer.get_name() == "headless"`, create audio players but do NOT call `play()` (the test driver leaks looping or unfinished playback).
- Tests: `extends SceneTree`; `await process_frame` first; look up autoloads with `root.get_node("Name")`; no casts to autoload-using classes; record signals into a shared `var got := {}`. Print `PASS` / `FAIL: <reason>`, then `quit(0/1)`.
- Finish with a summary of at most 10 lines: files changed, anything unresolved, any deviation. Do not paste file contents.

All five tasks run in parallel. **Contract:** the `Sfx` autoload (stub in `scripts/systems/sfx.gd`):
- `play(id, at = null, volume_db = 0.0, bus = "SFX") -> Node` (pass a Vector3 for 3D sound)
- `get_stream(id) -> AudioStream`
- Ids: click, beep, beep_error, success, fail, clunk, creak, hiss, step, static, heartbeat, flatline, alarm_ping, hum, siren

---

## T9b1 — Sfx engine + buses + heartbeat + footsteps

Files: `scripts/systems/sfx.gd`, NEW `tests/test_sfx.gd`.

1. In `_ready`, create audio buses with `AudioServer.add_bus` (skip any that already exist), each sending to "Master":
   - "SFX", with an `AudioEffectReverb`: room_size 0.35, wet 0.12
   - "Voice"
   - "Radio", with `AudioEffectBandPassFilter` (cutoff_hz 1800) and `AudioEffectDistortion` (mode DISTORTION_OVERDRIVE, drive 0.15, post_gain -4)
2. Streams. For each id, if `ResourceLoader.exists("res://assets/sfx/%s.ogg" % id)`, load it. For `step`, load `step_1`, `step_2` and `step_3` and pick one at random on each play.
   Otherwise, generate an `AudioStreamWAV` in code (16-bit mono, 22050 Hz), keeping each generator small:
   - static: 0.4 s of filtered noise
   - heartbeat: a two-thump "lub-dub" of 60 Hz sine bursts, 0.5 s
   - flatline: a 1000 Hz sine, 3.0 s
   - fail: a descending saw, 0.6 s
   - anything else missing: a short 880 Hz blip
3. `play()`:
   - 2D: use a pool of 8 AudioStreamPlayers (`process_mode` ALWAYS).
   - 3D: when `at` is a Vector3, spawn an AudioStreamPlayer3D (unit_size 6, max_distance 25) under `get_tree().current_scene`, at that global position, and free it on `finished`.
   - Honor the headless rule.
4. Heartbeat: in `_process`, when `Stress.heart_rate > 95`, play `heartbeat` every `60 / bpm` seconds at volume `lerp(-24, -6, clamp((bpm - 95) / 60, 0, 1))` dB.
5. Footsteps: find `get_tree().current_scene.get_node_or_null("FirstPersonPlayer")`. When it `is_on_floor()` and its horizontal speed is above 1.0, play `step` (2D, -10 dB) every 0.42 s.
6. Test: every id in IDS gives a non-null `get_stream`; `play("click")` returns a node; the buses "SFX", "Voice" and "Radio" exist.

## T9b2 — Wire sounds into the game

Files:
- `scripts/minigames/o2_keypad.gd`, `reactor_sequence.gd`, `co2_adapter.gd`, `dust_storm_power.gd`
- `scripts/ui/minigame_host.gd`
- `scripts/stage1/breaker_box.gd`, `bulkhead_door.gd`, `console_chair.gd`, `do_not_press_button.gd`, `alarm_controller.gd`
- `scripts/systems/voice.gd`
- NEW `tests/test_sfx_wiring.gd`

Each call goes through `get_node_or_null("/root/Sfx")` and is a no-op when it's missing:
- **Minigames:**
  - every button or key press → `click` (keypad digits → `beep`)
  - reactor playback flashes → `beep`
  - slider changes → `click` (throttled to one every 0.08 s)
- **Host:** `completed` → `success`; `failed` → `beep_error` then `fail`.
- **Breaker:** cover toggle → `creak` at the box's position (3D); main breaker toggle → `clunk` (3D).
- **Door:** `unseal()` → `hiss` (3D, at the door).
- **Chair:** sit or stand → `click`.
- **DO NOT PRESS:** → `clunk` (3D), then after 0.3 s `siren`.
- **Alarm controller:**
  - Keep the procedural klaxon, but play it on bus "SFX" at -14 dB.
  - On `malfunction_started(id)`, also start a looping 3D `alarm_ping` (its own AudioStreamPlayer3D, stream from `Sfx.get_stream("alarm_ping")`, -6 dB) at that station's position, so the player can *hear* where to go. Stop it on fixed or died. The stations are:
    - reactor `(0, 1.4, 3.9)`
    - o2 `(-2.13, 1.4, 3.9)`
    - co2 `(2.13, 1.4, 3.9)`
    - power `(2.8, 1.55, -4.6)`
    - dust_storm `(5.6, 1.5, -3.6)`
- **Voice:**
  - HAL lines play on bus "Voice".
  - Sam (crew) lines play on bus "Radio", with `static` played on "SFX" at -12 dB just before and just after each crew line.
  - Captions are unchanged.
- **Test:** instance the room, `start_run()`, then `trigger("o2")`, and assert the AlarmController has a child AudioStreamPlayer3D. Then `fix("o2")` and assert it's stopped or freed.

## T9c1 — Camera feel: head bob + shake

Files: `scripts/player/first_person_controller.gd`, NEW `tests/test_camera_feel.gd`.
- **Head bob:** while on the floor and moving, offset `camera.position.y` by `sin(t * 9) * 0.035`, scaled by speed / move_speed, and `camera.position.x` by `cos(t * 4.5) * 0.02`. Ease back to 0 when stopped. Off while seated.
- **`func shake(strength: float, duration: float)`:** applies a random camera rotation offset (degrees: `strength * 1.5`) that decays to 0 over `duration`, and is added on top of the mouse look (don't touch `_target_pitch` / `_target_yaw`).
- **Auto-shake**, via MalfunctionManager signals connected in `_ready`:
  - `malfunction_started` → `shake(0.6, 0.5)`
  - `practice_mistake` → `shake(1.2, 0.6)`
  - `player_died` → `shake(2.0, 0.8)`
- Keep the file readable. Put the new logic in clearly named functions and change nothing else.
- **Test:** instance the player scene alone, call `shake(1.0, 0.3)`, wait 1 frame, and assert the camera rotation is non-zero. Wait 0.5 s and assert it's back near zero (`is_zero_approx` per axis, within 0.001).

## T9c2 — Death sequence + success flash

Files: `scripts/ui/game_over.gd`, `scripts/ui/shift_complete.gd`, NEW `tests/test_death_sequence.gd`.
- **`game_over.gd`:** when the mission log entry arrives, run a 2.6 s sequence BEFORE showing the existing panel, built in code on this layer:
  1. A full-screen red flash (alpha 0.5 → 0 over 0.25 s).
  2. A black "tunnel vision" ColorRect with a small canvas_item shader in code (radial: transparent center, black edges). Its radius uniform tweens from 1.2 to 0.0 over 2.0 s.
  3. `Sfx`: 3 `heartbeat` plays at increasing gaps (0.5, 0.8, 1.2 s), then `flatline`.
  4. Then fade the existing panel in (alpha 0 → 1 over 0.4 s).

  Use tweens with `set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)` (the tree is paused). R / Restart must work during the sequence too: skip it. Expose `func sequence_running() -> bool`.
- **`shift_complete.gd`:** on show, a cyan-white flash (alpha 0.4 → 0 over 0.5 s), then `Sfx.play("success")`. Change nothing else.
- **Test:** instance `hud.tscn`, then `MissionLog.record_death("o2", "mistake", "t")`, wait 0.2 s, and assert `GameOver.sequence_running()`. Wait 3.0 s and assert it's not running and `is_showing()`. Unpause the tree before quitting.

## T9c3 — CRT monitors + minigame transitions

Files: `scripts/stage1/monitor_display.gd`, `scripts/minigames/minigame.gd`, NEW `tests/test_crt.gd`.
- **`monitor_display.gd`:** replace the screen's unshaded StandardMaterial3D with a `ShaderMaterial` running a spatial shader written in code (`render_mode unshaded;`):
  - sample `uniform sampler2D screen_tex` (set to the viewport texture), with slight barrel curvature (0.08)
  - horizontal scanlines (`0.85 + 0.15 * sin(UV.y * 900)`)
  - a vignette toward the edges
  - a faint chromatic offset (0.0015 on R and B)
  - a subtle flicker (`0.97 + 0.03 * sin(TIME * 60)`)
  - `ALBEDO` = result × 1.25

  Keep `setup()`'s signature and return value.
- **`minigame.gd`:** when the panel is created in `make_panel`, start it at scale 0.92 and alpha 0, then tween to 1 / 1 over 0.18 s (TWEEN_PAUSE_PROCESS, so it works while paused). Keep the existing heart-rate shake working: it offsets position, which is independent of scale and alpha. Set `pivot_offset` to the panel's center once it's sized (deferred).
- **Test:** instance `stage_1_room.tscn` and wait 2 frames. Assert that the `MainConsole/ConsoleDisplays/CenterDisplay` mesh's material is a ShaderMaterial with a `screen_tex` parameter set. Then instance the O2 keypad minigame, wait 0.3 s, and assert its panel's modulate.a is 1.0 or more (within 0.01).
