# Phase 247: CI critical path and suite lanes - Research

**Researched:** 2026-10-26
**Domain:** GitHub Actions topology, bash process supervision, ExUnit formatter protocol, Playwright JSON reporting, contract-test maintenance
**Confidence:** HIGH for in-repo shapes and contract literals (read this session); HIGH for ExUnit/OTP/bash behavior (read upstream source or probed locally); MEDIUM for GitHub Actions runtime behavior that can only be proven on a live run

## Summary

All 16 decisions in 247-CONTEXT.md can be built as written, but several of them collide with existing contract tests and helper scripts in ways the CONTEXT does not mention. These collisions are the main planning risk. A naive edit breaks six or more contract files at once, or worse, breaks something silently:

1. `bin/browser-full-projects` finds the projects ci.yml runs by regex-scanning `--project=<name>` in `run:` bodies (`@project_flag ~r/--project[= ]([a-z0-9-]+)/`). A matrix `--project=${{ matrix.project }}` does not match that regex, so the CI set comes back empty and Browser-full would start running `desktop-chromium` and `mobile-chromium` too. Nothing turns red until the ci_coverage_doc / browser_full_projects contracts run. CI-02 must teach this script to resolve `${{ matrix.project }}` from the job's `strategy.matrix.project` list, and it must fail closed.
2. The fan-in receipt job's `needs: verify-example-browser` breaks the 221 D-07 rule `order_needs_errors` ("Only ci-required may carry `needs`"). It also needs entries in `@ci_job_ids`, `@time_to_red_order`, `@ci_check_names`, the CONTRIBUTING roster and the `ci-required` needs roster.
3. `posted_lanes/1` in the name contract hard-codes the matrix axis `lane` (`with ["lane"] <- axes`). It has to be generalized before `verify-example-browser` can post composed names.
4. ExUnit stops formatter processes at the end of the suite: `EM.stop` calls `GenServer.stop(pid, :normal, :infinity)` on every formatter (ExUnit 1.15.8 `event_manager.ex`). A deadline timer inside the formatter therefore dies when `suite_finished` fires, so D-13's "VM-not-exiting" case needs a separate unlinked watchdog process.
5. The fake `mix` used by `--self-test` rejects every unknown flag (`-*) … exit 3`), and `ci_topology_contract_test` pins two exact script literals: the `"$MIX_BIN" test --no-compile --no-deps-check --timeout="$PARTITION_TEST_TIMEOUT_MS" "${files[@]}"` line and the per-PID wait loop. The formatter flags and the watchdog have to keep both literals intact (append after `"${files[@]}"`, and poll before the unchanged wait loop).
6. `operator-ci-evidence.test.ts` is **never run anywhere**. `package.json` `test:unit` runs only `operator-surface-paths.test.ts`, and no ExUnit test calls it. D-06's "invoked the way operator-ci-evidence.test.ts is" therefore has no existing wiring to copy. Both TS tests must be wired into something.

A few useful findings go beyond the CONTEXT:

- ExUnit (1.15.8 through 1.20.4) already traps SIGQUIT. It sends `{:sigquit, [test | test_module]}` to every formatter and prints "Aborting test suite, the following have not completed:" with `file:line`. That gives D-14's diagnose step a free, version-stable in-VM dump: send QUIT to the BEAM before TERM.
- The default OTP `sigterm` handler is `init:stop()` (a graceful stop that can itself hang), which explains why PR #89 ignored the cancel grace.
- The run endpoint's `updated_at` moves when a run is re-run. Wall time must be read from `/actions/runs/{id}/attempts/1`.

**Primary recommendation:** Treat every contract that pins a moved literal as part of the same commit as the change. Sequence the work as: (A) land 244/245 and 246, (B) land the `ci:` PR with CI-01, the monitor formatter, the watchdog and the CI-03 scope, (C) observe 3 or more runs, (D) land the CI-02 split together with the browser-full-projects resolver and the contract generalizations, (E) measure with a committed read-only script that reads attempt-1 timestamps.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Slow-spec summary (CI-01) | CI job step (Node script over Playwright JSON) | Artifact storage | Data already exists in `PLAYWRIGHT_JSON_OUTPUT_FILE`; a post-step summarizes it |
| Per-project browser legs (CI-02) | GitHub Actions matrix on `verify-example-browser` | `run-e2e.sh` / `mix verify.example_browser` | Each leg owns its own Postgres service and `phx.server` |
| Journey receipt reconciliation | Fan-in job (`verify-example-browser-receipt`) | `operator-ci-evidence.ts` | Needs every leg's executed and discovered files at once |
| Lane scoping of repo contracts (CI-03) | `bin/ci-test-partitions` enumeration | `@moduletag :repo_contract` in test files + a contract test | File-level filter before assignment; ExUnit config untouched |
| Partition timings / weights | CI-only ExUnit formatter (in-VM) | `bin/ci-test-partitions --ingest-weights` (offline) | Only the VM sees module start/finish; ingest is a deterministic local transform |
| Hang detection (CI-04) | In-VM monitor (names + stacks) | Bash watchdog (budget, process-group kill, backstop dump) | The VM can name the test; only bash can kill a VM that stopped scheduling |
| Measurement (D-08/D-12) | Read-only `gh api` script | VERIFICATION.md | Reads attempt-1 run and job timestamps |

## User Constraints (from CONTEXT.md)

<user_constraints>
### Locked Decisions

**Sequencing and landing (cross-cutting)**
- **D-01: Landing v1.47 to main is in scope of this phase.** Every gate is measured on main and none of v1.47 (160 commits on `milestone/v1.47`) is on main. Land under the standing merge grant (merge own green quality PRs, report after). — **Reversibility:** costly — merged PRs on main are reverted, not unmerged.
- **D-02: Order.**
  1. **Land A** — 244/245/246 work, with the 246 critic removal as its own non-releasable `chore:` squash PR (246 D-12); the `archive/ui-critic-loop` tag push stays a maintainer hand-off (246 D-13) and does not block 247. Then a `ci:` PR carrying CI-01, the CI partition monitor formatter (D-13), the CI-04 watchdog, and the CI-03 lane scope (D-09/D-10).
  2. **Observe** ≥ 3 main runs: read browser per-project / per-file totals (CI-01) and collect per-file test timing artifacts (D-12).
  3. **Land B** — CI-02 matrix split + receipt fan-in, weights refreshed from CI timings, `stress_router_test.exs` split if it still exceeds an even share.
  4. **Measure** — 5 main runs for the median, 3 runs for the partition ratio (D-08).
  CI-01 MUST be on main and read before the CI-02 split is designed in detail (roadmap SC1).
- **D-03: Commit types.** CI/test infrastructure changes are non-releasable (`ci:`/`chore:`/`test:`); nothing in this phase changes the public API or the Hex package.

**CI-01: slow browser specs**
- **D-04: Source = the JSON report CI already writes** (`PLAYWRIGHT_JSON_OUTPUT_FILE`, `results[].duration` per attempt), summarized by a committed `examples/threadline_phoenix/e2e/support/slow-specs.ts` run with the already-installed `tsx`, in the style of `operator-ci-evidence.ts`. No new dependency, no reporter config change.
  - Rejected: custom Playwright reporter (changes the `[["github"], ["json"]]` reporter config pinned by `browser_journey_evidence_contract_test.exs`); built-in `reportSlowTests` (per file, annotation-only, not contract-testable); `--reporter` CLI flag (overrides config reporters and silently drops the JSON the receipt parses).
  - Footguns: sum all attempts' durations and flag retried tests; exclude skipped (duration 0); cap input size like `MAX_REPORT_BYTES`.
- **D-05: Output = both** a Markdown table in `$GITHUB_STEP_SUMMARY` (top 20: project, file, title, duration, attempts; plus per-file and per-project totals — the totals are what inform the split) **and** a JSON artifact `browser-timings-<project|all>-<run_id>` (14-day retention). Runs on every event under `if: always()` + file-exists guard; never fails the job (missing/malformed report → warning).
- **D-06: Pinning.** Extend `browser_journey_evidence_contract_test.exs` (step exists in `verify-example-browser`, `always()`-guarded, writes the step summary, artifact names the timings file) and add a `slow-specs.test.ts` unit test (ranking, cap 20, retry/skip handling) invoked the way `operator-ci-evidence.test.ts` is.

**CI-02: browser split**
- **D-07: Matrix over `project` on the SAME job id `verify-example-browser`**, `fail-fast: false`, static name `Example app browser E2E` → checks "Example app browser E2E (desktop-chromium)" / "(mobile-chromium)". Copies the `verify-test` / `@verify_test_check_names` precedent (221 D-04). Job id stays immutable (CLAUDE.md). — **Reversibility:** costly — check names, contracts and docs move together.
  - Update `@ci_check_names`, add `@verify_example_browser_check_names`, add "Example app browser E2E (2 projects)" to `@retired_check_names`, CONTRIBUTING "## CI Coverage", and the literal `--project=… --project=…` assertions in `browser_journey_evidence_contract_test.exs`.
  - New contract assertion: matrix project list == inventory `votingProjects`, so a dropped project fails the suite.
  - Check `browser-full.yml` / `bin/browser-full-projects` "projects ci.yml does not run" parity (`ci_workflow_parity_contract_test.exs` ~1115).
  - Rejected: separate jobs (two new immutable ids, duplicated YAML); `--shard` as the primary shape (balances by file count without `fullyParallel`, mixes projects, breaks "one job per project") — kept only as the miss fallback (D-08).
