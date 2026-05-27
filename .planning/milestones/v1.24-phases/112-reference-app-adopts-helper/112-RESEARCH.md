# Phase 112: Reference App Adopts Helper — Research

**Researched:** 2026-05-27  
**Phase:** 112 — Reference App Adopts Helper  
**Status:** Complete

## Summary

Phase 112 migrates four primary audited write paths in `examples/threadline_phoenix/` from the hand-rolled `set_config` → domain writes → `record_action/2` → `action_id` linkage recipe to `Threadline.Audit.transaction/3` (shipped Phase 111 in `lib/threadline/audit.ex`). It replaces the dual-snippet §6 in `guides/getting-started-saas.md` with a single helper excerpt sourced from the `blog-create-post-transaction` doc marker, and adds README cross-links per ADOPT-HELPER-03.

**Prerequisite lib bugfix:** capture-only paths (`:action` absent / `:capture_only: true`) do not apply `:transaction_meta` today — `finalize_success/3` at `lib/threadline/audit.ex:187-188` skips straight to `attach_audit_transaction_id/2`. This blocks `HelpDesk.delete_reply/3` adoption, which today applies org meta via a manual meta-only `update_all` at `help_desk.ex:250-254`.

---

## 1. Manual write paths vs target helper calls (per function)

### `Blog.create_post/2` — `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex:21-79`

| Aspect | Current (manual) | Target (helper) |
|--------|------------------|-----------------|
| Actor guard | `audit_context.actor_ref` nil → `{:error, :missing_actor}` (`:22-24`) | Helper pre-txn validation via `audit_context:` sugar |
| Transaction body | `Repo.transaction` + `set_config` (`:34`) + insert + `record_action` + `update_all` + fetch id (`:48-73`) | `Threadline.Audit.transaction(Repo, [audit_context:, action: :post_created_via_api, transaction_meta: audit_transaction_meta(opts)], fn -> … end)` |
| Doc marker | `# doc: start/end: blog-create-post-transaction` wraps manual interior (`:33-77`) | Marker **unchanged**; interior swaps to helper call (D-112-02b) |
| Return | `{:ok, %{post:, audit_transaction_id:}}` from txn callback (`:73`) | Same envelope via helper map-merge (D-111-02b) |
| Removable imports | `AuditTransaction`, `AuditAction` aliases (`:6-7`) | Drop after migration if unused |

**Target callback shape (rollback-safe, D-112-02e):**

```elixir
fn ->
  case Repo.insert(Post.changeset(%Post{}, attrs)) do
    {:error, changeset} -> Repo.rollback(changeset)
    {:ok, post} -> %{post: post}
  end
end
```

**Call site:** `post_controller.ex:24` passes `organization_id:` opt — unchanged.

---

### `HelpDesk.ticket_replied_and_closed/6` — `help_desk.ex:136-219`

| Aspect | Current (manual) | Target (helper) |
|--------|------------------|-----------------|
| Actor guard | Same nil check (`:145-147`) | `audit_context:` sugar |
| Transaction body | `set_config` (`:156`) → insert reply → update ticket → `record_action(:ticket_replied_and_closed)` → link + meta (`:183-214`) | Single `Threadline.Audit.transaction/3` with `action: :ticket_replied_and_closed`, `transaction_meta: audit_transaction_meta(organization)` |
| Meta source | `audit_transaction_meta(organization)` → `%{"organization_id" => to_string(org_id)}` (`:269-271`) | Same via `:transaction_meta` opt |
| Return | `%{ticket:, reply:, audit_transaction_id:}` (`:210-214`) | Same map-merge envelope |
| HTTP test anchor | `help_desk_audit_http_test.exs:37-43` asserts `at.meta["organization_id"]` | Must stay green |

**Call sites:** `help_desk_dev_controller.ex:19`, demo seeds (`demo/seed/anchors.ex`) — behavior unchanged, implementation only.

---

### `Blog.touch_post_for_job/2` — `blog.ex:99-137` (SEED-001 footgun)

