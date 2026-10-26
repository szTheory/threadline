---
phase: 246-debt-closeout-and-critic-retirement
verified: 2026-10-26T01:34:33Z
status: gaps_found
score: 9/11 must-haves verified
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
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-DEBT-REGISTER.md"
  - ".planning/phases/246-debt-closeout-and-critic-retirement/246-LANDING.md"
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
  - "test/threadline/ci_topology_contract_test.exs"
  - "test/threadline/operator_surface/stress_ledger_test.exs"
  - "test/threadline/ui_critic_retirement_doc_contract_test.exs"
covered_digest: "v3:sha256:38d8b21ef9be8cc4647586800a84d4f9acb7acd7e60012a2fd16f8a7d847dcb0"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Docs stay consistent after the removal (goal clause 'docs consistent for the CI phase to measure'; SC4 'honest-default test docs remain true')"
    status: failed
    reason: >-
      C3a (9ea29dc4) wrote a description of Browser-full coverage that does not match the code.
      CONTRIBUTING.md:311-312 says route-capture is "a render smoke over every inventoried route
      at three viewports"; browser-full.yml:6 says "every inventoried route". Without
      THREADLINE_E2E_EVIDENCE (which the new contract forbids in browser-full.yml), the only
      test that runs is "renders every curated operator route at 1280"
      (operator-page-capture.spec.ts:425). It covers 6 hard-coded ROUTES at BREAKPOINTS = [1280]
      (:35, :88). The per-inventory 1280/768/375 tests (:377-378) skip outside evidence mode.
      Phase 247 measures CI from this coverage table, so it would start from a false baseline.
      This is review finding WR-01, confirmed independently.
    artifacts:
      - path: "CONTRIBUTING.md"
        issue: ":311-312 claims inventory-wide, three-viewport coverage; the code runs 6 curated routes at 1280"
      - path: ".github/workflows/browser-full.yml"
        issue: ":6 claims 'every inventoried route'"
      - path: "examples/threadline_phoenix/e2e/playwright.config.ts"
        issue: "route-capture comment describes the evidence and non-evidence modes the wrong way round (review WR-01)"
    missing:
      - "Reword the three descriptions to match the code: 6 curated routes at 1280, plus inventory-wide 1280/768/375 only in evidence mode, which Browser-full never sets"
      - "Optionally pin the wording in browser_journey_evidence_contract_test.exs or the ui_critic_retirement doc contract"
  - truth: "D-24 phase gate: the standalone browser run has exactly the 8 known :108/:115/:136/:145 screenshot failures, and any deviation is honestly routed"
    status: partial
    reason: >-
      The measured standalone result is 419/10/58. The 2 extra failures are
      operator-screenshot-regression.spec.ts:101 (Home), desktop and mobile. They are
      pre-existing, not a phase regression. The slices touch only the stress lab (stress_live.ex,
      sections.ex, stress_fixtures.ex) and never Home (/audit) render code. The recorded heights
      show :101 already fails on origin/main 23178fb0 (1274/2048 px against the 1281/2013
      baseline). However, the "routed to SEED-008" claim in deferred-items.md and 246-LANDING.md
      is not reflected in SEED-008 itself. SEED-008 lists only :108/:115/:136/:145 and still
      says "a healthy browser lane has exactly these 8 failures" and "the 8-failure browser
      baseline". 246-DEBT-REGISTER.md has no :101 row either. The plan criterion is therefore
      neither met nor formally waived, and the seed that is supposed to own the item gives the
      next phase the wrong regression threshold (8, when 10 is what was measured).
    artifacts:
      - path: ".planning/seeds/SEED-008-operator-ui-carry.md"
        issue: "Scope and Done-when name 8 failures; :101 x2 is absent"
      - path: ".planning/phases/246-debt-closeout-and-critic-retirement/246-DEBT-REGISTER.md"
        issue: "no row for the :101 Home screenshot drift, which deferred-items.md says is routed"
    missing:
      - "Add :101 (desktop and mobile Home full-page height drift, pre-existing on origin/main 23178fb0) to SEED-008 Scope and change 'exactly these 8' and '8-failure' to 10"
      - "Add a routed register row (-> SEED-008) for :101, or accept an override for the D-24 'exactly 8' criterion citing the origin/main evidence"
