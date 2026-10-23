# Phase 242: Export and retention operations - Pattern Map

**Mapped:** 2026-10-10  
**Files analyzed:** 19 likely existing implementation/test files, plus one optional internal runner boundary  
**Analogs found:** 19 / 19 existing files; no exact analog for a new retention-runner module or native disable-on-socket-loss behavior

All source and test analogs below were checked with `git ls-files`; the listed files are tracked sources, not generated or ignored mirrors. The project has no `.codex/skills/` or `.agents/skills/` directory in this worktree.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/operator_surface/live/timeline_live.ex` | LiveView/controller | request-response + persisted-job write | same module's `request_background_export/3` | exact |
| `lib/threadline/operator_surface/live/timeline_live/filters.ex` | component/template | transform + interactive control | same module's `export_actions/1` | exact |
| `lib/threadline/operator_surface/live/export_status_live.ex` | LiveView/controller | CRUD read + queue request + polling | same module's mount, refresh, and queue event | exact |
| `lib/threadline/operator_surface/live/export_status_live/components.ex` | component/template | transform/render | same module's `job_history/1` and `timeline_search_path/2` | exact |
| `lib/threadline/operator_surface/presentation.ex` | utility/presentation | transform | `export_readiness/2`, `export_status_label/2` | exact |
| `lib/threadline/operator_surface/controllers/export_controller.ex` | controller | request-response + file I/O | same module's `download/2` and `deliver_export/2` | exact |
| `lib/threadline/governance/export_job.ex` | model/schema | CRUD persistence | same module's actor-validated changeset | exact |
| `lib/threadline/query/filter_params.ex` | utility/validation | transform | same module's allowlist, parse, canonical query | exact |
| `lib/threadline/operator_surface/live/retention_history_live.ex` | LiveView/controller | CRUD read + destructive request + polling | same module's `prune_now` event and run refresh | exact |
| `lib/threadline/retention/pruner.ex` | GenServer/worker | event-driven + scheduled batch | same module's callback and advisory lock | exact |
| `lib/threadline/retention.ex` | service | batch database I/O | same module's purge tracking and batch loop | exact |
| `lib/threadline/governance/retention_run.ex` | model/schema | CRUD persistence | same module's unconstrained status and changeset | exact |
| `lib/threadline/operator_surface/ui/page.ex` | component/shell | static render | `shell/1` shared root | exact |
| `lib/threadline/operator_surface/ui/overlay.ex` | component | static render + status | `reconnect_banner/1` and modal primitive | exact |
| `lib/threadline/operator_surface/style/08_overlays_motion.css` | stylesheet | state-to-render transform | existing LiveView lifecycle selectors | exact (visual only) |
| `test/threadline/operator_surface/live/export_status_live_test.exs` | test | request-response + DB | same module's queue, ownership, expiry, polling tests | exact |
| `test/threadline/operator_surface/live/retention_history_live_test.exs` | test | request-response + DB | same module's confirmation/auth tests | exact |
| `test/threadline/retention/pruner_test.exs` and `test/threadline/retention_test.exs` | tests | worker/event-driven + batch DB | current scheduler, lock, purge and run tests | exact |
| `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | browser test | interactive + transport lifecycle | existing socket-drop and modal keyboard cases | exact journey; assertion gap |

## Pattern Assignments

### Export request, durable job, and source-search return

**Analog:** `lib/threadline/operator_surface/live/timeline_live.ex` (tracked)

The LiveView validates its server-owned assigns before handling the event, inserts an actor-owned `ExportJob`, and reports acceptance only after the queue adapter returns `:ok`. Adapter rejection is persisted as a safe failed job. Extend this path with a duplicate/in-flight guard while retaining all current scope and actor checks.

**Request and persistence pattern** (lines 415-468):

