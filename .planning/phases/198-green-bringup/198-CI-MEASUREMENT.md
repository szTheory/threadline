# 198-18: CI Measurement — Gap-Closure Round 2

**Written per plan 198-18.** Task 1 establishes the local baseline and its explicit
limits, and states a prediction, all BEFORE anything is pushed. Task 2 pushes,
watches the real CI run to completion, and records it. Task 3 sets GREEN-04/GREEN-07
from that measured run.

---

## Task 1 — Local pre-flight baseline (written before the push)

**Worktree base:** `70503b8b` (contains merged 198-14, 198-15, 198-16, 198-17).
**Timestamp:** 2026-08-28T18:00Z (approx, UTC).

### Verbatim results

**`mix compile --warnings-as-errors` (MIX_ENV=test):** exit 0, clean compile
(threadline + ex_aws + ex_aws_s3 + threadline_phoenix, no warnings).

**`mix test`, run 1 (after root deps + example-app deps fetched):**
```
Finished in 43.9 seconds (1.8s async, 42.0s sync)
1412 tests, 0 failures (1 excluded)
```

**`mix test`, run 2 (independent, consecutive):**
```
Finished in 43.2 seconds (2.0s async, 41.1s sync)
1412 tests, 0 failures (1 excluded)
```

Two consecutive runs, byte-identical pass/fail/excluded counts. (An initial attempt
before `examples/threadline_phoenix`'s deps were fetched in this fresh worktree
checkout showed 1 failure at `stress_router_test.exs` — the exact ambient-dependency
class 198-15 diagnosed and retired for the *test-outcome* path; here it was purely a
worktree setup gap, not a regression of 198-15's fix, and disappeared once
`examples/threadline_phoenix`'s deps were fetched, which this worktree had never
done. Confirmed by re-running `stress_router_test.exs` alone afterward: 17 tests, 0
failures.)

**Anti-laundering caps** (`zero_skips_contract_test.exs`,
`storage_schema_prefix_contract_test.exs`,
`storage_schema_call_site_contract_test.exs`):
```
Running ExUnit with seed: 749446, max_cases: 36
Excluding tags: [pgbouncer_topology: true]
.........................
Finished in 0.1 seconds (0.05s async, 0.08s sync)
25 tests, 0 failures
```

**`mix verify.format`:** exit 0, no output.

**`mix verify.credo`:**
```
Checking 257 source files (this might take a while) ...
2721 mods/funs, found no issues.
```

**Pooled topology sequence (198-14's proven path — invisible to `mix test` by
design, since the file carries `@moduletag :pgbouncer_topology`):**
```
$ THREADLINE_DB_PORT=5434 docker compose --profile pgbouncer up -d
 Container ...-postgres-1 Started / Healthy
 Container ...-pgbouncer-1 Started

$ until pg_isready -h localhost -p 5434 -U postgres; do sleep 1; done
localhost:5434 - accepting connections
$ until pg_isready -h localhost -p 6432 -U postgres; do sleep 1; done
localhost:6432 - accepting connections

$ MIX_ENV=test DB_HOST=localhost DB_PORT=5434 THREADLINE_TOPOLOGY_BOOTSTRAP=1 mix run priv/ci/topology_bootstrap.exs
Threadline: topology bootstrap OK (migrations + threadline_pooler_topology_ctx)

$ DB_HOST=localhost DB_PORT=6432 THREADLINE_PGBOUNCER_TOPOLOGY=1 mix test test/threadline/pgbouncer_topology_test.exs --include pgbouncer_topology
Running ExUnit with seed: 303839, max_cases: 36
Including tags: [:pgbouncer_topology]
.
Finished in 0.05 seconds (0.00s async, 0.05s sync)
1 test, 0 failures

$ docker compose --profile pgbouncer down
 Container ...-pgbouncer-1 Removed
 Container ...-postgres-1 Removed
```
(Same port remap as 198-14: local host port 5432 is bound by this machine's own
system Postgres, used for the ordinary `mix test` runs above; `THREADLINE_DB_PORT`
remapped to 5434 for the direct-Postgres leg only. `THREADLINE_PGBOUNCER_PORT` left
at the plan/CI default 6432. Same real docker-compose postgres+pgbouncer topology as
CI; only the local host-port literal differs.)

**`mix ci.all`:** stopped at `verify.example` (the example app's own
`ThreadlinePhoenix.DemoContractTest`), exactly as documented:
```
109 tests, 8 failures
** (Mix) verify.example failed (2)
```
All 8 failures are `Ecto.NoResultsError`/assertion-mismatch failures against
seeded-data shapes (org_memberships actor attribution, SEED-03 manifest hero
transactions, SEED-05 delete incident) — the same class already recorded in
`deferred-items.md` (Plan 198-12 entry) and carried across Phases 177/179/180/182.
**This matches the documented, expected stopping point.** Everything before it in
the `ci.all` chain (`verify.format`, `verify.credo`,
`compile --warnings-as-errors`, `verify.compile_no_optional`, `verify.test`,
`verify.threadline`) ran and passed: `verify.test` inside `ci.all` reported
`1412 tests, 0 failures (1 excluded)`, and `verify.threadline`'s coverage canary
reported `1/1 expected tables covered (0 violated)`. `mix ci.all` was not run past
`verify.example` — `verify.doc_contract`, `verify.critic_trust`, `verify.mechanical`,
and `verify.example_browser` (the four steps after it in the alias) did not execute
this pass, consistent with the documented, unfixed, out-of-scope deferred item.

