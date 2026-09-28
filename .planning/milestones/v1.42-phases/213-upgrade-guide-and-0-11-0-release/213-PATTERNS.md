# Phase 213: Upgrade Guide and 0.11.0 Release - Pattern Map

**Mapped:** 2026-09-26
**Files analyzed:** 10 (new/modified)
**Analogs found:** 10 / 10

All analog paths below were checked with `git ls-files` and are tracked source
(none are gitignored mirrors).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|---------------|
| `guides/upgrading-to-0.11.md` | doc (new guide) | request-response (prose, adopter-run steps) | `guides/upgrade-path.md` | role-match (same guide family, different scope: satellite step-by-step vs. summary matrix) |
| `guides/upgrade-path.md` (modify) | doc | request-response | itself, "0.9.x → 0.10.x" bullet (lines 109-115) | exact (copy the existing per-minor bullet shape verbatim) |
| `CHANGELOG.md` (modify) | doc / config | event-driven (release notes keyed off shipped changes) | itself, `## Unreleased — highlights` → `### Breaking changes` section (lines 19-30) | exact |
| `mix.exs` (modify: `:docs, :extras` + `groups_for_extras`) | config | CRUD (add one list entry + one regex alternative) | itself, lines 480-524 | exact |
| `test/threadline/upgrading_to_0_11_doc_contract_test.exs` | test (doc-contract) | request-response (string/structural assertions on a guide) | `test/threadline/upgrade_path_doc_contract_test.exs` | exact |
| `test/threadline/guide_graph_contract_test.exs` (modify) | test (doc-contract) | request-response | itself, `@lanes.adopt` list + `length(assigned) == 18` (lines 5-20, 68-72) | exact |
| `test/threadline/changelog_contract_test.exs` (modify) | test (doc-contract) | request-response | itself, `@breaking_section_regex`/security-heading-adjacent assertions (lines 45-46, 99-123) | exact |
| `test/threadline/upgrade_backfill_test.exs` | test (real-PG integration) | batch / transform (extract SQL from guide markers, execute against seeded rows) | `test/threadline/capture/legacy_trigger_regeneration_test.exs` | role-match (real-PG fixture-seed-then-assert pattern; this one adds guide-text extraction, which has no existing analog) |
| `test/threadline/upgrade_rollback_test.exs` | test (real-PG integration, catalog) | batch / transform (down-migration + catalog scan) | `test/threadline/capture/legacy_trigger_regeneration_test.exs` (its `assert_regenerates_in_place!` up/down pattern) | role-match (down-migration precedent exists; the `pg_proc`/`pg_trigger` orphan-scan and foreign-trigger-survives assertions are net-new, no analog) |
| `test/support/legacy_trigger_sql.ex` (extend, if a new fixture shape is needed) | test-support / utility | file-I/O (renders frozen SQL text) | itself | exact |

## Pattern Assignments

### `guides/upgrading-to-0.11.md` (doc, new guide)

**Analog:** `guides/upgrade-path.md`

**Structural heading pattern** — `upgrade-path.md` uses `##`-level sections that the doc-contract test pins verbatim (`test/threadline/upgrade_path_doc_contract_test.exs:8-16`). Mirror this: pick fixed `##` headings for the new guide and pin every one of them in the new contract test, e.g.:

```markdown
## Who this guide is for
## Before you start
## Step 1: Regenerate triggers
## Step 2: Migrate
## Step 3: Add the row-history index
## Step 4: Verify coverage
## Step 5 (optional): Backfill unresolved primary keys
## What cannot be recovered
## Facts you need before you start
## See also
```

**Per-minor bullet to copy into `guides/upgrade-path.md`** (D-01) — copy this exact shape from `guides/upgrade-path.md:109-115` (the "0.9.x → 0.10.x" bullet), which is itself under `test/threadline/upgrade_path_doc_contract_test.exs:196-211` (must contain the arrow/ASCII form, cite `CHANGELOG.md`, and the mandatory `"nothing required"` reassurance string somewhere in the guide):

```markdown
- **0.9.x → 0.10.x**: A documented public surface, the new `storage_schema` seam, and an operator surface with a theme lane and row-level deep links. Breaking changes: **None**. Required migration: **None**. Config changes: **None required** — ... Unlike every earlier bump in this list, this one is **not** a nothing-required bump: four adopter actions remain.
  - **S3 export adopters** — ...
  - ...
  Per lane: `capture-only` adopters can be touched by ... See `CHANGELOG.md` `[0.10.0]`.
```

