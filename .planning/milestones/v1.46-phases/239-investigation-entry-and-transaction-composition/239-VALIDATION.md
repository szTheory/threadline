---
phase: "239"
slug: "investigation-entry-and-transaction-composition"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-09"
---

# Phase 239 — Validation Strategy

This began as the prospective validation contract. Executed test results are recorded below; receipt-bound browser captures and independent review artifacts are recorded in `239-EVIDENCE-INDEX.md` and the phase review files.

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | ExUnit/Phoenix LiveView; Playwright Test 1.60.0 |
| Config | `examples/threadline_phoenix/e2e/playwright.config.ts` |
| Quick run | `mix test test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/style_contract_test.exs` (narrow to the changed concern after each task) |
| Journey run | `mix verify.example_browser --project=desktop-chromium operator-timeline-investigation-flow.spec.ts` |
| Final suite | `mix ci.all` under Bash 5 with writable caches and a fresh short test partition; record actual command/environment, seed and failures |
| Feedback budget | Focused pure tests target under 30 seconds; browser/runtime startup is measured separately, not fabricated |

## Sampling Rate

Run the affected focused ExUnit/Node contract after each meaningful implementation task and the relevant mounted browser spec for behavior changes. At a wave boundary run the integrated journey/affected theme lane. Run the final required suite once on the candidate after focused checks pass; repeat only for changes, failures or unresolved concerns. Use separate fresh synthetic E2E partitions for capture and normal verification. Normal tests may not rewrite reference images.

## Per-Task Verification Map

Plan IDs and waves are assigned below. These are intended commands and failure signals, not executed results. The requirement-level map remains the acceptance cross-check:

| Requirements | Required proof | Existing seams |
| --- | --- | --- |
| UIS-01/02; UII-01 | Readable shared hierarchy, canonical labels, visible supported entry controls | start_live_test; style_contract_test; operator-shell-home and investigation-flow specs |
| UIS-03; UII-03 | JS-on native disclosure, exact bytes/timezone, independent actor/action/context, before/after, redaction canary | presentation_test; ui_test; transaction_live_test; mounted transaction flow |
| UII-02; UIA-04 | Apply/cursor reset/URL restoration; nonempty query A → delayed B, failure, denial, recovery with correct row/scope identity | timeline_live_test; investigation-flow and route-states specs |
| UIA-01 | 320/375/768/1280 reflow, short heights, long values; real tab zoom set/readback 2.0 and reachable controls | responsive/browser contracts plus new scoped zoom proof |
| UIA-02 | Saved preference vs computed appearance, OS switch under System, reload/navigation | start_live_test; accessibility/theme specs |
| UIA-03 | Keyboard/touch focus, overlapping toast/menu/drawer dismissal and return after real patches | ui_test; accessibility/component contracts |
| D-12/13/14 | Forward candidate receipt, immutable baseline, scoped synthetic DB/loopback/source/assets and negative controls | evidence support/runner contracts; existing auth/scope tests; test discovery/weights |

### Task and wave map

