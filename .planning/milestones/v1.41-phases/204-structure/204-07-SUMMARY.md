---
phase: 204-structure
plan: 07
subsystem: core-domain
tags: [refactor, credo, structural-register, nesting, cyclomatic-complexity, critic-trust, mix-tasks]

requires:
  - phase: 204-structure
    provides: "204-04 drained four register sites (register 38 at plan base); 204-06 UI split finished, so this serial wave had the tree to itself"
provides:
  - "All 15 non-surface lib register sites drained across 14 files (change_diff, audit, evidence, retention/policy, policy/redaction_presenter, export/orchestrator, export/cleanup_task, critic_trust/{krippendorff_alpha x2, rank_metrics, measure}, mix tasks critic.measure, threadline.export, threadline.install, threadline.verify_coverage)"
  - "Credo register lowered 38 -> 23 (Nesting 25 -> 17, CyclomaticComplexity 13 -> 6), @ceiling 23, exact at every commit"
  - "No `Structural debt:` line remains in lib/ outside lib/threadline/operator_surface/"
affects: [204-08, 204-09, 204-10, 204-11, 204-15, credo-config-contract, STRUCT-07]

actuals:
  tokens: 9900     # chars/4 over the realized diff c4de8a2a..df6d1ba8 (39547 chars)
  tasks: 3
  commits: 14      # MEASURED: git rev-list --count c4de8a2a..HEAD before the SUMMARY commit
plan_head_before: c4de8a2a45caa252cffaf1b05b8ffd066694739f

tech-stack:
  added: []
  patterns:
    - "Transaction/checkout fn bodies extracted to a defp that is still called inside the same fn (audit transaction_body/3, cleanup_task locked_cleanup/2), so rollback and connection scope are unchanged"
    - "Multi-clause helpers carry a comment saying clause order is the original branch order when first-match precedence matters (evidence normalize_subject!/1, retention window_seconds!/3)"
    - "Numeric helpers move whole expressions verbatim, including the trailing weight factor, so no arithmetic is reassociated (krippendorff expected_term/5)"

key-files:
  created: []
  modified:
    - lib/threadline/change_diff.ex
    - lib/threadline/audit.ex
    - lib/threadline/evidence.ex
    - lib/threadline/retention/policy.ex
    - lib/threadline/policy/redaction_presenter.ex
    - lib/threadline/export/orchestrator.ex
    - lib/threadline/export/cleanup_task.ex
    - lib/threadline/critic_trust/krippendorff_alpha.ex
    - lib/threadline/critic_trust/rank_metrics.ex
    - lib/threadline/critic_trust/measure.ex
    - lib/mix/tasks/critic.measure.ex
    - lib/mix/tasks/threadline.export.ex
    - lib/mix/tasks/threadline.install.ex
    - lib/mix/tasks/threadline.verify_coverage.ex
    - test/threadline/credo_config_contract_test.exs

key-decisions:
  - "The plan's `@ceiling 37` after the tracer assumed a register of 42 - 4 - 1. The live register at plan base was 38, so the tracer left 37, which matches."
  - "After a disable is removed, Credo can report a second, deeper node that the disable had been hiding. In redaction_presenter the reduce_while `with` was also depth 3, so it was extracted too (parse_mask_pair/2) in the same commit. The fix stays one site in the register."
  - "measure_lens/4 steps run in the original order because alpha_and_ci/1 draws from the seeded bootstrap RNG. Reordering them would change the CI values."
  - "No per-site fallback was needed. All 15 sites were fixed in place."

requirements-completed: []
requirements-advanced: [STRUCT-07]  # still open: 23 register sites remain (operator_surface lib + test), drained by later 204 plans

coverage:
  - id: D1
    description: "change_diff.ex primary_map/2 flattened (tracer); register 38 -> 37"
    requirement: STRUCT-07
    verification:
      - kind: unit
        ref: "test/threadline/change_diff_test.exs + test/threadline/credo_config_contract_test.exs"
        status: pass
      - kind: other
        ref: "mix credo --strict lib/threadline/change_diff.ex"
        status: pass
    human_judgment: false
  - id: D2
    description: "Six core-domain sites (audit, evidence, retention/policy, redaction_presenter, export orchestrator, cleanup_task) flattened with identical outcomes and process/transaction boundaries"
    requirement: STRUCT-07
    verification:
      - kind: integration
        ref: "mix test test/threadline/export test/threadline/retention test/threadline/policy test/threadline/evidence_test.exs test/threadline/audit_transaction_test.exs test/threadline/storage_schema_integration_test.exs test/threadline/credo_config_contract_test.exs (82 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "grep -oE 'Task\\.|spawn|Repo\\.transaction|transaction\\(|GenServer\\.|send\\(' before/after on orchestrator.ex and cleanup_task.ex (identical)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Critic-trust and Mix task sites (8 sites, 7 files) flattened with arithmetic, RNG order, parsing, exit behavior, and output unchanged"
    requirement: STRUCT-07
    verification:
      - kind: unit
        ref: "mix test test/threadline/critic_trust test/threadline/operator_surface/critic_trust_test.exs test/threadline/dialyzer_slice_contract_test.exs test/mix test/threadline/credo_config_contract_test.exs (94 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "MIX_ENV=dev mix verify.dialyzer (Total errors: 0)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Whole-repo gates after the plan: full suite and strict Credo"
    requirement: STRUCT-07
    verification:
      - kind: integration
        ref: "DB_PORT=5433 mix test (1769 tests, 0 failures, 1 excluded)"
        status: pass
      - kind: other
        ref: "mix credo --strict (exit 0, no issues)"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-09-23
