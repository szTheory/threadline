# Round-6 Review Triage Ledger

**Phase:** 198-green-bringup, plan 198-38
**Source:** `198-REVIEW.md` (2026-08-30, standard depth, diff `11f1c883..HEAD`, plans 198-30 through
198-37), 3 findings (1 Critical, 1 Warning, 1 Info) — the two unresolved findings this round-6
gap-closure plan exists to close, plus one cosmetic one.
**Purpose:** give CR-01, WR-01 and IN-01 each a terminal, recorded disposition, following
`198-round5-review-triage.md`'s format. Round-5's own findings (`CR-01`..`CR-05`, `WR-01`..`WR-11`,
`IN-01`..`IN-04`, a disjoint id space from a prior REVIEW.md revision) are unaffected and already
terminally dispositioned in `198-round5-review-triage.md` — this ledger covers only the three findings
in the round-6 `198-REVIEW.md`.

## Mechanical completeness proof

```
$ grep -oE "(CR|WR|IN)-[0-9]{2}" .planning/phases/198-green-bringup/198-REVIEW.md | sort -u
CR-01
IN-01
WR-01
$ grep -oE "(CR|WR|IN)-[0-9]{2}" .planning/phases/198-green-bringup/198-round6-review-triage.md | sort -u
CR-01
IN-01
WR-01
```
Identical sets — no finding missing, none invented.

## Disposition counts

| Disposition | Count |
|---|---|
| `fixed` | 3 |
| `deferred` | 0 |
| `accepted` | 0 |
| `open` | 0 |
| **Total** | **3** |

## Ledger

| Finding | One-line restatement | Owning plan | Disposition | Verification citation |
|---|---|---|---|---|
| CR-01 | Nested demo-seed advisory-lock acquisition (`Demo.Reset.run/1` → `Demo.Seed.run/0`) had no connection pinning, so Postgres advisory-lock session reentrancy was not guaranteed under real pooled (`pool_size: 10`) usage | 198-38 | fixed | `Repo.checkout/2` now wraps the entire guarded region — `SET lock_timeout`, the `pg_try_advisory_lock` retry loop, `fun.()` (including any nested acquire), and `pg_advisory_unlock` — in `Demo.Reset.with_demo_lock/1` (`reset.ex:80-97`, commit `76dbc373`). `grep -c 'Repo.checkout(' reset.ex` → `1`. Falsified and re-proven by `advisory_lock_pinning_test.exs` (commit `709a87d8`): the structural assertion (`Repo.checked_out?()` true at the innermost point of a nested `with_demo_lock/1` call) was observed **RED** against pre-fix tree `1bda5d1c` (`Process.get(:outer_checked_out) == false`, assertion failure) and **GREEN** against post-fix tree `76dbc373` (`2 tests, 0 failures`). See "Red-then-green teeth proof" below for verbatim output. |
| WR-01 | `SET lock_timeout` was issued on a connection not guaranteed to be the one that later attempted the lock, making the "defense in depth" comment's guarantee illusory | 198-38 | fixed by the same change | Same `Repo.checkout/2` region as CR-01 — `SET lock_timeout` (`reset.ex:88`) and the retry loop's `pg_try_advisory_lock` call (`do_acquire_demo_lock/1`) now execute inside the identical checked-out connection, so the statement provably bounds the connection that subsequently attempts the lock. This is the same root cause as CR-01 (both are "the guarded region was not pinned to one connection"), so it received no independent fix — pinning the connection closes both simultaneously. Docstring restated at `reset.ex:46-59` to state the enforced property rather than an assumed one. |
| IN-01 | Duplicated word ("label label") in the CR-02 coverage-snapshot comment at `walkthrough_evidence_test.exs:96` (round-6 `198-REVIEW.md`'s IN-01 — unrelated to round-5's IN-01, a different finding about a screenshot-target element, already dispositioned in `198-round5-review-triage.md`) | 198-38 | fixed | `walkthrough_evidence_test.exs:99` corrected from "either label label passes" to "either label passes". `grep -c 'label label' walkthrough_evidence_test.exs` → `0`. Diff is comment-only: `git diff -- walkthrough_evidence_test.exs \| grep '^[-+][^-+]' \| grep -vc '^[-+]\s*#'` → `0`. `MIX_ENV=test mix test test/threadline_phoenix_web/walkthrough_evidence_test.exs` → `3 tests, 0 failures`. |

## Rejected alternative, recorded per this plan's objective

