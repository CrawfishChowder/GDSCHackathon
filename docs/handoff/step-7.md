# Step 7 handoff: adapt Eddie's power-failure event onto MalfunctionManager

Branch: `step-7-merge-main`, in the middle of merging `origin/main` (Scott's chairs and Eddie's breaker event). Claude has already resolved the merge conflicts. Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first. Paths are relative to `red-alert/`.

**Decision (team):** Eddie's breaker procedure is THE power fix. `MalfunctionManager` stays the single source of timing, deaths, the mission log and voices. When `power` fails:
- Eddie's red flashing alert lighting runs.
- The player fixes it physically: open the breaker cover, flip the main breaker OFF, then ON. That calls `MalfunctionManager.fix("power")`.
- The switch-matching power minigame is retired.

Rules: the same as in `docs/handoff/step-6.md` (touch only the listed files, no shell commands, no `.uid` files, no commits; tests look up autoloads by node path, use no network, and record signals into a shared Dictionary, not a local bool). Finish with a summary of at most 10 lines.

## T7a — Power event adapter (gemini-3.8-flash-high)

Files:
- `scripts/stage1/power_failure_event.gd`
- `scripts/stage1/event_director.gd`
- `scripts/stage1/breaker_box.gd`
- `scenes/stage1/components/breaker_box.tscn`
- `scripts/stage1/lighting_director.gd`
- `data/voice_lines.json`
- DELETE `scripts/minigames/power_switches.gd`, `scenes/minigames/power_switches.tscn` and `tests/test_minigame_power.gd`
- NEW `tests/test_power_breaker.gd`

1. `event_director.gd`: change the default `auto_start_event` to `&""`, so nothing auto-starts; MalfunctionManager decides when power fails. Keep `register_event` / `start_event` working.
2. `power_failure_event.gd`: rewrite it as a thin adapter (≤ 90 lines, `process_mode = ALWAYS`, autoloads via `get_node_or_null("/root/...")`).
   - Keep: registering with the EventDirector, and the `_room_shell`, `_breaker` and `_world_environment` references.
   - REMOVE: the `_screen_labels` (those Label3D nodes no longer exist; our live monitors show the status), `_player.die()`, and its own countdown (MalfunctionManager owns the countdown and the death).
   - On `MalfunctionManager.malfunction_started` with id `"power"`, call `start_event()`. That means: remember the ambient energy, set ambient to 0.2, set `_has_been_switched_off = false`, set active, and start the flash loop (toggle `_room_shell.set_alert_lighting(on)` every `flash_interval_seconds` in `_process`).
   - `_on_main_breaker_changed(is_on)` while active: off → `_has_been_switched_off = true`; on after off → `MalfunctionManager.fix("power")`.
   - On `malfunction_fixed("power")`, `player_died`, or `run_started`: if active, stop. That means `_room_shell.restore_overhead_lighting()`, restore the ambient energy, set inactive, and emit `event_finished(EVENT_ID, succeeded)` (true when fixed).
   - Expose `func is_active() -> bool`.
3. `breaker_box.gd` and `breaker_box.tscn`: remove the `PowerStation` FixStation node, its `fix_station.gd` / `power_switches.tscn` ext_resources and all `fix_station` code.
   - The `prompt_text` getter: if power is active (`/root/MalfunctionManager`.active_id == "power") and the cover is closed → "Open breaker cover (POWER FAILURE)"; otherwise "Close breaker cover" or "Open breaker cover".
   - `get_main_breaker_prompt()`: during a power failure, "Main breaker OFF (step 1 of 2)" while it's on, or "Main breaker ON (step 2 of 2)" while it's off. Otherwise keep the current text.
   - `interact` just toggles the cover.
4. `lighting_director.gd`: while `active_id == "power"`, do NOT write the overhead light energies (Eddie's flash owns them). Snap your stored per-light state when power ends, so there's no jump. Keep the reactor flicker and the hum changes.
5. `voice_lines.json`: set `crew_hint_power` to "Power's out! Breaker box by the north door. Open the cover, flip the main breaker off, then back on."
6. `tests/test_power_breaker.gd`:
   - Instance `stage_1_room.tscn`, wait 2 frames, then `MalfunctionManager.trigger("power")` and wait 0.2 s. Assert `EventDirector/PowerFailureEvent.is_active()`.
   - Get `WallFixtures/NorthDoorBreakerBox`: call `interact(null)` (open the cover), then `toggle_main_breaker()` (off), then `toggle_main_breaker()` (on), and wait 0.2 s.
   - Assert `MalfunctionManager.active_id == ""`, `fixes_count == 1` and that the event is inactive.
   - Also assert that flipping only OFF does not fix: run a second trigger and a single toggle, and check the malfunction is still active.
