# Phase 231: Facade Topology and the Capture/Semantics Edge - Research

**Researched:** 2026-10-03
**Domain:** Elixir/Ecto API-surface hiding (ExDoc visibility), Ecto association removal with behavior-preserving hydrate helper
**Confidence:** HIGH

## Summary

This phase has no unknowns requiring external research — it is a closed-world refactor inside a single, already-mapped codebase, and 231-CONTEXT.md already carries 13 locked decisions (D-01..D-13) with exact file:line targets. The research work here is **verification**: every claim in CONTEXT.md was read against the live source tree this session and confirmed, and two consequential facts were found that CONTEXT.md does not mention and the plan must account for.

**New findings not in CONTEXT.md (the two things planning must add):**
1. Two tests assert the **literal source text** of the preload call sites being changed: `test/threadline/query_test.exs:983` ("query preload call sites pass resolved storage options") and `test/threadline/operator_surface/live/timeline_live_test.exs:1204` ("source contract: visible Timeline preloads pass selected storage opts"). Both read the `.ex` file with `File.read!/1` and assert `source =~ "repo.preload(... [transaction: :action] ...)"`. Introducing the hydrate helper will make these two tests fail even though behavior is unchanged — they must be updated to assert the new call shape in the same commit that changes `query.ex:109` and `timeline_live.ex:552`.
2. `Threadline.Query` and `Threadline.Investigation` are currently listed in `mix.exs`'s `groups_for_modules["Core API"]` (lines ~628, ~634), and `public_surface_contract_test.exs` has a test ("every visible compiled module belongs to exactly one of six groups") asserting `MapSet.new(flattened) == visible_modules()`. Hiding the two modules via `@moduledoc false` without also removing them from that `groups_for_modules` list will make this existing test fail (a hidden module would still appear in the group list). Their child structs (`Threadline.Query.Cursors`, `.FilterParams`, `.Scope`, `.TimelinePage`, `.ActorHistoryPage`, `Threadline.Investigation.IncidentBundle`, etc.) are separate modules with independent visibility and must **not** be touched — they stay visible/grouped exactly as today.

**Primary recommendation:** Treat this as a mechanical, four-part change: (1) hide `Query`/`Investigation` and repair `mix.exs` groups + add the `skip_code_autolink_to` entry + rewrite `lib/threadline.ex` moduledoc/docstrings; (2) drop the two Ecto associations and add the hidden hydrate helper, rewriting the 6 call sites (including the 2 source-literal tests) and adding the `preload: :action` deprecation shim; (3) rewrite the 8 guide/example call sites and add the new `facade_only_references_contract_test.exs`; (4) add the `__schema__(:associations)` mutation-controlled test. All four are independently verifiable and should land as ordered, dependency-respecting waves.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Hide `Threadline.Query`/`Threadline.Investigation` from docs | Exploration/Operations (docs/API surface) | — | ExDoc visibility is a docs-generation concern, owned by the exploration layer's public-facing contract, not capture or semantics |
| `timeline_query/1` escape hatch naming | Exploration/Operations | — | It is Query's one deliberately-exposed Ecto-composition function; naming it lives in the facade's docs |
| Drop `belongs_to :action` / `has_many :transactions` | Capture layer (`AuditTransaction`) + Semantics layer (`AuditAction`) | — | Per CLAUDE.md's three-layer rule: capture must not own semantics-layer associations, and vice versa; this is the edge the phase is named for |
| `.action` hydration after association removal | Exploration/Operations (new hidden helper in `Threadline.Query`) | — | Cross-layer joins belong in the exploration layer, never in the capture or semantics schemas themselves |
| `preload: :action` deprecation shim | Exploration/Operations (`query.ex` public option parsing) | — | Public option compatibility is an API-surface concern, same tier as the functions that expose `:preload` |
| Guide/example call-site rewrites | Docs (guides, README, example app) | — | No runtime tier; pure documentation/example code following the new facade-only contract |

## User Constraints

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Escape hatch: how `timeline_query/1` is "linked"**
- D-01: ExDoc 0.40.1 (the version in `mix.lock`) cannot render a link to a function in a `@moduledoc false` module. It emits a "hidden or private" warning, and `mix docs --warnings-as-errors` (mix.exs:336) fails on it. So "the `Threadline` moduledoc links `Threadline.Query.timeline_query/1`" (SC1) means the moduledoc **names** it as inline code. It is not a clickable anchor. Add `skip_code_autolink_to: ["Threadline.Query.timeline_query/1"]` to `docs()` in `mix.exs`. This is ExDoc's documented mechanism for mentioning private or hidden functions (deps/ex_doc/lib/ex_doc.ex ~line 156). Keep the list to exactly that one entry.
- D-02: The SC1 test reads the moduledoc via `Code.fetch_docs(Threadline)` and asserts the text contains `Threadline.Query.timeline_query/1`. The test lives with the hidden-set pin in `test/threadline/public_surface_contract_test.exs`: add `Threadline.Query` and `Threadline.Investigation` to `@hidden_modules`.
- D-03: Every other reference to `Threadline.Query.*` or `Threadline.Investigation.*` in `lib/threadline.ex` docs (about 13: `timeline/2`, `audit_changes_for_transaction/2`, `history`, `as_of`, `actor_history`, `timeline_page`, `incident_bundle`, ...) is rewritten. Each becomes a facade `Threadline.*` reference or self-contained prose, for example the ordering guarantee and correlation semantics stated inline. None of them may need a skip entry.
- D-04: Rejected: a `Threadline.timeline_query/1` facade delegate. It would deviate from the requirement wording and add public API surface.

