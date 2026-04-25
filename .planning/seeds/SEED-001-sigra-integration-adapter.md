---
id: SEED-001
status: dormant
planted: 2026-04-25
planted_during: v1.12 — Temporal Truth & Safety (As-of Reconstruction), pre-Phase-38
trigger_when: v1.12 ships OR first external adopter requests Sigra+Threadline guidance OR Threadline picks up its first Sigra-using pilot host
scope: Medium
---

# SEED-001: Optional Threadline ↔ Sigra integration adapter

Map Sigra-authenticated request state into `Threadline.Semantics.ActorRef` and
`AuditContext` without making Threadline auth-aware or making Sigra
Threadline-aware. Tier and exact mapping decisions are deferred to a future
spec phase.

## Why This Matters

**Distribution multiplier.** Sigra is the user's own auth library on Hex. Every
host that adopts Sigra is a likely candidate to also adopt Threadline; a clean,
documented integration path turns the existing Sigra installed-base into a
warm Threadline funnel. Without it, every Sigra-using adopter has to derive the
mapping themselves, get impersonation/org-scope semantics wrong, and write
near-identical glue code.

**Architectural integrity.** Doing the mapping right (Sigra-unaware-of-Threadline,
Threadline-auth-agnostic) is a chance to validate Threadline's "host owns auth,
Threadline owns the wiring contract" stance against a real, non-trivial auth
surface. If `:actor_fn` and `ActorRef` can't cleanly absorb Sigra's
impersonation + org scope + session metadata, that's a signal the core surface
needs adjustment — better to discover that against Sigra (well-known, controlled
by user) than against an external adopter's bespoke auth.

**Zero-disruption capture.** The exploration work and architectural framing are
already done (see breadcrumbs below). Without this seed, that context decays;
re-doing it later costs another full session of cross-codebase exploration.

## When to Surface

**Trigger:** Any of —

- v1.12 milestone (Phases 38–40, As-of / Point-in-Time Reconstruction) ships
- First external adopter requests Sigra+Threadline integration guidance
- Threadline picks up its first Sigra-using pilot host

This seed should be presented during `/gsd-new-milestone` when the next
milestone scope matches any of these conditions, OR when /gsd-progress notes
that v1.12 is wrapping.

**Suggested workflow when surfaced:**
`/gsd-spec-phase sigra-integration-adapter` →
`/gsd-discuss-phase` →
`/gsd-plan-phase` →
execute.

The spec phase's primary input is `.planning/research/sigra-integration-context.md`
— it contains the full exploration findings, the locked architectural framing,
the three-tier menu, and the six open design questions.

## Scope Estimate

**Medium** — most likely a single phase landing Tier 1 (docs + example-app
update), with the option to grow into Tier 2 (in-tree
`Threadline.Integrations.Sigra` module) or Tier 3 (separate `threadline_sigra`
Hex package) in a follow-up milestone if adoption signals warrant it.

Rough sizing per tier (full detail in research note):
- **Tier 1 — Docs + example only:** ~80 LOC. One phase.
- **Tier 2 — In-tree integration module:** ~80–150 LOC + tests. One phase.
- **Tier 3 — Separate Hex package:** Tier 2 surface + new repo, CI, version-compat matrix. Could span two phases or its own mini-milestone.

The spec phase decides which tier to ship first. Tier 1 is the likely answer
unless adoption pressure has built up by trigger time.

## Breadcrumbs

**Primary research artifact (required reading for the spec phase):**
- `.planning/research/sigra-integration-context.md` — full exploration findings, three-tier menu, six open questions

**Threadline integration surface (already exists, no new core needed for Tier 1):**
- `lib/threadline/plug.ex:16-18, 61, 68` — `:actor_fn` callback, signature `(Plug.Conn.t() -> ActorRef.t() | nil)`
- `lib/threadline/semantics/actor_ref.ex:24, 35-91` — 6 closed types, JSONB serialization
- `lib/threadline/semantics/audit_context.ex` — `actor_ref`, `request_id`, `correlation_id`, `remote_ip`
- `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex:1-15` — Phase 23 stub the Sigra example would replace

**Architectural constraints (locked, do not relitigate):**
- `prompts/threadline-elixir-oss-dna.md:49` — "semantics layer should integrate with host auth without becoming an auth library"
- `/Users/jon/projects/sigra/.planning/decisions/001-defer-sigra-lockspire-glue-package.md` — Sigra's own decision to not depend on third-party libraries

**Sigra public auth surface (read-only — adapter consumes):**
- `conn.assigns.current_scope` — host-generated struct with `:user`, `:active_organization`, `:membership`, `:impersonating_from`
- `conn.private[:sigra_session]` — `Sigra.Session` with id, IP, UA, geo, impersonator IDs, sudo timestamps
- Telemetry `[:sigra, :audit, :log]` — fires on Sigra's own audit-log commit

**Current state at planting:** Threadline v1.11 shipped 2026-04-24; v1.12 (Phases 38–40) not started; no `Threadline.Integrations.*` namespace exists; no `999.x` backlog parking lot exists; no prior seeds.

## Notes

**Locked architectural framing (input for spec phase, not subject to reopening):**

1. Sigra stays unaware of Threadline. Adapter lives on the Threadline side.
2. No hard Threadline dependency in Sigra (confirmed by Sigra's own decision).
3. Threadline must remain auth-agnostic — integration must coexist with hosts using other auth (Pow, `phx.gen.auth`, custom, none).
4. Sigra is one possible auth source, not a privileged core dependency.

**Open design questions for the spec phase (full text in research note):**

1. How to represent **impersonation** in `ActorRef` (closed at 6 types, no first-class impersonation slot — encode in `:id`? extend `AuditContext`? extend `ActorRef`?)
2. Where **organization scope** lands (extend `ActorRef`? extend `AuditContext`? encode in `:id`? out of scope?)
3. Whether `session.id` should populate `audit_context.correlation_id` when no `x-correlation-id` header is present
4. **Telemetry subscription vs Plug-only adapter** — does subscribing to `[:sigra, :audit, :log]` catch Oban/non-Plug auth events worth auditing, or is Plug-only sufficient for v1?
5. **Service-account / API-token actor mapping** — `Sigra.APIToken`-authenticated requests: `:service_account` with token-owner ID, or `:user` with on-behalf-of user?
6. **`:anonymous` fallback policy** when `current_scope` is nil — return `nil` (no actor) or `ActorRef.new(:anonymous, nil)`?

**Why deferred from v1.12:** v1.12 is focused on As-of / Point-in-Time
Reconstruction (Phases 38–40), an unrelated capability. Inserting Sigra
integration mid-milestone would derail focus; landing it after v1.12 ships
gives it a clean phase of its own and lets the spec phase benefit from any
ActorRef/AuditContext lessons learned during temporal-reconstruction work.

**Why a seed and not a backlog entry or v1.13 pre-commit:** Threadline doesn't
maintain a 999.x backlog parking lot today. Pre-committing as a v1.13 phase
would lock in scope before the spec phase has run (the three-tier choice is
real and shouldn't be foreclosed). A seed with explicit triggers is the
lightest-weight option that preserves all the exploration context and surfaces
automatically at the right moment.
