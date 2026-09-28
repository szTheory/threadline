---
phase: 215-supply-chain-gate
plan: 06
subsystem: ci
tags: [hex, mix, supply-chain, deps-health, bash, exunit]

requires:
  - phase: 215-supply-chain-gate
    provides: bin/deps-health-report (weekly lane), test/threadline/deps_health_report_test.exs, CONTRIBUTING.md freshness policy (215-01..05), bin/verify-deps-audit's refuse_global_hex_ignores mechanism (215-05)
provides:
  - bin/deps-health-report refuses a non-empty global Hex ignore_advisories/ignore_retirements (any HEX_HOME) or HEX_IGNORE_* env var before any per-dir mix call, classifying unknown
  - bin/deps-health-report fetches with deps.get --check-locked, so a drifted or missing mix.lock classifies unknown and skips that dir's audit/outdated
  - CONTRIBUTING.md states both new weekly-lane rules
  - .planning/phases/215-supply-chain-gate/deferred-items.md tracks every non-promoted 215-REVIEW finding (WR-01, WR-03..WR-08, IN-01..IN-04, MIX_EXS/MIX_HOME observation)
affects: [216, future-supply-chain-work]

actuals:
  tokens: 5898
  tasks: 2
  commits: 5

tech-stack:
  added: []
  patterns:
    - "Weekly (informational) lane mirrors the required gate's suppression-check mechanism exactly (same key order, same neutral-dir rule, same exact-`[]` parse) so the two scripts cannot disagree about what counts as suppressed"
    - "deps.get --check-locked as the single mechanism that also mitigates a missing-lockfile misclassification (WR-03), without a dedicated seam"

key-files:
  created: []
  modified:
    - bin/deps-health-report
    - test/threadline/deps_health_report_test.exs
    - CONTRIBUTING.md
    - .planning/phases/215-supply-chain-gate/deferred-items.md

key-decisions:
  - "CR-01 in the weekly lane: reused 215-05's read_global_hex_ignore/refuse_global_hex_ignores design (env var refusal, then a mix.exs-free neutral tmp dir query for both keys, exact-[] parse joining a multi-line-wrapped answer) rather than inventing a second parser — the drift-guard test asserts the literal key order string appears in both scripts."
  - "WR-02 in the weekly lane: deps.get --check-locked, matching 215-05's required-gate fix exactly; a --check-locked failure also mitigates WR-03 (missing mix.lock reported clean) as a side effect, verified live and recorded as `status: mitigated` rather than closed with a dedicated test."
  - "WR-08 (no Hex version floor in the weekly lane) is explicitly NOT a one-line change and stays deferred per the plan's own scope note — not attempted here."

requirements-completed: [SUP-04, SUP-03]

coverage:
  - id: D1
    description: "CR-01 closed in the weekly lane: an active Hex advisory suppression (env var or global hex.config ignore, either key) classifies unknown before any per-dir mix call, and names the reason in report.md"
    requirement: SUP-04
    verification:
      - kind: unit
        ref: "test/threadline/deps_health_report_test.exs#Hex advisory suppression a non-empty global hex.config ignore_advisories -> unknown, no per-dir mix calls, report names it"
        status: pass
      - kind: unit
        ref: "test/threadline/deps_health_report_test.exs#Hex advisory suppression a non-empty global hex.config ignore_retirements -> unknown, no per-dir mix calls, report names it"
        status: pass
      - kind: unit
        ref: "test/threadline/deps_health_report_test.exs#Hex advisory suppression HEX_IGNORE_ADVISORIES set in the environment -> unknown, no per-dir mix calls, report names it"
        status: pass
      - kind: unit
        ref: "test/threadline/deps_health_report_test.exs#Hex advisory suppression HEX_IGNORE_RETIREMENTS set in the environment -> unknown, no per-dir mix calls, report names it"
        status: pass
      - kind: unit
        ref: "test/threadline/deps_health_report_test.exs#Hex advisory suppression hex.config printing nothing fails closed"
        status: pass
      - kind: unit
        ref: "test/threadline/deps_health_report_test.exs#Hex advisory suppression hex.config exiting non-zero fails closed"
        status: pass
      - kind: manual_procedural
        ref: "real-Hex check: a throwaway HEX_HOME with mix hex.config ignore_advisories set classifies unknown, no leftover tmp dir"
        status: pass
    human_judgment: false
  - id: D2
    description: "The weekly lane's suppression check cannot diverge from the required gate's: same key order literal present in both scripts"
    requirement: SUP-04
    verification:
      - kind: unit
        ref: "test/threadline/deps_health_report_test.exs#Hex advisory suppression the suppression key literal is present in both bin/deps-health-report and bin/verify-deps-audit"
        status: pass
    human_judgment: false
  - id: D3
    description: "WR-02 closed in the weekly lane: deps.get --check-locked fails a drifted dir, skips its audit/outdated, keeps other dirs aggregating"
    requirement: SUP-04
    verification:
      - kind: unit
        ref: "test/threadline/deps_health_report_test.exs#committed lock (WR-02) a drifted lock in bench -> unknown, bench's audit/outdated skipped, root and example still run hex.audit"
        status: pass
      - kind: unit
        ref: "test/threadline/deps_health_report_test.exs#committed lock (WR-02) every fetch on a default run carries --check-locked"
        status: pass
    human_judgment: false
  - id: D4
    description: "CONTRIBUTING.md's weekly-lane paragraph states both new rules; every non-promoted 215-REVIEW finding is tracked in deferred-items.md with a status"
    requirement: SUP-03
    verification:
      - kind: other
        ref: "grep counts in acceptance criteria: check-locked/unknown >=2 in the policy section; 11 WR/IN entries + MIX_EXS observation + preserved ExUnitProperties entry"
        status: pass
    human_judgment: false
  - id: D5
    description: "Real tree still classifies clean/outdated; a global-ignore HEX_HOME classifies unknown; full suite, format, compile stay clean; no lockfile or protected-file diff"
    verification:
      - kind: integration
        ref: "mix test (2293 tests, 0 failures, 2 excluded); mix format --check-formatted; mix compile --warnings-as-errors; mix verify.deps_audit; bin/verify-deps-audit --self-test; git diff 0812bddb over locks/workflows/bin/upsert-ci-issue"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-09-27
