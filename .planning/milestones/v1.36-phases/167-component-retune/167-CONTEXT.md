# Phase 167: component-retune - Context

**Gathered:** 2026-06-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 167 retunes every dark-tuned visual effect in the operator surface into an
explicitly-designed light treatment — nothing ships into light unreviewed or
merely recolored. Three workstreams, all bounded by the approved 167-UI-SPEC.md:

1. **COMP-01 — the ~9 dark-effect families** (glass topbar/shell-nav/toolbar/
   coverage-command/subview-header, drawer scrim, drawer shadow, focus glow,
   home-card signature effects, shell-nav active inset): confirm the Phase 166
   token-recolor is correct; author an additive `[data-tl-theme="light"]`
   override only where confirmation fails.
2. **COMP-01/TOKEN-02 — the ~20 tint-riders** (status chips, alerts, timeline
   facts, op badges, redaction rows, policy-drift rows, job-error states):
   verification-only that they resolve through the shared status-tint system; a
   per-component light override is OUT of contract unless a family is *proven*
   to misresolve.
3. **COMP-02 — data-viz design review** (coverage / timeline / diff): explicit
   light-mode design review against named criteria (the Grafana lesson),
   recorded as human-gateable judgment.

This is a *retune + verification* phase, not greenfield design. The 45-token
light lane already exists (Phase 166, `style.ex:187–287`). This phase does not
re-derive tokens.

</domain>

<spec_lock>
## Requirements (locked via 167-UI-SPEC.md)

**The approved 167-UI-SPEC.md is the locked design contract.** Downstream agents
MUST read it before planning or implementing. Per-family dispositions, tint-rider
list, data-viz review criteria, color roles, and accent-reserved-for list are not
duplicated here.

**In scope (from UI-SPEC):**
- Additive `[data-tl-theme="light"]` (+ mirrored `system`/`prefers-color-scheme: light`)
  overrides for any of the ~9 families whose token-recolor is *proven* to fail.
- Verification that the ~20 tint-riders resolve correctly through the shared
  status-tint system (no new per-component CSS).
- Explicit light-mode design review of coverage / timeline / diff surfaces.

**Out of scope (from UI-SPEC + ROADMAP non-goals):**
- Rewriting any base `.tl-*` rule or touching dark token values (dark byte-stability).
- New spacing, type, copy, or layout (light is a *value* lane, not a layout lane).
- Runtime theme-toggle UI, segmented control, or theme settings surface.
- Screenshot `__light__` baseline lane (Phase 169), AA mirror test (Phase 168),
  brandbook token parity (Phase 170).
- The uncommitted nav-overhaul lane (~29 files; incl. its 3 pre-existing failures).

</spec_lock>

<decisions>
## Implementation Decisions

### Review sequencing (the STATE human gate)
- **D-01: Review-first.** The user eyeballs the *current* Phase 166 token-recolor
  rendered live across `:dark` / `:light` / `:system` BEFORE override-authoring.
  That review produces the disposition list (which families pass, which fail)
  that drives which override tasks exist. This satisfies the STATE human gate
  ("eyeball the rendered light surface before retune effort is spent") and the
  UI-SPEC's confirm-first default — you cannot know which of #1/#5/#8 fail without
  looking.
- **D-02:** The planner MUST structure the live review as an explicit early gate
  whose output (the proven fail-list) is the input to the override-authoring tasks
  — not as an end-of-phase check.

### Override appetite
- **D-03: Confirm-strict.** Author an additive override ONLY for families the live
  review proves fail. No pre-judging. This honors the UI-SPEC default disposition
  and Hard Constraint 1 (minimal additive surface; dark base untouched). The
  spec's flagged high-risk trio (#1 glass-vs-page distinctness, #5 scrim strength,
  #8 signal-line read) get explicit review but are NOT pre-authored.

### FLAG handling mid-execution
- **D-04: Bounded alpha autonomy.** The planner pre-authorizes bounded alpha
  tuning of *existing* tokens (e.g. lowering glass `surface-tint` alpha, bumping
  the `backdrop` scrim alpha) — the UI-SPEC explicitly calls this "still additive."
  Execution proceeds on these without pausing.
- **D-05:** A genuinely NEW token (new hue, new non-blur primitive, any value not
  derivable from the existing 45-token lane) is FLAGGED and PAUSES for a user
  decision — not silently invented. (Blur radii may reuse `--tl-blur-*`.)

