# Phase 234: Typespec and Doc Completion Gate - Research

**Researched:** 2026-10-04
**Domain:** Elixir static-analysis tooling (`Code.fetch_docs/1`, `Code.Typespec`, ExDoc 0.40.1, Dialyzer/dialyxir) applied as a committed test-suite gate over the `Threadline` facade and its supporting modules.
**Confidence:** HIGH

## Summary

This phase builds a self-enforcing coverage gate (`Code.fetch_docs/1` + `Code.Typespec.fetch_specs/1`) over every visible public function in `lib/`, narrows `keyword()`/`term()`/`any()` specs into named option types, turns on five additional strict Dialyzer flags with zero ignores, and groups the `Threadline` facade's ExDoc page by job. Everything that matters architecturally was already locked in `234-CONTEXT.md` (53 decisions, D-01 through D-53) by six parallel researchers who read the ExDoc 0.40.1 and Ecto source directly. This RESEARCH.md does not re-litigate those decisions. It exists to give the planner the mechanical facts CONTEXT assumes: the exact current baseline (independently re-measured, matches CONTEXT's figures exactly), the exact shape of `Code.fetch_docs/1`'s `docs_v1` tuple and `Code.Typespec.fetch_specs/1`'s key format, the exact current `mix.exs`/`.dialyzer_ignore.exs` state the gate will be diffed against, and the exact file/line locations the plans must touch.

**Primary recommendation:** Build plan 234-01's checker exactly to the measured baseline below (54 gaps across 92 checked entries in 52 documented modules: 53 `:missing_spec`, 6 `:missing_doc`) and pin that exact set as the starting ratchet. All six plans in D-47's phase shape are ready to execute as specified; no open architectural question remains for the planner to resolve beyond ordinary task sequencing within each plan.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Doc/spec coverage gate | Test/CI (ExUnit contract test) | — | Pure static analysis over compiled BEAM metadata; no runtime behavior |
| Named option/filter types | API/Backend (`lib/threadline.ex` facade + supporting modules) | — | Types are part of the public Elixir API surface adopters' own Dialyzer consumes |
| Runtime option-allowlist closing (D-15/D-17) | API/Backend | — | Runtime validation (`ArgumentError`) must match the `@type` promise; this is business-logic-adjacent validation, not test-only |
| Dialyzer strictness | Dev tooling (mix.exs config + CI job) | — | Build-time static analysis, not shipped runtime code |
| Facade grouping (`@doc group:`) | Documentation (ExDoc metadata on `lib/threadline.ex`) | — | Pure doc-generation metadata; zero runtime effect |
| Call-site fixes (D-17, operator-surface LiveViews/controllers) | Browser/Client-adjacent (LiveView) call sites, but the *fix* is routing to hidden facade functions | API/Backend (`Threadline.Query`/`Investigation`) | The bug is that operator-surface code calls the *public* facade with internal keys; the fix moves those calls to the hidden internal API, not a UI change |

This phase is almost entirely in the Backend/API and Dev-tooling tiers. No browser/client or CDN/static capability is in scope — correctly, since CONTEXT explicitly excludes operator-UI markup changes beyond the forced D-17 call-site moves.

## User Constraints (from CONTEXT.md)

<user_constraints>
### Locked Decisions

