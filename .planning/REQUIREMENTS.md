# Requirements: Threadline v1.45 1.0 API Contract

**Defined:** 2026-10-02
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why, without the developer having to remember to opt in.
**Research:** `.planning/research/SUMMARY.md`, built on STACK, FEATURES, ARCHITECTURE, PITFALLS and CONTRACT. It reconciles five cross-file conflicts.

**Maintainer decisions (2026-10-02, the one-way calls; all four research recommendations accepted):**

1. `row_history` defaults to a 200-row cap. The return stays a bare list. The cursor path returning `Threadline.Page` is documented as the only read that proves completeness. `limit: :infinity` opts out, and a truncation telemetry event fires when the cap is hit.
2. The PostgreSQL floor rises to 15 at the 1.0.0 cut, as a breaking change.
3. The `AuditTransaction` ↔ `AuditAction` Ecto association is decoupled (Option C). The DB foreign key and the `.action` key shape that callers see are unchanged.
4. `Threadline` becomes the single public read facade. `Threadline.Query` and `Threadline.Investigation` are hidden. `Threadline.Query.timeline_query/1` remains the one Ecto-composition escape hatch.

**Settled by research without escalation:**

- **Deprecation policy:** "Deprecated in 1.0.0. Kept as a functioning, fully-specced delegate for the rest of the 1.x line. Removed no earlier than 2.0.0, which is not currently planned."
- **Return shapes:** collection reads return bare values. Single-subject lookups return `{:ok, _}` or `{:error, :not_found}` and have `!` siblings. Bad options raise `ArgumentError`. No NimbleOptions.
- **Floors and support:** Elixir stays `~> 1.15` on OTP 26. 0.12.x gets a 6-month security and correctness backport window.

## v1.45 Requirements

### API: one public surface

- [x] **API-01**: An adopter calls one function, `Threadline.row_history/3`, to read a row's changes, with filters passed as keyword opts.
  - Without options it returns at most 200 changes, newest first, as a bare list.
  - `limit: n` and `limit: :infinity` override the cap.
  - `cursor:` with `page_size:` returns a `%Threadline.Page{}`. Walking it until `has_more: false` yields exactly the full history.
  - Passing `:limit` together with `:cursor` raises `ArgumentError`.
  - Hitting the cap emits `[:threadline, :row_history, :truncated]`, which carries no row values or actor ids and is added to the telemetry allowlist.
  - Export and `as_of` stay unbounded, proven by a test.
  - v1.44 properties that read history are updated explicitly to pass `limit: :infinity` or walk the cursor.
- [x] **API-02**: An adopter can tell `actor_history/2` (transactions) from `actor_window/3` (cross-table changes). Each `@doc` states its return type first and cross-links the other function, and a doc-contract test pins both.
- [x] **API-03**: Every paged read returns the same `%Threadline.Page{entries, cursor, has_more}` struct, which replaces `TimelinePage` and `ActorHistoryPage`. `timeline/2` and `timeline_page/2` remain the only deliberate pair of names; no third naming pattern exists on the facade.
- [x] **API-04**: The adopter's docs contain one read API.
  - `Threadline.Query` and `Threadline.Investigation` are `@moduledoc false`.
  - `Threadline.Query.timeline_query/1` is the one documented escape hatch, linked from the `Threadline` moduledoc.
  - The three guides that call the hidden modules (`audit-indexing`, `how-threadline-works`, `code-walkthrough`) call `Threadline.*` instead.
  - `public_surface_contract_test.exs` pins the hidden set.
- [x] **API-05**: Internal helpers no longer appear in the adopter's docs. This covers the `Threadline.Telemetry` `emit_*` functions, the raw `*_query` builders other than `timeline_query/1`, and any module without a moduledoc, such as `Threadline.Export.CSV`. Before hiding a name, guides, the README and the example app are grepped for it, and every hit is rewritten in the same change.
- [x] **API-06**: Single-subject lookups behave the same way everywhere. `audit_transaction/2` and `transaction_context/2` return `{:ok, _}` or `{:error, :not_found}`, matching `incident_bundle/2`. New siblings `audit_transaction!/2` and `transaction_context!/2` raise. Not-found and present cases are tested for all four.
- [x] **API-07**: The capture layer no longer depends on the semantics layer at compile time.
  - `AuditTransaction` drops `belongs_to :action` and `AuditAction` drops `has_many :transactions`.
  - An exploration-layer helper hydrates `transaction.action`, so every existing call-site assertion on `.action` passes unchanged.
  - The `action_id` column and its foreign key are untouched.
  - A test asserts that neither schema declares an association to the other.
