# Phase 49: Native Plug Context Overrides - Research

**Researched:** 2026-05-05
**Domain:** Elixir Plug/Phoenix request-context integration for `Threadline.Plug` `[VERIFIED: lib/threadline/plug.ex]`
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Verbatim copy from `49-CONTEXT.md` `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]`

- **D-01:** `Threadline.Plug` should expose `:context_overrides_fn` as a generic host-level callback, not as a Sigra-specific or correlation-only escape hatch.
- **D-02:** The top-line host-wiring story is two direct callbacks on `Threadline.Plug`: `actor_fn` for identity and `context_overrides_fn` for additive request metadata.
- **D-03:** Actor ownership stays with `actor_fn`. `:context_overrides_fn` must not become a second actor-authority path.
- **D-04:** Narrow the override allowlist to additive request metadata only: `:request_id` and `:correlation_id`.
- **D-05:** Remove `:actor_ref` from the override allowlist. Allowing actor replacement through `:context_overrides_fn` creates ambiguous provenance, weakens the `actor_fn` contract, and is too easy to misuse in misordered pipelines.
- **D-06:** Remove `:remote_ip` from the override allowlist. Proxy-aware IP normalization is a host concern and should happen upstream before `Threadline.Plug`; the library should keep `remote_ip` derived from `conn.remote_ip`.
- **D-07:** Transport-derived values are authoritative. `request_id` and `correlation_id` should come from the normal conn/header extraction path first.
- **D-08:** `:context_overrides_fn` may supplement `:request_id` or `:correlation_id` only when the derived base value is `nil`; it must not replace an explicit inbound header or already-derived value.
- **D-09:** Keep the existing least-surprise rule already implied by Sigra integration: when `x-correlation-id` is present, it wins and override callbacks should return `%{}` for that field.
- **D-10:** Validation inside `Threadline.Plug` should stay narrow and deterministic: the callback must return a map and the keys must be a subset of the allowed override keys.
- **D-11:** Unknown keys must raise `ArgumentError` immediately. Non-map returns must also raise `ArgumentError` immediately. Invalid shapes should fail loudly, not be ignored.
- **D-12:** Do not add deep coercion or Ecto-style casting inside `Threadline.Plug`. Hosts should normalize values before returning them from the callback. This keeps the public contract small and avoids turning the hook into a mini validation framework.
- **D-13:** `nil` values in the returned override map are non-destructive and do not delete or clobber derived values.
- **D-14:** Teach this feature as a generic `Threadline.Plug` host-wiring capability first, with `Threadline.Integrations.Sigra` as the canonical worked example.
- **D-15:** Do not frame the feature as "the correlation hook." That is too narrow for the public surface and creates future naming pressure once `request_id` and other additive request metadata matter.
- **D-16:** Keep actor identity primary in the narrative. `context_overrides_fn` is additive enrichment, not a peer replacement for actor extraction.
- **D-17:** Documentation must make placement, precedence, and failure behavior explicit: where the plug belongs, which values win, what raises, and what stays host-owned.
- **D-18:** Favor explicit, narrow options over broad escape hatches. This matches Plug/Phoenix conventions and protects the library from surprising behavior becoming a permanent public contract.
- **D-19:** Preserve unchanged behavior for hosts that only use `actor_fn` or do not pass `:context_overrides_fn` at all.
- **D-20:** Recommendation-first synthesis is preferred for low- and medium-impact planning choices in this project. Escalate interactively only for choices that materially affect public API stability, security model, naming, or milestone scope.

### Claude's Discretion
Verbatim copy from `49-CONTEXT.md` `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]`

- Exact wording of the moduledoc and guide prose, provided it preserves the contract above.
- Whether to phrase the docs as "additive request metadata" or "additive request-derived audit context," provided the meaning stays narrow and explicit.
- Exact test organization and helper naming, provided precedence and failure behavior are fully locked.

### Deferred Ideas (OUT OF SCOPE)
Verbatim copy from `49-CONTEXT.md` `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]`

