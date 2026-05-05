# Phase 49: native-plug-context-overrides - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 9
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/plug.ex` | middleware | request-response | `lib/threadline/plug.ex` | exact |
| `lib/threadline/integrations/sigra.ex` | service | request-response | `lib/threadline/integrations/sigra.ex` | exact |
| `test/threadline/plug_test.exs` | test | request-response | `test/threadline/plug_test.exs` | exact |
| `test/threadline/integrations/sigra_test.exs` | test | request-response | `test/threadline/integrations/sigra_test.exs` | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | route | request-response | `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | exact |
| `guides/integrations/sigra.md` | config | request-response | `guides/integrations/sigra.md` | exact |
| `test/threadline/integrations/sigra_doc_contract_test.exs` | test | transform | `test/threadline/integrations/sigra_doc_contract_test.exs` | exact |
| `guides/getting-started-saas.md` | config | request-response | `guides/getting-started-saas.md` | role-match |
| `examples/threadline_phoenix/README.md` | config | request-response | `examples/threadline_phoenix/README.md` | role-match |

## Pattern Assignments

### `lib/threadline/plug.ex` (middleware, request-response)

**Analog:** `lib/threadline/plug.ex`

**Imports / aliases pattern** (`lib/threadline/plug.ex:60-66`):
```elixir
@behaviour Plug

import Plug.Conn, only: [get_req_header: 2, assign: 3]

alias Threadline.Semantics.AuditContext

@allowed_override_keys [:actor_ref, :request_id, :correlation_id, :remote_ip]
```

**Init + baseline context pattern** (`lib/threadline/plug.ex:68-87`):
```elixir
@impl Plug
def init(opts) do
  %{
    actor_fn: Keyword.get(opts, :actor_fn),
    context_overrides_fn: Keyword.get(opts, :context_overrides_fn)
  }
end

@impl Plug
def call(conn, %{actor_fn: actor_fn, context_overrides_fn: context_overrides_fn}) do
  context =
    %AuditContext{
      actor_ref: extract_actor(conn, actor_fn),
      request_id: extract_request_id(conn),
      correlation_id: get_req_header(conn, "x-correlation-id") |> List.first(),
      remote_ip: format_ip(conn.remote_ip)
    }
    |> apply_context_overrides(conn, context_overrides_fn)

  assign(conn, :audit_context, context)
end
```

**Extraction helper pattern** (`lib/threadline/plug.ex:90-106`):
```elixir
defp extract_actor(_conn, nil), do: nil
defp extract_actor(conn, fun) when is_function(fun, 1), do: fun.(conn)

defp extract_request_id(conn) do
  case get_req_header(conn, "x-request-id") do
    [id | _] -> id
    [] -> conn.assigns[:request_id]
  end
end
```

**Override validation / reduce pattern** (`lib/threadline/plug.ex:108-137`):
```elixir
defp apply_context_overrides(context, _conn, nil), do: context

defp apply_context_overrides(context, conn, fun) when is_function(fun, 1) do
  overrides = fun.(conn)
  validate_context_overrides!(overrides)

  Enum.reduce(overrides, context, fn
    {_key, nil}, acc ->
      acc

    {key, value}, acc ->
      Map.put(acc, key, value)
  end)
end

defp validate_context_overrides!(overrides) when is_map(overrides) do
  case Map.keys(overrides) -- @allowed_override_keys do
    [] -> :ok
    unknown_keys ->
      raise ArgumentError,
            "unknown audit context override keys: #{inspect(unknown_keys)}; expected a subset of #{inspect(@allowed_override_keys)}"
  end
end
```

**What to copy forward:** keep the `init/1` shape, baseline-first `%AuditContext{}` construction, helper extraction functions, and immediate `ArgumentError` validation at the plug boundary. Phase 49 should tighten the allowlist and merge semantics inside this existing structure, not introduce a second pre-plug or alternate callback path.

---

### `lib/threadline/integrations/sigra.ex` (service, request-response)

**Analog:** `lib/threadline/integrations/sigra.ex`

**Alias + type pattern** (`lib/threadline/integrations/sigra.ex:10-18`):
```elixir
alias Threadline.Semantics.ActorRef

@type audit_overrides :: %{optional(:correlation_id) => String.t()}

@spec actor_ref_from_conn(Plug.Conn.t()) :: ActorRef.t() | nil
```

