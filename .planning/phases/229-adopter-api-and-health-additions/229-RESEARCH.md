# Phase 229: Adopter API and Health Additions - Research

**Researched:** 2026-10-02
**Domain:** Elixir/Ecto query API additions + Mix CLI health-gate extensions (PostgreSQL catalog introspection)
**Confidence:** HIGH

## Summary

This phase is almost entirely a codebase-grounded implementation exercise: 229-CONTEXT.md already
contains 28 locked decisions (D-01..D-28) reached via four parallel researchers and a roll-up
confirm, and `.planning/research/FEATURES.md` §B-D already covers the domain tradeoffs. This
RESEARCH.md's job is narrower: confirm the exact file:line anchors CONTEXT cites, verify the single
open empirical question the ROADMAP flagged (does any existing test pin `health.coverage`'s
per-severity exit codes?), and surface a few small factual corrections found while reading the
source.

**Key verified facts:**
- `Threadline.Query.history/3` (query.ex:396-402) and its private `history_query/3` (query.ex:405-415)
  have no `:limit` handling today — confirmed by reading the full function bodies.
- `Threadline.Evidence`'s `validate_limit!/1` (evidence.ex:313-317) and `maybe_limit/2`
  (evidence.ex:345-346) are the exact precedent CONTEXT cites, verbatim.
- `mix threadline.health.coverage`'s `OptionParser.parse(argv, strict: [json: :boolean, schema: :string])`
  (threadline.health.coverage.ex:50) discards the third tuple element, so an unknown/misspelled
  flag passes silently today — this is the live bug D-16 fixes.
- **No existing test pins per-severity exit codes of `health.coverage`.** The closest test,
  `"the task returns :ok (no exit) with an error finding present"`
  (coverage_mix_test.exs:260-262), proves the current (no-`--strict`) behavior never exits
  non-zero even with an `:error` finding present — it does **not** pin any strict-mode exit
  behavior, because `--strict` does not exist yet. This directly confirms the ROADMAP's research
  note: **the Phase 229 matrix test (D-09) is the baseline, not a regression check.**
- `verify_coverage.ex:83-85` already uses `exit({:shutdown, 1})` — the exact precedent D-06 cites,
  confirmed verbatim.
- The pre-0.11 legacy-key fixture infrastructure (`test/support/legacy_trigger_sql.ex`,
  `test/threadline/upgrade_backfill_test.exs`) already exists, seeds a real 0.10.2-shaped trigger
  via `LegacyTriggerSQL.v0_10_2_install_function/2`, and the guide's marker-delimited backfill SQL
  (`guides/upgrading-to-0.11.md:145-158`) matches D-19's probe predicate almost verbatim
  (`table_pk = '{"id": null}'::jsonb OR table_pk = '{}'::jsonb`, `op IN ('insert','update')`).
- One correction to CONTEXT D-25: the `guides/configuration-and-commands.md` config table has no
  column literally named "Failure-mode" — its header is `Key | Purpose and accepted shape |
  Default or absence behavior | Primary owner` (configuration-and-commands.md:17). The sentence
  belongs in the **"Default or absence behavior"** cell of the `trigger_capture` row (line 22);
  flag this for the planner so the task doesn't search for a nonexistent column name.

**Primary recommendation:** Follow 229-CONTEXT.md's 28 decisions as written; this research's value
is in the file:line confirmations below (so the planner can cite them directly in PLAN.md tasks)
and the one correction above.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `history/3` `:limit` validation + cap | API / Backend (Ecto query layer, `Threadline.Query`) | — | Pure Ecto query-building code; no DB schema change, no CLI involvement |
| `--strict` exit-code gate | CLI / Mix Task (`Mix.Tasks.Threadline.Health.Coverage`) | API / Backend (`Threadline.Health.trigger_findings/1`, unchanged) | The gate decision (exit code) is a CLI-only concern layered on an unchanged library function |
| `--all-schemas` multi-schema report | CLI / Mix Task | Database / Storage (catalog queries: `pg_tables`, `pg_depend`) | Task-only per D-11 (no new public API); batched catalog queries own the cross-schema scan |
| `:unresolved_legacy_keys` finding | API / Backend (new `Threadline.Health.legacy_key_findings/1`) | Database / Storage (`audit_changes` scan, capped per-table probe) | New public API surface per D-18, callable without `mix`; backed by a bounded per-table SQL probe |
| `:trigger_capture` fail-fast doc | Documentation only | — | No code change (HLTH-04 is doc-only per the anti-features table) |

## User Constraints

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

See 229-CONTEXT.md D-01 through D-28 (28 decisions across four areas: A. `history/3` `:limit`,
B. `--strict`, C. `--all-schemas`, D. `:unresolved_legacy_keys` + fail-fast doc, plus
cross-cutting D-27/D-28). Full text is in `.planning/phases/229-adopter-api-and-health-additions/229-CONTEXT.md`
and is **not** re-litigated here — this research confirms the file:line anchors those decisions
cite and does not propose alternatives.

