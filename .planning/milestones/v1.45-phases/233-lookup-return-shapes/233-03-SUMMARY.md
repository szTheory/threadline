---
phase: 233-lookup-return-shapes
plan: 03
subsystem: api
tags: [ecto, elixir, deprecation, changelog, docs]

requires:
  - phase: 233-lookup-return-shapes
    provides: "Plan 01/02's Threadline.Query.TransactionLookup (validate_opts!/2, resolve_id/1, fetch_row/2, fetch/2) and the final audit_transaction/2,!/2, transaction_context/2,!/2, incident_bundle/2,!/2 facade specs"
provides:
  - "Threadline.Query.audit_transaction/2 as a pinned, parity-tested @deprecated delegate that reads through the shared TransactionLookup.scoped_row/4 while keeping its 0.12 contract (nil, ArgumentError on malformed id, :preload :action with its own warning)"
  - "test/threadline/lookup_return_shapes_contract_test.exs: a doc-contract test pinning the lookup family's names/docs/specs in both directions, with an explicit as_of/4 exemption"
  - "CHANGELOG Unreleased entries: two Breaking-changes bullets (transaction_context/2 tuple shape, shared option allowlist), one merged Deprecations bullet for Query.audit_transaction/2, one Added bullet for the NotFoundError-raising bangs"
  - "Rewritten guide excerpts (code-walkthrough section 13, getting-started-saas and domain-reference building-blocks paragraphs) showing the current tuple/bang shapes instead of the retired Query.audit_transaction source"
affects: [233-04-fail-closed-scope]

actuals:
  tokens: 6651
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Deprecated delegate reads through the same shared row-first helper as the new facade (TransactionLookup.scoped_row/4) instead of duplicating query logic, so the 0.12 contract and the 0.13 contract can never silently drift apart."
    - "Doc-contract test enforces the bang-naming convention bidirectionally: every `!`-suffixed export must have a plain sibling in the pinned @lookups list, and every spec mentioning :not_found must be in that list — new lookups can't slip through with no doc contract, and the list can't silently grow without a bidirectional check catching it."
    - "as_of/4's lack of a `!` sibling is pinned as an explicit, reasoned exemption (not an oversight) — its {:error, :deleted_record} / {:error, :before_audit_horizon} results are outcomes callers branch on, not an absence-is-a-bug case."

key-files:
  modified:
    - lib/threadline/query.ex
    - lib/threadline/query/transaction_lookup.ex
    - lib/threadline.ex
    - test/threadline/deprecation_parity_test.exs
    - test/threadline/query/action_hydration_test.exs
    - test/partition_weights.txt
    - CHANGELOG.md
    - guides/code-walkthrough.md
    - guides/getting-started-saas.md
    - guides/domain-reference.md
  created:
    - test/threadline/lookup_return_shapes_contract_test.exs

key-decisions:
  - "The deprecated Query.audit_transaction/2 keeps its 0.12 surface default (:transaction) and caller :surface override by reading through TransactionLookup.scoped_row(uuid, transaction_id, Keyword.get(opts, :surface, :transaction), opts) rather than hardcoding :transaction_header — an adopter scope fn written against 0.12 sees exactly what it saw before upgrading (T-233-10)."
  - "CHANGELOG Deprecations: the old single bullet describing :preload :action for both Query.audit_transaction/2 and Query.audit_changes_for_transaction/2 was split so Query.audit_transaction/2 gets its own full deprecation bullet (naming the replacement, removal floor, and that :preload still works) and the surviving sentence for audit_changes_for_transaction/2's :action preload stays separate (D-06 merge requirement: the function is described once)."
  - "guides/code-walkthrough.md section 13 now quotes incident_bundle/2's exact current body (TransactionLookup.validate_opts!/2 + TransactionLookup.fetch/2) rather than paraphrasing, so the guide and the source can never visibly diverge — verified byte-for-byte against lib/threadline/investigation.ex before committing."
  - "No changes were needed to README.md, guides/incident-playbook.md, guides/how-threadline-works.md, guides/operator-surface.md, or the example app — none of them show a bare-struct return or a retired option key; they already use the {:ok, bundle} = idiom or the already-correct :transaction_header scope clause."

requirements-completed: [API-06]

