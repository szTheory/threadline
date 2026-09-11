---
phase: 199-decouple
plan: "11"
subsystem: repository-hygiene
tags: [clean-checkout, shell-safety, git-worktrees, exunit, tdd]

requires:
  - phase: 199-decouple
    plan: "10"
    provides: "anchored generated-output ignores and reviewed-output trackability policy"
provides:
  - "sourceable temp-child cleanup guarded by canonical paths, lstat identity, and the complete Git worktree registry"
  - "committed-HEAD no-local clone proof for locked dependencies, generated probes, and trackable controls"
affects: [DECOUPLE-05, contributor-dx, repository-safety, generated-output-policy]

actuals:
  tokens: 4996
  tasks: 2
  commits: 4
plan_head_before: b548e5f994f1b656bf3de6ec65cc8ee8808f5107

tech-stack:
  added: []
  patterns:
    - "recursive cleanup is centralized behind canonical direct-child, non-symlink, lstat-identity, and worktree-root checks"
    - "repository hygiene is proven from an exact detached committed SHA in a no-local disposable clone"

key-files:
  created:
    - bin/safe-temp-tree
    - bin/verify-clean-checkout
  modified:
    - test/threadline/clean_checkout_contract_test.exs
    - .planning/phases/199-decouple/deferred-items.md

key-decisions:
  - "Cleanup registration snapshots both trusted-parent and literal-child canonical paths and device/inode identities, then repeats those validations immediately before deletion."
  - "Every porcelain-listed main or linked Git worktree is canonicalized and compared for exact equality with the cleanup target before removal."
  - "The clean-checkout verifier detaches the clone at the caller's committed HEAD, proving policy without inheriting index or untracked state."

patterns-established:
  - "Safe temp cleanup: register one existing canonical direct child, validate the same filesystem objects at exit, reject all worktree roots, and remove only the quoted child."
  - "Clean checkout proof: dependency status, generated probes, and reviewed-source controls are independent assertions with explicit status markers."

requirements-completed: [DECOUPLE-05]

coverage:
  - id: D1
    description: "An ordinary registered child is removed, while empty/root/parent/outside/worktree/symlink/replacement targets are rejected and sentinels survive byte-identically."
    requirement: DECOUPLE-05
    verification:
      - kind: integration
        ref: "test/threadline/clean_checkout_contract_test.exs#safe temp-tree cleanup"
        status: pass
    human_judgment: false
  - id: D2
    description: "A no-local clone at exact committed HEAD remains clean after locked dependency fetch and all generated-output probes."
    requirement: DECOUPLE-05
    verification:
      - kind: integration
        ref: "bin/verify-clean-checkout"
        status: pass
    human_judgment: false
  - id: D3
    description: "Reviewed snapshot and source probes remain visible, and a forced verifier failure cleans only its clone child while preserving caller state."
    requirement: DECOUPLE-05
    verification:
      - kind: integration
        ref: "test/threadline/clean_checkout_contract_test.exs#committed checkout verifier"
        status: pass
    human_judgment: false

duration: 11min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 11: Hardened Cleanup and Committed Clean-Clone Proof Summary

**Exact committed HEAD now proves clean dependency and generated-output behavior inside a no-local disposable clone whose only recursive cleanup is protected against path mutation and every registered Git worktree root.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-09-11T14:52:23Z
- **Completed:** 2026-09-11T15:03:03Z
- **Tasks:** 2
- **Files modified:** 4 production/test/planning files

## Accomplishments

- Added one sourceable cleanup primitive that accepts an explicit trusted parent and literal child, snapshots their canonical lstat identities, and rejects empty, root, parent, outside, symlinked, replaced, or non-direct-child targets.
- Parsed the complete `git worktree list --porcelain -z` registry and refused cleanup when the canonical child equals either the main checkout or any linked worktree; the adversarial linked-worktree test proves its binary sentinel and registration survive.
- Added a no-local clone verifier that detaches at the exact committed source SHA, runs `mix deps.get --check-locked`, proves exact empty porcelain status after dependency fetch and generated probes, and proves reviewed snapshot/source controls remain visible.
- Routed forced verifier failure through the same safe trap and proved it removes only the clone child without changing caller `HEAD`, caller porcelain status, or a neighboring sentinel.

## Task Commits

1. **Task 1 RED: failing hostile cleanup and linked-worktree contract** — `25d2b58b` (test)
2. **Task 1 GREEN: canonical/lstat/worktree-root cleanup guard** — `6f35208b` (feat)
3. **Task 2 RED: failing committed-checkout verifier contract** — `c04265f7` (test)
4. **Task 2 GREEN: exact-HEAD clean clone verifier** — `dc21bc8d` (feat)

## Files Created/Modified

- `bin/safe-temp-tree` — registration and immediate pre-removal validation for exactly one ordinary temporary child.
- `bin/verify-clean-checkout` — committed-HEAD no-local clone, dependency fetch, generated-output probes, trackable controls, and failure-safe trap.
- `test/threadline/clean_checkout_contract_test.exs` — valid cleanup, hostile mutation, linked-worktree, committed-clone, and forced-failure restoration controls.
- `.planning/phases/199-decouple/deferred-items.md` — records the pre-existing advisories reported by the locked dependency fetch without changing dependency policy in this plan.

