# Phase 66: Coverage Dashboard & Mix Task Parity - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `66-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-05-07
**Phase:** 66-coverage-dashboard-mix-task-parity
**Areas discussed:** Surface header, Expected-uncovered policy, Refresh behavior, Schema scope on the dashboard

---

## Discussion shape (research-then-recommend)

User invoked `/gsd-discuss-phase 66`. After the initial gray-area selection (all 4 areas selected), the user immediately reinforced the standing project rule: "research using subagents… think deeply one-shot a perfect set of recommendations so i don't have to think, all recommendations are coherent/cohesive with each other." The first attempt to ask area-by-area sub-questions WITHOUT prior research was rejected. The standing memory (`gsd-research-then-recommend.md`) was updated to add Phase 66 as the third reinforcement of the rule (joining v1.18 scoping + Phase 64 discuss-phase) and to clarify that the trigger is "any AskUserQuestion that lists architectural / UX / scope / dependency options," including per-area sub-questions inside discuss-phase, not just the top-level "which areas to discuss" gate.

Four parallel `gsd-advisor-researcher` agents were dispatched (one per gray area), each producing a structured comparison table + per-option pros/cons/footguns + a single recommendation. Synthesis combined the four picks into one coherent set, presented as a single confirm/override AskUserQuestion. User accepted all four.

---

## Surface header (where the uncovered count lives so an operator notices drift from any screen)

| Option | Description | Selected |
|--------|-------------|----------|
| Shared header on every LV (per-LV count fetch) | Phoenix.Component invoked atop each LV; per-LV `Process.send_after` timer | |
| Coverage-page-only banner | Banner only on `/audit/coverage`; cheaper but defeats COV-01's "from any screen" intent | |
| Timeline-only header | Header on `/audit` (Timeline) only; misses deep-linked Transaction/Actor pages | |
| `live_session` `on_mount` hook + shared `surface_header` Phoenix.Component (proposed by research) | Single source of truth via `attach_hook(:handle_info, ...)` from a new `Coverage.OnMount`; mirrors existing `Threadline.OperatorSurface.Auth` shape; surface-header function-component reads `@threadline_coverage` from parent LV's assigns | ✓ |

**User's choice:** "Accept all 4" (research recommendation set).
**Notes:** Choice satisfies COV-01 "from any screen" by construction (no LV in the session can opt out). Single source of truth eliminates per-LV polling. Mirrors `Threadline.OperatorSurface.Auth.on_mount/4` precedent. No PubSub, no GenServer — keeps `phoenix_pubsub` `optional: true`. Visual treatment: explicit "All covered" pill when uncovered_count == 0 (never hidden — audit tooling earns trust by loudly confirming the boring case); amber `{n} uncovered` pill matching Phase 65's truncation-warning palette for visual continuity.

---

## Expected-uncovered policy (how operators tell Threadline that `schema_migrations`, `oban_jobs`, etc. are intentional non-audits)

| Option | Description | Selected |
|--------|-------------|----------|
| Hardcode in lib | All "expected uncovered" tables baked into `Threadline.Health` (e.g. `schema_migrations`, `oban_*`) | |
| Config-driven (no default) | Adopter declares everything via `config :threadline, :expected_uncovered, [...]` | |
| Heuristic match | Regex/glob on names (`*_migrations`, `oban_*`); zero adopter config | |
| Reuse `:verify_coverage, :expected_tables` inverted | Existing positive list defines "must be covered"; everything else = "expected uncovered" | |
| Hybrid (minimal hardcoded baseline + adopter-configurable additions) | `["schema_migrations"]` baseline only; adopter adds via `config :threadline, :health, expected_uncovered_tables: [...]`; override-to-audit via `:audit_anyway` | ✓ |

**User's choice:** "Accept all 4" (research recommendation set).
**Notes:** Hybrid was chosen because (a) zero-config day-1 DX for the 95% (no false-positive drift on `schema_migrations`), (b) Oban tables explicitly NOT baselined to avoid silent drift on hypothetical domain tables sharing the name, (c) `:audit_anyway` escape hatch for the extreme corner case of wanting to audit `schema_migrations`. Three-tuple return shape `[{:covered | :uncovered | :expected_uncovered, table}]` is additive — existing pattern matches keep working. `Threadline.Verify.CoveragePolicy.violations/2` gets one additive case clause. Telemetry `emit_health_checked/2` becomes `/3` with `expected_uncovered_count` (additive). Mix-task `--json` schema includes `source: "baseline" | "config"` per row for grep-discoverability.

---

## Refresh behavior (auto-poll vs manual vs hybrid; on-error UX; how the every-page header gets fresh data)

| Option | Description | Selected |
|--------|-------------|----------|
| Auto-poll only | Per-LV `Process.send_after`; no manual button | |
| Manual button only | Operator clicks "Refresh"; no timer | |
| Hybrid (auto-poll + manual button) | Both — Oban Web pattern | |
| PubSub broadcast | Single GenServer source-of-truth; broadcasts to all LVs | |
| Telemetry hook (LV attaches in mount) | LVs subscribe to `:health_checked` | |
| Hybrid + telemetry hook + `:persistent_term` cache (research-proposed combination) | Per-LV timer for primary refresh; application-level `:telemetry.attach_many/4` opportunistically populates a cache; LVs read cache on each tick | (concept — simplified at synthesis) |

