# Phase 200: Public Surface - Pattern Map

**Mapped:** 2026-09-11
**Files analyzed:** 24 explicit files plus 4 bounded cohorts
**Analogs found:** 5 strong tracked analogs; 2 current in-place implementation seams

This map translates D-01 through D-29 into existing Threadline patterns. It does
not add a runtime abstraction, a docs site, operator UI work, release automation,
or any other work deferred beyond Phase 200.

## File Classification

| New/Modified File or Cohort | Role | Data Flow | Closest Tracked Analog | Match Quality |
|---|---|---|---|---|
| `mix.exs` | config / build | batch + transform | `mix.exs` | exact, in place |
| `guides/configuration-and-commands.md` (new) | documentation / reference | transform | `guides/getting-started-saas.md` | role match; change format from tutorial to exhaustive reference |
| `lib/threadline/storage.ex` | behavior / public API docs | request-response | existing `Threadline.Storage` behavior plus `lib/threadline/storage/{local,s3}.ex` | exact, in place |
| `lib/threadline/storage/local.ex` | service / adapter docs | file-I/O | existing `Threadline.Storage.Local` implementation | exact, in place |
| `lib/threadline/storage/s3.ex` | service / adapter docs | request-response | existing `Threadline.Storage.S3` implementation | exact, in place |
| `lib/threadline/operator_surface/controllers/export_controller.ex` | controller | request-response + file-I/O | its existing local/remote delivery split | exact, in place |
| `test/threadline/operator_surface/controllers/export_controller_test.exs` | integration test | request-response + file-I/O | its existing `RemoteStorageStub` and download describe block | exact, in place |
| `test/threadline/public_surface_contract_test.exs` (new) | contract test | batch + transform | `test/threadline/version_truth_doc_contract_test.exs` | role match |
| `test/threadline/guide_graph_contract_test.exs` (new) | graph/documentation contract test | batch + transform | `test/threadline/persona_routing_doc_contract_test.exs` | role match |
| `test/threadline/community_health_contract_test.exs` (new) | repository contract test | file-I/O + transform | `test/threadline/persona_routing_doc_contract_test.exs` | role match; no YAML-schema analog exists |
| `test/threadline/release_artifact_contract_test.exs` | package integration test | file-I/O + batch | itself | exact, in place |
| `README.md` | documentation / navigation hub | transform | existing intent-led README, guarded by `persona_routing_doc_contract_test.exs` | exact, in place |
| `CONTRIBUTING.md` | documentation / contributor workflow | transform | existing intent lanes plus canonical-owner guide pattern | role match |
| `CHANGELOG.md` | release documentation | append-only transform | existing unreleased changelog section | exact, in place |
| `guides/getting-started-saas.md` | canonical tutorial | sequential request-response | itself | exact, in place |
| `guides/operator-surface.md` | canonical operator how-to | request-response | `guides/getting-started-saas.md` heading/link structure | role match |
| `guides/local-docker-dx.md` | canonical environment runbook | process lifecycle + file-I/O | `guides/getting-started-saas.md` ordered procedure structure | role match |
| remaining `guides/**/*.md` | leaf documentation / graph nodes | transform | `guides/getting-started-saas.md` intro, descriptive links, terminal successor section | role match |
| `examples/threadline_phoenix/README.md` | example-app entrypoint | transform | README intent routing; canonical owners above | role match |
| D-09 mandatory hidden modules (6 files) | maintainer utility / Mix task | batch + transform | existing `@moduledoc false` modules, including `lib/mix/tasks/threadline/verify_topology.ex` | exact annotation pattern |
| D-10 visibility-audit candidates | internal model/service/controller/helper | CRUD, request-response, or transform | existing hidden operator modules and `verify_topology.ex` annotation pattern | role match, conditional on call-site audit |
| scanner-selected packaged source/doc files | public artifact content | batch + transform | `release_artifact_contract_test.exs` archive traversal | exact selection mechanism |
| `.github/ISSUE_TEMPLATE/01-bug.yml` (new) | intake form / config | request-response | none in repository | no analog |
| `.github/ISSUE_TEMPLATE/02-feature-request.yml` (new) | intake form / config | request-response | none in repository | no analog |
| `.github/ISSUE_TEMPLATE/03-question.yml` (new) | intake form / config | request-response | none in repository | no analog |
| `.github/ISSUE_TEMPLATE/config.yml` (new) | chooser config | request-response | none in repository | no analog |
| `.github/pull_request_template.md` (new) | intake template | request-response | none in repository | no analog |
| `SECURITY.md` (new) | security policy / routing | request-response | none in repository | no analog |
| `CODE_OF_CONDUCT.md` (new) | conduct policy / routing | request-response | none in repository | no analog |

