# Stack Research: v1.44 Behavioral Depth — Property Testing

**Domain:** Property-based testing strategy for an Elixir/Ecto/PostgreSQL audit library (`threadline` 0.11.2)
**Researched:** 2026-09-30
**Confidence:** HIGH for the bench compile fix and the DB-sandbox strategy (both reproduced locally against this repo). MEDIUM for ecosystem precedent (web sources, not exhaustively cross-checked) and for exact `max_runs` numbers, which are a judgment call bounded by the existing two property files' precedent.

**Confidence labels:**
- **[VERIFIED]** — reproduced locally against this repo's code, or read directly from source.
- **[WEB]** — a web source, not independently cross-checked against a second source.
- **[INFERENCE]** — reasoning from the verified facts above it.

---

## 0. What already exists (read first)

- `{:stream_data, "~> 1.4", only: :test}` in `mix.exs:113-118`, pinned deliberately below the 1.15 Elixir floor. [VERIFIED]
- Two property files, both **pure** (no DB), both `async: true`, both pass `max_runs:` explicitly (300, not StreamData's default 100): `test/threadline/capture/naming_property_test.exs`, `test/threadline/mix/trigger_migration_property_test.exs`. [VERIFIED]
- `test/support/naming_generators.ex` is the one shared generator module (`use ExUnitProperties`, `pair_gen/0`, `ident/1`, `fixed_ident/1`, `pair_of_pairs_gen/0`), reused by both files via `import`. [VERIFIED]
- `Threadline.DataCase` (`test/support/data_case.ex`): **no Ecto SQL Sandbox** — triggers fire at the DB level, outside sandbox awareness — so every DB-touching test cleans audit tables in `setup` and defaults to **`async: false`** so tests in one module never race the same DB. This is the established, load-bearing pattern for any DB work in this suite. [VERIFIED]
- `Threadline.AsyncHelpers.assert_eventually/2` is the house pattern for polling instead of `Process.sleep`. [VERIFIED]
- The suite is ~91% serial (per PROJECT.md); adding slow, serial, DB-touching properties directly taxes the number the milestone wants to *improve*, not just hold steady.

---

## 1. Per-target verdicts

### 1. Cursor paging (`lib/threadline/query/cursors.ex`, `actor_history_page.ex`, `row_history_page`)

**Verdict: INCLUDE, as a pure property. No DB.**

`Cursors` is already a pure module over in-memory data: `actor_history_trim/3` (`cursors.ex:74-84`), `actor_history_cursor/2` (`:88-91`), `timeline_page_next_cursor/2` (`:157-162`), and the two validators. None of it queries the database — the DB only supplies the ordered list that these functions slice. That means the actual paging *invariant* (pages joined == full list, no dupes, no gaps, tie-heavy `captured_at`/`occurred_at` handled) can be tested by generating an already-sorted-by-tiebreak list of synthetic entries **in memory**, then driving `actor_history_trim/3` / `timeline_page_next_cursor/2` repeatedly with varying `limit`/`page_size`, exactly the way `row_history_page` (`lib/threadline/query.ex:81-101`) and `actor_history` (`query.ex:531-559`) drive them against real query results. This tests the real bug class (off-by-one at page boundaries, `has_more?`/`reverse?` interaction, `(occurred_at, id)` tuple-comparison ties) without touching PostgreSQL.

Invariants to assert:
- `Enum.concat(pages) == original_list` when paging forward to exhaustion (dedup by `id`, since tie-heavy timestamps make `Enum.uniq/1` misleading — the same `captured_at` can legitimately repeat for two rows, only `id` is unique).
- No `id` appears in two pages, and no `id` from `original_list` is missing from `Enum.concat(pages)`.
- The generator must be biased toward **duplicate `captured_at`/`occurred_at` values** (the tie-heavy case named in the milestone) — e.g. `StreamData.frequency` weighted so ~40% of generated entries share a timestamp with the previous one. A uniform-random-timestamp generator would almost never exercise the tuple tiebreak and the property would pass vacuously.
- `next_cursor`/`prev_cursor` correctness: paging with the returned cursor never re-yields an already-seen `id` and never skips the row immediately after/before the cursor.
- The reverse-page path (`before:` cursor, `actor_history_window/3` at `cursors.ex:66-70`) reconstructs the same forward-order page as walking without a cursor to that offset.

One property test per page kind (actor-history and row/timeline-history share `Cursors` code but have different struct wrappers) is enough; do not fan out per field.

### 2. `as_of` == replayed history (`lib/threadline/query.ex:467-508`)

**Verdict: INCLUDE, but DB-backed. This one cannot be pure.**

Unlike cursors, `as_of/4` is genuinely a query (`as_of_query/4`, `query.ex:484-495`): `WHERE captured_at <= timestamp ORDER BY captured_at DESC, id DESC LIMIT 1`, then a case split on `op`. The invariant — "the row `as_of(t)` returns equals the row you'd get by replaying `history(schema, id)` up to `t` in order" — is a statement about the query's *interaction with real ordering and real data*, not a pure function over a list you already control. Faking `history/3`'s ordering in memory to avoid the DB would just re-implement `as_of_query`'s own `ORDER BY`/`LIMIT` logic and test that copy against itself — a vacuous property.

Design: generate a **small** (5-20 entries) sequence of synthetic inserts/updates/deletes for one row with a `StreamData`-generated but monotonically-jittered `captured_at` (including some exact ties), insert them via `Threadline.Test.Repo` inside a `Threadline.DataCase` test (no sandbox, `async: false`, per §0), then for a StreamData-generated timestamp `t` drawn from the *same* range as the sequence (including exactly-on-a-boundary values), assert:
- `Threadline.as_of(schema, id, t, repo: Repo)` returns `{:error, :before_audit_horizon}` iff no entry has `captured_at <= t`.
- Otherwise it returns the `data_after` of `Enum.filter(history, & &1.captured_at <= t) |> Enum.max_by(&{&1.captured_at, &1.id})` computed from the very list you inserted (not re-derived some other way) — i.e. "replayed history" means "the last entry your test fixture inserted at or before `t`", which is a genuine independent check because it does not go through `as_of_query`'s SQL at all.
- The delete case (`{:error, :deleted_record}`) is covered by biasing the generator so the last inserted op before some cut points is a delete.

Because this needs DB writes, keep `max_runs` low (see §3) and build the whole sequence of rows **once per check iteration**, not row-by-row with intermediate assertions — see §2 DB strategy below.

### 3. ChangeDiff (`lib/threadline/change_diff.ex`)

**Verdict: INCLUDE, pure, highest-value target in this list.**

`Threadline.ChangeDiff.from_audit_change/2` is a pure projection over an `%AuditChange{}` struct (`change_diff.ex:85-91`) — no DB, no I/O, and it already has a precisely specified INSERT/UPDATE/DELETE × before_values matrix in its moduledoc (`:24-49`). This is exactly the profile the milestone guide asks for ("an invariant and a large input space meet"): a deterministic pure function, a rich combinatorial input space (op × changed_fields × changed_from presence/sparseness × key-type mismatches between atom/string), and existing prose invariants that are currently only asserted by hand-picked example tests.

Invariants to assert, generating `%AuditChange{}` fixtures (op, `data_after`, `changed_fields`, `changed_from`, JSON-safe scalar/nested values) with StreamData:
- `"field_changes"` is always sorted ascending by `"name"` (`update_field_changes/1` sorts at `change_diff.ex:173`, `insert_field_changes/2` at `:152` — both should be checked, not just one).
- UPDATE: every name in `field_changes` is present in `changed_fields`, and every name in `changed_fields` appears exactly once in `field_changes` (round-trip completeness — this is the "except_columns" invariant from the moduledoc, `:41-45`).
- `before_values_signal(nil) == "none"` implies no field entry ever has a `"before"` or `"prior_state"` key; `"sparse"` implies every field entry has exactly one of `"before"` xor `"prior_state" => "omitted"`, never both, never neither (`build_update_field/4`, `:179-198`).
- DELETE always yields `field_changes: []` and `data_after: nil` regardless of what `data_after`/`changed_fields` are set to in the fixture (proves the DELETE branch really ignores those fields rather than being coincidentally empty for the hand-picked test rows).
- Atom-keyed vs string-keyed `changed_from`/`data_after` maps produce identical output (`map_has_field?/2`, `map_get/2` accept both) — generate both key shapes and assert the outputs are `==`.
- `:export_compat` format (`export_compat_map/1`, `:93-106`) always has the same `data_after`/`changed_fields`/`changed_from` *values* as the primary format's top-level fields, for the same fixture — this is the moduledoc's cross-format authority claim (`:12-16`), currently undocumented as a test.

This needs no `Threadline.Test.Repo`, no `DataCase`, no `async: false` — plain `async: true` `ExUnitProperties`, same shape as `naming_property_test.exs`.

### 4. Redaction never leaks (`lib/threadline/capture/redaction_policy.ex`, `trigger_sql.ex`, `export.ex`)

**Verdict: RESHAPE. Split into a pure property (policy validation) and a bounded DB property (leak-proof at the SQL layer); do NOT attempt a pure property over generated SQL text.**

Two genuinely different mechanisms share the word "redaction" here, and they need different test strategies:

- **`Threadline.Capture.RedactionPolicy.validate!/1`** (`redaction_policy.ex`) is pure: it rejects `exclude`/`mask` column-name overlap and validates the placeholder (empty, >200 bytes, control characters). **INCLUDE as a pure property**: generate random column-name lists with a forced non-empty intersection and assert `validate!/1` always raises `ArgumentError` mentioning both "exclude" and "mask"; generate placeholders containing a random control byte (`0..31`) and assert always-raise; generate disjoint exclude/mask sets and valid placeholders and assert always `:ok`. This is cheap, fast, and matches `naming_property_test.exs`'s shape exactly.
- **The actual "never leaks" guarantee** is a property of the *generated trigger SQL executed against real PostgreSQL*: a masked/excluded column's raw value must never appear in `data_after` or `changed_from` for any row shape, any `changed_fields` combination, or any value (including values that happen to collide with the placeholder string, embedded NUL bytes rejected earlier by `validate_placeholder!/1`, or Unicode). This has to run against a live trigger-installed table, so it is DB-backed and expensive. **Do not generate SQL identifiers here** — that space is already exhaustively covered by `naming_property_test.exs`; this property's only job is *values*, not *names*. Bound the generator to a **fixed single test table** with a fixed 2–3 column shape (one masked, one excluded, one plain), and only vary the **inserted/updated values** (strings including near-placeholder collisions, NULLs, nested JSON, empty strings) across `check all` iterations. Reuse one migrated table across the whole property (`setup_all`, not `setup`), insert/update per iteration, then delete the rows the property itself created before the next iteration (or better: use unique PK values per iteration and read `WHERE table_pk = ...` to avoid any cross-iteration interference, which sidesteps needing a clean-slate truncate every run — see §2 strategy 3 below). Assert the masked column's raw value is byte-for-byte absent from `data_after`/`changed_from` JSON, and the excluded column is entirely absent as a key.

Keep `max_runs` small here (10-20, see §3) — this is the one property in the set that is both DB-backed and adversarial-security-relevant, so a handful of well-chosen adversarial values (via `StreamData.frequency` biasing toward edge cases: the exact placeholder string, an empty string, a string containing the placeholder as a substring, `nil`) buys more than raw iteration count.

### 5. Retention cutoff boundaries (`lib/threadline/retention.ex`)

**Verdict: RESHAPE into a narrow DB-backed boundary property; do not property-test the batching/looping machinery.**

`Threadline.Retention.purge/1` is mostly orchestration (batch loop, `RetentionRun` bookkeeping, dry-run counting) around one real invariant: rows are partitioned by `captured_at < cutoff` (`delete_change_batch/3`, `retention.ex:203-217`, and the dry-run count at `:136-142`) — a **strict** `<`, not `<=`. That strictness at the exact cutoff instant is the boundary bug class worth a property (off-by-one on `<` vs `<=`, and microsecond-precision `DateTime` comparison, since the policy cutoff is computed with `Policy.cutoff_utc_datetime_usec!/0`).

Property: generate a small set (5-15) of `AuditChange` rows with `captured_at` values clustered **tightly around** a chosen cutoff (some strictly before, some exactly equal to the microsecond, some strictly after — `StreamData.frequency` biased so ties at the cutoff are common, not rare), insert them, run `purge/1` with `dry_run: true` (no destructive writes needed to prove the boundary — `dry_run_result/4` at `:135-155` runs the identical `WHERE captured_at < cutoff` predicate), and assert `eligible_changes` count equals exactly the count of fixture rows with `captured_at < cutoff` (strict), with rows at exactly `cutoff` never counted. Also cover `resolve_cutoff/2`'s own invariant (`:118-126`): a caller-supplied `:cutoff` strictly after the policy cutoff always raises `ArgumentError`, at or before it always resolves to that value.

Do **not** property-test `purge_loop/7`'s batch/`max_batches`/orphan-draining control flow — that is deterministic looping logic better covered by the existing example-based tests (a handful of fixed-size fixtures at 1x, exactly-`batch_size`, and `batch_size + 1` rows already exercises every branch; a property adds iteration count, not new failure classes). This keeps the DB property small and fast: one boundary check per run, `dry_run: true` (no deletes to clean up), against a handful of rows.

### 6. Export round-trips (`lib/threadline/export.ex`)

**Verdict: INCLUDE, and it should be pure — do not run it against the DB.**

`csv_row/2` and `change_map/1` (`export.ex:387-451`) are plain functions over a **map**, not an `%AuditChange{}` struct or a live query result — the map shape returned by `export_changes_query/2`'s join (`row.id`, `row.table_pk`, `row.data_after`, `row.tx_occurred_at`, etc.). That means the round-trip property — "what export writes, export's own consumers can read back losslessly" — can be built entirely in memory: construct such row-maps with StreamData (JSON-safe `data_after`/`changed_from` values, `changed_fields` lists, `table_pk` maps, `DateTime`s, an `ActorRef` or `nil`), run them through `csv_row/2`, `dump_csv_to_iodata/1`/`NimbleCSV.RFC4180`, parse the CSV text back with `NimbleCSV.RFC4180.parse_string/1`, `Jason.decode!/1` each JSON-bearing column, and assert the decoded values equal the original fixture values (mod string-vs-atom key normalization, since JSON has no atoms). Do the same for `change_map/1` → `Jason.encode!/1` → `Jason.decode!/1`.

Invariants:
- CSV: `Jason.decode!(csv_field)` for `table_pk`/`data_after`/`changed_fields`/`changed_from`/`transaction_json` columns reconstructs the original map/list, for every generated value shape (nested maps, empty maps/lists, Unicode strings, large integers, floats, `nil`).
- CSV escaping never corrupts a value: values containing commas, quotes, newlines, and the placeholder string round-trip byte-for-byte through NimbleCSV.
- JSON (`:wrapped` and `:ndjson`): decoding reproduces the same `"id"`/`"transaction_id"` (string-coerced) and the same nested `"transaction"`/`"action"` shape as the input row-map, including the `aa_id`-present/absent branch (`:439-450`).
- `ChangeDiff`'s `:export_compat` format and `Export`'s own `change_map/1` genuinely agree on field-for-field values for the same underlying data (this cross-checks target 3's cross-format claim from the export side, catching drift between the two modules if one changes without the other).

No `Threadline.Test.Repo`, no `DataCase` — this is the second cheapest property in the set after ChangeDiff.

**Net:** of the 6 named targets, **4 are pure** (cursors, ChangeDiff, redaction-policy-validation, export round-trip) and **3 touch the DB** (as_of, redaction-leak-at-the-SQL-layer, retention boundary — one of the 4 "pure" ones, redaction, splits into one pure + one DB-backed test). Lead with the pure ones; they are strictly cheaper and just as likely to catch the bug classes the milestone names.

---

## 2. DB strategy without a SQL Sandbox

`Threadline.DataCase` already answers "how do DB tests work here" for the whole suite (no sandbox, `async: false`, clean-in-`setup`, per §0) [VERIFIED]. Property tests that touch the DB should be a **thin extension of that pattern**, not a parallel mechanism:

1. **Reuse `Threadline.DataCase`, do not invent a second harness.** `use Threadline.DataCase` (default `async: false`) inside the property test module, `use ExUnitProperties` alongside it — this is exactly how `naming_property_test.exs` layers `use ExUnit.Case, async: true` with `use ExUnitProperties`; the DB properties just swap in `Threadline.DataCase` and drop `async: true`.
2. **Generate the whole fixture in memory first, then do one bounded batch of inserts per `check all` iteration** — never insert row-by-row with an assertion in between. `Repo.insert_all/3` (or a small `Enum.each(&Repo.insert!/1)` for ≤15 rows) once per iteration keeps each iteration to a handful of round trips instead of one per generated value.
3. **Uniquify by generated PK/id per iteration instead of truncating between iterations.** `DataCase`'s `setup` already truncates once per *test* (`clean_storage_schemas!/0`), but a property's `check all` runs the body many times inside **one** test. Re-truncating audit tables every iteration (a full `TRUNCATE`/`DELETE` round trip) is the single biggest cost driver for a DB property and is unnecessary if each iteration's fixture rows carry a fresh, StreamData-generated UUID/table_pk — then every assertion filters `WHERE table_pk = <this iteration's key>` (exactly how `as_of`/`history` already scope by `table_pk`, `query.ex:423-428`), so iterations never see each other's rows and cleanup can happen once, in the test's own `on_exit`, not per iteration. This is strictly cheaper than a per-property schema/table and does not require touching migrations or `Ecto.Adapters.SQL.Sandbox` (which triggers cannot see anyway, per `DataCase`'s own moduledoc).
4. **Do not stand up a dedicated schema or table per property.** A separate schema per property (rejected): needs its own migration/trigger install per test run, multiplies DDL cost, and this repo's per-table capture-function model (v1.42) makes "spin up throwaway tables" a nontrivial fixed cost per property, not a cheap knob. Unique-PK-per-iteration against the **existing** `Threadline.Test.Repo` fixture tables (the ones `test/support` already migrates for other DB tests) gets the same isolation for near-zero marginal cost.
5. **`sleep_ms`/`Process.sleep` has no place inside a property iteration.** If a DB-backed property ever needs to wait on something async (it shouldn't for these 3 targets — retention/as_of/redaction are all synchronous `Repo` calls), use `Threadline.AsyncHelpers.assert_eventually/2`, never a raw sleep, matching house convention.

This gets all three DB-backed targets to "one test module, `Threadline.DataCase`, unique keys per iteration, no schema-per-property, no sandbox illusion" — consistent with how the rest of the suite already runs against a real, unsandboxed database.

---

## 3. Bounded runtime in CI

The two existing property files already establish the pattern to extend, not replace: **explicit `max_runs:`, not StreamData's default of 100** [VERIFIED, both files pass `max_runs: 300`]. Recommendation, tiered by cost:

| Target | Kind | Default `max_runs` (`mix test`) | Weekly/nightly scale-up |
|---|---|---|---|
| Cursors | pure | 200 | ×5 (1000) |
| ChangeDiff | pure | 200 | ×5 |
| Redaction policy validation | pure | 200 | ×5 |
| Export round-trip | pure | 150 (larger generated maps) | ×5 |
| `as_of` == replayed history | DB | **20** | ×3 (60) |
| Redaction never leaks (SQL) | DB | **15** | ×3 |
| Retention cutoff boundary | DB | **20** | ×3 |

Rationale for the pure/DB split: pure properties are µs-scale per iteration, so 200 runs costs nothing measurable; DB properties are ms-to-tens-of-ms per iteration (one or a few round trips), so 15-20 runs already buys meaningfully more coverage than the current zero, without materially growing the "91% serial, ~191s of 209s" number the milestone is trying to *shrink*. A DB property at `max_runs: 200` would be the single most expensive thing in the suite for no proportionate return — adversarial value generation (biased `frequency`, not uniform-random) buys more per run than raw run count for these targets, per Hypothesis's own "shrink/report, don't just brute-force" lesson [WEB].

**Mechanism for the scale-up lane**, adapting Hypothesis's CI-profile idea [WEB] to this repo's existing `@tag`/exclude convention (`test/test_helper.exs:5-16` already excludes `pgbouncer_topology`/`live_dialyzer` by default and the weekly Flake Detection lane un-excludes them):
- Read `max_runs` from an env var with a small default, e.g. `@property_scale (System.get_env("THREADLINE_PROPERTY_SCALE") |> then(&(&1 && String.to_integer(&1))) || 1)`, defined once in a shared test-support helper (not per-file), and write `max_runs: 200 * @property_scale` (pure) / `max_runs: 20 * @property_scale` (DB) at each `check all`. Default `mix test` runs at scale 1 (the table above); the weekly Flake Detection workflow sets `THREADLINE_PROPERTY_SCALE=5` (or 3 for the DB-backed ones — two env vars, or one var and two multiplier constants, whichever reads more plainly) before invoking `mix test`.
- **Seeds for reproducibility:** ExUnit's own `--seed` already flows into StreamData (StreamData seeds itself from `:rand` state, which ExUnit seeds per test) — a failing property already prints a seed and reproduction instructions on failure [WEB, stream_data's own `ExUnitProperties` docs describe this]. No extra plumbing is needed here; the ask in the milestone ("seeds for reproducibility") is met by *not* suppressing StreamData's default failure output and by keeping `mix test --seed <N>` in the contributor-facing failure message CONTRIBUTING.md already uses for flaky-test triage. Do not attempt to hand-roll a Hypothesis-style persistent example database — that is real added infrastructure for a benefit StreamData's built-in seed replay already covers at this scale.
- **Promote real counterexamples to fixed tests**, per the Hypothesis/QuickCheck lesson of "a discovered failure becomes a permanent regression test" [WEB]: when a property finds a genuine bug, add the minimal failing input as a new `test` (not just leave it to the property to keep re-finding it), the same way a fixed `describe "boundary"` example-based test already exists alongside StreamData properties in well-run Elixir/Erlang suites [WEB].

---

## 4. The bench compile failure — root cause and fix

**Root cause [VERIFIED, reproduced]:** `bench/mix.exs:22` declares `{:threadline, path: "..", env: :test}`. The `env: :test` option forces **only the `threadline` dependency** to compile in `:test` Mix env, which flips on `elixirc_paths(:test) == ["lib", "test/support"]` (root `mix.exs:83`) — pulling in `test/support/naming_generators.ex`, which does `use ExUnitProperties` (`naming_generators.ex:8`). But `env: :test` does **not** change **bench's own** Mix env. Plain `mix compile` (or `cd bench && mix compile --warnings-as-errors`, exactly the command the deferred-item note used) runs bench itself in the default `:dev` env. Whether an `only: :test` dependency (here, `stream_data`, declared `only: :test` in the *root* `mix.exs`) is pulled into the resolved dependency tree at all is decided by the **top-level project's** Mix env, not by a nested path-dependency's forced `env:` override. So under bare `mix compile`: bench resolves its dep tree for `:dev`, `stream_data` is excluded from that tree, but `threadline` is still compiled with `test/support` on its path (because of its own `env: :test` override) — and that file needs a module (`ExUnitProperties`) that was never fetched/compiled for this env. Confirmed by reproducing exactly this failure (`module ExUnitProperties is not loaded and could not be found` at `naming_generators.ex:8`) and by confirming `MIX_ENV=test mix compile` (forcing bench's own env to `:test` too) compiles cleanly with the identical, unmodified `bench/mix.lock`.

This is not a version, lock, or missing-dependency problem — `bench/mix.lock` already resolves and fetches `stream_data 1.4.0` correctly once bench's own env is `:test`; deferred-item 215's note that it "reproduces identically before and after the 215-01 bench dependency bump" is consistent with this: the bump never touched the actual cause.

**Fix [VERIFIED, tested locally then reverted — this research is read-only for code]:** add a `def cli/0` to `bench/mix.exs` that defaults `compile` (and `run`, since bench scripts execute via `mix run`) to the `:test` env, mirroring the pattern the **root** `mix.exs` already uses for its own env-sensitive tasks (`def cli do [preferred_envs: [...]] end`, root `mix.exs:8-27`):

```elixir
def cli do
  [preferred_envs: [compile: :test, run: :test]]
end
```

With this added, `cd bench && mix compile --warnings-as-errors` (no `MIX_ENV` prefix needed) compiles cleanly against the existing, unmodified `bench/mix.lock` — verified by a full `rm -rf deps _build && mix deps.get && mix compile --warnings-as-errors` cycle. This also matches `bench/bench_helper.exs`'s own existing assumption (`unless Mix.env() == :test do ... System.halt(1) end`, `bench_helper.exs:5-8`) — bench has always required `:test` env to actually *run*; this fix just makes that requirement hold for `compile` too, so a bare `mix compile` (what CI's `verify-deps-audit`/contributors are most likely to type) stops failing. **Do not** instead remove `env: :test` from the threadline path dependency — that would break `Threadline.Test.Repo` and other `test/support` fixtures bench genuinely needs at runtime (`bench_helper.exs` calls into `Threadline.Test.Repo`, `custom_priv_repo.ex`, etc.), so the dependency's own forced `:test` env is correct and load-bearing; the bug is only that bench's *own* env wasn't following it.

---

## 5. Ecosystem precedent

**StreamData vs PropCheck [WEB]:** StreamData is Elixir-native (Elixir-lang.org-published), generator-first (generators double as plain Elixir streams usable outside property tests), and is what Ecto's own ecosystem and this repo already standardize on. PropCheck wraps Erlang's PropEr and adds **stateful/model-based testing** and persistent counterexample storage that StreamData lacks. **Recommendation: stay on StreamData for all 6 targets in this milestone** — none of them need PropEr's `statem` state-machine modeling; they are pre/postcondition-style invariants over generated inputs (cursors, diffs, redaction, retention, export), which is squarely StreamData's sweet spot and avoids adding a second property library (and PropEr as a transitive Erlang dependency) for a capability this milestone doesn't need.

**Should the capture → history pipeline get stateful/model-based testing (PropEr `statem`)?** [INFERENCE from the code + MILESTONE-GUIDE §8's "deliberate, bounded" instruction] **DEFER, explicitly, not silently.** A `statem` model of "insert/update/delete a row, then assert `history`/`as_of`/`row_history_page` agree with a pure in-memory model of the same sequence" is a real, high-value idea — it is structurally the generalization of target #2 (`as_of` == replayed history) to arbitrary sequences and arbitrary read APIs at once. But it is a materially bigger investment: a new dependency (`propcheck`, pulling in PropEr), a command/postcondition model to write and maintain, and — per this repo's no-sandbox DB constraint — a *sequence* of real DB writes per generated command list, which multiplies the DB-cost concern in §3 by whatever sequence length the model generates. Landing target #2 first (a bounded, non-stateful version of exactly this idea) is the right-sized step for this milestone; revisit `statem` only if #2 surfaces sequencing bugs that a single-snapshot `as_of` check cannot express (e.g. bugs specific to *interleavings* of writes across concurrent transactions, which single-writer sequential properties cannot reach anyway).

**How Ecto/Postgrex/Oban/Phoenix/Plug/Jason use properties [WEB, general community pattern, not each library's own CI verified line-by-line]:** the common thread across the ecosystem is that DB-touching Ecto/Ecto-adjacent properties consistently pair StreamData with `Ecto.Adapters.SQL.Sandbox` in `async: true` mode to keep property iterations cheap and parallel-safe — which is exactly the affordance this repo's trigger-based capture layer cannot use (`DataCase`'s own moduledoc is explicit that triggers are invisible to the sandbox). This is the single biggest way threadline's property strategy must diverge from generic Ecto-app precedent: where a typical Ecto app leans on the sandbox to make DB properties cheap and parallel, this repo has to lean on unique-key-per-iteration + `async: false` instead (§2). Community guidance on Ecto+StreamData also converges on "generate the changeset/struct in memory, keep DB round trips to the minimum the property actually needs to prove," which is the same principle behind keeping targets #3 and #6 (ChangeDiff, export round-trip) pure rather than DB-backed even though their inputs originate from DB rows in production.

**Hypothesis (Python) lessons applied here [WEB]:** (1) CI profiles that trade iteration count by lane (§3's `THREADLINE_PROPERTY_SCALE`); (2) shrinking to a minimal failing example is the debuggability payoff, not just "more inputs" — StreamData ships this natively, same as Hypothesis; (3) promote discovered counterexamples to permanent regression tests rather than relying on the property to keep re-finding them (§3). **QuickCheck/proptest** reinforce the same "generators are the real design work, not the property assertion" lesson — most of the effort in this milestone should go into writing generators biased toward the adversarial cases named in the milestone text itself (tie-heavy timestamps, near-placeholder-collision redaction values, exact-cutoff boundary times), not into maximizing `max_runs`.

**Audit-library precedent (PaperTrail, Logidze, Carbonite, django-simple-history) [WEB, general survey, not each repo's test suite individually audited]:** these libraries' test suites are predominantly example-based, not property-based — property testing is not yet a common pattern in the audit-trail-library space specifically. That is *not* a reason to skip it here; it means threadline has no direct precedent to borrow test *shapes* from in this niche, only the general Ecto/StreamData guidance above. It does reinforce MILESTONE-GUIDE §8's instruction to keep property tests deliberate and scoped to genuine invariant/large-input-space intersections (the 6 named targets) rather than trying to property-test the whole capture pipeline just because the library category is "audit."

---

## 6. DX: generator reuse, shrinking readability, failure messages

- **Extend `test/support/naming_generators.ex`'s pattern, do not fragment it.** Add new generator modules under `test/support/` per domain (`Threadline.Test.ChangeDiffGenerators`, `Threadline.Test.CursorGenerators`, etc.) rather than inlining `gen all` blocks inside each property test — this is the existing convention (`naming_generators.ex` is `import`ed by two separate test files today) and keeps a generator's adversarial bias (e.g. tie-heavy timestamps) documented and reused instead of redefined per file.
- **Name generators for the bias they encode, not just the type.** `naming_generators.ex`'s own moduledoc already models this well ("StreamData generators for host table pairs, biased toward the pairs that break naive naming") — new generators should say what failure class they are biased toward in a `@moduledoc`, e.g. a `tie_heavy_timestamps/1` generator's doc should say *why* it clusters values instead of just "generates timestamps."
- **Shrinking readability:** StreamData's default shrinker on structured generators (maps/lists via `gen all`) already produces reasonably minimal counterexamples; the main DX risk is if a generator wraps its output in an opaque struct before returning it (harder to read a shrunk `%AuditChange{}` than a shrunk plain map). Prefer generating **plain maps** and only building the target struct (`%AuditChange{}`, a row-map for `csv_row/2`) as the last step inside the property body, so a shrink failure prints the plain generated map, not a struct with `__struct__`/`__meta__` noise.
- **Failure messages a contributor understands:** every `assert`/`refute` inside a property body should carry its own message when the default ExUnit diff would be uninformative (e.g. asserting a `MapSet` equality on `Enum.concat(pages)` vs `original_list` — a bare `assert` there produces a large, hard-to-read set diff; assert on `Enum.sort(ids_a) == Enum.sort(ids_b)` with a message naming which invariant failed, e.g. `"page union lost or duplicated ids"`). This matches `naming_property_test.exs`'s own restraint — it names *why* an assertion holds in a comment right above it, not just what it checks (e.g. the "no trigger-name injectivity" comment at the top of that file). Carry that same commenting discipline into the new files: state the invariant in English before the `check all`, the way `retention.ex`'s own moduledoc already states its cutoff semantics before the code.

---

## 7. What NOT to do

- Do not add `propcheck`/PropEr this milestone (§5) — no target here needs stateful modeling; it is a real dependency-and-maintenance cost for a capability this milestone's 6 targets don't require.
- Do not property-test SQL identifier generation again for the redaction-leak target — that space is `naming_property_test.exs`'s job; redaction's DB-backed property should vary **values**, not **names** (§1.4).
- Do not stand up a dedicated schema, table, or `Ecto.Adapters.SQL.Sandbox` usage for DB-backed properties (§2) — both diverge from this repo's established no-sandbox `DataCase` convention for no measurable benefit here.
- Do not run any DB-backed property at StreamData's default `max_runs: 100` in the default `mix test` lane (§3) — that materially grows the serial-suite-time number this milestone is separately trying to shrink.
- Do not remove `env: :test` from `bench/mix.exs`'s `threadline` path dependency to "fix" the compile error (§4) — that breaks bench's genuine runtime need for `Threadline.Test.Repo` and other `test/support` fixtures; fix bench's own env instead.
- Do not property-test `Retention.purge/1`'s batch-loop/orphan-draining control flow (§1.5) — that is deterministic branching better and more cheaply covered by a few fixed-size example tests; a property there adds run count, not new coverage.
- Do not hand-roll a persistent counterexample database (à la Hypothesis's example DB) — StreamData's seed-based reproduction plus "promote a found bug to a fixed test" (§3) covers the same need at this project's scale without new infrastructure.

---

## Sources

- [stream_data (whatyouhide/stream_data) — GitHub](https://github.com/whatyouhide/stream_data)
- [PropCheck — Property based testing for Elixir (HexDocs)](https://hexdocs.pm/propcheck/readme.html)
- [Elixir Community Tools: StreamData — Erlang Solutions](https://www.erlang-solutions.com/blog/elixir-community-tools-streamdata/)
- [Property-based testing in Elixir using PropEr](https://jeffkreeftmeijer.com/mix-proper/)
- [StreamData: Property-based testing and data generation — elixir-lang.org blog](https://elixir-lang.org/blog/2017/10/31/stream-data-property-based-testing-and-data-generation-for-elixir/)
- [Property-Based Testing with StreamData — Allan MacGregor](https://allanmacgregor.com/posts/property-based-testing-with-streamdata)
- [EctoStreamFactory — GitHub](https://github.com/ibarchenkov/ecto_stream_factory)
- [Hypothesis: Property-Based Testing for Python — Hacker News discussion](https://news.ycombinator.com/item?id=45818562)
- [In praise of property-based testing — Increment](https://increment.com/testing/in-praise-of-property-based-testing/)
- Local, repo-internal: `mix.exs`, `bench/mix.exs`, `bench/bench_helper.exs`, `test/test_helper.exs`, `test/support/data_case.ex`, `test/support/async_helpers.ex`, `test/support/naming_generators.ex`, `test/threadline/capture/naming_property_test.exs`, `test/threadline/mix/trigger_migration_property_test.exs`, `lib/threadline/query/cursors.ex`, `lib/threadline/query.ex`, `lib/threadline/change_diff.ex`, `lib/threadline/capture/redaction_policy.ex`, `lib/threadline/capture/trigger_sql.ex`, `lib/threadline/retention.ex`, `lib/threadline/export.ex`.
