# Phase 69: Integration Contracts & Support Matrix - Pattern Map

**Mapped:** 2026-05-07
**Scope:** plan-splitting, integration seam docs, doc-contract locking, verification/CI anchors

## File Classification

| Planned File / Slice | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/69-integration-contracts-and-support-matrix/69-01-PLAN.md` | plan | docs-contract | `.planning/phases/68-lifecycle-ergonomics/68-01-PLAN.md` | exact |
| `.planning/phases/69-integration-contracts-and-support-matrix/69-02-PLAN.md` | plan | support-matrix | `.planning/phases/68-lifecycle-ergonomics/68-02-PLAN.md` | exact |
| `.planning/phases/69-integration-contracts-and-support-matrix/69-03-PLAN.md` | plan | verification-proof | `.planning/phases/68-lifecycle-ergonomics/68-03-PLAN.md` | exact |
| `guides/integration-contracts.md` (recommended new canonical doc) | guide | request-response + batch-proof | `guides/upgrade-path.md` plus `guides/integrations/sigra.md` | partial |
| `guides/upgrade-path.md` | guide | support-matrix | `guides/upgrade-path.md` | exact |
| `guides/integrations/sigra.md` | guide | request-response adapter | `guides/integrations/sigra.md` | exact |
| `guides/operator-surface.md` or README cross-links | guide | request-response auth surface | `test/threadline/operator_surface_doc_contract_test.exs`-locked wording | role-match |
| `test/threadline/*doc_contract*_test.exs` for the new contract doc | test | wording-lock | `test/threadline/upgrade_path_doc_contract_test.exs` | exact |
| `test/threadline/integrations/sigra_doc_contract_test.exs` | test | wording-lock | `test/threadline/integrations/sigra_doc_contract_test.exs` | exact |
| `test/threadline/operator_surface_doc_contract_test.exs` | test | scope/cross-link lock | `test/threadline/operator_surface_doc_contract_test.exs` | exact |

## Pattern Assignments

### 1. Split the phase into executable doc slices, not one broad docs plan

**Primary analogs:** `.planning/phases/68-lifecycle-ergonomics/68-01-PLAN.md`, `68-02-PLAN.md`, `68-03-PLAN.md`

**Frontmatter + must_haves pattern**  
Copy the Phase 68 shape: explicit `files_modified`, one requirement per plan, then `must_haves.truths`, `artifacts`, and `key_links`.

- `68-01-PLAN.md` lines 1-65
- `68-02-PLAN.md` lines 1-66
- `68-03-PLAN.md` lines 1-66

```yaml
phase: 68
plan: 02
type: execute
wave: 1
files_modified:
  - guides/upgrade-path.md
  - guides/operator-surface.md
  - CHANGELOG.md
  - mix.exs
  - test/threadline/operator_surface_doc_contract_test.exs
  - test/threadline/upgrade_path_doc_contract_test.exs
must_haves:
  truths:
  artifacts:
  key_links:
```

**Task/body pattern**  
Copy the `<objective>`, `<context>`, `<tasks>`, `<verification>`, `<success_criteria>` sections verbatim as the planning skeleton.

- `68-01-PLAN.md` lines 68-199
- `68-03-PLAN.md` lines 69-197

**Phase 69 planning implication**  
Follow the same split:

1. `69-01`: canonical integration contract doc + cross-links.
2. `69-02`: support-lane / support-matrix wording updates + focused doc-contract tests.
3. `69-03`: proof-anchor / verification wording only if docs need CI-evidence reconciliation.

### 2. Document concrete seams; do not invent a new abstraction layer

**Primary analogs:** [lib/threadline/plug.ex](/Users/jon/projects/threadline/lib/threadline/plug.ex:19), [lib/threadline/job.ex](/Users/jon/projects/threadline/lib/threadline/job.ex:21), [lib/threadline/integrations/sigra.ex](/Users/jon/projects/threadline/lib/threadline/integrations/sigra.ex:14)

**Request-path contract pattern**  
`Threadline.Plug` is documented and implemented as one actor callback plus one additive context callback.

- [lib/threadline/plug.ex](/Users/jon/projects/threadline/lib/threadline/plug.ex:21)
- [lib/threadline/plug.ex](/Users/jon/projects/threadline/lib/threadline/plug.ex:84)

```elixir
- `:actor_fn` — ... extracts the current actor from the conn.
- `:context_overrides_fn` — ... additive `:request_id` and `:correlation_id` values only.

%AuditContext{
  actor_ref: extract_actor(conn, actor_fn),
  request_id: extract_request_id(conn),
  correlation_id: get_req_header(conn, "x-correlation-id") |> List.first(),
  remote_ip: format_ip(conn.remote_ip)
}
|> apply_context_overrides(conn, context_overrides_fn)
```

**Fail-closed additive-only validation pattern**  
This is the wording and behavior Phase 69 should treat as contract, not restate loosely.

- [lib/threadline/plug.ex](/Users/jon/projects/threadline/lib/threadline/plug.ex:116)

```elixir
@allowed_override_keys [:request_id, :correlation_id]
...
raise ArgumentError,
  "unknown audit context override keys: ..."
```

**Job-path contract pattern**  
`Threadline.Job` is intentionally simpler: explicit serialized `"actor_ref"`, extracted `"correlation_id"` and `"job_id"`, no runner coupling.

- [lib/threadline/job.ex](/Users/jon/projects/threadline/lib/threadline/job.ex:21)
- [lib/threadline/job.ex](/Users/jon/projects/threadline/lib/threadline/job.ex:43)
- [lib/threadline/job.ex](/Users/jon/projects/threadline/lib/threadline/job.ex:60)

```elixir
def actor_ref_from_args(%{"actor_ref" => actor_ref_map}) when is_map(actor_ref_map) do
  ActorRef.from_map(actor_ref_map)
end

base = [
  correlation_id: Map.get(args, "correlation_id"),
  job_id: Map.get(args, "job_id")
]
```

**Reference adapter pattern**  
`Threadline.Integrations.Sigra` is the concrete model for `Threadline.Integrations.*`: soft-gated, host-owned, returns neutral defaults, exposes direct callback helpers.

- [lib/threadline/integrations/sigra.ex](/Users/jon/projects/threadline/lib/threadline/integrations/sigra.ex:19)
- [lib/threadline/integrations/sigra.ex](/Users/jon/projects/threadline/lib/threadline/integrations/sigra.ex:33)
- [lib/threadline/integrations/sigra.ex](/Users/jon/projects/threadline/lib/threadline/integrations/sigra.ex:55)
- [lib/threadline/integrations/sigra.ex](/Users/jon/projects/threadline/lib/threadline/integrations/sigra.ex:67)

```elixir
if sigra_available?() do
  ...
else
  nil
end

def actor_fn, do: &actor_ref_from_conn/1
defp sigra_available?, do: Code.ensure_loaded?(Sigra.Session)
```

### 3. Treat operator-surface auth as one contract with two transports

**Primary analogs:** [lib/threadline/operator_surface/auth.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/auth.ex:9), [lib/threadline/operator_surface/export_auth_plug.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/export_auth_plug.ex:3), [lib/threadline/operator_surface/router.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/router.ex:7)

**LiveView-side auth contract**  
- [lib/threadline/operator_surface/auth.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/auth.ex:9)

```elixir
case authorize_fn.(socket) do
  :ok -> {:cont, socket}
  true -> {:cont, socket}
  {:ok, scope} when is_map(scope) ->
    {:cont, Phoenix.Component.assign(socket, :threadline_scope, scope)}
  _ ->
    {:halt, redirect(socket, to: "/")}
end
```

**HTTP export-side parity contract**  
The export plug uses the same telemetry event, same result vocabulary, same `:threadline_scope`, and a deliberate synthetic mirror fallback.

- [lib/threadline/operator_surface/export_auth_plug.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/export_auth_plug.ex:7)
- [lib/threadline/operator_surface/export_auth_plug.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/export_auth_plug.ex:43)
- [lib/threadline/operator_surface/export_auth_plug.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/export_auth_plug.ex:81)

```elixir
case export_authorize_fn do
  fun when is_function(fun, 1) -> fn -> fun.(conn) end
  nil ->
    fn ->
      mirror = %{assigns: conn.assigns}
      authorize_fn.(mirror)
    end
end
```

**Secure-by-default mount contract**  
Phase 69 should cite the router macro as the support boundary for surface mounting.

- [lib/threadline/operator_surface/router.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/router.ex:41)
- [lib/threadline/operator_surface/router.ex](/Users/jon/projects/threadline/lib/threadline/operator_surface/router.ex:59)

```elixir
if not (_has_pipe? or unquote(has_auth_fn?) or unquote(has_ack?)) do
  raise CompileError,
    description:
      "Threadline Operator Surface must be mounted inside a secure pipeline..."
end
```

### 4. Lock docs by asserting headings, literals, and anti-overclaim wording directly

**Primary analogs:** [test/threadline/upgrade_path_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/upgrade_path_doc_contract_test.exs:5), [test/threadline/integrations/sigra_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_doc_contract_test.exs:11), [test/threadline/operator_surface_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface_doc_contract_test.exs:32)

**Section-heading lock pattern**  
- [test/threadline/upgrade_path_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/upgrade_path_doc_contract_test.exs:5)

```elixir
assert String.contains?(guide, "## Who this guide is for")
assert String.contains?(guide, "## Supported compatibility matrix")
assert String.contains?(guide, "## Canonical references")
```

**Exact-literal support-claim lock pattern**  
- [test/threadline/upgrade_path_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/upgrade_path_doc_contract_test.exs:32)

```elixir
assert String.contains?(guide, "exact dependency ranges Threadline declares and CI-covers in this release")
assert String.contains?(guide, "Anything outside the listed ranges is not claimed, even if it may work.")
refute String.contains?(guide, "Phoenix 1.7+")
```

**Guide marker + section-order pattern**  
- [test/threadline/integrations/sigra_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/integrations/sigra_doc_contract_test.exs:11)

```elixir
assert String.contains?(doc, "<!-- SIGRA-03-INTEGRATION-GUIDE -->")
{idx_install, _} = :binary.match(doc, "## Install")
...
assert idx_install < idx_plug
```

**Scope-boundary doc-contract pattern**  
- [test/threadline/operator_surface_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/operator_surface_doc_contract_test.exs:32)

```elixir
assert String.contains?(guide, "guides/upgrade-path.md")
refute String.contains?(guide, "## Supported compatibility matrix")
```

**Phase 69 planning implication**  
Use one focused source-reading contract test per doc surface. Do not rely on broad markdown snapshots.

### 5. Use named Mix aliases and stable CI job IDs as proof anchors

**Primary analogs:** [mix.exs](/Users/jon/projects/threadline/mix.exs:67), [.github/workflows/ci.yml](/Users/jon/projects/threadline/.github/workflows/ci.yml:1)

**Canonical alias pattern**  
- [mix.exs](/Users/jon/projects/threadline/mix.exs:67)

```elixir
"verify.format": ["format --check-formatted"],
"verify.credo": ["credo --strict"],
"verify.test": ["test"],
"verify.doc_contract": ["test test/threadline/readme_doc_contract_test.exs"],
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

**Stable job-ID pattern**  
- [.github/workflows/ci.yml](/Users/jon/projects/threadline/.github/workflows/ci.yml:1)
- [.github/workflows/ci.yml](/Users/jon/projects/threadline/.github/workflows/ci.yml:15)

```yaml
# Job id contract — stable YAML `jobs:` keys are relied on by docs and `act`:
# verify-format, verify-credo, verify-compile-no-optional, verify-test, verify-pgbouncer-topology, verify-docs, verify-hex-package, verify-release-shape
jobs:
  verify-format:
  verify-credo:
  verify-compile-no-optional:
  verify-test:
  verify-pgbouncer-topology:
  verify-docs:
```

**Important planning note (inference from sources)**  
`mix verify.doc_contract` is currently narrow: it runs only `test/threadline/readme_doc_contract_test.exs` in [mix.exs](/Users/jon/projects/threadline/mix.exs:73), while CI's `verify-test` job separately runs `mix verify.doc_contract` after `mix verify.example` in [.github/workflows/ci.yml](/Users/jon/projects/threadline/.github/workflows/ci.yml:113). Phase 69 should therefore verify new contract docs with explicit `mix test ...doc_contract...` commands unless widening `verify.doc_contract` is itself in scope.

## Shared Patterns

### Contract posture
- Prefer concrete seams over new behaviors/protocols. The best analogs are `Threadline.Plug`, `Threadline.Job`, and `Threadline.Integrations.Sigra`.

### Auth/export composition
- Keep one shared authorization story across LiveView and HTTP exports: same telemetry event, same result atoms, same scope assign, explicit `export_authorize_fn`, and documented fallback to synthetic `%{assigns: conn.assigns}`.

### Support claims
- Support language must point to named repo proof: `mix verify.compile_no_optional`, `mix verify.test`, `mix verify.example`, specific CI jobs, and exact dependency declarations. Avoid ecosystem-wide compatibility prose.

### Doc-contract style
- Lock headings, markers, route literals, and anti-broadening phrases with direct `String.contains?/2` assertions and occasional `refute`.

### Verification entrypoints
- For plan verification text, prefer these anchors:
  - `mix verify.compile_no_optional`
  - `mix verify.test`
  - `mix verify.example`
  - targeted `mix test test/threadline/...doc_contract_test.exs`
  - `mix ci.all`
  - CI job IDs `verify-compile-no-optional`, `verify-test`, `verify-docs`

## No Analog Found

| File / Need | Reason |
|---|---|
| A single existing “integration contract” guide spanning Plug + Job + Integrations + operator-surface auth/export | The repo has the pieces split across `guides/upgrade-path.md`, `guides/integrations/sigra.md`, and module docs, but no prior guide combines them into one breadth contract. Use those three as the composite analog. |

## Metadata

**Analog search scope:** `.planning/phases/68-*`, `lib/threadline/*`, `lib/threadline/operator_surface/*`, `guides/*`, `guides/integrations/*`, `test/threadline/*doc_contract*`, `mix.exs`, `.github/workflows/ci.yml`  
**Key repo pattern:** docs phases split by contract surface first, then by verification/proof surface.  
**Best-fit Phase 69 shape:** one plan for the canonical contract doc, one for support-lane wording/tests, one only if CI-proof wording needs a dedicated reconciliation slice.
