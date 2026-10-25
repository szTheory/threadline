---
phase: 246-debt-closeout-and-critic-retirement
plan: 01
subsystem: planning-gates
tags: [close-check, debt-register, windows-ledger, critic-retirement, self-test]
status: complete
requires: []
provides:
  - "tools/verify-phase.sh: default (hygiene + partition rows), --close (D-15 checks 1-8 + D-09), --self-test (27 mutation controls)"
  - "tools/register-check.py: python3 -I parsers for WINDOWS json, register table, D-09 hit filtering"
affects: [246-02, 246-03, 246-04, 246-05, 246-06, 246-07]
tech-stack:
  added: []
  patterns:
    - "phase dir derived from SCRIPT_DIR/.. (survives archival)"
    - "accumulating ok:/FAIL: checks with evidence; fail closed on grep exit 2 and parse errors"
    - "self-test mutation guard: a mutation that leaves its fixture unchanged fails"
key-files:
  created:
    - .planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh
    - .planning/phases/246-debt-closeout-and-critic-retirement/tools/register-check.py
  modified: []
decisions:
  - "Parsers live in a sibling tools/register-check.py (the plan allowed this), so the bash script stays readable."
  - "The register is any markdown table whose header has a 'disposition' cell; the id is the first column with HTML anchors, backticks and bold stripped; the reason column is the first header containing 'reason' or 'route'."
  - "Allowlist entries are `path` or `path:ERE` matched against the hit's content; the CONTRIBUTING Retired section is exempted by line range, fail closed when the heading is missing or appears twice."
  - "Register sub-checks run only when the register exists, so a missing register shows up as one register-missing failure instead of five parse errors."
metrics:
  duration: "about 25 min"
  completed: 2026-10-25
estimate:
  tokens: 55000
  tasks: 2
actuals:
  tokens: 7099
  tasks: 2
  commits: 2
plan_head_before: 0364446a31c392d78e0347fd940db8d79a304bd9
plan_head_after: e4727b9420a301b915f8d4ff1c4a1459aece71dc
---

# Phase 246 Plan 01: Phase 246 close check Summary

This plan adds a read-only `verify-phase.sh`, built from the Phase 222 script, with a `python3 -I` parser beside it. It is now the mechanical definition of "done" for DEBT-01 and DEBT-02. It checks:

- the register's counts, dispositions, routes, uniqueness and id coverage (the 60 W ids, the literal required list, and at least 11 `217-` ids);
- that WINDOWS has zero open rows;
- that every D-09 live-reference hit is on the allowlist, with the CONTRIBUTING Retired section exempted by line range;
- the closure fields in SEED-005 and SEED-008;
- the username and machine-path hygiene greps;
- that every partition row names a file that exists.

A 27-case `--self-test` proves each check can fail.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (tracer) | Close-check skeleton, one real check per source | 94413c28 | tools/verify-phase.sh, tools/register-check.py |
| 2 (tdd) | Full D-15 check set, id list, D-09 allowlist, --self-test | e4727b94 | tools/verify-phase.sh, tools/register-check.py |

## Verification (run at e4727b94)

- `bash -n` is clean. Default mode exits 0 and prints `verify-phase: all checks passed`. `--bogus` exits 64.
- `--close` exits 1 at HEAD, as it should. These checks fail:
  - register missing;
  - WINDOWS: `open_count: 60` and 60 open rows listed;
  - D-09: 1509 hits that are not on the allowlist, including `lib/threadline/critic_trust/`;
  - stale allowlist entry `ui_critic_retirement_doc_contract_test.exs` (plan 246-02 creates that file);
  - SEED-005 lacks the closure fields and SEED-008 is absent.

  The hygiene and partition checks print `ok:`.
- `--self-test` exits 0 with 27 case lines. The cases are:
  - valid register, valid WINDOWS, reordered register;
  - blank disposition, blank reason, unnamed route, count drift, duplicate id;
  - missing W id, missing required id, empty register;
  - open window, open_count drift, malformed JSON;
  - grep exit 2 for both the machine-path and username greps;
  - partition file missing, partition vacuous;
  - retired section scope, heading absent, heading twice, section-only hit;
  - path:ERE allowlist scope, stale allowlist entry;
  - valid seeds, SEED-005 still Open, SEED-008 missing.
- Idempotent: `git status --porcelain` was unchanged after two runs in a row in every mode. All scratch lives in mktemp and is removed by the trap.
- Acceptance greps:
  - `216-SHA-PINNING` and `INCIDENT-REPLAY-SESSION` are present.
  - `CONTRIBUTING.md:ui-critic-loop` gives 0 hits and `## Retired: UI critic loop` gives 1.
  - Username grep gives 0 hits.
  - No `P=.planning/phases/` literal.
  - The script is executable.

## TDD note

Task 2 had one RED moment. The first self-test run reported `blank disposition` and `blank reason` as "expected fail, got pass". Their sed mutation targeted W3, which is the fixture's routed row, so the fixture never changed. I moved the target to W5. I also added a `mutate` helper that fails the self-test whenever a mutation leaves its fixture byte-identical, so no case can pass vacuously that way again. Task 2 is one commit, as the plan's commit message asked.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Self-test mutation-applies guard**
- **Found during:** Task 2
- **Issue:** a sed mutation that matched nothing made the self-test pass vacuously, which breaks the plan's "never pass vacuously" rule.
- **Fix:** a `mutate` helper uses `cmp -s` to compare the source and mutated fixtures and fails if they are identical.
- **Files modified:** tools/verify-phase.sh
- **Commit:** e4727b94

**2. [Rule 2] Extra self-test cases beyond the 11 the plan names**
- The plan names 11 cases. I added: reordered register (ordering edge), missing W id, missing required id, open_count drift, username grep exit 2, two partition cases, two more retired-heading fail-closed variants, section-only pass, path:ERE scope, stale allowlist entry and three seed cases. Without them, checks 5 and 7, the partition check and the stale-allowlist check would have no self-test showing they can fail.

**3. Note on the plan's `files_modified`:** I added a sibling `tools/register-check.py`, which the plan allowed. It is committed in both task commits.

## Known Stubs

None. The `ui_critic_retirement_doc_contract_test.exs` allowlist entry points at a file that plan 246-02 creates. Until then the stale-entry check reports it, as intended.

## Self-Check: PASSED

- FOUND: tools/verify-phase.sh, tools/register-check.py
- FOUND: 94413c28, e4727b94 (both ancestors of HEAD)
