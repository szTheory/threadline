---
phase: 198-green-bringup
verified: 2026-08-29T00:00:00Z
status: gaps_found
round: 4
supersedes: "Round 3 section of this same file (verified 2026-08-28, gaps_found, 3/6 SC / 10/12 requirements). Round-3 content is PRESERVED VERBATIM below under 'ARCHIVED — Round 3' and is reconciled, not discarded. This Round 4 section is authoritative."
ci_measured:
  round_1: "PR #29, run 33183920952, FAILURE (6/13 checks red)"
  round_2: "PR #29, run 33197493051, FAILURE — 13m29s"
  round_3: "PR #30 (draft, DO NOT MERGE), run 33204829086, FAILURE — 13m29s, 3/12 needs: red"
  round_4: "PR #31 (draft, DO NOT MERGE), run 33253587315, attempt 1, head f433ef3e, FAILURE — 8m11s, 3/12 needs: red, 0 skipped, 0 cancelled"
score: 3/6 roadmap success criteria verified (10/12 requirements Complete, 2 Pending — GREEN-04, GREEN-07). Unchanged from round 3; no requirement crossed either way.
behavior_unverified: 0
overrides_applied: 0
integrity_verdict: "PASS — no laundering found. All six named laundering vectors independently re-derived and clean (see 'Integrity Audit' below)."
re_verification:
  previous_status: gaps_found (round 3)
  previous_score: "3/6 roadmap success criteria (10/12 requirements)"
  gaps_closed:
    - "GREEN-04's round-3 cause (9 demo-seed content mismatches across DemoContractTest / WalkthroughHappyPathTest / WalkthroughEvidenceTest, the D-41 class) — CLOSED at cause by plans 198-23/24/25 and confirmed on measured CI run 33253587315: the job reports '109 tests, 1 failure' and none of those tests appear among the failures."
    - "A genuine production defect: lib/threadline/operator_surface/live/export_status_live.ex:489 carried a private duplicate label branch returning \"Expired\" while the spec-tested canonical Threadline.OperatorSurface.Presentation.export_action_label/2 (presentation.ex:340, spec-tested since Phase 137 at presentation_test.exs:84) returns \"Export expired\". Fixed toward the canonical source; presentation.ex and presentation_test.exs untouched this round, so the fix direction is independently anchored, not self-confirming."
    - "Playwright: all five of round 3's named failing tests now PASS by name on run 33253587315 (operator-find-mobile.spec.ts:48/66/103, operator-phase-135-uat.spec.ts:76, operator-phase-173-uat.spec.ts:74), plus 198-28's two CI-contributing screenshot rows. 198-26/27/28's fixes held, measured on CI."
  gaps_remaining:
    - "GREEN-04 — 'Run test suite (current)' still concludes failure on run 33253587315, now for a THIRD distinct cause: ThreadlinePhoenix.DemoResetTest 'prod mix demo.reset fails fast without DEMO_ALLOW_RESET=1' (examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs:56) times out at 60000ms in a System.cmd(\"mix\", [\"demo.reset\"], env: MIX_ENV=prod) cold prod compile with no @tag timeout:. Independently confirmed: the test exists at that line, shells out exactly as described, and carries zero @tag directives."
    - "GREEN-07 — 'CI required' concluded the literal string failure with 3 of 12 needs: members red (verify-test, verify-example-browser, verify-capture), 9 success, 0 skipped, 0 cancelled. Time clause MET at 8m11s. Independently re-derived by this verifier from `gh run view 33253587315 --json jobs`, not read from the write-up."
  regressions:
    - "One self-reported, self-caused regression, disclosed by the phase itself rather than found by this verifier: 198-25's \"Expired\" -> \"Export expired\" copy fix breaks two Playwright specs whose locators use the capital-E regex /Expired|File unavailable/ (operator-accessibility.spec.ts:611, operator-prove-mobile.spec.ts:60). Independently confirmed present in both files at HEAD. Recorded in deferred-items.md and WINDOWS.md #10/#11 with the corrected diagnosis, owned by a round-5 plan. Disclosing a regression your own fix caused is the opposite of laundering; it is scored here as an open gap, not as an integrity finding."
gaps:
  - truth: "GREEN-04 — mix test passes with no deterministically-failing tests, each former failure fixed on its merits"
    status: failed
    reason: "Per D-01 only measured CI is admissible. On run 33253587315 the check 'Run test suite (current)' concluded failure. The job's root-suite step passed (1423 tests, 0 failures, 1 excluded); the failing step is 'Verify Threadline Phoenix example' (mix verify.example), 109 tests / 1 failure. Causes 1 (search_path, closed since 198-19) and 2 (demo-seed content, closed by 198-23/24/25) are both genuinely closed; cause 3 is a newly-visible CI-only test-harness timeout. Local mix verify.example measured 109/0 twice — recorded side by side and correctly refused as evidence."
    artifacts:
      - path: "examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs:56"
        issue: "System.cmd shell-out to a cold MIX_ENV=prod compile with no @tag timeout: budget; exceeds ExUnit's 60000ms default on CI. Verified: zero @tag directives in the file."
    missing:
      - "A timeout budget or a restructuring of demo_reset_test.exs:56 that does not require a cold prod compile inside the 60s ExUnit default, then a fresh measured CI run confirming 'Run test suite (current)' concludes the literal string success"
  - truth: "GREEN-07 — origin/main carries every local commit and its latest CI run concludes success in <= 20 minutes"
    status: failed
    reason: "Time clause MET (8m11s, independently re-derived from createdAt 2026-08-29T12:52:18Z / updatedAt 13:00:29Z). Success clause NOT MET: `gh run view 33253587315 --json jobs` independently returns conclusion failure for CI required, Example app browser E2E (Playwright), Run test suite (current), and Tier A capture lane; the other 10 jobs are success. origin/main is a97f527e and is 145 commits behind HEAD (137 behind the measured head f433ef3e). PR #31 mergeStateStatus BLOCKED."
    artifacts:
      - path: "GitHub Actions run 33253587315 (PR #31, ci/198-round4, attempt 1)"
        issue: "conclusion failure; 3/12 ci-required needs: members red; 0 skipped, 0 cancelled — so no member's verdict was laundered through the D-09 skipped-scores-as-passing hazard"
    missing:
      - "Close GREEN-04's third cause (removes verify-test from the red set)"
      - "A round-5 plan for the Playwright lane: the two /Expired/ locator rows this round's own fix broke, plus the un-inventoried operator-responsive-mobile-first.spec.ts:577:5 'Row history' failure"
      - "Tier A capture lane remains structurally uncloseable inside this milestone (D-39 forbids page.* regeneration, its only remedy). GREEN-07 cannot close through this lane until that milestone-level constraint lifts — a constraint outside Phase 198's authority, not an unfixed defect."
