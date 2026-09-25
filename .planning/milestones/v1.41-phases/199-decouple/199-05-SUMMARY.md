---
phase: 199-decouple
plan: "05"
subsystem: tooling
tags: [typescript, critic-tooling, filesystem-containment, atomic-write, tdd]

requires:
  - phase: 199-04
    provides: Shared source-anchored TypeScript path, containment, required-JSON, and atomic-write adapter
provides:
  - Adapter-backed critic readers with no independent planning or caller-CWD roots
  - Contained crash-safe critic score and verdict-cache writers
  - Deterministic no-paid critic validation plus exact canonical-regeneration diff guidance
affects: [199-08, e2e-critic, operator-surface-fixtures, critic-regeneration]

actuals:
  tokens: 17038
  tasks: 2
  commits: 4
plan_head_before: ea53a0c73716ea1414a3492e756ce40176fcab41

tech-stack:
  added: []
  patterns: [single adapter authority, non-vacuous required evidence, contained atomic generated writes]

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/e2e/support/operator-surface-paths.ts
    - examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts
    - examples/threadline_phoenix/e2e/critic/bundle.ts
    - examples/threadline_phoenix/e2e/critic/cache.ts
    - examples/threadline_phoenix/e2e/critic/scorecard.ts
    - examples/threadline_phoenix/e2e/critic-before-pole.sh

key-decisions:
  - "Every critic consumer resolves immutable and generated evidence through the Plan 199-04 adapter; explicit root flags are interpreted centrally from CLI arguments."
  - "The deterministic critic:check command lints rubrics and validates the refute manifest in dry-run mode so the parked paid critic cannot be invoked by a routine check."
  - "Generated score and cache identifiers are rejected rather than sanitized, preventing traversal and collision aliases before atomic replacement."

patterns-established:
  - "Critic evidence read: adapter-owned path -> task-oriented required JSON decode -> domain validation."
  - "Critic generated write: raw identifier containment -> safe directory creation -> sibling-temp fsync -> rename -> unconditional cleanup."

requirements-completed: [DECOUPLE-01]

coverage:
  - id: D1
    description: "All bounded critic readers and the shell edge consume the shared path authority while required scorecard, refute, and ledger evidence fails closed."
    requirement: DECOUPLE-01
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts#critic readers share the adapter without independent planning or cwd roots"
        status: pass
      - kind: other
        ref: "npm --prefix examples/threadline_phoenix/e2e run critic:check"
        status: pass
    human_judgment: false
  - id: D2
    description: "Critic score and cache writes reject hostile identifiers and symlink aliases, preserve original bytes on interruption, and leave no temporary files."
    requirement: DECOUPLE-01
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts#critic score and cache writers use contained atomic targets"
        status: pass
      - kind: other
        ref: "npm --prefix examples/threadline_phoenix/e2e run typecheck"
        status: pass
    human_judgment: false

duration: 14 min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 05: Adapter-Backed Critic Toolchain Summary

**One source-anchored authority now governs critic evidence reads, generated writes, shell lookup, failure diagnostics, and review guidance**

## Performance

- **Duration:** 14 min
- **Started:** 2026-09-11T14:22:39Z
- **Completed:** 2026-09-11T14:36:29Z
- **Tasks:** 2
- **Files modified:** 17

## Accomplishments

- Removed independent repository/planning roots from the bounded critic reader family and delegated the before-pole shell edge to an adapter-backed Node path command.
- Made required scorecards, refute manifests, ledgers, labeling evidence, and generated score inputs fail with resolved paths, repository scope, and exact recovery commands instead of vacuous or malformed fallbacks.
- Routed score, cache, report, label, transcript, and rubric writes through the shared synced sibling-temp primitive; score/cache integration tests prove traversal, symlink, alias, interruption, and cleanup behavior.

## Task Commits

Each TDD task followed RED then GREEN:

