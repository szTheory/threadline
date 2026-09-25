# Phase 204: Structure - Pattern Map

**Mapped:** 2026-09-23
**Files analyzed:** 22 file groups. Some groups cover many files: 9 CSS segments, 6 UI family modules, 33 register-site files, 17 migrated test files, and the docs set.
**Analogs found:** 21 / 22. Only the ci.all dedup guard's alias-expansion logic lacks a close analog; a partial one is listed.

All analog paths below were checked with `git ls-files` and are tracked source. Line numbers are from HEAD `86e753a0` and will drift, so re-grep them at execution time.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/threadline/operator_surface/style_byte_lock_test.exs` (new) | test (contract) | transform (render → bytes → sha256) | `test/threadline/dialyzer_ignore_contract_test.exs` (sha pins, fixture dir + README) and `test/threadline/credo_config_contract_test.exs` (demand!/fail! reporter) | role-match (composite) |
| `test/fixtures/style/operator_surface.css` + `README.md` (new) | fixture | file-I/O | `test/fixtures/dialyzer/README.md` | exact (fixture + bump-procedure README) |
| `test/threadline/source_size_contract_test.exs` (new) | test (source-scan gate) | batch (glob → AST → register) | `test/threadline/credo_config_contract_test.exs` + `test/threadline/source_comment_location_contract_test.exs` | exact |
| `lib/threadline/operator_surface/style.ex` (modify: pivot) | component (function component) | transform (compile-time file read) | `lib/threadline/operator_surface/fonts.ex` | exact |
| `lib/threadline/operator_surface/style/{stylesheet,01_tokens … 09_responsive}.css` (new) | asset (compile-time resource) | file-I/O | `priv/fonts/*.woff2` consumed by `fonts.ex` | role-match |
| `test/support/<source_family>.ex` (new: `Threadline.Test.SourceFamily` / `StyleSource`) | test utility | file-I/O | `test/support/operator_surface_fixtures.ex` | role-match |
| `test/support/operator_surface_case.ex` (new) | test case template (macros) | request-response (test endpoint) | `test/support/data_case.ex` (`__using__` + `quote`) + the hand-rolled modules in `test/threadline/operator_surface/live/actor_live_test.exs:1-128` | exact (the modules to extract) |
| `test/threadline/test_structure_contract_test.exs` (new) | test (source-scan gate) | batch | `test/threadline/source_comment_location_contract_test.exs` | exact |
| ci.all dedup guard (new, in `ci_topology_contract_test.exs` or `ci_all_dedup_contract_test.exs`) | test (config gate) | transform (alias tree) | `test/threadline/public_surface_contract_test.exs:399-404` (`Threadline.MixProject.project()[:aliases]`) | partial (reader only) |
| `lib/threadline/operator_surface/ui/{actions,display,page,data,overlay,form}.ex` (new) + `ui.ex` (modify) | component module | request-response (render) | `lib/threadline/operator_surface/components/surface_header.ex`; header of `ui.ex:1-12` | exact |
| `lib/threadline/operator_surface/mechanical_checker/{scorecards,parsing,…}.ex` (new) | utility (maintainer-only) | batch/transform | `lib/threadline/query/filter_params.ex` (internal `@moduledoc false` sibling) | role-match |
| `lib/threadline/query/<private_helpers>.ex` (new) + `query.ex` (modify) | service helper (internal) | CRUD (Ecto query composition) | `lib/threadline/query/filter_params.ex` | exact |
| `lib/threadline/operator_surface/live/timeline_live/{helpers,filters}.ex` (new) + `timeline_live.ex` | LiveView + sibling components | request-response | in-module: `timeline_live.ex:551` `defp timeline_command`, `:682` `defp timeline_filter_drawer`; sibling: `components/surface_header.ex` | exact |
| Other LiveViews (render carving: stress_live, export_status_live, start_live, retention_history_live, transaction_live, actor_live, coverage_live) | LiveView | request-response | `timeline_live.ex:381-549` (render calling `<.timeline_filter_drawer …/>`) | exact |
| Banner files (export_controller, start_live, actor_ref, coverage_live, query) | varied | — | removal rule D-11; the regex lives in the new size gate | n/a |
| 33 register-site files (lib + test) | varied | — | refactor target; gate is `credo_config_contract_test.exs` | n/a |
| `test/threadline/credo_config_contract_test.exs` (modify) | test | batch | itself (:35-41, :91-115) | self |
| `test/threadline/release_artifact_contract_test.exs` (modify) | test | file-I/O (tarball) | itself (:152-200) | self |
| `mix.exs` (modify: aliases, preferred_envs, exclude_patterns) | config | — | itself (:11-30, :122-215, :457-469) | self |
| `bin/verify-bump-rehearsal` (modify) | script | batch | itself (:131-139 `tracked_blast_radius`, :379 gate) | self |
| `.github/workflows/ci.yml`, `release.yml`, CONTRIBUTING.md, guides/* (modify) | config/docs | — | pinned by `ci_topology_contract_test.exs:210-221` and doc contracts | self |
| 17 test files migrated to shared templates + `exports_mix_parity_test.exs` | test | request-response | `actor_live_test.exs:1-128` (before shape) | exact |
| Style-source readers (style_contract, brandbook_token_parity, component_contract, stress_router, rendered_output_contract) | test | file-I/O | `brandbook_token_parity_test.exs:22,34` (`defp style_source, do: File.read!(@style_path)`) | self |

## Pattern Assignments

### `test/threadline/operator_surface/style_byte_lock_test.exs` (test, transform)

**Analog A:** `test/threadline/dialyzer_ignore_contract_test.exs`. It shows the module attributes, the sha pin, and the fixture-dir layout.

Header and pins (lines 1-23):
```elixir
defmodule Threadline.DialyzerIgnoreContractTest do
  use ExUnit.Case, async: true

  @root Path.expand("../..", __DIR__)
  @mix_path Path.join(@root, "mix.exs")
  @ignore_path Path.join(@root, ".dialyzer_ignore.exs")
  @fixture_dir Path.join(@root, "test/fixtures/dialyzer")
  @readme_path Path.join(@fixture_dir, "README.md")
  ...
  @sealed_output_sha256 "12c1164ae38a943a738b339d2758e866c51b284444480585e80d5d591169c3e6"
```
The new test should copy this shape with `@golden_path Path.join(@root, "test/fixtures/style/operator_surface.css")`, `@golden_sha256 "…"` and `@rendered_sha256 "…"`. Use hashes measured at execution time. The research values are `b10d6a2c…` for the full output and `c7baf51e…` for the style-owned suffix.

sha256 helper (line 315):
```elixir
defp sha256(bytes), do: :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
```

DECOUPLE-01 self-check idiom (lines 40-41; also in `credo_config_contract_test.exs:87-88` and `source_comment_location_contract_test.exs:69-70`):
```elixir
planning_directory = "." <> "planning"
refute File.read!(__ENV__.file) =~ planning_directory
```

**Analog B: LiveView guard wrapper.** `lib/threadline/operator_surface/style.ex:1` wraps the module in `if Code.ensure_loaded?(Phoenix.LiveView) do … end`. Wrap the whole test module the same way, as `actor_live_test.exs:1` does.

**Rendering and suffix, verified by research** (RESEARCH.md §Code Examples):
```elixir
full =
  Threadline.OperatorSurface.Style.css(%{__changed__: nil})
  |> Phoenix.HTML.Safe.to_iodata()
  |> IO.iodata_to_binary()
prefix = "<style>" <> Threadline.OperatorSurface.Fonts.face_css() <> "</style>"
true = String.starts_with?(full, prefix)
style_owned = binary_part(full, byte_size(prefix), byte_size(full) - byte_size(prefix))
```
The test is `async: true`, so never toggle `Application.put_env`. Strip the prefix instead. Also assert `Application.get_env(:threadline, :operator_surface_embed_fonts, true) == true`. The fonts-off branch is in `fonts.ex:60-66`.

**Failure reporting.** Do not use a bare `assert a == b`, because it prints about 100 KB of output. Build a message string the way `credo_config_contract_test.exs:395-399` and `:478-483` build theirs, then `flunk`/`assert false, msg` with sizes, the first differing line, the byte offset, the new sha, and the regeneration one-liner.

**Pitfall-2 guard** (segment order and `@external_resource` coverage; add it after the pivot): read `Threadline.OperatorSurface.Style.__info__(:attributes)` or a `@doc false` accessor. Assert that the segment list equals the explicit ordered list, and that it equals the sorted `Path.wildcard("lib/threadline/operator_surface/style/*.css")`, so no orphans are left.

---

### `test/fixtures/style/README.md` (fixture docs)

**Analog:** `test/fixtures/dialyzer/README.md`. It has a short provenance paragraph, then a "## Updating" section with a numbered command list:
```markdown
## Updating a slice

1. Capture the full raw analyzer baseline with `MIX_ENV=dev mix dialyzer --no-check --format raw --ignore-exit-status`.
2. Update only the fixture assigned to the source slice. ...
3. Verify every fixture independently:
```
Use one paragraph plus the bump steps: the `MIX_ENV=test mix run --no-start -e …` regeneration, paste both hashes, and commit with a why. Do not use planning vocabulary. The file is not packaged, but keep it clean anyway. Do **not** put it under `test/fixtures/operator_surface/`, because `operator_surface_fixture_contract_test.exs:65-71` asserts that the whole corpus matches `manifest.sha256`.

---

### `test/threadline/source_size_contract_test.exs` (test, batch source scan)

**Analog A:** `test/threadline/credo_config_contract_test.exs`. Copy its structure: the exact register, the self-test with a synthetic planted violation, the empty-scan guard, and demand!/fail!.

Register attributes (lines 32-41). New shape: `@file_exceptions %{path => {exact_lines, reason}}` and `@function_exceptions %{{path, name, arity} => {exact_lines, reason}}`.
```elixir
@root Path.expand("../..", __DIR__)
@scan_glob "{lib,test}/**/*.{ex,exs}"

