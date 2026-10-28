# Local ExUnit Boundary Validation — 247-22

## Verdict

**Terminal result: INVALID after one attempted arm.** The metadata/runtime preflight passed, but the first async warmup exited 1 while compiling the runner. No A/B pair or control ran; the authorized one-series reservation is consumed. This records an instrument/runtime failure and provides no semantic boundary result.

## Provenance and environment

- Scope: the maintainer authorized one local series on 2026-10-27, bounded to one metadata/runtime preflight, at most two warmups, three A/B pairs in A/B, B/A, A/B order, and two controls; each child is limited to 15 seconds and the series to 150 seconds. No retry or replacement sample is authorized.
- Source / producer commit: `8e6321f36ed285c057532bade0ba4a007c5e5451`; coordinator SHA-256: `8f810426c637b4152f4cd77e4375b45157f22ee1362b108a53e4aa3807334eba`.
- Runner SHA-256: `39c18eb1873ffa4522684a1f0ac3800d6f2157b0294db8ba5efbcd71fa3a3634`; formatter SHA-256: `3164124276f674842be3d4515eb94a063969a7054f7716b655d206fefbbe2aa4`.
- Image: `hexpm/elixir:1.15.8-erlang-26.2.5.21-debian-bookworm-20260824`, immutable ID `sha256:34238960354603d7bbe04d55c0c67a5c9b03e1366f3511614ca6357d74a6650b`, repo digest `hexpm/elixir@sha256:bcead3678dec8be86c3d8b93236e4b9c685f2a30472e71aeb972a834ef05b5fb`, architecture `arm64`.
- Preflight: `247-LOCAL-CANARY-VALIDATION-PREFLIGHT.json` SHA-256 `6915bb07923065354184cb0085bb29653629f3e560b9b043654766eee6ca7e81`, result **VALID**; Elixir `1.15.8` / OTP `26.2.5.21`.
- **Provenance limitation:** the preflight labeled image/runtime identity valid, but the tool did not record an owned Docker container ID or name for its two `docker run --rm` probes. The attempted arm's actual generated name is also redacted as `<owned-container>` and no container ID is present in the raw receipt. Thus the requested owned-container identity evidence is missing; this does not change the terminal child failure or justify a rerun.
- Historical inputs remain SHA-pinned: original canary `7a946173a6e4c9ca407d94d766343596f77980eaf01eb0ad353985e85b171385`; original preflight `728d8c8efa6fd88c6124c0c1745bcd0a26b00c4b61ebbcd25c7135aa607bb553`; frozen replay `5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1`.
- Reservation `247-LOCAL-CANARY-VALIDATION.reservation.json` remains in place and binds the preflight and producer. It must not be removed or reused.

## Attempted arm and terminal evidence

| Arm | Kind / mode | Exit | Runtime/events/TSV | Outcome |
|---|---|---:|---|---|
| `arm-01-warmup-async` | warmup / async | `1` | Runtime identity absent; no event records or formatter TSV | `child_nonzero_exit`; terminal early stop |

Captured stderr reports an internal compiler exception in OTP's `beam_ssa_recv` while compiling `probe/runner.exs`: `no match of right hand side value false` in `beam_ssa_recv:pu_is_ref_used_is/2`. The process ended in 407 ms, within the child limit. The runner emitted no parseable runtime/event/formatter record. The receipt derives `INVALID` from the nonzero exit, absent evidence, and incomplete fixed schedule. This command invokes the standalone Elixir runner directly; it does not invoke `mix test` or `Mix.Compilers.Test`, so it says nothing about Mix test compilation or project partition behavior. The failure is preserved as emitted; no source or cached image was changed.

## Clock and measurement interpretation

Collection bounds use UTC wall-clock values and monotonic nanoseconds. Event occurrence time, if emitted, is signed monotonic milliseconds within one child and is never compared across children. Formatter TSV `boot_ms` and `wall_ms` are VM-relative `:erlang.statistics(:wall_clock)` values. This failed arm emitted no events and no TSV, so no event ordering or timing comparison exists.

## Limited interpretation and remaining gaps

This local native ARM64 failure cannot identify the historical AMD64 minimum-P3 cause. B3 remains training. B4 has four successes and two failed exclusions, so its five-run median remains null. Diagnostic run `40504321590` is off main. The fixed B4 first-three minimum ratios remain `1.24 / 1.28 / 1.27`.

CI-01 and CI-04 remain VERIFIED; CI-02 remains INCOMPLETE; CI-03 remains MISS; Phase 247 remains 2/4. This observation changes none of those acceptance states.

## Independent review

