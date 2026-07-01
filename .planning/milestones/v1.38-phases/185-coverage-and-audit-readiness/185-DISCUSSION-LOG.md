# Phase 185: Coverage and audit readiness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-29
**Phase:** 185-coverage-and-audit-readiness
**Areas discussed:** Readiness hierarchy, Remediation actions, Schema workflow, Proof and regression scope

---

## Readiness Hierarchy

| Option | Description | Selected |
|--------|-------------|----------|
| Current trust rail plus metrics grid plus remediation | Lowest code churn and reuses existing tests/CSS, but repeats the readiness signal across multiple blocks. | |
| Verdict-card/summary | One first-viewport answer with selected schema, checked-at metadata, counts, and next step. Table remains for row triage. | yes |
| Table-first | Best for row comparison, but buries the primary verdict and increases mobile scan cost. | |
| Dashboard-like metrics | Familiar numeric scan, but optimizes for "how many?" instead of "can I rely on this schema?" | |

**User's choice:** Discuss/consider all; use subagents and produce a cohesive recommendation so the user does not need to make piecemeal choices.

**Notes:** Subagent research recommended one consolidated selected-schema verdict summary. This aligns with Phase 185 success criteria, Threadline brand posture, GOV.UK summary-list/table separation, Carbon data-table hierarchy, and Phoenix function-component/URL-state idioms. Repeated page-level "needs capture" signals are the key current footgun.

---

## Remediation Actions

| Option | Description | Selected |
|--------|-------------|----------|
| Row-level Add capture | Exact table context and safe per-row command copy, but too repetitive as the only page-level path. | |
| One page-level remediation path | Clear next step, but too generic alone and risks unsafe all-table commands. | |
| Hybrid selected-schema remediation | One schema-level next step plus contextual row-level Add capture disclosures. | yes |
| Covered-row Timeline links | Useful contextual investigation handoff for covered rows, but not remediation. | yes, covered rows only |

**User's choice:** Discuss/consider all; emphasize DX, operator UX, footguns, architecture, and coherent recommendations.

**Notes:** The selected model keeps a short schema-level remediation instruction in the verdict, exact row-level `Add capture` for uncovered rows, and `View activity` only for covered rows. Generic page-level Timeline CTAs are rejected because they compete with the readiness job and can imply incomplete data is reliable.

---

## Schema Workflow

| Option | Description | Selected |
|--------|-------------|----------|
| Native select/dropdown, URL-backed `?schema=` | Constrains normal selection to known schemas, keeps shareable URL state, and uses native controls. | yes |
| Free text input with `<datalist>` | Supports paste-by-name but is not a true constraint and has accessibility/browser inconsistency risk. | |
| Schema tabs | Visible for a tiny fixed set, but wrong for dynamic tenant schemas and adds APG/mobile complexity. | |
| Route/list of schema links | URL-native, but bloats the page and risks route churn. | |

**User's choice:** Discuss/consider all; account for Phoenix/Plug/Ecto library idioms, consumer perspective, and least surprise.

**Notes:** The selected workflow keeps `/audit/coverage?schema=NAME`, validates untrusted schema names at the UI/CLI edge, preserves invalid URLs with a recovery path, and makes `checked_at` selected-schema-specific. The surface header badge remains public-schema-only as documented.

---

## Proof And Regression Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Broad screenshot matrix | High visual confidence but slow, brittle, and misaligned with prior anti-matrix decisions. | |
| Targeted Coverage state lattice | Proves COV-01..03 directly with focused source/LiveView/doc/browser coverage. | yes |
| Source/LiveView only | Fast and deterministic but misses mobile/action layout regressions. | |
| Stress-ledger ratchet only | Good for generic states, but synthetic fixtures cannot prove live schema URL/refresh/link behavior. | |

**User's choice:** Discuss/consider all; use product, UI/UX, accessibility, engineering, DevOps/SRE, and verification lenses.

**Notes:** The selected proof model covers public/non-public schema URL state, invalid schema, refresh/stale last-good behavior, empty schema, covered/uncovered/expected rows, contextual links, and mobile disclosure/no-overflow proof. Existing stress/ledger/theme/permission proof remains in its current lanes unless Phase 185 changes those semantics.

---

## Claude's Discretion

- Exact helper names, CSS selector names, component extraction, test file split, and plan slicing remain planner discretion.
- The planner may decide whether the readiness verdict is a local private function component or inline markup, as long as route/test-id/component boundaries remain stable.
- Exact final copy can be tuned during planning/implementation, but it must preserve the locked meanings and avoid overclaims.

## Deferred Ideas

- Coverage trend/SLO dashboard.
- Schema tabs.
- Route-level schema inventory or `/coverage/:schema`.
- Free-text schema search as a fallback for very large schema lists.
- Broad screenshot matrix.
- Generic page-level Timeline CTAs from Coverage.
