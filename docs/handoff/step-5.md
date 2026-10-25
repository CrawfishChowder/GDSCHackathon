# Step 5 handoff: scene polish (monitors, signage, lighting, doorways, props)

Branch: `step-5-scene-polish`. Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first. Paths are relative to `red-alert/`.

Rules for every task (on top of CLAUDE.md):
- Touch ONLY the files listed in your task. Other agents edit other files at the same time. Do not edit `docs/`, `CLAUDE.md` or `AGENTS.md`.
- You cannot run shell commands. Do not try. Do NOT create `.uid` files. Do NOT commit.
- The room scene already contains your node (`Polish/<Name>`) with a stub script. Implement that script; do NOT edit `stage_1_room.tscn`.
- Build everything in code in `_ready()`, from primitives (BoxMesh, CylinderMesh, QuadMesh, Label3D, lights) and procedural audio. No image files and no AI art.
- Look: dark industrial steel (`Color(0.12, 0.15, 0.18)`, metallic about 0.85, roughness about 0.4), cold cyan accents (`Color(0.3, 0.8, 1.0)`), red for danger, and yellow/black hazard stripes. Match the existing console.
- Any script that reacts to the game must set `process_mode = PROCESS_MODE_ALWAYS` (minigames pause the tree), and must reach autoloads with `get_node_or_null("/root/Name")`, so it still works when an autoload is missing.
- Accessibility: never signal state with color alone. Always pair color with text or shape.
- Tests: `extends SceneTree`; `await process_frame` first; look up autoloads with `root.get_node("Name")`; never cast to classes whose scripts use autoloads (use `Node`); print `PASS` / `FAIL: <reason>`; `quit(0/1)`.
- Finish with a summary of at most 10 lines: files changed, anything unresolved, any deviation. Do not paste file contents.

**Room layout (world coordinates; the floor is at y = 0, +Y is up):**
- The room is x −6…6, z −5…5, 3.5 m high. Walls are at z = −5 (north), z = 5 (south), x = −6 (west) and x = 6 (east).
- Bulkhead doors sit 0.22 m in front of the north, east and west walls, centered on each wall. Each door frame is 4 m wide and about 2.8 m tall.
- The console runs along the south wall: x −3.2…3.2, z 3.6…5, up to 3.3 m high.
- Its monitors face north (−Z):
  - Left screen: center `(-2.1, 2.2)`, size 1.4 × 0.64, front face at z = 4.48
  - Center screen: center `(0, 2.25)`, size 1.72 × 0.78, front face at z = 4.455
  - Right screen: center `(2.1, 2.2)`, size 1.4 × 0.64, front face at z = 4.48
- The overhead console header is at y = 3.02 with its front face at z = 4.44.
- Fix stations: `reactor` = center keyboard `(0, 1.2, 3.94)`, `o2` = left keyboard `(-2.13, 1.17, 3.94)`, `power` = breaker box `(2.8, 1.55, -4.78)` on the north wall.
- Other fixed objects:
  - DO NOT PRESS button at `(4.8, 0, 3.8)`
  - player spawn at `(0, 0.96, 2.7)`
  - door access monitors on the wall at x = −2.8 beside each door (in door-local space)
- Nine overhead OmniLights named `ColdOverheadLight_RR_CC` are created at runtime under `Architecture/IndustrialRoomShell`.

All five tasks run in parallel.

---

## T5a — Live console and door monitors (gemini-3.8-flash-high)

Files: NEW `scripts/stage1/monitor_display.gd`, NEW `scripts/stage1/console_displays.gd`, NEW `scripts/stage1/door_display.gd`, `scenes/stage1/components/main_console.tscn` (add ONE node), `scenes/stage1/components/sealed_bulkhead_door.tscn` (add ONE node), NEW `tests/test_monitors.gd`.

