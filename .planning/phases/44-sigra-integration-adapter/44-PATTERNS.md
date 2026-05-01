# Phase 44: sigra-integration-adapter — Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 9 (5 to create, 4 to modify)
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/threadline/integrations/sigra.ex` (NEW) | adapter / value-extractor | request-response (read conn → return value) | `lib/threadline/job.ex` + `lib/threadline/plug.ex` | role-match (no in-tree soft-dep precedent yet) |
| `test/support/sigra_test_doubles.ex` (NEW) | test support / loader | compile-time scaffolding | `test/support/repo.ex` (loader mechanism) + `test/support/data_case.ex` (file shape) | role-match |
| `test/threadline/integrations/sigra_test.exs` (NEW) | unit test | request-response | `test/threadline/plug_test.exs` (Plug.Conn fixture pattern) + `test/threadline/semantics/actor_ref_test.exs` (case-table pattern) | exact |
| `test/threadline/integrations/sigra_doc_contract_test.exs` (NEW) | doc-contract test | file-I/O | `test/threadline/stg_doc_contract_test.exs` (per CONTEXT D-13) | exact |
| `guides/integrations/sigra.md` (NEW) | ExDoc extra (markdown guide) | file-I/O (rendered doc) | `guides/audit-indexing.md` (anchor + sectioned-table conventions) | role-match |
| `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` (MODIFY) | example shim | request-response | itself, before edit (pure replacement) | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (MODIFY) | Phoenix router | request-response | itself, before edit (pipeline insertion) | exact |
| `examples/threadline_phoenix/mix.exs` (MODIFY) | build config | n/a (declarative) | itself, before edit (deps list append) | exact |
| `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs` (MODIFY) | integration test | request-response | itself, before edit (assertion update — RESEARCH §Landmines #4 / Phase 23 stub pin) | exact |

## Pattern Assignments

### `lib/threadline/integrations/sigra.ex` (adapter, request-response) — NEW

**Closest analog:** `lib/threadline/job.ex` (and the consumer `lib/threadline/plug.ex` for the `:actor_fn` contract).

**Why this match:** No existing module in `lib/threadline/` uses the `Code.ensure_loaded?` soft-dep guard pattern (verified by reading the directory listing — no `Threadline.Integrations.*` namespace exists today). The closest functional analog is `Threadline.Job`: a small helpers module that reads a context-bearing data structure (job `args` map) and returns `{:ok, ActorRef}`/`nil` via `ActorRef.new/2`, with a clear `@moduledoc` linking usage. The consumer side — how the adapter's output flows downstream — is locked by `Threadline.Plug`'s `:actor_fn` contract and its `extract_actor/2` private helper.

**Imports / aliases pattern** — `lib/threadline/job.ex:33`:
```elixir
alias Threadline.Semantics.ActorRef
```
The adapter must mirror this exactly: a single `alias` for `Threadline.Semantics.ActorRef`. The adapter MUST NOT add `alias Sigra.Session` or any Sigra alias — the modules are referenced via fully-qualified `Code.ensure_loaded?(Sigra.Session)` only, never aliased (would force a compile-time dep).

**`@moduledoc` shape** — `lib/threadline/job.ex:1-31`:
```elixir
defmodule Threadline.Job do
  @moduledoc """
  Helpers for propagating audit context through background job `args` maps.

  Context is explicitly passed via serializable maps and never stored in process
  state, ETS, or a process dictionary. This satisfies CTX-05 and keeps helpers
  testable as pure functions.

  ## Usage in a worker

      def perform(%{args: args}) do
        with {:ok, actor_ref} <- Threadline.Job.actor_ref_from_args(args) do
          ...
```
Replicate: short paragraph stating purpose, `## Usage` section with copy-pasteable Elixir block, link to the integration guide (`See \`guides/integrations/sigra.md\` for the wiring contract.`). CONTEXT line 114 explicitly establishes this `@moduledoc + guide-link` convention.

**Public-function `@doc` shape** — `lib/threadline/job.ex:35-47`:
```elixir
@doc """
Extracts an `ActorRef` from a job args map.

Looks for an `"actor_ref"` key containing a map serialized by
`ActorRef.to_map/1`.

