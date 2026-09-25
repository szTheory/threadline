---
phase: 198-green-bringup
plan: 14
subsystem: testing
tags: [ecto, storage-schema, test-hygiene, contract-test, pgbouncer, tdd]

requires:
  - phase: 198-08
    provides: "the proven repo_opts() port recipe and the D-02 mask-regression guard (StorageSchemaMaskContractTest)"
  - phase: 198-12
    provides: "the mechanical application of the port recipe to 14 defective files, observed-failure-list methodology"
provides:
  - "pgbouncer_topology_test.exs ported to Threadline.StorageSchemaCase.repo_opts(), green through a real PgBouncer transaction pool"
  - "Threadline.StorageSchemaCallSiteContractTest — a static, source-level sweep that scans test/**/*.exs for unprefixed owned-schema Ecto call sites regardless of tag exclusion or environment gating"
  - "Threadline.StorageSchemaCase.owned_schema_modules/0 — the roster SSOT the sweep derives from"
affects: [198-VERIFICATION]

actuals:
  tokens: 41000
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Static source-scanning contract test (regex match + balanced-paren call-expression extraction, bounded for DoS safety) as a run-independent alternative to an observed-failure-list sweep — catches defects in tag-excluded/environment-gated files that never execute in a default run"
    - "Runtime-assembled / concatenation-built fixture strings inside a self-scanning contract test, so the test's own file does not trip its own detector (same idiom as zero_skips_contract_test.exs's runtime-assembled needles)"
    - "Structural (not file-name) recognition of a deliberate teeth-proof call site (lexically inside assert_raise's lambda or an open try/rescue block) so a D-02 mask-regression guard's own intentionally-unprefixed read is not misclassified as the defect it exists to prove is absent"

key-files:
  created:
    - test/threadline/storage_schema_call_site_contract_test.exs
  modified:
    - test/threadline/pgbouncer_topology_test.exs
    - test/support/storage_schema_case.ex

key-decisions:
  - "Docker's default postgres host-port mapping (5433) and the plan's illustrative verify command (5432) both collided with ports already bound on this machine (a real shared dev Postgres already listens on 5432, and another project's container already holds 5433) — remapped THREADLINE_DB_PORT to 5434 for the direct-Postgres leg while keeping the pgbouncer leg on the plan's stated 6432. Still the same one real path CI runs (bootstrap via direct Postgres, capture+GUC via a real PgBouncer transaction pool); only the local port number differs from CI's fixed 5432, which is a machine-specific constraint, not a downgrade to a direct-Postgres run."
  - "The detector's offense rule required two refinements beyond a literal 'contains repo_opts' check, discovered by running the finished sweep over the real tree: (1) recognize a same-source variable bound from repo_opts(...) and reused across calls (the storage_opts = repo_opts(schema) pattern in timeline_live_test.exs) as equivalent to inlining repo_opts(); (2) recognize a call site lexically inside assert_raise's lambda or an open try/rescue block as a deliberate teeth-proof, not an offense (storage_schema_prefix_contract_test.exs's own D-02 mask-regression guard reads AuditTransaction unprefixed on purpose, to assert it raises). Both are structural, roster-independent, and file-name-independent rules with their own behaviour test cases — not a permitted-file exemption."
  - "No file/list-based escape hatch exists anywhere in the detector. Confirmed by reading the diff: the only sanctioned markers are the literal repo_opts substring, the variable-binding rule, and the assert_raise/try-rescue structural rule — none of which name a specific file or path."

requirements-completed: [GREEN-04]

