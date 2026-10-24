---
phase: 224-capture-and-bench-fixes
fixed_at: 2026-09-30T00:00:00Z
review_path: .planning/phases/224-capture-and-bench-fixes/224-REVIEW.md
iteration: 2
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 224: Code Review Fix Report

**Fixed at:** 2026-09-30T00:00:00Z
**Source review:** .planning/phases/224-capture-and-bench-fixes/224-REVIEW.md
**Iteration:** 2

**Summary:**
- Findings in scope: 2 (fix_scope `all` — WR-01 and IN-01)
- Fixed: 2
- Skipped: 0

## Fixed Issues

### WR-01: `verify-compile-no-optional` CI job timeout not re-validated after adding a dependency-fetching step

**Files modified:** `.github/workflows/ci.yml`
**Commit:** 199515b8 (carried from iteration 1)
**Applied fix:** Bumped `timeout-minutes` on the `verify-compile-no-optional` job from `10` to `15` for margin. Verified in this iteration that the change is present at `.github/workflows/ci.yml:192` (`timeout-minutes: 15`) — no re-application needed.

### IN-01: `CONTRIBUTING.md`'s "no `MIX_ENV`" phrasing is a little imprecise

**Files modified:** `CONTRIBUTING.md`
**Commit:** 220fb91a
**Applied fix:** Reworded the `verify-compile-no-optional` table cell (CONTRIBUTING.md:649) from "...the bench project compiles with a bare `mix compile`, no `MIX_ENV`)" to "...the bench project compiles with a bare `mix compile`, `MIX_ENV` unset by the caller; `bench/mix.exs`'s own `preferred_envs` resolves it to `:test`)". Kept as a single table cell with no `|` characters.

Before editing, grepped `test/` for any doc-contract test pinning the exact prose. `test/threadline/ci_topology_contract_test.exs` was the only hit referencing `bench_compile`/`MIX_ENV`, but its assertions (`bench_compile_errors/3`) pin the `mix.exs`/`ci.yml` *command* content (e.g. `verify_bench_compile/1 must unset MIX_ENV`, `must not set MIX_ENV=`), not the `CONTRIBUTING.md` prose — no test pins the doc text itself, so the wording was free to change.

After editing, ran:
- `mix format --check-formatted` — clean, no diff
- `mix test test/threadline/ci_topology_contract_test.exs` — 22 tests, 0 failures

## Skipped Issues

None — all findings in scope were fixed.

---

_Fixed: 2026-09-30T00:00:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 2_
