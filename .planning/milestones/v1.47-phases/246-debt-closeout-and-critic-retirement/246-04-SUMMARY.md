---
phase: 246-debt-closeout-and-critic-retirement
plan: 04
subsystem: operator-surface-fixtures-and-stress-lab
status: complete
tags: [critic-retirement, removal-slice, fixture-corpus, design-system-ledger, stress-lab]
requires:
  - phase: 246-03
    provides: "C3a/C3b removal slices (9ea29dc4, 1258c014)"
provides:
  - "C4 (Removal-Slice: C4): refute twins, graded ladder, four fixture dirs, ledger prune, one-line manifest and the rewritten fixture/ledger contracts"
  - "C5 (Removal-Slice: C5): residual live references reworded; D-09 close check clean"
  - "Ordered list of all six removal-slice SHAs for the 246-07 landing hand-off"
affects: [246-05, 246-06, 246-07]
tech-stack:
  added: []
  patterns:
    - "Manifest regenerated from git index blobs (git show :path), asserting index == working tree per file, after staging the deletions"
    - "Single-entry manifest controls: path-set mismatch proven by appending an untracked synthetic row, not by dropping one"
key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/stress_fixtures.ex
    - lib/threadline/operator_surface/live/stress_live.ex
    - lib/threadline/operator_surface/live/stress_live/sections.ex
    - test/fixtures/operator_surface/design-system-ledger.json
    - test/fixtures/operator_surface/manifest.sha256
    - test/fixtures/operator_surface/README.md
    - test/support/operator_surface_fixtures.ex
    - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
    - test/threadline/operator_surface/rendered_output_contract_test.exs
    - test/threadline/operator_surface/stress_ledger_test.exs
    - test/threadline/operator_surface/stress_fixtures_test.exs
    - test/threadline/operator_surface/stress_router_test.exs
    - test/threadline/source_size_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
    - DESIGN-SYSTEM.md
    - CONTRIBUTING.md
    - test/threadline/ci_topology_contract_test.exs
    - test/threadline/ci_workflow_parity_contract_test.exs
    - .planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh
decisions:
  - "Ledger ratchet keys kept: ratchet.{locked_ids,minimum_scores,resets} and ratchet_rule stay because DESIGN-SYSTEM inventory rows still carry Current Score / Target Score columns (e.g. DESIGN-SYSTEM.md `| ID | Status | Current Score | Target Score | ...`) and stress_ledger_test keeps inventory_row/1 plus the 'locked IDs and minimum scores are enforced' test; cube_axes dropped with the Scorecard Cube"
  - "screenshot_allowlist.ci[].semantic_guard_stamp dropped: it recorded the retired mechanical floor and critic panel verdict (verify.mechanical evidence_ref strings) and nothing reads it"
  - "Capture Matrix heading kept, rewritten to the one surviving tier (the 3-entry screenshot allowlist); the scored Tier A/B paragraphs left"
  - "C5 rewording over allowlisting for CONTRIBUTING removed-proof bullets and two test comments; one allowlist entry (partition row naming the already-allowlisted retirement contract) in a separate chore(246-04) planning commit"
metrics:
  duration: "about 60 min"
  completed: 2026-10-25
actuals:
  tokens: 47000
  tasks: 2
  commits: 3
plan_head_before: c2c20837ca7e7c19219d078800b91c43df5f2588
plan_head_after: 33ff76e8835041a7c1fda2aa6ea3e355f9e7ffee
---

# Phase 246 Plan 04: Removal slice C4 (stress stories and fixture corpus) and residual sweep Summary

The refute twins and graded ladder are gone from the stress lab, along with the `scorecards/`, `golden/`, `refute/` and `critic-scores/` fixture dirs. The design-system ledger is pruned to `entries`, `screenshot_allowlist` and the ratchet keys, and the reference manifest now holds one line. All of this landed in one green `chore:` commit (C4). A follow-up C5 commit reworded the last live references, so the D-09 close check is clean. The default suite is green on postgres:16.

