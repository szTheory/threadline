---
phase: 204-structure
verified: 2026-09-24T05:10:00Z
status: passed
score: 6/6 must-haves verified
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
  - ".planning/phases/204-structure/204-16-PLAN.md"
  - ".planning/phases/204-structure/204-16-SUMMARY.md"
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
  - "lib/threadline/critic_trust/repository_boundary.ex"
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
covered_digest: "v1:sha256:d25235718134ecc248781a2fffc7ff52d50b88137dd76edb7a258eb87fe0acdb"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "Separator comments no longer stand in for module or function boundaries in lib/ (STRUCT-04): the 5 box-rule banners are gone and the gate now catches that form"
  gaps_remaining: []
  regressions: []
advisory:
  - finding: "WR-03: the widened @banner regex still misses other banner shapes: `# -- Title --`, `# == Title ==`, `# ═══ Title ═══`, `# ━━━━`, `#####…`, `## ─── Title`. I probed each one against the literal regex and every one returned false."
    category: other
    reason: "This is a robustness gap in the regression guard, not a violation in the tree. An AST scan of all 861 comments in the 126 lib/**/*.ex files, using a much broader detector (a leading run of 2+ of any of - = * ─ ━ ═ _ ~ + #, a trailing run of 2+, or ###+), finds 0 banners. Its only 3 hits are prose that begins or ends with a `--tl-*` CSS custom property. The same scanner, run on the pre-fix files at 5df40009, found exactly the 5 known banners, so it is calibrated. To resolve: widen the regex as WR-03 proposes and plant the missed shapes as positives."
    evidence_status: "none provided (no offending comment exists in lib/ at HEAD 759f2820)"
  - finding: "IN-06: the trailing-rule branch flags prose that ends in a rule run (`# see table below ---`)"
    category: other
    reason: "A false positive fails loudly, so nothing can hide behind it. The moduledoc wording overstates the exemption."
    evidence_status: "probe confirmed; no such comment in lib/"
  - finding: "WR-02 (carried): ci_all_dedup_contract_test expand/3 raises 'alias cycle' on a legal self-referencing alias"
    category: other
    reason: "mix.exs has no such alias, so this is a latent false failure only"
    evidence_status: "no failing case in the current tree"
---

# Phase 204: Structure Verification Report

**Phase Goal:** Make the largest files legible without changing a byte of output. `style.ex` is split behind an executable byte-hash lock, the render monsters are extracted, separator comments are replaced by real boundaries, and the shared test case templates are adopted. The redundant second definition of "which contract tests matter" is deleted rather than preserved.
**Verified:** 2026-09-24 (HEAD 759f2820)
**Status:** passed
**Re-verification:** Yes. This follows gap-closure plan 204-16. The prior report (f045ce28) was gaps_found, 5/6.

## Re-verification

**Previous gap (f045ce28):** STRUCT-04 was partial. Five `# ── Title ────…` banners remained:
- `lib/mix/tasks/critic.measure.ex:44, :122, :172, :431`
- `lib/threadline/critic_trust/krippendorff_alpha.ex:107`

The `@banner` regex could not see them because it needed at least 3 rule characters right after `#`, and it had no self-test for that form.

**Now: CLOSED.** The evidence below comes from my own runs.

- **The five banners are gone.** I did not rely on grep for this. My AST comment scan (`Code.string_to_quoted_with_comments` over all 126 `lib/**/*.ex` files, 861 comments) finds 0 matches for the gate regex. I also ran a much broader detector: a leading 2+ run of any of `- = * ─ ━ ═ _ ~ + #`, a trailing 2+ run, or `###+`. It found only 3 hits, all prose starting or ending with `--tl-*` custom property names (`stress_live/refute.ex:27,116,211`). A codepoint grep for any box-drawing or block character (U+2500–U+259F) in lib/**/*.ex returns nothing. Title-only section-header comments (`# Private helpers` style) also return nothing.
- **The scanner is calibrated.** I ran the same scanner on the pre-fix `critic.measure.ex` and `krippendorff_alpha.ex` from 5df40009. It reports exactly the 5 known banners (:44, :122, :172, :431, :107) and nothing else.
- **The boundary is real.** The fifth section became `Threadline.CriticTrust.RepositoryBoundary` (`lib/threadline/critic_trust/repository_boundary.ex`, 267 lines). `critic.measure.ex` aliases it and calls `RepositoryBoundary.*` at :24–:71 and beyond. The new module is registered in `public_surface_contract_test.exs:11` (`@hidden_modules`) and `release_artifact_contract_test.exs:174` (`@maintainer_only_paths`). `critic_trust_test.exs` exercises it end to end, including traversal, symlink, overlap and interrupted-write cases, and that test passed in my run. The other four sections were deleted as cohesive groups. `krippendorff_alpha.ex` keeps its explanatory prose comment and drops the rule, which honours D-11.
- **The gate is widened and self-tested.** `source_size_contract_test.exs:45` now holds the two-branch regex. The planted test "a titled banner is counted whether the rule leads or trails…" exists, `@banner_exceptions %{}` is unchanged, and `@source_glob` is still `lib/**/*.ex`, so the gate was not weakened.
- **Scope held.** `git diff --stat 5df40009 HEAD -- lib/threadline/operator_surface test/fixtures mix.exs examples` is empty. The whole 204-16 code diff is 6 files: critic.measure.ex, krippendorff_alpha.ex, repository_boundary.ex, and three test files.
- **WR-01 (prior advisory) is resolved.** Planted tests at :152 and :170 cover keyword-form clauses measured to `end_of_expression`. The real tree still passes with `@function_exceptions %{}`.

