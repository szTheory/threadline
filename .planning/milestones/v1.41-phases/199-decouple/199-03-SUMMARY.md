---
phase: 199-decouple
plan: "03"
subsystem: tooling
tags: [elixir, mix-task, filesystem-containment, atomic-write, tdd]

requires: []
provides:
  - Project-file-anchored private fixture and critic-score root overrides
  - Fail-closed traversal, symlink, prefix-confusion, alias, and evidence-schema validation
  - Exclusive sibling-temp, sync, close-before-rename replacement for both canonical critic writers
affects: [199-08, critic-measure, critic-synth, operator-surface-fixtures]

actuals:
  tokens: 8861
  tasks: 2
  commits: 5
plan_head_before: a6e062286f03c5941b5a56d600495690ec0eaa9e

tech-stack:
  added: []
  patterns: [Mix.Project.project_file anchor, Path.safe_relative_to containment, exclusive sibling-temp replacement]

key-files:
  created: []
  modified:
    - lib/mix/tasks/critic.measure.ex
    - lib/mix/tasks/critic.synth.ex
    - test/threadline/operator_surface/critic_trust_test.exs

key-decisions:
  - "Private Mix-task overrides resolve within the loaded repository and generated critic scores remain separate from immutable evidence roots."
  - "Canonical fixture replacement uses an exclusive sibling temp, file sync, close-before-rename, and unconditional temp cleanup."

patterns-established:
  - "Repository-only task edge: validate and decode every filesystem input before calling the pure measurement engine or opening an output."
  - "Atomic canonical write: exclusive sibling temp -> write -> sync -> close -> rename -> cleanup -> exact git diff command."

requirements-completed: [DECOUPLE-01]

coverage:
  - id: D1
    description: "critic.measure resolves deterministic project-anchored roots and rejects unsafe, aliased, missing, or malformed evidence before ledger mutation."
    requirement: DECOUPLE-01
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/critic_trust_test.exs#critic.measure path-boundary cases"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/operator_surface/critic_trust_test.exs --max-failures 1 (28 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "critic.measure and critic.synth replace canonical files atomically, preserve originals on interruption, clean temps, and print exact review commands."
    requirement: DECOUPLE-01
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/critic_trust_test.exs#canonical atomic writer cases"
        status: pass
      - kind: other
        ref: "source scan confirms no direct canonical File.write remains"
        status: pass
    human_judgment: false

duration: 16 min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 03: Safe Critic Evidence Edges Summary

**Project-anchored, schema-validated critic evidence reads with symlink-safe containment and crash-safe atomic ledger/oracle regeneration**

## Performance

- **Duration:** 16 min
- **Started:** 2026-09-11T03:27:11Z
- **Completed:** 2026-09-11T03:43:22Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added private `--fixture-root` and `--output-root` contracts anchored to `Mix.Project.project_file/0`, independent of caller CWD and ambient environment.
- Rejected traversal, absolute escape, prefix confusion, symlink aliases, immutable/output aliases, missing roots, malformed JSON, and invalid evidence schemas before canonical writes.
- Replaced both direct canonical writers with exclusive same-directory temps that sync, close, rename, clean on failure, preserve originals under injected interruption, and print exact `git diff -- <target>` commands.

## Task Commits

Each task followed a RED→GREEN TDD cycle, with one correctness hardening commit:

1. **Task 1 RED: Safe critic measurement roots** - `aebb8fb1` (test)
2. **Task 1 GREEN: Project-anchored validated measurement inputs** - `700e81a3` (feat)
3. **Task 2 RED: Atomic critic writers** - `4a21317e` (test)
4. **Task 2 GREEN: Atomic canonical fixture replacement** - `a336553a` (feat)
5. **Rule 2 hardening: Evidence schema validation** - `2ca1f6e3` (fix)

## Files Created/Modified

- `lib/mix/tasks/critic.measure.ex` - Private path adapter, containment/separation checks, actionable decode/schema failures, and atomic ledger replacement.
- `lib/mix/tasks/critic.synth.ex` - Project-anchored fixture override and atomic synthetic-oracle regeneration.
- `test/threadline/operator_surface/critic_trust_test.exs` - Nested-CWD, override, traversal, symlink, alias, malformed-input, interruption, cleanup, and review-command controls.

## Decisions Made

