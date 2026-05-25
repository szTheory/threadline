# Phase 89: Contract Lock & Final Verification - Pattern Map

**Mapped:** 2026-05-25
**Files analyzed:** 20
**Analogs found:** 20 / 20

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `guides/upgrade-path.md` | guide | transform | `guides/upgrade-path.md` | exact |
| `guides/operator-surface.md` | guide | request-response | `guides/operator-surface.md` | exact |
| `guides/getting-started-saas.md` | guide | request-response | `guides/getting-started-saas.md` | exact |
| `guides/integration-contracts.md` | guide | request-response | `guides/integration-contracts.md` | exact |
| `examples/threadline_phoenix/README.md` | guide | request-response | `examples/threadline_phoenix/README.md` | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | route | request-response | `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` | exact |
| `test/threadline/upgrade_path_doc_contract_test.exs` | test | transform | `test/threadline/upgrade_path_doc_contract_test.exs` | exact |
| `test/threadline/operator_surface_doc_contract_test.exs` | test | request-response | `test/threadline/operator_surface_doc_contract_test.exs` | exact |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | test | request-response | `test/threadline/getting_started_saas_doc_contract_test.exs` | exact |
| `test/threadline/integration_contracts_doc_contract_test.exs` | test | request-response | `test/threadline/integration_contracts_doc_contract_test.exs` | exact |
| `test/threadline/example_phoenix_readme_contract_test.exs` | test | transform | `test/threadline/example_phoenix_readme_contract_test.exs` | exact |
| `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` | test | request-response | `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs` | exact |
| `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` | test | request-response | `examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs` | exact |
| `mix.exs` | config | batch | `mix.exs` | exact |
| `.github/workflows/ci.yml` | config | batch | `.github/workflows/ci.yml` | exact |
| `.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md` | test | transform | `.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-VERIFICATION.md` | role-match |
| `.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md` | test | batch | `.planning/phases/80-governance-verification-and-milestone-surface-repair/80-VALIDATION.md` | role-match |
| `.planning/ROADMAP.md` | config | transform | `.planning/ROADMAP.md` plus Phase 80 reconciliation usage | exact |
| `.planning/STATE.md` | config | transform | `.planning/STATE.md` plus Phase 80 reconciliation usage | exact |
| `.planning/PROJECT.md` | config | transform | `.planning/PROJECT.md` plus Phase 80 reconciliation usage | exact |

## Pattern Assignments

### `guides/upgrade-path.md` (guide, transform)

**Analog:** [guides/upgrade-path.md](/Users/jon/projects/threadline/guides/upgrade-path.md:15)

**Lane authority and support vocabulary** (lines 15-34):
```md
## How to tell which lane you are on

You are on the `phoenix-surface` lane ...
You are on the `sigra-reference` lane ...

- `supported` means the lane is documented and backed by current repo proof.
- `reference` means the repo maintains a first-party composition path inside a narrower host story.
- `unclaimed` means the combination may be plausible locally, but this repo does not currently prove it.
```

**Proof-chain matrix pattern** (lines 36-51):
```md
Support claims in this table come from current in-repo proof only:

1. declared optional dependency ranges in `mix.exs`
2. current lock resolution in `mix.lock`
3. current CI coverage in `.github/workflows/ci.yml`
4. focused guide, doc-contract, and example-app verification for the named lane
```

**Release-checklist rerun anchors** (lines 107-112):
```md
- If you are `phoenix-surface`, run `mix ci.all` ...
- If you are using the `sigra-reference` lane, run `mix verify.example` ...
```

Use this file as the top-level authority for whether the lane is claimed at all and whether it is `supported`, `reference`, or `unclaimed`.

---

### `guides/operator-surface.md` (guide, request-response)

**Analog:** [guides/operator-surface.md](/Users/jon/projects/threadline/guides/operator-surface.md:29)

**One shared `/audit` topology** (lines 29-73):
```md
The canonical topology is one host-owned `/audit` mount ...

- Keep `/audit` behind `pipe_through [:browser, :admin_auth]`.
- Let `authorize_fn` make the final allow/deny decision.
...
- Return `{:ok, %{access: :support_read_only, organization_id: "org_123"}}` ...
- Use `export_authorize_fn` ...
```

**Transport-parity auth contract** (lines 92-127):
```md
The `:authorize_fn` callback is invoked directly as a 1-arity function.
...
- `{:ok, scope}` - Allowed. The `scope` is host-owned and opaque.
...
`live_session` and `on_mount` protect the LiveView pages only.
They do not secure the sibling HTTP export controller routes.
...
plain-text `403`
```

