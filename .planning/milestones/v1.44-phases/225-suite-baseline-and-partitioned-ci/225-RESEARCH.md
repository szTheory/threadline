# Phase 225: Suite Baseline and Partitioned CI - Research

**Researched:** 2026-09-30
**Domain:** ExUnit test partitioning, Elixir/Mix build internals, GitHub Actions CI contract tests, `:telemetry` process-scoping
**Confidence:** HIGH (most claims verified by reading source in this repo or running read-only commands; a few execution-time unknowns are flagged explicitly and delegated to the planner/executor per CONTEXT.md's own instructions)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
D-01..D-20 in `.planning/phases/225-suite-baseline-and-partitioned-ci/225-CONTEXT.md` are locked;
this research does not re-litigate them. Key points, verbatim in spirit:

- D-01: Run partitions concurrently inside the existing `verify-test` job (in-job OS-process
  partitioning), not as separate matrix jobs. Matrix fan-out is the fallback only if in-job
  concurrency can't reach 30%.
- D-02: Partition all three lanes (min, current, latest).
- D-03: `N = 3` default, confirmed by measurement (`mix test --slowest-modules 10`) before locking.
- D-04: Per-partition database name via `config/test.exs:10` →
  `database: "threadline_test#{System.get_env("MIX_TEST_PARTITION")}"`.
- D-05: Connection budget not binding (pool_size 2, ~15-30 connections at N=3-4 vs 100 default).
- D-06: Compile once, then fan out; partition processes start only after `mix compile
  --warnings-as-errors`; planner verifies no unsafe concurrent `_build` writes.
- D-07: Fix every post-test step that depends on the unsuffixed base DB (e.g. `mix
  verify.threadline`).
- D-08: Local default (`mix test`, `mix verify.test`, `mix ci.all`) stays whole/unpartitioned; new
  opt-in `mix verify.test_partitioned`.
- D-09: One committed entrypoint `bin/ci-test-partitions`, style of `bin/verify-deps-audit`;
  `wait "$pid" || fail=1` per PID; per-partition logs; timings to stdout + `$GITHUB_STEP_SUMMARY`;
  step becomes `Run tests` → `mix verify.test_partitioned`.
- D-10: Two mutation controls — runtime (`bin/ci-test-partitions --self-test`, CI step "Prove the
  gate goes red (failing partition)") and shape (extend `mutation_controls` in
  `ci_topology_contract_test.exs`). Leave the alls-green pin test untouched.
- D-11: Flake Detection stays unpartitioned; re-measure and resize its budget/sizing in the same
  change.
- D-12: One commit carries the whole gate change (`bin/ci-test-partitions`, `ci.yml`, `mix.exs`,
  `ci_topology_contract_test.exs`, CONTRIBUTING.md, `flake-detection.yml`,
  `flake_classifier_contract_test.exs`). Job `id:`s unchanged.
- D-13: Authoritative "before" is CI run `36730596489`; comparator is the `Run tests` **step**
  duration from the jobs API.
- D-14: Local detail at 225's starting HEAD, labelled "local, not the CI comparator" — slowest/
  slowest-modules, three timing runs with median async/sync split.
- D-14a: Billed runner-minutes proxy = sum of `ceil(job_seconds/60)` over the three `Build and test
  (…)` jobs, via a phase-local `tools/ci-job-timing.sh`/`.py`.
- D-14b: Doc is `225-BASELINE.md`, checked by a copy of `check-citations.py` (widen phase-range
  exempt regex to cover 224-230).
- D-14c: CI "after" figures need a maintainer push/PR/dispatch grant, named explicitly at that
  moment. "Over cited runs" = at least two post-change runs.
- D-15: SUITE-03 scope narrowed to exactly three files: `auth_test.exs`, `export_auth_plug_test.exs`,
  `theme_auth_plug_test.exs`. The other seven "telemetry/named-process" files stay `async: false` for
  unrelated reasons (DB writes without Sandbox, `Application.put_env`). Update REQUIREMENTS.md and
  ROADMAP.md success criterion 4 wording to match, in a planning-docs commit.
- D-16: Isolate by emitting process (`self()`/`$callers`), not handler id/ref alone. New
  `test/support/telemetry_helpers.ex` with `attach_telemetry!(events)`.
- D-17: Mutation control proving an unrelated-process emission is NOT delivered, and the test's own
  emission is.
- D-18: Proof of no new flake — local `--repeat-until-failure 200` on the three files, plus one cited
  Flake Detection run after the change.
- D-19: Replace the CONTRIBUTING.md "Telemetry tests are `async: false`" bullet (~L181) with the
  narrower async-allowed rule; remove stale header comments from the three files.
- D-20: VERIFICATION.md reports suite wall clock before/after — local median of three `mix test`
  runs, and CI partitioned step duration + runner-minutes proxy with run IDs. SUITE-03 delta reported
  separately from the partitioning delta.

### Claude's Discretion
- The internal shape of `bin/ci-test-partitions` (log directory, summary formatting, the self-test
  seam's variable name). The seam must be documented as test-only.
- Whether the self-test CI step lives in `verify-test` or in an existing cheaper job, provided the
  topology contract pins wherever it lives.
- How D-07 is fixed (this research recommends option 1: point the coverage step at partition 1's DB
  via `MIX_TEST_PARTITION=1`, see Pattern 3).
- The commit split, other than the D-12 atomic gate commit. Suggested order: (1) baseline doc and
  tools (`docs(225)`); (2) SUITE-03 helper and files (`test:`); (3) the partition gate commit
  (`ci:`/`build:`). All three are non-releasable types.
- The wording of CONTRIBUTING and the script's header, in project voice: plain and specific.

### Deferred Ideas (OUT OF SCOPE)
- Making the seven DB-writing or app-env-mutating "telemetry/named-process" files async (D-15):
  `telemetry_test.exs`, `health_test.exs`, `health/trigger_findings_test.exs`,
  `export_queue/task_adapter_test.exs`, `retention/pruner_test.exs`,
  `operator_surface/live/retention_history_live_test.exs`, `operator_surface/stress_router_test.exs`.
- Partitioning Flake Detection (D-11) — revisit only with a design that keeps a whole-suite reshuffle
  on every repeat.
- Matrix fan-out — fallback for D-01 only, not the default.
- Any SQL Sandbox or per-test schema isolation — rejected by design
  (`.planning/research/ARCHITECTURE.md` Part A).
- Change-aware lanes and fastest-to-red ordering — separate seeds.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SUITE-01 | A fresh suite timing baseline is recorded before any suite change: per-module slowest times, sync vs async seconds, and the CI test-step duration with run IDs. | Live-verified CI "before" figures pulled from run `36730596489`'s jobs API this session (see Open Question 2 and Sources); local base/head timing precedent in 224-EVIDENCE.md; `check-citations.py` copy-and-widen mechanics (Pattern/Wave-0 Gaps); `bin/verify-deps-audit`-style script template for the new `tools/ci-job-timing.sh`. |
| SUITE-02 | The CI test step runs the suite in parallel partitions, each with its own database, and the step's wall clock drops by at least 30% against SUITE-01; billed runner-minutes rise ≤10%; Flake Detection budget resized in the same change; required aggregate stays fail-closed with its contract test, CONTRIBUTING, and the topology test changing together. | Pattern 1 (DB provisioning is free via existing `test_helper.exs`), Pattern 2 (`verify.test` alias args pass through), Pattern 3 + Pitfall 2 (D-07's `verify.threadline` fix, concretely diagnosed), Pattern 4 (mutation-control template from `ci_topology_contract_test.exs`), Pitfall 1 (every literal `mix verify.test` pin in `ci_workflow_parity_contract_test.exs` that must be updated), Pitfall 3 (the `CREATE ROLE` collision risk D-04 introduces, not previously documented), Pitfall 4 (advisory locks confirmed safe), Pitfall 5 (`_build` concurrency safety recommendation), flake-detection.yml/`flake_classifier_contract_test.exs` Test 6 exact constants for D-11's re-derivation. |
| SUITE-03 | The telemetry-handler and named-process test files run `async: true` (narrowed by D-15 to three operator-surface files), using unique handler ids/process names, with no new flake over a Flake Detection run. | Code Examples section confirms zero `spawn`/`Task` in the three lib emission sites (validates D-16's process-identity filter premise); current exact `async: false` + per-test unique-handler-id shape of all three test files, read in full; CONTRIBUTING.md's exact current telemetry-rule wording for the D-19 replacement. |

</phase_requirements>

## Summary

Phase 225's three deliverables (SUITE-01/02/03) are fully scoped by `225-CONTEXT.md` (D-01..D-20).
This research fills the execution-level gaps the planner needs to turn those locked decisions into
tasks: (1) the exact literal strings the CI contract tests pin, which change and which don't, (2)
the authoritative CI "before" figures for SUITE-01 pulled live from run `36730596489`'s jobs API,
(3) a genuine, previously-undocumented collision risk (cluster-wide `CREATE ROLE` against
per-VM-restarting `System.unique_integer/1`) that the planner must close alongside D-04, (4) the
current exact shape of the three SUITE-03 files and their lib-side emission paths (no `spawn`/`Task`
anywhere — D-16's process-identity filter is sound), and (5) the precise `mix.exs` alias and
`test/test_helper.exs` mechanics that make D-04's per-partition database scheme work with zero new
provisioning code.

**Primary recommendation:** Build `bin/ci-test-partitions` and the topology-contract extension
first (D-09/D-10), because the D-07 "keep the after-test steps working" fix and the
`ci_workflow_parity_contract_test.exs` literal-string updates are downstream of exactly what that
script's CI step is named and what command it runs. Do the SUITE-01 baseline doc in parallel (it
has no code dependency). Do SUITE-03 last — it's the most isolated change and has the least
interaction with the other two.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Partitioned test execution (SUITE-02) | CI / Build tooling (`bin/`, `.github/workflows/ci.yml`) | Database (per-partition DB provisioning via existing `test_helper.exs`) | Partitioning is an orchestration concern; the DB-per-partition scheme is config, not new runtime code |
| Suite timing baseline (SUITE-01) | CI / Build tooling (phase-local `tools/`) | — | Pure measurement/reporting, no product code |
| Telemetry test isolation (SUITE-03) | Test infrastructure (`test/support/`) | Application/lib (telemetry emission sites, unchanged) | The isolation filter lives entirely in test support code; lib code is proven synchronous and untouched |
| CI contract enforcement (mutation controls) | CI / Build tooling (`test/threadline/*_contract_test.exs`) | — | Pure-Elixir checkers over committed YAML/mix.exs text, no runtime dependency |

## Standard Stack

No new dependencies. This phase uses only what's already in `mix.exs` (`:telemetry` `~> 1.2`,
already present [VERIFIED: mix.exs:97], `stream_data` test-only, unrelated) plus Elixir/Mix's
built-in `--partitions` / `MIX_TEST_PARTITION` mechanism (no library).

**Version verification:** Local committed toolchain is Elixir 1.17.3 / OTP 27 (via `.tool-versions`,
matching the CI `current` lane) `[VERIFIED: elixir -v ran locally, 2026-09-30]`. `--partitions` is
documented as available on `mix test` since it appears in the local `mix help test` output
`[VERIFIED: mix help test ran locally, 2026-09-30]`, and CONTEXT D-03 already establishes it exists
back to the CI `min` lane's Elixir 1.15.8. `--slowest-modules` is annotated "(since v1.17.0)" in the
local help text `[VERIFIED: mix help test]` — confirming CONTEXT D-03's claim that it is unavailable
on the 1.15.8 min lane and must be run on `current`/`latest` or locally (this repo's local toolchain
is 1.17.3, so it works here).

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| In-job OS-process partitioning (chosen, D-01) | Matrix-job fan-out | Repeats 1-3 min of setup per partition per lane; breaks the ≤10% runner-minutes cap; appends to composed check names pinned by the parity contract. Fallback only. |

**Installation:** None — no new deps.

## Package Legitimacy Audit

Not applicable. This phase adds no external packages (npm/PyPI/Hex). `bin/ci-test-partitions` is a
new bash script, not a package.

## Architecture Patterns

### System Architecture Diagram

```
 PR push
   │
   ▼
 verify-test job (matrix: min/current/latest)
   │
   ├─ checkout, setup-beam, cache restore, deps.get      (unchanged)
   ├─ mix compile --warnings-as-errors                    (unchanged; D-06 boundary)
   ├─ mix verify.xref_cycles                              (unchanged)
   │
   ├─ [NEW] "Run tests" step → mix verify.test_partitioned
   │     │
   │     └─ bin/ci-test-partitions N
   │           │
   │           ├─ MIX_TEST_PARTITION=1 mix test --partitions N --no-compile ... &  (pid1)
   │           ├─ MIX_TEST_PARTITION=2 mix test --partitions N --no-compile ... &  (pid2)
   │           ├─ MIX_TEST_PARTITION=3 mix test --partitions N --no-compile ... &  (pid3)
   │           │     each writes to config/test.exs's
   │           │     threadline_test#{MIX_TEST_PARTITION} DB (D-04),
   │           │     auto-created+migrated by test_helper.exs's
   │           │     existing storage_up + Ecto.Migrator.run path
   │           │
   │           ├─ wait "$pid1" || fail=1   (repeated per pid — never bare `wait`)
   │           ├─ per-partition log; on failure print only failing logs
   │           ├─ emit timings to stdout + $GITHUB_STEP_SUMMARY
   │           └─ exit $fail
   │
   ├─ [D-07 FIX] step(s) that need the base "threadline_test" DB
   │     (mix verify.threadline / current-lane-only)
   │     → explicit create+migrate of the unsuffixed DB, or repoint
   │       at a partition DB
   │
   └─ ...rest of job unchanged (example app steps use a different DB)

 [NEW, mutation control] "Prove the gate goes red (failing partition)" step
   → bin/ci-test-partitions --self-test   (test-only seam, MIX_BIN-style)

 Flake Detection workflow (weekly/dispatch) — UNCHANGED topology,
   re-sized budget only (D-11): still runs the WHOLE suite unpartitioned,
   `mix verify.flake` = `test --repeat-until-failure 12`.
```

### Recommended Project Structure
```
bin/
└── ci-test-partitions          # NEW — committed entrypoint, style of bin/verify-deps-audit
.planning/phases/225-suite-baseline-and-partitioned-ci/
├── 225-BASELINE.md             # NEW — cited SUITE-01 doc (D-14b)
└── tools/
    ├── ci-job-timing.sh        # NEW — D-14a proxy-metric script (or .py)
    └── check-citations.py      # COPIED from 222's tools/, widened EXEMPT regex (D-14b)
test/support/
└── telemetry_helpers.ex        # NEW — attach_telemetry!/1 (D-16)
test/threadline/
├── ci_topology_contract_test.exs        # EXTENDED — mutation_controls (D-10)
├── ci_workflow_parity_contract_test.exs # EDITED — every literal "mix verify.test" pin (see Pitfall 1)
└── flake_classifier_contract_test.exs   # EDITED — Test 6 sizing constants re-derived (D-11)
```

### Pattern 1: Per-partition database name resolves the existing provisioning path for free
**What:** `config/test.exs:10` currently hardcodes `database: "threadline_test"`
`[VERIFIED: config/test.exs:5-12, quoted below]`:
```
repo_base = [
  hostname: System.get_env("DB_HOST", "localhost"),
  port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
  username: "postgres",
  password: "postgres",
  database: "threadline_test",
  pool_size: 2
]
```
D-04 changes line 10 to `database: "threadline_test#{System.get_env("MIX_TEST_PARTITION")}"`. With
`MIX_TEST_PARTITION` unset (plain `mix test`, `mix verify.test`, `mix ci.all` — D-08), this resolves
to the literal string `"threadline_test"` (Elixir string interpolation of `nil` via
`System.get_env/1` returning `nil` — `#{nil}` is `""`), preserving the unpartitioned default exactly.
**When to use:** This is the only `config/test.exs` change needed for SUITE-02.
**Why no new provisioning step is needed:** `test/test_helper.exs` already does, unconditionally, on
every `mix test` invocation, for whatever `repo.config()[:database]` currently resolves to
`[VERIFIED: test/test_helper.exs:19-21,23-45,71, quoted]`:
```elixir
repo = Threadline.Test.Repo
config = repo.config()
...
case Ecto.Adapters.Postgres.storage_up(config) do
  :ok -> :ok
  {:error, :already_up} -> :ok
  ...
Ecto.Migrator.run(repo, :up, all: true)
```
So three concurrent `MIX_TEST_PARTITION=1|2|3 mix test --partitions 3` processes each independently
create-and-migrate their own `threadline_test1`/`threadline_test2`/`threadline_test3` database. No
CI provisioning step, no new migration code.

### Pattern 2: `verify.test` is a bare Mix alias — CLI args pass straight through
**What:** `[VERIFIED: mix.exs, "aliases" block, quoted]`:
```elixir
"verify.test": ["test"],
```
There is no `"test": [...]` alias overriding the raw `mix test` task anywhere in `mix.exs`
`[VERIFIED: grepped aliases() block in mix.exs, no "test:" key present]`. This means:
- `mix verify.test --partitions 3` would pass `--partitions 3` straight to the underlying `test`
  task (Mix appends extra CLI args to the last task in an alias's list, and `"test"` is the only
  entry).
- No ecto.create/ecto.migrate wrapping exists at the alias level — `test/test_helper.exs`'s own
  `storage_up`/`Ecto.Migrator.run` (Pattern 1) is the entire provisioning path, and it already reads
  `MIX_TEST_PARTITION` indirectly through the DB name once D-04 lands.
- The new `mix.exs` alias for D-01 should be `"verify.test_partitioned": &verify_test_partitioned/1`
  (a function alias, matching the style of `verify_example/1`, `verify_bench/1`, etc. already in
  this file `[VERIFIED: mix.exs aliases() block]`) that shells out to `bin/ci-test-partitions`, NOT
  a plain `["cmd bin/ci-test-partitions"]` list — CONTEXT D-12 requires the script be the single
  source of truth called by both CI and the alias.

### Pattern 3: `mix threadline.verify_coverage` (the D-07 problem, verified)
**What:** The current-lane step `Verify Threadline trigger coverage` runs `mix verify.threadline` =
`["threadline.verify_coverage"]` `[VERIFIED: mix.exs aliases()]`. Reading the task
`[VERIFIED: lib/mix/tasks/threadline.verify_coverage.ex:57-117]`:
```elixir
def run(argv) do
  ...
  repo = resolve_repo!()
  ensure_repo_started!(repo)
  validate_schema!(repo, schema)
  ...
  coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)
  ...
```
`resolve_repo!/0` reads `Application.get_env(:threadline, :ecto_repos, [])` → `Threadline.Test.Repo`
→ `ensure_repo_started!/1` calls `repo.start_link()`. **It runs NO migration and NO `storage_up`** —
it assumes the repo's configured database (per `config/test.exs`, unsuffixed once
`MIX_TEST_PARTITION` is unset in this later step) already exists and is migrated. Today that's true
because the immediately-preceding `mix verify.test` step created+migrated `threadline_test` as a
side effect of `test_helper.exs`. Once D-04 lands, the `Run tests` step's partition processes create
`threadline_test1`/`2`/`3`, never the unsuffixed `threadline_test` — so `verify.threadline` (and any
other post-test step depending on the base DB) will fail with "relation does not exist" or connect
to an empty/unmigrated database.

