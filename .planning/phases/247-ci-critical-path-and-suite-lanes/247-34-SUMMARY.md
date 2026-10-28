---
phase: 247-ci-critical-path-and-suite-lanes
plan: 34
subsystem: ci-partitioning
status: complete
tags: [ci, tail-queue, lane_tail_k, D-32, D-31, D-34, CI-03, CI-04, self-test-cap]
requires:
  - phase: 247-32
    provides: "B6 gate FAIL and 247-B6-ESCALATION.md; maintainer chose option 2 (D-32)"
provides:
  - "bin/ci-test-partitions lane_tail_k() (current TAIL_QUEUE_K=12, min 0, latest 0), the default of the CI_TEST_PARTITIONS_TAIL_K seam, and the tq-lane-k self-test (8caf2295, trimmed in 462a6063); runner_sha256 2d420a97..449b"
  - "ci_topology_contract_test: lane_tail_k_errors/1 + the lane_tail_k test with a min -> $TAIL_QUEUE_K mutant caught textually and in the sandbox; doc-parity extension (99f0a595); tq-lane-k ok-token pin with a mutant (4f872f5e)"
  - "CONTRIBUTING: only the current lane queues; the min and latest lanes queue none (lane_tail_k)"
  - "247-B6-LOCAL-2.md (threadline.phase247-b6-local/2) at 4f872f5e, with self_test_seconds by the D-34 interleaved method: env 30 -> 45, /bin/bash 30 -> 47 (cap +20). Both halted series disclosed verbatim."
  - "247-B6-ESCALATION.md: append-only '## Resolution — D-32 (append-only)' + B6-ESCALATION-RESOLUTION-JSON"
affects: ["247-35 (P10 reads self_test_seconds from 247-B6-LOCAL-2.md)", "247-36 (lands this non-planning tree, 4f872f5e)", "247-37"]
actuals:
  tokens: 17253
  tasks: 3
  commits: 7
plan_head_before: 7d555e68db4e12cd52fc8ff90a4e92c9859f964a
plan_head_after: 1ea452e7f0c3570daf1ed6e717ec9ca5debac352
tech-stack:
  added: []
  patterns:
    - "Per-lane map pinned three ways, like lane_rule: a self-test case, a contract rule reading only the production function body plus a mutant, and a doc-parity rule"
    - "Interleaved paired timing (D-34): base, head, base, head, base, head per bash, so host-load drift falls on both sides"
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-B6-LOCAL-2.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-34-SUMMARY.md
  modified:
    - bin/ci-test-partitions
    - test/threadline/ci_topology_contract_test.exs
    - CONTRIBUTING.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-B6-ESCALATION.md
    - .planning/STATE.md
    - .planning/ROADMAP.md
decisions:
  - "247-34 first halted at the D-31 self-test cap after the I5 trim (/bin/bash 59 vs 33 + 20, non-interleaved). The orchestrator's D-34 (a48c23ab) resolved it by changing the measurement to interleaved samples, with the cap rule unchanged. The interleaved series passed: env 30 -> 45, /bin/bash 30 -> 47."
  - "I5 trim (462a6063): tq-lane-k's current case reuses the tq-k-pin lift, and min's seam-0 comparison uses one lift (min's assignment.tsv equals tq-k-pin's, and each static set equals that assignment's rows). Five lifts became three. Every assertion and the ok token stay."
  - "The tq-lane-k ok-line token is now contract-pinned inside ci_topology_contract_test.exs (Task 2 file scope), so it is not left as a deferred item."
metrics:
  duration: "~81 min of executor time (19:42-20:33Z, then 20:37-21:03Z after D-34)"
  started: 2026-10-28T19:42:23Z
  completed: 2026-10-28T21:03:03Z
---

# Phase 247 Plan 34: per-lane tail-queue K (D-32) Summary

**`lane_tail_k()` now gives current 12, and min and latest 0. Under both bashes, min and latest reproduce origin/main 824c2851's static sets byte for byte, and current still queues the same 12 files over an unchanged greedy assignment. A self-test case, a contract mutant, an ok-token pin and a doc-parity rule pin it.**

The plan halted once at the D-31 self-test cap. The orchestrator's D-34 changed only how the cap is measured, to interleaved paired samples with the rule unchanged. Under D-34 the cap passes: env 30 → 45 and /bin/bash 30 → 47, against +20. The final runner is proven locally on all three lanes, plus a queued hang. That proof is in 247-B6-LOCAL-2.md, and the D-32 resolution is appended to 247-B6-ESCALATION.md.

