# Phase 44: sigra-integration-adapter - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship `Threadline.Integrations.Sigra` in-tree: adapter module with three public functions, example app rewiring away from the Phase 23 stub, integration guide (`guides/integrations/sigra.md`), and a doc-contract test locking the guide's literals. The six SEED-001 semantic decisions (Q1–Q6) are locked in SPEC.md; this context captures implementation-level decisions about test infrastructure, detection order, wiring pattern, and test module structure.

</domain>

<spec_lock>
## Requirements (locked via SPEC.md)

**9 requirements are locked.** See `44-SPEC.md` for full requirements, boundaries, and acceptance criteria.

Downstream agents MUST read `44-SPEC.md` before planning or implementing. Requirements are not duplicated here.

**In scope (from SPEC.md):**
- New module `lib/threadline/integrations/sigra.ex` with `actor_ref_from_conn/1`, `audit_context_overrides_from_conn/1`, `actor_fn/0`
- Soft-dep guard via `Code.ensure_loaded?(Sigra.Session)` — single gate
- `test/support/sigra_test_doubles.ex` with minimal `Sigra.Session` / `Sigra.Scope` / `Sigra.APIToken` shims
- Mapping rules for four request shapes: user session, admin impersonating, API-token, anonymous
- Example app rewiring (`examples/threadline_phoenix/`): replace `audit_actor.ex` stub, add `:sigra` as optional dep in example `mix.exs` only, wire `Threadline.Plug` with new `actor_fn`
- `guides/integrations/sigra.md` ExDoc extra and paired `sigra_doc_contract_test.exs`

**Out of scope (from SPEC.md):**
- `{:sigra, ...}` in library `mix.exs` (not even `optional: true`)
- Telemetry subscription to `[:sigra, :audit, :log]` (Q4 — deferred to v1.15+)
- 7th `ActorRef` type for impersonation
- New fields on `AuditContext`
- Worked impersonation walkthrough end-to-end example
- Tier-3 separate `threadline_sigra` Hex package
- Pow / `phx.gen.auth` / other auth-library adapters
- Any capture / semantics / exploration public surface changes
- `Threadline.Plug` source modifications

</spec_lock>

<decisions>
## Implementation Decisions

