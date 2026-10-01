# Phase 226: Pure Property Tests and Run Budget - Context

**Gathered:** 2026-10-01
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers four `async: true` StreamData properties. A reviewer can trust each one, and their run time is bounded and can be tuned.

- **PROP-01:** timeline and actor-history cursor paging over tie-heavy lists
- **PROP-02:** the ChangeDiff INSERT/UPDATE/DELETE × before_values matrix
- **PROP-03:** redaction-policy validation
- **PROP-05:** export CSV/JSON round-trip

**PROP-08:** one `THREADLINE_PROPERTY_SCALE` setting multiplies runs on the weekly Flake Detection lane, and a test pins that wiring.

VERIFICATION.md records:
- a mutation control, with its failing seed, for each property
- the suite wall clock before and after

The properties expose some real defects. Two small fixes are in scope (D-17, D-18), because a property that finds a bug turns that bug into a fixed regression test. DB-backed properties belong to phase 227.

</domain>

<decisions>
## Implementation Decisions

### Cursor paging (PROP-01): a pure property plus DB example tests that pin its model to the real SQL
- **D-01:** **Move the post-fetch page assembly into `Threadline.Query.Cursors`.**
  - Today `lib/threadline/query.ex` (about lines 547-559) trims the page, works out `has_next?`/`has_prev?` and builds next/prev cursors.
  - Move that into one `Cursors` function, for example `actor_history_page(raw, limit, reverse?, after_cursor)` returning entries, next and prev. `query.ex` calls it.
  - The timeline/row-history paths get the same treatment if they have equivalent glue.
  - This is a behaviour-preserving refactor. The existing `query_test.exs` tests at ~L470/L506/L795/L819 guard it.
  - Why: without the move, the property would test a copy of the glue written in the test, not the code the product runs.
  - Do not extract a shared comparator or ordering constant that both the SQL and the in-memory model read. If both sides read it, flipping it changes both, so the SQL mutation control could never go red.
  - **Reversibility:** reversible. Internal `@moduledoc false` module.
- **D-02:** **Generator `Threadline.Test.CursorGenerators`** in `test/support/cursor_generators.ex`. Its moduledoc names the bias: "timestamp tie groups interleaved with singletons".
  - **Entries:** 0..60 maps `%{ts_usec: integer, id: uuid_string}`, built as a list of tie groups. Group size comes from `frequency([{5, constant(1)}, {3, integer(2..4)}, {2, integer(5..12)}])`, so about 60-70% of entries share a timestamp with a neighbour.
  - **Timestamps:** group timestamps are distinct, and are often 1 µs apart to cover the off-by-one-µs boundary.
  - **Ids:** `binary(length: 16) |> map(&Ecto.UUID.load!/1)`.
  - **Page size:** `integer(1..8)`, weighted toward 1-3 so page cuts land inside tie groups. Sizes equal to n and larger than n must also occur.
  - Convert to `DateTime` only inside the property body.
- **D-03:** **The in-memory model and the expected order use different keys.**
  - **Model:** the test-written stand-in for the SQL keyset filter and ORDER BY compares `{usec_integer, lowercase_uuid_string}` tuples.
  - **Expected order:** `Enum.sort_by(entries, &{&1.ts_usec, Ecto.UUID.dump!(&1.id)}, :desc)`. This is raw 16-byte keys, which is Postgres's `uuid` byte order.
  - Never compare `%DateTime{}` structs with `<`, `>` or `sort`.
- **D-04:** **Assertions.** Each has a named failure message.
  1. The concatenated page ids equal the expected order.
  2. Set equality with the input.
  3. No duplicates.
  4. **Actor history:** walking `before:` back from the last page reproduces every forward page.
  5. **Timeline:** at most one empty trailing page, and only when `n > 0 and rem(n, k) == 0`. This is real current behaviour, because `timeline_page` fetches `page_size` rows, not `limit+1`. Do not write a naive page-count assertion.
  6. The page walker is bounded with `reduce_while` at `n + 2` steps and fails with "cursor did not advance", so a broken cursor fails instead of hanging the suite.
- **D-05:** **New DB example test** in the `actor_history/2 — QUERY-02` describe of `test/threadline/query_test.exs`: "pages across occurred_at ties forward and backward without duplicates or skips".
  - **Fixture:** one unique actor (`System.unique_integer([:positive])`) and 7 transactions with fixed explicit `occurred_at` µs timestamps, in tie groups of 3/1/3. Use no wall-clock time.
  - **Walk:** `limit: 2` forward to exhaustion with `after:`, then back with `before:`.
  - **Assert:** the ids equal both the independent expected order and the pure model's output on the same fixture. The second check is what ties the model to the real SQL.
  - The existing timeline tie test (`query_test.exs:819`) gains the same model-agreement assertion.
