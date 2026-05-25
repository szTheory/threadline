# Phase 92: Phase 87 Verification Backfill - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 18
**Analogs found:** 18 / 18

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VERIFICATION.md` | test | transform | `.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md` | exact |
| `.planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VALIDATION.md` | test | batch | `.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md` | exact |
| `guides/getting-started-saas.md` | config | request-response | `guides/getting-started-saas.md` | exact |
| `examples/threadline_phoenix/README.md` | config | request-response | `examples/threadline_phoenix/README.md` | exact |
| `guides/operator-surface.md` | config | request-response | `guides/operator-surface.md` | exact |
| `guides/upgrade-path.md` | config | transform | `guides/upgrade-path.md` | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | route | request-response | `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | exact |
| `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` | test | request-response | `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` | exact |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | test | transform | `test/threadline/getting_started_saas_doc_contract_test.exs` | exact |
| `test/threadline/example_phoenix_readme_contract_test.exs` | test | transform | `test/threadline/example_phoenix_readme_contract_test.exs` | exact |
| `test/threadline/operator_surface_doc_contract_test.exs` | test | transform | `test/threadline/operator_surface_doc_contract_test.exs` | exact |
| `test/threadline/upgrade_path_doc_contract_test.exs` | test | transform | `test/threadline/upgrade_path_doc_contract_test.exs` | exact |
| `mix.exs` | config | batch | `mix.exs` | exact |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `.planning/ROADMAP.md` | config | transform | `.planning/ROADMAP.md` | exact |
| `.planning/STATE.md` | config | transform | `.planning/STATE.md` | exact |
| `.planning/PROJECT.md` | config | transform | `.planning/PROJECT.md` | exact |
| `.planning/REQUIREMENTS.md` | config | CRUD | `.planning/REQUIREMENTS.md` | exact |

## Pattern Assignments

### `.planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VERIFICATION.md` (verification artifact, transform)

**Analog:** `.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md`

**Frontmatter + verdict header** (lines 1-15):
```md
---
phase: 89-contract-lock-final-verification
verified: 2026-05-25T07:45:00Z
status: verified_with_followup
score: 4/4 evidence bands reviewed
authoritative_surface_drift: detected
---

# Phase 89: Contract Lock & Final Verification — Verification Report

**Phase Goal:** Prove on the current tree that Threadline’s public docs, root behavior, example-host proof, and named verification surfaces all describe the same support lane truthfully...
```

**Evidence-band section pattern** (lines 19-38, 73-92, 96-125):
```md
## 1. Public Contract Text

**Result:** PASS

### Evidence

```bash
mix verify.doc_contract
```

Result: PASS
```

**Truth-first drift section** (lines 129-143):
```md
## 5. Authoritative-Surface Drift

**Verdict:** detected

... Phase 89 must not silently patch them inside this verification plan.

### Required Follow-up

- Open or execute `89-03` specifically...
```

**Apply to Phase 92:** Keep the same split between public-contract proof, runnable example-host proof, named verification/CI proof, and conditional authority-surface drift. Replace the Phase 89 row-history narrowing narrative with Phase 92's `/audit` mount and example-host closure narrative.

---

### `.planning/phases/87-canonical-mount-recipe-and-example-app-proof/87-VALIDATION.md` (validation artifact, batch)

**Analog:** `.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md`

**Frontmatter + validation framing** (lines 1-15):
```md
---
phase: 89
slug: contract-lock-final-verification
status: verified_with_followup
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
updated: 2026-05-25T07:45:00Z
---

# Phase 89 — Validation Strategy
```

**Test infrastructure table** (lines 18-28):
```md
| Property | Value |
|----------|-------|
| **Framework** | ExUnit, Mix alias verification, CI-surface grep, and planning-artifact review |
| **Quick run command** | `mix verify.doc_contract` |
| **Example-host proof** | `mix verify.example` |
| **Full suite command** | `mix ci.all` |
```

**Per-task verification map + command ledger** (lines 41-68):
```md
| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
...
## Commands Actually Used

1. `mix test ...`
   Result: PASS
2. `mix verify.doc_contract`
   Result: PASS
3. `mix verify.example`
   Result: PASS
```

**Apply to Phase 92:** Keep the same Nyquist-style structure. Phase 92 should explicitly map `ADOPT-01` and `ADOPT-02` to `mix verify.doc_contract`, `mix verify.example`, CI-surface grep, and any targeted root/example test reruns actually used.

---

### `guides/getting-started-saas.md` (guide, request-response)

**Analog:** `guides/getting-started-saas.md`