## Commits

| Slice | Commit | Subject | Size |
|---|---|---|---|
| C4 | 35243789 | chore: prune critic stress stories and the fixture corpus | 442 files, +100 / -99122 |
| C5 | 61f58954 | chore: remove residual references to the retired UI critic loop | 3 files, +4 / -4 |
| (planning) | 33ff76e8 | chore(246-04): allowlist the partition row naming the retirement contract | 1 file |

Neither removal commit touches `.planning/`.

### All removal-slice SHAs, in order (for the 246-07 landing hand-off)

1. `4b2c3f89f1d596721d36fafab49359d8f2279377` chore: retire critic-trust tooling and its Dialyzer slice (C1)
2. `cbb804a6186b15a0a6ede315fe8f2d37001a4ee2` chore: retire the TypeScript critic runner (C2)
3. `9ea29dc4c3370a08f6fd64cab10db9f4832393a8` chore: retire capture projects and the verify-capture job (C3a)
4. `1258c014c847d39201e809afe9aeafe87a6da7d6` chore: retire the mechanical floor (C3b)
5. `35243789040d234dd721642d52c6aa123483bcd7` chore: prune critic stress stories and the fixture corpus (C4)
6. `61f589541675db4cab1cfb40be01f5843953abbf` chore: remove residual references to the retired UI critic loop (C5)

`git log --format=%B --grep='^Removal-Slice:' | grep -c '^Removal-Slice:'` = 6. None of the six touches a `.planning/` path (checked per commit).

The removal range is not fully contiguous. The `docs(246-02)` and `docs(246-03)` planning commits sit between C2/C3a and C3b/C4. The landing branch should cherry-pick the six SHAs above.

## What C4 changed

- **Stories:** `stress_live/refute.ex` was deleted. These were removed:
  - the refute matrix and its eight twin sections from `sections.ex`, along with the `Refute` alias
  - from `stress_live.ex`: the `graded_stories` merge, `<Sections.refute_matrix>` and `show_refute_matrix?/1`
  - from `stress_fixtures.ex`: `@refute_twin_stories`, `@graded_rungs`, `@graded_ladder`, `@graded_twin_stories`, the refute `assigns_for` clause, `category_for("refute")`, the builders, and `graded_rungs/0`, `graded_stories/0`, `rung_verdict/1` and `rung_to_pole/1`

  `stress_fixtures.ex` went from 980 to 753 lines. The stress lab, stress router, Storybook, the surviving stories and the degraded timeline twin are unchanged.
- **Fixtures:** the four dirs were deleted (436 files). `scorecards!/0`, `golden!/0`, `refute!/0` and `critic_scores!/0` were removed from `test/support/operator_surface_fixtures.ex`.
- **Ledger:** pruned by a one-off scratchpad script (`python3 -I`, idempotent, not committed). It went from 144 to 130 entries, which means the 14 `refute.*` entries are gone. These top-level keys are gone: `critic_trust`, `critic_trust_provenance`, `critic_panel`, `mechanical_auto_apply`, `mechanical_floors` and `cube_axes`. `ratchet.signoffs`, every entry's `scores` and `screenshot_allowlist.ci[].semantic_guard_stamp` are also gone. The surviving top-level keys are `entries`, `provenance`, `ratchet` (`locked_ids`, `minimum_scores`, `resets`), `ratchet_rule`, `required_inventory`, `screenshot_allowlist` and `version`. The source file was confirmed canonical `json.dumps(indent=2, ensure_ascii=False)` before the prune.
- **Manifest:** regenerated from the git index after the deletions and the ledger were staged. The script hashes `git show :path` blobs and asserts that each one equals the working-tree bytes. Result, one line: `55580b67…  design-system-ledger.json`.
- **Contracts:**
  - `stress_ledger_test.exs` was rewritten over the pruned key set. It drops the ratchet-upward, refute-entry, graded-synthetic, Scorecard Cube, per-cell rollup, per-cell ratchet, evidence_ref, cube_axes and signoff-floor tests. It keeps `inventory_row/1` and the locked-IDs/minimum-scores test.
  - `operator_surface_fixture_contract_test.exs` was rewritten. The synthetic corpus is now a ledger plus a `local/` dir. `validate_corpus` checks:
    - that the ledger is tracked
    - JSON shape: non-empty entries with ids, plus a `screenshot_allowlist` map
    - that every allowlisted `ledger_id` resolves to an entry

    The live "manifest == tracked set" test stays non-vacuous with one entry.
  - `rendered_output_contract_test.exs`: the entry count went from 427 to 1. The path-set control now appends an untracked synthetic row.
  - `stress_router_test.exs` and `stress_fixtures_test.exs` were trimmed.
  - The `stress_fixtures.ex` size exception was removed. The "exactly one named exception remains: facade prose" test now holds.
  - `refute.ex` was dropped from the release-artifact maintainer-only list.
