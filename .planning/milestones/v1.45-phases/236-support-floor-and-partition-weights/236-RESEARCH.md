# Phase 236: Support Floor and Partition Weights - Research

**Researched:** 2026-10-07
**Domain:** PostgreSQL compatibility floor, CI topology contracts, measured ExUnit partition weights
**Confidence:** HIGH for repository state and implementation seams; MEDIUM for local environment coverage

## Summary

This phase has two independent proof jobs. The support floor is only honest if the declared package metadata, adopter guide, CHANGELOG, CI minimum lane, and a passing full suite all agree. The current `mix.exs` comment still declares PostgreSQL 14 and CI `verify-test`'s `min` matrix row still sets `pg: "14"`; `guides/upgrade-path.md` has no single toolchain support table today. [VERIFIED: `mix.exs:39-46`; quote: “PostgreSQL 14 min / 16 current” and `elixir: "~> 1.15"`. VERIFIED: `.github/workflows/ci.yml:600-616`; quote: `lane: min`, `elixir: "1.15.8"`, `otp: "26.2.5.21"`, `pg: "14"`. VERIFIED: `guides/upgrade-path.md:50-66`]

The weight refresh is also measurable: the partition runner currently finds 264 `*_test.exs` files while the committed `test/partition_weights.txt` has 234 entries, leaving 30 files unweighted. The runner intentionally assigns missing entries the median weight and still runs them, so its exactly-once guard cannot prove the separate CI-01 requirement that every test file has a measured weight. [VERIFIED: `bin/ci-test-partitions:22-30,350-367`; quote: “A file with no weight gets the median weight” and `verify_assignment` checks assignment coverage. VERIFIED: current filesystem inventory and `test/partition_weights.txt:1-6`; observed counts: 264 files / 234 entries / 30 missing.]

**Primary recommendation:** Update the existing `verify-test` minimum lane to PostgreSQL 15 and pin it in `Threadline.CiTopologyContractTest`; add one support-policy table to `guides/upgrade-path.md` and a doc contract deriving the Elixir floor from `mix.exs` and the CI lane values from `ci.yml`; record the floor increase under Unreleased breaking changes; add a permanent weights-coverage check with a mutation control; regenerate weights only after the phase’s test churn; then prove the full suite and `mix ci.all` against PostgreSQL 15.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FLOOR-01 | “PostgreSQL 15 is the supported minimum.” [VERIFIED: `.planning/REQUIREMENTS.md:102-107`] | Change the CI `min` database image and topology contract together; record the break in Unreleased; require a passing complete suite on the minimum lane to substantiate trigger SQL compatibility. |
| FLOOR-02 | One `guides/upgrade-path.md` support-policy table shows the Elixir/OTP/PG floor and CI lanes, and a doc test rejects drift from `mix.exs` or the CI `min` lane. [VERIFIED: `.planning/REQUIREMENTS.md:108`] | Keep one table as the support source for adopters. Distinguish the supported minimum row from current/latest tested-on rows; have the test compare literal source values to the table. |
| CI-01 | “A check proves that no test file is missing from `test/partition_weights.txt`.” [VERIFIED: `.planning/REQUIREMENTS.md:112`] | Add a missing-weight check and a red mutation control. Run `bin/ci-test-partitions --write-weights` after all phase test additions so generated measurements cover the final inventory. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PostgreSQL minimum compatibility proof | CI / Build | Database / Storage | The `verify-test` lane provisions PostgreSQL and executes the full test suite; migration and trigger behavior is the database proof. |
| Support policy and drift contract | API / Backend | CI / Build | Elixir package metadata is declared by Mix; CI owns the tested lane evidence; the guide brings those claims together for adopters. |
| Test timing weights and completeness check | CI / Build | — | The script measures and assigns test files; ExUnit remains the test runner. |

## Standard Stack

### Core