- **D-06:** **Two cursor mutation controls.**
  1. Break the reverse trim in `Cursors` (keep the wrong end). The property must go red.
  2. Flip the id tie-break to `asc`, both in `actor_history_window` and at the timeline `desc: ac.id` (`query.ex` ~L360). The property stays green, which is expected, and the DB agreement tests go red.

  VERIFICATION.md records both and uses this wording for the coverage boundary: "PROP-01 is a pure property over the real `Cursors` slicing/cursor code against an in-memory model of the keyset SQL; the SQL ordering and predicate are pinned by DB example tests that compare real query output to the same model on fixed tie-heavy fixtures."

### Run budget (PROP-08): one setting, read at runtime
- **D-07:** **Helper `Threadline.Test.PropertyRuns`** in `test/support/property_runs.ex`.
  - `@env_var "THREADLINE_PROPERTY_SCALE"`, exposed as `env_var/0`.
  - Pure `parse_scale(nil | binary)`: nil gives 1. Only the integers 1..10 are accepted. `""`, `"0"`, `"-1"`, `"5x"`, `"5.0"` and `"11"` all raise `ArgumentError` naming the variable and the range.
  - `scale/0` reads the environment **at runtime**. Never read it into a module attribute: `test/support` is compiled, so the value would be frozen at compile time.
  - `pure(base) = base * scale()` and `db(base) = base * min(scale(), 3)`. Both guard `base` to 1..200. The moduledoc records two rules: pure properties use base 150-200, and DB properties use base ≤ 20.
  - Use one variable, not two. The DB cap is a code decision, not something to tune per run.
- **D-08:** **Fail fast and show the scale.** `test/test_helper.exs` calls `PropertyRuns.scale()` once after `ExUnit.start()`, so an invalid value aborts before any test runs. When the scale is not 1 it prints one line, e.g. `THREADLINE_PROPERTY_SCALE=5: pure max_runs x5, DB x3`.
  - Before committing, confirm that `bin/classify-flake-run` still classifies a log containing that line. Its contract tests parse the log's shape.
- **D-09:** **Workflow:** add `env: THREADLINE_PROPERTY_SCALE: "5"` on the `id: repeat` step of `.github/workflows/flake-detection.yml`, with a one-line comment pointing at the contract test.
  - The scale applies inside all 12 iterations, each with a fresh seed.
  - `ci.yml` never sets it.
  - Use explicit `max_runs:` only. No `max_run_time`, because a time limit makes the same seed reproduce different cases on fast and slow machines. Leave `max_shrinking_steps` at its default. Seeds stay ExUnit-derived, so `mix test --seed N` replays.
  - `config :stream_data, max_runs:` is rejected: an explicit per-call `max_runs:` overrides it.
- **D-10:** **Existing property files move to the helper.**
  - `naming_property_test.exs`, which today relies on StreamData's implicit default of 100 → `PropertyRuns.pure(200)`.
  - `trigger_migration_property_test.exs` → `pure(200)`. This drops it from 300 per PR, but the weekly lane runs 1000.
  - `trigger_rerun_property_test.exs` `@max_runs 20` → `PropertyRuns.db(20)`.
- **D-11:** **Pinning test:** `test/threadline/property_scale_contract_test.exs`, `async: true`. Never call `System.put_env`. It covers:
  - (a) unit tests of `parse_scale/1`, `pure/1` and `db/1` at scales 1 and 5 (200→1000, 20→60);
  - (b) the workflow YAML, parsed rather than matched by regex: the step whose `run` contains `mix verify.flake` has the variable set to `"5"`, and no `ci.yml` job or step sets it;
  - (c) a source scan: every `check all(` in `test/**/*_property_test.exs` uses `PropertyRuns.pure(`/`.db(`, possibly through an `@max_runs` attribute;
  - (d) CONTRIBUTING.md names the variable.
  - **Mutation controls:** misspelled key, moved to the compile step, set to `"1"`, deleted, and fixture sources with `max_runs: 300` and with no `max_runs`. Each must produce violations, and each asserts that the mutated input really differs from the original (the Test 6 pattern).
