# Phase 247: CI critical path and suite lanes - Context

**Gathered:** 2026-10-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Required CI (`ci.yml`) finishes in ≤ 9 minutes median on main without dropping coverage, test partitions are balanced (slowest/fastest ≤ 1.15 over 3 runs), and a hung test fails fast and names itself. Requirements CI-01..CI-04. Measured on main, on the post-246 suite and Playwright project set.

Research method: three parallel researchers (CI-01/02 browser split, CI-03 lanes + partitions, CI-04 hang detection) plus an orchestrator cross-cutting/adversarial pass (sequencing, landing, coherence between clusters). The maintainer approved the synthesized set with a single confirm on 2026-10-26.

</domain>

<baseline>
## Measured Baseline (main, before this phase)

- **ci.yml run wall time**, last 5 main push runs, attempt 1 (`run_started_at` → `updated_at`): 13.5 / 11.05 / 10.05 / 12.3 / 12.07 min, **median 12.07 min**. Run wall ≈ browser job + ~7 s `ci-required`.
- **Browser job** "Example app browser E2E (2 projects)": 802 / 653 / 593 / 706 / 715 s (median 706 s). Run 40139774739: setup 43 s (all cache hits), Playwright step 754 s (~30 s of it compile + server boot in `run-e2e.sh`); "Running 482 tests using 1 worker … 418 passed, 64 skipped (12.1m)". 241 tests per project in `--list`; inventory requires 16 desktop + 15 mobile journeys. **No per-spec durations exist anywhere** (JSON report written to `runner.temp`, never uploaded).
- Next slowest: "Capture evidence byte-stable" 357–448 s (still on main; 246 removes it), "Build and test (current)" 280–397 s; everything else < 170 s.
- **Partition seconds (p1..p4) / ratio**, runs 40139774739, 40107416579, 40056037547:
  - min: 206/146/186/182 (1.41), 202/144/187/185 (1.40), 201/142/187/181 (1.42)
  - current: 136/103/134/136 (1.32), 200/127/181/175 (1.57), 143/91/132/130 (1.57)
  - latest: 152/106/142/136 (1.43), 198/150/184/168 (1.32), 185/134/166/155 (1.38)
  - The greedy assignment is fine (local plan: 74,397/74,396/74,396/74,396 ms). **The weights are wrong for CI**: they come from `--slowest-modules` (which forces `--trace`, unavailable before Elixir 1.17, so never on min), are Mac-warm, and use a guessed 1/4 async factor. Partition 2 (git/shell-heavy colocated group) is consistently ~30 s fastest.
- **PR #89 hang** (run 40137607358 attempt 1, job 121002346075, "Build and test (min)", OTP 26.2.5 / Elixir 1.15.8): step 16 "Run tests" started 22:14:24 and never completed; 22:33:17 = 20-min job timeout (ci.yml:655); completed 22:38:17 = +5-min default cancel grace — the step ignored cancel signals the whole grace. "25 minutes" = 20 + 5. **The attempt-1 log is unrecoverable** (`BlobNotFound`; attempt-1 log zip lacks the job); only the annotation "The job has exceeded the maximum execution time of 20m0s" survives. A test body cannot cause this (ExUnit `--timeout=180000` would fail it); candidates are `setup_all` (no timeout; 38 files use it, e.g. `test/threadline/operator_surface/rendered_output_contract_test.exs` runs external commands), `on_exit`, `test_helper.exs` pre-start, VM shutdown, or cross-partition Postgres contention. Signal chain: runner → `bash -e` → mix BEAM → `Mix.shell().cmd` → `sh` → `bin/ci-test-partitions` → subshells → 4 `mix test` BEAMs.

</baseline>

<decisions>
## Implementation Decisions

