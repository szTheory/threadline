# Phase 67: Drift-Aware Redaction Admin & Mix Task Parity - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a read-only redaction admin surface under the existing operator surface plus a parity `mix threadline.policy.show` task. The feature reconciles configured redaction (`config :threadline, :trigger_capture`) against deployed trigger behavior extracted conservatively from `pg_proc.prosrc`. It never renders sample values. It must make the "config changed but triggers were not regenerated/applied" footgun obvious, and it must work for both Phoenix-mounted adopters and capture-only adopters.

</domain>

<decisions>
## Implementation Decisions

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

- **D-54: Never render sample values anywhere.** Not in the LiveView, not in the Mix task, not in JSON. Column names and placeholder metadata only.
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase contract and milestone scope
- `.planning/ROADMAP.md` §"Phase 67: Drift-Aware Redaction Admin & Mix Task Parity" — goal, success criteria, read-only posture, parity requirement.
- `.planning/REQUIREMENTS.md` §"REDN-03..05" — route, drift detection, Mix-task parity, no sample values.
- `.planning/PROJECT.md` §"Current Milestone: v1.18 Adoption and Policy Hardening" — strategic framing for policy hardening and operator rollout.
- `.planning/STATE.md` §"Accumulated Context" — prior v1.18 rationale around policy drift visibility and read-only ceilings.

### Prior phase conventions that Phase 67 should extend
- `.planning/phases/65-exports-ui-parity/65-CONTEXT.md` — semantic-vs-visual parity rule for Mix vs UI, aligned table + `--json` posture, stable machine contract.
- `.planning/phases/66-coverage-dashboard-mix-task-parity/66-CONTEXT.md` — sectioned state presentation, header badge conventions, small status taxonomy, parity Mix task.

### Existing code and docs
- `lib/threadline/capture/redaction_policy.ex` — validation and placeholder semantics.
- `lib/threadline/capture/trigger_sql.ex` — actual trigger-generation semantics for `exclude`, `mask`, and placeholder behavior.
- `lib/mix/tasks/threadline.gen.triggers.ex` — source of configured trigger-capture policy and operator rerun action.
- `lib/threadline/operator_surface/router.ex` — current surface route shape and sibling-LV conventions.
- `lib/threadline/operator_surface/live/coverage_live.ex` — closest existing state-bucketed operator page pattern.
- `lib/threadline/operator_surface/components/surface_header.ex` — current operator-surface tone and badge posture.
- `lib/threadline/operator_surface/style.ex` — existing CSS namespace and sticky-header conventions.
- `lib/mix/tasks/threadline.health.coverage.ex` — local model for viewer-style Mix parity and `--json`.
- `guides/operator-surface.md` — operator-facing documentation tone and current coverage-page precedent.
- `guides/domain-reference.md` — operational style and Mix-task documentation conventions.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Capture.RedactionPolicy.validate!/1` already defines the configured policy vocabulary and placeholder validation rules.
- `Threadline.Capture.TriggerSQL` is the semantic truth for what `exclude`, `mask`, and `mask_placeholder` actually do in deployed SQL.
- `CoverageLive` and `Mix.Tasks.Threadline.Health.Coverage` provide the closest in-repo parity pattern: compact human output, stable `--json`, and explicit "viewer, not gate" semantics.
- `Threadline.OperatorSurface.Style` already supports a sticky global header and a low-noise read-only operator surface.

### Established Patterns
- Optional Phoenix/LiveView deps remain gated at file scope; `mix verify.compile_no_optional` must stay green.
- The operator surface favors compact scan-first pages over dense admin-matrix UIs.
- Mix tasks in this repo should expose compact human output plus a stable JSON mode rather than turning human text into the machine contract.
- State names should be explicit and conservative; uncertainty is surfaced, not hidden.

### Integration Points
- New LiveView under the existing operator surface, likely as a sibling route to `/audit/coverage`.
- New Mix task `mix threadline.policy.show`.
- Shared presenter/diff logic strongly recommended so UI and Mix consume the same per-table reconciliation result rather than reimplementing comparison logic twice.
- Tests should include both doc-contract and behavior-level parity assertions across LV, Mix human output, and `--json`.

</code_context>

<specifics>
## Specific Ideas

- The strongest layout direction is: summary counts first, then state-grouped sections, then expandable per-table exact details.
- The strongest Mix direction is: summary line, aligned table, details only for non-boring rows, `--json` for the full machine shape.
- Popular successful tools in adjacent spaces converge on the same pattern: small top-level states, explicit reasons/messages, and tighter machine contracts than human output. This showed up consistently in the research pass across CloudFormation drift, Argo CD/Kubernetes-style conditions, Terraform/GitHub CLI JSON contracts, and Postgres-style terminal ergonomics.

</specifics>

<deferred>
## Deferred Ideas

- Deep-linkable expansion state or saved filtered redaction views.
- Additional top-level states beyond the three locked here unless a future phase introduces materially new uncertainty classes.
- Overbuilt alphabetical index/jump-link UX unless real adopters prove scale pain with large audited-table inventories.
- Any runtime editing of policy from the UI — explicitly out of scope for v1.18.

</deferred>

---

*Phase: 67-drift-aware-redaction-admin-mix-task-parity*
*Context gathered: 2026-05-07*
