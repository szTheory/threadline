# Phase 26: Support playbooks & doc contracts - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `26-CONTEXT.md`.

**Date:** 2026-04-24
**Phase:** 26 — Support playbooks & doc contracts
**Areas discussed:** Guide source of truth (dual-file), SQL depth, LOOP-04 anchors/tests, five-question layout (user selected **all**; one-shot research-led lock-in)

---

## 1. Guide source of truth (domain-reference vs production-checklist)

| Option | Description | Selected |
|--------|-------------|----------|
| A | Full duplicate sections in both guides |  |
| B | Canonical in domain-reference; pointers only in checklist | ✓ (adapted) |
| C | New `guides/support-incidents.md` as canonical |  |

**User's choice:** Research + requirement synthesis — **B adapted to LOOP-02**: both files gain a **Support incident queries** subsection, but **only `domain-reference.md`** holds long SQL / full tables; **`production-checklist.md`** is checklist lines + deep links. **C deferred** because LOOP-02 does not authorize a third guide in v1.8.

**Notes:** Cross-ecosystem pattern (Ecto guides vs checklist, Oban troubleshooting as single narrative, AWS/Datadog runbook hubs) argues against full duplication; checklist is pre/post-launch framing, not primary home for incident SQL catalogs.

---

## 2. SQL concreteness in operator docs

| Option | Description | Selected |
|--------|-------------|----------|
| A | Fragments + glossary only |  |
| B | Near-complete SELECTs + placeholders only |  |
| C | Hybrid: golden path + labeled fragments | ✓ |

**User's choice:** **C** — hybrid balances **SQL-native** promise, heterogeneous `schema`/table names, and **time-to-first-query** for support; fragments-only risks wrong joins; SQL-only tables risk rot and wide-cell layout issues.

**Notes:** Align Elixir examples with “whole pipeline” idioms; SQL blocks follow Postgres operator doc norms (complete statement + “replace these tokens”).

---

## 3. LOOP-04 anchors and test module placement

| Option | Description | Selected |
|--------|-------------|----------|
| A | Headings only | partial |
| B | HTML comment sentinels only |  |
| C | Frozen prose substring only | partial |
| D | Hybrid heading + marker token | ✓ |

**User's choice:** **D** — exact **heading lines** for human anchors + one **`LOOP-04-…`** namespaced marker in canonical body; new **`support_playbook_doc_contract_test.exs`** following **Stg/Ci** contract style, not README contract module.

**Notes:** Avoid snapshot/golden-file churn for prose; avoid over-loose substring tests.

---

## 4. Layout for five canonical questions

| Option | Description | Selected |
|--------|-------------|----------|
| A | One wide markdown table for all five |  |
| B | Five subsections only, no summary table |  |
| C | Hybrid: narrow summary table + five subsections | ✓ |

**User's choice:** **C** — matches LOOP-02 “small table” + subsection semantics; mobile/print friendly; SQL in **fences** under headings, not in pipe cells.

**Notes:** Industry runbooks (PagerDuty, SRE, observability vendors) favor vertical flow + code blocks over dense matrices for executable content.

---

## Claude's Discretion

- Placeholder spelling, exact subsection title strings, optional `verify.doc_contract` alias extension, optional second marker in checklist.

## Deferred Ideas

- Third guide `guides/support-incidents.md` — future milestone if requirements expand.
