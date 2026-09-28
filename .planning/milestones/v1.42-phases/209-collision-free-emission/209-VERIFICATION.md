---
phase: 209-collision-free-emission
verified: 2026-09-25T18:24:50Z
status: passed
score: 4/4 must-haves verified (plus 3/3 requirements satisfied)
covered_files:
  - .planning/REQUIREMENTS.md
  - .planning/phases/209-collision-free-emission/209-01-PLAN.md
  - .planning/phases/209-collision-free-emission/209-01-SUMMARY.md
  - .planning/phases/209-collision-free-emission/209-02-PLAN.md
  - .planning/phases/209-collision-free-emission/209-02-SUMMARY.md
  - .planning/phases/209-collision-free-emission/209-03-PLAN.md
  - .planning/phases/209-collision-free-emission/209-03-SUMMARY.md
  - .planning/phases/209-collision-free-emission/209-04-PLAN.md
  - .planning/phases/209-collision-free-emission/209-04-SUMMARY.md
  - .planning/phases/209-collision-free-emission/209-05-PLAN.md
  - .planning/phases/209-collision-free-emission/209-05-SUMMARY.md
  - .planning/phases/209-collision-free-emission/209-06-PLAN.md
  - .planning/phases/209-collision-free-emission/209-06-SUMMARY.md
  - CHANGELOG.md
  - lib/mix/tasks/threadline.gen.triggers.ex
  - lib/threadline/capture/trigger_sql.ex
  - lib/threadline/mix/trigger_migration.ex
  - priv/ci/notice_guard_canary.exs
  - test/mix/tasks/threadline.incident_test.exs
  - test/mix/tasks/threadline/gen_triggers_test.exs
  - test/support/legacy_trigger_sql.ex
  - test/support/migration_harness.ex
  - test/support/naming_generators.ex
  - test/support/notice_guard.ex
  - test/test_helper.exs
  - test/threadline/capture/collision_free_emission_test.exs
  - test/threadline/capture/legacy_function_upgrade_test.exs
  - test/threadline/capture/legacy_trigger_regeneration_test.exs
  - test/threadline/capture/naming_property_test.exs
  - test/threadline/capture/notice_guard_canary_test.exs
  - test/threadline/capture/notice_guard_test.exs
  - test/threadline/capture/trigger_rerun_test.exs
  - test/threadline/capture/trigger_sql_storage_schema_test.exs
  - test/threadline/mix/trigger_migration_property_test.exs
  - test/threadline/mix/trigger_migration_test.exs
covered_digest: "v1:sha256:78f0529ee1bd37d4823797e0ffa2da559308fa668ac156869ac78526f0494dbc"
behavior_unverified: 0
overrides_applied: 0
deferred:
  - truth: "Health / policy.show flag stale, drifted, shared, duplicate and disabled triggers (incl. tables still on a shared legacy function)"
    addressed_in: "Phase 212"
    evidence: "Phase 212: Detection and Adopter Twins - Health checks flag stale, drifted, shared, duplicate and disabled triggers"
  - truth: "The 'kept ... still use it' WARNING is noisy when billing.invoices is added after public.billing_invoices on a current install"
    addressed_in: "Phase 212"
    evidence: "Deliberately deferred by the orchestrator; current behaviour pinned by legacy_function_upgrade_test.exs 'a project installed on the current release'"
  - truth: "Upgrade guide and CHANGELOG security note for the shared-function fix"
    addressed_in: "Phase 213"
    evidence: "Phase 213: Upgrade Guide and 0.11.0 Release - Adopters can upgrade safely from 0.10.x"
  - truth: "Frozen 0.10.x migrations' down still contains DROP FUNCTION ... CASCADE (adopter-owned, already written)"
    addressed_in: "Phase 213"
    evidence: "Deliberately deferred by the orchestrator to the upgrade guide; generated SQL from this release has no CASCADE"
---

