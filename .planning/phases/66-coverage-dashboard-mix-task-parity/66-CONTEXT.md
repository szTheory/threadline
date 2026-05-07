# Phase 66: Coverage Dashboard & Mix Task Parity - Context

**Gathered:** 2026-05-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a polled `CoverageLive` at `/audit/coverage` that renders `Threadline.Health.trigger_coverage/1` with three buckets (covered / uncovered / expected-uncovered), a new every-page surface header showing the public-schema uncovered count visible from any LV, an optional `:schema` argument on `Threadline.Health.trigger_coverage/1` (default `"public"`) so non-`public` adopters get correct results, a parity `mix threadline.health.coverage` task with table format + `--json` for capture-only adopters, and a doc-contract test pinning the LV route literal + Mix-task help text + `--json` output schema. Refresh is per-LV `Process.send_after` driven by a new `live_session :threadline` `on_mount` hook (no PubSub, no GenServer — `phoenix_pubsub` stays `optional: true`). Schema scope on the dashboard and Mix tasks is exposed via URL `?schema=NAME` / flag `--schema=NAME`, validated against `pg_namespace`. Read-only throughout; zero new platform infrastructure; `mix verify.compile_no_optional` stays green.

</domain>

<decisions>
## Implementation Decisions

### Refresh mechanism

- **D-30: New `Threadline.OperatorSurface.Coverage.OnMount` hook drives polling for every LV in the `live_session :threadline` block — no PubSub, no GenServer.** The hook mirrors the existing `Threadline.OperatorSurface.Auth` shape (gated on `Phoenix.LiveView`). At mount: fetch coverage, assign `:threadline_coverage` (a struct/map carrying `covered_count`, `uncovered_count`, `expected_uncovered_count`, `last_checked_at`, `coverage_error`), schedule first tick via `Process.send_after(self(), :threadline_refresh_coverage, interval)` (guarded by `connected?(socket)`), and `attach_hook(:threadline_coverage_refresh, :handle_info, &handle_refresh/2)` so the tick is intercepted across every LV without per-LV `handle_info` boilerplate. Re-fetch + reschedule on each tick. Mounted in `router.ex` via `live_session :threadline, on_mount: [{Auth, opts}, {Coverage.OnMount, opts}]`. Does **not** use `Phoenix.PubSub`. Does **not** introduce a GenServer. Keeps `phoenix_pubsub` `optional: true` and `mix verify.compile_no_optional` trivially green.
- **D-30a: Polling parameters.** Default interval `30_000` ms (matches COV-02 literal). Override via `config :threadline, :coverage_poll_ms, 30_000` (global) or socket-assign `:threadline_coverage_poll_ms` (per-mount). Floor of `5_000` ms — raise at mount below that with a clear message ("coverage poll interval must be ≥ 5_000 ms; below this, the two `pg_*` queries become a noisy neighbor on busy schemas"). The two SQL calls inside `trigger_coverage/1` (`pg_tables` + `pg_trigger` join) are bounded sub-second on normal schemas; per-LV polling at the realistic operator-surface ceiling of N≈10 open tabs is cheap.
- **D-30b: Manual refresh button lives on `CoverageLive` only.** The dashboard page exposes a small "Refresh" link beside a "Last checked Xs ago" timestamp. Click handler cancels the pending timer (`Process.cancel_timer(socket.assigns.threadline_timer_ref)`), runs an immediate refresh, reschedules. Surface-header pages (Timeline / Transaction / Actor / RowHistory) have **no** manual button — multiplying the same affordance across four pages is noise; an operator who wants a manual poke navigates to `/audit/coverage`.
- **D-30c: On-poll-error UX — keep last-good, never stop polling.** Wrap `trigger_coverage/1` in `try/rescue`. On failure: keep the previous `:threadline_coverage` assign and `:last_checked_at`, set `:threadline_coverage_error` to the exception message, and **always reschedule** (transient DB blips must not silently freeze the count). `CoverageLive` renders an inline yellow strip: "Coverage check failed at {time} — showing last successful result from {last_checked_at}". Surface-header pages render the previous count with a small "stale (last checked Xs ago)" tooltip on the badge. Emit a `[:threadline, :health, :checked, :error]` telemetry event so adopters can alert on it. The existing `[:threadline, :health_checked]` event continues to fire on every successful call (`Telemetry.emit_health_checked/2`-derivative) and remains the documented "hookable telemetry" surface for COV-02.
- **D-30d: Forward-compat escape hatch documented but NOT shipped in v1.18.** If a real adopter hits per-LV polling pain at v1.19+ scale (50+ admin tabs on a busy 10k-table schema), document a `config :threadline, :coverage_source, {:pubsub, MyApp.PubSub}` opt that — when set AND `phoenix_pubsub` is loaded — swaps the per-LV timer for a single-source GenServer + broadcast. This is a runtime opt-in, not a hard dep. Out of scope for Phase 66; mention only as a defensive note in `@moduledoc`.

### Surface header (every-page drift visibility)