**Parity table / row-history wording** (lines 166-190):
```md
### Row History / As-of Sub-view (`/audit/rows/:table/:pk`)
...
| `/audit/rows/:table/:pk` | How did this row change over time? | `Threadline.history/3` and `Threadline.as_of/4` | API parity |
```

Use this file as the behavior contract for the shipped `/audit` surface. If row-history/as-of cannot be proven for support-scoped sessions, narrow this wording here first.

---

### `guides/getting-started-saas.md` (guide, request-response)

**Analog:** [guides/getting-started-saas.md](/Users/jon/projects/threadline/guides/getting-started-saas.md:209)

**Canonical first-hour mount recipe** (lines 209-246):
```md
## 9. Mount the operator surface and open `/audit`
...
threadline_operator_surface("/",
  actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
  authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
  export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
  scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
  repo: ThreadlinePhoenix.Repo
)
...
The canonical first-hour recipe is still admin first, but the runnable example
also proves the stronger shared-operator shape ...
```

**Pointer-back-to-authority split** (lines 273-278):
```md
If you are not ready to mount the UI yet ...
Keep support-lane claims and exact proof pins in
`guides/upgrade-path.md` ...
```

Keep this guide as the adopter recipe, not the support-matrix owner.

---

### `guides/integration-contracts.md` (guide, request-response)

**Analog:** [guides/integration-contracts.md](/Users/jon/projects/threadline/guides/integration-contracts.md:102)

**Operator-surface seam contract** (lines 102-123):
```md
The operator surface is one breadth contract with two transport faces:

- LiveView mount/auth via `authorize_fn`
- HTTP export auth via optional `export_authorize_fn`
...
`threadline_operator_surface/2` is the supported mount boundary.
```

**Shared callback vocabulary** (lines 129-200):
```elixir
def authorize_operator(%{assigns: assigns}) do
  case assigns[:current_user] do
    %{role: :admin} -> :ok
    %{role: :support, organization_id: org_id} ->
      {:ok, %{access: :support_read_only, organization_id: org_id}}
    _ -> {:error, :unauthorized}
  end
end
```

```elixir
mirror = %{assigns: conn.assigns}
authorize_fn.(mirror)
```

**Download boundary wording** (lines 202-203):
```md
For background exports, keep one actor-owned Threadline download route keyed by
the export job ID.
```

Use this guide for host-owned seam truth: `authorize_fn`, `scope_query_fn`, and `export_authorize_fn` stay central; no policy DSL language is introduced.

---

### `examples/threadline_phoenix/README.md` (guide, request-response)

**Analog:** [examples/threadline_phoenix/README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:3)

**Narrow runnable-proof disclaimer** (lines 3-9):
```md
Treat the install, run, test, and reconstruction commands in this document as the runnable example contract.
...
This app is the current `sigra-reference` lane ...
It does not claim that arbitrary Sigra versions ... are supported automatically.
```

**Layered-on-top wording + copied mount block** (lines 136-183):
```md
For support language, treat this as a `sigra-reference` example layered on top
of the root library's broader `phoenix-surface` lane.
...
threadline_operator_surface("/",
  actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
  authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
  export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
  scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
  repo: ThreadlinePhoenix.Repo
)
...
They remain on the same `/audit` path,
but see fewer records, cannot trigger exports, and still receive standard `403`
errors ...
```

Do not let this README become the broader root-lane authority. It proves the narrower reference path only.

---

### `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (route, request-response)

**Analog:** [examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:62)

**Shared `%{assigns: assigns}` authorizer** (lines 62-80):
```elixir
def my_authorize_fn(%{assigns: assigns}) do
  case assigns[:current_user] do
    %{is_admin: true} ->
      :ok

    %{role: :support, organization_id: org_id} when is_binary(org_id) and org_id != "" ->
      {:ok, %{access: :support_read_only, organization_id: org_id}}

    _ ->
      {:error, :unauthorized}
  end
end
```

**Scope seam pattern** (lines 82-97):
```elixir
def scope_operator_query(query, %{organization_id: org_id}, %{surface: :actor_history}) ...
def scope_operator_query(query, %{organization_id: org_id}, %{surface: :transaction_header}) ...
def scope_operator_query(query, %{organization_id: org_id}, %{surface: surface})
    when surface in [:timeline, :transaction, :export] ...
```

