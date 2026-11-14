# Phase 252: Complete Operations and Connected Catalog Review - Pattern Map

**Mapped:** 2026-11-13  
**Files classified:** 18 new or modified files  
**Analogs found:** 18 / 18 (one internal Pruner target handshake has no exact precedent)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/retention/pruner.ex` | service | event-driven | same file, `trigger/0`, state capture and `handle_call/3` | partial: no target-snapshot/guarded-call API exists |
| `lib/threadline/operator_surface/live/retention_history_live.ex` | controller (LiveView) | request-response, event-driven | same file; `ExportStatusLive` for persisted history reads | role-match |
| `lib/threadline/operator_surface/live/retention_history_live/components.ex` (new) | component | transform | `lib/threadline/operator_surface/live/export_status_live/components.ex` | role-match |
| `test/threadline/retention/pruner_test.exs` | test | event-driven | same file | exact |
| `test/threadline/retention_test.exs` | test | request-response | same file | exact |
| `test/threadline/operator_surface/live/retention_history_live_test.exs` | test | request-response, event-driven | same file; `export_status_live_test.exs` for persisted-read boundaries | exact |
| `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex` | utility | transform | same file and `StressFixtures` | exact |
| `examples/threadline_phoenix/storybook/index.exs` | config | transform | same file | exact |
| `examples/threadline_phoenix/storybook/operations/index.exs` (new) | config | transform | `storybook/groups/index.exs`, `storybook/patterns/index.exs` | role-match |
| `examples/threadline_phoenix/storybook/operations/export_page.story.exs` (new) | component | transform | `storybook/groups/operator_groups.story.exs` | role-match |
| `examples/threadline_phoenix/storybook/operations/retention_page.story.exs` (new) | component | transform | `storybook/groups/operator_groups.story.exs`, plus production Retention markup | role-match |
| `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs` | test | transform | same file | exact |
| `examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts` | test | request-response | same file | exact |
| `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | test | event-driven | same file; Export reconnect case for transport handling | role-match |
| `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json` | config | transform | same file | exact |
| `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts` | test | transform | same file | exact |
| `test/fixtures/operator_surface/route-inventory.json` | config | batch | same file | exact |
| `test/fixtures/operator_surface/source-surface-checklist.json` | config | batch | same file | exact |

The existing `test/fixtures/operator_surface/route-inventory.json` and
`test/fixtures/operator_surface/source-surface-checklist.json` are source-owned
inventories to update if the source scan gains controls/anchors. Keep their current
route and source semantic identities stable. They are not a second Storybook registry.

All analogs named here are git-tracked source, verified with `git ls-files`.

## Pattern Assignments

### `lib/threadline/retention/pruner.ex` (service, event-driven)

**Analog:** same file; no existing worker offers a target snapshot or guarded same-PID
acceptance call.

The existing synchronous trigger resolves the current named PID and converts a worker
exit into `:not_started`:

```elixir
def trigger do
  case Process.whereis(__MODULE__) do
    nil -> {:error, :not_started}
    pid ->
      try do
        GenServer.call(pid, :prune)
      catch
        :exit, {:noproc, _} -> {:error, :not_started}
      end
  end
end

def handle_call(:prune, _from, state) do
  {:reply, accept_or_coalesce(state), state}
end
```

Source: `lib/threadline/retention/pruner.ex` lines 31-46, 96-99. `init/1` captures
the worker's `repo`, `sleep_ms`, `storage_schema`, and derived `storage_opts` into
GenServer state (lines 55-94); `handle_info({:execute, run_id}, state)` later runs
with that captured target (lines 108-128). Add the narrow allowlisted snapshot and
expected-target acceptance as GenServer calls against the captured PID/state. Keep
`trigger/0` and `:prune` behavior unchanged for every existing caller. Never resolve a
replacement PID after the guarded check and never inspect live business state with
`:sys.get_state`.

