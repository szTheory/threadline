# Milestone Arc: Threadline

**Updated:** 2026-05-06
**Active milestone:** v1.18 — Adoption and Policy Hardening (opened 2026-05-06, continuing phase numbering from Phase 64)
**Standing recommendation after v1.18 ships:** Open **v1.19 — Integration Breadth** next, with the `threadline_web` companion-package extraction as the leading candidate once the in-tree operator surface has live adopters.

## Strategic thesis

With v1.17 shipped and v1.18 active, the question has shifted from "is there a usable surface?" to "is the surface easy to roll out, upgrade, and govern in production?" v1.18 closes that loop with: full filter parity on a raw timeline browse, exports-from-current-view parity, drift-aware policy viewers (coverage + redaction), and lifecycle ergonomics. The standing posture is read-only throughout, zero new platform infrastructure, and Mix-task parity for every UI viewer so capture-only adopters never lose access.

The standing recommendation is therefore:

1. Finish v1.18 (raw timeline browse + filter form, exports UI parity, coverage dashboard, drift-aware redaction admin, lifecycle ergonomics).
2. After v1.18 ships, broaden reach via integration breadth + the `threadline_web` companion-package extraction once the in-tree surface has live adopters (v1.19).
3. Add heavier-duty governance / scale knobs only after v1.18's adoption and v1.19's integration story is proven (v1.20+). Retention admin (deferred from v1.18 because it requires net-new `audit_retention_runs` capture machinery) lives here unless a v1.19 capture-surface decision pulls it forward.

## Option record

These are the standing milestone directions and the recommended order to revisit them:

| Rank | Option | Recommendation | Why |
|------|--------|----------------|-----|
| 1 | Operator UX / UI surface | **Shipped (v1.17)** | The core investigation contract was stable enough to support a real operator-facing surface; v1.17 delivered the mountable in-tree LiveView with two must-have screens, row history sub-view, fail-closed auth, and Mix-task parity. |
| 2 | Onboarding + lifecycle hardening | **In progress (v1.18)** | Now that a concrete operator surface ships, first-hour adoption and production rollout ergonomics are the sharpest gap — raw timeline browse + filter form, exports UI parity, drift-aware policy viewers, and the onboarding/upgrade-path docs rollup. |
| 3 | Framework breadth / more adapters | **Do next after v1.18** | Once adoption is hardened, expanding reach (more auth/framework adapters, the `threadline_web` companion split once the in-tree surface has live adopters) is the next leverage point. |
| 4 | Production confidence / governance defaults | **After integration breadth settles** | Heavier governance knobs (retention admin with capture machinery, runtime policy controls, scale dashboards) inform better once adopters exercise the operator + integration loop in real host apps. |
| 5 | Policy / compliance depth | **Later** | SIEM-grade reporting / compliance depth is best informed by real adopter pain, not speculative scoping. |

## Arc order

| Version | Status | Theme | Why now | Unlocks | Non-goals |
|---------|--------|-------|---------|---------|-----------|
| v1.16 | **shipped** | Investigation Table Stakes | Closed the gap between capture and usable incident/support workflows. | Operator surface work, stronger onboarding, future investigation-specific integrations. | Full LiveView UI, new auth adapters, retention redesign. |
| v1.17 | **shipped** | Operator Surface Foundation | The investigation contract was stable enough to support a host-usable surface instead of docs-only composition. Mountable in-tree LiveView surface with optional Phoenix/LiveView deps; incident drill-down + actor window must-have screens; host-mount-default auth with optional `:authorize_fn`; `mix threadline.incident` parity. | Raw timeline browse + filter form, exports UI parity, drift-aware policy viewers, lifecycle ergonomics — i.e. v1.18. | Reinventing tenancy/authorization; broad frontend framework work; separate `threadline_web` package (deferred to v1.19+). |
| v1.18 | **active** | Adoption and Policy Hardening | After operator workflows shipped, tighten lifecycle ergonomics, raw-timeline + filter form, exports parity, and safer read-only policy defaults for production teams. Read-only throughout; zero new platform infrastructure; Mix-task parity for every viewer. | Cleaner pilots, better upgrade confidence, easier ops sign-off; clean ground for v1.19 integration breadth and the `threadline_web` extraction conversation. | Saved views; queued/Oban-based exports; retention admin (needs new capture surface — deferred to v1.19+); runtime policy edits in any viewer; new storage backend or CDC/WAL architecture. |
| v1.19 | **next** | Integration Breadth | Expand reach only after the core investigation + operator story is easier to adopt repeatedly. Earliest reasonable home for the `threadline_web` companion-package extraction once the in-tree surface has live adopters. Possible home for the deferred retention admin if the capture surface is decided here. | Additional auth/framework adapters and host patterns; companion-package split. | Weakening the auth-agnostic core or hard-coupling Threadline to one stack. |
| v1.20 | candidate | Scale and Governance Depth | Add the heavier-duty knobs once the core adoption and operator loop is proven. Likely home for queued/Oban-based exports if real adopters report row-cap pain. | More enterprise-friendly retention/policy/reporting work. | Turning Threadline into a SIEM or general analytics product. |

## Activation rules

- When `/gsd-new-milestone` runs and no stronger context exists, recommend the highest-priority non-shipped milestone in this file.
- If the user wants to pivot, record the pivot here instead of relying on conversation memory.
- Prefer tightening an existing candidate milestone over inventing a disconnected one.
- Keep this file updated whenever a milestone is opened or a major strategic ordering decision changes.
