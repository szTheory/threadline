# Phase 247 B5 min-lane weights (Plan 27, D-25(b))

This record holds the pre-registration reference, both candidates, the training-only
selection, the holdout replays, the advisory `ci03_expectation`, `async_flips`, the D-11
follow-up, cross-lane predictions and the local run receipts. Plan 28 reads it.

## Provenance

- Training runs (B4 main successes): 40449332597, 40450141708, 40450801580. Holdouts: B4
  40451533079 and diagnostic 40504321590.
- All 20 min TSVs (12 training, 8 holdout) match the sha256 values pinned in
  `247-FROZEN-REPLAY.json` `manifest.artifact_hashes`, whose own sha256 is pinned
  (`5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1`). The diagnostic TSVs come from
  `247-DIAGNOSTIC-EVIDENCE.json` `raw_min_timings`.
- Tool: `tools/min_balance.py` (`fetch`, `derive --rule max`, `predict`, `replay`,
  `--self-test`). `predict` runs the production runner with `MIX_BIN=false`, so the
  assignment is the runner's own; the effective-weight sums are cross-checked against its
  printed weights. Cost per partition is `S + max(floor(A * 292 / 1000), L)`.
- N stays 4. The runner, `ASYNC_FACTOR_PERMILLE`, the current and latest weights, the
  colocation, ci.yml and the thresholds are unchanged.

## Pre-registration and selection (R1–R3)

`pre_registration_commit` 425a3965 is the last commit that
touched `247-27-PLAN.md` before Task 1 began, and it contains the R1–R5 block copied verbatim
into `pre_registered_rule`. R3 reads the three training runs only.

| Candidate | Predicted min ratio | Eligible | Training spreads (…597 / …708 / …580) | Worst |
|---|---|---|---|---|
| A (strict median) | 1.000071 | True | 1.281 / 1.180 / 1.348 | 1.348 |
| B (per-file max) | 1.00011 | True | 1.054 / 1.032 / 1.161 | 1.161 |

Both candidates are eligible under R2, and R3 selects **B** (the lower worst training
spread). Disclosure, as pre-registered: the candidate family and R5 were authored after the
iteration-1 checker numbers were known, holdouts included.

## Holdouts and expectation (R4, R5)

Holdouts 40451533079 and 40504321590 were replayed once, after `selected_weights_commit`
8ef4b801. They did not change the selection. Over all five persisted min
observations, the selected candidate's worst replay spread is 1.273 (run 40451533079).
The predicted ratios are min 1.00011, current 1.000017 and latest 1.000046.

`ci03_expectation` is **EXPECTED_MISS**. It is advisory only: it never halts and never re-selects, and
Plan 28 lands and runs the cohort under either value (D-25). CI-03 is decided only by measured
main ratios in Plan 28 (D-24). The checker's scratch replay of R1–R5 had already made
EXPECTED_MISS the likely outcome; the drift concentrates in
`test/threadline/deps_audit_gate_test.exs`, which sets the async floor L. CI-02 (B4 walls
404–468 s) remains the likely pass.

`follow_up`: the D-11 split of `test/threadline/deps_audit_gate_test.exs` into two module
files is the next candidate if CI-03 misses. It is not implemented here.

## Local runs (Task 3, D-12)

