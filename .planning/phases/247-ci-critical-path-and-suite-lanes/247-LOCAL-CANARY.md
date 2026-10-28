# Phase 247 local ExUnit boundary canary

**Local result: `INVALID`.** After the documented pre-data repair, the sole actual series stopped on its first warmup because the event parser rejected valid negative monotonic timestamps. The child did run on the exact runtime and emitted ExUnit events, but the receipt lacked registration events and parsed formatter timings, so the timing oracle was invalid. No A/B pair or control ran, and no arm was replaced.

## Prespecified pre-data repair

The immutable first-attempt receipt is retained as [247-LOCAL-CANARY-PREFLIGHT.json](./247-LOCAL-CANARY-PREFLIGHT.json), SHA-256 `728d8c8efa6fd88c6124c0c1745bcd0a26b00c4b61ebbcd25c7135aa607bb553`. It records one warmup launch, exit `125`, 15 ms, no runtime/event/formatter data, and the derived invalid stop. A metadata-only `elixir --version` replay identified the CLI error: `--mount ...dst=/probe,rw` is invalid because `rw` is not a key/value field. The pre-data repair removes that suffix (bind mounts are writable by default), records bounded sanitized output, and adds a negative self-test for missing stderr capture. Corrected Docker flags passed metadata-only `elixir --version` from the same private temp mount location. This repair did not alter runtime, fixtures, schedule, or thresholds. The actual receipt links to the unchanged preflight hash.

## Provenance

- Cached image tag: `hexpm/elixir:1.15.8-erlang-26.2.5.21-debian-bookworm-20260824`
- Immutable image ID: `sha256:34238960354603d7bbe04d55c0c67a5c9b03e1366f3511614ca6357d74a6650b`
- Repository digest: `hexpm/elixir@sha256:bcead3678dec8be86c3d8b93236e4b9c685f2a30472e71aeb972a834ef05b5fb`
- Inspected platform: `linux/arm64`; host architecture `arm64`; container CPU quota `1` (host reported 18 CPUs).
- The image was inspected locally and not pulled. Separate metadata inspection confirmed Elixir `1.15.8`, OTP version file `26.2.5.21`, and `aarch64-unknown-linux-gnu`; that inspection did not run the canary.
- Source HEAD for the preserved preflight attempt: `120cf53ab61da052b64aef3b7113fdb4581100cc`.
- Source HEAD for the actual series: `07d6a2c3805f1aaa728dc0c28367f56afca6e9f8`.
- Producer commit for the actual receipt: `07d6a2c3805f1aaa728dc0c28367f56afca6e9f8`; coordinator SHA-256 at that commit: `60f8ee458e0104ac105abc0edb3fc211ff871b06ae64e671d5fc7c9d72ac9b4b`.
- Unchanged copied `PartitionMonitor` SHA-256: `3164124276f674842be3d4515eb94a063969a7054f7716b655d206fefbbe2aa4`.
- Runner SHA-256: `e42f640c715af972265d55f6c81ead5f0d2512da73210c9b9ca9d32289f50a57`.
- Generated canary SHA-256: async `93e1a05fc7cfa191abbcc3fde8d46901cc7941aa948c67c791a09c234b5d42cf`; sync `63444ce36842d903a74211e3ba4f5b00d50ce720e3e761b00746e7f5ca48e46c`; `setup_all` control `fe801f618db362ca6e81852d17174df0b50773272bcbd138e50f552e8f008440`.
- The A/B fixtures were generated from one template; their sole source difference is `async: true` versus `async: false`.

## Fixed protocol and observed arm

The corrected coordinator allowed at most two warmups, three alternating A/B pairs, and two controls, with a 15-second child cap and 150-second overall cap. It invoked one actual bounded series. The child used a unique owned container name, `--pull=never`, no network, a read-only image filesystem, a one-CPU limit, and a private temporary bind mount. The owned temporary directory was removed at exit. No database, application modules, production tests, or CI workflows were involved.

| Attempt | Role | Variant | Result | Events / formatter |
| --- | --- | --- | --- | --- |
| `arm-01-warmup-async` | Warmup 1 of at most 2 | Async | Child exit `0` after about 2.58 s; parser stopped the series | Exact runtime line and helper/start/require/module/suite event lines were emitted; no `registration_*` line; no parsed event list or retained TSV |

The actual receipt records one attempted warmup in 2,578 ms overall. Its raw output order was `helper_start`, `exunit_start`, `require_start`, `module_started`, `require_return`, `barrier_start`, `barrier_release`, `suite_finished`; there was no `registration_*` line. For example, the raw child clock reports `module_started=-576460751623` and `require_return=-576460751622`, followed by `barrier_release=-576460749611`. The raw sequence is qualitatively consistent with a module starting during require, but it is not a valid event-order oracle and does not establish `VALID_SEMANTIC`: the registration trace is missing, and the parser requires non-negative decimal text, raising `ValueError: malformed event record` on values such as `-576460751714`. The generic handler then placed that coordinator error in `stderr_excerpt`, overwriting the process stderr already captured by `communicate`; therefore the child's original stderr is unavailable. The parsed `runtime` field and formatter TSV are null because parsing aborted before those values were extracted. The immutable preflight artifact separately records the earlier Docker syntax failure. No controls or A/B pairs were reached, so this is an invalid measurement, not a no-signal result.

