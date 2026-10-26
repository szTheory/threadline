---
phase: 246-debt-closeout-and-critic-retirement
verified: 2026-10-26T03:18:58Z
status: passed
score: 11/11 must-haves verified
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
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-10-PLAN.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-10-SUMMARY.md"
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
covered_digest: "v3:sha256:bf347a76885d9c673b1541959f8ba2d8cc279a200ec03d49941994ebfcbdd83b"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 10/11
  gaps_closed:
    - "Docs stay consistent after the removal: the playwright.config.ts route-capture comment now says the curated non-evidence smoke writes route-scorecards/ and evidence mode writes per-width scorecards under its run root (removal slice C8, e9a97139)"
  gaps_remaining: []
  regressions: []
---

# Phase 246: Debt closeout and critic retirement Verification Report

**Phase Goal:** The carried-debt register is fully dispositioned, and the parked UI-critic loop is gone from main yet restorable, leaving the suite, CI topology and docs consistent for the CI phase to measure.
**Verified:** 2026-10-26T03:18:58Z
**Status:** passed
**Re-verification:** Yes, round 3, after gap-closure plan 246-10 (removal slice C8)

## Previous round (8377fa71, gaps_found 10/11) and how the gap was handled

| # | Previous gap | Closure | Result now |
|---|--------------|---------|------------|
| 1 | playwright.config.ts route-capture comment said "the route scorecards run only in evidence mode", the reverse of the code | 246-10: removal slice C8 e9a97139 (comment rewrite, R2-WR-01 twin-aware phrase, R2-WR-02 regex denylist plus scoping), with `.planning/` follow-ups 62b137b1, 2a2d9e9e, 0e16e1f2 | **Closed.** See truth 10 |

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1 / DEBT-01: every carried-debt row has a disposition; obsolete rows waived with a reason; real items routed to a named milestone or seed | VERIFIED (regression) | `verify-phase.sh --close` at 20fc1f3d: checks 1-7 all `ok`, `verify-phase: all checks passed`. No 246-10 commit touches the register |
| 2 | The D-15 close check is mechanical, read-only and self-tested | VERIFIED (regression) | `--close` and `--self-test` both print `verify-phase: all checks passed`. `git status --porcelain` was empty before and after |
| 3 | SC2: the cheap 215/223 self-test findings are fixed | VERIFIED (regression) | No 246-10 commit touches them. Previous evidence stands |
| 4 | SC3: critic code, tests, fixtures, capture projects and doc references are absent from main's tree | VERIFIED (regression) | `bin/browser-full-projects --list config` prints `desktop-chromium mobile-chromium route-capture`. The D-09 grep (check 6) passes, and the allowlist has no stale entries |
| 5 | Removal slices are separable: no `.planning/` path, each carries a Removal-Slice trailer | VERIFIED | `git log --grep='^Removal-Slice:'` lists 9 commits with trailers C1, C2, C3a, C3b, C4, C5, C6, C7, C8. A per-slice loop under `bash -c` prints `planning=0` for all 9. C8 touches exactly 4 files: browser-full.yml, CONTRIBUTING.md, playwright.config.ts and ci_coverage_doc_contract_test.exs |
| 6 | Restorable (DEBT-02 / D-11 / D-13), judged against the hand-off | VERIFIED | 246-LANDING.md is now a nine-slice recipe. Row 9 is C8 with its full SHA (:259), the cherry-pick line ends with `e9a97139` (:303), and the fallback pathspec lists `ci_coverage_doc_contract_test.exs (C7, C8)` (:162). The stated totals of 528 paths and 479 deletions match my independent recount over the nine SHAs (528 / 479). Creating the tag is a maintainer step after landing (D-13), so it is not a gap |
| 7 | SC4: `mix ci.all` green after removal; partition contract lists no deleted files; no orphaned capture project | VERIFIED | Orchestrator-supplied executor gate on the C8 tree against an ephemeral postgres:16: `CI=true mix ci.all` exit 0 (lib 3332 tests / 0 failures, example 132/0, Dialyzer 0, CI browser 418 passed / 0 failed / 56 skipped). Every commit since then changed `.planning/` only. My own targeted run of the six contract files (ci_coverage_doc, ci_workflow_parity, browser_journey_evidence, ui_critic_retirement, ci_topology, browser_full_projects) gave 126 tests / 0 failures. The close-check partition rows name existing files. Required GitHub CI waits on the push decision |
| 8 | SEED-005 closed / SEED-008 planted with reopen_when | VERIFIED (regression) | Close check 7 `ok` |
| 9 | CI topology consistent: verify-capture removed and recorded as a coverage cut | VERIFIED (regression) | ci_topology_contract_test.exs is in the green targeted run |
| 10 | Docs consistent for the CI phase to measure (goal clause; SC4 honest docs) | VERIFIED | **playwright.config.ts:27-30** now reads: outside evidence mode it renders the 5 curated operator routes plus a degraded Timeline twin at 1280 "and writes their route scorecards to route-scorecards/; that is what Browser-full runs. The inventory-wide 1280/768/375 route tests run only in evidence mode, which writes per-width scorecards under its run root instead." This matches the code at every point. (a) `ROUTES` (spec:88-95) has 6 entries: 5 distinct paths plus `route.timeline.degraded`, which is `/audit/timeline` with `degrade: true`. (b) The non-evidence test "renders every curated operator route at 1280" (spec:425) skips in evidence mode (:430) and calls `captureCell`. (c) `captureCell` ends in `writeJson(scorecardPath(id), scorecard)` (:371), which writes under `routeScorecardsDir = resolve(generatedRoot, "route-scorecards")` (operator-surface-paths.ts:79). (d) The evidence inventory test writes `${id}-scorecard.json` under `runRoot()` (spec:401-402). The comment also agrees with the spec header (spec:17-19). **browser-full.yml:6-8** and **CONTRIBUTING.md:311-315** both state the same derived phrase plus "only in evidence mode", and neither makes a scorecard claim. A grep of both files for `inventor`, `three viewport`, `768`, `curated`, `scorecard` and `evidence` hits only the scoped blocks, so no false claim sits elsewhere in either file today. A `git grep` outside `.planning/` finds no other live scorecard-mode claim |
| 11 | D-24 browser gate: deviations from the expected failure set are honestly routed | VERIFIED (regression) | Register row `UI-HOME-SHOT-101` and SEED-008 are unchanged since round 2, and REQUIRED_IDS still pins the row (close check 5 `ok`). The C8 gate's CI browser lane is 418 / 0 failed, which matches the `ci.all` lane design (CI=true) |

