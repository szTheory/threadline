# Phase 203: Real Gates - Pattern Map

**Mapped:** 2026-09-22
**Files analyzed:** 22 file targets (plus the AliasUsage/mechanical/structural sweeps, which touch about 56, 48, and 35 files)
**Analogs found:** 20 / 22 (every analog path below is git-tracked; `deps/credo/**` is a gitignored dependency and is cited only as the D-02 copy source and as Credo semantics, never as a pattern analog)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/threadline/credo_config_contract_test.exs` (NEW) | test (contract/ratchet) | file-I/O + transform (parse config/source, then validate) | `test/threadline/dialyzer_ignore_contract_test.exs` | exact (D-08 names it) |
| `test/threadline/layer_boundary_contract_test.exs` (NEW) | test (source-scan contract) | file-I/O batch scan | `test/threadline/zero_skips_contract_test.exs` + `storage_schema_call_site_contract_test.exs` "real tree sweep" | exact |
| `.credo.exs` (REBUILD) | config | n/a | current `.credo.exs` (tracked; its shape is the defect) + `deps/credo/.credo.exs` lines 1-66 (copy source per D-02) | role-match |
| `mix.exs` (`verify.xref_cycles` alias + `ci.all` entry) | config (alias) | batch | `mix.exs:160` `"verify.compile_no_optional"` + `ci.all` block `:184-209` | exact |
| `.github/workflows/ci.yml` (`verify-test` new step) | config (CI) | batch | `ci.yml:348-352` (`Compile (warnings as errors)` / `Run tests` steps) | exact |
| `test/threadline/ci_topology_contract_test.exs` (optional pin for new alias) | test | file-I/O | same file `:45-49`, `:75-100` | exact |
| `lib/threadline/query/scope.ex` (git mv of `operator_surface/scope.ex`) | utility (query hook) | transform | `lib/threadline/query/actor_history_page.ex` (namespace sibling) | role-match |
| `lib/threadline/query.ex` (alias retarget `:35`, use `:731`) | service | CRUD/query | itself | n/a (edit in place) |
| `lib/threadline/query/filter_params.ex` (git mv of `operator_surface/exports/filter_params.ex`) | utility (codec) | transform | itself (pure rename) | n/a |
| `lib/threadline/export/orchestrator.ex` + 4 operator-surface callers | service / LiveView / controller | request-response | own alias lines | n/a (alias rename) |
| `test/threadline/query/filter_params_test.exs` (git mv of `test/threadline/operator_surface/exports/filter_params_test.exs`) | test | transform | itself | n/a |
| Pin tests: `exports_doc_contract_test.exs`, `code_walkthrough_doc_contract_test.exs`, `how_threadline_works_doc_contract_test.exs`, `public_surface_contract_test.exs`, `export_controller_test.exs` | test | file-I/O | own lines | n/a |
| `lib/threadline/capture/audit_transaction.ex` (delete `:59`) | model | CRUD | n/a (one-line deletion) | n/a |
| `lib/threadline/capture/audit_change.ex`, `audit_transaction.ex`, `lib/threadline/semantics/actor_ref.ex` (add `@type t`) | model | n/a | `lib/threadline/retention/policy.ex:15-20` | role-match |
| `lib/threadline/operator_surface/live/timeline_live.ex:34`, `controllers/export_controller.ex:349` (stale comments) | component/controller | n/a | n/a (comment rewrite) | n/a |
| `test/support/repo.ex` (`@moduledoc false`) | config (Repo) | n/a | `lib/threadline/operator_surface/scope.ex:2` (`@moduledoc false` form) | role-match |
| 46 structural disable sites (Nesting/CC) across lib/test | annotation | n/a | **none in repo** (zero `credo:` comments exist today) | no analog |
| AliasUsage sweep (56 files) | all roles | n/a | `lib/threadline/query.ex:30-38` alias block | role-match |
| Mechanical sweep (82 findings) | all roles | n/a | per-finding; see Shared Patterns | partial |
| `.planning/ROADMAP.md` Phase 204 mirror | docs | n/a | n/a | no analog needed |

---

## Pattern Assignments

### `test/threadline/credo_config_contract_test.exs` (test, file-I/O + validate)

**Analog:** `test/threadline/dialyzer_ignore_contract_test.exs` (512 lines, tracked)

**Module header + attributes** (lines 1-23). Copy the `@root` path anchoring and the ceiling attribute:
```elixir
defmodule Threadline.DialyzerIgnoreContractTest do
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)
  @mix_path Path.join(@root, "mix.exs")
  @ignore_path Path.join(@root, ".dialyzer_ignore.exs")
  ...
  @warning_ceiling 0