### Bounded Cohort Membership

The planner should expand cohorts only as follows:

- **D-09 mandatory hidden files:**
  `lib/threadline/critic_trust/{measure,rank_metrics,ledger_splice,krippendorff_alpha}.ex`
  and `lib/mix/tasks/critic.{measure,synth}.ex`.
- **D-10 named audit candidates:**
  `lib/threadline/capture/{migration,redaction_policy,trigger_capture_config,trigger_sql}.ex`,
  `lib/threadline/export/cleanup_task.ex`,
  `lib/threadline/governance/{export_job,migration,retention_run,saved_view}.ex`,
  `lib/threadline/health/coverage_schemas.ex`,
  `lib/threadline/policy/redaction_presenter.ex`,
  `lib/threadline/retention/pruner.ex`, and
  `lib/threadline/semantics/migration.ex`, plus private operator-surface
  controller/live/component/hook/session/style/scope/presentation helpers.
  Do not hide a candidate until the required public call-path, return-type, and
  documentation-reference audit passes. Keep
  `lib/threadline/export/orchestrator.ex` visible because built-in queue adapters
  call its execution entry point.
- **Guide graph cohort:** all 18 tracked `guides/**/*.md` files. Each must be
  assigned exactly once to an existing intent lane, gain valid inbound and
  outbound edges, and end with a semantic `Next steps` section when it is a leaf.
- **Scanner-selected cohort:** files found by scanning the freshly unpacked Hex
  archive, not a hand-maintained working-tree list. The current diagnostic set
  includes `mix.exs`, `CONTRIBUTING.md`, `guides/brownfield-continuity.md`,
  `guides/domain-reference.md`, critic/task files, capture/query files, and
  operator-surface implementation files. The archive contract decides the final
  edit set and must allow zero exceptions.

## Pattern Assignments

### `mix.exs` (config/build, batch + transform)

**Analog:** `mix.exs` (tracked; extend its existing private helper boundaries)

**Version-derived URL pattern** (lines 355-372):

```elixir
defp doc_source_ref do
  case Version.parse(@version) do
    {:ok, %Version{pre: []}} -> "v#{@version}"
    _ -> "main"
  end
end

defp package do
  [
    # ...
    files:
      ~w(lib priv/fonts guides brandbook/favicon.svg .formatter.exs mix.exs README.md LICENSE CHANGELOG.md CONTRIBUTING.md)
  ]
end
```

Copy this source-ref derivation for the two external project-resource links.
Do not hard-code `main`, and do not add `DESIGN-SYSTEM.md` or the example README
to `package.files`.

**ExDoc ownership pattern** (lines 375-423):

```elixir
defp docs do
  [
    source_ref: doc_source_ref(),
    source_url: @source_url,
    favicon: "brandbook/favicon.svg",
    before_closing_head_tag: &before_closing_head_tag/1,
    before_closing_body_tag: &before_closing_body_tag/1,
    extras: [
      "README.md",
      # explicit guide list
      "CONTRIBUTING.md",
      "CHANGELOG.md"
    ],
    groups_for_extras: [
      Overview: ~r/README/,
      Integrations: ~r{^guides/integrations/},
      Evaluate: ~r{...},
      Adopt: ~r{...},
      Operate: ~r{...},
      Contribute: ~r{...}
    ]
  ]
end
```

Preserve the private `docs/0` convergence point and the exact extra-group order.
Change `main` to `"readme"`, add `extra_section: "Guides"`, normalize local and
URL extras, and replace the module groups with the six explicit D-11 lists.
Keep the existing native ExDoc/Mermaid hooks at lines 478-594.

