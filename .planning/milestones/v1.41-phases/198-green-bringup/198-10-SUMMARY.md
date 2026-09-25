---
phase: 198-green-bringup
plan: 10
subsystem: infra
tags: [ci, github-actions, postgres, evidence-bundle, playwright]

requires:
  - phase: 198-green-bringup
    provides: diagnosis of the 8 red jobs on run 33138291361 (198-VERIFICATION.md)
provides:
  - verify-mechanical job now reaches a live database instead of dying on connection refused
  - Tier A evidence-bundle assertion replaced with a shape assertion that cannot rot at the next capture-set change
  - verify-example-browser resolves the audit tables the demo seed queries unqualified
affects: [198-13 roadmap debt line, PR #26 mergeability, ci-required aggregate]

actuals:
  tokens: 9500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "shape assertion over pinned literal: non-vacuity floor (count > 0) plus a relationship check (every aria.yml has a matching json sibling) instead of an absolute count that rots at the next capture-set change"

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml

key-decisions:
  - "verify-mechanical needed only env+services (no extra ecto.create step) — test/test_helper.exs self-creates and migrates the database via Ecto.Adapters.Postgres.storage_up, confirmed by running mix verify.mechanical locally before making any change and observing 18 tests, 0 failures once a reachable postgres existed"
  - "kept the duplicated two-line ALTER DATABASE statement in verify-example-browser rather than extracting a composite action, per the plan's explicit call — a third call site is the trigger to extract one"

requirements-completed: [GREEN-07]

coverage:
  - id: D1
    description: "verify-mechanical job gains env+services shape matching verify-capture; mix verify.mechanical reaches a live database instead of dying on connection refused"
    requirement: GREEN-07
    verification:
      - kind: unit
        ref: "mix verify.mechanical (18 tests, 0 failures) — run locally against a live postgres, both before the DB existed (would fail) and after the job shape was added"
        status: pass
      - kind: integration
        ref: "test/threadline/ci_topology_contract_test.exs (12 tests, 0 failures) + test/threadline/phase06_nyquist_ci_contract_test.exs (1 pre-existing failure, confirmed present before this plan's edits via git-diff-free re-run, owned by plan 198-12)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Tier A evidence-bundle assertion replaced with a non-vacuity + completeness shape check; proven to fail on an empty bundle and an orphan aria.yml"
    requirement: GREEN-07
    verification:
      - kind: unit
        ref: "new step body run verbatim against .planning/scorecards/ (366 json, 54 aria.yml) — exits 0"
        status: pass
      - kind: unit
        ref: "same body run against an empty temp directory — exits 1, names the zero json count"
        status: pass
      - kind: unit
        ref: "same body run against a temp directory with one orphan *.aria.yml and no *.json sibling — exits 1, names the orphan stem"
        status: pass
    human_judgment: false
  - id: D3
    description: "verify-example-browser's DB-prep step gains the same ALTER DATABASE threadline_phoenix_test SET search_path statement verify-capture already carries"
    requirement: GREEN-07
    verification:
      - kind: e2e
        ref: "test/threadline/ci_attestation_contract_test.exs + .planning/audits/ci-attestation-33353447804.json"
        status: pass
      - kind: manual_procedural
        ref: "the exact psql ALTER DATABASE statement run manually against a freshly created threadline_phoenix_test_verify database — exits 0 (ALTER DATABASE)"
        status: pass
      - kind: e2e
        ref: "Example app browser E2E (Playwright) concluded success on measured CI run 33353447804 — the reduced lane this ref names, run in the environment it could not be run in locally"
        status: pass
    human_judgment: false
    rationale: "the full browser E2E lane needs Playwright browsers and a booted Phoenix demo app, neither installed in this sandbox; the CI run on this PR is the proof for the complete job, though the specific statement that fixes the diagnosed root cause was verified in isolation Discharged by measured CI run 33353447804: `Example app browser E2E (Playwright)` concluded success, which exercises the DB-prep step end-to-end rather than in isolation. The complete job is now proven, which is exactly the evidence this entry deferred to."

duration: 24min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 10: CI Gap Closure — verify-mechanical DB, Tier A Shape Assertion, Example-Browser Schema Resolution Summary

**Three diagnosed-but-unfixed red CI jobs closed in `.github/workflows/ci.yml`: verify-mechanical gets a postgres service, the Tier A evidence-bundle assertion is now a non-rotting shape check, and verify-example-browser resolves the `threadline` schema the demo seed needs.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-08-28T13:41:00Z (approx)
- **Completed:** 2026-08-28T14:05:59Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments
- `verify-mechanical` job now carries the same `env:`/`services:` shape as `verify-capture` (postgres:16, DB_HOST/DB_PORT), and its header comment no longer falsely claims "no DB, no browser" — `mix verify.mechanical` verified locally: 18 tests, 0 failures.
- The Tier A "Assert complete evidence bundle" step no longer compares against the pinned `120`/`54` literal (which rotted to a real count of 366/54). It now asserts a non-vacuity floor (both counts > 0) plus the actual completeness relationship — every `*.aria.yml` has a same-stem `*.json` sibling — proven locally to fail correctly on an empty directory and on an orphan `aria.yml`.
- `verify-example-browser`'s "Ensure threadline_phoenix_test database exists" step gained the identical `ALTER DATABASE threadline_phoenix_test SET search_path ...` statement that `verify-capture` already carries, resolving the demo seed's unqualified audit-table reads. The statement was proven to execute cleanly against a fresh database matching the job's shape.

## Task Commits

Each task was committed atomically:

1. **Task 1: Give `verify-mechanical` the database it needs** - `c34440c9` (fix)
2. **Task 2: Replace the rotted Tier A evidence-count literal with a shape assertion** - `bfadd74f` (fix)
3. **Task 3: Make the example-app browser lane resolve the audit tables the demo seed reads** - `f9a82681` (fix)

**Plan metadata:** (this commit)

## Files Created/Modified
- `.github/workflows/ci.yml` - added `env:`/`services:` to `verify-mechanical`; rewrote the Tier A evidence-bundle assertion as a shape check; added the schema-resolution `ALTER DATABASE` statement to `verify-example-browser`'s DB-prep step

## Decisions Made
- No `mix test.setup`-equivalent DB-preparation step was needed for `verify-mechanical` — `test/test_helper.exs` self-creates and migrates `Threadline.Test.Repo` via `Ecto.Adapters.Postgres.storage_up/1` on every `mix test` invocation, confirmed by running `mix verify.mechanical` locally against a reachable-but-not-pre-created database and observing success (18 tests, 0 failures). Determined by measurement per the task instruction, not by assumption.
- Kept the two-line duplicated `ALTER DATABASE` statement across `verify-capture` and `verify-example-browser` rather than extracting a composite action — the plan explicitly calls this out as deliberate at two call sites, with a third call site as the trigger to extract.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix verify.example_browser --project=desktop-chromium` could not be run in this sandbox — no Playwright browsers or `node_modules` installed under `examples/threadline_phoenix/e2e/`, and installing + running the full browser E2E suite was out of scope for this plan's time budget. Per the plan's own acceptance-criteria fallback ("OR the SUMMARY records verbatim why local execution is not possible and names the CI run that will be the proof"), the specific fix (the `ALTER DATABASE` statement) was verified in isolation by running it manually against a freshly created `threadline_phoenix_test`-shaped database, which succeeded (`ALTER DATABASE`). The CI run on this PR is the proof for the complete browser lane.
- `test/threadline/phase06_nyquist_ci_contract_test.exs` has one failure (job-key parity: `ci.yml` jobs vs CONTRIBUTING List 1 drift, listing `verify-capture` and `verify-mechanical` as only-in-jobs). This is pre-existing — confirmed present on the pre-edit tree by running the same test file before this plan's edits were applied, with an identical failure message. Per the plan's own acceptance criteria, this failure is owned by plan 198-12, not this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All three diagnosed-but-unfixed red CI jobs from run `33138291361` have their root causes addressed in `ci.yml`.
- No job `id:` or job `name:` changed anywhere in the diff (verified via `git diff` grep across all three commits combined) — the `CI required` aggregate's required-context surface is provably unchanged.
- `verify-mechanical` and `verify-capture` are both verified locally (mechanical checker: 18/18 pass; evidence-bundle shape check: pass on real data, correctly fails on empty and orphan cases).
- `verify-example-browser`'s fix is verified at the statement level; full-lane confirmation is deferred to the CI run on this PR, consistent with the plan's own allowed fallback.
- The pre-existing `phase06_nyquist_ci_contract_test.exs` List 1 parity failure remains open, owned by plan 198-12 per this plan's explicit scope boundary.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
