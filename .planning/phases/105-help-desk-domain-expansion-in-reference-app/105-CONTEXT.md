# Phase 105: Help-Desk Domain Expansion in Reference App - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Add help-desk Ecto schemas, migrations, context modules, trigger capture, and `trigger_capture` redaction config under `examples/threadline_phoenix/` only. Prove multi-table audited writes and org-scoped `audit_transactions.meta` through existing `/audit` operator surfaces. No new routes, LiveViews, controllers, or `lib/` edits.

Requirements: DEMO-01, DEMO-02, DEMO-03, DEMO-04. Visual/operator contract: `105-UI-SPEC.md` (approved).

</domain>

<decisions>
## Implementation Decisions

### Org & ticket identity (D-01)

- **D-01a:** `audit_transactions.meta` uses `%{"organization_id" => to_string(organization.id)}` — UUID string matching `organizations` PK and Phase 106 `current_user.organization_id`. Never slug or dual keys in meta.
- **D-01b:** `organizations.slug` (e.g. `"acme"`) and `organizations.name` are for seeds, docs, and future product UI only — not written to audit meta, not used in `scope_operator_query/3`.
- **D-01c:** `tickets.number` is a required integer, unique per org via `unique_index(:tickets, [:organization_id, :number])`. PK remains `:binary_id`. Phase 107 seeds Acme + `number: 4521` for WALK-03.
- **D-01d:** Ticket identity in operator surfaces comes from captured row fields (`number`, `status`, etc.) on `tickets` / `ticket_replies` change rows — not friendly aliases in capture payloads (per UI-SPEC).