status: complete
---

# Phase 215 Plan 06: Close CR-01 and WR-02 in the weekly (non-required) supply-chain lane Summary

**`bin/deps-health-report` now refuses to report `clean`/`outdated` under an active Hex advisory suppression (env var or global `hex.config` ignore, either key) — classifying `unknown` and naming the reason instead — and fetches every directory with `mix deps.get --check-locked`, mirroring the required gate's own CR-01/WR-02 fixes exactly; every non-promoted 215-REVIEW finding is now tracked in `deferred-items.md`.**

## Performance

- **Duration:** ~50 min
- **Started:** 2026-09-27T01:05:00Z (approx, from state)
- **Completed:** 2026-09-27T01:55:00Z (approx)
- **Tasks:** 2 (Task 1 tracer/TDD, Task 2 auto/TDD)
- **Files modified:** 4

## Accomplishments

- Closed CR-01 in the weekly lane: `bin/deps-health-report` now checks `HEX_IGNORE_ADVISORIES`/`HEX_IGNORE_RETIREMENTS`, then Hex's global `ignore_advisories`/`ignore_retirements` (via `mix hex.config`, run from a neutral `$ROOT/tmp/deps-health-hex-config.XXXXXX` dir, mirroring 215-05's mechanism verbatim) before touching any of the three canonical directories. An active suppression, or an unreadable/non-`[]` answer, bumps the classification to `unknown`, writes the reason at the top of `report.md`, and every per-dir section reports `skipped (Hex advisory suppression active)` instead of running `deps.get`/`hex.audit`/`hex.outdated`.
- A drift-guard test asserts the literal `ignore_advisories ignore_retirements` key-order string is present in both `bin/deps-health-report` and `bin/verify-deps-audit`, so the two scripts' suppression checks cannot silently diverge.
- Closed WR-02 in the weekly lane: every per-directory fetch is now `mix deps.get --check-locked`; a drifted (or missing) `mix.lock` fails that directory's fetch, bumps `unknown`, and skips that directory's `hex.audit`/`hex.outdated` with a report note explaining why — while the other canonical directories still aggregate normally.
- Verified live: `mix.lock` never rewritten on a real drifted-lock trial covered by the offline fake-mix matrix; real report on the clean tree still classifies `outdated` (informational, expected); a real global-ignore `HEX_HOME` classifies `unknown` with no leftover tmp dir.
- `CONTRIBUTING.md`'s weekly-lane paragraph now states both rules: `--check-locked` fetching and the suppression-triggers-`unknown` behavior.
- `.planning/phases/215-supply-chain-gate/deferred-items.md` gained 11 entries (WR-01, WR-03..WR-08, IN-01..IN-04) plus a new "Runtime MIX_EXS / MIX_HOME redirection" observation (threat T-215-36), each citing `215-REVIEW.md` and its file:line. WR-03 is recorded `status: mitigated` (the `--check-locked` change also stops a missing-lockfile misclassification as a side effect, with no dedicated seam or test) rather than closed. WR-08 (no Hex floor in the weekly lane) is confirmed out of scope and stays `open`, per the plan's own note that it is not a one-line change.

## Task Commits