The event clock is monotonic milliseconds scoped to one child; OTP can return negative monotonic values, and values must not be compared across VMs. The copied formatter's `boot_ms` and `wall_ms` use VM-relative `:erlang.statistics(:wall_clock)`. The pre-ExUnit control would test the first-module/boot endpoint; the `setup_all` control would test suite wall after the first module. Neither control ran.

Before the actual series, `--self-test` passed its synthetic semantic case and rejected 11 negative mutations, including missing stderr capture. Those checks validate the receipt oracle only; they are not canary observations. The independent receipt verifier accepts the resulting honest `INVALID` receipt and rejects promotion to a valid status. It validates the Elixir runner, formatter, canary, and preflight hashes; it does not currently compare the Python coordinator SHA to the producer commit. Any future offline parser review must first verify the recorded producer commit and coordinator SHA, and must retain this receipt's original `INVALID` disposition.

## Historical evidence and limits

B4 remains **INCOMPLETE**: four qualifying successful main runs and two failed exclusions exhausted its six-run cap. The fixed min partition-3 ratios remain `1.24 / 1.28 / 1.27`, all above the unchanged `1.15` limit; there is no complete-five median. The separate off-main diagnostic, run `40504321590`, completed 17/17 jobs in 450 seconds, but it changed source and assignment: the old B4 min P3 had 31 all-sync files, while the diagnostic P3 had 36 files including eight async files. That comparison cannot establish historical causality.

Exact-version sources explain why the proposed oracle was relevant: Mix 1.15.8's `Mix.Compilers.Test` starts `ExUnit.async_run()` before `Kernel.ParallelCompiler.require/2`, then calls `ExUnit.await_run/1`; async module registration can therefore be scheduled before the all-modules-loaded barrier, while sync modules wait for it. See [Mix.Compilers.Test v1.15.8](https://github.com/elixir-lang/elixir/blob/v1.15.8/lib/mix/lib/mix/compilers/test.ex), [ExUnit.Case v1.15.8](https://github.com/elixir-lang/elixir/blob/v1.15.8/lib/ex_unit/lib/ex_unit/case.ex), [ExUnit.Server v1.15.8](https://github.com/elixir-lang/elixir/blob/v1.15.8/lib/ex_unit/lib/ex_unit/server.ex), and [ExUnit.Runner v1.15.8](https://github.com/elixir-lang/elixir/blob/v1.15.8/lib/ex_unit/lib/ex_unit/runner.ex). The existing formatter defines `boot_ms` at its first `:module_started` and suite `wall_ms` at `:suite_finished`.

This local run did not test that mechanism. It also cannot explain the historical 17–22 second min pre-module interval. The profile-only exit-1 behavior remains a separate diagnostic: that Mix profile path skips test execution and cannot substitute for the normal ExUnit runner boundary.

| Verdict | Status |
| --- | --- |
| Local semantic canary | `INVALID` — one warmup emitted events, but the event/parser oracle failed and no formatter timing was retained |
| Historical CI cause | `UNPROVEN` |
| CI-02 | `INCOMPLETE` |
| CI-03 | `MISS` |

<!-- receipt-projection:start -->
{
  "arms": [
    {
      "control": null,
      "error_code": "child_execution_error:ValueError",
      "events": [],
      "exit_code": 0,
      "formatter": null,
      "id": "arm-01-warmup-async",
      "kind": "warmup",
      "mode": "async",
      "stderr_excerpt": "malformed event record",
      "stdout_excerpt": "THREADLINE_RUNTIME|1.15.8|26.2.5.21|aarch64-unknown-linux-gnu\nTHREADLINE_EVENT|helper_start|-576460751714\nTHREADLINE_EVENT|exunit_start|-576460751641\nTHREADLINE_EVENT|require_start|-576460751635\nTHREADLINE_EVENT|module_started|-576460751623\nTHREADLINE_EVENT|require_return|-576460751622\nTHREADLINE_EVENT|barrier_start|-576460751622\nTHREADLINE_EVENT|barrier_release|-576460749611\nTHREADLINE_EVENT|suite_finished|-576460749610\n",
      "timed_out": false
    }
  ],
  "attempted_count": 1,
  "ci_02": "INCOMPLETE",
  "ci_03": "MISS",
  "historical_ci_cause": "UNPROVEN",
  "reason": "fixed_schedule_stopped_early_or_incomplete;arm-01-warmup-async:registration_event_missing_or_duplicated;arm-01-warmup-async:required_event_missing;arm-01-warmup-async:formatter_tsv_invalid;control_missing",
  "status": "INVALID"
}
<!-- receipt-projection:end -->