| Facility | Version / value | Purpose | Why Standard |
|----------|-----------------|---------|--------------|
| Mix / Elixir | Package metadata quote: `elixir: "~> 1.15"`; CI floor quote: `elixir: "1.15.8"` | Declared runtime support and ExUnit command entrypoints | Already the project’s metadata and named verification interface. [VERIFIED: `mix.exs:39-46`; `.github/workflows/ci.yml:603-607`] |
| Erlang/OTP | CI minimum quote: `otp: "26.2.5.21"` | Toolchain paired with the minimum Elixir lane | Preserve the established min lane while changing only the PostgreSQL version. [VERIFIED: `.github/workflows/ci.yml:603-607`] |
| PostgreSQL | Target quote from the requirement: “PostgreSQL 15 is the supported minimum.” | CI database image and local floor-level full-suite run | The product’s capture and migration behavior is PostgreSQL-specific; the requirement makes the tested minimum explicit. [VERIFIED: `.planning/REQUIREMENTS.md:104-107`] |
| Existing scripts and ExUnit | `bin/ci-test-partitions`, `test/threadline/ci_topology_contract_test.exs` | Refresh timings; enforce CI matrix and weights contracts | Reuse established project seams and named `mix verify.*` entrypoints. [VERIFIED: `mix.exs:131-150,233-258`; `bin/ci-test-partitions:1-30`] |

### Supporting

| Facility | Purpose | When to Use |
|----------|---------|-------------|
| `Threadline.CiTopologyContractTest` | Existing workflow/topology assertions and source mutation controls | Extend or add a focused sibling test for the min database value and weight inventory. [VERIFIED: `test/threadline/ci_topology_contract_test.exs:1-16,269-334,336-451`] |
| `mix test --slowest-modules 1000` via `bin/ci-test-partitions --write-weights` | One full, instrumented local run to write per-file milliseconds | Run after all test-file churn, with the supported timing toolchain and a reachable test database. The script documents Elixir ≥1.17 and a local test DB requirement. [VERIFIED: `bin/ci-test-partitions:58-64,451-528`] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit support table contract | Derive table rows from existing prose at test time | Prose parsing is fragile and can preserve a misleading table. Prefer a small, explicit test that compares the named table values to Mix and workflow source. |
| Check every test file has a weight | Rely on runtime exactly-once assignment | Exactly-once proves no test is skipped or duplicated, but deliberately treats a missing measurement as median weight. Keep both checks because they prove different properties. |
| Change support floor metadata along with CI | Raise the Elixir constraint or alter current/latest lanes | Those changes are outside FLOOR-01/02. Keep Elixir/OTP and current/latest lane values stable; update only the PostgreSQL minimum and its documentation. |

There are no new external package dependencies in this phase; the package-legitimacy gate does not apply.

## Project Constraints (from AGENTS.md)

- Use named `mix verify.*` / `mix ci.*` entrypoints when documenting verification; `mix ci.all` is the canonical aggregate. [VERIFIED: `AGENTS.md:49-64`; exact command quote: `mix ci.all`]
- Keep the default test suite honest; changing test inclusion requires updating `test/test_helper.exs` and docs together. [VERIFIED: `AGENTS.md:56-64`]
- Preserve immutable GitHub Actions job IDs. The existing build-and-test job is `verify-test`; change its matrix values without renaming it. [VERIFIED: `AGENTS.md:60-64`; `.github/workflows/ci.yml:577-616`; exact ID quote: `verify-test:` at line 577]
- Expensive CI jobs must continue to run on `main` if job-level path filters are ever used. [VERIFIED: `AGENTS.md:60-64`]
- Keep guide claims aligned through doc-contract tests. [VERIFIED: `AGENTS.md:60-64`]
- Preserve capture’s generated PostgreSQL trigger and host-owned Ecto migration boundary. This phase proves compatibility; it does not redesign capture SQL. [VERIFIED: `AGENTS.md:66-74`]
- Zero human verification by default: make the support-table and missing-weight decisions executable in tests; maintainer attention is reserved for scope, secrets, and spend. [VERIFIED: `AGENTS.md:76-92`]

## Architecture Patterns

### CI compatibility evidence

