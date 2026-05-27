# Phase 111: Audited Write-Path Helper - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship `Threadline.Audit.transaction/3` in `lib/threadline/` — a single documented library call that replaces the hand-rolled `set_config` → domain writes → `record_action/2` → `audit_transactions.action_id` linkage recipe. Include PostgreSQL integration tests and guide documentation (helper snippet + doc-contract pin). Example app adoption and blog-excerpt replacement are **Phase 112**; this phase delivers the library API, tests, and canonical docs only.

Requirements: AUDIT-TXN-01, AUDIT-TXN-02, AUDIT-TXN-03, AUDIT-TXN-04.

</domain>

<decisions>
## Implementation Decisions

### Public API surface (D-111-01)

- **D-111-01a:** Module **`Threadline.Audit`**, function **`transaction/3`**: `Threadline.Audit.transaction(repo, opts, fun)`.
- **D-111-01b:** Arity matches Ecto mental model: repo first, options second, zero-arity callback third — same ordering as `Repo.transaction/2` + callback, with opts inserted for audit ceremony.
- **D-111-01c:** Does **not** replace `Threadline.Plug`, `Threadline.Job`, or host context modules. Plug/Job stay at the HTTP/job edge; the helper is called from Phoenix context functions (or Oban workers) after actor/context is resolved.
- **D-111-01d:** No macro DSL, no mandatory `Ecto.Multi` integration in v1.24.0 — explicit `fn ->` callback only. Multi composition remains a host concern inside the callback until a concrete adopter need justifies a `:multi` opt.

### Return contract (D-111-02)

- **D-111-02a:** Success/error shape stays **`{:ok, result} | {:error, reason}`** — two-tuple only, mirroring `Ecto.Repo.transaction/1`. No third tuple element (breaks `with` chains and Elixir convention).
- **D-111-02b:** When the callback returns a **map**, the helper **merges** `:audit_transaction_id` into that map on success. This matches today's `Blog.create_post/2` return shape (`%{post: post, audit_transaction_id: uuid}`) with zero adapter code at call sites that already return domain-keyed maps.
- **D-111-02c:** When the callback returns a **non-map** (struct, scalar, tuple), the helper wraps as **`%{result: value, audit_transaction_id: uuid}`** — avoids key collision on structs, documents the rule in moduledoc.
- **D-111-02d:** `:audit_transaction_id` is populated on every successful path where capture produced an `audit_transactions` row (normal PostgreSQL trigger path after domain writes). Omitted only on `{:error, _}`.
- **D-111-02e:** Reject side-channel patterns (Process dict, Logger metadata, post-txn query helpers as primary contract). Optional read helper deferred unless planning discovers a concrete need.

### Action recording policy (D-111-03)

- **D-111-03a:** **`:action` opt present → correlation-ready path:** helper calls `Threadline.record_action/2` after the callback succeeds, then links `audit_transactions.action_id` via `txid_current()` update — same recipe as `Blog.create_post/2`, never manual at call sites.
- **D-111-03b:** **`:action` absent → capture-only path:** helper sets GUC + runs callback only. Row capture and actor on `audit_transactions` still work; strict `:correlation_id` timeline/export filters **will not match** — document prominently in moduledoc and guides.
- **D-111-03c:** **`:capture_only: true`** — explicit alias for capture-only (same semantics as omitting `:action`). Signals intent in code review; useful for batch/internal writes where inventing action names adds noise.
- **D-111-03d:** Do **not** require `:action` for every write (batch noise, fake intent). Do **not** leave linkage manual when `:action` is present (SEED-001 foot-gun). The recommended SaaS write path always passes `:action`.
- **D-111-03e:** `:action` accepts atom (`:post_created_via_api`) or tuple `{:post_created_via_api, action_opts}` where `action_opts` are forwarded to `record_action/2` (correlation_id, request_id, job_id, verb, reason, etc.).

### Missing actor_ref policy (D-111-04)

- **D-111-04a:** **Default: fail before transaction** with `{:error, :missing_actor}` when `actor_ref` is nil — matches `Blog.create_post/2`, `HelpDesk.*`, and AUDIT-TXN-03 predictable failure.
- **D-111-04b:** **Nil is not anonymous.** Host `actor_fn` must return an explicit `%ActorRef{}` for routes that call the helper — including `ActorRef.new(:anonymous)` for intentional unauthenticated writes, or `:system` / `:service_account` for jobs. Nil means "host did not decide," not "guest user."
- **D-111-04c:** **Opt-in escape:** `allow_missing_actor: true` permits capture-only with NULL `audit_transactions.actor_ref`. Document as **non-recommended for multi-tenant SaaS**; acceptable for migrations, seeds, tests, internal batch paths.
- **D-111-04d:** When `:action` is present, **`allow_missing_actor` is ignored** — action recording requires a valid actor (fail `{:error, :missing_actor}`).

