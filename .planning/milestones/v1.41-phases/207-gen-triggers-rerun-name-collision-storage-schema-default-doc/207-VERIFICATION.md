---
phase: 207-gen-triggers-rerun-name-collision-storage-schema-default-doc
verified: 2026-09-25T00:44:32Z
status: passed
score: 16/16 must-haves verified
covered_files:
  - ".planning/phases/207-gen-triggers-rerun-name-collision-storage-schema-default-doc/207-01-PLAN.md"
  - ".planning/phases/207-gen-triggers-rerun-name-collision-storage-schema-default-doc/207-01-SUMMARY.md"
  - ".planning/phases/207-gen-triggers-rerun-name-collision-storage-schema-default-doc/207-02-PLAN.md"
  - ".planning/phases/207-gen-triggers-rerun-name-collision-storage-schema-default-doc/207-02-SUMMARY.md"
  - ".planning/phases/207-gen-triggers-rerun-name-collision-storage-schema-default-doc/207-03-PLAN.md"
  - ".planning/phases/207-gen-triggers-rerun-name-collision-storage-schema-default-doc/207-03-SUMMARY.md"
  - "CHANGELOG.md"
  - "guides/audit-indexing.md"
  - "guides/domain-reference.md"
  - "guides/how-threadline-works.md"
  - "guides/production-checklist.md"
  - "lib/mix/tasks/threadline.gen.triggers.ex"
  - "lib/threadline/capture/trigger_sql.ex"
  - "lib/threadline/mix/migration_version.ex"
  - "lib/threadline/mix/trigger_migration.ex"
  - "test/mix/tasks/threadline/gen_triggers_test.exs"
  - "test/threadline/capture/trigger_rerun_test.exs"
  - "test/threadline/capture/trigger_sql_storage_schema_test.exs"
  - "test/threadline/mix/trigger_migration_test.exs"
  - "test/threadline/storage_schema_test.exs"
covered_digest: "v1:sha256:cae9313e2923877b5e10d7685a67f65d9fa1ea4d962b330f3511f349529140d6"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 207: Trigger Migration Rerun and Storage-Schema Default Docs — Verification Report

**Phase Goal:** Rerunning `mix threadline.gen.triggers` for tables that already have a trigger migration produces a migration Ecto accepts (no duplicate migration name/module), as the drift-remediation guides instruct, with a second-run regression test; and every guide states the real `storage_schema` default (`public`).
**Verified:** 2026-09-25T00:44:32Z
**Status:** passed
**Re-verification:** No (initial verification)
**Requirements:** no formal REQ IDs. Audit items W1 and W2 from `.planning/v1.41-MILESTONE-AUDIT.md`. Plans declare `requirements: [W1]`, `[W1]` and `[W1, W2]`. REQUIREMENTS.md has no W1/W2 entries, which is expected for tech-debt closure. No requirements are orphaned.

## Goal Achievement

### Roadmap-level truths (goal contract)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| G1 | A rerun for the same tables writes a migration with a distinct Ecto name and module | VERIFIED | `TriggerMigration.resolve_name/2` (lib/threadline/mix/trigger_migration.ex) builds the name and the module from one parts list and skips a candidate when either one is taken. It is wired at gen.triggers.ex:176-178. An independent spot check ran the real task 3 times into /tmp, giving `..._v207_posts`, `..._v207_posts_2` and `..._v207_posts_3`. Using Ecto's own parse, the versions were unique and the names were unique. The modules were `ThreadlineTriggersV207Posts`, `...Posts2` and `...Posts3`. |
| G2 | The rerun migration applies (SQL accepted, no "trigger already exists") | VERIFIED | `create_trigger_sql/2` emits `CREATE OR REPLACE TRIGGER` (trigger_sql.ex:145). Spot check: the `up` statements of the 3 generated migrations (default, then `--store-changed-from`, then default) were applied in order with `ON_ERROR_STOP` inside a rolled-back transaction on threadline_test. All applied. The result was one `threadline_audit_v207_posts` trigger on `threadline_capture_changes`, with 0 leftover per-table functions. |
| G3 | A second-run regression test exists and passes | VERIFIED | gen_triggers_test.exs has the `describe "rerun naming"` cases: distinct Ecto name across runs 1-3, distinct module, legacy file, lookalikes. trigger_rerun_test.exs covers the DB tier ("installing the trigger twice succeeds"). The 5 phase test files were re-run: 56 tests, 0 failures. |
| G4 | Every guide states the real `storage_schema` default (`public`) | VERIFIED | `@default "public"` (storage_schema.ex:22). audit-indexing.md:7, production-checklist.md:14, how-threadline-works.md:94 and domain-reference.md:311 now say `public`. A grep over guides/ and README.md finds no remaining "default ... threadline" claim and no "historical footprint" phrasing. The guard in storage_schema_test.exs scans `guides/**/*.md` plus README.md. It has a known-offender positive control and a non-vacuity floor of 3 or more correct claims. |

