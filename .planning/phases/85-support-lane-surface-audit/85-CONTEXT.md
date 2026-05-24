# Phase 85 Context: Support Lane Surface Audit & Claim Lock

## Surface Audit Lock

The v1.21 milestone explicitly claims support-lane safety for the following views:
- Timeline
- Actor
- Transaction
- Row History (and As-Of)

**Crucially, no existing UI components will be disabled for support agents.** The `RowHistoryComponent` will be safely scoped. We will push `scope_query_fn` into the core query APIs (`Threadline.history/3` and `Threadline.as_of/4`), matching the pattern established for TimelineLive.

## Packaging and Scope Guard (Support Matrix Lock)

Threadline provides safe UI exploration out of the box (`scope_query_fn`), but treats bulk data exfiltration as a separate, opt-in privilege. 

The documentation and integration recipes must teach the following "scope guard":
- `exports: false` is the **default posture** for support-scoped users.
- An explicit `export_authorize_fn` is required to override this and permit bulk data exports.