```elixir
job_changeset =
  ExportJob.operator_changeset(%{
    status: "pending",
    query_params: Map.new(socket.assigns.filters, fn {k, v} -> {to_string(k), v} end),
    actor_ref: actor_ref
  })

job = repo.insert!(job_changeset, StorageSchema.repo_opts(storage_schema: storage_schema))

case adapter.enqueue(job.id, storage_schema: storage_schema) do
  :ok ->
    {:noreply,
     socket
     |> put_flash(:info, "Background export requested. View progress on the Export Status page.")
     |> push_navigate(to: "#{socket.assigns.base_path}/exports")}
  {:error, reason} ->
    error_message = background_export_error_message(reason)
    job |> ExportJob.changeset(%{status: "failed", error_message: error_message,
      expires_at: terminal_export_expiry()}) |> repo.update!(storage_opts(socket))
    {:noreply, put_flash(socket, :error, error_message)}
end
```

The adapter contract is explicit at `lib/threadline/export_queue.ex:58-65`: `:ok` means the queue accepted responsibility. Do not move “queued” feedback ahead of that response. `ExportJob.operator_changeset/2` at `lib/threadline/governance/export_job.ex:25-50` requires an identifiable actor; preserve it rather than constructing a generic changeset for operator jobs.

**Filter and URL pattern:** `lib/threadline/query/filter_params.ex:16-39,44-80` owns an explicit supported-key allowlist and stable key order. Use its `parse/1`, `filters_raw_from_params/1`, and `canonical_query/1` to validate/rebuild Timeline state; never take a browser-supplied return URL. Empty-filter return is represented by the base Timeline path in `TimelineLive` saved-view handling (`lib/threadline/operator_surface/live/timeline_live.ex:293-309`).

**Status presentation:** `lib/threadline/operator_surface/presentation.ex:283-302,325-382` already centralizes readiness and status/action copy. It considers completed + nonblank path + unexpired timestamp ready; pending/running states preparing; failed states attention; a completed expired/pathless record unavailable. Keep the controller authoritative for whether current storage can deliver the file.

**Status page analog:** `lib/threadline/operator_surface/live/export_status_live.ex:28-44,61-132,348-405` initializes from persisted jobs, scopes the query by `ActorRef`, keeps a single owned polling timer, and separates adapter rejection from transport state. Reconnect/mount must reload durable actor-owned rows; do not enqueue from the read path. `components.ex:62-72,100-105,161-170` renders download only when readiness allows and builds a local source link. Its current source link is conditional on nonempty filters; D-02 requires using the same local-link idea with an unfiltered `/timeline` fallback.

**Download authority:** `lib/threadline/operator_surface/controllers/export_controller.ex:28-68,70-88` parses the job UUID, fetches the current record, compares owner ActorRefs, checks completion/expiry, then resolves storage delivery on the request. Preserve this request-time check; do not preflight storage on every render or treat job metadata as proof the file exists.

### Retention confirmation and one-record run lifecycle

**Confirmation/auth analog:** `lib/threadline/operator_surface/live/retention_history_live.ex` (tracked)

The handler's order is security-significant: event-time host authorization, canonical server token, constant-time equality, audit action, then pruner. Keep the ordering and public host authorization integration.

```elixir
with :ok <- authorize_prune(socket),
     canonical <- @canonical_policy_name,
     true <- Plug.Crypto.secure_compare(typed, canonical),
     {:ok, _action} <- audit_prune(socket, canonical),
     :ok <- Pruner.trigger() do
  Process.send_after(self(), :refresh, 500)
  {:noreply, socket |> assign(:prune_modal_open, false)
    |> put_flash(:info, "Retention prune started. Follow retention runs here.")}
else
  # Return safe failure copy; no unaudited or unauthorized prune.
end
```

Source: `retention_history_live.ex:77-107`; event-time authorization helper at `365-400`. The existing modal at `322-354` uses `UI.Overlay.modal`, labeled policy confirmation, and a native submit button. Preserve the exact canonical policy name and recheck authorization on the server; add native disabled/in-flight state to the submit while keeping the cancel button available.

**Worker/exclusion analog:** `lib/threadline/retention/pruner.ex` (tracked)

```elixir
def handle_info(:run_purge, state) do
  %{repo: repo, interval_ms: interval_ms, sleep_ms: sleep_ms,
    storage_schema: storage_schema} = state

  repo.checkout(fn ->
    if acquire_lock(repo) do
      try do
        Threadline.Retention.purge(repo: repo, sleep_ms: sleep_ms,
          storage_schema: storage_schema)
      after
        release_lock(repo)
      end
    else
      Logger.debug("threadline_retention_pruner lock held elsewhere, skipping purge")
    end
  end)

  schedule_next(interval_ms)
  {:noreply, state}
end
```

