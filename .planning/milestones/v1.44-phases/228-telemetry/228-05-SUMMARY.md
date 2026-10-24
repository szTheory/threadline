---
phase: 228-telemetry
plan: 05
subsystem: telemetry
tags: [telemetry, documentation, doc-contract, ecto, guide]

requires:
  - phase: 228-telemetry (plan 01)
    provides: "Threadline.Telemetry @events registry, __events__/0"
  - phase: 228-telemetry (plan 02)
    provides: "[:threadline, :export, :completed|:failed]"
  - phase: 228-telemetry (plan 03)
    provides: "[:threadline, :retention, :purge, :start|:stop|:exception], [:threadline, :retention, :batch_purged]"
provides:
  - "guides/telemetry.md: 14-row event table, per-family attach_many examples, a telemetry_metrics example, handler-safety/cardinality/redaction warnings, and the [:my_app, :repo, :query] repo-query recipe — registered in ExDoc and the guide graph (20-node graph), routed from guides/operator-surface.md"
  - "Threadline.Telemetry moduledoc rewritten to the same 14-row table, hand-written and linked to the guide (D-15)"
  - "test/threadline/telemetry_doc_contract_test.exs: parses both tables, asserts the row set equals __events__/0 exactly and non-vacuously"
  - "test/threadline/telemetry_repo_query_recipe_test.exs (5 tests): proves the schema-source allowlist, the no-prefix source literal, the nil-source cases (raw SQL, subquery-rooted count), capture's invisibility to repo telemetry, and the metadata.params leak"
  - "guides/operator-surface.md: authorize-event sentence links the guide; health error sentence corrected to %{exception: module} (D-17)"
affects: [228-06]

actuals:
  tokens: 8450
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Hand-written doc tables kept honest by a parity test, not generation: both the moduledoc table and the guide table are typed by hand (D-15 — generation from __events__/0 would make the test tautological), and telemetry_doc_contract_test.exs parses each with a tiny markdown-table scanner, comparing MapSets of {name, measurement-keys, metadata-keys, when} against the registry"
    - "Repo-query caveats proven, not asserted: the guide's 'Observing Threadline's queries' section states only what telemetry_repo_query_recipe_test.exs demonstrated against a real Threadline.Test.Repo query event — including the one surprising fact (capture's own trigger-side writes never appear as their own repo query event, because they run inside PostgreSQL as part of the single statement the host application issued)"

key-files:
  created:
    - test/threadline/telemetry_doc_contract_test.exs
    - test/threadline/telemetry_repo_query_recipe_test.exs
    - guides/telemetry.md
  modified:
    - lib/threadline/telemetry.ex
    - guides/operator-surface.md
    - mix.exs
    - test/threadline/guide_graph_contract_test.exs
    - test/threadline/public_surface_contract_test.exs
    - README.md
    - CHANGELOG.md

key-decisions:
  - "The repo-query recipe test uses Repo.insert_all/3 (not raw Repo.query!/2) to prove the host-table-source caveat, because Ecto only attaches a :source to queries it compiles from an Ecto.Query/schema — a raw SQL string never carries :source regardless of which table it targets. This matches what the guide's caveats actually claim: :source is nil for raw SQL in general, and capture's own writes (always raw, from inside the trigger function) are correspondingly invisible, not merely absent from metadata."
  - "guides/telemetry.md's Next steps distinct successor is production-checklist.md (over incident-playbook.md): production-checklist.md already carries the telemetry alert-on-failure bullet, so routing there closes a loop the guide graph can verify instead of adding a new one."

requirements-completed: [TELE-04]

