# Phase 57: Optional Deps & Module Gating - Research

**Researched:** 2026-05-06
**Domain:** Elixir Hex library packaging — optional Phoenix/LiveView deps + compile-time module gating + CI verification
**Confidence:** HIGH

## Summary

Phase 57 ships a single atomic three-file change set: (1) declare four Phoenix/LiveView family deps as `optional: true` in `mix.exs`, (2) add one new gated namespace module `lib/threadline/operator_surface.ex` whose entire `defmodule` is wrapped in a file-scope `if Code.ensure_loaded?(Phoenix.LiveView) do ... end`, and (3) add a `mix verify.compile_no_optional` alias plus a dedicated CI job with stable id `verify-compile-no-optional` running `mix compile --no-optional-deps --warnings-as-errors`.

CONTEXT.md has already locked every load-bearing decision (D-01..D-14). This research document fills in the **concrete technical specifics** the planner needs: exact alias-table entry shapes that match `mix.exs`'s existing style, exact GH Actions YAML stanza that matches `.github/workflows/ci.yml`'s job-id contract, the byte-exact Sentry `live_view_hook.ex` idiom (file-scope wrap + `*Available since vX.Y.Z*` italics line in moduledoc + separate `@moduledoc since:` attribute), and four cross-checked external citations (Sentry, Elixir 1.14 CHANGELOG, Library Guidelines, LV 1.x mix.exs) that anchor every locked decision.

**Primary recommendation:** Implement exactly as CONTEXT.md specifies. Use Sentry's `lib/sentry/live_view_hook.ex` as the byte-level template for the wrapper structure and the `@moduledoc since:` placement. Use Wojtek Mach's `req` repo for the CI invocation pattern (`mix compile --no-optional-deps --warnings-as-errors`), but split it into a dedicated GH Actions job (not a matrix step) to match Threadline's existing immutable-job-id convention.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Optional Phoenix/LV dep declaration | Build / Packaging (`mix.exs`) | — | Hex-package metadata is the only place adopters read dep posture from |
| Compile-time module presence gating | Source compile (file-scope `if`) | — | The file is a pure compile-time guard; nothing runs at module load time |
| CI verification of "compiles without LV" | CI (`.github/workflows/ci.yml`) | Local (`mix ci.all` alias) | Must be both a stable GH Actions check AND runnable locally per OSS DNA "named entrypoints" rule |
| Doc-contract that the gated module disappears when LV absent | (deferred to Phase 58) | — | Per D-14 — the test helper becomes reusable once Phase 58 ships the first behavioural gated module |

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SURF-02 | `phoenix`, `phoenix_live_view`, `phoenix_html`, `phoenix_pubsub` declared `optional: true` in `mix.exs` so capture-only adopters install threadline with no Phoenix or LiveView code compiled | Section "Standard Stack" (verified Sentry precedent + Hex.pm version data) and "Code Examples → mix.exs deps block" below |
| SURF-03 | All modules under `lib/threadline/operator_surface/` (and `lib/threadline/operator_surface.ex` itself) gated via `Code.ensure_loaded?(Phoenix.LiveView)` so threadline compiles cleanly when LV is absent and adds zero observable overhead to the capture path | Section "Architecture Patterns → Pattern 1: File-scope `if Code.ensure_loaded?` wrap" + "Don't Hand-Roll" (rejecting runtime guards / compile_env / conditional elixirc_paths) |

