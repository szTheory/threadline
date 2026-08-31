---
phase: 198-green-bringup
reviewed: 2026-08-30T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex
  - examples/threadline_phoenix/test/threadline_phoenix/demo/advisory_lock_pinning_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs
findings:
  critical: 0
  warning: 1
  info: 1
  total: 2
status: issues_found
---

**Note:** The round-5 review is preserved unchanged at
`.planning/phases/198-green-bringup/198-REVIEW-round5.md`. This file (`198-REVIEW.md`) now holds the
round-6 gap-closure review (plans 198-38..198-40; 198-39/198-40 were docs-only, so only 198-38 touched
source).

# Phase 198 (green-bringup, gap-closure round 6): Code Review Report

**Reviewed:** 2026-08-30
**Depth:** standard (diff `1bda5d1c..HEAD`, plan 198-38)
**Files Reviewed:** 4
**Status:** issues_found (1 Warning, 1 Info — no Critical)

## Summary

Round 6's central claim — that CR-01 (round-5's unresolved Critical: the nested demo-seed advisory
lock was not pinned to one physical connection) is fixed **at cause**, not merely reworded — holds up
under direct tracing through the Ecto/DBConnection source, not just under trust of the plan's own
narrative.

**CR-01 verified fixed at cause.** `Reset.with_demo_lock/1` now wraps `acquire_demo_lock/0`, the
caller's `fun.()`, and the `pg_advisory_unlock` release inside one `Repo.checkout(fn -> ... end,
timeout: :infinity)` call (`reset.ex:80-98`). I traced this through
`deps/ecto_sql/lib/ecto/adapters/sql.ex`: `Ecto.Adapters.SQL.checkout/3` →
`checkout_or_transaction/4` stores the checked-out `%DBConnection{}` reference in the *process
dictionary* under `{Ecto.Adapters.SQL, pool}` (`put_conn/2`) before invoking the callback, and — this
is the load-bearing fact — a *nested* call to `Repo.checkout/2` (or `Repo.transaction/2`) from the
same process resolves `get_conn_or_pool/2` against that same process-dictionary entry first
(`sql.ex:1482-1493`) rather than re-checking-out from the pool. So when `fun.()` synchronously calls
`Demo.Seed.run/0`, which calls `Reset.with_demo_lock/1` again, the nested `Repo.checkout/2` reuses the
outer physical connection — it does not attempt a second pool checkout that could land on a different
backend. The intervening `Repo.transaction/1` calls the seed pipeline performs (`Seed.Personas.run/1`
etc.) go through the same process-dictionary lookup, so they run as nested transactions on the same
pinned connection rather than releasing the pin — exactly what the new test's "intervening
`Repo.transaction/1`" assertion checks. `Demo.Seed` no longer has a second, independently maintained
copy of the guard (`grep -c 'defp with_demo_lock' seed.ex` → `0`, confirmed by direct read); it
delegates via `Reset.with_demo_lock(fn -> ... end)` (`seed.ex:29`). Neither `mix demo.reset` nor `mix
demo.seed`'s task modules (`lib/mix/tasks/demo.reset.ex`, `lib/mix/tasks/demo.seed.ex`) acquire the
lock a third time — both simply call the already-guarded `Reset.run/1` / `Seed.run/0`. Release is
guaranteed on every exit path from `fun.()`, including exceptions, by the `try/after` inside the
checkout closure; if `acquire_demo_lock/0` itself raises (the bounded-retry timeout), that's correctly
*outside* the `try`, since no lock was ever held in that case, so no spurious unlock is attempted. No
`Task.async`/`spawn`/`send` was found anywhere in `lib/threadline_phoenix/demo/`, so there is no path
that escapes the checked-out process and its process-dictionary pin.

**The regression test is a real falsifier, not a tautology, per the plan's own honest disclosure.**
`AdvisoryLockPinningTest`'s first test (`Repo.checked_out?()` true at the innermost point of a nested
`with_demo_lock/1` call) is the deterministic gate, and I confirmed by direct reasoning through the
same `sql.ex` source that on the pre-fix tree (no `Repo.checkout/2` at all, every statement an
independent `Repo.query!/2`) `Repo.checked_out?()` would correctly read `false` throughout — matching
the plan's own recorded red output. The second test's `pg_backend_pid()` identity assertion is
correctly described in the plan/summary as *corroborating, not primary* — it is disclosed as having
passed even pre-fix in one observed run (single sequential process usually reuses a connection from a
small pool), which the executor reported honestly rather than suppressing. That non-determinism is a
real property of the pre-fix code (it fails intermittently, not always), and the structural assertion
is what actually encodes the defect deterministically — this is a legitimate, disclosed design choice,
not a hidden weakness. The second test does still add real coverage beyond redundancy: its final
`Repo.checkout(fn -> pg_try_advisory_lock ... end)` block, run *after* the outer guard has returned,
proves the release actually reached the holding backend (a fresh acquire from a fresh checkout
succeeds) — this specifically falsifies the "nested inner release strands the lock" half of CR-01's
failure mode, which the structural test alone does not cover.

**IN-01 verified fixed, comment-only.** `git diff` on `walkthrough_evidence_test.exs` shows exactly one
changed line, `label label` → `label`, no assertion or executable line touched.

**Residual risk found in the new test's `Sandbox.mode(Repo, :auto)` mid-suite switch — see WR-01
below.** This is not a proven regression (I could not reproduce a failure, and the plan's own repeated
`mix test` / `mix verify.example` runs report `0 failures`), but it rests on an ExUnit ordering
guarantee (`async: false` modules run only after all `async: true` modules have finished) that the test
file's own comment does not name, while `Ecto.Adapters.SQL.Sandbox`'s own docs carry an explicit
warning about exactly this operation that the comment also does not cite.

---

## Warnings

### WR-01: Sandbox mode is switched process-globally mid-suite; the safety argument in the test's moduledoc doesn't name the actual mechanism the fix depends on

**File:** `examples/threadline_phoenix/test/threadline_phoenix/demo/advisory_lock_pinning_test.exs:22-24,32-37`

**Issue:** `Ecto.Adapters.SQL.Sandbox.mode/2`'s own docs (`deps/ecto_sql/lib/ecto/adapters/sql/sandbox.ex:497-500`) state: *"Whenever you change the mode to `:manual` or `:auto`, all existing connections are checked in. Therefore, it is recommended to set those modes before your test suite starts, as otherwise you will check in connections being used in any other test running concurrently."* This test module calls `Sandbox.mode(Repo, :auto)` in `setup` and `Sandbox.mode(Repo, :manual)` in `on_exit` — i.e., mid-suite, not before it starts — which is precisely the case the library's own doc warns about.

This is safe in practice **only** because ExUnit guarantees `async: false` modules run strictly after every `async: true` module has finished, so no other test process is holding a sandboxed connection open when this module's `setup`/`on_exit` fire, and ExUnit never runs two `async: false` modules concurrently with each other either. That is the actual mechanism the plan's own threat model (T-198-38-04) and this file's moduledoc rely on for safety — but the moduledoc/comment states only "the sandbox mode is process-global for the repo... so this module is `async: false`... so no other module inherits `:auto` mode" (lines 22-24, 32-37). That phrasing describes *inheriting a mode setting*, which understates the real risk documented by `Sandbox.mode/2` itself: a concurrently-running test's connection being **forcibly checked in out from under it**, not merely "inheriting" a mode value. A future reader relying on this comment to reason about safety would not learn the actual invariant being depended on (ExUnit's async-then-sync scheduling order), nor that this file is, per `grep -rln 'Sandbox.mode' test`, the *only* place in this test suite other than `test_helper.exs`'s one-time startup call that invokes `Sandbox.mode/2` mid-run — there is no established precedent elsewhere in this codebase to cross-check against.

This did not fail in the plan's own repeated `mix test`/`mix verify.example 0 failures` runs, and is not a proven regression; it is a maintainability/robustness gap in the safety argument as documented, which is exactly the kind of implicit cross-module invariant that's easy to violate in a future refactor (e.g. a test-runner config change that partitions or reorders test execution, or a future `async: true` addition elsewhere that happens to still be finishing when this module's `setup` runs under a different ExUnit version's scheduling).

**Fix:** Update the moduledoc/comment to name the actual invariant depended on, e.g.:

```elixir
# The sandbox mode is process-global for the repo, and Ecto.Adapters.SQL.Sandbox's
# own docs warn that switching :auto/:manual mid-suite force-checks-in every
# connection any OTHER concurrently-running test process currently owns — not
# merely that a mode setting is "inherited." This module is therefore `async:
# false`, relying on ExUnit's guarantee that async: false modules run only after
# every async: true module has finished (and never concurrently with another
# async: false module), so no other test process holds a connection open while
# this module's setup/on_exit switch the mode. :manual is restored in on_exit so
# the next module to run resumes ExUnit's normal per-test sandbox ownership.
```

Optionally, add a `mix test`/`--seed`-stability comment noting this assumption would need
re-verification if the suite ever adopts test partitioning (`--partitions`) or a different ExUnit
scheduler behavior.

---

## Info

### IN-02 (round 6 numbering; distinct from round-5's IN-02 namespacing item): `Repo.checkout/2`'s `timeout: :infinity` silently also removes the pool's own checkout-queue timeout for the whole guarded region, including the entire seed pipeline

**File:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex:79-98`