**User's choice:** "Accept all 4" (research recommendation set).
**Notes:** During synthesis the research-proposed `:persistent_term` cache layer was simplified out (per the cohesive-set principle): the `live_session` `on_mount` hook from the surface-header research already gives single-source-of-truth across LVs without needing a cache layer. Final shape: per-LV `Process.send_after(self(), :threadline_refresh_coverage, 30_000)`, intercepted by a hook in `Coverage.OnMount` that owns the `handle_info` clause across all LVs. Default 30s, configurable via `config :threadline, :coverage_poll_ms`, floor 5_000ms (raise below). Manual "Refresh" button only on `CoverageLive` (cancels stored timer ref). On-poll-error: keep last-good assign, set `:threadline_coverage_error` message, render inline yellow strip on dashboard + small "stale" tooltip on header pages, ALWAYS reschedule. The existing `[:threadline, :health_checked]` telemetry event stays the COV-02 "hookable" surface — no new mechanism needed. Documented escape hatch (`config :threadline, :coverage_source, {:pubsub, ...}`) for v1.19+ if real adopter scale demands it.

---

## Schema scope on the dashboard (how the `:schema` dimension is exposed in LV + Mix task)

| Option | Description | Selected |
|--------|-------------|----------|
| Hardcode `"public"` everywhere except the lib API | Lib API change only; no LV/Mix exposure | |
| URL query param `?schema=NAME` + `--schema=NAME` flag | Operator types schema in URL or flag; validated against `pg_namespace` | ✓ |
| In-page schema selector dropdown | Allowlist sourced from `pg_namespace`; UI widget | |
| Multi-schema view in one table | Lib API extended to `:schemas` (list); rows grouped by schema | |
| Tabbed `:schema` route | `/audit/coverage/:schema` route; one tab per schema | |

**User's choice:** "Accept all 4" (research recommendation set).
**Notes:** URL `?schema=NAME` chosen because (a) matches Phase 64's existing `?from=&to=&table=` LV idiom, (b) parity-clean with the Mix task `--schema=NAME` flag (same name, same validation), (c) zero new UI for the 95% single-schema case, (d) operator-typing-the-URL is acceptable admin UX (LiveDashboard, Oban Web rely on it). Validation lives at the LV/Mix EDGE (NOT in `Threadline.Health`): two-layer regex `\A[a-z_][a-z0-9_]{0,62}\z` first, then `SELECT 1 FROM pg_namespace WHERE nspname = $1` parameterized. Surface header always queries `"public"` (global drift signal stays simple; multi-schema is opt-in via dashboard URL). `mix threadline.verify_coverage` gets the same `--schema=NAME` flag for parity. TimelineLive datalist (line 30) stays bare — out of scope for COV-02. Forward-compat note at `timeline_live.ex:27-28` is conceptually satisfied; literal refactor deferred until adopter pain.

---

## Claude's Discretion

Areas captured in `66-CONTEXT.md` §"Claude's Discretion" where the planner/researcher/executor has flexibility:

- Exact CSS rule names within `.threadline-ui` namespace beyond the locked literals.
- Exact keyset/struct shape of the `:threadline_coverage` socket assign.
- Exact wording of the on-poll-error inline strip on `CoverageLive`.
- Whether `Threadline.Health.Policy.validate!/1` lives at `lib/threadline/health/policy.ex` (recommended) or `lib/threadline/health.ex`-internal.
- Exact column widths / alignment of the Mix-task default table format (must be readable on 80-col terminal).
- Exact CHANGELOG wording for the `:health_checked` telemetry-event metadata change.
- Whether the page-header timestamp on `CoverageLive` ("Last checked Xs ago") is static or 1Hz-driven.
- Whether the surface header brand label is just `"Threadline"` wordmark or includes a small logo.

---

## Deferred Ideas

Captured in `66-CONTEXT.md` §"Deferred Ideas". Highlights:

- PubSub-based single-source coverage broadcast — documented opt-in escape hatch for v1.19+ scale.
- `:persistent_term` cache for opportunistic external pokes — research-proposed but simplified out at synthesis.
- TimelineLive datalist refactor to read `:threadline_coverage` — forward-compat satisfied conceptually, literal refactor deferred until adopter pain.
- Schema selector dropdown / multi-schema view / tabbed `:schema` route — research-evaluated and rejected as speculative complexity for the 5%.
- Drift surface header on Phoenix-host pages outside `/audit/...` — host concern, not lib concern.
- Coverage history / "covered since when" timestamps — would broaden rather than harden; v1.19+.
- Per-table "why was this table flagged?" detail page — badge + tooltip is sufficient.
- "Audit me" inline button on uncovered rows — runtime policy edits violate read-only ceiling permanently.
- `mix threadline.health.coverage` exit code on uncovered — explicitly NOT a CI gate (`mix threadline.verify_coverage` is).
- Adding `oban_jobs` / `oban_peers` to the hardcoded baseline — explicitly rejected; adopter-declared.
- Surface header showing per-schema counts — out of scope; always queries `"public"`.
- Phase 67 forward-compat for the redaction admin badge — Phase 67 picks layout when REDN drift-detected badge slots beside coverage badge.