## Judgment on WR-03 (the reviewer's residual blind spots)

I confirmed WR-03 by probing the literal regex. `# -- Private helpers --`, `# == Section ==`, `# ═══ Section ═══`, `# ━━━━━━━━━━`, `#####…` and `## ─── Section` all return `false`. `# ── Title ────` returns `true`.

I measured the tree, and it contains **none** of these shapes (see the Re-verification section). STRUCT-04 reads "Separator comments no longer stand in for module or function boundaries in lib/". That is a claim about the codebase, and it is true at HEAD: no banner-shaped separator of any family exists in lib/**/*.ex.

WR-03 is about how well the regression guard holds up in the future. It is not a missed outcome, so I record it as **advisory, not blocking**. This is the same reasoning the prior report applied to WR-01. It differs from the original gap, where banners were actually present. I recommend a small follow-up: widen the regex and plant the missed shapes as positives, and resolve IN-06 in the same change.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Emitted CSS locked by a committed hash gated in ci.all; style split into ordered segments with the hash unchanged at every intermediate commit (SC-1, STRUCT-01/02) | ✓ VERIFIED | Regression check. style_byte_lock_test passed in my run. 204-16 touched no style, CSS or fixture file (empty diff). The prior report recomputed the hash at all 11 split commits. |
| 2 | No lib/ file over ~800 lines or function over ~120 lines without a named exception (SC-2a, STRUCT-03) | ✓ VERIFIED | source_size_contract_test passes. It now measures keyword clauses correctly (WR-01 fixed and self-tested). The only exception is still stress_fixtures.ex, and `@function_exceptions %{}`. The new files are 267 lines (repository_boundary) and 240 lines (critic.measure). |
| 3 | Separator comments no longer stand in for module/function boundaries in lib/ (SC-2b, STRUCT-04) | ✓ VERIFIED | 0 banners of any shape among the 861 AST comments (calibrated scanner). The gate is widened, self-tested and green with an empty exception map. The residual gate blind spots are advisory (WR-03). |
| 4 | Test files share endpoint/router templates from test/support/ except documented differences (SC-3, STRUCT-05) | ✓ VERIFIED | Regression check. test_structure_contract_test passed. test/support and those tests are unchanged since the prior verification. |
| 5 | ci.all has no step re-running another step's assertions and no second contract-test definition (SC-4, STRUCT-06) | ✓ VERIFIED | Regression check. mix.exs and the CI files are unchanged since the prior verification. |
| 6 | Credo structural ceiling ratcheted to 0 (SC-5, STRUCT-07) | ✓ VERIFIED | credo_config_contract_test passed. `grep -rn 'credo:disable\|credo:enable' lib test` still returns nothing, since 204-16 added no suppressions. 204-16-SUMMARY records `mix credo --strict` clean. |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/threadline/source_size_contract_test.exs` | widened banner gate, keyword-clause measure, planted self-tests | ✓ VERIFIED | 18 gate tests pass. The regex blind spots are advisory (WR-03) |
| `lib/threadline/critic_trust/repository_boundary.ex` | real module boundary for critic.measure's path/decode/atomic-write section | ✓ VERIFIED | wired from critic.measure.ex and registered in two enumeration contracts |
| `lib/mix/tasks/critic.measure.ex` | no banners, delegates to RepositoryBoundary | ✓ VERIFIED | 240 lines. The SUMMARY's "202 lines" is inaccurate (info only) |
| `lib/threadline/critic_trust/krippendorff_alpha.ex` | banner removed, prose kept | ✓ VERIFIED | :107 now opens with the explanatory comment |
| Prior-phase artifacts (style lock, operator_surface_case, dedup/credo/structure contracts, verify-bump-rehearsal) | unchanged | ✓ VERIFIED | regression check; tests green |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| `@banner` | `count_banners/1` over parsed comments → `validate_banners/2` with `@banner_exceptions %{}` | verify.test in ci.all | WIRED |
| `Mix.Tasks.Critic.Measure.run/1` | `Threadline.CriticTrust.RepositoryBoundary` | alias plus qualified calls; critic_trust_test end to end | WIRED |
| `collect_clause/2` (end_of_expression) | `validate_functions/2` against `@function_limit 120` | planted tests :152, :170 | WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase contract gates plus the critic boundary | `DB_PORT=5433 … mix test` on source_size, public_surface, release_artifact, operator_surface/critic_trust, critic_trust/, credo_config, test_structure, style_byte_lock | 170 tests, 0 failures | ✓ PASS |
| Compile gate | `mix compile --force --warnings-as-errors` | 126 files compiled, no warnings | ✓ PASS |
| No banner-shaped comments in lib | AST scan `/tmp/v204r/scan.exs` (broad detector, calibrated on 5df40009 files) | 0 banners; 3 `--tl-*` prose hits | ✓ PASS |
| WR-03 blind spots are real | `/tmp/v204r/probe.exs` against the literal `@banner` | 6 missed shapes confirmed | ℹ️ advisory |
| Full gate and browser lane | 204-16-SUMMARY: ci.all 1781/0; browser 326/8/16 at the known 8 | not re-run. The code diff is 6 maintainer-only or test files with no operator_surface change, and my focused runs agree | ✓ PASS (recorded) |

Note: the orchestrator named the test file `test/threadline/critic_trust_test.exs`. It lives at `test/threadline/operator_surface/critic_trust_test.exs`, and I ran it from there.

### Probe Execution

Step 7c: SKIPPED. The phase declares no `scripts/*/tests/probe-*.sh` probes.

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| STRUCT-01 | 204-01 | ✓ SATISFIED | truth 1 |
| STRUCT-02 | 204-03 | ✓ SATISFIED | truth 1 |
| STRUCT-03 | 204-01, 03–06, 08–11, 15, 16 | ✓ SATISFIED | truth 2 |
| STRUCT-04 | 204-01, 04, 08, 11, 12, 15, 16 | ✓ SATISFIED | truth 3 (gap closed) |
| STRUCT-05 | 204-13, 14 | ✓ SATISFIED | truth 4 |
| STRUCT-06 | 204-02 | ✓ SATISFIED | truth 5 |
| STRUCT-07 | 204-04, 07–12, 15 | ✓ SATISFIED | truth 6 |

No requirements are orphaned. REQUIREMENTS.md maps exactly STRUCT-01..07 to Phase 204, and all 7 are `[x]` / Complete. The STRUCT-04 checkbox is now backed by evidence.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| test/threadline/source_size_contract_test.exs | 45 | regex misses ASCII 2-char, double/heavy box and hash-rule banners (WR-03) | 📋 Advisory | a future regression could slip through; no violation exists today |
| test/threadline/source_size_contract_test.exs | 16-23, 45 | trailing branch flags prose ending in `---` (IN-06) | ℹ️ Info | fails loudly, so nothing hides |
| lib/threadline/critic_trust/repository_boundary.ex | — | hardwired to critic.measure; critic.synth keeps a weaker copy with no realpath check (IN-08) | ℹ️ Info | out of STRUCT scope; the two maintainer tools apply different path guarantees |

No TBD/FIXME/XXX markers appear in the 204-16 files.

### Human Verification Required

None.

### Gaps Summary

The single prior gap is closed. The five box-rule banners are gone: one section became a real module boundary, and the other four were deleted as cohesive groups, per D-11. The gate now detects that form and is self-tested. A calibrated, deliberately broader scan confirms that no separator banner of any shape remains in lib/. The reviewer's WR-03 is correct that the gate still has blind spots, but no comment in the tree uses those shapes, so the STRUCT-04 outcome holds. WR-03 is recorded as an advisory hardening item, not a blocker.

---

_Verified: 2026-09-24_
_Verifier: Claude (gsd-verifier)_