Write the new `0.10.x → 0.11.x` bullet in this same shape: lead sentence, `Breaking changes:` / `Required migration:` / `Config changes:` lines, then a bulleted list of concrete adopter actions, then `See CHANGELOG.md [0.11.0]. Full procedure: guides/upgrading-to-0.11.md.` (link required by D-01).

**Vocabulary constraint (critical, cross-cutting):** neither this guide nor the CHANGELOG entry may contain phase numbers, decision IDs, or requirement-ID prefixes — `test/threadline/release_artifact_contract_test.exs:311-314` scans the entire built Hex tarball (guides included) and fails the release on any match of `Phase \d+`, `phase\d+`, `D-\d{2,}`, or the listed requirement prefixes. Verify with:
```
grep -riE '\bphase\s?[0-9]+\b|\bD-[0-9]{2,}\b' guides/upgrading-to-0.11.md guides/upgrade-path.md CHANGELOG.md
```

**Guide registration — all three points must be updated together** (`mix.exs` pattern below covers point 1; `guide_graph_contract_test.exs` pattern covers point 2; point 3 is auto-satisfied once 1 is done but must be verified with `mix test test/threadline/release_artifact_contract_test.exs`).

---

### `CHANGELOG.md` (modify — security note, D-05)

**Analog:** itself, existing `### Breaking changes` block under `## Unreleased — highlights` (lines 19-30, quoted above).

**Placement pattern:** add a new `### Security` heading. `changelog_contract_test.exs`'s ordering assertion (lines 99-123) only requires `### Breaking changes` / `### Required action` to precede any of `### Added|Changed|Fixed|Deprecated|Removed|Features|Bug Fixes` — a `### Security` heading is not in either regex, so place it directly after `### Breaking changes` / before the feature-tour headings to read naturally, and extend `changelog_contract_test.exs` with a new assertion pinning the heading text and its presence (mirror the existing `test "the newest release entry answers breaking changes..."` structure, lines 99-123, for the new pinned assertion).

**Wording pattern (domain-first, no IDs)** — model on the existing Breaking-changes prose style (mechanism, symptom, fix, all in plain domain language, e.g. lines 26-30 above): "installs where two audited tables were configured to share one per-table capture function" → detection (`mix threadline.health.coverage`, finding code `shared_capture_function`) → fix (regenerate all affected tables together, e.g. `mix threadline.gen.triggers --tables a,b`).

**Heading rewrite (D-12), NOT done in this phase's WIP commits:** `## Unreleased — highlights` → `## [0.11.0] - <date>` happens only on the landing branch, per `test "the human changelog contains at least one dated release entry"` (lines 70-80) and `@dated_entry_regex` (line 33). Do this last, at landing time, not while drafting the guide/security note.

---

### `mix.exs` (modify — guide registration point 1 of 3)

**Analog:** itself, `extras:` list and `groups_for_extras:` (lines 480-524, quoted above).

**Pattern:** add `"guides/upgrading-to-0.11.md"` to the `extras:` list (anywhere; order is cosmetic there except that `Overview`/`Integrations` groups must still match first per the comment at lines 506-512), and add `upgrading-to-0\.11` as an alternative inside the existing `Adopt:` regex at line 518-519:

```elixir
Adopt:
  ~r{^guides/(getting-started-saas|production-checklist|brownfield-continuity|integration-contracts|local-docker-dx|upgrade-path|upgrading-to-0\.11|configuration-and-commands)\.md$|/examples/threadline_phoenix/README\.md$},
```

---

### `test/threadline/upgrading_to_0_11_doc_contract_test.exs` (new)

**Analog:** `test/threadline/upgrade_path_doc_contract_test.exs` (full file read, 224 lines).

**Imports/module shape:**
```elixir
defmodule Threadline.UpgradingTo011DocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "..." do
    guide = File.read!("guides/upgrading-to-0.11.md")
    assert String.contains?(guide, "## Step 1: Regenerate triggers")
    ...
  end
end
```

