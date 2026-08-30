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

