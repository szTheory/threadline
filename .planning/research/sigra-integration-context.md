# Sigra Integration Context

**Project:** Threadline
**Topic:** Optional integration with [Sigra](https://hex.pm/packages/sigra) auth library
**Captured:** 2026-04-25
**Status:** PRE-SPEC — input for a future spec/discuss/plan phase (see seed `sigra-integration-adapter`)
**Author:** Captured from cross-codebase exploration of `/Users/jon/projects/threadline` and `/Users/jon/projects/sigra`

## Why this note exists

This is research input for a future Sigra integration phase, captured now so the exploration work isn't lost. **No design decisions are committed here.** The future spec phase will pick a tier from the menu below and answer the open questions.

The work was deliberately deferred from v1.12 (As-of / Point-in-Time Reconstruction) because Sigra integration is not blocking, is forward-looking, and needs a spec phase before it's plannable.

## Architectural framing (locked)

These constraints come from the user and from existing project decisions. The spec phase inherits them; it does not relitigate them.

- **Sigra stays unaware of Threadline.** Adapter lives on the Threadline side, not in Sigra.
- **No hard Threadline dependency in Sigra.** Confirmed by Sigra's own decision `001-defer-sigra-lockspire-glue-package.md` — Sigra deliberately does not depend on third-party libraries; it stays focused on host auth.
- **Threadline must remain auth-agnostic.** OSS DNA, `prompts/threadline-elixir-oss-dna.md:49`:
  > "Sigra's auth research… informs **who is the actor**, request-bound context, and multi-tenant boundaries — Threadline semantics layer **should integrate with host auth without becoming an auth library**."
- **Sigra is one possible auth source, not a privileged core dependency.** The integration must coexist with hosts using other auth (Pow, Phoenix's built-in `mix phx.gen.auth`, custom, none).

## Threadline's existing extension surface

Threadline already exposes the right hook. No new core surface is needed for a Tier-1 ship.

| What | Where | Notes |
|---|---|---|
| `:actor_fn` callback | `lib/threadline/plug.ex:16-18, 61, 68` | `(Plug.Conn.t() -> ActorRef.t() \| nil)` — the canonical adapter signature |
| `ActorRef.new(type, id)` | `lib/threadline/semantics/actor_ref.ex:24, 35-91` | 6 closed types: `:user, :admin, :service_account, :job, :system, :anonymous`. JSONB-serializable via `to_map/1` |
| `AuditContext` struct | `lib/threadline/semantics/audit_context.ex` | Carries `actor_ref`, `request_id`, `correlation_id`, `remote_ip`. Not persisted directly — feeds the trigger-side GUC |
| Example wiring | `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex:1-15` | Phase 23 stub returning a static `service_account`. The Sigra example would replace this with a real `current_scope` extraction |
| DB bridge contract | `lib/threadline/plug.ex:28-49` (docstring) | Host calls `SET LOCAL` on `threadline.actor_ref` GUC inside the transaction. Plug deliberately does NOT do this — PgBouncer transaction-mode safe |
| `Threadline.Integrations.*` namespace | (does not exist) | Establishing one is a Tier-2 decision, not a precondition |

## Sigra's public auth surface

What an adapter would read from a Sigra-authenticated `conn`. All paths are within `/Users/jon/projects/sigra`.

### Primary surfaces

- **`conn.assigns.current_scope`** — host-generated struct built by `Sigra.Scope.build/3`. Fields:
  - `:user` — authenticated user struct
  - `:active_organization` — current org (multi-tenant), nil if disabled or unscoped
  - `:membership` — user's role within the active org
  - `:impersonating_from` — when an admin is acting as another user, this holds the real admin user struct
- **`conn.private[:sigra_session]`** — `Sigra.Session` struct with rich session metadata:
  - `:id` (DB PK), `:user_id`, `:type` (`:standard | :remember_me | :mfa_pending`)
  - `:ip`, `:user_agent`, `:parsed_ua`, `:geo_city`, `:geo_country_code`
  - `:active_organization_id`
  - `:impersonator_user_id`, `:impersonator_session_id` — bi-directional audit hook for impersonation
  - `:sudo_at`, `:last_active_at`, `:inserted_at`

### Telemetry / extension hooks

- `[:sigra, :auth, :register, :start | :stop | :exception]` — registration span
- `[:sigra, :audit, :log]` — fires on Sigra's own audit-log commit (transaction-success only)
- Sigra has its own internal audit (`Sigra.Audit`) — separate from Threadline's audit. They can coexist; they audit different concerns (auth events vs row mutations).

### Stable structs an adapter can rely on

- `Sigra.Session` — public, intended for external read
- The host-generated `Scope` struct — accessed by convention (`conn.assigns.current_scope`)
- Sigra v0.2.4 published to Hex as `sigra`

## The three-tier integration menu

The future spec phase will pick one (or stage them). All three are compatible with the locked framing.

### Tier 1 — Docs + example-app update only

**Scope:** README/guide section showing how to write an `actor_fn` from `current_scope`, plus the matching update to `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex`. Copy-pasteable.

**Pros:** Cheapest. No new code surface to maintain. Respects the "Threadline owns the Plug wiring contract, host owns auth" framing exactly. Probably the right Tier-1 ship — most adopters need a recipe, not a library.

**Cons:** Every adopter writes near-identical code. Drift over time as Sigra evolves its `current_scope` shape.

**LOC estimate:** ~50 lines of docs + ~30-line example adapter.

### Tier 2 — In-tree `Threadline.Integrations.Sigra` module

**Scope:** `lib/threadline/integrations/sigra.ex` exposing `actor_ref_from_conn/1` and possibly `audit_context_overrides_from_conn/1`. Loaded only if `Sigra` is available (`Code.ensure_loaded?(Sigra)` guard) — Sigra stays an optional dep, not a hard one.

**Pros:** One canonical mapping, versioned with Threadline. Test coverage in Threadline's suite. Adopters write one line: `plug Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1`.

**Cons:** Establishes a `Threadline.Integrations.*` namespace — implies parity for other auth libraries (Pow, etc.). Couples Threadline's release cadence to Sigra's API stability. Threadline takes on knowledge of Sigra's internals.

**LOC estimate:** ~80-150 lines + tests.

### Tier 3 — Separate `threadline_sigra` Hex package

**Scope:** New repo and Hex package. Depends on both `threadline` and `sigra`. Owns its own README, tests, CI, release notes.

**Pros:** Cleanest separation. Independent release cadence. Doesn't bloat Threadline. Pattern scales — `threadline_pow`, `threadline_phx_gen_auth` could follow the same model. Matches the OSS DNA "borrow checklist" instinct of treating integration adapters as their own published artifacts.

**Cons:** Highest overhead — new repo, separate CI, version-compatibility matrix to maintain. Premature if Tier 1 docs would already serve 95% of adopters.

**LOC estimate:** Whatever Tier 2 would have been + repo scaffolding + matrix tests.

### Likely staging

Tier 1 first (always cheap, always useful). Promote to Tier 2 if multiple adopters appear and Tier 1 docs feel repetitive. Promote to Tier 3 only if the integration grows beyond ~150 LOC, develops its own test surface, or needs a release cadence independent of Threadline.

## Open questions for the spec phase

These are the substantive design questions a future `/gsd-spec-phase sigra-integration-adapter` run must answer. **Do not pre-commit answers here** — capture is enough.

1. **Impersonation representation.** When `scope.impersonating_from` is set (admin acting as user), what is the `ActorRef`?
   - Option A: `ActorRef{type: :admin, id: "<admin_id>"}` and stash impersonation target in `AuditContext` extras.
   - Option B: `ActorRef{type: :user, id: "<impersonated_user_id>"}` with admin in extras.
   - Option C: Encode both in `:id` string (e.g., JSON or `"admin:42:as:user:99"`).
   - Each has audit-trail implications. Pick deliberately.

2. **Organization scope.** `ActorRef` has no first-class slot for `active_organization_id`. Where does it land?
   - Extend `ActorRef` schema (open question — currently closed at 6 types and `:id`).
   - Extend `AuditContext` with an `:org_scope` field.
   - Encode in `:id`.
   - Out of scope — Threadline doesn't promise org-aware audit retrieval today.

3. **Session-ID → correlation_id passthrough.** Sigra's `session.id` is a stable cross-request identifier. Should the adapter populate `audit_context.correlation_id` from it when no `x-correlation-id` header is present?

4. **Telemetry vs Plug-only adapter.** Sigra emits `[:sigra, :audit, :log]`. Should Threadline subscribe (catching auth events that don't go through a Plug, like Oban-job-triggered re-auth), or is Plug-only sufficient for v1?

5. **Service-account / API-token actors.** Sigra has `Sigra.APIToken`. How are token-authenticated requests mapped — `:service_account` with the token's owner ID, or `:user` with the on-behalf-of user? Affects audit semantics.

6. **`:anonymous` fallback policy.** When `current_scope` is nil (unauthenticated request), should the adapter return `nil` (Threadline records no actor) or `ActorRef.new(:anonymous, nil)`? The example app currently returns a static service_account — clearly a stub.

## Decision deferred to

The seed `sigra-integration-adapter` (under `.planning/seeds/`) will surface this note as input when triggered. The trigger conditions and the spec/discuss/plan/execute workflow live there.

## File references for the spec phase

When the future phase runs, it should pull from:

**Threadline:**
- `lib/threadline/plug.ex`
- `lib/threadline/semantics/actor_ref.ex`
- `lib/threadline/semantics/audit_context.ex`
- `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex`
- `prompts/threadline-elixir-oss-dna.md` (sections 4, 7, line 49)

**Sigra (read-only — do not modify):**
- `/Users/jon/projects/sigra/README.md` and `mix.exs`
- `Sigra.Plug.FetchSession`, `Sigra.Scope`, `Sigra.Session`
- `/Users/jon/projects/sigra/.planning/decisions/001-defer-sigra-lockspire-glue-package.md`
