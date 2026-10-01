# Requirements: Threadline v1.44 Behavioral Depth: Properties, Twins, Telemetry

**Defined:** 2026-09-30
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why, without the developer having to remember to opt in.
**Research:** `.planning/research/SUMMARY.md` (with STACK, FEATURES, ARCHITECTURE and PITFALLS). The maintainer asked for research-backed recommendations to be followed without further scoping questions (2026-09-30).

## v1.44 Requirements

### Capture correctness (carried from v1.42)

- [x] **CAPT-01**: An adopter who runs `mix threadline.gen.triggers` for a table and then reruns it (adding a per-table function) can roll back with `mix ecto.rollback --all` and be left with no orphaned `threadline_capture_*` function in `pg_proc`. The down path uses the existing idempotent, usage-checked `TriggerSQL.drop_function_if_unused/2` and emits no CASCADE drop.
- [x] **CAPT-02**: A deterministic regression test pins the exact two-migration repro. A property over random rerun sequences (1–4 runs per table, applied for real) asserts that no orphaned capture function remains in `pg_proc` after a full rollback.

### Property tests

- [ ] **PROP-01**: Cursor paging is proven by a pure property. For generated, tie-heavy ordered lists, concatenating every page equals the full list, with no duplicates and no gaps, for both the timeline and actor-history cursors.
- [ ] **PROP-02**: A pure property proves ChangeDiff's documented INSERT/UPDATE/DELETE × before_values matrix against an independently derived expectation.
- [ ] **PROP-03**: A pure property proves that redaction-policy validation accepts exactly the valid policies and rejects the rest.
- [ ] **PROP-04**: A DB-backed property varies captured values on a fixed table shape and proves that a redacted column's plaintext never appears in the stored audit change, its diff or its export output.
- [ ] **PROP-05**: A pure property proves that export (CSV and JSON) round-trips generated change maps without loss.
- [ ] **PROP-06**: A DB-backed property proves that `as_of` equals the state reconstructed by replaying the row's history in order.
- [ ] **PROP-07**: A DB-backed property proves the retention cutoff boundary with `dry_run: true`: rows strictly older than the cutoff are selected and every row at or after it survives.
- [ ] **PROP-08**: Property run time is bounded and tunable.
  - Pure properties run with an explicit `max_runs` of about 150–200.
  - DB-backed properties run with `max_runs` of at most 20.
  - A `THREADLINE_PROPERTY_SCALE` env var multiplies runs on the weekly Flake Detection lane.
  - Generators live in `test/support/` modules named for the bias they encode.
  - Every property records a mutation control (the invariant broken on purpose, the property shown red) in its phase verification.

### Telemetry

- [ ] **TELE-01**: An operator can attach to `[:threadline, :export, :completed]` and `[:threadline, :export, :failed]`, which carry a row count, a duration and a format. Both are emitted after the export finishes, on both outcome branches.
- [ ] **TELE-02**: An operator can observe retention purges through a `:telemetry.span/3` on `[:threadline, :retention, :purge, :start | :stop | :exception]`, plus a `[:threadline, :retention, :batch_purged]` event per batch that carries the rows deleted.
- [ ] **TELE-03**: No Threadline telemetry event carries row values, actor identifiers, correlation ids or free-text reasons.
  - An allowlist test pins every event's measurement and metadata keys.
  - A test handler attached during the redaction property never observes plaintext.
  - A raising handler does not break the instrumented operation.
- [ ] **TELE-04**: An adopter can find every event in one place: an event table in the `Threadline.Telemetry` moduledoc and a new `guides/telemetry.md`. The guide includes a recipe for observing Threadline's queries through the host repo's own `[:my_app, :repo, :query]` event instead of a duplicate query event.

### Query API

- [ ] **QRY-01**: A developer can pass `limit: n` to `Threadline.history/3` to get at most `n` changes, newest first, with the existing `captured_at desc, id desc` tiebreak. The default is unbounded (`nil`). Zero, negative or non-integer values raise `ArgumentError`, and the docs point to `row_history_page/4` for paging.
- [ ] **QRY-02**: A test proves that calling `history/3` without `:limit` returns the same list as before. The CHANGELOG entry states the option is additive and that the default is unchanged.

### Health and CLI (carried from v1.42)

- [ ] **HLTH-01**: A CI pipeline can run `mix threadline.health.coverage --strict` and get a nonzero exit on any `:error`-severity finding. The command composes with `--json`. Without `--strict`, the exit codes are unchanged, and a severity × strict/non-strict test matrix proves both.
- [ ] **HLTH-02**: An adopter with several Postgres schemas can run `mix threadline.health.coverage --all-schemas` and get a report keyed by schema, in both table and JSON output. The option is mutually exclusive with `--schema=NAME`.
- [ ] **HLTH-03**: An adopter upgrading from before 0.11 sees an `:unresolved_legacy_keys` warning finding. It counts, per table, the rows whose `table_pk` was never resolved, and links to the backfill steps in `guides/upgrading-to-0.11.md`. It does not fail `--strict`.
- [ ] **HLTH-04**: The docs state that malformed `:trigger_capture` config fails fast (raises) rather than producing a finding.

### Test suite economy