| Aspect | Current (manual) | Target (helper) |
|--------|------------------|-----------------|
| Actor | `Job.actor_ref_from_args/1` (`:100-104`) | Unchanged pre-helper |
| Transaction body | `set_config` (`:117`) → update → `record_action(:post_title_refreshed_from_queue, …)` (`:129-131`) | Helper with `actor_ref:`, `action: {:post_title_refreshed_from_queue, Job.context_opts(args)}` |
| **Linkage gap** | Records action but **never** sets `audit_transactions.action_id` (`:129-131` returns `updated` only) | Helper links automatically when `:action` present (D-112-01a #3) |
| Return | `{:ok, %Post{}}` struct from txn (`:130`) | `{:ok, %{post: %Post{}, audit_transaction_id: uuid}}` (D-112-04a) |
| Worker edge | `PostTouchWorker` matches `{:ok, _post}` (`post_touch_worker.ex:15-16`) | Still valid — map matches `_post` |

**Target callback:**

```elixir
fn ->
  post = Repo.get!(Post, post_id)
  case Repo.update(Post.changeset(post, %{title: title})) do
    {:error, cs} -> Repo.rollback(cs)
    {:ok, updated} -> %{post: updated}
  end
end
```

---

### `HelpDesk.delete_reply/3` — `help_desk.ex:229-267` (capture-only)

| Aspect | Current (manual) | Target (helper) |
|--------|------------------|-----------------|
| Semantics | No `record_action` (D-107-05d) | `:capture_only: true`, no `:action` |
| Meta | Manual meta-only `update_all` (`:250-254`) | `:transaction_meta: audit_transaction_meta(organization)` — **requires lib bugfix** |
| Error atom | `:missing_audit_transaction_for_delete` (`:257`) | `:missing_audit_transaction_for_link` (D-112-03d) |
| Public return | `{:ok, :deleted}` via unwrap (`:262-265`) | Unwrap helper `%{result: :deleted, audit_transaction_id: _}` → `{:ok, :deleted}` (D-112-03c) |

---

### Explicitly **not** migrated (D-112-01b)

| Function | Location | Reason |
|----------|----------|--------|
| `provision_default_workspace_for_user/2` | `help_desk.ex:21-50` | Registration bootstrap, no request actor |
| Demo seed paths | `demo/seed/*`, `Demo.Seed.Support` | Maintainer tooling |
| `incident_replay.exs` | Out of scope per CONTEXT |

---

## 2. Lib bugfix — capture-only `:transaction_meta`

### Problem

```185:197:lib/threadline/audit.ex
  defp finalize_success(repo, resolved, result) do
    case resolved.action_name do
      nil ->
        attach_audit_transaction_id(repo, result)

      action_name ->
        with {:ok, %AuditAction{id: action_id}} <- record_action(repo, resolved, action_name),
             :ok <- link_action(repo, action_id, resolved.transaction_meta),
             ...
```

When `action_name` is `nil`, `:transaction_meta` is never written. Correlation-ready paths apply meta in `link_action/3` (`:217-222`), which sets both `action_id` and `meta`.

`HelpDesk.delete_reply/3` today does the meta-only update manually:

```248:254:examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex
          meta = audit_transaction_meta(organization)

          {count, _} =
            Repo.update_all(
              from(at in AuditTransaction, where: at.txid == fragment("txid_current()")),
              set: [meta: meta]
            )
```

### Fix approach (D-112-01c)

In `lib/threadline/audit.ex`, extend the capture-only branch of `finalize_success/3`:

1. When `resolved.transaction_meta` is non-nil, run a meta-only `update_all` on `audit_transactions` where `txid == txid_current()` (mirror `link_action/3` but `set: [meta: transaction_meta]` only).
2. If count != 1, return `{:error, :missing_audit_transaction_for_link}` (same atom as linkage failures — D-112-03d).
3. Then call existing `attach_audit_transaction_id/2`.

Suggested private helper: `apply_capture_meta/2` or extend `link_action/3` with an optional `action_id: nil` mode — planner chooses decomposition.

### Test to add

**File:** `test/threadline/audit_transaction_test.exs` (alongside existing `"transaction_meta stored on linked audit_transaction"` at `:157-175`)

**New test name:** `"transaction_meta stored on capture-only audit_transaction"`

**Shape:**

```elixir
Threadline.Audit.transaction(
  Repo,
  [
    actor_ref: actor,
    capture_only: true,
    transaction_meta: %{"organization_id" => "org-capture-only"}
  ],
  fn -> insert_row!("capture-meta"); :done end
)
# assert Repo.get!(AuditTransaction, id).meta == %{"organization_id" => "org-capture-only"}
# assert action_id is nil
```

Existing linked-meta test proves the action path; this closes the capture-only gap.

---

## 3. Tests that must stay green + assertions to strengthen

### Must stay green (ADOPT-HELPER-02) — no weakened assertions

| Test file | What it proves | Migration sensitivity |
|-----------|----------------|----------------------|
| `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs` | HTTP POST captures change + actor on transaction (`:9-45`) | `create_post` helper swap — actor/capture unchanged |
| `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs` | Strict `:correlation_id` timeline match (`:6-77`) | Requires `:action` + linkage — helper preserves |
| `examples/threadline_phoenix/test/threadline_phoenix/help_desk_audit_http_test.exs` | HTTP reply actor + `at.meta["organization_id"]` (`:11-44`) | `ticket_replied_and_closed` helper swap |
| `examples/threadline_phoenix/test/threadline_phoenix/help_desk_audit_test.exs` | Multi-table capture, redaction, delete audit row (`:13-101`) | Both HelpDesk paths |
| `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` | Seeded `ticket_replied_and_closed` action on #4521 | Indirect — uses migrated functions |
| `examples/threadline_phoenix/test/threadline_phoenix/workers/post_touch_worker_test.exs` | Job capture + action with job_id/correlation (`:12-64`) | `touch_post_for_job` — **linkage gap today** |

### Assertions to **strengthen** (locked in CONTEXT)

| File | Line(s) | Addition |
|------|---------|----------|
| `post_touch_worker_test.exs` | after `:58` | `assert at.action_id == action.id` — proves SEED-001 linkage fix (D-112-01d) |
| `post_touch_worker_test.exs` | optional (D-112 discretion) | Correlation timeline row via `Threadline.timeline/2` with job correlation_id |
| `help_desk_audit_test.exs` | after `:84` in delete test | Fetch delete-path `AuditTransaction`, assert `at.meta["organization_id"] == to_string(org.id)` (D-112-03e) |

### Lib tests (prerequisite plan)

| File | Test |
|------|------|
| `test/threadline/audit_transaction_test.exs` | New capture-only `transaction_meta` test (§2) |

### Doc-contract tests touched by guide/marker changes

| File | Current contract | Phase 112 change |
|------|------------------|------------------|
| `test/threadline/getting_started_saas_doc_contract_test.exs` | `blog_block()` extracts `blog-create-post-transaction` marker (`:121-126`); asserts marker text in guide via `assert String.contains?(doc, blog_block())` (`:37`) | Marker interior becomes helper → guide §6 must match; add `refute String.contains?(doc, "Legacy manual recipe")` (D-112-02f) |
| `test/threadline/audit_doc_contract_test.exs` | Locks `audit-transaction-helper` in `lib/threadline/audit.ex` — **unchanged** (D-112-02d) | No marker move to lib for getting-started extract |
| `test/threadline/integration_contracts_doc_contract_test.exs` | Asserts `Threadline.Audit.transaction/3` section (`:130-131`) | Optional: align snippet to rollback-safe `case`/`Repo.rollback` (D-112-02e) — not in Phase 112 scope guard unless planner bundles |

---

## 4. Doc contract changes

### `guides/getting-started-saas.md` §6 (`:83-173`)

**Current structure:**

- `### Recommended path (v1.24+)` — helper snippet with rollback-safe `case` (`:85-110`)
- `### Legacy manual recipe (reference app)` — full manual block extracted from old marker (`:112-161`)
- curl exercise (`:163-173`)

**Target (D-112-02a-c):**

1. **Remove** entire `### Legacy manual recipe (reference app)` subsection (`:112-161`).
2. **Single fenced block** = helper interior from `blog.ex` marker (example app SSOT per Phase 47 D-03).
3. Prose: `:audit_transaction_id` on success, capture-only opt-out, link to `guides/integration-contracts.md` § Audited write path for forbidden-callback / GUC internals (B-lite pointer).
4. Keep curl exercise unchanged (`:165-171`).
5. Retain downstream phrases still asserted elsewhere (e.g. `"capture-only path for now"` at `:54` in doc-contract — lives outside §6, unchanged).

### `blog.ex` doc marker

- **Marker name:** `blog-create-post-transaction` — unchanged (D-112-02b)
- **Interior:** `Threadline.Audit.transaction(...)` call wrapping rollback-safe insert callback
- **Extract path:** `GettingStartedFixtures.extract!("examples/threadline_phoenix/lib/threadline_phoenix/blog.ex", "blog-create-post-transaction")`

### `getting_started_saas_doc_contract_test.exs` changes (D-112-02f)

```elixir
# blog_block() — auto-updates when marker interior changes
assert String.contains?(doc, blog_block())

# New negative assertion
refute String.contains?(doc, "Legacy manual recipe")

# Optional positive — helper signature in extracted block
assert String.contains?(blog_block(), "Threadline.Audit.transaction")
```

Router/mount anchors (`router_block()`, `mount_block()`) — **unchanged**.

### `guides/integration-contracts.md` § Audited write path (`:78-112`)

- Currently uses `Repo.insert!` in snippet (`:96`) — CONTEXT D-112-02e prefers rollback-safe `case`/`Repo.rollback` alignment with example marker and §6.
- Phase 112 scope guard lists `getting-started-saas.md` explicitly; integration-contracts alignment is recommended in CONTEXT but optional unless bundled in a plan.

---

## 5. README cross-link targets (ADOPT-HELPER-03, D-112-05)

### Root `README.md`

| Section | Current (`:74-97`) | Target |
|---------|-------------------|--------|
| Quick Start step 4 | Manual `set_config` + `Repo.transaction` + separate `record_action/2` (`:74-97`) | Point to `Threadline.Audit.transaction/3` as first audited write path; link `guides/getting-started-saas.md` §6 |
| "Start here" (`:14-22`) | Lists getting-started guide | Add explicit `Threadline.Audit.transaction/3` mention alongside Plug/record_action |
| Public API blurb (`:10`) | Lists Plug, record_action, timeline, etc. | Include `Threadline.Audit.transaction/3` in API surface list |

**Doc-contract impact:** `readme_doc_contract_test.exs` asserts Plug/record_action literals (`:15-24`, `:150-158`) — extend with helper assertion or replace step-4 manual block carefully so existing contracts stay satisfied or are updated in same plan.

### Example `examples/threadline_phoenix/README.md`

| Section | Lines | Target (D-112-05a) |
|---------|-------|---------------------|
| **Semantics in jobs** | `:319-323` | Replace "runs GUC + post update + `record_action`" with helper-based `touch_post_for_job/2`; cite `Threadline.Audit.transaction/3` + `Threadline.Job` |
| POST /api/posts note | `:332` | Update "sets `audit_transactions.action_id`" prose to "via `Threadline.Audit.transaction/3`" |
| Getting-started pointer | `:14`, `:263` | Already links guide — ensure §6 helper path referenced |

**Existing contracts:** `example_phoenix_readme_contract_test.exs` locks Sigra/router/incident literals — no conflict if Semantics section updated in place. `readme_doc_contract_test.exs:150-158` asserts `Threadline.record_action/2` in example README — keep or supplement with helper mention.

---

## 6. Validation Architecture (Nyquist Dimension 8)

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + PostgreSQL (root `Threadline.Test.Repo`; example `ThreadlinePhoenix.Repo`) |
| **Config** | `test/test_helper.exs`, `examples/threadline_phoenix/config/test.exs` |
| **Prerequisite gate** | `mix test test/threadline/audit_transaction_test.exs` (includes new capture-only meta test) |
| **Example audit/correlation gate** | `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/posts_audit_path_test.exs test/threadline_phoenix_web/posts_correlation_path_test.exs test/threadline_phoenix/help_desk_audit_http_test.exs test/threadline_phoenix/help_desk_audit_test.exs test/threadline_phoenix/workers/post_touch_worker_test.exs` |
| **Doc contract gate** | `mix verify.doc_contract` (includes `getting_started_saas_doc_contract_test.exs`, `example_phoenix_readme_contract_test.exs`, `audit_doc_contract_test.exs`) |
| **Example app gate** | `mix verify.example` (full example suite from repo root) |
| **Full CI** | `mix ci.all` |
| **Estimated quick runtime** | Lib audit tests ~15–30s; example targeted tests ~20–40s; full verify ~2–4 min |

### Per-wave sampling (recommended)

| Wave | Delivers | Automated command | Requirement |
|------|----------|-------------------|-------------|
| 0 / Plan 01 | Lib capture-only meta fix + integration test | `mix test test/threadline/audit_transaction_test.exs` | D-112-01c |
| 1 / Plan 02 | `Blog.create_post/2` + guide §6 + doc contract | `mix test test/threadline/getting_started_saas_doc_contract_test.exs` | ADOPT-HELPER-01, ADOPT-HELPER-03 |
| 2 / Plan 03 | HelpDesk HTTP + capture-only delete | `mix test examples/.../help_desk_audit_test.exs examples/.../help_desk_audit_http_test.exs` (from example dir) | ADOPT-HELPER-01, ADOPT-HELPER-02 |
| 3 / Plan 04 | `touch_post_for_job/2` + worker test + README | `mix test examples/.../post_touch_worker_test.exs` + targeted correlation if added | ADOPT-HELPER-01, ADOPT-HELPER-02 |
| Closeout | Full phase | `mix verify.example && mix verify.doc_contract && mix verify.test` | ADOPT-HELPER-02, ADOPT-HELPER-03 |

**Sampling rule:** Run the wave command after each plan commit; run closeout before `/gsd-verify-work`.

---

## 7. Dependencies, risks, wave grouping

### Dependencies

| Dependency | Status |
|------------|--------|
| Phase 111 complete (`Threadline.Audit.transaction/3` in `lib/threadline/audit.ex`) | ✅ Shipped |
| Phase 111 guides (helper subsection in §6, integration-contracts section) | ✅ Present — Phase 112 **replaces** legacy block, not adds |
| PostgreSQL triggers on `posts`, help-desk tables in example app | ✅ Existing |
| No new migrations expected | ✅ Meta/action_id columns already exist |

### Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Capture-only meta bug blocks `delete_reply/3` | **Blocking** | Plan 01 lib fix before HelpDesk delete migration |
| `blog_block()` doc contract fails if guide §6 not synced with marker | High | Single commit or atomic plan for marker + guide + test |
| Weakening `post_touch_worker_test` by only checking action exists | Medium | Mandatory `at.action_id == action.id` assertion (D-112-01d) |
| README step-4 manual snippet vs ADOPT-HELPER-03 | Medium | Update root README + extend `readme_doc_contract_test` in same plan |
| `touch_post_for_job` return shape change breaks callers | Low | Only `PostTouchWorker` calls it; `{:ok, _}` pattern survives map envelope |
| Dropping `:missing_audit_transaction_for_delete` | Low | No tests grep that atom; unify to `:missing_audit_transaction_for_link` |
| `integration-contracts.md` still shows `insert!` | Low | Optional alignment plan; not in strict scope guard |

### Wave grouping recommendation (3–4 plans)

```
Plan 01 — Lib prerequisite (Wave 0)
  • apply capture-only :transaction_meta in lib/threadline/audit.ex
  • test/threadline/audit_transaction_test.exs new test
  • mix compile --warnings-as-errors

Plan 02 — HTTP blog path + guide truth (Wave 1)
  • Blog.create_post/2 → helper + marker interior
  • guides/getting-started-saas.md §6 replace legacy block
  • getting_started_saas_doc_contract_test.exs updates
  • posts_audit_path_test + posts_correlation_path_test green

Plan 03 — HelpDesk paths (Wave 2)
  • ticket_replied_and_closed/6 → helper
  • delete_reply/3 → capture_only helper + return unwrap
  • help_desk_audit_test.exs meta assertion on delete
  • help_desk_audit_http_test green

Plan 04 — Oban path + README cross-links (Wave 3)
  • touch_post_for_job/2 → helper + envelope
  • post_touch_worker_test.exs action_id linkage assertion
  • examples/threadline_phoenix/README.md Semantics in jobs
  • root README.md ADOPT-HELPER-03 cross-links
  • mix verify.example + mix verify.doc_contract closeout
```

Plans 02–03 can run in parallel **after** Plan 01 if different agents touch disjoint files; guide/marker/test must stay atomic within Plan 02.

---

## RESEARCH COMPLETE
