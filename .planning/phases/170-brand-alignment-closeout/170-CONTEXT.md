# Phase 170: brand-alignment-closeout - Context

**Gathered:** 2026-06-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Close out the v1.36 Operator Surface Light Mode milestone by making the brand
SSOT and the shipped UI lane state the same settled truth, and by making the
milestone audit-ready.

Delivers exactly four things (no new capabilities):
1. `brandbook/tokens.json` + `tokens.css` reach defined parity with the shipped
   operator-surface token lane (`lib/threadline/operator_surface/style.ex`).
2. The brand book carries a settled-truth "UI theming posture" note.
3. `brandbook/pressure-test.md` carries a dual-mode addendum.
4. v1.36 milestone audit prep: all 15 requirements traceable, audit doc authored.

This is a docs/closeout + alignment phase. It does NOT change the shipped UI
token values, add runtime theme-switching, or touch the uncommitted nav-overhaul
lane (~29 files — never staged/edited/reverted).
</domain>

<decisions>
## Implementation Decisions

### A — Token parity: definition + enforcement (BRAND-01)
- **D-01:** "Full parity" = **curated-subset parity, not 1:1 with the runtime lane.**
  The brandbook mirrors the *brand-defining* semantic tokens; for every token the
  brandbook claims to mirror, its **name and value must equal the shipped lane's
  corresponding token exactly**, in both dark and light blocks.
