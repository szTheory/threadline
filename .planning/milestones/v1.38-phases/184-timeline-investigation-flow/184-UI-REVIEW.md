# Phase 184 - UI Review

**Audited:** 2026-06-28 local / 2026-06-29 UTC
**Baseline:** `.planning/phases/184-timeline-investigation-flow/184-UI-SPEC.md`
**Screenshots:** not captured (no app dev server returned a direct usable Timeline page on localhost:3000, 5173, or 8080; 8080 served `/dashboard/` but `/audit/timeline` returned 404)
**Verification Evidence Considered:** focused source contracts 223 tests/0 failures, full Timeline browser proof 27 tests/0 failures, light/system Timeline lane 9 tests/0 failures, targeted actor+Timeline browser checks 27 tests/0 failures, and targeted legacy browser checks for removed legend/accessibility assertions 6 tests/0 failures.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | PASS: Required Timeline CTA, empty, invalid-filter, unknown-table, export, and saved-view copy remains on-contract. |
| 2. Visuals | 4/4 | PASS: Row-first command/scan/drawer hierarchy is intact and the visible post-row journey legend has been removed from `TimelineLive`. |
| 3. Color | 4/4 | PASS: Timeline uses the declared token palette with accent reserved for primary action, pivots, focus, and status facts. |
| 4. Typography | 4/4 | PASS: Prior 12px/15px/500 Timeline typography drift is resolved for command facts, lede, drawer labels, and filter summary. |
| 5. Spacing | 4/4 | PASS: Prior row stripe and badge spacing findings are resolved; Timeline row stripes use the 4px token and compact badges use token spacing. |
| 6. Experience Design | 4/4 | PASS: Prior disabled/tabindex direct download issue is resolved and browser proof checks enabled, tabbable CSV/JSON/NDJSON links. |

**Overall: 24/24**

---

## Top Priority Fixes

No priority fixes remain. The three prior priority findings and the remaining Visuals caveat are resolved.

---

## Resolved Prior Findings

1. **Direct CSV/JSON/NDJSON links disabled/tabindex - resolved.** In `lib/threadline/operator_surface/live/timeline_live.ex`, the direct export links keep `href` and `download`, but do not include permanent `aria-disabled="true"`, `tabindex="-1"`, or `data-tl-mutating`. Browser proof in `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts` asserts each link is visible, enabled, not aria-disabled, not removed from tab order, not marked mutating, has `download`, preserves the current query, and is reachable by Tab.
2. **Timeline typography using 12/15/500 roles - resolved.** Timeline-specific CSS maps command and drawer roles to the Phase 184 contract: lede uses body size at `style.ex:1143-1149`, fact labels use label size and regular weight at `style.ex:1181-1188`, fact values use body size and strong weight at `style.ex:1190-1197`, fact details use label size at `style.ex:1200-1207`, drawer utility labels use label size and regular weight at `style.ex:1462-1469`, and filter summary strong text uses strong weight at `style.ex:2863-2866`.
3. **Timeline row stripe/badge spacing - resolved.** Timeline row status stripes use `var(--tl-space-1)` (4px) for base/insert/update/delete/featured rows at `style.ex:2395-2428`. Operation badge padding is tokenized as `0 var(--tl-space-2)` at `style.ex:2440-2449`, and table-ref padding is tokenized as `0 var(--tl-space-1)` at `style.ex:2516-2518`.
4. **Visible post-row journey legend - resolved.** `lib/threadline/operator_surface/live/timeline_live.ex:450-484` now renders the pager, empty state, drawer, and shell close without a `tl-journey--legend` block. Source and browser checks assert absence at `test/threadline/operator_surface/live/timeline_live_test.exs:987-1003`, `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts:32-45`, and `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts:356-360`.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

PASS - Contract strings remain implemented in `lib/threadline/operator_surface/live/timeline_live.ex`: H1 `Investigate audit activity` at line 500, `Reset to last 24h` at line 592, `Apply` at lines 594-596, drawer title `Filters and handoff` at line 634, `Apply filters` at lines 694-696, export success copy at line 281, invalid-filter copy at line 1114, unknown-table copy at line 1142, filtered empty heading at line 1188, filtered empty body at line 1201, future-window body at line 1195, and export failure copy at lines 1268-1273.

PASS - Generic copy scan found no disallowed `Submit`, `Click Here`, `OK`, generic error, hype, SIEM, immutable-ledger, or compliance-suite language in the scoped implementation. `Save view` at `timeline_live.ex:784` is permitted by the actor-owned saved-view drawer contract and remains gated behind actor-owned saved views at `timeline_live.ex:771`.

### Pillar 2: Visuals (4/4)

PASS - The primary visual hierarchy is contract-aligned: one compact H1 and lede at `timeline_live.ex:496-504`, exactly the useful facts at `timeline_live.ex:507-520`, starter filters at `timeline_live.ex:536-597`, hybrid scan-first rows at `timeline_live.ex:384-447`, and advanced/handoff utilities in the drawer starting at `timeline_live.ex:625`.

PASS - The prior visible legend caveat is resolved. `rg` finds no `tl-journey--legend`, `Timeline workflow`, or old visible legend copy in `TimelineLive`; the only remaining `tl-journey--legend` occurrences are an inert stylesheet selector and absence assertions in tests. The LiveView render proceeds directly from rows/pager/empty-state into the drawer and shell close at `timeline_live.ex:450-484`.

