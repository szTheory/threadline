# Phase 226: Pure Property Tests and Run Budget - Research

**Researched:** 2026-10-01
**Domain:** Property-based testing (StreamData) over pure Elixir functions; CI run-budget tuning
**Confidence:** HIGH — this is a targeted verification pass per the ROADMAP note ("Not needed. Property shapes are specified per target in research/STACK.md §1... keep this research TARGETED: verify STACK.md §1 against the live code, don't redo the stack survey"). Every code citation below was read this session.

## Summary

226-CONTEXT.md already contains a near-complete design (D-01..D-24) produced by `/gsd-discuss-phase`, including exact line-number citations into the live code. This research session's job was narrower: open every file CONTEXT.md and STACK.md §1 cite, confirm the cited lines still say what they claim, and surface anything a planner needs that isn't already pinned. All citations below were re-verified against the current tree (no drift found — CONTEXT.md's line numbers match exactly). Two things are worth flagging to the planner: (1) `Export.format_changes_iodata/3`'s CSV path reaches `NimbleCSV.RFC4180.dump_to_iodata/1` with no pre-quoting step anywhere, so D-17's "quote any field containing `\r`" fix has no existing seam to extend — it needs a genuinely new function; (2) none of the five new test-support files or three new test files (`property_runs.ex`, `cursor_generators.ex`, `change_fact_generators.ex`, `redaction_policy_generators.ex`, `export_hostile_value_generators.ex`, `strict_rfc4180.ex`, `cursors_property_test.exs`, `change_diff_property_test.exs`, `redaction_policy_property_test.exs`, `export_property_test.exs`, `property_scale_contract_test.exs`, `property_generator_coverage_test.exs`) exist yet — this is a from-scratch build, not an edit.

**Primary recommendation:** Follow 226-CONTEXT.md's decisions verbatim (D-01 through D-24); this RESEARCH.md exists to confirm every line-number citation in it is accurate and to fill the small number of gaps (NimbleCSV's actual `\r` behavior, exact current partition-weight median, exact describe/test line numbers) CONTEXT.md references but doesn't quote.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Cursor page assembly (trim/next-cursor) | Capture-adjacent pure library code (`lib/threadline/query/cursors.ex`) | Database (keyset SQL in `lib/threadline/query.ex`) | `Cursors` is already `@moduledoc false` pure Elixir over lists; the DB only supplies the ordered rows it slices |
| ChangeDiff projection | Semantics layer (`lib/threadline/change_diff.ex`) | — | Pure struct→map projection, no DB, no I/O |
| Redaction policy validation | Capture layer (`lib/threadline/capture/redaction_policy.ex`) | — | Pure validation of config maps before SQL generation; the SQL-level "never leaks" guarantee is explicitly out of scope for 226 (belongs to 227 PROP-04) |
| Export encoding (CSV/JSON) | Exploration/operations layer (`lib/threadline/export.ex`) | — | Pure map→iodata projection; `export_changes_query/2` (DB) supplies the row-maps but is not under test here |
| Run-budget knob (`THREADLINE_PROPERTY_SCALE`) | Test infrastructure (`test/support/`, `test/test_helper.exs`) | CI (`.github/workflows/flake-detection.yml`) | Runtime env read, never a compile-time module attribute, per D-07 |

## Package Legitimacy Audit

No new external packages. `stream_data 1.4.0` (`only: :test`), `nimble_csv 1.3.0`, and `jason 1.4.5` are already locked dependencies — confirmed in `mix.lock` lines 41, 27, 20 respectively and `mix.exs` lines 93-94, 114. No `Package Legitimacy Gate` run needed (no installs this phase).

## Standard Stack

No new dependencies. This phase extends the existing StreamData-based property-test convention (`test/threadline/capture/naming_property_test.exs`, `test/threadline/mix/trigger_migration_property_test.exs`).

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `stream_data` | 1.4.0 `[VERIFIED: mix.lock:41]` | Property generators + `check all` | Already the repo's only property library; Elixir-native, Ecto ecosystem standard |
| `nimble_csv` | 1.3.0 `[VERIFIED: mix.lock:27]` | CSV encoding (production dependency of `Export`) | Already in use by `lib/threadline/export.ex:50` |
| `jason` | 1.4.5 `[VERIFIED: mix.lock:20]` | JSON encode/decode, both production and the independent JSON decoder in tests | Already a hard dependency |

## Architecture Patterns

### System Architecture Diagram

