# Phase 143-04 Summary: Screenshot Regression Guard

## Scope

Added a lightweight screenshot regression guard to the existing Playwright browser lane.

## Changes

- Added `operator-screenshot-regression.spec.ts`.
- Added 10 committed Playwright snapshot PNGs for fixed desktop and mobile projects.
- Covered representative polished surfaces:
  - Home/global chrome and EF1/EF4 launchers
  - dense Timeline viewport
  - row-history drawer
  - Exports readiness hierarchy
  - Retention safety hierarchy
- Masked dynamic time/copy-state elements.
- Skipped only the duplicate default Chromium project; the fixed desktop/mobile projects run through normal `npm test`, `mix verify.example_browser`, and CI.

## Verification

- Snapshot generation:
  - `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-screenshot-regression.spec.ts --update-snapshots`
  - 10 passed, 5 skipped
- Focused guard:
  - `cd examples/threadline_phoenix/e2e && E2E_BASE_URL=http://127.0.0.1:4002 npm test -- tests/operator-screenshot-regression.spec.ts`
  - 10 passed, 5 skipped
- Full browser lane:
  - `mix verify.example_browser`
  - 133 passed, 5 skipped
- Automation scan:
  - `rg -n "operator-screenshot-regression|toMatchSnapshot|toHaveScreenshot|verify.example_browser|playwright" examples/threadline_phoenix/e2e .github/workflows/ci.yml mix.exs`
  - confirms the guard spec, `toHaveScreenshot`, existing Playwright script, CI `mix verify.example_browser`, and Mix alias wiring.
- Port check:
  - `lsof -nP -iTCP:4002 -sTCP:LISTEN || true`
  - no listener after verification

## Deviations

- No `package.json` or CI edits were needed because the guard runs through the existing `npm test` discovery path.
- Dense Timeline uses a viewport-level screenshot rather than a full-page screenshot to avoid coupling the guard to volatile seeded list length while still guarding chrome, filters, row-first ordering, and mobile layout.
