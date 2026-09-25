---
phase: 198-green-bringup
reviewed: 2026-08-30T00:00:00Z
depth: standard
files_reviewed: 19
files_reviewed_list:
  - lib/threadline/operator_surface/presentation.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - test/threadline/operator_surface/presentation_test.exs
  - test/threadline/operator_surface/copy_contract_test.exs
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex
  - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex
  - examples/threadline_phoenix/test/support/walkthrough_case.ex
  - examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs
  - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-135-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-177-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
findings:
  critical: 1
  warning: 1
  info: 1
  total: 3
status: issues_found
---

# Phase 198 (green-bringup, gap-closure round 5): Code Review Report

**Reviewed:** 2026-08-30
**Depth:** standard (diff `11f1c883..HEAD`, plans 198-30 through 198-37)
**Files Reviewed:** 19
**Status:** issues_found

## Summary

Round 5 is, on the whole, genuinely honest gap-closure work, and the majority of it checks out under direct re-derivation rather than trust in the round's own claims:

- **CR-01 (round 4, `export_status_live.ex` duplicate label function)** — verified **actually fixed**, not merely realigned. The private `defp export_job_status_label/1` is gone; the template calls the new public `Presentation.export_status_label/2`; I hand-traced every branch (`Queued`/`Processing`/`Failed`/`Export expired`/`File unavailable`/fallback) against the deleted private function's old logic and they are identical, including the `nil`-status and `nil`/absent-`expires_at` edge cases and the exact-equality expiry boundary (`DateTime.compare(...) != :gt`, unchanged). `export_action_label/2` is correctly retained-with-reason per the maintainer's `198-34-DECISION.md`, with an honest `@doc` explaining why it has no in-tree caller.
- **CR-02 (round 4, vacuous coverage-snapshot assertion)** — verified fixed. `coverage_live.ex:291-296` renders `<dt>Covered</dt><dd><%= @snapshot.covered_count %></dd>` unconditionally; the new regex `~r/<dt>Covered<\/dt>\s*<dd>[1-9]\d*<\/dd>/` correctly requires a strictly-positive leading digit, which a `0` count cannot satisfy. This is a real fix.
- **CR-03 (round 4, tautological `subject_ref` assertion)** — verified fixed. The manifest-literal pin (`assert subject_ref == %{"policy" => "walk-demo-redaction-policy"}`) is restored ahead of the round-trip assertion, and the round-trip assertion's now-honest comment correctly documents that it is non-load-bearing by construction (the query filters on the same value).
- **CR-04 / WR-07 (round 4, phase-177 group-story floor and filter-applied proof)** — verified fixed and verified correct against source: `stress_fixtures.ex` declares exactly 12 `"group.*"` entries; I confirmed all four of `REQUIRED_GROUP_STORY_IDS` (`group.page-header.current`, `group.modal-destructive.current`, `group.drawer-form.reference`, `group.offline.current`) are literal ids in that list, and `GROUP_STORY_FLOOR = 12` matches the declared count exactly.
- **WR-08 / WR-09 (round 4, dropped `<nav>` landmark assertion, dropped actor-type assertion)** — both verified fixed and verified correct against source (`surface_header.ex:57` renders a `<nav aria-label="Audit navigation">`; `actor_live.ex:156` + `ui.ex:441-450` render `<div class="tl-kv__row"><dt class="tl-kv__key">Kind</dt><dd class="tl-kv__value">user</dd></div>`, which the restored `.tl-kv__row`/`.tl-kv__key`/`.tl-kv__value` selectors match exactly).
- **WR-11 (round 4, order-dependent `<details>` click)** — verified fixed with a real idempotent read-before-click and a state assertion.

However, this round's own headline mechanism — the advisory-lock refactor that was supposed to close round-4's WR-01/WR-02 (session-scoped lock leaking on abnormal exit, guarding only some entry points) — introduces a new correctness bug of the same shape it was meant to fix. See CR-01 below.

