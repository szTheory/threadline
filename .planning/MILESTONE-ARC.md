# Milestone Arc: Threadline

**Updated:** 2026-05-06
**Active milestone:** v1.17 — Operator Surface Foundation (Phases 57-63, opened 2026-05-06)
**Standing recommendation after v1.17 ships:** Open **v1.18 — Adoption and Policy Hardening** next.

## Strategic thesis

With v1.17 active, the operator surface contract is being stood up on top of v1.16's stable investigation APIs. Once it ships, the next adoption gap moves from "is there a usable surface?" to "is the surface easy to roll out, upgrade, and govern in production?" — that is what v1.18 should target.

The standing recommendation is therefore:

1. Finish v1.17 (mountable in-tree LiveView surface, two must-have screens + row history sub-view, Mix task, fail-closed auth contract).
2. After v1.17 ships, tighten onboarding, lifecycle ergonomics, and policy guardrails for production teams (v1.18).
3. Broaden integrations and governance depth only after that operator loop is real and proven (v1.19+).

## Option record

These are the standing milestone directions after v1.16 shipped and the recommended order to revisit them:

| Rank | Option | Recommendation | Why |
|------|--------|----------------|-----|
| 1 | Operator UX / UI surface | **In progress (v1.17)** | The core investigation contract is now stable enough to support a real operator-facing surface without API churn. |
| 2 | Onboarding + lifecycle hardening | **Do next after v1.17** | Once a concrete operator surface ships, first-hour adoption + production rollout ergonomics become the sharpest gap. |
| 3 | Production confidence / governance defaults | **After the operator loop hardens** | Important, but better informed once adopters are actually using the operator surface in host apps. |
| 4 | Framework breadth / more adapters | **After core operator adoption settles** | More adapters widen reach, but the main product gap is still usability after install. |
| 5 | Policy / compliance depth | **Later** | Better informed once real adopters exercise the operator workflows in host applications. |

## Arc order

| Version | Status | Theme | Why now | Unlocks | Non-goals |
|---------|--------|-------|---------|---------|-----------|
| v1.16 | **shipped** | Investigation Table Stakes | Closed the gap between capture and usable incident/support workflows. | Operator surface work, stronger onboarding, future investigation-specific integrations. | Full LiveView UI, new auth adapters, retention redesign. |
| v1.17 | **active** | Operator Surface Foundation | The investigation contract is stable enough to support a host-usable surface instead of docs-only composition. Mountable in-tree LiveView surface with optional Phoenix/LiveView deps; incident drill-down + actor window must-have screens; host-mount-default auth with optional `:authorize_fn`. | Reference operator surface, richer demos, adoption proof. | Reinventing tenancy/authorization; broad frontend framework work; separate `threadline_web` package (deferred to v1.19+). |
| v1.18 | **next** | Adoption and Policy Hardening | After operator workflows ship, tighten lifecycle ergonomics, raw-timeline + filter form, exports parity, and safer defaults for production teams. | Cleaner pilots, better upgrade confidence, easier ops sign-off. | New storage backend or CDC/WAL architecture. |
| v1.19 | candidate | Integration Breadth | Expand reach only after the core investigation + operator story is easier to adopt repeatedly. Earliest reasonable home for the `threadline_web` companion-package extraction once the in-tree surface has live adopters. | Additional auth/framework adapters and host patterns; companion-package split. | Weakening the auth-agnostic core or hard-coupling Threadline to one stack. |
| v1.20 | candidate | Scale and Governance Depth | Add the heavier-duty knobs once the core adoption and operator loop is proven. | More enterprise-friendly retention/policy/reporting work. | Turning Threadline into a SIEM or general analytics product. |

## Activation rules

- When `/gsd-new-milestone` runs and no stronger context exists, recommend the highest-priority non-shipped milestone in this file.
- If the user wants to pivot, record the pivot here instead of relying on conversation memory.
- Prefer tightening an existing candidate milestone over inventing a disconnected one.
- Keep this file updated whenever a milestone is opened or a major strategic ordering decision changes.