**Existing test owners:** `test/threadline/retention/pruner_test.exs`:

- `"trigger persists one run before acknowledgement and permits a later deliberate run"`
  (lines 111-151) establishes synchronous acceptance and later-run semantics.
- `"rapid triggers coalesce while the accepted run is active"` and
  `"worker startup failure marks the accepted run failed and permits a later request"`
  (lines 153-225) own coalescing and failure recovery.
- `"startup marks abandoned runs only in the selected storage schema"` and
  `"triggered prune records runs only in the selected storage schema"` (lines 301-350)
  own schema selection.

Add focused tests here for allowlisted target fields, same-PID acceptance, mismatch,
unreadable/dead/restarted worker, and no fallback to a replacement. Test-only
`:sys.replace_state` helpers in this file are fixture setup, not a production pattern.

### `lib/threadline/retention.ex` (existing read-only preview service)

**Analog:** same file; it already implements the authorized primitive `purge/1` with
`dry_run: true`, so no second estimate service or public API is needed.

```elixir
span_dry_run? = dry_run? not in [false, nil]

Threadline.Telemetry.purge_span(span_dry_run?, fn ->
  run_purge(dry_run?, repo, cutoff, batch_size, max_batches, policy, sleep_ms, storage_opts)
end)
```

```elixir
eligible_changes =
  repo.one(from(ac in AuditChange, where: ac.captured_at < ^cutoff, select: count(ac.id)), storage_opts)

eligible_txns =
  if policy.delete_empty_transactions do
    repo.one(
      from(at in AuditTransaction,
        as: :audit_transaction,
        where:
          not exists(
            from(c in AuditChange,
              where:
                c.transaction_id == parent_as(:audit_transaction).id and
                  c.captured_at >= ^cutoff,
              select: 1
            )
          ),
        select: count(at.id)
      ),
      storage_opts
    )
  else
    0
  end

%{deleted_changes: eligible_changes, deleted_transactions: eligible_txns,
  batches_run: 0, dry_run: true}
```

Source: `lib/threadline/retention.ex` lines 112-133, 265-300. The two counts are
sequential full-table queries; the dry run makes no deletes, has `batches_run: 0`,
ignores `batch_size`/`max_batches`, and computes its policy cutoff at invocation.
Treat change and empty-transaction estimates as distinct; if empty-transaction
cleanup is disabled, render “not included” rather than presenting that implementation
zero as zero eligible transactions. No cutoff or preview lineage is returned.

**Existing test owners:** `test/threadline/retention_test.exs`:

- `"dry-run counts only the selected storage schema"` (lines 357-406) also asserts
  unchanged source counts and zero batches.
- `"dry run counts the transactions a purge would empty, matching a completed real purge (D-20 regression)"`
  (408-430) owns the transaction predicate boundary.
- `"dry run ignores :batch_size and :max_batches (preview is a full-table count, not batched)"`
  (432-455) owns the full-table limitation.
- `"dry run emits zero batch_purged events"` (230-244) owns telemetry behavior.

Extend the existing owner for any separate no-write proof needed: assert preview does
not change audit row totals or create `RetentionRun`/`AuditAction` records. Disabled,
query failure, valid `0/0`, and disabled empty-transaction cleanup need explicit UI
states in the LiveView tests below.

### `lib/threadline/operator_surface/live/retention_history_live.ex` (controller, LiveView)

**Analog:** same file for the destructive flow; `lib/threadline/operator_surface/live/export_status_live.ex`
for persisted history state/retry patterns.

Current submit ordering is authorization, canonical constant-time typed confirmation,
audit, then trigger; the audit write currently resolves repo/schema independently:

```elixir
with :ok <- authorize_prune(socket),
     canonical <- @canonical_policy_name,
     true <- Plug.Crypto.secure_compare(typed, canonical),
     {:ok, _action} <- audit_prune(socket, canonical),
     :ok <- Pruner.trigger() do
  ...
end
```