### Test-Double Scaffolding
- **D-01:** Use `defstruct`-based module shims — one `defmodule` per Sigra type — not Mox and not plain maps. Mox is for function contract mocking; the adapter only reads struct fields. Plain maps break `%Sigra.Session{}` pattern-match guards in the adapter code.
- **D-02:** Shim all three types: `Sigra.Session`, `Sigra.Scope`, and `Sigra.APIToken`. All three are exercised in the four-request-shape test matrix; shimming only `Sigra.Session` would require mixed plain-map fallbacks for the other two.
- **D-03:** Load via `elixirc_paths(:test)` in `mix.exs` (same mechanism as `data_case.ex` and `repo.ex`). Do NOT use `Code.require_file` in `test_helper.exs` — that pattern breaks Mix's incremental compilation graph.
- **D-04:** Place the `unless Code.ensure_loaded?(Sigra.Session)` mutual exclusion guard at the top of `test/support/sigra_test_doubles.ex`. The shim file evaporates when Sigra is actually installed (e.g., in the example app's own test suite).
- **D-05:** Each shim struct should define only the fields the adapter reads (per SPEC.md Background): `Sigra.Session` — `:id, :user_id, :active_organization_id, :impersonator_user_id, :impersonator_session_id`; `Sigra.Scope` — `:user, :active_organization, :membership, :impersonating_from`; `Sigra.APIToken` — `:user_id, :id`.

### Conn-Shape Detection Order
- **D-06:** Primary source for actor resolution: `conn.assigns.current_scope`. This mirrors Sigra's own internal actor-resolution pattern (`Sigra.Audit.scope_fields/1`, `Sigra.Impersonation.actor_id/1`, `Sigra.Plug.ForbidDuringImpersonation` all read exclusively from assigns). Do NOT use `conn.private[:sigra_session]` as the primary source for ActorRef.
- **D-07:** `conn.private[:sigra_session]` is supplemental only — used to extract `session.id` for `correlation_id` construction in `audit_context_overrides_from_conn/1`. It is absent on API-token requests (`Sigra.Plug.FetchBearer` never sets it), so it cannot be the primary source.
- **D-08:** Detection order inside `actor_ref_from_conn/1` — check in this order:
  1. `current_scope.impersonating_from` non-nil → `:admin` (real admin id) — impersonation takes precedence
  2. `current_scope.user` non-nil → `:user`
  3. `current_api_token` non-nil (no session) → `:service_account` (token's `user_id`)
  4. Otherwise → `nil` (anonymous / missing scope)
  When both API token AND session are present, session wins — `FetchBearer` skips scope assignment if scope is already set, so the scope already reflects the session actor; no explicit arbitration required.
- **D-09:** Use `Map.get/3` (not dot-access) for all `current_scope` field reads. Sigra's own audit code uses `Map.get(scope, :impersonating_from)` rather than `scope.impersonating_from`. Hosts may define scope structs that omit optional fields; dot-access would raise `KeyError` on those.

### audit_context_overrides_from_conn/1 Wiring Pattern
- **D-10:** Guide documents **Option A: pre-plug header injection**. A thin host-app custom plug (`MyApp.SigraContextPlug` or similar) runs BEFORE `Threadline.Plug` in the pipeline. It checks `get_req_header(conn, "x-correlation-id")` first; if the list is non-empty (header present), it returns `conn` untouched — header wins. If the list is empty, it calls `audit_context_overrides_from_conn/1`, extracts any `correlation_id`, and sets it via `put_req_header/3`. `Threadline.Plug` then reads the (now-populated) header normally. This matches the `Plug.RequestId` pattern — Phoenix developers immediately recognize it.
- **D-11:** The guide should include a one-paragraph forward-pointer note that a future `Threadline.Plug` `:context_overrides_fn` option will replace the two-plug pattern for hosts who want native wiring without a custom plug. This sets adopter expectations without committing to a timeline.
- **D-12:** The example app (`examples/threadline_phoenix/`) should demonstrate the two-plug pipeline pattern with a concrete `SigraContextPlug` implementation inline (or as a minimal module in the example). The example proves the pattern works end-to-end.

### Doc-Contract Test Module
- **D-13:** `test/threadline/integrations/sigra_doc_contract_test.exs` should use `use ExUnit.Case, async: true` — NOT `use Threadline.DataCase`. The `readme_doc_contract_test.exs` uses `DataCase` specifically because it calls live DB fixtures; this test has no DB access whatsoever. The existing `stg_doc_contract_test.exs` and `audit_indexing_doc_contract_test.exs` confirm the correct codebase pattern for pure file-read doc-contract tests: `use ExUnit.Case, async: true`.
- **D-14:** The test's assertions should lock the following literals (per SPEC.md Requirement 9): (a) install snippet `{:sigra, "~> 0.2", optional: true}`, (b) the Plug-callback wire-up line verbatim, (c) each of the six SPEC-answered outcome statements, (d) the four `correlation_id` format strings (`sigra-imp:`, `sigra-session:`, `sigra-token:`, the `nil`/anonymous case), (e) the `Code.ensure_loaded?(Sigra.Session)` fallback contract mention.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Locked Requirements
- `.planning/phases/44-sigra-integration-adapter/44-SPEC.md` — 9 locked requirements, boundaries, acceptance criteria, interview log. Mandatory first read.

### Core Library Files (do not modify)
- `lib/threadline/plug.ex` (lines 16–18, 61–78) — `:actor_fn` callback wiring; `correlation_id` reads from `x-correlation-id` header only. No changes permitted this phase.
- `lib/threadline/semantics/actor_ref.ex` — `@types ~w(user admin service_account job system anonymous)a` (6 closed types); JSONB serialization contract. Must stay byte-identical.
- `lib/threadline/semantics/audit_context.ex` — `defstruct [:actor_ref, :request_id, :correlation_id, :remote_ip]` (4 fields). Must stay byte-identical — no new fields.

### Example App (to be modified)
- `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` — Phase 23 stub returning hardcoded `:service_account`; to be replaced with Sigra delegation.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — Pipeline wiring point (line 7); to be updated with two-plug pattern.
- `examples/threadline_phoenix/mix.exs` — Example deps; add `{:sigra, "~> 0.2", optional: true}` here only (NOT in library `mix.exs`).

### Test Infrastructure
- `test/support/data_case.ex` — Pattern for `elixirc_paths(:test)` loaded support modules.
- `test/support/repo.ex` — Same pattern.
- `test/test_helper.exs` — Existing ExUnit configuration; check for `elixirc_paths` in `mix.exs`.
- `test/threadline/readme_doc_contract_test.exs` — Doc-contract test pattern (`File.read!` + `String.contains?`). Note: uses DataCase because it calls DB fixtures — `sigra_doc_contract_test.exs` should NOT follow this case choice; use `ExUnit.Case, async: true` instead.

### Project Context
- `.planning/REQUIREMENTS.md` — v1.14 milestone requirements; "Out of Scope" list confirms zero new library deps, no 7th ActorRef type, telemetry deferred.
- `.planning/ROADMAP.md` — Phase 44 success criteria and downstream phase dependencies (44→45→...→48).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Semantics.ActorRef.new/2` — constructor with validation; returns `{:ok, ref}` or `{:error, reason}`. The adapter should use this (not direct struct construction) so validation is consistent.
- `test/support/data_case.ex` + `test/support/repo.ex` — template for `elixirc_paths(:test)` support modules; copy the loading mechanism for `sigra_test_doubles.ex`.

### Established Patterns
- `Threadline.Plug` `:actor_fn` option — already accepts `(Plug.Conn.t() -> ActorRef.t() | nil)`. The adapter's `actor_fn/0` captures `actor_ref_from_conn/1` for this interface. No new Plug options needed.
- `Plug.RequestId` "check-before-set" pattern — the guide's `SigraContextPlug` should mirror this: `get_req_header` first, set only if empty. This is the established Phoenix convention for request-header enrichment plugs.
- `unless Code.ensure_loaded?` guard — already conceptually in play for this project (see SPEC.md soft-dep contract). The doubles file uses this guard to evaporate when Sigra is installed.
- `@moduledoc` + `@doc` linking to the guide (`guides/integrations/sigra.md`) — established convention for integration modules to link their guide.

### Integration Points
- `lib/threadline/integrations/sigra.ex` (new) — adapts `conn.assigns.current_scope` + `conn.private[:sigra_session]` + `conn.assigns.current_api_token` → `ActorRef.t() | nil` and `%{optional(:correlation_id) => String.t()}`.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` pipeline — two-plug insertion point: `SigraContextPlug` before `Threadline.Plug`.
- `test/threadline/integrations/` (new directory) — home for `sigra_test.exs` and `sigra_doc_contract_test.exs`.

</code_context>

<specifics>
## Specific Ideas

- The guide's two-plug pipeline snippet (from D-10) should be complete and copy-pasteable: `plug MyApp.SigraContextPlug` followed by `plug Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1`. The `SigraContextPlug` implementation (~5 lines using `get_req_header`/`put_req_header` guard) should appear inline in the guide.
- The forward pointer note (D-11) for future `:context_overrides_fn` should be brief — one sentence or a callout box — not a full section.
- Conn-shape detection should prefer a `case conn.assigns[:current_scope]` pattern with guard clauses (not a long `if/else` chain) to keep it readable and pattern-matchable.

</specifics>

<deferred>
## Deferred Ideas

- Future `Threadline.Plug :context_overrides_fn` option — cleaner native wiring than the two-plug pattern; deferred until adopter feedback justifies the API surface. Forward-pointed in guide per D-11.
- Worked impersonation walkthrough end-to-end example — deferred to v1.15 SIGRA-stretch per REQUIREMENTS.md.
- Tier-3 separate `threadline_sigra` Hex package — reconsidered in a future milestone if adoption pressure justifies it.

</deferred>

---

*Phase: 44-sigra-integration-adapter*
*Context gathered: 2026-04-26*
