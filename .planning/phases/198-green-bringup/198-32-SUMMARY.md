---
phase: 198-green-bringup
plan: 32
subsystem: testing
tags: [exunit, walkthrough-evidence, demo-contract, anti-vacuity, coverage-live, redaction-policy]

# Dependency graph
requires:
  - phase: 198-green-bringup
    provides: round-4 hardening (198-30 and prior plans) whose CR-02/CR-03/WR-10 findings this plan repairs
provides:
  - Non-vacuous coverage-snapshot assertions in walkthrough_evidence_test.exs (discriminate on <dt>/<dd> count pairs, not static labels)
  - Restored negative timeline assertion (refute "View Incident") alongside the positive empty-state assertion
  - Restored manifest-literal pin for redaction_policy subject_ref in demo_contract_test.exs
affects: [198-37 (round-5 closeout consolidation)]

actuals:
  tokens: 3600
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Pair a conditionally-static <dt> label with its adjacent <dd> count via regex (`[1-9]\\d*`) when the label itself renders unconditionally"
    - "Annotate structurally-tautological assertions (round-trip checks against a query's own filter columns) as documentation rather than deleting them"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs
    - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs

key-decisions:
  - "Coverage assertions use option (a) — count-pairing via regex, not per-row chip markup — because the plan's read_first note claimed a per-row 'Covered' string is unsatisfiable (Presentation.status_label(\"covered\") => \"Captured\"), but reading coverage_live.ex:231 directly showed the covered row renders a literal 'Covered' chip (not routed through status_label). Given that contradiction, the count-pairing approach avoids relying on either premise and is unambiguously correct against the code as read."
  - "Teeth proofs combine a synthetic regex check (hand-built zero-count/populated HTML fragments matching the real DOM shape) with a real ExUnit red-then-green run (temporarily perturbing the assertion/input in the live test file, capturing genuine failure output, then reverting) rather than seeding a real zero-covered/zero-uncovered database state, which would require destabilizing the shared demo fixture."

requirements-completed: []

coverage:
  - id: D1
    description: "Coverage-snapshot assertions in walkthrough_evidence_test.exs discriminate on count, failing when covered_count and uncovered_count are both zero (CR-02)"
    verification:
      - kind: unit
        ref: "test/threadline_phoenix_web/walkthrough_evidence_test.exs#WALK-04-03 trigger coverage dashboard and evidence snapshot"
        status: pass
    human_judgment: false
  - id: D2
    description: "Negative timeline assertion refute timeline_html =~ \"View Incident\" restored alongside the positive empty-state assertion on /audit/timeline (WR-10)"
    verification:
      - kind: unit
        ref: "test/threadline_phoenix_web/walkthrough_evidence_test.exs#WALK-04-01 retention_run evidence and empty offboarded-co timeline"
        status: pass
    human_judgment: false
  - id: D3
    description: "Manifest's declared redaction-policy subject_ref literal pinned in demo_contract_test.exs, alongside the retained (now honestly-labelled) tautological round-trip assertion (CR-03)"
    verification:
      - kind: unit
        ref: "test/threadline_phoenix/demo_contract_test.exs#WALK-04 redaction policy evidence post-demo.seed redaction_policy row matches manifest subject_ref"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-08-30
status: complete
---

# Phase 198 Plan 32: Restore vacuous-assertion teeth (CR-02, CR-03, WR-10) Summary

**Coverage-snapshot assertions now discriminate on count via regex, the deleted negative `View Incident` timeline assertion is restored, and the manifest's redaction-policy literal is pinned again — each proven red-then-green.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-08-30T19:35:00Z
- **Completed:** 2026-08-30T20:00:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Coverage assertions in `walkthrough_evidence_test.exs` now assert `<dt>Covered</dt>`/`<dt>Needs capture</dt>` paired with a strictly-positive adjacent `<dd>` value via regex, replacing the bare static-label substring match that passed regardless of count (CR-02).
- `refute timeline_html =~ "View Incident"` restored beside the round-4 positive `"No captured changes"` assertion on the corrected `/audit/timeline` route (WR-10) — both failure modes are now guarded.
- `demo_contract_test.exs` pins `Manifest.evidence_subject_ref(:redaction_policy)` against the published demo-contract literal `%{"policy" => "walk-demo-redaction-policy"}` before the query runs (CR-03); the tautological round-trip `record.subject_ref == subject_ref` assertion is retained and now honestly labelled as query-contract documentation rather than a load-bearing check.

