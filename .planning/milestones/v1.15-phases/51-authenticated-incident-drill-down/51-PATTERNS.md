# Phase 51: authenticated-incident-drill-down - Pattern Map

**Mapped:** 2026-05-05
**Files analyzed:** 10
**Analogs found:** 10 / 10

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` | controller | request-response | `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` | exact |
| `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` | test | request-response | `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` | exact |
| `examples/threadline_phoenix/test/support/conn_case.ex` | test | request-response | `examples/threadline_phoenix/test/support/conn_case.ex` | exact |
| `examples/threadline_phoenix/README.md` | docs | request-response | `examples/threadline_phoenix/README.md` | exact |
| `guides/domain-reference.md` | docs | request-response | `guides/domain-reference.md` | exact |
| `guides/incident-playbook.md` | docs | request-response | `guides/incident-playbook.md` | exact |
| `guides/getting-started-saas.md` | docs | request-response | `guides/getting-started-saas.md` | exact |
| `guides/adoption-pilot-backlog.md` | docs | request-response | `guides/adoption-pilot-backlog.md` | exact |
| `test/threadline/example_phoenix_readme_contract_test.exs` | test | request-response | `test/threadline/example_phoenix_readme_contract_test.exs` | role-match |
| `test/threadline/exploration_routing_doc_contract_test.exs` or `test/threadline/incident_playbook_doc_contract_test.exs` | test | request-response | `test/threadline/exploration_routing_doc_contract_test.exs` + `test/threadline/incident_playbook_doc_contract_test.exs` | role-match |

## Pattern Assignments

### `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` (controller, request-response)

**Analog:** [audit_transaction_controller.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex:1)

**Endpoint-local guard pattern** (lines 15-21):
```elixir
def changes(conn, %{"id" => id}) do
  case authenticated_actor(conn) do
    nil ->
      conn
      |> put_status(:unauthorized)
      |> json(%{errors: %{detail: "authentication required for incident drill-down"}})
```

**Why this is the Phase 51 analog:** keep the guard in the controller action. Do not move this into a new plug or router pipeline for a single protected endpoint.

**Normalized auth predicate pattern** (lines 46-53):
```elixir
defp authenticated_actor(conn) do
  conn.assigns
  |> Map.get(:audit_context)
  |> case do
    %{actor_ref: actor_ref} -> actor_ref
    _ -> nil
  end
end
```

**Success payload + bad UUID handling** (lines 23-41):
```elixir
case Ecto.UUID.cast(id) do
  :error ->
    conn
    |> put_status(:bad_request)
    |> json(%{errors: %{detail: "invalid audit transaction id"}})

  {:ok, uuid} ->
    changes = Threadline.audit_changes_for_transaction(uuid, repo: Repo)

    json(conn, %{
      audit_transaction_id: uuid,
      changes:
        Enum.map(changes, fn ac ->
          %{
            audit_change_id: to_string(ac.id),
            change_diff: Threadline.change_diff(ac, [])
          }
        end)
    })
end
```

**Planner note:** mirror this exact split in the plan: `401` for missing actor, `400` for malformed UUID, unchanged `200` body for authenticated success.

---

### `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` (test, request-response)

**Analog:** [posts_incident_json_path_test.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs:1)

**Authenticated success path** (lines 6-39):
```elixir
conn =
  build_conn()
  |> sigra_conn(%{user_id: "incident-user-1", session_id: "incident-session-1"})
  |> put_req_header("content-type", "application/json")
  |> put_req_header("x-request-id", "comp-req")
  |> put_req_header("x-correlation-id", "comp-corr")
  |> post(~p"/api/posts", Jason.encode!(%{post: %{title: "Incident JSON", slug: slug}}))

conn2 =
  build_conn()
  |> sigra_conn(%{user_id: "incident-user-1", session_id: "incident-session-1"})
  |> get(~p"/api/audit_transactions/#{atid}/changes")

assert response(conn2, 200)
```

**Anonymous rejection path** (lines 41-50):
```elixir
conn =
  build_conn()
  |> get(~p"/api/audit_transactions/#{Ecto.UUID.generate()}/changes")

assert response(conn, 401)

assert Jason.decode!(conn.resp_body) == %{
         "errors" => %{"detail" => "authentication required for incident drill-down"}
       }