### Sequencing and landing (cross-cutting)
- **D-01: Landing v1.47 to main is in scope of this phase.** Every gate is measured on main and none of v1.47 (160 commits on `milestone/v1.47`) is on main. Land under the standing merge grant (merge own green quality PRs, report after). — **Reversibility:** costly — merged PRs on main are reverted, not unmerged.
- **D-02: Order.**
  1. **Land A** — 244/245/246 work, with the 246 critic removal as its own non-releasable `chore:` squash PR (246 D-12); the `archive/ui-critic-loop` tag push stays a maintainer hand-off (246 D-13) and does not block 247. Then a `ci:` PR carrying CI-01, the CI partition monitor formatter (D-13), the CI-04 watchdog, and the CI-03 lane scope (D-09/D-10).
  2. **Observe** ≥ 3 main runs: read browser per-project / per-file totals (CI-01) and collect per-file test timing artifacts (D-12).
  3. **Land B** — CI-02 matrix split + receipt fan-in, weights refreshed from CI timings, `stress_router_test.exs` split if it still exceeds an even share.
  4. **Measure** — 5 main runs for the median, 3 runs for the partition ratio (D-08).
  CI-01 MUST be on main and read before the CI-02 split is designed in detail (roadmap SC1).
- **D-03: Commit types.** CI/test infrastructure changes are non-releasable (`ci:`/`chore:`/`test:`); nothing in this phase changes the public API or the Hex package.

### CI-01: slow browser specs
- **D-04: Source = the JSON report CI already writes** (`PLAYWRIGHT_JSON_OUTPUT_FILE`, `results[].duration` per attempt), summarized by a committed `examples/threadline_phoenix/e2e/support/slow-specs.ts` run with the already-installed `tsx`, in the style of `operator-ci-evidence.ts`. No new dependency, no reporter config change.
  - Rejected: custom Playwright reporter (changes the `[["github"], ["json"]]` reporter config pinned by `browser_journey_evidence_contract_test.exs`); built-in `reportSlowTests` (per file, annotation-only, not contract-testable); `--reporter` CLI flag (overrides config reporters and silently drops the JSON the receipt parses).
  - Footguns: sum all attempts' durations and flag retried tests; exclude skipped (duration 0); cap input size like `MAX_REPORT_BYTES`.
- **D-05: Output = both** a Markdown table in `$GITHUB_STEP_SUMMARY` (top 20: project, file, title, duration, attempts; plus per-file and per-project totals — the totals are what inform the split) **and** a JSON artifact `browser-timings-<project|all>-<run_id>` (14-day retention). Runs on every event under `if: always()` + file-exists guard; never fails the job (missing/malformed report → warning).
- **D-06: Pinning.** Extend `browser_journey_evidence_contract_test.exs` (step exists in `verify-example-browser`, `always()`-guarded, writes the step summary, artifact names the timings file) and add a `slow-specs.test.ts` unit test (ranking, cap 20, retry/skip handling) invoked the way `operator-ci-evidence.test.ts` is.

### CI-02: browser split
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

### CI-03: repo-file contract tests on the current lane only + partition balance
- **D-09: Classify with `@moduletag :repo_contract`**, meaning "outcome does not depend on the Elixir/OTP/PostgreSQL toolchain". Module tag only, never per-test `@tag` (exclusion is per file). The file name is NOT the classifier: `public_surface_contract_test` (`Code.fetch_docs`), `release_artifact_contract_test` (`mix hex.build`), `dialyzer_slice_contract_test` depend on the toolchain; `repo_hygiene_guard_test`, `verify_action_pins_test`, `date_release_changelog_test` are repo-only despite their names. ~51 candidate files (~89 s raw / ~58 s effective) from a static scan — each needs review before tagging; read `clean_checkout` / `planning_independence` first (they may assert this-toolchain behaviour → stay untagged).
  - Enforced by a new contract test (itself tagged `:repo_contract`), two directions: (a) **no dodging** — a tagged file fails if it contains denylisted markers (`"mix"`/`Mix.Task`, `Repo.`, `DataCase`/`ConnCase`, `Code.fetch_docs`/`ensure_*`/`eval`, `Phoenix.*Test`, `Threadline.<Module>.fun(` calls, `elixir`/`erl` invocations); (b) **no silent unclassified** — every `*_contract_test.exs` carries the tag or sits in an exemption map in the test with a one-line reason. Failure direction is safe: untagged runs everywhere.
  - Rejected: path convention (moving ~50 files breaks `partition_colocate.txt`, weights, docs, blame); manifest file (drifts, second source of truth).
