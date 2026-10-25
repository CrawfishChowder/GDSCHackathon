# Red Alert

**Team:** Calvin Gavin · Gerald Lê · Scott Sonnier · Eddie Summitt · Brandon Braswell
**Event:** LSU Geaux Hack 2026 · **Engine:** Godot 4.7 (GDScript)

> A first-person survival game in a habitat module. Over one five-minute shift, life-critical systems fail and you fix them by hand. One mistake kills you instantly, and the mission log tells you which **real spaceflight disaster** your mistake mirrors. Players leave thinking: *astronauts really put their lives on the line.*

---

## The problem
Space-safety history (Apollo 1, Soyuz 11, Apollo 13) is usually taught as dates and names. Red Alert makes it *felt*. Every crisis in the game is modeled on a real emergency, so every failure ends in a short, accurate lesson about what happened to a real crew, and every success shows how a real crew survived.

**Who it's for:** STEM classrooms, museums and science-outreach events, and anyone curious about what life support actually involves.

## Features
- **Five crises, each with its own fix:**
  - **Reactor:** repeat the control sequence at the center console
  - **Oxygen:** enter the filter code at the left console
  - **CO2:** build the Apollo 13 scrubber adapter, step by step, at the right console
  - **Power:** open the breaker cover and cycle the main breaker OFF, then ON
  - **Dust storm:** balance solar power between life support, heaters and comms at the east-wall array
- **Instant failure, real lessons:** a wrong move ends the run, and the mission log names the matching real incident: SL-1 (1961), Apollo 1 (1967), Soyuz 11 (1971), Apollo 13 (1970), or the Opportunity rover (2018).
- **Survival cards:** each fix shows how a real crew or mission pulled through: Apollo 12, Apollo 13, Kilopower, Spirit and Opportunity.
- **Cast:** HAL, the cold habitat computer, runs the alarms. Sam, a crewmate stuck in another module, guides you over the radio.
- **Heart rate:** your BPM climbs during alarms; above 120 your hands shake (minigames jitter). Hold **B** to breathe slowly and calm down.
- **Live data:**
  - the latest real solar flare from **NASA DONKI** (M/X-class flares shorten every countdown and trigger a mid-shift blackout)
  - the number and names of **people in space right now**, from Open Notify
- **Life-support gauges** for O2, CO2, power and core stability, with NASA planning figures in the footnotes.
- **End-of-shift report:** an A–F grade, the oxygen you "breathed" during the shift, and a comparison with real crews (Scott Kelly, Valeri Polyakov, Apollo 13).
- **The DO NOT PRESS button.** It kills you, and the game remembers how many times you pressed it.
- **Accessibility and personalization:**
  - always-on captions for every voice line
  - a high-contrast mode
  - adjustable mouse sensitivity, invert Y and volume
  - status is never shown by color alone (it always has text like "CRITICAL" or ">> FIX HERE <<")
  - Practice mode (no deaths) and a guided first-run tutorial

## How to run
1. Install **Godot 4.7** (standard build).
2. Open `red-alert/project.godot` in Godot and press **F5**.
3. Choose **Practice** for a first run (no deaths), **Start shift** for the real thing, or **Hard** (half the time).

Optional:
- **Live solar-flare data:** set a free NASA key with `export NASA_API_KEY=...`. Without one, the game uses `DEMO_KEY`, and when the API is unreachable it falls back to the last cached flare or an offline message.
- **Voice audio:** copy `.env.example` to `.env`, fill in your ElevenLabs key and voice IDs, then run `python3 tools/generate_voices.py`. Without the audio files, captions still play.

### Controls
| Key | Action |
|---|---|
| WASD / Mouse | Move / look |
| E | Interact (sit, open, fix) |
| B (hold) | Breathe slowly to lower your heart rate |
| Space | Jump |
| Esc | Pause menu (settings, restart, quit to title) |

### Demo keys (for judges)
| Key | Action |
|---|---|
| F1 / F2 / F3 | Reactor / power / O2 failure |
| F4 / F5 | CO2 / dust storm |
| F6 | Skip to the end of the shift |
| F7 | Instant failure (shows the mission log) |
| F12 | Show the list of demo keys |

### Tests
`tools/run_tests.sh` runs 33 headless test scenes plus a smoke run of the game, and prints one PASS/FAIL line per test.

## How it works
- **Autoload singletons** communicate through signals:
  - `MalfunctionManager` (timing, deaths, the shift)
  - `MinigameHost`, `MissionLog`, `Voice`, `LifeSupport`, `Stress`
  - `SpaceWeather` and `PeopleInSpace` (live APIs)
  - `Settings` and `SaveData`

  Features never call each other directly. For example, the alarm, monitors, gauges, voices and signs all react to `malfunction_started`.
- **Interaction:** a raycast from the camera finds the first node with an `interact()` method.
- **Pausing:** minigames pause the world, but the countdown keeps running.
- **Visuals:** the room, props, monitors (SubViewports), signs and sound effects are all generated in code from Godot primitives.

The full map is in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Data sources
- **NASA DONKI** (Space Weather Database Of Notifications, Knowledge, Information) solar flare API, `api.nasa.gov`. *External API #1.*
- **Open Notify** "people in space" API, `api.open-notify.org`. *External API #2.*
- **ElevenLabs** text-to-speech for the HAL and Sam voices. *Sponsor API; it doesn't count toward the limit.*
- **NASA life-support planning figures:** about 0.84 kg of oxygen consumed and about 1 kg of CO2 exhaled per crew member per day.
- **Historical incidents** (SL-1, Apollo 1, Apollo 12, Apollo 13, Soyuz 11, Spirit/Opportunity, Kilopower/KRUSTY), summarized in our own words from public NASA and historical records.

## Asset credits
- **All 3D geometry, UI, monitors and signage** were built by the team from Godot primitives (boxes, cylinders, labels, SubViewports). No downloaded models, textures or stock images.
- **The klaxon and ambient hum** are generated procedurally in code.
- **Voices:** generated with ElevenLabs (sponsor) from lines our team wrote.
- **No AI-generated images or video** are used anywhere in the project.

## AI use disclosure
AI tools assisted with this project, as allowed by the rules:
- **Claude (Claude Code):** planning, writing task tickets, code review, merge resolution, tests and documentation.
- **Gemini (Google Antigravity):** implementing most features from those tickets.

The team designed the game, wrote the briefs, reviewed and tested every change, and owns each system (see [`docs/QA_SHEET.md`](docs/QA_SHEET.md)). AI-authored commits are labeled in the git history. No external source code was given to the AI tools as reference.

## Team roles
| Member | Focus |
|---|---|
| Scott Sonnier | Room, console, doors, chairs (scene design) |
| Eddie Summitt | Power failure event and breaker |
| Gerald Lê | Architecture, malfunction loop, minigames, AI workflow |
| Calvin Gavin | Live data (NASA DONKI, Open Notify), life support |
| Brandon Braswell | UX, accessibility, voices, history content |

*(The roles mirror the Q&A sheet; adjust them to match who actually did what.)*

## License
Apache 2.0. See [LICENSE](LICENSE).
