---
phase: 204-structure
plan: 16
subsystem: testing
tags: [size-gate, banners, critic-trust, structure, gap-closure]

requires:
  - phase: 204-structure
    provides: "source_size_contract_test (204-12 banner gate, 204-15 exceptions at rest)"
provides:
  - "Widened two-branch @banner regex with a planted titled-banner self-test"
  - "Keyword-form (do:) clause length measured to end_of_expression (WR-01)"
  - "Threadline.CriticTrust.RepositoryBoundary: critic.measure's repository-only path, decode and atomic-write boundary as a real module"
  - "Zero separator banners in lib/ under a gate that catches the titled box-rule form"
affects: [204-verification, STRUCT-04, STRUCT-03]

actuals:
  tokens: 9300
  tasks: 3
  commits: 5
plan_head_before: 5df400097ab96a82d7acd18bf58e18121c7ce9f0

tech-stack:
  added: []
  patterns:
    - "Banner = comment that opens with a rule run (box run of 2+) or ends with a rule run of 3+"
    - "Module extracted out of a Mix task keeps the task's Process key and error prefix as literals"

key-files:
  created:
    - lib/threadline/critic_trust/repository_boundary.ex
  modified:
    - test/threadline/source_size_contract_test.exs
    - lib/mix/tasks/critic.measure.ex
    - lib/threadline/critic_trust/krippendorff_alpha.ex
    - test/threadline/public_surface_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
    - .planning/REQUIREMENTS.md
    - .planning/phases/204-structure/204-12-SUMMARY.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "Four of the five banners were deleted as cohesive clause groups; the critic.measure repository-only boundary (~258 lines) became Threadline.CriticTrust.RepositoryBoundary (D-11)"
  - "RepositoryBoundary reads the atomic-write hook from {Mix.Tasks.Critic.Measure, :atomic_write_hook} written out literally, not __MODULE__, so the existing interrupted-write test keeps working"
  - "Keyword-form clauses are measured by end_of_expression; the subtree-max fallback is best effort, because plain heredoc strings carry no metadata of their own"

patterns-established:
  - "Titled separator banners (rule, title, rule) are caught by the size gate; prose containing rule characters (--tl- names, table rules, arrows) is not"

requirements-completed: [STRUCT-04, STRUCT-03]

coverage:
  - id: D1
    description: "Widened banner gate: RED on exactly the 5 real banners, GREEN with @banner_exceptions %{} after their removal; planted 4-positive/4-negative self-test"
    requirement: STRUCT-04
    verification:
      - kind: unit
        ref: "test/threadline/source_size_contract_test.exs#a titled banner is counted whether the rule leads or trails, and prose with rule characters is not"
        status: pass
      - kind: unit
        ref: "test/threadline/source_size_contract_test.exs#the real tree matches the banner register exactly"
        status: pass
    human_judgment: false
  - id: D2
    description: "critic.measure repository boundary extracted to Threadline.CriticTrust.RepositoryBoundary with unchanged behavior and error text"
    requirement: STRUCT-04
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface/critic_trust_test.exs"
        status: pass
      - kind: unit
        ref: "test/threadline/public_surface_contract_test.exs; test/threadline/release_artifact_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Keyword-form do: clauses measured to the end of their expression (WR-01); real tree still passes with @function_exceptions %{}"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "test/threadline/source_size_contract_test.exs#a keyword do: clause is measured to the end of its expression, not counted as one line"
        status: pass
      - kind: unit
        ref: "test/threadline/source_size_contract_test.exs#a keyword clause followed by another def is measured exactly"
        status: pass
    human_judgment: false
  - id: D4
    description: "Phase-end proof: ci.all, credo --strict, browser lane at 326/8/16"
    verification:
      - kind: other
        ref: "MIX_ENV=test mix ci.all (1781 tests, 0 failures)"
        status: pass
      - kind: e2e
        ref: "mix verify.example_browser (326 passed / 8 failed / 16 skipped, the known 8)"
        status: pass
    human_judgment: false

