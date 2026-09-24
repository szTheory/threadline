---
phase: 204-structure
verified: 2026-09-24T00:00:00Z
status: gaps_found
score: 5/6 must-haves verified
covered_files:
  - ".github/workflows/ci.yml"
  - ".github/workflows/release.yml"
  - ".planning/REQUIREMENTS.md"
  - ".planning/phases/204-structure/204-01-PLAN.md"
  - ".planning/phases/204-structure/204-01-SUMMARY.md"
  - ".planning/phases/204-structure/204-02-PLAN.md"
  - ".planning/phases/204-structure/204-02-SUMMARY.md"
  - ".planning/phases/204-structure/204-03-PLAN.md"
  - ".planning/phases/204-structure/204-03-SUMMARY.md"
  - ".planning/phases/204-structure/204-04-PLAN.md"
  - ".planning/phases/204-structure/204-04-SUMMARY.md"
  - ".planning/phases/204-structure/204-05-PLAN.md"
  - ".planning/phases/204-structure/204-05-SUMMARY.md"
  - ".planning/phases/204-structure/204-06-PLAN.md"
  - ".planning/phases/204-structure/204-06-SUMMARY.md"
  - ".planning/phases/204-structure/204-07-PLAN.md"
  - ".planning/phases/204-structure/204-07-SUMMARY.md"
  - ".planning/phases/204-structure/204-08-PLAN.md"
  - ".planning/phases/204-structure/204-08-SUMMARY.md"
  - ".planning/phases/204-structure/204-09-PLAN.md"
  - ".planning/phases/204-structure/204-09-SUMMARY.md"
  - ".planning/phases/204-structure/204-10-PLAN.md"
  - ".planning/phases/204-structure/204-10-SUMMARY.md"
  - ".planning/phases/204-structure/204-11-PLAN.md"
  - ".planning/phases/204-structure/204-11-SUMMARY.md"
  - ".planning/phases/204-structure/204-12-PLAN.md"
  - ".planning/phases/204-structure/204-12-SUMMARY.md"
  - ".planning/phases/204-structure/204-13-PLAN.md"
  - ".planning/phases/204-structure/204-13-SUMMARY.md"
  - ".planning/phases/204-structure/204-14-PLAN.md"
  - ".planning/phases/204-structure/204-14-SUMMARY.md"
  - ".planning/phases/204-structure/204-15-PLAN.md"
  - ".planning/phases/204-structure/204-15-SUMMARY.md"
  - "CONTRIBUTING.md"
  - "DESIGN-SYSTEM.md"
  - "bin/verify-bump-rehearsal"
  - "examples/threadline_phoenix/e2e/critic/scorecard.ts"
  - "examples/threadline_phoenix/e2e/tests/operator-component-contracts.spec.ts"
  - "examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts"
  - "examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts"
  - "examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts"
  - "examples/threadline_phoenix/storybook/data_display/data_table.story.exs"
  - "examples/threadline_phoenix/storybook/forms/field.story.exs"
  - "examples/threadline_phoenix/storybook/foundations/index.story.exs"
  - "examples/threadline_phoenix/storybook/groups/operator_groups.story.exs"
  - "examples/threadline_phoenix/storybook/overlays/modal.story.exs"
  - "examples/threadline_phoenix/storybook/patterns/operator_patterns.story.exs"
  - "examples/threadline_phoenix/storybook/primitives/button.story.exs"
  - "examples/threadline_phoenix/storybook/states/data_state.story.exs"
  - "examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs"
  - "guides/adoption-pilot-backlog.md"
  - "guides/configuration-and-commands.md"
  - "guides/evaluating-threadline.md"
  - "lib/mix/tasks/critic.measure.ex"
  - "lib/mix/tasks/threadline.export.ex"
  - "lib/mix/tasks/threadline.install.ex"
  - "lib/mix/tasks/threadline.verify_coverage.ex"
  - "lib/threadline/audit.ex"
  - "lib/threadline/change_diff.ex"
  - "lib/threadline/critic_trust/krippendorff_alpha.ex"
  - "lib/threadline/critic_trust/measure.ex"
  - "lib/threadline/critic_trust/rank_metrics.ex"
  - "lib/threadline/evidence.ex"
  - "lib/threadline/export/cleanup_task.ex"
  - "lib/threadline/export/orchestrator.ex"
  - "lib/threadline/governance/migration.ex"
  - "lib/threadline/operator_surface/auth.ex"
  - "lib/threadline/operator_surface/controllers/export_controller.ex"
  - "lib/threadline/operator_surface/controllers/export_controller/encoding.ex"
  - "lib/threadline/operator_surface/live/actor_live.ex"
  - "lib/threadline/operator_surface/live/coverage_live.ex"
  - "lib/threadline/operator_surface/live/evidence_live.ex"
  - "lib/threadline/operator_surface/live/export_status_live.ex"
  - "lib/threadline/operator_surface/live/export_status_live/components.ex"
  - "lib/threadline/operator_surface/live/policy_redaction_live.ex"
  - "lib/threadline/operator_surface/live/retention_history_live.ex"
  - "lib/threadline/operator_surface/live/row_history_component.ex"
  - "lib/threadline/operator_surface/live/row_history_live.ex"
  - "lib/threadline/operator_surface/live/start_live.ex"
  - "lib/threadline/operator_surface/live/stress_live.ex"
  - "lib/threadline/operator_surface/live/stress_live/paths.ex"
  - "lib/threadline/operator_surface/live/stress_live/refute.ex"
  - "lib/threadline/operator_surface/live/stress_live/sections.ex"
  - "lib/threadline/operator_surface/live/timeline_live.ex"
  - "lib/threadline/operator_surface/live/timeline_live/filters.ex"
  - "lib/threadline/operator_surface/live/timeline_live/helpers.ex"
  - "lib/threadline/operator_surface/live/transaction_live.ex"
  - "lib/threadline/operator_surface/mechanical_checker.ex"
  - "lib/threadline/operator_surface/mechanical_checker/accent_hue.ex"
  - "lib/threadline/operator_surface/mechanical_checker/contrast.ex"
  - "lib/threadline/operator_surface/mechanical_checker/parsing.ex"
  - "lib/threadline/operator_surface/mechanical_checker/ratchet_metrics.ex"
  - "lib/threadline/operator_surface/mechanical_checker/scorecards.ex"
  - "lib/threadline/operator_surface/mechanical_checker/token_conformance.ex"
  - "lib/threadline/operator_surface/presentation.ex"
  - "lib/threadline/operator_surface/router.ex"
  - "lib/threadline/operator_surface/stress_fixtures.ex"
  - "lib/threadline/operator_surface/style.ex"
  - "lib/threadline/operator_surface/style/01_tokens.css"
  - "lib/threadline/operator_surface/style/02_base_shell.css"
  - "lib/threadline/operator_surface/style/03_page_home.css"
  - "lib/threadline/operator_surface/style/04_controls.css"
  - "lib/threadline/operator_surface/style/05_feedback.css"
  - "lib/threadline/operator_surface/style/06_layout_primitives.css"
  - "lib/threadline/operator_surface/style/07_find_detail.css"
  - "lib/threadline/operator_surface/style/08_overlays_motion.css"
  - "lib/threadline/operator_surface/style/09_responsive.css"
  - "lib/threadline/operator_surface/ui/actions.ex"
  - "lib/threadline/operator_surface/ui/data.ex"
  - "lib/threadline/operator_surface/ui/display.ex"
  - "lib/threadline/operator_surface/ui/form.ex"
  - "lib/threadline/operator_surface/ui/overlay.ex"
  - "lib/threadline/operator_surface/ui/page.ex"
  - "lib/threadline/policy/redaction_presenter.ex"
  - "lib/threadline/query.ex"
  - "lib/threadline/query/cursors.ex"
  - "lib/threadline/query/filter_params.ex"
  - "lib/threadline/retention/policy.ex"
  - "lib/threadline/semantics/actor_ref.ex"
  - "mix.exs"
  - "test/fixtures/style/README.md"
  - "test/fixtures/style/operator_surface.css"
  - "test/support/getting_started_fixtures.ex"
  - "test/support/operator_surface_case.ex"
  - "test/support/ref_copy_contract.ex"
  - "test/support/source_family.ex"
  - "test/support/style_source.ex"
  - "test/threadline/adoption_pilot_doc_contract_test.exs"
  - "test/threadline/brandbook_token_parity_test.exs"
  - "test/threadline/ci_all_dedup_contract_test.exs"
  - "test/threadline/ci_coverage_doc_contract_test.exs"
  - "test/threadline/ci_topology_contract_test.exs"
  - "test/threadline/ci_workflow_parity_contract_test.exs"
  - "test/threadline/credo_config_contract_test.exs"
  - "test/threadline/dialyzer_ignore_contract_test.exs"
  - "test/threadline/evaluating_threadline_doc_contract_test.exs"
  - "test/threadline/guide_graph_contract_test.exs"
  - "test/threadline/operator_surface/breadcrumb_test.exs"
  - "test/threadline/operator_surface/card_nesting_regression_test.exs"
  - "test/threadline/operator_surface/component_contract_test.exs"
  - "test/threadline/operator_surface/controllers/export_controller_test.exs"
  - "test/threadline/operator_surface/copy_contract_test.exs"
  - "test/threadline/operator_surface/data_state_mapping_wave0_test.exs"
  - "test/threadline/operator_surface/exports_doc_contract_test.exs"
  - "test/threadline/operator_surface/exports_mix_parity_test.exs"
  - "test/threadline/operator_surface/gating_test.exs"
  - "test/threadline/operator_surface/live/actor_live_test.exs"
  - "test/threadline/operator_surface/live/coverage_live_test.exs"
  - "test/threadline/operator_surface/live/evidence_live_test.exs"
  - "test/threadline/operator_surface/live/export_status_live_test.exs"
  - "test/threadline/operator_surface/live/policy_redaction_live_test.exs"
  - "test/threadline/operator_surface/live/retention_history_live_test.exs"
  - "test/threadline/operator_surface/live/row_history_live_test.exs"
  - "test/threadline/operator_surface/live/start_live_test.exs"
  - "test/threadline/operator_surface/live/timeline_live_test.exs"
  - "test/threadline/operator_surface/operator_surface_fixture_contract_test.exs"
  - "test/threadline/operator_surface/page_header_test.exs"
  - "test/threadline/operator_surface/pager_test.exs"
  - "test/threadline/operator_surface/rendered_output_contract_test.exs"
  - "test/threadline/operator_surface/skip_link_test.exs"
  - "test/threadline/operator_surface/stress_router_test.exs"
  - "test/threadline/operator_surface/style_byte_lock_test.exs"
  - "test/threadline/operator_surface/style_contract_test.exs"
  - "test/threadline/operator_surface/timeline_browse_doc_contract_test.exs"
  - "test/threadline/operator_surface/transaction_live_test.exs"
  - "test/threadline/operator_surface/ui_form_policy_contract_test.exs"
  - "test/threadline/operator_surface/ui_stress_test.exs"
  - "test/threadline/operator_surface/ui_test.exs"
  - "test/threadline/public_surface_contract_test.exs"
  - "test/threadline/release_artifact_contract_test.exs"
  - "test/threadline/source_family_test.exs"
  - "test/threadline/source_size_contract_test.exs"
  - "test/threadline/storage_schema_migration_contract_test.exs"
  - "test/threadline/test_structure_contract_test.exs"