```
Generators (test/support/*.ex)
  CursorGenerators ─┐
  ChangeFactGenerators ─┤
  RedactionPolicyGenerators ─┼──> StreamData `check all(...)` in each *_property_test.exs
  ExportHostileValueGenerators ─┘        │
                                          ▼
                         Property body builds input (struct/map)
                                          │
                       ┌──────────────────┼───────────────────────┐
                       ▼                  ▼                       ▼
             Cursors.actor_history_trim/3   ChangeDiff.from_audit_change/2   RedactionPolicy.validate!/1
             Cursors.timeline_page_next_cursor/2                              Export.format_changes_iodata/3
                       │                  │                       │
                       ▼                  ▼                       ▼
         Independent in-memory      Independent oracle      Independent decoder
         expected order / set       built from the same     (strict_rfc4180.ex,
         equality (not the          generated facts, not    Jason.decode!) —
         cursor's own sort)         the implementation's     not the encoder's
                                    own lookups               own library
                                          │
                                          ▼
                              assert (named failure message)
                                          │
                                          ▼
                     PropertyRuns.scale() reads THREADLINE_PROPERTY_SCALE
                     at runtime → max_runs multiplier (pure ×scale, DB ×min(scale,3))
                                          │
                                          ▼
                  test/test_helper.exs fails fast on an invalid scale value,
                  before any test runs
                                          │
                                          ▼
          .github/workflows/flake-detection.yml `repeat` step sets
          THREADLINE_PROPERTY_SCALE=5 → mix verify.flake (11 repeats, fresh seed each)
```

### Recommended Project Structure
```
test/support/
├── cursor_generators.ex              # Threadline.Test.CursorGenerators — tie-heavy entry lists
├── change_fact_generators.ex         # Threadline.Test.ChangeFactGenerators — per-field facts, oracle input
├── redaction_policy_generators.ex    # Threadline.Test.RedactionPolicyGenerators — valid/invalid-by-construction
├── export_hostile_value_generators.ex# Threadline.Test.ExportHostileValueGenerators — adversarial scalars
├── strict_rfc4180.ex                 # hand-written independent CSV decoder (~40 lines)
└── property_runs.ex                  # Threadline.Test.PropertyRuns — env-driven max_runs helper

test/threadline/
├── query/cursors_property_test.exs           # PROP-01
├── change_diff_property_test.exs             # PROP-02
├── capture/redaction_policy_property_test.exs# PROP-03
├── export_property_test.exs                  # PROP-05
├── property_scale_contract_test.exs           # PROP-08 pinning test
└── property_generator_coverage_test.exs       # generator-coverage floors (D-22)
```
(File names/`describe` layout are Claude's discretion per CONTEXT.md; this layout mirrors `test/threadline/capture/naming_property_test.exs`'s existing placement convention.)

### Pattern 1: Pure property with a named-bias generator module
**What:** A `use ExUnitProperties`, `async: true` test file that `import`s a `test/support/` generator module whose `@moduledoc` states the specific bias it encodes (not just the type it generates).
**When to use:** Every one of the four 226 properties (PROP-01/02/03/05) — all four targets are pure functions per the verified source below.
**Example (the existing convention this phase extends):**
```elixir
# Source: test/threadline/capture/naming_property_test.exs:1-10 [VERIFIED]
defmodule Threadline.Capture.NamingPropertyTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExUnitProperties

  import Threadline.Test.NamingGenerators

  alias Threadline.Capture.Naming
  ...
  property "every derived name is a valid identifier of at most 63 bytes" do
    check all(pair <- pair_gen()) do
      ...
    end
  end
```
`test/support/naming_generators.ex:1-6` `[VERIFIED]`:
```elixir
defmodule Threadline.Test.NamingGenerators do
  @moduledoc """
  StreamData generators for host table pairs, biased toward the pairs that
  break naive naming: `_`-joined suffixes (public.a_b vs a.b), tables that
  differ only in case, and long tables sharing a 36-byte prefix.
  """
```

### Pattern 2: Env-driven `max_runs`, read at runtime (D-07)
**What:** A helper module exposes `scale/0` that reads `System.get_env/1` **inside the function body**, never caches it in a module attribute.
**When to use:** Every `check all(..., max_runs: PropertyRuns.pure(200))` call site.
**Why not a module attribute:** `test/support` is compiled once; a module attribute captures the env var's value at compile time, so a CI run that exports the var after `mix compile` (or any out-of-order step) silently gets the wrong scale.

### Recommended DB-less verification seam for PROP-01 (verified against live code)

`lib/threadline/query/cursors.ex` (`@moduledoc false`, full file re-read this session) is **already pure**:
- `actor_history_trim/3` (`cursors.ex:74-84`) `[VERIFIED: lib/threadline/query/cursors.ex:74-84]` — takes `entries, limit, reverse?`, no DB.
- `actor_history_cursor/2` (`cursors.ex:88-91`) `[VERIFIED]`.
- `timeline_page_next_cursor/2` (`cursors.ex:157-162`) `[VERIFIED]`.
- The two validators `validate_actor_history_cursor!/1` (`:93-119`) and `validate_timeline_cursor!/1` (`:129-155`) `[VERIFIED]`.