**Score:** 11/11 truths verified (0 present, behavior-unverified)

The 246-10 plan-level must-haves were checked as well:
- The R2-WR-02 regexes and mutation controls exist (test:66-74) and the test is green.
- The scoping helpers `scoped_source(:browser_full | :playwright)` (test:288-324) match the plan.
- The R2-WR-01 phrase derive passes.
- REVIEW-DISPOSITION marks R2-WR-01 and R2-WR-02 `fixed` at e9a97139 (:115-116).
- No prohibited file was edited: C8 touches neither operator-page-capture.spec.ts nor operator-surface-paths.ts, and the playwright.config.ts diff changes comment lines only.

### Judgment on R3-WR-01 and R3-WR-02

**Verdict: both are warnings, not goal-blocking.** The goal clause is that docs are *consistent for the CI phase to measure*. That is a property of the docs as they stand, and truth 10 shows directly that all three sources match the code. Both R3 findings are about how well the contract test protects that consistency against *future* edits. Neither shows any doc being untrue today. The previous round used the same standard for R2-WR-02: it treated the narrow denylist as the reason the inversion escaped detection, not as a gap in itself.

**R3-WR-01** (the scoped denylist no longer sees the rest of each file): confirmed in code. `coverage_sources/0` (test:278-285) passes only the scoped text, and `coverage_wording_errors/3` runs both the positive check and `@false_claims` over it. A false sentence placed above the `Run Playwright` step in browser-full.yml would now pass, where C7's version refused it.
- **Severity:** Warning. It is a real loss of regression coverage introduced by C8, but it is latent. My grep of both files finds no coverage claim outside the scoped blocks, and the step comment at browser-full.yml:137-145 describes project derivation, not coverage.
- **Fix:** R3's split (positive check against the scoped text, denylist against the whole file, plus one control) is small, and should land as a C8 amendment or C9 before the removal squash lands.

**R3-WR-02** (the paraphrase guarantee is overstated): confirmed. The moduledoc (test:37-38) and the attribute comment (test:62-65) say the patterns stop paraphrases and refuse "both inversions". In fact the two scorecard patterns are near-literal sentences. 246-LANDING.md:288 repeats the overstatement ("refuses both scorecard inversions and the paraphrases").
- **Severity:** Warning. This is an inaccurate description of a test guard's strength, inside the test's own prose and a planning hand-off. It is not a misdescription of what CI runs or covers, which is what Phase 247 measures and what WR-01 was about.
- **Fix:** Either widen the patterns and add the positive scorecard pin R3 proposes, or narrow the moduledoc and LANDING wording to "refuses these specific sentences". The narrowing is a two-line fix.