covered_digest: "v1:sha256:e1ef732900a8a3a48eb3f41f416fb892da9674a3d9af6b345471ca99d687a580"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Separator comments no longer stand in for module or function boundaries in `lib/` (ROADMAP SC-2 second half, STRUCT-04)"
    status: partial
    reason: "Five separator-banner comments remain in lib/. The banner gate cannot see them: its regex `^\\s*#\\s*(-{3,}|={3,}|─{3,}|\\*{3,})` needs at least three rule characters directly after `#`, and these banners open with only two (`# ── Title ────…`). As a result `@banner_exceptions == %{}` passes, and 204-12-SUMMARY's claim that 'any `# ───` rule comment in lib/**/*.ex now fails' overstates what the gate checks. The banners predate the phase and were not in the D-11 inventory. Phase 204 did touch both files (204-07 register drains db9f172b and c5bf57ef) but left the banners in place."
    artifacts:
      - path: "lib/mix/tasks/critic.measure.ex"
        issue: "4 banners at :44 `# ── Source + provenance ──…`, :122 `# ── Readers ──…`, :172 `# ── Repository-only path and decode boundary ──…`, :431 `# ── Output ──…`"
      - path: "lib/threadline/critic_trust/krippendorff_alpha.ex"
        issue: "1 banner at :107 `# ── Private helpers ──…`"
      - path: "test/threadline/source_size_contract_test.exs"
        issue: "The `@banner` regex misses the two-leading-rule-char form `# ── Title ────`, and no planted-violation self-test covers it"
    missing:
      - "Remove the 5 banners. Replace each with a real boundary, or delete it where its section is one cohesive clause group; any informative title can stay as a plain comment without rule characters (D-11 rule)"
      - "Widen the banner detector to match a trailing rule run as well as a leading one, e.g. `~r/^\\s*#.*(-{3,}|={3,}|─{3,}|\\*{3,})\\s*$/u`. At HEAD this matches exactly these 5 lines and nothing else in lib/**/*.ex. Also add a synthetic self-test for `# ── Title ────`"
