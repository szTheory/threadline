# Phase 44: sigra-integration-adapter - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-26
**Phase:** 44-sigra-integration-adapter
**Areas discussed:** Test-double scaffolding, Conn-shape primary source, audit_context_overrides_from_conn/1 wiring pattern, Doc-contract test case

---

## Test-Double Scaffolding

Research-backed decision — no AskUserQuestion presented (clear winner).

| Option | Description | Selected |
|--------|-------------|----------|
| `defstruct`-based module shims | Three `defmodule` blocks, each with `defstruct` limited to adapter-read fields; loaded via `elixirc_paths(:test)`; guarded by `unless Code.ensure_loaded?(Sigra.Session)` | ✓ |
| Mox behaviour-based mocks | Enforces function contracts; requires behaviour wrapper module; cannot set up cleanly when dep is absent from `mix.exs` entirely | |
| Plain maps | Zero new files; breaks `%Sigra.Session{}` pattern-match guards in the adapter | |
| `Code.require_file` in test_helper | No `mix.exs` change; breaks Mix incremental compilation graph | |

**Decision:** `defstruct` shims for all three types (`Sigra.Session`, `Sigra.Scope`, `Sigra.APIToken`) via `elixirc_paths(:test)`.
**Notes:** Research via subagent. Elixir Forum and library-guidelines docs confirm this as the idiomatic pattern for optional-dep test doubles. Mox was explicitly ruled out — adapter reads struct fields, never calls Sigra functions.

---

## Conn-Shape Primary Source

Research-backed decision — no AskUserQuestion presented (clear winner from Sigra source analysis).

| Option | Description | Selected |
|--------|-------------|----------|
| Scope-first (`conn.assigns.current_scope` primary) | Mirrors Sigra's own actor-resolution code; `impersonating_from` only available here; works for token auth via `FetchBearer`-populated scope | ✓ |
| Session-first (`conn.private[:sigra_session]` primary) | Sigra-canonical struct; `session.id` explicit; absent on API-token requests — needs assigns fallback anyway | |
| Scope-only (no `conn.private` access) | Simplest adapter; loses session.id for correlation_id construction | |

**Decision:** `current_scope`-first detection; `conn.private[:sigra_session]` supplemental for `session.id` in correlation_id. Detection order: impersonation → plain user → API token → anonymous. `Map.get/3` over dot-access.
**Notes:** Sigra source analysis confirmed scope-first is canonical (`Sigra.Audit.scope_fields/1`, `Sigra.Impersonation.actor_id/1` both read from assigns). `FetchBearer` never sets `conn.private[:sigra_session]` for token requests — session-first would require assigns fallback anyway.

---

## audit_context_overrides_from_conn/1 Wiring Pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Option A: Pre-plug header injection | Thin host plug before `Threadline.Plug`; checks header absence first; sets `x-correlation-id` if empty; matches `Plug.RequestId` idiom | ✓ |
| Option B: Post-plug assigns merge | Thin host plug after `Threadline.Plug`; merges into `conn.assigns.audit_context` when `correlation_id` is nil; cleaner architecture but ordering footgun | |

**User's choice:** Option A — Pre-plug header injection (Recommended)
**Notes:** Research confirmed Option A matches the `Plug.RequestId` "check-before-set" pattern that Phoenix developers immediately recognize. Option B architecturally cleaner but ordering footgun (silent nil correlation_id, no error). Guide will include a forward-pointer note about future `:context_overrides_fn` option on `Threadline.Plug`.

---

## Doc-Contract Test Case

Research-backed decision — no AskUserQuestion presented (existing codebase pattern settled it).

| Option | Description | Selected |
|--------|-------------|----------|
| `use ExUnit.Case, async: true` | No DB; runs in parallel; matches `stg_doc_contract_test.exs` and `audit_indexing_doc_contract_test.exs` | ✓ |
| `use Threadline.DataCase` | Matches `readme_doc_contract_test.exs` surface; but that file uses DataCase because it calls DB fixtures — misleading to copy here | |
| `use ExUnit.Case` (no async) | Simpler than reasoning about async; wastes parallelism for no reason | |

**Decision:** `use ExUnit.Case, async: true`.
**Notes:** Codebase scout found two existing pure-file-read doc-contract tests both using `async: true`. The `readme_doc_contract_test.exs` DataCase usage is load-bearing (DB fixtures) — copying that pattern for a file-read-only test would be misleading.

---

## Claude's Discretion

- Struct field selection for test doubles — SPEC.md Background explicitly lists the fields the adapter reads from each Sigra type, making this deterministic.
- `Map.get/3` vs dot-access — settled by reading Sigra's own source code pattern.
- Pre-plug guard implementation details (the 5-line `SigraContextPlug` body) — left to planner/executor as the implementation is mechanically derived from D-10.

## Deferred Ideas

- Future `Threadline.Plug :context_overrides_fn` option — forward-pointer note in guide only; not a Phase 44 deliverable.
- Worked impersonation walkthrough end-to-end example — v1.15 SIGRA-stretch.
- Tier-3 `threadline_sigra` Hex package — future milestone if adoption pressure warrants.