Phase boundary (verbatim): "Additive adopter-facing API and CLI work, released together in one
0.12.0 CHANGELOG section: `Threadline.history/3` takes an optional `:limit` cap (QRY-01, QRY-02).
`mix threadline.health.coverage` gains `--strict` (HLTH-01) and `--all-schemas` (HLTH-02). A new
`:unresolved_legacy_keys` warning finding (HLTH-03). Documentation that malformed
`:trigger_capture` config raises (HLTH-04). Every default behavior stays unchanged."

Explicitly OUT of scope: consolidating `history`/`row_history` (deferred to v1.45), a backfill
generator (`mix threadline.gen.backfill` — a durable anti-feature), and a new `:invalid_config`
finding code.

### Claude's Discretion

- Exact stderr status-line wording, and column widths/padding in the `--all-schemas` table.
- Whether the timed-out legacy probe surfaces as a raise or a sentinel in the public function (D-20).
- Module and file split (e.g. `lib/threadline/health/legacy_key_findings.ex`, location of the
  batched catalog helper).
- Whether to add an optional incident-playbook sentence about `limit:` with a matching contract
  assertion.

### Deferred Ideas (OUT OF SCOPE)

- Coverage/findings exclusion mismatch (threadline_export_jobs, threadline_retention_runs,
  threadline_saved_views, threadline_evidence_records showing as "uncovered"; extension-member
  tables like `spatial_ref_sys`) — own backlog item, own scope decision.
- v1.45 API contract: umbrella `Health.findings/1`, public multi-schema coverage API, `@spec` for
  `history/3` opts, `:limit` on `timeline/2`/`actor_history/2`/`row_history`.
- `actor_history/2`'s already-unvalidated `:limit` (query.ex:534) — fix belongs to v1.45.
- Separate exit codes (1 = findings, 2 = usage) across all mix tasks — coordinated later change.
- `--fail-on-uncovered` for `health.coverage` — only if a future requirement asks for it.
- `--summary` condensed output for `--all-schemas` — additive later if adopters ask.

</user_constraints>

## Phase Requirements

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QRY-01 | `Threadline.history/3` accepts `limit: n`, newest-first, `captured_at desc, id desc` tiebreak, `0`/negative/non-integer raise `ArgumentError` | query.ex:396-415 confirmed as the exact insertion points (D-01, D-02); evidence.ex:313-317/345-346 confirmed as the validator/apply precedent |
| QRY-02 | A test proves no-`:limit` behavior is unchanged; CHANGELOG states additive/default-unchanged | query_test.exs:411 "history/3 applies support scope" confirmed as the fixture D-04 says to reuse; CHANGELOG.md Unreleased structure confirmed (Breaking changes / feature sections) |
| HLTH-01 | `--strict` nonzero exit on any `:error` finding, composes with `--json`, non-strict exit unchanged, matrix test proves both | verify_coverage.ex:83-85 `exit({:shutdown, 1})` confirmed verbatim; coverage_mix_test.exs:72-75 JSON key-set pin confirmed verbatim; coverage_mix_test.exs:260-262 confirmed as proof no exit-code test exists yet |
| HLTH-02 | `--all-schemas` schema-keyed report (table + JSON), mutually exclusive with `--schema=NAME` | CoverageSchemas.available/1 (coverage_schemas.ex:39-51) confirmed as the enumeration base (needs `pg_depend` extension-exclusion added — not present today); health.coverage.ex:50 confirmed as where the mutual-exclusion check must land before repo start |
| HLTH-03 | `:unresolved_legacy_keys` warning finding, per-table counts, link to upgrade guide, never fails `--strict` | TriggerCatalog.threadline_triggers/1 (trigger_catalog.ex:22-37) confirmed as the key-column source; guide SQL (upgrading-to-0.11.md:145-158) confirmed matching D-19's predicate; upgrade_backfill_test.exs fixture infra confirmed present and reusable |
| HLTH-04 | Docs state malformed `:trigger_capture` raises rather than producing a finding | health.coverage.ex:83-88 and verify_coverage.ex:92-97 confirmed as the existing `Mix.raise` wrapping; configuration-and-commands.md trigger_capture row confirmed at line 22, but column is "Default or absence behavior", not "Failure-mode" (correction noted above) |

</phase_requirements>

## Standard Stack

