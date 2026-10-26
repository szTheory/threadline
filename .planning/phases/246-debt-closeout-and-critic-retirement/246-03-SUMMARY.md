---
phase: 246-debt-closeout-and-critic-retirement
plan: 03
subsystem: ci-and-maintainer-tooling
status: complete
tags: [critic-retirement, ci-topology, browser-full, removal-slice, coverage-cut]
requires:
  - phase: 246-02
    provides: "C1/C2 removal slices (4b2c3f89, cbb804a6)"
provides:
  - "C3a (Removal-Slice: C3a): verify-capture job, verify.capture alias, five capture projects and four capture specs gone; Browser-full runs route-capture only"
  - "C3b (Removal-Slice: C3b): MechanicalChecker, its tests and the verify.mechanical alias gone"
affects: [246-04, 246-07]
tech-stack:
  added: []
  patterns:
    - "Browser-full non-skipped proof: list the lane's own --project flags with playwright test --list and require the render smoke exactly once"
    - "Contract controls that leaned on a deleted live edge are rebuilt as synthetic mutations of copied inputs (canary project, verify.fixture alias)"
key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/browser-full.yml
    - bin/browser-full-projects
    - CONTRIBUTING.md
    - DESIGN-SYSTEM.md
    - mix.exs
    - examples/threadline_phoenix/e2e/playwright.config.ts
    - examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts
    - examples/threadline_phoenix/e2e/support/operator-surface-paths.ts
    - test/threadline/browser_full_projects_contract_test.exs
    - test/threadline/browser_journey_evidence_contract_test.exs
    - test/threadline/ci_topology_contract_test.exs
    - test/threadline/ci_workflow_parity_contract_test.exs
    - test/fixtures/operator_surface/route-inventory.json
    - test/fixtures/operator_surface/source-surface-checklist.json
    - test/partition_weights.txt
decisions:
  - "Renamed route-capture render smoke: `renders every curated operator route at 1280` (the test renders the six curated ROUTES at BREAKPOINTS = [1280]; the suggested 1280/768/375 title would have been false)"
  - "Kept the `capture:pages` npm script: it runs route-capture, and readRouteScorecard's recovery message names it; the other four capture:* scripts left"
  - "C3a and C3b stay two slices; the one coupling found (mechanical_checker_test.exs read the deleted Tier A spec) was resolved by dropping that single source-pin test in C3a"
metrics:
  duration: "about 75 min"
  completed: 2026-10-25
actuals:
  tokens: 59000
  tasks: 3
  commits: 2
plan_head_before: 00048f2e501160f4f79dc76d96edd30cc215f158
plan_head_after: 1258c014c847d39201e809afe9aeafe87a6da7d6
---

# Phase 246 Plan 03: Removal slice C3 (capture lane and mechanical floor) Summary

The `verify-capture` CI job, the Tier A/storybook/graded/refute capture lane and the mechanical floor are gone, in two contiguous green `chore:` commits. ci.yml now has 13 jobs and `ci-required` needs 12. Browser-full runs one project, `route-capture`, and a new contract proves that lane discovers a test it cannot skip. The coverage cut is recorded in ci.yml and in CONTRIBUTING's removed-proofs section.

## Commits

| Slice | Commit | Subject | Size |
|---|---|---|---|
| C3a | 9ea29dc4 | chore: retire capture projects and the verify-capture job | 31 files, +383 / -1959 |
| C3b | 1258c014 | chore: retire the mechanical floor | 13 files, +2 / -1920 |

Both carry `Removal-Slice: C3a` or `Removal-Slice: C3b`. Neither touches `.planning/`. `.github/rulesets/` is unchanged since 872ee30f (D-26).

Renamed render-smoke title: `renders every curated operator route at 1280`. Its full title path is `operator real-route deterministic capture › renders every curated operator route at 1280`.

## Verification (measured)

- Task 1 (staged only): `mix verify.format` passed. `hex_pin_contract_test.exs` passed (22 tests, 0 failures). The precondition and staging checks passed: newest slice C2, nothing outside `.planning/` after it, ci.yml staged, no `.planning/` path staged.
- C3a, before commit:
  - `mix compile --warnings-as-errors` and `mix verify.format` passed.
  - The 12 targeted contracts passed (309 tests, 0 failures).
  - `bin/browser-full-projects --list config` printed `desktop-chromium mobile-chromium route-capture`.
  - `npm run test:unit` passed (14/14).
  - `mix verify.credo` found no issues.
  - Full gate `mix verify.test` on an ephemeral postgres:16: `32 properties, 3373 tests, 0 failures, 3 excluded`.
- `playwright test --list --project=route-capture` discovers the render smoke once (`Total: 13 tests in 1 file`). The other 12 tests are evidence-only.
- C3b, before commit:
  - Compile and format passed.
  - The targeted set (release_artifact, public_surface, ci_topology, `test/threadline/operator_surface/`, source_size) passed: 953 tests, 0 failures.
  - `mix verify.credo` was clean.
  - Full gate: `32 properties, 3336 tests, 0 failures, 3 excluded`.
