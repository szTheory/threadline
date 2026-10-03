---
phase: 226-pure-property-tests-and-run-budget
plan: 01
subsystem: testing
tags: [stream_data, property-testing, redaction, mutation-testing, run-budget]

requires: []
provides:
  - "Threadline.Test.PropertyRuns (test/support/property_runs.ex): env_var/0, parse_scale/1, scale/0, pure/1, db/1 — THREADLINE_PROPERTY_SCALE read at runtime"
  - "Threadline.Test.RedactionPolicyGenerators (test/support/redaction_policy_generators.ex): valid_policy_gen/0, invalid_policy_gen/0, policy_gen/0, defect_tags/0"
  - "PROP-03 property: test/threadline/capture/redaction_policy_property_test.exs"
  - "Re-runnable mutation-control runner: .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh"
  - "D-18 fix: RedactionPolicy and TriggerCaptureConfig raise ArgumentError instead of silently dropping/crashing on bad exclude:/mask:/mask_placeholder:"
affects: [226-02, 226-03, 226-04, 226-05, 226-06, 227]

actuals:
  tokens: 9521
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "PropertyRuns.pure/1 / .db/1 as the single max_runs scale knob, read at runtime (never a module attribute — test/support is compiled once)"
    - "Generators label valid/invalid inputs by construction (tag fixed before validate!/1 runs) — no tautological oracle"
    - "Re-runnable, lib-only mutation-control.sh: refuse-on-dirty-lib, apply+trap-revert, K/K kill requirement, reproduce seed 1, require green+clean after restore, markdown evidence output scrubbed of absolute paths/home/username"

key-files:
  created:
    - test/support/property_runs.ex
    - test/support/redaction_policy_generators.ex
    - test/threadline/capture/redaction_policy_property_test.exs
    - .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh
    - .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/redaction_policy.patch
    - .planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/redaction_policy_length.patch
    - .planning/phases/226-pure-property-tests-and-run-budget/evidence/PROP-03-mutation-trim.md
    - .planning/phases/226-pure-property-tests-and-run-budget/evidence/PROP-03-mutation-length.md
  modified:
    - lib/threadline/capture/redaction_policy.ex
    - lib/threadline/capture/trigger_capture_config.ex
    - test/threadline/capture/trigger_capture_config_test.exs
    - CHANGELOG.md

key-decisions:
  - "StreamData's uniq_list_of/2 hit the 'too many non-unique elements' guard on the small (6-name) fixed pools; switched to a plain bounded list_of/2 deduplicated with Enum.uniq in the generator body"
  - "D-18 fix comments initially cited the plan decision ID (D-18) inline in lib/ source, which the release-artifact contract test (planning-vocabulary ban) correctly flagged; reworded as durable domain rationale with no plan-ID references"
  - "build_opts/4 is generic over the exclude/mask value type (not just lists), so the :non_list_columns generator reuses it directly instead of a parallel builder"

requirements-completed: [PROP-03, PROP-08]

coverage:
  - id: D1
    description: "Threadline.Test.PropertyRuns reads THREADLINE_PROPERTY_SCALE at runtime and exposes pure/1 and db/1 max_runs multipliers"
    requirement: "PROP-08"
    verification:
      - kind: unit
        ref: "mix test test/threadline/capture/redaction_policy_property_test.exs (uses PropertyRuns.pure/1 as max_runs)"
        status: pass
    human_judgment: false
  - id: D2
    description: "PROP-03 property proves every generated valid redaction policy returns :ok and every tagged invalid policy raises ArgumentError matching its tag, against the real RedactionPolicy.validate!/1"
    requirement: "PROP-03"
    verification:
      - kind: unit
        ref: "mix test test/threadline/capture/redaction_policy_property_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Re-runnable mutation-control.sh proves both PROP-03 mutants (trim removal, length >= off-by-one) are killed 5/5, reproduce the same counterexample, and restore lib/ to green"
    verification:
      - kind: other
        ref: "bash .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh --max-runs 200 <patch> test/threadline/capture/redaction_policy_property_test.exs 5"
        status: pass
    human_judgment: false
  - id: D4
    description: "D-18: a non-list exclude:/mask: and a non-binary mask_placeholder: now raise ArgumentError (not silently dropped / not FunctionClauseError), on both the direct RedactionPolicy path and the TriggerCaptureConfig.load/1 path; CHANGELOG upgrade note added"
    requirement: "PROP-03"
    verification:
      - kind: unit
        ref: "mix test test/threadline/capture/redaction_policy_property_test.exs test/threadline/capture/trigger_capture_config_test.exs test/threadline/capture/trigger_redaction_test.exs"
        status: pass
    human_judgment: false

