---
phase: 104-reference-walkthrough-charter-override-decision
plan: 01
subsystem: planning
tags: [charter, override, milestone-arc, project-md, doc-edit, v1.23]

# Dependency graph
requires:
  - phase: 103-authority-surface-reconciliation-and-closeout
    provides: v1.22 closeout decisions and PROJECT.md Key Decisions baseline
provides:
  - PROJECT.md Key Decisions row recording the deliberate v1.22 -> v1.23 framing override with bolded re-engagement trigger
  - PROJECT.md **v1.23 non-goals:** subsection (Evidence subjects, RBAC/tenancy/lib boundary, no "demo product" rebrand + Sigra carve-out)
  - MILESTONE-ARC.md header refreshed to v1.23 active state (Updated, Active milestone, Next ranked candidate)
  - MILESTONE-ARC.md strategic-thesis paragraph extended with override sentence cross-linking PROJECT.md Key Decisions
  - MILESTONE-ARC.md option-record row 6 (Policy / compliance depth) flipped to Shipped (v1.22) with past-tense Why cell
  - MILESTONE-ARC.md arc-order v1.22 row flipped to **shipped**; new v1.23 row appended with synthetic-first-adopter theme and non-goals
  - PROJECT.md last-updated footnote tense corrected (will record -> recorded) to keep the footnote honest post-commit
  - One-line precedent rule for the next `/gsd-complete-milestone` archive pass (D-05; verbatim below)
affects:
  - "105-help-desk-domain-expansion (will read locked v1.23 non-goals as scope guard for lib/ read-only and Evidence-subject ceiling)"
  - "106-sigra-real-signup-login (will read sub-phase 106b escape-valve carve-out from PROJECT.md non-goals)"
  - "107-mix-demo-seed-reset (will inherit examples/threadline_phoenix/ scope from non-goals)"
  - "108-walkthrough-script (will reference v1.23 framing and non-goals as scope contract)"
  - "109-maintainer-dry-run (synthetic-first-adopter framing originates here)"
  - "110-fix-vs-defer-triage (re-engagement trigger and v1.24-seeds routing originate here)"
  - "/gsd-complete-milestone (at v1.23 close; D-05 precedent rule applies to its checklist)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Override Key Decision row with bolded re-engagement clause inline in Rationale (v1.18 precedent extended for open-ended `— Active (recorded ...)` status)"
    - "Milestone-block release-scoped non-goals as a `**v1.23 non-goals:**` bullet subsection inside the Current Milestone block (distinct from top-level `## Out of Scope` and from shipped-milestone `**Non-goals (unchanged):**` inline prose)"
    - "Closeout-gate / first-milestone-phase carve-out: stale-status doc-hygiene sweeps in archive-owned docs are allowed; narrative restructuring remains `/gsd-complete-milestone`'s job (D-05 precedent rule)"

key-files:
  created:
    - .planning/phases/104-reference-walkthrough-charter-override-decision/104-01-SUMMARY.md
  modified:
    - .planning/PROJECT.md
    - .planning/MILESTONE-ARC.md

key-decisions:
  - "v1.23 deliberately overrides v1.22's real-adopter-first closeout rule and ships a synthetic-first-adopter walkthrough instead (override scoped to v1.23 only)"
  - "Re-engagement is triggered by the first sustained real-adopter signal — defined as any of (a) a live-integration issue, (b) a maintainer-confirmed pilot host, or (c) a named procurement/security-review/evaluation conversation; drive-by interest routes to .planning/v1.24-seeds/"
  - "v1.23 non-goals are locked in PROJECT.md Current Milestone block (no new Evidence subjects, no Threadline-owned RBAC/tenancy DSLs, no lib/ auth or domain-model code, no reference-app rebrand to 'demo product', no Sigra extension absent contract gap)"
  - "MILESTONE-ARC.md targeted-fix sweep is doc-hygiene, not narrative restructuring — D-05 precedent rule preserves the D-02 archive/closeout-gate separation"

patterns-established:
  - "First-milestone-phase status-field freshness sweep: a charter phase opening a new milestone may correct demonstrably-stale status fields (Updated date, Active milestone, Next ranked candidate, option-record + arc-order status fields) in MILESTONE-ARC.md in the same commit batch that adds the new milestone row, without crossing into narrative restructuring"
  - "Override decisions get a `— Active (recorded Phase N, vN.NN, YYYY-MM-DD)` open-ended status cell (matching v1.19 precedent) rather than `✓ Shipped` — the row remains live until the re-engagement trigger fires or the override expires at milestone close"

requirements-completed: [CHARTER-01, CHARTER-02, CHARTER-03]

# Metrics
duration: ~6min
completed: 2026-05-27
---

# Phase 104 Plan 01: Reference-Walkthrough Charter & Override Decision Summary

**Locked the deliberate v1.22 -> v1.23 framing override (synthetic-first-adopter walkthrough) and v1.23 non-goals across PROJECT.md and MILESTONE-ARC.md in three atomic commits, with the re-engagement trigger bolded in the new Key Decisions row and a v1.23 arc-order row added under a refreshed header.**

