---
gsd_state_version: 1.0
milestone: v1.31
milestone_name: "Operator Surface: Insane Polish"
status: planning
last_updated: "2026-06-03T21:54:37.608Z"
last_activity: 2026-06-03
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State: Threadline

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-29)

**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.
**Current focus:** Hold — pre-pilot hardening (Hex CI + WALKTHROUGH automation) shipped in v1.30; v1.28 signal-gated. Post-v1.30, all as direct PRs (no milestone): 0.7.0 cut + release-pipeline/test-determinism hardening (2026-05-30); operator-surface first-class positioning + a11y pass and 0.8.0/0.9.0 cuts (2026-06-03); release-please born-red root-cause fix (2026-06-03).

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-06-03 — Milestone v1.31 started

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
| post-v1.29 | Hold mode | **Active** — default after v1.29 ships; pre-pilot hardening in-repo |
| v1.22 DEFER | COMPLIANCE-PACK, LEGAL-HOLD, IMMUTABLE-ARCHIVE | Deferred until procurement pressure |
| host-class | STG-01 host staging depth | Integrator-owned; v1.28 when signal |
| Pow / bearer auth lane | On explicit demand only | Not planned |

## Accumulated Context

### Pending Todos

- **Capture direct demo and UI polish** — decide how to reflect direct Hold-mode commits `253bec3` and `f23a9cc` in GSD authority surfaces, changelog/release notes, or next-milestone planning.

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
- **Last Action**: 0.9.0 published + release-please born-red root-cause fix via direct PRs (2026-06-03)
- **Next Step**: Hold — use evaluator ladder; open v1.28 via `/gsd-new-milestone` when adopter signal appears (see `2026-05-29-v1.28-pilot-readiness.md`)
- **Resume file**: None

## Operator Next Steps

- **Hold** — no new milestone until sustained adopter signal
- **Evaluator ladder** — `mix ci.all`, `mix verify.hex_evaluator`, example Track A/B, evaluating guide
- **v1.28 trigger** — `/gsd-new-milestone` when pilot-readiness thread conditions met
- Do **not** open v1.28 external pilot until sustained adopter signal