**Existing release-lane pattern** (lines 200-209):

```elixir
defp verify_release(_args) do
  ensure_clean_tree!()

  [
    "bin/verify-release-shape",
    "mix test test/threadline/release_artifact_contract_test.exs test/threadline/ci_topology_contract_test.exs",
    "MIX_ENV=dev mix docs",
    "mix hex.build"
  ]
  |> Enum.each(&run_release_step!/1)
end
```

Modify this existing docs step to use warnings-as-errors; do not add a parallel
release alias.

### `test/threadline/public_surface_contract_test.exs` (contract test, batch + transform)

**Analogs:** `test/threadline/version_truth_doc_contract_test.exs` and
`test/threadline/release_artifact_contract_test.exs` (both tracked)

**Source-derived, non-vacuous discovery pattern**
(`version_truth_doc_contract_test.exs`, lines 43-69):

```elixir
defp doc_files do
  ["README.md" | Path.wildcard("guides/**/*.md")]
end

all_pins =
  for path <- doc_files(),
      [_full, captured] <- Regex.scan(pin_regex, File.read!(path)),
      do: {path, captured}

assert all_pins != [],
       "no ... found ... the glob or regex is broken"

for {path, captured} <- all_pins do
  assert captured == @expected_pin_version
end
```

Use this discover-first shape, but parse Elixir source with
`Code.string_to_quoted!/2` for application-env calls, task modules, and aliases.
Return literal keys and dynamic key expressions separately. Assert a nonempty set
and stable sentinel before exact-set comparison; assert category unions equal the
discovered set and all category intersections are empty.

**Exact project-config comparison pattern**
(`release_artifact_contract_test.exs`, lines 5-23 and 48-76):

```elixir
defp project_config, do: Threadline.MixProject.project()
defp docs_config, do: project_config()[:docs]

defp guides_on_disk do
  Path.wildcard("guides/**/*.md")
  |> MapSet.new()
end

test "guides on disk match the ExDoc guide extras allowlist" do
  assert guide_extras() == guides_on_disk()
end

test "ExDoc extras keep integrations ahead of the verb routing lanes" do
  assert Keyword.keys(docs_config()[:groups_for_extras]) == [
           :Overview, :Integrations, :Evaluate, :Adopt, :Operate, :Contribute
         ]
end
```

Apply the same direct project-config access to the six module-group keys and
flattened membership. Discover visible modules from compiled Threadline
application modules with `Code.fetch_docs/1`; do not infer visibility from file
names. Reject missing members, duplicates, hidden members in a group, and hidden
modules that still expose module docs.

### `test/threadline/guide_graph_contract_test.exs` (graph contract, batch + transform)

**Analog:** `test/threadline/persona_routing_doc_contract_test.exs` (tracked)

**Explicit routing-map pattern** (lines 14-32):

```elixir
@repo_root File.cwd!()

@lanes [
  {"Evaluate", "guides/evaluating-threadline.md"},
  {"Adopt", "guides/getting-started-saas.md"},
  {"Operate", "guides/operator-surface.md"},
  {"Contribute", "CONTRIBUTING.md"}
]

defp read_rel!(segments) when is_list(segments) do
  @repo_root |> Path.join(Path.join(segments)) |> File.read!()
end

defp groups_for_extras do
  Threadline.MixProject.project()[:docs][:groups_for_extras]
end
```

**Readable per-member failure pattern** (lines 42-60):

```elixir
for {label, landing} <- @lanes do
  assert String.contains?(slice, label),
         "expected README `## Start here` to contain the #{inspect(label)} lane label"

  assert String.contains?(slice, landing),
         "expected the #{inspect(label)} lane to link its canonical landing #{inspect(landing)}"
end
```

Extend the explicit map to lane-to-all-guide assignments and derive the graph
from Markdown links. Assert each guide appears exactly once, has a non-README
inbound edge and outbound edge, and each leaf has a lane-return plus a distinct
task-adjacent successor. Resolve relative paths and normalized heading anchors;
include negative fixtures for missing paths and anchors rather than accepting
link-count-only coverage.

### Canonical guides and callers (documentation, sequential + transform)

**Analog:** `guides/getting-started-saas.md` (tracked)

**Canonical-owner opening pattern** (lines 1-18):

```markdown
# Getting started with Threadline in a Phoenix SaaS app