`198-REVIEW.md`'s CR-01 remedy offered two options: wrap the guarded region in `Repo.transaction/2`
using the transaction-scoped `pg_advisory_xact_lock` (auto-released on commit/rollback, no manual
unlock), or pin a single connection with `Repo.checkout/2`. The transaction-scoped variant is not
admissible here: `with_demo_lock/1`'s own docstring records that the demo pipeline issues many
independent, separately-committed database transactions by design (each producing its own distinct
audit transaction for the seeded fiction), and the guarded body also runs
`Demo.Tables.truncate_sql()`. Wrapping the whole pipeline in one outer transaction would collapse
every seeded audit transaction into a single Postgres transaction and change the shape of the seeded
audit trail that the walkthrough and demo-contract tests assert against. `Repo.checkout/2` was chosen
instead — it pins the connection, which is the whole of what CR-01/WR-01 require, while leaving each
inner transaction its own commit boundary. This rejection is recorded in the `with_demo_lock/1`
docstring itself (`reset.ex:61-69`) so a future reader does not re-litigate it.

## Structural change: one canonical guard (assumption-delta `promote`)

Per plan 198-38's `assumption_delta_decision`, `Demo.Seed` no longer maintains a second,
independently-maintained copy of the acquire/retry/release trio. `Demo.Seed.run/0` now delegates to
`Reset.with_demo_lock/1` directly:

```
$ grep -v '^\s*#' examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex | grep -c 'defp with_demo_lock'
0
$ grep -v '^\s*#' examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex | grep -c 'defp do_acquire_demo_lock'
0
$ grep -c 'Reset.with_demo_lock(' examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex
1
```

This eliminates the drift mechanism CR-01 exploited: two copies of a connection-scoping policy that
must agree, with nothing enforcing agreement, is exactly what `198-34-DECISION.md` already ruled
against for the export-status copy contract earlier in this phase.

## Red-then-green teeth proof (CR-01 regression test)

Pre-fix tree: `1bda5d1c` (round-5 gate-recording commit, HEAD before this plan's Task 1 commit).
Post-fix tree: `76dbc373` (this plan's Task 1 commit, `fix(198-38): pin demo lock critical section
to one connection`).

**RED — `MIX_ENV=test mix test test/threadline_phoenix/demo/advisory_lock_pinning_test.exs` against
`1bda5d1c`:**

```
Running ExUnit with seed: 676614, max_cases: 36

.

  1) test nested with_demo_lock/1 pins the whole guarded region to one checked-out connection (ThreadlinePhoenix.Demo.AdvisoryLockPinningTest)
     test/threadline_phoenix/demo/advisory_lock_pinning_test.exs:46
     Assertion with == failed
     code:  assert Process.get(:outer_checked_out) == true
     left:  false
     right: true
     stacktrace:
       test/threadline_phoenix/demo/advisory_lock_pinning_test.exs:59: (test)


Finished in 0.01 seconds (0.00s async, 0.01s sync)
2 tests, 1 failure
```

The structural assertion — the deterministic gate — failed exactly as CR-01 predicts: with no
`Repo.checkout/2`, `Repo.checked_out?()` is never `true` inside the guarded region, because every
`Repo.query!/2` call independently checks a connection out of and back into the pool rather than
pinning one for the block. (The second, identity-based test happened to pass on this run — consistent
with `198-REVIEW.md`'s own observation that "a single sequential process usually gets the same pooled
connection back," which is precisely why the identity test alone would be a weak, non-deterministic
regression gate and the structural assertion is required as the primary falsifier.)

**GREEN — same command against `76dbc373`:**

```
Running ExUnit with seed: 297284, max_cases: 36

..
Finished in 0.01 seconds (0.00s async, 0.01s sync)
2 tests, 0 failures
```

Both tests pass once `Repo.checkout/2` pins the whole guarded region.

## Full-suite confirmation (no assertion weakened, no leak)

- `cd examples/threadline_phoenix && MIX_ENV=test mix compile --warnings-as-errors` — exits `0`, no
  unused-module-attribute warning (the retry attributes/functions removed from `seed.ex` are gone
  entirely, not merely unused).
- `cd examples/threadline_phoenix && MIX_ENV=test mix test` — `111 tests, 0 failures` (the sandbox
  `:auto` mode override in the new test module did not leak into any other module).
- `mix verify.example` (repo root) — `111 tests, 0 failures`.
- `cd examples/threadline_phoenix && MIX_ENV=dev mix demo.reset` — completes, prints `demo.seed
  complete`, exit `0` (the nested acquire resolves against the outer holder on a real, non-Sandbox
  pooled connection, `pool_size: 10`).
- `mix format --check-formatted` — exits `0`.
- `git status --porcelain .github/ .planning/scorecards/ CONTRIBUTING.md
  examples/threadline_phoenix/e2e/playwright.config.ts` — empty (D-39/D-42; this plan's
  `files_modified` never named any of these paths).

## Residue

No part of any of the three findings is left open. Nothing is deferred to `deferred-items.md` from
this plan.

---
*Phase: 198-green-bringup*
*Plan: 38*
