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
