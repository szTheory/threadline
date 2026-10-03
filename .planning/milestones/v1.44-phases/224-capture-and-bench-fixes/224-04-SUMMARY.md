---
phase: 224-capture-and-bench-fixes
plan: 04
subsystem: docs
tags: [docs, changelog, ci, mix-test, suite-measurement]

requires:
  - phase: 224-01
    provides: "the unconditional first-run down function drop this docs remediation points to"
  - phase: 224-02
    provides: "the property test's own solo cost, cross-referenced in the SUITE-06 table"
  - phase: 224-03
    provides: "bench-compile fix and verify.bench_compile step, exercised by this plan's ci.all run"
provides:
  - "Adopter-facing guide prose covering rollback of a pre-fix (0.11.2-or-earlier) rerun chain, pointed at the existing rollback-cleanup SQL sweep"
  - "CHANGELOG Unreleased Fixed entry for the CAPT-01 rollback fix, linked to the guide"
  - "224-EVIDENCE.md SUITE-06 local + CI wall-clock record and the mix ci.all phase-gate result"
affects: [225-suite-baseline]

actuals:
  tokens: 1990
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Reused the existing pinned rollback-cleanup-sql marker block for a broadened adopter case, rather than adding a second snippet"

key-files:
  created: []
  modified:
    - guides/upgrading-to-0.11.md
    - CHANGELOG.md
    - .planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md

key-decisions:
  - "D-06: documented the pre-fix rerun-chain remediation as new prose under the existing '## Rolling back' heading, reusing the pinned rollback-cleanup-sql block verbatim (byte-identical to base) rather than adding a second marker pair or naming Threadline.Capture.TriggerSQL"
  - "Local SUITE-06 wall clock showed high run-to-run variance (head run1 282.5s vs run2 187.7s; base run1 231.0s vs run2 243.2s) attributable to concurrent unrelated processes on the shared machine, not to the +5 tests/+1 property this phase added (isolated property cost ~4-5s per 224-02); recorded all 4 runs plus the reliable CI run 36730596489 citation rather than treating the noisy local delta as a regression signal"
  - "CI 'after' figure recorded as pending a maintainer push grant with the exact gh commands, per this plan's executor_safety constraint against pushing or dispatching CI"

patterns-established: []

requirements-completed: [CAPT-01, SUITE-06]

coverage:
  - id: D1
    description: "Guide's Rolling back section broadened to cover a chain whose first trigger migration predates this fix, pointing at the existing rollback-cleanup SQL sweep; no second snippet, no TriggerSQL mention"
    requirement: CAPT-01
    verification:
      - kind: integration
        ref: "test/threadline/upgrading_to_0_11_doc_contract_test.exs (marker-exactly-once, headings, banned-vocabulary tests)"
        status: pass
      - kind: integration
        ref: "test/threadline/upgrade_rollback_test.exs#rolling back a whole upgraded fixture (live-catalog proof of the pinned SQL snippet)"
        status: pass
      - kind: other
        ref: "diff of the rollback-cleanup-sql marker block against dd780e68 (byte-identical, exit 0)"
        status: pass
    human_judgment: false
  - id: D2
    description: "CHANGELOG Unreleased Fixed entry documents the fix for adopters and links to the guide's Rolling back section"
    requirement: CAPT-01
    verification:
      - kind: integration
        ref: "test/threadline/changelog_contract_test.exs (dated-entry, ownership-split, bracketed-heading checks; scoped to dated entries so Unreleased prose is exercised only by the acceptance-criteria greps below)"
        status: pass
      - kind: other
        ref: "grep -n \"### Fixed\" CHANGELOG.md (before first dated heading) + grep -c \"Nothing yet for the next release\" CHANGELOG.md == 0 + bullet contains upgrading-to-0.11.md#rolling-back"
        status: pass
    human_judgment: false
  - id: D3
    description: "SUITE-06: suite wall clock measured before (dd780e68, local worktree + CI run 36730596489) and after (phase head, local), with the CI 'after' recorded as pending a maintainer push grant"
    requirement: SUITE-06
    verification:
      - kind: manual_procedural
        ref: ".planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md#Suite wall clock (SUITE-06)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Phase gate: mix ci.all exits 0 on the phase head, including the new verify.bench_compile step and the browser lane; bin/verify-repo-hygiene clean"
    verification:
      - kind: other
        ref: "mix ci.all (exit 0; verify.test 10 properties/2583 tests/0 failures; browser lane 315 passed/3 flaky-passed/26 skipped)"
        status: pass
      - kind: other
        ref: "bin/verify-repo-hygiene (4268 tracked files clean, 0 inert)"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-09-30
status: complete
---

# Phase 224 Plan 04: Docs Remediation and Suite Measurement Summary

**Broadened the upgrade guide's Rolling back section and added a CHANGELOG Fixed entry for adopters with a pre-0.11.2-or-earlier rerun chain, then measured the phase's suite wall clock (local + CI citation) and confirmed `mix ci.all` green on the phase head.**

## Performance

