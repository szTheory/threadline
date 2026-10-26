---
phase: 228-telemetry
reviewed: 2026-10-02T00:00:00Z
depth: standard
files_reviewed: 24
files_reviewed_list:
  - CHANGELOG.md
  - README.md
  - guides/operator-surface.md
  - guides/telemetry.md
  - lib/threadline/export.ex
  - lib/threadline/export/orchestrator.ex
  - lib/threadline/operator_surface/auth.ex
  - lib/threadline/operator_surface/controllers/export_controller.ex
  - lib/threadline/operator_surface/coverage/on_mount.ex
  - lib/threadline/operator_surface/export_auth_plug.ex
  - lib/threadline/operator_surface/live/coverage_live.ex
  - lib/threadline/operator_surface/theme_auth_plug.ex
  - lib/threadline/retention.ex
  - lib/threadline/telemetry.ex
  - mix.exs
  - test/threadline/capture/redaction_leak_property_test.exs
  - test/threadline/export/orchestrator_test.exs
  - test/threadline/export_test.exs
  - test/threadline/guide_graph_contract_test.exs
  - test/threadline/operator_surface/auth_test.exs
  - test/threadline/operator_surface/export_controller_telemetry_test.exs
  - test/threadline/operator_surface/exports_doc_contract_test.exs
  - test/threadline/operator_surface/theme_auth_plug_test.exs
  - test/threadline/public_surface_contract_test.exs
  - test/threadline/retention_test.exs
  - test/threadline/telemetry_doc_contract_test.exs
  - test/threadline/telemetry_raising_handler_test.exs
  - test/threadline/telemetry_registry_contract_test.exs
  - test/threadline/telemetry_repo_query_recipe_test.exs
  - test/threadline/telemetry_test.exs
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Phase 228: Code Review Report

**Reviewed:** 2026-10-02
**Depth:** standard
**Files Reviewed:** 24 (source + test, excluding `.planning/`)
**Status:** issues_found

## Summary

Reviewed the telemetry-event build-out (new `[:threadline, :export, :*]` and
`[:threadline, :retention, :purge, *]`/`batch_purged` events, the
`actor_ref`/`session_actor_ref`/`scope_actor_ref` metadata removal, and the
`Threadline.Telemetry.emit_operator_surface_authorize/3` helper consolidation)
against the five stated priorities.

Traced `Threadline.Export.to_csv_iodata/2` and `to_json_document/2`'s
`rescue`/`reraise e, __STACKTRACE__` paths, `Threadline.Export.Orchestrator`'s
every `handle_transaction_result/4` and `compensate_failed_finalization/4`
branch, the chunked `send_chunked_stream/5` reduce_while (`:client_closed`
vs `:exception` vs normal completion), and `Threadline.Retention.purge/1`'s
`purge_span/2` wrapping. All four return-contract and re-raise requirements in
priority 1 hold: every Orchestrator failure branch returns `{:error, _}`,
`Retention.purge/1`'s dry-run/real agreement and `{:error, :disabled}`
short-circuit are unchanged, the eager export functions reraise the original
exception with its original stacktrace, and the chunked download's truncation
(`count > @max_rows`) and client-closed handling are unchanged apart from the
new telemetry emission wrapped around them.

Diffed `lib/threadline/operator_surface/auth.ex`,
`export_auth_plug.ex`, and `theme_auth_plug.ex` against their pre-change
(`3159f27a`) versions: the `authorize_fn`/`export_authorize_fn` decision
trees and conn/socket assignment logic are byte-for-byte unchanged; only the
telemetry call sites were swapped for the new shared helper. Auth decisions
are not affected by the helper move (priority 1, operator-surface auth
clause).

Confirmed emission is exactly-once per logical export across all three entry
points (eager iodata functions, `Orchestrator.run/2`, and the chunked
controller path) by reading every call site and the `orchestrator_test.exs` /
`export_controller_telemetry_test.exs` assertions that explicitly
`refute_receive` the sibling event. No Mix task references
`Threadline.Telemetry` (`mix/tasks/threadline.export.ex` has no telemetry
calls, and a dedicated static-scan test enforces this).

Found two WARNING-level documentation/contract-honesty gaps and one INFO item;
no BLOCKER-level regressions. The two warnings below are pre-existing (not
introduced by this diff — confirmed against the `3159f27a` baseline) but the
diff's own module-doc wording made the first one newly visible/unflagged, so
both are called out here for the maintainer to consciously accept or fix.

## Warnings

### WR-01: `Threadline.Telemetry`'s own moduledoc asserts a guarantee its own event table contradicts

**File:** `lib/threadline/telemetry.ex:5-10` (contradicted by the table row at `lib/threadline/telemetry.ex:26` and the `exempt_metadata` field at `lib/threadline/telemetry.ex:138`)

