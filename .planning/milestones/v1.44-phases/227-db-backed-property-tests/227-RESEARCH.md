# Phase 227: DB-Backed Property Tests - Research

**Researched:** 2026-10-01
**Domain:** Property-based testing against a live (non-Sandbox) PostgreSQL database for an Elixir/Ecto audit library
**Confidence:** HIGH — every file/function/line CONTEXT.md names was opened this session; no new library research was needed (this phase adds no new dependency).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

See `.planning/phases/227-db-backed-property-tests/227-CONTEXT.md` `<decisions>` for the full D-01 through D-27 set — copied here only as a summary index since the full text is 27 detailed decisions (~250 lines); the planner MUST read 227-CONTEXT.md directly rather than rely on this index:

- **Shared harness (D-01 to D-06):** per-iteration isolation via `with_iteration/1` in a new `Threadline.Test.DbProperty` support module; no `on_exit`-once cleanup; `PropertyRuns.db(20)` run budget; extend `property_scale_contract_test.exs` to require `db(...)` (not `pure(...)`) for any `*_property_test.exs` using `Threadline.DataCase`.
- **PROP-04 (D-07 to D-13):** dedicated `prop_redaction_leak` fixture table; escape-proof canary strings in hostile wrapper shapes; three-layer detection (`Threadline.Test.LeakOracle`: canary search, structural rules, positive controls); three named mutation controls; closes an existing example-test gap in `trigger_redaction_test.exs`.
- **PROP-06 (D-14 to D-17):** oracle is a hand-written in-order replay model built by the test itself (not a synthetic `AuditChange`/`max_by` tautology); fixed table `asof_prop_rows`; generator produces write/delete batches; readback links each timestamp to its step by direct observation; one pinning example test for the deterministic-but-not-causal uuid tiebreak; four named mutation controls.
- **PROP-07 (D-18 to D-22):** oracle shape (A) — dry run + real purge of the same fixture, survivors snapshotted and compared byte-identical; generator clusters rows on the cutoff microsecond; D-20 fixes a real dry-run transaction-count defect (reversible, maintainer may veto at plan review); five named mutation controls; three new example tests.
- **Mutation evidence / defect policy (D-23 to D-27):** reuse and harden 226's `tools/mutation-control.sh` (fix the `extract_counterexample` awk pattern); K=5 per control; D-25's defect policy (fix-in-scope vs. pin-and-report) governs anything else a property exposes; generator coverage floors in `property_generator_coverage_test.exs`; CI/flake/wall-clock rules follow 225/226 unchanged.

### Claude's Discretion

- Exact helper function names and arity in `DbProperty` and `LeakOracle`, as long as D-01/D-02/D-10 hold.
- `describe` layout inside each property file. Mirror `cursors_property_test.exs`.
- Plan and wave split. The harness (D-01/D-02/D-06/D-23) comes first. After it, the three properties are independent. D-20 lands before PROP-07's dry/real agreement assertion is turned on.
- Whether PROP-04 also runs some plans in multi-statement transactions (D-09), if it costs little.

### Deferred Ideas (OUT OF SCOPE)

- **v1.45 API contract:** a causal ordering for `audit_changes` (monotonic `seq` column or uuidv7) — changes the capture schema, the cursor contract and the adopter migration.
- **Security, backlog / v1.45:** redaction fails open on misnamed `exclude:`/`mask:` columns — no existence check today; candidate fix is a migrate-time column-existence check.
- **Capture fidelity:** `numeric` precision loss through Jason (`1.10`→`1.1`); `timestamptz` renders in session timezone. Candidate: decode with `floats: :decimals` or similar, under its own requirement.
- **Direct-API guard gap:** `TriggerSQL.create_trigger/3` without `:redacted_columns` skips the redacted-PK refusal. Only `gen.triggers` passes it.
- **Untested path:** the global redacted capture function (`install_function(exclude:/mask:)`). `gen.triggers` never emits it.
- Carried from 226: export nil → `{}` defaults, CSV formula injection, an optional muex sweep, full `partition_weights.txt` refresh in phase 230.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROP-04 | A DB-backed property varies captured values on a fixed table shape and proves that a redacted column's plaintext never appears in the stored audit change, its diff, or its export output. | `prop_redaction_leak` fixture table design (D-07), canary/hostile-shape generator strategy (D-08), three-layer `LeakOracle` detection and its three mutation controls (D-10/D-12) all verified against `lib/threadline/capture/trigger_sql.ex` line-for-line (redaction SQL at ~L401/403/447/455/583-589); export/diff surfaces verified against `lib/threadline/export.ex` and `lib/threadline/change_diff.ex` exact function signatures. |
| PROP-06 | A DB-backed property proves that `as_of` equals the state reconstructed by replaying the row's history in order. | Hand-written in-order replay oracle (D-14, rejects the tautological synthetic-`AuditChange` alternative), generator/readback/probe design (D-15), tie-example pinning (D-17) all verified against `lib/threadline/query.ex:467-495` (`as_of/4`, `as_of_query/4`) read directly this session; four mutation controls (D-16) map to specific verified lines. |
| PROP-07 | A DB-backed property proves the retention cutoff boundary with `dry_run: true`: rows strictly older than the cutoff are selected and every row at or after it survives. | Oracle shape A (dry run + real purge + byte-identical survivors, D-18), cutoff-clustering generator (D-19), the D-20 dry-run transaction-count fix (verified exact defect and one-line fix against `lib/threadline/retention.ex:131-164`), five mutation controls (D-21) and three example tests (D-22) all verified against live source; this research adds explicit survivor-snapshot mechanics (row-to-text cast scope, map-keyed comparison, precision round-trip, whole-table-empty precondition) beyond what CONTEXT.md specifies. |
</phase_requirements>

