# Phase 29: Audit table indexing cookbook - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **IDX-01** and **IDX-02** (`.planning/REQUIREMENTS.md`): a dedicated **indexing cookbook** for **`audit_transactions`**, **`audit_changes`**, and **`audit_actions`** aligned with **`Threadline.Query.timeline/2`**, **`Threadline.Export`**, optional **`:correlation_id`**, and **`Threadline.Retention`** / purge access patterns — with **tradeoffs** (write amplification, redundancy, bloat) and **no mandatory one-size-fits-all DDL**; plus **doc contract test(s)** so stable anchors cannot drift silently.

**Out of scope:** Automated index recommendation from library code; changing default shipped migrations in this phase unless a planning follow-up explicitly scopes it; LiveView operator UI; new capture semantics.

</domain>

<decisions>
## Implementation Decisions

Discussion used **parallel subagent research** per gray area, then a **single cohesive pass** so recommendations stay mutually consistent. Log: `[--all] Auto-selected all gray areas: Guide placement & navigation; Baseline vs additive framing; Outline shape; Doc contract strictness.` Auto-resolution follows subagent synthesis + maintainer preference for **research-led defaults** (see `.planning/config.json` workflow keys).

### D-1 — Guide placement & navigation (IDX-01)

- **Ship a standalone `guides/audit-indexing.md`** as the **only** home for index recipes and workload tuning prose (canonical cookbook).
- **`guides/domain-reference.md`:** Add at most a **short** callout or subsection: audit indexing is **integrator-owned**, points to the cookbook — **do not** duplicate full DDL or decision tables there (avoids drift; matches Ecto/Oban-style separation of reference vs ops).
- **`guides/production-checklist.md`:** Add **durable** operator-path link(s) into the cookbook (concrete path + heading anchor where helpful).
- **HexDocs:** Register the new file in **`mix.exs`** `docs: [extras: [...]]` alongside existing `guides/*` (today: `domain-reference`, `production-checklist`, etc.) so it appears under the same **Reference** group pattern.
- **Rationale:** Matches mature Elixir library IA (focused guides + API/reference split), SQL-native “model vs physical tuning” split seen in temporal/audit docs elsewhere, lowest surprise for operators who grep one path.

### D-2 — Baseline vs additive framing (IDX-01)

- **Open the cookbook with a compact “Installed defaults”** section: inventory **indexes and columns the library migrations already create**, with **explicit pointers to source of truth** — `lib/threadline/capture/migration.ex` and `lib/threadline/semantics/migration.ex` (or the generated host migration if docs refer generically). Version-scope the block to **current Hex version** or `main` with a note to diff when upgrading.
- **Body organization:** Prefer **access-pattern sections** (timeline, export, correlation, retention/purge), each using a **two-column “Already covered / Consider adding”** (or equivalent) so the mental model is **pattern → default coverage → optional acceleration**.
- **Every additive example:** Prefix with **non-mandatory** framing; recommend **`CREATE INDEX CONCURRENTLY`** for production; call out **redundant prefixes**, overlapping partial indexes, and **`EXPLAIN (ANALYZE, BUFFERS)`** / **`pg_stat_user_indexes`** before treating an index as a win.
- **Rationale:** Minimizes duplicate indexes and “cookbook = required” misread; fits teams that treat `mix threadline.install` output as opaque; aligns with Crunchy/Citus-style “prove it” Postgres education without the footgun of jumping straight to paste-only DDL.

### D-3 — Outline shape inside the cookbook (IDX-01)

- **Hybrid outline:** **Short per-table primers** (transactions → changes → actions): grain, primary keys/FKs used in joins, one screen each, **invariants** (e.g. retention touches multiple tables — do not imply “changes only” is safe).
- Then **access-pattern deep dives** (timeline, export, correlation filter, retention/purge). Each deep dive includes a fixed **“Tables & modules”** (or equivalent) box: **`Threadline.Query` / `Threadline.Export` / `Threadline.Retention`** entry points and the **join graph** for that path (correlation path uses inner join to `audit_actions` on `correlation_id`; export may `LEFT JOIN` actions when correlation filter absent — prose must stay aligned with code).
- **Duplication guard:** Do **not** repeat full index definitions in multiple chapters — **link** back to primer or a single “index family” subsection (runbook style: link, do not copy five paragraphs).
- **Rationale:** Operators debug by symptom (SRE runbooks); DBAs think by catalog (Postgres books); hybrid matches Phase 28’s intent to treat this doc as **DDL-shaped** while keeping API evolution localized to access chapters.

### D-4 — IDX-02 doc contract strictness

