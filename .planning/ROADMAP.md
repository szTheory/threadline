# Roadmap: Threadline

## Milestones

- 🚧 **v1.45 1.0 API Contract** - Phases 231-237 (in progress, opened 2026-10-02)
- [x] **v1.44 Behavioral Depth: Properties, Twins, Telemetry** - Phases 224-230 (shipped 2026-10-02, released as 0.12.0). Archive: `.planning/milestones/v1.44-ROADMAP.md`
- [x] **v1.43 Supply Chain, CI Economy and Repo Hygiene** - Phases 214-223 (shipped 2026-09-30, released as 0.11.1 and 0.11.2). Archive: `.planning/milestones/v1.43-ROADMAP.md`
- [x] **v1.42 Capture Correctness for Real Table Shapes** - Phases 208-213 (shipped 2026-09-26, released as 0.11.0). Archive: `.planning/milestones/v1.42-ROADMAP.md`
- [x] **v1.41 Green, Clean, and Honest** - Phases 198-207 (shipped 2026-09-24). Archive: `.planning/milestones/v1.41-ROADMAP.md`
- [x] **v1.40 Automated Operator-UI Critique & Forward-Only Iteration Harness** - Phases 194-197 (shipped 2026-08-27). Archive: `.planning/milestones/v1.40-ROADMAP.md`
- [x] **v1.39 Quality Baseline, Schema Confidence, and CI Efficiency** - Phases 189-193 (shipped 2026-07-03). Archive: `.planning/milestones/v1.39-ROADMAP.md`
- [x] **v1.38 Operator UI Page-by-Page IA & Design-System Polish** - Phases 181-188 (shipped 2026-06-30). Archive: `.planning/milestones/v1.38-ROADMAP.md`
- [x] **v1.37 Operator Surface Design-System Stress Test & Component System** - Phases 171-180 (shipped 2026-06-20). Archive: `.planning/milestones/v1.37-ROADMAP.md`
- [x] **v1.36 Operator Surface Light Mode** - Phases 166-170 (shipped 2026-06-14). Archive: `.planning/milestones/v1.36-ROADMAP.md`
- [x] **v1.35 Unified Logo & Brand Book v2** - Phases 159-165 (shipped 2026-06-12). Archive: `.planning/milestones/v1.35-ROADMAP.md`
- [x] **v1.34 Local Docker Admin UI DX** - Phases 154-158 (shipped 2026-06-07). Archive: `.planning/milestones/v1.34-ROADMAP.md`

## 🚧 v1.45 1.0 API Contract (In Progress)

**Milestone Goal:** Lock down a public API that adopters can depend on for all of 1.x: one read facade, one obvious entry point per job, consistent return shapes, complete typespecs and docs behind a gate, a 1.x stability promise enforced by tests, and a deliberate support floor. Then declare **1.0.0** through release-please.

**Granularity:** coarse config, but seven phases, the ceiling for this rung. Each boundary is an ordering constraint, not a feature split. The facade topology and the association edge are the one-way structural calls and touch the same files, so they go first. Consolidation and deprecation need the final topology to know which module each delegate lives on. Return shapes must settle before specs are written. Specs are written once, against the settled surface. The stability contract pins a surface that will no longer move. The partition-weight refresh waits until the test churn settles. The upgrade guide and the release come last because they must list every breaking change. Phase 233 carries a single requirement. It could fold into 232, but keeping it separate means specs in 234 are written against final lookup signatures, with a phase gate in between.

**Evidence:** `.planning/research/SUMMARY.md` (Implications for Roadmap, Reconciling the Five Conflicts, Watch-Outs) and `.planning/REQUIREMENTS.md`. Where they conflict, REQUIREMENTS.md wins. The sketch's SPEC-04 is merged into API-08, and its DOCS-04/05 and CI-02 are not v1.45 requirements.

### Dependency spine

