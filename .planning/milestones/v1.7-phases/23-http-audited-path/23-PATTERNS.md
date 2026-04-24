# Phase 23 — Pattern map

Analogs in-repo for files Phase 23 will create or extend.

---

## Router + Plug

| New / changed | Role | Analog | Notes |
|---------------|------|--------|-------|
| `router.ex` — `:api` pipeline | Mount `Threadline.Plug` + routes | `lib/threadline/plug.ex` @moduledoc lines 8–12 | `plug Threadline.Plug, actor_fn: &Mod.fun/1` |
| `endpoint.ex` | RequestId before Router | Current file lines 38–50 | Preserve order per D-11 |

---

## Transaction + GUC + audited write

| New / changed | Role | Analog |
|---------------|------|--------|
| Context module (e.g. `Blog` / `Posts`) | `Repo.transaction` + `set_config` + `Repo.insert` | `test/threadline/capture/trigger_context_test.exs` lines 33–36 |
| — | `ActorRef.to_map/1` + `Jason.encode!` | `trigger_context_test.exs` line 31 |

---

## HTTP integration test

| New / changed | Role | Analog |
|---------------|------|--------|
| `test/.../…_test.exs` ConnCase | `post(conn, path, body)` through Endpoint | `examples/threadline_phoenix/test/support/conn_case.ex` `using` block |
| Assertions on capture | Ecto query audit tables | `trigger_context_test.exs` uses `Repo.all(AuditTransaction)` — same idea for `AuditChange` + join |

---

## Skinny controller

| New / changed | Role | Analog |
|---------------|------|--------|
| `*_controller.ex` | Parse params, call context with `conn.assigns.audit_context` | Phoenix 1.7 JSON controller conventions (no in-repo file — follow generated `scope "/api", …` patterns) |

---

## PATTERN MAPPING COMPLETE