No new dependencies. D-01 explicitly rejects NimbleOptions ("it is not a direct dependency").
This phase is pure Elixir/Ecto + Mix + Postgrex against the existing `threadline` Hex package
dependency set — no `mix.exs` changes.

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ecto / ecto_sql | already a dependency (unchanged) | `Ecto.Query.limit/2`, catalog `SQL.query!/3` calls | Already used throughout `Threadline.Query` and `Threadline.Health` |
| jason | already a dependency (unchanged) | `--json` output, incl. `Jason.OrderedObject` for D-13's sorted-key schema envelope | Already the project's JSON library; `Jason.OrderedObject` is the documented fix for Elixir map hash-order ambiguity above 32 keys |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-written `validate_limit!/1` (mirroring Evidence) | NimbleOptions | Rejected by D-01 — not a direct dependency, and the mirrored-message precedent keeps the two validators textually consistent without adding a dependency for one option |

**Installation:** None — no new packages.

## Package Legitimacy Audit

Not applicable. This phase adds zero new runtime or dev dependencies; all work is internal Elixir
code (new functions/modules in the existing `threadline` package) plus guide prose. No `mix.exs`
changes.

## Architecture Patterns

### System Architecture Diagram

```
Adopter code                          CI pipeline
     |                                      |
     v                                      v
Threadline.history/3                mix threadline.health.coverage [--strict] [--json]
     |  (opts: limit, repo, scope)         |
     v                                      v
Threadline.Query.history_query/3     OptionParser.parse(strict: [...]) --unknown switches now raise (D-16)
     |  RowKey.match! -> where_row          |
     |  order_by(captured_at desc, id desc) v
     |  maybe_limit/2 (NEW, after order_by) resolve_repo! / validate_schema! / load_capture_config!
     v                                      |         (raises on malformed :trigger_capture, HLTH-04)
repo.all/2 -> [AuditChange]                 v
                                      Threadline.Health.trigger_findings/1
                                      Threadline.Health.legacy_key_findings/1  (NEW, concatenated here only)
                                             |
                                             v
                                      render_table / render_json (schema-keyed envelope if --all-schemas)
                                             |
                                             v
                                      strict gate: any :error finding in scope? -> exit({:shutdown, 1}) : :ok
                                      (stderr status line via Mix.shell().error/1)
```

### Recommended Project Structure

No new top-level directories. New files slot into the existing layout:

```
lib/
├── threadline/query.ex                       # add maybe_limit/2, validate_history_limit!/1 (private)
├── threadline/health.ex                      # add legacy_key_findings/1 (delegates to new module)
├── threadline/health/finding.ex               # extend code() union + Codes doc list
├── threadline/health/legacy_key_findings.ex   # NEW (planner's discretion on name/location, D-20/D-21/D-22/D-23)
├── threadline/health/coverage_schemas.ex       # extend available/1 (or add all_schemas/1) with pg_depend extension exclusion
├── mix/tasks/threadline.health.coverage.ex    # --strict, --all-schemas, unknown-switch raise, mutual exclusion
test/
├── threadline/query_test.exs                  # :limit test cases (D-04)
├── support/property_runs.ex                   # reused unchanged (PropertyRuns.db)
├── support/row_history_generators.ex           # reused unchanged (history_gen/0)
├── threadline/operator_surface/coverage_mix_test.exs          # --strict matrix (D-09), rename "exits 0" test
├── threadline/operator_surface/coverage_doc_contract_test.exs # update pinned OptionParser spec string
├── threadline/health_findings_doc_contract_test.exs            # extend to TriggerFindings.codes() ++ LegacyKeyFindings.codes()
├── threadline/upgrade_backfill_test.exs         # extend with legacy-key-finding assertions (D-26)
```

### Pattern 1: Validate-before-DB-access, mirror Evidence's message shape

**What:** A private `validate_limit!/1` in `Threadline.Query`, called inside `history/3` **before**
`RowKey.match!` runs (which hits the catalog/DB), raising the exact Evidence wording with `nil`
explicitly accepted (unlike Evidence).

**When to use:** Any new option validation on a query-layer public function, per this phase's D-01.

**Example (precedent, verbatim read from source):**
```elixir
# Source: lib/threadline/evidence.ex:313-317 (read this session)
defp validate_limit!(value) when is_integer(value) and value > 0, do: :ok

defp validate_limit!(value) do
  raise ArgumentError, ":limit must be a positive integer, got: #{inspect(value)}"
end
```
```elixir
# Source: lib/threadline/evidence.ex:345-346 (read this session)
defp maybe_limit(query, nil), do: query
defp maybe_limit(query, limit), do: limit(query, ^limit)
```