deferred:
  - truth: "The Tier A capture lane's 198-file scorecard drift (120 page.*, 78 refute.*)"
    addressed_in: "Beyond v1.41 — milestone-level prohibition (D-39), not a later phase"
    evidence: "REQUIREMENTS.md 'Out of Scope': 'Regenerating Tier-A page.* scorecards — Not reproducible in this environment (v1.40 Seed #3). The committed scorecards are the floor; regenerating them would manufacture a floor rather than measure one.'"
  - truth: "Two operator-stress.spec.ts page.* ledger-baseline screenshot diffs (page.home.happy, page.timeline.empty, dark 1024px)"
    addressed_in: "Beyond v1.41 — same D-39 class"
    evidence: "Same 'Out of Scope' row; no PNG baseline was regenerated anywhere in the phase (verified: git diff 412123ca..HEAD -- '*.png' is empty)"
human_verification: []
---

# Phase 198: Green Bringup — Verification Report (Round 4)

**Phase Goal:** `origin/main` carries every local commit and its CI concludes green well inside a usable feedback loop; the red-test baseline that nobody re-derived is retired with each former failure fixed on its merits; branch protection requires exactly the checks CI emits; and the measurement sweep that sizes Phases 201 and 203 is on disk before either is planned.

**Verified:** 2026-08-29 · **HEAD:** `455c2328` · **Status:** `gaps_found`
**Re-verification:** Yes — round 4, covering plans 198-23 … 198-29. Round-3 content is preserved verbatim below.

---

## Verdict in one paragraph

**The phase goal is NOT achieved, and the phase's own records say so accurately.** `CI required` concludes the literal string `failure` on the only admissible evidence (run `33253587315`), so the headline sentence — "its CI concludes green" — remains false. Two of twelve requirements (GREEN-04, GREEN-07) are correctly Pending. **On process integrity, however, this round is a clean PASS**: this verifier independently re-derived every one of the six named laundering vectors from primary sources and found no violation. Nothing was narrowed, regenerated, skipped, weakened, or retro-edited to make the number look better; the round's stated target (red `needs:` 3 → 1) was missed, the locked pre-push prediction (2) was falsified, and both are recorded as such in the phase's own ledger with the prediction section left byte-unchanged. **Goal: FAILED. Integrity: PASS.**

---

## Integrity Audit — the six named laundering vectors

Every row below was re-derived by this verifier from primary sources (`gh` API, `git diff`, `psql`, file reads). None was accepted from `198-CI-MEASUREMENT.md` or any SUMMARY.

| # | Vector | Independent check run | Result | Verdict |
|---|---|---|---|---|
| 1 | GREEN-04 / GREEN-07 laundered to Complete, or justified by local output | Read `.planning/REQUIREMENTS.md` lines 14, 17, 133, 136. Re-derived the run with `gh run view 33253587315 --json attempt,conclusion,createdAt,updatedAt,headSha,jobs` | Both carry `- [ ]` and `Pending` in both the checklist and the status table. `attempt: 1`, `conclusion: failure`, head `f433ef3e`, `12:52:18Z → 13:00:29Z` = **8m11s** — every figure matches. Job conclusions re-derived independently: 3 red lanes + the aggregate, 10 green. The GREEN-04 note explicitly states local `109 tests, 0 failures` is "a readiness signal only and is NOT admissible evidence for this requirement." | ✓ CLEAN |
| 2 | A gate narrowed to manufacture green (D-42) | `git diff --stat 4a62a006..HEAD -- .github/workflows/ci.yml .github/rulesets/main.json CONTRIBUTING.md examples/threadline_phoenix/e2e/playwright.config.ts`; also `git diff --stat f433ef3e..HEAD -- .github/ CONTRIBUTING.md ...` | **Both empty.** `ci-required`'s `needs:` list read directly at `ci.yml:754-766` — **all 12 members present**, `allowed-skips`/`allowed-failures` deliberately absent (`ci.yml:774-778`). The run's own alls-green step reports 9 success / 3 failure / **0 skipped / 0 cancelled**, so the D-09 skipped-scores-as-passing hazard is provably not in play. | ✓ CLEAN |
| 3 | Evidence regenerated (D-39) | `git diff --stat 412123ca..HEAD -- '*.png' '.planning/scorecards/'` — the **entire phase**, not just round 4 | **Empty.** Not one PNG baseline and not one committed scorecard changed across all of Phase 198. The Tier A lane and the two `operator-stress.spec.ts` screenshot rows are red **by construction**, exactly as claimed. | ✓ CLEAN |
| 4 | A test skipped, tagged out, weakened, or excluded | Grepped the round-4 diff for added `@tag :skip` / `@moduletag :skip` / `test.skip` / `.skip(` / `xit(` / `it.todo`; `git diff 4a62a006..HEAD -- '**/test_helper.exs'`; hand-read every removed `assert`/`expect`/`refute` line | **Zero skips added. `test_helper.exs` untouched.** Every removed assertion was replaced by a **stronger** one — `refute timeline_html =~ "View Incident"` → `assert timeline_html =~ "No captured changes"` (a vacuous refute replaced with a positive emptiness assertion); `assert coverage_html =~ "covered"` → two chip assertions (`"Covered"` AND `"Needs capture"`, so an all-covered or trigger-empty DB can no longer pass); `getByText("Signed in as")` → scoped to `.rd-signed-in`; `{ name: "Exports" }` → `{ name: "Exports", exact: true }`. This is the opposite of weakening. | ✓ CLEAN |
| 5 | `search_path` / `storage_schema` ALTER on the local `threadline_test` DB | `psql -Atqc "select d.datname, s.setconfig from pg_db_role_setting s join pg_database d on d.oid=s.setdatabase where d.datname like 'threadline%'"` | `threadline_test` → **NONE**. Settings exist only on `threadline_phoenix_test` and the 198-25 scratch DB `threadline_phoenix_test_198_25` — both the EXAMPLE APP class, mirroring the legitimate `ci.yml:361-362` ALTER. **The forbidden masking remedy did not reach `threadline_test`.** | ✓ CLEAN |
| 6 | The missed target hidden, or the prediction retro-edited | `git show f433ef3e:198-CI-MEASUREMENT.md` → extracted the prediction section → `diff` against HEAD's copy | **Byte-identical.** The only delta is the *appended* next section header; not one character of the prediction was altered. The measured section records, unsoftened: "**The target was MISSED**" (3 vs the target of 1, delta 0 against round 3) and "**That prediction is FALSIFIED**" (2 predicted vs 3 measured), plus an explicit note that the prediction "is not amended, annotated, or corrected in place — a prediction edited after its scoring is not a prediction." | ✓ CLEAN |

