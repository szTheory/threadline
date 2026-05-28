# Phase 118: Pilot Prep (Optional) — Research

**Researched:** 2026-05-27  
**Phase:** 118-pilot-prep-optional  
**Requirements:** PILOT-01, PILOT-02

## Summary

Phase 118 is a **doc-authority + contract** slice for external evaluators and pilot hosts. CONTEXT decisions are locked: remove stale test counts from adoption-pilot backlog; cite **named `mix verify.*` entrypoints** only; add thin `guides/evaluating-threadline.md` with README map links; extend doc-contract tests. No library APIs.

**Primary recommendation:** Two parallel plans — **118-01** (PILOT-01 backlog refresh + contracts), **118-02** (PILOT-02 evaluating guide + README/ExDoc + contracts) — each ships prose + contracts in one changeset (Phase 117 pattern).

---

## Current State (verified)

| Area | Status |
|------|--------|
| `guides/adoption-pilot-backlog.md` L5 | Stale **`136 tests`** in evidence pass paragraph |
| `guides/adoption-pilot-backlog.md` L126–134 | **In-repo parity** omits `verify.credo`, `verify.compile_no_optional`, `verify.example` |
| `mix.exs` `ci.all` L88–96 | Order: `verify.format` → `verify.credo` → compile strict → `verify.compile_no_optional` → `verify.test` → `verify.threadline` → `verify.example` → `verify.doc_contract` |
| `test/threadline/adoption_pilot_doc_contract_test.exs` | Version SSOT + upgrade-path link only — **no** entrypoint or stale-count refutes |
| `guides/evaluating-threadline.md` | **Missing** |
| `README.md` L18 | Evaluating bullet points to HexDocs only |
| `README.md` Documentation list | No evaluating guide entry |
| `mix.exs` ExDoc extras L178–194 | No `guides/evaluating-threadline.md` |
| `mix.exs` `verify.doc_contract` L80–81 | No `evaluating_threadline_doc_contract_test.exs` |
| D-117-02g evaluator sentence | Lives in `guides/upgrade-path.md` L5 — reuse verbatim in evaluating guide |

---

## PILOT-01: Backlog evidence refresh

**Decision (locked):** Hybrid commands + contracts; no numeric test totals.

| Work item | Target |
|-----------|--------|
| Remove stale count | Refute `136 tests` and `(\d+ tests` patterns in prose |
| Evidence pass paragraph | `DB_PORT=5433 MIX_ENV=test mix ci.all` + ordered verify steps matching `mix.exs` |
| In-repo parity § | Sync to same chain or cross-link “see Evidence pass above” + CONTRIBUTING |
| Date bump | Evidence pass date → implementation date (2026-05-27) |
| PgBouncer language | Keep unchanged (already correct) |

**Do not:** Re-assert `ci.all` ordering in adoption_pilot tests — owned by `ci_topology_contract_test.exs`.

---

## PILOT-02: Evaluator one-pager

**Decision (locked):** Thin guide (~80–120 lines) + README map; no full README band.

| Concern | Authoritative path |
|---------|-------------------|
| Evaluator journey | `guides/evaluating-threadline.md` (new) |
| 0.6.0 packaging anchor | D-117-02g sentence from `guides/upgrade-path.md` L5 |
| Three layers | Link `guides/how-threadline-works.md` |
| Host boundaries | Link `guides/production-checklist.md`, `CONTRIBUTING.md` § Host STG evidence |
| STG templates | Link `guides/adoption-pilot-backlog.md` markers `STG-HOST-TOPOLOGY-TEMPLATE`, `STG-AUDITED-PATH-RUBRIC` |
| Verify ladder | Entrypoint names: `mix ci.all`, `mix verify.doc_contract`, `mix verify.example` |

**Guide outline (8 sections):** Who this is for → What 0.6.0 packages → Three layers → Maintainer CI-class proof → Integrator host-class proof → Verify ladder → Explicit non-claims → Pilot next step.

**Must-not:** STG rubric table bodies; maintainer STG attestation; `v1.2x` milestone labels; compliance-ready language.

---

## PILOT doc-contract extensions (D-118-04)

| Test module | New / extended behavior |
|-------------|-------------------------|
| `adoption_pilot_doc_contract_test.exs` | `refute` `136 tests` / `~r/\(\d+ tests/`; `assert` `mix ci.all`, `mix verify.doc_contract`, core verify steps, `CONTRIBUTING.md` pointer |
| `evaluating_threadline_doc_contract_test.exs` | **New** — guide exists; D-117-02g literals; verify ladder; `host-owned`; STG markers; outward links; refute maintainer STG attestation phrasing |
| `readme_doc_contract_test.exs` | `assert` link to `guides/evaluating-threadline.md` in Start here or Documentation |
| `mix.exs` | Append evaluating contract to `verify.doc_contract`; add ExDoc extra |

**Pattern:** Phase 117 minimal-plus — literal asserts, scoped refutes, no paragraph snapshots.

---

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Quick run** | `mix test test/threadline/adoption_pilot_doc_contract_test.exs test/threadline/evaluating_threadline_doc_contract_test.exs` |
| **Gate command** | `mix verify.doc_contract` |
| **Full CI slice** | `mix ci.all` (optional post-phase) |

**Per-requirement verification:**

| REQ | Automated command | Signal |
|-----|-------------------|--------|
| PILOT-01 | `rg '136 tests|\(\d+ tests' guides/adoption-pilot-backlog.md` → empty; `mix test test/threadline/adoption_pilot_doc_contract_test.exs` exit 0 | Entrypoints not counts |
| PILOT-02 | `test -f guides/evaluating-threadline.md`; `mix test test/threadline/evaluating_threadline_doc_contract_test.exs` exit 0 | One-pager + contracts |
| Both | `mix verify.doc_contract` exit 0 | Gate green |

---

## Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Duplicating `ci.all` order asserts | adoption_pilot tests assert presence only; order owned by `ci_topology_contract_test.exs` |
| Evaluating guide bloat / README collision | Locked 80–120 line target; README map link only (D-118-02b/c) |
| False-positive STG attestation refute | Scope refute to evaluating guide with `~r/maintainer.*STG.*(attest|certif)/i` |
| ExDoc / alias drift | Single 118-02 task wires both in `mix.exs` |

---

## Plan decomposition (recommended)

| Plan | Wave | Scope |
|------|------|-------|
| 118-01 | 1 | PILOT-01 adoption-pilot-backlog prose + adoption_pilot_doc_contract_test |
| 118-02 | 1 | PILOT-02 evaluating guide + README + mix.exs + evaluating/readme contracts |

Plans are parallel — no file overlap except shared gate `mix verify.doc_contract` run at end of each plan.

---

## RESEARCH COMPLETE
