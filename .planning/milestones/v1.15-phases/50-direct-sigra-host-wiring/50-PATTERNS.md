# Phase 50: direct-sigra-host-wiring - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 8
**Analogs found:** 8 / 8
**Research artifact:** `50-RESEARCH.md` present in the phase directory.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | route | request-response | `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` | utility | request-response | `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` | exact-delete |
| `examples/threadline_phoenix/README.md` | config | request-response | `guides/integrations/sigra.md` + `examples/threadline_phoenix/README.md` | role-match |
| `guides/integrations/sigra.md` | config | request-response | `guides/integrations/sigra.md` | exact |
| `test/threadline/integrations/sigra_test.exs` | test | request-response | `test/threadline/integrations/sigra_test.exs` | exact |
| `test/threadline/integrations/sigra_doc_contract_test.exs` | test | request-response | `test/threadline/integrations/sigra_doc_contract_test.exs` | exact |
| `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs` | test | request-response | `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs` | exact |
| `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs` | test | request-response | `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs` | exact |

## Pattern Assignments

### `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (route, request-response)

**Analog:** `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`

**Direct Plug wiring pattern** ([router.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:4)):
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

**Route scope shape** ([router.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:16)):
```elixir
scope "/api", ThreadlinePhoenixWeb do
  pipe_through(:api)

  post "/posts", PostController, :create
  get "/audit_transactions/:id/changes", AuditTransactionController, :changes
end
```

**Use for Phase 50:** Keep the visible wiring point in the router pipeline. Do not introduce an example-local wrapper plug.

---

### `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` (utility, request-response)

**Analog:** `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex`

**Dead delegate pattern to remove** ([audit_actor.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex:1)):
```elixir
defmodule ThreadlinePhoenix.AuditActor do
  @moduledoc false

  defdelegate from_conn(conn), to: Threadline.Integrations.Sigra, as: :actor_ref_from_conn
end
```

**Use for Phase 50:** Treat this as a delete candidate, not a reusable seam. The phase context explicitly prefers one canonical name: `Threadline.Integrations.Sigra`.

---

### `guides/integrations/sigra.md` (config/docs, request-response)

**Analog:** `guides/integrations/sigra.md`

**Canonical wiring prose + literal block** ([sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:17)):
```elixir
pipeline :api do
  plug :accepts, ["json"]
  plug Threadline.Plug,
    actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1,
    context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1
end
```

**Contract wording to preserve** ([sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:31)):
- `` `actor_fn` decides who acted. `context_overrides_fn` can add only additive request metadata ``
- `` `Threadline.Plug` always derives `request_id` from `x-request-id` first ``
- `` `correlation_id` from `x-correlation-id` first ``
- `` `Threadline.Plug` raises `ArgumentError` immediately ``

**Behavior checklist pattern** ([sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md:43)):
- Enumerate exact supported semantics as numbered bullets.
- Keep impersonation, token, organization suffix, anonymous fallback, and header precedence explicit.
- Keep soft-dependency behavior in its own section.

**Use for Phase 50:** Update docs by replacing any example-local delegate language with the direct callback names above. Keep the guide as the authoritative place for broader Sigra semantics.

---

### `examples/threadline_phoenix/README.md` (config/docs, request-response)

**Analog:** `examples/threadline_phoenix/README.md`

**Example-app golden-path prose** ([README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:87)):
- The README anchors the `POST /api/posts` story first.
- It explains that `Threadline.Plug` is wired on the `:api` pipeline with both callbacks.
- It points to request-path tests as the proof surface.

**Current line to tighten** ([README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:100)):
```text
The actor callback now delegates to Threadline.Integrations.Sigra.actor_ref_from_conn/1.
```

**Use for Phase 50:** Rewrite this surface to say the example wires directly to `Threadline.Integrations.Sigra.actor_ref_from_conn/1` and `audit_context_overrides_from_conn/1`, not that it "delegates to" them. Pair the README wording with a root-side contract test so future docs drift fails fast.