| Task | Wave | Target | Focused automated gate and observable failure |
| --- | --- | --- | --- |
| 239-01-01 | 1 | Home→applied Timeline→transaction tracer | `mix verify.example_browser --project=desktop-chromium operator-timeline-investigation-flow.spec.ts`; fail on zero discovery, broken path, scope mismatch |
| 239-01-02 | 1 | Home supported jobs/copy | `mix test test/threadline/operator_surface/live/start_live_test.exs`; fail on zero tests, lost controls or false health/context |
| 239-01-03 | 1 | Applied URL/history/cursor | `mix test test/threadline/operator_surface/live/timeline_live_test.exs`; fail on zero tests, wrong URL/query/cursor/scope |
| 239-02-01 | 1 | Real tab zoom mechanism | `mix verify.example_browser --project=desktop-chromium operator-zoom-proof.spec.ts`; fail on absent set/get 2.0 or zero tests |
| 239-02-02 | 1 | Controls at measured zoom | same zoom spec; fail on hidden control, overflow or missing readback |
| 239-03-01 | 2 | Transaction/change tracer | `mix verify.example_browser --project=desktop-chromium operator-transaction-evidence.spec.ts`; fail on missing semantic/change labels or zero tests |
| 239-03-02 | 2 | Exact sanctioned disclosure | `mix test test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/transaction_live_test.exs`; fail on missing full bytes/timezone or canary leakage |
| 239-03-03 | 2 | Detail cardinality/states | `mix test test/threadline/operator_surface/transaction_live_test.exs`; fail on zero tests, inferred actor or mislabeled states |
| 239-04-01 | 2 | Populated A→held B | `mix verify.example_browser --project=desktop-chromium operator-route-states.spec.ts`; fail unless A nonempty and B truly held, or if rows/scope mismatch |
| 239-04-02 | 2 | Empty/error/denial/recovery | `mix test test/threadline/operator_surface/live/timeline_live_test.exs`; fail on collapsed status or altered query/scope |
| 239-06-01 | 2 | Theme selection/effective appearance | `mix verify.example_browser_light --project=desktop-chromium-light operator-accessibility.spec.ts`; fail on zero tests or mismatched computed colors |
| 239-06-02 | 2 | Overlay stack/focus | `mix verify.example_browser --project=desktop-chromium operator-accessibility.spec.ts operator-component-contracts.spec.ts`; fail on zero per-spec discovery or wrong focus/top layer |
| 239-05-01 | 3 | Long-filter reflow/tokens | `mix verify.example_browser --project=desktop-chromium operator-timeline-investigation-flow.spec.ts`; fail on lost 232 chars, controls or page overflow |
| 239-05-02 | 3 | Home/detail role floors and rendered reflow | `mix test test/threadline/operator_surface/style_contract_test.exs` plus `mix verify.example_browser --project=desktop-chromium operator-transaction-evidence.spec.ts`; fail on empty circular aliases/role floors, zero browser discovery, Home/Transaction overflow or unreachable controls/evidence |
| 239-07-01 | 4 | Forward receipt + one Home capture | `THREADLINE_E2E_EVIDENCE=1 MIX_TEST_PARTITION=operator_239trace_$(date +%s)_$$ mix verify.example_browser --project=route-capture operator-page-capture.spec.ts --grep "home"`; fail on zero tests or custody/source/asset mismatch |
| 239-07-02 | 4 | Negative custody controls | `examples/threadline_phoenix/e2e/node_modules/.bin/tsx --test examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts`; fail on zero tests or a forged receipt/asset/unsafe DB accepted |
| 239-07-03 | 4 | Bounded review and final gate | `/opt/homebrew/bin/bash -lc 'MIX_TEST_PARTITION=tl239_$(date +%s) mix ci.all'`; fail on suite failure, undiscovered tests or open required proof reported green |

Wave 1 plans 01/02 have no file overlap. Wave 2 plans 03/04/06 have no file overlap. Plan 05 waits for all source/zoom inputs; plan 07 waits for all implementation and owns the forward evidence tooling. Existing ExUnit files already have partition weights; any newly added ExUnit path must gain a nonzero or explicit measured weight before 239-07-03. The actual Playwright projects are `desktop-chromium`, `mobile-chromium`, `route-capture`, and conditional `desktop-chromium-light`; no invented project is used.

### UI, edge, prohibition and threat coverage — planned, unexecuted

| Source set | Count and mapping | Execution disposition |
| --- | --- | --- |
| UI Considerations | 35/35: UC-239-01–06 → 01/05/02; 07–14 → 01/04/05; 15–26 → 03/05/02; 27–35 → 06/05/02 | Explicit truths in PLAN must_haves; final rendered review records actual results. |
| Resolved edge probe | 5/5: UIS-01 empty and encoding → 05/03; UIA-03 adjacency, empty-child and ordering → 06 | Plain measurable truths; no backstop substitution. |
| Unclassified edge probe | 8/8: UIS-02, UIS-03, UII-01, UII-02, UII-03, UIA-01, UIA-02, UIA-04 → flagged `must_haves.assumptions` in 01/03/04/05/06 | Remain unresolved until genuinely classified; no auto-dismissal or fabricated pass. |
| Bespoke prohibition recall | 10 descriptor-less flagged items in plans 01–07 | `must_haves.prohibitions` only; no `check_*` descriptor or invented test pass. Canon authorization/redaction concerns route to security threat checks. |
| Threats | T-239-01–19 plus SC per plan | High threats block; task gates and final evidence index must cite positive and negative controls. |

The fallback report has 13 applicable edges = 5 explicit resolved + 8 unresolved unclassified. No SPEC is present. The UI probe's 35 resolved considerations are acceptance checks; their rendered outcomes are recorded by the independent UI review. The prohibition recall uses the values/transparency/safety precision filter; ordinary engineering and OWASP canon items are handled by tests/threat model rather than minted as bespoke prohibitions. All ten requirements appear in PLAN frontmatter.