**Mounted proof block** (lines 119-128):
```elixir
scope "/audit" do
  pipe_through([:browser, :operator_auth])

  threadline_operator_surface("/",
    actor_fn: &ThreadlinePhoenixWeb.Router.my_actor_fn/1,
    authorize_fn: &ThreadlinePhoenixWeb.Router.my_authorize_fn/1,
    export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1,
    scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3,
```

If the example proof changes, keep README snippets extracted from this router rather than hand-maintained duplicates.

---

### Doc-contract tests (`test/threadline/*doc_contract_test.exs`) (test, transform/request-response)

**Primary analogs:** [test/threadline/upgrade_path_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/upgrade_path_doc_contract_test.exs:5), [test/threadline/operator_surface_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface_doc_contract_test.exs:32), [test/threadline/getting_started_saas_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/getting_started_saas_doc_contract_test.exs:14), [test/threadline/integration_contracts_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integration_contracts_doc_contract_test.exs:84), [test/threadline/example_phoenix_readme_contract_test.exs](/Users/jon/projects/threadline/test/threadline/example_phoenix_readme_contract_test.exs:50)

**Section-architecture lock pattern**:
```elixir
assert String.contains?(guide, "## How to tell which lane you are on")
assert String.contains?(guide, "## Supported compatibility matrix")
...
assert String.contains?(guide, "## Canonical references")
```

**Truth-first wording lock pattern**:
```elixir
assert String.contains?(guide, "Anything outside these named lanes is `unclaimed`")
refute String.contains?(guide, "Phoenix 1.7+")
```

**Snippet-extraction pattern for router-backed docs**:
```elixir
assert contains_normalized?(doc, router_mount_block())

GettingStartedFixtures.extract!(
  "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex",
  "operator-surface-mount"
)
```

**Negative-contract pattern**:
```elixir
refute String.contains?(guide, "permissions_dsl")
refute String.contains?(router, "def my_authorize_fn(%Plug.Conn{}")
```

For Phase 89, keep tests literal and narrow. Prefer direct `String.contains?/2` and `refute` assertions over broad snapshots.

---

### Example behavior tests (`examples/threadline_phoenix/test/threadline_phoenix_web/*.exs`) (test, request-response)

**Analog:** [examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs:23)

**Scoped support-read proof** (lines 23-45):
```elixir
test "support user only sees transactions scoped to their organization", %{conn: conn} do
  {:ok, visible_tx} = create_post_for_org("support-org-1", "support-visible")
  {:ok, hidden_tx} = create_post_for_org("support-org-2", "support-hidden")
  ...
  hidden_conn = get(conn, "/audit/transactions/#{hidden_tx}")
  assert html_response(hidden_conn, 200) =~ "Transaction Not Found"
end
```

**Export denial proof** (lines 47-63):
```elixir
test "support user cannot export from the shared operator surface", %{conn: conn} do
  ...
  export_conn =
    get(conn, "/audit/exports/changes.csv?from=2020-01-01T00:00&to=2099-01-01T00:00")

  assert response(export_conn, 403) == "forbidden"
end
```

**Incident drill-down request-path proof** from [posts_incident_json_path_test.exs](/Users/jon/projects/threadline/examples/threadline_phoenix/test/threadline_phoenix_web/posts_incident_json_path_test.exs:6):
```elixir
test "POST /api/posts returns audit_transaction_id; GET changes returns the bundled incident contract" do
  ...
  assert drill["transaction"]["actor_ref"] == %{"type" => "user", "id" => "incident-user-1"}
  ...
end
```

Use example tests as the mandatory proof band for the routed Phoenix host path.

---

### `mix.exs` and `.github/workflows/ci.yml` (config, batch)

**Analogs:** [mix.exs](/Users/jon/projects/threadline/mix.exs:73), [.github/workflows/ci.yml](/Users/jon/projects/threadline/.github/workflows/ci.yml:1)

**Named verify alias pattern** (`mix.exs` lines 73-94):
```elixir
"verify.test": ["test"],
"verify.doc_contract": ["test test/threadline/readme_doc_contract_test.exs"],
"verify.example": &verify_example/1,
"verify.compile_no_optional": ["compile --no-optional-deps --warnings-as-errors"],
"ci.all": [
  "verify.format",
  "verify.credo",
  "compile --warnings-as-errors",
  "verify.compile_no_optional",
  "verify.test",
  "verify.threadline",
  "verify.example",
  "verify.doc_contract"
]
```