advisory:
  - finding: "WR-01: the function-length gate counts a keyword-form `def f(...), do: <expr>` clause as 1 line (`meta[:end]` is nil and it falls back to 1), so a long `do: ~H\"\"\"…\"\"\"` body would pass the 120-line rule"
    category: other
    reason: "A hardening item, not a STRUCT-03 failure. An independent AST measure over all 2033 def/defp/defmacro clauses in lib/ (body max line including sigil heredoc newlines, :closing and :end_of_expression) finds the longest clause is 114 lines (evidence_live render/1). The longest of the 787 keyword-form clauses is 7 lines, and no `do: \"\"\"`/`do: ~X\"\"\"` heredoc body exists in lib/. STRUCT-03 is true of the delivered tree. The hole only weakens protection against future regressions. Fix it with WR-01's end_of_expression/max-line measure and a planted keyword-clause self-test, ideally in the same change as the banner-regex fix, because both are about gate precision."
    evidence_status: "independent measurement at HEAD a61effc3; no violation present"
  - finding: "WR-02: ci_all_dedup_contract_test's `expand/3` raises 'alias cycle' when a legal alias invokes its own underlying task (e.g. `test: [\"ecto.create --quiet\", \"test\"]`)"
    category: other
    reason: "mix.exs has no such alias today, so the guard is correct against the current tree. This is a latent false-failure with a misleading message. Hardening only."
    evidence_status: "no failing case in the current tree"