## Performance

- **Duration:** ~6 min (execution-only wall time; three commits landed at 09:30:31, 09:31:19, 09:31:49 local time over 78 git-timestamp seconds)
- **Started:** 2026-05-27T13:28:02Z (per planner-recorded session start in STATE.md)
- **Completed:** 2026-05-27T13:32:10Z
- **Tasks:** 3 of 3 completed
- **Files modified:** 2 (`.planning/PROJECT.md`, `.planning/MILESTONE-ARC.md`)

## Accomplishments

- Recorded the v1.22 -> v1.23 framing override as a new PROJECT.md Key Decisions row, matching v1.18 density/voice with a bolded `**Re-engages the v1.22 rule on first sustained real-adopter signal**` clause and a three-shape trigger definition (live-integration issue / pilot host / procurement-or-security-review conversation).
- Locked v1.23-scoped non-goals as a new `**v1.23 non-goals:**` subsection inside the PROJECT.md Current Milestone block: no new `Threadline.Evidence` subjects, no Threadline-owned RBAC/tenancy DSLs, no `lib/` auth or domain-model code, no rebrand of `examples/threadline_phoenix/` to "demo product", and no Sigra extension absent a contract gap (with the sub-phase 106b escape-valve carve-out spelled out verbatim).
- Refreshed MILESTONE-ARC.md so it no longer actively lies about v1.22 being active: header `Updated` / `Active milestone` / `Next ranked candidate` flipped to v1.23 state; strategic-thesis paragraph extended with the override-and-re-engagement sentence; option-record row 6 status flipped to `**Shipped (v1.22)**` with past-tense Why cell; arc-order v1.22 row status flipped to `**shipped**`; new v1.23 arc-order row appended with synthetic-first-adopter theme and full non-goals cell.
- Kept the PROJECT.md last-updated footnote honest by flipping `Phase 104 will record...` to `Phase 104 recorded...` in the same task as the substantive PROJECT.md edits (Landmine 7 recommendation from 104-RESEARCH.md).

## Task Commits

Each task was committed atomically on `main`:

1. **Task 1: PROJECT.md — v1.23 non-goals subsection + Key Decisions row + stale footnote refresh** — `f6db97e` (docs)
2. **Task 2: MILESTONE-ARC.md — header refresh + strategic-thesis append + option-record row 6 past-tense rewrite** — `ac0cd27` (docs)
3. **Task 3: MILESTONE-ARC.md — arc-order v1.22 status flip + new v1.23 arc-order row** — `9985f96` (docs)

The orchestrator owns STATE.md, ROADMAP.md, and REQUIREMENTS.md updates after the wave completes; no final metadata commit is made by this executor (per `<parallel_execution>` directives in the orchestrator-supplied prompt).

## Files Created/Modified

- `.planning/PROJECT.md` — Inserted `**v1.23 non-goals:**` bullet subsection in the Current Milestone block (3 bullets, positioned between `**Key context:**` block and `**Current State:**`); appended the v1.23 override row to the `## Key Decisions` table; flipped the last-line footnote tense from `will record` to `recorded`.
- `.planning/MILESTONE-ARC.md` — Header (lines 3-5) flipped to v1.23 active state; strategic-thesis paragraph (line 9) extended with the override sentence and PROJECT.md cross-reference; option-record table row 6 status + Why cell rewritten as a done-thing; arc-order table v1.22 status flipped to `**shipped**`; new v1.23 arc-order row appended (file grew 41 -> 42 lines).
- `.planning/phases/104-reference-walkthrough-charter-override-decision/104-01-SUMMARY.md` — This summary (committed after the three task commits).

## D-05 Precedent Rule (for the next `/gsd-complete-milestone` checklist)

> *"Closeout-gate and first-milestone-phase work may correct demonstrably-stale status fields in archive-owned docs, but never restructure narrative sections or option/rank ordering — that remains `/gsd-complete-milestone`'s job."*

This rule was the boundary discipline that allowed Phase 104 to refresh MILESTONE-ARC.md's stale header / strategic-thesis / option-record-row-6 / arc-order-v1.22-status fields in the same commit batch that added the v1.23 arc-order row, without crossing into D-02 territory (D-02 archive/closeout-gate separation). The v1.22 closeout (`/gsd-complete-milestone` for v1.22) demonstrably missed these status fields — recording this rule as a retrospective input lets a future archive pass either sweep them automatically or rely on the first-milestone-phase carve-out documented here.

## Decisions Made

None new — the five locked decisions (D-01 through D-05) from `104-CONTEXT.md` were executed verbatim. The verbatim row text from D-02 and the verbatim non-goals bullets from D-03 were preserved exactly. The past-tense rewording of MILESTONE-ARC.md option-record row 6 "Why" cell (Edit 2E) used the wording suggested in `104-RESEARCH.md` Landmine 3 verbatim ("Shipped durable evidence records and audit-of-audit posture after the support-safe adopter lane proved out — without broadening into a Threadline-owned platform expansion"), which was planner's discretion per CONTEXT.md.

