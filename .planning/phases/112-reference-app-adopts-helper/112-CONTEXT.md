# Phase 112: Reference App Adopts Helper - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Refactor `examples/threadline_phoenix/` primary audited write paths and `guides/getting-started-saas.md` to use `Threadline.Audit.transaction/3` instead of hand-rolled `set_config` → domain writes → `record_action/2` → `action_id` linkage. Existing audit/correlation tests must stay green without weakened assertions. README quickstart cross-links the helper.

Requirements: ADOPT-HELPER-01, ADOPT-HELPER-02, ADOPT-HELPER-03.

Scope guard: `examples/threadline_phoenix/` + `guides/getting-started-saas.md` + README cross-links. `lib/` read-only **except** bugfixes blocking example adoption (capture-only `:transaction_meta` — see D-112-01).

Out of scope: demo seed backdating (`Demo.Seed.Support`), registration bootstrap (`provision_default_workspace_for_user/2`), `incident_replay.exs`, sweeping all `set_config` in the tree.

</domain>

<decisions>
## Implementation Decisions

### Migration breadth (D-112-01)

- **D-112-01a:** Migrate **four** primary write paths to the helper:
  1. `Blog.create_post/2` — HTTP correlation-ready path
  2. `HelpDesk.ticket_replied_and_closed/6` — HTTP correlation-ready path
  3. `Blog.touch_post_for_job/2` — Oban correlation-ready path (fixes SEED-001 orphaned-action linkage footgun)
  4. `HelpDesk.delete_reply/3` — capture-only path with `:capture_only: true` (no `:action` per D-107-05d)
- **D-112-01b:** **Do not migrate** demo seeds, `provision_default_workspace_for_user/2`, or maintainer scripts — bootstrap/fixture territory, not first-hour integrator paths.
- **D-112-01c:** **Prerequisite lib bugfix** (allowed under scope guard): extend `Threadline.Audit.transaction/3` capture-only finalize to apply `:transaction_meta` via meta-only `update_all` when `:action` is absent — required for `delete_reply/3` org scoping without inventing fake semantic actions. Add integration test: `"transaction_meta stored on capture-only audit_transaction"`.
- **D-112-01d:** Strengthen `post_touch_worker_test.exs` to assert `audit_transactions.action_id == audit_actions.id` after helper migration (linkage proof, not just action existence).

### Guide & doc-marker sync (D-112-02)

- **D-112-02a:** **Replace** the legacy manual recipe block in `guides/getting-started-saas.md` §6 entirely — one fenced helper snippet, one adoption path for first-hour integrators.
- **D-112-02b:** Move `blog-create-post-transaction` doc marker interior in `blog.ex` to wrap the helper call (marker stays in example app per Phase 47 D-03; kebab name unchanged).
- **D-112-02c:** **No second fenced manual block** in getting-started. Advanced mechanics (forbidden callback ops, GUC internals, `txid_current()` linkage) live in `guides/integration-contracts.md` § Audited write path + `Threadline.Audit` moduledoc — link-out only, B-lite pointer.
- **D-112-02d:** Retain `audit-transaction-helper` marker in `lib/threadline/audit.ex` for AUDIT-TXN-04 library doc contract — **not** the getting-started extract source. Example app remains SSOT for first-hour snippet.
- **D-112-02e:** Align helper snippet shape across example marker, guide §6, and `integration-contracts.md` to rollback-safe `case`/`Repo.rollback` (not bang inserts).
- **D-112-02f:** Doc-contract test changes: `blog_block()` asserts helper interior; add `refute String.contains?(doc, "Legacy manual recipe")`; keep router/mount anchors unchanged.

### Capture-only deletes (D-112-03)

