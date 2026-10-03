# Phase 227: DB-Backed Property Tests - Context

**Gathered:** 2026-10-01
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers three DB-backed StreamData properties. Each runs with `Threadline.DataCase` (`async: false`, no SQL Sandbox) and `max_runs ≤ 20`.

- **PROP-04:** a redacted column's plaintext never reaches the stored audit change, its ChangeDiff output, or its CSV/JSON export.
- **PROP-06:** `as_of` at every point in a row's history equals an independent, in-order replay of the mutations that produced that history.
- **PROP-07:** `Retention.purge` selects exactly the rows strictly older than the cutoff. `dry_run: true` and the real purge agree. Every row at or after the cutoff survives byte-for-byte.

VERIFICATION.md records:
- a mutation control and failing seed for each property;
- the suite wall clock before and after, against SUITE-01 and the phase-225 partitioned figure.

The research probes found one real defect in scope (D-20, the dry-run transaction count) and several out of scope (Deferred). A defect a property exposes is handled by the D-25 rule.

No new public API, no capture-schema change, and no trigger-SQL change ship in this phase.

</domain>

<decisions>
## Implementation Decisions

### Shared harness: a thin addition to DataCase, isolated per iteration
- **D-01:** **Key created inside the property body, cleaned up in `after` on every iteration.**
  - Each `check all` body runs inside `with_iteration(fn n -> ... end)`. Here `n = System.unique_integer([:positive, :monotonic])` is created **in the body**, never generated, so every shrink rerun gets fresh rows and the key never appears in a counterexample.
  - `after` deletes this iteration's rows: the host row, `audit_changes`, then the now-empty `audit_transactions`, in FK order.
  - Cleanup rescues and `IO.warn`s and never raises, so a cleanup error can't hide the real assertion failure.
  - Why per-iteration and not once in `on_exit` (as STACK §2.3 suggested):
    - retention's dry-run count and its delete both act on the **whole table**;
    - export has **no row-key filter** (only `table/actor_ref/from/to/correlation_id`).

    Rows left over from an earlier iteration would make both oracles wrong.
  - Transaction-plus-rollback per iteration is rejected. It hides capture (Pitfall 1), and other connections can't see the rows.
  - Assertion messages never include the iteration key, or seed replay would compare different text.
- **D-02:** **`Threadline.Test.DbProperty`** in `test/support/db_property.ex`.
  - It holds plain functions only. Its moduledoc forbids `__using__` and `setup`, so it can't grow into a second harness next to DataCase (STACK §2.1).
  - Functions:
    - `iteration_key/0`
    - `with_iteration/1`
    - `delete_iteration!/…`
    - `assert_audit_tables_empty!/0` (the PROP-07 precondition)
    - `ordered_id(rank, n)` = `Ecto.UUID.load!(<<rank::32, n::96>>)`. Only the D-17 tie example test uses it: Postgres compares uuids byte by byte, so the tie winner comes from generated data and replays the same every time.
  - Each test file does `use Threadline.DataCase` + `use ExUnitProperties` + `import Threadline.Test.DbProperty`.
  - Every raw read uses the storage-qualified table name (`StorageSchema.table/2`). Unqualified reads have caused CI-only failures before.
- **D-03:** **File layout, one file per layer:**
  - `test/threadline/capture/redaction_leak_property_test.exs`
  - `test/threadline/query/as_of_property_test.exs`, next to `cursors_property_test.exs`
  - `test/threadline/retention/cutoff_property_test.exs`

  Generators live in `test/support/` and are named by domain, each moduledoc stating its bias (226 convention): `RedactionLeakGenerators`, `RowHistoryGenerators`, `RetentionCutoffGenerators`.
- **D-04:** **DB generators must not depend on size.** Use `member_of`, `frequency`, `integer(a..b)` and bounded `list_of(..., max_length:)`. Fixtures stay at 5-15 rows or steps.
  - Why: StreamData raises the generation size every run. At scale ×3 a size-dependent DB generator grows its row count along with the run count. 226 measured that effect at 1.6 s unscaled vs 96.6 s scaled.
