---
phase: 202-release-0-10-0
plan: 04
subsystem: infra
tags: [release, hex, github-actions, gh-cli, contract-tests, publish-gate]

requires:
  - phase: 202-release-0-10-0
    provides: "202-01's THREADLINE_HEX_EVALUATOR_MODE / THREADLINE_PUBLISHED_VERSION mode switch in priv/ci/hex_evaluator"
  - phase: 202-release-0-10-0
    provides: "202-02's tarball exclusions and pin automation; 202-03's changelog ownership split"
provides:
  - "`bin/verify-environment-protection` — a fail-closed live read of the production-hex required-reviewer rule, with a second half tying it to the environment the publish job actually declares"
  - "`.github/workflows/environment-protection.yml` — that check, run outside the required status check"
  - "`smoke-published` — a stable release.yml job id that installs the just-published tarball in published mode before anything attests it"
  - "distribution-sync gated on smoke-published, in both `needs:` and its `if:`"
  - "four new control-plane contract assertions, including the standing emptiness of ci-required's allowed-skips / allowed-failures"
  - "CONTRIBUTING.md: the publish approval described as a confirmation step, and a pre-written recovery runbook"
affects: [202-05 post-publish verification, future release-gate work, ship-time review of the publish pipeline]

actuals:
  tokens: 7333
  tasks: 3
  commits: 3
  plan_head_before: 28c1930f3df9f9d2a62d97295c10c0f6ae80940c

tech-stack:
  added: []
  patterns:
    - "Fail-closed live-GitHub-state verification, kept outside the required status check: an unreadable response exits non-zero unless an explicitly named ALLOW_UNVERIFIED_* variable opts in and prints a warning"
    - "Two-half live verification: assert the rule exists AND that the thing being protected is the same named object the workflow uses, so a rename cannot leave both halves green"
    - "Post-publish jobs live in release.yml only — a conditionally-skipped member of the per-PR required check is scored as a pass"
    - "Under `always()`, needs: membership is ordering, not a gate; the `if:` must also assert the dependency's result"

key-files:
  created:
    - bin/verify-environment-protection
    - .github/workflows/environment-protection.yml
  modified:
    - .github/workflows/release.yml
    - test/threadline/release_control_plane_contract_test.exs
    - CONTRIBUTING.md

key-decisions:
  - "ALLOW_UNVERIFIED_ENVIRONMENT_PROTECTION is deliberately NOT set in environment-protection.yml — unlike the branch-protection script's classic-protection field, the protection rule read here IS the load-bearing assertion, so passing on an unreadable response would recreate the vacuous gate this plan exists to close"
  - "distribution-sync's `if:` gained `needs.smoke-published.result == 'success'` in addition to the needs: entry, because the job carries always() and needs: alone would not have blocked it"
  - "Half (b) derives the publish job from the workflow source (the job whose body contains the publish command) rather than hardcoding `publish-hex`, so a renamed publish job is caught too"
  - "The environment name is overridable via THREADLINE_PUBLISH_ENVIRONMENT so the FAIL path can be exercised without mutating live repository configuration"

patterns-established:
  - "Live-state verifier + own workflow + escape hatch left unset in CI: the escape hatch exists for local/edge tokens, not to keep the hosted check green"
  - "Contract failure messages name the consequence (an attestation about an uninstalled artifact; a skip scored as a pass), not just the broken assertion"

requirements-completed: [RELEASE-03, RELEASE-05]

