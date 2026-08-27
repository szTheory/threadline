---
phase: 195-validated-adversarial-critic-runner-panel
reviewed: 2026-08-26T15:46:28Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - test/threadline/operator_surface/stress_ledger_test.exs
  - test/threadline/critic_trust/ledger_splice_test.exs
  - lib/threadline/operator_surface/live/stress_live.ex
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 195: Code Review Report (plan 195-10 gap closure)

**Reviewed:** 2026-08-26T15:46:28Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Narrative Findings (AI reviewer)

## Summary

Reviewed the two extended guard-contract test files and the formatted LiveView against ground truth (`.planning/design-system-ledger.json`, `.planning/golden/synthetic-set.json`, `LedgerSplice`, `StressFixtures`). Both test files pass (23 tests, 0 failures) and the extensions are verified against the actual artifacts:

- `stress_live.ex` change is confirmed **whitespace-only** (`git diff -w` between `0e07f6d8..HEAD` is empty for the file). No behavior change.
- The `:object_key_not_found` atom matches `lib/threadline/critic_trust/ledger_splice.ex:54`; the old `:critic_trust_not_found` atom no longer exists anywhere. Reconciliation is correct.
- The extended `@top_level_keys` (`critic_panel`, `critic_trust_provenance`, `mechanical_auto_apply`) match the committed ledger exactly, and exact-equality on sorted keys means the contract remains frozen (any new/removed key fails loudly). Not weakened.
- The new refute sub-contract test is genuinely load-bearing: it asserts non-emptiness (no vacuous pass), null-never-0 scalars, and refute exclusion from `locked_ids`, `minimum_scores`, and `signoffs`. The three refute-kind exclusions added to pre-existing tests are each cross-referenced to it.
- The `is_integer/1` filter added to the evidence-ref test does not weaken the contract for non-refute entries: a nil `current_score` on a non-refute entry still fails the ratchet-upward test's `is_integer` assertion, so nothing slips through the filter silently. The `nil > 0` term-ordering rationale in the comment is accurate.

However, the extension leaves three "deliberately absent" claims stated in comments but unasserted, one contract gap at the cell level, and one latent misfire in the reset escape hatch. No Critical findings.

## Warnings

### WR-01: `ratchet.resets` shape mismatch makes the score-reset escape hatch unreachable

**File:** `test/threadline/operator_surface/stress_ledger_test.exs:118` (contrast with line 366)
**Issue:** The "scores can only ratchet upward" test reads `reset_ids = Map.get(ledger["ratchet"], "resets", [])` and later checks `id in reset_ids`. The committed ledger's `ratchet.resets` is an **object** (`{}`), and the sibling per-cell test (line 366) correctly reads `Map.keys(Map.get(ledger["ratchet"], "resets", %{}))`. When resets is a non-empty map, `id in reset_ids` enumerates `{key, value}` tuples and is **always false** — the first legitimately recorded reset will fail this guard with the misleading message "lowered current_score below ratchet_score without being listed in ratchet.resets" even when it is listed. This line predates the reviewed commits, but the diff touched the surrounding test (refute exclusion) without reconciling it, and the new refute work makes resets more likely to be exercised. Fails loud rather than silent, but the escape hatch is dead code as written.
**Fix:**
```elixir
reset_ids = Map.keys(Map.get(ledger["ratchet"], "resets", %{}))
```
(Extract a shared `reset_ids(ledger)` helper so the two tests cannot drift again.)

### WR-02: Refute twins' per-cell scores are not asserted null — "all-null by contract" is unguarded at the cell level

**File:** `test/threadline/operator_surface/stress_ledger_test.exs:145-175` (gap), `:341-344` (comment claiming coverage)
**Issue:** The rollup-integrity test now excludes refute entries with the comment "Refute twins are all-null by contract (D-04) — rollup covered by the refute sub-contract test", but the refute sub-contract test only asserts the **scalar** fields (`current_score`, `legacy_score`) are null. Nothing asserts the per-cell `scores[cell]["current"]` values are null for refute entries. A refute twin that gains an integer cell score passes every test: the rollup test skips it by kind, the per-cell ratchet test passes (`current >= floor` with floor default 0), and the cube-cell-set test only checks keys, not values. That integer cell would then contradict the null scalar rollup with no failure — exactly the drift D-04 exists to prevent.
**Fix:** In the refute sub-contract test's per-entry loop, add:
```elixir
for {cell_key, cell} <- entry["scores"] || %{} do
  assert is_nil(cell["current"]),
         "#{id} refute cell #{cell_key} current must be null (D-04), got #{inspect(cell["current"])}"
end
```

