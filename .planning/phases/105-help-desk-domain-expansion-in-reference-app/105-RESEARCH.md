# Phase 105: Help-Desk Domain Expansion in Reference App — Research

**Researched:** 2026-05-27
**Domain:** `examples/threadline_phoenix/` — Ecto help-desk domain, Threadline capture/semantics, DataCase proof tests
**Confidence:** HIGH — findings from direct reads of example app, Blog pattern, config, and ROADMAP/CONTEXT

---

## Executive Summary

Phase 105 adds a five-table help-desk domain to the canonical Phoenix example app, wires one multi-table semantic action (`:ticket_replied_and_closed`), configures capture-time mask redaction for `internal_note_body`, generates triggers for all audited tables, and proves behavior with **DataCase** tests (not HTTP). `lib/` at repo root stays read-only.

**Critical findings:**

1. **No help-desk code exists yet** — only `posts` + Blog context; all five tables and `lib/threadline_phoenix/help_desk/` are greenfield.
2. **Blog.create_post/2 is the clone target** for GUC → writes → `record_action` → `update_all` on `AuditTransaction` via `txid_current()` + `audit_transaction_meta/1` with `%{"organization_id" => org_id}`.
3. **Example app has no `:trigger_capture` or `:verify_coverage` config today** — both must be added under `examples/threadline_phoenix/config/` before `mix threadline.gen.triggers` and coverage verification.
4. **Posts use integer PKs; help-desk uses `binary_id`** per CONTEXT D-01a/c — schemas need `@primary_key` / `@foreign_key_type :binary_id`.
5. **ROADMAP SC #3 says "ConnCase" but CONTEXT D-05e overrides** — Phase 105 proof is `ThreadlinePhoenix.DataCase`, `async: false`; HTTP waits for Phase 106.
6. **`mix verify.example`** (repo root) runs `cd examples/threadline_phoenix && mix test` — new tests must keep that alias green (21 tests baseline will grow).

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `audit_transactions.meta` = `%{"organization_id" => to_string(organization.id)}` (UUID string); `tickets.number` per-org unique integer; slug/name not in meta.
- **D-02:** Single action `:ticket_replied_and_closed` only; M1 Blog pattern; one `record_action` per transaction.
- **D-03:** `mask` (not `exclude`) for `ticket_replies.internal_note_body`; `store_changed_from: true` on `ticket_replies`.
- **D-04:** Hard `DELETE` on replies; no delete pre-image in capture; defer `:ticket_reply_deleted` to Phase 107.
- **D-05:** DataCase tests, no HTTP; `help_desk_fixtures.ex`; pattern `posts_audit_path_test` capture joins.
- **D-06:** `agents.user_id` required; `ActorRef.new(:user, user_id)` for humans; `assignee_id` → `agents.id`.
- **D-07:** All five tables audited; `mix threadline.gen.triggers` + coverage green; context under `help_desk/`.

### Claude's Discretion

- Exact status enum / changeset fields; `delete_reply/2` in 105 vs test-only helper; ticket `number` allocation (max+1 in tests OK).

### Deferred (OUT OF SCOPE)

- Other action atoms, HTTP audit tests, soft-delete, `lib/` edits, new operator UI routes.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEMO-01 | Schemas + migrations for org, memberships, agents, tickets, replies with associations | Greenfield; use `binary_id`; follow `Post` migration style + Ecto associations |
| DEMO-02 | Context writes with GUC + `record_action` multi-table in one tx | Clone `Blog.create_post/2` lines 32–74; new `HelpDesk.ticket_replied_and_closed/…` |
| DEMO-03 | Triggers for all tables + coverage green + integration test on multi-table write | Add `:verify_coverage` + gen.triggers migration; DataCase test joins `AuditChange` → `AuditTransaction` |
| DEMO-04 | `trigger_capture` masks `internal_note_body` | Add to `config/test.exs` and `config/dev.exs` (gen.triggers reads app config); default `[REDACTED]` |

</phase_requirements>

---

## Codebase State (Verified)

### Existing example-app domain

| Asset | Path | Notes |
|-------|------|-------|
| Post schema | `examples/threadline_phoenix/lib/threadline_phoenix/post.ex` | `posts` table, integer `id`, `title`/`slug` |
| Blog context | `examples/threadline_phoenix/lib/threadline_phoenix/blog.ex` | `create_post/3`, `audit_transaction_meta/1`, `touch_post_for_job/2` |
| Posts migration | `priv/repo/migrations/20260424080611_create_posts.exs` | `create table(:posts)` |
| Posts triggers | `priv/repo/migrations/20260424080642_threadline_triggers_posts.exs` | `threadline_audit_posts` trigger |
| DataCase | `test/support/data_case.ex` | Sandbox owner pattern |
| ConnCase audit test | `test/threadline_phoenix_web/posts_audit_path_test.exs` | HTTP path — **not** template for 105 |
| Worker audit test | `test/threadline_phoenix/workers/post_touch_worker_test.exs` | `Sandbox.unboxed_run` + capture joins — **use for nested tx** |
| Router org scope | `lib/threadline_phoenix_web/router.ex:82-95` | `meta->>'organization_id'` filter |
| PostController org | `post_controller.ex:9,24` | passes `organization_id:` to `create_post` |

### Missing today (must ship in 105)

- `lib/threadline_phoenix/help_desk/` directory and modules
- Help-desk migrations (5 tables)
- `config :threadline, :trigger_capture` in example app
- `config :threadline, :verify_coverage, expected_tables: [...]`
- Trigger migration(s) for help-desk tables
- `test/support/help_desk_fixtures.ex`
- `test/threadline_phoenix/help_desk_audit_test.exs` (name per planner)

### Root `lib/` — read-only

