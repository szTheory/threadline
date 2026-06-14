# Phase 168: accessibility-verification - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 168 proves the light token lane is **accessible** — it invents no tokens,
colors, type, or layout. It is a *verification / enforcement* phase: it turns the
accessibility guarantees into measurable, source-first contracts (test assertions +
e2e re-runs) so contrast and interaction affordances hold in BOTH dark and light
modes, enforced by the contract rather than by eyeball. (Requirements A11Y-01,
A11Y-02.)

Three deliverables, all bounded by the approved `168-UI-SPEC.md`:

1. **A11Y-01 — the AA contrast mirror.** Extend `style_contract_test.exs` with a
   light-lane mirror of the existing dark contrast test (`phase 143`, line 653),
   plus **alpha-aware parsing** so `rgba(...)` tokens (status-tint backgrounds,
   accent washes, the focus-ring alpha layers) are no longer silently dropped.
   Every text-bearing token clears WCAG 2.1 AA 4.5:1 in both modes, including
   status text **composited over its own tint background**.
2. **A11Y-02 part 1 — focus-ring non-text contrast.** The solid 1px `border-focus`
   edge clears 3:1 (SC 1.4.11) against focusable-control surfaces in both modes;
   the `outline:none`-forbidden + `:focus-visible` restore guard holds per mode.
3. **A11Y-02 part 2 — interaction states + e2e affordance re-run.** Hover / active
   / disabled / selected resolve to a perceptible delta in each lane, and the
   `operator-accessibility.spec.ts` affordance suite is re-run under the light lane.

The 45-token dual-lane system already exists (Phase 166, `style.ex`) and was
retuned + human-reviewed in Phase 167 (`167-UI-SPEC.md`, `LIGHT-REVIEW.md`). This
phase does **not** re-derive tokens. The deliverable is **proof**, not pixels.

</domain>

<spec_lock>
## Requirements (locked via 168-UI-SPEC.md)

**The approved `168-UI-SPEC.md` is the locked design/verification contract.**
Downstream agents MUST read it before planning or implementing. It is not a
greenfield design contract — it locks the *measurable accessibility contracts*
the planner turns into tests, every value anchored to existing `style.ex` line
ranges. The token-pair contrast table, thresholds, focus-ring contract,
interaction-state table, and alpha-aware compositing rules are NOT duplicated
here — read the SPEC.

**Hard constraints (from 168-UI-SPEC.md — carry into every plan/task):**
- **Source-first contract.** Contrast is asserted in-source by
  `style_contract_test.exs` reading `style.ex` directly (the `phase 143` pattern,
  line 653). No runtime axe/contrast dependency is added to the library.
- **Dark byte-stability.** Dark token values and base rules are untouched; the
  original `phase 143` dark contrast test and frozen-hex catalog pass unchanged.
  The seven theme-aware assertions and the `theme-toggle` ban (test lines 11–29)
  stay intact.
- **Additive light lane only.** Any contrast/focus failure is fixed by an additive
  `[data-tl-theme="light"]` (+ mirrored `@media (prefers-color-scheme: light)
  [data-tl-theme="system"]`) token-alpha/value tune — never a base-rule rewrite,
  never a dark-token edit. A new value not derivable from the 45-token lane is
  FLAGGED, not invented.
- **No new theme UI** (carried from Phases 166/167).
- **Do not touch the uncommitted nav-overhaul lane** (~29 files; incl. its 3
  pre-existing test failures).
- **WCAG 2.1.** Text/icon-text → AA **4.5:1**; non-text (focus ring, UI boundaries)
  → **3:1** (SC 1.4.11). These literals are encoded as-is; not relaxed.

**In scope:** the light-lane AA contrast mirror with alpha-aware/compositing
parsing; the focus-ring 3:1 contract; per-mode interaction-state assertions; the
`operator-accessibility.spec.ts` light-lane re-run.

**Out of scope:** new tokens/colors/type/layout/copy; any dark-token or base-rule
edit; theme-toggle UI; the `__light__` screenshot baseline lane and example-app
`theme: :system` demonstration (Phase 169); brandbook token parity (Phase 170);
the nav-overhaul lane.

</spec_lock>

<decisions>
## Implementation Decisions

These three appetite/mechanism calls were the only gray areas the SPEC delegates;
everything else is locked by `168-UI-SPEC.md` + carried from Phase 167.