```
New file should declare `@credo_path Path.join(@root, ".credo.exs")`, a pinned `@deltas` (the exact `extra:` list, `disabled: []`), a `@register` such as `[{Credo.Check.Refactor.Nesting, <n>, "Phase 204 / STRUCT-03"}, {Credo.Check.Refactor.CyclomaticComplexity, <n>, "Phase 204 / STRUCT-03"}]`, and a `@ceiling` that may only decrease. Add a `@moduledoc` (house style: `zero_skips_contract_test.exs:2-19` explains the invariant in prose).

**Positive real-tree test + planning-name self-guard** (lines 25-42):
```elixir
  test "five source fixtures form the exact 40-warning and 22-origin partition" do
    fixtures = load_fixtures!()
    assert :ok = validate_contract(fixtures, File.read!(@ignore_path), @warning_ceiling)
    ...
    planning_directory = "." <> "planning"
    refute File.read!(__ENV__.file) =~ planning_directory
  end
```
Copy the last two lines verbatim. `planning_dependency_contract_test.exs:5` scans tracked tests for `.planning/...` paths, and DECOUPLE-01 forbids gates reading `.planning/`. The register's successor text must say "Phase 204 / STRUCT-xx", never a planning path.

**Negative synthetic-source tests** (lines 44-58, 93-116). Pattern: feed a mutated source string to the same `validate_contract/…`, assert `{:error, message}`, and match a message fragment:
```elixir
    assert {:error, message} = validate_contract(fixtures, "[~r/lib\\/.*/]", @warning_ceiling)
    assert message =~ "literal exact tuple"
    ...
    assert {:error, message} = validate_contract(fixtures, source, 0)
    assert message =~ "ceiling of 0"
```
Required Credo negatives (D-08 1-5): `enabled:` key present; delta list differs from `@deltas`; `disable-for-this-file`, `disable-for-lines:N`, nameless `disable-for-next-line`, or a disable naming any other check; trailing text after the check name; missing adjacent `# Phase 204 (STRUCT-NN)` line; per-check count differs from the register; count above `@ceiling`; an upstream opt-in module in `extra:` (Open Q1 / D-06 interpretation).

**Throw-based validator core** (lines 182-203):
```elixir
  defp validate_contract(fixtures, ignore_source, ceiling, unused_filters \\ []) do
    try do
      validate_fixtures!(fixtures)
      {entries, entry_lines, source_lines} = parse_ignore_source!(ignore_source)
      reject_broad_entries!(entries)
      demand!(length(entries) == length(Enum.uniq(entries)), "duplicate exact ignore tuple")
      ...
      demand!(
        length(entries) <= ceiling,
        "ignore count exceeds the ratchet ceiling of #{ceiling}"
      )
      :ok
    catch
      {:contract_error, message} -> {:error, message}
    end
  end
```

**AST parse (never eval for the shape check)** (lines 336-352):
```elixir
    {ast, comments} =
      case Code.string_to_quoted_with_comments(source, columns: true) do
        {:ok, ast, comments} -> {ast, comments}
        {:error, error} -> fail!("ignore file is not valid Elixir: #{inspect(error)}")
      end
```
Use `Code.string_to_quoted!/1` on `.credo.exs` and walk the AST for any `:enabled` key under `checks:`. Use `Code.eval_file/1` only for the exact `@deltas` equality.

**Adjacent-comment check** (lines 421-431). This is the direct template for D-08(4) "each disable has an adjacent `# Phase 204 (STRUCT-…)` line":
```elixir
      previous_line = source_lines |> Enum.at(line_number - 2, "") |> String.trim()
      ...
      demand!(
        previous_line == expected_comment,
        "each irreducible tuple needs its actionable comment on the immediately preceding line"
      )
```

**Helpers** (lines 508-511). Copy verbatim:
```elixir
  defp present?(value), do: is_binary(value) and String.trim(value) != ""
  defp demand!(true, _message), do: :ok
  defp demand!(false, message), do: fail!(message)
  defp fail!(message), do: throw({:contract_error, message})
```

