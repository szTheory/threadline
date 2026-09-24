---
phase: 204-structure
reviewed: 2026-09-23T00:00:00Z
depth: standard
files_reviewed: 143
files_reviewed_list:
  - .github/workflows/ci.yml
  - .github/workflows/release.yml
  - CONTRIBUTING.md
  - DESIGN-SYSTEM.md
  - bin/verify-bump-rehearsal
  - examples/threadline_phoenix/e2e/critic/scorecard.ts
  - examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts
  - examples/threadline_phoenix/storybook/data_display/data_table.story.exs
  - examples/threadline_phoenix/storybook/forms/field.story.exs
  - examples/threadline_phoenix/storybook/foundations/index.story.exs
  - examples/threadline_phoenix/storybook/groups/operator_groups.story.exs
  - examples/threadline_phoenix/storybook/overlays/modal.story.exs
  - examples/threadline_phoenix/storybook/patterns/operator_patterns.story.exs
  - examples/threadline_phoenix/storybook/primitives/button.story.exs
  - examples/threadline_phoenix/storybook/states/data_state.story.exs
  - examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs
  - guides/adoption-pilot-backlog.md
  - guides/configuration-and-commands.md
  - guides/evaluating-threadline.md
  - lib/mix/tasks/critic.measure.ex
  - lib/mix/tasks/threadline.export.ex
  - lib/mix/tasks/threadline.install.ex
  - lib/mix/tasks/threadline.verify_coverage.ex
  - lib/threadline/audit.ex
  - lib/threadline/change_diff.ex
  - lib/threadline/critic_trust/krippendorff_alpha.ex
  - lib/threadline/critic_trust/measure.ex
  - lib/threadline/critic_trust/rank_metrics.ex
  - lib/threadline/evidence.ex
  - lib/threadline/export/cleanup_task.ex
  - lib/threadline/export/orchestrator.ex
  - lib/threadline/governance/migration.ex
  - lib/threadline/operator_surface/auth.ex
  - lib/threadline/operator_surface/controllers/export_controller.ex
  - lib/threadline/operator_surface/controllers/export_controller/encoding.ex
  - lib/threadline/operator_surface/live/actor_live.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/live/evidence_live.ex
  - lib/threadline/operator_surface/live/export_status_live.ex
  - lib/threadline/operator_surface/live/export_status_live/components.ex
  - lib/threadline/operator_surface/live/policy_redaction_live.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/row_history_component.ex
  - lib/threadline/operator_surface/live/row_history_live.ex
  - lib/threadline/operator_surface/live/start_live.ex
  - lib/threadline/operator_surface/live/stress_live.ex
  - lib/threadline/operator_surface/live/stress_live/paths.ex
  - lib/threadline/operator_surface/live/stress_live/refute.ex
  - lib/threadline/operator_surface/live/stress_live/sections.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/timeline_live/filters.ex
  - lib/threadline/operator_surface/live/timeline_live/helpers.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/operator_surface/mechanical_checker.ex
  - lib/threadline/operator_surface/mechanical_checker/accent_hue.ex
  - lib/threadline/operator_surface/mechanical_checker/contrast.ex
  - lib/threadline/operator_surface/mechanical_checker/parsing.ex
  - lib/threadline/operator_surface/mechanical_checker/ratchet_metrics.ex
  - lib/threadline/operator_surface/mechanical_checker/scorecards.ex
  - lib/threadline/operator_surface/mechanical_checker/token_conformance.ex
  - lib/threadline/operator_surface/presentation.ex
  - lib/threadline/operator_surface/router.ex
  - lib/threadline/operator_surface/stress_fixtures.ex
  - lib/threadline/operator_surface/style.ex
  - lib/threadline/operator_surface/style/01_tokens.css
  - lib/threadline/operator_surface/style/02_base_shell.css
  - lib/threadline/operator_surface/style/03_page_home.css
  - lib/threadline/operator_surface/style/04_controls.css
  - lib/threadline/operator_surface/style/05_feedback.css
  - lib/threadline/operator_surface/style/06_layout_primitives.css
  - lib/threadline/operator_surface/style/07_find_detail.css
  - lib/threadline/operator_surface/style/08_overlays_motion.css
  - lib/threadline/operator_surface/style/09_responsive.css
  - lib/threadline/operator_surface/ui/actions.ex
  - lib/threadline/operator_surface/ui/data.ex
  - lib/threadline/operator_surface/ui/display.ex
  - lib/threadline/operator_surface/ui/form.ex
  - lib/threadline/operator_surface/ui/overlay.ex
  - lib/threadline/operator_surface/ui/page.ex
  - lib/threadline/policy/redaction_presenter.ex
  - lib/threadline/query.ex
  - lib/threadline/query/cursors.ex
  - lib/threadline/query/filter_params.ex
  - lib/threadline/retention/policy.ex
  - lib/threadline/semantics/actor_ref.ex
  - mix.exs
  - test/fixtures/style/README.md
  - test/fixtures/style/operator_surface.css
  - test/support/getting_started_fixtures.ex
  - test/support/operator_surface_case.ex
  - test/support/ref_copy_contract.ex
  - test/support/source_family.ex
  - test/support/style_source.ex
  - test/threadline/adoption_pilot_doc_contract_test.exs
  - test/threadline/brandbook_token_parity_test.exs
  - test/threadline/ci_all_dedup_contract_test.exs
  - test/threadline/ci_coverage_doc_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/credo_config_contract_test.exs
  - test/threadline/dialyzer_ignore_contract_test.exs
  - test/threadline/evaluating_threadline_doc_contract_test.exs
  - test/threadline/guide_graph_contract_test.exs
  - test/threadline/operator_surface/breadcrumb_test.exs
  - test/threadline/operator_surface/card_nesting_regression_test.exs
  - test/threadline/operator_surface/component_contract_test.exs
  - test/threadline/operator_surface/controllers/export_controller_test.exs
  - test/threadline/operator_surface/copy_contract_test.exs
  - test/threadline/operator_surface/data_state_mapping_wave0_test.exs
  - test/threadline/operator_surface/exports_doc_contract_test.exs
  - test/threadline/operator_surface/exports_mix_parity_test.exs
  - test/threadline/operator_surface/gating_test.exs
  - test/threadline/operator_surface/live/actor_live_test.exs
  - test/threadline/operator_surface/live/coverage_live_test.exs
  - test/threadline/operator_surface/live/evidence_live_test.exs
  - test/threadline/operator_surface/live/export_status_live_test.exs
  - test/threadline/operator_surface/live/policy_redaction_live_test.exs
  - test/threadline/operator_surface/live/retention_history_live_test.exs
  - test/threadline/operator_surface/live/row_history_live_test.exs
  - test/threadline/operator_surface/live/start_live_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
  - test/threadline/operator_surface/operator_surface_fixture_contract_test.exs
  - test/threadline/operator_surface/page_header_test.exs
  - test/threadline/operator_surface/pager_test.exs
  - test/threadline/operator_surface/rendered_output_contract_test.exs
  - test/threadline/operator_surface/skip_link_test.exs
  - test/threadline/operator_surface/stress_router_test.exs
  - test/threadline/operator_surface/style_byte_lock_test.exs
  - test/threadline/operator_surface/style_contract_test.exs
  - test/threadline/operator_surface/timeline_browse_doc_contract_test.exs
  - test/threadline/operator_surface/transaction_live_test.exs
  - test/threadline/operator_surface/ui_form_policy_contract_test.exs
  - test/threadline/operator_surface/ui_stress_test.exs
  - test/threadline/operator_surface/ui_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/release_artifact_contract_test.exs
  - test/threadline/source_family_test.exs
  - test/threadline/source_size_contract_test.exs
  - test/threadline/storage_schema_migration_contract_test.exs
  - test/threadline/test_structure_contract_test.exs
