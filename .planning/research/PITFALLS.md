# Pitfalls Research — v1.44 Behavioral Depth: Properties, Twins, Telemetry

**Domain:** Trigger-backed Postgres audit capture library (Elixir/Phoenix/Ecto), adding property tests, telemetry, a `history/3` limit, a test-suite rebalance/async cut, a `gen.triggers` down-orphan fix, and a bench compile fix, one minor release before the v1.45 API-contract milestone.
**Researched:** 2026-09-30
**Confidence:** HIGH for repo-specific claims (read from `lib/`, `test/`, `.planning/`); MEDIUM for ecosystem-precedent claims (StreamData/Carbonite/Oban/PaperTrail/Logidze docs and community reports, not independently re-verified against every version).

## Critical Pitfalls

### Pitfall 1: Properties that shrink against a live, shared, non-sandboxed database

**What goes wrong:**
Threadline's suite has no `Ecto.Adapters.SQL.Sandbox` anywhere (trigger capture must see real committed transactions — `AuditTransaction`/`AuditChange` rows only exist after commit, so a rolled-back sandbox test never captures anything). 56 test files already run `async: false` for exactly this reason. StreamData's shrinker re-runs the property body dozens of times per failure, each iteration doing real INSERT/UPDATE/DELETE plus trigger execution and NOTIFY/foreign-key checks. Against a shared, non-transactional DB this means: (a) shrinking itself mutates state other properties or async processes can observe, (b) a shrink step that "fixes" a generated input by retrying can leave rows from earlier failed shrink candidates behind, corrupting the next property's row counts, and (c) two properties or `mix test` and a manually-open `psql` session touching the same tables at once produce lock contention that looks like a StreamData counter-example but is actually a schedule artifact.

**Why it happens:**
Property tests are typically written and demoed against ExUnit's default in-memory or sandboxed setup (the Elixir docs and most StreamData tutorials assume `Ecto.Adapters.SQL.Sandbox`). Threadline can't use that pattern because triggers require committed rows, so anyone porting a "normal" StreamData/Ecto property recipe in will reach for sandbox checkouts that silently no-op the capture path, or skip cleanup and get a growing, cross-run-polluted dataset.

**How to avoid:**
- Every new property test must explicitly truncate/delete its own rows in `setup`/`on_exit`, scoped by a per-test-run unique key (table name suffix, actor id, or correlation id), never relying on transaction rollback.
- Keep every new property `async: false` (matching the existing 56-file convention) unless the property module only touches an in-memory pure function (e.g. `ChangeDiff` on structs, not DB rows) — in that case make it explicitly `async: true` and never touch `Threadline.Test.Repo`.
- Cap `max_runs`/`:max_shrinking_steps` explicitly per property (don't take StreamData's defaults) so a shrink storm against the DB has a bounded worst case.
- Bound generators to the domain's edges (e.g. cursor pages over 1–200 rows, not 1–100k) — see Pitfall 2.

**Warning signs:** A property test passes solo but fails under `mix test` full-suite order; failure output shows a shrunk counter-example that doesn't reproduce when run alone; `mix verify.flake` flags a property file; CI shows different failures on reruns of the same commit.

**Phase to address:** The phase introducing property tests (cursor paging, `as_of`, ChangeDiff, redaction, retention, export). Acceptance check: each new property test file runs green 20x locally (`mix test --repeat-until-failure 20 path/to_test.exs` or equivalent) before merge, and is `async: false` unless proven pure.

---

### Pitfall 2: `captured_at`/`occurred_at` tie generators that don't match the real tiebreak

**What goes wrong:**
The keyset cursor helpers (`Threadline.Query.Cursors`) order by `(occurred_at, id)` / `(captured_at, id)` pairs via a `(?, ?) < (?, ?)` row-comparison fragment. If a property test generates change rows with `StreamData.timestamp` variants that produce *distinct* timestamps for every row, it never exercises the tie path that the deterministic tiebreak (`captured_at desc, id desc`) exists to solve. A generator that instead constant-folds timestamps (e.g. `constant(DateTime.utc_now())` reused across a batch insert) will produce real ties but only ever with a single fixed value, hiding order-dependent bugs that appear only when ties are interleaved with non-ties.

**Why it happens:** Postgres timestamp columns have microsecond resolution; a naive generator using `DateTime.utc_now()` per row "looks" like it produces ties because rows insert faster than the clock ticks in CI, and this is invisible until it isn't (a slower CI runner spreads them out, and the "tie" property silently stops testing what it claims to).

**How to avoid:**
Generate `captured_at` explicitly as a controlled list with deliberate duplicates (e.g. `StreamData.member_of([t0, t0, t0, t1, t1, t2])` interleaved with unique ids) rather than relying on wall-clock timing. Assert the invariant against the *generated* timestamp/id pairs, not against `DateTime.utc_now()` read back out — the property must know its own ground truth, not re-derive it from the DB.

**Warning signs:** A "duplicate captured_at" property that never fails even when the fragment ordering is deliberately reverted (mutation-test it: temporarily flip `desc, desc` to `desc, asc` and confirm the property catches it).

**Phase to address:** The cursor-paging and `as_of`/history property-test work. Acceptance check: mutation control — temporarily break the tiebreak order in a throwaway branch and confirm the new property goes red (same discipline v1.43 applied to CI contract rules per RETROSPECTIVE.md).

---

### Pitfall 3: Properties that restate the SQL instead of testing the invariant (tautological, Hypothesis/QuickCheck's classic trap)

**What goes wrong:**
A "property" that generates a list of changes, inserts them, calls `history/3`, and asserts the result equals `Enum.sort_by(inserted, & &1.captured_at, :desc)` computed the *same way the query does it* (same tiebreak, same ORDER BY logic reimplemented in Elixir) tests that two implementations of the same sort agree, not that the invariant (`as_of` == replayed history, `pages joined == full list`) actually holds against independent ground truth. This is the single most common QuickCheck/Hypothesis failure mode: model-based properties whose "model" is just the implementation copied into the test.

**Why it happens:** It's the path of least resistance — the fastest way to get a passing property is to mirror the implementation's logic in the assertion. The MILESTONE-GUIDE.txt itself calls this out generally ("Tests are never tautological... restates the implementation"), and v1.41's retrospective explicitly names a credo-vacuous-gate regression from exactly this class of shortcut.

