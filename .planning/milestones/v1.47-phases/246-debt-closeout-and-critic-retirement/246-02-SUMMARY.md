---
phase: 246-debt-closeout-and-critic-retirement
plan: 02
subsystem: maintainer-tooling
status: complete
tags: [critic-retirement, dialyzer, npm, doc-contract, removal-slice]
requires:
  - phase: 246-01
    provides: close-check script (tools/verify-phase.sh) with the ui_critic_retirement allowlist entry
provides:
  - "C1 (Removal-Slice: C1): Elixir critic-trust tooling gone; live Dialyzer slice proof on query-storage"
  - "C2 (Removal-Slice: C2): TypeScript critic runner and its 9 npm packages gone; CONTRIBUTING Retired pointer under a doc contract"
affects: [246-03, 246-04, 246-07]
tech-stack:
  added: []
  patterns:
    - "Removal slice = one green chore: commit carrying every reference edit, with a Removal-Slice trailer"
    - "Partition rows dropped by path from the staged deletions, never by line number"
key-files:
  created:
    - test/threadline/ui_critic_retirement_doc_contract_test.exs
  modified:
    - mix.exs
    - guides/configuration-and-commands.md
    - CONTRIBUTING.md
    - test/threadline/dialyzer_slice_contract_test.exs
    - test/threadline/dialyzer_ignore_contract_test.exs
    - test/fixtures/dialyzer/README.md
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
    - test/threadline/layer_boundary_contract_test.exs
    - test/partition_weights.txt
    - examples/threadline_phoenix/e2e/package.json
    - examples/threadline_phoenix/e2e/package-lock.json
    - examples/threadline_phoenix/e2e/support/operator-surface-paths.ts
    - examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts
decisions:
  - "Dialyzer out-of-bound control path is lib/threadline/retention.ex (in no slice fixture); the unrecorded-live-warning control uses lib/threadline/query.ex"
  - "Dialyzer ignore contract keeps sealed_run.warning_count == 40 and derives the expected id set W03, W04, W06-W40 from one helper"
  - "Retained adapter functions (route scorecard readers, reviewDiffCommand) keep adapter-only tests after their critic-runner tests left"
metrics:
  duration: "about 55 min"
  completed: 2026-10-25
actuals:
  tokens: 46000
  tasks: 2
  commits: 2
plan_head_before: 614cb1fdf2774d53c4f127de0a9f806ff270b1ed
plan_head_after: cbb804a6186b15a0a6ede315fe8f2d37001a4ee2
---

# Phase 246 Plan 02: Critic removal slices C1 and C2 Summary

The Elixir critic-trust tooling (C1) and the TypeScript critic runner (C2) are gone, in two contiguous green `chore:` commits. The live Dialyzer slice proof now runs against `query-storage` with its controls swapped. The e2e lock drops exactly 9 packages. CONTRIBUTING's runbook is now a contract-guarded pointer to `archive/ui-critic-loop`.

## Commits

| Slice | Commit | Subject | Size |
|---|---|---|---|
| C1 | 4b2c3f89 | chore: retire critic-trust tooling and its Dialyzer slice | 22 files, +73 / -3277 |
| C2 | cbb804a6 | chore: retire the TypeScript critic runner | 34 files, +96 / -8352 |

Both carry `Removal-Slice: C1` or `Removal-Slice: C2`. Neither touches `.planning/`. Neither contains a non-critic hunk.

## Verification (measured)

