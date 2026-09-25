---
phase: 200-public-surface
plan: 14
subsystem: community-health
tags: [github, issue-forms, pull-requests, security, conduct, hosted-verification]
requires:
  - phase: 200-public-surface
    provides: complete public-document, archive, guide-graph, and CI contracts
provides:
  - exactly three safe GitHub issue forms with disabled blank issues and no Discussions route
  - concise pull-request intake, private vulnerability reporting, and distinct conduct/abuse routing
  - default-branch API, public-content, community-profile, and hosted-CI evidence
affects: [contributors, security-reporters, maintainers, phase-200-verification]
actuals:
  tasks: 3
  commits: 11
plan_head_before: 6b338d08
tech-stack:
  added: []
  patterns: [job-specific issue forms, private sensitive-report routing, default-branch hosted read-back]
key-files:
  created:
    - .github/ISSUE_TEMPLATE/01-bug.yml
    - .github/ISSUE_TEMPLATE/02-feature-request.yml
    - .github/ISSUE_TEMPLATE/03-question.yml
    - .github/ISSUE_TEMPLATE/config.yml
    - .github/pull_request_template.md
    - SECURITY.md
    - CODE_OF_CONDUCT.md
  modified:
    - bin/verify-dialyzer-slice
    - test/threadline/dialyzer_slice_contract_test.exs
    - test/threadline/playwright_fail_fast_contract_test.exs
    - priv/static/js/operator-surface-paths.ts
    - test/fixtures/operator_surface/manifest.sha256
key-decisions:
  - "Sensitive vulnerability reports use only GitHub private vulnerability reporting; conduct reports use GitHub Report Abuse."
  - "Hosted run 34732689921 is the decisive Phase 200 integration run, and squash merge 18fe87f5 is the exact default-branch state checked afterward."
  - "The maintainer accepted the residual outsider-render evidence gap after every available structural, API, public-content, and signed-out route check passed."
patterns-established:
  - "Public community surfaces are verified at three authorities: source contracts, hosted CI, and default-branch API/public-content read-back."
  - "A hosted API inconsistency is reported explicitly and never rewritten into a fabricated pass."
requirements-completed: [SURFACE-01, SURFACE-02, SURFACE-03, SURFACE-04, SURFACE-05, SURFACE-06, SURFACE-07, SURFACE-08, SURFACE-09, SURFACE-10, SURFACE-11]
coverage:
  - id: D1
    description: "Exactly three job-specific forms use one existing label each, assign nobody, require the intended fields, keep optional context optional, warn against private data, and disable blank/Discussions intake."
    requirement: SURFACE-11
    verification:
      - kind: integration
        ref: "test/threadline/community_health_contract_test.exs --only issue_security_tracer --only community_health"
        status: pass
      - kind: other
        ref: "PyYAML exact inventory/schema/field/requiredness audit"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pull-request, security, support, conduct, and abuse routes are concise, safe, distinct, and backed by enabled private vulnerability reporting."
    requirement: SURFACE-11
    verification:
      - kind: integration
        ref: "community-health contract plus GitHub private-vulnerability-reporting API read-back"
        status: pass
      - kind: other
        ref: "public SECURITY and CODE_OF_CONDUCT rendering/link inspection"
        status: pass
    human_judgment: false
  - id: D3
    description: "The merged default branch contains byte-identical community files and GitHub reports 100% community health; the exact separate-account issue-form rendering was not observable because GitHub redirects signed-out issue creation to login."
    requirement: SURFACE-11
    verification:
      - kind: ci
        ref: "GitHub Actions run 34732689921: 15/15 checks passed"
        status: pass
      - kind: other
        ref: "main@18fe87f5 API content/read-back, public raw SHA-256 comparison, community health 100%, private reporting enabled"
        status: pass
      - kind: manual
        ref: "Maintainer approval on 2026-09-13 accepting the remaining outsider-render evidence gap"
        status: accepted_gap
    human_judgment: true
    rationale: "A signed-out browser and anonymous HTTP both redirect New Issue, direct issue forms, pull-request creation, and private-advisory creation to GitHub login. The available authenticated identity is the repository owner, whose chooser can include maintainer-only controls and therefore cannot substitute for a non-maintainer. The maintainer explicitly approved proceeding after the exhaustive automatic audit."