- [x] **API-08**: An adopter on a retired name gets a working call and one compiler warning naming the replacement.
  - Each retired entry point (`history/3`, `row_history/4`, `row_history_page/4`, and the filters-as-positional-argument shapes, on every module that exposed them) is a pure one-line `@deprecated` delegate.
  - Each has a parity test against its replacement and a spec that matches the replacement's (not `term()`).
  - `@doc since: "1.0.0"` marks the replacements.
  - `mix compile --warnings-as-errors` is clean for `lib/`, `test/` and the example app, so nothing internal calls a deprecated name.

### SPEC: typespecs and docs

- [x] **SPEC-01**: Every public function in every documented module under `lib/` has a `@doc` and a `@spec`. Baseline is 129 of 169 missing (remeasured at the 233 close: 54 of 92 visible entries across 52 documented modules; the 129/169 figure predates phases 231–233). A new `async: true` test using `Code.fetch_docs/1` and `Code.Typespec.fetch_specs/1` fails on any gap, so coverage cannot regress.
- [x] **SPEC-02**: The specs give adopters real information.
  - No public spec uses bare `term()` or `any()` where a real shape exists.
  - Option arguments use named `@type` option lists rather than bare `keyword()`.
  - Reviewed in phase verification by agent review against a written rubric.
  - Strict Dialyzer stays green with zero ignores.
- [x] **SPEC-03**: The `Threadline` facade page in ExDoc groups functions by job using `@doc group:`: Capture & Transactions, Querying & Timelines, Actions & Context, Operations. A test asserts that every facade function has a group.

### CONTRACT: the 1.x stability promise, enforced by tests

- [x] **CONTRACT-01**: An adopter can read `guides/stability.md` to learn what 1.x promises.
  - **Elixir API tier:** Hex semver, with the deprecation policy above.
  - **Database Contract tier:** additive-only for tables, columns, indexes, the trigger-function naming scheme and the GUC name.
  - **Named exception class:** only security- or correctness-critical fixes may require trigger regeneration in a 1.x minor.
  - **Explicitly not API:** operator-surface HTML, CSS and LiveView internals. The router macro, its options and the documented mount routes are API.
  - **0.12.x:** the 6-month backport window.
  - A doc-contract test pins each of these statements.
- [x] **CONTRACT-02**: A schema-snapshot test pins the column names, types and nullability of `audit_transactions`, `audit_changes` and `audit_actions`, plus the shipped indexes. Removing or renaming any of them fails CI.
- [x] **CONTRACT-03**: A test pins the GUC name `threadline.actor_ref` and the trigger-function naming scheme as literals. A rename anywhere in `lib/` fails CI.
- [ ] **CONTRACT-04**: Additive-only allowlist tests, following the pattern of `telemetry_registry_contract_test.exs`, pin:
  - the CSV and JSON export headers, with and without action metadata
  - the `Health.Finding` code set
  - each mix task's accepted flags
  - the `threadline_operator_surface/2` option keys and documented mount routes
- [ ] **CONTRACT-05**: Each of `AuditChange`, `AuditTransaction` and `AuditAction` documents its stable field subset in its moduledoc. The `data_after`, `changed_fields` and `changed_from` jsonb columns carry an additive key/shape promise, not a byte-stable serialization promise. A test pins the stable field lists against the schema.

### DOCS: adopter guides

- [x] **DOCS-01**: A supported-table-shapes guide lets an adopter check, before installing, whether their tables are supported.
  - Covers composite and non-`id` keys, the `primary_key:` override, cross-schema tables, long identifiers and `char(n)`.
  - States explicitly what happens with partitioned tables, unlogged tables and views.
  - A doc-contract test checks the option and table names it cites against the real code.
- [x] **DOCS-02**: A redaction threat model tells a security reviewer exactly what redaction guarantees and what it does not.
  - Every guarantee names the property test or health check that proves it.
  - Generated trigger migrations fail before installing a trigger when any `mask:` or `exclude:` column name is absent from the selected table; tests cover both options and preserve a valid-column control. This closes the fail-open typo path for migrations that include the validation.
  - The guide states that already-installed triggers and previously captured rows are not changed by this validation; adopters must regenerate and run the host-owned trigger migration for the affected table.
  - It states where plaintext can still exist: WAL and logical decoding, replication slots, backups, superuser access, rows captured before a rule changed, and host logs.
  - A doc-contract test rejects unscoped absolutes ("all", "never", "guarantees", "prevents" with no qualifier).
- [ ] **DOCS-03**: `guides/upgrading-to-1.0.md` takes a 0.11 or 0.12 adopter to 1.0, with one numbered step per breaking change in this milestone:
  - the facade collapse
  - the history default
  - the `Page` struct
  - lookup return shapes
  - the association
  - the PG floor
  - deprecations
  It follows the `upgrading-to-0.11.md` template and voice and says whether trigger regeneration is required. A doc-contract test cross-checks its steps against the CHANGELOG breaking-changes entries.

### FLOOR: support floor

