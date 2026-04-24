# Phase 32: Transaction-scoped change listing - Context

**Gathered:** 2026-04-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **XPLO-02** (`.planning/REQUIREMENTS.md`) and roadmap **Phase 32** success criteria:

- **`Threadline.Query`** exposes a documented function accepting an explicit **`audit_transactions.id`** (same type as `AuditChange.transaction_id`) and **`opts`** with required **`:repo`**, returning **all** matching `%AuditChange{}` rows for that transaction.
- **`Threadline`** delegates to that query entrypoint (same public name on both modules).
- **Integration or repo-level test** exercises **multi-change** ordering within one transaction.
- **Stable ordering** is defined precisely in moduledoc (composite key), not implied by UUID order.

**Out of scope:** New capture semantics; LiveView; Phase 33 routing docs; unifying this call into `timeline/2` filter vocabulary unless a later phase intentionally merges validation paths.

</domain>

<decisions>
## Implementation Decisions

Synthesis from **five parallel research passes** (2026-04-24), aligned with **Phase 31** (`Threadline.Query` = retrieval/listing; **`Threadline.ChangeDiff`** = single-row projection), existing **`history/3`**, **`actor_history/2`**, **`timeline/2`** patterns, and Threadline principles (**honest by default**, explicit Repo, SQL-native integrator paths).

### D-1 — Public function name

- **Name:** **`audit_changes_for_transaction/2`** on **`Threadline.Query`** and **`Threadline`** (mirrors existing delegator naming: same symbol on root and `Query`).
- **Rationale:** **`AuditChange`** is the capture vocabulary; bare **`changes`** collides with Ecto “changeset” mental noise and under-specifies capture vs semantic **actions**. **`audit_changes_`** greps and ExDoc-discoverability beat generic `changes_for_transaction` / `by_transaction_id`.
- **Do not:** Introduce a different root name than `Query` (one concept, one name).

### D-2 — Arity and repo placement

- **Signature:** **`audit_changes_for_transaction(transaction_id, opts)`** with **required** **`opts[:repo]`** via **`Keyword.fetch!(opts, :repo)`** (same contract as **`history/3`** / **`actor_history/2`**).
- **Rationale:** Roadmap’s “repo and transaction_id” is satisfied as **explicit repo in options + domain id first** — least surprise **inside this module**, vs **`repo` first** (footgun with `binary_id` argument order vs other `Query` APIs) or **timeline-style filter lists** (would expand validated filter grammar or duplicate validation for a narrow fetch).
- **Do not:** Add `:transaction_id` to **`validate_timeline_filters!/1`** in Phase 32 unless deliberately designing unified filters (defer).

### D-3 — Stable ordering

- **Default order:** **`captured_at` DESC, `id` DESC** — **same tie-break stack as `timeline/2`** (`timeline_order/1`).
- **Documentation (mandatory):** Stability means a **total order on `(captured_at, id)`** — not “UUID narrative order,” not unproven physical commit order. Call out that **random `binary_id` is not a safe monotonic sequence** for ordering semantics.
- **Rationale:** Cross-API consistency for integrators comparing timeline slices vs transaction drill-down; honest contract vs sorting by **`id` alone**.
- **Optional later:** A named **`:order`** or separate function for **ascending “replay”** only if product demand warrants a **second** explicit contract — not default (avoids silent opposite order vs global timeline).

### D-4 — Malformed id vs empty result

- **Malformed `transaction_id`:** **`ArgumentError`** with a **clear message** (validate with **`Ecto.UUID.cast/1`** or equivalent **before** `Repo.all` so Postgrex never owns the error shape). Matches strict **`validate_timeline_filters!/1`** style.
- **Well-formed id, zero matching change rows** (unknown transaction **or** transaction with no changes rows): return **`[]`** — same as **`history/3`** / `Repo.all` empty set.
- **Rationale:** Do not use one changes query to leak **“transaction row exists”** vs **“empty children”**; callers who need **HTTP 404 vs 200 + []** should **`Repo.get(AuditTransaction, id)`** (or app context) **first**, then load changes (**pattern D** from research).
- **Do not:** Return **`{:ok, _}` / `:not_found`** tuples from this Query API (breaks list-shaped module contract).

### D-5 — Preloading `transaction`

