---
phase: 198-green-bringup
plan: 17
subsystem: testing
tags: [ci, playwright, e2e, rotting-assertion, browser-lane, diagnosis]

requires:
  - phase: 198-16
    provides: "Diagnosis-before-fix pattern for GREEN-04 gaps; worktree deps/DB setup convention for the example-app browser lane"
provides:
  - "Measured, reproducible root-cause diagnosis for GREEN-04 Gap 4 (Example app browser E2E, 5 failed/9 passed/348 did not run), committed BEFORE any fix per the plan's binding must-haves"
  - "Fix for the actual cause: two Playwright assertions rewritten from a literal string 197-02 intentionally removed from the product to the schema name the product still genuinely renders, with a red-then-green teeth proof for each"
  - "Discovery, logged but explicitly not fixed here, that 28 additional pre-existing failures across 14 unrelated tests were masked by CI's maxFailures:5 ceiling and will surface on the next CI run"
affects: [198-VERIFICATION, green-04, example-browser-e2e, deferred-items, windows-ledger]

actuals:
  tokens: 7874
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Fetch the CI run's uploaded diagnostics artifact directly via gh api (not re-run CI) to read verbatim assertion messages before diagnosing"
    - "Red-then-green teeth proof for a rewritten browser assertion: drift the new literal to a nonsense value, confirm the test fails, restore, confirm it passes — the browser-test analogue of the derive-from-SSOT idiom used elsewhere in this repo"
    - "Diagnosis-before-fix artifact committed as its own atomic commit, separate from the remedy commit, so the evidence trail survives independent of the fix"

key-files:
  created:
    - .planning/audits/198-example-browser-e2e.md
  modified:
    - examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts
    - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
    - .planning/phases/198-green-bringup/deferred-items.md

key-decisions:
  - "Classified the cause as assertion-side (a rotting assertion), not environmental, directly from evidence: commit 842bd737 (197-02, one day before the CI run under diagnosis) intentionally removed the 'selected schema: … · Checked …' meta line from the coverage verdict as a deliberate density/de-chroming change, updating the Elixir unit test in the same commit but never touching either Playwright spec."
  - "Ruled out any collision with the deferred examples/threadline_phoenix demo-seed drift directly from the failures' own rendered content — the coverage verdict shows real, correct, non-empty counts (Covered: 6, Needs capture: 8, Expected gaps: 1), not a Postgrex.Error/Ecto.NoResultsError or an empty-data state, which is the deferred drift's actual failure signature."
  - "Auto-resolved Task 2's checkpoint:decision from the unambiguous evidence rather than picking a 'first option' from an enumerated list (the task asked two classification questions, not a pick-one remedy menu), consistent with 'auto-mode NEVER overrides your plan's own must_haves or measured evidence.'"
  - "Did NOT attempt to fix the 28 newly-discovered, unrelated pre-existing failures surfaced by running the full local verify command — out of this plan's declared scope (files_modified names exactly ci.yml, the two specs, and the diagnosis artifact), logged to deferred-items.md and WINDOWS.md entry #8 for a follow-up plan instead of silently absorbing or narrowing the finding."

requirements-completed: []