- **D-10: Exclude by file filtering in `bin/ci-test-partitions`**, driven by `THREADLINE_TEST_SCOPE: toolchain` on the min and latest matrix rows only (absent on current). Tagged files are dropped from enumeration (same grep style as async detection); the exactly-once check compares against the filtered set; the step summary prints "N repo-contract files run on the current lane only". Local `mix test` and the current lane run everything; `test_helper.exs` exclude list does NOT change (`zero_skips_contract_test` allows exactly two gates: `pgbouncer_topology`, `live_dialyzer`) — add only a pointer comment. Docs: one sentence under CONTRIBUTING "## CI Coverage" + ci.yml comment; a contract test asserts the sentence, that the env var is on min/latest only, and that the script's filter matches the tag literal. Add `--self-test` case: tagged file absent from every partition under scope=toolchain, present exactly once under full scope, summary names the count.
  - Rejected: env-driven ExUnit exclude in `test_helper.exs` (weakens the anti-laundering guard; excluded files still load and the balancer carries dead weight).
  - Follow-on in scope: once Playwright-dependent tests (`playwright_fail_fast`, `browser_full_projects`, `e2e_preflight`) are tagged, drop the Playwright CLI install steps from min/latest, updating the ci.yml comment and any topology contract that pins them.
- **D-11: Weights from real CI timings.** A CI-only formatter (D-13) records per-file wall time (`module_started`→`module_finished`), summed `test.time`, partition boot time before the first module, and partition wall; writes a TSV per partition uploaded as an artifact on all lanes (SHA-pinned `upload-artifact`, satisfying `ci_action_pin_contract_test`). New mode `bin/ci-test-partitions --ingest-weights <dir>`: per-file median over the last 3 current-lane runs → rewrites `test/partition_weights.txt` in the unchanged `<ms> <file>` format (self-test (p) and the inventory contract keep working); prints files whose weight moved > 2×. Fit the async factor once by least squares from partition totals vs sync/async sums and record it as a constant with evidence, replacing the guessed 1/4. One weights file from current-lane timings; per-lane weights only if min/latest still miss 1.15 after refresh. Keep `--write-weights` as the offline fallback. Keep N=4 (4-vCPU runners; 225 D-03b). If a single file exceeds the even share (likely `stress_router_test.exs`, 47.5 s local, much more on CI), split it by module into two files (two `setup_all`, ~9 `defmodule`s). The weights-inventory contract must accept full-file weights while min/latest run a subset.
  - Rejected: a one-off serial refresh job in CI (> 10 min, still traced, goes stale); lowering N per lane.
- **D-12: Ratio measurement.** The script prints `max/min ratio` in its report table and emits `::warning::` above 1.15 — NOT a hard gate (~10% runner noise would flake). VERIFICATION records the ratio for 3 consecutive runs on each lane from the step summary. Parse the script's own table, never ExUnit summary lines (1.19 format change). Run `mix verify.flake` or 3 CI runs after reassignment before claiming the ratio (new partition mixes can expose order/shared-state coupling).

### CI-04: hung test fails fast and names itself
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


### Local-only gap diagnosis after the single off-main trace (2026-10-27)

The maintainer requested broad parallel primary-source research, adversarial synthesis,
a coherent recommendation set to follow automatically, small dependency trees, and
explicit lessons. This authorizes the bounded local work below; it grants no new CI run.

- **D-20: Separate timestamp semantics from historical causality.** Use a disposable dependency-free ExUnit canary on exact Elixir 1.15.8/OTP 26, copying the existing formatter unchanged. Hold its benign workload constant; vary only auxiliary async metadata around a controlled 2,000 ms load barrier. Follow the real async_run → parallel require → await_run order. Do not change async annotations on real tests. A demonstrated local boundary effect does not prove the old AMD64 CI delay's cause.
- **D-21: Replay frozen evidence once, without fitting.** Separate B3 source/training runs, four successful B4 descriptive holdout runs, two visible failed exclusions, and the off-main diagnostic. Resolve each historical classifier/weights/colocation from its exact source head. Report observed-cost components, weight error and residual separately; printed total-second ratios remain authoritative. Do not search coefficients, refresh weights, or choose a favorable cohort.
- **D-22: Fixed local budget and deterministic stop.** At most two warmups, three alternating pairs (A/B, B/A, A/B), and two timing-oracle controls; no replacement samples. Bound each child and the full canary; control invalidity/timeout is an explicit stop. Use event ordering as the main causal oracle and retain raw timings. One offline replay follows. Stop with a reviewed evidence/decision record; no unconditional optimizer, landing or new hosted cohort follows either outcome. Existing six-run B4 and one-run diagnostic caps stay exhausted.
  - **Pre-data implementation clarification (recorded before any ExUnit observation):** the first Docker launch exited 125 because the mount argument incorrectly contained `,rw`; no ExUnit event was collected. Preserve that raw preflight receipt. One launcher/stderr-capture repair and metadata-only version check are allowed before the first observed series. The series retains the same sample/deadline caps. Any later launcher failure or invalidity after ExUnit begins is a hard stop, with no replacement. This is not permission to relabel an observed failure as preflight.
