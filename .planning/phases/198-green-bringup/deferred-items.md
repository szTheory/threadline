# Deferred Items

## Plan 198-12

- **Status:** acknowledged
- **Acknowledged at:** 2026-08-28 (Plan 198-12 execution)

- `mix ci.all` fails at the `verify.example` step: `examples/threadline_phoenix`'s own
  `ThreadlinePhoenix.DemoContractTest` (`test/threadline_phoenix/demo_contract_test.exs`) has
  5-9 failing tests asserting specific seeded-data shapes (org_memberships actor attribution,
  SEED-03 manifest hero transactions, SEED-05 delete incident) that do not hold against the
  current `mix demo.seed` output. This reproduces standalone (`cd examples/threadline_phoenix
  && MIX_ENV=test mix test test/threadline_phoenix/demo_contract_test.exs`), is unrelated to the
  root-repo `threadline_test` unprefixed-audit-table defect class this plan targets (no
  `Postgrex.Error ERROR 42P01 undefined_table` involved — these are `Ecto.NoResultsError` /
  assertion mismatches against demo-seed content), and matches the recurring "example precommit
  demo-seed/walkthrough failures" pattern already acknowledged & deferred across Phases 177,
  179, 180, and 182 (see `.planning/STATE.md` Deferred Items table). Out of scope for GREEN-04 —
  `files_modified` for 198-12 is limited to the 14 root test files plus `CONTRIBUTING.md`; fixing
  the example app's demo-seed generator/assertions was never part of this plan's target.
  Root `mix test` — the actual GREEN-04 headline — passes at **1397 tests, 0 failures**,
  confirmed on two consecutive runs.

## Plan 198-17

- **Status:** acknowledged
- **Acknowledged at:** 2026-08-28 (Plan 198-17 execution)

- CI run 33183920952's `Example app browser E2E (Playwright)` reported 5 failed / 9 passed /
  348 did not run. This plan diagnosed and fixed the actual cause of all 5 (two Playwright
  specs asserting a `"selected schema"` literal that commit `842bd737` (197-02) intentionally
  removed from the product one day before the CI run) with a red-then-green teeth proof —
  see `.planning/audits/198-example-browser-e2e.md`.
- **New discovery, out of this plan's scope:** running the plan's own required verify command
  (`mix verify.example_browser --project=desktop-chromium --project=mobile-chromium`, the
  reduced PR lane, unbounded locally) after the fix surfaces **28 additional failures across
  14 unrelated tests** (`operator-find-mobile.spec.ts`, `operator-phase-135-uat.spec.ts`,
  `operator-phase-173-uat.spec.ts`, `operator-phase-175-uat.spec.ts`,
  `operator-phase-177-uat.spec.ts`, `operator-screenshot-regression.spec.ts`,
  `operator-screenshots.spec.ts`, `register.spec.ts`) — none touching either file this plan
  modified. These were never visible in CI because `playwright.config.ts:141`'s
  `maxFailures: 5` always aborted the run at the first 5 failures, which (before this plan)
  were always the two now-fixed specs. **Fixing the diagnosed cause did not turn the lane
  green; it revealed the next layer of pre-existing red underneath it.** `git rm`-ing or
  narrowing any of these 28 was never considered (out of scope, unrelated cause, no diagnosis
  performed). The backstop truth "`Example app browser E2E (Playwright)` concludes success on
  the next CI run" is **not** expected to hold as a direct result of this plan alone — logged
  as WINDOWS.md entry #8 and needs a follow-up 198 (or successor-phase) gap-closure plan to
  diagnose and fix in the same disciplined, no-weakening manner as this plan.

## Plan 198-23

- **Status:** acknowledged
- **Acknowledged at:** 2026-08-28 (Plan 198-23 execution)

- Diagnosed and fixed the root cause of 7 of `mix verify.example`'s 9 (union, two-run) failures:
  `ThreadlinePhoenix.Demo.Seed.RetentionTail.run/1` called `Threadline.Retention.purge/1` with no
  `:cutoff` override, so the library's global-age default (real `DateTime.utc_now()` minus
  `keep_days`) purged every organization's epoch-anchored demo fiction as collateral damage, not
  just `offboarded-co`'s intended `-90 day` backdate — because real wall-clock time has now
  drifted more than `keep_days` (30) past the frozen `Manifest.epoch()` (2026-05-27). Fixed by
  passing an explicit, epoch-anchored `:cutoff` (the library's own documented
  stricter-than-policy seam). Red-then-green proof and full diagnosis in
  `.planning/audits/198-round4-demo-seed.md`. `mix verify.example` union failure count: 9 → 1
  (both after-runs consistent).
- **Remaining, out-of-scope, `undiagnosed`:** `ThreadlinePhoenixWeb.WalkthroughHappyPathTest`'s
  `admin export status shows seeded job states` (`walkthrough_happy_path_test.exs:145`,
  `assert html =~ "Export expired"`). Confirmed unrelated to the retention-purge cause above (the
  failing label depends on a `Threadline.Governance.ExportJob` row and
  `Threadline.OperatorSurface.Presentation`'s `expired?/2` check, a code path
  `Threadline.Retention.purge/1` never touches). Root cause not established — needs a follow-up
  198 (or successor-phase) gap-closure plan to diagnose and fix in the same disciplined,
  no-weakening manner as this plan.

## Plan 198-27

