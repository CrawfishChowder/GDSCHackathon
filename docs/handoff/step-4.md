# Step 4 handoff: life-support gauges, NASA solar flares, people in space

Branch: `step-4-life-support`. Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first. They hold the project rules, the autoload APIs and the test rules.
All paths below are relative to `red-alert/` unless they start with the repo root.

Rules for every task (on top of CLAUDE.md):
- Touch ONLY the files listed in your task. Other agents edit other files at the same time. Do not edit `docs/`, `CLAUDE.md` or `AGENTS.md`.
- You cannot run shell commands. Do not try. Do NOT create `.uid` files. Do NOT commit.
- Implement the stub in `scripts/systems/<your file>.gd` without changing its existing signatures (you may add private helpers).
- Build UI in code in `_ready()`. Each `.tscn` is a root node plus its script only.
- Tests: `extends SceneTree`; `await process_frame` first; look up autoloads with `root.get_node("Name")`; never cast to classes whose script uses autoloads; print `PASS` / `FAIL: <reason>`; `quit(0/1)`. **Tests must not touch the network.** Test the `parse_response()` functions with inline sample JSON.
- Network code: use an `HTTPRequest` child with `timeout = 8.0`. On any error or non-200 response, use the offline fallback. Never crash or block the game.
- Facts: use ONLY the text given here.
- Finish with a summary of at most 10 lines: files changed, anything unresolved, any deviation. Do not paste file contents.

All three tasks run in parallel.

---

## T4a — Life-support gauges (gemini-3.8-flash-high)

Files: `scripts/systems/life_support.gd`, NEW `scenes/ui/life_support_panel.tscn`, NEW `scripts/ui/life_support_panel.gd`, `scenes/ui/hud.tscn` (only to instance the panel), NEW `tests/test_life_support.gd`.

1. `life_support.gd` (`process_mode = ALWAYS`). In `_process`, read `MalfunctionManager`. While a malfunction is active, let `p = 1.0 - time_left / time_limit`, where `time_limit` comes from `MalfunctionManager.MALFUNCTIONS[active_id]["time_limit"]`. Move gauges toward these targets:
   - `o2` active: `o2 = 1.0 - 0.9 * p`
   - `power` active: `power = 1.0 - 0.9 * p` and `co2 = 0.9 * p` (the CO2 scrubbers lose power)
   - `reactor` active: `core_temp = 0.9 * p`
   - Every other gauge recovers toward healthy at 0.15 per second.

   Apply changes smoothly: move each value toward its target at up to 0.5 per second. Also:
   - Emit `level_critical(id)` once each time a gauge crosses into critical (o2 or power < 0.25, co2 or core_temp > 0.75), and implement `is_critical`.
   - On `MalfunctionManager.run_started`, reset all gauges to healthy.
2. `life_support_panel.tscn`: root `Control` named `LifeSupportPanel` with the script. Instance it in `hud.tscn` as a child of the root.
3. `life_support_panel.gd`: `process_mode = ALWAYS`. Top-right panel, about 260 px wide with a 16 px margin. Dark StyleBoxFlat like `minigame.gd` uses. It has a "LIFE SUPPORT" title and 4 rows, each a label plus a ProgressBar (0–100):
   - `O2 RESERVE`
   - `CO2 SCRUBBED` (show `100 - co2*100`, so a full bar is always good)
   - `POWER`
   - `CORE STABLE` (show `100 - core_temp*100`)

   **Accessibility:** each row also shows text, `"%d%%"` plus `"  CRITICAL"` when critical. So meaning never relies on color alone. Bar fill colors: healthy `Color(0.3, 0.8, 1.0)`, critical `Color(1.0, 0.35, 0.2)`. In critical, the text label blinks every 0.5 s.

   Below the bars, a small grey footnote (font size 12, autowrap) rotates every 8 s through exactly these lines:
   - "NASA plans for about 0.82 kg of oxygen per crew member per day."
   - "Each crew member exhales about 1 kg of carbon dioxide per day."
   - "When the scrubbers lose power, carbon dioxide builds up in the cabin."
   - "Apollo 13's crew had to build an improvised CO2 scrubber adapter to survive."
   - `mouse_filter = IGNORE` everywhere.
4. Test: get the `LifeSupport` and `MalfunctionManager` autoloads, then `start_run()`, `trigger("power")`, and set `time_left` to 10% of the limit. Wait 3 s, then assert that `power < 0.5`, `co2 > 0.4` and `is_critical("power")` are all true, and that `level_critical` fired for "power". Then `fix("power")`, wait 4 s, and assert `power > 0.5`.

---

## T4b — Real solar flares from NASA DONKI (gemini-3.8-flash-high)

