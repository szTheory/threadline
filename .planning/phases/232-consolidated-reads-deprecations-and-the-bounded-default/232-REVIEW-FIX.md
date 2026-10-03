---
phase: 232-consolidated-reads-deprecations-and-the-bounded-default
fixed_at: 2026-10-03T21:44:31Z
review_path: .planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 1
status: partial
---

# Phase 232: Code Review Fix Report

**Fixed at:** 2026-10-03T21:44:31Z
**Source review:** .planning/phases/232-consolidated-reads-deprecations-and-the-bounded-default/232-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 3 (CR-01, WR-01, WR-02); IN-01 was explicitly excluded from scope per the orchestrator's `fix_scope`
- Fixed: 3
- Skipped: 1 (IN-01, out of scope by request, not attempted)

## Fixed Issues

### CR-01: `next-page` in actor_live.ex sets `prev_cursor` to a value that causes duplicate re-fetch on scroll-up

**Files modified:** `lib/threadline/operator_surface/live/actor_live.ex`, `test/threadline/operator_surface/live/actor_live_test.exs`
**Commit:** `fa5a6113`
**Applied fix:** Removed the `|> assign(:prev_cursor, newer_boundary_cursor(page.entries))` line from the `"next-page"` handler, restoring the pre-phase invariant that forward (older) page loads never touch `prev_cursor`. Removed the now-unused `newer_boundary_cursor/1` helper (confirmed no other callers; `mix compile --warnings-as-errors` stays clean). Added a regression test (`Case 6`) that inserts 110 transactions, loads the page, calls `"next-page"` twice, and asserts the `Newer` pager control stays `disabled` throughout, then calls `"prev-page"` and asserts the row count is unchanged (no duplicate re-fetch/re-prepend). Verified RED-then-GREEN: with the lib fix temporarily reverted (via `git stash` on only the lib file, never committed), the new test failed exactly as the finding predicted (`Newer` control became reachable after the first `next-page`); with the fix restored, all 15 tests in the file pass.

### WR-01: `RowReads.list/3`'s explicit `limit: n` path silently returns fewer rows than `n` with no truncation signal, by design

**Files modified:** `lib/threadline/query/row_reads.ex`
**Commit:** `39d9da9b`
**Applied fix:** Added a comment at the `{:ok, n}` clause in `list/3` explaining that an explicit `limit: n` intentionally never fires the row-history truncation telemetry event (only the implicit default cap does), so a future contributor does not "fix" this by adding a symmetric emit that would misreport which limit was actually hit. The comment describes the behavior and its rationale without referencing any internal planning-decision IDs, to stay clear of the planning-vocabulary guard in `test/threadline/release_artifact_contract_test.exs`.

### WR-02: `row_history_scope_opts/3`'s shared `:surface` default between the bounded and deprecated-unbounded read paths

**Files modified:** `lib/threadline/query.ex`, `guides/integration-contracts.md`
**Commit:** `949b24a3`
**Applied fix:** Chose the documentation-only option the review itself offered (not the riskier "give the deprecated path a distinct `:surface` value" option, which would be an undocumented, unlocked behavior change affecting any existing `scope_query_fn` that already filters on `surface: :row_history` for both paths). Added a comment at `row_history_scope_opts/3`'s definition explaining that its default `:surface` is shared by the bounded `row_history/3` read and the deprecated, unbounded `history/3` read, and that callers needing to distinguish them should pass an explicit `:surface` override. Added a matching caller-facing paragraph to `guides/integration-contracts.md`'s `scope_query_fn` section. `mix test test/threadline/integration_contracts_doc_contract_test.exs` (8 tests) still passes with the new prose.

## Skipped Issues

### IN-01: `Investigation.row_history_page/4`'s doc caveat is not cross-linked across its `_page` siblings

**File:** `lib/threadline/investigation.ex:56-71`
**Reason:** Out of scope by the orchestrator's explicit instruction (`fix_scope: critical_warning (CR-01, WR-01, WR-02; leave IN-01 as skipped)`). Not attempted.
**Original issue:** `row_history_page/4`'s moduledoc states the "absent/nil cursor means first page" caveat independently of its `actor_window_page`/`correlation_bundle_page` siblings, which repeat the same caveat rather than cross-linking a single source of truth. Low-value cleanup per the review; left for a future pass if desired.

## Verification

All verification below ran inside the isolated worktree created for this fix session
(`.claude/worktrees/rf-232-...`, removed after this report was written), with `deps/`
and `_build/` symlinked in from the main checkout so the project's Mix tasks could
run (the worktree has no dependencies installed of its own). The symlinks were never
staged or committed. Compile, format, and credo results are reproducible from the
main checkout at the commits listed above; the `mix test test/threadline/operator_surface`
run noted below was re-run directly in the main checkout after the fast-forward merge,
since the worktree's `critic_trust_test.exs` cases fail there for an environment
reason unrelated to this phase's findings (see note).

- `mix compile --warnings-as-errors` — clean after each commit.
- `mix verify.format` — clean after each commit.
- `mix verify.credo` — clean after each commit (0 issues across 428 files).
- `mix test test/threadline/operator_surface/live/actor_live_test.exs` — 15 tests, 0 failures (includes the new CR-01 regression test), confirmed RED before the fix and GREEN after.
- `mix test test/threadline/query_test.exs test/threadline/query/row_key_read_test.exs test/threadline/telemetry_registry_contract_test.exs test/threadline/release_artifact_contract_test.exs` — 107 tests, 0 failures.
- `mix test test/threadline/integration_contracts_doc_contract_test.exs` — 8 tests, 0 failures.
- `mix test test/threadline/operator_surface` run inside the worktree showed 7 failures, all in `critic_trust_test.exs`, all unrelated to this phase's findings (that suite anchors some checks to the repository root, and fails identically regardless of whether the CR-01/WR-01/WR-02 fixes are applied or reverted). Reproduced the same full directory run in the main checkout both before and after the fast-forward merge: 853/854 tests, 0 failures (854 once the new regression test lands), confirming the worktree failures are an artifact of the symlinked, path-relocated environment rather than a regression caused by these fixes.

---

_Fixed: 2026-10-03T21:44:31Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