coverage:
  - id: D1
    description: "Diagnosis artifact attributing all 5 CI-observed failures to a single, evidence-backed cause, and settling the 348-did-not-run figure as the configured maxFailures:5 abort, written and committed before any fix"
    requirement: "GREEN-04"
    verification:
      - kind: unit
        ref: "test -s .planning/audits/198-example-browser-e2e.md && grep -qi 'ruled out' ... && git diff --exit-code examples/ .github/ (at Task 1 commit)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The two rotting Playwright assertions rewritten at the identified cause, with a red-then-green teeth proof for each, and the browser job's identifier/check-name/aggregate-membership/timeout bounds verified unchanged"
    requirement: "GREEN-04"
    verification:
      - kind: e2e
        ref: "mix verify.example_browser operator-coverage-readiness.spec.ts --project=desktop-chromium --grep desktop-1024 (RED then GREEN)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser operator-accessibility.spec.ts --project=desktop-chromium --grep 'keyboard reachable' (RED then GREEN)"
        status: pass
      - kind: unit
        ref: "git diff .github/workflows/ci.yml examples/threadline_phoenix/e2e/playwright.config.ts .github/rulesets/ .github/workflows/branch-protection.yml — all empty"
        status: pass
    human_judgment: false
  - id: D3
    description: "The must-have backstop truth ('Example app browser E2E (Playwright) concludes success on the next CI run') requires an actual next CI run to verify, and this plan's own full local reproduction found 28 additional, unrelated, pre-existing failures that will very likely keep the job red on that next run"
    verification: []
    human_judgment: true
    rationale: "Whether the next real CI run of this job concludes success cannot be determined locally with certainty (CI environment differences are possible in principle), and this plan's own evidence (28 failures found in the full local reduced-lane run, none related to the diagnosed cause) makes a green next-run unlikely without further, separately-scoped work. A human/maintainer decision is needed on how to sequence the follow-up gap-closure plan this discovery requires."

duration: ~2h10min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 17: Example app browser E2E diagnosis and fix (rotting assertion), plus a new discovery Summary

**Diagnosed and fixed CI run 33183920952's 5-failure `Example app browser E2E (Playwright)` gap — two Playwright specs still asserted a literal string that commit 842bd737 (197-02) intentionally removed from the coverage verdict a day earlier — with a red-then-green teeth proof, then discovered (but did not fix, per scope) 28 additional pre-existing failures the CI failure ceiling had been masking underneath those two.**

## Performance

- **Duration:** ~2h10min (including fresh worktree dependency/browser/DB setup, artifact retrieval via `gh api`, three local Playwright runs — two targeted teeth-proof runs and one full 362-test reduced-lane run at 14.2 min)
- **Started:** ~2026-08-28T17:05:00Z (approx)
- **Completed:** 2026-08-28T19:15:00Z (approx)
- **Tasks:** 3 of 3 completed as designed (Task 1 diagnosis, Task 2 decision, Task 3 implement + prove)
- **Files modified:** 2 spec files fixed, 1 diagnosis artifact created (later extended), 1 deferred-items.md entry added, 1 WINDOWS.md ledger entry added

## Accomplishments

- Fetched CI run 33183920952's uploaded `example-browser-e2e-diagnostics` artifact directly via `gh api` (not a re-run) and read the verbatim assertion message for each of the 5 failures — all five are the exact same `toContainText("selected schema")` failure against the `Selected schema readiness` region, at 4 viewports of `operator-coverage-readiness.spec.ts` plus 1 instance in `operator-accessibility.spec.ts`.
- Settled the "348 did not run" figure with a config-line citation (`playwright.config.ts:141`, `maxFailures: process.env.CI ? 5 : 0`) and confirmed it directly by reproducing all 5 of `operator-coverage-readiness.spec.ts`'s viewports (including the CI-unreached `desktop-1440`) locally, unbounded — it fails identically, proving the 348 figure is the configured abort, not a second defect.
- Identified the cause via `git blame`/`git log`: commit `842bd737` (`feat(197-02): raise coverage page signal-to-chrome`, 2026-08-27) intentionally removed the verdict's `"selected schema: … · Checked …"` meta line as a deliberate density/de-chroming change, updated the Elixir `coverage_live_test.exs` in the same commit, but never touched either Playwright spec — both assertions predate that commit by roughly two months (`git blame` June 29/30).
- Ruled out any collision with the deferred `examples/threadline_phoenix` demo-seed drift directly from the failures' own rendered content: the coverage verdict region shows real, correct, non-empty counts (`Covered: 6`, `Needs capture: 8`, `Expected gaps: 1`), not the `Postgrex.Error`/`Ecto.NoResultsError` signature the deferred drift actually produces.
- Rewrote both assertions to check `"public"` — the schema name the verdict heading still genuinely renders, and which both tests' navigation (no `schema` query param) always resolves to — with a red-then-green teeth proof executed for each (drift to nonsense → confirmed RED → restore → confirmed GREEN).
- Verified the browser job's identifier, check name, aggregate-gate membership, and step/job timeout bounds are all byte-unchanged (`git diff .github/` is empty; `verify-example-browser` still present in `ci-required`'s `needs:` list).
- **Discovered, and explicitly did not fix**, 28 additional pre-existing failures across 14 unrelated tests (`operator-find-mobile.spec.ts`, `operator-phase-135/173/175/177-uat.spec.ts`, `operator-screenshot-regression.spec.ts`, `operator-screenshots.spec.ts`, `register.spec.ts`) by running the plan's own required full verify command locally, unbounded — these were always present but invisible to CI because the `maxFailures: 5` ceiling always aborted on the two now-fixed specs first.

