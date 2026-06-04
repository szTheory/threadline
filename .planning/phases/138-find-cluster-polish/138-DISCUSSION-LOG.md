# Phase 138: find-cluster-polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 138-find-cluster-polish
**Areas discussed:** Timeline journey and dense-first treatment, Diff/value primitive convergence, Coverage remediation model, Actor blast-radius rows

---

## Todo Cross-Reference

| Option | Description | Selected |
|--------|-------------|----------|
| Do not fold | Leave the low-confidence todo reviewed but not folded because it matched only on the generic word `polish`. | X |
| Fold | Fold `Capture direct demo and UI polish` into Phase 138 context. | |

**User's choice:** User asked to discuss and consider all gray areas; no instruction to fold the low-confidence todo.
**Notes:** The todo is represented as reviewed-but-not-folded in CONTEXT.md.

---

## Timeline Journey and Dense-First Treatment

| Option | Description | Selected |
|--------|-------------|----------|
| Deep-link the full strip | Make `FIND / EXPLAIN / PACKAGE` clickable wherever labels can map to existing destinations. | |
| Visually demote the strip | Satisfy F-403 by making the journey strip read as caption/legend and pushing rows up. | |
| Hybrid | Demote by default; deep-link only real contextual pivots; rows become first useful content. | X |
| Mobile-only collapse | Aggressively collapse chrome on 375px while keeping desktop narrative intact. | |

**User's choice:** User requested subagent-backed one-shot recommendations across all areas.
**Notes:** Advisor research recommended the hybrid. It preserves Phase 138 scope, avoids fake affordances, and prevents `PACKAGE` from implying Phase 140 closed export flow.

---

## Diff/Value Primitive Convergence

| Option | Description | Selected |
|--------|-------------|----------|
| Shared pure value primitive in `Presentation` | Centralize value semantics but keep Transaction and Row-history markup local. | X |
| Shared HEEx function component | Centralize value/KV/diff markup via function component. | |
| Formatter plus separate adapters | Use low-level formatter with separate Transaction/Row-history adapters. | |
| Local fixes only | Fix Transaction and Row-history independently. | |

**User's choice:** User requested coherent recommendations with great architecture/DX and least surprise.
**Notes:** Advisor research recommended pure presentation helpers. This avoids component-framework churn while solving repeated null/timestamp/INSERT/diff semantics.

---

## Coverage Remediation Model

| Option | Description | Selected |
|--------|-------------|----------|
| CLI snippet in uncovered rows | Put concrete commands directly in uncovered rows with secondary `View activity`. | |
| `Add capture` guidance plus command/hint | Compact remediation action with copyable/revealable command or guidance. | X |
| Diagnostic links only | Keep table clean and put consequence copy in section callout only. | |

**User's choice:** User requested all areas researched and recommendations optimized for OSS library/app DX.
**Notes:** Advisor research recommended a hybrid centered on `Add capture` guidance with real command/hint support. Browser copy must not imply in-browser code mutation.

---

## Actor Blast-Radius Rows

| Option | Description | Selected |
|--------|-------------|----------|
| Transaction-led rows with compact blast-radius metadata | Show op/table/change-count inline, keep `Open transaction` as detail pivot. | X |
| Rich inline transaction summaries | Render mini transaction reports inside Actor rows. | |
| Mostly transaction-led with secondary metadata only | Keep rows close to current implementation. | |

**User's choice:** User requested subagent-backed recommendations that move the project toward its vision.
**Notes:** Advisor research recommended compact transaction-led blast-radius rows. This closes F-703 without turning Actor into Transaction detail or changing public query contracts.

---

## the agent's Discretion

- Exact helper names and module grouping.
- Exact Timeline layout order after screenshot validation.
- Exact Coverage command copy after verifying current Mix task syntax.
- Exact Actor summary computation strategy, provided it avoids N+1 queries and misleading summaries.

## Deferred Ideas

- Phase 140: Home record-first lookup, Home correlation paste/deep-link, first-class row-history entry from Home, and closed export loop.
- Phase 142: broad responsive/mobile nav architecture.
- Phase 143: full accessibility and final consistency sweep.