1. `monitor_display.gd`: `class_name MonitorDisplay extends Node3D`.
   - `func setup(size_m: Vector2, resolution: Vector2i) -> Control`: creates a `SubViewport` (that size, `render_target_update_mode = UPDATE_ALWAYS`, opaque) with a full-rect dark-navy `ColorRect` background, and a `MeshInstance3D` with a `QuadMesh` of `size_m`. The material is an unshaded `StandardMaterial3D` with `albedo_texture = viewport.get_texture()`.
   - It returns the root Control inside the viewport, for content. The quad faces +Z locally; callers rotate the node.
2. `console_displays.gd` (extends Node3D, `process_mode = ALWAYS`). Add it to `main_console.tscn` as `[node name="ConsoleDisplays" type="Node3D" parent="."]` with this script.
   - In `_ready`, create 3 MonitorDisplays at 512×256: `LeftDisplay`, `CenterDisplay`, `RightDisplay`.
   - Each sits at its screen center, with z 0.01 in front of the front face (so z − 0.01, toward the room), `rotation.y = PI`, and a size 0.04 smaller than the screen.
   - Update the labels 4 times a second (the code freeze is near, so keep it simple: Labels in a VBox, font sizes 18–40):
     - **Left, "ATMOSPHERE":** O2 % and CO2-scrubbed % from `LifeSupport.get_level`, each with "OK" / "CRITICAL" text.
     - **Center, "HABITAT STATUS":**
       - with an active malfunction: a big red display name in uppercase, the countdown `m:ss`, and `"GO TO: <station>"` (reactor → "CENTER CONSOLE", o2 → "LEFT CONSOLE", power → "BREAKER BOX, NORTH WALL")
       - otherwise: green "ALL SYSTEMS NOMINAL", `"SHIFT m:ss LEFT"` and `"FIXES n"`
       - after death: "CREW LOST"
     - **Right, "POWER / CORE":** power % and core-stable %, with OK/CRITICAL; `"SOLAR: <class> (NASA DONKI)"` or `"SOLAR: FEED OFFLINE"` from `SpaceWeather.latest_flare`; and `"IN SPACE NOW: <n>"` from `PeopleInSpace.count`, or "IN SPACE NOW: --".
3. `door_display.gd` (extends Node3D, `process_mode = ALWAYS`). Add it to the door scene root as `[node name="DoorDisplay" type="Node3D" parent="."]` with this script.
   - In `_ready`, create one MonitorDisplay at local `(-2.8, 1.64, 0.285)`, size 1.04 × 0.62, 384×224, with no rotation.
   - Text: the module name, chosen by the parent door's node name:
     - "North…" → "MODULE B: CREW QUARTERS"
     - "East…" → "AIRLOCK"
     - "West…" → "GREENHOUSE"
     - otherwise "MODULE"
   - Then the status, read from the parent's `is_sealed()` 4 times a second: "SEALED" in red or "OPEN" in green, followed by "PRESSURE NOMINAL".
4. Test: instance `stage_1_room.tscn` and wait 2 frames. Assert that `MainConsole/ConsoleDisplays` has 3 MonitorDisplay children. Then `MalfunctionManager.trigger("o2")`, wait 0.5 s, and assert that some Label under CenterDisplay has text containing "O2". Also assert that `BulkheadDoors/NorthBulkheadDoor/DoorDisplay` exists.

---

## T5b — Station signage and "fix here" cues (gemini-3.8-flash-high)

Files: `scripts/stage1/station_signage.gd`, NEW `tests/test_station_signage.gd`.

1. Static signs: Label3D with no billboard, `pixel_size = 0.004`, font size 64, a dark outline, facing north (`rotation.y = PI`), placed at the header front (z = 4.42, y = 3.02):
   - "O2 CONTROL" at x = −2.1
   - "REACTOR" at x = 0
   - "SYSTEMS" at x = 2.1

   Also "POWER BREAKERS" at `(2.8, 2.55, -4.72)` facing south (no rotation).

   Signs are cyan, and turn red and blink every 0.4 s while their system is the active malfunction.
