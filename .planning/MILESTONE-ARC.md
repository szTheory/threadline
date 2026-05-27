# Milestone Arc: Threadline

**Updated:** 2026-05-27
**Active milestone:** v1.25 — Adopter-Ready Release & First-Hour Truth (started 2026-05-27)
**Next ranked candidate:** v1.25 release & first-hour truth (synthetic); then v1.26 auth lane breadth; external pilot when sustained signal exists

## Strategic thesis

With v1.24 shipped, the manual audited-transaction foot-gun is closed (`Threadline.Audit.transaction/3` + reference/doc truth). The library is ~88–92% done for its stated narrow scope. The highest-leverage synthetic wedge is **Hex release truth + first-hour doc/example alignment** (0.6.0), not compliance expansion. **phx.gen.auth breadth** is the largest remaining adopter-reach gap (v1.26). The v1.22 real-adopter-first rule re-engages on first sustained external signal (see PROJECT.md Key Decisions).

## Option record

These are the standing milestone directions and the recommended order to revisit them:

| Rank | Option | Recommendation | Why |
|------|--------|----------------|-----|
| 1 | Operator UX / UI surface | **Shipped (v1.17)** | The core investigation contract was stable enough to support a real operator-facing surface; v1.17 delivered the mountable in-tree LiveView with two must-have screens, row history sub-view, fail-closed auth, and Mix-task parity. |
| 2 | Onboarding + lifecycle hardening | **Shipped (v1.18)** | v1.18 completed the rollout-hardening loop: raw timeline browse + filter form, exports UI parity, drift-aware policy viewers, and onboarding/upgrade-path docs plus final-tree CI evidence. |
| 3 | Framework breadth / more adapters | **Shipped (v1.19)** | Once adoption is hardened, the next leverage point is reusable host patterns, auth/framework adapters, and a disciplined package-boundary decision. |
| 4 | Production confidence / governance defaults | **Shipped (v1.20)** | v1.20 delivered governance schemas, retention runtime closure, actor-owned saved views, built-in async exports, and truthful Oban/S3 adapter seams on the repaired final tree. |
| 5 | Scoped support/operator adoption lane | **Shipped (v1.21)** | v1.21 turned the host-owned `scope_query_fn` seam into a truthful first-party support lane on the shipped `/audit` surface, including scoped row history / as-of proof and export denial posture. |
| 6 | Policy / compliance depth | **Shipped (v1.22)** | Shipped durable evidence records and audit-of-audit posture after the support-safe adopter lane proved out — without broadening into a Threadline-owned platform expansion. |
| 7 | Audited write-path ergonomics | **Shipped (v1.24)** | Packaged manual transaction recipe into `Threadline.Audit.transaction/3`; reference app and doc truth for 0.5.x evaluators. |
| 8 | Adopter-ready release & first-hour truth | **Recommended (v1.25)** | Hex 0.5.0 lags in-repo stack; narrative docs and example README still friction-heavy; evaluators need 0.6.0 + aligned crash course. |
| 9 | Auth lane breadth (phx.gen.auth) | **Queued (v1.26)** | Most Phoenix SaaS teams are unclaimed outside sigra-reference; cookbook + proof path is highest reach expansion. |
| 10 | External pilot | **When signal exists** | First sustained real-adopter signal → pilot unblockers, not synthetic scope. |

## Arc order