# Phase 209: Collision-Free Emission Verification Report

**Phase Goal:** No audited table can run another table's capture function or redaction rules, and regenerating or dropping one table's capture never damages another's.
**Verified:** 2026-09-25T17:56:50Z
**Status:** passed
**Re-verification:** No (initial verification)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC1 | On real PG, `public.billing_invoices` / `billing.invoices` and two long names sharing 36 bytes each get a distinct per-table function, and each applies only its own `mask`/`exclude` | VERIFIED | `TriggerSQL.per_table_function_name/2` now pipes `Naming.function_name/1` (sole source; no other `threadline_capture_changes_<x>` derivation left in `lib/`). `collision_free_emission_test.exs` generates via `mix threadline.gen.triggers`, applies via `Ecto.Migrator`, asserts `pg_trigger.tgfoid` resolves to `..._billing_invoices` vs `..._billing_invoices_9bba11019407`, distinct hashed names for the 36-byte pair, `function_users` of each = its own table only, and inserted rows show only own-table masking/exclusion. Passed in my run. |
| SC2 | Regenerating over a 0.10.x install (frozen 0.10.x trigger SQL) leaves exactly one Threadline trigger per table; fitting names byte-identical | VERIFIED | `rerun?` rewritten to match the `ON` clause (`{schema, table}`), never the trigger name. `test/support/legacy_trigger_sql.ex` freezes the 0.9.0 / 0.10.0 / 0.10.2 statements (I cross-checked the shapes against `create_trigger_sql` at 7378b75a, 3d148435, ee137e51). `legacy_trigger_regeneration_test.exs` counts `pg_trigger` rows (`threadline_audit_%`) per table after up and after down: exactly one, `tgenabled = 'O'`, with literal expected names (`threadline_audit_regen_nine`, `threadline_audit_regen_s_ten`, ...), in both default and per-table mode. Passed. |
| SC3 | Dropping/rolling back one table's capture leaves every other table's trigger present and enabled; no generated SQL has `CASCADE` on a capture function; a function is dropped only when no trigger references it by `tgfoid` | VERIFIED | `drop_function_if_unused/2` emits the `DO` block that looks up `pg_trigger.tgfoid = fn` and drops (RESTRICT) only if there are no users, otherwise `RAISE WARNING`. `drop_function_for_table/2` lost `CASCADE`; `per_table_function_fits?` / `drop_orphan_function_for_table` removed. `grep -i cascade` across the three changed lib files matches only doc prose. Real PG: rolling back the second of two tables that share a cut trigger name leaves the first `{cut, "O"}` and its function; a hand-pointed foreign trigger keeps the function, with a WARNING. Static: `gen_triggers_test.exs` "no statement cascades and every quoted identifier fits in 63 bytes" covers 16 files (default/per-table x 4 table shapes x first run/rerun, up and down). Passed. |
| SC4 | Any identifier-truncation NOTICE during the suite fails the suite (with a positive control) | VERIFIED | `Threadline.Test.NoticeGuard` is attached in `test_helper.exs` before `Ecto.Migrator.run`. It matches SQLSTATE `42622` from telemetry, and `verify!/1` runs through `ExUnit.after_suite` with a non-zero `System.at_exit` on undrained hits or a detached handler. A `client_min_messages = notice` assertion is present. Positive and negative controls are in `notice_guard_test.exs`. The contract `notice_guard_canary_test.exs` runs `mix test priv/ci/notice_guard_canary.exs`: non-zero exit with the flag, zero without. Both passed in my run, so the canary is proven end to end. |

**Score:** 4/4 truths verified (0 present, behavior-unverified). Every SC is behavior-dependent and has a passing real-PG or contract test that exercises it.

