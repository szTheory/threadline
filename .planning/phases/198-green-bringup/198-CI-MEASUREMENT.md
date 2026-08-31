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

### Push

Pushed the worktree's HEAD (`f748e43d`, which carries all of 198-14, 198-15,
198-16, 198-17, and Task 1's own commit) to the existing `ci/198-gap-closure`
branch, per the maintainer's explicit authorization for this round and PR #29's
existing open state:

```
$ git push origin HEAD:ci/198-gap-closure
   ffcff0d1..f748e43d  HEAD -> ci/198-gap-closure
```

`main` was never touched; `git diff --exit-code .github/rulesets/
.github/workflows/branch-protection.yml` was clean both before and after the
push, and the live ruleset (`gh api repos/szTheory/threadline/rulesets/21702804`)
reported `{"bypass_actors":[],"enforcement":"active"}` identically before and
after. No bypass actor was added. No direct push to `main` was attempted.

### The run

```
$ gh run list --branch ci/198-gap-closure --limit 1 --json conclusion,databaseId,headSha,createdAt,updatedAt
[{"conclusion":"failure","databaseId":33197493051,"headSha":"f748e43d...","createdAt":"2026-08-28T18:02:46Z","updatedAt":"2026-08-28T18:16:15Z"}]
```

- **Run ID:** `33197493051`
- **Head SHA:** `f748e43d7e4c1e63a0142569a55f57c7187e5cb1`
- **Conclusion:** `failure`
- **Wall clock:** `18:02:46Z` → `18:16:15Z` = **13m29s** (well inside the ≤20-minute
  clause on its own; the *other* GREEN-07 clause — `CI required` must conclude
  `success` — is what fails this run, not time)
- Watched to completion in the foreground (`gh run watch 33197493051
  --exit-status`); no re-run was issued at any point in this task.

### Per-check table (all 14 checks the run reported, `CI required` called out
separately)

| Check | Conclusion | Duration |
|---|---|---|
| Check formatting | ✓ success | 19s |
| Run Credo (strict) | ✓ success | 1m16s |
| Compile without optional deps | ✓ success | 1m8s |
| Run test suite (min) | ✓ success | 4m26s |
| Run test suite (current) | ✗ **failure** | 7m2s |
| Hex evaluator smoke (threadline from hex.pm) | ✓ success | 1m7s |
| PgBouncer transaction topology | ✓ success | 1m57s |
| Mechanical checker (committed scorecards) | ✓ success | 1m34s |
| Tier A capture lane (byte-stable evidence) | ✗ **failure** | 6m16s |
| Example app browser E2E (Playwright) | ✗ **failure** | 13m20s |
| Build ExDoc (dev) | ✓ success | 1m26s |
| Hex package tarball | ✓ success | 17s |
| Release metadata (version / changelog) | ✓ success | 8s |
| **`CI required` (aggregate)** | **✗ failure** | 3s |

`CI required`'s own `re-actors/alls-green` step ("Decide whether all needed jobs
succeeded") failed because 3 of its 12 `needs:` dependencies concluded `failure`
(`Run test suite (current)`, `Tier A capture lane`, `Example app browser E2E`).
No dependency was `skipped` or `cancelled` — every job actually ran to completion.

### Prediction scorecard (Task 1's prediction vs. the actual run)

| Check | Predicted | Actual | Right? |
|---|---|---|---|
| Check formatting | GREEN | success | ✓ |
| Run Credo (strict) | GREEN | success | ✓ |
| Compile without optional deps | GREEN | success | ✓ |
| Run test suite (min) | GREEN (uncertain) | success | ✓ |
| Run test suite (current) | GREEN (uncertain) | **failure** | ✗ — see below |
| Hex evaluator smoke | GREEN | success | ✓ |
| PgBouncer transaction topology | GREEN (uncertain) | success | ✓ |
| Mechanical checker | GREEN | success | ✓ |
| Tier A capture lane | RED (expected) | failure | ✓ |
| Example app browser E2E | RED (expected) | failure | ✓ |
| Build ExDoc (dev) | GREEN | success | ✓ |
| Hex package tarball | GREEN | success | ✓ |
| Release metadata | GREEN | success | ✓ |
| CI required | RED (expected) | failure | ✓ |

**11 of 14 predictions correct.** The one wrong prediction —
`Run test suite (current)` — is explained below with its own root-cause evidence,
not merely marked wrong.

**Why the `Run test suite (current)` prediction was wrong.** The prediction
correctly anticipated that 198-14's and 198-15's fixes (the pgbouncer file's
`repo_opts()` port, and retiring `stress_router_test.exs`'s ambient
`examples/threadline_phoenix` dependency) would let `mix verify.test` itself pass
inside this job — and it did (confirmed by the job's own `mix verify.test` step,
which is the same command both matrix lanes run and which is what `Run test suite
(min)` — now green — depends on exclusively). What the prediction could not
anticipate, because no local task in this round or 198-16/198-17 ran it, is that
`Run test suite (current)`'s job carries **three** additional `if: matrix.lane
== 'current'`-gated steps after `mix verify.test`: `mix verify.threadline`, then
`mix verify.example` (the example app's own `ThreadlinePhoenix` ExUnit suite,
including `ThreadlinePhoenixWeb.WalkthroughHappyPathTest`), then
`mix verify.doc_contract`. In every prior CI run (baseline `33138291361`
and prior round `33183920952`), this job's earlier `mix verify.test` step failed
first (on the pgbouncer/stress-router defects), which — by GitHub Actions' default
sequential-step semantics — meant `mix verify.example` never ran at all in this
job. Fixing `mix verify.test` did not turn the lane green; it advanced the job far
enough to reach a distinct, previously-masked third defect underneath: **this
job's own database-preparation step (`.github/workflows/ci.yml:235-240`, "Ensure
threadline_phoenix_test database exists") runs `createdb` but — unlike the
equivalent preparation step in the `verify-example-browser` job
(`ci.yml:346-355`) and the `verify-capture` job (`ci.yml:500-509`) — never runs
the `ALTER DATABASE threadline_phoenix_test SET search_path TO "$user", public,
threadline;` statement those two other jobs both carry.** Without that ALTER,
`mix verify.example`'s `ThreadlinePhoenixWeb.WalkthroughHappyPathTest` queries
`audit_transactions` on the default `public`-only search path and gets
`** (Postgrex.Error) ERROR 42P01 (undefined_table) relation "audit_transactions"
does not exist"` — the exact GREEN-04 defect class this phase exists to close,
now measured in a fourth location. This is new information this round's local
tasks had no way to surface locally (`mix ci.all` on this machine hits
`verify.example` too, but through its OWN db-prep path in `mix.exs`'s
`verify_example/1`, which is a different code path from this CI job's inline
`createdb`-only step — the local reproduction in Task 1 above used the shared
local Postgres, which already had `threadline_phoenix_test`'s search_path altered
from prior 198-16/198-17 work, so it could not have caught this).

### Three-way job comparison — "N of 7 now green"

Baseline run `33138291361` (`main` @ `a97f527e`) had **7 non-aggregate red
jobs**. Comparing all three runs directly (job conclusions fetched fresh via
`gh api .../actions/runs/<id>/jobs` for all three, not carried from any prior
summary):

