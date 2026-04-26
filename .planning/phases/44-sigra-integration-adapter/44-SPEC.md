# Phase 44: sigra-integration-adapter — Specification

**Created:** 2026-04-26
**Ambiguity score:** 0.13 (gate: ≤ 0.20)
**Requirements:** 9 locked

## Goal

Ship `Threadline.Integrations.Sigra` in-tree so a Phoenix host running [Sigra](https://hex.pm/packages/sigra) wires Threadline once (`plug Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1`) and observes `audit_actions` rows whose `ActorRef` and `correlation_id` correctly distinguish four request shapes — user session, admin impersonating a user, machine-to-machine API token, and unauthenticated — without `:sigra` becoming a Threadline runtime dep.

## Background

Threadline's Plug surface (`lib/threadline/plug.ex:16-18, 61-78`) already accepts an `:actor_fn` callback with signature `(Plug.Conn.t() -> ActorRef.t() | nil)`. `ActorRef` (`lib/threadline/semantics/actor_ref.ex`) is closed at six types — `:user, :admin, :service_account, :job, :system, :anonymous` — with JSONB serialization. `AuditContext` (`lib/threadline/semantics/audit_context.ex`) carries four fields: `actor_ref`, `request_id`, `correlation_id`, `remote_ip` — no extras slot, no extension hooks. The example app's `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex:9-14` returns a static `:service_account` stub from Phase 23, clearly placeholder.

No `Threadline.Integrations.*` namespace exists today. No `guides/integrations/` directory exists. The library `mix.exs` has zero auth dependencies and v1.14 keeps it that way (REQUIREMENTS.md "Out of Scope": no `{:sigra, ...}`, not even `optional: true`).

Sigra v0.2.4 is published to Hex. An adapter reads two surfaces: `conn.assigns.current_scope` (host-built struct with `:user, :active_organization, :membership, :impersonating_from`) and `conn.private[:sigra_session]` (`Sigra.Session` struct with `:id, :user_id, :active_organization_id, :impersonator_user_id, :impersonator_session_id`, plus IP/UA/geo/timestamps). `Sigra.APIToken` is a separate auth path (no `Sigra.Session` attached on token requests).

This phase replaces the Phase 23 stub with a Sigra-aware adapter, ships an integration guide and doc-contract test, and locks the six SEED-001 design questions whose answers determine how each request shape maps to Threadline's locked semantic types.

## Requirements

1. **Adapter module location and surface**: A new `Threadline.Integrations.Sigra` module ships at `lib/threadline/integrations/sigra.ex` with three public functions: `actor_ref_from_conn/1` (returns `ActorRef.t() | nil`), `audit_context_overrides_from_conn/1` (returns `%{optional(:correlation_id) => String.t()}` for `correlation_id` augmentation only — no other fields), and `actor_fn/0` (returns `&actor_ref_from_conn/1` as a captured function reference suitable for `Threadline.Plug` `:actor_fn` option).
   - Current: `Threadline.Integrations.*` namespace does not exist; no Sigra-aware module exists in `lib/`.
   - Target: Module ships with the three public functions plus `@moduledoc` and `@doc` strings linking to `guides/integrations/sigra.md`.
   - Acceptance: `Code.ensure_loaded?(Threadline.Integrations.Sigra) == true`; `function_exported?/3` returns true for `actor_ref_from_conn/1`, `audit_context_overrides_from_conn/1`, `actor_fn/0`; `actor_fn/0` returns a function that, when called with a conn, equals `actor_ref_from_conn/1`'s output for the same conn.

2. **Soft-dep guard (Sigra-absent safety)**: The adapter must not raise, crash, or fail to compile when Sigra is not installed in the host application. The single gate is `Code.ensure_loaded?(Sigra.Session)` — if it returns false, `actor_ref_from_conn/1` returns `nil` and `audit_context_overrides_from_conn/1` returns `%{}`. The library's `mix.exs` does NOT add `:sigra` (not even `optional: true`).
   - Current: Library `mix.exs` has no auth deps; no Sigra-related code exists in `lib/`.
   - Target: Adapter compiles and loads without `:sigra`; the three-conn-shape baseline (no `:current_scope` key, `current_scope: nil`, `current_scope: %{user: nil}`) all return `nil` from `actor_ref_from_conn/1` and `%{}` from `audit_context_overrides_from_conn/1` deterministically without raising.
   - Acceptance: `mix compile --warnings-as-errors` passes against a clean checkout without `:sigra` in deps; `grep -E '\{:sigra' mix.exs` returns no matches; `test/threadline/integrations/sigra_test.exs` runs `mix test` to green with the three-conn-shape baseline using `Sigra`-absent test doubles.

3. **Q1 — Impersonation maps to admin actor with target encoded in correlation_id**: When `scope.impersonating_from` is non-nil (admin acting as a user), `actor_ref_from_conn/1` returns `{type: :admin, id: <real_admin_user_id>}` — i.e. the audit row records who really pressed the button. The impersonated user's id survives at the Threadline layer via `correlation_id` in the format defined in Requirement 7. Threadline's six `ActorRef` types remain closed; no 7th type is added.
   - Current: ActorRef has 6 closed types and no impersonation slot; no impersonation handling exists anywhere.
   - Target: Given `current_scope.impersonating_from = %{id: "<admin_id>"}` and `current_scope.user = %{id: "<imp_user_id>"}`, `actor_ref_from_conn/1` returns `%ActorRef{type: :admin, id: "<admin_id>"}`; `audit_context_overrides_from_conn/1` returns `%{correlation_id: "sigra-imp:<sid>:user:<imp_user_id>"}` (or with `:org:<org_id>` suffix per Requirement 5). Six-type closed enumeration unchanged.
   - Acceptance: Test fixture with both `impersonating_from` and `user` set produces an `:admin` ActorRef with `id == admin_id`; `audit_context_overrides_from_conn/1` returns a correlation_id containing both `sigra-imp:` prefix AND `:user:<imp_user_id>` substring; `ActorRef.@types` (compile-time list) length stays at 6; no `mix.exs` schema migration is added.

4. **Q5 — API-token requests map to `:service_account`**: When the request is authenticated by `Sigra.APIToken` (token in `Authorization: Bearer ...` header, no `Sigra.Session` attached), `actor_ref_from_conn/1` returns `{type: :service_account, id: <token.user_id>}`. This makes machine-to-machine writes visibly distinct from interactive user writes in audit queries.
   - Current: No API-token handling exists; the example app's stub returns a static service_account regardless of auth.
   - Target: Token-shape conn (e.g. `conn.assigns.current_api_token` is a `%Sigra.APIToken{user_id: <id>}`) yields a `:service_account` ActorRef whose `id` equals the token's `user_id`. Session-shape conn continues to yield `:user`/`:admin`.
   - Acceptance: Test fixture with API-token assigns and no `Sigra.Session` produces `%ActorRef{type: :service_account, id: <token.user_id>}`; the same fixture with both an API token AND a session present prefers the session path (session-driven request, token is incidental); a query against the audit table can distinguish the two paths via `WHERE actor_ref->>'type' = 'service_account'`.

5. **Q2 — Organization scope encoded in correlation_id**: The `active_organization_id` from `current_scope.active_organization` (or `Sigra.Session.active_organization_id` when scope-derived org is nil) is appended to `correlation_id` as a `:org:<org_id>` suffix. No new field is added to `AuditContext`. No new type is added to `ActorRef`. v1.14's "no new public capture/semantics surface" rule is preserved.
   - Current: `AuditContext` has 4 fields; no org-aware data path exists; org-aware audit queries require joining the host's own tables.
   - Target: When `active_organization_id` is non-nil, `audit_context_overrides_from_conn/1`'s correlation_id ends with `:org:<org_id>`. When org is nil, no `:org:` suffix is appended. `AuditContext` struct definition is unchanged.
   - Acceptance: Test fixture with `active_organization_id: "99"` produces a correlation_id ending in `:org:99`; fixture with `active_organization_id: nil` produces a correlation_id with no `:org:` substring; `defstruct` of `AuditContext` is byte-identical to pre-phase definition (verified in test).

6. **Q6 — Anonymous requests return `nil`**: When `current_scope` is nil OR `current_scope.user` is nil OR neither `current_scope` nor `Sigra.Session` is present, `actor_ref_from_conn/1` returns `nil` (NOT `ActorRef.new(:anonymous, nil)`). This preserves the distinction between "no actor, by policy" and "actor not yet attached" — Threadline's audit row stays honest about the absence of identity.
   - Current: Example app's stub always returns a synthetic `:service_account`; no anonymous handling exists.
   - Target: Three-conn-shape baseline (no `:current_scope` key, `current_scope: nil`, `current_scope: %{user: nil}`) all return `nil`. `ActorRef.new(:anonymous, nil)` is never constructed by this adapter.
   - Acceptance: Test sweep over the three baseline conns returns `nil` from `actor_ref_from_conn/1`; grep of `lib/threadline/integrations/sigra.ex` for `:anonymous` returns zero matches; doc-contract test asserts the guide explicitly documents `nil` (not `:anonymous`) as the unauthenticated outcome.

7. **Q3 + Q-Token-Corr — correlation_id passthrough hierarchy**: When `x-correlation-id` header is present on the conn, `audit_context_overrides_from_conn/1` returns `%{}` (header wins; adapter never overrides explicit integrator intent). When the header is absent, the adapter constructs `correlation_id` from Sigra state with the following precedence and format:
   - **Impersonation present** (`scope.impersonating_from` non-nil): `"sigra-imp:<session.id>:user:<imp_user_id>"` (+ optional `:org:<org_id>` suffix from Requirement 5)
   - **Plain user session** (`Sigra.Session` present, no impersonation): `"sigra-session:<session.id>"` (+ optional `:org:<org_id>`)
   - **API token** (no `Sigra.Session`, but token authentication detected): `"sigra-token:<token_id>"` (+ optional `:org:<org_id>` if scoped)
   - **Anonymous / Sigra absent**: no `correlation_id` override (`%{}` returned)
   - Current: `Threadline.Plug` extracts correlation_id from `x-correlation-id` header only; nil if absent. No Sigra-derived fallback exists.
   - Target: `Threadline.Plug` continues to read the header first; the adapter's `audit_context_overrides_from_conn/1` is consulted afterward only when the header is absent. The adapter is additive, never overriding.
   - Acceptance: For each of the four shapes (impersonation, session, token, anonymous), the test fixture produces the documented correlation_id literal (or `%{}` for anonymous); fixture with `x-correlation-id: "explicit-cid"` AND a Sigra session produces `correlation_id == "explicit-cid"` (header wins) at the audit-row level; doc-contract test asserts the guide enumerates all four shapes with their literal correlation_id formats.

8. **Example app wired to Sigra (SIGRA-02)**: `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` is replaced with a thin wrapper that delegates to `Threadline.Integrations.Sigra.actor_ref_from_conn/1` (guarded so the example continues to work without Sigra installed). `examples/threadline_phoenix/mix.exs` adds `{:sigra, "~> 0.2", optional: true}` (NOT in the library's `mix.exs`). The example's router/endpoint wires `Threadline.Plug` with `actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1`. Existing example test suite (HTTP audited path, Oban audited path, correlation path, incident JSON path) continues to pass without modification.
   - Current: `audit_actor.ex` returns a hardcoded `:service_account`; `examples/threadline_phoenix/mix.exs` does not list `:sigra`; the example's router does not use `:actor_fn`.
   - Target: `audit_actor.ex` returns `Threadline.Integrations.Sigra.actor_ref_from_conn/1`'s result (or nil if Sigra absent); `examples/threadline_phoenix/mix.exs` lists `{:sigra, "~> 0.2", optional: true}`; example router pipes through `plug Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1`.
   - Acceptance: `cd examples/threadline_phoenix && mix deps.get && mix test` passes; existing tests (HTTP path, Oban worker, correlation path, incident JSON contract) all stay green; grep of library `mix.exs` for `:sigra` still returns zero matches.

9. **Integration guide + doc-contract test (SIGRA-03)**: `guides/integrations/sigra.md` ships as an ExDoc extra documenting: (a) the install snippet (`{:sigra, "~> 0.2", optional: true}` for hosts; never for the library); (b) the Plug callback wire-up line verbatim; (c) the six SPEC-locked behaviors as documented outcomes (impersonation→admin actor + correlation_id encoding, API token→service_account, org→correlation_id suffix, anonymous→nil, header-wins precedence, Plug-only — no telemetry subscription); (d) the four correlation_id literal formats; (e) the `Code.ensure_loaded?(Sigra.Session)` fallback contract. A paired `test/threadline/integrations/sigra_doc_contract_test.exs` locks the install snippet, the Plug-callback line, and the six question outcomes against drift.
   - Current: `guides/integrations/` directory does not exist; no Sigra documentation exists anywhere in the repo.
   - Target: `guides/integrations/sigra.md` exists with all five sections above; `test/threadline/integrations/sigra_doc_contract_test.exs` exists and asserts the locked literals; ExDoc `extras` list (modified in Phase 48) is prepared to include the file.
   - Acceptance: File `guides/integrations/sigra.md` exists; doc-contract test runs to green; deliberately mutating any locked literal (install snippet, Plug-callback line, or one of the six outcome statements) fails the doc-contract test.

## Boundaries

**In scope:**
- New module `lib/threadline/integrations/sigra.ex` exposing `actor_ref_from_conn/1`, `audit_context_overrides_from_conn/1`, `actor_fn/0`.
- Soft-dep guard via `Code.ensure_loaded?(Sigra.Session)` — single source of truth for "Sigra installed?" detection.
- `test/support/sigra_test_doubles.ex` with minimal `Sigra.Session` / `Sigra.Scope` shims used only when real modules are absent in the test environment.
- Mapping rules for four request shapes: user session, admin impersonating a user, API-token, anonymous (covered by Requirements 3–7 above).
- Example app rewiring (`examples/threadline_phoenix/`): replace `audit_actor.ex` stub, add `:sigra` as optional dep in the example's `mix.exs` only, wire `Threadline.Plug` with the new `actor_fn`.
- `guides/integrations/sigra.md` ExDoc extra and paired `sigra_doc_contract_test.exs`.

**Out of scope:**
- **`{:sigra, ...}` in library `mix.exs`** (not even `optional: true`) — Sigra is a host runtime expectation, never a Threadline library dep. Carried forward verbatim from REQUIREMENTS.md / PROJECT.md.
- **Telemetry subscription to `[:sigra, :audit, :log]`** (Q4 — already locked in REQUIREMENTS.md "Out of Scope") — Plug-only adapter for v1; subscription dedup design is not mature enough. Defer until adopter feedback exists.
- **7th `ActorRef` type for impersonation** — impersonation is a relationship between actors, not a new actor kind. Adding a type would force a JSONB migration of `audit_actions`. Carried forward from REQUIREMENTS.md "Out of Scope".
- **New fields on `AuditContext`** (e.g. `:org_scope`, `:impersonation_target`) — v1.14's "no new public capture/semantics surface" rule. Org and impersonation target ride in `correlation_id` instead.
- **Worked impersonation walkthrough end-to-end example** — deferred to v1.15 SIGRA-stretch (REQUIREMENTS.md). The guide documents the encoding; the operator-facing walkthrough waits for adopter feedback.
- **Tier-3 separate `threadline_sigra` Hex package** — Tier 2 (in-tree) is the v1.14 ship per REQUIREMENTS.md. Tier 3 reconsidered in a future milestone if adoption pressure justifies it.
- **Pow / `phx.gen.auth` / other auth-library adapters** — `Threadline.Integrations.*` namespace is established with one entry; other adapters are separate phases driven by their own seeds.
- **Capture / semantics / exploration / retention / export / correlation / time-travel public surface changes** — v1.14 is additive only (REQUIREMENTS.md "Out of Scope" — `:additive only`).
- **Threadline.Plug source modifications** — adapter is consumed via the existing `:actor_fn` callback. No changes to `lib/threadline/plug.ex`.

## Constraints

- **Library `mix.exs`**: zero net new dependencies. The only place `:sigra` may appear is in `examples/threadline_phoenix/mix.exs` as `{:sigra, "~> 0.2", optional: true}`.
- **Sigra-absent safety**: `mix compile --warnings-as-errors` and `mix test` against the library suite must both pass on a clean checkout without `:sigra` installed. Test doubles are loaded only when `Code.ensure_loaded?(Sigra.Session) == false`, with mutual exclusion guarded by an explicit `unless Code.ensure_loaded?(Sigra.Session)` in `test/support/sigra_test_doubles.ex`.
- **JSONB compatibility**: `ActorRef`'s six-type closed list and JSONB serialization (`%{"type" => "...", "id" => "..."}`) remain unchanged. No migration of `audit_actions.actor_ref`.
- **PgBouncer transaction-mode safety**: Adapter touches only conn assigns and `conn.private`; no DB connection state, no `SET LOCAL` calls. Existing `Threadline.Plug` PgBouncer-safety contract (`lib/threadline/plug.ex:28-49`) is preserved.
- **API stability**: Adapter's three public functions become a versioned surface. Their signatures may not change after v0.3.0 ships without a Threadline major-version bump or a 0.3.x deprecation cycle.
- **Header precedence**: When `x-correlation-id` is present, the adapter's `audit_context_overrides_from_conn/1` MUST return `%{}` for the `correlation_id` key — never override explicit integrator intent.
- **Non-modification of Sigra**: Adapter only reads from `conn.assigns.current_scope`, `conn.private[:sigra_session]`, and the `Sigra.APIToken`/`Sigra.Session`/`Sigra.Scope` public surfaces. No PRs to Sigra are required by this phase.

## Acceptance Criteria

- [ ] `Threadline.Integrations.Sigra` module exists at `lib/threadline/integrations/sigra.ex` and exports `actor_ref_from_conn/1`, `audit_context_overrides_from_conn/1`, `actor_fn/0`.
- [ ] `grep -E '\{:sigra' mix.exs` (library, not example) returns zero matches.
- [ ] `mix compile --warnings-as-errors` passes on a clean checkout without `:sigra` installed.
- [ ] Three-conn-shape baseline (no `:current_scope`, `current_scope: nil`, `current_scope: %{user: nil}`) returns `nil` from `actor_ref_from_conn/1` and `%{}` from `audit_context_overrides_from_conn/1` without raising.
- [ ] User-session conn produces `%ActorRef{type: :user, id: <user_id>}`.
- [ ] Impersonation conn (`impersonating_from` non-nil) produces `%ActorRef{type: :admin, id: <real_admin_id>}` AND `audit_context_overrides_from_conn/1` returns `%{correlation_id: "sigra-imp:<sid>:user:<imp_user_id>"}` (with optional `:org:<org_id>` suffix).
- [ ] API-token conn produces `%ActorRef{type: :service_account, id: <token.user_id>}` AND `audit_context_overrides_from_conn/1` returns `%{correlation_id: "sigra-token:<token_id>"}`.
- [ ] Plain user-session conn produces `%{correlation_id: "sigra-session:<session.id>"}`.
- [ ] Conn with `active_organization_id` non-nil yields a correlation_id ending in `:org:<org_id>`; with nil org, no `:org:` suffix appears.
- [ ] Conn with `x-correlation-id: "explicit-cid"` and Sigra session both present yields the audit row's `correlation_id == "explicit-cid"` (header wins).
- [ ] `ActorRef.@types` compile-time list length equals 6 (no 7th type added).
- [ ] `defstruct` of `AuditContext` is byte-identical to the pre-phase definition (no new fields).
- [ ] `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` delegates to `Threadline.Integrations.Sigra.actor_ref_from_conn/1`; `examples/threadline_phoenix/mix.exs` lists `{:sigra, "~> 0.2", optional: true}`.
- [ ] `cd examples/threadline_phoenix && mix deps.get && mix test` passes with all existing tests (HTTP, Oban, correlation, incident JSON) green.
- [ ] `guides/integrations/sigra.md` exists with the five required sections (install, Plug wire-up, six SPEC outcomes, four correlation_id formats, soft-dep contract).
- [ ] `test/threadline/integrations/sigra_doc_contract_test.exs` runs to green; mutating any locked literal in the guide (install snippet, Plug-callback line, or any of the six outcome statements) fails the test.
- [ ] No telemetry handler is attached for `[:sigra, :audit, :log]` by this adapter (grep for `:telemetry.attach` in `lib/threadline/integrations/` returns zero matches).

## Ambiguity Report

| Dimension          | Score | Min  | Status | Notes                                                                                  |
|--------------------|-------|------|--------|----------------------------------------------------------------------------------------|
| Goal Clarity       | 0.92  | 0.75 | ✓      | All six SEED-001 questions locked + two clarifying details (token corr_id, header wins) |
| Boundary Clarity   | 0.85  | 0.70 | ✓      | Out-of-scope list cites REQUIREMENTS.md verbatim; Tier 3 explicitly deferred           |
| Constraint Clarity | 0.85  | 0.65 | ✓      | mix.exs gate, soft-dep contract, JSONB closed-types, PgBouncer safety all named        |
| Acceptance Criteria| 0.85  | 0.70 | ✓      | 17 pass/fail criteria; each requirement has a corresponding falsifiable test           |
| **Ambiguity**      | 0.13  | ≤0.20| ✓      |                                                                                        |

Status: ✓ = met minimum, ⚠ = below minimum (planner treats as assumption)

## Interview Log

| Round | Perspective                  | Question summary                                  | Decision locked                                                                                  |
|-------|------------------------------|---------------------------------------------------|--------------------------------------------------------------------------------------------------|
| 1     | Researcher / Simplifier      | Q6: Anonymous fallback policy                     | Return `nil` (not `ActorRef.new(:anonymous, nil)`) — preserve "no actor recorded" semantics       |
| 1     | Researcher / Simplifier      | Q1: Impersonation representation                  | Admin in `ActorRef`; impersonated user_id in `correlation_id` — keeps 6 types closed              |
| 1     | Researcher / Simplifier      | Q3: Session→correlation_id passthrough            | Yes, prefix as `sigra-session:<id>` when no `x-correlation-id` header                            |
| 2     | Boundary Keeper / Simplifier | Q5: API-token actor mapping                       | `:service_account` with token's `user_id` — distinguish machine from interactive writes          |
| 2     | Boundary Keeper / Simplifier | Q2: Organization scope encoding                   | Append `:org:<org_id>` to correlation_id; no new `AuditContext` field (preserves additive rule)  |
| 2     | Boundary Keeper / Simplifier | Q1-detail: Where does impersonated user_id live?  | Encode in correlation_id: `sigra-imp:<sid>:user:<imp_user_id>` (Threadline-only readable)        |
| 3     | Failure Analyst / Seed Closer| API-token correlation_id when no session present  | `sigra-token:<token_id>` — mirrors session-passthrough pattern                                   |
| 3     | Failure Analyst / Seed Closer| Header-vs-Sigra correlation_id precedence         | `x-correlation-id` header always wins — adapter is additive, never overriding                    |
| —     | Pre-locked in REQUIREMENTS   | Q4: Telemetry vs Plug-only                        | Plug-only for v1; telemetry subscription deferred to v1.15+ (REQUIREMENTS.md "Out of Scope")     |

---

*Phase: 44-sigra-integration-adapter*
*Spec created: 2026-04-26*
*Next step: /gsd-discuss-phase 44 — implementation decisions (test-double scaffolding, conn-shape detection order, doc-contract test structure, etc.)*