D-01 requires `history/3`'s version to diverge from this exactly one way: `limit: nil` must be
**accepted** (meaning unbounded), not rejected the way Evidence's `validate_limit!/1` rejects an
explicit `nil` elsewhere in that module (CONTEXT: "Unlike Evidence, which rejects an explicit nil,
this keeps `limit: opts[:limit]` pass-through working"). The planner should have the executor
write a new clause set, not reuse Evidence's function, because the `nil`-handling differs.

### Pattern 2: `exit({:shutdown, 1})` gate after full output, never mid-stream

**What:** Print the complete report (table or one JSON document to stdout) first, then decide the
exit code, then — if failing — write a **separate** status line to stderr via `Mix.shell().error/1`
so stdout under `--json` stays exactly one JSON document.

**Example (precedent, verbatim read from source):**
```elixir
# Source: lib/mix/tasks/threadline.verify_coverage.ex:80-85 (read this session)
print_report(expected, coverage, counts)
print_findings(partition)

if violations != [] or partition.gated != [] do
  exit({:shutdown, 1})
end
```

`health.coverage`'s `--strict` gate (D-06/D-07) follows the identical shape: render first
(unchanged JSON/table code paths), then a pure `in_scope_error_findings` check, then
`exit({:shutdown, 1})` with a `Mix.shell().error/1` line — never `System.halt`, never a second exit
code.

### Pattern 3: Capped, index-bound per-table probe instead of a global aggregate

**What:** D-19's probe runs per table (driven by `TriggerCatalog.threadline_triggers/1`'s rows
whose trigger records key args), using a `LIMIT 10001`-capped subquery, never a `GROUP BY` over
the whole `audit_changes` table.

**Example (existing precedent for the "N / N+" capped-count pattern):**
```elixir
# Source: lib/threadline/export.ex:218-224 (read this session)
count =
  if is_integer(cap) and cap > 0 do
    capped = base_query |> limit(^cap)

    from(sub in subquery(capped), select: count())
    |> repo.one(Query.storage_opts(filters, opts))
  else
    repo.aggregate(base_query, :count, :id, Query.storage_opts(filters, opts))
```
This is the Elixir-side analog of D-19's raw-SQL `LIMIT 10001` subquery — same cap-at-10000(+1)
convention, same reason (avoid `statement_timeout` on a multi-million-row scan), cited by CONTEXT
as "the `export.ex` 10,000+ convention."

### Anti-Patterns to Avoid

- **A global `GROUP BY table_schema, table_name` over `audit_changes` for `:unresolved_legacy_keys`:**
  explicitly rejected by D-19 — "never a global `GROUP BY`, which would mean a seq scan plus
  detoasting `data_after` on 100M rows." Drive probes per table from the trigger catalog instead.
- **Reusing `trigger_findings/1` to emit the new finding:** explicitly rejected by D-18 —
  `trigger_findings/1` is pinned as a zero-grant, catalog-only check
  (`pgbouncer_topology_test.exs:50-68`, read this session, confirms a role with no table grants
  gets identical findings to the owner — a data-scanning finding would break that invariant). Keep
  `legacy_key_findings/1` as a separate function, concatenated only inside the Mix task.
- **A per-schema loop for `--all-schemas`:** D-11 explicitly rejects this ("200 tenants would mean
  400 round trips with no consistent snapshot"); use one batched catalog query per concern (tables,
  triggers) across all schemas.
- **Filtering extension-member schemas via `pg_extension.extnamespace`:** D-12 explicitly rejects
  this — it "would drop `public`" (because `public` can itself be `extnamespace` for some
  extensions). Use `pg_depend` with `classid = 'pg_namespace'::regclass AND deptype = 'e'` instead.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-schema enumeration | A bespoke `SELECT nspname FROM pg_namespace WHERE ...` query | `CoverageSchemas.available/1` (coverage_schemas.ex:39-51), extended with the `pg_depend` exclusion | Already the single source of truth `--schema=NAME` validates against; reusing it keeps `--schema` and `--all-schemas` semantics identical by construction |
| Keyset paging for `history/3` | A second cursor system bolted onto `history/3` | `row_history_page/4` (query.ex:80-103), already shipped, same `timeline_order/1` tiebreak | FEATURES.md §B: Ecto/Ash both treat "cap" and "keyset-paginate" as different concerns; `history/3` stays the eager-bounded half, `row_history_page/4` stays the keyset half |
| Backfill automation | `mix threadline.gen.backfill` | The already-shipped, tested, marker-delimited guide SQL (`guides/upgrading-to-0.11.md:145-182`) | FEATURES.md §D: a durable anti-feature per Carbonite/PaperTrail/Logidze precedent; the new finding adds detectability, not automation |

**Key insight:** Nearly every "don't hand-roll" item in this phase is "don't hand-roll a thing
Threadline (or Ecto) already built" — `CoverageSchemas`, `row_history_page/4`, and the guide SQL
are all pre-existing, tested assets this phase extends or links to rather than duplicates.

## Common Pitfalls

### Pitfall 1: Validating `:limit` after the DB round-trip instead of before

**What goes wrong:** If `validate_history_limit!/1` is called after `RowKey.match!/3` (which hits
the DB to resolve the row key / catalog fallback), an invalid `:limit` wastes a round-trip and
produces a confusing error ordering (a DB-shaped error could fire first on an unrelated bad `id`).

**Why it happens:** `history/3`'s current body (query.ex:396-402) calls `history_query/3`
immediately, and `history_query/3` calls `RowKey.match!/3` as its first line (query.ex:408). It's
easy to add the new validation inside `history_query/3` after that call instead of before it.