**How to avoid:** For each invariant, write the test's ground truth using a *different* mechanism than the code under test: for cursor paging, assert `Enum.sort(joined_ids) == Enum.sort(full_list_ids)` (set equality, not an order replica) and separately assert no duplicate ids across pages and page count matches `ceil(n/limit)`; for `as_of`, replay changes with a hand-written fold over `AuditChange` structs (not by calling the same query function under test with different args) and compare final state field-by-field; for export round-trip, decode the export format with an independent decoder path (e.g. `Jason.decode!` against the raw NDJSON bytes) and compare to the source rows, not to `Export.encode/1`'s own output structure.

**Warning signs:** Code review finds the property's expected-value computation imports or calls the same private helper the implementation uses; the property still passes after intentionally introducing an off-by-one in the code under test (this is the mutation-testing check — required before merge per the MILESTONE-GUIDE.txt quality bar).

**Phase to address:** Every property-test requirement in this milestone. Acceptance check: each property PR includes one intentional-bug mutation run showing red, cited in the phase's VERIFICATION.md (mirrors the v1.43 pattern of "mutation controls on every contract rule").

---

### Pitfall 4: Property runtime creep silently eating the CI budget this milestone is trying to shrink

**What goes wrong:** v1.44 explicitly exists partly to cut the suite's ~91% serial core (~191s of 209s per pass). Adding 6+ new property tests, each doing real DB round-trips per StreamData run (default 100 runs/property), at `async: false`, can easily add more serial wall-clock time than the async-conversion work removes — net-negative on the milestone's own goal. StreamData has no built-in per-test wall-clock budget; a generator with a wide size range (e.g. "cursor paging" testing lists up to 10,000 rows) turns a 100-run property into a multi-minute single test.

**Why it happens:** Property-test defaults are tuned for pure, fast, in-memory code, not DB-round-tripping ones. Nobody caps `max_runs` explicitly and it silently stays at 100.

**How to avoid:** Set an explicit, small `max_runs` per property (e.g. 20–30 for DB-touching properties, default 100 only for pure ones like `ChangeDiff`), bound generator sizes to realistic adopter scale (tens to low hundreds of rows, matching §4's "large tables" concern being a separate perf-baseline topic, not this milestone's), and measure each new property test's wall-clock cost before merge — cite it in VERIFICATION.md the way 214/218 cited runner-minutes. Consider `ExUnitProperties`'s `:initial_size`/`:max_run_time` options if the version in use exposes them.

**Warning signs:** `mix test` total wall-clock goes up after the "rebalance toward behavior" phase; a single property test takes >5s.

**Phase to address:** Both the property-test phase and the "cut the serial core" phase — they should be sequenced or measured together, not independently, since one adds serial DB tests and the other tries to remove serial time. Recommend measuring total suite wall-clock before and after each phase, not just at milestone end.

---

### Pitfall 5: Telemetry metadata leaking PII or raw row data (redaction bypass via the side door)

**What goes wrong:** Threadline promises redaction never leaks (`--except-columns`, redaction is a named property-test target this milestone). Telemetry events for export/retention/query/install are a second, unaudited channel for the same data to leak through: an export-telemetry event that includes `metadata: %{file_path: path, row_count: n, query: sql}` looks harmless, but if a future or adopter-side handler logs metadata wholesale (a common Oban/Telemetry.Metrics pattern — attach a handler that does `Logger.info(inspect(metadata))`), and `sql` embeds literal `WHERE actor_id = 'user@example.com'` or export metadata embeds a redacted column's post-redaction value for debugging, PII exits through a code path redaction tests never look at. This is a known Oban footgun too — Oban's own telemetry docs warn against putting `args` (which can hold PII) directly into telemetry metadata for exactly this reason, and Oban Web had to add explicit scrubbing.

**Why it happens:** Telemetry metadata is typically built by whoever writes the emit call, months after the redaction contract was designed, and nobody re-runs the redaction property tests against telemetry payloads because they're a different subsystem.

**How to avoid:**
- Telemetry metadata for export/retention/query events carries **counts, durations, table names, and status atoms** — never row values, actor emails, free-text reasons, or literal SQL/WHERE fragments. Follow the existing `[:threadline, :health, :checked]` pattern (`%{covered: int, uncovered: int}` — structural counts only) as the house style; do not regress from it.
- Add one property or example test asserting that for every new telemetry event, `metadata` values are drawn only from an allowlisted type set (integers, atoms, short enumerated strings) — this can be a simple `Enum.all?(metadata, fn {_k, v} -> is_integer(v) or is_atom(v) or v in @allowed_strings end)` check exercised against representative event calls in the export/retention/query code paths.
- Extend redaction's "never leaks" property (already scoped this milestone) to also assert telemetry handlers attached during the test never observe a redacted value — attach a test handler in the redaction property test itself and assert on what it captured.

**Warning signs:** Grep `Telemetry.execute` call sites this milestone adds; any metadata map literal that includes a variable sourced from row data, query params, or `reason:`/`context:` free text is a hit.

**Phase to address:** The telemetry phase (export/retention/query/install events), cross-checked against the redaction property-test phase. Acceptance check: a redaction-leak property test that also subscribes a telemetry handler and fails if it observes plaintext.

---

### Pitfall 6: Telemetry handler crashes silently detaching the handler (adopter loses observability with no signal)

**What goes wrong:** `:telemetry.execute/3` runs attached handlers synchronously in the caller's process. If an adopter's handler raises (a very common integration bug — e.g. their `Logger`/Prometheus/StatsD client isn't started yet, or their handler pattern-matches a metadata shape that changes), `:telemetry` itself catches the error, logs it, and **detaches the handler**, but Threadline's own code path continues (the transaction still commits, the export still runs). The adopter now silently stops receiving telemetry for the rest of the process/app lifetime with no restart, and nothing in Threadline surfaces that — mirroring exactly the reasoning already written into `[:threadline, :health, :checked, :error]`'s moduledoc ("lets adopters alert on transient failure") for health, but this milestone adds four more event families without that same "what if the handler itself is broken" thought applied.

**Why it happens:** Library authors assume `:telemetry.execute` is fire-and-forget-safe because the *library's* code won't raise; they don't design for the handler side, which is entirely the adopter's code and out of Threadline's control.

**How to avoid:** Document explicitly (in the telemetry moduledoc, following the existing docstring style) that handlers must not raise, that `:telemetry` detaches on error, and that adopters should wrap their own handler bodies. Optionally add a lightweight `Threadline.Telemetry.attach_default_logger/0` or similar safe reference handler for install/export/retention/query events (Oban and Ecto both ship a "here is a working example handler" precedent) so most adopters copy something already crash-safe rather than writing their first handler from scratch. Do not add automatic handler supervision/retry — that's out of scope and out of Threadline's control per `:telemetry`'s design.

**Warning signs:** No test currently proves a raising handler doesn't break the emitting call site itself (should exist: attach a raising test handler, execute the event, assert the caller's own function still returns its normal value).