## Summary

Phase 227 adds three DB-backed StreamData properties (PROP-04 redaction leak, PROP-06 `as_of` replay, PROP-07 retention cutoff) on top of machinery phase 226 already built (`Threadline.Test.PropertyRuns`, the mutation-control runner, the scale contract, generator coverage floors). 227-CONTEXT.md is exhaustive (27 decisions) and already resolves essentially every design question; this research's job was to verify that every cited file, function, and line number is real and matches CONTEXT's description, and to flag two places where the plan needs extra care: the retention survivor byte-equality snapshot, and the D-20 dry-run fix's exact code shape.

**All citations in CONTEXT.md were independently re-verified this session and are accurate** (see Code Context below for exact re-confirmed line numbers — a few drifted by 2-10 lines from CONTEXT's figures, which is expected given CONTEXT was written against a specific commit; the *content* at each citation matches exactly). One load-bearing subtlety was independently confirmed: `Retention.purge/1`'s `sleep_ms` option (default `50`) is read only from the `opts` keyword list passed by the caller — `config/test.exs`'s `:threadline, :retention, sleep_ms: 0` key is dead for this purpose, confirming D-18 step 6's claim that the property must pass `sleep_ms: 0` explicitly.

**Primary recommendation:** Follow 227-CONTEXT.md's D-01 through D-27 as written — they are internally consistent and already verified against the codebase. The one place the planner should add explicit task-level detail beyond CONTEXT is the retention survivor snapshot/compare mechanics (below), because CONTEXT specifies the *what* (byte-identical survivors) but the exact SQL text and column list are easy to get subtly wrong (ordering, timestamp precision, text-cast scope).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Redaction leak detection (PROP-04) | Database / Storage (trigger SQL) | API/Backend (ChangeDiff, Export) | The trigger writes `data_after`/`changed_from`; the property must inspect raw DB rows *and* every downstream Elixir transform to prove no layer re-introduces plaintext. |
| `as_of` reconstruction (PROP-06) | API/Backend (`Threadline.Query`) | Database (trigger-captured `audit_changes`) | `as_of_query/4` is a pure Ecto query function; its correctness depends on trigger-written `captured_at`/`op`/`data_after`, so the oracle must independently replay real mutations rather than re-deriving from the same captured rows. |
| Retention cutoff (PROP-07) | API/Backend (`Threadline.Retention`) | Database (cascade delete, `RetentionRun`) | `purge/1` issues `delete_all` against `AuditChange`/`AuditTransaction`; the FK `ON DELETE CASCADE` (migration.ex ~L43) is a DB-tier concern the oracle must account for separately from the SQL predicate. |
| Test harness / isolation (`DbProperty`, `LeakOracle`) | Test infrastructure (not a product tier) | — | Lives entirely in `test/support/`; never ships in `lib/`. |

## Package Legitimacy Audit

Not applicable. This phase adds no new dependency — `StreamData`/`ExUnitProperties` are already present from phase 226 (`mix.exs` unchanged). No `Package Legitimacy Gate` run was needed.

## Standard Stack

No new packages. Phase reuses exactly what 226 established:

| Library | Version | Purpose | Status |
|---------|---------|---------|--------|
| `stream_data` | (pinned in `mix.exs` since 226) | Generators, `check all` | [VERIFIED: test/threadline/query/cursors_property_test.exs uses `use ExUnitProperties`, confirms dependency already wired] |
| `ex_unit_properties` | (same) | `check all` DSL | same |

**Installation:** none — no `mix deps.get` changes needed for this phase.

## Architecture Patterns

### System Architecture Diagram

```
                 ┌─────────────────────────────┐
  property body  │  StreamData generator        │
  (check all)    │  (RedactionLeakGenerators /   │
                  │   RowHistoryGenerators /       │
                  │   RetentionCutoffGenerators)   │
                 └───────────────┬─────────────┘
                                 │ generated op plan / steps / cutoff
                                 v
                 ┌─────────────────────────────┐
                 │ with_iteration(fn n -> ... end)│  <- Threadline.Test.DbProperty (D-01/D-02)
                 │  n = unique_integer (in body)  │
                 └───────────────┬─────────────┘
                                 │ real INSERT/UPDATE/DELETE via Repo
                                 v
                 ┌─────────────────────────────┐
                 │ PostgreSQL trigger (real DDL) │  <- per-table or global capture fn
                 │ writes audit_transactions +   │     (trigger_sql.ex)
                 │ audit_changes (redaction       │
                 │ applied here, not in Elixir)   │
                 └───────────────┬─────────────┘
                                 │ raw SQL readback (storage-qualified)
                                 v
        ┌────────────────────────┼─────────────────────────┐
        v                        v                          v
 LeakOracle surfaces      Query.as_of/4 model-replay   Retention.purge/1
 (PROP-04): stored rows,  oracle (PROP-06): hand-       dry-run + real
 ChangeDiff variants,     written in-order fold over    (PROP-07): oracle
 CSV/JSON/NDJSON export   generated steps, compared     computed from
                          to as_of_query output          generated facts,
                                                          never from lib code
                                 │
                                 v
                 ┌─────────────────────────────┐
                 │ after: delete_iteration!     │  <- per-iteration cleanup,
                 │ (host row -> audit_changes ->│     never on_exit-once
                 │  audit_transactions, FK order)│
                 └─────────────────────────────┘
```

A reader can trace PROP-04: generator -> real mutation -> trigger capture (redaction happens in SQL) -> raw-SQL readback of stored rows + three ChangeDiff variants + CSV/JSON/NDJSON export surfaces -> canary search (refute) + structural checks + positive-control markers -> per-iteration cleanup. PROP-06 and PROP-07 follow the same generator -> real-DB-mutation -> independent-oracle -> compare -> cleanup shape, differing only in what the oracle is (replay model vs. generated-fact set).

### Recommended Project Structure

```
test/
├── support/
│   ├── db_property.ex                  # Threadline.Test.DbProperty (D-02)
│   ├── leak_oracle.ex                  # Threadline.Test.LeakOracle (D-10)
│   ├── redaction_leak_generators.ex    # (D-03)
│   ├── row_history_generators.ex       # (D-03)
│   └── retention_cutoff_generators.ex  # (D-03)
├── threadline/
│   ├── capture/
│   │   └── redaction_leak_property_test.exs   # PROP-04 (D-03)
│   ├── query/
│   │   ├── cursors_property_test.exs          # existing (226) — pattern to mirror
│   │   └── as_of_property_test.exs            # PROP-06 (D-03)
│   └── retention/
│       └── cutoff_property_test.exs           # PROP-07 (D-03)
```

`test/threadline/retention/` does not yet exist as a directory (only `test/threadline/retention_test.exs` exists as a flat file) — the planner's file-creation task should note this is a new subdirectory, not a sibling of an existing one. [VERIFIED: `find test/threadline -maxdepth 1 -name retention*` shows only `retention_test.exs`, no `retention/` dir]

### Pattern 1: Per-iteration isolation without Sandbox (D-01)
**What:** Each `check all` body generates its unique key *inside* the body (`System.unique_integer([:positive, :monotonic])`), performs real DB writes, asserts, then deletes only its own rows in an `after` block — never relying on `on_exit` once per test, and never wrapping the iteration in a transaction+rollback.
**When to use:** Every property in this phase; this is the harness-level convention, not per-property discretion.
**Example:**
```elixir
# Pattern mirrors 226's existing DB property (verified: test/threadline/capture/trigger_rerun_property_test.exs
# exists at 133 lines and is cited in CONTEXT.md as "an existing DB property" — read directly to confirm its
# setup/teardown shape before writing the new harness).
check all plan <- op_plan_generator(), max_runs: PropertyRuns.db(20) do
  with_iteration(fn n ->
    # ... perform real inserts/updates/deletes keyed by n ...
    # ... assert against the oracle ...
  end)
end
```

### Pattern 2: Storage-qualified raw SQL reads (D-02, D-10)
**What:** Every raw SQL read against `audit_changes`/`audit_transactions` in these new properties must use `StorageSchema.table/2`, not a bare table name.
**Why:** [VERIFIED: lib/threadline/storage_schema.ex:121 `def table(name, opts \\ []) when name in @threadline_tables do`] — this is the existing qualification helper; memory and CONTEXT.md both flag unqualified reads as a documented CI-only failure vector (local DBs can carry a stale `public.threadline_capture_changes()` function that masks the defect).
**Example:**
```elixir
# Source: lib/threadline/storage_schema.ex:121 (StorageSchema.table/2)
Repo.query!(
  "SELECT row_to_json(c)::text FROM #{StorageSchema.table(:audit_changes)} c WHERE c.table_name = $1 AND c.table_pk->>'id' = $2",
  [table_name, id]
)
```

### Anti-Patterns to Avoid
- **Transaction+rollback per iteration:** rejected by D-01 explicitly — it hides trigger capture (triggers need a committed transaction, per Pitfall 1) and other connections can't see the rows for the readback/oracle steps that run outside the same transaction.
- **Extracting a shared "eligible rows" predicate between the dry-run and real-purge paths:** rejected by D-18 ("Rejected (B)") because it would make the `<` vs `<=` mutation controls flip both sides together and never go red.
- **A `max_by({captured_at, id})` oracle built from `AuditChange` structs for `as_of` (rejected D-14):** this just restates `as_of_query`'s own ORDER BY in Elixir — a tautology (Pitfall 3) that can't catch a real `as_of_query` bug because flipping the SQL flips the oracle identically.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DB test isolation without Sandbox | A custom transactional test wrapper | `Threadline.DataCase` (`async: false`) + per-iteration unique keys (D-01) | Sandbox is incompatible with triggers firing on committed data (project-wide constraint, confirmed in `test/support/data_case.ex` moduledoc: "Does NOT use Ecto sandbox — PostgreSQL triggers fire at the DB level, outside sandbox awareness") |
| Mutation-control tooling | A new script | `.planning/phases/226-.../tools/mutation-control.sh`, hardened per D-23 | Already proven on 7 controls in 226; only needs the `awk` fix (below) |
| Deterministic uuid tie construction | Ad hoc byte packing | `ordered_id(rank, n) = Ecto.UUID.load!(<<rank::32, n::96>>)` (D-02) | Needed once, for the D-17 tie example only; keep it in the shared support module so it isn't reinvented |

**Key insight:** every "don't hand-roll" item here is actually "don't re-diverge from phase 226's pattern" — this phase's main engineering risk is harness drift (a fourth DB-test convention appearing next to DataCase), which D-02's moduledoc forbids by banning `__using__`/`setup` in `Threadline.Test.DbProperty`.

## Common Pitfalls

### Pitfall 1: Shrinking against a live, shared, non-sandboxed database
**What goes wrong:** StreamData's shrinker reruns the property body with smaller/different generated values on failure. If iteration state (DB rows) from a failed run isn't cleaned up, or if cleanup happens in a module-level `on_exit` rather than per-iteration, the second shrink pass starts from a dirty database and produces misleading results — or the dry-run/real-purge oracles (which scan the *whole* table) silently include rows from a prior unrelated iteration.
**Why it happens:** No Sandbox means no implicit rollback; every `check all` run is a committed side effect.
**How to avoid:** D-01's `with_iteration/1` + `after`-block cleanup, scoped by a key generated fresh *inside* the body (never as a generated value — a generated key could get shrunk and start colliding across runs, or appear in a counterexample and break replay-seed comparison).
**Warning signs:** `assert_audit_tables_empty!()` failing at the start of a PROP-07 iteration; the retention survivor count including "extra" rows.

### Pitfall 2: Capture-layer clock monotonicity assumptions
**What goes wrong:** `clock_timestamp()` ([VERIFIED: lib/threadline/capture/trigger_sql.ex:566, global function] and ~L331 for the per-table function) gives every captured row a distinct, strictly-increasing timestamp in practice (D-17's probe: 0 ties in 9,001 real captures, 38µs floor) — but this is an empirical property of `clock_timestamp()`, not a guarantee. A mutant that swaps it for `now()` (which is frozen per-transaction) makes every step in one multi-statement transaction share a timestamp.
**Why it happens:** `now()` and `clock_timestamp()` are easy to confuse; both compile and both "work" for a single-statement-per-transaction workload.
**How to avoid:** D-16's `capture_clock.patch` mutation control exists specifically to catch this; the property must assert strictly increasing `captured_at` across steps in the same iteration (D-15) to have a chance of catching it — a weaker assertion (e.g., non-decreasing) would miss it.
**Warning signs:** A green mutation-control run for `capture_clock.patch` would mean the strict-increase assertion is missing or too weak.

### Pitfall 3: Dry-run / real-purge count drift (the D-20 defect)
**What goes wrong:** `dry_run_result/4` ([VERIFIED: lib/threadline/retention.ex:131-164]) computes `eligible_txns` via a `not exists` subquery that checks "does this transaction have *any* surviving change at all" ([VERIFIED: lib/threadline/retention.ex:144-149] `where: c.transaction_id == parent_as(:audit_transaction).id` — no `captured_at` filter). The real purge's `drain_orphans/4` ([VERIFIED: lib/threadline/retention.ex:228-250]) runs *after* `delete_change_batch/4` has already deleted expired changes, so its identical-looking `not exists` check (same shape, same missing `captured_at` filter — [VERIFIED: lib/threadline/retention.ex:233-238]) is correct in context: by the time it runs, "no surviving change" and "no change past cutoff" are the same thing, because the expired ones are already gone. The dry-run path never deletes anything, so its `not exists` check without the `captured_at >= cutoff` guard answers a different question ("is this transaction already fully orphaned today") rather than "would this transaction become orphaned by this purge" — undercounting transactions that currently have *only* expired changes.
**Why it happens:** The two code paths look structurally identical (same `not exists` shape) but run at different points relative to the delete, so a predicate that's correct in one context is silently wrong in the other.
**How to avoid:** D-20's fix — add `and c.captured_at >= ^cutoff` inside the dry-run subquery's `not exists`, making it "no *surviving* change" instead of "no change at all." [VERIFIED: confirmed exact code at lib/threadline/retention.ex:141-156 — this is the only place the predicate needs to change]
**Warning signs:** The probe CONTEXT.md cites reproduces this today: dry `{changes: 2, txns: 0}` vs. real `{changes: 2, txns: 1}` for `cutoff = 2001-06-01` with rows at `C−1µs, C, C−1s, C+1s`.

### Pitfall 4: `sleep_ms` config is a dead letter for `purge/1`
**What goes wrong:** A test author might expect `config :threadline, :retention, sleep_ms: 0` (set in `config/test.exs` [VERIFIED: config/test.exs:78-83]) to make `purge/1` run without the inter-batch sleep. It does not: `purge/1` reads `sleep_ms` only from its own `opts` argument ([VERIFIED: lib/threadline/retention.ex:53] `sleep_ms = Keyword.get(opts, :sleep_ms, 50)` — the `policy` struct returned by `Policy.resolve!/1` is never consulted for `sleep_ms` inside `purge/1`), defaulting to `50` ms if the caller doesn't pass it explicitly.
**Why it happens:** Config and function-opts both plausibly look like "the sleep setting"; only one is wired.
**How to avoid:** PROP-07's call to `purge/1` must pass `sleep_ms: 0` explicitly (as D-18 step 6 already specifies), or every iteration pays a real 50ms sleep per batch — at `batch_size` values like `1`, this could blow the property's run-time budget across `max_runs: PropertyRuns.db(20)` iterations with multiple batches each.
**Warning signs:** The property runs much slower than the "measure first, only lower max_runs if it costs >2s" budget in D-05 would predict, with no obvious cause in the generator.

### Pitfall 5: The scale-contract gap this phase must close (D-06)
**What goes wrong:** `test/threadline/property_scale_contract_test.exs`'s rule (c) ([VERIFIED: test/threadline/property_scale_contract_test.exs:12-18, moduledoc] and the `classify_max_runs/3` dispatch at lines 298-313) scans every `test/**/*_property_test.exs` file and checks that `max_runs:` resolves to either `PropertyRuns.pure(150..200)` **or** `PropertyRuns.db(1..20)` — it does not check which case-use macro (`ExUnit.Case` vs `Threadline.DataCase`) the file uses. A new `*_property_test.exs` using `Threadline.DataCase` with `max_runs: PropertyRuns.pure(150)` would pass this contract today even though `pure(150)` means ~150 live-DB iterations, wildly over SC4's "DB properties ≤ 20" ceiling.
**Why it happens:** The contract's source-scan classifies the `max_runs:` expression in isolation; it has no cross-reference to the enclosing module's `use` clause.
**How to avoid:** D-06's fix — extend the contract to detect `use Threadline.DataCase` in the same file and require `db(...)` specifically (not `pure(...)`) when present, with its own mutation control (a `DataCase` fixture using `pure(150)` must be flagged).
**Warning signs:** None in production — this is a documentation/test-authoring-time safety net, so the only way to "see" the gap is to try the contract test against a deliberately wrong fixture, which D-06 asks for as the mutation control.

### Pitfall 6: `extract_counterexample`'s `awk` pattern (D-23)
**What goes wrong:** [VERIFIED: .planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh:122-126] — `extract_counterexample()` is: `awk '/Failed with generated values/{flag=1} flag{print} flag && /^\s*$/{exit}' "$1"`. CONTEXT.md's D-23 states this stops right after the header on GNU awk today, so the replay comparison (the main determinism proof for DB properties, since DB generators are more structurally complex than 226's pure ones) only compares "after N successful runs" rather than the full generated-values block across every clause.
**Why it happens:** `\s` is a GNU awk extension for whitespace; behavior around it interacting with the blank-line match can differ subtly from the intended "stop at the first blank line after the header" semantics, especially with multi-clause `check all` generators that may have different inter-field whitespace shapes than 226's.
**How to avoid:** D-23's directed fix — use the POSIX bracket expression `[[:space:]]` instead of `\s`, then re-run one 226 patch to confirm backward compatibility before relying on it for 227's three (structurally larger) generators.
**Warning signs:** A mutation-control "replay" step that reports success even when the shrunk counterexample text visibly differs between runs — the exact failure mode D-23 is defending against.

## Code Examples

### Verified storage-qualified raw read pattern
```elixir
# Source: lib/threadline/storage_schema.ex:121 (table/2), combined with the
# existing raw-read convention already used in the codebase for audit tables.
alias Threadline.StorageSchema

qualified = StorageSchema.table(:audit_changes)
Repo.query!("SELECT row_to_json(c)::text FROM #{qualified} c WHERE c.id = $1", [id])
```

### Verified `as_of`/`as_of_query` contract to replay against
```elixir
# Source: lib/threadline/query.ex:467-495 (read directly this session)
def as_of(schema_module, id, timestamp, opts) do
  repo = Keyword.fetch!(opts, :repo)
  snapshot = schema_module |> as_of_query(id, timestamp, opts) |> repo.one(storage_opts([], opts))

  case snapshot do
    %AuditChange{op: "delete"} -> {:error, :deleted_record}
    %AuditChange{data_after: data_after} -> load_as_of_snapshot(schema_module, data_after, opts)
    nil -> {:error, :before_audit_horizon}
  end
end

def as_of_query(schema_module, id, timestamp, opts) do
  repo = Keyword.fetch!(opts, :repo)
  matched = RowKey.match!(schema_module, id, repo)

  AuditChange
  |> where_row(matched)
  |> where([ac], ac.captured_at <= ^timestamp)       # D-16 mutation target 1: <= -> <
  |> maybe_apply_scope(row_history_scope_opts(schema_module, id, opts))
  |> order_by([ac], desc: ac.captured_at)             # D-16 mutation target 2: desc -> asc
  |> order_by([ac], desc: ac.id)                      # D-16 mutation target 3 (expected to survive, per D-17)
  |> limit(1)
end
```
Every value in this example (`"delete"`, `:before_audit_horizon`, `:deleted_record`, the two `order_by` clauses, the `<=` operator) is quoted verbatim from the file read this session — no paraphrase.

### Verified retention purge return shape and dry-run defect site
```elixir
# Source: lib/threadline/retention.ex:131-164 (read directly this session)
defp dry_run_result(repo, cutoff, policy, storage_opts) do
  eligible_changes =
    repo.one(
      from(ac in AuditChange, where: ac.captured_at < ^cutoff, select: count(ac.id)),
      storage_opts
    )

  eligible_txns =
    if policy.delete_empty_transactions do
      repo.one(
        from(at in AuditTransaction,
          as: :audit_transaction,
          where:
            not exists(
              from(c in AuditChange,
                where: c.transaction_id == parent_as(:audit_transaction).id,
                select: 1
              )
            ),
          select: count(at.id)
        ),
        storage_opts
      )
    else
      0
    end

  %{
    deleted_changes: eligible_changes,
    deleted_transactions: eligible_txns,
    batches_run: 0,
    dry_run: true
  }
end
```
The D-20 fix adds `and c.captured_at >= ^cutoff` inside the inner `where:` of the `not exists` subquery (the `c.transaction_id == parent_as(:audit_transaction).id` line) — this is the exact and only line to change.

### Retention survivor snapshot — recommended exact mechanics (new content beyond CONTEXT.md, for the planner)

CONTEXT.md's D-18 step 4 says: "Snapshot `SELECT id::text, t::text FROM <qualified table> t` for both tables. Casting the whole row to text covers every column, including future ones." This researcher verified the shape is sound but flags four details the plan must pin down explicitly, since getting any of them wrong silently weakens the byte-equality check to a vacuous one:

1. **Row-to-text cast, not column-by-column.** `t::text` on a composite row alias casts the *entire row* (every column, in table-definition order) to its default text representation — this is what makes the check automatically cover a column added to `audit_changes`/`audit_transactions` later, as CONTEXT.md intends. A column-by-column `SELECT id, data_after, ...` snapshot would need updating every time the schema gains a column, defeating the stated purpose.
2. **Ordering for comparison, not for the SQL itself.** The snapshot must be captured as a `%{id => text}` map (or sorted by `id`) rather than compared as an ordered list — Postgres makes no row-order guarantee without `ORDER BY`, and the real purge's `delete_all` could plausibly interact with autovacuum/row layout between the dry-run snapshot and the post-purge read. Compare by id-keyed map equality, not list equality.
3. **Timestamp precision interaction with `insert_all`.** D-19 generates `captured_at` at precision-6 explicitly because (per the Specific Ideas section) "`insert_all` rejects precision-0 values" while "Ecto's `cast(:utc_datetime_usec)` normalises precision-0 and non-UTC values at query time." Since the survivor snapshot reads the row back via raw SQL (`::text`) rather than through an Ecto cast, the stored precision is whatever Postgres actually persisted — the plan should confirm (as a one-line assertion inside the property, not assumed) that the inserted precision-6 value round-trips through `::text` unchanged, since this is exactly the kind of implicit normalization that would make "byte-identical" silently pass on a value that was never actually compared at full precision.
4. **Scope of "every row at or after cutoff," given no Sandbox.** Because `Threadline.DataCase` cleans `clean_storage_schemas!()` in its own `setup` (not `setup_all`) ([VERIFIED: test/support/data_case.ex:19-23] `setup do Threadline.StorageSchema.clean_storage_schemas!() :ok end`), this wipes the tables before *each test function* starts, but says nothing about other rows appearing *during* the property's own `check all` loop — i.e., leftover rows from the prior iteration of the same `check all`, not from other tests. This is exactly D-01's `assert_audit_tables_empty!()` precondition: the property must call it at the top of every iteration (not just once per test) to keep the global-table oracle (D-18) sound, since retention's dry-run and purge act on the *whole* table with no row-key filter.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| 226's "clean once in `on_exit`" rule (STACK §2.3) | Per-iteration cleanup inside `with_iteration/1`'s `after` block | This phase (D-01) | Required because retention's oracle and export's filterless query act on the whole table, not a row-keyed subset — leftover rows from a prior iteration would silently corrupt both oracles. |
| 226's rejected synthetic-`AuditChange` oracle suggestion for `as_of` (STACK §2 L50) | Hand-written in-order replay model built from the test's own fold over generated steps (D-14) | This phase | Closes the tautology risk (Pitfall 3 in PITFALLS.md): an oracle built from the same `AuditChange` rows the code under test reads would flip in lockstep with a buggy `ORDER BY`. |
| STACK §1.5's "dry-run-only" retention design | Dry run + real purge + byte-identical-survivor check (D-18, shape A) | This phase | A dry-run-only check can prove the *count* is right but can't prove the cascade or a content-tampering bug (Pitfall 16) wouldn't still destroy or corrupt survivors during a real run. |

**Deprecated/outdated:** None — this phase doesn't retire any existing test infrastructure, only extends it (`DbProperty` is new but additive; `property_scale_contract_test.exs` gains a rule, doesn't replace one).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `test/threadline/retention/` directory does not yet exist and must be created fresh | Recommended Project Structure | Low — trivially checked by `mkdir -p` at execution time; confirmed via `find` this session, not a risky guess. |
| A2 | A `timestamptz` column's session-timezone rendering issue (noted in D-14's "Column choice" and the Specific Ideas probe) only affects the *excluded* `numeric`/`timestamptz` column types, not the precision-6 `captured_at` column itself | Retention survivor snapshot (point 3) | Medium — if `captured_at`'s `::text` rendering is also timezone-dependent in a way that differs between the dry-run snapshot and the post-purge read (e.g., a session-level `SET TIME ZONE` executed mid-test by an unrelated connection), the byte-equality check could falsely pass or fail. The property's own one-line round-trip assertion (recommended above) would catch this at property-write time rather than leaving it as a latent assumption. |

