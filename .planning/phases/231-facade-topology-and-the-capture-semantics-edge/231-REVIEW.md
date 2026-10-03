---
phase: 231-facade-topology-and-the-capture-semantics-edge
reviewed: 2026-10-03T00:00:00Z
depth: standard
files_reviewed: 25
files_reviewed_list:
  - CHANGELOG.md
  - examples/threadline_phoenix/priv/scripts/incident_replay.exs
  - guides/audit-indexing.md
  - guides/code-walkthrough.md
  - guides/domain-reference.md
  - guides/how-threadline-works.md
  - guides/production-checklist.md
  - lib/threadline.ex
  - lib/threadline/audit.ex
  - lib/threadline/capture/audit_transaction.ex
  - lib/threadline/export.ex
  - lib/threadline/investigation.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/query.ex
  - lib/threadline/query/action_hydration.ex
  - lib/threadline/retention.ex
  - lib/threadline/semantics/audit_action.ex
  - mix.exs
  - test/threadline/capture_semantics_boundary_test.exs
  - test/threadline/facade_only_references_contract_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/query/action_hydration_test.exs
  - test/threadline/query_test.exs
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Phase 231: Code Review Report

**Reviewed:** 2026-10-03T00:00:00Z
**Depth:** standard
**Files Reviewed:** 25
**Status:** issues_found

## Summary

This phase (1) removes the `belongs_to :action` / `has_many :transactions` Ecto
associations between `Threadline.Capture.AuditTransaction` and
`Threadline.Semantics.AuditAction`, replacing them with a virtual `:action`
field hydrated by a new hidden `Threadline.Query.ActionHydration` module, and
(2) hides `Threadline.Query` / `Threadline.Investigation` behind the
`Threadline` facade, backed by a new `facade_only_references_contract_test.exs`
regression guard over guides/README/example-app source.

The core mechanism (`hydrate_actions/3`, the `:preload` deprecation shims,
the capture/semantics schema split) is implemented carefully, is well tested
(`action_hydration_test.exs`, `capture_semantics_boundary_test.exs`), and the
call sites in `Threadline.Query`, `Threadline.Investigation`,
`timeline_live.ex`, and `transaction_live.ex` were all updated consistently —
I traced every call site that previously relied on the removed associations
and found none left over (confirmed via `test/threadline/query_test.exs` and
`test/threadline/operator_surface/live/timeline_live_test.exs` source-pinning
assertions, which were updated in lockstep).

Two issues stood out on closer inspection: a leftover plain-text mention of
the now-hidden `Threadline.Query` module in `guides/audit-indexing.md` that
slips past the new regression guard's regexes (defeating this phase's own
stated goal for that specific line), and a `Threadline` moduledoc list of
"supported read API" functions that omits roughly half of the module's
actual public functions. Neither is a runtime defect, but both directly
concern the facade-topology contract this phase exists to establish.

## Warnings

### WR-01: `guides/audit-indexing.md` still names the hidden `Threadline.Query` module, undetected by the new facade-only guard

**File:** `guides/audit-indexing.md:44`
**Issue:** The phase's stated goal (231-CONTEXT.md D-12/SC2, restated in the
moduledoc of `test/threadline/facade_only_references_contract_test.exs`) is
that guides must call the `Threadline` facade and never reference the hidden
`Threadline.Query` / `Threadline.Investigation` modules directly, except the
one documented escape hatch. Every other reference to `Threadline.Query` in
this guide was rewritten to `Threadline.timeline/2` / `Threadline.timeline_page/2`
in this same diff — except this one:

```
## Timeline and Threadline.Query
```

This heading still names the hidden module. It survives
`facade_only_references_contract_test.exs`'s "reports zero facade-only
offenders" test because none of that test's three detection regexes
(`@backtick_regex`, `@call_regex`, `@bare_alias_regex`) match a bare
mid-sentence/heading mention of a module name with no trailing arity, no
call-parens, and no `alias` keyword. The guard itself therefore has a
detection gap in addition to the doc having drifted.

**Fix:** Rename the heading to match the rest of the section (e.g. `## Timeline
and Threadline.timeline/2`), and consider extending the contract test with a
fourth regex that catches a bare `Threadline.Query` / `Threadline.Investigation`
module-name mention with no following `.function(...)` or arity, so this class
of drift is caught mechanically in the future:

```elixir
# catches a bare module mention that isn't a `Module.fun(...)` call,
# `` `Module.fun/N` `` backtick reference, or `alias Module` — e.g. a heading
# or prose sentence that just names the hidden module.
@bare_module_mention_regex ~r/\bThreadline\.(?:Query|Investigation)\b(?!\.\w|\s*\()/
```

### WR-02: `Threadline` moduledoc's "supported read API" list omits most of the module's actual public read functions

**File:** `lib/threadline.ex:10-13`
**Issue:** This phase's moduledoc update states:

```
The functions on this module are the supported read API: `timeline/2`,
`history/3`, `row_history/4`, `actor_window/3`, `incident_bundle/2`,
`audit_changes_for_transaction/2`, `export_csv/2`, and `export_json/2`. Build
on these rather than on the internal modules behind them.
```

But `Threadline` also publicly exports `as_of/4`, `actor_history/2`,
`timeline_page/2`, `row_history_page/4`, `actor_window_page/3`,
`correlation_bundle/3`, `correlation_bundle_page/3`, and
`transaction_context/2` — none of which are mentioned in this list. Since this
phase's whole point is establishing the `Threadline` facade as *the* supported
surface (replacing direct references to the now-hidden `Query`/`Investigation`
modules), an incomplete enumeration of that surface in the facade's own
moduledoc is misleading to adopters trying to learn what "the supported read
API" actually is — it reads as if half the public functions are either
internal-only or deliberately unlisted, when they are not.
**Fix:** Either list every public read function, or drop the closed-looking
enumeration in favor of language that doesn't imply completeness, e.g.:

```
The functions on this module are the supported read API (see the function
list below). Build on these rather than on the internal modules behind them.
```

## Info

### IN-01: `incident_replay.exs` duplicates `audit_transactions` table access via raw SQL instead of a facade helper

**File:** `examples/threadline_phoenix/priv/scripts/incident_replay.exs:139-151,165-169`
**Issue:** `scenario_service_account/0` and `scenario_oban_job/0` query
`audit_transactions` directly via `Ecto.Adapters.SQL.query!/3` with
hand-built `WHERE actor_ref->>'id' = ...` SQL, duplicating logic that
`Threadline.actor_history/2` already provides (and which this same script
uses correctly for `Threadline.history/3` in `scenario_who_changed_row/0`).
This file is in the facade-only-references contract's scope globs and would
not trip that guard either way, since it isn't referencing
`Threadline.Query`/`Threadline.Investigation` — it is simply not using the
facade at all for two of its three scenarios, which undercuts the file's own
purpose as an example of idiomatic facade usage for adopters to copy from.
**Fix:** Replace the raw SQL in `scenario_service_account/0` /
`scenario_oban_job/0` with `Threadline.actor_history/2` (or
`Threadline.timeline/2` with `:actor_ref`) so the example consistently
demonstrates the supported read API.

---

_Reviewed: 2026-10-03T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
