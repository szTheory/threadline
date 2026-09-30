---
phase: 218-ci-economy-remove-waste
verified: 2026-09-27T23:10:00Z
status: passed
score: 12/12 must-haves verified
covered_files: [".github/workflows/branch-protection.yml", ".github/workflows/browser-full.yml", ".github/workflows/ci.yml", ".github/workflows/community-health.yml", ".github/workflows/deps-health.yml", ".github/workflows/flake-detection.yml", ".github/workflows/release.yml", ".planning/phases/218-ci-economy-remove-waste/218-01-PLAN.md", ".planning/phases/218-ci-economy-remove-waste/218-01-SUMMARY.md", ".planning/phases/218-ci-economy-remove-waste/218-02-PLAN.md", ".planning/phases/218-ci-economy-remove-waste/218-02-SUMMARY.md", ".planning/phases/218-ci-economy-remove-waste/218-03-PLAN.md", ".planning/phases/218-ci-economy-remove-waste/218-03-SUMMARY.md", ".planning/phases/218-ci-economy-remove-waste/218-04-PLAN.md", ".planning/phases/218-ci-economy-remove-waste/218-04-SUMMARY.md", ".planning/phases/218-ci-economy-remove-waste/218-05-PLAN.md", ".planning/phases/218-ci-economy-remove-waste/218-05-SUMMARY.md", ".planning/phases/218-ci-economy-remove-waste/218-06-PLAN.md", ".planning/phases/218-ci-economy-remove-waste/218-06-SUMMARY.md", ".planning/phases/218-ci-economy-remove-waste/218-07-PLAN.md", ".planning/phases/218-ci-economy-remove-waste/218-07-SUMMARY.md", ".planning/phases/218-ci-economy-remove-waste/218-08-PLAN.md", ".planning/phases/218-ci-economy-remove-waste/218-08-SUMMARY.md", "CONTRIBUTING.md", "bin/browser-full-projects", "bin/ci-sha-gate", "bin/classify-flake-run", "bin/upsert-ci-issue", "bin/verify-dialyzer-slice", "examples/threadline_phoenix/e2e/playwright.config.ts", "guides/upgrade-path.md", "mix.exs", "scripts/ci/README.md", "test/support/ci_issue_pairing.ex", "test/test_helper.exs", "test/threadline/browser_full_projects_contract_test.exs", "test/threadline/ci_all_dedup_contract_test.exs", "test/threadline/ci_coverage_doc_contract_test.exs", "test/threadline/ci_issue_upsert_contract_test.exs", "test/threadline/ci_sha_gate_contract_test.exs", "test/threadline/ci_topology_contract_test.exs", "test/threadline/ci_workflow_parity_contract_test.exs", "test/threadline/deps_health_doc_contract_test.exs", "test/threadline/dialyzer_slice_contract_test.exs", "test/threadline/flake_classifier_contract_test.exs", "test/threadline/release_control_plane_contract_test.exs", "test/threadline/upgrade_path_doc_contract_test.exs", "test/threadline/zero_skips_contract_test.exs"]
covered_digest: "v2:sha256:5de5c8f07a0518d0eb7bd076685378c52328a1f10f790d901a2e13cba810ce7b"
behavior_unverified: 0
overrides_applied: 0
coincidental_reliance_items:
  - truth: "SC5 / ECON-07: the re-measurement doc's per-run ci.yml figures describe the code on this branch"
    reason: undeclared-precondition
    harden: "The eight ci.yml samples ran before the review-fix commits (955afd33..7b50e442). They still describe HEAD only because those commits changed no ci.yml line (checked with git diff --stat). The first post-merge push run should re-confirm the per-run figure, as 218-REMEASURE already says for the push unit."
---

# Phase 218: CI Economy: Remove Waste Verification Report

**Phase goal:** Every remaining CI minute buys a distinct signal, and the savings are measured against the baseline.
**Verified:** 2026-09-27
**Status:** passed
**Re-verification:** No. This is the initial verification.

