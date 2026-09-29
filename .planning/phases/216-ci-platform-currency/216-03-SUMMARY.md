---
phase: 216-ci-platform-currency
plan: 03
subsystem: ci
status: complete
tags: [ci, toolchain, setup-beam, release, sparse-checkout, contract-tests]
requires:
  - "216-01 (file-form setup-beam, toolchain contract helpers)"
  - "216-02 (verify-test matrix form, runner_image_errors/2)"
provides:
  - "release.yml sync-release-pr-pins / publish-hex / smoke-published: toolchain-first sparse checkout of .tool-versions (workflow commit), then file-form setup-beam, then the unchanged target-ref checkout"
  - "browser-full, flake-detection, deps-health: file-form setup-beam; resolved-output deps keys (browser-full, flake-detection)"
  - "toolchain_source_errors/3 (+ pin_checkout_errors/2) and all_workflows/0 in the parity test"
  - "Toolchain contract and runner-image check scan every workflow file by glob"
  - "sync-release-pr-pins checkout count == persist-credentials: false count assertion"
affects:
  - "Later CI-economy phase adds the all-workflows OS-family grep (OD-3)"
tech-stack:
  added: []
  patterns:
    - "Toolchain-first sparse checkout: read .tool-versions from the workflow's own commit before switching to a target ref"
key-files:
  created: []
  modified:
    - .github/workflows/release.yml
    - .github/workflows/browser-full.yml
    - .github/workflows/flake-detection.yml
    - .github/workflows/deps-health.yml
    - test/threadline/ci_workflow_parity_contract_test.exs
    - test/threadline/release_control_plane_contract_test.exs
key-decisions:
  - "Assumption A2 confirmed against actions/checkout v5 source before any edit, so the toolchain-first sparse-checkout design (RESEARCH Pattern 3) was used as planned"
  - "toolchain_source_errors/3 runs inside toolchain_contract_errors/1 for every job, not only release jobs"
requirements-completed: [PLAT-01, PLAT-03]
duration: "~30 min"
completed: 2026-09-27
plan_head_before: 97e36278370cae9d79d2d6ab4621584a07dbe1b8
actuals:
  tokens: 4785
  tasks: 2
  commits: 2
coverage:
  - deliverable: "Release ref-switching jobs read .tool-versions from the workflow commit"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#release jobs read the toolchain pin from the workflow's own commit"
        status: pass
      - kind: test
        ref: "test/threadline/release_control_plane_contract_test.exs#the release PR pin-sync job exists, is scoped, and gates the CI bootstrap"
        status: pass
  - deliverable: "Every workflow installs the committed toolchain; BEAM cache keys use resolved outputs"
    human_judgment: false
    verification:
      - kind: test
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#every workflow job installs an exact toolchain and keys caches on it"
        status: pass
      - kind: test
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#the browser and scheduled workflows install the committed toolchain"
        status: pass
      - kind: test
        ref: "test/threadline/ci_workflow_parity_contract_test.exs#no workflow runs a job on the deprecated runner image"
        status: pass
      - kind: command
        ref: "actionlint -shellcheck= clean; full mix test 9 properties, 2303 tests, 0 failures, 2 excluded"
        status: pass
---

# Phase 216 Plan 03: Committed toolchain in every workflow Summary

**The three ref-switching release jobs now sparse-check out `.tool-versions` from the workflow's own commit (credentials not persisted), install it with strict file-form setup-beam, and only then check out the release branch or tag, which is unchanged. browser-full, flake-detection and deps-health install the same pin. Their deps keys name the resolved OTP/Elixir. The toolchain contract and the runner-image check now glob every workflow file, and a new `toolchain_source_errors/3` fails if the toolchain checkout is removed, reordered, or widened.**

## Assumption A2 evidence (actions/checkout v5, fetched 2026-09-26)

- `src/git-source-provider.ts` turns sparse checkout off when the input is absent. So the second, full target-ref checkout in the same workspace restores the whole tree:
  - line 214: `if (!settings.sparseCheckout) {`
  - line 218: `await git.disableSparseCheckout()`
  - lines 221-225 run the non-cone path when cone mode is false: `await git.sparseCheckoutNonConeMode(settings.sparseCheckout)`
- `action.yml` declares both inputs:
  - line 65: `sparse-checkout:`
  - line 70: `sparse-checkout-cone-mode:` (default `true`, hence the explicit `false`)
- Side note: a sparse fetch uses `filter: 'blob:none'` (line 168). The later full checkout lazily fetches blobs while its own auth is active. The repo is public, so later blob reads need no credential.

## Task Commits