- C1, before commit: `mix compile --warnings-as-errors`, `mix verify.format` and the five targeted contracts passed (97 tests, 0 failures). The runbook doc contract also passed. `mix verify.dialyzer_slice` passed, and `bin/verify-dialyzer-slice --fixture …/query-storage.json` printed `verified slice query-storage: 10/40 sealed warnings; 5 authorized origins; 0 live warnings`. `mix verify.credo` found no issues. Full gate `mix verify.test` on an ephemeral postgres:16: `32 properties, 3376 tests, 0 failures, 3 excluded`.
- C2, before commit: the new doc contract failed 3 of 4 tests against the unedited CONTRIBUTING (RED), then passed. `npm run test:unit`: 14 tests, 14 pass, 0 fail. The targeted contracts passed: ui_critic_retirement, browser_journey_evidence (`playwright test --list`), playwright_fail_fast and public_surface (55 tests, 0 failures). `mix verify.credo` was clean. Full gate `mix verify.test`: `32 properties, 3370 tests, 0 failures, 3 excluded`.
- Lock diff, checked against HEAD's lock: 9 keys removed (`@anthropic-ai/sdk`, `@babel/runtime`, `@stablelib/base64`, `fast-sha256`, `json-schema-to-ts`, `standardwebhooks`, `ts-algebra`, `typescript`, `zod`), 0 added, no surviving entry changed, `lockfileVersion` 3. `npm ci --ignore-scripts` installed cleanly.
- Partition diffs are exact by path. C1 removed the 4 rows of its deleted tests and added none. C2 removed its 3 rows and added only `+3 test/threadline/ui_critic_retirement_doc_contract_test.exs`, in byte-sorted position (`LC_ALL=C sort -c` passes).
- The gate container (labels `dev.threadline.kind=gate-db`, `dev.threadline.plan=246-02`) was removed. `docker ps -a` shows 0 for both labels.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] C1 had to edit CONTRIBUTING's critic section, not only :890**
- **Found during:** Task 1
- **Issue:** `public_surface_contract_test.exs` checks every `mix` alias that CONTRIBUTING mentions. Once the aliases were deleted, it failed: `unknown public references: aliases: ["verify.ui_critique", "verify.critic_trust"]`. The plan defers the CONTRIBUTING section to C2.
- **Fix:** C1 removed only the deleted-alias mentions inside the section that C2 then deletes, and renamed the heading to `## Local-only critic (critic:score)`. The C2 slice boundary and the runbook doc contract stayed intact until C2. The new doc contract refutes the `## Local-only critic` prefix, so both heading spellings are covered.
- **Commit:** 4b2c3f89

**2. [Rule 1 - Bug] Dialyzer ignore contract used W01 (critic-tooling) as its irreducible/fixed-warning probe**
- **Found during:** Task 1
- **Fix:** Those probes now use W03, a query-storage warning. The plan named only the W05 references in the slice contract.
- **Commit:** 4b2c3f89

**3. [Rule 2 - Coverage] Retained adapter functions kept adapter-level tests**
- **Found during:** Task 2
- **Issue:** Deleting the critic-runner tests (the route score/gate test and the score/cache writer test) would have left `routeScorecardCellIds`, `routeCellMatchesPage`, `readRouteScorecard`, `routeScorecardPath` and `reviewDiffCommand` with no test.
- **Fix:** Two small adapter-only tests now cover those functions and use no critic code. The nested-cwd check moved from `e2e/critic` to `e2e/support`.
- **Commit:** cbb804a6

**4. [Gate mechanics] `git diff --quiet` scoped to exclude `.planning/STATE.md`**
- The orchestrator's unstaged `.planning/STATE.md` edit was already present when this plan started. This plan must not touch that file. The gate therefore ran `git diff --quiet -- . ':!.planning/STATE.md'`. Every slice file was staged when each gate ran.

**5. [Plan check imprecision] doc-contract count**
- `ls test/threadline/*doc_contract_test.exs | wc -l` prints 30, not 37, both at HEAD before C2 and after it. The canonical derivation in `bin/verify-bump-rehearsal` (`find test … doc_contract|readme_contract`) prints 37 before and after C2. The count is unchanged, as intended.

## Known Stubs

None.

## Threat Flags

None. The only surface change is removal. The release_artifact contract passed at both commits, and every exclude pattern left in the same commit as the files it excluded.

## TDD Gate Compliance

Task 2: RED observed (`4 tests, 3 failures` against the unedited CONTRIBUTING), then GREEN after the edit. Both steps landed in the single C2 commit, as this plan's one-commit-per-slice rule requires.

## Self-Check: PASSED

- FOUND commits 4b2c3f89, cbb804a6 (ancestors of HEAD); 2 commits measured from plan_head_before.
- FOUND test/threadline/ui_critic_retirement_doc_contract_test.exs, examples/threadline_phoenix/e2e/package.json, test/threadline/dialyzer_slice_contract_test.exs.
- No tracked file remains under any deleted critic path.
