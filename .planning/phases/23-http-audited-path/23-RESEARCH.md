# Phase 23 — HTTP audited path — Research

**Date:** 2026-04-24  
**Question:** What do we need to know to plan REF-03 (HTTP + `Threadline.Plug` + audited write + proof) well?

---

## 1. Requirement restatement (REF-03)

From `.planning/REQUIREMENTS.md`: the example **HTTP stack** includes **`Threadline.Plug`** in the pipeline used for audited writes; a **controller or context** performs at least one **audited insert or update**; an **automated test** or **documented curl/httpie** proves **`audit_changes`** and **transaction linkage**.

**Locked in 23-CONTEXT:** Canonical proof = **ConnCase integration test** through **Endpoint → Router → plugs → handler**; **synthetic `ActorRef`** via `actor_fn`; **`POST /api/posts`** only; **context-owned** `Repo.transaction` + `set_config('threadline.actor_ref', …, true)` before audited `Repo.insert`; skinny controller passes **`conn.assigns[:audit_context]`** into the context.

---

## 2. Library contracts (implementation truth)

### `Threadline.Plug` (PgBouncer-safe)

`lib/threadline/plug.ex` assigns **`conn.assigns[:audit_context]`** with `actor_ref`, `request_id` (header or `conn.assigns[:request_id]` from `Plug.RequestId`), `correlation_id`, `remote_ip`. It **never** calls `SET` on the DB — GUC belongs in the transaction around writes (CTX-03 in moduledoc).

### CTX-03 bridge

`test/threadline/capture/trigger_context_test.exs` is the executable contract: inside `Repo.transaction/1`, run `Repo.query!("SELECT set_config('threadline.actor_ref', $1::text, true)", [json])` **before** the first audited statement; `AuditTransaction.actor_ref` matches the JSON.

### Example app baseline (Phase 22)

- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — today only `pipeline :api` with `plug :accepts, ["json"]` and empty `/api` scope — **Phase 23 adds** `Threadline.Plug` and routes.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/endpoint.ex` — already has **`Plug.RequestId`** before Router — aligns with D-11 “order plugs like prod.”
- `examples/threadline_phoenix/test/support/conn_case.ex` — `@endpoint ThreadlinePhoenixWeb.Endpoint`, sandbox via `DataCase.setup_sandbox` — correct base for **`post(conn, …)`** integration tests.
- `ThreadlinePhoenix.Post` + `posts` triggers already exist — reuse for audited insert.

---

## 3. Proof and verification commands

| Intent | Command |
|--------|---------|
| Example app only | From repo root: `mix verify.example` (nested `cd examples/threadline_phoenix && …`) |
| Targeted during dev | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/path_test.exs` |
| Full gate | `MIX_ENV=test mix ci.all` (includes `verify.example`) |

Assertions should use **`Threadline.Capture.AuditChange`** and **`Threadline.Capture.AuditTransaction`** (or raw SQL) against **`ThreadlinePhoenix.Repo`** — same database as `posts` and Threadline install migrations.

---

## 4. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Proof uses `DataCase` + `Repo.insert` only | **Reject** — REF-03 and D-01 require HTTP through Endpoint stack. |
| `actor_fn` omitted | `audit_context.actor_ref` nil; GUC may still be set from context using a default — prefer explicit **`actor_fn`** returning `{:ok, ref} = ActorRef.new(:service_account, "threadline-phoenix-example")` (or `:system`) per D-04. |
| GUC set outside transaction or after insert | Follow `trigger_context_test.exs` order exactly inside **one** `Repo.transaction`. |

---

## Validation Architecture

### Test stack (ExUnit / Mix)

- **Example:** ConnCase tests under **`examples/threadline_phoenix/test/`** hitting **`ThreadlinePhoenixWeb.Endpoint`** with **`post/3`** (or `put_req_header` + `post`) so **`Threadline.Plug`** runs on the `:api` pipeline.
- **Assertions:** Query **`audit_changes`** joined to **`audit_transactions`** (Ecto schemas **`Threadline.Capture.AuditChange`**, **`Threadline.Capture.AuditTransaction`**) and assert **≥1** change row for **`table_name`** matching **`posts`**, **`transaction_id`** non-nil FK to the transaction row created in the same HTTP-handled transaction.

### Commands: quick vs full

| Intent | Command |
|--------|---------|
| After HTTP-path code changes | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/…` (module path TBD by executor) |
| CI parity | `MIX_ENV=test mix verify.example` from repo root |

### Sampling strategy

- After router/context/controller/test edits: run **`mix verify.example`** (or scoped **`mix test`** then full verify before PR).
- If root **`mix.exs`** / **`.github/workflows/ci.yml`** change: run **`mix test test/threadline/phase06_nyquist_ci_contract_test.exs`**.

### Mapping verification to **REF-03**

| Requirement | What “done” looks like |
|-------------|-------------------------|
| **REF-03** | `Threadline.Plug` in **`:api`** pipeline for the route serving **`POST /api/posts`**; audited insert via context inside transaction + GUC; **automated test** proves **`audit_changes`** row(s) and **linkage** to **`audit_transactions`**. |

---

## RESEARCH COMPLETE
