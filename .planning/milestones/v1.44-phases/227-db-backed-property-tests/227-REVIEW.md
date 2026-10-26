---
phase: 227-db-backed-property-tests
reviewed: 2026-10-01T00:00:00Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - .github/workflows/flake-detection.yml
  - CHANGELOG.md
  - lib/threadline/retention.ex
  - test/support/db_property.ex
  - test/support/leak_oracle.ex
  - test/support/redaction_leak_generators.ex
  - test/support/retention_cutoff_generators.ex
  - test/support/row_history_generators.ex
  - test/threadline/capture/redaction_leak_property_test.exs
  - test/threadline/capture/trigger_redaction_test.exs
  - test/threadline/db_property_harness_test.exs
  - test/threadline/flake_classifier_contract_test.exs
  - test/threadline/property_generator_coverage_test.exs
  - test/threadline/property_scale_contract_test.exs
  - test/threadline/query/as_of_property_test.exs
  - test/threadline/query_test.exs
  - test/threadline/retention/cutoff_property_test.exs
  - test/threadline/retention_test.exs
  - .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 227: Code Review Report

**Reviewed:** 2026-10-01
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found (no blockers)

## Summary

This phase's core product change is small and well-targeted: `lib/threadline/retention.ex`'s
`dry_run_result/4` orphan-transaction predicate was changed from "transaction has no
`audit_changes` row at all" to "transaction has no `audit_changes` row with
`captured_at >= cutoff`" (the D-20 fix). I traced this against the real purge path
(`purge_loop` → `delete_change_batch` + `drain_orphans`) by hand for the cases the task
flagged:

- **Zero-change transactions** (never had any `audit_changes` row): both the old and new
  dry-run predicate count these as eligible (`NOT EXISTS` is vacuously true either way), and
  the real `drain_orphans` predicate (`NOT EXISTS (change WHERE transaction_id = t)`, no
  cutoff filter) also deletes them in the very first batch. Dry run and real purge agree.
- **Transactions with only expired changes**: before the fix, the dry run only counted a
  transaction as orphaned if it had *zero* changes *before the run even started* — it could
  never predict a transaction that the purge itself would empty out. After the fix, the
  predicate correctly mirrors the terminal state the real loop reaches once all
  `captured_at < cutoff` rows are deleted (at that point `NOT EXISTS (any change)` and
  `NOT EXISTS (change >= cutoff)` are equivalent, because no `< cutoff` rows remain to
  create a difference). This is the regression this fix closes, and it's exactly the gap
  `retention_test.exs`'s new "D-20 regression" example and `cutoff_property_test.exs`'s
  property pin down.
- **Multiple tables / batch boundaries**: `delete_change_batch` has no table filter (it
  purges by `captured_at` across all tables in one storage schema), and the orphan drain is
  unconditional over `audit_transactions`, so multi-table fixtures don't change the
  predicate's correctness — confirmed by the property's `table_pk`/`table_name` being
  irrelevant to the purge predicate, and by `cutoff_property_test.exs` generating multiple
  independent transactions per iteration with a `batch_size` of `1, 2, 3, 500` specifically
  to exercise small-batch orphan draining between change-delete passes. Draining happens once
  per outer iteration (not only at the very end), but because a transaction's orphan status
  can only flip from "not yet orphan" to "orphan" (not back), the final total still matches
  the dry-run's one-shot full-table prediction.

The property tests and their oracles were specifically checked for the "oracle reuses the
code under test" trap (the task's second priority) and I did not find an instance of it:

- `test/threadline/retention/cutoff_property_test.exs` computes `expected_purged_ids`,
  `expected_survivor_ids`, and `expected_orphaned_ids` purely from generated facts
  (`DateTime.compare(captured_at, cutoff)`), never from `lib/threadline/retention.ex`. Good —
  this is the right design to catch exactly the class of bug the D-20 fix addresses (a
  one-sided `<`/`<=` mutation on either the dry run or the real delete).
- `test/threadline/query/as_of_property_test.exs`'s oracle is a folded in-memory model built
  from the generated steps as they're applied as literal SQL, never from `data_after` or
  `Query.as_of/4` itself — also correctly independent.
- `test/support/leak_oracle.ex` / `redaction_leak_generators.ex` plant canary tokens
  independently of the trigger/export code and scan raw storage + every export surface for
  leakage; the oracle doesn't call into `Threadline.Capture`'s redaction logic to decide what
  "should" be masked.
- `test/support/db_property.ex`'s per-iteration cleanup and `assert_audit_tables_empty!`
  precondition are sound: DataCase modules default to `async: false`, so ExUnit never runs
  these whole-table-assuming properties concurrently with another DB-touching test (ExUnit
  serializes all `async: false` tests against each other and runs them outside the
  concurrent `async: true` pool), which is what makes the "assert whole table is empty before
  each iteration" precondition safe rather than racy.

No blockers found. Two warnings and two info items below, none specific to the D-20 fix
itself (which I believe is correct) — they're pre-existing or adjacent quality points
surfaced while tracing the change.

## Warnings

### WR-01: `purge_result/0` typespec doesn't include the `:dry_run` key the dry-run path actually returns

