# Requirements: Threadline v1.29 — First-Hour Parity

**Defined:** 2026-05-28
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Milestone goal:** Eliminate remaining adopter-facing first-hour footguns and close non-blocking verify/planning debt — without pretending to be a pilot or expanding product surface.

**Assessment source:** `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md`

---

## v1 Requirements

### README + first-hour config parity (Phase 128)

- [x] **README-01**: `README.md` Quick Start documents `config :threadline, ecto_repos: [MyApp.Repo]` before mix tasks that call `resolve_repo!/0`, with a cross-link to getting-started §2.
- [x] **README-02**: Doc-contract test locks README `ecto_repos` literal and placement (e.g. extend `readme_doc_contract_test.exs`).
- [x] **TRIG-01**: README Quick Start trigger registration step cross-links getting-started or production-checklist for table-selection SSOT (no divergent trigger-table guidance).

### phx-gen-auth mount parity (Phase 128)

- [x] **AUTH-MOUNT-01**: `guides/integrations/phx-gen-auth.md` mount snippet uses scope-first `authorize_fn` shape consistent with getting-started §9 and `phx_gen_auth_integration_test.exs` (not legacy `current_user.role` string-only pattern as the primary example).
- [x] **AUTH-MOUNT-02**: Doc-contract test locks phx-gen-auth mount literals and scope-first posture (extend or add integration guide contract test).

### WALKTHROUGH truth (Phase 129)

- [ ] **WALK-01**: `examples/threadline_phoenix/WALKTHROUGH.md` runs `mix verify.threadline` from repo root (or documents cwd explicitly if a wrapper is introduced) — alias lives on root `mix.exs`, not example app.
- [ ] **WALK-02**: WALKTHROUGH row-history URLs match shipped transaction-scoped route (`/audit/transactions/:id/history/:table/:record_id`) or clearly label shorthand vs canonical path with navigation steps from transaction drill-down.
- [ ] **WALK-03**: Doc-contract test locks WALKTHROUGH verify cwd and row-history URL truth (extend `walkthrough_doc_contract_test.exs` or dedicated contract).

### Verify/planning hygiene (Phase 130)

- [ ] **NYQ-01**: `.planning/phases/125-authority-surface-reconciliation/125-VALIDATION.md` signed `nyquist_compliant: true` with green verification bundle recorded.
- [ ] **PLAN-01**: Phase SUMMARY frontmatter convention documents `requirements_completed` values; existing v1.27 phase SUMMARY files updated or a single planning convention note added so closeout metadata is not ambiguous.

---

## v2 Requirements

Deferred until after v1.29 or on signal.

- **EXTERNAL-PILOT (v1.28)** — unblockers when sustained real-adopter signal exists
- **Pow / bearer auth lane** — on explicit demand
- **v1.22 DEFER trio** — compliance packs, legal hold, immutable archive (procurement pressure only)
- **Evidence auto-population** from retention/health — only with explicit adopter signal
- **IN-110-003** — `:agent2` manifest hardening (optional, no milestone)
- **Second phx.gen.auth reference app** — guide + root CI proof pattern sufficient

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| External pilot / STG host matrices | v1.28 — signal-gated |
| Compliance packs / legal hold / immutable archive | DEFER trio — no procurement signal |
| Second reference app | v1.26 pattern: docs + contracts |
| Pow / bearer auth adapter | On demand only |
| Evidence auto-write from ops paths | Host-write boundary unchanged |
| New capture / Evidence subjects | Hygiene milestone, not platform expansion |
| Hex semver bump | No library API change required |
| Synthetic walkthrough v2 | WALKTHROUGH truth only, not new fiction |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| README-01 | 128 | Complete |
| README-02 | 128 | Complete |
| TRIG-01 | 128 | Complete |
| AUTH-MOUNT-01 | 128 | Complete |
| AUTH-MOUNT-02 | 128 | Complete |
| WALK-01 | 129 | Pending |
| WALK-02 | 129 | Pending |
| WALK-03 | 129 | Pending |
| NYQ-01 | 130 | Pending |
| PLAN-01 | 130 | Pending |

**Coverage:**

- v1 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-28*
*Last updated: 2026-05-28 after milestone v1.29 initialization*
