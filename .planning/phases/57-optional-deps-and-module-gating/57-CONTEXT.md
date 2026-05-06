# Phase 57: optional-deps-and-module-gating - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 57 ships only the **dependency posture** and **module-gating mechanism**
for the v1.17 operator surface. It declares the Phoenix/LiveView family of deps
as `optional: true`, ships exactly one gated namespace module
(`Threadline.OperatorSurface`) that proves the file-scope
`if Code.ensure_loaded?(Phoenix.LiveView) do defmodule ... end` wrapper pattern
in production conditions, and adds a `mix verify.compile_no_optional` alias
plus a dedicated GitHub Actions job so the "capture path observably unchanged
when LiveView is absent" success criterion is enforced from day one.

It is **not** the phase for the mount macro (Phase 58), the screens
(59-61), the `mix threadline.incident` Mix task (Phase 62), `guides/operator-surface.md`
or CHANGELOG entries for `0.4.0` (Phase 63), or any auth/telemetry surface
(Phase 58). It is also **not** the phase to revisit `:plug`'s posture — Plug
remains a hard dep.

</domain>

<decisions>
## Implementation Decisions

### Optional dep posture
- **D-01:** `mix.exs` declares the four operator-surface deps as
  `optional: true`:
  - `{:phoenix, "~> 1.7", optional: true}`
  - `{:phoenix_live_view, "~> 1.0", optional: true}`
  - `{:phoenix_html, "~> 4.0", optional: true}`
  - `{:phoenix_pubsub, "~> 2.1", optional: true}`
  Greenfield posture — the `~> 0.20` LV branch is dropped intentionally so the
  gating code never has to handle two LV major versions. Phoenix floor is
  `~> 1.7` because LV `~> 1.0` requires it.
- **D-02:** `:plug` stays a HARD dep (`{:plug, "~> 1.15"}` unchanged). Plug is
  the substrate of capture wiring (`Threadline.Plug` is 154 lines and
  pervasively typed on `Plug.Conn`; `Threadline.Integrations.Sigra` carries
  `Plug.Conn.t()` typespecs and runtime calls). Flipping it optional would tax
  four gating sites for a phantom Ecto-only adopter cohort that does not exist
  in Threadline's stated target audience. Phase 57's roadmap line scopes
  optionality to Phoenix/LiveView only — touching Plug here is scope creep.
- **D-03:** `package: [files: ...]` in `mix.exs` is unchanged. The existing
  `"lib"` directory entry auto-includes the new
  `lib/threadline/operator_surface.ex` and any future operator-surface modules,
  so no enumeration change is needed.