```
231 Facade topology + edge ─→ 232 Consolidation, deprecation, bounded default ─→ 233 Return shapes ─→ 234 Specs + gate ─→ 235 Contract tests + guides ─→ 236 Floor + partition weights ─→ 237 Upgrade guide + 1.0.0
```

- **231 before 232.** Deprecated delegates and the `Page` struct live on the facade. Which modules are hidden decides where each retired name keeps its one-line delegate.
- **233 before 234.** Specs are written against final signatures. A spec written for `audit_transaction/2` before its return shape changes would be rewritten.
- **234 before 235.** CONTRACT-05 edits the same schema moduledocs that SPEC-01 backfills, and the stability guide cites the specced surface.
- **235 before 236.** CI-01 refreshes the partition weights only after the last test-adding phase before the release. The missing-weight check is permanent, so the doc-contract test that 237 adds must carry its own weight entry.
- **FLOOR before REL.** The PG 15 floor is a breaking change that the upgrade guide and the 1.0.0 CHANGELOG must list.
- **REL-01's config flip ships in the landing change.** Nothing from this milestone reaches main before the single `feat!:` squash, so `bump-minor-pre-major` is flipped in 237, before the first breaking commit lands on main.

### Cross-cutting invariants (hold in every phase)

- **Every breaking change is recorded when it is made.** The phase that makes a breaking change adds its CHANGELOG `Unreleased` breaking-changes entry, and its commit carries a `BREAKING CHANGE:` footer. REL-02 cross-checks both at the end and does not reconstruct either from memory.
- **Grep before hiding.** Before any name or module becomes `@moduledoc false` / `@doc false`, guides, the README and the example app are grepped for it, and every hit is rewritten in the same change.
- **Warnings stay errors.** `mix compile --warnings-as-errors` stays clean for `lib/`, `test/` and the example app at each phase close. Nothing internal calls a deprecated name.
- **Operator UI stays parked.** `operator_surface` LiveView and markup change only where API-04, API-06 or API-07 forces a call-site update.
- **No planning vocabulary in product code.** No phase or plan IDs in `lib/`, moduledocs, guides, CHANGELOG or releasable commit subjects.
- **Zero human verification.** Every success criterion names the test, alias or run ID that proves it. Judgment calls (spec informativeness, guide prose) go to agent review against a written rubric. `mix ci.all` is green at each phase close. The maintainer handles only push, merge, `production-hex` approval and scope decisions.
- **Never `git add .planning/` wholesale.** Stage explicit file lists only, and keep home paths and usernames out of planning prose (the hygiene guard scans `.planning/`).

## Phases

- [x] **Phase 231: Facade Topology and the Capture/Semantics Edge** - `Threadline` is the one documented read API, and the capture schemas no longer declare an association to the semantics schema
- [x] **Phase 232: Consolidated Reads, Deprecations and the Bounded Default** - One `row_history/3`, one `Threadline.Page`, a 200-row default with truncation telemetry, and a warning-only path off every retired name (completed 2026-10-03)
- [x] **Phase 233: Lookup Return Shapes** - Single-subject lookups return `{:ok, _}` / `{:error, :not_found}` with raising `!` siblings (completed 2026-10-03)
- [ ] **Phase 234: Typespec and Doc Completion Gate** - Every public function has an informative `@spec` and a `@doc`, enforced by a test, and the facade page is grouped by job
- [ ] **Phase 235: Stability Contract and Adopter Guides** - The 1.x promise is written down and pinned by tests, with the supported-table-shapes guide and the redaction threat model
- [ ] **Phase 236: Support Floor and Partition Weights** - PostgreSQL 15 is the tested minimum, the support policy has one table, and every test file is weighted
- [ ] **Phase 237: Upgrade Guide and 1.0.0** - A 0.11/0.12 adopter can follow one guide to 1.0, and hex.pm serves threadline 1.0.0

## Phase Details

### Phase 231: Facade Topology and the Capture/Semantics Edge