**Disable-comment discovery: mirror Credo exactly.** Credo finds config comments through real comments only, not raw text (`deps/credo/lib/credo/check/config_comment_finder.ex:29-53`):
```elixir
    if source =~ config_comment_format() do
      case Code.string_to_quoted_with_comments(source) do
        {:ok, _ast, comments} -> extract_config_comments(comments)
    ...
  defp config_comment_format, do: ~r/#\s*credo\:([\w\-\:]+)\s*(.*)/im
```
Recommendation: scan `Path.wildcard("{lib,test}/**/*.{ex,exs}")` with `Code.string_to_quoted_with_comments/1` and apply the same regex to each `%{text: text, line: line}` comment. Then the synthetic negative sources held as string literals inside this test file are invisible to both Credo and the real-tree scan, the same way they are invisible to Credo. If you use a raw-text regex scan instead, you must use the needle-concatenation trick from `zero_skips_contract_test.exs:26-39`, because this test file is inside its own glob.

**Vacuous-gate guard** (`zero_skips_contract_test.exs:44-50`), for D-08(5):
```elixir
    files = test_files()

    assert files != [],
           "no files matched #{@test_glob} — the glob is broken. A broken glob would " <>
             "let this guard pass vacuously while every skip tag in the suite went " <>
             "unnoticed, which is worse than having no guard at all."
```

**Mix project introspection** (dialyzer test lines 60-75), if the test also pins `verify.credo`:
```elixir
    project = Threadline.MixProject.project()
    dialyzer = Keyword.fetch!(project, :dialyzer)
```

---

### `test/threadline/layer_boundary_contract_test.exs` (test, file-I/O batch scan)

**Primary analog:** `test/threadline/zero_skips_contract_test.exs` (85 lines, tracked). This is the smallest complete source-scan contract in the repo.

**Structure** (lines 1-21, 42-65). A prose `@moduledoc` that states the invariant, `async: true`, a glob attribute, a non-empty guard, and an offenders comprehension with an actionable failure message:
```elixir
defmodule Threadline.ZeroSkipsContractTest do
  @moduledoc """
  Phase 198 (D-05) anti-laundering cap, asserted mechanically rather than
  promised in prose.
  ...
  """

  use ExUnit.Case, async: true

  @test_glob "test/**/*_test.exs"
  ...
  defp test_files, do: Path.wildcard(@test_glob)

  test "no test file carries a skip tag (D-05 zero-exclusions cap)" do
    files = test_files()

    assert files != [], "no files matched #{@test_glob} — the glob is broken. ..."

    offenders =
      for path <- files,
          source = File.read!(path),
          needle <- skip_needles(),
          String.contains?(source, needle),
          do: {Path.relative_to_cwd(path), needle}

    assert offenders == [], "these test files carry a skip tag, ... #{inspect(offenders)}. ..."
  end
```
The zero_skips moduledoc and failure message mention a `.planning/` path as diagnostic text. `planning_dependency_contract_test.exs:117-124` allows that, but the new test should not need it.

**Secondary analog, a multi-invariant real-tree sweep:** `test/threadline/storage_schema_call_site_contract_test.exs:107-112` (sorted, deduped file set) and `:450-501` (non-vacuity assertions beyond `files != []`):
```elixir
  defp source_files do
    @source_globs
    |> Enum.flat_map(&Path.wildcard/1)
    |> Enum.uniq()
    |> Enum.sort()
  end
```

**Source-file set precedent:** `test/threadline/public_surface_contract_test.exs:527`:
```elixir
  defp source_files, do: ["mix.exs" | Path.wildcard("lib/**/*.ex")]
```

**Allowlist existence check precedent:** `public_surface_contract_test.exs:529-532`:
```elixir
  defp read_public!(path) do
    assert File.regular?(path), "missing required public-document subject: #{path}"
    File.read!(path)
  end
```

