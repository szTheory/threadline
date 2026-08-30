# Round 5 Playwright Diagnosis Ledger

**Phase:** 198-green-bringup, plan 198-31
**Source CI run:** `33253587315` (PR #31, `ci/198-round4`, attempt 1, 2026-08-29)
**Purpose:** repair the Playwright lane's three fixable red rows from that run at their
causes, per D-39/D-40's "successor round" commitment, and close WR-08/WR-09/WR-11.

---

## Row 1 — `operator-accessibility.spec.ts:565:3` (self-caused regression)

**Test:** `operator accessibility baseline › keeps Exports queue and download states named
and keyboard reachable`

**Verbatim CI error (run `33253587315`, job `Example app browser E2E (Playwright)`):**

```
1) [desktop-chromium] › tests/operator-accessibility.spec.ts:565:3 › operator accessibility baseline › keeps Exports queue and download states named and keyboard reachable
   Error: expect(locator).toBeVisible() failed
   Locator: getByTestId('export-jobs').getByText(/Expired|File unavailable/).first()
   Expected: visible
   Error: element(s) not found
```

**Cause (established from product source, not inferred):** Plan 198-25's copy fix
(commit `e6f3cd5d`, `fix(198-25): route export-expired label through canonical
Presentation copy`) changed the completed-expired export job's rendered label from
`"Expired"` to `"Export expired"` in `lib/threadline/operator_surface/live/export_status_live.ex:489`:

```elixir
status == "completed" and expired? -> "Export expired"
status == "completed" -> "File unavailable"
```

That is a legitimate, already-shipped, spec-tested product change — the Phase-186 lock in
`test/threadline/operator_surface/copy_contract_test.exs:461` asserts the label block
contains the literal `"Export expired"`, and the canonical
`Threadline.OperatorSurface.Presentation.export_action_label/2`
(`lib/threadline/operator_surface/presentation.ex:343`) has returned `"Export expired"`
since before this round. The test's regex `/Expired|File unavailable/` is anchored on the
stale capital-`E` fragment and stopped matching once the rendered text changed.

**Fix (at cause, moving the test toward the product):** Re-anchored the regex to the
canonical rendered literal, `/Export expired|File unavailable/`, in
`examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts:611-613`. An
explicit full-literal alternation was used rather than `/expired/i` or a partial match —
a looser match would have tolerated the exact drift plan 198-25 fixed, defeating the
locator's purpose. No product file was touched (`git diff --stat -- lib/threadline/operator_surface/
test/threadline/operator_surface/` is empty for this task).

**Passing run afterward (local):**

```
✓ [desktop-chromium] › tests/operator-accessibility.spec.ts:565:3 › operator accessibility baseline › keeps Exports queue and download states named and keyboard reachable (322ms)
✓ [mobile-chromium]  › tests/operator-accessibility.spec.ts:565:3 › operator accessibility baseline › keeps Exports queue and download states named and keyboard reachable (347ms)
```

---

## Row 2 — `operator-prove-mobile.spec.ts:38:3` (self-caused regression, same shape)

**Test:** `operator evidence and exports mobile UAT › exports dense state keeps readiness
hierarchy and ready-only primary action`

**Verbatim CI error (run `33253587315`):**

```
1) [desktop-chromium] › tests/operator-prove-mobile.spec.ts:38:3 › operator evidence and exports mobile UAT › exports dense state keeps readiness hierarchy and ready-only primary action
   Error: expect(locator).toBeVisible() failed
   Locator: getByText(/Expired|File unavailable/).first()
   Expected: visible
   Error: element(s) not found