### e2e light-lane re-run mechanism (A11Y-02 part 2)
- **D-01: Playwright `colorScheme: 'light'` emulation.** Re-run
  `operator-accessibility.spec.ts` against the existing operator surface with
  Playwright `colorScheme: "light"`, driving the `[data-tl-theme="system"]` light
  branch. Chosen over a dedicated `theme: :light` example-app route because it adds
  **zero example-app code footprint**, reuses the existing spec assertions verbatim,
  proves the `:system` light render path (otherwise only source-asserted), and keeps
  example-app theme demonstration in **Phase 169's** lane (roadmap-assigned). The
  SPEC lists a dedicated `:light` route as its first option; this decision selects
  the SPEC's second (emulation) option as lowest-friction. The re-run must assert the
  *same* affordance set (focus `box-shadow` non-`none`, chip border non-`0px`/non-
  `none`, `aria-current`, `aria-pressed`, dialog semantics, no horizontal overflow).

### Failure-fix autonomy (when the AA/focus mirror surfaces a sub-threshold pair)
- **D-02: Carry Phase 167 D-04 — bounded alpha autonomy.** If a composited pair
  falls below 4.5:1 (or the focus edge below 3:1), execution autonomously
  alpha/value-tunes the **existing** light-lane tokens — uniform at the lane root,
  the `LIGHT-REVIEW.md` item-A pattern (strengthen `*-bg`/`*-border` alpha across
  all riders), **never per-component**, never a hue change. Both the light and the
  mirrored `system` branch are edited in the same task. Execution does not pause for
  these in-lane tunes.
- **D-03: Carry Phase 167 D-05 — new-token halt.** A genuinely new hue, new
  primitive, or any value **not derivable** from the existing 45-token lane is
  FLAGGED and PAUSES for a user decision — not silently invented. (Phase 167 already
  tuned the known-weak danger/warning tint pairs (item A) and coverage hover polarity
  (item B); D-02/D-03 govern any *newly*-surfaced failure this phase finds.)

### Disabled-text (`--tl-color-muted-soft`) strictness
- **D-04: Strict-by-default, bounded exemption fallback.** Assert `muted-soft` at
  **4.5:1** against `surface`/`surface-raised` in both modes (Threadline's
  "disabled stays legible by default" posture). ONLY if a tune cannot reach 4.5:1
  without breaking the "disabled looks disabled" read may the planner downgrade the
  **disabled-token rows only** to "exempt — documented" with an explicit code comment
  citing WCAG 1.4.3 (inactive controls). No other contrast row is exemptable.

### Claude's Discretion
- **Parser placement** — extend `color_tokens/1` in place vs. add a sibling
  alpha-aware parser (the SPEC permits either), provided it parses `#RRGGBB`,
  `rgba(r,g,b,a)` (and `#RRGGBBAA` if any appear) and composites translucent tokens
  over the correct **per-mode** opaque base (`#141B2D`/`#FFFFFF` for surface tints,
  page bg for page-level) before luminance math.
- **Exact form/organization** of the new contract assertions and the light-mirror
  token-pair table within `style_contract_test.exs`, provided they cover every row in
  the SPEC's "Token pairs the mirror MUST assert" table in both modes.
- **Lowest-friction wiring** of the Playwright `colorScheme` re-run (new spec project/
  config vs. parameterized existing spec), provided the same affordance set is asserted.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope & Locked Contract
- `.planning/phases/168-accessibility-verification/168-UI-SPEC.md` — **the approved
  locked verification contract.** Token-pair contrast table, thresholds, alpha-aware
  compositing rules, focus-ring 3:1 contract, interaction-state table, e2e re-run
  contract, verification outcomes. Read first.
- `.planning/ROADMAP.md` §"Phase 168" — goal, requirements (A11Y-01, A11Y-02),
  execution order, milestone non-goals.
- `.planning/REQUIREMENTS.md` — A11Y-01, A11Y-02 definitions.
- `.planning/STATE.md` — decision ledger [165-01], v1.36 continuity, the standing
  nav-overhaul caution.

### Prior-Phase Decisions (carried forward)
- `.planning/phases/167-component-retune/167-UI-SPEC.md` — the retuned light lane this
  phase measures; color roles, accent-reserved-for list, family source anchors.
- `.planning/phases/167-component-retune/LIGHT-REVIEW.md` — the human-judgment fail-list.
  **Item A** (danger/warning tint weak on white) and **item B** (coverage `.tl-table`
  hover polarity) are the already-fixed weak pairs; the item-A pattern (uniform
  lane-root alpha strengthening) is the template for D-02 autonomous fixes.
- `.planning/phases/167-component-retune/167-CONTEXT.md` — D-04 bounded-alpha autonomy
  and D-05 new-token-halt, carried verbatim into D-02/D-03 here.