- **Default:** **No preload** — plain **`%AuditChange{}`**, matching **`timeline/2`**’s **`select`** of **`ac`** only (join for filters is separate from returned shape).
- **Opt-in:** **`preload: [:transaction]`** in **`opts`** when callers need **`occurred_at`**, **`actor_ref`**, etc., on the same result set. **`Repo.preload`** for one txn’s changes does **not** N+1 (single parent batch).
- **Do not:** Default preload (surprise + cost for hot paths). A **merged `select` / map projection** remains the domain of **`export_changes_query/1`**-style APIs if a flat JSON row is needed later — not the default struct list here.

### D-6 — Tests and delegation

- **`Threadline.audit_changes_for_transaction/2`** **`defdelegate`** or one-liner to **`Threadline.Query`** (match **`history`** / **`timeline`** style).
- **Test:** **Integration or repo-level** test inserts **multiple** `audit_changes` sharing one **`transaction_id`** (or one txn + multi-row fixture), asserts **order** matches **D-3** and **full row set** returned.

### Claude's Discretion

- Exact **`ArgumentError`** message strings.
- Whether **`opts`** allow any other documented keys in Phase 32 (e.g. strict **unknown-key raise** vs only `:repo` + `:preload`) — prefer **strict** if the module already trends that way for integrator-facing opts.
- Optional **`:order`** for asc replay if implemented in a follow-up without a new phase.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap

- `.planning/REQUIREMENTS.md` — **XPLO-02**.
- `.planning/ROADMAP.md` — Phase **32** success criteria (items 4–5 under v1.10).

### Prior phase lock (API layering)

- `.planning/phases/31-field-level-change-presentation/31-CONTEXT.md` — **`Threadline.Query`** owns listing; **`Threadline.ChangeDiff`** owns single-change projection.

### Code (implementation anchors)

- `lib/threadline/query.ex` — **`timeline_order/1`**, **`history/3`**, **`timeline/2`**, **`validate_timeline_filters!/1`**, **`timeline_repo!/2`**.
- `lib/threadline.ex` — delegator patterns.
- `lib/threadline/capture/audit_change.ex` — **`transaction_id`**, schema fields.
- `lib/threadline/capture/audit_transaction.ex` — transaction primary key (if preload or doc examples reference it).
- `guides/domain-reference.md` — Phase **33** will cross-link; no new anchors required in **32** unless you add a short “transaction drill-down” note by choice.

### GSD workflow preference (project-local)

- `.planning/config.json` — **`workflow.research_before_questions`**, **`workflow.discuss_use_subagent_research`**, **`workflow.discuss_one_shot_cohesive_context_default`**, **`workflow.discuss_interactive_menus_high_impact_only`**, **`workflow.discuss_high_impact_tags`** (reserved for semver/security/breaking/scope).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`timeline_order/1`** — copy or reuse for ordering contract parity with **`timeline/2`**.
- **`Keyword.fetch!(opts, :repo)`** pattern from **`history/3`** / **`actor_history/2`**.
- **`AuditChange`** schema — **`transaction_id`** is **`:binary_id`**.

### Established patterns

- Query APIs return **plain lists**; invalid integrator input tends **`ArgumentError`**, not tuples.
- **Explicit `:repo`** — no implicit repo from **`Application.get_env`**.

### Integration points

- **`Threadline`** root delegator beside **`timeline/2`**, **`change_diff/2`**.
- Future **Phase 33** “which API when” table should list **transaction-scoped listing** next to **`history`**, **`timeline`**, export, **`change_diff`**.

</code_context>

<specifics>
## Specific Ideas

- Maintainer preference (2026-04-24): **All gray areas** researched in parallel + **one-shot cohesive** recommendations (no per-area interactive re-litigation) except for **high-impact** tags in **`.planning/config.json`**.

</specifics>

<deferred>
## Deferred Ideas

- **Unified `timeline` filter key** `:transaction_id`** — only if a later phase merges validation and export vocabulary intentionally.
- **Ascending / “replay” order** — optional second contract (parameter or separate function) if integrators ask; default stays timeline-consistent **DESC**.
- **Flat map / export-shaped rows** for one txn — reuse or extend **`export_changes_query/1`** patterns if needed; not the default **`audit_changes_for_transaction`** return.

### Reviewed Todos (not folded)

- None from `todo.match-phase` for phase 32.

</deferred>

---

*Phase: 32-transaction-scoped-change-listing*  
*Context gathered: 2026-04-24*