## Wave 0 Requirements

- Add focused regressions in the owning implementation tasks, reusing existing files when appropriate.
- Prove a legitimate isolated browser tab-zoom mechanism early; fail closed on denial/unavailable API and never substitute viewport/DPR/CSS scaling.
- Extend evidence custody forward without overwriting accepted before bundles or weakening source/asset/database guards.
- Confirm all selected browser projects/specs exist and newly added ExUnit files have partition weights. Avoid empty/undiscovered green runs.

## Manual-Only Verifications

None are assigned to the maintainer. Agent-rendered review and real browser automation own judgment and zoom evidence. An unavailable required proof remains a disclosed execution gap; no automatic pass or human-UAT handoff.

## Validation Sign-Off

- [x] All executable tasks have automated verification with explicit failure signals.
- [x] No three consecutive implementation tasks lack focused verification.
- [x] Required new tests and proof helpers are created before use.
- [x] No watch-mode commands or placeholder success claims.
- [x] All 35 UI considerations and requirement edge/prohibition predicates are mapped.
- [x] Actual execution evidence reconciled; Nyquist status updated by validation owner.

Approval: all requirement/task mappings have automated coverage; no validation gaps remain.

## Execution Record — 239-07

The earlier receipt-bound capture and CI records targeted candidates `207cf971dc6263241287b5433010b7eb2da2ff08`, `d0994c8610388b20109b80da1d466aea0217dff1`, and `f2909373788ffb1d81a4ba89410477c4d313c397`; they are historical. This execution record describes final source candidate `6d9f00387434420353aab8202da23b3db20523fb`.

Commit `f2909373788ffb1d81a4ba89410477c4d313c397` applies the three responsive review fixes: the Home lead stays 32px, long active filters wrap as compact rectangles, and Timeline facts use two columns at tablet widths and three on wide desktop. Commit `6d9f00387434420353aab8202da23b3db20523fb` makes the earned-flow browser tests wait for LiveView readiness; the previous full run showed the selected table reverting before the socket connected. The affected mobile route test passed five consecutive repeats after the change.

The final numeric-partition `mix ci.all` run used GNU Bash 5.2.37, `MIX_TEST_PARTITION=1791590010`, `THREADLINE_ZOOM_ACCEPT=1`, and writable Hex/npm caches. It exited 0: root ExUnit passed 3,089 tests with 0 failures and 3 excluded; Phoenix example ExUnit passed 132 tests with 0 failures; Dialyzer reported zero errors; the live Dialyzer slice passed 17 tests with 16 excluded; Playwright discovered 428 tests, with 359 passed, 69 intentionally skipped, and no flaky retries. Credo, format, dependency audit, repository hygiene, cycle checks, and npm unit tests passed. Focused style/live-view contracts passed 172 tests; E2E TypeScript typecheck passed; the responsive browser subset passed 9/9 across 320/375/768/1280px.

Final receipt-bound Home/Timeline/Transaction captures, state/theme evidence, genuine browser zoom proof, capture-integrity check, and refreshed independent reviews remain to be reconciled for candidate `6d9f00387434420353aab8202da23b3db20523fb`. Historical captures and counts must not be attributed to this candidate.

### Validation sign-off

- [x] All executable tasks have automated verification with explicit failure signals.
- [x] No three consecutive implementation tasks lack focused verification.
- [x] Required tests and proof helpers were created before use.
- [x] No watch-mode commands or placeholder success claims were used.
- [x] All 35 UI considerations and requirement edge/prohibition predicates are mapped.
- [ ] Final candidate browser evidence and independent reviews reconciled.

Approval: Nyquist coverage is complete; final receipt-bound evidence and independent reviews remain in progress.

### Superseding execution record — 239-07, candidate `aa7c2186`

The preceding `6d9f003` execution record is historical. The final candidate now includes `e607967` (source-bound canary and redaction corrections), `10effef` (assert focused toast close control before Escape), and `aa7c2186` (wait for the retention LiveView to connect before clicking its prune control). The latter addresses the single retry-flake observed in the first full CI run; its focused canonical Playwright test passed 5/5 repeats.

