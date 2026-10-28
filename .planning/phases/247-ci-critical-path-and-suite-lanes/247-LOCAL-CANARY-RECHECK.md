# Local canary recheck

## Verdict and provenance

<!-- receipt-projection:start -->
{
  "arms": [],
  "attempted_count": 0,
  "compile_smoke": {
    "cidfile_absent_before_launch": true,
    "cleanup": "removed",
    "cleanup_exit_code": 0,
    "id": "59470909f5d3d36400f5e5e87496af2e8d0beeb21d135bf4a48e1c01b3828ef7",
    "inspect_exit_code": 0,
    "inspected_name": "/threadline-24723-c0183c8315a0",
    "launch_exit_code": 0,
    "name": "threadline-24723-c0183c8315a0",
    "ownership_disclosure": null,
    "parse_error": null,
    "retained_unverified": false,
    "stderr_excerpt": "warning: variable \"mode\" is unused (if the variable is not meant to be used, prefix it with an underscore)\n  probe/runner.exs:140: CanaryRunner.run_case/3\n\n",
    "stdout_excerpt": "THREADLINE_RUNTIME|1.15.8|26.2.5.21|aarch64-unknown-linux-gnu\nTHREADLINE_COMPILE_SMOKE|ok\n"
  },
  "compile_smoke_result": {
    "events": [],
    "reason": "compile_smoke_stderr_present",
    "status": "INVALID"
  },
  "hashes": {
    "formatter_sha256": "3164124276f674842be3d4515eb94a063969a7054f7716b655d206fefbbe2aa4",
    "runner_sha256": "dc75bbe51c196b6d1540f151d51b3443191d4ec76b59826ab3ee0ebcdf2640a2"
  },
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
  "plan": "247-23",
  "producer": {
    "commit": "d42f0912f17dc8dcd265a52f72c41d9f58e4e4b0",
    "path": ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py",
    "sha256": "7e4cd2f2fc125638a8b13d46e064c22beb7a43e2f6b77430b715b4d35ebce78d"
  },
  "reservation": {
    "path": "247-LOCAL-CANARY-RECHECK.reservation.json",
    "sha256": "c7c0aa1f1a45ce6fd2f557628afeb04b02f03641fdc03a6edaf6b4e14f93ebd5"
  },
  "result": {
    "reason": "compile_smoke_stderr_present",
    "status": "INVALID"
  },
  "runtime": {
    "architecture": "aarch64-unknown-linux-gnu",
    "elixir": "1.15.8",
    "otp": "26.2.5.21"
  },
  "schema": "threadline.exunit-boundary-recheck-preflight/1",
  "source": {
    "head": "d42f0912f17dc8dcd265a52f72c41d9f58e4e4b0",
    "status_before": [
      "?? .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-RECHECK-DECISION.md"
    ]
  },
  "stderr_excerpt": null
}
<!-- receipt-projection:end -->

## Limits

CI-02 remains INCOMPLETE; CI-03 remains MISS; exact-runtime evidence is scoped to this receipt.
