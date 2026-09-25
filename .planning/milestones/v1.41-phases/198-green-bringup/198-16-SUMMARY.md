---
phase: 198-green-bringup
plan: 16
subsystem: testing
tags: [ci, playwright, tier-a-capture, byte-stability, mechanical-checker, diagnosis]

requires:
  - phase: 198-14
    provides: "PgBouncer topology port + static call-site sweep (prior gap-closure conventions)"
  - phase: 198-15
    provides: "stress-router ambient-dependency retirement (prior gap-closure conventions)"
provides:
  - "Measured, reproducible root-cause diagnosis for GREEN-04 Gap 3 (Tier A capture lane byte-stability failure), committed BEFORE any fix per the plan's binding must-haves"
  - "Identification that scroll_cost's document-wide scrollHeight read (vs. the product-content scoping every sibling raw-input field uses) couples it to /audit/__stress's unvirtualized story-catalog sidebar size, not the captured cell's own content"
  - "A recorded, honest halt: every available remedy requires Tier A page.* scorecard regeneration, which 198-CONTEXT.md's deferred-items register states is forbidden this milestone — no code change made, GREEN-04 Gap 3 stays open"
affects: [198-VERIFICATION, green-04, mechanical-checker, tier-a-capture]

actuals:
  tokens: 8000
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Diagnosis-before-fix artifact committed as its own atomic commit, separate from any remedy, so a HALT outcome leaves a durable, reviewable record even when no code changes"
    - "Refusing an auto-mode checkpoint:decision default when the auto-selected option would misrepresent measured evidence, rather than picking a technically-first-listed-but-factually-wrong remedy class just to keep the plan moving"

key-files:
  created:
    - .planning/audits/198-tier-a-byte-stability.md
  modified: []

key-decisions:
  - "Did NOT auto-select Task 2's checkpoint:decision first option (a removable nondeterministic input). Two independent runs of mix verify.capture from a clean scorecard checkout produced byte-identical scroll_cost drift, ruling out nondeterminism outright — auto-selecting class 1 would have contradicted the plan's own measured evidence."
  - "Classified the cause as remedy class 3 (stale evidence, correct remedy is regeneration) but treated the checkpoint as blocked rather than authorizing regeneration on the maintainer's behalf, because 198-CONTEXT.md's deferred-items register states Tier A page.* scorecard regeneration is forbidden this milestone, and the plan's own must-have #4 requires exactly this halt in exactly this situation."
  - "Left both concrete remedy shapes (regenerate as-is vs. rescope scroll_cost to preview.offsetHeight/window.innerHeight then regenerate) documented with their respective blast radii in the audit artifact, for a maintainer to choose from once the recapture constraint lifts, rather than picking one unilaterally."

requirements-completed: []

coverage:
  - id: D1
    description: "Diagnosis artifact identifying the measured root cause of the scroll_cost byte-stability drift, written and committed before any fix"
    requirement: "GREEN-04"
    verification:
      - kind: unit
        ref: "test -s .planning/audits/198-tier-a-byte-stability.md && grep -qi reproduction ... && grep -qi 'ruled out' ..."
        status: pass
      - kind: integration
        ref: "DB_HOST=localhost DB_PORT=5432 mix verify.capture (run twice, byte-identical drift both times)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The byte-stability gate's strength is unchanged (no code, config, or ci.yml modification of any kind)"
    verification:
      - kind: unit
        ref: "git diff --exit-code .github/workflows/ci.yml examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts examples/threadline_phoenix/e2e/playwright.config.ts .github/rulesets/ .github/workflows/branch-protection.yml"
        status: pass
    human_judgment: false
  - id: D3
    description: "GREEN-04 Gap 3's actual resolution (whether to authorize regeneration, and which remedy shape) requires a maintainer decision this executor run could not obtain synchronously"
    verification:
      - kind: unit
        ref: "test/threadline/phase198_decision_attestation_test.exs + .planning/audits/198-tier-a-byte-stability.md"
        status: pass
    human_judgment: false
    rationale: "The plan's Task 2 is a checkpoint:decision whose only honest options both require overriding an explicit, separately-recorded milestone-wide constraint (Tier A page.* regeneration forbidden this milestone). Auto-mode's default (auto-select the first option) would have selected a remedy class the diagnosis explicitly rules out. A human must make this call; it is not safe to infer. Discharged by phase-199: the maintainer answered this exact question ('Yes - fix cause, then regen'), the answer is recorded verbatim in the audit, and the scroll_cost coupling is now fixed at cause with byte-stability restored."duration: ~55min
completed: 2026-08-28
status: halted
---

# Phase 198 Plan 16: Tier A `scroll_cost` byte-stability diagnosis (halted before remedy) Summary

**Reproduced the `page.coverage.error` CI byte-stability failure locally and deterministically, traced it to `scroll_cost` reading the whole `/audit/__stress` document (including a 288-story unvirtualized sidebar) instead of the product-content region every sibling field already scopes to, and halted before any fix because every available remedy requires Tier A `page.*` scorecard regeneration — which this milestone's own deferred-items register states is forbidden.**

## Performance