- **D-112-03a:** Migrate `HelpDesk.delete_reply/3` to helper with **`capture_only: true`** + **`transaction_meta: audit_transaction_meta(org)`** — explicit signal that omission of `:action` is intentional (D-111-03c), not a bug.
- **D-112-03b:** **Do not** add `:ticket_reply_deleted` `record_action` (D-107-05d) — actor on capture transaction + row DELETE diff is sufficient semantic truth for hard deletes.
- **D-112-03c:** Normalize return shape to preserve existing contract: `{:ok, :deleted}` at public API (unwrap helper `%{result: :deleted, audit_transaction_id: _}` if present).
- **D-112-03d:** Unify error atom on helper path: `:missing_audit_transaction_for_link` (drop one-off `:missing_audit_transaction_for_delete`).
- **D-112-03e:** Optionally strengthen `help_desk_audit_test.exs` to assert `at.meta["organization_id"]` on delete transaction (107 verification intent; test gap today).

### Oban job return envelope (D-112-04)

- **D-112-04a:** `touch_post_for_job/2` returns **`{:ok, %{post: %Post{}, audit_transaction_id: uuid}}`** — same domain-keyed envelope as `create_post/2` (Phase 111 map-merge contract).
- **D-112-04b:** Callback returns `%{post: updated}` inside helper; helper merges `:audit_transaction_id`.
- **D-112-04c:** `PostTouchWorker` keeps collapsing to `:ok` / `{:error, reason}` — rich envelope stays in context layer for tests/seeds/future drill-down; worker remains thin edge adapter.
- **D-112-04d:** **Reject** opt-in `return_audit:` flag or struct-only return — one canonical audited-write envelope per context module (principle of least surprise, OSS DNA single blessed pattern).
- **D-112-04e:** Oban action opts: `action: {:post_title_refreshed_from_queue, Job.context_opts(args)}` — preserves job_id/correlation_id forwarding.

### README & cross-links (D-112-05)

- **D-112-05a:** Example README "Semantics in jobs" section updates to describe helper-based `touch_post_for_job/2` (not hand-rolled GUC + record_action).
- **D-112-05b:** Root/example README quickstart pointer mentions `Threadline.Audit.transaction/3` as the first audited write path (ADOPT-HELPER-03).

### Ecosystem synthesis (locked rationale)

- **django-auditlog:** middleware + `set_actor` for HTTP/jobs — Threadline's Plug/Job + helper mirrors this; maintenance deletes use explicit opt-out, not fake action names.
- **Carbonite / trigger capture:** metadata on transaction record without requiring semantic event — supports capture-only `:transaction_meta` lib fix.
- **PaperTrail / Logidze footguns:** opt-in capture and connection-local metadata — Threadline avoids via triggers + explicit write-boundary helper.
- **SEED-001:** #1 adoption footgun is `record_action` without `action_id` linkage — `touch_post_for_job` migration is non-negotiable for honest reference app.
- **JaVers / operator drill-down:** `audit_transaction_id` on success maps enable incident bundles — discarding it at job boundary (struct-only return) fights COMP-01 path.

### Claude's Discretion

- Exact `with`/`case` nesting inside migrated context functions.
- Whether to rename doc marker to `blog-create-post-audit-transaction` (kebab-descriptive) — optional; not required if interior changes.
- Moduledoc wording polish on migrated functions.
- Whether to add correlation timeline assertion in `post_touch_worker_test` beyond action_id linkage.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Vision & domain model
- `prompts/audit-lib-domain-model-reference.md` — Three-layer model; capture vs semantics; AuditTransaction.meta for tenancy scope
- `prompts/THREADLINE-GSD-IDEA.md` — Core value; correct-by-default; non-goals
- `prompts/threadline-elixir-oss-dna.md` — Doc contracts, dual-contract README↔guides↔example, actionable errors
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — Ecosystem footguns; context propagation; happy path + escape hatches

### Requirements & milestone
- `.planning/REQUIREMENTS.md` — ADOPT-HELPER-01 through ADOPT-HELPER-03
- `.planning/ROADMAP.md` — Phase 112 scope guard and success criteria
- `.planning/v1.24-seeds/SEED-001-audited-write-transaction.md` — Linkage footgun motivation

### Prior phase decisions (locked)
- `.planning/phases/111-audited-write-path-helper/111-CONTEXT.md` — Helper API contract D-111-01 through D-111-07
- `.planning/phases/107-realistic-seed-data-demo-mix-tasks/107-CONTEXT.md` — D-107-05d (no delete action)
- `.planning/milestones/v1.14-phases/47-saas-adopter-onramp/47-CONTEXT.md` — D-03 doc marker format (example app anchors)

