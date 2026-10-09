# Phase 239 Real Tab Zoom Proof

**Status:** Mechanism proven in display-free Chromium headless mode; early surface observations recorded. This is not the post-correction acceptance result, and the portability check ran locally on macOS rather than Linux CI.

## Mechanism

- Playwright: `1.60.0`; launched Chrome for Testing: `148.0.7778.96`.
- A new persistent Chromium context used Playwright's `channel: "chromium"`, `headless: true`, and an explicit 1280 × 900 viewport. It loaded only the local Manifest V3 proof extension with the `tabs` permission. The temporary browser profile was created for this run and removed when the context closed. No existing or denied CUA browser profile was attached.
- The extension service worker selected the active `127.0.0.1` test tab, called `chrome.tabs.setZoom(tabId, 2)`, then read `chrome.tabs.getZoom(tabId)`. On the display-free follow-up, the worker returned tab ID `2042572943` and factor `2.0`.
- On the headless portability run, the same tab ID `2042572943` and `2.0` readback were asserted on Home, Timeline, and Transaction. The initial page URL was `http://127.0.0.1:4181/audit`; subsequent observations used that same page/tab.
- Configured browser viewport: `1280 × 900`; at actual tab zoom, page `innerWidth × innerHeight`: `640 × 450` on all three routes. Each route now asserts the 640px CSS viewport width. `devicePixelRatio` was `2`, recorded independently and not used as zoom evidence.

## Command and Result

```sh
env -u DISPLAY PATH="/private/tmp/threadline-239-bin:$PATH" \
npm_config_cache="/private/tmp/threadline-238-npm" \
MIX_TEST_PARTITION=tl239hdless THREADLINE_E2E_PORT=4181 \
mix verify.example_browser --project=desktop-chromium operator-zoom-proof.spec.ts
```

Exit status: `0` on **macOS (`Darwin`) with `DISPLAY` unset**. Playwright discovered and ran `1` desktop test; result `1 passed`, `0 failed`. The runner's Node unit suite discovered and passed `21` tests, `0 failed`. The temporary `npx` shim skipped only the already-installed browser installer; its local project resolved Playwright `1.60.0`, matching Chromium revision `1223`. Linux CI was not run; headless launch is the structural portability correction for display-free runners.

The measured `documentElement.scrollWidth` and `clientWidth` were both `640` on all three routes (zero whole-page overflow at this proof condition). The page-reported CSS viewport width was `640` on Home, Timeline, and Transaction from the configured 1280px browser viewport at genuine 200% browser zoom.

| Route | Controls observed | Result |
|---|---|---|
| Home | Open Timeline, row-history table and ID, correlation lookup | All present, visible, keyboard-focusable, and pointer-reachable after scrolling. |
| Timeline | From, To, Table, Correlation ID, Filters, Apply; System/Light/Dark and Apply theme | All present, visible, focusable, and reachable. Filter drawer opened; Escape dismissed it and returned focus to Filters. |
| Transaction | Row history; Before/After labels; transaction ID and inline native disclosure | Row-history action present and reachable. Before/After labels and a transaction-scoped full-value disclosure were absent in this pre-Plan-03 source, recorded as early findings for the transaction UI work. |

## Interpretation and Follow-up

This run proves that the isolated Playwright Chromium path can set and read genuine 200% browser tab zoom and reuse it across the target investigation routes. It does not claim that current transaction evidence meets the approved disclosure contract. The explicit `THREADLINE_ZOOM_ACCEPT=1` mode is implemented but intentionally not run before the Plan 05 UI corrections; Plan 07 owns that post-correction acceptance run.