**Integrity verdict: PASS. Zero violations found across all six vectors.**

---

## Nuance handling — was anything over- or under-claimed?

| Nuance | What the write-up claims | This verifier's finding |
|---|---|---|
| Playwright "5 failed" is right-censored | `playwright.config.ts:141` `maxFailures: process.env.CI ? 5 : 0` and `188 did not run`; the write-up states up front that 5 is "a floor, not a census" and that **"5 vs 5, delta 0 must NOT be read as 'no progress'"**, then compares **composition** instead — all five round-3 failures pass by name on run 33253587315. | ✓ **Correct in both directions.** The config line is verified verbatim at `playwright.config.ts:141`. The reasoning is sound and, notably, does not over-claim the other way either: it does **not** convert "different failures" into "progress toward green", and it records the lane's conclusion as `failure` with a per-failure cause table. It further self-scores the lane's *composition* prediction as only **2/5 correct** and names the methodological reason (the local inventory was unbounded, `maxFailures: 0`, so it samples a different population than a capped CI run). That is a miss volunteered against itself. |
| Tier A drift spans 198 files, workflow truncates at `head -200` | The write-up states the diff is "**truncated at 200 lines by the workflow itself**", names the 15 visible files, and writes: "The remaining 183 files — including all 78 `refute.*` cells — are **not visible** in the truncated diff, and this record therefore **does NOT claim** the drift is confined to `scroll_cost` or to `page.*` cells. It claims only what the log shows." | ✓ **Correctly scoped.** The unobservable majority is explicitly not characterised. The visible `scroll_cost` values (1280 `18.803→40.8`, 768 `19.038→36.504`, 375 `19.85→41.953`) are asserted byte-identical to rounds 2 and 3 — a determinism claim about the *visible* subset only, which is the right scope. |
| `attempt: 1` holds | Claimed; `(retry #1)` lines are in-suite Playwright retries, not workflow re-runs. | ✓ **Independently confirmed** — `gh run view --json attempt` returns `1`. No re-run, no selective retry. |
| GREEN-04's third cause | Diagnosed as a CI-only cold `MIX_ENV=prod` compile exceeding the 60s ExUnit default. | ✓ **Substantiated, with one advisory.** `demo_reset_test.exs:56` is exactly that test; `:69` is the `System.cmd("mix", ["demo.reset"], cd:, env: [{"MIX_ENV","prod"}])`; the file carries **zero** `@tag` directives — all independently confirmed. The stacktrace (`System.do_port_byte/3`) and the cited `DBConnection` ownership-timeout symptom fit. **Advisory (not a finding):** the log does not itself show compile output, so "cold prod compile" is a well-supported *inference*, stated slightly more definitively than the primary evidence strictly licenses. It does not affect the verdict — the requirement is Pending either way, and the write-up nowhere uses the diagnosis to soften the status. |

---

## What genuinely closed — assessed on the merits

| Fix | Merit assessment |
|---|---|
| **Demo-seed class (D-41), plans 198-23/24/25** | ✓ **Fixed at cause.** 198-23 scoped `RetentionTail.run/1`'s unscoped `Retention.purge/1` cutoff to the fictional epoch (7 of 9 failures) — a real seed-pipeline defect, not a test edit. Confirmed on CI: the nine `DemoContractTest` / `WalkthroughHappyPathTest` / `WalkthroughEvidenceTest` failures are gone from run `33253587315`. 198-24 additionally **hardened** the surviving assertions against vacuous-pass and version-literal rot rather than leaving them at the strength that let the bug hide. |
| **Production defect: `export_status_live.ex` label drift, plan 198-25** | ✓ **A real production defect, fixed in the correct direction.** `lib/threadline/operator_surface/live/export_status_live.ex:489` returned `"Expired"`; the canonical `Presentation.export_action_label/2` (`presentation.ex:340`) returns `"Export expired"` and has done so since Phase 137 (`presentation_test.exs:84`, blamed to `7b9e0348 feat(137-01)`). **`presentation.ex` and `presentation_test.exs` are untouched this round** (`git diff --stat` empty), so the fix is anchored to an independent, pre-existing spec — it is not a test edited to match new code. The three test files updated alongside it were asserting the *drifted* literal, so updating them is following the canonical source, not moving the goalposts. |
| **Playwright clusters, plans 198-26/27/28** | ✓ **Fixed at cause, measured on CI.** Each change carries a cited product-source reason: `.rd-nav__identity` added in v1.38 broke strict mode (scope the locator); `tl-row-action--capture` renders collapsed by default (expand before asserting); `data-testid="row-history-drawer"` lands on the full-viewport scrim shell not the bounded `.tl-drawer` panel (screenshot the panel that the baseline is sized to — **no baseline was regenerated**); the `Actor: user / {id}` literal was removed by `3022e2e0 feat(186-01)` (assert the `.tl-secondary-ref[title=...]` the page now renders). All five round-3 failures plus 198-28's two CI-contributing rows pass by name on CI. |
| **198-28's blocking decision** | ✓ Answered **"no committed PNG baseline may be regenerated"** — the harder option, taken under auto-mode. Verified by outcome: `git diff -- '*.png'` across the whole phase is empty. |