status: complete
---

# Phase 204 Plan 07: Core-domain, critic-trust, and Mix-task register drain Summary

**Drained all 15 non-surface lib Credo register sites with extracted defps and multi-clause helpers. The register drops from 38 to 23, and there is no behavior, arithmetic, RNG-order, or process-boundary change.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-09-23T22:19:17Z
- **Completed:** 2026-09-23T22:31:10Z
- **Tasks:** 3
- **Files modified:** 15 (14 lib + the credo register contract)

## Accomplishments

- 15 sites fixed in place, one file per commit. The register contract was lowered in the same commit each time, so `@register` stayed exact at every commit.
- Register after the plan: **Nesting 17 + CyclomaticComplexity 6 = 23**, `@ceiling 23`, `@historical_max 46` unchanged. Credo thresholds are unchanged (max_nesting 2, max_complexity 9). No other suppression form was used.
- `grep -rc 'Structural debt:' lib | awk -F: '$2 > 0' | grep -v 'operator_surface/'` prints nothing.

## Per-site table

| # | File | Function | Check | Technique | Commit |
|---|------|----------|-------|-----------|--------|
| 1 | lib/threadline/change_diff.ex | primary_map/2 | CyclomaticComplexity (11) | multi-clause `normalize_op!/1` + `field_changes/3` | 42fd6ac9 |
| 2 | lib/threadline/audit.ex | transaction/3 | Nesting | extracted `transaction_body/3`, still called inside the `repo.transaction` fn | 3d07ab27 |
| 3 | lib/threadline/evidence.ex | validate_subject!/1 | CyclomaticComplexity (10) | multi-clause `normalize_subject!/1`, original clause order | 30fc54c0 |
| 4 | lib/threadline/retention/policy.ex | resolve!/1 | CyclomaticComplexity (33) | multi-clause `boolean_opt!/2` + `window_seconds!/3` (guards in the original check order) | 53230928 |
| 5 | lib/threadline/policy/redaction_presenter.ex | parse_mask_fragment/1 | Nesting | extracted `single_placeholder_mask/1` + `parse_mask_pair/2` | 04606aad |
| 6 | lib/threadline/export/orchestrator.ex | run/2 | CyclomaticComplexity (12) | split into load (`run/2`), stream (`run_job/3`, `write_temp_csv/3`), persist (multi-clause `handle_transaction_result/4`) | 85cc7d01 |
| 7 | lib/threadline/export/cleanup_task.ex | handle_info(:run_cleanup, _) | Nesting | extracted `locked_cleanup/2`, still inside `repo.checkout` fn | b2c7709d |
| 8 | lib/threadline/critic_trust/krippendorff_alpha.ex | compute/1 | Nesting | extracted `add_coincidence/2` (reduce body verbatim) | c5bf57ef |
| 9 | lib/threadline/critic_trust/krippendorff_alpha.ex | weighted_sum/5 | Nesting | extracted `expected_term/5` (both expressions verbatim incl. `* w`) | c5bf57ef |
| 10 | lib/threadline/critic_trust/rank_metrics.ex | auc/1 | Nesting | extracted `add_pairwise_win/3` (cond verbatim) | 0fc91048 |
| 11 | lib/threadline/critic_trust/measure.ex | measure_lens/4 | CyclomaticComplexity (18) | per-metric defps `lens_single_item?/2`, `ok_or_nil/1`, `raw_agreement/2`, `lens_model_id/1`, `validated?/4` | d55b55e1 |
| 12 | lib/mix/tasks/critic.measure.ex | valid_adjudication?/4 | CyclomaticComplexity (13) | multi-clause `adjudication_source/3` + `adjudication_source_consistent?/4` + `adjudicated_margin_valid?/3` | db9f172b |
| 13 | lib/mix/tasks/threadline.export.ex | run/1 | CyclomaticComplexity (13) | `parse_argv/1`, `dry_run/2`, `write_export/3`, `export_format!/1`, multi-clause `json_format_kw!/1` + `export_data/4` | c2770b58 |
| 14 | lib/mix/tasks/threadline.install.ex | migrations_path/0 | Nesting | extracted `repo_migrations_path/1` (still under the rescue) | d00dd4f6 |
| 15 | lib/mix/tasks/threadline.verify_coverage.ex | resolve_expected_tables!/0 | Nesting | multi-clause `expected_table_name!/1` | df6d1ba8 |