Source: `lib/threadline/operator_surface/live/retention_history_live.ex` lines 97-114.
The write path calls `Threadline.record_action/2` using `resolve_repo(socket)` and
`StorageSchema.get()` (lines 509-519), while `fetch_runs/1` also derives its own
repo/storage options (521-535, 558-564). This is the hidden target coupling: mount
storage can differ from the worker's startup-captured repo/schema. Preview must obtain
and validate the worker snapshot before counting, recheck that same target after the
sequential count, and keep only a successful snapshot in server-side socket state.
Confirmation reauthorizes and rechecks that stored target, audits to that repo/schema,
then calls the guarded same-PID trigger. Caller params cannot establish preview state.
Unavailable, mismatched, unreadable, or restarted target means no visible counts and
no confirm path. Clear transient state on cancel/remount. Keep the existing
`secure_compare`, audit-before-trigger, active-run coalescing, and persisted
`RetentionRun` statuses/outcomes. A crash after the audit write may leave the request
AuditAction without a run, but must not redirect to a new worker.

Mount initializes transient confirmation state in `mount/3` (lines 34-60). Use this
server-owned state pattern; do not add a browser-supplied snapshot ID or a second
preview store. Existing modal cancel handlers clear confirmation error at lines
166-178.

**Existing test owners:** `test/threadline/operator_surface/live/retention_history_live_test.exs`:

- `"a failed history read stays distinct from empty and offers refresh"` (169-186)
  for unavailable vs empty.
- `"a forged confirmation token fails closed and performs no prune"` and
  `"an empty confirmation stays in place and performs no prune"` (545-591).
- `"event-time authorization revocation prevents audit and prune"` (640-658) and
  `"audit persistence failure prevents the prune and returns safe feedback"` (675-698).
- `"a valid type-to-confirm prune records an AuditAction for the destructive action"`
  (700-733) for audit-before-worker and persisted run.

Add target mismatch/restart, preview denial/failure/zero/no-write, forged direct
confirmation, and accepted outcome assertions in this owner. Do not replace these
independent authorization/audit controls.

### `lib/threadline/operator_surface/live/retention_history_live/components.ex` (new component)

**Analog:** `lib/threadline/operator_surface/live/export_status_live/components.ex`.

This is the closest production precedent for extracting a named `Phoenix.Component`
from a LiveView while keeping presentation helpers local to its markup:

```elixir
defmodule Threadline.OperatorSurface.Live.ExportStatusLive.Components do
  @moduledoc false
  use Phoenix.Component
  alias Threadline.OperatorSurface.Presentation
  alias Threadline.OperatorSurface.UI

  attr(:jobs_count, :integer, required: true)
  attr(:default_limit, :integer, required: true)
  attr(:job_groups, :list, required: true)
  attr(:base_path, :string, default: nil)

  def job_history(assigns) do
    ~H"""
      <section id="export-jobs" data-testid="export-jobs">...
    """
  end
end
```

Source: `lib/threadline/operator_surface/live/export_status_live/components.ex` lines
1-32. Continue calling `Components.job_history/1` for Export stories. Extract only
the Retention history/preview presentation needed by both `RetentionHistoryLive` and
the static story; do not create a generic page engine or duplicate the domain/action
markup. Story controls must be absent or inert.

### Static Storybook files and fixtures

**Story analog:** `examples/threadline_phoenix/storybook/groups/operator_groups.story.exs`
and `.../patterns/operator_patterns.story.exs`. **Index analogs:**
`storybook/index.exs`, `storybook/groups/index.exs`, and `storybook/patterns/index.exs`.

