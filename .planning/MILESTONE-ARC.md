# Milestone Arc: Threadline

**Updated:** 2026-06-06 (milestone v1.34 opened)
**Active milestone:** **v1.34 Local Docker Admin UI DX**
**Next ranked candidate:** **Hold** after v1.34; **v1.28** when sustained real-adopter signal exists

## Strategic thesis

With v1.29 shipped, first-hour parity and verify/planning hygiene wedge is closed (README `ecto_repos`, phx-gen-auth mount, WALKTHROUGH truth, Nyquist 125, SUMMARY SSOT). The library is **~92–95% done** for its stated narrow audit-platform scope (band: near-done / diminishing returns).

v1.34 is a local maintainer DX exception to the product hold posture: harden the Docker-backed `/audit` demo so multiple local admin UIs can run without port, cache, or cleanup friction. It does not reopen product scope, public brand rollout, compliance expansion, or external-pilot work.

The v1.22 **real-adopter-first** rule re-engages on first sustained external signal (see PROJECT.md Key Decisions). **No adopter signal today** — do not open v1.28. Default: **hold**; stop building synthetic product milestones.

**Assessment thread:** `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md`

## Option record

| Rank | Option | Recommendation | Why |
|------|--------|----------------|-----|
| 1–9 | _(prior shipped)_ | **Shipped** | See arc order table |
| 10 | Auth lane breadth (phx.gen.auth) | **Shipped (v1.26)** | Cookbook + root CI proof; four-lane matrix complete |
| 11 | Distribution & first-hour finish | **Shipped (v1.27)** | Hex 0.6.0 publish + `ecto_repos` doc + v1.26 audit doc carry-forward |
| 12 | External pilot | **When signal exists (v1.28)** | Pilot unblockers + STG host matrices — not synthetic scope |
| 13 | Hex 0.6.0 publish | **Shipped (v1.27)** | hex.pm 0.6.0 aligned with in-repo semver |
| 14 | First-hour parity & verify hygiene | **Shipped (v1.29)** | README `ecto_repos`, phx-gen-auth mount, WALKTHROUGH truth, Nyquist 125 — last synthetic pass before hold |
| 15 | Adoption evidence automation | **In progress (v1.30)** | ConnCase §5, Track A golden path, Playwright gaps — automation debt on existing demo fiction |
| 16 | Local Docker Admin UI DX | **Active (v1.34)** | Make the existing `/audit` demo easy to start, refresh, inspect, stop, and run beside other local Docker projects |

## Arc order

| Version | Status | Theme | Why now | Unlocks | Non-goals |
|---------|--------|-------|---------|---------|-----------|
| v1.26 | **shipped** | Auth Lane Breadth | Closed phx.gen.auth reach gap without second reference app. | Four-lane matrix; reduced integrator friction for majority Phoenix auth. | Second full reference app; Threadline-owned auth/RBAC. |
| v1.27 | **shipped** | Distribution & First-Hour Finish | In-repo done ≠ adopter can install/evaluate; `ecto_repos` hole; Hex lag. | Honest "done for scope"; evaluator path from Hex 0.6.0. | External pilot; compliance expansion; new product surface. |
| v1.28 | **queued (signal-gated)** | External Pilot | First sustained real-adopter signal. | Concrete host blockers; STG truth. | Synthetic walkthrough v2; compliance expansion. |
| v1.29 | **shipped** | First-Hour Parity & Verify Hygiene | Last adopter-facing doc footguns post-v1.27. | README/quick-path parity; WALKTHROUGH truth; Nyquist 125. | New product surface; pilot pretense. |
| v1.30 | **in progress** | Adoption Evidence Automation | Close WALKTHROUGH §5 + LiveView E2E gaps on existing demo. | Full §1–§5 CI proof; evaluator playbook. | Walkthrough v2; new domain; host STG pretense. |
| v1.34 | **active** | Local Docker Admin UI DX | Multiple local Elixir library demos make port conflicts, stale containers, and rebuild costs painful. | One-command `/audit` demo; project-scoped stacks; printed routes; clearer cleanup. | Traefik default; product UI changes; public brand rollout. |

## Path to done

Sequence to diminishing returns (~95%+), then stop major milestones:

1. **Now (~92–95%)** — v1.29 shipped; core JTBD + Hex 0.6.0 + first-hour spine + verify hygiene credible.
2. **Hold** — default now; issue-driven maintenance only.
3. **v1.28 on signal** — external pilot when sustained adopter signal fires.
4. **Done (~95%+)** — stop building synthetic milestones; on-demand forks only (Pow/bearer, DEFER trio, `threadline_web` extraction).

## Activation rules

- When `/gsd-new-milestone` runs without stronger context and **no adopter signal**, recommend **hold** from this file — **not v1.28**.
- When sustained adopter signal exists, recommend **v1.28 pilot-first**.
- **Do not** open compliance-pack / legal-hold / immutable-archive milestones without procurement pressure.
- **Do not** open Pow/bearer auth lane or second reference app without explicit demand.
