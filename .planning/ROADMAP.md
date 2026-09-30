# Roadmap: Threadline

## Milestones

- 🚧 **v1.44 Behavioral Depth: Properties, Twins, Telemetry** - Phases 224-230 (in progress, opened 2026-09-30)
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

## 🚧 v1.44 Behavioral Depth: Properties, Twins, Telemetry (In Progress)

**Milestone Goal:** Prove Threadline's behavioral invariants with bounded property tests, make its long-running operations observable without leaking audited data, and make the test suite faster and more honest. Close the capture and CLI correctness debt carried from v1.42. Ships as a minor release (0.12.0).

**Granularity:** coarse config, but seven phases, the ceiling for this rung. Each boundary is an ordering constraint, not a feature split. The suite has to be partitioned before the DB-backed properties add serial time to it. The pure properties prove the mutation-control discipline cheaply before the DB-backed ones. The redaction property must exist before telemetry can attach a handler to it. The guard-test cut and the net-suite check can only be judged once every test-adding phase has landed. Merging 226 with 227 would put the cheap and the expensive properties under one budget. Merging 228 into 227 would couple a new public event surface to test-only work. 229 is independent adopter-facing API and CLI work, grouped so the release has one CHANGELOG section for it.

**Evidence:** `.planning/research/SUMMARY.md` (Implications for Roadmap, Resolved Conflict) and `.planning/REQUIREMENTS.md`. Where they conflict, REQUIREMENTS.md wins (no `:invalid_config` finding, no `gen.backfill`, no query or Mix-task telemetry, `history/3` limit defaults to `nil`).

### Dependency spine

```
224 Capture + bench fixes ─→ 225 Suite baseline + partitioned CI ─→ 226 Pure properties ─→ 227 DB-backed properties ─→ 228 Telemetry ─┐
                                        └──────────────────────────→ 229 Adopter API + health (independent) ─────────────────────────────┼─→ 230 Rebalance, net-suite check, 0.12.0
```

- **SUITE-01's baseline is pinned to the milestone base** (`dd780e68`, before any v1.44 test change). Phase 224 lands first but adds tests, so its own before/after is measured against that base rather than hiding inside the baseline.
- **225 before 227.** Partitioning absorbs the DB-backed properties' serial time instead of compounding the unpartitioned suite. 225 also resizes Flake Detection, which 226's `THREADLINE_PROPERTY_SCALE` lane then reuses.
- **226 before 227.** The pure properties establish the generator modules, `max_runs` tiers and mutation-control record that 227 follows.
- **227 before 228.** TELE-03 attaches a test telemetry handler to 227's redaction property (PROP-04).
- **229 is independent** of 226-228 and can run any time after 225. It is sequenced before 230 so the release carries its CHANGELOG entries.
- **Known exception:** CAPT-02's rerun property in 224 is DB-backed and lands before partitioning. It is carried correctness debt, capped at `max_runs` ≤ 20 from the start (the DB tier PROP-08 later formalizes), and its cost is reported in 224.

### Cross-cutting invariants (hold in every phase)

- **Suite wall clock before and after (SUITE-06).** Every phase that adds, removes or re-schedules tests records local and CI suite wall clock before and after in its VERIFICATION.md, citing run IDs for CI figures. A net regression is caught mid-milestone, not at close.
- **No tautological properties.** Each property's expectation is derived independently of the code under test (set equality, a hand-written fold, an independent decoder). Each carries a mutation control: the invariant broken on purpose, the property shown red, the failing seed cited in VERIFICATION.md.
- **Honest default tests.** `mix test` still runs the full suite locally. Any tag or exclusion change updates `test/test_helper.exs` and the docs together.
- **Same-commit roster rule.** Any change to CI jobs or the required aggregate changes `ci.yml`, CONTRIBUTING's job table, `ci-required` `needs:` and the topology contract test in one commit. Job `id:`s stay immutable; `CI required` stays fail-closed.
- **No planning vocabulary in product code.** No phase or plan IDs in `lib/`, moduledocs, guides, CHANGELOG or releasable commit subjects.
- **Zero human verification.** Every success criterion names the test, alias or run ID that proves it. `mix ci.all` is green at each phase close. The maintainer handles only push, merge, `production-hex` approval and scope decisions.
- **Never `git add .planning/` wholesale.** Stage explicit file lists only, and keep home paths and usernames out of planning prose (the hygiene guard scans `.planning/`).

## Phases

