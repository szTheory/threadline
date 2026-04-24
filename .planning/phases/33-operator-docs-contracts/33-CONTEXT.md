# Phase 33: Operator docs & contracts - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **XPLO-03** (`.planning/REQUIREMENTS.md`) and roadmap **Phase 33** success criteria:

1. **`guides/domain-reference.md`** gains a **short, skimmable routing section** that tells operators and integrators **which public API to reach for** when answering: single-row history over time, bounded incident window, correlation-scoped slice, **all changes in one transaction**, and **field-level diff for one `%AuditChange{}`**.
2. At least **one** existing **support- or checklist-oriented** guide adds a **cross-link** into that section (not a duplicate narrative).
3. **Doc contract test(s)** in `test/threadline/` lock **new stable anchors** introduced for this routing material (headings and/or contract marker), following existing LOOP / indexing contract patterns.

**Out of scope:** LiveView or new operator UI; new capture semantics; Hex semver bump; repeating full SQL playbooks (defer to **Support incident queries** and subsections); ExDoc-only changes without the guide hub.

</domain>

<decisions>
## Implementation Decisions

Synthesis follows **`.planning/STATE.md`** and **`.planning/config.json`**: non–high-impact phase → **all gray areas** treated as in-scope; **one-shot cohesive** decisions (no per-area interactive menu). Grounded in **Phase 31** / **Phase 32** context, existing **`guides/domain-reference.md`** structure, and **`Threadline.SupportPlaybookDocContractTest`**.

### D-1 — Section placement in `domain-reference.md`

- **Add** a dedicated **`##`** section titled **`Exploration API routing (v1.10+)`** (exact title is a **stable anchor** for links and tests).
- **Position:** **Immediately before** the existing **`## Support incident queries`** section.
- **Rationale:** Support playbooks stay the deep copy-paste home; the new block is a **fast “which module/function first?”** layer that points into the five canonical questions where they overlap. Readers who open the doc for LOOP-04 land one scroll away from routing context.

### D-2 — Routing table shape and rows

- **Format:** One **compact Markdown table** (intent → primary API → pointer), **≤ ~8 rows** including a header row — “short” per roadmap, not a second domain guide.
- **Mandatory intents** (map to roadmap / XPLO-03 wording):
  1. **Single domain row over time** — `Threadline.history/3` for “one PK, list of changes”; `Threadline.Query.timeline/2` when filters (`:table`, `:from`, `:to`, etc.) are needed. Note **T0 / brownfield** pointer to existing brownfield subsection where relevant.
  2. **Incident / time window across rows** — `Threadline.Query.timeline/2` as default listing API; mention **`timeline_repo!/2`** only if the doc already establishes that pattern (keep consistent with Phase 17 narrative elsewhere).
  3. **Correlation-scoped changes** — `Threadline.Query.timeline/2` and **`Threadline.Export`** / **`mix threadline.export`** with **`:correlation_id`**, with **one sentence** on strict join semantics (defer detail to correlation subsection).
  4. **Everything captured in one DB transaction** — **`Threadline.Query.audit_changes_for_transaction/2`** and **`Threadline.audit_changes_for_transaction/2`** (delegator), **`opts[:repo]`** required; **ordering** = same stack as timeline (`captured_at`, `id` DESC) per Phase 32 lock.
  5. **Field-level diff for one change row** — **`Threadline.change_diff/2`** and **`Threadline.ChangeDiff`** (JSON-serializable map), with explicit **INSERT/UPDATE/DELETE** and **`changed_from` nil** behavior pointer to module doc (no full semantics duplicate).
- **Optional row (one line):** **Actor-scoped window** — `Threadline.actor_history/2` + timeline with `:actor_ref` — ties to support table row 2 without reopening scope.

### D-3 — Relationship to LOOP-04 table

