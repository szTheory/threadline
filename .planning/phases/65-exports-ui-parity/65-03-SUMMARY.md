---
phase: 65-exports-ui-parity
plan: 03
subsystem: live-view
tags: [elixir, phoenix-live-view, exports, task-async, filter-params, css, integration-test]

# Dependency graph
requires:
  - phase: 65-01
    provides: "Threadline.OperatorSurface.Exports.FilterParams (parse/1, filters_raw_from_params/1) and Threadline.Export.count_matching/2 :cap opt"
  - phase: 65-02
    provides: "Threadline.OperatorSurface.Controllers.ExportController + sibling /exports/changes.{csv,json,ndjson} GET routes that the LV's download anchors target"
  - phase: 64-raw-timeline-browse
    provides: "TimelineLive base structure (mount/handle_params/render), .button-cluster + .filter-error markup, build_canonical_query/1 + safe_validate/1 private helpers, timeline_live_test.exs Cases 1-14"
provides:
  - "TimelineLive runs Threadline.Export.count_matching/2 (cap: 10_001) and Threadline.Query.timeline_page/2 IN PARALLEL via Task.async/Task.await(_, 8_000) per Apply"
  - "TimelineLive delegates URL-params parsing to Threadline.OperatorSurface.Exports.FilterParams (Plan 01) — seven private parser helpers removed"
  - "Render appends three [Download CSV] [Download JSON] [Download NDJSON] anchors (with HTML download attribute) to the existing .button-cluster"
  - "Render adds a count status line above the timeline rows section ('Showing N of M matches in this window.')"
  - "Render adds a two-band truncation banner: informational (5,001 ≤ count ≤ 10,000) + warning (count ≥ 10,001) with deliberately distinct visual weight"
  - "format_count/1 helper produces '10,000+' at the cap and thousands-separator integers below"
  - "Threadline.OperatorSurface.Style extended with .download-button + .match-count-status + .truncation-banner.{informational,warning} CSS rules"
  - "Four new timeline_live integration tests (Cases 15-18) covering anchors, status line, and the two banner variants"
affects:
  - 65-04-doc-contract-parity-tests

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Parallel pre-flight via two Task.async/1 calls awaited together with 8_000 ms timeout — total LV-handle latency = max(count, page) not sum (RESEARCH §P-7)"
    - "Capped pre-flight: count_matching(filters, cap: 10_001) lets the LV distinguish exact-count-of-10_000 from cap-of-10_001+ (RESEARCH §P-8)"
    - "URL-as-state download anchors with the HTML `download` attribute (PR #2611) — keeps LV socket alive on click; controller's Content-Disposition: attachment also required (Plan 02)"
    - "format_count/1 handles both '10,000+' approximation and thousands-separator formatting via String.reverse/1 + Enum.chunk_every(3) (no NumberFormat dep)"
    - "Two-band truncation banner with distinct visual weight (D-18): informational uses neutral secondary palette; warning uses amber (#FEF3C7/#92400E/#F59E0B) — distinct from .filter-error's destructive red"
    - "Integration test bulk seeding via Repo.insert_all/3 in 1_000-row chunks (RESEARCH §P-10); ~100ms vs ~3s for 10k rows; uses unique-named tables to avoid cross-test pollution"

key-files:
  created: []
  modified:
    - lib/threadline/operator_surface/live/timeline_live.ex
    - lib/threadline/operator_surface/style.ex
    - test/threadline/operator_surface/live/timeline_live_test.exs