- **D-12:** **Budget re-derivation (225 D-11 rule).**
  - Dispatch Flake Detection on the phase head with the scale set, and cite the run id.
  - Update `flake_classifier_contract_test.exs` Test 6 (`@cold_first_run_ceiling_s`, `@repeat_ceiling_s`, the cited run id), and the workflow budget comment, which states the ceilings were measured at scale 5.
  - If 1 + 11 repeats no longer fit in 2,970 s, first drop the repeat count (Test 6 recomputes it). If that is not acceptable, fall back to a separate one-shot `mix test --only property` step. StreamData already registers the `:property` tag. That step needs its own log and classification.
  - Do not raise the 55-minute budget.
  - This dispatch needs a maintainer grant that names it.
- **D-13:** **CONTRIBUTING.md "Deterministic tests"** gains:
  - `THREADLINE_PROPERTY_SCALE=5 mix test <file>` and `mix test --only property`;
  - the allowed range 1..10;
  - the rule "pure ×scale, DB ×min(scale, 3)";
  - how to replay a failure with `--seed`.

### Independent expected results (PROP-02, PROP-03, PROP-05): generate the truth first
- **D-14:** **ChangeDiff (PROP-02): the expected output is built from generated facts.**
  - **Generator.** `Threadline.Test.ChangeFactGenerators` (`test/support/change_fact_generators.ex`) generates the ground truth first: op, before_values mode, key shape, and per-field facts `%{name, after, prior: :absent | {:present, v}}`. It then builds the `%AuditChange{}` from those facts.
  - **Biases:**
    - `{:present, nil}` about a third of the time (JSON null vs absent);
    - `changed_fields` names often missing from `data_after`;
    - op in both cases (`"update"`/`"UPDATE"`);
    - all-string vs all-atom key maps (mixed keys only if the oracle states the precedence);
    - `changed_from` as `nil`, `%{}` or a partial map;
    - `changed_fields` unique;
    - size-independent (`member_of`/`frequency`), so every matrix cell appears within 150 runs.
  - **Oracle:** `expected(fact)` is derived from the facts without the implementation's lookups and compared with a single `===`.
  - **Structural properties:** sorted names; UPDATE names equal `changed_fields`; `"none"` means no `before`/`prior_state` keys; `"sparse"` means exactly one of the two; DELETE gives `[]` and nil.
  - **Metamorphic properties:** atom keys equal string keys; shuffling `changed_fields` changes nothing; extra `data_after` columns outside `changed_fields` change nothing on UPDATE.
  - **`:expand_insert_fields`:** one property checking that INSERT gives `"kind" => "set"` rows for exactly the keys in `data_after`.
  - **Mutation control:** `map_has_field?(cf, name)` → `map_get(cf, name) != nil` in `build_update_field/4`. This turns a captured JSON null into "omitted", the bug a compliance reviewer would care about most.
- **D-15:** **Redaction policy (PROP-03): every input is built with a known label.**
  - **Generator.** `Threadline.Test.RedactionPolicyGenerators` builds valid policies by construction:
    - disjoint name pools;
    - whitespace padding, atom and string forms, and blank entries;
    - list or map options, with atom or string keys;
    - the default placeholder or a valid one.
  - **Invalid policies** each carry exactly one tagged defect: `:overlap` (often written differently on each side, e.g. `" ssn "` vs `:ssn`, at least half the time), `:empty_placeholder`, `:too_long` or `:control_char`.
  - **Placeholder ladder,** drawn with `member_of`: exactly 200 and 201 graphemes, in ASCII and multibyte forms, plus combining marks and each byte 0..31.
  - **Assertions:** valid inputs give `:ok`. Invalid inputs raise `ArgumentError` with a message matching their tag (the overlap message names "exclude", "mask" and the column).
  - **Mutation control:** remove `String.trim/1` from `normalize_columns/1`.
  - **Second control:** `>` → `>=` on the length check, caught by the exact-200 rung.