coverage:
  - id: D1
    description: "Deleting the required reviewer from the production-hex environment on GitHub's side makes a check go red, instead of leaving a green and inert YAML assertion"
    requirement: "RELEASE-03"
    verification:
      - kind: other
        ref: "bash bin/verify-environment-protection (live, exit 0, evidence line + OK summary)"
        status: pass
      - kind: other
        ref: "THREADLINE_PUBLISH_ENVIRONMENT=no-such-env-xyz bash bin/verify-environment-protection (exit 1, FAIL (a) block)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The newly published tarball is installed and exercised by the evaluator fixture before the attestation row is written — distribution-sync now waits on smoke-published"
    requirement: "RELEASE-05"
    verification:
      - kind: unit
        ref: "test/threadline/release_control_plane_contract_test.exs#the attestation job waits on the published-release smoke job"
        status: pass
      - kind: unit
        ref: "test/threadline/release_control_plane_contract_test.exs#the published-release smoke job exists and is fed the published version"
        status: pass
    human_judgment: false
  - id: D3
    description: "The smoke job lives in the release workflow only and is never a member of the required check; ci-required's allowed-skips and allowed-failures stay empty"
    verification:
      - kind: unit
        ref: "test/threadline/release_control_plane_contract_test.exs#the published-release smoke job exists in release.yml and nowhere else"
        status: pass
      - kind: unit
        ref: "test/threadline/release_control_plane_contract_test.exs#the required check launders nothing: allowed-skips and allowed-failures stay empty"
        status: pass
      - kind: other
        ref: "git diff f10f6319^..f10f6319 -- .github/workflows/ci.yml (no output)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The environment approval is documented as a confirmation step, not peer review, and the recovery path is written down before the first publish"
    verification:
      - kind: integration
        ref: "mix verify.doc_contract (134 tests, 0 failures)"
        status: pass
      - kind: integration
        ref: "mix test test/threadline/ (1680 tests, 0 failures)"
        status: pass
    human_judgment: true
    rationale: "The suite proves the prose does not trip the doc-contract or planning-vocabulary scans; it cannot judge whether the recovery runbook is one a maintainer could actually follow under pressure, or whether the approval is described honestly. A human read is the only check for that."
  - id: D5
    description: "The smoke job resolves the just-published version from hexpm in published mode"
    requirement: "RELEASE-05"
    verification:
      - kind: other
        ref: "backstop — observable only in a real release run; pre-publish evidence is priv/ci/hex_evaluator/mix.exs's System.fetch_env!(\"THREADLINE_PUBLISHED_VERSION\"), the job's env wiring, and the contract assertion that the job passes the version through"
        status: unknown
    human_judgment: true
    rationale: "Marked verification: backstop in the plan. The claim is only observable after an irreversible publish; Plan 05 Task 4 converts it into read-the-log human verification against live evidence."

duration: 38 min
completed: 2026-09-22
status: complete
---

# Phase 202 Plan 04: Publish-gate liveness, post-publish smoke, and the recovery runbook Summary

**A fail-closed live read of the production-hex required-reviewer rule, a `smoke-published` job that installs the just-published tarball before distribution-sync attests it, and a recovery procedure written before the first publish can need it.**

## Performance

- **Duration:** 38 min
- **Tasks:** 3
- **Files created:** 2
- **Files modified:** 3

## Accomplishments

- **The publish gate is now verified where it is enforced.** `bin/verify-environment-protection` reads the live GitHub environment and fails closed; deleting the required reviewer turns a check red instead of leaving `release_control_plane_contract_test.exs:12`'s YAML assertion green and inert.
- **Nothing is attested about a tarball nobody installed.** `smoke-published` runs `mix verify.hex_evaluator` in published mode against the version `release-ref` emitted, and `distribution-sync` now requires its success.
- **The required check still launders nothing.** The smoke job is in `release.yml` only, `ci.yml` is byte-identical, and a new contract assertion makes the emptiness of `allowed-skips` / `allowed-failures` a red test rather than a habit.
- **The human gate and the recovery path are described honestly, in writing, before the first publish.**

## Live assumption resolution (Task 1)

The plan required resolving RESEARCH.md's logged endpoint assumption against the live API rather than asserting configuration from memory. Observed 2026-09-22:

`GET repos/szTheory/threadline/environments/production-hex` → **HTTP/2.0 200 OK**, body:

```json
{"id":20753768806,"name":"production-hex","can_admins_bypass":false,
 "protection_rules":[{"id":63907787,"type":"required_reviewers","prevent_self_review":false,
   "reviewers":[{"type":"User","reviewer":{"login":"szTheory", ...}}]}],
 "deployment_branch_policy":null}
```

**The logged assumption held exactly.** A `protection_rules` collection is present; a `required_reviewers` rule appears in it; its `reviewers` list is non-empty (one `User`). The currently authenticated token (scopes `gist, read:org, repo`) can read it — no 403, so the fallback path was not exercised live.

Two facts worth recording beyond the endpoint shape:

- `prevent_self_review: false` — the live configuration confirms the phase decision that this approval is a confirmation step and not four-eyes. The documentation written in Task 3 matches the observed setting, not an aspiration.
- `can_admins_bypass: false`.

**Observed FAIL path** (`THREADLINE_PUBLISH_ENVIRONMENT=no-such-env-xyz bash bin/verify-environment-protection`, exit **1**):

```
FAIL (a): szTheory/threadline has no environment named "no-such-env-xyz" (HTTP 404).
Either the environment was deleted, or the name this script checks has drifted
from the one .github/workflows/release.yml gates the publish job on.
```

**Observed pass** (`bash bin/verify-environment-protection`, exit **0**):

```
Inspected szTheory/threadline environment "production-hex": required_reviewers rule present with 1 reviewer(s).
Confirmed .github/workflows/release.yml job "publish-hex" gates the publish on environment "production-hex".
Environment protection OK for szTheory/threadline environment "production-hex": a required_reviewers rule with 1 reviewer(s) is live, and the publish job in .github/workflows/release.yml is gated on that same environment.
```