coverage:
  - id: D1
    description: "pgbouncer_topology_test.exs passes against threadline_test with no schema search parameter, using only StorageSchemaCase.repo_opts() at every owned-schema call site, verified through a real PgBouncer transaction pool"
    requirement: "GREEN-04"
    verification:
      - kind: integration
        ref: "DB_HOST=localhost DB_PORT=6432 THREADLINE_PGBOUNCER_TOPOLOGY=1 mix test test/threadline/pgbouncer_topology_test.exs --include pgbouncer_topology"
        status: pass
    human_judgment: false
  - id: D2
    description: "Threadline.StorageSchemaCallSiteContractTest — static source sweep of test/**/*.exs proving zero unprefixed owned-schema Ecto call sites, with demonstrated teeth (5/14 tests go RED when the detector is neutered) and no escape hatch"
    requirement: "GREEN-04"
    verification:
      - kind: unit
        ref: "mix test test/threadline/storage_schema_call_site_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Full default suite green twice, plus the three anti-laundering caps (zero-skips, storage-schema-prefix, and the new call-site sweep) all green"
    requirement: "GREEN-04"
    verification:
      - kind: unit
        ref: "mix test (two consecutive runs)"
        status: pass
      - kind: unit
        ref: "mix test test/threadline/storage_schema_call_site_contract_test.exs test/threadline/zero_skips_contract_test.exs test/threadline/storage_schema_prefix_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "The pooled topology test result closes GREEN-04 only once CI's verify-pgbouncer-topology job (not this local run) reports green"
    verification:
      - kind: integration
        ref: "test/threadline/ci_attestation_contract_test.exs + .planning/audits/ci-attestation-33344382035.json"
        status: pass
    human_judgment: false
    rationale: "Local green through a manually port-remapped docker-compose stack proves the code path is correct but is not the CI environment itself — CI run confirmation is the only evidence that fully closes this gap, per the plan's own stated success criteria. Discharged by measured CI run 33344382035: 'PgBouncer transaction topology' concluded success - the CI-environment confirmation this entry required."duration: ~75min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 14: PgBouncer Topology Port + Static Call-Site Sweep Summary

**Ported `pgbouncer_topology_test.exs` to `repo_opts()` (proven green through a real local PgBouncer transaction pool) and landed a static, source-scanning contract test that catches unprefixed owned-schema reads in files the default suite never executes — precisely the class of miss that let this file hide.**

## Performance

- **Duration:** ~75 min
- **Started:** ~2026-08-28T15:20:00Z (approx)
- **Completed:** 2026-08-28T16:37:00Z
- **Tasks:** 3
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments

- `test/threadline/pgbouncer_topology_test.exs` ported: `import Threadline.StorageSchemaCase` added, and `repo_opts()` appended as the trailing opts argument to all three `delete_all` calls in `setup` plus the `Repo.all` query in the test body. All raw-SQL statements against the non-owned `threadline_pooler_topology_ctx` fixture table and `set_config` are untouched.
- Proven end-to-end through the actual path CI's `verify-pgbouncer-topology` job runs: `docker compose --profile pgbouncer up`, bootstrap DDL through direct Postgres, then the topology test green through the real PgBouncer transaction pool with `THREADLINE_PGBOUNCER_TOPOLOGY=1`.
- `test/support/storage_schema_case.ex` gained `owned_schema_modules/0`, a public zero-arity function exposing the existing `@cleanup_order` list — the single source of truth shared by `clean_storage_schema!/2` and the new sweep.
- New `test/threadline/storage_schema_call_site_contract_test.exs` (`Threadline.StorageSchemaCallSiteContractTest`, 14 tests): a static regex + balanced-paren-scan detector over `test/**/*.exs` that flags any Ecto call against a Threadline-owned schema module lacking `repo_opts()` (directly or via a traceable variable binding), independent of whether the file's tests ever run locally.
- Ran the finished sweep over the real tree: **208 in-scope call sites found across 143 files, 0 offenses.**
- Demonstrated the detector's teeth live: temporarily forced its offense determination to always return `false`, observed 5 of 14 tests go RED with the expected match-failure diffs, then reverted (`git status --porcelain` clean afterward).
- Full default suite green on two consecutive runs (1412 tests, 0 failures, 1 excluded — the `pgbouncer_topology` tag), plus all three anti-laundering caps (`storage_schema_call_site_contract_test.exs`, `zero_skips_contract_test.exs`, `storage_schema_prefix_contract_test.exs`) green together (25 tests, 0 failures).

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end — pgbouncer_topology_test.exs green through a real PgBouncer transaction pool** - `f47beb50` (fix)
2. **Task 2: Static, run-independent call-site sweep with demonstrated teeth** - `d26de33e` (test)
3. **Task 3: Drive the sweep to zero and re-confirm the caps** - no code changes required (verification-only; the sweep was already 0 offenses after Task 2)

