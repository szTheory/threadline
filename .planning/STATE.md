---
gsd_state_version: 1.0
milestone: v1.31
milestone_name: "Operator Surface: Insane Polish"
status: executing
last_updated: "2026-06-03T22:55:24.564Z"
last_activity: 2026-06-03 -- Phase 135 planning complete
progress:
  total_phases: 10
  completed_phases: 0
  total_plans: 4
  completed_plans: 0
  percent: 0
---

# Project State: Threadline

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-29)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current focus:** v1.31 — Operator Surface: Insane Polish (phases 134–143). A systematic second pass over the entire `/audit` operator surface: one consistent, brand-aligned, mobile-first baseline on a hardened BEM + `--tl-*` token design system, IA aligned to personas/JTBD with a few earned new flows, restrained micro-animation, enriched seed — screenshot-/decision-recorded so a context clear loses nothing. Foundations (audit → seed → design-system) precede per-screen work.

## Current Position

Phase: 135 — Seed Enrichment & IA Lock-In (context gathered)
Plan: — (next: /gsd:plan-phase 135)
Status: Ready to execute
Last activity: 2026-06-03 -- Phase 135 planning complete
Resume: `.planning/phases/135-seed-enrichment-ia-lock-in/135-CONTEXT.md`

## Performance Metrics

- **Last Milestone Shipped**: v1.30 — Adoption Evidence Automation (2026-05-29)
- **Scope completion (assessment)**: **~92–95%** for stated narrow audit-platform scope (band: near-done)
- **Hex distribution**: in-repo and hex.pm latest **0.9.0** (tag `v0.9.0`, published 2026-06-03; prior `v0.8.0` 2026-06-03, `v0.7.0` 2026-05-30)
- **Path-to-done thread**: `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md`
- **Posture thread**: `.planning/threads/2026-05-29-post-v1.29-posture.md`
- **v1.28 pilot readiness**: `.planning/threads/2026-05-29-v1.28-pilot-readiness.md`

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| external-pilot | v1.28 pilot unblockers | **Deferred** until sustained real-adopter signal |
| post-v1.29 | Hold mode | **Superseded** by v1.31 polish milestone (2026-06-03) |
| v1.22 DEFER | COMPLIANCE-PACK, LEGAL-HOLD, IMMUTABLE-ARCHIVE | Deferred until procurement pressure |
| host-class | STG-01 host staging depth | Integrator-owned; v1.28 when signal |
| Pow / bearer auth lane | On explicit demand only | Not planned |

## Accumulated Context

### Pending Todos

- **Capture direct demo and UI polish** — direct Hold-mode commits `253bec3` and `f23a9cc` (operator-surface positioning + a11y pass) are now the baseline that v1.31 systematizes; reconcile any deltas during Phase 134 audit.

### Roadmap Evolution

- Phase 130.1 inserted after Phase 130: Address tech debt: planning metadata hygiene (URGENT)
- Milestone v1.29 archived 2026-05-29
- **Post-v1.30 direct-PR work (2026-05-30, no milestone):**
  - **0.7.0 release** — unblocked the stuck release-please PR; fixed `bin/verify-release-shape` to accept release-please's CHANGELOG heading; published `v0.7.0` to Hex. Fixed the operator-surface timeline crash on `?correlation_id=` (`FilterParams` `String.to_existing_atom` → compile-time allowlist) that had kept the v1.30 Playwright job (Phase 132) red.
  - **Release-pipeline hardening** — generalized `bin/post-publish-distribution-sync` (was 0.5→0.6-pinned); added `workflow_dispatch` to `ci.yml` so "Bootstrap CI on Release PR" stops failing.
  - **Test determinism** — fixed the ~40% retention-pruner flake + a telemetry cross-contamination flake; added `test/support/async_helpers.ex`, `mix verify.flake`, and a nightly **Flake Detection** workflow. See `CONTRIBUTING.md` "Deterministic tests".
- **Direct-PR work (2026-06-03, no milestone):**
  - **Operator surface** — first-class positioning + accessibility pass (#16); deterministic evidence `record_*` export assertions (#18).
  - **0.8.0 + 0.9.0 cuts** — published to Hex via release-please.
  - **Release-please born-red root-cause fix (#22)** — every release PR was born red because release-please bumped `mix.exs` but not the adoption-pilot guide, failing `adoption_pilot_doc_contract_test`. Fixed via `extra-files` + `x-release-please-version` annotation so the SSOT line is bumped atomically in the release commit (green by construction, no manual prep). `bin/post-publish-distribution-sync` now owns only the post-publish Hex row; a guard test enforces the wiring. See memory `release-runbook` and `CONTRIBUTING.md`.
- **Milestone v1.31 opened (2026-06-03):** Hold superseded by a non-signal-gated polish milestone. 10 phases (134–143), 1:1 with 10 POLISH-* requirements, fully pre-decided order: measure → enrich → systematize → apply (least-iterated first) → hub → flows → motion → responsive → sweep.

### Decisions

- **130.1-02 (2026-05-29):** Nyquist waivers for doc-only phases 128–129; 130-VALIDATION superseded footnote; `mix ci.all` green at closeout.
- **130-02 (2026-05-28):** SUMMARY SSOT at `conventions/summary-frontmatter.md`; GAP IDs for 125–127 only; single `mix ci.all` in 130-VERIFICATION.
- **130-01 (2026-05-29):** Phase 125 archived under `milestones/v1.27-phases/`; `125-VALIDATION.md` finalized after Tier 1 green.
- **128-02 (2026-05-28):** phx-gen-auth mount uses `&MyApp.Audit.authorize_operator/1` with scope-first lookup and `is_admin: true` gate.
- **v1.29 posture (2026-05-29):** Hold for milestones; pre-pilot hardening: `mix verify.hex_evaluator`, WALKTHROUGH ConnCase tests; pilot pack queued.
- Full decision log: `.planning/PROJECT.md` Key Decisions table.

### Blockers

- None.

## Session Continuity

- **Milestone closeout (2026-05-29):** v1.29 archived; tag `v1.29`; REQUIREMENTS.md removed for fresh next milestone.
- **130.1-02 (2026-05-29):** 130-VALIDATION superseded footnote; Nyquist waivers for 128/129; 130.1-VERIFICATION passed; `mix ci.all` green (744+61 tests).
- **Last Action**: v1.31 roadmap created — phases 134–143 mapped 1:1 to POLISH-* requirements (2026-06-03)
- **Next Step**: Plan Phase 134 (`/gsd:plan-phase 134`) — Baseline Audit & Screenshot Inventory
- **Resume file**: None

## Operator Next Steps

- **Plan Phase 134** — Baseline Audit & Screenshot Inventory (foundation: every later phase cites its findings)
- **Locked constraints** — keep BEM `.tl-*` + `--tl-*` tokens in `style.ex` (no Tailwind/build step); dark-first brand; seed enrichment only; no new backend/screens; every new flow traces to a JTBD + decision record
- v1.28 external pilot remains signal-gated and out of scope for v1.31
