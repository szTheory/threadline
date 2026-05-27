# Phase 117: Evidence Plane Doc Authority — Research

**Researched:** 2026-05-27  
**Phase:** 117-evidence-plane-doc-authority  
**Requirements:** DOC-01, DOC-02, DOC-03

## Summary

Phase 117 is a **doc-authority + contract** phase, not a library feature phase. CONTEXT decisions are already locked: **no** `guides/evidence-plane.md` hub; README `## Evidence plane` remains the adopter entry; fix maintainer phantom paths; semver-not-milestone in adopter guides; surgical incident JSON step 1; minimal-plus doc-contract extensions; wire orphaned `exploration_routing_doc_contract_test.exs` into `mix verify.doc_contract`.

**Primary recommendation:** Two-wave execution — **wave 1** prose/maintainer fixes, **wave 2** doc-contract locks + alias wiring — so contracts are written against final prose.

---

## Current State (verified)

| Area | Status |
|------|--------|
| README `## Evidence plane` | Aligned — links how-threadline-works, upgrade-path, domain-reference; locked by `readme_doc_contract_test.exs` |
| `guides/how-threadline-works.md` Evolution | Prose has `0.5.0` / `0.6.0` bullets; **no** doc-contract locks yet |
| `guides/getting-started-saas.md` | `### Recommended path (v1.24+)` — milestone label in adopter path |
| `guides/upgrade-path.md` | `v1.21` lane prose, `v1.19` packaging scorecard; **missing** `0.5.x → 0.6.x` minor bullet |
| `guides/domain-reference.md` L274 | Incident step 1 cites `record_action/2` only — contradicts blessed write path |
| `.planning/PROJECT.md` L33 | Phantom `guides/evidence-plane.md` in shipped-milestone bullet |
| `exploration_routing_doc_contract_test.exs` | Exists; **not** in `mix.exs` `verify.doc_contract` alias |
| Adopter paths `evidence-plane.md` | No hits in README/guides (maintainer-only drift) |

---

## DOC-01: Entry point architecture

**Decision (locked):** Split-guide map, no hub file.

| Concern | Authoritative path |
|---------|-------------------|
| Scope / non-goals | `guides/how-threadline-works.md` |
| Lanes / `/audit/evidence` | `guides/upgrade-path.md` |
| Proof vocabulary | `guides/domain-reference.md` |
| Mount / auth / CLI | `guides/operator-surface.md` |
| Exercises | `examples/threadline_phoenix/WALKTHROUGH.md` §5 |

**Work:** Fix `.planning/PROJECT.md` (and batch stale `@guides/evidence-plane.md` in `.planning/milestones/` only when touching). Do **not** add ExDoc extra or hub file.

---

## DOC-02: Semver vocabulary

**Adopter files to scrub `v1.2x`:**

- `guides/getting-started-saas.md` — heading `v1.24+` → `0.6.0+` or timeless “Audit.transaction/3”
- `guides/upgrade-path.md` — `v1.21` → `0.5.0` lane era; `v1.19` scorecard → `0.5.0` or timeless + CHANGELOG pointer

**Add under `## Upgrade by Threadline minor`:**

> `0.5.x → 0.6.x`: Evidence plane (`Threadline.Evidence`, `mix threadline.evidence.show`, `/audit/evidence`), recommended audited write path (`Threadline.Audit.transaction/3`); see `CHANGELOG.md` `[0.6.0]` for deprecated manual GUC + `record_action/2` recipe.

**Allowlist (do not mass-scrub):** `guides/domain-reference.md` API-era section titles (`v1.10+`, `Phase 13`, etc.).

**Optional:** one-line maintainer mapping in CONTRIBUTING or `.planning/` only.

---

## DOC-03: Doc-contract minimal-plus

| Test module | New / extended behavior |
|-------------|-------------------------|
| `how_threadline_works_doc_contract_test.exs` | Evolution section: `` `0.5.0` ``, `` `0.6.0` ``, Evidence plane + `Audit.transaction/3`, ordering |
| `upgrade_path_doc_contract_test.exs` | `0.5` / `0.6` / `Audit.transaction/3` or `Evidence` under minor upgrades |
| `readme_doc_contract_test.exs` or `semver_adopter_doc_contract_test.exs` | `refute ~r/v1\.2[0-9]/` on README, getting-started, how-threadline-works, upgrade-path |
| `exploration_routing_doc_contract_test.exs` | After `COMP-EXAMPLE-INCIDENT-JSON`, scoped `Audit.transaction/3` in incident subsection |
| `mix.exs` | Append `exploration_routing_doc_contract_test.exs` to `verify.doc_contract` |

**Pattern:** Phase 115 `:binary.match` with `scope:` for section-bounded asserts (incident JSON, Evolution, minor upgrades).

---

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Mix) |
| **Quick run** | `mix test test/threadline/how_threadline_works_doc_contract_test.exs` (per touched file) |
| **Gate command** | `mix verify.doc_contract` |
| **Full CI slice** | `mix ci.all` (optional post-phase) |

**Per-requirement verification:**

| REQ | Automated command | Signal |
|-----|-------------------|--------|
| DOC-01 | `rg -l 'guides/evidence-plane.md' README.md guides/` → empty; PROJECT.md lists real guide paths | No adopter dead hub |
| DOC-02 | `rg 'v1\.2[0-9]' guides/getting-started-saas.md guides/upgrade-path.md` → empty | Semver prose |
| DOC-03 | `mix verify.doc_contract` exit 0 | Contracts green |

---

## Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Semver refute breaks domain-reference allowlist | Exclude `guides/domain-reference.md` from refute paths |
| Incident contract too broad | Scope `binary.match` to lines after `COMP-EXAMPLE-INCIDENT-JSON` only |
| Evolution test brittle on wording | Lock literals from existing Evolution bullets (D-117-04 table) |

---

## Plan decomposition (recommended)

| Plan | Wave | Scope |
|------|------|-------|
| 117-01 | 1 | DOC-01 maintainer refs + DOC-02 prose + domain-reference incident step |
| 117-02 | 2 | DOC-03 contracts + `mix.exs` alias + `mix verify.doc_contract` |

---

## RESEARCH COMPLETE