### Plan must-have truths

| # | Truth (abridged) | Status | Evidence |
|---|------------------|--------|----------|
| 1 | create_trigger/3 emits CREATE OR REPLACE TRIGGER in both modes; trigger name unchanged | VERIFIED | trigger_sql.ex:128-148 uses one shared template for both modes. The name `threadline_audit_<suffix>` is unchanged. |
| 2 | Installing twice succeeds on the real DB | VERIFIED | trigger_rerun_test.exs:46, passing |
| 3 | Moving from default to per_table re-points tgfoid; UPDATE records changed_from | VERIFIED | trigger_rerun_test.exs:53, passing |
| 4 | drop_orphan_function_for_table/2 is non-cascading and removes the orphan | VERIFIED | trigger_sql.ex:113-115 has no CASCADE. Tests at :82, :92 (refuses to cascade) and :105 all pass. |
| 5 | Catalog introspection unchanged; no DDL-text parsing | VERIFIED | The lib diff does not touch the health or policy introspection code. The full suite on HEAD shows only an unrelated temp-dir collision (see below). |
| 6 | RED-before-fix recorded; DB tier uses a scratch table with no sandbox | VERIFIED | Recorded in the SUMMARYs and in REVIEW-FIX (CR-01: 9 tests, 2 failures before the fix). |
| 7 | First-run name and module byte-identical | VERIFIED | gen_triggers_test.exs:167, :177, :186 |
| 8 | Second run gives `_2` with a larger version; third run gives `_3` | VERIFIED | gen_triggers_test.exs:195, plus the independent spot check |
| 9 | One function, one parts list; skip when the name or module is taken; recursive discovery | VERIFIED | `MigrationVersion.existing/1` uses a `**/*.exs` wildcard with Ecto's integer-prefix parse. `resolve_name` never parses an ordinal back out of an existing name. |
| 10 | Lookalikes and legacy files never collide | VERIFIED | gen_triggers_test.exs:233, :249 |
| 11 | Host files are only read as text and never compiled | VERIFIED | `scan/1` uses only File.read plus Regex, with no Code.eval or compile. A read error is skipped. |
| 12 | Default-mode up puts the orphan drop after the trigger; per-table up has no drop | VERIFIED | gen.triggers.ex:249-256 and `orphan_function_drop/1`. Tests at :288 and :306. |
| 13 | Rerun detection sets the down per table | VERIFIED | `rerun?/2` uses a negative lookahead. `first_run_specs` is at gen.triggers.ex:261. Tests at :358 and :380. The spot check's run-3 `down` contained only the comment. |
| 14 | Rerun rollback comment plus an info line | VERIFIED | `rerun_rollback_comment/1`. The spot check's stdout printed the info line. Test at :394. |
| 15 | Moduledoc updated (OR REPLACE, Rerunning, NOTICE, rollback) | VERIFIED | The moduledoc's `## Rerunning` section. The doc-contract test at :406 passes. |
| 16 | Guides, moduledoc and generated down share the rerun phrases; CHANGELOG entry | VERIFIED | production-checklist.md:45 and domain-reference.md:55 contain "replaces the trigger in place" and "does not restore the earlier capture policy". The tests at :406 and :429 pass. The CHANGELOG includes both quoted errors (per REVIEW-FIX WR-01/WR-03). |

**Score:** 16/16 verified. Four roadmap-level truths are folded into the plan truths (0 behavior-unverified).

### CR-01 logic change: resolved by verifier reasoning (no human item)

REVIEW-FIX flagged the CR-01 fix for a human check. I resolved it from the code and the tests.
- `per_table_function_fits?/1` compares only the function base name (`threadline_capture_changes_<suffix>`) with the 63-byte limit. That is correct, because the schema is a separate identifier and is not subject to the same truncation.
- The orphan drop is emitted only when the name fits. A fitting name cannot be truncated, so it cannot alias another table's function. That removes both failure modes in the review: aborting on a live dependent function, and dropping a sibling's function created earlier in the same migration.
- When the name does not fit, skipping the drop at worst leaves a harmless, non-capturing legacy function. The generator already refuses to create per-table functions with names that are too long (`quote_ident` raises), so no new orphan can be created.
- The 4 regression tests in trigger_rerun_test.exs:123-211 apply the real generated `up` against PostgreSQL, and they pass.