- A separate future option for host-controlled IP normalization, if real adopter pressure appears. Do not smuggle this into `:context_overrides_fn` now.
- Any broader generic metadata surface beyond `:request_id` and `:correlation_id`, unless a future phase establishes a concrete need with clear provenance rules.
- Any second actor override path or escape hatch through `:context_overrides_fn`.
- Any deeper coercion, casting, or schema-like validation layer inside `Threadline.Plug`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PLUG-01 | Phoenix hosts can supply additive request-derived audit context through `Threadline.Plug` without introducing a companion pre-plug solely for correlation or request metadata overrides. `[VERIFIED: .planning/REQUIREMENTS.md]` | Use a native `:context_overrides_fn` that merges only `:request_id` and `:correlation_id` onto a baseline `AuditContext`, with nil-only supplementation and router-level direct callback wiring. `[VERIFIED: lib/threadline/plug.ex] [CITED: https://hexdocs.pm/phoenix/plug.html] [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html]` |
| PLUG-02 | `Threadline.Plug` rejects invalid override shapes deterministically so hosts get a tight, testable public contract for `:context_overrides_fn`. `[VERIFIED: .planning/REQUIREMENTS.md]` | Keep shape validation narrow: non-map returns and unknown keys raise `ArgumentError` immediately; planner should extend tests around forbidden `:actor_ref` and `:remote_ip` keys plus precedence behavior. `[VERIFIED: lib/threadline/plug.ex] [VERIFIED: test/threadline/plug_test.exs]` |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Threadline has three layers with separate responsibilities: capture, semantics, and exploration/operations; this phase sits in the semantics/integration boundary and should not expand capture or exploration scope. `[VERIFIED: CLAUDE.md]`
- Use Threadline domain language consistently: `AuditContext`, `AuditAction`, `ActorRef`, and `Correlation` are distinct concepts. `[VERIFIED: CLAUDE.md]`
- The library is intended to be composable with Plug, Phoenix, Ecto, Oban, and LiveView; explicit Plug-friendly integration is therefore preferred over hidden magic. `[VERIFIED: CLAUDE.md]`
- Verification entrypoints should use named aliases such as `mix verify.test` and `mix ci.all` rather than ad-hoc command lists. `[VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]`
- Documentation contracts are part of the public API and should stay aligned with tests. `[VERIFIED: CLAUDE.md]`

## Summary

`Threadline.Plug` already contains the skeleton of the Phase 49 feature: it accepts `:context_overrides_fn`, derives a baseline `AuditContext`, validates map shape, and applies overrides before assigning `conn.assigns[:audit_context]`. `[VERIFIED: lib/threadline/plug.ex]` The current implementation is broader than the locked phase contract because it still allows overriding `:actor_ref` and `:remote_ip`, and it replaces derived values unconditionally when a non-nil override is returned. `[VERIFIED: lib/threadline/plug.ex]`

Phoenix and Plug precedent supports the narrowed design. Phoenix router pipelines are the standard place to wire explicit module-plug callbacks, and `Plug.RequestId` already follows the same “existing transport value wins; generate/fill only when absent” rule that this phase wants for `request_id`. `[CITED: https://hexdocs.pm/phoenix/plug.html] [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html] [CITED: https://hexdocs.pm/plug/Plug.RequestId.html]` Plug also documents `conn.remote_ip` as a field meant to be overwritten by upstream proxy-aware plugs, which aligns with the decision to keep remote IP host-owned and outside this callback surface. `[CITED: https://hexdocs.pm/plug/Plug.Conn.html]`

The plan should therefore treat Phase 49 as a contract-tightening pass over in-flight code, not a net-new feature build. The work is to narrow the allowlist, enforce nil-only supplementation semantics, preserve current actor-only hosts unchanged, and lock the contract in targeted unit and integration tests plus docs text that explicitly calls out placement, precedence, and failure behavior. `[VERIFIED: lib/threadline/plug.ex] [VERIFIED: test/threadline/plug_test.exs] [VERIFIED: test/threadline/integrations/sigra_test.exs] [VERIFIED: guides/integrations/sigra.md]`

