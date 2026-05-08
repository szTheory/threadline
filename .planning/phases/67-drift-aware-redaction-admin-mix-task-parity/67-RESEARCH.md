# Phase 67: Drift-Aware Redaction Admin & Mix Task Parity - Research

**Researched:** 2026-05-07  
**Domain:** Drift-aware redaction reconciliation across configured trigger-capture policy, deployed PostgreSQL trigger functions, an operator-surface LiveView, and a parity Mix task. [VERIFIED: .planning/ROADMAP.md, .planning/REQUIREMENTS.md, lib/threadline/capture/redaction_policy.ex, lib/threadline/capture/trigger_sql.ex, lib/mix/tasks/threadline.gen.triggers.ex]  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

Copied verbatim from `.planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md`. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md]

### Implementation Decisions

### Surface model

- **D-37: Drift-first scanner, not a wide compare matrix.** The LiveView should open with a scan-first summary and then show per-table details. Do **not** make the primary UI a horizontally wide side-by-side table of configured vs deployed sets for every table; that is noisier, less idiomatic for the current operator surface, weaker on narrow widths, and makes drift harder to spot at a glance.
- **D-38: Per-table exactness still matters.** Each table's detail view must still show the exact configured and deployed redaction sets, separated by `exclude` and `mask`, with placeholder information when relevant. The summary can be compact; the detailed table view must not collapse into prose-only "smart diffs."
- **D-39: No URL/state complexity for disclosure.** Expansion/collapse is local UI state only. No deep-linkable expansion params, no extra URL contract, no top-nav redesign. This page is for operational confirmation, not collaboration or saved views.

### Layout

- **D-40: Use explicit state sections with drift-first ordering.** The page should be grouped into visible sections in this order:
  1. `Drift detected`
  2. `Could not introspect`
  3. `Config matches deployed`
  Tables are alphabetical within each section. This preserves fast incident scanning while staying predictable enough for repeat use and screenshots.
- **D-41: Section headers carry counts.** Each section header should include its count so operators can assess overall state before reading rows. Empty sections may be hidden in the LiveView if the page still keeps the summary counts visible; the Mix task should stay compact and not print empty verbose blocks by default.
- **D-42: Matching tables stay quiet.** Matching tables belong after the actionable sections and should render with a lower-noise presentation than drift/failure rows. The boring case is visible, but it does not dominate the screen.

### State semantics

- **D-43: Keep the top-level status taxonomy small.** The per-table top-level states are:
  - `config matches deployed`
  - `drift detected`
  - `could not introspect`
  Do **not** promote `config-only`, `deployed-only`, `placeholder mismatch`, or similar directional variants into top-level statuses.
- **D-44: Direction lives in reason/detail, not in the badge.** Under `drift detected`, the UI/task may explain whether the mismatch is `mask_only_in_config`, `exclude_only_in_deployed`, placeholder mismatch, or another conservative diff reason. These are detail/hint fields, not top-level operator states.
- **D-45: Parse uncertainty is never a soft pass.** `could not introspect` is operationally distinct from both `matches` and `drift`. It must never be styled or worded in a way that implies safety. The per-table hint should instruct the operator to rerun `mix threadline.gen.triggers` and not assume the deployed trigger is aligned.
- **D-46: Human-facing copy should be plain and operator-safe.** Recommended badge/state copy:
  - `Config matches deployed`
  - `Drift detected`
  - `Could not introspect`
  Recommended hint copy:
  - Match: `Configured redaction matches deployed trigger redaction.`
  - Drift: `Configured redaction does not match deployed trigger SQL. Rerun \`mix threadline.gen.triggers\` and apply the migration.`
  - Introspection failure: `Could not inspect deployed trigger SQL. Rerun \`mix threadline.gen.triggers\`; do not assume capture is aligned.`

### Mix-task parity

- **D-47: UI and Mix must match semantically, not visually.** The Mix task should expose the same facts, same table inventory, same state taxonomy, same rerun hint, and same conservative failure behavior, but it should remain terminal-native rather than trying to textually clone the LiveView.
- **D-48: Default Mix output is hybrid.** `mix threadline.policy.show` should print:
  1. One summary line with counts
  2. One aligned table for all audited tables
  3. Additional detail blocks only for `drift detected` and `could not introspect`
  4. `--json` as the full stable machine-readable shape
  This is the best fit for capture-only adopters and mirrors Phase 66's parity posture.
- **D-49: Default human table columns are compact and stable.** Recommended default columns:
  - `TABLE`
  - `STATUS`
  - `CONFIG`
  - `DEPLOYED`
  - `HINT`
  `CONFIG` and `DEPLOYED` should use a compact terminal DSL such as `exclude=[password_hash] mask=[email,ssn]`.
- **D-50: Viewer semantics, not CI-gate semantics.** Like `mix threadline.health.coverage`, this task is diagnostic. Drift should not exit non-zero by itself. Reserve non-zero exits for invalid input or runtime failure.

### JSON contract

- **D-51: Stable JSON is a machine contract, not a serialized UI.** The `--json` output should be a top-level object with summary fields plus a `tables` array. Do **not** encode UI section layout directly into the JSON.
- **D-52: Use stable enum-like JSON status keys.** Recommended JSON status values:
  - `config_matches_deployed`
  - `drift_detected`
  - `could_not_introspect`
- **D-53: Preserve full structured detail in JSON.** Each table object should carry:
  - `table`
  - `status`
  - `configured` with `exclude`, `mask`, and `mask_placeholder`
  - `deployed` with `exclude`, `mask`, and `mask_placeholder` when available
  - `diff` fields such as `exclude_only_in_config`, `mask_only_in_deployed`, and `placeholder_mismatch`
  - `warning` and/or `hint`
  The planner may refine field names, but the shape must stay jq-friendly and additive.

### UX / DX guardrails

- **D-54: Never render sample values anywhere.** Not in the LiveView, not in the Mix task, not in JSON.
- **D-55: Keep `exclude` and `mask` visibly distinct.** They have different semantics in `Threadline.Capture.TriggerSQL` and must never be visually merged into a single "redacted columns" bucket.
- **D-56: Do not over-summarize diffs.** Any concise row-level summary must still allow the operator to inspect the exact configured vs deployed sets without guesswork.
- **D-57: Tests should lock semantics, not layout accidents.** Downstream doc-contract and integration tests should pin:
  - route literals
  - state literals
  - section ordering
  - alphabetical ordering within sections
  - no-sample-values invariants
  - JSON keys/status enums
  - UI/Mix parity on facts and state naming

### Decision-making preference for this phase

- **D-58: Bias toward researched defaults over repeated user arbitration.** For this phase, downstream agents should do the research, compare viable options, and present or implement the strongest coherent recommendation by default. Only surface decisions back to the user when they are unusually consequential, irreversible, or likely to affect project philosophy beyond the phase boundary.

### the agent's Discretion

