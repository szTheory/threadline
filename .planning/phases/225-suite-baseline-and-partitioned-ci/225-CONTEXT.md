# Phase 225: Suite Baseline and Partitioned CI - Context

**Gathered:** 2026-09-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Three deliverables, each proven by automated checks and cited CI runs:

1. **SUITE-01.** A cited suite-time baseline: per-module slowest times, sync vs async seconds,
   and the CI test-step duration with run IDs. An automated check finds no uncited figure.
2. **SUITE-02.** The `verify-test` job's test step runs the suite in parallel partitions
   (`MIX_TEST_PARTITION`), each with its own database. Over cited runs the step's wall clock is
   at least 30% lower than the SUITE-01 figure, and billed runner-minutes rise by no more than 10%.
   `CI required` stays fail-closed, proven by mutation controls. Flake Detection is resized in
   the same change.
3. **SUITE-03 (narrowed, see D-15).** The three operator-surface telemetry test files run
   `async: true`, isolated by the emitting process, with no new flake over a cited Flake
   Detection run.

Plus the SUITE-06 invariant: VERIFICATION.md reports suite wall clock before and after.

Out of scope:
- Making the seven DB-writing or app-env-mutating "telemetry/named-process" files async (D-15).
- Partitioning Flake Detection (D-11).
- Any SQL Sandbox or per-test schema isolation. Both were rejected by design
  (`.planning/research/ARCHITECTURE.md` Part A).
- Change-aware lanes and fastest-to-red ordering, which are separate seeds.

</domain>

<decisions>
## Implementation Decisions

### Partition topology (SUITE-02)
- **D-01:** **Run partitions concurrently inside the existing job, not as separate matrix jobs.**
  - Inside each `verify-test` lane, one step starts `N` background OS processes
    (`MIX_TEST_PARTITION=i mix test --partitions N`) against the existing `postgres:` service
    container, one logical database per partition.
  - **Why:** a matrix fan-out would repeat 1–3 minutes of per-job setup
    (checkout, setup-beam, cache, compile) for every partition across three lanes. That breaks the
    ≤10% runner-minutes cap. A new top-level matrix axis would also append to the composed check
    names `Build and test (min|current|latest)`, which `ci_workflow_parity_contract_test.exs`
    pins.
  - In-job concurrency leaves the job ids, check names, the `ci-required` `needs:` list and the
    branch-protection roster unchanged.
  - Matrix fan-out is the fallback only if the measured in-job gain is too CPU-starved to reach
    30%.
- **D-02:** **Partition all three lanes (min, current, latest).** `--partitions` exists on the
  min lane's Elixir 1.15.8. In-job concurrency adds no setup cost, so there is no reason to
  exclude any lane.
- **D-03:** **`N = 3` is the default, to be confirmed by measurement before it is locked.**
  - The repo is public (verified with `gh repo view --json visibility`), so `ubuntu-24.04` runners
    have 4 vCPU. `N=3` leaves a core for the Postgres container and the OS.
  - ExUnit partitions by module, so one slow module sets a partition's floor. Before fixing N, the
    planner runs `mix test --slowest-modules 10`. The flag exists on the committed Elixir 1.17.3
    (verified via `mix help test`) but not on the min lane's 1.15.8, so run it locally or on the
    current lane.
  - Check that no single module exceeds `serial_total / N`. If one does, choose N accordingly and
    record why.
- **D-04:** **Per-partition database name.**
  - Change `config/test.exs:10` to `database: "threadline_test#{System.get_env("MIX_TEST_PARTITION")}"`.
    This is the Phoenix generator convention, and it resolves to the plain `threadline_test` when
    the variable is unset.
  - The existing `storage_up` plus `Ecto.Migrator.run` path in `test/test_helper.exs` then creates
    and migrates each partition's DB. No new CI provisioning step is needed.
  - `test/support/async_helpers.ex:63` already derives its raw session's `:database` from
    `repo.config()`.
  - Other `threadline_test` literals stay unchanged: other jobs' service `POSTGRES_DB`, the
    PgBouncer `DATABASE_URL` (`ci.yml:274`, pinned at `ci_workflow_parity_contract_test.exs:979`),
    `flake-detection.yml:70`, `release.yml:620` and `docker-compose.yml`.
