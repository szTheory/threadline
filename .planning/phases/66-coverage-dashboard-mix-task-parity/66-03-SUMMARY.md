---
phase: 66
plan: 03
subsystem: operator-surface-coverage
tags:
  - elixir
  - threadline
  - liveview
  - phoenix
  - operator-surface
  - coverage
  - polling
  - on-mount-hook
requires:
  - 66-01
provides:
  - "Threadline.OperatorSurface.Coverage.Snapshot struct (pure stdlib, no LV gate per D-36)"
  - "Threadline.OperatorSurface.Coverage.OnMount on_mount/4 hook (LV-gated; 30s polling via attach_hook(:handle_info))"
  - "Threadline.OperatorSurface.Components.SurfaceHeader function component (LV-gated; locked literals)"
  - "Threadline.OperatorSurface.Live.CoverageLive (LV-gated; /coverage; three-bucket dashboard with locked literals)"
  - "Router live_session :threadline on_mount: list extended with Coverage.OnMount AFTER Auth"
  - "Router /coverage route inside operator-surface scope"
  - "style.ex --tl-header-height: 36px CSS variable + .timeline-toolbar offset edit + 8 new rules"
affects:
  - "66-04 sibling LV one-liner edits + LV integration tests (will mount <.surface_header /> on TimelineLive/TransactionLive/ActorLive)"
  - "66-05 doc-contract test (will pin Plan 03's locked literals from source)"
tech-stack:
  added: []
  patterns:
    - "Phoenix.LiveView.attach_hook(:threadline_coverage_refresh, :handle_info, ...) for cross-LV per-session polling"
    - "Process.send_after(self(), :threadline_refresh_coverage, interval) + Process.cancel_timer/1 race-prevention on manual refresh"
    - "try/rescue ALWAYS-reschedule keep-last-good error policy (T-66-14 mitigation)"
    - "Application.get_env(:threadline, :coverage_poll_ms, 30_000) test seam (Pitfall 13)"
    - "Two-layer schema validation: regex ~r/\\A[a-z_][a-z0-9_]{0,62}\\z/ + parameterized pg_namespace lookup (T-66-12)"
    - "File-scope `if Code.ensure_loaded?(Phoenix.LiveView) do defmodule … end end` gate on three new LV-touching files (Snapshot is pure stdlib, no gate per D-36)"
    - "Anchored amber palette (#FEF3C7/#92400E/#F59E0B) on .surface-badge--warn mirroring Phase 65 .truncation-banner.warning"
key-files:
  created:
    - "lib/threadline/operator_surface/coverage/snapshot.ex"
    - "lib/threadline/operator_surface/coverage/on_mount.ex"
    - "lib/threadline/operator_surface/components/surface_header.ex"
    - "lib/threadline/operator_surface/live/coverage_live.ex"
  modified:
    - "lib/threadline/operator_surface/router.ex"
    - "lib/threadline/operator_surface/style.ex"
    - ".gitignore"
decisions:
  - "Anchored gitignore 'coverage/' rule to '/coverage/' so the new lib/threadline/operator_surface/coverage/ subdir is not silently excluded (Rule 3)"
  - "attach_hook(:threadline_coverage_refresh, :handle_info, ...) on a single line so Plan 05's doc-contract grep matches the literal verbatim"
  - "Snapshot @doc string explicitly names from_coverage/2 so the acceptance criterion `grep -c from_coverage >= 2` holds across formatter passes"
metrics:
  duration: ~7 min
  completed: 2026-05-07T17:50:00Z
  tasks: 3
  files: 7
  full_suite: "433 tests / 0 failures (1 excluded — pgbouncer_topology)"
---

# Phase 66 Plan 03: Coverage Dashboard LV Surface Summary