duration: ~1h
completed: 2026-10-01
status: complete
---

# Phase 226 Plan 1: Pure Property Tests and Run Budget — Tracer Summary

**PROP-03 redaction-policy property with a six-tag generator, the PropertyRuns run-budget helper, a re-runnable lib-only mutation-control script, and two D-18 fixes that make silent redaction misconfiguration raise instead of fail open.**

## Performance

- **Duration:** ~1h
- **Started:** 2026-10-01 (approx. 08:10 ET)
- **Completed:** 2026-10-01T12:25:24Z
- **Tasks:** 3
- **Files modified:** 12 (8 created, 4 modified)

## Accomplishments

- `Threadline.Test.PropertyRuns` — the single `THREADLINE_PROPERTY_SCALE` run-budget knob, read at runtime (never cached at compile time), with `pure/1` and `db/1` multipliers, feeding every later property-test plan in this phase.
- `Threadline.Test.RedactionPolicyGenerators` builds valid policies from two disjoint name pools (string/padded-string/atom/padded-atom rendering, blank entries, keyword/map opts) and six tagged invalid-policy generators (`:overlap`, `:empty_placeholder`, `:too_long`, `:control_char`, `:non_list_columns`, `:non_binary_placeholder`), each labeled at construction time so the property's oracle is never derived by calling the code under test.
- PROP-03 property (`redaction_policy_property_test.exs`) runs `async: true` against the real `RedactionPolicy.validate!/1`, asserting every tag's message against a named regex, plus a `describe "D-18 regression examples"` block pinning every keep-behaviour (nil exclude, `false`/`nil` placeholder fallback, atom-key-wins, 200-grapheme acceptance, DEL/U+0085 acceptance).
- `.planning/.../tools/mutation-control.sh` — a re-runnable, lib-only mutation-control runner (refuses on dirty `lib/`, lib-only patch paths, trap-guarded revert, K/K kill requirement, seed-1 reproduction check, post-restore green + clean `lib/` requirement, markdown evidence output with repo-root/`$HOME`/`whoami` scrubbed) proven end-to-end on the tracer property before any expansion task, and reused for both PROP-03 mutation controls.
- D-18 fixed on both paths: `RedactionPolicy.normalize_columns/2` now raises `ArgumentError` naming the key and "must be a list" instead of silently returning `[]`; `validate_placeholder!/1` gains a catch-all raising `ArgumentError` instead of `FunctionClauseError`; `TriggerCaptureConfig.normalize_table_entry/2` gained its own `check_column_list!/3` guard so the config-load path has the same fail-loud behaviour before `normalize_columns/1` ever runs. CHANGELOG Unreleased Breaking changes documents the upgrade.
- Both PROP-03 mutation controls (trim removal, `>` → `>=` length off-by-one) recorded in `evidence/`, each 5/5 kill, seed-1 reproduction confirmed, `lib/` restored clean.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — PropertyRuns + overlap property + mutation-control runner, end to end** - `679544d5` (test)
2. **Task 2: D-18 — redaction-policy validation fails loudly** - `24c7af2e` (fix, RedactionPolicy) + `00fd767c` (fix, TriggerCaptureConfig)
3. **Task 3: Full PROP-03 generator ladder and both mutation controls recorded** - `d2064aa3` (test)

_Note: Task 2 split into two `fix:` commits, one per file, as the plan allowed ("two commits are fine: one per defect")._

## Files Created/Modified