**Canonical shared `/audit` recipe** (lines 211-226):
```elixir
Once capture is working, mount the shipped operator surface behind your existing
browser and operator pipeline. Reuse the real example router shape:

scope "/audit" do
  pipe_through([:browser, :operator_auth])

  threadline_operator_surface("/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
    scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
    repo: ThreadlinePhoenix.Repo
  )
end
```

**Host-owned auth/scope explanation** (lines 228-247):
```md
`pipe_through [:browser, :operator_auth]` is the important posture...
support operators return an opaque host-owned scope...
`scope_query_fn` narrows timeline, actor, transaction, row-history, and as-of queries to that scope.
`export_authorize_fn` keeps direct export requests ... admin-only on the same `/audit` tree.
```

**Apply when editing:** Keep this file as the adopter-facing canonical mount recipe. If truth changes, update the prose and the code block together.

---

### `examples/threadline_phoenix/README.md` (example doc, request-response)

**Analog:** `examples/threadline_phoenix/README.md`

**Example-host proof narrative** (lines 145-187):
```md
admins get the full surface, while support operators get the current scoped
read-only proof for timeline, actor, transaction, and export denial through the
host-owned `scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3`
seam:

scope "/audit" do
  pipe_through([:browser, :operator_auth])

  threadline_operator_surface("/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
    scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
    repo: ThreadlinePhoenix.Repo
  )
end
```

**Export denial language** (lines 179-191):
```md
By combining `authorize_fn`, `export_authorize_fn`, and `scope_query_fn` on one tree...
they remain on the same `/audit` path, but see fewer records, cannot trigger exports,
and still receive standard `403` errors...
```

**Apply when editing:** This file should stay narrower than broad product docs. Use it as the runnable reference-lane proof, not as a new product-policy document.

---

### `guides/operator-surface.md` (guide, request-response)

**Analog:** `guides/operator-surface.md`

**Admin-first + support-read-only variation pattern** (lines 43-81):
```elixir
scope "/audit", MyAppWeb do
  pipe_through [:browser, :admin_auth]

  threadline_operator_surface "/",
    actor_fn: &MyApp.Audit.current_actor/1,
    authorize_fn: &MyApp.Audit.authorize_operator/1,
    repo: MyApp.Repo
end
```

```md
- Reuse the same `/audit` surface and the same host auth boundary.
- Return `{:ok, %{access: :support_read_only, organization_id: "org_123"}}`...
- Use `export_authorize_fn` to keep export affordances and direct HTTP export requests behind explicit host authorization on the same tree.
```

**Apply when editing:** Preserve the “admin-first recipe” plus “support-read-only variation” structure. This file defines the generic host pattern; the example README proves it concretely.

---

### `guides/upgrade-path.md` (support matrix / lane taxonomy, transform)

**Analog:** `guides/upgrade-path.md`

**Lane taxonomy + proof-source pattern** (lines 17-26, 50-56, 112-116):
```md
You are on the `sigra-reference` lane ...
The proof for this lane comes from `examples/threadline_phoenix/`, its lockfile and README,
`guides/integrations/sigra.md`, and `mix verify.example`.

| `sigra-reference` | `reference` | ... | `mix verify.example`, and focused doc-contract tests |

- If you are using the `sigra-reference` lane, run `mix verify.example` ...
```

**Apply when editing:** Keep this file focused on claim taxonomy, evidence sources, and rerun guidance. Do not duplicate the full recipe prose here.

---

### `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (route, request-response)

**Analog:** `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`

**Fail-closed operator auth + shared assigns-shaped authorizer** (lines 34-79):
```elixir
def require_authenticated_operator(conn, _opts) do
  case conn.assigns[:current_user] do
    %{is_admin: true} = user ->
      Plug.Conn.put_session(conn, :threadline_current_user, user)

    %{role: :support, organization_id: org_id} = user when is_binary(org_id) and org_id != "" ->
      Plug.Conn.put_session(conn, :threadline_current_user, user)

    _ ->
      conn
      |> Plug.Conn.put_status(403)
      |> Phoenix.Controller.text("Forbidden")
      |> Plug.Conn.halt()
  end
end

def my_authorize_fn(%{assigns: assigns}) do
  case assigns[:current_user] do
    %{is_admin: true} -> :ok
    %{role: :support, organization_id: org_id} when is_binary(org_id) and org_id != "" ->
      {:ok, %{access: :support_read_only, organization_id: org_id}}
    _ -> {:error, :unauthorized}
  end
end

def my_export_authorize_fn(%{assigns: assigns}) do
  case assigns[:current_user] do
    %{is_admin: true} -> :ok
    _ -> {:error, :unauthorized}
  end
end
```