The evidence line precedes the OK summary, so the plan's `fails_when` ("an OK summary with no preceding evidence line") is structurally unreachable on the pass path.

**The zero-reviewer branch could not be exercised against live state** — the repository has exactly one environment and it carries the rule, and mutating live publish protection to exercise a test is a production change with no operational justification (the same reasoning that produced `bin/compare-required-contexts`). The decision itself was exercised against fixtures instead: an environment object carrying only a `wait_timer` rule yields reviewer count `0` (determinate, not empty), which routes to the `FAIL (a)` branch, and an empty `protection_rules` array renders as `(none)` in the "found instead" line. Recorded as an honest partial demonstration rather than a claim.

## Task Commits

1. **Task 1: bin/verify-environment-protection + its workflow** — `b15008a7` (feat)
2. **Task 2: smoke-published and the attestation ordering** — `f10f6319` (feat)
3. **Task 3: honest publish-gate docs and the recovery runbook** — `d4eddcbf` (docs)

## Files Created/Modified

- `bin/verify-environment-protection` — two-half fail-closed live check: (a) the environment still has a `required_reviewers` rule with ≥1 reviewer; (b) the publish job in `release.yml` is gated on that same environment name. Escape hatch: `ALLOW_UNVERIFIED_ENVIRONMENT_PROTECTION=1` only.
- `.github/workflows/environment-protection.yml` — runs it on `workflow_run` after CI on `main`, daily at 06:40 UTC, and on dispatch. Outside `ci-required`; the escape hatch is deliberately unset.
- `.github/workflows/release.yml` — new `smoke-published` job (Postgres service, toolchain pins, `mix verify.hex_evaluator` with `THREADLINE_HEX_EVALUATOR_MODE: published` and `THREADLINE_PUBLISHED_VERSION` from `release-ref`); `distribution-sync` needs and requires it.
- `test/threadline/release_control_plane_contract_test.exs` — 2 tests → 6. The two pre-existing tests are untouched.
- `CONTRIBUTING.md` — "The publish approval is a confirmation, not a review" and "Recovery after a bad publish".

## Verification results

| Check | Result |
|---|---|
| `bash bin/verify-environment-protection` | exit 0, evidence + OK summary |
| same, nonexistent environment | exit 1, `FAIL (a)` block |
| `mix test test/threadline/release_control_plane_contract_test.exs` | **6 tests, 0 failures** (was 2) |
| `mix test test/threadline/ci_topology_contract_test.exs` | 17 tests, 0 failures |
| `mix verify.hex_evaluator` (no mode var) | exit 0, 6 tests, 0 failures; resolved `threadline 0.9.0` from `threadline_rehearsal`, not hexpm |
| `mix verify.doc_contract` | 134 tests, 0 failures |
| `mix test test/threadline/` | **1680 tests, 0 failures**, 1 excluded |
| `git diff f10f6319^..f10f6319 -- .github/workflows/ci.yml` | no output — the job-id contract header is byte-identical |

**Negative control, as the plan required.** Removing `smoke-published` from `distribution-sync`'s `needs:` list and re-running the contract produced:

```
1) test the attestation job waits on the published-release smoke job
   distribution-sync must list smoke-published in needs:, or the distribution
   attestation row is written about an artifact that was never installed.
6 tests, 1 failure
```

The edit was reverted before commit; the committed workflow carries the full needs list and the suite is green.

## Decisions Made

- **The escape hatch is not set in the workflow.** `bin/verify-branch-protection` sets `ALLOW_UNVERIFIED_CLASSIC_PROTECTION: "1"` in its workflow because the field it covers is a narrow supplementary assertion. Here the protection-rule read *is* the assertion, so setting it would make the hosted check pass on any unreadable response — the exact vacuous shape this plan closes. If a hosted token cannot read the environment, the check goes red and a maintainer grants scope.
- **`distribution-sync`'s `if:` gained a result check.** The job carries `always()`, under which `needs:` membership only orders execution — it does not block. Without `needs.smoke-published.result == 'success'`, the plan's stated truth ("the attestation row must never be written about an artifact that has not been proven to install") would have been false while every contract assertion passed. Recorded below as a deviation.
- **Half (b) derives the publish job rather than hardcoding `publish-hex`**, so a rename of the publish job is caught rather than silently skipped.
- **`THREADLINE_PUBLISH_ENVIRONMENT` override**, so the FAIL path is observable without mutating live protection.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] `distribution-sync` needed an `if:` result check, not only a `needs:` entry**

