# Red Alert: judge demo script (8 minutes)

## 1. Before judges arrive
- [ ] Laptop on wall power, volume up, game in fullscreen (**F11**).
- [ ] Settings → Show FPS. If it stays under 55, turn on **Performance mode**.
- [ ] Sit at the title screen. Check the live solar flare and people-in-space lines have loaded (offline text is fine too).
- [ ] Know the rules of the demo keys:
  - F1–F5 only work when **no crisis is active**.
  - F7 does **not** kill in Practice mode, so demo in **Start shift** or **Story shift**.
  - **R** restarts the run, and that resets which minigame variant comes next.

## 2. Timeline
| Time | Who | What |
|---|---|---|
| 0:00–0:45 | Gerald | 30-second pitch (below). On the title screen, point at the live NASA flare and the people in space now. Click **Start shift**. |
| 0:45–1:30 | Brandon | Walk to the consoles. Point out HAL (the computer) and Sam (the crewmate on the radio), captions, and the heart-rate display. Press **H** for the controls panel. |
| 1:30–2:30 | Gerald | Wait for the first crisis (about 10 s) or press **F3** (O2). Follow the `>> FIX HERE <<` sign, press **E**, solve the keypad. A survival card shows a real crew's story. |
| 2:30–3:15 | Gerald | Press **F3** again. The O2 station now opens the **other** minigame (seal the leaking joint). "Every crisis has two minigames." |
| 3:15–3:45 | Eddie | Press **F2**. Open the breaker cover, flip the main breaker OFF, then ON. |
| 3:45–4:30 | Brandon | Press **F7**. Read the death screen: the mission log names the real disaster (SL-1 or Chernobyl), and HAL reads it aloud. |
| 4:30–5:15 | Scott | Press **R**, then **F6**: 10 s later the shift ends, the north door opens for the relief crew, and the A–F grade and comparison with real astronauts appear. |
| 5:15–6:00 | Calvin, Scott | Short lines (below). |
| 6:00–8:00 | All | Questions. |

If a random crisis starts while you're talking, just fix it; that is the game working.

**Optional hardware (only if it's already connected before judges arrive):**
- **DualSense** (Scott): plug in by USB. Let a judge play with it; it rumbles on alarms, on death and with the heartbeat above 120 BPM.
- **PS Vita** (Brandon): laptop and Vita on the same hotspot, game allowed through Windows Firewall. Show the Vita's live telemetry while someone else plays. If it doesn't connect in 30 seconds, skip it and describe it during the questions.

## 3. The 30-second pitch (Gerald)
"Red Alert is a first-person survival game in a habitat module. Over a five-minute shift, systems break: reactor, power, oxygen, CO2 and dust storms. You fix each one with a short minigame, and one mistake kills you. Then the mission log tells you which real spaceflight disaster that mistake mirrors. We want players to leave thinking: astronauts really put their lives on the line."

## 4. Who says what
- **Scott:** "I built the habitat room, consoles, doors and chairs in Godot from basic shapes, in code. No downloaded or AI-generated models."
- **Eddie:** "I built the power failure. The breaker is a real reset procedure: off, then on. Flipping it once does nothing."
- **Calvin:** "We use two live APIs. NASA's DONKI gives the latest solar flare; a big flare shortens every countdown and causes a blackout. Open Notify tells you who is in space right now."
- **Brandon:** "I worked on the menus, captions, accessibility settings and the history. Every death and survival card is a real incident in our own words."
- **Gerald:** "The systems talk through global signals, so features don't call each other directly. 70 automated tests check it all."

## 5. If something goes wrong
- **No internet:** the APIs fall back to the last cached flare, then to offline text. The game is unaffected.
- **No voice audio:** captions show every line.
- **Low FPS:** Esc → Settings → Performance mode.
- **Vita or controller not responding:** skip it and keep going with the keyboard. Nothing in the game depends on them.
- **Stuck or crashed:** Esc → Restart, or close and relaunch the game. Practice mode never kills you if a judge wants to play.

## 6. Likely questions
- **Did you use AI?** Yes, disclosed in the README. Claude planned and reviewed, Gemini wrote much of the code from our tickets, and some of us used Codex and Copilot. We read and tested every change. No AI art or video. The voices are ElevenLabs, a sponsor.
- **Where did the art and sound come from?** All geometry is Godot primitives placed by us. Sounds are credited Sonniss GDC bundle effects plus sounds generated in code.
- **What if a laptop can't run it?** Performance mode (lower 3D resolution, no shadows, fog or glow), suggested automatically under 55 FPS.
- **What's original?** Every failure is tied to a real spaceflight emergency, so a mistake becomes a history lesson. And the DO NOT PRESS button remembers you.
- **What next?** A real heart-rate sensor (the hook already exists), more modules, and lesson notes for teachers.