### Module gating mechanism
- **D-04:** Use **top-of-file** `if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface do ... end end`. Modeled verbatim on
  `getsentry/sentry-elixir`'s `lib/sentry/live_view_hook.ex` — the explicit
  idiomatic anchor recorded in `.planning/PROJECT.md`'s key-decisions row. The
  `if` wraps the whole `defmodule` at file scope; it does NOT live inside the
  module body around a `use Phoenix.LiveView` block (that path is
  [elixir-lang/elixir#8970](https://github.com/elixir-lang/elixir/issues/8970)).
- **D-05:** Phase 57 ships exactly **one gated module** —
  `lib/threadline/operator_surface.ex` defining
  `Threadline.OperatorSurface` as a documentation namespace with `@moduledoc`
  only. No functions, no behaviour, no telemetry. The `@moduledoc` explicitly
  states "Available since 0.4.0" and forward-references the upcoming
  `Threadline.OperatorSurface.Router` mount macro that lands in Phase 58.
  Mirrors `Sentry.LiveViewHook`'s `*Available since v10.5.0.*` convention.
- **D-06:** No empty placeholder `.ex` files anywhere under `lib/threadline/`.
  An unused stub would compile vacuously and pollute hexdocs. Phase 58 lands
  the first behavioural module under `lib/threadline/operator_surface/` (the
  subdirectory) when the mount macro arrives.
- **D-07:** Reject these alternative gating idioms:
  - `unless Code.ensure_loaded?(...), do: raise(...)` — runtime guard, wrong
    pattern for compile-time gating.
  - `Application.compile_env` flag — adopter-hostile (forces config) and not
    used by the surveyed mature libraries.
  - Conditional `elixirc_paths` for gating user-facing modules — invisible to
    readers, breaks `mix xref`, used internally only for `test/support`.
- **D-08:** Dialyzer runs only in the "all optional deps present" CI cell.
  PLTs legitimately differ when gated modules vanish; do not try to make
  dialyzer green in both legs of the matrix.

### Verification posture
- **D-09:** Add `mix verify.compile_no_optional` alias =
  `mix compile --no-optional-deps --warnings-as-errors`. This is the official
  Elixir Library Guidelines path
  (https://hexdocs.pm/elixir/library-guidelines.html) and the lowest-cost,
  strongest-signal mechanism. The flag has been stable since Elixir 1.14.
- **D-10:** Fold `verify.compile_no_optional` into `mix ci.all` so contributors
  running ci.all locally catch a missing-wrapper regression before pushing.
  Place it after `compile --warnings-as-errors` and before `verify.test`.
- **D-11:** Add a dedicated GitHub Actions job in `.github/workflows/ci.yml`
  with the stable immutable id `verify-compile-no-optional`. Naming it
  separately matches Threadline's existing `verify.*` job-id contract (the
  ci.yml header already enumerates stable ids as a contract). Cost is one YAML
  stanza + roughly 45s/push. Sentry's CI gap (no equivalent job) is an
  acknowledged omission, not a deliberate engineering choice — replicating it
  would invert Threadline's capture-only-first value proposition (their
  adopters all have Phoenix; ours specifically may not).
- **D-12:** The dedicated job runs on both `main` and PRs (the OSS DNA
  "expensive jobs on main even when PRs are path-filtered" rule is satisfied
  trivially because this job is cheap).

### Phase boundary discipline
- **D-13:** Phase 57 explicitly does NOT introduce: the mount macro
  `Threadline.OperatorSurface.Router` (Phase 58), the `:authorize_fn` contract
  or compile-time fail-closed check (Phase 58), the
  `[:threadline, :operator_surface, :authorize]` telemetry event (Phase 58),
  any LiveView screen (59-61), the `mix threadline.incident` Mix task (62),
  `guides/operator-surface.md`, README operator-surface section, or any
  CHANGELOG entry for `0.4.0` (Phase 63).
- **D-14:** Phase 57 does NOT add a doc-contract test that asserts
  `Threadline.OperatorSurface` is defined when LV is present and absent when
  LV is missing. That belongs in Phase 58 alongside the first behavioural
  gated module (the mount macro), where the test helper for "compile without
  LV present" assertions becomes reusable. The Phase 57
  `verify.compile_no_optional` job already provides automated regression
  protection without per-module doc-contract scaffolding.

### Agent's discretion
- Exact `@moduledoc` wording on `Threadline.OperatorSurface`, provided it
  states "since 0.4.0" and forward-references the Phase 58 mount macro.
- Whether the new GH Actions job lives inside the existing
  `.github/workflows/ci.yml` as an additional job entry or is split into a
  separate workflow file (planner judgment based on existing workflow shape).
- Exact placement of `verify.compile_no_optional` within the `ci.all` step
  list, provided it lands after `compile --warnings-as-errors` and before
  `verify.test`.
- Whether to update `CONTRIBUTING.md`'s "verification entrypoints" section in
  Phase 57 or defer to Phase 63 docs work — planner decides based on minimal-
  diff ergonomics.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase framing and active milestone context
- `.planning/ROADMAP.md` — Phase 57 goal, dependency, requirements
  (SURF-02, SURF-03), and three success criteria (`mix.exs optional`,
  module gating, capture-path runtime unchanged).
- `.planning/REQUIREMENTS.md` — SURF-02 and SURF-03 requirement text;
  also DOC-04 for the eventual CHANGELOG note that lands in Phase 63.
- `.planning/PROJECT.md` — v1.17 framing, the
  `v1.17 operator surface ships in-tree with optional Phoenix/LiveView deps`
  key-decisions row, and the "Hard LiveView/Phoenix dependency in
  `threadline` core" out-of-scope row.
- `.planning/STATE.md` — current sequencing; v1.17 active, Phase 57 is the
  first execution target.
- `.planning/MILESTONE-ARC.md` — canonical forward milestone strategy
  (referenced for context, not directly modified by Phase 57).

### Repo files the planner must read before writing the plan
- `mix.exs` — current deps list, alias machinery (`verify.*` /
  `ci.all`), `package: [files: ...]`, and `docs:` config. Phase 57 only
  edits the deps list and aliases; do not touch `package`, `docs`, or
  module groups for modules that have not landed yet.
- `.github/workflows/ci.yml` — existing immutable job-id contract; the new
  `verify-compile-no-optional` job mirrors that convention.
- `lib/threadline/integrations/sigra.ex` — existing `Code.ensure_loaded?`
  precedent. Note: that file uses the function as a **runtime** soft-dep
  guard (`defp sigra_available?, do: Code.ensure_loaded?(Sigra.Session)`).
  Phase 57 uses the same function but at **file scope** for **compile-time**
  gating — a different idiom even though the function call looks similar.
- `prompts/threadline-elixir-oss-dna.md` — OSS quality-bar conventions:
  named `mix verify.*` / `mix ci.*` entrypoints, stable immutable GH
  Actions job ids, expensive jobs run on `main` even when PRs are
  path-filtered, doc-contract tests align with public docs.
- `CONTRIBUTING.md` — current contributor verification surface; planner
  decides whether to add `mix verify.compile_no_optional` here in Phase 57
  or defer to Phase 63.
- `CHANGELOG.md` — current shape; Phase 57 does NOT write a CHANGELOG
  entry (Phase 63 does), but the planner should know the `Unreleased`
  section's current state.

### External anchors (research-cited; downstream agents should be
familiar with these but do not need to read them in full)
- https://github.com/getsentry/sentry-elixir/blob/master/lib/sentry/live_view_hook.ex
  — verbatim file-scope `if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule ... end` shape that the new `Threadline.OperatorSurface`
  module should mirror.