- **Found during:** Task 2
- **Issue:** The plan specified extending `distribution-sync`'s `needs:` list to include `smoke-published`. That job's `if:` begins with `always()`, under which GitHub runs the job regardless of its dependencies' results. Membership in `needs:` alone would have ordered the smoke job before the attestation while still writing the attestation row after a *failed* smoke run — leaving the plan's load-bearing truth false with every gate green, which is the same vacuous-gate shape the plan exists to eliminate.
- **Fix:** Added `needs.smoke-published.result == 'success'` to `distribution-sync`'s `if:` alongside the existing result checks, with a comment at the `needs:` line explaining why membership alone is insufficient. Added a contract assertion (`the attestation job waits on the published-release smoke job`) that fails if that clause is removed.
- **Files modified:** `.github/workflows/release.yml`, `test/threadline/release_control_plane_contract_test.exs`
- **Verification:** Contract test green; the negative control above shows the assertion is live.
- **Committed in:** `f10f6319` (Task 2 commit)

**2. [Rule 3 - Blocking] Half (b)'s job scanner matched the `on:` block**

- **Found during:** Task 1
- **Issue:** The first run of half (b) reported `FAIL (b): job "workflow_dispatch" publishes to Hex under environment "(none)"`. The awk scanner treated any two-space YAML key as a job, and `release.yml`'s `workflow_dispatch` input description contains the string `mix hex.publish` — so a workflow input was read as an unprotected publish job.
- **Fix:** The scanner now only considers keys inside the `jobs:` mapping.
- **Files modified:** `bin/verify-environment-protection`
- **Verification:** Re-ran live; half (b) correctly identifies `publish-hex`. Observed output quoted above.
- **Committed in:** `b15008a7` (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (1 missing critical, 1 blocking)
**Impact on plan:** Both were necessary for the plan's own stated truths to actually hold. No scope creep — no new dependency, no new alias, no change to the authentication swap-point region, and nothing added to the required check.

## Prohibitions honored

- `smoke-published` is absent from `ci-required`'s `needs:`, from any allowed-skips list, and from `ci.yml`'s job-id contract header (`ci.yml` is byte-identical across this plan's commits).
- `allowed-skips` and `allowed-failures` remain absent from `ci-required`, now asserted.
- The live verifier never downgrades an unreadable response to a pass without `ALLOW_UNVERIFIED_ENVIRONMENT_PROTECTION=1` plus a printed warning.
- No second invocation of the publish command: `release.yml` still carries exactly two `mix hex.publish` occurrences (dry-run and real), asserted by the pre-existing contract test.
- The environment approval is never described as peer review; `CONTRIBUTING.md` states explicitly that it is not.
- No package was installed; the phase adds no external dependency.

## Issues Encountered

None beyond the two deviations above.

## Known Stubs

None.

## Threat Flags

None. The two files created are read-only verification surface; no new network endpoint, auth path, or schema change was introduced. `bin/verify-environment-protection` performs only `GET` requests against the GitHub REST API and reads one file from the repository.

## Backstop verification (not manufactured)

One `must_haves` truth is marked `verification: backstop` in the plan and remains unproven here by design: **the smoke job actually resolves the just-published version from hexpm in published mode.** That is observable only in a real release run, and this plan is explicitly forbidden from operating the release control plane. The pre-publish evidence that does exist:

- `priv/ci/hex_evaluator/mix.exs` reads the version with `System.fetch_env!("THREADLINE_PUBLISHED_VERSION")` — published mode dies loudly rather than degrading to rehearsal.
- `mix.exs`'s `verify_hex_evaluator/1` skips the rehearsal-registry wrapper when the mode is `published`, so the fixture resolves against hexpm.
- The smoke job's `env` block sets both variables, and the contract test asserts the version flows from `release-ref.outputs.release_version`.

Plan 05 Task 4 converts this into read-the-log human verification against live evidence. Nothing was fabricated to close it here.

## Next Phase Readiness

- Plan 05 can proceed: the control plane it verifies post-publish is now wired and contract-asserted.
- **Not exercised in anger:** `.github/workflows/environment-protection.yml` has never run under a hosted `GITHUB_TOKEN`. If that token cannot read the environments endpoint, the check will go red by design (fail-closed) and a maintainer must grant the scope — that is the intended outcome, not a regression, but it will be the first thing to look at when the workflow first runs.
- `bin/verify-release-shape` still has not been exercised against a 0.10.0 heading (carried forward from Plan 03; not this plan's scope).

---
*Phase: 202-release-0-10-0*
*Completed: 2026-09-22*

## Self-Check: PASSED

- `bin/verify-environment-protection` — FOUND on disk
- `.github/workflows/environment-protection.yml` — FOUND on disk
- Commits `b15008a7`, `f10f6319`, `d4eddcbf` — all FOUND in `git log`
- `commits: 3` MEASURED via `git rev-list --count 28c1930f..HEAD`
