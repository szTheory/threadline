---
phase: 219-deps-only-build-cache
verified: 2026-09-28T19:30:00Z
status: passed
score: 4/4 roadmap success criteria verified (plus all plan must-have truths)
covered_files:
  - .github/workflows/ci.yml
  - .planning/phases/219-deps-only-build-cache/219-01-PLAN.md
  - .planning/phases/219-deps-only-build-cache/219-01-SUMMARY.md
  - .planning/phases/219-deps-only-build-cache/219-02-PLAN.md
  - .planning/phases/219-deps-only-build-cache/219-02-SUMMARY.md
  - .planning/phases/219-deps-only-build-cache/219-03-PLAN.md
  - .planning/phases/219-deps-only-build-cache/219-03-SUMMARY.md
  - .planning/phases/219-deps-only-build-cache/219-REMEASURE.md
  - .planning/phases/219-deps-only-build-cache/tools/check-citations.py
  - .planning/phases/219-deps-only-build-cache/tools/collect-ci-runs.sh
  - .planning/phases/219-deps-only-build-cache/tools/remeasure-219.py
  - .planning/phases/219-deps-only-build-cache/tools/summarize-ci.py
  - CONTRIBUTING.md
  - test/threadline/ci_workflow_parity_contract_test.exs
covered_digest: "v2:sha256:95fea624f0c1fef33e9783cdbed56a2c28ba1cab4d8f943e37d626c55e7fd366"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 219: Deps-Only Build Cache Verification Report

**Phase Goal:** Test jobs stop recompiling dependencies on every run without ever serving a stale or wrong artifact
**Verified:** 2026-09-28T19:30:00Z
**Status:** passed
**Re-verification:** No, initial verification

## Goal Achievement

The goal has two halves, and each was checked against code and against CI runs, not against the SUMMARY claims.

- **Stop recompiling dependencies.** In the post-review-fix run 36465241600 (head 0204690d, whose ci.yml, CONTRIBUTING.md and contract test match milestone/v1.43 HEAD byte for byte), every cached job logged a hit, and every `Compile … on … miss` and `Save …` step concluded `skipped`. In the five cached jobs, the only `Generated … app` lines are `threadline` and `threadline_phoenix`. The uncached bump rehearsal still compiles every dependency in the same run, which is the contrast.
- **Never serve a stale or wrong artifact.** Keys are exact (no `restore-keys` on any `_build` restore). They carry the runner, the resolved OTP/Elixir, `build-v1`, the project, `MIX_ENV`, `full`, and the project's own lock and config hashes. First-party build dirs are `rm -rf`'d unconditionally before the save and before the compile, and the logs show threadline (and threadline_phoenix) recompiled on every hit. Saves run only on a miss, after a successful `deps.compile`, with no `always()` and no `continue-on-error`. The live contract test enforces all of these rules, and a mutation control proves each rule red.

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC1 | Test jobs restore a deps-only `_build` cache and a separate example-app cache via split restore/save, keyed exactly on runner, resolved OTP/Elixir, MIX_ENV, profile, lock and config, with no `restore-keys` | VERIFIED | Static: `.github/workflows/ci.yml` verify-test root restore at L373-378 and save at L412-417; example restore L446-454 and save L478-485 (both lane-guarded); verify-example-browser L601-638; verify-capture L751-788; verify-pgbouncer-topology restore-only at L879-884. Every `_build` restore uses `actions/cache/restore@v5`, every save uses `actions/cache/save@v5` keyed `${{ steps.<id>.outputs.cache-primary-key }}`, and none has `restore-keys`. The only `restore-keys` in the file belong to the `deps` source cache (pre-existing, corrected by `mix deps.get`), the Playwright cache and the Dialyzer PLT. Runtime: run 36465241600 logged `THREADLINE_BUILD_CACHE=hit` for Test (current), Test (min) and PgBouncer, and `THREADLINE_EXAMPLE_BUILD_CACHE=hit` for Test (current), Browser E2E and Capture. The rendered keys end in `-full-<64hex>-<64hex>` (0c194951…/e098d77b… root, 831b9543…/ccc5e458… example). The min lane has its own OTP-26/1.15.8 key and prints no example line (lane guard, IN-03). |
| SC2 | Project's own build (`_build/$MIX_ENV/lib/threadline`) removed before compiling in every cached job | VERIFIED | `rm -rf "_build/${MIX_ENV:?}/lib/threadline"` at ci.yml L410 (verify-test) and L907 (pgbouncer), with no `if:`, placed after deps.compile and before save/compile. The example rm removes `lib/threadline` and `lib/threadline_phoenix` under `examples/threadline_phoenix/_build/${MIX_ENV:?}` at L475-476, L628-629 and L778-779. Contract rules `rule=order`, `rule=rm-target`, `rule=rm-unconditional` and `rule=rm-env-guard` are asserted live, and mutation controls prove each red. Runtime (run 36465241600): `Generated threadline app` appears in the compile/consumer step of every cached job, and `Generated threadline_phoenix app` appears in the example consumers. |
| SC3 | `verify-compile-no-optional` and the `release.yml` publish path contain no cache step, and the parity contract test asserts all of the above rules | VERIFIED | verify-compile-no-optional (ci.yml L296-313) has checkout, setup-beam, `mix deps.get` and `mix verify.compile_no_optional` only; its old `Cache deps` step was deleted. release.yml has no git change in phase 219, and a grep for `cache` finds only comments and `git diff --cached`. `test/threadline/ci_workflow_parity_contract_test.exs` `describe "deps-only build cache contract"` asserts `build_cache_errors(all_workflows(), CONTRIBUTING) == []` against the live files (L529-535). Also live: the D-17 security subset (L522), `rule=release-cache` and `rule=no-optional-cache`, live and fixture mutation controls (L537, L689, L709, L720), and a YamlElixir anti-drift assert (L541). Local run: 104 tests, 0 failures across the four CI contract test files. |
| SC4 | A before/after measurement cites run IDs and records the per-job and critical-path delta against the Phase 214 baseline | VERIFIED | `219-REMEASURE.md` §3 and §9: critical-path p50 623 → 547 s, −76 s vs BASE-01 (run 36256339043 vs 36455432448), −96 s vs 218. §4a gives the per-job p50 for every cached job against 214 and 218. Uncached jobs are in §4c. Test (min) +23 s vs 218 and Capture's noise level are recorded, not dropped. `check-citations.py` exits 0. `remeasure-219.py samples`, `critical-path --set warm` and `runner-minutes --set post218` rerun locally and reproduce the published figures. PR runs 36446346094 (cold) and 36447864779 (warm) are confirmed `success` via `gh run view`. |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Plan must-have truths (merged)