- `.planning/phases/166-unfreeze-token-lane-mechanism/166-CONTEXT.md` — additive
  light-lane CSS mechanism, dual-branch (`light` + `system`) discipline, the 45-token
  lane values.

### Source Contracts
- `lib/threadline/operator_surface/style.ex` — the dark base block + 45-token light
  lane; light root `:188–237`, system branch `:240–289`; focus ring `:157` (dark) /
  `:236` (light); `:focus-visible` restore `:350–356`; `--tl-hit-area` `:156`. All
  interaction-state and contrast source anchors are cited by file:line in the UI-SPEC.
- `test/threadline/operator_surface/style_contract_test.exs` — source-first style
  contract. Existing dark contrast test (`phase 143`) at line 653; dark token pairs
  `:668–685`; the hex-only `color_tokens/1` helper `:1058–1062` (the parser to make
  alpha-aware); behavioral focus guard `:688`. Extend here for A11Y-01 + A11Y-02 part 1.
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` — the dark
  affordance suite re-run under the light lane for A11Y-02 part 2 (`expectFocused`
  `:18–24`; retention `data-confirm` `:168`).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`style_contract_test.exs`** — already reads `style.ex` as a raw string and
  asserts contrast on dark token pairs (`phase 143`, line 653). The light mirror is a
  natural extension of the same test; the `color_tokens/1` helper (`:1058–1062`) is
  the single parsing chokepoint to make alpha-aware.
- **45-token light lane** (`style.ex:188–289`) — every light value the mirror measures
  already exists; any D-02 fix tunes these tokens, never literals.
- **`operator-accessibility.spec.ts`** — the full affordance assertion set already
  exists; the light re-run reuses it verbatim under `colorScheme: "light"`.

### Established Patterns
- **Source-first contract amendment** (166 D-05): `style.ex` + `style_contract_test.exs`
  move in the same wave because the test reads the source directly. Any D-02 token tune
  and its new/updated assertion land together.
- **Dual-branch additive discipline** (166/167): every light override edits both the
  `[data-tl-theme="light"]` lane and the mirrored `@media (prefers-color-scheme: light)
  [data-tl-theme="system"]` branch in the same task. The mirror test asserts both.
- **Alpha-aware compositing** (new this phase): translucent token composited over the
  per-mode opaque base before luminance — `effective = src.rgb * a + base.rgb * (1 - a)`.

### Integration Points
- The ten LiveView roots already render `data-tl-theme` (166 D-02) — no root changes
  this phase. All work is inside `style_contract_test.exs` + (only if a failure is
  surfaced) additive `style.ex` light-lane token tunes + the e2e spec config.

</code_context>

<specifics>
## Specific Ideas

- **The parsing gap is the technical heart of A11Y-01.** The current hex-only
  `color_tokens/1` silently drops every `rgba(...)` token, so status text is never
  actually measured against the tint background it paints on. Making the parser
  alpha-aware + compositing-aware is what unlocks the composited-tint rows the dark
  test cannot see — it is mandatory, not optional.
- **The focus contract hinges on the opaque 1px edge**, not the 3px translucent halo:
  assert the solid `border-focus` edge at 3:1; composite-and-*report* the halo so a
  low-alpha halo cannot mask a failure.
- **No large-text 3:1 carve-out.** Threadline holds ALL text-bearing tokens (incl.
  ≥18px headings) to the single 4.5:1 bar, matching the dark contract. Don't grant the
  WCAG large-text exemption.
- Phase 167 already fixed the two known light failures (item A danger/warning tint,
  item B coverage hover). A green-on-arrival mirror is the expected outcome; D-02/D-03
  exist for anything the formal math newly surfaces.

</specifics>

<deferred>
## Deferred Ideas

- `__light__` screenshot baseline lane + example-app `theme: :system` demonstration +
  adopter docs — **Phase 169** (the visual/appearance proof; this phase proves
  behavior/affordance only).
- Brandbook `tokens.json` / `tokens.css` 45-token parity — **Phase 170**.

### Reviewed Todos (not folded)
The `todo.match-phase` matcher surfaced three Phase-167 deferred seeds via keyword
overlap ("light/phase/167/mode") — none are accessibility-verification scope:
- `coverage-schema-card-declutter.md` (item C) — structural de-clutter, not a11y; future polish phase.
- `theme-picker-idiomatic-ui.md` (item D, `THEME-TOGGLE-01`) — blocked by the [165-01] theme-toggle ban; demand-gated.
- `transaction-page-left-push-desktop.md` (item E) — theme-independent desktop layout bug; not in this verification lane.

</deferred>

---

*Phase: 168-accessibility-verification*
*Context gathered: 2026-06-13*