- **D-31: New shared `Phoenix.Component` `Threadline.OperatorSurface.Components.SurfaceHeader.surface_header/1`, gated on `Phoenix.LiveView`, invoked atop each LV's existing `<div class="threadline-ui">` wrapper.** Reads `@threadline_coverage` from the parent LV's assigns (sourced by D-30's hook). **Zero per-LV polling.** Each of the four existing LVs (TimelineLive, TransactionLive, ActorLive — and the new CoverageLive — RowHistoryComponent inherits via TransactionLive's render) gains a single one-line render edit: `<.surface_header coverage={@threadline_coverage} base_path={@base_path} />` directly under `<Threadline.OperatorSurface.Style.css />`.
- **D-31a: Visual treatment — explicit "boring case" reassurance.**
  - `uncovered_count == 0` → `<a class="surface-badge surface-badge--ok" href={"#{@base_path}/coverage"}>All covered</a>` (text-muted, no fill). **Never hide** — silently disappearing creates uncertainty ("is the badge broken or am I really covered?"); audit tooling earns trust by loudly confirming the boring case.
  - `uncovered_count > 0` → `<a class="surface-badge surface-badge--warn" href={"#{@base_path}/coverage"}>{n} uncovered</a>` (amber `#FEF3C7` bg / `#92400E` fg / `#F59E0B` accent — **same palette as Phase 65's truncation warning**, for visual continuity of the "data-loss-adjacent" semantic).
  - `:threadline_coverage_error` set → small "stale (last checked Xs ago)" subtle indicator next to the badge.
- **D-31b: Header always queries the `"public"` schema.** It is a global drift signal across the surface; multi-schema is opt-in via URL on `CoverageLive` (D-33). The header does not change per-page — keeps the cognitive surface simple, matches the 95% adopter case (single-schema). Multi-schema operators get per-schema detail on the dashboard, not in the header.
- **D-31c: Header sits OUTSIDE / ABOVE Phase 65's `.timeline-toolbar`.** Phase 65's sticky toolbar gets `top: var(--tl-header-height, 36px)` so it docks below the surface header. CSS variable so future header height changes don't break the toolbar offset. **No collision with `.match-count-status` or `.truncation-banner`** — those remain owned by `TimelineLive` body content, the surface header is sibling chrome one DOM level up.
- **D-31d: Click-through is a plain anchor (`<a href={…}>`), not `live_patch`.** The destination is a different LV in the session (`CoverageLive`); a full `live_redirect`/anchor is correct and matches the Phase 65 download-anchor precedent (post-PR-#2611 LiveView semantics). No flash of empty content; user lands on `/audit/coverage` cleanly.

### Expected-uncovered policy

- **D-32: Three-bucket return shape — `Threadline.Health.trigger_coverage/1` returns `[{:covered | :uncovered | :expected_uncovered, table_name}]`.** The `:expected_uncovered` bucket is computed inside `Health` by unioning the hardcoded baseline + the configured `:expected_uncovered_tables` (minus any in `:audit_anyway`). Existing pattern matches on `{:covered, _}` / `{:uncovered, _}` keep working — the new tuple variant is additive. **Backward compatibility** is the load-bearing constraint here.
- **D-32a: Hardcoded baseline = `["schema_migrations"]` only.** Codified as `@expected_uncovered_baseline ~w(schema_migrations)` module attribute on `Threadline.Health`. Documented in `@moduledoc` with rationale: "Ecto-canonical migrations bookkeeping table; never an application table; baselined here so a fresh adopter does not see drift on day one." **Oban tables are NOT baselined** (`oban_jobs`, `oban_peers`, `oban_producers`) — not every adopter uses Oban; symmetry-breaking hardcodes seed silent drift on a hypothetical `oban_jobs` domain table that the adopter actually wants captured. The baseline must stay conservative; resist temptation to grow it.
- **D-32b: Adopter-configurable additions via `config :threadline, :health, expected_uncovered_tables: [...]`.** Default `[]`. Type spec `[String.t()]`. Validated by a new `Threadline.Health.Policy.validate!/1` (mirrors existing `Threadline.Capture.RedactionPolicy.validate!/1` shape — raise on non-binary entries, raise on duplicates). Namespaced under `:health` (not top-level) so future health knobs (poll interval, schema option) live together. Adopter typically adds `["oban_jobs", "oban_peers", "oban_producers"]` — the `Oban` documented set — or their own host-specific bookkeeping tables.
- **D-32c: Override-to-audit escape hatch — `config :threadline, :health, audit_anyway: ["schema_migrations"]`.** Removes the table from the baseline before union with `:expected_uncovered_tables`. Documented as "extreme corner case" in `Threadline.Health` `@moduledoc`. Preserves the read-only-ceiling philosophy: policy is declarative in `runtime.exs`, not editable from the LV.
- **D-32d: LV badge literals — three states.** `"covered"` (green), `"uncovered"` (red — drift), `"expected"` (gray, neutral). Tooltip on `expected` reads literal source: `"Baseline: schema_migrations"` or `"Configured via :expected_uncovered_tables"` — discoverability matters more than terseness; the operator must be able to trace WHY a table is exempt without reading lib source. Surface-header counts `uncovered` only; `:expected_uncovered` is visible-but-quiet on the dashboard, never on the header.
- **D-32e: Telemetry shape — additive.** `Threadline.Telemetry.emit_health_checked/2` becomes `emit_health_checked/3` with an `expected_uncovered_count` arg. The telemetry event metadata gains an `expected_uncovered` key. Old subscribers reading only `covered` / `uncovered` measurements keep working unchanged. Document the shape change in CHANGELOG and `@moduledoc`.
- **D-32f: Backward-compat update to `Threadline.Verify.CoveragePolicy.violations/2`.** Today `violations/2` flags any `{:uncovered, table}` whose name is in `:expected_tables`. With the new bucket, `:expected_uncovered` rows must be treated as "intentionally not covered" — i.e., NOT flagged as missing when absent from `:expected_tables` (today they'd silently show up as `:missing` because the verify gate didn't know about the bucket). One additive case clause: `{:expected_uncovered, _table}` → ignore. Existing `mix threadline.verify_coverage` semantics are preserved for tables an adopter has explicitly listed in `:expected_tables`.

### Schema scope (LV + Mix exposure)

- **D-33: URL `?schema=NAME` on the LV, `--schema=NAME` on Mix tasks, regex + `pg_namespace` validated.** No selector dropdown, no tabs, no multi-schema view. Single mechanism; LV param ↔ Mix flag, same name, same validation contract.
  - **CoverageLive**: `/audit/coverage?schema=tenant_42`. No widget. Param absent → `"public"`. Page header renders `"Coverage — schema: tenant_42"` so it's visible in screenshots.
  - **Mix tasks**: `mix threadline.health.coverage --schema=NAME` (new task, see D-34). `mix threadline.verify_coverage --schema=NAME` (additive flag, default behavior unchanged). Both default `"public"`.
- **D-33a: Validation lives at the LV/Mix EDGE, not in `Threadline.Health`.** Two-layer belt-and-suspenders:
  1. Regex first: `~r/\A[a-z_][a-z0-9_]{0,62}\z/` — malformed input never reaches a query.
  2. Catalog lookup: `SELECT 1 FROM pg_namespace WHERE nspname = $1` (parameterized; never interpolated). Unknown schema → LV `:form_error` "Schema 'X' not found"; Mix `Mix.raise/1` exits 1.
  - Document on `Threadline.Health.trigger_coverage/1` `@doc`: lib does NOT validate `:schema`; programmatic callers are responsible for sanitizing or trusting their own input. This keeps the lib API thin and the validation behavior visible at the surfaces that take untrusted input.
- **D-33b: TimelineLive datalist consumer (`timeline_live.ex:30`) stays bare — `Threadline.Health.trigger_coverage(repo: repo)`, no `:schema` argument.** That surface is single-schema-scoped today; changing it is out of scope for COV-02. Phase 66 touches only the new `CoverageLive` and the new `mix threadline.health.coverage` (and the additive flag on `mix threadline.verify_coverage`). The forward-compat note in `timeline_live.ex:27-28` ("Phase 66 will introduce a polled coverage source we can subscribe to") IS satisfied by D-30 — the datalist will eventually move from "compute once at mount" to reading the same `:threadline_coverage` assign, but that refactor is best done when a real adopter reports stale-datalist pain on a long-lived session.
- **D-33c: Lib API change — `Threadline.Health.trigger_coverage/1` accepts `:schema` keyword opt, default `"public"`.** Replace the hardcoded `'public'` literal in BOTH inner SQL queries (`pg_tables WHERE schemaname = 'public'` AND the `pg_trigger`/`pg_class` join — must filter by `pg_namespace.nspname = $1` joined to `pg_class.relnamespace`). Both queries become parameterized. Add a `## Options` entry to the `@doc` with one example: `trigger_coverage(repo: MyApp.Repo, schema: "tenant_42")`. Cross-link from `Threadline.Health` `@moduledoc` to the new `mix threadline.health.coverage` task; add reciprocal cross-links from both Mix tasks back to `Threadline.Health.trigger_coverage/1`.

### Mix task (`mix threadline.health.coverage`)

- **D-34: New `Mix.Tasks.Threadline.Health.Coverage` task — table format default + `--json` flag + `--schema=NAME` flag.** Mirrors the existing `mix threadline.verify_coverage` shape (resolve repo from `:ecto_repos`, `ensure_repo_started!/1`, etc.) but does NOT exit 1 on uncovered — this is a viewer, not a CI gate. The CI gate is the existing `mix threadline.verify_coverage` task; the new task is purely informational.
  - Default output: a three-section table with headers `TABLE`, `STATUS` (literal values: `covered` / `uncovered` / `expected`), and `SOURCE` (only populated for `expected` rows: `baseline` or `config`). Summary footer with counts: `Coverage: N covered, M uncovered, K expected uncovered`.
  - `--json` schema: `{"schema": "public", "covered": ["users", "posts", ...], "uncovered": ["orders", ...], "expected_uncovered": [{"table": "schema_migrations", "source": "baseline"}, {"table": "oban_jobs", "source": "config"}]}`. Three top-level lists; `expected_uncovered` is a list of objects (not strings) so the `source` discoverability is preserved. The `schema` field surfaces which schema was queried, useful for audit logs.
  - `--schema=NAME` flag — same validation as the LV (D-33a). Default omitted → `"public"`.
  - File location: `lib/mix/tasks/threadline.health.coverage.ex` (matches sibling `threadline.verify_coverage.ex`, NOT the nested-directory shape of `threadline/verify_topology.ex`). Module name: `Mix.Tasks.Threadline.Health.Coverage`.

### Doc-contract test (COV-03)

- **D-35: Pure source-reading doc-contract test — mirrors BROWSE-04 and EXPO-05 patterns.** Test file: `test/threadline/operator_surface/coverage_doc_contract_test.exs`. Asserts:
  - **LV route literal:** `live("/coverage", CoverageLive, :index)` parsed via `Code.string_to_quoted/1` + tree-walk over `lib/threadline/operator_surface/router.ex` (parity with BROWSE-04 / EXPO-05's literal pinning).
  - **Surface header literals:** `"All covered"` and `~r/\d+ uncovered/` (count is dynamic; the format string is locked) over `surface_header.ex`.
  - **Three badge state literals:** `"covered"`, `"uncovered"`, `"expected"` over `coverage_live.ex` (NOT `"missing"` / `"not_covered"` / `"untracked"` etc. — pin the specific literals).
  - **Mix-task help text:** `@shortdoc` and the `@moduledoc` `## Usage` section over `lib/mix/tasks/threadline.health.coverage.ex`. Locks `mix threadline.health.coverage` and `mix threadline.health.coverage --json` and `mix threadline.health.coverage --schema=NAME` literals.
  - **Mix-task `--json` schema** — invoke the task in test mode and assert the parsed JSON has exactly the keys `["covered", "expected_uncovered", "schema", "uncovered"]` (sorted) and that `expected_uncovered` entries have keys `["source", "table"]` with `source ∈ {"baseline", "config"}`.
  - **Hardcoded baseline list:** `["schema_migrations"]` — assert the `@expected_uncovered_baseline` module attribute literal (parsed source, not runtime introspection) so any future expansion fails CI explicitly.
  - **Atom-safety refute:** `refute String.contains?(src, "String.to_atom\\b")` regex against `coverage_live.ex` and `Mix.Tasks.Threadline.Health.Coverage` (Pitfall 11 carry-forward from Phase 65).
  - **`mix verify.compile_no_optional` greenness:** spawn the alias in CI; this is the existing safety net, not a new contract.

### Optional-deps posture

- **D-36: `mix verify.compile_no_optional` stays green.** Two new files gate on `Phoenix.LiveView`: `lib/threadline/operator_surface/coverage/on_mount.ex`, `lib/threadline/operator_surface/components/surface_header.ex`, `lib/threadline/operator_surface/live/coverage_live.ex`. Capture-only adopter (no Phoenix/LiveView) compiles cleanly; the new Mix task (`threadline.health.coverage`) requires NO Phoenix deps and works for capture-only adopters — the parity surface intent is preserved literally. The `Threadline.Health.Policy` validator (new module) is pure stdlib, no gating needed. **No new hard deps; `phoenix_pubsub` stays `optional: true`.**

### Claude's Discretion

- Exact CSS rule names within the `.threadline-ui` namespace beyond the locked literals (`.surface-badge`, `.surface-badge--ok`, `.surface-badge--warn`, `.threadline-ui-header`).
- Exact keyset/struct shape of the `:threadline_coverage` socket assign (recommend a `Threadline.OperatorSurface.Coverage.Snapshot` struct with `covered_count`, `uncovered_count`, `expected_uncovered_count`, `last_checked_at`, `error`; planner picks).
- Exact wording of the on-poll-error inline strip on `CoverageLive` (D-30c gives the recommended literal; planner may tighten).
- Whether the `Threadline.Health.Policy.validate!/1` lives at `lib/threadline/health/policy.ex` (sibling under a new `threadline/health/` directory) or `lib/threadline/health.ex`-internal — recommend the sibling file since the redaction precedent at `lib/threadline/capture/redaction_policy.ex` does the same.
- Exact column widths / alignment of the Mix-task default table format (must be readable on an 80-col terminal; planner picks).
- Exact filename of the `:health_checked` telemetry-event metadata change documentation in CHANGELOG.
- Whether the page-header timestamp on `CoverageLive` ("Last checked Xs ago") is a static render or a 1Hz timer-driven update — recommend static (re-renders on each 30s tick anyway), but accept a smoother UX if the planner finds it cheap.
- Whether the surface header brand label literal is `"Threadline"` or includes a small audit/health logo affordance — recommend just the wordmark for now.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 66 contract + milestone scope

- `.planning/ROADMAP.md` §"Phase 66: Coverage Dashboard & Mix Task Parity" — phase goal, 3 success criteria (dashboard LV + `:schema` arg + parity Mix task), sequencing rationale (does not depend on Phases 64/65 — distinct subsystem).
- `.planning/REQUIREMENTS.md` §"COV-01..03" — verbatim:
  - **COV-01** — Coverage dashboard LV at `/audit/coverage` rendering `Threadline.Health.trigger_coverage/1` with separate covered / uncovered lists, expected-uncovered marked (e.g. `schema_migrations`), uncovered count surfaced in the surface header.
  - **COV-02** — `:schema` arg on `trigger_coverage/1` (default `"public"`); LV refreshes on configurable poll (default 30s); `:health_checked` telemetry signal hookable for refresh.
  - **COV-03** — `mix threadline.health.coverage` parity task (table format + `--json`); doc-contract test locks LV route literal + Mix-task help text + output schema.
- `.planning/REQUIREMENTS.md` §"Out of Scope (explicit exclusions for v1.18)" — read-only ceiling; no runtime policy edits; no retention admin (deferred to v1.19).
- `.planning/PROJECT.md` §"Current Milestone: v1.18" — strategic framing; "correct by default — harder to miss capture than to enable it"; "trigger-backed capture (not application-hook-based)".
- `.planning/STATE.md` §"Accumulated Context" — v1.18 scoping rationale; 2026-05-06 decision: "v1.18 ships read-only policy admin viewers" (coverage + drift-aware redaction admin).

### Phase 64 + 65 carry-forward (LV pattern + auth + style namespace are LOCKED)

- `.planning/phases/64-raw-timeline-browse-and-filter-form/64-CONTEXT.md` — TimelineLive shape, file-scope `Phoenix.LiveView` gating, `<div class="threadline-ui">` wrapper, `.threadline-ui` CSS namespace, doc-contract test posture (BROWSE-04).
- `.planning/phases/65-exports-ui-parity/65-CONTEXT.md` — D-15 plain `<.link href={…}>` anchor pattern (Phase 66 surface header click-through reuses), D-21 file-scope `Code.ensure_loaded?(Phoenix.Controller)` gating posture, D-26 doc-contract test pattern (Phase 66 D-35 mirrors).
- `.planning/phases/65-exports-ui-parity/65-CONTEXT.md` §"Stream-vs-iodata Dispatch" — Phase 65's `.match-count-status` and `.truncation-banner` styles live in `style.ex`; Phase 66's surface header sits ABOVE `.timeline-toolbar` and uses CSS variable `--tl-header-height` for offset.

### Library APIs the new code must call (and not duplicate)

- `lib/threadline/health.ex:29-53` — current `Threadline.Health.trigger_coverage/1`. Phase 66 EDITS this to: (a) accept `:schema` opt with default `"public"`, (b) parameterize the two SQL queries against `$1`, (c) compute the third bucket (`:expected_uncovered`) by unioning baseline + config minus `:audit_anyway`, (d) return three-tuple shape, (e) emit telemetry with the additional `expected_uncovered_count`.
- `lib/threadline/health.ex:9` — `@audit_tables ~w(audit_transactions audit_changes audit_actions)` — these stay EXCLUDED from the result entirely (they're Threadline's own tables, not adopter audit targets). The new `:expected_uncovered` bucket is for adopter-side bookkeeping tables (`schema_migrations`, `oban_jobs`, etc.).
- `lib/threadline/telemetry.ex:60-66` — `Threadline.Telemetry.emit_health_checked/2`. Phase 66 EXTENDS to `/3` with `expected_uncovered_count` (additive — old subscribers reading only `covered`/`uncovered` keep working). The `[:threadline, :health_checked]` event metadata gains an `expected_uncovered` key. **Document the shape change in CHANGELOG and `Threadline.Health` `@moduledoc`.**
- `lib/threadline/capture/redaction_policy.ex:1-22` — precedent for the new `Threadline.Health.Policy.validate!/1`. Same shape: accept keyword OR map; raise with a clear message on non-binary entries / duplicates / unknown keys.
- `lib/threadline/verify/coverage_policy.ex` — existing CI-gate logic. Phase 66 ADDS one case clause for `{:expected_uncovered, _table}` (treated as covered-equivalent for tables NOT in `:expected_tables`); existing semantics for tables IN `:expected_tables` are preserved.
- `lib/mix/tasks/threadline.verify_coverage.ex` — existing CI-gate Mix task. Phase 66 ADDS `--schema=NAME` flag (default `"public"`); same validation contract as D-33a. The task is otherwise unchanged — still the CI gate, still positive-list config.

### v1.17 + v1.18 surface artifacts the new code must integrate with

- `lib/threadline/operator_surface/router.ex:67-76` — `live_session :threadline` block. Phase 66 EDITS `on_mount: [...]` to append `Coverage.OnMount`, and ADDS the new `live("/coverage", CoverageLive, :index)` route inside the existing scope.
- `lib/threadline/operator_surface/auth.ex` — `Threadline.OperatorSurface.Auth.on_mount/4`. **Mirror its file shape and gating** for the new `Threadline.OperatorSurface.Coverage.OnMount`. Same `Code.ensure_loaded?(Phoenix.LiveView)` outer guard, same `on_mount/4` callback signature.
- `lib/threadline/operator_surface/style.ex` — `.threadline-ui` CSS namespace + CSS-variable convention. Phase 66 ADDS rules for `.threadline-ui-header`, `.surface-badge`, `.surface-badge--ok`, `.surface-badge--warn`, the coverage page's `.coverage-table`, `.coverage-row--covered/uncovered/expected`, and the Phase-65 toolbar offset variable `--tl-header-height: 36px`.
- `lib/threadline/operator_surface/live/timeline_live.ex:27-35` — existing `Threadline.Health.trigger_coverage(repo: repo)` call for the table datalist. **Stays unchanged in Phase 66** (D-33b). The forward-compat note at lines 27-28 is satisfied by D-30 conceptually; refactoring the datalist to read `:threadline_coverage` is deferred until adopter pain is reported.
- `lib/threadline/operator_surface/live/transaction_live.ex:73-80` — render shape (`<div class="threadline-ui"><Threadline.OperatorSurface.Style.css /> ...`). The `<.surface_header />` invocation slots in directly under `<Threadline.OperatorSurface.Style.css />`.
- `lib/threadline/operator_surface/live/actor_live.ex` — same shape; same one-line render edit.
- `lib/threadline/operator_surface/exports/filename.ex` (Phase 65) — precedent for new lib-internal helper modules under `operator_surface/`. Phase 66 may follow the same nesting convention if a coverage helper warrants its own file.

### Mix-task parity (COV-03 byte/format-equality target)

- `lib/mix/tasks/threadline.verify_coverage.ex:1-90` — sibling Mix task. Phase 66's new `mix threadline.health.coverage` mirrors the resolve-repo / ensure-started boilerplate; differs in (a) does NOT exit 1 on uncovered (viewer, not gate), (b) prints a three-bucket table including `expected_uncovered`, (c) supports `--json` flag.
- `lib/mix/tasks/threadline.export.ex:73-93` (Phase 65) — flag→opt-mapping precedent for the `OptionParser.parse!/2` shape; reuse the same parsing posture for `--json` / `--schema=NAME`.

### Verification + CI invariants

- `mix verify.compile_no_optional` (Phase 57 alias) — must stay green. New LV files (`coverage/on_mount.ex`, `components/surface_header.ex`, `live/coverage_live.ex`) wrap in `if Code.ensure_loaded?(Phoenix.LiveView) do … end` at file scope. New Mix task and `Threadline.Health.Policy` are pure-stdlib, no gating needed.
- COV-03 doc-contract test — `test/threadline/operator_surface/coverage_doc_contract_test.exs`. Pure source-reading; locks all the literals listed in D-35.
- Recommended additional integration test: `test/threadline/operator_surface/live/coverage_live_test.exs` — Phoenix.LiveViewTest cases for: mount renders three buckets; manual "Refresh" click cancels-and-reschedules timer; `?schema=NAME` validation 422 (form_error) on bad input; surface header on three other LVs (Timeline / Transaction / Actor) renders the badge with the same count.
- Recommended additional Mix-task integration test: `test/threadline/operator_surface/coverage_mix_test.exs` — exercises both `--json` and default table output, asserts `--schema=NAME` flag plumbing matches the LV behavior (parity test, not byte-equality this time since formats differ).

### Idiomatic peer projects (consult during planning if patterns are unclear)

- **Phoenix LiveDashboard** (`phoenix_live_dashboard`) — single `PageLive` LV with `Process.send_after(self(), :refresh, n)` + a refresh-interval dropdown. The polling primitive is idiomatic; Threadline goes lighter (per-LV timer in the session via `attach_hook`, no central PageLive).
- **Oban Web** (oban-bg/oban_web) — `stats_interval` + `tick_interval` per-page configuration; pause-on-blur. The configurable-interval pattern is mainline; Threadline's `:coverage_poll_ms` global config matches.
- **`phx.gen.auth`'s `UserAuth` module** — generates `on_mount/4` callback for `live_session` shared assigns. Direct precedent for `Threadline.OperatorSurface.Coverage.OnMount`.
- **Sentry-Elixir** `lib/sentry/live_view_hook.ex` — file-scope `Code.ensure_loaded?(Phoenix.LiveView) do defmodule … end` gating shape. Threadline's existing `auth.ex` follows this; `coverage/on_mount.ex` does the same.
- **Carbonite** (`bitcrowd/carbonite`) — multi-prefix audit trails via `prefix` opt on triggers. Establishes that `:schema` (or `:prefix`) is a first-class lib API surface in this ecosystem.
- **PostgREST `db-schemas` allowlist** — schema validation precedent: schema names treated as untrusted, validated at the edge against an allowlist, never interpolated. Threadline uses `pg_namespace` lookup for the same purpose (D-33a).
- **Ecto's `mix ecto.dump` / `mix ecto.load`** — `schema_migrations` is the canonical "exclude this from any introspection" table across the entire Elixir/Ecto ecosystem. Direct precedent for the D-32a hardcoded baseline of one entry.
- **GitHub audit log nav-level "X events" badge** — direct UX precedent for the surface-header "{n} uncovered" pill.
- **Phoenix LiveView PR #2611** — `wantsNewTab()` fix for anchors with `Content-Disposition: attachment`. Phase 65 leans on this; Phase 66's plain `<a>` click-through to `/audit/coverage` works regardless because no download is involved, but the reasoning is the same: plain anchors are post-fix idiomatic.

### Documentation surfaces

- `guides/operator-surface.md` — Phase 66 ADDS a `## Coverage dashboard` section: route literal, polling defaults + override config, three badge meanings, screenshot of the "All covered" / "{n} uncovered" header pill, multi-schema usage (`?schema=`), `:expected_uncovered_tables` config example with rationale.
- `guides/domain-reference.md` §"Trigger coverage (operational)" (Phase 28) — UPDATE with the three-bucket return shape, `:schema` opt, and the new Mix-task name.
- `guides/production-checklist.md` — ADD a "Coverage drift visibility" subsection cross-linking to the new dashboard + Mix task, framed as the dominant failure-mode safety check.
- `CHANGELOG.md` — entry for v1.18 noting: `Threadline.Health.trigger_coverage/1` API change (additive `:schema` opt; additive third tuple bucket; backward-compat preserved for existing pattern-matching consumers); new `mix threadline.health.coverage` task; new operator surface header; new `:expected_uncovered_tables` / `:audit_anyway` config keys.
- `README.md` — minor: cross-link to the new coverage dashboard in the operator-surface bullet; the doc-contract test (`test/threadline/readme_doc_contract_test.exs`) may need a small update if literals shift.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Threadline.Health.trigger_coverage/1` (`lib/threadline/health.ex`) — the central lib API. Phase 66 EDITS in place to add `:schema` opt, parameterize SQL, and return the three-tuple. Existing callers (`mix threadline.verify_coverage`, `TimelineLive` datalist) keep working without changes thanks to the additive shape.
- `Threadline.Telemetry.emit_health_checked/2` (`lib/threadline/telemetry.ex:60`) — extend additively to `/3` for `expected_uncovered_count`. The `[:threadline, :health_checked]` event is COV-02's "hookable" telemetry contract; no new event needed.
- `Threadline.OperatorSurface.Auth.on_mount/4` (`lib/threadline/operator_surface/auth.ex`) — file-shape precedent for `Threadline.OperatorSurface.Coverage.OnMount`. Same `Code.ensure_loaded?(Phoenix.LiveView)` gate, same callback signature, same `attach_hook` pattern (auth uses `attach_hook(:handle_params, ...)`; coverage uses `attach_hook(:handle_info, ...)`).
- `Threadline.OperatorSurface.Style.css/1` (`lib/threadline/operator_surface/style.ex`) — CSS-variable themed `.threadline-ui` namespace. Phase 66 ADDS rules; no conflicts with Phase 65's `.button-cluster` / `.match-count-status` / `.truncation-banner` because the surface header is a sibling above the toolbar.
- `Threadline.Capture.RedactionPolicy.validate!/1` (`lib/threadline/capture/redaction_policy.ex:20-22`) — the precedent for `Threadline.Health.Policy.validate!/1`. Mirror the keyword/map dual-form, the raise-on-bad-shape posture, and the named module location under a per-subsystem subdirectory.
- `Threadline.Verify.CoveragePolicy.violations/2` (`lib/threadline/verify/coverage_policy.ex`) — existing CI-gate logic; ADD one additive case clause for `{:expected_uncovered, _}`. Existing tests and behavior are preserved for `{:covered, _}` / `{:uncovered, _}`.
- `Mix.Tasks.Threadline.VerifyCoverage` (`lib/mix/tasks/threadline.verify_coverage.ex`) — sibling task; reuse the `resolve_repo!/0` + `ensure_repo_started!/1` + `app.config + ssl + postgrex + ecto_sql` boot sequence verbatim in the new `Mix.Tasks.Threadline.Health.Coverage`.
- `lib/threadline/operator_surface/live/timeline_live.ex` lines 30-35 — pattern for calling `trigger_coverage/1` and folding the result into `Enum.flat_map/2`. Phase 66's `CoverageLive` extends the pattern to render all three buckets.
- `Phoenix.LiveView.attach_hook/4` — the primitive that lets `Coverage.OnMount` intercept `:threadline_refresh_coverage` `handle_info` messages across every LV in the `live_session` without touching individual LV `handle_info/2` clauses.
- `Process.send_after/3` + `Process.cancel_timer/1` — the polling primitive. Phase 66 stores the timer ref in `socket.assigns.threadline_timer_ref` so the manual "Refresh" button on `CoverageLive` can cancel-and-reschedule cleanly.

### Established Patterns

- **File-scope optional-deps gating:** every operator-surface module starts with `if Code.ensure_loaded?(<dep>) do defmodule … end end`. Phase 66's new files: `coverage/on_mount.ex`, `components/surface_header.ex`, `live/coverage_live.ex` all gate on `Phoenix.LiveView`. Mix task and `Health.Policy` are pure stdlib. `mix verify.compile_no_optional` enforces in CI.
- **CSS isolation:** every render block opens with `<div class="threadline-ui"><Threadline.OperatorSurface.Style.css /> …`. No layout component, no Tailwind utilities. Phase 66's `<.surface_header />` slots inside the existing `threadline-ui` div on each page.
- **Repo resolution:** `socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()` — same shape used throughout. `Coverage.OnMount` resolves identically. Mix tasks resolve via the existing `resolve_repo!/0` helper.
- **Doc-contract test posture:** pure source-reading tests (no LV bootup needed for literal pinning). BROWSE-04 / EXPO-05 are the templates for COV-03.
- **Atom-safety refute:** `refute String.contains?(src, "String.to_atom\\b")` regex pin (Phase 65's Pitfall 11). Carry forward to coverage_live.ex and the new Mix task.
- **Config namespacing:** Phase 65 introduced an unstated convention via `config :threadline, :verify_coverage`. Phase 66 introduces `config :threadline, :health` for the coverage knobs (`expected_uncovered_tables`, `audit_anyway`, `coverage_poll_ms`). Future health-related config lives here.
- **Auth scope threading:** `:authorize_fn`-returned scope is set on assigns by `on_mount`. Phase 66's `Coverage.OnMount` runs AFTER `Auth` in the `on_mount` chain (order matters in `live_session`); coverage queries use the same repo resolution but do NOT need scope (coverage data is global, not per-tenant — Threadline's host is a single trust boundary).
- **Mix-task parity:** every UI viewer ships with a Mix-task parity surface (precedent set in v1.17 with `mix threadline.incident`; reinforced in v1.18 by COV-03 and REDN-05). Phase 66 follows the convention literally.

### Integration Points

- **Edit:** `lib/threadline/health.ex` — add `:schema` opt + parameterize SQL + compute `:expected_uncovered` bucket + return three-tuple + emit telemetry with `expected_uncovered_count`. Update `@moduledoc` and `@doc` for `trigger_coverage/1` (document `:schema` is untrusted-by-callers; document the three-bucket shape; cross-link the Mix task).
- **Edit:** `lib/threadline/telemetry.ex` — `emit_health_checked/2` → `/3` (additive, keep `/2` as a delegate that calls `/3` with `0` for the new arg, OR replace and update the one in-tree caller in `Threadline.Health` directly — planner picks; cleanest is direct replacement since there is exactly one in-tree caller).
- **New file:** `lib/threadline/health/policy.ex` — `Threadline.Health.Policy.validate!/1`. Mirrors `Capture.RedactionPolicy.validate!/1` shape. Validates `:expected_uncovered_tables` and `:audit_anyway` config (binary entries, no duplicates, no unknown keys).
- **Edit:** `lib/threadline/verify/coverage_policy.ex` — one additive case clause for `{:expected_uncovered, _}`.
- **Edit:** `lib/threadline/operator_surface/router.ex` — append `Coverage.OnMount` to the `on_mount: [...]` list inside `live_session :threadline`; add `live("/coverage", CoverageLive, :index)` inside the existing scope.
- **New file:** `lib/threadline/operator_surface/coverage/on_mount.ex` (gated on `Phoenix.LiveView`). Implements `on_mount/4` per D-30: fetch coverage, assign `:threadline_coverage`, schedule first tick, attach the `:handle_info` hook for `:threadline_refresh_coverage`. Stores timer ref in `socket.assigns.threadline_timer_ref`.
- **New file:** `lib/threadline/operator_surface/components/surface_header.ex` (gated on `Phoenix.LiveView`). `surface_header(assigns)` function component per D-31. Reads `assigns.coverage.uncovered_count` and `assigns.coverage.last_checked_at`; renders the badge link to `"#{base_path}/coverage"`.
- **New file:** `lib/threadline/operator_surface/live/coverage_live.ex` (gated on `Phoenix.LiveView`). Renders three-bucket table, three-state badges (`covered` / `uncovered` / `expected`), schema in page header, manual "Refresh" link + last-checked timestamp, on-error inline strip. `handle_params/3` validates `?schema=NAME` per D-33a; on bad input, renders the form_error inline.
- **Edit:** `lib/threadline/operator_surface/style.ex` — add `.threadline-ui-header`, `.surface-badge`, `.surface-badge--ok`, `.surface-badge--warn`, `.coverage-table`, `.coverage-row--covered/uncovered/expected`, `--tl-header-height: 36px` CSS variable, and `top: var(--tl-header-height, 36px)` on the existing `.timeline-toolbar` rule.
- **Edit:** `lib/threadline/operator_surface/live/timeline_live.ex` — single render edit: `<.surface_header coverage={@threadline_coverage} base_path={@base_path} />` directly under `<Threadline.OperatorSurface.Style.css />`. Datalist call at line 30 stays unchanged (D-33b).
- **Edit:** `lib/threadline/operator_surface/live/transaction_live.ex` — single render edit: same one-line `<.surface_header />`.
- **Edit:** `lib/threadline/operator_surface/live/actor_live.ex` — single render edit: same one-line `<.surface_header />`.
- **New file:** `lib/mix/tasks/threadline.health.coverage.ex` — `Mix.Tasks.Threadline.Health.Coverage`. Default table format + `--json` + `--schema=NAME`. Mirrors `threadline.verify_coverage` boot sequence; does NOT exit 1 on uncovered.
- **Edit:** `lib/mix/tasks/threadline.verify_coverage.ex` — additive `--schema=NAME` flag with the same validation contract as D-33a; default behavior unchanged.
- **New file:** `test/threadline/operator_surface/coverage_doc_contract_test.exs` — pure source-reading test per D-35.
- **New file:** `test/threadline/operator_surface/live/coverage_live_test.exs` — LiveViewTest integration cases (mount renders three buckets; manual "Refresh" click; `?schema=NAME` validation; surface header on three sibling LVs).
- **New file:** `test/threadline/operator_surface/coverage_mix_test.exs` — Mix-task integration (default table output; `--json` schema; `--schema=NAME` plumbing).
- **Edit (small):** `test/threadline/operator_surface/live/timeline_live_test.exs`, `transaction_live_test.exs`, `actor_live_test.exs` — extend with one assertion each that the surface header renders with the expected count badge text.
- **Edit:** `guides/operator-surface.md` — new `## Coverage dashboard` section per the Documentation surfaces canonical refs.
- **Edit:** `guides/domain-reference.md` §"Trigger coverage (operational)" — update three-bucket return shape, `:schema` opt, new Mix-task name.
- **Edit:** `CHANGELOG.md` — v1.18 entry covering the API change and additive surface.

</code_context>

<specifics>
## Specific Ideas

- **Idiomatic anchor (D-30):** `phx.gen.auth`'s `UserAuth` module generates `on_mount/4` for `live_session`-shared assigns. Threadline's existing `Threadline.OperatorSurface.Auth` is the in-house parallel; `Coverage.OnMount` ships as a sibling.
- **Polling primitive (D-30):** Phoenix LiveDashboard's `PageLive` uses `Process.send_after(self(), :refresh, n)` with a configurable interval — direct precedent for the per-LV timer at 30s default.
- **Hook-as-cross-LV-glue (D-30):** `attach_hook(:name, :handle_info, fn)` lets one `on_mount` callback own the `handle_info(:threadline_refresh_coverage, …)` clause across every LV in the session — zero per-LV boilerplate, idiomatic since Phoenix LiveView 1.0.
- **Surface header palette (D-31a):** `#FEF3C7` bg / `#92400E` fg / `#F59E0B` accent matches Phase 65's truncation-warning amber band, for visual continuity of the "data-loss-adjacent" semantic across the surface.
- **"All covered" pill literal (D-31a):** explicit reassurance, never hidden — operator trust in audit tooling correlates with how loudly it confirms the boring case (Datadog, Sentry, GitHub Audit all do this).
- **Three-bucket return shape (D-32):** Carbonite's positive allowlist + Ecto's hardcoded `schema_migrations` skip — both establish that "intentional non-audit" tables are first-class in the ecosystem; the three-tuple makes Threadline's stance explicit instead of implicit.
- **Conservative baseline (D-32a):** `["schema_migrations"]` only — universal across every Ecto codebase ever; growing the list in lib means every adopter inherits Threadline maintainer judgment about what ISN'T worth auditing, which is the wrong default direction.
- **`:audit_anyway` escape hatch (D-32c):** name chosen for grep-discoverability; an operator wondering "why isn't `schema_migrations` audited?" greps for `expected_uncovered`, sees the baseline, then greps for `audit_anyway` to see the override path.
- **Schema validation at the edge (D-33a):** PostgREST's `db-schemas` allowlist is the closest precedent — schemas treated as untrusted, validated against `pg_namespace` before any query, never interpolated. The two-layer regex+catalog is belt-and-suspenders against typos AND injection.
- **Mix-task `--json` schema (D-34):** `expected_uncovered` as objects (not strings) so the `source` field surfaces baseline-vs-config provenance — `jq '.expected_uncovered[] | select(.source == "config")'` answers "what did my host config exempt?" without touching the LV.

</specifics>

<deferred>
## Deferred Ideas

- **PubSub-based single-source coverage broadcast** — out of v1.18 scope. If real adopter pain emerges at v1.19+ scale (50+ admin tabs on a busy 10k-table schema), document a `config :threadline, :coverage_source, {:pubsub, MyApp.PubSub}` opt-in escape hatch (D-30d). For now per-LV `Process.send_after` at 30s × N≈10 tabs is cheap.
- **`:persistent_term` cache for opportunistic external pokes** — research-suggested addition (telemetry handler writes; LVs read on tick) deferred. Adds machinery without solving a current pain point. Revisit if external-monitoring adopters report wanting their `mix` calls to update the LV without an LV poll cycle.
- **TimelineLive datalist refactor to read `:threadline_coverage`** — the forward-compat note at `timeline_live.ex:27-28` is conceptually satisfied by D-30, but the datalist call at line 30 stays bare (`trigger_coverage(repo: repo)`, no `:schema`) until adopter pain on long-lived sessions is reported. Out of Phase 66 scope.
- **Schema selector dropdown / multi-schema view / tabbed `:schema` route on the LV** — research-evaluated and rejected. Speculative complexity for the 5%; URL `?schema=NAME` covers the multi-tenant case cleanly. Revisit if adopter UX feedback specifically asks.
- **Drift surface header on Phoenix-host pages OUTSIDE `/audit/...`** — out of scope. The header lives inside the operator surface; broader cross-app drift visibility is a host concern, not lib concern.
- **Coverage history / "covered since when" timestamps** — out of scope; would require new capture machinery (`audit_coverage_runs` table writes), violates "broadens rather than hardens." Revisit in v1.19+.
- **Per-table "why was this table flagged?" detail page** — out of Phase 66 scope; the dashboard's badge + tooltip is sufficient. Operators investigating drift go to `mix threadline.gen.triggers` next, not deeper into the LV.
- **"Audit me" inline button on uncovered rows** — runtime policy edits violate read-only ceiling. Permanently out of scope at the surface layer; lives in `mix threadline.gen.triggers` regeneration.
- **Surface header on RowHistoryComponent specifically** — RowHistoryComponent renders inside TransactionLive's render block, so it inherits the header automatically; no separate edit needed. (Noted explicitly to avoid redundant integration-point work.)
- **`mix threadline.health.coverage` exit code on uncovered** — explicitly NOT a CI gate (D-34). The CI gate is the existing `mix threadline.verify_coverage` task. Folding the two would conflate "is my coverage correct?" (positive list) with "what's my coverage?" (viewer). Keep separate.
- **Adding `oban_jobs` / `oban_peers` to the hardcoded baseline** — explicitly rejected (D-32a). Adopter-declared via `:expected_uncovered_tables` config. Symmetry-breaking hardcodes seed silent drift.
- **Surface header showing per-schema counts** — explicitly out of scope (D-31b). Header always queries `"public"`; multi-schema is a drill-down on the dashboard.
- **Phase 67 forward-compat for the redaction admin** — REDN-03/04/05's drift-aware redaction admin will follow the same surface-header pattern (Phase 67's "drift detected" badge slots beside the coverage badge; Phase 67 picks the layout). Independent decisions; Phase 66's header is single-pill for now.

### Reviewed Todos (not folded)

None — no `.planning/todos/` matches surfaced for Phase 66.

</deferred>

---

*Phase: 66-coverage-dashboard-mix-task-parity*
*Context gathered: 2026-05-07*