Additional decision-level checks (D-04/D-05/D-06/D-07), all backed by passing tests:
- D-05 owner guard: `legacy_function_upgrade_test.exs` regenerates only the keeper table over a 0.10.x shared function. `Postgrex.Error` has the HINT `mix threadline.gen.triggers --tables billing_invoices,billing.invoices`. The function body is unchanged, both triggers stay on the shared function, the migration is not recorded, and `billing.invoices` keeps its old rules. Moved-first and both-together orders succeed with correct per-table rules.
- D-04 ordering: "every retire block runs after every trigger" (gen_triggers_test).
- D-06 advisory: the "shared capture function advisory" describe (4 tests).
- D-07 rollback comment: "a per-table rerun names the old name it retired and the function it keeps".

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|--------------|----------|
| 1 | Health findings for shared/stale/duplicate triggers | Phase 212 | ROADMAP Phase 212 goal |
| 2 | Noisy "kept" WARNING for billing.invoices after public.billing_invoices (pinned by test) | Phase 212 | Orchestrator deferral; pinned in legacy_function_upgrade_test.exs |
| 3 | Upgrade guide + security note | Phase 213 | ROADMAP Phase 213 goal |
| 4 | Frozen 0.10.x `down` CASCADE hazard | Phase 213 | Orchestrator deferral (upgrade guide) |

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `lib/threadline/capture/trigger_sql.ex` | VERIFIED | `drop_function_if_unused/2`, `function_owner_guard/2`, Naming-sourced per-table names, validated to at most 63 bytes |
| `lib/mix/tasks/threadline.gen.triggers.ex` | VERIFIED | up = functions, triggers, guards, retires; down = first-run-only drop trigger + orphan-safe drop; advisory; moduledoc |
| `lib/threadline/mix/trigger_migration.ex` | VERIFIED | `parse_triggers/1`, `rerun?/2` on the ON clause, `covered_pairs/1` |
| `test/support/notice_guard.ex` + `test_helper.exs` wiring | VERIFIED | attached before migrations; `after_suite` hook |
| `test/support/notice_guard_canary.exs` (planned path) | VERIFIED (relocated) | Moved to `priv/ci/notice_guard_canary.exs` in commit 22913568 to satisfy credo's test-file naming. The contract test uses the new path and passes. `priv/ci` is not in the package `files` list (only `priv/fonts` ships). |
| `test/support/legacy_trigger_sql.ex` | VERIFIED | frozen 0.9 / 0.10.0 / 0.10.2 renderers, independent of current code |
| `test/support/migration_harness.ex` | VERIFIED | real `Ecto.Migrator.up/down`, pg_trigger/tgfoid introspection |
| real-PG tests (collision_free_emission, legacy_function_upgrade, legacy_trigger_regeneration) | VERIFIED | all pass |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| trigger_sql.ex | naming.ex | `per_table_function_name/2` -> `Naming.function_name/1` | WIRED |
| gen.triggers | trigger_sql.ex | `drop_function_if_unused/2`, `function_owner_guard/2` | WIRED |
| gen.triggers | trigger_migration.ex | `rerun?(pair, scan.sources)`, `covered_pairs/1` | WIRED. The plan named `parse_triggers` for the advisory; it is reached through `covered_pairs/1`, so the gsd-tools pattern miss is cosmetic. |
| test_helper.exs | notice_guard.ex | `attach!()` + `ExUnit.after_suite(&verify!/1)` | WIRED |
| notice_guard_canary_test | priv/ci/notice_guard_canary.exs | `System.cmd("mix", ["test", path])` | WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase test set (SC1-SC4, D-05..D-11, properties) | `mix test test/threadline/capture/ test/threadline/mix/ test/mix/tasks/threadline/gen_triggers_test.exs` | exit 0; 9 properties, 181 tests, 0 failures; no "identifier truncation" in output | PASS |
| Canary + structure/skip/changelog/source-size/policy.show contracts | `mix test test/threadline/capture/notice_guard_canary_test.exs test/threadline/zero_skips_contract_test.exs test/threadline/test_structure_contract_test.exs test/threadline/changelog_contract_test.exs test/threadline/source_size_contract_test.exs test/threadline/operator_surface/policy_show_mix_test.exs` | 42 tests, 0 failures | PASS |
| Compile | `mix compile --warnings-as-errors` | clean | PASS |
| Full gate | `mix ci.all` on 22913568 (orchestrator-supplied; not re-run per instruction) | 1975 tests + 9 properties, 0 failures; example 117/0; Dialyzer 0; browser 318 passed / 26 skipped / 0 failed | accepted |