findings:
  critical: 0
  warning: 2
  info: 5
  total: 7
status: issues_found
---

# Phase 204: Code Review Report

**Reviewed:** 2026-09-23
**Depth:** standard
**Files Reviewed:** 143
**Status:** issues_found

## Summary

Scope: the `lib/` refactor commits (5d8b97d7^..HEAD). I checked every lib commit with `git show --color-moved=plain --color-moved-ws=allow-indentation-change` and read only the lines git did not mark as moved. Every hand-edited restructuring got a clause-by-clause check against the original. That covers the retention `window_seconds!/3` clause order, `ChangeDiff.normalize_op!/1`, `Evidence.normalize_subject!/1`, `FilterParams.actor_ref_from/2`, `Query.Cursors` (paging window, trim and edge cursors), the `Orchestrator.run_job/3` rescue scope, `Auth.reconcile_actor/3`, the `Router` macro guard hygiene, `Presentation.status_label/1`, the TimelineLive `handle_params/3` `with` flattening, `ActorLive.activity_presence/4`, the export ownership check, and the `mix threadline.export` validation order. None of these changed behaviour, error messages or clause precedence. The UI split kept its content: the multiset of stripped lines in the old `ui.ex` matches the six `UI.*` files, apart from module headers and the `<.x>` to `<Family.x>` call rewrites. No `attr`/`slot` declarations or defaults were lost. The CSS pivot is sound. `@segments` is explicit, every segment is an `@external_resource`, `Phoenix.HTML.raw` is applied, and the `.css` files ship in the Hex tarball. The widened `exclude_patterns` in `mix.exs` cover the new `stress_live/` and `mechanical_checker/` children, and no packaged module references them.

