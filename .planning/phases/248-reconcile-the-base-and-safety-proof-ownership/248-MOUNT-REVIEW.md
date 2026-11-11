---
phase: 248-reconcile-the-base-and-safety-proof-ownership
reviewed: 2026-11-11T02:14:32Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - lib/threadline/operator_surface/router.ex
  - test/threadline/operator_surface/router_test.exs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
  necessity: 0
status: clean
---

# Phase 248 Mount Correction Review

**Scope:** Final recheck of the mount authorization callback normalization and guarded-clause arity changes in `lib/threadline/operator_surface/router.ex` and `test/threadline/operator_surface/router_test.exs`. Phoenix LiveView route metadata and lifecycle handling were read to verify the integration boundary.

**Final source identity:** child worktree HEAD `1149e817058f25858701cf8756eaf98275fbb72b`; `router.ex` SHA-256 `9ed3e3b394cb5127ea9e099080902529bb8643bd9f371aba03f2664b35a6f7a0`; `router_test.exs` SHA-256 `892dae5c0ca25821443bebfa8b1062cd7a6766bb88910322eb4f09b87235816c`. The child worktree was clean when checked.

**Summary:** Both findings from the initial review are resolved in the final source. The regression tests now compile actual Phoenix routers, inspect the stored Auth lifecycle hook, and verify callback execution only when that hook runs. Qualified external captures remain unchanged, and guarded unary callbacks compile while guarded multi-argument callbacks receive the actionable mount error. The fix report records passing focused, operator-surface, and format checks; these checks were not rerun during this targeted recheck.

## Resolved Findings (Historical IDs)

### CR-01: Accepted local short captures failed during Phoenix router expansion — RESOLVED

**Original classification:** BLOCKER (Critical)  
**Fix commit:** `e4694ebbb88a8315f78b1a468bcc41f171de3fc4`

**Original finding:** The mount accepted unary short captures such as `&authorize(&1)` and local named captures such as `&authorize/1`, but left them as local callbacks in the router options.

**Mechanism correction:** The fix report records the observed pre-fix failure as `undefined function authorize/1` while expanding a real Phoenix router, before route serialization. The initial report overstated `Macro.escape(routes)` as the observed failure point. The final code also normalizes the callbacks into generated remote captures, which can be retained in Phoenix route metadata.

**Verification:** `normalize_authorize_fn/2` lowers local named captures and unary short captures to a generated remote callback (`router.ex:172-212`). Tests compile Phoenix routers for both forms, retrieve the Auth hook from `Phoenix.Router.routes/1`, assert the callback has not run before hook invocation, then invoke the stored hook and observe the callback (`router_test.exs:412-418, 486-532`). The existing qualified capture `&__MODULE__.auth/1` still compiles (`router_test.exs:95-109`), and opaque callback expansion still asserts no compile-time invocation (`router_test.exs:358-390`).

### WR-01: Guarded multi-argument callbacks were miscounted as unary — RESOLVED

**Original classification:** WARNING  
**Fix commit:** `f00b2b5e3a2929a63fdac26fc435e1139bf711a3`

**Original finding:** Guarded callback parameters are grouped inside the `:when` AST node, so counting the outer argument list treated a multi-argument callback as unary.

**Verification:** `authorize_fn_clause_arity/1` now counts patterns inside the `:when` node, excluding the guard expression (`router.ex:229-239`). The test matrix confirms a guarded unary callback compiles and a guarded multi-argument callback fails at the mount call with the expected authorization diagnostic (`router_test.exs:91-93, 393-410`).

## Recorded Verification

The committed [248-MOUNT-FIXES.md](/Users/jon/projects/threadline/.claude/worktrees/v148-admin-orchestrator/.claude/worktrees/agent-p248-02-1794358771/.planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-MOUNT-FIXES.md) records exit 0 for the focused router/auth/export/theme/scope set (85 tests), the operator-surface suite (843 tests), and `mix verify.format`. These results are carried forward from that report; this recheck did not run product tests or Mix commands.

No open findings remain in this targeted mount review. This report does not certify unrelated Phase 248 requirements.