**Primary recommendation:** Keep the native callback in `Threadline.Plug`, but implement it as a deterministic nil-only supplement for `:request_id` and `:correlation_id` only; reject any attempt to route actor or IP authority through it. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]`

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Extract actor identity from request state | API / Backend | — | `actor_fn` runs inside `Threadline.Plug` against `Plug.Conn`, and the repo already wires it in Phoenix router pipelines. `[VERIFIED: lib/threadline/plug.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]` |
| Derive baseline `request_id`, `correlation_id`, and `remote_ip` from transport state | API / Backend | — | The values come from request headers, `conn.assigns`, and `conn.remote_ip`, all inside the server-side `Plug.Conn`. `[VERIFIED: lib/threadline/plug.ex] [CITED: https://hexdocs.pm/plug/Plug.Conn.html]` |
| Normalize proxy-aware client IP | API / Backend | CDN / Static | Plug documents `remote_ip` as a field upstream plugs may rewrite from forwarded headers, so the host boundary owns that normalization before `Threadline.Plug` executes. `[CITED: https://hexdocs.pm/plug/Plug.Conn.html]` |
| Add missing request metadata when transport derivation returns `nil` | API / Backend | — | The new callback is a router plug option and should run in the same pipeline stage as actor extraction. `[VERIFIED: lib/threadline/plug.ex] [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html]` |
| Persist semantic use of `AuditContext` into `AuditAction` / downstream queries | API / Backend | Database / Storage | `AuditContext` feeds `Threadline.record_action/2` and later query surfaces, while durable storage stays in Ecto/Postgres-backed schemas. `[VERIFIED: lib/threadline/semantics/audit_context.ex] [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix/blog.ex]` |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | `1.19.5` `[VERIFIED: elixir --version]` | Runtime and language for the phase implementation and tests. `[VERIFIED: elixir --version]` | Matches the local execution environment and exceeds the project floor of `~> 1.15`. `[VERIFIED: elixir --version] [VERIFIED: mix.exs]` |
| Plug | `1.19.1` locked; latest listed by Hex as `1.19.1` on 2025-12-09. `[VERIFIED: mix.lock] [VERIFIED: mix hex.info plug]` | Owns `Plug.Conn`, plug callbacks, and request metadata extraction semantics. `[VERIFIED: lib/threadline/plug.ex]` | This phase is fundamentally a `Plug` contract change, and official docs provide direct precedent for request-id precedence and upstream IP rewriting. `[CITED: https://hexdocs.pm/plug/Plug.RequestId.html] [CITED: https://hexdocs.pm/plug/Plug.Conn.html]` |
| Phoenix | Example app locked at `1.8.5`; Hex lists `1.8.6` released on 2026-05-05. `[VERIFIED: examples/threadline_phoenix/mix.exs] [VERIFIED: mix hex.info phoenix]` | Provides the router pipeline where hosts wire `Threadline.Plug`. `[VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]` | Official router/pipeline docs match the repo’s direct callback wiring approach. `[CITED: https://hexdocs.pm/phoenix/plug.html] [CITED: https://hexdocs.pm/phoenix/Phoenix.Router.html]` |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ExUnit / Mix test | `1.19.5` via local Mix runtime. `[VERIFIED: mix --version]` | Fast unit coverage for precedence, failure mode, and compatibility behavior. `[VERIFIED: test/threadline/plug_test.exs]` | Use for all phase-gating tests; existing targeted suites already run green in under a second. `[VERIFIED: mix test test/threadline/plug_test.exs] [VERIFIED: mix test test/threadline/integrations/sigra_test.exs]` |
| Ecto SQL | `3.13.5` locked; latest listed by Hex as `3.13.5` on 2026-03-03. `[VERIFIED: mix.lock] [VERIFIED: mix hex.info ecto_sql]` | Needed for the full repository suite and test bootstrapping, though not for the narrow plug unit tests themselves. `[VERIFIED: test/test_helper.exs]` | Use when phase validation expands beyond unit-level contract tests into full `mix verify.test`. `[VERIFIED: test/test_helper.exs] [VERIFIED: mix.exs]` |
| `Threadline.Integrations.Sigra` | In-tree adapter; optional host dependency path `{:sigra, "~> 0.2", optional: true}` documented in guide and example app. `[VERIFIED: lib/threadline/integrations/sigra.ex] [VERIFIED: guides/integrations/sigra.md] [VERIFIED: examples/threadline_phoenix/mix.exs]` | Canonical worked example for callback composition and header-wins correlation behavior. `[VERIFIED: test/threadline/integrations/sigra_test.exs]` | Use as the exemplar integration when writing tests and docs, not as a special-case API surface. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native `:context_overrides_fn` in `Threadline.Plug` | Phase 44 two-plug pre-header injection pattern | The pre-plug pattern already works and mirrors `Plug.RequestId`, but it leaves additive context wiring as example-only host glue instead of a first-class Threadline contract. `[VERIFIED: .planning/milestones/v1.14-phases/44-sigra-integration-adapter/44-CONTEXT.md] [VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]` |

**Installation:** The repo already carries the relevant dependencies; phase planning should use existing `mix deps.get` / `mix test` flows rather than introduce new packages. `[VERIFIED: mix.exs] [VERIFIED: examples/threadline_phoenix/mix.exs]`

## Architecture Patterns

### System Architecture Diagram

```text
HTTP request
  -> Phoenix endpoint/router pipeline
  -> upstream host plugs
     -> Plug.RequestId / host proxy-IP rewrite / auth setup
  -> Threadline.Plug
     -> derive baseline actor via actor_fn(conn)
     -> derive baseline request_id from header then assigns
     -> derive baseline correlation_id from x-correlation-id header
     -> derive baseline remote_ip from conn.remote_ip
     -> if context_overrides_fn exists:
        -> call callback
        -> validate "is map?"
        -> validate keys subset of [:request_id, :correlation_id]
        -> for each allowed key:
           -> if baseline value is nil and override value is non-nil, fill it
           -> else keep baseline value
  -> assign conn.assigns[:audit_context]
  -> host code records AuditAction / audited writes
```

### Recommended Project Structure

```text
lib/threadline/
├── plug.ex                     # public plug contract and override semantics
├── integrations/sigra.ex      # canonical host adapter example
└── semantics/audit_context.ex # fixed context struct; no field expansion in this phase

test/threadline/
├── plug_test.exs              # callback contract and failure semantics
└── integrations/sigra_test.exs# canonical composition path and header-wins behavior

examples/threadline_phoenix/
└── lib/.../router.ex          # direct host-wiring example
```

### Pattern 1: Baseline-First, Nil-Only Supplement

**What:** Build `AuditContext` from transport state first, then allow `context_overrides_fn` to fill only missing `request_id` / `correlation_id` values. `[VERIFIED: lib/threadline/plug.ex] [VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]`

**When to use:** Any host callback that can derive additive request metadata but must not outrank explicit inbound headers or earlier pipeline derivation. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md] [CITED: https://hexdocs.pm/plug/Plug.RequestId.html]`

**Example:**

```elixir
# Source inspiration: https://hexdocs.pm/plug/Plug.RequestId.html
base = %AuditContext{
  actor_ref: extract_actor(conn, actor_fn),
  request_id: extract_request_id(conn),
  correlation_id: get_req_header(conn, "x-correlation-id") |> List.first(),
  remote_ip: format_ip(conn.remote_ip)
}

overrides = context_overrides_fn.(conn)
validate_context_overrides!(overrides)

Enum.reduce(overrides, base, fn
  {key, value}, acc when key in [:request_id, :correlation_id] and not is_nil(value) ->
    if Map.get(acc, key) == nil, do: Map.put(acc, key, value), else: acc

  {_key, _value}, acc ->
    acc
end)
```

### Pattern 2: Shape Validation at the Public Boundary

**What:** Validate callback output immediately inside `Threadline.Plug` and raise `ArgumentError` for non-map returns or unknown keys. `[VERIFIED: lib/threadline/plug.ex]`

**When to use:** Any plug callback that defines a stable public contract and should fail loudly on host misuse instead of silently discarding data. `[VERIFIED: lib/threadline/plug.ex]`

**Example:**

```elixir
# Source pattern: https://hexdocs.pm/phoenix/plug.html
defp validate_context_overrides!(overrides) when is_map(overrides) do
  case Map.keys(overrides) -- [:request_id, :correlation_id] do
    [] -> :ok
    unknown_keys -> raise ArgumentError, "unknown audit context override keys: #{inspect(unknown_keys)}"
  end
end

defp validate_context_overrides!(other) do
  raise ArgumentError, "context_overrides_fn must return a map, got: #{inspect(other)}"
end
```

### Anti-Patterns to Avoid

- **Second actor-authority path:** Letting `context_overrides_fn` replace `actor_ref` would contradict the locked actor ownership boundary and create provenance ambiguity. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]`
- **Proxy/IP logic in the override callback:** Plug documents proxy-aware IP rewriting as an upstream concern; adding it here would permanently widen the API around transport normalization. `[CITED: https://hexdocs.pm/plug/Plug.Conn.html]`
- **Silent ignore of bad callback output:** The current contract already raises on bad shapes; softening that would make host misconfiguration harder to detect and would violate PLUG-02. `[VERIFIED: lib/threadline/plug.ex] [VERIFIED: .planning/REQUIREMENTS.md]`
- **Unconditional override replacement:** Overwriting an existing header-derived `request_id` or `correlation_id` would violate the locked precedence model and diverge from `Plug.RequestId` expectations. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md] [CITED: https://hexdocs.pm/plug/Plug.RequestId.html]`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Request-id generation and precedence | Custom request-id semantics inside `Threadline.Plug` | `Plug.RequestId` plus Threadline’s existing header/assign read path | `Plug.RequestId` already defines the ecosystem rule for request-id ownership and fallback. `[CITED: https://hexdocs.pm/plug/Plug.RequestId.html]` |
| Proxy-aware client-IP extraction | Ad hoc `x-forwarded-for` parsing in `context_overrides_fn` | Upstream host plug or endpoint configuration that rewrites `conn.remote_ip` before Threadline runs | Plug documents `remote_ip` as an upstream rewrite point; keeping Threadline out of that avoids security-sensitive parsing logic. `[CITED: https://hexdocs.pm/plug/Plug.Conn.html]` |
| Alternate actor override channel | Map-based `actor_ref` override in `context_overrides_fn` | `actor_fn` only | The repo already provides a dedicated actor callback, and the phase locks actor ownership there. `[VERIFIED: lib/threadline/plug.ex] [VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]` |

**Key insight:** The only safe custom logic in this phase is “derive missing additive metadata from host request state”; everything else already has a clearer owner in Plug, Phoenix, or the existing `actor_fn` contract. `[CITED: https://hexdocs.pm/plug/Plug.Conn.html] [CITED: https://hexdocs.pm/plug/Plug.RequestId.html] [VERIFIED: lib/threadline/plug.ex]`

## Common Pitfalls

### Pitfall 1: Preserving the Broad Override Allowlist

**What goes wrong:** The planner treats the current in-flight implementation as final and leaves `:actor_ref` / `:remote_ip` in `@allowed_override_keys`. `[VERIFIED: lib/threadline/plug.ex]`

**Why it happens:** The current code and tests explicitly exercise those keys, so a superficial “feature already exists” read misses the narrower locked phase contract. `[VERIFIED: lib/threadline/plug.ex] [VERIFIED: test/threadline/plug_test.exs]`

**How to avoid:** Make allowlist narrowing an explicit first implementation task and update tests/doc text in the same wave. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]`

**Warning signs:** Tests still mention overriding `actor_ref` or `remote_ip`, or moduledoc text still advertises those keys. `[VERIFIED: lib/threadline/plug.ex] [VERIFIED: test/threadline/plug_test.exs]`

### Pitfall 2: Replacing Header-Derived Values Instead of Filling Nil

**What goes wrong:** A non-nil callback result clobbers `x-request-id` or `x-correlation-id` even when the request already supplied one. `[VERIFIED: lib/threadline/plug.ex]`

**Why it happens:** The current `Enum.reduce/3` unconditionally `Map.put/3`s any non-nil override value. `[VERIFIED: lib/threadline/plug.ex]`

**How to avoid:** Add tests that assert header or earlier derivation wins, then implement fill-only semantics keyed by `Map.get(acc, key) == nil`. `[VERIFIED: test/threadline/integrations/sigra_test.exs] [CITED: https://hexdocs.pm/plug/Plug.RequestId.html]`

**Warning signs:** Tests cover `%{}` on header-present Sigra paths but do not cover a misbehaving callback trying to replace an existing value. `[VERIFIED: test/threadline/integrations/sigra_test.exs]`

### Pitfall 3: Confusing Host Normalization with Threadline Enrichment

**What goes wrong:** Planner tasks try to solve proxy-aware IP handling or broader request metadata normalization inside this phase. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]`

**Why it happens:** `AuditContext` already contains `remote_ip`, which makes it tempting to widen the new callback to “all context fields.” `[VERIFIED: lib/threadline/semantics/audit_context.ex]`

**How to avoid:** Keep the phase scoped to `request_id` and `correlation_id` only, and point any IP work back to upstream host plugs. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md] [CITED: https://hexdocs.pm/plug/Plug.Conn.html]`

