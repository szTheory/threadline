---
phase: 196-forward-only-net-positive-gate-first-proven-iteration
plan: 01
subsystem: testing
tags: [critic, forward-only-gate, tsx, elixir, exunit, ledger, mechanical-floor, gate-01, gate-04]

# Dependency graph
requires:
  - phase: 195-critic-synthetic-oracle-ranking-gate
    provides: validated critic_trust lenses (brand_fidelity/density/typography/rhythm), scoreCellLens primitive, synthetic-set oracle
  - phase: 194-tier-a-mechanical-floor
    provides: MechanicalChecker + verify.mechanical deterministic floor over committed page.* scorecards
provides:
  - "gate.ts — propose→re-evaluate→guard orchestrator skeleton (one blocking lens × one route cell), dry-run wired, zero API billing"
  - "critic:gate npm script + run.ts lazy-imported gate dispatch arm"
  - "route.timeline → page.timeline.happy twin map resolving the route.* mechanical-jurisdiction gap"
  - "critic_panel ledger baseline (blocking/advisory/trust_floors/oracle_inventory/signoff_ref) as the recorded GATE-04 sign-off"
  - "vacuous-safe panel-membership freeze clause in verify.critic_trust"
affects: [196-02, 196-03, 196-04, 196-05, 196-06, 197]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Four-step gate loop as separate functions (blastRadius/mechanicalFloor/rankReeval/verdict) so Plan 03 expands each independently"
    - "Deterministic mechanical floor gated on the committed page.* Tier-A twin, never the gitignored route.* cell (Pattern 3 / Pitfall 1)"
    - "Frozen module-constant panel + ledger cross-check as the append-only GATE-04 guard idiom"

key-files:
  created:
    - examples/threadline_phoenix/e2e/critic/gate.ts
  modified:
    - examples/threadline_phoenix/e2e/critic/run.ts
    - examples/threadline_phoenix/e2e/critic/refute.ts
    - examples/threadline_phoenix/e2e/package.json
    - .planning/design-system-ledger.json
    - test/threadline/operator_surface/critic_trust_test.exs

key-decisions:
  - "Exported scoreCellLens + LENS_DIMENSIONS from refute.ts (were module-private) so the gate composes the existing primitive instead of reimplementing per-cell scoring"
  - "trust_floors seeded 0.85/0.78/0.72/0.72 (recorded ρ − ~0.05, floored at the 0.70 validation bar) — a maintainer knob confirmable at PROOF-01 sign-off"
  - "Tracer keyed re-eval uses before==after (Δ=0) as an honest non-accept; the real post-edit 'after' pole is Plan 03's expansion, not a hidden stub"

patterns-established:
  - "Pattern 1: gate steps are independently-expandable functions — the tracer wires the shape end-to-end, Plan 03 fills each"
  - "Pattern 2: mechanical floor jurisdiction routes route.* → committed page.* twin so a route fix cannot bypass the deterministic block"

requirements-completed: [GATE-01, GATE-04]

coverage:
  - id: D1
    description: "Forward-only gate runs the full propose→re-evaluate→guard loop for one lens × one route cell under --dry-run, resolving the page.* twin, naming the accept/reject rule, exiting 0 with no ANTHROPIC_API_KEY"
    requirement: GATE-01
    verification:
      - kind: e2e
        ref: "cd examples/threadline_phoenix/e2e && npm run critic:gate -- --page route.timeline --lens brand_fidelity --dry-run"
        status: pass
    human_judgment: false
  - id: D2
    description: "critic_panel ledger baseline committed (append-only) and panel-membership freeze clause green + vacuous-safe in verify.critic_trust"
    requirement: GATE-04
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/critic_trust_test.exs#critic_panel block freezes blocking/advisory membership and agrees with validated flags"
        status: pass
      - kind: unit
        ref: "mix verify.critic_trust"
        status: pass
    human_judgment: false

# Metrics
duration: ~15min
completed: 2026-07-28
status: complete
---

# Phase 196 Plan 01: Thinnest End-to-End Forward-Only Gate (Tracer) Summary

**A single `critic:gate` command runs the whole propose→re-evaluate→guard loop for brand_fidelity × route.timeline under dry-run — resolving the page.timeline.happy mechanical twin and printing a verdict with zero API billing — plus the committed critic_panel GATE-04 baseline and its vacuous-safe membership-freeze guard.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-07-29T02:32Z
- **Completed:** 2026-07-29T02:47Z
- **Tasks:** 2
- **Files modified:** 6 (1 created, 5 modified)

## Accomplishments
- Landed the production-quality tracer: `gate.ts` closes the forward-only loop architecture end-to-end (blast-radius diff → deterministic mechanical floor on the page.* twin → LLM ranking re-eval → ACCEPT/REJECT/VOID verdict) in one command, proving the architecture before any expansion.
- Wired `critic:gate` into the runner exactly like `case "validate"` (lazy import + `ERR_MODULE_NOT_FOUND` guard); the LLM gate is kept strictly out of every `mix` alias / `ci.all` (196-D9).
- Resolved the route.* mechanical-jurisdiction gap: the floor is asserted on the committed `page.timeline.happy` Tier-A twin, never on the gitignored, non-byte-stable `route.timeline` cell (Pattern 3 / Pitfall 1 / T-196-01-01).
- Seeded the append-only `critic_panel` ledger baseline (blocking/advisory/trust_floors/oracle_inventory/signoff_ref) and froze panel membership in `verify.critic_trust`, cross-checked against the per-lens `validated` flags — the GATE-04 guard host now has its baseline.

