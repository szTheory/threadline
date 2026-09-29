---
phase: 212-detection-and-adopter-twins
reviewed: 2026-09-26T00:00:00Z
depth: standard
files_reviewed: 30
files_reviewed_list:
  - lib/threadline/health.ex
  - lib/threadline/health/finding.ex
  - lib/threadline/health/trigger_catalog.ex
  - lib/threadline/health/trigger_findings.ex
  - lib/threadline/capture/primary_key_sql.ex
  - lib/threadline/verify/coverage_policy.ex
  - lib/threadline/telemetry.ex
  - lib/mix/tasks/threadline.verify_coverage.ex
  - lib/mix/tasks/threadline.health.coverage.ex
  - lib/threadline/query.ex
  - mix.exs
  - priv/ci/topology_bootstrap.exs
  - config/test.exs
  - examples/threadline_phoenix/config/test.exs
  - examples/threadline_phoenix/test/test_helper.exs
  - examples/threadline_phoenix/test/support/shape_fixtures.ex
  - examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_migration_contract_test.exs
  - examples/threadline_phoenix/test/threadline_phoenix/shape_fixtures_round_trip_test.exs
  - examples/threadline_phoenix/priv/shape_fixtures/migrations/20260926100000_create_shape_fixtures.exs
  - priv/ci/hex_evaluator/config/config.exs
  - priv/ci/hex_evaluator/test/support/shape_fixtures.ex
  - priv/ci/hex_evaluator/test/hex_evaluator/shape_fixtures_migration_contract_test.exs
  - priv/ci/hex_evaluator/test/hex_evaluator/shape_fixtures_round_trip_test.exs
  - priv/ci/hex_evaluator/priv/repo/migrations/20260926100000_create_shape_fixtures.exs
  - test/threadline/health/trigger_findings_test.exs
  - test/threadline/health/trigger_findings_key_test.exs
  - test/threadline/health/trigger_findings_non_owner_test.exs
  - test/threadline/health_findings_doc_contract_test.exs
  - test/threadline/health_test.exs
  - test/threadline/pgbouncer_topology_test.exs
  - test/threadline/verify_coverage_policy_test.exs
  - test/threadline/verify_coverage_task_test.exs
  - test/threadline/operator_surface/coverage_mix_test.exs
  - test/threadline/operator_surface/coverage_doc_contract_test.exs
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 212: Code Review Report

**Reviewed:** 2026-09-26
**Depth:** standard
**Files Reviewed:** 30
**Status:** issues_found

## Summary

This phase adds `Threadline.Health.trigger_findings/1`, its five finding codes, wiring into
both Mix tasks, and shape-fixture adopter twins in the example app and hex evaluator. The
implementation is careful and internally consistent with the locked CONTEXT decisions
(D-01..D-22): catalog-only, parameterized SQL everywhere identifiers could otherwise be
interpolated (the one identifier-shaped interpolation, `identification_predicate/0`, is a
fixed internal constant, never caller input); the override-qualification SQL in
`TriggerCatalog.qualifying_override_index?/3` correctly reuses
`PrimaryKeySQL.qualifying_index_predicate/0` and `override_index_key_set_sql/0` so it can
never diverge from the migration's own enforcement; tgargs NUL-decoding, tgenabled 'D'/'R'
handling, the case-insensitive-only-for-reason-selection column-rename detection, the
partition-clone (`tgparentid = 0`) exclusion, and the duplicate/canonical-trigger logic all
match their D-08..D-13 specs and are exercised by real-Postgres fixtures with clean negative
controls. The twins (example app and hex evaluator) mirror each other closely, keep their
fixture migrations correctly isolated from the frozen browser-lane baselines, and the
migration-contract tests include a genuine non-vacuous "edited copy differs" control.

No BLOCKER-level defects were found. Two WARNING-level issues affect message-format
consistency and doc-comment accuracy; two INFO-level items are minor redundancy/clarity notes.

## Warnings

### WR-01: `duplicate_capture_trigger`'s fix command is not fully qualified for a `public`-schema table, unlike every other finding's fix command (deviates from D-14)

**File:** `lib/threadline/health/trigger_findings.ex:160-172`

**Issue:** D-14 states: "Use the qualified form everywhere, including `public`, so the
command pastes correctly." Every other finding's fix command builds its `--tables` argument
from `fix_command(schema, table)`, which always renders `"#{schema}.#{table}"` — fully
qualified even for `public` (see `pk_drift_message/5` and `legacy_warning_message/1`, both
via `fix_command/2` at line 300).