This is the canonical first-hour path for a Phoenix SaaS app: install
Threadline, capture one real write, mount the shipped operator surface, and
finish by checking the same request through `/audit` and the query APIs.

## 1. Prerequisites

- You need a Phoenix app with Ecto + PostgreSQL available before you start.
- The mounted operator surface stays behind your app's own admin/auth boundary.
```

The owner establishes audience, outcome, prerequisites, and safety boundary
before commands. Continue using numbered task headings and executable fenced
examples as shown at lines 19-84. In non-owner files, replace those sequences
with one-sentence context and a descriptive deep link.

**Descriptive integration-link pattern** (lines 100-118):

```markdown
[`guides/integrations/phx-gen-auth.md`](integrations/phx-gen-auth.md) uses
`MyApp.AuditActor` for the same two callbacks — rename the module freely in
your app.

Choose an auth lane when you need a full cookbook:

- **phx-gen-auth-reference** → [`guides/integrations/phx-gen-auth.md`](integrations/phx-gen-auth.md)
- **sigra-reference** (optional) → [`guides/integrations/sigra.md`](integrations/sigra.md)
```

Use purpose-led link text, paths relative to the current guide, and defined
terms. Fix the current wrong same-directory link at lines 343-346 rather than
copying it.

**Terminal successor pattern** (lines 411-419):

```markdown
## Next reads

- [guides/production-checklist.md](production-checklist.md)
- [guides/incident-playbook.md](incident-playbook.md)
- [guides/performance.md](performance.md)
```

Rename this consistently to `Next steps`; include the lane landing and at least
one task-adjacent successor. Keep install/first-hour content in Getting Started,
mount/auth/config content in Operator Surface, and Docker lifecycle/troubleshooting
in Local Docker DX. README, CONTRIBUTING, and the example README only route.

### `test/threadline/release_artifact_contract_test.exs` (package test, file-I/O + batch)

**Analog:** itself (tracked)

**Fresh-artifact and cleanup pattern** (lines 112-138):

```elixir
unpack_root =
  Path.join(
    System.tmp_dir!(),
    "threadline-hex-contract-#{System.unique_integer([:positive])}"
  )

on_exit(fn -> File.rm_rf!(unpack_root) end)

case System.cmd(
       System.find_executable("mix"),
       ["hex.build", "--unpack", "--output", unpack_root],
       cd: File.cwd!(),
       env: [{"MIX_ENV", "dev"}],
       stderr_to_stdout: true
     ) do
  {_output, 0} ->
    unpack_root
    |> Path.join("**/*")
    |> Path.wildcard(match_dot: true)
    |> Enum.filter(&File.regular?/1)
    |> Enum.map(&Path.relative_to(&1, unpack_root))

  {output, status} ->
    flunk("mix hex.build --unpack failed (#{status}):\n#{output}")
end
```

Extend this single harness to return both entry paths and readable UTF-8 text.
Assert expected sentinels and a nonempty scan set before checking zero planning
vocabulary. Inject a temporary offender into the unpack root and prove the same
scanner reports it. Skip binary files only after a documented UTF-8/binary test;
never by public-document allowlist.

Normalize ExDoc extras by shape: local paths participate in package/existence
checks; URL extras participate in title/group/version-ref checks and must remain
absent from the package.

### `lib/threadline/operator_surface/controllers/export_controller.ex`

**Current in-place seam:** tracked controller, lines 86-175

The existing flow already centralizes delivery resolution and preserves stable
HTTP outcomes:

```elixir
with :ok <- ensure_not_expired(job),
     {:ok, delivery} <- resolve_delivery(file_path, job) do
  send_delivery(conn, delivery, file_path)
else
  {:error, :expired} ->
    unavailable_export(conn, 410, "Export download is no longer available")

  {:error, _reason} ->
    unavailable_export(conn, 404, "Export download is not available")