## Task Commits

Each task was committed atomically:

1. **Task 1: Thinnest end-to-end gate — one lens × one route cell, dry-run wired** - `527a3e90` (feat)
2. **Task 2: Seed critic_panel ledger baseline + first vacuous-safe GATE-04 guard clause** - `90d92d78` (feat)

_Note: this plan's Task 1 is a `type="tracer" tdd="true"` slice; RED was the missing `critic:gate` script (npm error), GREEN the wired dry-run exiting 0. It committed as a single production-quality feat commit._

## Files Created/Modified
- `examples/threadline_phoenix/e2e/critic/gate.ts` - Forward-only gate orchestrator: `runGate(argv)` + the four ordered step functions (blastRadius/mechanicalFloor/rankReeval/verdict), ROUTE_PAGE_TWIN map, dry-run degradation without a key.
- `examples/threadline_phoenix/e2e/critic/run.ts` - Added `case "gate"` lazy-import dispatch arm and listed `gate` in the default-usage help.
- `examples/threadline_phoenix/e2e/critic/refute.ts` - Exported `scoreCellLens` and `LENS_DIMENSIONS` so the gate composes the existing per-cell scoring primitive (deviation, below).
- `examples/threadline_phoenix/e2e/package.json` - Added the `critic:gate` npm script (`tsx critic/run.ts gate`) next to `critic:score`.
- `.planning/design-system-ledger.json` - Additive `critic_panel` block (append-only; existing `critic_trust` bytes untouched).
- `test/threadline/operator_surface/critic_trust_test.exs` - Frozen `@blocking_panel`/`@advisory_panel` constants + panel-membership freeze clause cross-checked against `validated` flags.

## Decisions Made
- **Exported the refute.ts primitives** instead of duplicating scoring logic — keeps validation == deployment (the gate scores with the exact primitive the refute battery validated). See deviations.
- **trust_floors = 0.85/0.78/0.72/0.72** (recorded Spearman ρ minus ~0.05, floored at the 0.70 validation bar), matching RESEARCH A4's resolved seed. These are a maintainer knob and are confirmable at the PROOF-01 sign-off; GATE-03 (Plan 03) uses them as the divergence floor.
- **Tracer keyed path uses before==after (Δ=0)** as an honest non-accept. The tracer's job is the dry-run architecture proof; the real post-edit "after" pole (a recapture diff) is Plan 03's expansion, explicitly scoped by this plan's `<action>`. This is a documented tracer boundary, not a hidden stub.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Exported scoreCellLens + LENS_DIMENSIONS from refute.ts**
- **Found during:** Task 1 (gate.ts implementation)
- **Issue:** The plan mandates `gate.ts` import `scoreCellLens` + `LENS_DIMENSIONS` from `refute.ts`, but both were module-private (unexported) — a compile-blocking import. `refute.ts` was not in the plan's `files_modified`.
- **Fix:** Added the `export` keyword to both declarations. Purely additive and behavior-neutral for `runValidate` (the refute battery still calls them identically); it only widens their visibility.
- **Files modified:** examples/threadline_phoenix/e2e/critic/refute.ts
- **Verification:** `npx tsc --noEmit` exits 0; `grep -q "scoreCellLens" gate.ts` passes; dry-run runs green.
- **Committed in:** `527a3e90` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The export is the minimal change required to satisfy the plan's own "compose, don't reimplement" instruction. No behavior change, no scope creep.

## Known Stubs

- **`gate.ts` non-dry-run ranking re-eval (`rankReeval`) uses before==after (Δ=0).** Intentional tracer boundary — the keyed path wires the `scoreCellLens` shape and the accept/reject rule, but the real post-edit "after" pole (a recapture byte-diff) lands in **Plan 03** (per this plan's `<action>`). The plan's goal (dry-run architecture proof, GATE-01 shape) is fully achieved; the keyed path is not part of the tracer's `<verify>`. Not a data-wiring gap that blocks the plan's goal.
- **`blastRadius` non-dry-run branch returns an empty changed set (no real recapture diff yet).** Same tracer boundary — Plan 03 wires the real `npm run capture:pages` recapture + byte diff.

## Issues Encountered
None. Both deterministic gates (`verify.critic_trust` 16 tests, `verify.mechanical` 18 tests) pass green; TypeScript type-check clean; Elixir format check clean.

## User Setup Required
None - no external service configuration required. The LLM re-eval path is local-only and requires `ANTHROPIC_API_KEY` only for a non-dry-run gate; the dry-run proof and all CI-side deterministic guards need no key.

## Next Phase Readiness
- **Plan 02** (GATE-04 target-drop + fixture-removal clauses) builds directly on the committed `critic_panel` baseline and `ratchet.signoffs` this plan seeded the guard host for.
- **Plan 03** (blast-radius fan-out + real recapture diff) expands `blastRadius`/`rankReeval`/`ROUTE_PAGE_TWIN` — the four step functions were authored as independent expansion points for exactly this.
- No blockers.

## Self-Check: PASSED

- `examples/threadline_phoenix/e2e/critic/gate.ts` — FOUND
- `.planning/phases/196-.../196-01-SUMMARY.md` — FOUND
- Commit `527a3e90` (Task 1) — FOUND
- Commit `90d92d78` (Task 2) — FOUND

---
*Phase: 196-forward-only-net-positive-gate-first-proven-iteration*
*Completed: 2026-07-28*