duration: 18min
completed: 2026-09-24
status: complete
---

# Phase 204 Plan 16: STRUCT-04 banner gate gap closure Summary

**The size gate's banner regex now catches titled box-rule banners. It went RED on exactly the five that had escaped it. Those five are gone: four were deleted as cohesive groups, and critic.measure's repository-only boundary became `Threadline.CriticTrust.RepositoryBoundary`. Keyword-form `do:` clauses are now measured to the end of their expression, not counted as one line.**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-09-24T04:26:58Z
- **Completed:** 2026-09-24T04:45Z
- **Tasks:** 3
- **Files modified:** 11 (6 code/test, 5 planning including this SUMMARY)

## Accomplishments

- `@banner` is now `~r/^\s*#\s*(?:-{3,}|={3,}|─{2,}|\*{3,})|(?:-{3,}|={3,}|─{3,}|\*{3,})\s*$/u`. A planted self-test counts 4 titled banners and ignores 4 prose comments: a `--tl-` custom property, a markdown table rule, an arrow, and plain prose.
- Zero banners remain in lib/. The gate is GREEN with `@banner_exceptions %{}`, and the "exceptions at rest" test is untouched.
- `Threadline.CriticTrust.RepositoryBoundary` (`@moduledoc false`, excluded from the Hex package) holds the path checks, the validated decode and the atomic ledger write. The functions moved verbatim, and the `critic.measure:` error text is byte-identical.
- `collect_clause/2` measures keyword clauses via `end_of_expression`, with a fallback to the largest line in the clause subtree. After the fix, the longest clause in the real tree is **114 lines** (`evidence_live.ex` `render/1`), and the longest keyword-form clause is 7 lines (`icon.ex` `paths/1`). There are still no function exceptions.
- STRUCT-04 was reopened, then re-closed after a green ci.all. 204-12-SUMMARY has an append-only erratum.

## RED evidence

**Task 1, widened regex before any banner was removed.** `mix test test/threadline/source_size_contract_test.exs` failed on exactly the two expected offenders. The failure line:

```
1) test separator banners the real tree matches the banner register exactly (Threadline.SourceSizeContractTest)
   right: {:error,
           "separator banners:\n  lib/mix/tasks/critic.measure.ex has 4 separator banner comment(s) and no banner exception. Replace each banner with a real module or function boundary.\n  lib/threadline/critic_trust/krippendorff_alpha.ex has 1 separator banner comment(s) and no banner exception. Replace each banner with a real module or function boundary."}
16 tests, 1 failure
```

This re-measures the planner's figure from f045ce28: the widened regex matches exactly 5 real lib/ comments. The new self-test passed in the same run, so it matched its 4 planted positives and none of its 4 negatives.

**Task 2, keyword-clause tests before the counter fix:**

```
1) test function length a keyword do: clause is measured to the end of its expression, not counted as one line
   Assertion with >= failed
   code:  assert length >= 121
   left:  1
2) test function length a keyword clause followed by another def is measured exactly
   left:  %{{"lib/kw2.ex", :f, 1} => 8, {"lib/kw2.ex", :g, 0} => 1}
   right: %{{"lib/kw2.ex", :f, 1} => 1, {"lib/kw2.ex", :g, 0} => 1}
18 tests, 2 failures
```

Both tests failed on their behavioral assertions, and the old counter reported 1 in each. After the fix, all 18 tests pass.

## Task Commits

1. **Task 1, Step 0: reopen STRUCT-04.** `00dfb6aa` (docs)
2. **Task 1: make the critic.measure repository boundary a real module.** `e8e66b27` (refactor). This commit covers critic.measure.ex (the extraction plus 3 banner deletions), repository_boundary.ex, and the two enumeration tests.
3. **Task 1: drop the private-helpers banner in krippendorff_alpha.** `8d53836f` (refactor)
4. **Task 1: widen the banner gate to titled box-rule banners.** `857dac3b` (test)
5. **Task 2: measure keyword-form clauses to the end of their expression.** `456f3500` (test)
6. **Task 3: close STRUCT-04 after the widened banner gate is green.** This is the close-out commit and holds this SUMMARY, REQUIREMENTS, the 204-12 erratum, ROADMAP and STATE.

