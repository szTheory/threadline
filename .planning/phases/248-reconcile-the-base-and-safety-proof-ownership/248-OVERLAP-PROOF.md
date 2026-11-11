# Phase 248: Formatter overlap fixture correction

## Current diagnostic outcome and narrow correction — 2026-11-11

Plan 248-04 remains halted and ADM-04 incomplete. The approved instrumented nine-run alias failed its first suite on `8bdb4ac0`: 32 properties, 3,400 tests, one formatter timeout, three exclusions; 727.45 seconds wall, suite exit 2 / capture 0 / wrapper 1, classifier `broken`. No later suites ran. The one-invocation grant is consumed. [Exact diagnostic receipt](248-INSTRUMENTED-DIAGNOSTIC-RECEIPT.json).

Current source `ce0c2e30d0b7401b3b35df21dcd986ad9ed8cafb` changes only the synthetic overlap input to the exact existing representative, preserving production formatter configs/globs, all 12 representatives, exact overlap/uncovered assertions, async settings and timeouts. A post-run check showed the old recursive fixture glob returned 107 files, including 97 under dependencies/build output, while the literal returned the one required representative. This is scope evidence, not a latency or exclusive-cause claim. Focused test, format and strict Credo pass; two private control mutants fail as intended; independent 33-file recheck has no active findings (32 exact reads reused, one changed file fully read). [Correction and bounded proof](248-OVERLAP-PROOF.md), [review](248-OVERLAP-REVIEW.md).

No current full-root or plain nine-run pass is claimed. During the timeout, sampled file-server counters kept advancing with changing operations and queued requests; the observer had material variable overhead, so no single continuous stall, sole cause or reliable speedup is established. PostgreSQL is stopped after zero clients; shared services untouched. The next concrete decision is one plain acceptance invocation with the same nine-run / scale 5 / max-cases 36 / 55-minute plus 60-second limits; authorization is false. [Current readiness](248-OVERLAP-READINESS.md). Formal post-gates, acceptance and phases 249–253 remain pending; no external authority inferred.

## Preserved behavior and source scope

The sole code change is in `test/threadline/formatter_topology_contract_test.exs`: synthetic `bench/**/*.exs` becomes `bench/audit_capture_bench.exs`, with a brief purpose comment. Both are valid formatter inputs. The changed in-memory root owner still passes through the existing `Path.wildcard/2` helper and must claim the same already-owned representative. The original five formatter configs and their 12 production patterns, baseline one-owner check, exact two-owner overlap result, exact uncovered result and all suite settings remain unchanged. No cache, dependency, product/API or test exclusion change was added.

## Current automated evidence

| Check | Result and limit |
| --- | --- |
| Existing focused check | `mix verify.test test/threadline/formatter_topology_contract_test.exs --seed 584294 --max-cases 36`, `MIX_ENV=test`, scale 5: exit 0, one test, 0 failures, 1.067 s wall. Working-tree content committed unchanged at current source. |
| Format and lint | Changed-file format, `mix verify.format` and `mix verify.credo`: all exit 0; strict Credo reported no issues. |
| Private overlap mutant | Misdirect only the synthetic literal; the exact overlap assertion fails as expected (one test / one failure, exit 2). Actual tracked source unchanged. |
| Private uncovered mutant | Restore the removed bench input; the exact uncovered assertion fails as expected (one test / one failure, exit 2). Actual tracked source unchanged. |
| Independent code recheck | All 33 source hashes match; 32 exact prior reads reused, formatter test fully read; no active findings. Historical guide and tagged-fixture corrections remain resolved in unchanged source. |
| Protected identities | 22 identities bound to the current proposal; only the declared formatter test differs from the diagnostic source. Runtime, router, script, locks, browser inventory and package identities unchanged. |

The private mutants ran as standalone ExUnit copies rooted at the real formatter configs, with one mutation each. They used no database or `test_helper`, and are expected failures, not failures of current tracked source. These control checks do not become full-root or repeated-suite proof.

## Diagnostic interpretation

[Diagnostic analysis](248-DIAGNOSTIC-ANALYSIS.md) distinguishes observed pressure from inferred cause. In the 60.75-second failed-test event window, 184 samples all had different increasing file-server reduction values (429,209 total progress), with changing functions. Queue p50 was 17, p95 30 and maximum 34; scheduler run queue peaked at 126. Maximum sample cost was 4.686 seconds and the longest sample interval 5.781 seconds. Thus this was an irregular sampled view, not per-request latency or a complete trace. The failed test's reported `duration_us: 0` is not its elapsed duration; ExUnit's timeout and event window are authoritative.

After the run and PostgreSQL shutdown, one read-only external-VM comparison found the recursive synthetic pattern matched 107 files: 70 under `deps`, 27 under `_build`, ten elsewhere. The literal matched the single representative. Its one-off 84.625 ms versus 0.946 ms timings are order/cache biased and are not used as speedup or timeout-fix proof. The 106 irrelevant returned matches are the basis for the local correction.

## Source-bound evidence identities

- Current formatter source SHA-256: `ce45d84c0645e1e510130a3656d48af1ed3ade04db297f0bbda885016cb9e07d`.
- Focused log SHA-256: `781e30406d15347f7fa70c67f686c045501d7cad3e98e1c5bbb54c7dd51ea8c2`.
- Strict Credo log SHA-256: `ab42ee298d039b2aeee97c2e6ff030db9b00629bdd70ffc3efc3278b88e3a3f5`.
- Overlap-mutant log SHA-256: `638e7bd33d3b17d1dada3e9250285f973a7bd0feed1f86cafe24866143e079a4`.
- Uncovered-mutant log SHA-256: `db3c3c39741840e832aa1b2142a453274e62fe860fb8ec0c9ebc6e5c246a3ea8`.

Raw logs and machine paths stay private. Earlier failed repeats and the intermediate tagged-fixture regression remain preserved; no old run is relabeled. The producer's private `not_a_full_repeat` field means nine suites did not complete: the actual diagnostic command was the existing nine-run alias, stopped by its first failure.