No edits under `/Users/jon/projects/threadline/lib/` per scope guard and Phase 104 v1.23 non-goals.

---

## Implementation Patterns

### M1 — Multi-table action (from Blog)

```elixir
Repo.transaction(fn ->
  Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])
  # ... insert reply, update ticket ...
  {:ok, %AuditAction{id: action_id}} = Threadline.record_action(:ticket_replied_and_closed, action_opts)
  Repo.update_all(
    from(at in AuditTransaction, where: at.txid == fragment("txid_current()")),
    set: [action_id: action_id, meta: %{"organization_id" => to_string(org.id)}]
  )
end)
```

Pass `correlation_id` / `request_id` from `%AuditContext{}` when present (D-02e).

### Trigger generation workflow

From example README (verified):

```bash
cd examples/threadline_phoenix
mix threadline.gen.triggers --tables organizations,org_memberships,agents,tickets,ticket_replies
mix ecto.migrate
```

`mix threadline.gen.triggers` runs `Mix.Task.run("app.config", [])` — config must exist **before** codegen in the same `MIX_ENV`.

### Coverage verification

`mix threadline.verify_coverage` requires:

```elixir
config :threadline, :verify_coverage,
  expected_tables: ["posts", "organizations", "org_memberships", "agents", "tickets", "ticket_replies"]
```

Run from `examples/threadline_phoenix/` with app repo `ThreadlinePhoenix.Repo`. Root `mix verify.threadline` uses **root** repo — phase exit should cite **example-app** command in plans (DEMO-03 intent is example tables).

### Redaction config shape (from root `config/test.exs:32-38`)

```elixir
config :threadline, :trigger_capture,
  tables: %{
    "ticket_replies" => [
      mask: ["internal_note_body"],
      store_changed_from: true
    ]
  }
```

Regenerate triggers after config change so deployed SQL matches config (policy viewer / DEMO-04).

### DataCase test pattern

- `use ThreadlinePhoenix.DataCase, async: false`
- `Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn -> ... end)` when asserting capture inside orchestrated transaction (see `post_touch_worker_test.exs:13`)
- Query: join `AuditChange` → `AuditTransaction`, filter `table_name in ["tickets", "ticket_replies"]`, same `transaction_id`
- Assert `at.meta["organization_id"] == to_string(org.id)`
- Assert linked `AuditAction` name `"ticket_replied_and_closed"` (string form in DB per existing tests)
- Assert `internal_note_body` in `data_after` shows masked placeholder, not plaintext

---

## Suggested Schema Sketch (planner discretion on field names)

| Table | Key columns |
|-------|-------------|
| `organizations` | `id` (binary_id), `slug` (unique), `name` |
| `org_memberships` | `organization_id`, `user_id` (string), `role` (`:agent` \| `:support`) |
| `agents` | `organization_id`, `user_id`, optional `display_name`; unique `[org, user_id]` |
| `tickets` | `organization_id`, `number`, `status`, `assignee_id` → agents, `closed_at` |
| `ticket_replies` | `ticket_id`, public `body`, `internal_note_body` |

Use `mix ecto.gen.migration` from example app directory for timestamped files.

---

## Landmines

1. **Editing root `lib/`** — scope guard forbids; redaction is config-only in example app.
2. **ConnCase for SC #3** — ROADMAP wording is stale vs CONTEXT; use DataCase or phase fails scope creep.
3. **Forgetting `verify_coverage` config** — `mix threadline.verify_coverage` raises without `:expected_tables`.
4. **gen.triggers before config** — mask SQL won't include `internal_note_body` rules if `trigger_capture` missing at codegen time.
5. **Sandbox + capture** — multi-table test may need `unboxed_run` like worker test.
6. **Integer vs binary_id** — do not copy `Post` PK style for help-desk tables.
7. **`mix verify.example`** — run from repo root after phase; must pass with new tests.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via `mix test` in `examples/threadline_phoenix/` |
| Config file | `examples/threadline_phoenix/config/test.exs` |
| Quick run command | `cd examples/threadline_phoenix && mix test test/threadline_phoenix/help_desk_audit_test.exs --max-failures 1` |
| Full suite command | `cd examples/threadline_phoenix && mix test` |
| Repo-root gate | `mix verify.example` (nested example app test + ecto.create) |
| Estimated runtime | ~30–90s full example suite (depends on DB) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command |
|--------|----------|-----------|-------------------|
| DEMO-01 | Tables exist after migrate | integration | `cd examples/threadline_phoenix && mix ecto.migrate --quiet && mix run -e 'IO.inspect(ThreadlinePhoenix.Repo.query!("SELECT tablename FROM pg_tables WHERE tablename IN (''organizations'',''tickets'')"))'` |
| DEMO-02 | Multi-table single transaction + action | unit/DataCase | `mix test test/threadline_phoenix/help_desk_audit_test.exs` (assertion names in plan) |
| DEMO-03 | Triggers installed | mix task | `cd examples/threadline_phoenix && mix threadline.verify_coverage` exits 0 |
| DEMO-04 | Mask on internal_note_body | DataCase + config grep | test asserts `[REDACTED]` or configured placeholder; `grep mask examples/threadline_phoenix/config/test.exs` |
| Regression | Pre-existing example tests | integration | `mix verify.example` from repo root |

### Sampling Rate

- **Per task commit:** Task-level `mix test` path from plan
- **Per wave:** Full `cd examples/threadline_phoenix && mix test`
- **Phase gate:** `mix verify.example` + `mix threadline.verify_coverage` in example app

### Wave 0 Gaps

None — DataCase, Repo, and Threadline install migrations already exist. New: fixtures file + help_desk test module (created in Plan 03, can stub in Plan 01 if TDD desired — planner chose Plan 03 for tests).

---

## RESEARCH COMPLETE