key-decisions:
  - "Tasks 1 and 2 committed as ONE commit because the format_count/1 helper added in Task 1 is consumed only by Task 2's render markup — a Task-1-alone commit would fail mix compile --warnings-as-errors with an unused-helper warning. The plan's per-task verification gate (mix compile --warnings-as-errors exit 0 per task) implicitly required them to land together."
  - "Plan-supplied test Case numbers 12-15 already exist in this file (Phase 64 wrote Cases 12, 13, 14 for BROWSE-02/-03 history-entry / allowlist tests). Renumbered the new cases to 15-18 to avoid collision (Rule 1 - Bug). Plan 04's doc-contract grep targets are case-body literals (Download CSV / Truncated to first 10,000 / Large export — will stream in chunks.) not case numbers, so the renumber is safe."
  - "Cases 17 and 18 use uniquely-named tables (`bulk_band_info_<unique_int>`, `bulk_band_warn_<unique_int>`) so the bulk-seeded 5,001 / 10,001 rows do not pollute other tests' filter windows in this `async: true` test module that has no per-test cleanup."
  - "bulk_seed_changes!/2 batches insert_all/3 calls at 1_000 rows per batch (PostgreSQL parameter-limit defense). The plan supplied a single insert_all call which would exceed PG's 65_535 bind-parameter limit at 10_001 × 8 fields = 80_008 binds."
  - "Amber hex literals (#FEF3C7 / #92400E / #F59E0B) added inline rather than promoting to new --tl-color-warning* CSS variables. Discretion permitted by CONTEXT.md and RESEARCH §P-3 line 433-435; keeps the Style module's :root-equivalent variable set unchanged from Phase 64."

requirements-completed: [EXPO-03, EXPO-04]

# Metrics
duration: ~6 min
completed: 2026-05-07
---

# Phase 65 Plan 03: Exports UI Parity — TimelineLive Export Buttons + Count Status + Truncation Banner Summary

