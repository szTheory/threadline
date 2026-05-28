---
status: passed
phase: 124-adopter-doc-finish
verified: 2026-05-28
goal: Close v1.26 audit carry-forward and operator expectation gaps so first-hour and operator docs match shipped behavior — contract-locked via doc tests (DOC-01 through DOC-05).
requirements: DOC-01, DOC-02, DOC-03, DOC-04, DOC-05
score: 9/9
---

# Phase 124 Verification Report

## Goal assessment

**Result: PASSED**

Adopter docs now match shipped behavior for §6 auth-neutral first-hour exercise, ADOPT-AUTH strict literals, `:schemas` row-history reification, evidence host-write boundary, and integration-contracts four-lane vocabulary. All five requirement IDs are satisfied in guides and locked by dedicated doc-contract tests. `mix verify.doc_contract` and targeted phase test files are green.

---

## Requirement traceability

| Requirement | Plan | Description (REQUIREMENTS.md) | Evidence | Status |
|-------------|------|-------------------------------|----------|--------|
| **DOC-01** | 124-01 | Getting-started §6 cookie/session staging is auth-neutral or lane-branched; Sigra-only curl prose is not the only path | `### Run your first audited write in IEx` @153; `### HTTP requests and host auth` @194; `_threadline_phoenix_key` only inside `<details>` after `getting-started-sigra-http-staging-fence`; dedicated DOC-01 test | ✅ |
| **DOC-02** | 124-01 | `getting_started_saas_doc_contract_test.exs` asserts strict ADOPT-AUTH literals | Test `"getting-started §5 locks auth-neutral ADOPT-AUTH literals (DOC-02)"` with D-07 literals and `:binary.match` ordering | ✅ |
| **DOC-03** | 124-02 | `guides/operator-surface.md` documents mount `:schemas` required for row-history reification | `schemas:` in admin @49 and support @83 mount blocks; `#### Row history reification (:schemas)` @184; failure UX @200; §9 link @320–323; DOC-03 test | ✅ |
| **DOC-04** | 124-03 | Evidence plane is host-written; lib does not auto-populate from retention/health/export | `## Evidence write boundary (host-written)` + `EVIDENCE-HOST-WRITE-BOUNDARY` @75–92 in domain-reference; mental-model fix @31–37; integration-contracts @174–176; operator-surface viewer @136–137; two DOC-04 tests | ✅ |
| **DOC-05** | 124-03 | integration-contracts four-lane vocabulary matches upgrade-path; doc-contract locks lane names | `## Adoption lanes and integration seams` @18–36; canonical order; `guides/upgrade-path.md` cross-link; no `\| Lane \| Claim type \|`; DOC-05 test with strictly increasing indices | ✅ |

**Coverage:** All five phase requirement IDs appear in plan frontmatter and match `REQUIREMENTS.md` traceability table. No unmapped IDs.

---

## Must-haves (124-01-PLAN — DOC-01, DOC-02)

| Truth / artifact | Check | Result |
|------------------|-------|--------|
| §6 IEx-first audited write with `demo-corr` handoff to §8; open prose has no Sigra cookie names | §6 @153–189: IEx snippet, handoff @188–189; open §6 slice refutes `_threadline_phoenix_key` (DOC-01 test) | ✅ |
| §6 HTTP subsection is `### HTTP requests and host auth` with canonical lane IDs; cookie/curl inside `<details>` only | Heading @194; lane table @207–208; fence @214 before key @223 | ✅ |
| Dedicated DOC-02 test locks ADOPT-AUTH literals and §5 ordering; monolith no longer requires open `_threadline_phoenix_key` | Tests @99–172; monolith @67 asserts HTTP heading only, no key assert | ✅ |
| Artifact: `guides/getting-started-saas.md` | §5–§6 restructured per plan | ✅ |
| Artifact: `test/threadline/getting_started_saas_doc_contract_test.exs` | 7 tests including DOC-01 and DOC-02 | ✅ |

---

## Must-haves (124-02-PLAN — DOC-03)