### Probe Execution

Not applicable. The phase declares no `scripts/*/tests/probe-*.sh`.

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| NAME-02 | 209-03, 209-04, 209-06 | SATISFIED | SC1 + D-05 guard tests |
| NAME-03 | 209-02, 209-06 | SATISFIED | SC2 regeneration test, rerun?/property tests |
| NAME-04 | 209-03, 209-06 | SATISFIED | SC3 real-PG + static no-CASCADE matrix |

No orphaned requirements: REQUIREMENTS.md maps only NAME-02/03/04 to Phase 209. The traceability table still reads "Pending" for those three. That is bookkeeping for the orchestrator to flip; it is not a code gap.

### Planning Vocabulary Check

- Lines added by this phase in `lib/`, `test/`, `priv/`, `CHANGELOG.md` (`git diff f4ac6404 HEAD`): **none** (grep for phase numbers, NAME-0x, D-xx, SCn, Wave, W0 returned nothing).
- The whole trees: `lib/`, `priv/`, `CHANGELOG.md` are clean. `test/` has **pre-existing** planning vocabulary from earlier phases, for example `test/test_helper.exs:63` "(Phase 198, D-03)", which was present at f4ac6404, plus `zero_skips_contract_test.exs`, `ci_workflow_parity_contract_test.exs` and `health_test.exs`. Phase 209 introduced none. Informational only.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (all phase-modified files) | - | TBD/FIXME/XXX/TODO/HACK | none found | - |
| test run output | - | `the log level :warn is deprecated` from ecto_sql's migration runner logging the PG WARNING | Info | Upstream ecto_sql noise when the orphan-safe block raises a WARNING. Not a phase defect. |

### Human Verification Required

None. Verification is fully automated per project policy.

### Gaps Summary

No gaps. Every per-table function name is sourced from `Naming.function_name/1`, so two tables cannot share a function. The migrate-time owner guard makes the one remaining sharing path, a 0.10.x shared function regenerated keeper-first, fail atomically. Rerun detection keys on the ON clause and is proven against frozen historical SQL. Every generated function drop is RESTRICT and gated on `tgfoid`. The truncation guard has a canary that proves it fails the suite. Items listed under Deferred are owned by Phases 212 and 213 and do not count against this phase.

---

_Verified: 2026-09-25T17:56:50Z_
_Verifier: Claude (gsd-verifier)_

## Re-verification after code-review fixes

After the first verification, the code review (209-REVIEW.md) found one blocker and two warnings. Each was fixed and tested, so every success criterion still holds, and each one gets stronger:
- `0cd1e0ec`: the owner guard and the drop-if-unused check ignore partition trigger clones (`tgparentid = 0`). A real-PG test with a partitioned table migrates up and down cleanly, with the partition's rows redacted. This strengthens SC1 and SC3.
- `7f42cd34`: generated migrations write SQL longer than 4096 bytes in full. The test uses 40 mask columns and round-trips the SQL.
- `ca4de538`: redaction config is matched by the schema/table pair, and a table listed twice is rejected. This closes an unredacted-capture path, strengthening SC1.

Gate: `mix ci.all` exited 0 on ca4de538:
- suite: 1981 tests and 9 properties, 0 failures;
- example app: 117 tests, 0 failures;
- Dialyzer: 0 errors;
- browser lane: 318 passed, 26 skipped, 0 failed.

Status stays `passed`.
