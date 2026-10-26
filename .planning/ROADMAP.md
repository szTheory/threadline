# Roadmap: Threadline

## Milestones

- [ ] **v1.47 Release on autopilot** — Phases 244–247; in progress (opened 2026-10-24). Four phases, 14 requirements. Evidence: research/QUALITY-ROADMAP-2026-10-24.md; requirements: REQUIREMENTS.md.
- [x] **v1.46 Operator UI Refinement** — Phases 238–243; completed 2026-10-11. Six phases, 27 plans, 49 tasks, 26/26 requirements. Audit: tech_debt, with no unmet requirements or broken flows. Roadmap archive: milestones/v1.46-ROADMAP.md; requirements: milestones/v1.46-REQUIREMENTS.md; audit: milestones/v1.46-MILESTONE-AUDIT.md.
- [x] **v1.45 1.0 API Contract** — Phases 231–237; shipped as 1.0.0 on 2026-10-07. Archive: milestones/v1.45-ROADMAP.md.
- [x] **v1.44 Behavioral Depth: Properties, Twins, Telemetry** — Phases 224–230; shipped as 0.12.0 on 2026-10-02. Archive: milestones/v1.44-ROADMAP.md.
- [x] **v1.43 Supply Chain, CI Economy and Repo Hygiene** — Phases 214–223; shipped as 0.11.1 and 0.11.2 on 2026-09-30. Archive: milestones/v1.43-ROADMAP.md.
- [x] **v1.42 Capture Correctness for Real Table Shapes** — Phases 208–213; shipped as 0.11.0 on 2026-09-26. Archive: milestones/v1.42-ROADMAP.md.
- [x] **v1.41 Green, Clean, and Honest** — Phases 198–207; shipped on 2026-09-24. Archive: milestones/v1.41-ROADMAP.md.
- [x] **v1.40 Automated Operator-UI Critique and Forward-Only Iteration Harness** — Phases 194–197; shipped on 2026-08-27. Archive: milestones/v1.40-ROADMAP.md.
- [x] **v1.39 Quality Baseline, Schema Confidence, and CI Efficiency** — Phases 189–193; shipped on 2026-07-03. Archive: milestones/v1.39-ROADMAP.md.
- [x] **v1.38 Operator UI Page-by-Page IA and Design-System Polish** — Phases 181–188; shipped on 2026-06-30. Archive: milestones/v1.38-ROADMAP.md.
- [x] **v1.37 Operator Surface Design-System Stress Test and Component System** — Phases 171–180; shipped on 2026-06-20. Archive: milestones/v1.37-ROADMAP.md.
- [x] **v1.36 Operator Surface Light Mode** — Phases 166–170; shipped on 2026-06-14. Archive: milestones/v1.36-ROADMAP.md.
- [x] **v1.35 Unified Logo and Brand Book v2** — Phases 159–165; shipped on 2026-06-12. Archive: milestones/v1.35-ROADMAP.md.
- [x] **v1.34 Local Docker Admin UI DX** — Phases 154–158; shipped on 2026-06-07. Archive: milestones/v1.34-ROADMAP.md.

Earlier milestones are recorded in MILESTONES.md and their archives under milestones/.

## Phases

**v1.47 Release on autopilot.** Goal: a release needs only the maintainer's prose and the Hex publish approval, and CI is faster and never red for reasons unrelated to the change.

- [x] **Phase 244: Release flow** - The release workflow dates the CHANGELOG and refreshes stale release PRs; network fetches retry; Hex lock drift cannot recur silently (completed 2026-10-25)
- [x] **Phase 245: Supply chain** - grouped monthly Dependabot for SHA-pinned actions, SHA-pinned actions, a tiered deps-audit gate, and a self-closing deps-health issue (completed 2026-10-25)
- [x] **Phase 246: Debt closeout and critic retirement** - Every carried-debt row has a disposition, and the parked UI-critic loop is removed from main and tagged for restoration (completed 2026-10-25)
- [ ] **Phase 247: CI critical path and suite lanes** - Browser-spec timing visibility, then a per-project browser split, contract tests on one lane, rebalanced partitions, and hang-proof partitions

**Ordering note.** Debt closeout (246) runs before the CI phase (247): DEBT-02 deletes tests and the critic Playwright capture projects, so the CI-02 per-project split and the CI-02/CI-03 measured gates (median ≤ 9 min over 5 runs, ratio ≤ 1.15 over 3 runs) are taken once on the final suite instead of being split, measured, and re-measured. This swaps the numbers of the two approved phases; their contents are unchanged.