end
```

The modification belongs inside `resolve_delivery/2` (currently lines 106-122):
check `function_exported?(storage_adapter, :path, 1)` before calling `path/1`.
When absent, call the same `download_url/2` path used by `{:error, :not_local}`.
Preserve all other `path/1` errors and the existing `download_url_opts/2`, expiry,
404, 410, local send-file, and remote redirect behavior. Do not add or rename a
storage callback.

### `test/threadline/operator_surface/controllers/export_controller_test.exs`

**Current in-place seam:** tracked integration test

**Behavior-stub pattern** (lines 151-176):

```elixir
defmodule RemoteStorageStub do
  @behaviour Threadline.Storage

  @impl true
  def init(_opts), do: :ok

  @impl true
  def put(_content, _opts), do: {:error, :unsupported}

  @impl true
  def get(_file_id), do: {:error, :unsupported}

  @impl true
  def path(_file_id), do: {:error, :not_local}

  @impl true
  def download_url(file_id, opts \\ []) do
    {:ok, "https://downloads.example.test/#{file_id}"}
  end

  @impl true
  def delete(_file_id), do: :ok
end
```

Add a second behavior-conforming stub that intentionally omits optional `path/1`.
Do not merely alter `RemoteStorageStub`, because its `{:error, :not_local}` test
must continue to protect the existing branch.

**Global-config isolation pattern** (lines 437-460): save the previous adapter
and module options, install the test adapter, and restore both in `on_exit/1`.
**Remote delivery assertion pattern** (lines 506-529): insert a completed job,
assign the same actor, GET the download route, and assert `302` plus the exact
`location` header. The new optional-callback regression should follow this shape.

### Visibility and public module docs (module/service/model, transform)

**Annotation analog:** `lib/mix/tasks/threadline/verify_topology.ex` line 2

```elixir
@moduledoc false
```

Use this exact annotation for D-09 and for D-10 candidates only after their
call-path/return-contract audit. Do not delete callable code and do not describe
the annotation as runtime privacy. For visible façades, returned structs,
behaviors/adapters, integrations, `OperatorSurface.Router`/`Auth`, and adopter Mix
tasks, preserve module docs and shorten the first paragraph for ExDoc listings.
Rewrite public references to hidden modules in façade/task/domain language in the
same task that hides them.

### Community/security surfaces (config/policy, request-response)

No project-local issue-form, PR-template, security-policy, or conduct-policy
analog exists. Use the exact filenames and fields locked by D-24 through D-28;
the local pattern to copy is the small, direct file contract from
`persona_routing_doc_contract_test.exs`, not an invented YAML framework.

For `community_health_contract_test.exs`:

```elixir
@repo_root File.cwd!()

defp read_rel!(segments) when is_list(segments) do
  @repo_root |> Path.join(Path.join(segments)) |> File.read!()