coverage:
  - id: D1
    description: "guides/telemetry.md exists as an ExDoc Operate extra, is in the guide_graph_contract_test operate lane (20-node graph), is routed from guides/operator-surface.md, and ends with a ## Next steps section linking back to the landing and to production-checklist.md as a distinct successor"
    requirement: TELE-04
    verification:
      - kind: unit
        ref: "test/threadline/guide_graph_contract_test.exs#all 20 guides form one complete intent-led graph"
        status: pass
      - kind: unit
        ref: "mix docs (no warning naming telemetry.md)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Threadline.Telemetry moduledoc's event list is replaced by one hand-written 14-row markdown table covering every registered event, linking to the guide"
    requirement: TELE-04
    verification:
      - kind: unit
        ref: "test/threadline/telemetry_doc_contract_test.exs#the moduledoc table is non-vacuous and matches the registry exactly"
        status: pass
    human_judgment: false
  - id: D3
    description: "guides/telemetry.md sections in order: event table; one attach_many per family; a telemetry_metrics example with unit {:native, :millisecond} and tags [:dry_run]; handlers-must-not-raise; cardinality; redaction side-door warning; the [:my_app, :repo, :query] recipe"
    requirement: TELE-04
    verification:
      - kind: unit
        ref: "test/threadline/telemetry_doc_contract_test.exs#the guide table is non-vacuous and matches the registry exactly"
        status: pass
      - kind: other
        ref: "grep -c attach_many guides/telemetry.md == 7; grep -c 'unit: {:native, :millisecond}' == 2; grep -c '[:telemetry, :handler, :failure]' == 1"
        status: pass
    human_judgment: false
  - id: D4
    description: "A doc-parity test parses both tables and requires each row set to equal Threadline.Telemetry.__events__/0, derived from the registry rather than hand-typed; proved red on a deliberate one-row mutation, then reverted"
    requirement: TELE-04
    verification:
      - kind: unit
        ref: "test/threadline/telemetry_doc_contract_test.exs (2 tests, both pass; manually confirmed red on a one-row guide mutation before committing the guide content, reverted before commit)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The [:my_app, :repo, :query] recipe matches metadata.source in ~w(audit_changes audit_transactions audit_actions), and every caveat it states is proven by a test: :source is the bare table name with no prefix; nil for raw SQL and a subquery root; capture never appears in repo telemetry; :params carry plaintext bind values"
    requirement: TELE-04
    verification:
      - kind: unit
        ref: "test/threadline/telemetry_repo_query_recipe_test.exs (5 tests)"
        status: pass
    human_judgment: false
  - id: D6
    description: "guides/operator-surface.md links the authorize-event sentence to the telemetry guide and its health-error sentence says %{exception: module}"
    requirement: TELE-04
    verification:
      - kind: unit
        ref: "grep -c telemetry.md guides/operator-surface.md >= 1; grep -c 'error: message' guides/operator-surface.md == 0"
        status: pass
    human_judgment: false
  - id: D7
    description: "CHANGELOG ## Unreleased — highlights gains a ### Added section after ### Breaking changes, adopter language, no planning vocabulary, describing the new export/retention events and the telemetry guide"
    requirement: TELE-04
    verification:
      - kind: unit
        ref: "awk-scoped grep: '^### Added' appears exactly once under ## Unreleased — highlights"
        status: pass
    human_judgment: false

duration: ~1h10m
completed: 2026-10-02
status: complete
---

# Phase 228 Plan 05: Telemetry Documentation and Repo-Query Recipe Summary

**One documented contract for all fourteen telemetry events — a 14-row table in both the `Threadline.Telemetry` moduledoc and the new `guides/telemetry.md`, kept honest by a doc-parity test derived from `__events__/0`, plus a repo-query recipe whose every caveat is proven against a real database.**

## Performance

- **Duration:** ~1h10m
- **Completed:** 2026-10-02
- **Tasks:** 3/3 completed
- **Files modified:** 10 (3 created, 7 modified)

## Accomplishments