| Job | Baseline (33138291361) | Round 1 (33183920952) | Round 2 (33197493051, this run) |
|---|---|---|---|
| Compile without optional deps | ✗ failure | ✓ success | ✓ success |
| Mechanical checker (committed scorecards) | ✗ failure | ✓ success | ✓ success |
| PgBouncer transaction topology | ✗ failure | ✗ failure | **✓ success** |
| Run test suite (min) | ✗ failure | ✗ failure | **✓ success** |
| Run test suite (current) | ✗ failure | ✗ failure | ✗ failure (new cause — see above) |
| Tier A capture lane (byte-stable evidence) | ✗ failure | ✗ failure | ✗ failure (unchanged — 198-16's diagnosed, forbidden-remedy cause) |
| Example app browser E2E (Playwright) | ✗ failure | ✗ failure | ✗ failure (unchanged — 198-17's diagnosed, out-of-scope 28-failure discovery) |
| **`CI required` (aggregate)** | ✗ failure | ✗ failure | ✗ failure |

**4 of the 7 originally-red jobs are green now: `Compile without optional deps`,
`Mechanical checker`, `PgBouncer transaction topology`, and `Run test suite
(min)`.** Round 1 fixed 2 (`Compile without optional deps`,
`Mechanical checker`); this round (198-14/198-15) fixed 2 more (`PgBouncer
transaction topology`, `Run test suite (min)`). **3 of the 7 remain red:**
`Run test suite (current)` (a newly-measured, previously-masked third cause, not
yet diagnosed or authorized for a fix in this plan's scope), `Tier A capture
lane` (198-16's diagnosed-but-forbidden-remedy halt, unchanged), and `Example app
browser E2E` (198-17's diagnosed 5-of-33 fix plus the 28-failure discovery,
unchanged — this run's 5 failures are exactly 5 of that 28-failure set, confirmed
by name below).

### Verbatim failure output for every still-red check

**`Run test suite (current)`** (`job 98938250341`) — 9 tests failed, all the
identical `undefined_table` cause (one representative shown; all 9 share the
same query and stacktrace shape):
```
1) test §2 onboarding (WALK-01-05..07) WALK-01-06 support user reaches org-scoped audit timeline (ThreadlinePhoenixWeb.WalkthroughHappyPathTest)
   test/threadline_phoenix_web/walkthrough_happy_path_test.exs:43
   ** (Postgrex.Error) ERROR 42P01 (undefined_table) relation "audit_transactions" does not exist

       query: SELECT a0."id" FROM "audit_transactions" AS a0 WHERE (a0."txid" = txid_current())
   stacktrace:
     (ecto_sql 3.13.5) lib/ecto/adapters/sql.ex:1113: Ecto.Adapters.SQL.raise_sql_call_error/1
     ...
     (threadline_phoenix 0.1.0) lib/threadline_phoenix/demo/seed/personas.ex:106: anonymous fn/4 in ThreadlinePhoenix.Demo.Seed.Personas.seed_memberships/1
```
All 9 failing test names: `WALK-01-06`, `WALK-03-04`, `WALK-03-01`, `WALK-02-02`,
`WALK-02-01`, `WALK-03-03`, `WALK-03-02`, `WALK-02-03 (admin export status)`,
`WALK-01-07` — the entirety of `ThreadlinePhoenixWeb.WalkthroughHappyPathTest`
that touches seeded audit data, all failing at the same `seed_memberships`
setup call, all with the identical `undefined_table` cause.

**`Tier A capture lane (byte-stable evidence)`** (`job 98938250050`) — the
capture itself passed (`2 passed (4.0m)`), then the byte-stability assertion
failed exactly as 198-16 diagnosed and predicted:
```
##[error]Tier A capture is not byte-stable, or committed evidence is stale.
-    "scroll_cost": 18.803,
+    "scroll_cost": 40.8,
-    "scroll_cost": 19.85,
+    "scroll_cost": 41.953,
-    "scroll_cost": 19.038,
+    "scroll_cost": 36.504,
```
(repeated across all 6 `page.coverage.error__*` cells, matching
`.planning/audits/198-tier-a-byte-stability.md`'s own reproduction values within
measurement noise — 40.8/41.953/36.504 here vs. 40.37/41.417/36.478 in the local
reproduction, both far from the committed 18.803/19.85/19.038 and both far above
the correctly-scoped ~0.558 the audit computed).

**`Example app browser E2E (Playwright)`** (`job 98938250110`) — `5 failed`,
`305 did not run`, `50 passed (10.8m)` (`maxFailures: 5` ceiling hit, per
`playwright.config.ts:141`). All 5 failing tests, by name:
```
[desktop-chromium] › operator-find-mobile.spec.ts:48:3 › transaction mobile opens from Timeline with semantic values and copy controls
[desktop-chromium] › operator-find-mobile.spec.ts:66:3 › row-history mobile opens from a Transaction row with formatted values
[desktop-chromium] › operator-find-mobile.spec.ts:103:3 › coverage mobile shows Add capture remediation without horizontal overflow
[desktop-chromium] › operator-phase-135-uat.spec.ts:76:3 › support user is denied admin-only Coverage
[desktop-chromium] › operator-phase-173-uat.spec.ts:74:3 › dropdown: opens and exposes aria-expanded state
```
All 5 are members of the 28-failure set 198-17 already discovered, diagnosed as
out-of-scope, and logged in `deferred-items.md` (Plan 198-17 entry) and
`.planning/WINDOWS.md` entry #8 — confirmed by name match against that entry's
own list (`operator-find-mobile.spec.ts`, `operator-phase-135-uat.spec.ts`,
`operator-phase-173-uat.spec.ts` are all named there). Neither of the two specs
198-17 fixed (`operator-coverage-readiness.spec.ts`,
`operator-accessibility.spec.ts`) appears anywhere in this run's failures —
confirming 198-17's fix held on the real CI run. The two fixed specs' tests
(coverage-readiness viewports 11-15 and accessibility test 10 in the run's own
numbered output above) all show `✓` in this run.

### Re-run discipline

No check in this run was re-run for any reason — this section is present per the
plan's acceptance criteria to state that explicitly. `gh run watch` observed the
single run to its single, natural completion.

### Branch protection — before/after

```
$ git diff --exit-code .github/rulesets/ .github/workflows/branch-protection.yml
(exit 0, both before and after the push)

$ gh api repos/szTheory/threadline/rulesets/21702804 --jq '{enforcement, bypass_actors}'
{"bypass_actors":[],"enforcement":"active"}
(identical before and after)
```

### PR #29 mergeability

```
$ gh pr view 29 --json mergeStateStatus,state
{"mergeStateStatus":"BLOCKED","state":"OPEN"}
```
Unchanged from before this run — `CI required` is red, so the branch protection
gate correctly still blocks the merge, exactly as designed.

---

## Round 3 (2026-08-28) — Local pre-push readiness signal (Plan 198-19)

**Worktree base:** `ec9e7fdd` (contains merged 198-01 through 198-18, plus round-3
plan 198-19's own two fixes: the `verify-test` current-lane db-prep step now sets
`threadline` on the example-app database's search_path, and the call-site sweep's
CR-01/CR-02 blind spots are closed).

**IMPORTANT — inadmissible as CI proof.** Everything in this section is a local
readiness signal only. It is NOT admissible as proof that GREEN-04 or GREEN-07 are
met — that verdict belongs exclusively to the measured CI run recorded in plan
198-21 (198-CONTEXT.md D-01). A green local run and a green CI run are not the same
claim; CI's runner OS, Postgres version, and dependency resolution differ from this
machine's.

### `mix test`, run 1

```
Finished in 46.6 seconds (2.0s async, 44.6s sync)
1420 tests, 0 failures (1 excluded)
```

### `mix test`, run 2 (independent, consecutive)

```
Finished in 48.1 seconds (2.4s async, 45.6s sync)
1420 tests, 0 failures (1 excluded)
```

Both runs report **1420 tests, 0 failures (1 excluded)** — byte-identical
pass/fail/excluded counts across the two runs.

### `mix ci.all` step-by-step ledger

Run as `DB_HOST=localhost MIX_ENV=test mix ci.all` against a freshly recreated
`threadline_phoenix_test` database (dropped and recreated immediately before this
run, exercising the same `createdb` idempotency the CI step relies on).

| Step | Result |
|------|--------|
| `verify.format` | PASS — no output (clean) |
| `verify.credo` | PASS — `2721 mods/funs, found no issues` (257 files) |
| `compile --warnings-as-errors` | PASS (implicit — run continued past this step) |
| `verify.compile_no_optional` | PASS (implicit — run continued past this step) |
| `verify.test` | PASS — `1420 tests, 0 failures (1 excluded)` |
| `verify.threadline` | PASS — `1/1 expected tables covered (0 violated)` |
| `verify.example` | **FAIL** — `109 tests, 8 failures`, exit code 2 |
| `verify.doc_contract` | not reached (ci.all halts at first failing step) |
| `verify.critic_trust` | not reached |
| `verify.mechanical` | not reached |
| `verify.example_browser` | not reached |

`mix ci.all` exited 1.

### `verify.example` failure — known, previously-acknowledged deferral

All 8 failures are `ThreadlinePhoenix.DemoContractTest` assertions against
`mix demo.seed`-generated content (SEED-03 manifest-hero transactions, SEED-05
delete-incident, D-05 persona actor attribution) — `Ecto.NoResultsError` and
assertion-count mismatches, never a `Postgrex.Error 42P01 (undefined_table)`. Zero
`undefined_table` / "does not exist" occurrences appear anywhere in this run's
output (confirmed via `grep -c`). This is the exact class of failure
`deferred-items.md`'s Plan 198-12 entry already acknowledges and defers — "the
recurring 'example precommit demo-seed/walkthrough failures' pattern already
acknowledged & deferred across Phases 177, 179, 180, and 182" — and is out of
round 3's scope per that entry and per this plan's own read_first note.

The specific failing test names are non-deterministic across runs (a second,
independent `mix verify.example` run earlier in this plan's Task 1 execution
produced a different 9-test failure set, including two `ThreadlinePhoenixWeb.
WalkthroughHappyPathTest` content-assertion mismatches not present in this run) —
consistent with order/seed-dependent demo-seed content, not a stable regression.
In both independent local runs, the `undefined_table` failure class this plan's
Task 1 targets was completely absent (0 occurrences), which is the honest scope of
what Task 1's local fix can prove.

### Honest limits of this local evidence

This local evidence is **inadmissible** as proof that GREEN-04 or GREEN-07 are met.
The authority for that verdict is the measured CI run in plan 198-21, not this
worktree. Recorded here only as a pre-push readiness signal: local `mix test` is
green (twice, byte-identical), and the one `mix ci.all` failure is the
already-acknowledged, already-deferred example-app demo-seed content class — not a
new defect and not the `undefined_table` defect this plan's Task 1 targets.

---

## Round 3 (2026-08-28) — Measured CI run (Plan 198-22, gap-closure round 3)

**Push.** Worktree HEAD `80bf701e7486962e538d16f213874cbba8f24115` (merge commit
carrying all of 198-01 through 198-21, including 198-19's search_path fix and
CR-01/CR-02 sweep closure, and 198-21's `needs:`-roster/ruleset-singleton
contract tests) pushed to a **fresh** branch, distinct from round 2's
`ci/198-gap-closure`:

```
$ git push origin HEAD:refs/heads/ci/198-round3
 * [new branch]        HEAD -> ci/198-round3
$ git ls-remote --heads origin ci/198-round3
80bf701e7486962e538d16f213874cbba8f24115	refs/heads/ci/198-round3
```

`git ls-remote --heads origin ci/198-gap-closure` at the same time still resolves
to round 2's SHA (`f748e43d7e4c1e63a0142569a55f57c7187e5cb1`) — the two branches
are distinct refs; round 3's evidence cannot be confused with round 2's.

`git log origin/main..HEAD --oneline | wc -l` at push time: **88** — `origin/main`
does not yet carry these 88 commits; that gap closes only if/when this PR merges.

Opened as a **draft** pull request against `main`, explicitly marked "DO NOT
MERGE" in its body (a measurement vehicle, not a merge request):

```
$ gh pr create --draft --base main --head ci/198-round3 --title "ci(198): round-3 measurement — search_path fix + merge-gate self-guards" ...
https://github.com/szTheory/threadline/pull/30
```

- **PR:** #30, state `OPEN`, `mergeStateStatus`: `BLOCKED` (unchanged from round
  2's PR #29 pattern — `CI required` red blocks the merge, exactly as designed).

### The run

```
$ gh run list --branch ci/198-round3 --limit 10 --json databaseId,conclusion,headSha,status,createdAt
[{"createdAt":"2026-08-28T19:39:29Z","databaseId":33204829086,"headSha":"80bf701e7486962e538d16f213874cbba8f24115","status":"in_progress"}]
```

Exactly one run exists for this branch/head SHA — no ordering ambiguity; this run
is authoritative by construction, not by selection among competitors.

```
$ gh run view 33204829086 --json status,conclusion,createdAt,updatedAt,attempt,headSha
{"attempt":1,"conclusion":"failure","createdAt":"2026-08-28T19:39:29Z","headSha":"80bf701e7486962e538d16f213874cbba8f24115","status":"completed","updatedAt":"2026-08-28T19:52:58Z"}
```

- **Run ID:** `33204829086`
- **Head SHA:** `80bf701e7486962e538d16f213874cbba8f24115` (matches the recorded
  local head SHA exactly)
- **Conclusion:** `failure`
- **Attempt:** `1` — no rerun, re-dispatch, or selective retry occurred at any
  point; `gh run watch` observed the single run to its single, natural completion
  (background-watched to `--exit-status`, which correctly reported non-zero since
  the run's own conclusion is `failure` — not a tooling error).
- **Wall clock:** `19:39:29Z` → `19:52:58Z` = **13m29s** — byte-identical to
  round 2's wall clock, and well inside the ≤20-minute clause on its own. As in
  round 2, the *other* GREEN-07 clause (`CI required` must conclude `success`) is
  what fails this run, not time.

### Per-job table (all 13 jobs the run reported, `CI required` called out separately — 14 checks total, matching round 2's count)

| Check | Conclusion | Duration (started→completed) |
|---|---|---|
| Check formatting | ✓ success | 19:39:32 → 19:39:50 (18s) |
| Run Credo (strict) | ✓ success | 19:39:33 → 19:40:52 (1m19s) |
| Compile without optional deps | ✓ success | 19:39:32 → 19:40:47 (1m15s) |
| Run test suite (min) | ✓ success | 19:39:32 → 19:43:51 (4m19s) |
| Run test suite (current) | ✗ **failure** | 19:39:32 → 19:46:53 (7m21s) |
| Hex evaluator smoke (threadline from hex.pm) | ✓ success | 19:39:32 → 19:40:34 (1m2s) |
| PgBouncer transaction topology | ✓ success | 19:39:32 → 19:41:23 (1m51s) |
| Mechanical checker (committed scorecards) | ✓ success | 19:39:32 → 19:40:59 (1m27s) |
| Tier A capture lane (byte-stable evidence) | ✗ **failure** | 19:39:32 → 19:47:22 (7m50s) |
| Example app browser E2E (Playwright) | ✗ **failure** | 19:39:32 → 19:52:50 (13m18s) |
| Build ExDoc (dev) | ✓ success | 19:39:32 → 19:40:58 (1m26s) |
| Hex package tarball | ✓ success | 19:39:32 → 19:39:48 (16s) |
| Release metadata (version / changelog) | ✓ success | 19:39:32 → 19:39:41 (9s) |
| **`CI required` (aggregate)** | **✗ failure** | 19:52:53 → 19:52:57 (4s) |

**Job-conclusion collection was non-empty: 14 conclusions collected (13 named
jobs + the aggregate), not zero — this is treated as successful collection, not
failed collection.**

`CI required`'s own `re-actors/alls-green` step ("Decide whether all needed jobs
succeeded") reported, verbatim from its own job-status summary:

```
❌ Some of the required to succeed jobs failed 😢😢😢
✓ verify-format → 🟢 success [required to succeed]
✓ verify-credo → 🟢 success [required to succeed]
✓ verify-compile-no-optional → 🟢 success [required to succeed]
❌ verify-test → 🔴 failure [required to succeed]
✓ verify-hex-evaluator → 🟢 success [required to succeed]
❌ verify-example-browser → 🔴 failure [required to succeed]
✓ verify-mechanical → 🟢 success [required to succeed]
❌ verify-capture → 🔴 failure [required to succeed]
✓ verify-pgbouncer-topology → 🟢 success [required to succeed]
✓ verify-docs → 🟢 success [required to succeed]
✓ verify-hex-package → 🟢 success [required to succeed]
✓ verify-release-shape → 🟢 success [required to succeed]
```

All 12 `needs:` members are accounted for by name in this output — 9 `success`,
3 `failure` (`verify-test`, `verify-example-browser`, `verify-capture`). **Zero**
members report `skipped` or `cancelled`. This is the empty-edge check the plan's
must-haves require: a zero-length collection would be failed collection, not a
pass — here the collection has exactly 12 entries, matching the `needs:` list's
own cardinality, and none were laundered through `skipped`/`cancelled`.

### Four-column baseline comparison — "N of 7 now green"

Extending round 2's three-way table (baseline `33138291361`, round 1
`33183920952`, round 2 `33197493051`) with round 3 (`33204829086`), all four
columns fetched fresh (round 3 via `gh api .../actions/runs/33204829086/jobs`,
carried from round 2's own three-way table for the first three columns, which
were themselves independently fetched, not narrated):

| Job | Baseline (33138291361) | Round 1 (33183920952) | Round 2 (33197493051) | Round 3 (33204829086) |
|---|---|---|---|---|
| Compile without optional deps | ✗ failure | ✓ success | ✓ success | ✓ success |
| Mechanical checker (committed scorecards) | ✗ failure | ✓ success | ✓ success | ✓ success |
| PgBouncer transaction topology | ✗ failure | ✗ failure | ✓ success | ✓ success |
| Run test suite (min) | ✗ failure | ✗ failure | ✓ success | ✓ success |
| Run test suite (current) | ✗ failure | ✗ failure | ✗ failure | ✗ failure (different cause — see below) |
| Tier A capture lane (byte-stable evidence) | ✗ failure | ✗ failure | ✗ failure | ✗ failure (unchanged) |
| Example app browser E2E (Playwright) | ✗ failure | ✗ failure | ✗ failure | ✗ failure (unchanged) |
| **`CI required` (aggregate)** | ✗ failure | ✗ failure | ✗ failure | ✗ failure |

**4 of the 7 originally-red baseline jobs are green as of round 3 — unchanged
from round 2's count.** No new job crossed to green this round, and none
regressed. This is the honest, expected outcome per D-41: round 3's own scope
(198-19/198-21) targeted the *cause* of `Run test suite (current)`'s failure,
not the job's conclusion — the search_path defect was fixed, but a different,
previously-masked defect underneath it (the demo-seed content class) now
determines the job's red conclusion. **3 of the 7 remain red, for three
independently-classified reasons**, none of them "expected red without a
citation":

1. **`Run test suite (current)`** — **newly discovered cause, distinct from round
   2's.** Round 2's cause (missing `ALTER DATABASE ... SET search_path` at
   `ci.yml:235-240`) is **closed**: `grep -c "undefined_table"` against this
   run's full job log returns **0**, and all 9 failing tests in `mix
   verify.example`'s output are `Ecto.NoResultsError` / assertion-mismatch /
   one `ExUnit.TimeoutError` against seeded-data shapes, never a
   `Postgrex.Error 42P01 (undefined_table)`. This is the **8 demo-seed content
   mismatches D-41 named in advance** ("`Run test suite (current)` is expected
   to conclude FAILURE on plan 198-22's measured CI run for this reason, even
   though the originally-named search_path cause is closed") — measured here as
   **9** failures, not 8, consistent with 198-19-SUMMARY's own observation that
   the failure count and specific test names are non-deterministic run-to-run
   (demo-seed content ordering), not a stable regression. **Citation: D-41,
   pointing to `deferred-items.md` Plan 198-12 entry** (demo-seed/walkthrough
   content mismatches acknowledged and deferred across Phases 177, 179, 180,
   182). Two stray Postgres-server-log lines reading `ERROR: relation
   "audit_transactions" does not exist` do appear in this job's container-log
   dump (`Stop containers` step, timestamped `19:43:37Z`, coincident with the
   *root* `mix verify.test` step's own completion at `19:43:42Z`, not with the
   `mix verify.example` step that starts afterward) — these are two isolated
   database-server log lines, not test failures (the root suite step itself
   reported `1423 tests, 0 failures, 1 excluded` immediately after), and most
   plausibly correspond to the root suite's own negative-path contract tests
   that intentionally query without the `threadline` schema prefix to prove
   such access fails (e.g. `storage_schema_prefix_contract_test.exs`). Recorded
   here verbatim rather than silently omitted, but not classified as a
   `verify.example` test failure — none of the 9 named failures cite this
   error.
2. **`Tier A capture lane (byte-stable evidence)`** — **previously known and
   deferred cause, unchanged. Citation: D-39, pointing to
   `.planning/audits/198-tier-a-byte-stability.md`.** The byte-stability
   assertion fails with `scroll_cost` drift values essentially identical to
   round 2's: `18.803→40.8`, `19.85→41.953`, `19.038→36.504` (round 2 measured
   `18.803→40.8`, `19.85→41.953`, `19.038→36.504` — byte-identical), confirming
   the drift is deterministic and reproducible, not measurement noise, exactly
   as 198-16 diagnosed. No remedy was attempted this round (Tier-A `page.*`
   regeneration remains forbidden per D-39/the milestone-level prohibition).
3. **`Example app browser E2E (Playwright)`** — **previously known and
   deferred cause, unchanged. Citation: D-40, pointing to `deferred-items.md`
   Plan 198-17 entry and `.planning/WINDOWS.md` #8.** `5 failed`, `305 did not
   run`, `50 passed (10.8m)` — identical counts to round 2. All 5 failing
   tests, by name, are members of the same 28-failure set: `[desktop-chromium]
   › operator-find-mobile.spec.ts:48:3`, `:66:3`, `:103:3`,
   `operator-phase-135-uat.spec.ts:76:3`, `operator-phase-173-uat.spec.ts:74:3`
   — an exact name-for-name match against round 2's own 5-failure list. No fix
   was attempted this round (out of 198-19's/198-21's scope per D-40).

No lane was made non-blocking by the 198-20 decision (D-39/D-40/D-41 were all
"keep in `needs:`"), so no job's absence from this table needs a
non-blocking-by-decision citation — all three originally-red-and-still-red jobs
are accounted for above by name.

### Wall-clock ≤20-minute evaluation

**Measured: 13m29s (19:39:29Z → 19:52:58Z).** `13m29s ≤ 20m00s` — **the
≤20-minute clause is satisfied**, byte-identical to round 2's own 13m29s figure.
This is not the clause blocking GREEN-07; the blocking clause is `CI required`'s
`success` requirement, addressed next.

### `CI required` conclusion

**Literal string returned by `gh run view 33204829086 --json conclusion` for the
`CI required` job: `"failure"`.** Is it exactly `success`? **No.**

### `mergeStateStatus`

```
$ gh pr view 30 --json mergeStateStatus,state,number,url
{"mergeStateStatus":"BLOCKED","number":30,"state":"OPEN","url":"https://github.com/szTheory/threadline/pull/30"}
```

### Headline claim — true, false, or true-subject-to-a-merge

The phase goal's headline claim — "`origin/main` carries every local commit and
its CI concludes green" — is **false** as of this measured run. Not
true-subject-to-a-merge either: PR #30's `mergeStateStatus` is `BLOCKED`, not
`CLEAN`/`UNSTABLE`, precisely because `CI required` concluded `failure` on this
run, and branch protection (`.github/rulesets/main.json`, unchanged —
`gh api repos/szTheory/threadline/rulesets/21702804 --jq
'{enforcement, bypass_actors}'` returns `{"bypass_actors":[],"enforcement":"active"}`,
identical to round 2) refuses the merge while that stands. `origin/main`
remains 88 commits behind local `HEAD` (unchanged from the push-time count
above — nothing has merged).

### Re-run discipline

No check in this run was re-run, re-dispatched, or selectively retried for any
reason. `attempt: 1` for the run as a whole. `gh run watch` observed the single
run to its single, natural completion.
new defect and not the `undefined_table` defect this plan's Task 1 targets.

## Round 4 (2026-08-28) — Prediction stated before the push

Written **before** `git push`, per plan 198-29 Task 1. One row per `ci-required`
`needs:` member (12 members), plus the `CI required` aggregate itself, with a
predicted conclusion and a one-line basis grounded in this round's own measured
local evidence — never in hope.

| `needs:` member | Check name | Predicted conclusion | Basis |
|---|---|---|---|
| `verify-format` | Check formatting | success | Unaffected by this round's changes (no formatting-relevant file touched by 198-23..28); green on every prior round. |
| `verify-credo` | Run Credo (strict) | success | Unaffected; no lib-code style changed beyond 198-25's one-line label fix, already `mix credo --strict` clean per 198-25's own root-suite run. |
| `verify-compile-no-optional` | Compile without optional deps | success | Unaffected; green on rounds 1-3, no optional-dep surface touched this round. |
| `verify-test` | Run test suite (current) | **success** | `.planning/audits/198-round4-demo-seed.md`'s closing measurement (plan 198-25): `mix verify.example` — `109 tests, 0 failures` (two consecutive runs) — the demo-seed content-mismatch cause D-41 named is fixed at cause (`retention_tail.ex` cutoff, `export_status_live.ex` copy fix). Root `mix test`: `1422 tests, 0 failures, 1 excluded`, unchanged. |
| `verify-hex-evaluator` | Hex evaluator smoke (threadline from hex.pm) | success | Unaffected; no Hex-publish-path or evaluator file touched this round. |
| `verify-example-browser` | Example app browser E2E (Playwright) | **failure** | `.planning/audits/198-round4-playwright.md`'s `## Post-merge re-validation (198-28)` section: 198-28 closed both of cluster-198-28's CI-contributing rows (CI-contributing delta 2 → 0), but that same section recorded a **divergence count of 2** (the mobile row-history and mobile Retention rows re-attributed post-merge) and, separately, **4 new CI-contributing discovery rows** out of scope for this round — `operator-accessibility.spec.ts:565:3` and `operator-prove-mobile.spec.ts:38:3` (both desktop-chromium and mobile-chromium), neither file carrying a `test.skip(!!process.env.CI, ...)` guard (confirmed: `grep -n "test.skip\|process.env.CI"` returns zero matches in either file), so both run and fail on CI. These 4 rows, plus row 30's `operator-accessibility.spec.ts:655:3` mobile-only focus-timing flake (also un-skipped on CI), mean the lane is predicted red despite both formal clusters closing. |
| `verify-mechanical` | Mechanical checker (committed scorecards) | success | Unaffected; no Tier-A scorecard or mechanical-checker file touched this round (D-39 forbids Tier-A work entirely). |
| `verify-capture` | Tier A capture lane (byte-stable evidence) | **failure** | D-39 — only remedy forbidden this milestone; untouched this round. `scroll_cost` drift is deterministic and reproducible per rounds 2/3's byte-identical measurements; no task in 198-23..28 touched the Tier A capture lane, its specs, or its scorecards. |
| `verify-pgbouncer-topology` | PgBouncer transaction topology | success | Unaffected; green on rounds 2-3, no topology-test file touched this round. |
| `verify-docs` | Build ExDoc (dev) | success | Unaffected; no doc-generation-relevant file touched this round. |
| `verify-hex-package` | Hex package tarball | success | Unaffected; no package-manifest file touched this round. |
| `verify-release-shape` | Release metadata (version / changelog) | success | Unaffected; no `CHANGELOG.md`/`mix.exs` version-metadata file touched this round. |
| **`CI required`** (aggregate) | CI required | **failure** | Two `needs:` members (`verify-example-browser`, `verify-capture`) are predicted red; `re-actors/alls-green` fails the aggregate if any required job is not `success`. |

**Predicted red-`needs:`-member count: 2** (`verify-example-browser`, `verify-capture`). This is stated honestly against the plan's own stated aspirational target of 1 — the plan's objective section assumed the Playwright lane would fully close this round, but `## Post-merge re-validation (198-28)`'s own recorded divergence count (2) and its logged new-discovery rows (out of this round's declared scope, per `deferred-items.md`'s Plan 198-27/198-28 entries and `WINDOWS.md` #10/#11) mean at least one further gap-closure round is needed on the Playwright lane specifically. A prediction that assumed the aspirational target without re-checking the evidence would be exactly the kind of unmeasured optimism this plan's `must_haves` forbid.

## Round 4 (2026-08-29) — Measured CI run (Plan 198-29, gap-closure round 4)

**Push.** Worktree HEAD `f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6` (carrying all of
198-01 through 198-28, including this round's demo-seed fixes 198-23/24/25 and
Playwright fixes 198-26/27/28, plus the locked pre-push prediction commit
`f433ef3e docs(198-29): state Round 4 pre-push prediction`) pushed to a **fresh**
branch, distinct from round 3's `ci/198-round3` and round 2's `ci/198-gap-closure`.

**Concurrency edge — the three `ci/198-*` refs resolved at the same moment, provably distinct:**

```
$ git ls-remote --heads origin ci/198-round4 ci/198-round3 ci/198-gap-closure
f748e43d7e4c1e63a0142569a55f57c7187e5cb1	refs/heads/ci/198-gap-closure
80bf701e7486962e538d16f213874cbba8f24115	refs/heads/ci/198-round3
f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6	refs/heads/ci/198-round4
```

Three distinct SHAs. Round 4's evidence cannot be confused with round 2's or round 3's.

`git log origin/main..f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6 --oneline | wc -l`:
**137** — `origin/main` (`a97f527e375f4c1909236b7dbdd5fa3fd9b7d2f2`) does not carry
these 137 commits; that gap closes only if/when a PR merges.

**Pull request — a measurement vehicle, not a merge request.**

```
$ gh pr view 31 --json number,state,isDraft,mergeStateStatus,url,headRefName
{"headRefName":"ci/198-round4","isDraft":true,"mergeStateStatus":"BLOCKED","number":31,"state":"OPEN","url":"https://github.com/szTheory/threadline/pull/31"}
```

PR **#31**, `isDraft: true`, body opening with the literal string **DO NOT MERGE**:

```
**DO NOT MERGE.** This draft PR exists solely as a measurement vehicle for Phase 198 gap-closure round 4.
```

### The run

```
$ gh run list --branch ci/198-round4 --limit 10 --json databaseId,conclusion,headSha,status,createdAt,event
[{"conclusion":"failure","createdAt":"2026-08-29T12:52:18Z","databaseId":33253587315,"event":"pull_request","headSha":"f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6","status":"completed"}]
```

**Ordering edge — satisfied by uniqueness, stated explicitly rather than left silent:**
`gh run list --branch ci/198-round4` returned **exactly one** run for this head SHA.
There are no competing run ids, so no most-recent-completed selection among rivals
was needed; this run is authoritative by construction, not by choice.

```
$ gh run view 33253587315 --json status,conclusion,createdAt,updatedAt,attempt,headSha,event
{"attempt":1,"conclusion":"failure","createdAt":"2026-08-29T12:52:18Z","event":"pull_request","headSha":"f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6","status":"completed","updatedAt":"2026-08-29T13:00:29Z"}
```

- **Run ID:** `33253587315`
- **Head SHA:** `f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6` — character-for-character
  identical to the pushed local head SHA above.
- **Event:** `pull_request`
- **Conclusion:** `failure`
- **Attempt:** `1`
- **Wall clock:** `12:52:18Z` → `13:00:29Z` = **8m11s**

### (a) Per-job table

All 13 named jobs the run reported, with `CI required` called out separately — 14
checks total, matching rounds 2 and 3's count.

| Check | Conclusion | Duration (started→completed) |
|---|---|---|
| Check formatting | ✓ success | 12:52:22 → 12:52:40 (18s) |
| Run Credo (strict) | ✓ success | 12:52:20 → 12:53:35 (1m15s) |
| Compile without optional deps | ✓ success | 12:52:20 → 12:53:20 (1m0s) |
| Run test suite (min) | ✓ success | 12:52:21 → 12:56:49 (4m28s) |
| Run test suite (current) | ✗ **failure** | 12:52:21 → 12:59:40 (7m19s) |
| Hex evaluator smoke (threadline from hex.pm) | ✓ success | 12:52:21 → 12:53:23 (1m2s) |
| PgBouncer transaction topology | ✓ success | 12:52:20 → 12:54:02 (1m42s) |
| Mechanical checker (committed scorecards) | ✓ success | 12:52:21 → 12:53:48 (1m27s) |
| Tier A capture lane (byte-stable evidence) | ✗ **failure** | 12:52:21 → 13:00:18 (7m57s) |
| Example app browser E2E (Playwright) | ✗ **failure** | 12:52:21 → 13:00:22 (8m1s) |
| Build ExDoc (dev) | ✓ success | 12:52:22 → 12:53:48 (1m26s) |
| Hex package tarball | ✓ success | 12:52:20 → 12:52:41 (21s) |
| Release metadata (version / changelog) | ✓ success | 12:52:20 → 12:52:27 (7s) |
| **`CI required` (aggregate)** | **✗ failure** | 13:00:24 → 13:00:28 (4s) |

**Empty edge — stated affirmatively rather than left silent: job-conclusion
collection was NOT empty. 14 conclusions were collected (13 named jobs + the
aggregate), and all 12 `ci-required` `needs:` members are accounted for by name in
(b) below. A zero-length collection would have been recorded as failed collection,
not as a pass; this collection is non-empty and complete, so neither GREEN-04's nor
GREEN-07's empty-edge failure mode applies to this record.**

### (b) Verbatim `re-actors/alls-green` output — all 12 `needs:` members

From the `CI required` job's own "Decide whether all needed jobs succeeded" step
(job id `99104195672`), verbatim:

```
# ❌ Some of the required to succeed jobs failed 😢😢😢
✓ verify-format → 🟢 success [required to succeed]
✓ verify-credo → 🟢 success [required to succeed]
✓ verify-compile-no-optional → 🟢 success [required to succeed]
❌ verify-test → 🔴 failure [required to succeed]
✓ verify-hex-evaluator → 🟢 success [required to succeed]
❌ verify-example-browser → 🔴 failure [required to succeed]
✓ verify-mechanical → 🟢 success [required to succeed]
❌ verify-capture → 🔴 failure [required to succeed]
✓ verify-pgbouncer-topology → 🟢 success [required to succeed]
✓ verify-docs → 🟢 success [required to succeed]
✓ verify-hex-package → 🟢 success [required to succeed]
✓ verify-release-shape → 🟢 success [required to succeed]
```

The same step's input payload records `allowed-failures: []` and
`allowed-skips: []` — no member was pre-authorised to fail or skip.

**Member counts: `success` 9, `failure` 3, `skipped` 0, `cancelled` 0. Sum: 12,
equal to the `needs:` list's own cardinality.**

**Adjacency edge (GREEN-07), stated explicitly:** a lane counts as met here only on
the exact conclusion string `success`. `neutral`, `skipped` and `cancelled` are each
recorded as **not-success**. This matters because `re-actors/alls-green` would score
a `skipped` required check as passing — a green aggregate could therefore be
manufactured by skipping a lane rather than fixing it, which is exactly the
laundering D-09 rejects. On this run the point is moot in the maintainer's favour:
zero members reported `skipped` or `cancelled`, so no member's verdict was laundered,
and the aggregate's `failure` is traceable entirely to three genuine `failure`
conclusions.

### (c) Prediction scorecard

Scored against `## Round 4 (2026-08-28) — Prediction stated before the push`, which
was committed to disk in `f433ef3e` **before** `git push`. Nothing below has been
retro-edited; a missed row is written as a miss.

| `needs:` member | Check name | Predicted | Actual | Hit / miss |
|---|---|---|---|---|
| `verify-format` | Check formatting | success | success | hit |
| `verify-credo` | Run Credo (strict) | success | success | hit |
| `verify-compile-no-optional` | Compile without optional deps | success | success | hit |
| `verify-test` | Run test suite (current) | **success** | **failure** | **MISS** |
| `verify-hex-evaluator` | Hex evaluator smoke (threadline from hex.pm) | success | success | hit |
| `verify-example-browser` | Example app browser E2E (Playwright) | failure | failure | hit |
| `verify-mechanical` | Mechanical checker (committed scorecards) | success | success | hit |
| `verify-capture` | Tier A capture lane (byte-stable evidence) | failure | failure | hit |
| `verify-pgbouncer-topology` | PgBouncer transaction topology | success | success | hit |
| `verify-docs` | Build ExDoc (dev) | success | success | hit |
| `verify-hex-package` | Hex package tarball | success | success | hit |
| `verify-release-shape` | Release metadata (version / changelog) | success | success | hit |
| **`CI required`** (aggregate) | CI required | failure | failure | hit |

**Hit rate: 11/12 `needs:` members (12/13 rows including the aggregate).**

**Two separate predictions were falsified this round, and both are recorded as
misses without softening:**

1. **The plan's honest target was to take the red-`needs:` count from 3 down to 1.
   The measured count is 3. Delta against round 3: 0. The target was MISSED.**
2. **The pre-push prediction, written after re-reading 198-28's post-merge
   re-validation, said 2. The measured count is 3. That prediction is FALSIFIED.**
   Its single wrong row is `verify-test`, predicted `success` on the strength of
   198-25's closing local measurement of `109 tests, 0 failures` (twice,
   consecutively). The measured CI conclusion is `failure`. The prediction was
   wrong because it treated a *local* `mix verify.example` result as a reliable
   proxy for the CI job's conclusion — which is precisely the substitution D-01
   forbids as *evidence*, and which this round demonstrates is also unreliable as a
   *forecast*. The cause is diagnosed in (f)(1) below: a CI-only, cold-build
   timeout that a warm local `_build/prod` structurally cannot reproduce.

**The pre-push prediction section above is left exactly as written. It is not
amended, annotated, or corrected in place — a prediction edited after its scoring is
not a prediction.**

### (d) Five-column baseline comparison — "N of 7 now green"

Extending round 3's four-column table (baseline `33138291361`, round 1
`33183920952`, round 2 `33197493051`, round 3 `33204829086`) with round 4
(`33253587315`, fetched fresh via `gh run view 33253587315 --json jobs`):