- Exact CSS class names and visual styling inside the existing `.threadline-ui` namespace.
- Whether the page uses `<details>`/`<summary>` or a custom LiveView disclosure widget, as long as it stays simple and local-state-only.
- Exact compact DSL formatting for `CONFIG` and `DEPLOYED` cells in the Mix task.
- Exact naming of internal diff-reason atoms/struct fields, as long as the user-facing status taxonomy above remains fixed.

### Deferred Ideas

- Deep-linkable expansion state or saved filtered redaction views.
- Additional top-level states beyond the three locked here unless a future phase introduces materially new uncertainty classes.
- Overbuilt alphabetical index/jump-link UX unless real adopters prove scale pain with large audited-table inventories.
- Any runtime editing of policy from the UI — explicitly out of scope for v1.18.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REDN-03 | Read-only redaction admin LiveView renders `config :threadline, :trigger_capture`, re-validates through `Threadline.Capture.RedactionPolicy.validate!/1`, and shows only column names / placeholder metadata. [VERIFIED: .planning/REQUIREMENTS.md, lib/threadline/capture/redaction_policy.ex] | Shared `Threadline.Capture.RedactionReconciler` report with normalized `configured` policies and no value-level fields; LiveView becomes a pure presenter over that report. [VERIFIED: lib/threadline/capture/redaction_policy.ex, lib/mix/tasks/threadline.gen.triggers.ex] |
| REDN-04 | Drift detection compares configured redaction with deployed trigger SQL from `pg_proc.prosrc`; parse failures must warn and never pass silently. [VERIFIED: .planning/REQUIREMENTS.md] | Primary query joins `pg_trigger.tgfoid` to `pg_proc.oid`, parses known `TriggerSQL` anchors conservatively, and maps ambiguity to `could_not_introspect` with the rerun hint. [CITED: https://www.postgresql.org/docs/current/catalog-pg-trigger.html] [CITED: https://www.postgresql.org/docs/current/catalog-pg-proc.html] [VERIFIED: lib/threadline/capture/trigger_sql.ex] |
| REDN-05 | Parity `mix threadline.policy.show` plus doc-contract tests pinning route, output literals, badge states, and no-sample-values behavior. [VERIFIED: .planning/REQUIREMENTS.md] | Mix task and LiveView both consume the same reconciler report; doc-contract and parity tests follow the existing Phase 66 coverage pattern. [VERIFIED: lib/mix/tasks/threadline.health.coverage.ex, test/threadline/operator_surface/coverage_doc_contract_test.exs, test/threadline/operator_surface/coverage_mix_test.exs] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Phase 67 lives at the exploration/operations layer and may read capture metadata, but it must not move UI concerns into trigger-generation code. [VERIFIED: CLAUDE.md]
- Optional Phoenix deps remain optional, so any shared reconciliation logic must be pure Elixir and live outside `Threadline.OperatorSurface.*`. [VERIFIED: CLAUDE.md, mix.exs]
- Mix parity is a standing repo convention for operator-surface screens, so the LiveView and `mix threadline.policy.show` must share facts and status semantics. [VERIFIED: .planning/ROADMAP.md, lib/mix/tasks/threadline.health.coverage.ex, guides/operator-surface.md]
- Public docs are enforced by doc-contract tests, and canonical verification entrypoints remain `mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix verify.compile_no_optional`, and `mix ci.all`. [VERIFIED: CLAUDE.md, mix.exs, .github/workflows/ci.yml]
- The operator surface stays read-only; policy edits continue to happen in config plus `mix threadline.gen.triggers` and migration application. [VERIFIED: .planning/ROADMAP.md, .planning/REQUIREMENTS.md, .planning/PROJECT.md]

## Summary

Phase 67 should be built around one new shared, pure-Elixir reconciliation core that both the LiveView and `mix threadline.policy.show` consume. The current codebase already has the necessary raw ingredients: `Threadline.Capture.RedactionPolicy.validate!/1` defines the config vocabulary and placeholder rules, `Mix.Tasks.Threadline.Gen.Triggers` defines how `config :threadline, :trigger_capture` is loaded and normalized today, and `Threadline.Capture.TriggerSQL` emits a highly regular PL/pgSQL shape for `exclude`, `mask`, and `mask_placeholder`. [VERIFIED: lib/threadline/capture/redaction_policy.ex, lib/mix/tasks/threadline.gen.triggers.ex, lib/threadline/capture/trigger_sql.ex]

The safest implementation is not a generic PL/pgSQL parser. It is a fail-closed parser for the exact SQL anchors Threadline emits today, using `pg_trigger.tgfoid -> pg_proc.oid -> pg_proc.prosrc` to inspect the deployed trigger function body. PostgreSQL documents that `pg_trigger.tgfoid` identifies the function a trigger calls, and that `pg_proc.prosrc` is language-specific source text whose meaning depends on the function language. For Threadline’s generated `LANGUAGE plpgsql` functions, that is a good fit for conservative body parsing; for anything outside the known Threadline shape, the correct behavior is `Could not introspect`, not a guessed pass. [CITED: https://www.postgresql.org/docs/current/catalog-pg-trigger.html] [CITED: https://www.postgresql.org/docs/current/catalog-pg-proc.html] [VERIFIED: lib/threadline/capture/trigger_sql.ex]

Existing Phase 66 artifacts provide the delivery pattern: a shared report model, a terminal-native Mix viewer with `--json`, a gated LiveView route under the existing operator surface, and doc-contract tests that pin route literals, output literals, and parity semantics. Phase 67 should mirror that structure, but it should not extend the every-page header badge unless a later phase explicitly scopes that work; the locked scope for this phase is the redaction admin page and parity Mix task. [VERIFIED: .planning/phases/66-coverage-dashboard-mix-task-parity/66-RESEARCH.md, lib/threadline/operator_surface/router.ex, lib/threadline/operator_surface/live/coverage_live.ex, lib/threadline/operator_surface/components/surface_header.ex]

**Primary recommendation:** extract config normalization out of `Mix.Tasks.Threadline.Gen.Triggers` into a shared capture-policy module, build a `Threadline.Capture.RedactionReconciler` report over `pg_proc.prosrc`, and make both the LiveView and `mix threadline.policy.show` pure presenters over that report. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex, lib/threadline/capture/trigger_sql.ex, lib/mix/tasks/threadline.health.coverage.ex]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Load and normalize `config :threadline, :trigger_capture` | API / Backend | — | The policy vocabulary already lives in capture-layer modules and Mix trigger generation; extracting it keeps one source of truth for config semantics. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex, lib/threadline/capture/redaction_policy.ex] |
| Inspect deployed trigger function bodies via catalog query | Database / Storage | API / Backend | The data comes from PostgreSQL catalogs through `Ecto.Adapters.SQL`; the app layer should only interpret the returned rows. [CITED: https://www.postgresql.org/docs/current/catalog-pg-trigger.html] [CITED: https://www.postgresql.org/docs/current/catalog-pg-proc.html] [VERIFIED: lib/threadline/health.ex] |
| Reconcile configured vs deployed policy into statuses and diffs | API / Backend | — | This is shared domain logic that must be Phoenix-free so Mix and LiveView stay in parity and `mix verify.compile_no_optional` stays green. [VERIFIED: mix.exs, lib/mix/tasks/threadline.health.coverage.ex, lib/threadline/operator_surface/router.ex] |
| Render operator page sections and disclosure UI | Frontend Server (SSR LiveView) | — | The operator surface already renders read-only LiveViews under the router macro and is the right place for section ordering and local disclosure state. [VERIFIED: lib/threadline/operator_surface/router.ex, lib/threadline/operator_surface/live/coverage_live.ex] |
| Render terminal table and JSON output | API / Backend | — | Mix tasks in this repo already own terminal formatting and stable JSON contracts without Phoenix dependencies. [VERIFIED: lib/mix/tasks/threadline.health.coverage.ex] |
| Lock literals, parity, and no-sample-values invariants | Test infrastructure | — | Existing doc-contract and Mix/LV integration suites are the repo-standard way to protect UI/Mix parity. [VERIFIED: test/threadline/operator_surface/coverage_doc_contract_test.exs, test/threadline/operator_surface/coverage_mix_test.exs, test/threadline/operator_surface/live/coverage_live_test.exs] |

## Standard Stack

### Core

| Library / Module | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Elixir | `~> 1.15` in project; local `1.19.5` available. [VERIFIED: mix.exs] [VERIFIED: local env `elixir -e 'IO.puts(System.version())'`] | Implementation language for the shared reconciler, Mix task, and tests. | Matches repo baseline and keeps the new core in the same language/runtime as existing health and trigger tasks. [VERIFIED: mix.exs] |
| `Ecto.Adapters.SQL` | `~> 3.10`. [VERIFIED: mix.exs] | Parameterized catalog query against `pg_trigger`, `pg_proc`, and related tables. | Already used by `Threadline.Health.trigger_coverage/1`; avoids introducing new DB access patterns. [VERIFIED: lib/threadline/health.ex] |
| `Threadline.Capture.RedactionPolicy` | repo module. [VERIFIED: lib/threadline/capture/redaction_policy.ex] | Re-validates configured `exclude`, `mask`, and `mask_placeholder`. | It is already the canonical validator for trigger-redaction semantics. [VERIFIED: lib/threadline/capture/redaction_policy.ex] |
| New `Threadline.Capture.TriggerCaptureConfig` | additive repo module. [ASSUMED] | Shared loader/normalizer for `config :threadline, :trigger_capture` extracted from `mix threadline.gen.triggers`. | Prevents semantic drift between trigger generation and the new drift viewer. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex] |
| New `Threadline.Capture.RedactionReconciler` | additive repo module. [ASSUMED] | Single report builder returning normalized configured policy, deployed policy, status, diff, warning, and hint per table. | Gives Mix and LiveView one shared contract and preserves optional Phoenix deps. [VERIFIED: mix.exs, lib/mix/tasks/threadline.health.coverage.ex] |

