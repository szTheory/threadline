---
phase: 209-collision-free-emission
plan: 05
subsystem: capture-generator-docs
status: complete
tags: [docs, capture, triggers, changelog, upgrade]
requires:
  - hashed per-table function names and orphan-safe drops (plan 03)
  - migrate-time owner guard and its HINT (plan 04)
provides:
  - gen.triggers moduledoc describing derived/hashed per-table names, orphan-safe non-cascading drops, and long/non-public per-table support
  - moduledoc section "Tables that shared a capture function" (safe orders, migrate-time error + hint, keep WARNING)
  - corrected CHANGELOG Unreleased / Changed sentence
affects:
  - later release phase still owns the security advisory note, leaked-rows disclosure and upgrade guide
tech-stack:
  added: []
  patterns: []
key-files:
  created: []
  modified:
    - lib/mix/tasks/threadline.gen.triggers.ex
    - CHANGELOG.md
decisions:
  - "The new section tells adopters to delete the refused migration file before generating the suggested one: it keeps an earlier version, so leaving it would make the next mix ecto.migrate run and refuse it again"
  - "The section says 'Releases up to 0.10.2' (matching the function_owner_guard @doc) and 'Later releases', not 'this release', so the moduledoc does not go stale"
metrics:
  duration: ~12m
  completed: 2026-09-25
actuals:
  tokens: 1800
  tasks: 2
  commits: 2
plan_head_before: 5e07512548543de41178273b964beacb3f88c9f8
---

# Phase 209 Plan 05: Adopter Docs for Collision-Free Emission Summary

The `mix threadline.gen.triggers` moduledoc and the CHANGELOG Unreleased section now describe what shipped:
- per-table capture function names come from the schema and table, with a hash for non-public tables and names over 36 bytes;
- a function is dropped only when no trigger uses it, and the drop never cascades;
- per-table mode works for long and non-public tables;
- the docs give the safe regeneration orders for tables that shared a capture function, and describe the migrate-time error with its hint.

## What was built

**Task 1: hashed names and orphan-safe drops** (commit 4422f43e)
- The per-table sentence no longer uses `threadline_capture_changes_<table>`. It says a public table of at most 36 bytes keeps `threadline_capture_changes_` plus the table name, and every other table gets a shortened name ending in a hash of its schema and table.
- The Rerunning paragraph: a function the migration no longer needs is dropped only after every trigger is re-pointed, and only when no trigger still uses it. Otherwise the function is kept and `mix ecto.migrate` prints a WARNING naming the tables. The drop never cascades, and a missing function is skipped. The old sentence about skipping names over 63 bytes was removed.
- Long table names: per-table mode now works for long and non-public tables. The "until a later release" promise is gone.
- The `parse_tables!/1` comment now says derived names are built to fit in 63 bytes.
- CHANGELOG Unreleased / Changed: the "still rejected ... until a later release" sentence now says such tables generate, and that a non-public table or a name over 36 bytes gets a capture function whose name ends in a hash. A new sentence says generated migrations drop a capture function only when no trigger uses it, and never cascade. The changes add no security note, disclosure or upgrade guide.

**Task 2: the formerly shared function section** (commit 6795520d)
- New `## Tables that shared a capture function` section, using the `public.billing_invoices` / `billing.invoices` example. It covers:
  - the two safe orders: both tables in one command, or the non-public or long table first;
  - the command itself;
  - regenerating only the table that keeps the old name, which stops `mix ecto.migrate` with an error whose hint gives the command, and applies nothing;
  - deleting the refused migration file;
  - the keep WARNING, including the case where a public table legitimately owns the name. Regenerating as advised is always safe.

## Verification

- Task 1: gen_triggers, changelog_contract, release_artifact_contract and code_walkthrough_doc_contract tests passed: 70 tests, 0 failures.
- Task 2: gen_triggers and source_size_contract tests passed: 54 tests, 0 failures.
- `mix verify.test`: 9 properties, 1963 tests, 0 failures, 1 excluded (`pgbouncer_topology`). No 42622 in the output. The known ecto_sql `:warn` deprecation stack traces appear, as described in 209-03.
- Acceptance greps:
  - `until a later release`: 0 in both files.
  - `threadline_capture_changes_<table>`: 0 in gen.triggers and in trigger_sql.ex.
  - Planning vocabulary: none.
  - `billing.invoices`: 7.
  - `mix ecto.migrate`: 5.
  - `git diff main -- guides/code-walkthrough.md`: empty.
- Every `@rerun_doc_phrases` string is still in the moduledoc, checked by the gen_triggers rerun documentation test.
- `mix format --check-formatted` on the task file: clean.

## Deviations from Plan

- **The moduledoc says to delete the refused migration file.** The plan did not list this sentence. It follows from the code: the refused migration is still on disk with an earlier version, so `mix ecto.migrate` would run it again before the combined one.
- **The moduledoc says "Later releases" instead of "this release".** This keeps it accurate after the next release.
- Reflowed one pre-existing moduledoc paragraph, because the new per-table sentence made a line too long.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: lib/mix/tasks/threadline.gen.triggers.ex, CHANGELOG.md
- FOUND: 4422f43e (Task 1)
- FOUND: 6795520d (Task 2)
