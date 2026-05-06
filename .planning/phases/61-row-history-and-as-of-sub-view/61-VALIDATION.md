# Phase 61: Row History and As-Of Sub-View - Validation Plan

## Goal
Verify the successful implementation of the Row History and As-Of Sub-View, ensuring that routing, data fetching, optional dependencies, and schema mappings all function correctly.

## Test Matrix

| Feature | Test File | Type | Coverage Required |
|---------|-----------|------|-------------------|
| Sub-view Routing & Schema Config | `test/threadline/operator_surface/transaction_live_test.exs` | Unit / Integration | Verifies the `:history` live route parses URL parameters correctly and applies `threadline_schemas`. |
| Sub-view Data Fetching & UI | `test/threadline/operator_surface/row_history_component_test.exs` | Component | Verifies that `RowHistoryComponent` resolves schemas properly, queries `Threadline.history` and `Threadline.as_of`, and updates the click-to-scrub timeline correctly. |

## Automated Verification

Run the full suite to verify regressions are not introduced, and specifically run the tests above:

```bash
mix test test/threadline/operator_surface/transaction_live_test.exs
mix test test/threadline/operator_surface/row_history_component_test.exs
```

## Security & Optional Dependency Verification

- **Module Gating:** Confirm that `RowHistoryComponent` is wrapped in `if Code.ensure_loaded?(Phoenix.LiveView) do` to maintain the optional dependency contract.
- **Threat Mitigation:** Validate that an invalid `table` passed in the URL results in a safe error state and does not map to arbitrary internal Ecto schemas.