## Outcome

| Item | Result |
|---|---|
| Task 1 (tracer): `lane_tail_k`, seam default, `tq-lane-k`, header docs | Done, 8caf2295 (trim 462a6063). The verify passed under env bash and /bin/bash, both before and after the trim. |
| Task 2: contract rule + mutant, CONTRIBUTING, doc parity | Done, 99f0a595, plus the ok-token pin 4f872f5e. Format and credo are clean, and the five listed files ran 114 tests / 0 failures (twice). |
| Task 3: local proof, D-31 cap, records | Done after D-34, 1ea452e7. The Task 3 verify passes unmodified: `B6 local-2: PASS`. |
| D-31 cap by the D-34 method | **PASS.** env 45 ≤ 30 + 20, /bin/bash 47 ≤ 30 + 20. |
| Replan trigger (I3) | Not tripped. Outside `.planning/`, only `bin/ci-test-partitions`, `test/threadline/ci_topology_contract_test.exs` and `CONTRIBUTING.md` changed, and no `async:` flag changed. |
| Round-1 records | 247-B6-PREDICTION.md is byte-identical (sha256 33fbbc3f…cefe09). 247-B6-LOCAL.md and 247-33-PLAN.md are unchanged. 247-B6-ESCALATION.md's 0c5903ab bytes are an exact prefix of the file. |

## Resolution: D-34 interleaved re-measure and final proof

