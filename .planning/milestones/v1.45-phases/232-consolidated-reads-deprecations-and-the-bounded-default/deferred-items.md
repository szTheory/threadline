# Deferred Items — Phase 232

## From 232-01

- status: resolved

- **RESOLVED in 232-06.** `test/threadline/audit_indexing_doc_contract_test.exs`
  asserted `guides/audit-indexing.md` contains the heading `## Timeline and Threadline.Query`, but the
  guide (last touched in Phase 231's facade-hiding commit `d1609504`) has `## Timeline and
  Threadline.timeline/2`. Confirmed via `git show 30016de7:...` that this mismatch predates Plan 232-01
  entirely — neither file was in that plan's `files_modified` list and neither was touched by it.
  232-06 reconciled it in the facade-only direction (the guide must not re-name the hidden
  `Threadline.Query` module): the test's expected heading was updated to
  `## Timeline and Threadline.timeline/2` to match the guide. `guides/audit-indexing.md` is in
  232-06's `files_modified` list.
