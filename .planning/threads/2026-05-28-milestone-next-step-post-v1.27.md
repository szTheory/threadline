# Thread: Milestone next-step assessment (post-v1.27)

**Opened:** 2026-05-28
**Status:** closed
**Outcome:** **~92% done** for stated narrow audit-platform scope (band: 90–95% near-done / diminishing returns soon). **Do not open v1.28 External Pilot** — no sustained adopter signal confirmed. Recommended path: **hold** or optional thin **v1.29 First-Hour Parity & Verify Hygiene**, then stop building synthetic milestones.

**Supersedes:** [2026-05-28-milestone-next-step-post-v1.26.md](./2026-05-28-milestone-next-step-post-v1.26.md) (v1.27 wedge closed; done-% revised to ~92%).

## Done-% judgment

- **~92%** for stated narrow audit-platform scope (post-v1.27).
- Band: **90–95% near-done / diminishing returns soon**.
- Remaining delta is **IMPORTANT-BUT-NARROW** (doc parity, pilot validation) + **LONG-TAIL POLISH** (Nyquist metadata, WALKTHROUGH shorthand) — not missing core engine.

## Repo-grounded evidence (2026-05-28)

| Finding | Severity | Source |
|---------|----------|--------|
| Hex.pm and in-repo both **0.6.0** | Resolved (v1.27) | `mix.exs`, hex.pm API, Phase 122 |
| `ecto_repos` in getting-started §2 | Resolved (v1.27) | `guides/getting-started-saas.md`, CFG doc contracts |
| README Quick Start **omits `ecto_repos`** | Adopter footgun | `README.md` — no `ecto_repos` match; getting-started has it |
| phx-gen-auth mount snippet omits canonical `scope` shape | Partial lane friction | `guides/integrations/phx-gen-auth.md` vs getting-started §9 / example router |
| WALKTHROUGH `verify.threadline` from example cwd | Doc lie | WALKTHROUGH runs alias from example dir; alias lives on root `mix.exs` |
| WALKTHROUGH `/audit/rows/` shorthand vs transaction-scoped route | Low — integration gap | v1.27 audit; shipped route is `/audit/transactions/:id/history/:table/:record_id` |
| Phase 125 Nyquist still draft | Non-blocking planning debt | `125-VALIDATION.md` `nyquist_compliant: false` |
| Example app is **sigra-reference**, not phx.gen.auth proof | Misread risk | `examples/threadline_phoenix/README.md`, upgrade-path matrix — docs honest |
| Evidence plane **host-write** only | Expectation set (v1.27) | `lib/threadline/evidence.ex`; no lib auto-population |
| Core lib surfaces shipped (not stubs) | Strong | `lib/threadline/` capture, semantics, query, export, evidence, operator surface |
| `mix ci.all` + `mix verify.example` green posture | Strong | `mix.exs` aliases; adoption-pilot ladder |

**Adopter signal today:** **None** (maintainer confirmed at assessment).

## Adopter coverage map

| Flow | Status |
|------|--------|
| Greenfield capture + Plug + query | **Well served** |
| Blessed audited write (`Audit.transaction/3`) | **Well served** |
| Operator mount admin + support scoping | **Well served** |
| phx.gen.auth lane | **Partial** — guide + root test; no runnable reference app |
| Sigra reference end-to-end | **Well served (reference lane)** |
| Evaluator from Hex without maintainer | **Well served** |
| Host prod STG / pooler truth | **Rough by design** — integrator-owned |
| External pilot / real-host friction | **Gated** — no signal |
| Compliance DEFER trio | **Out of scope** — procurement only |

## Wedge ranking

| Rank | Wedge | Verdict |
|------|-------|---------|
| 1 | **External pilot validation** | Highest leverage when signal exists — v1.28 |
| 2 | **First-hour doc parity** | README `ecto_repos`, phx-gen-auth mount, trigger table SSOT — v1.29 candidate |
| 3 | **Planning/verify hygiene** | Nyquist 125, WALKTHROUGH truth, SUMMARY frontmatter — v1.29 candidate |
| 4 | Pow / bearer auth lane | On explicit demand only |
| 5 | v1.22 DEFER trio | Procurement pressure only |

## Single pick (no adopter signal)

**Do not open v1.28 External Pilot.**

**Default:** **Hold** — adopter-driven maintenance only (~92% is defensible).