- [ ] **FLOOR-01**: PostgreSQL 15 is the supported minimum.
  - The CI `min` lane runs on PG 15.
  - The CHANGELOG records the change under breaking changes.
  - The trigger SQL uses no feature newer than the floor, proven by the `min` lane passing.
- [ ] **FLOOR-02**: An adopter finds one support-policy table, the Elixir/OTP/PG floor plus the CI lanes, in `guides/upgrade-path.md`. A doc-contract test fails if it disagrees with `mix.exs` or the CI `min` lane values.

### CI: carried housekeeping

- [ ] **CI-01**: Run `bin/ci-test-partitions --write-weights` after this milestone's test churn. A check proves that no test file is missing from `test/partition_weights.txt`. The v1.44 debt is 10 unweighted property files.

### REL: declare 1.0.0

- [ ] **REL-01**: release-please proposes exactly 1.0.0.
  - `bump-minor-pre-major` is flipped off in `release-please-config.json` in the landing change.
  - A `Release-As: 1.0.0` footer goes on the squash commit.
  - `verify.bump_rehearsal`, or an equivalent dry run, shows 1.0.0 and not 0.13.0 before merge.
- [ ] **REL-02**: The 1.0.0 CHANGELOG lists every breaking change and deprecation in the milestone. It is cross-checked against `git log --grep="BREAKING CHANGE"` for the milestone range, and the generated release notes are not trusted to carry the footers.
- [ ] **REL-03**: The milestone lands on main as one squash with a conventional `feat!:` title and ships **1.0.0** to hex.pm through release-please. The pins on the `latest` lane are re-checked at landing. Push, merge and the production-hex publish each need an explicit maintainer grant.

## Future Requirements (deferred)

- **Opaque result structs replacing raw Ecto schemas**: a larger, separately one-way redesign. For 1.0, documenting the stable field subset (CONTRACT-05) is enough.
- **Stateful (PropEr) model of capture → history**: carried from v1.44. A post-1.0 quality candidate.
- **More table shapes in the adopter twin**: only when a concrete failure mode needs it.
- **Async for pure-read `DataCase` tests**: needs a per-file audit. The only new async test here is SPEC-01's.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Operator UI design and markup changes | Parked until after 1.0.0. Only call sites forced by API-04 or API-07 are touched. |
| NimbleOptions | Options are flat and per-function, and the hand-rolled validators give more specific errors. It would add a dependency for no benefit. |
| A hand-maintained API-reference guide | It would duplicate ExDoc and drift, and no doc-contract test could catch it. |
| Raising the Elixir floor | Oban and LiveView keep 1.15/OTP 26, and raising it would strand adopters for no new capability. |
| Removing deprecated functions in 1.x | That breaks semver. Removal waits for 2.0 at the earliest. |
| Renaming `actor_history` / `actor_window` | The names reflect a real distinction (transactions vs changes). Docs fix the ambiguity. |
| Rewriting trigger SQL or capture internals | They are stable and proven, and the 1.x DB contract freezes their names. |
| `gen.backfill`, an `:invalid_config` finding, query telemetry, telemetry from mix tasks | Rejected in v1.44 research. Nothing here reopens them. |
| GDPR erasure, per-table retention, partitioning/RLS, multiple repos, external pilot, compliance packs | Long horizon, gated on adopter demand. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| API-01 | Phase 232 | Complete |
| API-02 | Phase 232 | Complete |
| API-03 | Phase 232 | Complete |
| API-04 | Phase 231 | Complete |
| API-05 | Phase 232 | Complete |
| API-06 | Phase 233 | Complete |
| API-07 | Phase 231 | Complete |
| API-08 | Phase 232 | Complete |
| SPEC-01 | Phase 234 | Complete |
| SPEC-02 | Phase 234 | Complete |
| SPEC-03 | Phase 234 | Complete |
| CONTRACT-01 | Phase 235 | Complete |
| CONTRACT-02 | Phase 235 | Complete |
| CONTRACT-03 | Phase 235 | Complete |
| CONTRACT-04 | Phase 235 | Pending |
| CONTRACT-05 | Phase 235 | Pending |
| DOCS-01 | Phase 235 | Complete |
| DOCS-02 | Phase 235 | Complete |
| DOCS-03 | Phase 237 | Pending |
| FLOOR-01 | Phase 236 | Pending |
| FLOOR-02 | Phase 236 | Pending |
| CI-01 | Phase 236 | Pending |
| REL-01 | Phase 237 | Pending |
| REL-02 | Phase 237 | Pending |
| REL-03 | Phase 237 | Pending |

**Coverage:**

- v1.45 requirements: 25 total
- Mapped to phases: 25
- Unmapped: 0
- Per phase: 231 (2), 232 (5), 233 (1), 234 (3), 235 (7), 236 (3), 237 (4)

---
*Requirements defined: 2026-10-02*
*Last updated: 2026-10-03 after roadmap creation (phases 231-237, 25/25 mapped)*
