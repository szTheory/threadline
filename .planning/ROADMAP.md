# Roadmap: Threadline

## Milestones

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

Earlier milestones are recorded in MILESTONES.md and their archives under milestones/.

## Current Position

The latest published package is Hex 1.1.0. v1.47 is a completed planning milestone and local Git tag; it shipped no package release because no merge changed the shipped package. No milestone is active. REL-01's next-release clause is bound to the first natural release (see the archived 247.1-REL01-EVIDENCE.md): that release PR's first CI run must be green with no separate CHANGELOG-dating PR.

## Next

Re-derive the baseline using .planning/MILESTONE-GUIDE.txt and .planning/MILESTONE-ARC.md, then start `/gsd-new-milestone`. MILESTONE-ARC rank 2 is v1.48 Safe by default (operator surface fail-closed, txid-reuse detection, CSV/header hardening, Elixir 1.17 / OTP 27 floor) as 1.2.0; its first releasable merge is also REL-01's trigger.