**File:** `lib/threadline/retention.ex:24-28` (type), `lib/threadline/retention.ex:161-166` (actual return)
**Issue:** `@type purge_result` declares a map with exactly three keys
(`deleted_changes`, `deleted_transactions`, `batches_run`), and `purge/1`'s `@spec` promises
`purge_result() | {:error, :disabled}`. But `dry_run_result/4` returns a fourth key,
`dry_run: true`, that isn't part of the declared type. This isn't new in this diff, but it's
directly adjacent to the D-20 change (same function family) and a caller writing a
pattern-match against the documented type won't realize `:dry_run` is present without reading
the implementation. A pre-existing gap, but worth closing while this code is being touched
regardless.
**Fix:**
```elixir
@type purge_result :: %{
        deleted_changes: non_neg_integer(),
        deleted_transactions: non_neg_integer(),
        batches_run: non_neg_integer(),
        dry_run: boolean()
      }
```
and always include `dry_run: false` in the real-run result map (`run_with_tracking/7`'s
return), so the key is present in both branches rather than only in dry-run output.

### WR-02: `dry_run: true` silently ignores `:batch_size` and `:max_batches`, with no runtime signal

**File:** `lib/threadline/retention.ex:49-79`
**Issue:** `purge/1` extracts `batch_size` and `max_batches` from `opts` unconditionally
(lines 51-52) and only threads them into `run_with_tracking/7`; `dry_run_result/4` never
receives them. The moduledoc documents this ("The preview assumes the run completes; a run
cut short by `:max_batches` deletes fewer"), and `retention_test.exs`/`cutoff_property_test.exs`
exercise dry runs with explicit `batch_size:`/`max_batches:` values that are silently dropped
on the floor — which is harmless in tests but means an operator script that passes
`max_batches: 5` to a dry run, expecting a bounded preview, gets the full-table count instead
with no warning. Given this is specifically the function the D-20 fix just made more subtle
(dry run and real-run agreement is now the selling point of this fix, documented as a
near-contract), a silent divergence in the one case where they're *expected* to disagree is a
sharp edge.
**Fix:** Either reject `batch_size`/`max_batches` when `dry_run: true` with a clear error, or
emit a one-line `Logger.warning` when they're passed alongside `dry_run: true`, e.g.:
```elixir
if dry_run? and (Keyword.has_key?(opts, :batch_size) or Keyword.has_key?(opts, :max_batches)) do
  Logger.warning("threadline retention dry_run ignores :batch_size/:max_batches; preview assumes a complete run")
end
```

## Info

### IN-01: `drain_orphans/4`'s unconditional predicate and the dry run's cutoff-filtered predicate are proven equivalent only by inference, not documented at the call site

**File:** `lib/threadline/retention.ex:227-253` (real), `lib/threadline/retention.ex:132-167` (dry run)
**Issue:** The real orphan-drain query (`NOT EXISTS (change WHERE transaction_id = t)`, no
cutoff) and the dry-run preview query (`NOT EXISTS (change WHERE transaction_id = t AND
captured_at >= cutoff)`) are deliberately *different* predicates by design (per
`cutoff_property_test.exs`'s moduledoc, this is intentional — a shared predicate would let a
single mutation escape detection on both sides at once). Their results only coincide because,
by the time `drain_orphans/4` runs within a given outer iteration, all `captured_at < cutoff`
rows for that transaction have already been deleted by `delete_change_batch/4` earlier in the
same iteration (or a prior one) — so "no changes at all" and "no changes >= cutoff" become the
same fact at drain time. This reasoning lives in the property test's moduledoc, not in
`retention.ex` itself; a future maintainer editing `drain_orphans/4` in isolation has no
pointer in the production file to the invariant that makes dry-run/real-run agreement hold.
**Fix:** Add a short comment above `drain_orphans/4` (or above `purge_loop/6`) noting that the
unconditional "no changes at all" check is only equivalent to the dry run's "no changes >=
cutoff" check because expired rows are always deleted first within the same pass — pointing
readers at `cutoff_property_test.exs` for the property that enforces this.

### IN-02: `.github/workflows/flake-detection.yml`'s re-derived ceilings rest on a single dispatch run

**File:** `.github/workflows/flake-detection.yml` (comment block above the repeat-count logic), `test/threadline/flake_classifier_contract_test.exs:747-813`
**Issue:** The updated budget comment and the matching `@cold_first_run_ceiling_s 370` /
`@repeat_ceiling_s 300` constants are derived from exactly one dispatch run
(`36930385324`). The previous ceiling (348 s/295 s) was itself derived from a second,
confirmatory run after an initial inconclusive one. This isn't a bug — the test and workflow
are internally consistent with each other, and the arithmetic (370 + 8×300 = 2,770s under the
2,970s budget) checks out — but a single data point sets the margin for a weekly Flake
Detection lane that costs real CI minutes to re-run if it's wrong (and failing closed —
`inconclusive`, not `flaky` — if the real worst case is slower). Flagging for awareness
rather than action: worth a second confirmatory run before this ceiling is trusted long-term,
same as the prior one was.
**Fix:** No code change needed; consider capturing a second dispatch run's numbers before the
next unrelated phase touches this file again, so the ceiling has two data points like its
predecessor did.

---

_Reviewed: 2026-10-01_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
