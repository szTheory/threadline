# Phase 28: Telemetry & health operators' narrative - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **OPS-01** and **OPS-02** (`.planning/REQUIREMENTS.md`): operator-facing narrative so a reader can map each shipped **`[:threadline, :transaction, :committed]`**, **`[:threadline, :action, :recorded]`**, and **`[:threadline, :health, :checked]`** event to **when it fires**, **what to watch or chart**, and **what “bad” or misleading looks like** without opening Elixir implementation first; and describe **`Threadline.Health.trigger_coverage/1`** as an operational check (cadence, interpretation of **`{:covered, _}`** / **`{:uncovered, _}`** for user tables, relationship to **`mix threadline.verify_coverage`**, audit-catalog exclusion), with **cross-links** between **`guides/domain-reference.md`** and **`guides/production-checklist.md`**.

**Out of scope:** New telemetry events or health semantics; vendor-specific dashboard JSON/PromQL as **canonical** in-repo docs; full LOOP-04-class doc contract matrices (reserved for Phase 29 **IDX-02** and indexing cookbook stability).

</domain>

<decisions>
## Implementation Decisions

### D-1 — Telemetry operator narrative (OPS-01): structure

- **Primary structure (lookup mode):** Under the existing **`## Telemetry (operator reference)`** in **`guides/domain-reference.md`**, **keep the current table** as the single at-a-glance contract (when / measurements / metadata).
- **Add three parallel `###` subsections** — one per event name — each with a consistent inner pattern: **When it fires** · **What to measure** (plain language; point at measurement keys) · **Metadata** (note `%{}` where true) · **Misleading or degraded signals** (especially proxy **`table_count: 0`** on **`[:threadline, :transaction, :committed]`** unless **`Threadline.Telemetry.transaction_committed/2`** is wired post-commit) · **Where to look next** (link to production checklist observability row, health subsection, or brownfield as appropriate).
- **Secondary structure (procedure mode):** Add **one short numbered playbook** (roughly 5–10 steps) for **weekly / post-deploy triage** and **“something looks wrong in metrics”** that points into the three subsections and **`guides/production-checklist.md`** §6 — not a replacement for per-event docs.
- **HexDocs boundary:** **`lib/threadline/telemetry.ex`** `@moduledoc` remains the **canonical copy-paste** attach surface and versioned contract; the guide **extends** with operator narrative and **links** to HexDocs for examples — **do not** fork event names or measurement keys into conflicting prose.
- **Rationale:** Matches idiomatic Elixir split (**Plug.Telemetry** / **Ecto**-style tables in reference + **Oban**-style guide narrative); satisfies OPS-01 literally; least surprise for integrators who already expect “guide = run it, moduledoc = contract.”

### D-2 — Health & coverage narrative (OPS-02): information architecture

- **Split placement (checklist + reference),** aligned with **v1.8** “support incident queries” pattern: **checklist = when + gates + links**; **domain reference = semantics + interpretation**.
- **`guides/production-checklist.md` §1 (Capture and triggers):** Operational **when** — after deploy, after schema/migrations/trigger regen, periodic (e.g. weekly) or release health; bullets stay **short** for **`config :threadline, :verify_coverage, expected_tables:`**, **`mix threadline.verify_coverage`**, wiring **`Threadline.Health.trigger_coverage/1`**; **one explicit line** that **audit catalog tables are excluded by design** with a **single link** to the canonical prose (no second full explanation in the checklist).
- **`guides/domain-reference.md`:** Add a dedicated subsection **“Trigger coverage (operational)”** (or equivalent stable title) covering: **`{:covered, table}`** vs **`{:uncovered, table}`** meaning; **relationship between `trigger_coverage/1` and `mix threadline.verify_coverage`** (same catalog; policy compares **expected** tables — clarify that not every `{:uncovered, _}` is necessarily a CI failure); **audit table exclusion** (same wording as **`Threadline.Health`** `@moduledoc`); pointer to **`[:threadline, :health, :checked]`** in the telemetry table.
- **Cross-links:** Bidirectional links between checklist §1 / §6 and the new domain-reference anchor; README may keep **one sentence** + link — avoid a third full copy of semantics.
- **Rationale:** Avoids dual-runbook drift; matches Ecto/Kubernetes-style split (semantics vs “when to wire”); preserves grep-friendly single source of truth for tuple interpretation.

### D-3 — “What bad looks like” depth (OPS-01 / cross-cutting)

- **Default depth:** **Plain-language symptoms** plus **at most one generic, vendor-agnostic interpretive example per semantically tricky event** (transaction committed / proxy zeros; action recorded error status; health covered vs uncovered counts).
- **Contract vs dashboard:** Semantic caveats (**when a measurement lies or is best-effort**) belong in the **same tier as the public contract** — surfaced in **HexDocs + guide prose**, not hidden behind example queries.
- **Out of scope for stable guides:** PromQL, LogQL, Datadog notebooks, Grafana JSON, cloud console paths — **defer** to optional HexDocs “Examples”, **`examples/`**, or a later blog/wiki if needed; if ever added, label **illustrative / not supported across all exporter versions**.
- **Rationale:** Reduces staleness and false “official vendor” signaling; keeps operators who are not library authors unblocked; matches Phoenix Telemetry guide (patterns + contract) and OpenTelemetry-style explicit semantics without owning every downstream stack.

