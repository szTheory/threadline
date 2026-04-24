# Phase 28: Telemetry & health operators' narrative - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in **28-CONTEXT.md**.

**Date:** 2026-04-24
**Phase:** 28 — Telemetry & health operators' narrative
**Areas discussed:** All four gray areas (user-selected: all), with parallel subagent research and maintainer-requested one-shot synthesis

---

## Area 1 — Telemetry narrative shape (OPS-01)

| Option | Description | Selected |
|--------|-------------|----------|
| A — Three `###` subsections per event | Table + per-event blocks (when / measure / degraded / next steps) | ✓ (primary) |
| B — Unified playbook only | Numbered scenarios; weak isolated lookup | ✓ (thin layer only) |
| C — Table + minimal prose | Fast but buries proxy / `table_count` semantics | |

**User's choice:** Maintainer asked for deep research + single coherent recommendation; adopted **A as primary** + **short B-style playbook** + **HexDocs as contract home** (see D-1 in CONTEXT).

**Notes:** Subagent research compared Phoenix/Plug/Ecto/Oban patterns and OTel/Rails/Micrometer lessons; hybrid optimizes lookup + on-call procedure without duplicating attach examples in the guide.

---

## Area 2 — Health + coverage doc placement (OPS-02)

| Option | Description | Selected |
|--------|-------------|----------|
| 1 — Checklist-first | Long §1 owns all semantics | |
| 2 — Reference-first | Thin checklist | |
| 3 — Split | Checklist when/gates; reference interpretation | ✓ |

**User's choice:** **Split (3)** — checklist operational triggers + bullets + link; domain-reference owns tuple semantics, exclusions, verify relationship (see D-2).

**Notes:** Avoids Kubernetes-style dual-runbook contradictions; matches existing support-playbook IA between the two guides.

---

## Area 3 — "Bad" signals depth

| Option | Description | Selected |
|--------|-------------|----------|
| Plain symptoms only | No examples | |
| Plain + one generic example per tricky event | Vendor-agnostic interpretation | ✓ |
| In-repo PromQL / vendor snippets | High DX for one stack; high staleness | |

**User's choice:** **Plain language + one generic quantitative/interpretive example** where semantics are subtle; vendor queries deferred (see D-3).

---

## Area 4 — Doc contract markers

| Option | Description | Selected |
|--------|-------------|----------|
| Zero new markers | Manual review | ✓ (default) |
| 1–2 markers | Lock critical new headings | (optional later) |
| LOOP-04 full parity | Many CI strings | |

**User's choice:** **Defer doc contract tests** for Phase 28; optional 1–2 literals only if a stable interface heading is introduced; heavy locking reserved for Phase 29 **IDX-02** (see D-4).

---

## Claude's Discretion

- Exact headings, step counts, optional OPS marker after draft review.

## Deferred Ideas

- Vendor dashboard recipes as first-class guide content.
- New telemetry events / health semantics (out of milestone scope).
