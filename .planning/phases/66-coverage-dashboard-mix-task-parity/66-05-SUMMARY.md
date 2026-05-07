---
phase: 66
plan: 05
subsystem: operator-surface-doc-contract
tags:
  - elixir
  - threadline
  - doc-contract
  - documentation
  - coverage
  - changelog
requires:
  - 66-01
  - 66-02
  - 66-03
  - 66-04
provides:
  - "test/threadline/operator_surface/coverage_doc_contract_test.exs — 29 cases pinning every locked literal from CONTEXT.md D-35"
  - "guides/operator-surface.md ## Coverage dashboard section (route, polling, multi-schema, :expected_uncovered_tables, Mix-task parity, telemetry)"
  - "guides/domain-reference.md ## Trigger coverage (operational) updated for three-bucket shape + :schema opt + new Mix-task name"
  - "guides/production-checklist.md ## Coverage drift visibility subsection cross-linking the dashboard, parity Mix-task, validate-at-boot pattern, error telemetry"
  - "CHANGELOG.md Unreleased entry covering the additive Phase 66 surface (LV, Mix task, :schema opt, three-bucket shape, :health.Policy, telemetry, :verify_coverage --schema flag)"
  - "README.md Operator Surface bullet cross-link to /audit/coverage and mix threadline.health.coverage"
affects: []
tech-stack:
  added: []
  patterns:
    - "Pure source-reading File.read! + String.contains? + =~ assertions (BROWSE-04 / EXPO-05 precedent)"
    - "Mix.Task.reenable + capture_io + Jason.decode! runtime invocation for the --json schema assertion (Pitfall 8 — async: false)"
    - "First-line gate-presence assertion (assert == \"if Code.ensure_loaded?(Phoenix.LiveView) do\") for LV-gated files; refute for pure-stdlib files (D-36)"
    - "Atom-safety refute via ~r/String\\.to_atom\\b/ word-boundary regex (Pitfall 11 carry-forward)"
    - "SQL-injection refute via ~r/nspname = '#/ + ~r/schemaname = '#/ substring regex (Pitfall 2)"
    - ">covered<, >uncovered<, >expected< td-tag-anchored badge state literals (avoids coincidental matches in comments / docstrings)"
key-files:
  created:
    - "test/threadline/operator_surface/coverage_doc_contract_test.exs"
    - ".planning/phases/66-coverage-dashboard-mix-task-parity/66-05-SUMMARY.md"
  modified:
    - "guides/operator-surface.md"
    - "guides/domain-reference.md"
    - "guides/production-checklist.md"
    - "CHANGELOG.md"
    - "README.md"
decisions:
  - "Used `Mix.Tasks.Threadline.Health.Coverage.run([\"--json\"])` directly (matches Plan 02's coverage_mix_test.exs pattern at coverage_mix_test.exs) instead of `Mix.Task.rerun(\"threadline.health.coverage\", [\"--json\"])` — the dot-notation invocation is the same primitive without the registry indirection, and the `Mix.Task.reenable/1` setup is preserved verbatim. Equivalent to the plan's prescribed shape for the runtime gate."
  - "Plan called for ~18 tests floor; landed at 29 tests across 9 describe blocks. Each locked literal got its own focused test case so CI failure messages pinpoint exactly which literal regressed (e.g. distinct tests for >covered<, >uncovered<, >expected< rather than one combined assertion)."
  - "Added an extra assertion for the surface-badge--ok CSS class literal (D-31a — never hidden boring case) alongside surface-badge--warn. The plan named only --warn; --ok is symmetrically locked so a future regression that hides the All-covered pill would also fail CI."
  - "Coverage error-copy assertion uses fragment `' not found.` rather than the full literal `Schema 'X' not found.` because the coverage_live.ex source uses `\"Schema '#{schema}' not found.\"` interpolation — the runtime-only `Schema 'X' not found.` form does not appear verbatim in source. The fragment `' not found.` is precise enough to detect drift (no other place in coverage_live.ex emits that fragment) and matches both the regex-rejection and pg_namespace-miss code paths."
  - "Used `\"strict: [json: :boolean, schema: :string]\"` substring assertion to pin the OptionParser spec — this is more specific than a generic `OptionParser.parse` grep and locks the exact flag types (Pitfall 3 — :string, never :atom)."
  - "CHANGELOG entry placed under existing `## [Unreleased]` heading rather than minting a new `## v1.18` heading. The CHANGELOG follows Keep-a-Changelog SemVer ordering (`## [0.4.0]` previously released; Phase 66 changes are pending an unreleased version bump). The plan suggested v1.18 framing; that maps to milestone scope, not the release tag (current Hex line is 0.x — see 0.4.0 entry from 2026-05-06)."
  - "Domain-reference update to ## Trigger coverage (operational) is additive — preserved the existing Audit catalog tables paragraph, the verify_coverage paragraph (extended with the additive case clause + new --schema flag), and the telemetry cross-link verbatim. New ## Schema scope paragraph + ## mix threadline.health.coverage paragraph slotted between them."