| Job | Baseline (33138291361) | Round 1 (33183920952) | Round 2 (33197493051) | Round 3 (33204829086) | Round 4 (33253587315) |
|---|---|---|---|---|---|
| Compile without optional deps | ✗ failure | ✓ success | ✓ success | ✓ success | ✓ success |
| Mechanical checker (committed scorecards) | ✗ failure | ✓ success | ✓ success | ✓ success | ✓ success |
| PgBouncer transaction topology | ✗ failure | ✗ failure | ✓ success | ✓ success | ✓ success |
| Run test suite (min) | ✗ failure | ✗ failure | ✓ success | ✓ success | ✓ success |
| Run test suite (current) | ✗ failure | ✗ failure | ✗ failure | ✗ failure | ✗ failure (third distinct cause — see (f)(1)) |
| Tier A capture lane (byte-stable evidence) | ✗ failure | ✗ failure | ✗ failure | ✗ failure | ✗ failure (unchanged, D-39) |
| Example app browser E2E (Playwright) | ✗ failure | ✗ failure | ✗ failure | ✗ failure | ✗ failure (entirely different failing tests — see (f)(2)) |
| **`CI required` (aggregate)** | ✗ failure | ✗ failure | ✗ failure | ✗ failure | ✗ failure |

**4 of the 7 originally-red baseline jobs are green as of round 4 — unchanged from
round 3's 4.** No job crossed to green this round, and none regressed.

