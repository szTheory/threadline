---
phase: 246-debt-closeout-and-critic-retirement
plan: 06
subsystem: planning-ledgers
tags: [debt, register, seeds, quality-roadmap, critic-retirement]
status: complete
requires: ["246-05"]
provides:
  - "246-DEBT-REGISTER.md: 131 evidenced rows (64 closed, 44 waived, 23 routed), 60 W anchors"
  - "SEED-005 closure schema; SEED-008 operator-UI carry seed"
  - "QUALITY-ROADMAP v1.48/v1.49/v1.51 route lines and Disposition (246) pointer"
affects: ["246-07 (WINDOWS writes use the register's W dispositions and #W<n> anchors)"]
tech-stack:
  added: []
  patterns: ["register rows cross-reference adjacent records instead of merging them (W7 and 198-CR-05)"]
key-files:
  created:
    - .planning/phases/246-debt-closeout-and-critic-retirement/246-DEBT-REGISTER.md
    - .planning/seeds/SEED-008-operator-ui-carry.md
  modified:
    - .planning/seeds/SEED-005-reconnect-banner-shell-mount.md
    - .planning/research/QUALITY-ROADMAP-2026-10-24.md
    - .planning/milestones/v1.45-phases/231-facade-topology-and-the-capture-semantics-edge/231-REVIEW-DISPOSITION.md
    - .planning/UI-MILESTONE-PREFLIGHT.md
    - .planning/MILESTONE-GUIDE.txt
    - .planning/PROJECT.md
decisions:
  - "218 WR-03 waived on locked maintainer decision 218 D-04 (orchestrator resolution 2); departs from D-19's REL-02 framing"
  - "W9 and W47 keep D-20's waived disposition, but their reasons are not 'obsolete with DEBT-02': W9 is a dropdown flake that has not reproduced, W47 is a process record"
  - "SEED-008 uses status: dormant because SEED-007 now reads 'absorbed (v1.47)', which is not an open status"
metrics:
  duration: 35min
  completed: 2026-10-25
estimate:
  tokens: 95000
  tasks: 3
actuals:
  tokens: 12137
  tasks: 3
  commits: 3
plan_head_before: 37dc883d04a3ead7395f5e6d10f5798b9a84f100
plan_head_after: e29e6c5f305912151b60c663b81ff41f7da0e61a
---

# Phase 246 Plan 06: DEBT-01 record Summary

The phase now has one canonical carried-debt register: `246-DEBT-REGISTER.md`, with 131 rows. Each row has a source file, evidence at `37dc883d` or a commit on main, and one disposition: `closed` (64), `waived` (44) or `routed` (23). The 60 WINDOWS rows appear as `W<n>` anchors in the D-20 buckets.

Other changes in this plan:

- SEED-005 moved to the SEED-006 closure schema.
- SEED-008 is planted as the operator-UI carry.
- Every route is now listed in its milestone's candidate list in QUALITY-ROADMAP.
- The stale 231 WR-01 disposition row was hand-fixed.
- No live planning file calls the critic "parked" any more.

## Commits

| Task | Commit | Files |
|---|---|---|
| 1 (tracer) register | 6d72086c | 246-DEBT-REGISTER.md |
| 2 seeds + routes | 60f82a3b | SEED-005, SEED-008, QUALITY-ROADMAP-2026-10-24.md |
| 3 stale row + live wording | e29e6c5f | 231-REVIEW-DISPOSITION.md, UI-MILESTONE-PREFLIGHT.md, MILESTONE-GUIDE.txt, PROJECT.md |

## Register contents

- **Required ids:** every id in the close check's literal array is present.
- **217:** 11 rows, `217-R1-*` and `217-R2-*`. They cite squash #60 (3c4ac9b1) and #66 (db8d5373), because the phase-branch hashes in 217-REVIEW-DISPOSITION.md are not ancestors of HEAD.
- **Extra ids beyond the array:**
  - `215-CR-01` and `215-WR-02`, fixed in 215-06 and named in 215-06-SUMMARY.md.
  - `198-CR-05`, the review-finding twin of W7. Following the adjacency rule, the two rows cross-reference each other and are not merged.