---

### `test/threadline/integrations/sigra_test.exs` (test, request-response)

**Analog:** `test/threadline/integrations/sigra_test.exs`

**Adapter-shape matrix pattern** ([sigra_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_test.exs:36)):
```elixir
describe "actor_ref_from_conn/1" do
  test "returns a user actor for a user scope" do
    conn = build_sigra_conn(scope: %{user: %{id: "u-42"}})

    assert %ActorRef{type: :user, id: "u-42"} = SigraAdapter.actor_ref_from_conn(conn)
  end

  test "returns an admin actor for an impersonation scope" do
    conn =
      build_sigra_conn(
        scope: %{impersonating_from: %{id: "admin-7"}, user: %{id: "imp-user-1"}}
      )

    assert %ActorRef{type: :admin, id: "admin-7"} = SigraAdapter.actor_ref_from_conn(conn)
  end
end
```

**Threadline.Plug composition pattern** ([sigra_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_test.exs:196)):
```elixir
conn =
  build_sigra_conn(
    scope: %{user: %{id: "u-42"}},
    sigra_session: %Sigra.Session{
      id: "s-1",
      user_id: "u-42",
      active_organization_id: "org-9"
    },
    headers: [{"x-request-id", "req-1"}]
  )
  |> Threadline.Plug.call(
    Threadline.Plug.init(
      actor_fn: SigraAdapter.actor_fn(),
      context_overrides_fn: &SigraAdapter.audit_context_overrides_from_conn/1
    )
  )
```

**Authority split pattern** ([sigra_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_test.exs:241)):
```elixir
assert %AuditContext{
         actor_ref: ^expected_ref,
         correlation_id: "sigra-imp:s-1:user:imp-user-1"
       } = conn.assigns.audit_context
```

**Helper pattern for unit-level request shapes** ([sigra_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_test.exs:287)):
```elixir
defp build_sigra_conn(opts) do
  scope = Keyword.get(opts, :scope)
  headers = Keyword.get(opts, :headers, [])
  sigra_session = Keyword.get(opts, :sigra_session)

  conn =
    Enum.reduce(headers, conn(:get, "/"), fn {key, value}, acc ->
      put_req_header(acc, key, value)
    end)

  conn =
    if Keyword.has_key?(opts, :scope) do
      assign(conn, :current_scope, scope)
    else
      conn
    end

  if sigra_session do
    %{conn | private: Map.put(conn.private, :sigra_session, sigra_session)}
  else
    conn
  end
end
```

**Use for Phase 50:** Keep rich Sigra semantics here, not in the example app. Add direct-wiring contract coverage here first if new adapter semantics need protection.

---

### `test/threadline/integrations/sigra_doc_contract_test.exs` (test, request-response)

**Analog:** `test/threadline/integrations/sigra_doc_contract_test.exs`

**Doc loader pattern** ([sigra_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_doc_contract_test.exs:5)):
```elixir
@repo_root File.cwd!()

defp read_rel!(segments) when is_list(segments) do
  @repo_root |> Path.join(Path.join(segments)) |> File.read!()
end
```

**Marker + section-order guard pattern** ([sigra_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_doc_contract_test.exs:11)):
```elixir
assert String.contains?(doc, "<!-- SIGRA-03-INTEGRATION-GUIDE -->")
assert String.contains?(doc, "# Threadline ↔ Sigra integration")

for heading <- [
      "## Install",
      "## Plug callback wire-up",
      "## Behaviors locked by SPEC",
      "## correlation_id formats",
      "## Soft-dep contract"
    ] do
  assert String.contains?(doc, heading)
end
```

**Literal-lock pattern** ([sigra_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_doc_contract_test.exs:39)):
```elixir
assert String.contains?(doc, "plug Threadline.Plug,")
assert String.contains?(doc, "actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1")
assert String.contains?(
         doc,
         "context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1"
       )
```