---

## Critical Issues

### CR-01: The "reentrant on the same session" claim for the nested demo-seed advisory lock is not guaranteed by Ecto's connection pool, and the untested path is exactly the one this round shipped

**File:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex:57-96`, `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex:9-19,53-91`

**Issue:** `Demo.Reset.run/1` wraps its body in `with_demo_lock/1` (`reset.ex:83-93`), whose `fun` calls `Demo.Seed.run()` (`reset.ex:112`). `Demo.Seed.run/0` itself unconditionally calls its own `with_demo_lock/1` (`seed.ex:19-24`), which tries to acquire the *same* advisory lock pair (`Reset.advisory_lock_classid()`/`objid()`) a second time. `seed.ex:9-16`'s docstring states this is safe because Postgres advisory locks are "reentrant on the same session, so calling this from within `Reset.run/1` (which has already taken the lock) succeeds immediately and cannot deadlock."

That claim depends on the outer acquire (`reset.ex`'s `acquire_demo_lock`) and the inner acquire (`seed.ex`'s `acquire_demo_lock`) running on the **same Postgres backend connection** — Postgres advisory-lock reentrancy is per-session (per-backend), not per-call. Neither `with_demo_lock/1` implementation pins a connection: each is a bare sequence of independent `Repo.query!/2` calls (`SET lock_timeout`, `SELECT pg_try_advisory_lock`, the caller's work, `SELECT pg_advisory_unlock`), and outside an explicit `Repo.transaction/2` or `Ecto.Adapters.SQL.Sandbox` checkout, every `Repo.query!/2` call independently checks a connection out of and back into the DBConnection pool. Ecto/DBConnection do not guarantee that sequential, non-transactional queries from one process reuse the same physical connection.

Both real invocation paths of this code run *without* any such pinning:
```elixir
# lib/mix/tasks/demo.reset.ex
Mix.Task.run("app.start")
ThreadlinePhoenix.Demo.Reset.run(skip_assert: true)
```
`config/dev.exs:18` and `config/runtime.exs:37,54` set `pool_size: 10` for exactly this environment. So under real `mix demo.reset` / `mix demo.seed` usage — the two entry points this round's own docstring at `reset.ex:34-36` names as needing coverage — the outer lock acquired by `Reset.with_demo_lock/1` and the inner (re-)acquire attempted by `Seed.with_demo_lock/1` can land on two different backend sessions. When they do:

1. The inner `pg_try_advisory_lock` sees the lock held by a *different* session and returns `false` (not an error — it's non-blocking by design), so `do_acquire_demo_lock/1` sleeps and retries for up to `90 * 500ms = 45s`, then raises: `"demo seed lock: timed out ... — another session is still holding the demo seed/reset lock"` — a false-positive crash, since the "other session" is this same call graph's own outer lock.
2. Even when the inner acquire happens to land on the same connection as the outer one (Postgres correctly treats this as reentrant), the matching inner `pg_advisory_unlock` call is itself a separate, independently pooled `Repo.query!/2` call. If *that* one lands on a different connection than the one actually holding the lock, `pg_advisory_unlock` is a silent no-op (it only unlocks locks held by the calling session) — the lock is left held on the original connection, which is then returned to the idle pool. It will not be released until that specific physical connection is closed or the outer `with_demo_lock/1`'s own `after`-block unlock happens to land on it, meaning the lock can leak into the pool and cause the *next* `mix demo.reset` to reproduce (1) — precisely the "session-scoped lock leak poisons a pooled connection" failure mode (round-4 WR-01) this round's SUMMARY claims to have closed, reintroduced through the pooling behavior of the fix itself rather than an ExUnit process kill.

This is why the round's own test suite cannot catch it: every test exercising `Reset.run/1`/`Seed.run/0` (`demo_reset_test.exs:41-64`, `demo_contract_test.exs`, `walkthrough_case.ex:17-19`) wraps the call in `Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn -> ... end)`. `unboxed_run/2` (`ecto_sql/lib/ecto/adapters/sql/sandbox.ex:624-633`) calls `checkout(repo, sandbox: false)`, which pins the calling process to one physical connection via `DBConnection.Ownership` for the whole block — so in every test, the nested acquire/release pair is guaranteed to land on the same connection as the outer one, masking exactly the scenario that breaks under the real `mix demo.reset`/`mix demo.seed` CLI paths (`pool_size: 10`, no Sandbox, no transaction wrapping).

**Failure scenario:** A developer or CI job runs `mix demo.reset` against a running Phoenix app (`app.start` boots the full supervision tree, so other connections in the 10-connection pool may be in flight from Endpoint/LiveView/health-check traffic). The nested `Demo.Seed.run()` acquire happens to land on a different pooled connection than `Demo.Reset.run/1`'s own acquire. `mix demo.reset` hangs for 45 seconds and then crashes with `"another session is still holding the demo seed/reset lock"` — a confusing, self-inflicted false positive — or, worse, silently leaves the lock held on an idle pooled connection, so the *next* `mix demo.reset` reproduces the same failure deterministically until that connection cycles out of the pool.

**Fix:** Pin one connection for the entire guarded region instead of relying on incidental pool behavior — e.g., wrap `with_demo_lock/1`'s body in `Repo.transaction/2` and use the transaction-scoped `pg_advisory_xact_lock` (auto-released on commit/rollback, no manual unlock needed, and reentrant *within* a transaction by construction):
```elixir
def with_demo_lock(fun) do
  Repo.transaction(
    fn ->
      acquire_demo_lock()
      fun.()
    end,
    timeout: :infinity
  )
  :ok