| Version | Status | Theme | Why now | Unlocks | Non-goals |
|---------|--------|-------|---------|---------|-----------|
| v1.16 | **shipped** | Investigation Table Stakes | Closed the gap between capture and usable incident/support workflows. | Operator surface work, stronger onboarding, future investigation-specific integrations. | Full LiveView UI, new auth adapters, retention redesign. |
| v1.17 | **shipped** | Operator Surface Foundation | The investigation contract was stable enough to support a host-usable surface instead of docs-only composition. Mountable in-tree LiveView surface with optional Phoenix/LiveView deps; incident drill-down + actor window must-have screens; host-mount-default auth with optional `:authorize_fn`; `mix threadline.incident` parity. | Raw timeline browse + filter form, exports UI parity, drift-aware policy viewers, lifecycle ergonomics — i.e. v1.18. | Reinventing tenancy/authorization; broad frontend framework work; separate `threadline_web` package (deferred to v1.19+). |
| v1.18 | **shipped** | Adoption and Policy Hardening | After operator workflows shipped, tighten lifecycle ergonomics, raw-timeline + filter form, exports parity, and safer read-only policy defaults for production teams. Read-only throughout; zero new platform infrastructure; Mix-task parity for every viewer. | Cleaner pilots, better upgrade confidence, easier ops sign-off; clean ground for v1.19 integration breadth and the `threadline_web` extraction conversation. | Saved views; queued/Oban-based exports; retention admin (needs new capture surface — deferred to v1.19+); runtime policy edits in any viewer; new storage backend or CDC/WAL architecture. |
| v1.19 | **shipped** | Integration Breadth | Expand reach only after the core investigation + operator story is easier to adopt repeatedly. Use the in-tree optional web surface as the stable base, broaden host patterns, and define objective extraction triggers instead of forcing a package split. | Additional auth/framework adapters and host patterns; a cleaner future `threadline_web` decision if real evidence appears. | Weakening the auth-agnostic core, adding hard runtime deps, or pulling governance/UI-state expansion into the milestone. |
| v1.20 | **shipped** | Scale and Governance Depth | Added governance schemas, batched retention with operator history, actor-owned saved views, built-in background exports, and truthful adapter-backed export delivery without taking over optional Oban/S3 runtime ownership. | Better enterprise readiness, stronger lifecycle controls, and a cleaner base for policy/compliance depth. | Turning Threadline into a SIEM or general analytics product. |
| v1.21 | **shipped** | Scoped Support / Operator Proof | The highest-leverage remaining adopter gap was a proven tenant-safe support lane on the shipped `/audit` surface. v1.21 stayed narrow: productized the mount contract, not the auth model, and closed on proof-first rerun evidence. | Stronger SaaS support adoption, clearer tenant-safe operator guidance, a truthful support-safe claim on the current tree, and a firmer base for later compliance-proof work. | Threadline-owned RBAC or tenancy DSLs, broad policy engines, SIEM positioning, separate support route families, or unrelated new UI families. |
| v1.22 | **shipped** | Policy / Evidence Plane | After the support-safe lane is proven, strengthen durable policy snapshots and audit-of-audit evidence so Threadline stands up better to enterprise scrutiny without broadening into a compliance platform. | More credible export/retention/policy proof, better procurement posture, cleaner later sink-hook work if needed. | Legal-hold platform work, immutable storage guarantees, generic compliance packs, vendor-specific reporting suites, or Threadline-owned RBAC/tenancy semantics. |
| v1.23 | **shipped** | Realistic-Demo Walkthrough | Synthetic-first-adopter override of v1.22's real-adopter-first rule — no real adopter exists and the alternative is shipping nothing. | Walkthrough-surfaced design gaps as v1.24 seeds; first concrete fix-vs-defer rule in practice; durable boundary against scope creep tested under synthetic pressure. | No new Evidence subjects, no Threadline-owned RBAC/tenancy DSLs, no `lib/` auth or domain code, no "demo product" rebrand, no Sigra integration extension absent contract gap. Re-engages v1.22 rule on first sustained real-adopter signal. |
| v1.24 | **shipped** | Audited Write Path & Adopter Truth | Capture+semantics+operator stack strong; #1 foot-gun was manual transaction recipe. Shipped helper + doc truth without DEFER compliance work. | Easier first-hour adoption; honest sigra-reference including `/audit/evidence`; evaluators see 0.5.x-aligned pilot docs. | No new Evidence subjects; no compliance packs / legal hold / immutable archive; no second walkthrough; no Threadline-owned RBAC; no help-desk product expansion. |
| v1.25 | **recommended** | Adopter-Ready Release & First-Hour Truth | Hex 0.5.0 stale vs v1.22–v1.24; crash course lags `Audit.transaction/3`; example README friction. Release-and-truth milestone, not feature expansion. | Truthful Hex evaluators; aligned first-hour path; optional pilot-prep. | DEFER trio; new Evidence subjects; container walk unless demand; `threadline_web` split. |
| v1.26 | **queued** | Auth Lane Breadth | phx.gen.auth is the majority Phoenix lane but unclaimed in upgrade-path; largest reach gap after release truth. | Non-Sigra adopters get proof path; reduced translation tax from sigra-reference. | Second full reference app; Threadline-owned auth. |

## Activation rules

- When `/gsd-new-milestone` runs and no stronger context exists, recommend **v1.25** from this file unless sustained adopter signal exists (then pilot-first).
- If the user wants to pivot, record the pivot here instead of relying on conversation memory.
- Prefer tightening an existing candidate milestone over inventing a disconnected one.
- Keep this file updated whenever a milestone is opened or a major strategic ordering decision changes.
