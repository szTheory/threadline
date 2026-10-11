# Phase 239 Real Tab Zoom Proof

**Status:** Final candidate `b97f0ab9523de8669e53310adc757f393cbbfd36` passes the dedicated 200% tab-zoom acceptance test.

## Mechanism

- Playwright 1.60.0 launched Chrome for Testing 148.0.7778.96 in a new persistent headless Chromium context with a temporary browser profile.
- The isolated local Manifest V3 extension uses the `tabs` permission to call `chrome.tabs.setZoom(tabId, 2)` and reads the value back using `chrome.tabs.getZoom(tabId)`. The test verifies the same tab ID and zoom factor on Home → Timeline → Transaction. CSS scaling, DPR and viewport emulation are not accepted as zoom evidence.
- Configured viewport: 1280×900; measured CSS viewport at actual 200% tab zoom: 640×450. Device pixel ratio is reported separately.

## Final command and result

```sh
MIX_TEST_PARTITION=1791590058 THREADLINE_ZOOM_ACCEPT=1 \
E2E_HOST=127.0.0.1 PORT=4278 DB_HOST=127.0.0.1 \
mix verify.example_browser --project=desktop-chromium operator-zoom-proof.spec.ts
```

Exit status `0`; Playwright ran 1 test and passed. The runner's 21 E2E Node tests also passed. Final `mix ci.all` included the same zoom test in its 428-case browser roster.

| Route | CSS viewport | Document overflow | Verified controls |
|---|---:|---:|---|
| Home | 640×450 | 0px | Open Timeline, row-history table and ID, correlation lookup |
| Timeline | 640×450 | 0px | Date/table/correlation filters, Apply, Filters drawer, System/Light/Dark and theme Apply; Escape closes the drawer and restores focus to Filters |
| Transaction | 640×450 | 0px | Stacked Before/After diff, full transaction ID disclosure, native value disclosure and row-history link |

All named controls were observed visible, reachable and pointer-targetable. The run read back `zoomFactor=2` on the same tab across the route journey. Receipt-bound route/state bundles separately bind screenshots and served/local asset hashes to the same candidate receipt.

## Scope note

The dedicated proof ran on macOS; a Linux-hosted GitHub Actions zoom run was not part of this phase. No maintainer visual verification is required under the approved zero-human-verification policy.
