# Step 14 handoff: more real survival stories

Branch: `step-13-overnight`. Read `CLAUDE.md` first. **Readability beats line count**: one statement per line, no `;`-joined statements.

## T14a — Rotating survival cards

Files: `scripts/ui/survival_card.gd`, NEW `tests/test_survival_variety.gd`.

1. Change the per-crisis card data from a single card to an **Array of cards** per id. Keep the existing cards exactly, and add these (exact text):
   - **power:** "Skylab (1973)": "During launch, Skylab's micrometeoroid shield tore away, taking one solar wing and jamming the other. The first crew deployed a parasol sunshade and freed the jammed solar wing on a spacewalk, saving the station."
   - **o2:** "Mir fire (1997)": "An oxygen-generating canister caught fire aboard the Mir space station. The crew put on masks, fought the fire with extinguishers and kept the station habitable."
   - **reactor:** "ISS ammonia leak (2013)": "When the International Space Station began leaking ammonia coolant, astronauts Chris Cassidy and Tom Marshburn made an unplanned spacewalk to replace a suspect pump controller box."
2. When showing a card for an id, pick randomly, but never the same card as last time for that id (if it has more than one).
3. Don't change the timing, layout, practice-mistake card or public functions (`current_title()`, `is_showing()`).
4. Test: call the show logic for "power" twice (expose `func show_for(id: String)`, used by the existing malfunction_fixed handler), and assert both titles come from the power list and differ. The test must not depend on random luck: with two cards and no-repeat, two consecutive picks always differ.

Rules: touch only these files, don't edit `.tscn`, don't run shell commands, don't create `.uid` files, don't commit. Finish with a summary of at most 8 lines.