- **D-07a: Receipt fan-in job** (e.g. id `verify-example-browser-receipt`, name "Browser journey receipt"), `needs: verify-example-browser`, added to `ci-required.needs` (no `allowed-skips`). Each leg uploads `operator-ci-executed-<project>-<run_id>.json` and its `--list` output; the fan-in downloads with `pattern:`/`merge-multiple`; `operator-ci-evidence.ts` accepts N executed + N discovered files and concatenates (`uniqueIndex` already rejects duplicates; tests carry `projectName`). Fails closed: a missing leg fails "not executed"; a failed leg skips the fan-in, which alls-green scores as failure. Keep the receipt's `jobId: "verify-example-browser"` (job id unchanged).
  - Rejected: per-leg subset reconciliation (loses "across merged results"); blob reporter + `merge-reports` (replaces the JSON the receipt parses, needs npm ci + config at merge time).
  - Footguns: the fan-in sits serially on the critical path — keep it ~20 s (sparse checkout, cached npm or Node `--experimental-strip-types` since the script imports only `node:fs`, no Playwright run); artifact names include the matrix leg (upload-artifact v4+ 409s on collisions); diagnostics artifact `example-browser-e2e-diagnostics` gets `${{ matrix.project }}`.
- **D-07b: `workers: 1` stays.** Shared seeded DB + one `phx.server` on 4002; per-project jobs already give each leg its own Postgres and server. Raising workers is a separate future change.
- **D-07c: Timeouts per leg** re-derived from CI-01 data in the D-16 budget style; provisional step 9 min < job 12 min (step < job so the diagnostics upload survives); fan-in 5 min. Note in the config comment that `maxFailures: 5` now applies per leg. Setup duplication (~75 s/leg, cache hits) is runner-minutes only, not critical path; the example build cache save may be guarded to one leg.
- **D-08: Measurement protocol and miss policy.** The first 5 consecutive `ci.yml` runs on main at/after the split head, attempt 1, conclusion success; event `push` or `workflow_dispatch` on main (record the event per run). Wall = `run_started_at` → `updated_at` via `gh api …/actions/runs/<id>`. Record the 5 run IDs, wall times, median, per-leg and fan-in durations, and the new slowest job in VERIFICATION, and rewrite SEED-006 `reopen_when`, replacing the stale "Browser E2E bound (about 550 s, run 36455432448)" with the measured median and critical-path job. Use a committed read-only measurement script (alongside `bin/observe-main-ci` or the 222 `tools/` precedent). **If it misses:** read CI-01 per-project totals; shard the dominant project 2-way (matrix `include` with `project`+`shard`; only the receipt glob changes); re-measure. Never relax 9 min silently — a remaining miss is a recorded gap and a scope decision for the maintainer.

**CI-03: repo-file contract tests on the current lane only + partition balance**
- **D-09: Classify with `@moduletag :repo_contract`**, meaning "outcome does not depend on the Elixir/OTP/PostgreSQL toolchain". Module tag only, never per-test `@tag` (exclusion is per file). The file name is NOT the classifier: `public_surface_contract_test` (`Code.fetch_docs`), `release_artifact_contract_test` (`mix hex.build`), `dialyzer_slice_contract_test` depend on the toolchain; `repo_hygiene_guard_test`, `verify_action_pins_test`, `date_release_changelog_test` are repo-only despite their names. ~51 candidate files (~89 s raw / ~58 s effective) from a static scan — each needs review before tagging; read `clean_checkout` / `planning_independence` first (they may assert this-toolchain behaviour → stay untagged).
  - Enforced by a new contract test (itself tagged `:repo_contract`), two directions: (a) **no dodging** — a tagged file fails if it contains denylisted markers (`"mix"`/`Mix.Task`, `Repo.`, `DataCase`/`ConnCase`, `Code.fetch_docs`/`ensure_*`/`eval`, `Phoenix.*Test`, `Threadline.<Module>.fun(` calls, `elixir`/`erl` invocations); (b) **no silent unclassified** — every `*_contract_test.exs` carries the tag or sits in an exemption map in the test with a one-line reason. Failure direction is safe: untagged runs everywhere.
  - Rejected: path convention (moving ~50 files breaks `partition_colocate.txt`, weights, docs, blame); manifest file (drifts, second source of truth).
- **D-10: Exclude by file filtering in `bin/ci-test-partitions`**, driven by `THREADLINE_TEST_SCOPE: toolchain` on the min and latest matrix rows only (absent on current). Tagged files are dropped from enumeration (same grep style as async detection); the exactly-once check compares against the filtered set; the step summary prints "N repo-contract files run on the current lane only". Local `mix test` and the current lane run everything; `test_helper.exs` exclude list does NOT change (`zero_skips_contract_test` allows exactly two gates: `pgbouncer_topology`, `live_dialyzer`) — add only a pointer comment. Docs: one sentence under CONTRIBUTING "## CI Coverage" + ci.yml comment; a contract test asserts the sentence, that the env var is on min/latest only, and that the script's filter matches the tag literal. Add `--self-test` case: tagged file absent from every partition under scope=toolchain, present exactly once under full scope, summary names the count.
  - Rejected: env-driven ExUnit exclude in `test_helper.exs` (weakens the anti-laundering guard; excluded files still load and the balancer carries dead weight).
  - Follow-on in scope: once Playwright-dependent tests (`playwright_fail_fast`, `browser_full_projects`, `e2e_preflight`) are tagged, drop the Playwright CLI install steps from min/latest, updating the ci.yml comment and any topology contract that pins them.
- **D-11: Weights from real CI timings.** A CI-only formatter (D-13) records per-file wall time (`module_started`→`module_finished`), summed `test.time`, partition boot time before the first module, and partition wall; writes a TSV per partition uploaded as an artifact on all lanes (SHA-pinned `upload-artifact`, satisfying `ci_action_pin_contract_test`). New mode `bin/ci-test-partitions --ingest-weights <dir>`: per-file median over the last 3 current-lane runs → rewrites `test/partition_weights.txt` in the unchanged `<ms> <file>` format (self-test (p) and the inventory contract keep working); prints files whose weight moved > 2×. Fit the async factor once by least squares from partition totals vs sync/async sums and record it as a constant with evidence, replacing the guessed 1/4. One weights file from current-lane timings; per-lane weights only if min/latest still miss 1.15 after refresh. Keep `--write-weights` as the offline fallback. Keep N=4 (4-vCPU runners; 225 D-03b). If a single file exceeds the even share (likely `stress_router_test.exs`, 47.5 s local, much more on CI), split it by module into two files (two `setup_all`, ~9 `defmodule`s). The weights-inventory contract must accept full-file weights while min/latest run a subset.
  - Rejected: a one-off serial refresh job in CI (> 10 min, still traced, goes stale); lowering N per lane.
- **D-12: Ratio measurement.** The script prints `max/min ratio` in its report table and emits `::warning::` above 1.15 — NOT a hard gate (~10% runner noise would flake). VERIFICATION records the ratio for 3 consecutive runs on each lane from the step summary. Parse the script's own table, never ExUnit summary lines (1.19 format change). Run `mix verify.flake` or 3 CI runs after reassignment before claiming the ratio (new partition mixes can expose order/shared-state coupling).

**CI-04: hung test fails fast and names itself**
- **D-13: One CI-only ExUnit formatter module in `test/support`** (e.g. `Threadline.Test.PartitionMonitor`, ~100 lines, no dependency) serves both D-11 timings and hang detection. Attached only by `bin/ci-test-partitions` via `--formatter ExUnit.CLIFormatter --formatter <module>`; local `mix test` output unchanged. It tracks `module_started`/`test_started`/`test_finished`/`module_finished`/`suite_finished` → in-flight tests and the current `setup_all` module. When `THREADLINE_TEST_DEADLINE_MS` (set by the script to budget − 30 s) passes, it prints a delimited `HANG: in-flight: <file:line test>` block, then `Process.info(pid, [:current_stacktrace, :registered_name, :status, :message_queue_len])` for processes (test/module processes first, then non-idle; cap ~200), then `System.halt(1)`. Go "panic: test timed out" model: names the test with its stack, and also covers `setup_all` (module started, no test yet) and VM-not-exiting (`suite_finished` seen). Verify formatter event tuple shapes on Elixir 1.15 (min lane).
  - Rejected: `--trace` (serializes async, ~4× slower, no stack); SIGQUIT / `erl_crash.dump` (huge, unnamed); per-test-only timeouts (ExUnit already has them; they missed this).