Everything was checked in the main checkout on `milestone/v1.43` at `fb58390b`, against the code rather than the SUMMARY claims. I made one GitHub API call, a single read-only GraphQL query for the state of #28 and #36. There were no GitHub writes.

## Goal Achievement

### Observable Truths (ROADMAP success criteria, merged with the plan must-haves)

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | SC1 / ECON-01: Flake Detection runs weekly plus on dispatch, with 10–15 repeats sized from measured iteration time | ✓ VERIFIED | The workflow has `workflow_dispatch` plus `cron: "0 7 * * 1"` and no daily cron. The mix.exs alias is `verify.flake: ["test --repeat-until-failure 12"]`. 12 is within the 10–15 bound; it was resized from 15 after run 36359135268 hit the budget (218-08 deviation 3). The header arithmetic is 269 + 12 × 214 = 2,837 s, and Test 6 in `flake_classifier_contract_test.exs` pins the sizing (at most 15, with 10% headroom), with mutation controls. |
| 2 | SC1: the step timeout is shorter than the job timeout, so classify and report always run | ✓ VERIFIED | The budget is `timeout --signal=TERM --kill-after=60s 55m`, inside step `timeout-minutes: 58`, inside job `timeout-minutes: 70`. The repeat step runs `set +e` and always writes `exit_code=` and `elapsed_s=`. The classify, issue, close and fail steps are all `always()`-gated. |
| 3 | SC1: skips an unchanged green SHA and exits `broken-upstream` when CI on that SHA is red | ✓ VERIFIED | `bin/ci-sha-gate --workflow flake-detection.yml ... --upstream ci.yml` is wired, and every heavy step carries `if: steps.gate.outputs.decision == 'run'`. `ci_sha_gate_contract_test.exs` is a fake-gh decision table: skip only on `schedule` with an own-workflow success on the exact `head_sha`, and fail-open to `run` on API errors. The classifier checks `GATE_DECISION` before the exit code. |
| 4 | SC1: a timeout is reported as inconclusive, and there is no false "no header" | ✓ VERIFIED | `bin/classify-flake-run` maps 124, and 137 with elapsed ≥ budget, to `inconclusive`. Zero headers gives `unknown` with reason "timed out before the suite started". The issue body is driven by `REASON`, has an `inconclusive` arm, and no longer carries the hard-coded no-banner sentence. In real CI, run 36359135268 classified `inconclusive (completed iterations: 16, exit: 124)`. |
| 5 | SC1: contract-compliant cache key, and the anti-regression grep covers all workflows | ✓ VERIFIED | The flake cache key is `ubuntu-24.04-<otp-version>-elixir-<elixir-version>-mix-deps-<lock hash>`. `ci_workflow_parity_contract_test.exs` loops over `all_workflows()` for the OS-family context check, with a flake-detection injection control. `grep runner.os .github/workflows/` finds nothing. |
| 6 | SC2 / ECON-02: `bin/upsert-ci-issue` closes a tracking issue when its lane goes green (table test), and #28 and #36 are resolved | ✓ VERIFIED | `--close` covers 0 matches (action=none), 1 match (comment then close) and 2+ matches (ambiguous, exit 1), plus a metacharacter row, in `ci_issue_upsert_contract_test.exs`. It is wired to close only on `clean` (deps-health), `pass` (flake) and `success() && decision == 'run'` (Browser-full). Live GraphQL read: #28 CLOSED/COMPLETED at 2026-09-28T01:01:34Z and #36 CLOSED/COMPLETED at 2026-09-28T01:52:01Z, matching the green runs 36363979144 and 36364688861 cited in 218-REMEASURE §7. |
| 7 | SC2 / ECON-03: a release PR head SHA gets one CI run, through a deterministic PAT guard, and the contract is extended | ✓ VERIFIED | `release.yml` has job env `RELEASE_PAT_CONFIGURED: ${{ secrets.RELEASE_PLEASE_TOKEN != '' }}` and the dispatch step's `if: env.RELEASE_PAT_CONFIGURED != 'true'`. The job keeps `needs: [release-please, sync-release-pr-pins]`, the `always()` job `if:` and its permissions. It has no run-query step. `release_control_plane_contract_test.exs` passes with mutation controls, and actionlint accepts the file. The one-run outcome itself can only be observed at the next release cycle and is recorded as [inference] from the double-dispatch pair (run 36256339043 / run 36256344029). See Info 1. |
| 8 | SC3 / ECON-04: on push, Browser-full runs only the projects ci.yml does not, and a contract test proves that CI's set plus Browser-full's equals the config | ✓ VERIFIED (see Warning 1) | Live `bin/browser-full-projects` output: `--project=` graded-capture, refute-capture, route-capture and storybook-capture. `--list ci` gives desktop-chromium, mobile-chromium, tier-a-capture and tier-a-capture-light. The union equals `--list config`, and the two sets are disjoint. browser-full.yml has no literal `--project`, and it captures the script output before the run, refusing an empty list. `browser_full_projects_contract_test.exs` passes (union, disjointness, derivation mutations, and the WR-05 conditional-flag refusals). |
| 9 | SC3: the Browser-full nightly skips an already-green SHA | ✓ VERIFIED | Gate step `bin/ci-sha-gate --workflow browser-full.yml --sha ... --event ...`, with every heavy step gated on `run` and `actions: read` granted. Skip is reachable only on `schedule`, and this is table-tested in `ci_sha_gate_contract_test.exs`. |
| 10 | SC4 / ECON-05: `:live_dialyzer` is excluded from default `mix test` and runs only in the PLT-cached verify-dialyzer job, with test_helper, CONTRIBUTING and the topology test changed together, and it is a real proof | ✓ VERIFIED | test_helper excludes `live_dialyzer: true` in both branches and stores the list under `:default_test_excludes`. The only ci.yml runner of the tag is verify-dialyzer's `Live Dialyzer slice proof (fails closed)` step, which runs after the PLT steps. Commit 15d7f521 changes ci.yml, CONTRIBUTING, mix.exs, test_helper, zero_skips, the topology test and the dedup test together. **Fail-closed spot check:** raw output holding only `:dialyzer.run error: Could not read PLT file ...` gives exit 1 ("Dialyzer did not complete"), and empty raw output gives exit 1. The live `MIX_ENV=test mix verify.dialyzer_slice` run against the real PLT printed `17 tests, 0 failures, 16 excluded`. |
| 11 | SC4 / ECON-06: verify-mechanical and the capture lane's trailing mechanical step are gone, the alias is kept, and each removal has a "still caught by job Y on trigger Z" line | ✓ VERIFIED | The ci.yml job keys and header list 13 voting jobs plus ci-required, with no verify-mechanical, verify-docs or verify-hex-package. The `verify.mechanical` alias is still in mix.exs:162. `# Removed:` comments sit at each former location. CONTRIBUTING has `### Removed CI proofs and what still catches them`, with four still-caught-by lines. The dominators exist and are unconditional: `verify_release/1` contains `MIX_ENV=dev mix docs --warnings-as-errors` and `mix hex.build`, and `bin/verify-bump-rehearsal` runs `run_gate ... mix verify.release`. Its `|| true` does not swallow the failure, because `GATE_STATUS` fails the script at the end. There is no `paths:`, `continue-on-error` or active `allowed-skips`. The roster change is a single commit, b87b4b4e. No stale reference to a removed job id remains outside `.planning/`, tests and changelogs. |
| 12 | SC5 / ECON-07: a re-measurement doc records runner-minute and critical-path deltas against 214, with every figure citing run IDs | ✓ VERIFIED (coincidental-reliance, advisory) | `218-REMEASURE.md` exists, and `check-citations.py` on it exits 0, as does the checker's `--self-test`. Re-running `remeasure-218.py runner-minutes --set post`, `comparable-minutes --set post`, `--set base` and `critical-path --set post` reproduced the doc's figures exactly: 44.4 / 53, 43.7 / 51, 46.3 / 55 and 643 s. The copied tools differ from the 214 originals only in self-path strings and the 21[4-8] exemption, checked with diff. No 218 commit touches the 214 directory. Every projection carries [inference]. |

