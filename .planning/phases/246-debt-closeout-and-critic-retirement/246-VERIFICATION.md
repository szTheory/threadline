---
phase: 246-debt-closeout-and-critic-retirement
verified: 2026-10-26T02:31:50Z
status: gaps_found
score: 10/11 must-haves verified
covered_files:
  - ".github/workflows/browser-full.yml"
  - ".github/workflows/ci.yml"
  - ".planning/WINDOWS.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-01-PLAN.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-01-SUMMARY.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-02-PLAN.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-02-SUMMARY.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-03-PLAN.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-03-SUMMARY.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-04-PLAN.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-04-SUMMARY.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-05-PLAN.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-05-SUMMARY.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-06-PLAN.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-06-SUMMARY.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-07-PLAN.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-07-SUMMARY.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-08-PLAN.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-08-SUMMARY.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-09-PLAN.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-09-SUMMARY.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-DEBT-REGISTER.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-LANDING.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-REVIEW-DISPOSITION.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/deferred-items.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/tools/register-check.py"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh"
  - ".planning/seeds/SEED-005-reconnect-banner-shell-mount.md"
  - ".planning/seeds/SEED-008-operator-ui-carry.md"
  - "CONTRIBUTING.md"
  - "examples/threadline_phoenix/e2e/package.json"
  - "examples/threadline_phoenix/e2e/playwright.config.ts"
  - "examples/threadline_phoenix/e2e/support/operator-surface-paths.ts"
  - "examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts"
  - "examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts"
  - "lib/threadline/operator_surface/stress_fixtures.ex"
  - "mix.exs"
  - "test/fixtures/operator_surface/design-system-ledger.json"
  - "test/fixtures/operator_surface/manifest.sha256"
  - "test/partition_weights.txt"
  - "test/threadline/ci_coverage_doc_contract_test.exs"
  - "test/threadline/ci_topology_contract_test.exs"
  - "test/threadline/ci_workflow_parity_contract_test.exs"
  - "test/threadline/operator_surface/stress_ledger_test.exs"
  - "test/threadline/ui_critic_retirement_doc_contract_test.exs"
covered_digest: "v3:sha256:cdcefbdae873c2f099cd5e3e6d48b9eb2f9b5b2de039ae5549d6df3d3bc2f30c"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 9/11
  gaps_closed:
    - "D-24 phase gate: the :101 Home screenshot drift is routed (SEED-008 Scope + register row UI-HOME-SHOT-101), and the healthy standalone threshold reads the measured 10"
  gaps_remaining:
    - "Docs stay consistent after the removal: CONTRIBUTING.md and browser-full.yml are now true, but the playwright.config.ts route-capture comment still has the scorecard half of round-1 WR-01 the wrong way round"
  regressions: []
gaps:
  - truth: "Docs stay consistent after the removal (goal clause 'docs consistent for the CI phase to measure'; SC4 'honest-default test docs remain true')"
    status: partial
    reason: >-
      C7 (f57237d6) fixed the coverage half of WR-01 in all three sources, and the
      CONTRIBUTING.md and browser-full.yml wording now matches the code. The
      playwright.config.ts route-capture comment (:27-29), which C7 also rewrote, still says
      "the inventory-wide 1280/768/375 tests and the route scorecards run only in evidence
      mode". The scorecard clause is the reverse of what the code does. Round-1 WR-01 called
      out exactly this inversion ("the non-evidence path writes `route-scorecards/`"), and the
      previous gap listed this comment as describing the modes the wrong way round. The
      non-evidence test "renders every curated operator route at 1280"
      (operator-page-capture.spec.ts:425) is Browser-full's only test, and it skips in
      evidence mode (:430). It calls captureCell, which writes
      `writeJson(scorecardPath(id), scorecard)` (:371) into `routeScorecardsDir` =
      test/generated/operator_surface/route-scorecards (operator-surface-paths.ts:79). So
      `route-scorecards/` is written only outside evidence mode, by the lane Browser-full runs.
      The spec's own header (:17-18, "Outside evidence mode it ... writes its route
      scorecard") contradicts the config comment. The new CiCoverageDocContractTest cannot
      catch this, because its denylist is just the two strings "every inventoried route" and
      "at three viewports" (R2-WR-02). Round-2 review recorded the inversion as resolved,
      which is incorrect. This is a carried-forward gap, so the re-verification evidence gate
      lets it block. It is a one-clause comment fix, not a code defect, and the coverage table
      Phase 247 measures from is now true.
    artifacts:
      - path: "examples/threadline_phoenix/e2e/playwright.config.ts"
        issue: ":28-29 'and the route scorecards run only in evidence mode' is inverted; the curated non-evidence smoke is what writes route-scorecards/"
    missing:
      - "Reword the playwright.config.ts route-capture comment so the scorecard clause matches the code. For example: the curated 1280 smoke (what Browser-full runs) writes route-scorecards/, and evidence mode adds the inventory-wide 1280/768/375 tests with per-width evidence scorecards in its run root. Or drop the scorecard clause."
      - "Optionally pin the inversion in CiCoverageDocContractTest (R2-WR-02's pattern `in evidence mode,? writes the route scorecards` plus a 'scorecards run only in evidence mode' pattern, each with a mutation control). As removal-slice work it must be a C7 amendment or a C8 commit with a Removal-Slice trailer and no .planning/ path, with 246-LANDING.md updated."
