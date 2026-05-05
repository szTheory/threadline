# Milestone Arc: Threadline

**Updated:** 2026-05-05  
**Current recommendation:** Open **v1.16 — Investigation Table Stakes** first.

## Strategic thesis

Threadline's biggest remaining adoption deficit is no longer capture correctness or host wiring. The repo now has trigger-backed capture, semantics, retention, export, as-of reconstruction, a Phoenix reference app, and a direct Sigra path. The remaining gap is that a serious team still has to assemble its own investigation workflows from low-level primitives right after install.

The standing recommendation is therefore:

1. Package the common investigation questions into durable library APIs first.
2. Build any operator-facing surface or broader onboarding story on top of that stabilized exploration contract.
3. Broaden integrations and policy depth after the investigation backbone is easier to adopt and harder to misuse.

## Option record

These are the milestone directions considered during v1.16 planning and the recommended order to revisit them:

| Rank | Option | Recommendation | Why |
|------|--------|----------------|-----|
| 1 | Query ergonomics / investigation workflows | **Do now** | Biggest gap between "captured data exists" and "a team can answer support questions quickly." |
| 2 | Operator UX / UI surface | **Do after v1.16** | Worthwhile, but only once the underlying investigation contract is stable enough to avoid UI-driven API churn. |
| 3 | Onboarding compression | **Fold into v1.16 and revisit later** | Better docs alone will not fix the current need for custom query/controller composition. |
| 4 | Production confidence / lifecycle hardening | **After the investigation backbone** | Important for mature adopters, but less adoption-blocking than answering the first real incident cleanly. |
| 5 | Framework breadth / more adapters | **After core exploration settles** | More adapters widen top-of-funnel, but the post-install investigation story is still the sharper product gap. |
| 6 | Policy / compliance depth | **Later** | Valuable, but better informed once more operators use the stabilized exploration surface in real hosts. |

## Arc order

| Version | Status | Theme | Why now | Unlocks | Non-goals |
|---------|--------|-------|---------|---------|-----------|
| v1.16 | **active** | Investigation Table Stakes | Close the gap between capture and usable incident/support workflows. | Operator UI, stronger onboarding, future investigation-specific integrations. | Full LiveView UI, new auth adapters, retention redesign. |
| v1.17 | candidate | Operator Surface Foundation | Once exploration contracts settle, publish a host-usable investigation surface instead of docs-only composition. | `threadline_web` or equivalent reference surface, richer demos, adoption proof. | Reinventing tenancy/authorization; broad frontend framework work. |
| v1.18 | candidate | Adoption and Policy Hardening | After operator workflows are stable, tighten lifecycle ergonomics and safer defaults for production teams. | Cleaner pilots, better upgrade confidence, easier ops sign-off. | New storage backend or CDC/WAL architecture. |
| v1.19 | candidate | Integration Breadth | Expand reach only after the core investigation story is easier to adopt repeatedly. | Additional auth/framework adapters and host patterns. | Weakening the auth-agnostic core or hard-coupling Threadline to one stack. |
| v1.20 | candidate | Scale and Governance Depth | Add the heavier-duty knobs once the core adoption and operator loop is proven. | More enterprise-friendly retention/policy/reporting work. | Turning Threadline into a SIEM or general analytics product. |

## Activation rules

- When `/gsd-new-milestone` runs and no stronger context exists, recommend the highest-priority `candidate` milestone in this file.
- If the user wants to pivot, record the pivot here instead of relying on conversation memory.
- Prefer tightening an existing candidate milestone over inventing a disconnected one.
- Keep this file updated whenever a milestone is opened or a major strategic ordering decision changes.
