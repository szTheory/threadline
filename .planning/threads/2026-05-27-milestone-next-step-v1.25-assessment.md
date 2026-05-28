# Thread: Milestone next-step assessment → v1.25 recommendation

**Opened:** 2026-05-27  
**Status:** closed (v1.25 shipped 2026-05-28; v1.26 opened 2026-05-27 per diminishing-returns assessment)  
**Source:** Post-v1.24 milestone next-step assessment (repo-grounded; plan approved)

**Supersedes:** `.planning/threads/2026-05-27-milestone-next-step-v1.24.md` (closed)

## Summary

Threadline is **~88–92% done** for its stated narrow audit-platform scope (80–89% band trending toward 90–95% near-done). v1.24 closed the primary adoption foot-gun (`Threadline.Audit.transaction/3` + reference/doc truth). **No sustained real-adopter signal** — same gating condition as v1.24 kickoff.

**Prior ~83% figure is stale** — it measured pre-v1.24 wedge (manual transaction recipe); do not cite as current completion %.

## Recommended milestone

**v1.25 — Adopter-Ready Release & First-Hour Truth**

**Goal:** Make the shipped v1.22–v1.24 stack truthfully adoptable from Hex and remove first-hour doc/example friction — without compliance expansion or a second synthetic walkthrough.

**Illustrative scope (for `/gsd-new-milestone`):**
- **REL:** Cut **threadline 0.6.0** — changelog, ExDoc includes `Threadline.Audit`, `mix verify.release` green
- **NARR:** Sync `guides/how-threadline-works.md` to `Audit.transaction/3` as blessed write path
- **EXAMPLE:** Fix example README (API auth staging, setup vs `demo.seed`, generator/migration confusion)
- **DOC:** Evidence-plane doc authority (thin hub or fix PROJECT references); semver-not-milestone in adopter prose
- **PILOT-PREP (optional narrow phase):** Refresh adoption-pilot test counts; external evaluator one-pager

**Non-goals (carry forward):** DEFER trio (compliance packs, legal hold, immutable archive); new Evidence subjects; Threadline-owned RBAC; help-desk product UI; container compose walk unless demand; `threadline_web` split.

## Suggested ordering after v1.25

1. **v1.26 — Auth Lane Breadth** — phx.gen.auth cookbook + proof (largest remaining Phoenix SaaS reach gap)
2. **v1.27 — External Pilot** — when sustained signal appears; unblockers only
3. **Maintenance** — IN-110-003 Manifest hardening, operator UX micro-polish
4. **DEFER trio** — only on procurement pressure

## Open investigations

| ID | Severity | Topic | Routing |
|----|----------|-------|---------|
| IN-110-003 | info | `:agent2` not on `Manifest.user_id/1` | Optional hardening; UUID locked in contract test |
| STG-01 | P2 | Host staging depth vs library CI | adoption-pilot backlog; not v1.25 blocker |
| Real external adopter | — | No sustained signal | Re-engages v1.22 rule; pivot to pilot unblockers |
| Containerized walk | deferred | Full compose app+db walk | Seed only if demand |

## Doc drift flagged (fix in v1.25)

- Hex **0.5.0** (2026-05-08) lags v1.22–v1.24 in-repo stack; CHANGELOG `[Unreleased]` only
- `how-threadline-works.md` centers `record_action/2`; getting-started/README lead with `Audit.transaction/3`
- `PROJECT.md` referenced missing `guides/evidence-plane.md` (content split across other guides)
- Example README curl for `POST /api/posts` missing auth staging
- Dual semver vs internal milestone vocabulary in adopter docs

## Graduation candidates (cross-phase)

1. **Three-phase vertical slice** — library helper → reference adoption → doc truth (v1.24 validated)
2. **Doc-contract tests as evaluator closeout gate** — CLI naming, version table, mount options (v1.24 Phase 113)
3. **Observe-only dry-run → triage phase** — v1.23 Phases 109→110
4. **Named `mix verify.*` as claim authority** — vs `mix ci.all` on dirty tree

## Re-engagement trigger

First **sustained** real-adopter signal (pilot host, integration issue, procurement/security review) → pause synthetic release/truth work; pivot to pilot unblockers (per PROJECT.md Key Decisions v1.23 override).

## Next GSD steps

1. `/gsd-new-milestone` — **v1.25 Adopter-Ready Release & First-Hour Truth** (or override if adopter signal exists)
2. On sustained adopter signal: pilot milestone instead of v1.25 synthetic wedge