**Warning signs:** Planner includes tasks about forwarded-header parsing, CIDR logic, or remote-IP validation. `[CITED: https://hexdocs.pm/plug/Plug.Conn.html]`

## Code Examples

Verified patterns from official and codebase sources:

### Router-Level Direct Callback Wiring

```elixir
# Source: https://hexdocs.pm/phoenix/plug.html
pipeline :api do
  plug :accepts, ["json"]

  plug Threadline.Plug,
    actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
    context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
end
```

This is already the example app shape in the repo. `[VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex]`

### Existing Correlation Header-Wins Pattern

```elixir
# Source: lib/threadline/integrations/sigra.ex
def audit_context_overrides_from_conn(conn) do
  if header_correlation_id?(conn) do
    %{}
  else
    build_audit_overrides(conn)
  end
end
```

This adapter behavior is the canonical compatibility target for Phase 49’s precedence rules. `[VERIFIED: lib/threadline/integrations/sigra.ex] [VERIFIED: test/threadline/integrations/sigra_test.exs]`

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Example-only pre-plug header injection before `Threadline.Plug` | First-class native `:context_overrides_fn` on `Threadline.Plug` | Phase 44 documented the pre-plug workaround on 2026-04-26; Phase 49 context locks the native callback direction on 2026-05-05. `[VERIFIED: .planning/milestones/v1.14-phases/44-sigra-integration-adapter/44-CONTEXT.md] [VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]` | Host wiring becomes simpler and officially supported, but only if the callback surface stays narrow and deterministic. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]` |

**Deprecated/outdated:**

- The broad override contract advertised in the current `Threadline.Plug` moduledoc is outdated for this phase because it still lists `:actor_ref` and `:remote_ip`. `[VERIFIED: lib/threadline/plug.ex]`
- The “companion pre-plug solely for correlation wiring” story is outdated as the primary recommendation once Phase 49 lands. `[VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]`

## Assumptions Log

All claims in this research were verified in the current session or cited from official documentation. `[VERIFIED: this file's source tags]`

## Open Questions (RESOLVED)

1. **None blocking for planning.** The phase contract, affected files, test surfaces, and host-facing precedence rules are already locked strongly enough to produce executable plans. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md] [VERIFIED: .planning/ROADMAP.md]`

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Implementation and test execution | ✓ `[VERIFIED: elixir --version]` | `1.19.5` `[VERIFIED: elixir --version]` | — |
| Mix | Named verification entrypoints | ✓ `[VERIFIED: mix --version]` | `1.19.5` `[VERIFIED: mix --version]` | — |
| PostgreSQL CLI | Full suite bootstrap and DB-backed tests | ✓ `[VERIFIED: psql --version]` | `14.17` `[VERIFIED: psql --version]` | Targeted unit tests for this phase do not require a live DB. `[VERIFIED: mix test test/threadline/plug_test.exs] [VERIFIED: mix test test/threadline/integrations/sigra_test.exs]` |
| Docker | Optional local Postgres/bootstrap workflow mentioned by test helper | ✓ `[VERIFIED: docker --version]` | `29.4.1` `[VERIFIED: docker --version]` | Use an already running local PostgreSQL instance if Docker is not desired. `[VERIFIED: test/test_helper.exs]` |

**Missing dependencies with no fallback:** None. `[VERIFIED: environment probes above]`

**Missing dependencies with fallback:** None. `[VERIFIED: environment probes above]`

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix on Elixir `1.19.5`. `[VERIFIED: mix --version] [VERIFIED: test/test_helper.exs]` |
| Config file | `test/test_helper.exs`. `[VERIFIED: test/test_helper.exs]` |
| Quick run command | `mix test test/threadline/plug_test.exs test/threadline/integrations/sigra_test.exs` `[VERIFIED: executed in this session]` |
| Full suite command | `mix verify.test` `[VERIFIED: mix.exs]` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PLUG-01 | Native direct callback wiring fills missing additive metadata without a separate pre-plug and without changing actor-only hosts. `[VERIFIED: .planning/REQUIREMENTS.md]` | Unit + integration | `mix test test/threadline/plug_test.exs test/threadline/integrations/sigra_test.exs` | ✅ existing files; cases need expansion for nil-only `request_id` and forbidden override keys. `[VERIFIED: test/threadline/plug_test.exs] [VERIFIED: test/threadline/integrations/sigra_test.exs]` |
| PLUG-02 | Invalid override shapes raise deterministically. `[VERIFIED: .planning/REQUIREMENTS.md]` | Unit | `mix test test/threadline/plug_test.exs` | ✅ existing file; retain current non-map/unknown-key coverage and retarget it to the narrowed allowlist. `[VERIFIED: test/threadline/plug_test.exs]` |

### Sampling Rate

- **Per task commit:** `mix test test/threadline/plug_test.exs test/threadline/integrations/sigra_test.exs` `[VERIFIED: executed in this session]`
- **Per wave merge:** `mix verify.test` `[VERIFIED: mix.exs]`
- **Phase gate:** `mix verify.test` green before `/gsd-verify-work`. `[VERIFIED: mix.exs]`

### Wave 0 Gaps

- [ ] `test/threadline/plug_test.exs` — replace broad override examples with locked allowlist cases: reject `:actor_ref`, reject `:remote_ip`, preserve baseline values when override tries to replace non-nil transport-derived fields. `[VERIFIED: test/threadline/plug_test.exs]`
- [ ] `test/threadline/integrations/sigra_test.exs` — keep header-wins coverage and add explicit direct-callback composition assertions for native nil-only supplementation semantics. `[VERIFIED: test/threadline/integrations/sigra_test.exs]`
- [ ] Doc-contract coverage does not yet lock the narrowed `Threadline.Plug` public wording for allowed keys and precedence; planner should add or extend a doc-contract test in the phase. `[VERIFIED: rg results for context_overrides_fn and current doc-contract files]`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no `[VERIFIED: phase scope in .planning/ROADMAP.md]` | Actor extraction stays delegated to host `actor_fn`; this phase does not introduce new auth flows. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]` |
| V3 Session Management | no `[VERIFIED: phase scope in .planning/ROADMAP.md]` | Session handling remains host-owned or Sigra-owned. `[VERIFIED: lib/threadline/integrations/sigra.ex]` |
| V4 Access Control | yes `[VERIFIED: provenance decisions in 49-CONTEXT.md]` | Single actor-authority path via `actor_fn`; do not allow `context_overrides_fn` to replace actor identity. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]` |
| V5 Input Validation | yes `[VERIFIED: PLUG-02]` | Immediate `ArgumentError` on bad callback shape or keys. `[VERIFIED: lib/threadline/plug.ex]` |
| V6 Cryptography | no `[VERIFIED: phase scope in .planning/ROADMAP.md]` | None required in this phase. `[VERIFIED: .planning/ROADMAP.md]` |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Actor provenance spoofing through override map | Spoofing | Remove `:actor_ref` from the override allowlist and keep identity authority in `actor_fn` only. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]` |
| Header/callback clobbering of existing transport values | Tampering | Use nil-only supplementation so explicit inbound `x-request-id` / `x-correlation-id` values remain authoritative. `[VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md] [CITED: https://hexdocs.pm/plug/Plug.RequestId.html]` |
| Unexpected callback payload keys widening behavior silently | Tampering | Raise `ArgumentError` on unknown keys immediately. `[VERIFIED: lib/threadline/plug.ex]` |
| Proxy IP spoofing through arbitrary callback data | Spoofing | Keep `remote_ip` derived from `conn.remote_ip` and require upstream proxy-aware rewriting. `[CITED: https://hexdocs.pm/plug/Plug.Conn.html] [VERIFIED: .planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md]` |