duration: ~18h33m wall-clock
completed: 2026-09-13
status: complete
---

# Phase 200 Plan 14: Community Intake and Hosted Verification Summary

**Threadline now has three focused issue forms, concise pull-request guidance, private vulnerability reporting, and distinct conduct handling on the merged default branch, with all automatic gates green and one explicitly accepted outsider-render evidence gap.**

## Performance

- **Duration:** ~18h33m wall-clock, including the protected checkpoint and hosted CI repair cycles
- **Started:** 2026-09-12T12:07:54Z
- **Completed:** 2026-09-13T02:40:55Z
- **Tasks:** 3
- **Hosted integration:** PR #35, squash-merged as `18fe87f5`

## Accomplishments

- Added exactly Bug report, Feature request, and Question YAML forms with one known label each, no assignee, job-specific required fields, optional diagnostic/context fields, and repeated warnings against secrets, personal data, and production audit records.
- Disabled blank issues, omitted Discussions, and routed suspected vulnerabilities only to GitHub private vulnerability reporting.
- Added a short pull-request template, supported-release security policy, Contributor Covenant 3.0 policy, and separate GitHub Report Abuse route.
- Passed the full local Phase 200 contracts, ExDoc warnings gate, Hex build, formatter, private-reporting read-back, `mix ci.all`, and clean-clone planning-independence verifier.
- Repaired four hosted-only CI compatibility defects without weakening assertions, then refreshed deterministic Tier A evidence and its manifest.
- Proved the final PR head with all 15 required checks green in run `34732689921`, then merged PR #35 and verified `origin/main` and the GitHub API both resolved to `18fe87f5f107f155a1a98c1f33b8a64cca3741e3`.
- Confirmed all seven public files exist on `main`, public raw contents match the checked files byte-for-byte, community health is 100%, private reporting is enabled, SECURITY reaches the private-advisory route, and the conduct link reaches GitHub Report Abuse.

## Task Commits