### (e) Red `needs:` count

**Red `needs:` members: 3** — `verify-test`, `verify-example-browser`,
`verify-capture`.

**Round 3's count: 3. Delta: 0.**

**This round's stated target was 1. The target was MISSED.** Two of the three lanes
were expected to close: `verify-test` on the strength of 198-23/24/25, and
`verify-example-browser` was already downgraded to "expected red" in the pre-push
prediction. Neither closed. Progress *inside* two of the three lanes is real and
measured (see (f)), but progress inside a lane is not the metric — the metric is the
lane's conclusion string, and three lanes still conclude `failure`.

### (f) Root cause for every still-red check

Every red check below carries a named cause and a citation. No row reads "still red".

#### (f)(1) `Run test suite (current)` — `verify-test`

**Conclusion: `failure`. Failing step: `Verify Threadline Phoenix example`
(`mix verify.example`).** The job's earlier root-suite step (`Run tests`,
`mix verify.test`) **passed**, verbatim: `1423 tests, 0 failures, 1 excluded`.

Failing step output, verbatim:

```
Finished in 96.1 seconds (0.6s async, 95.5s sync)
109 tests, 1 failure
** (Mix) verify.example failed (2)
```

The single failure, verbatim:

```
  1) test prod mix demo.reset fails fast without DEMO_ALLOW_RESET=1 (ThreadlinePhoenix.DemoResetTest)
     test/threadline_phoenix/demo_reset_test.exs:56
     ** (ExUnit.TimeoutError) test timed out after 60000ms. You can change the timeout:
     ...
     code: System.cmd(
     stacktrace:
       (elixir 1.17.3) lib/system.ex:1142: System.do_port_byte/3
       (elixir 1.17.3) lib/system.ex:1131: System.do_cmd/3
       test/threadline_phoenix/demo_reset_test.exs:69: (test)
```