The existing `verify-test` matrix has `min`, `current`, and `latest` rows. Its comments explicitly distinguish min/latest explicit pins from the current `.tool-versions` source, and call latest tested-on evidence rather than a support promise. Keep those classifications visible in the guide. [VERIFIED: `.github/workflows/ci.yml:577-616`; quote: `lane: [min, current, latest]`, `version-file: ".tool-versions"`, `pg: "16"`, and `pg: "18.6"`.]

The requirement asks for a passing complete suite on PostgreSQL 15, and PostgreSQL 15 release notes identify compatibility-affecting changes from earlier versions. Therefore, the CI minimum lane and a local full-suite run against PostgreSQL 15 are the direct product evidence; release notes are useful for identifying behavior to watch but cannot establish Threadline compatibility by themselves. [VERIFIED: `.planning/REQUIREMENTS.md:104-107`; [PostgreSQL 15 release notes](https://www.postgresql.org/docs/release/15.0/)]

### Recommended support-policy table

Use one table with columns such as `Lane`, `Elixir`, `OTP`, `PostgreSQL`, and `Meaning`. Give `min` the supported-floor meaning, and mark `current` and `latest` as tested-on lanes. This avoids the existing guide’s Phoenix adoption-lane matrix being mistaken for a runtime/database support table. Do not duplicate the values in a second table elsewhere in the guide. The Elixir constraint is declared in `mix.exs`; the exact minimum Elixir/OTP/PG row and current/latest values come from the workflow. [VERIFIED: `mix.exs:39-46`; `.github/workflows/ci.yml:600-616`; `guides/upgrade-path.md:50-66`]

### Recommended contracts

1. Extend the topology contract to parse or narrowly inspect the `verify-test` matrix and assert that the `min` row’s PostgreSQL value is 15. Include a mutation control that changes only this value and demonstrates the contract fails. Preserve the stable job ID.
2. Add a focused support-table doc contract that reads `mix.exs`, `.github/workflows/ci.yml`, and `guides/upgrade-path.md`; assert the guide’s one table reflects the source values and lane classifications. Give each failed comparison an actionable message.
3. Add a test for weights coverage that computes the same test-file set as `bin/ci-test-partitions` and compares it with the weights paths. In the mutation control, remove one real path from an in-memory weights string and assert it is reported missing. Do not weaken the runner’s median fallback or its test that unweighted files still execute; runtime assignment and measurement freshness are distinct contracts.

These are implementation recommendations based on current seams, not descriptions of already-existing behavior. [ASSUMED]

### Weight generation flow

`--write-weights` executes the whole suite once with `mix test --slowest-modules 1000`, parses per-module timings into sorted per-file weights, then atomically replaces the weights file only after a successful run. Its current behavior does not require every enumerated test to appear in the generated output; CI-01’s permanent coverage test catches this independently. Run it after any newly added test files so measurement covers the final tree. [VERIFIED: `bin/ci-test-partitions:451-528`; quote: `"$MIX_BIN" test --slowest-modules 1000` and `WEIGHTS_REL="test/partition_weights.txt"` at line 123.]

## Exact Files and Evidence Gaps

| File | Current state / gap | Phase action |
|------|---------------------|--------------|
| `mix.exs` | Comment says PostgreSQL 14 minimum and 16 current; declared Elixir value is `~> 1.15`. [VERIFIED: `mix.exs:39-46`; quote: `elixir: "~> 1.15"`] | Update only the support-contract comment’s PostgreSQL floor/current statement as required; leave the Elixir constraint unchanged. |
| `.github/workflows/ci.yml` | Existing `verify-test` `min` matrix row runs PostgreSQL 14. [VERIFIED: `.github/workflows/ci.yml:597-616`; quote: `pg: "14"`] | Set the `min` row to PostgreSQL 15; do not change the stable job ID or other lanes. |
| `test/threadline/ci_topology_contract_test.exs` | Contains CI matrix/topology contract patterns and mutation-control arrays; no current assertion found pinning the minimum PostgreSQL value. [VERIFIED: `test/threadline/ci_topology_contract_test.exs:98-104,269-334,336-451`] | Add a min-lane PG contract and a change-to-other-version mutation control. |
| `guides/upgrade-path.md` | Has a compatibility table for Phoenix adoption lanes, but no single Elixir/OTP/PostgreSQL floor and CI-lanes policy table. [VERIFIED: `guides/upgrade-path.md:50-66`] | Add one support-policy table and a source-derived doc contract. |
| `CHANGELOG.md` | Unreleased already has a `### Breaking changes` section; it contains other breaking entries, but no PG floor change. [VERIFIED: `CHANGELOG.md:20-40`] | Add a clear adopter-facing breaking-change entry explaining the PostgreSQL 15 minimum and supported action. |
| `bin/ci-test-partitions` | Missing weights receive median weight; exact-once coverage is already checked. [VERIFIED: `bin/ci-test-partitions:22-30,350-367`] | Keep runtime behavior; use a separate permanent inventory contract to require measurements. |
| `test/partition_weights.txt` | 234 entries versus 264 current `*_test.exs` files; 30 are missing. The 30 observed missing paths are the `public_sql_contract`, redaction property/policy, `capture_semantics_boundary`, `change_diff_property`, `cloak_advisory_reachability_contract`, `db_property_harness`, `export_property`, `export_public_contract`, facade-reference, three guide contracts, legacy-key findings, operator telemetry, PgBouncer, property coverage/scale, public options, action hydration, as-of/cursor properties, retention cutoff, schema fields, storage catalog, RFC4180, and telemetry contract/test files. [VERIFIED: current filesystem and weight-file comparison; header: `test/partition_weights.txt:1-6`] | Regenerate after tests settle; ensure every enumerated file has an entry and sorted path output remains intact. |
| `test/test_helper.exs` | Default test path excludes only `:pgbouncer_topology` and `:live_dialyzer` outside the PgBouncer topology run. [VERIFIED: `test/test_helper.exs:18-32`] | No test-inclusion change is required; run `mix ci.all` for the project’s normal suite coverage. |

### Support values to pin

The following existing values were opened directly in their source files; preserve these values while changing the PostgreSQL floor. [VERIFIED: `mix.exs:39-46`; `.github/workflows/ci.yml:600-616`]

> `elixir: "~> 1.15"`
> `lane: [min, current, latest]`
> `elixir: "1.15.8"` / `otp: "26.2.5.21"` / `pg: "14"`
> `version-file: ".tool-versions"` / `erlang 27.3.4.15` / `elixir 1.17.3-otp-27` / `pg: "16"`
> `elixir: "1.20.4"` / `otp: "29.1.1"` / `pg: "18.6"`

The required new PG floor is stated verbatim in the source requirement: > “The CI `min` lane runs on PG 15.” [VERIFIED: `.planning/REQUIREMENTS.md:104-107`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Timing collection and weights file formatting | A second benchmark parser or manually assigned time table | `bin/ci-test-partitions --write-weights` | The existing script owns parsing, summing per-file measurements, sorting, and safe replacement. |
| Test execution completeness | A separate runner-level assignment algorithm | Existing `verify_assignment` plus the new missing-weight contract | Assignment completeness and measured-weight completeness are separate invariants. |
| PostgreSQL compatibility evidence | A source grep or syntax-only proof | Run the full test suite on the min lane and locally against PostgreSQL 15 | Threadline’s trigger SQL and Ecto migration behavior need to execute on the claimed server version. |

## Common Pitfalls

### Keep support statements aligned

**What goes wrong:** An adopter-facing table says PostgreSQL 15 while the workflow’s `min` row or package support comment still says PostgreSQL 14.
**Why it happens:** The same claim currently lives in `mix.exs`, CI, and prose.
**How to avoid:** Pin the `min` lane in the topology contract and make the guide’s contract compare against both `mix.exs` and `ci.yml`, as FLOOR-02 requires. Keep current/latest described as tested-on coverage rather than new floor promises.
**Warning signs:** Different PG values in the changelog, mix comment, guide, or workflow.

### Do not mistake assignment for weights coverage

**What goes wrong:** CI stays green while newly added tests use fallback median weights, leaving partitions less balanced.
**Why it happens:** The script explicitly assigns the median to a file with no weight and verifies only that each discovered test runs exactly once.
**How to avoid:** Have a contract compare the complete discovered test path set with paths in the weight file, plus a mutation control; regenerate after all file churn.
**Warning signs:** More `*_test.exs` files than non-comment weight rows; currently 264 versus 234.

### Preserve full floor-lane execution

**What goes wrong:** The workflow calls PG 15 the supported floor but a filtered, partial, or skipped suite supplies the evidence.
**Why it happens:** CI job topology evolves separately from lane values.
**How to avoid:** Keep the existing `verify-test` job and full partitioned test step on every matrix row. Its runner self-test proves that failure propagation is not swallowed; the actual min-lane test step proves application behavior.
**Warning signs:** A new `if:` condition on `Run tests`, a missing job from `ci-required`, or a local run against PG 14 being presented as floor proof.

PostgreSQL 15's official release notes identify compatibility-affecting changes, including changes to default `public` schema privileges. Check that test database provisioning and migration assumptions continue to work on a fresh PostgreSQL 15 service; do not infer compatibility solely from the PG 14 suite. [CITED: [PostgreSQL 15 release notes](https://www.postgresql.org/docs/release/15.0/)]

## Code Examples

The existing matrix shape should be preserved; only the minimum row’s database image changes per FLOOR-01. The expected target is quoted in the requirement above and should also appear verbatim in the new topology test’s expected value. [VERIFIED: `.github/workflows/ci.yml:600-616`; `.planning/REQUIREMENTS.md:104-107`]

```yaml
matrix:
  lane: [min, current, latest]
  include:
    - lane: min
      elixir: "1.15.8"
      otp: "26.2.5.21"
      pg: "15"
```

The table contract should compare against the source-of-truth files; example assertion shape:

```elixir
assert support_table =~ "PostgreSQL 15"
assert ci_min_lane.pg == "15"
assert mix_elixir_requirement == "~> 1.15"
```

The current-lane values also appear verbatim in `.tool-versions`: > `erlang 27.3.4.15` and `elixir 1.17.3-otp-27`. [VERIFIED: `.tool-versions:1-2`] The eventual parser/assertion implementation is at the agent’s discretion. [ASSUMED]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Support-floor prose and CI floor can drift | A doc-contract and topology contract connect guide statements to Mix and CI values | This phase requirement | Adopter support claims become executable and attributable. |
| Missing measurement silently uses median weight | Missing measurements fail a separate permanent check; runtime still executes all tests | This phase requirement | New files cannot quietly degrade partition balance. |

## Validation Architecture

Nyquist validation is enabled (`workflow.nyquist_validation: true`). [VERIFIED: `.planning/config.json:53-54`; quote: `"nyquist_validation": true`]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Mix/Elixir) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/threadline/ci_topology_contract_test.exs` |
| Full suite command | `mix ci.all` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FLOOR-01 | Min CI row uses PG 15 and regression contract fails if changed | contract + CI integration | `mix test test/threadline/ci_topology_contract_test.exs` | ✅ topology test exists; add min-value assertion/control |
| FLOOR-02 | One support table matches Mix Elixir floor and CI min values | doc contract | `mix test test/threadline/guides/upgrade_path_contract_test.exs` (recommended focused file) | ❌ focused support table contract not found |
| CI-01 | Every enumerated test file has a weight; removing a weight makes contract fail | contract + mutation control | `mix test test/threadline/ci_topology_contract_test.exs` (or focused weights contract) | ❌ add test; script already has runner self-test |
| FLOOR-01 | Full suite passes on PostgreSQL 15 | integration | `mix ci.all` with test DB on PG 15 | CI min lane exists; local PG15 proof not yet run |

### Sampling Rate

- **Per task commit:** Run the focused contract test(s) above.
- **Phase gate:** `mix ci.all` with PostgreSQL 15 available; separately run the weight refresh after the final test inventory.

### Wave 0 Gaps

- Add a test that pins minimum PG 15 in `ci.yml` with a mutation control.
- Add a doc-contract test for the support-policy table and a missing-weight inventory contract with a deliberately unweighted fixture/control.
- No new test framework or package installation is required.

## Security Domain

The phase does not change user authentication, sessions, authorization, cryptography, or application input handling. The relevant risks are integrity of CI evidence and avoiding support claims that exceed executed proof. Security remains included because project configuration does not explicitly disable enforcement.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No auth changes. |
| V3 Session Management | no | No session changes. |
| V4 Access Control | no | No authorization changes. |
| V5 Input Validation | limited | Test-only weights coverage should consume enumerated repository paths and committed weights; preserve shell quoting in the existing runner. |
| V6 Cryptography | no | No cryptographic changes. |

### Known Threat Patterns for CI and support metadata

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| CI lane is changed or skipped while docs retain support claim | Tampering / Repudiation | Contract-test matrix value and full-suite step; preserve job identity and aggregate gate. |
| Test is present but not measured, reducing confidence in partition balance | Tampering | Compare full discovered test set to weight paths and keep a mutation control. |
| Docs call current/latest tested lanes guaranteed support | Information disclosure / Repudiation | Label min as the support floor and current/latest as tested-on evidence. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Erlang | Weight generation and Mix checks | ✓ | Elixir 1.17.3 / OTP 27 | CI min lane for floor validation; local weight generation requires Elixir ≥1.17. |
| PostgreSQL test DB | Weight generation and full test suite | ✓ | Local server reports 14.17 | Provision PostgreSQL 15 for required floor proof. |
| Docker | PostgreSQL 15 local service | ✓ | Docker 29.5.2; `postgres:15` image is present | CI min lane also supplies PG15. |
| `mix` | Test and aggregate validation | ✓ | Mix 1.17.3 | — |

**Missing dependencies with no fallback:** None observed; PostgreSQL 15 is not the local server version, but a local image and CI lane are available for that proof.

## Sources

### Primary (HIGH confidence)

- `.planning/REQUIREMENTS.md:102-112` — FLOOR-01, FLOOR-02, CI-01 exact acceptance contract.
- `mix.exs:35-47,131-150,233-258` — Elixir metadata, named tests, aggregate verification alias.
- `.github/workflows/ci.yml:597-716` — min/current/latest matrix and partitioned test execution.
- `bin/ci-test-partitions:1-30,350-367,451-528` — enumerator, fallback weighting, exactly-once guard, and weight regeneration.
- `test/threadline/ci_topology_contract_test.exs:1-16,269-451` — existing CI topology contract and mutation-control pattern.
- `guides/upgrade-path.md:50-66` and `CHANGELOG.md:20-40` — current adopter compatibility table and Unreleased breaking-change location.
- `AGENTS.md:49-74` — named verification, test honesty, stable CI IDs, doc contracts, and trigger boundary constraints.

### Secondary (MEDIUM confidence)

- [PostgreSQL 15.0 Release Notes](https://www.postgresql.org/docs/release/15.0/) — compatibility-affecting changes to review when validating on PG15.
- [PostgreSQL Versioning Policy](https://www.postgresql.org/support/versioning/) — upstream major-version maintenance lifecycle; supplementary context, not evidence of Threadline support.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A focused guide contract can parse the support table robustly enough to keep a single table authoritative; if not, use an explicit narrow table parser with anchored headings/cells. | Architecture Patterns | Overly brittle parsing could make wording edits noisy; derived claims still need live source comparison. |
| A2 | Put the weights completeness test in the existing topology test module unless it becomes large enough to justify a focused sibling. | Architecture Patterns | No behavioral risk; only test organization changes. |

## Open Questions

None that block planning. The implementation should preserve existing CI lanes and test runner behavior while adding independent contracts for support metadata and weight coverage.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — existing Mix, CI, ExUnit, and script source opened directly.
- Architecture: HIGH — topology and weighting seams are already implemented; recommendations are narrowly scoped.
- Pitfalls: HIGH — current drift and missing weight counts were measured from the repository; PostgreSQL behavior caveat is cited to official release notes.

**Research date:** 2026-10-07
**Valid until:** 2026-11-06; recheck the live CI matrix, test inventory, and official PostgreSQL lifecycle before execution if delayed.