Source: `pruner.ex:91-128`. Keep acquisition/execution/release within the same `repo.checkout/1` session and pair release in `after`. The current `trigger/0` at `28-37` casts and returns `:ok` before a run exists; this is the acceptance gap. Rework the synchronous acceptance edge so a run is inserted/coalesced before acknowledging, then pass that same ID into execution. Do not mistake the execution advisory lock for queued-request coalescing.

**Run persistence/batch analog:** `lib/threadline/retention.ex` and `lib/threadline/governance/retention_run.ex` (tracked)

```elixir
run_record = repo.insert!(RetentionRun.changeset(%RetentionRun{}, %{
  status: "running", started_at: started_at
}), storage_opts)

result = purge_loop(repo, cutoff, batch_size, max_batches, delete_empty?,
  sleep_ms, storage_opts)

repo.update!(RetentionRun.changeset(run_record, %{
  status: "completed",
  deleted_count: result.deleted_changes + result.deleted_transactions,
  duration_ms: duration_ms, completed_at: completed_at
}), storage_opts)
```

Source: `retention.ex:117-154`; batch totals are accumulated by `purge_loop/7` at `204-249`. Existing tracking inserts at execution start and only writes success; an exception can leave no terminal state. Change the smallest internal seam to create/claim queued state before ack and update that same record with cumulative completed deletes and a safe failure category on exceptions. Preserve `Retention.purge/1`'s documented success result, `{:error, :disabled}`, and reraising behavior (`retention.ex:42-75`; regression `test/threadline/retention_test.exs:203-225`). `RetentionRun` already has unconstrained text status and fields for counts, duration, safe error message, and timestamps (`retention_run.ex:10-33`); no schema migration is needed. No existing dedicated runner module is a strong analog, so prefer keeping the extraction private to these current boundaries unless planning proves a tiny internal module is materially clearer.

### Shared reconnect UI and mutation controls

**Shell/banner/CSS analogs:** `lib/threadline/operator_surface/ui/page.ex`, `ui/overlay.ex`, and `style/08_overlays_motion.css` (tracked)

The shell renders `Overlay.reconnect_banner/1` once immediately above `#tl-main` (`page.ex:275-299`). The banner is a polite `role="status"` using LiveView's client-applied lifecycle classes (`overlay.ex:280-307`). CSS selectors are scoped under `[data-phx-main].phx-loading|phx-error|phx-client-error` and dim/pointer-block `[data-tl-mutating]` (`08_overlays_motion.css:271-307`). Reuse this lifecycle and keep page content/navigation visible.

**Important gap / no exact analog:** existing CSS blocks pointer events only. A comment in `ui/overlay.ex:289-297` notes pointer blocking is only an affordance; for links it recommends `aria-disabled` and removing tab order. Phase 242's locked contract calls for native disabled state on mutation buttons, including Timeline export and prune submit, plus an in-flight guard. Do not copy the current pointer-only behavior as a complete fix. There is no existing reusable native disabled-on-socket-loss binding; if a client lifecycle hook is needed to set/restore `disabled`, keep it within Phoenix LiveView and the existing private UI layer, with a fresh durable-state gate before reenable. Retain server auth/validation independently.

### Test patterns