### Callback contract (D-111-05)

- **D-111-05a:** Callback shape: **`fn -> domain_result end`** with `Repo` captured in closure (Phoenix context style). No `repo` argument — avoids redundant second authority and matches existing `Repo.transaction(fn -> ... end)` patterns.
- **D-111-05b:** **Inside callback:** domain inserts/updates/deletes only. On failure, `Repo.rollback(reason)` and return (standard Ecto transaction semantics).
- **D-111-05c:** **Outside callback (helper-owned):** open transaction, `set_config('threadline.actor_ref', …, true)` once before callback, optional `record_action` + `action_id` link + `audit_transaction_id` lookup after callback success.
- **D-111-05d:** **Forbidden inside callback** (moduledoc + integration test): `set_config` for actor GUC, `Threadline.record_action/2`, nested `Repo.transaction/1`. Prevents double-GUC, orphaned actions, and `txid_current()` linkage breaks.
- **D-111-05e:** On linkage failure (`update_all` count != 1), rollback with **`:missing_audit_transaction_for_link`** — preserve existing example app atom for consistent error handling.

### Options / ergonomics (D-111-06)

- **D-111-06a:** Required opt: **`:actor_ref`** (`%ActorRef{}`) unless `audit_context:` sugar is used (see below).
- **D-111-06b:** **`audit_context: %AuditContext{}`** sugar — extracts `actor_ref`, `correlation_id`, `request_id` from Plug-assigned context. Satisfies AUDIT-TXN-02 without requiring hosts to pass `%AuditContext{}` into the callback or destructure manually. Host may still pass explicit `actor_ref` + metadata opts for Oban paths.
- **D-111-06c:** **`:transaction_meta`** — map merged into `audit_transactions.meta` when linking action (Blog `organization_id` pattern). Nil when absent.
- **D-111-06d:** Correlation fields (`:correlation_id`, `:request_id`, `:job_id`) may be passed at top-level opts and forwarded into `record_action/2` when `:action` is an atom (not only via action tuple).
- **D-111-06e:** Stable error reasons: `:missing_actor`, `:missing_audit_transaction_for_link`, `%Ecto.Changeset{}` from domain or action validation — actionable `{:error, reason}` per OSS DNA.

### Documentation & contracts (D-111-07)

- **D-111-07a:** Add helper section to **`guides/getting-started-saas.md`** (step 6 area) and **`guides/integration-contracts.md`** (new "Audited write path" section) as the **recommended write path**.
- **D-111-07b:** Doc-contract test locks canonical **`Threadline.Audit.transaction/3`** snippet literal (new marker block in guide or fixture module) — separate from existing `blog-create-post-transaction` marker (Phase 112 replaces that marker).
- **D-111-07c:** Moduledoc includes: capture-only vs correlation-ready table, forbidden callback operations, nil-actor policy, and pointer to strict `:correlation_id` semantics in `Threadline.Query`.

### Claude's Discretion

- Exact internal function decomposition within `Threadline.Audit` (private helpers for GUC encode, link, id lookup).
- Whether to ship a `@doc false` `Threadline.Audit.Result` struct for internal typing only (not public return contract).
- Test module organization (`audit_transaction_test.exs` vs extending existing semantics tests).
- Minor moduledoc examples for Oban job call site (Phase 112 will provide the live example).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Vision & domain model
- `prompts/audit-lib-domain-model-reference.md` — Three-layer model (capture / semantics / exploration); AuditTransaction vs AuditAction separation; "correct by default" principles
- `prompts/THREADLINE-GSD-IDEA.md` — Core value, semantics hook intent, non-goals
- `prompts/threadline-elixir-oss-dna.md` — Named verify entrypoints, doc-contract tests, actionable errors, explicit orchestration over magic

### Ecosystem & product strategy
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — Carbonite/PaperTrail/Logidze/django-auditlog lessons; metadata propagation footguns; blessed Plug/job context pattern
- `.planning/v1.24-seeds/SEED-001-audited-write-transaction.md` — Primary motivation; action_id linkage as #1 adoption foot-gun