**Example verification implementation** (`mix.exs` lines 120-127):
```elixir
defp verify_example(_args) do
  cmd =
    "bash -lc 'set -euo pipefail && cd examples/threadline_phoenix ... && mix test'"
```

**Stable CI job-id contract** (`.github/workflows/ci.yml` lines 1-2):
```yaml
# Job id contract — stable YAML `jobs:` keys are relied on by docs and `act`:
# verify-format, verify-credo, verify-compile-no-optional, verify-test, ...
```

**Proof discoverability pattern** (`.github/workflows/ci.yml` lines 67-117, 185-202):
```yaml
verify-test:
  ...
  - name: Run tests
    run: mix verify.test
  - name: Verify Threadline Phoenix example
    run: mix verify.example
  - name: Doc contract tests
    run: mix verify.doc_contract

verify-docs:
  ...
  - name: Build docs
    run: mix docs
```

Do not introduce ad hoc one-off commands if the proof can be attached to existing `mix verify.*` aliases and stable CI jobs.

---

### `.planning/phases/89-contract-lock-final-verification/89-VERIFICATION.md` (test, transform)

**Analog:** [.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-VERIFICATION.md](/Users/jon/projects/threadline/.planning/phases/84-export-delivery-and-scale-adapter-integration-repair/84-VERIFICATION.md:1)

**Frontmatter + final-tree header** (lines 1-12):
```md
---
phase: 84-export-delivery-and-scale-adapter-integration-repair
verified: 2026-05-24T11:08:09Z
status: passed
score: 4/4 truths verified
overrides_applied: 0
---
```

**Observable truths + requirements coverage structure** (lines 13-42):
```md
## Goal Achievement

### Observable Truths
| # | Truth | Status | Evidence |
...
### Requirements Coverage
| Requirement | Source Plan(s) | Description | Status | Evidence |
```

**Command log + verification notes shape** (lines 44-98):
```md
### Commands Run On Final Tree
1. ...
Result: PASS

### Verification Notes
- ...
### Gaps Summary
```

For Phase 89, keep the report focused on four evidence bands:
1. public contract text
2. root behavioral proof
3. example-host proof
4. named verification / CI proof

If `89-03` is not opened, say so explicitly in `Verification Notes` rather than implying milestone-surface edits happened.

---

### `.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md` (test, batch)

**Analog:** [.planning/phases/80-governance-verification-and-milestone-surface-repair/80-VALIDATION.md](/Users/jon/projects/threadline/.planning/phases/80-governance-verification-and-milestone-surface-repair/80-VALIDATION.md:1)

**Nyquist frontmatter pattern** (lines 1-8):
```md
---
phase: 80
slug: governance-verification-and-milestone-surface-repair
status: passed
nyquist_compliant: true
wave_0_complete: true
```

**Test-infrastructure and sampling blocks** (lines 12-32):
```md
## Test Infrastructure
| **Framework** | Planning-artifact checks, targeted ExUnit verification ... |
...
## Sampling Rate
- After ...
- Before final verification ...
```

**Per-task verification map pattern** (lines 34-61):
```md
| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
| 80-01-01 | 01 | 1 | ... |
```

**Wave 0 / manual-only / sign-off pattern** (lines 63-80):
```md
## Wave 0 Requirements
- [x] ...

## Manual-Only Verifications
| Behavior | Requirement | Why Manual | Test Instructions |
```

Phase 89 already has the draft task map in [89-VALIDATION.md](/Users/jon/projects/threadline/.planning/phases/89-contract-lock-final-verification/89-VALIDATION.md:37). Preserve that table-driven structure and upgrade it into final Nyquist-compliant form instead of rewriting the artifact shape.

---

### Optional milestone-surface reconciliation: `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/PROJECT.md` (config, transform)

**Primary analog:** [.planning/phases/80-governance-verification-and-milestone-surface-repair/80-VALIDATION.md](/Users/jon/projects/threadline/.planning/phases/80-governance-verification-and-milestone-surface-repair/80-VALIDATION.md:39)

**Current Phase 89 hooks**

`ROADMAP.md` phase slot ([lines 61-69](/Users/jon/projects/threadline/.planning/ROADMAP.md:61)):
```md
### Phase 89: Contract Lock & Final Verification
**Goal**: The named support lane is contract-tested, docs-locked, and verified on the current tree.
...
- [ ] 89-03: Optional roadmap / milestone-surface reconciliation if closeout reveals drift
```