- **Duration:** ~55 min (including two full local `mix verify.capture` runs at ~2.2-2.3 min each, plus deps fetch/compile/Playwright browser setup in a fresh worktree)
- **Started:** ~2026-08-28T16:10:00Z (approx)
- **Completed:** 2026-08-28T17:02:29Z
- **Tasks:** 2 of 3 completed as designed by the plan (Task 1 diagnosis + Task 2 decision-recording); Task 3 executed its explicit halt path (no code changes, by design)
- **Files modified:** 1 created (`.planning/audits/198-tier-a-byte-stability.md`)

## Accomplishments

- Reproduced CI's `Tier A capture lane` `scroll_cost` drift locally, twice, byte-identically each time — ruling out both run-to-run flakiness and any CI-only environmental cause.
- Ruled out two plausible-but-wrong candidate causes with direct evidence: (1) the committed `meta.playwright_version` field is a hardcoded literal, not derived from the actual installed browser, so it cannot signal a real version-driven rendering difference; (2) `page.coverage.error` renders from static stress-lab fixture data (`Threadline.OperatorSurface.StressFixtures.assigns_for/1`), not from `demo.seed`'s DB-seeded content, ruling out the known `search_path` wart as a cause for this cell.
- Identified the actual cause via direct DOM measurement (a temporary, uncommitted diagnostic Playwright script, deleted after use): `scroll_cost`'s numerator is `document.documentElement.scrollHeight` — the entire `/audit/__stress` debug harness document — while every sibling raw-input field in the same function is deliberately scoped to `[data-testid="stress-preview"]`, the actual page under test. 98.5% of the measured document height (35726px of 36288px) is the harness's unvirtualized sidebar listing all 288 currently registered stress-lab stories, not the captured cell's own content (502px).
- Showed the committed evidence predates catalog growth: the fixture registry grew from 874 to 981 lines since the scorecards were last committed (Phase 195-03), and the `scroll_cost` value for this ledger has grown across three untracked capture generations (`16.561` → `18.803` → `~36-41` now).
- Determined both concrete remedies (regenerate as-is; or rescope the metric to product content then regenerate) require Tier A `page.*` scorecard regeneration, which `198-CONTEXT.md`'s deferred-items register explicitly states is "forbidden this milestone" — and recorded that finding, with a maintainer recommendation, in the audit artifact per the plan's Task 2 instructions.
- Halted at Task 3 with zero code, config, or `ci.yml` changes, per the plan's explicit, designed fallback for exactly this outcome.

## Task Commits

Each task was committed atomically:

1. **Task 1: Measure what actually differs, and write the diagnosis before touching anything** - `4ba907eb` (docs)
2. **Task 2: Decide the remedy against the diagnosis** - `a1b71473` (docs) — recorded classification against all four remedy classes and a maintainer recommendation; no maintainer response was available synchronously to this executor run, so no remedy was authorized
3. **Task 3: Implement the authorized remedy, or halt honestly** - no commit (halt path: zero files changed, `git diff --exit-code` on all constrained paths passes clean, matching the plan's own stated outcome for "no remedy currently available")

**Plan metadata:** committed alongside this SUMMARY.

## Files Created/Modified

- `.planning/audits/198-tier-a-byte-stability.md` — the full measured diagnosis: verbatim reproduction output (two runs), run-to-run determinism proof, field-level diff analysis (only `scroll_cost` moved for the target cell), two ruled-out candidate causes with their tests and evidence, the identified cause with DOM-structure measurement, the "which value is correct" analysis, both concrete remedy shapes with their costs, and the Task 2 decision-recording section (classification against all four remedy classes, recommendation, explicit note that auto-mode's default was deliberately not applied)

## Decisions Made

- **Refused to auto-select Task 2's checkpoint:decision first option.** Auto-mode's stated default (auto-select the first listed remedy) would have picked "a removable nondeterministic input" — a class this plan's own measured evidence (two byte-identical runs) directly rules out. Selecting it anyway to keep the plan moving would have meant reporting a diagnosis conclusion the evidence contradicts; refused per this plan's own must-have #4 ("if the only available remedy would require regenerating Tier A `page.*` evidence in a way this milestone forbids, the plan halts and says so") and per the general instruction that a plan's own must-haves override auto-mode's default checkpoint behavior when they conflict.
- **Classified the cause as remedy class 3** (stale evidence, remedy is regeneration) but did not authorize regeneration on the maintainer's behalf, since `198-CONTEXT.md`'s deferred-items register independently and explicitly forbids Tier A `page.*` regeneration this milestone — that constraint predates and is broader than this plan, and overriding it is not this executor's call to make.
- **Documented both concrete remedy shapes with their blast radii** (regenerate as-is: 198 scorecards, non-durable; rescope + regenerate: all 366 scorecards plus a `mechanical_floors` re-seed, durable) so a maintainer has what they need to decide once the recapture constraint lifts, without this executor picking one.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fetched example-app deps and e2e node/Playwright dependencies**
- **Found during:** Task 1 setup
- **Issue:** This worktree had root deps already fetched (from prior 198-14/15 work) but `examples/threadline_phoenix/deps`, `examples/threadline_phoenix/e2e/node_modules`, and the Playwright Chromium browser were absent — required to run `mix verify.capture` at all.
- **Fix:** Ran `MIX_ENV=test mix deps.get` in `examples/threadline_phoenix`, `npm ci` in `examples/threadline_phoenix/e2e`, and `npx playwright install --with-deps chromium`. All packages were already declared in the respective lockfiles (already-verified dependencies, not new/unverified packages — the Rule 3 package-install exclusion does not apply).
- **Files modified:** none tracked (`deps/`, `node_modules/`, and the Playwright browser cache are all gitignored; no lockfile changed).
- **Verification:** `mix verify.capture` subsequently ran and produced the reproduction evidence in the audit artifact.
- **Committed in:** N/A (no file changes to commit; environment setup only).

**2. [Rule 3 - Blocking] Created the local `threadline_phoenix_test` database and applied the CI-matching `search_path` ALTER**
- **Found during:** Task 1 reproduction attempt
- **Issue:** `run-e2e.sh` (invoked transitively by `mix verify.capture`) expects `threadline_phoenix_test` to exist with `threadline` on the search_path, matching `ci.yml:374-375`'s prep step. This worktree's Postgres (already running locally on port 5432, matching CI's port) did not yet have that database.
- **Fix:** Ran the exact CI prep commands (`createdb`, then the `ALTER DATABASE ... SET search_path` statement) locally, matching `ci.yml:374-375` verbatim, before running `mix verify.capture`.
- **Files modified:** none (database-only, no tracked files).
- **Verification:** `mix verify.capture` subsequently ran to completion (2 passed) on both runs.
- **Committed in:** N/A (no file changes to commit; environment setup only).

---

**Total deviations:** 2 auto-fixed (both Rule 3 — blocking environment setup necessary to run any local reproduction at all; neither is a new/unverified package install, so the Rule 3 package-manager exclusion does not apply). No scope creep — both were prerequisites for the diagnosis task itself, not additional work.
**Impact on plan:** None beyond enabling the reproduction the plan requires. No code, config, or evidence files were touched by either fix.

## Issues Encountered

- A throwaway manual `mix phx.server` probe (attempting to inspect the harness DOM outside the test harness) failed to boot cleanly under `MIX_ENV=test` due to Ecto sandbox ownership semantics (`DBConnection.ConnectionError` from a background cleanup task holding a sandboxed connection with no owning test process). This was not pursued further — the diagnostic need was met instead by a temporary, uncommitted Playwright spec file (`tests/tmp-diag-198-16.spec.ts`) run through the same `run-e2e.sh` path the real capture uses, which booted correctly and produced the DOM-structure measurement in §4 of the audit artifact. The temp file was deleted before finishing Task 1; `git status --porcelain` and `git diff --exit-code .github/ examples/ lib/ test/` were both confirmed clean before committing.

## User Setup Required

None — no external service configuration required. (A local Postgres on port 5432 was already running in this environment; the `threadline_phoenix_test` database this plan created is local-only, gitignored, and matches CI's own prep step.)

## Next Phase Readiness

- **GREEN-04 Gap 3 remains open.** This plan intentionally made no code, config, or `ci.yml` change — per its own must-haves, a diagnosed-but-forbidden remedy is a legitimate halt, not a failure to close.
- **What would close this gap:** a maintainer decision (recorded in `.planning/audits/198-tier-a-byte-stability.md`'s "Decision (Task 2)" section) choosing between (a) a stopgap regeneration of the currently-drifted 198 scorecards' `scroll_cost` values, accepting it will drift again as the stress-lab catalog grows, or (b) waiting for "the recapture constraint" (the same one named in `198-CONTEXT.md`'s deferred-items register for the related `search_path` wart) to lift, then doing a single durable pass: rescope `scrollCost` to `preview.offsetHeight / window.innerHeight`, regenerate all 366 committed scorecards once, and re-seed `mechanical_floors["scroll_cost"]` in `.planning/design-system-ledger.json`.
- **A related, out-of-scope drift was flagged, not chased:** 42 of the 198 currently-drifted scorecards (`refute.brand-fidelity.mis-jobbed-accent.flawed__*` and `refute.density.chrome-bloat.flawed__*`) show content-level diffs beyond `scroll_cost` — plausibly legitimate Phase 195/196 critic-work changes never recaptured. Noted in the audit artifact §3 so a future recapture effort does not mistake this diagnosis as covering the full 198-file drift; not diagnosed further here (out of this plan's declared scope).
- No blockers for subsequent 198 gap-closure plans — this plan's worktree state (deps fetched, local test DB created) is disposable/gitignored and does not need to be preserved or cleaned up by a sibling plan.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*

## Self-Check: PASSED

- FOUND: .planning/audits/198-tier-a-byte-stability.md
- FOUND commits: 4ba907eb, a1b71473 (git log --oneline)
- CONFIRMED: git status --porcelain is clean except this SUMMARY (pre-commit)
- CONFIRMED: git diff --exit-code .github/ examples/ lib/ test/ passes (no code/config changes)
