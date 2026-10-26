# Requirements: Threadline

**Defined:** 2026-10-24
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Milestone:** v1.47 Release on autopilot — evidence in `.planning/research/QUALITY-ROADMAP-2026-10-24.md`.

## v1.47 Requirements

### Release flow

- [x] **REL-01**: The maintainer writes release prose under `## Unreleased` (plus the upgrade-path row) in the landing PR, and the release workflow renames it to `## [X.Y.Z] - YYYY-MM-DD` on the release branch. The release PR's first CI run is green and no separate CHANGELOG-dating PR is needed; the release-shape and version-truth contract tests prove it.
- [ ] **REL-02**: When a non-releasable merge leaves an open release PR behind main (release-please reports it unchanged), the release workflow rebases it with a CI-triggering token, and fresh CI runs with no human action.
- [x] **REL-03**: Network dependency fetches in CI (`mix deps.get`, the hex-evaluator resolve) retry with backoff on transient failure; test steps are never retried.
- [x] **REL-04**: The cause of the 1.1.0 `deps.get --check-locked` manager-field mismatch is verified. If Hex version drift is the cause, CI pins the Hex version, so the lock mismatch cannot recur silently.

### Supply chain

- [x] **SUP-01**: Dependabot keeps SHA-pinned GitHub Actions current through one grouped monthly version-update PR with a 7-day cooldown. Hex security coverage comes from the tiered `hex.audit` gate (SUP-03) and the deps-health issue (SUP-04), because Dependabot does not serve Hex. A contract test pins the config.
- [x] **SUP-02**: Every third-party `uses:` reference is pinned to a full commit SHA with a version comment, setup-node reads its version from `.tool-versions`, and a contract test rejects tag-only refs.
- [x] **SUP-03**: The dependency-audit gate is tiered. A new advisory in a shipped runtime dependency fails required CI. A new advisory confined to dev/test/bench/example dependencies files or updates an issue and leaves the release lane green. A test pins both behaviours.
- [x] **SUP-04**: The scheduled deps-health report opens or updates an issue only for advisories, retirements or an unknown audit state and closes it when clean; `bin/deps-health-report` classification is covered by a test.

### CI critical path and suite lanes

- [x] **CI-01**: Every main CI run publishes the slowest browser specs (at least the top 20 with durations) in the job summary or an artifact.
- [ ] **CI-02**: Browser E2E runs as one parallel job per Playwright project. The operator-journey receipt still reconciles every journey, and median CI wall time over 5 main runs is ≤ 9 minutes. This is the measured gate for SEED-006's reopen condition.
- [ ] **CI-03**: Repo-file contract tests run only on the current lane (local `mix test` stays whole and the honest-default docs stay true), and partition weights are refreshed from CI timings so the slowest/fastest partition ratio is ≤ 1.15 over 3 runs.
- [x] **CI-04**: A hung test fails within its partition timeout and names the stuck test, instead of running to the 25-minute job timeout. This is reproduced against the PR #89 evidence (run 40137607358, job 121002346075).

### Debt closeout

- [x] **DEBT-01**: Every row of the 2026-10-24 carried-debt register has a recorded disposition. Fixed items are closed, obsolete items (including stale WINDOWS rows) are waived with a reason, and the cheap 215/223 CI self-test findings are fixed.
- [x] **DEBT-02**: The parked UI-critic loop (code, tests, fixtures, capture projects, docs references) is removed from main, its last commit is tagged for restoration, and the suite, CI topology and docs stay consistent (decision D-4).

## Future Requirements

Ranked in `.planning/MILESTONE-ARC.md`: v1.48 Safe by default, v1.49 Honest specs, v1.50 Measured performance, v1.51 Lean dependency tree.

## Out of Scope

| Item | Reason |
|------|--------|
| Merge queue | A single maintainer and strict checks off; adds latency without catching a failure class |
| Change-aware CI lanes | SEED-006 measured 0 of 28 PRs as inert |
| Release-please-generated user-facing notes | The generated 1.1.0 note was useless to adopters; human prose stays |
| Auto-merging the release PR; skipping `production-hex` approval | Intentional human publish gate |
| `workers > 1` / `fullyParallel` in one browser job | Specs share one server and DB; known timing flakes |
| Retrying test steps or auto-rerun bots | Hides flakes; Flake Detection covers them |
| Moving `HEX_API_KEY` to an environment secret | Maintainer settings action, tracked outside requirements |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| REL-01 | Phase 244 | Complete |
| REL-02 | Phase 244 | Pending (contract verified; observed run deferred to first release cycle after landing, 244-REL02-EVIDENCE.md) |
| REL-03 | Phase 244 | Complete |
| REL-04 | Phase 244 | Complete |
| SUP-01 | Phase 245 | Complete |
| SUP-02 | Phase 245 | Complete |
| SUP-03 | Phase 245 | Complete |
| SUP-04 | Phase 245 | Complete |
| DEBT-01 | Phase 246 | Complete |
| DEBT-02 | Phase 246 | Complete |
| CI-01 | Phase 247 | Complete |
| CI-02 | Phase 247 | Pending |
| CI-03 | Phase 247 | Pending |
| CI-04 | Phase 247 | Complete |

**Coverage:**
- v1.47 requirements: 14 total
- Mapped to phases: 14 (Phase 244: 4, Phase 245: 4, Phase 246: 2, Phase 247: 4)
- Unmapped: 0

---
*Requirements defined: 2026-10-24; traceability filled by the v1.47 roadmap 2026-10-24*