`STATE.md` contradiction-check surface ([lines 25-34](/Users/jon/projects/threadline/.planning/STATE.md:25)):
```md
Phase: Not started (defining requirements and roadmap)
Status: Planning v1.21 support-lane proof work
...
- **Phases Completed**: 0 of 5 and 0 of 11 plans complete for v1.21
```

`PROJECT.md` milestone truth boundary ([lines 38-41](/Users/jon/projects/threadline/.planning/PROJECT.md:38)):
```md
**Next milestone goals:**
- Prove the host-owned support lane ...
- Productize the mount contract, not the auth model ...
- Treat row history / as-of conservatively ...
```

Use the Phase 80 rule: only update authority surfaces when they contradict final verified current-tree truth. Do not open `89-03` for ordinary guide/test/example cleanup.

## Shared Patterns

### Layered authority by concern
**Sources:** [guides/upgrade-path.md](/Users/jon/projects/threadline/guides/upgrade-path.md:15), [guides/operator-surface.md](/Users/jon/projects/threadline/guides/operator-surface.md:29), [guides/getting-started-saas.md](/Users/jon/projects/threadline/guides/getting-started-saas.md:209), [examples/threadline_phoenix/README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md:136)

Apply across all public contract updates:
```md
- `guides/upgrade-path.md` owns lane breadth and support words
- `guides/operator-surface.md` owns `/audit` behavior
- `guides/getting-started-saas.md` owns the first-hour recipe
- `examples/threadline_phoenix/README.md` proves the narrow reference path
```

### Shared auth/scope vocabulary
**Sources:** [guides/integration-contracts.md](/Users/jon/projects/threadline/guides/integration-contracts.md:131), [examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:62)

Apply to docs, router snippets, and behavioral tests:
```elixir
def my_authorize_fn(%{assigns: assigns}) do
  ...
  %{role: :support, organization_id: org_id} ->
    {:ok, %{access: :support_read_only, organization_id: org_id}}
end
```

```elixir
scope_query_fn: &ThreadlinePhoenixWeb.Router.scope_operator_query/3
export_authorize_fn: &ThreadlinePhoenixWeb.Router.my_export_authorize_fn/1
```

### Router-backed documentation snippets
**Sources:** [test/threadline/getting_started_saas_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/getting_started_saas_doc_contract_test.exs:110), [test/threadline/example_phoenix_readme_contract_test.exs](/Users/jon/projects/threadline/test/threadline/example_phoenix_readme_contract_test.exs:104)

Apply to guide and example README updates:
```elixir
GettingStartedFixtures.extract!(
  "examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex",
  "operator-surface-mount"
)
```

If the router changes, update docs by reusing the extracted mount block rather than manually drifting snippets.

### Named proof entrypoints and stable CI IDs
**Sources:** [mix.exs](/Users/jon/projects/threadline/mix.exs:75), [.github/workflows/ci.yml](/Users/jon/projects/threadline/.github/workflows/ci.yml:1)

Apply to verification, validation, and docs:
```md
- cite `mix verify.doc_contract`
- cite `mix verify.example`
- cite `mix ci.all`
- preserve stable job ids such as `verify-test`, `verify-docs`, `verify-compile-no-optional`
```

### Truth-first reconciliation taxonomy
**Sources:** [.planning/phases/80-governance-verification-and-milestone-surface-repair/80-VALIDATION.md](/Users/jon/projects/threadline/.planning/phases/80-governance-verification-and-milestone-surface-repair/80-VALIDATION.md:34), [.planning/PROJECT.md](/Users/jon/projects/threadline/.planning/PROJECT.md:293)

Apply if `89-03` is needed:
```md
- current-tree truth beats continuity
- only authoritative contradiction triggers milestone-surface edits
- do not widen the claim during closeout
```

## No Analog Found

None. Every likely Phase 89 file already has a strong in-repo analog or an existing same-file contract to tighten.

## Metadata

**Analog search scope:** `.planning/phases/69-*`, `.planning/phases/70-*`, `.planning/phases/72-*`, `.planning/phases/74-*`, `.planning/phases/80-*`, `.planning/phases/84-*`, `guides/`, `examples/threadline_phoenix/`, `test/threadline/`, `.github/workflows/`, root planning files  
**Files scanned:** 27  
**Pattern extraction date:** 2026-05-25