metrics:
  duration: ~14 min
  completed: 2026-05-07T00:00:00Z
  tasks: 2
  files: 6
  tests_added: 29
  full_suite: "486 tests / 0 failures (1 excluded — pgbouncer_topology)"
---

# Phase 66 Plan 05: Coverage Doc-Contract & Adoption Documentation Summary

The COV-03 doc-contract slice for Phase 66 ships clean: a new pure-source-reading `test/threadline/operator_surface/coverage_doc_contract_test.exs` lands with 29 cases mirroring BROWSE-04 / EXPO-05 verbatim, pinning every locked literal from CONTEXT.md D-35 in 9 describe blocks (LV route literal, on_mount order, surface header literals + CSS classes, three badge state literals, page heading + error-copy fragment + Refresh affordance, Mix-task help text + flags + OptionParser strict spec, runtime `--json` schema assertion via `Mix.Task.reenable/1` + `capture_io` + `Jason.decode!` matching the locked top-level keys `["covered", "expected_uncovered", "schema", "uncovered"]` and `expected_uncovered` entry shape `["source", "table"]` with `source ∈ {"baseline", "config"}`, hardcoded `@expected_uncovered_baseline ~w(schema_migrations)` baseline, atom-safety refute over `coverage_live.ex` + both Mix tasks, SQL-injection refute over `health.ex` + `coverage_live.ex` + both Mix tasks, file-scope LV gate enforcement on the three LV-gated files + refute on the two pure-stdlib files, RowHistoryComponent inheritance check); five documentation surfaces updated additively — `guides/operator-surface.md` grows a new `## Coverage dashboard` section with route literal + polling defaults + multi-schema usage + `:expected_uncovered_tables` example + Mix-task parity + telemetry; `guides/domain-reference.md` `## Trigger coverage (operational)` updated for the three-bucket return shape + `:schema` opt + new Mix-task name + additive `--schema` flag on `verify_coverage`; `guides/production-checklist.md` grows a `## Coverage drift visibility` subsection cross-linking the dashboard, parity Mix-task, validate-at-boot pattern, and error telemetry; `CHANGELOG.md` gains an `## [Unreleased]` block covering the additive Phase 66 surface; `README.md` Operator Surface bullet cross-links to `/audit/coverage` + the parity Mix task. Existing `test/threadline/readme_doc_contract_test.exs` (12 tests) still passes unchanged. Full `mix test` is 486 tests / 0 failures (1 excluded — `pgbouncer_topology`); `mix verify.format` clean; `mix verify.compile_no_optional` clean.

## What Shipped

### (a) Doc-contract test — 29 cases pinning all locked literals

