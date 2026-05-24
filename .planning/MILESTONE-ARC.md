# Milestone Arc: Threadline

**Updated:** 2026-05-24
**Active milestone:** v1.21 — Scoped Support / Operator Proof
**Next ranked candidate:** Policy / Evidence Plane

## Strategic thesis

With v1.19 shipped, the focus shifts to heavier-duty scale and governance capabilities. v1.19 broadened host/framework adoption through adapter contracts, support-matrix honesty, canonical mount patterns, and a measured `threadline_web` extraction-readiness decision.

## Option record

These are the standing milestone directions and the recommended order to revisit them:

| Rank | Option | Recommendation | Why |
|------|--------|----------------|-----|
| 1 | Operator UX / UI surface | **Shipped (v1.17)** | The core investigation contract was stable enough to support a real operator-facing surface; v1.17 delivered the mountable in-tree LiveView with two must-have screens, row history sub-view, fail-closed auth, and Mix-task parity. |
| 2 | Onboarding + lifecycle hardening | **Shipped (v1.18)** | v1.18 completed the rollout-hardening loop: raw timeline browse + filter form, exports UI parity, drift-aware policy viewers, and onboarding/upgrade-path docs plus final-tree CI evidence. |
| 3 | Framework breadth / more adapters | **Shipped (v1.19)** | Once adoption is hardened, the next leverage point is reusable host patterns, auth/framework adapters, and a disciplined package-boundary decision. |
| 4 | Production confidence / governance defaults | **Shipped (v1.20)** | v1.20 delivered governance schemas, retention runtime closure, actor-owned saved views, built-in async exports, and truthful Oban/S3 adapter seams on the repaired final tree. |
| 5 | Scoped support/operator adoption lane | **Next after v1.20** | The strongest remaining Phoenix SaaS adoption question is whether support can use `/audit` safely without cross-tenant leakage. The host-owned `scope_query_fn` seam is shipped; the next milestone should turn it into a first-party proven lane. |
| 6 | Policy / compliance depth | **After scoped operator proof** | Compliance depth is still valuable, but it should follow the support-safe adopter lane and stay narrow: stronger evidence records and audit-of-audit posture, not a Threadline-owned platform expansion. |

## Arc order

| Version | Status | Theme | Why now | Unlocks | Non-goals |
|---------|--------|-------|---------|---------|-----------|
| v1.16 | **shipped** | Investigation Table Stakes | Closed the gap between capture and usable incident/support workflows. | Operator surface work, stronger onboarding, future investigation-specific integrations. | Full LiveView UI, new auth adapters, retention redesign. |
| v1.17 | **shipped** | Operator Surface Foundation | The investigation contract was stable enough to support a host-usable surface instead of docs-only composition. Mountable in-tree LiveView surface with optional Phoenix/LiveView deps; incident drill-down + actor window must-have screens; host-mount-default auth with optional `:authorize_fn`; `mix threadline.incident` parity. | Raw timeline browse + filter form, exports UI parity, drift-aware policy viewers, lifecycle ergonomics — i.e. v1.18. | Reinventing tenancy/authorization; broad frontend framework work; separate `threadline_web` package (deferred to v1.19+). |
| v1.18 | **shipped** | Adoption and Policy Hardening | After operator workflows shipped, tighten lifecycle ergonomics, raw-timeline + filter form, exports parity, and safer read-only policy defaults for production teams. Read-only throughout; zero new platform infrastructure; Mix-task parity for every viewer. | Cleaner pilots, better upgrade confidence, easier ops sign-off; clean ground for v1.19 integration breadth and the `threadline_web` extraction conversation. | Saved views; queued/Oban-based exports; retention admin (needs new capture surface — deferred to v1.19+); runtime policy edits in any viewer; new storage backend or CDC/WAL architecture. |
| v1.19 | **shipped** | Integration Breadth | Expand reach only after the core investigation + operator story is easier to adopt repeatedly. Use the in-tree optional web surface as the stable base, broaden host patterns, and define objective extraction triggers instead of forcing a package split. | Additional auth/framework adapters and host patterns; a cleaner future `threadline_web` decision if real evidence appears. | Weakening the auth-agnostic core, adding hard runtime deps, or pulling governance/UI-state expansion into the milestone. |
| v1.20 | **shipped** | Scale and Governance Depth | Added governance schemas, batched retention with operator history, actor-owned saved views, built-in background exports, and truthful adapter-backed export delivery without taking over optional Oban/S3 runtime ownership. | Better enterprise readiness, stronger lifecycle controls, and a cleaner base for policy/compliance depth. | Turning Threadline into a SIEM or general analytics product. |
| v1.21 | **active** | Scoped Support / Operator Proof | The highest-leverage remaining adopter gap is a proven tenant-safe support lane on the shipped `/audit` surface. This milestone is deliberately narrow: productize the mount contract, not the auth model, and prefer proof-first closure over new product families. | Stronger SaaS support adoption, clearer tenant-safe operator guidance, a truthful support-safe claim on the current tree, and a firmer base for later compliance-proof work. | Threadline-owned RBAC or tenancy DSLs, broad policy engines, SIEM positioning, separate support route families, or unrelated new UI families. |
| v1.22 | **candidate** | Policy / Evidence Plane | After the support-safe lane is proven, strengthen durable policy snapshots and audit-of-audit evidence so Threadline stands up better to enterprise scrutiny without broadening into a compliance platform. | More credible export/retention/policy proof, better procurement posture, cleaner later sink-hook work if needed. | Legal-hold platform work, immutable storage guarantees, generic compliance packs, or vendor-specific reporting suites. |

## Activation rules

- When `/gsd-new-milestone` runs and no stronger context exists, recommend the highest-priority non-shipped, non-active milestone in this file.
- If the user wants to pivot, record the pivot here instead of relying on conversation memory.
- Prefer tightening an existing candidate milestone over inventing a disconnected one.
- Keep this file updated whenever a milestone is opened or a major strategic ordering decision changes.