**Issue:** The moduledoc's opening sentence states unconditionally: *"No event
carries row values, actor identifiers, correlation ids, or free-text
reasons."* Four lines later, the same moduledoc's own event table lists
`[:threadline, :retention, :purge, :exception]` with metadata
`dry_run, kind, reason, stacktrace, telemetry_span_context` — and the
registry entry for that event explicitly carries an `exempt_metadata: [:kind,
:reason, :stacktrace]` field (acknowledging `reason`/`stacktrace` are NOT
held to the "no free-text" rule; a raised exception's message or stacktrace
frame can echo a captured row value). `guides/telemetry.md` is honest about
this — it has a dedicated caveat ("its `reason`/`stacktrace` metadata is
forwarded for incident diagnosis only — see Keep row data out of your
handlers before logging it anywhere durable") — but the module doc that
ships on HexDocs as the primary API reference for `Threadline.Telemetry`
does not carry that caveat anywhere near its absolute claim, so a reader who
only opens the module docs (rather than following the guide link) walks away
with a false guarantee.

This is pre-existing in spirit (the exemption itself is not new — it was
this phase's PR that introduced the retention span and its exemption), but
since this phase is precisely the one that added the `:exception` event and
wrote the "No event carries..." sentence in its current unconditional form
in the same commit series, the contradiction is new as of this diff.

**Fix:** Soften the opening sentence or add the same caveat inline, e.g.:

```elixir
No event carries row values, actor identifiers, correlation ids, or
free-text reasons — with one narrow exception: `[:threadline, :retention,
:purge, :exception]`'s `reason`/`stacktrace` metadata, forwarded verbatim
from a raised exception for incident diagnosis (see the Telemetry guide's
"Keep row data out of your handlers" section before logging it anywhere
durable).
```

### WR-02: `path` metadata on `[:threadline, :operator_surface, :authorize]` forwards the raw request path with no shape validation

**File:** `lib/threadline/telemetry.ex:250-251` (`authorize_path/1`), consumed by `lib/threadline/operator_surface/theme_auth_plug.ex:76`

**Issue:** `Threadline.Telemetry.emit_operator_surface_authorize/3` takes
`conn.request_path` verbatim as the `path` metadata value whenever a caller
passes a real `%Plug.Conn{}` (currently only `ThemeAuthPlug` does this;
`ExportAuthPlug` and `Auth.on_mount/4` always pass `nil`, so they get `""`
instead). `guides/telemetry.md`'s cardinality section and the module's
top-line claim both assert telemetry here carries no identifiers, but
`request_path` is whatever the host's router mounts — if a host app ever
nests the operator-surface theme route under a dynamic segment (e.g.
`/accounts/:account_id/audit/theme`), the account id becomes part of every
`:authorize` event's `path` metadata, forwarded to every attached handler
indefinitely. The current `guides/operator-surface.md` canonical topology
mounts at a single fixed `/audit` prefix with no dynamic segments, so this is
not exploitable with the documented mount shape — but nothing in code or
in the `telemetry_registry_contract_test.exs` static/runtime contract check
enforces that `path` stays shape-safe; the contract test only asserts
`is_binary(value)` for this key (its own comment even calls `:path` "the
single allowed exception" to the identity-safety rule, but exempts it from
the rule entirely rather than bounding it).

**Fix:** Either document explicitly in `guides/telemetry.md`'s cardinality
section that adopters who mount the theme route under a dynamic path segment
take on responsibility for that leak, or constrain `authorize_path/1` to the
static mount prefix (e.g. strip everything after the second path segment)
so the guarantee holds regardless of how a host nests its router.

## Info

### IN-01: `ExportAuthPlug` and `Auth.on_mount/4` always pass `nil` for `conn_or_nil`, silently dropping `path` even though a conn is available

**File:** `lib/threadline/operator_surface/export_auth_plug.ex:70`, `lib/threadline/operator_surface/auth.ex:93`

**Issue:** `ThemeAuthPlug.emit_telemetry/3` passes the real `conn`, so its
`:authorize` events carry `path`. `ExportAuthPlug.emit_telemetry/3` (which
also has a `conn` in scope) and `Auth.on_mount/4`'s `emit_telemetry/3` (a
LiveView mount, which legitimately has no conn) both hard-code `nil`, so
every export-auth and LiveView-mount `:authorize` event always has
`path: ""`. This matches the pre-change (`3159f27a`) behavior exactly (not a
regression introduced by this diff) and may be a deliberate choice to keep
path off the higher-traffic export/LiveView surface — but it is an
unexplained asymmetry between the three auth entry points worth a one-line
comment so a future contributor doesn't "fix" it as a bug (or doesn't leave
it inconsistent by accident while "fixing" WR-02).

**Fix:** Either pass `conn` from `ExportAuthPlug` for parity with
`ThemeAuthPlug`, or add a comment at each `nil` call site stating why the
export-auth and mount paths intentionally omit `path`.

---

_Reviewed: 2026-10-02_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