The fix is correct and bounded. The residual long-name per-table collision is recorded as deferred, needs a public-behaviour decision, and is out of scope for W1.

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| lib/threadline/capture/trigger_sql.ex | VERIFIED | Contains CREATE OR REPLACE TRIGGER, `drop_orphan_function_for_table` and `per_table_function_fits?` |
| lib/threadline/mix/trigger_migration.ex | VERIFIED | Has `@moduledoc false` and scan/resolve_name/rerun?; used by the gen.triggers task |
| lib/threadline/mix/migration_version.ex | VERIFIED | Has `def existing(`; used by `next/3` and `TriggerMigration.scan/1` |
| lib/mix/tasks/threadline.gen.triggers.ex | VERIFIED | Calls `TriggerMigration.resolve_name(`, emits the orphan drop and the rollback comment |
| test/mix/tasks/threadline/gen_triggers_test.exs | VERIFIED | Rerun naming, up/down body and doc-contract cases |
| test/threadline/mix/trigger_migration_test.exs | VERIFIED | Unit tests |
| test/threadline/capture/trigger_rerun_test.exs | VERIFIED | DB tier plus CR-01 cases |
| test/threadline/capture/trigger_sql_storage_schema_test.exs | VERIFIED | Pins the OR REPLACE text |
| test/threadline/storage_schema_test.exs | VERIFIED | Guard over guides and README |
| 4 guides + CHANGELOG.md | VERIFIED | See G4 and truth 16 |

### Key Link Verification

| From | To | Status |
|------|----|--------|
| gen.triggers.ex | TriggerMigration.resolve_name/2 | WIRED (line 177) |
| trigger_migration.ex | MigrationVersion.existing/1 | WIRED (scan/1) |
| gen.triggers up body | TriggerSQL.drop_orphan_function_for_table/2 | WIRED (orphan_function_drop/1) |
| create_trigger/3 | create_trigger_sql/2 | WIRED (both modes) |
| storage_schema_test | StorageSchema.get([]) | WIRED |
| guides rerun text | generated down comment | WIRED (tests at :406 and :429) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase test files | `mix test` on the 5 phase files | 56 tests, 0 failures | PASS |
| 3 consecutive gen.triggers runs give unique Ecto versions, names and modules | `mix run` script in /tmp | `_posts`, `_posts_2`, `_posts_3`; unique=true/true | PASS |
| Generated ups apply in sequence on real PG | psql `ON_ERROR_STOP`, BEGIN…ROLLBACK | 1 trigger on the global function, 0 leftover functions | PASS |
| Rerun down keeps capture on | inspect the `_3` down | comment only, no DROP | PASS |

### Probe Execution

None. The phase declares no `scripts/*/tests/probe-*.sh`. The one-shot psql probe from 207-03 was reproduced independently above.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| (all changed files) | TBD/FIXME/XXX/TODO/HACK | none | The added lines in the diff `4454661b..HEAD` contain none of these markers. |
| git history | 4 review-fix commits use `fix(207): CR-01/WR-0x ...` subjects (35ec16b8, 917418ff, 292c0173, 660e2ad3) | Warning (release hygiene) | The plan's D-13 truth applies to the plan commits, which use `fix(gen.triggers): ...` correctly. These review-fix subjects are releasable and would leak phase and finding IDs into release-please notes. This is the same class as audit W4. Reword or squash when the branch lands. This does not block the goal. |

### Out-of-scope observations

- The full suite on HEAD 55c3d0f5 had 1 failure: clean_checkout_contract_test.exs:276. A temp-dir name collided with a stale directory left by an interrupted run, because `System.unique_integer` restarts in each VM. This is test fragility unrelated to phase 207. The file passes 9/9 after cleanup.
- Deferred by the review: two per-table tables whose suffixes share their first 36 bytes, where the generator raises. This needs a public-behaviour decision and is not part of W1.

### Human Verification Required

None. Per the PROJECT.md constraint, every check was automated or resolved by reading the code.

### Gaps Summary

No gaps. W1 is closed: a rerun gives a distinct Ecto name and module, its SQL applies idempotently on PostgreSQL 14 and later (the published floor), and second- and third-run regression tests exist and pass. W2 is closed: all four wrong default sentences are corrected, and a guard protects the claim across guides and README. One release-hygiene warning: reword or squash the `fix(207): ...` review-fix commit subjects on landing.

---

_Verified: 2026-09-25T00:44:32Z_
_Verifier: Claude (gsd-verifier)_
