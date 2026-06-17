# Phase 176: Data display & operator patterns - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-17
**Phase:** 176-Data display & operator patterns
**Areas discussed:** Copy + truncation, Table overuse + responsive collapse, Data-state taxonomy, Destructive + bulk actions
**Mode:** Advisor (ADVISOR_MODE=true; technical owner → technical framing; calibration `minimal_decisive`). User directed a deep multi-lens research pass (Elixir/Phoenix/Ecto idiom, cross-ecosystem lessons + footguns, DX, UI/UX/creative/user-psychology, JTBD/persona, brand compliance) and one-shot synthesis — no per-decision bounce-back.

---

## Gray-area selection

| Option | Description | Selected |
|--------|-------------|----------|
| Copy + truncation of ugly values | DATA-01; middle-truncation + copy + title; CSP tension with `.tl-copy`/`script.ex` | ✓ |
| Table overuse + responsive collapse | DATA-01/05; table vs KV vs card; mobile collapse; coverage flatten | ✓ |
| Data-state taxonomy | DATA-03; empty/loading/error/stale/permission/no-data/unavailable | ✓ |
| Destructive + bulk action rigor | DATA-04; kebab vs inline; confirm tiers; bulk scope | ✓ |

**User's choice:** All four selected.

---

## Copy + truncation of ugly values (DATA-01)

Initial decisive rec: ref helper on existing `truncate_middle`/`secondary_ref`, value resident in `title` + `data-tl-copy`, embed-scripts escape hatch, select-all fallback.

**Deep research refinement (adopted):** five drifting ref paths exist; `data-tl-copy` currently binds `.title` by coincidence (footgun); KV/diff cells render untruncated with no copy (the real gap); `.tl-secondary-ref` has a latent CSS double-truncation; tail-biased middle truncation per value type; render `ref.full` when scripts disabled; `required` `copy_label`.

**User's choice:** Locked as synthesized (D-01..D-07).

---

## Table overuse + responsive collapse + flatten (DATA-01 + DATA-05)

Initial decisive rec: rubric (table vs `<dl>` vs card), keep `data-label` stacking + restore ARIA roles, flatten coverage card-in-card.

**Deep research refinement (adopted, with 3 corrections):** (1) do NOT add ARIA table roles — would regress mobile AT (overturns starting rec); (2) policy/redaction stays a 2-col Configured-vs-Deployed diff table, NOT a KV (overturns rubric); (3) the DATA-05 defect is a hand-rolled header + synthetic `tl-coverage-command` shell, not literal `card > card`. Extract `UI.kv/1` + `UI.data_table/1`; per-surface verdict table; "one card boundary per logical unit" + regression test.

**User's choice:** Locked as synthesized (D-08..D-12).

---

## Data-state taxonomy (DATA-03)

Initial decisive rec: extend named-family (add `loading_state`, `stale_banner`, `empty_state` variants), per-state copy, AsyncResult mapping.

**Deep research refinement (adopted, with sharpenings):** named-family beats polymorphic (consistent with shipped `error_state = empty_state variant="error"`); `stale` precedes data (not in AsyncResult switch); per-state role/aria/icon-shape/microcopy table; ok-empty must branch empty(first-run) vs no_data(filtered); preserve typed server reason; the 3 forensic distinctions enforced in copy.

**User's choice:** Locked as synthesized (D-13..D-17).

---

## Destructive + bulk actions (DATA-04)

Initial decisive rec: kebab default, no bulk, T1/T2/T3 tiers, type-to-confirm for irreversible enforced server-side.

**Deep research refinement (adopted, with refinements):** confirm token must be the object's VARIABLE id/name (never a constant "DELETE"); server re-fetches canonical token + `secure_compare` + re-check authz + scope-filter + audit-the-action + fail closed; delete today's client-only `data-confirm` prune; undo doesn't apply here (strengthens T3). Severity→tier table.

**User's choice:** Locked as synthesized (D-18..D-21).

---

## Claude's Discretion

- DATA-02 (charts/metrics + no-color-alone + time/timezone) — not selected; handled at discretion per `presentation.ex` + brand no-color-alone (D-22).
- Exact component/token/icon names, slot APIs, file locations — match `ui.ex` + 173/174/175 idioms.

## Deferred Ideas

- Sticky-first-column / horizontal-scroll table fallback — build only on real demand.
- Bulk "Export all N matching" — additive bulk only, if a real need surfaces; never bulk redact/prune.
- Live-ticking relative timestamps — requires JS; out of scope.
