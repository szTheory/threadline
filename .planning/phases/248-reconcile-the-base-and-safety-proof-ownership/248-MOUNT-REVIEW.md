---
phase: 248-reconcile-the-base-and-safety-proof-ownership
reviewed: 2026-11-11T01:39:49Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - lib/threadline/operator_surface/router.ex
  - test/threadline/operator_surface/router_test.exs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
  necessity: 0
status: issues_found
---

# Phase 248 Mount Correction Review

**Scope:** `lib/threadline/operator_surface/router.ex` and `test/threadline/operator_surface/router_test.exs`, plus the Phoenix LiveView/Phoenix router option path and Elixir function serialization behavior in the child worktree.

**Source identity:** child worktree HEAD `814057583b28aab25c0e97a116f3491b29121494`; `router.ex` SHA-256 `c63b88acad976f7529136abec9744cd604b5f864f30ea985f07ca908ef21cadc`; `router_test.exs` SHA-256 `3c383eec17f572baa9c1ac376abcf5677aa85bfdcdba3a3ee18f8bb714ed1211`.

**Summary:** The review found one supported unary callback form that cannot be serialized into Phoenix route metadata, and one guarded multi-argument callback shape that bypasses the intended arity check and produces an unrelated generated-function compile error. The tuple-literal rejection and remote generated callback used for inline `fn` values are present in this source snapshot. No necessity finding was warranted: the authorization and callback serialization checks address real host integration boundaries. No Mix commands or product tests were run.

## Critical Issues

### CR-01: Accepted local short captures fail during Phoenix route serialization

**Classification:** BLOCKER (Critical)  
**File:** `lib/threadline/operator_surface/router.ex:159-169`

**Issue:** The arity checker accepts valid unary short captures such as `authorize_fn: &authorize(&1)` and unqualified named captures such as `authorize_fn: &authorize/1`. `normalize_inline_authorize_fn/2` only rewrites literal `fn ... end` ASTs (lines 175-186), so these captures remain local functions in the `on_mount` options. Phoenix stores those options in each LiveView route's `:phoenix_live_view` metadata (`deps/phoenix_live_view/lib/phoenix_live_view/router.ex:391`) and later emits `__routes__/0` by applying `Macro.escape(routes)` (`deps/phoenix/lib/phoenix/router.ex:554`). Elixir only accepts empty-environment external function values for AST serialization; local captures fail that check (`lib/macro.ex:897-902`). The mount therefore passes Threadline's explicit authorization guard but fails when Phoenix compiles route metadata. Qualified external captures such as `&MyApp.Audit.authorize_operator/1` do not have this serialization problem.

**Acceptance property:** A usable unary short capture and a usable local named capture must compile through Phoenix router generation and be invoked only at request/mount time. The test should also retain the no-compile-time-callback-execution assertion.

**Minimal fix:** Normalize accepted local short and local named captures into a generated remote callback on the host router before inserting the callback into `opts`, as is done for inline anonymous functions. Keep already-qualified external captures unchanged.

## Warnings

### WR-01: Guarded multi-argument callbacks are miscounted as unary

**Classification:** WARNING  
**File:** `lib/threadline/operator_surface/router.ex:151-156, 191-199`

**Issue:** Elixir represents `fn socket, conn when is_map(socket) -> ... end` with one outer clause argument: a `{:when, ..., [socket, conn, guard]}` node. The check at line 154 counts the outer list and treats it as arity one. The converter only recognizes the two-item unary guard form at lines 193-195; this multi-argument form falls through and is emitted as a malformed function head (`generated_auth(when(socket, conn, is_map(socket))`), yielding a compiler error about `when/3` in a match instead of Threadline's mount authorization diagnostic.

**Acceptance property:** A statically recognizable guarded callback with two or more parameters must be rejected at the mount call with the actionable one-argument authorization diagnostic; a guarded one-argument callback must continue to compile.

**Minimal fix:** Count the parameter patterns inside the `:when` node, excluding its guard expression, and only lower guarded clauses when exactly one parameter is present. Add guarded unary and guarded multi-argument cases to the compile matrix.

## Resolved checks

- Literal tuple values are now recognized as non-functions and rejected by the mount guard.
- Inline anonymous callbacks are rewritten to a generated remote capture, which is compatible with Phoenix route-option serialization. The generated helper's export is an internal implementation detail needed for this serialization path; this review does not treat it as a public API defect.
- The callback body remains in a generated function definition; the macro's guard does not invoke it while compiling the mount.