**Soft-dependency gate pattern** (`lib/threadline/integrations/sigra.ex:19-39`):
```elixir
def actor_ref_from_conn(conn) do
  if sigra_available?() do
    conn
    |> current_scope()
    |> actor_ref_from_scope()
  else
    nil
  end
end

def audit_context_overrides_from_conn(conn) do
  if header_correlation_id?(conn) do
    %{}
  else
    build_audit_overrides(conn)
  end
end
```

**Header-wins adapter pattern** (`lib/threadline/integrations/sigra.ex:41-65`):
```elixir
defp build_audit_overrides(conn) do
  if sigra_available?() do
    scope = current_scope(conn)
    sigra_session = sigra_session(conn)

    case build_correlation_id(scope, sigra_session) do
      nil -> %{}
      correlation_id -> %{correlation_id: correlation_id}
    end
  else
    %{}
  end
end

defp header_correlation_id?(conn) do
  conn
  |> Plug.Conn.get_req_header("x-correlation-id")
  |> Enum.any?()
end
```

**Adapter callback export pattern** (`lib/threadline/integrations/sigra.ex:55-59`):
```elixir
@doc """
Returns the adapter callback in a form suitable for `Threadline.Plug`.
"""
@spec actor_fn() :: (Plug.Conn.t() -> ActorRef.t() | nil)
def actor_fn, do: &actor_ref_from_conn/1
```

**What to copy forward:** preserve the soft-dependency boundary and `%{}`-when-header-present behavior. If `sigra.ex` changes in this phase, it should stay a thin adapter that derives additive metadata and never owns actor replacement or transport normalization.

---

### `test/threadline/plug_test.exs` (test, request-response)

**Analog:** `test/threadline/plug_test.exs`

**Test module setup pattern** (`test/threadline/plug_test.exs:1-12`):
```elixir
use ExUnit.Case, async: true

import Plug.Test
import Plug.Conn

alias Threadline.Plug, as: ThreadlinePlug
alias Threadline.Semantics.{ActorRef, AuditContext}

defp call(conn, opts \\ []) do
  ThreadlinePlug.call(conn, ThreadlinePlug.init(opts))
end
```

**Boundary-behavior test pattern** (`test/threadline/plug_test.exs:14-58`):
```elixir
test "assigns an AuditContext to conn" do
  conn = conn(:get, "/") |> call()
  assert %AuditContext{} = conn.assigns[:audit_context]
end

test "actor_fn: option sets actor_ref from the function result" do
  {:ok, ref} = ActorRef.new(:user, "u-1")

  conn =
    conn(:get, "/")
    |> call(actor_fn: fn _conn -> ref end)

  assert conn.assigns[:audit_context].actor_ref == ref
end
```

**Override-contract test pattern** (`test/threadline/plug_test.exs:60-123`):
```elixir
test "context_overrides_fn: non-nil values override the derived context" do
  conn =
    conn(:get, "/")
    |> put_req_header("x-request-id", "req-abc")
    |> put_req_header("x-correlation-id", "corr-xyz")
    |> call(context_overrides_fn: fn _conn -> %{request_id: "override-req"} end)

  assert conn.assigns[:audit_context].request_id == "override-req"
end

test "context_overrides_fn: unknown keys raise" do
  assert_raise ArgumentError, ~r/unknown audit context override keys/, fn ->
    conn(:get, "/")
    |> call(context_overrides_fn: fn _conn -> %{tenant_id: "org-1"} end)
  end
end
```

**Remote-IP helper assertions** (`test/threadline/plug_test.exs:125-138`):
```elixir
test "remote_ip from Erlang tuple is formatted as dotted-decimal string" do
  conn = %{conn(:get, "/") | remote_ip: {127, 0, 0, 1}} |> call()
  assert conn.assigns[:audit_context].remote_ip == "127.0.0.1"
end
```

**What to copy forward:** keep the one-file unit-test style with `Plug.Test`, local `call/2`, and targeted `assert_raise` coverage. Phase 49 tests should rewrite the current broad override expectations into nil-only supplement tests for `:request_id` and `:correlation_id`, while retaining the same test structure.

---

