# Feature Research — v1.44 Behavioral Depth: Properties, Twins, Telemetry

**Domain:** Elixir/Ecto/PostgreSQL trigger-backed audit library — API/DX decisions for
telemetry (export, retention, query, install), `history/3` limit, deferred v1.42 health
CLI items, and the deferred backfill generator.
**Researched:** 2026-09-30
**Confidence:** HIGH (code citations verified against current `milestone/v1.44` tree at
`ca032824`; ecosystem precedent — Ecto, Oban, Phoenix, Finch, Broadway, `telemetry_metrics`,
OpenTelemetry semantic conventions, PaperTrail/Carbonite/Logidze — is well-established public
convention, not a single fetched source)

This file is a decision record for four milestone areas, not a competitor feature survey —
adapted from the standard template because the milestone question is "what exact API shape,"
not "what does the market expect." Table-stakes/differentiator framing is folded into each
area's verdict instead of kept as a separate section.

---

## A. Telemetry for export, retention, query, and install

### What exists today

`lib/threadline/telemetry.ex:1-113` documents five events, all `:telemetry.execute/3`
(none are spans):

| Event | Measurements | Metadata |
|---|---|---|
| `[:threadline, :transaction, :committed]` | `%{table_count}` | `%{}` |
| `[:threadline, :action, :recorded]` | `%{status}` | `%{}` |
| `[:threadline, :health, :checked]` | `%{covered, uncovered, expected_uncovered}` | `%{}` |
| `[:threadline, :health, :checked, :error]` | `%{}` | `%{error}` |
| `[:threadline, :health, :findings_checked]` | `%{errors, warnings}` | `%{}` |

Naming convention: `[:threadline, noun, verb_past_tense]`, with an occasional `.error`/`.error`-
suffixed sibling event for the failure path (`health.checked` / `health.checked.error`) rather
than a `status` field baked into one event. `action.recorded` breaks that pattern by putting
`status` inside `measurements` — `:telemetry`'s own convention is that measurements are numeric
(for `telemetry_metrics` `counter()`/`sum()`/`last_value()` to consume); an atom `status` there
is a pre-existing footgun, not something to copy into new events.

### Recommendation: keep execute-only as the default idiom; add exactly one span

Threadline's own precedent is uniform execute-first — introducing `:telemetry.span/3`
everywhere would fragment the library's telemetry idiom for no adopter benefit. But one
operation in this milestone is a genuine bounded "run" with a real start/stop and a real risk
of mid-run exceptions: retention purge. That is the one place a span earns its keep, exactly
the way Oban reserves `[:oban, :job, :start|:stop|:exception]` for the one thing that is
actually a supervised unit of work, while everything else in Oban (`:oban, :engine, ...`,
`:oban, :notifier, ...`) stays plain execute events. Ecto (`[:my_app, :repo, :query]`), Phoenix
(`[:phoenix, :endpoint, :start|:stop]` around the whole request, but `[:phoenix, :router_dispatch, :start|:stop]` per route), Finch, and Broadway all follow the same rule: span the outer
unit of work that can fail partway through, execute everything else.

**New events (all under existing `Threadline.Telemetry` naming convention):**

| Event | Shape | When | Measurements | Metadata |
|---|---|---|---|---|
| `[:threadline, :export, :completed]` | execute | after `Threadline.Export.to_csv_iodata/2`, `to_json_document/2`, `format_changes_iodata/3`, and the async governance export job succeed | `%{duration: native_time, row_count: non_neg_integer(), truncated: 0 \| 1}` | `%{format: :csv \| :json \| :ndjson, table: String.t() \| nil}` |
| `[:threadline, :export, :failed]` | execute | export raises or the governance job records `status: "failed"` | `%{}` | `%{format: ..., reason: String.t()}` (message only, never the failing row) |
| `[:threadline, :retention, :purge, :start\|:stop\|:exception]` | `:telemetry.span/3` | wraps the whole `Threadline.Retention.purge/1` call | span-standard (`:stop` adds `duration`) | `%{dry_run: boolean()}` (start); `:stop` adds `%{deleted_changes, deleted_transactions, batches_run}` |
| `[:threadline, :retention, :batch_purged]` | execute | once per batch loop iteration, nested inside the span | `%{deleted_changes: n, deleted_transactions: n, duration: native}` | `%{dry_run: boolean()}` |