- **D-23: Small dependency tree and scoped verification.** Add no package, profiler service or permanent CI gate for this one-shot diagnosis. Prefer small local code built from standard Elixir/OTP and Python/shell facilities; record provenance and hashes. Preserve N=4, full/toolchain inventories, colocation, watchdogs, named verification paths, 1.15 and 540-second acceptance, public API and source fixture fixes. Keep reliability fixes independently reviewable and diagnostic instrumentation off main.
- **D-24: Carry the lessons and uncertainty forward.** Record why call-site ordering did not prove callee ordering, why a changed assignment invalidates a causal A/B, why model fit is not measured balance, and why profiling-only exit 1 is not a failed test or a missing file. Cite exact-version primary sources. Keep local semantic validation, historical-cause confidence and main acceptance as separate verdicts; a no-signal result is not permission to enlarge the experiment.

### Min-lane gap closure (maintainer scope decision, 2026-10-27)

- **D-25: Lift D-22's hosted-cohort cap for one min-lane fix-and-measure cohort.** The maintainer approved this after verification showed both B4 failed exclusions were single-test failures on `Build and test (min)` (run 40452150109 partition 3 `test/threadline/operator_surface/live/row_history_live_test.exs:361`, `audit_changes_transaction_id_fkey`; run 40452833440 partition 1 `test/threadline/export/orchestrator_test.exs:239`), and CI-03 misses only on the min lane (1.24/1.28/1.27/1.25, current and latest pass). Scope: (a) root-cause and fix both min-lane failures in test/support code — no retries, skips, exclude tags, `@tag :flaky`, or loosened assertions; (b) re-derive `test/partition_weights_min.txt` (and colocation only if justified) from the already-persisted B4 min-lane timing artifacts so the predicted slowest/fastest ratio is ≤ 1.15, keeping N=4 partitions; (c) land on main via the standing self-merge grant; (d) one new main cohort of at most six runs measured with `bin/measure-main-ci`, needing five qualifying successes for CI-02's ≤ 540 s median and three runs per lane at ≤ 1.15 for CI-03. Thresholds 540 s and 1.15 are unchanged. The cohort is capped; a miss is recorded honestly, not re-sampled.
- **D-26: Drop the pinned ARM64 canary (CR-05) from phase acceptance.** It was a diagnostic side channel, not a CI-01..CI-04 truth; its consumed grant is not renewed. Record CR-05 as closed-by-descoping in the review disposition; no further canary runs or canary source changes.
- **D-27: Fix CI-03 on the current lane with a runtime tail queue in `bin/ci-test-partitions`, not a weight refresh.** The maintainer approved acting on the 2026-10-28 recommendation (evidence: `247-B6-REMEDY-RESEARCH.md`). Every static refresh rule replays at 1.12–1.28 leave-one-cohort-out, and the D-11 `deps_audit_gate` split targets the wrong partition, so neither is adopted. The design:
  - Compute today's greedy assignment unchanged.
  - Lift the K heaviest ungrouped `async: false` files out of the static sets. K is a pinned constant, 12, enforced by a self-test. Colocation groups stay static.
  - After its static set, each partition claims queued files largest-first under an atomic `mkdir` lock, and runs each with a separate `mix test <file>` invocation on the same partition DB.
  - Each partition's per-invocation TSVs merge into the existing `partition-timings-<i>.tsv` schema, so the CI-01 artifacts and `--ingest-weights` keep working.
  - Log a claim map (file → partition, start/end) to the job log and step summary, for flake triage.
  - The exactly-once check covers static plus claimed files.
  - One CI-04 watchdog deadline spans every invocation in a partition. The hang self-tests, and the `partition_monitor_test` `file:line` naming, must still pass when a queued file hangs.
  - All lanes; N=4 unchanged; no test-semantic changes. D-09 still applies: no skips, tags, retries or threshold changes.