### `test/threadline/integrations/sigra_test.exs` (test, request-response)

**Analog:** `test/threadline/integrations/sigra_test.exs`

**Shared test setup pattern** (`test/threadline/integrations/sigra_test.exs:1-9`):
```elixir
use ExUnit.Case, async: true

import Plug.Conn
import Plug.Test

alias Threadline.Integrations.Sigra, as: SigraAdapter
alias Threadline.Semantics.{ActorRef, AuditContext}
```

**Behavior-grouping pattern** (`test/threadline/integrations/sigra_test.exs:36-80`, `82-174`, `176-240`):
```elixir
describe "actor_ref_from_conn/1" do
  ...
end

describe "audit_context_overrides_from_conn/1" do
  ...
end

describe "Threadline.Plug integration" do
  ...
end
```

**Canonical header-wins assertions** (`test/threadline/integrations/sigra_test.exs:127-135`, `224-239`):
```elixir
test "returns empty overrides when x-correlation-id header is already present" do
  ...
  assert %{} = SigraAdapter.audit_context_overrides_from_conn(conn)
end

test "explicit x-correlation-id header still wins when using Threadline.Plug" do
  ...
  assert %AuditContext{correlation_id: "explicit-cid"} = conn.assigns.audit_context
end
```

**Conn-builder helper pattern** (`test/threadline/integrations/sigra_test.exs:242-264`):
```elixir
defp build_sigra_conn(opts) do
  scope = Keyword.get(opts, :scope)
  headers = Keyword.get(opts, :headers, [])
  sigra_session = Keyword.get(opts, :sigra_session)

  conn =
    Enum.reduce(headers, conn(:get, "/"), fn {key, value}, acc ->
      put_req_header(acc, key, value)
    end)
```

**What to copy forward:** keep the adapter tests split into pure-adapter and plug-composition sections, and extend the composition section rather than inventing a second integration fixture. This is the right place to lock "Sigra returns `%{}` when transport already supplied correlation" and "native plug callback composes directly."

---

### `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (route, request-response)

**Analog:** `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`

**Pipeline wiring pattern** (`examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:4-13`):
```elixir
pipeline :api do
  # doc: start: router-pipeline-actor-fn
  plug(:accepts, ["json"])

  plug(Threadline.Plug,
    actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
    context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
  )

  # doc: end: router-pipeline-actor-fn
end
```

**What to copy forward:** preserve direct router-level callback wiring and the doc snippet markers. If the planner touches example wiring in Phase 49, it should reuse this exact pipeline shape rather than introducing a wrapper plug.

---

### `guides/integrations/sigra.md` (adopter doc, request-response)

**Analog:** `guides/integrations/sigra.md`

**Guide structure pattern** (`guides/integrations/sigra.md:1-17`):
```md
# Threadline ↔ Sigra integration

<!-- SIGRA-03-INTEGRATION-GUIDE -->

## Install
...
## Plug callback wire-up
```

**Wire-up excerpt pattern** (`guides/integrations/sigra.md:17-29`):
```elixir
pipeline :api do
  plug :accepts, ["json"]
  plug Threadline.Plug,
    actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
    context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
end
```

**Behavior-list pattern** (`guides/integrations/sigra.md:31-54`):
```md
5. `x-correlation-id` header always wins. When the header is present, `audit_context_overrides_from_conn/1` returns `%{}` so `Threadline.Plug` preserves the request value.
...
- `audit_context_overrides_from_conn/1` returns `%{}`
```

**What to copy forward:** if docs land in Phase 49, follow the existing "small explicit guide + locked literals" shape. Keep the messaging narrow: actor identity via `actor_fn`, additive correlation via `context_overrides_fn`, header precedence explicit.

---

### `test/threadline/integrations/sigra_doc_contract_test.exs` (test, transform)

**Analog:** `test/threadline/integrations/sigra_doc_contract_test.exs`

**Doc contract helper pattern** (`test/threadline/integrations/sigra_doc_contract_test.exs:5-9`):
```elixir
@repo_root File.cwd!()

defp read_rel!(segments) when is_list(segments) do
  @repo_root |> Path.join(Path.join(segments)) |> File.read!()
end
```

