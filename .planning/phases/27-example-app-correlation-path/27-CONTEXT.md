# Phase 27: Example app correlation path - Context

**Gathered:** 2026-04-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver **LOOP-03** (`.planning/REQUIREMENTS.md`): **`examples/threadline_phoenix/`** demonstrates **one** end-to-end correlation path — HTTP request with **`x-correlation-id`**, audited write **with** semantic linkage suitable for Phase 25 filters, and **proof** of retrieval using **`:correlation_id`** via **`Threadline.timeline/2`** (and a **README-only** pointer to export with the same filters). **Out of scope:** LiveView, new capture semantics, duplicating full timeline↔export parity matrices (owned by library tests), new guides beyond README tweaks that stay within LOOP-03.

**Note:** `gsd-sdk query init.phase-op "27"` currently returns `phase_found: false` against ROADMAP parsing; phase scope is authoritative from `.planning/ROADMAP.md` v1.8 + **LOOP-03**.

</domain>

<decisions>
## Implementation Decisions

### D-1 — Proof surface (test vs README)

- **Primary proof:** **Integration test** under the example app (extend or add alongside `posts_audit_path_test.exs`) that runs under **`mix verify.example`**: HTTP request with **`x-correlation-id`** → **`Repo.transaction`** with GUC + audited write + **`record_action/2`** with correlation → assert **non-empty** **`Threadline.timeline/2`** (or `Query.timeline/2`) using **`:correlation_id`** matching the request (and table/verb assertions as appropriate).
- **Secondary proof:** **README** — short subsection with header + **one** retrieval shape, **cross-linked** to the test module **by name** so maintainers update test first, README second.
- **Rationale:** CI is the non-negotiable contract for a security-adjacent propagation path; README answers “what do I paste?” without floating free of behavior. LOOP-03 allows “test **or**” README — we take **both** with explicit priority (test > prose).

### D-2 — HTTP semantics (`record_action` on create)

- **Golden path:** **`Blog.create_post/2`** (or the single HTTP entrypoint for `POST /api/posts`) runs **`Threadline.record_action/2`** in the **same** **`Repo.transaction/1`** as the audited insert, **after** GUC + domain write, passing **`correlation_id:`** / **`request_id:`** (and **`actor:`**, **`repo:`**) from **`Threadline.Plug`**-derived **`%AuditContext{}`** — same mental model as **`Blog.touch_post_for_job/2`** for Oban.
- **Explicit non-default:** If any **capture-only** path remains documented, label it clearly: **`:correlation_id`** timeline/export **will not** return those rows until an **`AuditAction`** is linked on the transaction (Phase 25 strict semantics).
- **Rationale:** Resolves README vs strict-filter tension; matches “command boundary = one durable audit story”; avoids integrators assuming headers alone populate queryable correlation.

### D-3 — Retrieval demonstration (timeline vs export)

- **Automated assertion:** **`Threadline.timeline/2`** with **`filters: [correlation_id: …]`** (plus **`repo:`** and scoping keys as today). Smallest moving parts; native ExUnit.
- **README:** **One** snippet showing the **same `filters`** passed to **`Threadline.export_json/2`** (e.g. **`json_format: :ndjson`**) + **one-line `jq`** hint — prose states **timeline and export share filter semantics** (LOOP-01); **do not** duplicate full parity testing in the example (library tests already own timeline ↔ export correlation parity).

### D-4 — README structure and stale `action_id` language

- **Architecture:** **Layered README** — (1) prerequisites / DB / setup unchanged, (2) **capture path** + pointer to existing audit path test, (3) **semantics + correlation bundle** — boxed **operator contract**: **`:correlation_id`** = strict join to **`audit_actions`** via **`audit_transactions.action_id`** (link to **`Threadline.Query`** / CHANGELOG for edge cases).
- **Replace** the vague “future release may tighten **`action_id`**” / “example does not rely on **`action_id`**” narrative with **current, test-backed truth** after wiring **`record_action`** on HTTP create.
- **curl:** Keep **localhost**, non-secret placeholders; **one sentence**: headers illustrate traceability; **SQL-side filters follow persisted semantics + linkage**, not raw header echo alone.
- **Doc contracts:** Preserve **REF-01** literals (`mix phx.server` **or** `iex -S mix phx.server`, `mix test`, `ecto.migrate` per `test/threadline/readme_doc_contract_test.exs`). Add new doc-contract assertions **only** if a single sentence becomes a non-negotiable public guarantee; avoid golden-file prose.