**Cause — a CI-only test-harness defect, not a demo-seed defect and not a product
defect.** `demo_reset_test.exs:69` is a `System.cmd("mix", ["demo.reset"], cd:
@app_dir, env: [{"MIX_ENV", "prod"}], stderr_to_stdout: true)` — it shells out to a
*separate* `MIX_ENV=prod` Mix invocation to prove that `mix demo.reset` refuses to
run in prod without `DEMO_ALLOW_RESET=1`. On a cold CI checkout there is no
`_build/prod`, so that child process must compile the example app **and all of its
dependencies** in the `prod` environment before the `DEMO_ALLOW_RESET` guard it is
asserting on is ever reached. That compile exceeds ExUnit's 60 000 ms default
timeout, and the test carries no `@tag timeout:` budget covering the shell-out.
A secondary symptom in the same log confirms the shape — the owning process held its
Ecto connection past the ownership timeout while blocked on the port:
`Postgrex.Protocol ... disconnected: ** (DBConnection.ConnectionError) owner
#PID<0.820.0> (:proc_lib) timed out because it owned the connection for longer than
60000ms`.

**This is NOT one of the failures plans 198-23/24/25 targeted, and those fixes
held.** The demo-seed content-mismatch class D-41 named — 8–9 `Ecto.NoResultsError`
/ assertion mismatches in `DemoContractTest`, `WalkthroughHappyPathTest`,
`WalkthroughEvidenceTest` — is **gone**: the job reports `109 tests, 1 failure`, and
the one failure is this timeout. Round 3's own cause (`33204829086`: 9 demo-seed
content failures) and round 2's (`33197493051`: missing `ALTER DATABASE ... SET
search_path`) are both closed. This is the **third distinct cause** to hold this
lane red across four rounds.

**Ordering edge (GREEN-04) — the local and CI figures disagree, and both are shown
side by side rather than the newer silently replacing the older:**

| Measurement | Provenance | Result |
|---|---|---|
| Local `mix verify.example`, run 1 | Plan 198-25 closing measurement, repo root, warm `_build`, `.planning/audits/198-round4-demo-seed.md` (`Finished in 36.6 seconds`) | `109 tests, 0 failures` |
| Local `mix verify.example`, run 2 | Plan 198-25 closing measurement, immediately consecutive (`Finished in 14.7 seconds`) | `109 tests, 0 failures` |
| **CI `mix verify.example`** | **Run `33253587315`, job `Run test suite (current)` (`99103350741`), step `Verify Threadline Phoenix example` (`Finished in 96.1 seconds`)** | **`109 tests, 1 failure`** |

The disagreement is explained, not averaged: locally `_build/prod` is already warm,
so the child `mix demo.reset` returns in seconds and the assertion passes; the 36.6s
and 14.7s local wall clocks against CI's 96.1s are themselves the signature of that
warm/cold difference. **Per D-01 the local 0-failure figure is a readiness signal
only. The CI figure is the evidence. GREEN-04 follows the CI figure.**

#### (f)(2) `Example app browser E2E (Playwright)` — `verify-example-browser`

**Conclusion: `failure`.** Step `Run example Playwright suite` →
`** (Mix) verify.example_browser failed (1)`. Verbatim summary:

```
  5 failed
  9 skipped
  188 did not run
  138 passed (5.4m)
```

**Read the count with its censoring, stated up front:** the log also records
`Testing stopped early after 5 maximum allowed failures.`
`examples/threadline_phoenix/e2e/playwright.config.ts:141` sets
`maxFailures: process.env.CI ? 5 : 0`. **The "5 failed" figure is therefore
right-censored at exactly 5 — it is a floor, not a census, and 188 tests never
ran.** Round 3's count was also 5, under the same cap. **"5 vs 5, delta 0" must NOT
be read as "no progress": both numbers are the cap.** What *can* be compared is
composition, and it changed completely.

**Round 3's five failing tests all pass on this run** — confirmed by name in run
`33253587315`'s own log:

| Round 3 failing test | Round 4 result |
|---|---|
| `operator-find-mobile.spec.ts:48:3` | `✓ 36 ... (765ms)` |
| `operator-find-mobile.spec.ts:66:3` | `✓ 37 ... (774ms)` |
| `operator-find-mobile.spec.ts:103:3` | `✓ 39 ... (535ms)` |
| `operator-phase-135-uat.spec.ts:76:3` | `✓ 55 ... (512ms)` |
| `operator-phase-173-uat.spec.ts:74:3` | `✓ 58 ... (1.1s)` |

**198-28's two CI-contributing rows also pass:**
`✓ 117 [desktop-chromium] › tests/operator-screenshots.spec.ts:90:3 › admin
investigation and governance surfaces (8.7s)` and `✓ 118 ... :174:3 › empty and
denied states (4.2s)`. **198-26/27/28's fixes held, measured on CI.** The lane is red
on five *different* tests that the round-3 run's own `maxFailures: 5` cap prevented
from ever executing.

**Row-by-row cross-check against `.planning/audits/198-round4-playwright.md`
`## Post-merge re-validation (198-28)` — was each failure in the CI-contributing set
198-26/27/28 believed closed?**

| # | Failing test (all `[desktop-chromium]`) | In 198-28's inventory? | Believed closed? | Prediction status |
|---|---|---|---|---|
| 1 | `operator-accessibility.spec.ts:565:3` › keeps Exports queue and download states named and keyboard reachable | **Yes** — rows 31/32, logged as **`unassigned` / new discovery, out of 198-28's `files_modified`** | **No** — explicitly recorded as needing a follow-up plan | **Predicted.** The pre-push prediction named this file and line by name. |
| 2 | `operator-prove-mobile.spec.ts:38:3` › exports dense state keeps readiness hierarchy and ready-only primary action | **Yes** — rows 33/34, same `unassigned` disposition | **No** | **Predicted.** Also named by line in the pre-push prediction. |
| 3 | `operator-responsive-mobile-first.spec.ts:577:5` › operator responsive matrix: phone › keeps every operator route usable without root horizontal overflow | **No** — `grep -c "operator-responsive-mobile-first" .planning/audits/198-round4-playwright.md` returns **0** | n/a — never inventoried | **Un-inventoried CI-only discovery.** |
| 4 | `operator-stress.spec.ts:277:5` › ledger-owned stress screenshots › `page.home.happy` dark 1024px matches its ledger baseline | **No** — `grep -c "operator-stress" ...playwright.md` returns **0** | n/a | **Un-inventoried. Red by construction (D-39).** |
| 5 | `operator-stress.spec.ts:277:5` › ledger-owned stress screenshots › `page.timeline.empty` dark 1024px matches its ledger baseline | **No** — same | n/a | **Un-inventoried. Red by construction (D-39).** |

**Prediction-miss assessment for this lane, stated plainly: the lane's *conclusion*
was predicted correctly (`failure`, a hit), but the *composition* was only 2/5
predicted. Three of the five failing tests appear in no audit row anywhere in this
round's inventory. The inventory in `198-round4-playwright.md` was built from
*unbounded local* runs (`process.env.CI` unset, `maxFailures: 0`), and it is
therefore a poor predictor of which five tests a capped CI run will surface: it
covers a different, non-nested population (local runs skip
`operator-screenshot-regression.spec.ts` never, CI skips it entirely; CI stops at 5,
local does not stop). That is the most likely reason from the logs, and it is a
methodological miss worth carrying into any round 5.**

Per-failure causes:

1. **`operator-accessibility.spec.ts:565:3`** — `Locator: getByTestId('export-jobs').getByText(/Expired|File unavailable/).first()` → `Error: element(s) not found`, at `operator-accessibility.spec.ts:612`. **Cause, already established and cited: `deferred-items.md`'s Plan 198-28 entry — `fix(198-25)`'s label-copy change from `"Expired"` to `"Export expired"` (lowercase `expired`) no longer matches the capital-`E` `/Expired|.../` regex.** Not a seed-content change (`demo/seed/exports.ex` was not touched); the corrected diagnosis is recorded in `WINDOWS.md` #10/#11. Out of 198-28's and 198-29's `files_modified`; owned by a follow-up plan.
2. **`operator-prove-mobile.spec.ts:38:3`** — `Locator: getByText(/Expired|File unavailable/).first()` → `Error: element(s) not found`, at `operator-prove-mobile.spec.ts:60`. **Identical cause and citation to (1).**
3. **`operator-responsive-mobile-first.spec.ts:577:5`** — `Locator: getByRole('heading', { name: 'Row history', exact: true })` → `Error: element(s) not found`, at `operator-responsive-mobile-first.spec.ts:475` (helper), reached from `:587` / `:584`. **Cause: not established.** The phone-viewport route-usability matrix opens the row-history drawer and asserts an exact `Row history` heading; that heading does not resolve at phone width within 15 s. This is an **un-inventoried CI-only failure**, first observed on this run. It is NOT diagnosed further here: 198-29's `files_modified` contract is documentation-only, and speculating a cause without reading the component would be exactly the unmeasured attribution this phase exists to prevent. **Recorded as a new dated `deferred-items.md` entry with its verbatim locator, owned by a round-5 plan.**
4 & 5. **`operator-stress.spec.ts:277:5`, `page.home.happy` and `page.timeline.empty` (dark, 1024px)** — `expect(locator).toHaveScreenshot(expected) failed` at `operator-stress.spec.ts:293`, against `stress-page-home-happy-dark-1024-desktop-chromium.png` (`4779 pixels (ratio 0.02)`) and `stress-page-timeline-empty-dark-1024-desktop-chromium.png` (`5823 pixels (ratio 0.02)`), each against the call site's own `maxDiffPixelRatio: 0.01` (`operator-stress.spec.ts:294`). No dimension mismatch is reported — these are content-only diffs at matching dimensions, at roughly 2× their tolerance. **Cause and citation: these are `page.*` ledger baselines — the same D-39-forbidden regeneration class as the Tier A capture lane. Their only available remedy is regenerating committed `page.*` evidence, which D-39 forbids for this entire milestone. They are red by construction, not by defect, and nothing in this round may fix them.**

#### (f)(3) `Tier A capture lane (byte-stable evidence)` — `verify-capture`