**Literal-lock assertion pattern** (`test/threadline/integrations/sigra_doc_contract_test.exs:39-83`):
```elixir
assert String.contains?(doc, "plug Threadline.Plug,")
assert String.contains?(doc, "actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1")
assert String.contains?(doc, "context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1")
assert String.contains?(doc, "`x-correlation-id` header always wins")
```

**What to copy forward:** if a guide changes in this phase, lock the new language with narrow `String.contains?/2` tests rather than looser prose-only review. This repo treats doc literals as part of the public contract.

---

### Optional adopter docs: `guides/getting-started-saas.md` and `examples/threadline_phoenix/README.md`

**Analogs:** `guides/getting-started-saas.md`, `examples/threadline_phoenix/README.md`

**Quickstart copy pattern** (`guides/getting-started-saas.md:49-65`):
```md
The Phoenix example keeps request capture small and explicit by wiring both
Sigra callbacks directly into `Threadline.Plug`:
...
If you do not use Sigra, keep the same shape: populate the conn with authenticated
request context first, then hand `Threadline.Plug` an `actor_fn` and any
request-derived context overrides you need.
```

**Example README framing pattern** (`examples/threadline_phoenix/README.md:87-100`):
```md
The example wires `Threadline.Plug` with both `actor_fn` and
`context_overrides_fn` on the `:api` pipeline ...

The actor callback now delegates to
`Threadline.Integrations.Sigra.actor_ref_from_conn/1`.
```

**Doc-snippet contract pattern** (`test/threadline/getting_started_saas_doc_contract_test.exs:14-37`, `63-75`):
```elixir
assert String.contains?(doc, router_block())

defp router_block do
  GettingStartedFixtures.extract!(
    "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex",
    "router-pipeline-actor-fn"
  )
end
```

**What to copy forward:** if the planner includes adopter docs in Phase 49, prefer reusing router snippet extraction and explicit wording around "direct callback wiring" instead of inventing a separate example.

## Shared Patterns

### Direct host wiring
**Sources:** `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:4-13`, `guides/integrations/sigra.md:17-29`

Apply to all example and guide updates:
```elixir
plug(Threadline.Plug,
  actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
  context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
)
```

### Baseline-first context derivation
**Source:** `lib/threadline/plug.ex:77-87`

Apply to `lib/threadline/plug.ex` changes:
```elixir
%AuditContext{
  actor_ref: extract_actor(conn, actor_fn),
  request_id: extract_request_id(conn),
  correlation_id: get_req_header(conn, "x-correlation-id") |> List.first(),
  remote_ip: format_ip(conn.remote_ip)
}
```

### Deterministic public-boundary validation
**Source:** `lib/threadline/plug.ex:123-136`

Apply to callback contract enforcement and matching tests:
```elixir
defp validate_context_overrides!(overrides) when is_map(overrides) do
  case Map.keys(overrides) -- @allowed_override_keys do
    [] -> :ok
    unknown_keys -> raise ArgumentError, ...
  end
end

defp validate_context_overrides!(other) do
  raise ArgumentError, "context_overrides_fn must return a map, got: #{inspect(other)}"
end
```

### Header-wins precedence
**Sources:** `lib/threadline/integrations/sigra.ex:33-39`, `test/threadline/integrations/sigra_test.exs:127-135,224-239`, `guides/integrations/sigra.md:37-38`

Apply to plug semantics, Sigra adapter behavior, and docs:
```elixir
if header_correlation_id?(conn) do
  %{}
else
  build_audit_overrides(conn)
end
```

### Doc-contract locking
**Sources:** `test/threadline/integrations/sigra_doc_contract_test.exs:39-83`, `test/threadline/getting_started_saas_doc_contract_test.exs:14-37`

Apply to any guide/README edits that ship in this phase:
```elixir
assert String.contains?(doc, "plug Threadline.Plug,")
assert String.contains?(doc, router_block())
```

## No Analog Found

None. Every likely Phase 49 touchpoint already has an in-repo analog, and the strongest matches are the current in-flight implementations plus their existing tests/docs.

## Metadata

**Analog search scope:** `lib/`, `test/`, `examples/`, `guides/`, `.planning/`
**Files scanned:** 12 primary files plus roadmap/requirements/context/research inputs
**Pattern extraction date:** 2026-05-05