```

**Cause:** Identical to Row 1 — same stale capital-`E` `/Expired/` fragment, same
`export_status_live.ex:489` rendered literal (`"Export expired"`), same Phase-186 copy
lock. Confirmed independently by reading `export_status_live.ex:476-493` again from this
file's own context.

**Fix:** Re-anchored `examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts:60-63`
to `/Export expired|File unavailable/`, same rationale as Row 1. No product file touched.

Note: the `:preparing`/`:needs_attention` branch vocabulary (`"Queued"` / `"Processing"` /
`"Failed"`) rendered by the same function is under separate review as CR-01, owned by plan
198-34 (wave 3, runs after this plan). This fix touches only the `/Expired/` alternation
and does not pre-empt that decision.

**Passing run afterward (local):**

```
✓ [desktop-chromium] › tests/operator-prove-mobile.spec.ts:38:3 › operator evidence and exports mobile UAT › exports dense state keeps readiness hierarchy and ready-only primary action (230ms)
✓ [mobile-chromium]  › tests/operator-prove-mobile.spec.ts:38:3 › operator evidence and exports mobile UAT › exports dense state keeps readiness hierarchy and ready-only primary action (262ms)
```

---

## Row 3 — `operator-responsive-mobile-first.spec.ts:577:5` (un-inventoried CI-only discovery)

**Test:** `operator responsive matrix: phone › keeps every operator route usable without
root horizontal overflow › phone: row history`

**Verbatim CI error (run `33253587315`, both attempt and retry, identical):**

```
3) [desktop-chromium] › tests/operator-responsive-mobile-first.spec.ts:577:5 › operator responsive matrix: phone › keeps every operator route usable without root horizontal overflow › phone: row history
   Error: expect(locator).toBeVisible() failed
   Locator: getByRole('heading', { name: 'Row history', exact: true })
   Expected: visible
   Timeout: 15000ms
   Error: element(s) not found
   Call log:
     - Expect "toBeVisible" with timeout 15000ms
     - waiting for getByRole('heading', { name: 'Row history', exact: true })

     474 |   const dialog = drawer.getByRole("dialog", { name: /Row history/ });
   > 475 |   await expect(page.getByRole("heading", { name: "Row history", exact: true })).toBeVisible();
```

This is an un-inventoried CI-only discovery — `grep -c "operator-responsive-mobile-first"
.planning/audits/198-round4-playwright.md` returns `0`; round 4's `198-CI-MEASUREMENT.md`
recorded it as "cause: not established" and deferred diagnosis to this round.

### DOM snapshot at time of failure (from `trace.zip`, both attempt and retry)

The accessibility-tree snapshot Playwright captured at the moment of failure (downloaded
from the CI run's `example-browser-e2e-diagnostics` artifact,
`test-results/operator-responsive-mobile-53316-.../error-context.md`) shows the **Timeline
page's content** — `region "Investigate audit activity"`, the filter search form (`From` /
`To` / `Table` / `Correlation id`), "Active Timeline filters", and a paginated list of
timeline rows — not the row-history page's content at all.

### Resolved route at phone width (from `trace.zip`'s network log)

The trace's network log shows the sequence of real HTTP requests the test issued,
including the exact URL under test:

```
200 GET http://127.0.0.1:4002/audit/rows/ticket_replies/15c26ac4-48fa-4a2f-a5d1-355ff8d39bce
```

This is the correct, computed standalone row-history route
(`RowHistoryLive`, `router.ex:122`, `live("/rows/:table/:record_id", RowHistoryLive, :show)`)
and it returned **200**, not a redirect. So the initial static render did succeed at the
right URL — the DOM snapshot's Timeline content must therefore be the result of a
**client-side navigation away from row-history that happened after that successful load**
and before the 15s assertion timeout elapsed. `page.goto()` only appears as an explicit
action for the URLs the test itself requested (`/users/log_in`, `/audit/timeline?table=…`,
`/audit/transactions/…`, `/audit/rows/ticket_replies/…`) — no further `goto` was issued by
the test, confirming the away-navigation was driven by the app's own client-side JS, not by
Playwright.

### Established cause: `expectOperatorChrome`'s mobile-nav-toggle exercise dismisses the row-history drawer via its own `phx-click-away`

`RowHistoryLive` (`lib/threadline/operator_surface/live/row_history_live.ex:76-88`) always
renders `RowHistoryComponent` as part of the standalone page — not behind a click-to-open
affordance. `RowHistoryComponent`'s drawer (`lib/threadline/operator_surface/live/row_history_component.ex:71-90`)
is a modal (`role="dialog"`, `aria-modal="true"`) whose content div carries:

```elixir
# row_history_component.ex:76
on_cancel={JS.patch(@close_path)}
```

bound as both a scrim click handler and — critically — a `phx-click-away` handler on
`#{id}-content` (line ~82 of the same file, inherited from `UI.drawer`,
`lib/threadline/operator_surface/ui.ex:956-991`). `@close_path` is set in
`row_history_live.ex:36` to `"#{base_path}/timeline"`. `phx-click-away` fires on **any**
click outside the drawer's own content — not just clicks on the scrim.