The load-bearing slice of Phase 66's LV surface ships clean: pure-stdlib `Threadline.OperatorSurface.Coverage.Snapshot` (`covered_count/uncovered_count/expected_uncovered_count/last_checked_at/error/tables` keyword list grouped by bucket; `from_coverage/2` + `empty/1` constructors; NO `Code.ensure_loaded?(Phoenix.LiveView)` gate per D-36 so future Mix-task surfaces can read it); LV-gated `Threadline.OperatorSurface.Coverage.OnMount` `on_mount/4` hook driving 30-second polling via `Process.send_after(:threadline_refresh_coverage)` + `attach_hook(:threadline_coverage_refresh, :handle_info, &handle_refresh/2)` so a single ticker per LV process services every LV in the `:threadline` session; LV-gated `Threadline.OperatorSurface.Components.SurfaceHeader` function component with the locked badge literals (`"All covered"` / `"<n> uncovered"`) linking to `"#{base_path}/coverage"` plus a stale indicator under `:threadline_coverage_error`; LV-gated `Threadline.OperatorSurface.Live.CoverageLive` mounting at `/coverage` with the three locked badge state literals (`"covered"`, `"uncovered"`, `"expected"`), the page heading `"Coverage — schema: {name}"`, the manual `"Refresh"` anchor (with `Process.cancel_timer/1` race-prevention per Pitfall 6), the on-error inline truncation-banner with the locked copy, and two-layer schema validation (regex + parameterized `pg_namespace` lookup) closing the SQL-injection surface; router with `Coverage.OnMount` appended AFTER `Auth` in the `on_mount:` list (Pitfall 7) and the new `/coverage` route inside the existing scope; and `style.ex` extended with `--tl-header-height: 36px`, the `.timeline-toolbar` `top:` offset edit, and 8+ new rules covering the surface header, three badge variants, and the coverage-table layout. Atom-safety + SQL-injection refutes both clean across the four new/edited Phase 66 source files. Full `mix test` is 433 tests / 0 failures (1 excluded — `pgbouncer_topology`), matching Plan 01's baseline byte-for-byte.

## What Shipped

### (a) Pure-stdlib `Snapshot` struct

`lib/threadline/operator_surface/coverage/snapshot.ex` — a `defstruct` with `:covered_count`, `:uncovered_count`, `:expected_uncovered_count`, `:last_checked_at`, `:error`, `:tables` (keyword list `[covered: [], uncovered: [], expected_uncovered: []]`). NO file-scope `Code.ensure_loaded?(Phoenix.LiveView)` gate per D-36 — capture-only adopters and future Mix-task surfaces (`mix threadline.health.coverage`) need the struct without paying for a Phoenix dep.

`from_coverage/2` reduces a `Threadline.Health.trigger_coverage/1` result list (the Plan-01 three-bucket shape) into the bucket counts and sorted tables; `empty/1` returns a zeroed snapshot with optional `:last_checked_at` for the very-first-render-under-error path.

### (b) `Coverage.OnMount` hook with ALWAYS-reschedule + test seam

`lib/threadline/operator_surface/coverage/on_mount.ex` — file-scope LV-gated. Drives polled `Threadline.Health.trigger_coverage/1` on a default 30-second interval (configurable via `Application.get_env(:threadline, :coverage_poll_ms, 30_000)` — the test seam from Pitfall 13 — or per-mount socket assign `:threadline_coverage_poll_ms`). Floor 5_000 ms enforced at mount via `poll_interval!/1` raising `ArgumentError`.

The polling pattern is `Process.send_after(self(), :threadline_refresh_coverage, interval)` to schedule + `attach_hook(:threadline_coverage_refresh, :handle_info, &handle_refresh/2)` to intercept. The `handle_refresh/2` private function runs `refresh_coverage/1` (which returns the rescued/keep-last-good socket), then unconditionally reschedules via another `Process.send_after`, matching the locked `:threadline_refresh_coverage` tick atom and `:threadline_coverage_refresh` hook name from CONTEXT.md.