**Query events: explicitly rejected (anti-feature).** Threadline calls the *host's* configured
`Ecto.Repo`, which already emits `[<host_app>, :repo, :query]` for every SQL statement Threadline
issues — same duration, same query text, same row-count-adjacent info, at the same or higher
fidelity, for zero new code. A parallel `[:threadline, :query, ...]` event would duplicate that
signal under a second name while adding real cardinality (`history`, `as_of`, `timeline`,
`row_history`, `actor_window`, `correlation_bundle` are all separate call sites hitting
`audit_changes`/`audit_transactions` repeatedly) with no new information. The correct answer is
**docs, not code**: document, in the `Threadline.Telemetry` moduledoc and the new telemetry
guide, how to filter the host's own `[:repo, :query]` handler by
`metadata.source in ~w(audit_changes audit_transactions audit_actions)` to get
Threadline-specific query observability today, with nothing to maintain. **Verdict: DEFER
(reshaped into a documentation recipe, not an event).**

**Install: DEFER — mix tasks stay silent on `:telemetry`.** `gen.triggers`, `gen.migration`, and
`gen.row_history_index` write migration *files*; the DDL itself runs later inside
`mix ecto.migrate`, in a process with no host-attached telemetry handlers (mix tasks call
`Application.ensure_all_started(:ecto_sql)` and start the bare repo — see
`lib/mix/tasks/threadline.health.coverage.ex:47-56` — not the host's own `Application.start/2`,
so handlers the host attaches in its own `start/2` are not running). This matches the ecosystem:
`mix ecto.migrate` and `mix oban.install` emit no telemetry either; CLI output is
`Mix.shell().info`/`Mix.raise`, which is the correct observability layer for a one-shot,
human/CI-driven command — precedent already established by
`lib/mix/tasks/threadline.health.coverage.ex` and `threadline.verify_coverage.ex`.
`mix threadline.retention.purge` and a future `mix threadline.export` are thin CLI wrappers
around the library functions above (`lib/mix/tasks/threadline.retention.purge.ex:1-50`
delegates to `Threadline.Retention.purge/1`) — when run inside a booted host app, or scripted
via `mix run -e`, the span/execute events fire automatically because they live in the library
function, not the task. No task-specific telemetry code is needed or wanted.

**PII / redaction interaction.** No event above carries `data_after`, `data_before`,
`changed_fields`, `table_pk`, `actor_ref`, `correlation_id`, or filter values (`from`/`to`).
Only counts, durations, `table` (name only — low cardinality, matches Ecto's own `:source`
metadata), and `format`/`dry_run` flags. This is deliberate: redaction (`RedactionPolicy`)
enforces at capture time, inside the trigger-generated SQL; a telemetry handler runs in-process
with no policy enforcement, so any temptation to attach a "sample row" to an event for debugging
would silently bypass redaction's guarantee. Flag this explicitly in the telemetry guide as the
one footgun to never introduce.

**Cardinality.** `table`/`format`/`dry_run` are bounded-cardinality metadata, safe for
dashboard grouping. `actor_ref`, `correlation_id`, and any UUID (job id, transaction id) must
never be used as a `telemetry_metrics` tag — document this the way Phoenix's own guides warn
against tagging on `request_id`.

**Docs: moduledoc table + guide.** Extend the `Threadline.Telemetry` moduledoc's "five events"
list to the new count, in the same table shape already used above. Add a new `guides/telemetry.md`
with the same event table, one `:telemetry.attach_many/4` example per operation, and the
`[:repo, :query]` filtering recipe for query observability — mirroring how `Oban.Telemetry`'s
moduledoc plus the Oban telemetry guide are the two places adopters look. Cross-link it from
`Threadline.Telemetry`'s moduledoc and the README's guide index.

