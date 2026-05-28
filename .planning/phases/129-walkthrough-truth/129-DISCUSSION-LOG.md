# Phase 129: WALKTHROUGH Truth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-28
**Phase:** 129-WALKTHROUGH Truth
**Areas discussed:** verify.threadline cwd strategy, row-history URL presentation, doc-contract strictness, phase scope boundary (all four — user requested full research + one-shot recommendations)

---

## verify.threadline cwd strategy (WALK-01)

| Option | Description | Selected |
|--------|-------------|----------|
| A — root `cd` + `mix verify.threadline` | Explicit repo-root cwd before CI alias | |
| B — remove verify lines | Delete optional verify mentions | |
| C — `mix threadline.verify_coverage` from example cwd | Host task checks correct repo/tables | ✓ |
| D — example-app `verify.threadline` wrapper alias | Duplicate alias in example mix.exs | |

**User's choice:** Option C (agent-researched recommendation; user requested decisive one-shot package)
**Notes:** Root `verify.threadline` passes against `Threadline.Test.Repo` / `threadline_ci_coverage_canary`, not help-desk tables on `ThreadlinePhoenix.Repo`. Option A would be a silent false positive. Aligns with Phase 113 `verify.*` = CI-only namespace and existing `verify.evidence` → `threadline.evidence.show` WALKTHROUGH fix. §0 adds contributor-vs-walk cwd split with CONTRIBUTING cross-link.

---

## Row-history URL presentation (WALK-02)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Hybrid (Do: navigation + canonical; tables: labeled shorthand) | Mirror operator-surface.md SSOT | ✓ |
| B — all canonical URLs everywhere | Replace every `/audit/rows/` | |
| C — shorthand in Do + inline hint | Parenthetical navigation note | |
| D — §0 footnote only | Leave step URLs unchanged | |

**User's choice:** Option A
**Notes:** Shipped route is `/audit/transactions/:id/history/:table/:record_id`; no `/audit/rows/` mount. Contextual drill-down pattern (Sentry/Grafana) — Do steps must not tempt paste of 404 URLs. Operator tables keep shorthand for scannability with canonical in Drill-down column. New §0 "Row history URLs" subsection.

---

## Doc-contract strictness (WALK-03)

| Option | Description | Selected |
|--------|-------------|----------|
| A — extend walkthrough_doc_contract_test.exs | Two-tier locks + refutes in existing file | ✓ |
| B — new walkthrough_truth_contract_test.exs | Separate file | |
| C — minimal locks only | Assert canonical + cwd, skip refutes | |

**User's choice:** Option A
**Notes:** Phase 128 two-tier model (footgun locks + semantic refutes). Gate via `verify.example` (already runs example-app tests). Do not add to root `verify.doc_contract` alias list.

---

## Phase scope boundary

| Option | Description | Selected |
|--------|-------------|----------|
| A — WALKTHROUGH.md only | Phase boundary per ROADMAP | ✓ (primary) |
| B — also update example README | Fix repeated lies | |
| C — WALKTHROUGH cross-link to operator-surface §179 | SSOT pointer | ✓ (minimal, in Further reading) |

**User's choice:** A + minimal C
**Notes:** Example README already honest (no verify.threadline, no /audit/rows URLs). README stays map; WALKTHROUGH stays executable runbook.

---

## Claude's Discretion

- Exact prose for §0 row-history subsection and operator-table relabeling
- WALK-04-02 step 5: "Repeat WALK-03-01 step 6" vs inline rewrite
- Optional router cross-check in contract test

## Deferred Ideas

- PROJECT.md L167 mounted-route wording drift
- Repo-wide shorthand purge in operator-surface guide
- Example-app verify.threadline wrapper alias