**Plan metadata:** committed alongside this SUMMARY.

## Files Created/Modified

- `test/threadline/pgbouncer_topology_test.exs` — `import Threadline.StorageSchemaCase` added; `repo_opts()` appended to 3 `delete_all` calls and 1 `all` query
- `test/support/storage_schema_case.ex` — new `owned_schema_modules/0` exposing `@cleanup_order`
- `test/threadline/storage_schema_call_site_contract_test.exs` — new file, `Threadline.StorageSchemaCallSiteContractTest`, the detector plus 14 tests (12 inline-fixture behaviour cases + 1 module-attribute test + 1 real-tree sweep)

## Verbatim Local Pooled-Run Command Sequence

```
$ THREADLINE_DB_PORT=5434 docker compose --profile pgbouncer up -d
 Container agent-ab8fb99ead20caa13-postgres-1 Started
 Container agent-ab8fb99ead20caa13-postgres-1 Healthy
 Container agent-ab8fb99ead20caa13-pgbouncer-1 Started

$ until pg_isready -h localhost -p 5434 -U postgres; do sleep 1; done
localhost:5434 - accepting connections

$ until pg_isready -h localhost -p 6432 -U postgres; do sleep 1; done
localhost:6432 - accepting connections

$ MIX_ENV=test DB_HOST=localhost DB_PORT=5434 THREADLINE_TOPOLOGY_BOOTSTRAP=1 mix run priv/ci/topology_bootstrap.exs
...
Threadline: topology bootstrap OK (migrations + threadline_pooler_topology_ctx)

$ DB_HOST=localhost DB_PORT=6432 THREADLINE_PGBOUNCER_TOPOLOGY=1 mix test test/threadline/pgbouncer_topology_test.exs --include pgbouncer_topology
Running ExUnit with seed: 375569, max_cases: 36
Including tags: [:pgbouncer_topology]

.
Finished in 0.05 seconds (0.00s async, 0.05s sync)
1 test, 0 failures
```

**Port note:** the plan's illustrative verify command uses `DB_PORT=5432` (matching CI's fixed direct-Postgres port). On this machine, host port 5432 is already bound by a real, unrelated system Postgres, and docker-compose's own default host-port mapping for the `postgres` service (5433) was also already taken by another project's container. `THREADLINE_DB_PORT=5434` was used for the direct-Postgres leg instead; `THREADLINE_PGBOUNCER_PORT` was left at its default 6432, matching the plan and CI exactly. This is the same real path (bootstrap through direct Postgres in a docker container → capture and GUC through a real `edoburu/pgbouncer` transaction pool in a docker container) with only the local host-port number substituted — not a downgrade to a direct-Postgres run.

## Acceptance Criteria Verification (verbatim greps)

```
$ grep -vE '^\s*#' test/threadline/pgbouncer_topology_test.exs | grep -c 'repo_opts'
4
$ grep -vE '^\s*#' test/threadline/pgbouncer_topology_test.exs | grep -cE 'prefix:|search_path'
0
$ grep -c '@moduletag :pgbouncer_topology' test/threadline/pgbouncer_topology_test.exs
1
$ git diff --exit-code priv/ci/topology_bootstrap.exs config/ lib/ test/support/repo.ex
(no output — no changes)
```

## Detector Non-Vacuity Proof (live rehearsal, Task 2)

Temporarily replaced the detector's `offense:` computation with the literal `offense: false` (unconditional), re-ran the contract test file, and observed:

```
14 tests, 5 failures
```

with each failure being a `match (=) failed` against the expected `offense: true`/`offense: false` shape for exactly the fixture cases designed to prove teeth (the plain unprefixed call, the `@repo`/`repo` receiver variants, and the assert_raise-leak-check). Reverted the file from a pre-edit backup; `mix test test/threadline/storage_schema_call_site_contract_test.exs` returned to `14 tests, 0 failures` afterward, and `git status --porcelain` on the file was clean at that point (no uncommitted diff beyond the intended final state).