On poll error (RESEARCH Pitfall 4): keep the previous `:threadline_coverage` assign untouched (last-good), set `:threadline_coverage_error` to the exception message, emit `[:threadline, :health, :checked, :error]` via `Threadline.Telemetry.emit_health_checked_error/1` (Plan 01's new sibling event), and ALWAYS reschedule. The `@moduledoc` documents this as the "ALWAYS reschedules" guarantee — the acceptance criterion `grep -c "ALWAYS reschedule\|always reschedule"` returns `2` (one in the `## Error policy` heading, one in the rationale paragraph).

### (c) `SurfaceHeader` function component with locked literals

`lib/threadline/operator_surface/components/surface_header.ex` — file-scope LV-gated `Phoenix.Component`. Renders a `<header class="threadline-ui-header">` containing the brand label, a coverage badge anchored to `"#{base_path}/coverage"`, and (when `:threadline_coverage_error` is set) a small "stale (last checked Xs ago)" indicator. The badge has two locked-literal forms:

- `uncovered_count == 0` → `<a class="surface-badge surface-badge--ok" href="#{base_path}/coverage">All covered</a>` (D-31a — never hidden, even when there's nothing to flag).
- `uncovered_count > 0`  → `<a class="surface-badge surface-badge--warn" href="#{base_path}/coverage"><%= @coverage.uncovered_count %> uncovered</a>` — matches the doc-contract regex `~r/\d+ uncovered/`.

Plan 05's doc-contract test will `grep -F` the literals `All covered`, `surface-badge surface-badge--ok`, `surface-badge surface-badge--warn` from this source verbatim.

### (d) `CoverageLive` three-bucket dashboard with locked literals

`lib/threadline/operator_surface/live/coverage_live.ex` — file-scope LV-gated, mounts at `/coverage`. Mirrors the `timeline_live.ex` shape (single render function, `~H` template, base_path resolution from `URI.parse/1` on the request URI) but holds none of TimelineLive's stream/cursor machinery (the coverage list is small enough to render in one pass).

Locked literals (each pinned by Plan 05's doc-contract test from source):

| Literal                                                                                          | CONTEXT D-ID         | Render context                        |
| ------------------------------------------------------------------------------------------------ | -------------------- | ------------------------------------- |
| `<td>covered</td>` / `<td>uncovered</td>` / `<td>expected</td>`                                  | D-32d                | three badge state strings in tbody    |
| `Coverage — schema: {name}`                                                                      | D-33                 | page heading                          |
| `Refresh` (anchor with `phx-click="refresh"`)                                                    | D-30b                | manual refresh affordance             |
| `Coverage check failed at {now} — showing last successful result from {last_checked_at}.`        | D-30c                | on-poll-error inline strip            |
| `Schema 'X' not found.`                                                                          | D-33a                | regex/pg_namespace validator output   |
| `Coverage: N covered, M uncovered, K expected uncovered`                                         | D-34                 | summary footer                        |
| `No audited tables found for schema 'X'. Run mix threadline.gen.triggers to set up capture.`     | UI-SPEC empty state  | rendered when all three buckets are 0 |
| `live("/coverage", CoverageLive, :index)`                                                        | D-35                 | router scope literal                  |

`handle_event("refresh", ...)` cancels the pending `:threadline_timer_ref` before refetching (Pitfall 6 — manual refresh races a tick), then reschedules using the same interval source the `OnMount` hook uses. `Process.cancel_timer/1` is idempotent on already-fired timers (returns `false`) so it's safe to call unconditionally.

### (e) Two-layer schema validation closes the SQL-injection edge

`handle_params/3` reads `?schema=NAME` (default `"public"`) and validates via:

1. Regex `@schema_regex ~r/\A[a-z_][a-z0-9_]{0,62}\z/` (62 chars matches PostgreSQL identifier max, leaving room for the leading char; rejects bytes outside the lowercase-identifier safe set).
2. Parameterized `Ecto.Adapters.SQL.query!(repo, "SELECT 1 FROM pg_namespace WHERE nspname = $1 LIMIT 1", [schema])` — bind list, never string interpolation.

On any validation failure the LV renders `<div class="filter-error" role="alert">Schema 'X' not found.</div>` and DOES NOT call `Threadline.Health.trigger_coverage/1` with the bad input. The SQL-injection refute (`grep -E "nspname = '#" lib/threadline/operator_surface/live/coverage_live.ex`) is empty. T-66-12 mitigation holds.

Schema strings stay binary throughout — `Map.get(params, "schema", ...)` reads string keys, the regex matches strings, the SQL bind is a binary. Atom-safety refute clean (`grep -E "String\\.to_atom\\b"` over all four new/edited Phase 66 source files returns nothing). T-66-13 mitigation holds.

### (f) Router on_mount order locked + new `/coverage` route

`lib/threadline/operator_surface/router.ex` — `live_session :threadline` block now reads:

```elixir
live_session :threadline,
  on_mount: [
    {Threadline.OperatorSurface.Auth, unquote(opts)},
    {Threadline.OperatorSurface.Coverage.OnMount, unquote(opts)}
  ] do
  scope unquote(path), alias: Threadline.OperatorSurface.Live do
    live("/", TimelineLive, :index)
    live("/coverage", CoverageLive, :index)
    live("/transactions/:id", TransactionLive, :show)
    ...
  end
end
```

`Auth` runs FIRST (Pitfall 7 — populates `:threadline_repo` from opts so `Coverage.OnMount`'s `resolve_repo/1` can read it). The `awk` line-ordering acceptance criterion (`Auth, unquote(opts)` line < `Coverage.OnMount, unquote(opts)` line) returns `ORDER OK`. The Phase 65 sibling controller scope (`/exports/changes.csv|json|ndjson`), the `pipeline :threadline_exports`, and the `:authorize_fn` / `pipe_through` / `:adopter_acknowledges_unauthenticated` gating — all preserved untouched.

### (g) Style.ex grows the variable + 8 new rules; Phase 64/65 styles intact

`lib/threadline/operator_surface/style.ex` — three additive edits:

1. `--tl-header-height: 36px` declaration added inside the existing `.threadline-ui` CSS-variable block (does NOT create a duplicate `.threadline-ui` block or `:root` rule).
2. `.threadline-ui .timeline-toolbar { top: 0 }` → `top: var(--tl-header-height, 36px)` so Phase 64/65's sticky filter toolbar slots correctly under the new surface header.
3. Eight new rules at the end of the `<style>` block (after the existing `.timeline-rows` / `.change-time` rules):
   - `.threadline-ui-header` (sticky surface header at viewport `top: 0`, height `var(--tl-header-height)`, flex layout for brand + badge + stale-indicator)
   - `.threadline-ui-header .brand` (font-weight 600)
   - `.threadline-ui-header .stale-indicator` (muted text)
   - `.threadline-ui .surface-badge` (base — pill shape, right-aligned via `margin-left: auto`)
   - `.threadline-ui .surface-badge--ok` (transparent background, muted border)
   - `.threadline-ui .surface-badge--warn` (amber `#FEF3C7` / `#92400E` / `#F59E0B` mirroring Phase 65 `.truncation-banner.warning`)
   - `.threadline-ui .coverage-page` (page padding)
   - `.threadline-ui .coverage-table` + `.coverage-table th` + `.coverage-table td` (table layout, monospace td, header treatment)
   - `.threadline-ui .coverage-row--covered` / `--uncovered` / `--expected` (per-bucket row tint)

Phase 64/65 style preservation regression check passed — `.truncation-banner` (3 occurrences), `.match-count-status` (1), `.button-cluster` (3), and the amber palette literals (`#FEF3C7`/`#92400E`/`#F59E0B` each appear ≥ 2 times: once in `.truncation-banner.warning`, once in `.surface-badge--warn`) are all intact.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] gitignore 'coverage/' silently excluded the new module subdirectory**

- **Found during:** Task 1 commit prep (`git status` showed only `components/` as untracked, but `coverage/` was missing despite `lib/threadline/operator_surface/coverage/{snapshot,on_mount}.ex` existing on disk).
- **Issue:** `.gitignore:40` had `coverage/` (unanchored), which excludes any directory named `coverage` anywhere in the tree — including the new `lib/threadline/operator_surface/coverage/` subdirectory. `git check-ignore -v` confirmed: `.gitignore:40:coverage/	lib/threadline/operator_surface/coverage/snapshot.ex`.
- **Fix:** Anchored the rule to `/coverage/` so it only matches the project-root ExCoveralls output dir (its actual intent), not any nested directory. Bundled into Task 1's commit alongside the new modules.
- **Files modified:** `.gitignore`
- **Commit:** `8fccb28` (Task 1)
- **Rationale:** Without this fix the entire `Coverage.OnMount` + `Snapshot` module hierarchy would be invisible to git and silently absent from the merged worktree. Rule 3 — a blocking issue preventing the task from completing — auto-fix is the correct disposition. No alternative ExCoveralls-output path exists for the project (no `cover/` or `_build/coverage/` substitute), so anchoring to `/coverage/` matches the intent and removes the false-positive on the new lib subdir.

**2. [Rule 1 — Bug] `attach_hook` literal must appear single-line for doc-contract grep to match**

- **Found during:** Task 1 acceptance verification (the criterion `grep -F "attach_hook(:threadline_coverage_refresh, :handle_info" lib/threadline/operator_surface/coverage/on_mount.ex` returned empty).
- **Issue:** Initial implementation used the multi-line pipe form Phoenix.LiveView's docs prefer:
  ```elixir
  socket
  |> Phoenix.Component.assign(:threadline_timer_ref, ref)
  |> attach_hook(
    :threadline_coverage_refresh,
    :handle_info,
    &handle_refresh/2
  )
  ```
  The formatter wrapped each argument onto its own line, breaking the single-line literal that the doc-contract grep depends on.
- **Fix:** Collapsed the `attach_hook` arguments to a single line. The line `|> attach_hook(:threadline_coverage_refresh, :handle_info, &handle_refresh/2)` is 86 columns, well under the 98-column formatter limit, so the formatter preserves it. Added an inline comment explaining the literal-grep dependency to defend against future re-wrappings.
- **Files modified:** `lib/threadline/operator_surface/coverage/on_mount.ex`
- **Commit:** `8fccb28` (Task 1)
- **Rationale:** Plan 05's doc-contract test will assert exact source-string presence; if the formatter wraps this literal in a future change the test will fail and the wrap will be the visible cause. The inline comment makes that contract explicit. Rule 1 — the literal-grep acceptance criterion failed without the fix — auto-fix is the correct disposition.

**3. [Rule 1 — Bug] Snapshot `@doc` rephrased so `grep -c "from_coverage" >= 2` holds**

- **Found during:** Task 1 acceptance verification (the criterion `grep -c "from_coverage" lib/threadline/operator_surface/coverage/snapshot.ex` returned `1`, not `>= 2`).
- **Issue:** The `@doc` for `from_coverage/2` described the behavior without naming the function in the prose; only the `def from_coverage(...)` line contained the literal token, so the grep returned 1.
- **Fix:** Rephrased the `@doc` to lead with the literal `from_coverage/2 — ...` so the function name appears in both the doc and the def. The grep now returns 2.
- **Files modified:** `lib/threadline/operator_surface/coverage/snapshot.ex`
- **Commit:** `8fccb28` (Task 1)
- **Rationale:** The plan's acceptance criterion is `grep -c "from_coverage" >= 2 (def + clauses or doc)`. The "doc" branch was the intended path here (Snapshot has only one `from_coverage` clause). Rule 1 fix.

### Pre-existing format drift outside scope

`mix verify.format` reports drift in `test/threadline/health_test.exs` — a Plan-01 file modified before this plan opened. The drift is unrelated to Plan 03's six file modifications and is in scope for Phase 68 (ADOPT-07 repo-wide format drift cleanup) per the v1.18 milestone plan. Not auto-fixed (per the scope-boundary rule — only files DIRECTLY modified by this plan's changes). All six Plan 03 files (`snapshot.ex`, `on_mount.ex`, `surface_header.ex`, `coverage_live.ex`, `router.ex`, `style.ex`) pass `mix format --check-formatted` cleanly.

### Flaky telemetry test seen once during run

A single run of `mix test test/threadline/operator_surface/` (seed 455349) reported one failure in `export_auth_plug_test.exs` ("case 3: scope_keys"). Subsequent runs of both the full operator-surface suite (seed 455349) and the export_auth_plug_test alone returned 0 failures consistently. Re-running the same test on the main worktree (commit `c1d0730`) at the same baseline also returned 0 failures. The failure pattern is consistent with a transient telemetry-handler-ordering flake in the existing test suite (a Phase 65 test concern), unrelated to Plan 03's changes — `lib/threadline/operator_surface/export_auth_plug.ex` is not modified by this plan, and Plan 03's six file edits do not touch any telemetry handler attachment logic. Documented here for traceability; not a regression and not auto-fixed.

## Tasks → Commits

| Task | Description                                                                   | Commit    |
| ---- | ----------------------------------------------------------------------------- | --------- |
| 1    | Snapshot struct + Coverage.OnMount hook + SurfaceHeader function component    | `8fccb28` |
| 2    | CoverageLive three-bucket dashboard at `/coverage`                            | `513f64f` |
| 3    | Router on_mount/route edits + style.ex CSS extension                          | `beb2ba7` |

## Plan-Level Verification Results

| Check                                                                                           | Status                                                |
| ----------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| `mix compile --warnings-as-errors`                                                              | clean (51 files compile)                              |
| `mix verify.compile_no_optional`                                                                | clean (51 files; the three new LV-gated files skip cleanly absent Phoenix; Snapshot compiles unconditionally) |
| `mix verify.format` (Plan 03 files only)                                                        | clean (6/6 files)                                     |
| `awk` on_mount order check (Auth before Coverage.OnMount in router.ex)                          | `ORDER OK`                                            |
| Atom-safety refute over `snapshot.ex`/`on_mount.ex`/`surface_header.ex`/`coverage_live.ex`      | empty (T-66-13)                                       |
| SQL-injection refute (`nspname = '#` over `coverage_live.ex`)                                   | empty (T-66-12)                                       |
| `mix help` lists all `mix threadline.*` tasks without errors                                    | clean (8 threadline tasks listed)                     |
| Existing operator-surface tests (`mix test test/threadline/operator_surface/`)                  | 122 tests / 0 failures                                |
| Full `mix test` (no regressions)                                                                | 433 tests / 0 failures (1 excluded — pgbouncer_topology) — matches Plan 01 baseline byte-for-byte |
| Phase 65 style preservation (`.truncation-banner` + `.match-count-status` + `.button-cluster`)  | all preserved                                         |
| Amber palette preserved (`#FEF3C7` / `#92400E` / `#F59E0B` ≥ 2 each)                            | all preserved                                         |

## Self-Check: PASSED

**Files created:**

- FOUND: `lib/threadline/operator_surface/coverage/snapshot.ex`
- FOUND: `lib/threadline/operator_surface/coverage/on_mount.ex`
- FOUND: `lib/threadline/operator_surface/components/surface_header.ex`
- FOUND: `lib/threadline/operator_surface/live/coverage_live.ex`

**Files modified:**

- FOUND modifications in `lib/threadline/operator_surface/router.ex` (live_session on_mount: list + new `/coverage` route)
- FOUND modifications in `lib/threadline/operator_surface/style.ex` (`--tl-header-height` variable + `.timeline-toolbar top:` edit + 8 new rules)
- FOUND modifications in `.gitignore` (anchored `coverage/` → `/coverage/`)

**Commits:**

- FOUND: `8fccb28` — feat(66-03): add Snapshot struct, Coverage.OnMount hook, SurfaceHeader component
- FOUND: `513f64f` — feat(66-03): add CoverageLive — three-bucket dashboard at /coverage
- FOUND: `beb2ba7` — feat(66-03): wire CoverageLive into router + extend style.ex