- **D-05:** **Connection budget is not binding.** With `pool_size: 2` plus short-lived dedicated
  Postgrex sessions, N=3–4 comes to roughly 15–30 connections against the service container's
  default of 100. No `pool_size` change. The planner confirms this with one measured run.
- **D-06:** **Compile once, then fan out.** Partition processes start only after the job's
  existing `mix compile --warnings-as-errors` step, so that concurrent `mix test` processes never
  compile into the shared `_build`.
  - The planner verifies that an up-to-date `mix test` does no writes to the shared `_build`.
  - If it does, the planner uses whatever flag or order makes the partition processes read-only
    against `_build`, and records it.
- **D-07:** **Keep the steps that run after the tests working.** In the current lane,
  `Verify Threadline trigger coverage` (`mix verify.threadline`, `ci.yml:703-705`) runs after the
  tests against the unsuffixed `threadline_test`. Once the tests run only on suffixed partition
  DBs, that database is no longer migrated by the test run.
  - The planner must make that step, and every later step in the job that relies on the base DB,
    work: for example an explicit create-and-migrate of the base DB, or pointing the step at a
    partition DB.
  - Prove it with a green current-lane run.
- **D-08:** **Local default stays whole and unpartitioned.** Plain `mix test`, `mix verify.test`
  and `mix ci.all` keep running the whole suite on one `threadline_test` DB. This follows CLAUDE.md's
  honest-default-tests rule, and the local Postgres is shared and has hit `too_many_connections`.
  The partitioned path is the opt-in `mix verify.test_partitioned`.

### Fail-closed gate and proof (SUITE-02 criterion 3)
- **D-09:** **One committed entrypoint, `bin/ci-test-partitions`, called by both CI and the new
  `mix verify.test_partitioned` alias.** It follows the style of `bin/verify-deps-audit`:
  `set -euo pipefail`, argument validation and a header doc.
  - It records each background PID and does `wait "$pid" || fail=1` for every PID. Never a bare
    `wait`, which returns 0, and never `a & b & wait`, which returns only the last status.
  - Each partition writes to its own `partition-<i>.log`. On failure the script prints only the
    failing partitions' logs, then exits non-zero.
  - It emits each partition's wall clock, and the whole step's, to stdout and to
    `$GITHUB_STEP_SUMMARY` when that is set. This makes the ≥30% claim citable from the run page.
  - The CI step becomes `Run tests` → `mix verify.test_partitioned`. Keep the step name `Run tests`
    unless a contract pins otherwise.
- **D-10:** **Two mutation controls, both from existing repo precedent.**
  - **Runtime:** `bin/ci-test-partitions --self-test` injects a failing partition through a
    documented test-only command seam, in the style of `bin/verify-deps-audit`'s `MIX_BIN`. It
    must exit non-zero, and must also exit zero when every partition passes. It runs as a CI step
    named `Prove the gate goes red (failing partition)` in `verify-test`, or in a cheaper existing
    job if the planner shows that is equivalent. This is the control that catches the `wait`
    exit-code bug class.
  - **Shape:** extend the `mutation_controls` list in `test/threadline/ci_topology_contract_test.exs`
    (~L130-184, the Dialyzer-topology precedent). It asserts that the partition step exists in
    `verify-test`, runs after compile, calls the committed script or alias rather than inline
    `&`/`wait`, and that the self-test step exists. Every mutation must turn the pure checker red.
  - `ci_topology_contract_test.exs` is "the topology test" (CONTRIBUTING.md:546-569).
  - Leave the alls-green pin test (`ci_topology_contract_test.exs:105-115`) untouched.
- **D-11:** **Flake Detection stays unpartitioned, and its budget is re-derived.**
  - Each `--repeat-until-failure` iteration reshuffles the whole suite, which is what catches
    order-dependent flakes. Partitioning would weaken that.
  - Re-measure the per-iteration time after the SUITE-03 change, and resize the repeat count and
    ceilings in `.github/workflows/flake-detection.yml` (L38-53, L139) and
    `test/threadline/flake_classifier_contract_test.exs` Test 6 (~L749, the `sizing_violations/4`
    pattern and its sizing-mutation control, ~L815).
  - If the measurement shows the current sizing still fits with headroom, update the cited
    measurement and run ID in the comment and the test anyway. "Resized" means re-derived from a
    fresh cited figure.