**Phase to address:** The telemetry phase. Acceptance check: one test per new event family that attaches a deliberately-raising handler and asserts (a) the caller's function still completes normally and (b) the raise is at least logged, matching `:telemetry`'s documented behavior.

---

### Pitfall 7: Cardinality explosion in telemetry metadata/measurements (StatsD/Prometheus footgun via table or actor labels)

**What goes wrong:** It's tempting to add `table: table_name` or `actor_id: id` to export/retention/query telemetry metadata "for debugging." If an adopter's handler forwards telemetry straight into a metrics backend with those fields as tags/labels (the default `Telemetry.Metrics` pattern), every distinct table name or actor id becomes a new metric series. For retention (runs per table) and query (potentially per-actor) events this is an unbounded-cardinality time series that can take down a Prometheus instance — a well-documented Oban/Broadway/Ecto telemetry mistake (Ecto's own telemetry docs explicitly warn against putting `:query` string or unbounded params into `Telemetry.Metrics` tags).

**Why it happens:** Table names feel "bounded" (a real schema has dozens, not millions, of tables) so it looks safe, but actor ids, correlation ids, or job ids are not bounded and are easy to add alongside table name without noticing the difference.

**How to avoid:** Metadata may include `table:` (bounded, schema-fixed cardinality) but must never include `actor_id`, `correlation_id`, `job_id`, row ids, or free-text reasons as metadata keys intended for tagging. If per-actor or per-correlation detail is genuinely needed, that's a query-API concern (`Threadline.Query`), not a telemetry-metadata concern — telemetry measurements/metadata should answer "how much/how long/success or failure," not "which specific row."

**Warning signs:** Any telemetry metadata key whose value space grows with the size of the audited dataset rather than the schema.

**Phase to address:** The telemetry phase. Acceptance check: telemetry moduledoc's documented metadata keys per event, reviewed once for cardinality the way health's `covered`/`uncovered` counts already model correctly.

---

### Pitfall 8: Double-emitting telemetry inside a DB transaction (event fires before commit is durable, or fires twice on retry)

**What goes wrong:** Threadline already has a real instance of this shape: `emit_action_recorded/1` fires unconditionally in `Threadline.record_action/2` regardless of whether the underlying write actually committed, and the moduledoc for `transaction_committed/2` explicitly warns callers to call it manually "after a known DB transaction commit" for accuracy — i.e. the library already knows naive placement is wrong. Retention and export are both candidates for the same mistake in the new events: if `[:threadline, :retention, :purged]` or `[:threadline, :export, :completed]` is emitted *inside* an `Ecto.Multi`/`Repo.transaction` block before the outer transaction actually commits, a handler that reacts to the event (e.g. sending a notification, incrementing an external counter) can act on a purge/export that later rolls back on a downstream step or an Oban retry — and if the surrounding code retries the whole operation (Oban jobs are famously idempotent-by-retry, not exactly-once), the event fires twice for one logical purge/export.

**Why it happens:** It's natural to call `:telemetry.execute` right where the "success" branch of the code is, which is often still inside the transaction function, especially in an `Ecto.Multi` step.

**How to avoid:** Emit retention/export/query/install telemetry **after** the enclosing `Repo.transaction`/`Multi.transaction` returns `{:ok, _}`, never from inside the transaction function itself, matching the lesson already encoded in `transaction_committed/2`'s docstring. For retention/export specifically (both can be Oban-job-driven per the domain model), make the emit idempotent-safe or at least clearly scoped to one attempt (emit with the job/run id in the *span*, not as a side effect inside retried business logic) so a retried Oban job doesn't double-count in a naively-summing dashboard.

**Warning signs:** Grep for `:telemetry.execute` calls that are lexically inside a `Repo.transaction(fn -> ... end)` block or an `Ecto.Multi.run/3` step body.

**Phase to address:** The telemetry phase, specifically the export and retention sub-items (both are transactional, multi-step operations, unlike the simpler health checks that already exist). Acceptance check: a test that makes the enclosing transaction fail/rollback after the business logic "succeeds" and asserts no telemetry event fired.

---

### Pitfall 9: `:telemetry.span/3` swallowing or mis-tagging exceptions on export/retention

**What goes wrong:** If the telemetry phase reaches for `:telemetry.span/3` (the idiomatic way to get paired `:start`/`:stop`/`:exception` events, which Oban, Broadway, and Ecto all use) for export or retention, a common mistake is wrapping only the "happy path" call and letting the `:exception` event's default metadata (kind, reason, stacktrace) be the *only* signal, while the function itself still needs to re-raise or return `{:error, reason}` through its normal contract. Two failure modes: (a) `:telemetry.span/3` re-raises by design, so if the surrounding mix task or context function was written to catch and convert exceptions to `{:error, _}` tuples, wrapping it in `span/3` changes the function's public contract from "returns error tuple" to "raises" — a **breaking API change** hiding inside what looks like an observability-only addition; (b) the stacktrace or exception message captured in `:exception` metadata can itself contain interpolated row data (Postgres errors sometimes echo the offending value), reintroducing Pitfall 5 through a different door.

**Why it happens:** `:telemetry.span/3`'s contract (call the function, let exceptions propagate, always emit `:stop` or `:exception`) is exactly right for functions that already raise-to-fail, but Threadline's public API style (per the domain reference and existing `Threadline.Query`/`Threadline.Health` functions) is `{:ok, _} | {:error, _}` tuples, not exceptions.

**How to avoid:** Do not use `:telemetry.span/3` around functions whose public contract is `{:ok, _} | {:error, reason}`. Instead, call `:telemetry.execute/3` explicitly on both branches (success and error) after computing the result, keeping the function's return contract unchanged. Reserve `span/3` only for genuinely exception-raising internal helpers, and scrub any stacktrace/exception metadata before including it (or omit stacktraces from telemetry metadata entirely — logs are the right place for those, not `:telemetry` metadata that adopters may forward to metrics backends).

**Warning signs:** A public function's `@spec` or moduledoc return shape changes from `{:ok, _} | {:error, _}` to unguarded after a telemetry change; a test that used to assert on an `{:error, reason}` tuple starts needing `assert_raise`.

**Phase to address:** The telemetry phase, and cross-checked by the v1.45 API-contract milestone (this is exactly the kind of "consistent return shapes" concern v1.45 is scoped to own — flag it now, fix contract drift there if any slips through).

---

### Pitfall 10: One-way telemetry event names and shapes (irreversible once an adopter attaches a handler)

**What goes wrong:** MILESTONE-GUIDE.txt §3 states plainly: "Hex versions cannot be unpublished. Treat every public default and API shape as one-way." Telemetry event names (`[:threadline, :export, :completed]`) and their measurement/metadata key sets are exactly this kind of one-way public surface — once an adopter's `:telemetry.attach/4` pattern-matches a metadata shape, renaming a key, changing a measurement from a count to something else, or restructuring nested metadata is a breaking change with no deprecation window (unlike a function call, there's no compiler warning for a stale telemetry pattern match; it just silently stops matching or crashes the handler on the next line).