- **D-05:** **Run budget.**
  - Every DB property uses `max_runs: PropertyRuns.db(20)`.
  - Measure first. Lower only the redaction property (`db(15)`, then `db(10)`), and only if it costs more than 2 s unscaled or more than ~9 s at `THREADLINE_PROPERTY_SCALE=5`.
  - Keep StreamData's default `max_shrinking_steps` (226 D-09). Each moduledoc records the worst case (~100 × iteration ms). Cap at 50 only if a measured iteration exceeds 100 ms.
  - No `max_run_time`.
- **D-06:** **Extend the scale contract** in `property_scale_contract_test.exs`: a `*_property_test.exs` that uses `Threadline.DataCase` must resolve to `PropertyRuns.db(`.
  - Today a DataCase property written as `pure(150)` passes, which breaks SC4's "≤ 20".
  - Add a mutation control: a DataCase fixture source using `pure(150)` must be flagged, asserting the mutated input differs from the original.

### PROP-04: redaction never leaks, checked with canaries, structural rules and positive controls
- **D-07:** **A dedicated fixed table, `prop_redaction_leak`**, created in `setup_all`.
  - Columns:
    - `id uuid PK`, supplied explicitly per iteration;
    - `secret_excluded text NULL`;
    - `secret_masked text NULL`;
    - `profile_masked jsonb NULL`, with the canary nested as `{"k": c, "l": [c]}`;
    - `bio text NULL`, the plain column.
  - Trigger:
    - `TriggerSQL.install_function_for_table(@t, store_changed_from: true, exclude: ["secret_excluded"], mask: ["secret_masked", "profile_masked"])`;
    - `create_trigger(@t, :per_table, redacted_columns: [...])`, passing `redacted_columns:` the way `gen.triggers` does.
  - `on_exit` drops the trigger, the function and the table.
  - Do not reuse `test_redaction_users`. `trigger_redaction_test.exs` drops its triggers in `setup`, and `config/test.exs` `:trigger_capture` points at it.
- **D-08:** **Plaintext generation: escape-proof canaries wrapped in hostile shapes.**
  - **Canary:** `"ZQXSECRET_<slot>_s<step>_ZQX"`.
    - It uses only `[A-Z0-9_]`, so its bytes are identical in Jason output, CSV quoting and jsonb text.
    - Its uppercase non-hex letters can't match a uuid, a timestamp, a table name or the placeholder.
    - It is deterministic per slot and step, so seed replay holds and shrinking can't reduce it to something that collides.
    - The step index makes consecutive values differ, so every "touch" step really puts the column in `changed_fields`. That is what reaches the `changed_from` path.
  - **Value for a redacted slot**, by `frequency`:
    - about 70%: `prefix <> canary <> suffix`, with prefix and suffix drawn from `["", "[REDACTED]", ",", "\"", "\r\n", "😀", "é", "\\", "{\"a\":1}"]`, plus an occasional 1-4 KB padding;
    - about 10% each: `nil`, `""` and exactly `"[REDACTED]"`. These get **structural checks only**, because no substring search can be meaningful for them.
  - **Plain column:** carries a positive-control marker `"ZQXVISIBLE_plain_s<step>_ZQX"`, wrapped in the same hostile shapes.
- **D-09:** **Operation plan per iteration:** an INSERT, then 1-4 steps, and about a third of plans end in DELETE.
  - Step mix:
    - `{5, touch_redacted}`, a non-empty subset that always includes a redacted column;
    - `{2, touch_plain_only}`;
    - `{1, noop_update}`.
  - Some plans run two steps in one DB transaction, to exercise the same-txid upsert.
