# Judge Q&A sheet: who explains what

Each person owns a few systems and should be able to walk a judge through the files listed here. Read your section, open the files, and run the game once in **Practice** mode. The owner assignments are a suggestion; swap them as you like.

Rubric reminder: Presentation 9–10 requires that "the team answers all questions confidently and accurately".

---

## The 30-second pitch (everyone)
Red Alert is a first-person survival game in a habitat module. Over one 5-minute shift, systems break: reactor, power, O2, CO2 and dust storms. You fix each one at its station with a short minigame. One mistake kills you instantly, and the mission log tells you which real spaceflight disaster that mistake mirrors (Apollo 1, Soyuz 11, SL-1, Apollo 13). The goal is that players leave thinking "astronauts really put their lives on the line."

---

## Scott: room, console, doors, chairs
- **Files:** `scripts/stage1/industrial_room_shell.gd` (the room is built in code), `scenes/stage1/components/*`, `scripts/stage1/console_chair.gd`, `scripts/stage1/bulkhead_door.gd`, `scripts/stage1/doorways.gd`
- **How:** The room is generated from boxes in `_ready()`: walls, panels, lights and collision. The north, east and west walls have doorway openings cut into them, with corridor stubs behind. A chair calls `player.sit_in(self)`. Doors slide up with a tween in `unseal()`.
- **Likely Q: "Where did the 3D art come from?"** Everything is Godot primitives (boxes, cylinders, Label3D) placed by the team in code or in the editor. There are no downloaded or AI-generated models or textures.

## Eddie: power failure and breaker
- **Files:** `scripts/stage1/power_failure_event.gd`, `scripts/stage1/breaker_box.gd`, `scripts/stage1/breaker_handle_interactable.gd`, `scripts/stage1/event_director.gd`
- **How:** When `MalfunctionManager` starts the "power" failure, the event flashes the room red. The fix is physical: open the cover, flip the main breaker OFF, then ON. The breaker emits `main_breaker_changed`, and the event calls `MalfunctionManager.fix("power")`.
- **Likely Q: "Why off then on?"** It mirrors a real breaker reset procedure, so the order matters. Flipping it once does nothing.

## Gerald: architecture, malfunction loop, minigames
- **Files:** `scripts/systems/malfunction_manager.gd`, `scripts/ui/minigame_host.gd`, `scripts/minigames/*`, `scripts/interaction/*`, `scripts/player/interactor.gd`
- **How:** The game is organized around autoloads (global singletons, listed in `docs/ARCHITECTURE.md`).
  - `MalfunctionManager` picks a random failure, runs its countdown and emits signals. Everything else (the alarm, voices, monitors, gauges, signs) listens to those signals, so features never call each other directly.
  - The Interactor is a raycast from the camera. It walks up from whatever it hits to the first node with `interact()`.
  - Minigames pause the game, but the countdown keeps running, because the manager is set to `PROCESS_MODE_ALWAYS`.
- **Likely Q: "How do you know it works?"** There are 70 automated headless tests. `tools/run_tests.sh` runs them all plus a smoke run of the game.

## Calvin: real data and APIs
- **Files:** `scripts/systems/space_weather.gd` (NASA DONKI), `scripts/systems/people_in_space.gd` (Open Notify), `scripts/systems/life_support.gd`
- **How:**
  - At startup we fetch the latest solar flare from NASA's DONKI API. M-class and X-class flares shorten every countdown and cause a mid-shift blackout. If the API is down, we fall back to the last flare we cached, and after that to an offline message.
  - Open Notify gives the live number and names of people in space, shown on the title and end screens.
  - Both are fetched with Godot's `HTTPRequest`, with an 8 s timeout. Tests never touch the network.
- **Likely Q: "API limit?"** We use exactly 2 external APIs (DONKI and Open Notify). ElevenLabs is a sponsor API, so it doesn't count.
- **Likely Q: "Where do the numbers come from?"** The NASA planning figure of about 0.84 kg of oxygen per crew member per day, and about 1 kg of CO2 exhaled per day. They're used in the gauges' footnotes and on the end screen.