---

# Phase 204: Structure Verification Report

**Phase Goal:** The largest files become legible — `style.ex` split behind an executable byte-hash lock, the render monsters extracted, separator comments replaced by real boundaries, shared test case templates adopted — without changing a byte of output, and with the redundant second definition of "which contract tests matter" deleted rather than preserved.
**Verified:** 2026-09-24 (HEAD a61effc3)
**Status:** gaps_found
**Re-verification:** No, this is the initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Emitted CSS is locked by a committed content hash gated in `ci.all`, and the style module is split into ordered, individually legible segments with the hash unchanged at every intermediate commit (SC-1, STRUCT-01/02) | ✓ VERIFIED | The golden `test/fixtures/style/operator_surface.css` was committed once (ef458852) and never modified. `@golden_sha256 c7baf51e…` and `@rendered_sha256 b10d6a2c…` show no +/- lines in any later diff. I independently recomputed `sha256("<style>" <> segments-in-@segments-order <> "</style>")` from git objects at the pivot (efbac2cd), at all 8 peels (864232ec…093d10c9), at the rename (fe3dfc5e) and at HEAD. All 11 equal `c7baf51ecd9b…ab4b`, the golden's sha. `style.ex` is 56 lines with an explicit `@segments ~w(01..09)`, one `@external_resource` per segment, `Phoenix.HTML.raw`, and no `Path.wildcard`. The 9 `.css` segments are 317–685 lines each. The lock runs in `verify.test`, which `ci.all` lists (mix.exs:191). style_byte_lock_test passed in my run. |
| 2 | No `lib/` file exceeds ~800 lines and no function ~120 lines, or the exception is named with a stated reason (SC-2a, STRUCT-03) | ✓ VERIFIED | Only one file in lib/ is over 800 lines: `stress_fixtures.ex` (980). It is the sole `@file_exceptions` entry, with the reason "declarative fixture data tables; excluded from the Hex package", and it is in mix.exs `exclude_patterns`. The next largest are sections.ex (706) and query.ex (745). `@function_exceptions == %{}`. My independent AST measure (sigil heredoc spans included, so it does not share WR-01's blind spot) puts the longest clause at 114 lines (evidence_live render/1), then 111 and 103. There are no `.heex` files, no `embed_templates` and no `defdelegate` facades in operator_surface. `ui.ex` is gone and split into 6 `UI.*` families. |
| 3 | Separator comments no longer stand in for module or function boundaries in `lib/` (SC-2b, STRUCT-04) | ✗ FAILED (partial) | The 42 inventoried `# ---`/`# ===` banners are gone and `@banner_exceptions == %{}`. But 5 box-drawing banners remain and the gate misses them: `lib/mix/tasks/critic.measure.ex:44,122,172,431` and `lib/threadline/critic_trust/krippendorff_alpha.ex:107` (`# ── Private helpers ────…`). The regex needs at least 3 rule characters right after `#`, and these banners open with 2. They are textbook section separators standing in for boundaries. See the gaps. |
| 4 | Test files share endpoint/router case templates from `test/support/`, except for documented deliberate differences (SC-3, STRUCT-05) | ✓ VERIFIED | `test/support/operator_surface_case.ex` defines Layouts, Router, Endpoint and Case. Outside that file, `use Phoenix.Endpoint` appears only in stress_router_test, and `use Phoenix.Router` only in router_test, stress_router_test and stress_router_prod_compile.exs. Those are exactly the allowlisted paths in test_structure_contract_test, each with a written reason and stale-entry detection. No other test defines `Layouts`/`root/1`. 19 test files use the templates. The contract passed in my run. (Review IN-03: the regex misses `use(Phoenix.Endpoint…)` and aliased forms. That is low risk, and no such form exists in test/.) |
| 5 | `ci.all` has no step that re-runs another step's assertions, and no second drift-prone definition of which contract tests matter (SC-4, STRUCT-06) | ✓ VERIFIED | `ci.all` (mix.exs:185-208) runs format, credo, compile, xref_cycles, compile_no_optional, verify.test, verify.threadline (coverage task, not tests), verify.example (the example app's own suite), Dialyzer and the browser lane. `verify.doc_contract` is deleted, and apart from a concatenated literal in the guards, no tracked file outside CHANGELOG/.planning names it. `verify.critic_trust` and `verify.mechanical` are out of ci.all but kept as focused aliases. The ci.yml "Doc contract tests" step is gone. `bin/verify-bump-rehearsal:381-398` derives the list with `find … | sort` and has a floor of 30. ci_all_dedup_contract_test and ci_topology_contract_test passed. |
| 6 | The credo structural ceiling is ratcheted from 42 to 0, or each remaining site names a post-v1.41 successor (SC-5, STRUCT-07) | ✓ VERIFIED | `@register %{}`, `@ceiling 0`, `@historical_max 46`. `grep -rn 'credo:disable\|credo:enable' lib test` returns nothing, and so does `grep 'Structural debt' lib`. `.credo.exs` is unchanged by the phase, with `disabled: []` and no threshold raise. The orchestrator's ci.all log shows `mix credo --strict` passing, and credo_config_contract_test passed in my run. |

