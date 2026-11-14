---
phase: 248-reconcile-the-base-and-safety-proof-ownership
plan: "02"
type: targeted-code-review-fixes
findings: 2
status: fixed
starting_head: 9d7c65095bcbbff52d9cadee5cd61ff49238ccd5
---

# Phase 248 Plan 02: Mount Review Fixes

This report records only the two supplied mount-review findings. The retained GSD worktree started at `9d7c65095bcbbff52d9cadee5cd61ff49238ccd5` on branch `worktree-agent-p248-02-1794358771`; no parent checkout, state file, roadmap, issue, remote, or published artifact was changed.

## Source identities

The immutable review input identified source `814057583b28aab25c0e97a116f3491b29121494`, with these SHA-256 digests:

| File | Review input | Retained starting tree | Final fixed tree |
| --- | --- | --- | --- |
| `lib/threadline/operator_surface/router.ex` | `c63b88acad976f7529136abec9744cd604b5f864f30ea985f07ca908ef21cadc` | `c63b88acad976f7529136abec9744cd604b5f864f30ea985f07ca908ef21cadc` | `9ed3e3b394cb5127ea9e099080902529bb8643bd9f371aba03f2664b35a6f7a0` |
| `test/threadline/operator_surface/router_test.exs` | `3c383eec17f572baa9c1ac376abcf5677aa85bfdcdba3a3ee18f8bb714ed1211` | `fc12927368cbcf9d2a2958c73329e2e5d7b76cac962d1b7dd40e96c3bf2a6c7e` | `892dae5c0ca25821443bebfa8b1062cd7a6766bb88910322eb4f09b87235816c` |

The router source matched the review exactly. The test source had advanced in the retained tree after the review snapshot through the existing behavioral-test commit `80f3c0be`; the tests below were added to that current source. Existing author changes were preserved.

## CR-01: Normalize local unary captures before Phoenix route serialization

**Status:** Fixed. **Commit:** `e4694ebbb88a8315f78b1a468bcc41f171de3fc4` — `fix(248-02): normalize local mount authorizers for Phoenix`.

The macro now lowers supported local named captures such as `&authorize/1` and unary short captures such as `&authorize(&1)` into generated remote callbacks on the host router. Qualified external captures are left intact. The generated helper keeps callback execution deferred until the LiveView mount hook runs.

**Regression evidence before the source fix:** `mix test test/threadline/operator_surface/router_test.exs` exited 2 with 15 tests and 2 failures. Both new target cases failed while compiling a real Phoenix router because the local `authorize/1` form could not be expanded into the router's mount options (`undefined function authorize/1`).

**Verification after the source fix:** the same focused command exited 0 with 15 tests and no failures. Each regression compiles a Phoenix router, reads the `:phoenix_live_view` session metadata from `Phoenix.Router.routes/1`, and invokes the `Threadline.OperatorSurface.Auth` lifecycle hook stored there. The tests assert no callback message exists before invocation and observe the callback message after invocation. The existing no-compile-time-callback-execution assertion remains in place.

## WR-01: Count guarded callback parameters correctly

**Status:** Fixed. **Commit:** `f00b2b5e3a2929a63fdac26fc435e1139bf711a3` — `fix(248-02): validate guarded authorizer arity`.

Guarded function clauses now count the patterns in the `:when` node and exclude its final guard expression. The converter lowers a guarded unary callback with one parameter; a guarded callback with multiple parameters is rejected by the existing mount guard before generated code is emitted.

**Regression evidence before the source fix:** `mix test test/threadline/operator_surface/router_test.exs` exited 2 with 17 tests and 1 failure. The new guarded multi-argument case produced a generated `when/3` match-head compile error instead of the expected actionable mount diagnostic.

**Verification after the source fix:** the focused router command exited 0 with 17 tests and no failures. It includes both the guarded unary compile case and the guarded multi-argument diagnostic assertion.

## Superseding verification

After both fixes, checks ran serially in managed noninteractive sessions, with each command's output logged and its process exit status retained:

| Command | Result |
| --- | --- |
| `mix test test/threadline/operator_surface/router_test.exs test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/theme_auth_plug_test.exs test/threadline/query/scope_fail_closed_test.exs` | Exit 0; 85 tests, 0 failures |
| `mix test test/threadline/operator_surface` | Exit 0; 843 tests, 0 failures |
| `mix verify.format` | Exit 0 |

No tests or shared-database suites ran concurrently. No dependency, lockfile, route, host API, runtime brand, or unrelated source changes were made.

## Scope and remaining status

Both supplied findings are fixed and verified. There is no blocker within this targeted review-fix pass. This report does not certify the full Phase 248 or other plan requirements; those remain with their existing phase verification ownership. No `STATE.md` or `ROADMAP.md` update was made.