end
```
or, if the existing design's multiple independent `Repo.transaction/1` calls inside `fun` must be preserved (per the module's own stated reason for avoiding one outer transaction), pin a single connection explicitly with `Repo.checkout/2` around the acquire+work+release sequence instead of transaction-wrapping it, and make `Demo.Seed.run/0` accept an option (e.g. `already_locked?: true`) so `Demo.Reset.run/1` can skip the nested acquire entirely rather than relying on incidental session reentrancy.

---

## Warnings

### WR-01: `SET lock_timeout` is set on a connection that is not guaranteed to be the one used for the following query, making the "defense in depth" comment's guarantee illusory

**File:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex:70-75`, `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex:63-68`

**Issue:** `acquire_demo_lock/1` issues `Repo.query!("SET lock_timeout = '45s'")` as its own independent, non-transactional query, then calls `do_acquire_demo_lock/1`, which issues a second independent `Repo.query!/2` for `pg_try_advisory_lock`. For the same connection-pooling reason as CR-01, these two calls are not guaranteed to run on the same backend session — the `SET lock_timeout` may silently apply to a connection that is never used again, while the connection that actually executes later queries in `fun.()` (including any blocking operation, however unlikely) runs with the default `lock_timeout` (typically unset/infinite). The comment at `reset.ex:71-73` describes this as bounding "any other blocking wait this connection might incur," but "this connection" is not a stable referent across the function.

**Fix:** Either drop the `SET lock_timeout` (it protects nothing today, since `pg_try_advisory_lock` never blocks and is the only query it precedes) or set it session-wide via `Repo.checkout/2` around the whole guarded region so "this connection" is actually one connection, consistent with the CR-01 fix.

---

## Info

### IN-01: Minor typo in the corrected coverage-snapshot comment

**File:** `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs:96`

**Issue:** The corrected comment explaining the CR-02 fix reads "...so a bare substring match on either label label passes..." — a duplicated word ("label label"). Purely cosmetic; does not affect the (correct) assertion it documents.

**Fix:** Remove the duplicated word.

---

_Reviewed: 2026-08-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
