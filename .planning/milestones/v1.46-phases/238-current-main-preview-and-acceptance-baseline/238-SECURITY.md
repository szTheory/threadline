---
phase: "238"
slug: current-main-preview-and-acceptance-baseline
status: verified
threats_open: 0
asvs_level: 1
created: "2026-10-09"
---

# Phase 238 — Security

## Trust Boundaries

| Boundary | Data/control crossing |
|---|---|
| Original checkout → isolated current-main worktree | Approved context and immutable base; original unrelated byte hashes retained |
| Runner → local PostgreSQL / preview process | Fresh synthetic database, loopback binding and owned process lifecycle |
| Browser → evidence files | Synthetic rendered output, allowlisted metadata and source/asset/output hashes |
| Source declarations → findings | Exact generic inventory with linked rendered evidence or explicit limitation |

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation and verification | Status |
|---|---|---|---|---|---|---|
| T-238-01 | Tampering | reset target | high | mitigate | run-e2e.sh evidence_preflight verifies fresh unique test target, local host, absent DB and no override; mutation tests reject unsafe/reused targets before reset | closed |
| T-238-02 | Spoofing | source/assets | high | mitigate | Exact receipt ancestry/context, candidateIdentity effective bytes and assetRecord served/local equality; changed-byte negative controls | closed |
| T-238-03 | Information disclosure | manifest | medium | mitigate | Manifest nested key schemas and recursive sensitive-field rejection; browser recorder retains hashes, not response bodies or credentials | closed |
| T-238-04 | Tampering | captures | high | mitigate | Recorder and serializeManifest validate unique IDs/contained outputs/hashes; live_catalog! checks each actual file and current source/assets | closed |
| T-238-05 | Elevation of privilege | direct entry | medium | mitigate | Seeded authenticated routes, existing server Auth/export guard, actual separate read-only HTTP403 probe | closed |
| T-238-06 | Repudiation | findings | medium | mitigate | Independent source scan closes 355 IDs; live findings reject missing IDs, forged hashes and source-only rendered claims | closed |
| T-238-07 | Information disclosure | receipt/index | high | mitigate | Fixed 2a1887e9: typed nested schemas for lifecycle/isolation/identity/assets and recursive secret rejection; valid-receipt negative mutations | closed |
| T-238-08 | Denial of service | preview stop | medium | mitigate | Fixed 2a1887e9: both public stop paths check JSON/PID/cwd/all local listeners/actual PID database ownership and unchanged state before SIGTERM; mocked signal positive and mismatch controls | closed |
| T-238-SC | Tampering | dependencies | high | mitigate | Existing npm lockfile/npm ci; no dependency/package/lock changes against immutable base | closed |

## Accepted Risks Log

No accepted risks. No observed secret exposure. Ordinary local process-check/signal operations cannot eliminate every OS scheduling race; only the verified owned PID is targeted.

## Security Audit Trail

| Date | Total | Closed | Open | Evidence |
|---|---|---|---|---|
| 2026-10-09 initial | 9 | 7 | 2 (1 blocking) | Typed gsd-security-auditor reproduced T07 in memory and T08 with mocked kill/rm; no actual signals |
| 2026-10-09 after repair | 9 | 9 | 0 | Same auditor rechecked 2a1887e9: 16 nested mutations rejected; owned mocked stop succeeds, wrong cwd/listener/database/changed state reject without signal/removal |

Focused logs: `/tmp/threadline-238-security-green.log` (36 ExUnit passes) and `/tmp/threadline-238-security-node.log` (20 Node passes). Contract source: `test/threadline/operator_surface/operator_evidence_contract_test.exs`; runner and controls: `examples/threadline_phoenix/e2e/run-e2e.sh`, `support/operator-evidence-manifest.test.ts`.

## Sign-Off

- [x] All nine plan-authored threats have verified mitigations.
- [x] No risk acceptance used to close a gap.
- [x] `threats_open: 0`; status verified.

**Approval:** Verified 2026-10-09 by independent security review and executable negative controls.

The subsequent code review tightened the selected-manifest path (CR-01), with actual renamed-manifest positive and forged base/hash/missing output negatives. Strict custody remains checked after portable path normalization; other reviewed security mitigations are preserved. See `238-REVIEW-FIX.md`.
