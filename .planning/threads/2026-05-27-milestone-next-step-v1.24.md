# Thread: Milestone next-step assessment → v1.24 kickoff

**Opened:** 2026-05-27  
**Closed:** 2026-05-27  
**Status:** closed — v1.24 shipped; superseded by `.planning/threads/2026-05-27-milestone-next-step-v1.25-assessment.md`  
**Source:** Milestone-next-step assessment (plan approved; no sustained real-adopter signal)

## Summary

Threadline is **~83% done** for its stated narrow audit-platform scope (80–89% band: strong, meaningful wedges remain). v1.23 walkthrough filed **zero** design-gap deferrals; `.planning/v1.24-seeds/` was empty at closeout.

**Confirmed v1.24:** **Audited Write Path & Adopter Truth** — no pilot-first pivot (no sustained adopter signal in 4–8 weeks).

## Recommended milestone

**Goal:** Make the trustworthy capture+semantics path the **easy** path (library helper), and make the **sigra-reference** example + docs **honest** for 0.5.x evaluators.

**Non-goals (carry forward):** No new Evidence subjects; no compliance packs / legal hold / immutable archive (v1.22 DEFER); no Threadline-owned RBAC; no second synthetic walkthrough; no help-desk product expansion.

**Phase numbering:** Continue from **Phase 111** (after v1.23 Phase 110).

## Open investigations (pre-milestone)

| ID | Severity | Topic | v1.24 routing |
|----|----------|-------|----------------|
| WR-110-001 | warning | WALK-03-02 operator question says "last 24 hours" vs `demo_last_tuesday` / `demo_epoch` | Phase 113 doc truth |
| IN-110-001 | info | Leaving-agent contract test shallow (`count >= 1`) | Optional hardening in 113 |
| IN-110-002 | info | `walkthrough_doc_contract_test` omits WALK-03-02 literals | Phase 113 |
| IN-110-003 | info | `:agent2` not on `Manifest.user_id/1` | Optional 113 |
| Containerized walk | discussed | Full compose app+db walk | **Defer** — seed only if demand |

## Doc drift flagged (fix in v1.24)

- `PROJECT.md` Active listed v1.23 reqs unchecked → fixed at kickoff
- `MILESTONE-ARC.md` v1.23 still `active` → fixed at kickoff
- `guides/adoption-pilot-backlog.md` cites Hex **0.2.0**; tree is **0.5.0**
- Example mount lacks `evidence_authorize_fn` → `/audit/evidence` fail-closed
- `mix verify.evidence` vs canonical `mix threadline.evidence.show`

## Graduation candidates (closeout playbook)

1. Observe-only dry-run → triage phase (v1.23 Phases 109→110)
2. Verification backfill + authority reconciliation (v1.22 Phases 100–103)
3. Named `mix verify.*` bundle as **claim** authority vs `mix ci.all` on dirty tree

## Re-engagement trigger

First **sustained** real-adopter signal (pilot host, integration issue, procurement/security review) → pause v1.24-style synthetic work; pivot milestone to pilot unblockers (per PROJECT.md Key Decisions v1.23 override).

## Next GSD steps

1. `/gsd-discuss-phase 111` or `/gsd-plan-phase 111`
2. On sustained adopter signal: file `.planning/v1.24-seeds/` or open pilot milestone
