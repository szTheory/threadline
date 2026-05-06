# Milestone Arc: Threadline

**Updated:** 2026-05-06  
**Current recommendation:** Open **v1.17 — Operator Surface Foundation** next.

## Strategic thesis

With v1.16 shipped, Threadline now has stable investigation workflows in the library surface as well as the prior capture, semantics, retention, export, as-of reconstruction, Phoenix reference app, and Sigra integration pieces. The sharpest remaining adoption gap is no longer raw query capability; it is the lack of a host-usable operator surface built on that now-stable exploration contract.

The standing recommendation is therefore:

1. Build the operator-facing surface on top of the stabilized exploration contract next.
2. Tighten onboarding, lifecycle, and policy ergonomics after that operator loop is real.
3. Broaden integrations and governance depth only after the operator surface proves out.

## Option record

These are the standing milestone directions after v1.16 shipped and the recommended order to revisit them:

| Rank | Option | Recommendation | Why |
|------|--------|----------------|-----|
| 1 | Operator UX / UI surface | **Do next** | The core investigation contract is now stable enough to support a real operator-facing surface without API churn. |
| 2 | Onboarding compression | **After v1.17** | Better first-hour ergonomics will matter more once there is a concrete operator surface to teach. |
| 3 | Production confidence / lifecycle hardening | **After the operator loop** | Important, but now secondary to making the shipped investigation APIs easier to use repeatedly. |
| 4 | Framework breadth / more adapters | **After core operator adoption settles** | More adapters widen reach, but the main product gap is still usability after install. |
| 5 | Policy / compliance depth | **Later** | Better informed once real adopters exercise the operator workflows in host applications. |

## Arc order

| Version | Status | Theme | Why now | Unlocks | Non-goals |
|---------|--------|-------|---------|---------|-----------|
| v1.16 | **shipped** | Investigation Table Stakes | Closed the gap between capture and usable incident/support workflows. | Operator surface work, stronger onboarding, future investigation-specific integrations. | Full LiveView UI, new auth adapters, retention redesign. |
| v1.17 | **next** | Operator Surface Foundation | The investigation contract is now stable enough to support a host-usable surface instead of docs-only composition. | `threadline_web` or equivalent reference surface, richer demos, adoption proof. | Reinventing tenancy/authorization; broad frontend framework work. |
| v1.18 | candidate | Adoption and Policy Hardening | After operator workflows are stable, tighten lifecycle ergonomics and safer defaults for production teams. | Cleaner pilots, better upgrade confidence, easier ops sign-off. | New storage backend or CDC/WAL architecture. |
| v1.19 | candidate | Integration Breadth | Expand reach only after the core investigation story is easier to adopt repeatedly. | Additional auth/framework adapters and host patterns. | Weakening the auth-agnostic core or hard-coupling Threadline to one stack. |
| v1.20 | candidate | Scale and Governance Depth | Add the heavier-duty knobs once the core adoption and operator loop is proven. | More enterprise-friendly retention/policy/reporting work. | Turning Threadline into a SIEM or general analytics product. |

## Activation rules

- When `/gsd-new-milestone` runs and no stronger context exists, recommend the highest-priority non-shipped milestone in this file.
- If the user wants to pivot, record the pivot here instead of relying on conversation memory.
- Prefer tightening an existing candidate milestone over inventing a disconnected one.
- Keep this file updated whenever a milestone is opened or a major strategic ordering decision changes.