**Shared `/audit` mount** (lines 119-130):
```elixir
scope "/audit" do
  pipe_through([:browser, :operator_auth])

  threadline_operator_surface("/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
    scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
    repo: ThreadlinePhoenix.Repo
  )
end
```

**Apply when editing:** Preserve one shared mount tree, one assigns-shaped authorization callback, and a separate export-authorize seam.

---

### `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` (example proof test, request-response)

**Analog:** `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs`

**Behavior-proof structure** (lines 8-63):
```elixir
test "anonymous request is rejected", %{conn: conn} do
  conn = get(conn, "/audit/transactions/123")
  assert response(conn, 403) == "Forbidden"
end

test "authenticated admin request reaches the surface", %{conn: conn} do
  ...
  assert html_response(conn, 200) =~ "Transaction Not Found"
end

test "support user only sees transactions scoped to their organization", %{conn: conn} do
  ...
  refute visible_html =~ "Transaction Not Found"
  ...
  assert html_response(hidden_conn, 200) =~ "Transaction Not Found"
end

test "support user cannot export from the shared operator surface", %{conn: conn} do
  ...
  assert response(export_conn, 403) == "forbidden"
end
```

**Fixture helper pattern** (lines 65-86):
```elixir
defp create_post_for_org(org_id, slug) do
  unique_slug = "#{slug}-#{System.unique_integer([:positive])}"

  Ecto.Adapters.SQL.Sandbox.unboxed_run(Repo, fn ->
    {:ok, actor_ref} = ActorRef.new(:user, "support-#{org_id}")
    ...
    with {:ok, %{audit_transaction_id: tx_id}} <- Blog.create_post(...),
         true <- is_binary(tx_id) do
      {:ok, tx_id}
    else
      _ -> {:error, :missing_audit_transaction_id}
    end
  end)
end
```

**Apply when editing:** Keep this as the concrete example-host proof for shared-path auth, scoped reads, and export denial.

---

### Doc-contract tests (`test/threadline/*doc_contract_test.exs`) (tests, transform)

**Analogs:**
- `test/threadline/getting_started_saas_doc_contract_test.exs`
- `test/threadline/example_phoenix_readme_contract_test.exs`
- `test/threadline/operator_surface_doc_contract_test.exs`
- `test/threadline/upgrade_path_doc_contract_test.exs`

**Exact string-lock pattern from the SaaS quickstart** (`getting_started_saas_doc_contract_test.exs` lines 72-85):
```elixir
assert String.contains?(doc, "support operators return an opaque host-owned scope")
assert String.contains?(doc, "export_authorize_fn")
assert String.contains?(doc, "`scope_query_fn` narrows timeline, actor, transaction,")
assert String.contains?(doc, "row-history, and as-of queries to that scope")
assert String.contains?(doc, "plain-text `403`")
```

**Example README + router contract pattern** (`example_phoenix_readme_contract_test.exs` lines 60-96):
```elixir
assert String.contains?(doc, "current scoped")
assert String.contains?(doc, "timeline, actor, transaction, and export denial")
assert String.contains?(doc, "shared scoped `/audit` proof now includes")
...
assert String.contains?(router, "def my_authorize_fn(%{assigns: assigns}) do")
assert String.contains?(router, "scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3")
assert String.contains?(router, "export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1")
```

**Operator-surface guide lock** (`operator_surface_doc_contract_test.exs` lines 32-40):
```elixir
assert String.contains?(guide, "pipe_through [:browser, :admin_auth]")
assert String.contains?(guide, "support-read-only variation")
assert String.contains?(guide, "export_authorize_fn")
refute String.contains?(guide, "support_roles =")
refute String.contains?(guide, "permissions_dsl")
```

**Upgrade-path proof-source lock** (`upgrade_path_doc_contract_test.exs` lines 87-92):
```elixir
assert String.contains?(guide, "mix verify.example")
assert String.contains?(guide, "Root `mix.exs`, root `mix.lock`")
assert String.contains?(guide, "`examples/threadline_phoenix/mix.lock`")
assert String.contains?(guide, "`examples/threadline_phoenix/README.md`")
```

**Apply when editing:** Keep doc-contract assertions literal and adopter-facing. When wording changes, update only the strings that encode the public claim boundary.

---

### `mix.exs` and `.github/workflows/ci.yml` (verification surfaces, batch)

**Analogs:** `mix.exs`, `.github/workflows/ci.yml`

**Named verify alias pattern** (`mix.exs` lines 7-19, 76-97):
```elixir
preferred_envs: [
  "ci.all": :test,
  "verify.doc_contract": :test,
  ...
  "verify.example": :test
]

"verify.doc_contract": [
  "test test/threadline/readme_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs"
],
"verify.example": &verify_example/1,
"ci.all": [
  "verify.format",
  "verify.credo",
  ...
  "verify.example",
  "verify.doc_contract"
]
```