**Concrete D-07 fix options** (planner picks one, per CONTEXT "Claude's Discretion"):
1. **Point the step at one partition's DB.** Set `MIX_TEST_PARTITION=1` as an env var on the
   `Verify Threadline trigger coverage` step. Zero new code — the DB already exists and is migrated
   by partition 1's test run. Simplest; recommended.
2. **Explicit create+migrate of the base DB.** A new tiny step (e.g. `mix ecto.create --quiet -r
   Threadline.Test.Repo && mix ecto.migrate -r Threadline.Test.Repo`) with `MIX_TEST_PARTITION` unset,
   run before the coverage step. More CI time (redundant migration), but leaves `verify.threadline`
   running against a DB shaped exactly like the local/unpartitioned default.

Option 1 is lower-risk and adds no wall-clock cost; document the choice and rationale in the plan.

### Pattern 4: mutation-control precedent in `ci_topology_contract_test.exs`
**What:** The Dialyzer topology test (`[VERIFIED: test/threadline/ci_topology_contract_test.exs:119-206]`,
read in full above) is the template D-10 names. Its shape:
1. A `mutation_controls` list of `{label, mutated_yaml_or_text}` tuples, each produced by
   `String.replace/3` on the real committed file text (e.g. swapping a real timing command for a
   bare one, deleting a named step, reordering two named steps).
