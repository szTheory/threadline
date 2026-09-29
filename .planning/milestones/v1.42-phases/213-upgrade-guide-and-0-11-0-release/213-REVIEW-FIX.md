---
phase: 213-upgrade-guide-and-0-11-0-release
fixed_at: 2026-09-26T15:30:00Z
review_path: .planning/phases/213-upgrade-guide-and-0-11-0-release/213-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 213: Code Review Fix Report

**Fixed at:** 2026-09-26T15:30:00Z
**Source review:** .planning/phases/213-upgrade-guide-and-0-11-0-release/213-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2 (Critical: 0, Warning: 2)
- Fixed: 2
- Skipped: 0

## Fixed Issues

### WR-01: Shared-function fixture is built from the current TriggerSQL renderer, not a frozen 0.10.2 shape

**Files modified:** `test/support/legacy_trigger_sql.ex`, `test/threadline/upgrade_backfill_test.exs`, `test/threadline/upgrade_rollback_test.exs`
**Commit:** `0fa38e63`
**Applied fix:** Added `Threadline.Test.LegacyTriggerSQL.v0_10_2_install_function_for_table/3`, a byte-for-byte reproduction of v0.10.2's `per_table_install_sql_legacy/3` and `per_table_install_sql_redacted/7` (with their private helpers inlined and renamed to avoid any accidental reuse of current code), taken verbatim from `git show v0.10.2:lib/threadline/capture/trigger_sql.ex`. Supports the same options the release-era function did (`:store_changed_from`, `:exclude`, `:mask`, `:mask_placeholder`, `:except_columns`), with the same "at least one of store_changed_from/exclude/mask" guard the real code raised. Switched both `upgrade_backfill_test.exs`'s and `upgrade_rollback_test.exs`'s shared-capture-function-pair fixture setup from `Threadline.Capture.TriggerSQL.install_function_for_table("billing_invoices", mask: ["secret"])` (the current 0.11 renderer) to `LegacyTriggerSQL.v0_10_2_install_function_for_table(@shared_function, storage, mask: ["secret"])`, matching the doc-comment convention and naming style already used by `v0_10_2_install_function/2` and `v0_10_2_drop_function_for_table/2`. Verified: `mix test test/threadline/upgrade_backfill_test.exs test/threadline/upgrade_rollback_test.exs` — 4 tests, 0 failures.

### WR-02: `CONTRIBUTING.md` release-PR description is stale, left unfixed

**Files modified:** `CONTRIBUTING.md`
**Commit:** `d538f708`
**Applied fix:** Corrected the line-690 sentence (verified against `release-please-config.json`'s `changelog-path: "CHANGELOG-GENERATED.md"` and `CHANGELOG.md`'s own human-owned banner) from "The Release PR bumps `mix.exs`, `CHANGELOG.md`, **and** the adoption-pilot SSOT line together" to "The Release PR bumps `mix.exs`, `CHANGELOG-GENERATED.md`, **and** the adoption-pilot SSOT line together" plus an added clarifying sentence that `CHANGELOG.md` is human-owned and never written by Release Please. Searched the rest of that section and the rest of `CONTRIBUTING.md` for other stale `CHANGELOG.md`-as-bump-target sentences (per the 213-03 SUMMARY's own finding, which named only this one instance) — none found. `test/threadline/release_artifact_contract_test.exs`'s "CONTRIBUTING carries the release pre-flight and release workflow literals" test (and 11 other CONTRIBUTING-referencing doc-contract test files) still pass: 138 tests, 0 failures.

## Skipped Issues

None — both in-scope findings were fixed.

---

_Fixed: 2026-09-26T15:30:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