**Score:** 12/12 truths verified (0 present-but-behavior-unverified)

Behavior-dependent truths (the classifier transitions, the SHA-gate decisions, close-on-green gating and fail-closed Dialyzer) are each backed by a passing table or mutation test, run below. Each also has at least one real CI execution: flake run 36359135268 was `inconclusive` and run 36364688861 was `pass` and closed #36; Browser-full run 36363979144 closed #28; verify-dialyzer ran the live step in eight post-landing runs.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.github/workflows/release.yml` | PAT-absence guard | ✓ VERIFIED | Guard present, wiring unchanged |
| `bin/upsert-ci-issue` | `--close` path | ✓ VERIFIED | Wired in three workflows |
| `bin/verify-dialyzer-slice` | fails closed | ✓ VERIFIED | Spot-checked exit 1 on the error and empty rows |
| `test/test_helper.exs` | `live_dialyzer` excluded, `:default_test_excludes` stored | ✓ VERIFIED | Read by `ci_all_dedup` and `zero_skips` |
| `bin/ci-sha-gate` | green-SHA and broken-upstream decision | ✓ VERIFIED | Used by flake-detection.yml and browser-full.yml |
| `bin/classify-flake-run` | inconclusive, broken-upstream and skip rows, plus a reason | ✓ VERIFIED | Consumed with the `REASON` env |
| `.github/workflows/flake-detection.yml` | weekly bounded lane | ✓ VERIFIED | See truths 1–5 |
| `bin/browser-full-projects` | derived partition | ✓ VERIFIED | Live output checked |
| `.github/workflows/browser-full.yml` | difference run, gate, close-on-green | ✓ VERIFIED | |
| `CONTRIBUTING.md` | Removed-proofs section, CI Coverage partition | ✓ VERIFIED | |
| `218-REMEASURE.md` plus `tools/` | cited deltas | ✓ VERIFIED | Figures regenerated |