**Use for Phase 50:** Extend this file when docs change. Lock the direct callback names and any wording that distinguishes actor authority from additive context overrides.

---

### `examples/threadline_phoenix/test/support/conn_case.ex` (test helper, request-response)

**Analog:** `examples/threadline_phoenix/test/support/conn_case.ex`

**Sigra request-state fixture pattern** ([conn_case.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/test/support/conn_case.ex:39)):
```elixir
def sigra_conn(conn, attrs \\ %{}) do
  user_id = Map.get(attrs, :user_id, "example-user-1")
  session_id = Map.get(attrs, :session_id, "sigra-session-1")
  org_id = Map.get(attrs, :active_organization_id)
  auth_method = Map.get(attrs, :auth_method)
  token_id = Map.get(attrs, :token_id)

  scope =
    %{
      user: %{id: user_id},
      active_organization_id: org_id
    }
    |> maybe_put(:auth_method, auth_method)
    |> maybe_put(:token_id, token_id)
    |> maybe_put(:id, Map.get(attrs, :scope_id))
    |> maybe_put(:impersonating_from, Map.get(attrs, :impersonating_from))

  session =
    %Sigra.Session{
      id: session_id,
      user_id: user_id,
      active_organization_id: org_id
    }

  conn
  |> Plug.Conn.assign(:current_scope, scope)
  |> then(&%{&1 | private: Map.put(&1.private, :sigra_session, session)})
end
```

**Use for Phase 50:** Reuse this helper for all request-path tests. It is the example app’s honest way to seed Sigra request state without coupling tests to external runtime auth.

---

### `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs` (test, request-response)

**Analog:** `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs`

**Real router-path request pattern** ([posts_audit_path_test.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs:9)):
```elixir
conn =
  build_conn()
  |> sigra_conn(%{user_id: "phase-44-user", session_id: "phase-44-session"})
  |> put_req_header("content-type", "application/json")
  |> put_req_header("x-request-id", "phase-23-req")
  |> put_req_header("x-correlation-id", "phase-23-corr")
  |> post(~p"/api/posts", Jason.encode!(%{post: %{title: "HTTP audit", slug: slug}}))
```

**Persistence assertion pattern** ([posts_audit_path_test.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs:26)):
```elixir
rows =
  Repo.all(
    from(ac in AuditChange,
      join: at in assoc(ac, :transaction),
      where: ac.table_name == "posts" and fragment("?->>'id' = ?", ac.table_pk, ^to_string(post.id)),
      select: {ac, at}
    )
  )
```

**Use for Phase 50:** Keep one golden-path test that proves actor extraction through the real request pipeline. Do not inflate this file into an auth-matrix test.

---

### `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs` (test, request-response)

**Analog:** `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs`

**Current header-driven correlation proof** ([posts_correlation_path_test.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs:6)):
```elixir
conn =
  build_conn()
  |> sigra_conn(%{user_id: "corr-user-1", session_id: "corr-session-1"})
  |> put_req_header("content-type", "application/json")
  |> put_req_header("x-request-id", "loop-03-req")
  |> put_req_header("x-correlation-id", corr)
  |> post(~p"/api/posts", Jason.encode!(%{post: %{title: "Correlation path", slug: slug}}))
```

**Timeline query assertion pattern** ([posts_correlation_path_test.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs:21)):
```elixir
filters = [
  table: "posts",
  correlation_id: corr,
  repo: Repo
]

assert :ok = Threadline.Query.validate_timeline_filters!(filters)

rows = Threadline.timeline(filters, [])

assert Enum.any?(rows, fn ac ->
         ac.table_name == "posts" and ac.op == "insert" and
           match?(%{"slug" => ^slug}, ac.data_after)
       end)
```

