# Phase 111: Audited Write-Path Helper — Research

**Researched:** 2026-05-27  
**Phase:** 111 — Audited Write-Path Helper  
**Status:** Complete

## Summary

Phase 111 extracts the repeated Blog/HelpDesk transaction recipe into `Threadline.Audit.transaction/3` in `lib/threadline/`. The golden reference is `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` (`blog-create-post-transaction` marker): encode actor → `Repo.transaction` → `set_config('threadline.actor_ref', …, true)` → domain writes → optional `Threadline.record_action/2` → `update_all` on `audit_transactions` by `txid_current()` → fetch `audit_transaction_id`.

Existing test infrastructure (`Threadline.DataCase`, trigger table pattern in `test/threadline/capture/trigger_context_test.exs`, `Threadline.Query` LOOP-01 correlation tests) supports PostgreSQL integration tests without touching the example app. Doc contracts use `Threadline.GettingStartedFixtures.extract!/2` with `# doc: start/end:` anchors — new anchor `audit-transaction-helper` in `lib/threadline/audit.ex`, separate from Phase 112's blog marker migration.

## Technical Findings

### Manual recipe (current state)

| Step | Location | Detail |
|------|----------|--------|
| Actor guard | `Blog.create_post/2:22-24` | `nil` actor → `{:error, :missing_actor}` before txn |
| GUC encode | `Blog.create_post/2:27-34` | `ActorRef.to_map/1` → `Jason.encode!/1` → `set_config(..., true)` |
| Domain writes | callback | `Repo.insert/update/delete` only |
| Action + link | `Blog.create_post/2:48-63` | `record_action/2` → `update_all` where `txid == txid_current()` → rollback `:missing_audit_transaction_for_link` if count != 1 |
| Return | `Blog.create_post/2:73` | `%{post: post, audit_transaction_id: uuid}` inside txn → `Repo.transaction` unwraps to `{:ok, map}` |

**Known gap:** `Blog.touch_post_for_job/2` records action but does not link `action_id` — Phase 112 fixes via helper adoption; Phase 111 must implement linkage when `:action` is present.

### Public API decisions (locked in CONTEXT)

| Decision | Implementation note |
|----------|---------------------|
| `Threadline.Audit.transaction(repo, opts, fun)` | Third arg zero-arity callback; repo first matches Ecto mental model |
| Return merge | Map callback result → merge `:audit_transaction_id`; non-map → `%{result: value, audit_transaction_id: uuid}` |
| `:action` absent | Capture-only: GUC + callback only; no `record_action`, no linkage |
| `:action` present | Must link; `allow_missing_actor` ignored |
| `audit_context:` sugar | Extract `actor_ref`, `correlation_id`, `request_id` from `%AuditContext{}` |
| Top-level correlation opts | Forward to `record_action/2` when `:action` is atom |
| `:transaction_meta` | Merged into `audit_transactions.meta` on linkage update |

### `Threadline.record_action/2` contract

- Requires `:repo` and `:actor` / `:actor_ref`
- Returns `{:ok, %AuditAction{}}` | `{:error, changeset}` | `{:error, :missing_actor}` | etc.
- Helper must call **inside** the open transaction with `repo: repo` (same repo module passed to `transaction/3`)

### Strict `:correlation_id` semantics

`Threadline.Query.timeline/2` with `:correlation_id` JOINs `audit_transactions.action_id` → `audit_actions.correlation_id`. Capture-only writes (no linkage) **will not appear** in correlation-filtered timelines — document prominently.

### Test strategy

| Test | Pattern source | Proves |
|------|----------------|--------|
| Row capture under helper | `TriggerContextTest` setup (temp table + trigger) | AUDIT-TXN-03a |
| Correlation timeline match | Insert via helper with `:action` + `correlation_id` → `Threadline.timeline/2` | AUDIT-TXN-03b |
| Missing actor | Call without `actor_ref` → `{:error, :missing_actor}` | AUDIT-TXN-03c |
| Capture-only path | No `:action` → capture works, timeline correlation empty | D-111-03b |
| `allow_missing_actor: true` | NULL actor on txn when no `:action` | D-111-04c |

Use `Threadline.DataCase` and a dedicated test table (same pattern as `test_audit_target_ctx` in trigger tests).

### Documentation surfaces

| File | Change |
|------|--------|
| `guides/getting-started-saas.md` §6 | Add "recommended path" subsection pointing to `Threadline.Audit.transaction/3`; keep existing manual snippet until Phase 112 |
| `guides/integration-contracts.md` | New `## Audited write path via Threadline.Audit` section |
| `lib/threadline/audit.ex` | Moduledoc + `# doc: start/end: audit-transaction-helper` fenced canonical snippet |
| `test/threadline/audit_doc_contract_test.exs` | New — extract marker, assert signature literals |
| `test/threadline/integration_contracts_doc_contract_test.exs` | Extend with audited-write-path section assertions |

### Module placement

Single module `lib/threadline/audit.ex` (`Threadline.Audit`) — no subdirectory split unless file exceeds ~200 lines. Private helpers: `encode_actor_guc/1`, `link_action/4`, `fetch_audit_transaction_id/1`, `build_action_opts/2`, `resolve_opts/1`.

### Scope guard (ROADMAP)

**In scope:** `lib/threadline/`, `test/threadline/`, `guides/`  
**Out of scope:** `examples/threadline_phoenix/` (Phase 112), replacing `blog-create-post-transaction` marker (Phase 112)

## Validation Architecture

Nyquist Dimension 8 — per-task verification map in `111-VALIDATION.md`.

| Property | Value |
|----------|-------|
| Framework | ExUnit + PostgreSQL (Threadline.Test.Repo) |
| Config | `test/test_helper.exs`, `test/support/data_case.ex` |
| Quick run | `mix test test/threadline/audit_transaction_test.exs test/threadline/audit_doc_contract_test.exs` |
| Full suite | `mix verify.test` or `mix ci.all` |
| Estimated quick runtime | ~15–45s |

**Sampling:** Run audit tests after Plan 02; doc contract tests after Plan 03; `mix verify.test` before phase complete.

## Dependencies

- v1.23 complete (Phase 110) — no blocking dependency
- Existing capture triggers + semantics schema migrations already in test DB
- No new migrations expected — **no blocking schema push**

## Risks

| Risk | Mitigation |
|------|------------|
| Nested `Repo.transaction/1` inside callback breaks linkage | Moduledoc + integration test asserting forbidden pattern documented |
| REQUIREMENTS say `transaction/2` but CONTEXT locks `transaction/3` | Public API is `transaction(repo, opts, fun)` — update doc-contract literals to `/3`; requirements intent is "repo-scoped helper" |
| Guide §6 duplication (manual + helper) | Phase 111 adds helper as recommended; Phase 112 replaces manual block |

## RESEARCH COMPLETE