- **D-16:** **Export (PROP-05): independent decoders, expected value = the input after one named normalisation.**
  - **Entry point:** the public `Threadline.Export.format_changes_iodata/3` with `:csv`, `:json_wrapped` and `:ndjson`, with and without `include_action_metadata`.
  - **CSV decoder:** a hand-written strict RFC 4180 decoder in `test/support/strict_rfc4180.ex`, about 40 lines. It handles quoted fields with `""` and CRLF records, and rejects a bare CR/LF or a stray quote inside an unquoted field. It accepts tabs and any non-ASCII. It gets its own RFC example tests.
    - NimbleCSV is not used to decode, because decoding with the encoder's own library hides its quirks.
    - Parse `csv_header() <> body`, assert the header once against a hand-typed column list, and `Jason.decode!` the JSON columns.
  - **JSON decoder:** `Jason.decode!`. The risk under test is Export's mapping, not Jason itself.
  - **Normalisation:** one named, commented function.
    - atom keys become strings;
    - non-boolean, non-nil atom values become strings;
    - ids go through `to_string`;
    - DateTimes are generated at µs precision and compared after `DateTime.from_iso8601`;
    - plus the documented defaults in D-19.
  - **Comparisons use `===`,** so integer vs float is caught. `-0.0` is only distinct on OTP ≥ 27; the min lane is OTP 26.
  - **Generators:**
    - Main values are JSON-domain: string keys; nil, bool, bignum, float, binary, list, map.
    - `Threadline.Test.ExportHostileValueGenerators` adds commas, `"`, CRLF, lone LF, lone CR, leading `= + - @`, astral and combining Unicode, `""`, `"[REDACTED]"`, `1.0e300`, `5.0e-324`, `2.0`, `-0.0`, and `.000000` µs.
    - Row maps come from ChangeFactGenerators with the `tx_*` fields, an ActorRef or nil, and `aa_id` present or absent.
  - **Cross-format agreement property:** decoded `:json_wrapped` without `"transaction"`/`"action"` `===` `ChangeDiff.from_audit_change(.., format: :export_compat)` passed through Jason, for one fact projected both ways. This catches drift between the two modules. It is not PROP-02's oracle.
  - **Mutation controls:** truncate `datetime_iso/1` to `:second`, and replace the RFC4180 dump with a naive `Enum.join(",") <> "\r\n"`.

### Defects the properties expose (maintainer-approved 2026-10-01)
- **D-17:** **Fix the bare CR in CSV export (`fix:` commit).**
  - NimbleCSV leaves a lone `\r` unquoted. Excel and Python's `csv` read that as a line break, so a row can split.
  - Export must quote any field containing `\r`. The planner picks the mechanism, for example a custom `NimbleCSV.define` or field pre-quoting.
  - Add the minimal counterexample as a fixed regression example test.
  - Only quoting is added, so RFC-compliant readers are unaffected.
  - **Reversibility:** reversible.
- **D-18:** **Make redaction-policy validation fail loudly (`fix:` commits, with a CHANGELOG upgrade note).**
  - A non-list `exclude:`/`mask:` (e.g. `exclude: :ssn`) currently becomes `[]` without warning, so the column is silently not redacted. It must raise `ArgumentError` with a message saying a list is expected.
  - A non-binary placeholder currently raises `FunctionClauseError`. It must raise `ArgumentError`.
  - Keep the 200-character limit counted in graphemes (`String.length/1`), and correct any doc or moduledoc wording that says bytes.
  - DEL (127) and C1 bytes stay accepted, with a code comment explaining why.
  - `mask_placeholder: false/nil` keeps falling back to the default. When both `:exclude` and `"exclude"` are given, the atom key still wins. Both behaviours get example tests.
  - **Reversibility:** costly. Configs that pass today would start raising. They are configs that already fail to redact, which is the justification, and the upgrade note names the change.
- **D-19:** **Export's nil defaults are documented and pinned, not changed, in 226.**
  - Both formats turn a nil `changed_from` into `{}`, which loses the "none" signal. CSV also turns `data_after: nil` into `"{}"` (JSON keeps `null`), and `include_action_metadata` turns a nil correlation/action id into `""`.
  - Model these in one named `export_defaults/1` normalisation step, with an assertion pinning each one.
  - Changing them is an export-contract change that belongs in v1.45 (see Deferred).