Files: `scripts/systems/space_weather.gd`, `scripts/systems/malfunction_manager.gd`, `scripts/systems/voice.gd`, `data/voice_lines.json`, repo-root `.env.example`, NEW `tests/test_space_weather.gd`.

1. `space_weather.gd` (`process_mode = ALWAYS`):
   - In `_ready`, fetch `https://api.nasa.gov/DONKI/FLR?startDate=<30 days ago>&endDate=<today>&api_key=<key>`. Dates are `YYYY-MM-DD` via `Time.get_date_string_from_unix_time(Time.get_unix_time_from_system() - 30 * 86400)` and the same for today. `key = OS.get_environment("NASA_API_KEY")`, or `"DEMO_KEY"` when that's empty.
   - `parse_response(body)`: the body is a JSON array of objects with `classType`, `peakTime` and `beginTime`. Return `{"class_type": classType, "peak_time": peakTime, "source": "live"}` for the entry with the latest `peakTime` (string compare is fine). Return `{}` on anything invalid or for an empty array.
   - On success, set `latest_flare` and emit `flare_loaded`. On failure, set `latest_flare = {"class_type": "", "peak_time": "", "source": "offline"}` and emit it.
   - `difficulty_multiplier()`: if `class_type` starts with "X" return 0.8, if "M" return 0.9, otherwise 1.0.
   - **Wake report.** When `MalfunctionManager.run_started` fires, or when the flare loads during a running run (report only once per run), call `Voice.say_text("hal", text)`:
     - live: `"NASA DONKI space weather report. Latest solar flare: class %s, peaking %s UTC."`, using `peak_time` with the `T` replaced by a space and the `Z` removed
     - offline: `"Space weather feed offline. Assuming quiet solar conditions."`
   - **Mid-shift solar event.** If the flare class starts with "M" or "X", then once per run, when `MalfunctionManager.survived_seconds >= 150` and nothing is active: `MalfunctionManager.trigger("power")`, then `Voice.say("hal_flare_hit")`.
2. `malfunction_manager.gd`: in `trigger()`, multiply the time limit by `SpaceWeather.difficulty_multiplier()` when the `/root/SpaceWeather` node exists (use `get_node_or_null`, so the manager's own tests still pass without it). Change nothing else.
3. `voice.gd`: add `func say_text(speaker: String, text: String) -> void`. It queues a caption-only line (no audio file) with the same display and timing as `say()`. Store queued items so both kinds share the one queue. Keep `say()` and `is_speaking()` working.
4. `voice_lines.json`: add `hal_flare_hit` (HAL): "Solar particle event in progress. Radiation has disrupted the power grid."
5. `.env.example`: add `NASA_API_KEY=` with the comment "free key from api.nasa.gov; DEMO_KEY is used if empty". It's read from the OS environment.
6. Test (inline JSON, no network):
   - `parse_response` on a 2-entry array returns the later flare's `class_type`; on `"[]"` and `"oops"` it returns `{}`.
   - `difficulty_multiplier()` after setting `latest_flare` to X2.1, M1.0 and C3.0 gives 0.8, 0.9 and 1.0.
   - `Voice.say_text("hal", "test")` makes `Voice.is_speaking()` true.

---

## T4c — People in space right now (Open Notify) (gemini-3.8-flash-high)

Files: `scripts/systems/people_in_space.gd`, `scripts/ui/shift_complete.gd`, `scripts/ui/game_over.gd`, NEW `tests/test_people_in_space.gd`.

1. `people_in_space.gd` (`process_mode = ALWAYS`):
   - In `_ready`, fetch `http://api.open-notify.org/astros.json` (plain HTTP; this API has no HTTPS).
   - `parse_response(body)`: the JSON is `{"message": "success", "number": N, "people": [{"name": "...", "craft": "..."}]}`. Fill `count` and `names`, set `source = "live"`, emit `loaded(count, names)` and return true. On invalid data, return false.
   - On any failure, set `source = "offline"`.
   - `summary_line()`:
     - live: `"Right now, %d people are in space: %s."`, with names joined by ", " (at most 8, then `" and %d more"`)
     - pending or offline: `"Live crew data unavailable. More than 600 people have flown in space since 1961."`
2. `shift_complete.gd` and `game_over.gd`: add one Label (autowrap, grey, font size 16) under the existing stats, with the text `PeopleInSpace.summary_line()`. Set it when the screen is shown. Change nothing else in those files.
3. Test (inline JSON, no network):
   - A 3-person body gives `count == 3`, `source == "live"`, and a summary that contains all 3 names.
   - A 10-person body's summary contains "and 2 more".
   - `"not json"` returns false.
