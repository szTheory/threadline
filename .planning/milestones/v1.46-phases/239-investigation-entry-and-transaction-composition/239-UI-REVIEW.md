# Phase 239 — UI Review

**Audited:** 2026-10-10  
**Candidate:** `b97f0ab9523de8669e53310adc757f393cbbfd36` (`worktree-agent-v146-operator-preview`)  
**Baseline:** Approved [239-UI-SPEC.md](239-UI-SPEC.md), accepted Phase 238 renders, and Phase 239 plans 01–07  
**Screenshots:** Captured — reviewed the current receipt-bound route, state, and System/light screenshots; no extra unbound screenshots were taken.  
**Interaction captures:** Captured in the receipt-bound route/state evidence and actual 200% browser zoom proof. The separate `chrome-devtools` interaction-capture workflow was not run.  
**Evidence bundles:** routes `operator_239routes_b97f0ab9final`; states `operator_239states_b97f0ab9final`; System/light `operator_239light_b97f0ab9final`; actual zoom proof `MIX_TEST_PARTITION=1791590058`. Evidence-indexed route coverage is 375/768/1280 CSS px; route observations show `scrollWidth=cssWidth` at 375px. The final-candidate zoom run read back tab zoom `2.0`, viewport 640×450 CSS px, and zero document overflow on Home, Timeline, and Transaction.

This review supersedes the prior `aa7c2186` render assessment after inspecting the final receipt-bound Home, Timeline, Transaction and System/light captures. The final `mix ci.all` run exited 0 with 3,089 root tests and 132 Phoenix example tests passing. Playwright discovered 428 tests: 357 passed and 69 were intentionally skipped; two unrelated first-attempt browser flakes recovered on retry and each passed in an isolated rerun. The final evidence index, validation, summary, code review and security audit now agree on the same candidate and outcome.

The edge disposition remains open: [239-EDGE-PROBE.json](239-EDGE-PROBE.json) records 5 of 13 applicable rows resolved and 8 unclassified/unresolved (UIS-02, UIS-03, UII-01/02/03, UIA-01/02/04). These are not passes. The separate `239-UI-PROBE.json` classifies 35/35 UI-consideration rows; that is a different set and does not close these eight edge rows. The UI-SPEC explicitly treats its 35 resolved consideration rows as acceptance criteria, not execution passes.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Investigation copy is clear and consistent, but the correlation lookup is titled “Open incident timeline,” implying a narrower incident object than the correlation behavior. |
| 2. Visuals | 3/4 | Home and Transaction have strong hierarchy; the mobile Timeline remains a long, dense list with a high scan and scroll cost. |
| 3. Color | 3/4 | Dark and light captures preserve the existing semantic palette; no measured 60/30/10 area check is included, so the palette's visual balance is not fully verified. |
| 4. Typography | 3/4 | Main route text meets the UI-SPEC's readable role sizes, while the captured Filters heading renders at 700 weight, outside the contract's 400/500/600 roles. |
| 5. Spacing | 3/4 | The 4px scale and responsive reflow are visible, but 320px and short-height conditions required by the contract are not in the current capture matrix. |
| 6. Experience Design | 2/4 | Route/state/zoom coverage is broad, but eight explicit edge rows remain unclassified and narrow/short viewport acceptance is incomplete. |

**Overall: 17/24**

There are no BLOCKER findings in the reviewed evidence. The findings below are WARNINGs: they reduce polish or leave part of the approved contract unverified, but the captured Home → Timeline → Transaction flows remain usable.

## Top 3 Priority Fixes

1. **Classify the eight unresolved edge rows** — reviewers cannot treat the semantic edge contract as closed — record explicit, reviewed dispositions for the eight IDs in the owning planning artifact; preserve unresolved status until then.
2. **Reduce the mobile Timeline scan burden** — the 375px route presents a long set of similarly dense activity rows and many actions — keep operation/table and row/actor identity together, preserve a clear transaction action, and test any density adjustment against the full row set.
3. **Complete the responsive acceptance matrix** — the UI-SPEC names 320px and short viewport heights, while the current route matrix starts at 375px and the zoom proof uses 640×450 CSS px — add route/state evidence at 320px and a short viewport height before claiming those conditions verified.

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **PASS evidence:** Home uses the approved supporting copy and the same primary wording, “Open the timeline,” for the primary CTA and correlation form (`lib/threadline/operator_surface/live/start_live.ex:187-191, 229-236, 345-365`). The rendered 375px Home screenshot confirms those labels remain readable and adjacent to their fields/actions.
- **PASS evidence:** Timeline's retryable error and filter-empty copy are task-specific (`timeline_live.ex:429-430, 478`); Transaction keeps missing/not-found messaging distinct from pruning and offers a return path (`transaction_live.ex:113-147`).
- **WARNING:** The correlation panel heading “Open incident timeline” (`start_live.ex:345-348`) implies the correlation ID identifies an incident. The input and behavior are correlation-based and can join request/job/integration activity; prefer a heading such as “Find changes by correlation” or “Resume a timeline search.”
- No generic “Submit,” “Click Here,” or ambiguous “OK” action was found in the reviewed journey.

### Pillar 2: Visuals (3/4)

