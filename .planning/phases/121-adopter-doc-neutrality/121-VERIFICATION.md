---
phase: 121-adopter-doc-neutrality
phase_name: Adopter Doc Neutrality
verified_at: "2026-05-28"
status: passed
score: 15/15
requirements:
  - ADOPT-AUTH-01
  - ADOPT-AUTH-02
  - ADOPT-AUTH-03
plans_verified:
  - 121-01
  - 121-02
---

# Phase 121 Verification Report

## Goal Achievement

**Status: passed**

Phase 121 goal — auth-neutral adopter docs with host-owned `Threadline.Plug` wiring first, phx.gen.auth and Sigra as peer optional reference lanes, and CI-backed doc-contract locks — is **achieved**. Both plans executed; all three ADOPT-AUTH requirements satisfied.

---

## Must-Haves vs Codebase

### Plan 121-01 (ADOPT-AUTH-01)

| Truth / Artifact | Expected | Verified |
|------------------|----------|----------|
| §5 opens with host-owned plug fence | `MyApp.Audit` callbacks, not Sigra default | PASS |
| Sigra router excerpt scoped | Only after `getting-started-sigra-reference-fence` marker | PASS |
| §6 generic auth-before-plug contract | Lane table + 401/403 teaching; curl labeled sigra-reference only | PASS |
| Next reads links phx alongside sigra | `guides/integrations/phx-gen-auth.md` in Next reads | PASS |
| Doc contract: no whole-guide router assert | `router_block/0` scoped to optional subsection test only | PASS |
| `guides/getting-started-saas.md` | Auth-neutral §5/§6, lane pointers, optional Sigra fence | PASS |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | Neutrality asserts + scoped fence test | PASS |

### Plan 121-02 (ADOPT-AUTH-02, ADOPT-AUTH-03)

| Truth / Artifact | Expected | Verified |
|------------------|----------|----------|
| README four-lane Start here | `capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, `sigra-reference` | PASS |
| README groups phx + sigra as optional reference | `Phoenix auth (reference lanes, pick one)` bullet; no standalone `Using Sigra:` | PASS |
| Evaluating guide neutrality + phx link | `phx-gen-auth-reference`, host vs maintainer proof split | PASS |
| `phx_gen_auth_doc_contract_test.exs` | ~12–18 asserts locking guide markers and host-owned literals | PASS (17 asserts) |
| `mix verify.doc_contract` includes phx contract | Registered in `mix.exs` alias | PASS |
| `README.md` | Four-lane discovery map | PASS |
| `guides/evaluating-threadline.md` | Evaluator neutrality + phx link | PASS |
| `mix.exs` | `phx_gen_auth_doc_contract_test.exs` in verify alias | PASS |

---

## Requirement Traceability

| Requirement | Status | Evidence |
|-------------|--------|----------|
| **ADOPT-AUTH-01** | PASS | `guides/getting-started-saas.md` §5 hero `MyApp.Audit` plug; Sigra callbacks only in optional subsection; §6 lane table + `<details>` sigra-reference curl; `getting_started_saas_doc_contract_test.exs` neutrality + scoped fence tests |
| **ADOPT-AUTH-02** | PASS | `README.md` four-lane Start here + grouped Phoenix auth bullet; `guides/evaluating-threadline.md` phx link and host-owned auth proof; `readme_doc_contract_test.exs` and `evaluating_threadline_doc_contract_test.exs` ADOPT-AUTH-02 test |
| **ADOPT-AUTH-03** | PASS | `phx_gen_auth_doc_contract_test.exs` (3 tests, 17 asserts); getting-started neutrality strings locked; `mix verify.doc_contract` green |

Cross-reference: `.planning/REQUIREMENTS.md` lists ADOPT-AUTH-01 as pending in traceability table — implementation is complete; table should be updated to `[x]` on next REQUIREMENTS sync.

---

## Automated Verification (2026-05-28)

| Check | Command | Result |
|-------|---------|--------|
| Doc contracts | `mix verify.doc_contract` | PASS — 86 tests, 0 failures |
| Getting-started contract | `mix test test/threadline/getting_started_saas_doc_contract_test.exs` | PASS — 4 tests, 0 failures |
| Hero plug literal | `grep 'actor_fn: &MyApp.Audit.actor_ref_from_conn/1' guides/getting-started-saas.md` | PASS |
| Sigra-first opening removed | `grep 'The Phoenix example keeps' guides/getting-started-saas.md` | PASS — exit 1 |
| Sigra curl label | `grep 'sigra-reference example app only' guides/getting-started-saas.md` | PASS |
| README four-lane | `grep 'phx-gen-auth-reference' README.md` | PASS |
| README no Sigra-first bullet | `grep 'Using Sigra:' README.md` | PASS — exit 1 |
| phx assert count | `grep -c 'assert ' test/threadline/integrations/phx_gen_auth_doc_contract_test.exs` | PASS — 17 |
| upgrade-path four lanes | `grep 'phx-gen-auth-reference' guides/upgrade-path.md` in Who section | PASS |

---

## Gaps

None identified.

---

## Human Verification

None required. Optional spot-check: read §5/§6 in `guides/getting-started-saas.md` for cognitive order (contract → lane choice → optional runnable reference) — content matches plan intent on filesystem review.

---

## Self-Check

**Self-Check: PASSED** — 15/15 plan must-haves verified against filesystem and test output; all three ADOPT-AUTH requirements satisfied.