### Mutation evidence, generator coverage and timing
- **D-20:** **Re-runnable mutation controls.**
  - Patches live in `.planning/phases/226-pure-property-tests-and-run-budget/tools/mutations/{cursor,cursor_sql,change_diff,redaction_policy,export}.patch` and touch only `lib/`.
  - Each mutant is wrong only in the case its generator is biased toward, so a kill also proves the generator reaches that case.
  - Runner: `tools/mutation-control.sh <patch> <test_file> [K=5]`. It:
    1. refuses to start unless `git diff --quiet -- lib` passes;
    2. runs `git apply --check`, applies the patch, and reverts it through a `trap`;
    3. runs the file under seeds 1..K and requires red on K of K, capturing the seed, the "after N successful runs" count and the shrunk value;
    4. re-runs the first seed and requires the same counterexample;
    5. reverts, requires green, and asserts `git diff --quiet -- lib`;
    6. prints a markdown evidence block.

    For `cursor_sql.patch`, the expectation is inverted: property green, DB agreement tests red.
  - A generator counts as weak if any seed survives or the median N exceeds `max_runs / 2`.
  - Phase 227 reuses the script.
  - EVIDENCE.md (cited from VERIFICATION.md) records, per property: the invariant in English, the diff, the red excerpt with seed and shrunk value, the K/K kill rate, the green-after-restore line and the command.
  - Scrub absolute paths before committing (repo-hygiene guard).
- **D-21:** **Executor halt clause.** Executors may never commit a mutated `lib/`. During a mutation control they may not edit anything except the patch target, and they may not bypass hooks or move protected files. If a precondition blocks them, they stop and report.
- **D-22:** **Generator coverage test:** `test/threadline/property_generator_coverage_test.exs`, `async: true`.
  - StreamData has no `classify`/`cover`, so the test samples each generator with `StreamData.seeded(gen, <fixed seed>) |> Enum.take(1000)` and asserts floors set well below the expected rates:
    - at least 25% of tie lists contain a duplicate timestamp, and some contain at least 3 equal ones;
    - every ChangeDiff op × before_values cell has at least 1 sample;
    - every redaction defect tag has at least 1 sample, and valid samples make up at least 30%;
    - export values include quote, comma, CR, LF, Unicode and nil.
  - Every floor assertion names the bias it protects.
- **D-23:** **Wall clock (SC5).**
  1. **Primary:** the new files' own cost, via `mix test <files> --slowest-modules N`, median of 5 after one warm-up, at scale 1 and at `THREADLINE_PROPERTY_SCALE=5`.
  2. **Context:** local whole-suite `mix test`, median of 3, at the phase head vs the phase-226 base commit. Build the base in a detached `git worktree` and remove it afterwards. Label the figure "local, noisy" and restate the ±50 s noise floor measured in 224.
  3. **CI:** `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py --compare <pre-226 run> <post-226 run>` per lane, using the `Run tests` step. Record it as pending, with the exact commands, if there is no push grant.
  - Evidence docs must pass `225/tools/check-citations.py`.
- **D-24:** **Partition weights stay untouched.** The new files take the median weight (23 ms) at ¼ for async files. Append a measured line only for a file whose solo cost exceeds 2 s. The full `--write-weights` refresh is phase 230's job.