- **Export LiveView:** `test/threadline/operator_surface/live/export_status_live_test.exs:25-49,98-107,133-157,412-459,538-628` uses small queue adapter modules, deterministic actor session setup, DB fixtures, `live/2`, and focused assertions. Extend with adapter error/acceptance, empty source fallback, actor-owned reconnect/remount state, and no fake download for missing/expired outcomes.
- **Download boundary:** `test/threadline/operator_surface/controllers/export_controller_test.exs:644-742,800-830` covers absent actor, wrong owner/schema, not-ready, expired, and storage-unavailable responses. Add missing-object proof here if the UI must distinguish the request result; don't weaken controller assertions.
- **Retention LiveView:** `test/threadline/operator_surface/live/retention_history_live_test.exs:110-145,224-268,427-555` uses `open_prune_modal/1`, server `render_submit`, before/after run and `AuditAction` counts, and event-time auth revocation. Reuse these helpers to assert the accepted record appears before acknowledgement and forged/unauthorized attempts create neither action nor run.
- **Pruner:** `test/threadline/retention/pruner_test.exs:9-41,65-119,146-171` controls the singleton and long timer interval, uses `assert_eventually`, and holds the PostgreSQL lock on a dedicated session. Extend for synchronous persisted acceptance, active-run coalescing, and lock-release/failure paths; retain schema scoping checks.
- **Purge service:** `test/threadline/retention_test.exs:203-244` verifies raised DB errors retain their public behavior and successful deletion records one completed run. This is the closest test pattern for cumulative partial failure and same-record terminal update.
- **Real transport:** `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts:598-630` actually closes/restores the LiveView websocket and tries pointer and keyboard activation. It currently captures `disabled`/`aria-disabled`/marker state as evidence without requiring disabled to be true; its post-reconnect count allows one added job. Promote these observations to assertions, keep the read-only page available, add retention submit and in-flight cases, and verify no replay. Nearby `632-648` provides a browser focus-return pattern for the confirmation modal.

## Shared Patterns

### Authorization and ownership

**Sources:** `RetentionHistoryLive.handle_event/3` (`retention_history_live.ex:77-107`), `ExportController.download/2` (`export_controller.ex:28-68`), `ExportJob.operator_changeset/2` (`export_job.ex:41-50`).

Keep browser state as affordance only: reauthorize destructive prune in the LiveView event; compare the canonical confirmation server-side with `Plug.Crypto.secure_compare/2`; persist an audit action before deletion; scope exports to the identifiable actor; and authorize every download request against the current stored job.

### Durable status and truthful errors

**Sources:** `export_status_live.ex:91-124,348-405`, `retention_run.ex:10-33`, `retention.ex:117-154`.

Persist before success acknowledgement; use the persisted job/run for remount and polling; distinguish adapter acceptance from socket transport; keep one `RetentionRun` identity across queued/running/terminal states; preserve completed deletion count on partial failure; and expose only safe failure categories. Do not promise exactly-once behavior after uncertain transport or deliberate retry.

### Reconnect accessibility

**Sources:** `page.ex:275-299`, `overlay.ex:280-307`, `08_overlays_motion.css:271-307`.

Keep the shell's status banner polite and focus-neutral. Pause only mutations, natively disable buttons while offline/in-flight, leave navigation/read-only content usable, and do not reenable until a fresh authoritative read. CSS opacity/pointer rules do not block keyboard activation or forged server events.

### Verification

Run focused ExUnit using the existing files listed above, then the named mounted-browser entrypoint `mix verify.example_browser` for actual socket loss, and finish with `mix ci.all`. No package, migration, route, or public API addition is indicated by these patterns.

## No Analog Found

| File/behavior | Role | Data Flow | Reason |
|---|---|---|---|
| Optional new `lib/threadline/retention/runner.ex` | internal service/coordinator | request-response + event-driven | No existing single-run acceptance coordinator. Prefer a private refactor within `Retention`/`Pruner`; introduce a new file only if that is the smallest clear seam, and preserve public `purge/1` behavior. |
| Native disabled state synchronized to socket loss/reconnect | client lifecycle behavior | event-driven | Existing shell exposes the real lifecycle via CSS, but no tracked pattern dynamically applies native `disabled` to buttons. Keep any needed binding minimal and private; tests must prove pointer and keyboard behavior on actual socket loss. |

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/live`, `lib/threadline/operator_surface/ui`, `lib/threadline/operator_surface/style`, `lib/threadline/retention*`, `lib/threadline/governance`, `lib/threadline/query`, matching `test/threadline` modules, and Phoenix example E2E tests.  
**Files scanned:** 19 primary files plus direct dependencies (`ExportQueue`, `ExportController`, `ExportJob`, `FilterParams`, `Presentation`).  
**Pattern extraction date:** 2026-10-10