**Content to implement (D-15, D-19b):**
- Scope: `Path.wildcard("lib/**/*.ex")` minus `lib/threadline/operator_surface.ex`, everything under `lib/threadline/operator_surface/`, and the existence-checked allowlist `lib/mix/tasks/critic.synth.ex` (D-14; references the operator surface at `:8`). `critic.measure.ex` holds only lowercase `operator_surface` strings, so a case-sensitive `OperatorSurface` needle does not need to allowlist it. Only add it if the planner chooses case-insensitive matching.
- Needle: case-sensitive `"OperatorSurface"` substring. It catches `alias`, multi-alias `{}`, `Module.concat`, and `:"Elixir.…"`. The test lives in `test/`, which it does not scan, so it cannot self-match.
- Test 2 (GATE-04): no `no_warn_undefined` in any `lib/**/*.ex`, **and** `Keyword.get(Mix.Project.config()[:elixirc_options] || [], :no_warn_undefined) == nil`. `mix.exs` has no `elixirc_options` today (verified by grep), so the second assertion passes trivially but blocks relocation.
- Optional test 3 (GATE-05): no lib comment matches `~r/#.*\b[\w\/.-]+\.exs?:\d+/`. Verified today: exactly 2 hits (`timeline_live.ex:34`, `export_controller.ex:349`), so it goes green once Plan 3 fixes them. Sequence the scan after that fix, or put it in Plan 3.

---

### `.credo.exs` (config, rebuild in Plan 5)

**Current tracked file** (20 lines). Keep `strict: true` (line 5). Replace the `enabled:` list (lines 12-17), which is the vacuous gate:
```elixir
      checks: %{
        enabled: [
          {Credo.Check.Readability.ModuleDoc, []},
          {Credo.Check.Design.TagTODO, [exit_status: 0]}
        ]
      }
```

**Copy source (D-02):** `deps/credo/.credo.exs` lines 1-66 verbatim (comment header, `name:`, `files:` with the upstream `included:` list of 8 globs and `excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]`, `plugins:`, `requires:`, `strict:`, `parse_timeout: 5000`, `color: true`). Line 49 `strict: false` becomes `strict: true` (a documented delta). Line 67 onward (`checks: %{ enabled: [...]`) is replaced by the delta map from RESEARCH §"Recommended `.credo.exs` shape":
```elixir
      checks: %{
        extra: [
          {Credo.Check.Design.TagTODO, [exit_status: 0]},
          {Credo.Check.Readability.ModuleDoc, [ignore_names: [], ignore_modules_using: []]},
          {Credo.Check.Warning.MissedMetadataKeyInLoggerConfig,
           [metadata_keys: [:deleted_changes, :deleted_transactions, :batch, :total_changes, :total_transactions]]}
        ],
        disabled: []
      }
```
The Logger keys come from `lib/threadline/retention.ex:180-186` (verified: `deleted_changes: n1, deleted_transactions: n2, batch: idx, total_changes: tc, total_transactions: tt`). The contract test's `@deltas` must equal this list exactly.

---

### `mix.exs` (alias + `ci.all`)

**Analog, a list-form alias** (`mix.exs:160`):
```elixir
      "verify.compile_no_optional": ["compile --no-optional-deps --warnings-as-errors"],
```
New alias, same shape, placed near it with a short why-comment like the neighbouring aliases:
```elixir
      "verify.xref_cycles": ["xref graph --format cycles --label compile-connected --fail-above 0"],
```

**`ci.all` insertion** (`mix.exs:184-209`). Put it immediately after `"compile --warnings-as-errors"` (line 187):
```elixir
      "ci.all": [
        "verify.format",
        "verify.credo",
        "compile --warnings-as-errors",
        "verify.compile_no_optional",
        "verify.test",
```
Ordering constraints already pinned by `test/threadline/ci_topology_contract_test.exs:75-100` (`compile --warnings-as-errors` < `verify.compile_no_optional` < `verify.test` < …) and `ci_workflow_parity_contract_test.exs:32-60`. Inserting between `compile --warnings-as-errors` and `verify.compile_no_optional` does not break either test. `preferred_cli_env` (line 14 region) needs no entry: xref runs in any env.

---

### `.github/workflows/ci.yml` (`verify-test` job, new step)

**Analog** (`ci.yml:348-352`). The step shape inside the frozen `verify-test:` job (line 278) is `- name:` plus `run: mix verify.*`:
```yaml
      - name: Compile (warnings as errors)
        run: mix compile --warnings-as-errors

      - name: Run tests
        run: mix verify.test
```
Insert between them, with **no** `if: matrix.lane == 'current'` so the Elixir 1.15 min lane proves it (contrast the lane-gated steps at `:355`, `:359`):
```yaml
      - name: Verify no compile-connected xref cycles
        run: mix verify.xref_cycles
```
Do not touch job IDs (`ci_workflow_parity_contract_test.exs:14-18` asserts `^  verify-credo:` / `^  verify-test:`). The `verify-credo` job (`:107-130`) needs no edit. It already runs `mix verify.credo` under MIX_ENV=dev, which is why the Logger delta has to live in `.credo.exs` and not in env config.