Root categories are explicit labels/indices (`storybook/index.exs` lines 8-15); a
category folder module sets `folder_name`, icon and `folder_index` (`storybook/patterns/index.exs`
lines 1-6). Page stories use `PhoenixStorybook.Story, :page`, import the wrapper,
alias `Fixtures` and `UI`, document fixture/accessibility/theme limits, assign static
data before rendering, and compose real production components (groups story lines
1-27, 37-57). `Fixtures.group_sample/1` resolves an allowlisted ID through the pure
`StressFixtures.by_id/1` and `assigns_for/1` functions (fixtures.ex lines 91-106);
it does not call Repo or demo seeders.

Extend `fixtures.ex` with a narrow explicit Operations fixture helper. Current static
page identities in `StressFixtures`/the design-system ledger include
`page.exports.happy`, `.empty`, `.loading`, `.error`, `.permission`, `.boundary`,
`.advanced` and the corresponding `page.retention.*` IDs. `page.retention.happy` has
its current production-source description in `lib/threadline/operator_surface/stress_fixtures.ex`
lines 724-731. Existing ordinary/boundary semantic scenario IDs include
`scenario.acme-4521-investigation` and `scenario.offboarded-co-retention-boundary`;
the existing seeded failed-job scenario is `scenario.state-export-failed`. Stories may
cite these identities as provenance, but must render deterministic static assigns and
must not invoke `Demo.Seed`, Repo, file writes, or destructive actions.

Use current surface identities in story docs and the single semantic inventory:

| Surface | Job | Existing source refs | Existing proof refs |
|---|---|---|---|
| `route.exports` | `job.operator-export-status` | `source-exports-2` through `source-exports-9`, `source-route-exports-9` | `proof-exports-1`, `proof-exports-2` |
| `route.retention` | `job.operator-retention-operations` | `source-retention-2` through `source-retention-9` | `proof-retention-1`, `proof-retention-2` |

Source: `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json`
surfaces for those route IDs. Preserve `route.exports`, `route.retention`, and these
job/source/proof IDs; add Storybook references only to this existing inventory and
validate them through its current contract. The route paths remain `/audit/exports`
and `/audit/policy/retention`.

### Catalog, inventory, and browser test owners

- `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs`
  already enforces explicit categories, docs/provenance/theme, and curated page
  contracts. Extend `@categories` and add a narrow Operations story-to-inventory
  contract; preserve the existing test `"story taxonomy includes the required
  categories and small Patterns branch"` (lines 144-154) and provenance test
  (156-175). Do not use a story count or second registry as the link source.
- `examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts` owns the bounded
  rendered-page smoke. Add Operations routes to `representativeStories` (lines 5-16);
  preserve its index/local-assets test and 320/375/768 responsive loop (45-80).
- `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` owns mounted
  mutation and reconnect behavior. Existing cases are `"Retention confirmation focus
  and cancel preserve state; Chromium touch navigation works"` (1403-1454) and the
  parameterized `"offline Exports blocks ${input} activation until fresh persisted
  state returns"` (1330-1400). The latter demonstrates blocked socket reconnect,
  disabled stale activation, changed mutation revision, and a later deliberate click;
  create a Retention-specific case to prove its preview/confirm state cannot replay
  after reconnect. The Export case alone is not proof of Retention behavior.
- Preserve Export behavior under its existing owners unless a defect is found:
  `test/threadline/operator_surface/live/export_status_live_test.exs` cases
  `"queueing carried Timeline context creates an actor-owned canonical ExportJob"`
  (515-563), `"scoped carried Timeline context cannot create an unscoped background
  job"` (564-583), `"shows download link when completed"` (641-678), and
  `"hides the download action for expired completed exports"` (735-758). Browser flow
  owners are `"filtered Timeline context carries into Exports"` and `"filtered Evidence
  context carries into Exports"` in `operator-earned-flows.spec.ts` (594-693), plus
  `"Exports seeded pending, failed, completed, unavailable and invalid context stay
  distinct"` in `operator-route-states.spec.ts` (1003-1020).