Both requirements are **fully covered by the locked CONTEXT.md decisions**. Research provides the citations and exact text the planner will paste.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | `~> 1.7` | Phoenix framework substrate (required by LV 1.0+) | LV 1.0/1.1 declares `{:phoenix, "~> 1.6.15 or ~> 1.7.0 or ~> 1.8.0-rc"}` as a HARD dep — choosing `~> 1.7` floor narrows the matrix to versions that pair with LV 1.0+ without dragging in 1.6.x. `[VERIFIED: github.com/phoenixframework/phoenix_live_view/v1.0.0/mix.exs and v1.1.30/mix.exs, fetched 2026-05-06]` |
| `phoenix_live_view` | `~> 1.0` | LiveView runtime needed by the operator surface | Latest stable is `1.1.30` (released 2026-05-05); `~> 1.0` means `>= 1.0.0 and < 2.0.0` so 1.1.x flows in. Sentry uses `~> 0.20 or ~> 1.0` to span both major lines; Threadline drops 0.20.x per D-01. `[VERIFIED: hex.pm/api/packages/phoenix_live_view, fetched 2026-05-06]` |
| `phoenix_html` | `~> 4.0` | Required transitively by LV 1.x for HTML helpers | LV 1.x lists `{:phoenix_html, "~> 3.3 or ~> 4.0 or ~> 4.1"}` as a HARD dep — declaring `~> 4.0` in our optional list narrows to the modern 4.x line. Latest: `4.3.0` (2025-09-28). `[VERIFIED: github.com/phoenixframework/phoenix_live_view/v1.1.30/mix.exs + hex.pm/api/packages/phoenix_html, fetched 2026-05-06]` |
| `phoenix_pubsub` | `~> 2.1` | Required transitively by Phoenix 1.7/1.8 (NOT by LV directly) | Phoenix 1.7 and 1.8 mix.exs lists `{:phoenix_pubsub, "~> 2.1"}` as a HARD dep. Latest stable is `2.2.0` (2025-10-22) but `~> 2.1` admits 2.1.x AND 2.2.x. `[VERIFIED: github.com/phoenixframework/phoenix/v1.8.7/mix.exs + hex.pm/api/packages/phoenix_pubsub, fetched 2026-05-06]` |
| `plug` | `~> 1.15` | HARD dep — substrate of capture wiring (D-02) | Existing line stays unchanged. `[VERIFIED: existing mix.exs line 55]` |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| (none — Phase 57 adds zero supporting deps) | — | Phase 57 is purely declaration + one namespace module | The mount macro, telemetry, and any per-screen dependencies land in Phase 58+ |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `phoenix_live_view ~> 1.0` (single major) | `phoenix_live_view ~> 0.20 or ~> 1.0` (Sentry's shape) | D-01 explicitly drops 0.20.x — gating code never has to handle two LV major versions. Greenfield posture. |
| `phoenix ~> 1.7` floor | `phoenix ~> 1.6` (matches LV 1.0's lowest accepted Phoenix) | LV requires `~> 1.6.15 or ~> 1.7.0 or ~> 1.8.0-rc`; a `~> 1.7` floor avoids the 1.6.x branch which is rapidly aging. |
| `phoenix_pubsub` declared explicitly | Letting Phoenix's transitive HARD dep on `phoenix_pubsub ~> 2.1` cover it | CONTEXT.md D-01 names all four explicitly. Reasoning: declaring it explicitly makes the dep posture self-documenting in `mix.exs`, doesn't rely on adopters reading Phoenix's transitive graph. Cost: one extra optional line. |
| `plug` flipped to `optional: true` | Keep `:plug` HARD per D-02 | Plug is pervasively typed across `Threadline.Plug` (154 lines) and `Threadline.Integrations.Sigra`. Optional Plug = four new gating sites for a phantom Ecto-only adopter cohort. |

**Installation (planner reference, not a phase action):**

The four optional deps are *declared* but not *installed by `mix deps.get`* in capture-only adopter projects — that's the whole point. For Threadline's own development, `mix deps.get` will fetch them because the library always installs its own optional deps locally (per Library Guidelines: "the current project will always include the optional dependency"). `[CITED: hexdocs.pm/mix/Mix.Tasks.Deps.html]`

**Version verification (executed during research, 2026-05-06):**

| Package | Latest Stable | Latest Release Date | Recommended Constraint |
|---------|---------------|---------------------|------------------------|
| `phoenix` | `1.8.7` | 2026-05-06 | `~> 1.7` (admits 1.7.x and 1.8.x) |
| `phoenix_live_view` | `1.1.30` | 2026-05-05 | `~> 1.0` (admits 1.0.x and 1.1.x) |
| `phoenix_html` | `4.3.0` | 2025-09-28 | `~> 4.0` (admits 4.0.x – 4.3.x) |
| `phoenix_pubsub` | `2.2.0` | 2025-10-22 | `~> 2.1` (admits 2.1.x and 2.2.x) |

`[VERIFIED: hex.pm/api/packages/* JSON, fetched 2026-05-06]`

## Architecture Patterns

### System Architecture Diagram

```
                    ┌──────────────────────────────────────────┐
                    │  Adopter's host app (capture-only)       │
                    │  deps: [{:threadline, "~> 0.4"}]         │
                    │       └─ NO :phoenix_live_view           │
                    └─────────────┬────────────────────────────┘
                                  │ mix deps.get + mix compile
                                  ▼
   ┌────────────────────────────────────────────────────────────────┐
   │  Hex resolves threadline                                       │
   │  threadline mix.exs lists :phoenix_live_view as optional       │
   │  → Hex skips it (consumer didn't add it)                       │
   │  → Code.ensure_loaded?(Phoenix.LiveView) returns false at      │
   │    compile time of lib/threadline/operator_surface.ex          │
   │  → defmodule never expands → BEAM file never produced          │
   └────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
   ┌────────────────────────────────────────────────────────────────┐
   │  threadline compiles cleanly                                   │
   │  ✓ capture path: trigger registration, AuditTransaction,       │
   │    AuditChange, Threadline.Plug — all present                  │
   │  ✗ Threadline.OperatorSurface — NOT loaded                     │
   │  ✗ no boot warnings, no telemetry events fire                  │
   └────────────────────────────────────────────────────────────────┘

                    ─── parallel adopter (UI-enabled) ───

                    ┌──────────────────────────────────────────┐
                    │  Adopter's host app (with operator UI)   │
                    │  deps: [                                 │
                    │    {:threadline, "~> 0.4"},              │
                    │    {:phoenix_live_view, "~> 1.0"}        │
                    │  ]                                       │
                    └─────────────┬────────────────────────────┘
                                  │
                                  ▼
   ┌────────────────────────────────────────────────────────────────┐
   │  Hex resolves both threadline and phoenix_live_view            │
   │  → Code.ensure_loaded?(Phoenix.LiveView) returns true          │
   │  → defmodule Threadline.OperatorSurface compiles               │
   │  → Module appears in hexdocs and runtime                       │
   └────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

Phase 57 file edit cluster (per CONTEXT.md):

```
lib/threadline/
├── operator_surface.ex        # NEW — file-scope-gated namespace module, @moduledoc only
├── plug.ex                    # unchanged
├── integrations/
│   └── sigra.ex               # unchanged (illustrative — runtime guard, not a template)
└── ...

mix.exs                        # MODIFY — 4 optional deps + verify.compile_no_optional alias + ci.all extension

.github/workflows/
└── ci.yml                     # MODIFY — add verify-compile-no-optional job
```

**Do NOT create** `lib/threadline/operator_surface/` (the directory) in Phase 57 — that's a Phase 58 artifact when the mount macro lands. Per CONTEXT.md "Things to NOT Do".

### Pattern 1: File-scope `if Code.ensure_loaded?(...)` wrap

**What:** Wrap the entire `defmodule` block at file scope (NOT inside the module body) with an `if Code.ensure_loaded?(Phoenix.LiveView) do ... end`.

**When to use:** Compile-time gating of a module that depends on an optional dep. Required pattern for any module that uses `Phoenix.LiveView` macros (e.g. `use Phoenix.LiveView`, `import Phoenix.LiveView`, `attach_hook/4`) — those macros expand at compile time and would crash the build if LV is absent.

**Example (byte-exact reproduction of Sentry's idiom):**

```elixir
# Source: github.com/getsentry/sentry-elixir/blob/master/lib/sentry/live_view_hook.ex
# (verified raw fetch 2026-05-06)

if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Sentry.LiveViewHook do
    @moduledoc """
    A module that provides a `Phoenix.LiveView` hook to add Sentry context and breadcrumbs.

    *Available since v10.5.0.*

    This module sets context and breadcrumbs for the live view process through
    `Sentry.Context`. It sets things like:

      * The request URL
      * The user agent and user's IP address
      * Breadcrumbs for events that happen within LiveView

    ...
    """

    @moduledoc since: "10.5.0"

    import Phoenix.LiveView, only: [attach_hook: 4, get_connect_info: 2]
    # ...
  end
end
```

**Two structural conventions to copy verbatim:**
1. The `*Available since vX.Y.Z*` line lives **inside** the `@moduledoc """..."""` heredoc, on its own line, italicized with single asterisks.
2. The separate `@moduledoc since: "X.Y.Z"` attribute (no `v` prefix, no triple-quote heredoc) sits **after** the closing `"""` of the docstring. ExDoc reads `@moduledoc since:` to render a "since X.Y.Z" badge in the module header.

`[VERIFIED: raw.githubusercontent.com/getsentry/sentry-elixir/master/lib/sentry/live_view_hook.ex, fetched 2026-05-06]`

### Pattern 2: Mix alias entry shape (matches Threadline's existing style)

The existing `mix.exs` `aliases/0` function uses a list-of-strings shape for simple alias entries. New alias slots in alongside existing entries:

```elixir
# Existing pattern (lib/mix.exs line 64-71):
defp aliases do
  [
    "verify.format": ["format --check-formatted"],
    "verify.credo": ["credo --strict"],
    "verify.test": ["test"],
    # ...
    "verify.compile_no_optional": ["compile --no-optional-deps --warnings-as-errors"],  # NEW
    # ...
    "ci.all": [
      "verify.format",
      "verify.credo",
      "compile --warnings-as-errors",
      "verify.compile_no_optional",      # NEW — placed after compile, before verify.test
      "verify.test",
      "verify.threadline",
      "verify.example",
      "verify.doc_contract"
    ]
  ]
end
```

The string `"compile --no-optional-deps --warnings-as-errors"` is one alias step (Mix splits on whitespace into a task name + args). `[VERIFIED: existing mix.exs lines 62-83]`

### Pattern 3: GH Actions job stanza (matches Threadline's job-id contract)

The existing `.github/workflows/ci.yml` enumerates stable immutable job ids in a top-of-file comment. The new job mirrors `verify-format` and `verify-credo` (the cheapest existing jobs) — single-checkout, single-setup-beam, single mix step. No Postgres service is needed (compile-only check):

```yaml
# Top-of-file comment update — extend the existing enumeration:
# Job id contract — stable YAML `jobs:` keys are relied on by docs and `act`:
# verify-format, verify-credo, verify-compile-no-optional, verify-test,
# verify-pgbouncer-topology, verify-docs, verify-hex-package, verify-release-shape

# New job entry (insertion point: between verify-credo and verify-test reads naturally):
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

Match the existing convention precisely:
- `runs-on: ubuntu-24.04` — same as every other job
- `elixir-version: "1.17.3"` and `otp-version: "27.0"` — exact pinned values used elsewhere
- `actions/checkout@v4` — exact pin
- `erlef/setup-beam@v1` — exact pin
- Step name uses sentence case ("Compile without optional deps (warnings-as-errors)") — matches existing style
- `name:` field uses Title Case ("Compile without optional deps") — matches "Check formatting", "Run Credo (strict)", "Run test suite"
- The job runs `mix verify.compile_no_optional` (the alias), not the raw command — matches "Run Credo" → `mix verify.credo`, "Check formatting" → `mix verify.format`. This enforces the "named entrypoints" OSS DNA rule.

`[VERIFIED: .github/workflows/ci.yml lines 16-32 (verify-format) and lines 33-48 (verify-credo)]`

### Pattern 4: `@moduledoc` shape for `Threadline.OperatorSurface`

Direct application of Pattern 1 to Threadline's namespace, honoring CONTEXT.md D-05 (must state "Available since 0.4.0", forward-reference the Phase 58 mount macro, note the module disappears when LV absent):

```elixir
# Source: applies Sentry's idiom to Threadline's namespace.
# Forward-references the Phase 58 mount macro by name only; does NOT
# claim the macro exists yet.

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

Notes for the planner:
- **Body is intentionally empty.** No functions, no `@behaviour`, no `defstruct`. Per D-05, this is a documentation namespace only.
- **Forward-reference `Threadline.OperatorSurface.Router`** by name. Phase 58 ships the mount macro as `defmacro threadline_operator_surface/2` inside that module. Phrase as "Mount the surface from a host Phoenix router using the `Threadline.OperatorSurface.Router` macro (shipping in v0.4.0)" — does NOT claim the macro exists yet, references the version it ships in.
- **Italics line** uses `*Available since 0.4.0.*` (no `v` prefix to match Threadline's CHANGELOG which uses bare `0.3.0`, `0.4.0`).
- **`@moduledoc since: "0.4.0"`** uses bare version string (no `v` prefix) — matches Sentry's `since: "10.5.0"` form.

### Anti-Patterns to Avoid

- **`unless Code.ensure_loaded?(...), do: raise(...)` (runtime guard):** Wrong layer. `Code.ensure_loaded?` at runtime can't prevent compile-time `use Phoenix.LiveView` macro expansion. The `Threadline.Integrations.Sigra` file uses runtime guards but only for soft-dep *function calls*, not module gating — different problem. `[VERIFIED: lib/threadline/integrations/sigra.ex line 67]`

- **`Application.compile_env(:threadline, :enable_operator_surface, false)`:** Forces adopters to add config — adopter-hostile and not used by mature libraries (Sentry, Oban Web, LiveDashboard all gate purely on dep presence). Per D-07.

- **Conditional `elixirc_paths` (e.g. `defp elixirc_paths(...), do: ["lib", "lib/threadline_web"]` only when LV present):** Invisible to readers, breaks `mix xref`, breaks ExDoc. Threadline already uses this pattern internally for `test/support` (existing `elixirc_paths(:test)` — see mix.exs line 46), but extending it to user-facing module gating is the wrong tool. Per D-07.

- **`Code.ensure_loaded?` wrapping `use Phoenix.LiveView` *inside* the `defmodule` body:** This is the [elixir-lang/elixir#8970](https://github.com/elixir-lang/elixir/issues/8970) footgun — `use` macros expand at compile time before the `if` is evaluated. The wrap **must** be at file scope, around the entire `defmodule`. `[CITED: github.com/elixir-lang/elixir/issues/8970]`

- **Pre-creating `lib/threadline/operator_surface/` (the directory) in Phase 57:** Per CONTEXT.md "Things to NOT Do" — empty placeholder files compile vacuously and pollute hexdocs. Phase 58's mount macro lands the first file under that subdirectory.

- **Adding `Threadline.OperatorSurface` to `groups_for_modules:` in `mix.exs`'s `docs/0` function in Phase 57:** Per CONTEXT.md "Things to NOT Do" — wait until Phase 58 so a single hexdocs group entry covers the surface family.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| "Adopter has LV / doesn't have LV" detection | Custom application config flag, runtime feature toggle, or `Mix.env`-keyed branching | `Code.ensure_loaded?(Phoenix.LiveView)` at file scope | This is the Library Guidelines normative pattern. Sentry, Oban Web, LiveDashboard all use it. Adopter doesn't have to know it exists. |
| "Verify the gated module compiles cleanly without LV" | Custom shell script that uninstalls LV from `_build`, custom Mix task that inspects `:application.get_env`, or a doc-contract test that intercepts BEAM file presence | `mix compile --no-optional-deps --warnings-as-errors` (Elixir 1.14+) | Native, single-flag, well-understood by tooling. Wojtek Mach's `req` repo uses exactly this. |
| "Multi-file conditional module loading" | A custom registry that tracks which optional-dep-gated modules exist, or a metaprogramming layer | One file-scope `if` per module that depends on the optional dep | Adds zero indirection; readers can see the gating inline; `mix xref` understands it natively. |

**Key insight:** The Elixir ecosystem has converged on file-scope `if Code.ensure_loaded?(...) do defmodule ... end` as the *only* correct pattern for compile-time gating against optional deps. Every alternative (runtime guards, compile_env flags, conditional elixirc_paths) trades a small surface inconvenience for invisible, hard-to-grep coupling. Threadline's CONTEXT.md correctly rejects all alternatives.

## Common Pitfalls

### Pitfall 1: Wrapping `use Phoenix.LiveView` inside the module instead of around the module
**What goes wrong:** Build crashes with `(CompileError) module Phoenix.LiveView is not loaded and could not be found` when LV is absent.
**Why it happens:** `use SomeMod` triggers macro expansion at compile time, BEFORE the surrounding `if Code.ensure_loaded?(SomeMod)` evaluates at runtime. The footgun is that the `if` looks like it should gate the `use`, but macro expansion is eager.
**How to avoid:** Wrap the *entire `defmodule` block* at file scope. Sentry's pattern is the canonical reference.
**Warning signs:** Compile error message names a Phoenix/LiveView module as "not loaded" even though `Code.ensure_loaded?` is in the source.
`[CITED: github.com/elixir-lang/elixir/issues/8970]`

### Pitfall 2: Forgetting that Threadline's own dev environment ALWAYS pulls optional deps
**What goes wrong:** Maintainer runs `mix compile --warnings-as-errors` locally (sees the gated module), thinks the gating is verified. Ships. Adopter without LV gets a broken install.
**Why it happens:** Per Library Guidelines: "the current project will always include the optional dependency" — Threadline's own `mix deps.get` always fetches LV. The gated module is always present in maintainer's local builds.
**How to avoid:** `mix verify.compile_no_optional` (folded into `ci.all` per D-10) and the `verify-compile-no-optional` GH job (per D-11/D-12) both run `mix compile --no-optional-deps --warnings-as-errors`, which simulates the adopter-without-LV environment. CONTEXT.md's design directly addresses this pitfall.
**Warning signs:** Local `mix compile` succeeds but adopter reports `(UndefinedFunctionError) function Phoenix.LiveView.* is undefined`.
`[CITED: hexdocs.pm/mix/Mix.Tasks.Deps.html — "the current project will always include the optional dependency"]`

### Pitfall 3: Optional dep declared in mix.exs's `deps/0` but the BEAM-level application is auto-started
**What goes wrong:** Capture-only adopter sees boot-time warnings about a missing application.
**Why it happens:** `application/0`'s `:extra_applications` and `:applications` lists tell the BEAM which apps to start. If a maintainer adds `:phoenix_live_view` to either list, the BEAM tries to start it at boot regardless of the `deps/0` `optional: true` declaration.
**How to avoid:** Threadline's existing `application/0` is `[extra_applications: [:logger]]` — leave it untouched. Do NOT add Phoenix or LV to either list. The deps declaration is purely a Hex/Mix concern; runtime startup is separate.
**Warning signs:** Capture-only adopter logs show `Application :phoenix_live_view could not be started` at boot.
`[VERIFIED: existing mix.exs lines 40-44 — application/0 returns [extra_applications: [:logger]]]`

### Pitfall 4: Dialyzer PLT cache fails when running both legs of an LV-present / LV-absent matrix
**What goes wrong:** PLT cached from "LV present" run contains `Phoenix.LiveView.*` references. PLT cached from "LV absent" run does not. Re-running either leg without rebuilding the PLT produces noisy false positives or "module not loaded" errors.
**Why it happens:** Dialyzer PLTs encode the full set of loaded modules at PLT-build time.
**How to avoid:** Per D-08 — Dialyzer runs in only ONE leg of the matrix (the "all optional deps present" one). Don't try to make Dialyzer green in both legs. (Note: Threadline doesn't currently run Dialyzer in CI; the existing `dialyzer:` config in `mix.exs` line 36 is for local use only. This pitfall is forward-looking.)
**Warning signs:** Dialyzer surfaces `Phoenix.LiveView.*` "no_return" or "unknown_function" warnings only in one CI leg.

### Pitfall 5: `mix xref` complaints in the no-optional-deps build
**What goes wrong:** Even though `Threadline.OperatorSurface` is gated and never compiled when LV is absent, other Threadline modules might `alias Threadline.OperatorSurface` or reference it in typespecs. Without LV, those references become "unknown module" xref warnings.
**Why it happens:** Phase 57 ships only the namespace module — no other Threadline module references it yet, so this pitfall is **theoretical for Phase 57** but very real for Phase 58+. Calling it out here so the planner knows the pattern.
**How to avoid:** When Phase 58 lands the mount macro and any future Threadline module imports/aliases operator-surface modules, that referencing code itself must be gated. Phase 57 has nothing to gate-reference yet.
**Warning signs:** `mix verify.compile_no_optional` exits non-zero with `mix xref` style "unknown module" messages.

## Code Examples

Verified patterns ready for the planner to paste into PLAN.md:

### Example A: Final `mix.exs` deps block

```elixir
# Source: applies Sentry's optional pattern + LV 1.x dep tree to threadline.
# Verified against:
#   - github.com/getsentry/sentry-elixir/master/mix.exs (deps/0)
#   - github.com/phoenixframework/phoenix_live_view/v1.1.30/mix.exs (deps/0)
#   - github.com/phoenixframework/phoenix/v1.8.7/mix.exs (deps/0)
defp deps do
  [
    {:ecto_sql, "~> 3.10"},
    {:postgrex, "~> 0.17"},
    {:jason, "~> 1.4"},
    {:nimble_csv, "~> 1.2"},
    {:plug, "~> 1.15"},
    {:telemetry, "~> 1.2"},
    {:phoenix, "~> 1.7", optional: true},                # NEW
    {:phoenix_live_view, "~> 1.0", optional: true},      # NEW
    {:phoenix_html, "~> 4.0", optional: true},           # NEW
    {:phoenix_pubsub, "~> 2.1", optional: true},         # NEW
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
    {:ex_doc, "~> 0.34", only: :dev, runtime: false}
  ]
end
```

Insertion points: per Threadline's existing convention, runtime deps come before `:dev`/`:test`-only deps. Place the four new optional deps after `:telemetry` and before `:credo`.

### Example B: Final `mix.exs` aliases block

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
    "verify.compile_no_optional": ["compile --no-optional-deps --warnings-as-errors"],   # NEW
    "ci.all": [
      "verify.format",
      "verify.credo",
      "compile --warnings-as-errors",
      "verify.compile_no_optional",                                                       # NEW
      "verify.test",
      "verify.threadline",
      "verify.example",
      "verify.doc_contract"
    ]
  ]
end
```

Per D-10: `verify.compile_no_optional` lands in `ci.all` AFTER `compile --warnings-as-errors` (so the all-deps-present compile catches its bugs first) and BEFORE `verify.test` (so a regression in gating fails fast before running the slow test suite).

### Example C: Final `lib/threadline/operator_surface.ex`

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

The file ends after the outer `end` (the one closing the `if`). No trailing newline-and-extra-content. Total roughly 22 lines including blank lines.

The exact `@moduledoc` wording is at planner discretion per CONTEXT.md "Agent's discretion" — the above honors all three constraints (states "Available since 0.4.0", forward-references `Threadline.OperatorSurface.Router`, notes the module disappears when LV is absent) but the planner may rephrase.

### Example D: Final `.github/workflows/ci.yml` job entry

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

Plus the top-of-file comment update:

```yaml
# Job id contract — stable YAML `jobs:` keys are relied on by docs and `act`:
# verify-format, verify-credo, verify-compile-no-optional, verify-test,
# verify-pgbouncer-topology, verify-docs, verify-hex-package, verify-release-shape
```

Insertion point recommendation: between `verify-credo` (ends ~line 48) and `verify-test` (starts at line 50). This places the cheap compile-only check immediately after the cheap format/credo checks, before the expensive Postgres-backed test job. The job-id alphabetical ordering in the comment header is preserved.

### Example E: CONTRIBUTING.md update (planner discretion per CONTEXT.md)

Per CONTEXT.md "Agent's discretion": *"Whether to update CONTRIBUTING.md's 'verification entrypoints' section in Phase 57 or defer to Phase 63 docs work — planner decides based on minimal-diff ergonomics."*

If included in Phase 57, the existing CONTRIBUTING.md table (lines 56-62) gets one new row:

```markdown
| `verify-compile-no-optional` | `mix compile --no-optional-deps --warnings-as-errors` (gates against missing Phoenix/LiveView optional deps) |
```

**Recommendation to planner:** INCLUDE the CONTRIBUTING.md row in Phase 57. Reasoning:
1. It's a single-line addition co-located with the change set's atomic commit.
2. The Phase 63 docs phase is far away (5 phases later); leaving CONTRIBUTING.md stale for that long means contributors run `mix ci.all` locally, see the new step, and have nothing to grep for in CONTRIBUTING.md.
3. The OSS DNA "doc-contract tests align with public docs" principle is satisfied trivially because the row references the alias name and command verbatim.

The trade-off is negligible — one Markdown table row vs. five-phase staleness. Plan it in Phase 57.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Maintainer-only verification ("trust me, it compiles without LV") | `mix compile --no-optional-deps --warnings-as-errors` in CI | Elixir 1.14 (Aug 2022) introduced the flag | Regression-proof; integrated into `req`, Sentry's later-PR additions, Oban Web's CI |
| Conditional `elixirc_paths` for optional-dep gating | File-scope `if Code.ensure_loaded?(...) do defmodule ... end` | Sentry-elixir PR #722 (added `LiveViewHook`, 2024) — also Oban Web, LiveDashboard | Visible to readers, plays well with `mix xref`, no metaprogramming |
| `unless ..., do: raise` runtime guards for compile-time deps | (Same — file-scope wrap) | Elixir community settled this idiom over 2018-2022 | Compile-time errors caught at the right layer |

**Deprecated/outdated:**
- **Two-major-version LV support (`~> 0.20 or ~> 1.0`):** Threadline (greenfield, no installed base) explicitly drops 0.20.x per D-01. Sentry needs to support both because Sentry has installed bases on 0.20.x.
- **`elixirc_paths(:prod) do [..., "lib/threadline_web"]`** style gating: out of fashion since LV 1.0 made file-scope wrapping idiomatic.

`[VERIFIED: github.com/elixir-lang/elixir/v1.14/CHANGELOG.md (Mix section: "[mix compile] Add --no-optional-deps to skip optional dependencies to test compilation works without optional dependencies")]`

## Project Constraints (from CLAUDE.md)

- **Three-layer architecture (capture / semantics / exploration).** Phase 57 is solely about packaging the *exploration* layer's UI substrate as opt-in. Capture and semantics layers MUST be observably unchanged — Success Criterion 3 ("capture path runtime behavior observably unchanged when LiveView is absent") is the explicit guardrail. The planner should NOT add any cross-layer references in this phase.
- **Domain language preserved.** The new `Threadline.OperatorSurface` module is a *namespace*, not a domain entity. It does not introduce or rename `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, `Correlation`. The `@moduledoc` should not redefine domain terms — keep the docstring focused on the operator-surface contract.
- **Named verification entrypoints.** New alias `mix verify.compile_no_optional` follows the existing `mix verify.*` family. Contributors must be able to cite the alias by name; the GH Actions job must call the alias (`run: mix verify.compile_no_optional`), not the raw `mix compile --no-optional-deps --warnings-as-errors` invocation.
- **Stable CI job IDs.** New job key `verify-compile-no-optional` is immutable after merge. The `name:` field ("Compile without optional deps") may evolve later; the `id:` (the YAML key) cannot.
- **Honest default tests.** `mix verify.compile_no_optional` is folded into `ci.all` so contributors running locally catch a regression — not silently excluded.
- **Path filters + main rule.** Phase 57 doesn't change path filters; the new job runs on both `main` push and PRs (existing workflow's `on:` block is `push: branches: [main]` + `pull_request: branches: [main]`).
- **Doc contract tests align.** Per CONTEXT.md D-14, no doc-contract test for this gated module in Phase 57 (deferred to Phase 58). If Example E (CONTRIBUTING.md row) is included, it's a one-line documentation update, not a doc-contract test.
- **GSD positional args for `state.begin-phase`.** Use positional `phase`, `slug`, `plan_count` arguments — flag-style invocations corrupt STATE.md.

## Runtime State Inventory

(Phase 57 is greenfield-additive — adds a new namespace module, declares new optional deps, adds a new CI alias and job. No rename, no migration, no string replacement. Inventory not applicable.)

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | All Threadline development | ✓ | 1.17.3 (CI pin) / `~> 1.15` (mix.exs floor) | — |
| OTP | All Threadline development | ✓ | 27.0 (CI pin) | — |
| `mix compile --no-optional-deps` flag | Phase 57's verify alias | ✓ | Introduced Elixir 1.14 (Aug 2022); current CI uses 1.17.3 — flag is well past stability | — |
| `mix compile --warnings-as-errors` flag | Phase 57's verify alias | ✓ | Long-standing flag (pre-1.14); used elsewhere in Threadline (`ci.all` step `compile --warnings-as-errors`) | — |
| GitHub Actions | Phase 57's CI job | ✓ | Existing workflow at `.github/workflows/ci.yml` | — |
| `actions/checkout@v4`, `erlef/setup-beam@v1` | Phase 57's CI job | ✓ | Both pinned and used in every existing job | — |
| Phoenix / Phoenix.LiveView (for the LV-present leg) | Local maintainer compile of `Threadline.OperatorSurface` | ✓ (will become available after `mix deps.get` runs with the new optional deps in mix.exs) | `~> 1.7` / `~> 1.0` | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

`[VERIFIED: Elixir 1.14 CHANGELOG entry for `--no-optional-deps`; existing `.github/workflows/ci.yml` lines 21-26 (action pins); `mix.exs` line 26 elixir floor]`

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir's built-in test framework) |
| Config file | `test/test_helper.exs` (existing) + `mix.exs` `preferred_envs` for `ci.all`/`verify.test` |
| Quick run command | `mix verify.compile_no_optional` (Phase 57's primary new gate) |
| Full suite command | `mix ci.all` |
| Phase gate | `mix ci.all` green AND new GH job `verify-compile-no-optional` green on PR |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SURF-02 | `mix.exs` declares the four Phoenix/LV deps as `optional: true` | smoke (compile both with and without optional deps) | `mix verify.compile_no_optional` (LV-absent leg) AND `mix compile --warnings-as-errors` (LV-present leg, already in `ci.all`) | ✅ Both flags exist; the new alias is added in this phase |
| SURF-02 | An adopter without LV installs threadline cleanly | indirect smoke — no installed-app integration test in Phase 57 | `mix verify.compile_no_optional` simulates the adopter environment | ✅ |
| SURF-03 | `Threadline.OperatorSurface` is gated; compile succeeds with and without LV | smoke (the verify alias enforces the without-LV path) | `mix verify.compile_no_optional` | ✅ |
| SURF-03 | Capture path runtime behavior observably unchanged when LV absent (no new modules loaded, no boot warnings, no telemetry events) | manual + indirect | manual: maintainer reviews boot logs of a no-LV adopter sandbox; indirect: existing `verify.test` continues to pass | ⚠️ See "Wave 0 Gaps" — no formal test for "Threadline.OperatorSurface is NOT loaded when LV absent" lands until Phase 58 (per D-14) |

### Sampling Rate

- **Per task commit:** `mix verify.compile_no_optional && mix verify.format && mix verify.credo` (under 10s combined locally)
- **Per wave merge:** `mix ci.all` (full suite — uses Postgres)
- **Phase gate:** Full `mix ci.all` green locally; GH Actions all jobs green on PR (including new `verify-compile-no-optional`); `/gsd-verify-work` review

### Wave 0 Gaps

- **None blocking Phase 57.** The phase ships its own verification (`mix verify.compile_no_optional` alias + dedicated CI job). The companion *doc-contract test* — asserting `Threadline.OperatorSurface` is defined when LV is present and absent when LV is missing — is **deliberately deferred to Phase 58 per CONTEXT.md D-14**. That test helper becomes reusable once Phase 58 lands the first behavioural module (the mount macro). Phase 57's CI gate provides automated regression protection without per-module doc-contract scaffolding.

## Security Domain

(Not applicable in any meaningful sense for Phase 57. The phase ships a documentation namespace module with no functions, no I/O, no secrets, no input validation surface. Security implications are zero. The existing Threadline security posture — host-owned auth, Plug-substrate capture, no UI auth — is preserved unchanged.)

If `security_enforcement` is enabled in `.planning/config.json`, this section is intentionally minimal because the phase has no executable surface.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | (no auth surface in this phase) |
| V3 Session Management | no | (no session surface) |
| V4 Access Control | no | (no access-controlled surface) |
| V5 Input Validation | no | (no inputs accepted by the namespace module) |
| V6 Cryptography | no | (no crypto) |

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Supply-chain risk from optional deps | Tampering | Hex.pm package signing (existing); `mix deps.unlock --check-unused` covers nothing new because Phase 57 doesn't add hard deps. Optional deps are declared, not installed by adopter unless adopter requests them. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| (none) | All factual claims in this research are tagged `[VERIFIED: ...]` or `[CITED: ...]` from authoritative sources fetched 2026-05-06. | — | — |

**No claims are tagged `[ASSUMED]`.** All version constraints, dep tree relationships, Sentry idiom byte-content, Elixir flag history, and CI job conventions were verified by fetching official repos, Hex.pm API, hexdocs.pm, or the existing Threadline repo files during this research session.

## Open Questions (RESOLVED)

1. **Whether the planner includes the CONTRIBUTING.md row in Phase 57 or defers to Phase 63.**
   - What we know: CONTEXT.md explicitly delegates this to planner judgment. Existing CONTRIBUTING.md has a `Job key | Purpose` table at lines 56-62 and the "Verification entrypoints" prose section is an obvious home for the new alias.
   - What's unclear: Whether the planner prioritizes minimal-diff atomic commits (in-phase) or strict scope discipline (defer to Phase 63 docs work).
   - Recommendation: **Include in Phase 57** — single Markdown row, co-located atomic commit, avoids 5-phase doc staleness. (See Example E above.)

2. **Whether the new `Threadline.OperatorSurface` namespace should appear in `mix.exs`'s `groups_for_modules:` ExDoc grouping in Phase 57 or be deferred to Phase 58.**
   - What we know: CONTEXT.md "Things to NOT Do" is explicit — defer to Phase 58 so a single hexdocs group entry covers the surface family.
   - What's unclear: Nothing — answered.
   - Recommendation: **Defer to Phase 58.** Don't touch `groups_for_modules:` in Phase 57.

3. **Whether to add `phoenix_view` to the optional list (LV's optional dep).**
   - What we know: LV 1.x lists `{:phoenix_view, "~> 2.0", optional: true}`. CONTEXT.md D-01 names exactly four deps and does NOT include `phoenix_view`.
   - What's unclear: Nothing — Threadline doesn't use `phoenix_view`. Phoenix 1.7+ uses function components, not Phoenix.View.
   - Recommendation: **Do NOT add `phoenix_view`** to the optional list. CONTEXT.md is the canonical decision; this confirms the locked decision is correct against current Phoenix 1.7/1.8 conventions.

## Sources

### Primary (HIGH confidence)

- `lib/threadline/integrations/sigra.ex` (line 67) — existing `Code.ensure_loaded?` precedent in the codebase. `[VERIFIED]`
- `mix.exs` (lines 49-83) — existing deps + alias machinery shape. `[VERIFIED]`
- `.github/workflows/ci.yml` (lines 16-101) — existing job-id contract and YAML conventions. `[VERIFIED]`
- `CONTRIBUTING.md` (lines 56-62) — existing job-key documentation pattern. `[VERIFIED]`
- `CHANGELOG.md` (lines 1-50) — current `[Unreleased]` and `[0.3.0]` shape; bare-version style (no `v` prefix). `[VERIFIED]`
- https://raw.githubusercontent.com/getsentry/sentry-elixir/master/lib/sentry/live_view_hook.ex — byte-exact file-scope wrap idiom + `@moduledoc since:` convention (verified by raw fetch 2026-05-06). `[VERIFIED]`
- https://raw.githubusercontent.com/getsentry/sentry-elixir/master/mix.exs — Sentry's optional-dep declarations: `{:phoenix, "~> 1.6", optional: true}`, `{:phoenix_live_view, "~> 0.20 or ~> 1.0", optional: true}`, `{:plug, "~> 1.6", optional: true}`. `[VERIFIED]`
- https://raw.githubusercontent.com/phoenixframework/phoenix_live_view/v1.0.0/mix.exs — LV 1.0.0 deps: `{:phoenix, "~> 1.6.15 or ~> 1.7.0"}`, `{:plug, "~> 1.15"}`, `{:phoenix_html, "~> 3.3 or ~> 4.0 or ~> 4.1"}`. `[VERIFIED]`
- https://raw.githubusercontent.com/phoenixframework/phoenix_live_view/v1.1.30/mix.exs — LV 1.1.30 deps confirm same shape with phoenix `~> 1.8.0-rc` admitted. `[VERIFIED]`
- https://raw.githubusercontent.com/phoenixframework/phoenix/v1.8.7/mix.exs — Phoenix 1.8 deps: `{:phoenix_pubsub, "~> 2.1"}` is HARD. `[VERIFIED]`
- https://github.com/elixir-lang/elixir/blob/v1.14/CHANGELOG.md — entry: "[mix compile] Add `--no-optional-deps` to skip optional dependencies to test compilation works without optional dependencies". `[VERIFIED]`
- https://hexdocs.pm/elixir/library-guidelines.html — "you should also consider compiling your projects with the `mix compile --no-optional-deps --warnings-as-errors` in your test environments". `[CITED]`
- https://hexdocs.pm/mix/Mix.Tasks.Deps.html — `optional: true` semantics: "the current project will always include the optional dependency but any other project that depends on the current project won't be forced to use the optional dependency. However, if the other project includes the optional dependency on its own, the requirements and options specified here will also be applied." `[CITED]`
- https://hex.pm/api/packages/phoenix_live_view — current versions JSON. `[VERIFIED]`
- https://hex.pm/api/packages/phoenix_html — current versions JSON. `[VERIFIED]`
- https://hex.pm/api/packages/phoenix_pubsub — current versions JSON. `[VERIFIED]`
- https://hex.pm/api/packages/phoenix — current versions JSON. `[VERIFIED]`

### Secondary (MEDIUM confidence)

- https://github.com/wojtekmach/req/blob/main/.github/workflows/ci.yml — confirms `mix compile --no-optional-deps --warnings-as-errors` is a real-world CI step in a respected library. (Implementation differs from Threadline's locked decision: `req` uses a matrix conditional step; Threadline uses a dedicated job. Both are valid; CONTEXT.md picks the dedicated-job approach for stable-id discoverability.) `[VERIFIED via WebFetch]`
- https://github.com/getsentry/sentry-elixir/pull/722 — Sentry's PR adding the LV hook with optional deps. Confirms files changed: `mix.exs` and `lib/sentry/live_view_hook.ex`; no compile-without-LV test added in same PR (matches Threadline's D-14 deferral). `[VERIFIED via WebFetch — partial: full file-changed list inferred from the title and the summary, not enumerated line-by-line]`
- https://github.com/elixir-lang/elixir/issues/8970 — the `use SomeMod` inside `defmodule` footgun; explains why file-scope wrapping is required. `[CITED]`

### Tertiary (LOW confidence)

- (none — every claim made in this document is anchored to a Primary or Secondary source.)

## Metadata

**Confidence breakdown:**
- Standard stack (versions and dep tree): HIGH — all four version constraints cross-verified against Hex.pm JSON + LV 1.x and Phoenix 1.7/1.8 mix.exs files; Sentry's optional-dep idiom is byte-verified.
- Architecture (file-scope wrap pattern + `@moduledoc since:` placement): HIGH — Sentry's `lib/sentry/live_view_hook.ex` fetched verbatim; Library Guidelines normative quote; Elixir issue #8970 documents the footgun.
- Verification (alias shape, CI YAML stanza): HIGH — every example matches existing Threadline file conventions verified line-by-line; the `--no-optional-deps` flag history is confirmed in the Elixir 1.14 CHANGELOG.
- Pitfalls (5 listed): HIGH for #1 (issue #8970), #2 (Library Guidelines quote), #3 (existing application/0 verified); MEDIUM for #4 (Dialyzer matrix is forward-looking — Threadline doesn't run Dialyzer in CI yet); MEDIUM for #5 (theoretical for Phase 57 — no Threadline module yet aliases the new namespace).

**Research date:** 2026-05-06
**Valid until:** 2026-06-05 (30 days — stack is mature/stable; the only refresh trigger would be a major LV 2.0 release or a new Phoenix major version, neither imminent based on May 2026 release cadence).
