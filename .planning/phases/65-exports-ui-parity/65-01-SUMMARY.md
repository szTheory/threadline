---
phase: 65-exports-ui-parity
plan: 01
subsystem: api
tags: [elixir, ecto, exports, csv, json, filter-params, pure-helpers]

# Dependency graph
requires:
  - phase: 14-export
    provides: "Threadline.Export module with timeline-filter parity (count_matching/2, to_csv_iodata/2, to_json_document/2, stream_changes/2)"
  - phase: 25-loop-correlation
    provides: ":correlation_id timeline-filter branch (preserved by the additive :cap opt)"
  - phase: 64-raw-timeline-browse
    provides: "Inline URL-params parser inside TimelineLive (lifted out into FilterParams in this plan)"
provides:
  - "Threadline.Export.count_matching/2 :cap keyword opt (windowed-count subquery, default unbounded)"
  - "Threadline.OperatorSurface.Exports.Filename pure-stdlib helper (canonical UTC-minute filename)"
  - "Threadline.OperatorSurface.Exports.FilterParams pure-stdlib shared parser (LV ↔ controller byte equality)"
affects:
  - 65-02-export-controller
  - 65-03-timeline-live-export-buttons
  - 65-04-doc-contract-parity-tests

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure-stdlib helper modules under lib/threadline/operator_surface/exports/ — no file-scope Code.ensure_loaded? gate (D-21)"
    - "Windowed-count subquery via from(sub in subquery(... |> limit(^cap)), select: count()) — NOT EXISTS LIMIT N"
    - "URL params -> filter keyword list: shared parser, byte-equivalent across LV and controller surfaces"

key-files:
  created:
    - lib/threadline/operator_surface/exports/filename.ex
    - lib/threadline/operator_surface/exports/filter_params.ex
    - test/threadline/operator_surface/exports/filename_test.exs
    - test/threadline/operator_surface/exports/filter_params_test.exs
  modified:
    - lib/threadline/export.ex
    - test/threadline/export_test.exs

key-decisions:
  - "Windowed-count subquery (from(sub in subquery(... |> limit(^cap)), select: count())) instead of EXISTS LIMIT 10001 — RESEARCH Pitfall 8 caught D-23's wrong SQL (EXISTS returns boolean, not count)."
  - "Default :cap = nil keeps Mix task and capture-only adopters unaffected — :cap is opt-in only on the LV/controller path."
  - "Both new helper modules are pure stdlib, no file-scope Code.ensure_loaded?(Phoenix.LiveView) wrapper — diverges from sibling timeline_live.ex on purpose (D-21)."
  - "Atom safety: FilterParams uses String.to_existing_atom/1 only (3 call sites, including allowlist normalization). The bare String.to_atom token never appears anywhere in the source — moduledoc rephrased to keep the word-boundary regex test refute clean."
  - "FilterParams.parse/1 lifted byte-equivalently from timeline_live.ex:264-393 so the EXPO-05 parity test is a structural guarantee (Plan 04), not a hand-copy guard (RESEARCH Pitfall 3)."

patterns-established:
  - "Optional-deps gate posture: pure-stdlib helpers under lib/threadline/operator_surface/exports/ stay file-scope-ungated; behavioral modules under lib/threadline/operator_surface/live/ stay file-scope-gated. Doc-contract test in Plan 04 will lock both halves."
  - "Atom-safety in-source regex refute: tests grep the source file for the unsafe variant via ~r/String\\.to_atom\\b/ and refute. The moduledoc cannot mention the bare token literally — rephrase or qualify."

requirements-completed: [EXPO-04]

# Metrics
duration: ~5 min
completed: 2026-05-07
---

# Phase 65 Plan 01: Exports UI Parity — Library + Helper Foundation Summary