### Implementation targets
- `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` — create_post, touch_post_for_job, blog-create-post-transaction marker
- `examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex` — ticket_replied_and_closed, delete_reply
- `examples/threadline_phoenix/lib/threadline_phoenix/workers/post_touch_worker.ex` — Oban edge
- `lib/threadline/audit.ex` — helper + capture-only meta bugfix
- `guides/getting-started-saas.md` — §6 first audited write
- `guides/integration-contracts.md` — Audited write path section (escape hatch docs)
- `test/threadline/getting_started_saas_doc_contract_test.exs` — blog_block contract
- `test/threadline/audit_doc_contract_test.exs` — lib marker contract

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Audit.transaction/3` — shipped Phase 111; map-merge return envelope
- `Threadline.Job.actor_ref_from_args/1` + `context_opts/1` — Oban actor/correlation for touch_post_for_job
- `blog-create-post-transaction` marker — doc contract extract source (interior swaps to helper)
- `audit-transaction-helper` marker in `lib/threadline/audit.ex` — library doc contract only

### Established Patterns
- HTTP paths: `audit_context:` + `:action` + optional `:transaction_meta`
- Job paths: `actor_ref:` + `action: {:name, Job.context_opts(args)}`
- Capture-only: omit `:action` or `:capture_only: true` — **gap:** `:transaction_meta` not applied today without action (D-112-01c fix)
- Doc contract: `GettingStartedFixtures.extract!/2` pins example-app literals

### Integration Points
- Tests: `posts_audit_path_test`, `posts_correlation_path_test`, `help_desk_audit_http_test`, `help_desk_audit_test`, `post_touch_worker_test`
- Guide §6 ↔ blog.ex marker ↔ example app implementation (triple sync)
- README "Semantics in jobs" ↔ touch_post_for_job after migration

</code_context>

<specifics>
## Specific Ideas

### Canonical HTTP call site (blog.ex marker target)

```elixir
Threadline.Audit.transaction(
  Repo,
  [
    audit_context: audit_context,
    action: :post_created_via_api,
    transaction_meta: audit_transaction_meta(opts)
  ],
  fn ->
    case Repo.insert(Post.changeset(%Post{}, attrs)) do
      {:error, changeset} -> Repo.rollback(changeset)
      {:ok, post} -> %{post: post}
    end
  end
)
```

### Canonical Oban call site

```elixir
Threadline.Audit.transaction(
  Repo,
  [
    actor_ref: actor_ref,
    action: {:post_title_refreshed_from_queue, Job.context_opts(args)}
  ],
  fn ->
    case Repo.update(Post.changeset(post, %{title: title})) do
      {:error, cs} -> Repo.rollback(cs)
      {:ok, updated} -> %{post: updated}
    end
  end
)
# => {:ok, %{post: %Post{}, audit_transaction_id: id}}
```

### Capture-only delete call site

```elixir
Threadline.Audit.transaction(
  Repo,
  [
    audit_context: audit_context,
    capture_only: true,
    transaction_meta: audit_transaction_meta(organization)
  ],
  fn ->
    Repo.delete!(reply)
    :deleted
  end
)
```

### Guide §6 after migration (structure)

Single helper fenced block extracted from `blog.ex` marker → prose notes on `:audit_transaction_id` / capture-only → link to integration-contracts for advanced mechanics → curl exercise unchanged.

</specifics>

<deferred>
## Deferred Ideas

- Demo seed `set_config` sweep (`Demo.Seed.Support`) — maintainer tooling; not first-hour path
- `provision_default_workspace_for_user/2` audit wrapping — registration bootstrap without request actor
- `:ticket_reply_deleted` semantic action — deferred per D-107-05d unless Phase 108+ proves correlation need
- Lint/static analysis for forbidden callback operations — moduledoc + tests sufficient for v1.24
- Doc marker rename to `blog-create-post-audit-transaction` — cosmetic; optional

</deferred>

---

*Phase: 112-reference-app-adopts-helper*
*Context gathered: 2026-05-27*