### Key Link Verification

| From | To | Via | Status |
|---|---|---|---|
| release.yml | `secrets.RELEASE_PLEASE_TOKEN` | job env boolean read by the step `if:` | WIRED |
| deps-health.yml | bin/upsert-ci-issue | `--close` on `classification == 'clean'` | WIRED |
| ci.yml verify-dialyzer | mix.exs `verify.dialyzer_slice` | `run: mix verify.dialyzer_slice` (MIX_ENV=test) | WIRED |
| mix.exs alias | dialyzer_slice_contract_test | `--only live_dialyzer` | WIRED |
| flake-detection.yml | bin/ci-sha-gate, bin/classify-flake-run | gate decision on heavy steps; `GATE_DECISION`, `EXIT_CODE`, `ELAPSED_S` env | WIRED |
| flake-detection.yml | bin/upsert-ci-issue | close step on `classification == 'pass'` | WIRED |
| browser-full.yml | bin/browser-full-projects | captured flags passed to `mix verify.example_browser` | WIRED |
| bin/browser-full-projects | mix.exs `verify_capture` | tier-a flags via `run: mix verify.capture` | WIRED |
| ci_topology_contract_test | mix.exs `verify_release/1`, bin/verify-bump-rehearsal | dominance pins with mutation controls | WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| 13 phase contract files | `mix test` over release_control_plane, ci_issue_upsert, deps_health_doc, dialyzer_slice, zero_skips, ci_topology, ci_all_dedup, ci_workflow_parity, upgrade_path_doc, flake_classifier, ci_sha_gate, browser_full_projects and ci_coverage_doc | 228 tests, 0 failures, 1 excluded (live_dialyzer) | ✓ PASS |
| Live Dialyzer slice with the real PLT | `MIX_ENV=test mix verify.dialyzer_slice` | 17 tests, 0 failures, 16 excluded | ✓ PASS |
| Verifier fails closed on a PLT error | `bin/verify-dialyzer-slice --fixture ... --raw-output <tmp file with the :dialyzer.run error line>` | exit 1, "Dialyzer did not complete" | ✓ PASS |
| Verifier fails closed on empty output | same, with empty raw output | exit 1, "found 0" completion markers | ✓ PASS |
| Browser-full partition | `bin/browser-full-projects` plus `--list config`, `ci`, `browser-full`, `deps` and `executed` | the four difference projects; union = config | ✓ PASS |
| WR-02 failure-evidence regex against a **real** ExUnit failure transcript | A standalone ExUnit script with one failing test (pinned toolchain), whose log was fed to `EXIT_CODE=124 bin/classify-flake-run` | Log alone (1 header): `broken`. Prefixed with a clean iteration (2 headers): `flaky` | ✓ PASS. This automates the check 218-REVIEW-FIX said needed a human |
| actionlint | `actionlint -shellcheck= .github/workflows/*.yml` | exit 0 | ✓ PASS |
| Repo hygiene | `bin/verify-repo-hygiene` | 4023 files clean, 8 allowlist entries used, 0 inert | ✓ PASS |
| Citations | `check-citations.py 218-REMEASURE.md` and `--self-test` | exit 0 / exit 0 | ✓ PASS |
| Full default suite (run once) | `mix test` | 2488 tests, 1 failure, 3 excluded. The failure is pre-existing and environmental (Info 3). A re-run of that file gives 9 tests, 0 failures | ✓ PASS (no phase-218 regression) |