---

### `test/threadline/ci_topology_contract_test.exs` (optional: pin the new alias)

**Analog, same file `:45-49`:**
```elixir
  test "mix aliases expose the named support-lane proof entrypoints" do
    mix_exs = read_rel!(["mix.exs"])

    assert String.contains?(mix_exs, "\"verify.compile_no_optional\":")
    assert String.contains?(mix_exs, "\"compile --no-optional-deps --warnings-as-errors\"")
```
Add `"\"verify.xref_cycles\":"` and the command string, and extend the `:binary.match` ordering block (`:82-96`) with `pos_compile_strict < pos_xref_cycles`. Optional, but it stops the alias from being silently dropped.

---

### `lib/threadline/query/scope.ex` (git mv + rename, Plan 1)

**Source** (`lib/threadline/operator_surface/scope.ex`, 25 lines). Only line 1 changes:
```elixir
defmodule Threadline.OperatorSurface.Scope do   # -> defmodule Threadline.Query.Scope do
  @moduledoc false

  @spec apply(Ecto.Queryable.t(), keyword()) :: Ecto.Queryable.t()
  def apply(query, opts \\ []) do
```
The body (lines 4-24) must stay byte-identical: it is the tenant-scope enforcement point (RESEARCH §Security V4). Note it carries a `cond` (`:9-22`). If Credo flags it under `Refactor.CondStatements` or similar, leave it for Plan 3 and never change it in the move commit.

**Namespace sibling:** `lib/threadline/query/actor_history_page.ex:1` `defmodule Threadline.Query.ActorHistoryPage do`. The directory exists.

**Caller retarget** (`lib/threadline/query.ex:32-38`, `:729-732`):
```elixir
  alias Threadline.Capture.AuditChange
  alias Threadline.Capture.AuditTransaction
  alias Threadline.OperatorSurface.Scope, as: OperatorScope   # -> alias Threadline.Query.Scope
  alias Threadline.Semantics.ActorRef
  ...
  @doc false
  def maybe_apply_scope(query, opts) do
    OperatorScope.apply(query, opts)                          # -> Scope.apply(query, opts)
  end
```
Keep alias alphabetical order (`Threadline.Query.Scope` sorts after `Threadline.Capture.*` and before `Threadline.Semantics.*`), or Credo `AliasOrder` fires.

**Pins updated in the same commit:**
- `test/threadline/code_walkthrough_doc_contract_test.exs:80`: `"Threadline.OperatorSurface.Scope",` becomes `"Threadline.Query.Scope",`
- `test/threadline/how_threadline_works_doc_contract_test.exs:78`: `refute String.contains?(doc, "Threadline.OperatorSurface.Scope")` becomes `Threadline.Query.Scope`
- `test/threadline/public_surface_contract_test.exs:641` in `modules_for_visibility_tag(:module_visibility_operator_helpers)` (`:636-644`). Rename the entry. Planner decides whether to keep it under `operator_helpers` or move it to `:module_visibility_domain_tail` (`:613-620`). Either keeps both tags non-empty.

---

### `lib/threadline/query/filter_params.ex` (git mv + rename, Plan 1)

**Source header** (`lib/threadline/operator_surface/exports/filter_params.ex:1-4`):
```elixir
defmodule Threadline.OperatorSurface.Exports.FilterParams do   # -> Threadline.Query.FilterParams
  @moduledoc false

  alias Threadline.Semantics.ActorRef
```
The body is unchanged. Its own Credo findings move with it at the same line numbers.

**lib callers (alias line only, verified by grep):**
- `lib/threadline/export/orchestrator.ex:11` `alias Threadline.OperatorSurface.Exports.FilterParams`. After the rename, the alias block `:9-12` must stay sorted: `Threadline.Export`, `Threadline.Governance.ExportJob`, `Threadline.Query.FilterParams`, `Threadline.StorageSchema`
- `lib/threadline/operator_surface/live/timeline_live.ex:16`
- `lib/threadline/operator_surface/live/export_status_live.ex:17`
- `lib/threadline/operator_surface/live/start_live.ex:17`
- `lib/threadline/operator_surface/controllers/export_controller.ex:12`