Verification I ran: `MIX_ENV=test mix compile --warnings-as-errors` is clean. `mix compile --no-optional-deps --warnings-as-errors` is clean, so `ExportController.Encoding` relies only on the non-optional `plug`. The full `mix test` run had 1778 tests with 0 failures. `mix credo --strict` found no issues. The byte lock, the governance migration sha pins (committed before the refactor, in `3c749d67`) and the storage-schema contracts are green. `test/support/operator_surface_case.ex` does not leak env between async tests. Env is keyed per endpoint module, which is unique per file. It is written before `start_supervised!` and restored in `on_exit`, which ExUnit runs after supervised children are stopped.

I found no BLOCKER. The defects are in the new contract gates. One can be bypassed and one can fail with a misleading message. A few stale-prose and quality items follow as Info.

## Warnings

### WR-01: Size gate measures every keyword-`do:` clause as 1 line, so a 200-line function passes the 120-line limit

**File:** `test/threadline/source_size_contract_test.exs:252-261`
**Issue:** `collect_clause/2` takes a clause's length from `meta[:end]` and falls back to `1` when it is `nil`. `Code.string_to_quoted(..., token_metadata: true)` emits `:end` only for `do ... end` blocks. A keyword-form clause never has it. I checked this directly: the source `def f(assigns),\n do: ~H"""` followed by 200 lines of markup and `"""` parses to def metadata `[end_of_expression: [line: 204, ...], line: 2, column: 3]`, with no `:end`. The gate records that clause as 1 line. So a `render/1`, or any function written as `def x(...), do: <multi-line expression>`, passes the function-length rule however long it is. That is exactly the kind of dodge the contract's moduledoc and D-08 rule out. The self-tests use only `do ... end` clauses (`clause/4`), so the hole isn't exercised. The tree has no violations today (only two short `do:` bodies in `transaction_live.ex:326,331`), but the gate enforces less than it claims.
**Fix:** Measure keyword clauses by their last line. Use `end_of_expression` when it is present, or walk the body for the maximum `:line`/`:closing`/`:end_line`. Add a planted-violation self-test.
```elixir
length =
  cond do
    end_meta = meta[:end] -> end_meta[:line] - meta[:line] + 1
    eoe = meta[:end_of_expression] -> eoe[:line] - meta[:line] + 1
    true -> max_line(node) - meta[:line] + 1
  end
```
```elixir
test "a keyword do: clause spanning 121 lines is measured, not counted as 1" do
  body = String.duplicate("    <p>x</p>\n", 119)
  src = "defmodule S do\n  def f(assigns),\n    do: ~H\"\"\"\n" <> body <> "    \"\"\"\nend\n"
  assert %{{"lib/kw.ex", :f, 1} => n} = measure_functions([{"lib/kw.ex", src}])
  assert n > 120
end
```

### WR-02: The ci.all dedup guard raises "alias cycle" on a legal self-referencing `test` alias

**File:** `test/threadline/ci_all_dedup_contract_test.exs:218-240`
**Issue:** `expand/3` treats any string whose first word names an alias as a recursive alias reference. Mix doesn't work that way: inside an alias, a step with the alias's own name runs the underlying task. The Phoenix generator's default `test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]` relies on this. If that common alias is added to `mix.exs`, the real-tree tests fail with `ArgumentError: alias cycle: verify.test -> test -> test`. The chain is `ci.all` -> `verify.test` -> `"test"` -> the `test:` alias -> `"test"`, which is already in `seen`. The error blames the wrong thing and makes it look as though `ci.all` is miswired. The synthetic cycle test (`"a.b" <-> "c.d"`) passes, but no test covers the self-reference case.
**Fix:** When the step's head equals the alias currently being expanded (the most recent `seen` entry), treat it as the underlying task, a leaf, instead of recursing. Add a self-test.
```elixir
cond do
  seen != [] and head == hd(seen) -> [{Enum.reverse(seen), step}]   # alias invoking its own task
  head in seen -> raise ArgumentError, "alias cycle: ..."
  ...
end
```
```elixir
test "an alias that runs its own underlying task is not a cycle" do
  synthetic = [test: ["ecto.create --quiet", "test"], "verify.test": ["test"], "ci.all": ["verify.test"]]
  assert validate_single_test_step(synthetic) == :ok
end
```