**Score:** 5/6 truths verified (0 present but behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/threadline/operator_surface/style_byte_lock_test.exs` | golden + 2 sha pins, segment-order, orphan and external_resource checks | ✓ VERIFIED | 286 lines; the pins are unchanged since they were introduced |
| `test/fixtures/style/operator_surface.css` + `README.md` | golden bytes + bump procedure | ✓ VERIFIED | single commit; sha matches the pin |
| `lib/threadline/operator_surface/style.ex` + `style/0[1-9]_*.css` | ordered compile-time segments | ✓ VERIFIED | see truth 1 |
| `test/threadline/source_size_contract_test.exs` | file/function/banner/heex gate with a one-exception rest state | ⚠️ PARTIAL | file and function rules work for the tree. The banner regex misses the `# ── …` form (gap). Keyword-clause measurement is 1 line (WR-01, advisory) |
| `test/support/operator_surface_case.ex` | shared Layouts/Router/Endpoint/Case | ✓ VERIFIED | wired into 19 test files |
| `test/threadline/test_structure_contract_test.exs` | template adoption guard with an allowlist | ✓ VERIFIED | |
| `test/threadline/ci_all_dedup_contract_test.exs` | runtime alias-expansion guard | ✓ VERIFIED | WR-02 advisory |
| `test/threadline/credo_config_contract_test.exs` | register drained to 0 | ✓ VERIFIED | IN-02 (hardwired successor) is info only |
| `bin/verify-bump-rehearsal` | derived doc-contract list with a floor | ✓ VERIFIED | |
| `lib/threadline/operator_surface/ui/*.ex`, `mechanical_checker/*`, `stress_live/*`, `timeline_live/*`, `query/cursors.ex`, `export_controller/encoding.ex` | extracted modules | ✓ VERIFIED | all under the limits. Maintainer-only families are in `exclude_patterns` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| style_byte_lock_test | `Style.css/1`, `Style.segments/0`, golden | render + sha256 | WIRED | passed at HEAD |
| `Style` | `style/*.css` | `@external_resource` per segment + `File.read!` at compile time | WIRED | the test asserts every segment is an external resource |
| `ci.all` | style lock, size gate, structure, credo and dedup contracts | `verify.test` | WIRED | orchestrator log: 1778 tests, 0 failures |
| verify-bump-rehearsal | doc-contract files | `find … \| sort`, floor 30 | WIRED | |
| mix.exs `exclude_patterns` | stress_live/, mechanical_checker/, stress_fixtures | regex | WIRED | mix.exs:445-453 |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase contract gates are green at HEAD | `mix test` on style_byte_lock, source_size_contract, test_structure_contract, credo_config_contract, ci_all_dedup_contract, ci_topology_contract | 87 tests, 0 failures | ✓ PASS |
| CSS bytes identical at every split commit | recompute sha256 of `<style>`+segments+`</style>` from git objects at 11 commits | all `c7baf51e…ab4b` | ✓ PASS |
| No lib function over 120 lines, including keyword clauses | independent AST measure `/tmp/v204/measure.exs` | max 114 (keyword-form max 7) | ✓ PASS |
| No separator banners in lib | `grep -rnE '^\s*#.*(-{3,}\|={3,}\|─{2,}\|\*{3,})' lib --include='*.ex'` | 5 hits (critic.measure.ex ×4, krippendorff_alpha.ex ×1) | ✗ FAIL |
| Full gate | orchestrator `mix ci.all` log | exit 0; Dialyzer 0; no xref cycles; Playwright 318 passed / 26 skipped | ✓ PASS (log re-read) |
| Browser lane at the 8 known failures | orchestrator `verify.example_browser` log | 326/8/16; failures are exactly screenshot-regression :108, :115, :136, :145 on desktop and mobile | ✓ PASS (pre-existing baseline) |
| Screenshot baselines and sealed fixture corpus untouched | `git diff --stat 5d8b97d7^ HEAD -- …-snapshots test/fixtures/operator_surface` | empty | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED. The phase declares no `scripts/*/tests/probe-*.sh` probes.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| STRUCT-01 | 204-01 | CSS locked by a content hash gated in ci.all | ✓ SATISFIED | truth 1 |
| STRUCT-02 | 204-03 | style split, hash unchanged at every intermediate commit | ✓ SATISFIED | truth 1 (independently recomputed at 11 commits) |
| STRUCT-03 | 204-01, 03, 04, 05, 06, 08, 09, 10, 11, 15 | ≤800 lines per file, ≤120 per function, or a named exception | ✓ SATISFIED | truth 2. WR-01 is advisory |
| STRUCT-04 | 204-01, 04, 08, 11, 12, 15 | separator comments replaced by real boundaries in lib/ | ✗ BLOCKED (partial) | truth 3: 5 residual banners and a gate blind spot |
| STRUCT-05 | 204-13, 14 | shared endpoint/router templates | ✓ SATISFIED | truth 4 |
| STRUCT-06 | 204-02 | no duplicate ci.all steps, no second contract-test definition | ✓ SATISFIED | truth 5 |
| STRUCT-07 | 204-04, 07, 08, 09, 10, 11, 12, 15 | register drained to 0 | ✓ SATISFIED | truth 6 |

No orphaned requirements. REQUIREMENTS.md maps exactly STRUCT-01..07 to Phase 204, and every ID appears in at least one plan. REQUIREMENTS.md marks STRUCT-04 `[x]` Complete. That checkbox should be reopened until the gap closes.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| lib/mix/tasks/critic.measure.ex | 44, 122, 172, 431 | `# ── Title ────` section banner | 🛑 Blocker (for STRUCT-04) | separator comments stand in for boundaries. Maintainer-only file, not packaged |
| lib/threadline/critic_trust/krippendorff_alpha.ex | 107 | `# ── Private helpers ────` | 🛑 Blocker (for STRUCT-04) | same |
| test/threadline/source_size_contract_test.exs | 38, 252-261 | banner regex blind spot; keyword clause = 1 line | ⚠️ Warning | gate enforces less than its moduledoc claims |
| examples/threadline_phoenix/storybook/forms/field.story.exs, overlays/modal.story.exs | doc prose | names the retired `UI.field`/`UI.modal` forms (review IN-01) | ℹ️ Info | stale prose. The plan deliberately left `doc/0` prose unedited |

No TBD/FIXME/XXX debt markers appear in the phase-modified lib or test files (grep was clean).

### WR-01 Judgment (requested)

WR-01 is an advisory hardening item. It does not undermine STRUCT-03 as delivered. STRUCT-03 is a claim about the tree: no function in lib/ is roughly 120 lines or longer without a named exception. I checked that claim without relying on the gate. My AST measure computes each clause's span as the maximum of `:line`, `:end`, `:closing` and `:end_of_expression` over the whole subtree, plus the newline count of any sigil heredoc. It found no clause over 114 lines, and the longest keyword-form clause is 7 lines. There is no `do: """` or `do: ~H"""` heredoc body anywhere in lib/. So no oversized function is hiding behind the blind spot. What WR-01 shows is that the gate would not catch a future long keyword clause, which is a durability weakness in the regression guard rather than a missed outcome. It should be fixed with WR-01's `end_of_expression`/max-line measure and a planted self-test, ideally in the same gap-closure change as the banner regex, because both are gate-precision defects in the same file.

The banner finding is different, and it is a blocker. The separators it describes are in the tree now, so the STRUCT-04 outcome itself is false today, not just weakly guarded.

### Human Verification Required

None. Rendered-output equality is covered by the byte lock, the contract tests and the orchestrator's browser-lane log at the known 8 failures.

### Gaps Summary

The phase delivered almost all of its goal, and the evidence is independent. The CSS byte lock is real. It held at every intermediate split commit, which I recomputed from git objects rather than taking from the summaries. The render monsters are carved to 114 lines or fewer. `ui.ex`, `mechanical_checker`, `timeline_live` and `stress_live` are split into legible families. The single file exception is named and justified. The shared test templates are adopted and guarded. `verify.doc_contract` is deleted and the rehearsal list is derived. The Credo register is at 0 with no suppressions left.

One gap remains, and its root cause is the definition of a separator banner. The D-11 inventory and the gate's regex (`#\s*` followed by at least 3 rule characters) both missed the box-drawing form `# ── Title ────…`. As a result, 5 section banners survive in lib/: 4 in `lib/mix/tasks/critic.measure.ex` and 1 in `lib/threadline/critic_trust/krippendorff_alpha.ex`. The gate still reports zero-tolerance, and 204-12-SUMMARY overstates it. The fix is small: remove the 5 banners by the D-11 rule, then widen `@banner` to catch a trailing rule run and add a self-test for that form. At HEAD the widened regex matches only these 5 lines, so it adds no false positives. No later milestone phase covers this, so it cannot be deferred.

---

_Verified: 2026-09-24_
_Verifier: Claude (gsd-verifier)_