- **D-10:** **Detection, three layers in one pass. Shared module `Threadline.Test.LeakOracle`** in `test/support/leak_oracle.ex`.
  1. **Surfaces** are a list of `{name, bytes}` built by the body:
     - stored rows read raw with `SELECT row_to_json(c)::text FROM <qualified audit_changes> c WHERE c.table_name = $1 AND c.table_pk->>'id' = $2`. This bypasses the Ecto schema, so a column added later is covered automatically;
     - the iteration's `audit_transactions` rows, read the same way;
     - ChangeDiff for every change in three variants (default, `expand_insert_fields: true`, `format: :export_compat`), each through `Jason.encode!`;
     - real DB exports `to_csv_iodata/2` (with `include_action_metadata` generated) and `to_json_document/2` (`:wrapped`, `:ndjson`);
     - `stream_export_rows/2` piped into `format_changes_iodata/3` for `:csv`, `:json_wrapped` and `:ndjson`.

     `format_changes_iodata/3` over `%AuditChange{}` read back is not viable, because it needs the join's `tx_*` fields.
  2. **`refute_canaries!(surfaces, canaries)`** searches for every step's canaries. It fails with the surface name, the canary (which identifies slot and step), the op plan and an 80-byte window around the match.
  3. **Structural rules:**
     - the excluded key is absent from `data_after`, `changed_from` **and** `changed_fields`;
     - masked keys equal the placeholder exactly, including when the plaintext was NULL or `""` (a mask hides NULL-ness);
     - `table_pk == %{"id" => id}`.
  4. **Positive controls:**
     - the captured change count equals the planned op count (no trigger means zero rows, which would pass vacuously);
     - export `returned_count` equals the same number;
     - the plain marker appears in `data_after` of every INSERT and UPDATE and on every export surface (`assert_markers!`).
  - **Accepted, not a leak:** the masked column's *name* in `changed_fields`. Change detection compares raw values (`trigger_sql.ex` ~L597), so `changed_fields` shows *that* a masked value changed. The moduledoc records this as an intended equality side channel.
  - **Out of scope, named in the moduledoc:** the global redacted function (`install_function(exclude:/mask:)`, ~L478-534). `gen.triggers` never emits it.
- **D-11 (228 hook):** Phase 228 adds a `:telemetry` handler that forwards events to the test pid.
  - Each event is serialized with `inspect(term, limit: :infinity, printable_limit: :infinity)`. The default limits truncate output and would hide a leak.
  - Each event is appended as a `"telemetry:<event>"` surface, with its own at-least-one-event positive control.
  - 227 builds the surfaces list so that this is purely additive. 227 does not attach any handler.
- **D-12:** **Three mutation controls** (line numbers as of 78721f84; the planner re-confirms them):
  1. `redaction_changed_from_mask.patch`: `trigger_sql.ex` ~L588. Replace the mask CASE with `to_jsonb(OLD) -> u.k`.
  2. `redaction_exclude_change_detect.patch`: ~L401, `changed_fields_except_array_sql(except_columns, [])`. The excluded column's old value then leaks into `changed_from`, and its name into `changed_fields`. **The current suite misses this mutant**, which is evidence that the property adds coverage.
  3. `redaction_update_path.patch`: remove the `redact_after_new` splice at ~L455, so redaction runs on INSERT only.

  `setup_all` reinstalls the function from `lib/`, so a mutant takes effect.
- **D-13:** **Close the existing example gap.** `trigger_redaction_test.exs`'s UPDATE example (~L71-94) gains:
  - `refute "password" in change.changed_fields`;
  - no `"password"` key in `changed_from`.

  After this change, mutant 2 also has a fast deterministic example that kills it.