- **D-14: Bash watchdog in `run_partitions`**: per-partition wall budget `CI_TEST_PARTITIONS_BUDGET_S` default **480 s** (slowest measured partition 201 s → ~2.4× headroom; > 180 s per-test timeout + a full normal partition, so ExUnit's own timeout fires first for slow test bodies). Portable bash (`sleep 5` loop + `kill -0` + age; stock macOS has no `timeout`/`gtimeout`/`setsid`/`ps --ppid`): each partition in its own process group (`set -m`), on fire → diagnose → SIGTERM → 10 s → SIGKILL `-- -PGID`; write `status=124 reason=budget`; keep the report table. Never block on `wait "$pid"` before polling. Backstop if no in-VM dump arrives within 30 s: print the partition's last 40 log lines, its `ps -o pid,ppid,etime,args -A` subtree (awk-filtered), and `pg_stat_activity` (wait_event, query, age) for that partition's DB. Stack dump goes to the partition log/stdout only; the step summary gets the row + in-flight test names (~1 KB; no raw log text, per the script's contract).
  - Rejected: `timeout --signal` (not portable, signals only the direct child); relying on job/step timeouts (the path that failed in PR #89).
- **D-15: Timeout layering.** Partition budget 480 s < "Run tests" step `timeout-minutes: 12` < job 20 (unchanged), commented in the browser-job pattern (ci.yml ~983–989). Add an `if: failure()` upload of `tmp/ci-test-partitions/` with the already-pinned `upload-artifact` (a killed job loses its whole log, as PR #89 shows). Keep `mix verify.test_partitioned` as the canonical CI step (named-entrypoint convention); the script's own watchdog makes the mix signal chain irrelevant.
- **D-16: Proof.** (a) Two `--self-test` cases with the fake mix: `hang` (sleeps forever; budget 3 s via env seam; asserts killed within budget, non-zero exit, table shows 124, log says "exceeded budget", no leftover process via `pgrep` sentinel) and `hang_ignore_term` (traps TERM; asserts SIGKILL escalation). (b) A **normal default-suite test** (no new exclude tag) that builds a sandbox project at runtime (precedent: self-test sandboxes, repo-hygiene runtime-built fixtures) and runs `mix test` with `THREADLINE_TEST_DEADLINE_MS=2000` against a test-body hang and a `setup_all` hang, asserting the output names `<file>:<line>` and contains a stack frame. Fixtures are NOT committed as `*_test.exs` under `test/` (plain `mix test` would discover them). (c) A throwaway-branch synthetic reproduction of the PR #89 shape on the min lane (`Process.sleep(:infinity)` in a `setup_all`) showing red well under the job timeout with the module named; VERIFICATION records honestly that the original attempt-1 log is unrecoverable.

### Claude's Discretion
- Exact module/script/job names (`PartitionMonitor`, `verify-example-browser-receipt`, artifact names) as long as job ids stay immutable once landed.
- Whether the fan-in uses cached `npm ci` or Node type-stripping.
- Final per-leg timeouts and budgets once CI-01/D-11 data exists (D-16 budget style, documented in comments).
- Whether the measurement script lives in `bin/` or under a phase `tools/` dir.
- Optional small `with_timeout/2` helper for `setup_all` subprocess calls if the D-16(c) reproduction points at one.

### Deferred Ideas (OUT OF SCOPE)
- Raising Playwright `workers` above 1 (needs per-worker DB/tenant isolation + flake run).
- Rebalancing current-only steps across lanes.
- Path-aware / change-aware lanes — SEED-006 stays closed unless its measured trigger fires.
- `Mix.shell().cmd` not forwarding cancel signals to child scripts — a possible future requirement line (mitigated here by the script's own watchdog).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CI-01 | Every main CI run publishes the slowest browser specs (at least top 20 with durations) in the job summary or an artifact. | §CI-01 below: Playwright 1.60.0 JSONReport shape (verified from installed `testReporter.d.ts`), Node-builtin-only script, wiring gap for TS unit tests, contract literals to extend |
| CI-02 | Browser E2E runs as one parallel job per Playwright project; receipt reconciles every journey; median wall ≤ 9 min over 5 main runs. | §CI-02: matrix naming (verified on run 40139774739), download-artifact v8.0.2 pin (node24, verified), the `bin/browser-full-projects` resolver gap, contract inventory, attempt-1 measurement endpoint |
| CI-03 | Repo-file contract tests run only on the current lane; weights refreshed from CI timings; ratio ≤ 1.15 over 3 runs. | §CI-03: 113-file classification table, denylist false positives found by scan, filter insertion point, ingest/least-squares design, stress_router split shape |
| CI-04 | A hung test fails within its partition timeout and names the stuck test. | §CI-04: ExUnit 1.15.8/1.17.3/1.20.4 event shapes, EM.stop kills formatters, built-in SIGQUIT dump, OTP sigterm → init:stop, bash 3.2/5.2 probe results, literal-preserving watchdog shape |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Named entrypoints:** CI cites `mix verify.*` / `mix ci.*` aliases. Keep `run: mix verify.test_partitioned` as the "Run tests" step. Do not inline the script.
- **Honest default tests:** never silently exclude suites from `mix test` without updating `test/test_helper.exs` and docs together. D-10 deliberately leaves `test_helper.exs` excludes unchanged and adds only a pointer comment.
- **Stable CI job IDs:** `verify-example-browser` stays. A new fan-in id becomes immutable once landed. `name:` may evolve.
- **Path filters + main:** not in play. ci.yml has no path filters.
- **Doc contract tests:** CONTRIBUTING "## CI Coverage", "### `ci-required` needs: roster" and "## Branch protection (maintainers)" are contract-pinned. Edit them in the same commit as ci.yml.
- **Zero human verification by default:** every proof below is automated. The maintainer hand-offs are push/PR/merge (classifier-gated), the `archive/ui-critic-loop` tag push, and any spend or scope decision on a CI-02 miss.
- **Commit hygiene (maintainer memory, applies to executors):** never `git add .planning/` wholesale. Planning prose must not spell out home-directory paths or the username (repo-hygiene guard scans tracked `.planning/`). Never run `npx @opengsd/gsd-core`.

## Standard Stack

No new packages. Everything uses what is installed and pinned.

### Core
| Component | Version | Purpose | Evidence |
|-----------|---------|---------|----------|
| `@playwright/test` | 1.60.0 (lock) | JSON report source for CI-01 | [VERIFIED: e2e/package-lock.json `"node_modules/@playwright/test": { "version": "1.60.0"`] |
| `tsx` | 4.x (installed devDependency) | Run `slow-specs.ts` and the TS unit tests | [VERIFIED: e2e/package.json `"tsx": "^4.19.2"`; `tsx --test support/operator-ci-evidence.test.ts` → 10 pass, run this session] |
| Node | 22.14.0 | `--experimental-strip-types` for the fan-in (no npm ci) | [VERIFIED: `.tool-versions` `nodejs 22.14.0`; `node --experimental-strip-types support/operator-ci-evidence.ts` printed the usage line, run this session] |
| `node:util` `parseArgs` | Node built-in | Multi-file `--discovered`/`--executed` flags for the receipt | [ASSUMED: built-in since Node 18.3; not probed] |
| ExUnit formatter protocol | Elixir 1.15.8 / 1.17.3 / 1.20.4 | PartitionMonitor events | [VERIFIED: upstream source read, see §CI-04] |
| `actions/download-artifact` | v8.0.2 @ `9000827ccba6bdab643e8b6fd33ac0654aef8333`, `runs.using: 'node24'` | Fan-in download with `pattern` + `merge-multiple` | [VERIFIED: `gh api repos/actions/download-artifact/commits/v8.0.2`, action.yml at that SHA] |
| `actions/upload-artifact` | v7.0.2 @ `cf430e030ddbb5b0abf93d22962f4752f3646cd9` (already pinned 4×) | Timings, executed/discovered, partition TSVs, failure logs | [VERIFIED: ci.yml grep] |

### Already-pinned actions to reuse verbatim (copy these exact lines)
```
actions/checkout@fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09 # v5.1.0
actions/setup-node@a0853c24544627f65ddf259abe73b1d18a591444 # v5.0.0
actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7.0.2
actions/cache@caa296126883cff596d87d8935842f9db880ef25 # v5.1.0
erlef/setup-beam@54075bcc5e249e4758d363f27d099f55d843f124 # v1.24.1
re-actors/alls-green@b5b5b37504aa4183270bd3d855c52a67f212be35 # v1.3.0
```
New pin line: `uses: actions/download-artifact@9000827ccba6bdab643e8b6fd33ac0654aef8333 # v8.0.2`. Adding it requires a new `{"actions/download-artifact", "v8"} => :node24` entry in `@node24_or_non_js` (`test/threadline/ci_action_runtime_contract_test.exs:18-27`). `bin/verify-action-pins` (network provenance) must accept it. Dependabot (actions, monthly grouped) will track it from then on.

## Package Legitimacy Audit

No npm, Hex or PyPI package is installed by this phase. The one new third-party artifact is a GitHub Action.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| actions/download-artifact v8.0.2 | GitHub Actions | first-party `actions/` org; v8.0.2 published 2026-10-07 | n/a | github.com/actions/download-artifact | OK (official GitHub org; SHA resolved from tag via API) | Approved; pin by SHA; `bin/verify-action-pins` re-proves |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
push/PR ──► ci.yml
   │
   ├─► verify-test (matrix lane: min | current | latest)
   │      compile ─► self-test ─► "Run tests" = mix verify.test_partitioned
   │                                   │
   │                                   ▼
   │                    bin/ci-test-partitions
   │                      enumerate test files
   │                      ── THREADLINE_TEST_SCOPE=toolchain? ─► drop @moduletag :repo_contract files
   │                      assign by weights (greedy, colocate) ─► verify exactly-once vs FILTERED set
   │                      fork N partitions (set -m: own process group each)
   │                          └─ mix test <files> --formatter CLIFormatter --formatter PartitionMonitor
   │                                 PartitionMonitor ─► per-file timings TSV
   │                                 deadline watcher (separate process) ─► HANG block + stacks + halt(1)
   │                      poll loop (kill -0, age) ── age > budget ─► QUIT ─► TERM ─► 10 s ─► KILL -PGID
   │                      collect (per-PID wait || fail=1) ─► report table (+ max/min ratio, ::warning::)
   │                   upload timings TSV (always), upload tmp/ci-test-partitions on failure()
   │
   ├─► verify-example-browser (matrix project: desktop-chromium | mobile-chromium)
   │      setup ─► mix verify.example_browser --project=${{ matrix.project }}  (JSON report)
   │             ─► slow-specs.ts (always(), never fails) ─► step summary + browser-timings-<project>-<run>
   │             ─► playwright --list --project=<p> ─► upload executed + discovered (<project> in names)
   │             ─► on failure(): diagnostics-<project>
   │
   ├─► verify-example-browser-receipt (needs: verify-example-browser)  [skipped if any leg failed]
   │      sparse checkout ─► download pattern operator-ci-* merge-multiple
   │             ─► node --experimental-strip-types operator-ci-evidence.ts --verify … (N files)
   │             ─► upload operator-ci-evidence-<run>
   │
   └─► ci-required (if: always(), needs: every job) ─► alls-green (skipped = failure)
```

### Recommended File Layout (new or changed)
```
bin/ci-test-partitions                    # scope filter, formatter args, watchdog, ratio row, --ingest-weights, self-test cases
bin/browser-full-projects                 # resolve ${{ matrix.project }} from the job's matrix list (fail closed)
bin/measure-main-ci (or a phase tools/ script)   # read-only attempt-1 wall/median/per-job
test/support/partition_monitor.ex         # Threadline.Test.PartitionMonitor (Elixir 1.15-safe)
test/threadline/repo_contract_scope_contract_test.exs   # D-09 (a)+(b), D-10 doc/env/literal assertions
test/threadline/partition_monitor_test.exs            # D-16(b): runtime-built sandbox project
examples/threadline_phoenix/e2e/support/slow-specs.ts (+ .test.ts)
examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts  # N-file inputs
test/threadline/operator_surface/stress_router_alternate_path_test.exs  # only if D-11 split triggers
```

### Pattern 1: The verified shape of a matrix check name
Static `name:` plus one base axis gives `"<name> (<value>)"`. Keys added only through `include` do not append. [VERIFIED: run 40139774739 job names "Build and test (min|current|latest)" from `name: Build and test` + `lane:` axis + include-only keys; ci.yml:614-621 comment]
```yaml
  verify-example-browser:
    name: Example app browser E2E
    strategy:
      fail-fast: false
      matrix:
        project: [desktop-chromium, mobile-chromium]
```
→ "Example app browser E2E (desktop-chromium)" (42 chars, under `@max_check_name_length 48`).

### Pattern 2: Literal-preserving watchdog (keeps the ci_topology contract and its mutation controls valid)
`ci_topology_contract_test.exs:529-603` uses these exact script texts as mutation anchors. Each control asserts that its replacement changed the input:
- `"$MIX_BIN" test --no-compile --no-deps-check --timeout="$PARTITION_TEST_TIMEOUT_MS" "${files[@]}"`
- `"  local fail=0\n  for i in $(seq 1 \"$n\"); do\n    wait \"${pids[i]}\" || fail=1\n  done\n"`
- `"  verify_assignment \"$n\" \"$enumerated\" \"$assignment\" || {\n"`
- `WEIGHTS_REL="test/partition_weights.txt"`

Design so all four survive unchanged:
```bash
# inside the partition subshell (append AFTER "${files[@]}"; bash 3.2 + set -u safe empty expansion)
MIX_TEST_PARTITION="$i" "$MIX_BIN" test --no-compile --no-deps-check --timeout="$PARTITION_TEST_TIMEOUT_MS" "${files[@]}" ${monitor_args[@]+"${monitor_args[@]}"} \
  >"$log_dir/partition-$i.log" 2>&1

# NEW: poll loop BEFORE the unchanged collection loop
watch_partitions "$n" "$log_dir"        # kill -0 + age; on budget: diagnose, QUIT, TERM, sleep 10, KILL -- -PGID, write status=124
local fail=0
for i in $(seq 1 "$n"); do
  wait "${pids[i]}" || fail=1
done
```
On the real path, `monitor_args=(--formatter ExUnit.CLIFormatter --formatter Threadline.Test.PartitionMonitor)`. The fake mix in `write_fake_mix` must learn to consume `--formatter <value>` pairs. Today `--formatter` hits `-*) unexpected flag … exit 3`, and its value would be treated as a file. [VERIFIED: bin/ci-test-partitions:566-592]

### Pattern 3: The PartitionMonitor process split (required by the EM.stop finding)
```elixir
# Formatter (GenServer, started by ExUnit at suite start, STOPPED by EM.stop after suite_finished)
#   handle_cast({:module_started, %ExUnit.TestModule{name: m, file: f}}, s)
#   handle_cast({:test_started, %ExUnit.Test{module: m, name: n, tags: %{file: f, line: l}}}, s)
#   handle_cast({:test_finished, %ExUnit.Test{time: us}}, s)   # time in microseconds
#   handle_cast({:module_finished, %ExUnit.TestModule{}}, s)
#   handle_cast({:suite_finished, times_us}, s)               # %{run:, async:, load:} microseconds
#   handle_cast({:sigquit, current}, s)                       # current = [ExUnit.Test | ExUnit.TestModule]
#   handle_cast(_other, s)  -> {:noreply, s}                  # MUST ignore :case_started/:case_finished, :max_failures_reached
# Watcher (plain spawn, NOT linked to the formatter) owns the deadline.
#   It receives in-flight updates and keeps running after suite_finished. It is armed against
#   VM-relative time (:erlang.statistics(:wall_clock) total ms) so boot/load time counts.
```
Use only fields present on 1.15.8: `ExUnit.TestModule` `[:file, :name, :state, tags: %{}, tests: []]` and `ExUnit.Test` `[:name, :case, :module, :state, time: 0, tags: %{}, logs: ""]`. Do not use `setup_all?`, `parameters` or `description` (1.18+), `Process.set_label` or `Duration` (1.17+), or the `JSON` module (1.18+).

### Anti-Patterns to Avoid
- **Deadline timer inside the formatter GenServer:** it dies at `EM.stop` and never covers "VM won't exit".
- **`wait -n` or `"${arr[@]}"` on possibly-empty arrays:** both fail on macOS `/bin/bash` 3.2 (probed, see Pitfalls).
- **`trap '' QUIT` in the partition subshell:** an ignored signal is inherited as SIG_IGN by exec'd children. Use `trap ':' QUIT` (a handler trap resets to default in children) if the subshell must survive a group-wide QUIT. Simpler: send QUIT only to the BEAM's own PID (`$!` of the backgrounded mix inside the subshell).
- **Guarding the browser example-cache save to one leg:** `cache_miss_guards/3` (`ci_workflow_parity_contract_test.exs:4333-4342`) allows only `steps.<id>.outputs.cache-hit != 'true'` for that job. A `&& matrix.project == …` guard fires `rule=save-guard`. Leave the save unguarded; a second leg's save of an existing key only logs a warning [ASSUMED: actions/cache v5 save-collision behavior].
- **Parsing ExUnit summary lines for ratio math:** parse the script's own table (D-12).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Listing in-flight tests on a hang | A process-dictionary walker that guesses which pid is "the test" | ExUnit's own `{:sigquit, current}` event (exact Test/TestModule structs from the runner's pdict) plus a stack filter on frames whose module ∈ in-flight modules | ExUnit's runner tracks `@current_key` per module process and already reports both test bodies and `setup_all` modules |
| Multi-file CLI args in the receipt | Positional index arithmetic | `node:util` `parseArgs({ options: { discovered: {type:"string", multiple:true}, executed: {…} } })` | Built-in, no dependency |
| Merging per-leg artifacts | `gh` API calls inside the job | `actions/download-artifact` `pattern: operator-ci-*-${{ github.run_id }}` + `merge-multiple: true` | First-party, same-run runtime token |
| Process-tree kill | `pkill -f` patterns | `set -m` process groups + `kill -SIG -- -PGID`, plus a pre-kill `ps -A -o pid=,ppid=` descendant snapshot for children that called `setsid` | Children that `setsid` (e.g. `run-e2e.sh` starts `phx.server` with `start_new_session=True`) escape the group, and once the parent dies they reparent to PID 1 |
| Attempt-1 wall time | `run_started_at`/`updated_at` from `/actions/runs/{id}` | `/actions/runs/{id}/attempts/1` | The run object reflects the **latest** attempt (verified on run 40137607358: attempt 1 ended 22:38:24Z, the run object shows attempt 2 ending 22:42:51Z) |

## Runtime State Inventory

The phase renames the browser check ("(2 projects)" → per-project), so this section applies only for the check name.

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None. Check-run history on GitHub is immutable and irrelevant. | none |
| Live service config | Branch protection requires only `CI required` (`.github/rulesets/main.json`, `bin/verify-branch-protection`). The per-job names are not required contexts. | none. Re-run `bin/verify-branch-protection` read-only after Land B to prove the single context still holds |
| OS-registered state | None | none |
| Secrets/env vars | None renamed. New env names: `THREADLINE_TEST_SCOPE`, `CI_TEST_PARTITIONS_BUDGET_S`, `THREADLINE_TEST_DEADLINE_MS` (all new, no rename) | none |
| Build artifacts | Artifact names change (`operator-ci-evidence-<run>` keeps its name, produced by the fan-in). Old artifacts expire at 14 days. | none |

## Common Pitfalls

### Pitfall 1: Browser-full silently absorbs the CI projects after the matrix split
**What goes wrong:** `bin/browser-full-projects` computes CI projects from `@project_flag ~r/--project[= ]([a-z0-9-]+)/` over `run:` bodies of `mix`/`npx` commands [VERIFIED: bin/browser-full-projects lines `@project_flag` and `body_projects/2`]. `--project=${{ matrix.project }}` yields nothing, so CI = [] and BROWSER-FULL = all default-config projects.
**How to avoid:** In the same commit as the matrix, extend `ci_projects/2`. When a flag value is `${{ matrix.project }}`, read the enclosing job's `strategy.matrix.project` inline list (text parse, since the script has no YAML library). Refuse (exit 1) any other `${{ … }}` project value, a matrix list it cannot parse, or `include`-only project rows. Rewrite the browser_full_projects_contract_test mutation controls that anchor on the old literals (lines ~307-322, 374, 510, 531-532, 586-588) to mutate the matrix list instead.
**Warning signs:** `bin/browser-full-projects --list ci` prints nothing, and `ci_coverage_doc_contract_test` fails on the desktop/mobile rows.

### Pitfall 2: `needs:` on the fan-in breaks the 221 no-preflight rule
`order_needs_errors/1`: "Only ci-required may carry `needs`" [VERIFIED: ci_workflow_parity_contract_test.exs:1357-1363]. Add a narrow exemption (`%{"verify-example-browser-receipt" => ["verify-example-browser"]}`, exact list equality) with a mutation control proving any other `needs` still fails. In the same commit also update: `@ci_job_ids` (:1753-1767, 13 ids → 14), `@time_to_red_order` (:1297-1300, place the receipt directly after `verify-example-browser`), `@ci_check_names` (:1367-1381), ci.yml `ci-required.needs`, the CONTRIBUTING roster lists (both the branch-protection list and the `ci-required` needs roster), and the ci.yml comments "not twelve" (ci.yml:1038) and "all twelve jobs" (ci.yml:1077).

### Pitfall 3: The name contract only understands axis `lane`
`posted_lanes/1` does `with ["lane"] <- axes` and `posted_check_names/2` special-cases only `"verify-test"` [VERIFIED: ci_workflow_parity_contract_test.exs:3217-3245, 1520-1529]. Generalize to `composed_check_names(job, axis)` and add `@verify_example_browser_check_names ["Example app browser E2E (desktop-chromium)", "Example app browser E2E (mobile-chromium)"]`. On the D-08 shard fallback (two base axes), GitHub composes `"(desktop-chromium, 1)"` [ASSUMED from GitHub's multi-axis naming]. The generalized helper should then accept an ordered axis list.

### Pitfall 4: Formatter-owned deadline dies at suite end
`ExUnit.EventManager.stop/1` (1.15.8) runs `GenServer.stop(pid, :normal, @timeout)` for every formatter child [VERIFIED: event_manager.ex lines 20-26]. Formatters are added in `run_with_trap` at run start [VERIFIED: runner.ex:43-46,72], so they also do **not** exist during `test_helper.exs` or file loading. Pre-suite hangs (`Ecto.Adapters.Postgres.storage_up`, `repo.start_link()` in test_helper) are covered only by the bash watchdog.

### Pitfall 5: OTP's default SIGTERM is a graceful stop that can hang
`erl_signal_handler`: `handle_event(sigterm, S) -> … ok = init:stop()`, `handle_event(sigquit, S) -> erlang:halt()` [VERIFIED: OTP-27.3.4 lib/kernel/src/erl_signal_handler.erl lines 45-50]. `init:stop` waits for applications and port owners to terminate, so a stuck VM can ignore TERM. This is consistent with PR #89 ignoring the 5-min cancel grace, though not proven, since the log is unrecoverable. The 10 s TERM → KILL escalation in D-14 is required, not optional.

### Pitfall 6: ExUnit already turns SIGQUIT into a named dump (use it in D-14's diagnose step)
`ExUnit.Runner.run/2` calls `System.trap_signal(:sigquit, …)`. On QUIT it stops module processes, emits `{:sigquit, current}`, and CLIFormatter prints `"Aborting test suite, the following have not completed:"` with `* <test> [file:line]` or `* <Module> [file]` for setup_all [VERIFIED: 1.15.8 runner.ex:14-33,181-197; cli_formatter.ex:169-182,218-224; same mechanism in 1.17.3 and 1.20.4]. Elixir runs user traps first, then the default halt [VERIFIED: 1.15.8 system.ex trap_signal doc: "if you add traps to the signals above, the default behaviour above will be executed after all user signals"]. **Recommendation (within D-14's "diagnose"):** the watchdog sends QUIT to the BEAM PID first, waits up to 30 s for the `HANG:` or "Aborting test suite" marker, then escalates to TERM and KILL. PartitionMonitor's `:sigquit` clause should dump stacks for processes whose `current_stacktrace` contains an in-flight module, **before** the runner kills them. Caveat: the runner shuts down the module processes, while test processes (spawned, not linked) survive until halt. This does not reverse D-13's rejection of "SIGQUIT / erl_crash.dump". That rejection concerned SIGUSR1-style crash dumps; ExUnit's QUIT trap prints names, not a dump.

### Pitfall 7: macOS bash 3.2 traps (probed this session)
- `/bin/bash -c 'set -u; e=(); echo x "${e[@]}"'` → `e[@]: unbound variable`, status 127. Use `${e[@]+"${e[@]}"}`.
- `wait -n` → `wait: -n: invalid option`. Poll with `kill -0`.
- `set -m` works on both 3.2 and 5.2: the background subshell got PGID == its PID, and `kill -TERM -- -PGID` reaped both of its `sleep` children; `wait` returned 143.
- On the dev machine `/usr/bin/env bash` resolves to Homebrew bash 5.2 and `timeout`/`gtimeout` exist via Homebrew. Stock macOS has neither, so do not rely on them (D-14).
- The interactive shell's `grep` is ugrep on this machine (its regex rejects `(alias |\b)`). Scripts must keep using POSIX ERE, which they already do.

### Pitfall 8: `operator-ci-evidence.test.ts` runs nowhere today
`package.json` `"test:unit": "tsx --test support/operator-surface-paths.test.ts"`, and `run-e2e.sh` runs `npm test -- <args>` (`npm run test:unit && playwright test`). No ExUnit test invokes the evidence test [VERIFIED: e2e/package.json; repo-wide grep]. Under plain Node it fails (`ERR_MODULE_NOT_FOUND …/operator-ci-evidence.js`, because the import uses a `.js` specifier that tsx maps and Node does not). Under tsx it passes 10/10. **Recommendation:** add both `operator-ci-evidence.test.ts` and `slow-specs.test.ts` to `test:unit`. They then run before Playwright in every browser leg and locally via `mix verify.example_browser`. Also add an ExUnit contract assertion that `test:unit` lists both files. Keep `slow-specs.ts` imports to `node:*` only, and import siblings with `.ts`-agnostic paths if the fan-in must run it under plain Node.

### Pitfall 9: The ci_topology contract's Run-tests anchor
`run_tests_step_text = "      - name: Run tests\n        run: mix verify.test_partitioned\n"` must stay byte-present (`assert String.contains?(yaml, run_tests_step_text), "mutation anchor missing"`) [VERIFIED: ci_topology_contract_test.exs:533-539], and ci_workflow_parity uses the same text (:519). Put the new keys **after** `run:`:
```yaml
      - name: Run tests
        run: mix verify.test_partitioned
        timeout-minutes: 12
        env:
          THREADLINE_TEST_SCOPE: ${{ matrix.test-scope }}
```
Add `test-scope: toolchain` to the min and latest `include` rows only. An absent key renders as an empty string on current (ci.yml:628-631 notes the same matrix-key behavior). The script must treat empty/unset as full scope and reject unknown values (exit 2). The step must not carry `if:` or `continue-on-error:` (partition_topology_errors and voting_lane_errors).

### Pitfall 10: The global `timeout-minutes: 12` mutation in the Dialyzer contract
`{"measured timeout", String.replace(yaml, "timeout-minutes: 12", "timeout-minutes: 11")}` is a global replace [VERIFIED: ci_topology_contract_test.exs:279]. Adding `timeout-minutes: 12` to Run tests (D-15) and to the browser legs (D-07c) keeps the control red, because it still edits the Dialyzer job. It does make the mutation less targeted, though. Optionally scope that control to the Dialyzer job block.

### Pitfall 11: The D-09 denylist false positives found by static scan
A literal reading of D-09(a) would flag repo-only files:
- `date_release_changelog_test.exs:70` has `use Mix.Project` inside a fixture heredoc.
- `ci_workflow_parity_contract_test.exs` reads `"elixir"` matrix keys (:3141-3392).
- `ci_topology_contract_test.exs` mentions `bin/verify-dialyzer-slice` as asserted text.
- `repo_hygiene_contract_test.exs:244` has `Mix.shell().cmd(` inside a mutation string.
- Many doc contracts mention `Threadline.Plug` in string assertions.

Make the markers **invocation-shaped**: `System.cmd("mix"`, `System.cmd("elixir"`/`"erl"`, `Mix.Task.run(`, `Mix.Tasks.<X>.<f>(`, `Mix.Project.<f>(` (with the dot-call), `Code.fetch_docs(`, `Code.ensure_loaded`/`ensure_compiled`, `Code.eval_`, `\bRepo\.`, `DataCase`, `ConnCase`, `Phoenix.ConnTest`/`Phoenix.LiveViewTest`. For library calls, match `alias <M>` or `<M>.<f>(` where `<M>` is a module **defined under `lib/`** (compute the set at test time from `defmodule` lines in `lib/**/*.ex`), including the `alias Threadline.{A, B}` multi-alias form. Test-support modules (`Threadline.Test.*`, in-file helpers like `Threadline.RemovedArtifactContract`) must not count. Also deny `System.cmd` on `bin/` scripts that call a real `mix`: `bin/verify-clean-checkout`, `bin/verify-bump-rehearsal`, `bin/verify-dialyzer-slice`, `bin/with-rehearsal-registry`, `bin/demo-up` [VERIFIED: grep of mix invocations in bin/*]. Run the denylist against the proposed tag set and tune it before tagging.

### Pitfall 12: Removing Node from min/latest before every Node-executing test is tagged
Tests that execute Node or Playwright are `browser_journey_evidence_contract_test` (`playwright --list`), `operator_surface/operator_evidence_contract_test` (tsx), `playwright_fail_fast_contract_test` (`npm exec`) and `e2e_preflight_contract_test` (bash + node). `browser_journey_evidence_contract_test.exs:142-147` also asserts `npm ci` appears in the verify-test job before "Run tests" via the literal `"working-directory: examples/threadline_phoenix/e2e\n        run: npm ci"`. Put any `if: matrix.lane == 'current'` line **above** `working-directory:` and rewrite that assertion to "current lane only". Add a D-09 contract direction: a file containing `node_modules/.bin` or `System.cmd("npm"`/`"node"` must be tagged. Otherwise a future untagged file breaks min/latest once `npm ci` is gone.

### Pitfall 13: stress_router_test split shape is not "~9 modules / two setup_all" as described
The file has two **test** modules: `Threadline.OperatorSurface.StressRouterTest` (line 120, `setup_all` at 147) and `Threadline.OperatorSurface.StressRouterAlternatePathTest` (line 588, `setup_all` at 597). Seven support modules are defined at the top (Layouts, Auth, LedgerSession, Router, Endpoint, AlternateRouter, AlternateEndpoint), plus three generated inside setup_all [VERIFIED: grep of defmodule lines, stress_router_test.exs]. A split moves `StressRouterAlternatePathTest` and whichever support modules it uses into a new file. Shared support modules must then move to `test/support/` or be duplicated under distinct names, since a module defined twice raises a redefinition warning (and `--warnings-as-errors` on test compile is not used, but credo/duplicate concerns apply). The new file needs a weights row in the same commit (the inventory contract rejects a missing weight).

### Pitfall 14: Release-please and the Land A squash subjects
Release-please parses only the squash subject [CITED: CONTRIBUTING.md "### Ongoing releases (0.6.1+)" last paragraph: "Release Please only parses the squash subject"]. The 244/245 commits include `feat(244-…)`/`feat(245-…)` subjects, but they touch CI/tooling, not `lib/`. Only three 246 `chore:` commits touch `lib/` (critic stress fixtures) [VERIFIED: `git log origin/main..HEAD -- lib/`]. Under D-03, Land A uses non-releasable subjects: `ci:` for 244/245, `chore:` for the 246 removal.

## Code Examples

### Playwright 1.60 JSON fields for slow-specs.ts
```typescript
// Source: examples/threadline_phoenix/e2e/node_modules/playwright/types/testReporter.d.ts (1.60.0)
// JSONReport { config, suites: JSONReportSuite[], errors, stats: { startTime, duration /* ms */, expected, unexpected, flaky, skipped } }
// JSONReportSuite { title, file, line, column, specs: JSONReportSpec[], suites?: JSONReportSuite[] }
// JSONReportSpec { tags, title, ok, tests: JSONReportTest[], id, file, line, column }
// JSONReportTest { timeout, annotations, expectedStatus, projectName, projectId, results: JSONReportTestResult[], status: 'skipped'|'expected'|'unexpected'|'flaky' }
// JSONReportTestResult { workerIndex, parallelIndex, shardIndex?, status, duration /* ms */, error, errors, stdout, stderr, retry, steps?, startTime, attachments, annotations }
type Row = { project: string; file: string; title: string[]; ms: number; attempts: number };
// Walk suites recursively the same way parseExecuted() in operator-ci-evidence.ts does
// (reuse its file/titlePath logic), sum results[].duration across attempts,
// skip tests whose expectedStatus === "skipped" or results.length === 0, flag attempts > 1.
// Totals: per project, per (project,file); also report stats.duration minus the sum of results
// as "unattributed" (server boot and worker fixtures are outside test results).
```
Whether `beforeAll` hook time is attributed to the first test's `results[].duration` is **[ASSUMED]**. Report the unattributed remainder so the split decision does not depend on it.

### Receipt N-file inputs (minimal change to operator-ci-evidence.ts)
```typescript
// main(): keep "--verify <inventory> … <receipt>" but take repeated flags
import { parseArgs } from "node:util";
const { values, positionals } = parseArgs({
  args, allowPositionals: true,
  options: { verify: { type: "boolean" }, discovered: { type: "string", multiple: true }, executed: { type: "string", multiple: true } },
});
// discovered = values.discovered.flatMap(p => parseDiscovered(readFileSync(p, "utf8")))
// executed   = values.executed.flatMap(p => parseExecutedJson(readFileSync(p, "utf8")))
// validateEvidence() is unchanged: uniqueIndex() rejects duplicates; a missing leg → "required journey was not executed"
```
`browser_journey_evidence_contract_test.exs:163` asserts only `support/operator-ci-evidence.ts --verify` and the receipt filename, so the flag shape is free. Extend `operator-ci-evidence.test.ts` with one case that splits the two projects across two executed files and one that drops a leg (expects "not executed").

### Fan-in job skeleton
```yaml
  verify-example-browser-receipt:
    name: Browser journey receipt
    needs: verify-example-browser
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09 # v5.1.0
        with:
          sparse-checkout: examples/threadline_phoenix/e2e/support
      - uses: actions/setup-node@a0853c24544627f65ddf259abe73b1d18a591444 # v5.0.0
        with:
          node-version-file: .tool-versions
      - uses: actions/download-artifact@9000827ccba6bdab643e8b6fd33ac0654aef8333 # v8.0.2
        with:
          pattern: operator-ci-*-${{ github.run_id }}
          path: ${{ runner.temp }}/legs
          merge-multiple: true
      - name: Reconcile required operator journey evidence
        working-directory: examples/threadline_phoenix/e2e
        run: >-
          node --experimental-strip-types support/operator-ci-evidence.ts --verify …
```
Notes:
- Cone-mode sparse checkout includes root-level files, so `.tool-versions` is present for setup-node [ASSUMED: git cone-mode semantics].
- `setup-node` without `cache:` avoids needing the lockfile.
- The workflow is `permissions: contents: read`. Same-run downloads are expected to work through the runtime token without `actions: read` [ASSUMED]. If the first PR run shows 403, add `actions: read` for this job **and** a `@job_read_grants` entry in `ci_token_permissions_contract_test.exs:73-92`.
- The `pattern` must not also match the receipt artifact (`operator-ci-evidence-<run>`) the fan-in uploads. Name leg artifacts `operator-ci-executed-<project>-<run>` / `operator-ci-discovered-<project>-<run>` and use two download steps, or a pattern like `operator-ci-{executed,discovered}-*`. Glob brace support in `pattern` is [ASSUMED], so prefer two steps.

## CI-03 Classification (all 113 `*_contract_test.exs` plus non-contract repo-only candidates)

The scan ran this session over every `test/**/*_test.exs` with invocation-shaped markers. Weights are ms from `test/partition_weights.txt` (local, traced). The executor confirms each row with the new D-09 contract before the tag lands.

**Tag A: heavy, read this session, repo-only (the load that matters):**

| File | ms | Why repo-only |
|---|---|---|
| playwright_fail_fast_contract_test.exs | 32012 | runs `bin/verify-playwright-fail-fast` (npm/Playwright), no Mix |
| planning_independence_contract_test.exs | 18742 | `bin/verify-planning-independent` with a **fake** `mix` on PATH (asserts invocation log `deps.get --check-locked\nnpm ci\ndialyzer --plt\nci.all\n`) |
| browser_full_projects_contract_test.exs | 17230 | runs `bin/browser-full-projects` (text parsing; its production consumer runs on `.tool-versions`) |
| repo_hygiene_guard_test.exs | 10976 | git + `bin/verify-repo-hygiene` |
| ci_workflow_parity_contract_test.exs | 5378 | YAML/text + `git` only (the `"elixir"` hits are matrix keys) |
| deps_health_report_test.exs | 3270 | `bin/deps-health-report` through the fake-`mix` `MIX_BIN` seam |
| deps_audit_gate_test.exs | 2960 | `bin/verify-deps-audit` through a fake `mix` |
| ci_coverage_doc_contract_test.exs | 2169 | doc text + `bin/browser-full-projects` |
| verify_action_pins_test.exs | 1777 | `bin/verify-action-pins` offline cases |
| branch_protection_comparison_contract_test.exs | 1448 | bash script |

**Tag B: light, scan-clean (weight ≤ 1 s each; tag mainly to satisfy D-09(b)):** browser_journey_evidence (800), date_release_changelog_test (800), removed_artifact (785), ci_sha_gate (955), main_ci_observer (633), e2e_preflight (555), ci_issue_upsert (542), flake_classifier (508), ci_token_permissions (451), dependabot_config (439), operator_surface/operator_surface_fixture (414), temp_leak_check_test (229, fake `MIX_BIN`), operator_surface/operator_evidence (200), guides/upgrade_path (152), ci_topology (124, after the marker tuning in Pitfall 11), ci_action_pin (101), ci_attestation (77), operator_surface/style (75), guide_graph (71), row_history_focus_evidence (52, fake `MIX_BIN`; confirm), hex_pin (50), planning_dependency (34), community_health_render (33), community_health (14), release_control_plane (14), version_truth_doc (13), semver_adopter_doc (9), ci_action_runtime (8), deps_audit (7), public_options (6), and the ≤ 4 ms doc contracts: adoption_evidence_playbook_doc, audit_doc (uses test/support `GettingStartedFixtures`; confirm it calls no lib module), changelog, evaluating_threadline_doc, evidence_cli_doc, example_phoenix_schemas_mount, exploration_routing_doc, guides/redaction, guides/stability, guides/table_shapes, incident_playbook_doc, performance_doc, persona_routing_doc, production_checklist_doc, release_ci_gate, release_distribution_doc, support_playbook_doc, ui_critic_retirement_doc, upgrading_to_0_11_doc, upgrading_to_1_0_doc. Also repo_hygiene_contract (227; its `Mix.shell().cmd(` is inside a string) and deps_health_doc / local_docker_dx (bin paths mentioned as text). These last three are tagged after confirming the hits are text, not invocations.

**Exempt (stay untagged; one-line reason for the D-09(b) map):**

| File | Reason code |
|---|---|
| clean_checkout_contract_test.exs (15573) | runs `bin/verify-clean-checkout`, which runs a real `mix deps.get --check-locked` in a clone |
| public_surface_contract_test.exs (35153) | `Code.fetch_docs` / compiled docs |
| release_artifact_contract_test.exs (12154) | `mix hex.build` |
| dialyzer_slice_contract_test.exs (8286) | Dialyzer / real mix |
| retry_network_contract_test.exs (1300) | real `System.cmd("mix", ["help", "compile"])` (:1219) |
| doc_rubric (1646), readme_doc (872), copy (414), rendered_output (875), telemetry_registry (294), storage_schema_prefix (190), storage_schema_call_site (175), export_public (107), idle_transaction_reaper (94), storage_catalog (59) | Repo/DataCase/ConnCase or compiled library calls |
| formatter_topology (377), capture/public_sql (312), source_size (220), facade_only_references (214), doc_spec_coverage (99), source_comment_location (89), test_structure (76), optional_deps (75), credo_config (69), property_scale (69), operator_surface/coverage_doc (58), operator_surface/ui_form_policy (34), operator_surface/component (22), dialyzer_ignore (15), code_walkthrough_doc (11), no_warn_undefined (10), layer_boundary (8), facade_naming (7), ci_all_dedup (7), example_phoenix_readme (7), health_findings_doc (6), operator_surface/exports_doc (6), operator_surface/policy_show_doc (5), operator_surface/timeline_browse_doc (5), getting_started_saas_doc (4), storage_schema_migration (3), lookup_return_shapes (3), telemetry_doc (3), ignore_advisories (2), schema_fields (2), operator_surface_doc (2), actor_reads_doc (1), adoption_pilot_doc (1), how_threadline_works_doc (1), integration_contracts_doc (1), integrations/sigra_doc (1), upgrade_path_doc (1), integrations/phx_gen_auth_doc (0), audit_indexing_doc (0) | parse code with this toolchain's `Code`/`Macro` AST, load compiled modules, or call `lib/` / Mix task modules |
| zero_skips_contract_test.exs (1357) | asserts the **running lane's** `ExUnit.configuration()[:exclude]` |

Estimated effect: Tag A + B ≈ 102 s raw local weight removed from min/latest (≈ 85 s of it sync), in line with CONTEXT's ~89 s / ~58 s effective estimate. The colocated group `clean_checkout | planning_independence | release_artifact` (`test/partition_colocate.txt`) keeps working. `assign_files` ignores colocate entries that are not enumerated: "listed files that no longer exist are simply never seen below" [VERIFIED: bin/ci-test-partitions:182-185].

## CI-03/D-11 mechanics

- **Filter insertion point:** after `enumerate_test_files >"$enumerated"` in `run_partitions` (bin/ci-test-partitions:356). Write `enumerated.full.txt`, then filter by `grep -lE '^[[:space:]]*@moduletag :repo_contract[[:space:]]*$'` when `THREADLINE_TEST_SCOPE=toolchain`. `verify_assignment` already compares against whatever `$enumerated` holds, so pass the filtered list. Print `N repo-contract files run on the current lane only` to stdout and the step summary.
- **Weights inventory contract unchanged:** `partition_weight_inventory_errors` compares the weights file against `enumerated_test_files!()` (the full `find`) [VERIFIED: ci_topology_contract_test.exs:60-85]. A weights row for a file filtered out on min/latest is "stale" for that run, and `assign_files` ignores stale entries by design.
- **Ratio row:** in `report()` (:289-323), compute max/min over partitions with ≥ 1 file and numeric seconds. Add `| max/min | - | 1.23 | - |` and `printf '::warning::partition ratio %s exceeds 1.15\n'` on stdout (not the summary).
- **`--ingest-weights <dir>`:** reads `partition-timings-*.tsv` (one header line + `file<TAB>wall_ms<TAB>test_ms<TAB>async`). Take the per-file median across runs (awk sort per key). Keep existing weights for files absent from the inputs, print `moved >2x` lines, and write the same header block plus sorted `<ms> <file>` rows. Self-test: a sandbox with three TSV fixtures, asserting median and sort.
- **Async factor fit:** for each partition p in each run, `wall_p ≈ boot_p + S_p + k·A_p`, where S/A are summed sync/async per-file walls. OLS for k over the 12 points of 3 runs × 4 partitions (closed form: `k = Σ(y−S)·A / ΣA²` after subtracting boot). Record k and its run IDs in a comment beside the constant that replaces `int(raw / 4)` at bin/ci-test-partitions:175.
- **Artifact names (avoid 409s):** `partition-timings-${{ matrix.lane }}-${{ github.run_id }}` (always) and `partition-logs-${{ matrix.lane }}-${{ github.run_id }}` (on `failure()`), both with the already-pinned upload-artifact.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Weights from `--slowest-modules` (forces `--trace`, Elixir ≥ 1.17, warm Mac) | Per-file walls recorded by a CI formatter, ingested offline | this phase | Weights match CI, including the min lane |
| Job/step timeouts as the hang guard | Script-owned budget + process-group kill + in-VM naming | this phase | Hang becomes red in about 8 min with a name, not 25 min with no log |
| One browser job for both projects | Matrix legs + fan-in receipt | this phase | Critical path ≈ max(leg) + fan-in + gate |

**Deprecated/outdated:** formatter events `:case_started`/`:case_finished` (still emitted in 1.15.8 through 1.20.4, documented "deprecated and should be ignored") [VERIFIED: 1.15.8 formatter.ex:33-40].

## Landing mechanics (D-01/D-02)

- **State:** 162 commits on `milestone/v1.47` not on `origin/main` (merge-base `23178fb0`, "docs(planning): adopt rolling quality roadmap after 1.1.0 (#89)") [VERIFIED: `git log origin/main..HEAD`]. Releasable-typed subjects exist only as per-commit `feat(244-…)`/`feat(245-…)`/`fix(24x…)` (CI/release tooling). `lib/` is touched only by three 246 `chore:` commits (35243789, 1258c014, 4b2c3f89).
- **Precedent:** build a fresh `land/<name>` branch from `origin/main` in a temporary worktree. Cherry-pick `git log --reverse <range> -- . ':!.planning'`, add a `docs(planning): sync …` commit via `git checkout <milestone-sha> -- .planning`, run `bin/verify-repo-hygiene`, push, open a PR and squash-merge [maintainer memory: landing-branch-extension; STATE.md v1.43 entries]. Inspect `git show HEAD -- CHANGELOG.md` after any CHANGELOG pick (hunks can land under a dated section).
- **Order:** (1) A1 `ci:` squash for 244+245. (2) A2 `chore:` squash for the 246 removal slices C1-C8, as its own PR (246 D-12). (3) Maintainer: `! git push origin refs/tags/archive/ui-critic-loop` after A2's squash SHA exists (246 D-13; non-blocking). (4) B `ci:` PR: CI-01 + PartitionMonitor + watchdog + CI-03 scope + tags + docs. (5) Observe ≥ 3 main runs. (6) C `ci:` PR: CI-02 split + resolver + contract generalization + weights ingest + optional stress_router split. (7) Measure.
- **Hand-offs:** pushes, PR creation and merges are covered by the standing merge grant, but the action classifier has blocked them unless the grant names the verbs (maintainer memory: push-blocked-by-classifier). Plan each landing task with a ready-to-copy `! gh pr merge <n> --squash --subject "…" --body "…"` fallback. `workflow_dispatch` runs on main (to collect the 5/3 samples faster) are a GitHub write and a spend decision. Ask in one batch. Note the concurrency group `${{ github.workflow }}-${{ github.ref }}` keeps only one pending run per ref, so a queued dispatch or push run can be replaced (cancelled). Dispatch one at a time and exclude cancelled runs from the "5 consecutive" set.
- **Squash body:** set `--body` explicitly so the merged message carries no stray conventional-commit lines. This is belt and braces; CONTRIBUTING states that only the subject is parsed.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Same-run `download-artifact` works without `actions: read` under `permissions: contents: read` | Fan-in skeleton | First PR run 403s. Add `actions: read` + a token-permissions contract entry |
| A2 | A second leg's `actions/cache/save` of an existing key only warns | Anti-patterns | A leg fails. Then guard the save and extend `cache_miss_guards/3` |
| A3 | Playwright attributes `beforeAll` time to the first test's result duration | CI-01 example | Per-file totals undercount. Mitigated by reporting "unattributed" |
| A4 | A two-base-axis matrix composes `"(desktop-chromium, 1)"` | Pitfall 3 | Only matters on the D-08 shard fallback |
| A5 | Cone-mode sparse checkout keeps root `.tool-versions` | Fan-in skeleton | setup-node fails. Add `.tool-versions` explicitly or use `sparse-checkout-cone-mode: false` with a file list |
| A6 | `download-artifact` `pattern` brace globs | Fan-in | Use two download steps (recommended anyway) |
| A7 | `node:util.parseArgs` `multiple: true` on Node 22.14 | Receipt | Low. Fallback: manual flag loop |
| A8 | The PR #89 hang shape (setup_all / on_exit / VM shutdown / PG contention) | CI-04 | The attempt-1 log is unrecoverable. D-16(c) reproduces the shape synthetically and VERIFICATION must say so |

## Open Questions (RESOLVED)

1. **Whether the A1 (244/245) squash should be releasable.** CONTEXT D-03 says this phase's work is non-releasable, and 244/245 carry `feat(...)` per-commit subjects that are CI/release tooling only. Recommendation: `ci:`. No adopter-facing CHANGELOG entry exists to strand. Confirm by diffing `CHANGELOG.md` on the land branch for `Security`/`Fixed` entries before merging.
   **RESOLVED:** `ci:`. 247-01 diffs `CHANGELOG.md` against origin/main on the A1 land branch and stops at its checkpoint for the maintainer if any adopter-facing `## Unreleased` entry would be stranded.
2. **Per-leg budget numbers.** Provisional: step 9 / job 12 min. Final values come from CI-01 data in the D-16 budget style (D-07c is Claude's discretion).
   **RESOLVED:** 247-08 derives the provisional per-leg step/job timeouts from ≥ 3 main runs of CI-01 data (`247-OBSERVATION.md` `## CI-02 split design inputs`, arithmetic shown); 247-10 writes them into ci.yml with the arithmetic in the comment.
3. **Whether min/latest still miss 1.15 after a current-lane refresh.** D-11 allows per-lane weights only on evidence. The ingest mode should accept `--lane` from the first version, at little cost.
   **RESOLVED:** 247-04 ships `--ingest-weights <dir> [--lane <name>]` from the first version, selecting TSVs by a `lane=` header field the monitor writes from `THREADLINE_CI_LANE` (set to `${{ matrix.lane }}` in ci.yml by 247-05). 247-12 refreshes with `--lane current`. If 247-13 measures a min/latest ratio miss, the per-lane weights file and its selection in the runner are the gap-closure plan (D-11 fallback); the ingest side needs no change.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Docker daemon | Ephemeral `postgres:16` for local suites; optional Elixir 1.15 image for D-13 min-compat | ✓ | server 29.5.2 | push to a PR and read the min lane |
| Elixir 1.15.8 / OTP 26 locally | D-13 compile check on min | ✗ (asdf has 1.17.3+ only) | — | a docker `hexpm/elixir` 1.15.8/OTP 26 image [ASSUMED tag naming] or the CI min lane |
| Elixir 1.17.3 / OTP 27 | current lane, local runs | ✓ | 1.17.3 | — |
| Node | tsx tests, strip-types probe | ✓ | 22.14.0 | — |
| `gh` (authenticated) | read-only measurement, `gh run download` for ingest | ✓ | 2.101.0 | — |
| `/bin/bash` 3.2 and bash 5.2 | watchdog portability proof | ✓ both | 3.2 / 5.2.37 | — |
| `timeout`/`setsid` | — (must NOT be used) | timeout via Homebrew only; setsid ✗ | — | `set -m` + poll |
| psql | watchdog `pg_stat_activity` backstop | ✓ locally; on CI runner via the postgres client | — | skip the backstop when `psql` is absent |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17.3 local / CI matrix 1.15.8, 1.17.3, 1.20.4); `node:test` via tsx 4 for TS; bash self-test harness in `bin/ci-test-partitions --self-test` |
| Config file | `test/test_helper.exs` (unchanged except a pointer comment); `examples/threadline_phoenix/e2e/package.json` `test:unit` |
| Quick run command | `DB_PORT=<ephemeral> mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/browser_journey_evidence_contract_test.exs test/threadline/browser_full_projects_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs test/threadline/ci_action_pin_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs test/threadline/repo_contract_scope_contract_test.exs` |
| Full suite command | `mix verify.test` on an ephemeral `postgres:16` (`docker run -d --rm -e POSTGRES_PASSWORD=postgres -p 55432:5432 postgres:16`, `DB_PORT=55432`). Never the shared PG14 on 5432 |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CI-01 | slow-specs ranking, cap 20, retry summing, skip exclusion, oversize/malformed → warning exit 0 | unit (node:test) | `cd examples/threadline_phoenix/e2e && ./node_modules/.bin/tsx --test support/slow-specs.test.ts` | ❌ Wave 0 |
| CI-01 | step exists in every leg, `if: always()`, file-exists guard, writes `$GITHUB_STEP_SUMMARY`, uploads `browser-timings-…` 14 d | contract | `mix test test/threadline/browser_journey_evidence_contract_test.exs` | ✅ (extend) |
| CI-01 | TS unit tests are wired (`test:unit` lists both files) | contract | same file, new test | ❌ |
| CI-01 | summary visible on a real main run | live | read the job summary / `gh run download <id> -n browser-timings-all-<id>` | live main run |
| CI-02 | matrix projects == inventory `votingProjects`; check names compose; retired name absent; roster; needs exemption; job ids; time-to-red | contract | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs` | ✅ (extend) |
| CI-02 | `bin/browser-full-projects --list ci` == `desktop-chromium mobile-chromium` with the matrix; fails closed on unresolvable `${{ }}` | contract + mutation | `mix test test/threadline/browser_full_projects_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs` | ✅ (extend) |
| CI-02 | receipt merges N files, a missing leg → "not executed", duplicates rejected | unit | `./node_modules/.bin/tsx --test support/operator-ci-evidence.test.ts` | ✅ (extend; currently unwired) |
| CI-02 | download-artifact pin form + node24 + provenance | contract / network | `mix test test/threadline/ci_action_pin_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs`; `bin/verify-action-pins` | ✅ |
| CI-02 | median wall ≤ 9 min over 5 attempt-1 main runs | measurement | `bin/measure-main-ci --since <split-sha> --count 5` (new, read-only, with a fake-`gh` contract test like `main_ci_observer_contract_test`) | ❌ Wave 0 + live main runs |
| CI-03 | tagged file absent under scope=toolchain, present once under full scope, summary count, unknown scope → exit 2 | self-test | `bin/ci-test-partitions --self-test` | ✅ (extend) |
| CI-03 | D-09 (a) no dodging, (b) every contract tagged or exempted; env var on min/latest rows only; CONTRIBUTING sentence; script filter literal == tag | contract | `mix test test/threadline/repo_contract_scope_contract_test.exs` | ❌ Wave 0 |
| CI-03 | `test_helper` excludes unchanged | contract | `mix test test/threadline/zero_skips_contract_test.exs` | ✅ |
| CI-03 | `--ingest-weights` median + header + moved-2× report | self-test | `bin/ci-test-partitions --self-test` | ✅ (extend) |
| CI-03 | weights inventory still complete after ingest/split | contract | `mix test test/threadline/ci_topology_contract_test.exs` | ✅ |
| CI-03 | ratio ≤ 1.15 over 3 runs per lane | measurement | parse the "max/min" row from 3 consecutive main-run step summaries (`gh api …/jobs/<id>/logs` or the summary) | live main runs |
| CI-03 | no new order coupling after reassignment | flake | `mix verify.flake` (ephemeral PG) or 3 green CI runs | ✅ |
| CI-04 | hang killed within budget, 124 in table, "exceeded budget", no leftover process; TERM-ignoring child escalated to KILL | self-test | `CI_TEST_PARTITIONS_BUDGET_S=3 bin/ci-test-partitions --self-test` (seam set inside the case) on both `/bin/bash` and bash 5 | ✅ (extend) |
| CI-04 | monitor names `file:line` + a stack frame for a test-body hang and a `setup_all` hang | integration (runtime-built sandbox, default suite) | `mix test test/threadline/partition_monitor_test.exs` | ❌ Wave 0 |
| CI-04 | monitor compiles and behaves on Elixir 1.15.8 / OTP 26 | CI lane | the min lane runs the partitioned suite with the formatter attached (every PR) | live PR run |
| CI-04 | PR #89 shape reproduced red, module named, well under 20 min | live synthetic | throwaway-branch PR run with `Process.sleep(:infinity)` in a `setup_all` | live (dispatch/PR, maintainer grant) |

### Sampling Rate
- **Per task commit:** the quick-run contract list above, plus `bin/ci-test-partitions --self-test` and the tsx unit tests for any touched TS.
- **Per wave merge:** `mix verify.test` on ephemeral `postgres:16`, plus `mix verify.credo` and `mix format --check-formatted`.
- **Phase gate:** `mix ci.all` green (CI=true) on an ephemeral PG16. Then live: 3 observed runs after B, 5 attempt-1 runs after C (median), 3 runs per lane for the ratio, and one synthetic-hang PR run.

### Wave 0 Gaps
- [ ] `examples/threadline_phoenix/e2e/support/slow-specs.test.ts`, plus `test:unit` wiring for it and `operator-ci-evidence.test.ts`
- [ ] `test/threadline/repo_contract_scope_contract_test.exs` (D-09/D-10)
- [ ] `test/threadline/partition_monitor_test.exs` (D-16(b); builds fixtures in `System.tmp_dir!` at runtime, never as committed `*_test.exs`)
- [ ] the measurement script and its fake-`gh` contract test
- [ ] fake-mix support for `--formatter X` pairs and a `hang` / `hang_ignore_term` plan behavior in `write_fake_mix`

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes (CI token scope) | `permissions: contents: read` stays. Any `actions: read` grant is job-scoped and recorded in `ci_token_permissions_contract_test` |
| V5 Input Validation | yes | `slow-specs.ts` and the receipt cap input size (`MAX_REPORT_BYTES` 20 MiB), validate the JSON shape, and use `SAFE_NAME` for project names. The step summary gets numbers/names only, never raw logs |
| V6 Cryptography | no | — |
| V14 Configuration (supply chain) | yes | New action pinned by full SHA with an exact tag. `bin/verify-action-pins` proves provenance. `@node24_or_non_js` entry |

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Artifact poisoning between jobs | Tampering | Same-run artifacts only (no `run-id`/`github-token` inputs), names scoped by `run_id` |
| Mutable action tag | Tampering | SHA pin + provenance check |
| Log/summary injection from test titles | Tampering | Escape `|` and newlines in Markdown table cells. Cap title length |
| Fan-in skipped reads as green | Elevation | `ci-required` `if: always()` + alls-green with no `allowed-skips` (skipped counts as failure) |

## Sources

### Primary (HIGH confidence)
- In-repo files read this session: `.github/workflows/ci.yml` (600-1078), `bin/ci-test-partitions` (1-912), `bin/browser-full-projects` (1-448), `test/threadline/ci_topology_contract_test.exs` (60-660), `test/threadline/ci_workflow_parity_contract_test.exs` (460-700, 1095-1640, 1694-2060, 2385-2530, 3217-3247, 3990-4080, 4326-4345, 5470-5903), `test/threadline/browser_journey_evidence_contract_test.exs` (1-175), `test/threadline/zero_skips_contract_test.exs`, `test/threadline/hex_pin_contract_test.exs` (20-60, 520-568), `test/threadline/ci_token_permissions_contract_test.exs` (40-100), `test/threadline/ci_action_pin_contract_test.exs` (1-60), `examples/threadline_phoenix/e2e/{playwright.config.ts,package.json,run-e2e.sh,support/operator-ci-evidence.ts}`, `CONTRIBUTING.md` (61-100, 285-384, 809-920), `mix.exs`, `test/test_helper.exs`, `release-please-config.json`, `.planning/seeds/SEED-006…`
- Elixir upstream source at tags v1.15.8, v1.17.3, v1.20.4: `lib/ex_unit/lib/ex_unit.ex`, `ex_unit/formatter.ex`, `ex_unit/runner.ex`, `ex_unit/cli_formatter.ex`, `ex_unit/event_manager.ex`, `lib/mix/lib/mix/tasks/test.ex`, `lib/elixir/lib/system.ex`
- OTP-27.3.4 `lib/kernel/src/os.erl`, `erl_signal_handler.erl`
- Playwright 1.60.0 `playwright/types/testReporter.d.ts` (installed)
- GitHub API (read-only): runs 40139774739, 40137607358 (+ `/attempts/1`), job 121002346075; `actions/download-artifact` v8.0.2 tag/commit/action.yml/README

### Secondary (MEDIUM confidence)
- Maintainer memory notes (landing-branch-extension, push-blocked-by-classifier, local gate gotchas), corroborated by STATE.md entries

### Tertiary (LOW confidence)
- Items A1-A8 in the Assumptions Log

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH. No new packages; one action pin resolved via API.
- Architecture / contract inventory: HIGH. Every moved literal was read in its file.
- Pitfalls: HIGH for ExUnit/OTP/bash (source + probes); MEDIUM for Actions runtime behaviors (A1, A2, A5, A6).
- CI-03 classification: MEDIUM. Static scan plus targeted reads; the executor's D-09 contract is the arbiter.

**Research date:** 2026-10-26
**Valid until:** 2026-11-25 (CI topology moves fast inside this milestone; re-read ci.yml after Land A)