```

**Planner note:** keep both proofs in one request-path file. Do not expand into tenancy, role, `403`, or concealment cases.

---

### `examples/threadline_phoenix/test/support/conn_case.ex` (test helper, request-response)

**Analog:** [conn_case.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/test/support/conn_case.ex:39)

**Authenticated request fixture** (lines 39-66):
```elixir
def sigra_conn(conn, attrs \\ %{}) do
  user_id = Map.get(attrs, :user_id, "example-user-1")
  session_id = Map.get(attrs, :session_id, "sigra-session-1")
  org_id = Map.get(attrs, :active_organization_id)

  scope =
    %{
      user: %{id: user_id},
      active_organization_id: org_id
    }

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

**Planner note:** tests should continue to model auth by feeding normalized request state through the real router path, not by assigning `audit_context` manually.

---

### `examples/threadline_phoenix/README.md` (docs, request-response)

**Analog:** [README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:106)

**Incident drill-down wording to mirror** (lines 106-113):
```markdown
## Incident JSON drill-down (`audit_transaction_id` → changes)

CI: `ThreadlinePhoenixWeb.PostsIncidentJsonPathTest`. **Security:**
the reference app now requires an authenticated actor before it serves the
drill-down endpoint. Hosts still need their own tenancy and policy checks
before exposing transaction drill-down in production.
```

**Planner note:** use this exact boundary language in plan tasks: authenticated baseline shipped; tenancy and richer authorization stay host-owned.

---

### `guides/domain-reference.md` (docs, request-response)

**Analog:** [domain-reference.md](/Users/jon/projects/threadline/guides/domain-reference.md:209)

**Reference-example contract block** (lines 211-223):
```markdown
### Reference example: incident JSON (v1.11+)

Contract marker for automated doc checks: **COMP-EXAMPLE-INCIDENT-JSON**

...
CI covers the round-trip in `ThreadlinePhoenixWeb.PostsIncidentJsonPathTest`.
The reference app requires an authenticated actor before it serves the
drill-down endpoint. Production hosts still own tenancy scoping and any richer
authorization policy beyond that baseline.
```

**Planner note:** if docs change here, keep the existing anchor/marker style and extend doc-contract coverage rather than adding a parallel guide-only narrative.

---

### `guides/incident-playbook.md` (docs, request-response)

**Analog:** [incident-playbook.md](/Users/jon/projects/threadline/guides/incident-playbook.md:3)

**Operator-facing boundary wording** (lines 3-8):
```markdown
The Phoenix reference app now includes a baseline auth gate for
`GET /api/audit_transactions/:id/changes`: incident drill-down requires an
authenticated actor. Treat that as the minimum host shape, then layer your own
tenancy and policy rules on top.
```

**Planner note:** this is the right wording shape for incident/auth boundary docs: clear shipped minimum, explicit host-owned follow-on policy.

---

### `guides/getting-started-saas.md` (docs, request-response)

**Analog:** [getting-started-saas.md](/Users/jon/projects/threadline/guides/getting-started-saas.md:175)

**Onboarding wording** (lines 175-178):
```markdown
The reference app also requires an authenticated actor before it serves
`GET /api/audit_transactions/:id/changes`. That keeps the example honest about
incident drill-down: auth is included, while tenancy rules still belong to the
host app.
```

**Planner note:** preserve the “honest about incident drill-down” framing for adopter docs.

---

### `guides/adoption-pilot-backlog.md` (docs, request-response)

**Analog:** [adoption-pilot-backlog.md](/Users/jon/projects/threadline/guides/adoption-pilot-backlog.md:54)

**Evidence-row pattern** (lines 54-58):
```markdown
| `GET /api/audit_transactions/:id/changes` | HTTP | OK | `guides/getting-started-saas.md`; `guides/incident-playbook.md`; `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` | CI-class proof only: the reference app now requires an authenticated actor before drill-down. Host teams still own tenancy and richer authorization review. |
```

**Planner note:** if this guide changes, keep the evidence row tied to exact docs + request-path test, and keep the CI-class vs host-class disclaimer explicit.

---

### `test/threadline/example_phoenix_readme_contract_test.exs` (test, request-response)

**Analog:** [example_phoenix_readme_contract_test.exs](/Users/jon/projects/threadline/test/threadline/example_phoenix_readme_contract_test.exs:1)

**Repo-root markdown loader pattern** (lines 5-10):
```elixir
@repo_root File.cwd!()
@readme_path ["examples", "threadline_phoenix", "README.md"]

defp read_rel!(segments) when is_list(segments) do
  @repo_root |> Path.join(Path.join(segments)) |> File.read!()
end
```