**`.action` after the association is dropped**
- D-05: `AuditTransaction` removes `belongs_to :action`. It declares `field :action_id, :binary_id` explicitly (formerly generated by `belongs_to`; `cast` already lists `:action_id`) and `field :action, :any, virtual: true, default: nil`. `@type t` must NOT reference `AuditAction.t()`. The moduledoc's "Relationships" section is updated in prose. — Reversibility: costly — re-adding the association later would reintroduce the cross-layer dependency this milestone's 1.x contract freezes out.
- D-06: `AuditAction` removes `has_many :transactions` (no callers found).
- D-07: Behavior change to note in the CHANGELOG: an un-hydrated `transaction.action` is now `nil` instead of `%Ecto.Association.NotLoaded{}`. No existing call site matches on `NotLoaded`.
- D-08: The hydrate helper is a `@doc false` internal function in the exploration layer, inside `Threadline.Query` (or a small hidden submodule if `query.ex` crowds). It is not a new public namespace. Its contract:
  - It accepts a single `AuditTransaction`, a list of them, or `AuditChange`s with their transaction already loaded (it walks changes → transaction → action).
  - It dedupes the non-nil `action_id`s and runs ONE `WHERE id IN ^ids` query.
  - It threads `storage_opts`/`StorageSchema.repo_opts(opts)` exactly as the current `repo.preload` calls do. Honoring the storage-schema prefix is mandatory.
- D-09: Every internal `:action` preload site switches to the helper:
  - `query.ex:109` (`preload_investigation_context`)
  - `investigation.ex:134,154,167`
  - `operator_surface/live/timeline_live.ex:552`
  - `operator_surface/live/transaction_live.ex:22`

  These are forced call sites; markup is not touched. Every existing assertion on `.action` must pass unchanged (SC4).

**Public `preload:` options naming `:action` (HIGH-IMPACT: user decided)**
- D-10: Keep it working and warn. The affected options are the public `:preload` opt paths (`audit_changes_for_transaction/2`, the single-transaction fetch at `query.ex:128-137`, and any facade wrapper that forwards `:preload`). In them, `:action` and `transaction: :action` are pulled out of the preload list. The rest goes through `repo.preload`, then the hydrate helper fills `.action`. One deprecation warning (`IO.warn`/`Logger.warning`, planner's choice; consistent with Phase 232's tone) names the replacement path. Removal is earliest 2.0. Nested keys under `:action` (e.g. `[action: :x]`) raise `ArgumentError`, because `AuditAction` has no associations to traverse. Tests cover the pulled-out-and-warned path and the nested-raise path. — Reversibility: one-way — once 1.0 ships with this compatibility path, removing it is a semver-major change.
  - Rationale: Phase 232 promises "a working call and one warning" for retired names. A retired preload key gets the same treatment instead of being the one hard break in the API-freeze release.

**Guide rewrites and the facade-only doc-contract test**
- D-11: Rewrite all hidden-module calls. The reach is wider than the three guides API-04 names; SC2's test forces it:
  | File:line | Old | New |
  |---|---|---|
  | guides/how-threadline-works.md:221 | `Threadline.Investigation.row_history/4` | `Threadline.row_history/4` |
  | guides/how-threadline-works.md:223 | `Threadline.Investigation.actor_window/3` | `Threadline.actor_window/3` |
  | guides/code-walkthrough.md:368 | `Threadline.Investigation.incident_bundle/2` | `Threadline.incident_bundle/2` |
  | guides/audit-indexing.md:81 | `Threadline.Query.export_changes_query/1` | prose pointing at `Threadline.export_csv/2` / `Threadline.export_json/2` (no second allowlist entry, no new facade function) |
  | guides/audit-indexing.md:102 | `Threadline.Query.timeline/2` | `Threadline.timeline/2` |
  | guides/production-checklist.md:100,110 | `Threadline.Query.timeline/2` | `Threadline.timeline/2` |
  | guides/domain-reference.md:63,72,351,443 | `Threadline.Query.timeline/2` | `Threadline.timeline/2` |
  | examples/threadline_phoenix/priv/scripts/incident_replay.exs:117 | `Threadline.Query.history(...)` | `Threadline.history(...)` |

  Line numbers are from the 2026-10-03 scan, so the executor must re-grep. README.md and the example app README are already clean.