Every call site uses the short `FilterParams.` name, so only the alias lines change. Re-sort each alias block afterwards.

**Test pins in the same commit:**
- `git mv test/threadline/operator_surface/exports/filter_params_test.exs test/threadline/query/filter_params_test.exs`. `test/threadline/query/` does not exist yet; `test/threadline/query_test.exs` is the sibling. Update line 1 `defmodule Threadline.OperatorSurface.Exports.FilterParamsTest` to `Threadline.Query.FilterParamsTest`, line 5 alias, and line 146 `File.read!("lib/threadline/operator_surface/exports/filter_params.ex")`
- `test/threadline/operator_surface/exports_doc_contract_test.exs:10` `@filter_params_path` (read at `:140`, `:192`, `:266`; a stale path crashes, it does not pass vacuously), and `:157-158`:
  ```elixir
      assert String.contains?(lv_src, "Threadline.OperatorSurface.Exports.FilterParams") or
               String.contains?(lv_src, "alias Threadline.OperatorSurface.Exports.FilterParams"),
  ```
  Retarget both strings to `Threadline.Query.FilterParams`. The atom-safety guard at `:262-270` must be repointed through the attribute, not dropped.
- `test/threadline/operator_surface/controllers/export_controller_test.exs:436`: `Threadline.OperatorSurface.Exports.FilterParams.canonical_query(%{`
- `test/threadline/public_surface_contract_test.exs:639` (same visibility-tag decision as Scope)
- `CHANGELOG.md`: do not edit history.

---

### `lib/threadline/capture/audit_transaction.ex` (GATE-04 deletion)

**Site** (lines 55-62):
```elixir
    # Actor and semantic-action context are additive and nullable; capture works
    # without either.
    field(:actor_ref, Threadline.Semantics.ActorRef)

    @compile {:no_warn_undefined, Threadline.Semantics.AuditAction}
    belongs_to(:action, Threadline.Semantics.AuditAction)
```
Delete line 59 only. Keep `belongs_to` (line 60) and `lib/threadline/semantics/audit_action.ex:47` `has_many(:transactions, …)`.

---

### `@type t` additions (SpecWithStruct fix, Plan 3)

**Analog:** `lib/threadline/retention/policy.ex:15-20` (the only `@typedoc` + `@type t :: %__MODULE__{…}` pair in lib):
```elixir
  @typedoc "Normalized retention options as returned by `resolve/1`."
  @type t :: %__MODULE__{
          enabled: boolean(),
          delete_empty_transactions: boolean(),
          window_seconds: pos_integer()
        }
```
Secondary: `lib/threadline/query/actor_history_page.ex:11-16`. No Ecto schema in lib defines `@type t` today, so `AuditChange` (`use Ecto.Schema` at `:40`), `AuditTransaction`, and `ActorRef` (plain `defstruct [:type, :id]` at `:22`) are all first-of-kind. The minimal `@type t :: %__MODULE__{}` is acceptable. Then replace `%AuditChange{}` / `%AuditTransaction{}` in the specs at `query.ex:65, 106, 117, 649`, `change_diff.ex:84`, `integrations/sigra.ex:18, 58`. Gate: `MIX_ENV=dev mix dialyzer --no-check` reports `Total errors: 0`.

---

### GATE-05 stale comments (Plan 3)

- `lib/threadline/operator_surface/live/timeline_live.ex:34`: `# For :ok / true returns, the assign is absent. (auth.ex:21-27)`. Rewrite with a symbol reference, not `file:line`. The comment is also semantically stale: auth assigns `:threadline_scope` to `nil`.
- `lib/threadline/operator_surface/controllers/export_controller.ex:349`: `# ---- Filter validation (lifted from timeline_live.ex:366-373) ----`. The referent is now `TimelineLive.safe_validate/1` (`timeline_live.ex:~1370`).
- House form for symbol references: RESEARCH notes that "see `TimelineLive.safe_validate/1`" style references don't rot.

### `test/support/repo.ex` (ModuleDoc delta finding)

Current file (5 lines, tracked) has no moduledoc. Add `@moduledoc false` as the first line of the module body, the same form as `lib/threadline/operator_surface/scope.ex:2`.