### Claude's Discretion
- File names and `describe` layout of the four property test files. Mirror `test/threadline/capture/naming_property_test.exs`, e.g. `test/threadline/query/cursors_property_test.exs` and `test/threadline/change_diff_property_test.exs`.
- The exact refactor shape in D-01, as long as no logic is duplicated and the existing tests pass unchanged.
- Plan and wave split. The pure property files are independent of each other once D-07 lands.
- The mechanism for the D-17 CSV fix.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` (Phase 226 and 227 sections) — success criteria SC1-SC5, and why 226 comes before 227
- `.planning/REQUIREMENTS.md` (PROP-01, 02, 03, 05, 08) — requirement text
- `.planning/MILESTONE-GUIDE.txt` — quality bar (no tautological tests)

### Research
- `.planning/research/STACK.md` §1.1, §1.3, §1.4, §1.6 — per-target invariants
- `.planning/research/STACK.md` §3 — `max_runs` tiers and the scale mechanism
- `.planning/research/PITFALLS.md` Pitfalls 1-3 — shared DB without a sandbox, tie generators that don't match the real tie-break, tautological oracles

### Prior-phase decisions this phase builds on
- `.planning/phases/225-suite-baseline-and-partitioned-ci/225-CONTEXT.md`
  - D-08: local default stays whole and unpartitioned
  - D-11: Flake Detection sizing is re-derived from a cited run
  - D-03a: partition weights
- `.planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md` — format of the SUITE-06 before/after report
- `.planning/phases/225-suite-baseline-and-partitioned-ci/tools/ci-job-timing.py`, `tools/check-citations.py` — reused tools
- `.planning/phases/224-capture-and-bench-fixes/224-EVIDENCE.md` — mutation-control evidence shape ("CAPT-02 mutation controls")

### Project quality bar
- `prompts/threadline-elixir-oss-dna.md` — honest default tests, named entrypoints, contract tests with mutation controls
- `CLAUDE.md` — three-layer architecture, domain language, verification conventions
- `.planning/PROJECT.md` Constraints — zero human verification by default

### External
- StreamData 1.4.0, `deps/stream_data/lib/ex_unit_properties.ex` — L240 `:property` tag, L456-465 app-config doc, L554-558 precedence of per-call `max_runs`
- RFC 4180 — the contract the strict CSV decoder (D-16) encodes
- John Hughes, "How to Specify It!" — model, postcondition and metamorphic oracle patterns (D-14)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `test/support/naming_generators.ex`, `test/support/trigger_run_generators.ex` — conventions for generator modules: named for their domain, bias stated in the moduledoc, `use ExUnitProperties`.
- `test/threadline/capture/naming_property_test.exs` — shape of a pure `async: true` property file.
- `test/threadline/ci_topology_contract_test.exs` (~L130-185, L351+) — the `mutation_controls` list pattern.
- `test/threadline/flake_classifier_contract_test.exs` Test 6 (~L749-848) — `sizing_violations/4` and the sizing-mutation control, to update in D-12.
- `bin/ci-test-partitions` (L23-25) — async ¼ weighting and the median fallback.
- `Threadline.Export.format_changes_iodata/3` and `csv_header/1` — public round-trip entry points. `csv_row/2` and `change_map/1` are private.

### Established Patterns
- No SQL Sandbox anywhere: triggers need committed rows. DB tests use unique keys per test, not rollback.
- Contract tests parse YAML rather than matching it with regex, and carry mutation controls that assert the mutated input differs from the original.
- Local `mix test` is the whole suite. CI partitions with N=4.
- Pure properties are `async: true` and never touch `Threadline.Test.Repo`.

### Integration Points
- `lib/threadline/query/cursors.ex` and `lib/threadline/query.ex` (L81-101, L309-335, L359-360, L531-559, L727-742) — D-01 refactor and D-06 mutation targets.
- `lib/threadline/change_diff.ex` (`build_update_field/4`, the `Enum.sort` calls) — D-14 mutation target.
- `lib/threadline/capture/redaction_policy.ex` (`validate!/1`, `validate_placeholder!/1`, `normalize_columns/1`) — D-15 mutation target and D-18 fixes.
- `lib/threadline/export.ex` (`csv_row` ~L387, `change_map` ~L419, `dump_csv_to_iodata` ~L277, `datetime_iso`) — D-16 mutation targets and the D-17 fix.
- `test/test_helper.exs` — D-08 fail-fast scale check.
- `.github/workflows/flake-detection.yml`, `repeat` step — D-09 env.
- `CONTRIBUTING.md` "Deterministic tests" (~L229-245) — D-13.

</code_context>

<specifics>
## Specific Ideas

- Verified findings from research probes (Elixir 1.17 / OTP 27, NimbleCSV 1.3.0):
  - `dump([["a\rb","x"]])` gives `"a\rb,x\r\n"` with the `\r` unquoted;
  - `%{a: 1} == %{a: 1.0}` is true, so lossless checks must use `===`;
  - the placeholder limit is `String.length/1`, which counts graphemes.
- When a property finds a real bug, add the minimal failing input as a fixed example test. Don't rely on the property re-finding it.
- The default `mix test` stays honest: scale 1, nothing excluded.

</specifics>

<deferred>
## Deferred Ideas

- **v1.45 API-contract milestone:** export's nil → `{}` defaults (D-19) lose the "no before-values stored" signal that ChangeDiff reports as `"none"`. Decide whether export should keep `null`. This is a public export-shape change.
- **Backlog / v1.45:** CSV formula injection. Leading `= + - @` values pass through export unescaped. This is a security-hardening scope call, not a round-trip loss.
- **Optional, later:** an exploratory muex mutation sweep (e.g. `--files lib/threadline/change_diff.ex`). Not adopted as a gate: muex is pre-1.0, and Muzak is stale with a non-commercial licence.
- **Phase 227 (already planned):** a generated-data, DB-backed tie-heavy cursor layer if wanted, reusing CursorGenerators and the mutation-control script. Re-measure the Flake Detection budget again once DB properties land.
- **Phase 230:** a full `test/partition_weights.txt` refresh.

</deferred>

---

*Phase: 226-pure-property-tests-and-run-budget*
*Context gathered: 2026-10-01*