**Conclusion: `failure`, exactly as predicted.** Failing step: `Assert byte-stable
regeneration (no drift from committed evidence)`
(`.github/workflows/ci.yml:550-558`), verbatim error:

```
::error::Tier A capture is not byte-stable, or committed evidence is stale.
Regenerate locally with 'mix verify.capture' and commit the result.
```

**Scope of the drift, counted from the step's own `git status --porcelain
.planning/scorecards/` output: 198 scorecard files modified — 120 `page.*` and 78
`refute.*`. Sum 198; no other prefix appears.**

**Honest limit on characterising that drift, stated rather than glossed:** the step
prints `git diff -- .planning/scorecards/ | head -200` — the diff is **truncated at
200 lines by the workflow itself**. The visible portion covers 15 files
(`page.actor.happy__{dark,light}-{375,768,1280}`,
`page.coverage.empty__{dark,light}-{375,768,1280}`,
`page.coverage.error__dark-{375,768,1280}`, `page.coverage.error__light-1280`) and
every visible hunk is a **single `scroll_cost` field**, keyed deterministically by
viewport:

| Viewport | Committed | Regenerated |
|---|---|---|
| 1280 | `18.803` | `40.8` |
| 768 | `19.038` | `36.504` |
| 375 | `19.85` | `41.953` |

These are **byte-identical to rounds 2 and 3's measured values**, confirming the
drift is deterministic and reproducible, not measurement noise, exactly as 198-16
diagnosed. **The remaining 183 files — including all 78 `refute.*` cells — are not
visible in the truncated diff, and this record therefore does NOT claim the drift is
confined to `scroll_cost` or to `page.*` cells. It claims only what the log shows.**

**Citation: D-39, pointing to `.planning/audits/198-tier-a-byte-stability.md`.** The
only available remedy is Tier-A `page.*` scorecard regeneration, forbidden for this
milestone. **No remedy was attempted, no scorecard was regenerated, and the lane was
not removed from `needs:`. This lane is red by construction, not by defect.**

### (g) Wall-clock ≤20-minute evaluation

**Measured: 8m11s (`2026-08-29T12:52:18Z` → `2026-08-29T13:00:29Z`).**
`8m11s ≤ 20m00s` — **the ≤20-minute clause is satisfied**, and by a wider margin
than round 3's 13m29s (the Playwright lane finished 5m7s sooner, having stopped early
at its 5-failure cap). **This is not the clause blocking GREEN-07.**

### (h) `CI required` conclusion

**Literal conclusion string: `"failure"`.**

**Is it exactly `success`? No.**

### (i) `mergeStateStatus`

```
$ gh pr view 31 --json number,state,isDraft,mergeStateStatus,url,headRefName
{"headRefName":"ci/198-round4","isDraft":true,"mergeStateStatus":"BLOCKED","number":31,"state":"OPEN","url":"https://github.com/szTheory/threadline/pull/31"}
```

### (j) Headline claim — true, false, or true-subject-to-a-merge

The phase goal's headline claim — "`origin/main` carries every local commit and its
CI concludes green" — is **false** as of this measured run, and not
true-subject-to-a-merge either. Two figures, not a narrative:

- `git log origin/main..f433ef3e --oneline | wc -l` = **137**. `origin/main` does not
  carry these commits.
- PR #31's `mergeStateStatus` = **`BLOCKED`**, not `CLEAN`/`UNSTABLE`, because
  `CI required` concluded `failure`. It is also `isDraft: true` by design.

### (k) Re-run discipline

**`attempt: 1`.** No check in this run was re-run, re-dispatched, or selectively
retried, for any reason. The run was observed to its single natural completion. There
was no second attempt to explain, because there was no second attempt.

(For completeness and to avoid a false claim: Playwright's own in-suite
`retries` produced `(retry #1)` lines for each failing spec — that is the test
runner's configured per-test retry inside a single job execution, visible in the job
log, and is not a workflow re-run, job re-dispatch, or `gh run rerun`. No GitHub
Actions attempt beyond 1 exists for run `33253587315`.)

---

## Round 5 (2026-08-30) — Prediction stated before the push

Written **before** `git push`, per plan 198-37 Task 1. One row per `ci-required`'s 12 `needs:`
members, plus the `CI required` aggregate itself, with a predicted conclusion and a one-line basis
grounded in this round's own tree-level evidence — `198-round5-review-triage.md` (plan 198-36's
20-row triage ledger) and the 198-30…198-36 SUMMARYs — never in plan promises.

| `needs:` member | Check name | Predicted conclusion | Basis |
|---|---|---|---|
| `verify-format` | Check formatting | success | Unaffected; no formatting-relevant file touched by 198-30..36; green on every prior round. |
| `verify-credo` | Run Credo (strict) | success | Unaffected; no lib-code style surface changed this round beyond the targeted fixes, all of which are within existing Credo-clean modules. |
| `verify-compile-no-optional` | Compile without optional deps | success | Unaffected; green on rounds 1-4, no optional-dep surface touched this round. |
| `verify-test` | Run test suite (current) | **success** | Round 4's sole GREEN-04 blocker (`demo_reset_test.exs:56`, `ExUnit.TimeoutError` from a cold `MIX_ENV=prod` compile inside the 60000ms per-test budget) was moved out of that budget by plan 198-30's `setup_all` restructure (198-round5-review-triage.md row IN-03: cold=30.3s/warm=0.73s/warm-guard-only=0.748s, inside the default). Both prior causes underneath it (missing `search_path` ALTER, demo-seed content mismatches) were already closed in rounds 2-4 and untouched since. Orchestrator-measured local figures at this merged head (readiness signal only, per D-01 — NOT admissible evidence): `mix test` 1433 tests, 0 failures (1 excluded); `mix verify.example` 109 tests, 0 failures. |
| `verify-hex-evaluator` | Hex evaluator smoke (threadline from hex.pm) | success | Unaffected; no Hex-publish-path or evaluator file touched this round. |
| `verify-example-browser` | Example app browser E2E (Playwright) | **failure** | `198-round5-review-triage.md`'s "Structurally uncloseable inside milestone v1.41" section names two `operator-stress.spec.ts` `page.*` ledger-baseline diffs (`page.home.happy`, `page.timeline.empty`, dark 1024px) whose only remedy is `page.*` baseline regeneration, forbidden by D-39 for the whole milestone — no round-5 plan's `files_modified` touches `operator-stress.spec.ts`'s baseline PNGs (confirmed empty by every round-5 plan's own verification section, restated in that ledger). The two `/Expired/` locator rows and the `operator-responsive-mobile-first.spec.ts:577:5` cause were fixed at cause by 198-31 (local pass confirmed both projects), but those closures cannot outweigh the two D-39-forced rows still present. **Carrying round 4's own methodological lesson forward explicitly:** the unbounded local Playwright inventory samples a different, non-nested population from CI's `maxFailures: 5`-capped run (`playwright.config.ts:141`), so this prediction is confident on the lane's *conclusion* (`failure`, forced by the two D-39 rows alone) but weakly grounded on its exact five-test *composition* — it is labelled as such rather than stated with false confidence, per round 4's f(2) finding. |
| `verify-mechanical` | Mechanical checker (committed scorecards) | success | Unaffected; no Tier-A scorecard or mechanical-checker file touched this round (D-39 forbids Tier-A work entirely). |
| `verify-capture` | Tier A capture lane (byte-stable evidence) | **failure** | D-39 — only remedy (Tier-A `page.*` scorecard regeneration) forbidden this milestone; no round-5 plan touched the Tier A capture lane, its specs, or its scorecards. `scroll_cost` drift has been deterministic and byte-identical across rounds 2, 3, and 4. |
| `verify-pgbouncer-topology` | PgBouncer transaction topology | success | Unaffected; green on rounds 2-4, no topology-test file touched this round. |
| `verify-docs` | Build ExDoc (dev) | success | Unaffected; no doc-generation-relevant file touched this round. |
| `verify-hex-package` | Hex package tarball | success | Unaffected; no package-manifest file touched this round. |
| `verify-release-shape` | Release metadata (version / changelog) | success | Unaffected; no `CHANGELOG.md`/`mix.exs` version-metadata file touched this round. |
| **`CI required`** (aggregate) | CI required | **failure** | Two `needs:` members (`verify-example-browser`, `verify-capture`) are predicted red; `re-actors/alls-green` fails the aggregate under `if: always()` if any required job is not `success`. |

**Predicted red-`needs:`-member count: 2** (`verify-example-browser`, `verify-capture`) — down from
round 4's measured 3, because `verify-test` is predicted to close this round on the strength of
198-30's `setup_all` fix to its distinct, round-4-diagnosed cause.

**The ceiling, stated plainly before the run:** `CI required` cannot conclude `success` this round.
The Tier A capture lane and the two `operator-stress.spec.ts` `page.*` rows are red by construction
under D-39 — no plan in this round attempted, or was permitted to attempt, their only available
remedy (Tier-A evidence regeneration). **GREEN-07 therefore cannot reach Complete this round on any
basis**, regardless of what the run measures for `verify-test` or any other lane. GREEN-04, by
contrast, is the one requirement this round's evidence supports predicting closed — it depends only
on `Run test suite (current)`'s own conclusion, and this round's fix targets that lane's own
round-4-diagnosed cause directly.

This prediction is committed **before** Task 2 raises the push checkpoint. A prediction that lands
in the same commit as its result is not a prediction, and it will be scored — not amended — once the
measured run in Task 3 completes.

---

## Round 5 (2026-08-30) — Measured CI run (Plan 198-37, gap-closure round 5)

