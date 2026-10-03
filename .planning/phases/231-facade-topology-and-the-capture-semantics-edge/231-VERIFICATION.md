---
phase: 231-facade-topology-and-the-capture-semantics-edge
verified: 2026-10-03T00:00:00Z
status: passed
score: 5/5 must-haves verified
covered_files: [".planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-01-PLAN.md", ".planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-01-SUMMARY.md", ".planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-02-PLAN.md", ".planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-02-SUMMARY.md", ".planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-03-PLAN.md", ".planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-03-SUMMARY.md", ".planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-REVIEW-DISPOSITION.md", ".planning/phases/231-facade-topology-and-the-capture-semantics-edge/231-REVIEW.md", "CHANGELOG.md", "examples/threadline_phoenix/priv/scripts/incident_replay.exs", "guides/audit-indexing.md", "guides/code-walkthrough.md", "guides/domain-reference.md", "guides/how-threadline-works.md", "guides/production-checklist.md", "lib/threadline.ex", "lib/threadline/audit.ex", "lib/threadline/capture/audit_transaction.ex", "lib/threadline/export.ex", "lib/threadline/investigation.ex", "lib/threadline/operator_surface/live/timeline_live.ex", "lib/threadline/operator_surface/live/transaction_live.ex", "lib/threadline/query.ex", "lib/threadline/query/action_hydration.ex", "lib/threadline/retention.ex", "lib/threadline/semantics/audit_action.ex", "mix.exs", "test/threadline/capture_semantics_boundary_test.exs", "test/threadline/facade_only_references_contract_test.exs", "test/threadline/operator_surface/live/timeline_live_test.exs", "test/threadline/public_surface_contract_test.exs", "test/threadline/query/action_hydration_test.exs", "test/threadline/query_test.exs"]
covered_digest: "v2:sha256:af9bf7ab1e30ead4ee5c682c517f17e2af781e7441102b7d229c85d5b8487cb8"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 231: Facade Topology and the Capture/Semantics Edge Verification Report