## Task Commits

Each task was committed atomically:

1. **Task 1: Attribute all five failures to causes, from evidence, before changing anything** - `4a79c7ce` (docs)
2. **Task 2: Decide the remedy, and decide the deferred-drift question if it arises** - decision recorded in the Task 1 artifact and extended in the Task 3 commit below; no separate commit (this checkpoint's decision was auto-resolved from unambiguous evidence per the plan's own checkpoint protocol, not a picked-from-a-menu remedy class requiring its own commit)
3. **Task 3: Implement the authorized remedy and prove it against the real specs** - `d900e32e` (fix)

**Plan metadata:** committed alongside this SUMMARY.

## Files Created/Modified

- `.planning/audits/198-example-browser-e2e.md` — the full diagnosis: uploaded-diagnostics contents, the 348-figure config citation, the five-row attribution table (all sharing one cause), local reproduction (verbatim), the ruled-out-collision analysis against the deferred demo-seed drift, three ruled-out hypotheses with evidence, the recorded Task 2 decision, and a Task 3 outcome section documenting the teeth proofs and the new 28-failure discovery
- `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts` — line 142: `toContainText("selected schema")` → `toContainText("public")`, with an explanatory comment citing 197-02/842bd737
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` — line 411: same rewrite, same reasoning
- `.planning/phases/198-green-bringup/deferred-items.md` — new "Plan 198-17" entry recording the 28-failure discovery
- `.planning/WINDOWS.md` — new entry #8 (kind: deviation) for the same discovery, so it is visible at ship time

## Decisions Made

- **Classified the cause as assertion-side (rotting assertion), not environmental**, directly from the same-day commit's own explanatory comment and commit message plus the pre-197-02 `git blame` dates on both failing assertion lines — no ambiguity requiring a maintainer tiebreak.
- **Ruled out any collision with the deferred demo-seed drift** directly from the failures' own rendered content (real, correct, non-empty coverage counts), so no scope expansion into that deferred item was authorized or needed.
- **Auto-resolved Task 2's checkpoint:decision from evidence** rather than picking a first-listed option from an enumerated menu — the task asked two classification questions answerable unambiguously from Task 1's evidence, consistent with the instruction that auto-mode's default never overrides measured evidence.
- **Did not fix the 28 newly-discovered failures.** They are unrelated to this plan's diagnosed cause and outside `files_modified`; fixing them here would have been unauthorized scope expansion into work this plan was never scoped, planned, or threat-modeled for. Logged instead, per the scope-boundary rule, to `deferred-items.md` and `WINDOWS.md` for a follow-up gap-closure plan to diagnose properly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fetched example-app deps, e2e node/Playwright dependencies, and prepared the local test database**
- **Found during:** Task 1 setup
- **Issue:** This fresh worktree had no root `deps/`, no `examples/threadline_phoenix/deps`, no `examples/threadline_phoenix/e2e/node_modules`, and no installed Playwright Chromium browser — required to reproduce anything locally. `threadline_phoenix_test` already existed in the shared local Postgres from prior work.
- **Fix:** `mix deps.get` (root), `MIX_ENV=test mix deps.get` (example app), `npm ci` + `npx playwright install --with-deps chromium` (e2e), and the CI-matching `ALTER DATABASE ... SET search_path` prep step (already applied to the shared DB; re-ran harmlessly).
- **Files modified:** none tracked (`deps/`, `node_modules/`, Playwright browser cache all gitignored).
- **Verification:** subsequent `mix verify.example_browser` runs completed and produced the reproduction evidence in the audit artifact.
- **Committed in:** N/A (environment setup only, no file changes).

---

**Total deviations:** 1 auto-fixed (Rule 3 — blocking environment setup necessary to run any local reproduction; not a new/unverified package install, all already-declared/lockfile-pinned dependencies, so the Rule 3 package-install exclusion does not apply).
**Impact on plan:** None beyond enabling the diagnosis and teeth proof. No scope creep — this was a prerequisite, not additional work.

## Issues Encountered

- **The plan's own Task 3 acceptance criterion ("the named command exits 0") is not literally met.** `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium` (unbounded locally) exits non-zero: `28 failed`, `15 skipped`, `319 passed (14.2m)`. Neither of the two files this plan fixed appears anywhere in that failure list — confirmed by grep against the full failure block and by two separate targeted teeth-proof runs that isolated and passed exactly those two assertions. The 28 failures are pre-existing, unrelated, and were never visible to any prior CI run of this job because `maxFailures: 5` always aborted on the two now-fixed specs first (they sort/execute before all 8 of the newly-visible spec files). This is treated as a legitimate, honestly-reported partial outcome rather than either (a) silently declaring victory on a red command, or (b) expanding scope to fix 28 unrelated, undiagnosed failures inside a plan whose `files_modified` and threat model never contemplated them. See the audit artifact's "Task 3 outcome" section and the new `deferred-items.md`/`WINDOWS.md` entries.

## User Setup Required

None — no external service configuration required. (Local Postgres on port 5432 was already running in this environment; the deps/browser/DB setup above is local-only and gitignored.)

## Next Phase Readiness

- **GREEN-04 Gap 4, narrowly defined as "the 5 failures from CI run 33183920952," is closed.** Both assertions are fixed at the correct, evidence-identified cause with a demonstrated red-then-green teeth proof, and the browser job's identity/aggregate-membership/timeout contract is fully unchanged.
- **The browser lane as a whole is NOT yet green.** A follow-up gap-closure plan is needed to diagnose and fix the 28 newly-surfaced failures (`operator-find-mobile.spec.ts`, `operator-phase-135/173/175/177-uat.spec.ts`, `operator-screenshot-regression.spec.ts`, `operator-screenshots.spec.ts`, `register.spec.ts`), in the same disciplined, no-weakening manner this plan used. Because CI's `maxFailures: 5` ceiling will still be active, the next real CI run of this job will very likely fail again — at a different, smaller subset of these 28 — and that run's diagnostics artifact is the correct next input, exactly as this plan used run 33183920952's artifact.
- **The must-have backstop truth ("`Example app browser E2E (Playwright)` concludes success on the next CI run") is not expected to hold as a direct, sole result of this plan.** This is stated plainly rather than assumed away — see `coverage[D3]` above and the audit artifact.
- No blockers for subsequent 198 gap-closure plans — this plan's worktree state (deps fetched, local test DB present) is disposable/gitignored and does not need to be preserved or cleaned up by a sibling plan.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*

## Self-Check: PASSED

- FOUND: .planning/audits/198-example-browser-e2e.md
- FOUND: examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts (line 142: `toContainText("public")`)
- FOUND: examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts (line 411: `toContainText("public")`)
- FOUND commits: 4a79c7ce, d900e32e (`git log --oneline`)
- CONFIRMED: `git diff --exit-code .github/ examples/threadline_phoenix/e2e/playwright.config.ts .github/rulesets/ .github/workflows/branch-protection.yml` passes (no CI/config/protection changes)
- CONFIRMED: `git status --porcelain` clean except this SUMMARY (pre-commit)