- **D-28: Close R3-WR-01..04 in the same gap, as dispositioned in `247-B6-REMEDY-RESEARCH.md`.**
  - WR-04 puts the per-lane weight rule in `bin/`: `lane_rule()` gives current median, min max, latest median.
  - `--ingest-weights --rule`, with strict-mode mismatch exit 2, self-test cases, a `ci_topology_contract_test` mutant, and one CONTRIBUTING sentence.
  - A strict min ingest over the B4 training runs must byte-match the committed min weights. The R1 header stays verbatim.
  - The weight files themselves are not refreshed in this gap. The tail queue absorbs the drift. The min and latest weight files must stay byte-identical.
- **D-29: Authorize one fix-and-measure cohort (B6) under B5's rules.**
  - Same cap and rules as B5: at most 6 runs (the merge push plus guarded serial dispatches), stopping at 5 attempt-1 successes.
  - The first three decide CI-03 on all lanes. The median of five decides CI-02, re-measured at the same head.
  - Failed runs count against the cap and are excluded and root-caused, never re-run. Limits stay 540 s and 1.15.
  - Main is frozen during the cohort; halt if it moves.
  - Before any push, pre-register `247-B6-PREDICTION.md`: the K, the per-claim overhead assumption, and replay ratios per lane and cohort from a committed phase-local replay tool. The gate: worst replay ≤ 1.08 on every lane at 8 s per claim.
  - The landing PR's attempt-1 run is a go/no-go preflight, not a gate sample. Measured mean per-claim overhead ≤ 8 s, and every lane ratio ≤ 1.10. If it fails, stop before spending the cohort and escalate.
  - Land as one non-releasable `ci:` squash from `land/v1.47-ci03-tail-queue`, merged with `--match-head-commit`.
- **D-31: Tighten the B6 gate to protect CI-02.** Plan-check iteration 2 (2026-10-28) added these conditions before any replay or timing number existed. Each one only tightens when the cohort may run, never loosens it.
  - The D-29 pre-registration gate gains a second component: the predicted CI-02 median (B5 457 s, plus the median slowest-partition delta from the tail-queue replay, plus the measured self-test delta) must be ≤ 510 s.
  - Both components must hold, or the zero-spend stop path is taken.
  - Tail-queue self-test growth is capped. The median of 3 runs at the head may be at most 20 s above the origin/main median of 3, under both env bash and `/bin/bash`. If the cap can't be met after trimming, write an escalation with per-case seconds and stop.
- **D-32: Resolve the B6 gate FAIL with a current-lane-only tail queue (escalation option 2).** The maintainer approved this on 2026-10-28, resolving `247-B6-ESCALATION.md` (stage `prediction`, with 0 hosted runs spent).
  - Runner: the queue size becomes per lane. A `lane_tail_k()` function sits beside `lane_rule()`: current 12, min 0, latest 0. The `CI_TEST_PARTITIONS_TAIL_K` test seam still overrides it.
  - With K=0, min and latest must produce exactly the static assignment they had at origin/main (824c2851), byte-identical `partition-<i>.files`. Their B5-measured passing behaviour is the evidence for them.
  - Pin it the way `lane_rule` is pinned: self-test cases, a `ci_topology_contract_test` mutant, and docs.
  - Pre-register a second prediction file before any push, keeping the first one unchanged.
    - Disclose that the lane subset was chosen after seeing the per-lane replays.
    - Same tool, same rules P1–P10, re-run against the new runner. Gate (a): every current-lane run replays ≤ 1.08 at 8 s per claim, and the min and latest static replays are reported. Gate (b): the P10 predicted CI-02 median is ≤ 510 s.
    - Same preflight (P8): every lane must be ≤ 1.10. Claim-line checks apply only where K is above 0.
  - The cohort is the unspent B6 cohort, under the D-29 rules.
  - A gate FAIL, a preflight NO_GO, or a miss of CI-02 or CI-03 is final: fall back to escalation option 1. That means accepting the requirement as unmet-but-bounded, with a seed and a measured reopen trigger. There is no further remedy round.