| Truth / artifact | Check | Result |
|------------------|-------|--------|
| 1-Minute Mount includes `schemas:` map with PostgreSQL `table_name` keys | Admin @49, support @83; `table_name` sentence @55 | ✅ |
| Row history reification subsection documents `:schemas`, failure UX, route shorthand vs drill-down, two prerequisites | Subsection @184–202 covers all plan elements | ✅ |
| Getting-started §9 links to reification SSOT without duplicating full map | @320–323: `:schemas` sentence + anchor link only | ✅ |
| Artifact: `guides/operator-surface.md` | Mount + reification SSOT present | ✅ |
| Artifact: `guides/getting-started-saas.md` (§9) | Link present | ✅ |
| Artifact: `test/threadline/operator_surface_doc_contract_test.exs` | DOC-03 test + dual-mount `schemas:` assert (`>= 2`) | ✅ |

---

## Must-haves (124-03-PLAN — DOC-04, DOC-05)

| Truth / artifact | Check | Result |
|------------------|-------|--------|
| domain-reference has `## Evidence write boundary (host-written)` with marker before proof contract | @75–92 before `## Evidence proof contract` @94 | ✅ |
| Mental-model and integration-contracts refute auto-populate evidence; operator-surface states `/audit/evidence` is viewer-only | No `Threadline may persist evidence` in guides; host-written + auto-populate refutation in how-threadline-works, integration-contracts, operator-surface | ✅ |
| integration-contracts enumerates four lanes in canonical order with upgrade-path cross-link; no matrix table duplicate | Section @18–36; indices test passes; matrix header absent | ✅ |
| Artifact: `guides/domain-reference.md` | Six `record_*` names listed; retention vs evidence distinction | ✅ |
| Artifact: `guides/how-threadline-works.md` | Host-written framing + domain-reference anchor | ✅ |
| Artifact: `guides/integration-contracts.md` | Four-lane section + host-owned evidence paragraph | ✅ |
| Artifact: `guides/operator-surface.md` | Viewer-only `/audit/evidence` sentence | ✅ |
| Artifact: `test/threadline/how_threadline_works_doc_contract_test.exs` | Two DOC-04 tests | ✅ |
| Artifact: `test/threadline/integration_contracts_doc_contract_test.exs` | DOC-05 four-lane test | ✅ |

**Must-have score: 9/9 truths verified across three plans** (artifact rows confirm file presence; no truth failures).

---

## Automated verification (2026-05-28)

```text
mix test test/threadline/getting_started_saas_doc_contract_test.exs
  test/threadline/example_phoenix_readme_contract_test.exs
  test/threadline/operator_surface_doc_contract_test.exs
  test/threadline/how_threadline_works_doc_contract_test.exs
  test/threadline/integration_contracts_doc_contract_test.exs
→ 36 tests, 0 failures

mix verify.doc_contract
→ 97 tests, 0 failures
```

---

## Phase boundary notes

- **Explicitly deferred (not gaps):** Example app `:schemas` wiring for help-desk tables (D-14); upgrade-path "How to tell which lane" prose harmonization (D-23 — no drift found). Both were out of DOC-03/DOC-05 strict scope per `124-CONTEXT.md`.
- **Dual-contract preserved:** Sigra HTTP literals remain locked in `example_phoenix_readme_contract_test.exs`; getting-started open walkthrough is auth-neutral.
- **Wave dependency satisfied:** 124-03 edited operator-surface additively after 124-02 `:schemas` section; no merge conflicts observed.

---

## Gaps

None. All phase requirements and plan must-haves verified in codebase and tests.

---

## Sign-off

| Criterion | Status |
|-----------|--------|
| Phase goal achieved | ✅ |
| DOC-01 / DOC-02 / DOC-03 / DOC-04 / DOC-05 satisfied | ✅ |
| All plan must_haves verified in codebase | ✅ (9/9) |
| Requirement IDs accounted for in REQUIREMENTS.md | ✅ |
| `mix verify.doc_contract` green | ✅ |

**Phase 124: adopter-doc-finish — VERIFIED PASSED**