2. Cues: one per station (`reactor`, `o2`, `power`). Each is a Node3D holding:
   - an OmniLight3D (orange-red, range 2.2, pulsing energy 0–2.5)
   - a billboard Label3D `">> FIX HERE <<"` (font size 48, pixel_size 0.004) that bobs ±0.05 m

   Positions: reactor `(0, 1.75, 3.7)`, o2 `(-2.13, 1.75, 3.7)`, power `(2.8, 2.25, -4.45)`.

   A cue is hidden unless its id is `MalfunctionManager.active_id`. Poll in `_process`; don't rely on signals alone.
3. Name the nodes `Sign_reactor`, `Sign_o2`, `Sign_systems`, `Sign_power`, `Cue_reactor`, `Cue_o2` and `Cue_power`, so tests can find them.
4. Test: instance the room and wait 2 frames. Call `trigger("power")` and wait 0.2 s. Assert `Polish/StationSignage/Cue_power` is visible and `Cue_o2` is hidden. Then `fix("power")`, wait 0.2 s, and assert `Cue_power` is hidden.

---

## T5c — Lighting and atmosphere (gemini-3.8-flash-high)

Files: `scripts/stage1/lighting_director.gd`, NEW `tests/test_lighting.gd`.

1. In `_ready`, `await get_tree().process_frame` (the room shell builds its lights in its own `_ready`). Then collect every OmniLight3D whose name begins with `ColdOverheadLight` under `../../Architecture/IndustrialRoomShell`, searching recursively, and remember each one's base energy.
2. Each frame (`process_mode = ALWAYS`), set a target multiplier:
   - power failure active → 0.15, plus a 5% chance per frame of a brief 0.5 flicker
   - reactor failure active → 1.0, but each frame with a 25% chance it dips to 0.4 (a nervous flicker)
   - otherwise → 1.0

   Move each light's energy toward `base * target` quickly: lerp factor `1 - exp(-8 * delta)`, or snap for flickers.
3. Ambient hum: an AudioStreamPlayer with a procedural looping `AudioStreamWAV`: 16-bit mono, 22050 Hz, 2.0 s. It's `0.06*sin(60 Hz) + 0.04*sin(120 Hz) + 0.01*noise`, at volume −16 dB, and it always plays.
   - During a power failure, lerp `pitch_scale` to 0.8 and the volume to −24 dB (the systems spinning down); otherwise back to 1.0 and −16.
   - Make the loop seamless: 2.0 s is a whole number of cycles for 60 and 120 Hz.
4. Environment: find `../../WorldEnvironment` and, at runtime, set `environment.glow_enabled = true`, `glow_intensity = 0.6`, `glow_bloom = 0.05`, `fog_enabled = true`, `fog_light_color = Color(0.05, 0.07, 0.09)`, `fog_density = 0.008`. Assign each in its own statement; unsupported ones are harmless.
5. Expose `func average_multiplier() -> float` (the mean of energy / base over all lights) for tests.
6. Test: instance the room and wait 3 frames. Assert that the director found at least 9 lights (expose `light_count()`). Then `trigger("power")`, wait 1.5 s, and assert `average_multiplier() < 0.5`. Then `fix("power")`, wait 1.5 s, and assert it's > 0.8.

---

## T5d — Real doorways and corridors (gemini-3.8-flash-high)

Files: `scripts/stage1/industrial_room_shell.gd`, `scripts/stage1/doorways.gd`, NEW `tests/test_doorways.gd`.

1. `industrial_room_shell.gd`: add `const DOOR_OPENING_WIDTH := 3.6` and `const DOOR_OPENING_HEIGHT := 2.6`, and cut a centered opening in the **north, east and west** walls (not south). Do this for BOTH:
   - the wall collision boxes in `_build_collision`
   - the visual wall boxes in `_build_base_shell`

   Replace each affected full-wall box with 3 boxes: one on the left of the opening, one on the right, and a header above it (from the opening height to the ceiling). Add a small helper for this, rather than repeating the math.

   In `_build_wall_panels` and `_build_structure`, skip any panel or column whose footprint overlaps an opening (horizontal overlap test along the wall, below `DOOR_OPENING_HEIGHT`). Keep everything else identical.