## Task Commits

1. **Task 1: Make the coverage-snapshot assertions discriminate, and restore the deleted negative timeline assertion (CR-02, WR-10)** - `0bb02c4f` (test)
2. **Task 2: Pin the manifest's declared redaction-policy subject_ref literal alongside the round-trip assertion (CR-03)** - `8fcc4356` (test)

**Plan metadata:** committed with this SUMMARY

## Files Created/Modified
- `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs` - coverage-snapshot count-pairing regex assertions + restored negative timeline assertion
- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` - restored manifest subject_ref pin + honest tautology label on the round-trip assertion

## Decisions Made
- Chose count-pairing (plan's option (a)) over per-row chip markup (option (b)) for the coverage assertions. The plan's `read_first` note claimed `Presentation.status_label("covered")` returns `"Captured"`, making a per-row `"Covered"` assertion unsatisfiable — but reading `coverage_live.ex:231` directly showed the covered row renders a **literal** `"Covered"` chip, not routed through `Presentation.status_label` at all (that function is used by `retention_history_live.ex`, `export_status_live.ex`, and `evidence_live.ex`, not `coverage_live.ex`). Given this contradiction between the plan's stated premise and the code as actually read, count-pairing sidesteps the disputed claim entirely and is unambiguously correct.
- Teeth proofs were captured by combining (a) a synthetic Elixir regex check against hand-built zero-count and populated HTML fragments that mirror the real `<dt>/<dd>` markup shape, proving the regex discriminates, and (b) a real ExUnit red-then-green run against the live seeded demo fixture — temporarily perturbing the assertion pattern (coverage) or injecting a literal `"View Incident"` string into the rendered HTML (timeline) to produce a genuine failure, then reverting to capture the genuine pass. Seeding an actual zero-covered/zero-uncovered database state was judged unnecessarily destabilizing to the shared demo fixture for a test-only hardening plan.

## Deviations from Plan

None - plan executed exactly as written. The coverage-assertion shape choice ((a) vs (b)) was an explicit judgment call the plan itself delegated ("the choice must be justified against `coverage_live.ex` as read, not assumed"), not a deviation from the plan's instructions.

## Issues Encountered

None. The worktree's `examples/threadline_phoenix/deps` and `_build` were not present (unlike the main repo checkout); ran `mix deps.get`, `mix compile`, `mix ecto.create`/`mix ecto.migrate` locally in the worktree before executing tests. This is expected worktree setup, not a plan deviation.

## Teeth Proofs (verbatim, required by acceptance criteria)

### Coverage-snapshot assertions (CR-02)

**Synthetic regex proof** — hand-built HTML fragments matching the real `<dt>/<dd>` markup shape:

```
=== zero-count snapshot (expect false/false = FAIL as an assertion) ===
covered match (zero snapshot): false
uncovered match (zero snapshot): false
=== populated snapshot (expect true/true = PASS) ===
covered match (populated): true
uncovered match (populated): true
```

**Real ExUnit RED** (assertion temporarily perturbed to an impossible pattern `<dd>NEVERMATCHES</dd>`, run against the live seeded coverage page):

```
  1) test §5 evidence plane (WALK-04-01..03) WALK-04-03 trigger coverage dashboard and evidence snapshot (ThreadlinePhoenixWeb.WalkthroughEvidenceTest)
     test/threadline_phoenix_web/walkthrough_evidence_test.exs:89
     Assertion with =~ failed
     code:  assert coverage_html =~ ~r/<dt>Covered<\/dt>\s*<dd>NEVERMATCHES<\/dd>/
     left:  "<!DOCTYPE html>...<truncated real coverage page HTML>..."
     right: ~r/<dt>Covered<\/dt>\s*<dd>NEVERMATCHES<\/dd>/
     stacktrace:
       test/threadline_phoenix_web/walkthrough_evidence_test.exs:104: (test)