**How to avoid:** D-01 is explicit: validate "before any DB access (before `RowKey.match!`)".
Put the check in `history/3` itself (or as the very first line of `history_query/3`, before
`RowKey.match!`), not after.

**Warning signs:** A test passing a garbage `id` *and* an invalid `:limit` together raises the
`RowKey.match!` error instead of the `:limit` error.

### Pitfall 2: Applying `:limit` before the scope predicate

**What goes wrong:** If `maybe_limit/2` runs before `maybe_apply_scope/2` in the pipeline, the cap
could count rows outside the caller's scope, then the scope filter removes some of them —
returning fewer than `n` rows even when `n` in-scope rows exist.

**Why it happens:** `history_query/3`'s current pipe order is
`where_row |> maybe_apply_scope |> order_by |> order_by` (query.ex:410-415). D-02 requires
`maybe_limit/2` to be placed **after both `order_by`s**, which is also after `maybe_apply_scope`
in the existing pipe — so the natural insertion point (end of pipe) is already correct, but it's
easy to misplace it earlier while refactoring.

**How to avoid:** Append `|> maybe_limit(limit)` as the last step, after both `order_by` calls.
Document (per D-02) that `scope_query_fn` must only add predicates — a limit it sets internally
would be silently overridden by this final `LIMIT`.

