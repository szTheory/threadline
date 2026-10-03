---
phase: 227-db-backed-property-tests
fixed_at: 2026-10-02T03:20:00Z
review_path: .planning/phases/227-db-backed-property-tests/227-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 227: Code Review Fix Report

**Fixed at:** 2026-10-02T03:20:00Z
**Source review:** .planning/phases/227-db-backed-property-tests/227-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2 (fix_scope: critical_warning — no Critical findings existed; both Info
  findings, IN-01 and IN-02, were out of scope and not touched)
- Fixed: 2
- Skipped: 0

All work was done in an isolated git worktree (`gsd-reviewfix/227-81305`, created from
`milestone/v1.44`) per the writer-isolation protocol. `deps/` and `_build/` were symlinked in
from the main checkout so `mix` could run without a fresh
`deps.get`/compile; both symlinks were removed before handoff and never committed. All gate
commands (`mix compile --warnings-as-errors`, `mix test`, `mix format`, `mix credo --strict`)
ran inside that worktree, not the main checkout — this is worth noting for reproducibility,
since the worktree is torn down after this run.

## Fixed Issues

### WR-01: `purge_result/0` typespec doesn't include the `:dry_run` key the dry-run path actually returns

**Files modified:** `lib/threadline/retention.ex`
**Commit:** f68a65a5
**Applied fix:** Added `dry_run: boolean()` to the `@type purge_result` map type, and changed
`purge_loop/6`'s success-path return map (used by `run_with_tracking/7`, the real-run branch)
to always include `dry_run: false`. The dry-run branch (`dry_run_result/4`) already returned
`dry_run: true`; now both branches of `purge/1` return a map matching the full declared type
instead of only the dry-run branch carrying the key. No runtime behavior changed for callers
that were already pattern-matching loosely or reading specific keys — this only makes the
`@spec` honest and gives real-run callers a `:dry_run` key to check if they want one, matching
the dry-run branch's shape.
**Verification:** `mix compile --warnings-as-errors` clean; `mix test
test/threadline/retention_test.exs test/threadline/retention/cutoff_property_test.exs` — 11
tests / 1 property, 0 failures; `mix format` produced no diff beyond the edit itself; `mix
credo --strict` on the touched file — no issues.

### WR-02: `dry_run: true` silently ignores `:batch_size` and `:max_batches`, with no runtime signal

**Files modified:** `lib/threadline/retention.ex`, `test/threadline/retention_test.exs`,
`CHANGELOG.md`
**Commit:** c28f74e2
**Applied fix:** Per phase guidance, chose the documentation-first option over adding a
`Logger.warning` or raising, since this is pre-existing behavior (not a regression) and a
runtime signal would be a user-facing behavior change with its own risk. Extended the
`:dry_run` option doc in `purge/1`'s `@doc` to state explicitly: "`:batch_size` and
`:max_batches` are ignored in dry-run mode — the preview is a single full-table count, not a
batched simulation, so passing either alongside `dry_run: true` has no effect on the returned
counts." Added a test, `"dry run ignores :batch_size and :max_batches (preview is a full-table
count, not batched)"`, that pins the behavior by asserting a dry run with `batch_size: 1,
max_batches: 1` returns an identical result map to an unbounded dry run over the same fixture.
Added a `CHANGELOG.md` entry under `## Unreleased — highlights` → `### Fixed` describing both
WR-01 and WR-02 in adopter-facing prose (no internal finding IDs or planning vocabulary), each
explicitly marked "No action needed". Orchestrator correction: WR-01 IS a small additive runtime change (real purges previously returned no `dry_run` key); the CHANGELOG entry was reworded to say so.
**Verification:** `mix compile --warnings-as-errors` clean; `mix test
test/threadline/retention_test.exs test/threadline/retention/cutoff_property_test.exs` — 11
tests / 1 property, 0 failures (new pinning test passing); `mix format` produced no diff beyond
the edit itself; `mix credo --strict` on the touched source/test files — no issues.

## Skipped Issues

None — all in-scope findings (WR-01, WR-02) were fixed. IN-01 and IN-02 were out of scope for
`fix_scope: critical_warning` and were not evaluated or touched.

---

_Fixed: 2026-10-02T03:20:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