### Supporting

| Library / Module | Version | Purpose | When to Use |
|------------------|---------|---------|-------------|
| Phoenix LiveView | optional `~> 1.0` in project; current HexDocs page is v1.1.30. [VERIFIED: mix.exs] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html] | Read-only admin screen under the existing operator surface. | Only for the page layer; keep shared reconciliation logic outside `Threadline.OperatorSurface.*`. [VERIFIED: mix.exs, lib/threadline/operator_surface/router.ex] |
| `OptionParser` | stdlib; current docs prefer `strict:` for declared switches. [CITED: https://hexdocs.pm/elixir/OptionParser.html] | `mix threadline.policy.show` flags such as `--json` and optional schema filters if added. | Use for stable, explicit CLI contracts and to avoid atom creation from untrusted switches. [CITED: https://hexdocs.pm/elixir/OptionParser.html] |
| `Jason` | `~> 1.4`. [VERIFIED: mix.exs] | Stable JSON report output. | Use only at the presentation edge; keep the reconciler report as plain maps/structs. [VERIFIED: lib/mix/tasks/threadline.health.coverage.ex, mix.exs] |
| `Threadline.OperatorSurface.Style` | repo module. [VERIFIED: lib/threadline/operator_surface/style.ex] | Extends `.threadline-ui` CSS namespace for grouped sections and low-noise status treatments. | Follow the existing operator-surface styling pattern instead of introducing a new UI shell. [VERIFIED: lib/threadline/operator_surface/style.ex, lib/threadline/operator_surface/live/coverage_live.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Primary `pg_proc.prosrc` parsing | `pg_get_functiondef(p.oid)` parsing | PostgreSQL exposes `pg_get_functiondef`, but it returns a decompiled `CREATE OR REPLACE FUNCTION` statement rather than the stored body, which adds more formatting noise and broader version-sensitivity than `prosrc`. Keep it as a debug aid, not the pass/fail parser input. [CITED: https://www.postgresql.org/docs/current/functions-info.html] [CITED: https://www.postgresql.org/docs/current/catalog-pg-proc.html] |
| Shared reconciler report | Separate LiveView and Mix comparisons | Duplicates status logic, ordering, and no-sample-values rules in two places, which is exactly the kind of parity drift Phase 67 is supposed to prevent. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md] |
| Conservative anchor parsing | Generic PL/pgSQL parsing | Overbuilt for this phase and more likely to create false positives; the repo only needs to recognize Threadline’s own generated SQL shape and fail closed otherwise. [VERIFIED: lib/threadline/capture/trigger_sql.ex] |

**Installation:** no new Hex dependencies recommended. Reuse project-pinned `ecto_sql`, `jason`, and optional Phoenix deps only. [VERIFIED: mix.exs]

## Architecture Patterns

### System Architecture Diagram

```text
Application env
config :threadline, :trigger_capture
        |
        v
Threadline.Capture.TriggerCaptureConfig.load()
        |
        v
Threadline.Capture.RedactionPolicy.validate!()
        |
        +------------------------------+
        |                              |
        v                              v
Configured policy map          PostgreSQL catalog query
                               pg_trigger -> tgfoid -> pg_proc.prosrc
                               (optionally select pg_get_functiondef for debug only)
                                        |
                                        v
                           Threadline.Capture.RedactionReconciler
                           - parse known TriggerSQL anchors
                           - fail closed on ambiguity
                           - diff configured vs deployed
                           - produce summary + per-table entries
                                        |
                     +------------------+------------------+
                     |                                     |
                     v                                     v
mix threadline.policy.show                    /audit/policy/redaction LiveView
- summary line                               - summary counts
- compact table                              - sectioned groups by status
- detail blocks for drift/introspection      - local disclosure for exact sets
- --json stable contract                     - never renders sample values
```

All data flow after the catalog query should operate on one shared report shape so the Mix task and LiveView can only drift in presentation, not in facts. [VERIFIED: lib/mix/tasks/threadline.health.coverage.ex, lib/threadline/operator_surface/live/coverage_live.ex]

### Recommended Project Structure

```text
lib/
├── threadline/capture/
│   ├── trigger_capture_config.ex      # extracted config loader/normalizer
│   ├── redaction_reconciler.ex        # shared report builder + parser + diff
│   └── redaction_policy.ex            # existing validator
├── mix/tasks/
│   └── threadline.policy.show.ex      # Mix presenter over reconciler report
└── threadline/operator_surface/
    ├── live/redaction_policy_live.ex  # LiveView presenter over reconciler report
    ├── router.ex                      # sibling live route
    └── style.ex                       # additive `.threadline-ui` styles
test/
├── threadline/capture/redaction_reconciler_test.exs
├── mix/tasks/threadline.policy.show_test.exs
└── threadline/operator_surface/
    ├── redaction_policy_doc_contract_test.exs
    └── live/redaction_policy_live_test.exs
```

This structure preserves the existing split between pure core logic, Mix tasks, and optional Phoenix files. [VERIFIED: mix.exs, lib/threadline/operator_surface/router.ex, lib/mix/tasks/threadline.health.coverage.ex]

### Pattern 1: Extract Trigger-Capture Config Normalization Before Building the Viewer

**What:** move `load_trigger_capture_tables/0`, `normalize_tables_map/1`, and the table-entry normalization rules out of `Mix.Tasks.Threadline.Gen.Triggers` into a shared capture-policy module. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex]  
**When to use:** first slice; both the reconciler and `mix threadline.gen.triggers` should call the same loader. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex]  
**Why:** a config-only viewer is wrong if it does not use the same normalization path that trigger generation uses today. [VERIFIED: .planning/PROJECT.md, .planning/STATE.md]