- [ ] **Phase 224: Capture and Bench Fixes** - Full rollback after a `gen.triggers` rerun leaves no orphaned capture function, and the bench project compiles bare
- [ ] **Phase 225: Suite Baseline and Partitioned CI** - A cited suite-time baseline, then a partitioned CI test step at least 30% faster and async telemetry/named-process tests
- [ ] **Phase 226: Pure Property Tests and Run Budget** - Cursor paging, ChangeDiff, redaction-policy validation and export round-trips proven by bounded, mutation-controlled pure properties
- [ ] **Phase 227: DB-Backed Property Tests** - Redaction never leaks to storage, diff or export; `as_of` equals replayed history; the retention cutoff boundary holds
- [ ] **Phase 228: Telemetry** - Operators can observe export and retention runs through documented events that never carry audited data
- [ ] **Phase 229: Adopter API and Health Additions** - `history/3` takes a `:limit`; `health.coverage` gains `--strict`, `--all-schemas` and a legacy-keys warning
- [ ] **Phase 230: Rebalance, Net-Suite Check and 0.12.0** - Prose-only guard tests merged or cut, the net suite time proven not to regress, and 0.12.0 released

## Phase Details

### Phase 224: Capture and Bench Fixes

**Goal**: An adopter can roll back every generated capture migration, including per-table reruns, and be left with a clean `pg_proc`; a contributor can compile the bench project with a bare `mix compile`
**Depends on**: Nothing (first phase)
**Requirements**: CAPT-01, CAPT-02, SUITE-05
**Success Criteria** (what must be TRUE):

  1. After `mix threadline.gen.triggers` for a table, a rerun that adds a per-table function, and `mix ecto.rollback --all`, a `pg_proc` query for `threadline_capture_%` returns zero rows. The generated `down` drops functions only through `TriggerSQL.drop_function_if_unused/2`, and a test asserts the emitted SQL contains no `CASCADE`.
  2. A deterministic regression test pins the exact two-migration repro against real Postgres. It covers both a partial rollback (the rerun migration only) and a full-chain rollback, and shows no orphaned function and no function dropped while still in use. Reverting the fix turns it red (mutation control recorded).
  3. A property over random rerun sequences (1-4 runs per table, applied for real, `max_runs` ≤ 20) asserts no orphaned capture function remains in `pg_proc` after a full rollback, with its own mutation control recorded.
  4. `mix compile` in `bench/` succeeds with no `MIX_ENV` set (`preferred_envs`), an existing CI job runs that bare compile, and removing `preferred_envs` makes it fail (local mutation control).
  5. VERIFICATION.md reports suite wall clock before and after, measured against the milestone base `dd780e68`.

**Plans**: 4 plans

Plans:
- [ ] 224-01-PLAN.md — First-run `down` drops the per-table function; regression test through `Ecto.Migrator` (partial + full chain); re-pinned outputs; regenerated example fixture (wave 1)
- [ ] 224-02-PLAN.md — DB-backed rerun-sequence property (`@max_runs 20`) and recorded CAPT-02 mutation controls (wave 2)
- [ ] 224-03-PLAN.md — Bench `preferred_envs`, `mix verify.bench_compile` in `ci.all` and the `verify-compile-no-optional` job, contract + mutation control (wave 1)
- [ ] 224-04-PLAN.md — Upgrade-guide remediation + CHANGELOG, SUITE-06 wall clock vs `dd780e68`, `mix ci.all` gate (wave 3)
**Research**: Resolved in discuss-phase (224-CONTEXT D-01): the first-run migration's `down` unconditionally emits the idempotent, usage-checked drop for the table's deterministic per-table function name after its trigger drop; the rerun's `down` stays unchanged. The earlier two-sided/`covered_pairs/1` wiring is superseded (the first run is generated before any rerun exists, and a rerun-side drop never succeeds under reverse-order rollback). Plan-phase still checks partial and full-chain rollback orders against the regression and property tests. No catalog sweep and no CASCADE.

### Phase 225: Suite Baseline and Partitioned CI

**Goal**: The maintainer can cite a fresh suite-time baseline, and every PR's test step finishes at least 30% sooner, with billed runner-minutes up no more than 10% and the required gate still fail-closed
**Depends on**: Phase 224
**Requirements**: SUITE-01, SUITE-02, SUITE-03
**Success Criteria** (what must be TRUE):

  1. A baseline doc records per-module slowest times (a fresh local `mix test --slowest 50` with the DB up), sync versus async seconds, and the CI test-step duration with run IDs, all measured at the milestone base before any suite change. An automated check finds no uncited figure.
  2. The CI test step runs the suite in N parallel partitions (`MIX_TEST_PARTITION`), each with its own database. Over cited runs, the step's wall clock is at least 30% lower than the SUITE-01 figure and billed runner-minutes rise by no more than 10%.
  3. `CI required` fails when any single partition fails, proven by a contract-test mutation control. The contract test, CONTRIBUTING and the topology test change in the same commit, and the Flake Detection budget is resized in the same change.
  4. The telemetry-handler and named-process test files run `async: true` with unique handler ids and process names, and one cited Flake Detection run shows no new flake.
  5. Local `mix test` still runs the whole suite, `mix ci.all` is green, and VERIFICATION.md reports suite wall clock before and after.