The final numeric-partition `/opt/homebrew/bin/bash -lc '... mix ci.all'` run used `MIX_TEST_PARTITION=1791590024` and `THREADLINE_ZOOM_ACCEPT=1`. It exited 0. Root ExUnit passed 3,089 tests with 0 failures and 3 excluded; Phoenix example ExUnit passed 132 tests with 0 failures; Dialyzer and the live Dialyzer slice passed; Playwright discovered 428 tests, with 359 passed, 69 intentionally skipped, and no retry-flakes. Credo reported no issues across 452 files; format, dependency audit, repository hygiene, cycle checks, and 21 E2E unit tests passed. The separate E2E TypeScript typecheck passed, as did the focused retention modal run (5/5). Genuine 200% tab zoom read back `2.0` with a 640×450 CSS viewport and zero horizontal overflow on Home, Timeline, and Transaction.

The final candidate receipt, route/state/System-light captures, capture-integrity check, and refreshed independent UI/code/security reviews are being regenerated for `aa7c2186`; the final validation checkbox remains open until those outputs are reconciled. Evidence from `6d9f003` and earlier must not be attributed to this candidate.

### Final superseding execution record — 239-07, candidate `b97f0ab9`

This record supersedes the earlier `6d9f003` and `aa7c2186` candidate records. Final source candidate: `b97f0ab9523de8669e53310adc757f393cbbfd36`, on `worktree-agent-v146-operator-preview`, based on immutable base `9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2` and accepted Phase 238 head `43c5bcfa960b1a10cb07ef997e2231e9615dca6f`. The final product commits add LiveView readiness waits in the browser contracts and allow only the reviewed scalar `scopeDecision: "host callback"` provenance value in evidence metadata; the adversarial test still rejects `authorizationSource` and other secret-shaped fields.

The final gate ran as `PATH=/private/tmp/threadline-239-bin:$PATH HEX_HOME=/private/tmp/threadline-239-hex-ci npm_config_cache=/private/tmp/threadline-239-npm-ci MIX_TEST_PARTITION=1791590057 THREADLINE_ZOOM_ACCEPT=1 mix ci.all` using GNU Bash 5.2.37, ExUnit seed 559692, and writable temporary caches. It exited 0. Root ExUnit passed 3,089 tests with 0 failures and 3 excluded (32 property tests); the Phoenix example passed 132 tests with 0 failures; Dialyzer reported 0 errors; the live-Dialyzer slice passed 17 tests with 0 failures and 16 excluded. Credo found no issues across 452 source files, formatting, dependency audit, repository hygiene (4,718 tracked text files; 8 allowlist entries used), cycle checks, and 21 E2E Node unit tests passed. Playwright discovered 428 tests: 357 passed and 69 were intentionally skipped. Two first-attempt browser failures recovered on Playwright retry: the desktop group-catalog stress matrix timed out while waiting for a LiveView connection, and the mobile Transaction-to-row-history drawer was not found after navigation. Both tests then passed in isolated fresh partitions (1/1 each); the retry-only failures are recorded as flakes, not as a zero-flake run. The separate E2E TypeScript typecheck and the focused 200% browser-zoom acceptance check passed; the zoom test read back tab zoom 2.0 at a 640×450 CSS viewport with no horizontal overflow on Home, Timeline, or Transaction.

Final receipt-bound route/state/System-light captures, integrity results, and independent code/security/rendered reviews are recorded in `239-EVIDENCE-INDEX.md`, `239-REVIEW.md`, `239-SECURITY.md`, and `239-UI-REVIEW.md`. The exact candidate identity and capture receipt SHA must match those artifacts. The review keeps the eight unclassified edge-probe rows open and retains non-blocking error-path findings; their nearby passing UI evidence does not imply those cases were resolved.

### Final validation sign-off

- [x] All executable tasks have automated verification with explicit failure signals.
- [x] No three consecutive implementation tasks lack focused verification.
- [x] Required tests and proof helpers were created before use.
- [x] No watch-mode commands or placeholder success claims were used.
- [x] All 35 UI considerations and requirement edge/prohibition predicates are mapped and honestly classified.
- [x] Final candidate gate exited 0; retry-only browser flakes were isolated and passed.
- [x] Final receipt-bound evidence and independent reviews are reconciled in the companion artifacts.

Approval: Phase 239 validation is complete for candidate `b97f0ab9523de8669e53310adc757f393cbbfd36`; the remaining limitations and warnings are explicitly recorded and do not falsify the phase-owned acceptance claims.
