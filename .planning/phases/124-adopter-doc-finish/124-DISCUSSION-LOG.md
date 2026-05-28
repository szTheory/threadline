# Phase 124: Adopter Doc Finish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 124-adopter-doc-finish
**Areas discussed:** All five (DOC-01 through DOC-05) — user requested full research + one-shot recommendations

---

## §6 session/cookie staging (DOC-01)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Collapse sigra HTTP only | Move cookie/curl to `<details>` + example README | Partial (paired with C) |
| B — Co-equal phx-gen-auth curl | Parallel open HTTP paths for both lanes | |
| C — IEx-first primary | Open §6 = IEx `Audit.transaction/3`; HTTP collapsed | ✓ |
| D — Lane-branched §6 subsections | Four subsections under §6 | |

**User's choice:** Auto-selected all areas; user requested research-backed unified recommendation without manual option picking.

**Notes:** Subagent research + ecosystem review (Oban, ExAudit, django-auditlog, Rails audited) favored IEx-first for Elixir library DX. Co-equal curl rejected (no phx proof app). Lane branches belong in upgrade-path. Sigra HTTP stays in collapsed block + `examples/threadline_phoenix/README.md` Track A.

---

## ADOPT-AUTH contract literals (DOC-02)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Extend main walkthrough test | Add ~8 asserts to 85-assert monolith | |
| B — Dedicated DOC-02 test (CFG-02 style) | New test with literals + ordering | ✓ |
| C — exploration_routing contract | Wrong guide/REQ | |
| D — evaluating_threadline only | ADOPT-AUTH-02 scope, not §5 | |

**User's choice:** Dedicated test with exact literals and `:binary.match` ordering vs sigra fence marker.

**Notes:** Locks `Threadline does not require Sigra`, lane IDs, neutrality ordering. Does not duplicate README matrix or phx guide contracts.

---

## `:schemas` mount documentation (DOC-03)

| Option | Description | Selected |
|--------|-------------|----------|
| 1 — Canonical mount block only | Add `:schemas` to primary mount example | Partial |
| 2 — Dedicated reification subsection | Full SSOT under Row History | ✓ |
| 3 — Full duplicate in getting-started §9 | Full map in walkthrough | |
| 4 — One-liner cross-link in §9 | Pointer only | ✓ (partial) |

**User's choice:** Options 1 + 2 + one-line §9 cross-link. Document two prerequisites for support row history: `scope_query_fn` + `:schemas`.

**Notes:** ExAudit/django-simple-history pattern = host registers schemas for reification. Example app `:schemas` deferred.

---

## Evidence host-write expectation (DOC-04)

| Option | Description | Selected |
|--------|-------------|----------|
| domain-reference SSOT | New section before proof contract | ✓ |
| how-threadline-works only | Mental model without reference depth | Partial (mirror + link) |
| integration-contracts only | Seam doc owns write boundary | Partial (one paragraph) |
| New evidence-plane hub | Standalone guide | Rejected (phantom hub) |

**User's choice:** domain-reference canonical; fix misleading "Threadline may persist evidence" in how-threadline-works; distinguish retention runs vs evidence records.

**Notes:** CloudTrail vs Config analogue. v1.22 non-goals preserved. Auto-population explicitly out of scope.

---

## Integration-contracts four-lane vocabulary (DOC-05)

| Option | Description | Selected |
|--------|-------------|----------|
| 1 — Compact lane section + cross-link | Names + seam map; link upgrade-path | ✓ |
| 2 — Inline capture-only paragraph only | Single lane mention | |
| 3 — Full matrix duplicate | Copy upgrade-path table | Rejected |
| 4 — Doc contract lane order lock | Canonical ID ordering + anti-matrix refute | ✓ |

**User's choice:** Phase 122 D-09 minimal pattern — enumerate IDs, link SSOT, stop. Oban Pro / Sentry tier naming precedent.

---

## Claude's Discretion

- IEx snippet polish, anchor slugs, optional README one-liner for evidence, router moduledoc if zero-cost

## Deferred Ideas

- Example app `:schemas` for walkthrough parity
- Evidence auto-population product feature
- upgrade-path lane detection prose order fix