**Why it happens:** Telemetry events feel like "just observability," lower-stakes than a public function signature, so less design care goes into naming/shape before shipping than into `Threadline.Query.history/3`'s signature.

**How to avoid:** Name new events consistently with the existing five (`[:threadline, <subsystem>, <past-tense-verb>]`, e.g. `[:threadline, :export, :completed]`, `[:threadline, :retention, :purged]`, `[:threadline, :query, :executed]`, `[:threadline, :install, :completed]`), following the established `expected_uncovered`-is-additive precedent (new measurement/metadata keys are additive-only; never repurpose or remove an existing key without a major-version deprecation path). Document each new event's measurements/metadata in `Threadline.Telemetry`'s moduledoc with the same rigor as the existing five, since that moduledoc is effectively the contract. Treat this milestone's telemetry additions as pre-1.0 (last chance to get shapes right before the v1.45 API-contract freeze) rather than "add now, fix later."

**Warning signs:** A telemetry event shipped in v1.44 needs a shape change during v1.45 — that's the signal this pitfall wasn't fully prevented; budget an explicit v1.45 telemetry-shape review line item as insurance regardless.

**Phase to address:** The telemetry phase, with an explicit note carried into the v1.45 API-contract milestone's scope (MILESTONE-GUIDE.txt already tracks a similar carry-forward pattern for the AuditTransaction<->AuditAction edge).

---

### Pitfall 11: `history/3` gaining a default limit changes today's callers' return shape before the v1.45 contract exists to govern it

**What goes wrong:** `Threadline.history/3` (delegating to `Threadline.Query.history/3`) currently has no limit — it's a "return everything" call. Adding a default limit (the milestone's explicit target) is a **behavior-breaking change disguised as a feature add**: any current adopter code relying on `history/3` returning the complete history (e.g. building a full audit report, or asserting `length(history) == n` in their own tests) silently gets truncated results with no compile error and no runtime error — it just returns fewer rows. This is precisely the kind of one-way default MILESTONE-GUIDE.txt §3 flags, and it's happening *before* v1.45's "consolidate overlapping entry points... consistent return shapes" work is scoped to formalize the contract, meaning it either needs its own careful versioning now or risks a second breaking change at v1.45 if the limit's shape (a plain list vs. a paginated/cursor-shaped return) doesn't match what v1.45 standardizes on.

**Why it happens:** A limit sounds like a safety/performance improvement (bounding an unbounded query), so it's easy to treat as a non-breaking hardening change rather than a return-shape change.