**Use for Phase 50:** Add the no-header fallback proof here, not in a separate library-only test. Copy this request structure, omit `x-correlation-id`, derive the expected `sigra-session:<session_id>` or `sigra-session:<session_id>:org:<org_id>` value, then assert timeline rows through the real router path.

## Shared Patterns

### Native `Threadline.Plug` callback contract

**Source:** [plug.ex](/Users/jon/projects/threadline/lib/threadline/plug.ex:77)
**Apply to:** Router wiring, Sigra adapter composition tests, guide prose

```elixir
def init(opts) do
  %{
    actor_fn: Keyword.get(opts, :actor_fn),
    context_overrides_fn: Keyword.get(opts, :context_overrides_fn)
  }
end

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

**Important lines:** `extract_request_id/1` at line 101, additive-only override merge at lines 116-137, strict override validation at lines 139-152.

### Sigra adapter strictness split

**Source:** [sigra.ex](/Users/jon/projects/threadline/lib/threadline/integrations/sigra.ex:18)
**Apply to:** Router docs, adapter tests, fallback-path integration tests

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

**Important lines:** `sigra_available?/0` soft-dep gate at line 67, `actor_fn/0` convenience callback at line 59, correlation builder families at lines 99-184.

### Doc-contract style

**Source:** [sigra_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_doc_contract_test.exs:11)
**Apply to:** Any Phase 50 doc edits in `guides/integrations/sigra.md` and the example README, including the paired README contract test that locks the direct callback wording

- Read docs from repo-relative paths with `read_rel!/1`.
- Lock a stable marker and section order first.
- Lock the exact direct-wiring literals separately from broader semantics text.
- Keep soft-dependency assertions in the same contract file so docs and library posture cannot drift apart.

### Phoenix request-path test style

**Source:** [posts_audit_path_test.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs:9), [posts_correlation_path_test.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs:6), [conn_case.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/test/support/conn_case.ex:39)
**Apply to:** The new fallback-path proof for Phase 50

- Build a real conn with `build_conn()`.
- Seed Sigra request state with `sigra_conn/2`.
- Set only the headers under test.
- Hit the real route with `post(~p"/api/posts", ...)`.
- Assert queryability through Threadline public APIs, not internal assigns.

## Likely Change Clusters

### Cluster 1: Direct wiring convergence

**Files:** `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`, `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex`, `examples/threadline_phoenix/README.md`

- Keep the router as the single visible host-wiring point.
- Remove the dead `AuditActor` delegate if nothing host-owned remains there.
- Replace README wording that implies an app-local seam.

### Cluster 2: Sigra contract and doc alignment

**Files:** `guides/integrations/sigra.md`, `test/threadline/integrations/sigra_doc_contract_test.exs`, optionally `test/threadline/integrations/sigra_test.exs`

- Keep the guide as the authoritative surface for impersonation, token, and soft-dependency semantics.
- Lock the direct callback literals and additive-only contract language in the doc-contract test.
- If wording changes expose a semantic gap, add the corresponding unit-level adapter test before widening example-app coverage.

### Cluster 3: Real-path fallback proof

**Files:** `examples/threadline_phoenix/test/threadline_phoenix_web/posts_correlation_path_test.exs`, optionally `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs`

- Add one integration test that omits `x-correlation-id` and proves the router-driven Sigra fallback correlation value.
- Keep the broader matrix in `sigra_test.exs`; do not expand the example app into impersonation or token variants.

## No Analog Found

None. The repository already contains exact analogs for router wiring, adapter composition, doc-contract locking, and request-path integration tests.

## Metadata

**Analog search scope:** `lib/threadline`, `guides/integrations`, `examples/threadline_phoenix/lib`, `examples/threadline_phoenix/test`, `test/threadline`
**Project instructions loaded:** `CLAUDE.md`
**Project-local skills:** none under `.claude/skills` or `.agents/skills`
**Pattern extraction date:** 2026-05-05