- **Status:** acknowledged
- **Acknowledged at:** 2026-08-28 (Plan 198-27 execution)

- Fixed all 12 cluster-`198-27` rows assigned by `198-round4-playwright.md` at their attributed
  causes (`operator-phase-135-uat.spec.ts`, `operator-phase-173-uat.spec.ts`,
  `operator-phase-175-uat.spec.ts`, `operator-phase-177-uat.spec.ts`), with red-then-green teeth
  proof for one failure per file. Full diagnosis, fixes, and reconciliation in
  `.planning/audits/198-round4-playwright.md`.
- **New discovery, out of this plan's scope, `undiagnosed`:** the post-fix unbounded measurement
  surfaces a failure in `operator-accessibility.spec.ts:655:3` ("opens stress rendered widgets
  with names, keyboard state, and focus entry"), mobile-chromium only (desktop-chromium passes):
  `expect(locator('#stress-dropdown-button')).toBeFocused()` times out at 15s, receiving
  "inactive" instead of "focused" after a click that is expected to move focus into the opened
  dropdown menu. This file is not in plan 198-27's `files_modified` list (only the four
  Phase-UAT specs and this audit file are), so diagnosing/fixing it is out of scope here — Rule
  1/2 auto-fix authority does not extend to files outside the declared task boundary. Root cause
  not established (could be a genuine focus-management regression, a mobile-viewport-specific
  timing issue, or non-determinism consistent with the mount-timing flake class 198-26 already
  documented for this same stress-preview surface). Needs a follow-up 198 (or successor-phase)
  gap-closure plan to diagnose and fix in the same disciplined, no-weakening manner as this plan.

## Plan 198-28

- **Status:** acknowledged (complete)
- **Acknowledged at:** 2026-08-28 (Plan 198-28 execution)

- Re-ran `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium`
  unbounded against the merged tree (post-198-23/24/25/26/27 HEAD
  `8670d0215445dc8cd540ffd7942ded0479c1d72f`): **14 failed, 15 skipped, 311 passed (4.8m)**.
  Re-derived every `seed-sensitive? = yes` row, established the CI-contributing (2) vs
  local-only (8) split, got a blocking `checkpoint:decision` answered (option A — fix at cause,
  regenerate no baseline), then fixed both CI-contributing rows at cause and improved (without
  fully closing) one local-only row. Closing count: **12 failed, 15 skipped, 313 passed (4.4m)**.
  Full diagnosis, teeth proofs, and reconciliation are in
  `.planning/audits/198-round4-playwright.md`.
- **Fixed at cause (2 rows, both CI-contributing, `operator-screenshots.spec.ts`):** a stale
  `Actor: {type} / {id}` literal removed from the product in phase 186 (commit `3022e2e0`), long
  before this round — never seed-sensitive despite 198-26's classification, confirmed by
  recomputing the deterministic actor UUID directly; plus a `getByRole("heading", {name:
  "Exports"})` strict-mode collision (same cause as cluster rows 21/22) reached only after the
  Actor fix unblocked the rest of the test.
- **Left open, with cause named, under the Task 2 no-regeneration decision (8 rows, all
  local-only, `operator-screenshot-regression.spec.ts` — none of these ever bore on the CI
  lane, since this file skips entirely under `process.env.CI`):** dense Timeline (whole-page
  layout drift predating this round, not maskable), row-history (genuinely improved by fixing a
  wrong-element locator — `data-testid` landed on the full-viewport drawer container, not the
  bounded `.tl-drawer` panel — but a residual content/height diff remains), Exports (assertion-rot
  half fixed; the screenshot diff is a legitimate, already-shipped visual change from this same
  round's `fix(198-25): route export-expired label through canonical Presentation copy`, which
  Task 2 explicitly forbids resolving via baseline regeneration), Retention (retention-run history
  row count/order varies with real pruner execution timing, not a single volatile field).
- **New discovery diagnosis corrected:** the two new out-of-cluster failures logged in Task 1
  (`operator-accessibility.spec.ts:565:3`, `operator-prove-mobile.spec.ts:38:3`, both projects
  each) are NOT a `demo/seed/exports.ex` content change as first hypothesized — `exports.ex` was
  not touched by any plan this round. The real cause, established while diagnosing cluster
  198-28's own Exports row: `fix(198-25)`'s label-copy change from `"Expired"` to
  `"Export expired"` (lowercase `expired`) broke both files' `/Expired|File unavailable/` regex
  (capital `E`), which no longer matches. Still out of this plan's declared `files_modified`, so
  not fixed here — corrected diagnosis recorded in WINDOWS.md #10/#11 for the follow-up plan.
- **Housekeeping correction:** cluster `198-28`'s row count was documented as "13 rows" in
  198-26's and 198-27's headers, but the enumerated row list contains only 10 distinct rows.
  This plan proceeds from the reconciled 10-row count rather than propagate the unverified 13
  figure — see `.planning/audits/198-round4-playwright.md`'s housekeeping note.
- **Checkpoint:** Task 2 (whether any committed PNG baseline under
  `operator-screenshot-regression.spec.ts-snapshots/` may be regenerated) was answered under
  auto-mode: option A — fix at cause, regenerate nothing, with a documented fallback to leaving a
  row open (not force-fixing) where only a regeneration could close it. No baseline file was
  written or modified; `git status --porcelain` on the snapshots directory is empty.
