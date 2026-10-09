---
phase: "239"
slug: "investigation-entry-and-transaction-composition"
status: executed-with-blocker
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-09"
---

# Phase 239 — Validation Strategy

This began as the prospective validation contract. Task 239-07 execution results and the final-gate blocker are recorded in `239-EVIDENCE-INDEX.md` and `239-REVIEW.md` below.

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

The fallback report has 13 applicable edges = 5 explicit resolved + 8 unresolved unclassified. No SPEC is present. The UI probe's 35 resolved considerations are future checks, not runtime passes. The prohibition recall uses the values/transparency/safety precision filter; ordinary engineering and OWASP canon items are handled by tests/threat model rather than minted as bespoke prohibitions. All ten requirements appear in PLAN frontmatter, with actual completion pending execution.

## Wave 0 Requirements

- Add focused regressions in the owning implementation tasks, reusing existing files when appropriate.
- Prove a legitimate isolated browser tab-zoom mechanism early; fail closed on denial/unavailable API and never substitute viewport/DPR/CSS scaling.
- Extend evidence custody forward without overwriting accepted before bundles or weakening source/asset/database guards.
- Confirm all selected browser projects/specs exist and newly added ExUnit files have partition weights. Avoid empty/undiscovered green runs.

## Manual-Only Verifications

None are assigned to the maintainer. Agent-rendered review and real browser automation own judgment and zoom evidence. An unavailable required proof remains a disclosed execution gap; no automatic pass or human-UAT handoff.

## Validation Sign-Off

- [ ] All executable tasks have automated verification with explicit failure signals.
- [ ] No three consecutive implementation tasks lack focused verification.
- [ ] Required new tests and proof helpers are created before use.
- [ ] No watch-mode commands or placeholder success claims.
- [ ] All 35 UI considerations and requirement edge/prohibition predicates are mapped.
- [ ] Actual execution evidence reconciled; Nyquist status updated by validation owner.

Approval: approved direction; task map and execution evidence pending.

## Execution Record — 239-07

- Task 239-07-01: completed. Evidence mode produced an authenticated Home capture using the distinct forward receipt; see `239-EVIDENCE-INDEX.md`.
- Task 239-07-02: completed. The 21/21 Node custody contracts passed, including forged-parent, extra-commit, context, source, asset and unsafe-target negatives. The final route/state capture matrix and actual zoom proof are indexed.
- Task 239-07-03: rendered review and reconciliation completed. Required Bash 5 `mix ci.all` did not pass: it exited at strict Credo with three refactoring findings and two design suggestions in an unchanged Phase 238 test file. A subsequent canonical `mix verify.test` discovered 3,087 tests and ended with 36 failures and 3 exclusions. Failures include stale rendered CSS byte pins after the intentional Phase 239-05 token correction, and existing Phase 238/core test failures. No fixture refresh or unrelated repairs were made after the normal approval review denied the proposed tracked fixture rewrite as outside 239-07.
- The summary is `status: halted` pending maintainer/parent resolution of the final automated gate. This record does not claim a green full-suite result.

### Current execution counts

| Gate | Observed result |
| --- | --- |
| Forward receipt and custody validation | 1/1 passed; candidate `04f77cadb7feb44a0f294d29fbb3207ef65b387d`; the current receipt hash is in `239-EVIDENCE-INDEX.md` |
| Node custody contract tests | 21/21 passed; nonzero discovery |
| Final route capture | 3/3 passed at 1280/768/375 CSS widths; Home, filtered Timeline, Transaction |
| Evidence-state matrix | 12/12 passed in dark mode; light/System theme 1/1 passed |
| Actual browser tab zoom | 1/1 passed at `zoomFactor=2`; 640×450 CSS viewport on each route; zero document overflow |
| Captured manifest outputs/assets | 147 capture records validated; output hashes and served/local CSS/JS hashes agree |
| `mix ci.all` | Blocked at Credo; exit 10, no test stage reached |
| `mix verify.test` | 3,087 tests discovered; 36 failures; 3 excluded |

All browser evidence uses distinct fresh local test databases and loopback ports. No new ExUnit file was added; existing partition weights therefore need no update. Actual CI browser projects were checked against the repository workflow and include `desktop-chromium`, `mobile-chromium`, `route-capture`, and conditional `desktop-chromium-light`.

See `239-REVIEW.md` for requirement, UC, edge, decision and threat dispositions, including exact remaining limits.