---

## Shared Patterns

### Contract-test failure style (all new tests)
**Source:** `test/threadline/zero_skips_contract_test.exs:44-65`, `storage_schema_call_site_contract_test.exs:452-457`
Every assertion carries a long `<>`-concatenated message that says what broke, why a vacuous pass would be worse, and what to do instead. Offenders are reported as `{Path.relative_to_cwd(path), detail}` tuples via `inspect/1`.

### Self-match avoidance (any test whose glob includes its own file)
**Source:** `test/threadline/zero_skips_contract_test.exs:26-39`
```elixir
  # The needles below are assembled at runtime instead of written as literals
  # because THIS FILE is itself matched by the glob it scans. ...
  defp skip_needles do
    attr = "@"
    test_level = attr <> "tag"
```
**Apply to:** `credo_config_contract_test.exs` if it raw-text scans `test/`. It is not needed if it uses Credo's comment-only scan (`Code.string_to_quoted_with_comments`), and it is not needed for `layer_boundary_contract_test.exs`, which scans only `lib/`.

### Planning-independence guard
**Source:** `dialyzer_ignore_contract_test.exs:40-41` (`planning_directory = "." <> "planning"; refute File.read!(__ENV__.file) =~ planning_directory`)
**Apply to:** `credo_config_contract_test.exs` (and optionally `layer_boundary_contract_test.exs`). Enforced repo-wide by `test/threadline/planning_dependency_contract_test.exs:5, 126`.

### Structural disable comment (46 sites, Plan 4). No in-repo analog; use the verified grammar
**Source:** RESEARCH §Code Examples + `deps/credo/lib/credo/check/config_comment.ex` (line_no_issue == line_no + 1)
```elixir
    # Phase 204 (STRUCT-03): flatten nested case — requires function split, filed per 203 hard rule
    # credo:disable-for-next-line Credo.Check.Refactor.Nesting
    case Storage.fetch(key) do
```
No trailing text after the check name, never nameless, and placed above the *reported* line (for Nesting, the nested construct). Place against line numbers re-measured after Plans 2-3.

### Alias blocks (AliasUsage sweep, 356 findings / 91 pairs / 56 files)
**Source:** `lib/threadline/query.ex:30-38`
```elixir
  import Ecto.Query

  alias Threadline.Capture.AuditChange
  alias Threadline.Capture.AuditTransaction
  alias Threadline.OperatorSurface.Scope, as: OperatorScope
  alias Threadline.Semantics.ActorRef
```
One `alias` per line, alphabetical, after `require`/`import`, and `as:` only for collisions (D-10; this line is the in-repo `as:` precedent, and it goes away in Plan 1). In multi-module test files (for example `start_live_test.exs`), each module needs its own alias block. Example test alias form: `test/threadline/operator_surface/exports/filter_params_test.exs:1-6`.

### Verify-alias / CI step wiring
**Source:** `mix.exs:160` (alias shape), `mix.exs:184-209` (`ci.all`), `ci.yml:348-352` (step shape), `ci_topology_contract_test.exs:45-100` (pinning)
**Apply to:** `verify.xref_cycles` only. Every other gate is wired already (`verify.credo` `mix.exs:125`, `verify.dialyzer` `:126`).

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| 46 `# credo:disable-for-next-line` sites | annotation | n/a | Zero `credo:` config comments exist in `lib/` or `test/` today (grep: only `verify-credo:` in a YAML regex). Use the RESEARCH grammar above |
| `.credo.exs` `extra:`/`disabled:` delta shape | config | n/a | No tracked file uses the delta form. The shape comes from Credo semantics (`deps/credo/lib/credo/config_file.ex:388-399`, verified in RESEARCH probes) |

## Metadata

**Analog search scope:** `test/threadline/*_contract_test.exs` (60 files listed), `lib/threadline/{query,export,capture,semantics,retention,operator_surface}/`, `mix.exs`, `.github/workflows/ci.yml`, `.credo.exs`, `deps/credo/` (semantics only)
**Files scanned:** ~25 read or grepped
**Tracked-source gate:** every analog was confirmed with `git ls-files` or is inside a tracked directory. `deps/credo/**` is cited only as the D-02 copy source and as Credo semantics.
**Pattern extraction date:** 2026-09-22