2. A loop asserting `refute <pure_checker>.(mutated) == [], "#{label} mutation must make the
   contract fail"`.
3. A final loop over "stable marker" env-var-name strings (`THREADLINE_DIALYZER_PLT_CACHE=` etc.)
   asserting each one's removal also goes red.
4. A pure checker function (`dialyzer_topology_errors/3` in that file) that returns `[]` on the real
   files and a non-empty error list on any mutation — no shelling out, no I/O beyond `File.read!`.

**For D-10's partition mutation controls**, the pure checker (`partition_topology_errors/1` or
similar, appended to this same file per D-10's instruction "extend the `mutation_controls` list")
should assert, reading `.github/workflows/ci.yml` and `mix.exs` as text:
- the `Run tests` step in `verify-test` exists and its `run:` is the committed script/alias
  invocation, not inline `&`/`wait` shell
- that step occurs after the `Compile (warnings as errors)` step (textual position, same
  `:binary.match/2` pattern already used at `ci_topology_contract_test.exs:76-95`)
- a step literally named `Prove the gate goes red (failing partition)` exists in `verify-test` (or
  wherever D-10's "Claude's Discretion" places it) and its `run:` invokes `bin/ci-test-partitions
  --self-test`
- mutation controls: rename the self-test step away, replace the script invocation with inline
  `a & b & wait` shell text, move the partition step before compile — each must go red.

Leave `ci_topology_contract_test.exs:105-115` (the "sole required-check decision pins alls-green
immutably" test, D-10's explicit "leave untouched" instruction) alone entirely.

### Anti-Patterns to Avoid
- **Bare `wait` or `a & b & wait`:** returns exit 0 regardless of background failures, or only the
  last job's status. D-09 explicitly calls this the bug class the self-test control exists to catch.
  Use `wait "$pid" || fail=1` per recorded PID.
- **Matrix fan-out as the default (not the fallback):** re-pays setup cost per lane × per partition
  and breaks the composed check-name contract the parity test pins (see Pitfall 1). D-01 is explicit
  this is fallback-only.
- **A second `CREATE ROLE` collision left unaddressed:** see Pitfall 3.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Partitioned test execution | A custom test-file-splitting scheme | Mix's built-in `--partitions N` / `MIX_TEST_PARTITION` (round-robin by module, documented, already present in Elixir 1.15.8+) | Already correct, already documented, zero new code in `lib/` or `test/` |
| Per-partition DB provisioning | A new CI provisioning step / migration script | The existing `test/test_helper.exs` `storage_up` + `Ecto.Migrator.run` path, driven purely by the DB name interpolating `MIX_TEST_PARTITION` (D-04) | Already runs on every `mix test` invocation; making the DB name partition-aware is the only change needed |
| Background-job exit-status aggregation | Any bespoke semaphore/lockfile scheme | `wait "$pid" || fail=1` per recorded PID (POSIX shell, already the project's own precedent pattern for other scripts) | Simple, portable, exactly matches what the mutation control tests for |

**Key insight:** Every piece of this phase that looks like it needs new infrastructure (DB
provisioning, alias-arg passthrough, a self-test seam style) already has a working, tested precedent
in this repo. The actual new code surface is small: `bin/ci-test-partitions`, one `mix.exs` alias,
one `config/test.exs` line, one `test/support/telemetry_helpers.ex`, and edits to existing contract
tests.

## Common Pitfalls

### Pitfall 1: `ci_workflow_parity_contract_test.exs` pins the literal string `"mix verify.test"` in at least 8 places — most will break the moment the step changes
**What goes wrong:** Changing the `Run tests` step's `run:` line from `mix verify.test` to `mix
verify.test_partitioned` without updating this file turns multiple existing, currently-green
contract tests red, for reasons unrelated to the actual change (they're D-15/WR-01-era anti-bypass
guards, not bugs).
**Why it happens:** This file hard-pins the exact command string in several independent checkers,
confirmed by reading the file `[VERIFIED: test/threadline/ci_workflow_parity_contract_test.exs, grep
for "mix verify\.test" returned 8 hits]`:
- Line ~2009, the `@every_lane_steps` module attribute
  `[VERIFIED: test/threadline/ci_workflow_parity_contract_test.exs:2005-2009, quoted]`:
  ```elixir
  @every_lane_steps [
    {"Compile (warnings as errors)", "mix compile --warnings-as-errors"},
    {"Verify no compile-connected xref cycles", "mix verify.xref_cycles"},
    {"Run tests", "mix verify.test"}
  ]
  ```
  This is the D-15/WR-01 "every lane step must actually run and be able to fail" guard
  (`every_lane_step_errors/1`). It must become `{"Run tests", "mix verify.test_partitioned"}`.
- Line ~511-523: a fixture string `run_tests = "      - name: Run tests\n        run: mix
  verify.test\n"`, used to build continue-on-error / step-level bypass mutation controls.
- Line ~554-604: multiple mutation-control tuples building synthetic `ci.yml` text containing
  `"      - name: Run tests\n        run: mix verify.test\n"` (lane-skip, unable-to-fail, quoted-if,
  space-before-colon variants).
- Line ~620-626: shell-override mutation controls against the same literal.
- Line ~5640-5689: `fixture_verify_test/0`, a full synthetic `verify-test` job block containing
  `- name: Run tests\n  run: mix verify.test`, used elsewhere in the file as a baseline fixture.
**How to avoid:** Treat this as its own task in the D-12 atomic gate commit: grep the file for every
literal occurrence of `mix verify.test` (not `mix verify.test_partitioned`, not `verify.test_slice`)
and update each one that represents the *live* `ci.yml` expectation. Some of these (the mutation
*inputs*, e.g. "Run tests skipped on the latest lane") are deliberately mutating away from the
correct value to prove the checker catches it — those stay as literal `mix verify.test` text **only
if** that's what makes the mutation wrong relative to the new correct value; re-read each one in
context rather than blind find-replace, because several are testing that a *different* string (not
the real command) is caught.
**Warning signs:** Any red in `ci_workflow_parity_contract_test.exs` after the D-09 script lands
that isn't the intentional `every_lane_step_errors` update — re-read the specific assertion before
assuming it's a stale pin; a few of the ~8 hits are legitimately mutation-input text that should stay
byte-identical to `"mix verify.test"` because the control is proving something unrelated (e.g. that a
`shell:` override makes the step unable to fail) still catches the class of bug once the base string
is the new command.

### Pitfall 2: `mix threadline.verify_coverage` silently trusts an unmigrated base DB (D-07, detailed above)
**What goes wrong:** Once partitioning lands, the current-lane's `Verify Threadline trigger coverage`
step either errors (relation does not exist) or — worse — succeeds vacuously against a database that
was auto-created by Postgres's `CREATE DATABASE` default but never migrated, silently reporting zero
coverage as if correct.
**Why it happens:** `Threadline.Health.trigger_coverage/1` queries `pg_catalog`/`information_schema`
directly; an empty, unmigrated database has no user tables, so the coverage report would show
`0/N covered` rather than crashing outright in some code paths — a **false negative that looks like
a real regression**, not an obvious CI failure. (`storage_up` only ensures the DB shell exists, not
that migrations ran — that's `test_helper.exs`'s separate `Ecto.Migrator.run` call.)
**How to avoid:** See Pattern 3 above — either point the step at a migrated partition DB via
`MIX_TEST_PARTITION=1`, or add an explicit create+migrate step. Whichever fix is chosen, the plan's
verification step must assert the coverage report shows the expected non-zero covered count (not
just "step exited 0"), so a silently-empty-DB false pass is caught.

### Pitfall 3: `CREATE ROLE` is cluster-wide, and role naming relies on `System.unique_integer/1`, which is NOT globally unique across separate partition OS processes
**What goes wrong:** `test/threadline/health/trigger_findings_non_owner_test.exs` is the only test
in the suite that runs `CREATE ROLE`
`[VERIFIED: grep -rn "CREATE ROLE" test/ returned exactly one hit, test/threadline/health/trigger_findings_non_owner_test.exs:25]`:
```elixir
role = "threadline_findings_probe_#{System.unique_integer([:positive])}"
...
SQL.query!(@repo, "CREATE ROLE #{quoted_role} NOLOGIN", [])
```
`System.unique_integer/1` is scoped per-BEAM-VM, monotonically increasing from each VM's own start
(Erlang `erlang:unique_integer/1`, `[:positive]` option) — it is **not** cluster-wide or
cross-process unique. PostgreSQL roles, unlike databases, ARE cluster-global (shared across every
database on the same Postgres server/cluster)
`[CITED: postgresql.org/docs/current/view-pg-locks.html — search context confirms advisory locks are
per-database, by explicit contrast with roles which pg_roles documents as a cluster-wide catalog; a
role name collision across two separate databases on one cluster is a real `CREATE ROLE` conflict,
not merely a same-name coincidence]`. Three concurrent partition processes, each a freshly-started
BEAM VM, will each start counting `System.unique_integer([:positive])` from near 0-1 again — if this
test runs in more than one partition in the same window (it will, once a partition happens to draw
this module and another partition's own early unique-integer calls coincidentally produce the same
small integer, e.g. both processes' first `[:positive]` call across the whole run happening to land
on the same N), `CREATE ROLE "threadline_findings_probe_N" NOLOGIN` from the second partition fails
with `role "..." already exists` (Postgres `42710`), because roles are visible across every database
in the cluster regardless of which partition's DB issued the DDL.
**Why it happens:** This is genuinely new exposure from D-04's introduction of concurrent OS
processes — it doesn't happen today because there's exactly one `mix test` process.
**How to avoid:** Make the role name collision-proof across concurrent partition processes. Cheapest
fix: append `System.get_env("MIX_TEST_PARTITION", "0")` to the role name alongside the existing
unique integer (mirrors D-04's own DB-naming pattern), e.g.
`"threadline_findings_probe_#{System.get_env("MIX_TEST_PARTITION", "0")}_#{System.unique_integer([:positive])}"`.
This is a one-line test-file edit, small enough to fold into the D-12 atomic commit or its own
tiny preceding commit — flag it explicitly in the plan since CONTEXT.md's Step 4 grep (which this
research performed) is what surfaces it; CONTEXT.md did not enumerate this specific file.
**Warning signs:** An intermittent (not-every-run) `42710 duplicate_object` failure in
`trigger_findings_non_owner_test.exs`, specifically after partitioning lands and specifically only
when this module's partition assignment happens to run concurrently with another partition process
early in its own `System.unique_integer` sequence. Low probability per run (both processes' *first*
calls to this counter would need to coincide, and other code paths in each VM may also consume the
counter first) but nonzero and would present as a flake, not a deterministic failure — exactly the
kind of bug D-11's "reshuffle catches order-dependent flakes" reasoning doesn't cover, because this
is a *cross-process* race, not an intra-suite ordering issue.

### Pitfall 4: advisory locks are safe (verified), so don't over-fix here
**What's true:** PostgreSQL advisory locks are scoped per-database
`[CITED: postgresql.org/docs/current/view-pg-locks.html search summary — "Advisory locks are local to
each database, so the database column is meaningful for an advisory lock"]`. Since D-04 gives each
partition its own database, `pg_advisory_lock`/`pg_try_advisory_lock` calls with the same integer key
in `test/support/async_helpers.ex`'s `with_advisory_lock_held/3`
`[VERIFIED: test/support/async_helpers.ex:60-75, read in full above]` and in
`test/threadline/retention/pruner_test.exs` cannot collide across partitions even when both use the
same literal lock key. **No fix needed for advisory locks** — this closes CONTEXT's explicit
"verify" instruction on this point with a confirmed-safe result, not a pitfall to fix.
**Other cluster-global scan (grep results):** no `CREATE DATABASE`, `pg_terminate_backend`, `ALTER
SYSTEM`, or `LISTEN`/`NOTIFY` literal found anywhere under `test/`
`[VERIFIED: grep -rn "advisory_lock|pg_advisory|CREATE ROLE|CREATE DATABASE|pg_terminate_backend|ALTER
SYSTEM|LISTEN |NOTIFY " test/ --include="*.exs"` returned only the advisory-lock helper comments, the
pruner test's advisory-lock use, and the single `CREATE ROLE` hit above]`. `CREATE ROLE` (Pitfall 3)
is the only cluster-global-object risk in the suite.

### Pitfall 5: `mix test` compiling test files "in parallel" is a per-invocation behavior, not necessarily a shared-`_build`-write hazard — but this needs a local, cheap falsification before locking N
**What we know:** Elixir's `mix test` task "starts the current application, loads up
`test/test_helper.exs` and then requires all files matching the `test/**/*_test.exs` pattern in
parallel" `[CITED: hexdocs.pm/mix/Mix.Tasks.Test.html, per WebSearch summary]` — this parallel
`require` is within a *single* `mix test` invocation and writes no on-disk manifest for `*_test.exs`
files themselves (only `elixirc_paths` sources — `lib/` and, in `:test` env, `test/support/` — are
compiled to persistent `.beam` + manifest files under `_build/test/lib/threadline/`)
`[VERIFIED: mix.exs:85-86, elixirc_paths(:test) = ["lib", "test/support"]]`. D-06 already sequences
the partition fan-out strictly after the job's own `mix compile --warnings-as-errors` step, so
`lib/` and `test/support/` are already up to date on disk before any partition process starts.
**What's unclear:** Whether an *up-to-date* `mix test` run (nothing to compile) still performs any
write against `_build` — e.g. touching `.mix/compile.app_cache`, the `manifest.tmp` staging file
Mix's compile task uses for atomic manifest writes, or `deps.loadpaths`' own check manifest — and
whether three concurrent processes independently reaching that "nothing to compile, still touches a
manifest timestamp" code path is safe (writes are typically atomic rename-based in Mix, which would
make them safe even if all three touch the same path, but this wasn't verified against the exact
Elixir 1.15.8 / 1.17.3 source this run).
**Recommendation (echoing CONTEXT D-06's own delegation):** the planner/executor should run a cheap,
local falsification before locking the partition invocation flags: `mix compile --warnings-as-errors`
once, note `_build/test/lib/threadline/.mix/*` file mtimes
(`find _build/test/lib/threadline/.mix -newer /tmp/marker` after touching `/tmp/marker` right after
compile), then run 3 concurrent `MIX_TEST_PARTITION=i mix test --partitions 3 --no-compile
--no-deps-check` and diff mtimes again. `--no-compile` and `--no-deps-check` are both accepted by
`mix test` `[VERIFIED: mix help test local output — "--no-compile - does not compile, even if files
require compilation" and "--no-deps-check - does not check dependencies"]`, so using both is a safe,
documented way to force each partition process to skip any compile/deps-check code path entirely
rather than relying on "nothing to do" being provably a no-op write. **Recommend using
`--no-compile --no-deps-check` unconditionally on each partition invocation inside
`bin/ci-test-partitions`** — it removes the ambiguity entirely rather than requiring proof the no-op
path never writes.

## Code Examples

### `bin/verify-deps-audit`'s header/seam style (template for `bin/ci-test-partitions`)
```bash
# Source: bin/verify-deps-audit (this repo), lines 1-40, read in full above
#!/usr/bin/env bash
# <header doc: what this proves, modes, --self-test cases, the seam>
#
# Seam: MIX_BIN (default `mix`) lets tests substitute a fake `mix` binary to
# exercise this script's behavior fully offline. Never used by real callers.

set -euo pipefail

die() {
  printf 'verify-deps-audit: %s\n' "$*" >&2
  exit 2
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
MIX_BIN="${MIX_BIN:-mix}"
```
`bin/ci-test-partitions` should follow this exact shape: `set -euo pipefail`, a `SCRIPT_DIR`/`ROOT`
resolution block, a documented test-only seam (D-10 names it explicitly, in "the style of
`bin/verify-deps-audit`'s `MIX_BIN`"), and a `--self-test` mode.

### Partition wait-loop (the exit-code-safe pattern D-09 requires)
```bash
# Not copied from an existing file — this is the documented correct pattern D-09
# specifies, contrasted with the bug classes it names.
pids=()
for i in $(seq 1 "$N"); do
  MIX_TEST_PARTITION="$i" mix test --partitions "$N" --no-compile --no-deps-check \
    > "partition-${i}.log" 2>&1 &
  pids+=("$!")
done

fail=0
for i in "${!pids[@]}"; do
  wait "${pids[$i]}" || fail=1
done

if [ "$fail" -ne 0 ]; then
  for i in $(seq 1 "$N"); do
    # print only logs for partitions that actually failed, per D-09
    :
  done
  exit 1
fi
```

### D-04's `config/test.exs` change
```elixir
# Source: config/test.exs:5-12 (current, read above) — D-04 changes only line 10
repo_base = [
  hostname: System.get_env("DB_HOST", "localhost"),
  port: System.get_env("DB_PORT", "5432") |> String.to_integer(),
  username: "postgres",
  password: "postgres",
  database: "threadline_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool_size: 2
]
```

### D-16's telemetry isolation helper shape (new file, not yet written — spec from CONTEXT + verified lib emission sites)
```elixir
# test/support/telemetry_helpers.ex — NEW, per D-16. Shape implied by CONTEXT's
# exact wording plus the three verified call sites below (all synchronous
# :telemetry.execute, no spawn/Task anywhere in the three lib modules).
defmodule Threadline.Test.TelemetryHelpers do
  @moduledoc """
  Attaches a :telemetry handler that only forwards events emitted by the
  calling test process (directly, or via a tracked $callers chain), so
  async: true telemetry tests are not cross-contaminated by concurrently
  running tests attached to the same VM-global event name.
  """

  def attach_telemetry!(events) do
    test_pid = self()
    ref = make_ref()
    handler_id = {__MODULE__, ref}

    :telemetry.attach_many(
      handler_id,
      events,
      fn event, measurements, metadata, %{test_pid: ^test_pid, ref: ^ref} = config ->
        if self() == config.test_pid or config.test_pid in Process.get(:"$callers", []) do
          send(config.test_pid, {event, config.ref, measurements, metadata})
        end
      end,
      %{test_pid: test_pid, ref: ref}
    )

    ExUnit.Callbacks.on_exit(fn -> :telemetry.detach(handler_id) end)
    ref
  end
end
```
(This is a research-derived sketch matching D-16's described contract — `self() == test_pid` or
`test_pid in Process.get(:"$callers", [])`, forwards `{event, ref, measurements, metadata}`, returns
`ref`, registers `on_exit` detach — not a file read from disk since it doesn't exist yet. The planner
should treat the exact handler-config plumbing as an implementation detail; the *contract* (filter
condition, return value, on_exit registration) is what D-16 locks.)

### Verified: no async emission path in any of the three SUITE-03 lib modules
```
grep -n "spawn\|Task\.\|:telemetry.execute" \
  lib/threadline/operator_surface/auth.ex \
  lib/threadline/operator_surface/theme_auth_plug.ex \
  lib/threadline/operator_surface/export_auth_plug.ex
```
`[VERIFIED: ran locally, 2026-09-30]` — matched only `:telemetry.execute(` (3, 1, 1 occurrences
respectively), zero `spawn` or `Task.` anywhere. All three modules' `:telemetry.execute` calls run
synchronously in the calling process (confirmed by reading `auth.ex` lines 97/161/221 in context
during this session, and by the test files themselves asserting via `assert_receive`/`assert_received`
in the same process that called `Auth.on_mount/4` / `Plug.call/2`). This directly confirms D-16's
premise.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Single unpartitioned `mix verify.test` per lane | In-job OS-process partitioning via `bin/ci-test-partitions` calling `MIX_TEST_PARTITION=N mix test --partitions N` | This phase (225) | `Run tests` step CI time expected to drop ≥30% per D-02/SUITE-02; the step's `run:` command literal changes everywhere it's pinned (Pitfall 1) |
| Telemetry tests forced `async: false` (CONTRIBUTING.md ~L181) | Process-identity-filtered handler (`attach_telemetry!/1`) allows `async: true` for in-process-only emitters | This phase (SUITE-03, D-15/D-16/D-19) | Only 3 files affected per D-15's narrowed scope; 7 other "telemetry/named-process"-labeled files stay serial for unrelated reasons (DB writes without Sandbox, `Application.put_env`) |

**Deprecated/outdated:** The blanket CONTRIBUTING.md rule "Telemetry tests are `async: false`"
(current text, `[VERIFIED: CONTRIBUTING.md ~L181-183, quoted above in the read of that section]`:
"**Telemetry tests are `async: false`.** `:telemetry` handlers are process-global; an `async: true`
module that attaches a handler will receive events emitted by *any* concurrently-running test for
the same event name.") is replaced per D-19 with a narrower rule: async is allowed when the test uses
`attach_telemetry!/1` and emits in-process; the old warning is kept for tests that emit from other
processes.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | An up-to-date `mix test` performs no unsafe concurrent write against shared `_build` manifests even without `--no-compile`/`--no-deps-check` | Pitfall 5 | Low — mitigated by the explicit recommendation to always pass both flags, which sidesteps the question entirely rather than relying on the assumption |
| A2 | The sketched `test/support/telemetry_helpers.ex` handler-config plumbing (using `:telemetry.attach_many` with a match-spec-like anonymous function) is implementable as written in real `:telemetry` v1.2 semantics | Code Examples | Low-medium — `:telemetry`'s handler function signature and config matching may need adjustment (e.g. filtering inside the function body rather than the function head, since `:telemetry` handler configs aren't pattern-matched by the library itself); the planner/executor should treat this as a sketch of the *contract*, not copy-pasteable code |
| A3 | Elixir 1.15.8/1.17.3's compile-manifest writes are atomic (rename-based) even under concurrent invocation, based on general Mix architecture knowledge rather than reading the exact `Mix.Tasks.Compile.Elixir` source for these versions this session | Pitfall 5 | Low — superseded by the `--no-compile --no-deps-check` recommendation, which avoids needing this to be true |

**If this table is empty:** N/A — see above.

## Open Questions (RESOLVED)

1. **Exact partition count N.** RESOLVED: CONTEXT D-03; Plan 225-01 Task 2 measures and locks N.
   - What we know: CONTEXT D-03 sets a starting default of 3 (4 vCPU public-repo runner, 1 core
     reserved for Postgres + OS), to be confirmed by `mix test --slowest-modules 10` before locking.
   - What's unclear: Which specific module(s) are the long pole locally. This session did not run
     `--slowest-modules` (out of scope for research — CONTEXT explicitly assigns this measurement to
     "the planner" as a pre-N-lock step, not to research). The only related data point surfaced this
     session is 224-EVIDENCE.md's aggregate split: base `dd780e68` local `mix test` ran 231.0-243.2s
     total, with sync (serial, `async: false`) time 186.3-208.8s and async (parallel) time 30.8-44.7s
     across two head-vs-base comparison runs `[VERIFIED: .planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md,
     "Suite wall clock (SUITE-06)" table, read in full above]` — meaning the overwhelming majority of
     suite time is in `async: false` modules, which partitioning still parallelizes across processes
     (each partition runs its own mix of sync+async tests), but a single very slow sync-heavy module
     landing entirely in one partition would set that partition's floor per D-03's own reasoning.
   - Recommendation: run `mix test --slowest-modules 10` locally (Elixir 1.17.3 is available) before
     finalizing N; confirm no single module's time exceeds `serial_total / N` at N=3.

2. **CI runner-minutes proxy "after" figures require a maintainer-granted push** (D-14c). RESOLVED: CONTEXT D-14c; Plan 225-04 Task 1 is the grant checkpoint.
   - What we know: the proxy formula (`ceil(job_seconds/60)` summed over the three `Build and test`
     jobs) is now concretely demonstrated against the authoritative "before" run, live-verified this
     session (see Sources below) — latest job 321s→6 min, min job 340s→6 min, current job 476s→8 min,
     total 20 billed-minute-proxy for the "before" state.
   - What's unclear: the "after" figures, by construction, don't exist until the partitioned code is
     pushed and CI runs at least twice (D-14c: "at least two post-change runs of the partitioned
     step").
   - Recommendation: this is explicitly a maintainer handoff per D-14c; the plan must mark the push
     step as a checkpoint, not attempt to simulate it.

3. **`test/support/telemetry_helpers.ex`'s exact `:telemetry.attach`/`attach_many` mechanics.** RESOLVED: CONTEXT D-16; Plan 225-02 Task 1 uses `:telemetry.attach_many/4`.
   - What we know: D-16's functional contract (filter on `self() == test_pid` or `test_pid in
     Process.get(:"$callers", [])`, forward `{event, ref, measurements, metadata}`, return `ref`,
     register `on_exit` detach).
   - What's unclear: whether to use `:telemetry.attach/4` (one event) or `:telemetry.attach_many/4`
     (list) — D-16 says `attach_telemetry!(events)` (plural param name), implying `attach_many`, but
     this wasn't verified against a real call site since the file doesn't exist yet. Use
     `:telemetry.attach_many/4` given the plural signature D-16 specifies.
   - Recommendation: low risk, implementation-detail level; flagged only so the plan's task
     description is precise rather than copying the illustrative sketch verbatim as gospel.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | All of SUITE-01/02/03 | ✓ | 1.17.3 (OTP 27) `[VERIFIED: elixir -v]` | — |
| PostgreSQL (local) | Local baseline measurement, partition DB testing | Not probed this session (CLAUDE.md memory notes local PG is shared and has hit `too_many_connections` before) | — | Planner/executor should check `pg_isready` before running concurrent local partition tests, per CONTEXT D-05/D-08's own caution |
| `gh` CLI | SUITE-01 CI baseline citation, D-14c "after" runs | ✓ | Used this session (`gh api`) successfully against run `36730596489` | — |

**Missing dependencies with no fallback:** None identified.

**Missing dependencies with fallback:** Local Postgres state not probed; executor should `pg_isready`
before local concurrent-partition experiments.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir's built-in), Elixir 1.17.3 local / 1.15.8-1.20.4 across CI lanes |
| Config file | `test/test_helper.exs` + `config/test.exs` (no separate ExUnit config file) |
| Quick run command | `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs` |
| Full suite command | `mix verify.test` (unpartitioned, D-08 default) or `mix verify.test_partitioned` (new, partitioned) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SUITE-01 | Baseline doc cites every figure to a run/command; `check-citations.py` proves no uncited figure | unit (script self-test + doc check) | `python3 .planning/phases/225-suite-baseline-and-partitioned-ci/tools/check-citations.py .planning/phases/225-suite-baseline-and-partitioned-ci/225-BASELINE.md` and `--self-test` | ❌ Wave 0 — doc + copied script don't exist yet |
| SUITE-02 | Partitioned `Run tests` step, ≥30% wall-clock drop, ≤10% runner-minutes rise, fail-closed gate | unit (contract) + integration (real CI run) | `mix test test/threadline/ci_topology_contract_test.exs` (mutation controls) + `bin/ci-test-partitions --self-test` (runtime mutation control) + cited CI runs | ❌ Wave 0 — script, alias, contract extension don't exist yet |
| SUITE-02 (parity) | Existing `ci_workflow_parity_contract_test.exs` literal pins updated, not broken | unit (contract) | `mix test test/threadline/ci_workflow_parity_contract_test.exs` | ✅ file exists, needs edits (Pitfall 1) |
| SUITE-03 | Three files run `async: true`, isolated by emitting process | unit + mutation control | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/theme_auth_plug_test.exs --repeat-until-failure 200` (D-18) | ✅ files exist, need `async: true` + helper wiring |
| SUITE-06 | Suite wall clock reported before/after | manual doc entry, machine-derived | Local: median of 3 `mix test` runs. CI: `tools/ci-job-timing.sh` on before/after run IDs | ❌ Wave 0 — timing script doesn't exist |

### Sampling Rate
- **Per task commit:** targeted `mix test <changed contract file>` (fast, seconds)
- **Per wave merge:** `mix ci.all` (full local gate, ~4-5 min sync per the 224-EVIDENCE.md baseline)
- **Phase gate:** Full suite green (`mix ci.all`) before `/gsd-verify-work`; plus the D-18
  `--repeat-until-failure 200` proof on the three SUITE-03 files, plus at least 2 cited CI runs of the
  partitioned step (D-14c, maintainer-granted push required)

### Wave 0 Gaps
- [ ] `bin/ci-test-partitions` — the committed entrypoint script (D-09)
- [ ] `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.sh` (or `.py`) —
      D-14a proxy-metric script
- [ ] `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/check-citations.py` — copy from
      `.planning/milestones/v1.43-phases/222-seed-006-change-aware-lanes-conditional/tools/`
      (with `fixtures/`), widen the `EXEMPT` phase-range regex from `21[4-9]|22[0-2]` to cover
      224-230 (e.g. `21[4-9]|22[0-9]|230`) — exact three regex lines to update are quoted in Pattern
      discussion below
- [ ] `test/support/telemetry_helpers.ex` — `attach_telemetry!/1` (D-16)
- [ ] Framework install: none — ExUnit, `:telemetry`, and Mix's `--partitions` are all already
      present; no new test-framework dependency

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | Partial — `bin/ci-test-partitions`'s self-test seam and any env-var-driven partition count | Validate `N` is a positive integer before use in `seq`/loop bounds; the test-only injection seam (D-10, `MIX_BIN`-style) must be gated so it cannot be triggered from PR-controlled input (e.g. a PR description or branch name) — only from an explicit CI step or local flag, never from `GITHUB_EVENT`-derived data |
| V1 Architecture (CI-specific) | Yes | `$GITHUB_STEP_SUMMARY` writes (D-09) must never include untrusted PR-controlled content verbatim (e.g. a test name containing shell metacharacters from a malicious fixture) without safe quoting — since this phase's content is all internally generated (partition numbers, timings), risk is low but the plan's verification should confirm no test output is echoed unescaped into the step summary |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Test-only command seam (D-10's self-test) accidentally reachable from a real CI run, masking a genuine partition failure as "expected self-test behavior" | Tampering / Repudiation | Seam must require an explicit `--self-test` flag (never an ambient env var alone that a PR could plausibly set), documented as test-only per D-10's own instruction, and the mutation control itself (the topology contract extension) proves the self-test step exists and runs separately from the real `Run tests` step |
| A `wait`-exit-code bug silently turning a real partition failure into a green gate | Tampering | This is exactly what D-09's `wait "$pid" || fail=1` pattern and D-10's runtime self-test control exist to catch — verified as the correct pattern against bash semantics (bare `wait` always returns 0; `a & b & wait` returns only the last backgrounded job's status) |

## Sources

### Primary (HIGH confidence — read directly in this repo, or a live authoritative API call this session)
- `.planning/phases/225-suite-baseline-and-partitioned-ci/225-CONTEXT.md` — full D-01..D-20 locked decisions
- `mix.exs` (aliases, deps, cli/preferred_envs) — read in full
- `config/test.exs` — read in full
- `test/test_helper.exs` — read in full
- `.github/workflows/ci.yml` (`verify-test` job, lines ~560-780) — read in full
- `test/threadline/ci_topology_contract_test.exs` (lines 1-200+) — read, mutation-control pattern confirmed
- `test/threadline/ci_workflow_parity_contract_test.exs` — grepped for every `verify.test`/`Run tests` occurrence (8 literal `mix verify.test` hits identified and contextualized)
- `lib/mix/tasks/threadline.verify_coverage.ex` — read in full, confirmed no migration/storage_up call
- `test/threadline/health/trigger_findings_non_owner_test.exs` — read, confirmed `CREATE ROLE` + `System.unique_integer` pattern
- `test/support/async_helpers.ex` — read, confirmed advisory-lock-on-dedicated-session pattern
- `lib/threadline/operator_surface/{auth,theme_auth_plug,export_auth_plug}.ex` — grepped, confirmed zero `spawn`/`Task`, only synchronous `:telemetry.execute`
- `test/threadline/operator_surface/{auth_test,export_auth_plug_test,theme_auth_plug_test}.exs` — read headers/setup blocks, confirmed current `async: false` + per-test unique handler-id pattern
- `CONTRIBUTING.md` (~L158-200, "Deterministic tests") — read, confirmed exact current telemetry-rule wording for D-19
- `bin/verify-deps-audit` (header, lines 1-60) — read, confirmed as D-09's named template
- `.github/workflows/flake-detection.yml` and `test/threadline/flake_classifier_contract_test.exs` Test 6 — read, confirmed exact constants (`@cold_first_run_ceiling_s 269`, `@repeat_ceiling_s 214`, `@headroom_percent 10`, current 12 repeats, budget 55min) needing re-derivation per D-11
- `.planning/milestones/v1.43-phases/222-seed-006-change-aware-lanes-conditional/tools/check-citations.py` — read header + EXEMPT regex list, confirmed exact lines needing the 224-230 range widening
- `.planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md` — read "Suite wall clock" table, local base/head timing data
- `gh api repos/szTheory/threadline/actions/runs/36730596489/jobs` (live call, 2026-09-30) — confirmed real `Run tests` step start/end timestamps for all three lanes, and job-level start/end for the runner-minutes proxy
- `mix help test` (local) — confirmed `--partitions`, `--no-compile`, `--no-deps-check`, `--slowest`, `--slowest-modules` flag text
- `elixir -v` (local) — confirmed Elixir 1.17.3 / OTP 27

### Secondary (MEDIUM confidence)
- WebSearch: PostgreSQL advisory-lock database-scoping (postgresql.org/docs/current/view-pg-locks.html) — confirms advisory locks are per-database
- WebSearch: hexdocs.pm/mix/Mix.Tasks.Test.html — confirms `mix test` requires test files in parallel per-invocation; general Mix manifest/parallel-compiler behavior

### Tertiary (LOW confidence)
- The `test/support/telemetry_helpers.ex` code sketch in Code Examples — a contract-level illustration, not verified against real `:telemetry` v1.2 API semantics this session (see Assumption A2)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps, all mechanics (`--partitions`, aliases, DB provisioning) verified by reading source and running local commands
- Architecture: HIGH — every integration point (D-04 config, D-07 verify.threadline, D-09 script template) verified by reading the actual files
- Pitfalls: HIGH for Pitfalls 1-4 (all verified by direct file reads / grep / live docs); MEDIUM for Pitfall 5 (mix compile-manifest write safety under concurrency — flagged as needing a cheap local falsification, with a recommendation that sidesteps the uncertainty)

**Research date:** 2026-09-30
**Valid until:** ~14 days (CI timing figures and cited run IDs are point-in-time; re-verify the SUITE-01 "before" numbers are still the authoritative baseline if this phase's planning is delayed past another main-branch CI run)