**Optional:** **v1.29 First-Hour Parity & Verify Hygiene** — one last thin synthetic pass before going quiet.

**Goal (v1.29):** Eliminate remaining adopter-facing first-hour footguns and close non-blocking verify/planning debt — without pretending to be a pilot.

**Suggested phases (continue from 128):**

1. Phase 128 — README + phx-gen-auth mount parity (`ecto_repos` in Quick Start, canonical scope mount snippet, trigger table SSOT)
2. Phase 129 — WALKTHROUGH truth (`verify.threadline` cwd, row-history URL shorthand vs shipped route)
3. Phase 130 — Nyquist finalize 125 + planning metadata convention (SUMMARY frontmatter guidance)

**Done enough (v1.29):** Evaluator following README or getting-started hits no silent config failures; doc contracts green; v1.27 audit integration gaps closed.

**Not next:** synthetic walkthrough v2, second reference app, compliance expansion, evidence auto-population, ecosystem adapters (SEED-003 retired).

## Path-to-done roadmap

| Step | Milestone | Trigger | Exit |
|------|-----------|---------|------|
| Now | post-v1.27 | Shipped | ~92% |
| Optional | **v1.29** First-Hour Parity | No pilot signal; want one hygiene pass | First-hour footguns closed |
| Default | **Hold** | After v1.29 or skip v1.29 | Issue-driven fixes only |
| On signal | **v1.28** External Pilot | Sustained adopter signal | Pilot host green on STG rubric |
| Terminal | **Done ~95%+** | After v1.29 or v1.28 | Diminishing returns — stop major milestones |
| Forks | Pow/bearer, DEFER trio, `threadline_web` | Explicit demand | Separate gates |

**Ordering after hold:**

1. Hold / adopter-driven maintenance
2. **v1.28 External Pilot** — when re-engagement trigger fires
3. Pow or bearer lane — on explicit demand
4. DEFER trio — procurement pressure only

## Re-engagement trigger (unchanged)

First **sustained** real-adopter signal (pilot host, integration issue, procurement/security review) → pivot to **v1.28 pilot unblockers**, not synthetic product milestones. See PROJECT.md Key Decisions v1.23.

## Diminishing-returns judgment

**Still high-leverage:** Real pilot feedback; README/Quick Start parity; WALKTHROUGH command truth.

**Probably polish:** Nyquist 125 metadata; PROJECT.md duplicate milestone blocks; example `actor_fn` nil for support users.

**Overbuilding:** Synthetic walkthrough v2; second reference app; compliance expansion; evidence auto-population; queued-export public API without adopter pain.

**Verdict:** Finish 0–1 last thin wedges, then mostly stop.

## Blunt maintainer takeaway

Skip v1.28 until a real pilot bites. Either go straight to **hold mode** or run one thin **v1.29**, then stop building milestones. The engine, operator surface, evidence plane, auth lanes, and Hex story are already credible for the stated narrow scope. The next meaningful work is **someone else's production stack**.

## Graduation candidates (cross-phase patterns)

- Distribution truth check (in-repo semver vs hex.pm) at every milestone assessment
- Guide + root CI proof > second reference app for auth lanes
- Doc-contract tests as adopter claim authority
- Gap-closure phases (125–127 pattern) for audit hygiene without scope creep
- `mix ci.all` + `mix verify.example` as evaluator ladder SSOT
- Assessment thread at each `/gsd-new-milestone` with path-to-done recorded in MILESTONE-ARC

## Open investigations (carry forward)

| ID | Topic | Routing |
|----|-------|---------|
| IN-110-003 | `:agent2` not on `Manifest.user_id/1` | Optional hardening; no milestone |
| STG-01 | Host staging depth | Integrator-owned; v1.28 when signal |
| WALK-URL | WALKTHROUGH row-history URL shorthand | v1.29 Phase 129 candidate |
| README-ECTO | README Quick Start `ecto_repos` gap | v1.29 Phase 128 candidate |
| PHX-AUTH-MOUNT | phx-gen-auth mount vs canonical scope shape | v1.29 Phase 128 candidate |
| NYQ-125 | Phase 125 Nyquist finalize | v1.29 Phase 130 candidate |

## Next step

Run **`/gsd-new-milestone`** when ready — scope **v1.29** (optional hygiene) or declare **hold**. Do **not** auto-open v1.28 without adopter signal.
