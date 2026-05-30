# Roadmap: Threadline

## Milestones

- ✅ **v1.22 Policy / Evidence Plane** — Phases 95-103, shipped 2026-05-27. Archive: `.planning/milestones/v1.22-ROADMAP.md`
- ✅ **v1.23 Realistic-Demo Walkthrough** — Phases 104-110, shipped 2026-05-27. Archive: `.planning/milestones/v1.23-ROADMAP.md`
- ✅ **v1.24 Audited Write Path & Adopter Truth** — Phases 111-113, shipped 2026-05-27. Archive: `.planning/milestones/v1.24-ROADMAP.md`
- ✅ **v1.25 Adopter-Ready Release & First-Hour Truth** — Phases 114-118, shipped 2026-05-28. Archive: `.planning/milestones/v1.25-ROADMAP.md`
- ✅ **v1.26 Auth Lane Breadth** — Phases 119-121, shipped 2026-05-28. Archive: `.planning/milestones/v1.26-ROADMAP.md`
- ✅ **v1.27 Distribution & First-Hour Finish** — Phases 122-127, shipped 2026-05-28. Archive: `.planning/milestones/v1.27-ROADMAP.md`
- ✅ **v1.29 First-Hour Parity** — Phases 128-130.1, shipped 2026-05-29. Archive: `.planning/milestones/v1.29-ROADMAP.md`
- ✅ **v1.30 Adoption Evidence Automation** — Phases 131-133, shipped 2026-05-29. Archive: `.planning/milestones/v1.30-ROADMAP.md`

## Current Planning State

**Milestone:** Hold
**Status:** In progress (evaluating pilot readiness)
**Last shipped:** v1.30 — Adoption Evidence Automation (2026-05-29)
**Live on Hex:** **0.7.0** (tag `v0.7.0`, 2026-05-30)
**Next step:** Await real adopter signal for v1.28

**Assessment:** v1.30 closed shift-left automation gaps (ConnCase, hex_evaluator) to ensure demo walkthrough and adoption path are bulletproof. Pre-pilot hardening complete. Defaulting to Hold.

**Post-v1.30 maintenance (2026-05-30, direct PRs — not a milestone):** Cut and published **0.7.0**; fixed the operator-surface timeline crash on `?correlation_id=` that had kept the v1.30 Playwright job (Phase 132) red; hardened the release pipeline (`verify-release-shape`, `post-publish-distribution-sync`, bootstrap CI); made the test suite deterministic (retention-pruner + telemetry flakes fixed, `mix verify.flake` + nightly Flake Detection workflow). See `STATE.md` → Roadmap Evolution.

**Non-goals:** External pilot without signal (v1.28); compliance DEFER trio; second reference app.

## Phases

<details>
<summary>✅ v1.30 Adoption Evidence Automation (Phases 131-133) — SHIPPED 2026-05-29</summary>

- [x] Phase 131: ConnCase §5 + walkthrough tighten — completed 2026-05-29
- [x] Phase 132: Playwright gap suite + CI job — completed 2026-05-29
- [x] Phase 133: Evaluator playbook + doc contracts — completed 2026-05-29

Full phase details: `.planning/milestones/v1.30-ROADMAP.md`

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
| ----- | --------- | -------------- | ------ | --------- |
| 131 ConnCase §5 + walkthrough tighten | v1.30 | - | Complete | 2026-05-29 |
| 132 Playwright gap suite + CI job | v1.30 | - | Complete | 2026-05-29 |
| 133 Evaluator playbook + doc contracts | v1.30 | - | Complete | 2026-05-29 |