All five recorded runs exited 0 with zero failures, on HEAD with candidate B: three host
min-scope runs (Elixir 1.17.3 / OTP 27, postgres:16 16.14), one host full run, and one exact-min
min-scope run in `hexpm/elixir:1.15.8-erlang-26.2.5.21-debian-bookworm-20260824` against
postgres:15 (15.18) on a private Docker network. Local ratios are informational only (arm64
host, not CI's runner). One earlier host min-scope invocation was discarded, not counted: it ran
with a non-normalized `TMPDIR` (a path containing `..`), which made two path-equality
assertions in `source_family_test.exs` and two in `deps_audit_gate_test.exs` compare
`a/../b` against `b`. That was an invocation artifact, not a mix defect; the sequence was
restarted from the first host run with the default `TMPDIR`. All labelled containers and the
network were removed.

## Record

```json
<!-- B5-WEIGHTS-JSON-BEGIN -->
{
  "async_factor_permille": 292,
  "async_flips": [
    {
      "file": "test/threadline/storage/local_test.exs",
      "from": "async",
      "to": "sync"
    }
  ],
  "candidates": {
    "A": {
      "all_sync_partitions": [],
      "derivation": "strict per-file median: bin/ci-test-partitions --ingest-weights <train> --lane min --output test/partition_weights_min.txt",
      "eligible": true,
      "predicted_costs_ms": [
        112588,
        112581,
        112581,
        112580
      ],
      "predicted_ratio": 1.000071,
      "training_costs_ms": {
        "40449332597": [
          138723,
          150060,
          117180,
          149671
        ],
        "40450141708": [
          110600,
          116211,
          111951,
          98490
        ],
        "40450801580": [
          105881,
          97490,
          80436,
          108442
        ]
      },
      "training_spreads": {
        "40449332597": 1.280594,
        "40450141708": 1.179927,
        "40450801580": 1.348177
      },
      "weights_sha256": "9280bf4dbd95e2ad1cd771f2eec581e0d3ba0a001cfafa6da334154bbe4b23e5"
    },
    "B": {
      "all_sync_partitions": [],
      "derivation": "per-file maximum wall_ms over the three training runs (floor 1): min_balance.py derive --rule max",
      "eligible": true,
      "predicted_costs_ms": [
        136953,
        136946,
        136960,
        136945
      ],
      "predicted_ratio": 1.00011,
      "training_costs_ms": {
        "40449332597": [
          127590,
          133643,
          134458,
          131368
        ],
        "40450141708": [
          105000,
          102585,
          105683,
          102445
        ],
        "40450801580": [
          100483,
          89178,
          93784,
          86531
        ]
      },
      "training_spreads": {
        "40449332597": 1.053829,
        "40450141708": 1.031607,
        "40450801580": 1.161237
      },
      "weights_sha256": "cb833068ef4eec9a8896edea1e4ae405b11bb1d7a5e1515724850fc5b663b187"
    }
  },
  "ci03_expectation": "EXPECTED_MISS",
  "ci03_expectation_advisory": true,
  "dominating_files": [
    {
      "error_ms": -47333,
      "file": "test/threadline/deps_audit_gate_test.exs",
      "observed_ms": 51308,
      "run": 40504321590,
      "weight_ms": 98641
    },
    {
      "error_ms": -41285,
      "file": "test/threadline/public_surface_contract_test.exs",
      "observed_ms": 59667,
      "run": 40504321590,
      "weight_ms": 100952
    },
    {
      "error_ms": -32070,
      "file": "test/threadline/operator_surface/stress_router_test.exs",
      "observed_ms": 37697,
      "run": 40504321590,
      "weight_ms": 69767
    },
    {
      "error_ms": -26622,
      "file": "test/threadline/operator_surface/stress_router_prod_compile_test.exs",
      "observed_ms": 34339,
      "run": 40504321590,
      "weight_ms": 60961
    },
    {
      "error_ms": -12921,
      "file": "test/threadline/release_artifact_contract_test.exs",
      "observed_ms": 8852,
      "run": 40450141708,
      "weight_ms": 21773
    }
  ],
  "follow_up": "If CI-03 misses on min, the next candidate is the D-11 split of test/threadline/deps_audit_gate_test.exs into two module files, so the async floor L it sets is halved; it is named here and not implemented in Plan 27.",
  "frozen_replay_sha256": "5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1",
  "holdout_costs_ms": {
    "40451533079": [
      133015,
      141626,
      111251,
      128176
    ],
    "40504321590": [
      78676,
      75976,
      75326,
      75429
    ]
  },
  "holdout_max_boot_ms": {
    "40451533079": 22723,
    "40504321590": 2239
  },
  "holdout_runs": [
    40451533079,
    40504321590
  ],
  "holdout_spreads": {
    "40451533079": 1.273031,
    "40504321590": 1.044473
  },
  "local_runs": [
    {
      "exit": 0,
      "failures": 0,
      "head": "b46d935cd2c956963baa99ba713fea1894e307c4",
      "name": "host-min-1",
      "note": "THREADLINE_CI_LANE=min THREADLINE_TEST_SCOPE=toolchain mix verify.test_partitioned; partition seconds 39/49/47/38",
      "postgres": "16",
      "printed_ratio": 1.29,
      "scope": "toolchain",
      "tests": 2564,
      "toolchain": "elixir 1.17.3-otp-27 (erlang 27.3.4.15), host arm64"
    },
    {
      "exit": 0,
      "failures": 0,
      "head": "b46d935cd2c956963baa99ba713fea1894e307c4",
      "name": "host-min-2",
      "note": "same; partition seconds 39/48/46/37",
      "postgres": "16",
      "printed_ratio": 1.3,
      "scope": "toolchain",
      "tests": 2564,
      "toolchain": "elixir 1.17.3-otp-27 (erlang 27.3.4.15), host arm64"
    },
    {
      "exit": 0,
      "failures": 0,
      "head": "b46d935cd2c956963baa99ba713fea1894e307c4",
      "name": "host-min-3",
      "note": "same; partition seconds 39/48/46/39",
      "postgres": "16",
      "printed_ratio": 1.23,
      "scope": "toolchain",
      "tests": 2564,
      "toolchain": "elixir 1.17.3-otp-27 (erlang 27.3.4.15), host arm64"
    },
    {
      "exit": 0,
      "failures": 0,
      "head": "b46d935cd2c956963baa99ba713fea1894e307c4",
      "name": "host-full-1",
      "note": "mix verify.test_partitioned (current weights, full scope); partition seconds 62/74/67/46",
      "postgres": "16",
      "printed_ratio": 1.61,
      "scope": "full",
      "tests": 3384,
      "toolchain": "elixir 1.17.3-otp-27 (erlang 27.3.4.15), host arm64"
    },
    {
      "exit": 0,
      "failures": 0,
      "head": "b46d935cd2c956963baa99ba713fea1894e307c4",
      "name": "exact-min-1",
      "note": "git archive HEAD scratch copy, container-local _build/deps, git+jq+gawk via apt inside the container, private Docker network, DB_HOST=postgres:15 (15.18) container; partition seconds 40/43/44/45",
      "postgres": "15",
      "printed_ratio": 1.12,
      "scope": "toolchain",
      "tests": 2564,
      "toolchain": "elixir 1.15.8 (OTP 26.2.5.21), hexpm/elixir:1.15.8-erlang-26.2.5.21-debian-bookworm-20260824, arm64, GNU Awk 5.2.1"
    }
  ],
  "n_partitions": 4,
  "pre_registered_rule": "R1 candidates. A = output of `bin/ci-test-partitions --ingest-weights <train> --lane min --output test/partition_weights_min.txt` (per-file median of the three training runs). B = for every file in the strictly validated min lane inventory, the maximum wall_ms across the same three training runs (floor 1), written in the identical header and `<ms> <file>` format sorted by path.\nR2 eligibility. A candidate is eligible if `predict --lane min` on the production assignment gives ratio <= 1.15.\nR3 selection (training runs only). Select the eligible candidate with the lower worst replay spread over the three training runs; on a tie, or if B is ineligible, select A; if neither is eligible, select A.\nR4 holdouts. Replay 40451533079 and 40504321590 exactly once, after selected_weights_commit; holdouts never change the selection.\nR5 expectation (advisory, never a halt). ci03_expectation = EXPECTED_PASS if and only if the selected candidate's worst replay spread across the three training runs and two holdouts is <= 1.15 and the min, current and latest predictions are each <= 1.15; otherwise EXPECTED_MISS.\nDisclosure. The candidate family (A, B) and R5 were authored after the iteration-1 checker numbers were known, holdouts included. B is worse than A on holdout 40451533079 (1.273 vs 1.114), so no sign of holdout tuning exists.",
  "pre_registration_commit": "425a3965e76ce3ac440c94fc262e3aee1920f251",
  "predicted": {
    "current": 1.000017,
    "latest": 1.000046,
    "min": 1.00011
  },
  "r3_worst_training_spread": {
    "A": 1.348177,
    "B": 1.161237
  },
  "risk": "The selected candidate B's worst replay spread is 1.273 on B4 holdout 40451533079, dominated by test/threadline/deps_audit_gate_test.exs (observed 112715 ms against a 98641 ms weight, the async floor L of its partition), so ci03_expectation is EXPECTED_MISS (advisory).",
  "schema": "threadline.phase247-b5-weights/1",
  "selected": "B",
  "selected_weights_commit": "8ef4b801294289bc7f06d0f74fc2a986697dec5d",
  "source_sha256": {
    "colocation": "ac8c8d194e981af4eda888e4ffd3e855ac85c0de518186f5b20b159331f6f543",
    "runner": "bae639ed3162fcf6a1bd2ef2d07c35cabe032057d5c8b7e13fbe23a8ce360259"
  },
  "training_runs": [
    40449332597,
    40450141708,
    40450801580
  ],
  "tsv_sha256": {
    "40449332597/min/1": "8f68d7e146ff567b86d67eb69051f8455ce8d070f0bd13ae498ecb2f6001054f",
    "40449332597/min/2": "ec634bf85a9f4f47222985fb3803a0231b41a590d6f470f448b1f9a1b90c7466",
    "40449332597/min/3": "2f85de00f0d218893531f3d290ee35f1262e4b8e473a464b7f046bc53b042724",
    "40449332597/min/4": "f38a93d7ca1c2c6674edc8a52bf4b3199efd3a1ab5c2411149e89e57c4a42961",
    "40450141708/min/1": "c35e333ad88d34993d272b9696e7b52a393d52ab4809ee4946e241d60f744246",
    "40450141708/min/2": "63246d80ec06ef6316aa570d85745712dd99f6ad731a87f8475cbf3a962128f1",
    "40450141708/min/3": "49daeb55cb2d7cbcf79f3bf6ff4abc56beae9b57cbb8429600ec6e32eae2e556",
    "40450141708/min/4": "311fbd2349cbae4d631d199bd40150f42262b61b19c9d9449b8eed5bbb61c07c",
    "40450801580/min/1": "024eb134c78fc0ef3cc43a27c753297889b5840d1c1978f924829a71f0ad987e",
    "40450801580/min/2": "b372d03aeac068cc69aac0be2a4a394f1e91317b5f1c28575c7551bfb88246d9",
    "40450801580/min/3": "06e983c548acd22e4632f2f1fd426235eb5451fcc5ac8a4980598f77a62a5ff1",
    "40450801580/min/4": "6a2b1bdc21465ae3bbc1ac3e9ae01a59463c27a0daaa46da50756220cc4489ad",
    "40451533079/min/1": "e4a3bb798e0f8f625cfe2693b146b07ae4b1cbdb7d0c754a2a83e8a6ee764fc5",
    "40451533079/min/2": "4bbb0b9a2c84e3e1ec184272d873f08e19ac940f2f71bee8113f2ed5be3ff9f1",
    "40451533079/min/3": "783c3f620e8b39a3f991e63c415e21110b37227c0d619901f08a04da8fae61a5",
    "40451533079/min/4": "8d17634440826f8c3d15d92b8251f34a1b3b09f5ffde2a68426430d707c40465",
    "40504321590/min/1": "d38e76ed7619ef4a02f565d3d445de10f30ff65fce14d81fc09e4758b2890772",
    "40504321590/min/2": "2fada20fa27d9a36b1899d92e395915c62d7c6d65c345dc21cf82e957eac4687",
    "40504321590/min/3": "b8e3afec7b7a7d3fdb82502cd71905437bdba4708cd00c09bc0a86ab0a6c0e63",
    "40504321590/min/4": "2b0f28c5120581de82e4d85e4b83b6b41fcdcc16d13e1309e0807624c14882d5"
  },
  "weights_sha256": "cb833068ef4eec9a8896edea1e4ae405b11bb1d7a5e1515724850fc5b663b187",
  "worst_spread": 1.273031,
  "worst_spread_run": "40451533079"
}
<!-- B5-WEIGHTS-JSON-END -->
```