@successor "Phase 204 / STRUCT-07"
@register %{
  Credo.Check.Refactor.Nesting => {26, "Phase 204 / STRUCT-07"},
  Credo.Check.Refactor.CyclomaticComplexity => {16, "Phase 204 / STRUCT-07"}
}
@ceiling 42
@historical_max 46
```
Use `@scan_glob "lib/**/*.{ex,css}"` for the file limit and `lib/**/*.ex` for the function limit and the banner check. This file is in `test/`, so the phase vocabulary ban does not apply, but keep the reason strings adopter-neutral.

Scanner (lines 355-360):
```elixir
defp scanned_files do
  @root
  |> Path.join(@scan_glob)
  |> Path.wildcard()
  |> Enum.map(&{Path.relative_to(&1, @root), File.read!(&1)})
end
```

Pure validator with a throw-based error collector (lines 362-405, 506-508):
```elixir
defp validate_register(files, register, ceiling) do
  demand!(
    files != [],
    "the scanned file set is empty. A broken #{@scan_glob} glob would let this " <>
      "register pass vacuously, which is worse than having no gate at all."
  )
  ...
  :ok
catch
  {:contract_error, message} -> {:error, message}
end

defp demand!(true, _message), do: :ok
defp demand!(false, message), do: fail!(message)
defp fail!(message), do: throw({:contract_error, message})
```

Planted-violation self-test (lines 91-115). Mirror it with a synthetic source that has an 801-line file and a 121-line def, and assert `{:error, msg}`. Also plant a stale exception, where the file is under its registered limit, and assert that it fails.
```elixir
test "one extra or one missing disable fails exact equality" do
  ...
  extra = exact ++ [synthetic("lib/extra.ex", [pair("Nesting")])]
  assert {:error, message} = validate_register(extra, @register, @ceiling)
  assert message =~ "adding a disable requires raising the register in review"