coverage:
  - id: D1
    description: "Threadline.Query.audit_transaction/2 is a pinned, parity-tested @deprecated delegate sharing TransactionLookup.scoped_row/4 with the facade, keeping its 0.12 nil/raise/:preload contract"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/deprecation_parity_test.exs#Threadline.Query.audit_transaction/2 parity"
        status: pass
      - kind: unit
        ref: "test/threadline/query/action_hydration_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "A doc-contract test pins the lookup family's exported names, doc first-lines, and specs bidirectionally, with an explicit as_of/4 exemption"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/lookup_return_shapes_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "CHANGELOG Unreleased records both breaking changes (transaction_context/2 tuple shape, shared option allowlist), the merged Query.audit_transaction/2 deprecation, and the NotFoundError Added bullet"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs"
        status: pass
      - kind: other
        ref: "bash -c 'test \"$(grep -c \"Threadline.Query.audit_transaction/2\" CHANGELOG.md)\" -ge 1 && grep -q \"%LinkedTransaction{transaction: nil}\" CHANGELOG.md && grep -q \"transaction_context!/2\" CHANGELOG.md'"
        status: pass
    human_judgment: false
  - id: D4
    description: "Every guide, README and example-app reference to the three lookups shows the current tuple/bang shapes; no guide quotes the retired Query.audit_transaction source"
    requirement: API-06
    verification:
      - kind: unit
        ref: "test/threadline/code_walkthrough_doc_contract_test.exs, test/threadline/getting_started_saas_doc_contract_test.exs, test/threadline/exploration_routing_doc_contract_test.exs, test/threadline/facade_only_references_contract_test.exs, test/threadline/readme_doc_contract_test.exs, test/threadline/public_surface_contract_test.exs"
        status: pass
      - kind: other
        ref: "bash -c '! grep -rn \"Query.audit_transaction\" guides README.md examples/threadline_phoenix/README.md'"
        status: pass
    human_judgment: false

duration: ~45min (continuation; Tasks 1-2 executed in a prior stalled session)
completed: 2026-10-03
status: complete
---

# Phase 233 Plan 03: CHANGELOG, Doc Contract and Deprecated Delegate for the Lookup Family Summary

**Query.audit_transaction/2 retired behind a parity-tested @deprecated delegate sharing the facade's row-first read; a bidirectional doc-contract test pins all three lookups plus an explicit as_of/4 exemption; CHANGELOG and every guide now describe the tuple/bang shapes.**

## Performance

- **Duration:** ~45 min total across two sessions (Tasks 1-2 by an earlier executor that stalled before committing Task 3; this continuation verified Tasks 1-2, completed and committed Task 3, and wrote this SUMMARY)
- **Tasks:** 3/3
- **Files modified:** 10, created: 1

## Accomplishments

- `Threadline.Query.audit_transaction/2` is now `@deprecated "Use Threadline.audit_transaction/2 instead."`, reads through the new `Threadline.Query.TransactionLookup.scoped_row/4` (shared with the facade), and is proven byte-for-byte parity-equivalent to its 0.12 behavior (nil on missing, raises `ArgumentError` on a malformed id, `:preload :action` still hydrates and still warns) via `apply/3`-only test calls.
- `Threadline.Query.__info__(:deprecated)` inventory is pinned exactly, including the new entry; a mutation-control run (deleting the `@deprecated` line) was reconfirmed red during this continuation, then restored and reconfirmed green.
- `test/threadline/lookup_return_shapes_contract_test.exs` pins `audit_transaction/2`, `transaction_context/2`, `incident_bundle/2` and their `!` siblings bidirectionally (exported names, doc first-lines, specs mentioning `:not_found`) with `as_of/4` named as an explicit, reasoned exemption. A mutation-control run (removing the `incident_bundle!/2` doc link) was reconfirmed red during this continuation, then restored and reconfirmed green.
- CHANGELOG `Unreleased` now carries two new Breaking-changes bullets (the `transaction_context/2` tuple shape with a before/after snippet, and the shared `:repo`/`:storage_schema`/`:scope`/`:scope_query_fn` option allowlist for all three lookups and their bangs), one merged Deprecations bullet for `Query.audit_transaction/2`, and one Added bullet naming the `NotFoundError`-raising bangs (`Plug.Exception`, status 404) — the last of these was missing when this continuation started and was added to close the plan's acceptance criteria.
- `guides/code-walkthrough.md` section 13 now quotes the current `incident_bundle/2` body (`TransactionLookup.validate_opts!/2` + `TransactionLookup.fetch/2`) instead of the retired `Query.audit_transaction` source; `guides/getting-started-saas.md` and `guides/domain-reference.md` note the `{:ok, _} | {:error, :not_found}` shape of `transaction_context/2` and point to `audit_transaction/2` for the bare row.

## Task Commits

1. **Task 1: Tracer — deprecate Threadline.Query.audit_transaction/2 onto the shared scoped row read** - `c8f53f8b` (feat)
2. **Task 2: Lookup-family doc contract with the as_of/4 exemption** - `7a494d03` (test)
3. **Task 3: CHANGELOG entries and guide rewrites** - `04302cad` (docs)

