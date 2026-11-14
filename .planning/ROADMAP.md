# Roadmap: Threadline

## Milestones

- [x] **v1.48 Threadline Admin: brand and complete journeys** — Completed planning 2026-11-13; six phases, 36 plans, 34/34 requirements. PR #105 merged as `b9dba172`; repair PR #107 merged as `5fcac23`. [Archive](milestones/v1.48-ROADMAP.md), [audit](milestones/v1.48-MILESTONE-AUDIT.md). The natural 1.2.0 handoff passed REL-01; release PR #106 squash-merged as `93d57ddb` and GitHub published tag/release v1.2.0. Hex publication still awaits `production-hex` approval; Hex lists 1.1.0.
- [x] **v1.47 Release on autopilot** — Phases 244–247.1; completed 2026-10-29. Five phases (including gap phase 247.1), 66 plans, 68 tasks, 13/14 requirements; REL-01 deferred-with-trigger (accepted at close). Audit: tech_debt. No package release (no merge changed the shipped package; Hex stays 1.1.0). Roadmap archive: milestones/v1.47-ROADMAP.md; requirements: milestones/v1.47-REQUIREMENTS.md; audit: milestones/v1.47-MILESTONE-AUDIT.md.
- [x] **v1.46 Operator UI Refinement** — Phases 238–243; completed 2026-10-11. Six phases, 27 plans, 49 tasks, 26/26 requirements. Audit: tech_debt, with no unmet requirements or broken flows. Roadmap archive: milestones/v1.46-ROADMAP.md; requirements: milestones/v1.46-REQUIREMENTS.md; audit: milestones/v1.46-MILESTONE-AUDIT.md.
- [x] **v1.45 1.0 API Contract** — Phases 231–237; shipped as 1.0.0 on 2026-10-07. Archive: milestones/v1.45-ROADMAP.md.
- [x] **v1.44 Behavioral Depth: Properties, Twins, Telemetry** — Phases 224–230; shipped as 0.12.0 on 2026-10-02. Archive: milestones/v1.44-ROADMAP.md.
- [x] **v1.43 Supply Chain, CI Economy and Repo Hygiene** — Phases 214–223; shipped as 0.11.1 and 0.11.2 on 2026-09-30. Archive: milestones/v1.43-ROADMAP.md.
- [x] **v1.42 Capture Correctness for Real Table Shapes** — Phases 208–213; shipped as 0.11.0 on 2026-09-26. Archive: milestones/v1.42-ROADMAP.md.
- [x] **v1.41 Green, Clean, and Honest** — Phases 198–207; shipped on 2026-09-24. Archive: milestones/v1.41-ROADMAP.md.
- [x] **v1.40 Automated Operator-UI Critique and Forward-Only Iteration Harness** — Phases 194–197; shipped on 2026-08-27. Archive: milestones/v1.40-ROADMAP.md.
- [x] **v1.39 Quality Baseline, Schema Confidence, and CI Efficiency** — Phases 189–193; shipped on 2026-07-03. Archive: milestones/v1.39-ROADMAP.md.
- [x] **v1.38 Operator UI Page-by-Page IA and Design-System Polish** — Phases 181–188; shipped on 2026-06-30. Archive: milestones/v1.38-ROADMAP.md.
- [x] **v1.37 Operator Surface Design-System Stress Test and Component System** — Phases 171–180; shipped on 2026-06-20. Archive: milestones/v1.37-ROADMAP.md.
- [x] **v1.36 Operator Surface Light Mode** — Phases 166–170; shipped on 2026-06-14. Archive: milestones/v1.36-ROADMAP.md.
- [x] **v1.35 Unified Logo and Brand Book v2** — Phases 159–165; shipped on 2026-06-12. Archive: milestones/v1.35-ROADMAP.md.
- [x] **v1.34 Local Docker Admin UI DX** — Phases 154–158; shipped on 2026-06-07. Archive: milestones/v1.34-ROADMAP.md.


Earlier milestones are recorded in [MILESTONES](MILESTONES.md).

## Current position

No active implementation phase or new milestone is selected. v1.48 completes all six phases 248–253, 36 plan contributions and 34 requirements, with independent goal/integration verification and required candidate CI green. [Closeout](milestones/v1.48-CLOSEOUT.md) preserves exact evidence and historical limits. PR #105 is merged; the implementation is on main.

## Next

[REL-01](milestones/v1.47-phases/247.1-close-gap-rel-01-rel-02-releasable-type-guard-and-release-pr/247.1-REL01-EVIDENCE.md) is observed: the release PR carried its own Unreleased prose, the release workflow dated it, no separate changelog-dating PR merged, and required CI passed on final head `032aea5`. PR #106 is merged and GitHub published v1.2.0; the Release workflow verified main CI and is waiting at the protected `production-hex` approval, while Hex still lists 1.1.0. The post-release baseline found repeated min/latest partition imbalance, so the lane weights were refreshed locally from the last three main runs. A reviewed PR must get the change onto main before the next three ratios can verify it; the scheduled flake detector should confirm its Playwright setup fix before milestone selection. “Remaining Safe by default” remains provisional. Keep v1.48 archived and complete.
