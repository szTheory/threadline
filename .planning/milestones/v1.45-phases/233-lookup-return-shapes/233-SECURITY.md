---
phase: "233"
slug: "lookup-return-shapes"
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-07"
---

# Phase 233 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Caller ID → lookup | Raw identifiers, often from URL segments, reach row queries. | IDs and lookup results |
| Host scope function → row/change queries | The host decides tenant visibility; Threadline must apply the scope or refuse. | Scope values, surface/params, SQL predicates |
| Exception message → logs/error pages | Not-found messages may be rendered or logged by Plug hosts. | Resource name and caller ID |
| Browser URL → TransactionLive | Untrusted route IDs reach the operator lookup. | Route identifier and response status |
| Concurrent retention → two-read lookup | Retention can delete rows between the transaction and change reads. | Transaction and change records |
| Package install boundary | Phase changes could alter package dependencies. | Dependency manifests and lockfiles |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-233-01 | Information disclosure | `TransactionLookup.fetch_row/2` | high | mitigate | Uses the fixed `:transaction_header` surface; rejected rows have the same not-found outcome as absent rows. | closed |
| T-233-02 | Information disclosure | `NotFoundError.message/1` | high | mitigate | Message includes only resource and caller ID; tests compare rejected/missing messages and exclude distinctive row data. | closed |
| T-233-03 | Denial of service | Malformed ID input | medium | mitigate | Malformed binary IDs return `:not_found`; non-binaries raise `ArgumentError` as programmer errors. | closed |
| T-233-04 | Repudiation / tampering | Storage schema misconfiguration | medium | mitigate | Lookup does not rescue repo errors; invalid identifiers and missing schemas remain loud. | closed |
| T-233-05 | Information disclosure | `TransactionLookup.fetch/2` changes read | high | mitigate | Changes use the fixed `:transaction` surface after the row passes `:transaction_header` scope. | closed |
| T-233-06 | Information disclosure | Caller-supplied `:surface` / `:params` | high | mitigate | The option allowlist rejects caller-supplied scope labels and parameters. | closed |
| T-233-07 | Denial of service | Garbage ID in operator route | medium | mitigate | Malformed binary IDs render not-found instead of raising a server error. | closed |
| T-233-08 | Denial of service | Caller-supplied `:preload` | medium | mitigate | The lookup option allowlist rejects arbitrary preload requests. | closed |
| T-233-09 | Tampering | Row/change race with retention | low | accept | Two READ COMMITTED reads may observe a cascade delete between them; the resulting row with fewer changes is a valid point-in-time result. | open — below high threshold |
| T-233-10 | Information disclosure | Deprecated `Query.audit_transaction/2` scope surface | high | mitigate | Deprecated API preserves its historical `:transaction` default and caller override through the shared scoped-row helper. | closed |
| T-233-11 | Information disclosure | Guide scope examples | medium | mitigate | Changelog and guides document the required `:transaction_header` clause and deny-all fallback. | closed |
| T-233-12 | Repudiation | Deprecated lookup return shape | medium | mitigate | Deprecated name retains its historical `nil`/row result; parity tests pin the behavior. | closed |
| T-233-13 | Information disclosure / elevation of privilege | `Scope.apply/2` fail-open behavior | critical | mitigate | Non-nil scope without a valid 3-arity function, or a wrong-arity function, raises; tests cover scoped reads and operator transports. | closed |
| T-233-14 | Information disclosure | Permissive adopter scope fallback | high | mitigate | Guide specifies a deny-all final clause; reference app uses `where(query, false)`. | closed |
| T-233-15 | Information disclosure | Scope misconfiguration error text | medium | mitigate | Error message omits the scope value; a test checks that secret values are absent. | closed |
| T-233-16 | Elevation of privilege | Nil scope with a scope function | medium | accept | Nil scope is the host's explicit unscoped authorization; this is documented and tested. | open — below high threshold |
| T-233-17 | Denial of service | Misconfigured host scope | low | accept | Loud failure is the intended fail-closed behavior; the changelog states the required action. | open — below high threshold |
| T-233-SC | Tampering | Package installation | low | accept | No packages or lockfile changes were introduced. | open — below high threshold |

*Only open threats at or above the configured high block threshold count toward `threats_open`.*

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-233-01 | T-233-09 | The two reads have READ COMMITTED semantics; a concurrent retention delete can remove changes after the row read without creating an invalid audit result. | Plan 233-02 disposition | 2026-10-03 |
| AR-233-02 | T-233-16 | Nil scope represents the host's explicit unscoped authorization. | Plan 233-04 disposition | 2026-10-03 |
| AR-233-03 | T-233-17 | Raising on host misconfiguration preserves fail-closed access rather than silently widening tenant reads. | Plan 233-04 disposition | 2026-10-03 |
| AR-233-04 | T-233-SC | No packages or lockfiles changed. | Plans 233-01 through 233-04 dispositions | 2026-10-03 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-07 | 18 | 14 | 4 below threshold | gsd-security-auditor; ASVS L1 |

## Sign-Off

- [x] All threats have a disposition
- [x] Accepted risks are recorded
- [x] `threats_open: 0` confirmed; four risks remain open below the high block threshold
- [x] `status: verified` set in frontmatter

**Approval:** Security verification is complete under ASVS level 1. No blocking threats remain open.