- D-12: Add a new dedicated test file (e.g. `test/threadline/facade_only_references_contract_test.exs`). It is a separate contract from `public_surface_contract_test.exs`'s ownership tags.
  - Scope: `guides/*.md`, `README.md`, `examples/threadline_phoenix/README.md`, example app `lib/**/*.{ex,heex}`, and example app `priv/scripts/*.exs`.
  - Excluded: `CHANGELOG.md` (historical), example app `test/**` (internal verification, e.g. `posts_correlation_path_test.exs` uses `validate_timeline_filters!`), `e2e/` artifacts, and `.planning/`.
  - Patterns: a backtick form `` `Threadline\.(Query|Investigation)\.[a-z_]\w*[!?]?/\d+` `` and a call form `Threadline\.(Query|Investigation)\.[a-z_]\w*[!?]?\s*\(`. The allowlist is exactly `timeline_query`. Requiring a lowercase function name excludes struct aliases such as `alias Threadline.Investigation.{IncidentBundle, ...}` in `audit_transaction_json.ex`.
  - Alias guard: a bare `alias Threadline.Query` or `alias Threadline.Investigation` (not a struct-group alias) in the scanned scope fails loudly with "extend the scanner", so aliases are never missed silently.
  - Self-test: a fixture string makes the regex non-vacuous.
- D-13: Mutation controls are recorded for both new guards:
  - re-adding a hidden call to a guide turns the D-12 test red;
  - re-adding `belongs_to :action` turns the SC3 `__schema__(:associations)` test red.

### Claude's Discretion
- Whether the hydrate helper stays inside `query.ex` or becomes a hidden submodule.
- The exact deprecation-warning mechanism and its message wording for D-10.
- The exact rewritten prose in `lib/threadline.ex` docs and `audit-indexing.md`.

### Deferred Ideas (OUT OF SCOPE)
- Removing the `preload: :action` compatibility path is earliest 2.0 (D-10).
- A public facade wrapper for a composable export query (`export_changes_query/1`) was not added. Revisit only if adopters ask; Phase 232's API-05 may hide it anyway.
- Full alias resolution in the doc-contract scanner is replaced for now by the fail-loud alias guard (D-12).

Out of scope (owned by later phases): consolidated `row_history/3`, deprecating retired function names, and hiding other internal helpers (Phase 232, API-05/API-08). Lookup return shapes belong to Phase 233, and the typespec/doc gate to Phase 234. Operator UI markup is parked until 1.0.0; only call sites forced by API-04/API-07 change.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| API-04 | `Threadline.Query`/`Threadline.Investigation` become `@moduledoc false`; `timeline_query/1` is the one documented escape hatch; three named guides call `Threadline.*`; `public_surface_contract_test.exs` pins the hidden set. | Verified exact `@hidden_modules` location (test file line ~6), verified current `groups_for_modules["Core API"]` membership (mix.exs ~line 628/634) that must be removed in the same change, verified ExDoc 0.40.1 + `skip_code_autolink_to` mechanism, verified all 12 `lib/threadline.ex` references and all 8 guide/example call sites by line number. |
| API-07 | `AuditTransaction` drops `belongs_to :action`; `AuditAction` drops `has_many :transactions`; exploration-layer hydrate helper preserves `.action` shape; `action_id` + FK untouched; new association-absence test. | Verified both schema files (exact line numbers 62 and 47), verified all 6 forced `:action` preload call sites, verified the 2 source-literal tests that assert the preload call text and will need updating, verified no `%Ecto.Association.NotLoaded{}` matching exists anywhere in the tree, confirmed `AuditTransaction.@type t` is already a bare `%__MODULE__{}` (no AuditAction.t() reference to remove). |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Three-layer rule:** capture layer (triggers, `AuditTransaction`, `AuditChange`) must not own action naming, UI grouping, or semantics-layer concerns; semantics layer (`AuditAction`, actor/intent/context) must not depend on capture internals. This phase's whole purpose (API-07) is enforcing this rule at the Ecto-association level — do not reintroduce `belongs_to`/`has_many` as a convenience.
- **Domain language:** use `AuditTransaction`, `AuditChange`, `AuditAction`, `AuditContext`, `ActorRef`, `Correlation` consistently; do not invent new terms for the hydrate helper's concepts.
- **Named verification entrypoints:** cite `mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix ci.all` — never ad-hoc `mix test` invocations in docs/CI references (ad-hoc `mix test <file>` is fine for local iteration, per the Build & Development Commands section).
- **Honest default tests:** do not silently exclude the new `facade_only_references_contract_test.exs` or the new association-absence test from `mix test`'s default run; no `test/test_helper.exs` exclusion without updating docs together.
- **`mix compile --warnings-as-errors`** must stay clean for `lib/`, `test/`, and the example app (this is also SC5, so CLAUDE.md and the phase success criteria agree).
- **GSD zero-human-verification default:** automate all verification for this phase (tests + `mix ci.all`); nothing here touches secrets, spend, push/publish, or scope, so no maintainer checkpoint is expected mid-phase.
- **Local gate gotchas to factor into plan verification steps:** never run `playwright` directly — use `mix verify.example_browser`; a red Dialyzer step in `mix ci.all` usually means a PLT cache miss (`mix dialyzer --plt`), not a real type error; the local test DB has a stale `public.threadline_capture_changes()` function that can mask CI failures — use schema-qualified checks when in doubt.

## Standard Stack

No new dependencies. This phase edits existing modules only (`ex_doc` 0.34→locked 0.40.1 already a dep, `ecto`/`ecto_sql` already deps). No installation step applies.

**Installation:** N/A — no new packages.

## Package Legitimacy Audit

Not applicable — this phase installs no external packages.