---

# Phase 246: Debt closeout and critic retirement Verification Report

**Phase Goal:** The carried-debt register is fully dispositioned, and the parked UI-critic loop is gone from main yet restorable, leaving the suite, CI topology and docs consistent for the CI phase to measure.
**Verified:** 2026-10-26T01:34:33Z
**Status:** gaps_found
**Re-verification:** No (initial verification)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1 / DEBT-01: every carried-debt row has a disposition; obsolete rows (incl. WINDOWS) are waived with a reason; real items are routed to a named milestone or seed | VERIFIED | `verify-phase.sh --close` exit 0 at HEAD 2d86fe9c (checks 1-7 ok). Register frontmatter shows 64 closed, 44 waived, 23 routed, 131 total. WINDOWS: `open_count: 0`, JSON 27 fixed / 40 waived / 0 open (counted independently). The routes are in QUALITY-ROADMAP (v1.48 :38-41, v1.49 :52-55, v1.51 :71-72), and the Disposition (246) pointer is at :100 |
| 2 | D-15 close check is mechanical, read-only and self-tested | VERIFIED | `--close` exit 0 and `--self-test` exit 0 (24 negative and positive controls). `git status --porcelain` was the same before and after (only the pre-existing STATE.md edit) |
| 3 | SC2: the cheap 215/223 self-test findings are fixed and their tests pass | VERIFIED | Commits f29a40bf, 1df4c803, f9764172, 9ff63692, 6e439225 and 46efd9d4 (216 IN-01). A targeted run of deps_health_doc_contract, deps_audit_gate, repo_hygiene_contract and changelog_contract, with others, gave 126 + 48 tests, 0 failures |
| 4 | SC3: critic code, tests, fixtures, capture projects and doc references are absent from main's tree (no live references) | VERIFIED | critic_trust/, critic.* tasks, e2e/critic/, mechanical_checker* and the scorecards/golden/refute/critic-scores fixtures are all gone. `bin/browser-full-projects --list config` prints `desktop-chromium mobile-chromium route-capture`. package.json `test:unit` runs only operator-surface-paths.test.ts. manifest.sha256 has 1 line. stress_fixtures.ex is 753 lines. The remaining `critic`/`verify-capture` hits are the allowlisted .gitignore lines, clean-checkout probes, the reworded guard, removed-job contracts, the Retired section and historical CHANGELOG-GENERATED entries. The D-09 grep passes |
| 5 | Removal slices are separable: C1-C6 touch no `.planning/` path and carry Removal-Slice trailers | VERIFIED | 4b2c3f89 C1, cbb804a6 C2, 9ea29dc4 C3a, 1258c014 C3b, 35243789 C4, 61f58954 C5 and 8eb54275 C6 each have 0 `.planning/` paths and the trailer. C6 is a 3-line test-only wait in operator-accessibility.spec.ts:1296-1298 for the focus race that C4 exposed at :1281. The fix is legitimate and touches no product code |
| 6 | Restorable (DEBT-02 / D-11 / D-13): judged against the hand-off, not the tag | VERIFIED | The tag `archive/ui-critic-loop` is deliberately absent (`git tag -l` is empty). Per D-13 the maintainer creates and pushes it after the removal squash lands. 246-LANDING.md gives the target (`<removal-squash-sha>^` on origin/main, never a milestone commit), a D-31 message, `git revert` as the primary restore, and a checkout fallback. I checked it independently: the 25 fallback pathspecs cover all 479 files the seven slices delete, with 0 uncovered. It also gives the hand-restore mix.exs list, the ARCHIVE-REGISTER row, the D-14 evidence commands and `! git push origin refs/tags/archive/ui-critic-loop`. SC3's "a tag marks the last commit" therefore waits on the maintainer push decision. It is not a phase gap |
| 7 | SC4: `mix ci.all` green after removal; partition contract lists no deleted files; no orphaned capture project | VERIFIED | The recorded CI=true ci.all exit 0 (lib 3328/0, example 132/0, Dialyzer 0, CI browser 415+3 flaky/0) is consistent with the tree. I did not re-run the full suite. The close check confirms partition rows name existing files, and the only added row is ui_critic_retirement_doc_contract_test.exs. The targeted ci_topology_contract, source_size, rendered_output and ui_critic_retirement contracts are green. Required CI on GitHub has not run, because nothing is pushed (a landing/push decision) |
| 8 | SEED-005 closed / SEED-008 planted with reopen_when (D-21/D-22) | VERIFIED | SEED-005 has `status: closed`, closed_on, closed_during and closed_reason citing page.ex:295 / script.ex:58,101, and its body Status line reads Closed. SEED-008 has `reopen_when` |
| 9 | CI topology consistent: verify-capture removed from roster and contracts, recorded as a coverage cut | VERIFIED | ci.yml:850 has the `# Removed: verify-capture` comment. `@removed_job_ids` includes verify-capture (ci_topology_contract_test.exs:1269) with a re-add negative control (:1375-1381). CONTRIBUTING:594 has the removed-proof bullet |
| 10 | Docs consistent for the CI phase to measure (goal clause; SC4 honest docs) | FAILED | CONTRIBUTING.md:311-312 and browser-full.yml:6, both written by C3a 9ea29dc4, describe Browser-full as an inventory-wide, three-viewport smoke. The code runs 6 curated routes at 1280 (operator-page-capture.spec.ts:35, :88, :425); the 1280/768/375 tests skip outside evidence mode (:377-378), and Browser-full is contract-forbidden from setting evidence mode |
| 11 | D-24 browser gate: exactly the 8 known failures, with deviations honestly routed | PARTIAL (gap) | The 10 failures are the 8 known plus :101 x2. :101 is pre-existing: the slices never touch Home, and it already failed on origin/main 23178fb0. But SEED-008 still says "exactly these 8", and neither SEED-008 nor the register carries :101, so the route that deferred-items.md claims does not exist at its destination |