## Real-Tree Sweep Result (Task 3)

```
files scanned: 143
total in-scope: 208
total offenses: 0
```

Task 3's action — "drive the sweep to zero across the whole tree" — required no further code changes: Task 1 (this file) plus 198-08 and 198-12's prior work had already ported every real call site, and the sweep confirmed it directly rather than by inference.

## Full Suite Verification (Task 3, verbatim)

Run 1: `1412 tests, 0 failures (1 excluded)`
Run 2: `1412 tests, 0 failures (1 excluded)`

`mix test test/threadline/storage_schema_call_site_contract_test.exs test/threadline/zero_skips_contract_test.exs test/threadline/storage_schema_prefix_contract_test.exs`: `25 tests, 0 failures`

`grep -n 'exclude' test/test_helper.exs`:
```
exclude = if(topology_pooler?, do: [], else: [pgbouncer_topology: true])
ExUnit.configure(exclude: exclude)
```
— exactly the single topology tag, no new exclusion added.

`git diff --stat` after all task commits: no test file deleted, no test function removed (only the 3 files listed above were touched, all additive/porting changes).

`grep -rn '@tag :skip\|@moduletag :skip' test/`: no matches.

`mix verify.format`: exit 0. `mix compile --warnings-as-errors`: exit 0.

**Local green does not establish the CI result.** The only evidence that fully closes GREEN-04's PgBouncer-topology gap is the next `verify-pgbouncer-topology` CI run reporting green — this SUMMARY records a faithful local reproduction of that job's path (direct-Postgres bootstrap → real PgBouncer pool), not a substitute for it.

## Decisions Made

