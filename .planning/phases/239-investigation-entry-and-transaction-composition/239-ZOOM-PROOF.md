# Phase 239 Real Tab Zoom Proof

**Status:** Mechanism proven; early surface observations recorded. This is not the post-correction acceptance result.

## Mechanism

- Playwright: `1.60.0`; launched Chrome for Testing: `148.0.7778.96`.
- A new persistent Chromium context loaded only the local Manifest V3 proof extension with the `tabs` permission. The temporary browser profile was created for this run and removed when the context closed. No existing or denied CUA browser profile was attached.
- The extension service worker selected the active `127.0.0.1` test tab, called `chrome.tabs.setZoom(tabId, 2)`, then read `chrome.tabs.getZoom(tabId)`. The worker returned tab ID `1014977919` and factor `2.0`.
- The same tab ID and `2.0` readback were asserted again on Home, Timeline, and Transaction. The initial page URL was `http://127.0.0.1:4178/audit`; subsequent observations used the same page/tab.
- Configured project viewport: `1280 × 900`; at actual tab zoom, page `innerWidth × innerHeight`: `640 × 450`. `devicePixelRatio` was `2`, recorded independently and not used as zoom evidence.

## Command and Result

```sh
PATH="/private/tmp/threadline-239-bin:$PATH" \
npm_config_cache="/private/tmp/threadline-238-npm" \
MIX_TEST_PARTITION=tl239zoom1020 THREADLINE_E2E_PORT=4178 \
mix verify.example_browser --project=desktop-chromium operator-zoom-proof.spec.ts
```

Exit status: `0`. Playwright discovered and ran `1` desktop test; result `1 passed`. The runner's Node unit suite also discovered and passed `21` tests. The temporary `npx` shim skipped only the already-installed browser installer; its local project resolved Playwright `1.60.0`, matching Chromium revision `1223`.

The measured `documentElement.scrollWidth` and `clientWidth` were both `640` on all three routes (zero whole-page overflow at this proof condition).

| Route | Controls observed | Result |
|---|---|---|
| Home | Open Timeline, row-history table and ID, correlation lookup | All present, visible, keyboard-focusable, and pointer-reachable after scrolling. |
| Timeline | From, To, Table, Correlation ID, Filters, Apply; System/Light/Dark and Apply theme | All present, visible, focusable, and reachable. Filter drawer opened; Escape dismissed it and returned focus to Filters. |
| Transaction | Row history; Before/After labels; transaction ID and inline native disclosure | Row-history action present and reachable. Before/After labels and a transaction-scoped full-value disclosure were absent in this pre-Plan-03 source, recorded as early findings for the transaction UI work. |

## Interpretation and Follow-up

This run proves that the isolated Playwright Chromium path can set and read genuine 200% browser tab zoom and reuse it across the target investigation routes. It does not claim that current transaction evidence meets the approved disclosure contract. The explicit `THREADLINE_ZOOM_ACCEPT=1` mode is implemented but intentionally not run before the Plan 05 UI corrections; Plan 07 owns that post-correction acceptance run.
