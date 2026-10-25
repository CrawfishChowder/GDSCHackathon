# Architecture

All paths are relative to `red-alert/` (`res://`). Main scene: `scenes/ui/title_screen.tscn` (Start / Practice / Hard → `scenes/stage1/stage_1_room.tscn`).

## Autoloads (project.godot, in load order)
| Name | File | Job |
|---|---|---|
| `SaveData` | `scripts/systems/save_data.gd` | Key/value store persisted to `user://save.json` (`get_value`, `set_value`, `increment`). |
| `Settings` | `scripts/systems/settings.gd` | Player settings (sensitivity, invert Y, volume, captions, high contrast) via SaveData; `settings_changed` signal. |
| `Stress` | `scripts/systems/stress.gd` | Heart rate (BPM) driven by alarms/mistakes; hold B to breathe; `external_heart_rate` hook for a real sensor. |
| `MalfunctionManager` | `scripts/systems/malfunction_manager.gd` | Run state: random failures with countdowns, deaths, the 5-minute shift. |
| `MinigameHost` | `scenes/ui/minigame_host.tscn` | Opens a minigame overlay, pauses the tree, routes completed/failed/cancelled. |
| `MissionLog` | `scripts/systems/mission_log.gd` | Records each death with its real-world incident; persisted via SaveData. |
| `Voice` | `scripts/systems/voice.gd` | Voice line queue (`data/voice_lines.json` + `assets/voice/<id>.mp3`), always-on captions, reacts to manager signals. |

Every autoload uses `PROCESS_MODE_ALWAYS`, so it keeps running while a minigame or end screen pauses the tree.

## MalfunctionManager API
- Signals: `run_started`, `malfunction_started(id, display_name, time_limit)`, `malfunction_fixed(id)`, `player_died(cause_id, display_name)`, `shift_completed`.
- State: `running`, `active_id`, `time_left`, `survived_seconds`, `fixes_count`, `death_kind` (`timeout` / `mistake` / `button`), `death_detail`.
- Methods: `start_run()`, `trigger(id)`, `fix(id)`, `kill(cause_id, kind, detail)`, `shift_time_left()`, `display_name(id)`.
- Cause ids: `reactor`, `power`, `o2`, `co2`, `dust_storm`, `do_not_press`. Grade stats: `close_calls`, `practice_mistakes` (see `ShiftGrade.compute`).
- `mode`: `normal` / `practice` (mistakes and timeouts emit `practice_mistake` instead of killing) / `hard` (half time). `countdown_frozen` pauses the timer (tutorial). One malfunction is active at a time, and the gap between them shrinks after each fix.

## Interaction
- `scripts/player/interactor.gd` (a RayCast3D on the camera, 3 m) walks up from the hit collider to the first node with `interact(by)`. It reads optional `prompt_text` and `enabled` from that node, and the HUD shows "[E] prompt".
- `Interactable` (`scripts/interaction/interactable.gd`) is an Area3D base on physics layer 2. `FixStation` extends it, is enabled only while its malfunction is active, and opens its minigame.
- `Minigame` (`scripts/minigames/minigame.gd`) is the Control base. It has signals `completed`, `cancelled` and `failed(reason)`, and a `make_panel(title)` helper. Minigames: `reactor_sequence`, `o2_keypad`, `co2_adapter`. Power is fixed physically at the breaker (Eddie's `PowerFailureEvent`: cover open, main breaker OFF then ON).

## Scene tree (stage_1_room.tscn)
```
Stage1IndustrialRoom (stage1_controller.gd: start_run, F1-F3, emergency key -> north door)
├─ WorldEnvironment
├─ Architecture/IndustrialRoomShell   (room geometry built in code, 12x10x3.5)
├─ BulkheadDoors/{North,East,West}BulkheadDoor   (bulkhead_door.gd: unseal(); DoorDisplay monitor)
├─ WallFixtures/NorthDoorBreakerBox   (breaker_box.gd: cover + main breaker; power fix)
├─ ConsoleChairs/{Left,Center,Right}ConsoleChair (Scott: E to sit / stand)
├─ EventDirector/PowerFailureEvent   (Eddie: red flash lighting; breaker OFF→ON calls fix("power"))
├─ WallFixtures/DoNotPressButton      (do_not_press_button.gd)
├─ MainConsole (components/main_console.tscn)
│   ├─ LeftStation/O2Station          (FixStation "o2")
│   ├─ RightStation/CO2Station        (FixStation "co2", Apollo 13 adapter checklist)
│   ├─ CenterStation/ReactorStation   (FixStation "reactor"), EmergencyReleaseKey
│   └─ ConsoleDisplays                (3 live MonitorDisplay screens: atmosphere / status / power)
├─ WallFixtures/SolarPanelStation    (east wall; FixStation "dust_storm", power balancing minigame)
├─ DemoHelper                         (F4 co2, F5 dust storm, F6 skip to shift end, F7 instant death, F12 key list)
├─ TutorialDirector                   (first-run guided O2 fix, countdown frozen)
├─ AlarmController                    (red lights + procedural klaxon)
├─ Polish/StationSignage              (station signs + ">> FIX HERE <<" cues)
├─ Polish/LightingDirector            (overhead light dimming/flicker, ambient hum, glow/fog)
├─ Polish/Doorways                    (corridor stubs behind N/E/W openings cut by the shell)
├─ Polish/RoomProps                   (pipes, vents, lockers, cable trays, hazard stripes)
└─ FirstPersonPlayer (scenes/player/first_person_player.tscn)
    ├─ Head/Camera3D/Interactor
    └─ HUD (hud.gd: prompt, alert banner, shift timer)
        ├─ GameOver       (death screen with mission log entry)
        ├─ HeartRateOverlay (BPM, "Hold B to breathe", red vignette)
        ├─ ControlsPanel   (H: grouped controls, auto-shown on first shift)
        ├─ PauseMenu      (Esc: resume / settings / restart / quit to title)
        ├─ SurvivalCard   (real success story on each fix; practice "would have killed you")
        └─ ShiftComplete  (win screen with real-astronaut comparison)
```

## Flow
`stage1_controller._ready` → `start_run()` → after 10 s, a random malfunction starts (alarm, HAL and Sam voice lines, HUD countdown) → the player presses E at the station → the minigame opens (tree paused, timer still running):
- success → `fix()`
- mistake → `kill("mistake")`
- countdown expires → `kill("timeout")`

`player_died` → MissionLog entry → GameOver. Surviving 300 s → `shift_completed` → north door opens for the relief crew (HAL + Sam lines) → ShiftComplete after 4 s. R restarts by reloading the scene.

## Tools
- `tools/run_tests.sh`: runs all tests plus a smoke run.
- `tools/generate_voices.py`: generates the ElevenLabs mp3s from `data/voice_lines.json` (needs `.env`).