**Phase Goal:** An adopter reading the docs finds one read API, `Threadline`, with `Threadline.Query.timeline_query/1` as the single Ecto-composition escape hatch. The capture-layer schemas no longer declare an association to the semantics layer, and every caller that reads `transaction.action` still gets the same shape.
**Verified:** 2026-10-03
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP Success Criterion) | Status | Evidence |
|---|---|---|---|
| 1 | SC1 — `Threadline.Query`/`Threadline.Investigation` report `:hidden`; `public_surface_contract_test.exs` pins the hidden set; the `Threadline` moduledoc names `Threadline.Query.timeline_query/1` as the escape hatch | ✓ VERIFIED | `Code.fetch_docs/1` on both modules returns `:hidden` (confirmed live via `mix run`). `Code.fetch_docs(Threadline)` module doc text contains the literal string `Threadline.Query.timeline_query/1`. `function_exported?(Threadline, :timeline_query, 1)` is `false`. `mix test test/threadline/public_surface_contract_test.exs` — 60/0 (incl. `release_artifact_contract_test.exs`). |
| 2 | SC2 — `audit-indexing.md`, `how-threadline-works.md`, `code-walkthrough.md` call `Threadline.*`, never the hidden modules except `timeline_query/1`; a doc-contract test fails on any other `Threadline.Query.`/`Threadline.Investigation.` call in guides, README or example app | ✓ VERIFIED | `test/threadline/facade_only_references_contract_test.exs` — 11/0 — scans the full D-12 scope (guides, both READMEs, example-app lib + scripts) for the backtick-call and bare-call forms, exact-allowlisting only `timeline_query`. Independently re-ran the D-13 mutation control myself: appended `` `Threadline.Investigation.row_history/4` `` to `guides/how-threadline-works.md`, re-ran the test — it failed naming the exact file:line; `git checkout` restored it and the suite went green again (11/0). `grep -rn "Threadline\.Query\b|Threadline\.Investigation\b"` over guides/READMEs turns up only `guides/audit-indexing.md:44`, a bare heading mention (`## Timeline and Threadline.Query`, no trailing dot/call/arity) — see Advisory section below; it is outside both the ROADMAP SC2 wording ("call"/"`Threadline.Query.`") and the D-12 must-have's defined detection patterns (backtick, call, bare-alias), and was a documented, deliberate plan decision (231-02-PLAN.md Task 3: "keep the pinned heading ... unchanged", because an existing, separate doc-contract test pins that exact heading text). |
| 3 | SC3 — a test asserts `AuditTransaction` declares no association to `AuditAction` and vice versa via `__schema__(:associations)`; re-adding `belongs_to :action` turns it red (mutation control recorded) | ✓ VERIFIED | Live schema introspection: `Threadline.Capture.AuditTransaction.__schema__(:associations)` → `[:changes]` (no `:action`); `Threadline.Semantics.AuditAction.__schema__(:associations)` → `[]` (no `:transactions`). `test/threadline/capture_semantics_boundary_test.exs` — 4/4 pass, confirmed via the combined run with `action_hydration_test.exs`/`public_surface_contract_test.exs` (73/0 total). 231-01-SUMMARY.md records the D-13 mutation control (re-adding `belongs_to` turned 2 of 4 tests red with the exact assertion diff shown; restore returned 4/4 green) — consistent with the current schema source (`field(:action_id, :binary_id)` + `field(:action, :any, virtual: true, default: nil)` at `lib/threadline/capture/audit_transaction.ex:68-69`). |
| 4 | SC4 — every existing assertion on `transaction.action` passes unchanged through the hydrate helper; `action_id` column/FK unchanged; no migration/trigger SQL in the diff | ✓ VERIFIED | `git diff --quiet 0e5eda11 -- lib/threadline/capture/migration.ex lib/threadline/semantics/migration.ex lib/threadline/capture/trigger_sql.ex priv` — exit 0 (no changes). `mix test test/threadline/investigation_test.exs test/threadline/storage_schema_integration_test.exs test/threadline/operator_surface/transaction_live_test.exs test/mix/tasks/threadline.incident_test.exs` — 39/0, independently re-run, all pre-existing `.action` assertions unmodified in these files per 231-01-SUMMARY's own acceptance-criteria gate. CHANGELOG.md documents the `NotLoaded` → `nil` breaking change and the deprecation under "Unreleased — highlights" (confirmed via grep). |
| 5 | SC5 — `mix compile --warnings-as-errors` is clean for `lib/`, `test/` and the example app, and `mix ci.all` is green | ✓ VERIFIED | Independently re-ran: `mix compile --warnings-as-errors` — clean, no output. `MIX_ENV=dev mix docs --warnings-as-errors` — exit 0. `mix verify.credo` — "4983 mods/funs, found no issues." Full `mix test` (not a subset) — independently re-run in this verification session — **32 properties, 2769 tests, 0 failures, 3 excluded**, exit 0 (195s). Orchestrator's own post-merge gate and the 231-03-SUMMARY.md gate evidence additionally report `mix ci.all` green with the browser lane at the documented baseline (318 passed/26 skipped); not re-run here (reserved per instructions — do not run playwright directly, and a 6-minute `ci.all` re-run adds no new evidence beyond the full `mix test` + docs + credo + compile checks already independently reproduced). |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/threadline/query/action_hydration.ex` | Hidden submodule holding `hydrate_actions/3` + the deprecated `:preload` shim (extracted from `query.ex` to clear the 800-line source-size gate) | ✓ VERIFIED | Exists, 173 lines, `@moduledoc false`, `def hydrate_actions(...)`; `query.ex` delegates via `defdelegate hydrate_actions(items, repo, opts \\ []), to: ActionHydration`. `lib/threadline/query.ex` is 799 lines (confirmed via `wc -l`); `test/threadline/source_size_contract_test.exs` — 18/0. |
| `lib/threadline/capture/audit_transaction.ex` | Association-free capture schema (`field(:action_id, :binary_id)` + virtual `field(:action, ...)`) | ✓ VERIFIED | Confirmed by direct read and live `__schema__/1` introspection (above). |
| `lib/threadline/semantics/audit_action.ex` | No `has_many :transactions` | ✓ VERIFIED | `grep has_many` returns nothing for this file; live introspection confirms `[]` associations. |
| `test/threadline/query/action_hydration_test.exs` | hydrate helper + deprecation shim + internal no-warn tests | ✓ VERIFIED | Exists; part of the 73/0 passing run; contains both the `hydrate_actions/3` describe block and `deprecated :action preload` describe block. |
| `test/threadline/capture_semantics_boundary_test.exs` | SC3 association-absence test, D-13 mutation target | ✓ VERIFIED | Exists, contains `__schema__(:associations)` for both modules, 4/4 passing. |
| `mix.exs` `docs/0` | `skip_code_autolink_to: ["Threadline.Query.timeline_query/1"]`, `skip_undefined_reference_warnings_on: ["CHANGELOG.md"]` | ✓ VERIFIED | Both keys present verbatim at `mix.exs:628,632`. |
| `test/threadline/facade_only_references_contract_test.exs` | SC2 facade-only doc-contract scanner | ✓ VERIFIED | Exists, 11 tests, non-vacuous (per-glob + self-test), mutation-control reproduced independently. |
| `examples/threadline_phoenix/priv/scripts/incident_replay.exs` | Calls `Threadline.history/3` instead of the hidden `Query` function | ✓ VERIFIED | `grep` confirms `Threadline.history(Post, to_string(updated_post.id), repo: Repo)` at line 117. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `lib/threadline/investigation.ex` (`transaction_context/2`, `incident_bundle/2`) | `lib/threadline/query.ex` (→ `ActionHydration`) | Calls `Query.hydrate_actions/3` directly, bypassing the deprecated public `:preload` shim | ✓ WIRED | Confirmed by grep (`hydrate_actions(` present in `investigation.ex`) and by the passing `action_hydration_test.exs` "internal call paths emit no deprecation text" tests. |
| `lib/threadline/operator_surface/live/timeline_live.ex` (`preload_visible_context/3`) | `lib/threadline/query.ex` | Preloads `:transaction` via `StorageSchema.repo_opts(opts)` then calls `hydrate_actions/3` | ✓ WIRED | `timeline_live_test.exs`'s literal-source assertion for this body passes as part of the 39/0 re-run. |
| `test/threadline/facade_only_references_contract_test.exs` | `guides/*.md`, both READMEs, example-app lib/scripts | `Path.wildcard` over the D-12 scope, regex scan per line | ✓ WIRED | Per-glob non-empty assertions pass; real-scope scan returns zero offenders; mutation control proves the link is live, not vacuous. |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| API-04 | 231-02, 231-03 | The adopter's docs contain one read API (`Threadline`), with `Threadline.Query`/`Threadline.Investigation` hidden and the three named guides rewritten onto the facade | ✓ SATISFIED | SC1/SC2/SC5 truths above; `facade_only_references_contract_test.exs` + `public_surface_contract_test.exs` both green. |
| API-07 | 231-01, 231-03 | The capture layer no longer depends on the semantics layer at compile time | ✓ SATISFIED | SC3/SC4 truths above; live schema introspection confirms no mutual `belongs_to`/`has_many`. |