**Plans**: TBD
**Research**: Needed. Open with a fresh local `mix test --slowest 50` timing run (DB up) before choosing the partition count. Research cited 209 s / 191 s serial from older records, not a re-measurement. Check `pool_size` against the per-partition Postgres `max_connections` too (`too_many_connections` is a known local hazard).

### Phase 226: Pure Property Tests and Run Budget

**Goal**: A reviewer can trust cursor paging, ChangeDiff, redaction-policy validation and export encoding across generated inputs, and the property suite's run time stays bounded and tunable
**Depends on**: Phase 225
**Requirements**: PROP-01, PROP-02, PROP-03, PROP-05, PROP-08
**Success Criteria** (what must be TRUE):

  1. For generated, tie-heavy ordered lists (deliberate duplicate timestamps, not wall-clock timing), concatenating every page of the timeline cursor and of the actor-history cursor equals the full list, with no duplicates and no gaps. The expectation is checked by set equality and an independent ordering, not the cursor's own sort.
  2. ChangeDiff matches an independently derived expectation across the INSERT/UPDATE/DELETE × before_values matrix. Redaction-policy validation accepts every generated valid policy and rejects every generated invalid one. Export CSV and JSON round-trip generated change maps without loss, checked by an independent decoder.
  3. Each pure property runs `async: true` with an explicit `max_runs` of 150-200. Generators live in `test/support/` modules named for the bias they encode. `THREADLINE_PROPERTY_SCALE` multiplies runs on the weekly Flake Detection lane, and a test pins that wiring.
  4. VERIFICATION.md records a mutation control for each of the four properties: the invariant broken on purpose, the property red, and the failing seed.
  5. VERIFICATION.md reports suite wall clock before and after.

**Plans**: TBD
**Research**: Not needed. Property shapes are specified per target in `research/STACK.md` §1 and mirror the two existing property files.

### Phase 227: DB-Backed Property Tests

**Goal**: A security reviewer can rely on redacted columns never reaching storage, diffs or exports, and an operator can rely on `as_of` reconstruction and retention cutoffs being exact
**Depends on**: Phase 226
**Requirements**: PROP-04, PROP-06, PROP-07
**Success Criteria** (what must be TRUE):

  1. Over generated captured values on a fixed table shape, a redacted column's plaintext never appears in the stored audit change, its ChangeDiff output, or its CSV and JSON export.
  2. For generated row histories, `as_of` at each point equals the state reconstructed by a hand-written, in-order replay of that row's history.
  3. With generated timestamps clustered at the cutoff, `Retention.purge(dry_run: true)` selects exactly the rows strictly older than the cutoff. Every row at or after it survives with its content unchanged, not merely its count.
  4. Each property uses `Threadline.DataCase` (`async: false`, no Sandbox), cleans up by a per-iteration unique key, runs with `max_runs` ≤ 20, and passes under partitioned CI and a scaled Flake Detection run. VERIFICATION.md records a mutation control and failing seed for each.
  5. VERIFICATION.md reports suite wall clock before and after, against both SUITE-01 and the partitioned figure from phase 225.

**Plans**: TBD
**Research**: Not needed for the harness (`research/STACK.md` §1.2/§1.4/§1.5, PITFALLS Pitfall 1). Plan-phase should still review the retention survivor content-equality check carefully.

### Phase 228: Telemetry

**Goal**: An operator can observe export and retention runs through documented `[:threadline, ...]` events, and a compliance reviewer can confirm those events never carry audited data
**Depends on**: Phase 227
**Requirements**: TELE-01, TELE-02, TELE-03, TELE-04
**Success Criteria** (what must be TRUE):

  1. An attached handler receives `[:threadline, :export, :completed]` or `[:threadline, :export, :failed]`, with a row count, a duration and a format, after an export finishes. Tests cover both outcome branches.
  2. An attached handler receives the `[:threadline, :retention, :purge, :start | :stop | :exception]` span and one `[:threadline, :retention, :batch_purged]` event per batch, carrying the rows deleted. A test forces the exception path.
  3. An allowlist test pins the measurement and metadata keys of every Threadline event, existing and new, and adding an unlisted key turns it red. A handler attached during the PROP-04 redaction property never observes plaintext. A raising handler does not break export or purge.
  4. The `Threadline.Telemetry` moduledoc event table and the new `guides/telemetry.md` list every event. The guide includes the host-repo `[:my_app, :repo, :query]` recipe. A test derives the documented list from the emitted events rather than from a hand-typed literal.
  5. No query or Mix-task event is added. VERIFICATION.md reports suite wall clock before and after.

