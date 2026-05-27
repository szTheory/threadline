# Phase 103: Authority-Surface Reconciliation And Milestone Re-Audit - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 103-authority-surface-reconciliation-and-milestone-re-audit
**Areas discussed:** Authority-surface scope (103-01), Audit artifact handling (103-02), Closeout-readiness rerun bar (103-02)
**Mode:** advisor (USER-PROFILE.md present); calibration tier `minimal_decisive` (vendor_philosophy: opinionated)

---

## Authority-surface scope (103-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Trio + PROJECT.md current-state | Touch ROADMAP, REQUIREMENTS, STATE, and the v1.22-remaining-work / next-step sections of PROJECT.md only. Leave MILESTONE-ARC's `v1.22 \| active` row, PROJECT.md's `Last shipped: v1.21`, MILESTONES.md, RETROSPECTIVE.md, and milestone archive copies untouched — those move at `/gsd-complete-milestone v1.22`. Matches Phase 94's exact pattern (git commit `140a5c2` archived v1.21 only after Phase 94 closed). | ✓ |
| Strict authority trio only | Touch just ROADMAP, REQUIREMENTS, STATE as the v1.22-MILESTONE-AUDIT recommendation literally names. Smaller surface, but leaves PROJECT.md's `Operator Next Steps` and v1.22 remaining-work narrative contradicting the repaired STATE counts — violates Phase 94 D-16 and recreates the "narrative outruns proof" failure mode. | |

**User's choice:** Trio + PROJECT.md current-state (Recommended)
**Notes:** Locked as D-01..D-06 in CONTEXT.md. PROJECT.md gets a narrow narrative-only pass — no flip of "Last shipped: v1.21", no claim that v1.22 is shipped. `/gsd-complete-milestone v1.22` is the next gate that owns MILESTONE-ARC, archive copies, and shipped-pointer flips.

---

## Audit artifact handling (103-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Replace in place | Rewrite `.planning/v1.22-MILESTONE-AUDIT.md` with the rerun verdict. One canonical audit per milestone — matches every prior milestone (v1.1–v1.21 each have exactly one audit file) and Phase 94's explicit "Rewrote the stale v1.21 milestone audit" pattern. Historical `gaps_found` snapshot is preserved at SHA precision via git. | ✓ |
| Additive rerun file | Keep the original gaps_found audit and write a dated rerun file (e.g., `v1.22-MILESTONE-AUDIT-2026-05-27.md`) alongside it. On-disk historical snapshot, but breaks the one-canonical-audit invariant, forces readers to disambiguate, and creates archive-time ambiguity. No Threadline phase has ever done this. | |

**User's choice:** Replace in place (Recommended)
**Notes:** Locked as D-07..D-09 in CONTEXT.md. Forensic-history concern addressed by git (`git show HEAD~:.planning/v1.22-MILESTONE-AUDIT.md` recovers the gaps_found snapshot). Contestability of the closeout claim is preserved by the audit's own `audited:` timestamp + 103-02-SUMMARY.md naming the rerun command.

---

## Closeout-readiness rerun bar (103-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Audit + named focused bundle | Rerun the three commands the v1.22 audit body names at lines 142-145: `mix verify.doc_contract` (~46 tests), the 5-file `mix test` invocation (~55 tests), `mix verify.example` (~21 tests), then rerun `gsd-audit-milestone`. Matches Phase 94 / v1.21 closeout exactly and Phase 99 D-13/D-14. Bundle stays named in the audit body — no new `mix verify.closeout` alias. | ✓ |
| Audit + `mix ci.all` | Full repo health check before the audit rerun. Phase 99 D-15 explicitly disclaimed this as a closeout authority — formatting/credo noise muddies the milestone-truth signal, and dirty-tree `verify.format` failures already demonstrated the failure mode. | |

**User's choice:** Audit + named focused bundle (Recommended)
**Notes:** Locked as D-10..D-13 in CONTEXT.md. `mix ci.all` rejected as a closeout authority per Phase 99 D-15. No new `mix verify.closeout` alias — the middle command (5-file evidence/auth bundle) is milestone-specific (v1.21's bundle was `support-lane/timeline/export`; v1.22's is `evidence/proof/evidence_show/evidence_live/auth`), so a stable alias would either go stale or need to be rewritten each milestone.

---

## Claude's Discretion

The following implementation details are explicitly left to the planner / executor per CONTEXT.md "Claude's Discretion" section:

- Exact order of authority-surface edits inside 103-01 (final state must be consistent).
- Exact wording of the four per-phase `### Decisions` entries appended to STATE.md (one each for Phases 100/101/102/103), matching the existing Phase 90-94 entry shape.
- Exact wording of the closeout-ready Recommendation in the rewritten `v1.22-MILESTONE-AUDIT.md`, as long as it names `/gsd-complete-milestone v1.22` as the next gate and does not declare v1.22 "shipped".
- Whether 103-01 and 103-02 are one commit per plan (Phase 94 precedent) or split further. Default is one commit per plan summary.
- Whether `103-VERIFICATION.md` cites the three closeout-bundle commands as separate evidence bands or one combined band, as long as observed counts and exit codes are recorded verbatim.

## Deferred Ideas

- **`/gsd-complete-milestone v1.22`** — owns the MILESTONE-ARC v1.22 row flip, PROJECT.md "Last shipped" flip, and `.planning/milestones/v1.22-*` archive copy creation. Next gate after Phase 103 closes green.
- **Potential Phase 104** — only if 103-02's audit rerun surfaces a new gap that Phases 100/101/102 missed. Per D-15, Phase 103 stops in place; new gaps open a dedicated follow-up phase rather than being absorbed inline.
- **`mix verify.closeout` alias** — considered and rejected (D-13). The closeout-bundle middle command is milestone-specific. The two genuinely reusable pieces (`mix verify.doc_contract`, `mix verify.example`) are already aliases; that's the right generalization level.