### WR-03: "Graded stories never in the product ratchet ledger" is a comment, not an assertion

**File:** `test/threadline/operator_surface/stress_ledger_test.exs:216-219`
**Issue:** The fixture-registry test was narrowed to skip graded stories, with the comment "registered in the synthetic oracle set …, never in the product ratchet ledger." The new synthetic-set test guards the positive half (every graded story backs an oracle cell) but nothing guards the negative half: a graded story's `ledger_id` (which defaults to its `id` per `stress_fixtures.ex:710`) added to `design-system-ledger.json` would violate D-12 silently — no test fails. Currently zero graded-ish ids appear in the ledger, so the absence assertion is cheap to add now. Without it, the D-12 registry split ("oracle set is the registry, not the ledger") is enforced in only one direction.
**Fix:** In the fixture-registry test (or the graded-set test):
```elixir
for story <- StressFixtures.graded_stories() do
  refute Map.has_key?(by_id, story.ledger_id),
         "graded story #{story.id} must not have a #{@ledger_path} entry (D-12: oracle set is the registry)"
end
```

### WR-04: `replace_provenance/2` happy path has zero test coverage — only the error atom is asserted

**File:** `test/threadline/critic_trust/ledger_splice_test.exs:80-81`
**Issue:** The extension adds only the `{:error, :object_key_not_found}` case for `replace_provenance/2`, yet this function is on the production write path (`lib/mix/tasks/critic.measure.ex:67`) and mutates the committed ledger. Untested behaviors: splice targets the right object (the key `"critic_trust":` is a strict prefix of `"critic_trust_provenance":` in the raw text — the colon-terminated needle disambiguates, but nothing proves it), byte-stability of the surrounding text, idempotence, `render_provenance` field order, and the documented "keys not in `provenance` are dropped" semantics. Note also that `render_provenance` uses `Map.get` (not `Map.fetch!` like `render_block`), so a partial or empty provenance map splices silent `null`s into the ledger — the very map shape (`%{}`) the test passes to the error case would succeed silently on a ledger that has the key. The sibling `replace/2` has four dedicated tests; `replace_provenance/2` deserves at least the byte-stability + idempotence pair.
**Fix:** Add a happy-path test mirroring "replace swaps only the critic_trust object": a ledger fixture containing both `"critic_trust"` and `"critic_trust_provenance"` siblings, assert only the provenance object changes, `critic_trust` bytes survive verbatim, and splice(splice(x)) == splice(x).

## Info

### IN-01: Signoff refute-exclusion uses undelimited prefix matching

**File:** `test/threadline/operator_surface/stress_ledger_test.exs:190-193`
**Issue:** `String.starts_with?(signoff["cell_key"], id)` without a trailing `.` delimiter. If a future entry id extends a refute id as a prefix (the ledger already contains such pairs among non-refute ids, e.g. `state.permission` / `state.permission-denied`), a legitimate signoff would be falsely rejected. Over-strict (fails loud), not a weakening.
**Fix:** `String.starts_with?(signoff["cell_key"], "#{id}.")`

### IN-02: "DESIGN-SYSTEM.md carries no refute rows" is asserted nowhere

**File:** `test/threadline/operator_surface/stress_ledger_test.exs:306-308`
**Issue:** The projection-freshness test skips refute entries with the comment "DESIGN-SYSTEM.md deliberately carries no refute rows" — currently true (zero `refute` mentions in the file) but unguarded; a stale refute row could linger or be added without failure. Same one-directional pattern as WR-03, lower stakes (projection doc, not the ratchet).
**Fix:** `refute markdown =~ "`refute.", "..."` alongside the freshness loop.

### IN-03: Synthetic-set linkage is one-directional — orphan oracle cells are unguarded

**File:** `test/threadline/operator_surface/stress_ledger_test.exs:229-243`
**Issue:** The test proves every graded story backs at least one oracle cell, but not that every `synthetic-set.json` item's `cell_id` prefix resolves to a live graded story. A renamed/deleted graded story leaves dangling oracle cells that silently stop rendering. Suggest asserting the inverse: each item's `cell_id` prefix (before `__`) is a member of `graded_ids`.
**Fix:** `for item <- synthetic_set["items"] do [prefix | _] = String.split(item["cell_id"], "__", parts: 2); assert MapSet.member?(graded_ids, prefix) end`

---

_Reviewed: 2026-08-26T15:46:28Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
