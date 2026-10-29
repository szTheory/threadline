---
phase: 245-supply-chain
plan: 01
subsystem: ci
tags: [hex-audit, sarif, deps-health, github-actions, bash, jq]
status: complete

requires:
  - phase: 244
    provides: Hex 2.6.0 pin and bin/retry-network used by the deps-health lane
provides:
  - "bin/deps-audit-tier: sourced SARIF library (DAT_TMP_DIRS, dat_cleanup, dat_new_sarif_path, dat_audit, DAT_AUDIT_OUTPUT, dat_findings, dat_audit_shape_error)"
  - "bin/deps-health-report: four-class classifier, RANK_NAMES=(clean unknown retirement advisory), unknown fallback rank"
  - "bin/upsert-ci-issue: retitle-on-update (gh issue edit N --title before the comment)"
  - "deps-health.yml: daily cron, push-to-main lockfile path filter, fail on any non-clean class, CLASSIFICATION via env:"
  - "Seven Hex 2.6.0-shape SARIF fixtures under test/fixtures/deps_audit/sarif/"
affects: [245-02, 245-04, 245-05]

actuals:
  tokens: 18034
  tasks: 3
  commits: 2
plan_head_before: 91dc99bc593071abd8ca0e69ec1d5b78046eb350
plan_head_after: b2b152a1b31a4928067ab49dd948f97b60fa5e22

tech-stack:
  added: []
  patterns:
    - "Sourced bash library with no set -e/trap; status capture via `cmd && st=0 || st=$?`"
    - "jq capture()? wrapped as `[... | capture(re)?] | .[0]` so a non-match is null, not empty"

key-files:
  created:
    - bin/deps-audit-tier
    - test/fixtures/deps_audit/sarif/clean.json
    - test/fixtures/deps_audit/sarif/advisory_plug.json
    - test/fixtures/deps_audit/sarif/retired_plug.json
    - test/fixtures/deps_audit/sarif/plug_1_20_0.json
    - test/fixtures/deps_audit/sarif/vulnerable_lock.json
    - test/fixtures/deps_audit/sarif/unparseable_fingerprint.json
    - test/fixtures/deps_audit/sarif/denied_plug.json
  modified:
    - bin/deps-health-report
    - bin/upsert-ci-issue
    - .github/workflows/deps-health.yml
    - test/threadline/deps_health_report_test.exs
    - test/threadline/ci_issue_upsert_contract_test.exs
    - test/threadline/deps_health_doc_contract_test.exs
    - CONTRIBUTING.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md

decisions:
  - "D-30 ordering refinement: the SARIF half of bin/deps-audit-tier lands in 245-01; 245-02 adds the closure/tier functions and makes verify-deps-audit the second consumer"
  - "D-24 discretion: no hex.outdated job-summary step; freshness review stays the maintainer's pre-release mix hex.outdated"
  - "dat_audit_shape_error also fails when the parsed row count differs from the SARIF result count, so no result can silently vanish"

metrics:
  duration: 16min
  completed: 2026-10-25
---

# Phase 245 Plan 01: Self-closing deps-health lane Summary

The deps-health lane now classifies each run from Hex 2.6.0 SARIF fingerprints alone, as `clean`, `unknown`, `retirement` or `advisory` (highest wins). `hex.outdated` no longer runs. Any non-clean class opens the single `ci-deps` issue (or retitles and comments on it) and turns the job red. Only `clean` closes the issue.

## What shipped

