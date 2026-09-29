---
phase: 213-upgrade-guide-and-0-11-0-release
reviewed: 2026-09-26T15:12:04Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - CHANGELOG.md
  - README.md
  - guides/getting-started-saas.md
  - guides/upgrade-path.md
  - guides/upgrading-to-0.11.md
  - mix.exs
  - test/support/legacy_trigger_sql.ex
  - test/threadline/changelog_contract_test.exs
  - test/threadline/guide_graph_contract_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/upgrade_backfill_test.exs
  - test/threadline/upgrade_path_doc_contract_test.exs
  - test/threadline/upgrade_rollback_test.exs
  - test/threadline/upgrading_to_0_11_doc_contract_test.exs
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 213: Code Review Report

**Reviewed:** 2026-09-26T15:12:04Z
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Reviewed the upgrade guide's backfill/rollback SQL (`guides/upgrading-to-0.11.md`), the CHANGELOG security note, the doc-contract and real-PG proof tests, and every shipped surface file (README, mix.exs, getting-started-saas.md, upgrade-path.md) for planning-vocabulary leakage.

The backfill and rollback SQL are correct and match the actual trigger/capture code:
- The single-column and composite backfill statements use the text (`->>`) arrow exclusively, matching `PrimaryKeySQL.row_key_statements/0`'s own `v_row ->> TG_ARGV[i]` encoding — verified no `->` (JSON) arrow anywhere in either marker block.
- The composite backfill's "all key columns present and non-null" guard matches the trigger's own all-or-nothing key-resolution rule (`PrimaryKeySQL.row_key_statements/0`: any missing/NULL key column collapses the whole `table_pk` to `{}`).
- Idempotence and safe-to-rerun/overlap claims hold: the subquery re-filters by the still-unresolved `table_pk` predicate on every invocation, and two concurrent runs computing the same row's key from the same immutable `data_after` converge to identical output even if they block on each other's row locks.
- Both "unrecoverable" categories are accurate against the actual code: `test/support/legacy_trigger_sql.ex`'s frozen 0.10.2 body sets `v_data_after := NULL` for DELETE (confirmed at lines 121-123), and masked/excluded columns are genuinely never written to `data_after` by `TriggerSQL`'s redaction statements.
- Batching via `LIMIT <batch_size>` inside a `WHERE id IN (subquery)` keeps each transaction's lock footprint bounded, as documented.
- The rollback-cleanup `DO $$` block never touches the global `threadline_capture_changes` function (its `LIKE 'threadline\_capture\_changes\_%'` pattern requires a trailing underscore-plus-suffix the global name never has) and never uses `CASCADE`; this was independently proven by the new `upgrade_rollback_test.exs` catalog-level assertions.

The CHANGELOG Security section's every factual claim (which capture-function shapes are affected, the "last-migration-wins" mechanism, the cascade-drop-on-rollback hazard, and that upgrading does not rewrite `audit_changes`) was checked against `lib/threadline/health/trigger_findings.ex`'s `shared_findings/1` and the frozen legacy trigger body, and holds up.

No planning vocabulary (phase numbers, `D-NN` decision IDs, `REL-NN`/`HLTH-`/`TWIN-`/`WR-` requirement IDs, milestone literals) was found in any shipped file (CHANGELOG.md, README.md, guides/, mix.exs) — confirmed by both a manual grep and the shipped `upgrading_to_0_11_doc_contract_test.exs`'s own banned-vocabulary scan.

Two warnings below concern the real-PG proof's fidelity to its own stated methodology, not the shipped guide text itself.

## Warnings

### WR-01: Shared-function fixture is built from the current TriggerSQL renderer, not a frozen 0.10.2 shape

**File:** `test/threadline/upgrade_backfill_test.exs:344-348`, `test/threadline/upgrade_rollback_test.exs:189-193`

**Issue:** The phase's own context (D-07) requires: "Build the fixture from the frozen `Threadline.Test.LegacyTriggerSQL` 0.10.2 SQL... No `git show` at test time... Extend `LegacyTriggerSQL` where a shape needs it." For the shared-capture-function pair — the exact scenario the new CHANGELOG Security note discloses, and the most security-sensitive fixture in this phase — both `upgrade_backfill_test.exs` and `upgrade_rollback_test.exs` instead call `Threadline.Capture.TriggerSQL.install_function_for_table/2` (the **current**, 0.11 renderer) to install the "pre-upgrade" shared function, rather than adding a frozen 0.10.2 per-table redacted function to `LegacyTriggerSQL` as D-07 directs.

