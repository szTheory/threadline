---
phase: 198-green-bringup
plan: 11
subsystem: infra
tags: [ci, github-actions, bash, testing, flake-detection]

requires:
  - phase: 198-green-bringup
    provides: "198-REVIEW.md (CR-01/CR-02 findings), 198-VERIFICATION.md (SC6 gap)"
provides:
  - "bin/classify-flake-run — extracted, directly executable, unit-tested flake classifier"
  - "flake-detection.yml wired so the classifier is reachable on a failing run"
  - "test/threadline/flake_classifier_contract_test.exs — proof the classifier and its wiring both work, run under plain mix test"
affects: ["199-decouple", "any future GitHub Actions run: step relying on inherited errexit"]

actuals:
  tokens: 12500
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "committed-script-as-a-gate idiom (bin/verify-release-shape, bin/verify-branch-protection, now bin/classify-flake-run) — logic that must be provable lives in a directly executable, unit-tested script, not inline workflow shell"
    - "if: always() plus an explicit if:-body assertion in a contract test, so a future accidental removal of the always-condition fails fast under mix test instead of silently in a 120-minute nightly"

key-files:
  created:
    - bin/classify-flake-run
    - test/threadline/flake_classifier_contract_test.exs
  modified:
    - .github/workflows/flake-detection.yml

key-decisions:
  - "Used explicit `set +e` (not `continue-on-error: true`) in the repeat step, matching the review's suggested fix and keeping exit-code capture local to the step body rather than a step-level GitHub Actions property."
  - "The classify step still computes `iterations` locally (for the issue-body message) even though bin/classify-flake-run owns the classification itself — the script's job is strictly the six-way classification, not full issue-body content."
  - "bin/classify-flake-run relies on GITHUB_OUTPUT already being an inherited env var inside a GitHub Actions step, so the classify step does not double-write the classification= line; it only adds iterations= separately."

requirements-completed: [GREEN-11]

coverage:
  - id: D1
    description: "bin/classify-flake-run: a committed, directly executable, unit-tested classifier implementing the exact six-row behavior table (pass/broken/flaky/unknown), with `flaky` reachable only via an explicit `>= 2` branch and `unknown` as the true default (CR-02 fixed)."
    requirement: "GREEN-11"
    verification:
      - kind: unit
        ref: "test/threadline/flake_classifier_contract_test.exs#Test 1: six-row classification behavior table"
        status: pass
      - kind: manual_procedural
        ref: "direct invocation of bin/classify-flake-run against 6 fixture logs — verbatim output recorded below"
        status: pass
    human_judgment: false
  - id: D2
    description: "flake-detection.yml wired so the classify + issue steps are actually reached on a failing repeat step (CR-01 fixed): repeat step uses explicit set +e, classify step carries if: always(), issue and final-fail steps gated on if: always() && classification-value."
    requirement: "GREEN-11"
    verification:
      - kind: unit
        ref: "test/threadline/flake_classifier_contract_test.exs#Test 2/3/4"
        status: pass
      - kind: manual_procedural
        ref: "local execution of the repeat step's exact shell body against a failing command under bash -e {0}, with GITHUB_OUTPUT pointed at a temp file — transcript recorded below"
        status: pass
    human_judgment: false
  - id: D3
    description: "Threadline.FlakeClassifierContractTest exercises the classifier and its workflow reachability under plain `mix test`, not only via the 120-minute nightly Flake Detection workflow."
    requirement: "GREEN-11"
    verification:
      - kind: unit
        ref: "test/threadline/flake_classifier_contract_test.exs (10 tests, 0 failures)"
        status: pass
    human_judgment: false

duration: 35min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 11: Flake classifier reachability fix Summary

**Extracted the flake-detection classifier into `bin/classify-flake-run` (a committed, directly executable, unit-tested script) and fixed the `Classify broken vs flaky` GitHub Actions step so it actually runs when `mix verify.flake` fails — closing CR-01 (unreachable classifier) and CR-02 (unparseable-output-reported-as-flaky) with a contract test that proves both under plain `mix test`.**

## Performance

- **Duration:** 35 min
- **Tasks:** 3
- **Files modified:** 3 (1 new script, 1 new test, 1 amended workflow)

## Accomplishments