Finished in 0.6 seconds (0.00s async, 0.6s sync)
3 tests, 1 failure
```

**Real ExUnit GREEN** (perturbation reverted to the actual `[1-9]\d*` regex):

```
Running ExUnit with seed: 699432, max_cases: 36
demo.seed complete
demo.seed complete
...
Finished in 0.6 seconds (0.00s async, 0.6s sync)
3 tests, 0 failures
```

### Negative timeline assertion (WR-10)

**Real ExUnit RED** (`"<a href=\"#\">View Incident</a>"` temporarily injected into the rendered fixture path):

```
  1) test §5 evidence plane (WALK-04-01..03) WALK-04-01 retention_run evidence and empty offboarded-co timeline (ThreadlinePhoenixWeb.WalkthroughEvidenceTest)
     test/threadline_phoenix_web/walkthrough_evidence_test.exs:21
     Refute with =~ failed
     code:  refute timeline_html =~ "View Incident"
     left:  "<!DOCTYPE html>...<truncated real timeline page HTML>..."
     right: "View Incident"
     stacktrace:
       test/threadline_phoenix_web/walkthrough_evidence_test.exs:55: (test)

Finished in 0.8 seconds (0.00s async, 0.8s sync)
3 tests, 1 failure
```

**Real ExUnit GREEN** (injection reverted):

```
Running ExUnit with seed: 841378, max_cases: 36
demo.seed complete
demo.seed complete
...
Finished in 0.5 seconds (0.00s async, 0.5s sync)
3 tests, 0 failures
```

### Manifest redaction-policy pin (CR-03)

**Real ExUnit RED** (pinned literal temporarily perturbed to `%{"policy" => "WRONG-VALUE-drift"}`):

```
  1) test WALK-04 redaction policy evidence post-demo.seed redaction_policy row matches manifest subject_ref (ThreadlinePhoenix.DemoContractTest)
     test/threadline_phoenix/demo_contract_test.exs:248
     Assertion with == failed
     code:  assert subject_ref == %{"policy" => "WRONG-VALUE-drift"}
     left:  %{"policy" => "walk-demo-redaction-policy"}
     right: %{"policy" => "WRONG-VALUE-drift"}
     stacktrace:
       test/threadline_phoenix/demo_contract_test.exs:259: anonymous fn/0 in ThreadlinePhoenix.DemoContractTest."test WALK-04 redaction policy evidence post-demo.seed redaction_policy row matches manifest subject_ref"/1
       (ecto_sql 3.13.5) lib/ecto/adapters/sql/sandbox.ex:629: Ecto.Adapters.SQL.Sandbox.unboxed_run/2
       test/threadline_phoenix/demo_contract_test.exs:249: (test)

Finished in 3.4 seconds (0.00s async, 3.4s sync)
13 tests, 1 failure
```

**Real ExUnit GREEN** (perturbation reverted to the correct literal):

```
Running ExUnit with seed: 940994, max_cases: 36
demo.seed complete
...
Finished in 3.4 seconds (0.00s async, 0.0s sync)
13 tests, 0 failures
```

## Deleted assertions and their strictly-stronger replacements

Per `git diff -U0 <base>..HEAD -- <the two files>`, exactly two `assert`/`refute` lines were deleted, both with named strictly-stronger replacements:

| Deleted | Replaced by |
|---|---|
| `assert coverage_html =~ "Covered"` | `assert coverage_html =~ ~r/<dt>Covered<\/dt>\s*<dd>[1-9]\d*<\/dd>/` |
| `assert coverage_html =~ "Needs capture"` | `assert coverage_html =~ ~r/<dt>Needs capture<\/dt>\s*<dd>[1-9]\d*<\/dd>/` |

No other `assert`/`refute` lines were deleted. `refute timeline_html =~ "View Incident"` (WR-10) and `assert subject_ref == %{"policy" => "walk-demo-redaction-policy"}` (CR-03) are pure additions, not replacements of a deletion.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Both restored assertion sets pass `mix test` for their respective files individually and together (16 tests, 0 failures), and `mix verify.example` from the repository root passes (109 tests, 0 failures) as the readiness signal recorded per D-01.
- No `@tag :skip`/`:pending` markers introduced; no product code (`lib/`, `.github/`, `CONTRIBUTING.md`, `.planning/scorecards/`, `*.png`) touched — confirmed via `git diff --stat` returning empty for those paths.
- Ready for 198-37 (round-5 closeout consolidation), which enumerates this plan alongside the other gap-closure plans.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-30*