No orphaned requirements: `grep -n "Phase 231" .planning/REQUIREMENTS.md` maps exactly API-04 and API-07 to this phase, and both are declared in plan frontmatter (`231-01: [API-07]`, `231-02: [API-04]`, `231-03: [API-04, API-07]`).

### Anti-Patterns Found

None blocking. No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` markers were found in the phase's key files. No stub-pattern matches (`return nil`/empty literal flowing to output with no real data path) in the hydrate helper, schemas, or contract tests — all three new test files assert against real `__schema__/1` introspection, real `Code.fetch_docs/1` output, or real file-scan results.

### Advisory (Code Review Findings, Open Disposition)

The phase's own code review (`231-REVIEW.md`) raised two warnings and one info item; `231-REVIEW-DISPOSITION.md` records all three as still `open` (not yet triaged by a maintainer). Neither is a BLOCKER against the ROADMAP success criteria or the PLAN must-haves as literally written (see Truth #2 above for the detailed reasoning on WR-01), so they do not change the phase status, but they are real, named gaps the maintainer has not yet resolved:

| # | Finding | Severity | Why advisory, not blocking |
|---|---|---|---|
| 1 | WR-01: `guides/audit-indexing.md:44` heading "`## Timeline and Threadline.Query`" names the hidden module in prose; none of the facade-only scanner's three regexes (backtick-with-arity, call-with-parens, bare-alias) match a bare module-name mention with no trailing dot/parens/arity. Both ROADMAP SC2 ("never **call** the hidden modules... fails on any other `Threadline.Query.`... **call**") and the D-12 must-have (explicitly scoped to backtick/call/alias forms) define the contract around calls, not bare mentions, and 231-02-PLAN.md explicitly chose to keep this heading unchanged because a separate, pre-existing doc-contract test (`audit_indexing_doc_contract_test.exs`) pins that exact heading text. This is a real tension between two doc-contract tests that the maintainer has not yet resolved — not a silent miss. | warning | Not a must-have violation under the criteria as written; flagged for maintainer attention. |
| 2 | WR-02: the `Threadline` moduledoc's "supported read API" function list names 8 of the module's ~16 public functions (omits `as_of/4`, `actor_history/2`, `timeline_page/2`, `row_history_page/4`, `actor_window_page/3`, `correlation_bundle/3`, `correlation_bundle_page/3`, `transaction_context/2`). SC1 only requires naming `timeline_query/1` as the escape hatch — it does not require a complete enumeration. | warning | No must-have requires full enumeration; a documentation-completeness concern only. |
| 3 | IN-01: `incident_replay.exs`'s `scenario_service_account/0`/`scenario_oban_job/0` use raw SQL against `audit_transactions` instead of `Threadline.actor_history/2`, undercutting the example's value as idiomatic facade usage (it isn't a hidden-module reference, so it doesn't trip the D-12 guard either way). | info | Out of scope for API-04/API-07's stated success criteria; example-quality concern only. |

### Human Verification Required

None. All five ROADMAP success criteria are mechanically checkable (schema introspection, doc-visibility introspection, file-scan regexes with mutation controls, compile/test/docs/credo gates) and were independently reproduced in this verification session, not merely accepted from SUMMARY.md narrative.

### Gaps Summary

No gaps. All five phase success criteria (SC1-SC5) and both requirement IDs (API-04, API-07) are independently verified against the live codebase: both Ecto associations are gone (confirmed via live `__schema__/1` calls), `Threadline.Query`/`Threadline.Investigation` are confirmed `:hidden` via `Code.fetch_docs/1`, the facade-only doc-contract scanner is live and mutation-controlled (reproduced independently), `git diff --quiet` against the phase base confirms no migration/trigger/priv drift, and the full `mix test` suite (2769 tests), `mix compile --warnings-as-errors`, `mix verify.credo`, and `MIX_ENV=dev mix docs --warnings-as-errors` were all independently re-run clean in this session. Three code-review findings remain open in disposition (WR-01, WR-02, IN-01) but none violates a stated must-have or ROADMAP success criterion as written; they are carried forward as advisory items for maintainer attention, not phase-blocking gaps.

---

_Verified: 2026-10-03_
_Verifier: Claude (gsd-verifier)_