**Core pattern** — one `String.contains?`-per-fact test grouped by concern (structure, then each D-02/D-04 fact), mirroring `upgrade_path_doc_contract_test.exs`'s test names ("... guide keeps the locked section architecture", "... guide locks ... language"). Per D-06, pin these literal commands verbatim:
```elixir
assert String.contains?(guide, "mix threadline.gen.triggers --tables")
assert String.contains?(guide, "mix threadline.gen.row_history_index")
assert String.contains?(guide, "mix threadline.verify_coverage")
assert String.contains?(guide, "<!-- threadline:backfill-sql:start -->")
assert String.contains?(guide, "<!-- threadline:backfill-sql:end -->")
```

**Vocabulary-refuting pattern** — copy the negative-assertion style from `upgrade_path_doc_contract_test.exs:213-223` ("refutes aspirational and product-milestone tokens"):
```elixir
test "guide carries no phase or decision vocabulary" do
  guide = File.read!("guides/upgrading-to-0.11.md")
  refute Regex.match?(~r/\bphase\s?[0-9]+\b/i, guide)
  refute Regex.match?(~r/\bD-[0-9]{2,}\b/, guide)
end
```

**Registration assertion** — copy line 160-163 verbatim, retargeted:
```elixir
test "mix.exs exposes the new guide in ExDoc extras" do
  mix_exs = File.read!("mix.exs")
  assert String.contains?(mix_exs, "\"guides/upgrading-to-0.11.md\"")
end
```

---

### `test/threadline/guide_graph_contract_test.exs` (modify)

**Analog:** itself (lines 5-20 for `@lanes`, lines 68-72 for the count assertion, quoted above).

**Pattern:** add `"guides/upgrading-to-0.11.md"` to `@lanes.adopt` (line ~15) and bump `assert length(assigned) == 18` to `19` (line 72). The `configured == on_disk` assertion (lines 75-80) needs no separate edit — it self-verifies once `mix.exs`'s `extras:` list is updated.

---

### `test/threadline/changelog_contract_test.exs` (modify — pin the Security heading)

**Analog:** itself, `@breaking_section_regex`/`@feature_tour_section_regex` definitions (lines 45-46) and the ordering test (lines 99-123).

**Pattern:** add a new module attribute and test following the exact style of the existing ordering test:
```elixir
@security_section_regex ~r/^### Security\b/m

test "the newest release entry documents the shared-capture-function security note" do
  body = newest_entry_body()
  assert Regex.match?(@security_section_regex, body), "..."
  assert body =~ "shared_capture_function"
  assert body =~ "mix threadline.health.coverage"
end
```
Reuse `newest_entry_body/0` (private helper, line 58) — do not re-implement entry scoping.

---

### `test/threadline/upgrade_backfill_test.exs` (new, real-PG integration)

**Analog:** `test/threadline/capture/legacy_trigger_regeneration_test.exs` (full file, 290 lines) for the seed/regenerate/assert real-PG harness pattern, plus `test/support/legacy_trigger_sql.ex` and `test/support/migration_harness.ex` for the fixture primitives.

**Module shape / setup pattern** (copy from `legacy_trigger_regeneration_test.exs:1-82`):
```elixir
use Threadline.DataCase, async: false

alias Threadline.Capture.{AuditChange, AuditTransaction, Naming, TriggerSQL}
alias Threadline.StorageSchema
alias Threadline.Test.LegacyTriggerSQL
alias Threadline.Test.MigrationHarness, as: Harness

setup do
  # tmp migrations dir, drop_all!/create tables, install 0.10.2 legacy
  # trigger via LegacyTriggerSQL.v0_10_2_create_trigger/3, seed rows with
  # {"id": null}/{} table_pk, on_exit cleanup (mirror lines 38-82)
end
```

**Seeding a 0.10.x install** — reuse `LegacyTriggerSQL.v0_10_2_create_trigger/3` and `v0_10_2_install_function/2` (`test/support/legacy_trigger_sql.ex:45,78`) exactly as `legacy_trigger_regeneration_test.exs:137-141` does, to reproduce the pre-210 `{"id": null}` capture bug for INSERT/UPDATE/DELETE.

**Regenerate-then-assert pattern** — reuse `Harness.generate!/2` + `Harness.migrate_up/1` + `Harness.migrate_down/1` (`test/support/migration_harness.ex:25,48,51`), matching the call shape in `legacy_trigger_regeneration_test.exs:174-176,189`.