```
Synthetic-source builder (lines 501-504):
```elixir
defp synthetic(path, bodies) do
  {path,
   "defmodule Synthetic do\n  def run(x) do\n" <> Enum.join(bodies) <> "    x\n  end\nend\n"}
end
```
Sorted offender listing (lines 478-483). Reuse it for the path:line listing of offenders:
```elixir
defp reject_offenders!(offenders, rule) do
  listed = Enum.map_join(offenders, ", ", &"#{&1.path}:#{&1.line}")
  fail!("#{rule}. Offenders: #{listed}. " <> @ratchet_message)
end
```

**AST walker analog.** The same file uses `Macro.prewalk` over a parsed source (lines 222-229):
```elixir
ast = @credo_config |> File.read!() |> Code.string_to_quoted!()
{_ast, enabled_keys} =
  Macro.prewalk(ast, [], fn
    {{:__block__, _, [:enabled]}, _value} = node, acc -> {node, [node | acc]}
    {:enabled, _value} = node, acc -> {node, [node | acc]}
    node, acc -> {node, acc}
  end)
```
Combine it with RESEARCH's per-clause measurement. Measure `token_metadata: true` and `meta[:end][:line] - meta[:line] + 1`, unwrap `{:when, _, [head | _]}`, take the max per name/arity, and never sum clauses.

**Analog B:** `test/threadline/source_comment_location_contract_test.exs`. Use it for the banner describe block (STRUCT-04), since it scans comments only.

Lines 19-33:
```elixir
@lib_glob "lib/**/*.ex"

