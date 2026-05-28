# Phase 127 Research: Example App `:schemas` Demonstration

**Researched:** 2026-05-28  
**Phase:** 127 — Example App `:schemas` Demonstration  
**Confidence:** HIGH

## RESEARCH COMPLETE

## Summary

Phase 127 closes the sole v1.27 milestone blocker: **DOC-03 is satisfied in guides** but the runnable example app mount omits `:schemas`, so WALKTHROUGH row-history steps hit the documented failure panel instead of reification. Fix is a **focused vertical slice** in `examples/threadline_phoenix` plus doc-snippet parity — no `lib/` changes required unless scope gaps appear during test execution.

**Recommended shape:** Two plans — (1) mount + doc SSOT sync, (2) integration test + phase verification artifact.

## Root Cause (audit-confirmed)

| Surface | Drift | Evidence |
|---------|-------|----------|
| `router.ex` operator mount | No `schemas:` key | L148–155; milestone audit `mix hex.info` corroboration |
| `getting-started-saas.md` §9 | Snippet omits `:schemas` | Contract extracts `operator-surface-mount` from router — must match after fix |
| `examples/threadline_phoenix/README.md` | Mount block omits `:schemas` | `example_phoenix_readme_contract_test.exs` normalizes against router |
| WALKTHROUGH row-history URLs | Use shorthand `/audit/rows/...` | Shipped route is slide-over: `/audit/transactions/:id/history/:table/:record_id` (operator-surface.md D-11) |
| `scope_operator_query/3` | No `:row_history` surface clause | Docs require `%{surface: :row_history}` pairing; catch-all returns unscoped query |

Fresh verification (2026-05-28): `mix verify.doc_contract` — **97 tests, 0 failures**; gap is **runnable** not **documented**.

## Canonical `:schemas` Map (help-desk tables)

Captured table strings from triggers/migrations match Ecto `schema` source names:

| PostgreSQL `table_name` | Ecto module |
|-------------------------|-------------|
| `"tickets"` | `ThreadlinePhoenix.HelpDesk.Ticket` |
| `"ticket_replies"` | `ThreadlinePhoenix.HelpDesk.TicketReply` |

**Exclude `posts`** from the mount map — walkthrough hero scenarios and demo_contract focus on help-desk tables; `operator_surface_test.exs` uses posts for timeline scoping, not row-history reification proof.

**Target mount addition** (inside `# doc: start: operator-surface-mount` block):

```elixir
schemas: %{
  "tickets" => ThreadlinePhoenix.HelpDesk.Ticket,
  "ticket_replies" => ThreadlinePhoenix.HelpDesk.TicketReply
},
```

Place after `scope_query_fn:` and before `repo:` to match operator-surface guide ordering (`schemas:` appears in canonical mount examples).

## Scope Query Fix (`:row_history`)

Extend existing org-scoped clause in `ThreadlinePhoenixWeb.Router.scope_operator_query/3`:

```elixir
when surface in [:timeline, :transaction, :export, :row_history] ...
```

Precedent: `transaction_live_test.exs` scoped history case; operator-surface guide D-11 requires `scope_query_fn` + `:schemas` for support-scoped row history.

## Doc SSOT Chain (must edit together)

1. **`examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`** — authoritative `operator-surface-mount` doc markers
2. **`guides/getting-started-saas.md` §9** — `getting_started_saas_doc_contract_test.exs` asserts `contains_normalized?(doc, mount_block())` where `mount_block()` extracts router markers
3. **`examples/threadline_phoenix/README.md`** — `example_phoenix_readme_contract_test.exs` same extraction pattern

**Do not** duplicate a third divergent mount block — router is SSOT; copy normalized block to §9 and README.

## Route Semantics for Tests

| Doc shorthand | Shipped path | Test target |
|---------------|--------------|-------------|
| `/audit/rows/:table/:pk` | `/audit/transactions/:id/history/:table/:record_id` | Use shipped path in integration test |
| Failure without `:schemas` | Error panel copy from `row_history_component.ex` | Refute after wiring |

Row-history links from transaction drill-down use `patch` to `{base_path}/history/{table}/{pk}` (see `transaction_live.ex` L119).

## Test Strategy

**Primary integration test** (extend `operator_surface_test.exs`):

1. Seed help-desk write via `HelpDesk.ticket_replied_and_closed/6` (pattern from `help_desk_audit_test.exs`)
2. Extract `ticket_replies` change pk from `AuditChange`
3. `login_via_sigra` admin user with org membership
4. `get(conn, "/audit/transactions/#{tx_id}/history/ticket_replies/#{reply_pk}")`
5. Assert `200`, body contains `Row History: ticket_replies /`, refute `not mapped to an Ecto schema`

**Optional contract test** (extend `walkthrough_doc_contract_test.exs` or new file):

- Assert router mount block contains `schemas:` and both help-desk table keys (grep-verifiable D-14 closure)

**Verification bundle:**

```
cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/operator_surface_test.exs
mix verify.doc_contract
```

Session close (plan 02): add `mix test examples/threadline_phoenix/test/...` from repo root or run example app suite if lightweight.

## Precedents

| Phase | Pattern reused |
|-------|----------------|
| 124 D-14 | Deferred example `:schemas`; doc contract in `operator_surface_doc_contract_test.exs` only |
| 124 D-13 | getting-started §9 one sentence + link — full map stays in operator-surface guide |
| 126 | Nyquist VALIDATION.md per phase; honest command reruns |
| `transaction_live_test.exs` | Scoped row history via history sub-route |

## Out of Scope

- Adding `/audit/rows/:table/:pk` as a new LiveView route (docs explicitly describe shorthand vs slide-over)
- `lib/threadline` operator surface changes
- Pow/bearer lane or second reference app
- Nyquist retroactive sign-off for phases 122–126 (done in 126)

## Validation Architecture

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix |
| **Config file** | `mix.exs` (`verify.doc_contract`); example app `mix.exs` |
| **Quick run command** | `cd examples/threadline_phoenix && mix test test/threadline_phoenix_web/operator_surface_test.exs` |
| **Full suite command** | `mix verify.doc_contract` (+ example targeted test) |
| **Estimated runtime** | ~15–45s targeted |

## Confidence Notes

- **HIGH** — audit + file reads confirm exact gap and fix surface
- **HIGH** — doc contract chain is deterministic (extract markers from router)
- **MEDIUM** — support-scoped row-history test may need fixture tuning; admin-path test sufficient for ROADMAP SC #3 minimum