### PROP-06: `as_of` checked against a model built from real mutations
- **D-14:** **The fixture is real mutations on a trigger-captured table. The oracle is the test's own model of the row.**
  - **Table** (DDL in `setup_all`): `asof_prop_rows (id bigint PRIMARY KEY, name text NOT NULL, note text NULL, n bigint, flag boolean, doc jsonb)`, with `TriggerSQL.install_function([])` + `create_trigger`.
  - **Schema module:** `AsOfPropRow`, with `@primary_key {:id, :id, autogenerate: false}`.
  - **Body:** fold over the generated steps. Apply each step as parameterised SQL and keep a string-keyed model of the live row. The expected value at step i is `{:ok, Map.put(model, "id", pk)}` or `{:error, :deleted_record}`.
  - This is the "hand-written in-order replay" of SC2. The expected values never come from `data_after` or from any ORDER BY.
  - **Rejected:** synthetic `AuditChange` rows with a `max_by({captured_at, id})` oracle (STACK §2 L50, and the harness probe's suggestion). That restates `as_of_query` L490-494 in Elixir: it is the Pitfall 3 tautology, and flipping the SQL would flip the oracle too.
  - **Column choice:**
    - Values are exact with no normaliser: bigint above 2^53, unicode and quote text, NULL, nested jsonb of strings/ints/bools/nil, partial and no-op UPDATEs.
    - `numeric` and `timestamptz` are excluded. numeric is lossy through Jason (`1.10`→`1.1`), and timestamptz text depends on the session timezone. That would make the property fail on capture fidelity rather than as_of (see Deferred).
- **D-15:** **Generator, readback and probes.**
  - **Steps:** `batches <- list_of(list_of(step, 1..3), 1..4)`, capped at 8 steps, always preceded by a full INSERT.
    - `step = frequency([{3, {:write, field_subset}}, {1, :delete}])`, applied totally:
      - write when the row is absent = INSERT a full fresh row;
      - write when it is present = partial UPDATE, including NULLs and no-ops;
      - delete when absent = drop the step.
    - Re-inserting the same PK after a delete therefore happens naturally.
    - Each batch runs in one `Repo.transaction`.
    - `pk = iteration_key()`.
  - **Readback:** after each statement, inside the same transaction, raw SQL reads the new `audit_changes` rows for this table and PK, excluding ids already seen. Assert **exactly one** new row whose `op` matches the step, and record its `captured_at`.
    - This links each timestamp to its step by observation, never through `history_query`/`as_of_query`.
    - As a side check, the readback `data_after` must equal the model, so a red points at capture rather than at as_of.
  - **Assert strictly increasing `captured_at`**, with a message naming the tie / clock-step risk (D-17).
  - **Probes**, all deterministic:
    - for every step i: `as_of(ts_i) == expected_i` and `as_of(ts_i − 1µs) == expected_{i−1}`, where i = 1 gives `{:error, :before_audit_horizon}`;
    - `as_of(ts_last + 1h) == expected_last`.

    Random time sampling is not used: it almost never lands on the inclusive bound.
  - **`cast: true`:** at every `{:ok, _}` probe, also call with `cast: true` and assert `Map.take(struct, fields)` equals the atomized model.
- **D-16 (PROP-06 mutation controls):** Patches:
  1. `as_of_le.patch`: `query.ex` ~L490 `<=` → `<`. The exact-`ts_1` probe kills it on every iteration.
  2. `as_of_order.patch`: ~L492 `desc: captured_at` → `asc`.
  3. `as_of_delete.patch`: drop the `op: "delete"` arm at ~L476.
  4. `capture_clock.patch`: `trigger_sql.ex` ~L566 `clock_timestamp()` → `now()`. Every step in a batch then shares one timestamp, and the strict-increase assertion fails. Only a real-mutation fixture can catch this capture-layer mutant.

  The ~L493 `desc: ac.id` tiebreak is **expected to survive** the property, because real capture never ties (D-17). EVIDENCE.md records it honestly as "unreachable by design". Its control is the D-17 example test.
- **D-17:** **Timestamp ties: deterministic but not causal. Pin the behaviour; don't fix it in 227.**
  - **Probe evidence** (local PG 14, Apple Silicon): over 9,001 real same-row captures in tight single-transaction loops there were **0 duplicate `captured_at`**, a 38-46 µs minimum gap and 0 order inversions.
  - The uuid-v4 tiebreak picks the higher random id on a tie. That is deterministic, but it has nothing to do with mutation order. It is latent, not live.
  - The real remaining risk is the system clock stepping **backwards**, which causes inversions. No property can fix that; only a monotonic sequence column can.
  - Add **one example test** in `query_test.exs` `describe "as_of/4"`, named for pinning the "deterministic, not causal" tie behaviour. It uses two synthetic changes with the same `captured_at` and ids from `ordered_id/2`, and asserts that repeated calls agree and the higher id wins. Its control is ~L493 `desc`→`asc`.
  - The causal fix (a `seq` column, or uuidv7, which needs PG18+) changes the capture schema and the cursor `(captured_at, id)` contract. It is deferred to v1.45.
  - **Reversibility:** reversible. Pinning adds only a test.

### PROP-07: retention, checked with an oracle outside lib/, a real purge, byte-identical survivors and dry/real agreement
- **D-18:** **Oracle shape (A): dry run, then a real purge of the same fixture.**
  - **Expected sets** come from generated facts (`DateTime.compare(ts, cutoff) == :lt`), never from lib code.
  - **Per iteration:**
    1. `assert_audit_tables_empty!()`, with the message "foreign rows present; global purge oracle unsound".
    2. `Application.put_env(:threadline, :retention, enabled: true, keep_days: 1, delete_empty_transactions: <generated>)`. A setup/`on_exit` pair saves and restores the original value, using `delete_env` when it was unset (the `retention_test.exs` L46-55 pattern; Pitfall 14 is safe because the module is `async: false`).
    3. `insert_all` the transactions, then the changes, with explicit ids, txids and **precision-6** `captured_at`. `insert_all` rejects precision-0 values.
    4. **Snapshot** `SELECT id::text, t::text FROM <qualified table> t` for both tables. Casting the whole row to text covers every column, including future ones.
    5. **Dry run:** `deleted_changes == |expected_purged|` and `deleted_transactions == |expected_orphaned|`, or 0 when the flag is false.
    6. **Real purge** `purge(cutoff:, batch_size:, sleep_ms: 0)`. `sleep_ms` defaults to 50 from opts and ignores `config/test.exs`. Then assert:
       - remaining change ids == expected survivors;
       - every surviving change **and** every surviving transaction is byte-identical to its snapshot;
       - the real return counts equal the dry-run counts;
       - exactly one completed `RetentionRun` exists, with `deleted_count == deleted_changes + deleted_transactions`.
    7. `after` deletes the iteration's transactions (the `ON DELETE CASCADE` removes their changes) and `RetentionRun` rows.
  - Don't assert `batches_run` beyond `>= 1` when something was deleted. 228 may change how batches are reported.
  - **Rejected:**
    - (B) extracting one shared eligible-changes query. That is the 226 D-01 trap: the `<`→`<=` control would flip both sides and could never go red. It is also lib churn right before 228 instruments purge.
    - (C) a dry-run count only. The survivor check would be vacuous, and it would miss the cascade and the D-19 defect.
  - **228 compatibility:** the property uses only `purge/1` and its return map. 228 can attach handlers to this same fixture.
- **D-19:** **Generator: rows clustered on the cutoff microsecond, plus transactions with mixed survivors.**
  - **Cutoff:** `~U[2001-01-01 00:00:00.000000Z]` plus `frequency` over a `.000000` part, a `.999999` part, and a random µs offset up to ~10^12 µs. Always precision 6.
    - The year-2001 window is always older than the policy cutoff (`keep_days: 1`), so an explicit `cutoff:` never trips `resolve_cutoff`.
  - **Transactions:** `list_of(list_of(offset_us, max_length: 5), min_length: 1, max_length: 4)`. An empty transaction (a pre-existing orphan) appears ~10% of the time.
    - `offset_us = frequency([{4, constant(0)}, {3, member_of([-1, 1])}, {2, member_of([±999_999, ±1_000_000, ±1_000])}, {1, integer(-10^11..10^11)}])`.
    - With ~6 rows, an iteration lacks an exact-cutoff tie only ~5% of the time.
  - **`delete_empty?`:** `frequency([{3, true}, {1, false}])`.
  - **`batch_size`:** `member_of([1, 2, 3, 500])`. Small batches exercise the orphan drain between batches at no extra run cost. The property asserts the **end state**, not loop branches, which stays consistent with STACK §1.5.
  - Rows carry distinct `op` and `data_after`/`changed_from` jsonb values, so a content change is visible.
  - **Failure messages:** a per-row table of offset µs, ISO `captured_at`, expected `keep`/`purge`, and actual, naming the rule. For example: "row at cutoff+0µs was deleted, but captured_at == cutoff must survive (strict <)", or "transaction <id> deleted while it still had a surviving change (cascade would destroy survivors)".
- **D-20:** **Fix the dry-run transaction under-count (`fix:` commit, CHANGELOG note).**
  - **Defect:** `dry_run_result` (`retention.ex` ~L138-153) counts only transactions that are *already* orphaned. The real purge also drains the transactions it orphans itself. Probe: dry `{changes: 2, txns: 0}` vs real `{changes: 2, txns: 1}`.
  - **Who it affects:** an operator previewing a purge sees a smaller blast radius than they get.
  - **Fix:** add `and c.captured_at >= ^cutoff` inside the `not exists` subquery. The predicate then becomes "no change survives the cutoff", which is exactly the orphan set after a completed purge.
  - **Docs:** the `:dry_run` doc says the preview assumes the run completes. A run cut short by `max_batches` deletes fewer.
  - **Tests:** pin the probe fixture as a fixed regression example test in `retention_test.exs`.
  - **Why it qualifies under D-25:**
    - it breaks documented behaviour ("counts of rows that would match");
    - the return shape is unchanged;
    - it touches one module;
    - it needs no trigger SQL or migration;
    - it only makes a reported number accurate.
  - **Reversibility:** reversible. The maintainer can veto at plan review; in that case the property pins the current behaviour with a named assertion and VERIFICATION.md records the gap.
- **D-21 (PROP-07 mutation controls):** Five separate patches. Each wrong only where the generator is biased:
  1. `retention_dry_run_lte.patch`: ~L134 `<` → `<=` (dry run only).
  2. `retention_delete_lte.patch`: ~L208 `<` → `<=` (delete only). With M1, this shows that patching one site alone is caught by the dry/real agreement assertion.
  3. `retention_orphan_guard.patch`: drop the `not exists` guard in `drain_orphans` (~L229-241). The cascade then deletes survivors.
  4. `retention_survivor_update.patch`: an `update_all` that rewrites the `captured_at` of survivors after the batch delete (the Pitfall 16 tamper case).
  5. `retention_dry_run_txn.patch`: revert the D-20 fix.
- **D-22:** **Example tests in `retention_test.exs`** (not properties):
  - `cutoff: utc_now + 1 day` raises `ArgumentError` matching "retention". No existing test covers this.
  - A precision-0 cutoff gives the same result as the µs cutoff.
  - The D-20 regression fixture.

  The exact `resolve_cutoff` boundary (== policy, +1 µs) is **not** property-tested. The policy cutoff moves with `utc_now`, so the test would be flaky unless lib gained clock injection.

### Mutation evidence, defect policy and budget
- **D-23:** **Reuse and harden 226's runner where it is.**
  - `.planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh` gets one fix: `extract_counterexample` must compare the **whole** generated-values block (every clause) and stop before the assertion message.
    - Use `[[:space:]]`, not `\s`. GNU awk stops right after the header today, so replay currently compares only "after N successful runs". The replay check is the main determinism proof for DB properties.
  - Re-run one 226 patch afterwards to confirm the change is backwards compatible.
  - **Patches** go in `.planning/phases/227-db-backed-property-tests/tools/mutations/`, with K=5.
  - **EVIDENCE.md**, cited from VERIFICATION.md, uses 226's shape. For each control it records:
    - the invariant in English;
    - the diff;
    - the red excerpt with seed and shrunk value;
    - the K/K kill rate;
    - the green line after restore;
    - the command.

    It also records the D-16 expected survivor. Scrub absolute paths and the username before committing (repo-hygiene guard).
- **D-24:** **Executor halt clause** (226 D-21, carried verbatim):
  - Executors never commit a mutated `lib/`.
  - During a control, they edit nothing but the patch target.
  - They never bypass hooks or move protected files.
  - If a precondition blocks them, they stop and report.
- **D-25:** **Defect policy for anything else the properties expose.**
  - **Fix in scope** with a `fix:` commit, a CHANGELOG entry and the minimal counterexample as a fixed example test, only when **all** of these hold:
    - the counterexample breaks documented or obviously intended behaviour;
    - the fix is reversible;
    - it changes no public return shape, export format, trigger SQL or migration;
    - it fits in about one lib module.
  - **Otherwise:**
    - pin the current behaviour in an example test named as a known defect;
    - record a seed or deferred item;
    - hand the maintainer **one scope question with a recommendation**.
  - If a pin needs a generator exclusion, the exclusion is a named, commented filter that cites the seed. Never narrow a generator quietly.
  - **Any redaction leak** is reported to the maintainer the same day and flagged as security.
- **D-26:** **Generator coverage floors** in `property_generator_coverage_test.exs`. Sample the new generators with a **1..20 size ramp** to match `max_runs`. Floors:
  - an exact-cutoff row in ≥ 25% of retention fixtures;
  - a mixed-survivor transaction in ≥ 20%, an empty transaction ≥ 1, each `batch_size` ≥ 1;
  - a delete in ≥ 20% of row histories, and a re-insert after delete ≥ 1;
  - a redaction plan with a `touch_redacted` step that changes both the masked and excluded columns in ≥ 40%;
  - for redacted values, at least one each of `nil`, `""`, the exact placeholder, the placeholder as a substring, multibyte, and a value over 1 KB.

  Each floor names the bias it protects.
- **D-27:** **CI, flake and wall clock (SC4/SC5)**, following the 225/226 rules unchanged.
  - **Local acceptance:**
    - `mix test --repeat-until-failure 20 <3 files>` (Pitfall 1);
    - one pass at `THREADLINE_PROPERTY_SCALE=5`;
    - one full `mix test` to check suite-order effects.
  - **Partition weights:** append a measured line only for a new file costing more than 2 s solo (226 D-24).
  - **Flake Detection:** about 29 s of room per suite run at 8 repeats. Dispatch with the scale already wired and cite the run id. Re-derive the Test 6 ceilings and the workflow budget comment from that run (225 D-11 / 226 D-12).
    - If the three properties exceed the room, drop to 7 repeats.
    - Never raise the 55-minute budget.
    - The dispatch needs a maintainer grant that names it.
  - **SC5:** the files' own cost (median of 5 at scale 1 and at scale 5); local whole suite (labelled noisy, ±50 s floor); and `ci-job-timing.py --compare` per lane against SUITE-01 and the 225 partitioned figure.
    - With no push grant, record that step as pending, with the exact commands.
    - The doc must pass `check-citations.py`.

### Claude's Discretion
- Exact helper function names and arity in `DbProperty` and `LeakOracle`, as long as D-01/D-02/D-10 hold.
- `describe` layout inside each property file. Mirror `cursors_property_test.exs`.
- Plan and wave split. The harness (D-01/D-02/D-06/D-23) comes first. After it, the three properties are independent. D-20 lands before PROP-07's dry/real agreement assertion is turned on.
- Whether PROP-04 also runs some plans in multi-statement transactions (D-09), if it costs little.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md`, Phase 227 (SC1-SC5) and Phase 228 (it consumes D-11)
- `.planning/REQUIREMENTS.md`: PROP-04, PROP-06, PROP-07, PROP-08 (run-budget rules), TELE-03 (redaction-property handler)
- `.planning/MILESTONE-GUIDE.txt`: quality bar (no tautological tests)

### Research
- `.planning/research/STACK.md` §1.2, §1.4, §1.5, §2, §3. **Superseded in parts by this CONTEXT:**
  - the §2 L50 `max_by` oracle is rejected (D-14);
  - the §2.3 clean-once-in-on_exit rule is replaced by per-iteration cleanup (D-01);
  - the §1.5 dry-run-only design is replaced by D-18.
- `.planning/research/PITFALLS.md` Pitfalls 1, 3, 4, 5, 14, 16

### Prior-phase decisions this phase builds on
- `.planning/phases/226-pure-property-tests-and-run-budget/226-CONTEXT.md`: D-07 (PropertyRuns), D-09 (no max_run_time), D-12 (Flake re-derivation), D-20 (mutation runner), D-21 (halt clause), D-22 (coverage floors), D-23 (wall clock), D-24 (weights)
- `.planning/phases/226-pure-property-tests-and-run-budget/226-EVIDENCE.md`: the evidence shape, and the scaled-cost figure (L320-321)
- `.planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh`: reused and hardened (D-23)
- `.planning/phases/225-suite-baseline-and-partitioned-ci/225-CONTEXT.md` D-03a, D-08, D-11; `tools/ci-job-timing.py`, `tools/check-citations.py`

### Code under test
- `lib/threadline/capture/trigger_sql.ex`: redaction ~L401, L447, L455, L583-626; global function L255 and L566 (`clock_timestamp()`)
- `lib/threadline/query.ex`: `as_of` ~L467-508, `as_of_query` L484-495
- `lib/threadline/retention.ex`: `purge/1`, `dry_run_result` ~L128-155, `delete_change_batch` ~L203, `drain_orphans` ~L228-250
- `lib/threadline/capture/migration.ex` ~L43: the `ON DELETE CASCADE` on `audit_changes.transaction_id`
- `lib/threadline/export.ex`: `to_csv_iodata/2`, `to_json_document/2`, `stream_export_rows/2`, `format_changes_iodata/3`
- `lib/threadline/change_diff.ex`

### Test infrastructure
- `test/support/data_case.ex`, `storage_schema_case.ex`, `property_runs.ex`
- `test/threadline/capture/trigger_redaction_test.exs` (the D-13 gap), `trigger_rerun_property_test.exs` (an existing DB property)
- `test/threadline/query_test.exs` (as_of fixtures ~L72-171), `retention_test.exs` (put_env restore ~L46-55)
- `test/threadline/property_scale_contract_test.exs` (~L296-330, D-06), `property_generator_coverage_test.exs`, `flake_classifier_contract_test.exs` Test 6 (~L749-848)
- `config/test.exs` (per-partition DB name L10, Logger level L90, `:trigger_capture`)

### Project quality bar
- `prompts/threadline-elixir-oss-dna.md`, `CLAUDE.md`, `.planning/PROJECT.md` Constraints (zero human verification by default)

### External
- John Hughes, "How to Specify It!": model-based oracles (D-14)
- Debezium `column.mask.*` docs: the length/hash mask footgun (why the mask must be exactly the placeholder); paper_trail `:ignore` vs `:skip` (a value leaking through a different door)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Test.PropertyRuns.db/1`: the DB run tier (×min(scale, 3)).
- `trigger_redaction_test.exs` `setup_all`: the fixture-table + per-table trigger pattern to copy for `prop_redaction_leak`.
- `query_test.exs` `as_of_row_fixture`: synthetic `AuditTransaction`/`AuditChange` inserts, used for the D-17 tie example only.
- `StorageSchemaCase.clean_storage_schemas!/0`: per-test cleanup, including `RetentionRun`.
- 226 generator modules: naming, moduledoc bias, `use ExUnitProperties`.

### Established Patterns
- No SQL Sandbox. DB tests are `async: false` with unique keys, never rollback.
- Contract tests carry mutation controls that assert the mutated input differs from the original.
- Raw SQL against audit tables must use storage-qualified names.
- ExUnit never runs an `async: false` module at the same time as others. CI partitions use separate databases (`threadline_test#{MIX_TEST_PARTITION}`), so a global oracle is sound once the precondition holds.

### Integration Points
- `.github/workflows/flake-detection.yml` `repeat` step + Test 6 ceilings (D-27)
- `test/partition_weights.txt` (only if a file costs more than 2 s)
- `CHANGELOG.md` (the D-20 fix note)

</code_context>

<specifics>
## Specific Ideas

- Verified probe facts (2026-10-01, local PG 14.17):
  - zero `captured_at` ties in 9,001 same-row captures, with a 38 µs floor;
  - dry/real transaction mismatch reproduced with C = 2001-06-01: t1 at C−1µs, t2 at C, t3 at C−1s and C+1s;
  - Ecto's `cast(:utc_datetime_usec)` normalises precision-0 and non-UTC values at query time, but `insert_all` rejects precision-0;
  - `numeric 1.10` → Jason float `1.1`;
  - server TimeZone in the test DB is not UTC.
- The property must be able to go red on a one-site patch. That is why there are two retention `<` controls, and why no shared predicate is extracted.
- When a property finds a real bug, the minimal input becomes a fixed example test. Don't rely on the property to re-find it.

</specifics>

<deferred>
## Deferred Ideas

- **v1.45 API contract:** a causal ordering for `audit_changes`, either a monotonic `seq bigint GENERATED ALWAYS AS IDENTITY` or uuidv7 (PG18+). Ordering would become `(captured_at, seq)` or `seq`. This also hardens against the wall clock stepping backwards. It changes the capture schema, the cursor contract and the adopter migration (D-17).
- **Security, backlog / v1.45 (raise with the maintainer):** redaction **fails open on misnamed columns**.
  - Nothing checks that `exclude:`/`mask:` names exist on the table. A typo or case mismatch turns `v - 'col'` into a no-op and stores plaintext.
  - The mask path also adds a phantom `"col": "[REDACTED]"` key, so the output looks redacted.
  - Candidate fix: a migrate-time column-existence check like `PrimaryKeySQL.redaction_check_sql`.
- **Capture fidelity:** `numeric` values lose precision through Jason when decoded from `data_after` (`1.10`→`1.1`, large values become floats). timestamptz renders in the session timezone. Candidate: decode with `floats: :decimals` or similar, under its own requirement.
- **Direct-API guard gap:** `TriggerSQL.create_trigger/3` without `:redacted_columns` skips the redacted-PK refusal. Only `gen.triggers` passes it.
- **Untested path:** the global redacted capture function (`install_function(exclude:/mask:)`). `gen.triggers` never emits it. Decide whether to remove or test it.
- Carried from 226: export nil → `{}` defaults (D-19), CSV formula injection, an optional muex sweep, and the full `partition_weights.txt` refresh in phase 230.

</deferred>

---

*Phase: 227-db-backed-property-tests*
*Context gathered: 2026-10-01*