- **D-02:** Runtime-only structural tokens are **explicitly out of brand scope**
  and must be documented as such (so the gap is intentional, not drift). Known
  exclusions to confirm against `style.ex`: `op-insert/update/delete-*`,
  `accent-soft`, `accent-wash`, `accent-inset`, `accent-border`, `surface-tint`,
  `surface-tint-strong`, `signal-bg`, `signal-border`, status `*-bg`/`*-border`
  variants, `op badges`, `brand-rail`, `backdrop`, `border-focus`. (The planner
  reconciles the exact in/out lists against the live `style.ex` token set —
  Explore counted ~49 `--tl-color-*` runtime tokens vs. the brandbook's curated set.)
- **D-03:** Enforce with an **automated parity test** —
  `test/threadline/brandbook_token_parity_test.exs`. It parses the dark + light
  blocks of `style.ex` and `brandbook/tokens.json` (and/or `tokens.css`), asserts
  value-equality on the **intersection** of token names, and asserts the documented
  **exclusion list** so drift is caught in *both* directions (brandbook adds a token
  the lane doesn't have, or the lane changes a value the brandbook claims to mirror).
  This is the keystone of the phase — "correct by default," consistent with the
  project's doc-contract test habit.

### B — UI theming posture note: placement + framing (BRAND-01)
- **D-04:** Add a short **"UI theming posture" subsection inside
  `brandbook/brand-book.md`**, near the existing Dark/light strategy + color
  sections (≈ lines 217–287). Not the README, not a new pressure-test dimension.
- **D-05:** Content states the settled truth: **dark-primary; light is fully
  shipped and supported, enabled via host config** (`theme: :system | :light |
  :dark`); per-operator runtime toggle is **deferred to real adopter demand**
  (THEME-TOGGLE-01; localStorage remains rejected).
- **D-06:** Framing follows the **v1.33 lesson** — state it as settled truth
  *only now that light actually shipped* (v1.36). Pin the keystone sentence with a
  **doc-contract literal assertion** (extend an existing brand/doc-contract test or
  add to the parity test file).

### C — pressure-test dual-mode addendum: form (BRAND-02)
- **D-07:** **No scorecard inflation** — do NOT add a dimension #16. Instead
  **augment existing dimension #11 "Token rigor"** with a dual-mode pass condition,
  cross-referencing **#5 "Dark/light versatility."**
- **D-08:** **Plus one mechanical-suite assertion** (shell-runnable, consistent with
  the existing mechanical suite at the top of `pressure-test.md`) that runs the
  **same parity check** — so the brand pressure-test is tied to the actual UI token
  truth, not just narrative. Net form: narrative dimension addendum + one mechanical
  gate line.

### D — Milestone audit prep: scope (success criterion 4)
- **D-09:** Phase 170 **authors the audit doc now**:
  `.planning/milestones/v1.36-MILESTONE-AUDIT.md`, following the established v1.33 /
  v1.20 template (YAML header: milestone/audited/status/scores/nyquist; verdict;
  requirement audit table; phase coverage table; cross-phase integration; risks
  accepted; closeout readiness).
- **D-10:** Update `.planning/REQUIREMENTS.md` **traceability table** to mark all 15
  v1.36 requirements (incl. BRAND-01, BRAND-02) verified against their closing phases.
- **D-11:** **Closeout readiness is marked PENDING the End-of-milestone UAT human
  gate**, which runs *after* this phase (per ROADMAP Human Gates). Actual milestone
  archival + version bump stay with `/gsd-complete-milestone` post-UAT — NOT part of
  phase 170.

### Claude's Discretion
- Exact token name reconciliation (final in-scope vs. excluded lists) against the
  live `style.ex` — derive from code, not from memory.
- Parser implementation details for the parity test (regex over `style.ex`/`tokens.css`
  vs. JSON decode of `tokens.json`); whether the mechanical assert shells out to the
  Elixir test or is a standalone script — pick whatever stays consistent with the
  existing `pressure-test.md` mechanical suite and the project's test conventions.
- Whether the posture-note literal lock lives in a new test file or extends an
  existing brand doc-contract test.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase + milestone scope
- `.planning/ROADMAP.md` §"Phase 170: brand-alignment-closeout" — goal, success criteria, depends-on (168, 169), Human Gates (End-of-milestone UAT runs after this phase).
- `.planning/REQUIREMENTS.md` — BRAND-01, BRAND-02 (lines ~39–40); Traceability table (lines ~57–80, 15 reqs); Out-of-scope notes (incl. nav-overhaul lane, marketing/docs-site themes).

### Brand SSOT (the artifacts this phase aligns)
- `brandbook/tokens.json` — current curated brand token set (raw + semantic dark/light + typography/spacing/radius/shadow/focus/code/callout/state).
- `brandbook/tokens.css` — CSS-var emission of the same, with `.tl-theme-dark` / `.tl-theme-light` blocks.
- `brandbook/brand-book.md` — §Dark/light strategy + §Color (≈ lines 217–287); target for the new "UI theming posture" subsection.
- `brandbook/pressure-test.md` — mechanical suite (top) + 15 scored dimensions; target dimensions #5 (Dark/light versatility) and #11 (Token rigor); target mechanical-suite addition.

### Shipped UI token lane (parity source of truth)
- `lib/threadline/operator_surface/style.ex` — the frozen Phase-144 token contract; dark base block + light override block. The brandbook mirrors a subset of these values. This file's values WIN on any conflict (UI lane is shipped truth; brandbook aligns to it).

### Closeout patterns to follow
- `.planning/milestones/v1.33-MILESTONE-AUDIT.md` (and `v1.20-MILESTONE-AUDIT.md`) — the audit doc template to replicate for v1.36.
- `test/threadline/operator_surface_doc_contract_test.exs` and `test/threadline/v1_23_charter_doc_contract_test.exs` — the established doc-contract literal-lock pattern (File.read! + String.contains?/refute) to follow for the posture-note lock.

### v1.36 prior-phase context
- `.planning/phases/169-screenshots-example-docs/169-CONTEXT.md` and the 166 SUMMARY — establish that light shipped this milestone and that brandbook token parity was explicitly deferred to Phase 170.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Doc-contract test pattern** (`operator_surface_doc_contract_test.exs`,
  `v1_23_charter_doc_contract_test.exs`): `File.read!/1` + `String.contains?/2` /
  `refute String.contains?/2`, grouped by intent. Reuse for the posture-note literal
  lock and as the host for the parity assertions.
- **`brandbook/tools/`** — existing brandbook tooling dir; check for an existing
  token/lint harness the parity check can plug into rather than inventing a new one.
- **`pressure-test.md` mechanical suite** — already shell-assert based; the new
  mechanical parity line should match its existing style/format.

### Established Patterns
- **"Correct by default"** + heavy doc-contract test usage → an automated parity
  test is the idiomatic enforcement here (D-03), not manual sync.
- **No literal "45" count is asserted anywhere** — "45-token lane" is a planning-doc
  phrase; the runtime lane emits ~49 `--tl-color-*` tokens. The parity test asserts
  *value-equality on named tokens*, NOT a count.
- **Token freeze**: `style.ex` is the frozen source contract. Phase 170 changes the
  brandbook to match the lane — it does NOT change shipped UI token values.

### Integration Points
- Parity test reads from `lib/threadline/operator_surface/style.ex` ↔
  `brandbook/tokens.json`/`tokens.css` — establishes a standing link between the
  runtime lane and the brand SSOT that fails CI on future drift.
- Milestone audit doc + REQUIREMENTS traceability feed the post-phase UAT gate and
  `/gsd-complete-milestone`.
</code_context>

<specifics>
## Specific Ideas

- Posture wording must echo the project's settled framing: **dark-primary, light
  supported via host config** — the exact "v1.33 lesson" framing (state only now
  that it's true). Pin that sentence literally.
- Audit doc must mark **closeout readiness as gated on the End-of-milestone UAT**,
  not green, since the human gate runs after this phase.
</specifics>

<deferred>
## Deferred Ideas

- **THEME-TOGGLE-01** — per-operator runtime theme switching (Backpex-style cookie +
  plug, zero-JS form). Only on real adopter demand; localStorage remains rejected.
  Referenced in the posture note as deferred, not built here.
- **Milestone archival + version bump** — belongs to `/gsd-complete-milestone` after
  the UAT gate, not Phase 170.
- **SOCIAL-PNG-01 / HEXDOCS-BRAND-01 / LANDING-01** — out of v1.36 scope (per
  REQUIREMENTS out-of-scope notes); untouched.

</deferred>

---

*Phase: 170-brand-alignment-closeout*
*Context gathered: 2026-06-14*