**Score:** 9/11 truths verified (0 present, behavior-unverified)

### Decision on the 2 extra browser failures

They are **not a phase regression**:
- All three product files the slices modify are stress-lab files (`stress_live.ex`, `stress_live/sections.ex`, `stress_fixtures.ex`). The `:101` test renders `/audit` (Home).
- The recorded geometry shows `:101` failing on origin/main 23178fb0 before any slice.

The plan's "exactly 8" criterion is **not met as written and not formally waived**:
- There is no override.
- The owning seed contradicts the measured baseline.

That makes it a gap. The gap is cheap and confined to docs and routing: update SEED-008 and add a register row, or record an override. It is not a code defect.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `tools/verify-phase.sh` | D-15 close check + self-test | VERIFIED | exit 0 / exit 0 |
| `246-DEBT-REGISTER.md` | one row per item, counts match | VERIFIED | 131 rows; check 1 ok |
| `.planning/WINDOWS.md` | open_count 0 | VERIFIED | 0 open in JSON |
| `SEED-008-operator-ui-carry.md` | owns UI carry incl. screenshot baselines | PARTIAL | lacks :101; says 8 |
| `246-LANDING.md` | D-11/D-12/D-13/D-14 hand-off | VERIFIED | restore list complete (479/479) |
| `ui_critic_retirement_doc_contract_test.exs` | Retired pointer guard | VERIFIED | passes; replaces critic_iteration_runbook contract |
| `CONTRIBUTING.md` | Retired section + honest CI tables | PARTIAL | Retired section ok; :311 Browser-full claim false |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `bin/browser-full-projects` | playwright.config projects | `--list config` | WIRED | 3 projects; Browser-full = route-capture |
| register routed rows | QUALITY-ROADMAP candidate lists | D-23 append | WIRED | v1.48/v1.49/v1.51 entries present |
| deferred-items `:101` | SEED-008 | "routed to SEED-008" | NOT_WIRED | SEED-008 does not mention :101 |
| LANDING fallback restore | deleted file set | pathspec list | WIRED | 0 uncovered of 479 |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Close check | `bash tools/verify-phase.sh --close` | `verify-phase: all checks passed`, exit 0 | PASS |
| Self-test | `bash tools/verify-phase.sh --self-test` | exit 0 | PASS |
| Targeted contracts | `mix test` on ui_critic_retirement, deps_health, deps_audit_gate, source_size, rendered_output | 126 tests, 0 failures | PASS |
| Targeted CI contracts | `mix test` on ci_topology, repo_hygiene_contract, changelog_contract | 48 tests, 0 failures | PASS |
| Repo hygiene | `bin/verify-repo-hygiene` | exit 0 | PASS |
| Browser lane | not re-run (per instruction) | recorded 419/10/58 | SKIP |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| `.planning/phases/246-.../tools/verify-phase.sh` | `--close` / `--self-test` | exit 0 / exit 0 | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DEBT-01 | 01, 05, 06, 07 | every carried-debt row dispositioned; cheap 215/223 fixed | SATISFIED | truths 1-3, 8 |
| DEBT-02 | 01, 02, 03, 04, 07 | critic loop removed, tagged for restore, suite/CI/docs consistent | PARTIAL | removal and restore hand-off verified (truths 4-7, 9); docs consistency has gap (truth 10); tag creation deferred to maintainer per D-13 |