**Plan metadata:** pending (this SUMMARY's commit)

## Files Created/Modified

- `lib/threadline/query/transaction_lookup.ex` - extracted `scoped_row/4` (hidden), the shared row query the deprecated delegate and `fetch_row/2` both call
- `lib/threadline/query.ex` - `@deprecated` attribute + doc update on `audit_transaction/2`; body now reads through `TransactionLookup.scoped_row/4`
- `lib/threadline.ex` - `as_of/4` doc paragraph stating its lack of a `!` sibling is intentional
- `test/threadline/deprecation_parity_test.exs` - `@query_deprecated` inventory entry + parity describe block for `audit_transaction/2`, all through `apply/3`
- `test/threadline/query/action_hydration_test.exs` - four direct `Query.audit_transaction(` calls replaced with `apply(Query, :audit_transaction, [...])`
- `test/threadline/lookup_return_shapes_contract_test.exs` (new) - the bidirectional doc/spec contract for the lookup family, with the `as_of/4` exemption
- `test/partition_weights.txt` - weight entry for the new contract test
- `CHANGELOG.md` - two Breaking-changes bullets, merged Deprecations bullet, Added bullet
- `guides/code-walkthrough.md` - section 13 rewritten to quote current source
- `guides/getting-started-saas.md`, `guides/domain-reference.md` - building-blocks paragraphs updated with tuple/bang shapes

## Decisions Made

- The deprecated `Query.audit_transaction/2` keeps its 0.12 `:surface` default (`:transaction`) and caller override, reading through `TransactionLookup.scoped_row(uuid, transaction_id, Keyword.get(opts, :surface, :transaction), opts)` rather than hardcoding `:transaction_header` — an adopter scope fn written against 0.12 sees the same surface value after upgrading (T-233-10, information-disclosure mitigation).
- CHANGELOG Deprecations: `Query.audit_transaction/2` now has its own full bullet instead of sharing one with `audit_changes_for_transaction/2`'s `:preload :action` sentence, satisfying D-06's "described once" requirement while keeping the surviving `audit_changes_for_transaction/2` sentence intact.
- `guides/code-walkthrough.md` section 13 quotes `incident_bundle/2`'s exact current body rather than paraphrasing — verified line-for-line against `lib/threadline/investigation.ex` before committing, so the guide cannot silently drift from the source.
- No changes were needed in `README.md`, `guides/incident-playbook.md`, `guides/how-threadline-works.md`, `guides/operator-surface.md`, or the example app (grepped per the plan's step 0 instruction) — none show a bare-struct return, a retired option key, or a call to the deprecated `Query.audit_transaction/2`; they already use the `{:ok, bundle} =` idiom or the already-correct `:transaction_header` scope clause.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Completed the missing CHANGELOG Added bullet left by the stalled prior session**
- **Found during:** Task 3 continuation review
- **Issue:** The prior executor's uncommitted working-tree edits had written both Breaking-changes bullets and the merged Deprecations bullet, but the plan's required Added bullet (`Threadline.audit_transaction/2` and the three `!` siblings raising `Threadline.NotFoundError`, `Plug.Exception` status 404) was not yet present — the executor's last note ("Now update Deprecations (merge) and Added sections") confirmed Added was still outstanding.
- **Fix:** Added the bullet to `CHANGELOG.md`'s `### Added` section in the `Unreleased` block, matching the plan's required wording.
- **Files modified:** CHANGELOG.md
- **Verification:** `mix test test/threadline/changelog_contract_test.exs` passes; the three Task-3 `<verify>` commands (doc-contract suite, guide/README grep, CHANGELOG phrase grep) all exit 0.
- **Committed in:** 04302cad (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking — completing an unfinished edit)
**Impact on plan:** No scope creep; this closes a gap the plan's acceptance criteria already required.

## Issues Encountered

- The previous executor for this plan stalled mid-Task-3 with uncommitted edits to all four Task-3 files and no SUMMARY. This continuation verified Tasks 1 and 2's commits existed and were correct (re-ran both tasks' mutation controls independently to confirm the pins hold, since no prior SUMMARY recorded them), reviewed the uncommitted Task-3 diff against the plan's acceptance criteria, completed the one missing CHANGELOG bullet, ran the full Task-3 verification suite plus `mix compile --warnings-as-errors`, `mix verify.credo`, `MIX_ENV=dev mix docs --warnings-as-errors`, and the full `mix test --warnings-as-errors` (2928 tests, 0 failures), then committed.
- The per-plan commit ledger (`gsd-plan-head-before-233-03`) was never written by the prior session (it should have been created before Task 1's first commit). This continuation reconstructed it from the commit immediately preceding Task 1 (`6dda9bc2`, the final 233-02 commit) so `commits:` in this SUMMARY's frontmatter is measured, not narrated.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `Threadline.Query.audit_transaction/2` is fully retired behind a pinned, parity-tested deprecation; nothing in `lib/` calls it directly.
- The lookup family (`audit_transaction`, `transaction_context`, `incident_bundle`, their bangs, and the `as_of/4` exemption) is enforced by a weighted doc-contract test, not memory.
- CHANGELOG and every guide reference the current tuple/bang shapes; no outstanding guide debt for this plan.
- Ready for 233-04 (fail-closed scope), which the CHANGELOG's `:scope_query_fn` allowlist bullet already anticipates (`T-233-11`: full guide prose for the `:transaction_header` scope clause lands with that plan).

---
*Phase: 233-lookup-return-shapes*
*Completed: 2026-10-03*

## Self-Check: PASSED

All 11 claimed files found on disk; all 3 claimed commit hashes (c8f53f8b, 7a494d03, 04302cad) found in git history.
