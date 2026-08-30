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

## Plan 198-29

- **Status:** acknowledged (complete)
- **Acknowledged at:** 2026-08-29 (Plan 198-29 execution, gap-closure round 4)

Measured CI run `33253587315` (`ci/198-round4`, head
`f433ef3ea6fdc0667bb042addfa5a18eeb7f59e6`, PR #31 draft/DO NOT MERGE, `attempt: 1`)
concluded `failure` with **3 of 12 `ci-required` `needs:` members red** — unchanged
in count from round 3, against a stated target of 1. One dated entry per still-red
lane follows, each naming its cause and the decision or successor work that owns it.
Full record: `198-CI-MEASUREMENT.md` `## Round 4 (2026-08-29) — Measured CI run`.

### Still-red lane 1 — `verify-test` / `Run test suite (current)`

- **NEW DEFECT, first surfaced on CI this round — candidate for a round-5 plan.**
  `ThreadlinePhoenix.DemoResetTest` "prod mix demo.reset fails fast without
  `DEMO_ALLOW_RESET=1`"
  (`examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs:56`)
  fails on CI with `** (ExUnit.TimeoutError) test timed out after 60000ms` at
  `demo_reset_test.exs:69`. The job reports `109 tests, 1 failure`, then
  `** (Mix) verify.example failed (2)`.
- **Root cause:** line 69 is
  `System.cmd("mix", ["demo.reset"], cd: @app_dir, env: [{"MIX_ENV", "prod"}], stderr_to_stdout: true)`.
  On a cold CI checkout there is no `_build/prod`, so that child process must compile
  the example app **and all its dependencies** under `MIX_ENV=prod` before reaching
  the `DEMO_ALLOW_RESET` guard the test asserts on. That compile exceeds ExUnit's
  60 000 ms default, and the test carries no `@tag timeout:` budget covering the
  shell-out. Corroborating symptom in the same log: `Postgrex.Protocol ...
  disconnected: ** (DBConnection.ConnectionError) owner #PID<0.820.0> (:proc_lib)
  timed out because it owned the connection for longer than 60000ms`.
- **Classification:** a **CI-only test-harness defect** (an unbudgeted shell-out),
  **not** a demo-seed defect and **not** a product defect. It is NOT one of the
  failures plans 198-23/24/25 targeted — those fixes held. The demo-seed
  content-mismatch class D-41 named (8–9 `Ecto.NoResultsError`/assertion mismatches
  across `DemoContractTest`, `WalkthroughHappyPathTest`, `WalkthroughEvidenceTest`)
  is **gone**: 109 tests, and the single remaining failure is this timeout.
- **Local-vs-CI disagreement, recorded side by side rather than resolved by
  recency:** plan 198-25's closing local `mix verify.example` measured
  `109 tests, 0 failures` twice (36.6 s and 14.7 s wall clock, warm `_build/prod`);
  CI measured `109 tests, 1 failure` (96.1 s, cold build). Per D-01 the local figure
  is a readiness signal only; the CI figure is the evidence.
- **This defect is the sole blocker between the current state and GREEN-04.** Every
  other assertion in the `verify-test` job passes, including the root suite
  (`1423 tests, 0 failures, 1 excluded`).
- **NOT fixed here by design.** 198-29's `files_modified` contract is
  documentation-only; no source or test file was touched. **Flagged as a candidate
  for a round-5 plan**, to be fixed at cause and without weakening the assertion
  (a `@tag timeout:` budget sized for a cold prod compile, or pre-warming
  `_build/prod` in the job — never `@tag :skip`, never deleting the prod-guard
  assertion).

### Still-red lane 2 — `verify-example-browser` / `Example app browser E2E (Playwright)`

- Measured: `5 failed, 138 passed, 9 skipped, 188 did not run (5.4m)`, then
  `** (Mix) verify.example_browser failed (1)`, with
  `Testing stopped early after 5 maximum allowed failures.`
  **The count is right-censored at 5** by
  `examples/threadline_phoenix/e2e/playwright.config.ts:141`
  (`maxFailures: process.env.CI ? 5 : 0`); round 3's 5 was capped identically, so
  "5 vs 5" is a comparison of two caps, not evidence of no progress.
- **Confirmed progress, measured on CI:** all five of round 3's failing tests now
  pass (`operator-find-mobile.spec.ts:48/66/103`,
  `operator-phase-135-uat.spec.ts:76`, `operator-phase-173-uat.spec.ts:74`), and
  198-28's two CI-contributing rows pass (`operator-screenshots.spec.ts:90:3` and
  `:174:3`). 198-26/27/28's fixes held.