@location_citation ~r/[A-Za-z0-9_.\/-]+\.exs?:\d+(?:-\d+)?/

defp lib_files, do: @lib_glob |> Path.wildcard() |> Enum.sort()

defp comments(path) do
  {:ok, _ast, comments} =
    path
    |> File.read!()
    |> Code.string_to_quoted_with_comments(file: path)

  comments
end
```
Non-empty guard (lines 35-39) and detector sanity test (lines 61-71). Copy both for the banner regex `^\s*#\s*(-{3,}|={3,}|─{3,}|\*{3,})`. Scan `comments/1` text instead of raw lines so string literals are ignored. Add the `.heex` / `embed_templates` refutation beside it.

---

### `lib/threadline/operator_surface/style.ex` (pivot) + `style/*.css`

**Analog:** `lib/threadline/operator_surface/fonts.ex`. This is the only `@external_resource` use in `lib/`.

Compile-time resource loop (lines 30-34):
```elixir
@fonts_dir Path.join([__DIR__, "..", "..", "..", "priv", "fonts"])

for {_family, _weight, file} <- @faces do
  @external_resource Path.join(@fonts_dir, file)
end
```
Compile-time read into a module attribute (lines 36-53): `@face_css (for … File.read!() … end) |> Enum.join("\n")`.

