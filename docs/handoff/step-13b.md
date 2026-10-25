# Step 13b handoff: un-cram for readability (mechanical, no behavior change)

Branch: `step-13-overnight`. Read `CLAUDE.md` (see the updated rule: **readability beats line count**).

The last pass squeezed scripts under 150 lines by joining several statements on one line with `;`. Undo that.

## T13e — One statement per line

Files (exactly these): `scripts/minigames/dust_storm_power.gd`, `minigame.gd`, `reactor_sequence.gd`; `scripts/ui/controls_panel.gd`, `credits_screen.gd`, `game_over.gd`, `heart_rate_overlay.gd`, `hud.gd`, `life_support_panel.gd`, `mission_log_screen.gd`, `pause_menu.gd`, `shift_complete.gd`, `survival_card.gd`.

- Split every line that joins statements with `;` into one statement per line, at the same indentation. Also split one-line `if cond: stmt` bodies onto their own lines.
- Keep the logic, the order of operations, the names, the strings and the comments exactly the same. This is purely mechanical. A file may grow past 150 lines; that's fine.
- Don't touch any other file. You cannot run shell commands. Don't create `.uid` files. Don't commit.
- Finish with a summary of at most 8 lines listing each file and its new line count.
