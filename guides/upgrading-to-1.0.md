# Upgrading to 1.0.0

This guide takes a Threadline 0.11.x or 0.12.x application to 1.0.0. If you
are already on 0.12.x, skip the preflight and continue with Step 1.

## Before you upgrade from 0.11.x

Complete these three changes from 0.12.0 before moving to 1.0.0. The full
source notes are in the [0.12.0 breaking changes](../CHANGELOG.md#breaking-changes)
and their adopter route is in the [upgrade path](upgrade-path.md).

- Use lists for `exclude:`, `mask:`, and `except_columns:` table options, and
  pass a string to `mask_placeholder:`. For example, use `exclude: [:ssn]`.
  <!-- threadline:upgrade:0.12:config-shape -->
- Remove `actor_ref`, `session_actor_ref`, and `scope_actor_ref` from operator
  telemetry handler patterns. Read the actor from your own session or scope.
  <!-- threadline:upgrade:0.12:telemetry-actor -->
- Match health error telemetry metadata as `%{exception: module}` instead of
  `%{error: message}`, and pass the exception struct to
  `emit_health_checked_error/1`.
  <!-- threadline:upgrade:0.12:health-error -->

If you adopted 0.11.x but never completed its trigger migration, first follow
the [0.11 trigger regeneration procedure](upgrading-to-0.11.md#step-2-regenerate-triggers).
That is a prerequisite from the earlier release. **The 1.0 changes require no
trigger regeneration.**

## Step 1: Move to the supported API

Change calls to documented `Threadline` entry points and use the current
option contracts. `Threadline.Job.context_opts/2` now rejects unsupported
`extra` keys; remove them and provide string, integer, or `nil` context IDs.
Unknown options such as `:surface` and `:params` now raise `ArgumentError` on
the documented query, export, and transaction APIs. Remove those keys. The
undocumented proof-recording, SQL-construction, telemetry-emission, and export
query helpers are unsupported internals; migrate any direct calls to documented
APIs. A non-nil `:scope` requires a three-argument `scope_query_fn`; pair them,
or pass `scope: nil` for an intentionally unscoped read. End scope callbacks
with a deny-all clause such as `where(query, false)`.

<!-- threadline:upgrade:1.0:job-context -->
<!-- threadline:upgrade:1.0:hidden-apis -->
<!-- threadline:upgrade:1.0:strict-options -->
<!-- threadline:upgrade:1.0:hidden-helpers -->
<!-- threadline:upgrade:1.0:fail-closed-scope -->

## Step 2: Bound row history

`row_history/2,3` now returns at most 200 newest changes by default. Pass
`limit: :infinity` if you need the entire history, or walk pages with
`cursor: :start` and an optional `page_size:`. Do not combine `:limit` with
`:cursor`, or pass `:page_size` without a cursor.

<!-- threadline:upgrade:1.0:bounded-row-history -->

## Step 3: Use the shared Page shape

Timeline and actor-history paging return `%Threadline.Page{entries, cursor,
has_more}`. Replace page-specific result matches with `Threadline.Page`; read
`.cursor` and `.has_more`. A final full page has no cursor, and a first-page
request should omit `:cursor` or use `cursor: :start`, not `cursor: nil`.

<!-- threadline:upgrade:1.0:timeline-page -->
<!-- threadline:upgrade:1.0:actor-history-page -->

## Step 4: Handle lookup results and options

`transaction_context/2` returns `{:ok, linked_transaction}` or
`{:error, :not_found}`. Match the tuple, or call `transaction_context!/2` when
absence is an error. The transaction and incident lookup APIs accept only
`:repo`, `:storage_schema`, `:scope`, and `:scope_query_fn`; remove `:surface`,
`:params`, and `:preload`. An invalid binary UUID returns `:not_found` (or
raises `Threadline.NotFoundError` through a bang function); a non-binary id
still raises `ArgumentError`. Keep the `:transaction_header` scope clause.

<!-- threadline:upgrade:1.0:linked-lookup-shape -->
<!-- threadline:upgrade:1.0:transaction-lookup-options -->

## Step 5: Read action associations through exploration APIs

An un-hydrated `AuditTransaction.action` is now `nil`, not
`%Ecto.Association.NotLoaded{}`, and direct `Repo.preload(transaction, :action)`
is no longer available. Read an associated action through
`Threadline.transaction_context/2` or `Threadline.incident_bundle/2`, or query
`audit_actions` by `action_id`. This changes exploration hydration only:
`AuditTransaction` still represents one database transaction,
`AuditAction` remains a separate semantic event, and the `action_id` column
and foreign key are unchanged.

<!-- threadline:upgrade:1.0:association-hydration -->

## Step 6: Upgrade PostgreSQL

PostgreSQL 15 is the supported minimum for Threadline 1.0. Upgrade a
PostgreSQL 14 database before upgrading the dependency, then run your normal
database migration and application verification process.

<!-- threadline:upgrade:1.0:pg-floor -->

## Step 7: Replace deprecated calls

Deprecated calls remain available during 1.x and are scheduled for removal no
earlier than 2.0. Move to the listed replacement before then:

- Replace `Threadline.Query.audit_transaction` with the documented
  `Threadline.audit_transaction/2` facade.
  <!-- threadline:upgrade:1.0:deprecated-query-audit-transaction -->
- Remove `:action` from the `:preload` option of
  `Threadline.Query.audit_changes_for_transaction`; use the exploration APIs
  in Step 5 to read the action.
  <!-- threadline:upgrade:1.0:deprecated-preload-action -->
- Replace the legacy positional row-history call with `row_history/3`, using
  one keyword options list.
  <!-- threadline:upgrade:1.0:deprecated-row-history-4 -->
- Replace the removed unbounded history call with `row_history/3`. Pass
  `limit: :infinity` for its prior unbounded behavior and map `.audit_change`
  when callers need the old `%AuditChange{}` result.
  <!-- threadline:upgrade:1.0:deprecated-history-3 -->
- Replace the legacy row-history page helpers with `row_history/3`, starting
  with `cursor: :start`.
  <!-- threadline:upgrade:1.0:deprecated-row-history-page -->
- Replace the legacy actor-window pager with `actor_window/3` and
  `cursor: :start`.
  <!-- threadline:upgrade:1.0:deprecated-actor-window-page -->
- Replace the legacy correlation-bundle pager with `correlation_bundle/3` and
  `cursor: :start`.
  <!-- threadline:upgrade:1.0:deprecated-correlation-bundle-page -->
- Replace the `:after`, `:before`, and `:limit` options to `actor_history/2`
  with `cursor:` and `page_size:`. Use `{:before, cursor_map}` to walk newer.
  <!-- threadline:upgrade:1.0:deprecated-actor-history-options -->

## Next steps

Review the [1.x stability contract](stability.md) and run your application's
verification suite before deployment.

- [Return to the first-hour adoption path](getting-started-saas.md).
- [Review the full upgrade path](upgrade-path.md).
