# Phase 57: optional-deps-and-module-gating - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 3 (1 new, 2 modified)
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Status | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|--------|------|-----------|----------------|---------------|
| `mix.exs` | modify | config (Mix.Project) | build/declarative | self (existing `deps/0` + `aliases/0` + `ci.all` step list) | exact (in-place edit) |
| `lib/threadline/operator_surface.ex` | new | namespace module (documentation-only, gated) | compile-time guard | `lib/threadline/telemetry.ex` (top-level shape) + `lib/threadline/integrations/sigra.ex:67` (`Code.ensure_loaded?` precedent) + Sentry's `live_view_hook.ex` (file-scope gating) | role-match (no internal compile-time gated module exists yet) |
| `.github/workflows/ci.yml` | modify | CI config (GH Actions job) | request-response (single-checkout / single-step) | self → `verify-format` job (lines 16-31) and `verify-credo` job (lines 33-48) | exact (twin pattern) |

---

## Pattern Assignments

### `mix.exs` (config, build/declarative)

**Analog:** self — extend the existing `deps/0`, `aliases/0`, and `ci.all` step list in place.

**Imports / module shape pattern** (lines 1-5):

```elixir
defmodule Threadline.MixProject do
  use Mix.Project

  @version "0.3.0"
  @source_url "https://github.com/szTheory/threadline"
```

No change to this header. Phase 57 does not touch `@version`.

**`deps/0` shape pattern** (lines 49-60):

```elixir
defp deps do
  [
    {:ecto_sql, "~> 3.10"},
    {:postgrex, "~> 0.17"},
    {:jason, "~> 1.4"},
    {:nimble_csv, "~> 1.2"},
    {:plug, "~> 1.15"},
    {:telemetry, "~> 1.2"},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:ex_doc, "~> 0.34", only: :dev, runtime: false}
  ]
end
```

Convention to copy:
- Runtime hard deps come first, in roughly install-order.
- `:dev`/`:test`-scoped deps come last.
- One dep per line, two-space indent, trailing comma except last entry.
- `optional: true` is keyword-list-style after the version constraint (see Sentry analog).

**Insertion point for the four NEW optional deps:** after `{:telemetry, "~> 1.2"},` (line 56) and before `{:credo, ...}` (line 57). They form their own contiguous block of `optional: true` entries:

```elixir
{:phoenix, "~> 1.7", optional: true},
{:phoenix_live_view, "~> 1.0", optional: true},
{:phoenix_html, "~> 4.0", optional: true},
{:phoenix_pubsub, "~> 2.1", optional: true},
```

Per CONTEXT.md D-02: `:plug` line stays unchanged at `{:plug, "~> 1.15"}` — it is HARD, not optional.

**`aliases/0` shape pattern** (lines 62-83):

```elixir
defp aliases do
  [
    "verify.format": ["format --check-formatted"],
    "verify.credo": ["credo --strict"],
    "verify.test": ["test"],
    "verify.threadline": ["threadline.verify_coverage"],
    "verify.doc_contract": ["test test/threadline/readme_doc_contract_test.exs"],
    "verify.release": &verify_release/1,
    "verify.topology": ["threadline.verify_topology"],
    "verify.example": &verify_example/1,
    "verify.bench": &verify_bench/1,
    "ci.all": [
      "verify.format",
      "verify.credo",
      "compile --warnings-as-errors",
      "verify.test",
      "verify.threadline",
      "verify.example",
      "verify.doc_contract"
    ]
  ]
end
```

Convention to copy:
- Atom-key syntax `"verify.foo": [...]` for declarative one-liners.
- List-of-strings value where each string is a single Mix invocation; Mix splits each string on whitespace into task-name + args.
- The `ci.all` step list is itself a list of alias names (preferred — names CI cites verbatim) interleaved with the one raw `compile --warnings-as-errors` invocation.
- Function-reference alias style (`&verify_release/1`) is used only when the alias needs procedural shell logic; the new `verify.compile_no_optional` is purely a Mix flag, so it uses the simple list-of-strings form.

**New alias entry** (insertion: alongside the other `verify.*` simple aliases — alphabetic-friendly placement is between `verify.bench` and `ci.all`):