**Example:**

```elixir
defmodule Threadline.Capture.TriggerCaptureConfig do
  alias Threadline.Capture.RedactionPolicy

  def load! do
    Application.get_env(:threadline, :trigger_capture, [])
    |> normalize_tables()
    |> Enum.map(fn {table, entry} ->
      :ok = RedactionPolicy.validate!(entry)
      {table, normalize_entry(entry)}
    end)
    |> Map.new()
  end
end
```

Source pattern: current loader and validator usage in `mix threadline.gen.triggers`. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex]

### Pattern 2: Parse Only Known `TriggerSQL` Anchors and Treat Everything Else as `could_not_introspect`

**What:** parse deployed redaction from the exact statements Threadline emits today instead of trying to understand arbitrary PL/pgSQL. [VERIFIED: lib/threadline/capture/trigger_sql.ex]  
**When to use:** every deployed trigger-function inspection path. [VERIFIED: lib/threadline/capture/trigger_sql.ex]  
**Why:** `prosrc` is language-specific text, so correctness depends on recognizing the known Threadline body shape and refusing everything else. [CITED: https://www.postgresql.org/docs/current/catalog-pg-proc.html]

**Recommended anchors from current generated SQL:**

- Exclude statements: `v_data_after := v_data_after - 'column';` [VERIFIED: lib/threadline/capture/trigger_sql.ex]
- Mask statements: `v_data_after := v_data_after || jsonb_build_object('column', to_jsonb('PLACEHOLDER'::text));` [VERIFIED: lib/threadline/capture/trigger_sql.ex]
- `changed_from` mask statements: `WHEN u.k = ANY(ARRAY['email']::text[]) THEN to_jsonb('PLACEHOLDER'::text)` in per-table functions with `store_changed_from: true`. [VERIFIED: lib/threadline/capture/trigger_sql.ex]
- Legacy empty-redaction global body: no redaction anchors plus function name `threadline_capture_changes` means deployed `exclude=[]`, `mask=[]`, and default behavior. [VERIFIED: lib/threadline/capture/migration.ex, lib/threadline/capture/trigger_sql.ex]

**Example:**

```elixir
def deployed_policy_from_prosrc!(proname, prosrc) do
  exclude = extract_sql_string_literals(~r/v_data_after := v_data_after - '((?:''|[^'])+)';/, prosrc)
  masks = extract_mask_pairs(prosrc)
  changed_from_masks = extract_changed_from_mask_columns(prosrc)

  ensure_known_function_shape!(proname, prosrc, exclude, masks, changed_from_masks)
  ensure_mask_consistency!(masks, changed_from_masks)

  %{
    exclude: Enum.sort(Enum.uniq(exclude)),
    mask: masks |> Enum.map(& &1.column) |> Enum.sort(),
    mask_placeholder: shared_placeholder!(masks, changed_from_masks)
  }
end
```

Anchor sources: current generated SQL examples produced by `Threadline.Capture.TriggerSQL.install_function/1` and `install_function_for_table/2`. [VERIFIED: lib/threadline/capture/trigger_sql.ex]

### Pattern 3: Keep the Reconciler Report Stable and Let Presenters Stay Thin

**What:** the shared module should return a fully normalized report with summary counts, sorted table entries, statuses, hints, and structured diffs; the Mix task and LiveView should only group, format, and render. [ASSUMED]  
**When to use:** after the shared parser/diff layer exists. [ASSUMED]  
**Why:** this mirrors the Phase 66 parity model and makes doc-contract tests practical because output strings become deterministic. [VERIFIED: lib/mix/tasks/threadline.health.coverage.ex, test/threadline/operator_surface/coverage_doc_contract_test.exs]

**Example:**

```elixir
%Report{
  summary: %{drift_detected: 2, could_not_introspect: 1, config_matches_deployed: 8},
  tables: [
    %Entry{
      table: "users",
      status: :drift_detected,
      configured: %{exclude: ["password"], mask: ["email"], mask_placeholder: "[REDACTED]"},
      deployed: %{exclude: [], mask: [], mask_placeholder: nil},
      diff: %{exclude_only_in_config: ["password"], mask_only_in_config: ["email"]},
      hint: "Configured redaction does not match deployed trigger SQL. Rerun `mix threadline.gen.triggers` and apply the migration."
    }
  ]
}
```

Status taxonomy and hint copy come directly from the locked context. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md]

### Anti-Patterns to Avoid

- **Config-only viewer:** it ignores the exact footgun this phase exists to expose. [VERIFIED: .planning/ROADMAP.md, .planning/PROJECT.md]
- **Guessing through parse errors:** any unexpected trigger body must become `Could not introspect`, never a synthetic match. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md]
- **Putting the shared reconciler under `Threadline.OperatorSurface.*`:** that would force Phoenix onto the core logic path and violate the optional-deps posture. [VERIFIED: mix.exs, CLAUDE.md]
- **Leaking raw values in `warning`, `hint`, JSON, or tests:** only column names and placeholder metadata are allowed. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md]

## Concrete Implementation Seams

### Seam 1: Extract config loading from `Mix.Tasks.Threadline.Gen.Triggers`

`load_trigger_capture_tables/0`, `normalize_tables_map/1`, and `normalize_table_entry/1` are private to the generator today, but Phase 67 needs the same normalized table map to avoid config-dialect drift between generation and reconciliation. Extract them into a shared module and have the generator delegate back to it. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex]

### Seam 2: Build one catalog query that returns deployed function identity and source