- **D-12:** **One commit carries the gate change as a whole:**
  - `bin/ci-test-partitions`, `.github/workflows/ci.yml`, and `mix.exs` (the new alias).
  - `test/threadline/ci_topology_contract_test.exs`.
  - CONTRIBUTING.md, in both the `ci-required` roster / CI job table section and "Deterministic
    tests".
  - `.github/workflows/flake-detection.yml` and `flake_classifier_contract_test.exs`.
  - Keep every job `id:` unchanged.

### Baseline (SUITE-01)
- **D-13:** **The authoritative "before" is CI run `36730596489`**, the push-to-main run at
  milestone base `dd780e68`, which Phase 224 already cited.
  - The CI comparator for SUITE-02 is the `Run tests` **step** duration, computed from step
    `started_at`/`completed_at` in the jobs API. Job totals from 224-EVIDENCE.md are context only.
  - Flake Detection run `36359135268` (209 s/191 s) may appear only as a labelled historical
    cross-check. It predates the base.
- **D-14:** **Local detail at 225's starting HEAD** (post-224, before any 225 suite change) is
  labelled "local, not the CI comparator":
  - one `mix test --slowest 50` and one `mix test --slowest-modules 10` for the ranking;
  - three timing runs with the median of the `(Xs async, Ys sync)` split reported;
  - the DB up, and nothing else using the local Postgres.
  - Don't do another worktree measurement at `dd780e68`. 224 showed local swings of ±55 s, so cite
    224-EVIDENCE.md instead.
- **D-14a:** **Billed runner-minutes proxy.** GitHub's timing API returns `total_ms: 0` for public
  repos (re-verified live on run `36730596489`). The proxy metric is the sum of
  `ceil(job_seconds / 60)` over the three `Build and test (…)` jobs, labelled as a proxy.
  - One phase-local script, `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.sh`
    (or `.py`), computes the step duration and the proxy for **both** the before and after runs, so
    the formula can't drift.
  - It stays in the phase directory and is not promoted to `bin/`, matching the 192 and 219
    precedent.
- **D-14b:** **The doc is `225-BASELINE.md` in the phase directory, and citations are checked by
  a copy of `check-citations.py`.**
  - Copy it from `.planning/milestones/v1.43-phases/222-seed-006-change-aware-lanes-conditional/tools/`,
    along with its `fixtures/` and `--self-test`.
  - Widen its phase-number exempt regex to cover 224–230.
  - Run `--self-test` and the check on the doc, and cite both in VERIFICATION.md. No new CI job.
- **D-14c:** The CI "after" figures need a push. Push, PR creation and any workflow dispatch
  require an explicit, named maintainer grant at that moment, per the push-classifier memory.
  Plans must mark that step as a maintainer handoff, not route around it. "Over cited runs" means
  at least two post-change runs of the partitioned step.

### Async telemetry tests (SUITE-03)
- **D-15:** **Scope narrowed to three files** (maintainer decision, 2026-09-30):
  `test/threadline/operator_surface/auth_test.exs`, `export_auth_plug_test.exs` and
  `theme_auth_plug_test.exs`. None uses DataCase or `Application.put_env`.
  - The other seven files that research grouped as "telemetry/named-process" are serial for
    other reasons (writes to the database with no SQL Sandbox, and/or global `Application.put_env`),
    not because of telemetry or named processes. They stay `async: false`, and each is recorded
    with its reason in Deferred.
  - No in-scope file registers a named process.
  - The planner updates the SUITE-03 wording in `.planning/REQUIREMENTS.md` and the Phase 225
    success criterion 4 in `.planning/ROADMAP.md` to match, in a planning-docs commit.
- **D-16:** **Isolate by the emitting process, not by handler id or ref alone.**
  - `:telemetry` handlers are VM-global. A handler with a unique id, or one attached with
    `:telemetry_test.attach_event_handlers/2`, still fires for every emission of the event from any
    process, and forwards it tagged with its own ref. So ref-tagging does **not** stop another test's
    events from matching. `auth_test.exs`'s wildcard-metadata asserts would then pass falsely.
  - Verified: all three files call `Auth.on_mount/4` or `*.call/2` directly in the test process,
    and telemetry handlers run synchronously in the emitting process.
  - Add `test/support/telemetry_helpers.ex` with `attach_telemetry!(events)`. It attaches a handler
    whose config holds `test_pid` and a fresh `ref`. The handler forwards
    `{event, ref, measurements, metadata}` only when `self() == test_pid` or
    `test_pid in Process.get(:"$callers", [])`. It returns `ref` and registers
    `on_exit(fn -> :telemetry.detach(ref) end)`.
  - Assertions pin `^ref`. No new dependency; `:telemetry` is already locked.
  - The helper must be usable by Phase 228's new telemetry tests. Give it a short `@moduledoc`.