**LV-side export surface for EXPO-03 + EXPO-04 in one cohesive plan: TimelineLive's `handle_params/3` now runs `Threadline.Export.count_matching/2` (`cap: 10_001`) and `Threadline.Query.timeline_page/2` IN PARALLEL via two `Task.async/1` calls awaited at `Task.await(_, 8_000)`; URL-params parsing is delegated to Plan 01's `Threadline.OperatorSurface.Exports.FilterParams` (seven private parser helpers REMOVED — Plan 04's parity test is now a structural guarantee, not a hand-copy guard); render appends three `[Download CSV] [Download JSON] [Download NDJSON]` anchors (with the HTML `download` attribute per PR #2611) to the existing `.button-cluster`; count status line + two-band truncation banner (informational at 5,001 ≤ count ≤ 10,000 / warning at count ≥ 10,001) renders above the timeline rows section; CSS module extended with four additive rules; four new integration tests (Cases 15-18) lock the user-visible literals.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-05-07T13:45:44Z
- **Completed:** 2026-05-07T13:51:57Z
- **Tasks:** 4
- **Files modified/created:** 3 (3 modified, 0 created)

## Accomplishments

- **`TimelineLive.handle_params/3` parallel pre-flight** — replaces the single `page = Query.timeline_page(...)` call with `count_task = Task.async(fn -> Threadline.Export.count_matching(filters, cap: 10_001, repo: socket.assigns.repo) end); page_task = Task.async(fn -> Threadline.Query.timeline_page(filters, scope_aware_opts(socket)) end); {:ok, %{count: count}} = Task.await(count_task, 8_000); page = Task.await(page_task, 8_000)`. Total LV-handle latency is `max(count, page)` not `sum` (D-16). Tasks are NOT wrapped in `try/rescue` (RESEARCH §P-7 line 679 — silent failures are worse than a brief LV reconnect). The `8_000` ms timeout (vs. default `5_000`) leaves headroom for slow capped-count queries on large tables.
- **FilterParams delegation** — `TimelineLive` now calls `FilterParams.parse(params)` (replaces the old private `build_filters/1`) and `FilterParams.filters_raw_from_params(params)` (replaces the old private `filters_raw_from_params/1`). Seven private parser helpers REMOVED: `filters_raw_from_params/1`, `normalize_params/1`, `parse_datetimes/1`, `parse_datetime_local/1`, `collapse_actor_ref/1`, `safe_actor_kind/1`, `build_filters/1`. The `alias Threadline.Semantics.ActorRef` import is also removed (its only callers were the removed parser helpers). The remaining `safe_validate/1` private helper is KEPT — it's the validation gate, not a parser. `build_canonical_query/1` and `normalize_anonymous/1` are KEPT — they compute the new `:filter_query` socket assign.
- **New socket assigns `:match_count` and `:filter_query`** — initialized to `0` and `""` in `mount/3` so the first render before `handle_params/3` does not crash on `nil`; populated in the success branch of `handle_params/3`; reset to safe defaults in BOTH error branches (the `FilterParams.parse` `{:error, ...}` arm AND the `safe_validate` `{:error, ...}` arm) so stale values don't leak after invalid-filter form submit.
- **Three download anchors appended to `.button-cluster`** — `<.link href={"#{@base_path}/exports/changes.csv?#{@filter_query}"} download class="download-button">Download CSV</.link>` plus `:json` and `:ndjson` siblings. The HTML `download` attribute is present on each anchor (PR #2611 — keeps LV socket alive on click; without it, `wantsNewTab()` may return false and the LV may tear down). The button labels `"Download CSV"`, `"Download JSON"`, `"Download NDJSON"` are exact literals (D-22 + Plan 04 doc-contract). Hrefs are computed from `@base_path` (already set by `handle_params/3`) and `@filter_query` (set by Task 1's edit) — never re-derived inline.
- **Count status line** — `<div class="match-count-status" role="status">Showing <%= length(@streams.changes.inserts) %> of <%= format_count(@match_count) %> matches in this window.</div>` renders between the existing `<%= if @form_error do %>` / `<%= if filter-hint do %>` blocks AND the `<section class="timeline-rows">` block. `length(@streams.changes.inserts)` is the visible-row count (≤ `@page_size = 50` for the first page); `format_count/1` produces `"10,000+"` at the cap and thousands-separator integers below.
- **Two-band truncation banner** — band 1 (informational, neutral, `role="status"`) renders when `@match_count > 5_000 and @match_count < 10_001` with the literal `"Large export — will stream in chunks."` (em-dash U+2014, NOT two hyphens); band 2 (warning, amber, `role="alert"`) renders when `@match_count >= 10_001` with the literal `"Truncated to first 10,000 rows. Use \`mix threadline.export --max-rows N\` for the full window."`. Bands are mutually exclusive (D-18). At counts ≤ 5,000 neither band shows — the count line alone tells the operator "this is small enough for a sync download."
- **`format_count/1` private helper** — pure function: `count >= 10_001 -> "10,000+"`, otherwise `count |> Integer.to_string |> String.reverse |> String.codepoints |> Enum.chunk_every(3) |> Enum.map(&Enum.join/1) |> Enum.join(",") |> String.reverse`. Examples: `0 -> "0"`, `42 -> "42"`, `1234 -> "1,234"`, `5000 -> "5,000"`, `10000 -> "10,000"`, `10001 -> "10,000+"`, `1234567 -> "1,234,567"`.
- **CSS module extension** — four additive rules in `Threadline.OperatorSurface.Style`'s `~H` heredoc: `.threadline-ui .button-cluster .download-button` (secondary-bg neutral pill, `text-decoration: none` overrides default underline on `<.link href>`); `.threadline-ui .match-count-status` (muted body text, thin bottom border to separate from timeline rows); `.threadline-ui .truncation-banner` base (padding/margin/radius); `.threadline-ui .truncation-banner.informational` (neutral secondary palette); `.threadline-ui .truncation-banner.warning` (amber `#FEF3C7` / `#92400E` / `#F59E0B` — distinct from `.filter-error`'s destructive red per D-18). All four rules are namespaced to `.threadline-ui` (Phase 64 Footgun F-8).
- **Four new integration tests** — `timeline_live_test.exs` extended with Cases 15-18 (renumbered from plan-supplied 12-15 because those numbers were already used by Phase 64's BROWSE tests in this file). Case 15 asserts the three anchor labels + hrefs + `download` attribute via a `Regex.scan/2` over the rendered HTML. Case 16 seeds 7 changes in a uniquely-named table and asserts the `"Showing N of 7 matches in this window."` count line. Cases 17 and 18 (`@tag :slow`) bulk-seed 5,001 / 10,001 changes in uniquely-named tables and assert the band-1 informational / band-2 warning + `"10,000+"` approximation. New helper `bulk_seed_changes!/2` batches `Repo.insert_all/3` at 1,000 rows per batch (PG bind-parameter limit defense).

## Task Commits

1. **Tasks 1 + 2 (combined): TimelineLive handle_params parallel + render-block edits** — `b88dfa7` (feat). Single commit because Task 1's `format_count/1` helper is unused without Task 2's render edits — the per-task `mix compile --warnings-as-errors` gate would otherwise fail Task 1 standalone.
2. **Task 3: Style CSS rules** — `7a97ab5` (feat).
3. **Task 4: Four new integration tests** — `509e75c` (test).

## API Surface (final shapes)

### `Threadline.OperatorSurface.Live.TimelineLive` (file-scope wrapper UNCHANGED)

```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.TimelineLive do
    @moduledoc false
    use Phoenix.LiveView

    alias Threadline.Export
    alias Threadline.OperatorSurface.Exports.FilterParams
    alias Threadline.Query
    # alias Threadline.Semantics.ActorRef  ← REMOVED (only callers were the removed parser helpers)

    @page_size 50
    @filter_keys ~w(from to table actor_kind actor_id correlation_id)
    @default_window_hours 24

    def mount(_params, _session, socket) do
      # ... (unchanged) plus two new initial assigns:
      socket =
        socket
        # ... existing assigns ...
        |> assign(:match_count, 0)
        |> assign(:filter_query, "")

      {:ok, socket}
    end

    def handle_params(params, uri, socket) do
      # ... default-window canonicalization unchanged ...
      socket = assign(socket, :filters_raw, FilterParams.filters_raw_from_params(params))

      case FilterParams.parse(params) do
        {:error, message} ->
          # error branch — also assigns :match_count = 0, :filter_query = ""
          # ...

        {:ok, filters} ->
          case safe_validate(filters) do
            {:error, message} ->
              # error branch — also assigns :match_count = 0, :filter_query = ""
              # ...

            :ok ->
              # ... unchanged unknown_table_attempted + cursor reset ...

              count_task =
                Task.async(fn ->
                  Export.count_matching(filters, cap: 10_001, repo: socket.assigns.repo)
                end)

              page_task =
                Task.async(fn ->
                  Query.timeline_page(filters, scope_aware_opts(socket))
                end)

              {:ok, %{count: count}} = Task.await(count_task, 8_000)
              page = Task.await(page_task, 8_000)

              filter_query = build_canonical_query(socket.assigns.filters_raw)

              socket =
                socket
                |> assign(:filters, filters)
                |> assign(:form_error, nil)
                |> assign(:unknown_table_attempted, unknown_table_attempted)
                |> assign(:match_count, count)
                |> assign(:filter_query, filter_query)
                |> stream(:changes, page.entries, reset: true)
                |> assign(:cursor, page.next_cursor)

              {:noreply, socket}
          end
      end
    end

    # render/1 button cluster:
    #   <div class="button-cluster">
    #     <.link patch={@base_path} class="clear-link">Clear all</.link>
    #     <button type="submit">Apply</button>
    #     <.link href={"#{@base_path}/exports/changes.csv?#{@filter_query}"}    download class="download-button">Download CSV</.link>
    #     <.link href={"#{@base_path}/exports/changes.json?#{@filter_query}"}   download class="download-button">Download JSON</.link>
    #     <.link href={"#{@base_path}/exports/changes.ndjson?#{@filter_query}"} download class="download-button">Download NDJSON</.link>
    #   </div>
    #
    # render/1 count status line + two-band banner (between filter-hint and <section class="timeline-rows">):
    #   <div class="match-count-status" role="status">
    #     Showing <%= length(@streams.changes.inserts) %> of <%= format_count(@match_count) %> matches in this window.
    #   </div>
    #   <%= if @match_count > 5_000 and @match_count < 10_001 do %>
    #     <div class="truncation-banner informational" role="status">Large export — will stream in chunks.</div>
    #   <% end %>
    #   <%= if @match_count >= 10_001 do %>
    #     <div class="truncation-banner warning" role="alert">Truncated to first 10,000 rows. Use `mix threadline.export --max-rows N` for the full window.</div>
    #   <% end %>

    # Removed private helpers (lifted to FilterParams in Plan 01):
    #   filters_raw_from_params/1, normalize_params/1, parse_datetimes/1,
    #   parse_datetime_local/1, collapse_actor_ref/1, safe_actor_kind/1,
    #   build_filters/1

    # Kept private helpers:
    #   scope_aware_opts/1, scope_to_query_opts/1, default_repo/0,
    #   safe_validate/1, build_canonical_query/1, normalize_anonymous/2

    # New private helper:
    defp format_count(count) when is_integer(count) do
      cond do
        count >= 10_001 -> "10,000+"
        true ->
          count
          |> Integer.to_string()
          |> String.reverse()
          |> String.codepoints()
          |> Enum.chunk_every(3)
          |> Enum.map(&Enum.join/1)
          |> Enum.join(",")
          |> String.reverse()
      end
    end
  end
end
```

### `Threadline.OperatorSurface.Style` (additive CSS rules — public surface unchanged otherwise)

```css
.threadline-ui .button-cluster .download-button {
  padding: var(--tl-spacing-xs) var(--tl-spacing-md);
  background: var(--tl-color-secondary);
  color: var(--tl-color-text);
  border: 1px solid var(--tl-color-secondary);
  border-radius: 4px;
  text-decoration: none;
  cursor: pointer;
}

.threadline-ui .match-count-status {
  padding: var(--tl-spacing-sm) var(--tl-spacing-md);
  font-size: var(--tl-font-label);
  color: var(--tl-color-text-muted);
  border-bottom: 1px solid var(--tl-color-secondary);
}

.threadline-ui .truncation-banner {
  padding: var(--tl-spacing-sm) var(--tl-spacing-md);
  margin: var(--tl-spacing-sm) var(--tl-spacing-md);
  border-radius: 4px;
  font-size: var(--tl-font-label);
}

.threadline-ui .truncation-banner.informational {
  background: var(--tl-color-secondary);
  color: var(--tl-color-text-muted);
}

.threadline-ui .truncation-banner.warning {
  background: #FEF3C7;            /* amber-50 */
  color: #92400E;                 /* amber-800 */
  border-left: 3px solid #F59E0B; /* amber-500 */
}
```

## Verification

- `mix compile --warnings-as-errors` — **exits 0**.
- `mix verify.compile_no_optional` — **exits 0** (TimelineLive's existing file-scope gate on `Phoenix.LiveView` is preserved unchanged at line 1; the new `Task.async`/`Task.await` pair only runs at request time inside the LV process; no new optional-dep references introduced).
- `mix verify.format` — **exits 0** (touched files formatted; pre-existing repo-wide drift in untouched files outside this plan's scope remains scheduled for Phase 68 ADOPT-07).
- `mix test test/threadline/operator_surface/live/timeline_live_test.exs --max-failures 5` — **18/18 tests pass** in 1.9s (14 existing main-module Cases 1-9 + 11-14, 4 new Cases 15-18, 1 scoped Case 10).
- `mix verify.test` — **371/371 tests pass** in 3.1s (1 excluded `pgbouncer_topology` tag, 1 pre-existing unused-default-arg warning in `verify_coverage_task_test.exs` — out of plan scope). Net 4 new tests since Plan 65-02's 367-test baseline.

Greppable invariants verified:

- `head -1 lib/threadline/operator_surface/live/timeline_live.ex` → `if Code.ensure_loaded?(Phoenix.LiveView) do` (UNCHANGED).
- `grep -c "alias Threadline.OperatorSurface.Exports.FilterParams" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "alias Threadline.Export" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "alias Threadline.Semantics.ActorRef" lib/threadline/operator_surface/live/timeline_live.ex` → **0** (REMOVED).
- `grep -c "Task.async" lib/threadline/operator_surface/live/timeline_live.ex` → **2** (one for count, one for page).
- `grep -c "Task.await" lib/threadline/operator_surface/live/timeline_live.ex` → **3** (the two awaits + one in a comment context).
- `grep -c "cap: 10_001" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "8_000" lib/threadline/operator_surface/live/timeline_live.ex` → **3** (the two `Task.await` timeouts + one in the inline comment).
- `grep -c "FilterParams.parse" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "FilterParams.filters_raw_from_params" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "{:ok, %{count: count}}" lib/threadline/operator_surface/live/timeline_live.ex` → **1** (Pitfall 5 destructure).
- `grep -c "assign(:match_count" lib/threadline/operator_surface/live/timeline_live.ex` → **4** (mount + success branch + two error branches).
- `grep -c "assign(:filter_query" lib/threadline/operator_surface/live/timeline_live.ex` → **4** (mount + success branch + two error branches).
- `grep -c "defp format_count" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- Removed helpers — all **0**: `defp filters_raw_from_params`, `defp normalize_params`, `defp parse_datetimes`, `defp parse_datetime_local`, `defp collapse_actor_ref`, `defp safe_actor_kind`, `defp build_filters`.
- Kept helpers — all **1**: `defp safe_validate`, `defp build_canonical_query`, `defp scope_aware_opts`.
- `grep -c "Download CSV" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "Download JSON" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "Download NDJSON" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "/exports/changes.csv" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "/exports/changes.json" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "/exports/changes.ndjson" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -E '<\.link href=.*download ' lib/threadline/operator_surface/live/timeline_live.ex` → **3** matches (the bare `download` attribute on each anchor).
- `grep -c "match-count-status" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "truncation-banner informational" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "truncation-banner warning" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "Large export — will stream in chunks." lib/threadline/operator_surface/live/timeline_live.ex` → **1** (em-dash literal U+2014).
- `grep -c "Truncated to first 10,000 rows." lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "format_count(@match_count)" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "@match_count > 5_000" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "@match_count >= 10_001" lib/threadline/operator_surface/live/timeline_live.ex` → **1**.
- `grep -c "phx-change" lib/threadline/operator_surface/live/timeline_live.ex` → **0** (Phase 64 carry-forward / Footgun F-12).
- `grep -c "\.download-button" lib/threadline/operator_surface/style.ex` → **1**.
- `grep -c "\.match-count-status" lib/threadline/operator_surface/style.ex` → **1**.
- `grep -c "\.truncation-banner" lib/threadline/operator_surface/style.ex` → **3** (base + .informational + .warning).
- `grep -c '"Case 15:' test/threadline/operator_surface/live/timeline_live_test.exs` → **1**.
- `grep -c '"Case 16:' test/threadline/operator_surface/live/timeline_live_test.exs` → **1**.
- `grep -c '"Case 17:' test/threadline/operator_surface/live/timeline_live_test.exs` → **1**.
- `grep -c '"Case 18:' test/threadline/operator_surface/live/timeline_live_test.exs` → **1**.
- `grep -c "bulk_seed_changes!" test/threadline/operator_surface/live/timeline_live_test.exs` → **3** (1 helper definition + 2 callsites in Cases 17 + 18).
- `grep -c "insert_all" test/threadline/operator_surface/live/timeline_live_test.exs` → **2** (the bulk helper's call + module reference).
- `grep -c "@tag :slow" test/threadline/operator_surface/live/timeline_live_test.exs` → **2** (Cases 17 + 18 only).

## Decisions Made

- **Tasks 1 and 2 committed as ONE commit** — the `format_count/1` helper added in Task 1 is consumed only by Task 2's render markup. A Task-1-alone commit would fail `mix compile --warnings-as-errors` with an unused-helper warning. Per the plan's per-task verification gate (`mix compile --warnings-as-errors` exit 0), they had to land together. The combined commit message documents this explicitly so a future bisect operator sees the boundary clearly.
- **Test cases renumbered to 15-18** — plan-supplied numbers 12-15 already exist in this file (Phase 64 wrote Cases 12, 13, 14 for BROWSE-02 / BROWSE-03 history-entry / allowlist tests). Renumbering to 15-18 avoids `mix test` collision-by-name. Plan 04's doc-contract grep targets are case-body literals (`"Download CSV"` / `"Truncated to first 10,000"` / `"Large export — will stream in chunks."` / etc.), NOT case numbers — the renumber is safe.
- **Cases 17 and 18 use uniquely-named tables** — `bulk_band_info_<unique_int>` and `bulk_band_warn_<unique_int>` (via `System.unique_integer([:positive])`) so the bulk-seeded 5,001 / 10,001 rows do not pollute other tests' filter windows in this `async: true` test module that has no per-test cleanup. Without unique table names, Cases 17 and 18 could cause Cases 3 (`table=posts`) or 9 (`table=posts`) to see thousands of extra rows, breaking their assertions.
- **`bulk_seed_changes!/2` batches at 1,000 rows per `insert_all` call** — PostgreSQL's bind-parameter limit is 65,535 per query. The `AuditChange` schema has 8 fields per row, so 10,001 rows × 8 fields = 80,008 binds — over the limit. Batching at 1,000 rows = 8,000 binds per call, well under the limit. The plan's single-`insert_all/3` shape would have crashed at the second test (Case 18, 10,001 rows). Auto-fixed inline; this is a Rule 1 bug in the plan-supplied test stub.
- **Amber hex literals (`#FEF3C7` / `#92400E` / `#F59E0B`) added inline** — discretion permitted by CONTEXT.md and RESEARCH §P-3 line 433-435. The alternative (promoting to three new `--tl-color-warning*` CSS variables in the `:root`-equivalent at the top of the Style module) would expand the variable set Phase 64 froze; keeping the variables stable across phases reduces the doc-contract test surface area Plan 04 has to assert. The hex values are documented inline with `/* amber-50 */` etc. comments so a Tailwind-fluent reader recognizes the palette family.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan-supplied test Case numbers 12-15 collide with existing Phase 64 cases**

- **Found during:** Task 4 (writing the new test cases)
- **Issue:** The plan asked for new Cases numbered 12, 13, 14, 15. But the existing `timeline_live_test.exs` already contains `"Case 12:"`, `"Case 13:"`, and `"Case 14:"` (Phase 64 wrote them for BROWSE-02 / BROWSE-03 — allowlist-drop, one-Apply-one-history-entry, history-round-trip). Adding new tests with the same case numbers would produce duplicate test names in `mix test` output and confuse `--seed`-based reruns.
- **Fix:** Renumbered the four new cases to 15, 16, 17, 18. Plan 04's doc-contract grep targets are case-body literals (`"Download CSV"` etc.), not case numbers, so the renumber does not break Plan 04's assertions.
- **Files modified:** test/threadline/operator_surface/live/timeline_live_test.exs (only)
- **Verification:** `mix test test/threadline/operator_surface/live/timeline_live_test.exs --max-failures 5` — 18/18 tests pass; no duplicate-name warnings.
- **Committed in:** 509e75c (Task 4 commit; the renumber is documented in the commit message)

**2. [Rule 1 - Bug] Plan-supplied `bulk_seed_changes!/2` would crash on PG bind-parameter limit at 10,001 rows**

- **Found during:** Task 4 (test stub authoring)
- **Issue:** The plan's stub called `repo.insert_all(AuditChange, changes)` once with the full `changes` list. PostgreSQL's bind-parameter limit is 65,535 per query; the `AuditChange` schema has 8 fields per row, so 10,001 rows × 8 fields = 80,008 binds — over the limit. Case 18 would have crashed with `(Postgrex.Error) ERROR 08P01 (protocol_violation)`.
- **Fix:** Batch the inserts in chunks of 1,000 rows (8,000 binds per call, well under the limit). The bulk helper now does `changes |> Enum.chunk_every(1_000) |> Enum.each(fn chunk -> repo.insert_all(...) end)`.
- **Files modified:** test/threadline/operator_surface/live/timeline_live_test.exs (only)
- **Verification:** Cases 17 and 18 both pass; `mix test` runtime for Cases 17 + 18 is ~150ms each (target was ~100ms per RESEARCH §P-10; the chunking adds negligible overhead).
- **Committed in:** 509e75c

**3. [Rule 1 - Bug] Plan-supplied `~r|...|s` regex with `|` alternation collides with sigil delimiter**

- **Found during:** Task 4 (Case 15 — `Regex.scan` over the rendered HTML)
- **Issue:** The plan-supplied regex `~r|<a [^>]*\bdownload\b[^>]*>Download (CSV|JSON|NDJSON)</a>|` uses `|` as both the sigil delimiter and the regex alternation operator. Elixir's parser treats the first `|` after `(CSV` as the sigil close, raising `MismatchedDelimiterError`.
- **Fix:** Switched the sigil delimiter from `|...|` to `{...}`: `~r{<a [^>]*\bdownload\b[^>]*>Download (CSV|JSON|NDJSON)</a>}s`. Curly braces are not used inside the regex, so the delimiter is unambiguous.
- **Files modified:** test/threadline/operator_surface/live/timeline_live_test.exs (only)
- **Verification:** Case 15 compiles and passes; the regex matches all three anchors as intended.
- **Committed in:** 509e75c

---

**Total deviations:** 3 auto-fixed (all Rule 1 bugs in plan-supplied test stubs; each pre-empts a regression that would have surfaced as a `mix test` collision, a PG protocol error, or a compile error).
**Impact on plan:** No scope creep. All three fixes are local to `timeline_live_test.exs`. Plan 04's doc-contract assertions remain accurate because they target case-body literals, not case numbers, and the bulk helper's behavior (insert N rows in audit_changes) is unchanged from the plan's intent.

## Issues Encountered

None beyond the three auto-fixed deviations above. The combined Tasks 1+2 commit was a deliberate decision (documented in the commit message and SUMMARY) rather than a deviation — the plan's per-task `mix compile --warnings-as-errors` gate implicitly required them to land together because of the unused-helper warning.

## Threat Flags

None. The LV's render block introduces three new download anchors, but they target the controller routes Plan 02 already secured behind `Threadline.OperatorSurface.ExportAuthPlug` (same auth contract as the LV mount via D-20 dispatch). The `Task.async`/`Task.await` pair runs inside the LV process and inherits the LV's caller process's `:authorize_fn`-derived scope via `socket.assigns` — no new auth surface.

The two new socket assigns (`:match_count` and `:filter_query`) are read-only data derived from the operator's input; `:match_count` is bounded by the `cap: 10_001` opt and `:filter_query` is the byte-equivalent re-encoding of the URL the operator just submitted (not derived from any DB content). No PII or audit-data leakage path introduced.

## Self-Check: PASSED

All claimed files exist and are in their expected state:

- `lib/threadline/operator_surface/live/timeline_live.ex` — modified, contains `alias Threadline.OperatorSurface.Exports.FilterParams`, `Task.async`, `cap: 10_001`, `defp format_count`, `Download CSV`, `match-count-status`, `truncation-banner informational`, `truncation-banner warning`, `Large export — will stream in chunks.`, `Truncated to first 10,000 rows.`. Removed: seven private parser helpers + `alias Threadline.Semantics.ActorRef`. NO `phx-change` literal anywhere.
- `lib/threadline/operator_surface/style.ex` — modified, contains `.threadline-ui .button-cluster .download-button`, `.threadline-ui .match-count-status`, `.threadline-ui .truncation-banner`, `.threadline-ui .truncation-banner.informational`, `.threadline-ui .truncation-banner.warning` rules.
- `test/threadline/operator_surface/live/timeline_live_test.exs` — modified, contains `Case 15:`, `Case 16:`, `Case 17:`, `Case 18:` test names plus the new `bulk_seed_changes!/2` helper.

All claimed commits found in `git log`:

- `b88dfa7` — Tasks 1 + 2 (combined feat commit; documented in commit message).
- `7a97ab5` — Task 3 (CSS).
- `509e75c` — Task 4 (tests).

## Next-Plan Readiness

- **Plan 65-04 (doc-contract test trifecta):** Will assert (a) the three button-label literals via doc-contract regex over `lib/threadline/operator_surface/live/timeline_live.ex` (`Download CSV` / `Download JSON` / `Download NDJSON`); (b) the count line text via doc-contract (`Showing` + `matches in this window.`) and the two banner literals via doc-contract (`Large export — will stream in chunks.` + `Truncated to first 10,000 rows.`); (c) the `download` HTML attribute on each anchor via doc-contract regex (`<.link href=.*download `); (d) `phx-change` absence via doc-contract refute (`grep -c "phx-change" → 0`); (e) the controller content-type literals via doc-contract over `lib/threadline/operator_surface/controllers/export_controller.ex` (`text/csv; charset=utf-8` etc., already shipped in Plan 02); (f) Mix-task `mix threadline.export` vs controller byte-equality via the EXPO-05 parity test — the latter relies on `Threadline.Export.stream_export_rows/2` (Plan 02) AND `Threadline.OperatorSurface.Exports.FilterParams.parse/1` (Plan 01) being byte-equivalent across the LV ↔ Mix-task ↔ controller surfaces, which this plan made a structural guarantee by deleting TimelineLive's private parser helpers and delegating to `FilterParams`.

---

*Phase: 65-exports-ui-parity*
*Completed: 2026-05-07*