Follow Phase 66’s `Threadline.Health` pattern and use one parameterized query. Join the audited table trigger row to the trigger function row through `tgfoid`, and include `pg_language.lanname` so non-`plpgsql` functions can fail closed immediately. PostgreSQL documents `tgfoid` as the trigger’s function reference and `prosrc` as language-specific invocation/source text. [CITED: https://www.postgresql.org/docs/current/catalog-pg-trigger.html] [CITED: https://www.postgresql.org/docs/current/catalog-pg-proc.html] [VERIFIED: lib/threadline/health.ex]

Recommended query shape:

```sql
SELECT
  c.relname AS table_name,
  t.tgname,
  p.oid AS proc_oid,
  p.proname,
  p.prosrc,
  l.lanname,
  pg_get_functiondef(p.oid) AS function_def
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
JOIN pg_proc p ON t.tgfoid = p.oid
JOIN pg_language l ON p.prolang = l.oid
WHERE n.nspname = $1
  AND t.tgname LIKE 'threadline_audit_%'
  AND NOT t.tgisinternal;
```

Use `function_def` only for debugging or tests; do not let it turn parse failures into passes. [CITED: https://www.postgresql.org/docs/current/functions-info.html]

### Seam 3: Inventory should be `configured ∪ deployed`, not only config tables

`config :threadline, :trigger_capture` only names tables with special options; unlisted audited tables still exist and often correctly use empty redaction through the global function installed by `mix threadline.install`. The reconciler therefore needs the union of configured tables and deployed Threadline trigger tables. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex, lib/mix/tasks/threadline.install.ex, lib/threadline/capture/migration.ex]

Recommended handling:

- Configured + deployed + same policy -> `config_matches_deployed`. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md]
- Configured + deployed + policy mismatch -> `drift_detected`. [VERIFIED: .planning/REQUIREMENTS.md]
- Configured + no Threadline trigger row -> `drift_detected` with reason `trigger_missing`. [RESOLVED]
- Deployed + no config entry -> treat configured policy as empty and compare normally. [VERIFIED: lib/mix/tasks/threadline.install.ex, lib/threadline/capture/migration.ex]
- Multiple Threadline trigger rows for one table -> `could_not_introspect` with reason `ambiguous_trigger_inventory`. [ASSUMED]

### Seam 4: Reuse the Phase 66 presenter split

`mix threadline.health.coverage` already demonstrates the right split: repo/bootstrap in the task, shared library call for facts, human formatter plus `--json` path in the task, and no non-zero exit for informational drift. Phase 67 should copy that pattern exactly. [VERIFIED: lib/mix/tasks/threadline.health.coverage.ex]

### Seam 5: Route and style changes should mirror `CoverageLive`, not invent a new surface shell

Add a sibling LiveView route under the existing `threadline_operator_surface` macro and extend `Threadline.OperatorSurface.Style` inside `.threadline-ui`. CoverageLive already shows the expected optional-deps gating, page wrapper, and read-only table layout style. [VERIFIED: lib/threadline/operator_surface/router.ex, lib/threadline/operator_surface/live/coverage_live.ex, lib/threadline/operator_surface/style.ex]

## `pg_proc.prosrc` Introspection Options and Failure Modes

### Recommended option: primary parse input = `pg_proc.prosrc`

PostgreSQL documents `pg_proc.prosrc` as language-specific source/invocation text and specifically notes that, for currently known non-compiled languages, it contains source text. Threadline’s generated trigger functions are `LANGUAGE plpgsql`, so `prosrc` is the closest stored representation of the exact body shape `TriggerSQL` emits. [CITED: https://www.postgresql.org/docs/current/catalog-pg-proc.html] [VERIFIED: lib/threadline/capture/trigger_sql.ex]

Why this is the right fit here:

- It gives the function body without the reconstructed `CREATE OR REPLACE FUNCTION` wrapper, so the parser only has to recognize Threadline’s own emitted statements. [CITED: https://www.postgresql.org/docs/current/catalog-pg-proc.html]
- It lines up with the exact literals present in `TriggerSQL.install_function/1` and `install_function_for_table/2`, including `v_data_after := v_data_after - ...`, `jsonb_build_object(...)`, and the `CASE WHEN u.k = ANY(...)` branch for `changed_from`. [VERIFIED: lib/threadline/capture/trigger_sql.ex]
- It makes conservative failure straightforward: if the body stops matching the known anchors, return `could_not_introspect`. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md]

### Secondary option: fetch `pg_get_functiondef(p.oid)` for diagnostics only

PostgreSQL exposes `pg_get_functiondef`, which reconstructs a complete `CREATE OR REPLACE FUNCTION` statement. That is useful for debugging, for parity tests, or for logging the exact deployed function when a parser test fails, but it should not be the authoritative parse source for Phase 67 because it is a decompiled reconstruction rather than the stored body. [CITED: https://www.postgresql.org/docs/current/functions-info.html]

### Option explicitly not recommended: generic PL/pgSQL or AST parsing

The repo does not need a generic function parser. The generated SQL is regular enough that regex/anchor extraction with explicit consistency checks is safer, cheaper, and easier to keep honest in tests. Anything outside the known shape should fail closed. [VERIFIED: lib/threadline/capture/trigger_sql.ex]

### Failure modes the reconciler must detect

| Failure mode | What it looks like | Required behavior |
|--------------|--------------------|-------------------|
| Trigger row missing for a configured table | No `pg_trigger` row matching `threadline_audit_%` for the table. [CITED: https://www.postgresql.org/docs/current/catalog-pg-trigger.html] | `drift_detected` with rerun hint; absence of a deployed trigger is a definite mismatch. [RESOLVED: REDN-04 + Open Questions section] |
| Multiple Threadline triggers on one table | More than one `threadline_audit_%` row for a single table. [ASSUMED] | `could_not_introspect` because deployed policy is ambiguous. [ASSUMED] |
| Non-`plpgsql` trigger function | `pg_language.lanname != 'plpgsql'`. [CITED: https://www.postgresql.org/docs/current/catalog-pg-proc.html] | `could_not_introspect`; the parser is intentionally scoped to Threadline’s generated PL/pgSQL. [VERIFIED: lib/threadline/capture/trigger_sql.ex] |
| Global legacy function with no redaction anchors | `proname == "threadline_capture_changes"` and no exclude/mask anchors in `prosrc`. [VERIFIED: lib/threadline/capture/migration.ex, lib/threadline/capture/trigger_sql.ex] | Treat as deployed empty policy, not as a parse error. [VERIFIED: lib/threadline/capture/migration.ex] |
| Placeholder mismatch between `data_after` and `changed_from` sections | Different placeholder strings extracted from the same function body. [VERIFIED: lib/threadline/capture/trigger_sql.ex] | `drift_detected` if both parse cleanly but differ; `could_not_introspect` if the body is internally inconsistent beyond the supported shape. [ASSUMED] |
| Manual edits or future formatter changes break anchor patterns | `prosrc` no longer matches the emitted regex anchors. [VERIFIED: lib/threadline/capture/trigger_sql.ex] | `could_not_introspect`; this is the load-bearing fail-closed path. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md] |
| Escaped quotes inside column names or placeholders | SQL literals appear as doubled quotes inside `prosrc`. [VERIFIED: lib/threadline/capture/trigger_sql.ex] | Use a SQL-string-literal unescaper, not a bare identifier regex, before comparing. [VERIFIED: lib/threadline/capture/trigger_sql.ex] |

## Recommended Phase Decomposition

### Slice 67-01: Shared reconciliation core

**Deliverables**

- Extract shared `TriggerCaptureConfig` loader from `mix threadline.gen.triggers`. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex]
- Add `Threadline.Capture.RedactionReconciler` report structs and core `reconcile/1`. [ASSUMED]
- Implement the catalog query, `prosrc` parser, diff logic, status mapping, and sort order. [CITED: https://www.postgresql.org/docs/current/catalog-pg-trigger.html] [CITED: https://www.postgresql.org/docs/current/catalog-pg-proc.html]
- Add focused unit tests against known SQL bodies generated by `TriggerSQL`. [VERIFIED: lib/threadline/capture/trigger_sql.ex, test/threadline/capture/trigger_redaction_test.exs]

**Depends on:** none. [VERIFIED: phase scope]

### Slice 67-02: Mix parity task

**Deliverables**

- Add `mix threadline.policy.show` with summary line, compact table, detail blocks for drift/introspection, and `--json`. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md]
- Keep exit code informational, mirroring `mix threadline.health.coverage`. [VERIFIED: lib/mix/tasks/threadline.health.coverage.ex]
- Add task tests for human output, `--json`, no-sample-values invariants, and error exits on invalid input/runtime failure only. [VERIFIED: test/threadline/operator_surface/coverage_mix_test.exs]

**Depends on:** 67-01. [VERIFIED: architecture]

### Slice 67-03: LiveView page

**Deliverables**

- Add sibling route under `threadline_operator_surface`, gated at file scope like existing surface modules. [VERIFIED: lib/threadline/operator_surface/router.ex]
- Add `RedactionPolicyLive` with summary counts, locked section ordering, alphabetical ordering, and local disclosure only. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md]
- Extend `Threadline.OperatorSurface.Style` for section and row styling inside `.threadline-ui`. [VERIFIED: lib/threadline/operator_surface/style.ex]

**Depends on:** 67-01. [VERIFIED: architecture]

### Slice 67-04: Parity, docs, and contract tests

**Deliverables**

- Add doc-contract test pinning route literal, status literals, section ordering, JSON keys, and no-sample-values invariants. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md]
- Add parity assertions proving the Mix task and LiveView consume the same facts/statuses for the same seeded state. [VERIFIED: Phase 66 test patterns]
- Update `guides/operator-surface.md` and `guides/domain-reference.md` with the new read-only redaction viewer and rerun guidance. [VERIFIED: guides/operator-surface.md, guides/domain-reference.md]

