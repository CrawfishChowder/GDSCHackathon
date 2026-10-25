# Red Alert (GDSC / Geaux Hack 2026)

First-person survival game in a habitat module (Godot 4.7, GDScript). Survive a 5-minute shift: systems fail, you fix them with minigames, one mistake kills you and the mission log names the real spaceflight disaster it mirrors.

## Run / test
- Play: open `red-alert/project.godot` in Godot 4.7, F5. Demo keys F1/F2/F3 trigger reactor/power/O2.
- All tests + smoke run: `tools/run_tests.sh` (prints one PASS/FAIL line per test).
- Godot binary: `godot` (`/usr/local/bin/godot`).

## Read first
- `docs/ARCHITECTURE.md`: autoloads, signals, scene tree, where things live. Read this instead of scanning the code.
- `docs/handoff/step-*.md`: task tickets (historical; the code is the source of truth).

## Token rules
- Don't open `.godot/`, `*.import`, `*.uid` or `assets/`. Open `.tscn` files only when editing that scene. `main_console.tscn` is about 590 lines, so grep it for the node you need.
- Prefer `grep -n` and a targeted read over reading whole files.

## Code rules
- Typed GDScript, tabs, scripts ≤ 150 lines. Build UI and meshes in code in `_ready()`; keep `.tscn` files minimal.
- Cross-feature communication goes through autoload signals (see ARCHITECTURE).
- Anything interactable is a node with `interact(by)`, plus optional `prompt_text` and `enabled`.
- Tests are `extends SceneTree` in `red-alert/tests/`. They must look up autoloads with `root.get_node("Name")` and never cast to classes whose scripts use autoloads.

## Hackathon rules (break them = DQ or rubric loss)
- Code freeze **12:00 PM CDT Sun 2026-10-25**. No commits after.
- No AI-generated images/video/art. AI voice (ElevenLabs, sponsor) is OK. Credit any external assets in README.
- AI-written code must be disclosed in README. Don't feed external source code to AI.
- Max 2 external APIs (sponsor APIs exempt). Planned: NASA DONKI + Open Notify.
- Every teammate must be able to explain the code: keep it simple.
- Never commit `.env`.

## Workflow
Claude plans and reviews. Gemini (Antigravity CLI `~/.gemini/bin/agy -p ... --mode accept-edits`) implements tickets from `docs/handoff/`. Gemini cannot run shell commands headless, so Claude runs `tools/run_tests.sh` and commits.
