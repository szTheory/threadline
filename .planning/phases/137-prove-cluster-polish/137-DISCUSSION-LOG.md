# Phase 137: prove-cluster-polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 137-prove-cluster-polish
**Areas discussed:** Export readiness model, Retention destructive-action safety, Evidence proof-card hierarchy, Cross-surface primitive strictness, Cohesive Prove cluster strategy

---

## Export readiness model

| Option | Description | Selected |
|--------|-------------|----------|
| Keep newest-first, improve card styling only | Minimal churn, but does not answer what is ready to hand off. | |
| Single list sorted by derived readiness rank | Stronger readiness signal without section chrome. | |
| Grouped readiness sections | `Ready to hand off`, `Preparing`, `Needs attention`, `Unavailable`; newest first within each group. | ✓ |
| Lifecycle groups | Queued/running/completed/failed mirror persisted status but conflate completed-expired with ready. | |
| Filter/tabs | Useful for large histories, but overbuilt for a 100-job actor-owned list. | |

**User's choice:** User asked to discuss all areas with subagent-backed research and one-shot cohesive recommendations.
**Notes:** Chosen recommendation: derived readiness groups in presentation only; `Download export` is the only solid primary action and only for completed+unexpired+file-path jobs.

---

## Retention destructive-action safety

| Option | Description | Selected |
|--------|-------------|----------|
| Keep header primary danger action | Minimal churn but unsafe visual hierarchy. | |
| Context-first layout with outline danger action | Summary/latest context precedes `Run retention prune`; browser confirm remains. | ✓ |
| Inline two-step arm state | Stronger protection but extra LiveView state for a polish phase. | |
| Modal or typed confirmation | Strongest guard but high UI/a11y/test churn; defer. | |
| Failure count as plain metric | Simple but not actionable. | |
| Failure count links to first failed row | Low-churn native anchor that closes F-606. | ✓ |

**User's choice:** User asked for the agent to research and decide.
**Notes:** Chosen recommendation: context-first Retention page, secondary/outline danger button, locked confirmation copy, and failure count linking to first failed row when present.

---

## Evidence proof-card hierarchy

| Option | Description | Selected |
|--------|-------------|----------|
| Status-led proof card | Verdict owner first, subject second, payload as muted detail. | ✓ |
| Subject-led proof card | Familiar card mapping but verdict risks reading as metadata. | |
| Two-zone card | Strong desktop separation but extra responsive complexity. | |
| Disclosure-first payload | Prevents payload dominance but hides a secondary scan element. | |
| Backend semantic expansion | Adds new proof statuses, but widens scope and proof contract. | |

**User's choice:** User asked for one-shot recommendation.
**Notes:** Chosen recommendation: status-led cards and presentation-only `Failed export evidence` labeling for failed export contexts; do not widen `Threadline.Evidence.Proof`.

---

## Cross-surface primitive strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Only apply Phase 136 primitives | Strong boundary discipline but repeats fragile markup. | |
| Add Prove-local helpers/classes | Fast for Phase 137 but risks a second vocabulary. | |
| Narrow shared helpers/components | Use `Presentation` helpers and lightweight function components for repeated semantic patterns. | ✓ |
| Broad component system | Too much churn and bad OSS DX for this phase. | |

**User's choice:** User asked for research-backed cohesive recommendations.
**Notes:** Chosen recommendation: constrained hybrid. Consume Phase 136 primitives first; extract only narrow helpers for semantic repeats that appear across Prove screens and will pay forward to Phase 138+.

---

## Cohesive Prove cluster strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Treat screens separately | Simpler planning but weak cross-screen consistency. | |
| Treat as P3/P4 Prove workflow | Evidence proves, Redaction/Retention establish trust, Exports hands off. | ✓ |
| Merge Redaction/Retention | Tempting policy consolidation but wrong operator moment and out of scope. | |

**User's choice:** User explicitly requested all areas be considered together for a coherent recommendation set.
**Notes:** Chosen recommendation: Redaction is the local baseline pattern; Exports, Evidence, and Retention should adopt the same one-status-owner, summary-before-detail, explicit-action vocabulary.

---

## the agent's Discretion

- Exact helper/module split.
- Exact readiness-rank implementation details.
- Exact token-backed CSS class names.
- Exact test decomposition, provided locked UI-SPEC copy and Phase 137 findings are covered.

## Deferred Ideas

- Full Timeline/Evidence to Exports loop: Phase 140.
- Retention typed/modal confirmation or sudo-mode: future safety flow if needed.
- URL-backed failed-run focus: future retention investigation flow if needed.
- Broad responsive/nav work: Phase 142.
- Full accessibility sweep: Phase 143.