**Depends on:** 67-02 and 67-03. [VERIFIED: architecture]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Shared config interpretation | A second ad hoc parser for `config :threadline, :trigger_capture` inside the LiveView or Mix task | Extract a shared config loader from `mix threadline.gen.triggers` | The generator already defines the runtime truth for redaction options; duplicating it invites parity drift. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex] |
| Deployed trigger inspection | A generic PL/pgSQL parser or heuristic free-text compare | Conservative anchor parsing of Threadline’s own `prosrc` body shape | Generic parsing is unnecessary and more dangerous than fail-closed shape recognition here. [VERIFIED: lib/threadline/capture/trigger_sql.ex] |
| UI/Mix parity | Two separate status and diff implementations | One shared reconciler report consumed by both presenters | Parity failures become one-core bugs instead of cross-surface drift. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md] |
| Value display | Sampling or querying `audit_changes` data to “show examples” | Configured/deployed column names plus placeholder metadata only | Sample values are explicitly forbidden by the phase contract and would create a compliance leak. [VERIFIED: .planning/REQUIREMENTS.md] |

**Key insight:** the hard part of this phase is not rendering a page. It is preserving one source of truth for redaction semantics across generation, introspection, CLI output, and LiveView output while failing closed whenever deployed SQL stops looking like Threadline’s own generated shape. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex, lib/threadline/capture/trigger_sql.ex, .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Config-only “success” after a trigger migration was not regenerated

**What goes wrong:** the UI shows the current config and implies safety even though the deployed trigger function still contains the old redaction behavior. [VERIFIED: .planning/PROJECT.md, .planning/STATE.md]  
**Why it happens:** config loading is easy; deployed trigger introspection is the hard part. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex, lib/threadline/capture/trigger_sql.ex]  
**How to avoid:** always compare normalized config to deployed `prosrc` output through the shared reconciler. [VERIFIED: primary recommendation]  
**Warning signs:** a table appears configured for masking/exclusion but still points at the legacy global function or a mismatched per-table body. [VERIFIED: lib/threadline/capture/migration.ex, lib/threadline/capture/trigger_sql.ex]

### Pitfall 2: Treating parse ambiguity as a match

**What goes wrong:** the viewer silently passes a function body it does not actually understand. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md]  
**Why it happens:** a permissive parser tries to recover from unknown SQL shapes. [ASSUMED]  
**How to avoid:** map every unsupported or ambiguous case to `could_not_introspect`. [VERIFIED: .planning/REQUIREMENTS.md]  
**Warning signs:** fallback branches that return empty sets or default placeholders after regex misses. [ASSUMED]

### Pitfall 3: Duplicating config normalization in the new task

**What goes wrong:** `mix threadline.gen.triggers` and `mix threadline.policy.show` disagree about what config means. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex]  
**Why it happens:** the generator’s config loader is private today. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex]  
**How to avoid:** extract the loader first and make the generator call back into it. [VERIFIED: recommended Slice 67-01]  
**Warning signs:** different handling of string keys, map-vs-keyword entries, or placeholder defaults between the generator and the viewer. [VERIFIED: lib/mix/tasks/threadline.gen.triggers.ex, lib/threadline/capture/redaction_policy.ex]

### Pitfall 4: Forgetting the “empty config, global function” happy path

**What goes wrong:** unconfigured audited tables are incorrectly flagged because the parser only expects per-table redacted functions. [VERIFIED: lib/mix/tasks/threadline.install.ex, lib/threadline/capture/migration.ex]  
**Why it happens:** the initial install path creates the global legacy function with no redaction anchors. [VERIFIED: lib/threadline/capture/migration.ex]  
**How to avoid:** explicitly recognize `threadline_capture_changes` with no redaction anchors as the deployed empty-policy baseline. [VERIFIED: lib/threadline/capture/trigger_sql.ex]  
**Warning signs:** every audited table without a config entry shows `could_not_introspect`. [ASSUMED]

### Pitfall 5: Leaking sensitive values in “helpful” details or tests

**What goes wrong:** raw values or example values appear in HTML, Mix output, JSON, or snapshot tests. [VERIFIED: .planning/REQUIREMENTS.md]  
**Why it happens:** presenters or tests use `AuditChange` fixtures instead of only config and deployed function metadata. [ASSUMED]  
**How to avoid:** keep the report model value-free and write no-sample-values assertions into doc-contract and integration tests. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md]  
**Warning signs:** strings from inserted row fixtures appear in rendered output or JSON. [ASSUMED]