The `commits: 5` figure in the frontmatter is `git rev-list --count 5df40009..HEAD`, measured before the close-out commit.

## Phase-end gate table (Task 3)

| Gate | Command | Exit | Summary line | Duration |
|------|---------|------|--------------|----------|
| ci.all | `DB_PORT=5433 ... MIX_ENV=test mix ci.all` | 0 | `1781 tests, 0 failures, 1 excluded` (plus `117 tests, 0 failures`; Dialyzer `done (passed successfully)`; its Playwright step `318 passed / 26 skipped`) | 375 s |
| credo | `mix credo --strict` | 0 | `3471 mods/funs, found no issues.` (316 files) | 1 s |
| browser | `mix verify.example_browser` | lane exit 0; composite gate 0 under bash (see Deviations) | `326 passed / 8 failed / 16 skipped` | 398 s |

The 8 browser failures are exactly the known screenshot cases, with nothing else failing:

- [desktop-chromium] operator-screenshot-regression.spec.ts:108, :115, :136, :145
- [mobile-chromium] operator-screenshot-regression.spec.ts:108, :115, :136, :145

The snapshot directory is clean. `test/fixtures/operator_surface/scorecards/` was restored after the run and never staged. No re-run was needed.

## Files Created/Modified

- `lib/threadline/critic_trust/repository_boundary.ex` (new). Holds project_root!/0, resolve_repository_root!/3, validate_root_separation!/2, require_directory!/3, read_json_object!/3, read_json_text!/3, read_text!/3, validate_score!/2, validate_golden!/3, atomic_replace!/2, restore_command/1 and task_error!/3, all public. canonicalize_root!, within?, atomic_write_hook and the valid_*/adjudication_* helpers stay private.
- `lib/mix/tasks/critic.measure.ex`. Now 202 lines, down from 466. It has no banners and calls `RepositoryBoundary.*`.
- `lib/threadline/critic_trust/krippendorff_alpha.ex`. The banner line and its blank line are removed, and the explanatory comment is kept.
- `test/threadline/source_size_contract_test.exs`. Adds the widened regex, the titled-banner self-test, the keyword-clause measure with the `last_meta_line/1` and `max_meta_line/2` helpers, two planted keyword tests, and the updated moduledoc bullets.
- `test/threadline/public_surface_contract_test.exs` and `test/threadline/release_artifact_contract_test.exs` register the new module.
- `.planning/REQUIREMENTS.md`: STRUCT-04 goes to In Progress, then back to Complete.
- `.planning/phases/204-structure/204-12-SUMMARY.md`: an appended erratum (numstat `8 0`).

## STATE.md / ROADMAP.md line changes

**ROADMAP.md** (one line, by hand):
- :865 before: `- [ ] 204-16-PLAN.md — **Tracer:** widened banner gate ...`
- :865 after: `- [x] 204-16-PLAN.md — **Tracer:** widened banner gate ...`
- Nothing else was changed. The progress-table row `| 204. Structure | v1.41 | 0/TBD | Not started | |` (:913) is stale from before this plan, and I left it alone as instructed.