### D-5 — Cross-cutting principles (research synthesis)

- **Least surprise:** One **vertical slice** per transport (HTTP create vs Oban touch) — both use **same transaction recipe** (GUC → DML → **`record_action`** with explicit context opts).
- **DX:** Thin controller, **fat context**; correlation as **explicit opts**, not magic.
- **Operator story:** Aligns with support-loop milestone — correlation bundle is **queryable** in DB and export, not only in logs.

### Claude's Discretion

- Exact **`record_action`** name / attrs map for “post created” vs reusing an existing action key family.
- Whether to extend **`posts_audit_path_test.exs`** vs add **`posts_correlation_path_test.exs`** (prefer **one** focused module name stable for README links).
- Minor README heading wording as long as REF-01 literals remain.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap

- `.planning/REQUIREMENTS.md` — **LOOP-03**
- `.planning/ROADMAP.md` — Phase 27 success criterion (v1.8)
- `.planning/PROJECT.md` — v1.8 goals, SQL-native / operator-grade, non-goals

### Prior phase context (semantics + docs)

- `.planning/phases/25-correlation-aware-timeline-export/25-CONTEXT.md` — **`:correlation_id`** strict join, validation, JSON/CSV notes
- `.planning/phases/26-support-playbooks-doc-contracts/26-CONTEXT.md` — playbook wording vs strict correlation

### Library API & ingress

- `lib/threadline/plug.ex` — `x-correlation-id`, **`AuditContext`**
- `lib/threadline/query.ex` — **`timeline/2`**, **`validate_timeline_filters!/1`**
- `lib/threadline/export.ex` — export entrypoints, shared filters
- `CHANGELOG.md` — LOOP-01 / correlation filter narrative

### Example app (integration targets)

- `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex`
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/post_controller.ex` (or current HTTP entrypoint)
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs`
- `examples/threadline_phoenix/README.md`

### Doc contracts

- `test/threadline/readme_doc_contract_test.exs` — REF-01 literals for example README

### Domain vocabulary

- `prompts/audit-lib-domain-model-reference.md` — **AuditAction**, **AuditTransaction**, correlation

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable assets

- **`posts_audit_path_test.exs`** — ConnCase, headers, **`AuditChange`** / **`AuditTransaction`** queries; extend or sibling test for **`record_action`** + **`timeline/2`**.
- **`Blog.touch_post_for_job/2`** — Transaction-local GUC + **`record_action`** pattern to mirror on HTTP create.
- **`Threadline.Plug`** on **`:api`** — correlation already available on **`conn`** for context layer.

### Established patterns

- **Example suite** — `MIX_ENV=test mix test` in example; **`mix verify.example`** in **`mix ci.all`**.
- **Phase 25** — timeline/export share **`timeline_query/1`** / filters; example should consume **public** API, not internal query structs.

### Integration points

- **`Blog.create_post/2`** — primary place to add **`record_action`** + pass **`AuditContext`** fields into opts.
- **README** — “Audited HTTP path” and “Semantics” sections; remove contradictory **`action_id`** disclaimer after code matches story.

</code_context>

<specifics>
## Specific Ideas

- Research consensus (2026-04-24): **Tests lock behavior**, **README teaches** with cross-links; **OTel/Rails** lessons = propagate at edge + attach to **durable** artifacts you query; **Stripe-style** = state exact semantics of filters vs headers.
- **README contract:** Keep `mix phx.server` / `iex -S mix phx.server`, `mix test`, `ecto.migrate` substrings intact.

</specifics>

<deferred>
## Deferred Ideas

- LiveView operator UI — out of scope per **PROJECT.md**
- Second query mode for “orphan” capture rows — future phase (Phase 25 context explicitly deferred)
- New **`guides/support-incidents.md`** — Phase 26 deferred standalone guide

### Reviewed Todos (not folded)

- None from `todo.match-phase` for phase 27.

</deferred>

---

*Phase: 27-example-app-correlation-path*
*Context gathered: 2026-04-24*