### Pitfall 6: Breaking optional-deps compilation by placing shared logic under operator-surface files

**What goes wrong:** capture-only adopters lose `mix verify.compile_no_optional` because the shared core requires Phoenix. [VERIFIED: mix.exs, CLAUDE.md]  
**Why it happens:** the page and the shared reconciliation logic get implemented together in `Threadline.OperatorSurface.*`. [ASSUMED]  
**How to avoid:** keep the reconciler in `Threadline.Capture.*` or another pure namespace and gate only the LiveView files. [VERIFIED: mix.exs, lib/threadline/operator_surface/router.ex]  
**Warning signs:** new parser/report modules start with `if Code.ensure_loaded?(Phoenix.LiveView) do`. [ASSUMED]

## Code Examples

### Catalog query for deployed trigger SQL

```elixir
sql = """
SELECT
  c.relname AS table_name,
  t.tgname,
  p.proname,
  p.prosrc,
  l.lanname,
  pg_get_functiondef(p.oid) AS function_def
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
JOIN pg_proc p ON t.tgfoid = p.oid
JOIN pg_language l ON p.prolang = l.oid
WHERE n.nspname = $1
  AND t.tgname LIKE 'threadline_audit_%'
  AND NOT t.tgisinternal
ORDER BY c.relname
"""

%{rows: rows} = Ecto.Adapters.SQL.query!(repo, sql, [schema])
```