**Push.** The user pushed local branch `ci/198-round5` (HEAD `14f923a71c0901cd5f95fc3a72e0971b05861543`,
carrying all of 198-01 through 198-36 plus this plan's own Task 1 prediction commit `14f923a7
docs(198-37): state Round 5 pre-push prediction`) by hand — `git push` from the agent session is
blocked by a local classifier, and this decision belongs to the person who owns the remote (T-198-37-01).

```
$ git ls-remote --heads origin ci/198-round5
14f923a71c0901cd5f95fc3a72e0971b05861543	refs/heads/ci/198-round5
```

Matches the prepared local head SHA character for character. `git ls-remote --heads origin
'ci/198-*'` at the same moment lists five refs, four distinct from round 5's own:

```
d941ae1050c639121bdb5c1cc6fd8ea13e6cfafc	refs/heads/ci/198-05-verify
f748e43d7e4c1e63a0142569a55f57c7187e5cb1	refs/heads/ci/198-gap-closure
80bf701e7486962e538d16f213874cbba8f24115	refs/heads/ci/198-round3
f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6	refs/heads/ci/198-round4
14f923a71c0901cd5f95fc3a72e0971b05861543	refs/heads/ci/198-round5
```

`git log origin/main..14f923a7 --oneline | wc -l` = **186** — `origin/main`
(`a97f527e375f4c1909236b7dbdd5fa3fd9b7d2f2`) does not carry these 186 commits; that gap closes only
if/when a PR merges.

**Pull request — a measurement vehicle, not a merge request.**

```
$ gh pr view 32 --json number,state,isDraft,mergeStateStatus,url,headRefName,body
{"body":"Measurement vehicle for Phase 198 gap-closure round 5. DO NOT MERGE.","headRefName":"ci/198-round5","isDraft":true,"mergeStateStatus":"BLOCKED","number":32,"state":"OPEN","url":"https://github.com/szTheory/threadline/pull/32"}
```

PR **#32**, `isDraft: true`, body containing the literal string **DO NOT MERGE**.

### The run

**Ordering edge — satisfied by uniqueness, stated explicitly rather than left silent:**

```
$ gh run list --branch ci/198-round5 --limit 10 --json databaseId,conclusion,headSha,status,createdAt,event
[{"conclusion":"failure","createdAt":"2026-08-30T21:31:21Z","databaseId":33336651956,"event":"pull_request","headSha":"14f923a71c0901cd5f95fc3a72e0971b05861543","status":"completed"}]
```

`gh run list --branch ci/198-round5` returned **exactly one** run for this head SHA. There are no
competing run ids, so no most-recent-completed selection among rivals was needed; this run is
authoritative by construction, not by choice.

```
$ gh run view 33336651956 --json status,conclusion,createdAt,updatedAt,attempt,headSha,event
{"attempt":1,"conclusion":"failure","createdAt":"2026-08-30T21:31:21Z","event":"pull_request","headSha":"14f923a71c0901cd5f95fc3a72e0971b05861543","status":"completed","updatedAt":"2026-08-30T21:42:29Z"}
```

- **Run ID:** `33336651956`
- **Head SHA:** `14f923a71c0901cd5f95fc3a72e0971b05861543` — character-for-character identical to the
  pushed local head SHA above.
- **Event:** `pull_request`
- **Conclusion:** `failure`
- **Attempt:** `1` — no rerun, re-dispatch, or selective retry occurred at any point; the run was
  observed to its single, natural completion via a polling wait on `status == completed`, which
  correctly ran to full length rather than concluding early.
- **Wall clock:** `21:31:21Z` → `21:42:29Z` = **11m8s**

### (a) Per-job table

All 13 named jobs the run reported, with `CI required` called out separately — 14 checks total,
matching every prior round's count.

| Check | Conclusion | Duration (started → completed) |
|---|---|---|
| Check formatting | ✓ success | 21:31:23 → 21:31:43 (20s) |
| Run Credo (strict) | ✓ success | 21:31:24 → 21:32:26 (1m2s) |
| Compile without optional deps | ✓ success | 21:31:23 → 21:32:26 (1m3s) |
| Run test suite (min) | ✓ success | 21:31:24 → 21:34:53 (3m29s) |
| Run test suite (current) | ✓ **success** | 21:31:24 → 21:39:02 (7m38s) |
| Hex evaluator smoke (threadline from hex.pm) | ✓ success | 21:31:24 → 21:32:26 (1m2s) |
| PgBouncer transaction topology | ✓ success | 21:31:24 → 21:33:24 (2m0s) |
| Mechanical checker (committed scorecards) | ✓ success | 21:31:23 → 21:32:51 (1m28s) |
| Tier A capture lane (byte-stable evidence) | ✗ **failure** | 21:31:24 → 21:37:21 (5m57s) |
| Example app browser E2E (Playwright) | ✗ **failure** | 21:31:23 → 21:42:23 (11m0s) |
| Build ExDoc (dev) | ✓ success | 21:31:24 → 21:32:36 (1m12s) |
| Hex package tarball | ✓ success | 21:31:24 → 21:31:42 (18s) |
| Release metadata (version / changelog) | ✓ success | 21:31:24 → 21:31:31 (7s) |
| **`CI required` (aggregate)** | **✗ failure** | 21:42:25 → 21:42:28 (3s) |

**Empty edge — stated affirmatively rather than left silent: job-conclusion collection was NOT
empty. 14 conclusions were collected (13 named jobs + the aggregate). A zero-length collection
would have been recorded as failed collection, not as a pass; this collection is non-empty and
complete.**

### (b) Verbatim `re-actors/alls-green` output — all 12 `needs:` members

From the `CI required` job's own "Decide whether all needed jobs succeeded" step (job id
`99326011873`), verbatim:

```
# ❌ Some of the required to succeed jobs failed 😢😢😢
✓ verify-format → 🟢 success [required to succeed]
✓ verify-credo → 🟢 success [required to succeed]
✓ verify-compile-no-optional → 🟢 success [required to succeed]
✓ verify-test → 🟢 success [required to succeed]
✓ verify-hex-evaluator → 🟢 success [required to succeed]
❌ verify-example-browser → 🔴 failure [required to succeed]
✓ verify-mechanical → 🟢 success [required to succeed]
❌ verify-capture → 🔴 failure [required to succeed]
✓ verify-pgbouncer-topology → 🟢 success [required to succeed]
✓ verify-docs → 🟢 success [required to succeed]
✓ verify-hex-package → 🟢 success [required to succeed]
✓ verify-release-shape → 🟢 success [required to succeed]
```

The same step's input payload records `allowed-failures: []` and `allowed-skips: []` — no member
was pre-authorised to fail or skip.

**Member counts: `success` 10, `failure` 2, `skipped` 0, `cancelled` 0. Sum: 12, equal to the
`needs:` list's own cardinality.**

**Adjacency edge (GREEN-07), stated explicitly:** a lane counts as met here only on the exact
conclusion string `success`. `neutral`, `skipped` and `cancelled` are each recorded as
**not-success**. This matters because `re-actors/alls-green` would score a `skipped` required check
as passing — a green aggregate could therefore be manufactured by skipping a lane rather than fixing
it, which is exactly the laundering D-09 rejects. On this run the point is moot in the maintainer's
favour: zero members reported `skipped` or `cancelled`, so no member's verdict was laundered, and the
aggregate's `failure` is traceable entirely to two genuine `failure` conclusions.

### (c) Prediction scorecard

Scored against `## Round 5 (2026-08-30) — Prediction stated before the push`, which was committed to
disk in `14f923a7` **before** `git push`. Nothing below has been retro-edited; a missed row is
written as a miss, and a hit is written as a hit without softening either way.

| `needs:` member | Check name | Predicted | Actual | Hit / miss |
|---|---|---|---|---|
| `verify-format` | Check formatting | success | success | hit |
| `verify-credo` | Run Credo (strict) | success | success | hit |
| `verify-compile-no-optional` | Compile without optional deps | success | success | hit |
| `verify-test` | Run test suite (current) | success | **success** | **hit** |
| `verify-hex-evaluator` | Hex evaluator smoke (threadline from hex.pm) | success | success | hit |
| `verify-example-browser` | Example app browser E2E (Playwright) | failure | failure | hit (conclusion); composition partial miss — see below |
| `verify-mechanical` | Mechanical checker (committed scorecards) | success | success | hit |
| `verify-capture` | Tier A capture lane (byte-stable evidence) | failure | failure | hit |
| `verify-pgbouncer-topology` | PgBouncer transaction topology | success | success | hit |
| `verify-docs` | Build ExDoc (dev) | success | success | hit |
| `verify-hex-package` | Hex package tarball | success | success | hit |
| `verify-release-shape` | Release metadata (version / changelog) | success | success | hit |
| **`CI required`** (aggregate) | CI required | failure | failure | hit |

**Conclusion-level hit rate: 13/13 (12/12 `needs:` members plus the aggregate).** Every predicted
conclusion string was correct, including `verify-test`'s predicted `success` — 198-30's `setup_all`
restructure closed the round-4-diagnosed cold-compile cause, confirmed on the measured CI job itself
(see (f) below).

**One composition-level partial miss, scored honestly rather than absorbed into the conclusion hit:**
the prediction's basis for `verify-example-browser` named "the two `operator-stress.spec.ts` `page.*`
rows" (`page.home.happy`, `page.timeline.empty`) from `198-round5-review-triage.md`'s "Structurally
uncloseable" section. The measured run failed on those two rows **plus a third, un-cited row**:
`footgun.transaction-page-left-push-desktop` dark 1024px (same `ciScreenshotAllowlist()` mechanism,
same `toHaveScreenshot`-against-committed-baseline remedy class, same D-39 prohibition — see (f)(1)).
The prediction explicitly flagged this exact failure mode in advance ("weakly grounded... labelled as
such rather than stated with false confidence, per round 4's f(2) finding"), and that flag held: the
lane's *conclusion* (`failure`) was predicted correctly with full confidence, but its *composition*
(3 failing tests, not 2) was under-enumerated. This is recorded as a genuine partial miss, not
retroactively folded into a clean hit.

**A second, more consequential note the prediction correctly anticipated but is worth stating in its
own right:** for the first time across all five rounds, this run's `Example app browser E2E` job did
**not** hit `playwright.config.ts:141`'s `maxFailures: 5` cap. Only 3 tests failed — below the
5-failure ceiling that right-censored every prior round's count — so the suite ran to its own natural
end: `312 passed`, `3 failed`, `25 skipped` (Playwright-level `test.skip`, not a CI/workflow skip).
This is the first round where the lane's failure count is a **census, not a floor**.

### (d) Six-column baseline comparison — "N of 7 now green"

Extending round 4's five-column table (baseline `33138291361`, round 1 `33183920952`, round 2
`33197493051`, round 3 `33204829086`, round 4 `33253587315`) with round 5 (`33336651956`, fetched
fresh via `gh run view 33336651956 --json jobs`):

| Job | Baseline (33138291361) | Round 1 (33183920952) | Round 2 (33197493051) | Round 3 (33204829086) | Round 4 (33253587315) | Round 5 (33336651956) |
|---|---|---|---|---|---|---|
| Compile without optional deps | ✗ failure | ✓ success | ✓ success | ✓ success | ✓ success | ✓ success |
| Mechanical checker (committed scorecards) | ✗ failure | ✓ success | ✓ success | ✓ success | ✓ success | ✓ success |
| PgBouncer transaction topology | ✗ failure | ✗ failure | ✓ success | ✓ success | ✓ success | ✓ success |
| Run test suite (min) | ✗ failure | ✗ failure | ✓ success | ✓ success | ✓ success | ✓ success |
| Run test suite (current) | ✗ failure | ✗ failure | ✗ failure | ✗ failure | ✗ failure | **✓ success (198-30's fix — see (f))** |
| Tier A capture lane (byte-stable evidence) | ✗ failure | ✗ failure | ✗ failure | ✗ failure | ✗ failure | ✗ failure (unchanged, D-39) |
| Example app browser E2E (Playwright) | ✗ failure | ✗ failure | ✗ failure | ✗ failure | ✗ failure | ✗ failure (3 failures, no longer capped — D-39 class, see (f)(1)) |
| **`CI required` (aggregate)** | ✗ failure | ✗ failure | ✗ failure | ✗ failure | ✗ failure | ✗ failure |

**5 of the 7 originally-red baseline jobs are green as of round 5 — up from round 4's 4.**
`Run test suite (current)` crossed to green this round; no job regressed.

### (e) Red `needs:` count

**Red `needs:` members: 2** — `verify-example-browser`, `verify-capture`.

**Round 4's count: 3. Delta: −1.**

**This round's stated target was 2. The target was HIT exactly.** `verify-test` closed as predicted;
the two remaining red lanes are both the ones D-39 forbids fixing, exactly as the plan's ceiling
stated before the run.

### (f) Root cause for every still-red check

#### (f)(1) `Example app browser E2E (Playwright)` — `verify-example-browser`

**Conclusion: `failure`.** Step `Run example Playwright suite` → `** (Mix) verify.example_browser
failed (1)`. Verbatim summary:

```
##[notice]  3 failed
  25 skipped
  312 passed (8.3m)
```

All 3 failures, by name (all `[desktop-chromium]`, all `tests/operator-stress.spec.ts:277:5 ›
ledger-owned stress screenshots ›`):

```
page.home.happy dark 1024px matches its ledger baseline
page.timeline.empty dark 1024px matches its ledger baseline
footgun.transaction-page-left-push-desktop dark 1024px matches its ledger baseline
```

Each fails identically — `expect(locator).toHaveScreenshot(expected) failed` against
`getByTestId('stress-preview')`, with 4779–5823-pixel diffs (ratio ~0.02) against each row's
committed baseline PNG at `maxDiffPixelRatio: 0.01` — a content-only diff at matching dimensions,
roughly 2× tolerance, the same shape as round 4's two `page.*` failures.

**Cause and citation — all three rows are the same D-39-forbidden class, confirmed by mechanism:**
`operator-stress.spec.ts:276-296` generates one test per `ciScreenshotAllowlist()` entry and asserts
`toHaveScreenshot(item.baseline_ref, ...)` against a committed snapshot PNG under
`tests/operator-stress.spec.ts-snapshots/`. `page.home.happy` and `page.timeline.empty` are the two
rows `198-round5-review-triage.md`'s "Structurally uncloseable inside milestone v1.41" section
named in advance, citing `198-31-SUMMARY.md`'s "Next Phase Readiness" as the origin diagnosis.
`footgun.transaction-page-left-push-desktop` (`operator-stress.spec.ts:167`) is the same mechanism —
its own ledger-baseline screenshot — that this round's local un-inventoried evidence did not surface
(a genuine methodological gap, scored honestly in (c) above), but its remedy is identical: baseline
regeneration, forbidden by D-39 for this milestone. `git diff --stat ab412fdd..14f923a7 -- '*.png'`
(the round's full commit range) is empty — no round-5 plan touched any baseline PNG, confirming the
row was never in scope to fix.

**A structural change worth recording plainly:** this is the first round where the lane's failure
count is not right-censored by `playwright.config.ts:141`'s `maxFailures: 5`. `312 passed, 3 failed,
25 skipped` is the suite's actual, complete result — not a floor. All of round 4's `verify-test`-side
demo-seed and cold-compile fixes (198-23…198-30) and this round's Playwright fixes (198-31, 198-33)
evidently closed enough of the population that the cap is no longer binding. **This is real,
measured progress inside the lane even though its conclusion string is unchanged** — the same
distinction round 4's f(2) drew between "conclusion" and "composition," now resolved in the
maintainer's favour: composition improved from an opaque 5-failure floor to a fully-enumerated
3-failure census, and all 3 are the identical, already-cited D-39 class.

#### (f)(2) `Tier A capture lane (byte-stable evidence)` — `verify-capture`

**Conclusion: `failure`, exactly as predicted.** Failing step: `Assert byte-stable regeneration (no
drift from committed evidence)`, verbatim error:

```
::error::Tier A capture is not byte-stable, or committed evidence is stale.
Regenerate locally with 'mix verify.capture' and commit the result.
```

**Scope of the drift, counted from the step's own `git status --porcelain .planning/scorecards/`
output: 198 scorecard files modified — 120 `page.*` and 78 `refute.*`, identical composition to every
prior round.**

`scroll_cost` values, sampled from the visible diff — **byte-identical to rounds 2, 3, and 4**:

| Viewport | Committed | Regenerated |
|---|---|---|
| 1280 | `18.803` | `40.8` |
| 768 | `19.038` | `36.504` |
| 375 | `19.85` | `41.953` |

**Citation: D-39, pointing to `.planning/audits/198-tier-a-byte-stability.md`.** The only available
remedy is Tier-A `page.*` scorecard regeneration, forbidden for this milestone. No remedy was
attempted, no scorecard was regenerated, and the lane was not removed from `needs:`. This lane is red
by construction, not by defect — unchanged from rounds 2 through 4.

### (g) Wall-clock ≤20-minute evaluation

**Measured: 11m8s (`2026-08-30T21:31:21Z` → `2026-08-30T21:42:29Z`).** `11m8s ≤ 20m00s` — **the
≤20-minute clause is satisfied**, wider margin than round 3's 13m29s, narrower than round 4's 8m11s
(the Playwright lane now runs its full, uncapped suite rather than stopping at 5 failures, which adds
wall clock even as it removes ambiguity).

### (h) `CI required` conclusion

**Literal conclusion string: `"failure"`.**

**Is it exactly `success`? No.**

### (i) `mergeStateStatus`

```
$ gh pr view 32 --json number,state,isDraft,mergeStateStatus,url,headRefName
{"headRefName":"ci/198-round5","isDraft":true,"mergeStateStatus":"BLOCKED","number":32,"state":"OPEN","url":"https://github.com/szTheory/threadline/pull/32"}
```

### (j) Headline claim — true, false, or true-subject-to-a-merge

The phase goal's headline claim — "`origin/main` carries every local commit and its CI concludes
green" — is **false** as of this measured run, and not true-subject-to-a-merge either. Two figures,
not a narrative:

- `git log origin/main..14f923a7 --oneline | wc -l` = **186**. `origin/main` does not carry these
  commits.
- PR #32's `mergeStateStatus` = **`BLOCKED`**, not `CLEAN`/`UNSTABLE`, because `CI required` concluded
  `failure`. It is also `isDraft: true` by design.

### (k) Re-run discipline

**`attempt: 1`.** No check in this run was re-run, re-dispatched, or selectively retried, for any
reason. The run was observed to its single natural completion via a wait on GitHub's own `status`
field reaching `completed`. There was no second attempt to explain, because there was no second
attempt.

### (l) `.github/`, `CONTRIBUTING.md`, Playwright config, and scorecard invariants (D-42)

```
$ git diff --stat ab412fdd..14f923a7 -- .github/ CONTRIBUTING.md examples/threadline_phoenix/e2e/playwright.config.ts .planning/scorecards/ '*.png'
(empty — exit 0)
```

No gate was narrowed, no config weakened, no evidence regenerated across the full round-5 commit
range. `CI required`'s guarantee is exactly as strong on this run as it was on round 4's; two lanes
are red for the identical reasons cited above, not because the aggregate's meaning shrank.

---

## Round 6 (2026-08-30) — Prediction stated before the push

Written **before** `git push`, per plan 198-40 Task 1. One row per `ci-required`'s 12 `needs:`
members, plus the `CI required` aggregate itself, with a predicted conclusion and a one-line basis
grounded in this round's own tree-level evidence — `198-38-SUMMARY.md`'s file list and plan-level
verification, and `198-39-SUMMARY.md`'s planning-only file list — never in plan promises.

Round 6's own commit set is small and precisely scoped: plan 198-38 touched four source/test files
in `examples/threadline_phoenix/` (`demo/reset.ex`, `demo/seed.ex`, a new
`demo/advisory_lock_pinning_test.exs`, and a comment-only fix in
`walkthrough_evidence_test.exs`) plus one new planning file
(`198-round6-review-triage.md`). Plan 198-39 touched only planning records
(`REQUIREMENTS.md`, `ROADMAP.md`, `deferred-items.md`, `STATE.md`,
`198-39-DECISION.md`) — no source, no test, no config file. No plan in this round touched
`.github/`, `CONTRIBUTING.md`, `playwright.config.ts`, `.planning/scorecards/`, or any `*.png`.

| `needs:` member | Check name | Predicted conclusion | Basis |
|---|---|---|---|
| `verify-format` | Check formatting | success | Unaffected; neither 198-38 nor 198-39 touched a formatting-relevant file; green on every prior round. |
| `verify-credo` | Run Credo (strict) | success | Unaffected; 198-38's `reset.ex`/`seed.ex` edits are within already Credo-clean modules, and 198-39 touched no lib code at all. |
| `verify-compile-no-optional` | Compile without optional deps | success | Unaffected; no optional-dep surface touched this round; green on rounds 1-5. |
| `verify-test` | Run test suite (current) | **success** | **The new-risk lane this round.** 198-38 changed shipped example-app source (`demo/reset.ex`, `demo/seed.ex`) exercised by `mix verify.example`, and added a new async:false test module that manipulates `Sandbox.mode`. 198-38-SUMMARY.md's own plan-level verification, re-run at the end of that plan, recorded: `cd examples/threadline_phoenix && MIX_ENV=test mix compile --warnings-as-errors` exit 0 no warnings; `cd examples/threadline_phoenix && MIX_ENV=test mix test` → `111 tests, 0 failures`; `mix verify.example` (repo root) → `111 tests, 0 failures` (up from round 5's measured 109 — the 2 new `advisory_lock_pinning_test.exs` tests, consistent with the file added); `mix format --check-formatted` exit 0; `MIX_ENV=dev mix demo.reset` exit 0. These are readiness signals only per D-01, not admissible evidence — this row is the one this round's evidence supports predicting, but it is the one CI must re-prove, not assume, per this plan's own objective. |
| `verify-hex-evaluator` | Hex evaluator smoke (threadline from hex.pm) | success | Unaffected; no Hex-publish-path or evaluator file touched this round. |
| `verify-example-browser` | Example app browser E2E (Playwright) | **failure** | **Cannot close, per D-39.** Neither 198-38 nor 198-39 touched `operator-stress.spec.ts`, its baselines, or any Playwright config; `git diff --stat -- '*.png'` is empty across both plans' commits (confirmed in both SUMMARYs). Predicting the same three rows round 5 measured — `page.home.happy`, `page.timeline.empty`, `footgun.transaction-page-left-push-desktop` — all dark 1024px, all `ciScreenshotAllowlist()`-driven ledger-baseline diffs. **Carrying round 5's own methodological lesson forward explicitly:** round 5's prediction under-enumerated this exact row set by one (the third row was un-cited in advance), so this composition prediction is stated with the same caveat — a per-test composition prediction for the browser lane is weakly grounded even when the *conclusion* (`failure`) is not, and an additional row of the identical class would not be a surprise. |
| `verify-mechanical` | Mechanical checker (committed scorecards) | success | Unaffected; no Tier-A scorecard or mechanical-checker file touched this round (D-39 forbids Tier-A work entirely). |
| `verify-capture` | Tier A capture lane (byte-stable evidence) | **failure** | **Cannot close, per D-39.** No round-6 plan touched the Tier A capture lane, its specs, or its scorecards; `scroll_cost` drift has been deterministic and byte-identical across rounds 2 through 5. |
| `verify-pgbouncer-topology` | PgBouncer transaction topology | success | Unaffected; green on rounds 2-5, no topology-test file touched this round. |
| `verify-docs` | Build ExDoc (dev) | success | Unaffected; no doc-generation-relevant file touched this round. |
| `verify-hex-package` | Hex package tarball | success | Unaffected; no package-manifest file touched this round. |
| `verify-release-shape` | Release metadata (version / changelog) | success | Unaffected; no `CHANGELOG.md`/`mix.exs` version-metadata file touched this round. |
| **`CI required`** (aggregate) | CI required | **failure** | Two `needs:` members (`verify-example-browser`, `verify-capture`) are predicted red; `re-actors/alls-green` fails the aggregate under `if: always()` if any required job is not `success`. |

**Predicted red-`needs:`-member count: 2** (`verify-example-browser`, `verify-capture`) — unchanged
from round 5's measured 2, because this round's only lib/test-affecting plan (198-38) is scoped to
the `Run test suite (current)` lane, which is predicted to stay green on the strength of its own
local verification, not to move either D-39-forced lane.

**The ceiling, stated plainly before the run — restating the plan objective's own stated ceiling:**
`CI required` cannot conclude `success` this round. The Tier A capture lane and the three
`operator-stress.spec.ts` `page.*` rows are red by construction under D-39 — no plan in this round
attempted, or was permitted to attempt, their only available remedy (Tier-A evidence regeneration).
**GREEN-07 therefore cannot reach Complete this round on any basis**, and this is stated before the
run rather than discovered after it. GREEN-04, by contrast, is re-proved this round — not assumed —
because 198-38 changed the exact code `Run test suite (current)` exercises through `mix
verify.example`; if it goes red, that is 198-38 regressing GREEN-04, and the honest response is to
fix the cause, not to re-run the check.

**Carried requirements, restated as a decision, not a prediction:** GREEN-01, GREEN-02, GREEN-03,
GREEN-05, GREEN-06, GREEN-09, GREEN-10, GREEN-11, and GREEN-12 are already Complete and
independently re-verified at round 5; round 6 plans no new work for them and predicts no change to
their status. GREEN-07's status after this run follows `198-39-DECISION.md`'s recorded disposition
(option-a, accepted-Pending for v1.41) regardless of what this run measures — the disposition
explains the status, it does not, and cannot, satisfy the requirement on a measured `success`.

This prediction is committed **before** Task 2 raises the push checkpoint. A prediction that lands
in the same commit as its result is not a prediction, and it will be scored — not amended — once the
measured run in Task 3 completes.