- **Do not** replace or widen the **`| 1 |` … `| 5 |`** support table; the routing section **summarizes API entrypoints** and explicitly says **“detail and SQL: [Support incident queries](#support-incident-queries)”** (use the real heading slug).
- **No new canonical “sixth question”** — Phase 33 is routing clarity, not new support taxonomy.

### D-4 — Cross-link source (XPLO-03 ≥ 1)

- **Primary:** Extend **`guides/production-checklist.md`** in the existing **Support incident queries** area (or the nearest operator-facing cross-links block) with **one explicit link** to **`guides/domain-reference.md#exploration-api-routing-v110`** (slug must match generated anchor for the chosen heading; verify after edit — GitHub/CommonMark heading rules).
- **Rationale:** Checklist is already contract-linked from **`Threadline.SupportPlaybookDocContractTest`**; minimal diff satisfies “checklist-oriented” and keeps discovery on the ops path **`.planning/REQUIREMENTS.md`** names.
- **Do not require** README changes for XPLO-03 closure unless planning finds checklist-only link too weak (defer optional second link to README maintainer band).

### D-5 — Doc contract tests

- **Add** a dedicated test module **`test/threadline/exploration_routing_doc_contract_test.exs`** (name mirrors **`audit_indexing_doc_contract_test.exs`**).
- **Assertions:** Read **`guides/domain-reference.md`** and assert:
  - Presence of **`## Exploration API routing (v1.10+)`** (exact string).
  - A visible contract marker line **`XPLO-03-API-ROUTING`** (same pattern as **`LOOP-04-SUPPORT-INCIDENT-QUERIES`**).
  - Table includes stable cues for **transaction-scoped** and **field diff** rows (e.g. assert substring `audit_changes_for_transaction` and `change_diff` / `ChangeDiff` as appropriate — pick strings that won’t churn casually).
- **Optional:** One test that **`production-checklist.md`** contains the new **`domain-reference.md#`** fragment — strengthens end-to-end discovery; align with whether D-4 uses that exact URL fragment.

### D-6 — ExDoc / README

- **Not required** for Phase 33 acceptance unless a plan task explicitly adds a pointer; milestone acceptance is guide + cross-link + contract.

### Claude's Discretion

- Exact anchor slug if the **`##`** title is tweaked for readability (keep marker + test strings in sync).
- Minor row wording and whether the optional **actor** row ships in v1.10.
- Whether the contract test also asserts **`production-checklist.md`** link (recommended but left flexible above).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **XPLO-03**.
- `.planning/ROADMAP.md` — v1.10 **Phase 33** success criteria (items 6–7).

### Prior phase locks

- `.planning/phases/31-field-level-change-presentation/31-CONTEXT.md` — **`Threadline.ChangeDiff`**, **`change_diff/2`**, JSON shape rules.
- `.planning/phases/32-transaction-scoped-change-listing/32-CONTEXT.md` — **`audit_changes_for_transaction/2`**, ordering, `ArgumentError` vs `[]`.

### Guides and contracts (edit targets)

- `guides/domain-reference.md` — primary edit surface for routing section.
- `guides/production-checklist.md` — cross-link target for XPLO-03.
- `test/threadline/support_playbook_doc_contract_test.exs` — precedent for domain-reference + checklist contracts.

### Code (names must match docs)

- `lib/threadline.ex` — delegators: **`history/3`**, **`timeline/2`**, **`change_diff/2`**, **`audit_changes_for_transaction/2`**, export helpers.
- `lib/threadline/query.ex` — **`timeline/2`**, **`validate_timeline_filters!/1`**, **`audit_changes_for_transaction/2`**, ordering helper.
- `lib/threadline/change_diff.ex` — field diff semantics reference for doc accuracy.

### Project workflow

- `.planning/STATE.md` — discuss defaults for v1.10.
- `.planning/config.json` — **`workflow.discuss_*`** keys used for this one-shot discuss.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **Support incident queries** block and subsections **`### 1` … `### 5`** — authoritative SQL/API detail; routing section should **link in**, not fork.
- **`Threadline.SupportPlaybookDocContractTest`** — template for reading guides from repo root and locking anchors.

### Established patterns

- Contract markers as HTML spans or bold single-line tokens (`LOOP-04-…`).
- **`production-checklist.md`** already links **`domain-reference.md#`** fragments for support material.

### Integration points

- New section sits in the **long single-file** domain reference; ExDoc “extras” already include this guide — no `mix.exs` change required unless maintainers want an extra link line.

</code_context>

<specifics>
## Specific Ideas

- **Project preference (2026-04-24):** One-shot cohesive context from parallel / synthesized research for phases without **high-impact** tags — applied here.

</specifics>

<deferred>
## Deferred Ideas

- **README** discovery line for routing — optional polish after checklist link lands.
- **Unified `:transaction_id` on `timeline/2` filters** — explicitly deferred in Phase 32 context; do not document as supported until a future phase adds it.

</deferred>

---

*Phase: 33-operator-docs-contracts*  
*Context gathered: 2026-04-24*