1. Task 1 (tracer): `8b4a4858` ci(release): read the toolchain pin from the workflow commit in release jobs
2. Task 2: `0ed0a5c5` ci(toolchain): install the committed toolchain in the browser and scheduled workflows

## Accomplishments

- release.yml:
  - Each of `sync-release-pr-pins`, `publish-hex` and `smoke-published` gains `Read the toolchain pin from this workflow's commit` (`sparse-checkout: .tool-versions`, `sparse-checkout-cone-mode: false`, `persist-credentials: false`, no `ref:`), then `erlef/setup-beam@v1` with `id: beam`, `version-file`, `version-type: strict`.
  - The existing target-ref checkouts are byte-identical. The 4-line credential comment still sits directly above the release-branch checkout.
  - No `permissions` / `concurrency` / `needs:` / `if:` / `secrets.` line changed (diff check = 0).
- browser-full.yml: file-form setup-beam. The deps key is `ubuntu-24.04-${{ steps.beam.outputs.otp-version }}-elixir-${{ steps.beam.outputs.elixir-version }}-mix-deps-…`. The Playwright cache and upload-artifact are untouched.
- flake-detection.yml: file-form setup-beam. The deps key uses the same template instead of the OS-family context, and a one-line comment points at the ci.yml CACHE KEY CONTRACT.
- deps-health.yml: file-form setup-beam; no cache added.
- Parity test:
  - `toolchain_source_errors/3` has 4 mutation controls: toolchain checkout removed, setup-beam below the target checkout, missing `persist-credentials: false`, and a pin checkout naming another file. It is wired into `toolchain_contract_errors/1`.
  - `all_workflows/0` feeds the live contract and the runner-image check.
  - Task 2 adds 4 mutation controls, including a synthetic new workflow with an unknown cache path on a lockfile-only key (fails closed).
- Release contract: the checkout count equals the `persist-credentials: false` count in sync-release-pr-pins (2 = 2), with a mutation control that drops the flag from the release-branch checkout.

## Verification

- Task 1 `<verify>` passed. It was re-run verbatim after the commit as the tracer feedback gate (exit 0): "Tracer verified end-to-end — expanding".
- Task 2 `<verify>` passed:
  - contract files: 49 tests, 0 failures
  - full `mix test`: 9 properties, 2303 tests, 0 failures, 2 excluded
  - `verify.format` and `verify.credo` clean
  - no quoted OTP/Elixir setup-beam input and no deprecated image label in any workflow
  - HEAD file set matches exactly
- Acceptance counts:
  - release.yml: sparse-checkout = 3, version-file = 3, `otp-version|elixir-version` = 0
  - repo-wide: `version-file: .tool-versions` = 19; `id: beam` = 20
  - flake-detection has no OS-family context; Playwright key lines = 2; deps-health cache/path = 0
  - `toolchain_source_errors` defined once
  - in publish-hex and smoke-published, the sparse-checkout line comes before `id: beam`, which comes before the target `ref:` line

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `mix verify.credo` was already red on HEAD**
- **Found during:** Task 1
- **Issue:** `credo --strict` reported "Function body is nested too deep" in `runner_image_errors/2`, which plan 02 added. Checking HEAD's copy of the file alone reproduced it. My first draft of `toolchain_source_errors/3` hit the same check.
- **Fix:** Flattened `runner_image_errors/2` into a map/reject/filter pipeline (same behaviour; its mutation controls still fail as expected). Moved the checkout-ref branch into `pin_checkout_errors/2`.
- **Files modified:** test/threadline/ci_workflow_parity_contract_test.exs
- **Commit:** 8b4a4858

### Acceptance-criterion note (plan text, not code)

- The criterion `awk … sync-release-pr-pins … | grep -c 'persist-credentials: false'` = 2 prints **3**. The third match is the kept comment line `# persist-credentials: false keeps the token out of .git/config.`, which the plan requires to stay byte-identical. On HEAD before this plan the same command printed 2 (comment plus one flag).
- The intended invariant holds: there are exactly 2 real flag lines (job-block lines 27 and 42), and the contract test counts only flag lines (`^\s+persist-credentials: false$`), giving 2 checkouts = 2 flags.
- Nothing was weakened or edited to force the count.

## Known Stubs

None.

## Threat Flags

None. The only new surface is the toolchain checkout, which is covered by T-216-07 and T-216-08 (both mitigated and classifier-enforced).

## Self-Check: PASSED

- Files: all six modified files exist.
- Commits: 8b4a4858 and 0ed0a5c5 are present in `git log`.
- `git rev-list --count 97e36278..HEAD` = 2.