2. `doorways.gd`: in `_ready`, build a corridor stub behind each opening: 3.6 wide inside, 2.6 high, 3.0 deep. That's a floor, a ceiling, two side walls and an end wall (0.2 thick boxes, the room's steel material), all with `StaticBody3D` collision.
   - Each also gets one dim OmniLight (cyan-white, energy 1.2, range 4) and a Label3D on the end wall facing the room:
     - north → "CREW QUARTERS"
     - east → "AIRLOCK: EVA PREP"
     - west → "GREENHOUSE"

     (font size 72, pixel_size 0.004)
   - Plus a yellow/black hazard stripe on the floor at each threshold: alternating 0.3 m boxes, 0.01 high.
   - Corridors run north from z = −5 to −8 (x centered on 0), east from x = 6 to 9, and west from x = −6 to −9 (both centered on z = 0).
3. Test: instance the room and wait 3 frames. Disable `BulkheadDoors/NorthBulkheadDoor/DoorCollision`, then wait 2 physics frames. Raycast with `room.get_world_3d().direct_space_state` from `(0, 1.3, -4.0)` to `(0, 1.3, -9.5)` and assert that it hits with `position.z < -7.5` (the corridor end wall, not the old wall at −5). Also raycast from `(-3.5, 1.3, -4.0)` to `(-3.5, 1.3, -6.0)` and assert that it hits at z ≈ −5 (wall still solid beside the opening).

---

## T5e — Room props and detail (gemini-3.8-flash-high)

Files: `scripts/stage1/room_props.gd`, NEW `tests/test_room_props.gd`.

1. In `_ready`, add greebles in code to make the room feel like a lived-in habitat. Keep it ≤ 150 lines by using loops and a helper `_box(name, size, pos, color, collide := false)`:
   - Ceiling pipe runs: 3 CylinderMesh pipes (radius 0.06–0.1) along the east and west walls at y = 3.25, inset 0.25 m from the wall, running z −4.6…4.6, each with bracket boxes every 1.5 m. They stop 0.3 m short of the door openings: skip the z −1.9…1.9 span on the east and west walls.
   - Wall vents: 4 dark louvered vents (a 0.6×0.35 frame plus 5 slats) on the south wall above the console's end pylons, at x = ±4.6 and y = 2.6, and on the north wall at x = ±4.6, y = 2.6.
   - Storage: two locker columns (0.6×2.0×0.5, with collision) against the west wall at z = 3.2 and 4.0, x = −5.6, each with a thin handle and a small cyan status strip.
   - Cable trays: a cable tray box (0.3×0.06) along the north wall at y = 2.9, from x = −5.5 to −2.2 and from 2.2 to 5.5 (skip the door).
   - Floor: hazard stripe borders around the DO NOT PRESS button (a 1.2 × 1.2 square outline of alternating yellow/black 0.15 m boxes, 0.01 high, centered at `(4.8, 0.005, 3.8)`).
   - Keep clear of: the console (x −3.2…3.2, z ≥ 3.5), the doors and openings (3.6 m centered on the N, E and W walls), the breaker box (x 2.2…3.4 on the north wall, y 0.6…2.5), the door access monitors (x = −2.8 on the north wall, y 1.1…2.2; and the equivalent positions on the east and west walls, at z = +2.8 on the east wall and z = −2.8 on the west wall), and the player spawn.
2. Test: instance the room and wait 2 frames. Assert that `Polish/RoomProps` has at least 20 descendant MeshInstance3D nodes, and that no prop's global AABB center lies inside the console box (x −3.2…3.2, y 0…3.3, z 3.5…5).