**Additive `:cap` opt on `Threadline.Export.count_matching/2` (windowed-count subquery, default unbounded) plus two pure-stdlib helpers (`Filename.for/2` for canonical UTC-minute export filenames; `FilterParams.parse/1` shared URL-params parser lifted byte-equivalently from `TimelineLive`) — the lib-side foundation Plans 02, 03, and 04 build on.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-07T13:14:28Z
- **Completed:** 2026-05-07T13:19:35Z
- **Tasks:** 3
- **Files modified/created:** 6 (2 modified, 4 created)

## Accomplishments

- **`Threadline.Export.count_matching/2` `:cap` opt** — additive keyword option that clamps the count via `from(sub in subquery(... |> limit(^cap)), select: count()) |> repo.one()`. Default `nil` preserves the existing unbounded `repo.aggregate(:count, :id)` behavior so the Mix task `mix threadline.export` and capture-only adopters are byte-for-byte unaffected. The `:correlation_id`-aware select-binding split (`[ac, _at]` vs `[ac, _at, _aa]`) is preserved. Return shape `{:ok, %{count: non_neg_integer()}}` is unchanged for both capped and uncapped paths.
- **`Threadline.OperatorSurface.Exports.Filename.for/2`** — pure helper that produces `threadline-changes-YYYY-MM-DDTHH-MM-Z.{csv|json|ndjson}` from `(format, datetime)` via `Calendar.strftime("%Y-%m-%dT%H-%MZ")` after `DateTime.shift_zone!(dt, "Etc/UTC")`. Hyphen between hours and minutes (filesystem-friendly on Windows). `~w(csv json ndjson)` allowlist enforced via guard; any other format raises `FunctionClauseError`. NO file-scope `Code.ensure_loaded?` wrapper — pure stdlib (D-21).
- **`Threadline.OperatorSurface.Exports.FilterParams.parse/1`** — shared URL-params → keyword-list parser lifted byte-equivalently from `TimelineLive` private helpers (`filters_raw_from_params/1`, `normalize_params/1`, `parse_datetimes/1`, `parse_datetime_local/1`, `collapse_actor_ref/1`, `safe_actor_kind/1`). Datetime-local pad rule `if String.length(str) == 16, do: <> ":00Z", else: <> "Z"` preserved verbatim. Atom-safe via `String.to_existing_atom/1` (3 call sites, RESEARCH Pitfall 11). The bare `String.to_atom` token does not appear anywhere in the source. Also exports `filters_raw_from_params/1` so the LV form re-render call site can delegate to the same module. NO file-scope optional-dep gate — pure stdlib.

## Task Commits

1. **Task 1: Add `:cap` opt to `Threadline.Export.count_matching/2` + 3 unit tests** — `b461f87` (feat)
2. **Task 2: Create `Threadline.OperatorSurface.Exports.Filename` pure helper + 7 unit tests** — `bb2d3f1` (feat)
3. **Task 3: Create `Threadline.OperatorSurface.Exports.FilterParams` shared parser + 13 unit tests** — `d2f5e6f` (feat)

## API Surface (final shapes)

### `Threadline.Export.count_matching/2` (edited)

```elixir
@spec count_matching(keyword(), keyword()) :: {:ok, %{count: non_neg_integer()}}
def count_matching(filters, opts \\ []) when is_list(filters) and is_list(opts) do
  Query.validate_timeline_filters!(filters)
  repo = Query.timeline_repo!(filters, opts)
  cap = Keyword.get(opts, :cap)

  base_query =
    case Keyword.get(filters, :correlation_id) do
      nil -> filters |> Query.timeline_query() |> select([ac, _at], ac.id)
      _ -> filters |> Query.timeline_query() |> select([ac, _at, _aa], ac.id)
    end

  count =
    if is_integer(cap) and cap > 0 do
      capped = base_query |> limit(^cap)
      from(sub in subquery(capped), select: count()) |> repo.one()
    else
      repo.aggregate(base_query, :count, :id)
    end

  {:ok, %{count: count}}
end
```