- **Duration:** ~50 min
- **Started:** 2026-09-30
- **Completed:** 2026-09-30
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- `guides/upgrading-to-0.11.md` "## Rolling back" section now covers a chain whose first trigger migration was generated by 0.11.2 or earlier, followed by a rerun that added redaction, exclusions or `store_changed_from`: that rerun's per-table function can be left behind after a full rollback, and the existing `<!-- threadline:rollback-cleanup-sql:start/end -->` sweep (byte-identical to `dd780e68`, live-tested by `upgrade_rollback_test.exs`) removes it. The closing sentence was corrected so it no longer implies a universally clean `pg_proc` for pre-fix chains.
- `CHANGELOG.md`'s `## Unreleased — highlights` section gained `### Breaking changes` (None.) and a `### Fixed` entry describing the rollback fix for adopters, linking to `guides/upgrading-to-0.11.md#rolling-back`.
- `224-EVIDENCE.md` gained `## Suite wall clock (SUITE-06)` (4 local runs — head and base, two each, both in a `git worktree add --detach dd780e68` checkout removed afterward — plus CI run `36730596489`'s per-job durations as the "before" citation, and the "after" recorded as pending a maintainer push grant with the exact `gh` commands) and `## Phase gate` (`mix ci.all` exit 0, `verify.test` and browser-lane summaries, `bin/verify-repo-hygiene` clean).
- Confirmed the ROADMAP Phase 224 Research note already matches D-01 (commit `02c0dfbd`); no edit needed.

## Task Commits

1. **Task 1: Tracer — guide remediation prose and CHANGELOG entry, proven by the live-catalog and doc-contract tests** - `4db4d3db` (docs)
2. **Task 2: SUITE-06 wall clock, CI citations, roadmap note check, and the ci.all phase gate** - `d8cdeee2` (docs)

## Files Created/Modified
- `guides/upgrading-to-0.11.md` - broadened "## Rolling back" prose for pre-fix rerun chains, corrected closing sentence
- `CHANGELOG.md` - `### Breaking changes` (None.) + `### Fixed` entry under `## Unreleased — highlights`
- `.planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md` - new `## Suite wall clock (SUITE-06)`, `## Roadmap check (D-01)`, `## Phase gate` sections

## Decisions Made
- Followed 224-CONTEXT.md D-06 exactly: reused the pinned rollback-cleanup SQL sweep rather than adding a second snippet, and never named `Threadline.Capture.TriggerSQL` in guide prose.
- The plan's own step 3 threshold (repeat both local runs once if head/base differ by more than 10% beyond the property's own cost) was triggered by run 1's 52s real-time gap; repeated both runs. Run 2 showed the opposite sign with an even larger swing, confirming the local signal is dominated by shared-machine load noise (other unrelated project processes were observed running concurrently via `ps aux`) rather than by this phase's own +5 tests / +1 property. Recorded all 4 runs plus the CI citation rather than picking one run to report as "the" number.
- CI "after" recorded as `pending: needs a maintainer push grant` with the exact `gh run list`/`gh run view` commands, per this plan's `executor_safety` constraint against pushing or dispatching CI. Confirmed via a read-only `gh run list --workflow ci.yml --branch milestone/v1.44 --limit 3` that no runs exist yet (branch never pushed).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None. The local machine ran other unrelated project processes concurrently during both measurement passes, producing high wall-clock variance; this is documented in the evidence file rather than treated as a defect, since the CI citation (single-tenant runners) is the reliable before/after signal per D-18.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 224 (Capture and Bench Fixes) is now fully executed: 224-01 (CAPT-01/CAPT-02 deterministic half), 224-02 (CAPT-02 property half), 224-03 (SUITE-05 bench compile), 224-04 (this plan: CAPT-01 docs remediation + SUITE-06 measurement + phase gate).
- `mix ci.all` exits 0 on the phase head (`4db4d3db` before this plan's docs commits; `d8cdeee2` after). `mix test test/threadline/upgrading_to_0_11_doc_contract_test.exs test/threadline/upgrade_rollback_test.exs test/threadline/changelog_contract_test.exs` (20/0), `mix verify.credo` (clean, 0 issues over 383 files), `mix format --check-formatted` (clean) all pass.
- `bin/verify-repo-hygiene` clean (4268 tracked files, 0 inert).
- CI "after" figure for SUITE-06 remains pending a maintainer push grant — the exact command is recorded in `224-EVIDENCE.md`.
- Ready for phase 224 verification, then `/gsd-plan-phase 225` (Suite Baseline and Partitioned CI), which opens with a fresh local `mix test --slowest 50` run.

## Self-Check: PASSED

- `[ -f guides/upgrading-to-0.11.md ]` FOUND
- `[ -f CHANGELOG.md ]` FOUND
- `[ -f .planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md ]` FOUND
- `git log --oneline -3` shows `d8cdeee2` and `4db4d3db` present in history
- Re-ran all task `<verify>` commands: `mix test test/threadline/upgrading_to_0_11_doc_contract_test.exs test/threadline/upgrade_rollback_test.exs test/threadline/changelog_contract_test.exs` (20/0), `mix ci.all` (exit 0), the Task 2 automated bash check (SUITE-06 heading + dd780e68 + run id present, worktree count 1 — all pass), `bin/verify-repo-hygiene` (clean) — all pass
- `plan_head_before: 57715c58e3b4a9cd656558242ce2fc0413ef4fac`, `plan_head_after: d8cdeee220e35fc6f11c342a3a66bca5a1094818`, commits measured via `git rev-list --count 57715c58..HEAD` = 2

---
*Phase: 224-capture-and-bench-fixes*
*Completed: 2026-09-30*