**Goal**: An adopter reading the docs finds one read API, `Threadline`, with `Threadline.Query.timeline_query/1` as the single Ecto-composition escape hatch. The capture-layer schemas no longer declare an association to the semantics layer, and every caller that reads `transaction.action` still gets the same shape.
**Depends on**: Nothing (first phase)
**Requirements**: API-04, API-07
**Success Criteria** (what must be TRUE):

  1. `Code.fetch_docs/1` reports `Threadline.Query` and `Threadline.Investigation` as hidden. `public_surface_contract_test.exs` pins the hidden set and fails if either becomes documented again. A test asserts that the `Threadline` moduledoc links `Threadline.Query.timeline_query/1` as the escape hatch.
  2. `guides/audit-indexing.md`, `guides/how-threadline-works.md` and `guides/code-walkthrough.md` call `Threadline.*` and never call the hidden modules, except `timeline_query/1`. A doc-contract test fails on any other `Threadline.Query.` or `Threadline.Investigation.` call in guides, the README or the example app.
  3. A test asserts that `AuditTransaction` declares no association to `AuditAction` and that `AuditAction` declares none to `AuditTransaction`, via `__schema__(:associations)`. Re-adding `belongs_to :action` turns it red (mutation control recorded).
  4. Every existing assertion on `transaction.action` passes unchanged through the exploration-layer hydrate helper. The `action_id` column and its foreign key are unchanged: no migration or trigger SQL in the diff touches them.
  5. `mix compile --warnings-as-errors` is clean for `lib/`, `test/` and the example app, and `mix ci.all` is green.

**Plans**: 3/3 plans complete

Plans:
**Wave 1**

- [x] 231-01-PLAN.md — API-07: drop the AuditTransaction/AuditAction associations, hidden `hydrate_actions/3` helper, rewired internal call sites, deprecated `:preload :action` shim, CHANGELOG (wave 1) — complete 2026-10-03

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 231-02-PLAN.md — API-04: hide `Threadline.Query`/`Threadline.Investigation`, name the `timeline_query/1` escape hatch, facade-only lib docs and guides, strict docs gate green (wave 2) — complete 2026-10-03

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 231-03-PLAN.md — facade-only doc-contract scanner, example script on the facade, mutation controls, full `mix ci.all` gate (wave 3) — complete 2026-10-03

### Phase 232: Consolidated Reads, Deprecations and the Bounded Default

**Goal**: An adopter reads a row's history through one function with keyword opts. By default it is bounded, the cursor path proves completeness, and truncation is observable. Every paged read returns one `Page` shape. Internal helpers are out of the docs. Any adopter still on a retired name gets a working call and one compiler warning naming the replacement.
**Depends on**: Phase 231
**Requirements**: API-01, API-02, API-03, API-05, API-08
**Success Criteria** (what must be TRUE):

  1. Against real Postgres with more than 200 changes on one row, `Threadline.row_history/3` with no options returns exactly 200 changes, newest first, as a bare list. `limit: n` and `limit: :infinity` override the cap. Walking `cursor:` + `page_size:` pages until `has_more: false` yields exactly the `limit: :infinity` result. Passing `:limit` with `:cursor` raises `ArgumentError`.
  2. Hitting the cap emits `[:threadline, :row_history, :truncated]`. The event is in the telemetry registry allowlist, and the leak check proves its metadata carries no row values or actor ids. A test proves export and `as_of` stay unbounded past 200 changes. The v1.44 properties that read history pass `limit: :infinity` or walk the cursor, and they stay green.
  3. Every paged read on the facade returns `%Threadline.Page{entries, cursor, has_more}`, and `TimelinePage` / `ActorHistoryPage` no longer exist. A facade-naming test asserts that `timeline/2` + `timeline_page/2` is the only paired-name pattern. The `actor_history/2` and `actor_window/3` docs each state their return type first and cross-link the other, pinned by a doc-contract test.
  4. Each retired entry point (`history/3`, `row_history/4`, `row_history_page/4` and the filters-as-positional-argument shapes, on every module that exposed them) is a one-line `@deprecated` delegate. Each has a parity test against its replacement and a spec matching the replacement's. The replacements carry `@doc since: "1.0.0"`. `mix compile --warnings-as-errors` is clean for `lib/`, `test/` and the example app.
  5. The `Threadline.Telemetry` `emit_*` functions, the raw `*_query` builders other than `timeline_query/1`, and moduledoc-less modules such as `Threadline.Export.CSV` are absent from `Code.fetch_docs/1` output. A grep test finds no reference to any hidden name in guides, the README or the example app.