- **Tracer (Task 1):** `guides/telemetry.md` created with an intro, the 14-row event table, and a terminal `## Next steps`; registered as an ExDoc extra and added to the Operate group regex in `mix.exs`; added to `guide_graph_contract_test.exs`'s `@lanes.operate` with the lane-count assertions, test name, and outside-graph message bumped from 19 to 20; added to `public_surface_contract_test.exs`'s `@local_reference_owners.public_doc_refs_operate` with the local-extras count bumped from 23 to 24; `guides/operator-surface.md`'s authorize-event sentence now links the guide, and its health-error sentence was corrected from the stale `%{error: message}` to the actual `%{exception: module}` shape (D-17).
- **Task 2:** `Threadline.Telemetry`'s moduledoc replaced its partial five-bullet prose list with the same hand-written 14-row table used in the guide (D-15 — hand-written so the parity test is non-tautological), kept the `[:threadline, :health, :findings_checked]` literal `health_findings_doc_contract_test.exs` greps for, and kept the existing `## Usage` attach example. The guide gained, in order: `## Attaching handlers` (one `attach_many` example per family — capture, health, export, retention, operator surface — with the export/retention sections also stating the D-04/D-08/D-10/D-11 facts about where those events come from and what their counts mean), `## Metrics with telemetry_metrics` (adopter code; `unit: {:native, :millisecond}` on export/purge durations, `tags: [:dry_run]` on the purge-stop summary), `## Handlers must not raise` (the `attach_many`-wide detach semantics plus `[:telemetry, :handler, :failure]`), `## Cardinality` (id-shaped values, and the `scope_keys`-is-keys-not-values caveat), and `## Keep row data out of your handlers` (the redaction side door). `test/threadline/telemetry_doc_contract_test.exs` parses both tables with a small markdown-table scanner (filter rows starting with a backtick, split on `|`, `Code.string_to_quoted!/1` the event-name cell, backtick-word-scan the key cells, em dash means no keys) and asserts the parsed `MapSet` of `{name, measurements, metadata, when}` rows equals the one built from `__events__/0`, non-vacuously (row count == `length(__events__())`). Proved red locally: mutated one guide row to add an extra measurement key, confirmed the guide-table test failed with a clear diff, then reverted before committing. README's Operate list and CHANGELOG's `## Unreleased — highlights` → `### Added` (placed directly after `### Breaking changes`) document the new export/retention events, the moduledoc table, and the guide in adopter language.
- **Task 3:** `guides/telemetry.md` gained `## Observing Threadline's queries`, stating the `[:my_app, :repo, :query]` recipe and its caveats exactly as proven by the new `test/threadline/telemetry_repo_query_recipe_test.exs` (5 tests, `async: false`, `attach_telemetry!/1` on `Keyword.fetch!(Repo.config(), :telemetry_prefix) ++ [:query]`): (1) the three capture/semantics schema sources sort to exactly `~w(audit_actions audit_changes audit_transactions)`, matching the guide's literal; (2) `Repo.all(AuditChange, repo_opts("threadline"))` emits `metadata.source == "audit_changes"` with no storage-schema prefix leaking into the value; (3) `Repo.query!("SELECT 1")` and `Export.count_matching/2` with `cap: 1` (which routes through a `subquery/1`-rooted count) both report `source == nil`; (4) `Repo.insert_all/3` against a real trigger-audited table reports only that table as source, while the PostgreSQL trigger's own writes to `audit_changes`/`audit_transactions` — happening entirely inside the database as part of executing that one statement — never surface as their own repo query event (proven, not just claimed: `AuditChange` row confirmed written afterward via `Repo.all(AuditChange, repo_opts("threadline"))`); (5) a pinned bind value passed to `Repo.query!/2` appears verbatim in `metadata.params`, proving the leak the guide's redaction warning cross-references. The test deliberately uses `Repo.insert_all/3` rather than raw `Repo.query!/2` for case (4), because Ecto's `put_source/2` only attaches `:source` to queries compiled from an `Ecto.Query`/schema — a raw SQL string carries no `:source` key regardless of target table, which is exactly why case (3)'s raw-SQL assertion holds.
- Full `mix test`: 2702 tests (31 properties), 0 failures, 3 excluded. `mix compile --warnings-as-errors`, `mix format --check-formatted`, `mix verify.credo` (415 files, no issues), and `mix docs` (no warning) all clean.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — guide with event table + Next steps, registered in ExDoc and the guide graph** - `b9198896` (feat)
2. **Task 2: Moduledoc table, guide body sections, doc-parity test, README and CHANGELOG** - `3066e281` (test)
3. **Task 3: The `[:my_app, :repo, :query]` recipe and a test that proves each caveat** - `0f990c58` (test)

## Files Created/Modified