- **Task 1 (tracer, 657aa51a):** `bin/deps-audit-tier`, the sourced SARIF library. It writes each audit to a fresh `mktemp -d` path under `$ROOT/tmp` that is never pre-created, runs `hex.audit --format sarif` outside `bin/retry-network` (D-19), parses fingerprints with jq into TSV, and checks the result's shape, failing closed. `bin/deps-health-report` sources the library, uses the new rank set, and ranks any unknown class name as `unknown`. `bin/upsert-ci-issue` retitles the matched issue before commenting when the title differs. A retirement fixture produces `classification=retirement` end to end.
- **Tasks 2+3 (b2b152a1, one commit, as the plan requires):**
  - The `hex.outdated` call and every `outdated` line are gone.
  - `deps.get` output appears only for a directory whose fetch failed.
  - The header now documents the D-25 precedence.
  - Five more fixtures.
  - `deps-health.yml` gains:
    - a daily `0 8 * * *` cron and a push-to-main filter on exactly the six `mix.exs`/`mix.lock` paths;
    - a fail step that exempts only `'clean'` and reads `$CLASSIFICATION` from `env:`;
    - renamed job and step names and a new label description.
  - The job id `deps-health` and `cancel-in-progress: false` are unchanged.
  - Tests now cover:
    - every class arm, including a missing directory (built as a temp copy of the tree);
    - the three cross-directory precedence cases;
    - `hex.outdated` never being invoked even though the fake exits 1;
    - `GITHUB_OUTPUT` values staying within the four classes, with all four exercised;
    - the noise trim;
    - the fail, close and push-path workflow shapes, with the paths derived from `@canonical_dirs`.
  - The CONTRIBUTING lane paragraph is rewritten. The doc contract pins `RANK_NAMES` to the classes named in CONTRIBUTING, refutes `alone stays green`, and no longer requires `hex.outdated`.
  - REQUIREMENTS SUP-01/SUP-04 and ROADMAP 245 criteria 1 and 4 and the phase-list line now carry the D-01/D-25 wording.

Issue #61 was not touched (D-28). The next non-clean run retitles it, and the first clean run closes it.

## Verification

- `mix test` (default suite) before the Task 1 commit: 3291 tests, 0 failures, 3 excluded.
- `mix test` before the Task 2+3 commit: 3315 tests, 0 failures, 3 excluded.
- Task 3 targeted set (8 files): 295 tests, 0 failures.
- `mix format --check-formatted`, `mix verify.credo` (no issues), `actionlint .github/workflows/deps-health.yml` (clean), `bash -n` on all three scripts, and `bin/verify-repo-hygiene` (exit 0) all pass.
- Every acceptance grep in the plan matches its expected count.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] The RESEARCH parsing recipe dropped unparseable fingerprints, which made them fail open as clean**
- **Found during:** Task 2 (the class-arm test `unparseable_fingerprint.json -> unknown` reported `clean`).
- **Issue:** On a non-match, jq's `capture(...)?` emits no output at all rather than `null`, so the whole result row vanished. A non-zero exit with one unparseable result passed the shape check and then read as "no findings", which classified the run clean. The Task 1 commit (657aa51a) contains this recipe as written, but no caller relied on it before the fix.
- **Fix:** Changed it to `([$fp | capture(re)?] | .[0]) as $m`, which yields null on a non-match and so an explicit `UNPARSEABLE` row. Also added a second guard to `dat_audit_shape_error`: a parsed row count that differs from the SARIF result count is a shape error. `results` must also be an array.
- **Files modified:** bin/deps-audit-tier
- **Commit:** b2b152a1
- **Note for 245-02:** `bin/verify-deps-audit` will reuse this fixed library. Do not copy the recipe from RESEARCH.

**2. [Rule 3 - Blocking] `advisory_plug.json` was created in Task 1, not Task 2**
- The Task 1 commit had to keep the existing advisory tests meaningful once the fake `hex.audit` switched to SARIF. The fixture content matches the Task 2 spec.

**3. Test-fake details (within the plan's intent)**
- The fake also has `FAKE_AUDIT_FORCE_NONZERO` and `FAKE_AUDIT_FORCE_ZERO` knobs, for the "non-zero exit with clean.json" and "exit 0 with results" arms.
- The fake `deps.get` now emits the `FAKE_HUGE` output before its failure checks. The 60000-byte cap test sets `FAKE_FAIL_DEPS_GET` so that output still reaches the body after the noise trim.
- Message text in `vulnerable_lock.json` is paraphrased. The five fingerprints, ids, packages and levels are the real ones listed in RESEARCH.

## Known Stubs

None.

## Deferred Issues

None. shellcheck reports two pre-existing info-level notes (SC2016 on the fenced-block printf, SC2329 on the trap-invoked `cleanup_sections`). No CI lane runs shellcheck.

## Self-Check: PASSED

- bin/deps-audit-tier and all 7 fixtures exist.
- Commits 657aa51a and b2b152a1 are ancestors of HEAD.
