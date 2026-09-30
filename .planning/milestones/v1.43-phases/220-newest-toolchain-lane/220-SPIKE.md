# Phase 220: Newest-toolchain spike

The D-10 dispatch spike for the voting `lane: latest` row. It was one dispatch, run 36484105399, and every job in it passed. The D-11 bar was met on the first run, so neither the fix cycle nor the flake re-dispatch was used.

## Pins

Re-checked on **2026-09-28 at 21:08 UTC**, just before the first push. The sources are the same three plan 01 used (D-01).

| Component | Committed latest row | Newest found at re-check | Source | Drift |
|-----------|----------------------|--------------------------|--------|-------|
| Elixir | `1.20.4` | `v1.20.4-otp-29` (2026-08-28T10:07:51Z) | builds.hex.pm/builds/elixir/builds.txt, newest `v1.20.*-otp-29` line | none |
| OTP | `29.1.1` | `OTP-29.1.1` (2026-09-22T08:11:48Z) | builds.hex.pm/builds/otp/ubuntu-24.04/builds.txt, newest `OTP-29` line | none |
| PostgreSQL | `18.6` | `18.6` | `docker manifest inspect postgres:18.6` succeeds; `postgres:18.7` and `postgres:18.8` do not exist | none |

The committed row (`ci.yml` lines 349-353 on the spike tip) is `lane: latest`, `elixir: "1.20.4"`, `otp: "29.1.1"`, `pg: "18.6"`, `runner: "ubuntu-24.04"`. No re-pin was needed.

## Branch and commits

- **Base:** `land/v1.43-217-218` at `fcb22e00c4dc80f9a05a242ccb11b2136dfaaaa2`, fetched just before the build. The local and `origin/` values were equal.
- **Spike tip:** `spike/220-latest` at **`4a32cbf6ccf026ffd727d2c183d9aa356431f788`**. It was built in a throwaway worktree.
- **Commits** (`git log --oneline land/v1.43-217-218..spike/220-latest`):
  - `56015527 refactor(220): remove dead code that Elixir 1.20's type checker flags`. This is the cherry-pick of plan 01's `17a7faa5`.
  - `4a32cbf6 ci(220): add a voting newest-toolchain lane with fail-closed lane contracts`. This is the cherry-pick of plan 02's commit A, `77ff2392`.
- Plan 02's commit B (`5a037db2`) and all `.planning/` commits were left out.
- **Conflicts:** none. `mix.exs` auto-merged.
- **Tree gate.** Let P be the 11 paths the two commits touch. `git diff --quiet milestone/v1.43 spike/220-latest -- P` exited 0. `git diff --name-only land/v1.43-217-218 spike/220-latest` lists exactly P and contains no `.planning/` path. P is:
  - six `lib/` and `test/support/` files;
  - `.github/workflows/ci.yml`;
  - `CONTRIBUTING.md`;
  - `README.md`;
  - `mix.exs`;
  - `test/threadline/ci_workflow_parity_contract_test.exs`.

## Runs

Grant: one push of `spike/220-latest` and one `gh workflow run ci.yml --ref spike/220-latest` were used. The grant allowed 2 pushes and 3 dispatches.

| Dispatch | Run | Head SHA | min | current | latest | Run conclusion |
|----------|-----|----------|-----|---------|--------|----------------|
| 1 (spike) | run 36484105399 | `4a32cbf6ccf026ffd727d2c183d9aa356431f788` (= spike tip) | success (job 109136659655) | success (job 109136659639) | success (job 109136659729) | success |

- **Event:** `workflow_dispatch`, created 2026-09-28T21:08:43Z and completed by 21:18:15Z.
- **Other jobs:** every other job in the run passed. That is 16 jobs including `CI required` (job 109140237771), and it covers Browser E2E, Dialyzer, PgBouncer, Tier A, Credo, formatting, the dependency audit, the hex smoke, release metadata, bump rehearsal, repo hygiene and compile without optional deps. No job was red.

## Latest lane evidence

All quotes come from `gh run view 36484105399 --log --job 109136659729`. Timestamps are kept, ANSI escapes are stripped, and runner paths are omitted.

- **Resolved toolchain (cache-key line):**
  ```
  THREADLINE_BUILD_CACHE=miss key=ubuntu-24.04-otp-OTP-29.1.1-elixir-v1.20.4-otp-29-build-v1-root-test-full-0c194951d817bc592cff4f743beba763f761a313fe126834ac763f71d7579d29-e098d77b7acc4b6c74360c91f1d8df156a90b3285ad667cd492eb224b1287843
  ```
  setup-beam also printed `Installing Erlang/OTP OTP-29.1.1 - built on amd64/ubuntu-24.04`, `emulator version 17.1` and `Using Elixir 1.20.4 (built for Erlang/OTP 29)`, with `version-type: strict`.