No orphaned requirement IDs. REQUIREMENTS.md maps only DEBT-01/02 to Phase 246, and both are claimed. Both still read Pending, as expected before phase completion.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| CONTRIBUTING.md / browser-full.yml | 311 / 6 | doc claim contradicts code | Blocker (goal clause) | false CI coverage baseline for Phase 247 |
| test/threadline/operator_surface/stress_ledger_test.exs | - | ratchet scalar test deleted while `ratchet_rule` kept (review WR-04, confirmed: no test now checks target_score >= current_score or the ratchet watermark) | Warning | a kept rule now has no enforcement |
| ci_topology_contract_test.exs | 1262-1381 | "still caught by" claims for removed jobs not pinned (review WR-03) | Warning | dominance unguarded |
| operator-surface-paths.ts | 80-81 | output-root guard narrowed to the ledger file (review WR-05) | Warning | guard disagrees with the manifest writer |
| CONTRIBUTING.md | 285-289 | restore pointer names a tag that does not exist yet (review WR-02) | Info | expected under D-13 until landing; the D-14 landing evidence commands cover it |

No unreferenced TBD/FIXME/XXX markers were found in the phase's implementation files.

### Human Verification Required

None. Every judgment call was resolved by the verifier. The only outstanding external step is the tag creation and push after landing (D-13), which is a maintainer push decision and not a verification item.

### Gaps Summary

The core of the phase is achieved:
- The register and WINDOWS are fully dispositioned and mechanically checked.
- The critic loop is removed in seven separable slices.
- The restore hand-off is complete and covers every deleted path.
- The suite gate was green.

Two gaps remain, both in docs and routing honesty, and both cheap:
1. **Browser-full coverage is misdescribed** in CONTRIBUTING.md:311 and browser-full.yml:6. Phase 246 introduced this, and it is exactly the docs that Phase 247 will measure CI against.
2. **The `:101` screenshot drift is called "routed to SEED-008" but SEED-008 doesn't carry it.** SEED-008 still states an 8-failure healthy baseline when 10 was measured, and the register has no row for it. The failures themselves are pre-existing, not a regression.

Review warnings WR-03/04/05 are recorded as warnings. They do not block the goal.

---

_Verified: 2026-10-26T01:34:33Z_
_Verifier: Claude (gsd-verifier)_