- **`operator-accessibility.spec.ts:565:3`** and **`operator-prove-mobile.spec.ts:38:3`**
  (both desktop-chromium) — `getByText(/Expired|File unavailable/)` not found.
  **Cause already established and unchanged: the Plan 198-28 entry above —
  `fix(198-25)`'s label-copy change from `"Expired"` to `"Export expired"`
  (lowercase `expired`) no longer matches the capital-`E` regex.** Owner: the
  follow-up plan already recorded in `WINDOWS.md` #10/#11. Still out of any executed
  plan's `files_modified`.
- **NEW, un-inventoried CI-only failure —
  `operator-responsive-mobile-first.spec.ts:577:5`** ("operator responsive matrix:
  phone › keeps every operator route usable without root horizontal overflow"),
  desktop-chromium. Verbatim:
  `Locator: getByRole('heading', { name: 'Row history', exact: true })` →
  `Error: element(s) not found`, at `operator-responsive-mobile-first.spec.ts:475`
  (helper), reached from `:587`/`:584`. **`grep -c "operator-responsive-mobile-first"
  .planning/audits/198-round4-playwright.md` returns 0** — this test appears in no
  audit row from any plan this round. **Root cause NOT established**; diagnosing it
  requires reading component source outside 198-29's documentation-only
  `files_modified`, and guessing a cause would be the unmeasured attribution this
  phase exists to prevent. **Candidate for a round-5 plan.**
- **`operator-stress.spec.ts:277:5`, `page.home.happy` dark 1024px and
  `page.timeline.empty` dark 1024px** — `toHaveScreenshot` diffs at
  `operator-stress.spec.ts:293` against
  `stress-page-home-happy-dark-1024-desktop-chromium.png` (`4779 pixels, ratio 0.02`)
  and `stress-page-timeline-empty-dark-1024-desktop-chromium.png`
  (`5823 pixels, ratio 0.02`), each against `maxDiffPixelRatio: 0.01`
  (`operator-stress.spec.ts:294`); no dimension mismatch, content-only diffs at ~2×
  tolerance. **Owner: D-39.** These are `page.*` ledger baselines — the same
  forbidden-regeneration class as the Tier A capture lane. **Red by construction, not
  by defect. No PNG baseline was regenerated and none may be for this milestone.**
- **Methodological finding for round 5:** `198-round4-playwright.md`'s inventory was
  built from **unbounded local** runs (`process.env.CI` unset, `maxFailures: 0`),
  which covers a different population than a capped CI run. Only 2 of the 5 CI
  failures appear anywhere in it. A local inventory is a weak predictor of which
  tests a capped CI run will surface.

### Still-red lane 3 — `verify-capture` / `Tier A capture lane (byte-stable evidence)`

- Failing step `Assert byte-stable regeneration (no drift from committed evidence)`
  (`.github/workflows/ci.yml:550-558`):
  `::error::Tier A capture is not byte-stable, or committed evidence is stale.`
- **198 scorecard files modified** per the step's own `git status --porcelain
  .planning/scorecards/` output — 120 `page.*`, 78 `refute.*`.
- The visible diff is **truncated at 200 lines by the workflow itself**
  (`git diff -- .planning/scorecards/ | head -200`). Across the 15 files it does
  show, every hunk is a single `scroll_cost` field, keyed deterministically by
  viewport: 1280 `18.803→40.8`, 768 `19.038→36.504`, 375 `19.85→41.953` —
  **byte-identical to rounds 2 and 3**, confirming deterministic drift, not noise.
  The remaining 183 files (including all 78 `refute.*` cells) are **not visible**, so
  no claim is made that the drift is confined to `scroll_cost` or to `page.*`.
- **Owner: D-39**, citing `.planning/audits/198-tier-a-byte-stability.md`. The only
  available remedy is Tier-A `page.*` scorecard regeneration, forbidden for this
  entire milestone. **No remedy attempted, no scorecard regenerated, lane not removed
  from `needs:`. Red by construction, not by defect.**

### Prohibitions verified for this plan

- No local result used as evidence for GREEN-04/GREEN-07 (D-01) — both statuses set
  from run `33253587315`'s conclusion strings alone.
- `ci-required`'s `needs:` list not narrowed (D-42) — `.github/` untouched;
  `git diff` on `ci.yml`, `rulesets/main.json`, `CONTRIBUTING.md` and
  `playwright.config.ts` is empty.
- No Tier-A `page.*` evidence regenerated, no PNG baseline regenerated anywhere
  (D-39).
- No check re-run, re-dispatched, or selectively retried. `attempt: 1`.
- No assertion weakened, no `@tag :skip` added, no allowlist widened.

## Round 5

- **Status:** deferred
- **Acknowledged at:** 2026-08-30 (Plan 198-36 execution, gap-closure round 5 review triage)

**IN-01 — Row-history screenshot targets a content-sized element with no height guard.**
`operator-screenshot-regression.spec.ts:117-131`'s retarget from `.tl-drawer-container` to
`.tl-drawer` is correct and well-evidenced (REVIEW.md's own assessment); the finding is
informational, suggesting a bounding-box height assertion be added before the screenshot so a
future content addition that makes the panel taller than the viewport fails with a named cause
instead of a raw pixel diff. Deferred rather than fixed in round 5 because it is genuinely
non-urgent: `operator-screenshot-regression.spec.ts:77-78` skips entirely under CI
(`test.skip(!!process.env.CI, ...)`), confirmed directly against the file, so **this finding does
not bear on any measured lane** — it is stated here explicitly, not deferred silently on size.
**Owner:** any future round-5-successor plan touching `operator-screenshot-regression.spec.ts`'s
row-history story; no phase or plan number is currently assigned. See
`.planning/phases/198-green-bringup/198-round5-review-triage.md` (IN-01 row) for the full
disposition record and its verification citation.

## Round 6 — GREEN-07 milestone disposition

- **Status:** accepted (terminal for v1.41)
- **Acknowledged at:** 2026-08-30 (Plan 198-39 execution, gap-closure round 6, blocking-decision
  checkpoint answered by the maintainer: option-a)

GREEN-07 and roadmap success criterion 3 have failed five consecutive measured CI rounds for the
same two reasons, neither a defect this phase can fix: `verify-capture` (Tier A capture lane,
byte-stable evidence) and `verify-example-browser` (3 `operator-stress.spec.ts` ledger-baseline
screenshot rows) are red **by construction** under standing decision D-39, which forbids their
only mechanical remedy — Tier-A `page.*` baseline regeneration — for the whole of milestone
v1.41. The maintainer selected option-a at the `198-39` blocking checkpoint, verbatim: "option-a".

**Owner:** the v1.41 milestone record itself — GREEN-07 is accepted in place, not moved to a
named future milestone (option (b) was explicitly not selected; no target milestone was named).

**Unblock condition, `verify-capture`:** a milestone in which Tier-A `page.*` scorecard
regeneration is authorized AND the `scroll_cost` coupling diagnosed in 198-16 (a document-wide
`scrollHeight` read tied to the stress-lab catalog size) is addressed.

**Unblock condition, `verify-example-browser`:** the same authorization, scoped to the three
named `operator-stress.spec.ts` ledger baseline rows: `page.home.happy`, `page.timeline.empty`,
`footgun.transaction-page-left-push-desktop`.

Full record, options table, and the branch/PR disposition this decision also owns:
`.planning/phases/198-green-bringup/198-39-DECISION.md`.