- https://github.com/getsentry/sentry-elixir/pull/722 — Sentry's
  atomic-shipped optional deps + gated module + companion test pattern.
  Threadline diverges by NOT shipping the companion test in Phase 57
  (deferred to Phase 58 per D-14).
- https://github.com/getsentry/sentry-elixir/blob/master/mix.exs — full
  optional Phoenix/LV/Plug declaration line.
- https://github.com/wojtekmach/req/blob/main/.github/workflows/ci.yml —
  minimum-credible `mix compile --no-optional-deps --warnings-as-errors`
  CI precedent (Wojtek Mach / Elixir core team).
- https://hexdocs.pm/elixir/library-guidelines.html — normative
  `--no-optional-deps` guidance.
- https://github.com/elixir-lang/elixir/issues/8970 — the
  `Code.ensure_loaded?/1` wrapping `use` *inside* `defmodule` footgun;
  D-04 wraps at file scope to avoid it.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The `verify.*` alias machinery in `mix.exs` already standardizes named
  entrypoints (`verify.format`, `verify.credo`, `verify.test`,
  `verify.threadline`, `verify.doc_contract`, `verify.release`,
  `verify.topology`, `verify.example`, `verify.bench`, `ci.all`). Adding
  `verify.compile_no_optional` is one new alias entry plus one entry in the
  `ci.all` step list — same shape as every existing alias.
- `lib/threadline/integrations/sigra.ex:67` already imports the
  `Code.ensure_loaded?` mental model into the codebase (runtime soft-dep
  pattern). The new file-scope compile-time pattern is adjacent but distinct;
  documenting the difference in the new module's `@moduledoc` helps future
  contributors understand why the call site looks different.
- `.github/workflows/ci.yml` already enforces the stable immutable job-id
  contract that the new `verify-compile-no-optional` job extends.

### Established Patterns
- This repo prefers **named entrypoints** that contributors and CI cite
  verbatim. The new `mix verify.compile_no_optional` alias must be cite-able
  and self-explanatory.
- This repo prefers **stable job IDs** in GitHub Actions; `id:` fields are
  immutable, `name:` evolves freely. The new job follows that rule.
- This repo prefers **honest defaults** — heavy suites are not silently
  excluded. The new alias is folded into `ci.all` so it runs by default.

### Integration Points
- The single edit cluster for Phase 57:
  1. `mix.exs` — add four optional deps; add `verify.compile_no_optional`
     alias; extend `ci.all` step list.
  2. `lib/threadline/operator_surface.ex` (new file) — the gated namespace
     module with `@moduledoc` only.
  3. `.github/workflows/ci.yml` — add the new job entry with stable id
     `verify-compile-no-optional`.
- Out of edit cluster for Phase 57: `package` files list, `docs` module
  groups, `CHANGELOG.md`, `CONTRIBUTING.md` (planner discretion), README,
  any guide.