Review source: `automated-review`. Reviewer: `/root/execute_247_22_observation/review_24722_receipt` (`gsd-code-reviewer`). The reviewer checked the raw receipt, this report, reservation and original receipts, plus exact Elixir v1.15.8 source for [`ExUnit.Case`](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/ex_unit/lib/ex_unit/case.ex), [`ExUnit.Server`](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/ex_unit/lib/ex_unit/server.ex), [`ExUnit.Runner`](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/ex_unit/lib/ex_unit/runner.ex), [`ExUnit`](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/ex_unit/lib/ex_unit.ex), and [`Mix.Compilers.Test`](https://raw.githubusercontent.com/elixir-lang/elixir/v1.15.8/lib/mix/lib/mix/compilers/test.ex). Case's after-compile hook selects the async or sync Server registration; Server queues registrations; Runner drains async modules before sync modules; Mix's test compiler follows async-run, parallel require, then await. This observation bypasses Mix and failed compiling the standalone runner before runtime, so none of those registration or execution semantics were observed here.

**Reviewed-body hash method:** SHA-256 of the exact UTF-8 bytes before `## Independent review\n` concatenated with the exact bytes starting at the receipt-projection start marker through EOF. The marker bytes are `&lt;!-- receipt-projection:start --&gt;`. This excludes this review section while binding the machine projection. The previously recorded `f80f4d63d4b9cc104a8880a2883fb4d6abb0936bf809138467f28c3409421abe` used a different body boundary and is superseded.

**Reviewed-body SHA-256:** `6f6525d1490bfcb46e6f3b7be3049827e4b4cbfa557ef7027b28f69f8336eb58`.

Reviewed input SHA-256 values:

| Input | SHA-256 |
|---|---|
| `247-LOCAL-CANARY-VALIDATION.json` | `2be63b2ac0894f17321f437ffa839b4c36333f0af0d4f9392eee707322214f93` |
| `247-LOCAL-CANARY-VALIDATION-PREFLIGHT.json` | `6915bb07923065354184cb0085bb29653629f3e560b9b043654766eee6ca7e81` |
| `247-LOCAL-CANARY-VALIDATION.reservation.json` | `290f7325a6797854a38039014cc7db0d96e6241bee33e89eb806e62ec2638a62` |
| `247-LOCAL-CANARY.json` | `7a946173a6e4c9ca407d94d766343596f77980eaf01eb0ad353985e85b171385` |
| `247-LOCAL-CANARY-PREFLIGHT.json` | `728d8c8efa6fd88c6124c0c1745bcd0a26b00c4b61ebbcd25c7135aa607bb553` |
| `247-FROZEN-REPLAY.json` | `5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1` |
| `tools/exunit_boundary_probe.py` | `8f810426c637b4152f4cd77e4375b45157f22ee1362b108a53e4aa3807334eba` |
| `tools/exunit_boundary_case.exs` | `39c18eb1873ffa4522684a1f0ac3800d6f2157b0294db8ba5efbcd71fa3a3634` |
| `test/support/partition_monitor.ex` | `3164124276f674842be3d4515eb94a063969a7054f7716b655d206fefbbe2aa4` |

**Finding and disposition:** WARNING — Docker container names/IDs are missing from preflight and attempted-arm evidence. The report now discloses the omission. Reviewer otherwise found the report consistent with the raw `INVALID` receipt, confirmed the historical hashes, and found no promotion of CI-02/CI-03 or the historical AMD64 cause. Projection verification passed (`INVALID; 1 attempted arms`).

<!-- receipt-projection:start -->
{
  "arms": [
    {
      "argv": [
        "docker",
        "run",
        "--pull=never",
        "--rm",
        "--name",
        "<owned-container>",
        "--network=none",
        "--read-only",
        "--cpus=1",
        "--mount",
        "<private-owned-mount>",
        "--entrypoint",
        "elixir",
        "sha256:34238960354603d7bbe04d55c0c67a5c9b03e1366f3511614ca6357d74a6650b",
        "/probe/runner.exs",
        "/probe/case.exs",
        "async",
        "none"
      ],
      "child_duration_ms": 407,
      "child_ended_monotonic_ns": 531030083,
      "child_started_monotonic_ns": 124418125,
      "cleanup_duration_ms": 0,
      "control": null,
      "duration_ms": 407,
      "ended_monotonic_ns": 531082250,
      "error_code": "child_nonzero_exit",
      "events": [],
      "exit_code": 1,
      "formatter": null,
      "id": "arm-01-warmup-async",
      "kind": "warmup",
      "mode": "async",
      "parse_error": null,
      "raw_tsv_excerpt": "",
      "runtime": null,
      "started_monotonic_ns": 124060416,
      "stderr_excerpt": "** (CompileError) probe/runner.exs: internal error in pass beam_ssa_recv:\nexception error: no match of right hand side value false\n  in function  beam_ssa_recv:pu_is_ref_used_is/2 (beam_ssa_recv.erl, line 632)\n  in call from beam_ssa_recv:pu_is_ref_used_in_1/3 (beam_ssa_recv.erl, line 596)\n  in call from beam_ssa_recv:pu_ref_used_in/2 (beam_ssa_recv.erl, line 580)\n  in call from beam_ssa_recv:pu_is_ref_used/4 (beam_ssa_recv.erl, line 556)\n  in call from lists:search_1/2 (lists.erl, line 1776)\n  in call from beam_ssa_recv:plan_uses_1/4 (beam_ssa_recv.erl, line 520)\n  in call from beam_ssa_recv:'-plan_uses/3-anonymous-0-'/5 (beam_ssa_recv.erl, line 511)\n  in call from maps:fold_1/4 (maps.erl, line 416)\n    (stdlib 5.2.3.6) lists.erl:1686: :lists.foreach_1/2\n",
      "stdout_excerpt": "",
      "timed_out": false
    }
  ],
  "attempted_count": 1,
  "budgets": {
    "child_seconds": 15,
    "max_controls": 2,
    "max_warmups": 2,
    "overall_seconds": 150,
    "pairs": [
      [
        "async",
        "sync"
      ],
      [
        "sync",
        "async"
      ],
      [
        "async",
        "sync"
      ]
    ]
  },
  "ci_02": "INCOMPLETE",
  "ci_03": "MISS",
  "collection": {
    "clock": "UTC wall clock for collection bounds; signed monotonic event occurrence time remains per child",
    "ended_at_utc": "2026-10-27T15:31:09.490Z",
    "ended_monotonic_ns": 546884416,
    "started_at_utc": "2026-10-27T15:31:09.053Z",
    "started_monotonic_ns": 109761541
  },
  "hashes": {
    "canary_sha256": {
      "async": "93e1a05fc7cfa191abbcc3fde8d46901cc7941aa948c67c791a09c234b5d42cf",
      "setup_all": "fe801f618db362ca6e81852d17174df0b50773272bcbd138e50f552e8f008440",
      "sync": "63444ce36842d903a74211e3ba4f5b00d50ce720e3e761b00746e7f5ca48e46c"
    },
    "formatter_sha256": "3164124276f674842be3d4515eb94a063969a7054f7716b655d206fefbbe2aa4",
    "runner_sha256": "39c18eb1873ffa4522684a1f0ac3800d6f2157b0294db8ba5efbcd71fa3a3634"
  },
  "historical_ci_cause": "UNPROVEN",
  "historical_sha256": {
    "247-FROZEN-REPLAY.json": "5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1",
    "247-LOCAL-CANARY-PREFLIGHT.json": "728d8c8efa6fd88c6124c0c1745bcd0a26b00c4b61ebbcd25c7135aa607bb553",
    "247-LOCAL-CANARY.json": "7a946173a6e4c9ca407d94d766343596f77980eaf01eb0ad353985e85b171385"
  },
  "image": {
    "architecture": "arm64",
    "id": "sha256:34238960354603d7bbe04d55c0c67a5c9b03e1366f3511614ca6357d74a6650b",
    "os": "linux",
    "repo_digests": [
      "hexpm/elixir@sha256:bcead3678dec8be86c3d8b93236e4b9c685f2a30472e71aeb972a834ef05b5fb"
    ],
    "size_bytes": 223929793,
    "tag": "hexpm/elixir:1.15.8-erlang-26.2.5.21-debian-bookworm-20260824"
  },
  "preflight": {
    "path": "247-LOCAL-CANARY-VALIDATION-PREFLIGHT.json",
    "sha256": "6915bb07923065354184cb0085bb29653629f3e560b9b043654766eee6ca7e81"
  },
  "producer": {
    "commit": "8e6321f36ed285c057532bade0ba4a007c5e5451",
    "path": ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py",
    "sha256": "8f810426c637b4152f4cd77e4375b45157f22ee1362b108a53e4aa3807334eba"
  },
  "result": {
    "reason": "fixed_schedule_incomplete;arm-01-warmup-async:child_timeout_or_nonzero_exit;arm-01-warmup-async:runtime_identity_invalid;arm-01-warmup-async:registration_event_missing_or_duplicated;arm-01-warmup-async:required_event_missing;arm-01-warmup-async:formatter_tsv_invalid",
    "status": "INVALID"
  },
  "runtime": {
    "elixir": "1.15.8",
    "otp": "26.2.5.21"
  },
  "source": {
    "head": "8e6321f36ed285c057532bade0ba4a007c5e5451"
  }
}
<!-- receipt-projection:end -->