```elixir
"verify.compile_no_optional": ["compile --no-optional-deps --warnings-as-errors"],
```

**`ci.all` step list extension** — per CONTEXT.md D-10, insert AFTER `compile --warnings-as-errors` and BEFORE `verify.test`:

```elixir
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

**`preferred_envs` consideration** (lines 7-20): `ci.all` is already pinned to `:test`. The new `verify.compile_no_optional` step inside `ci.all` inherits that env. Adding a separate `preferred_envs` entry for `verify.compile_no_optional` is unnecessary because the alias is invoked stand-alone (in the dedicated CI job) where the default env (`:dev`) is fine — the flag is env-agnostic.

**`package/0` and `docs/0` are NOT touched** (lines 146-217). Per CONTEXT.md D-03 and "Things to NOT Do":
- `package: [files: ~w(lib ...)]` already auto-includes `lib/threadline/operator_surface.ex`.
- `docs: [groups_for_modules: [...]]` does NOT get a new entry for `Threadline.OperatorSurface` in Phase 57 — wait until Phase 58.

---

### `lib/threadline/operator_surface.ex` (namespace module, compile-time gated)

**Status:** NEW file.

**Internal analog:** `lib/threadline/telemetry.ex` (lines 1-29) — closest in role (top-level `lib/threadline/*.ex` module file with substantial `@moduledoc` and minimal body) and `lib/threadline/integrations/sigra.ex:67` (only existing `Code.ensure_loaded?` call site in the codebase, demonstrating that the function name is already familiar but used at *runtime* — Phase 57 introduces the same function at *file scope* / compile time).

**External analog (canonical, byte-verified per RESEARCH.md):** `getsentry/sentry-elixir/lib/sentry/live_view_hook.ex` — the file-scope `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule … end end` shape, the italicized `*Available since vX.Y.Z*` line inside `@moduledoc """..."""`, and the separate `@moduledoc since: "X.Y.Z"` attribute placed AFTER the heredoc.

**Top-level module shape pattern** (`lib/threadline/telemetry.ex` lines 1-29):

```elixir
defmodule Threadline.Telemetry do
  @moduledoc """
  Telemetry integration helpers for Threadline.

  Threadline emits three telemetry events:

  - `[:threadline, :transaction, :committed]` — after an `AuditTransaction` is
    committed. Automatically emitted (with `table_count: 0`) when
    `Threadline.record_action/2` succeeds. For accurate per-transaction counts,
    call `Threadline.Telemetry.transaction_committed/2` explicitly after a known
    DB transaction commit.
  ...
  """
```

Convention to copy from internal style:
- `@moduledoc """..."""` heredoc opens immediately after `defmodule ... do` with one blank line preceding it (match `Threadline.Health` and `Threadline.Plug` shape — heredoc is the first attribute, no blank line between `do` and `@moduledoc`).
- Sentence-case opening line that names what the module is.
- Markdown bullet lists, code fences, and inline backticks for module/function names — matches Threadline's prevailing docstring style (`Threadline.Telemetry`, `Threadline.Health`, `Threadline.Plug` all do this).
- No `alias` / `import` block on a docs-only namespace module (telemetry.ex shows that even `Threadline.Telemetry` has no aliases when its surface is small).
- File ends with the closing `end` of `defmodule`. Phase 57's file ends one level deeper — with the closing `end` of the outer `if Code.ensure_loaded?(...) do`.

**`Code.ensure_loaded?` precedent in repo** (`lib/threadline/integrations/sigra.ex` line 67):

```elixir
defp sigra_available?, do: Code.ensure_loaded?(Sigra.Session)
```

Note for the planner: this is a **runtime soft-dep guard** wrapping function calls inside the module body. Phase 57 uses the **same function name** but at a **different layer** — file-scope, surrounding the entire `defmodule`. The two idioms LOOK similar (`Code.ensure_loaded?(SomeModule)`) but solve different problems:
- `sigra.ex` → "is Sigra.Session callable right now?" (runtime branch)
- `operator_surface.ex` → "should this module's BEAM file even be produced?" (compile-time gate)

The new module's `@moduledoc` should NOT itself document this distinction (per CONTEXT.md "Domain language preserved" — keep the docstring focused on the operator-surface contract, not the gating mechanic). The distinction is for plan-internal documentation only.

**File-scope gating pattern (external analog — copy verbatim shape):**

Sentry's `lib/sentry/live_view_hook.ex` (verified by RESEARCH.md):

```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Sentry.LiveViewHook do
    @moduledoc """
    A module that provides a `Phoenix.LiveView` hook to add Sentry context and breadcrumbs.

    *Available since v10.5.0.*

    ...
    """

    @moduledoc since: "10.5.0"

    import Phoenix.LiveView, only: [attach_hook: 4, get_connect_info: 2]
    # ...
  end
end
```

Three structural details to mirror:
1. **`if Code.ensure_loaded?(Phoenix.LiveView) do`** wraps the WHOLE `defmodule`. NOT inside the module body. NOT around a `use Phoenix.LiveView`. This is the elixir-lang/elixir#8970 footgun avoidance.
2. **Italicized "since" line** lives inside the `@moduledoc """..."""` heredoc on its own line: `*Available since 0.4.0.*`. Per RESEARCH.md, drop the `v` prefix to match Threadline's CHANGELOG bare-version style (`0.3.0`, `0.4.0`).
3. **Separate `@moduledoc since: "0.4.0"`** attribute sits AFTER the closing `"""` of the docstring (one blank line between them is fine). ExDoc reads this attribute to render a "since 0.4.0" badge in the module header.

**Final file shape (per RESEARCH.md Example C — planner has discretion on exact wording):**

```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface do
    @moduledoc """
    Namespace for the Threadline operator surface — the opt-in mountable
    LiveView surface that turns Threadline's investigation contracts into
    one-click answers for documented support questions.

    *Available since 0.4.0.*

    This module is gated at file scope on `Code.ensure_loaded?(Phoenix.LiveView)`
    and only compiles when `:phoenix_live_view` is present in the consumer's
    deps. Capture-only adopters who install `:threadline` without
    `:phoenix_live_view` will not have this module loaded and will not see
    it in their hexdocs build.

    Mount the surface from a host Phoenix router using the
    `Threadline.OperatorSurface.Router` macro (shipping in v0.4.0).
    """

    @moduledoc since: "0.4.0"
  end
end
```

**Body must remain empty** (no functions, no `@behaviour`, no `defstruct`, no `alias`, no `import`) per CONTEXT.md D-05 and D-06. The phase ships exactly one gated module that proves the wrapping idiom under production conditions; the first behavioural module under `lib/threadline/operator_surface/` (the subdirectory) lands in Phase 58.

---

### `.github/workflows/ci.yml` (CI config, GH Actions job)

**Analog:** self — twin the existing `verify-format` (lines 16-31) and `verify-credo` (lines 33-48) jobs. Both are cheap, single-checkout, single-setup-beam, single-mix-step jobs without Postgres services — exactly the shape the new compile-only check needs.

**Existing top-of-file job-id contract comment** (lines 1-2):

```yaml
# Job id contract — stable YAML `jobs:` keys are relied on by docs and `act`:
# verify-format, verify-credo, verify-test, verify-pgbouncer-topology, verify-docs, verify-hex-package, verify-release-shape
```

**Update pattern:** insert `verify-compile-no-optional` between `verify-credo` and `verify-test` to preserve the comment's current ordering (which appears to be roughly file-order, not alphabetical):

```yaml
# Job id contract — stable YAML `jobs:` keys are relied on by docs and `act`:
# verify-format, verify-credo, verify-compile-no-optional, verify-test, verify-pgbouncer-topology, verify-docs, verify-hex-package, verify-release-shape
```

**Trigger pattern (`on:` block, lines 6-10):**

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
```

No change. The new job inherits this — runs on PRs and on `main` push, satisfying CONTEXT.md D-12 and the OSS DNA "expensive jobs run on `main` even when PRs are path-filtered" rule (trivially, because this workflow is not path-filtered today).

**`permissions:` block (lines 12-13):** unchanged (`contents: read`).

**Twin job pattern — `verify-format` (lines 16-31):**

```yaml
  verify-format:
    name: Check formatting
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4

      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.17.3"
          otp-version: "27.0"

      - name: Install dependencies
        run: mix deps.get

      - name: Check formatting
        run: mix verify.format
```

**Twin job pattern — `verify-credo` (lines 33-48):**

```yaml
  verify-credo:
    name: Run Credo (strict)
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4

      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.17.3"
          otp-version: "27.0"

      - name: Install dependencies
        run: mix deps.get

      - name: Run Credo
        run: mix verify.credo
```

Conventions to copy verbatim:
- **Two-space indent** for the job key under `jobs:`; **four-space indent** for keys inside the job.
- **Stable id (the YAML key)** — `verify-compile-no-optional`. Immutable post-merge per the OSS DNA / job-id contract. Hyphens (not underscores) in YAML keys; the alias name uses underscores (`verify.compile_no_optional` → `verify-compile-no-optional`). This split is consistent with `verify.format` ↔ `verify-format`.
- **`name:`** field uses Title Case sentence ("Check formatting", "Run Credo (strict)", "Run test suite"). For the new job: `name: Compile without optional deps`.
- **`runs-on: ubuntu-24.04`** — exact pinned value used by every job.
- **`actions/checkout@v4`** — exact pin.
- **`erlef/setup-beam@v1`** — exact pin.
- **`elixir-version: "1.17.3"`** and **`otp-version: "27.0"`** — exact quoted strings used elsewhere.
- **`Install dependencies` / `run: mix deps.get`** — verbatim step name and command.
- **Final step** uses sentence-case `name:` ("Check formatting", "Run Credo") and **runs the `mix verify.*` alias, NOT the raw command** — enforces the OSS DNA "named entrypoints" rule. Confirmed by `verify-format` running `mix verify.format` (not `mix format --check-formatted`) and `verify-credo` running `mix verify.credo` (not `mix credo --strict`).

**New job entry (insertion point: after `verify-credo` ends at line 48, before `verify-test` starts at line 50):**

```yaml
  verify-compile-no-optional:
    name: Compile without optional deps
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4

      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.17.3"
          otp-version: "27.0"

      - name: Install dependencies
        run: mix deps.get

      - name: Compile without optional deps (warnings-as-errors)
        run: mix verify.compile_no_optional
```

No Postgres `services:` block needed — this job is compile-only and never touches the DB.

---

## Shared Patterns

### Named entrypoints (mix verify.* / mix ci.*)

**Source:** OSS DNA + existing `mix.exs` `aliases/0` (lines 62-83) + every existing CI job's final `run:` step.

**Apply to:** `mix.exs` (new alias must follow the family naming) AND `.github/workflows/ci.yml` (the new job's final step calls the alias by name, not the raw `mix compile` command).

**Concrete example from existing code** — `verify-format` job step (`.github/workflows/ci.yml` line 30-31):

```yaml
      - name: Check formatting
        run: mix verify.format
```

The corresponding alias entry in `mix.exs` (line 64):

```elixir
"verify.format": ["format --check-formatted"],
```

Pattern: the CI step `run:` and the alias name are the same string. Contributors and CI cite the alias verbatim. The raw command lives only inside the alias definition.

### Stable immutable GH Actions job ids

**Source:** `.github/workflows/ci.yml` line 1-2 (top-of-file contract comment) + `CONTRIBUTING.md` lines 56-62 ("Stable job keys (do not rename)" table).

**Apply to:** `.github/workflows/ci.yml` (the new job's YAML key `verify-compile-no-optional` is immutable after merge; the `name:` field can evolve).

**Concrete example from CONTRIBUTING.md:**

```markdown
| Job key | Purpose |
| `verify-format` | `mix verify.format` |
| `verify-credo` | `mix verify.credo` |
| `verify-test` | compile `--warnings-as-errors` + `mix verify.test` (Postgres service) |
```

If the planner elects to update CONTRIBUTING.md in Phase 57 (per "Agent's discretion" in CONTEXT.md), the new row follows this shape verbatim:

```markdown
| `verify-compile-no-optional` | `mix verify.compile_no_optional` (compile without optional deps; gates against missing Phoenix/LiveView) |
```

### `@moduledoc` heredoc style for top-level Threadline modules

**Source:** `lib/threadline/telemetry.ex` (lines 1-29), `lib/threadline/health.ex` (lines 1-7), `lib/threadline/plug.ex` (lines 1-62).

**Apply to:** `lib/threadline/operator_surface.ex` (despite being inside an `if` wrapper, the inner `defmodule`'s `@moduledoc` follows the same heredoc style as every other `lib/threadline/*.ex` file — see Sentry's example, where the inner `defmodule Sentry.LiveViewHook do` body opens with `@moduledoc """..."""` exactly the way an ungated module would).

**Concrete example** — `Threadline.Telemetry`'s opening:

```elixir
defmodule Threadline.Telemetry do
  @moduledoc """
  Telemetry integration helpers for Threadline.

  Threadline emits three telemetry events:

  - `[:threadline, :transaction, :committed]` — after an `AuditTransaction` is
    committed. ...
  """
```

Conventions:
- `@moduledoc """` opens on the line immediately after `defmodule ... do` (no blank line between).
- One-sentence summary on the first content line of the heredoc.
- Markdown body with bullet lists, inline backticks for module/function names, and (where relevant) `## Section` headings.
- Closing `"""` aligned to module-body indentation.

Phase 57 deviates from existing internal Threadline modules in only one way: it adds a separate `@moduledoc since: "0.4.0"` attribute after the heredoc, mirroring Sentry's external pattern. No existing Threadline module currently uses `@moduledoc since:` — Phase 57 introduces this convention because it's the canonical ExDoc badge mechanism for "available since" semantics.

### Honest defaults — folding new gates into `ci.all`

**Source:** OSS DNA + existing `ci.all` step list (`mix.exs` lines 73-81).

**Apply to:** `mix.exs` `ci.all` extension. The new `verify.compile_no_optional` step is included in `ci.all` (per D-10) so contributors running `mix ci.all` locally catch a missing-wrapper regression before pushing — never silently excluded.

**Concrete shape** — current `ci.all` (line 73-81) shows that `ci.all` is one flat list with every check the project considers part of the green-bar contract. The new step joins that list, not a separate list.

---

## No Analog Found

| File | Role | Data Flow | Reason | Mitigation |
|------|------|-----------|--------|------------|
| `lib/threadline/operator_surface.ex` (file-scope `Code.ensure_loaded?` wrap) | namespace module, compile-time gated | compile-time guard | No internal Threadline module currently wraps `defmodule` in a file-scope `if`. The closest internal analog (`Threadline.Integrations.Sigra` line 67) uses `Code.ensure_loaded?` only as a runtime guard inside private functions. | Use `getsentry/sentry-elixir/lib/sentry/live_view_hook.ex` as the byte-verified external template (per RESEARCH.md). The planner pastes the file-scope wrap shape from there; the inner `@moduledoc` heredoc style follows internal Threadline conventions (`Threadline.Telemetry`, `Threadline.Health`). |
| `@moduledoc since: "X.Y.Z"` attribute | ExDoc since-badge | doc metadata | No existing Threadline module uses `@moduledoc since:`. | Sentry's `live_view_hook.ex` is the canonical external template. Phase 57 introduces this convention for Threadline; it composes cleanly with the existing `@moduledoc """..."""` heredoc style. |

---

## Reference Excerpts (for plan paste-readiness)

The planner can paste these byte-verified blocks directly into PLAN.md actions. All three are reproduced from RESEARCH.md Examples A / B / C / D.

### Excerpt 1 — `mix.exs` deps block (final state, after Phase 57 edits)

```elixir
defp deps do
  [
    {:ecto_sql, "~> 3.10"},
    {:postgrex, "~> 0.17"},
    {:jason, "~> 1.4"},
    {:nimble_csv, "~> 1.2"},
    {:plug, "~> 1.15"},
    {:telemetry, "~> 1.2"},
    {:phoenix, "~> 1.7", optional: true},
    {:phoenix_live_view, "~> 1.0", optional: true},
    {:phoenix_html, "~> 4.0", optional: true},
    {:phoenix_pubsub, "~> 2.1", optional: true},
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:ex_doc, "~> 0.34", only: :dev, runtime: false}
  ]
end
```

### Excerpt 2 — `mix.exs` aliases block (final state)

```elixir
defp aliases do
  [
    "verify.format": ["format --check-formatted"],
    "verify.credo": ["credo --strict"],
    "verify.test": ["test"],
    "verify.threadline": ["threadline.verify_coverage"],
    "verify.doc_contract": ["test test/threadline/readme_doc_contract_test.exs"],
    "verify.release": &verify_release/1,
    "verify.topology": ["threadline.verify_topology"],
    "verify.example": &verify_example/1,
    "verify.bench": &verify_bench/1,
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
  ]
end
```

### Excerpt 3 — `lib/threadline/operator_surface.ex` (entire file, final state)

```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface do
    @moduledoc """
    Namespace for the Threadline operator surface — the opt-in mountable
    LiveView surface that turns Threadline's investigation contracts into
    one-click answers for documented support questions.

    *Available since 0.4.0.*

    This module is gated at file scope on `Code.ensure_loaded?(Phoenix.LiveView)`
    and only compiles when `:phoenix_live_view` is present in the consumer's
    deps. Capture-only adopters who install `:threadline` without
    `:phoenix_live_view` will not have this module loaded and will not see
    it in their hexdocs build.

    Mount the surface from a host Phoenix router using the
    `Threadline.OperatorSurface.Router` macro (shipping in v0.4.0).
    """

    @moduledoc since: "0.4.0"
  end
end
```

### Excerpt 4 — `.github/workflows/ci.yml` new job (insert between `verify-credo` and `verify-test`)

```yaml
  verify-compile-no-optional:
    name: Compile without optional deps
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4

      - uses: erlef/setup-beam@v1
        with:
          elixir-version: "1.17.3"
          otp-version: "27.0"

      - name: Install dependencies
        run: mix deps.get

      - name: Compile without optional deps (warnings-as-errors)
        run: mix verify.compile_no_optional
```

### Excerpt 5 — `.github/workflows/ci.yml` top-of-file comment update

Replace lines 1-2:

```yaml
# Job id contract — stable YAML `jobs:` keys are relied on by docs and `act`:
# verify-format, verify-credo, verify-compile-no-optional, verify-test, verify-pgbouncer-topology, verify-docs, verify-hex-package, verify-release-shape
```

### Excerpt 6 — `CONTRIBUTING.md` row (planner discretion per CONTEXT.md "Agent's discretion")

If the planner elects to include in Phase 57, insert into the table at line 56-62:

```markdown
| `verify-compile-no-optional` | `mix verify.compile_no_optional` (compile without optional deps; gates against missing Phoenix/LiveView) |
```

---

## Metadata

**Analog search scope:**
- `mix.exs` (whole file, 218 lines) — read once for deps + aliases + ci.all + package + docs context.
- `.github/workflows/ci.yml` (whole file, 251 lines) — read once for job-id contract comment, twin patterns, `on:` triggers, and existing `runs-on` / setup-beam / step pinning conventions.
- `lib/threadline/integrations/sigra.ex` (lines 1-90) — confirms `Code.ensure_loaded?` precedent at line 67 (runtime guard, not file-scope wrap).
- `lib/threadline/telemetry.ex` (lines 1-50), `lib/threadline/health.ex` (lines 1-40), `lib/threadline/plug.ex` (lines 1-60) — top-level `Threadline.*` module shapes for `@moduledoc` heredoc style.
- `CONTRIBUTING.md` (lines 42-90) — verification entrypoints table format.
- File listing of `lib/threadline/*.ex` (10 files) — confirms no existing internal compile-time gated module exists; `lib/threadline/operator_surface.ex` is the first.

**External anchors (cited from RESEARCH.md, not re-fetched):**
- `getsentry/sentry-elixir/lib/sentry/live_view_hook.ex` — file-scope wrap idiom + `@moduledoc since:` placement.
- `getsentry/sentry-elixir/mix.exs` — `optional: true` declaration shape.
- `wojtekmach/req/.github/workflows/ci.yml` — `mix compile --no-optional-deps --warnings-as-errors` precedent.

**Files scanned:** 6 source files + 1 directory listing.

**Pattern extraction date:** 2026-05-06.