- `examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts` is the
  existing semantic/source/proof link validator. Preserve independent negative
  controls: `"route inventory exactly matches the independently read eleven router
  paths"` (876-884), `"named scenarios reject missing state links, duplicate-label
  identities, unsafe paths, and wrong proof owners"` (1045 onward), and
  `"semantic identities and source ownership survive reordered declarations;
  malformed mappings fail"` (1139-1196). These currently exercise duplicate route
  identities, missing/source-locator ownership and malformed mappings. Keep them
  independent when adding story links.

## Shared Patterns

### Retention target and authorization

**Sources:** `lib/threadline/retention/pruner.ex` lines 34-45, 55-94;
`lib/threadline/operator_surface/live/retention_history_live.ex` lines 97-114,
471-519. Preview is permitted only after event-time policy authorization. Compare the
mounted target to the allowlisted worker snapshot before counting and recheck the
same PID/target after both counts. Store only successful preview state on the server;
confirmation must reauthorize, recheck, audit to that same target, then guarded-trigger
that PID. Any mismatch/failure/restart clears counts and the confirm path. Existing
direct `Pruner.trigger/0` callers keep their current path.

### Read-only estimate and persisted outcome

**Sources:** `lib/threadline/retention.ex` lines 265-300 and
`lib/threadline/retention/pruner.ex` lines 131-189; live history `fetch_runs/1` at
`retention_history_live.ex` lines 521-535. Label counts as estimates with UTC
generation time and sequential/non-atomic/full-schema limitations. Display persisted
queued/running/completed/failed RetentionRun values as outcomes; preview totals are
not deletion totals. A valid `0/0` preview may confirm. Empty-transaction cleanup
disabled is “not included,” not an eligible count.

### Storybook isolation

**Sources:** `storybook/patterns/operator_patterns.story.exs` lines 8-20, 23-36;
`storybook/groups/operator_groups.story.exs` lines 8-24, 27-44;
`storybook/fixtures.ex` lines 91-106. Stories show production components with static
assigns and state their provenance and boundary. Seed modules are writeful and do not
belong on render paths. Storybook proves composition only, not permission, URL, file,
persistence, mutation, or reconnect behavior; those remain with the actual route and
journey owners above.

### Source and semantic identities

**Sources:** `test/fixtures/operator_surface/route-inventory.json` routes
`route.exports`/`route.retention`; `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json`
surfaces/jobs/sourceRefs/proofRefs; `operator-route-evidence.test.ts` above. Update
the existing inventory owners when source anchors change. Keep route patterns and
semantic IDs stable, and retain malformed, duplicate and wrong-owner controls. Do not
introduce an adapter, parallel source map, or generic registry.

## No Exact Analog

| File/behavior | Reason | Planner guidance |
|---|---|---|
| Guarded same-PID Pruner target snapshot and acceptance | No current API returns an allowlisted captured target or accepts only against that expected snapshot. | Add two narrow undocumented GenServer calls to `lib/threadline/retention/pruner.ex`; preserve `trigger/0`, the captured target and active-run behavior. Never use `:sys.get_state` in LiveView business logic. |
| Retention preview LiveView state and shareable read-only presentation | The page currently has type-to-confirm pruning and run history, but no UI preview gate or extracted Retention component. | Reuse `Retention.purge(dry_run: true)` and extract only the needed markup into an internal component shared with its static Storybook story. Keep server state ephemeral and preserve honest preview limits. |

## Execution Limits

This artifact maps code and test owners only; no tests, builds, database, app, or
browser proof were run. Preserve existing full-root, native clipboard, foreground and
external-action stops; this mapping does not renew any run window or claim verification.

## Metadata

**Analog search scope:** `lib/threadline/retention*`, operator LiveViews/components and
their tests, Storybook source/fixture/test files, semantic inventory/validator, and
existing operator browser route/story tests.  
**Tracked-source gate:** all named analogs passed `git ls-files`.  
**Pattern extraction date:** 2026-11-13