## Phase Details

### Phase 244: Release flow

**Goal**: A release takes the landing PR, the release PR and the Hex approval, with no CHANGELOG-dating PR, no hand rebase of a stale release PR, and no red run from a transient fetch or Hex lock drift.
**Depends on**: Nothing (first phase of v1.47)
**Requirements**: REL-01, REL-02, REL-03, REL-04
**Success Criteria** (what must be TRUE):
  1. With release prose and the upgrade-path row under `## Unreleased` in the landing PR, the release workflow renames the section to `## [X.Y.Z] - YYYY-MM-DD` on the release branch, the release PR's first CI run is green, and no separate CHANGELOG-dating PR exists; the release-shape and version-truth contract tests pass against the renamed shape.
  2. After a non-releasable merge leaves the open release PR behind main (release-please reports it unchanged), the release workflow rebases it with a CI-triggering token and a fresh CI run starts on the new head with zero human actions, proven by a release.yml contract test and one observed run.
  3. `mix deps.get` and the hex-evaluator resolve retry with backoff on a transient network failure, and a contract test fails if any test step is wrapped in a retry.
  4. The cause of the 1.1.0 `deps.get --check-locked` manager-field mismatch is recorded with evidence; if Hex version drift is the cause, CI pins the Hex version so the mismatch cannot recur silently.

**Plans**: 10/10 plans complete (3 gap-closure plans added)

Plans:
**Wave 1**
- [x] 244-01-PLAN.md — REL-01/02: bin/date-release-changelog in sync-release-pr-pins, always-update, contracts with mutation controls

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 244-02-PLAN.md — REL-01/02: rehearsal runs the real rename script in release order; CONTRIBUTING/CHANGELOG/workflow docs

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 244-03-PLAN.md — REL-03: bin/retry-network + contract; all 15 workflow deps.get steps retried (publish-hex via ref-independent inline loop)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 244-04-PLAN.md — REL-03: nested fetches (hex-evaluator resolve, mix aliases, bin scripts) wrapped; fake-mix tests

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 244-05-PLAN.md — REL-04: cause recorded; Hex 2.6.0 pin tracer on verify-deps-audit; MIN_HEX 2.6.0; hex pin contract

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 244-06-PLAN.md — REL-04: pin Hex 2.6.0 in all 17 setup-beam steps (release lane via inline retry); parity matrix input

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 244-07-PLAN.md — phase gate (CI=true ci.all, bump rehearsal, REL-04 reproduction) + REL-02 observed-run evidence and PAT-expiry item (may stay pending)

**Gap closure, wave 1** *(from 244-VERIFICATION.md)*
- [x] 244-08-PLAN.md — REL-04 gap: bin/verify-lock-hygiene (empty `:hex` manager list, deps/-independent) in verify-deps-audit; CONTRIBUTING cause rewritten to the deps/-state mechanism
- [x] 244-09-PLAN.md — CR-01 gap: mix.exs resolves bin/retry-network lazily via RETRY_NETWORK; spaced-path load test; WR-01/03/04

**Gap closure, wave 2** *(blocked on 244-08 and 244-09)*
- [x] 244-10-PLAN.md — CI=true ci.all on ephemeral postgres:16 over both fixes; repo-hygiene evidence; final review dispositions

### Phase 245: Supply chain