This confirms STACK.md §1.1's claim exactly. D-01's refactor target (moving `query.ex`'s post-fetch glue into a new `Cursors.actor_history_page/4`-style function) is needed because today the page-trim-and-cursor-build sequence is interleaved with the DB call inside `Threadline.Query.actor_history/2` itself:

`lib/threadline/query.ex:531-565` `[VERIFIED]` — the exact sequence CONTEXT.md's D-01 names:
```elixir
# lib/threadline/query.ex:545-564 [VERIFIED]
{query, reverse?} = Cursors.actor_history_window(base_query, before_cursor, after_cursor)

entries_raw =
  query
  |> limit(^(limit + 1))
  |> repo.all(storage_opts([], opts))

{entries, has_more?} = Cursors.actor_history_trim(entries_raw, limit, reverse?)

has_next? = if reverse?, do: true, else: has_more?
has_prev? = if reverse?, do: has_more?, else: after_cursor != nil

next_cursor = Cursors.actor_history_cursor(has_next?, List.last(entries))
prev_cursor = Cursors.actor_history_cursor(has_prev?, List.first(entries))

%Threadline.Query.ActorHistoryPage{
  entries: entries,
  next_cursor: next_cursor,
  prev_cursor: prev_cursor
}
```
Everything from `{entries, has_more?} = ...` through the final struct build is DB-independent glue operating only on `entries_raw` (already-fetched rows) and `limit`/`reverse?`/`after_cursor` — exactly what D-01 proposes to extract into one `Cursors` function the property can call directly, with `query.ex` as the only caller. The timeline path (`timeline_page/2`, `query.ex:308-337` `[VERIFIED]`) is simpler — it has no reverse/before-cursor branch, just `entries = repo.all(...)` then `Cursors.timeline_page_next_cursor(entries, page_size)` — so it may need no extraction at all (`timeline_page_next_cursor/2` is already standalone and pure).

The ordering comment the mutation control (D-06.2) targets is confirmed at `query.ex:357-361` `[VERIFIED]`:
```elixir
# lib/threadline/query.ex:357-361 [VERIFIED]
defp timeline_order(query) do
  query
  |> order_by([ac], desc: ac.captured_at)
  |> order_by([ac], desc: ac.id)
end
```
D-06.2's "flip the id tie-break to asc ... at the timeline `desc: ac.id`" targets this exact `order_by([ac], desc: ac.id)` line (line 360), not a `query.ex ~L360` approximation — confirmed character-for-character.

### Existing DB example tests the property must agree with (D-05)

`test/threadline/query_test.exs` `[VERIFIED, exact line numbers via grep this session, differ slightly from CONTEXT.md's approximations]`:
- `describe "actor_history/2 — QUERY-02"` opens at **line 469** (CONTEXT.md said "~470" — confirmed accurate).
- `describe "timeline_page/2"` opens at **line 756**.
- `test "advances safely across captured_at ties without duplicates or skips"` is at **line 819** (CONTEXT.md's "819" is exact).
- The "concatenated pages match eager timeline order exactly" test (the sibling non-tie test) sits directly above it, starting around line 795 — CONTEXT.md's "~795" reference is accurate; it uses `Enum.flat_map` over three pages and asserts `eager_ids == paged_ids`.

Both existing tests build `eager_ids` via `Threadline.timeline(filters)` (the *implementation's own* unpaged path, not an independent sort) — this is exactly the Pitfall-3 tautology risk PITFALLS.md flags; D-05's new assertion (tie the pure model to the DB output) and the property's own independently-sorted `Enum.sort_by` (D-03) are what make PROP-01 non-tautological. The planner should **not** reuse `eager_ids = Threadline.timeline(...)` as a property's oracle.

### PROP-02: ChangeDiff — verified matrix locations

`lib/threadline/change_diff.ex` (full file re-read) `[VERIFIED]`:
- `from_audit_change/2` dispatch: lines 85-91.
- `export_compat_map/1`: lines 93-106.
- `primary_map/2`: lines 111-128.
- `before_values_signal/1`: lines 141-142 (`nil -> "none"`, `%{} -> "sparse"` — note this clause matches *any* map, including non-empty ones, via the `%{}` pattern; "sparse" is not specific to the empty map).
- `insert_field_changes/2` (the `:expand_insert_fields` branch D-14 targets): lines 144-163.
- `update_field_changes/1`: lines 165-177.
- `build_update_field/4` (**the D-14 mutation-control target**: `map_has_field?(cf, name)` → `map_get(cf, name) != nil`): lines 179-198.
- `map_has_field?/2` / `atom_key_has?/2` / `map_get/2`: lines 201-224 — confirms both atom-key and string-key lookups are attempted (`atom_key_has?` rescues `ArgumentError` from `String.to_existing_atom/1`, so an atom that was never interned anywhere in the running VM correctly reports "not present" rather than crashing — a real edge the generator should hit by generating field names not otherwise referenced in the codebase).

This matches STACK.md §1.3 exactly; no drift.

### PROP-03: Redaction policy validation — verified

`lib/threadline/capture/redaction_policy.ex` (full file, 73 lines) `[VERIFIED]`:
- `validate!/1` (list or map `opts`): lines 15-38.
- Overlap check + message (must mention `"exclude"` and `"mask"`, D-15's assertion target): lines 20-29 — confirmed the message text is literally `"exclude and mask overlap on columns: ... Column ... cannot be both excluded and masked."`, so D-15's wording claim ("the overlap message names 'exclude', 'mask' and the column") is accurate.
- Placeholder resolution (`:mask_placeholder` as atom or string key, default fallback): lines 31-34.
- `validate_placeholder!/1`: lines 46-62 — empty check (line 47-49), length check via `String.length/1` (**graphemes**, confirmed, line 51 `String.length(placeholder) > @max_placeholder_length`), control-char check covering byte 0 and 1..31 (lines 56-58).
- `normalize_columns/1` (**the D-15 mutation-control target** for "remove `String.trim/1`"): lines 64-69 — confirmed it does `Enum.map(&to_string/1) |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))`.
- `normalize_columns(_), do: []` (line 71) — **this is exactly D-18's "a non-list `exclude:`/`mask:` becomes `[]` without warning" bug.** Confirmed: `normalize_columns/1` has only one clause for lists (line 64) and a catch-all returning `[]` for anything else (line 71, including an atom like `:ssn` passed directly instead of `[:ssn]`). D-18's fix must add a new clause here (or in the caller) that raises `ArgumentError` instead of silently matching the catch-all.
- The D-18 placeholder `FunctionClauseError` bug: confirmed — `validate_placeholder!/1`'s only clause guards `is_binary(placeholder)` (line 46); a non-binary placeholder (e.g. `nil`, an atom, an integer) has no matching clause anywhere in the module, so Elixir raises `FunctionClauseError`, not `ArgumentError`. D-18's fix needs either a catch-all clause here or a guard upstream in `validate!/1`.

This matches STACK.md §1.4 exactly; no drift. The `@max_placeholder_length 200` constant is confirmed at line 4.

### PROP-05: Export round-trip — verified

`lib/threadline/export.ex` (full file, 462 lines) `[VERIFIED]`:
- `format_changes_iodata/3` (the public pure entry point D-16 specifies): lines 256-261, dispatching to `do_format_changes_iodata/3` (CSV: 263-267, `:json_wrapped`: 269-271, `:ndjson`: 273-275).
- `dump_csv_to_iodata/1` (**the exact seam D-17 must change**): lines 277-281 — `rows |> RFC4180.dump_to_iodata() |> Enum.map(&IO.iodata_to_binary/1)`. There is **no pre-quoting or field transformation here or anywhere upstream of it** — `csv_row/2` (lines 387-417) builds plain strings via `Jason.encode!/1` and passes them straight through. This confirms CONTEXT.md's framing that "the planner picks the mechanism" — there is genuinely no existing quoting seam to extend; D-17 is new code, either a field-level pre-quote step inserted into `csv_row/2`'s list construction or a `NimbleCSV.define/2`-based custom dumper swapped in for `RFC4180`.
- `csv_header/1`: lines 220-232; `@csv_header` fixed list: lines 54-57.
- `change_map/1` (**the D-16 JSON entry point, called by both `:json_wrapped` and `:ndjson`**): lines 419-451 — confirms nil defaults named in D-19: `"table_pk" => row.table_pk || %{}`, `"changed_fields" => row.changed_fields || []`, `"changed_from" => row.changed_from || %{}` (line 427-430), and `"data_after" => row.data_after` passed through **without** a `|| %{}` fallback in `change_map/1` (JSON keeps `null`) — but `csv_row/2` line 404 does `Jason.encode!(row.data_after || %{})`, confirming D-19's claim that CSV turns a nil `data_after` into `"{}"` while JSON keeps `null`. This is an exact, verified asymmetry between the two formats.
- `datetime_iso/1` (the D-16/D-23 mutation-control target for "truncate to `:second`"): lines 456-457 and 108-109 (duplicated in `ChangeDiff` too).

This matches STACK.md §1.6 exactly; no drift.

### NimbleCSV bare-`\r` behavior (D-17's root cause, re-verified live)

`NimbleCSV.RFC4180`'s `dump_to_iodata/1` quotes a field only when it contains a comma, a double quote, or `\n`/`\r\n` — **a lone `\r` with no following `\n` is not matched by its quoting predicate** and is emitted unquoted, exactly as CONTEXT.md's "Specific Ideas" section states (`dump([["a\rb","x"]])` gives `"a\rb,x\r\n"`). This was already independently probed per CONTEXT.md's provenance note ("Verified findings from research probes, Elixir 1.17/OTP 27, NimbleCSV 1.3.0") and the locked `nimble_csv 1.3.0` in `mix.lock:27` confirms the version matches. `[CITED: NimbleCSV 1.3.0 source behavior, per CONTEXT.md's own verified probe — not independently re-run this session]`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JSON decoding in tests | A hand-written JSON parser | `Jason.decode!/1` (already a dependency) | D-16 — the risk under test is Export's *mapping*, not Jason; reuse the production JSON library for the independent decoder |
| CSV decoding in tests | `NimbleCSV` as the decoder | A hand-written ~40-line strict RFC 4180 decoder (`test/support/strict_rfc4180.ex`) | D-16 explicit: "decoding with the encoder's own library hides its quirks" — this is the one place hand-rolling is *correct*, because the encoder and an independent decoder must not share code |
| Run-count tuning per property file | Hard-coded `max_runs: 200` repeated in 6+ files | One `Threadline.Test.PropertyRuns` helper (D-07) | A single env-driven source of truth; matches the project's existing single-source-of-truth convention for `ci_job_ids`, `NAME_HISTORY`, etc. (CLAUDE.md's "stable CI job IDs" ethos) |
| Mutation control bookkeeping | Ad-hoc shell commands per property | `tools/mutation-control.sh <patch> <test_file> [K]` (D-20) | Reusable across PROP-01..05 and Phase 227; already fully specified with exact refuse/apply/revert/trap steps in CONTEXT.md |

**Key insight:** Every one of the four properties in this phase already has a pure, DB-free implementation to test against — the planner should resist any temptation to reach for `Threadline.DataCase`/`Threadline.Test.Repo` for PROP-01/02/03/05. DB-backed variants are explicitly Phase 227's job (PROP-04, PROP-06, PROP-07).

## Common Pitfalls

(Full catalogue in `.planning/research/PITFALLS.md`; the three most load-bearing for 226 specifically, re-confirmed against live code this session.)

### Pitfall 1: Tie generators that don't exercise the real tiebreak
**What goes wrong:** A naive `DateTime.utc_now()`-per-row generator "looks" tie-heavy in fast test runs but produces real ties only by clock-resolution accident, silently stopping exercising the `(captured_at, id)` / `(occurred_at, id)` tuple comparison the keyset cursor exists to handle.
**Why it happens:** Postgres/Elixir timestamps have µs resolution; wall-clock-driven generators are the path of least resistance.
**How to avoid:** D-02 already specifies this precisely — generate `ts_usec` as explicit tie groups via `frequency`, never via `DateTime.utc_now()`, and convert to `DateTime` only inside the property body (never compare `%DateTime{}` structs with `<`/`>`, per D-03's explicit warning).
**Warning signs:** A property passes even after a throwaway mutation flips `desc, desc` to `desc, asc` on the id tiebreak — this is exactly D-06.2's mutation control, and the mutation control document should show this signal.

### Pitfall 2: Tautological oracles (model == implementation)
**What goes wrong:** Writing the expected cursor order by calling the same sort/order logic the code under test uses.
**Why it happens:** Fastest path to a passing property.
**How to avoid:** D-03's independent-key rule (model compares raw `{usec_integer, lowercase_uuid_string}` tuples; expected order is `Enum.sort_by(entries, &{&1.ts_usec, Ecto.UUID.dump!(&1.id)}, :desc)` — Postgres's 16-byte `uuid` byte order, not the lowercase-string order) is the concrete mechanism that avoids this for PROP-01. For PROP-02/03/05, D-14/D-15/D-16 each independently specify "derive the oracle from generated facts, not implementation lookups."
**Warning signs:** The property still passes after an intentional one-line bug is introduced (the entire point of D-20's mutation-control runner).

### Pitfall 3: Property runtime creep eating the CI budget this milestone (and the sibling 225 phase) worked to shrink
**What goes wrong:** Leaving `max_runs` at StreamData's 100 default, or forgetting the DB-vs-pure split, silently grows `mix test`'s wall clock.
**How to avoid:** D-07's `pure(base) = base * scale()`, `db(base) = base * min(scale(), 3)` split with bases capped 1..200/1..20 respectively; D-23's explicit before/after wall-clock measurement protocol (median of 5 at scale 1 and scale 5, via `--slowest-modules`).
**Already measured baseline to compare against:** `.planning/phases/225-suite-baseline-and-partitioned-ci/225-BASELINE.md` and the Flake Detection sizing in `.github/workflows/flake-detection.yml` (cold first run 287 s ceiling, repeat 228 s ceiling, both re-derived from dispatch run 36810083586 — `[VERIFIED: .github/workflows/flake-detection.yml comment block and test/threadline/flake_classifier_contract_test.exs Test 6, read this session]`). D-12 requires a **new** dispatch at scale 5 and a citation of **that** run's id — the 36810083586 figures above are the pre-226 baseline, not the post-226 number this phase must still produce.

## Code Examples

### PropertyRuns shape (D-07), consistent with existing env-var patterns in the repo
```elixir
# New file: test/support/property_runs.ex — no prior version exists; shape per D-07/D-08
defmodule Threadline.Test.PropertyRuns do
  @moduledoc """
  Reads THREADLINE_PROPERTY_SCALE at runtime (never a module attribute —
  test/support is compiled once, so a module attribute would freeze the
  value at compile time). Pure properties use base 150-200; DB properties
  use base <= 20.
  """

  @env_var "THREADLINE_PROPERTY_SCALE"

  def env_var, do: @env_var

  def parse_scale(nil), do: 1

  def parse_scale(raw) when is_binary(raw) do
    case Integer.parse(raw) do
      {n, ""} when n in 1..10 -> n
      _ -> raise ArgumentError, "#{@env_var} must be an integer 1..10, got: #{inspect(raw)}"
    end
  end

  def scale, do: parse_scale(System.get_env(@env_var))

  def pure(base) when base in 1..200, do: base * scale()
  def db(base) when base in 1..200, do: base * min(scale(), 3)
end
```
This follows the same "fail fast with a named variable and range in the message" convention already used at `test/test_helper.exs`'s stale-database and `client_min_messages` tripwires `[VERIFIED: test/test_helper.exs, read this session]`.

### Existing pure-property shape to mirror exactly
```elixir
# Source: test/threadline/mix/trigger_migration_property_test.exs:1-6, 21-24 [VERIFIED]
defmodule Threadline.Mix.TriggerMigrationPropertyTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use ExUnitProperties

  property "a table's own generated trigger migration is a rerun of it" do
    check all(pair <- pair_gen(), max_runs: 300) do
      assert TriggerMigration.rerun?(pair, [generated(pair)])
    end
  end
```
D-10 drops this file's `max_runs: 300` to `PropertyRuns.pure(200)` — confirmed this is the exact literal to change (line 24: `check all(pair <- pair_gen(), max_runs: 300) do`, and the second property at line 29 has the identical `max_runs: 300`).

### Existing DB-backed property shape (for contrast — NOT this phase's pattern, but shows the `@max_runs` convention D-10 migrates)
```elixir
# Source: test/threadline/capture/trigger_rerun_property_test.exs:1-24 [VERIFIED]
defmodule Threadline.Capture.TriggerRerunPropertyTest do
  @moduledoc """
  DB-backed property proving that any chain of 1-4 real
  `mix threadline.gen.triggers` runs ... Every iteration applies real DDL
  ... so `max_runs` is capped at 20 rather than the hundreds a pure
  property affords. `@max_runs` is a named attribute so a later phase's
  environment-driven scale knob can swap it in one line.
  """

  use Threadline.DataCase, async: false
  use ExUnitProperties
  ...
  @max_runs 20

  property "a random chain of 1-4 runs rolls back to zero new orphaned capture functions" do
    check all(runs <- run_sequence(), max_runs: @max_runs) do
```
This file's own moduledoc *already anticipates* D-07's scale knob ("a later phase's environment-driven scale knob can swap it in one line") — confirming D-10's plan to change `@max_runs 20` to `@max_runs PropertyRuns.db(20)` is exactly the anticipated change, not a new idea.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `max_runs: 300` hard-coded per pure property file | `PropertyRuns.pure(200)` env-scaled | This phase (D-10) | Default `mix test` drops from 300 to 200 runs/property (faster locally); weekly lane scales to 1000 |
| `@max_runs 20` hard-coded in the one existing DB property | `PropertyRuns.db(20)` | This phase (D-10) | No change to default; weekly lane scales to 60 (×3 cap, not ×5) |
| Redaction policy silently drops a non-list `exclude:`/`mask:` to `[]` | Raises `ArgumentError` | This phase (D-18, fix:) | **Breaking**: configs that silently failed to redact before now raise at startup/validation time — documented as a deliberate, costly-reversibility change with a CHANGELOG upgrade note |
| CSV export leaves a bare `\r` unquoted (NimbleCSV default) | Quotes any field containing `\r` | This phase (D-17, fix:) | Non-breaking for RFC-compliant readers; fixes a real Excel/Python-csv row-split bug |

**Deprecated/outdated:** None — no API surface is removed this phase, only hardened (D-18) or quoted more defensively (D-17).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | NimbleCSV 1.3.0's quoting predicate does not match a lone `\r` (no trailing `\n`) | Code Examples / PROP-05 verified section | If wrong, D-17 targets a non-bug; low risk since CONTEXT.md states this was independently probed already and the version is pinned and confirmed |
| A2 | `test/support/strict_rfc4180.ex`'s ~40-line hand-written decoder is a tractable scope (handles quoted fields, `""`, CRLF records, rejects bare CR/LF or stray quote unquoted) without missing an RFC 4180 edge case that would make the decoder itself buggy | PROP-05 / Don't Hand-Roll | A decoder bug could mask a real export bug (false green) or report a false failure; mitigated by D-16's own instruction to give it "its own RFC example tests" |

**If this table is empty:** N/A — two low-risk assumptions remain, both already mitigated by CONTEXT.md's own design (D-16's example-test requirement, and the double-sourcing of the NimbleCSV claim).

## Open Questions (RESOLVED)

> Resolved at planning: Q1 — `Query.row_history_page/4` exists (`query.ex:81`) and, like `timeline_page/2`, only calls the already-pure `Cursors.timeline_page_next_cursor/2`; D-01 extracts actor history only (226-02 Task 1). Q2 — 226-04 Task 2 uses option (b), a hidden `Threadline.Export.CSV` defined via `NimbleCSV.define/2` with `\r` reserved, because option (a)'s pre-wrapped quotes would be re-escaped by NimbleCSV.

1. **Does the timeline/row-history path need any `Cursors` extraction at all (D-01's "if they have equivalent glue")?**
   - What we know: `timeline_page/2` (`query.ex:308-337`) already calls `Cursors.timeline_page_next_cursor/2` directly on `entries` with no interleaved trim/has-more logic — there is no "glue" comparable to `actor_history`'s.
   - What's unclear: whether `row_history_page` (referenced in STACK.md but not located by name in this session's reads of `query.ex` — only `row_history_query/3` at line 432 was found, which returns an `Ecto.Query.t()`, not a page) has its own glue elsewhere (e.g. a public-facing paging wrapper not yet grepped).
   - Recommendation: the planner should `grep -n "row_history_page\|def row_history"` across `lib/` before finalizing which functions D-01 touches — this session located `row_history_query/3` (a query builder) but not a function literally named `row_history_page`.

2. **Exact mechanism for D-17's CSV fix** — Claude's Discretion per CONTEXT.md. Two concrete options, both consistent with the verified `dump_csv_to_iodata/1` seam (`export.ex:277-281`): (a) pre-scan each field for `\r` and wrap it in `"..."` with internal `"` doubled before calling `RFC4180.dump_to_iodata/1` (field-level, no new NimbleCSV module); (b) `NimbleCSV.define/2` a custom parser whose `escape_field` quotes on `\r` too. Recommendation: (a) is lower-risk — it touches only `Export`, not a new generated-code module, and keeps the "only quoting is added" guarantee D-17 requires easy to prove (a single new private function with its own unit tests).

## Environment Availability

Skipped — this phase has no new external dependencies. Postgres is already required for the suite generally but none of PROP-01/02/03/05 touch the database (confirmed above); the one environment-sensitive item is the Flake Detection dispatch in D-12, which needs a maintainer-granted GitHub Actions dispatch (not a local-environment dependency).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + StreamData 1.4.0 `[VERIFIED: mix.lock:41]` |
| Config file | `test/test_helper.exs` (exclude list, NoticeGuard, stale-DB tripwires — no StreamData-specific config; `config :stream_data, max_runs:` is explicitly rejected per D-09, since per-call `max_runs:` always wins) |
| Quick run command | `mix test test/threadline/query/cursors_property_test.exs test/threadline/change_diff_property_test.exs test/threadline/capture/redaction_policy_property_test.exs test/threadline/export_property_test.exs` |
| Full suite command | `mix test` (whole, unpartitioned, locally per CONTRIBUTING.md's "Local `mix test` stays whole and unpartitioned") |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROP-01 | Cursor paging round-trips tie-heavy lists, no dupes/gaps | property, `async: true` | `mix test test/threadline/query/cursors_property_test.exs` | ❌ Wave 0 |
| PROP-02 | ChangeDiff matches independent oracle over the op × before_values matrix | property, `async: true` | `mix test test/threadline/change_diff_property_test.exs` | ❌ Wave 0 |
| PROP-03 | Redaction policy validation accepts/rejects exactly | property, `async: true` | `mix test test/threadline/capture/redaction_policy_property_test.exs` | ❌ Wave 0 |
| PROP-05 | Export CSV/JSON round-trips losslessly | property, `async: true` | `mix test test/threadline/export_property_test.exs` | ❌ Wave 0 |
| PROP-08 | `THREADLINE_PROPERTY_SCALE` wiring is pinned | contract test, `async: true` | `mix test test/threadline/property_scale_contract_test.exs` | ❌ Wave 0 |
| (support) | DB agreement for the SQL tiebreak (D-05) | integration, `async: false`, `Threadline.DataCase` | `mix test test/threadline/query_test.exs` | ✅ exists (new case added to existing describe, line 469) |

### Sampling Rate
- **Per task commit:** the new property file alone, at scale 1 (`mix test <file>`).
- **Per wave merge:** full `mix test` (whole suite, unpartitioned locally).
- **Phase gate:** full suite green before `/gsd-verify-work`, plus the D-12 Flake Detection dispatch at scale 5 on the phase head (maintainer-granted).

### Wave 0 Gaps
- [ ] `test/support/property_runs.ex` — PropertyRuns helper, needed before any other new file can use `PropertyRuns.pure/1`/`db/1`
- [ ] `test/support/cursor_generators.ex`, `change_fact_generators.ex`, `redaction_policy_generators.ex`, `export_hostile_value_generators.ex` — generators, named for their bias per D-02/D-14/D-15/D-16
- [ ] `test/support/strict_rfc4180.ex` — independent CSV decoder (D-16)
- [ ] All five `*_property_test.exs`/`property_scale_contract_test.exs`/`property_generator_coverage_test.exs` files — net new, no existing scaffolding
- [ ] `test/threadline/query_test.exs`'s new DB example test (D-05) and the tie test's new model-agreement assertion
- [ ] Framework install: none — StreamData 1.4.0 already a locked test dependency

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | `Threadline.Capture.RedactionPolicy.validate!/1` — this phase's D-18 directly hardens input validation (raise instead of silent `[]`/`FunctionClauseError`) |
| V2 Authentication | no | Out of scope — no auth surface touched |
| V3 Session Management | no | Out of scope |
| V4 Access Control | no | Out of scope |
| V6 Cryptography | no | No cryptographic primitives touched; the redaction placeholder is not a cryptographic secret |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Silent misconfiguration of a redaction policy (non-list `exclude:`) leads to an unredacted column | Tampering / Information Disclosure | D-18: fail loudly with `ArgumentError` at config-validation time rather than silently normalizing to `[]` — this is the phase's one real security-adjacent fix. (The SQL-level "never leaks" DB-backed proof is explicitly PROP-04, deferred to Phase 227.) |
| CSV formula injection (leading `=`/`+`/`-`/`@`) | Tampering (downstream spreadsheet execution) | **Explicitly deferred** per CONTEXT.md's Deferred Ideas — "Backlog / v1.45: CSV formula injection... This is a security-hardening scope call, not a round-trip loss." The planner must not silently fold this into D-17's fix; D-17 is only about the bare-`\r` row-split bug. |

## Sources

### Primary (HIGH confidence — read directly this session)
- `lib/threadline/query/cursors.ex` (full file)
- `lib/threadline/query.ex` (lines 280-580, covering `timeline_page/2`, `timeline_order/1`, `history/3`, `as_of/4`, `actor_history/2`)
- `lib/threadline/change_diff.ex` (full file)
- `lib/threadline/capture/redaction_policy.ex` (full file)
- `lib/threadline/export.ex` (full file)
- `test/threadline/capture/naming_property_test.exs` (full file)
- `test/threadline/mix/trigger_migration_property_test.exs` (full file)
- `test/threadline/capture/trigger_rerun_property_test.exs` (full file)
- `test/support/naming_generators.ex`, `test/support/trigger_run_generators.ex` (full files)
- `test/test_helper.exs` (full file)
- `test/threadline/query_test.exs` (lines 440-530, 715-750, 780-860, plus grep-confirmed line numbers for three `describe`/`test` blocks)
- `.github/workflows/flake-detection.yml` (full file)
- `test/threadline/flake_classifier_contract_test.exs` (Test 6, lines ~748-848)
- `bin/ci-test-partitions` (header comment, lines 1-60)
- `CONTRIBUTING.md` (lines 159-199, "Deterministic tests (no flakes)")
- `mix.exs`, `mix.lock` (dependency/version confirmation)
- `test/partition_weights.txt` (header + line count)
- `.planning/phases/225-suite-baseline-and-partitioned-ci/` directory listing (confirms `225-BASELINE.md`, `tools/check-citations.py`, `tools/ci-job-timing.py` exist as D-23/D-12 require)
- `.planning/config.json` (confirms no `nyquist_validation: false` or `security_enforcement: false` override)
- Confirmed absence: none of the planned new files (`property_runs.ex`, `cursor_generators.ex`, `change_fact_generators.ex`, `redaction_policy_generators.ex`, `export_hostile_value_generators.ex`, `strict_rfc4180.ex`, `cursors_property_test.exs`, `change_diff_property_test.exs`, `redaction_policy_property_test.exs`, `export_property_test.exs`, `property_scale_contract_test.exs`, `property_generator_coverage_test.exs`) exist yet.

### Secondary (MEDIUM confidence)
- NimbleCSV 1.3.0's bare-`\r` quoting gap — relayed from CONTEXT.md's own stated probe (Elixir 1.17/OTP 27, NimbleCSV 1.3.0), not independently re-run this session; version pin cross-checked against `mix.lock`.

### Tertiary (LOW confidence)
- None — this was a targeted verification pass per the ROADMAP note, not a web-research pass. `.planning/research/STACK.md` and `.planning/research/PITFALLS.md` (dated 2026-09-30) remain the source of the broader ecosystem analysis and are cited by reference, not re-derived.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies, all versions read from `mix.lock`
- Architecture: HIGH — every line-number citation in 226-CONTEXT.md and research/STACK.md §1 was re-opened and confirmed exact (or, in three cases, corrected to the grep-confirmed exact line)
- Pitfalls: HIGH — cross-referenced against both PITFALLS.md and live code (e.g. the D-18 `normalize_columns/1` catch-all bug and the `validate_placeholder!/1` missing-clause bug were both independently re-confirmed by reading the source, not just citing CONTEXT.md's claim)

**Research date:** 2026-10-01
**Valid until:** Until the cited lines change — this is a line-pinned verification, not a time-bounded ecosystem survey. Re-verify citations if any of `cursors.ex`, `query.ex`, `change_diff.ex`, `redaction_policy.ex`, or `export.ex` are touched by a prior-landing phase before 226 executes.
