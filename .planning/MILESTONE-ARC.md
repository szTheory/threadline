# Milestone Arc: Threadline

**Updated:** 2026-05-27
**Active milestone:** v1.26 — Auth Lane Breadth (started 2026-05-27)
**Next ranked candidate:** v1.26 auth lane breadth (in progress); external pilot when sustained signal exists; Hex 0.6.0 publish (maintainer tag)

## Strategic thesis

With v1.25 shipped, in-repo release truth and first-hour docs align on `Threadline.Audit.transaction/3` and **0.6.0** packaging. The library is **~88–92% done** for its stated narrow audit-platform scope. The largest remaining **adopter-reach** gap is **phx.gen.auth-style auth lane proof** (most Phoenix SaaS teams are outside `sigra-reference`). **Hex.pm still lists 0.5.0** as of 2026-05-27 — push tag `v0.6.0` for CI publish; adoption-pilot backlog tracks Pending until live.

The v1.22 **real-adopter-first** rule re-engages on first sustained external signal (see PROJECT.md Key Decisions). Until then, avoid large synthetic milestones beyond narrow proof wedges.

## Option record

| Rank | Option | Recommendation | Why |
|------|--------|----------------|-----|
| 1–8 | _(prior shipped)_ | **Shipped** | See arc order table |
| 9 | Adopter-ready release & first-hour truth | **Shipped (v1.25)** | 0.6.0 in-repo SSOT, narrative/example/evaluator alignment |
| 10 | Auth lane breadth (phx.gen.auth) | **Active (v1.26)** | Largest reach gap; cookbook + CI proof without second reference app |
| 11 | External pilot | **When signal exists** | Pilot unblockers + STG host matrices — not synthetic scope |
| 12 | Hex 0.6.0 publish | **Maintainer ops** | Tag-triggered `hex-publish.yml`; backlog Pending until hex.pm shows 0.6.0 |

## Arc order

| Version | Status | Theme | Why now | Unlocks | Non-goals |
|---------|--------|-------|---------|---------|-----------|
| v1.25 | **shipped** | Adopter-Ready Release & First-Hour Truth | Closed synthetic first-hour wedge (0.6.0 packaging, narrative, example, evidence doc authority, evaluator one-pager). | Honest evaluator path; v1.26 auth breadth. | DEFER trio; phx.gen.auth (deferred to v1.26); second walkthrough. |
| v1.26 | **active** | Auth Lane Breadth | Majority Phoenix lane unclaimed; translation tax from sigra-reference is #1 reach gap. | `phx-gen-auth-reference` lane; reduced integrator friction. | Second full reference app; Threadline-owned auth/RBAC; replacing Sigra example. |
| v1.27 | **queued** | External Pilot | First sustained real-adopter signal. | Concrete host blockers; STG truth. | Synthetic walkthrough v2; compliance expansion. |

## Activation rules

- When `/gsd-new-milestone` runs without stronger context, recommend **v1.26** from this file unless sustained adopter signal exists (then pilot-first).
- **Do not** open compliance-pack / legal-hold / immutable-archive milestones without procurement pressure.
- Keep this file updated at milestone open/close and when strategic ordering changes.