**Goal**: Security fixes arrive as PRs without routine version noise, every action reference is immutable, and only advisories that reach adopters block the release lane.
**Depends on**: Phase 244 (both edit ci.yml and release.yml; sequential to avoid workflow conflicts, and SUP-03's green release lane builds on Phase 244's release flow)
**Requirements**: SUP-01, SUP-02, SUP-03, SUP-04
**Success Criteria** (what must be TRUE):
  1. `.github/dependabot.yml` keeps SHA-pinned GitHub Actions current through one grouped monthly version-update PR with a 7-day cooldown and no mix or npm entry, because Dependabot does not serve Hex; a contract test pins this.
  2. Every third-party `uses:` reference is a full commit SHA with a version comment, setup-node reads its version from `.tool-versions`, and a contract test rejects a tag-only ref, with a negative control proving it fails.
  3. A test pins both audit tiers: a new advisory in a shipped runtime dependency fails required CI, while a new advisory confined to dev/test/bench/example dependencies files or updates an issue and leaves the release lane green.
  4. The scheduled deps-health report opens or updates an issue for advisories, retirements or an unknown audit state and closes it only when clean (a permanently "outdated" issue like #61 no longer stays open); `bin/deps-health-report` classification is covered by a test.

**Plans**: 5/5 plans complete

Plans:
**Wave 1**
- [x] 245-01-PLAN.md — SUP-04 (+ D-01 rewording): four-class SARIF classifier, hex.outdated dropped, retitling upsert, daily/push-triggered self-closing deps-health issue

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 245-02-PLAN.md — SUP-03: shared bin/deps-audit-tier tiering (directory role + post-fetch --only prod closure), tiered verify-deps-audit, self-test case (e), tier sections in the issue

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 245-03-PLAN.md — SUP-02: one atomic commit SHA-pinning all 79 refs, setup-node from .tool-versions, pin contract, {action, major} runtime allowlist

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 245-04-PLAN.md — SUP-02 (D-14b): bin/verify-action-pins in the scheduled lane; a pin mismatch makes the run unknown

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 245-05-PLAN.md — SUP-01: .github/dependabot.yml and its contract, D-06/D-07 docs, phase gate (CI=true mix ci.all on ephemeral postgres:16)

### Phase 246: Debt closeout and critic retirement

**Goal**: The carried-debt register is fully dispositioned, and the parked UI-critic loop is gone from main yet restorable, leaving the suite, CI topology and docs consistent for the CI phase to measure.
**Depends on**: Phase 245 (register rows such as 216 action pinning, the setup-node float and 215 WR-01 are closed by SUP-02, so their dispositions cite Phase 245)
**Requirements**: DEBT-01, DEBT-02
**Success Criteria** (what must be TRUE):
  1. Every row of the 2026-10-24 carried-debt register has a recorded disposition, with none left blank: fixed items closed, obsolete items (including the stale WINDOWS rows) waived with a reason, and still-real items routed to a named later milestone.
  2. The cheap 215/223 CI self-test findings are fixed and their tests pass; the remaining 215/223 findings are waived with a reason.
  3. The critic loop's code, tests, fixtures, Playwright capture projects and doc references are absent from main (a repo search finds no live references), and a tag marks the last commit that carries them for restoration (decision D-4).
  4. After the removal, `mix ci.all` and required CI are green, the partition contract lists no deleted test files, the browser lane runs no orphaned capture project, and the honest-default test docs remain true.

**Plans**: 10/10 plans complete (3 gap-closure plans added)

Plans:
**Wave 1**
- [x] 246-01-PLAN.md — Wave 0 close check (`tools/verify-phase.sh` default / --close / --self-test)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 246-02-PLAN.md — Removal slices C1 (critic-trust + Dialyzer re-point) and C2 (TS critic, npm, Retired pointer)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 246-03-PLAN.md — Removal slices C3a (capture projects + verify-capture job, Browser-full one-project) and C3b (mechanical floor)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 246-04-PLAN.md — Removal slice C4 (stress stories, ledger, fixture corpus) + residual sweep + post-removal suite

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 246-05-PLAN.md — D-16 cheap 215/223 self-test fixes and the 216 IN-01 fix-or-waive

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 246-06-PLAN.md — Debt register, SEED-005 closure, SEED-008 carry, routes, stale rows, live planning wording

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 246-07-PLAN.md — WINDOWS to zero open, D-24 phase gate, landing hand-off for the squash PR and archive tag

**Wave 8 — gap closure** *(from 246-VERIFICATION.md)*
- [x] 246-08-PLAN.md — Gap 1 (WR-01 + IN-02): honest Browser-full coverage wording pinned by a spec-derived doc contract, job display rename, carried as removal slice C7

**Wave 9 — gap closure** *(blocked on 246-08: shared 246-LANDING.md)*
- [x] 246-09-PLAN.md — Gap 2 (D-24): route the :101 Home screenshot drift to SEED-008 (10-failure threshold) with a pinned register row

**Wave 10 — gap closure** *(from 246-VERIFICATION.md re-verification, 10/11)*
- [x] 246-10-PLAN.md — Residual WR-01: un-invert the playwright.config.ts scorecard clause, harden CiCoverageDocContractTest (R2-WR-01 twin-aware phrase, R2-WR-02 scoped blocks + widened denylist), carried as removal slice C8

### Phase 247: CI critical path and suite lanes

**Goal**: Required CI finishes in ≤ 9 minutes median on main without dropping coverage, partitions are balanced, and a hung test fails fast and names itself.
**Depends on**: Phase 246 (measured on the post-removal suite and Playwright project set). Within the phase, CI-01 timing visibility lands and is read before the CI-02 split.
**Requirements**: CI-01, CI-02, CI-03, CI-04
**Success Criteria** (what must be TRUE):
  1. Every main CI run publishes at least the 20 slowest browser specs with durations in the job summary or an artifact, and this lands before the browser split.
  2. Browser E2E runs as one parallel job per Playwright project, the operator-journey receipt still reconciles every journey across the merged results, and median ci.yml wall time over 5 main runs is ≤ 9 minutes (recorded as the measured gate for SEED-006's reopen condition).
  3. Repo-file contract tests run only on the current lane while local `mix test` still runs them, the honest-default docs stay true, and with partition weights refreshed from CI timings the slowest/fastest partition ratio is ≤ 1.15 over 3 runs.
  4. A hung test fails within its partition timeout and names the stuck test instead of running to the 25-minute job timeout, reproduced against the PR #89 evidence (run 40137607358, job 121002346075).

**Plans**: 9/13 plans executed

Plans:
**Wave 1**
- [x] 247-01-PLAN.md — Land A1: 244/245 work to main as one `ci:` squash (D-01/D-02/D-03; maintainer push/merge checkpoint)
- [x] 247-03-PLAN.md — CI-01: slow-specs.ts summary + `browser-timings` artifact + contract; read-only `bin/measure-main-ci`

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 247-02-PLAN.md — Land A2: 246 critic removal as its own `chore:` squash; local archive tag + register row (tag push = maintainer hand-off)
- [x] 247-04-PLAN.md — CI-04/D-11: `Threadline.Test.PartitionMonitor` (timings TSV with `lane=` + named hang dump), attached by the partition runner; `--ingest-weights [--lane]`; D-16(b) sandbox test

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 247-05-PLAN.md — CI-04: bash budget watchdog (process groups, QUIT/TERM/KILL, Exit 124), hang self-tests, D-15 timeout layering + artifacts + `THREADLINE_CI_LANE`, D-12 ratio row

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 247-06-PLAN.md — CI-03 lane-scope plumbing: `THREADLINE_TEST_SCOPE` filter on min/latest, tracer tag, scope contract (D-10 half), CONTRIBUTING sentence

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 247-07-PLAN.md — CI-03 classification: D-09 no-dodging / no-unclassified contract, `@moduletag :repo_contract` on ~50 files, drop Node from min/latest

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 247-08-PLAN.md — Land B1 `ci:` PR from a pinned `B1 end SHA`; observe ≥ 3 main runs (CI-01 data, ratios); D-16(c) PR #89-shape reproduction
- [x] 247-09-PLAN.md — CI-02 prep: N-file journey receipt (plain node) + `bin/browser-full-projects` matrix resolution (fail closed)

**Wave 7** *(blocked on Wave 6 completion)*
- [ ] 247-10-PLAN.md — CI-02 split: matrix `verify-example-browser` + `verify-example-browser-receipt` fan-in, contracts/rosters/docs in one commit; action-pin provenance
- [ ] 247-12-PLAN.md — CI-03 balance: weights ingested from CI timings (`--lane current`), fitted async factor, conditional stress_router split

**Wave 8** *(blocked on Wave 7 completion)*
- [ ] 247-11-PLAN.md — CI-02 hardening: matrix == votingProjects, exact receipt needs, unconditional receipt, leg artifact names; full `ci.all` gate

**Wave 9** *(blocked on Wave 8 completion)*
- [ ] 247-13-PLAN.md — Land B2 (range from `B1 end SHA`); measure median ≤ 9 min over 5 runs and ratio ≤ 1.15 over 3 runs per lane; SEED-006 rewrite or recorded miss

## Progress

**Execution order:** 244 → 245 → 246 → 247

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 244. Release flow | 10/10 | Complete    | 2026-10-25 |
| 245. Supply chain | 5/5 | Complete    | 2026-10-25 |
| 246. Debt closeout and critic retirement | 10/10 | Complete    | 2026-10-25 |
| 247. CI critical path and suite lanes | 9/13 | In Progress | - |

## Current Position

v1.47 Release on autopilot is active; the roadmap is defined (Phases 244–247, 14/14 requirements mapped) and Phase 244 Release flow is next, not started. The latest published package is Hex 1.1.0. v1.46 is a completed planning milestone and local Git tag.

## Next

Run `/gsd-discuss-phase 244` (Release flow), then `/gsd-plan-phase 244`. Before closing v1.47, read .planning/MILESTONE-GUIDE.txt and .planning/MILESTONE-ARC.md; the next rung is v1.48 Safe by default.