## Info

### IN-01: Storybook doc prose still names the deleted `Threadline.OperatorSurface.UI` module and the old `UI.fn` call forms

**File:** `examples/threadline_phoenix/storybook/forms/field.story.exs:10-19`, `examples/threadline_phoenix/storybook/overlays/modal.story.exs:18-19`
**Issue:** The rendered `doc/0` text says "the current private Threadline.OperatorSurface.UI source" and lists `UI.field`, `UI.label`, `UI.help`, `UI.error`, `UI.error_summary`, `UI.field_group`, `UI.radio`, `UI.switch`, `UI.combobox`, `UI.modal`, `UI.drawer`, `UI.toast`, `UI.tooltip`, `UI.popover`, `UI.dropdown`, `UI.accordion`, `UI.tabs` and `UI.segmented_control`. None of these exist after the family split. They are now `UI.Form.*`, `UI.Overlay.*` and `UI.Page.*`. Every other storybook call site was migrated, and the `alias Threadline.OperatorSurface.UI` lines still resolve as namespace prefixes.
**Fix:** Change the prose to the family-qualified names (`UI.Form.field`, `UI.Overlay.modal`, `UI.Page.tabs`, ...) and to "the private `Threadline.OperatorSurface.UI.*` component families".

### IN-02: The credo register can only name a successor that is a completed phase

**File:** `test/threadline/credo_config_contract_test.exs:37`, `:79-84`, `:403`
**Issue:** `@successor "Phase 204 / STRUCT-07"` is hardwired. The real-tree test asserts every register entry's successor `== @successor`, and a missing key defaults to it. Now that the register is drained, a future reviewed disable can't name a real successor phase unless someone edits the constant. Leaving it unchanged would record a false successor that points at this finished phase. The moduledoc says a new entry needs "a named successor", which the code doesn't allow.
**Fix:** Drop the equality assertion. Require each successor to be a non-blank string that differs from the drained phase's label, or keep an explicit allowlist of open successors.

### IN-03: The test-structure scan only sees a bare `use Phoenix.Endpoint` / `use Phoenix.Router` at the start of a line

**File:** `test/threadline/test_structure_contract_test.exs:27-28`
**Issue:** `~r/^\s*use Phoenix\.Endpoint\b/m` misses `use(Phoenix.Endpoint, ...)`, an aliased form (`alias Phoenix.Endpoint, as: E` then `use E`), and `Phoenix.Endpoint.__using__` reached through a local wrapper macro. A hand-rolled endpoint in any of those forms passes the "only in the shared template" rule. The formatter's `locals_without_parens` makes the paren form unlikely, so this is low risk.
**Fix:** Scan the AST instead: use `Code.string_to_quoted` and look for `{:use, _, [{:__aliases__, _, [:Phoenix, :Endpoint]} | _]}`, with a one-level alias-resolution pass. Or at minimum widen the regex to `use\(?\s*Phoenix\.(Endpoint|Router)\b`.

### IN-04: `MechanicalChecker` and `MechanicalChecker.Contrast` call each other

**File:** `lib/threadline/operator_surface/mechanical_checker/contrast.ex:37-39`
**Issue:** The parent calls `Contrast.check/2`, and `Contrast` calls back into the parent's public `contrast_ratio/2` and `relative_luminance/1`. It is a runtime edge, so `verify.xref_cycles` (compile-connected only) allows it, but the child depends on its own caller. The comment justifies it as keeping the gamma-2.4 linearization in one place, but a leaf module would do that without the cycle.
**Fix:** Move `relative_luminance/1` and `contrast_ratio/2` into `Contrast` or `Parsing`, and have the parent delegate to them or call them. Keep the parent's public names if the meta-test pins them.

### IN-05: The same atom-key schema matcher now exists as two private helpers

**File:** `lib/threadline/operator_surface/live/row_history_component.ex:156-160`, `lib/threadline/operator_surface/live/timeline_live/helpers.ex:115-119`
**Issue:** The two register drains (commits `34b8c8a9` and `3c629670`) extracted the same inline lambda twice: `schema_for_atom_key/2` and `atom_key_schema/2`. Their bodies are identical (`if Atom.to_string(key) == table, do: schema`). The surrounding `schema_for_table` lookups were already duplicated. The extraction turned that duplication into two named functions that can drift apart.
**Fix:** Move the table-to-schema lookup into one shared internal helper, for example next to `Threadline.OperatorSurface.RowHistoryPath`, or a small `@moduledoc false` module, and call it from both places.

---

_Reviewed: 2026-09-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