**One advisory on merit (⚠️ WARNING, not a blocker):** plan 198-27 collapsed the twelve per-story Phase-177 viewport tests into **one** test looping over a runtime-resolved story catalog (`operator-phase-177-uat.spec.ts`). The anti-rot rationale is genuine and every assertion is preserved. But the loop short-circuits on first failure, so a single broken story now hides the remaining eleven within a run — a real reduction in per-run diagnostic granularity, and it shrinks the lane's test count under a `maxFailures: 5` cap. **This is not scored as laundering**: the write-up never uses test counts as evidence of progress (it explicitly disclaims the 5-vs-5 comparison and compares by name instead), and the change is documented with its reason in-line. Worth a round-5 look at using `test.step`-per-story with soft assertions, or a parameterised `for` over the resolved catalog.

---

## Observable Truths — Round 4

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Measurement sweep on disk; `.credo.exs` unmodified; no scorecard touched (GREEN-01/02/03) | ✓ VERIFIED | Unchanged since round 1. Re-confirmed phase-wide: `git diff 412123ca..HEAD -- '.planning/scorecards/'` is **empty** |
| 2 | `mix test`-equivalent passes on real CI (GREEN-04's only admissible evidence, D-01) | ✗ FAILED — **third** distinct cause | Run `33253587315`, `Run test suite (current)` = `failure`, re-derived via `gh run view --json jobs`. Root suite passed (`1423 tests, 0 failures, 1 excluded`); `mix verify.example` = `109 tests, 1 failure`. Causes 1 (search_path) and 2 (demo-seed) both independently confirmed closed |
| 3 | The demo-seed content class (D-41) is fixed at cause, not deferred or masked | ✓ VERIFIED | `retention_tail.ex` cutoff scoped to the fictional epoch; none of the nine round-3 failing tests appears on run `33253587315`; assertions strengthened, none removed |
| 4 | The `export_action_label` drift is fixed toward the canonical spec-tested source | ✓ VERIFIED | `presentation.ex:340` + `presentation_test.exs:84` (Phase 137, `7b9e0348`) untouched this round; the LiveView duplicate now matches. `mix test` on `copy_contract_test.exs` + `ci_topology_contract_test.exs`: **27 tests, 0 failures**, run fresh by this verifier |
| 5 | Formless-page guard (GREEN-05) | ✓ VERIFIED | Unchanged since round 1; no round-4 change touched `lib/threadline/operator_surface/live/*` beyond the one-line label fix |
| 6 | Every job carries `timeout-minutes`; browser suite aborts early (GREEN-06) | ✓ VERIFIED | `playwright.config.ts:141` `maxFailures: process.env.CI ? 5 : 0` read verbatim; `Run example Playwright suite` carries `timeout-minutes: 14` under an 18-minute job bound, deliberately step-first so the failure-artifact upload survives |
| 7 | `origin/main` carries every local commit and its latest CI run concludes `success` ≤ 20 min (GREEN-07) | ✗ FAILED (time clause met) | 8m11s ≤ 20m — **met**, and faster than round 3's 13m29s. `CI required` = `failure`; 3/12 `needs:` red, 9 success, **0 skipped, 0 cancelled**. `origin/main` = `a97f527e`, 145 commits behind HEAD. PR #31 `BLOCKED` |
| 8 | Branch protection requires exactly the emitted names; the aggregate stays a singleton as `needs:` evolves (GREEN-08 + D-42) | ✓ VERIFIED | `.github/rulesets/main.json` byte-unchanged this round; `ci_topology_contract_test.exs` re-run by this verifier and passes; all 12 `needs:` members present at `ci.yml:754-766` |
| 9 | Paid critic scoring untriggerable; exactly one gated Hex publish path (GREEN-09/10) | ✓ VERIFIED | Re-run: `ls .github/workflows/` → `branch-protection, browser-full, ci, flake-detection, release` (no `ui-critic.yml`, no `hex-publish.yml`); `grep -rl ANTHROPIC .github/` → empty; `grep -rl "hex.publish" .github/workflows/` → `release.yml` only |
| 10 | Flake Detection broken-vs-flaky + dedup; one worktree, archive tags recorded (GREEN-11/12) | ✓ VERIFIED | `git worktree list` → exactly one entry (`/Users/jon/projects/threadline 455c2328 [main]`); all executor worktrees cleanly merged and removed |
| 11 | Nothing was narrowed, regenerated, skipped, weakened, or retro-edited (D-39 / D-42 / D-01) | ✓ VERIFIED | See Integrity Audit — all six vectors independently re-derived clean |

**Score: 3/6 roadmap success criteria verified · 10/12 requirements Complete.** Unchanged from round 3.

### Roadmap Success Criteria

| SC | Requirements | Status | Note |
|---|---|---|---|
| 1 | GREEN-01/02/03 | ✓ VERIFIED | Unchanged |
| 2 | GREEN-04, GREEN-05 | ✗ FAILED | GREEN-05 met; GREEN-04 blocked by the `demo_reset_test.exs:56` CI-only timeout |
| 3 | GREEN-06, GREEN-07 | ✗ FAILED | GREEN-06 met; the ≤20-min clause is met at 8m11s; the `success` clause is not |
| 4 | GREEN-08 | ⚠️ PARTIAL | First clause met (protection names exactly one context, `CI required`, matching `ci.yml`'s emitted `name:`). Second clause — "PR #26 is mergeable" — is **false**: PR #26 `mergeStateStatus: BLOCKED`, a downstream consequence of GREEN-07's red aggregate, not a protection-configuration defect |
| 5 | GREEN-09, GREEN-10 | ✓ VERIFIED | Unchanged |
| 6 | GREEN-11, GREEN-12 | ✓ VERIFIED | Unchanged |

### Requirements Coverage — agreement with REQUIREMENTS.md

| Req | REQUIREMENTS.md | This verifier | Agreement |
|---|---|---|---|
| GREEN-01/02/03 | `[x]` Complete | ✓ SATISFIED | Yes |
| **GREEN-04** | `[ ]` **Pending**, cites run `33253587315`, names the third cause, explicitly refuses the local 0-failure figure | ✗ BLOCKED — independently confirmed from `gh run view` | **Yes — no over-claim, no under-claim.** It correctly credits the two closed sub-causes while keeping the requirement open |
| GREEN-05/06 | `[x]` Complete | ✓ SATISFIED | Yes |
| **GREEN-07** | `[ ]` **Pending**, cites the 3-of-12 breakdown, records 0 skipped / 0 cancelled, states `needs:` was not narrowed, records the target as MISSED and the prediction as FALSIFIED | ✗ BLOCKED — independently confirmed | **Yes — correctly recorded.** Unusually precise: it volunteers its own missed target inside the requirement text |
| GREEN-08 | `[x]` Complete | ✓ SATISFIED (see SC 4 note on the mergeability clause) | Yes |
| GREEN-09/10/11/12 | `[x]` Complete | ✓ SATISFIED | Yes |

**No orphaned requirements.** All twelve GREEN IDs are claimed by plans 198-01…198-12; plans 198-13…198-29 are gap-closure rounds declaring no new IDs, which is correct.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| The measured run is real, single-attempt, and 8m11s | `gh run view 33253587315 --json attempt,conclusion,createdAt,updatedAt,headSha` | `attempt: 1`, `failure`, `12:52:18Z → 13:00:29Z`, `f433ef3e` | ✓ PASS |
| The 3-red / 10-green job split is real | `gh run view 33253587315 --json jobs` | 3 red lanes + aggregate; 10 green; no skipped/cancelled | ✓ PASS |
| `ci-required` still has all 12 `needs:` members | Read `ci.yml:754-766` | 12 members, `allowed-skips`/`allowed-failures` absent | ✓ PASS |
| D-42 interlock + canonical-copy contracts still hold | `mix test test/threadline/ci_topology_contract_test.exs test/threadline/operator_surface/copy_contract_test.exs` | `27 tests, 0 failures` | ✓ PASS |
| No `search_path` on `threadline_test` | `psql` against `pg_db_role_setting` ⋈ `pg_database` | `threadline_test` → NONE | ✓ PASS |
| No PNG / scorecard regenerated, phase-wide | `git diff --stat 412123ca..HEAD -- '*.png' '.planning/scorecards/'` | empty | ✓ PASS |
| Prediction section byte-unchanged | `diff <(git show f433ef3e:...CI-MEASUREMENT.md \| sed -n '/Prediction stated before/,$p') <current>` | identical modulo the appended next-section header | ✓ PASS |
| Post-measurement commits are documentation-only | `git diff --name-only f433ef3e..HEAD` | 6 files, all under `.planning/` | ✓ PASS |
| No debt markers in round-4 source | `grep -nE "TBD\|FIXME\|XXX"` over every non-`.planning` file in `4a62a006..HEAD` | zero hits | ✓ PASS |

### Probe Execution

No `scripts/*/tests/probe-*.sh` exists for this phase. **CI is the probe**, and its measured run is the evidence — reproduced above from the `gh` API by this verifier rather than read from any SUMMARY. SKIPPED (no conventional probe scripts; the CI run is the equivalent evidence class and was independently executed).

### Anti-Patterns Found

None. Zero debt markers in round-4 source; zero skips added; zero assertions weakened; the only two removed-and-replaced assertion sites are both **strengthenings**.

### Human Verification Required

**None.** Infrastructure/gating phase, no product or UI change in scope. Every truth is mechanically checkable (`gh` API, `git`, `psql`, file reads) or settled by a recorded maintainer decision (D-39/D-41/D-42). No behavior-dependent truth was left unexercised.

### Gaps Summary

Two requirements remain genuinely unmet — **GREEN-04** and **GREEN-07** — and the phase goal's headline sentence ("its CI concludes green") is still false. That is a real failure to reach the goal and it is not softened here.

But the failure is honest at every layer this verifier could test. The round moved three of the four red-lane *causes*: the demo-seed class is closed at cause, a genuine production label-drift defect was found and fixed toward its canonical spec, and all five of round 3's named Playwright failures pass by name on CI. What did **not** move is the metric that counts — the red `needs:` count held at 3 (delta 0 against a target of 1), because closing one cause exposed a third, previously-invisible one behind it (`demo_reset_test.exs:56`), and because this round's own copy fix broke two Playwright locators — a regression the phase **disclosed against itself** rather than absorbing.

The remaining gaps split cleanly:

1. **Actionable in a round 5:** the `demo_reset_test.exs:56` timeout budget (GREEN-04's sole blocker), the two `/Expired/` locator rows this round caused, and the un-inventoried `operator-responsive-mobile-first.spec.ts:577:5` failure whose cause is honestly recorded as **not established** rather than guessed.
2. **Structurally uncloseable inside v1.41:** the Tier A capture lane and the two `operator-stress.spec.ts` `page.*` baseline diffs. Their only remedy is `page.*` regeneration, which D-39 forbids for the milestone. These are red **by construction, not by defect** — and the maintainer explicitly declined to make them green by removing the lane from `needs:`.

**Status: `gaps_found`** — the goal is not achieved. **Integrity: PASS** — no laundering found on any of the six vectors, and this round's records are, if anything, harder on themselves than a neutral reader would require.

---
---

# ARCHIVED — Round 3 Verification Report (preserved verbatim)

> The section below is the round-3 report exactly as written on 2026-08-28. It is superseded by the Round 4 section above, but preserved unedited: a superseded verification record edited in place is not a record.


# Phase 198: Green Bringup — Verification Report (Post-Gap-Closure, Round 3)

**Phase Goal:** `origin/main` carries every local commit and its CI concludes green well inside a usable feedback loop; the red-test baseline that nobody re-derived is retired with each former failure fixed on its merits; branch protection requires exactly the checks CI emits; and the measurement sweep that sizes Phases 201 and 203 is on disk before either is planned.

**Verified:** 2026-08-28
**Status:** gaps_found
**Re-verification:** Yes — supersedes round-2 `198-VERIFICATION.md`. This report covers gap-closure round 3 (plans 198-19 through 198-22: the missing `ALTER DATABASE` fix, the CR-01/CR-02 call-site-sweep closure, the maintainer-decided `needs:` disposition checkpoint, the standing-interlock contract tests, and a fresh measured CI push).

## Goal Achievement — the phase goal is NOT fully achieved

CI on the real, measured PR run (`33204829086`) concludes `failure`. `origin/main` therefore still does not carry a green-CI state of every local commit — the plainest reading of the phase's own headline sentence remains false. This is scored honestly below. Real, independently-confirmed progress happened this round (the search_path defect that was GREEN-04's originally-named cause is genuinely closed, and two call-site-sweep blind spots are closed with proof of teeth), but the requirement-level scoreboard for GREEN-04 and GREEN-07 has not crossed to "met," and per this verifier's explicit instructions, those two are NOT marked met here.

### Reconciliation with Round 2

Round 2 left `Run test suite (current)` red because of a missing `ALTER DATABASE threadline_phoenix_test SET search_path` statement at `ci.yml:235-240`. This round's plan 198-19 added it — independently confirmed by this verifier (`grep -n "ALTER DATABASE" .github/workflows/ci.yml` returns exactly 3 hits, all naming `threadline_phoenix_test`, at lines 247, 362, 516 in the current file — matching round 3's db-prep step for the `current` lane plus the two pre-existing sibling jobs). On the round-3 measured run, `grep -c "undefined_table"` against the job's full log is `0`, and none of the job's 9 failures cite `Postgrex.Error 42P01`. **The originally-named GREEN-04 cause is genuinely closed, not merely claimed closed.**

But `Run test suite (current)` is still red on the same measured run, for a *different*, previously-masked cause: `mix verify.example` (which never ran to completion in any prior round, because `mix verify.test` failed first every time before this round) now runs and reports 9 failures out of 109 tests — pre-existing demo-seed content mismatches, a class explicitly named in advance by `198-CONTEXT.md` D-41 as this round's predicted outcome. This is the textbook shape of "fixing the first-diagnosed cause exposes a second, previously-invisible cause underneath it" — not a failure to fix what was promised, and not conflated with the closed defect in either `REQUIREMENTS.md`'s own text or this report.

**Net honest position: GREEN-04's requirement text is more precisely true today than at round 2's close (the exact defect it was originally opened against is closed and cited), but the requirement as a whole is still Pending** because a distinct defect keeps the same CI check red. Round 3's own `198-CONTEXT.md` D-41 states this outcome explicitly and in advance — it is not an unexamined gap, it is a maintainer-ratified, evidence-cited deferral to a dedicated successor round.

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Measurement sweep (GREEN-01/02/03) on disk, `.credo.exs` unmodified, no scorecard touched | ✓ VERIFIED (unchanged since round 1) | `.planning/audits/198-ci-run-28214113903-logs.md` present on disk; not touched by any round-3 plan |
| 2 | `mix test` passes locally with no deterministically-failing tests | ✓ VERIFIED (local only, not admissible for GREEN-04 per D-01) | Independently re-run by this verifier: `test/threadline/ci_topology_contract_test.exs` (14 tests, 0 failures) and `test/threadline/operator_surface/ui_form_policy_contract_test.exs` (1 test, 0 failures) both pass fresh |
| 3 | `mix test`-equivalent passes on real CI (GREEN-04's own admissible evidence) | ✗ FAILED — new cause | CI run 33204829086: `Run test suite (current)` `failure`; originally-named `undefined_table` cause independently confirmed closed (0 occurrences); 9 demo-seed content-mismatch failures remain, per D-41 |
| 4 | The static call-site sweep enumerates every Ecto call site against Threadline-owned schemas, no escape hatch (round-2's CR-01/CR-02 blind spots) | ✓ VERIFIED | 198-REVIEW.md hand-traced both regex fixes independently; this verifier independently re-ran the touched test files (36 tests, 0 failures per 198-REVIEW.md; this verifier separately confirmed `ci_topology_contract_test.exs` alone at 14/0) |
| 5 | Formless-page guard fails loudly on a legitimate new form (GREEN-05) | ✓ VERIFIED (unchanged since round 1) | `@ui_form_policy` present on all 11 files under `lib/threadline/operator_surface/live/*.ex`, self-declared, not an allowlist; `ui_form_policy_contract_test.exs` (1 test, 0 failures) independently re-run by this verifier |
| 6 | Every job carries `timeout-minutes`; browser suite aborts early (GREEN-06) | ✓ VERIFIED (unchanged since round 1) | `grep -c timeout-minutes` across all 5 workflow files returns non-zero in each; `playwright.config.ts:141` `maxFailures: process.env.CI ? 5 : 0` independently confirmed present |
| 7 | `origin/main` carries every local commit and its latest CI run concludes `success` <=20min (GREEN-07) | ✗ FAILED | Run 33204829086: wall clock 13m29s (time clause met), conclusion `failure` (success clause not met); `origin/main..HEAD` = 88 commits, unchanged; PR #30 `mergeStateStatus`: `BLOCKED` |
| 8 | Branch protection requires exactly the emitted check names; the aggregate ruleset stays a singleton even as `needs:` evolves (GREEN-08 + D-42 standing interlock) | ✓ VERIFIED | `.github/rulesets/main.json` independently read: exactly one `required_status_checks` context, `"CI required"`; `ci_topology_contract_test.exs`'s new ruleset-singleton and needs:-roster-drift tests independently re-run by this verifier (14 tests total, 0 failures) — mutation-tested per 198-REVIEW.md against a one-character ruleset change and a silently-dropped needs: entry, both caught |
| 9 | Paid critic scoring untriggerable; exactly one gated Hex publish path (GREEN-09/10) | ✓ VERIFIED (unchanged since round 1) | Independently re-confirmed: `.github/workflows/ui-critic.yml` absent from `ls .github/workflows/`; `grep -rl ANTHROPIC .github/` returns empty; `grep -rl "hex.publish" .github/workflows/` returns exactly `release.yml` |
| 10 | Flake Detection classifies broken vs flaky, dedup issue; one worktree, no stale local branches, archive tags recorded (GREEN-11/12) | ✓ VERIFIED (unchanged since round 1) | `.github/workflows/flake-detection.yml` independently read: names broken/flaky/unknown explicitly, `timeout-minutes: 120`, dedup issue logic present; `git worktree list` returns exactly one entry; `.planning/ARCHIVE-REGISTER.md` has 2 rows, both with matching `archive/*` tags independently confirmed via `git tag -l "archive/*"` |

**Score:** 3/6 roadmap success criteria fully verified (Criteria 1, 5, and the unchanged parts of 6 — same criteria as round 2, no new criterion crossed to fully-met because the same two requirements remain Pending). 10/12 requirements Complete (GREEN-01, 02, 03, 05, 06, 08, 09, 10, 11, 12), 2/12 Pending (GREEN-04, GREEN-07) — **up from round 2's 8/12**, driven by the search_path fix and the CR-01/CR-02 closure, neither of which changes GREEN-04's or GREEN-07's own Pending status because a distinct, previously-masked cause now determines each.

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.github/workflows/ci.yml:247` (verify-test, current lane) | `ALTER DATABASE threadline_phoenix_test SET search_path ...` | ✓ VERIFIED | Confirmed present; 3 total `ALTER DATABASE` statements in the file, all naming `threadline_phoenix_test` |
| `test/threadline/ci_topology_contract_test.exs` | needs:-roster drift guard + ruleset-singleton guard | ✓ VERIFIED | 14 tests, 0 failures, independently re-run; mutation-tested per 198-REVIEW.md |
| `test/threadline/storage_schema_call_site_contract_test.exs` | CR-01/CR-02 fixed, in_scope_count 270, offense_count 0 | ✓ VERIFIED (via 198-REVIEW.md's independent hand-trace; not separately re-executed by this verifier beyond confirming the file compiles and its sibling suite passes) | 198-REVIEW.md: 36 tests, 0 failures across both touched files |
| `.github/rulesets/main.json` | Single `required_status_checks` context `"CI required"` | ✓ VERIFIED | Read directly; matches `ci-required`'s `name:` in `ci.yml` |
| `CONTRIBUTING.md` — CI Coverage table | Project list matches actual `--project` flags | ✓ VERIFIED | `desktop-chromium`/`mobile-chromium` rows present, bare `chromium` explicitly documented as deleted-not-moved |
| `.github/workflows/ui-critic.yml` | Deleted (not stubbed) | ✓ VERIFIED | Absent from `.github/workflows/` listing |
| `.github/workflows/hex-publish.yml` | Deleted (not stubbed) | ✓ VERIFIED | Absent; `hex.publish` appears only in `release.yml` |
| `.planning/ARCHIVE-REGISTER.md` + `archive/*` tags | 2 rows, 2 tags, restore commands | ✓ VERIFIED | Both tags resolve (`git tag -l "archive/*"`); register non-empty, states "Rows: 2" explicitly rather than omitting an empty-case sentence |
| `198-CI-MEASUREMENT.md` Round 3 section | Push, measured run, per-job table, prediction scorecard, root-cause citations | ✓ VERIFIED | Read in full; run ID `33204829086`, head SHA `80bf701e`, 14 checks with 9 green/3 red/aggregate red, all root-caused with citations to specific defects, none left as bare "still red" |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `ci.yml`'s `ci-required` job `needs:` | `.github/rulesets/main.json` | D-42 standing interlock, enforced by `ci_topology_contract_test.exs`'s new roster-drift test | ✓ WIRED | Test independently re-run, passes; 198-REVIEW.md mutation-tested it against a dropped `needs:` entry and it caught the drift |
| `ci.yml`'s `current`-lane db-prep step | `mix verify.example`'s `WalkthroughHappyPathTest` | The now-present `ALTER DATABASE` statement | ✓ WIRED (defect closed) | 0 `undefined_table` occurrences in the round-3 measured job log, independently corroborated by this report's own re-reading of `198-CI-MEASUREMENT.md`'s verbatim failure output, which shows only demo-seed content assertions, never a `42P01` error, among the 9 failures |
| `ci-required`'s `re-actors/alls-green` step | The 12-member `needs:` list | `if: always()`, `jobs: ${{ toJSON(needs) }}` | ✓ WIRED | Round-3 run's own step output enumerates all 12 members by name with explicit `[required to succeed]` tags; 0 `skipped`/`cancelled` — confirms the D-09 skipped-scores-as-passing hazard is not silently masking anything here |

### Requirements Coverage

| Req | REQUIREMENTS.md status (as of this verification) | This verifier's independent finding | Agreement? |
|---|---|---|---|
| GREEN-01 | `[x]` Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-02 | `[x]` Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-03 | `[x]` Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-04 | `[ ]` Pending, inline note cites run `33204829086`, distinguishes the closed original cause from the new demo-seed cause | ✗ BLOCKED — independently confirmed via the same run; REQUIREMENTS.md's note is accurate and does not overclaim | Yes — correctly recorded, not over-claimed, not under-claimed (correctly credits the closed sub-cause) |
| GREEN-05 | `[x]` Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-06 | `[x]` Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-07 | `[ ]` Pending, inline note cites run `33204829086` and the 3-of-12-red breakdown, explicitly states closure was NOT via narrowing `needs:` | ✗ BLOCKED — independently confirmed | Yes — correctly recorded |
| GREEN-08 | `[x]` Complete | ✓ SATISFIED — independently re-confirmed against `.github/rulesets/main.json` and the new D-42 interlock tests | Yes |
| GREEN-09 | `[x]` Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-10 | `[x]` Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-11 | `[x]` Complete | ✓ SATISFIED, unchanged | Yes |
| GREEN-12 | `[x]` Complete | ✓ SATISFIED, unchanged | Yes |

**No over-claim or under-claim found in REQUIREMENTS.md.** GREEN-04's inline note is unusually precise — it distinguishes a genuinely-closed sub-cause from a genuinely-open one in the same sentence, and cites the exact measured run for both claims. This is the traceability discipline this phase exists to enforce, working correctly on itself for a second consecutive round.

**Plan -> requirement traceability:** all 12 GREEN-01..12 IDs are claimed by at least one of plans 198-01 through 198-12 (verified directly from each plan's frontmatter `requirements:` field, not from a shallow grep). Plans 198-13 through 198-22 are gap-closure rounds; none declares a new requirement ID, which is expected and correct — they close gaps against requirements already claimed by 198-01..12. No orphaned requirement.

### Anti-Patterns Found

None found in the round-3 diff. `198-REVIEW.md` (independently read, not merely trusted) reports 0 Critical / 0 Warning / 0 Info across the 4 files it scoped to (`ci.yml`, `storage_schema_call_site_contract_test.exs`, `ci_topology_contract_test.exs`, `CONTRIBUTING.md`), and this verifier found no debt markers (`TBD`/`FIXME`/`XXX`) in any of those files during independent reading.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| `ci_topology_contract_test.exs`'s new contracts actually run and pass | `mix test test/threadline/ci_topology_contract_test.exs` | `14 tests, 0 failures` | ✓ PASS |
| `ui_form_policy_contract_test.exs` (GREEN-05) actually runs and passes | `mix test test/threadline/operator_surface/ui_form_policy_contract_test.exs` | `1 test, 0 failures` | ✓ PASS |
| Exactly 3 `ALTER DATABASE` statements exist, all scoped to `threadline_phoenix_test` | `grep -n "ALTER DATABASE" .github/workflows/ci.yml` | 3 hits, all naming `threadline_phoenix_test` | ✓ PASS |
| `ui-critic.yml` absent, no `ANTHROPIC` refs anywhere in `.github/` | `ls .github/workflows/; grep -rl ANTHROPIC .github/` | absent; empty grep | ✓ PASS |
| Exactly one workflow runs `hex.publish` | `grep -rl "hex.publish" .github/workflows/` | `release.yml` only | ✓ PASS |
| `git worktree list` shows exactly one entry | `git worktree list` | 1 entry (`/Users/jon/projects/threadline [main]`) | ✓ PASS |
| Local `git status` is clean modulo the pre-existing, explicitly-deferred `milestone.lock` | `git status --porcelain` | `?? .planning/milestone.lock` only | ✓ PASS (consistent with D-47/deferred item, Phase 199/DECOUPLE-05) |

### Probe Execution

No `scripts/*/tests/probe-*.sh` convention or PLAN-declared probes exist for this phase — CI itself is the probe, and its measured run is treated as the authoritative evidence throughout this report (never local `mix test`, never SUMMARY narration). SKIPPED (no conventional probe scripts; CI run is the equivalent evidence class and is fully reproduced in this report).

### Human Verification Required

None. Every truth in this phase is either mechanically checkable (file contents, test runs, `gh` API state) or already settled by an explicit, recorded maintainer decision (D-39/D-40/D-41, 198-20). No item requires a human to newly judge visual, real-time, or UX-quality behavior — this is a bringup/gating phase with no product or UI change in scope.

### Gaps Summary

Two of twelve GREEN requirements remain genuinely unmet: **GREEN-04** and **GREEN-07**. Both are unmet for measured, cited, non-vacuous reasons rather than unexamined defects:

1. **GREEN-04** — the requirement's originally-named cause (a missing `ALTER DATABASE ... SET search_path` statement) is now closed and independently confirmed on a real CI run. But `Run test suite (current)` remains red because of a distinct, previously-masked cause: 9 demo-seed content mismatches, a defect class already known and deferred since Phase 177. This is explicitly named in `198-CONTEXT.md` D-41 as a predicted outcome of this round, and the maintainer explicitly chose (checkpoint 198-20, decision C1) to defer its fix to a dedicated successor round rather than have this round attempt it.
2. **GREEN-07** — a direct consequence of GREEN-04 plus two other, independently-known-and-deferred red lanes: `Tier A capture lane` (D-39, maintainer decision A1 — the only available remedy, Tier-A scorecard regeneration, is forbidden this milestone) and `Example app browser E2E` (D-40, maintainer decision B1 — 28 masked failures deferred to a successor round). No lane was removed from `ci-required`'s `needs:` to manufacture a green aggregate; the maintainer explicitly declined that path, so `CI required`'s guarantee is unchanged and GREEN-07 can only close by fixing the underlying causes.

Neither gap traces to unreviewed code, an unproven test, or a claim this report could not independently verify — the CI-MEASUREMENT.md ledger, the CONTEXT.md decision record, and the REQUIREMENTS.md inline notes all agree with each other and with the raw `gh` API output this verifier independently re-derived. **`passed` is not defensible for this phase as a whole**, because two of the phase's own twelve requirements are, on the phase's own admissible evidence (real measured CI, not local `mix test`), not met — and the phase's headline success criterion is exactly "CI concludes green," which is the literal thing still false. `human_needed` is not appropriate either, because nothing here awaits a human judgment call: the two open items already went through their maintainer decision point (198-20) and the outstanding work is well-scoped engineering (fix demo-seed content; fix 28 Playwright failures) with a citation, not an ambiguity. **`gaps_found` is the honest status**, with both gaps clearly scoped to dedicated successor rounds already named in `198-CONTEXT.md` D-40/D-41, not to further work inside Phase 198 itself. Whether those successor rounds happen as Phase 198 round 4, as their own future phase, or are formally accepted as a standing debt register entry is a decision for the human maintainer at this checkpoint — this report does not make that call.

---

_Verified: 2026-08-28_
_Verifier: Claude (gsd-verifier)_