**Guide-marker extraction (new — no existing analog)** — write a small private helper, not a dependency:
```elixir
defp backfill_sql_from_guide! do
  guide = File.read!("guides/upgrading-to-0.11.md")
  [_, rest] = String.split(guide, "<!-- threadline:backfill-sql:start -->", parts: 2)
  [sql_block, _] = String.split(rest, "<!-- threadline:backfill-sql:end -->", parts: 2)
  sql_block
  |> String.replace(~r/```sql\n?/, "")
  |> String.replace(~r/```\n?/, "")
end
```
Then substitute placeholders (`<storage_schema>`, `<host_schema>`, `<host_table>`, `<key_col>`, `<batch_size>`) via `String.replace/3` per fixture, and loop-execute via `Repo.query!/2` until `%{num_rows: 0}` (bounded `Enum.reduce_while(1..20, ...)`), per RESEARCH.md's Code Examples section.

**Verified backfill SQL to embed in the guide markers** (live-verified in RESEARCH.md against `threadline_test`; copy this shape into the guide, substitute for the composite case):
```sql
UPDATE <storage_schema>.audit_changes
SET table_pk = jsonb_build_object('<key_col>', data_after ->> '<key_col>')
WHERE id IN (
  SELECT id FROM <storage_schema>.audit_changes
  WHERE table_schema = '<host_schema>' AND table_name = '<host_table>'
    AND op IN ('insert', 'update')
    AND (table_pk = '{"id": null}'::jsonb OR table_pk = '{}'::jsonb)
    AND data_after ? '<key_col>'
    AND data_after ->> '<key_col>' IS NOT NULL
  LIMIT <batch_size>
);
```
Cross-check the `jsonb_build_object(..., data_after ->> '<col>', ...)` shape against the current trigger's own key-build logic, `lib/threadline/capture/primary_key_sql.ex:31-49` (`row_key_statements/0`, quoted in full in RESEARCH.md) — same per-column `->>` shape, so backfilled rows converge to what a regenerated trigger would have written (jsonb equality is order-independent).

**Assertions to copy** — `AuditChange |> where(...) |> Repo.all(repo_opts())` pattern from `legacy_trigger_regeneration_test.exs:246-249` (`insert_and_capture!/1`) for reading back rows and checking `data_after`/`table_pk` after the backfill runs.

---

### `test/threadline/upgrade_rollback_test.exs` (new, real-PG integration, D-09)

**Analog:** `test/threadline/capture/legacy_trigger_regeneration_test.exs`'s `assert_regenerates_in_place!/3` (lines 199-225) for the up/down migration shape; no existing analog for the catalog-orphan scan itself (confirmed absent by grep in RESEARCH.md).

**Down-migration pattern to copy:**
```elixir
assert {:ok, _log} = Harness.migrate_up(file)
# ... seed a foreign (non-Threadline) trigger on an audited and an unaudited table first
assert {:ok, _log} = Harness.migrate_down(file)  # or Ecto.Migrator down all: true, per D-09
```

**New catalog-orphan assertion (net-new SQL, modeled on `TriggerSQL.drop_function_if_unused/2`'s generated join, per RESEARCH.md)**:
```sql
SELECT n.nspname, p.proname
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = $1
  AND p.proname LIKE 'threadline_capture_changes%'
  AND NOT EXISTS (
    SELECT 1 FROM pg_trigger t WHERE t.tgfoid = p.oid AND t.tgparentid = 0
  );
```
Assert this returns `[]` after the all-the-way-down rollback. For the foreign-trigger-survives assertion, reuse `Harness.threadline_triggers/2`'s exact filter (`test/support/migration_harness.ex:152`) and additionally query the foreign trigger's own name directly (it will never match the `threadline_audit_%`/`threadline_capture_changes%` filters, so absence from `Harness.threadline_triggers/2`'s result is not itself proof — query `pg_trigger` for the foreign trigger's own `tgname` before and after and assert equality).

**Fixture note (Pitfall 3, cross-cutting):** the shared-capture-function fixture in this test must use the OLD pre-209 `CASCADE` `down` shape (`test/support/legacy_trigger_sql.ex`'s `v0_10_2_create_trigger`/`migration_source` helpers, lines 45,50), not the current generator's output, to prove the new upgrade-time behavior (regenerate together) sidesteps the historical cascade hazard.

---

## Shared Patterns

### Real-PG test harness (all new integration tests)
**Source:** `test/support/migration_harness.ex` (full file, `generate!/2`, `migrate_up/1`, `migrate_down/1`, `cleanup!/1`, catalog helpers `trigger_function/2`, `threadline_triggers/2`, `function_exists?/1`)
**Apply to:** `upgrade_backfill_test.exs`, `upgrade_rollback_test.exs`
```elixir
# test/support/migration_harness.ex:25
def generate!(tmp, args) do
  ...
end
# :36 migration_files/1, :48 migrate_up/1, :51 migrate_down/1, :91 cleanup!/1
```

### Frozen legacy SQL fixtures
**Source:** `test/support/legacy_trigger_sql.ex` (full file — `v0_9_create_trigger/2`, `v0_10_0_create_trigger/3`, `v0_10_2_create_trigger/3`, `v0_10_2_install_function/2`, `migration_source/3`)
**Apply to:** `upgrade_backfill_test.exs`, `upgrade_rollback_test.exs` — extend this module (not a new one) if a new fixture shape (e.g. a `timestamptz`-PK table, or a two-table shared-function pair) needs frozen SQL not already rendered here. No `git show` at test time (D-07).

### Doc-contract structural assertions
**Source:** `test/threadline/upgrade_path_doc_contract_test.exs` (full file)
**Apply to:** `test/threadline/upgrading_to_0_11_doc_contract_test.exs`
```elixir
use ExUnit.Case, async: true
test "..." do
  guide = File.read!("guides/upgrade-path.md")
  assert String.contains?(guide, "## Some Locked Heading")
end
```

### Vocabulary ban (no phase/decision/requirement IDs in shipped prose)
**Source:** `test/threadline/release_artifact_contract_test.exs:7-13,311-314` (existing, not modified — scans the whole built Hex tarball)
**Apply to:** `guides/upgrading-to-0.11.md`, `guides/upgrade-path.md`'s new bullet, `CHANGELOG.md`'s new Security note
```
grep -riE '\bphase\s?[0-9]+\b|\bD-[0-9]{2,}\b' <files>
```

### Guide registration (three independent enforcement points)
**Source:** `mix.exs:480-524` (extras + groups_for_extras), `test/threadline/guide_graph_contract_test.exs:5-20,68-80` (lanes + count + `configured == on_disk`), `test/threadline/release_artifact_contract_test.exs:71` (`guide_extras() == guides_on_disk()`, no separate edit needed but must be verified)
**Apply to:** `guides/upgrading-to-0.11.md`'s registration step — edit all three, verify with `mix test test/threadline/guide_graph_contract_test.exs test/threadline/release_artifact_contract_test.exs`.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| Guide-marker SQL extraction helper (inside `upgrade_backfill_test.exs`) | test utility | file-I/O + transform | No test in the repo yet extracts and executes a fenced code block from a guide (confirmed in RESEARCH.md); build the small string-split helper directly per the Code Examples section above, no dependency needed. |
| `pg_proc`/`pg_trigger` orphan-catalog scan (inside `upgrade_rollback_test.exs`) | test assertion | event-driven (catalog state after DDL) | No existing test queries the catalog post-`Ecto.Migrator.down` for orphaned functions or trigger survival (confirmed by grep across `test/` in RESEARCH.md); modeled on `TriggerSQL.drop_function_if_unused/2`'s generated `DO` block join shape (`lib/threadline/capture/trigger_sql.ex`), not on an existing test. |
| Maintainer hand-off command list (SUMMARY/VERIFICATION content) | doc / runbook | request-response (human-executed) | Not a source file; sourced from `CONTRIBUTING.md`, project memory `release-runbook.md`, and `.planning/phases/202-*/202-05-SUMMARY.md`'s `--match-head-commit` precedent — no code analog applies. |

## Metadata

**Analog search scope:** `guides/`, `test/threadline/*.exs`, `test/threadline/capture/*.exs`, `test/support/*.ex`, `lib/threadline/capture/*.ex`, `mix.exs`
**Files scanned:** ~15 (all read in full or targeted-range this session; several pre-verified in RESEARCH.md with exact line citations, re-confirmed here as tracked source)
**Pattern extraction date:** 2026-09-26