`git status --porcelain` after all of the above: clean (confirmed before writing
this artifact).

### Honest limits — what local evidence does and does not establish

For each of the four gaps this round targeted:

1. **The two `Run test suite` matrix lanes (`min` / `current`).** Local evidence:
   `mix test` twice, byte-identical, 1412/0. This establishes the default suite is
   deterministic and green **on this machine, on this Elixir/OTP/Postgres
   combination**. It does **not** establish that GitHub's `min` lane (Elixir 1.15 /
   OTP 26 / pg14 / ubuntu-22.04) or `current` lane (their own pins) produce the same
   result — no local run exercises either lane's actual toolchain matrix, and the
   `min` lane in particular has a standing note in `198-CONTEXT.md` that it has
   never been observed reporting on `origin` under the current `ci.yml`. This
   prediction is informed, not proven.
2. **`PgBouncer transaction topology` against the real pooler service.** Local
   evidence: the exact bootstrap→pool sequence above, green. This establishes the
   ported code path (`repo_opts()` at every owned-schema call site in
   `pgbouncer_topology_test.exs`) is structurally correct against a real
   `edoburu/pgbouncer` container on this machine. It does **not** establish CI's own
   `pgbouncer` service container (pinned version, CI network topology, CI's exact
   env var wiring in `verify-pgbouncer-topology`) behaves identically — no local run
   uses CI's own service-container definition.
3. **`Tier A capture lane` byte-stability on a CI runner.** Local evidence: none run
   this task (deliberately — see below). 198-16's audit
   (`.planning/audits/198-tier-a-byte-stability.md`) already reproduced the
   `scroll_cost` drift locally, twice, byte-identically, and diagnosed its cause
   (the harness sidebar's unvirtualized story catalog leaking into a document-wide
   `scrollHeight` read). **Carried forward verbatim: every available remedy requires
   Tier A `page.*` scorecard regeneration, which the maintainer decision for this
   run explicitly reaffirms is not to be attempted.** No local run in this task
   re-attempts capture or regeneration. This gap is **expected-still-red** by
   design, not by omission.
4. **`Example app browser E2E`.** Local evidence: none run this task (deliberately
   — the browser lane is slow and 198-17 already ran the plan's own required verify
   command in full). 198-17's audit
   (`.planning/audits/198-example-browser-e2e.md`) fixed the 5 originally-diagnosed
   failures with a red-then-green teeth proof, then discovered 28 additional,
   unrelated, pre-existing failures across 14 tests that CI's `maxFailures: 5`
   ceiling had been masking (logged in `deferred-items.md` and
   `.planning/WINDOWS.md` entry #8). **Carried forward verbatim: those 28 failures
   were never fixed — they are explicitly out of 198-17's scope and remain
   unaddressed going into this run.** This gap is **expected-still-red**.

No local run can predict the outcome of any of these four checks with certainty —
that is precisely why this plan pushes and observes rather than asserting.

### Prediction (stated before the push)

| Check | Prediction | Basis |
|---|---|---|
| `Check formatting` | GREEN | Unchanged; local `verify.format` clean |
| `Run Credo (strict)` | GREEN | Unchanged; local `verify.credo` clean |
| `Compile without optional deps` | GREEN | Fixed by 198-10 in the prior round; unchanged since |
| `Run test suite (min)` | GREEN (uncertain — see limits §1) | Local 1412/0 ×2; 198-14/198-15 closed the two GREEN-04 defects (pgbouncer file, ambient stress-router dependency) that made this lane fail last round |
| `Run test suite (current)` | GREEN (uncertain — see limits §1) | Same basis as `min` |
| `Hex evaluator smoke` | GREEN | Unchanged; not touched by any gap-closure plan |
| `PgBouncer transaction topology` | GREEN (uncertain — see limits §2) | 198-14's port + local pooled-run proof, reproduced fresh above |
| `Mechanical checker (committed scorecards)` | GREEN | Fixed by 198-10 in the prior round; unchanged since |
| `Tier A capture lane` | **RED (expected)** | 198-16 diagnosed the cause and explicitly halted — every remedy is forbidden this milestone; carried forward verbatim, no fix attempted here |
| `Example app browser E2E` | **RED (expected)** | 198-17 fixed the 5 diagnosed failures but discovered 28 unrelated, unfixed, pre-existing failures underneath the `maxFailures: 5` ceiling; carried forward verbatim, no fix attempted here |
| `Build ExDoc (dev)` | GREEN | Unchanged |
| `Hex package tarball` | GREEN | Unchanged |
| `Release metadata (version / changelog)` | GREEN | Unchanged |
| **`CI required` (aggregate)** | **RED (expected)** | `needs:` includes both expected-red checks above; `re-actors/alls-green` under `if: always()` fails the aggregate on any non-success dependency |

**Expected-red set, carried forward verbatim from 198-16/198-17's own halts:**
`Tier A capture lane` and `Example app browser E2E`. Both are explicitly predicted
red here, before the push, because their remedies are either forbidden
(Tier A) or out of this round's scope (browser lane's 28-failure discovery).
**GREEN-07 is therefore predicted Pending after this run** — the `CI required`
aggregate is predicted to fail because two of its twelve dependencies are predicted
red. This prediction exists precisely so the actual run can be scored against it in
Task 2, per the plan's own framing: a prediction later contradicted is useful
evidence, a run with no prior prediction teaches nothing about whether the
diagnosis was right.

`git status --porcelain` at the end of Task 1: clean except this artifact
(confirmed).

---

## Task 2 — Push, watch the run, record it

See below.