- `guides/telemetry.md` - new Operate guide: intro, 14-row event table, per-family `attach_many` examples, `telemetry_metrics` example, handler-safety/cardinality/redaction warnings, the repo-query recipe, Next steps
- `lib/threadline/telemetry.ex` - moduledoc rewritten to the same 14-row table with a link to the guide; `@events`/helper functions unchanged
- `test/threadline/telemetry_doc_contract_test.exs` - new: moduledoc/guide table parser + parity assertions against `__events__/0`
- `test/threadline/telemetry_repo_query_recipe_test.exs` - new: 5 tests proving the repo-query recipe's caveats against a real trigger-audited table
- `guides/operator-surface.md` - authorize-event sentence links the guide; health-error sentence corrected to `%{exception: module}`
- `mix.exs` - `guides/telemetry.md` added to ExDoc `extras` and the Operate group regex
- `test/threadline/guide_graph_contract_test.exs` - telemetry.md added to `@lanes.operate`; 19 → 20 in three places
- `test/threadline/public_surface_contract_test.exs` - telemetry.md added to `public_doc_refs_operate`; local-extras count 23 → 24
- `README.md` - Telemetry added to the Operate guide list
- `CHANGELOG.md` - `### Added` section under `## Unreleased — highlights`, directly after `### Breaking changes`

## Decisions Made

- See `key-decisions` in frontmatter: `Repo.insert_all/3` over raw SQL for the host-table-source proof; `production-checklist.md` chosen as the guide's distinct Next-steps successor over `incident-playbook.md` because it already carries the telemetry alert-on-failure bullet, closing an existing cross-reference instead of adding a new one.

## Deviations from Plan

**1. [Rule 1 - Bug] `test/threadline/telemetry_repo_query_recipe_test.exs` initially used `prefix: "threadline"` literals instead of the repository's `repo_opts/1` helper**
- **Found during:** Task 3, full-suite verification run
- **Issue:** Two `Repo.all(AuditChange, prefix: "threadline")` calls in the new test tripped `test/threadline/storage_schema_call_site_contract_test.exs`'s real-tree sweep for unprefixed-by-helper owned-schema Ecto call sites (D-02/D-05 — the same defect class that previously hid a real `pgbouncer_topology_test.exs` bug until that sweep existed).
- **Fix:** Both call sites now use `repo_opts("threadline")` (from `Threadline.StorageSchemaCase`, already imported via `Threadline.DataCase`), which produces the same `prefix:` value through the repository's designated helper.
- **Files modified:** `test/threadline/telemetry_repo_query_recipe_test.exs`
- **Verification:** `mix test test/threadline/telemetry_repo_query_recipe_test.exs test/threadline/storage_schema_call_site_contract_test.exs` (27 tests, 0 failures); confirmed again in the full `mix test` run (2702 tests, 0 failures)
- **Committed in:** `0f990c58` (fix folded into the Task 3 commit before it was ever pushed; never landed as a separate broken commit)

**2. [Rule 1 - Bug, credo] `apply/3` with a known arity in the schema-source test**
- **Found during:** Task 3, `mix verify.credo`
- **Issue:** `Enum.map(&apply(&1, :__schema__, [:source]))` tripped credo's refactoring-opportunity check for `apply/2`/`apply/3` with a statically known argument count.
- **Fix:** Replaced with a literal three-element list of direct `Module.__schema__(:source)` calls.
- **Files modified:** `test/threadline/telemetry_repo_query_recipe_test.exs`
- **Verification:** `mix verify.credo` clean (415 files, 0 issues)
- **Committed in:** `0f990c58`

---

**Total deviations:** 2 auto-fixed (both Rule 1, both caught by local verification before the task commit landed — neither reached a committed state in broken form)
**Impact on plan:** No scope creep; both fixes were required for the plan's own stated verification commands to pass honestly.

## Issues Encountered

None blocking.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

TELE-04 is closed: every telemetry event is documented in exactly two places (the moduledoc and the guide), a test derives both from `Threadline.Telemetry.__events__/0` so they cannot silently drift from the code, and the host-repo query-observation recipe's every caveat is proven against a real database rather than merely asserted. Plan 228-06 (EVIDENCE.md assembly + maintainer push/dispatch checkpoint) can cite this plan's doc-parity and repo-query-recipe tests directly; no further telemetry documentation or registry changes are needed from this plan.

---
*Phase: 228-telemetry*
*Completed: 2026-10-02*

## Self-Check: PASSED

All 10 created/modified files confirmed present on disk; all 3 task commit
hashes (`b9198896`, `3066e281`, `0f990c58`) confirmed in `git log`.
