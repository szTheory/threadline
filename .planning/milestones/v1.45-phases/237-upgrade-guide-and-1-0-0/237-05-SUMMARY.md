---
phase: 237-upgrade-guide-and-1-0-0
plan: 05
subsystem: release
tags: [hex, release-please, github-actions, 1.0.0]
requires:
  - phase: 237-upgrade-guide-and-1-0-0
    provides: "Release candidate, adopter guide, and green candidate CI"
provides:
  - "Published threadline 1.0.0 package with docs on Hex.pm"
  - "Recorded the exact protected publication, smoke test, distribution sync, and public artifact evidence"
  - "Refreshed milestone arc to show v1.45 and 1.0.0 shipped"
affects: [milestone-close, release]
actuals:
  tokens: 1700
  tasks: 2
  commits: 0
tech-stack:
  added: []
  patterns: ["Separate explicit grants for release merge and protected publication"]
key-files:
  created:
    - .planning/phases/237-upgrade-guide-and-1-0-0/237-05-SUMMARY.md
  modified:
    - .planning/phases/237-upgrade-guide-and-1-0-0/237-VERIFICATION.md
    - .planning/MILESTONE-ARC.md
    - .planning/STATE.md
key-decisions:
  - "Treat the production Hex approval as its own D-05 grant, separate from the Release PR merge."
  - "Leave generated distribution-sync PR #80 open until its CI result and its own merge decision."
requirements-completed: [REL-03]
coverage:
  - id: D1
    description: "Threadline 1.0.0 is published on Hex.pm with documentation and a matching successful protected publish job."
    requirement: REL-03
    verification:
      - kind: other
        ref: "Hex release API 1.0.0; release workflow 37706469316 publish job 113084855750"
        status: pass
    human_judgment: false
  - id: D2
    description: "Post-publication smoke test and distribution sync succeeded; generated PR #80 is recorded without merging it."
    verification:
      - kind: other
        ref: "Release workflow jobs 113086596432 and 113086937773; PR #80 status recorded in 237-VERIFICATION.md"
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-10-08
status: complete
plan_head_before: 933ac0945c3e6de447b3a2d5930f03888189ff51
plan_head_after: 933ac0945c3e6de447b3a2d5930f03888189
commits: 0
---

# Phase 237 Plan 05: Publish 1.0.0 Summary

**The separately authorized production workflow published threadline 1.0.0 with docs to Hex.pm, passed the smoke test, and synchronized the distribution docs.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-10-08T00:23:30Z
- **Completed:** 2026-10-08T00:29:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Recorded the maintainer's separate `yes` grant and successful protected publish job for release run `37706469316` and SHA `f815e589c954a8e3983bc6f73b21c9e3304d6aa4`.
- Verified Hex serves version `1.0.0` with docs; package checksum is `ca848cfb6afe6b539d7e823bf6ed51115e384c4622ee8ee5331b16274ac7f87f`.
- Recorded successful post-publish smoke test and distribution sync, and kept PR #80 open/unmerged pending its own CI and merge decision.
- Refreshed the milestone arc to show v1.45 / 1.0.0 shipped on 2026-10-08.

## Task Commits

No task commits were made. The plan consisted of explicit release checkpoints and evidence documentation; repository changes remain uncommitted so the orchestrator can complete phase-level bookkeeping without staging unrelated shared-worktree edits.

## Files Created/Modified

- `.planning/phases/237-upgrade-guide-and-1-0-0/237-VERIFICATION.md` — protected publish grant, release/job links, Hex metadata, smoke test, and unmerged distribution follow-up.
- `.planning/MILESTONE-ARC.md` — v1.45 and 1.0.0 marked shipped.
- `.planning/STATE.md` — both plan tasks recorded complete; Phase 237 remains executing for final verification/bookkeeping.
- `.planning/phases/237-upgrade-guide-and-1-0-0/237-05-SUMMARY.md` — plan outcome and evidence.

## Decisions Made

- Kept the production Hex grant separate from the earlier Release PR merge grant.
- Left generated distribution-sync PR #80 unmerged because its CI was still running and it has no merge authorization.

## Deviations from Plan

None — both checkpointed tasks completed as planned. No external actions or tests were run during this documentation continuation; the recorded CI and Hex API evidence came from the completed release workflow.

## Issues Encountered

The distribution-sync workflow opened PR #80, which remains open and unmerged while CI runs. It requires its own CI result and merge decision.

## User Setup Required

None.

## Next Phase Readiness

Both Plan 237-05 tasks are complete, and v1.0.0 is publicly available from Hex.pm. Phase 237 remains executing until the orchestrator completes final verification and phase bookkeeping. PR #80 is an unmerged generated follow-up and must be handled under its own authorization.

## Self-Check: PASSED

- Summary file exists.
- Current recorded HEAD `933ac0945c3e6de447b3a2d5930f03888189ff51` is the unchanged plan base; zero commits is correct for this documentation-only continuation.
- Protected publish, public package, smoke-test, distribution-sync, and PR #80 evidence are present in the verification record.

---
*Phase: 237-upgrade-guide-and-1-0-0*
*Completed: 2026-10-08*