### Probe Execution

The phase declares no `scripts/*/tests/probe-*.sh` probes. Step 7c does not apply.

### Requirements Coverage

| Requirement | Source plan | Status | Evidence |
|---|---|---|---|
| ECON-01 | 218-05, 218-06 | ✓ SATISFIED | Truths 1–5 |
| ECON-02 | 218-02, 218-06, 218-07, 218-08 | ✓ SATISFIED | Truth 6; #28 and #36 closed, confirmed live |
| ECON-03 | 218-01 | ✓ SATISFIED | Truth 7. All three sub-bullets (guard without run queries, wiring kept, contract extended) are verified in code. The one-run outcome is [inference] until the next release |
| ECON-04 | 218-07 | ✓ SATISFIED | Truths 8–9 (Warning 1) |
| ECON-05 | 218-03 | ✓ SATISFIED | Truth 10 |
| ECON-06 | 218-04 | ✓ SATISFIED | Truth 11. verify-docs and verify-hex-package were also removed with dominance proven on the same triggers (D-10) |
| ECON-07 | 218-08 | ✓ SATISFIED | Truth 12 |

All seven IDs appear in plan frontmatter and in REQUIREMENTS.md, where they are mapped to Phase 218. There are no orphaned requirements.

### Prohibitions (plan `must_haves.prohibitions`)

Each prohibition was resolved against wired enforcement evidence, so none stays flagged:

- A release PR is never left with zero CI runs: the no-PAT path always dispatches, because the job keeps its `always()` and the step `if:` fires when the token is absent. This is pinned by the release contract test.
- Close paths never close on a non-proof: they close only on `clean`, `pass`, or `success() && decision == 'run'`. The pairing helper `test/support/ci_issue_pairing.ex` pins them in three lanes. #28 and #36 were closed by their own lanes' green runs.
- A Dialyzer error never reads as "0 live warnings", as spot-checked above. The negative tests use `@tag :tmp_dir` raw output and never touch `.dialyzer/`.
- No proof was removed without a same-trigger catcher. The topology dominance pins and their mutation controls enforce this, and there is no laundering (`paths:`, `continue-on-error`, `allowed-skips`).
- A green non-proof never concludes green: inconclusive and broken-upstream fail the job. The gate never fails closed into a skip, because an API error gives `run` (table-tested).
- No default-config project is run by neither lane (union contract), and a script failure or empty list never becomes an unrestricted run (captured output, empty-list refusal).
- Projections carry [inference], and the 214 evidence is unmodified: no 218 commit touches `.planning/phases/214-baseline-measurement/`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| Phase diff (non-planning) | — | TBD/FIXME/XXX/TODO/HACK scan of added lines | none found | — |
| `examples/threadline_phoenix/e2e/playwright.config.ts` / Browser-full | refute-capture `dependencies` | ci.yml project re-executed as a setup dependency | ⚠️ Warning 1 | See below |
| `CONTRIBUTING.md` Branch protection section | — | lists six per-job checks next to the "only `CI required`" sentence | ℹ️ Info 2 | Pre-existing doc-truth issue, logged in deferred-items.md |
| `test/threadline/clean_checkout_contract_test.exs` | 338 | `unique_integer` temp name under the system temp dir collides with a stale leftover dir | ℹ️ Info 3 | Pre-existing, outside phase 218 |

**Warning 1: Browser-full re-executes one ci.yml project, tier-a-capture, as a declared dependency.** The `--project` set Browser-full passes is exactly the four-project difference. But refute-capture declares `dependencies: ["tier-a-capture"]` (218-08 deviation 1), so Playwright runs tier-a-capture again inside Browser-full: 5 tests, not 4, in run 36363979144. That is a narrow residual repeat of CI's work. It is necessary, because refute-capture reads the gitignored tier-a cell dirs that only tier-a-capture creates. It is honestly handled: CONTRIBUTING `## CI Coverage` states it, and `browser_full_projects_contract_test.exs` pins `--list deps` and `--list executed` so that any pulled-in project must be a declared dependency edge. It does not undo the ECON-04 saving (18.0 → 6.4 min per run). I judge the success criterion met in intent, because the difference set is exact, contract-proven and derived. A later cleanup could remove the repeat by letting refute-capture produce its own cell directories. This is not a gap under the decision tree.

**Info 1: ECON-03 end-to-end.** "Exactly one CI run per release head" can only be observed at the next release-please cycle. The guard is deterministic, contract-pinned and actionlint-clean, and the pre-change double-dispatch evidence shows where the second run came from. This is not a human item: the next release's run list confirms or refutes it automatically.

**Info 2:** see deferred-items.md (218-04). The live protection and the ruleset require only `CI required`. Phase 221 (CI names) is the candidate owner.

**Info 3: the one full-suite failure is not a phase-218 regression.** `CleanCheckoutContractTest` failed with `File.mkdir!` "file already exists" on `$TMPDIR/threadline-clean-verifier-test-13`, a leftover directory dated 2026-09-24, before this phase began. The name comes from `System.unique_integer([:positive, :monotonic])`, which restarts every VM, so a stale leftover collides. The file was last changed in phase 200. Re-running it gives 9 tests, 0 failures. It is a latent flake worth a one-line fix, a random suffix or `@tag :tmp_dir`, in a later hygiene pass.

**Info 4:** the live slice's `verified slice ... 0 live warnings` line is asserted inside the test and not echoed to the CI log (deferred-items.md 218-08). The CI pass still proves that both strings were printed, because the test asserts them.

### Human Verification Required

None. The one item the review-fix report handed to a human (confirming the WR-02 failure regex against a real ExUnit failure transcript) was automated above and passes.

### Gaps Summary

There are no gaps. All five ROADMAP success criteria and all seven ECON requirements hold in the code, and they are backed by passing contract tests, direct spot checks, reproduced re-measurement figures and live issue state. The warning and info items above are advisory and do not block the phase.

---

_Verified: 2026-09-27_
_Verifier: Claude (gsd-verifier)_