- **Service image:**
  ```
  2026-09-28T21:08:49.9980206Z ##[command]/usr/bin/docker pull postgres:18.6
  2026-09-28T21:08:56.7058199Z Status: Downloaded newer image for postgres:18.6
  ```
- **`Compile (warnings as errors)`: success.** The step ran `mix compile --warnings-as-errors` and printed `Compiling 156 files (.ex)` and then `Generated threadline app`. It printed no warning lines.
- **`Verify no compile-connected xref cycles`: success.** It printed `No cycles found`.
- **`Run tests` (`mix verify.test`): success.** The ExUnit summary line was:
  ```
  2026-09-28T21:14:58.6945003Z Result: 2513 passed (9 properties, 2504 tests), 3 excluded
  ```
- **Warnings in `Run tests`: 25 `warning:` lines, all non-fatal (D-05).**
  - **20 are test-file warnings.** This matches plan 01's local count. They break down as:
    - 1 unused `require Logger` at `test/mix/tasks/threadline.incident_test.exs:6`;
    - 17 comparison-between-distinct-types warnings;
    - 1 clause-will-never-match warning;
    - 1 incompatible-types warning. This is the deliberate FunctionClauseError test for `Threadline.Export.format_changes_iodata/3`.
  - **1 is ExUnit's `:test_load_filters` notice.**
  - **4 are runtime `the log level :warn is deprecated` warnings.** They come from the ecto_sql dependency, not from our code.

## Pre-spike vs CI

| Item | Plan 01 local pre-spike | CI (run 36484105399, latest job) |
|------|-------------------------|----------------------------------|
| Toolchain | Elixir 1.20.4 / OTP 29.1.1. Erlang was built from source on macOS | Elixir v1.20.4-otp-29 / OTP-29.1.1, prebuilt by setup-beam for ubuntu-24.04 |
| PostgreSQL | `postgres:18.6` container, server_version 18.6 | `postgres:18.6` service image |
| Compile `--warnings-as-errors` | exit 0 | success |
| `verify.xref_cycles` | No cycles found | No cycles found |
| Suite | `Result: 2509 passed (9 properties, 2500 tests), 3 excluded` | `Result: 2513 passed (9 properties, 2504 tests), 3 excluded` |
| Test-file warnings | 20 | 20 |
| Prediction | green, with residual risk from the Linux prebuilt OTP and flakes | green; neither risk showed up |

The CI run has 4 more tests than the local run, and that is expected. The local run was on plan 01's tree, before commit A. Commit A adds 6 `test "` blocks to `ci_workflow_parity_contract_test.exs` and removes 2, a net of +4. The spike's `test/` tree is byte-identical to `milestone/v1.43`'s.

## Classification

**No failures, so there is nothing to classify.**

- The D-11 green bar was met in one cited run, run 36484105399. That run passed `Run test suite (latest)`, which covers compile `--warnings-as-errors`, `verify.xref_cycles` and `verify.test`. It also passed `Run test suite (min)` and `Run test suite (current)`.
- The flake re-dispatch was not spent. The Flake Detection runs 36391367194 and 36359135268 were not needed.
- No fix cycle ran. There was no `mix.lock` change, no dependency bump, and no version-conditional code.

## Cost

Billed minutes are counted per job as ceil((completedAt − startedAt) / 60 s), using the `gh run view 36484105399 --json jobs` data.

| Job | Duration | Billed min (measured) |
|-----|----------|-----------------------|
| Run test suite (latest), job 109136659729 | 378 s | **7** |
| Run test suite (min), job 109136659655 | 397 s | 7 |
| Run test suite (current), job 109136659639 | 492 s | 9 |
| **Whole run, 16 jobs** | 49.3 unrounded runner-min | **58** |