Neither finding reverses truth 10, so neither is a gap. Both stay `open` in 246-REVIEW-DISPOSITION.md (:121-122) as tracked follow-ups.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `examples/threadline_phoenix/e2e/playwright.config.ts` | route-capture comment with the scorecard writer the right way round | VERIFIED | :27-30; contains `route-scorecards/` |
| `test/threadline/ci_coverage_doc_contract_test.exs` | twin-aware derive, regex denylist, scoped sources, mutation controls | VERIFIED | contains `scorecards run only in evidence mode` (:73); green |
| `CONTRIBUTING.md` | Browser-full sentence with distinct-route count plus degraded twin | VERIFIED | :311-315 |
| `.github/workflows/browser-full.yml` | honest header | VERIFIED | :6-8 |
| `246-LANDING.md` | nine-slice recipe including C8 | VERIFIED | :259, :303, :162, :288 (wording overstated, see R3-WR-02) |
| `246-REVIEW-DISPOSITION.md` | R2-WR-01/02 fixed; R3 rows merged | VERIFIED | :115-116, :121-126 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `CiCoverageDocContractTest` | `operator-page-capture.spec.ts` | parses `const ROUTES` / `const BREAKPOINTS` | WIRED | the derived phrase "5 curated operator routes plus a degraded Timeline twin at 1280" appears in all three sources |
| `CiCoverageDocContractTest` denylist | inverted scorecard claim | regex `scorecards run only in evidence mode` | WIRED (narrow) | refuses the exact pre-C8 sentence; paraphrases are not refused (R3-WR-02); scope limited to the blocks (R3-WR-01) |
| LANDING recipe | C8 commit | Removal-Slice trailer and cherry-pick list | WIRED | `--grep` derive returns e9a97139 |
| playwright.config.ts comment | spec `captureCell` / `routeScorecardsDir` | prose claim vs code | WIRED | spec:371 writes to `route-scorecards` (paths.ts:79), and only in the non-evidence test (:430) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Close check | `bash tools/verify-phase.sh --close` | `verify-phase: all checks passed` | PASS |
| Self-test | `bash tools/verify-phase.sh --self-test` | `verify-phase: all checks passed` | PASS |
| Targeted contracts | `mix test` on the six contract files | 126 tests, 0 failures | PASS |
| Browser-full project set | `bin/browser-full-projects --list config` | desktop-chromium, mobile-chromium, route-capture | PASS |
| Slice separability | per-slice `.planning/` count under `bash -c` | 9 slices, all 0 | PASS |
| LANDING totals | union / deletion recount over the 9 SHAs | 528 / 479 | PASS |
| Full gate | not re-run here (shared local Postgres); executor's ephemeral PG16 run on the C8 tree | exit 0 | PASS (recorded) |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| `.planning/phases/246-debt-closeout-and-critic-retirement/tools/verify-phase.sh` | `--close` / `--self-test` | both pass | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DEBT-01 | 01, 05, 06, 07, 09 | every carried-debt row dispositioned; cheap 215/223 fixed | SATISFIED | truths 1-3, 8, 11 |
| DEBT-02 | 01-04, 07, 08, 10 | critic loop removed, tagged for restore, suite/CI/docs consistent | SATISFIED | truths 4-7, 9, 10. Tag creation is a maintainer step after landing (D-13) |

No orphaned IDs. REQUIREMENTS.md maps only DEBT-01 and DEBT-02 to Phase 246 (:63-64), and both are claimed by plans. Their checkboxes and table rows still read Pending, because phase completion updates them.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| ci_coverage_doc_contract_test.exs | 278-285 | denylist runs only over scoped blocks (R3-WR-01) | Warning | latent; a future false claim outside the blocks would pass |
| ci_coverage_doc_contract_test.exs, 246-LANDING.md | 37-38, 62-65; 288 | paraphrase / "both inversions" guarantee overstated (R3-WR-02) | Warning | the guard is weaker than its prose says |
| ci_coverage_doc_contract_test.exs | 357-361, 170, 69 | R3-IN-01/02/04 (hard pins, entry count, mode-blind inventory pattern) | Info | |
| playwright.config.ts | 29 | 126-column unwrapped comment line (R3-IN-03) | Info | cosmetic |
| stress_ledger_test.exs, ci_topology_contract_test.exs, operator-surface-paths.ts | - | round-1 WR-03/04/05 still open | Warning | unchanged from earlier rounds; not goal-blocking |

No TBD/FIXME/XXX markers in the four C8 files.

### Human Verification Required

None. The R3-WR-01 and R3-WR-02 severity calls are resolved above.

### Gaps Summary

The single remaining gap from round 2 is closed. The playwright.config.ts route-capture comment now names the right scorecard writer: the curated non-evidence smoke that Browser-full runs writes `route-scorecards/`, and evidence mode writes per-width scorecards under its run root. All three coverage sources Phase 247 measures from match the code, and no regression was found in the other ten truths.

Two warnings remain open in the disposition file. R3-WR-01 means the scoped denylist is blind outside its blocks. R3-WR-02 means the paraphrase guarantee is overstated in the test prose and LANDING:288. Neither makes any current doc untrue. Both are cheap enough to fold into the removal squash before landing: split the scope for the denylist, and narrow or strengthen the guarantee wording. They do not hold back phase completion.

---

_Verified: 2026-10-26T03:18:58Z_
_Verifier: Claude (gsd-verifier)_