- [x] **SUITE-01**: A fresh suite timing baseline is recorded before any suite change: per-module slowest times, sync vs async seconds, and the CI test-step duration with run IDs.
- [x] **SUITE-02**: The CI test step runs the suite in parallel partitions, each with its own database, and the step's wall clock drops by at least 30% against SUITE-01.
  - Billed runner-minutes do not rise by more than 10%.
  - The Flake Detection budget is resized in the same change.
  - The required aggregate stays fail-closed, and its contract test, CONTRIBUTING and the topology test change together.
- [x] **SUITE-03**: The three operator-surface auth telemetry test files (`auth_test.exs`, `export_auth_plug_test.exs`, `theme_auth_plug_test.exs`) run `async: true`, isolated by the emitting process, with no new flake over a Flake Detection run. The seven other telemetry or named-process files stay serial for database-write or app-env reasons (narrowed by 225-CONTEXT D-15).
- [ ] **SUITE-04**: Guard tests that only compare prose to a hand-typed literal are merged or cut under the recorded keep/cut rubric.
  - Tests that derive from a live source, or that carry a v1.43 mutation control, are kept.
  - The required-check count is unchanged, and suite wall clock is reported before and after.
- [x] **SUITE-05**: The bench project compiles with a bare `mix compile` (via `preferred_envs`), and an existing CI lane proves it.
- [x] **SUITE-06**: Each phase that adds or removes tests reports the suite wall clock before and after. Across the milestone, the net suite time does not regress against SUITE-01.

### Release

- [ ] **REL-01**: The milestone lands on main as a squash with a clean conventional `feat:` title and ships as a minor release (0.12.0) through release-please. The `latest` lane's pins are re-checked against builds.hex.pm and Docker Hub at landing.

## Future Requirements (deferred)

- **A bounded default limit for `history/3`**: a one-way semver decision. It belongs to the v1.45 history/row_history consolidation.
- **Async for pure-read `DataCase` tests**: needs a per-file audit and is not a mechanical sweep. It is a candidate after the partitioning data is in.
- **A stateful (PropEr) model of the capture → history pipeline**: real value, but it needs a new dependency and a model. Revisit only if the properties above expose pipeline bugs.
- **Growing the adopter twin with more table shapes**: only when a concrete failure mode needs it (guide §8).

## Out of Scope

| Feature | Reason |
|---------|--------|
| `[:threadline, :query, ...]` telemetry | It duplicates the host repo's `[:repo, :query]` event. The guide recipe covers it (TELE-04). |
| Telemetry emitted from Mix task bodies | Tasks run outside the host's booted app, where no handlers are attached. This follows Ecto and Oban precedent. |
| `mix threadline.gen.backfill` | A durable anti-feature. The tested, marker-delimited SQL in `guides/upgrading-to-0.11.md` is right-sized, as with Carbonite, PaperTrail and Logidze. HLTH-03 adds detection instead. |
| An `:invalid_config` health finding | The existing fail-fast raise is stricter than a soft finding would be. HLTH-04 documents it. |
| Ecto SQL Sandbox, schema-per-test, or tuning only `:max_cases` | Triggers need committed transactions. Schema-per-test adds migration cost, and `:max_cases` does nothing for `async: false` modules. |
| Cutting CI-topology or CONTRIBUTING contract tests hardened in v1.43 | It would reopen gaps that phases 220 and 221 closed. |
| Operator UI design | Parked until 1.0.0. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| CAPT-01 | Phase 224 | Complete |
| CAPT-02 | Phase 224 | Complete |
| PROP-01 | Phase 226 | Pending |
| PROP-02 | Phase 226 | Pending |
| PROP-03 | Phase 226 | Pending |
| PROP-04 | Phase 227 | Pending |
| PROP-05 | Phase 226 | Pending |
| PROP-06 | Phase 227 | Pending |
| PROP-07 | Phase 227 | Pending |
| PROP-08 | Phase 226 | Pending |
| TELE-01 | Phase 228 | Pending |
| TELE-02 | Phase 228 | Pending |
| TELE-03 | Phase 228 | Pending |
| TELE-04 | Phase 228 | Pending |
| QRY-01 | Phase 229 | Pending |
| QRY-02 | Phase 229 | Pending |
| HLTH-01 | Phase 229 | Pending |
| HLTH-02 | Phase 229 | Pending |
| HLTH-03 | Phase 229 | Pending |
| HLTH-04 | Phase 229 | Pending |
| SUITE-01 | Phase 225 | Complete |
| SUITE-02 | Phase 225 | Complete |
| SUITE-03 | Phase 225 | Complete |
| SUITE-04 | Phase 230 | Pending |
| SUITE-05 | Phase 224 | Complete |
| SUITE-06 | Phase 230 | Complete |
| REL-01 | Phase 230 | Pending |

**Coverage:**
- v1.44 requirements: 27 total
- Mapped to phases: 27
- Unmapped: 0
- SUITE-06 is cross-cutting: it maps to Phase 230 for the milestone net check, and every phase that adds or removes tests reports suite wall clock before and after

---
*Requirements defined: 2026-09-30*
*Last updated: 2026-09-30 after roadmap creation (phases 224-230)*