Each task was committed atomically (Task 1 is `type="tracer" tdd="true"`, Task 2 is `type="auto" tdd="true"` — both carry a RED test commit and a GREEN implementation commit; Task 2's docs step is a third commit):

1. **Task 1 RED** — `728a8ac9` test(deps-health): reproduce global hex.config ignore bypass in the weekly lane (CR-01)
2. **Task 1 GREEN** — `1f136400` ci(deps-health): classify an active Hex advisory suppression as unknown (CR-01)
3. **Task 2 RED** — `4b831efe` test(deps-health): reproduce silent lock re-resolution in the weekly lane (WR-02)
4. **Task 2 GREEN** — `0a36f263` ci(deps-health): report on the committed lock via deps.get --check-locked (WR-02)
5. **Task 2 docs** — `d63d9060` docs(deps-health): state check-locked and suppression rules; track non-promoted review findings

**Plan metadata:** (this commit, following this SUMMARY)

_Tracer feedback gate: after Task 1's GREEN commit, auto mode (`workflow.auto_advance: true`) re-ran the tracer's `<automated>` verify end-to-end (`mix test` for the report + doc-contract test files, and the real-Hex `HEX_HOME` global-ignore check with the no-leftover-tmp-dir assertion) — all passed, so expansion into Task 2 proceeded with no checkpoint._

## Files Created/Modified

- `bin/deps-health-report` — new `read_global_hex_ignore`/`check_hex_suppression` functions and `SUPPRESSION_REASON` variable, checked before the canonical-dirs loop; per-dir fetch changed to `deps.get --check-locked` with a new note line on failure; header comments updated to describe both new rules; `cleanup_sections` EXIT trap extended to also remove the neutral hex-config tmp dir
- `test/threadline/deps_health_report_test.exs` — `fake_mix/0` logs full argument strings (not just the subcommand), gained a `hex.config)` case arm (`FAKE_HEX_CONFIG_IGNORE_ADVISORIES`/`_RETIREMENTS`/`_EXIT`, `__NOOUTPUT__` sentinel) and `FAKE_LOCK_DRIFT` handling on `deps.get`; new `describe "Hex advisory suppression"` (8 tests) and `describe "committed lock (WR-02)"` (2 tests)
- `CONTRIBUTING.md` — weekly-lane paragraph states the `--check-locked` fetch rule and the suppression-classifies-`unknown` rule
- `.planning/phases/215-supply-chain-gate/deferred-items.md` — 11 new entries (WR-01, WR-03 mitigated, WR-04..WR-08, IN-01..IN-04) plus the MIX_EXS/MIX_HOME runtime-redirection observation, appended after the pre-existing bench `ExUnitProperties` entry (preserved unchanged)

## Decisions Made

See `key-decisions` in the frontmatter. No deviation from the plan's specified design — Task 1's suppression-check logic and Task 2's `--check-locked` fetch were implemented exactly as 215-05 established them for the required gate, since the plan explicitly called for mirroring that mechanism so the two scripts cannot disagree.

## Deviations from Plan

None - plan executed exactly as written. The multi-line-wrapped `hex.config` answer parser and the `__NOOUTPUT__` sentinel pattern were both already-known gotchas from 215-05 (cited in this plan's `<context>` and required reading), so they were implemented correctly on the first pass rather than discovered as deviations here.

## Issues Encountered

One `mix test` run mid-session reported "1 failure" in the full suite; a clean re-run (2293 tests, 0 failures, 2 excluded) confirmed it was a transient flake unrelated to this plan's changes (no failure detail was captured in the truncated first run's tail output, and it did not reproduce). Not investigated further — full baseline is green on the authoritative re-run used for the plan's verification gate.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Both 215-VERIFICATION gaps (CR-01, WR-02) are now closed in the weekly, non-required lane, matching the required gate's fixes from 215-05 exactly, with a drift-guard test proving the two scripts cannot silently diverge.
- Every non-promoted 215-REVIEW finding (WR-01, WR-03..WR-08, IN-01..IN-04) is tracked in `deferred-items.md` with a status — none silently lost.
- `mix test` is green at 2293 tests (up from 2283 baseline before this plan; 0 failures, 2 excluded), `mix format --check-formatted` and `mix compile --warnings-as-errors` are clean, and no mix.lock, mix.exs constraint, workflow file, or `bin/upsert-ci-issue` was touched.
- Phase 215 gap-closure work (215-05 + 215-06) is complete; ready for phase re-verification or the next phase in the v1.43 milestone.

---
*Phase: 215-supply-chain-gate*
*Completed: 2026-09-27*

## Self-Check: PASSED

- Files verified present: `bin/deps-health-report`, `test/threadline/deps_health_report_test.exs`, `CONTRIBUTING.md`, `.planning/phases/215-supply-chain-gate/deferred-items.md`, this SUMMARY.md.
- Commits verified present in `git log`: `728a8ac9`, `1f136400`, `4b831efe`, `0a36f263`, `d63d9060`.
- All task `<acceptance_criteria>` and the plan-level `<verification>` block re-run and passing at commit time (see task-by-task verification runs above; full `mix test` at 2293/0 failures, 2 excluded).