**Warning signs:** The "limit plus scope" test (reusing `query_test.exs:411`'s fixture per D-04)
returns fewer rows than expected when the limit is smaller than the in-scope row count.

### Pitfall 3: `--strict` failing on uncovered tables (scope creep into `verify_coverage`'s job)

**What goes wrong:** A developer instinct is to make `--strict` fail on `:uncovered` tables too
(since that reads as "this table has no capture"). D-05 explicitly reserves that behavior for
`mix threadline.verify_coverage`'s positive list.

**Why it happens:** `health.coverage`'s existing moduledoc already calls itself a scan of "every
table," which makes "uncovered = bad" feel like the natural strict condition.

**How to avoid:** `--strict` only inspects `trigger_findings/1` (now plus
`legacy_key_findings/1`) results for `severity: :error`, never the `trigger_coverage/1` tuples.
Point users at `verify_coverage` in both the moduledoc and the stderr status line (D-05, D-07).

**Warning signs:** The matrix test (D-09) would need a case proving `--strict` passes against a
schema with zero triggers (fully uncovered, zero findings) — if that case fails, coverage leaked
into the strict gate.

### Pitfall 4: `--json` output losing determinism above 32 keys

**What goes wrong:** D-13's `--all-schemas --json` envelope nests one object per schema under
`"schemas"`. A plain Elixir map with more than 32 keys does **not** preserve insertion order when
encoded by `Jason.encode!/1` (it falls back to the underlying hash-map iteration order), so two
runs over the same 40-schema database could emit different key orders.

**Why it happens:** Elixir/Erlang maps only guarantee insertion-order iteration below a small
internal size threshold (historically 32); above it, order is hash-determined.

**How to avoid:** D-13 mandates `Jason.OrderedObject` for the `schemas` key specifically. Confirm
`jason` (already a dependency) exposes `Jason.OrderedObject` in the vendored version before
relying on it — this is worth a quick `mix deps` version check at plan time, not assumed.

**Warning signs:** A golden-output test comparing two `--all-schemas --json` runs over an
identical fixture (>32 schemas) produces byte-different output.

### Pitfall 5: `OptionParser.parse/2`'s discarded third element hiding new typos too

**What goes wrong:** D-16 fixes the *existing* silent-typo bug, but if the new `--strict` /
`--all-schemas` switches are added to the `strict:` keyword list without also handling the
(currently discarded) third tuple element, the fix is incomplete — a new typo like `--strci`
would still pass silently.

**Why it happens:** `OptionParser.parse/2` returns `{parsed, remaining_args, invalid}` — today's
code destructures as `{opts, _, _}` (health.coverage.ex:50), discarding both the second element
(unexpected positional args) and the third (switches that don't match the `strict:` spec or have
the wrong type).

**How to avoid:** Destructure all three elements and `Mix.raise` on a non-empty `invalid` list
(and decide, per planner discretion informed by the moduledoc's existing usage grammar, whether
unexpected positional args should also raise).

**Warning signs:** A positive-control test for `--all-schemas` plus a negative-control test for
`--all-schema` (singular typo) — the latter must now raise instead of silently being ignored.

## Code Examples

### `maybe_limit/2` — the exact precedent to adapt

```elixir
# Source: lib/threadline/evidence.ex:345-346 (read this session)
defp maybe_limit(query, nil), do: query
defp maybe_limit(query, limit), do: limit(query, ^limit)
```

### `exit({:shutdown, 1})` gate — the exact precedent to adapt

```elixir
# Source: lib/mix/tasks/threadline.verify_coverage.ex:80-86 (read this session)
print_report(expected, coverage, counts)
print_findings(partition)

if violations != [] or partition.gated != [] do
  exit({:shutdown, 1})
end
```

### `TriggerFindings.codes/0` — the exact precedent `LegacyKeyFindings.codes/0` must match

```elixir
# Source: lib/threadline/health/trigger_findings.ex:8-17 (read this session)
@doc false
@spec codes() :: [Finding.code()]
def codes do
  [
    :legacy_trigger_no_pk_args,
    :pk_drift,
    :shared_capture_function,
    :duplicate_capture_trigger,
    :capture_trigger_disabled
  ]
end
```

### `CoverageSchemas.available/1` — today's enumeration, needs the `pg_depend` exclusion added

```elixir
# Source: lib/threadline/health/coverage_schemas.ex:39-51 (read this session)
@spec available(module()) :: [String.t()]
def available(repo) do
  sql = """
  SELECT DISTINCT schemaname
  FROM pg_tables
  WHERE schemaname <> 'information_schema'
    AND schemaname NOT LIKE 'pg\\_%' ESCAPE '\\'
  ORDER BY schemaname
  """

  %{rows: rows} = SQL.query!(repo, sql, [])
  List.flatten(rows)
end
```
Per D-12, the planner's `--all-schemas` enumeration needs this query extended with a `NOT EXISTS`
(or equivalent) against `pg_depend` filtered to `classid = 'pg_namespace'::regclass AND deptype =
'e'`, joined on the schema's `pg_namespace.oid` — **not** a filter on `pg_extension.extnamespace`
(which would incorrectly exclude `public` for extensions installed there).

### Backfill guide SQL — the exact predicate the new finding's probe must mirror

```sql
-- Source: guides/upgrading-to-0.11.md:145-158 (read this session)
UPDATE <storage_schema>.audit_changes
SET table_pk = jsonb_build_object('<key_col>', data_after ->> '<key_col>')
WHERE id IN (
  SELECT id
  FROM <storage_schema>.audit_changes
  WHERE table_schema = '<host_schema>'
    AND table_name = '<host_table>'
    AND op IN ('insert', 'update')
    AND (table_pk = '{"id": null}'::jsonb OR table_pk = '{}'::jsonb)
    AND data_after ? '<key_col>'
    AND data_after ->> '<key_col>' IS NOT NULL
  LIMIT <batch_size>
);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `health.coverage` is viewer-only (always exits 0) | `health.coverage --strict` adds an opt-in CI gate scoped to error findings anywhere, distinct from `verify_coverage`'s positive-list gate | This phase (0.12.0) | Adopters without an `expected_tables` allowlist get a "fail CI on any capture defect" option |
| `OptionParser.parse/2`'s third element silently discarded | Unknown/invalid switches now raise `Mix.raise` | This phase (0.12.0), listed under CHANGELOG Fixed | A typo'd flag (`--stict`) now fails loudly instead of silently no-opping |
| `history/3` always returns every row | `history/3` accepts `limit: n`, default unchanged (`nil`/unbounded) | This phase (0.12.0) | Adopters can cap `history/3` without switching to `row_history_page/4`'s keyset API |

**Deprecated/outdated:** None — this phase adds nothing that replaces or deprecates an existing
code path; every change is additive (D-27: "no Breaking entries" for the additions, though the
unknown-switch fix is listed under CHANGELOG Fixed, which is a behavior change in the strict
sense but not semver-breaking for any conforming caller).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Jason.OrderedObject` is available in the vendored `jason` version without a dependency bump | Pitfall 4 / Standard Stack | If unavailable, D-13's sorted-key JSON envelope needs a different encoding strategy (e.g. a custom `Jason.Encoder` impl or manual string-building) — the planner should confirm the vendored jason version supports it before committing to the approach |
| A2 | The extension-schema exclusion via `pg_depend` (D-12) behaves correctly against a real Timescale/PostGIS-style extension schema | Architecture Patterns / Anti-Patterns | CONTEXT itself already flags this as "unverified against real Timescale/PostGIS" and requires a fixture test — this research did not independently verify it either (no such extension is installed in this dev environment); the planner must keep D-12's required fixture test |

**If this table is empty:** N/A — two items above need confirmation during planning/execution,
both already flagged by CONTEXT itself; this research did not discover new unverified claims
beyond what CONTEXT already marked.

## Open Questions

1. **Where exactly should HLTH-04's sentence land, given the "Failure-mode cell" doesn't exist?**
   - What we know: `guides/configuration-and-commands.md`'s config table header is `Key | Purpose
     and accepted shape | Default or absence behavior | Primary owner` (line 17), and the
     `trigger_capture` row is at line 22 — matching CONTEXT's "~22" citation.
   - What's unclear: D-25 names a "Failure-mode cell" that doesn't exist as a column in this
     table today.
   - Recommendation: Put the sentence in the "Default or absence behavior" cell of the
     `trigger_capture` row — that cell already states failure behavior for the
     `verify_coverage` row ("...causes the verification task to raise instead of passing
     vacuously") at line 23, so there's a direct same-table precedent for failure-mode prose
     living in that column. Flag this correction explicitly in the plan so the executor doesn't
     search for a literal "Failure-mode" column.

## Environment Availability

Skipped — this phase has no new external tool/service dependencies. All required tooling
(Elixir/Mix, PostgreSQL via the existing test repo, Jason) is already a verified, exercised
project dependency with no version change.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in), StreamData for properties (already a dependency per phases 226-227) |
| Config file | `mix.exs` aliases (`verify.test`, `verify.test_partitioned`, `ci.all`); `test/test_helper.exs` |
| Quick run command | `mix test test/threadline/query_test.exs` / `mix test test/threadline/operator_surface/coverage_mix_test.exs` (single-file, per CONTRIBUTING convention — these are `async: false` DB tests, so keep scope narrow) |
| Full suite command | `mix verify.test` (unpartitioned local default) or `mix ci.all` (full gate incl. format/credo/dialyzer_slice/test) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|--------------------|--------------|
| QRY-01 | `limit: n` caps, validates, tiebreak order | unit + property | `mix test test/threadline/query_test.exs` | ✅ (extend existing file) |
| QRY-02 | No-`:limit` behavior unchanged | unit (regression) | `mix test test/threadline/query_test.exs` | ✅ (extend existing file) |
| HLTH-01 | `--strict` exit-code matrix | integration | `mix test test/threadline/operator_surface/coverage_mix_test.exs` | ✅ (extend existing file) |
| HLTH-02 | `--all-schemas` table/JSON, mutual exclusion | integration | `mix test test/threadline/operator_surface/coverage_mix_test.exs` | ✅ (extend existing file) |
| HLTH-03 | `:unresolved_legacy_keys` finding | integration (DB-backed, real pre-0.11 fixture) | `mix test test/threadline/upgrade_backfill_test.exs` | ✅ (extend existing file) |
| HLTH-04 | Doc states fail-fast behavior | doc contract | `mix test test/threadline/health_findings_doc_contract_test.exs` (or a new doc-contract assertion in `coverage_doc_contract_test.exs`) | ✅ (extend existing file) |

### Sampling Rate

- **Per task commit:** the single modified test file(s) (e.g. `mix test test/threadline/query_test.exs`)
- **Per wave merge:** `mix verify.test` (full local suite)
- **Phase gate:** `mix ci.all` green before `/gsd-verify-work`; VERIFICATION.md reports suite wall
  clock before/after per D-28 and SUITE-06's established format (see `228-VERIFICATION.md` SC5 row
  for the precedent: local median before/after + CI proxy-minute note)

### Wave 0 Gaps

None — every test file this phase touches already exists and is already registered in the
partitioned-CI weights/colocation mechanism (`test/partition_weights.txt`,
`test/partition_colocate.txt`, via `bin/ci-test-partitions`). New assertions added to existing
files do not require new colocation-group entries; only a brand-new test *file* would need one,
and CONTEXT's canonical-refs list names only existing files to extend (query_test.exs,
coverage_mix_test.exs, coverage_doc_contract_test.exs, verify_coverage_task_test.exs,
health_findings_doc_contract_test.exs, pgbouncer_topology_test.exs, upgrade_backfill_test.exs,
property_runs.ex). If the planner's module split (D-20 discretion) produces a genuinely new test
file, add one line to `test/partition_colocate.txt` grouping it with its nearest sibling (e.g.
group a new `legacy_key_findings_test.exs` with `upgrade_backfill_test.exs`) so weighted
assignment doesn't isolate a cold, unweighted file into its own partition.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | Mix tasks run with the operator's own DB credentials; no new auth surface |
| V3 Session Management | No | N/A |
| V4 Access Control | No | No new access-control surface; `legacy_key_findings/1` reads only `audit_changes`, already readable by the same role `trigger_findings/1` reads with (role-agnostic per `pgbouncer_topology_test.exs`) |
| V5 Input Validation | Yes | `:limit` validated as positive integer before use (mirrors `Threadline.Evidence`); `--schema=NAME` already validated via `CoverageSchemas.validate/2` regex + `pg_namespace` lookup (coverage_schemas.ex:14-34), reused unchanged for `--all-schemas`'s per-schema enumeration |
| V6 Cryptography | No | No cryptographic material involved |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| SQL injection via `--schema=NAME` | Tampering | Already mitigated by `CoverageSchemas.validate/2`'s conservative identifier regex (`~r/\A[a-z_][a-z0-9_]{0,62}\z/`, coverage_schemas.ex:6) plus a `pg_namespace` existence check — both reused unchanged by `--all-schemas`'s enumeration path, not reinvented |
| Unbounded/slow DB scan causing a CI job hang | Denial of Service (self-inflicted) | D-19/D-20: per-table `LIMIT 10001` cap plus `SET LOCAL statement_timeout` inside one transaction for the new legacy-key probe, mirroring `export.ex`'s existing 10,000+ convention |
| Information disclosure via `--json` findings | Information Disclosure | Findings already carry only schema/table/count metadata, never row values (per `Finding` struct's documented fields); the new `:unresolved_legacy_keys` finding's `details` (`unresolved_count`, `capped`, `key_columns`) follows the same shape — no `data_after` values are ever surfaced |

## Sources

### Primary (HIGH confidence — read directly this session)
- `lib/threadline/query.ex` (full file) — `history/3`, `history_query/3`, `row_history_page/4`, `timeline_order/1`
- `lib/threadline.ex:60-190` — public `history/3`/`row_history_page/4` docs
- `lib/threadline/evidence.ex:290-346` — `validate_limit!/1`, `maybe_limit/2` precedent
- `lib/threadline/query/cursors.ex:100-150` — `timeline_page_size!/1` (not generalized, per D-01)
- `lib/mix/tasks/threadline.health.coverage.ex` (full file)
- `lib/mix/tasks/threadline.verify_coverage.ex` (full file)
- `lib/threadline/health.ex` (full file)
- `lib/threadline/health/finding.ex` (full file)
- `lib/threadline/health/trigger_findings.ex:1-80` — `codes/0`, `run/1`
- `lib/threadline/health/trigger_catalog.ex:1-75` — `threadline_triggers/1`
- `lib/threadline/health/coverage_schemas.ex` (full file)
- `lib/threadline/storage_schema.ex:1-135` — `table/2`, `@threadline_tables`
- `lib/threadline/capture/primary_key_sql.ex:25-60,155-175` — key-resolution SQL
- `lib/threadline/export.ex:185-225` — `count_matching/2` capped-count precedent
- `test/threadline/operator_surface/coverage_mix_test.exs` (full file)
- `test/threadline/operator_surface/coverage_doc_contract_test.exs:1-260` — pinned OptionParser spec string, JSON key-set pin
- `test/threadline/pgbouncer_topology_test.exs:40-68` — zero-grant findings parity test
- `test/threadline/upgrade_backfill_test.exs:1-80` — pre-0.11 fixture setup
- `test/threadline/query_test.exs:199-230,411-430` — scope fixtures (`as_of/4`, `history/3` "applies support scope")
- `test/threadline/public_surface_contract_test.exs:1-60,660-680` — module-visibility contract (TriggerFindings/TriggerCatalog not tracked, confirming private-module precedent)
- `test/support/row_history_generators.ex:100-130` — `history_gen/0`
- `test/support/property_runs.ex:1-50` — `PropertyRuns.db/1`
- `guides/upgrading-to-0.11.md` (full file) — Step 4/6 anchors, backfill SQL, "What cannot be recovered"
- `guides/configuration-and-commands.md:17-30,96-115` — config table header/columns, commands table
- `guides/operator-surface.md:400-415` — Mix-task parity section
- `guides/domain-reference.md:260-272` — Finding codes table, `verify_coverage`/`health.coverage` prose
- `lib/threadline/telemetry.ex:20-22,150-230` — existing 14-event registry (unchanged this phase)
- `CHANGELOG.md:1-40` — Unreleased section structure
- `mix.exs:10-30,130-165` — `verify.*` alias definitions
- `bin/ci-test-partitions:20-100,350-375` — partition weights/colocation mechanism
- `.planning/phases/228-telemetry/228-VERIFICATION.md:127` — suite-wall-clock reporting precedent

### Secondary (MEDIUM confidence)
- `.planning/research/FEATURES.md` §B-D — prior-phase domain research, already roadmap-endorsed as sufficient (not independently re-verified beyond cross-checking its file:line citations against source, above)

### Tertiary (LOW confidence)
- None — this phase's scope was narrow enough that no WebSearch-only claims were needed; every
  factual claim above was verified by reading the cited file this session.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies, all precedent code read directly
- Architecture: HIGH — every cited pattern (`maybe_limit`, `exit({:shutdown, 1})`, `codes/0`,
  capped-count convention) verified verbatim against source this session
- Pitfalls: HIGH — each pitfall traced to a specific locked decision (D-01, D-02, D-05, D-13,
  D-16) with a corresponding source line confirming the current (pre-phase) behavior
- Open question (A1, A2): MEDIUM — flagged for planner confirmation during execution, not blocking

**Research date:** 2026-10-02
**Valid until:** Next phase touching the same files (likely v1.45's history/row_history
consolidation) — no external API drift risk since this is all internal code; estimate 90 days
given the project's own release cadence.