### Requirements & milestone
- `.planning/REQUIREMENTS.md` — AUDIT-TXN-01 through AUDIT-TXN-04 (locked)
- `.planning/ROADMAP.md` — Phase 111 scope guard (lib + test + guides only; example deferred to 112)
- `.planning/threads/2026-05-27-milestone-next-step-v1.24.md` — Milestone intent and assessment

### Existing implementation patterns (reference, do not modify in Phase 111)
- `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` — Golden manual recipe (`blog-create-post-transaction` marker)
- `examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex` — Second copy of linkage recipe
- `lib/threadline.ex` — `record_action/2` opts and error shapes
- `lib/threadline/plug.ex` — GUC set_config pattern for actor_ref
- `lib/threadline/job.ex` — Job actor_ref serialization for Oban paths
- `lib/threadline/query.ex` — Strict `:correlation_id` join semantics
- `test/threadline/getting_started_saas_doc_contract_test.exs` — Doc-contract patterns for guide literals

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.record_action/2` — semantic action insertion; already validates actor and repo
- `Threadline.Plug` / `Threadline.Job` — edge context producers; not modified by this phase
- `Threadline.Capture.AuditTransaction` schema — `action_id`, `meta`, `txid` fields for linkage
- `Threadline.Semantics.ActorRef` — `to_map/1`, `new/2` for GUC encoding and anonymous/system actors
- `blog-create-post-transaction` doc marker — current canonical snippet source (Phase 112 migrates to helper marker)

### Established Patterns
- Manual recipe repeated in Blog + HelpDesk: encode actor → transaction → set_config → writes → record_action → update_all by txid → fetch audit_transaction_id
- `touch_post_for_job/2` records action but **does not link action_id** — known gap; Phase 112 fixes via helper adoption
- Doc-contract tests extract fenced regions via `GettingStartedFixtures.extract!/2`
- Error atoms: `:missing_actor`, `:missing_audit_transaction_for_link` already used in example app

### Integration Points
- New module: `lib/threadline/audit.ex` (or `lib/threadline/audit/transaction.ex` if split — planner decides)
- Tests: `test/threadline/audit_transaction_test.exs` (PostgreSQL integration)
- Guides: `guides/getting-started-saas.md`, `guides/integration-contracts.md`
- Doc contract: extend or add test file pinning helper snippet literal

</code_context>

<specifics>
## Specific Ideas

### Canonical call site (target shape for guides + Phase 112)

```elixir
Threadline.Audit.transaction(
  Repo,
  [
    audit_context: audit_context,
    action: :post_created_via_api,
    transaction_meta: %{"organization_id" => org_id}
  ],
  fn ->
    case Repo.insert(Post.changeset(%Post{}, attrs)) do
      {:ok, post} -> %{post: post}
      {:error, changeset} -> Repo.rollback(changeset)
    end
  end
)
# => {:ok, %{post: %Post{}, audit_transaction_id: <<uuid>>}}
```

### Oban job path (Phase 112 target)

```elixir
with {:ok, actor_ref} <- Threadline.Job.actor_ref_from_args(args) do
  Threadline.Audit.transaction(
    Repo,
    [
      actor_ref: actor_ref,
      action: {:post_title_refreshed_from_queue, Threadline.Job.context_opts(args)}
    ],
    fn ->
      # domain update...
    end
  )
end
```

### Research synthesis — what we learned from other ecosystems

- **Got right elsewhere:** explicit transaction/event handles for drill-down (Carbonite, COMP-01 JSON path); typed principals not NULL-as-user (CloudTrail, ActorRef taxonomy); middleware for actor binding (django-auditlog, PaperTrail whodunnit).
- **Footguns to avoid:** implicit connection-local metadata (Logidze + PgBouncer); record_action without linkage (current `touch_post_for_job`); side-channel audit IDs; collapsing capture and semantics into one blob; requiring fake action names on every batch write.

</specifics>

<deferred>
## Deferred Ideas

- `Ecto.Multi` first-class integration (`action: {:multi, multi}`) — defer until adopter demand; hosts flatten Multi steps inside callback for now
- `Threadline.Audit.Result` as public return struct — envelope adds ceremony; map merge is sufficient
- Example app refactor (`Blog`, `HelpDesk`, `touch_post_for_job`) — **Phase 112**
- Replacing `blog-create-post-transaction` doc marker — **Phase 112** (Phase 111 adds new helper marker alongside)
- Lint/static analysis for forbidden callback operations — moduledoc + tests sufficient for v1.24.0
- Capture-only adopters using helper with `allow_missing_actor: true` in production — document as escape hatch, not recommended path

</deferred>

---

*Phase: 111-audited-write-path-helper*
*Context gathered: 2026-05-27*