**Current `style.ex` shape to preserve** (lines 1-16, 4498-4507):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Style do
    @moduledoc false

    import Phoenix.Component

    alias Threadline.OperatorSurface.Fonts

    def css(assigns) do
      assigns =
        assign(
          assigns,
          :fonts_html,
          Phoenix.HTML.raw(font_face_style())
        )

      ~H"""
      {@fonts_html}<style>
      ...
    defp font_face_style do
      case Fonts.face_css() do
        "" -> ""
        css -> "<style>" <> css <> "</style>"
      end
    end
```
Target shape, prototyped byte-identical in RESEARCH. Use `@style_dir Path.join(__DIR__, "style")` and an explicit `@segments ~w(...)`, with `for seg <- @segments, do: @external_resource Path.join(@style_dir, seg)` and `@stylesheet Enum.map_join(...)`, and wrap it in `Phoenix.HTML.raw(@stylesheet)`. Without `raw`, the lock fails. The single call site is `ui.ex:1165` `<Threadline.OperatorSurface.Style.css />`, and it stays unchanged.

**Packaging:** `mix.exs:440` `files: ~w(lib priv/fonts …)` already covers `lib/**`. Add a `.css` presence assertion next to `release_artifact_contract_test.exs:141-142` (`assert "lib/threadline.ex" in entries`).

**Lib comment rule:** `source_comment_location_contract_test.exs` rejects `file.ex:NN` citations in `lib/` comments. It covers `.ex` files only, but keep CSS comments free of them too. `rendered_output_contract_test` must be widened to scan `style/*.css` for planning vocabulary (D-05).

---

### Source-family reader in `test/support` (test utility, file-I/O)

**Analog:** `test/support/operator_surface_fixtures.ex` (lines 1-30). It is a plain `@moduledoc false` module with path-resolving `!` functions:
```elixir
defmodule Threadline.Test.OperatorSurfaceFixtures do
  @moduledoc false

  @root Path.expand("../fixtures/operator_surface", __DIR__)
  ...
  def root!, do: required_directory!(@root, "operator-surface fixture corpus")
```
Naming convention: `Threadline.Test.*`. Provide `read!(path)`, which returns the file bytes concatenated with the sorted `Path.wildcard(Path.rootname(path) <> "/*.{ex,css}")`. Call sites being repointed include `brandbook_token_parity_test.exs:22,34` (`defp style_source, do: File.read!(@style_path)`), `style_contract_test.exs:5`, and `stress_router_test.exs:136` (`@style_source "lib/threadline/operator_surface/style.ex"`). Wildcards are fine in tests. The wildcard ban applies only to `@segments` in lib.

---

### `test/support/operator_surface_case.ex` (test case template)

**Analog A, the macro shape:** `test/support/data_case.ex` (whole file, 29 lines):
```elixir
defmodule Threadline.DataCase do
  @moduledoc """
  Test case for integration tests that require a real PostgreSQL database.
  ...
  """

  defmacro __using__(opts) do
    opts = Keyword.merge([async: false], opts)

    quote do
      use ExUnit.Case, unquote(opts)

      alias Threadline.Capture.{AuditChange, AuditTransaction}
      alias Threadline.Test.Repo
      import Ecto.Query
      ...
    end
  end
end
```
Every new module needs a real `@moduledoc`, because the ModuleDoc check has `ignore_names: []`. Keep each `quote` under 150 lines (LongQuoteBlocks). Wrap the whole file in `if Code.ensure_loaded?(Phoenix.LiveView) do`, because `verify.compile_no_optional` compiles `test/support`.

**Analog B, the content to extract:** `test/threadline/operator_surface/live/actor_live_test.exs`.

Layouts (lines 2-19):
```elixir
defmodule Threadline.OperatorSurface.ActorLiveTest.Layouts do
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <html>
      <head><title>Test</title></head>
      <body><%= @inner_content %></body>
    </html>
    """
  end

  def render("500.html", assigns) do
    ~H"""
    Error 500: <%= inspect(assigns.reason) %>
    """
  end
end
```
Router (lines 21-40). The `pipeline :browser` block becomes the `__using__` body. `scope` + mount stay per file:
```elixir
use Phoenix.Router
import Phoenix.LiveView.Router
require Threadline.OperatorSurface.Router

pipeline :browser do
  plug(:accepts, ["html"])
  plug(:fetch_session)
  plug(:fetch_live_flash)

  plug(:put_root_layout,
    html: {Threadline.OperatorSurface.ActorLiveTest.Layouts, :root}
  )
end
```
Per-file router helpers must stay in the router module, because they are captured as `&__MODULE__.fun/1` (lines 42-72: `import Ecto.Query`, `def auth/1`, `def scope_operator_query/3`). The timeline variant adds `plug(:put_test_actor)` and `def put_test_actor/2` (`timeline_live_test.exs:~95-117`), which is the `opts[:browser_plugs]` delta.

Endpoint, default variant (lines 75-90):
```elixir
use Phoenix.Endpoint, otp_app: :threadline

@session_options [
  store: :cookie,
  key: "_threadline_key",
  signing_salt: "v8q+QWvj"
]

plug(Plug.Session, @session_options)
plug(:fetch_session)
plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
plug(Plug.MethodOverride)
plug(Plug.Head)
plug(Threadline.OperatorSurface.ActorLiveTest.Router)
```
Variant 2 is `export_controller_test.exs:85-99`: `parsers: [:urlencoded, :json] … json_decoder: Jason`, with salt `String.duplicate("x", 8)`. Variant 3 is `gating_test.exs:58-72`, `ExportsDisabledEndpoint`, which has **no `Plug.Parsers`**. The template therefore needs `parsers: false`.

Case setup with env before start (lines 108-131):
```elixir
use Threadline.DataCase, async: false
import Phoenix.ConnTest
import Phoenix.LiveViewTest

