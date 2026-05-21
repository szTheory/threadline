# Milestone Arc: Threadline

**Updated:** 2026-05-21
**Active milestone:** v1.20 — Scale and Governance Depth
**Next ranked candidate:** Policy / compliance depth

## Strategic thesis

With v1.19 shipped, the focus shifts to heavier-duty scale and governance capabilities. v1.19 broadened host/framework adoption through adapter contracts, support-matrix honesty, canonical mount patterns, and a measured `threadline_web` extraction-readiness decision.

## Option record

These are the standing milestone directions and the recommended order to revisit them:

| Rank | Option | Recommendation | Why |
|------|--------|----------------|-----|
| 1 | Operator UX / UI surface | **Shipped (v1.17)** | The core investigation contract was stable enough to support a real operator-facing surface; v1.17 delivered the mountable in-tree LiveView with two must-have screens, row history sub-view, fail-closed auth, and Mix-task parity. |
| 2 | Onboarding + lifecycle hardening | **Shipped (v1.18)** | v1.18 completed the rollout-hardening loop: raw timeline browse + filter form, exports UI parity, drift-aware policy viewers, and onboarding/upgrade-path docs plus final-tree CI evidence. |
| 3 | Framework breadth / more adapters | **Shipped (v1.19)** | Once adoption is hardened, the next leverage point is reusable host patterns, auth/framework adapters, and a disciplined package-boundary decision. |
| 4 | Production confidence / governance defaults | **Active (v1.20)** | Heavier governance knobs (retention admin with capture machinery, runtime policy controls, scale dashboards) inform better once adopters exercise the operator + integration loop in real host apps. |
| 5 | Policy / compliance depth | **Next after v1.20** | SIEM-grade reporting / compliance depth is best informed by real adopter pain, not speculative scoping. |

## Arc order

| Version | Status | Theme | Why now | Unlocks | Non-goals |
|---------|--------|-------|---------|---------|-----------|
| v1.16 | **shipped** | Investigation Table Stakes | Closed the gap between capture and usable incident/support workflows. | Operator surface work, stronger onboarding, future investigation-specific integrations. | Full LiveView UI, new auth adapters, retention redesign. |
| v1.17 | **shipped** | Operator Surface Foundation | The investigation contract was stable enough to support a host-usable surface instead of docs-only composition. Mountable in-tree LiveView surface with optional Phoenix/LiveView deps; incident drill-down + actor window must-have screens; host-mount-default auth with optional `:authorize_fn`; `mix threadline.incident` parity. | Raw timeline browse + filter form, exports UI parity, drift-aware policy viewers, lifecycle ergonomics — i.e. v1.18. | Reinventing tenancy/authorization; broad frontend framework work; separate `threadline_web` package (deferred to v1.19+). |
| v1.18 | **shipped** | Adoption and Policy Hardening | After operator workflows shipped, tighten lifecycle ergonomics, raw-timeline + filter form, exports parity, and safer read-only policy defaults for production teams. Read-only throughout; zero new platform infrastructure; Mix-task parity for every viewer. | Cleaner pilots, better upgrade confidence, easier ops sign-off; clean ground for v1.19 integration breadth and the `threadline_web` extraction conversation. | Saved views; queued/Oban-based exports; retention admin (needs new capture surface — deferred to v1.19+); runtime policy edits in any viewer; new storage backend or CDC/WAL architecture. |
| v1.19 | **shipped** | Integration Breadth | Expand reach only after the core investigation + operator story is easier to adopt repeatedly. Use the in-tree optional web surface as the stable base, broaden host patterns, and define objective extraction triggers instead of forcing a package split. | Additional auth/framework adapters and host patterns; a cleaner future `threadline_web` decision if real evidence appears. | Weakening the auth-agnostic core, adding hard runtime deps, or pulling governance/UI-state expansion into the milestone. |
| v1.20 | **active** | Scale and Governance Depth | Add the heavier-duty knobs once the core adoption and operator loop is proven. Likely home for retention-admin capture machinery or queued exports if real adopters report the need. | More enterprise-friendly retention/policy/reporting work. | Turning Threadline into a SIEM or general analytics product. |

## Activation rules

- When `/gsd-new-milestone` runs and no stronger context exists, recommend the highest-priority non-shipped, non-active milestone in this file.
- If the user wants to pivot, record the pivot here instead of relying on conversation memory.
- Prefer tightening an existing candidate milestone over inventing a disconnected one.
- Keep this file updated whenever a milestone is opened or a major strategic ordering decision changes.