### `Threadline.OperatorSurface.Exports.Filename`

```elixir
@valid_formats ~w(csv json ndjson)

@spec for(String.t(), DateTime.t()) :: String.t()
def for(format, %DateTime{} = dt) when format in @valid_formats
# -> "threadline-changes-2026-05-06T12-00Z.csv"
```

No `Code.ensure_loaded?` wrapper at file scope. `defmodule Threadline.OperatorSurface.Exports.Filename do` is the first line.

### `Threadline.OperatorSurface.Exports.FilterParams`

```elixir
@filter_keys ~w(from to table actor_kind actor_id correlation_id)

@spec parse(map()) :: {:ok, keyword()} | {:error, String.t()}
def parse(params) when is_map(params)

@spec filters_raw_from_params(map()) :: %{required(String.t()) => String.t()}
def filters_raw_from_params(params) when is_map(params)
```

No `Code.ensure_loaded?` wrapper at file scope. `String.to_existing_atom/1` only (3 call sites). `String.to_atom\b` is grep-empty across the source.

## Verification

- `mix test test/threadline/export_test.exs` — **18 tests pass** (15 pre-existing + 3 new for the `:cap` opt: clamps at cap, returns true count below cap, default unchanged).
- `mix test test/threadline/operator_surface/exports/filename_test.exs` — **7 tests pass** (canonical CSV/JSON/NDJSON literal, second-truncation, zero-padded month/day/hour/minute, non-UTC normalization via struct literal because Threadline has no `tzdata` dep, unsupported-format `FunctionClauseError`).
- `mix test test/threadline/operator_surface/exports/filter_params_test.exs` — **16 tests pass** across three describe blocks (`parse/1`, `filters_raw_from_params/1`, atom-safety regex refute). Covers empty input, allowlist drop, empty-string skip, 16-char/19-char datetime-local pad, datetime parse error, anonymous strip-id, kind+id collapse, kind-without-id silent drop, unknown actor kind error, correlation_id passthrough, table passthrough, the canonical six-key raw-map output, anonymous actor_id strip in raw map, and the in-source `~r/String\.to_atom\b/` refute.
- `mix test test/threadline/export_test.exs test/threadline/operator_surface/exports/` — **41/41 tests pass** in 0.2s.
- `mix test test/mix/tasks/threadline/export_test.exs` — **1/1 test passes** (Mix-task `Export.count_matching(filters, [])` call site at `lib/mix/tasks/threadline.export.ex:66` is unaffected by the additive opt).
- `mix verify.compile_no_optional` — **exits 0** (capture-only adopters compile cleanly because `:cap` adds no new optional-dep references and the two new helper modules are pure stdlib).
- `mix verify.format` — **exits 0** (touched files formatted; repo-wide format drift previously tracked in STATE.md is currently absent for the working tree).
- `mix verify.test` — **351/351 tests pass** in 2.9s (1 excluded `pgbouncer_topology` tag, 1 pre-existing unused-default-arg warning in `verify_coverage_task_test.exs` — out of plan scope).

Greppable invariants verified:

- `grep -c "Keyword.get(opts, :cap)" lib/threadline/export.ex` → **1**
- `grep -c "subquery" lib/threadline/export.ex` → **2**
- `grep -A 30 "def count_matching" lib/threadline/export.ex | grep -i "exists"` → no matches (no `EXISTS LIMIT` regression).
- `grep -c "{:ok, %{count: count}}" lib/threadline/export.ex` → 1
- `grep -c "{:ok, %{count: non_neg_integer()}}" lib/threadline/export.ex` → 1 (spec preserved)
- `grep -c "Code.ensure_loaded?" lib/threadline/operator_surface/exports/filename.ex` → **0**
- `grep -c "Code.ensure_loaded?" lib/threadline/operator_surface/exports/filter_params.ex` → **0**
- `grep -c "%Y-%m-%dT%H-%MZ" lib/threadline/operator_surface/exports/filename.ex` → 1
- `grep -c "~w(csv json ndjson)" lib/threadline/operator_surface/exports/filename.ex` → 1
- `grep -c "DateTime.shift_zone!" lib/threadline/operator_surface/exports/filename.ex` → 1
- `grep -E 'String\.to_atom\b' lib/threadline/operator_surface/exports/filter_params.ex` → **no matches**
- `grep -c "String.to_existing_atom" lib/threadline/operator_surface/exports/filter_params.ex` → 3
- `grep -c "if String.length(str) == 16" lib/threadline/operator_surface/exports/filter_params.ex` → 1
- `grep -c "ActorRef.new" lib/threadline/operator_surface/exports/filter_params.ex` → 1
- `lib/mix/tasks/threadline.export.ex` is byte-unchanged across this plan's three commits.

## Decisions Made

- **`Etc/GMT-5` non-UTC test fixture replaced with struct-literal `%DateTime{...}`** — Threadline does not depend on `tzdata`, so the stock `Calendar.UTCOnlyTimeZoneDatabase` returns `{:error, :utc_only_time_zone_database}` for any non-UTC zone passed to `DateTime.from_naive/2`. Constructing the non-UTC datetime via struct literal preserves the test's intent (verify `DateTime.shift_zone!(dt, "Etc/UTC")` defends against accidental local-tz inputs) without dragging tzdata into the dep tree.
- **Moduledoc rephrased to drop the bare `String.to_atom/1` token** — the in-source atom-safety regex refute (`refute src =~ ~r/String\.to_atom\b/`) is word-boundary-anchored, so any literal `String.to_atom/1` mention in the moduledoc would match. Rephrased to "never via the unsafe variant that creates fresh atoms from arbitrary strings" so the safety message stays clear without tripping the regex. Plan 04's doc-contract test will hold the same line.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test fixture used `Etc/GMT-5` zone-name lookup despite no tzdata dep**

- **Found during:** Task 2 (Filename test for non-UTC normalization)
- **Issue:** Plan-supplied test stub used `DateTime.from_naive(~N[2026-05-06 12:00:00.000], "Etc/GMT-5")`, but Threadline does not depend on `tzdata` — the stock `Calendar.UTCOnlyTimeZoneDatabase` returns `{:error, :utc_only_time_zone_database}` for any non-UTC zone, so `from_naive/2` returns an error tuple rather than a DateTime. The fixture would have crashed with a `MatchError`, masking the actual normalization behavior under test.
- **Fix:** Replaced `from_naive/2` with a `%DateTime{...}` struct literal (utc_offset -18_000s, time_zone "America/New_York", zone_abbr "EST"). `DateTime.shift_zone!(dt, "Etc/UTC")` itself does NOT require a TZ DB lookup (only the offsets), so the test still proves what it claims to: a non-UTC input is correctly normalized to UTC before formatting.
- **Files modified:** test/threadline/operator_surface/exports/filename_test.exs (only)
- **Verification:** All 7 Filename tests pass, including the normalization assertion `assert Filename.for("csv", non_utc) == "threadline-changes-2026-05-06T17-00Z.csv"` (12:00 EST + 5h = 17:00 UTC).
- **Committed in:** bb2d3f1 (Task 2 commit)

**2. [Rule 1 - Bug] Moduledoc literal `String.to_atom/1` tripped the in-source atom-safety regex refute**