@endpoint Threadline.OperatorSurface.ActorLiveTest.Endpoint

setup_all do
  Application.put_env(:threadline, Threadline.OperatorSurface.ActorLiveTest.Endpoint,
    secret_key_base: "x" |> String.duplicate(64),
    live_view: [signing_salt: "x" |> String.duplicate(8)],
    render_errors: [view: Threadline.OperatorSurface.ActorLiveTest.Layouts]
  )

  start_supervised!(@endpoint)
  :ok
end
```
For the `on_exit` restore in `start_endpoint!/2`, see `stress_router_test.exs:138-150`, which saves `Application.get_env`, puts, and uses an `on_exit(fn -> … end)` restore. For deletes, `verify_coverage_task_test.exs:150` has `defp restore_env(key, nil), do: Application.delete_env(:threadline, key)`.

**Cross-file coupling to remove:** `exports_mix_parity_test.exs:42-50` currently does `_ = start_supervised(@endpoint)` against `ExportControllerTest.Endpoint`. Give it its own endpoint through the template.

---

### `test/threadline/test_structure_contract_test.exs` (test, source scan)

**Analog:** `test/threadline/source_comment_location_contract_test.exs`. Copy the whole file shape: a moduledoc explaining the invariant, a glob, a non-empty guard test, an offenders comprehension sorted by path, a multi-line failure message, a detector-sanity test, and the planning self-check. Here the glob is `test/**/*.{ex,exs}` and the matcher is `~r/^\s*use Phoenix\.(Endpoint|Router)\b/m`.

Offender comprehension with message (lines 42-58):
```elixir
offenders =
  for path <- lib_files(),
      %{line: line, text: text} <- comments(path),
      location_citation?(text) do
    {path, line, text}
  end
  |> Enum.sort_by(fn {path, line, _text} -> {path, line} end)

assert offenders == [],
       "these lib comments cite a file:line location, ..." <>
         Enum.map_join(offenders, "\n", fn {path, line, text} ->
           "  #{path}:#{line}  #{text}"
         end)
```
Stale-allowlist check pattern: `release_artifact_contract_test.exs:180-186`, which asserts `File.regular?(path)` for each listed path with a "renamed? then move this list" message. Use it for `@allowlist %{path => reason}` (router_test, stress_router_test, support/stress_router_prod_compile.exs).

---

### ci.all dedup guard (test, config)

**Partial analog:** `test/threadline/public_surface_contract_test.exs:399-404`, which reads aliases at runtime:
```elixir
defp discovered_aliases do
  Threadline.MixProject.project()[:aliases]
  |> Keyword.keys()
  |> Enum.map(&to_string/1)
  |> MapSet.new()
