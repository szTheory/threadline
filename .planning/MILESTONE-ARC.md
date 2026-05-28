# Milestone Arc: Threadline

**Updated:** 2026-05-28
**Active milestone:** **v1.28 External Pilot** (queued — signal-gated; Phases 125–127 close v1.27 audit hygiene)
**Next ranked candidate:** **v1.28 External Pilot** when sustained real-adopter signal exists

## Strategic thesis

With v1.26 shipped, phx.gen.auth reach wedge is closed (guide + root CI proof). The library is **~90–93% done** for its stated narrow audit-platform scope. Hex.pm lists **0.6.0** (Phase 122); v1.27 closed distribution + first-hour doc gaps. Gap phases 125–127 address planning hygiene and optional example :schemas demo.

The v1.22 **real-adopter-first** rule re-engages on first sustained external signal (see PROJECT.md Key Decisions). Until then: one thin synthetic milestone (v1.27) to close release + first-hour truth, then adopter-driven maintenance.

## Option record

| Rank | Option | Recommendation | Why |
|------|--------|----------------|-----|
| 1–9 | _(prior shipped)_ | **Shipped** | See arc order table |
| 10 | Auth lane breadth (phx.gen.auth) | **Shipped (v1.26)** | Cookbook + root CI proof; four-lane matrix complete |
| 11 | Distribution & first-hour finish | **Shipped (v1.27)** | Hex 0.6.0 publish + `ecto_repos` doc + v1.26 audit doc carry-forward |
| 12 | External pilot | **When signal exists (v1.28)** | Pilot unblockers + STG host matrices — not synthetic scope |
| 13 | Hex 0.6.0 publish | **Part of v1.27 or maintainer parallel** | Tag-triggered `hex-publish.yml`; backlog Pending until hex.pm shows 0.6.0 |

## Arc order

| Version | Status | Theme | Why now | Unlocks | Non-goals |
|---------|--------|-------|---------|---------|-----------|
| v1.26 | **shipped** | Auth Lane Breadth | Closed phx.gen.auth reach gap without second reference app. | Four-lane matrix; reduced integrator friction for majority Phoenix auth. | Second full reference app; Threadline-owned auth/RBAC. |
| v1.27 | **shipped** | Distribution & First-Hour Finish | In-repo done ≠ adopter can install/evaluate; `ecto_repos` hole; Hex lag. | Honest "done for scope"; evaluator path from Hex 0.6.0. | External pilot; compliance expansion; new product surface. |
| v1.28 | **queued (signal-gated)** | External Pilot | First sustained real-adopter signal. | Concrete host blockers; STG truth. | Synthetic walkthrough v2; compliance expansion. |

## Activation rules

- When `/gsd-new-milestone` runs without stronger context, recommend **v1.27 Distribution & First-Hour Finish** from this file unless sustained adopter signal exists (then **v1.28 pilot-first**).
- **Do not** open compliance-pack / legal-hold / immutable-archive milestones without procurement pressure.
- **Do not** open Pow/bearer auth lane or second reference app without explicit demand.
- Keep this file updated at milestone open/close and when strategic ordering changes.