- **Local port remap (5434 instead of the plan's illustrative 5432) for the direct-Postgres leg only.** Host port 5432 was already bound by this machine's own system Postgres (used for this project's normal, non-dockerized `mix test` runs), and docker-compose's own default (5433) was already taken by an unrelated project's container. Remapping via `THREADLINE_DB_PORT=5434` preserves the real docker-compose postgres+pgbouncer topology end-to-end; only a host-port literal differs from CI, which runs in a clean container with no such collisions.
- **Detector rule refinement 1 — variable-bound `repo_opts`.** Running the finished sweep over the real tree surfaced 9 apparent offenses in `timeline_live_test.exs` that were all the same real pattern: `storage_opts = repo_opts(schema)` computed once and reused across several `insert!` calls. Per the plan's Task 3 decision rule ("if a surfaced site genuinely must not carry storage-schema opts... correct the rule... never exempt the file"), the detector's offense rule was extended to recognize a trailing argument that is a same-source variable traceably bound from `repo_opts(...)`, with a stated reason in the source and two dedicated behaviour cases (the positive case and a negative control proving a genuinely-unbound variable is still flagged).
- **Detector rule refinement 2 — assert_raise / try-rescue structural exemption.** The same real-tree run surfaced 2 apparent offenses inside `Threadline.StorageSchemaMaskContractTest` (198-08's own D-02 mask-regression guard), which deliberately reads `AuditTransaction` through `Repo.all/1` with no options to assert it raises `undefined_table` — the teeth-proof for D-02 itself. This is not the defect class the sweep exists to catch; it is that defect demonstrated on purpose as a regression guard. Fixed structurally (lexically inside an open `assert_raise` lambda or `try do/rescue` block), not by naming the file, with three dedicated behaviour cases including one proving the recognition does not leak past its own `end` and silently permit a later real offense.
- **Self-scanning fixture strings built via concatenation, not literals.** Because this contract test's own file is matched by the `test/**/*.exs` glob its "real tree sweep" test scans, several inline fixtures deliberately constructing "offending" call text (and one moduledoc/comment sentence) had to avoid spelling the offending pattern out contiguously in the file's raw source — otherwise the sweep would flag its own test file. Resolved with the same idiom `zero_skips_contract_test.exs` already established (runtime-assembled needles instead of literal ones).
- **Task 3 required no code changes.** The plan anticipated this ("Expect it to be green already if Task 1 plus 198-08 and 198-12 covered everything") — the real-tree sweep run at the end of Task 2's work already returned 0 offenses across 208 in-scope call sites, so Task 3 is a verification-only re-confirmation, not an additional porting pass.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Ran `mix deps.get` in the root project and in `examples/threadline_phoenix`**
- **Found during:** Task 1 setup (root) and Task 3's full-suite run (examples app)
- **Issue:** Neither `deps/` directory was populated in this fresh worktree checkout; the root suite failed to compile and one example-app-dependent test (`stress_router_test.exs:310`, which shells out to `mix run` inside `examples/threadline_phoenix`) failed with "the dependency is not available."
- **Fix:** Ran `mix deps.get` in both directories. All packages were already declared in the respective `mix.lock` files (already-verified dependencies, not new/unverified packages — the Rule 3 package-install exclusion does not apply).
- **Files modified:** none tracked (`deps/` is gitignored in both directories; neither `mix.lock` changed)
- **Verification:** subsequent `mix test` runs compiled and ran cleanly in both directories.
- **Committed in:** N/A (no file changes to commit; environment setup only)

**2. [Rule 1 - Bug] Fixed the detector's offense rule to recognize variable-bound `repo_opts()` and structural teeth-proof contexts**
- **Found during:** Task 2 (running the finished sweep over the real tree for the first time)
- **Issue:** The literal `String.contains?(expr, "repo_opts")` check produced 11 false-positive offenses: 9 real, correct call sites in `timeline_live_test.exs` that pass a variable bound from `repo_opts(...)`, and 2 real, correct call sites in `storage_schema_prefix_contract_test.exs`'s own D-02 mask-regression teeth-proof that are deliberately unprefixed to prove they raise.
- **Fix:** Extended the detector with two structural rules (see "Decisions Made" above), each with a stated reason in the source and dedicated behaviour test cases proving they do not become blanket passes.
- **Files modified:** `test/threadline/storage_schema_call_site_contract_test.exs`
- **Verification:** real-tree sweep dropped from 11 apparent offenses to 0; all 14 detector tests green; the neutering rehearsal confirmed the rules still have teeth against genuine offenses.
- **Committed in:** `d26de33e` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 blocking — environment setup, package-manager install of already-declared deps; 1 bug — detector precision fix required for the sweep to correctly distinguish real defects from legitimate patterns already in the codebase)
**Impact on plan:** No scope creep. Both fixes were necessary: the first to run any test in this worktree, the second because an overly-blunt detector would either miss a real class of correct code (false positives forcing needless "fixes" to already-correct call sites) or — had it been loosened the wrong way — reopen the exact D-05 laundering risk the plan explicitly warns against. Both fixes are structural rules applied uniformly, not per-file exemptions.

## Issues Encountered

None beyond the deviations documented above.

## User Setup Required

None - no external service configuration required. (Docker was used transiently for local verification of Task 1 and torn down afterward via `docker compose --profile pgbouncer down`.)

## Next Phase Readiness

- GREEN-04's PgBouncer-topology gap is closed on this branch, pending the next CI run of `verify-pgbouncer-topology` for full confirmation (this SUMMARY does not claim that confirmation itself).
- The static call-site sweep is now a permanent, run-independent guard: any future Threadline-owned schema call site added anywhere under `test/` — including in a file that never runs locally — is caught at `mix test test/threadline/storage_schema_call_site_contract_test.exs` time, closing the exact blind spot that let `pgbouncer_topology_test.exs` slip through 198-12's file selection.
- No new debt or deferred items introduced by this plan.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*

## Self-Check: PASSED

- FOUND: test/threadline/pgbouncer_topology_test.exs
- FOUND: test/support/storage_schema_case.ex
- FOUND: test/threadline/storage_schema_call_site_contract_test.exs
- FOUND: .planning/phases/198-green-bringup/198-14-SUMMARY.md
- FOUND commits: f47beb50, d26de33e (git log --oneline)