end
```
Recursive expansion needs a small new helper. String steps whose first word is a key in the alias keyword should recurse; function captures are opaque. No existing code does this. `ci_topology_contract_test.exs:82-112` is the **regex / `:binary.match`** style that D-24 explicitly replaces. Its `{pos, _} = :binary.match(ci_block, "\"verify.doc_contract\"")` at :94 raises a MatchError once the step is removed, so the same commit must delete that line and the `pos_verify_doc_contract` comparisons (:110-111). It must also delete :60-79 (the alias content asserts) and :218-219 (`- name: Doc contract tests` / `run: mix verify.doc_contract`).

---

### `lib/threadline/operator_surface/ui/*.ex` family modules (component, request-response)

**Analog:** `lib/threadline/operator_surface/components/surface_header.ex` (lines 1-18):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Components.SurfaceHeader do
    @moduledoc false

    use Phoenix.Component

    attr(:coverage, :map, required: true)
    attr(:base_path, :string, required: true)
    ...
    def surface_header(assigns) do
      ~H"""
```
Copy the header from `ui.ex:1-12`. Note that `ui.ex` guards on `Phoenix.Component`, not `Phoenix.LiveView`:
```elixir
if Code.ensure_loaded?(Phoenix.Component) do
  defmodule Threadline.OperatorSurface.UI do
    @moduledoc false
    use Phoenix.Component
    import Phoenix.Component, except: [link: 1]
    alias Phoenix.LiveView.JS
    alias Threadline.OperatorSurface.Components.Icon
    alias Threadline.OperatorSurface.Presentation
    alias Threadline.OperatorSurface.Script

    @doc false
    attr(:type, :string, default: "button")
```
Only the module that defines `link/1` needs `except: [link: 1]`. Each family keeps only the aliases it uses, or `--warnings-as-errors` fails on an unused alias. No `defdelegate` facades.

---

### `lib/threadline/query/<helpers>.ex` and `mechanical_checker/*.ex` (internal sibling modules)

**Analog:** `lib/threadline/query/filter_params.ex` (lines 1-4 and following). This is an existing internal sibling of `Threadline.Query`:
```elixir
defmodule Threadline.Query.FilterParams do
  @moduledoc false

  alias Threadline.Semantics.ActorRef

  # Allowed URL keys mapped to their filter atoms. Declaring the atoms in a
  # compile-time literal here ...
  @filter_key_atoms %{
```
Put the explanatory prose in plain `#` comments, not banners. Public functions (`def`) in a `@moduledoc false` module are the internal-API convention. Other siblings to check for naming: `lib/threadline/query/{scope,actor_history_page}.ex`.

**Constraints specific to these extractions:**
- `mechanical_checker/*` and any `stress_live/*`: widen `mix.exs:462-468` to directory patterns in the same commit. The current patterns are exact-file anchored:
  ```elixir
  ~r{^lib/threadline/operator_surface/live/stress_live\.ex$},
  ~r{^lib/threadline/operator_surface/mechanical_checker\.ex$},
  ```
  Then extend `release_artifact_contract_test.exs:152-169` `@maintainer_only_paths` / `@maintainer_only_prefixes`. That list is prefix-based: `"lib/threadline/critic_trust/"`.
- `mechanical_checker.ex`: keep the constants at :26-45 and `linearize_channel` textually in the parent. They are pinned by `mechanical_checker_test.exs:13-59`. Seams at :120/:132/:432/:536/:661/:743/:804.
- `query.ex`: keep the `filter_by_*` group (:840-894), the three `repo.preload(… storage_opts([], opts))` lines, and `@allowed_timeline_filter_keys`. These are pinned by `code_walkthrough_doc_contract_test.exs:21-23` and `query_test.exs:615-620`.

---

### `timeline_live.ex` + other LiveViews (render carving)

**Analog, in-module:** `lib/threadline/operator_surface/live/timeline_live.ex`. `render/1` at :385 calls `<.timeline_filter_drawer filters_raw={@filters_raw} … />` (:532-547). The component body at :551:
```elixir
defp timeline_command(assigns) do
  assigns =
    assigns
    |> assign(:window, filter_window_summary(assigns.filters_raw))
    |> assign(:active_filters, active_filter_pairs(assigns.filters_raw))
    |> assign(:advanced_filter_count, advanced_filter_count(assigns.filters_raw))

  ~H"""
  <section class="tl-toolbar tl-timeline-command" aria-labelledby="timeline-command-title">
```
**Gap:** `timeline_live.ex` has **0** `attr(` declarations, so there is no in-LiveView precedent for D-08's "with `attr` declarations". The `attr(...)` paren style comes from `components/surface_header.ex:7-16` and `ui.ex:12`. Remember that attrs add lines, and `export_status_live.ex` is at 796.

The banner triplets to remove are at `timeline_live.ex:381-383` and similar:
```elixir
# --------------------------------------------------------------------------
# render/1
# --------------------------------------------------------------------------
```
They are removed by the section becoming a sibling module or function, or deleted when the section is a single clause group (D-11).

---

### `test/threadline/credo_config_contract_test.exs` (modify)

Change lines 36-40 to `@register %{Nesting => {0, @successor}, CyclomaticComplexity => {0, @successor}}` and `@ceiling 0`. Keep the keys: `validate_register_shape!` at :407-411 demands exactly the two check keys, and `Map.fetch!` at :392 needs them. A literal `%{}` would fail the shape check, so the planner decides whether to keep zeroed keys (least change) or rework the shape check. The self-test at :91-115 uses `nesting - 1` from the live register, which gives -1 at zero. Rewrite it against `register_with(2, 1)` (helper at :490-495). Moduledoc :9-13 prose needs updating.

---

### `mix.exs`, `bin/verify-bump-rehearsal`, workflows, docs (modify)

- `mix.exs:13` (preferred env), `:129-131` (alias), `:196` (ci.all entry), `:206-211` (critic_trust / mechanical entries in ci.all), plus comments `:150-161`.
- `bin/verify-bump-rehearsal:379` currently runs `run_gate "mix verify.doc_contract at $NEXT" mix verify.doc_contract &&`, and the summary is at `:419`. For the derived list, the script's own list-building idiom is `tracked_blast_radius()` at :131-139, a brace group of `printf`/`git ls-files` piped to `sort -u`. Use a `while IFS= read -r` loop (no `mapfile`), run inside `$CLONE` as `run_gate` does with `cd "$CLONE"` (:367), and guard `>= 30`.

## Shared Patterns

### Contract-gate skeleton (apply to style_byte_lock, source_size, test_structure, dedup guard)
**Source:** `test/threadline/credo_config_contract_test.exs:362-405, 478-508`, `source_comment_location_contract_test.exs:35-71`
- `use ExUnit.Case, async: true`, `@root Path.expand("../..", __DIR__)`
- A pure `validate_*` returning `:ok | {:error, msg}` via `throw({:contract_error, msg})`, so the self-test can feed synthetic input
- An empty-scan-set guard with an explicit "pass vacuously" message
- A detector-sanity or planted-violation test
- The `"." <> "planning"` self-refute

### LiveView optional-dep guard
**Source:** `style.ex:1`, `components/surface_header.ex:1`, `actor_live_test.exs:1`
Apply to `operator_surface_case.ex`, `style_byte_lock_test.exs`, every `ui/*.ex`, and every LiveView sibling:
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
```
(`ui.ex` uses `Phoenix.Component`. Mirror the parent's guard.)

### Internal module convention
**Source:** `lib/threadline/query/filter_params.ex:1-2`, `fonts.ex:1-2`
Apply to every new lib module:
- deliberate `@moduledoc false`
- prose as plain `#` comments
- no `# ---` banners, since the new gate forbids them
- no `file:line` citations in comments (`source_comment_location_contract_test`)
- no `Phase N` / `STRUCT-0x` / `D-NN` text (`release_artifact_contract_test.exs:7-14` `@banned_shapes`)

### Maintainer-only packaging
**Source:** `mix.exs:457-469` + `release_artifact_contract_test.exs:148-200`
Apply to any file under `mechanical_checker/`, `stress_live/`, or `stress_fixtures`. Widen the pattern and extend the paths/prefixes in the same commit. User-visible LiveView siblings should instead join `@source_owners` (`release_artifact_contract_test.exs:16-47`).

### Source-text pin repointing
**Source:** `brandbook_token_parity_test.exs:22,34`, `stress_router_test.exs:130-136`, `style_contract_test.exs:5`
Before each extraction, run `grep -rn "<old path>" test examples/threadline_phoenix/test` and repoint the hits to the source-family reader in the same commit.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Recursive alias-expansion helper (inside the dedup guard) | test utility | transform | No existing code expands Mix alias chains. Only the flat key reader exists (`public_surface_contract_test.exs:399-404`). Build it from D-24's spec. |

Two partial gaps are noted inline above:
- No in-LiveView `attr` precedent. Use the `components/` style.
- No existing on_exit env-restore helper as a function. Copy from `stress_router_test.exs:138-150`.

## Metadata

**Analog search scope:** `test/support/`, `test/threadline/*contract_test.exs`, `test/threadline/operator_surface/**`, `lib/threadline/operator_surface/**`, `lib/threadline/query/`, `mix.exs`, `bin/verify-bump-rehearsal`, `test/fixtures/`
**Files scanned:** ~25 read or grepped
**Pattern extraction date:** 2026-09-23
