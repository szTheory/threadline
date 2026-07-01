---
phase: 181-baseline-audit-and-guard-repair
reviewed: 2026-06-26T17:33:31Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshots.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator.spec.ts
  - lib/threadline/operator_surface/components/surface_header.ex
  - test/threadline/operator_surface/breadcrumb_test.exs
  - test/threadline/operator_surface/card_nesting_regression_test.exs
  - test/threadline/operator_surface/component_contract_test.exs
  - test/threadline/operator_surface/data_state_mapping_wave0_test.exs
  - test/threadline/operator_surface/live/retention_history_live_test.exs
  - test/threadline/operator_surface/router_test.exs
  - test/threadline/operator_surface/stress_fixtures_test.exs
  - test/threadline/operator_surface/stress_router_test.exs
  - test/threadline/operator_surface/style_contract_test.exs
  - test/threadline/operator_surface/surface_header_test.exs
findings:
  critical: 0
  warning: 3
  info: 0
  total: 3
status: issues_found
---

# Phase 181: Code Review Report

**Reviewed:** 2026-06-26T17:33:31Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Narrative Findings (AI reviewer)

## Summary

Reviewed the listed Phase 181 source and test files at standard depth. The production component change is small and did not show a direct correctness or security defect. The issues found are guard-quality defects in the new/repaired tests: they can pass while the behavior they claim to protect is broken. Known residuals from `181-VERIFICATION.md` were treated as inherited and are not counted here.

## Warnings

### WR-01: Responsive nav guard can pass with hidden desktop navigation

**Classification:** WARNING
**File:** `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts:287`
**Issue:** `expectOperatorChrome` records `navVisible` once and only calls `expectReachable` when that value is true or the viewport is mobile. For `>= 768px`, if a regression hides `.tl-shell-nav__panel` while the toggle is also hidden, the loop still asserts `href` on hidden links and passes. The stylesheet makes the panel persistently visible at `min-width: 768px`, so this weakens the desktop/tablet usability guard exactly where Phase 181 added the 1024px slice.
**Fix:**
```ts
const nav = shell.locator(".tl-shell-nav__panel");
if (viewportWidth < 768) {
  await openOperatorNavIfNeeded(shell);
} else {
  await expect(shell.locator(".tl-shell-nav__toggle")).toBeHidden();
  await expect(nav).toBeVisible();
}

for (const destination of destinations) {
  const link = nav.getByTestId(destination.testId);
  await expectReachable(link, { scroll: false });
  await expect(link).toHaveAttribute("href", destination.path);
}
```

### WR-02: Export auth boundary test does not prove export routes use the auth pipeline

**Classification:** WARNING
**File:** `test/threadline/operator_surface/router_test.exs:262`
**Issue:** The new router test claims to lock the HTTP export auth boundary, but it collects only `{path, action}` from `Phoenix.Router.routes/1` and then uses source substring order (`pipeline :threadline_exports` before `get("/changes.csv"`) as a proxy. That can pass if the pipeline exists earlier in the file while export controller routes are accidentally mounted outside `pipe_through(:threadline_exports)`, which is the security boundary the test is supposed to guard.
**Fix:**
```elixir
export_routes =
  routes
  |> Enum.flat_map(fn
    %{
      path: "/threadline/exports" <> _rest = path,
      plug: Threadline.OperatorSurface.Controllers.ExportController,
      plug_opts: action,
      verb: :get,
      pipe_through: pipes
    } ->
      [{path, action, pipes}]

    _route ->
      []
  end)
  |> Enum.sort()

assert Enum.map(export_routes, fn {path, action, _pipes} -> {path, action} end) ==
         Enum.sort([
           {"/threadline/exports/changes.csv", :csv},
           {"/threadline/exports/changes.json", :json},
           {"/threadline/exports/changes.ndjson", :ndjson},
           {"/threadline/exports/download/:job_id", :download}
         ])

for {path, _action, pipes} <- export_routes do
  assert :threadline_exports in pipes,
         "#{path} must be routed through the export auth pipeline"
end
```

### WR-03: CI stress screenshot allowlist guard no longer locks the actual allowlist

**Classification:** WARNING
**File:** `examples/threadline_phoenix/e2e/tests/operator-stress.spec.ts:345`
**Issue:** The previous exact `expectedCiScreenshots` check was replaced with `expect(ci).toHaveLength(3)` plus baseline-file existence. That only prevents count growth; it does not catch replacing one of the approved CI stories with a different story, including one of the local-only Tier C packet states if a baseline is added. The Phase 181 verification explicitly depends on the CI screenshot allowlist boundary staying unchanged while selected stress packet screenshots remain local evidence.
**Fix:**
```ts
const expectedCiScreenshots = [
  {
    baseline_ref: "stress-page-home-happy-dark-1024.png",
    ledger_id: "page.home.happy",
    story_id: "page.home.happy",
    theme: "dark",
    viewport: 1024,
  },
  {
    baseline_ref: "stress-page-timeline-empty-dark-1024.png",
    ledger_id: "page.timeline.empty",
    story_id: "page.timeline.empty",
    theme: "dark",
    viewport: 1024,
  },
  {
    baseline_ref: "stress-footgun-transaction-desktop-centering-dark-1024.png",
    ledger_id: "footgun.transaction-page-left-push-desktop",
    story_id: "footgun.transaction-page-left-push-desktop",
    theme: "dark",
    viewport: 1024,
  },
];

test("ledger CI screenshot allowlist is bounded and baseline-backed", () => {
  const ci = ciScreenshotAllowlist();

  expect(ci).toEqual(expectedCiScreenshots);
  for (const item of ci) {
    expect(existsSync(desktopSnapshotPath(item.baseline_ref))).toBe(true);
  }
});
```

---

_Reviewed: 2026-06-26T17:33:31Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