**Plans**: 6 plans

Plans:
**Wave 1**

- [x] 232-01-PLAN.md — API-03: `Threadline.Page` with exact `has_more`, `cursor: :start`/nil rules, timeline/row/investigation pagers + export walk on Page, `TimelinePage` deleted (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 232-02-PLAN.md — API-02, API-03: `actor_history/2` on Page with `cursor:`/`page_size:` and warning legacy options, actor LiveView forced edit, `ActorHistoryPage` deleted, actor read doc contract (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 232-03-PLAN.md — API-01: `row_history/3` with the 200 default, `limit:`/`cursor:` modes, cursor mode on `actor_window/3`/`correlation_bundle/3`, deprecated `row_history/4` arity split, truncation telemetry, drawer opt-out (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 232-04-PLAN.md — API-08: every retired name a one-line `@deprecated` delegate with spec + parity test, exact deprecation inventory, `lib/` warnings-as-errors clean, CHANGELOG Deprecations (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 232-05-PLAN.md — API-08, API-01: all `test/` and example-app callers migrated off retired names (`Threadline.Test.RowHistory`, unbounded v1.44 property baseline), warnings-as-errors clean for `test/` and the example (wave 5)

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 232-06-PLAN.md — API-05: `emit_*`/`export_changes_query` hidden, scanners for hidden and retired names (no guide exemption), guides/README rewritten incl. upgrade guides, facade-naming contract, `mix ci.all` phase gate (wave 6)

### Phase 233: Lookup Return Shapes

**Goal**: An adopter handles a missing transaction the same way on every single-subject lookup: a tagged tuple by default and a raising `!` sibling when absence is a bug.
**Depends on**: Phase 232
**Requirements**: API-06
**Success Criteria** (what must be TRUE):

  1. `Threadline.audit_transaction/2` and `Threadline.transaction_context/2` return `{:ok, _}` for an existing id and `{:error, :not_found}` for a missing one, matching `incident_bundle/2`. Tests cover both cases for each function.
  2. `audit_transaction!/2` and `transaction_context!/2` return the bare value for an existing id and raise for a missing one. Tests cover both cases for each.
  3. Every internal caller in `lib/`, the operator surface, the example app and the guides uses the new shapes. The CHANGELOG `Unreleased` breaking-changes section records the change, and `mix ci.all` is green.

**Plans**: 4 plans

Plans:
**Wave 1**

- [x] 233-01-PLAN.md — shared scoped row fetch (`TransactionLookup`), facade `audit_transaction/2` + `!`, public `Threadline.NotFoundError` (Plug 404) (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 233-02-PLAN.md — `transaction_context/2` to the tuple shape and `incident_bundle/2` on the shared fetch, both `!` siblings, ≤3-query bundle, TransactionLive call site (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 233-03-PLAN.md — deprecate `Threadline.Query.audit_transaction/2` with parity, lookup-family doc contract (`as_of/4` exempt), CHANGELOG and guides (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 233-04-PLAN.md — fail-closed `Scope.apply/2` on every scoped read, example catch-all, integration-contracts guide, phase-close `mix ci.all` (wave 4)

### Phase 234: Typespec and Doc Completion Gate

**Goal**: Every public function an adopter can see has a `@doc` and an `@spec` that says something real. Coverage cannot regress, and the facade page reads by job rather than alphabetically.
**Depends on**: Phase 233
**Requirements**: SPEC-01, SPEC-02, SPEC-03
**Success Criteria** (what must be TRUE):

  1. A new `async: true` test using `Code.fetch_docs/1` and `Code.Typespec.fetch_specs/1` reports zero public functions missing a `@doc` or `@spec` across every documented module under `lib/`, down from a baseline of 129 of 169 missing. Adding an undocumented or unspecced public function turns it red (mutation control recorded).
  2. No public spec uses bare `term()` or `any()` where a real shape exists, and option arguments use named `@type` option lists rather than bare `keyword()`. Agent review against a written rubric records a pass in VERIFICATION.md.
  3. Strict Dialyzer is green with zero ignore entries.
  4. Every `Threadline` facade function carries a `@doc group:` of Capture & Transactions, Querying & Timelines, Actions & Context, or Operations. A test fails on any facade function without a group.

**Plans**: 6 plans

Plans:
**Wave 1**

- [x] 234-01-PLAN.md — SPEC-01/02/03 gates as exact ratchets: doc/spec coverage gate with fixture mutation control, hidden pin, option parity, M-checks, bare-type lint, facade-groups ratchet, D-27 grep contracts, frozen 234-SPEC-RUBRIC.md (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 234-02-PLAN.md — SPEC-02/03 facade: named option/filter/row-key types, `Threadline.Query.OptionKeys`, closed facade allowlists after moving the actor LiveView off the facade, four job groups + `## Jobs`, rubric doc rewrites, size pin, ExDoc `~> 0.40`, WR-01 test-first (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 234-03-PLAN.md — SPEC-01/02 Evidence: 20 gaps documented and specced, `EvidenceRecord.t`, two Proof helpers hidden with CHANGELOG record (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 234-04-PLAN.md — SPEC-01/02 operations: Export closed and typed via hidden `ExportReads` (export controller + timeline count moved), ChangeDiff/Storage/Orchestrator/TaskAdapter, StorageSchema (hide 6, spec 5) and the small modules (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 234-05-PLAN.md — SPEC-01/02 data types: every schema and result struct field hand-typed, `AuditAction.t`, precise `ActorRef.t`, Page cursor typedoc, `Audit.transaction/3` type variable (wave 5)

**Wave 6** *(blocked on Wave 5 completion)*

- [ ] 234-06-PLAN.md — SPEC-02 close: five strict Dialyzer flags with every finding fixed and zero ignores, ratchets deleted (gates assert zero), live mutation recorded, CHANGELOG/CONTRIBUTING/baseline notes, review input, `mix ci.all` (wave 6)

### Phase 235: Stability Contract and Adopter Guides

**Goal**: An adopter or security reviewer can read exactly what 1.x promises, which tables Threadline supports, and what redaction does and does not guarantee. Every one of those statements is held in place by a test that fails CI on drift.
**Depends on**: Phase 234
**Requirements**: CONTRACT-01, CONTRACT-02, CONTRACT-03, CONTRACT-04, CONTRACT-05, DOCS-01, DOCS-02
**Success Criteria** (what must be TRUE):

  1. `guides/stability.md` states:
     - the Elixir API tier, with the deprecation policy
     - the additive-only Database Contract tier
     - the named security/correctness exception class
     - the explicitly-not-API operator-surface internals
     - the 0.12.x six-month backport window
     A doc-contract test pins each statement.
  2. A schema-snapshot test pins column names, types and nullability for `audit_transactions`, `audit_changes` and `audit_actions`, plus the shipped indexes. A literal test pins the GUC name `threadline.actor_ref` and the trigger-function naming scheme. Renaming or dropping any of these turns CI red (mutation controls recorded).
  3. Additive-only allowlist tests pin:
     - the CSV and JSON export headers, with and without action metadata
     - the `Health.Finding` code set
     - each mix task's accepted flags
     - the `threadline_operator_surface/2` option keys and documented mount routes
     Removing an entry fails, and adding one requires an allowlist update.
  4. The `AuditChange`, `AuditTransaction` and `AuditAction` moduledocs each list a stable field subset and state the additive key/shape promise for the jsonb columns. A test pins each list against `__schema__(:fields)`.
  5. Each guide has a doc-contract test:
     - The supported-table-shapes guide covers composite and non-`id` keys, `primary_key:`, cross-schema tables, long identifiers, `char(n)`, and partitioned/unlogged tables and views. Its test checks every cited option and name against the code.
     - In the redaction threat model, every guarantee names its proving property test or health check, and the guide lists where plaintext can still exist. Its test rejects unscoped absolutes.

**Plans**: TBD

### Phase 236: Support Floor and Partition Weights

**Goal**: An adopter sees one support-policy table that matches what CI actually tests. PostgreSQL 15 is the proven minimum, and the partitioned suite weights every test file after this milestone's churn.
**Depends on**: Phase 235
**Requirements**: FLOOR-01, FLOOR-02, CI-01
**Success Criteria** (what must be TRUE):

  1. The CI `min` lane in `ci.yml` runs PostgreSQL 15, pinned by the topology contract test in the same commit. The full suite passes locally against PostgreSQL 15. The CHANGELOG `Unreleased` breaking-changes section records the new floor.
  2. `guides/upgrade-path.md` contains one support-policy table with the Elixir/OTP/PG floor and the CI lanes. A doc-contract test fails when it disagrees with `mix.exs` or the `ci.yml` `min` lane values.
  3. `bin/ci-test-partitions --write-weights` has regenerated `test/partition_weights.txt`, so the 10 unweighted v1.44 property files and every test added in 231-235 are weighted. A permanent check fails when any test file is missing from the weights file, and a deliberately unweighted file turns it red (mutation control recorded).
  4. `mix ci.all` is green.

**Plans**: TBD

### Phase 237: Upgrade Guide and 1.0.0

**Goal**: A 0.11 or 0.12 adopter can follow one guide through every breaking change to 1.0. The 1.0.0 CHANGELOG is complete, and hex.pm serves threadline 1.0.0, cut by release-please from one `feat!:` squash.
**Depends on**: Phase 236
**Requirements**: DOCS-03, REL-01, REL-02, REL-03
**Success Criteria** (what must be TRUE):

  1. `guides/upgrading-to-1.0.md` has one numbered step for each breaking change: the facade collapse, the history default, the `Page` struct, lookup return shapes, the association, the PG floor and deprecations. It follows the `upgrading-to-0.11.md` template and states whether trigger regeneration is required. A doc-contract test cross-checks its steps against the CHANGELOG breaking-changes entries. The test's file has a partition weight, so the CI-01 check stays green.
  2. The 1.0.0 CHANGELOG lists every breaking change and deprecation, cross-checked against `git log --grep="BREAKING CHANGE"` over the milestone range. VERIFICATION.md records the cross-check.
  3. `release-please-config.json` has `bump-minor-pre-major` off in the landing change. `mix verify.bump_rehearsal`, run on committed HEAD, shows 1.0.0 and not 0.13.0 before merge. The squash commit carries a `Release-As: 1.0.0` footer.
  4. The milestone lands on main as one squash with a conventional `feat!:` title. `CI required` is green, including the `min` lane on PostgreSQL 15 and the `latest` lane with re-checked pins. hex.pm serves threadline 1.0.0. Push, merge and the `production-hex` publish each run under an explicit maintainer grant.

**Plans**: TBD

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 231. Facade Topology and the Capture/Semantics Edge | 3/3 | Complete    | 2026-10-03 |
| 232. Consolidated Reads, Deprecations and the Bounded Default | 6/6 | Complete    | 2026-10-03 |
| 233. Lookup Return Shapes | 4/4 | Complete    | 2026-10-03 |
| 234. Typespec and Doc Completion Gate | 0/TBD | Not started | - |
| 235. Stability Contract and Adopter Guides | 0/TBD | Not started | - |
| 236. Support Floor and Partition Weights | 0/TBD | Not started | - |
| 237. Upgrade Guide and 1.0.0 | 0/TBD | Not started | - |

## Prior Milestones

<details>
<summary>v1.44 Behavioral Depth: Properties, Twins, Telemetry (Phases 224-230) - SHIPPED 2026-10-02</summary>

- [x] Phase 224: Capture and Bench Fixes (4/4 plans) — completed 2026-09-30
- [x] Phase 225: Suite Baseline and Partitioned CI (4/4 plans) — completed 2026-10-01
- [x] Phase 226: Pure Property Tests and Run Budget (6/6 plans) — completed 2026-10-01
- [x] Phase 227: DB-Backed Property Tests (5/5 plans) — completed 2026-10-01
- [x] Phase 228: Telemetry (6/6 plans) — completed 2026-10-02
- [x] Phase 229: Adopter API and Health Additions (4/4 plans) — completed 2026-10-02
- [x] Phase 230: Rebalance, Net-Suite Check and 0.12.0 (4/4 plans) — completed 2026-10-02

Capture rollback leaves a clean `pg_proc` and the bench compiles bare. Mutation-controlled property tests cover cursor paging, ChangeDiff, redaction, export round-trip, `as_of` and the retention cutoff, and they fixed a bare-CR CSV defect and a dry-run under-count. A leak-checked 14-event `Threadline.Telemetry` registry with `guides/telemetry.md`. `history/3` `:limit` and `health.coverage --strict`/`--all-schemas`. Weighted partitioned CI cut the test step 40.1% net (507 s vs 846 s). 27/27 requirements. Released as 0.12.0 (#73, #74, #75). Archive: `.planning/milestones/v1.44-ROADMAP.md`.

</details>

<details>
<summary>v1.43 Supply Chain, CI Economy and Repo Hygiene (Phases 214-223) - SHIPPED 2026-09-30</summary>

- [x] Phase 214: Baseline Measurement (4/4 plans) — completed 2026-09-26
- [x] Phase 215: Supply Chain Gate (6/6 plans) — completed 2026-09-26
- [x] Phase 216: CI Platform Currency (8/8 plans) — completed 2026-09-27
- [x] Phase 217: Repo Hygiene (7/7 plans) — completed 2026-09-27
- [x] Phase 218: CI Economy: Remove Waste (8/8 plans) — completed 2026-09-27
- [x] Phase 219: Deps-Only Build Cache (3/3 plans) — completed 2026-09-28
- [x] Phase 220: Newest-Toolchain Lane (4/4 plans) — completed 2026-09-28
- [x] Phase 221: CI Names and Order (4/4 plans) — completed 2026-09-29
- [x] Phase 222: SEED-006 Change-Aware Lanes (conditional; CLOSED on data) (2/2 plans) — completed 2026-09-29
- [x] Phase 223: Close v1.43 Audit Debt (6/6 plans) — completed 2026-09-29

Advisories cleared behind a required Hex audit gate, a committed toolchain pin, a required local-path/PII guard with a forward scrub, and measured CI economy: weekly flake lane, deduplicated jobs, deps-only build cache (warm run 49 vs 55 billed runner-min, critical path 547 vs 623 s), and a voting newest-toolchain lane. Check names now say what each check proves. 24/24 requirements. Released as 0.11.1 (#55, #56) and 0.11.2 (#66, #67, #69). Archive: `.planning/milestones/v1.43-ROADMAP.md`.

</details>

<details>
<summary>v1.42 Capture Correctness for Real Table Shapes (Phases 208-213) - SHIPPED 2026-09-26</summary>

- [x] Phase 208: Identifier Foundation (5/5 plans)
- [x] Phase 209: Collision-Free Emission (6/6 plans)
- [x] Phase 210: PK-Agnostic Capture (5/5 plans)
- [x] Phase 211: Read-Side Agreement (4/4 plans)
- [x] Phase 212: Detection and Adopter Twins (7/7 plans)
- [x] Phase 213: Upgrade Guide and 0.11.0 Release (3/3 plans) — completed 2026-09-26

Capture that is correct for every primary-key shape, schema and name length. Collision-free per-table functions fix the shared-function security issue, and history/as-of reads match exactly. Health findings detect broken capture. There is an upgrade guide with real-PG-proven backfill SQL. 28/28 requirements. Released as 0.11.0 (#52, #53, #54). Archive: `.planning/milestones/v1.42-ROADMAP.md`.

</details>

<details>
<summary>v1.41 Green, Clean, and Honest (Phases 198-207) - SHIPPED 2026-09-24</summary>

Repo hygiene and quality ratchet: real Credo/Dialyzer/xref gates, `mix test` 83 failures to 0 on CI, suite independent of `.planning/`, clean public surface, 0.10.0 and 0.10.1 on hex.pm, installer and `gen.triggers` rerun fixes (0.10.2 CHANGELOG entry, unreleased). 53/54 requirements; GREEN-07 accepted-pending (D-39). Archive: `.planning/milestones/v1.41-ROADMAP.md`.

</details>

<details>
<summary>v1.40 Automated Operator-UI Critique & Forward-Only Iteration Harness (Phases 194-197) - SHIPPED 2026-08-27</summary>

- [x] Phase 194: Deterministic Scorecard-Cube Ledger & Mechanical Capture Foundation (3/3 plans) — completed 2026-07-03
- [x] Phase 195: Validated Adversarial Critic Runner & Panel (9/9 plans) — completed 2026-08-26
- [x] Phase 196: Forward-Only Net-Positive Gate & First Proven Iteration (6/6 plans) — completed 2026-08-26
- [x] Phase 197: Coverage Growth, Adversarial Closeout & Design-Debt Register (3/5 plans; 03/04 waived on a ratified PROOF-02 shortfall) — completed 2026-08-27

28/29 requirements satisfied. The paid critic loop is PARKED on ratified spend/value grounds; residual design debt lives in `197-DESIGN-DEBT-REGISTER.md` with owner and reopen-trigger per row. Archive: `.planning/milestones/v1.40-ROADMAP.md`.

</details>

<details>
<summary>v1.39 Quality Baseline, Schema Confidence, and CI Efficiency (Phases 189-193) - SHIPPED 2026-07-03</summary>

Repo-evidence quality-risk ranking followed by high-confidence fixes to the three weakest surfaces: configurable PostgreSQL `storage_schema` behavior proven end-to-end, release/docs version truth reconciled to `0.9.0` behind a drift-guard test, and measured CI/CD efficiency work behind contract guards. 15/15 requirements. Archive: `.planning/milestones/v1.39-ROADMAP.md`.

</details>

<details>
<summary>v1.38 Operator UI Page-by-Page IA & Design-System Polish (Phases 181-188) - SHIPPED 2026-06-30</summary>

Baseline guard repair, PhoenixStorybook example/dev lane, shell/Home orientation, Timeline investigation flow, Coverage readiness, detail/governance/export surface polish, accessibility/motion/docs closeout, and Phase 188 audit-gap closure. Archive: `.planning/milestones/v1.38-ROADMAP.md`.

</details>

<details>
<summary>v1.37 Operator Surface Design-System Stress Test & Component System (Phases 171-180) - SHIPPED 2026-06-20</summary>

Internal component system, `/audit/__stress`, design-system ledger, shell/navigation/theme picker, page stress coverage, microcopy/IA normalization, WCAG/APG/motion guardrails, accessibility-tree evidence, and adversarial closeout. Archive: `.planning/milestones/v1.37-ROADMAP.md`.

</details>

<details>
<summary>v1.36 Operator Surface Light Mode (Phases 166-170) - SHIPPED 2026-06-14</summary>

`theme: :dark | :light | :system` host config and pure-CSS light/system lanes. Archive: `.planning/milestones/v1.36-ROADMAP.md`.

</details>