**Rationale:** Separates authorization grain (stable UUID) from human narrative (slug, ticket #). Matches Shopify/GitHub pattern (stable id for ACL, display id for support). Avoids PaperTrail-style associated-id type drift and slug-rename orphaning historical audit scope.

### Semantic action catalog (D-02)

- **D-02a:** Ship **one** new help-desk action atom in Phase 105: `:ticket_replied_and_closed` (insert `ticket_replies` + update `tickets` in one `Repo.transaction`).
- **D-02b:** Defer all other help-desk `record_action` atoms (`:ticket_created`, `:ticket_reply_deleted`, etc.) until Phase 107 seeds or Phase 109 UI flows reference them in tests/walkthrough.
- **D-02c:** Multi-table pattern is **M1 (Blog clone):** `set_config('threadline.actor_ref', …)` → writes → `Threadline.record_action/2` → `Repo.update_all` on `AuditTransaction` where `txid_current()` → set `action_id` + `meta`.
- **D-02d:** One business operation = one `record_action` per transaction (Stripe/GitHub lesson). Do not split reply vs close into separate actions or transactions.
- **D-02e:** Pass `correlation_id` / `request_id` in action opts when available (parity with `Blog.create_post/2`); not required for phase exit.

**Rationale:** UI-SPEC and DEMO-02 require exactly one multi-table bundle. Expanding the catalog early violates UI-SPEC (“only actions referenced by DEMO-02 and Phase 108 seeds”) and creates catalog drift before walkthrough stories exist.

### Redaction for `internal_note_body` (D-03)

- **D-03a:** Use **`mask`** (not `exclude`) for `ticket_replies.internal_note_body` in `config :threadline, :trigger_capture` in the example app.
- **D-03b:** Enable `store_changed_from: true` on `ticket_replies` so UPDATE diffs show masked before/after without raw plaintext.
- **D-03c:** Use default placeholder `"[REDACTED]"` unless policy viewer drift requires a custom placeholder (then regenerate triggers).
- **D-03d:** Phase 108 WALK-03 incident #1 must treat internal-note content as **redaction verification** (“field present, value redacted”), not plaintext recovery.

**Rationale:** Mask proves the sensitive column participated in the change (GDPR/HIPAA accountability without hoarding content). Exclude hides the column from diffs and weakens operator “did we capture a note change?” story. Aligns with `guides/domain-reference.md`, root `config/test.exs` pedagogy, and CAP-03 (DELETE rows do not store OLD content).

### Delete semantics (D-04)

- **D-04a:** Use **hard `DELETE`** on `ticket_replies` for the walkthrough delete story — not `deleted_at` soft-delete as the primary model.
- **D-04b:** Trigger capture records `op = delete` with empty `field_changes` (shipped capture contract). “What was the note?” comes from **prior** `row_history` / INSERT-UPDATE snapshots (masked), not the delete row.
- **D-04c:** Defer `:ticket_reply_deleted` `record_action` to Phase 107 unless walkthrough draft proves trigger-only delete is insufficient for “who deleted X?” — if added, same transaction as delete with `actor_ref` GUC + org meta.
- **D-04d:** Every org-scoped delete sets `audit_transactions.meta` `%{"organization_id" => org_uuid_string}` when the app links meta (same as writes).

**Rationale:** Hard delete + `op = delete` is SQL-native and matches timeline mental model. Soft-delete conflates archive with security delete (Logidze footgun: history lost with row unless soft-delete; soft-delete confuses audit readers). Threadline deliberately does not store delete pre-images in v1.23 (`lib/` read-only).

### Help-desk verification / tests (D-05)

- **D-05a:** Phase 105 proof tests use **`ThreadlinePhoenix.DataCase`**, `async: false`, calling **`ThreadlinePhoenix.HelpDesk`** (or equivalent) with explicit `%AuditContext{actor_ref: …}` — no HTTP, no `sigra_conn`.
- **D-05b:** Assert capture like `posts_audit_path_test.exs`: join `AuditChange` → `AuditTransaction`, verify `actor_ref`, `meta["organization_id"]`, multi-table single transaction, linked action for `:ticket_replied_and_closed`.
- **D-05c:** Add `test/support/help_desk_fixtures.ex` for org → membership → agent → ticket factory chain; fixture `user_id` strings until Phase 106.
- **D-05d:** Phase 106 adds **ConnCase + real Sigra session** tests for help-desk writes (AUTH-04); keep DataCase suite as fast regression.
- **D-05e:** ROADMAP “ConnCase/integration test” for SC #3 means **database integration** in 105; HTTP integration waits for routes in 106/109.

**Rationale:** Phase 105 has no routes — HTTP tests would be fake or scope-creep. Split matches multi-tenant SaaS practice (domain contract vs auth transport) and `threadline-elixir-oss-dna.md` honest verification.

### Agent ↔ user linkage (D-06)

- **D-06a:** `agents` table has **required `user_id`** (string, Sigra-compatible) + `organization_id`; `unique_index(:agents, [:organization_id, :user_id])`; optional `display_name`.
- **D-06b:** `org_memberships` holds **auth roles** `:agent | :support` (and admin via session `is_admin`, not duplicated on `agents`).
- **D-06c:** Human help-desk capture uses `ActorRef.new(:user, user_id)` — **not** `agents.id` as actor identity. Sigra maps humans to `:user` (`Threadline.Integrations.Sigra`).
- **D-06d:** `tickets.assignee_id` FK → `agents.id` for domain queries; operator “who” questions resolve assignee → `user_id` for actor history.
- **D-06e:** `:agent` role on `current_user` (Phase 106) is a desk worker without `/audit` access; `:support` + `is_admin` retain existing operator authorization. No Threadline-owned RBAC DSL.

**Rationale:** One identity for login + audit + walkthrough “agent X” (Sigra field guide / membership model). Standalone agents without `user_id` break Phase 106 and SEED-02/03.

### Audited tables & triggers (D-07)

- **D-07a:** All five help-desk tables are audited in Phase 105: `organizations`, `org_memberships`, `agents`, `tickets`, `ticket_replies`.
- **D-07b:** After migrations: `mix threadline.gen.triggers` for example-app schema; `mix verify.threadline` coverage green (DEMO-03).
- **D-07c:** Context layout: `lib/threadline_phoenix/help_desk/` (per DEMO-01) with schemas + single orchestration context module patterned on `Blog`.

### Claude's Discretion

- Exact help-desk context function names and changeset field lists (status enums, `closed_at`, reply body vs public body).
- Whether Phase 105 includes a minimal `HelpDesk.delete_reply/2` for tests only or delete is test-helper + deferred to 107 — as long as D-04 posture is documented for seeds.
- Ticket `number` allocation strategy (`Repo.aggregate` max+1 vs explicit in tests/seeds) — must respect per-org uniqueness.

### Folded Todos

(none)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contracts

- `.planning/ROADMAP.md` § Phase 105 — success criteria, scope guard
- `.planning/REQUIREMENTS.md` — DEMO-01 through DEMO-04
- `.planning/phases/105-help-desk-domain-expansion-in-reference-app/105-UI-SPEC.md` — operator vocabulary, redaction presentation, no new UI
- `.planning/phases/104-reference-walkthrough-charter-override-decision/104-CONTEXT.md` — v1.23 non-goals, `lib/` read-only through 109

### Example app patterns (copy, do not fork)

- `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` — GUC, `record_action`, `audit_transaction_meta/1`
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — `scope_operator_query/3`, `my_authorize_fn/1`
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs` — capture assertions
- `examples/threadline_phoenix/test/support/conn_case.ex` — `sigra_conn/2` (Phase 106 only for new help-desk audit HTTP tests)

### Library capture & policy

- `lib/threadline/capture/trigger_sql.ex` — DELETE does not store OLD row content
- `lib/threadline/change_diff.ex` — op matrix (INSERT/UPDATE/DELETE)
- `config/test.exs` — `trigger_capture` mask/exclude examples
- `guides/domain-reference.md` — redaction posture

### Vision & ecosystem lessons

- `prompts/audit-lib-domain-model-reference.md` — capture vs semantics vs exploration layers
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — PaperTrail/Logidze/Carbonite footguns, queryable metadata, delete semantics
- `prompts/threadline-elixir-oss-dna.md` — verification entrypoints, host-owned auth boundary
- `prompts/prior-art/from-sigra/Auth Domain Language — A Field Guide.md` — organization/membership vocabulary
- `prompts/prior-art/oss-deep-research/ecto-best-practices-deep-research.md` — context boundary, thin schemas, transactional orchestration

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `ThreadlinePhoenix.Blog.create_post/2` — canonical transaction-local actor GUC, `record_action`, `action_id` + `meta` link via `txid_current()`
- `Blog.audit_transaction_meta/1` — org id → `%{"organization_id" => org_id}` string meta
- `ThreadlinePhoenixWeb.Router.scope_operator_query/3` — exact string match on `meta->>'organization_id'`
- `ThreadlinePhoenix.Post` — single-table audited domain precedent
- Root `config/test.exs` — `trigger_capture` mask + exclude table config shape

### Established Patterns

- Example app uses flat `snake_case` action atoms (`:post_created_via_api`)
- Operator tests use `Ecto.Adapters.SQL.Sandbox.unboxed_run/2` when nesting transactions with capture
- `ActorRef` types: `:user` for humans; jobs use `:job` / service accounts per `post_touch_worker_test`

### Integration Points

- All help-desk writes that should appear in support-scoped `/audit` must set org meta on the transaction
- `/audit/coverage` and `/audit/policy/redaction` consume triggers + `trigger_capture` config after `mix threadline.gen.triggers`
- Phase 106 binds `current_user.organization_id` to the same UUID string written in meta

</code_context>

<specifics>
## Specific Ideas

- Coherent package: **UUID in meta + per-org ticket numbers + one multi-table action + mask redaction + hard delete story + DataCase tests + agents linked to users** — optimized for SQL-native ops, Phase 108 walkthrough scripts, and zero `lib/` churn in 105.
- Ecosystem “steal list”: Carbonite transaction grouping + PaperTrail queryable metadata (via JSONB meta) + Logidze’s **avoid** record-local history and connection-metadata footguns + GitHub-style one logical action per operation.
- Phase 108 script must not promise recovery of internal note plaintext — only attribution, timing, and redaction proof.

</specifics>

<deferred>
## Deferred Ideas

- `:ticket_reply_deleted` and other semantic action atoms — Phase 107 unless planner proves need earlier
- `:ticket_created`, assignment/status actions — Phase 107/109 when UI/seeds exist
- HTTP help-desk audit path tests — Phase 106 (real Sigra)
- Soft-delete / archive lifecycle — out of scope unless product explicitly needs undo (separate action atom, not SEED-05 substitute)
- Custom redaction placeholder string — only if default `[REDACTED]` insufficient in policy viewer
- `data_before` / delete pre-image capture in `lib/` — v2 / future capture milestone

### Reviewed Todos (not folded)

(none surfaced by todo.match-phase)

</deferred>

---

*Phase: 105-help-desk-domain-expansion-in-reference-app*
*Context gathered: 2026-05-27*
