---
phase: "199"
slug: "decouple"
status: verified
threats_open: 0
asvs_level: 1
block_on: high
audited_commit: 3680760f5a8e47c2d3a5e206e27976955bec3878
created: "2026-09-11"
updated: "2026-09-11"
---

# Phase 199 — Security

Phase 199 was audited against the threat registers authored in Plans 199-01 through 199-21 and the post-review implementation at commit `3680760f5a8e47c2d3a5e206e27976955bec3878`. ASVS depth is L1 and the blocking threshold is `high`.

## Trust Boundaries

| Boundary | Description | Data crossing |
|---|---|---|
| Caller evidence → checkers | Explicit corpus, session, route, score, and warning inputs enter repository gates | Untrusted paths, identifiers, structured evidence |
| Repository/index → artifacts | Tracked state defines manifests, removals, clean clones, packages, and planning-independent proof | Git paths, object identity, source bytes |
| Filesystem adapters → outputs | Elixir, TypeScript, and shell helpers select and replace evidence files or disposable trees | Paths, symlinks, temporary files, worktree registry |
| Database/runtime → operator surface | Audit records, actors, redaction policy, timers, and exports enter presentation and background flows | Potentially sensitive records and asynchronous messages |
| Analyzer/CI → durable claims | Dialyzer output and GitHub runs establish suppression, timing, and cache claims | Static-analysis metadata, immutable run provenance |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation evidence | Status |
|---|---|---|---|---|---|---|
| T-199-01 | Tampering | Corpus input | high | mitigate | Explicit input plus malformed/non-empty controls | closed |
| T-199-02 | Repudiation | Checker errors | medium | mitigate | Dataset/path/recovery-rich failures | closed |
| T-199-03 | Tampering | Session evidence | high | mitigate | Decode/schema validation and malformed controls | closed |
| T-199-04 | Information disclosure | Runtime boundary | medium | mitigate | Injected session only; repository/config negative scans | closed |
| T-199-05 | Tampering | Elixir path containment | high | mitigate | Canonical parent, relative-path, and symlink controls | closed |
| T-199-06 | Tampering | Elixir atomic writer | high | mitigate | Exclusive sibling temp, sync, rename, cleanup tests | closed |
| T-199-07 | Tampering | TypeScript path adapter | high | mitigate | Relative/realpath containment and alias separation | closed |
| T-199-08 | Tampering | TypeScript atomic writer | high | mitigate | Exclusive temp, fsync, close, rename, failure cleanup | closed |
| T-199-09 | Tampering | Critic consumers | high | mitigate | Sole shared adapter use plus hostile ID/symlink tests | closed |
| T-199-10 | Repudiation | Critic regeneration | medium | mitigate | Atomic writes and exact contained review command | closed |
| T-199-11 | Tampering | Capture outputs | high | mitigate | Shared containment, hostile names, immutable roots | closed |
| T-199-12 | Denial of service | Capture writes | medium | mitigate | Bounded scenarios and shared atomic replacement | closed |
| T-199-13 | Tampering | Manifest membership | high | mitigate | Git-index derivation and ignored-output control | closed |
| T-199-14 | Repudiation | Byte preservation | high | mitigate | Deterministic per-path SHA-256 and mutation teeth | closed |
| T-199-15 | Tampering | Corpus move | high | mitigate | 427 R100 moves plus live joins and manifest checks | closed |
| T-199-16 | Information disclosure | Hex package | high | mitigate | Actual archive rejects fixture and planning roots | closed |
| T-199-17 | Tampering | Deletion scope | high | mitigate | Literal inventory, preflight, and live scanner | closed |
| T-199-18 | Repudiation | Historical citations | high | mitigate | Recovery SHAs and historical addendum | closed |
| T-199-19 | Tampering | Ignore policy | high | mitigate | Anchored rules and positive/negative controls | closed |
| T-199-20 | Denial of service | Formatter topology | medium | mitigate | Derived exactly-one ownership contract | closed |
| T-199-21 | Tampering | Cleanup target | high | mitigate | Canonical/lstat/worktree revalidation before removal | closed |
| T-199-22 | Repudiation | Clean proof | high | mitigate | No-local exact-SHA clone and porcelain evidence | closed |
| T-199-23 | Tampering | Test reduction | high | mitigate | Exact retirement inventory and retained live assertions | closed |
| T-199-24 | Repudiation | Planning scanner | high | mitigate | Git-derived sources and injected positive controls | closed |
| T-199-25 | Tampering | Dialyzer ignore file | high | mitigate | Literal AST/comments, broad-form rejection, zero ceiling | closed |
| T-199-26 | Repudiation | Warning triage | high | mitigate | Sealed digest and complete W01–W40 ledger | closed |
| T-199-26A | Tampering | Warning-fix scope | high | mitigate | Origin ceiling hard stop and positive control | closed |
| T-199-27 | Tampering | PLT cache | high | mitigate | Exact key and ordered restore/build/save/analyze flow | closed |
| T-199-28 | Repudiation | CI measurements | high | mitigate | Immutable authenticated run evidence and exact SHA | closed |
| T-199-28A | Spoofing | Push/dispatch handoff | high | mitigate | Remote-head and same-SHA two-run equality | closed |
| T-199-30 | Denial of service | CI aggregate | medium | mitigate | Measured nine-minute timeout with cold-run headroom | closed |
| T-199-15-01 | Tampering | Critic slice fixture | high | mitigate | Sealed warnings, unique IDs, exact origins | closed |
| T-199-15-02 | Spoofing | Warning parser | medium | mitigate | Repository-relative origins; unattributable output rejected | closed |
| T-199-15-03 | Repudiation | Critic RED/GREEN evidence | medium | mitigate | Commands, states, and post-analysis hash | closed |
| T-199-15-04 | Denial of service | Critic Dialyzer slice | low | accept | AR-199-01 | closed |
| T-199-16-01 | Tampering | Query/change specs | medium | mitigate | Concrete structs and regression tests | closed |
| T-199-16-02 | Elevation of privilege | Local storage path | high | mitigate | Explicit OTP success/error tuple matching | closed |
| T-199-16-03 | Repudiation | Query/storage fixture | medium | mitigate | Exact ten warnings, origins, live result | closed |
| T-199-16-04 | Information disclosure | Warning fixture | low | accept | AR-199-02 | closed |
| T-199-17-01 | Information disclosure | Export cleanup | high | mitigate | Close/remove ordering and failed-export tests | closed |
| T-199-17-02 | Tampering | CSV normalization | medium | mitigate | Binary contracts and byte-equality tests | closed |
| T-199-17-03 | Spoofing | Sigra identity | medium | mitigate | Map-only scalar identity and actor tests | closed |
| T-199-17-04 | Repudiation | Export/investigation fixture | medium | mitigate | Exact fifteen warnings, origins, live result | closed |
| T-199-18-01 | Spoofing | Fallback actor identity | high | mitigate | Auth/fallback/mismatch behavior tests | closed |
| T-199-18-02 | Information disclosure | Redaction presentation | high | mitigate | All nine reasons exercised through public API with exact warnings | closed |
| T-199-18-03 | Tampering | Presentation helpers | medium | mitigate | Exact output strings and value-token tests | closed |
| T-199-18-04 | Repudiation | Operator-boundary fixture | medium | mitigate | Exact seven warnings, origins, live result | closed |
| T-199-19-01 | Denial of service | LiveView refresh timers | high | mitigate | Owned replacement/cancellation plus mount/refresh/terminate tests | closed |
| T-199-19-02 | Tampering | LiveView results | medium | mitigate | Concrete callee contracts and rendered-state tests | closed |
| T-199-19-03 | Repudiation | LiveView fixture | medium | mitigate | Exact five warnings, origins, live result | closed |
| T-199-19-04 | Information disclosure | LiveView tests | low | accept | AR-199-03 | closed |
| T-199-20-01 | Tampering | Ignore filters | high | mitigate | Exact tuple/comment joins and broad/duplicate rejection | closed |
| T-199-20-02 | Repudiation | Sealed warning partition | high | mitigate | Exact W01–W40 disjoint 22-origin union | closed |
| T-199-20-03 | Elevation of privilege | Warning ceiling | high | mitigate | Zero ceiling and fail-above/no-increase controls | closed |
| T-199-20-04 | Information disclosure | Analyzer evidence | low | accept | AR-199-04 | closed |
| T-199-20-05 | Denial of service | Full PLT analysis | medium | transfer | Measured CI lane and bounded timeout | closed |
| T-199-21-01 | Tampering | Committed-clone evidence | high | mitigate | No-local detached exact-HEAD certification | closed |
| T-199-21-02 | Denial of service | Quarantine restoration | high | mitigate | Restore-before-cleanup trap and failure retention | closed |
| T-199-21-03 | Elevation of privilege | Recursive cleanup | critical | mitigate | Sole safe-temp-tree authority and hostile-target tests | closed |
| T-199-21-04 | Repudiation | Planning dependency scan | high | mitigate | Default scan and injected-reference control | closed |
| T-199-21-05 | Information disclosure | Disposable clone output | low | accept | AR-199-05 | closed |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---|---|---|---|---|
| AR-199-01 | T-199-15-04 | The full-project analyzer can consume local CPU/time, but reuses the existing PLT, is constrained to three authorized origins, and the equivalent CI lane has a measured nine-minute timeout. | Phase 199 plan-time disposition; scope revalidated by security auditor at `3680760f` | 2026-09-11 |
| AR-199-02 | T-199-16-04 | The fixture contains repository-relative source paths and static type descriptions, not runtime audit records, payloads, credentials, or secrets. | Phase 199 plan-time disposition; scope revalidated by security auditor at `3680760f` | 2026-09-11 |
| AR-199-03 | T-199-19-04 | LiveView remediation tests use versioned fixtures/rendered test state and add no runtime logging. | Phase 199 plan-time disposition; scope revalidated by security auditor at `3680760f` | 2026-09-11 |
| AR-199-04 | T-199-20-04 | Analyzer evidence is bounded to paths, warning/type descriptions, toolchain/timing, and hashes; it contains no runtime audit payloads or secrets. | Phase 199 plan-time disposition; scope revalidated by security auditor at `3680760f` | 2026-09-11 |
| AR-199-05 | T-199-21-05 | Certification uses a detached no-local clone of exact committed HEAD; caller worktree files and repository configuration are not copied. | Phase 199 plan-time disposition; scope revalidated by security auditor at `3680760f` | 2026-09-11 |

## Security Audit Trail

| Audit Date | Commit | Threats Total | Closed | Open | Result | Run By |
|---|---|---:|---:|---:|---|---|
| 2026-09-11 | `dedf7ab5` | 61 | 54 | 7 | Two blocking test-evidence gaps; five low acceptances needed attribution | gsd-security-auditor |
| 2026-09-11 | `3680760f` | 61 | 61 | 0 | secured | gsd-security-auditor |

## Verification Evidence

- Redaction and timer suites: 78 tests, 0 failures.
- Dialyzer ignore/slice contracts: 17 tests, 0 failures; all 40 warnings and 22 origins accounted for with zero live warnings.
- `mix format --check-formatted`: passed.
- `mix dialyzer --no-check`: `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`.
- No unregistered threat flags were reported by phase summaries or the post-review audit.

## Sign-Off

- [x] All threats have a disposition.
- [x] Accepted risks are documented and attributable.
- [x] `threats_open: 0` confirmed.
- [x] `status: verified` set in frontmatter.

**Approval:** verified 2026-09-11 at `3680760f5a8e47c2d3a5e206e27976955bec3878`