See the full 53-decision set in `234-CONTEXT.md` (D-01 through D-53), organized as:
- **Baseline correction (D-01):** real baseline is 54/92 (53 missing spec, 6 missing doc) across 52 documented modules, not the stale roadmap figure of 129/169.
- **SPEC-01 coverage gate (D-02–D-12):** new `test/threadline/doc_spec_coverage_contract_test.exs`, universe definition, doc+spec-at-max-arity rule, macro exemption, `@typedoc` requirement, `@doc false` hidden-pin, triage of the 54 gaps (46 documented, 8 hidden), CHANGELOG breaking-change bullets for newly hidden functions, ratchet-then-delete pin pattern, mutation controls, vacuity sentinels, no new `mix verify.*` alias.
- **SPEC-02 real specs (D-13–D-25):** types live on the `Threadline` facade (no `Threadline.Types` module); `lib/threadline.ex` gets one exact-pinned `@file_exceptions` entry; close every runtime option allowlist (`ArgumentError` on unknown keys); the internal `:surface`/`:params` keys must leave public allowlists (D-17 forced call-site moves); option-type architecture (small shared pieces composing into one union per function family, never one big `Threadline.opts()`); `row_id()` type; deprecated options stay typed through 1.x; three-way drift guard (allowlist == `@type` keys == doc bullets); hand-written struct field types; `Page.t(entry)` stays parameterized; the R1–R5 spec rubric for surviving `term()`/`any()`/`map()`/`keyword()`.
- **Dialyzer strictness (D-26–D-28):** flags become `[:unmatched_returns, :extra_return, :missing_return, :underspecs, :error_handling]` with `list_unused_filters: true`; 22 warnings measured, all fixed in-phase (never ignored); zero ignores stays enforced; no `@opaque`, no `no_return()` on public bang functions.
- **SPEC-03 facade grouping (D-29–D-34):** `@moduledoc groups:` + `@doc group:` (not `groups_for_docs`); four groups in REQUIREMENTS order (Capture & Transactions, Querying & Timelines, Actions & Context, Operations); exact function→group table (23 entries); moduledoc `## Jobs` section replaces the hand-written function list; new `describe` block in `facade_naming_contract_test.exs`; raise `{:ex_doc, "~> 0.40"}`.
- **Doc rubric (D-35–D-46):** summary-first paragraphs, two-tier template (full/floor), `## Options`/`## Filters` exact bullet form, captured-data note (D-38), no `iex>` examples, `since: "1.0.0"` only on new names, no pointers to deprecated functions, brand-voice rules, mechanized checks (M2–M9), the full D-45 rubric committed as `234-SPEC-RUBRIC.md` before any doc is written, exhaustive agent review (D-46).
- **Phase shape (D-47–D-49):** six plans, sequential, no worktrees for this phase; exact plan boundaries and dependencies (02–05 depend only on 01; 06 depends on all); executor halt clauses (D-48); CHANGELOG policy (D-49).
- **Seams to 235/236/237 (D-50–D-53).**

### Claude's Discretion

- Exact wording of the group descriptions beyond D-30, and of the doc prose.
- Whether the D-21 parity and D-44 doc checks share the D-02 file or a sibling `doc_rubric_contract_test.exs`, as long as everything is `async: true` and weighted.
- The internal shape of `__option_keys__/1`, or an equivalent way to expose allowlists.
- Whether the `Evidence` list-function arities collapse into defaults (D-47, 234-03).
- How each of the 22 Dialyzer findings is fixed: code versus spec, as long as nothing is ignored and the result stays honest.

### Deferred Ideas (OUT OF SCOPE)