end
```

Assert files are nonempty, three form names and chooser policy are exact, labels
are from `bug`, `enhancement`, and `question`, and safety/routing strings keep
public support, private vulnerability reporting, and conduct reporting distinct.
Use structural assertions sufficient for the known forms; do not add a YAML
dependency or simulate GitHub rendering. Hosted recognition, labels, and private
reporting remain a post-merge GitHub read-back/manual smoke.

## Shared Patterns

### ExUnit Contract Shape

**Sources:** `test/threadline/release_artifact_contract_test.exs` lines 1-23 and
`test/threadline/version_truth_doc_contract_test.exs` lines 22-69.

- Contract modules use `@moduledoc false` when their documentation is not itself
  part of the public contract.
- Pure file/config contracts use `async: true`; the package-build test and tests
  mutating application environment remain `async: false`.
- Discover the source set first, assert non-vacuity and a stable sentinel, then
  compare exact sets. Never use a count floor as completeness proof.
- Failure messages name the file/member and the invariant a contributor must
  restore.

### Temporary Artifact Hygiene

**Source:** `test/threadline/release_artifact_contract_test.exs` lines 112-138.

Create a unique path under `System.tmp_dir!/0`, register cleanup immediately with
`on_exit/1`, run the real build command with captured stderr, and fail with the
command output. Positive controls live only inside that temporary artifact.

### Documentation Information Architecture

**Sources:** `mix.exs` lines 375-475,
`test/threadline/persona_routing_doc_contract_test.exs` lines 14-68, and
`guides/getting-started-saas.md` lines 1-18 and 411-419.

The README owns four intent verbs; ExDoc owns the same sidebar lanes; canonical
guides own executable procedures; leaf guides own semantic successors. Module
groups are a separate six-role taxonomy. Keep these two taxonomies explicit and
test their exact membership independently.

### Application Environment Isolation

**Source:**
`test/threadline/operator_surface/controllers/export_controller_test.exs`
lines 437-460.

Any test that changes `Application` environment saves the exact previous value
and restores or deletes it in `on_exit/1`. Such tests cannot be asynchronous.

### Error and Security Routing

**Source:** `lib/threadline/operator_surface/controllers/export_controller.ex`
lines 86-175.

Map known outcomes to stable, minimal responses; avoid leaking internal reasons.
For community intake, apply the same routing discipline: ordinary bug/question,
private vulnerability, and conduct escalation are separate destinations. Never
fall back from an undisclosed vulnerability to a public issue.

## No Analog Found

| File / Concern | Role | Data Flow | Reason / Planner Direction |
|---|---|---|---|
| `.github/ISSUE_TEMPLATE/{01-bug,02-feature-request,03-question,config}.yml` | config / intake form | request-response | No issue forms exist. Follow D-24/D-25 and GitHub's native schema; validate locally with narrow structural assertions and after merge with GitHub. |
| `.github/pull_request_template.md` | intake template | request-response | No PR template exists. Follow the four locked headings and HTML safety comment in D-26. |
| `SECURITY.md` | security policy | request-response | No security policy exists. Point only to enabled private vulnerability reporting for undisclosed reports; link releases rather than hard-coding a support matrix. |
| `CODE_OF_CONDUCT.md` | conduct policy | request-response | No conduct policy exists. Use Contributor Covenant 3.0 with attribution and Threadline's actual GitHub scope; use GitHub Report Abuse, not a fictional inbox or Security Advisories. |
| AST runtime-key/task/alias extractor | test utility | batch + transform | No existing AST inventory helper was found. Implement it inside the new contract test (or a test-support module only if two or more contracts consume it) using `Code.string_to_quoted!/2`; keep dynamic expressions visible. |
| compiled ExDoc visibility extractor | test utility | batch + transform | No existing compiled-doc inventory exists. Use application module discovery plus `Code.fetch_docs/1`, with nonempty sentinels and explicit handling of `:hidden`/`:none`. |
| Markdown anchor resolver | test utility | batch + transform | Existing contracts assert routing literals but do not resolve a full graph. Keep the resolver test-only, normalize ExDoc/Markdown heading anchors, and prove missing-path and missing-anchor failures with fixtures. |

## Planner Guardrails

1. Start with red, source-derived contracts; implement prose/config/runtime changes
   against those contracts; finish with the real docs and unpacked-package gates.
2. Do not centralize production code merely to support these tests. Small private
   test helpers are sufficient.
3. Do not let `@moduledoc false` become a proxy for a compatibility decision.
   D-09 is mandatory; D-10 remains audit-gated.
4. Do not make external URL extras package files, or treat them as local paths in
   existing release contracts.
5. Preserve the existing controller authorization, expiration, content delivery,
   and error semantics around the single optional-callback repair.
6. Do not claim hosted GitHub behavior from local tests. Plan the post-merge
   non-maintainer form/template smoke and private-reporting read-back explicitly.
7. Keep operator UI/DOM/CSS changes, publishing/version automation, deeper API
   redesign, Credo/layer repairs, and structural splits out of this phase.

## Metadata

**Analog search scope:** tracked `mix.exs`, `lib/threadline/**`,
`test/threadline/**`, `guides/**`, root public docs, and `.github/**`.

**Files scanned:** 77 library/task source files, 18 guides, 5 root/reference
documents, 140+ ExUnit files, and the current `.github` inventory.

**Tracked-source gate:** every analog named above was verified with `git ls-files`.
New Phase 200 files are correctly absent from the tracked analog set.

**Pattern extraction date:** 2026-09-11