**Verdict: INCLUDE** export + retention telemetry (5 new events/spans total), **DEFER** query
events (docs-only recipe) and install/mix-task telemetry (by design, not oversight). Semver-visible
(new public events are additive, not one-way — adopters who don't attach handlers see nothing
different) but the *event names and metadata shapes themselves* are one-way once published (Hex
can't unpublish); get the shapes above right before 0.12.0 ships them.

---

## B. `history/3` gets a `:limit`

### What exists today

`lib/threadline/query.ex:396-415` (`Threadline.history/3`, re-exported at
`lib/threadline.ex:95`) has no limit or paging option — it returns every matching row, ordered
`captured_at desc, id desc` (the tiebreak already exists at `query.ex:413-414`). A row with a
large change history returns unbounded today; that's a live correctness/ops risk (unbounded
memory, unbounded query time) for exactly the "large tables" case the milestone guide's §4 lens
calls out (DBA/SRE).

A parallel, already-shipped path exists for the *same* underlying data:
`Threadline.row_history_page/4` (`lib/threadline.ex:174`, `Investigation.row_history_page/4`,
backed by `Query.row_history_query/3` at `query.ex:430-441`, which reuses `timeline_order/1` —
the identical `captured_at desc, id desc` tiebreak) already does full keyset pagination with
`:page_size` (default 1000, validated by `Cursors.timeline_page_size!/1`, `query.ex:121`,
`is_integer and > 0`) and `:cursor`. `history/3` and `row_history`/`row_history_page` are two
entry points over the same rows — exactly the overlap v1.45's "1.0 API Contract" is scoped to
consolidate (`.planning/PROJECT.md` milestone_context; "Do not pre-empt that consolidation").

### Recommendation