**How to avoid:**
- Ship the limit as an **opt-in default that changes behavior only when the caller doesn't already pass a limit-equivalent option**, and make the default generous enough not to silently truncate realistic current usage (pick the default empirically — check the retention/export property-test work in this same milestone for realistic row-count scale, and document the chosen number with rationale, not a round guess).
- Add a CHANGELOG entry with explicit "breaking behavior change" framing (not buried as a `feat:`), since Hex/release-please's automation won't know this `feat:` is semver-sensitive beyond the normal minor bump — this crosses into "silently changes existing callers' data" territory that deserves an explicit upgrade-guide note, the same way v1.42's PK-agnostic capture change got one.
- Decide now whether `history/3`'s return shape with a limit stays a plain list (truncated, caller has no way to know more exist) or gains a `has_more`/cursor signal — and make that decision compatible with (ideally literally reusing) the cursor-paging property-test work landing in the same milestone, so v1.45 doesn't have to reconcile two different pagination idioms.
- Add a test asserting the *old* unlimited-call shape (no limit passed) still returns a `list()`, not a tuple or map, unless the team explicitly decides to break that now (in which case it's a deliberate, documented decision, not an accident).

**Warning signs:** No upgrade-guide entry drafted alongside the `history/3` change; the default limit number has no cited rationale; existing tests that call `history/3` without a limit pass unchanged (which paradoxically is a *bad* sign if the fixture data happens to be smaller than the new default — the property tests for `as_of`/history should be the ones to catch a silent truncation, not the example-app smoke tests).

**Phase to address:** The `history/3` phase, explicitly. Acceptance check: upgrade-guide/CHANGELOG note discoverable before merge, plus a property test proving pages-joined-via-the-new-limit equals the full unlimited result for realistic sizes (ties into Pitfall 3's cursor-paging invariant).

---

### Pitfall 12: Cutting "guard tests" that are actually load-bearing CI-topology/CONTRIBUTING contracts

**What goes wrong:** The milestone explicitly targets "merge or cut guard tests that no longer catch a distinct failure class." Threadline's CI-topology contract tests (the ones binding CONTRIBUTING's job roster to `ci.yml`'s `needs:` list and the required aggregate, hardened across v1.43 phases 216/218/220/221) look, superficially, like exactly the kind of "restates the implementation" tautological test this milestone is hunting for — a test that just re-lists job ids the workflow file also lists. But per v1.43's own audit and RETROSPECTIVE.md, these are the tests that were **specifically hardened this cycle** against being vacuous (moved from regex-over-YAML to parsed YAML, given named `rule=` fragments, given mutation controls) precisely because they catch a real, previously-missed failure class: a job silently dropped from the required aggregate, or CONTRIBUTING drifting from the actual roster. Cutting them now, mid-rebalance, would erase v1.43's own investment and reopen exactly the gap 220/221 closed.

**Why it happens:** "Rebalance toward behavior, cut guard tests" is a blunt instruction; without cross-referencing which guard tests were *just* proven load-bearing by a mutation control, a rebalance pass can't tell a genuinely-dead guard test from a recently-hardened one that happens to look similar (both assert "list X equals list Y").

**How to avoid:** Before cutting or merging any guard test, check whether it has a documented mutation control (a "this fails when X breaks" proof) from a v1.42/v1.43 phase — if it does, it's provably load-bearing and out of scope for this rebalance; if it doesn't, that's the actual candidate list. Treat the CI-topology/CONTRIBUTING contract tests and the aggregate `needs:` binding as **explicitly out of scope** for this milestone's guard-test cut unless new evidence shows the mutation control itself was wrong. Cross-reference `.planning/milestones/v1.43-MILESTONE-AUDIT.md` tech_debt and `RETROSPECTIVE.md` "Patterns established" before finalizing the cut list.

**Warning signs:** A cut guard test's name or file matches anything referenced in v1.43's 220/221 phase summaries or the CI job roster; `mix ci.all`'s required aggregate composition changes as a side effect of a "test rebalance" commit.

**Phase to address:** The guard-test-rebalance phase. Acceptance check: the cut/merge list is reviewed against "does this test have a v1.42/v1.43 mutation control" before any deletion, and the CI-required aggregate's job count is diffed before/after the phase and must be unchanged unless explicitly decided otherwise.

---

### Pitfall 13: Converting serial tests to `async: true` breaks trigger-capture's real-commit dependency and the shared local PG connection limit

**What goes wrong:** Threadline's capture mechanism fundamentally requires committed transactions (triggers fire on real commits; `AuditTransaction`/`AuditChange` rows are only visible after commit, and multiple related properties in this very milestone depend on that). `Ecto.Adapters.SQL.Sandbox`'s normal `async: true` mode wraps each test in a rolled-back transaction — which is exactly incompatible with observing trigger-captured rows, and is presumably *why* the suite has none today. "Cutting the serial core" therefore cannot mean "flip `async: true` broadly" for capture-adjacent tests; it can only mean (a) genuinely converting pure/non-DB tests that were serial for no reason, or (b) adopting sandbox's *non-transactional* async mode (checkout with `sandbox: false` equivalent, or per-test schema/savepoint isolation) which trades rollback-safety for real concurrent connections — and that reintroduces the second hazard: the local dev Postgres's `too_many_connections` (already a known-environmental issue per memory, seen during v1.43 landing). Naively parallelizing DB-touching tests without also raising `pool_size`/`max_connections` or partitioning by schema will produce connection-pool exhaustion failures that look like flakes but are actually a capacity ceiling.

**Why it happens:** "Cut serial time" is a natural instinct to reach for `async: true`, and most Elixir/Ecto guidance defaults to recommending it without flagging that trigger-based audit capture is one of the documented exceptions (Carbonite's own docs note the audit-trigger-and-transaction coupling as a first-class design constraint, not an incidental one) where naive sandboxing breaks the thing under test.

**How to avoid:**
- Audit the ~91% serial figure by *cause*, not by blanket flag-flip: separate "serial because it does real trigger-capture and needs commit visibility" from "serial with no reason" (leftover default, copy-paste from an earlier serial test, or accidental shared global state like `Application.put_env` — see Pitfall 14).
- For genuinely capture-dependent tests, look at test-isolation strategies that don't require sandbox rollback: unique per-test schema or table-name suffixes so concurrent tests don't collide on the same rows, keeping `async: true` viable without needing rollback. This is more work than a flag flip and should be scoped as its own explicit sub-item, not assumed free.
- Before enabling more parallelism, check and if needed raise the local/CI Postgres `max_connections` and the test repo's `pool_size`, and re-derive whether the "shared local PG" `too_many_connections` issue (flagged as environmental in prior memory) recurs under the new concurrency — if so, that's now a real regression, not environmental noise, and needs a fix (e.g. a bounded pool_size cap in `config/test.exs`, or a CI-only higher `max_connections`).
- Re-measure suite wall-clock time after each conversion batch, the same measure-first discipline v1.43 used for CI economy, rather than assuming async conversion helps by construction.

**Warning signs:** New `too_many_connections` errors appear only after the async-conversion phase lands, on the same machine that was fine before; a converted "async" test starts asserting on `AuditChange` rows it didn't itself insert (cross-test pollution from real, uncommitted-by-sandbox concurrent writes).

**Phase to address:** The "cut the suite's serial core" phase, explicitly gated on first classifying the 91% by cause. Acceptance check: a before/after wall-clock measurement (matching 214's baseline-then-measure pattern) plus zero new `too_many_connections` occurrences across 10 consecutive local/CI runs.

---

### Pitfall 14: Global `Application.put_env`/module-attribute state races once tests parallelize

**What goes wrong:** `test/test_helper.exs` already uses `Application.put_env(:threadline, :default_test_excludes, exclude)` and the `Threadline.Test.NoticeGuard` attaches a *global* (VM-wide) notice listener with an `after_suite` verification callback. Any test that reads or mutates `Application.env` for `:threadline` config (e.g. a future telemetry-config toggle, a redaction column-list override used to test the property in different configs, or an `:invalid_config` health check candidate this milestone might include) is unsafe to run `async: true` if any other concurrent test also touches that same config key — classic global-mutable-state-under-parallelism, and Threadline already has at least one VM-global piece of test infrastructure (`NoticeGuard`) that assumes a single serialized pass.

**Why it happens:** Global app config is convenient for one-off test setup and works fine serially; the failure mode only appears once two tests touching the same key run concurrently, which won't happen until the async-conversion phase actually increases concurrency.

**How to avoid:** Before marking any test `async: true`, grep its body and any helper it calls for `Application.put_env`/`Application.get_env` on `:threadline` keys, and for anything that depends on `Threadline.Test.NoticeGuard`'s global listener state; keep those `async: false` or refactor them to pass config explicitly as function/opts arguments instead of through global app env (the more durable fix, and one that also makes the affected code more testable under property tests that vary config per run).

**Warning signs:** A newly-async test intermittently fails only when run alongside a specific other test file (order-dependent flake); `NoticeGuard`'s `after_suite` verification reports a truncated-identifier NOTICE that no single test's own migration should have produced.

**Phase to address:** The async-conversion phase, as a required pre-check before flipping any given test file. Acceptance check: `mix verify.flake` (already exists per prior memory) run specifically against the newly-async set before merge.

---

### Pitfall 15: `gen.triggers --down` orphaning the per-table capture function is a correctness bug with a security echo, not cosmetic

**What goes wrong:** The deferred v1.42 item states `gen.triggers`'s `down, all: true` after a per-table rerun "leaves a function behind." Given v1.42's central fix was collision-free *per-table* capture functions (replacing one shared function specifically because a shared function let one table's trigger run another table's redaction logic — a security fix, not just a naming one), an orphaned per-table function left behind by an incomplete `down` is a smaller instance of the same class of risk: a stale function that no longer has a corresponding trigger can still exist in the catalog, potentially get reattached by a future manual `CREATE TRIGGER`, or simply pollute `pg_proc` in a way that a future `gen.triggers` name-collision check (also from v1.42) doesn't expect to see. It's also an adopter-trust issue: `mix threadline.gen.triggers --down` is the documented rollback path, and rollback that doesn't fully roll back breaks the "correct by default" and "SQL-native, no opaque state" promises in CLAUDE.md's Key Design Constraints.

**Why it happens:** `down` migrations for generated trigger code are easy to write against the "normal" case (one table, one generate-then-later-remove cycle) and miss the "regenerate the same table's trigger, then remove all" sequence where an older function name/hash from the earlier generation is still on disk in `pg_proc` under a name the newest `down` logic doesn't know to look for (especially relevant given v1.42's hashed-suffix policy for long identifiers — a regenerated table can get a *different* hashed function name than the one first installed).

**How to avoid:** Reproduce exactly: generate triggers for a table, regenerate them (same table, e.g. after an `--except-columns` change), then run `down, all: true`, and assert via `pg_proc` (or `information_schema.routines`) that zero `threadline_capture_*` functions remain for that table — not just that triggers are gone. Add this as a migration-property or integration test (fits naturally next to the trigger-migration property test that already exists — `trigger_migration_property_test`). Fix likely needs `down` to enumerate functions by a stable naming prefix/schema query rather than by replaying only the specific names the current migration file's `up` believes it created.

**Warning signs:** `SELECT proname FROM pg_proc WHERE proname LIKE 'threadline_capture_%'` after a full `down, all: true` returns any rows.

**Phase to address:** The `gen.triggers` down-orphan phase. Acceptance check: the exact regenerate-then-down-all repro above, asserted against `pg_proc`, added to the existing trigger-migration property test family (naming it consistently, e.g. `trigger_migration_property_test.exs`) rather than as an isolated one-off unit test, since it's exactly the kind of invariant ("every trigger this library ever installed for a table is fully removable") property testing suits.

---

### Pitfall 16: Retention/backfill tasks writing to audit history undermines the "correct by default" and tamper-evidence claims

**What goes wrong:** This milestone's scope brushes against `mix threadline.gen.backfill` (deferred from v1.42, "included, reshaped or deferred on research" this cycle) and ships retention property tests (cutoff boundaries) alongside retention telemetry. The structural risk both share: any code path that **mutates already-captured `AuditChange`/`AuditTransaction` rows** (as opposed to inserting new ones, or deleting whole rows under a documented retention policy) breaks the implicit tamper-evidence/integrity claim the capture layer exists to make — an audit trail where historical entries can be silently edited (not just pruned) is not an audit trail. A backfill task in particular is dangerous here: "backfill" naturally suggests filling in *missing* audit history for rows that existed before Threadline was installed, which requires synthesizing `AuditChange`/`AuditTransaction` records for events Threadline never actually observed — records that are indistinguishable, once written, from real trigger-captured ones unless deliberately marked. PaperTrail and Logidze (both prior-art audit/versioning libraries) draw a hard line here: versioning writes are additive-only by construction (new version rows), and any "backfill" or "reconcile" tooling in that ecosystem is understood as fundamentally different in trust level from trigger-captured rows, usually requiring an explicit `synthetic: true`-style marker or living in a completely separate table.

**Why it happens:** "Backfill" is a familiar, low-drama word from ordinary data-migration work; it's easy to reach for the same mental model (write historical rows in) without registering that in *this specific domain*, writing plausible-looking historical audit rows is materially different from writing plausible-looking historical `orders` rows, because the whole point of `AuditChange` is "this is what the trigger actually saw."

**How to avoid:**
- If `gen.backfill` ships this milestone, any row it produces must be structurally distinguishable from trigger-captured rows — e.g. a `source: :backfill` (or similar) column/metadata value never set by the trigger path, and documentation stating plainly that backfilled rows are reconstructed, not observed, and should be excluded or clearly labeled in any export/report that claims completeness.
- Retention's cutoff/purge logic must only ever **delete whole rows** past a cutoff, never edit surviving rows' content; the retention property test (cutoff boundaries) should assert this explicitly — generate a dataset, run purge at a cutoff, and assert every *surviving* row is byte-identical to its pre-purge self (not just "still present"), which also catches an accidental `UPDATE` sneaking into what should be a pure `DELETE` path.
- If `gen.backfill` research this cycle concludes the honest answer is "defer again" (a legitimate outcome per MILESTONE-GUIDE.txt's "if nothing clears the bar, choose sustainment or stop"), that's preferable to shipping a backfill tool without this distinction solved.

**Warning signs:** A backfill-produced row has no way to tell it apart from a real capture; the retention purge property test only asserts row *counts* before/after, not surviving-row content equality.

**Phase to address:** Whichever phase resolves the deferred `gen.backfill` item, plus the retention property-test phase for the surviving-row-integrity assertion. Acceptance check: retention property test includes a content-equality check on survivors, and (if backfill ships) a test asserting backfilled rows carry a distinguishing marker absent from trigger-captured rows.

---

### Pitfall 17: CI exit-code or required-check changes silently breaking adopters' own pipelines that shell out to `mix`

**What goes wrong:** This milestone touches several CLI-adjacent surfaces that adopters' own CI could depend on: `history/3` gaining a limit (Pitfall 11, a runtime contract change, not a CI one, but adopters sometimes assert exit codes from scripts that call into Threadline's mix tasks), `mix threadline.gen.triggers` (the down-orphan fix changes its behavior), a possible `health --strict` mode (explicitly listed as a deferred candidate), and `:invalid_config` handling. If `health --strict` is added and adopters who already run `mix threadline.health` (non-strict) in their own CI pipelines see its *default* exit-code behavior change (e.g. warnings that previously exited 0 now exit non-zero because "strict" logic leaked into the default path, or vice versa a bug flips it), their pipelines go red or silently stop catching what they used to catch, with no compile-time signal — the mix-task equivalent of Pitfall 10's telemetry one-way-shape problem.

**Why it happens:** CLI exit codes are even less visible as "public API" than telemetry event shapes — there's no moduledoc convention forcing a documented contract, and it's easy for a `--strict` flag's implementation to accidentally share exit-code logic with the default path during refactor.

**How to avoid:** If `health --strict` ships, keep its exit-code contract strictly additive: the non-strict default's exit code for every existing condition must be provably unchanged (a targeted test comparing exit codes before/after for each health-finding severity, not just "the task runs"), and `--strict`'s new stricter behavior must be opt-in only, gated behind the explicit flag with no default-path bleed. Document exit codes per finding severity in the task's `@moduledoc`/`--help` output, the same way the telemetry moduledoc documents event shapes, since that's the artifact adopters actually read before wiring a CI step to it.

**Warning signs:** No existing test asserts specific exit codes per health-finding severity today (worth checking before assuming there is one); a `--strict` implementation shares a code path with the default rather than layering on top of it.

**Phase to address:** Whichever phase resolves `health --strict`/`:invalid_config` (explicitly still "on research" per PROJECT.md). Acceptance check: an exit-code-contract test matrix (severity x strict/non-strict) added alongside the feature, not just a happy-path CLI smoke test.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|--------------------|-----------------|------------------|
| Writing a property's expected value with the same sort/order logic as the code under test | Fast to write, passes immediately | Tautological — catches nothing (Pitfall 3) | Never |
| Leaving StreamData `max_runs` at the 100 default for DB-touching properties | No tuning effort | Suite wall-clock creep, fights this milestone's own async-cut goal (Pitfall 4) | Only for pure, non-DB properties |
| Flipping `async: true` on a test file without checking for trigger-capture or global `Application.env` dependence | Immediate parallelism | Flaky cross-test pollution, `too_many_connections` (Pitfalls 13, 14) | Never without the dependency check first |
| Adding telemetry metadata fields "for debugging" (raw query, actor id, reason text) | Richer local debugging today | PII/redaction leak, unbounded cardinality, one-way contract lock-in (Pitfalls 5, 7, 10) | Never in emitted metadata; put it in `Logger.debug` instead, which isn't a public contract |
| Backfill writing rows indistinguishable from trigger-captured ones | Simpler backfill implementation | Breaks tamper-evidence claim permanently for that dataset once shipped | Never, unless explicitly marked (Pitfall 16) |
| Cutting a guard test because it "looks tautological" without checking for a v1.43 mutation control | Faster rebalance | Reopens a gap 220/221 just closed (Pitfall 12) | Never without the cross-check |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Unbounded `history/3` before the limit ships | Slow queries on tables with long-lived rows and heavy update rates | The limit itself is the fix; see Pitfall 11 for how not to break it | Already breaking for any adopter with a hot row updated thousands of times |
| Property `max_runs` left at default against real DB writes | CI wall-clock grows every time a new property is added | Explicit small `max_runs` per DB-touching property (Pitfall 4) | As soon as 3-4 more properties land at default settings |
| Async conversion without raising `pool_size`/`max_connections` | `too_many_connections` under concurrency | Measure connection ceiling before enabling more parallel DB tests (Pitfall 13) | As soon as concurrency exceeds the pool size, which is exactly what this phase intends to increase |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Telemetry metadata carrying row values, actor identifiers, or raw SQL | PII/secret leak to any attached handler, including third-party APM/metrics forwarders | Allowlist metadata value types; counts/durations/atoms only (Pitfall 5) |
| `:telemetry.span/3` exception metadata echoing a Postgres error that contains a literal offending value | Same leak, via stacktrace/exception metadata instead of the happy path | Don't use `span/3` for tuple-returning functions; scrub exception metadata (Pitfall 9) |
| Backfilled audit rows indistinguishable from real capture | An attacker (or a careless script) could insert synthetic "history" that reads as authoritative | Mark backfilled rows distinctly; never let backfill silently pass as capture (Pitfall 16) |
| Orphaned per-table capture function left by an incomplete `down` | Residual trigger-adjacent function in `pg_proc`, echoing the v1.42 collision class of bug | Verify against `pg_proc`, not just trigger listings, after `down` (Pitfall 15) |

## "Looks Done But Isn't" Checklist

- [ ] **Property tests exist and pass:** Often missing a mutation control proving they'd fail on a real regression — verify by temporarily breaking the invariant in a throwaway commit and confirming red (Pitfall 3).
- [ ] **Telemetry events for export/retention/query/install:** Often missing a raising-handler test and a PII-allowlist check on metadata — verify both exist per event (Pitfalls 5, 6).
- [ ] **`history/3` limit shipped:** Often missing an upgrade-guide/CHANGELOG note and a truncation-detecting test against realistic fixture sizes — verify the note exists and the old no-limit call path is deliberately tested (Pitfall 11).
- [ ] **Guard-test rebalance done:** Often accidentally includes CI-topology/CONTRIBUTING contract tests that have a v1.43 mutation control — verify the cut list was cross-checked against `.planning/milestones/v1.43-MILESTONE-AUDIT.md` (Pitfall 12).
- [ ] **Serial-core cut / async conversion:** Often missing a wall-clock before/after measurement and a `too_many_connections` regression check across repeated runs — verify both (Pitfall 13).
- [ ] **`gen.triggers` down-orphan fix:** Often verified only by "trigger is gone," not by "function is gone from `pg_proc`" — verify with a direct `pg_proc` query, not just the trigger listing (Pitfall 15).
- [ ] **Bench ExUnitProperties compile fix:** Often fixed locally without a CI job actually exercising the bench project's compile step going forward — verify the fix is proven by a job that would have caught the original break, not just a one-time local `mix compile` run.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|----------------|-----------------|
| Tautological property shipped and later found | LOW | Rewrite the expected-value computation with an independent method; add the mutation control retroactively; no data-shape change needed |
| Telemetry event shape needs to change post-release | HIGH | Requires an additive-only new event or a documented deprecation window at v1.45; cannot silently rename/remove a key once adopters may have attached handlers |
| `history/3` default limit found to be wrong (too low/high) post-release | MEDIUM | Ship a follow-up `fix:`/`feat:` adjusting the default with a CHANGELOG note; still a behavior change for callers relying on the old default, so treat with the same care as the original change |
| Async conversion caused `too_many_connections` in CI/shared local PG | LOW-MEDIUM | Revert the specific file(s) to `async: false`, or cap `pool_size`; re-measure before re-attempting |
| Backfilled rows shipped without a distinguishing marker | HIGH | Requires a follow-up migration to retroactively tag or separate backfilled rows from captured ones, and a public erratum since any exports/reports already taken are now known-tainted for that window |
| Guard test cut that was load-bearing (CI topology gap reopens) | MEDIUM | Restore the specific test/mutation control from git history; re-verify against the same repro that originally proved it load-bearing |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-------------------|---------------|
| 1. Shrinking against a live shared DB | Property-test phase | 20x local repeat run green; `async: false` unless proven pure |
| 2. Tie generators that don't match the real tiebreak | Cursor/history property-test phase | Mutation control: flip `desc, desc` to `desc, asc`, confirm red |
| 3. Tautological properties | Every property-test phase | Mutation control cited per property in VERIFICATION.md |
| 4. Property runtime creep | Property-test phase + serial-core-cut phase, sequenced together | Suite wall-clock measured before/after both phases |
| 5. PII in telemetry metadata | Telemetry phase | Metadata-type allowlist test; redaction property test also asserts on telemetry |
| 6. Handler crash silently detaches | Telemetry phase | Raising-handler test per new event family |
| 7. Cardinality explosion | Telemetry phase | Documented metadata keys reviewed for boundedness |
| 8. Double-emit inside transaction | Telemetry phase (export/retention) | Rollback test: no event fires if enclosing transaction fails |
| 9. `span/3` breaking tuple-return contracts | Telemetry phase | Return-shape test unchanged after telemetry added |
| 10. One-way event names/shapes | Telemetry phase, carried into v1.45 | Moduledoc documents every event; v1.45 scope note added |
| 11. `history/3` limit breaking return shape/behavior | `history/3` phase | Upgrade-guide note + truncation-detecting property test |
| 12. Cutting load-bearing guard tests | Guard-test-rebalance phase | Cut list cross-checked against v1.43 mutation controls; required-aggregate job count diffed |
| 13. Async conversion vs. trigger-capture/connections | Serial-core-cut phase | Wall-clock + zero new `too_many_connections` over 10 runs |
| 14. Global config state races under async | Serial-core-cut phase | `mix verify.flake` run against newly-async set |
| 15. `gen.triggers` down orphan | `gen.triggers` down-orphan phase | Direct `pg_proc` query after regenerate-then-down-all repro |
| 16. Backfill/retention mutating audit history | `gen.backfill` resolution phase + retention property-test phase | Survivor content-equality test; backfill marker test if shipped |
| 17. CI/CLI exit-code contract breaks | `health --strict`/`:invalid_config` phase | Exit-code matrix test (severity x strict/non-strict) |

## Sources

- Repo-grounded (HIGH confidence): `.planning/PROJECT.md`, `.planning/MILESTONE-GUIDE.txt`, `.planning/RETROSPECTIVE.md` (v1.41–v1.43 sections), `.planning/milestones/v1.43-MILESTONE-AUDIT.md`, `CLAUDE.md`, `lib/threadline/telemetry.ex`, `lib/threadline/query/cursors.ex`, `lib/threadline.ex`, `lib/threadline/query.ex`, `lib/mix/tasks/threadline.gen.triggers.ex`, `test/test_helper.exs`, repo `grep` for `async: false` / `Ecto.Adapters.SQL.Sandbox` usage (56 files serial, no sandbox found).
- [StreamData / property-based testing with Ecto — Elixir Forum: "Property-based testing slow when hitting the database"](https://elixirforum.com/t/property-based-testing-slow-when-hitting-the-database/58666)
- [stream_data — GitHub (whatyouhide/stream_data)](https://github.com/whatyouhide/stream_data)
- [8 Common Causes of Flaky Tests in Elixir — AppSignal blog](https://blog.appsignal.com/2021/12/21/eight-common-causes-of-flaky-tests-in-elixir.html)
- [Carbonite — Audit trails for Elixir/PostgreSQL based on triggers (GitHub, bitcrowd/carbonite)](https://github.com/bitcrowd/carbonite)
- [Carbonite API reference / README (hexdocs.pm/carbonite)](https://hexdocs.pm/carbonite/api-reference.html)
- MEDIUM confidence, from general ecosystem knowledge (not independently re-fetched this session): `:telemetry`'s documented handler-crash-detaches behavior; Oban's telemetry/`args`-in-metadata PII guidance and Oban Web scrubbing; Ecto's `Telemetry.Metrics` tag-cardinality guidance against unbounded `:query`/param tags; PaperTrail/Logidze's additive-only versioning-row design as prior art for audit-trail mutation discipline; Hypothesis/QuickCheck's well-known "model equals implementation" tautological-property anti-pattern.

---
*Pitfalls research for: Threadline v1.44 Behavioral Depth (Properties, Twins, Telemetry)*
*Researched: 2026-09-30*