---

# Phase 246: Debt closeout and critic retirement Verification Report

**Phase Goal:** The carried-debt register is fully dispositioned, and the parked UI-critic loop is gone from main yet restorable, leaving the suite, CI topology and docs consistent for the CI phase to measure.
**Verified:** 2026-10-26T02:31:50Z
**Status:** gaps_found
**Re-verification:** Yes, after gap closure (plans 246-08 and 246-09)

## Previous round (442c38bf, gaps_found 9/11) and how each gap was handled

| # | Previous gap | Closure | Result now |
|---|--------------|---------|------------|
| 1 | WR-01: Browser-full coverage misdescribed in CONTRIBUTING.md, browser-full.yml and playwright.config.ts | 246-08: removal slice C7 f57237d6 (three rewordings, the spec-derived `CiCoverageDocContractTest`, and the IN-02 job rename), with `.planning/` follow-up 9cfe8b16 | **Mostly closed.** CONTRIBUTING.md:311-313 and browser-full.yml:6-8 match the code. The playwright.config.ts comment still inverts the scorecard clause (see gap) |
| 2 | `:101` Home drift said to be "routed to SEED-008", but neither SEED-008 nor the register carried it | 246-09: cea43407 (SEED-008 Scope and the 10-failure threshold, register row `UI-HOME-SHOT-101`, the REQUIRED_IDS pin, cross-references) | **Closed** |

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1 / DEBT-01: every carried-debt row has a disposition; obsolete rows waived with a reason; real items routed to a named milestone or seed | VERIFIED (regression check) | `verify-phase.sh --close` passed at 87c78f9f (checks 1-7 ok). The frontmatter reads closed 64 / waived 44 / routed 24 / total 132, and 64+44+24 = 132 |
| 2 | The D-15 close check is mechanical, read-only and self-tested | VERIFIED | `--close` and `--self-test` both print `verify-phase: all checks passed`. `git status --porcelain` was empty before and after |
| 3 | SC2: the cheap 215/223 self-test findings are fixed | VERIFIED (regression) | No gap-closure commit touches them. Previous evidence stands |
| 4 | SC3: critic code, tests, fixtures, capture projects and doc references are absent from main's tree | VERIFIED (regression) | `bin/browser-full-projects --list config` prints `desktop-chromium mobile-chromium route-capture`. The D-09 grep passes (check 6), and the allowlist has no stale entries |
| 5 | Removal slices are separable: they touch no `.planning/` path and carry Removal-Slice trailers | VERIFIED | `git log --grep='^Removal-Slice:'` lists 8 slices, C1-C7 plus the C6 focus wait. C7 f57237d6 touches 0 `.planning/` paths and carries `Removal-Slice: C7` |
| 6 | Restorable (DEBT-02 / D-11 / D-13), judged against the hand-off | VERIFIED | 246-LANDING.md names eight slices, its cherry-pick line ends with `f57237d6` (:293) and its slice table row 8 is C7 (:258). The fallback pathspec list includes `ci_coverage_doc_contract_test.exs (C7)` (:162). Creating the tag is a maintainer step after landing (D-13), so it is not a gap |
| 7 | SC4: `mix ci.all` green after removal; partition contract lists no deleted files; no orphaned capture project | VERIFIED | The orchestrator gate at 70bead26 against an ephemeral postgres:16: `CI=true mix ci.all` exit 0 (lib 32 properties / 3331 tests / 0 failures, example 132/0, Dialyzer 0, CI browser 418/56/0). Since then only planning docs changed (87c78f9f), so the result still applies. My targeted re-run of six contract files gave 125 tests / 0 failures. Close-check partition rows name existing files. Required GitHub CI waits on the push decision |
| 8 | SEED-005 closed / SEED-008 planted with reopen_when | VERIFIED (regression) | Close check 7 ok |
| 9 | CI topology consistent: verify-capture removed and recorded as a coverage cut | VERIFIED (regression) | ci_topology_contract_test.exs is in the green targeted run |
| 10 | Docs consistent for the CI phase to measure (goal clause; SC4 honest docs) | PARTIAL (gap) | **CONTRIBUTING.md:311-313** says "a render smoke over the 6 curated operator routes at 1280; the inventory-wide 1280/768/375 route tests run only in evidence mode ... which Browser-full never sets". That is true: spec:425-440 loops `ROUTES` x `BREAKPOINTS = [1280]` (:35, :88-95), and the inventory tests skip outside evidence mode (:377-378). **browser-full.yml:6-8** is true as well. The IN-02 job name is `Example app browser E2E (projects ci.yml does not run)` (:48), id unchanged. **playwright.config.ts:28-29** is still inverted on scorecards, as detailed in the gap |
| 11 | D-24 browser gate: deviations from the expected failure set are honestly routed | VERIFIED | SEED-008:34-52 is titled "The 10 screenshot-regression baselines". It names `:101` with the 1281/2013 vs 1274/2048 px evidence on origin/main 23178fb0, and says "exactly these 10 failures" and "10-failure browser baseline". Register row `UI-HOME-SHOT-101` (:134) is `routed` to SEED-008, the Verdict bullet (:57) names it, and verify-phase.sh REQUIRED_IDS pins it (:90). deferred-items.md:23 and 246-LANDING.md:94 cite the row. This is a documented deviation from "exactly 8" backed by origin/main evidence, not an override |