- **D-33: Preflight thresholds per lane, for the D-32 round.** This amends D-32's "every lane ≤ 1.10" preflight. The orchestrator made the change on 2026-10-28, at plan-check, before any round-2 replay or hosted number existed.
  - The B5 static min lane, with an assignment that is byte-identical under K=0, already measured 1.11 in 2 of 5 runs. A ≤ 1.10 rule on one PR sample of an unchanged lane would turn noise into a final NO_GO.
  - For lanes with K = 0 (min, latest), the PR attempt-1 preflight requires a ratio ≤ 1.15, the CI-03 limit itself, as a disaster check. Their behaviour is already measured in B5.
  - For lanes with K > 0 (current), it still requires ≤ 1.10, plus the claim-line and overhead checks.
  - Acceptance is unchanged: the cohort decides CI-03 at ≤ 1.15 on every lane, from the first three runs, and CI-02 at ≤ 540 s.
  - The TQ-PREREG-2 rule block is updated to match before the second prediction is generated. The disclosure records this amendment.
  - **Amendment, same day, still before any round-2 number existed:** the K>0 (current) preflight ratio bound also becomes ≤ 1.15, the CI-03 limit, instead of 1.10. The current lane keeps its claim-line and pooled-overhead (≤ 8 s) mechanics checks.
    - Why: B5 measured current-lane ratios 0.064–0.119 above their queue replays. A preflight stricter than acceptance, on one sample, could end the round on noise. The preflight exists to catch broken mechanics or a lane already outside acceptance, not to act as a second, stricter acceptance test.
    - Every lane's P8 ratio bound is therefore ≤ 1.15.
  - **Ratification:** D-33 falls within the maintainer's 2026-10-28 instruction to "follow ur recs" (the option-2 approval). It changes only the go/no-go preflight, never acceptance. It is reported to the maintainer in the session handoff.
- **D-34: Measure the D-31 self-test cap with interleaved samples.** Orchestrator decision of 2026-10-28, under the maintainer's "follow ur recs" delegation.
  - Why: 247-34 halted at the cap because its baseline and HEAD series were taken at different times on a host with a load average of 12–23. Base samples spread over 28–40 s and HEAD over 45–60 s, and the tq-lane-k case itself costs about 0.8 s. With unpaired medians, host-load drift is mixed into the delta.
  - Measurement: under each bash, alternate runs base, HEAD, base, HEAD, base, HEAD. That gives 3 samples per side, keeping the existing self_test_seconds schema.
  - The cap rule is unchanged: HEAD median ≤ base median + 20 s, per bash. The halted series stay disclosed verbatim in 247-34-SUMMARY.md and 247-B6-LOCAL-2.md, and nothing is discarded silently.
  - The cap is an internal guard. CI-02 stays protected by the P10 ≤ 510 s gate (fed by the interleaved delta) and is decided only by the B6 cohort.
  - If the interleaved series still fails, halt and escalate to the maintainer. Do not trim further.
