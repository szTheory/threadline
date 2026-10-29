# Phase 247 Local Evidence Tool Fix Summary

## Fixes

- **CR-01:** Event timestamps now accept signed decimal integers. Pure fixtures cover a negative monotonic value, zero, a positive value, and malformed input.
- **CR-02:** The runner stops tracing, waits for Erlang's `trace_delivered(:all)` acknowledgment, requests a bounded collector flush, emits its retained registration records, and waits for a bounded stop acknowledgment. The existing `:set_on_spawn` flag remains enabled so spawned compiler workers inherit tracing; the deterministic delayed-message self-test checks a spawned child, delivery acknowledgment, collector flush, and stop without starting ExUnit.
- **CR-03:** Every selected TSV is compared with an expected digest before parsing. Diagnostic payloads are checked against the diagnostic evidence's per-partition `timing_sha256` and the saved replay. B4 archive metadata must identify the exact run, head, lane artifact name, and archive digest. The original replay receipt is SHA-pinned as saved historical digest evidence and cannot be overwritten by `--run`.
- **WR-02:** Captured child stdout/stderr remain separate from `parse_error`; a pure helper fixture checks that a parser exception retains the child's stderr.
- **WR-03:** Verification resolves producer, runner, and formatter bytes from the receipt's historical Git commits. It verifies the producer path, producer commit/source-head binding, and producer SHA-256; the mutation fixtures alter producer hash and commit.

## Follow-up Repair: CR-04

The collector now requests Erlang `:strict_monotonic_timestamp`, stores the monotonic nanosecond value embedded in each `:trace_ts` registration message, and formats that captured occurrence time as milliseconds. Immediately after `Kernel.ParallelCompiler.require/2` returns, the runner waits for trace delivery and collector flush, emits those timestamped events, and only then records `require_return`. The suite-end flush handles any later records with their original trace timestamps. The trace-only self-test delays collector processing and asserts the captured timestamp precedes its synthetic `require_return` boundary. The trace flag and tuple semantics follow the [official Erlang/OTP 26 `erlang` documentation](https://www.erlang.org/docs/26/man/erlang.html).

The unused `mode = Enum.at(args, 1)` assignment was removed. The raw canary receipt was not regenerated and remains `INVALID`.

### Follow-up Check

```text
elixir .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs --trace-self-test
PASS: trace plumbing self-test: PASS (captured occurrence timestamp precedes require_return)
Scope: deterministic trace-only fixture; no ExUnit process was started.
```

## Evidence Limit

The canonical B3/B4 measurement JSONs do not contain per-TSV digests. The B4 metadata contains the upstream archive digest and run/head/name identity, but the archive files needed to independently verify each extracted member are absent. B3 has no saved upstream artifact metadata. Therefore B3/B4 member checks use the digest list in the untouched, SHA-pinned historical replay receipt. This detects later cache substitution and preserves the original observed bytes, but it does **not** prove upstream archive/member authenticity. Diagnostic per-partition hashes are checked directly against the diagnostic manifest. No upstream authenticity is inferred for B3/B4.

The saved canary remains `INVALID`; the original replay JSON remains unchanged. Existing WR-01 disposition and its exact title are preserved in `247-REVIEW-DISPOSITION.md`.

## Commands and Results

All commands ran from the source-authority `quality-baseline` worktree root.

```text
python3 -B - <<'PY'
import ast, pathlib
for p in [pathlib.Path('.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py'), pathlib.Path('.planning/phases/247-ci-critical-path-and-suite-lanes/tools/replay_frozen_evidence.py')]:
 ast.parse(p.read_text()); print('syntax: PASS', p)
PY
PASS: syntax parsed for exunit_boundary_probe.py and replay_frozen_evidence.py

elixir .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs --trace-self-test
PASS: trace plumbing self-test: PASS
Scope: deterministic trace inheritance/collector protocol only; no ExUnit process was started.

python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py --self-test
PASS: signed clocks, stderr/parser split, producer mutation, synthetic oracle, INVALID accepted

python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py --verify .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY.json --report .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY.md
PASS: INVALID; 1 attempted arm

python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/replay_frozen_evidence.py --self-test
PASS: source, arithmetic, and valid-shape payload mutations rejected

python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/replay_frozen_evidence.py --verify .planning/phases/247-ci-critical-path-and-suite-lanes/247-FROZEN-REPLAY.json --report .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-DIAGNOSIS.md --validation .planning/phases/247-ci-critical-path-and-suite-lanes/247-VALIDATION.md
PASS: VALID replay; 96 rows and frozen projection checked

git show 07d6a2c3805f1aaa728dc0c28367f56afca6e9f8:.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py | shasum -a 256
PASS: 60f8ee458e0104ac105abc0edb3fc211ff871b06ae64e671d5fc7c9d72ac9b4b
git show 07d6a2c3805f1aaa728dc0c28367f56afca6e9f8:.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs | shasum -a 256
PASS: e42f640c715af972265d55f6c81ead5f0d2512da73210c9b9ca9d32289f50a57
git show 07d6a2c3805f1aaa728dc0c28367f56afca6e9f8:test/support/partition_monitor.ex | shasum -a 256
PASS: 3164124276f674842be3d4515eb94a063969a7054f7716b655d206fefbbe2aa4
```

No `--run`, Docker command, ExUnit run, timing observation, hosted dispatch, source library/test/bin/workflow change, dependency change, or model/threshold change was performed.

## Commits

- `94c1733f` — canary signed clocks, stderr separation, and historical producer checks
- `f5f06c48` — bounded ExUnit registration trace drain and acknowledgment
- `301369ce` — frozen replay payload digest and artifact identity checks

## Immutable Receipt Checks

After verification, the original files still had these SHA-256 values:

- `247-LOCAL-CANARY.json`: `7a946173a6e4c9ca407d94d766343596f77980eaf01eb0ad353985e85b171385`
- `247-FROZEN-REPLAY.json`: `5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1`
- `247-LOCAL-CANARY-PREFLIGHT.json`: `728d8c8efa6fd88c6124c0c1745bcd0a26b00c4b61ebbcd25c7135aa607bb553`