Give `history/3` a **simple cap**, not a second pagination system. Precedent: PaperTrail's
`versions` association is an unbounded `has_many` an adopter limits with ordinary Ecto
(`limit: n` on the query, or `Ecto.assoc/2` composition) — PaperTrail does not ship a bespoke
limit option, it's just an Ecto query. Ash and Ecto both treat "cap a result set" and
"keyset-paginate a result set" as different concerns with different options
(`Ash.Query.limit/2` vs `Ash.Query.page/2`; Ecto's `limit/2` vs `Repo.stream/2` + cursors).
Threadline already draws that same line between `timeline/2` (eager, bounded) and
`timeline_page/2` (keyset) — `history/3` should gain the eager-bounded half of that pair, while
`row_history_page/4` stays the keyset half. Do not fold cursoring into `history/3`; that is
`row_history_page/4`'s job today and will be the thing v1.45 decides whether to merge.

**Exact shape:**

```elixir
Threadline.history(MyApp.User, 42, repo: MyApp.Repo, limit: 20)
```

- `:limit` — optional positive integer. **Default: `nil` (unbounded — identical to current
  0.11.2 behavior).** Applied via `Ecto.Query.limit/2` after the existing
  `order_by(captured_at desc) |> order_by(id desc)` in `history_query/3` (`query.ex:406-415`),
  so the cap always lands on the deterministically-ordered result, never on an unordered one.
- Validation mirrors the existing `Cursors.timeline_page_size!/1` pattern
  (`query.ex:121-124`): `is_integer(limit) and limit > 0`, else `raise ArgumentError`. **Reject
  `0` explicitly** rather than silently returning `[]` — `limit: 0` is far more likely a caller
  mistake (e.g. a miscomputed page-size variable) than an intentional "give me nothing," and
  Ecto's own `limit(query, 0)` would otherwise silently do exactly that with no signal.
- Moduledoc note pointing to `row_history_page/4`: "`:limit` caps the result; it does not page.
  For a row with more changes than you want in memory at once, use `row_history_page/4`."

**Why default `nil`, not a bounded default (e.g. 500).** A bounded default is a **one-way,
semver-visible, silently-breaking** decision: every existing caller of `history/3` — including
production incident-response code that expects "give me everything for this row" — would start
getting truncated results with no error, no warning, nothing in the return shape to signal
truncation (unlike `Export`'s `truncated`/`returned_count`/`max_rows` triple at
`lib/threadline/export.ex:31-34`, which *does* signal truncation because export was designed for
it from day one). For a security/compliance-reviewer-facing function whose whole job is "show me
every change," silently returning a subset is the worst kind of surprise this product can
produce, and CLAUDE.md's "every public default is one-way" rule applies directly. Keeping the
default unbounded costs nothing today (this is additive) and leaves the one-way call to v1.45,
where it belongs next to the history/row_history consolidation decision — **flag explicitly for
the roadmapper: v1.45 must decide, consciously, whether the consolidated entry point keeps an
unbounded default or adopts a bounded one; v1.44 should not make that call implicitly by
choosing a number now.**

**Verdict: INCLUDE.** Semver-visible (new public option, additive) but **not** the one-way
decision itself — the default choice (`nil`) is what defers the one-way risk to v1.45's contract
work, where it belongs.

---

## C. `health --strict`, `:invalid_config`, `--all-schemas`

### What exists today

- `mix threadline.verify_coverage` (`lib/mix/tasks/threadline.verify_coverage.ex:1-40`) is
  **already** the CI gate: exits 1 when an expected table (from a required, adopter-declared
  `config :threadline, :verify_coverage, expected_tables: [...]` positive list) is missing,
  uncovered, or has an `:error`-severity finding; `:warning` findings never fail it; an `:error`
  finding for a table *not* in the positive list is printed but doesn't fail. This is the
  established error-fails/warning-never-fails split.
- `mix threadline.health.coverage` (`lib/mix/tasks/threadline.health.coverage.ex:1-40`) is
  explicitly documented as a **viewer**: "ALWAYS exits 0, even when uncovered tables exist,"
  scans every table (not a positive list), and requires no config.
- `Threadline.Health.Finding` (`lib/threadline/health/finding.ex:1-64`) has five codes, all
  `:error` or `:warning`, "never `:info`": `legacy_trigger_no_pk_args` (warning), `pk_drift`,
  `shared_capture_function`, `duplicate_capture_trigger`, `capture_trigger_disabled` (all four
  `:error`).
- A malformed `config :threadline, :trigger_capture` **already** stops both mix tasks hard, via
  `Mix.raise/1` wrapping `TriggerCaptureConfig.load/0`'s `ArgumentError`
  (`threadline.health.coverage.ex:80-86`), **before** any findings are computed — not as a
  finding, as an immediate task failure.
- `trigger_findings/1` already scans **every** non-system schema by default when `:schema` is
  omitted (`lib/threadline/health.ex` doc for `trigger_findings/1`); only `trigger_coverage/1`
  (and therefore `health.coverage`'s coverage table) defaults to `"public"` alone, with
  `--schema=NAME` selecting one schema at a time (validated against `pg_namespace` via
  `CoverageSchemas`).

### `--strict`: INCLUDE

Give `mix threadline.health.coverage` a `--strict` flag: exit `1` if `trigger_findings/1`
returns **any `:error`-severity finding** in the scanned scope (all tables, not a positive
list); exit `0` on warning-only or clean. This is exactly `verify_coverage`'s existing
error-fails/warning-never-fails rule, minus the positive-list requirement — a genuinely useful,
additive shape for adopters who want "fail CI on any capture defect anywhere" without
maintaining an `expected_tables` allowlist (the two gates serve different scopes: `verify_coverage`
= "these specific tables must be covered"; `health.coverage --strict` = "nothing anywhere is
broken"). Exit-code convention matches the project's own `credo --strict` /
`mix format --check-formatted` / sobelow pattern already named in CLAUDE.md: warnings never
gate, errors always do, `--strict` is the opt-in the *adopter's* CI chooses, not something
Threadline's own `mix ci.all` runs against itself (Threadline's repo doesn't have arbitrary
host-schema tables to scan). `--json --strict` stays composable — print the JSON, then exit
nonzero, mirroring how sobelow/credo print full output before a nonzero exit.

### `:invalid_config`: DEFER (reshape into documentation, not a new Finding code)

Turning the already-hard `ArgumentError`/`Mix.raise` into a soft `:invalid_config` finding would
be a **regression**, not an enhancement: a raise stops the task immediately and loudly; a finding
only fails the task if `--strict` happens to be passed, and is otherwise just a row in a table an
operator could miss. The existing behavior is already the stricter, safer one. The only thing
missing is documentation making the existing raise-fast behavior explicit and intentional (add
one line to the `Threadline.Health.Finding` moduledoc: "a malformed
`config :threadline, :trigger_capture` raises before any finding is computed — this is
deliberate fail-fast behavior, not an omitted finding code"). **Do not add `:invalid_config` to
the `Finding.code()` union.**

### `--all-schemas`: INCLUDE (reshaped: schema-keyed output, not a flat merge)

`trigger_findings/1` already covers every schema by default; only the coverage table
(`trigger_coverage/1` / `health.coverage`) is public-only. Add `--all-schemas` to
`mix threadline.health.coverage`: enumerate every non-system schema (reuse `CoverageSchemas`'
existing `pg_namespace` discovery/validation, the same helper `--schema=NAME` already uses) and
render the report **per schema** rather than flattening — a `SCHEMA` column added to the default
table output, and a schema-keyed JSON object (`{"public": {...}, "tenant_42": {...}}`) rather
than a merged flat list, so `--json --all-schemas` output is unambiguous about which schema each
row belongs to. `--schema=NAME` and `--all-schemas` are mutually exclusive; passing both is
`Mix.raise`. This directly serves the milestone guide's §4 "multiple Postgres schemas" adopter
shape (multi-tenant schema-per-tenant apps) with one command instead of a shell loop, and
combines naturally with `--strict` for "fail CI if any tenant schema anywhere has a capture
error."

**Verdict: `--strict` INCLUDE, `:invalid_config` DEFER (documentation only, no new code),
`--all-schemas` INCLUDE.** None of the three are one-way in the risky sense — `--strict` and
`--all-schemas` are new opt-in flags (default behavior of `health.coverage` is unchanged), and
declining to add `:invalid_config` leaves existing behavior untouched. The `Finding.code()`
union itself, however, **is** worth flagging as a standing footgun independent of this
milestone: any exhaustive `case f.code do ... end` a caller writes today will fail to compile —
or silently miss cases at runtime for a non-exhaustive `case`/`cond` — against a future added
code (this and any later milestone). Document "the code list may grow across minor releases;
always include a catch-all clause" once, in the `Finding` moduledoc, rather than treating each
future addition as its own one-way decision.

---

## D. `mix threadline.gen.backfill`

### What exists today

The backfill story for v1.42's `table_pk` change is **already shipped**, as a documented,
adopter-owned SQL recipe rather than a generator:

- `guides/upgrading-to-0.11.md:126-224` ("Step 6 (optional): Backfill unresolved primary keys")
  has fully-written, marker-delimited (`<!-- threadline:backfill-sql:start/end -->`,
  `...-composite:...`), parameterized `UPDATE ... WHERE id IN (SELECT ... LIMIT <batch_size>)`
  SQL for both single-column and composite (2-column) keys, batched, idempotent (safe to rerun
  and to run two overlapping copies), scoped to `op IN ('insert','update')` only, and explicit
  about what it can never recover: DELETE rows (no pre-0.11 row image) and redacted key columns
  (never written to `audit_changes` at all).
- `test/threadline/upgrade_backfill_test.exs` and `test/threadline/upgrade_path_doc_contract_test.exs`
  indicate this SQL is executed against real PostgreSQL and doc-contract-tested — matching
  CLAUDE.md's "Doc contract tests" convention (README/guides stay aligned via test assertions).
- The v1.42 audit (`.planning/milestones/v1.42-MILESTONE-AUDIT.md:22`) already flags the one real
  gap: "3+ column composite-key backfill extension described, not shown" — the guide *describes*
  how to extend the 2-column SQL to N columns (one more `jsonb_build_object` pair, one more `?&`
  array entry, one more `IS NOT NULL` guard) but doesn't show a worked 3-column example.

"Legacy rows" here means pre-0.11 `audit_changes` rows whose `table_pk` is `{"id": null}`
(written before 0.11's PK-agnostic capture) or `{}` (written by 0.11 when a key couldn't be
resolved at capture time) — i.e. rows a non-`id`-keyed or composite-keyed table's `history/3`
call silently excludes today, because `where_row/2` (`query.ex:423-428`) matches `table_pk`
exactly.

### Recommendation: DEFER the generator; INCLUDE the missing health signal instead

**Generator — DEFER, effectively a standing anti-feature.** Ecosystem precedent (Carbonite,
PaperTrail, Logidze) is that backfill is documented SQL or a documented Ecto script, not a
shipped generator — because backfill is a one-time, per-adopter, per-table operation whose
parameters (schema, table, key columns — 1, 2, or N of them, in order — batch size, whether to
dry-run) don't compress well into a generic Mix task without either being too rigid (breaks past
2 columns without the very extension the v1.42 audit already flagged as unproven) or reinventing
`mix ecto.gen.migration` badly. Oban's own precedent (`mix oban.install`) generates a fixed,
well-known migration with no adopter-supplied parameters — a fundamentally simpler generation
problem than "generate SQL parameterized by an arbitrary key-column list." The already-shipped
path — `mix ecto.gen.migration backfill_<table>_pk`, paste the guide's SQL, substitute the
documented placeholders, `mix ecto.migrate` — is two ordinary commands plus a copy-paste, is
already host-owned (keeps the CLAUDE.md "host-owned migrations" boundary cleanly, no new
Threadline-authored migration-generation code to maintain), and is already tested. Building a
generator to save that one copy-paste is negative leverage for a rung the milestone guide says
to push "until returns diminish." Only revisit if real adopter friction on 3+ column composite
keys shows up (in which case a worked 3-column example in the guide, not a generator, is almost
certainly still the right fix).

**The health finding — INCLUDE, reshaped.** The one thing that's genuinely missing is
*detectability*: nothing today tells an adopter, without hand-running a `count(*) ... WHERE
table_pk = '{}'::jsonb` query, that they still have unresolved legacy rows, or for which tables.
Add a new `Finding` code:

- **`:unresolved_legacy_keys`**, severity `:warning` (this is optional cleanup, not a capture
  defect — capture is working correctly today for these tables; it only affects reading
  pre-upgrade history by key). Computed per `{table_schema, table_name}` as roughly
  `SELECT table_schema, table_name, count(*) FROM audit_changes WHERE op IN ('insert','update')
  AND (table_pk = '{"id": null}'::jsonb OR table_pk = '{}'::jsonb) GROUP BY 1, 2`, scoped by the
  same `:schema` option other findings already take. `details` carries `%{"unresolved_count" =>
  n}`. `message` points straight at the existing guide anchor: `"N unresolved legacy rows in
  <schema>.<table>; see guides/upgrading-to-0.11.md#step-6-optional-backfill-unresolved-primary-keys."`
- Because it's `:warning` severity, it does **not** fail `--strict` (area C) by default — correct,
  since unresolved legacy rows are optional cleanup, not a live capture bug — while still
  showing up in `mix threadline.health.coverage`'s FINDINGS section and `trigger_findings/1`'s
  return value for adopters who want to track it.
- This is additive to the `Finding.code()` typespec union (see the catch-all-clause footgun
  flagged in area C) and does not touch capture, trigger generation, or any one-way default.

**Verdict: generator DEFER (durable anti-feature, not just "later"); health finding INCLUDE
(reshaped as a new warning-severity `Finding` code, not a generator, not a separate mix task).**
Neither is one-way: the generator not existing is the status quo, and a new warning-severity
finding is additive and silent-by-default under `--strict`.

---

## One coherent recommendation across A–D

All four areas converge on the same posture, consistent with the existing
`[:threadline, noun, verb_past_tense]` telemetry naming and the v1.45 contract work ahead:

1. **Instrument the two genuinely long-running, genuinely failure-prone operations** (retention
   purge as a span, export completion as execute events) and **say no to duplicating what Ecto
   and the OS process boundary already give you for free** (query telemetry, mix-task telemetry).
2. **Add options with `nil`/unbounded, backward-compatible defaults** (`history/3`'s `:limit`)
   rather than take a one-way bounded-default decision this milestone doesn't need to take —
   leave that call for v1.45's consolidation, where it belongs next to `history`/`row_history`
   merging.
3. **Extend the existing error/warning finding-and-gate machinery** (`--strict`, `--all-schemas`,
   `:unresolved_legacy_keys`) rather than inventing new machinery, and **don't weaken an
   already-stricter fail-fast behavior** into a softer, opt-in one (`:invalid_config`).
4. **Prefer the documented, host-owned, already-tested path over a new generator** when the
   generator would only reproduce what a copy-paste and `mix ecto.gen.migration` already do
   cleanly — spend the generator's would-be effort on the one real gap (the health signal)
   instead.

### Requirement candidates for the roadmapper (exact names)

| # | Requirement | Verdict | One-way? |
|---|---|---|---|
| 1 | `[:threadline, :export, :completed]` / `[:threadline, :export, :failed]` execute events on `Threadline.Export.to_csv_iodata/2`, `to_json_document/2`, `format_changes_iodata/3`, and the governance export job | INCLUDE | Event shape is one-way once published; no default behavior change |
| 2 | `:telemetry.span/3` around `Threadline.Retention.purge/1` as `[:threadline, :retention, :purge, :start\|:stop\|:exception]`, plus `[:threadline, :retention, :batch_purged]` execute per batch | INCLUDE | Event shape one-way; no default behavior change |
| 3 | `[:threadline, :query, ...]` events | ANTI-FEATURE / DEFER | Document `[:repo, :query]` filtering by `source` instead |
| 4 | Telemetry emitted from inside Mix task bodies (`gen.triggers`, `gen.migration`, `gen.row_history_index`, `retention.purge`, future `export`) | ANTI-FEATURE / DEFER | Library functions already emit for free when run inside a booted app |
| 5 | `Threadline.history/3` gains `:limit` (optional positive integer, default `nil`/unbounded, `ArgumentError` on `0`/negative/non-integer) | INCLUDE | Additive option; default choice defers the one-way bounded-default call to v1.45 |
| 6 | `mix threadline.health.coverage --strict` (exit 1 on any `:error` finding in scope, exit 0 otherwise; composable with `--json`) | INCLUDE | New opt-in flag; no default behavior change |
| 7 | `Threadline.Health.Finding` code `:invalid_config` | DEFER / documentation-only | N/A — no new code; existing raise-fast stays |
| 8 | `mix threadline.health.coverage --all-schemas` (schema-keyed table/JSON output, mutually exclusive with `--schema=NAME`) | INCLUDE | New opt-in flag; no default behavior change |
| 9 | `mix threadline.gen.backfill` generator | DEFER (durable anti-feature) | N/A — status quo (guide SQL + `mix ecto.gen.migration`) stands |
| 10 | New `Finding` code `:unresolved_legacy_keys` (`:warning`), counting pre-0.11 `table_pk = {"id": null}` / `{}` rows per table, message linking to the existing upgrade guide's Step 6 | INCLUDE | Additive `Finding.code()` union widening; silent under `--strict` by default |

### Explicit anti-features (do not build)

- A `[:threadline, :query, ...]` telemetry event duplicating the host's own `[:repo, :query]`.
- Telemetry calls inside Mix task bodies.
- A soft `:invalid_config` `Finding` replacing the existing hard `Mix.raise`/`ArgumentError`.
- `mix threadline.gen.backfill` as a parameterized SQL-generating Mix task.
- Any telemetry metadata carrying row data, `actor_ref`, `correlation_id`, or filter values —
  counts, durations, table names, and format/flag atoms only.
- A bounded default for `history/3`'s new `:limit` in this milestone (leave the number, if any,
  to v1.45's contract work).

## Sources

- Code: `lib/threadline/telemetry.ex:1-113`; `lib/threadline/query.ex:340-441` (tiebreak,
  `history_query/3`, `row_history_query/3`, `Cursors.timeline_page_size!/1` at line 121);
  `lib/threadline.ex:80-209`; `lib/threadline/export.ex:1-60` (moduledoc, `max_rows`,
  streaming caveat); `lib/threadline/retention.ex:1-30`; `lib/mix/tasks/threadline.retention.purge.ex:1-50`;
  `lib/threadline/health.ex` (moduledoc, `trigger_findings/1`/`trigger_coverage/1` schema-scope
  docs); `lib/mix/tasks/threadline.health.coverage.ex:1-95` (viewer semantics, `--schema`
  validation); `lib/mix/tasks/threadline.verify_coverage.ex:1-40` (gate semantics, exit-code
  convention); `lib/threadline/health/finding.ex:1-64` (code union, severity contract);
  `lib/threadline/capture/trigger_capture_config.ex` (existing raise-fast config validation);
  `lib/threadline/governance/export_job.ex`, `lib/threadline/governance/retention_run.ex`
  (durable governance-run rows, complementary to telemetry); `guides/upgrading-to-0.11.md:100-224`
  (backfill SQL, marker-delimited, batching/idempotency guarantees, what cannot be recovered).
- Project state: `.planning/PROJECT.md` (Current Milestone: v1.44, Deferred to v1.44 list,
  v1.42 delivered summary); `.planning/milestones/v1.42-MILESTONE-AUDIT.md:22-26` (exact deferral
  wording for `gen.backfill`, `--strict`, `:invalid_config`, `--all-schemas`, and the 3+ column
  composite-key gap); `.planning/MILESTONE-GUIDE.txt` §3 (product boundaries, host-owned
  migrations, one-way public defaults), §4 (adopter/DBA/SRE lenses, multi-schema adopter shape),
  §8 (quality/evidence bar), §9 (CI economy), §9a (performance/architecture).
- Ecosystem precedent (established public convention, general knowledge — not a single fetched
  URL): Ecto (`[:my_app, :repo, :query]` per-query telemetry, `limit/2` vs `Repo.stream/2`
  keyset pagination split); Oban (`[:oban, :job, :start|:stop|:exception]` span reserved for the
  one supervised unit of work; `Oban.Migration`/`mix oban.install` generates a fixed migration
  with no adopter-supplied parameters; no telemetry from the install task itself); Phoenix
  (`[:phoenix, :endpoint, :start|:stop]`, `[:phoenix, :router_dispatch, :start|:stop]`); Finch
  and Broadway (span around the unit of work that can fail partway through, execute for
  finer-grained detail); `telemetry_metrics` conventions (numeric measurements, bounded-cardinality
  metadata/tags — never IDs); OpenTelemetry semantic conventions (span for a bounded operation
  with a real start/stop, event for a point-in-time occurrence); PaperTrail (`versions` is an
  unbounded Ecto association, capped by ordinary `limit:`, no bespoke limit option); Ash
  (`Ash.Query.limit/2` vs `Ash.Query.page/2` as separate concerns, mirroring `timeline/2` vs
  `timeline_page/2`); Carbonite/PaperTrail/Logidze (backfill is documented SQL/Ecto scripts, not
  a generator, because parameters vary too much per adopter/table); Credo `--strict` and Sobelow
  (opt-in stricter gate, warnings vs. findings-that-fail, consistent with CLAUDE.md's cited
  `mix format --check-formatted` / `mix verify.*` conventions).