- `bin/classify-flake-run` implements the exact six-row classification table with `flaky` reachable only through an explicit `-ge 2` branch (CR-02's fall-through-to-flaky bug is gone), appends `classification=<token>` to `$GITHUB_OUTPUT` when set (append, not overwrite — verified against a pre-populated file), and does not itself rely on inherited errexit.
- `.github/workflows/flake-detection.yml` amended: the `repeat` step uses explicit `set +e` (GitHub injects `-e` via `shell: /usr/bin/bash -e {0}`, and `set -uo pipefail` alone never cleared it) so `exit_code` is written on every path; the `Classify broken vs flaky` step now carries `if: always()` and calls `bin/classify-flake-run` instead of inline branching; the issue-filing and final-failure steps are gated `if: always() && steps.classify.outputs.classification != 'pass'` so both depend on the classification value rather than the implicit success chain.
- `test/threadline/flake_classifier_contract_test.exs` (`Threadline.FlakeClassifierContractTest`, 10 tests) proves both halves under plain `mix test`: the six-row behavior table plus GITHUB_OUTPUT append semantics directly against the script, and the workflow's `if: always()` / script-invocation / errexit-independence via reading the amended YAML.

## Task Commits

Each task was committed atomically (Task 1 is `tdd="true"`, producing a RED then a GREEN commit):

1. **Task 1 (RED): Failing test for the six-way behavior table** - `88dfc794` (test)
2. **Task 1 (GREEN): bin/classify-flake-run implementation** - `be7809e5` (feat)
3. **Task 2: Wire flake-detection.yml so the classifier is reached** - `7fd402e6` (fix)

Task 3 (`tdd="true"`, "contract test binding the workflow to the script") had no additional file changes to commit: `test/threadline/flake_classifier_contract_test.exs` already carries the full six-row behavior table (Test 1/1b) AND the reachability assertions (Tests 2-4) required by Task 3's spec, all written in Task 1's RED commit per that task's explicit instruction ("Write the tests in Task 2 FIRST" — the plan's Task 1 action referred to what became Task 3's file). Task 2's fix commit turned Tests 2-4 from red to green. Task 3's remaining scope — the red-then-green non-vacuity proofs and the format/credo/no-new-alias checks — is evidence-only and is recorded below; the working tree is clean (`git status --short` empty) at the end of Task 3, so there is nothing further to commit.

**Plan metadata:** this SUMMARY commit (docs)

## Files Created/Modified

- `bin/classify-flake-run` - committed, executable, unit-tested flake-run classifier (the same idiom as `bin/verify-release-shape` and `bin/verify-branch-protection`)
- `test/threadline/flake_classifier_contract_test.exs` - `Threadline.FlakeClassifierContractTest`, 10 tests: 7 for the script's behavior table + GITHUB_OUTPUT append, 3 for workflow reachability
- `.github/workflows/flake-detection.yml` - `repeat` step uses explicit `set +e`; `Classify broken vs flaky` step carries `if: always()` and calls `bin/classify-flake-run`; issue and final-fail steps gated on `if: always() && classification-value`; stale comment corrected

## Decisions Made

- Chose explicit `set +e` in the repeat step over `continue-on-error: true` — matches the review's proposed fix and keeps the exit-code capture visible in the step body rather than a separate step-level property a reader could miss.
- `bin/classify-flake-run` owns classification only; the classify step still separately derives `iterations` locally for the issue body's human-readable message — kept the script's contract narrow (a single bare token on stdout, one `GITHUB_OUTPUT` line) rather than making it also own iteration counting output.
- Relied on GitHub Actions' auto-exported `GITHUB_OUTPUT` env var being inherited by the script subprocess so the classify step does not double-write `classification=`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Sequencing] Task 3's test file was written during Task 1's RED phase, not as a separate Task 3 commit**
- **Found during:** Task 1
- **Issue:** Task 1's `<action>` explicitly instructs "Write the tests in Task 2 FIRST and watch them fail against a stub before implementing" — but the file that contains those tests (`test/threadline/flake_classifier_contract_test.exs`) is Task 3's named deliverable, not Task 2's (Task 2 is the workflow YAML fix, which has no test file of its own). This is evidently a plan cross-reference artifact rather than an executable ambiguity: the only test file described anywhere in the plan is Task 3's, and Task 1's TDD framing (`tdd="true"`) requires a RED commit before the GREEN implementation commit.
- **Fix:** Wrote the full six-row-table test (Test 1/1b) AND the workflow-reachability assertions (Tests 2-4, Task 3's own spec) together in Task 1's RED commit, since both were needed to prove Task 1's six-way discrimination and both live in the same file per Task 3's `<action>`. Task 2's fix commit then turned Tests 2-4 green. Task 3 added no further code — its scope (red-then-green non-vacuity proofs, format/credo checks, no-new-alias check) is fully evidence-based and recorded in this SUMMARY.
- **Files modified:** test/threadline/flake_classifier_contract_test.exs (created in Task 1's RED commit `88dfc794`)
- **Verification:** All 10 tests pass after Task 2's fix; the RED commit shows 10/10 failing beforehand.
- **Committed in:** 88dfc794 (RED), be7809e5 (GREEN), 7fd402e6 (workflow fix that turns Tests 2-4 green)

---

**Total deviations:** 1 auto-fixed (1 sequencing clarification, no scope or behavior change)
**Impact on plan:** None on scope or correctness — same three commits' worth of production content as planned, sequenced to satisfy the TDD gate cleanly. No extra files, no extra tasks.

## Six-Row Behavior Table — Verbatim Output (Task 1 acceptance criterion)

Direct invocation of `bin/classify-flake-run` against fixture logs (each printed exactly one bare token, nothing else, on stdout):

```
Row 1 (EXIT_CODE=0, 3 headers)                    -> pass
Row 2 (EXIT_CODE=2, 0 headers)                     -> unknown
Row 3 (EXIT_CODE=2, 1 header)                      -> broken
Row 4 (EXIT_CODE=2, 3 headers)                     -> flaky
Row 5 (EXIT_CODE=2, no seed-banner match/unparseable) -> unknown
Row 6 (EXIT_CODE unset)                             -> unknown
  stderr: "classify-flake-run: EXIT_CODE is empty or non-numeric ('') — cannot classify, reporting unknown"
```

GITHUB_OUTPUT append proof (pre-populated file `pre_existing=value`, then `EXIT_CODE=0 GITHUB_OUTPUT=<file> bin/classify-flake-run <log>`):

```
pre_existing=value
classification=pass
```

## Repeat Step Shell-Body Transcript (Task 2 acceptance criterion)

Executed the amended `repeat` step's exact shell body locally under `bash -e {0}` (matching GitHub's injected shell), against a command that exits 2, with `GITHUB_OUTPUT` pointed at a temp file:

```
$ GITHUB_OUTPUT=/tmp/gh_output_test bash -e -c 'set +e; set -uo pipefail; (exit 2) 2>&1 | tee /tmp/flake-detection.log; exit_code="${PIPESTATUS[0]}"; echo "exit_code=$exit_code" >> "$GITHUB_OUTPUT"; exit 0'
$ echo "exit status: $?"
exit status: 0
$ cat /tmp/gh_output_test
exit_code=2
```

For contrast, the pre-fix body under the same failing command and shell:

```
$ GITHUB_OUTPUT=/tmp/gh_output_old bash -e -c 'set -uo pipefail; (exit 2) 2>&1 | tee /tmp/flake-detection-old.log; echo "exit_code=${PIPESTATUS[0]}" >> "$GITHUB_OUTPUT"'
$ echo "exit status: $?"
exit status: 2
$ cat /tmp/gh_output_old
cat: /tmp/gh_output_old: No such file or directory
```

The pre-fix body aborts before the `echo` line runs (`exit_code` never written) — confirming CR-01. The post-fix body writes `exit_code=2` and exits 0 itself.

## Red-Then-Green Non-Vacuity Pairs (Task 3 acceptance criteria)

**Pair 1 — Test 2 (workflow `if: always()` on the classify step):**

RED (line `if: always()` temporarily deleted from the classify step):
```
1) test Test 2: the classify step in the workflow carries an always-condition flake-detection.yml is non-empty and the classify step carries if: always() (Threadline.FlakeClassifierContractTest)
   test/threadline/flake_classifier_contract_test.exs:145
   the `Classify broken vs flaky` step must carry `if: always()` — without it, a failing `repeat` step skips classification entirely (the classifier is present but unreachable on the only path it exists for)
   code: assert classify_step_body =~ ~r/if:\s*always\(\)/,
   stacktrace:
     test/threadline/flake_classifier_contract_test.exs:155: (test)
```
GREEN (file restored from the committed copy): `mix test test/threadline/flake_classifier_contract_test.exs` — 10 tests, 0 failures.
`git status --porcelain .github/` — empty at task end (confirmed).

**Pair 2 — Test 1's `broken` row (script's 1-header branch inverted to `flaky`):**

RED (line 85 of `bin/classify-flake-run` temporarily changed from `classification="broken"` to `classification="flaky"`):
```
1) test Test 1: six-row classification behavior table (the load-bearing half) exit code non-zero, exactly 1 header -> broken (failed on first iteration) (Threadline.FlakeClassifierContractTest)
   test/threadline/flake_classifier_contract_test.exs:79
   Assertion with == failed
   code:  assert String.trim(output) == "broken"
   left:  "flaky"
   right: "broken"
   stacktrace:
     test/threadline/flake_classifier_contract_test.exs:84: (test)
```
GREEN (file restored from the committed copy, executable bit re-set): `mix test test/threadline/flake_classifier_contract_test.exs` — 10 tests, 0 failures.
`git status --porcelain bin/` — empty at task end (confirmed).

## Format / Credo / Alias Checks

- `mix verify.format` — exits 0, no output (clean).
- `mix verify.credo` — `2698 mods/funs, found no issues` (2 checks on 255 files; matches the milestone's documented vacuous-defaults posture, unchanged by this plan).
- `grep -c 'verify\.' mix.exs` — `59` both before and after this plan; no new alias was added.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- GREEN-11's three clauses (classification by name, time-bounded via the unchanged `timeout-minutes: 120`, deduplicated tracking issue) are all reachable on the failure path they exist for, provable in well under a second by `mix test` rather than only by a 120-minute nightly.
- `.github/workflows/flake-detection.yml` remains outside `ci-required`'s `needs:` list in `ci.yml` (unchanged, verified).
- No blockers for subsequent 198-series plans. This plan's changes are additive/self-contained (new script, new test file, one workflow file's step conditions) and do not touch `ci.yml`, `mix.exs` aliases, or any capture/query/auth code path.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