| Plan | Truth group | Status | Evidence |
|---|---|---|---|
| 219-01 | `build_cache_errors/2` pure function, `rule=<id>` messages, `@build_cache_jobs` (4 entries), `@build_cache_exclusions`, `@build_key_segments`/`@build_key_forbidden`, order classifier, save/guard/continue-on-error rules, D-09/D-17 env rules, docs parity, D-21 fixture + controls, `insert_step_in_job` live-needle controls, `rule=inline` | VERIFIED | The definitions are in the test file (L402-520, L1671+, L2824+). Every listed rule id is present, and the controls are asserted on the fixture, hybrid and live maps. All pass locally. |
| 219-02 | Exact-keyed caches in 4 jobs / 5 lanes; pgbouncer restore-only with split bootstrap (D-10: `Wait for Postgres and PgBouncer` after compile, bootstrap keeps `mix run priv/ci/topology_bootstrap.exs`); job-level `MIX_ENV: test` on browser and capture; no-optional cache removed; no `always()`, `continue-on-error`, new permissions or composite action; D-18 log lines; ci.yml comment + CONTRIBUTING `### Dependency build cache` | VERIFIED | ci.yml read directly (the line refs are above). The diff of `.github/` since 72790694~1 touches only ci.yml. setup-beam `uses:` count is still 11 (12 grep hits include one comment, the same as before 219). CONTRIBUTING L740+ carries both tables, the rm literals and the runbook. |
| 219-03 | Tools copied with only self-path + `21[4-9]` diffs; `remeasure-219.py` self-test; ≥2 cold + ≥8 warm; hit/miss/in-run labels from committed JSON; D-26 figures tagged `[inference]`; cache sizes vs 10 GB | VERIFIED | `diff` against the 218 tools shows exactly those lines. Both `--self-test`s pass. There are 2 cold and 8 warm samples, reproduced by `samples`. Six `build-v1` entries hold 78.8 MB (0.8 % of 10 GB). There are no phase-219 commits under the 214 or 218 phase dirs. |

### Prohibitions

Every prohibition below is enforced by a named test or a deterministic check, and none relies on judgment alone.

| Prohibition | Disposition | Enforcement evidence |
|---|---|---|
| First-party compiled code never written into or served from a build cache | enforced | Contract `rule=order` and `rule=rm-*`, with live controls. Runtime: threadline and threadline_phoenix are recompiled on every warm hit (run 36465241600, run 36455432448). |
| No `_build` restore from a near-miss key (`restore-keys`) | enforced | Contract `rule=restore-keys` (live + control). No `restore-keys` on any `_build` restore in ci.yml. |
| Release path and verify-compile-no-optional never gain a cache step | enforced | Contract `rule=release-cache`, `rule=no-optional-cache` and the security control test at L557. |
| A failed or partial deps.compile never saved | enforced | Contract `rule=save-guard` and `rule=continue-on-error`, with controls. |
| A projection is never presented as a measurement | enforced | `check-citations.py` exits 0, and every D-26 row carries `[inference]`. |
| 214/218 frozen evidence never modified | enforced | `git log 72790694~1..HEAD` on both phase dirs is empty. |
| A noise-level job is never silently dropped | enforced | REMEASURE §4b/§8 records Test (min) +23 s and Capture as noise-level. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.github/workflows/ci.yml` | exact-keyed root + example deps-only caches | VERIFIED | Contains `build-v1-root-` and `build-v1-example-` in 5 lanes. Wired: executed in CI run 36465241600. |
| `CONTRIBUTING.md` | `### Dependency build cache` section + runbook | VERIFIED | L740. The live `rule=doc-contributing` checks its table against the contract attributes. |
| `test/threadline/ci_workflow_parity_contract_test.exs` | live build cache contract + controls + anti-drift | VERIFIED | `build_cache_errors(all_workflows()` at L530. Passes. |
| `tools/check-citations.py` | accepts 219 | VERIFIED | `21[4-9]` |
| `tools/remeasure-219.py` | labels from committed JSON | VERIFIED | Self-test ok. Reproduces the REMEASURE tables. |
| `219-REMEASURE.md` | cited before/after | VERIFIED | Citation check exits 0. |