### Proof mechanism ("nothing ships unreviewed")
- **D-06: Both a source-contract test and a committed review checklist.**
- **D-07: Source-contract test** — extend `style_contract_test.exs` (it already
  reads `style.ex` as a string and asserts the frozen dark catalog) to assert:
  (a) each authored light override selector is present in the light lane, and
  (b) **no stray per-component `[data-tl-theme="light"]` selector exists for the
  ~20 tint-riders** — proving they ride the shared status-tint system. This is the
  CI guard for the TOKEN-02 "out of contract unless proven" invariant.
- **D-08: Committed review checklist** (`LIGHT-REVIEW.md` or equivalent in the
  phase dir) records the per-family disposition for the ~9 families and the
  named-criteria pass/override-needed outcome for each data-viz surface
  (coverage / timeline / diff). The UI-SPEC requires the data-viz review be a
  human-gateable judgment "recorded... not just a passing test" — this checklist
  IS the deliverable that satisfies it. Phase 169's screenshot lane is the later
  visual backstop, not a substitute here.

### Claude's Discretion
- Exact name/location of the review-checklist artifact, provided it lives in the
  phase dir and records dispositions explicitly.
- Exact form of the new `style_contract_test.exs` assertions, provided they prove
  D-07 (a) and (b) against the `style.ex` source.
- Internal organization of the additive override blocks within `style.ex`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope & Locked Contract
- `.planning/phases/167-component-retune/167-UI-SPEC.md` — **approved locked design
  contract.** Per-family dispositions, tint-rider list, data-viz review criteria,
  color roles, hard constraints. Read first.
- `.planning/ROADMAP.md` §"Phase 167" — goal, requirements (COMP-01, COMP-02),
  execution order, milestone non-goals.
- `.planning/REQUIREMENTS.md` — COMP-01, COMP-02, TOKEN-02 definitions.
- `.planning/STATE.md` — decision ledger [165-01], v1.36 continuity, the pending
  human light-lane review gate, and the standing nav-overhaul caution.

### Prior-Phase Decisions (carried forward)
- `.planning/phases/166-unfreeze-token-lane-mechanism/166-CONTEXT.md` — D-03 CSS
  mechanism (additive light lane, `color-scheme` flip), D-04 token lane values,
  D-07 worktree safety.
- `.planning/milestones/v1.35-phases/165-light-mode-strategy/165-LIGHT-MODE-RECOMMENDATION.md`
  — approved mechanism and v1.36 phase breakdown.
- `.planning/milestones/v1.35-phases/165-light-mode-strategy/165-RESEARCH-SURFACE.md`
  — change-surface map with file:line sizing for the retune.

### Source Contracts
- `lib/threadline/operator_surface/style.ex` — the dark base block + 45-token light
  lane (lines 187–287); all family source anchors cited by file:line in the UI-SPEC.
- `test/threadline/operator_surface/style_contract_test.exs` — source-first style
  contract; frozen dark catalog + theme-aware assertions; extend here for D-07.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **45-token light lane** (`style.ex:187–287`) — every light value this phase needs
  for confirm-only families already exists; overrides reference these tokens, never
  literals.
- **`style_contract_test.exs`** — already reads `style.ex` as a raw string and
  asserts presence/absence of selectors and frozen hexes; the natural home for the
  D-07 tint-rider invariant and authored-override assertions.

### Established Patterns
- **Additive override discipline** (166 D-03): base `.threadline-ui` stays dark;
  light is `[data-tl-theme="light"]` + a mirrored `@media (prefers-color-scheme:
  light) [data-tl-theme="system"]` branch. Every override edits both branches in
  the same task.
- **Source-first contract amendment** (166 D-05): style + contract test move in the
  same wave because the test reads the source directly.

### Integration Points
- The ten LiveView roots already render `data-tl-theme` (166 D-02) — no root changes
  this phase; all work is inside `style.ex` value lanes + the contract test +
  the review checklist artifact.

</code_context>

<specifics>
## Specific Ideas

- The UI-SPEC flags three families as most-likely-to-need-an-override under the
  confirm-strict policy: **#5 drawer scrim** ("single most likely-to-fail"),
  **#1 glass topbar** (glass-vs-page distinctness), and **#8 home-card signal-line**
  (the luminous-on-dark → saturated-on-light designed inversion). Give these
  explicit attention in the live review.
- The live review must cover `:dark`, `:light`, AND `:system` (the latter via OS
  light preference) — `:system` mirrors light but is a distinct render path.

</specifics>

<deferred>
## Deferred Ideas

- Screenshot `__light__` baseline lane — Phase 169 (the visual proof backstop).
- AA contrast mirror test + focus-visible/interaction-state a11y audit — Phase 168.
- Brandbook `tokens.json` / `tokens.css` 45-token parity — Phase 170.
- Example-app `theme: :system` demonstration + adopter docs — Phase 169.

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 167-component-retune*
*Context gathered: 2026-06-13*