### Things to NOT Do
- Do not add `Threadline.OperatorSurface` to `mix.exs`'s
  `groups_for_modules:` ExDoc grouping yet — wait until the mount macro
  lands in Phase 58 so a single hexdocs group entry covers the surface
  family.
- Do not pre-create `lib/threadline/operator_surface/` as a directory in
  Phase 57. The first file under that subdirectory is the mount macro in
  Phase 58. Phase 57 only creates `lib/threadline/operator_surface.ex`
  (a file at the same level as `lib/threadline/plug.ex`).

</code_context>

<specifics>
## Specific Ideas

- The execution shape is one cohesive plan with three file edits in a single
  atomic commit:
  1. `mix.exs` (deps + alias + ci.all)
  2. `lib/threadline/operator_surface.ex` (new gated namespace)
  3. `.github/workflows/ci.yml` (new job)
- The `@moduledoc` on `Threadline.OperatorSurface` should:
  - Open with one sentence on what the surface is and that it is opt-in.
  - State "Available since 0.4.0" explicitly (mirrors
    `Sentry.LiveViewHook`'s versioning convention).
  - Forward-reference `Threadline.OperatorSurface.Router` as the upcoming
    mount macro without claiming it exists yet (Phase 58 ships it).
  - Note that the module exists only when `phoenix_live_view` is available
    in the consumer's deps so hexdocs readers understand why it disappears
    from capture-only adopter docs.
- User's standing GSD preference (recorded in
  `~/.claude/projects/-Users-jon-projects-threadline/memory/`):
  research-then-recommend; for non-trivial option dimensions dispatch
  parallel subagents and return one coherent recommendation. Phase 57 used
  three parallel research agents (module footprint, verification approach,
  Plug posture) plus a prior single-shot research agent (gating idiom +
  version constraints). The four converged recommendations reinforce each
  other:
  - Q1 + Q2: tight `~> 1.0` LV (no dual-range) + smoke module = simplest
    wrapper code with one clear test target.
  - Q2 + Q3: smoke module gives the verify job something concrete to
    verify (without it, the CI step is theatre).
  - Q3 + Q4: dedicated CI job catches operator-surface gating regressions;
    leaving Plug hard means we don't multiply that gating surface across
    capture wiring.
  - Q4 + Q1: hard Plug + tight LV constraint keeps the gating surface
    narrow — one optional-dep family, one gated namespace.

</specifics>

<deferred>
## Deferred Ideas

- **Mount macro `Threadline.OperatorSurface.Router`** with the
  `threadline_operator_surface "/path", opts` shape — Phase 58.
- **`:authorize_fn` callback contract** and the compile-time fail-closed
  check (mount-macro raises unless one of: scope has `pipe_through`,
  `:authorize_fn` is supplied, or `:adopter_acknowledges_unauthenticated:
  true` is explicit) — Phase 58.
- **`[:threadline, :operator_surface, :authorize]` telemetry event** —
  Phase 58.
- **Doc-contract test** that asserts `Threadline.OperatorSurface` is
  defined when LV is present and is absent when LV is missing — Phase 58
  (the test helper becomes reusable once the mount macro is the first
  module to assert).
- **CHANGELOG `0.4.0` entry** documenting the new optional Phoenix/LV deps,
  the mount macro, and the required `mix.exs` adjustment for hosts that
  want the surface — Phase 63.
- **README "Operator Surface" section, `guides/operator-surface.md`,
  `guides/production-checklist.md` operator-surface row,
  `examples/threadline_phoenix/README.md` end-to-end wiring narrative** —
  Phase 63 (with cross-references to the wired example landing in
  Phase 62).
- **Flipping `:plug` to optional posture** — explicitly out of scope per
  D-02 research. Revisit only if a real Ecto-only adopter files an issue
  asking for it.
- **Splitting `threadline_web` as a separate Hex companion package** —
  deferred to v1.19+ per `.planning/PROJECT.md` out-of-scope row;
  migration path is documented (rename
  `Threadline.OperatorSurface.Router` → `Threadline.Web.Router`,
  deprecation overlap, then extract).
- **Updating `CONTRIBUTING.md` to reference
  `mix verify.compile_no_optional`** — agent discretion in Phase 57 or
  rolled into Phase 63 docs work, depending on planner's minimal-diff
  judgment.

</deferred>

---

*Phase: 57-optional-deps-and-module-gating*
*Context gathered: 2026-05-06*