### D-4 — Doc contract tests for Phase 28

- **Default:** **No new doc contract tests** for Phase 28 narrative (REQ does not mandate IDX-style locking).
- **Optional exception:** Add **at most one or two** stable literal markers **only if** a new heading or marker line is introduced that the team treats as an **interface** (e.g. REQ traceability string) **and** CI should prove it did not disappear — same spirit as minimal anchors, not LOOP-04 full parity.
- **Explicit deferral:** **LOOP-04-class** multi-string, table-row, and cross-link matrices stay appropriate for **Phase 29 (IDX-02)** indexing cookbook and other **DDL-shaped** guidance — not for first-pass exploratory telemetry prose.
- **Rationale:** YAGNI + roadmap coherence; avoids contributor friction while narrative may still move once.

### D-5 — GSD / discuss workflow preference (project-level)

- **Preference:** For **routine** discuss-phase gray areas, **default to research synthesis + a single coherent recommended option set** in context (subagent or inline research acceptable), so the maintainer is not forced through option menus for low-impact IA choices.
- **Exception:** Reserve interactive **conversational choice** for **high-impact** decisions (semver, security model, public API shape, breaking changes, scope cuts) — caller still uses `/gsd-discuss-phase` without `--auto` when those dominate.
- **Enforcement:** Project **`.planning/config.json`** sets **`workflow.research_before_questions": true`** so future discuss/plan sessions bias toward **informed defaults**; does not change roadmap gates.

### Claude's Discretion

- Exact subsection titles and playbook step count within the ranges above.
- Whether to add **zero vs one** optional OPS marker string after drafts exist.
- Minor wording and anchor slug spelling as long as cross-links resolve.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap

- `.planning/REQUIREMENTS.md` — **OPS-01**, **OPS-02**
- `.planning/ROADMAP.md` — Phase 28 success criteria (v1.9)
- `.planning/PROJECT.md` — v1.9 goals, docs-first, non-goals

### Prior patterns (playbooks + contracts)

- `.planning/milestones/v1.8-phases/26-support-playbooks-doc-contracts/26-CONTEXT.md` — checklist ↔ domain-reference split, LOOP-04 style when needed
- `guides/domain-reference.md` — existing telemetry table, support incident queries
- `guides/production-checklist.md` — §1 capture, §6 observability

### Code & tasks (behavior must match prose)

- `lib/threadline/telemetry.ex` — event names, `transaction_committed/2`, proxy emissions
- `lib/threadline/health.ex` — `trigger_coverage/1`, exclusions, telemetry emit
- `lib/mix/tasks/threadline.verify_coverage.ex` — policy, `expected_tables`, exit codes
- `lib/threadline/verify/coverage_policy.ex` — comparison semantics
- `README.md` — existing verify_coverage / health relationship one-liner

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`Threadline.Telemetry`** — documented `:telemetry.execute/3` points; public **`transaction_committed/2`** for accurate counts.
- **`Threadline.Health.trigger_coverage/1`** — single source of truth for coverage; emits **`[:threadline, :health, :checked]`**.
- **`mix threadline.verify_coverage`** — human + CI gate aligned with health catalog.

### Established patterns

- **Guides:** `domain-reference.md` already carries a **Telemetry (operator reference)** table; production checklist already links to it from §6.
- **Doc contracts elsewhere:** `test/threadline/` doc contract tests for README, STG, loops — use **sparingly** for Phase 28 per D-4.

### Integration points

- Edits are **markdown-only** under **`guides/`** (and optionally **HexDocs-visible** `@moduledoc` tweaks if narrative duplication would otherwise occur).

</code_context>

<specifics>
## Specific Ideas

- Research synthesis favored **A + thin B** for telemetry docs, **split checklist/reference** for OPS-02, **plain language + one generic example** for failure semantics, **defer heavy doc contracts** to Phase 29 unless a minimal marker is clearly valuable.
- Ecosystem parallels used for validation: **Plug.Telemetry**, **Ecto** Repo docs, **Phoenix** telemetry guides, **Oban** telemetry guide, **OpenTelemetry** semantic style (contract clarity), **Rails ActiveSupport::Notifications** lifecycle docs, **Stripe**-style “errors as contract” vs **AWS**-style stale query examples (avoid owning vendor snippets in core guides).

</specifics>

<deferred>
## Deferred Ideas

- **Vendor-specific observability recipes** (PromQL panels, etc.) — optional examples outside canonical guides.
- **Additional telemetry events** — explicit future milestone item in REQUIREMENTS “Future.”
- **Full doc contract parity for OPS prose** — reconsider only if narrative structure stabilizes or after Phase 29 establishes precedent.

### Reviewed Todos (not folded)

- None — `todo.match-phase` returned no matches.

</deferred>

---

*Phase: 28-telemetry-health-operators-narrative*
*Context gathered: 2026-04-24*