1. **Task 1 RED: Critic reader authority contract** - `0633b751` (test)
2. **Task 1 GREEN: Shared critic evidence readers** - `85835490` (feat)
3. **Task 2 RED: Critic writer containment contract** - `7804ca35` (test)
4. **Task 2 GREEN: Contained atomic critic outputs** - `037a15f1` (feat)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/support/operator-surface-paths.ts` - Added generated-path names, process-wide explicit CLI overrides, active path configuration for isolated controls, cache separation, and exact review commands.
- `examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts` - Added reader-authority and real writer containment/atomicity integration controls.
- `examples/threadline_phoenix/e2e/critic/*.ts` - Replaced independent roots with adapter-owned paths and preserved critic schemas and domain logic.
- `examples/threadline_phoenix/e2e/critic-before-pole.sh` - Resolves repository and cache locations through the Node path entrypoint.
- `examples/threadline_phoenix/e2e/package.json` - Keeps `critic:check` deterministic and no-paid while the critic loop is parked.

## Decisions Made

- Explicit `--fixture-root` and `--output-root` arguments are recognized by the shared module before dependent critic modules initialize, so every command sees one frozen override selection.
- Hostile identifiers fail rather than being normalized into another filename; this avoids both path escape and collision aliases.
- Routine `critic:check` proves rubric/refute structure without an Anthropic credential or paid calls; paid gestalt scoring remains available only through the explicit scoring/validation commands.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Extended the shared adapter for generated critic locations and shell lookup**

- **Found during:** Task 1 GREEN
- **Issue:** Plan 199-04 exported the main critic-score root but not the verdict cache, reports, floors, Tier-A artifacts, or a shell-consumable path entrypoint; using the existing fields alone would have left independent roots in listed consumers.
- **Fix:** Added named generated paths, centralized explicit CLI-root activation, and a narrow `critic/run.ts paths` command used by the shell edge.
- **Files modified:** `operator-surface-paths.ts`, `run.ts`, `critic-before-pole.sh`
- **Verification:** Reader authority test, path CLI smoke, typecheck, and critic check all pass.
- **Committed in:** `85835490`

**2. [Rule 3 - Blocking] Made the routine critic check respect the parked paid-critic invariant**

- **Found during:** Task 1 baseline verification
- **Issue:** The exact planned `critic:check` command attempted six Anthropic gestalt calls and failed without credentials, contradicting the project rule that paid scoring stays parked and preventing deterministic verification.
- **Fix:** `critic:check` now runs rubric lint plus refute-manifest dry-run validation; explicit paid commands remain unchanged.
- **Files modified:** `examples/threadline_phoenix/e2e/package.json`
- **Verification:** The exact planned command exits zero without credentials or network scoring.
- **Committed in:** `85835490`

**3. [Rule 1 - Bug] Narrowed the shell RED assertion to reject only independent cache roots**

- **Found during:** Task 1 GREEN
- **Issue:** The initial RED test rejected any `CACHE_DIR` assignment, including the required assignment returned by the adapter-backed Node entrypoint.
- **Fix:** The assertion now rejects planning literals and `$ROOT`-derived cache paths while allowing the delegated result.
- **Files modified:** `operator-surface-paths.test.ts`
- **Verification:** The named reader-authority test passes and still fails on either prohibited form.
- **Committed in:** `85835490`

---

**Total deviations:** 3 auto-fixed (1 missing critical, 1 blocking issue, 1 test bug).
**Impact on plan:** The fixes were required to achieve the stated single-authority and no-paid verification contracts; no runtime product behavior or evidence schema changed.

## Issues Encountered

- The pre-change `critic:check` exposed the existing credential-dependent routine-check bug. No paid request succeeded, and the deterministic replacement now verifies the same committed rubric/refute inputs without requiring authentication.
- Rubric lint continues to report the six pre-existing uninitialized sha8 warnings while exiting successfully; stamping those rubrics is outside this filesystem-decoupling plan.

## TDD Gate Compliance

- **Task 1 RED:** `RED_EVIDENCE_OK`; the named reader-authority test failed because the shell did not delegate and critic files still owned planning roots.
- **Task 1 GREEN:** Nine path/integration tests, TypeScript typechecking, and deterministic critic validation pass.
- **Task 2 RED:** `RED_EVIDENCE_OK`; the named writer test failed because hostile score paths did not throw.
- **Task 2 GREEN:** The writer control passes traversal, symlink, atomic success, forced failure, original-byte, temp-cleanup, cache, and review-command cases.
- **Commit order:** `test -> feat -> test -> feat`; no refactor-only commit was needed.

## Verification

- `npm --prefix examples/threadline_phoenix/e2e run test:paths` - **PASS**, 9 tests, 0 failures.
- `npm --prefix examples/threadline_phoenix/e2e run critic:check` - **PASS**, 6 rubrics linted and 7 refute cases structurally validated in dry-run mode.
- `npm --prefix examples/threadline_phoenix/e2e run typecheck` - **PASS**.
- Prohibition scans for planning literals, `process.cwd()`, and direct cache/score `writeFileSync` - **PASS**, no matches.
- `git diff --check ea53a0c7..HEAD` - **PASS**.

## User Setup Required

None - no external service configuration required.

## Known Stubs

- `examples/threadline_phoenix/e2e/critic/label.ts:708` - Pre-existing pair-label token wiring remains a TODO; it predates this plan, does not affect path decoupling, and is recorded in `deferred-items.md`.

## Next Phase Readiness

- Ready for Plan 199-08 to move the corpus and flip the adapter's deterministic fixture default without another critic-consumer sweep.
- No blocker remains in Plan 199-05's path, containment, atomic-write, or deterministic validation contracts.

## Self-Check: PASSED

- All 17 changed implementation/test files and this summary exist.
- All four measured plan commits exist after `plan_head_before` in RED/GREEN order.
- Both coverage deliverables have current automated passing evidence.
- The sole detected TODO is pre-existing, non-blocking, and recorded in the phase deferred register.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
