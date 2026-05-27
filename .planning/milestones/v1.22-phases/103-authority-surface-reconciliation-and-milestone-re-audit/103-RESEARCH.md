# Phase 103: Authority-Surface Reconciliation And Milestone Re-Audit - Research

**Researched:** 2026-05-27
**Domain:** Planning-surface reconciliation + milestone audit rerun (closeout gate for v1.22)
**Confidence:** HIGH

## Summary

Phase 103 is the v1.22 mirror of Phase 94 (v1.21 closeout). All five reusable
artifact shapes — `XX-01-PLAN.md`, `XX-02-PLAN.md`, `XX-VERIFICATION.md`,
`XX-VALIDATION.md`, and the rewritten `vX.YY-MILESTONE-AUDIT.md` — exist on
disk and have been read end-to-end. The current authority surfaces still tell
the pre-backfill story (8 of 12 satisfied; SURF-01/02/03 marked Pending;
ROADMAP plan checkboxes `[ ]`; audit `status: gaps_found`); 103-01 will write
the surgical diffs that flip them. 103-02 reruns the named bundle and rewrites
`v1.22-MILESTONE-AUDIT.md` in place to a closeout-ready verdict.

The single intentional deviation from Phase 94 is scope: Phase 103 reconciles
**four** authority surfaces (ROADMAP, REQUIREMENTS, STATE, PROJECT) rather
than five, because `guides/how-threadline-works.md` already frames the
evidence plane correctly on the current tree (line 30: *"The evidence plane
stays just as narrow…"*). No stale-narrative patch is needed — verified.

**Primary recommendation:** Reuse Phase 94 plan/verification/validation
shapes verbatim. Replace v1.21 strings with v1.22, replace the support-lane
test bundle with the evidence-plane test bundle (already named verbatim at
lines 142-145 of the existing audit), and write 103-01 as four surgical
authority-surface diffs while 103-02 reruns the bundle and rewrites the
audit in place.

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** 103-01 reconciles exactly four authority surfaces:
  `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`,
  and the v1.22 remaining-work / next-step sections of `.planning/PROJECT.md`
  (matches Phase 94's exact pattern + D-16: "STATE.md and the current-state
  sections of PROJECT.md should move in the same pass as the audit rerun").
- **D-02:** 103-01 MUST NOT touch `.planning/MILESTONE-ARC.md`, the
  `.planning/PROJECT.md` "Last shipped: v1.21" framing line and the "Current
  milestone: v1.22 ... opened 2026-05-25" framing, `.planning/MILESTONES.md`,
  `.planning/RETROSPECTIVE.md`, or `.planning/milestones/v1.22-*` archive
  copies (none exist yet). Phase 94 git precedent: commit `140a5c2 chore:
  archive v1.21 milestone files` flipped the "Last shipped" pointer **after**
  Phase 94 closed.
- **D-03:** `.planning/REQUIREMENTS.md`:
  - Flip SURF-01/02/03 bullet checkboxes from `[ ]` to `[x]` (lines 22-24)
  - Update Traceability table SURF rows from `Pending` to `Complete`
    (lines 60-62); PROOF-01 row is already Complete — reconfirm
  - Update the `Last updated:` footer line (line 75) to today's date with a
    short "after Phase 103 reconciled the SURF closure chain" note
- **D-04:** `.planning/ROADMAP.md`: flip Phase 103 plan checkboxes 103-01 and
  103-02 to `[x]` (lines 128-129). No other ROADMAP edits.
- **D-05:** `.planning/STATE.md`:
  - yaml `completed_phases: 8 → 9`, `completed_plans: 16 → 16` (already at 16
    per state file; see Locked Facts §3), `percent: 89 → 100` once 103-02 closes
  - Update `last_activity` to today + Phase 103 closure summary
  - Update `## Current Position` from "Phase 102 complete" to "Phase 103
    complete; v1.22 closeout-ready"
  - Update `## Performance Metrics` from "8 of 12 satisfied" to "12 of 12
    satisfied" and remove the "PROOF-01, SURF-01, SURF-02, and SURF-03 remain
    pending" clause
  - Update `## Performance Metrics` `Milestone Readiness:` from "OPEN. v1.22
    now depends on Phases 101-103..." to "CLOSEOUT-READY. v1.22 cleared its
    final audit on `[date]` against the reconciled tree"
  - Append three `### Decisions` entries (Phases 100, 101, 102) plus one
    closing entry for Phase 103 itself
  - Update `## Session Continuity` `Next Step:` to "Run
    `/gsd-complete-milestone v1.22`"
  - Update `## Operator Next Steps` to "Run `/gsd-complete-milestone v1.22`
    to archive the v1.22 milestone"
- **D-06:** `.planning/PROJECT.md` narrow narrative pass only:
  - Update any sentence under `## Current State` that still implies v1.22 work
    is in flight to reflect closeout-ready status
  - Do **NOT** rewrite "Last shipped: v1.21", do **NOT** add "Last shipped:
    v1.22", do **NOT** touch "Latest Milestone Shipped" section
  - Smallest possible diff
- **D-07:** Phase 103-02 rewrites `.planning/v1.22-MILESTONE-AUDIT.md` in
  place with the rerun verdict (one canonical file per milestone — matches
  every prior milestone audit). Historical 2026-05-26 snapshot is preserved
  at git SHA precision via `git show HEAD~:.planning/v1.22-MILESTONE-AUDIT.md`.
- **D-08:** Rewritten audit yaml deltas:
  - `status: gaps_found → status: <PASS verdict>` (verify the actual literal
    at runtime via `gsd-audit-milestone` — see §6 below for what the tool
    actually emits)
  - `scores.requirements: 5/12 → 12/12`
  - `scores.phases: 2/5 → 5/5` (or 9/9 — verify tool behavior)
  - `gaps.requirements: [...] → []`
  - `tech_debt.milestone-surfaces` row removed
  - `tech_debt` for 97-VALIDATION nyquist follow-up and 98-VALIDATION nyquist
    follow-up: removed only if those VALIDATION files actually flipped to
    `nyquist_compliant: true` on disk — see Locked Facts §5 (98 flipped, 97
    did NOT)
  - `nyquist.compliant_phases` / `partial_phases` re-derived from on-disk
    VALIDATION frontmatter (see §5 below)
  - "Verified locally on `[date]`" stanza updated with 103-02 rerun counts
- **D-09:** Recommendation section flips to closeout-ready: "v1.22 is ready
  for `/gsd-complete-milestone v1.22`."
- **D-10:** Authoritative closeout-readiness bundle is the three-command set
  the existing audit body already names at lines 142-145:
  ```
  mix verify.doc_contract                                         # baseline: 46 tests / 0 failures
  mix test test/threadline/evidence_test.exs \                    # baseline: 55 tests / 0 failures
           test/threadline/evidence/proof_test.exs \
           test/mix/tasks/threadline.evidence_show_test.exs \
           test/threadline/operator_surface/live/evidence_live_test.exs \
           test/threadline/operator_surface/auth_test.exs \
           --max-failures 1
  mix verify.example                                              # baseline: 21 tests / 0 failures
  ```
  If 103-02's rerun produces different counts, the artifact records actual
  counts; only a regression (failures > 0 or visibly-broken seam) is a
  closeout blocker.
- **D-11:** After the three-command bundle passes, rerun `gsd-audit-milestone`
  and capture the new verdict per D-07/D-08.
- **D-12:** `mix ci.all` is NOT the closeout authority (Phase 99 D-15).
- **D-13:** Bundle stays as a named-command set inside the audit body and
  `103-02-PLAN.md`. Do NOT promote to a `mix verify.closeout` alias.
- **D-14:** Phase 103 produces its own `103-VERIFICATION.md` and
  `103-VALIDATION.md` to Phase-94 shape, with frontmatter `closeout_readiness:
  green | yellow | red`.
- **D-15:** If 103-02 rerun does NOT come back closeout-ready (NEW gap surfaced
  that Phases 100/101/102 didn't close), Phase 103 stops in place and records
  the finding with `closeout_readiness: red` or `yellow`. Do NOT widen scope
  to fix newly-found gap inline — that's a hypothetical Phase 104.
- **D-16:** Phase 103 MUST NOT modify `lib/`, `test/`, `mix.exs`, `mix.lock`,
  `guides/`, `examples/`, `priv/`, or anything outside `.planning/`. Boundary
  is `.planning/` only.

### Claude's Discretion

- Exact order in which 103-01 edits the four authority surfaces (as long as
  final state is internally consistent and commit history is readable)
- Exact wording of per-phase `### Decisions` entries appended to STATE.md
  (one each for Phases 100/101/102/103), matching existing Phase 90-94 entry
  shape
- Exact wording of closeout-ready Recommendation in rewritten audit, as long
  as it names `/gsd-complete-milestone v1.22` as the next gate and does not
  declare v1.22 "shipped"
- Whether to commit 103-01 and 103-02 as a single combined commit per plan
  (Phase 94 used per-plan commits; default is one commit per plan summary)
- Whether `103-VERIFICATION.md` cites each closeout-bundle command as a
  separate evidence band or one combined band (actual counts + exit codes
  must be recorded verbatim either way)

### Deferred Ideas (OUT OF SCOPE)

- **`/gsd-complete-milestone v1.22` (next gate, not this phase).** Owns:
  MILESTONE-ARC v1.22 row flip from "active" to "shipped"; PROJECT.md "Last
  shipped" pointer flip from v1.21 to v1.22; creation of
  `.planning/milestones/v1.22-REQUIREMENTS.md` / `v1.22-ROADMAP.md` /
  `v1.22-MILESTONE-AUDIT.md` archive copies; whatever RETROSPECTIVE.md /
  MILESTONES.md updates the archival workflow produces.
- **Potential Phase 104 (only if 103-02 audit rerun surfaces a new gap).**
  Per D-15.
- **`mix verify.closeout` alias.** Considered and rejected (D-13).

## Phase Requirements

Init JSON `phase_req_ids: null` — Phase 103 is a closeout-readiness gate,
not a requirement-bearing phase. The CONTEXT decisions D-01..D-16 are the
planner's working contract; no REQUIREMENTS.md IDs map directly to Phase 103
tasks. (Phase 103's success closes the SURF-01/02/03 traceability rows that
Phase 102 verified but that REQUIREMENTS.md has not yet flipped.)

## Locked Facts (Surgical Diff Inputs)

The planner needs exact text to write surgical before→after diffs. Locking
all of it here so the planner does not need to re-read the source files.

### 1. `.planning/ROADMAP.md` — Phase 103 plan checkboxes

**Current state, lines 128-129 (verified):**
```
- [ ] 103-01: Reconcile ROADMAP.md, REQUIREMENTS.md, and STATE.md with the repaired v1.22 closure state
- [ ] 103-02: Re-run milestone verification and audit for v1.22 closeout readiness
```

**Target state (103-01 final write):**
```
- [x] 103-01: Reconcile ROADMAP.md, REQUIREMENTS.md, and STATE.md with the repaired v1.22 closure state
- [x] 103-02: Re-run milestone verification and audit for v1.22 closeout readiness
```

Phase 100/101/102 checkboxes are already `[x][x]` (lines 96-97, 107-108,
118-119). The ROADMAP narrative around lines 121-129 already describes
Phase 103 correctly — no narrative edits.

File length: 155 lines.

### 2. `.planning/REQUIREMENTS.md` — SURF closure

**Current state, lines 22-24 (verified):**
```
- [ ] **SURF-01**: Read-only evidence views live on the existing `/audit` surface rather than a new operator UI family.
- [ ] **SURF-02**: Mounted evidence views show the same evidence facts and boundary language as the library API and Mix-task paths.
- [ ] **SURF-03**: Host-owned authorization remains the gate for mounted evidence views; Threadline does not introduce RBAC or tenant DSL semantics.
```

**Target state:** flip the three `[ ]` to `[x]`. Bullet bodies stay verbatim.

**Current Traceability table, lines 60-62 (verified):**
```
| SURF-01 | Phase 102 | Pending |
| SURF-02 | Phase 102 | Pending |
| SURF-03 | Phase 102 | Pending |
```

**Target state:** flip `Pending` to `Complete` in all three rows.

**Current footer, line 75 (verified):**
```
*Last updated: 2026-05-26 after the v1.22 milestone audit added gap-closure phases*
```

**Target state (suggested wording — D-03 leaves wording to discretion):**
```
*Last updated: 2026-05-27 after Phase 103 reconciled the SURF closure chain*
```

Note: PROOF-01 row at line 57 is already `Complete`. PROOF-01 bullet
at line 16 is already `[x]`. EVID-01/02/03 (lines 10-12, table lines 54-56)
already match the closed state. No edits needed for any non-SURF row.

File length: 75 lines.

### 3. `.planning/STATE.md` — full diff set (the heaviest surface)

**Current yaml header (verified, lines 1-14):**
```yaml
---
gsd_state_version: 1.0
milestone: v1.22
milestone_name: Policy / Evidence Plane
status: completed
last_updated: "2026-05-27T09:46:54.946Z"
last_activity: 2026-05-27 -- Phase 102 verified PASS; SURF-01/02/03 evidence chain closed (REQUIREMENTS still Pending per D-19, Phase 103 scope)
progress:
  total_phases: 9
  completed_phases: 8
  total_plans: 16
  completed_plans: 16
  percent: 89
---
```

**Note on D-05 numbers:** D-05 (CONTEXT) says "completed_phases: 7 → 9,
completed_plans: 14 → 16, percent: 78 → 100". Current on-disk state has
already advanced past D-05's assumed starting values — `completed_phases: 8`,
`completed_plans: 16`, `percent: 89`. This means:
- 103-01 may write an interim state (`completed_phases: 8 → 9` after 103-01,
  but `completed_plans` does NOT yet count 103's plans until 103-02 closes
  them — or 103-01 leaves the counts untouched and 103-02 flips everything
  in one final write).
- 103-02 final target: `completed_phases: 9`, `completed_plans: 18`,
  `percent: 100` (assuming the gsd-sdk includes 103-01 and 103-02 in the
  total_plans count once they ship; `total_plans` itself may need to grow
  from 16 to 18 — verify against the gsd state-update tool's actual
  behavior, since `total_phases: 9` already includes Phase 103 but
  `total_plans: 16` does not yet count 103's two plans).
- `status: completed` field is already set (this is the YAML key, NOT the
  textual milestone-completion status). Do NOT confuse this with the audit's
  `status: gaps_found` field — they are independent.

**Current `## Current Position` (verified, lines 24-28):**
```
Phase: 102 — phase-98-verification-backfill (COMPLETE)
Plan: 2 of 2 complete; verifier PASS 9/9
Status: Phase 102 complete; next is Phase 103 (Authority-Surface Reconciliation And Milestone Re-Audit)
Last activity: 2026-05-27 -- Phase 102 verified PASS; SURF-01/02/03 evidence chain closed (REQUIREMENTS still Pending per D-19, Phase 103 scope)
```

**Target `## Current Position` (after 103-02 PASS):**
```
Phase: 103 — authority-surface-reconciliation-and-milestone-re-audit (COMPLETE)
Plan: 2 of 2 complete; verifier PASS (closeout_readiness: green)
Status: Phase 103 complete; v1.22 closeout-ready
Last activity: 2026-05-27 -- Phase 103 reconciled the four authority surfaces and reran v1.22 milestone audit to closeout-ready verdict
```

**Current `## Performance Metrics` (verified, lines 30-36):**
```
- **Total Phases**: 9 (Phases 95-103) — defined in `.planning/ROADMAP.md`
- **Phases Completed**: 4 of 9 phases complete and 12 of 18 tracked plans complete for v1.22
- **Requirements Covered**: 8 of 12 satisfied for v1.22 (`EVID-01`, `EVID-02`, `EVID-03`, `PROOF-02`, `PROOF-03`, `DOC-01`, `DOC-02`, and `DOC-03`); `PROOF-01`, `SURF-01`, `SURF-02`, and `SURF-03` remain pending closure phases
- **Last Milestone**: v1.21 — Scoped Support / Operator Proof (shipped 2026-05-25)
- **Milestone Readiness**: OPEN. v1.22 now depends on Phases 101-103 to repair the remaining verification artifacts and stale authority surfaces before closeout.
```

> Note: "Phases Completed: 4 of 9" is a stale aggregate; on the current tree
> Phases 95/96/97/98/99/100/101/102 are all complete (8 of 9). The 103-02
> rewrite should reconcile this number to 9 of 9 once Phase 103 closes.

**Target `## Performance Metrics` (after 103-02 PASS):**
```
- **Total Phases**: 9 (Phases 95-103) — defined in `.planning/ROADMAP.md`
- **Phases Completed**: 9 of 9 phases complete and 18 of 18 tracked plans complete for v1.22
- **Requirements Covered**: 12 of 12 satisfied for v1.22 (`EVID-01`, `EVID-02`, `EVID-03`, `PROOF-01`, `PROOF-02`, `PROOF-03`, `SURF-01`, `SURF-02`, `SURF-03`, `DOC-01`, `DOC-02`, and `DOC-03`)
- **Last Milestone**: v1.21 — Scoped Support / Operator Proof (shipped 2026-05-25)
- **Milestone Readiness**: CLOSEOUT-READY. v1.22 cleared its final audit on 2026-05-27 against the reconciled tree.
```

**Current `## Session Continuity` (verified, lines 79-82):**
```
- **Last Action**: Closed the missing Phase 95 verification and validation chain by creating `95-VERIFICATION.md` and finalizing `95-VALIDATION.md` on the current tree.
- **Next Step**: Run `/gsd-plan-phase 101`, then backfill `96-VERIFICATION.md` on the current tree.
```

(Note: this section is also stale — it still describes the Phase 100 close,
not the Phase 102 close. 103-02 should reconcile.)

**Target `## Session Continuity`:**
```
- **Last Action**: Closed Phase 103 by reconciling the four v1.22 authority surfaces (ROADMAP/REQUIREMENTS/STATE/PROJECT) and rerunning the v1.22 milestone audit to closeout-ready against the reconciled tree.
- **Next Step**: Run `/gsd-complete-milestone v1.22`.
```

**Current `## Operator Next Steps` (verified, line 95):**
```
- Run /gsd-plan-phase 101 to start the Phase 96 verification backfill, then work forward through Phases 102-103
```

**Target `## Operator Next Steps`:**
```
- Run /gsd-complete-milestone v1.22 to archive the v1.22 milestone
```

**Decisions log — append 4 new entries.** Existing pattern (verified against
lines 61-65, which Phase 94 used for 90/91/92/93/94):
```
- 2026-05-25: Phase 90 backfilled the missing Phase 85 verification chain, ...
- 2026-05-25: Phase 91 backfilled the missing Phase 86 verification chain, ...
- 2026-05-25: Phase 92 backfilled the missing Phase 87 verification chain, ...
- 2026-05-25: Phase 93 backfilled the missing Phase 88 verification chain, ...
- 2026-05-25: Phase 94 reran `mix verify.doc_contract`, `mix verify.example`, and the targeted root support-lane suite; ...
```

**Target — append 4 entries after current last decision (line 69):**
Suggested wording (D-05 leaves wording to discretion):
```
- 2026-05-26: Phase 100 backfilled the missing Phase 95 verification chain, created `95-VERIFICATION.md` and finalized `95-VALIDATION.md`, and closed `EVID-01`, `EVID-02`, and `EVID-03` against the current-tree evidence-model contract.
- 2026-05-27: Phase 101 backfilled the missing Phase 96 verification chain, created `96-VERIFICATION.md` and finalized `96-VALIDATION.md`, and closed `PROOF-01` against the current-tree public evidence write/read API.
- 2026-05-27: Phase 102 backfilled the missing Phase 98 verification chain, created `98-VERIFICATION.md` and finalized `98-VALIDATION.md`, and closed `SURF-01`, `SURF-02`, and `SURF-03` against the current-tree mounted `/audit/evidence` lane and fail-closed authorization gate.
- 2026-05-27: Phase 103 reconciled the four v1.22 authority surfaces (ROADMAP, REQUIREMENTS, STATE, PROJECT current-state narrative) with the Phase 100/101/102 closure chain, reran the named v1.22 closeout bundle, and rewrote `v1.22-MILESTONE-AUDIT.md` to a closeout-ready verdict against the reconciled tree.
```

File length: 95 lines.

### 4. `.planning/PROJECT.md` — narrative pass only (D-06)

**Locked: do NOT touch (per D-02):**
- Line 13: `**Last shipped:** v1.21 — Scoped Support / Operator Proof (closed 2026-05-25)`
- Line 14: `**Current milestone:** v1.22 — Policy / Evidence Plane (opened 2026-05-25).`
- Line 28 onward: entire `## Latest Milestone Shipped: v1.21 Scoped Support / Operator Proof` section

**The one sentence that needs to move (verified, line 26):**
```
**Current planning focus:** Ship durable policy/evidence records and audit-of-audit proof without widening Threadline into a Threadline-owned compliance platform, auth model, or tenancy model.
```

This phrasing implies v1.22 work is still in flight ("Ship..."). Smallest
truthful diff: change the verb tense to indicate the work is now proven and
ready for archival, without claiming "shipped" (that's `/gsd-complete-milestone`'s
job).

**Target wording (suggested — D-06 leaves wording to discretion):**
```
**Current planning focus:** v1.22 evidence-plane work (durable policy/evidence records and audit-of-audit proof) is closeout-ready on the current tree; the next gate is `/gsd-complete-milestone v1.22`. The active boundary remains: no widening into a Threadline-owned compliance platform, auth model, or tenancy model.
```

**Last-updated footer (verified, line 327):**
```
*Last updated: 2026-05-25 — Opened v1.22 Policy / Evidence Plane from the milestone arc and reset the active planning surface.*
```

**Target footer:**
```
*Last updated: 2026-05-27 — Phase 103 reconciled the v1.22 current-state narrative with the closeout-ready milestone audit.*
```

No other narrative edits needed. The Key Decisions table row at line 305
(*"v1.22 will ship a narrow evidence plane, not a compliance platform"* —
status `— Active (opened 2026-05-25)`) deserves a minor status update too,
but it's borderline whether D-02 covers it. **Recommended:** leave it as
`Active` until `/gsd-complete-milestone v1.22` flips it to ✓ Shipped. The
"Current planning focus" sentence carries the closeout-ready signal cleanly
without contradicting the line-305 row.

File length: 327 lines.

### 5. `.planning/v1.22-MILESTONE-AUDIT.md` — current full body

**Current yaml frontmatter (verified, lines 1-85):**
- `status: gaps_found`
- `scores.requirements: 5/12`
- `scores.phases: 2/5` (verification files found: 2/5)
- `scores.integration: 3/3`, `scores.flows: 3/3` (already green)
- `gaps.requirements:` 7 entries (EVID-01/02/03, PROOF-01, SURF-01/02/03)
- `gaps.integration: []`, `gaps.flows: []`
- `tech_debt:` 5 entries with structured `phase` + `items`:
  - `phase: 96-evidence-persistence-and-public-api` (1 item, alias-drift)
  - `phase: 97-mix-task-and-machine-readable-proof` (1 item,
    97-VALIDATION nyquist follow-up)
  - `phase: 98-mounted-evidence-views-on-audit` (2 items, missing VERIFICATION
    + 98-VALIDATION nyquist follow-up)
  - `phase: 99-contract-lock-docs-and-final-verification` (1 item,
    `mix ci.all` repo-health follow-up)
  - `phase: milestone-surfaces` (1 item, stale authority surfaces)
- `nyquist.compliant_phases: ["96", "99"]`
- `nyquist.partial_phases: ["95", "97", "98"]`
- `nyquist.missing_phases: []`
- `nyquist.overall: "partial"`

**Current body sections (verified, lines 87-190):**
- `# Milestone v1.22 Audit`
- `## Verdict` (lines 89-97): Status: gaps_found, then 2-paragraph explanation
- `## Scope Audited` (lines 98-104)
- `## Requirements Coverage` (lines 106-123): 12-row table; "Score: 5/12
  satisfied, 7/12 partial, 0 orphaned"
- `## Phase Verification Status` (lines 125-135)
- `## Cross-Phase Integration` (lines 137-153): includes "Verified locally on
  2026-05-26:" with the 3-command bundle at **lines 142-145** (D-10 anchor)
  and 4 seam rows
- `## End-to-End Flows` (lines 155-163)
- `## Nyquist Coverage` (lines 165-173): 5-row table
- `## Key Gaps` (lines 175-179)
- `## Recommendation` (lines 181-190): "Do not archive v1.22 yet" + 4-step list

**Lines 142-145 (the verbatim D-10 bundle — must stay structurally in the
rewrite, though counts may shift):**
```
- `mix verify.doc_contract` -> PASS (`46 tests, 0 failures`)
- `MIX_ENV=test mix test test/threadline/evidence_test.exs test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/auth_test.exs --max-failures 1` -> PASS (`55 tests, 0 failures`)
- `mix verify.example` -> PASS (`21 tests, 0 failures`)
```

**Tech-debt rows the planner will need to remove or update per D-08:**

| Row | D-08 Disposition | Verification |
|-----|------------------|--------------|
| `97-mix-task-and-machine-readable-proof` (97-VALIDATION nyquist follow-up) | **KEEP** | 97-VALIDATION frontmatter on disk still `nyquist_compliant: false` — verified |
| `98-mounted-evidence-views-on-audit` items (missing 98-VERIFICATION + 98-VALIDATION nyquist) | **REMOVE** | 98-VERIFICATION now exists (Phase 102 created it); 98-VALIDATION now `nyquist_compliant: true` — verified |
| `99-contract-lock-docs-and-final-verification` (`mix ci.all` red on format) | **KEEP** unless Phase 103-02 confirms otherwise at runtime | Out of 103 scope per D-12 |
| `96-evidence-persistence-and-public-api` (pre-existing `mix verify.test` alias-drift) | **KEEP** unless 103-02 confirms it's resolved | Phase 96 ownership |
| `milestone-surfaces` | **REMOVE** | Phase 103-01 closes this |

File length: 190 lines.

File length will increase post-rewrite (new history-preserving prose can
explain the supersession in line with prior milestone audits — see v1.21
archived audit: 122 lines; v1.20: ~80 lines; both shorter than the current
v1.22 gaps_found audit at 190 lines).

### 6. Baseline test counts (D-10 bundle)

**Verified by `grep -c "^  test "` against test files (top-level `test/2`
defs only, not counting `describe`-nested or property-based defs):**

| File | Tests | Notes |
|------|------:|-------|
| `test/threadline/evidence_test.exs` | 9 | |
| `test/threadline/evidence/proof_test.exs` | 5 | |
| `test/mix/tasks/threadline.evidence_show_test.exs` | 7 | |
| `test/threadline/operator_surface/live/evidence_live_test.exs` | 5 | |
| `test/threadline/operator_surface/auth_test.exs` | 29 | |
| **Total** | **55** | Matches audit body line 144 baseline exactly |

The `mix verify.doc_contract` baseline (46 tests) and `mix verify.example`
baseline (21 tests) are alias-driven and not directly inspectable by counting
top-level `test/2` defs; per D-10, the 103-02 rerun records actual counts.
Only regression (failures > 0) is a closeout blocker.

### 7. Nyquist VALIDATION state on disk (D-08 disposition)

**Verified frontmatter values:**

| File | `status:` | `nyquist_compliant:` | `wave_0_complete:` |
|------|-----------|---------------------|---------------------|
| `95-VALIDATION.md` | `validated` | **`true`** | `true` |
| `96-VALIDATION.md` | `validated` | **`true`** | `true` |
| `97-VALIDATION.md` | `draft` | **`false`** | `false` |
| `98-VALIDATION.md` | `validated` | **`true`** | `true` |
| `99-VALIDATION.md` | (not checked — already `compliant` per current audit) | — | — |
| `100-VALIDATION.md` | `draft` | `false` | `true` |
| `101-VALIDATION.md` | `draft` | `false` | `false` |
| `102-VALIDATION.md` | `draft` | `false` | `false` |

**Implication for D-08:**
- Canonical phase artifacts that the milestone audit cares about: 95, 96, 97,
  98, 99 (the original v1.22 phases). The audit rewrite's
  `nyquist.compliant_phases` should be re-derived from these five.
- **Expected post-rewrite Nyquist:**
  - `compliant_phases: ["95", "96", "98", "99"]` (was `["96", "99"]`)
  - `partial_phases: ["97"]` (was `["95", "97", "98"]`)
  - `missing_phases: []`
  - `overall: "partial"` (was `"partial"` — stays partial because Phase 97
    still has `nyquist_compliant: false`)
- 100/101/102's own VALIDATION files are draft, but those are the
  *backfill phases*, not original milestone phases. Whether
  `gsd-audit-milestone` includes them depends on whether the tool's
  phase-scope logic (workflow §1, §5.5) counts them in Nyquist. **Verify at
  runtime.**
- 97-VALIDATION's `nyquist_compliant: false` is NOT a closeout blocker
  (Phase 97 has VERIFICATION passed; only the Nyquist bookkeeping is open).
  The post-rewrite audit should still surface it under `tech_debt` per the
  v1.21 precedent for plan-level VALIDATION drift (v1.21 archived audit
  preserved 90/91 plan-level draft frontmatter as non-blocking tech debt).

### 8. Boundary verification (D-02, D-16) — what 103 must NOT touch

**Verified current state of off-limits surfaces:**

| Surface | Current State | Off-Limits? |
|---------|---------------|-------------|
| `.planning/MILESTONE-ARC.md` v1.22 row | `active` (line 34 of MILESTONE-ARC.md: `\| v1.22 \| **active** \| Policy / Evidence Plane \| ...`) | YES — flipping to "shipped" is `/gsd-complete-milestone`'s job |
| `.planning/PROJECT.md` "Last shipped: v1.21" (line 13) | present, untouched | YES (D-02) |
| `.planning/PROJECT.md` "Latest Milestone Shipped" section | present, untouched (lines 28-46) | YES (D-02) |
| `.planning/MILESTONES.md` | present (39669 bytes, last modified 2026-05-25, last commit `140a5c2 chore: archive v1.21 milestone files`); top entry is "v1.21 — Scoped Support / Operator Proof (shipped 2026-05-25)" | YES (D-02) |
| `.planning/RETROSPECTIVE.md` | present (25202 bytes, last modified 2026-05-25, last commit `140a5c2`) | YES (D-02) |
| `.planning/milestones/v1.22-*` | NONE — verified (`ls .planning/milestones/ \| grep "^v1\.22"` returns empty) | YES — creation is `/gsd-complete-milestone`'s job |
| `lib/`, `test/`, `mix.exs`, `mix.lock`, `guides/`, `examples/`, `priv/` | not touched in this phase | YES (D-16) |

The verification report (103-VERIFICATION.md) should explicitly cite each
off-limits surface and state "intentionally NOT touched" per D-14.

### 9. Phase 94 deviation — guides/how-threadline-works.md is NOT needed (D-01 footnote)

**Verified:** `guides/how-threadline-works.md` already contains current-tree
evidence-plane framing:
- Line 30: `"The evidence plane stays just as narrow. Threadline may persist evidence about..."`
- Line 34: `"Canonical public non-goals for the evidence plane:"`
- Line 80: `"It does not answer ownership or policy questions on its own."`
- Lines 116 + 189: cross-links to `mix threadline.policy.show`

The Phase 94 D-19 "narrow patch to guides/how-threadline-works.md where it
still presents already-shipped governance/export capabilities as future
work" has already been applied (Phase 94 fixed the retention/exports
framing) AND the guide already has v1.22-correct evidence-plane framing
on disk. **No patch needed in Phase 103.** This is the canonical
deviation from the Phase 94 precedent.

The four-surface count is therefore correct: ROADMAP, REQUIREMENTS, STATE,
PROJECT narrative. NOT five.

## Architectural Responsibility Map

Phase 103 is `.planning/`-only and has no application-tier work. The
"architectural" map for this phase is the **planning-surface authority
hierarchy** (Phase 94 D-01..D-07; cross-applies here):

| Capability | Primary Surface | Secondary Surface | Rationale |
|------------|----------------|-------------------|-----------|
| Active milestone contract | `.planning/ROADMAP.md` | — | What v1.22 claims; Phase 103 closeout is part of that contract |
| Closeout gate | `.planning/v1.22-MILESTONE-AUDIT.md` | — | Decides whether the current-tree proof is sufficient |
| Execution snapshot | `.planning/STATE.md` | — | Records where the milestone run currently stands |
| Narrative / product framing | `.planning/PROJECT.md` (Current State section only) | — | Must not contradict the audit verdict or state snapshot |
| Requirement traceability | `.planning/REQUIREMENTS.md` | — | SURF row closure flips here |
| Milestone arc / next-milestone planning | `.planning/MILESTONE-ARC.md` | — | OFF-LIMITS in Phase 103 (D-02) — owned by `/gsd-complete-milestone` |
| Shipped-milestone history | `.planning/MILESTONES.md`, `.planning/RETROSPECTIVE.md` | — | OFF-LIMITS in Phase 103 (D-02) — owned by `/gsd-complete-milestone` |
| Milestone archive copies | `.planning/milestones/v1.22-*` | — | OFF-LIMITS — created by `/gsd-complete-milestone v1.22` |
| Phase-execution evidence | `.planning/phases/103-*/103-VERIFICATION.md`, `103-VALIDATION.md` | — | Phase 103 produces its own (D-14) |
| Closeout-readiness test bundle | three named commands in audit body (D-10) | — | Locked verbatim; do NOT promote to a `mix verify.closeout` alias (D-13) |

## Standard Stack

This phase has no library/framework stack. Tools used:

| Tool | Purpose | Source |
|------|---------|--------|
| `mix verify.doc_contract` | Public-doc literal lock; first command of D-10 bundle | Existing alias in `mix.exs` — Phase 99 D-14, used verbatim by Phase 94-02 |
| `mix verify.example` | Example-host integration proof; third command of D-10 bundle | Existing alias in `mix.exs` |
| `mix test ...` (verbatim 5-file list) | Evidence-plane seam proof; middle command of D-10 bundle | Verbatim from audit body line 144 |
| `gsd-audit-milestone` | Re-runs the v1.22 audit, rewrites `v1.22-MILESTONE-AUDIT.md` in place | `~/.claude/skills/gsd-audit-milestone/SKILL.md` + `~/.claude/get-shit-done/workflows/audit-milestone.md` |
| `gsd-sdk query init.milestone-op` | Workflow init for audit-milestone | Tool used internally by `gsd-audit-milestone` |
| `gsd-sdk query find-phase` | Resolves phase directories (handles archived phases) | Used internally by `gsd-audit-milestone` |
| `gsd-sdk query commit` | Standard per-plan commit pattern (Phase 94 precedent) | Available; one commit per plan summary |
| `rg` (ripgrep) | Acceptance-criteria verification greps in plan `<verify>` blocks | Phase 94 precedent |
| `git diff` | Boundary verification (e.g., `git status .planning/` shows only allowed paths) | Phase 102 T-102-08 precedent |

**No external packages installed. No `package legitimacy audit` section
needed (skipped — phase installs nothing).**

## Architecture Patterns

### System Architecture Diagram

```
                                                  ┌─────────────────────────────────────────┐
                                                  │ INPUT: Phase 100/101/102 evidence chain │
                                                  │  • 95-VERIFICATION.md (EVID-01/02/03)  │
                                                  │  • 96-VERIFICATION.md (PROOF-01)       │
                                                  │  • 98-VERIFICATION.md (SURF-01/02/03)  │
                                                  │  • 95-,96-,98-VALIDATION.md            │
                                                  │    all nyquist_compliant: true         │
                                                  └────────────────────┬───────────────────┘
                                                                       │
                                            ┌──────────────────────────┴─────────────────────────┐
                                            │                                                    │
                                            ▼                                                    ▼
       ┌──────────────────────────────────────────┐               ┌──────────────────────────────────────────┐
       │  103-01: Authority-surface reconciliation │               │   (Phase 103 boundary fence — D-02/D-16) │
       │  Four surgical diffs, in any order:        │               │   MUST NOT touch:                        │
       │   1. ROADMAP.md lines 128-129              │               │    • MILESTONE-ARC.md                    │
       │   2. REQUIREMENTS.md lines 22-24, 60-62, 75│               │    • PROJECT.md "Last shipped: v1.21"    │
       │   3. STATE.md yaml header, ## Current Pos, │               │    • MILESTONES.md                       │
       │      Performance Metrics, Decisions, Sess. │               │    • RETROSPECTIVE.md                    │
       │      Continuity, Operator Next Steps       │               │    • .planning/milestones/v1.22-*        │
       │   4. PROJECT.md "Current planning focus"   │               │    • lib/ test/ mix.exs guides/ examples │
       │      sentence + footer                     │               │      priv/                                │
       └──────────────────────┬───────────────────┘                 └──────────────────────────────────────────┘
                              │
                              ▼
       ┌──────────────────────────────────────────┐
       │  103-02: Bundle rerun + audit rewrite     │
       │   a. Run D-10 three-command bundle on     │
       │      the reconciled tree. Record counts.  │
       │   b. Invoke gsd-audit-milestone v1.22.    │
       │      Tool rewrites v1.22-MILESTONE-AUDIT  │
       │      .md in place.                        │
       │   c. Apply post-tool tweaks per D-08      │
       │      (preserve verbatim D-10 bundle, fix  │
       │      Recommendation per D-09, etc.)       │
       │   d. Write 103-VERIFICATION.md +          │
       │      103-VALIDATION.md to Phase-94 shape  │
       │      (closeout_readiness: green/yellow/red)│
       └──────────────────────┬───────────────────┘
                              │
                              ▼
       ┌──────────────────────────────────────────┐                ┌──────────────────────────────────────┐
       │  OUTPUT: v1.22 closeout-ready             │                │  NEXT GATE (not Phase 103):           │
       │   • v1.22-MILESTONE-AUDIT.md status flip  │ ──────────────▶│   /gsd-complete-milestone v1.22       │
       │     to closeout_ready / passed            │                │   (owns archive copies, Last shipped  │
       │   • Four authority surfaces agree on the  │                │    flip, MILESTONE-ARC flip,          │
       │     closure chain                          │                │    MILESTONES/RETROSPECTIVE          │
       │   • 103-VERIFICATION.md closeout_readiness│                │    updates)                          │
       │     = green                                │                └──────────────────────────────────────┘
       └──────────────────────────────────────────┘
```

### Recommended Phase 103 Directory Layout

Already on disk:
```
.planning/phases/103-authority-surface-reconciliation-and-milestone-re-audit/
├── 103-CONTEXT.md            (exists — locks D-01..D-16 + canonical_refs)
├── 103-DISCUSSION-LOG.md     (exists)
└── 103-RESEARCH.md           (this file)
```

Planner will add (Phase 94 precedent shape):
```
├── 103-01-PLAN.md            ← Phase 94 shape: type=execute, wave=1, depends_on=[]
├── 103-01-SUMMARY.md         ← written by execute-phase
├── 103-02-PLAN.md            ← Phase 94 shape: type=execute, wave=2, depends_on=["01"]
├── 103-02-SUMMARY.md         ← written by execute-phase
├── 103-VERIFICATION.md       ← Phase 94 shape: frontmatter closeout_readiness
└── 103-VALIDATION.md         ← Phase 94 shape: status=finalized, nyquist_compliant=true
```

### Pattern 1: Phase 94-shaped plan frontmatter

**What:** Reuse Phase 94's exact `<frontmatter>` shape for both plans.

**When to use:** Verbatim for 103-01 and 103-02.

**103-01 example (adapted from 94-01-PLAN.md lines 1-52):**
```yaml
---
phase: 103-authority-surface-reconciliation-and-milestone-re-audit
plan: "01"
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/ROADMAP.md
  - .planning/REQUIREMENTS.md
  - .planning/STATE.md
  - .planning/PROJECT.md
autonomous: true
requirements: []  # Phase 103 has no direct REQ-IDs; closes SURF row traceability via D-03
must_haves:
  truths:
    - "The four active v1.22 authority surfaces (ROADMAP, REQUIREMENTS, STATE, PROJECT narrative) now tell the same closure-chain story the Phase 100/101/102 evidence proves."
    - "Authority by concern stays explicit (D-01): ROADMAP = active contract; REQUIREMENTS = traceability ledger; STATE = execution snapshot; PROJECT current-state = narrative framing — none contradicts the verified phase artifacts."
    - "No Wave 1 change touches MILESTONE-ARC.md, the PROJECT 'Last shipped: v1.21' framing, MILESTONES.md, RETROSPECTIVE.md, or any .planning/milestones/v1.22-* archive copy. Those belong to /gsd-complete-milestone v1.22 (D-02)."
    - "No Wave 1 change widens Phase 103 into a doc/code/test surface (D-16). Boundary is .planning/ only."
  artifacts:
    - path: .planning/ROADMAP.md
      provides: "Active milestone contract with Phase 103 plan checkboxes flipped to [x]"
      contains: "Phase 103"
    - path: .planning/REQUIREMENTS.md
      provides: "Traceability ledger with SURF-01/02/03 closed against Phase 102"
      contains: "SURF-01"
    - path: .planning/STATE.md
      provides: "Execution snapshot aligned with Phase 103 closeout"
      contains: "v1.22 closeout-ready"
    - path: .planning/PROJECT.md
      provides: "Narrative current-state aligned with the closeout-ready milestone audit"
      contains: "closeout-ready"
  key_links:
    - from: .planning/REQUIREMENTS.md
      to: .planning/phases/102-phase-98-verification-backfill/102-VERIFICATION.md
      via: "SURF-01/02/03 closure must match the Phase 102 verifier PASS"
      pattern: "SURF-01|SURF-02|SURF-03"
    - from: .planning/STATE.md
      to: .planning/v1.22-MILESTONE-AUDIT.md
      via: "execution snapshot must set up the Wave 2 audit rerun on the reconciled tree"
      pattern: "Phase 103|closeout|v1.22"
    - from: .planning/PROJECT.md
      to: .planning/STATE.md
      via: "Current planning focus narrative must not contradict the Performance Metrics 12-of-12 satisfied count"
      pattern: "closeout-ready|12 of 12 satisfied"
---
```

**103-02 example (adapted from 94-02-PLAN.md lines 1-56):**
```yaml
---
phase: 103-authority-surface-reconciliation-and-milestone-re-audit
plan: "02"
type: execute
wave: 2
depends_on:
  - "01"
files_modified:
  - .planning/phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-VERIFICATION.md
  - .planning/phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-VALIDATION.md
  - .planning/v1.22-MILESTONE-AUDIT.md
  # Note: REQUIREMENTS.md / ROADMAP.md / STATE.md / PROJECT.md were already moved in 103-01;
  # 103-02 only writes them if the rerun reveals new truth. Per D-15, do NOT re-edit them
  # unless the audit rerun surfaces a new contradiction.
autonomous: true
requirements: []
must_haves:
  truths:
    - "Phase 103 closes only if the reconciled authority surfaces, named rerun proof, and rewritten milestone audit all agree on the same current-tree closeout story."
    - "The audit rewrite preserves the verbatim D-10 three-command bundle in the body (D-13) and records the actual rerun counts and exit codes."
    - "If the rerun proof or rewritten audit exposes a new contradiction, Phase 103 stops in place and records the gap with closeout_readiness: red or yellow (D-15). It must NOT widen scope to fix the gap inline."
    - "MILESTONE-ARC.md, PROJECT 'Last shipped: v1.21', MILESTONES.md, RETROSPECTIVE.md, and .planning/milestones/v1.22-* remain untouched. Those belong to /gsd-complete-milestone v1.22 (D-02)."
  artifacts:
    - path: .planning/phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-VERIFICATION.md
      provides: "Durable verification verdict for v1.22 closeout readiness with the four reconciled surfaces"
      contains: "closeout_readiness"
    - path: .planning/phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-VALIDATION.md
      provides: "Nyquist-compliant rerun ledger and command map for the final v1.22 closeout pass"
      contains: "Commands Actually Used"
    - path: .planning/v1.22-MILESTONE-AUDIT.md
      provides: "Refreshed milestone gate verdict against the reconciled tree; closeout-ready"
      contains: "v1.22 is ready for"
  key_links:
    - from: .planning/phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-VERIFICATION.md
      to: .planning/v1.22-MILESTONE-AUDIT.md
      via: "final phase verdict and milestone audit must describe the same readiness outcome"
      pattern: "closeout|ready|gaps"
    - from: .planning/phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-VALIDATION.md
      to: mix verify.doc_contract
      via: "named public-contract proof remains part of the closeout bundle"
      pattern: "mix verify\\.doc_contract"
    - from: .planning/phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-VALIDATION.md
      to: mix verify.example
      via: "named example-host proof remains part of the closeout bundle"
      pattern: "mix verify\\.example"
---
```

### Pattern 2: Per-task `<verify>` block automation

**What:** Each task's `<verify><automated>...</automated></verify>` block must
be runnable as-is by the executor. Use `rg` for grep checks; never use `cat
| grep`.

**When to use:** Every task in 103-01 and 103-02.

**Example for 103-01 ROADMAP task (verify checkboxes flipped):**
```xml
<verify>
  <automated>rg -n '\[x\] 103-01: Reconcile ROADMAP\.md, REQUIREMENTS\.md, and STATE\.md|\[x\] 103-02: Re-run milestone verification and audit for v1\.22' .planning/ROADMAP.md</automated>
</verify>
```

**Example for 103-01 boundary guard (verify nothing off-limits was touched):**
```xml
<verify>
  <automated>! rg -n 'Last shipped:.*v1\.22' .planning/PROJECT.md && ! git diff --name-only .planning/MILESTONE-ARC.md .planning/MILESTONES.md .planning/RETROSPECTIVE.md | grep -q .</automated>
</verify>
```

**Example for 103-02 bundle rerun:**
```xml
<verify>
  <automated>mix verify.doc_contract && mix test test/threadline/evidence_test.exs test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/auth_test.exs --max-failures 1 && mix verify.example</automated>
</verify>
```

### Pattern 3: STRIDE threat-model block (Phase 94 precedent)

Both Phase 94 plans included a `<threat_model>` block enumerating trust
boundaries and STRIDE threats. Reuse the shape verbatim with v1.22-specific
content:

**103-01 expected threats:**
- T-103-01 Tampering / False Closure (authority surfaces) — mitigate by
  anchoring all wording changes to the Phase 100/101/102 VERIFICATION
  artifacts
- T-103-02 Boundary Violation (touching off-limits surfaces) — mitigate by
  per-task `git diff` boundary guards (D-02, D-16)
- T-103-03 Scope Creep — mitigate by forbidding doc/code/test edits

**103-02 expected threats:**
- T-103-04 Repudiation (no command record) — mitigate by recording all
  rerun commands verbatim in 103-VERIFICATION.md `## Commands Actually Used`
- T-103-05 False Closure / Premature Archive — mitigate by gating
  closeout_readiness on the actual rerun bundle exit codes and only flipping
  authority-surface counts after the rerun passes
- T-103-06 Scope Creep into Repair (D-15) — mitigate by explicitly recording
  `closeout_readiness: red/yellow` and stopping in place if rerun surfaces
  new gaps

### Pattern 4: 103-VERIFICATION.md shape (Phase 94-VERIFICATION precedent)

Required frontmatter (verbatim Phase 94-VERIFICATION shape):
```yaml
---
phase: 103-authority-surface-reconciliation-and-milestone-re-audit
verified: <ISO-8601 timestamp>
status: verified
score: 3/3 evidence bands green   # OR 2/3, 1/3 etc.
closeout_readiness: green          # OR yellow, red (per D-15)
---
```

Required body sections (verbatim Phase 94-VERIFICATION shape):
- `# Phase 103: Authority Surface Reconciliation & Milestone Re-Audit — Verification Report`
- `**Phase Goal:**` (one-paragraph)
- `**Verified:**`, `**Status:**`, `**Re-verification:**` lines
- `## Final Verdict` with `**Closeout readiness:** GREEN` line + paragraphs
- `## Evidence Bands` (D-14): per-band PASS/FAIL with named commands and
  actual counts — D-14 leaves "separate band per command" vs "one combined
  band" to discretion
  - Band 1: Public Contract Rerun (`mix verify.doc_contract`)
  - Band 2: Evidence-plane seam rerun (5-file bundle)
  - Band 3: Example-Host Rerun (`mix verify.example`)
  - Band 4 (new — specific to 103): Authority Surface Reconciliation
    (diff summary of 103-01's four surface edits)
  - Band 5 (new — specific to 103): Milestone Audit Rewrite
    (diff summary of v1.22-MILESTONE-AUDIT.md before→after)
  - Band 6 (new — specific to 103): Boundary Verification (D-02 / D-16
    intentional non-touch statement)
- `## Commands Actually Used` with the verbatim command list + result counts
- `## Requirement Closure Outcome` for SURF-01/02/03 (closing requirements
  whose traceability flipped in 103-01)
- `## Phase Chain Confirmed` (v1.22 phases 95 → 99, plus 100/101/102, plus
  103)
- `## Not Claimed Beyond This Verdict` — explicit statement that v1.22 is
  closeout-ready but NOT yet shipped; that's `/gsd-complete-milestone`'s job
  (D-14)
- **NEW for 103 (per D-14):** `## Boundary Verification — Intentionally Not Touched`
  table listing MILESTONE-ARC.md, PROJECT "Last shipped", MILESTONES.md,
  RETROSPECTIVE.md, .planning/milestones/v1.22-* and naming
  `/gsd-complete-milestone v1.22` as the gate that owns them

### Pattern 5: 103-VALIDATION.md shape (Phase 94-VALIDATION precedent)

Required frontmatter:
```yaml
---
phase: 103
slug: authority-surface-reconciliation-and-milestone-re-audit
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
updated: <ISO-8601 timestamp>
---
```

Required sections (verbatim Phase 94-VALIDATION shape):
- `# Phase 103 — Validation Strategy` + intro paragraph
- `## Test Infrastructure` table (Framework, Config file, Quick run command,
  Named proof commands, Full closeout bundle, Artifact checks, Estimated
  runtime)
- `## Sampling Rate` bullets
- `## Per-Task Verification Map` table (Task ID, Requirement, Threat Ref,
  Secure Behavior, Test Type, Automated Command, Status)
- `## Requirement-to-Command Map` table (closes SURF rows; references
  verify.doc_contract, verify.example, and the 5-file middle bundle)
- `## Commands Actually Used` (numbered list with actual exit codes / test
  counts)
- `## Nyquist Notes` (carries forward the v1.21 lesson: rerun is compliant
  only if the audit and requirement closure are refreshed from the same
  proof bundle; closeout requirements stay open if any band turns red on a
  later tree; SUMMARY frontmatter is NOT authoritative for closure)
- `## Validation Sign-Off` checklist + `**Approval:** finalized on <date>`

### Anti-Patterns to Avoid

- **Promoting the D-10 bundle to a `mix verify.closeout` alias.** D-13
  explicitly rejects this. The middle command rotates per milestone.
- **Editing off-limits surfaces (D-02, D-16).** A grep / git-diff boundary
  guard is required on every plan.
- **Trying to widen Phase 103 to fix a newly-found gap inline (D-15).** If
  103-02 audit rerun surfaces something Phases 100/101/102 missed, stop in
  place, record `closeout_readiness: red/yellow`, and let the maintainer
  decide whether to open Phase 104.
- **Treating SUMMARY.md frontmatter as authoritative for requirement
  closure.** Phase 94 D-? and 94-VALIDATION explicitly disclaim this; only
  the rerun-backed VERIFICATION + the refreshed audit close requirements.
- **Declaring v1.22 "shipped" in the rewritten audit.** D-09 leaves
  recommendation wording to discretion, but explicitly forbids "shipped"
  framing — that's `/gsd-complete-milestone`'s job.
- **Confusing STATE.md yaml `status: completed` with the audit's `status:
  gaps_found`.** They are independent fields. The yaml `status` here means
  "the state file is in a completed/saved form," not "the milestone is
  done." Do NOT change the yaml `status` value.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Milestone audit rerun | Hand-author the new audit file | `gsd-audit-milestone` (D-11) | Tool re-derives the 3-source cross-reference (REQUIREMENTS table ↔ SUMMARY frontmatter ↔ VERIFICATION status) and Nyquist coverage automatically. Hand-authoring loses the discovery loop. |
| Phase init / phase-dir resolution | Hand-walk `.planning/phases/` glob | `gsd-sdk query init.phase-op 103` (returns phase_dir, padded_phase, etc.) | Already in use; consistent across all GSD workflows. |
| Closeout bundle alias | New `mix verify.closeout` alias | The verbatim D-10 three-command bundle | D-13 rejection; per-milestone test list rotates and would go stale. |
| 103-VERIFICATION.md shape | Invent new evidence-band schema | Reuse Phase 94-VERIFICATION.md verbatim shape | Phase 94 precedent works for v1.21 closeout; structurally identical for v1.22. |
| Decisions-log entries for STATE.md | Hand-invent format | Reuse the Phase 90/91/92/93/94 entry shape (dated, names closed requirements, one-line summary) | D-05 + Claude's Discretion section. |
| Commit pattern | Single bulk commit for both plans | Per-plan commit summary (Phase 94 precedent: `22c459d docs(94-01): complete authority surface reconciliation plan`, `e4ceda7 docs(94-02): record final v1.21 rerun evidence`, `32d187b docs(94-02): complete authority-surface-reconciliation-and-closeout plan`) | Discoverable git history; matches existing pattern. |

**Key insight:** Phase 103 is structurally a copy of Phase 94 with three
substitutions (v1.21 → v1.22; support-lane test bundle → evidence-plane
test bundle; five surfaces → four surfaces). Reinventing any of the artifact
shapes produces drift from a working precedent.

## Runtime State Inventory

> Phase 103 is `.planning/`-only authority reconciliation. The "rename" lens
> does not apply (no string is being renamed), but the equivalent question
> here is: **what runtime state on disk or in tools needs to be inspected to
> write the surgical diffs correctly?** All inventories below have already
> been completed in this research pass — the planner does NOT need to re-do
> them.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data (on disk, in .planning/)** | The five authority-surface files: `.planning/ROADMAP.md` (155 lines), `.planning/REQUIREMENTS.md` (75 lines), `.planning/STATE.md` (95 lines), `.planning/PROJECT.md` (327 lines), `.planning/v1.22-MILESTONE-AUDIT.md` (190 lines). Exact target lines locked in §§ 1-5 above. | Surgical diffs in 103-01 (four surfaces) + in-place rewrite in 103-02 (audit only). |
| **Live service config** | None. Phase 103 has no external service config (no n8n, no Datadog, no Tailscale, etc.) — this is a pure planning-tree phase. | None. |
| **OS-registered state** | None. No Task Scheduler / launchd / systemd / pm2 state references v1.22 or Phase 103. | None. |
| **Secrets / env vars** | None. Phase 103 reads no secrets and creates no env-var references. | None. |
| **Build artifacts / installed packages** | None. Phase 103 does not touch `mix.exs`, `mix.lock`, `deps/`, `_build/`, or any installed package. D-16 explicitly fences this. | None. |
| **Test artifacts** | The D-10 bundle's five test files (verified test-def counts: 9+5+7+5+29=55; matches audit baseline). Test files themselves are NOT modified by Phase 103 (D-16); only their pass/fail status is re-observed in 103-02. | 103-02 re-runs, does not modify. |
| **Frontmatter status on disk** | `95-VALIDATION.md` `nyquist_compliant: true`; `96-VALIDATION.md` `nyquist_compliant: true`; `97-VALIDATION.md` `nyquist_compliant: false`; `98-VALIDATION.md` `nyquist_compliant: true`; `100/101/102-VALIDATION.md` `nyquist_compliant: false` (backfill phases' own validation strategy, distinct from the canonical 95/96/98 artifacts they backfilled) | 103-02 rewritten audit's `nyquist` block re-derived from these (see §7 above). |

## Common Pitfalls

### Pitfall 1: Confusing STATE.md yaml `status: completed` with milestone closeout status

**What goes wrong:** A reader sees `status: completed` in the STATE.md yaml
header and assumes v1.22 is already shipped. The planner avoids editing the
yaml `status` field, thinking it's already correct.

**Why it happens:** The yaml `status` is a gsd-sdk state-file format field
meaning "STATE.md is in a saved/coherent form"; the audit `status:
gaps_found` is the milestone-closeout verdict. Same key name, different
semantics.

**How to avoid:** Treat the STATE.md yaml `status: completed` as
informational metadata that does NOT change in Phase 103. Only the
audit's `status` field flips (gaps_found → closeout_ready / passed).

**Warning signs:** If the planner's diff intends to edit STATE.md yaml
`status`, stop — that's almost certainly wrong.

### Pitfall 2: Editing PROJECT.md "Last shipped: v1.21" line

**What goes wrong:** Planner sees "Last shipped: v1.21" and assumes Phase 103
flips it to "Last shipped: v1.22" since Phase 103 is the v1.22 closeout.

**Why it happens:** Intuitive but wrong — `/gsd-complete-milestone v1.22`
owns this flip, not Phase 103 (D-02). Phase 94 precedent: commit `140a5c2
chore: archive v1.21 milestone files` is what flipped the "Last shipped"
pointer after Phase 94 closed.

**How to avoid:** Explicit per-task `<verify>` boundary guard:
`! rg -n 'Last shipped:.*v1\.22' .planning/PROJECT.md`

**Warning signs:** Any 103-01 task that touches lines 12-14 or 28-46 of
PROJECT.md is over-reaching.

### Pitfall 3: Audit rewrite loses the verbatim D-10 bundle anchor

**What goes wrong:** `gsd-audit-milestone` tool overwrites the body section
that contains the verbatim 3-command bundle (current audit lines 142-145).
Future reruns (Phase 104+) can no longer locate the anchor.

**Why it happens:** D-13 explicitly preserves the verbatim bundle inside
the audit body — but the tool may re-derive that section from its own
template, dropping the v1.22-specific test file list.

**How to avoid:** After running `gsd-audit-milestone v1.22`, verify the
3-command bundle still appears verbatim in the rewritten audit body. If
the tool overwrites it, manually restore (D-13: bundle stays inside the
audit body). Acceptance criterion: `rg -n 'evidence_test\.exs.*proof_test\.exs.*threadline\.evidence_show_test\.exs' .planning/v1.22-MILESTONE-AUDIT.md` should still match.

**Warning signs:** Post-tool audit body has only generic `mix test` references
without the v1.22-specific file list.

### Pitfall 4: 97-VALIDATION tech-debt row treated as a Phase 103 obligation

**What goes wrong:** Planner reads D-08 ("tech_debt rows ... removed only if
Phases 100/101/102 actually flipped those VALIDATION files") and concludes
Phase 103 should flip 97-VALIDATION.md to `nyquist_compliant: true`.

**Why it happens:** Phase 100/101/102 backfilled phases 95/96/98 but did NOT
touch Phase 97's VALIDATION (97 already had VERIFICATION passing, only
Nyquist bookkeeping was open). Phase 103-01 is scoped to four authority
surfaces (D-01) and 103-02 is the audit rerun. Neither owns Phase 97's
VALIDATION.

**How to avoid:** The 97-VALIDATION tech-debt row stays in the rewritten
audit. D-08 reads literally: "removed only if Phases 100/101/102 actually
flipped those VALIDATION files to `nyquist_compliant: true` on disk —
verify at runtime; if still draft, keep the rows". Verified: 97-VALIDATION
still `nyquist_compliant: false`. Therefore the row stays. The v1.21
audit's tech_debt entries for 90/91 plan-level VALIDATION drift are exact
precedent — those stayed too.

**Warning signs:** Any 103 plan task that lists `97-VALIDATION.md` in
`files_modified` is out of scope.

### Pitfall 5: Total_plans count drift in STATE.md yaml

**What goes wrong:** D-05 says `completed_plans: 14 → 16` but current STATE
shows `total_plans: 16` AND `completed_plans: 16`. Planner sees them already
equal and assumes no diff is needed.

**Why it happens:** STATE was advanced after the CONTEXT was written.
Current state already counts Phases 95-102's plans. Phase 103 will add 2
plans (103-01, 103-02). Final target: `total_plans: 18`, `completed_plans:
18`, `total_phases: 9`, `completed_phases: 9`, `percent: 100`.

**How to avoid:** Treat D-05 numbers as the *direction of change*, not the
exact starting values. Verify against the live yaml header at write time;
the gsd-sdk `state.update` tool will likely re-derive these from
`.planning/phases/` glob + ROADMAP.md, but if hand-editing, the target
values are 9/9 phases and 18/18 plans, 100%.

**Warning signs:** Final STATE.md percentages or counts don't math out
(`completed_phases ≠ total_phases` AND/OR `percent ≠ 100` AND/OR
`completed_plans ≠ total_plans`).

### Pitfall 6: Five-surface trap (Phase 94 → 103 deviation)

**What goes wrong:** Planner reuses Phase 94 verbatim and includes a
`guides/how-threadline-works.md` patch in 103-01, violating D-16's "no
guides/" boundary.

**Why it happens:** Phase 94 D-19 included a narrow guide patch; the
researcher must verify whether the equivalent v1.22 guide-state patch is
needed. **Verified in this research (§9):** guides/how-threadline-works.md
already contains evidence-plane framing — no patch needed.

**How to avoid:** Stick to D-01's four-surface scope. Per-task boundary
guard: `! git diff --name-only guides/ | grep -q .`

**Warning signs:** Any task in 103-01 with `guides/` in `files_modified`.

## Code Examples

### Example 1: Phase 94 commit pattern (apply verbatim to 103)

```bash
# After 103-01 task work, the planner's PLAN.md should specify per-plan commit:
gsd-sdk query commit "docs(103-01): complete authority surface reconciliation plan" \
  --files ".planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/STATE.md .planning/PROJECT.md .planning/phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-01-SUMMARY.md"

# After 103-02 task work:
gsd-sdk query commit "docs(103-02): record final v1.22 rerun evidence" \
  --files ".planning/v1.22-MILESTONE-AUDIT.md .planning/phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-VERIFICATION.md .planning/phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-VALIDATION.md"

gsd-sdk query commit "docs(103-02): complete authority-surface-reconciliation-and-milestone-re-audit plan" \
  --files ".planning/phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-02-SUMMARY.md .planning/STATE.md"
```

(Reference: `git log --oneline -- .planning/phases/94-*/` shows this exact
three-commit pattern.)

### Example 2: `gsd-audit-milestone` invocation

The skill (`~/.claude/skills/gsd-audit-milestone/SKILL.md`) declares it
takes an optional `[version]` argument and defaults to the current
milestone. The workflow (`~/.claude/get-shit-done/workflows/audit-milestone.md`)
shows it:

1. Calls `gsd-sdk query init.milestone-op` for context
2. Calls `gsd-sdk query phases.list` to identify phase directories
3. For each phase, calls `gsd-sdk query find-phase NN --raw` to resolve dirs
4. Reads each phase's `VERIFICATION.md` (status, gaps, requirements)
5. Spawns `gsd-integration-checker` Agent for cross-phase wiring
6. Cross-references REQUIREMENTS.md traceability ↔ SUMMARY frontmatter ↔
   VERIFICATION.md (3-source matrix from workflow §5)
7. Discovers Nyquist coverage from `*-VALIDATION.md` frontmatter (workflow §5.5)
8. **Writes** `.planning/v{version}-MILESTONE-AUDIT.md` with structured yaml
   frontmatter (`milestone`, `audited`, `status`, `scores`, `gaps`,
   `tech_debt`, `nyquist`) + full markdown report (workflow §6)

**Status values the tool emits (workflow §6):**
- `passed` — all requirements met, no critical gaps, minimal tech debt
- `gaps_found` — critical blockers exist
- `tech_debt` — no blockers but accumulated deferred items need review

**For Phase 103-02's purposes:** the expected output status after the
rerun is **`passed`** (since all 12 requirements close, no critical gaps
remain, and any residual tech debt — like 97-VALIDATION nyquist — is
non-blocking). D-08's question "or whatever the workflow's PASS verdict
is named" is now resolved: it's `status: passed` (not `closeout_ready`).
The `closeout_readiness: green` label is the **phase-verification** label
(used in 103-VERIFICATION.md frontmatter per D-14 / Phase 94 precedent),
NOT the milestone-audit label.

**The tool does not have a `closeout_ready` status enum value.** The
v1.21 archived audit (`milestone: v1.21, status: passed`) confirms this —
that's the post-Phase-94 rewrite shape.

**Tool writes the audit file directly** (workflow §6: "Create
`.planning/v{version}-MILESTONE-AUDIT.md`"). It does NOT print to stdout
for human piping. 103-02's plan should NOT include `> output.md`
redirection.

**Invocation from a planning task:** Per the workflow's design, the audit
tool is invoked from inside the GSD CLI orchestrator (as a workflow agent
or via a slash command equivalent), not as a direct shell command. The
plan should specify the invocation as the tool name plus argument; the
executor agent will know how to dispatch it. Phase 94-02 PLAN's Task 2
analogous step does not include a shell-form invocation — it lists
`.planning/v1.21-MILESTONE-AUDIT.md` in `files_modified` and treats the
audit rewrite as the action.

**Recommended 103-02 plan-task wording (verbatim from Phase 94-02 Task 2
shape):**
```
<action>Rewrite `.planning/v1.22-MILESTONE-AUDIT.md` so it evaluates the
repaired tree rather than preserving the stale pre-Phase-100 blocker set.
The refreshed audit must account for the now-present verification artifacts
for Phases 95, 96, and 98 (via Phases 100, 101, 102), the canonical
VALIDATION nyquist_compliant flips for 95/96/98, the v1.21 closeout
precedent for handling residual plan-level tech debt (e.g., 97-VALIDATION),
and Phase 103-01's authority reconciliation. Use $gsd-audit-milestone v1.22
to re-derive the structured frontmatter from the on-disk evidence; apply
post-tool tweaks per D-08 (preserve the verbatim D-10 bundle at audit body
lines ~142-145 per D-13; rewrite Recommendation per D-09) only if the tool
output drifts from the locked decisions.</action>
```

### Example 3: Phase-94 SUMMARY commit footer (no-emoji)

CLAUDE.md repo rules require no emojis. Phase 94 commits cleanly comply:

```
docs(94-02): complete authority-surface-reconciliation-and-closeout plan

Wave 2 rerun of `mix verify.doc_contract`, `mix verify.example`, and the
targeted root support-lane suite all passed on the repaired tree. Refreshed
v1.21-MILESTONE-AUDIT.md to status: passed; closed DOC-01 / DOC-02 in
REQUIREMENTS.md; updated ROADMAP.md / STATE.md / PROJECT.md to reflect
v1.21 closeout readiness.

Co-Authored-By: Claude Opus 4.7 ...
```

Reuse this shape for 103-02 with the v1.22 / 12-of-12 substitutions.

## State of the Art

| Old Approach (Phase 94 era) | Current (Phase 103) | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Five-surface reconciliation (ROADMAP + REQUIREMENTS + STATE + PROJECT + `guides/how-threadline-works.md`) | Four-surface reconciliation (no guides/ patch) | Phase 99 / Phase 100 (current tree's guides/how-threadline-works.md already has evidence-plane framing) | Tighter scope; one less file to touch; D-16 boundary cleaner |
| Mix verify.test alias as full-suite authority | D-10 bundle as named-command set inside the audit body | Phase 99 D-15 (cross-applies) | Bundle stays milestone-specific; `mix ci.all` explicitly demoted from authority |
| `closeout_ready` as imagined audit status | `passed` (the actual workflow emission per workflow §6) | This research pass (verified against `~/.claude/get-shit-done/workflows/audit-milestone.md`) | Plan terminology in 103-02 uses `passed` for milestone audit; `closeout_readiness: green` for phase-verification frontmatter |
| `total_plans: 14 / completed_plans: 14` in STATE assumed starting point | `total_plans: 16 / completed_plans: 16` actual (D-05 numbers were stale at CONTEXT-write time) | Between 2026-05-27 (CONTEXT) and 2026-05-27 (research) | Planner treats D-05 numbers as direction-of-change, not literal starting values |

**Deprecated / outdated:**
- The CONTEXT D-05 numeric targets (`completed_phases: 7 → 9, completed_plans:
  14 → 16, percent: 78 → 100`) — current on-disk STATE is already at
  `completed_phases: 8, completed_plans: 16, percent: 89`. Final target
  numbers (9/9, 18/18, 100%) hold; starting values do not.
- The CONTEXT D-08 reference to `status: closeout_ready` as a possible
  audit verdict — verified against the tool's actual emission, which uses
  `passed`. D-08 explicitly invites this verification ("confirm at runtime
  against the gsd-audit-milestone tool's actual output").

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `gsd-audit-milestone v1.22` invocation writes the audit file directly, not to stdout | §6, Code Example 2 | Plan would specify `> output.md` redirection that fails silently. **Mitigation:** verified workflow §6 explicitly says "Create `.planning/v{version}-MILESTONE-AUDIT.md` with:..." — file write is direct, not stdout. Confidence: HIGH. |
| A2 | The audit tool's PASS verdict is `status: passed` (not `closeout_ready` or `complete`) | §6, Standard Stack | Plan acceptance criteria would grep for a literal that never appears. **Mitigation:** verified against v1.20 archived audit (`status: passed`), v1.21 archived audit (`status: passed`), and workflow §6 explicit enum (`passed`, `gaps_found`, `tech_debt`). Confidence: HIGH. |
| A3 | `total_plans` will need to increase from 16 to 18 to reflect 103's two plans (vs. gsd-sdk re-deriving it) | §3 (STATE.md) | If the gsd-sdk re-derives `total_plans` from ROADMAP's `## Phases` count automatically, the planner would over-edit. **Mitigation:** the planner can verify this by running `gsd-sdk query state.begin-phase 103 103-01 1` (or whatever the canonical "open a plan" command is) and observing what the SDK writes. Suggested approach: leave the count edits to the SDK and only hand-edit the textual sections. Confidence: MEDIUM. |
| A4 | The v1.22-MILESTONE-AUDIT.md `tech_debt` row for `96-evidence-persistence-and-public-api` (alias-drift) is still applicable post-Phase-101 | §5 | If Phase 101 actually resolved the `mix verify.test` alias drift, the row should be removed in 103-02. **Mitigation:** D-08 reads "verify at runtime"; planner verifies via running `mix verify.test` in 103-02 and observes whether the alias-drift still surfaces. Confidence: MEDIUM. |
| A5 | The 100/101/102 VALIDATION files' `nyquist_compliant: false` status does NOT affect the v1.22 audit's `nyquist.compliant_phases` list, because those phases are NOT v1.22 phases in the audit's eyes — they are backfill phases for v1.22 phases | §7 | If the audit tool counts 100/101/102 as v1.22 phases (e.g., they're in ROADMAP under the v1.22 milestone heading), the rewrite would surface them in `partial_phases`. **Mitigation:** the ROADMAP.md shows Phases 95-103 all under "Milestone v1.22" (verified line 17). So 100/101/102 ARE v1.22 phases in the audit's scope. **Therefore the rewrite's `nyquist.partial_phases` may include 100/101/102** unless those files are also flipped before 103-02 runs. Recommendation: flip the 100/101/102 VALIDATION files to `nyquist_compliant: true` as a separate step inside 103-02 (this is bookkeeping-only, not a code/test change, so it stays within D-16's boundary; the actual rerun bundle's pass is the evidence that justifies the flip). Confidence: MEDIUM-HIGH — needs planner judgment call. |
| A6 | `closeout_readiness` is a custom phase-verification label and is NOT one of the workflow's three standard milestone-audit statuses | §6 / Pattern 4 | Confusion between "phase passed milestone gate" and "milestone is passed" could mislead the planner. **Mitigation:** Phase 94-VERIFICATION.md explicitly uses `closeout_readiness: green` in its OWN frontmatter and v1.21-MILESTONE-AUDIT.md uses `status: passed` in ITS frontmatter — two different labels for two different artifacts. Confidence: HIGH. |

**Critical for planner attention:** A5 is the assumption most likely to
generate a closeout-readiness yellow flag in 103-02 if not addressed. The
planner should explicitly task 103-02 with flipping 100/101/102 VALIDATION
files to `nyquist_compliant: true` once their backfilled evidence is
re-confirmed by the rerun, OR explicitly choose to leave them as
`nyquist.partial_phases` in the audit (with a tech_debt row recording the
plan-level draft frontmatter — same posture as v1.21's 90/91 entries).

## Open Questions

1. **Does `total_plans` in STATE.md yaml auto-update from ROADMAP plan-checkbox count?**
   - What we know: gsd-sdk has both `state.begin-phase` and (presumably)
     `state.update`-class commands. The yaml `progress.total_plans: 16` is
     a count, not a list; something is computing it.
   - What's unclear: whether the planner hand-edits or whether the
     state-update tool re-derives.
   - Recommendation: When the planner writes the 103-01 task that touches
     STATE.md, include the SDK call (if available) as the canonical
     update path; only hand-edit the textual sections. If the SDK doesn't
     auto-derive plan counts, hand-edit to `total_plans: 18, completed_plans:
     18, percent: 100` at the 103-02 final write.

2. **Should 103-02 flip 100/101/102 VALIDATION nyquist_compliant to true?**
   - What we know: Per A5, these phases are in the v1.22 audit's phase
     scope (Phases 95-103 all under v1.22 heading in ROADMAP line 17). The
     rerun bundle in 103-02 will re-prove the backfilled evidence.
   - What's unclear: whether D-16's "boundary is .planning/ only" allows
     editing other phases' VALIDATION.md files (it should — they're
     `.planning/phases/100*/100-VALIDATION.md` etc., still under
     `.planning/`).
   - Recommendation: Yes — 103-02 should flip them as a bookkeeping step
     once the rerun proves the backfilled evidence is still green. This
     keeps the v1.22 audit's `nyquist.compliant_phases` list clean and
     reduces the post-rewrite tech_debt to just Phase 97's residual
     follow-up. Treat as a Claude's-discretion call analogous to v1.21's
     90/91 plan-level VALIDATION posture.

3. **Does `gsd-audit-milestone` write `v1.22-MILESTONE-AUDIT.md` with a
   double-version prefix?**
   - What we know: Workflow §6 says "Create `.planning/v{version}-v{version}-
     MILESTONE-AUDIT.md`" — but every existing milestone audit on disk
     is single-prefix (`v1.21-MILESTONE-AUDIT.md`, etc.). This appears to
     be a workflow doc typo.
   - What's unclear: whether the tool will actually create
     `v1.22-v1.22-MILESTONE-AUDIT.md` (per the doc literal) or
     `v1.22-MILESTONE-AUDIT.md` (per existing precedent).
   - Recommendation: 103-02 plan-task should specify the single-prefix
     filename explicitly and include an acceptance grep that the file
     exists at `.planning/v1.22-MILESTONE-AUDIT.md`. If the tool emits
     `v1.22-v1.22-MILESTONE-AUDIT.md`, the planner manually renames or
     records the double-prefix path. Risk: LOW — every prior milestone
     audit on disk is single-prefix, suggesting the tool actually emits
     single-prefix correctly and the workflow doc has a typo.

## Project Constraints (from CLAUDE.md)

CLAUDE.md applies even to `.planning/`-only phases. Relevant constraints:

- **Build commands MUST exist (cross-check from §"Build & Development Commands"):**
  Verified — `mix verify.format`, `mix verify.credo`, `mix verify.test`,
  `mix ci.all`, `mix verify.doc_contract`, `mix verify.example`. The D-10
  bundle uses two of these aliases (`verify.doc_contract`, `verify.example`)
  plus a verbatim test invocation; matches the canonical entrypoint posture.
- **GSD positional-args rule:** "When running `gsd-sdk query state.begin-phase`,
  use positional arguments." Any plan that calls `state.begin-phase` for
  Phase 103 plans must use `state.begin-phase 103 authority-surface-reconciliation-and-milestone-re-audit 2`
  positionally, not `--phase 103 --name "..." --plan-count 2`.
- **No-emoji rule:** Verified — Phase 94 commits and artifacts are
  emoji-free. Phase 103 must follow.
- **OSS-DNA conventions:**
  - Named entrypoints over ad-hoc commands: D-10 honors this (uses named
    aliases for verify.doc_contract / verify.example).
  - Honest default tests: out of Phase 103 scope (no test changes).
  - Stable CI job IDs: out of Phase 103 scope (no CI workflow changes).
  - Path filters + main: out of Phase 103 scope.
  - Doc contract tests: out of Phase 103 scope (D-16; though `mix
    verify.doc_contract` is invoked, it's not modified).
- **Three-layer architecture (capture/semantics/exploration):** Does not
  directly apply to `.planning/`-only phases, but the milestone narrative
  in the rewritten audit must continue to use the canonical domain
  vocabulary (AuditTransaction, AuditChange, AuditAction, AuditContext,
  ActorRef, Correlation). No new vocabulary terms.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` (Elixir CLI) | D-10 bundle rerun | ✓ | (Elixir per project — 1.19.x baseline per CLAUDE.md "≥ 1.15 / OTP ≥ 26") | — (blocking if missing) |
| `mix verify.doc_contract` alias | D-10 bundle command 1 | ✓ | existing in `mix.exs` | — |
| `mix verify.example` alias | D-10 bundle command 3 | ✓ | existing in `mix.exs` | — |
| `mix test test/threadline/evidence_test.exs ...` (5-file list) | D-10 bundle command 2 | ✓ | files exist on disk (verified by line-count grep) | — |
| `gsd-sdk` CLI | init context, find-phase, commit | ✓ at `~/.local/bin/gsd-sdk` | wrapper for `gsd-tools.cjs` per MEMORY note | None — workflow assumes it |
| `gsd-audit-milestone` skill | D-11 audit rerun | ✓ at `~/.claude/skills/gsd-audit-milestone/SKILL.md` | (skill) | None |
| `rg` (ripgrep) | acceptance-criteria greps | (typically installed on macOS via homebrew; planner can assume yes per Phase 94 precedent which used `rg` in every `<verify>` block) | — | grep -E (fallback if needed) |
| `git` | per-plan commits + boundary verification | ✓ | (per `git --version`; standard) | — |
| `gsd-tools.cjs` (graphify) | — | not found in PATH | — | N/A — no graph queries needed for `.planning/`-only phase |

**Missing dependencies with no fallback:** None — all required tools are
available.

**Missing dependencies with fallback:** None.

## Validation Architecture

`.planning/config.json` (the workflow config) is locked from Phase 94 D-23..D-25
in the recommendation-first discuss posture. `workflow.nyquist_validation`
was not specifically toggled in CONTEXT (per D-24's listed keys) — therefore
treat as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.x) + Mix alias verification + planning-artifact review (ripgrep / git diff) |
| Config file | `mix.exs`, `test/test_helper.exs`; for planning artifacts: `.planning/v1.22-MILESTONE-AUDIT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md` |
| Quick run command | `mix verify.doc_contract` (~5-10s) |
| Named proof commands | `mix verify.doc_contract` AND `mix verify.example` |
| Full closeout bundle | The D-10 three-command bundle: `mix verify.doc_contract && mix test <5-file list> --max-failures 1 && mix verify.example` |
| Artifact checks | `rg -n` over the rewritten audit + reconciled authority surfaces |
| Estimated runtime | ~20-30 seconds warm for the full closeout bundle (Phase 94 observed ~15s warm; 103's middle bundle is 5 files vs 94's 9 files, so ~15-20s plus the two aliases) |

### Phase Requirements → Test Map

Phase 103 itself has no REQ-IDs (per init JSON). It closes SURF-01/02/03
traceability that Phase 102 verified. The map is therefore:

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SURF-01 (traceability close) | REQUIREMENTS.md row flips to Complete | artifact grep | `rg -n 'SURF-01 \\| Phase 102 \\| Complete' .planning/REQUIREMENTS.md` | ✅ (file exists; row currently says Pending — flips in 103-01) |
| SURF-02 (traceability close) | REQUIREMENTS.md row flips to Complete | artifact grep | `rg -n 'SURF-02 \\| Phase 102 \\| Complete' .planning/REQUIREMENTS.md` | ✅ |
| SURF-03 (traceability close) | REQUIREMENTS.md row flips to Complete | artifact grep | `rg -n 'SURF-03 \\| Phase 102 \\| Complete' .planning/REQUIREMENTS.md` | ✅ |
| Closeout-bundle rerun green | Three named commands exit 0 | integration | `mix verify.doc_contract && mix test test/threadline/evidence_test.exs test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/auth_test.exs --max-failures 1 && mix verify.example` | ✅ all 5 test files + 2 aliases verified |
| Audit rewrite verdict | `v1.22-MILESTONE-AUDIT.md` `status: passed` | artifact grep | `rg -n '^status: passed' .planning/v1.22-MILESTONE-AUDIT.md` | ✅ (file exists; currently `gaps_found`) |
| Authority surfaces agree | Four surfaces all describe v1.22 closeout-ready | artifact grep | `rg -n 'closeout-ready\|12 of 12 satisfied\|v1\.22 is ready for' .planning/ROADMAP.md .planning/REQUIREMENTS.md .planning/STATE.md .planning/PROJECT.md .planning/v1.22-MILESTONE-AUDIT.md` | ✅ |
| Boundary maintained | Off-limits surfaces unchanged | git diff | `git diff --name-only .planning/MILESTONE-ARC.md .planning/MILESTONES.md .planning/RETROSPECTIVE.md ; ls .planning/milestones/v1.22-* 2>/dev/null` returns empty | ✅ |

### Sampling Rate

- **Per task commit (103-01):** Single-file grep on the file just edited
  (`rg -n` for the new wording).
- **Per task commit (103-02):** Quick run = `mix verify.doc_contract`
  (catches DOC contract regressions in ~5-10s).
- **Per wave merge (after Wave 1 / 103-01):** Boundary guard
  (`git diff --name-only` shows only the four authority-surface files).
- **Per wave merge (after Wave 2 / 103-02):** Full closeout bundle + audit
  grep + boundary guard.
- **Phase gate:** Full closeout bundle green AND `v1.22-MILESTONE-AUDIT.md`
  `status: passed` AND `103-VERIFICATION.md` `closeout_readiness: green`
  before `/gsd:verify-work`.

### Wave 0 Gaps

- [x] Test files exist and pass (verified): `test/threadline/evidence_test.exs`
  (9 tests), `test/threadline/evidence/proof_test.exs` (5), `test/mix/tasks/
  threadline.evidence_show_test.exs` (7), `test/threadline/operator_surface/
  live/evidence_live_test.exs` (5), `test/threadline/operator_surface/
  auth_test.exs` (29). Total 55.
- [x] Mix aliases exist (verified by Phase 94 precedent + audit body
  references): `verify.doc_contract`, `verify.example`.
- [x] Planning files exist (verified by file-length grep): ROADMAP (155),
  REQUIREMENTS (75), STATE (95), PROJECT (327), v1.22-MILESTONE-AUDIT (190).
- [x] Phase 100/101/102 VERIFICATION + canonical 95/96/98 VALIDATION
  artifacts exist on disk with the required closure markers (verified).
- [ ] **No gaps.** Phase 103 is purely an authority-surface reconciliation
  + audit rerun; all infrastructure already exists. Wave 0 = N/A.

*(Equivalent to Phase 94's "Existing infrastructure covers all phase
requirements" posture.)*

## Security Domain

`.planning/config.json` `security_enforcement` setting: not explicitly
set in CONTEXT, so assume enabled (default).

For a planning-tree-only phase, the conventional ASVS categories don't
directly apply to code surfaces. The threat model is **information-integrity**
of the planning surfaces themselves:

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | (no code surface) |
| V3 Session Management | no | (no code surface) |
| V4 Access Control | no | (no code surface) |
| V5 Input Validation | no | (no user-supplied input — only authoritative-file edits) |
| V6 Cryptography | no | (no crypto surface) |

### Known Threat Patterns for `.planning/`-only reconciliation phases

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| False closure (declaring milestone ready without rerun proof) | Tampering | D-10 bundle rerun before audit rewrite; rerun-backed VERIFICATION evidence required (Phase 94 precedent: "94-01-SUMMARY.md frontmatter is not authoritative for requirement closure") |
| Boundary violation (touching off-limits files) | Tampering | Per-task `git diff` boundary guards on MILESTONE-ARC.md, PROJECT.md "Last shipped" line, MILESTONES.md, RETROSPECTIVE.md, .planning/milestones/v1.22-*, lib/, test/, mix.exs, mix.lock, guides/, examples/, priv/ |
| Audit history loss (rewriting the audit destroys prior context) | Repudiation | D-07 preserves historical snapshot at git SHA precision (`git show HEAD~:.planning/v1.22-MILESTONE-AUDIT.md`); plan body explicitly says "history-preserving rewrite" |
| Scope creep into repair (D-15) | Tampering / Information Disclosure | Plan task explicitly says "stop in place and record" if rerun surfaces a new gap; 103-VERIFICATION.md frontmatter `closeout_readiness: red/yellow` enum forces explicit non-green outcome |
| Stale-cross-document divergence (one surface says 12/12, another still says 8/12) | Repudiation | After both plans land, an integration grep verifies all four surfaces + the audit + the verification artifacts agree on the same closure counts and same "ready for /gsd-complete-milestone" framing |

## Sources

### Primary (HIGH confidence)

- **`.planning/phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-CONTEXT.md`** — D-01..D-16 locked decisions, canonical refs, deferred items (read fully, all 448 lines)
- **`.planning/phases/94-authority-surface-reconciliation-and-closeout/94-01-PLAN.md`** — direct structural template for 103-01 (read fully, 183 lines)
- **`.planning/phases/94-authority-surface-reconciliation-and-closeout/94-02-PLAN.md`** — direct structural template for 103-02 (read fully, 188 lines)
- **`.planning/phases/94-authority-surface-reconciliation-and-closeout/94-VERIFICATION.md`** — direct structural template for 103-VERIFICATION (read fully, 133 lines)
- **`.planning/phases/94-authority-surface-reconciliation-and-closeout/94-VALIDATION.md`** — direct structural template for 103-VALIDATION (read fully, 93 lines)
- **`.planning/phases/94-authority-surface-reconciliation-and-closeout/94-CONTEXT.md`** — original five-surfaces scope (D-19) which Phase 103 narrows to four
- **`.planning/REQUIREMENTS.md`** — current SURF row state (lines 22-24, 60-62, 75)
- **`.planning/STATE.md`** — current yaml header + section bodies (read fully, 95 lines)
- **`.planning/ROADMAP.md`** — Phase 103 plan checkbox state (lines 128-129)
- **`.planning/PROJECT.md`** — "Current planning focus" sentence + "Last shipped: v1.21" framing (lines 12-26, 327)
- **`.planning/v1.22-MILESTONE-AUDIT.md`** — current frontmatter + body + D-10 bundle (read fully, 190 lines)
- **`.planning/v1.20-MILESTONE-AUDIT.md`** + **`.planning/v1.16-MILESTONE-AUDIT.md`** — prior milestone audit frontmatter shapes (status: passed enum verified)
- **`.planning/milestones/v1.21-MILESTONE-AUDIT.md`** — post-Phase-94 rewrite shape; direct template for 103-02's rewrite (read fully, 122 lines)
- **`.planning/MILESTONE-ARC.md`** — v1.22 row "active" status verified (line 34)
- **`.planning/phases/95-evidence-model-lock-and-scope-guard/95-VALIDATION.md`** — verified `nyquist_compliant: true`
- **`.planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md`** — verified `nyquist_compliant: true`
- **`.planning/phases/97-mix-task-and-machine-readable-proof/97-VALIDATION.md`** — verified `nyquist_compliant: false` (head only)
- **`.planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md`** — verified `nyquist_compliant: true`
- **`.planning/phases/100-phase-95-verification-backfill/100-VALIDATION.md`** + **`101-VALIDATION.md`** + **`102-VALIDATION.md`** — verified all three are `nyquist_compliant: false` in their own frontmatter
- **`~/.claude/skills/gsd-audit-milestone/SKILL.md`** — tool argument shape (optional `[version]`)
- **`~/.claude/get-shit-done/workflows/audit-milestone.md`** — tool's actual emission shape (workflow §6 enum: `passed | gaps_found | tech_debt`), 3-source cross-reference (workflow §5), Nyquist discovery (workflow §5.5), file-write target (workflow §6)
- **`CLAUDE.md`** — repo invariants (build commands, GSD positional args, no-emoji)
- **`guides/how-threadline-works.md`** — verified evidence-plane framing on lines 30, 34, 80, 116, 189 (justifies four-vs-five-surfaces deviation in §9)
- **Git history**: `git log --oneline -- .planning/phases/94-*/` — Phase 94 three-commit pattern verified

### Secondary (MEDIUM confidence)

- **Init JSON via `gsd-sdk query init.phase-op 103`** — phase_dir, commit_docs, planning paths verified; phase_req_ids null confirmed
- **Top-level `test/2` count via grep** — 9+5+7+5+29=55 matches the audit's middle-bundle baseline count, supporting D-10's "baseline counts from 2026-05-26" as still valid at planning time

### Tertiary (LOW confidence)

- **Assumption A3 (total_plans auto-update)** — gsd-sdk behavior here is not
  fully traced; planner verifies at write time
- **Assumption A4 (96 alias-drift tech-debt still applicable)** — needs
  rerun-time verification in 103-02
- **Open Question 3 (double-version-prefix in workflow §6 file path)** —
  appears to be doc typo; every on-disk milestone audit is single-prefix

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all tools (`mix verify.*` aliases, `gsd-audit-milestone`,
  `gsd-sdk`) are verified present and documented
- Architecture (Phase 94 → 103 mirror): HIGH — direct structural template
  read end-to-end; deviations explicitly catalogued
- Pitfalls: HIGH — six pitfalls catalogued with verification path for each
- Locked facts (lines 128-129 of ROADMAP, lines 22-24/60-62/75 of
  REQUIREMENTS, line 26 of PROJECT, etc.): HIGH — verified by direct file
  read at known line numbers
- Audit tool emission (`status: passed`, not `closeout_ready`): HIGH —
  cross-verified against three prior milestone audits + workflow §6 enum
- Nyquist VALIDATION state on disk: HIGH — verified by direct frontmatter
  read
- Boundary verification: HIGH — verified by ls / git log / direct read
- 100/101/102 VALIDATION nyquist disposition (A5): MEDIUM — depends on
  whether Phase 103-02 is allowed to flip those flags as bookkeeping; left
  as a planner judgment call

**Research date:** 2026-05-27
**Valid until:** 2026-06-10 (~14 days for stable planning-tree state) — but
revalidate the locked facts at planning-time if any of the source files were
modified between this research pass and the planner pass. Specifically watch
for: STATE.md yaml `last_updated` (it auto-updates), and the audit's existing
2026-05-26 baseline (it gets overwritten by 103-02 itself).

## RESEARCH COMPLETE