## Deviations from Plan

None — plan executed exactly as written. All three tasks committed in plan order, all `<automated>` grep gates green on first verification pass, all ordering / line-count checks green, scope guard clean (only `.planning/PROJECT.md` and `.planning/MILESTONE-ARC.md` modified by the three plan commits).

## Issues Encountered

**Worktree expectation mismatch (informational, not a deviation):** The orchestrator-supplied prompt included a `<parallel_execution>` block stating "You are running as a PARALLEL executor agent in a git worktree" and a `<worktree_branch_check>` block expecting HEAD on a `worktree-agent-*` branch. The actual execution environment was the main repo (`/Users/jon/projects/threadline`) on branch `main` (`.git` is a directory, `git worktree list` shows no linked worktrees). The executor's per-commit step-0 worktree-HEAD assertion correctly gates on `if [ -f .git ]` (only fires inside a worktree), so commits proceeded normally on `main`. This is recorded for orchestrator-side awareness in case the worktree-spawn step was intended to run but did not. No work was lost or compromised — the scope guard limited all writes to two `.planning/` doc files, and the three task commits are linear on `main` immediately after the `a977bfa` plan-creation commit.

## Known Stubs

None — this is a documentation-only phase. No UI components, no data wiring, no placeholder code paths.

## Threat Flags

None — Phase 104 introduces no new trust boundaries, no input handling, no network endpoints, no auth paths, no schema changes. The all-accept STRIDE disposition from the plan's `<threat_model>` block holds: doc-only edits whose integrity surface is git history.

## User Setup Required

None — no external service configuration required.

## Success Criteria Pass/Fail

All five plan-level success criteria pass:

| # | Criterion | Status | Verification |
|---|-----------|--------|--------------|
| 1 | **CHARTER-01** — PROJECT.md Key Decisions row with verbatim opening clause + bolded re-engagement clause | PASS | `grep -Fq 'v1.23 deliberately overrides v1.22' .planning/PROJECT.md` PASS; `grep -Fq '**Re-engages the v1.22 rule on first sustained real-adopter signal**' .planning/PROJECT.md` PASS |
| 2 | **CHARTER-02** — MILESTONE-ARC.md v1.23 arc-order row + strategic-thesis sentence | PASS | `grep -Fq '| v1.23 | **active** | Realistic-Demo Walkthrough |' .planning/MILESTONE-ARC.md` PASS; `grep -Fq "v1.23 deliberately overrides v1.22's 'real-adopter-first' closeout rule" .planning/MILESTONE-ARC.md` PASS |
| 3 | **CHARTER-03** — v1.23 non-goals locked in PROJECT.md with correct ordering | PASS | `grep -Fq '**v1.23 non-goals:**' .planning/PROJECT.md` PASS; `awk` ordering-check (non-goals precedes Current State) PASS |
| 4 | **Scope guard** — only `.planning/PROJECT.md` and `.planning/MILESTONE-ARC.md` modified by the three plan commits | PASS | `git diff --name-only HEAD~3 HEAD` returns exactly those two paths |
| 5 | **No stale-doc regressions** — `Phase 104 will record...`, `Updated: 2026-05-25`, `\| v1.22 \| **active** \| Policy / Evidence Plane \|` all absent | PASS | All three negative greps return no match |

The <2-minute cold-read criterion (ROADMAP success criterion 4) is **deferred to verify-phase / 104-VERIFICATION.md** per the plan's `<verification>` section — it is human-validated only and is logged as a Manual-Only Verification in `104-VALIDATION.md`.

## Self-Check: PASSED

Verified after writing SUMMARY.md:

- `[ -f .planning/PROJECT.md ]` -> FOUND
- `[ -f .planning/MILESTONE-ARC.md ]` -> FOUND
- `[ -f .planning/phases/104-reference-walkthrough-charter-override-decision/104-01-SUMMARY.md ]` -> FOUND (this file, after Write)
- `git log --oneline | grep f6db97e` -> FOUND
- `git log --oneline | grep ac0cd27` -> FOUND
- `git log --oneline | grep 9985f96` -> FOUND

All five plan-level success criteria green; all per-task `<automated>` grep gates green; all ordering and line-count checks green; scope guard clean.

## Next Phase Readiness

- v1.23 charter is locked. Phases 105-110 can read `.planning/PROJECT.md` (Current Milestone block + Key Decisions table) and `.planning/MILESTONE-ARC.md` (arc-order v1.23 row) as the authoritative scope and non-goals contract.
- Phase 105 (`105-help-desk-domain-expansion`) is unblocked; its scope guard for `lib/` read-only is consistent with the v1.23 non-goals locked here.
- No blockers introduced.

---
*Phase: 104-reference-walkthrough-charter-override-decision*
*Plan: 01*
*Completed: 2026-05-27*