**Score:** 10/11 truths verified (0 present, behavior-unverified)

### Judgment on R2-WR-01 ("6 curated operator routes" vs 5 distinct routes plus a degraded twin)

**Verdict: an acceptable wording nit, not a failed truth. Recorded as a warning.**

The facts:
- `ROUTES` (spec:88-95) has 6 entries, each with its own ledger id. One of them, `route.timeline.degraded`, is the same `/audit/timeline` path with `DEGRADE_CSS` injected (spec:90).
- The spec names this list "curated operator routes" itself: the test is "renders every curated operator route at 1280" (:425).
- The sentence counts entries of that list, and Browser-full renders exactly 6 cells. Nothing in it overstates the property Phase 247 measures: curated rather than inventory-wide, 1280 only, evidence mode never set.
- The overstatement is one distinct URL path, and it is internally consistent with the spec's own vocabulary.
- It is not the kind of misdescription WR-01 was, which claimed inventory-wide, three-viewport coverage that never ran.
- R2-WR-01's precision point is fair. Its commented-out-entry concern is hypothetical today: no `//` lines exist inside `ROUTES`.

Recommendation: fold "5 curated operator routes plus a degraded Timeline twin at 1280" into the same C7 amendment that fixes the scorecard clause. It does not block on its own.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/threadline/ci_coverage_doc_contract_test.exs` | spec-derived wording contract with negative controls | VERIFIED | in green run; derives from `const ROUTES` / `const BREAKPOINTS` |
| `CONTRIBUTING.md` | honest Browser-full sentence | VERIFIED | :311-313 |
| `.github/workflows/browser-full.yml` | honest header and renamed display name | VERIFIED | :6-8, :48 |
| `examples/threadline_phoenix/e2e/playwright.config.ts` | route-capture comment with the modes the right way round | PARTIAL | coverage half right; scorecard clause inverted (:28-29) |
| `246-LANDING.md` | eight-slice recipe including C7 | VERIFIED | :258, :293, :162 |
| `SEED-008-operator-ui-carry.md` | 10-failure baseline including :101 x2 | VERIFIED | :34-52 |
| `246-DEBT-REGISTER.md` | routed `UI-HOME-SHOT-101` row, counts 64/44/24/132 | VERIFIED | :134; check 1 ok |
| `tools/verify-phase.sh` | REQUIRED_IDS pin | VERIFIED | :90 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `ci_coverage_doc_contract_test.exs` | `operator-page-capture.spec.ts` | parses `const ROUTES` / `const BREAKPOINTS` | WIRED | the phrase "6 curated operator routes at 1280" is derived, not hard-coded |
| LANDING recipe | C7 commit | Removal-Slice trailer and cherry-pick list | WIRED | `--grep` derive returns f57237d6 |
| register row `UI-HOME-SHOT-101` | SEED-008 Scope | routed reason names SEED-008 | WIRED | check 3 ok; SEED-008:43 names the row |
| deferred-items `:101` entry | register | row id citation | WIRED | deferred-items.md:23 |
| `CiCoverageDocContractTest` denylist | inverted scorecard claim | refusal pattern | NOT_WIRED | denylist covers 2 strings only (R2-WR-02); the residual inversion passes |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Close check | `bash tools/verify-phase.sh --close` | `verify-phase: all checks passed` | PASS |
| Self-test | `bash tools/verify-phase.sh --self-test` | `verify-phase: all checks passed` | PASS |
| Targeted contracts | `mix test` on ci_coverage_doc, ci_workflow_parity, browser_journey_evidence, ui_critic_retirement, ci_topology, browser_full_projects | 125 tests, 0 failures | PASS |
| Browser-full project set | `bin/browser-full-projects --list config` | desktop-chromium, mobile-chromium, route-capture | PASS |
| Full gate | not re-run (shared local Postgres); orchestrator's ephemeral PG16 run at 70bead26 | exit 0 | PASS (recorded) |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| `.planning/phases/246-.../tools/verify-phase.sh` | `--close` / `--self-test` | both pass | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DEBT-01 | 01, 05, 06, 07, 09 | every carried-debt row dispositioned; cheap 215/223 fixed | SATISFIED | truths 1-3, 8, 11 |
| DEBT-02 | 01-04, 07, 08 | critic loop removed, tagged for restore, suite/CI/docs consistent | PARTIAL | removal, restore hand-off, suite and topology verified; one inverted doc clause remains (truth 10); tag creation is a maintainer step (D-13) |

No orphaned IDs. REQUIREMENTS.md maps only DEBT-01/02 to Phase 246 (:63-64), and both are claimed by plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| playwright.config.ts | 28-29 | comment contradicts code and the spec header (scorecard mode) | Blocker (carried-forward gap) | the residual of WR-01 |
| ci_coverage_doc_contract_test.exs | 57-58 | denylist too narrow; whole-file prose match (R2-WR-02) | Warning | this is why the residual inversion passes the contract |
| CONTRIBUTING.md / browser-full.yml / playwright.config.ts | 311 / 6 / 27 | "6 curated operator routes" counts the degraded twin (R2-WR-01) | Warning | wording nit, see judgment above |
| verify-phase.sh | 90 | pin checks presence, not the routed disposition (R2-IN-04) | Info | |
| stress_ledger_test.exs, ci_topology_contract_test.exs, operator-surface-paths.ts | - | round-1 WR-03/04/05 still open | Warning | unchanged from the previous round; not goal-blocking |

No TBD/FIXME/XXX markers in the gap-closure files.

### Human Verification Required

None. The judgment calls (R2-WR-01 and the scorecard clause) were resolved here.

### Gaps Summary

Gap 2 is fully closed: the `:101` drift is routed at every destination and pinned by the close check.

Gap 1 is closed for the two sources Phase 247 measures from, CONTRIBUTING.md and browser-full.yml. In the third source, the playwright.config.ts route-capture comment, C7 corrected the coverage half but kept "the route scorecards run only in evidence mode". The code does the reverse: Browser-full's curated non-evidence smoke is the only writer of `route-scorecards/`. Round 1 named this exact inversion, and round 2 marked it resolved, which is incorrect.

The fix is one clause in a comment. Ship it as a C7 amendment or a C8 removal slice, so the removal squash lands with honest docs. Optionally:
- widen the contract denylist (R2-WR-02) so the inversion cannot come back;
- adopt the "5 routes plus a degraded twin" wording (R2-WR-01) in the same commit.

---

_Verified: 2026-10-26T02:31:50Z_
_Verifier: Claude (gsd-verifier)_