- **Default: Medium strictness** for the new guide — **not** LOOP-04-heavy across the whole document on first ship.
- **Assert:** One stable **marker string** (e.g. `IDX-02-AUDIT-INDEXING` or similar, exact literal TBD at implementation) for grep/release notes; **main H2/H3 outline** strings the team treats as the operator spine; **presence of cross-links** to `guides/domain-reference.md` and `guides/production-checklist.md` (path and/or stable fragments as chosen in implementation — prefer patterns that don’t break on minor heading polish where possible).
- **Reserve Heavy / LOOP-04-style** (many literals, table row invariants) for **optional later promotion** if a specific subsection becomes a normative operator matrix — then **split** a dedicated small test module with a comment tying literals to a named invariant, rather than freezing every paragraph of the cookbook.
- **Rationale:** Phase 28 explicitly deferred heavy matrices here; medium catches broken navigation and lost spine with **lower false-positive churn** than duplicating support-playbook row literals everywhere.

### D-5 — Cross-cutting coherence & DX

- **Single narrative:** “Install ships a safe baseline; cookbook explains workloads and **optional** additive indexes with evidence; contracts protect **spine + navigation**, not every sentence.”
- **Implementation order hint:** Land **guide structure + marker + links** early so IDX-02 can lock anchors before prose polish expands.

### Claude's Discretion

- Exact marker string name, exact subsection titles within the agreed outline, and the minimal set of heading strings in IDX-02 once the first draft exists.
- Whether to add one extra cross-link (e.g. README one-liner) if Phase 30 discovery work overlaps — default: **only if** it reduces duplicate discovery text without scope creep.

### Folded Todos

_None — `todo.match-phase` returned no matches._

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap

- `.planning/REQUIREMENTS.md` — **IDX-01**, **IDX-02**
- `.planning/ROADMAP.md` — v1.9 Phase 29 success criteria (items 3–4)
- `.planning/PROJECT.md` — v1.9 goals, docs-first, non-goals

### Prior phase context

- `.planning/milestones/v1.9-phases/28-telemetry-health-operators-narrative/28-CONTEXT.md` — deferred LOOP-04-class weight to indexing phase; checklist ↔ domain-reference split

### Code & migrations (behavior and shipped DDL must match prose)

- `lib/threadline/query.ex` — `timeline_query/1`, `export_changes_query/1`, filters, correlation join semantics
- `lib/threadline/export.ex` — export column vocabulary vs actions join
- `lib/threadline/retention.ex` — purge predicates, orphan `audit_transactions`, `NOT EXISTS` patterns
- `lib/threadline/capture/migration.ex` — capture table DDL and baseline indexes
- `lib/threadline/semantics/migration.ex` — `audit_actions` DDL, indexes, `audit_transactions.action_id`
- `mix.exs` — `docs/0` extras list (must include new guide for HexDocs)

### Doc contract patterns

- `test/threadline/support_playbook_doc_contract_test.exs` — LOOP-04 style (**reference only** — default Phase 29 is lighter per D-4)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **Shipped migrations as truth:** `Threadline.Capture.Migration` / `Threadline.Semantics.Migration` — authoritative list of default indexes for the cookbook’s “Installed defaults” section.
- **Query shapes:** `timeline_base_query` + `filter_by_correlation` + `timeline_order` — drives which columns and joins matter for timeline vs correlation vs export.
- **Retention deletes:** time predicate on `audit_changes.captured_at`; optional orphan txn cleanup — index guidance must not contradict delete patterns.

### Established patterns

- **Guides** under `guides/` with ExDoc **Reference** group (see `mix.exs` `docs/0`).
- **Doc contracts** in `test/threadline/*_doc_contract_test.exs` — prefer **medium** surface for new guide per D-4.

### Integration points

- Add **`guides/audit-indexing.md`** + **`mix.exs` extras** + **cross-links** from `guides/domain-reference.md` and `guides/production-checklist.md`.
- New test module under **`test/threadline/`** for IDX-02 (naming at planner discretion).

</code_context>

<specifics>
## Specific Ideas

- Subagent research compared standalone guide (A) vs mega-domain-reference (B) vs split pointer (C); **A + thin domain-reference pointer** won.
- Baseline framing: **hybrid of inventory + per-pattern two-column tables**, not paste-only workload-first docs.
- Outline: **hybrid primers + access-pattern chapters** with **“Tables & modules”** boxes.
- IDX-02: **medium** contracts; **heavy** only if a subsection is later promoted to invariant matrix with its own test.

</specifics>

<deferred>
## Deferred Ideas

- **LOOP-04-full parity** on the entire indexing guide — only if explicitly promoted per D-4.
- **Automated index recommendation / codegen** — explicit future per REQUIREMENTS “Future” and PROJECT non-goals.

### Reviewed Todos (not folded)

_None._

</deferred>

---

_Phase: 29-audit-table-indexing-cookbook_  
_Context gathered: 2026-04-24_