- **D-30: B6 is final for phase 247.** If CI-03 misses, record it honestly. There is no B7 and no re-sampling of an unchanged head. Escalate one maintainer scope decision: accept CI-03 as unmet-but-bounded, with a measured-trigger seed, or something else.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/REQUIREMENTS.md` — CI-01..CI-04
- `.planning/ROADMAP.md` §"Phase 247: CI critical path and suite lanes" — goal, success criteria, ordering note
- `.planning/seeds/SEED-006-ci-feedback-loop-cost-and-latency.md` — `reopen_when` to rewrite with the measured median (D-08)
- `.planning/seeds/SEED-007-release-pr-refresh-and-browser-critical-path.md` — browser critical-path measurement history
- `.planning/phases/222-seed-006-change-aware-lanes-conditional/222-DECISION.md` — SEED-006 close and measurement tooling precedent
- `.planning/phases/246-debt-closeout-and-critic-retirement/246-CONTEXT.md` — D-12 (critic removal as its own `chore:` squash), D-13 (tag push = maintainer grant), D-14
- `.planning/PROJECT.md` — Constraints, incl. "Zero human verification by default"
- `.planning/MILESTONE-GUIDE.txt`, `.planning/MILESTONE-ARC.md` — milestone quality/CI/release bar

### CI topology and contracts
- `.github/workflows/ci.yml` — `verify-test` matrix (~613–860), `verify-example-browser` (~860–1040), `ci-required` (~1049)
- `.github/workflows/browser-full.yml`, `bin/browser-full-projects` — non-required browser projects
- `bin/ci-test-partitions` — partition runner, `--self-test`, `--write-weights`, `PARTITION_TEST_TIMEOUT_MS`
- `test/partition_weights.txt`, `test/partition_colocate.txt`
- `test/threadline/ci_workflow_parity_contract_test.exs` — `@ci_check_names` (~1367), `@verify_test_check_names`, `@retired_check_names`, browser-full parity (~1115)
- `test/threadline/ci_topology_contract_test.exs`, `test/threadline/ci_coverage_doc_contract_test.exs`
- `test/threadline/browser_journey_evidence_contract_test.exs` (~135–175)
- `test/threadline/zero_skips_contract_test.exs` — exactly two allowed default excludes
- `test/test_helper.exs`, `CONTRIBUTING.md` §"## CI Coverage"
- `examples/threadline_phoenix/e2e/playwright.config.ts`, `e2e/support/operator-ci-evidence.ts`, `e2e/support/operator-journey-inventory.json`, `operator-ci-evidence.test.ts`

### House conventions
- `prompts/threadline-elixir-oss-dna.md` — named entrypoints, honest default tests, stable job ids
- `prompts/prior-art/` — CI/CD patterns research
- `CLAUDE.md` — CI & verification conventions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `operator-ci-evidence.ts` + its `tsx` test harness — template for `slow-specs.ts` and for N-file receipt merging.
- `bin/ci-test-partitions` fake-mix `--self-test` harness — extend with scope, hang, and hang_ignore_term cases.
- `re-actors/alls-green` aggregate with `allowed-skips` extension point — fan-in job joins `needs:`.
- `bin/observe-main-ci` — base for the read-only measurement script.
- `bin/retry-network`, SHA-pinned `upload-artifact`/`cache` actions already in ci.yml.

### Established Patterns
- Matrix on one immutable job id with a composed check-name suffix (`verify-test`, 221 D-04).
- Step timeout strictly below job timeout so the failure-artifact upload survives (browser job comment).
- Deterministic greedy longest-first partitioning with an exactly-once file-set check; colocation groups.
- Summary output: counts and numbers only, never raw log text.

### Integration Points
- `ci-required.needs` (+ `allowed-skips` must stay empty).
- CONTRIBUTING "CI Coverage" doc contract; check-name contracts; action-pin contract.
- Elixir 1.15 (min lane) compatibility for anything in `test/support`.

</code_context>

<specifics>
## Specific Ideas

- Projected after split: ~377 s Playwright + ~75 s setup per leg ≈ 7.5 min/leg, ≈ 7.7 min run wall if balanced; 60/40 imbalance ≈ 8.7 min (passes barely), 65/35 ≈ 9.4 min (misses) — hence CI-01 before the split.
- 64 skipped tests are likely unevenly spread between projects, so test counts understate imbalance.
- Moving repo-contract files to current-only projects ~19% less load on min/latest.
- The PR #89 hang occurred only on the min lane (OTP 26 / Elixir 1.15); watch per-lane recurrence in the flake detector before blaming code.

</specifics>

<deferred>
## Deferred Ideas

- Raising Playwright `workers` above 1 (needs per-worker DB/tenant isolation + flake run).
- Rebalancing current-only steps across lanes.
- Path-aware / change-aware lanes — SEED-006 stays closed unless its measured trigger fires.
- `Mix.shell().cmd` not forwarding cancel signals to child scripts — a possible future requirement line (mitigated here by the script's own watchdog).

</deferred>

---

*Phase: 247-ci-critical-path-and-suite-lanes*
*Context gathered: 2026-10-26*
