# Phase 26: Support playbooks & doc contracts - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **LOOP-02** and **LOOP-04** from `.planning/REQUIREMENTS.md`: **`guides/domain-reference.md`** and **`guides/production-checklist.md`** each gain a **Support incident queries** subsection mapping the **five canonical support questions** to **API / Mix task** vs **copy-paste SQL** (with pointers to `AuditChange`, `AuditTransaction`, `AuditAction` columns). Text stays **SQL-native**; **no LiveView**. **LOOP-04:** doc contract tests assert **stable anchors** so those sections do not rot. **Out of scope:** Phase 27 example-app correlation path; new capture semantics; operator UI.

**Requirement lock:** LOOP-02 names **only** the two guides above — canonical narrative must live there (not a new third guide in v1.8 unless requirements are amended). A future standalone `guides/support-incidents.md` is **deferred** (see `<deferred>`).

</domain>

<decisions>
## Implementation Decisions

### D-1 — Where the “source of truth” lives (two guides, no drift)

- **Canonical depth:** **`guides/domain-reference.md`** holds the full **Support incident queries** material (hybrid layout per D-4, SQL shape per D-2).
- **`guides/production-checklist.md`:** Same **subsection title** for discoverability, but **checklist-first**: five short items (one per canonical question) that **link** to the matching anchors in `domain-reference.md` (relative paths `domain-reference.md#...`). **Do not** duplicate long SQL or full API tables in the checklist — avoids two bodies drifting (research: Ecto/Oban pattern of one narrative + pointers; STG rubric already uses marker + cross-links).
- **Rationale:** Satisfies LOOP-02 (“both guides gain a subsection”) while honoring **single source of truth** for volatile snippets and **least surprise** (pre-launch checklist points at reference, not a second encyclopedia).

### D-2 — SQL concreteness (hybrid “golden path + fragments”)

- **Default shape per question (where SQL is appropriate):** One **near-complete** `SELECT` (or `SELECT` + CTE) in a **fenced code block**, using **one consistent placeholder style** repo-wide (recommend **`your_schema`** / `your_app` prose list in a **“Replace before run”** bullet block immediately above the fence — pick one convention and document it once in the subsection intro).
- **Variants:** Short **fragments** (extra `WHERE`, optional `JOIN`, time bounds) labeled explicitly as **additions to the golden query**, not standalone answers.
- **When to prefer API/Mix in the table:** Dynamic identifiers, filter maps, or anything error-prone to hand-assemble — point to **`Threadline.Query`**, **`Threadline.Export`**, **`mix threadline.*`** per existing domain-reference style.
- **Safety defaults in examples:** Prefer **bounded** exploration (`LIMIT`, `:from`/`:to` where applicable) and state **read-only / replica** expectation in prose once for the subsection (operator DX; avoids prod table-scan footguns).
- **Phase 25 alignment:** Where **`:correlation_id`** appears, prose must match **strict** semantics (only changes whose transaction links to an **`AuditAction`** with that correlation) — do not imply orphan capture rows appear in filtered timeline/export.

### D-3 — LOOP-04 anchors and test module layout

- **Anchor strategy (hybrid):**
  - **Primary:** Assert exact markdown **heading lines** the operator sees — at minimum a section heading for **Support incident queries** in **both** guides, plus **five stable subsection headings** in `domain-reference.md` (one per canonical question). Treat heading text as **API**: rename only with coordinated test update.
  - **Secondary (recommended):** One **namespaced marker token** in the canonical subsection body (same spirit as `STG-AUDITED-PATH-RUBRIC`), e.g. **`LOOP-04-SUPPORT-INCIDENT-QUERIES`**, placed once in `domain-reference.md` so accidental heading rewords still trip a second assertion. **Avoid** duplicating the marker in checklist if links are the checklist’s job — optional short marker in checklist only if tests need a file-local invariant without reading domain-reference.
  - **Do not** rely on HTML comment sentinels alone for primary contracts (opaque to contributors); optional as tertiary if desired later.
- **Test module:** Add **`test/threadline/support_playbook_doc_contract_test.exs`** (or equivalent name) using **`ExUnit.Case, async: true`** + `File.read!/1` from repo root, mirroring **`Threadline.StgDocContractTest`** / **`CiTopologyContractTest`** (`read_rel!/1` helper). **Do not** overload **`readme_doc_contract_test.exs`** — LOOP-04 is guide-scoped, not README-scoped (matches REQUIREMENTS “prefer extending … if grouped”; STG/CI pattern already groups non-README guide contracts separately).
- **CI:** Full **`mix test`** / **`mix ci.all`** already runs all `test/threadline/*`; no mandate to extend the narrow **`verify.doc_contract`** alias unless maintainers want faster targeted runs (Claude’s discretion).

### D-4 — Information architecture (five questions)

- **In `domain-reference.md` — hybrid:**
  1. **At-a-glance** narrow table: **# | Question (one line) | Primary path** where the third column is **pointers only** (e.g. “§ SQL below”, “`Threadline.Query.timeline/2`”, “`mix threadline.export`”) — **no multi-line SQL inside table cells**.
  2. **Five subsections** (`###` or `####`) with **stable, boring titles** aligned to the five canonical questions (wording fixed for LOOP-04 asserts and deep links from the checklist).
  3. Under each subsection: **small table or tight bullets** for **API/Mix vs SQL**; **SQL lives in fenced blocks** below, not wrapped in pipe tables (mobile, GitHub preview, print; matches observability/runbook doc patterns).