## Architecture Patterns

### System Architecture Diagram

```
Adopter code
     │
     ▼
Threadline (facade, public, documented)
     │  delegates to
     ▼
Threadline.Query / Threadline.Investigation  (@moduledoc false, hidden from docs)
     │                              │
     │ reads                       │ reads + composes
     ▼                              ▼
Threadline.Capture.AuditTransaction   Threadline.Semantics.AuditAction
  (no belongs_to :action)              (no has_many :transactions)
     │                                      ▲
     │  action_id : binary_id (FK unchanged)│
     └──────────────┐          ┌────────────┘
                     ▼          ▼
         Threadline.Query.<hydrate_helper>/2  (@doc false, hidden)
           - accepts AuditTransaction | [AuditTransaction] | [AuditChange with .transaction loaded]
           - dedupes non-nil action_ids
           - ONE `WHERE id IN ^ids` query against audit_actions
           - threads storage_opts/StorageSchema.repo_opts(opts)
           - fills transaction.action (nil when absent — was NotLoaded before)
```

Trace the forced call sites (SC4's "every existing assertion passes unchanged"):
`query.ex:109 preload_investigation_context` → `investigation.ex:134,154,167` (transaction_context/2, incident_bundle/2) → `operator_surface/live/timeline_live.ex:552` and `transaction_live.ex:22` (LiveView mount/update, markup untouched) → each currently does `repo.preload(x, [transaction: :action] | :action, storage_opts)`; each becomes a call into the new hydrate helper with the same opts threaded through.

### Recommended Project Structure

No new files beyond the two test files; no src folder restructuring.
```
lib/threadline/
├── threadline.ex                     # facade — moduledoc + ~12 doc-text rewrites (D-03)
├── query.ex                          # @moduledoc false (D-01/D-02); hydrate helper (D-08); preload shim (D-10)
├── investigation.ex                  # @moduledoc false (D-01/D-02); 3 call sites switch to helper (D-09)
├── capture/audit_transaction.ex      # drop belongs_to, add explicit action_id + virtual action field (D-05)
├── semantics/audit_action.ex         # drop has_many :transactions (D-06)
└── operator_surface/live/
    ├── timeline_live.ex              # :552 switches to helper (D-09)
    └── transaction_live.ex           # :22 switches to helper (D-09) — opts shape only, no markup change

test/threadline/
├── public_surface_contract_test.exs          # extend @hidden_modules (D-02); SC1 moduledoc-names-timeline_query test
├── facade_only_references_contract_test.exs  # NEW — D-12 scanner + alias guard + self-test
├── query_test.exs                             # update the literal-source assertion at :983 to the new call shape
├── operator_surface/live/timeline_live_test.exs  # update the literal-source assertion at :1204
└── <schema association test — new test, likely in capture/audit_transaction_test.exs or a dedicated file>
      # SC3: __schema__(:associations) returns [] on both sides; mutation control re-adding belongs_to/has_many turns it red

mix.exs
  docs():
    - skip_code_autolink_to: ["Threadline.Query.timeline_query/1"]  (D-01)
    - groups_for_modules["Core API"]: remove Threadline.Query and Threadline.Investigation
      (required — public_surface_contract_test.exs's "every visible compiled module belongs
      to exactly one of six groups" test asserts flattened groups == visible_modules(); a
      hidden module left in the group list fails that test)
```

### Pattern 1: Hiding a facade-delegate module from ExDoc while keeping it compiled and tested
**What:** `@moduledoc false` on the module; remove it from `mix.exs`'s `groups_for_modules`; keep all `@doc`/`@spec` on its functions (ExDoc simply never renders the module page, but a `@doc false` function inside stays fully hidden too — distinct from the module-level flag).
**When to use:** When a module must stay a normal, testable, directly-callable Elixir module (internal call sites still do `Threadline.Query.timeline/2` etc.) but must disappear from the public docs tree and from adopter-facing guidance.
**Example (pattern already in this codebase):**
```elixir
# Source: lib/threadline/critic_trust/measure.ex:1-2 — existing @moduledoc false precedent in this repo
defmodule Threadline.CriticTrust.Measure do
  @moduledoc false
  ...
```

### Pattern 2: `@doc false` internal hydrate helper replacing a direct cross-schema preload
**What:** A single hidden function that walks from whatever shape callers have (`AuditTransaction`, `[AuditTransaction]`, or `[AuditChange]` with `.transaction` preloaded) down to a deduped list of `action_id`s, runs one query, and splices `.action` back onto each struct — never touching the Ecto association macros.
**When to use:** Any time two schemas must stop declaring a direct `belongs_to`/`has_many` to each other (cross-layer boundary) but callers must still see the same joined shape.
**Example (shape, not literal code — D-08's contract, consistent with the existing `storage_opts/2` helper at `lib/threadline/query.ex:685`):**
```elixir
# Source: inferred pattern from lib/threadline/query.ex:685 (storage_opts/2) + :106-110 (preload_investigation_context/3)
@doc false
def hydrate_action(transactions_or_changes, repo, opts \\ [])

defp hydrate_action_ids(items) do
  items
  |> List.wrap()
  |> Enum.map(&extract_transaction/1)
  |> Enum.map(& &1.action_id)
  |> Enum.reject(&is_nil/1)
  |> Enum.uniq()
end

defp fetch_actions(ids, repo, opts) do
  AuditAction
  |> where([a], a.id in ^ids)
  |> repo.all(storage_opts([], opts))
  |> Map.new(&{&1.id, &1})
end
```

### Pattern 3: Deprecated public option — pull the key out, warn once, delegate the rest
**What:** `:preload` lists/atoms containing `:action` or `transaction: :action` are filtered out before the real `repo.preload/3` call; the hydrate helper fills `.action` separately; a single `IO.warn/2` (or `Logger.warning/2`) fires naming the replacement.
**When to use:** D-10's public-compatibility requirement — any public keyword option whose value referenced the now-removed association.
**Example (shape, matching the two `:preload` validation sites at `query.ex:128-137` and `query.ex:613-622`):**
```elixir
# Source: inferred from existing validation shape at lib/threadline/query.ex:128-137
case Keyword.get(opts, :preload) do
  preloads when preloads in [nil, []] -> ...
  preloads ->
    {action_requested?, remaining} = extract_action_preload(preloads)
    if action_requested?, do: IO.warn("preload: :action is deprecated; .action is hydrated automatically")
    transaction = repo.preload(transaction, remaining, storage_opts([], opts))
    if action_requested?, do: hydrate_action(transaction, repo, opts), else: transaction
end
```

### Anti-Patterns to Avoid
- **Removing the association but leaving `@type t :: %__MODULE__{action: AuditAction.t()}`:** `AuditTransaction`'s type is already a bare `%__MODULE__{}` — verified at `lib/threadline/capture/audit_transaction.ex:45` — so there is nothing to strip here, but if the executor adds a richer type later, it must not reintroduce the cross-module type reference D-05 forbids.
- **Touching LiveView markup (`.heex`) while fixing the `:action` preload in `timeline_live.ex`/`transaction_live.ex`:** D-09 is explicit — these are forced call sites for the opts/preload shape only; operator-surface markup is parked until 1.0.0 per the Out-of-Scope table.
- **Hiding `Threadline.Query.Cursors`/`.FilterParams`/`.Scope`/`.TimelinePage`/`.ActorHistoryPage` or `Threadline.Investigation.IncidentBundle`/`.IncidentChange`/`.LinkedChange`/`.LinkedTransaction` along with their parent namespace modules:** these are separate, already-visible, already-grouped (`"Data Types"`) modules in `mix.exs`'s `groups_for_modules` and must stay untouched — verified by reading the current `groups_for_modules` list.
- **Forgetting the two source-literal tests:** `query_test.exs:983` and `timeline_live_test.exs:1204` assert exact preload-call substrings and will fail on an unrelated, correct refactor if not updated in the same commit.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Documenting-but-hiding a function in a hidden module | A custom ExDoc plugin or post-processing step on generated HTML | `skip_code_autolink_to` in `mix.exs` `docs()` (ExDoc 0.40.1 built-in, confirmed at `deps/ex_doc/lib/ex_doc.ex:156`) | It is the documented, maintained mechanism for exactly this case; a custom step would break on every ExDoc upgrade |
| Batch-loading `.action` across many transactions | N+1 per-transaction lookup queries, or re-introducing `repo.preload` via the association | One `WHERE id IN ^ids` query in the hidden hydrate helper, deduping first | `repo.preload` with an association requires the association to exist; dedupe + single IN-query is the standard batched-lookup pattern Ecto itself uses internally for preloads |
| Scanning guides/README/example app for stale module references | A one-off grep script run manually before each release | A committed ExUnit test (`facade_only_references_contract_test.exs`, D-12) with regex patterns, an allowlist, and an alias guard | Matches this repo's established "doc-contract test" convention (31 existing `*_doc_contract_test.exs` files) — a manual grep has no mutation control and silently rots |

**Key insight:** Every piece of this phase already has a proven in-repo pattern (hidden critic-trust modules, existing doc-contract tests, existing `storage_opts` threading, existing `:preload` validation `case` shape). The risk is not "what library to use" — it's missing one of the 6+8+2 enumerated call sites or the 2 literal-source test assertions.

## Common Pitfalls

### Pitfall 1: Hiding the module without unlisting it from `groups_for_modules`
**What goes wrong:** `mix docs` either warns/errors (depending on ExDoc version behavior for a hidden-but-grouped module) or, more reliably, the existing test `public_surface_contract_test.exs` ("every visible compiled module belongs to exactly one of six groups", asserting `MapSet.new(flattened) == visible_modules()`) goes red, because a hidden module should not be in `visible_modules()` but is still present in the flattened group list.
**Why it happens:** `@moduledoc false` and `groups_for_modules` are two independent configuration surfaces; nothing forces them to stay in sync automatically.
**How to avoid:** Remove `Threadline.Query` and `Threadline.Investigation` from `groups_for_modules["Core API"]` in the exact same commit that adds `@moduledoc false` to both.
**Warning signs:** `mix test test/threadline/public_surface_contract_test.exs` fails on the group-membership test, or `mix docs` emits an ExDoc warning about an ungrouped/hidden-but-grouped module.

### Pitfall 2: Literal-source-text tests silently drifting
**What goes wrong:** `query_test.exs:983` and `timeline_live_test.exs:1204` assert `File.read!/1` output contains an exact substring of the preload call. Changing the call to use the hydrate helper (functionally correct, SC4-satisfying) breaks these two tests even though nothing is semantically wrong.
**Why it happens:** These are "mutation-control"-style tests that pin the literal implementation text, not just behavior — a pattern this repo uses elsewhere (e.g. the D-13 mutation controls specified for this very phase).
**How to avoid:** Grep for the exact preload substrings (`repo.preload(changes, [transaction: :action]`, `repo.preload(entries, [transaction: :action]`) across `test/` before editing `query.ex`/`timeline_live.ex`, and update each matching assertion in the same wave.
**Warning signs:** `mix test` shows unrelated-looking failures in `query_test.exs` or `timeline_live_test.exs` after an otherwise-clean refactor.

### Pitfall 3: SC1's "links" wording taken literally
**What goes wrong:** Attempting to make `Threadline.Query.timeline_query/1` a clickable ExDoc anchor from the `Threadline` moduledoc. ExDoc 0.40.1 cannot render a link into a `@moduledoc false` module — it emits "hidden or private" warnings, and `mix docs --warnings-as-errors` (invoked at `mix.exs:336` inside `verify.release`, and `mix ci.all`'s docs step) fails.
**Why it happens:** SC1 reads "linked" but the only mechanism available is naming the function in inline code via `skip_code_autolink_to`.
**How to avoid:** Confirmed by D-01 — treat SC1's test as asserting the moduledoc *text contains* `Threadline.Query.timeline_query/1`, verified via `Code.fetch_docs(Threadline)`, not an `<a href>` check.
**Warning signs:** `mix docs --warnings-as-errors` fails with an autolink warning naming `timeline_query/1`.

### Pitfall 4: Forgetting the `preload: :action` nested-key raise path
**What goes wrong:** D-10 requires `[action: :x]` (a nested key under the now-association-less `:action`) to raise `ArgumentError`, because `AuditAction` has no associations to traverse. If the deprecation shim only strips a bare `:action`/`transaction: :action` and passes everything else straight to `repo.preload`, a nested form would reach Ecto's preloader and produce a generic/unrelated Ecto error instead of the project's own `ArgumentError`.
**Why it happens:** The shim must special-case "is this exactly `:action`/`transaction: :action`" vs. "is this `:action` with something nested under it" — easy to miss the second branch.
**How to avoid:** Write the nested-raise test first (red), then implement the branch that explicitly detects a nested-under-`:action` shape and raises before calling `repo.preload`.
**Warning signs:** A test for `preload: [action: :something]` raises an Ecto association error instead of `ArgumentError` with a message naming the problem.

### Pitfall 5: CHANGELOG `NotLoaded` → `nil` behavior note getting lost
**What goes wrong:** D-07 requires a CHANGELOG entry noting that un-hydrated `transaction.action` is now `nil` instead of `%Ecto.Association.NotLoaded{}`. Because no existing call site matches on `NotLoaded` (verified — zero hits in `lib/`, `test/`, `examples/`), this is easy to treat as a non-issue and skip the CHANGELOG entry, but adopters outside this repo may rely on the old sentinel.
**Why it happens:** The absence of an in-repo match makes the change feel purely internal.
**How to avoid:** Add the breaking-change-style CHANGELOG bullet regardless (under "Unreleased — highlights", breaking changes before feature tour, per this repo's CHANGELOG header convention). This feeds REL-02 in Phase 237, which cross-checks the final CHANGELOG against `git log --grep="BREAKING CHANGE"`.
**Warning signs:** Phase 237's CHANGELOG cross-check finds a breaking change from this milestone with no corresponding entry.

## Code Examples

### Existing `@moduledoc false` precedent in this repo
```elixir
# Source: lib/threadline/critic_trust/measure.ex:1-2
defmodule Threadline.CriticTrust.Measure do
  @moduledoc false
```

### Existing storage-opts threading pattern the hydrate helper must reuse
```elixir
# Source: lib/threadline/query.ex:685-694 (storage_opts/2, verified live)
def storage_opts(filters \\ [], opts \\ []) do
  StorageSchema.repo_opts(storage_schema_opts(filters, opts))
end

defp storage_schema_opts(_filters, opts) do
  case Keyword.get(opts, :storage_schema) do
    nil -> []
    storage_schema -> [storage_schema: storage_schema]
  end
end
```

### Existing `:preload` validation shape to extend for the D-10 shim
```elixir
# Source: lib/threadline/query.ex:128-138 (verified live, audit_transaction/2)
case Keyword.get(opts, :preload) do
  preloads when preloads in [nil, []] ->
    transaction

  preloads when is_list(preloads) or is_atom(preloads) ->
    repo.preload(transaction, preloads, storage_opts([], opts))

  other ->
    raise ArgumentError,
          ":preload must be nil, [], an atom, or a list, got: #{inspect(other)}"
end
```

### Existing doc-contract test file shape to follow for the new D-12 scanner
```elixir
# Source: test/threadline/audit_indexing_doc_contract_test.exs:1-9 (verified live)
defmodule Threadline.AuditIndexingDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `AuditTransaction belongs_to :action` / `AuditAction has_many :transactions` (direct Ecto association across capture/semantics layers) | Decoupled schemas + hidden hydrate helper (`Option C`, per `.planning/STATE.md` maintainer decision 2026-10-02 item 3) | This phase (231), landing with v1.45/1.0.0 | Capture no longer depends on semantics at compile time (API-07); `.action` un-hydrated value changes from `%Ecto.Association.NotLoaded{}` to `nil` (breaking, CHANGELOG-tracked) |
| `Threadline.Query`/`Threadline.Investigation` as documented public modules | `@moduledoc false`, reachable only through the `Threadline` facade (except the one escape hatch) | This phase (231) | Adopters see exactly one documented read API (API-04); internal call sites and tests are unaffected since the modules stay compiled and callable |

**Deprecated/outdated:**
- Direct `Threadline.Query.*`/`Threadline.Investigation.*` references in guides/README/examples: superseded by `Threadline.*` facade calls everywhere except the one named escape hatch (`timeline_query/1`).
- `preload: :action` / `preload: [transaction: :action]` as a public option value: deprecated in this phase (D-10), kept functional with one warning through the 1.x line, removal no earlier than 2.0.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The deprecation-warning mechanism (`IO.warn`/`Logger.warning`) and exact message wording is unconstrained by CONTEXT.md beyond "consistent with Phase 232's tone" — Phase 232 has not yet been planned/executed, so there is no existing precedent in this repo to match against yet. | Common Pitfalls / Pattern 3 | If Phase 232 later establishes a different warning convention, this phase's shim may need a one-line wording tweak for consistency — low risk, cosmetic only. |
| A2 | The new `__schema__(:associations)` test (SC3) is assumed to belong in a new or existing schema-focused test file (e.g. `test/threadline/capture/audit_transaction_test.exs` or similar) rather than in `public_surface_contract_test.exs`; no existing test file for this assertion was found during research. | Recommended Project Structure | If the planner places it elsewhere, no functional risk — purely an organizational choice left to Claude's discretion per CONTEXT.md's own framing of similar choices. |

**If this table is empty:** N/A — two low-risk organizational assumptions remain; neither affects correctness of SC1–SC5.

## Open Questions (RESOLVED)

1. **Exact name and location of the hydrate helper function**
   - What we know: D-08 specifies its contract (accepts transaction/list/changes-with-transaction, dedupes, one `IN` query, threads storage opts) and leaves "stays inside `query.ex` or becomes a hidden submodule" to Claude's discretion.
   - What's unclear: The literal function name/arity isn't fixed by CONTEXT.md.
   - Recommendation: Planner should name it something like `hydrate_action/2` or `hydrate_actions/2` inside `Threadline.Query`, `@doc false`, and have `preload_investigation_context/3` (currently at `query.ex:106-110`) call it, since that function already has the exact `[transaction: :action]` shape and is the natural first caller to convert.
   - RESOLVED: `Threadline.Query.hydrate_actions/3` (hidden, inside `query.ex`), called first from `preload_investigation_context/3` — see 231-01-PLAN.md Task 1.

## Environment Availability

Skipped — this phase has no external tool/service dependencies beyond the already-installed Elixir/Erlang/PostgreSQL toolchain and `ex_doc` dependency, all confirmed present and pinned (`.tool-versions`: elixir 1.17.3-otp-27, erlang 27.3.4.15; `mix.lock`: ex_doc 0.40.1).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (ex_doc 0.40.1 for docs generation is a build-time dep, not a test framework) |
| Config file | `mix.exs` (`project/0`, `docs/0`), `test/test_helper.exs` |
| Quick run command | `mix test test/threadline/public_surface_contract_test.exs test/threadline/query_test.exs test/threadline/investigation_test.exs test/threadline/operator_surface/live/timeline_live_test.exs` |
| Full suite command | `mix ci.all` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| API-04 (SC1) | `Threadline.Query`/`Threadline.Investigation` hidden; moduledoc names `timeline_query/1` | unit | `mix test test/threadline/public_surface_contract_test.exs` | ✅ (extend `@hidden_modules` + add moduledoc-text assertion) |
| API-04 (SC2) | Guides/README/example app never call hidden modules except `timeline_query/1` | unit | `mix test test/threadline/facade_only_references_contract_test.exs` | ❌ Wave — new file (D-12) |
| API-07 (SC3) | Neither schema declares an association to the other | unit | `mix test <new association test file — see Open Question>` | ❌ Wave — new test (A2) |
| API-07 (SC4) | Every existing `.action` assertion passes unchanged through the hydrate helper | unit/integration | `mix test test/threadline/investigation_test.exs test/threadline/query_test.exs test/threadline/storage_schema_integration_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/live/transaction_live_test.exs` | ✅ (existing tests; 2 need literal-source updates per Pitfall 2) |
| API-04/API-07 (SC5) | `mix compile --warnings-as-errors` clean; `mix ci.all` green | smoke | `mix compile --warnings-as-errors && mix ci.all` | ✅ existing alias |

### Sampling Rate
- **Per task commit:** targeted `mix test` on the files touched (schema files, query.ex, investigation.ex, the two LiveViews, the two source-literal tests, the new facade-only contract test).
- **Per wave merge:** `mix compile --warnings-as-errors` (lib/, test/, example app) + `mix test` (full, no partitioning needed at this scale) + `mix credo --strict` if adopted (confirm via `mix help credo` locally; CLAUDE.md marks it conditional).
- **Phase gate:** `mix ci.all` green before `/gsd-verify-work`, per CLAUDE.md's canonical verification entrypoints.

### Wave 0 Gaps
- [ ] `test/threadline/facade_only_references_contract_test.exs` — covers SC2/API-04, D-12
- [ ] A new association-absence test (file TBD by planner, see Open Question 1) — covers SC3/API-07
- [ ] No fixture/conftest-equivalent gaps — ExUnit has no shared-fixture file analogous to `conftest.py`; existing `test/support/` helpers are sufficient.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A — no auth logic touched |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A — this phase does not change who can call what, only what is documented/associated |
| V5 Input Validation | yes | The `:preload` deprecation shim (D-10) is new input-validation surface: it must raise `ArgumentError` on the nested-`:action` shape exactly as the existing `case` pattern at `query.ex:128-138`/`613-622` does for other malformed `:preload` values |
| V6 Cryptography | no | N/A |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed `:preload` option reaching `repo.preload/3` and raising an unhandled/leaky Ecto error instead of a clean `ArgumentError` | Denial of Service / information disclosure (low severity — error message detail, not data exposure) | Validate the shape explicitly before delegating to `repo.preload/3`, matching the existing fail-closed pattern already used for other `:preload` shapes in this file |

**Note:** This is a low-risk, internal-API-surface phase with no new network input, no new auth/authz logic, and no new cryptography. The ASVS section is included per the standing project default (`security_enforcement` not disabled) but the applicable surface is narrow — one input-validation branch.

## Sources

### Primary (HIGH confidence — all read live in this session)
- `lib/threadline/capture/audit_transaction.ex` — current `belongs_to :action` (line 62), `@type t` (line 45)
- `lib/threadline/semantics/audit_action.ex` — current `has_many :transactions` (line 47)
- `lib/threadline/query.ex` — `preload_investigation_context/3` (106-110), `audit_transaction/2` preload validation (117-139), `audit_changes_for_transaction/2` preload validation (590-622), `storage_opts/2` (685-694), `timeline_query/1` (241)
- `lib/threadline/investigation.ex` — `transaction_context/2` (130-143), `incident_bundle/2` (149-180), all three `:action` preload call sites (134, 154, 167)
- `lib/threadline/operator_surface/live/timeline_live.ex` — `preload_visible_context/3` (549-553)
- `lib/threadline/operator_surface/live/transaction_live.ex` — `mount/3` (17-28)
- `lib/threadline.ex` — moduledoc (1-7), 12 `Threadline.Query.*` doc references
- `test/threadline/public_surface_contract_test.exs` — `@hidden_modules` (6-13), `docs_visibility/1` (629), module-grouping tests (201-310)
- `test/threadline/query_test.exs:979-986` — literal-source preload assertion
- `test/threadline/operator_surface/live/timeline_live_test.exs:1197-1205` — literal-source preload assertion
- `test/threadline/audit_indexing_doc_contract_test.exs` — existing doc-contract test template
- `mix.exs` — `docs/0` (559-660), `groups_for_modules["Core API"]` membership of `Threadline.Query`/`Threadline.Investigation`, `verify_release/1` (`mix.exs:336` area, `MIX_ENV=dev mix docs --warnings-as-errors`)
- `mix.lock` — `ex_doc` pinned at `0.40.1`
- `deps/ex_doc/lib/ex_doc.ex:156` — `:skip_code_autolink_to` documented mechanism
- `CHANGELOG.md` — header convention (breaking changes before feature tour, "Unreleased — highlights" heading)
- `guides/how-threadline-works.md:221,223`, `guides/code-walkthrough.md:368`, `guides/audit-indexing.md:81,102`, `guides/production-checklist.md:100,110`, `guides/domain-reference.md:63,72,351,443`, `examples/threadline_phoenix/priv/scripts/incident_replay.exs:117` — all `Threadline.Query.*`/`Threadline.Investigation.*` call sites, line numbers confirmed via live grep
- `.planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-CONTEXT.md` — locked decisions D-01..D-13
- `.planning/REQUIREMENTS.md` — API-04, API-07 definitions and maintainer decisions
- `CLAUDE.md` — three-layer architecture rule, CI/verification entrypoints

### Secondary (MEDIUM confidence)
- None used — this phase required no external web research; it is a pure in-repo refactor.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages, confirmed via `mix.lock`/`.tool-versions`
- Architecture: HIGH — every call site and schema association verified by reading the live source this session
- Pitfalls: HIGH — the two literal-source test gotchas and the `groups_for_modules` gotcha were discovered by direct inspection, not inferred

**Research date:** 2026-10-03
**Valid until:** Stable for the remainder of this milestone (v1.45) — re-verify line numbers only if other phases (232+) land commits touching `query.ex`, `investigation.ex`, or `lib/threadline.ex` before Phase 231 executes.
