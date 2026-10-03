---
phase: 229-adopter-api-and-health-additions
fixed_at: 2026-10-02T00:00:00Z
review_path: .planning/phases/229-adopter-api-and-health-additions/229-REVIEW.md
iteration: 1
findings_in_scope: 1
fixed: 1
skipped: 1
status: partial
---

# Phase 229: Code Review Fix Report

**Fixed at:** 2026-10-02
**Source review:** .planning/phases/229-adopter-api-and-health-additions/229-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope (critical_warning): 1 (WR-01)
- Out-of-scope (Info, not attempted per fix_scope=critical_warning): 1 (IN-01)
- Fixed: 1
- Skipped: 1 (out-of-scope, not a fix failure)

## Fixed Issues

### WR-01: Stray positional CLI arguments to `mix threadline.health.coverage` are silently discarded

**Files modified:** `lib/mix/tasks/threadline.health.coverage.ex`,
`test/threadline/operator_surface/coverage_mix_test.exs`, `CHANGELOG.md`
**Commit:** `7f60339f`
**Applied fix:** `OptionParser.parse/2`'s discarded positional-args element
(previously bound to `_`) is now bound to `extra` and checked alongside
`invalid`: `if invalid != [] or extra != [] do ... end` raises
`Mix.raise/1` naming every bad switch and every stray positional argument,
matching the REVIEW.md suggestion. The moduledoc's "unknown or invalid
switch" sentence was extended to also describe the stray-positional-argument
case (a dropped leading `--`, e.g. `schema=public` instead of
`--schema=public`). Added a regression test,
`"stray positional arguments raise Mix.Error naming the stray argument,
before any DB access (WR-01)"`, asserting `Coverage.run(["--strict",
"schema=public"])` raises `Mix.Error` naming `schema=public` in the
`"unknown switches (D-16)"` describe block (kept adjacent to the existing
unknown-switch test it extends). Extended the existing CHANGELOG.md
"Unreleased -> Fixed" entry for `mix threadline.health.coverage`'s
unknown-switch raise to also cover stray positional arguments, rather than
adding a new entry.

Searched for other places documenting or exercising this switch-only raise
before touching anything: `guides/*.md` have no mention of the "unknown or
invalid switch" wording (nothing to update there); the doc-contract test
(`test/threadline/operator_surface/coverage_doc_contract_test.exs`) pins the
`OptionParser` `strict:` spec literal and the `@shortdoc`/usage lines, not
the raise-message wording, so it was unaffected and still passes.
`lib/mix/tasks/threadline.verify_coverage.ex` has the same `{opts, _, _}`
discard pattern, but it is a different mix task not named in WR-01's scope
(the REVIEW.md finding and this task's instructions both scope the fix to
`threadline.health.coverage.ex` only) — left untouched.

**Verification performed (in the main checkout, repo root, branch
`milestone/v1.44` — no isolated worktree was used per the task's explicit
"work in place" instruction):**
- `mix test test/threadline/operator_surface/coverage_mix_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs` — 88 tests, 0 failures (run sequentially, single process, against the shared non-sandboxed test Postgres).
- `mix format --check-formatted` — clean.
- `mix compile --warnings-as-errors` — clean.
- `mix verify.credo` — "4951 mods/funs, found no issues."
- `lib/threadline/query.ex` was not read or touched (out of scope per task instructions).

## Skipped Issues

### IN-01: Schema-identifier regex duplicated between `CoverageSchemas` and the mix task

**File:** `lib/mix/tasks/threadline.health.coverage.ex:278,282` and
`lib/threadline/health/coverage_schemas.ex:6`
**Reason:** out of scope for this fix pass. `fix_scope` for this run is
`critical_warning`; IN-01 is an Info-severity finding and the task
instructions explicitly call it out as "out of scope — record it as
skipped/out-of-scope." Not attempted; no code touched for this finding.
**Original issue:** The mix task re-derives `CoverageSchemas`'s
`@schema_regex` as an inline literal to decide between a "not a valid
PostgreSQL identifier" error and a "schema ... not found" error. The two
copies agree today but nothing enforces that, so if the regex is ever
tightened/loosened in `CoverageSchemas`, the task's error-message branch
could silently diverge from the actual validation outcome.

---

_Fixed: 2026-10-02_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