## Concurrency edge: primitive counts (plan base vs after)

| File | Base | After |
|------|------|-------|
| lib/threadline/export/orchestrator.ex | `transaction(` 1 | `transaction(` 1 |
| lib/threadline/export/cleanup_task.ex | `GenServer.` 1, `send(` 1 | `GenServer.` 1, `send(` 1 |

Neither file has any `Task.`, `spawn`, or `Repo.transaction`, before or after.

## Task Commits

1. **Task 1: Tracer, change_diff.ex**: `42fd6ac9` (refactor). Tracer verify re-run green, then expanded.
2. **Task 2: Core-domain sites**: `3d07ab27`, `30fc54c0`, `53230928`, `04606aad`, `85cc7d01`, `b2c7709d` (refactor)
3. **Task 3: Critic-trust and Mix tasks**: `c5bf57ef`, `0fc91048`, `d55b55e1`, `db9f172b`, `c2770b58`, `d00dd4f6`, `df6d1ba8` (refactor)

## Files Created/Modified

- The 14 lib files in the per-site table: private helpers extracted, public APIs unchanged.
- `test/threadline/credo_config_contract_test.exs`: `@register` and `@ceiling` lowered once per commit, 38 -> 23.

## Decisions Made

See key-decisions in the frontmatter. In short: the tracer ceiling matched the live register (37). One hidden depth-3 node surfaced in redaction_presenter and was fixed in the same commit. The measure_lens step order was kept for RNG determinism. No per-site fallback was needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] A second depth-3 node was hidden behind the redaction_presenter disable**
- **Found during:** Task 2 (redaction_presenter.ex)
- **Issue:** After the placeholder case was extracted, Credo reported the reduce_while `with` at depth 3 in the same function.
- **Fix:** Extracted the reduce fn as `parse_mask_pair/2` (body verbatim).
- **Files modified:** lib/threadline/policy/redaction_presenter.ex
- **Verification:** `mix credo --strict` on the file is clean, and the policy + redaction live tests pass (80 tests).
- **Committed in:** 04606aad

**2. [Rule 3 - Blocking] Clause grouping warning in critic.measure.ex**
- **Found during:** Task 3 (critic.measure.ex)
- **Issue:** New helpers had been inserted between the two `valid_adjudication?/4` clauses, which `--warnings-as-errors` rejects.
- **Fix:** Moved the fallback clause back next to its sibling.
- **Committed in:** db9f172b

**3. [Verify-path substitution] Task test paths**
- Two paths the plan names do not exist: test/threadline/operator_surface/critic_trust_test.exs does exist, but `test/mix` holds only `tasks/threadline/export_test.exs` plus evidence/incident tests, and there is no dedicated install task test. The substitutes were each module's real test files from `grep -rl '<Module>' test`, run in full: 319 tests for the export task and 181 for verify_coverage. The full suite at the end also covers them.
- Early in the run, zsh passed one grep-built path list as a single string, so `mix test` skipped those files and only the explicit paths ran. Each affected file set was then re-run with explicit paths, and the final full suite ran 1769 tests with 0 failures.

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking), plus 1 verify-path note.
**Impact on plan:** None on scope. The fixes stayed inside the plan's files.

## Issues Encountered

- No lib file in this plan renders operator output, so the D-00b browser lane (`mix verify.example_browser`) was not run. No UI or CSS file changed.

## User Setup Required

None. No external service configuration is required.

## Next Phase Readiness

- 23 register sites remain: operator_surface lib and test/support/test contract files, owned by later 204 plans. The register contract is exact at 23.
- `mix credo --strict` exits 0, the full suite has 0 failures, and `verify.dialyzer` reports 0 errors.

---
*Phase: 204-structure*
*Completed: 2026-09-23*

## Self-Check: PASSED

- All 15 files listed in key-files.modified exist.
- All 14 task commits (42fd6ac9..df6d1ba8) are present in `git log`.
- Acceptance greps: 0 `Structural debt:` in every plan file, and no non-surface lib site remains.
- The concurrency counts match.
