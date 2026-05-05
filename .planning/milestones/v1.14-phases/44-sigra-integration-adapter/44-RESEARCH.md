# Phase 44: sigra-integration-adapter — Research

**Researched:** 2026-05-01
**Domain:** Phoenix Plug + soft-dep adapter pattern (Threadline ↔ Sigra v0.2.x)
**Confidence:** HIGH

## Summary

Phase 44 ships a thin in-tree adapter (`Threadline.Integrations.Sigra`) that maps four Sigra-aware Phoenix conn shapes (user session, admin impersonation, API-token, anonymous) to the existing `ActorRef` + `correlation_id` slots that `Threadline.Plug`'s `:actor_fn` callback already consumes. SPEC and CONTEXT are tightly locked: 9 requirements, 14 implementation decisions, six SEED-001 questions answered. Nothing here re-litigates that — this research's job is to verify the **published Sigra v0.2.5 surface** the adapter must read and to surface code-level pinpoints the planner needs to write tasks.

**Three concrete findings the planner must factor in:**

1. **`%Sigra.APIToken{}` as a struct does not exist.** v0.2.5 `Sigra.APIToken` is an operations module; the actual API-token records use a host-generated schema (`config.api_token[:api_token_schema]`). The token-shape `current_scope` is built by `Sigra.Plug.FetchBearer` as `scope_module.new(%{id: user_id, auth_method: :api_token, token_id: ...})`. There is **no `conn.assigns.current_api_token`** in v0.2.5. SPEC line 41 and CONTEXT D-08 both reference `current_api_token` — that path doesn't exist as written. The adapter must detect the token shape from `current_scope.auth_method` (or `current_scope.token_id`) instead. (See Landmines §1.)

2. **`%Sigra.Scope{}` is host-generated, not library-defined.** `Sigra.Scope.build/3` calls `struct(scope_module, ...)` against a host module. Test doubles can ship a `Sigra.Scope` `defstruct` with the four canonical fields and the adapter will pattern-match cleanly, but the real-world struct in a host app is named whatever the host calls it (e.g. `MyApp.Auth.Scope`). The adapter must read scope shape via `Map.get/3` (already CONTEXT D-09) — never pattern-match on `%Sigra.Scope{}`.

3. **The Phase 23 example test currently pins the OLD stub's actor.** `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs:35-39` asserts `type: :service_account, id: "threadline-phoenix-example"`. After Phase 44 this test will receive `actor_ref = nil` (anonymous fallback per Q6) because the test conn carries no Sigra session. SPEC requirement 8 says "existing example test suite continues to pass without modification" — that's incorrect; this test must change. (See Landmines §3.)

**Primary recommendation:** Plan three tasks against an unambiguous physical layout, with eyes-open on the three findings above. Use the existing `stg_doc_contract_test.exs` shape verbatim for the new doc-contract test. Keep `Code.ensure_loaded?(Sigra.Session)` as the single soft-dep gate. Flag findings 1 and 3 as planner-level adjustments — they don't re-open SPEC's locked semantic decisions, but they do change task wording.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Adapter module (`actor_ref_from_conn/1`, `audit_context_overrides_from_conn/1`, `actor_fn/0`) | Library (`lib/threadline/integrations/`) | — | Threadline-owned bridge code; ships in the published Hex package |
| Soft-dep guard (`Code.ensure_loaded?(Sigra.Session)`) | Library | — | Single gate inside the adapter; same module |
| Test doubles (`Sigra.Session`, `Sigra.Scope`, `Sigra.APIToken` shims) | Test support (`test/support/`) | — | `elixirc_paths(:test)`; never compiled when Sigra is real |
| Pre-plug header injection (`SigraContextPlug`) | Example app (`examples/threadline_phoenix/lib/`) | Documented in guide | Host-owned plug; demonstrated in example, copy-pasted by integrators |
| Example app rewiring (router pipeline + `audit_actor.ex` delegation) | Example app | — | Adopter-facing reference; not part of the Hex package |
| Integration guide (`guides/integrations/sigra.md`) | Library docs (ExDoc extra) | — | Ships with `mix.exs` `:files` glob; surfaced via Phase 48's `extras` list |
| Doc-contract test | Library tests (`test/threadline/integrations/`) | — | Fails CI if guide drifts |

## Standard Stack

### Core (already in mix.exs — nothing new)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:plug` | `~> 1.15` (already in `mix.exs:53`) | Reads `Plug.Conn` assigns/private | Already a Threadline runtime dep; the adapter is a pure consumer |
| `:ex_doc` | `~> 0.34` (dev only, `mix.exs:56`) | Builds `guides/integrations/sigra.md` extra | Already configured in `docs/0` (`mix.exs:110-162`) |

### Soft-dep target (NEVER added to library `mix.exs`)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:sigra` | `~> 0.2` (latest 0.2.5, published 2026-04-25) [VERIFIED: hex.pm/api/packages/sigra/releases/0.2.5] | Host auth library | Added ONLY in `examples/threadline_phoenix/mix.exs` as `optional: true` per SIGRA-02 |

### Alternatives Considered
None — locked by SPEC and CONTEXT. The adapter consumes Sigra's existing public surface; no library swap is in scope.

**Installation (verification only — confirms no new library deps needed):**
```bash
# Library: zero new deps; verify with
grep -nE '\{:sigra' mix.exs   # expect empty
# Example app:
cd examples/threadline_phoenix && mix deps.get
```

**Version verification:**
- `sigra` v0.2.5 — published 2026-04-25T18:31:49Z [VERIFIED: hex.pm/api/packages/sigra/releases/0.2.5]
- v0.2.x line includes 0.2.0, 0.2.2, 0.2.3, 0.2.4, 0.2.5 (current). The `~> 0.2` constraint in SPEC requirement 8 covers all five releases. [VERIFIED: hex.pm/api/packages/sigra]

## Sigra Library Public Surface (v0.2.x)

Confirmed against `https://github.com/sztheory/sigra/blob/v0.2.5/lib/sigra/`. Status legend: ✅ confirmed / ⚠ drifted / ❌ missing.

### `Sigra.Session` struct — ✅ confirmed (with extra fields)

`lib/sigra/session.ex` defines the struct with these 16 fields [VERIFIED: github.com/sztheory/sigra/blob/v0.2.5/lib/sigra/session.ex via raw fetch]:

```elixir
defstruct [
  :id, :user_id, :token, :hashed_token,
  type: :standard,
  ip: nil, user_agent: nil, parsed_ua: nil,
  geo_city: nil, geo_country_code: nil,
  last_active_at: nil, sudo_at: nil,
  active_organization_id: nil,
  impersonator_user_id: nil, impersonator_session_id: nil,
  inserted_at: nil
]
```

| Field SPEC references | Present in v0.2.5? | Notes |
|----------------------|--------------------|-------|
| `:id` | ✅ | Used as `<sid>` in `correlation_id` formats |
| `:user_id` | ✅ | Identifies the session owner |
| `:active_organization_id` | ✅ | Q2 source of org id |
| `:impersonator_user_id` | ✅ | Real admin's id during impersonation |
| `:impersonator_session_id` | ✅ | Original admin session preserved for restoration |

The 11 fields the SPEC doesn't reference (`:token`, `:hashed_token`, `:type`, `:ip`, `:user_agent`, `:parsed_ua`, `:geo_city`, `:geo_country_code`, `:last_active_at`, `:sudo_at`, `:inserted_at`) are not read by the adapter. Test-double shim (CONTEXT D-05) ships only the five fields listed above — that remains correct.

### `Sigra.Scope` — ⚠ drifted (host-generated, not library-defined)

`lib/sigra/scope.ex` is **library helper code that constructs host structs**, not a struct definition. From `Sigra.Scope.build/3` [CITED: github.com/sztheory/sigra/blob/v0.2.5/lib/sigra/scope.ex]:

```elixir
def build(scope_module, user, opts \\ []) when is_atom(scope_module) and is_list(opts) do
  struct(scope_module,
    user: user,
    active_organization: Keyword.get(opts, :active_organization),
    membership: Keyword.get(opts, :membership),
    impersonating_from: Keyword.get(opts, :impersonating_from)
  )
end
```

| SPEC field reference | Confirmed key on host struct? | Notes |
|---------------------|------------------------------|-------|
| `:user` | ✅ | Set by `build/3` for session and impersonation paths |
| `:active_organization` | ✅ | Set by phase-14 plugs for session paths |
| `:membership` | ✅ | Set by phase-14 plugs |
| `:impersonating_from` | ✅ | Set when admin starts impersonation |