- **D-17:** **Mutation control for isolation.** Add a test showing that an event emitted from an
  unrelated process (for example a spawned process that is not a `$callers` child) is **not**
  delivered, and that the test's own emission is. If the filter is removed, that test must go red.
  Record the local red/green in VERIFICATION.md.
- **D-18:** **Proof of no new flake.** Run
  `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/export_auth_plug_test.exs test/threadline/operator_surface/theme_auth_plug_test.exs --repeat-until-failure 200`
  locally, following the CONTRIBUTING convention, plus one cited Flake Detection run after the
  change (a maintainer-granted dispatch, see D-14c).
- **D-19:** **In the same change, replace the "Telemetry tests are `async: false`" bullet in
  CONTRIBUTING.md (~L181)** with the new rule: async is allowed when the test uses
  `attach_telemetry!/1` and emits in-process. Keep the old warning for tests that emit from other
  processes.
  - Remove the now-stale "async: false — …" header comments from the three files.

### Measurement (SUITE-06)
- **D-20:** VERIFICATION.md reports suite wall clock before and after:
  - locally, as the median of three runs of plain `mix test`;
  - in CI, as the partitioned `Run tests` step duration and the runner-minutes proxy, with run IDs,
    computed by the D-14a script.
  - Report the SUITE-03 delta separately from the partitioning delta.