- Kept all repository discovery and validation private to the two Mix-task edges; `Threadline.CriticTrust.Measure` remains a pure decoded-data engine with no filesystem resolver API.
- Treated `.planning/critic-scores` as the current generated output root while `.planning/golden`, `.planning/scorecards`, `.planning/refute`, and the ledger remain immutable/canonical evidence targets. Plan 199-08 can flip these anchored defaults during the atomic fixture move.
- Used `Path.safe_relative_to/2` after repository-relative normalization, which rejects traversal and every symlink component rather than relying on vulnerable string-prefix comparisons.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced unsupported `mix test -x` verification flag**

- **Found during:** Task 1 RED verification
- **Issue:** The installed Mix 1.19.5 CLI rejects `-x` before test discovery, so the literal plan command cannot produce valid RED or completion evidence.
- **Fix:** Used `--max-failures 1`, the supported fail-fast equivalent, with the same focused test file.
- **Files modified:** None
- **Verification:** `mix test test/threadline/operator_surface/critic_trust_test.exs --max-failures 1` completed with 28 tests and 0 failures.
- **Committed in:** No source change required

**2. [Rule 2 - Missing Critical] Added decoded evidence schema validation**

- **Found during:** Post-GREEN threat-boundary review
- **Issue:** Valid JSON with invalid top-level/item or critic-score field types could reach the pure engine and raise an unstructured exception, violating the fail-before-IO and actionable-error contract.
- **Fix:** Added golden collection/item and critic-score field validation at the Mix edge, plus a malformed-schema control proving the ledger stays byte-identical.
- **Files modified:** `lib/mix/tasks/critic.measure.ex`, `test/threadline/operator_surface/critic_trust_test.exs`
- **Verification:** Focused suite passes 28 tests; malformed structural JSON raises the repository-only task error before ledger mutation.
- **Committed in:** `2ca1f6e3`

**3. [Rule 3 - Blocking] Applied the roadmap handler's narrow fallback**

- **Found during:** Post-summary planning-state synchronization
- **Issue:** `roadmap.update-plan-progress 199` returned `missing_phase_details` although the Phase 199 checklist exists.
- **Fix:** Marked only the completed `199-03-PLAN.md` checklist row as complete; the phase remains in progress.
- **Files modified:** `.planning/ROADMAP.md`
- **Verification:** The Plan 03 row is checked while all other unfinished Phase 199 plan rows remain unchecked.
- **Committed in:** Final planning-state commit

---

**Total deviations:** 3 auto-fixed (2 blocking workflow corrections, 1 missing critical validation).
**Impact on plan:** The changes enforce the intended verification/filesystem trust boundary and accurate progress tracking without adding public API or expanding product scope.

## Issues Encountered

- Repository-wide `mix verify.format` remains red on four pre-existing Phase 198 test files outside this plan. All three plan-owned files pass direct `mix format --check-formatted`; the unrelated drift is already recorded in Phase 199 `deferred-items.md` and was not modified.

## TDD Gate Compliance

- **Task 1 RED:** `RED_EVIDENCE_OK` — unsafe/aliased roots were ignored by the old task, causing the named behavioral assertion to fail.
- **Task 1 GREEN:** The focused root-boundary cases passed before commit `700e81a3`.
- **Task 2 RED:** `RED_EVIDENCE_OK` — the old writer ignored an injected interruption and failed the original-byte preservation assertion.
- **Task 2 GREEN:** Atomic replacement, interruption cleanup, and exact review-command cases passed before commit `a336553a`.
- **Commit order:** `test → feat → test → feat → fix`; no refactor commit was needed after the final green implementation.

## Verification

- `mix test test/threadline/operator_surface/critic_trust_test.exs --max-failures 1` — **PASS**, 28 tests, 0 failures.
- `mix format --check-formatted lib/mix/tasks/critic.measure.ex lib/mix/tasks/critic.synth.ex test/threadline/operator_surface/critic_trust_test.exs` — **PASS**.
- `MIX_BUILD_PATH=_build/199_03 mix compile --warnings-as-errors` — **PASS**.
- Temp-leak scan for `*.tmp-*` under the isolated test tree — **PASS**, no matches.
- Direct canonical `File.write` scan over both Mix tasks — **PASS**, no matches.
- `mix verify.format` — **FAIL outside plan scope** on four unchanged Phase 198 test files; previously recorded in the phase deferred-items register.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for Plan 199-08 to atomically move fixture roots and flip these private anchored defaults without changing the safety contract.
- No blocker exists in the critic task edges; the pre-existing repository-wide formatter drift remains independently deferred.

## Self-Check: PASSED

- All three modified implementation/test files and this summary exist on disk.
- All five measured plan commits are present after the persisted plan-head ledger.
- Both RED evidence records validated as `RED_EVIDENCE_OK`; final focused tests, targeted formatting, compilation, containment controls, and atomic-write controls pass.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
