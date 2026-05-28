# Milestone Arc: Threadline

**Updated:** 2026-05-28 (milestone v1.29 opened)
**Active milestone:** **v1.29 First-Hour Parity** (v1.28 External Pilot queued — signal-gated)
**Next ranked candidate:** **Hold** after v1.29; **v1.28** when sustained real-adopter signal exists

## Strategic thesis

With v1.27 shipped, distribution + first-hour finish wedge is closed (Hex **0.6.0**, `ecto_repos` in getting-started, adopter doc finish, `:schemas` demo). The library is **~92% done** for its stated narrow audit-platform scope (band: 90–95% near-done / diminishing returns soon).

The v1.22 **real-adopter-first** rule re-engages on first sustained external signal (see PROJECT.md Key Decisions). **No adopter signal today** — do not open v1.28. Default: **hold** or one optional thin **v1.29** hygiene milestone, then stop building synthetic product milestones.

**Assessment thread:** `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md`

## Option record

| Rank | Option | Recommendation | Why |
|------|--------|----------------|-----|
| 1–9 | _(prior shipped)_ | **Shipped** | See arc order table |
| 10 | Auth lane breadth (phx.gen.auth) | **Shipped (v1.26)** | Cookbook + root CI proof; four-lane matrix complete |
| 11 | Distribution & first-hour finish | **Shipped (v1.27)** | Hex 0.6.0 publish + `ecto_repos` doc + v1.26 audit doc carry-forward |
| 12 | External pilot | **When signal exists (v1.28)** | Pilot unblockers + STG host matrices — not synthetic scope |
| 13 | Hex 0.6.0 publish | **Shipped (v1.27)** | hex.pm 0.6.0 aligned with in-repo semver |
| 14 | First-hour parity & verify hygiene | **Active (v1.29)** | README `ecto_repos`, phx-gen-auth mount, WALKTHROUGH truth, Nyquist 125 — last synthetic pass before hold |

## Arc order

| Version | Status | Theme | Why now | Unlocks | Non-goals |
|---------|--------|-------|---------|---------|-----------|
| v1.26 | **shipped** | Auth Lane Breadth | Closed phx.gen.auth reach gap without second reference app. | Four-lane matrix; reduced integrator friction for majority Phoenix auth. | Second full reference app; Threadline-owned auth/RBAC. |
| v1.27 | **shipped** | Distribution & First-Hour Finish | In-repo done ≠ adopter can install/evaluate; `ecto_repos` hole; Hex lag. | Honest "done for scope"; evaluator path from Hex 0.6.0. | External pilot; compliance expansion; new product surface. |
| v1.28 | **queued (signal-gated)** | External Pilot | First sustained real-adopter signal. | Concrete host blockers; STG truth. | Synthetic walkthrough v2; compliance expansion. |
| v1.29 | **active** | First-Hour Parity & Verify Hygiene | Last adopter-facing doc footguns post-v1.27. | README/quick-path parity; WALKTHROUGH truth; Nyquist 125. | New product surface; pilot pretense. |

## Path to done

Sequence to diminishing returns (~95%+), then stop major milestones:

1. **Now (~92%)** — v1.27 shipped; core JTBD + Hex 0.6.0 + first-hour spine credible.
2. **Optional v1.29** — thin doc/verify hygiene (Phases 128–130) if maintainer wants one structured pass before hold.
3. **Hold** — default after v1.29 or skip v1.29; issue-driven maintenance only.
4. **v1.28 on signal** — external pilot when sustained adopter signal fires; may skip v1.29 entirely if pilot arrives first.
5. **Done (~95%+)** — stop building synthetic milestones; on-demand forks only (Pow/bearer, DEFER trio, `threadline_web` extraction).

## Activation rules

- When `/gsd-new-milestone` runs without stronger context and **no adopter signal**, recommend **hold** or optional **v1.29** from this file — **not v1.28**.
- When sustained adopter signal exists, recommend **v1.28 pilot-first** and skip optional v1.29 unless pilot findings need doc hygiene first.
- **Do not** open compliance-pack / legal-hold / immutable-archive milestones without procurement pressure.
- **Do not** open Pow/bearer auth lane or second reference app without explicit demand.
- Keep this file updated at milestone open/close and when strategic ordering changes.