### Key Link Verification

| From | To | Via | Status |
|---|---|---|---|
| ci.yml | parity contract test | `build_cache_errors(all_workflows(), contributing) == []` reads the live files through `File.read!` | WIRED |
| CONTRIBUTING.md | `@build_cache_jobs` / `@build_cache_exclusions` | table set-equality in `contributing_build_cache_errors/1` | WIRED |
| `_build` restore | `_build` save | save key `${{ steps.build-restore.outputs.cache-primary-key }}` / `example-build-restore` | WIRED |
| REMEASURE | 214-BASELINE / 218 raw data | `remeasure-219.py --set base/post218` reproduces BASE-01 46.3/55 and 218 44.4/53 | WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Contract suite green | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/ci_action_runtime_contract_test.exs test/threadline/browser_full_projects_contract_test.exs` | 104 tests, 0 failures | PASS |
| Warm hit on post-fix code | `gh run view 36465241600 --log` grep `THREADLINE_(EXAMPLE_)?BUILD_CACHE=` | 6 hit lines, 0 miss; min lane prints no example line | PASS |
| No dep compile on hit, first-party recompiled | same log, `Generated … app` in cached jobs | only threadline / threadline_phoenix | PASS |
| Miss/save steps skipped on hit | `gh run view 36465241600 --json jobs` | all `Compile … miss` and `Save …` steps `skipped` | PASS |
| Cold run exists and saves | 219-REMEASURE §6, run 36446346094 | `THREADLINE_BUILD_CACHE=miss`, 38 dep banners | PASS (cited) |
| PR runs green | `gh run view 36446346094 / 36447864779 / 36465241600` | all `completed success` | PASS |
| Citation check | `python3 …/check-citations.py …/219-REMEASURE.md` | exit 0 | PASS |
| Tool self-tests | `check-citations.py --self-test`, `remeasure-219.py --self-test` | ok | PASS |

### Probe Execution

The phase declares no `scripts/*/tests/probe-*.sh` probes. SKIPPED.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| CACHE-01 | 219-01, 219-02, 219-03 | Test jobs restore a deps-only `_build` cache and a separate example-app cache | SATISFIED | SC1-SC4 above. REQUIREMENTS.md already marks it `[x]` and the traceability row reads `Complete`. |

No orphaned requirements: REQUIREMENTS.md maps only CACHE-01 to Phase 219.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| (none) | - | No TBD/FIXME/XXX/TODO/HACK added in the phase 219 diff of ci.yml, CONTRIBUTING.md or the contract test, or in the tools | - | - |

### Informational notes (non-blocking)

- PR #60 is still OPEN (`gh pr view 60`: state OPEN, head 0204690d). Its runs are green. No success criterion requires a merge. REMEASURE §9 labels the "main scope makes a typical PR warm" claim `[inference]`, pending the first post-merge PR run.
- The 10 measured samples ran the plan-02 code (cherry-pick 7dbad5ff) before the review fixes (de860adc..fbd5a461). Run 36465241600 on the post-fix head re-proves the warm behaviour on the code that matches HEAD.
- The local Postgres is saturated by another project's test run, so DB-backed suites were not re-run locally. This phase only needs the pure contract tests locally, and those passed. CI run 36465241600 is the authority for the DB-backed suites and is green.
- Test (min)'s job-level delta vs 218 is +23 s. The compile step itself dropped −33 s, and the suite slowdown sits inside ExUnit's own timer, outside the cache. REMEASURE records this honestly.

### Human Verification Required

None. Every truth is backed by a named test, a deterministic script, or a cited CI run.

### Gaps Summary

No gaps. The phase goal is achieved:
- Dependency compilation is skipped on warm runs in all five cached lanes, as the CI logs show.
- Stale or wrong artifacts are excluded structurally by exact keys, no `restore-keys`, an unconditional rm of the first-party builds, and saves only on a miss. The live contract enforces all of this, and each rule is mutation-proven.

---

_Verified: 2026-09-28T19:30:00Z_
_Verifier: Claude (gsd-verifier)_