**Implication for the adapter:** Pattern-matching on `%Sigra.Scope{}` would NEVER match in production (host's scope is `MyApp.Auth.Scope` or similar). The adapter must use `Map.get/3` (CONTEXT D-09 — already correct). The test-double `Sigra.Scope` shim is only useful in *Threadline's own test environment* — which is exactly where the doubles ship.

### `Sigra.APIToken` — ❌ no struct (operations module only)

`lib/sigra/api_token.ex` contains zero `defstruct` lines [VERIFIED via `grep defstruct` on raw source]. The module exposes `create/3`, `verify/2`, `revoke/2`, `revoke_all/2`, `audit_jwt_refresh/2`, etc. The actual API-token records use a host-generated schema accessed as `config.api_token[:api_token_schema]`.

**The token-shape `current_scope` is built differently from session-shape.** From `Sigra.Plug.FetchBearer` [CITED: github.com/sztheory/sigra/blob/v0.2.5/lib/sigra/plug/fetch_bearer.ex:120]:

```elixir
defp build_scope(scope_module, user_id, extra) do
  scope_module.new(Map.merge(%{id: user_id}, extra))
end
```

For an API-token request, `extra = %{token_scopes: token.scopes, auth_method: :api_token, token_id: token.id}`. The resulting scope has fields `id` (user id), `token_scopes`, `auth_method`, `token_id` — **no `:user` key**. JWT tokens follow the same path with `auth_method: :jwt, token_id: claims["jti"]`.

**Implication for D-08 detection order:** "API token detected" cannot be defined as `conn.assigns[:current_api_token] != nil` — there is no such assign. The signal is one of:
- `current_scope.auth_method in [:api_token, :jwt]`, OR
- `current_scope.token_id != nil`, OR
- `current_scope.user == nil and current_scope.id != nil`

The cleanest detection (and the one the planner should specify): **`Map.get(scope, :auth_method) in [:api_token, :jwt]`**. The user_id for the resulting `:service_account` ActorRef comes from `Map.get(scope, :id)`, NOT from a separate `current_api_token` assign.

### `Sigra.Plug.FetchBearer` — ✅ confirmed (D-08 rationale validated)

`lib/sigra/plug/fetch_bearer.ex:42-44` — explicitly skips when `current_scope` is already set:

```elixir
@impl Plug
def call(conn, opts) do
  if conn.assigns[:current_scope] do
    conn
  else
    do_fetch(conn, opts)
  end
end
```

This validates CONTEXT D-08's "session wins over token" rationale: when a session-fetch plug runs first and assigns `current_scope`, FetchBearer is a no-op. So if `current_scope` carries a `:user` key, the request is session-shape regardless of any Authorization header. **No explicit arbitration code needed in the adapter.**

### `Sigra.Plug.ForbidDuringImpersonation` — ✅ confirmed

Exists at `lib/sigra/plug/forbid_during_impersonation.ex` [VERIFIED via raw fetch]. Reads `conn.assigns[:current_scope]`. Pattern-matches `impersonating?(%{impersonating_from: %_{}})` — confirms the scope's `:impersonating_from` field is the impersonation signal. The adapter's order `impersonation → user → token → nil` (D-08) matches Sigra's own internal precedence.

### `Sigra.Audit.scope_fields/1` — ⚠ drifted (PRIVATE, not public)

SPEC line 17 cites `Sigra.Audit.scope_fields/1` as a public reference. In v0.2.5 `lib/sigra/audit.ex:149-164` it's `defp` (private) [VERIFIED via grep]:

```elixir
defp scope_fields(nil), do: [organization_id: nil, effective_user_id: nil, actor_id: nil]

defp scope_fields(%{user: user} = scope) do
  org = Map.get(scope, :active_organization)
  actor = Map.get(scope, :impersonating_from) || user
  [organization_id: org && org.id, effective_user_id: user && user.id, actor_id: actor && actor.id]
end
```

**Substantive (not cosmetic) drift from SPEC:** the SPEC presents `Sigra.Audit.scope_fields/1` as an externally-callable reference; it is not. The adapter cannot delegate to it. However, the **logic is the canonical pattern** Threadline should mirror: `actor = impersonating_from || user`, `actor_id = actor && actor.id`. CONTEXT D-09 already encodes this via `Map.get/3`. No code change needed; just don't try to call `Sigra.Audit.scope_fields/1` directly.

### `Sigra.Impersonation.actor_id/1` — ⚠ drifted (PRIVATE, not public)

Same status: `lib/sigra/impersonation.ex:134-141` is `defp` [VERIFIED via grep on raw source]. Adapter cannot delegate to it. Same recommendation: mirror the pattern, don't call the function.

### Sigra telemetry — ✅ confirmed (Q4 deferred path is real)

`Sigra.Audit.log/2` `@doc` (lines 45-50): "Fires `[:sigra, :audit, :log]` telemetry exactly once on success, never on failure." [CITED: lib/sigra/audit.ex:45-50] The deferred Q4 telemetry-subscription path therefore exists as written in REQUIREMENTS.md "Out of Scope" — Phase 44 correctly defers this.

## Threadline.Plug `:actor_fn` Contract

| Property | Value | File:Line |
|----------|-------|-----------|
| Option name | `:actor_fn` | `lib/threadline/plug.ex:16-18` |
| Signature | `(Plug.Conn.t() -> ActorRef.t() \| nil)` | `lib/threadline/plug.ex:16-17` |
| Default when omitted | `nil` (no actor extraction) | `lib/threadline/plug.ex:61` |
| When actor_fn returns `nil` | `extract_actor/2` returns `nil`; `audit_context.actor_ref` is `nil` | `lib/threadline/plug.ex:77-78` |
| When actor_fn raises | NOT handled — exception propagates and crashes the request | `lib/threadline/plug.ex:78` (no `try/rescue`) |
| Init contract | `init/1` builds `%{actor_fn: ...}` map; called once at compile time | `lib/threadline/plug.ex:59-63` |

**`correlation_id` extraction in v0.2.0 (current Threadline):**

```elixir
correlation_id: get_req_header(conn, "x-correlation-id") |> List.first()  # plug.ex:70
```

**No `context_overrides_fn` option exists.** A grep across `lib/` confirms zero matches for `context_overrides_fn`. CONTEXT D-11's "future `:context_overrides_fn` option" is correctly deferred — Phase 44 must NOT add this option to `Threadline.Plug`. Boundary line: `Threadline.Plug` source is unchanged this phase (SPEC "Out of scope" line 91).

**Critical edge cases the adapter must handle (from this contract):**
1. `actor_fn` is called for every request — must be cheap and never raise.
2. Returning `nil` is the documented "no actor" signal — distinct from `ActorRef.new(:anonymous, nil)` (which is also valid but means "explicitly anonymous"). Q6 chose `nil` to preserve this distinction.
3. The plug calls `actor_fn.(conn)` exactly once per request (`plug.ex:78`). Idempotency assumed.

## ActorRef + AuditContext Contracts

### ActorRef — closed-type rules [CITED: lib/threadline/semantics/actor_ref.ex]

| Aspect | Value | File:Line |
|--------|-------|-----------|
| `@types` (closed list) | `~w(user admin service_account job system anonymous)a` (length 6) | `lib/threadline/semantics/actor_ref.ex:24` |
| `defstruct` | `[:type, :id]`, `@enforce_keys [:type]` | `actor_ref.ex:21-22` |
| Constructor | `new/2` returns `{:ok, ref}` or `{:error, reason}` | `actor_ref.ex:35-52` |
| `:anonymous` with nil id | Valid — special-cased to skip empty-id check | `actor_ref.ex:41-43` |
| Non-anonymous with `nil` or `""` id | `{:error, :missing_actor_id}` | `actor_ref.ex:45-48` |
| Non-binary id | Falls through to `{:error, :missing_actor_id}` (no clause matches `is_binary`) | `actor_ref.ex:50-52` |
| Unknown type | `{:error, :unknown_actor_type}` | `actor_ref.ex:37-39` |
| JSONB serialization (anonymous) | `%{"type" => "anonymous"}` (no `"id"` key) | `actor_ref.ex:57-59` |
| JSONB serialization (other) | `%{"type" => Atom.to_string(type), "id" => id}` | `actor_ref.ex:61-63` |

**Adapter integration rule (from CONTEXT — already established):** call `ActorRef.new/2`, not direct struct construction. This ensures the `{:error, :missing_actor_id}` case is consistently handled when, e.g., a host's session has a session_id but a nil user_id (degenerate but possible).

**Concrete consequence for Q6:** Returning `nil` (per Q6) is structurally different from `ActorRef.new(:anonymous, nil)` which yields `%ActorRef{type: :anonymous, id: nil}` — and the latter serializes as `%{"type" => "anonymous"}` in JSONB. The adapter never produces the latter; the audit row's `actor_ref` column is `nil` in JSONB for anonymous requests under SPEC's chosen semantics. (Verify the column nullability with the planner — `audit_actions.actor_ref` should accept JSONB null; this is established for v0.2.0 since `extract_actor/2` already returns nil and the existing tests pass.)

### AuditContext — byte-identical preservation [CITED: lib/threadline/semantics/audit_context.ex]

```elixir
@enforce_keys []
defstruct [:actor_ref, :request_id, :correlation_id, :remote_ip]
```

| Field | Type | Source |
|-------|------|--------|
| `:actor_ref` | `ActorRef.t() \| nil` | from `:actor_fn` |
| `:request_id` | `String.t() \| nil` | from `x-request-id` header, then `conn.assigns[:request_id]` |
| `:correlation_id` | `String.t() \| nil` | from `x-correlation-id` header only (today) |
| `:remote_ip` | `String.t() \| nil` | from `conn.remote_ip` formatted via `:inet.ntoa/1` |

**SPEC requirement 5 acceptance criterion**: `defstruct` of `AuditContext` is byte-identical to pre-phase. Any test that wishes to assert this can do so via `Threadline.Semantics.AuditContext.__info__(:struct)` — that's the public reflection API for struct keys and defaults. Equivalent assertion: `:erlang.term_to_binary(struct(Threadline.Semantics.AuditContext))` compared across commits, but the `__info__` route is more idiomatic.

## Test-Double Loader Mechanism

### `elixirc_paths(:test)` — already in place

`mix.exs:44-45` already contains:
```elixir
defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(_), do: ["lib"]
```

**No mix.exs change required for the loader.** New file `test/support/sigra_test_doubles.ex` will be picked up automatically when `MIX_ENV=test`.

### Existing pattern to mirror

`test/support/data_case.ex` and `test/support/repo.ex` already use this pattern. They're plain `.ex` files (compiled), not `.exs` (interpreted). Compare with `test/test_helper.exs:9` which references `Threadline.Test.Repo` directly — confirming the `test/support/*.ex` files are precompiled before `test_helper.exs` runs.

### `unless Code.ensure_loaded?(Sigra.Session)` guard placement

The shim file's structure (per CONTEXT D-04):

```elixir
# test/support/sigra_test_doubles.ex
unless Code.ensure_loaded?(Sigra.Session) do
  defmodule Sigra.Session do
    @moduledoc false
    defstruct [:id, :user_id, :active_organization_id,
               :impersonator_user_id, :impersonator_session_id]
  end

  defmodule Sigra.Scope do
    @moduledoc false
    defstruct [:user, :active_organization, :membership, :impersonating_from]
  end

  defmodule Sigra.APIToken do
    @moduledoc false
    defstruct [:id, :user_id]
  end
end
```

The guard wraps all three `defmodule` blocks. When Sigra is genuinely installed (e.g., the example app's test env when `:sigra` is fetched as an optional dep), `Code.ensure_loaded?(Sigra.Session)` returns `true` and none of the shims are defined — Sigra's real modules win. In Threadline's own test env, Sigra is not in deps, `ensure_loaded?` returns `false`, and the three shims become available.

**Subtle concern (NOT a blocker, just awareness):** `Code.ensure_loaded?(Sigra.Session)` triggers a code-load attempt. In a pristine library test env where `:sigra` is genuinely not in `deps/`, this returns `false` cheaply. If a developer adds a dev-only `:sigra` dep without realizing it, the shims would silently disappear and tests would fail because the real `Sigra.APIToken` has no `defstruct` and the real `Sigra.Scope` has no struct at all. **The planner should add a verification task: `mix deps | grep -v sigra || raise "tests assume :sigra absent in library deps"`.**

### `Sigra.APIToken` shim caveat

Reality (from research above) is that `Sigra.APIToken` in v0.2.5 has NO struct. Defining `defstruct [:id, :user_id]` in the shim is fine **as long as the adapter never pattern-matches on `%Sigra.APIToken{}`**. The adapter SHOULD detect via `current_scope.auth_method` (see Sigra Public Surface §APIToken above). The `Sigra.APIToken` shim is technically only useful if a test wants to construct one for a fixture — but per the actual flow, the test fixture's conn just has a token-shaped `current_scope` (`%{id: user_id, auth_method: :api_token, token_id: ...}`) and the `Sigra.APIToken` shim is unused. The planner should consider whether to ship the shim at all; CONTEXT D-02 says yes (defensive coverage), and that remains a reasonable choice — the cost is one tiny `defmodule` block.

## Doc-Contract Test Idiom

The codebase has FIVE doc-contract tests; FOUR use `ExUnit.Case, async: true`, ONE uses `Threadline.DataCase` (only because it loads DB fixtures). For a pure file-read test, `ExUnit.Case, async: true` is the canonical pattern.

### Verbatim pattern from `test/threadline/stg_doc_contract_test.exs`

```elixir
defmodule Threadline.StgDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "CONTRIBUTING documents host STG evidence for integrators" do
    doc = read_rel!(["CONTRIBUTING.md"])
    assert String.contains?(doc, "## Host STG evidence (integrators)")
  end
end
```

### Established conventions (mirror these)

1. **Module name:** `Threadline.{Topic}DocContractTest` (e.g., `Threadline.SigraDocContractTest` — though SPEC requirement 9 specifies file path `test/threadline/integrations/sigra_doc_contract_test.exs`, so the module name should be `Threadline.Integrations.SigraDocContractTest` to match Mix's path-to-module convention).
2. **`@repo_root File.cwd!()` + `read_rel!/1` helper.** Three of four pure-file tests use this exact helper.
3. **`String.contains?/2` for literal-presence assertions.** No regex unless absolutely necessary.
4. **One `test` block per locked literal group** (e.g., one test for install snippet, one for Plug-callback line, one for each of the six SPEC outcomes).
5. **`async: true`** — the test does no I/O beyond `File.read!`; safe to parallelize.
6. **Ordering assertions** when guide structure is part of the contract: use `:binary.match/2` to find substring positions and compare (see `exploration_routing_doc_contract_test.exs:20-22`).

### Why NOT to copy `readme_doc_contract_test.exs`

`readme_doc_contract_test.exs:3` uses `Threadline.DataCase` because it loads `Threadline.ReadmeQuickstartFixtures` and calls `Repo.transaction` against a live DB. Phase 44's doc-contract test reads guide markdown only — no DB, no fixtures. CONTEXT D-13 already calls this out; this research re-confirms it.

## Example App Insertion Points

### `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` — REPLACE

Current contents (15 lines):
```elixir
defmodule ThreadlinePhoenix.AuditActor do
  @moduledoc false
  @doc """
  Returns a stable synthetic `ActorRef` for the example HTTP API.
  Phase 23 ignores `conn`; production should derive the actor from authentication.
  """
  def from_conn(_conn) do
    case Threadline.Semantics.ActorRef.new(:service_account, "threadline-phoenix-example") do
      {:ok, ref} -> ref
      {:error, _} -> nil
    end
  end
end
```

**Target shape (per SPEC requirement 8):**
```elixir
defmodule ThreadlinePhoenix.AuditActor do
  @moduledoc false
  defdelegate from_conn(conn), to: Threadline.Integrations.Sigra, as: :actor_ref_from_conn
end
```

The thin delegate works because `Threadline.Integrations.Sigra.actor_ref_from_conn/1` already returns `nil` when Sigra is absent (soft-dep guard). In the example app's test env Sigra IS installed (optional dep added by SIGRA-02), so the function exercises the real Sigra path. In a hypothetical "Sigra absent" example run, the delegate returns `nil` instead of a synthetic stub.

### `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — INSERT before line 6

Current pipeline (line 4-7):
```elixir
pipeline :api do
  plug(:accepts, ["json"])
  plug(Threadline.Plug, actor_fn: &ThreadlinePhoenix.AuditActor.from_conn/1)
end
```

**Target (per CONTEXT D-10 + D-12 — two-plug pattern):**
```elixir
pipeline :api do
  plug(:accepts, ["json"])
  plug(ThreadlinePhoenixWeb.SigraContextPlug)   # NEW — sets x-correlation-id if absent
  plug(Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1)
end
```

The `SigraContextPlug` is a new ~5-line module in `examples/threadline_phoenix/lib/threadline_phoenix_web/sigra_context_plug.ex` (or inline in the router — the guide's recommendation is a separate file). It mirrors `Plug.RequestId`'s "check-before-set" pattern.

### `examples/threadline_phoenix/mix.exs` — ADD line in `deps/0` block

Current `deps/0` ends at `mix.exs:54`. Insert:
```elixir
{:sigra, "~> 0.2", optional: true},
```

The `optional: true` flag means the example app does not insist Sigra be running; it's fetched at deps level so test fixtures can construct real `%Sigra.Session{}` etc.

### Library `mix.exs` — DO NOT modify

`grep -E '\{:sigra' mix.exs` MUST return zero matches after the phase. CI gate per SPEC line 31.

## ExDoc Extras Wiring

Library `mix.exs:115-129` defines `extras` (current 9 entries) and `groups_for_extras` (current 3 groups: Overview, Reference, Project).

**Current state** (no `guides/integrations/` referenced):
```elixir
extras: [
  "README.md",
  "guides/domain-reference.md",
  "guides/brownfield-continuity.md",
  "guides/production-checklist.md",
  "guides/adoption-pilot-backlog.md",
  "guides/audit-indexing.md",
  "CONTRIBUTING.md",
  "CHANGELOG.md"
],
groups_for_extras: [
  Overview: ~r/README/,
  Reference: ~r{^guides/},
  Project: ~r/(CONTRIBUTING|CHANGELOG)/
],
```

**Phase 44 question:** does Phase 44 modify `extras` to add `guides/integrations/sigra.md`?

**Answer (from REQUIREMENTS.md REL-02 line 38 + SPEC line 69):** NO. Phase 48 (REL-02) is responsible for:
1. Adding `guides/integrations/sigra.md` to `extras`.
2. Inserting `Integrations: ~r{^guides/integrations/}` BEFORE `Reference:` in `groups_for_extras` (regex order matters — first match wins).
3. Adding the new plural `Integrations:` entry to `groups_for_modules`.

Phase 44 ships the file `guides/integrations/sigra.md` and the doc-contract test. The file exists on disk; ExDoc just doesn't surface it yet. The file IS picked up by `mix.exs:106` `:files` glob (`guides`) — so the Hex tarball includes it — but `mix docs` doesn't render it as a navigable extra until Phase 48.

**Implication for Phase 44 doc-contract test:** assert `File.exists?("guides/integrations/sigra.md")` and read its contents. Do NOT assert anything about `mix.exs` `extras` membership — that's Phase 48's contract, locked by the future `release_artifact_contract_test.exs` (REL-02).

**One caveat for the planner:** if Phase 44 ships `guides/integrations/sigra.md` without `extras` wiring, `mix docs` will still build but the file will live on disk in `doc/` (unsurfaced). Hex publish (Phase 48) is the cutover. This is the documented expected sequence per the milestone roadmap — flag in the plan as an expected gap for now.

## Validation Architecture

**Note:** `.planning/config.json` does NOT set `workflow.nyquist_validation: false`, so this section is required.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir 1.15+) |
| Config file | `test/test_helper.exs` (ExUnit.start; PG storage_up; migrations) |
| Quick run command | `mix test test/threadline/integrations/` |
| Full suite command | `mix test` (library) followed by `mix verify.example` (example app) |
| Phase gate | `mix ci.all` green = `verify.format`, `verify.credo`, `compile --warnings-as-errors`, `verify.test`, `verify.threadline`, `verify.example`, `verify.doc_contract` (all listed in `mix.exs:69-78`) |

### Test Fixture Matrix (4 conn shapes × 2 environments)

The Nyquist sample boundary for this phase: **the four request shapes exercised in two environments (Sigra-present, Sigra-absent)**, plus the header-precedence axis. Total fixture combinations the test suite must cover:

| Conn Shape | Sigra absent (library tests w/ doubles) | Sigra present (example app w/ real Sigra) |
|------------|----------------------------------------|--------------------------------------------|
| **Anonymous** (no current_scope) | `actor_ref_from_conn = nil`; `audit_context_overrides = %{}` | Same — `Code.ensure_loaded?` true, scope absent path |
| **User session** (`current_scope` with `:user`, no `impersonating_from`) | Returns `%ActorRef{type: :user, id: <user_id>}`; overrides = `%{correlation_id: "sigra-session:<sid>"}` | Same; `<sid>` is real session id from `Sigra.Session{}` |
| **Admin impersonation** (`current_scope.impersonating_from` non-nil) | `%ActorRef{type: :admin, id: <admin_id>}`; overrides = `%{correlation_id: "sigra-imp:<sid>:user:<imp_user_id>"}` | Same; admin id from `Map.get(impersonating_from, :id)` |
| **API token** (`current_scope.auth_method == :api_token`) | `%ActorRef{type: :service_account, id: <token.user_id>}`; overrides = `%{correlation_id: "sigra-token:<token_id>"}` | Same path; FetchBearer-built scope |

**Header-precedence axis** (orthogonal): For each non-anonymous shape, also test `x-correlation-id: "explicit"` present → `audit_context_overrides_from_conn` returns `%{}` (header wins, never overridden).

**Org-scope axis** (orthogonal): For each non-anonymous shape with `active_organization_id: "99"`, the produced `correlation_id` ends in `:org:99`. With `nil` org, no `:org:` substring.

**Total minimum unit-test count:** 4 shapes × 3 axes (env, header, org) where applicable ≈ **18 base tests + 3 negative-path tests** (e.g., scope without `:user`, scope without `:auth_method`, scope `nil`).

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SIGRA-01 | Adapter module ships with three public functions | unit | `pytest`-equiv: `mix test test/threadline/integrations/sigra_test.exs::"public surface"` (ExUnit names) | ❌ Wave 0 — file does not exist |
| SIGRA-01 | Soft-dep guard returns nil when Sigra absent | unit | `mix test test/threadline/integrations/sigra_test.exs --only sigra_absent` | ❌ Wave 0 |
| SIGRA-01 | Three-conn-shape baseline (no current_scope, nil, %{user: nil}) | unit | `mix test test/threadline/integrations/sigra_test.exs --only baseline` | ❌ Wave 0 |
| SIGRA-01 (Q1) | Impersonation → admin actor + correlation_id | unit | `mix test test/threadline/integrations/sigra_test.exs --only impersonation` | ❌ Wave 0 |
| SIGRA-01 (Q5) | API token → service_account actor + sigra-token correlation | unit | `mix test test/threadline/integrations/sigra_test.exs --only api_token` | ❌ Wave 0 |
| SIGRA-01 (Q2) | active_organization_id appended as `:org:` suffix | unit | `mix test test/threadline/integrations/sigra_test.exs --only org_scope` | ❌ Wave 0 |
| SIGRA-01 (Q6) | Anonymous returns nil (NOT ActorRef.new(:anonymous, nil)) | unit | `mix test test/threadline/integrations/sigra_test.exs --only anonymous` | ❌ Wave 0 |
| SIGRA-01 (Q3) | x-correlation-id header wins; adapter returns %{} | unit | `mix test test/threadline/integrations/sigra_test.exs --only header_wins` | ❌ Wave 0 |
| SIGRA-01 | ActorRef @types length unchanged (= 6) | unit | `mix test test/threadline/integrations/sigra_test.exs::"closed types"` | ❌ Wave 0 |
| SIGRA-01 | AuditContext defstruct byte-identical | unit | `mix test test/threadline/integrations/sigra_test.exs::"audit_context defstruct"` | ❌ Wave 0 |
| SIGRA-02 | Example app delegates to adapter; mix.exs lists :sigra optional | integration | `mix verify.example` (covers `cd examples/threadline_phoenix && mix test`) | ⚠ exists but Phase 23 test pins old stub (Landmines §3) |
| SIGRA-02 | Library mix.exs has no :sigra | static check | `grep -E '\{:sigra' mix.exs` (assert empty) — fold into existing `mix.exs` policy test or add to topology contract test | ❌ Wave 0 (or extend existing) |
| SIGRA-03 | Guide ships with five sections | doc-contract | `mix test test/threadline/integrations/sigra_doc_contract_test.exs` | ❌ Wave 0 |
| SIGRA-03 | Six SPEC outcome literals locked | doc-contract | Same file, multiple test blocks | ❌ Wave 0 |
| SIGRA-03 | No `:telemetry.attach` in `lib/threadline/integrations/` | static check | `grep -rn ':telemetry.attach' lib/threadline/integrations/` (assert empty) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/integrations/` (typically <5 seconds; doc-contract is `File.read!` + asserts)
- **Per wave merge:** `mix test` (full library suite) + `mix verify.example` (slower; runs example app's full suite against PG)
- **Phase gate:** `mix ci.all` green before `/gsd-verify-work`

### Wave 0 Gaps (test infrastructure to create before adapter implementation)
- [ ] `test/threadline/integrations/` directory (does not exist)
- [ ] `test/threadline/integrations/sigra_test.exs` — covers SIGRA-01 unit tests
- [ ] `test/threadline/integrations/sigra_doc_contract_test.exs` — covers SIGRA-03
- [ ] `test/support/sigra_test_doubles.ex` — three `defstruct` shims, guarded by `unless Code.ensure_loaded?(Sigra.Session)`
- [ ] (Optional but recommended) `test/threadline/integrations/sigra_mix_exs_policy_test.exs` — asserts `:sigra` not in library deps (or fold into `phase06_nyquist_ci_contract_test.exs`)
- [ ] Update `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs:35-39` to expect new actor shape (Landmines §3 — this is technically a test edit, not a Wave 0 file creation, but it's a prerequisite to `mix verify.example` going green).

**Framework install:** None needed — ExUnit is built in.

## Architecture Patterns

### Pattern 1: Soft-dep adapter via single `Code.ensure_loaded?` gate

**What:** A library module that conditionally adapts behavior based on whether an optional dep is loaded, without listing the dep in `mix.exs`.

**When to use:** When the library wants to integrate cleanly with an external library without pulling it as a runtime dep, and integrators activate the integration by adding the dep themselves.

**Example skeleton:**
```elixir
# lib/threadline/integrations/sigra.ex
defmodule Threadline.Integrations.Sigra do
  @moduledoc """
  Adapter mapping Sigra-aware Phoenix conns to Threadline ActorRef + correlation_id.
  See `guides/integrations/sigra.md` for the wiring contract.
  """

  alias Threadline.Semantics.ActorRef

  @spec actor_ref_from_conn(Plug.Conn.t()) :: ActorRef.t() | nil
  def actor_ref_from_conn(conn) do
    if Code.ensure_loaded?(Sigra.Session) do
      do_actor_ref(conn)
    else
      nil
    end
  end

  @spec audit_context_overrides_from_conn(Plug.Conn.t()) :: %{optional(:correlation_id) => String.t()}
  def audit_context_overrides_from_conn(conn) do
    if Code.ensure_loaded?(Sigra.Session) do
      do_overrides(conn)
    else
      %{}
    end
  end

  @spec actor_fn() :: (Plug.Conn.t() -> ActorRef.t() | nil)
  def actor_fn, do: &actor_ref_from_conn/1

  defp do_actor_ref(conn) do
    scope = conn.assigns[:current_scope]
    cond do
      is_map(scope) and Map.get(scope, :impersonating_from) ->
        from = Map.get(scope, :impersonating_from)
        case ActorRef.new(:admin, get_id(from)) do
          {:ok, ref} -> ref
          {:error, _} -> nil
        end
      is_map(scope) and Map.get(scope, :user) ->
        case ActorRef.new(:user, get_id(Map.get(scope, :user))) do
          {:ok, ref} -> ref
          {:error, _} -> nil
        end
      is_map(scope) and Map.get(scope, :auth_method) in [:api_token, :jwt] ->
        case ActorRef.new(:service_account, Map.get(scope, :id)) do
          {:ok, ref} -> ref
          {:error, _} -> nil
        end
      true ->
        nil
    end
  end

  defp get_id(%{id: id}), do: id
  defp get_id(map) when is_map(map), do: Map.get(map, :id)
  defp get_id(_), do: nil

  # do_overrides/1 — analogous structure
end
```

The `Code.ensure_loaded?/1` call is cheap on subsequent invocations (the BEAM caches module-load state). For very hot paths a one-time `Application.compile_env/3` cache is sometimes used, but at HTTP-request frequency this is unnecessary.

### Pattern 2: Pre-plug header injection (the `Plug.RequestId` idiom)

**What:** A small plug that runs before another plug, enriches a request header conditionally, and lets the downstream plug consume the (now-enriched) header normally.

**When to use:** When the downstream plug reads from headers, you cannot modify the downstream plug, and you want "explicit user input wins" semantics.

**Example skeleton (the example app's `SigraContextPlug`):**
```elixir
defmodule ThreadlinePhoenixWeb.SigraContextPlug do
  @moduledoc """
  Sets x-correlation-id from Sigra state if and only if the header is absent.
  Mirrors Plug.RequestId's check-before-set idiom.
  """
  @behaviour Plug
  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    case get_req_header(conn, "x-correlation-id") do
      [_ | _] -> conn
      [] ->
        case Threadline.Integrations.Sigra.audit_context_overrides_from_conn(conn) do
          %{correlation_id: cid} when is_binary(cid) -> put_req_header(conn, "x-correlation-id", cid)
          _ -> conn
        end
    end
  end
end
```

This file lives in the **example app**, not the library. It's reproduced verbatim in `guides/integrations/sigra.md` as the integrator's copy-paste source.

### Recommended File Structure

```
lib/threadline/integrations/
└── sigra.ex                                    # NEW — adapter module

test/support/
├── data_case.ex                                # existing
├── readme_quickstart_fixtures.ex               # existing
├── repo.ex                                     # existing
└── sigra_test_doubles.ex                       # NEW — three defstruct shims, guarded

test/threadline/integrations/                   # NEW directory
├── sigra_test.exs                              # NEW — unit tests for adapter
└── sigra_doc_contract_test.exs                 # NEW — guide drift test

guides/integrations/                            # NEW directory
└── sigra.md                                    # NEW — five-section guide

examples/threadline_phoenix/lib/
├── threadline_phoenix/audit_actor.ex           # MODIFY — defdelegate to adapter
└── threadline_phoenix_web/
    ├── router.ex                               # MODIFY — two-plug pipeline
    └── sigra_context_plug.ex                   # NEW — pre-plug header injection

examples/threadline_phoenix/mix.exs             # MODIFY — add :sigra optional dep

examples/threadline_phoenix/test/threadline_phoenix_web/
└── posts_audit_path_test.exs                   # MODIFY (Landmines §3) — actor expectation
```

### Anti-Patterns to Avoid

- **Pattern-matching `%Sigra.Scope{}` in adapter code.** That struct doesn't exist in production — host's scope is host-named. Use `Map.get/3` (CONTEXT D-09).
- **Pattern-matching `%Sigra.APIToken{}` to detect token-shape.** No such struct exists in v0.2.5. Detect via `current_scope.auth_method`.
- **Reading `conn.assigns.current_api_token`.** No such assign in v0.2.5 (Landmines §1).
- **Calling `Sigra.Audit.scope_fields/1` or `Sigra.Impersonation.actor_id/1` directly.** Both `defp` (private). Mirror the logic instead.
- **Adding `:sigra` to library `mix.exs` (even `optional: true`).** Hard rule from REQUIREMENTS.md, SPEC line 95, and Acceptance Criterion grep gate.
- **Using `Code.require_file` in `test_helper.exs` to load doubles.** CONTEXT D-03 vetoed this — breaks Mix incremental compilation.
- **Modifying `lib/threadline/plug.ex`.** Out of scope per SPEC line 91. The `:context_overrides_fn` option is deferred (CONTEXT D-11).
- **Returning `ActorRef.new(:anonymous, nil)` for missing scope.** Q6 chose `nil`. Grepping for `:anonymous` in `lib/threadline/integrations/sigra.ex` MUST return zero matches per SPEC requirement 6 acceptance.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Conditional integration with optional dep | Custom dep-presence detection logic, environment flags, Application config feature toggles | `Code.ensure_loaded?(Sigra.Session)` — single gate | Standard Elixir pattern; integrates with the BEAM's existing module-load tracking |
| Pre-`Threadline.Plug` header injection | Custom plug pipeline reordering, monkey-patching `Threadline.Plug` | A small `MyApp.SigraContextPlug` mirroring `Plug.RequestId` | Phoenix devs recognize the pattern instantly; SPEC requirement 9(b) requires the verbatim Plug-callback line |
| Test doubles for missing modules | Mox, plain maps, `Mock` library | `defstruct` shims in `test/support/` guarded by `unless Code.ensure_loaded?` | CONTEXT D-01 — adapter reads struct fields, doesn't call functions; Mox is over-engineered for this |
| Doc-drift detection | Custom diff tools, snapshot tests, post-publish checks | `String.contains?/2` on `File.read!`'d markdown | Codebase pattern (5 doc-contract tests use this); fast, deterministic, runs in async ExUnit |
| ActorRef construction | Direct `%ActorRef{type: ..., id: ...}` struct literals | `ActorRef.new(type, id)` returning `{:ok, _}` or `{:error, _}` | Validation centralized; planner can write a defensive task that asserts no direct struct literals appear in the adapter |
| `correlation_id` header read | Re-read `x-correlation-id` inside the adapter | Let `Threadline.Plug` read the header (already does, plug.ex:70); adapter only writes via the pre-plug | Single source of truth for "what's the correlation_id"; matches CONTEXT D-10 |

**Key insight:** This phase is almost entirely *plumbing* — the design questions are settled, the libraries are settled, the patterns exist. The risk surface is in three small areas: (1) the actual shape of Sigra's token-path scope (Landmines §1), (2) the existing example test's pinned actor (Landmines §3), and (3) keeping the soft-dep contract intact under all combinations of "Sigra installed / not installed" × "library tests / example tests."

## Common Pitfalls

### Pitfall 1: Detecting token shape via a non-existent assign

**What goes wrong:** Adapter reads `conn.assigns[:current_api_token]`; in production this is always `nil` because `Sigra.Plug.FetchBearer` writes to `current_scope`, not a separate assign. Token-authenticated requests would silently fall through to `nil` (anonymous).

**Why it happens:** SPEC requirement 4 line 41 and CONTEXT D-08 both say `current_api_token`. v0.2.5 doesn't expose this assign.

**How to avoid:** Detect token shape via `Map.get(current_scope, :auth_method) in [:api_token, :jwt]`. Use `Map.get(current_scope, :id)` for the user_id (FetchBearer's `build_scope/3` calls `scope_module.new(%{id: user_id, ...})`).

**Warning signs:** Test fixture for token shape passes when scope has `:user` field but fails when scope has `:id` + `:auth_method` only.

### Pitfall 2: `Sigra.Scope` shim ships, but real scope is host-named

**What goes wrong:** Adapter pattern-matches `%Sigra.Scope{user: u}`; in tests the shim matches; in production the real scope is `MyApp.Auth.Scope` and the match fails — adapter always returns nil.

**Why it happens:** The shim is named `Sigra.Scope` (so `Code.ensure_loaded?(Sigra.Session)` correlates), but Sigra's real Scope is host-generated.

**How to avoid:** NEVER pattern-match on the scope's struct module. Use `Map.get/3`. Tests must construct scopes as plain maps where possible (e.g., `%{user: %{id: "u1"}}`) to verify the production path, OR use a clearly distinct host-style struct in fixtures (e.g., `%TestHost.Scope{user: ...}`) to force the adapter to use `Map.get/3`.

**Warning signs:** Test passes against `%Sigra.Scope{...}` but identical fixture data in a plain map fails.

### Pitfall 3: `Code.ensure_loaded?` race in concurrent test runs

**What goes wrong:** `Code.ensure_loaded?(Sigra.Session)` triggers a load; in async tests with multiple modules referencing it, you can hit `Code.LoadError` or duplicate-load warnings.

**Why it happens:** The BEAM module loader is process-safe but emits warnings under concurrent first-load.

**How to avoid:** The shim file at `test/support/sigra_test_doubles.ex` is compiled once at `mix compile` time, before any test runs. By the time `Code.ensure_loaded?` executes in tests, the module is either present (shim defined) or genuinely absent — no race. Confirm by running `mix test --max-cases 32` in CI as part of `verify.test`.

**Warning signs:** Flaky test failures specifically on `Code.ensure_loaded?` calls; warnings about `Sigra.Session` being redefined.

### Pitfall 4: Doc-contract test passes when guide is empty

**What goes wrong:** All `String.contains?/2` assertions check substring presence — a guide containing only the literal substrings concatenated (with no surrounding prose) would pass.

**Why it happens:** `String.contains?` doesn't validate structure or context.

**How to avoid:** Add at least one ordering assertion (e.g., "Install snippet appears before Plug callback") using `:binary.match/2` (see `exploration_routing_doc_contract_test.exs:20-22`). Add a minimum-length assertion (`assert byte_size(doc) > 1000`). Don't over-engineer — the contract test's job is drift detection, not editorial review.

**Warning signs:** Mutating the guide body (deleting paragraphs but keeping the literal anchors) doesn't fail the test.

### Pitfall 5: Forgetting `actor_fn/0` is a factory, not a runtime call

**What goes wrong:** `actor_fn/0` returns a captured function reference. A test that calls `actor_fn()` and then expects to assert ActorRef shape directly will fail because it received a function, not a struct.

**Why it happens:** Naming. `actor_fn/0` sounds like "the actor function" but is "give me the actor-resolution function reference."

**How to avoid:** Test like `assert is_function(adapter.actor_fn(), 1); assert adapter.actor_fn().(conn) == adapter.actor_ref_from_conn(conn)`.

**Warning signs:** Tests of `actor_fn/0` look mechanically odd; planner might be tempted to "simplify" away the factory function.

## Code Examples

Verified patterns. File paths are absolute; line citations are from the current working tree.

### Threadline.Plug — `:actor_fn` consumption (already exists; do not modify)
```elixir
# /Users/jon/projects/threadline/lib/threadline/plug.ex:65-78
@impl Plug
def call(conn, %{actor_fn: actor_fn}) do
  context = %AuditContext{
    actor_ref: extract_actor(conn, actor_fn),
    request_id: extract_request_id(conn),
    correlation_id: get_req_header(conn, "x-correlation-id") |> List.first(),
    remote_ip: format_ip(conn.remote_ip)
  }

  assign(conn, :audit_context, context)
end

defp extract_actor(_conn, nil), do: nil
defp extract_actor(conn, fun) when is_function(fun, 1), do: fun.(conn)
```

### ActorRef.new/2 — validating constructor (use this, not direct struct literals)
```elixir
# /Users/jon/projects/threadline/lib/threadline/semantics/actor_ref.ex:35-52
def new(type, id \\ nil)
def new(type, _id) when type not in @types, do: {:error, :unknown_actor_type}
def new(:anonymous, _id), do: {:ok, %__MODULE__{type: :anonymous, id: nil}}
def new(type, id) when id in [nil, ""], do: {:error, :missing_actor_id}
def new(type, id) when is_binary(id), do: {:ok, %__MODULE__{type: type, id: id}}
```

### `mix.exs` `elixirc_paths(:test)` — already in place
```elixir
# /Users/jon/projects/threadline/mix.exs:44-45
defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(_), do: ["lib"]
```

### Sigra.Plug.FetchBearer.build_scope — token-path scope shape
```elixir
# https://github.com/sztheory/sigra/blob/v0.2.5/lib/sigra/plug/fetch_bearer.ex:120-122
defp build_scope(scope_module, user_id, extra) do
  scope_module.new(Map.merge(%{id: user_id}, extra))
end
# Called with extra = %{token_scopes: ..., auth_method: :api_token, token_id: ...}
```

### Doc-contract test pattern — copy this for `sigra_doc_contract_test.exs`
```elixir
# /Users/jon/projects/threadline/test/threadline/stg_doc_contract_test.exs:1-27 (verbatim minus body)
defmodule Threadline.StgDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "..." do
    doc = read_rel!(["guides", "integrations", "sigra.md"])
    assert String.contains?(doc, "...")
  end
end
```

## Project Constraints (from CLAUDE.md)

- **Three-layer architecture (capture / semantics / exploration):** This phase touches the `Threadline.Integrations.*` namespace — a NEW boundary, not one of the three core layers. The adapter reads from `conn` and produces `ActorRef`/`correlation_id` for the **semantics layer**'s `AuditContext`. It does not touch capture (no trigger changes), it does not own action naming (Threadline does, via `ActorRef.@types`), it does not touch exploration (no query path changes).
- **Domain language:** Adapter must use `ActorRef` and `AuditContext` consistently in code, docs, and the integration guide. Do not invent terms like "AuditActor" in the new module's `@moduledoc` (the example app's `ThreadlinePhoenix.AuditActor` is a Phase 23 legacy name being delegated through, not a domain term).
- **CI conventions:** Phase 44 must continue to flow through `mix verify.test`, `mix verify.example`, `mix verify.doc_contract`, and `mix ci.all`. The new doc-contract test should be picked up by `mix verify.doc_contract` (alias at `mix.exs:66` runs `test test/threadline/readme_doc_contract_test.exs` — the planner may want to broaden this alias to include the new test, OR add a separate alias, OR rely on `verify.test` covering it).
- **Honest default tests:** No silent excludes. The new test files run as part of `mix test` by default. Topology-only tests use `pgbouncer_topology` tags (`test_helper.exs:6`) — the new tests should NOT need any tags.
- **Stable CI job IDs:** N/A this phase (no GitHub Actions changes).
- **Doc contract tests:** EXACTLY the artifact this phase produces (SIGRA-03). Required.
- **GSD positional `state.begin-phase` invocation:** flagged in CLAUDE.md. Already used for phase 44 — STATE.md is intact.

**`mix verify.doc_contract` extension question:** The planner should decide whether to:
- (a) Extend `mix.exs:66` to `["test test/threadline/readme_doc_contract_test.exs", "test test/threadline/integrations/sigra_doc_contract_test.exs"]`, OR
- (b) Generalize to `["test test/threadline/**/*_doc_contract_test.exs"]` (using shell glob — Mix doesn't expand globs, so this needs to be a Mix.Project function), OR
- (c) Leave as-is and rely on `verify.test` running the full suite (which already includes the new test).

Option (c) is simplest and consistent with how the four other doc-contract tests are already covered (none are listed individually in `verify.doc_contract`). Recommend (c) unless the planner sees a reason to specifically gate `sigra_doc_contract_test.exs` early in `ci.all`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Build/test | ✓ | `~> 1.15` (mix.exs:24) | — |
| Erlang/OTP | Runtime | ✓ | implicit via Elixir | — |
| PostgreSQL | `mix test` (library + example) | ✓ assumed | per `config/test.exs` | docker compose up -d (test_helper.exs:30) |
| `:sigra` Hex package v0.2.x | example app deps after SIGRA-02 | ✓ on Hex | 0.2.5 (latest) [VERIFIED 2026-05-01] | — |
| Internet access (for `mix deps.get` of `:sigra` in example) | One-time at deps fetch | depends on dev env | — | offline cache; flag if CI is offline |

**Missing dependencies with no fallback:** None — the library has no new external dependencies, and Sigra is fetched at deps level for the example app only.

**Missing dependencies with fallback:** None.

## Phase Requirements

| ID | Description (from REQUIREMENTS.md) | Research Support |
|----|-------------------------------------|------------------|
| SIGRA-01 | Adapter module ships with `actor_ref_from_conn/1`, `audit_context_overrides_from_conn/1`, `actor_fn/0`; `Code.ensure_loaded?(Sigra.Session)` guard; library `mix.exs` adds nothing; test doubles via `elixirc_paths(:test)`; three-conn-shape baseline returns deterministic results | §Sigra Public Surface, §Threadline.Plug Contract, §Test-Double Loader, §Architecture Patterns/Pattern 1 |
| SIGRA-02 | Example app's `audit_actor.ex` delegates to adapter; `examples/threadline_phoenix/mix.exs` adds `{:sigra, "~> 0.2", optional: true}`; example router wires `actor_fn:`; existing example tests stay green | §Example App Insertion Points, §Landmines/§3 (Phase 23 test edit needed) |
| SIGRA-03 | `guides/integrations/sigra.md` ships five sections; `test/threadline/integrations/sigra_doc_contract_test.exs` locks install snippet, Plug-callback line, six SPEC outcomes, four correlation_id formats, soft-dep contract mention | §Doc-Contract Test Idiom, §ExDoc Extras Wiring, §Validation Architecture |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The library's existing test suite (`mix verify.test`) does not currently load `Sigra.Session` from any source. | Test-Double Loader | LOW — verifiable by `grep -r 'Sigra' lib/ test/` returning empty before Phase 44 starts. If wrong, test doubles might silently no-op. |
| A2 | The example app's CI (`mix verify.example`) tolerates `optional: true` deps that are not actually fetched offline. | Environment Availability | LOW — Mix handles `optional: true` deps as "fetch if available, skip otherwise." If a CI env blocks Hex access, deps.get fails before tests run; this is a CI-environment concern, not a Phase 44 design concern. |
| A3 | `audit_actions.actor_ref` (the Ecto column) accepts JSONB null when the actor_fn returns nil. | ActorRef Contracts | LOW — already true in v0.2.0; the existing example test exercises this when an unauthenticated request hits `Threadline.Plug` with a nil-returning actor_fn. The Phase 23 stub never returns nil, but `extract_actor/2` (`plug.ex:77`) does. |
| A4 | Phase 48's `release_artifact_contract_test.exs` will catch any Phase 44 drift in `mix.exs :files` glob coverage of `guides/integrations/sigra.md`. | ExDoc Extras Wiring | LOW — Phase 48 is the cutover; any Phase 44 oversight (e.g., a non-`.md` companion file under `guides/integrations/`) fails the future test. Phase 44 only needs to not block Phase 48. |
| A5 | The `Sigra.APIToken` shim is harmless to ship even though no real `%Sigra.APIToken{}` struct exists in v0.2.5. | Test-Double Loader, Sigra Public Surface | LOW — if no test or adapter pattern-matches `%Sigra.APIToken{}`, the shim is dead code in the doubles file. CONTEXT D-02 already mandates shipping it; this is a stylistic/defensive choice, not a correctness one. |

## Open Questions

1. **How should the adapter detect API-token shape in v0.2.5 — given there's no `current_api_token` assign?**
   - What we know: `Sigra.Plug.FetchBearer` builds `current_scope` with `auth_method: :api_token` and `token_id: <id>` packed in. The user_id is at `current_scope.id` (NOT `current_scope.user.id`).
   - What's unclear: SPEC requirement 4 line 41 example (`conn.assigns.current_api_token` is a `%Sigra.APIToken{user_id: <id>}`) is wrong relative to v0.2.5 reality.
   - Recommendation: Planner uses `Map.get(scope, :auth_method) in [:api_token, :jwt]` as the detection signal and `Map.get(scope, :id)` as the user_id source. The `<token_id>` for `correlation_id` (`sigra-token:<token_id>`) comes from `Map.get(scope, :token_id)`. Flag as a SPEC clarification (NOT relitigation — semantics unchanged) for the planner to surface in their plan-checker note.

2. **Should the existing Phase 23 test (`posts_audit_path_test.exs:35-39`) be updated as part of SIGRA-02 or noted as a separate fix?**
   - What we know: The test pins `type: :service_account, id: "threadline-phoenix-example"` from the Phase 23 stub. Post-Phase 44, an unauthenticated test conn yields `actor_ref = nil`.
   - What's unclear: SPEC requirement 8 line 65 says "existing example test suite (HTTP audited path, Oban audited path, correlation path, incident JSON path) continues to pass without modification." This is incorrect — at minimum this one test needs to change.
   - Recommendation: Plan a task under SIGRA-02 to update `posts_audit_path_test.exs` to either (a) build a `current_scope`-bearing test conn that yields a `:user` ActorRef, OR (b) assert `actor_ref == nil` to match the new anonymous baseline. Option (a) demonstrates the new wiring works end-to-end; option (b) is simpler. Either is valid; option (a) is recommended for documentation value.

3. **Does the adapter's `audit_context_overrides_from_conn/1` need to handle the case where `current_scope.id` exists but `current_scope.auth_method` is unset?**
   - What we know: A custom host plug might assign `current_scope = %{id: "u1"}` (no auth_method) for some legacy path.
   - What's unclear: Should the adapter treat this as user-shape (returning `:user` ActorRef and `sigra-session:` correlation_id with no session_id available) or as "unknown shape" (returning nil)?
   - Recommendation: Treat as anonymous (return nil). The adapter's contract is "Sigra-aware shapes only." Hosts with custom shapes should write their own actor_fn or layer atop the adapter. Document this in the guide's "Edge cases" subsection.

## Landmines / Open Questions (planner awareness)

These are findings the planner should flag as plan-checker review items — NOT for re-litigation, just for plan-text accuracy.

### Landmine 1: SPEC's `current_api_token` reference is incorrect for v0.2.5

**Where:** SPEC line 41 (Requirement 4 Target sentence: "Token-shape conn (e.g. `conn.assigns.current_api_token` is a `%Sigra.APIToken{user_id: <id>}`)"). CONTEXT D-08 also says "`current_api_token` non-nil (no session) → `:service_account`."

**Reality (v0.2.5):** No such assign exists. `Sigra.Plug.FetchBearer` writes `current_scope` with `auth_method: :api_token`, `token_id: <id>`. The user_id is at `current_scope.id` (literally the key `:id`, not nested under `:user`).

**Impact:** Plans must encode the actual detection signal: `Map.get(scope, :auth_method) in [:api_token, :jwt]` AND `Map.get(scope, :id)` for user_id. Plans must NOT specify `conn.assigns[:current_api_token]`. Plans should add a one-line note in the integration guide warning hosts that their custom token plugs should follow Sigra's convention.

**Why this isn't a re-litigation:** The Q5 outcome is unchanged (`:service_account` actor with the user_id from the token). Only the *Elixir-level access pattern* differs from what SPEC's example sentence says. Plan-checker should accept this as a textual correction.

### Landmine 2: SPEC's `Sigra.Audit.scope_fields/1` and `Sigra.Impersonation.actor_id/1` references are private

**Where:** SPEC line 17 (Background) cites these as `Sigra.Audit.scope_fields/1` and `Sigra.Impersonation.actor_id/1` as if they were public.

**Reality (v0.2.5):** Both are `defp` (private). Adapter cannot delegate.

**Impact:** None on behavior — the adapter mirrors the logic via `Map.get/3` (CONTEXT D-09). Plans should NOT include any task that calls these functions.

**Why this isn't a re-litigation:** SPEC was descriptive of Sigra's internal pattern, not prescriptive of an API contract. The scope-first detection order with `Map.get/3` is unchanged.

### Landmine 3: Existing example test pins the Phase 23 stub's actor

**Where:** `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs:35-39`.

**Reality:** The test asserts `type: :service_account, id: "threadline-phoenix-example"`. After Phase 44, the test conn (no Sigra session) yields `actor_ref = nil`.

**Impact:** SPEC requirement 8 acceptance line 65 is wrong as written. Plans must include a task to update this test (recommended: build a Sigra-shape test conn and assert `:user`, demonstrating the new wiring).

**Why this isn't a re-litigation:** The locked behaviors (anonymous → nil, user → :user) are unchanged. Only the test's expectation of the OLD stub's static actor is wrong relative to the NEW adapter's anonymous behavior.

### Landmine 4: `Sigra.APIToken` has no struct in v0.2.5; the shim is defensive

**Where:** CONTEXT D-02 mandates shipping a `Sigra.APIToken` defstruct shim with `:user_id, :id`.

**Reality:** `Sigra.APIToken` v0.2.5 has zero `defstruct` lines — it's an operations module.

**Impact:** Shipping the shim is harmless (and consistent with CONTEXT). When real Sigra is loaded, `Code.ensure_loaded?(Sigra.Session)` is true and the shim block evaporates, so the shim's `Sigra.APIToken` struct never collides with reality. The adapter must NOT pattern-match on `%Sigra.APIToken{}` — but it shouldn't anyway, given the token detection runs through `current_scope`.

**Why this isn't a re-litigation:** CONTEXT D-02 stands; the shim is just unused-but-harmless.

### Landmine 5: `mix verify.doc_contract` alias does not auto-discover new doc-contract tests

**Where:** `mix.exs:66` — `"verify.doc_contract": ["test test/threadline/readme_doc_contract_test.exs"]`. Hard-codes the README test only.

**Reality:** Other doc-contract tests (`stg_`, `audit_indexing_`, `exploration_routing_`, `support_playbook_`) are NOT in this alias today; they run only via `verify.test`. So the existing convention is "doc-contract tests run as part of `verify.test`, not via the explicit alias."

**Impact:** None on Phase 44's correctness. Plan-checker note: do NOT extend `verify.doc_contract` to include the new sigra doc-contract test unless the planner has a specific reason. Following the existing convention (let `verify.test` cover it) is consistent.

**Why this isn't a re-litigation:** SPEC and CONTEXT don't take a position on this. It's a code-level detail.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoded synthetic `:service_account` actor (Phase 23 stub) | Sigra-aware four-shape adapter via `Code.ensure_loaded?` | Phase 44 (this) | Audit rows distinguish admin/user/service_account/anonymous; correlation_id encodes session+impersonation+org context |
| Pattern-match `%Sigra.Scope{}` (hypothetical naive approach) | `Map.get/3` on the host's scope struct | Adopted upstream by Sigra in v0.2.x | Allows host-named scope structs (`MyApp.Auth.Scope`) without per-host adapter |
| Mox-based behaviour mocks for soft-dep tests | `defstruct` shims under `unless Code.ensure_loaded?` | CONTEXT D-01 (this phase) | Fewer moving parts; struct-field reads don't need behaviour contracts |

**Deprecated/outdated:**
- The Phase 23 stub (`audit_actor.ex` returning a static service_account) — explicitly replaced by SIGRA-02.

## Sources

### Primary (HIGH confidence)
- `lib/threadline/plug.ex:1-94` — `:actor_fn` callback contract
- `lib/threadline/semantics/actor_ref.ex:1-130` — closed-type and validation rules
- `lib/threadline/semantics/audit_context.ex:1-19` — 4-field struct, byte-identical preservation requirement
- `mix.exs:1-163` — library deps, `elixirc_paths(:test)`, ExDoc extras configuration
- `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex:1-15` — Phase 23 stub
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:1-16` — current pipeline wiring
- `examples/threadline_phoenix/mix.exs:1-71` — example deps (no `:sigra` today)
- `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs:1-41` — pinned stub assertion (Landmines §3)
- `test/test_helper.exs:1-40` — ExUnit setup; no `:sigra` references
- `test/support/data_case.ex`, `test/support/repo.ex` — `elixirc_paths(:test)` template
- `test/threadline/stg_doc_contract_test.exs:1-27` — canonical doc-contract pattern
- `test/threadline/audit_indexing_doc_contract_test.exs:1-37` — doc-contract pattern with multiple assertion blocks
- `test/threadline/readme_doc_contract_test.exs:1-97` — DataCase-using doc-contract (NOT to copy for Phase 44)
- `.planning/phases/44-sigra-integration-adapter/44-SPEC.md` — 9 locked requirements
- `.planning/phases/44-sigra-integration-adapter/44-CONTEXT.md` — 14 implementation decisions

### Secondary (HIGH confidence — verified via raw GitHub source)
- `https://github.com/sztheory/sigra/blob/v0.2.5/lib/sigra/session.ex` — `Sigra.Session` defstruct (16 fields)
- `https://github.com/sztheory/sigra/blob/v0.2.5/lib/sigra/scope.ex` — `Sigra.Scope.build/3` constructor (no struct in library)
- `https://github.com/sztheory/sigra/blob/v0.2.5/lib/sigra/api_token.ex` — operations module (no struct)
- `https://github.com/sztheory/sigra/blob/v0.2.5/lib/sigra/plug/fetch_bearer.ex` — token-path scope build pattern
- `https://github.com/sztheory/sigra/blob/v0.2.5/lib/sigra/plug/forbid_during_impersonation.ex` — `impersonating?` shape detection
- `https://github.com/sztheory/sigra/blob/v0.2.5/lib/sigra/audit.ex` — `defp scope_fields/1` (private), `[:sigra, :audit, :log]` telemetry event
- `https://github.com/sztheory/sigra/blob/v0.2.5/lib/sigra/impersonation.ex` — `defp actor_id/1` (private)

### Hex registry (HIGH confidence)
- `https://hex.pm/api/packages/sigra` — release list; v0.2.5 latest 0.2.x (published 2026-04-25)
- `https://hex.pm/api/packages/sigra/releases/0.2.5` — version metadata, dependency closure

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `:plug`, `:ex_doc`, `:sigra` versions all verified; no new library deps.
- Architecture: HIGH — soft-dep + pre-plug header injection are well-established Elixir/Phoenix patterns; codebase has clear precedent for `elixirc_paths(:test)` and doc-contract tests.
- Sigra public surface: HIGH for `Sigra.Session` (verified against raw source), MEDIUM-flagged-for-planner for `Sigra.APIToken`/`Sigra.Scope` (different shape than SPEC implies, but the adapter's actual access pattern via `Map.get/3` is correct — SPEC text is descriptive-imprecise, not prescriptively-wrong).
- Threadline.Plug contract: HIGH — file is 94 lines, fully read, no surprises.
- Pitfalls: HIGH — landmines §1, §3 are concrete and fixable in plan text.
- Validation architecture: HIGH — fixture matrix is fully enumerable; existing test infrastructure (PG, ExUnit, `verify.example`) covers all requirements.

**Research date:** 2026-05-01
**Valid until:** 2026-06-01 for Sigra v0.2.x surface (active development; minor versions arrive every few days). Threadline-side claims valid indefinitely until codebase changes.

## RESEARCH COMPLETE

Phase 44 is heavily pre-decided: 9 locked requirements (SPEC), 14 locked implementation decisions (CONTEXT), six SEED-001 questions answered. This research's load-bearing contributions are (1) verifying Sigra v0.2.5's actual public surface against the SPEC's referenced API, surfacing three substantive textual corrections the planner should bake into plan text without re-opening locked semantics: `current_api_token` doesn't exist (Landmines §1), `Sigra.Audit.scope_fields/1` and `Sigra.Impersonation.actor_id/1` are private (Landmines §2), and `Sigra.APIToken` has no struct (Landmines §4); (2) flagging that the existing Phase 23 example test pins the OLD stub's actor and will break unless updated as part of SIGRA-02 (Landmines §3, contradicting SPEC's "without modification" wording); and (3) producing the validation architecture (4 conn shapes × 2 environments × header/org axes ≈ 18 unit tests + 3 negative paths) the planner can translate directly into Wave 0 file scaffolding for `test/threadline/integrations/sigra_test.exs` and `test/threadline/integrations/sigra_doc_contract_test.exs`. Planner has everything needed to author a single concrete plan (or two — adapter + example/guide) under coarse granularity.