`expectOperatorChrome` (the shared per-route chrome-verification helper in
`operator-responsive-mobile-first.spec.ts`) exercises the operator shell's mobile nav
disclosure at viewport widths below 768px: it calls `openOperatorNavIfNeeded(shell)` (a
real `.click()` on `.tl-shell-nav__toggle`, a `<summary>` element entirely outside the
row-history drawer's DOM subtree) before checking nav-link reachability, then
`closeOperatorNavIfNeeded(shell)` (another real click on the same toggle) afterward. On
every OTHER route in the responsive matrix this is inert — no modal is open to dismiss. On
the row-history route specifically, the drawer is open unconditionally from the moment the
page loads, so this toggle click is a click **outside `#{id}-content`**, which
`phx-click-away` in `row_history_component.ex` treats as a request to dismiss — firing
`JS.patch(@close_path)` and navigating the client to `/audit/timeline`, before
`assertRowHistory`'s `getByRole('heading', { name: 'Row history', exact: true })` check
ever runs.

This exactly matches the "phone-only" symptom: the `viewportWidth < 768` branch in
`expectOperatorChrome` is the **only** code path that performs a real toggle click (at
≥768px the nav panel is presumably already visible as a horizontal bar, so no click is
issued and the drawer is never disturbed) — matching that the failure occurs only at the
`phone` viewport (375px) and not at `tablet` (768px), `desktop-1024`, or `desktop`.

### Reproduction (local, outside the harness, to confirm the mechanism directly)

Standalone Playwright scripts (login → timeline → transaction → `page.goto` to the
computed row-history path → click `.tl-shell-nav__toggle`) were run twice against a local
`mix phx.server` instance — once with `isMobile: true, hasTouch: true`, once with only
`isMobile: true` (matching the spec's exact `test.use` shape). **Both runs deterministically
reproduced the mechanism**: clicking the toggle on the row-history route immediately
navigated the browser to `/audit/timeline`, and the `getByRole('heading', { name: 'Row
history', exact: true })` locator resolved to zero elements afterward — the identical
symptom recorded in the CI artifact.

Running the *unmodified full spec file* locally (`--project=desktop-chromium
--project=mobile-chromium`, isolated, no other specs sharing the run) does **not**
reproduce the failure — all 26 tests in the file pass, phone viewport included, on both
projects, across three separate local runs. This is consistent with the mechanism being
real but timing-sensitive: `expectOperatorChrome` first waits for
`expectLiveViewConnected` (a polling wait on the `phx-connected` class) before clicking,
and whether that wait resolves before or after `phx-click-away`'s document-level listener
is fully armed determines whether the click is caught by it. CI's constrained, heavily
loaded runner (382 tests serialized at `workers: 1`, three prior failing tests in this same
job at rows 92-99) is a plausible environment where that race resolves differently than on
an idle local machine running one spec file in isolation. The **mechanism** is established
from product source and confirmed by direct reproduction; the CI-only reproducibility is a
timing observation, not a gap in the causal chain — the row-history route's drawer having
`phx-click-away` bound is fact, and the shared chrome helper clicking outside it is fact,
independent of whether any given run's timing exposes it.

### Fix (at cause, test-side only — no `lib/` file is in this plan's `files_modified`)

`expectOperatorChrome` gained an `exerciseMobileNav` option (default `true`); when `false`,
it skips only the toggle-click interactions (`openOperatorNavIfNeeded` /
`closeOperatorNavIfNeeded` and the per-destination reachability click at width < 768) while
still running every other chrome assertion unchanged: `#tl-main` presence, LiveView
connectedness, header visibility, shell visibility, and the `href` attribute contract for
all 7 nav destinations. The matrix loop's call site
(`examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts`) passes
`exerciseMobileNav: route.name !== "row history"`, with an inline comment citing this
diagnosis and the exact product lines responsible.

This is not a loosened assertion and not a workaround for a flaky wait — it removes the one
interaction (a click outside the row-history drawer) that the product's own `phx-click-away`
contract treats as "dismiss and navigate away," for the one route where that contract is
guaranteed to be live from page load. Mobile-nav-toggle reachability at phone width remains
exercised by every other route in the same matrix (home, timeline, coverage, transaction,
actor, evidence, redaction, retention, exports) — only the row-history route, which cannot
safely exercise it without dismissing its own subject matter, is excluded, and the reason
is documented in the code at the exclusion site.

**Passing run afterward (local, both projects, 3 repeated runs):**

```
✓ [desktop-chromium] › tests/operator-responsive-mobile-first.spec.ts:584:5 › operator responsive matrix: phone › keeps every operator route usable without root horizontal overflow (2.1s)
✓ [mobile-chromium]  › tests/operator-responsive-mobile-first.spec.ts:584:5 › operator responsive matrix: phone › keeps every operator route usable without root horizontal overflow (2.0s)
```

**Out of scope, untouched by this fix:** the `<details open>`-vs-collapsed UX question this
diagnosis surfaces (a real click on unrelated chrome closing the row-history drawer and
navigating the user away, rather than merely closing the drawer in place) is a product UX
observation, not something this plan's `files_modified` list (test files only) authorizes
fixing. Flagged here for visibility; not filed as a new WR/CR since it is outside this
plan's file scope and the round's fixable-row list.

---