**CI discoverability pattern** (`.github/workflows/ci.yml` lines 101-117):
```yaml
- name: Run tests
  run: mix verify.test

- name: Verify Threadline Phoenix example
  run: mix verify.example

- name: Doc contract tests
  run: mix verify.doc_contract
```

**Apply when editing:** Keep named rerun surfaces stable. If Phase 92 changes proof shape, update the alias and CI job references together.

---

### Conditional authority-surface files (`.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`) (config, transform/CRUD)

**Analogs:** same files

**Roadmap phase-slot pattern** (`.planning/ROADMAP.md` lines 93-101):
```md
### Phase 92: Phase 87 Verification Backfill

**Depends on**: Phase 91
**Requirements**: ADOPT-01, ADOPT-02

- [ ] 92-01: Re-verify the canonical `/audit` mount recipe and example-app proof
```

**State continuity pattern** (`.planning/STATE.md` lines 62-77):
```md
- 2026-05-25: Phase 91 backfilled ...

### Todos

- [ ] Execute Phase 92 ...

## Session Continuity

- **Last Action**: Closed Phase 91 ...
- **Next Step**: Execute Phase 92 ...
```

**Project milestone-truth pattern** (`.planning/PROJECT.md` lines 38-46):
```md
**Next milestone goals:**
- Prove the host-owned support lane on the shipped `/audit` surface end to end...
- Productize the mount contract, not the auth model...
- Treat row history / as-of conservatively for support-scoped sessions...
```

**Requirement status pattern** (`.planning/REQUIREMENTS.md` lines 21-33, 56-62):
```md
- [ ] **ADOPT-01**: Threadline ships one canonical `/audit` mount recipe...
- [ ] **ADOPT-02**: The example Phoenix app proves ...

| ADOPT-01 | Phase 92 | Pending |
| ADOPT-02 | Phase 92 | Pending |
```

**Apply when editing:** Touch these only if Phase 92 changes milestone truth or closes `ADOPT-01` / `ADOPT-02`. Keep the wording synchronized with the verification artifact; do not let these files drift from the proven current-tree claim.

## Shared Patterns

### Split Verdict vs Evidence Artifacts
**Sources:** `.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md:1`, `.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md:1`

Use two files, not one:
- `87-VERIFICATION.md` states verdicts, claim boundary, evidence-band outcomes, caveats, and any required follow-up.
- `87-VALIDATION.md` records command mapping, sampling cadence, commands actually used, manual checks, and sign-off.

### One Shared `/audit` Tree
**Source:** `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:119`

```elixir
scope "/audit" do
  pipe_through([:browser, :operator_auth])

  threadline_operator_surface("/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
    scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
    repo: ThreadlinePhoenix.Repo
  )
end
```

Apply to all docs, tests, and artifacts that describe the canonical mount recipe.

### Host-Owned Auth + Separate Export Capability
**Source:** `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:34`

```elixir
def my_authorize_fn(%{assigns: assigns}) do
  ...
  %{role: :support, organization_id: org_id} -> {:ok, %{access: :support_read_only, organization_id: org_id}}
  ...
end

def my_export_authorize_fn(%{assigns: assigns}) do
  case assigns[:current_user] do
    %{is_admin: true} -> :ok
    _ -> {:error, :unauthorized}
  end
end
```

Apply to router docs, README wording, and example-host proof.

### Public Contract Locked by Literal Doc Assertions
**Sources:** `test/threadline/getting_started_saas_doc_contract_test.exs:72`, `test/threadline/example_phoenix_readme_contract_test.exs:60`, `test/threadline/operator_surface_doc_contract_test.exs:32`, `test/threadline/upgrade_path_doc_contract_test.exs:87`

Use `String.contains?/2` assertions against exact adopter-facing phrases. When the claim boundary changes, update the guide and its matching assertions in the same pass.

### Named Rerun Surfaces Are Part of the Product Proof
**Sources:** `mix.exs:7`, `.github/workflows/ci.yml:101`

Use stable entrypoints already encoded in the repo:
- `mix verify.doc_contract`
- `mix verify.example`
- `mix ci.all`

Do not replace them with artifact-only shell recipes.

## No Analog Found

None. All required and conditional Phase 92 files already have direct analogs on the current tree.

## Metadata

**Analog search scope:** `.planning/phases/`, `guides/`, `examples/threadline_phoenix/`, `test/threadline/`, repo root config
**Files scanned:** 18 primary targets plus prior-phase artifact analogs
**Pattern extraction date:** 2026-05-25
