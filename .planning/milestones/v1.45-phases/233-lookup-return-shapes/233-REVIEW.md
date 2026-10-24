---
phase: 233-lookup-return-shapes
reviewed: 2026-10-03T00:00:00Z
depth: standard
files_reviewed: 28
files_reviewed_list:
  - CHANGELOG.md
  - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
  - guides/code-walkthrough.md
  - guides/domain-reference.md
  - guides/getting-started-saas.md
  - guides/integration-contracts.md
  - lib/threadline.ex
  - lib/threadline/investigation.ex
  - lib/threadline/not_found_error.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/query.ex
  - lib/threadline/query/scope.ex
  - lib/threadline/query/transaction_lookup.ex
  - mix.exs
  - test/partition_weights.txt
  - test/threadline/deprecation_parity_test.exs
  - test/threadline/investigation_test.exs
  - test/threadline/lookup_return_shapes_contract_test.exs
  - test/threadline/not_found_error_test.exs
  - test/threadline/operator_surface/controllers/export_controller_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
  - test/threadline/operator_surface/transaction_live_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/query/action_hydration_test.exs
  - test/threadline/query/scope_fail_closed_test.exs
  - test/threadline/query_test.exs
  - test/threadline/storage_schema_integration_test.exs
  - test/threadline/transaction_lookup_test.exs
findings:
  critical: 0
  warning: 1
  info: 1
  total: 2
status: issues_found
---

# Phase 233: Code Review Report

**Reviewed:** 2026-10-03
**Depth:** standard
**Files Reviewed:** 28
**Status:** issues_found

## Summary

Reviewed the diff since `dd645b96^` against the locked decisions in
`233-CONTEXT.md` (D-01 through D-22). The implementation is unusually
disciplined: every tenant-scope-leak concern the brief called out —
existence vs. scope-filtered indistinguishability, exception messages,
option allowlists, fail-open scoping paths — is independently proven by a
test, and I traced each through the actual code rather than taking the test
suite's word for it:

- `Threadline.Query.Scope.apply/2` (`lib/threadline/query/scope.ex`) matches
  D-20 exactly: a non-nil `:scope` with no usable 3-arity `:scope_query_fn`
  raises before looking at the scope value at all (so the `ArgumentError`
  message can never echo scope contents — confirmed against
  `test/threadline/query/scope_fail_closed_test.exs`'s
  `refute error.message =~ "tenant-secret-7"`); a `nil` scope stays unscoped
  and never invokes the configured fn, matching the documented "host's
  explicit unscoped authorization" carve-out.
- `Threadline.Query.TransactionLookup.fetch_row/2` and `fetch/2` decide
  existence once, by the scoped row, and a scope-rejected row produces the
  byte-identical `NotFoundError` message as a genuinely missing row
  (verified in `transaction_lookup_test.exs`'s "scope parity across lookups"
  and the dedicated byte-equality assertion in the `!` test) — no
  distinguishing wording leaks tenant-boundary information.
  `surface: :transaction_header` with a single `[at]` binding is
  hardcoded (never read from caller `opts`), closing the D-10 latent bug
  where a two-binding adopter scope fn would either crash on
  `unknown_binding_1!` or, worse under a permissive catch-all, return
  another tenant's row.
- The option allowlist (`@lookup_opt_keys`) rejects `:surface`, `:params`,
  and `:preload` on all three lookups and their bangs, closing the exact
  surface-relabeling and unscoped-preload holes D-13 names.
- `examples/.../router.ex`'s `scope_operator_query/3` ends in a deny-all
  catch-all (`where(query, [], false)`) rather than a permissive one, and
  has an explicit `:transaction_header` clause — matching the guide's
  warning in `guides/integration-contracts.md` almost verbatim.
- CHANGELOG `Unreleased` breaking-change entries were cross-checked
  sentence-by-sentence against the code and match (return shapes, option
  allowlist, scope fail-closed behavior, and the un-hydrated `.action`
  becoming `nil`).
- `mix compile --warnings-as-errors` is clean.

Two lower-severity items below are worth a look, but neither is a
correctness or security defect in what shipped.

## Warnings

### WR-01: A malformed binary id silently short-circuits a missing `:repo`, giving an inconsistent failure mode

**File:** `lib/threadline/query/transaction_lookup.ex:97-111`
**Issue:** `fetch_row/2` calls `resolve_id(id)` first and returns `:not_found`
immediately when the binary fails `Ecto.UUID.cast/1` — before ever reaching
`Keyword.fetch!(opts, :repo)`. Every lookup's `@doc` and the CHANGELOG state
`:repo` is a required option ("`:repo` — required `Ecto.Repo` module"), and
for a well-formed-but-missing UUID the code does enforce that (`fetch_row/2`
raises `KeyError` via `Keyword.fetch!/2` if `:repo` is absent). But for a
malformed id (e.g. `"garbage"`), a caller who forgot `:repo` entirely gets
`{:error, :not_found}` instead of a loud error about the missing option —
the same input shape (a caller mistake) resolves to two different failure
modes depending on what string happens to be in the id. This is a narrow
gap, not a scope leak (no row data is involved either way), but it is an
inconsistency relative to this codebase's stated preference for failing
loud on misconfiguration (D-15's "do not rescue a misconfiguration into
`:not_found`" principle, applied here to a different option than the one
D-15 names).
**Fix:** Either validate `:repo` presence unconditionally at the top of
`fetch_row/2` (and `fetch/2`) before calling `resolve_id/1`, or explicitly
document that a malformed id short-circuits before option validation so the
asymmetry is intentional rather than incidental:
```elixir
def fetch_row(id, opts) when is_list(opts) do
  _repo = Keyword.fetch!(opts, :repo)  # fail loud regardless of id shape

  case resolve_id(id) do
    :not_found -> :not_found
    {:ok, uuid} -> ...
  end
end
```

## Info

### IN-01: `Threadline.NotFoundError.message/1` pattern-matches a bare map, not the exception struct

**File:** `lib/threadline/not_found_error.ex:25`
**Issue:** `def message(%{resource: resource, id: id})` matches on a map
shape rather than `%__MODULE__{}`. Since Elixir structs are maps, this works
correctly for the real exception, but the clause head would also match any
other map with `:resource` and `:id` keys passed to `Exception.message/1`
(not a realistic call path here, since `message/1` is only invoked by the
`Exception` protocol on an actual `%Threadline.NotFoundError{}`). This
mirrors the exact sketch given in the phase's `233-CONTEXT.md`
`<specifics>` block, so it is a deliberate choice, not an oversight — noting
it only because a `%__MODULE__{resource: resource, id: id}` match would be
marginally tighter and self-documenting for future maintainers who don't
have the context doc open.
**Fix:** Optional: `def message(%__MODULE__{resource: resource, id: id})`.

---

_Reviewed: 2026-10-03_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