1. **Task 1: Route one public report safely, then expand to all three jobs** — `5f51847c`, `af5d7b67`
2. **Task 2: Add PR/conduct policy and enable private reporting** — `ece1a7cc`, `f5e97b82`
3. **Task 3 preparation and hosted compatibility repairs** — `1dc54122`, `cdd8ec4e`, `567d4da2`, `03ed8a89`, `d43c7467`, `621a5732`, `9824c6c3`
4. **Default-branch integration** — `18fe87f5` (PR #35 squash merge)

## Files Created/Modified

- `.github/ISSUE_TEMPLATE/01-bug.yml` — version/commit, environment, reproduction, observed, expected, and optional diagnostics intake.
- `.github/ISSUE_TEMPLATE/02-feature-request.yml` — problem/job, outcome, optional proposal, and optional context intake.
- `.github/ISSUE_TEMPLATE/03-question.yml` — goal, attempts, and optional context intake.
- `.github/ISSUE_TEMPLATE/config.yml` — blanks disabled and one private security contact route.
- `.github/pull_request_template.md` — Why, What changed, Verification, optional issue, and private-data warning.
- `SECURITY.md` — supported-release policy and private vulnerability workflow.
- `CODE_OF_CONDUCT.md` — Contributor Covenant 3.0 adaptation and private abuse route.
- Hosted-CI support files and deterministic operator evidence — minimum-OTP JSON decoding, isolated Playwright bootstrap, live Dialyzer timeout, first-run capture-root handling, Tier A public evidence, and manifest hashes.

## Decisions Made

- Kept exactly three YAML issue forms; adding a Markdown template merely to populate GitHub REST's legacy `issue_template` field would violate the exact chooser contract.
- Treated GitHub's 100% rendered community profile plus the present default-branch YAML forms as authoritative recognition evidence while recording that `GET /community/profile` still returns `files.issue_template: null`.
- Accepted the remaining separate-account rendering observation only after the maintainer explicitly replied `approved`; no outsider interaction was fabricated.
- Left draft PR #34 untouched because it is a measurement-only Phase 199 pull request marked `DO NOT MERGE`.

## Deviations from Plan

### Auto-fixed hosted blockers

- The first hosted run exposed minimum-OTP incompatibility with `:json.decode/1`; `bin/verify-dialyzer-slice` now loads the already-compiled locked Jason dependency deterministically.
- Clean hosted jobs lacked `@playwright/test`; the behavioral smoke now bootstraps the exact locked package and Chromium while preserving the expected five-failure/two-unrun/five-trace proof.
- First-run Tier A capture rejected a missing-but-valid output root; path validation now canonicalizes the nearest existing ancestor while retaining absolute-path, traversal, and symlink protections.
- The live external Dialyzer contract exceeded ExUnit's default timeout; only that test received a 540-second budget.
- Those repairs exposed stale operator evidence and manifest hashes; the corpus was mechanically refreshed and both Tier A and manifest contracts passed.

## Issues Encountered

- Plan commands ending in `-x` are invalid under the pinned Mix version. The identical path/tag selections were run without only that unsupported argument; every selection was nonempty and passed.
- GitHub redirects signed-out issue, pull-request, and private-advisory creation routes to login. No separate non-maintainer account was available, so the exact outsider chooser/form rendering could not be observed automatically.
- GitHub's community-profile REST response reports 100% health but leaves the legacy `files.issue_template` field `null` for these YAML forms. All forms are present, valid, public on `main`, and recognized by the overall profile; the inconsistency is retained as evidence rather than hidden.
- Owner notification delivery depends on personal GitHub watch/notification settings, and the current token lacks the `notifications` permission needed to inspect repository subscription state. The maintainer accepted this residual operational check with the hosted-render gap.

## Verification Results

- Focused community contracts: 5 tests, 0 failures.
- Exact PyYAML inventory/schema/field audit: pass for all three forms, chooser, PR, SECURITY, and conduct policy.
- Full local repository gate: 1,608 tests, 0 failures; example suite 114 tests, 0 failures; Dialyzer, Credo, and Playwright 318 passed/26 skipped.
- Clean-clone planning-independent verifier: `AGGREGATE_RESULT=PASS`.
- Hosted GitHub Actions run `34732689921`: 15 of 15 checks passed, including the required aggregate.
- Default branch: `main@18fe87f5`; seven of seven files present and byte-identical; private vulnerability reporting enabled; community health 100%.

## Authentication Gates

- Task 3's protected human checkpoint resumed only after the maintainer replied `approved` on 2026-09-13.
- Approval accepts the documented inability to observe a separate logged-in non-maintainer UI; it does not assert that such a session was run.

## Known Stubs

None.

## User Setup Required

None. Maintainers who want security-report delivery beyond GitHub's default behavior should configure Watch → Custom → Security alerts (or All Activity) and their personal notification delivery preferences.

## Next Phase Readiness

- Phase 200 implementation and all automatable local/hosted gates are complete.
- Phase verification should retain the accepted outsider-render and notification-setting uncertainty as an explicit evidence note.
- No code or configuration blocker remains for Phase 201.

## Self-Check: PASSED

- All seven community files exist locally and on merged `main`.
- All named task/repair commits and merge commit resolve.
- Automatic source, schema, route, CI, API, public-content, and clean-clone checks pass.
- The protected checkpoint has an explicit maintainer approval, and its residual uncertainty is recorded rather than silently converted to observed evidence.

---
*Phase: 200-public-surface*
*Completed: 2026-09-13*