Source: PostgreSQL catalog docs for `tgfoid` and `prosrc`, plus the existing parameterized catalog-query style in `Threadline.Health`. [CITED: https://www.postgresql.org/docs/current/catalog-pg-trigger.html] [CITED: https://www.postgresql.org/docs/current/catalog-pg-proc.html] [VERIFIED: lib/threadline/health.ex]

### Recognize current generated exclude/mask anchors

```elixir
exclude =
  Regex.scan(~r/v_data_after := v_data_after - '((?:''|[^'])+)';/, prosrc)
  |> Enum.map(fn [_, col] -> String.replace(col, "''", "'") end)

mask_pairs =
  Regex.scan(
    ~r/jsonb_build_object\('((?:''|[^'])+)',\s*to_jsonb\('((?:''|[^'])*)'::text\)\)/,
    prosrc
  )
```

Source: exact emitted SQL fragments from `Threadline.Capture.TriggerSQL`. [VERIFIED: lib/threadline/capture/trigger_sql.ex]

### Attach a new sibling LiveView route without changing the auth model

```elixir
live_session :threadline,
  on_mount: [
    {Threadline.OperatorSurface.Auth, opts},
    {Threadline.OperatorSurface.Coverage.OnMount, opts}
  ] do
  scope path, alias: Threadline.OperatorSurface.Live do
    live("/", TimelineLive, :index)
    live("/coverage", CoverageLive, :index)
    live("/policy/redaction", RedactionPolicyLive, :index)
  end
end
```

Source: current operator-surface router structure. [VERIFIED: lib/threadline/operator_surface/router.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Config-only policy views | Drift-aware config-vs-deployed reconciliation | v1.18 Phase 67 scope. [VERIFIED: .planning/ROADMAP.md, .planning/REQUIREMENTS.md] | Makes the “changed config but did not rerun/apply triggers” footgun visible instead of invisible. [VERIFIED: .planning/PROJECT.md] |
| Per-surface parity logic | Shared core report with thin Mix/LV presenters | Recommended for Phase 67 based on Phase 66 precedent. [VERIFIED: lib/mix/tasks/threadline.health.coverage.ex, lib/threadline/operator_surface/live/coverage_live.ex] | Lowers drift risk and shrinks the doc-contract surface. [ASSUMED] |
| Generic function reconstruction as parse input | `prosrc` as the authoritative parse input, `pg_get_functiondef` for diagnostics | Current PostgreSQL docs and Threadline SQL shape support this split. [CITED: https://www.postgresql.org/docs/current/catalog-pg-proc.html] [CITED: https://www.postgresql.org/docs/current/functions-info.html] | Keeps the parser tighter and more conservative. [ASSUMED] |

**Deprecated/outdated:**

- A config-only redaction viewer is outdated for this repo because it does not satisfy REDN-04’s drift-detection requirement. [VERIFIED: .planning/REQUIREMENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Threadline.Capture.TriggerCaptureConfig` is the best extraction target/module name for shared config normalization. | Standard Stack / Recommended Project Structure | Low — planner can rename the module without changing the architecture. |
| A2 | Configured tables with no deployed Threadline trigger should surface as `drift_detected`. | Concrete Implementation Seams | Low — resolved and aligned with plans/validation; absence of the deployed trigger is a definite mismatch. |
| A3 | Multiple Threadline triggers for one table should map to `could_not_introspect` rather than a directional drift reason. | `pg_proc.prosrc` Failure Modes | Medium — affects diagnostics wording, not data safety. |

## Open Questions (RESOLVED)

1. **Should the reconciler expose a reusable sort key or should presenters sort locally?**  
Resolved: the shared reconciler owns canonical ordering. It should expose or apply one section-rank contract plus alphabetical intra-section ordering so Mix and LiveView cannot drift on row order. [RESOLVED: aligns with locked D-40/D-57 in 67-CONTEXT.md]

2. **How should configured tables with no deployed Threadline trigger be classified?**  
Resolved: this is `drift_detected`, not `could_not_introspect`. Trigger absence is a definite mismatch, while `could_not_introspect` is reserved for ambiguous or unsupported deployed function shapes. [RESOLVED: aligns with REDN-04 and operator-safe semantics]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | compile, tests, Mix task work | ✓ | `1.19.5` | — |
| `elixir` | shared core and tests | ✓ | `1.19.5` | — |
| `psql` | manual catalog debugging if needed | ✓ | `14.17` | use `Ecto.Adapters.SQL.query!/3` from tests |
| PostgreSQL server | integration tests and catalog introspection | ✓ | server responded to `pg_isready` | none |

Missing dependencies with no fallback:

- None. [VERIFIED: local env commands]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with `Threadline.DataCase`, `Phoenix.LiveViewTest`, and `Phoenix.ConnTest` where Phoenix is loaded. [VERIFIED: test/test_helper.exs, test/support/data_case.ex, test/threadline/operator_surface/live/coverage_live_test.exs] |
| Config file | `test/test_helper.exs`. [VERIFIED: test/test_helper.exs] |
| Quick run command | `mix test test/threadline/capture/redaction_reconciler_test.exs test/mix/tasks/threadline.policy.show_test.exs test/threadline/operator_surface/redaction_policy_doc_contract_test.exs test/threadline/operator_surface/live/redaction_policy_live_test.exs -x` [ASSUMED] |
| Full suite command | `mix verify.test` and phase gate `mix ci.all`. [VERIFIED: mix.exs, .github/workflows/ci.yml] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REDN-03 | LiveView shows configured `exclude`/`mask`/placeholder data by column name only and never sample values. [VERIFIED: .planning/REQUIREMENTS.md] | integration | `mix test test/threadline/operator_surface/live/redaction_policy_live_test.exs -x` | ❌ Wave 0 |
| REDN-04 | Reconciler detects match, drift, and introspection failure from deployed `prosrc`. [VERIFIED: .planning/REQUIREMENTS.md] | unit | `mix test test/threadline/capture/redaction_reconciler_test.exs -x` | ❌ Wave 0 |
| REDN-05 | Mix task, JSON contract, route literals, status literals, and no-sample-values invariants stay locked. [VERIFIED: .planning/REQUIREMENTS.md] | doc-contract + integration | `mix test test/mix/tasks/threadline.policy.show_test.exs test/threadline/operator_surface/redaction_policy_doc_contract_test.exs -x` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** run the focused REDN tests above. [ASSUMED]
- **Per wave merge:** `mix verify.test`. [VERIFIED: mix.exs]
- **Phase gate:** `mix ci.all` before `/gsd-verify-work`. [VERIFIED: mix.exs, .github/workflows/ci.yml]

### Wave 0 Gaps

- `test/threadline/capture/redaction_reconciler_test.exs` — unit coverage for config normalization reuse, `prosrc` parsing, diff reasons, and ambiguity handling. [ASSUMED]
- `test/mix/tasks/threadline.policy.show_test.exs` — Mix human-output and `--json` parity coverage. [ASSUMED]
- `test/threadline/operator_surface/redaction_policy_doc_contract_test.exs` — route/output/no-sample-values literal pinning. [ASSUMED]
- `test/threadline/operator_surface/live/redaction_policy_live_test.exs` — section ordering, alphabetical ordering, disclosure details, and parity rendering. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Reuse the existing host-owned `:authorize_fn` contract and secure mount macro; do not invent a second auth path. [VERIFIED: CLAUDE.md, guides/operator-surface.md, lib/threadline/operator_surface/router.ex] |
| V3 Session Management | no | Host application owns session semantics; Phase 67 should not add session behavior. [VERIFIED: CLAUDE.md, guides/operator-surface.md] |
| V4 Access Control | yes | Keep the new page under the existing `threadline_operator_surface` auth boundary and preserve read-only behavior. [VERIFIED: .planning/ROADMAP.md, lib/threadline/operator_surface/router.ex] |
| V5 Input Validation | yes | Parameterize catalog queries, keep CLI/LV inputs strict, and avoid atom creation from untrusted values. [CITED: https://hexdocs.pm/elixir/OptionParser.html] [VERIFIED: lib/threadline/health.ex, test/threadline/operator_surface/coverage_doc_contract_test.exs] |
| V6 Cryptography | no | No cryptographic behavior is introduced in this phase. [VERIFIED: phase scope] |

### Known Threat Patterns for this Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection through schema or table selectors | Tampering | Parameterize every catalog query; if the page/task later accepts a schema filter, copy the Phase 66 regex + catalog validation pattern. [VERIFIED: lib/threadline/health.ex, lib/mix/tasks/threadline.health.coverage.ex] |
| Sensitive data disclosure in admin output | Information Disclosure | Keep the report model value-free and assert no sample values in UI, Mix, and JSON. [VERIFIED: .planning/REQUIREMENTS.md] |
| False-negative drift due to permissive parsing | Tampering | Fail closed to `could_not_introspect` on any unsupported function body. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md] |
| Access-control drift between HTTP/LV and Mix surfaces | Elevation of Privilege | Reuse existing router auth for LV; keep Mix task as local-operator tooling only and do not conflate it with a remotely exposed API. [VERIFIED: guides/operator-surface.md, lib/threadline/operator_surface/router.ex] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md` - locked decisions, status taxonomy, and parity constraints. [VERIFIED: .planning/phases/67-drift-aware-redaction-admin-mix-task-parity/67-CONTEXT.md]
- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `.planning/STATE.md` - phase goal, success criteria, milestone framing, and current repo decisions. [VERIFIED: .planning/ROADMAP.md, .planning/REQUIREMENTS.md, .planning/PROJECT.md, .planning/STATE.md]
- `lib/threadline/capture/redaction_policy.ex`, `lib/threadline/capture/trigger_sql.ex`, `lib/mix/tasks/threadline.gen.triggers.ex` - canonical config vocabulary and emitted SQL anchors. [VERIFIED: lib/threadline/capture/redaction_policy.ex, lib/threadline/capture/trigger_sql.ex, lib/mix/tasks/threadline.gen.triggers.ex]
- `lib/threadline/operator_surface/router.ex`, `lib/threadline/operator_surface/live/coverage_live.ex`, `lib/threadline/operator_surface/components/surface_header.ex`, `lib/threadline/operator_surface/style.ex`, `lib/mix/tasks/threadline.health.coverage.ex` - current operator-surface and Mix-parity patterns. [VERIFIED: listed files]
- `guides/operator-surface.md`, `guides/domain-reference.md`, `README.md`, `mix.exs`, `.github/workflows/ci.yml`, `test/test_helper.exs` - docs/tests/verification conventions. [VERIFIED: listed files]
- PostgreSQL docs: `pg_trigger`, `pg_proc`, and `pg_get_functiondef`.  
  - https://www.postgresql.org/docs/current/catalog-pg-trigger.html  
  - https://www.postgresql.org/docs/current/catalog-pg-proc.html  
  - https://www.postgresql.org/docs/current/functions-info.html
- Phoenix LiveView docs:  
  - https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html  
  - https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.Router.html
- Elixir `OptionParser` docs: https://hexdocs.pm/elixir/OptionParser.html

### Secondary (MEDIUM confidence)

- `.planning/phases/66-coverage-dashboard-mix-task-parity/66-CONTEXT.md` and `66-RESEARCH.md` - local precedent for Mix/LV parity and doc-contract protection. [VERIFIED: .planning/phases/66-coverage-dashboard-mix-task-parity/66-CONTEXT.md, .planning/phases/66-coverage-dashboard-mix-task-parity/66-RESEARCH.md]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - all recommended building blocks already exist in the repo or are official stdlib/framework/docs-backed. [VERIFIED: mix.exs, local source files, cited docs]
- Architecture: HIGH - the shared-core plus thin-presenter split is strongly supported by current Phase 66 patterns and the locked Phase 67 constraints. [VERIFIED: 67-CONTEXT.md, 66-RESEARCH.md]
- Pitfalls: HIGH - the main risks are directly visible in current trigger-generation code, current docs, and the phase contract. [VERIFIED: lib/threadline/capture/trigger_sql.ex, lib/mix/tasks/threadline.gen.triggers.ex, .planning/REQUIREMENTS.md]

**Research date:** 2026-05-07  
**Valid until:** 2026-06-06 for repo-local structure; re-check official PostgreSQL/Phoenix docs if implementation slips past that. [CITED: https://www.postgresql.org/docs/current/catalog-pg-proc.html] [CITED: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html]

## RESEARCH COMPLETE
