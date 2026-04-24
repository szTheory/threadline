# Phase 33: Operator docs & contracts - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.  
> Decisions are captured in **`33-CONTEXT.md`**.

**Date:** 2026-04-24  
**Phase:** 33 — Operator docs & contracts  
**Areas discussed:** Section placement; Routing table; LOOP-04 relationship; Cross-link; Doc contract; Scope boundaries

**Mode:** One-shot cohesive synthesis per **`.planning/STATE.md`** and **`.planning/config.json`** (`discuss_default_gray_areas: all`, `discuss_one_shot_cohesive_context_default: true`, non–high-impact phase). **`gsd-sdk query init.phase-op "33"`** returned **`phase_found: false`**; phase boundary taken from **`.planning/ROADMAP.md`** and **`.planning/REQUIREMENTS.md` (XPLO-03)**.

---

## Gray area: Where the routing section lives

| Option | Description | Selected |
|--------|-------------|----------|
| A | New `##` immediately before **Support incident queries** | ✓ |
| B | Inside or after Support incident (risk: burying “which API first?”) | |
| C | Top of file after ubiquitous language (risk: disrupting vocabulary-first flow) | |

**User's choice:** Project synthesis (config + STATE) — **A**  
**Notes:** Keeps vocabulary + relationships intact; routing acts as bridge to LOOP-04 depth.

---

## Gray area: Table vs prose vs new taxonomy

| Option | Description | Selected |
|--------|-------------|----------|
| A | Short table + links to existing subsections | ✓ |
| B | Long prose decision tree | |
| C | New numbered “questions” competing with LOOP-04 | |

**User's choice:** **A**  
**Notes:** Satisfies roadmap “short routing section” without duplicating SQL playbooks.

---

## Gray area: Which guide cross-links

| Option | Description | Selected |
|--------|-------------|----------|
| A | **`production-checklist.md`** only | ✓ |
| B | Adoption backlog instead | |
| C | Both checklist + README (required) | |

**User's choice:** **A** (README optional / deferred)  
**Notes:** XPLO-03 requires ≥1 checklist or support guide; checklist already in doc-contract graph.

---

## Gray area: Doc contract placement

| Option | Description | Selected |
|--------|-------------|----------|
| A | New **`exploration_routing_doc_contract_test.exs`** | ✓ |
| B | Only extend **`support_playbook_doc_contract_test.exs`** | |

**User's choice:** **A**  
**Notes:** Clear ownership for v1.10 anchors; mirrors **`audit_indexing_doc_contract_test.exs`** style.

---

## Claude's Discretion

- Exact Markdown anchor slug for the new heading after punctuation normalization.
- Optional **actor** row in the routing table.
- Whether checklist link assertion ships in the same test file as domain-reference or a second test.

## Deferred Ideas

- README maintainer-band link to routing (polish).
- `:transaction_id` on timeline filters (future phase).