- Partition diff for C3b removes 2 rows and adds none: `-310 …/mechanical_checker_test.exs` and `-64 …/refute_partition_test.exs`, both deleted in C3b. C3a does not touch `test/partition_weights.txt`. No partition row names a missing file.
- The gate container (labels `dev.threadline.kind=gate-db`, `dev.threadline.plan=246-03`) was removed. `docker ps -a` shows 0 for the plan label. No background shells were left.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] route-inventory.json had to change in C3a**
- **Found during:** Task 2
- **Issue:** `operator_evidence_contract_test.exs` requires the checklist IDs to equal the `route-inventory.json` IDs. Removing the four checklist probes that were anchored in the deleted specs needed the same four IDs removed from the inventory. The render-smoke label was also renamed there.
- **Fix:** Both files were edited by JSON round-trip. Both were already canonical `json.dumps(indent=2)`.
- **Commit:** 9ea29dc4

**2. [Rule 3 - Blocking] mechanical_checker_test.exs read the deleted Tier A spec**
- **Found during:** Task 2
- **Issue:** The test "the Tier A capture spec reads the product surface, not the document" does `File.read!` on `operator-tier-a-capture.spec.ts`. With that spec gone, C3a could not be green.
- **Fix:** That one source-pin test left in C3a, together with the spec it pins. C3b then deletes the whole file. Both slices stay revertable on their own, so they were not merged into one C3 commit.
- **Commit:** 9ea29dc4

**3. [Rule 1 - Bug] `capture:pages` kept**
- **Issue:** The plan said to drop every `capture:*` script. `readRouteScorecard` (`operator-surface-paths.ts`) names `npm run capture:pages` as its recovery command, and that script runs the surviving `route-capture` project. Dropping it would leave a recovery message that points at nothing.
- **Fix:** Only `capture:tier-a`, `capture:storybook`, `capture:refute` and `capture:graded` were dropped.

**4. [Rule 1 - Bug] Planning IDs removed from CONTRIBUTING and DESIGN-SYSTEM**
- **Issue:** `community_health_contract_test.exs` rejects planning IDs (`DEBT-02`) in CONTRIBUTING, and the first full C3a run failed on it.
- **Fix:** Fixed inside the staged slice before the commit. DESIGN-SYSTEM was given the same treatment.

**5. [Rule 1 - Bug] Additional live counts and controls**
- **Issue:** Several counts and controls were not in the RESEARCH site list:
  - the parity contract's setup-beam step count (11 → 10, `ci_workflow_parity_contract_test.exs`)
  - the CONTRIBUTING build-cache sentence ("six job-lanes" → "five")
  - an adapter test that read `operator-graded-capture.spec.ts`
- **Fix:** The count and sentence were corrected. The adapter test became an adapter-only traversal test.

**6. [Rule 1 - Accuracy] Render-smoke title**
- **Issue:** The suggested title `renders every inventoried route at 1280/768/375` is not what the test does.
- **Fix:** The chosen title describes the real behavior (curated routes at 1280).

**7. [Gate mechanics] `git diff --quiet` scoped to exclude `.planning/STATE.md`**
- **Issue:** The orchestrator's unstaged STATE.md edit was present throughout, and this plan must not touch that file.
- **Fix:** The gate used `git diff --quiet -- . ':!.planning/STATE.md'`.

### Left for C4 (by design, not deferred defects)

These still mention the retired capture lane or the mechanical floor. Each sits in a file C4 owns, so it was left alone:

- `test/fixtures/operator_surface/README.md:22-25`
- the `stress_fixtures.ex` comments at :186 and :242
- `refute.ex`
- the ledger's `mechanical_floors` and `verify.mechanical` evidence_ref strings
- DESIGN-SYSTEM's Scorecard Cube and Ratchet Rule

The Capture Matrix heading stays for C4 to decide.

## Known Stubs

None.

## Threat Flags

None. The only surface change is removal:

- **T-246-06:** `verify-capture` was added to `@removed_job_ids`, and the CONTRIBUTING bullet and the `# Removed:` comment were added.
- **T-246-07:** the render smoke was kept, with the exact-set and non-skip proofs.
- **T-246-08:** `@ci_job_ids` and the needs were updated together, and the ruleset is untouched.
- **T-246-09:** the paid-key guard keeps its needle and its non-empty-glob refutation. Only its name and messages were reworded.

## Self-Check: PASSED

- FOUND commits 9ea29dc4 and 1258c014 (ancestors of HEAD). 2 commits measured from plan_head_before.
- FOUND test/threadline/browser_full_projects_contract_test.exs, test/threadline/browser_journey_evidence_contract_test.exs, .github/workflows/ci.yml (`# Removed: verify-capture` x1, `verify-capture:` x0).
- No tracked file remains under the deleted mechanical_checker paths or the four capture specs. The resume note was removed.