## Sources

### Primary (HIGH confidence)

- `lib/threadline/plug.ex` - current implementation surface, allowed keys, precedence gap, validation behavior.
- `test/threadline/plug_test.exs` - current contract tests and remaining broad-surface examples.
- `lib/threadline/integrations/sigra.ex` - canonical nil-return / header-wins adapter behavior.
- `test/threadline/integrations/sigra_test.exs` - direct composition and header-wins verification.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` - current direct callback wiring in the example app.
- `mix.exs`, `mix.lock`, `examples/threadline_phoenix/mix.exs` - project dependency floors and locked versions.
- `test/test_helper.exs` - full-suite test bootstrapping requirements.
- `https://hexdocs.pm/plug/Plug.RequestId.html` - official request-id precedence behavior.
- `https://hexdocs.pm/plug/Plug.Conn.html` - official `remote_ip` ownership semantics.
- `https://hexdocs.pm/phoenix/plug.html` - official Plug/Phoenix wiring guidance.
- `https://hexdocs.pm/phoenix/Phoenix.Router.html` - official router pipeline behavior.

### Secondary (MEDIUM confidence)

- `.planning/milestones/v1.14-phases/44-sigra-integration-adapter/44-CONTEXT.md` - prior workaround pattern and migration context into the native callback.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - versions were verified from the local lockfile/runtime and Hex metadata during this session. `[VERIFIED: mix.lock] [VERIFIED: mix hex.info plug] [VERIFIED: mix hex.info ecto_sql] [VERIFIED: mix hex.info phoenix]`
- Architecture: HIGH - the key behavior is already implemented locally and aligns with official Plug/Phoenix docs. `[VERIFIED: lib/threadline/plug.ex] [CITED: https://hexdocs.pm/phoenix/plug.html] [CITED: https://hexdocs.pm/plug/Plug.RequestId.html]`
- Pitfalls: HIGH - the current code/tests directly expose the exact failure modes the phase must tighten. `[VERIFIED: lib/threadline/plug.ex] [VERIFIED: test/threadline/plug_test.exs]`

**Research date:** 2026-05-05
**Valid until:** 2026-06-04 for project-internal implementation details; re-check Hex/Phoenix version currency if planning is delayed. `[VERIFIED: mix hex.info phoenix] [VERIFIED: mix hex.info plug]`