- **`production-checklist.md`:** Same five-question **intent** via checklist lines + **links** to those anchors; optional one-line “why this matters pre-launch” per item.

### D-5 — Cross-links and ExDoc

- Use **repo-relative** links consistent with existing guides (`guides/...` or sibling `domain-reference.md#anchor` from checklist).
- If new headings are added, **ExDoc extras** already include both files in `mix.exs` — no new `extras` entry required for v1.8.

### D-6 — Doc contract scope (LOOP-04 minimum)

- Assert presence of:
  - Subsection heading **Support incident queries** in **`guides/domain-reference.md`** and **`guides/production-checklist.md`**.
  - The **five** per-question subsection headings in **`guides/domain-reference.md`** (exact strings chosen at implementation time — lock in this phase’s PR and mirror in tests).
  - Optional: marker token **`LOOP-04-SUPPORT-INCIDENT-QUERIES`** (or chosen final token) in domain-reference.
  - Minimal invariant that the **at-a-glance** table exists (e.g. contains all five question numbers **1–5** or the canonical short labels — pick one approach in implementation to avoid brittle full-row matching).

### Claude's Discretion

- Exact placeholder spelling (`YOUR_SCHEMA` vs `your_schema` vs `{{schema}}`).
- Precise subsection heading wording (must stay consistent with contract tests once merged).
- Whether to add a second marker in `production-checklist.md`.
- Extending **`verify.doc_contract`** alias to include the new test file for faster local runs.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap

- `.planning/REQUIREMENTS.md` — **LOOP-02**, **LOOP-04** (authoritative acceptance text).
- `.planning/ROADMAP.md` — Phase 26 success criteria (v1.8 section, items 4–5).
- `.planning/PROJECT.md` — v1.8 goals, SQL-native / operator-grade positioning, non-goals (LiveView, etc.).

### Prior phase (correlation semantics for playbook accuracy)

- `.planning/phases/25-correlation-aware-timeline-export/25-CONTEXT.md` — **`:correlation_id`** strict join semantics, validation, operator messaging when zero rows.

### Guides to edit

- `guides/domain-reference.md` — canonical support incident material.
- `guides/production-checklist.md` — checklist + links.

### Public API & tasks (for accurate “API / Mix” column)

- `lib/threadline/query.ex` — `timeline/2`, `validate_timeline_filters!/1`, `export_changes_query/1`, filter vocabulary.
- `lib/threadline/export.ex` — export entrypoints, CSV/JSON shapes.
- `lib/mix/tasks/threadline.export.ex` — `@moduledoc` / task name for Mix column (and any other relevant `mix threadline.*` tasks discovered during implementation).

### Domain model vocabulary

- `prompts/audit-lib-domain-model-reference.md` — **AuditChange**, **AuditTransaction**, **AuditAction**, correlation.

### Doc-contract precedents

- `test/threadline/stg_doc_contract_test.exs` — `read_rel!/1`, heading + marker pattern for guides.
- `test/threadline/ci_topology_contract_test.exs` — same pattern for CI/guide markers.
- `test/threadline/readme_doc_contract_test.exs` — README/example contracts (reference only; LOOP-04 not assumed to live here).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Threadline.StgDocContractTest`** / **`CiTopologyContractTest`** — copy **`read_rel!/1`**, `async: true`, `String.contains?/2` on guide paths under `guides/`.
- **Guide cross-link style** — `production-checklist.md` already links `domain-reference.md` (telemetry); replicate for support anchors.

### Established patterns

- **Marker tokens in markdown** (`STG-*`, `CI-*`) pair human-visible rubrics with machine-checkable strings.
- **Extras list** in `mix.exs` already registers `guides/domain-reference.md` and `guides/production-checklist.md` for ExDoc.

### Integration points

- **`mix ci.all`** runs full test suite — new contract module runs without alias changes.
- **`verify.doc_contract`** currently only runs `readme_doc_contract_test.exs`; optional follow-up to include support playbook tests for symmetry with operator docs.

</code_context>

<specifics>
## Specific Ideas

- Research synthesis (2026-04-24, parallel agents): **Oban Troubleshooting**-style single canonical narrative + **Ecto**-style separation of long-form guides from checklists; **Postgres operator** docs favor paste-ready SQL with explicit placeholders; **PagerDuty / SRE / AWS** patterns favor vertical subsections + copy-paste blocks over wide SQL-in-table layouts; **Threadline** already uses separate guide contracts for STG/CI — LOOP-04 should follow that split, not README tests.

</specifics>

<deferred>
## Deferred Ideas

- **Dedicated `guides/support-incidents.md`** as a third ExDoc extra — attractive for “on-call bookmark” ergonomics but **out of scope** for v1.8 while LOOP-02 explicitly names only two files; re-open if requirements add a third artifact.
- **i18n** of headings — if ever needed, prefer stable marker tokens + relaxed heading asserts per locale (not v1.8).

### Reviewed Todos (not folded)

- None from `gsd-sdk query todo.match-phase "26"`.

</deferred>

---

*Phase: 26-support-playbooks-doc-contracts*
*Context gathered: 2026-04-24*
