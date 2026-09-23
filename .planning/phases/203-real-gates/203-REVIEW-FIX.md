---
phase: 203-real-gates
fixed_at: 2026-09-23T00:00:00Z
review_path: /Users/jon/projects/threadline/.planning/phases/203-real-gates/203-REVIEW.md
iteration: 1
findings_in_scope: 2
fixed: 2
skipped: 0
status: all_fixed
---

# Phase 203: Code Review Fix Report

**Fixed at:** 2026-09-23
**Source review:** /Users/jon/projects/threadline/.planning/phases/203-real-gates/203-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 2 (WR-01, WR-02; fix_scope = critical_warning, so IN-01..IN-07 were not attempted)
- Fixed: 2
- Skipped: 0

**Where verification ran:** in the main checkout (`/Users/jon/projects/threadline`), at the caller's instruction. No worktree was used.

## Fixed Issues

### WR-01: The credo config-shape contract does not pin `files:`, `plugins:` or `requires:`

**Files modified:** `test/threadline/credo_config_contract_test.exs`
**Commit:** 151f6efb
**Applied fix:** Added the test "the non-checks scaffolding equals upstream except strict". It evaluates `deps/credo/.credo.exs` and checks the following against it:
- The top-level keys are identical (`[:configs]`).
- `name` is `"default"`, and `plugins` and `requires` are both `[]`.
- `files` equals upstream.
- Every non-`checks` key except `strict` equals upstream.

The review's sketch was adapted in two ways:
- Regexes are normalized to `{source, opts}` before comparing. A compiled `re_pattern` is not guaranteed to compare equal across OTP releases.
- `strict` is pinned to `true` as the one explicit divergence (upstream ships `false`). A comment explains why.

I checked the real shapes first. Once `checks` and `strict` are dropped, the upstream and project configs are identical: `name`, `files`, `plugins`, `requires`, `parse_timeout` and `color` all match.

**Verification:**
- `mix test` on the file: 16 tests, 0 failures.
- Mutation checks, each of which made the test fail with 1 failure:
  - drop `"test/"` from `included:`
  - add `~r"/operator_surface/"` to `excluded:`
  - add a `plugins:` entry
  - change `parse_timeout`
- `.credo.exs` was restored after the mutations, and `git diff` was clean.
- `mix format --check-formatted`, `mix credo --strict` (no issues) and the source-comment location contract all passed.

### WR-02: The new `mix verify.xref_cycles` CI step is not pinned by any contract test

**Files modified:** `test/threadline/ci_topology_contract_test.exs`
**Commit:** 9eb0056d
**Applied fix:** Added the test "verify-test job runs the xref cycle gate unconditionally before the suite". It is scoped to the `verify-test` job block rather than the whole file, and uses the existing `workflow_step/2`, `position/2` and `ordered_positions?/1` helpers. It asserts that the "Verify no compile-connected xref cycles" step:
- has `run: mix verify.xref_cycles`
- has no step-level `if:`
- has no `continue-on-error:`
- runs after `mix compile --warnings-as-errors` and before `mix verify.test`

**Verification:**
- `mix test` on the file: 19 tests, 0 failures.
- Mutation checks, each of which made the test fail with 1 failure:
  - delete the step
  - add `if: false`
  - add `continue-on-error: true`
- `ci.yml` was restored after the mutations, and `git diff` was clean.
- Format, credo and the location contract all passed.

---

_Fixed: 2026-09-23_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