## Brandon: UX, accessibility, voices, history content
- **Files:** `scripts/ui/*` (title, pause, settings, HUD, game over, shift complete, survival cards), `scripts/systems/voice.gd`, `data/voice_lines.json`, `scripts/systems/mission_log.gd`, `scripts/stage1/tutorial_director.gd`
- **Accessibility:**
  - Always-on captions, and every voice line also appears as text
  - A high-contrast mode
  - Adjustable mouse sensitivity and invert Y
  - A volume setting
  - Status is never shown by color alone: there's always text such as "CRITICAL" or ">> FIX HERE <<"
  - Practice mode, where mistakes don't kill you
  - A first-run tutorial
- **Voices:** HAL (the computer) and Sam (the crewmate) speak 38 lines the team wrote, voiced with ElevenLabs (a sponsor) by `tools/generate_voices.py`. Sam plays through a band-pass "radio" bus. Every line is captioned too.
- **History:** every death and survival card uses vetted text about real incidents: SL-1 (1961), Chernobyl (1986), Apollo 1 (1967), Soyuz T-10-1 (1983), Soyuz 11 (1971), Apollo 13 (1970), the Opportunity (2018) and Spirit (2010) rovers, Apollo 12 (1969), Kilopower (2018), Skylab, the Mir fire and the ISS ammonia leak. Each cause has up to two incidents, chosen at random, never the same twice in a row.

## Newer systems (assign an owner)
- **Sound** (`scripts/systems/sfx.gd`): recorded Sonniss effects plus procedural ones, on three buses (SFX with room reverb, Voice, and Radio, a band-pass filter for Sam). Each broken station emits a 3D alarm ping, so you can hear where to go. Heartbeat audio follows your BPM.
- **Story shift** (`scripts/stage1/story_director.gd`): the random scheduler is switched off (`scripted`), and the director triggers fixed beats by shift time, ending with the relief crew opening the north door.
- **Heart rate** (`scripts/systems/stress.gd`): BPM rises with alarms and mistakes; above 120 the minigames shake; hold B to breathe. `external_heart_rate` is the hook for a real sensor.
- **Achievements, grade and timeline** (`achievements.gd`, `shift_grade.gd`, `history` in the manager): stored in `SaveData` (`user://save.json`).
- **Minigame variants** (`scripts/minigames/catalog.gd`): each crisis has two minigames. The station picks when the crisis starts: the original first (it's what the tutorial teaches), then it alternates.
- **Robustness:** every timer wait re-checks that its node still exists, every pausing screen can unpause, and minigames ignore input after they finish. These are covered by four robustness test suites.
- **Likely Q: "How do you handle a laptop that can't run it?"** Settings has a Performance mode (3D at 0.75 scale, no shadows, fog or glow, monitors at 15 Hz), suggested automatically if FPS stays under 55, plus shadows, VSync, fullscreen, text scale and an FPS counter. MSAA is always off and the monitor screens are capped at 512×288.

---

## Questions anyone may get
- **"Did you use AI?"** Yes, and it's disclosed in the README. Claude planned and reviewed; Gemini (Antigravity) wrote much of the implementation from our tickets; some of us also used GPT Codex and GitHub Copilot. We read and tested all of it, and each of us owns and can explain our part. There's no AI-generated art or video. The voices are ElevenLabs, a sponsor.
- **"What's original here?"** Every failure is tied to a real spaceflight emergency, and a mistake is a lesson rather than just a game over. Plus the DO NOT PRESS button that remembers you.
- **"Real-world impact?"** STEM education and outreach (museums, classrooms). It makes space-safety history felt instead of memorized, and every run ends by comparing you with real crews.
- **"What would you do next?"** A real heart-rate sensor (the code already has an `external_heart_rate` hook), more modules, and teacher-facing lesson notes for each incident.
- **"Why Godot?"** It's free and open source, its GDScript is quick to learn, and a whole team can work in plain-text scene files with git.