**Issue:** `:timeout` passed to `Repo.checkout/2` is not a query timeout — it is `DBConnection.run/3`'s pool checkout/queue timeout, and it now bounds the entire guarded region (lock retry loop **plus** `Demo.Tables.truncate_sql()` **plus** the full `Demo.Seed.run/0` pipeline, since that whole body runs inside the same checkout closure via `fun.()`). Setting it to `:infinity` is a deliberate, documented tradeoff (the docstring correctly explains why: the 45s bounded lock-retry loop must not be truncated by the pool's 15s default), but one side effect worth naming explicitly is that if the seed pipeline itself ever hangs (e.g., a runaway query, a lock wait against unrelated app traffic sharing the same 10-connection pool), there is now no pool-level backstop timeout for that hang at all — only whatever timeout, if any, the individual `Repo.transaction/1` calls inside the pipeline carry. This is not a regression introduced carelessly (it's the necessary consequence of the correct fix), but the docstring's framing ("the lock-retry loop is still the thing that actually bounds how long this function can run," `reset.ex:57-59`) is true only for the *lock acquisition* phase, not for the pipeline body once the lock is held. Purely a documentation-completeness note.

**Fix:** Consider a sentence in the docstring clarifying that `timeout: :infinity` removes the pool-checkout backstop for the whole guarded region including the seed pipeline body, not only the lock-retry wait — so a future reader tuning pipeline reliability knows where the actual bound (or lack of one) now lives.

---

_Reviewed: 2026-08-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