PASS - Screenshot capture was unavailable because the standard dev-server probes did not expose `/audit/timeline`, but browser proof now covers the relevant rendered conditions: full Timeline proof 27/0, light/system lane 9/0, and targeted legacy legend/accessibility checks 6/0.

### Pillar 3: Color (4/4)

PASS - The declared dark and light/system palettes remain in `lib/threadline/operator_surface/style.ex`: dark background/surface/accent/destructive/signal tokens at lines 57-120 and light/system counterparts at lines 208-306.

PASS - Timeline color use remains semantic: primary actions use `.tl-button--primary`, route pivots use `.tl-link--deep`, operation badges use success/info/danger tokens, row status is reinforced with stripes plus labels, and the active window chip uses the info token. No ad hoc Timeline hardcoded colors were found outside the token source.

### Pillar 4: Typography (4/4)

PASS - Prior Timeline-specific typography drift is resolved. The command lede uses `--tl-font-size-body` at `style.ex:1147`; fact labels use `--tl-font-size-label` and `--tl-weight-regular` at lines 1183-1184; fact values use `--tl-font-size-body` and `--tl-weight-strong` at lines 1193-1194; fact details use `--tl-font-size-label` at line 1203; drawer utility labels use label size and regular weight at lines 1465-1466; filter summary strong text uses strong weight at line 2865.

PASS - The Timeline H1 remains compact at heading size/strong weight (`style.ex:1133-1140`), and scan rows use label-sized metadata and monospace only for table/ref values (`style.ex:2430-2508`). Existing global tokens like `--tl-font-size-xs`, `--tl-font-size-ui`, and `--tl-weight-medium` still exist for the broader operator surface, but are no longer used by the retuned Timeline-specific roles that triggered the prior review finding.

### Pillar 5: Spacing (4/4)

PASS - Prior row stripe and compact badge spacing findings are resolved. Timeline row stripes use `var(--tl-space-1)` (4px) at `style.ex:2399`, `2414`, `2418`, `2422`, and `2427`, matching UI-SPEC line 70. The operation badge uses token padding at `style.ex:2444`, and the table-ref badge uses token padding at `style.ex:2517`.

PASS - Other Timeline spacing remains contract-aligned: command gap 8px and bottom margin 16px at `style.ex:1116-1119`, primary filter grid gap 12px at `style.ex:1233-1237`, drawer section gap 16px at `style.ex:1414-1418`, row padding 16px at `style.ex:2395-2397`, metadata/action gaps 8px at `style.ex:2430-2437` and `style.ex:2479-2484`, and mobile compaction remains covered by the green browser lanes.

### Pillar 6: Experience Design (4/4)

PASS - Prior direct export interaction issue is resolved. CSV/JSON/NDJSON links in `timeline_live.ex` are real enabled download anchors, and the Playwright proof at `operator-timeline-investigation-flow.spec.ts` verifies enabled state, absence of `aria-disabled="true"`, absence of `tabindex="-1"`, absence of `data-tl-mutating`, `download` attributes, query-preserving `href`s, and Tab reachability.

PASS - The rest of the workflow remains implemented with URL-backed batch Apply and native controls: native datetime/table/correlation fields at `timeline_live.ex:536-575`, `phx-submit="apply"` through the Timeline form, drawer select/text fields at `timeline_live.ex:660-690`, drawer `Apply filters` at `timeline_live.ex:694-696`, and canonical query export links through `@filter_query`.

PASS - State coverage remains broad: invalid filters use `role="alert"` at `timeline_live.ex:360-363`, unknown-table and large-result statuses use `role="status"` at `timeline_live.ex:366-375`, capped results use warning alert at `timeline_live.ex:378-380`, empty states use `UI.empty_state` with state-specific variants/copy at `timeline_live.ex:459-473` and `timeline_live.ex:1184-1209`, and export failures preserve rows with clear feedback at `timeline_live.ex:1268-1273`.

PASS - Verification evidence now covers all prior findings directly: focused source contracts 223 tests/0 failures, full Timeline browser proof 27 tests/0 failures, light/system Timeline lane 9 tests/0 failures, targeted actor+Timeline browser checks 27 tests/0 failures, and targeted legacy browser checks for removed legend/accessibility assertions 6 tests/0 failures.

---

## Files Audited

- `.planning/phases/184-timeline-investigation-flow/184-01-PLAN.md`
- `.planning/phases/184-timeline-investigation-flow/184-02-PLAN.md`
- `.planning/phases/184-timeline-investigation-flow/184-03-PLAN.md`
- `.planning/phases/184-timeline-investigation-flow/184-01-SUMMARY.md`
- `.planning/phases/184-timeline-investigation-flow/184-02-SUMMARY.md`
- `.planning/phases/184-timeline-investigation-flow/184-03-SUMMARY.md`
- `.planning/phases/184-timeline-investigation-flow/184-UI-SPEC.md`
- `.planning/phases/184-timeline-investigation-flow/184-CONTEXT.md`
- `.planning/phases/184-timeline-investigation-flow/184-UI-REVIEW.md`
- `lib/threadline/operator_surface/live/timeline_live.ex`
- `lib/threadline/operator_surface/style.ex`
- `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-find-mobile.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts`
- `test/threadline/operator_surface/live/timeline_live_test.exs`