- **D-00a:** 223 WR-01..05 are closed on dd780e68 (#70), each citing its file:line. 223 IN-01 is closed on 6e439225.
- **D-18:** applied as written. 216 IN-01 is **closed** on 46efd9d4, as 246-05 recorded. 215 WR-09 is routed to v1.51 together with WR-10, following RESEARCH: it has a security angle, so it cannot be waived.
- **D-19:**
  - 221 BASH_ENV is closed, citing `ci_workflow_parity_contract_test.exs:1856` and `:1793-1796`.
  - ECON-03 is routed to v1.48; 244-REL02-EVIDENCE.md is still `Status: pending`.
  - 218 WR-03 is waived on 218 D-04. The row notes the deviation from D-19.
- **D-20:** W rows were re-verified against HEAD.
  - The fixed-bucket evidence holds. Examples: `bin/verify-branch-protection:94-103,111-163` for W5/W6; `.dialyzer_ignore.exs` is `[]` for W42; the Export expired regexes at HEAD; `demo_reset_test.exs` setup_all; the exerciseMobileNav opt-out; and `bin/upsert-ci-issue` for W1.
  - The DEBT-02 rows cite the removal slices that deleted their files (C1 4b2c3f89, C2 cbb804a6, C3b 1258c014, C4 35243789).

## Checks

- **234-REVIEW-DISPOSITION.md:** WR-01 already reads fixed, so the file was left alone.
- **233:** it has only 233-REVIEW.md and no disposition file, so there was nothing to hand-fix.
- **Final `verify-phase.sh --close`:** every check prints `ok:` except `FAIL: WINDOWS ledger has zero open rows and open_count: 0 (check 4)`. That check stays red until plan 246-07 writes WINDOWS.
- **Hygiene:** the username and machine-path greps over every staged file found 0 hits.

## Deviations from Plan

1. **[Rule 1] 231 frontmatter `open:` count.** Hand-editing WR-01 to fixed left the frontmatter at `open: 2` while only IN-01 was still open. I set it to `open: 1` so the frontmatter matches its rows.
2. **[Re-verification] W9 and W47 reasons.** D-20 lists both as "obsolete with DEBT-02". At HEAD that does not hold:
   - The `#stress-dropdown-button` story still exists (`operator-accessibility.spec.ts:1078`). W9 is waived as a flake that has not reproduced: the lane has run at exactly the 8 screenshot failures since phase 201.
   - W47 concerns the Dialyzer-slice verifier, not the critic. It is waived as an obsolete process record.
   Both keep the waived disposition, so the D-20 bucket counts (21/33/6) are unchanged.
3. **[Rule 2] Extra stale critic wording in UI-MILESTONE-PREFLIGHT.md.** Besides `:246`, two more lines described the critic as live:
   - the proof-layer table row naming the removed `mix verify.capture` / `mix verify.mechanical`;
   - the `:144` "Keep Threadline's paid critic parked" line.
   Both now say retired, with the tag. In MILESTONE-GUIDE.txt, the SEED-005 line beside `:301` now reads closed.
4. **SEED-008 `status: dormant`.** SEED-007 is no longer open ("absorbed (v1.47)"), so I used the open-seed status from SEED-006's history and the close-check fixture.
5. **Tooling scratch.** I loaded register-check.py through importlib to count rows, and that left a `tools/__pycache__/` that tripped the hygiene greps. I deleted it before committing; nothing generated was committed.

STATE.md, ROADMAP.md, WINDOWS.md, CHANGELOGs and CRITIQUE.md were not touched. The `archive/ui-critic-loop` tag does not exist yet: per D-13 it is created after the removal squash lands. The wording points at it the same way CONTRIBUTING.md:289 already does.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: 246-DEBT-REGISTER.md, SEED-008-operator-ui-carry.md
- FOUND: 6d72086c, 60f82a3b, e29e6c5f (all ancestors of HEAD)
