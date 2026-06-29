---
phase: 185-coverage-and-audit-readiness
reviewed: 2026-06-29T20:34:29Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/style.ex
  - test/threadline/operator_surface/live/coverage_live_test.exs
  - test/threadline/operator_surface/coverage_doc_contract_test.exs
  - test/threadline/operator_surface/style_contract_test.exs
  - test/threadline/operator_surface/copy_contract_test.exs
  - test/threadline/operator_surface/formless_pages_test.exs
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-features.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
  - guides/operator-surface.md
  - guides/production-checklist.md
findings:
  critical: 2
  warning: 4
  info: 0
  total: 6
status: issues_found
---

# Phase 185: Code Review Report

**Reviewed:** 2026-06-29T20:34:29Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Reviewed the Phase 185 Coverage LiveView, CSS contracts, docs, and Playwright/ExUnit proof. The primary problems are in CoverageLive's selected-schema error paths: failures can reuse a snapshot from a different schema, and schema list/validation query failures can still crash the page. The test and doc contracts also overstate coverage of stale/invalid behavior.

No verification commands were run; this was a static adversarial review.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Selected-schema fetch failures can show rows from a different schema

**Classification:** BLOCKER
**File:** `lib/threadline/operator_surface/live/coverage_live.ex:332`
**Issue:** `mount/3` seeds `:coverage_for_schema` with the public header snapshot, and `fetch_coverage_for_schema/2` rescues any selected-schema fetch failure by preserving whatever snapshot is already assigned. On the first valid non-public schema load, or after switching from one schema to another, a DB/catalog failure in `Threadline.Health.trigger_coverage/1` will render the previous schema's counts and rows under the new `@schema_param`, with only a stale warning. That violates Phase 185's "selected schema truth" requirement and can make operators trust public or prior-tenant rows as the selected schema's readiness state.
**Fix:**
```elixir
# Track which schema produced the snapshot and preserve last-good data only
# when the failing refresh is for that same schema.
defp fetch_coverage_for_schema(socket, schema) do
  repo = resolve_repo(socket)
  now = DateTime.utc_now()

  try do
    coverage = Threadline.Health.trigger_coverage(repo: repo, schema: schema)
    snapshot = Snapshot.from_coverage(coverage, last_checked_at: now)

    socket
    |> assign(:coverage_for_schema, snapshot)
    |> assign(:coverage_for_schema_name, schema)
  rescue
    e ->
      message = Exception.message(e)
      Threadline.Telemetry.emit_health_checked_error(message)

      previous = socket.assigns[:coverage_for_schema]
      previous_schema = socket.assigns[:coverage_for_schema_name]

      snapshot =
        case {previous_schema, previous} do
          {^schema, %Snapshot{last_checked_at: %DateTime{}} = last_good} ->
            %{last_good | error: message}

          _ ->
            %{Snapshot.empty(nil) | error: message}
        end

      socket
      |> assign(:coverage_for_schema, snapshot)
      |> assign(:coverage_for_schema_name, schema)
  end
end
```

### CR-02: Schema list/validation failures can crash `/audit/coverage`

**Classification:** BLOCKER
**File:** `lib/threadline/operator_surface/live/coverage_live.ex:46`
**Issue:** `handle_params/3` calls `available_schemas(socket)` before any rescue, and then calls `validate_schema/2`; both helpers call `Ecto.Adapters.SQL.query!/3` through `CoverageSchemas`. A transient database/catalog error or missing repo raises out of `handle_params/3`, so the LiveView crashes before it can render the unavailable/stale/error posture that the Coverage surface otherwise tries to support.
**Fix:**
```elixir
def handle_params(params, uri, socket) do
  # ...
  with {:ok, schemas} <- safe_available_schemas(socket),
       {:ok, schema} <- safe_validate_schema(socket, schema_param) do
    {:noreply,
     socket
     |> assign(:schema_param, schema)
     |> assign(:available_schemas, schemas)
     |> assign(:form_error, nil)
     |> fetch_coverage_for_schema(schema)}
  else
    {:error, message, schemas} ->
      {:noreply,
       socket
       |> assign(:schema_param, schema_param)
       |> assign(:available_schemas, schemas)
       |> assign(:coverage_for_schema, %{Snapshot.empty(nil) | error: message})
       |> assign(:form_error, message)}
  end
end

defp safe_available_schemas(socket) do
  {:ok, available_schemas(socket)}
rescue
  e -> {:error, Exception.message(e), ["public"]}
end
```

## Warnings

### WR-01: Refresh bypasses the schema validation boundary

**Classification:** WARNING
**File:** `lib/threadline/operator_surface/live/coverage_live.ex:97`
**Issue:** Manual refresh sends `socket.assigns[:schema_param]` directly to `fetch_coverage_for_schema/2`. If the current URL is invalid and `@form_error` is set, the refresh button still exists and can pass that untrusted value into `Threadline.Health.trigger_coverage/1`, even though `CoverageSchemas` explicitly documents that LiveView surfaces must validate user-provided schemas before calling the trusted programmatic API.
**Fix:** Disable refresh while `@form_error` is set, or re-run `validate_schema/2` in the refresh handler before calling `fetch_coverage_for_schema/2`.

### WR-02: Stale/invalid contract tests are source-grep checks, not behavior guards

**Classification:** WARNING
**File:** `test/threadline/operator_surface/coverage_doc_contract_test.exs:144`
**Issue:** The test named "invalid-schema recovery without stale selected-schema data" only checks for source substrings like `"Use public schema"` and refutes the literal text `"stale public data"`. The "preserves last-good checked_at" test likewise checks for `%{previous | error: message}` in source. These tests would pass with CR-01 present, so they give false confidence on the most important Phase 185 stale-data invariant.
**Fix:** Add LiveView behavior tests that force `trigger_coverage/1` to fail after a schema switch and after a same-schema refresh. Assert that same-schema refresh preserves last-good rows/timestamp, while cross-schema or first-load failures do not render rows/counts from the prior schema.

### WR-03: Operator docs still use retired dashboard/table-coverage framing

**Classification:** WARNING
**File:** `guides/operator-surface.md:264`
**Issue:** The docs table still describes `/audit/coverage` as "Which tables are covered right now?", and later says expected-uncovered config makes "the dashboard" show rows as expected. `guides/production-checklist.md:29` also describes polling failures as "freezing the dashboard." This conflicts with Phase 185's selected-schema audit-readiness posture and can keep downstream docs/tests anchored to the old dashboard framing.
**Fix:** Rewrite these remaining references around "Can operators rely on audit history for the selected schema?" and "readiness verdict / expected gaps" language. Extend `coverage_doc_contract_test.exs` to refute generic `dashboard` wording in the Coverage sections, not just the exact phrase `"Coverage dashboard responds"`.

### WR-04: Browser focus proof forces focus programmatically

**Classification:** WARNING
**File:** `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts:46`
**Issue:** `expectKeyboardFocus/2` presses Tab, then immediately calls `locator.focus()` before asserting focus styling. That can pass even when the control is not reachable in the natural tab order, weakening the Phase 185 accessibility proof for schema select, refresh, row disclosure, copy, and Timeline links.
**Fix:** Drive focus through keyboard navigation and assert the expected element receives focus without calling `locator.focus()`. If the sequence is long, write a helper that tabs until a selector is active with a small max-step guard.

---

_Reviewed: 2026-06-29T20:34:29Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