### Claude's Discretion
- The internal shape of `bin/ci-test-partitions` (log directory, summary formatting, the self-test
  seam's variable name). The seam must be documented as test-only.
- Whether the self-test CI step lives in `verify-test` or in an existing cheaper job, provided the
  topology contract pins wherever it lives.
- How D-07 is fixed.
- The commit split, other than the D-12 atomic gate commit. Suggested order:
  1. baseline doc and tools (`docs(225)`);
  2. SUITE-03 helper and files (`test:`);
  3. the partition gate commit (`ci:`/`build:`).
  All three are non-releasable types, so none of them triggers a release.
- The wording of CONTRIBUTING and the script's header, in project voice: plain and specific.

### Folded Todos
- **"Cut CI wall clock by making the test suite less sync-bound"**
  (`.planning/todos/pending/2026-09-28-ci-suite-sync-bound-parallelism.md`, `resolves_phase: 225`).
  - Lever 2 (partition across a matrix): delivered as D-01 to D-12.
  - Lever 3 (slowest report): D-14.
  - Lever 1 (serial-core audit): answered for the telemetry and named-process class by D-15. The
    wider audit of DB and app-env files is deferred.
  - Lever 5 feeds later seeds.
  - Move the todo to done when the phase closes.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/ROADMAP.md` §"Phase 225: Suite Baseline and Partitioned CI". Success criterion 4 is
  narrowed by D-15.
- `.planning/REQUIREMENTS.md`: SUITE-01, SUITE-02, SUITE-03, and SUITE-06 (cross-cutting).
- `.planning/todos/pending/2026-09-28-ci-suite-sync-bound-parallelism.md`, the folded todo.

### Research
- `.planning/research/ARCHITECTURE.md` Part A: option 1 is partitioning, Sandbox and per-test
  schemas are rejected, and it covers the Flake Detection interaction. Its "10 safe files" count is
  corrected by D-15.
- `.planning/research/PITFALLS.md`: Pitfalls 13 and 14 (no-Sandbox DB writes and global app env
  under async).

### Prior-phase evidence and tooling
- `.planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md` and `224-VERIFICATION.md`: the
  `dd780e68` base measurement and run `36730596489`.
- `.planning/milestones/v1.43-phases/222-seed-006-change-aware-lanes-conditional/tools/check-citations.py`
  with its `fixtures/`: the citation checker to copy.
- `.planning/milestones/v1.43-phases/219-deps-only-build-cache/tools/collect-ci-runs.sh` and
  `summarize-ci.py`: precedent for the D-14a timing script.

### CI and contracts
- `.github/workflows/ci.yml`: `verify-test` (~L577-775, including `Run tests` at L700 and
  coverage at L703), and `ci-required` (end of file).
- `.github/workflows/flake-detection.yml` L36-53 and L139: the budget arithmetic.
- `test/threadline/ci_topology_contract_test.exs`: the topology test, with `mutation_controls` at
  ~L130-184.
- `test/threadline/ci_workflow_parity_contract_test.exs`: pinned check names (~L241-242,
  L449-486) and the PgBouncer URL (L979).
- `test/threadline/flake_classifier_contract_test.exs` Test 6 (~L749, ~L815).
- `bin/verify-deps-audit`: the `--self-test` and `MIX_BIN` seam precedent.
- `CONTRIBUTING.md`: "Deterministic tests (no flakes)" (L158, the telemetry rule at L181) and
  "`ci-required` needs: roster" (L546).
- `CLAUDE.md`: named `mix verify.*` entrypoints, stable job ids, honest default tests.

### Test infrastructure
- `config/test.exs` (DB name at L10, `pool_size` at L11) and `test/test_helper.exs`
  (`storage_up` and migrate).
- `test/support/async_helpers.ex`, `test/support/data_case.ex` (no-Sandbox model).
- `deps/telemetry/src/telemetry_test.erl`: reference only. Its ref-tagging alone is insufficient
  (D-16).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test_helper.exs` already runs `storage_up` and migrate on whatever `repo.config()[:database]`
  is, so per-partition DBs need no provisioning code.
- The `bin/verify-deps-audit --self-test` pattern, and its CI step "Prove the gate goes red (…)".
- The `mutation_controls` plus pure-checker pattern in `ci_topology_contract_test.exs`.
- The `sizing_violations/4` pattern in `flake_classifier_contract_test.exs`.
- `check-citations.py`, copied four times in v1.43.

### Established Patterns
- There is no SQL Sandbox. `DataCase` is `async: false` with an FK-order `delete_all`. Don't change
  that model.
- There is one required check, `CI required`, an alls-green aggregate over 13 job ids. Matrix jobs
  already fail the aggregate if any lane fails.
- Phase-local measurement scripts live in the phase's `tools/`, and `bin/` is kept for hardened
  operational wrappers. `bin/ci-test-partitions` is the latter, because CI and the alias both
  call it.
- Local Postgres is shared. Don't run measurements while other suites use it.

### Integration Points
- The `verify-test` step `Run tests` changes from `mix verify.test` to
  `mix verify.test_partitioned`.
- `mix.exs` aliases gain `verify.test_partitioned`. `ci.all` keeps `verify.test`.
- `config/test.exs:10` changes the DB name.
- Current-lane steps that run after the tests and depend on the base DB (D-07).

</code_context>

<specifics>
## Specific Ideas

- `$GITHUB_STEP_SUMMARY` gets per-partition timings, so evidence can be cited from the run page
  without scraping logs.
- The maintainer's standing goals apply: efficient CI that doesn't flake, and zero human
  verification. Hand the maintainer only the push, PR and dispatch grants.

</specifics>

<deferred>
## Deferred Ideas

- **Seven serial files blocked by DB or app-env state (from D-15).** Each would need a
  config-passing refactor and/or DB-write isolation before it could go async. Candidates for a
  future serial-core audit:
  - `test/threadline/telemetry_test.exs`: DataCase.
  - `test/threadline/health_test.exs`: DataCase.
  - `test/threadline/health/trigger_findings_test.exs`: DataCase, and creates and drops schemas.
  - `test/threadline/export_queue/task_adapter_test.exs`: DataCase and `Application.put_env`. Its
    supervisor name is already partly unique.
  - `test/threadline/retention/pruner_test.exs`: DataCase, `Application.put_env` and the singleton
    `Pruner`.
  - `test/threadline/operator_surface/live/retention_history_live_test.exs`: DataCase,
    `Application.put_env` and `Pruner`.
  - `test/threadline/operator_surface/stress_router_test.exs`: extensive `Application.put_env` and
    Endpoint config.
- **Partitioning Flake Detection.** Rejected for this phase (D-11). Revisit only with a design that
  keeps a whole-suite reshuffle on every repeat.
- **Matrix fan-out.** A fallback for D-01 only.

</deferred>

---

*Phase: 225-suite-baseline-and-partitioned-ci*
*Context gathered: 2026-09-30*