**STATE.md** (compared against `/Users/jon/.claude/jobs/77cf1bdd/tmp/p204-16-STATE.before`, which already held the orchestrator's uncommitted begin-phase edits):
- :7 `status: executing` → `status: verifying` (advance-plan, `reason: last_plan`)
- :8 `stopped_at: Completed 204-15-PLAN.md` → `stopped_at: Completed 204-16-PLAN.md` (record-session)
- :9 `last_updated: "2026-09-24T04:26:19.676Z"` → `last_updated: "2026-09-24T04:45:41.347Z"`
- :12 `state_head: 5df40009…` → `state_head: 456f3500…`
- :17 `completed_plans: 145` → `completed_plans: 146` (the total stays 146; `percent: 86` and `completed_phases: 6` are unchanged, which is correct while 204 awaits re-verification)
- :34 `Status: Executing Phase 204` → `Status: Phase complete — ready for verification`
- :268 (new) `| Phase 204 P16 | 17 | 3 tasks | 11 files |` (record-metric)
- :843 `**Last session:** 2026-09-24T03:43:14.632Z` → `**Last session:** 2026-09-24T04:44:34.704Z`
- :844 `**Stopped at:** Completed 204-15-PLAN.md` → `**Stopped at:** Completed 204-16-PLAN.md`
- I hand-checked the progress block, and every value is right: 146/146 plans, and 6/7 phases, because Phase 204 has not been re-verified. Lines :32-33 (`Phase: 204 (Structure) — EXECUTING`, `Plan: 16 of 16`) were not touched by the handlers.

## Decisions Made

- The new module got a short prose comment (not a banner) under `@moduledoc false`. It explains why the error prefix and the Process hook key name the task module.
- I did not add `RepositoryBoundary` to `mix.exs`. The existing `^lib/threadline/critic_trust/` exclude pattern already covers it.

## Deviations from Plan

**1. [Rule 3 - Blocking/tooling] The browser composite gate reported R=1 in zsh even though every component passed**
- **Found during:** Task 3
- **Issue:** In this harness's zsh, `grep` is a shell function from the shell snapshot, not /usr/bin/grep. With it, `grep -qv` on empty input exits 0, so the plan's `! grep ... | grep -qv ...` clause fails even when there are no non-screenshot failures. The clause's `^ +[0-9]+\) \[` pattern also never matches Playwright's output, because every failure line starts with an ANSI color escape. That makes the clause vacuous even under a real grep.
- **Fix:** I re-evaluated the identical composite under `bash -c` on the same log, with no lane re-run, and got `bashR=0`. I then checked the failing set independently by stripping ANSI codes: 8 `N) [` lines, 0 outside operator-screenshot-regression.spec.ts. Each count grep (326 passed, 8 failed, 16 skipped) and the snapshot-clean check passed on their own.
- **Files modified:** none
- **Verification:** the listing above
- **Committed in:** n/a

**2. [Ordering] `state.advance-plan` declined on its first call**
- **Found during:** Task 3
- **Issue:** The plan orders the state.* calls before the close-out commit, but advance-plan refuses to run while 204-16 has no SUMMARY.md on disk (`reason: plans_outstanding`). It left STATE.md unchanged. update-progress, record-metric and record-session all succeeded.
- **Fix:** I re-ran `state.advance-plan` once, with the same flag-free invocation, after writing this SUMMARY. The result is in the STATE diff above.

**Total deviations:** 2. Both are tooling-only, and neither changes code. **Impact:** none on the delivered code. The browser gate's non-screenshot clause should be made ANSI-aware in future plans.

## Issues Encountered

- The keyword-clause subtree fallback returns the head line for a plain `"""` string body, because such strings carry no line metadata. It is only reached when `end_of_expression` is absent. The Elixir 1.17.3 probe showed that key is always present on a keyword-form def, including when the def is a module's last expression.

## Known Stubs

None.

## Next Phase Readiness

204-16 closes the single gap in 204-VERIFICATION (STRUCT-04). Phase 204 is ready for re-verification. Review items WR-02 and IN-01..IN-05 remain out of scope and still open.

## Self-Check: PASSED

- The FOUND files are repository_boundary.ex, critic.measure.ex, source_size_contract_test.exs and 204-12-SUMMARY.md (with its erratum).
- The FOUND commits are 00dfb6aa, e8e66b27, 8d53836f, 857dac3b and 456f3500.
- All acceptance criteria for Tasks 1–3 were re-run, and each one passed.

---
*Phase: 204-structure*
*Completed: 2026-09-24*