## Open Questions

1. **Does the D-20 fix require a maintainer veto decision before or during planning?**
   - What we know: D-20 names this as "reversible... the maintainer can veto at plan review; in that case the property pins the current behaviour with a named assertion and VERIFICATION.md records the gap." STATE.md's narrative line also flags this as "D-20 retention dry-run fix pending maintainer veto."
   - What's unclear: Whether the plan should include the fix as a default task with a maintainer-decision checkpoint, or ship the pin-only path and add the fix only on explicit approval.
   - Recommendation: Plan both paths behind a single `checkpoint:decision` task early in the PROP-07 wave (before D-18 step 6's dry/real-agreement assertion is turned on, as D-01's discretion note for wave split already anticipates) — the rest of the PROP-07 plan can be written to work either way since D-25's pin-path is well-specified as a fallback.

2. **Exact wording/line target for the `property_scale_contract_test.exs` D-06 extension.**
   - What we know: The existing contract's dispatch chain is `classify_max_runs/3` → `classify_db_or_attribute/3` → `classify_attribute_reference/3` ([VERIFIED: test/threadline/property_scale_contract_test.exs:298-326]), classifying purely on the `max_runs:` AST with no cross-reference to the file's `use` clause.
   - What's unclear: Whether detecting `use Threadline.DataCase` is best done via a source-text regex on the test file or via parsing its `use` clause's AST consistently with how the rest of the contract already parses `check all(...)` clauses.
   - Recommendation: Follow whatever AST-parsing convention the existing contract already uses for finding `check all` clauses (the file already does real AST work, not regex, per its moduledoc's "parsed with YamlElixir rather than matched by regex" philosophy applied elsewhere) — the planner should read the full file (not just the excerpt above) before writing this task.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL (local) | All three properties (`async: false`, real DDL/DML) | ✓ (per STATE.md narrative: PG 14.17 local, PG 18.6 in CI `latest` lane) | 14.17 local / 18.6 CI | — |
| `mix verify.flake` / Flake Detection workflow | D-27 scaled confirmation run | ✓ — workflow exists at `.github/workflows/flake-detection.yml`, confirmed `timeout-minutes: 70`, repeat step `timeout-minutes: 58`, ceilings `@cold_first_run_ceiling_s 348` / `@repeat_ceiling_s 295` [VERIFIED: test/threadline/flake_classifier_contract_test.exs:758-759] | 8 repeats (as of phase 226's confirmation run) | If the three new properties exceed the room, D-27 says drop to 7 repeats; never raise the 55-minute budget. |
| `test/partition_weights.txt` | D-27, only if a new file costs > 2s solo | ✓ exists, 230 lines, documented regeneration command `bin/ci-test-partitions --write-weights` [VERIFIED: test/partition_weights.txt:1-5] | — | Append-only; a missing entry only degrades partition balance, never fails a test (per the file's own header comment). |
| Push/dispatch grant for CI runs (Flake Detection, partitioned CI) | D-27's SC5 wall-clock comparisons | Pending — D-27 explicitly says "With no push grant, record that step as pending, with the exact commands." | — | Plan must include the exact commands to run once a grant is available, per repo convention (CLAUDE.md "push blocked by classifier" memory). |

**Missing dependencies with no fallback:** None — every dependency either exists or has a documented fallback/pending-state convention already established by prior phases.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + StreamData/ExUnitProperties (already in `mix.exs` since phase 226) |
| Config file | `config/test.exs` (DB connection, `:retention` defaults, `:trigger_capture` fixture config) |
| Quick run command | `mix test test/threadline/capture/redaction_leak_property_test.exs test/threadline/query/as_of_property_test.exs test/threadline/retention/cutoff_property_test.exs` |
| Full suite command | `mix test` (unscaled) and `THREADLINE_PROPERTY_SCALE=5 mix test` (scaled, weekly-lane equivalent) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROP-04 | Redacted plaintext never reaches stored change, ChangeDiff, or CSV/JSON/NDJSON export | property (DB-backed) | `mix test test/threadline/capture/redaction_leak_property_test.exs -x` | ❌ Wave: create per D-03 |
| PROP-06 | `as_of` at every point equals hand-written in-order replay | property (DB-backed) | `mix test test/threadline/query/as_of_property_test.exs -x` | ❌ Wave: create per D-03 |
| PROP-07 | `Retention.purge(dry_run: true)` selects exactly rows strictly older than cutoff; survivors byte-identical | property (DB-backed) | `mix test test/threadline/retention/cutoff_property_test.exs -x` | ❌ Wave: create per D-03 (new `test/threadline/retention/` dir) |

### Sampling Rate
- **Per task commit:** the single new/changed property file, via `mix test <file> --seed 0` plus one `--repeat-until-failure 20` pass per D-27's local acceptance step.
- **Per wave merge:** `mix test` (full unscaled suite) to check suite-order effects, as D-27 specifies.
- **Phase gate:** `THREADLINE_PROPERTY_SCALE=5 mix test` once at scale, plus the mutation-control runner (`K=5`) for every control named in D-12/D-16/D-21, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/support/db_property.ex` — new shared harness (D-02)
- [ ] `test/support/leak_oracle.ex` — new shared PROP-04 detection module (D-10)
- [ ] `test/support/redaction_leak_generators.ex`, `row_history_generators.ex`, `retention_cutoff_generators.ex` — new generator modules (D-03)
- [ ] `test/threadline/retention/` directory — does not exist yet (confirmed this session; only the flat `retention_test.exs` file exists)
- [ ] `property_scale_contract_test.exs` extension (D-06) — must land before or alongside the first `*_property_test.exs` file that uses `Threadline.DataCase`, or the gap it's meant to close is open for however long the ordering is reversed

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | Not in scope — no auth code touched this phase |
| V3 Session Management | No | — |
| V4 Access Control | No | — |
| V5 Input Validation | Partial — generator-produced hostile strings exercise redaction robustness, not user input validation per se | Canary/hostile-shape generation (D-08) acts as a fuzz-style input-validation proxy for the redaction boundary |
| V6 Cryptography | No | Redaction here is masking/exclusion, not cryptographic protection — no crypto primitives involved |
| V9 Data Protection (sensitive data exposure) | **Yes — this is the core of PROP-04** | `TriggerSQL.install_function_for_table(exclude:, mask:)` at the DB-trigger layer; the property's `LeakOracle` is itself the control verifying no sensitive data (the canary standing in for PII/secrets) reaches storage, diff, or export surfaces |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Redacted column plaintext leaking through a downstream transform (ChangeDiff variant, export format) that doesn't know about redaction | Information Disclosure | D-10's three-layer oracle (surfaces + canary search + structural rules + positive controls) — this is exactly the class of bug PROP-04 targets |
| Fail-open redaction on a misnamed `exclude:`/`mask:` column (noted in Deferred, NOT in this phase's scope) | Information Disclosure | Out of scope for 227 per CONTEXT.md's Deferred section — flagged for backlog/v1.45; the planner should not attempt to close this gap in 227 |
| A telemetry handler (228's scope, not 227's) accidentally observing plaintext from a redaction event | Information Disclosure | D-11 notes 227 must build the `LeakOracle` surfaces list so attaching a telemetry handler later (228) is "purely additive" — 227 itself attaches no handler |

**Any redaction leak this property finds is reported to the maintainer the same day and flagged as security, per D-25.**

## Sources

### Primary (HIGH confidence — all read directly this session)
- `lib/threadline/capture/trigger_sql.ex` (659 lines) — redaction SQL generation, `clock_timestamp()` usage, mask/exclude mechanics
- `lib/threadline/query.ex` (792 lines) — `as_of/4`, `as_of_query/4`
- `lib/threadline/retention.ex` (251 lines) — `purge/1`, `dry_run_result/4`, `drain_orphans/4`, `delete_change_batch/4`
- `lib/threadline/export.ex` (462 lines) — `to_csv_iodata/2`, `to_json_document/2`, `stream_export_rows/2`, `format_changes_iodata/3`
- `lib/threadline/change_diff.ex` (228 lines) — `:export_compat`, `:expand_insert_fields` options
- `lib/threadline/storage_schema.ex` — `table/2`
- `test/support/data_case.ex`, `test/support/property_runs.ex` — DataCase and PropertyRuns.db/1 exact arithmetic
- `test/threadline/retention_test.exs`, `test/threadline/query_test.exs`, `test/threadline/property_scale_contract_test.exs`, `test/threadline/flake_classifier_contract_test.exs`
- `config/test.exs` — partition DB naming, `:retention` defaults, `:trigger_capture` fixture
- `.planning/phases/226-pure-property-tests-and-run-budget/tools/mutation-control.sh` — `extract_counterexample`
- `.github/workflows/flake-detection.yml` — repeat/timeout budget
- `test/partition_weights.txt` — existing format, regeneration command

### Secondary (MEDIUM confidence)
- `.planning/research/STACK.md`, `.planning/research/PITFALLS.md` (Pitfall 1 and others) — prior-phase research, partially superseded per CONTEXT.md's own "Superseded in parts by this CONTEXT" note (§2 L50 oracle rejected, §2.3 on_exit rule replaced, §1.5 dry-run-only design replaced)

### Tertiary (LOW confidence)
- None — this phase needed no external/web research; everything is in-repo verification.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies, nothing to verify against a registry
- Architecture: HIGH — every cited file/function/line opened and confirmed this session
- Pitfalls: HIGH for the in-repo ones (D-20, sleep_ms, D-06 contract gap, D-23 awk bug) — all independently reproduced/confirmed by reading source; the broader "StreamData + live DB" pitfall class is carried from phase 226's already-proven pattern

**Research date:** 2026-10-01
**Valid until:** Next commit touching `lib/threadline/retention.ex`, `lib/threadline/query.ex`, `lib/threadline/capture/trigger_sql.ex`, or `test/threadline/property_scale_contract_test.exs` — line numbers will drift; re-verify citations before executing if any of these files changed since 2026-10-01.