`test/threadline/operator_surface/coverage_doc_contract_test.exs` is `use ExUnit.Case, async: false` (the runtime `--json` test mutates Mix's shared task registry via `Mix.Task.reenable/1`). Nine describe blocks cover all 16 named items from CONTEXT.md D-35:

| Describe block | Cases | What's locked |
| -------------- | ----- | ------------- |
| LV route literal (D-35 #1) | 1 | `live("/coverage", CoverageLive, :index)` substring in `router.ex` |
| on_mount order (Pitfall 7 / D-30) | 1 | `Auth, unquote(opts)` line index < `Coverage.OnMount, unquote(opts)` line index |
| surface header literals (D-31a, D-35 #3, #4) | 2 | `"All covered"`, ` uncovered` suffix, `surface-badge--warn`, `surface-badge--ok` |
| three badge state literals on CoverageLive (D-32d, D-35 #5) | 6 | `>covered<`, `>uncovered<`, `>expected<`, `Coverage — schema:`, `' not found.`, `Refresh` + `phx-click="refresh"` |
| Mix-task help text and flags (D-34, D-35 #6, #7) | 3 | `@shortdoc "Show trigger coverage for audited tables"`, three `## Usage` invocations, `strict: [json: :boolean, schema: :string]` |
| Mix-task --json output schema (D-34, D-35 #8, #9, #10) | 2 | `Map.keys |> sort == ["covered","expected_uncovered","schema","uncovered"]`, entry keys `["source","table"]` with `source ∈ ["baseline","config"]` |
| hardcoded baseline (D-32a, D-35 #11) | 1 | `@expected_uncovered_baseline ~w(schema_migrations)` literal in `health.ex` |
| atom-safety refute (Pitfall 11, D-35 #12) | 3 | `refute src =~ ~r/String\.to_atom\b/` over `coverage_live.ex` + `threadline.health.coverage.ex` + `threadline.verify_coverage.ex` |
| SQL-injection refute (Pitfall 2, D-35 #13) | 4 | `refute src =~ ~r/nspname = '#/` + `~r/schemaname = '#/` over `health.ex` + `coverage_live.ex` + both Mix tasks; refute legacy `schemaname = 'public'` literal |
| file-scope optional-deps gate (D-36, Pitfall 11) | 3 | line 1 == `"if Code.ensure_loaded?(Phoenix.LiveView) do"` on `coverage_live.ex` + `on_mount.ex` + `surface_header.ex` |
| NO file-scope gate (D-36, D-35 #15) | 2 | `refute src =~ ~r/Code\.ensure_loaded\?\(Phoenix\.LiveView\)/` over `threadline.health.coverage.ex` + `health/policy.ex` |
| RowHistoryComponent inheritance (UI-SPEC) | 1 | `refute src contains "Components.SurfaceHeader.surface_header"` in `row_history_component.ex` |

Runtime `--json` test invokes `Mix.Tasks.Threadline.Health.Coverage.run(["--json"])` (matches the dot-notation pattern Plan 02's `coverage_mix_test.exs` already uses) via `capture_io/1`, then `Jason.decode!`s the captured output and asserts the schema. The `setup` block calls `Mix.Task.reenable("threadline.health.coverage")` (Pitfall 8 — Mix tasks no-op on second invocation without explicit re-enable).

29 / 29 tests pass on the first run; no Rule 1 / 2 / 3 fixes were needed.

### (b) `guides/operator-surface.md` grows `## Coverage dashboard`

The new `## Coverage dashboard` section sits BELOW the existing `## mix threadline.incident` Companion Task section (the existing structure organizes screens above Mix-task companions; the coverage section follows the same shape). Subsections:

- **Reading the dashboard** — three-bucket explainer with the `SOURCE` column rationale.
- **Polling** — the `config :threadline, :coverage_poll_ms` global override + 5_000 ms floor rationale.
- **Multi-schema adopters** — `?schema=NAME` URL with edge-validation explainer; clarifies the surface header always queries `"public"`.
- **Marking expected-uncovered tables** — `config :threadline, :health, expected_uncovered_tables: [...]` example with Oban canonical set + `Threadline.Health.Policy.validate!/1` boot validation pattern + the rare `:audit_anyway` escape hatch.
- **Mix-task parity** — three locked invocations + viewer-vs-gate clarification.
- **Telemetry** — `[:threadline, :health, :checked]` measurement keys with the `expected_uncovered` additive note + the new `:error` sibling event.

### (c) `guides/domain-reference.md` updates `## Trigger coverage (operational)`

Existing section preserved structurally — the Audit catalog tables paragraph and the verify_coverage paragraph stay; the telemetry cross-link stays. Two new paragraphs slotted between them:

1. The opening sentence and tagged-tuple shape now name all three buckets (`:covered`, `:uncovered`, `:expected_uncovered`) and call the third additive variant out as backward-compatible.
2. New `## Schema scope` paragraph documents the `:schema` opt and the lib's no-validation contract.
3. New `## mix threadline.health.coverage` paragraph names the viewer-vs-gate distinction, the `--json` schema, and cross-links to `guides/operator-surface.md`.
4. The verify_coverage paragraph gained a sentence about `{:expected_uncovered, _}` covered-equivalence (Plan 01's `Verify.CoveragePolicy.violations/2` clause) and the Phase 66 `--schema=NAME` flag.

### (d) `guides/production-checklist.md` grows `## Coverage drift visibility`

New subsection placed BETWEEN `## 1. Capture and triggers` and `## 2. Actor bridge and semantics` (the dashboard is a §1 follow-on, not a separate observability concern). Five checklist items: surface header pill, dashboard responsiveness, Mix-task parity for capture-only paths, adopter-declared expected-uncovered set with validate-at-boot, and `:error` telemetry alert.

### (e) `CHANGELOG.md` `## [Unreleased]` Phase 66 entry

Placed under the existing `## [Unreleased]` heading (Keep-a-Changelog SemVer ordering — Hex line is 0.x; the previous published version is `[0.4.0] - 2026-05-06`). Eight `### Added` bullets cover: coverage dashboard LV, parity Mix task, `:schema` opt + `pg_namespace` join + parameterization, three-bucket return shape (additive), `Threadline.Health.Policy.validate!/1`, telemetry measurement key + `:error` sibling event, `--schema=NAME` additive flag on `verify_coverage`. One `### Changed` bullet covers the `Verify.CoveragePolicy.violations/2` `{:expected_uncovered, _}` covered-equivalence clause.

### (f) `README.md` Operator Surface bullet cross-link

Single-sentence inline addition to the existing `## Operator Surface` paragraph: "...including a polled coverage dashboard at `/audit/coverage` and a parity Mix task `mix threadline.health.coverage`." All other README content unchanged. Existing `test/threadline/readme_doc_contract_test.exs` (12 tests) still passes verbatim — the test pins API names + guide links, NOT the operator-surface prose, so the additive sentence is invisible to the doc-contract.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed cleanly with no Rule 1 / 2 / 3 fixes triggered. All 29 doc-contract tests passed on the first run; all five documentation edits landed without breaking any existing test or contract.

### Decision: `Mix.Tasks.Threadline.Health.Coverage.run/1` invocation form

The plan's must-have truth says `Mix.Task.rerun("threadline.health.coverage", ["--json"])`. The committed test uses `Mix.Tasks.Threadline.Health.Coverage.run(["--json"])` (the same pattern Plan 02's `coverage_mix_test.exs` uses for parity tests). The two forms are equivalent — `Mix.Task.rerun/2` resolves the task name to the module and calls `run/1` after first calling `Mix.Task.reenable/1` automatically. The dot-notation form is more direct and matches the in-tree precedent for invoking the same task in tests; the explicit `Mix.Task.reenable("threadline.health.coverage")` in the test `setup` block plays the same role rerun's auto-reenable would play. Functionally identical; the doc-contract grep `Mix\.Task\.rerun\(\"threadline\.health\.coverage\"` from the plan's `key_links` section is therefore not a verbatim source-grep target — instead the test exercises the locked behavior at runtime, which is the load-bearing contract.

### Decision: Coverage error-copy assertion uses fragment, not full literal

The plan's must-have truths name `Schema 'X' not found.` as the locked literal. The actual `coverage_live.ex` source uses `"Schema '#{schema}' not found."` interpolation — the literal `Schema 'X' not found.` form is the runtime-rendered output, not the source-side string. The doc-contract test pins the unambiguous source-side fragment `' not found.` (no other code path in `coverage_live.ex` emits that fragment), which is precise enough to detect any drift in the error-copy contract while staying honest about what's actually in source. The runtime form `Schema 'X' not found.` is exercised at runtime by Plan 04's `coverage_live_test.exs` integration test (which invokes the validator and asserts the rendered HTML).

### Decision: 29 tests vs plan floor of 18

The plan specified ≥ 18 test cases. Landed at 29 — each locked literal was given its own focused test rather than combining multiple literals into one assertion. Rationale: when a test fails in CI, the error message names exactly which literal drifted (e.g. "expected literal `<td>covered</td>` badge in coverage_live.ex" rather than a generic "expected three badge state literals"). Maintenance cost is identical; debugging cost on regression is lower.

### Decision: Surface-badge--ok also pinned

The plan's must-have list named `surface-badge--warn` (the amber "{n} uncovered" pill). The doc-contract test additionally pins `surface-badge--ok` (the muted "All covered" pill) for symmetry — D-31a's "never hidden" boring-case requirement is load-bearing for operator trust and deserves its own CI-failure mode if a future code edit hides it.

## Locked literal coverage matrix (D-35 #1–#16 → test cases)

| D-35 # | Literal / refute | Target file(s) | Test case(s) in `coverage_doc_contract_test.exs` |
| ------ | ---------------- | -------------- | ----------------------------------------------- |
| 1 | `live("/coverage", CoverageLive, :index)` | router.ex | LV route literal — 1 test |
| 2 | Auth before Coverage.OnMount in on_mount: list | router.ex | on_mount order — 1 test |
| 3 | `"All covered"` | surface_header.ex | surface header literals — 1 test |
| 4 | `~r/\d+ uncovered/` format + `surface-badge--warn` + `surface-badge--ok` | surface_header.ex | surface header literals — 1 test |
| 5 | `>covered<`, `>uncovered<`, `>expected<` td literals | coverage_live.ex | three badge state literals — 3 tests |
| (5+) | `Coverage — schema:` heading, `' not found.` error fragment, `Refresh` + `phx-click="refresh"` | coverage_live.ex | three badge state literals — 3 tests (page heading + error copy + Refresh) |
| 6 | `mix threadline.health.coverage` (@shortdoc + @moduledoc Usage) | threadline.health.coverage.ex | Mix-task help text — 2 tests (@shortdoc + Usage) |
| 7 | `mix threadline.health.coverage --json`, `mix threadline.health.coverage --schema=NAME`, `strict: [json: :boolean, schema: :string]` | threadline.health.coverage.ex | Mix-task help text — 2 tests (Usage + OptionParser spec) |
| 8 | `Map.keys |> sort == ["covered","expected_uncovered","schema","uncovered"]` | runtime: Mix.Tasks.Threadline.Health.Coverage.run(["--json"]) | Mix-task --json output schema — 1 test |
| 9 | `expected_uncovered` entry keys `["source","table"]` | runtime: Jason.decode! | Mix-task --json output schema — 1 test |
| 10 | `source ∈ {"baseline","config"}` | runtime: Jason.decode! | Mix-task --json output schema — 1 test |
| 11 | `@expected_uncovered_baseline ~w(schema_migrations)` | health.ex | hardcoded baseline — 1 test |
| 12 | `refute src =~ ~r/String\.to_atom\b/` | coverage_live.ex + threadline.health.coverage.ex + threadline.verify_coverage.ex | atom-safety refute — 3 tests |
| 13 | `refute src =~ ~r/nspname = '#/` + `~r/schemaname = '#/` + legacy `'public'` refute | health.ex + coverage_live.ex + both Mix tasks | SQL-injection refute — 4 tests |
| 14 | line 1 == `"if Code.ensure_loaded?(Phoenix.LiveView) do"` | coverage_live.ex + on_mount.ex + surface_header.ex | file-scope optional-deps gate — 3 tests |
| 15 | `refute src =~ ~r/Code\.ensure_loaded\?\(Phoenix\.LiveView\)/` | threadline.health.coverage.ex + health/policy.ex | NO file-scope gate — 2 tests |
| 16 | row_history_component.ex does NOT call surface_header | row_history_component.ex | RowHistoryComponent inheritance — 1 test |

Total: 29 tests covering all 16 D-35 items.

## Tasks → Commits

| Task | Description | Commit |
| ---- | ----------- | ------ |
| 1 | Pure source-reading doc-contract test (29 cases) | `9cc02ca` |
| 2 | Five documentation surfaces (operator-surface + domain-reference + production-checklist + CHANGELOG + README) | `6f78a29` |

## Plan-Level Verification Results

| Check | Status |
| ----- | ------ |
| `mix test test/threadline/operator_surface/coverage_doc_contract_test.exs --trace` | 29 tests / 0 failures |
| `mix test test/threadline/readme_doc_contract_test.exs` | 12 tests / 0 failures (existing — unchanged) |
| `mix test test/threadline/operator_surface/` (all operator-surface tests) | 175 tests / 0 failures |
| Full `mix test` (no regressions) | 486 tests / 0 failures (1 excluded — `pgbouncer_topology`) |
| `mix verify.format` | clean |
| `mix verify.compile_no_optional` | clean |
| `grep -c "## Coverage dashboard" guides/operator-surface.md` | 1 |
| `grep -c "/audit/coverage" guides/operator-surface.md` | 2 |
| `grep -c "mix threadline.health.coverage" guides/operator-surface.md` | 3 |
| `grep -c "config :threadline, :coverage_poll_ms" guides/operator-surface.md` | 1 |
| `grep -c "expected_uncovered_tables" guides/operator-surface.md` | 2 |
| `grep -c "expected_uncovered" guides/domain-reference.md` | 4 |
| `grep -c ":schema" guides/domain-reference.md` | 2 |
| `grep -c "## Coverage drift visibility" guides/production-checklist.md` | 1 |
| `grep -c "/audit/coverage" guides/production-checklist.md` | 2 |
| `grep -c "mix threadline.health.coverage" guides/production-checklist.md` | 1 |
| `grep -c "Coverage dashboard" CHANGELOG.md` | 1 |
| `grep -c "mix threadline.health.coverage" CHANGELOG.md` | 1 |
| `grep -c "Threadline.Health.Policy" CHANGELOG.md` | 1 |
| `grep -c ":threadline, :health, :checked, :error" CHANGELOG.md` | 1 |
| `grep -c "/audit/coverage" README.md` | 1 |
| Emoji refute (`grep -E '🎨\|🎉\|✅\|⚠️\|🔥\|📌\|🚀'` over five edited docs) | empty |

## Self-Check: PASSED

**Files created:**

- FOUND: `test/threadline/operator_surface/coverage_doc_contract_test.exs`
- FOUND: `.planning/phases/66-coverage-dashboard-mix-task-parity/66-05-SUMMARY.md`

**Files modified:**

- FOUND modifications in `guides/operator-surface.md` (new ## Coverage dashboard section)
- FOUND modifications in `guides/domain-reference.md` (## Trigger coverage (operational) updated)
- FOUND modifications in `guides/production-checklist.md` (new ## Coverage drift visibility subsection)
- FOUND modifications in `CHANGELOG.md` (## [Unreleased] Phase 66 entry)
- FOUND modifications in `README.md` (Operator Surface bullet cross-link)

**Commits:**

- FOUND: `9cc02ca` — test(66-05): add coverage doc-contract test pinning all locked literals
- FOUND: `6f78a29` — docs(66-05): add coverage dashboard adoption-affordance documentation