- **DESIGN-SYSTEM:** the Ratchet Rule and Scorecard Cube sections are gone (590 → 187 lines). The Capture Matrix now describes only the 3-entry screenshot allowlist. The fixtures README was rewritten for the one-entry corpus.

## Ratchet-key decision (orchestrator resolution 3)

- **Kept:** `ratchet.locked_ids`, `ratchet.minimum_scores`, `ratchet.resets` and `ratchet_rule`.
  - **Evidence:** every surviving DESIGN-SYSTEM inventory table still has the header `| ID | Status | Current Score | Target Score | Kind | Story ID | Fixture Key | Owner Phase |`.
  - `stress_ledger_test.exs` keeps `inventory_row/1`, which renders `current_score` and `target_score`. It also keeps "locked IDs and minimum scores are enforced", which reads `ratchet.locked_ids` and `ratchet.minimum_scores` against `current_score`.
- **Dropped:** `cube_axes`. Its only consumers were the Scorecard Cube projection and the cube_axes/evidence_ref tests, and all of those left.

## Verification (measured)

- **Before committing C4:**
  - `mix compile --warnings-as-errors` and `mix verify.format` passed. `mix verify.credo` found no issues.
  - The targeted set (`test/threadline/operator_surface/`, source_size, release_artifact, public_surface) passed: 918 tests, 0 failures.
  - `mix verify.operator_stress`: 32 passed, 6 skipped, 0 failed, exit 0.
  - `mix verify.example`: 132 tests, 0 failures.
  - Full gate `mix verify.test` on an ephemeral postgres:16 (labels `dev.threadline.kind=gate-db` and `dev.threadline.plan=246-04`), run with no unstaged changes: `32 properties, 3327 tests, 0 failures, 3 excluded`. That is 3336 at C3b minus 9 deleted tests.
- **C4 acceptance:**
  - manifest `wc -l` = 1
  - the four dirs and `refute.ex` are untracked
  - the ledger python check exits 0
  - `stress_fixtures.ex` is 753 lines
  - the `Ratchet Rule|Scorecard Cube` grep count is 0
  - no `.planning/` path, trailer `Removal-Slice: C4`
- The C4 gate container was removed. `docker ps -a --filter label=dev.threadline.plan=246-04 -q` printed nothing before Task 2 started.
- **C5:** `ci_topology`, `ci_workflow_parity`, `community_health` and `ui_critic_retirement_doc` contracts passed (86 tests, 0 failures). Credo was clean.
- **`tools/verify-phase.sh --close`:** prints `ok` for the D-09 live-reference check, the D-09 stale-allowlist check and the partition check. The register, WINDOWS and SEED checks still FAIL, as expected until plans 06-07. `--self-test` passes.
- **Post-removal suite (Task 2 recipe):** a trap-managed postgres:16 with `pg_isready` poll ran `mix verify.test`: `32 properties, 3327 tests, 0 failures, 3 excluded`. The gate-db container count afterwards was 0.
- No `test/partition_weights.txt` row names a deleted file (the close check confirms it). C4 deleted no test files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Stress-router test rendered a deleted refute story**
- **Found during:** Task 1, targeted run
- **Issue:** "authenticated stress route renders …" also loaded `refute.rhythm.doubled-padding.polished` and asserted the refute matrix heading.
- **Fix:** That trailing block was removed. The rest of the test is unchanged.
- **Commit:** 35243789

