---
phase: 61-row-history-and-as-of-sub-view
plan: 01
status: complete
---

## Execution Summary

- Mapped the `:history` live route in the operator surface router.
- Extracted `:threadline_schemas` in the auth pipeline to map table strings to Ecto schema modules.
- Wired the transaction drill-down view (`TransactionLive`) to handle `:history` parameters and conditionally render the row history sub-view.
- Added a click-to-scrub history link to the change rows in the transaction view.
- Implemented `RowHistoryComponent` to fetch row history (`Threadline.history/3`) and 'as-of' snapshots (`Threadline.as_of/4`), displaying them in a slide-over panel.
- Handled gracefully the case where a table string in the URL does not map to a configured Ecto schema.
- Addressed testing by ensuring clean component fallbacks and testing parent liveview mounting states. All tests pass successfully.