- **PASS evidence:** The Home render places the 32px lead and health signals before the single full-width Timeline card, then separates readiness/evidence destinations from row and correlation lookup. At 375px, cards stack in the intended order; at 1280px, the familiar navigation shell and two-column secondary cards remain intact.
- **PASS evidence:** Transaction renders its semantic summary before distinct change cards. At 375px, transaction facts stack as labeled pairs and Before/After evidence remains labeled and readable; at 1280px, the same information gains horizontal room without becoming a forced heterogeneous table.
- **WARNING — scan density:** The 375px Timeline capture is a very long list. Operation and table chips, actor/row values, and transaction/history actions are present, but repeated metadata and controls create a substantial scroll and make rows look similar. Preserve the visible transaction action and row identity while improving scan grouping in later work (`timeline_live.ex:532-577`; `style/06_layout_primitives.css:339-351`).
- Home, Timeline, and Transaction captures show the corrected mobile lead, wrapping long correlation content, and tablet-to-desktop fact-grid progression; the observations show no horizontal page overflow at the captured 375px width.

### Pillar 3: Color (3/4)

- **PASS evidence:** Dark and Light Home screenshots retain the established neutral page ground and raised surfaces. Blue is concentrated on the primary CTA, selected navigation/theme state, links, and focus; operation/status colors carry insert/update/delete or health meaning. Theme observations confirm the System preference follows the OS and Light uses the expected light page ground.
- **WARNING — area balance evidence:** The UI-SPEC calls for an approximate 60/30/10 visual-area balance. The scorecards record sampled computed colors and semantic tokens, but do not measure screen-area proportions. Keep this at 3/4 rather than treating token declarations alone as proof of the visual distribution.
- Registry audit is not applicable: the UI-SPEC says shadcn is not initialized and no third-party registry is used.

### Pillar 4: Typography (3/4)

- **PASS evidence:** The 375px Home scorecard measures the lead heading at 32px/500, body copy at 16px, and labels at 14px. Sampled Transaction values and labels are 14px; identifiers use the mono treatment. These match the UI-SPEC's role floors.
- **WARNING — weight role:** The 375px Timeline scorecard records `h2.tl-modal__title` at 24px/700 while the UI-SPEC limits role weights to 400/500/600. The Filters drawer title is rendered from `timeline_live/filters.ex:137`; give it an explicit 600 role if the default heading weight is not intentional.
- **WARNING — dense list:** The captured Timeline's subordinate facts/actions are compact relative to page headings. No below-floor size was found in the sampled 375px route scorecard, but additional shrinking would make the already long list harder to scan.

### Pillar 5: Spacing (3/4)

- **PASS evidence:** Route scorecards expose the declared 4px base steps (4, 8, 12, 16, 20, 24, 32, 40, 48px). Responsive CSS keeps Timeline facts to one column on narrow screens, two at tablet, and three at 1280px (`style/09_responsive.css:140-150, 236-252`).
- **PASS evidence:** The long-correlation mobile observation stays at `scrollWidth=cssWidth=375`; the current evidence index also records actual 200% zoom at 640px CSS width with no page overflow on all three routes.
- **WARNING — missing boundary evidence:** No current candidate screenshot/observation at 320px or a separately short viewport height appears in the evidence index. The tested 375px and 640×450 zoom cases do not establish those named UI-SPEC conditions.
- **WARNING — vertical effort:** Mobile Home stacks the complete set of task cards and lookup forms; the Timeline then adds a long activity list. The hierarchy is understandable, but users should expect considerable vertical travel on a phone.

### Pillar 6: Experience Design (2/4)

- **PASS evidence:** Final evidence index records the Home → filtered Timeline → Transaction route matrix, 12/12 state tests, System/light coverage, and the actual zoom test. State coverage includes pending/empty/error/denied, focus return, offline/reconnect, keyboard/touch navigation, and theme preference/effective appearance. The index reports output/asset hash integrity and the green final CI run with its two recovered flakes accurately disclosed.
- **WARNING — unresolved edge contract:** The edge probe reports 5 resolved and 8 unclassified/unresolved rows: UIS-02, UIS-03, UII-01, UII-02, UII-03, UIA-01, UIA-02, UIA-04. Adjacent route tests do not establish their meanings; retain these as open. The separate UI probe's 35/35 resolved rows are UI-consideration classifications, not these edge dispositions or execution passes.
- **WARNING — acceptance breadth:** Evidence starts at 375px and does not include the UI-SPEC's 320px check or a separate short-height pass. Actual browser zoom is a separate, successful 200% proof and does not replace those conditions.
- **Evidence reconciliation:** `239-EVIDENCE-INDEX.md`, `239-ZOOM-PROOF.md`, `239-07-SUMMARY.md` and `239-VALIDATION.md` now identify the same final candidate. The transaction disclosure is visible and reachable in the dedicated final zoom proof.

## Files and Evidence Audited

- `239-UI-SPEC.md`, `239-EVIDENCE-INDEX.md`, `239-UI-PROBE.json`, and `239-EDGE-PROBE.json`; current `239-07-SUMMARY.md` and `239-ZOOM-PROOF.md` checked for superseded statements.
- Receipt-bound screenshots, scorecards, and observations in `operator_239routes_b97f0ab9final`, `operator_239states_b97f0ab9final`, and `operator_239light_b97f0ab9final`; full-shell route screenshots reviewed for Home, Timeline, and Transaction at 375/768/1280px, plus System/Light and state examples.
- `lib/threadline/operator_surface/live/start_live.ex`, `timeline_live.ex`, `timeline_live/filters.ex`, `transaction_live.ex`, and `ui/display.ex`.
- `lib/threadline/operator_surface/style/01_tokens.css`, `03_page_home.css`, `06_layout_primitives.css`, `07_find_detail.css`, and `09_responsive.css`.

---
*Phase: 239-investigation-entry-and-transaction-composition*  
*Candidate: b97f0ab9523de8669e53310adc757f393cbbfd36*
