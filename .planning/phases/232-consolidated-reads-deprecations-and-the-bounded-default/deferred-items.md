# Deferred Items — Phase 232

## From 232-01

- **Pre-existing failing test, out of scope.** `test/threadline/audit_indexing_doc_contract_test.exs`
  asserts `guides/audit-indexing.md` contains the heading `## Timeline and Threadline.Query`, but the
  guide (last touched in Phase 231's facade-hiding commit `d1609504`) has `## Timeline and
  Threadline.timeline/2`. Confirmed via `git show 30016de7:...` that this mismatch predates Plan 232-01
  entirely — neither file is in this plan's `files_modified` list and neither was touched by this plan.
  Not fixed here (scope boundary). Someone updating that guide/test pair should reconcile the heading.
