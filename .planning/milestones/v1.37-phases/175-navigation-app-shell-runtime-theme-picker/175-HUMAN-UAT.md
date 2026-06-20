---
status: complete
phase: 175-navigation-app-shell-runtime-theme-picker
source: [175-VERIFICATION.md]
started: 2026-06-17T20:10:00Z
updated: 2026-06-18T12:15:00Z
---

## Current Test

[testing complete — shifted left into an automated Playwright spec]

## Tests

### 1. Playwright browser harness (visual + runtime behavior)
expected: Operator shell renders on-brand in both dark and light; theme picker switches dark/light/system with no FOUC and persists across reload; mobile nav opens/closes via native `<details>` with no nested-scroll trap; sticky topbar never covers anchored content; pager controls Older/Newer behave (disable at boundary, hide at zero). All browser specs green via `mix ci.all` (`verify.example_browser` + `verify.example_browser_light`).
result: pass
covered_by: examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts — theme server-decided (no FOUC) + picker form wired to switch (posts to /theme w/ csrf, 3 lanes, current checked, Apply); mobile nav native `<details>` toggles open/closed; sticky topbar stays above content at rest; timeline pager renders next-only Older control + hides at zero. On-brand dark+light rendering also covered by the dark + desktop-chromium-light lanes (operator-accessibility/screenshots). Pager disable-at-boundary arithmetic unit-covered by pager_test.exs.
follow_up: End-to-end runtime theme SWITCH (POST → session flip → re-render) is asserted at the form-contract level, not by driving the CSRF'd POST headlessly (signed session across the controller redirect did not flip the lane under Playwright). ThemeController + the /theme+csrf form are independently locked by surface_header_csp_test.exs. Non-blocking. See 175-VERIFICATION.md.

## Summary

total: 1
passed: 1
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none — item automated; one non-blocking runtime-switch-E2E follow-up recorded]