**Plans**: TBD
**Research**: Not needed. Event shapes and mitigations are in `research/FEATURES.md` §A and PITFALLS Pitfalls 5-10: emit after commit, execute events on both branches, and a span only around retention purge.

### Phase 229: Adopter API and Health Additions

**Goal**: A developer can cap `history/3` results without a breaking change, and a CI pipeline can gate on capture-coverage health across every schema
**Depends on**: Phase 225 (independent of 226-228)
**Requirements**: QRY-01, QRY-02, HLTH-01, HLTH-02, HLTH-03, HLTH-04
**Success Criteria** (what must be TRUE):

  1. `Threadline.history/3` with `limit: n` returns at most `n` changes, newest first, with the `captured_at desc, id desc` tiebreak. `0`, negative and non-integer values raise `ArgumentError`, and the docs point to `row_history_page/4` for paging.
  2. A test proves that `history/3` without `:limit` returns the same list as before. The CHANGELOG entry states the option is additive and the default is unchanged.
  3. `mix threadline.health.coverage --strict` exits nonzero on any `:error`-severity finding and composes with `--json`. A severity × strict/non-strict matrix test proves the non-strict exit codes are unchanged.
  4. `--all-schemas` produces a schema-keyed report in table and JSON output and is rejected alongside `--schema=NAME`. A pre-0.11 fixture produces an `:unresolved_legacy_keys` warning with per-table counts and a link to `guides/upgrading-to-0.11.md`, and `--strict` does not fail on it.
  5. The docs state that malformed `:trigger_capture` config raises rather than producing a finding. VERIFICATION.md reports suite wall clock before and after.

**Plans**: TBD
**Research**: Not needed (`research/FEATURES.md` §B-§D). Plan-phase should confirm first that no existing test pins per-severity exit codes, so the matrix is built as the baseline rather than assumed.

### Phase 230: Rebalance, Net-Suite Check and 0.12.0

**Goal**: The maintainer ships a milestone whose suite is more honest and no slower than where it started, released as 0.12.0 on hex.pm
**Depends on**: Phases 224-229
**Requirements**: SUITE-04, SUITE-06, REL-01
**Success Criteria** (what must be TRUE):

  1. The keep/cut rubric is recorded and applied, including the four guard-test files not yet audited. Tests that compare prose to a hand-typed literal are merged or cut. Tests that derive from a live source, or that carry a v1.43 mutation control (cross-checked against `.planning/milestones/v1.43-MILESTONE-AUDIT.md`), are kept, and no CI-topology or CONTRIBUTING contract test is cut.
  2. A diff of `ci-required` shows the required-check count unchanged. The rebalance reports suite wall clock before and after.
  3. A milestone suite-time table cites every phase's before/after figure and shows the net suite time does not regress against SUITE-01, locally and in CI with run IDs.
  4. The milestone lands on main as one squash with a clean conventional `feat:` title. release-please ships 0.12.0, hex.pm serves it, and the `latest` lane pins are re-checked against builds.hex.pm and Docker Hub, with the result cited.
  5. `mix ci.all` and `bin/verify-repo-hygiene` are green at close, and no phase or plan ID appears in `lib/`, guides or the 0.12.0 CHANGELOG.

**Plans**: TBD
**Research**: Apply the rubric in `research/ARCHITECTURE.md` B.1 to `operator_surface/coverage_doc_contract_test.exs`, `operator_surface/policy_show_doc_contract_test.exs`, `storage_schema_migration_contract_test.exs` and `storage_schema_prefix_contract_test.exs` before building the cut list. Landing needs a maintainer grant naming the branch, push, PR, merge and `production-hex` approval.

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 224. Capture and Bench Fixes | 0/TBD | Not started | - |
| 225. Suite Baseline and Partitioned CI | 0/TBD | Not started | - |
| 226. Pure Property Tests and Run Budget | 0/TBD | Not started | - |
| 227. DB-Backed Property Tests | 0/TBD | Not started | - |
| 228. Telemetry | 0/TBD | Not started | - |
| 229. Adopter API and Health Additions | 0/TBD | Not started | - |
| 230. Rebalance, Net-Suite Check and 0.12.0 | 0/TBD | Not started | - |

## Prior Milestones

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