- `test/support/property_runs.ex` - `Threadline.Test.PropertyRuns`: runtime-read `THREADLINE_PROPERTY_SCALE`, `pure/1`/`db/1` max_runs helpers
- `test/support/redaction_policy_generators.ex` - valid/invalid (6-tag) redaction-policy generators, `defect_tags/0`
- `test/threadline/capture/redaction_policy_property_test.exs` - PROP-03 property + D-18 regression examples
- `lib/threadline/capture/redaction_policy.ex` - D-18: `normalize_columns/2` raises on non-list, `validate_placeholder!/1` catch-all raises `ArgumentError`, doc wording corrected to "graphemes"
- `lib/threadline/capture/trigger_capture_config.ex` - D-18: `check_column_list!/3` rejects a non-nil non-list `exclude:`/`mask:` before `normalize_columns/1` runs
- `test/threadline/capture/trigger_capture_config_test.exs` - D-18 regression examples for the config-load path
- `CHANGELOG.md` - Unreleased Breaking changes upgrade note
- `.planning/.../tools/mutation-control.sh` - re-runnable lib-only mutation-control runner (reused by plans 02-06 and phase 227)
- `.planning/.../tools/mutations/redaction_policy.patch` - removes the `String.trim/1` mapping
- `.planning/.../tools/mutations/redaction_policy_length.patch` - `>` → `>=` on the length check
- `.planning/.../evidence/PROP-03-mutation-trim.md`, `.../PROP-03-mutation-length.md` - mutation-control evidence, 5/5 each

## Decisions Made

- `uniq_list_of/2` over a 6-element pool hit StreamData's "too many non-unique elements" guard at high generation sizes; switched to `list_of/2` + `Enum.uniq/1` in the generator body for `names_subset_gen/1`.
- The D-18 fix's first draft cited the plan decision ID ("D-18") directly in a `lib/` code comment; the `release_artifact_contract_test.exs` planning-vocabulary ban correctly caught this on the full-suite run. Reworded both comments as durable domain rationale with no references to plan artifacts — this is the kind of defect the gate exists to catch, not a gate to route around.
- `build_opts/4` was kept generic over the exclude/mask value type rather than typed to lists-only, so the `:non_list_columns` invalid-policy generator (which needs to pass an atom/binary/integer/map as the `exclude:`/`mask:` value) reuses it directly instead of a parallel opts builder.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed plan-ID references from lib/ code comments**
- **Found during:** Task 2, full-suite verification
- **Issue:** `check_column_list!/3`'s doc comment cited "(D-18)" inline, which `test/threadline/release_artifact_contract_test.exs` flags as packaged planning vocabulary (2 test failures: "the entire readable archive is free of planning vocabulary" and "all packaged source uses durable vocabulary")
- **Fix:** Reworded the comment to explain the rationale without referencing the plan decision ID
- **Files modified:** `lib/threadline/capture/trigger_capture_config.ex`
- **Verification:** `mix test test/threadline/release_artifact_contract_test.exs` passes; full suite re-run green (2600 tests, 0 failures)
- **Committed in:** `00fd767c` (part of Task 2's second commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — bug/contract violation)
**Impact on plan:** No scope creep; the fix only touched comment wording, not behavior.

## Issues Encountered

None beyond the deviation above. Two concurrent `mix test` invocations were accidentally started during verification (a stray background run colliding with the DB migrator); this is an operational artifact of this session, not a code or environment defect — resolved by not running them concurrently.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `Threadline.Test.PropertyRuns` and `.planning/.../tools/mutation-control.sh` are proven end-to-end and ready for reuse by plans 02-06 (PROP-01, PROP-02, PROP-05, PROP-08 pinning test, generator coverage test) and Phase 227's DB-backed properties.
- PROP-03 and the D-18 fixes (both the direct and config-load paths) are complete; `except_columns` on `TriggerCaptureConfig` has the same silent-coercion shape but is explicitly out of D-18's scope (noted in the plan, not fixed here) — a candidate for a future hardening pass if it proves to matter.
- No blockers for 226-02 onward.

---
*Phase: 226-pure-property-tests-and-run-budget*
*Completed: 2026-10-01*

## Self-Check: PASSED

All 8 created files confirmed present on disk; all 4 task commits (`679544d5`, `24c7af2e`, `00fd767c`, `d2064aa3`) confirmed in `git log --oneline --all`.