**2. [Rule 2 - Missing critical] `semantic_guard_stamp` also pruned**
- **Issue:** The three `screenshot_allowlist.ci` items carried `semantic_guard_stamp`, a mechanical-floor and critic-panel verdict (the `verify.mechanical … mechanical_floors[...]` evidence strings 246-03 handed to C4). D-04 did not list it, but nothing reads it.
- **Fix:** Dropped in the same prune script.
- **Commit:** 35243789

**3. [Rule 3 - Blocking] Fixture-contract control needed `git rm --cached --force`**
- **Issue:** The new missing-required-entry control untracks the ledger after it has been rewritten, and git refuses that without `--force` (staged content differs from both HEAD and the working tree).
- **Fix:** Added `--force` to that synthetic-repo command only.
- **Commit:** 35243789

**4. [Gate mechanics] `git diff --quiet` scoped to exclude `.planning/STATE.md`**
- **Issue:** The orchestrator's unstaged STATE.md edit was present throughout.
- **Fix:** The gate used `git diff --quiet -- . ':!.planning/STATE.md'`, as 246-03 did.

**5. [Plan note] RESEARCH Pitfall 5 was not reproduced**
- **Issue:** `validate_reference_manifest(tl(manifest), tracked)` would have returned `:path_set_mismatch`, not `:empty_manifest`, because the empty clause matches only `([], [])`.
- **Fix:** The control was rebuilt as an appended row anyway, as the plan asked. The appended row is the stronger single-entry control.

### C5 hits and how each was resolved

| Hit | Resolution |
|---|---|
| `CONTRIBUTING.md` removed-proof bullets for `verify-mechanical` and `verify-capture` (named the loop and the tag outside the Retired section) | reworded to point at the "Retired" section for the restore tag (C5) |
| `ci_topology_contract_test.exs:676` comment naming the deleted workflow file | reworded (C5) |
| `ci_workflow_parity_contract_test.exs:107` comment naming the deleted workflow file | reworded (C5) |
| `test/partition_weights.txt:262` row naming `ui_critic_retirement_doc_contract_test.exs` | allowlisted as `test/partition_weights.txt:ui_critic_retirement_doc_contract_test`, because the test file itself is already whole-file allowlisted (33ff76e8, planning commit) |

### Left as is (not D-09 hits)

These mention a "Tier A" or "Tier B" that is the phase-178 structural vs. real-engine split, not the critic capture lane, and the refined D-09 pattern does not match them:

- `stress_fixtures.ex:105,108,737`
- `operator-phase-178-uat.spec.ts`
- `operator-stress.spec.ts`
- `ci_workflow_parity_contract_test.exs`

Line 737 is rendered summary copy in the page-path stories. Changing it could move screenshot or stress expectations, so it was not touched.

## Known Stubs

None.

## Threat Flags

None. The only surface change is removal:

- **T-246-10:** the manifest was regenerated from index blobs after the deletions were staged, with a per-file index == working-tree assertion.
- **T-246-11:** `mix verify.operator_stress` and `mix verify.example` are green against the pruned ledger.
- **T-246-12:** the stress exclude patterns are untouched, and `release_artifact_contract_test.exs` passes.

## Self-Check: PASSED

- FOUND: test/fixtures/operator_surface/manifest.sha256 (1 line)
- FOUND: test/fixtures/operator_surface/design-system-ledger.json
- MISSING (intended): lib/threadline/operator_surface/live/stress_live/refute.ex
- FOUND: 35243789, 61f58954, 33ff76e8 are ancestors of HEAD
