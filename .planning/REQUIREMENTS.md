# Requirements: Threadline v1.27 — Distribution & First-Hour Finish

**Defined:** 2026-05-28
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Milestone goal:** Close the gap between "library is built in-repo" and "adopter can evaluate and wire the first hour from Hex and docs without maintainer context."

**Assessment source:** `.planning/threads/2026-05-28-milestone-next-step-post-v1.26.md`

---

## v1 Requirements

### Distribution truth (Phase 122)

- [x] **DIST-01**: Maintainer publishes **`threadline` 0.6.0** to hex.pm via tag **`v0.6.0`** and CI `hex-publish.yml`; post-publish verification recorded (adoption-pilot or milestone closeout note).
- [x] **DIST-02**: `guides/adoption-pilot-backlog.md` **Published** row and distribution preflight reflect **0.6.0** on hex.pm (not stale 0.5.0-only narrative).
- [x] **DIST-03**: `CHANGELOG.md` 0.6.0 entry mentions **four-lane** adopter matrix including **`phx-gen-auth-reference`** (v1.26 carry-forward for evaluator honesty).

### First-hour config (Phase 123)

- [ ] **CFG-01**: `guides/getting-started-saas.md` documents `config :threadline, ecto_repos: [MyApp.Repo]` in the Base install path (before mix tasks that call `resolve_repo!/0`).
- [ ] **CFG-02**: Doc-contract test locks `ecto_repos` literal and placement in getting-started (e.g. `getting_started_saas_doc_contract_test.exs`).
- [ ] **CFG-03**: `guides/production-checklist.md` cross-links the `ecto_repos` requirement for mix tasks and operator-surface fallbacks.

### Adopter doc finish (Phase 124)

- [ ] **DOC-01**: Getting-started **§6** cookie/session staging is auth-neutral or explicitly lane-branched (`phx-gen-auth-reference` vs `sigra-reference`); Sigra-only curl prose is not the only path.
- [ ] **DOC-02**: `getting_started_saas_doc_contract_test.exs` asserts strict ADOPT-AUTH literals (e.g. "does not require Sigra", `phx-gen-auth-reference`) — closes v1.26 audit soft-gap.
- [ ] **DOC-03**: `guides/operator-surface.md` documents mount **`:schemas`** required for row-history reification at `/audit/rows/:table/:pk`.
- [ ] **DOC-04**: `guides/how-threadline-works.md` or `guides/domain-reference.md` states evidence plane is **host-written** (lib does not auto-populate from retention/health/export).
- [ ] **DOC-05**: `guides/integration-contracts.md` four-lane vocabulary matches `guides/upgrade-path.md` (`capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, `sigra-reference`); doc-contract locks lane names.

---

## v2 Requirements

Deferred until after v1.27 or on signal.

- **EXTERNAL-PILOT (v1.28)** — unblockers when sustained real-adopter signal exists
- **Pow / bearer auth lane** — on explicit demand
- **v1.22 DEFER trio** — compliance packs, legal hold, immutable archive (procurement pressure only)
- **Evidence auto-population** from retention/health — only with explicit adopter signal
- **IN-110-003** — `:agent2` manifest hardening (optional, no milestone)

---

## Out of Scope

| Feature | Reason |
|---------|--------|
| External pilot / STG host matrices | v1.28 — signal-gated |
| Compliance packs / legal hold / immutable archive | DEFER trio — no procurement signal |
| Second reference app | v1.26 pattern: docs + contracts |
| Pow / bearer auth adapter | On demand only |
| Evidence auto-write from ops paths | Host-write boundary; docs-only in v1.27 |
| New capture / Evidence subjects | Finish milestone, not platform expansion |
| Automated Hex publish policy change | Tag-triggered workflow unchanged |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DIST-01 | 122 | Complete |
| DIST-02 | 122 | Complete |
| DIST-03 | 122 | Complete |
| CFG-01 | 123 | Pending |
| CFG-02 | 123 | Pending |
| CFG-03 | 123 | Pending |
| DOC-01 | 124 | Pending |
| DOC-02 | 124 | Pending |
| DOC-03 | 124 | Pending |
| DOC-04 | 124 | Pending |
| DOC-05 | 124 | Pending |

**Coverage:**
- v1 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-28*
*Last updated: 2026-05-28 after roadmap creation*
