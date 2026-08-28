---
phase: 198-green-bringup
verified: 2026-08-28T20:30:00Z
status: gaps_found
supersedes: "Prior 198-VERIFICATION.md (round 2, verified 2026-08-28, gaps_found, score 3/6 SC / 8/12 requirements). Round-2 findings are reconciled, not discarded — see 'Reconciliation with Round 2' below. This report is authoritative."
ci_measured:
  round_1: "PR #29, run 33183920952, FAILURE (6/13 checks red)"
  round_2: "PR #29, run 33197493051, FAILURE (11/14 checks reported, 3 red + aggregate red) — 13m29s wall clock"
  round_3: "PR #30 (draft, DO NOT MERGE), run 33204829086, FAILURE (14 checks reported, 3 red + aggregate red) — 13m29s wall clock, byte-identical to round 2"
score: 3/6 roadmap success criteria verified (10/12 requirements Complete, 2 Pending) — UP from round 2's 8/12 requirements; the same 2 requirements (GREEN-04, GREEN-07) remain Pending, for measured, cited, non-vacuous reasons
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found (round 2)
  previous_score: "3/6 roadmap success criteria (8/12 requirements)"
  gaps_closed:
    - "The originally-named GREEN-04 cause (missing ALTER DATABASE ... SET search_path at ci.yml:235-240) — fixed by 198-19, confirmed on measured CI run 33204829086: grep -c \"undefined_table\" against the job's full log returns 0, and none of the job's 9 test failures cite (undefined_table). Independently re-confirmed by this verifier: exactly 3 ALTER DATABASE statements exist in ci.yml, all naming threadline_phoenix_test, none touching threadline_test."
    - "CR-01 (call-site sweep blind to fully-qualified Threadline.Test.Repo.* receivers) — fixed by 198-19, independently re-verified by this verifier's own regex trace and by 198-REVIEW.md's independent hand-trace; locked in by new behaviour tests"
    - "CR-02 (Repo.insert_all/3 absent from @ecto_functions) — fixed by 198-19, independently re-verified; in_scope_count 208 -> 270, offense_count 0"
    - "D-42 standing interlock — a needs:-roster drift guard and a ruleset-singleton guard added to ci_topology_contract_test.exs (198-21); this verifier ran both tests directly (14 tests, 0 failures) rather than trusting the summary's count"
  gaps_remaining:
    - "GREEN-04 — still not met, but for a DIFFERENT, newly-measured cause than round 2. mix verify.example inside the current lane's Run test suite job now fails on 9 pre-existing demo-seed content mismatches (Ecto.NoResultsError / assertion-mismatch / one ExUnit.TimeoutError against ThreadlinePhoenix.DemoContractTest, WalkthroughHappyPathTest, WalkthroughEvidenceTest) — the same class already acknowledged and deferred across Phases 177/179/180/182 (deferred-items.md Plan 198-12 entry), and explicitly predicted in advance by 198-CONTEXT.md D-41. This is a genuine, evidence-backed deferral: the maintainer explicitly chose (C1, 198-20) to leave mix verify.example wired into verify-test's current lane and fix the demo-seed failures in a dedicated successor round, not to narrow the requirement's definition."
    - "GREEN-07 — still not met. CI required concluded failure on the round-3 measured run (3 of 12 needs: dependencies red: Run test suite (current) [new cause, see above], Tier A capture lane [unchanged, D-39], Example app browser E2E [unchanged, D-40]). No lane was removed from needs: — the maintainer explicitly declined to narrow the merge gate (D-39/D-40/D-41), so GREEN-07 can only close by fixing the underlying red lanes, never by definitional scope reduction."
  regressions: []
gaps:
  - truth: "GREEN-04 — mix test passes with no deterministically-failing tests, each former failure fixed on its merits"
    status: failed
    reason: "Local mix test admits no evidence for this requirement (D-01: green means fresh-clone-local AND CI, both reachable via mix ci.all). The measured CI run (33204829086) shows Run test suite (current) still fails, now on mix verify.example's 9 demo-seed content mismatches rather than the originally-named search_path cause, which is independently confirmed closed (0 undefined_table occurrences in the job's log)."
    artifacts:
      - path: "examples/threadline_phoenix/test/threadline_phoenix_web/demo_contract_test.exs, walkthrough_happy_path_test.exs, walkthrough_evidence_test.exs"
        issue: "9 pre-existing failures against mix demo.seed-generated content — a deferred class since Phase 177/179/180/182, not newly introduced by this phase"
    missing:
      - "A dedicated successor round (per D-41, maintainer decision C1) to fix the 8-9 demo-seed content mismatches, then re-measure on a real CI run before marking GREEN-04 Complete"
  - truth: "GREEN-07 — origin/main carries every local commit and its latest CI run concludes success in <=20 minutes"
    status: failed
    reason: "Time clause met (13m29s, well under 20min, byte-identical across rounds 2 and 3). Success clause not met: CI required concluded failure on run 33204829086 because 3 of 12 needs: dependencies were red (Run test suite (current) — new cause; Tier A capture lane — D-39, forbidden remedy this milestone; Example app browser E2E — D-40, 28-failure discovery deferred to a successor round). PR #30 mergeStateStatus: BLOCKED. origin/main remains 88 commits behind local HEAD."
    artifacts:
      - path: "GitHub Actions run 33204829086 (PR #30, ci/198-round3)"
        issue: "conclusion: failure; CI required aggregate: failure; 9/12 needs: green, 3/12 red, 0 skipped/cancelled"
    missing:
      - "Fix the GREEN-04 gap above (closes one of the three red needs:)"
      - "A dedicated successor round to fix the 28 masked Playwright failures (D-40, maintainer decision B1)"
      - "The Tier A capture lane's scroll_cost drift remains structurally unfixable within this milestone's regeneration prohibition (D-39, maintainer decision A1) — GREEN-07 cannot close through this lane until that milestone-level constraint lifts"
deferred: []
---

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