Returns `{:ok, %ActorRef{}}` or `{:error, reason}`.
"""
def actor_ref_from_args(%{"actor_ref" => actor_ref_map}) when is_map(actor_ref_map) do
  ActorRef.from_map(actor_ref_map)
end

def actor_ref_from_args(_args), do: {:error, :missing_actor_ref}
```
Replicate: docstring describes purpose + return shape; multi-clause function with explicit fallback on the last line. Phase 44 adapter's three public functions (`actor_ref_from_conn/1`, `audit_context_overrides_from_conn/1`, `actor_fn/0`) follow the same docstring → multi-clause pattern.

**ActorRef construction pattern** — `lib/threadline/job.ex:43-44` (delegate to `ActorRef.from_map`) and the more direct construction validated in RESEARCH §"Code Examples" (lines 733–741):
```elixir
def new(type, _id) when type not in @types, do: {:error, :unknown_actor_type}
def new(:anonymous, _id), do: {:ok, %__MODULE__{type: :anonymous, id: nil}}
def new(type, id) when id in [nil, ""], do: {:error, :missing_actor_id}
def new(type, id) when is_binary(id), do: {:ok, %__MODULE__{type: type, id: id}}
```
Pattern to copy: always wrap `ActorRef.new(type, id)` in a `case`/`with` and return `nil` on `{:error, _}`. RESEARCH §Code Examples line 540-542 shows the exact form:
```elixir
case ActorRef.new(:admin, get_id(from)) do
  {:ok, ref} -> ref
  {:error, _} -> nil
end
```
The example app's pre-edit `audit_actor.ex:10-13` ALSO uses this exact pattern — adapter must match.

**Soft-dep guard pattern** — no in-tree precedent; canonical form locked in CONTEXT D-04 + RESEARCH §"Pattern 1" (lines 503-565):
```elixir
def actor_ref_from_conn(conn) do
  if Code.ensure_loaded?(Sigra.Session) do
    do_actor_ref(conn)
  else
    nil
  end
end
```
Single gate via `Code.ensure_loaded?(Sigra.Session)` — never gate on `Sigra.Scope`, never gate on `Sigra.APIToken` (RESEARCH §Sigra Public Surface confirms no struct).

**Conn-shape detection pattern** — locked by CONTEXT D-08 + D-09 (use `Map.get/3`, never dot-access):
```elixir
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
```
**RESEARCH-driven adjustment** (Landmine §1): API-token detection is `Map.get(scope, :auth_method) in [:api_token, :jwt]` — NOT `conn.assigns[:current_api_token]`. The user_id comes from `Map.get(scope, :id)`.

**Function-reference factory pattern** — `lib/threadline/plug.ex:78` consumes `actor_fn` as `fun.(conn)`. The adapter's `actor_fn/0` returns the captured ref:
```elixir
@spec actor_fn() :: (Plug.Conn.t() -> ActorRef.t() | nil)
def actor_fn, do: &actor_ref_from_conn/1
```
RESEARCH §Pitfalls #5 (lines 698-708): `actor_fn/0` is a factory, not a runtime call. Tests verify via `assert is_function(adapter.actor_fn(), 1)`.

**Anti-patterns to avoid** (from RESEARCH §"Anti-Patterns to Avoid", lines 634-643):
- No pattern-matching on `%Sigra.Scope{}` or `%Sigra.APIToken{}` (production scope is host-named).
- No `:anonymous` literal anywhere in the adapter source (Q6 acceptance: `grep ':anonymous' lib/threadline/integrations/sigra.ex` must return zero).
- No direct `ActorRef` struct literals — always `ActorRef.new/2`.

---

### `test/support/sigra_test_doubles.ex` (test support, compile-time loader) — NEW

**Closest analog:** `test/support/repo.ex` for the `elixirc_paths(:test)` loader mechanism; `test/support/data_case.ex` for the `defmodule` placement under `test/support/`.

**Why this match:** Both existing files demonstrate that `test/support/*.ex` files are precompiled by `mix.exs:44` `elixirc_paths(:test), do: ["lib", "test/support"]` — the same mechanism Phase 44 needs. CONTEXT D-03 explicitly forbids `Code.require_file` in `test_helper.exs`. CONTEXT D-04 places the `unless Code.ensure_loaded?(Sigra.Session)` guard at the top of the file.

**Loader pattern** — `mix.exs:44-45` (already in place — no edit needed):
```elixir
defp elixirc_paths(:test), do: ["lib", "test/support"]
defp elixirc_paths(_), do: ["lib"]
```
RESEARCH §Test-Double Loader Mechanism line 252 confirms: "**No mix.exs change required for the loader.** New file `test/support/sigra_test_doubles.ex` will be picked up automatically when `MIX_ENV=test`."

**Existing minimalist `test/support/*.ex` shape** — `test/support/repo.ex:1-5` (verbatim):
```elixir
defmodule Threadline.Test.Repo do
  use Ecto.Repo,
    otp_app: :threadline,
    adapter: Ecto.Adapters.Postgres
end
```
Replicate: terse `defmodule` blocks at top level of file, no module-level extras beyond what's strictly needed.

**Guard wrapping pattern** — locked by CONTEXT D-04 + RESEARCH §Test-Double Loader (lines 263-281). Verbatim block to ship:
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
Three nested `defmodule` blocks, all under one `unless` guard. The `@moduledoc false` is mandatory (these are test scaffolding; ExDoc must not surface them).

**Field-list source** — CONTEXT D-05 (verbatim):
- `Sigra.Session` — `:id, :user_id, :active_organization_id, :impersonator_user_id, :impersonator_session_id`
- `Sigra.Scope` — `:user, :active_organization, :membership, :impersonating_from`
- `Sigra.APIToken` — `:user_id, :id`

RESEARCH §Sigra Library Public Surface (line 90) confirms these are the only adapter-read fields out of the real `Sigra.Session`'s 16 fields.

---

### `test/threadline/integrations/sigra_test.exs` (unit test, request-response) — NEW

**Closest analog:** `test/threadline/plug_test.exs` (Plug.Conn fixture construction) + `test/threadline/semantics/actor_ref_test.exs` (case-table iteration with `for type <- ...`).

**Why this match:** `plug_test.exs` is the canonical example of testing a Plug-conn-reading helper in this codebase: it imports `Plug.Test` + `Plug.Conn`, builds conns with `conn(:get, "/")`, and calls the unit-under-test with synthesized assigns/headers. `actor_ref_test.exs` shows the case-table iteration idiom used to cover the four Sigra request shapes × axes (header, org, env).

**`use` + imports pattern** — `test/threadline/plug_test.exs:1-8` (verbatim):
```elixir
defmodule Threadline.PlugTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  alias Threadline.Plug, as: ThreadlinePlug
  alias Threadline.Semantics.{ActorRef, AuditContext}
```
Replicate: `use ExUnit.Case, async: true` (NOT `Threadline.DataCase` — no DB), `import Plug.Test`, `import Plug.Conn`, alias the adapter under test.

**Conn fixture pattern** — `plug_test.exs:42-49`:
```elixir
test "actor_fn: option sets actor_ref from the function result" do
  {:ok, ref} = ActorRef.new(:user, "u-1")

  conn =
    conn(:get, "/")
    |> call(actor_fn: fn _conn -> ref end)

  assert conn.assigns[:audit_context].actor_ref == ref
end
```
For Phase 44 the conn fixtures inject `current_scope` directly via `Plug.Conn.assign/3` (or by direct `%{conn | assigns: ...}` map update — see `plug_test.exs:61` `%{conn(:get, "/") | remote_ip: {127, 0, 0, 1}}`). Use `put_req_header("x-correlation-id", "explicit-cid")` to test the header-wins axis (`plug_test.exs:30-32` is the verbatim header pattern).

**Case-table iteration pattern** — `test/threadline/semantics/actor_ref_test.exs:11-17`:
```elixir
test "all six actor types accept valid construction" do
  for type <- ~w(user admin service_account job system)a do
    assert {:ok, %ActorRef{type: ^type}} = ActorRef.new(type, "id-1")
  end

  assert {:ok, %ActorRef{type: :anonymous, id: nil}} = ActorRef.new(:anonymous)
end
```
Use this idiom for the `four-shape × org-on/off` matrix in `sigra_test.exs`. RESEARCH §"Test Fixture Matrix" (line 442+) sets the test count target: ~18 base tests + 3 negative-path tests.

**`describe` blocks pattern** — `actor_ref_test.exs:6-38` groups related tests under `describe "new/2" do ... end`. Replicate one `describe` per adapter function: `describe "actor_ref_from_conn/1" do`, `describe "audit_context_overrides_from_conn/1" do`, `describe "actor_fn/0" do`.

**Soft-dep test note:** Tests run with `Sigra.Session` defined as a shim (from `sigra_test_doubles.ex`), so `Code.ensure_loaded?(Sigra.Session)` returns true in the library test env. The "Sigra-absent" branch (returns `nil`/`%{}`) is exercised by passing conns with no `current_scope` (the three baseline shapes per Acceptance Criterion line 108).

---

### `test/threadline/integrations/sigra_doc_contract_test.exs` (doc-contract, file-I/O) — NEW

**Closest analog:** `test/threadline/stg_doc_contract_test.exs` (per CONTEXT D-13 — verbatim source for this pattern). Secondary reference: `test/threadline/exploration_routing_doc_contract_test.exs` for the ordering-assertion idiom (`:binary.match/2`).

**Why this match:** CONTEXT D-13 explicitly names `stg_doc_contract_test.exs` and `audit_indexing_doc_contract_test.exs` as the correct analogs and EXPLICITLY rejects `readme_doc_contract_test.exs` (which uses `Threadline.DataCase` because it loads DB fixtures). RESEARCH §Doc-Contract Test Idiom (line 293) confirms: "FOUR use `ExUnit.Case, async: true`, ONE uses `Threadline.DataCase`."

**Verbatim header to copy** — `test/threadline/stg_doc_contract_test.exs:1-9`:
```elixir
defmodule Threadline.StgDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end
```
Phase 44 module name: `Threadline.Integrations.SigraDocContractTest` (matches `test/threadline/integrations/sigra_doc_contract_test.exs` path → Mix path-to-module convention; RESEARCH line 317).

**Test-block pattern (one block per locked literal group)** — `stg_doc_contract_test.exs:11-26`:
```elixir
test "CONTRIBUTING documents host STG evidence for integrators" do
  doc = read_rel!(["CONTRIBUTING.md"])
  assert String.contains?(doc, "## Host STG evidence (integrators)")
end

test "production checklist points to backlog STG rubric" do
  doc = read_rel!(["guides", "production-checklist.md"])
  assert String.contains?(doc, "STG-AUDITED-PATH-RUBRIC")
  assert String.contains?(doc, "guides/adoption-pilot-backlog.md")
end
```
Each `test` block reads the doc once via `read_rel!/1`, then makes one or more `String.contains?/2` assertions on locked literals. CONTEXT D-14 enumerates the literals to lock (5 groups: install snippet, Plug-callback line, six SPEC outcomes, four `correlation_id` formats, soft-dep contract).

**For-loop assertion pattern** (when locking a list of literals) — `audit_indexing_doc_contract_test.exs:16-27`:
```elixir
for heading <- [
      "## Installed defaults",
      "### audit_transactions",
      ...
    ] do
  assert String.contains?(doc, heading)
end
```
Replicate this for the four `correlation_id` format strings (`sigra-imp:`, `sigra-session:`, `sigra-token:`, anonymous-`%{}` mention) and the six SPEC outcome statements.

**Ordering-assertion pattern** (RESEARCH §Pitfall #4 line 691 — needed to defeat "empty guide passes" failure mode) — `exploration_routing_doc_contract_test.exs:20-22`:
```elixir
{idx_routing, _} = :binary.match(doc, "## Exploration API routing (v1.10+)")
{idx_support, _} = :binary.match(doc, "## Support incident queries")
assert idx_routing < idx_support
```
Use at minimum once in `sigra_doc_contract_test.exs` to assert the install-snippet section appears before the Plug-callback wire-up section.

**Anti-pattern to avoid** — DO NOT copy `readme_doc_contract_test.exs:1-3`:
```elixir
defmodule Threadline.ReadmeDocContractTest do
  @moduledoc false
  use Threadline.DataCase   # WRONG for Phase 44 — DB fixtures not needed
```
Per CONTEXT D-13 + RESEARCH line 326. This file uses `DataCase` solely because it loads `Threadline.ReadmeQuickstartFixtures` and calls `Repo.transaction`. The Sigra doc-contract test reads markdown only.

---

### `guides/integrations/sigra.md` (ExDoc extra, markdown guide) — NEW

**Closest analog:** `guides/audit-indexing.md` (anchor-comment header convention + sectioned-table layout); secondary `guides/brownfield-continuity.md` for paragraph-level prose tone.

**Why this match:** No `guides/integrations/` directory exists yet. Of the five existing guides, `audit-indexing.md` is closest in shape: it ships an HTML-comment anchor (`<!-- IDX-02-AUDIT-INDEXING -->`) for the doc-contract test to lock, uses `## Section` headings paired with paired-test assertions, and combines copy-pasteable code snippets with operator prose. Phase 44 needs the same anchor + section-heading shape to support the doc-contract test's `String.contains?` assertions.

**Anchor-comment header pattern** — `guides/audit-indexing.md:1-5`:
```markdown
# Audit table indexing cookbook

<!-- IDX-02-AUDIT-INDEXING -->

This guide is the **integrator-owned** place for PostgreSQL index strategy on Threadline's audit tables.
```
Replicate: H1 title, blank line, HTML-comment anchor on its own line, blank line, lead paragraph. Suggested anchor for Phase 44: `<!-- SIGRA-03-INTEGRATION-GUIDE -->` (ties to SPEC requirement 9 / SIGRA-03 ID).

**Section ordering pattern** — `guides/brownfield-continuity.md` H2 sequence (`## Semantics (T0)`, `## Operator checklist`, `## Compliance snapshot`, `## PgBouncer / transactions`). Phase 44 must ship the five sections required by SPEC requirement 9 in stable order:
1. `## Install` — the snippet `{:sigra, "~> 0.2", optional: true}` (lock literal)
2. `## Plug callback wire-up` — the line `plug Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1` (lock literal verbatim)
3. `## Behaviors locked by SPEC` — the six outcome statements (impersonation→admin, API token→service_account, org→correlation_id suffix, anonymous→nil, header-wins, Plug-only)
4. `## correlation_id formats` — four literal formats (`sigra-imp:`, `sigra-session:`, `sigra-token:`, anonymous=`%{}`)
5. `## Soft-dep contract` — the `Code.ensure_loaded?(Sigra.Session)` fallback explanation

**Two-plug pipeline snippet** (per CONTEXT D-10 + D-12) — must be copy-pasteable:
```elixir
plug MyApp.SigraContextPlug
plug Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1
```
With the `SigraContextPlug` body inline (~5 lines using `get_req_header`/`put_req_header` mirroring `Plug.RequestId`'s check-before-set idiom — RESEARCH §Pattern 2 lines 575-598 has the verbatim form).

**Forward-pointer note pattern** (per CONTEXT D-11) — one paragraph or callout pointing at the future `:context_overrides_fn` Plug option, no timeline commitment.

**Hex-package inclusion** — RESEARCH line 423 confirms `mix.exs:106` `:files` glob (`guides`) already includes the new file in the published tarball. Phase 44 does NOT modify `mix.exs:115-129` `extras:` list (that's Phase 48 / REL-02).

---

### `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex` (MODIFY) — example shim

**Closest analog:** itself, before edit (verbatim source below).

**Pre-edit content** — `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex:1-15`:
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

**Target content** (per RESEARCH §"Example App Insertion Points" lines 351-355 + SPEC requirement 8):
```elixir
defmodule ThreadlinePhoenix.AuditActor do
  @moduledoc false
  defdelegate from_conn(conn), to: Threadline.Integrations.Sigra, as: :actor_ref_from_conn
end
```

**Pattern to replicate:** keep the `@moduledoc false` (consistent with all four other internal example modules); use `defdelegate` because the soft-dep guard in `Threadline.Integrations.Sigra.actor_ref_from_conn/1` already returns `nil` when Sigra is absent — no `case`-wrapping needed. The function arity (1) and name (`from_conn`) are preserved for backward compatibility with `router.ex:6`.

---

### `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` (MODIFY) — Phoenix router

**Closest analog:** itself, before edit.

**Pre-edit pipeline** — `router.ex:4-7`:
```elixir
pipeline :api do
  plug(:accepts, ["json"])
  plug(Threadline.Plug, actor_fn: &ThreadlinePhoenix.AuditActor.from_conn/1)
end
```

**Target pipeline** (per CONTEXT D-10 + D-12, RESEARCH lines 369-376):
```elixir
pipeline :api do
  plug(:accepts, ["json"])
  plug(ThreadlinePhoenixWeb.SigraContextPlug)
  plug(Threadline.Plug, actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1)
end
```

**Pattern to replicate:** the parenthesized `plug(...)` style is already established in `router.ex:5-6`; new lines must use the same style. The `:actor_fn` callback target switches from the example's `AuditActor.from_conn/1` to the adapter's `Threadline.Integrations.Sigra.actor_ref_from_conn/1` directly — eliminating the wrapper indirection (the `audit_actor.ex` `defdelegate` remains for backward compatibility with anything else that calls it).

**`SigraContextPlug` sibling file** — new at `examples/threadline_phoenix/lib/threadline_phoenix_web/sigra_context_plug.ex` per RESEARCH §"Recommended File Structure" (line 624). Verbatim body locked in RESEARCH lines 575-598 (Plug.RequestId check-before-set pattern). NOT counted in the original "files to create" list above; flag for planner.

---

### `examples/threadline_phoenix/mix.exs` (MODIFY) — build config

**Closest analog:** itself, before edit.

**Pre-edit `defp deps`** — `mix.exs:40-54`:
```elixir
defp deps do
  [
    {:threadline, path: "../.."},
    {:phoenix, "~> 1.8.5"},
    {:phoenix_ecto, "~> 4.5"},
    {:ecto_sql, "~> 3.13"},
    {:postgrex, ">= 0.0.0"},
    {:telemetry_metrics, "~> 1.0"},
    {:telemetry_poller, "~> 1.0"},
    {:jason, "~> 1.2"},
    {:dns_cluster, "~> 0.2.0"},
    {:bandit, "~> 1.5"},
    {:oban, "~> 2.19"}
  ]
end
```

**Target deps list** — append `{:sigra, "~> 0.2", optional: true}` as the last entry (consistent with the existing trailing-element style — no trailing comma in current code):
```elixir
{:oban, "~> 2.19"},
{:sigra, "~> 0.2", optional: true}
```

**Pattern to replicate:** maintain the two-space indent and the `{:atom, "version"}` tuple shape used throughout the existing list. The `optional: true` keyword arg is the discriminator that allows the example to compile and test without forcing Sigra to be present at every fetch (RESEARCH line 386).

**Library `mix.exs` (NOT modified):** RESEARCH line 391 + SPEC line 95 + Acceptance Criterion line 106 — `grep -E '\{:sigra' mix.exs` MUST return zero matches at the library root after the phase. Critical CI gate.

---

### `examples/threadline_phoenix/test/threadline_phoenix_web/posts_audit_path_test.exs` (MODIFY) — integration test fix

**Closest analog:** itself, before edit (per RESEARCH §Landmines #4 — pinned old-stub assertion).

**Pre-edit assertion** — `posts_audit_path_test.exs:35-39`:
```elixir
assert %Threadline.Semantics.ActorRef{
         type: :service_account,
         id: "threadline-phoenix-example"
       } =
         at.actor_ref
```

**Why this changes:** RESEARCH §Summary Finding #3 (line 17) and Landmines §3: "After Phase 44 this test will receive `actor_ref = nil` (anonymous fallback per Q6) because the test conn carries no Sigra session." SPEC requirement 8 line 62 states "existing example test suite continues to pass without modification" — RESEARCH explicitly flags this is incorrect; this test MUST change.

**Target assertion** (Q6 anonymous fallback — `actor_ref` is nil when no `current_scope` is set on the test conn):
```elixir
assert at.actor_ref == nil
```

OR — if the test is updated to set up a Sigra-shape conn fixture (more work, more representative): construct the conn with a synthetic `%Sigra.Scope{user: %{id: "test-user-id"}}` via `assign(conn, :current_scope, ...)` and assert `%Threadline.Semantics.ActorRef{type: :user, id: "test-user-id"} = at.actor_ref`. The simpler `nil` assertion is recommended for Phase 44 — fixture upgrade can come later.

**Pattern to replicate:** keep the existing `use ThreadlinePhoenixWeb.ConnCase, async: false`, `build_conn() |> ... |> post(...)` request flow, and the `Repo.all` query block (lines 22-29). Only the assertion at lines 35-39 changes. The `x-request-id` and `x-correlation-id` headers (lines 15-16) are unaffected — they continue to flow through `Threadline.Plug` unchanged.

---

## Shared Patterns

### Soft-dep guard (`Code.ensure_loaded?(Sigra.Session)`)
**Source:** No in-tree precedent; canonical form locked in CONTEXT D-04 + RESEARCH §Pattern 1.
**Apply to:** `lib/threadline/integrations/sigra.ex` (single gate at top of every public function); `test/support/sigra_test_doubles.ex` (single `unless` wrapping all three `defmodule` blocks).
```elixir
if Code.ensure_loaded?(Sigra.Session), do: do_real_path(conn), else: nil
```
**Critical:** never gate on `Sigra.Scope` or `Sigra.APIToken` (no struct in v0.2.5).

### `Map.get/3` for scope field reads (NEVER dot-access)
**Source:** RESEARCH §Sigra Library Public Surface lines 96-114 (mirrors Sigra's own `Sigra.Audit.scope_fields/1` private logic).
**Apply to:** every read from `current_scope` in the adapter.
```elixir
# CORRECT
user = Map.get(scope, :user)
imp = Map.get(scope, :impersonating_from)

# WRONG — dot-access raises KeyError on host-defined scopes that omit optional fields
user = scope.user
```
CONTEXT D-09 explicit; RESEARCH §Pitfall #2 line 670 explains why.

### `ActorRef.new/2` (NEVER direct struct literals)
**Source:** `lib/threadline/semantics/actor_ref.ex:35-52` + `lib/threadline/job.ex:43-44` + `examples/threadline_phoenix/lib/threadline_phoenix/audit_actor.ex:10-13`.
**Apply to:** all `ActorRef` construction in `lib/threadline/integrations/sigra.ex` and the example `audit_actor.ex` (latter via `defdelegate`).
```elixir
case ActorRef.new(:user, id) do
  {:ok, ref} -> ref
  {:error, _} -> nil
end
```
RESEARCH §"Don't Hand-Roll" line 653 reinforces: validation centralized; defensive task can grep adapter source for direct `%ActorRef{...}` literals and assert zero matches.

### Doc-contract test header (`use ExUnit.Case, async: true` + `read_rel!/1`)
**Source:** `test/threadline/stg_doc_contract_test.exs:1-9` (verbatim shape).
**Apply to:** `test/threadline/integrations/sigra_doc_contract_test.exs`.
**Apply NOT to:** Anything else this phase. (`readme_doc_contract_test.exs` uses `DataCase`; that's a deliberate exception, not a model — CONTEXT D-13.)

### `String.contains?/2` for literal-presence assertions
**Source:** all five existing doc-contract tests.
**Apply to:** `test/threadline/integrations/sigra_doc_contract_test.exs` for all 5 literal groups (CONTEXT D-14).

### `:binary.match/2` for ordering assertions (anti-empty-doc safeguard)
**Source:** `test/threadline/exploration_routing_doc_contract_test.exs:20-22`.
**Apply to:** `test/threadline/integrations/sigra_doc_contract_test.exs` (at least once, to guard against the RESEARCH §Pitfall #4 "empty guide passes" failure mode).

### Plug `import` + `conn(:get, "/")` fixture pattern
**Source:** `test/threadline/plug_test.exs:1-15`.
**Apply to:** `test/threadline/integrations/sigra_test.exs` for all four-shape fixtures (anonymous baseline, user, admin-impersonating, API-token).

### Anchor-comment + sectioned-headings (markdown guide structure)
**Source:** `guides/audit-indexing.md:1-9`.
**Apply to:** `guides/integrations/sigra.md` — H1 + HTML-comment anchor + lead paragraph + five `## Section` headings in stable order.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `examples/threadline_phoenix/lib/threadline_phoenix_web/sigra_context_plug.ex` (RECOMMENDED NEW, per RESEARCH line 624) | Phoenix plug | request-response | No existing two-plug header-injection pattern in the example app; canonical form is `Plug.RequestId` (external dep). RESEARCH §Pattern 2 lines 575-598 has the verbatim body. Planner should add this to the file list. |

**Note:** the original "files to create" list in the spawn prompt did NOT include `sigra_context_plug.ex`, but RESEARCH §"Recommended File Structure" (lines 622-626) and §"Example App Insertion Points" (line 378) confirm this file is required for the two-plug pattern in CONTEXT D-12. Planner should consider adding to the file inventory.

---

## Metadata

**Analog search scope:**
- `lib/threadline/` — full tree (capture, retention, semantics, verify subdirs + top-level modules)
- `test/threadline/` — full tree including `capture/`, `semantics/`, `retention/`
- `test/support/` — all three existing files
- `guides/` — all five existing guides
- `examples/threadline_phoenix/lib/` and `examples/threadline_phoenix/test/` — full Phoenix example tree
- `mix.exs` (library) and `examples/threadline_phoenix/mix.exs`

**Files scanned:** 22 (3 lib modules read fully; 5 test files read fully; 4 example app files read fully; 4 guides sampled; 2 mix.exs files; 4 directory listings).

**Pattern extraction date:** 2026-05-01

---

## PATTERN MAPPING COMPLETE

**Phase:** 44 - sigra-integration-adapter
**Files classified:** 9 (5 to create, 4 to modify) + 1 recommended addition (`sigra_context_plug.ex`)
**Analogs found:** 9 / 9 (all original files); 1 file lacks an in-tree analog (`sigra_context_plug.ex` — canonical form locked in RESEARCH).

### Coverage
- Files with exact analog: 6 (the four "modify" files plus `sigra_test.exs` and `sigra_doc_contract_test.exs`)
- Files with role-match analog: 3 (`sigra.ex` adapter, `sigra_test_doubles.ex`, `sigra.md` guide)
- Files with no analog: 1 (`sigra_context_plug.ex` — recommended addition; canonical form in RESEARCH §Pattern 2)

### Key Patterns Identified
- **Soft-dep guard via `Code.ensure_loaded?(Sigra.Session)`** is the single gate; same form used for adapter functions and the test-doubles wrapper.
- **`ActorRef.new/2` constructor with `case`-wrapping** is the codebase convention for all ActorRef construction (verified in `Threadline.Job`, the pre-edit `audit_actor.ex`, and the `ActorRef` test suite).
- **`Map.get/3` for all conn/scope field reads** (never dot-access) — host-defined scopes may omit optional fields; CONTEXT D-09 + RESEARCH §Pitfall #2.
- **Doc-contract tests use `ExUnit.Case, async: true` + `@repo_root File.cwd!()` + `read_rel!/1` helper + `String.contains?/2` assertions**, with at least one `:binary.match/2` ordering assertion to guard against empty-doc false-passes (4 of 5 existing tests follow this pattern).
- **`test/support/*.ex` files are picked up automatically** via existing `elixirc_paths(:test)` in `mix.exs:44` — no mix.exs change required for the test-doubles loader.
- **Plug-test fixtures use `import Plug.Test` + `conn(:get, "/")` + `put_req_header/3`** for request-shape construction (verbatim from `plug_test.exs`).
- **Markdown guides ship an HTML-comment anchor** (`<!-- IDX-02-AUDIT-INDEXING -->`-style) on line 3 immediately after the H1, locked by the doc-contract test.
- **Library `mix.exs` is the immovable boundary** — `:sigra` may appear ONLY in `examples/threadline_phoenix/mix.exs`. CI gate via `grep -E '\{:sigra' mix.exs`.

### File Created
`/Users/jon/projects/threadline/.planning/phases/44-sigra-integration-adapter/44-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now reference analog patterns in PLAN.md files. RESEARCH-derived adjustments (API-token via `current_scope.auth_method`, posts_audit_path_test.exs assertion change, recommended `sigra_context_plug.ex` addition) are flagged for planner attention.