**D-34 (orchestrator, a48c23ab, under the maintainer's "follow ur recs" delegation).** Under each bash, the runs alternate base, HEAD, base, HEAD, base, HEAD. The cap rule is unchanged. No further trim was made. The series was measured at the final runner: `462a6063`, which is byte-identical to `4f872f5e`'s runner.

| Variant | Load (start → end) | Base samples | Base median | HEAD samples | HEAD median | Cap | Verdict |
|---|---|---|---|---|---|---|---|
| env | 10.65 → 9.03 | 29, 31, 30 | 30 | 45, 52, 44 | 45 | 50 | **pass (+15)** |
| /bin/bash | 8.25 → 12.98 | 32, 28, 30 | 30 | 47, 52, 45 | 47 | 50 | **pass (+17)** |

**Final local proof**, at `4f872f5e`, which is the non-planning tree Plan 36 lands. It ran on an ephemeral postgres:16 (16.14) and was recorded in 247-B6-LOCAL-2.md:

- **Whole suite.** `mix test`: 32 properties, 3388 tests, 0 failures, 3 excluded, exit 0.
- **Lane runs.** Ratios and overheads are host-local and informational.

| Lane | Scope | Exit | Tests (Σ partitions) | Failures | max/min | K | Queued | Claimed | Claim lines | overhead_mean_ms |
|---|---|---|---|---|---|---|---|---|---|---|
| current | (all) | 0 | 3388 | 0 | 1.23 | 12 | 12 | 12 | 12 | 2867 |
| min | toolchain | 0 | 2568 | 0 | 1.32 | 0 | 0 | 0 | 0 | n/a |
| latest | toolchain | 0 | 2568 | 0 | 1.26 | 0 | 0 | 0 | 0 | n/a |

- **Queued hang.** Exit 1 in 65 s. Claim invocation `p1-1` names `test/zz_queued_hang_test.exs:4` with the `Process.sleep/1` frame. The claim line shows exit=1, the monitor deadline was 60000 ms, and no BEAM was left.
- **Static identity.** Min and latest `partition-1..4.files` are byte-identical to 824c2851's, and current's `assignment.tsv` is identical with 12 queued. This is the Task 1 verify under both bashes.

**Two points for reviewers:**
1. **The trim changed how the min seam-0 check works.** Before the trim, `tq-lane-k` ran min twice, seam unset and seam 0, and compared the outputs. After it, `tq-lane-k` makes one min lift. It asserts that the lift's `assignment.tsv` equals `tq-k-pin`'s, which holds because the sandbox lane weights are copies. It then asserts that each `partition-<i>.files` equals that assignment's rows for partition i, which is what seam 0 writes by construction. The runner's real seam-0 path is still exercised by `tq-empty`'s K=0 case and by the Task 1 verify against 824c2851. A red-capable control (a `run_partitions` that ignores `lane_tail_k`) still fails the trimmed case.
2. **The `tq-lane-k` ok-line token is now pinned.** `tq_lane_k_ok_token?/1` in `ci_topology_contract_test.exs` requires `tq-lane-k` on the runner's `--self-test` ok line. A mutant that removes the token is caught (4f872f5e). It lives inside the Task 2 file scope and touches no other file, so it is not a deferred item.

## Escalation: self-test time cap

D-31 cap: the HEAD median of 3 must be ≤ the baseline median of 3 + 20 s, under each bash. The baseline is a `git archive` of origin/main `824c2851` and the HEAD a `git archive` of the runner under test. Each round ran base-env, head-env, base-/bin/bash and head-/bin/bash, interleaved and timed with `date +%s`. Every run printed `self-test: ok`. Env bash is 5.2.37 and `/bin/bash` is 3.2.57. The host is shared, with load averages of about 12–23 during the timings.

**Series 1, at 8caf2295 (before the trim).** The cap failed on env.

| Variant | Baseline samples | Baseline median | HEAD samples | HEAD median | Cap | Verdict |
|---|---|---|---|---|---|---|
| env | 31, 29, 37 | 31 | 46, 54, 59 | 54 | 51 | FAIL (+23) |
| /bin/bash | 30, 38, 33 | 33 | 47, 60, 45 | 47 | 53 | pass (+14) |

**I5 trim (462a6063).** `tq-lane-k` went from five `MIX_BIN=false` lifts to three:
- Its current-lane case reuses the `tq-k-pin` lift, because lane '' is current.
- Min's seam-0 comparison uses a single lift. That lift's `assignment.tsv` must equal `tq-k-pin`'s, because the sandbox lane weights are copies. Each of its `partition-<i>.files` must equal that assignment's rows for partition i, which is by construction what seam 0 writes.

Every assertion and the `tq-lane-k` ok token stayed. Both bashes passed, and so did the Task 1 verify. A red-capable control showed that a runner whose `run_partitions` ignores `lane_tail_k` fails `tq-lane-k` ("min must queue nothing with the seam unset"). Before the trim, a control showed that a `min → $TAIL_QUEUE_K` arm fails the direct-map assertion.

**Series 2, at 462a6063 (after the trim, re-measured from the beginning).** The cap failed on /bin/bash, so the plan halts here (D-31).

| Variant | Baseline samples | Baseline median | HEAD samples | HEAD median | Cap | Verdict |
|---|---|---|---|---|---|---|
| env | 34, 36, 38 | 36 | 59, 53, 52 | 53 | 56 | pass (+17) |
| /bin/bash | 40, 33, 28 | 33 | 60, 50, 59 | 59 | 53 | **FAIL (+26)** |

**Per-case evidence.** One extra timestamped `/bin/bash --self-test` per side at 462a6063, load about 20. The times are seconds between successive `: ok` lines.

| Section (ending at the ok line) | Base 824c2851 | HEAD 462a6063 |
|---|---|---|
| … `async-duration-floor` | 4.2 | 4.9 |
| … `lane-min-routing` | 28.9 | 26.9 |
| … `lane-all-routing` | 2.2 | 2.6 |
| … `lane-assignment-mutation` | 0.5 | 0.7 |
| … `lane-ingest-integrity` | 4.6 | 5.4 |
| … `lane-rule` (Plan 29) | — | 2.5 |
| … `tail-queue-lift` (Plan 30: tq-basic…tq-k-pin) | — | 2.2 |
| … `tail-queue-scope` (Plan 30: tq-order, tq-empty, tq-scope) | — | 2.3 |
| … **`tail-queue-lane-k` (this plan, after the trim)** | — | **0.8** |
| … final ok line (Plan 30: tq-fail…tq-hang) | 0.0 | 10.6 |
| Total | 40.4 | 58.9 |

**Reading.**
- This plan's own case costs about 0.8 s.
- The HEAD-over-base excess (about 18 s in this run) comes almost entirely from cases Plans 29–30 added. Plan 30 measured them at +14/+15 and Plan 31 at +15/+13, against the same +20 cap.
- On this loaded host the HEAD samples spread over 45–60 s within one series. That spread is as wide as the cap's remaining margin, so the cap verdict here mostly depends on host load, not on this change.
- The plan is explicit, though: if the cap is still exceeded after the trim, stop. So the plan stops here, and nothing was re-run to get a passing sample.

**What a decision has to choose (not decided here).** These are not ranked, and none of them is a D-32 fallback:
- (a) Re-measure the cap on a quiet host or an isolated runner, keeping the same rule.
- (b) Trim further inside the pre-existing Plan 30 tail-queue cases, since about 10.6 s sits in tq-fail…tq-hang. That changes cases outside this plan's scope.
- (c) Record a maintainer-ratified change to how D-31 is measured, for example a quiet-host requirement or more samples.

247-35's P10 reads `self_test_seconds` from `247-B6-LOCAL-2.md`, so 247-35 cannot run until this is resolved and 247-34 Task 3 completes.

## History: local proof gathered before the halt (at 99f0a595, superseded by the runs at 4f872f5e above)

These runs used HEAD 99f0a595, with Tasks 1–2 and runner sha256 at the pre-trim body. They ran on an ephemeral `postgres:16` (16.14), labelled `dev.threadline.plan=247-34`, on a loopback ephemeral port, with `DB_HOST=127.0.0.1 DB_PORT=<port>` on every mix command. The toolchain was Elixir 1.17.3-otp-27 on OTP 27.3.4.15. The trim at 462a6063 changed only the `--self-test` body; `run_partitions` and every production path are byte-identical between the two commits. They are still not a record at the final runner. If Task 3 resumes, these runs must be repeated at whichever runner it records.

- **Whole suite.** `mix test`: 32 properties, 3388 tests, 0 failures, 3 excluded, exit 0, in 277 s. The total is one more than 247-B6-LOCAL's 3387 because of the new contract test.
- **Lane runs.** Values come from the runner's own report table and `tail queue K=` line. Ratios and overheads are host-local and informational.

| Lane | Scope | Exit | Tests (Σ partitions) | Failures | max/min | K | Queued | Claimed | Claim lines | overhead_mean_ms |
|---|---|---|---|---|---|---|---|---|---|---|
| current | (all) | 0 | 3388 | 0 | 1.17 | 12 | 12 | 12 | 12 | 1225 |
| min | toolchain | 0 | 2568 | 0 | 1.35 | 0 | 0 | 0 | 0 | n/a |
| latest | toolchain | 0 | 2568 | 0 | 1.28 | 0 | 0 | 0 | 0 | n/a |

  - The current total equals the whole suite.
  - The min and latest totals are equal, with 63 repo-contract files left out by design.
  - Min and latest printed `tail queue: 0 files lifted (K=0), weight 0 ms`, and their reports have no `Tail queue (K=…)` table.
- **Queued-hang proof (CI-04).**
  - Setup: a `git archive HEAD` scratch copy with `deps/` and `_build/` copied in, not linked. It kept three light sync files (`application_test`, `mix/migrations_path_test`, `storage_schema_test`) and added `test/zz_queued_hang_test.exs`, whose line-4 test body is `Process.sleep(:infinity)`. The colocate file was empty and the hang file weighed 999999. The run was `CI_TEST_PARTITIONS_BUDGET_S=90 bin/ci-test-partitions 4` with real mix, lane '' (K=12) and a 200 s alarm.
  - Result: exit 1 in 63 s.
  - Partition 1 claimed seq 1 as invocation `p1-1`. Its log has `----- HANG: in-flight: (deadline 60000 ms, VM wall 60001 ms) -----`, then `test/zz_queued_hang_test.exs:4 test hangs in the body of a queued file`, then the frame `(elixir 1.17.3) lib/process.ex:303: Process.sleep/1`, then `----- HANG: end -----`.
  - Stdout has `claim partition=1 seq=1 file=test/zz_queued_hang_test.exs … exit=1`, and the other three claims exited 0.
  - `pgrep -f <scratch path>` was empty, and the copy was removed. The fixture never existed under the repository's `test/`.
- **Static identity vs 824c2851.** This is the Task 1 verify, run under both bashes at 8caf2295 and again at 462a6063. Min and latest `partition-1..4.files` are byte-identical to 824c2851's, queue nothing and print the K=0 lift line. Current's `assignment.tsv` is byte-identical, with 12 queued.

## Tasks

| Task | Commit(s) | Result |
|---|---|---|
| 1 (tracer) | 8caf2295, trim 462a6063 | `lane_tail_k` sits after `lane_rule`, with the four arms verbatim. `run_partitions` computes `lane_k` (separate `local`, then the assignment) and uses it as both `count_env CI_TEST_PARTITIONS_TAIL_K` defaults. The `TAIL_QUEUE_K` comment cites 247-B6-PREDICTION.md (≤ 1.064 on current; min 1.101, latest 1.107), and the stale every-lane claim is gone. The header, Seams list and self-test letter list describe the per-lane K. The `tq-lane-k` case and ok token are in place. Tracer gate: the verify re-ran end to end and passed. |
| 2 | 99f0a595, 4f872f5e | `lane_tail_k_errors/1` reads only the production body via `~r/^lane_tail_k\(\) \{\n(.*?)^\}/ms` and checks the seam default. `tail_queue_sandbox!` takes an optional `lane` and writes min/latest weight copies. The new test covers: current queues the 12 expected rows; min and latest queue `[]`; the `min → "$TAIL_QUEUE_K"` mutant gives `["wrong tail K for lane min"]` and queues 12 in the sandbox. Doc parity requires `lane_tail_k` and `min and latest lanes queue none`, plus `lane_tail_k_errors(script) == []`, with two new mutants. The K=4, K=13 and "the 13 heaviest" mutants are kept. In CONTRIBUTING, "On the current lane, after the weighted split, the 12 heaviest …" is followed by "The min and latest lanes queue none (`lane_tail_k` in `bin/ci-test-partitions`), so they run the static weighted split unchanged." 4f872f5e adds `tq_lane_k_ok_token?/1` with a mutant. |
| 3 | 1ea452e7 | It first halted at step 4 (D-31, see the escalation above). After D-34: interleaved cap PASS, then the whole suite, current, min, latest and the queued hang were re-run at 4f872f5e. 247-B6-LOCAL-2.md was written, with both halted series disclosed verbatim and D-34 cited as the method. The D-32 resolution was appended to 247-B6-ESCALATION.md. The Task 3 verify passes as written. |

## Deviations from Plan

### Auto-fixed Issues

None.

### Plan-prescribed branches taken

**1. [I5 trim] Folded `tq-lane-k` lifts (462a6063).** The first cap series failed on env, so the plan's I5 trim was applied as prescribed and committed separately as `ci(247-34): trim tq-lane-k lifts for the self-test cap`. The Task 1 verify was re-run (pass), and all three rounds were re-measured from the beginning. One point of interpretation: "the min seam-0 comparison reuses one lift instead of two" was implemented by comparing the single min lift against its own greedy assignment rows, after checking that the assignment equals `tq-k-pin`'s. A second runner pass at seam 0 is no longer made. Seam 0 writes exactly those rows (verified by the Task 1 verify against 824c2851, and by `tq-empty`'s K=0 case).

**2. [D-31 halt, then D-34] Stopped before the record, then resumed.** The cap still failed after the trim, so the plan halted and escalated (9b195cc0). The orchestrator's D-34 (a48c23ab) changed only the measurement, to interleaved samples. The re-measure passed, and Task 3 then finished at the final runner.

**3. [Rule 2 - Correctness] Pinned the `tq-lane-k` ok token (4f872f5e).** The self-test's ok line had no contract rule, so dropping the case's token would have gone unnoticed by the Elixir suite. A one-helper assertion plus a mutant was added inside the Task 2 file. The assignment is unaffected: no weights, no `async:` flags.

## Known Stubs

None.

## Threat Flags

None. No new network, auth or file-access surface. T-247-89 (self-test cost on CI-02) is the mitigation that fired: the halt is that mitigation working.

## Self-Check: PASSED

- FOUND: bin/ci-test-partitions (contains `lane_tail_k() {`), test/threadline/ci_topology_contract_test.exs (contains `defp lane_tail_k_errors` and `tq_lane_k_ok_token?`), CONTRIBUTING.md (contains "min and latest lanes queue none"), 247-B6-LOCAL-2.md (one B6-LOCAL-2-JSON block), 247-B6-ESCALATION.md (B6-ESCALATION-RESOLUTION-JSON block)
- FOUND commits: 8caf2295, 99f0a595, 462a6063, 9b195cc0, 4f872f5e, 1ea452e7 (ancestors of HEAD). a48c23ab in the measured range is the orchestrator's D-34 commit.
- The Task 1, Task 2 and Task 3 verifies all pass. No labelled container is left, there are no scratch fixtures under `test/`, and repo hygiene is green.