`git log -p -- lib/threadline/capture/trigger_sql.ex` confirms `install_function_for_table/2`'s body changed in this same milestone (phase 210's `PrimaryKeySQL`-based primary-key resolution was folded into it), so the "pre-upgrade" fixture in both proof tests is actually running the 0.11 per-table function body, not 0.10.2's. For the two id-keyed tables used in these specific tests this happens to be behaviorally indistinguishable from a real 0.10.2 body (both resolve to the same `{"id": <value>}` shape via the `TG_NARGS = 0` legacy branch), so the tests' current assertions do not appear to be false positives — but the proof no longer demonstrates what it claims to (a real seeded 0.10.x install), and a future change to `install_function_for_table/2`'s per-table body would silently change what this "frozen legacy" fixture represents with no failing signal, since it isn't frozen at all. This is exactly the drift-without-a-test-failure risk D-07 was written to prevent.

**Fix:** Add a frozen `LegacyTriggerSQL.v0_10_2_install_function_for_table/3` (or similar) reproducing the actual 0.10.2 per-table redacted function body — mirroring how `v0_10_2_install_function/2` and `v0_10_2_drop_function_for_table/2` were already added for the global-function and rollback shapes — and use it in both test files' shared-pair fixture setup instead of the live `TriggerSQL.install_function_for_table/2`.

### WR-02: `CONTRIBUTING.md` release-PR description is stale, left unfixed

**File:** `CONTRIBUTING.md:690` (not in the reviewed file list, but flagged by the phase's own summary and independently confirmed)

**Issue:** `CONTRIBUTING.md` line 690 still states "The Release PR bumps `mix.exs`, `CHANGELOG.md`, **and** the adoption-pilot SSOT line together." This has been stale since the CHANGELOG split made `CHANGELOG.md` human-owned and `CHANGELOG-GENERATED.md` release-please's actual write target (documented at the top of `CHANGELOG.md` itself, and enforced by `changelog_contract_test.exs`'s ownership-split assertions). The 213-03 SUMMARY explicitly records this as a known, unfixed issue ("Finding for the maintainer (no fix made here)") but it ships as-is in this phase's diff scope.

**Fix:** One-line correction to `CONTRIBUTING.md:690` naming `CHANGELOG-GENERATED.md` (not `CHANGELOG.md`) as release-please's bump target, in a follow-up docs commit.

## Info

### IN-01: Guide's Step 2 "who this fix applies to" prose reads ambiguously on first pass

**File:** `guides/upgrading-to-0.11.md:116-124`

**Issue:** The paragraph explaining that a refused-type table's legacy trigger still reports `pk_drift` (added as a correction during 213-02, per that plan's SUMMARY) is dense: it packs the covered/not-covered distinction, the `id`-vs-other-name exception, and the "not a sign of a separate problem" reassurance into one long paragraph immediately after a five-row fix table. A first-time reader upgrading a `timestamptz`-keyed table could plausibly read the `pk_drift` row's "error" severity and treat it as a blocking problem before reaching this qualifying paragraph.

**Fix:** Consider a short callout or bullet directly under the finding-code table for this specific interaction ("Refused-type table + `pk_drift`: expected, not a regression") rather than trailing prose, so it isn't easy to miss when scanning the table for fixes.

### IN-02: `<key_col>` composite-key guidance doesn't show the guard for arbitrary N > 2

**File:** `guides/upgrading-to-0.11.md:138-142`

**Issue:** The parameters section tells an adopter with a 3+ column composite key to "add one more `jsonb_build_object` pair, one more entry in the `?&` array, and one more `IS NOT NULL` guard per column" but only ever shows the 2-column form. This is a reasonable extrapolation for a competent SQL reader, but since the guide otherwise goes out of its way to give copy-pasteable exact text everywhere else (including the batch pattern and rollback block), the one spot requiring adopter-authored SQL editing is also the one place a transcription mistake (e.g., forgetting one of the three required additions) would silently produce an under-guarded, non-idempotent statement.

**Fix:** Optional — a three-column worked example (even as a collapsed/appendix block) would remove the last spot in the guide requiring the adopter to hand-extend guarded SQL rather than substitute placeholders.

---

_Reviewed: 2026-09-26T15:12:04Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