- **Found during:** Task 3 (FilterParams atom-safety test)
- **Issue:** The plan-supplied moduledoc contained the literal sentence "`actor_kind` is converted to an atom via `String.to_existing_atom/1` — never `String.to_atom/1`." The in-source regex refute test `refute src =~ ~r/String\.to_atom\b/` matches that exact literal (word boundary after `to_atom`), failing with the moduledoc body in the diff. Plan 04's doc-contract test will use the same regex shape, so leaving it would break that test too.
- **Fix:** Rephrased the moduledoc sentence to "`actor_kind` is converted to an atom via `String.to_existing_atom/1` — never via the unsafe variant that creates fresh atoms from arbitrary strings." The safety message is preserved verbatim in intent; the literal token that the regex matches is removed.
- **Files modified:** lib/threadline/operator_surface/exports/filter_params.ex (only)
- **Verification:** `grep -E 'String\.to_atom\b' lib/threadline/operator_surface/exports/filter_params.ex` returns no matches; all 16 FilterParams tests pass including the atom-safety refute.
- **Committed in:** d2f5e6f (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 bugs in plan-supplied test/doc stubs; both pre-empt regressions Plan 04's doc-contract test would otherwise catch).
**Impact on plan:** No scope creep. Both fixes are local to this plan's new files.

## Issues Encountered

None beyond the two auto-fixed deviations above. No verification steps had to be retried, no Mix-task regression appeared, no `mix verify.compile_no_optional` regression appeared.

## Threat Flags

None. The two new helper modules introduce no new network surface, no auth path, no file-system access, and no schema changes. The `:cap` opt on `count_matching/2` is read-only Ecto query plumbing; it cannot widen the existing query's filter or join semantics.

## Self-Check: PASSED

All claimed files exist:

- `lib/threadline/export.ex` — modified, contains `Keyword.get(opts, :cap)` and `subquery`.
- `lib/threadline/operator_surface/exports/filename.ex` — created.
- `lib/threadline/operator_surface/exports/filter_params.ex` — created.
- `test/threadline/export_test.exs` — modified, contains `cap: 50` test.
- `test/threadline/operator_surface/exports/filename_test.exs` — created.
- `test/threadline/operator_surface/exports/filter_params_test.exs` — created.

All claimed commits found in `git log`:

- `b461f87` — Task 1.
- `bb2d3f1` — Task 2.
- `d2f5e6f` — Task 3.

## Next-Plan Readiness

- **Plan 65-02 (`ExportController` + `ExportAuthPlug` + router macro extension):** Imports `Threadline.OperatorSurface.Exports.Filename` for the `Content-Disposition` header builder and `Threadline.OperatorSurface.Exports.FilterParams.parse/1` for the request-side filter parsing path. The controller must also call `Threadline.Export.count_matching(filters, cap: 10_001)` for the threshold-dispatch decision (sync iodata vs `Plug.Conn.send_chunked/2` stream).
- **Plan 65-03 (`TimelineLive` export buttons + count status line):** Replaces the inline private helpers `filters_raw_from_params/1`, `normalize_params/1`, `parse_datetimes/1`, `parse_datetime_local/1`, `collapse_actor_ref/1`, `safe_actor_kind/1`, `build_filters/1` (all under the `if Code.ensure_loaded?(Phoenix.LiveView)` wrapper at `lib/threadline/operator_surface/live/timeline_live.ex:264-393`) with delegation to `Threadline.OperatorSurface.Exports.FilterParams.parse/1` and `Threadline.OperatorSurface.Exports.FilterParams.filters_raw_from_params/1`. Also calls `Threadline.Export.count_matching(filters, cap: 10_001)` in parallel with `Query.timeline_page/2` via `Task.async`.
- **Plan 65-04 (doc-contract test trifecta):** The `exports_doc_contract_test.exs` will assert the same invariants this plan's tests already cover — file-scope `Code.ensure_loaded?` count == 0 on both helper modules; `String.to_atom\b` regex matches == 0 in `FilterParams`; the literal `~w(csv json ndjson)` and `%Y-%m-%dT%H-%MZ` in `Filename`. The Mix-task vs controller byte-equality parity assertion will produce identical output by construction because both surfaces will call the same `FilterParams.parse/1`.

---

*Phase: 65-exports-ui-parity*
*Completed: 2026-05-07*