## Decisions Made

- Registration is explicit and source-process-local: callers provide an already created canonical parent and direct child, and cleanup accepts only those exact registered objects.
- Missing stale worktree paths are skipped, but any live registered path is canonicalized and compared. If a previously missing registered path becomes the proposed live target, it is therefore rejected.
- The test-only forced-failure switch is intentionally narrow (`THREADLINE_VERIFY_CLEAN_CHECKOUT_FORCE_FAILURE=1`) and runs after clone identity verification but before dependency fetch; it exposes trap behavior without accepting arbitrary commands.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced unsupported `mix test -x` verification syntax**

- **Found during:** Task 1 RED execution.
- **Issue:** This repository's installed Mix task rejects `-x` before ExUnit can discover tests.
- **Fix:** Used `--max-failures 1`, the supported fail-fast equivalent, for focused and final contract verification.
- **Files modified:** None.
- **Verification:** Final focused run passed 7/7 and the standalone verifier passed.

**2. [Rule 1 - Bug] Canonicalized platform temp roots and made linked-worktree teardown explicitly ordered**

- **Found during:** Task 1 GREEN verification.
- **Issue:** macOS exposes temporary roots through aliases such as `/var` → `/private/var`; additionally, generic fixture cleanup could remove a test-owned linked-worktree directory before unregistering it.
- **Fix:** Tests resolve created temp parents with `realpath`, and the linked-worktree control unregisters its exact target before removing its exact parent.
- **Files modified:** `test/threadline/clean_checkout_contract_test.exs`.
- **Commit:** `6f35208b`.

**3. [Rule 3 - Blocking] Reconciled Phase 199 roadmap progress after the canonical handler declined the legacy layout**

- **Found during:** Sequential state synchronization after the SUMMARY commit.
- **Issue:** `roadmap.update-plan-progress 199` counted 14 plans and 11 summaries but returned `missing_phase_details`, leaving Plan 11 unchecked and the progress row at `10/14`.
- **Fix:** Checked only `199-11-PLAN.md` and advanced the Phase 199 progress row to `11/14 In Progress`, matching the handler's live counts while leaving the remaining three plans unchecked.
- **Files modified:** `.planning/ROADMAP.md`.
- **Verification:** The Plan 11 checklist entry is checked, the progress row reads `11/14`, and Plans 08, 13, and 14 remain unchecked.

---

**Total deviations:** 3 auto-fixed (2 tooling/layout blockers, 1 cleanup-test correctness issue).
**Impact on plan:** Both changes preserve the specified security boundary and make the adversarial proof valid on the active platform.

## TDD Gate Compliance

- **Task 1 RED:** `25d2b58b`; the named cleanup contract failed because `bin/safe-temp-tree` did not exist. The persisted Node TAP wrapper returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Task 1 GREEN:** `6f35208b`; all five then-current tests passed, followed by the auto-mode tracer feedback rerun at 5/5.
- **Task 2 RED:** `c04265f7`; the named committed-checkout assertion failed because `bin/verify-clean-checkout` did not exist. The persisted Node TAP wrapper returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Task 2 GREEN:** `dc21bc8d`; the complete focused suite passed 7/7, and the standalone verifier proved exact SHA `dc21bc8d209b8fffbbd115c024594ec1be8a6529` clean.
- **REFACTOR:** No separate refactor commit was needed; both GREEN implementations remained direct and test-driven.

## Issues Encountered

- `mix deps.get --check-locked` completed and left the clone clean, but Hex reported pre-existing advisories for locked `decimal`, `hackney`, `phoenix`, `phoenix_live_view`, `plug`, and `postgrex` versions. Dependency selection is outside this plan; the finding is recorded in `deferred-items.md`.
- The checkout has no active asdf selection because `.tool-versions` intentionally remains operator-local and trackable. Verification used command-scoped Elixir `1.19.5-otp-27` and Erlang `27.3.4.15`, matching Plan 199-10's execution posture without modifying caller config.

## Known Stubs

None. The empty-list equality in the forced-failure assertion is a non-vacuity check that no verifier temp tree remains, not a UI/data stub.

## User Setup Required

None.

## Next Phase Readiness

- DECOUPLE-05 is now proven from committed history rather than the maintainer's dirty or ignored working state.
- Later scripts can source `bin/safe-temp-tree` instead of implementing recursive cleanup independently.
- Dependency advisories remain explicitly deferred for compatibility-aware lockfile remediation.

## Self-Check: PASSED

- Both executable artifacts and the expanded contract test exist; each script passes `bash -n`.
- Commits `25d2b58b`, `6f35208b`, `c04265f7`, and `dc21bc8d` resolve as commit objects in RED-before-GREEN order for both tasks.
- The final focused suite passed 7 tests with zero failures, and the standalone committed-HEAD verifier reported all four success markers before safely removing its clone child.
- `git diff --check` passes, the worktree registry contains only the caller checkout after verification, and no plan-owned stub or skipped test remains.
