# Red Alert
A first-person survival game in a habitat module. Over one five-minute shift, life-critical systems fail and you fix them by hand. One mistake kills you instantly, and the mission log tells you which **real spaceflight disaster** your mistake mirrors. Players leave thinking: *astronauts really put their lives on the line.*

## Team
- [Gerald Lê](https://github.com/g34rmeister)
- [Brandon Braswell](https://github.com/brandonBraswell)
- [Eddie Summitt](https://github.com/EdwardSummitt)
- Calvin Gavin (GitHub link: TODO)
- Scott Sonnier (GitHub link: TODO)

## About
**What we built.** Red Alert is a Godot 4.7 game, in GDScript. You keep a habitat alive through one shift while its systems break. Each crisis is fixed at its own station:

| Crisis | Station | How you fix it |
|---|---|---|
| Reactor | center console | repeat the control sequence |
| Oxygen | left console | enter the filter code |
| CO2 | right console | build the Apollo 13 scrubber adapter, step by step |
| Power | breaker box | open the cover, cycle the main breaker OFF then ON |
| Dust storm | east-wall solar array | balance power between life support, heaters and comms |

Two characters guide you:
- **HAL**, a cold computer, runs the alarms.
- **Sam**, a crewmate stuck in another module, coaches you over the radio.

Your heart rate climbs under pressure, and above 120 BPM your hands shake (the minigames jitter). Hold **B** to breathe slowly.

**The problem it solves.** Space-safety history (Apollo 1, Soyuz 11, Apollo 13) is usually taught as dates and names. Red Alert makes it *felt*:
- **When you fail,** the run ends with an accurate lesson about the real incident: SL-1 (1961), Apollo 1 (1967), Soyuz 11 (1971), Apollo 13 (1970), or the Opportunity rover (2018).
- **When you succeed,** a card shows how a real crew pulled through: Apollo 12, Apollo 13, Kilopower, or Spirit and Opportunity.
- **At the end of the shift,** you see an A–F grade and a comparison with real crews (Scott Kelly, Valeri Polyakov, Apollo 13).

It's aimed at STEM classrooms, museums and outreach events.

**What we did.**
- **Systems:** the game is built around autoload singletons that talk through signals: the malfunction manager, minigame host, mission log, voice, life support, stress, settings and save data.
- **Built in code:** the room, props, live console monitors (SubViewports), signage, alarm klaxon and ambient hum are all generated in code from Godot primitives.
- **Accessibility and personalization:** always-on captions, high contrast, adjustable sensitivity, invert Y, volume, and status that's never shown by color alone. There's also a Practice mode (no deaths) and a guided first-run tutorial.
- **Tests:** 36 headless test scenes plus a smoke run, all run by `tools/run_tests.sh`.

**External tools and APIs.**
- **NASA DONKI** (`api.nasa.gov`): the latest real solar flare. M-class and X-class flares shorten every countdown and trigger a mid-shift blackout. If the API is unreachable, the game falls back to the last cached flare, then to an offline message. *External API #1.*
- **Open Notify** (`api.open-notify.org`): the number and names of people in space right now. *External API #2.*
- **ElevenLabs** (sponsor): text-to-speech for the HAL and Sam voice lines, generated from lines the team wrote, via `tools/generate_voices.py`.
- **Godot Engine 4.7:** the game engine.
- **NASA life-support planning figures:** about 0.84 kg of oxygen and about 1 kg of CO2 per crew member per day.
- **Historical facts:** summarized in our own words from public NASA and historical records.

**Boilerplate.** None, apart from the default files Godot generates for a new project (`project.godot`, `icon.svg`, `.gitattributes`, `.editorconfig`). No external starter code or templates were used.

**AI-generated / AI-assisted code.** This project used AI assistance, as the rules allow:
- **Claude (Claude Code):** planning, task tickets, code review, merge resolution, tests and documentation.
- **Gemini (Google Antigravity):** implemented most features from those tickets.

The team designed the game, wrote the briefs, and reviewed and tested every change. Each member owns and can explain specific systems (see [`docs/QA_SHEET.md`](docs/QA_SHEET.md)). AI-authored commits are labeled in the git history. The Vita controller POC references official VitaSDK and libvita2d API documentation and boilerplate examples for standard input, networking, display and packaging APIs; this work remains unmerged for team review.

No AI-generated images or video are used. All 3D geometry, UI and signage were built by the team from Godot primitives, and the sound effects are generated procedurally.

![Godot](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)
![GDScript](https://img.shields.io/badge/GDScript-typed-355570)
![NASA DONKI](https://img.shields.io/badge/API-NASA%20DONKI-E03C31)
![ElevenLabs](https://img.shields.io/badge/Voices-ElevenLabs-000000)

## Prerequisites
- **Godot Engine 4.7** (the standard build, not .NET): https://godotengine.org/download
- **Git**, to clone the repository.
- *Optional:* **Python 3**, to regenerate the voice lines with `tools/generate_voices.py`.

Make sure your tools are up to date. For example:
```bash
# Windows
winget upgrade GodotEngine.GodotEngine
# macOS
brew upgrade --cask godot
# Git, any platform with a package manager (example: Ubuntu)
sudo apt update && sudo apt upgrade git
```

## Build from source
1. Clone the repository:
   ```bash
   git clone https://github.com/CrawfishChowder/GDSCHackathon.git
   cd GDSCHackathon
   ```
2. Open `red-alert/project.godot` in Godot 4.7, either from the Project Manager or with `godot --path red-alert --editor`.
3. Press **F5** to run. The game starts at the title screen: choose **Practice** (no deaths), **Start shift** or **Hard** (half the time).

   To run it without opening the editor: `godot --path red-alert`.
4. *Optional:* get live solar-flare data with a free NASA key: `export NASA_API_KEY=your_key`. Without one, the game uses `DEMO_KEY`.
5. *Optional:* generate the voice audio. Copy `.env.example` to `.env`, fill in your ElevenLabs key and voice IDs, then run `python3 tools/generate_voices.py`. Without the audio files, captions still play.
6. *Optional:* run the tests with `tools/run_tests.sh`. It needs `godot` on your PATH.

There are no other dependencies to install; Godot runs the project directly.

## Extras
**Controls**
| Key | Action |
|---|---|
| WASD / Mouse | Move / look |
| E | Interact (sit, open, fix) |
| B (hold) | Breathe slowly to lower your heart rate |
| Space | Jump |
| Esc | Pause menu (settings, restart, quit to title) |

**Demo keys (for judges)**
| Key | Action |
|---|---|
| F1 / F2 / F3 | Reactor / power / O2 failure |
| F4 / F5 | CO2 / dust storm |
| F6 | Skip to the end of the shift |
| F7 | Instant failure (shows the mission log) |
| F12 | Show the list of demo keys |

**More**
- **The DO NOT PRESS button.** It kills you, and the game remembers how many times you pressed it.
- **Architecture map:** [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- **Team roles:**
  | Member | Focus |
  |---|---|
  | Scott | room, console, doors, chairs |
  | Eddie | power failure event and breaker |
  | Gerald | architecture, malfunction loop, minigames, AI workflow |
  | Calvin | live data and life support |
  | Brandon | UX, accessibility, voices, history content, IO (vita controller+dashboard, stretch:TENS) |
- **License:** Apache 2.0 (see [LICENSE](LICENSE)).