- `@moduledoc groups:` for `Threadline.Evidence` (13 functions) and `Threadline.StorageSchema`. Cheap later with the Ecto pattern; SPEC-03 covers the facade only.
- A full visible-surface snapshot that catches removed functions belongs to 235's stability contract.
- A doc-substance floor in the gate was measured as vacuous today: no first line is under 30 characters. Substance stays with the D-45 agent rubric.
- NimbleOptions-generated `## Options` as a single source of truth stays excluded by REQUIREMENTS. A possible 1.x revisit; D-21 parity covers drift now.
- `as_of!/4` is still additive in 1.x (233 D-03).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SPEC-01 | Every public function in every documented module under `lib/` has a `@doc` and a `@spec`; `async: true` test using `Code.fetch_docs/1` + `Code.Typespec.fetch_specs/1` fails on any gap. | Baseline independently re-measured below (confirms CONTEXT D-01's 54/92 exactly); `docs_v1` shape and `fetch_specs` key-format documented below; `Code.fetch_docs` on `Code.compile_string` modules independently confirmed to return `{:error, :module_not_found}`, validating D-10's binary-read mutation-control design. |
| SPEC-02 | No public spec uses bare `term()`/`any()`; options use named `@type`s; agent review against written rubric; strict Dialyzer green with zero ignores. | Current `mix.exs` dialyzer config and `.dialyzer_ignore.exs` read directly (below); per-file `term()`/`any()`/`keyword()` grep below; D-17 call sites and the WR-01 bug location independently confirmed at the cited lines. |
| SPEC-03 | `Threadline` facade grouped by `@doc group:` into 4 named groups; test fails on any ungrouped facade function. | ExDoc 0.40.1 grouping mechanism (`config.ex:7`, `retriever.ex:140-152`) read and confirmed below; Ecto's `@moduledoc groups:` precedent (`deps/ecto/lib/ecto/repo.ex:223`) confirmed; current `mix.exs` `docs()` confirmed to have no `groups_for_docs`, so no conflict exists today. |
</phase_requirements>

## Standard Stack

No new dependencies. This phase is pure stdlib (`Code`, `Code.Typespec`, `:beam_lib`) plus the existing dev dependencies already in `mix.lock`:

| Library | Version (verified in mix.lock) | Purpose |
|---------|---------|---------|
| `ex_doc` | `0.40.1` installed; `mix.exs:108` currently pins `"~> 0.34"` — D-34 raises it to `"~> 0.40"` | ExDoc grouping (`:group` metadata arrived in 0.36) [VERIFIED: `mix.lock:15` — `"ex_doc": {:hex, :ex_doc, "0.40.1", ...}`] |
| `dialyxir` | `1.4.8` [VERIFIED: `mix.lock:7`] | Dialyzer wrapper, `mix dialyzer` |
| Elixir | `1.17.3` on OTP 27 [VERIFIED: ran `elixir --version` this session] | `~> 1.15` floor unchanged in `mix.exs:46` |

**Installation:** none — no new packages. This phase only edits `mix.exs`'s `{:ex_doc, ...}` version constraint string and the `dialyzer:` keyword list, both already dependencies.

## Package Legitimacy Audit

No new external packages are installed in this phase. `ex_doc` and `dialyxir` are pre-existing dependencies; only version-constraint strings change. Package Legitimacy Gate is not applicable.

## Architecture Patterns

### System Architecture Diagram

```
                      ┌─────────────────────────────┐
                      │   lib/**/*.ex (compiled)     │
                      │  (debug_info chunk present   │
                      │   because MIX_ENV=test/dev)  │
                      └──────────────┬────────────────┘
                                     │
                     :application.get_key(:threadline, :modules)
                                     │
                                     ▼
                  ┌──────────────────────────────────┐
                  │ Universe filter (D-03):            │
                  │  source not under /test/  AND      │
                  │  moduledoc != :hidden               │
                  └──────────────┬───────────────────┘
                                 │  52 documented modules
                                 ▼
          ┌──────────────────────────────────────────────┐
          │  Code.fetch_docs(mod) → {:docs_v1, _, _, _,    │
          │    moduledoc, meta, entries}                    │
          │  filter entries: kind in [:function,:macro],    │
          │    doc != :hidden, name not "__*__"             │
          └───────────────┬────────────────────────────────┘
                          │ 92 checked entries
                          ▼
     ┌───────────────────────────────────────────────────────┐
     │ Code.Typespec.fetch_specs(mod) → {:ok, [{{name,arity}, │
     │   spec_ast}, ...]}  (macro key is {:"MACRO-name",      │
     │   arity+1})                                            │
     └───────────────┬─────────────────────────────────────────┘
                     │  per-entry gap classification
                     ▼
        gaps :: [{module, fun, arity, :missing_doc |
                  :missing_spec | :missing_typedoc}]
                     │
                     ▼
        test/threadline/doc_spec_coverage_contract_test.exs
        (pure `gaps/3` checker behind a thin live wrapper,
         pinned exact-set ratchet, deleted entry-by-entry
         as each plan documents/specs a function)
```

A reader can trace: compiled modules → filtered to the documented universe → each module's doc entries enumerated → each entry's spec existence checked against the arity convention → gaps classified → asserted against a pinned exact set that shrinks plan by plan.

### Recommended Project Structure

No new directories. New/touched files, all already named by CONTEXT:

```
test/threadline/
├── doc_spec_coverage_contract_test.exs   # NEW (D-02) — the gate
├── facade_naming_contract_test.exs       # EXTENDED (D-33) — new describe block for groups
├── dialyzer_ignore_contract_test.exs     # EXTENDED (D-27) — flags assertion updated to 5-flag sorted list
├── source_size_contract_test.exs         # EXTENDED (D-14) — @file_exceptions gains lib/threadline.ex
└── (sibling, planner's discretion) doc_rubric_contract_test.exs  # D-21/D-44 checks, OR folded into doc_spec_coverage_contract_test.exs

234-SPEC-RUBRIC.md                        # NEW (D-45), committed in plan 234-01 before any doc/spec write
```

### Pattern 1: Pure checker behind a thin live wrapper (D-02, D-09)

**What:** The gap-detection logic is a pure function `gaps(module, docs_v1, specs) :: [{m, f, a, reason}]` that takes already-fetched data. A thin wrapper calls `Code.fetch_docs/1` and `Code.Typespec.fetch_specs/1` and passes the results in. The *same* pure function is exercised twice: once against the real `lib/` universe, once against an in-test fixture module compiled with `Code.compile_string` (read from its binary, not via `Code.fetch_docs`, since that returns `:error` for compile_string modules — independently confirmed below).

**When to use:** Whenever a contract test needs both a live-codebase assertion and a hermetic, mutation-controlled fixture assertion sharing one code path.

**Example (adapted from the `source_size_contract_test.exs` exact-pin exception pattern, confirmed present at the cited lines):**
```elixir
# Source: existing pattern read directly this session —
# test/threadline/source_size_contract_test.exs:51-63
@file_exceptions %{
  "lib/threadline/operator_surface/stress_fixtures.ex" =>
    {980, "declarative fixture data tables; excluded from the Hex package (mix.exs exclude_patterns)"}
}

test "exactly one named exception remains: the declarative stress fixture tables" do
  assert Map.keys(@file_exceptions) == ["lib/threadline/operator_surface/stress_fixtures.ex"]
  # ... exception file must still actually be at or above the pinned line count,
  #     so a stale pin (file shrunk) also fails.
end
```
This is the model D-09's ratchet reuses: a pinned exact set that fails if it goes stale in *either* direction (gap fixed but pin not removed = fail; new gap introduced and not pinned = fail).

### Anti-Patterns to Avoid

- **Reading `Code.fetch_docs/1` on a module compiled via `Code.compile_string/1` and expecting real data.** It returns `{:error, :module_not_found}` [VERIFIED this session: ran `Code.fetch_docs(mod)` against a `Code.compile_string`-produced module, matched against `{:error, _}`]. The D-10 mutation-control fixture must instead read `:beam_lib.chunks(bin, [~c"Docs"])` and `Code.Typespec.fetch_specs(bin)` directly off the returned binary, never via the module name.
- **Treating a bare `keyword()` as acceptable "because Dialyzer doesn't complain."** D-18 independently verified: against `[row_history_opt()]` Dialyzer flags a typo'd key (`limitt: 3`); against `keyword()` it does not. The whole point of named option types is the Dialyzer coverage a bare `keyword()` throws away.
- **Adding a broad `groups_for_docs` predicate in `mix.exs`'s `docs()`.** D-29 confirms `groups_for_docs` predicates take precedence over `@doc group:` metadata (`config.ex:116-124`), so a later broad predicate would silently override every careful per-function `@doc group:` tag. Confirmed: no `groups_for_docs` key exists in the current `docs()` function [checked directly this session].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Doc/spec coverage checking | A custom AST walker over `lib/**/*.ex` source files | `Code.fetch_docs/1` + `Code.Typespec.fetch_specs/1` over compiled modules | Source-level AST walking misses macro-expanded default-argument arities, `defdelegate`-generated clauses, and `@impl`/protocol-impl auto-hiding — all of which the BEAM's own doc/debug_info chunks already resolve correctly, as confirmed by this session's direct measurement matching CONTEXT's D-03/D-04 predictions exactly. |
| Option validation | NimbleOptions | Hand-rolled per-function allowlists (existing pattern, `@lookup_opt_keys` in `transaction_lookup.ex:15`, `@row_history_opt_keys` in `investigation.ex:21`) | REQUIREMENTS.md explicitly excludes NimbleOptions as Out of Scope: "Options are flat and per-function, and the hand-rolled validators give more specific errors. It would add a dependency for no benefit." |
| Grouped facade docs | A hand-maintained Markdown API-reference page | `@moduledoc groups:` + `@doc group:` (ExDoc-native) | REQUIREMENTS.md Out of Scope: "A hand-maintained API-reference guide... would duplicate ExDoc and drift, and no doc-contract test could catch it." |

**Key insight:** every "don't hand-roll" in this phase is already a locked project-level decision in REQUIREMENTS.md, not a fresh research finding — the risk here is an executor reaching for NimbleOptions or a hand-maintained reference page out of habit, not a genuine unknown.

## Runtime State Inventory

Not applicable — this is not a rename/refactor/migration phase. It is additive (new types, new test file, new `@doc`/`@spec` annotations) plus a small number of forced call-site edits (D-17) and runtime-behavior-changing allowlist closures (D-15), none of which touch stored data, live service config, OS-registered state, secrets, or build artifacts in the sense this inventory covers.

## Common Pitfalls

### Pitfall 1: Trusting the `mix run -e`/script compile path for debug_info experiments

**What goes wrong:** A scratch `.exs` script compiled via `mix run <script>.exs` does not register with `:code.get_object_code/1` the way a real `_build/{env}/lib/threadline/...` compiled module does, so experiments like "does a macro's spec actually produce a `MACRO-name/arity+1` key" can spuriously fail with `:error` from `:code.get_object_code` even though the real `lib/` build works fine.

**Why it happens:** `mix run` loads the script in-memory without writing a BEAM file to a code path directory `:code.get_object_code` can find.

**How to avoid:** Verify spec/doc mechanics against the **real compiled app** (`MIX_ENV=test mix run <script_calling_real_modules>.exs`, as done successfully in this session's baseline measurement) rather than against throwaway modules defined inside the same script. The baseline-measurement script in this research, which iterated `:application.get_key(:threadline, :modules)` and called `Code.Typespec.fetch_specs/1` on each real module, worked correctly and reproduced CONTEXT's D-01 figures exactly. A follow-up experiment defining a scratch macro-with-spec module inside the same script failed to retrieve its specs via `:code.get_object_code/1` — a tooling artifact of the script-compile path, not a fact about real `lib/` modules.

**Warning signs:** `:code.get_object_code/1` returning `:error` for a module you just defined in the same script.

### Pitfall 2: Forgetting the arity convention for default-argument functions (D-04)

**What goes wrong:** Writing a `@spec` at every arity a function has, rather than only at the docs-entry (maximum) arity, either produces redundant/misleading specs or an executor mistakenly believes lower arities need their own gap-fix.

**Why it happens:** `def f(a, b \\ nil)` produces two entries in `module_info` (`f/1` and `f/2`) but ExDoc and the doc chunk only carry one docs entry at the max arity; `Code.Typespec.fetch_specs/1` likewise only needs (and Elixir/Ecto convention only specs) the max arity.

**How to avoid:** The gate's own universe-filtering already follows the docs-entry convention (confirmed: my measured 92-entry universe used the `:docs_v1` entries, not raw `module_info(:functions)` arities). Executors must write specs only at the arity ExDoc actually renders a doc for.

**Warning signs:** A `@spec` added at a non-max default-argument arity triggers a Dialyzer `extra_range`/contract warning or is simply invisible to the gate (silently not read).

### Pitfall 3: Closing an option allowlist before moving the internal-key call sites (D-15 before D-17 ordering)

**What goes wrong:** If a plan closes `@row_history_opt_keys`/similar allowlists to reject unknown keys before the `actor_live.ex`/`export_controller.ex` call sites are moved off the public facade onto the hidden `Threadline.Query`/`Investigation` functions, the operator-surface LiveViews and controllers break at runtime (and, with closed `[opt()]` types, Dialyzer goes red — independently confirmed as the stated mechanism in D-17).

**Why it happens:** `actor_live.ex:32,309,351,394,431` and `export_controller.ex:178` currently call `Threadline.actor_history`/`Export.*` with literal `surface:`/`params:` keys [VERIFIED this session: grepped and read these exact lines, confirmed `surface: :actor_history, params: %{...}` at actor_live.ex and `surface: :export, params: %{filters: filters}` at export_controller.ex:178-179].

**How to avoid:** CONTEXT already orders this correctly inside plan 234-02 ("D-17 call-site moves, D-15/D-16 allowlist closing... D-14 size pin"). The planner should preserve that internal task ordering within 234-02 rather than parallelizing it.

**Warning signs:** `mix compile --warnings-as-errors` or the example app's own compile step failing after an allowlist closes, or a LiveView test raising `ArgumentError` on an unknown option.

## Code Examples

### `Code.fetch_docs/1` return shape (confirmed this session against real `lib/` modules)

```elixir
# Source: this session, MIX_ENV=test mix run against the real compiled app
{:docs_v1, _anno, _lang, _format, moduledoc, _module_meta, entries} = Code.fetch_docs(Threadline)

# entries is a list of:
# {{kind, name, arity}, _anno, _signature, doc, metadata}
# kind in [:function, :macro, :type, :callback, ...]
# doc is :none | :hidden | %{"en" => "markdown text"}
# metadata is a map that can carry :group, :since, :deprecated, etc.
```

### `Code.Typespec.fetch_specs/1` key format, including the macro `+1` arity rule (confirmed this session)

```elixir
# Source: this session — real spec_key construction used in the baseline
# measurement script, matched against CONTEXT D-04's claim.
{:ok, specs} = Code.Typespec.fetch_specs(SomeModule)
spec_key = if kind == :macro, do: {:"MACRO-#{name}", arity + 1}, else: {name, arity}
has_spec? = Enum.any?(specs, fn {k, _} -> k == spec_key end)
```

### `Code.fetch_docs/1` fails for `Code.compile_string` modules — confirmed this session

```elixir
# Source: this session, direct experiment
mod_name = :"ScratchCS#{System.unique_integer([:positive])}"
src = "defmodule #{mod_name} do\n @moduledoc false\n def f, do: :ok\nend\n"
[{mod, _bin}] = Code.compile_string(src)
Code.fetch_docs(mod)
# => {:error, :module_not_found}
```
This confirms D-10's mutation-control design is correct as specified: the in-test fixture must be read via `:beam_lib.chunks(bin, [~c"Docs"])` and `Code.Typespec.fetch_specs(bin)` against the compiled binary directly, never via `Code.fetch_docs(module_name)`.

### ExDoc group resolution — confirmed against the vendored `deps/ex_doc` source this session

```elixir
# Source: deps/ex_doc/lib/ex_doc/config.ex:7
def default_group_for_doc(metadata), do: metadata[:group]
```
```elixir
# Source: deps/ex_doc/lib/ex_doc/retriever.ex:142-150
moduledoc_groups = Map.get(metadata, :groups, [])
docs_groups =
  get_docs_groups(
    moduledoc_groups ++ config.docs_groups ++ module_data.default_groups,
    nodes_groups,
    docs,
    config
  )
```
Confirms D-29's ordering claim: `@moduledoc groups:` entries are consulted ahead of any `config.docs_groups` (i.e. `groups_for_docs` from `mix.exs`), which is why D-29 forbids ever adding a `groups_for_docs` predicate later — it would take precedence and silently override the per-function tags.

### Ecto's `@moduledoc groups:` precedent — confirmed present at the cited line

```elixir
# Source: deps/ecto/lib/ecto/repo.ex:223 (grepped this session)
@moduledoc groups: [
  # ... (groups list; line 250 shows the per-function form: @doc group: "Process API")
]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `mix.exs` `dialyzer: [flags: [:unmatched_returns, :extra_return], ...]` | Adds `:missing_return, :underspecs, :error_handling` | This phase (D-26) | 22 new warnings surface, all fixable in-code/spec per CONTEXT's own prior measurement; confirmed current flag list is exactly `[:unmatched_returns, :extra_return]` today [VERIFIED: `mix.exs:72` read directly this session] |
| `{:ex_doc, "~> 0.34", only: :dev, runtime: false}` | `{:ex_doc, "~> 0.40", ...}` | This phase (D-34) | `:group` metadata (needed for SPEC-03) arrived in ExDoc 0.36; 0.40.1 is already the resolved/installed version in `mix.lock`, so this is a constraint-string fix, not a real upgrade |
| Hand-written "Reading audit data" function list in the `Threadline` moduledoc | Short `## Jobs` section, one bullet per group | This phase (D-32) | The only group signal ExDoc's Markdown/`llms.txt` output preserves, per D-32 |

**Deprecated/outdated:** none introduced by this phase beyond what 232/233 already deprecated; this phase documents/types the deprecated delegates honestly (D-20) rather than removing or hiding them.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The 22 Dialyzer warnings from the five added flags (D-26) are still exactly 22 and distributed as CONTEXT describes (9 `missing_range`, 9 `contract_supertype`, 4 `error_handling`). This research did not re-run `mix dialyzer` with the new flags (a cold PLT rebuild costs ~9 minutes per CONTEXT's own note, and the flags are not yet added to `mix.exs`). | Dialyzer strictness, D-26 | If the real count differs once the flags are actually added in plan 234-06, the plan's fix list undercounts or overcounts work; low risk since this is CONTEXT's own prior measurement, already a locked decision, not a fresh unverified claim from this research session. |
| A2 | The exact 23-function facade group table in D-31 still matches `Code.fetch_docs(Threadline)`'s current function set. This research did not independently re-enumerate all 23 and cross-check against the table (CONTEXT itself flags this with "Re-check the 23 entries against `Code.fetch_docs(Threadline)` at execution time"). | SPEC-03, D-31 | If a facade function was added/removed/renamed between CONTEXT's gathering and plan 234-02's execution, the pinned `{name,arity} => group` table in D-33(b) would need a one-line correction; CONTEXT already flags this as an execution-time re-check, not a planning gap. |

**If this table is empty:** N/A — two low-risk items above, both already flagged by CONTEXT itself as execution-time re-checks rather than open design questions.

## Open Questions

None blocking. CONTEXT.md's 53 decisions cover every architectural and mechanical question the planner needs; this research's job was to confirm the mechanics and baseline numbers CONTEXT assumes, and both independently reproduced exactly.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP | all plans | ✓ | Elixir 1.17.3 / OTP 27 [VERIFIED this session] | — |
| Mix | all plans | ✓ | Mix 1.17.3 | — |
| `ex_doc` (installed) | SPEC-03, `mix docs --warnings-as-errors` | ✓ | 0.40.1 already resolved in mix.lock | — |
| `dialyxir` | Dialyzer strictness gate | ✓ | 1.4.8 | — |
| PostgreSQL (local) | full test suite (`mix ci.all`, not this phase's gate tests directly) | ✓ running on port 5432 | psql 14.17 (Homebrew) — below the 1.0 floor of PG 15 (FLOOR-01, phase 236), but not blocking for 234's gate/spec/doc work | If a plan's verification step needs the `min` PG 15 lane, that is phase 236's CI lane, not local dev; no fallback needed here |

**Missing dependencies with no fallback:** none.

**Missing dependencies with fallback:** none required for this phase's work.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/threadline/doc_spec_coverage_contract_test.exs` |
| Full suite command | `mix verify.test` (aliased to `mix test`); `mix ci.all` for the full gate incl. Dialyzer |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SPEC-01 | Zero doc/spec gaps across the documented `lib/` universe; mutation control turns red on a new gap | unit (ExUnit, `async: true`) | `mix test test/threadline/doc_spec_coverage_contract_test.exs` | ❌ Wave 0 (plan 234-01 creates it) |
| SPEC-01 | Vacuity sentinels (≥50 modules, ≥90 entries, `{Threadline,:timeline,2}` present) | unit, same file | same command | ❌ Wave 0 |
| SPEC-02 | No surviving bare `term()`/`any()`/`keyword()` without an R-rule; three-way option-key parity (allowlist == type == doc bullets) | unit (ExUnit, `async: true`) + agent review | `mix test test/threadline/doc_spec_coverage_contract_test.exs` (or sibling `doc_rubric_contract_test.exs`, planner's discretion) + manual agent-review pass recorded in VERIFICATION.md per D-46 | ❌ Wave 0 (mechanized checks); agent review is not a `mix test` command — runs once per plan per D-46 |
| SPEC-02 | Strict Dialyzer, zero ignores | static analysis | `MIX_ENV=dev mix verify.dialyzer` then `mix verify.dialyzer_slice` | ✅ exists today; flags/assertions extended in 234-06 |
| SPEC-03 | Every facade function has a group; exact `{name,arity}=>group` pin; moduledoc groups/order; `## Jobs` bullets resolve | unit (ExUnit, `async: true`) | `mix test test/threadline/facade_naming_contract_test.exs` | ✅ file exists; new `describe` block added in 234-02 |
| SPEC-02/03 | Doc link integrity (`mix docs --warnings-as-errors`), including the hidden-type-reference warning D-13 relies on | doc build | `MIX_ENV=dev mix docs --warnings-as-errors` | ✅ existing command; already part of `verify.release` per CONTEXT |

### Sampling Rate
- **Per task commit:** `mix test test/threadline/doc_spec_coverage_contract_test.exs test/threadline/facade_naming_contract_test.exs` (the two files directly under change), plus `mix verify.dialyzer` at the end of every plan (per CONTEXT's "every plan ends with `mix verify.dialyzer` and `MIX_ENV=dev mix docs --warnings-as-errors`").
- **Per wave merge:** `mix verify.test` (full suite).
- **Phase gate:** `mix ci.all` green (234-06's close step) plus the exhaustive agent review of all ~92 entries (D-46) recorded 100% passing in VERIFICATION.md.

### Wave 0 Gaps
- [ ] `test/threadline/doc_spec_coverage_contract_test.exs` — covers SPEC-01, part of SPEC-02 (bare-type lint, option-key parity if co-located per D-21's "sibling... or alongside the D-02 test")
- [ ] `234-SPEC-RUBRIC.md` — the written rubric file itself, committed before any doc/spec write, consumed by the D-46 exhaustive review (not a `mix test` artifact, but a Wave 0 deliverable of plan 234-01)
- [ ] A new `test/partition_weights.txt` line for the new gate test file (~30ms per D-02's "about 30" estimate) — framework install not needed, ExUnit is already the framework; just the weight-registration step 234-01 must not skip (per the permanent missing-weight check 236 inherits per D-52)

*(No framework install needed — ExUnit and dialyxir are both already configured.)*

## Security Domain

> `security_enforcement` status not found as explicitly `false` in `.planning/config.json` for this project snapshot — treated as enabled per the governing instruction, though this phase has no attack-surface-shaped work.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | no | N/A — no auth code touched |
| V3 Session Management | no | N/A |
| V4 Access Control | no (indirectly relevant via D-17) | D-17's fix routes operator-surface internal keys off the *public* facade onto hidden internal functions — this closes an API-surface leak (an adopter could in principle pass `:surface`/`:params` to the public `actor_history/2`), but it is a type/option-hygiene fix, not an access-control feature |
| V5 Input Validation | yes | D-15 closes every runtime option allowlist to raise `ArgumentError` on unknown keys — the existing hand-rolled-allowlist pattern (`transaction_lookup.ex:15`, `investigation.ex:21`), not a new library |
| V6 Cryptography | no | N/A — no crypto work in this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Internal-only option keys (`:surface`, `:params`) reachable through a public function's keyword-list API, silently accepted because the allowlist is wider than intended | Tampering / Information Disclosure (an adopter passing an internal key could get undocumented/unstable binding behavior) | D-15's closed per-function allowlist (`ArgumentError` on any key not in the named `@type` union) — the same hand-rolled pattern already used elsewhere in this codebase, not a new control |
| A spec that lies about its return shape (`missing_range` Dialyzer findings on the deprecated legacy-paging specs) masking an actual behavior change | Tampering (of trust in the contract adopters' own Dialyzer relies on) | D-26's five-flag strict Dialyzer set, fixed to zero ignores — standard dialyxir/Oban-style strictness, not a bespoke control |

## Sources

### Primary (HIGH confidence — read directly this session)
- `mix.exs` — current `dialyzer:` flags (`:unmatched_returns`, `:extra_return` only), `{:ex_doc, "~> 0.34"}` pin, `docs()` function (no `groups_for_docs`)
- `mix.lock` — `ex_doc` 0.40.1, `dialyxir` 1.4.8 resolved versions
- `.dialyzer_ignore.exs` — confirmed `[]`
- `test/threadline/dialyzer_ignore_contract_test.exs` — confirmed current flags assertion `[:extra_return, :unmatched_returns]`
- `test/threadline/public_surface_contract_test.exs` — confirmed `@hidden_modules`/`@hidden_functions` structure
- `test/threadline/facade_naming_contract_test.exs` — confirmed existing `async: true`, `since`/`deprecated` metadata assertion pattern
- `test/threadline/source_size_contract_test.exs` — confirmed `@file_exceptions` exact-pin pattern at lines 51-63, `@file_limit 800`
- `lib/threadline/investigation.ex:21` — confirmed `@row_history_opt_keys` includes `surface`
- `lib/threadline/query/transaction_lookup.ex:15,97-134` — confirmed `@lookup_opt_keys`, `fetch_row/2`/`fetch/2` WR-01 bug shape (resolve_id checked before `Keyword.fetch!(opts, :repo)`)
- `lib/threadline/operator_surface/live/actor_live.ex:32,39,309,317-318,351,359-360,394,401-402,431,438-439` — confirmed D-17 call sites (`surface: :actor_history, params: %{...}`)
- `lib/threadline/operator_surface/controllers/export_controller.ex:178-179` — confirmed D-17 call site (`surface: :export, params: %{filters: filters}`)
- `deps/ex_doc/lib/ex_doc/config.ex:7,116-124` — confirmed `default_group_for_doc/1` and `groups_for_docs` precedence
- `deps/ex_doc/lib/ex_doc/retriever.ex:140-150,260-265` — confirmed group-ordering logic
- `deps/ecto/lib/ecto/repo.ex:223,250` — confirmed `@moduledoc groups:`/`@doc group:` precedent
- `test/partition_weights.txt`, `bin/ci-test-partitions` — confirmed format and `--write-weights` regeneration mechanism
- Live measurement this session (`MIX_ENV=test mix run <scratch script>`, deleted after use): enumerated the real 52-documented-module / 92-checked-entry / 54-gap universe against the real compiled `threadline` app, matching CONTEXT D-01/D-07 exactly, including the precise 8 D-07 hide candidates (`StorageSchema.quote_ident/1` etc., `Evidence.Proof.present_record/1`/`record_claim_assessment/1`)
- Live measurement this session: confirmed `Code.fetch_docs/1` returns `{:error, :module_not_found}` for a `Code.compile_string`-produced module, validating D-10's binary-read mutation-control design

### Secondary (MEDIUM confidence)
- `234-CONTEXT.md`'s own citations to peer-library prior art (Oban's Dialyzer flag choices, Finch's `request_opt` naming, Rust/Go/TS doc-completeness lint prior art) — these were gathered by the six parallel CONTEXT researchers, not independently re-verified this session, but are locked decisions, not open research questions.

### Tertiary (LOW confidence)
- None — every claim in this document was either read directly from the repository/deps this session or copied verbatim from the already-locked CONTEXT.md.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies, versions read directly from mix.lock
- Architecture: HIGH — every mechanism (doc chunk shape, Typespec key format, ExDoc grouping precedence) independently confirmed against real compiled code and vendored ExDoc/Ecto source this session
- Pitfalls: HIGH — each pitfall traces to a specific confirmed fact (compile_string doc-fetch failure, call-site line numbers, arity convention)

**Research date:** 2026-10-04
**Valid until:** Effectively the life of this phase (234's execution window) — the baseline numbers will shift the moment plan 234-01 starts deleting pins, by design (D-09's ratchet). Re-measure before each plan if more than a few days elapse between planning and execution.
</content>
