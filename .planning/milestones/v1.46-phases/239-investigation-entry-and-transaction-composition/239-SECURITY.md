---
phase: 239-investigation-entry-and-transaction-composition
candidate_sha: b97f0ab9523de8669e53310adc757f393cbbfd36
reviewed: 2026-10-10T08:33:31Z
asvs_level: 1
threats_closed: 20
threats_open: 0
status: secured
---

# Phase 239 Security Audit

## Verdict

**SECURED for the phase-owned threat model.** All 20 registered threats are mitigated for candidate `b97f0ab9523de8669e53310adc757f393cbbfd36`; no high-severity threat remains open. The review preserves the host-owned authorization and tenant-scope boundary and makes no claim beyond the listed browser and test evidence.

## Threat disposition

| Threat | Category / severity | Disposition and evidence |
|---|---|---|
| T-239-01 | Elevation of privilege / high | Forged URL scope cannot widen Timeline results; out-of-scope transaction detail is hidden. `timeline_live_test.exs:1684-1706`; `transaction_live_test.exs:875-910`. |
| T-239-02 | Repudiation / medium | Transaction actor, action actor, request ID and job ID remain separate; cross-actor attribution is rejected. `transaction_live_test.exs:167-208`. |
| T-239-03 | Elevation of privilege / high | Zoom uses a temporary persistent browser context and closes/removes it in `finally`. `operator-tab-zoom.ts:26-48`. |
| T-239-04 | Spoofing / high | Zoom targets only the loopback test tab and checks the same tab ID and exact factor 2 across routes. `operator-tab-zoom.ts:51-74`; `operator-zoom-proof.spec.ts:29-48,94-104`. |
| T-239-05 | Information disclosure / high | Redacted transaction values suppress copy targets; a seeded synthetic secret is scanned through rendered text, attributes, evidence outputs and screenshots. `transaction_live.ex:446-455`; `ui_test.exs:743-760`; `operator-evidence-manifest.test.ts:94-113`. |
| T-239-06 | Elevation of privilege / high | Transaction reads use server-owned scope and scope-query callbacks; cross-scope denial has a regression. `transaction_live.ex:16-25`; `transaction_live_test.exs:875-910`. |
| T-239-07 | Repudiation / medium | Shared action IDs do not mix transaction change rows or counts; actor and context remain distinct. `transaction_live_test.exs:167-208,271-359`. |
| T-239-08 | Information disclosure / high | A pending replacement retains the applied query and rows until B completes; it does not label A as B. `operator-route-states.spec.ts:137-181`. |
| T-239-09 | Elevation of privilege / high | Query failure/retry preserves the same tenant scope and excludes another tenant's row; unauthorized host access is denied. `timeline_live_test.exs:1955-2023`. |
| T-239-10 | Repudiation / medium | Pending, empty, failed, denied, recovered and completed states remain distinct. `operator-route-states.spec.ts:84-133`; `timeline_live_test.exs:1955-2023`. |
| T-239-11 | Information disclosure / medium | Authorized transaction disclosure remains separate from redacted content; redacted title/copy attributes are suppressed. `operator-transaction-evidence.spec.ts:89-105`; `ui_test.exs:743-760`. |
| T-239-12 | Denial of service / medium | Long unbroken filters are bounded in pending/empty states; page width and controls remain usable. `operator-route-states.spec.ts:99-133`; `operator-timeline-investigation-flow.spec.ts:603-645`. |
| T-239-13 | Spoofing / medium | Theme tests distinguish saved preference from effective OS appearance; invalid theme input does not claim persistence. `operator-route-states.spec.ts:16-39`; `start_live_test.exs:690`. |
| T-239-14 | Tampering / medium | Repeated LiveView patches test top-layer Escape handling, focus restoration and removed/disabled controls. `operator-accessibility.spec.ts:1043-1118`. |
| T-239-15 | Spoofing / high | Forward receipt validates accepted Phase 238 custody, explicit first-parent Phase 239 ancestry and source digest. Forged parent/index/context/source and extra-commit controls fail closed. `operator-evidence-manifest.ts:107-186`; `operator-evidence-manifest.test.ts:145-220`. Final receipt verified. |
| T-239-16 | Tampering / high | Every contained output and served/local CSS/JS asset is hash-checked; adversarial tests reject altered/missing assets and outputs. `operator-evidence-manifest.ts:224-303`; `operator-evidence-manifest.test.ts:111-126`. Final check: 17 manifests, 147 references, 111 unique outputs, 588 asset references. |
| T-239-17 | Tampering / high | Before database reset, evidence mode requires a fresh owned test partition, derived database, loopback target and new contained output; unsafe/reused-target negatives fail. `run-e2e.sh:77-173`; `operator-evidence-manifest.test.ts` custody tests. |
| T-239-18 | Information disclosure / high | **Closed after initial audit:** capture metadata is a bounded plain-object allowlist; secret-shaped, unknown, nested, oversized and canary-bearing values fail. Canary is inserted into the actual demo row that is redacted and checked against artifacts. `operator-browser-evidence.ts:86-89`; `operator-evidence-manifest.ts:81-134`; `operator-evidence-manifest.test.ts:94-113`; `anchors.ex:80-86`. |
| T-239-19 | Repudiation / medium | **Closed after documentation reconciliation:** validation, summary, evidence index and reviews now identify candidate `b97f0ab9`, the final gate and its two retry-only flakes, exact receipt and remaining limitations. `239-VALIDATION.md`; `239-07-SUMMARY.md`; `239-EVIDENCE-INDEX.md`. |
| T-239-SC | Tampering / high | No runtime or development dependency was added; dependency audit found all three lockfiles clean. |

## Residual code-review warnings

The companion [239-REVIEW.md](239-REVIEW.md) records three non-blocking findings: query failure during Timeline pagination can terminate the LiveView; transaction row-history deep links can bypass the unavailable fallback during a database outage; and the zoom helper rejects `localhost` although runner preflight permits it. These are availability/test-configuration gaps, not authorization bypasses or unmitigated high-severity threats in this phase's STRIDE register. No phase-owned security invariant depends on silently ignoring them.

## Scope

This audit covers the Phase 239 STRIDE register at ASVS Level 1 and the final source-bound evidence. Physical-device testing, Firefox/Safari, and unlisted deployment-specific threat assumptions were not exercised and are not claimed.
