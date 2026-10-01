# Project Research Summary

**Project:** Threadline
**Milestone:** v1.44 Behavioral Depth: Properties, Twins, Telemetry
**Domain:** Trigger-backed PostgreSQL audit-capture library for Elixir/Phoenix/Ecto — this pass is behavioral-depth and CI-economy work on an existing 0.11.2 codebase, not a new-product research pass
**Researched:** 2026-09-30
**Confidence:** HIGH

## Executive Summary

v1.44 is not "what should we build" research — it is "how do we safely deepen an already-shipped trigger-capture library's behavioral guarantees without breaking its own one-way-default and CI-economy rules." The four research files (topic-themed, not stack/features-split, per this milestone's shape) converge on one throughline: every new surface this milestone touches — property tests, telemetry, a `history/3` limit, guard-test cuts, an async-conversion pass, and a migration-down bug fix — has a documented, low-risk shape *if* it reuses this repo's existing conventions (`Threadline.DataCase`'s no-sandbox pattern, `[:threadline, noun, verb_past_tense]` telemetry naming, `nil`-default additive options, mutation-controlled contract tests) and a real risk of silent regression if it doesn't. The single highest-leverage, zero-risk item is CI partitioning (`mix test --partitions N`) for the suite's ~91% serial core — it needs no test file changes and no capture-semantics risk, unlike targeted async-conversion which does.

The recommended approach: land the six named property-test targets as four pure (cursors, ChangeDiff, redaction-policy-validation, export round-trip) and three DB-backed (`as_of`, redaction-leak-at-SQL, retention-cutoff) tests, each with an explicit small `max_runs` and a mutation control proving it isn't tautological; ship five new telemetry events (export completed/failed, a `:telemetry.span/3` around retention purge, a batch-purged execute event) while explicitly declining query and mix-task telemetry as anti-features; give `history/3` an additive `:limit` option defaulting to `nil` (unbounded) rather than take the one-way bounded-default decision this milestone doesn't need to take; extend `mix threadline.health.coverage` with `--strict` and `--all-schemas` while declining a new `:invalid_config` Finding code (the existing `Mix.raise` is already stricter); defer `mix threadline.gen.backfill` as a durable anti-feature in favor of a new `:unresolved_legacy_keys` warning-severity health finding; fix the `gen.triggers` down-orphan bug by computing function-drops from the full `table_specs` (not the rerun-filtered set) with a `pg_proc`-verified property test; and fix the bench compile failure with a one-line `preferred_envs: [compile: :test, run: :test]` in `bench/mix.exs`.

The key risk, called out explicitly and repeatedly across PITFALLS.md and cross-referenced by ARCHITECTURE.md and STACK.md, is that this milestone contains two forces pulling in opposite directions on the same number: property tests (especially the three DB-backed ones) add real, serial, un-sandboxed DB round-trips to a suite whose ~91%-serial, 191-of-209-second footprint this same milestone is separately trying to shrink. These must be sequenced and measured together, not treated as independent phases — see "Resolved Conflict" below. A second cross-cutting risk is telemetry-as-a-side-door for the very PII/redaction leaks this milestone's own property tests are proving don't exist elsewhere; every new telemetry event must carry only counts/durations/table-names/status-atoms, never row values, actor identifiers, or free-text reasons.

## Key Findings

### Recommended Approach (from STACK.md)

Stay on StreamData for all six property targets — no PropEr/`propcheck` this milestone; none of the targets need stateful/model-based testing, and adding a second property library plus a transitive Erlang dependency is unjustified cost for a capability not required here. The load-bearing DB strategy, since `Threadline.DataCase` has no `Ecto.Adapters.SQL.Sandbox` (triggers fire at the DB level, outside sandbox awareness): reuse `DataCase` as-is (`async: false`), generate whole fixtures in memory then batch-insert once per `check all` iteration, and uniquify by a fresh per-iteration key rather than truncating between iterations — never stand up a schema-per-property. Explicit, tiered `max_runs` (200 for pure targets, 15-20 for DB-backed ones, both scaled up via an env-var-driven multiplier for a weekly/nightly lane) is the mechanism that keeps the property phase from fighting the suite-time-reduction phase.

**Core technologies / mechanisms:**
- `stream_data ~> 1.4` (already a test dep) — no new property library needed; StreamData's native seed-based shrink-reproduction already satisfies the "reproducibility" ask with zero new plumbing.
- `Threadline.DataCase` (no sandbox, `async: false`, unique-PK-per-iteration) — the only safe DB-property harness in this codebase; do not invent a second one.
- `bench/mix.exs` fix: add `def cli do [preferred_envs: [compile: :test, run: :test]] end` — root-caused and reproduced locally; do not remove `env: :test` from the `threadline` path dependency (that breaks bench's genuine runtime need for `Threadline.Test.Repo`).

### Expected Behavior/Feature Decisions (from FEATURES.md)

This file is a decision record across four named areas (telemetry, `history/3` limit, deferred v1.42 health/CLI items, `gen.backfill`), not a competitor survey — table-stakes/differentiator framing is folded into each verdict.

**Include:**
- `[:threadline, :export, :completed]` / `[:threadline, :export, :failed]` execute events.
- `:telemetry.span/3` around `Threadline.Retention.purge/1` (`start|stop|exception`) plus a `[:threadline, :retention, :batch_purged]` execute event per batch — the one place in this milestone a span is justified (a genuine bounded run with real mid-run exception risk), matching Oban's own precedent of reserving spans for the one supervised unit of work.
- `Threadline.history/3` gains `:limit` (optional positive integer, `ArgumentError` on `0`/negative/non-integer), **default `nil`/unbounded** — this is additive and semver-visible but explicitly not the one-way decision itself; a bounded default is deferred to v1.45's history/row_history consolidation, where it belongs.
- `mix threadline.health.coverage --strict` (exit 1 on any `:error`-severity finding in scope, composable with `--json`).
- `mix threadline.health.coverage --all-schemas` (schema-keyed table/JSON output, mutually exclusive with `--schema=NAME`).
- New `Finding` code `:unresolved_legacy_keys` (`:warning`), replacing the deferred `gen.backfill` generator with a detectability signal for pre-0.11 rows with unresolved `table_pk`.

**Defer (explicit anti-features, not "later"):**
- `[:threadline, :query, ...]` telemetry — duplicates the host's own `[:repo, :query]` event for zero new information; ship a documentation recipe (`metadata.source in ~w(...)` filtering) instead.
- Telemetry emitted from inside Mix task bodies — tasks run outside the host's booted `Application`, so handlers the host attaches never run there anyway; library functions already emit for free when run inside a booted app.
- `Threadline.Health.Finding` code `:invalid_config` — the existing `Mix.raise`/`ArgumentError` fail-fast behavior is already stricter than a soft finding would be; document the existing behavior, add no new code.
- `mix threadline.gen.backfill` as a parameterized SQL-generating Mix task — durable anti-feature; the already-shipped, already-tested guide-SQL-plus-`mix ecto.gen.migration` path is right-sized, matching Carbonite/PaperTrail/Logidze precedent that backfill stays documented SQL, not a generator.

### Architecture Approach (from ARCHITECTURE.md)

Three independent architectural work-items, each root-caused with file:line evidence:

**Major components / decisions:**
1. **Suite parallelism** — `Threadline.DataCase`'s `async: false` default (57 files use it, sharing global un-sandboxed tables) is the architectural root of the ~91% serial figure, not incidental. **Rank 1 fix: CI partitioning** (`mix test --partitions N` / `MIX_TEST_PARTITION`, one Postgres DB per partition) — near-linear wall-clock reduction, zero test-file changes, zero capture-semantics risk; this is Ecto's and Phoenix's own precedent for Sandbox-incompatible suites. **Rank 2: async-ify the narrow telemetry/named-process subset** (10 files) via unique handler ids and per-test process names — small, safe, mechanical. **Rank 3 (separate, audited follow-up, not this milestone): targeted async-ification of pure-read `DataCase` tests** — real per-file audit cost, not a blanket flip. **Explicitly do not**: schema-per-test (defeats the speed goal via per-test migration cost), `:max_cases` tuning alone (no-op for `async: false` modules), or reintroducing Sandbox for a subset (reopens the exact hazard `DataCase`'s no-sandbox design already rejected once).
2. **Guard-test rebalance** — apply a three-part KEEP/CUT rubric: KEEP if an assertion derives from a live source of truth (parsed CI YAML, `mix.exs` version, `git ls-files`) or asserts a structural invariant with no other proof; CUT/MERGE if every assertion is `String.contains?(doc_a, literal)` between two prose documents with no behavioral binding. Result: ~17 files KEEP (real drift detection), 2 files (`stg_doc_contract_test.exs`, `operator_surface/theme_doc_contract_test.exs`) are clean cut/merge candidates, 1 file (`operator_surface_doc_contract_test.exs`) needs a line-item split, and 4 files are flagged unaudited-this-pass. Sized at roughly one plan, not a phase. **Explicit exclusion**: CI-topology/CONTRIBUTING-roster contract tests hardened with v1.43 mutation controls are out of scope for this cut — cutting them would reopen a gap v1.43 phases 220/221 just closed.
3. **`gen.triggers` down orphan** — one-clause bug: `down_body/2` computes both trigger-drops and function-drops from the same `first_run_specs`-filtered set, but a rerun table's newly-created per-table function is never targeted by any migration's `down`. Fix: compute function-downs from the *full* `table_specs` for any table where *this migration* set `needs_per_table: true`, reusing the already-idempotent, usage-checked `TriggerSQL.drop_function_if_unused/2`. A subtler ordering gap remains (partial-rollback vs. full-chain rollback can still leave a one-migration lag) — the recommended resolution is two-sided idempotent-guard emission (both the rerun migration's own down and the first-run migration's down attempt the drop), not a catalog-driven sweep (which would violate the repo's "no CASCADE drops, explicit per-function DROP only" constraint). Verify with a `pg_proc`-scoped property test asserting zero orphaned `threadline_capture_%` functions survive `:down, all: true`, not just "trigger is gone."

### Critical Pitfalls (from PITFALLS.md)

1. **Properties shrinking against a live, shared, non-sandboxed DB** — every new DB-backed property must clean its own rows by a per-run unique key in `setup`/`on_exit` (never rely on rollback), stay `async: false` unless proven pure, and cap `max_runs` explicitly. Avoid by following STACK.md §2's harness reuse exactly.
2. **Tautological properties that restate the implementation** — the single most common property-testing failure mode (QuickCheck/Hypothesis's classic trap): computing "expected" with the same sort/order logic the code under test uses. Every property needs an independently-derived ground truth (set-equality checks, hand-written folds, an independent decoder) and a **mutation control** (temporarily break the invariant, confirm the property goes red) cited in the phase's VERIFICATION.md before merge.
3. **Telemetry as a redaction side-door** — metadata for export/retention/query/install events must carry only counts, durations, table names (bounded cardinality), and status/format atoms — never row values, actor ids, correlation ids, or free-text reasons; this needs its own allowlist test, and the redaction "never leaks" property should additionally attach a test telemetry handler and assert it never observes plaintext.
4. **`history/3` gaining a limit is a behavior-breaking change disguised as a feature** — resolved in FEATURES.md's recommendation (default `nil`), but PITFALLS.md adds the enforcement mechanism: a CHANGELOG/upgrade-guide note framed explicitly as behavior-relevant (not a buried `feat:`), and a test proving the old no-limit call path still returns a plain `list()` unchanged.
5. **Async-converting DB tests without checking for trigger-capture dependence or connection-pool ceiling** — flipping `async: true` broadly is incompatible with the reason the suite has no Sandbox (triggers need committed transactions); any conversion needs per-file cause classification first, and a connection-ceiling check (`too_many_connections` is a known-environmental issue locally) before/after.

## Resolved Conflict: Property Tests vs. Suite-Time Reduction

PITFALLS.md Pitfall 4 explicitly names this milestone's central tension: adding 6+ new property tests (3 of them DB-backed, `async: false`, real round-trips) risks adding more serial wall-clock time than the suite-rebalance work removes — net-negative against the milestone's own goal. ARCHITECTURE.md's Part A ranking (CI partitioning first, async-ify telemetry/named-process files second, audited pure-read async-ification third/deferred) and STACK.md's tiered `max_runs` table (15-20 for DB-backed properties vs. 150-200 for pure ones) are each individually correct, but neither alone resolves the tension — they must be **sequenced and measured together**, per PITFALLS.md Pitfall 4's own instruction and MILESTONE-GUIDE.txt's "measure, don't assume" discipline:

- **Sequencing:** land CI partitioning (ARCHITECTURE.md rank 1 — zero test-file risk) *before or alongside* the property-test phase, not after it, so the property tests' added serial DB time lands against an already-partitioned baseline rather than compounding an unpartitioned one.
- **Measurement:** every property-test phase and the suite-rebalance phase must each report suite wall-clock before/after in VERIFICATION.md — not just at milestone end — so a net-negative is caught mid-milestone, not discovered at closeout.
- **Sizing discipline:** the DB-backed properties (as_of, redaction-leak, retention-boundary) should ship at the smallest defensible `max_runs` (15-20, per STACK.md §3) specifically because they are the ones most likely to erode the gain from partitioning/async work landing in the same milestone.

## Implications for Roadmap

Based on combined research, suggested phase structure (build order, not final phase numbering):

### Phase A: Bench compile fix + gen.triggers down-orphan fix
**Rationale:** Both are small, well-scoped, root-caused-with-evidence bugs with no dependency on anything else in the milestone; landing them first clears carried v1.42/deferred debt and gives the rest of the milestone a clean, green baseline to measure against.
**Delivers:** `bench/mix.exs` `preferred_envs` fix (verified locally); `down_body/2` fix computing function-drops from full `table_specs`, with a `pg_proc`-scoped regression + property test.
**Avoids:** Pitfall 15 (verifying only "trigger is gone," not "function is gone from `pg_proc`"); PITFALLS' bench checklist item (a fix proven only by a one-time local `mix compile`, not a CI job that would have caught the original break).
**Research flag:** Standard patterns — both fixes are read-and-reproduced in STACK.md/ARCHITECTURE.md; low research need during planning.

### Phase B: CI partitioning (suite-time baseline)
**Rationale:** The one lever that reduces serial wall-clock with zero capture-semantics risk and zero test-file changes; landing it *before* the property-test phase means new DB-backed properties compound against an already-improved baseline, directly resolving the Pitfall-4/Architecture-A tension named above.
**Delivers:** `mix test --partitions N` wired into `verify-test`'s CI matrix, `MIX_TEST_PARTITION`-derived test-DB naming, and a resized Flake Detection budget (its own `postgres:16` service + 55-minute/3300s budget constants must be updated in the same change, not left to drift stale, per ARCHITECTURE.md §A.3).
**Avoids:** Pitfall 13 (naive parallelization exhausting the local/CI connection ceiling) — this phase should also verify/raise `pool_size`/`max_connections` as needed.
**Research flag:** Needs a fresh local `mix test --slowest 50` run with DB up before committing to a partition count — ARCHITECTURE.md explicitly declined to fabricate a per-category time split without this citation.

### Phase C: Property tests — pure targets first
**Rationale:** Cursors, ChangeDiff, redaction-policy-validation, and export round-trip are all pure (no DB, `async: true`), cheapest to land, and structurally identical to the two existing property files — lowest risk, fastest feedback on the mutation-control discipline before tackling the DB-backed targets.
**Delivers:** Four new property test files/generator modules under `test/support/`, each with an explicit `max_runs` and a documented mutation control.
**Addresses:** FEATURES.md is silent here (this is STACK.md's domain) — the milestone's "cursor paging," "ChangeDiff," "redaction never leaks" (policy half), and "export round-trips" named targets.
**Avoids:** Pitfall 2 (tie generators that don't exercise the real tiebreak — use `StreamData.member_of` with deliberate duplicates, never wall-clock timing) and Pitfall 3 (tautological properties — independently-derived ground truth required).

### Phase D: Property tests — DB-backed targets
**Rationale:** Sequenced after Phase B (partitioned baseline) and after Phase C proves the mutation-control discipline on cheaper targets; these three (`as_of`, redaction-leak-at-SQL, retention-cutoff-boundary) are the ones most likely to erode suite-time gains, so they land last and smallest.
**Delivers:** Three DB-backed property tests via `Threadline.DataCase` + unique-PK-per-iteration (STACK.md §2), each capped at `max_runs: 15-20`.
**Avoids:** Pitfall 1 (shrinking against a live shared DB) and Pitfall 16 (retention purge must delete whole rows only — assert survivor content-equality, not just row counts, catching an accidental `UPDATE` sneaking into what should be a pure `DELETE` path).
**Research flag:** None — STACK.md §1.2/§1.4/§1.5 and PITFALLS.md Pitfall 1 already fully specify the harness and generator shapes.

### Phase E: Telemetry (export, retention)
**Rationale:** Independent of the property-test phases but should follow Phase D so the redaction property test can be extended (per Pitfall 5) to also assert on telemetry — attaching a test handler and confirming it never observes plaintext, which requires the redaction property infrastructure to already exist.
**Delivers:** 5 new events (`export.completed`/`export.failed`, `retention.purge.{start,stop,exception}` span, `retention.batch_purged`), moduledoc + new `guides/telemetry.md` documentation, and the `[:repo, :query]`-filtering recipe (docs-only, no new event) for query observability.
**Avoids:** Pitfall 5 (PII via metadata — allowlist test), Pitfall 6 (raising-handler test per event family), Pitfall 7 (cardinality — table name only, never actor/correlation/job ids), Pitfall 8 (emit only after the enclosing transaction commits, never inside), Pitfall 9 (don't wrap `{:ok,_}|{:error,_}`-returning functions in `:telemetry.span/3` — execute on both branches instead; span is reserved for retention purge specifically), Pitfall 10 (document every event shape with the same rigor as the existing five before it becomes one-way).

### Phase F: `history/3` limit
**Rationale:** Self-contained, additive, no dependency on the other phases; the `nil`-default decision (FEATURES.md) plus the CHANGELOG/upgrade-guide framing (PITFALLS.md Pitfall 11) are both fully specified.
**Delivers:** `:limit` option on `history/3`, `ArgumentError` on `0`/negative/non-integer, moduledoc pointer to `row_history_page/4`, upgrade-guide note framed as behavior-relevant.
**Research flag:** None — fully specified by FEATURES.md §B and PITFALLS.md Pitfall 11 together.

### Phase G: Deferred v1.42 health/CLI items
**Rationale:** Independent, additive, opt-in-flag work; can run in parallel with any of B–F.
**Delivers:** `mix threadline.health.coverage --strict` and `--all-schemas`, new `:unresolved_legacy_keys` Finding code, documentation-only note on the existing `Mix.raise` fail-fast behavior (no `:invalid_config` code).
**Avoids:** Pitfall 17 (exit-code contract must be provably unchanged for the non-strict default — test a severity × strict/non-strict matrix, not just a happy-path smoke test).

### Phase H: Guard-test rebalance
**Rationale:** Lowest-risk, most self-contained, smallest (roughly one plan per ARCHITECTURE.md's own sizing) — can land any time after the CI-topology mutation-control cross-check is done; sequence last only because it's the lowest-priority/lowest-risk item, not because of a dependency.
**Delivers:** Cut/merge of ~2-3 files (`stg_doc_contract_test.exs`, `operator_surface/theme_doc_contract_test.exs`, a line-item split of `operator_surface_doc_contract_test.exs`), after applying the KEEP/CUT rubric to the 4 not-yet-audited files.
**Avoids:** Pitfall 12 (cutting a guard test that has a documented v1.43 mutation control reopens a gap 220/221 just closed) — cross-check the cut list against `.planning/milestones/v1.43-MILESTONE-AUDIT.md` before any deletion; diff the CI required-aggregate job count before/after and confirm it's unchanged.

### Phase Ordering Rationale

- **A before everything:** clears small, independent, already-diagnosed debt so later phases measure against a clean baseline.
- **B before C/D:** CI partitioning must land before the property-test phases (or at minimum before the DB-backed sub-phase, D) so their added serial time is absorbed by, not compounded against, the unpartitioned baseline — this is the direct resolution of the property-tests-vs-suite-time conflict flagged in the task.
- **C before D:** pure properties prove the mutation-control discipline cheaply before the team tackles the more expensive, riskier DB-backed targets.
- **D before E:** the redaction property (D) must exist before telemetry (E) can extend it with a "telemetry handler never observes plaintext" assertion (Pitfall 5's own recommended check).
- **F, G, H:** fully independent of B–E and each other; can be parallelized or interleaved based on team capacity, but H (guard-test rebalance) is lowest-risk/lowest-priority so it's listed last.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase B (CI partitioning):** needs a fresh local `mix test --slowest 50` run (DB up) before committing to partition count — ARCHITECTURE.md explicitly declined to fabricate this number.
- **Phase D (DB-backed properties):** the two-sided idempotent-guard-emission fix for the down-orphan's ordering gap (Phase A) and the retention survivor-content-equality check both need careful review during plan-phase, not just execute-phase, given their correctness-sensitive nature.

Phases with standard patterns (skip research-phase):
- **Phase A:** both fixes are fully root-caused with file:line evidence and a verified local repro/fix in STACK.md and ARCHITECTURE.md.
- **Phase C:** pure property shapes are fully specified per-target in STACK.md §1, mirroring the two existing property files exactly.
- **Phase E:** telemetry event shapes, naming convention, and every pitfall/mitigation are fully specified in FEATURES.md §A and PITFALLS.md Pitfalls 5-10.
- **Phase F:** fully specified by FEATURES.md §B and PITFALLS.md Pitfall 11.
- **Phase G:** fully specified by FEATURES.md §C/D.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack (property-test strategy, bench fix) | HIGH | Bench fix and DB-sandbox strategy reproduced locally against this repo; ecosystem precedent is web-sourced but not exhaustively cross-checked; exact `max_runs` numbers are a judgment call bounded by existing-file precedent |
| Features (telemetry/history-limit/health-CLI/backfill decisions) | HIGH | Code citations verified against current `milestone/v1.44` tree at `ca032824`; ecosystem precedent (Ecto/Oban/Phoenix/PaperTrail/Ash/Carbonite) is well-established public convention |
| Architecture (suite parallelism, guard rebalance, down-orphan) | HIGH | All claims grep/read evidence from this tree; no full-suite re-run performed (explicit constraint) — timings cited from existing todo/seed records, not re-measured this pass |
| Pitfalls | HIGH for repo-specific claims (read from lib/test/.planning); MEDIUM for ecosystem-precedent claims (StreamData/Carbonite/Oban/PaperTrail/Logidze community reports, not independently re-verified against every version) |

**Overall confidence:** HIGH

### Gaps to Address

- **Live suite timing breakdown:** no `mix test --slowest 50` run was performed with the DB up during research (explicit read-only/no-full-suite-rerun constraint). The 209s/191s split and per-category serial-time breakdown are cited from existing docs (`.planning/todos/pending/2026-09-28-ci-suite-sync-bound-parallelism.md`, Flake Detection dispatch run 36359135268), not freshly measured. **Handle during planning:** Phase B's plan should open with a fresh local timing run before committing to a partition count.
- **4 unaudited guard-test files:** `operator_surface/coverage_doc_contract_test.exs`, `operator_surface/policy_show_doc_contract_test.exs`, `storage_schema_migration_contract_test.exs`, `storage_schema_prefix_contract_test.exs` were seen in the async-inventory pass but not opened for content. **Handle during planning:** apply ARCHITECTURE.md's B.1 rubric to each before including them in Phase H's cut/merge list.
- **Down-orphan ordering gap:** the two-sided idempotent-guard-emission fix (Phase A) resolves the documented partial-rollback case cleanly but the full-chain-rollback ordering (migration N's down running before migration 1's down) needs the `TriggerMigration.covered_pairs/1` scan wired in carefully — flagged as needing "careful review during plan-phase" above, not a pure execute-phase task.
- **`--strict`/`--all-schemas` exit-code baseline:** PITFALLS.md notes no existing test currently asserts specific exit codes per health-finding severity — confirm this gap during Phase G planning before assuming a "before" baseline exists to diff against.

## Sources

### Primary (HIGH confidence — repo-grounded, reproduced or read directly)
- `mix.exs`, `bench/mix.exs`, `bench/bench_helper.exs`, `test/test_helper.exs`, `test/support/data_case.ex`, `test/support/naming_generators.ex`, `test/threadline/capture/naming_property_test.exs`, `test/threadline/mix/trigger_migration_property_test.exs`
- `lib/threadline/query/cursors.ex`, `lib/threadline/query.ex`, `lib/threadline/change_diff.ex`, `lib/threadline/capture/redaction_policy.ex`, `lib/threadline/capture/trigger_sql.ex`, `lib/threadline/retention.ex`, `lib/threadline/export.ex`, `lib/threadline/telemetry.ex`, `lib/threadline/health.ex`, `lib/threadline/health/finding.ex`, `lib/threadline.ex`
- `lib/mix/tasks/threadline.gen.triggers.ex`, `lib/mix/tasks/threadline.health.coverage.ex`, `lib/mix/tasks/threadline.verify_coverage.ex`, `lib/mix/tasks/threadline.retention.purge.ex`, `lib/threadline/mix/trigger_migration.ex`
- `guides/upgrading-to-0.11.md`, `.planning/PROJECT.md`, `.planning/MILESTONE-GUIDE.txt`, `.planning/milestones/v1.42-MILESTONE-AUDIT.md`, `.planning/milestones/v1.43-MILESTONE-AUDIT.md`, `.planning/RETROSPECTIVE.md`
- 24 `*doc_contract*`/`*_contract_test*` files read for the guard-test rebalance classification
- Grep inventory of all 222 `test/**/*_test.exs` files (async annotations, DB/filesystem/env/mix-task/telemetry/process categorization)

### Secondary (MEDIUM confidence — ecosystem precedent, web-sourced, not independently re-verified per version)
- StreamData/PropCheck comparison, Hypothesis (Python) CI-profile and shrink-to-minimal-example lessons, QuickCheck/proptest generator-design lessons
- Ecto/Oban/Phoenix/Finch/Broadway telemetry span-vs-execute conventions; `telemetry_metrics` numeric-measurement/bounded-cardinality conventions; OpenTelemetry semantic conventions
- PaperTrail/Carbonite/Logidze/django-simple-history precedent (test-suite shape, backfill-as-documented-SQL, additive-only versioning-row design)
- Ash `Ash.Query.limit/2` vs `Ash.Query.page/2` precedent
- Oban's `Oban.Testing`/Sandbox-prefix isolation precedent (confirmed as non-transferable here, since Threadline has already ruled out Sandbox)

---
*Research completed: 2026-09-30*
*Ready for roadmap: yes*