**Literal-lock pattern** (lines 12-18):
```elixir
doc = read_rel!(@readme_path)

assert String.contains?(doc, "Threadline.Integrations.Sigra.actor_ref_from_conn/1")
assert String.contains?(doc, "Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1")
assert String.contains?(doc, "wired directly into `Threadline.Plug`")
```

**Planner note:** reuse this exact test shape if Phase 51 adds README wording locks for the authenticated drill-down boundary.

---

### `test/threadline/exploration_routing_doc_contract_test.exs` and `test/threadline/incident_playbook_doc_contract_test.exs` (test, request-response)

**Analogs:** [exploration_routing_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/exploration_routing_doc_contract_test.exs:11), [incident_playbook_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/incident_playbook_doc_contract_test.exs:11)

**Anchor + literal-lock pattern** (`exploration_routing_doc_contract_test.exs`, lines 25-32):
```elixir
doc = read_rel!(["guides", "domain-reference.md"])

assert String.contains?(doc, "COMP-EXAMPLE-INCIDENT-JSON")
assert String.contains?(doc, "examples/threadline_phoenix")
assert String.contains?(doc, "GET /api/audit_transactions")
assert String.contains?(doc, "audit_transaction_id")
```

**Structured-section contract pattern** (`incident_playbook_doc_contract_test.exs`, lines 16-21, 56-80):
```elixir
assert content =~ "## Scenario: who changed this row at time T?"
assert content =~ "## Scenario: single-transaction drilldown"

assert section_content =~ "### Diagnosis (API)"
assert section_content =~ "### Diagnosis (raw SQL)"
assert section_content =~ "### Expected output"
assert section_content =~ "### Recovery"
```

**Planner note:** if Phase 51 adds new doc-contract tests, follow this style: read markdown at repo root, assert anchors/literals/section structure, and keep tests narrow.

## Shared Patterns

### Auth baseline
**Source:** [audit_transaction_controller.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex:12)

Use normalized Threadline context first:
```elixir
%{actor_ref: actor_ref} -> actor_ref
_ -> nil
```

Apply to: controller logic, docs, and plan wording. Avoid Sigra-private checks in the endpoint contract.

### Request-path proof shape
**Sources:** [posts_incident_json_path_test.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs:6), [conn_case.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/test/support/conn_case.ex:39)

Use one success test that creates a post and follows the returned `audit_transaction_id`, plus one anonymous `401` test. Build authenticated requests with `sigra_conn/2`.

### Boundary wording
**Sources:** [README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:110), [domain-reference.md](/Users/jon/projects/threadline/guides/domain-reference.md:220), [incident-playbook.md](/Users/jon/projects/threadline/guides/incident-playbook.md:5), [getting-started-saas.md](/Users/jon/projects/threadline/guides/getting-started-saas.md:175), [adoption-pilot-backlog.md](/Users/jon/projects/threadline/guides/adoption-pilot-backlog.md:57)

Repeat the same contract everywhere:
- authenticated actor required for drill-down
- tenancy and richer authorization remain host-owned
- the example is a baseline, not a production authorization policy

### Recent v1.15 plan phrasing
**Sources:** `50-01-PLAN.md`, `50-02-PLAN.md`, `51-CONTEXT.md`

Mirror the recent plan/task style:
- task actions start with a directive like `Keep`, `Preserve`, `Do not introduce`, `Follow the exact-file analogs`
- scope guards are explicit in the action text, not implied
- verify blocks cite exact `mix test` commands for the narrow proof surface
- docs tasks name the boundary they must preserve, not just “update docs”

Good Phase 51 phrasing to mirror:
- `Keep the authentication gate in the controller action rather than introducing a new plug or pipeline abstraction.`
- `Preserve the existing JSON success shape for authenticated callers and lock anonymous rejection at 401 with the stable error body.`
- `Update the example README and incident-facing guides together so they repeat the same shipped-baseline versus host-owned authorization boundary.`

## No Analog Found

None. Phase 51 already has exact in-repo controller, request-path test, and docs analogs for every planned surface.

## Metadata

**Analog search scope:** `examples/threadline_phoenix/`, `guides/`, `test/threadline/`, `.planning/milestones/v1.15-phases/50-direct-sigra-host-wiring/`

**Pattern extraction date:** 2026-05-05