- **Estimate:** about +6 billed runner-minutes per run for the latest lane, taking a warm p50 of about 49 to about 55 [inference] (D-07, from 219-REMEASURE §2).
- **Measured:** the latest job billed **7** minutes, and the whole run billed **58**.
- **The run was cold.** It was the first dispatch on a new ref, and all three verify-test lanes printed `THREADLINE_BUILD_CACHE=miss`. The latest lane also paid for `Compile dependencies on build cache miss`.
- **Compared with the cold baseline.** 219-REMEASURE's cold set has a billed p50 of 51 (n=2, run 36447911272), so this run is +7. That is consistent with the ~+6 warm estimate plus a cold-miss premium [inference: n=1, cold, not a warm measurement]. The warm per-run cost of the latest lane has not been measured yet. The first warm runs on main after landing will show it.

## Outcome

GREEN

The newest toolchain passed on its exact pins in run 36484105399: Elixir 1.20.4 / OTP 29.1.1 / PostgreSQL 18.6 on ubuntu-24.04, with `version-type: strict`. Compile `--warnings-as-errors`, `verify.xref_cycles` and `verify.test` all passed. Min and current were green in the same run. Plan 04 can cherry-pick the two spike commits onto `land/v1.43-217-218`.

## Landing

The GREEN branch of plan 04. `land/v1.43-217-218` (PR #60) was fast-forwarded to the spike tip, with no code edits.

- **Push.** The orchestrator ran it on 2026-09-28 under the maintainer's own grant. It fetched `origin/land/v1.43-217-218` at `fcb22e00c4dc80f9a05a242ccb11b2136dfaaaa2`, confirmed the fast-forward with `git merge-base --is-ancestor`, and ran `git push origin spike/220-latest:land/v1.43-217-218`. The result was `fcb22e00..4a32cbf6`.
- **Landed SHA:** `4a32cbf6ccf026ffd727d2c183d9aa356431f788`. PR #60 gained `56015527 refactor(220)` and `4a32cbf6 ci(220)`.
- **Local re-check after the push:**
  - `fcb22e00` is an ancestor of the new head, so the push was a fast-forward.
  - `56015527` and `4a32cbf6` have the same `git patch-id --stable` as plan 01's `17a7faa5` and plan 02's `77ff2392`.
  - 10 of the 11 touched paths are byte-equal to `milestone/v1.43`. The 11th, `mix.exs`, differs only in `@version`: the landing branch carries release-please's `0.11.1` bump, which predates this phase. The phase's `mix.exs` hunk is identical on both.
  - `fcb22e00..4a32cbf6` touches no `.planning/` path.
  - The four CI contract test files passed: 108 tests, 0 failures. `actionlint -shellcheck=` on the landed `ci.yml` was clean, and both fail-closed functions (`voting_lane_errors/1`, `postgres_image_errors/1`) are present.
- **PR #60 run: run 36487483472.** The event was `pull_request`, headSha `4a32cbf6ccf026ffd727d2c183d9aa356431f788` (the landed SHA). It was created 2026-09-28T21:38:47Z and completed with conclusion **success**. All 16 jobs passed.

| Check | Job ID | Conclusion |
|-------|--------|------------|
| `CI required` | 109150727021 | success |
| `Run test suite (latest)` | 109147800434 | success |
| `Run test suite (min)` | 109147800262 | success |
| `Run test suite (current)` | 109147800283 | success |

- **The latest lane on the PR run** printed `Result: 2513 passed (9 properties, 2504 tests), 3 excluded`, the same count as the spike run. It printed `THREADLINE_BUILD_CACHE=miss`, which is expected because the `pull_request` ref's cache scope is new.
- **Cost:** 53 billed runner-minutes for the whole run, measured as the per-job ceil of (completedAt − startedAt). That is 44.4 unrounded. The latest lane billed 6 minutes (358 s). This is still a cold-miss run, not the warm measurement.
- **Cleanup:**
  - The remote `spike/220-latest` was deleted by the orchestrator (`git push origin --delete spike/220-latest`), and `git ls-remote` no longer lists it.
  - `git worktree remove /tmp/threadline-spike-220` was run.
  - `git branch -D spike/220-latest` was run.
  - `git fetch origin land/v1.43-217-218:land/v1.43-217-218` was run, so the local ref equals origin at `4a32cbf6`.
  - The scratch dirs `/private/tmp/threadline-220-latest-build` and `/private/tmp/threadline-220-spike` were removed.
- **Correction to `## Branch and commits` above.** The earlier tree gate said `git diff --quiet milestone/v1.43 spike/220-latest -- P` exited 0. Under zsh, an unquoted multi-line `$P` is not word-split. That makes the pathspec a single non-matching path, so the check passes vacuously. Re-run with proper splitting, the gate holds for 10 of the 11 paths, and `mix.exs` differs only by the pre-existing `@version` bump described above.