`duplicate_message/4`, however, builds its regenerate-command argument from
`Naming.table_token/1` (line 162), which deliberately returns the *bare* table name when the
schema is `"public"` (see `Naming.table_token/1`'s own doc: "bare for `public`,
`schema.table` otherwise"). So a duplicate-trigger finding on a `public`-schema table emits:

```
... Fix: DROP TRIGGER "extra" ON "public"."dup_t";
mix threadline.gen.triggers --tables dup_t to confirm the canonical trigger.
```

instead of the fully-qualified `--tables public.dup_t` every other finding in this module
uses. `mix threadline.gen.triggers --tables` does accept a bare name for `public` (confirmed
in `lib/mix/tasks/threadline.gen.triggers.ex`), so the command still works — this is a
spec-adherence and consistency defect, not a broken command. It is also untested: every
`duplicate_capture_trigger` test in `trigger_findings_test.exs` uses a non-public schema
(`hlth_find_dup`, `hlth_find_order`), so the bare-vs-qualified discrepancy for `public` never
surfaces in the suite.

**Fix:**
```elixir
defp duplicate_message(schema, table, names, extra) do
  qualified = "#{schema}.#{table}"

  drops =
    Enum.map_join(extra, " ", fn name ->
      "DROP TRIGGER #{quote_identifier(name)} ON #{quote_identifier(schema)}.#{quote_identifier(table)};"
    end)

  "#{qualified}: #{length(names)} Threadline capture triggers record every write more than " <>
    "once (#{Enum.join(names, ", ")}). Fix: #{drops} then mix threadline.gen.triggers " <>
    "--tables #{qualified} to confirm the canonical trigger."
end
```
(drop the now-unused `token = Naming.table_token(...)` line), and add a `public`-schema test
case asserting `--tables public.<table>` appears in the message.

### WR-02: `Threadline.Query`'s doc edit removed the only pointer to the actual normalizer, without replacing it with an equally precise one

**File:** `lib/threadline/query.ex:380-383`

**Issue:** The diff changes:
```
`Threadline.Query.RowKey.normalize!/2`
```
to:
```
via the internal row-key normalizer
```
This is a purely cosmetic doc change (hiding a private-module reference from public docs is a
reasonable goal), but the replacement text is vaguer than necessary and no longer names which
function actually raises, which could make a future contributor's `grep` for the raising
site less direct. This is not a functional defect and is harmless, but since the file was
called out for review with "phase 212 touched only a doc line," it's worth confirming the
intent (hiding a private module name from public docs) was actually achieved elsewhere too —
it was not: `RowKey` remains referenced by name in other parts of the same moduledoc region
that were not touched, so the edit is inconsistent within the file itself (some raise-sources
are still named, this one was anonymized). Low-impact; flagged for consistency only, not
correctness.

**Fix:** Either revert to naming the module (if `RowKey` is meant to stay an internal
implementation detail referenced informally in docs, as it evidently already is elsewhere in
this file), or, if the intent is genuinely to stop naming private modules in public docs, do
that consistently across the whole moduledoc in a follow-up, not only at this one call site.

## Info

### IN-01: `qualifying_override_index?`'s extra `attnum = 0` guard is dead code given `qualifying_index_predicate/0`

**File:** `lib/threadline/health/trigger_catalog.ex:126-129`

**Issue:** `qualifying_override_index?/3` has two `NOT EXISTS` guards: one for `k.attnum = 0`
(an expression key part) and one for nullable columns. But `qualifying_index_predicate/0`
(reused via interpolation on line 125) already requires `i.indexprs IS NULL`, and PostgreSQL
never sets `indkey[i] = 0` for a key position without a corresponding non-null `indexprs`
entry — i.e. `indexprs IS NULL` already guarantees no `attnum = 0` positions exist. The guard
is consistent with `PrimaryKeySQL.detected_trigger_block/3`'s equivalent lookup (which has
the same redundant check), but not with `PrimaryKeySQL.override_trigger_block/4`'s idx_name
lookup (lines 261-274 of `primary_key_sql.ex`), which omits it. Harmless (the condition is
always vacuously true given the predicate), but the inconsistency across the three near-copies
of this lookup is worth collapsing so a future edit to `qualifying_index_predicate/0` doesn't
quietly change three lookups' semantics in three different ways.

**Fix:** No functional change needed. Consider a comment at each site noting the guard is
logically implied by `qualifying_index_predicate/0`'s `indexprs IS NULL`, or extracting the
whole idx_name-lookup WHERE-clause fragment into one shared helper (as
`override_index_key_set_sql/0` and `qualifying_index_predicate/0` already are) so all three
call sites can never drift.

### IN-02: `CoveragePolicy.partition_findings/2` gates purely on bare table name, which is only safe because callers always pre-filter `trigger_findings/1` to one schema

**File:** `lib/threadline/verify/coverage_policy.ex:69-84`, `lib/mix/tasks/threadline.verify_coverage.ex:73-85`

**Issue:** `partition_findings/2` buckets a finding as `:gated` purely by
`MapSet.member?(expected, f.table)` — schema is never consulted. This is safe today only
because `Mix.Tasks.Threadline.VerifyCoverage.run/1` always calls
`Threadline.Health.trigger_findings(repo: repo, schema: schema)` with a single schema (default
`"public"`), so within one invocation every returned finding's `table` values are already
schema-disambiguated by construction (no two findings in one run can share a bare table name
across schemas, because `:schema` was passed as a single string). This is fine, but it is an
implicit invariant that lives in the caller, not the policy module itself — `partition_findings/2`
would silently misattribute gating across schemas if ever called with `findings` gathered
across more than one schema (e.g. a future `--all-schemas` task, mentioned as a deferred idea
in the CONTEXT). Not a bug in the code as shipped; flagged so the invariant is documented or
enforced if `partition_findings/2` is ever reused outside this single-schema call path.

**Fix:** Add a moduledoc/doc note on `partition_findings/2` stating the single-schema
precondition explicitly (mirroring `violations/2`'s existing `expected_tables` contract doc),
so a future caller passing multi-schema findings doesn't reintroduce this bug silently.

---

_Reviewed: 2026-09-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
