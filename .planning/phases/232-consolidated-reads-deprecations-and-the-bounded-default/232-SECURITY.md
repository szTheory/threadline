---
phase: "232"
slug: "consolidated-reads-deprecations-and-the-bounded-default"
status: verified
threats_open: 0
threats_open_below_threshold: 1
threats_total: 19
threats_closed: 18
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-07"
---

# Phase 232 — Security

Re-verification of the six approved plan threat registers against current source.
The repeated T-232-SC entry denotes one shared threat. No new risk acceptance was
made: the two accepted dispositions below are copied from the approved plans.

## Trust Boundaries

| Boundary | Data crossing |
|----------|---------------|
| Caller and LiveView parameters to read queries | Cursor identifiers, timestamps, page sizes, limits, filters, scope and storage options |
| Row reads to telemetry | Truncation measurements and schema metadata |
| Retired entry points to current facade | Legacy arguments, caller scope, return-shape compatibility |
| Source and examples to adopter guidance | Public documentation, deprecation warnings and behavioral assertions |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and evidence | Status |
|-----------|----------|-----------|----------|-------------|-------------------------|--------|
| T-232-01 | Tampering | Page cursor validation | medium | mitigate | `lib/threadline/query/cursors.ex:193` casts UUIDs and validates DateTime; `lib/threadline/query.ex:696` binds values. | closed |
| T-232-02 | Denial of service | Paged walks | medium | mitigate | `lib/threadline/query/cursors.ex:250` rejects nil; line 227 derives `has_more` from the extra row. | closed |
| T-232-03 | Denial of service | Explicit page size | low | accept | Positive-integer validation remains; the approved plan accepts the caller's explicit choice of a large page size. See accepted risks. | closed |
| T-232-04 | Tampering | Actor cursor directions | medium | mitigate | `lib/threadline/query/cursors.ex:141` validates both directions and UUIDs; line 25 binds values. | closed |
| T-232-05 | Information disclosure | Actor history scope | high | mitigate | `lib/threadline/query.ex:501` applies scope before either cursor direction. | closed |
| T-232-06 | Repudiation | Legacy actor options | low | mitigate | `lib/threadline/query/legacy_opts.ex:68` emits replacement-specific warnings for each old option. | closed |
| T-232-07 | Information disclosure | Truncation telemetry | high | mitigate | `lib/threadline/telemetry.ex:405` emits integer limit and schema atom only; `test/threadline/telemetry_registry_contract_test.exs:225` checks the driven event. | closed |
| T-232-08 | Information disclosure | Row read scope | high | mitigate | `lib/threadline/query/row_reads.ex:52` and line 88 route list/page reads through the scoped query. | closed |
| T-232-09 | Denial of service | Default row-history read | medium | mitigate | `lib/threadline/query/row_reads.ex:17` sets 200; lines 56 and 109 require explicit infinity for unbounded reads. | closed |
| T-232-10 | Tampering | Invalid read options | low | mitigate | `lib/threadline/investigation.ex:214` rejects conflicts; `lib/threadline/query/option_keys.ex:4` restricts keys; `lib/threadline/query/row_reads.ex:74` rejects invalid limits. | closed |
| T-232-11 | Tampering | Deprecated return-shape parity | high | mitigate | `lib/threadline.ex:329` and line 617 retain delegates; `test/threadline/deprecation_parity_test.exs:175` proves 250-row parity and line 522 pins inventories. | closed |
| T-232-12 | Information disclosure | Legacy scope/storage options | medium | mitigate | `lib/threadline/query/legacy_opts.ex:99` preserves options; `lib/threadline/query/row_reads.ex:103` applies scope; `lib/threadline/query.ex:673` carries scope context. | closed |
| T-232-13 | Repudiation | Deprecated library calls | low | mitigate | `lib/threadline.ex:329` marks old calls deprecated; `.github/workflows/ci.yml:696` compiles library code with warnings as errors. | closed |
| T-232-14 | Tampering | Documentation scanners | medium | mitigate | `test/threadline/facade_only_references_contract_test.exs:298` exercises positive/negative controls; line 358 includes both upgrade guides. | closed |
| T-232-15 | Information disclosure | Internal helper documentation | low | mitigate | `lib/threadline/telemetry.ex:405` and `lib/threadline/query.ex:224` hide helpers; `test/threadline/public_surface_contract_test.exs:323` and line 382 pin hidden docs. | closed |
| T-232-16 | Tampering | ExDoc warning suppression | medium | mitigate | `mix.exs:631` retains narrow skip lists; `test/threadline/public_surface_contract_test.exs:278` pins both. | closed |
| T-232-17 | Tampering | Migrated assertions capped at 200 | medium | mitigate | `test/support/row_history.ex:10`, `test/threadline/query/as_of_property_test.exs:118` and example shape round-trip tests explicitly request infinity. | closed |
| T-232-18 | Repudiation | Test/example deprecation warnings | low | mitigate | Strict execution was recorded in the plan summary, but `mix.exs:144` and `bin/ci-test-partitions:380` do not enforce test warnings as errors persistently. Current focused suites pass; a persistent gate remains unverified. | open — below high threshold |
| T-232-SC | Tampering | Package installs | low | accept | The approved plans install no packages. See accepted risks. | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-232-01 | T-232-03 | Positive-integer validation is unchanged; an adopter choosing a huge page size is the adopter's explicit choice. | Existing disposition in approved `232-01-PLAN.md` | 2026-10-03 |
| AR-232-02 | T-232-SC | This plan installs no packages. | Existing shared disposition in all six approved plans | 2026-10-03 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-07 | 19 | 18 | 1 low, 0 blocking | gsd-security-auditor; orchestrator persisted approved risk dispositions |

## Sign-Off

- [x] All planned threats have a disposition and source evidence.
- [x] Existing accepted risks are documented without adding new acceptances.
- [x] `threats_open: 0` at the configured high threshold.
- [x] `status: verified`; one non-blocking warning-gate gap remains explicit.

**Approval:** verified 2026-10-07 at ASVS level 1, with T-232-18 open below threshold.
