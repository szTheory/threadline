# Phase 213: Upgrade Guide and 0.11.0 Release - Research

**Researched:** 2026-09-26
**Domain:** Elixir/Postgres upgrade documentation, doc-contract testing, release-please mechanics
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Phases 210-212 decisions stand (facts D-04 requires the guide to restate). Pre-1.0 versioning: `bump-minor-pre-major: true` is contract-enforced; a breaking change proposes 0.11.0, never 1.0.0. CHANGELOG split: `CHANGELOG.md` is human-owned, `CHANGELOG-GENERATED.md` is release-please's only write target. Release runbook: run `ci.all` AND a simulated bump before believing a release is green.

**Guide shape:** D-01 — the full 0.10.x → 0.11.0 procedure lives in a new `guides/upgrading-to-0.11.md`; `guides/upgrade-path.md` gains only the required 0.10.x → 0.11.x per-minor entry + link; the new guide is registered wherever guides are listed (mix.exs docs extras, guide graph contract, README if applicable). Reversible.

D-02 — step order (dependency-forced): (1) bump deps to `~> 0.11`; (2) regenerate triggers with `mix threadline.gen.triggers` per table, tables sharing a capture function regenerated together in one `--tables a,b` run; (3) `mix ecto.migrate`; (4) `mix threadline.gen.row_history_index` (concurrent, migrate, INVALID-index recovery included); (5) `mix threadline.verify_coverage` + `mix threadline.health.coverage`, confirm no error findings, show finding-code fixes; (6) optional backfill.

D-03 — backfill is plain SQL in the guide, no new Mix task. Scope: INSERT/UPDATE rows only, `table_pk` = `{"id": null}` or `{}`, from `data_after`. Encoding: trigger's text encoding, `jsonb_build_object('<col>', data_after ->> '<col>', ...)` in key order, never `->`. Idempotent (guarded on unresolved `table_pk`), batchable with a documented pattern. Never touches rows where any key column is absent/null in `data_after`. Unrecoverable rows stated explicitly: DELETE rows (no row image pre-0.11) and redaction-masked/excluded key columns. SQL wrapped in stable HTML-comment markers (`<!-- threadline:backfill-sql:start -->`…`end`); parameters (table, schema, key columns) exposed in a clearly marked substitutable form. Reversible (guide text; adopters run it themselves).

D-04 — facts the guide must state: PK types outside the allowlist refuse to regenerate (naming the column), keeping the legacy trigger; `{"id": null}` (legacy) and `{}` (0.11 unresolved) both mean "unresolved" — match both; `history/3`/`as_of/4` raise `ArgumentError` on wrong/nil/uncastable keys, composite keys take keyword list or map; `trigger_coverage/1` no longer counts disabled/replica-only triggers as covered (a passing gate can go red on upgrade — give the fix); `primary_key:` override goes in `config/config.exs` under `config :threadline, :trigger_capture, tables: %{...}`, needs a qualifying unique index; a key column in `mask`/`exclude` is refused; a fresh install already has the row-history index; point to the CHANGELOG security note.

D-05 — security note: CHANGELOG entry covering installs where two tables shared one per-table capture function (the phase 209 issue: cleanup/regeneration for one table could affect the other's capture or trigger). Gives detection command (`mix threadline.health.coverage`, code `shared_capture_function`) and fix (regenerate all affected tables together). Wording confirmed accurate against 209-CONTEXT.md/SUMMARYs — neither overstated nor understated. Placed in the human CHANGELOG's Unreleased section, under a Security heading, following repo CHANGELOG conventions. Costly once published (public release notes) — not reversible.

D-06 — doc contracts: extend the existing `*_doc_contract_test.exs` pattern. New contract for `upgrading-to-0.11.md` pins these literal commands: `mix threadline.gen.triggers --tables`, the together-regeneration rule, `mix threadline.gen.row_history_index`, `mix threadline.verify_coverage`, and the backfill markers. `upgrade_path_doc_contract_test.exs` pins the new per-minor entry and link. The CHANGELOG contract pins the security note heading.

**Upgrade/rollback proof (SC2):** D-07 — build the fixture from frozen `Threadline.Test.LegacyTriggerSQL` 0.10.2 SQL + `Threadline.Test.MigrationHarness`; extend `LegacyTriggerSQL` where a shape needs it; no `git show` at test time; the hex evaluator is not the primary proof.

D-08 — one root-suite real-PG test module seeds a 0.10.x install with: an `id`-keyed table; a non-`id`-keyed table with INSERT/UPDATE/DELETE captured as `{"id":null}`; a composite-key table; two tables sharing one per-table capture function (0.10.x shape); a `timestamptz`-PK table (must keep legacy trigger after upgrade). Runs the documented steps (regenerate, migrate, index, health with no error findings except documented timestamptz case, backfill SQL extracted from guide markers). Asserts: backfilled INSERT/UPDATE rows equal what a regenerated trigger writes and `history/3` finds them; DELETE rows untouched; a rerun of the backfill is a no-op.

D-09 — rollback: same module or sibling first creates a foreign (non-Threadline) host trigger on an audited table and an unaudited one; runs the full upgrade setup; runs `Ecto.Migrator` down to zero (`all: true`); asserts against the live catalog: no `threadline_capture_changes%` function remains that no trigger references (no orphans); every foreign trigger survives.

D-10 — tests live in the root suite, run under `mix test`, `mix verify.test`, `mix ci.all`; no new entrypoint; tests clean up their tables/functions/triggers/roles.

**Release (REL-03, SC3):** D-11 — local pre-land proof, all run and recorded with exit codes: `mix ci.all`; `mix verify.release`; `mix verify.bump_rehearsal` (release-lane only, NOT part of `ci.all`); `mix release.pins --check` or equivalent; `MIX_ENV=dev mix docs --warnings-as-errors`; `mix hex.build`; the CHANGELOG/version-truth/upgrade-path contracts; `mix verify.topology` and `mix verify.hex_evaluator` (CI jobs `ci.all` omits); the unscoped browser lane with the 8 known failures only.

D-12 — CHANGELOG heading: follow repo precedent (each human `## [x.y.z] - date` heading written before release); retitle `## Unreleased — highlights` to `## [0.11.0] - <landing date>` on the landing branch. Verify which convention applies against `changelog_contract_test.exs` and 0.10.2 history. Date set at landing time.

D-13 — landing branch: build via `gsd-pr-branch`, precedent of 0.10.0 (#43). Base on `origin/main`, carry milestone code/test/doc changes, filter out `.planning/`-only commits (squash body carries no phase IDs). Agent builds it **locally only** and verifies it: `ci.all` passes on it, diff check shows no `.planning/` paths and no phase-ID vocabulary in commit subjects. Maintainer chooses branch name at push time (suggest `land/v1.42`; warn a stale local `land/v1.41` exists). Reversible until pushed.

D-14 — squash title: `feat!: <summary>`, honest about breaking changes; `bump-minor-pre-major` makes it 0.11.0. Verify against the contract test. Suggested summary: `feat!: capture every primary-key shape, read it back exactly, and detect broken capture`. Final wording is Claude's discretion — conventional, free of phase/requirement IDs.

D-15 — maintainer hand-off: exact ordered command list in SUMMARY/VERIFICATION: (1) push branch; (2) `gh pr create`; (3) `gh pr checks`; (4) squash merge; (5) inspect release-please PR (expect exactly 0.11.0, phase-ID-free notes); (6) merge it with `--match-head-commit`; (7) approve `production-hex` via the `gh api .../pending_deployments` runbook command; (8) confirm publish and smoke; (9) merge the distribution-sync PR once green. Plus stray-branch deletion commands (maintainer actions): local `land/v1.41`; `origin/fix/branch-protection-after-ci`; `origin/phase-200/hosted-checkpoint`; `origin/release-please--branches--main` (only after 0.11.0 ships); `origin/release/sync-0.10.0-*` and `origin/release/sync-0.10.2-*`. Planner re-derives this list at execution time.

D-16 — phase is marked complete once every local truth is proven and hand-off is recorded. REL-03 stays **Pending**, with a "maintainer action" note, until the maintainer reports back.

**Hard boundary — never done by an agent:** push; PR creation; merge (`gh pr merge` is blocked anyway); approving the `production-hex` environment; hex publish; deleting remote branches. REL-03's post-merge truths are recorded as "maintainer action, pending" with exact commands, never marked verified until the maintainer reports SHAs and run IDs.

### Claude's Discretion

Guide prose and structure within D-02 to D-04, the backfill batch pattern, and the test module split. The exact squash title and PR body wording, with no phase or requirement IDs.

### Deferred Ideas (OUT OF SCOPE)

A `mix threadline.gen.backfill` task that emits a batched, encoding-safe backfill migration (add if adopters struggle with the SQL). A health finding that counts unresolved `table_pk` rows per table. A `--strict` health mode, an `:invalid_config` finding and `--all-schemas` (carried from phase 212). Widening the PK type allowlist. Operator-UI work.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-02 | An upgrade guide explains regenerating triggers, adding the row-history index concurrently, backfill SQL for INSERT/UPDATE rows captured as `{"id": null}`, which pre-0.11 rows cannot be recovered (DELETEs, redacted keys), and a CHANGELOG security note for shared-capture-function installs; doc-contract tests pin the regenerate and index steps. | Backfill SQL fully designed and live-verified (see "Pattern: Backfill SQL"); guide structure, registration points (3 enforcement locations), and doc-contract extension points identified with file:line citations; security-note mechanism and wording guidance sourced from 209-CONTEXT.md; unrecoverable-rows rationale (DELETE `data_after IS NULL`, redaction) confirmed live |
| REL-03 | 0.11.0 is released through release-please from a squash-landed PR with a clean title; `main` CI is green on the released SHA; no open PRs or stray branches left. | Full local pre-land command list confirmed to exist verbatim in `mix.exs`; `gsd-pr-branch` mechanics read in full (local-only, no auto-push); current repo state confirmed (`git rev-list --count HEAD..origin/main` = 0, no open PRs, exact stray-branch list); maintainer hand-off command sequence sourced from project memory + `CONTRIBUTING.md`, with the `gh api` environment-id caveat flagged as an assumption to re-verify |
</phase_requirements>

## Summary

This phase has almost no new library surface — it is prose (a guide + a CHANGELOG entry), one plain-SQL backfill block, two real-PG test modules, and a git/GitHub release lane the maintainer executes by hand. The high-value research here was **live-verifying the backfill SQL against the actual frozen 0.10.2 trigger** and **reading, not guessing, the exact doc-contract tests, guide registries, and release scripts this phase must satisfy** — several of which have hard-coded literals (a lane count of 18, a specific `pending_deployments` environment id, a banned-vocabulary regex list) that a plan written from memory would get wrong.

The backfill SQL was built and run against a live scratch table+trigger pair reproducing the exact 0.10.2 `{"id": null}` bug (single-column and composite-key cases), proved batchable and idempotent, and proved that it leaves DELETE rows and rows with a missing/null key column untouched. Its `jsonb_build_object(..., data_after ->> '<col>', ...)` shape was cross-checked against `Threadline.Capture.PrimaryKeySQL.row_key_statements/0` (`lib/threadline/capture/primary_key_sql.ex:29-46`, read this session) — the regenerated trigger builds `v_table_pk` with the *identical* `->>`-per-column shape, so the two converge to the same jsonb regardless of build order (jsonb equality is order-independent; PostgreSQL's own internal key ordering, verified live, sorts by length then lexicographically, so `tag_id` printed before `post_id` in one live output — this is a display/storage detail, not a match failure).

The CHANGELOG's `## Unreleased — highlights` section already contains nearly everything D-04 requires the guide to restate (breaking changes for HLTH-05, READ-02/READ-03, CAP-01..05, IDX-01) because phases 210-212 wrote it incrementally. The new guide's job is to sequence these into adopter steps, not re-derive facts. The security note (D-05) is new content with no CHANGELOG precedent for a `### Security` heading in this repo, and it must be written in "durable domain rationale," not planning vocabulary — `test/threadline/release_artifact_contract_test.exs:311-314` scans the **entire built Hex tarball** (guides included) for `Phase \d+`, `phase\d+`, `D-\d{2,}`, and several requirement-ID prefixes (not `REL-`, but `ADOPT|COMP|CRITIC|DATA|GREEN|GROUP|MECH|NAV|PROOF|SURFACE|WR`), and will fail the whole release if the new guide or the CHANGELOG entry leaks any of that vocabulary.

The new guide's registration is enforced in **three** separate places, not one: `mix.exs` `:docs, :extras` (a plain list), `test/threadline/guide_graph_contract_test.exs` `@lanes` map (hardcodes `assert length(assigned) == 18` — this literal must become 19), and `test/threadline/release_artifact_contract_test.exs:71` (`guide_extras() == guides_on_disk()`, no hardcoded count, but still requires the mix.exs entry). Missing any one of the three fails a different test.

**Primary recommendation:** Write the guide and the CHANGELOG security note as pure adopter-facing prose (no phase/decision/requirement vocabulary), register the new guide in all three enforcement points, build the backfill SQL exactly as verified below (parametrized on schema/table/key-columns, batched via `id IN (SELECT id ... LIMIT n)`, guarded on `{"id":null}`/`{}` and non-null key presence), and treat the release lane as a maintainer-executed runbook the phase only prepares and verifies locally — it never pushes, merges, or approves anything.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Backfill SQL execution | Database / Storage | — | Plain SQL an adopter runs directly against `audit_changes`; no application code involved (explicit non-goal: no `mix threadline.gen.backfill` task) |
| Trigger regeneration / index build | Database / Storage | Capture layer (Ecto migrations) | `mix threadline.gen.triggers` and `mix threadline.gen.row_history_index` already exist; the guide only sequences their invocation |
| Upgrade guide content | Docs / Exploration layer | — | Pure documentation; no runtime behavior change |
| CHANGELOG security note | Docs / Exploration layer | — | Human-owned `CHANGELOG.md`; release-please never touches it |
| Doc-contract enforcement | Test / CI | — | Existing `*_doc_contract_test.exs` pattern extended, not a new mechanism |
| Real-PG upgrade/rollback proof | Test / CI (root suite) | Database catalog (`pg_proc`/`pg_trigger`) | Uses `Threadline.Test.MigrationHarness` + `Threadline.Test.LegacyTriggerSQL`, both already exist |
| Release lane (push/PR/merge/publish) | Maintainer (human), CI | Release / CI layer | Hard-boundary per CONTEXT: agent prepares and verifies locally only |

## Package Legitimacy Audit

No new external packages are installed in this phase. `guides/upgrading-to-0.11.md` is a new Markdown file; the backfill is plain SQL; the two real-PG test modules use only existing test-support modules (`Threadline.Test.MigrationHarness`, `Threadline.Test.LegacyTriggerSQL`, `Ecto.Migrator`). **Package Legitimacy Gate: N/A — no packages installed.**

## Standard Stack

No new libraries. Everything needed already exists in the repo:

| Component | Location | Purpose |
|-----------|----------|---------|
| `Threadline.Test.LegacyTriggerSQL` | `test/support/legacy_trigger_sql.ex` | Frozen v0.9.0 / v0.10.0 / v0.10.2 trigger + install-function SQL renderers |
| `Threadline.Test.MigrationHarness` | `test/support/migration_harness.ex` | Compiles and runs a generated migration through real `Ecto.Migrator.up/4`/`down/4`; catalog helpers (`trigger_function/2`, `threadline_triggers/2`, `function_users/1`, `function_exists?/1`, `function_definition/1`) |
| `Threadline.Capture.PrimaryKeySQL.row_key_statements/0` | `lib/threadline/capture/primary_key_sql.ex:29-46` | The current (post-210) `v_table_pk` build logic the backfill SQL must match |
| `Threadline.StorageSchema` | `lib/threadline/storage_schema.ex` | `get/1` resolves the configured storage schema (default `"public"`; this repo's test config sets `"threadline"`) |
| `mix threadline.gen.triggers` / `mix threadline.gen.row_history_index` / `mix threadline.verify_coverage` / `mix threadline.health.coverage` | `lib/mix/tasks/threadline.*.ex` | The commands the guide sequences |
| `mix release.pins --check` | `lib/mix/tasks/release.pins.ex:16-18,50-54` | `--check` writes nothing, exits non-zero on drift — confirmed to exist with exactly this flag |
| `mix verify.release` / `mix verify.bump_rehearsal` | `mix.exs:227-244` | `verify.release` = `ensure_clean_tree!` + `bin/verify-release-shape` + `release_artifact_contract_test.exs` + `ci_topology_contract_test.exs` + `MIX_ENV=dev mix docs --warnings-as-errors` + `mix hex.build`; `verify.bump_rehearsal` = `bin/verify-bump-rehearsal` |

No installation step is needed.

## Architecture Patterns

### System Architecture Diagram

```
Adopter on 0.10.x
        │
        ▼
1. bump deps (~> 0.11)
        │
        ▼
2. mix threadline.gen.triggers --tables a,b   (siblings sharing a legacy
        │                                       capture function regenerated
        │                                       TOGETHER — see Security note)
        ▼
3. mix ecto.migrate
        │
        ▼
4. mix threadline.gen.row_history_index → mix ecto.migrate
   (CONCURRENTLY; INVALID-index recovery documented)
        │
        ▼
5. mix threadline.verify_coverage
   mix threadline.health.coverage        (confirm zero error findings,
        │                                  except documented timestamptz case)
        ▼
6. [optional] run backfill SQL from the guide's markers
   (INSERT/UPDATE rows with table_pk {"id":null} or {} only)
        │
        ▼
   history/3, as_of/4 now return backfilled + legacy + new rows uniformly
```

```
Landing branch build (local only, never pushed by the agent)
        │
        ▼
gsd-pr-branch: cherry-pick milestone commits onto origin/main,
filter .planning/phases|research|... (transient dirs), keep STATE/ROADMAP/etc.
        │
        ▼
Local verification: git diff --name-only shows 0 forbidden paths,
0 planning deletions; run `mix ci.all` IN PLACE on the checked-out branch
(same working tree — deps/_build already exist; do NOT use a worktree)
        │
        ▼
Hand off exact command list to maintainer (push → PR → merge → …)
REL-03 stays Pending until maintainer reports back
```

### Recommended Guide Structure (`guides/upgrading-to-0.11.md`)

Follow the step order fixed by D-02 exactly (it is dependency-forced: index needs migrated triggers; coverage check needs the index; backfill is optional and last). Register the guide as an `Adopt`-lane extra (see Don't Hand-Roll below for the exact three registration points).

```
guides/upgrading-to-0.11.md
├── ## Who this guide is for
├── ## Before you start (bump deps to ~> 0.11)
├── ## Step 1: Regenerate triggers
│     — mix threadline.gen.triggers --tables <table>
│     — tables sharing a legacy capture function: regenerate TOGETHER
│       (`--tables a,b`); cites the CHANGELOG Security section
├── ## Step 2: Migrate
│     — mix ecto.migrate
├── ## Step 3: Add the row-history index
│     — mix threadline.gen.row_history_index; mix ecto.migrate
│     — INVALID index recovery (DROP INDEX CONCURRENTLY IF EXISTS ...; retry)
├── ## Step 4: Verify coverage
│     — mix threadline.verify_coverage
│     — mix threadline.health.coverage (finding codes → fixes)
├── ## Step 5 (optional): Backfill unresolved primary keys
│     — <!-- threadline:backfill-sql:start --> ... <!-- threadline:backfill-sql:end -->
│     — parameters marked for substitution: schema, table, key columns
│     — before/after example against history/3
├── ## What cannot be recovered
│     — DELETE rows (no data_after stored pre-0.11)
│     — redacted/masked key columns (value never stored)
├── ## Facts you need before you start (D-04 restated)
│     — PK-type allowlist refusal; {"id":null} vs {} both mean unresolved;
│       ArgumentError on bad history/as_of keys; disabled/replica triggers
│       no longer count as covered; primary_key: config shape; masked-key
│       refusal; fresh installs already have the index
└── ## See also → CHANGELOG.md Security section, guides/upgrade-path.md
```

`guides/upgrade-path.md` gets ONLY the required per-minor entry + link (D-01), not the full procedure — it already has the "0.9.x → 0.10.x" precedent row shape to copy (`guides/upgrade-path.md`, "Current guidance by minor" section, read this session).

### Pattern: Backfill SQL (verified live against real PG)

**Verified live** against a scratch install of the frozen 0.10.2 global capture function (byte-identical to `Threadline.Test.LegacyTriggerSQL.v0_10_2_install_function/2`, applied directly since that module's own doc says it was copied verbatim from `git show v0.10.2:...`) on `postgres@localhost/threadline_test`. Scratch objects were created and dropped in the same session; nothing was left behind.

Single-column key (non-`id` PK named `post_uuid`):

```sql
-- Source: verified live, this session, against threadline_test.
-- Reproduced the exact 0.10.2 bug: INSERT/UPDATE on a table with no `id`
-- column captured table_pk = {"id": null}. DELETE captured data_after = NULL
-- (unrecoverable — no row image was ever stored for DELETE pre-0.11).
UPDATE <storage_schema>.audit_changes
SET table_pk = jsonb_build_object('post_uuid', data_after ->> 'post_uuid')
WHERE id IN (
  SELECT id
  FROM <storage_schema>.audit_changes
  WHERE table_schema = '<host_schema>'
    AND table_name = '<host_table>'
    AND op IN ('insert', 'update')
    AND (table_pk = '{"id": null}'::jsonb OR table_pk = '{}'::jsonb)
    AND data_after ? 'post_uuid'
    AND data_after ->> 'post_uuid' IS NOT NULL
  LIMIT <batch_size>
);
```

Composite key (verified live with `post_id`, `tag_id`):

```sql
UPDATE <storage_schema>.audit_changes
SET table_pk = jsonb_build_object(
  'post_id', data_after ->> 'post_id',
  'tag_id',  data_after ->> 'tag_id'
)
WHERE id IN (
  SELECT id
  FROM <storage_schema>.audit_changes
  WHERE table_schema = '<host_schema>'
    AND table_name = '<host_table>'
    AND op IN ('insert', 'update')
    AND (table_pk = '{"id": null}'::jsonb OR table_pk = '{}'::jsonb)
    AND data_after ?& array['post_id', 'tag_id']
    AND data_after ->> 'post_id' IS NOT NULL
    AND data_after ->> 'tag_id' IS NOT NULL
  LIMIT <batch_size>
);
```

**Live-verified properties** (this session, `psql` against `threadline_test`):
- Batch pattern (`id IN (SELECT id ... LIMIT n)`) resolved 3 unresolved rows across 3 batch runs of size 1, then a 4th run returned `UPDATE 0` — **idempotent by construction**: once a row's `table_pk` no longer matches `{"id":null}`/`{}` it drops out of the `WHERE` clause.
- DELETE rows (`op = 'delete'`, `data_after IS NULL`) were **never touched** — confirmed by direct query after the run.
- A row with a key column absent from `data_after` (simulating a missing/redacted column) was **never touched** — confirmed with a synthetic row (`data_after = '{"post_id": 3}'`, missing `tag_id`); the `?&`/`IS NOT NULL` guards correctly excluded it and it remained `{"id": null}` after the run.
- The `jsonb_build_object(..., data_after ->> '<col>', ...)` shape is structurally identical to what `PrimaryKeySQL.row_key_statements/0` builds at capture time (`v_table_pk := coalesce(v_table_pk, '{}'::jsonb) || jsonb_build_object(TG_ARGV[i], v_row ->> TG_ARGV[i])` per column, in `TG_ARGV` order) — **[VERIFIED: lib/threadline/capture/primary_key_sql.ex:29-46, read this session]**, quoted here verbatim: `` v_table_pk := coalesce(v_table_pk, '{}'::jsonb) || jsonb_build_object(TG_ARGV[i], v_row ->> TG_ARGV[i]); `` — so trigger-argument order (== declared/detected PK column order) is what the backfill's `jsonb_build_object` call order must follow for a composite key, even though jsonb equality does not depend on build order.
- Storage-schema qualification: use the placeholder convention already established in `guides/domain-reference.md` (`your_schema`/`your_table`, read this session) — NOT a literal `"public"` or `"threadline"`, since the storage schema is adopter-configured (`Threadline.StorageSchema.get/1`, defaults `"public"`).

### Pattern: Rollback catalog proof (D-09)

No test in the repo currently queries `pg_proc`/`pg_trigger` post-`Ecto.Migrator.down` to prove no orphan function remains and no foreign trigger was dropped — confirmed by grep across `test/` for `pg_proc`+`down` combinations; existing tests (`legacy_trigger_regeneration_test.exs`) only assert `threadline_triggers/2` counts, not a catalog-wide orphan scan. Build the assertion directly against `pg_proc`/`pg_trigger`/`pg_namespace`, mirroring the join shape already used in `TriggerSQL.drop_function_if_unused/2`'s generated `DO` block (`lib/threadline/capture/trigger_sql.ex`, the `SELECT string_agg(...) FROM pg_trigger t JOIN pg_class c ... WHERE t.tgfoid = fn` join), e.g.:

```sql
-- orphan Threadline capture functions: exist but no trigger's tgfoid references them
SELECT n.nspname, p.proname
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = $1  -- storage schema
  AND p.proname LIKE 'threadline_capture_changes%'
  AND NOT EXISTS (
    SELECT 1 FROM pg_trigger t WHERE t.tgfoid = p.oid AND t.tgparentid = 0
  );
```

A foreign (non-Threadline) trigger survives simply by never matching `tgname LIKE 'threadline_audit_%'` — reuse `MigrationHarness.threadline_triggers/2`'s exact filter and additionally assert the foreign trigger's own name/tgfoid is unchanged before/after the down.

### Recommended Test Module Split

- `test/threadline/upgrade_backfill_test.exs` (or similar) — extracts the guide's backfill SQL via the HTML-comment markers and runs it against seeded fixtures (D-08).
- `test/threadline/upgrade_rollback_test.exs` (or a `describe` block in the same module, per D-09's "same module, or a sibling") — the foreign-trigger + `Ecto.Migrator` all-the-way-down catalog proof.
- Both live in the root suite, run under `mix test`/`verify.test`/`ci.all` — no new alias (D-10).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Backfilling historic `table_pk` | A `mix threadline.gen.backfill` task | Plain SQL in the guide | Explicitly deferred (out of scope); D-03 mandates SQL-native |
| Guide markdown-fence extraction for tests | A generic Markdown parser dependency | A small regex/string-split helper anchored on the literal HTML-comment markers | No existing dependency does this; the markers are exact strings under test control |
| Registering the new guide | Assuming one registration point is enough | Register in **all three**: (1) `mix.exs` `:docs, :extras` list (`mix.exs:480-500`) and its `groups_for_extras` regex for the `Adopt` lane (`mix.exs:519`, currently matches `upgrade-path` — add `upgrading-to-0.11`); (2) `test/threadline/guide_graph_contract_test.exs` `@lanes.adopt` list (`test/threadline/guide_graph_contract_test.exs:14-20`) AND bump the hardcoded `assert length(assigned) == 18` to `19` (line ~73); (3) implicitly satisfied for `test/threadline/release_artifact_contract_test.exs:71` (`guide_extras() == guides_on_disk()`) once (1) is done, but verify it explicitly | Three independent tests enforce three different invariants; missing any one is a distinct CI failure, not a single fix |
| Checking the tarball for planning vocabulary | A new vocabulary scanner | The EXISTING `test/threadline/release_artifact_contract_test.exs:7-13,311-314` scan, which already runs over the whole built Hex archive | It already exists and already gates `mix hex.build` output; writing new guide/CHANGELOG content that matches `Phase \d+`, `phase\d+`, `D-\d{2,}`, or the listed requirement prefixes fails it |
| Approving the Hex publish deployment | Any new automation | The documented manual command form (see Release Lane below) | The `production-hex` GitHub Environment requires a human-clicked (or `gh api`-driven, by the human) approval; this is an intentional, irreversible gate (`CONTRIBUTING.md`, "The publish approval is a confirmation, not a review") |

**Key insight:** almost every "don't hand-roll" item in this phase is "don't assume — go read the actual test/config file," because the enforcement mechanisms (lane counts, banned-vocabulary regexes, environment ids) are hardcoded literals scattered across several files, not a single source of truth.

## Common Pitfalls

### Pitfall 1: Writing the security note (or guide) with banned vocabulary
**What goes wrong:** The CHANGELOG security note or new guide text uses phrases like "Phase 209", "the shared-capture-function issue (D-04)", or a requirement ID, and `mix verify.release` (which runs `release_artifact_contract_test.exs` against the actual built `mix hex.build` tarball) fails on the release PR — or worse, is only caught during the rehearsal, after the guide is already drafted.
**Why it happens:** The 209-CONTEXT.md and this phase's own CONTEXT.md are written in exactly this vocabulary (decision IDs, phase numbers), so drafting the shipped prose by lightly editing planning language is the path of least resistance.
**How to avoid:** Write the security note and guide from a domain-first framing: "installs where two audited tables shared one per-table capture function" (accurate, no ID), with the detection command (`mix threadline.health.coverage`, finding code `shared_capture_function`) and fix (regenerate together) as the actionable content.
**Warning signs:** `grep -riE '\bphase\s?[0-9]+\b|\bD-[0-9]{2,}\b' guides/upgrading-to-0.11.md CHANGELOG.md` returning anything.

### Pitfall 2: Treating the CHANGELOG heading rewrite (D-12) as reversible
**What goes wrong:** The `## Unreleased — highlights` heading is retitled to `## [0.11.0] - <date>` too early (before the maintainer confirms the exact date/squash), or too late (release-please's `changelog_contract_test.exs` requires at least one dated entry to exist at all times per `test "the human changelog contains at least one dated release entry"`).
**Why it happens:** The contract test (`test/threadline/changelog_contract_test.exs`, read this session) scopes its assertions to "the newest DATED entry" — if `## Unreleased — highlights` is the only heading, `dated_entries()` returns `[]` and the very first test in the file fails with an explicit message warning about vacuous pass, which is a hard, unambiguous signal, not a subtle one.
**How to avoid:** Retitle the heading only once, on the landing branch, at landing time (D-12 already specifies this exact sequencing) — never on a work-in-progress commit, since every phase before 213 landed content under the still-unbracketed `## Unreleased — highlights` heading with no dated entry, and that state is fine until the moment of landing.
**Warning signs:** `mix test test/threadline/changelog_contract_test.exs` failing with "no dated release heading matched."

### Pitfall 3: Rolling back a pre-0.11 trigger migration whose `down` still has `CASCADE`
**What goes wrong:** Deferred item from 209-CONTEXT.md: "0.10.x trigger migrations have a frozen `down` of `DROP FUNCTION IF EXISTS threadline_capture_changes_<x>() CASCADE`. Rolling one back after the upgrade can cascade-drop a sibling's live trigger." This is exactly what D-09's rollback proof must catch, and it is a **pre-existing** hazard the upgrade guide should warn about if adopters ever roll back an OLD (pre-0.11) migration after upgrading, not just the new one.
**Why it happens:** 0.10.x-era generated migrations are frozen text already applied in adopters' repos; the fix in 209 only affects NEW migrations generated after the fix, not migrations already committed to an adopter's `priv/repo/migrations`.
**How to avoid:** D-09's fixture must seed a shared-function scenario using the OLD (pre-209) `CASCADE` `down` shape, not the current generator's output, to prove the NEW upgrade-time behavior (regenerate together) avoids ever invoking that old cascading `down` at all — the guide's advice is "regenerate forward, don't roll old migrations back," which sidesteps the hazard rather than fixing the frozen SQL.
**Warning signs:** A rollback test that only exercises 209-and-later-generated migrations gives false confidence; it must include a legacy `CASCADE`-down fixture to be a real regression guard.

### Pitfall 4: Assuming `mix ci.all` needs a worktree
**What goes wrong:** The phase's plan dispatches `mix ci.all` on the landing branch inside a fresh git worktree (following the general GSD `use_worktrees: true` project default), and the Elixir suite fails immediately because a worktree has no `deps/`/`_build/` (per project memory: "worktrees have no deps/_build, so no Elixir suite can run in one").
**Why it happens:** `gsd-pr-branch` and general GSD dispatch conventions default to worktree isolation; this project's own `.gsd/dispatch-isolation-sentinel.json` was already hand-set to `{"isolation":"none", ..., "phase":"212", ...}` for exactly this reason on the prior phase.
**How to avoid:** Verify the landing branch with `mix ci.all` **in the current checkout** (the same directory `gsd-pr-branch` operates in — it does a plain `git checkout`, not a worktree), and re-record the dispatch-isolation sentinel as `none` for this phase's plans if the executor infrastructure checks it.
**Warning signs:** `mix ci.all` failing with missing-dependency compile errors immediately after a worktree dispatch.

### Pitfall 5: Missing the pre-emptive upgrade-path entry before release-please bumps the version
**What goes wrong:** `test/threadline/version_truth_doc_contract_test.exs` Family C derives its required coverage bullet (`"0.#{prev_minor}.x -> 0.#{minor}.x"`) from the CURRENT `mix.exs` `@version` (currently `"0.10.2"`, so today it requires `"0.9.x -> 0.10.x"`, already present). It will only require `"0.10.x -> 0.11.x"` once `@version` is actually `0.11.x` — which happens on **release-please's own release PR**, not on the landing branch. If the landing branch does not already contain the D-01-required `"0.10.x -> 0.11.x"` bullet, the release PR (created automatically after the squash-merge) is **born red** on this exact test, and the maintainer discovers it at the worst possible point in the runbook.
**Why it happens:** The self-referential design of the contract (deriving expectations from the live `@version`) means "green now" does not imply "green after the version bump" — this is the identical class of defect `bin/verify-bump-rehearsal`'s own header comment describes ("a class of release defect ... green at the current version by construction and only becomes observable once the version has moved").
**How to avoid:** Add the `"0.10.x -> 0.11.x"` bullet (with real content, not `bin/verify-bump-rehearsal`'s disclosed stand-in) to `guides/upgrade-path.md` on the landing branch itself, exactly as D-01 specifies. Confirm with `mix verify.bump_rehearsal` (which explicitly detects and reports whether it needed to synthesize a stand-in — if it does NOT report synthesizing one for the upgrade-path coverage, the real content is present).
**Warning signs:** `bin/verify-bump-rehearsal` output mentioning it added a stand-in upgrade-path bullet.

### Pitfall 6: CONTRIBUTING.md's release-mechanics prose may be stale
**What goes wrong:** `CONTRIBUTING.md` ("Ongoing releases (0.6.1+)") states "The Release PR bumps `mix.exs`, `CHANGELOG.md`, **and** the adoption-pilot SSOT line together" — but `changelog_contract_test.exs` (read this session) asserts release-please's `changelog-path` config key points at `CHANGELOG-GENERATED.md`, not `CHANGELOG.md`, and that `CHANGELOG.md` appears in NO release-please config key at all. This predates the CHANGELOG split (introduced per that test's own docstring, referencing "RELEASE-04").
**Why it happens:** `CONTRIBUTING.md` prose was not updated when the CHANGELOG ownership split landed.
**How to avoid:** Treat the CONTRACT TEST (`changelog_contract_test.exs`) as the source of truth for what release-please actually writes, not `CONTRIBUTING.md`'s prose. Do not use `CONTRIBUTING.md`'s wording as evidence for what the release-please PR will contain when planning verification steps.
**Warning signs:** None directly test-visible; this is a documentation-accuracy risk worth flagging to the maintainer rather than a CI failure.

## Code Examples

### Guide markers (D-03 extraction contract)

```markdown
<!-- threadline:backfill-sql:start -->
```sql
UPDATE <storage_schema>.audit_changes
SET table_pk = jsonb_build_object('<key_col>', data_after ->> '<key_col>' [, ...])
WHERE id IN (
  SELECT id FROM <storage_schema>.audit_changes
  WHERE table_schema = '<host_schema>' AND table_name = '<host_table>'
    AND op IN ('insert', 'update')
    AND (table_pk = '{"id": null}'::jsonb OR table_pk = '{}'::jsonb)
    AND data_after ?& array['<key_col>' [, ...]]
    AND data_after ->> '<key_col>' IS NOT NULL [AND ...]
  LIMIT <batch_size>
);
```
<!-- threadline:backfill-sql:end -->
```

The test extraction helper (Design, Claude's discretion per D-03/213-CONTEXT) should:
1. `File.read!("guides/upgrading-to-0.11.md")`
2. Split on the literal start/end marker strings (exact match — no regex needed, since the markers are fixed text)
3. Strip the ` ```sql ` / ` ``` ` fence from the extracted block
4. Substitute the bracketed placeholders (`<storage_schema>`, `<host_schema>`, `<host_table>`, `<key_col>`, `<batch_size>`) via `String.replace/3` for each fixture's real values
5. Loop-execute via `Repo.query!/2` until a run returns `%{num_rows: 0}` (bounded iteration count in the test, e.g. `Enum.reduce_while(1..20, ...)`, to avoid an infinite loop if the guard logic is ever wrong)

### `MigrationHarness` precedent for seeding + rerun (reuse for D-07/D-08)

```elixir
# Source: test/support/migration_harness.ex:24-33, read this session
tmp = ...
before = MigrationHarness.migration_files(tmp)
File.cd!(tmp, fn -> Mix.Tasks.Threadline.Gen.Triggers.run(["--tables", "a,b"]) end)
[file] = MigrationHarness.migration_files(tmp) -- before
{result, log} = MigrationHarness.migrate_up(file)
# ... assertions on log (WARNING text) and catalog state via
# MigrationHarness.trigger_function/2, threadline_triggers/2, function_users/1
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `table_pk = {"id": null}` for any table without a literal `id` column | Real primary key (or composite key, or declared `primary_key:` override) resolved at migrate time via `TG_ARGV` | Phase 210 (this milestone, pre-0.11) | This phase's entire reason to exist — the backfill closes the historical gap left by the old behavior |
| No row-history index | `audit_changes_row_history_idx` shipped by default; upgraders get a `CONCURRENTLY` migration | Phase 211 | `history/3`/`as_of/4` scan avoidance |
| `trigger_coverage/1` counted disabled/replica triggers as covered | Disabled/replica-only triggers are errors | Phase 212 | A previously-green `verify_coverage` gate can go red on upgrade — must be called out explicitly in the guide (already is, in CHANGELOG) |

**Deprecated/outdated:** None introduced by this phase; it documents deprecations already shipped by 210-212.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The exact `gh api ... pending_deployments` command and environment id (`20753768806`) from project memory (`release-runbook.md`, 3 days old at read time) are still valid | Release Lane / D-15 | If the environment was recreated, the id changes; the maintainer must re-derive it via `gh api repos/:owner/:repo/actions/runs/:run_id/pending_deployments` before using the cached id verbatim — flag this in the hand-off list rather than hardcoding the id as fact |
| A2 | No repo-internal doc states an exact "Security" CHANGELOG heading precedent (Keep a Changelog convention assumed: `### Security` placed with/near Breaking changes / Required action, before the feature-tour sections) | CHANGELOG security note (D-05) | If the maintainer expects a different heading position, `changelog_contract_test.exs`'s breaking-before-feature-tour test still passes either way (it only checks Breaking/Required-action vs. feature-tour order) — low risk, but flag heading placement as a discretion call |
| A3 | `guides/upgrade-path.md`'s existing "0.9.x → 0.10.x" bullet is a faithful structural template for the new "0.10.x → 0.11.x" bullet's shape (theme table + per-minor bullet + at-a-glance row) | Guide Structure | Low risk — the doc-contract test only checks presence of the coverage string and a few theme keywords, not exact structural mirroring |

## Open Questions (RESOLVED)

1. **Exact wording of the security note's impact statement**
   - What we know: the mechanism (a per-table capture function shared by two tables applies one table's redaction rules to both, until 209's fix regenerates them separately) is fully documented in `.planning/phases/209-collision-free-emission/209-CONTEXT.md` and matches `HLTH-04`'s `:shared_capture_function` finding code.
   - What's unclear: whether any REAL adopter install (vs. a theoretical one) is known to have hit this — the note should not overstate incidence.
   - Recommendation: word it as "installs where two tables were configured to share a capture function" (structural possibility), give the detection command, and avoid claiming a specific incidence rate, matching D-05's instruction to be "neither overstated nor understated."

2. **Whether `mix threadline.gen.triggers --tables a,b` syntax accepts cross-schema pairs in one call today**
   - What we know: `TriggerSQL.function_owner_guard/2`'s generated HINT text literally suggests `mix threadline.gen.triggers --tables #{owner_token},%s` with cross-schema table tokens (`Naming.table_token/1`) — confirming the CLI already supports this shape.
   - What's unclear: the exact `--tables` value syntax for a schema-qualified table (e.g. `billing.invoices` vs `billing_invoices`) — this needs one live invocation of `mix threadline.gen.triggers --help` or reading `lib/mix/tasks/threadline.gen.triggers.ex`'s option-parsing to confirm the guide's example command is copy-paste correct.
   - Recommendation: the planner/executor should read `lib/mix/tasks/threadline.gen.triggers.ex` `--tables` parsing directly before finalizing the guide's example command syntax (not done in this research pass — moderate priority, cheap to verify).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | Live backfill verification, real-PG upgrade/rollback tests | ✓ | confirmed reachable at `localhost:5432`, `threadline_test` db exists with `threadline` storage schema already migrated | — |
| Elixir/Erlang toolchain | `mix test`, `mix ci.all` | ✓ | Elixir 1.17.3-otp-27, Erlang/OTP 27.3.4.15 (`.tool-versions`, matches CLAUDE.md's "must pin erlang+elixir" gotcha) | — |
| `gh` CLI | Reading PR/branch state (read-only), later maintainer push/PR/merge | ✓ | `gh pr list --state open` returned empty; used read-only this session | — |
| Compiled deps/`_build` | `mix ci.all` on the landing branch | ✓ (in current checkout only) | — | Must verify IN the current checkout, not a fresh worktree/clone (Pitfall 4) |

No missing dependencies block this phase's local work.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (`mix test`), root suite, `async: false` for real-PG DDL-touching modules per repo convention |
| Config file | `config/test.exs` (DB: `postgres@localhost/threadline_test`, storage_schema `"threadline"`) |
| Quick run command | `mix test test/threadline/upgrade_backfill_test.exs test/threadline/upgrade_rollback_test.exs` (file names at plan's discretion) |
| Full suite command | `mix verify.test` (= `mix test`); phase gate additionally needs `mix ci.all` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-02 | Guide covers regenerate/index/backfill/unrecoverable/security-note; doc contracts pin regenerate+index steps | doc-contract (structural) | `mix test test/threadline/upgrading_to_0_11_doc_contract_test.exs` | ❌ Wave 0 — new file |
| REL-02 | Guide graph registration (3 enforcement points) | doc-contract (structural) | `mix test test/threadline/guide_graph_contract_test.exs test/threadline/release_artifact_contract_test.exs` | ✅ existing, needs literal updates (lane list + count) |
| REL-02 | Backfill SQL correctness (INSERT/UPDATE resolved, DELETE untouched, idempotent, matches regenerated-trigger output) | integration (real PG) | `mix test test/threadline/upgrade_backfill_test.exs` | ❌ Wave 0 — new file |
| REL-02 | CHANGELOG security note present, correctly placed, no banned vocabulary | doc-contract + existing archive scan | `mix test test/threadline/changelog_contract_test.exs test/threadline/release_artifact_contract_test.exs` | ✅ existing; security-heading pin is new assertions inside `changelog_contract_test.exs` — ❌ Wave 0 for the new assertions |
| REL-03 (local half only) | `ci.all`, `verify.release`, `verify.bump_rehearsal`, `release.pins --check`, `docs --warnings-as-errors`, `hex.build`, `verify.topology`, `verify.hex_evaluator`, browser lane (8 known failures) all green on the landing branch | local pre-land proof | `mix ci.all && mix verify.release && mix verify.bump_rehearsal && mix release.pins --check && MIX_ENV=dev mix docs --warnings-as-errors && mix hex.build && mix verify.topology && mix verify.hex_evaluator && CI=true mix verify.example_browser --project=desktop-chromium --project=mobile-chromium` | ✅ all commands already exist | — |
| REL-03 (rollback proof, D-09) | No orphan capture function, no dropped foreign trigger after `Ecto.Migrator` all-the-way-down | integration (real PG, catalog) | `mix test test/threadline/upgrade_rollback_test.exs` | ❌ Wave 0 — new file, no existing catalog-orphan test to reuse (confirmed by grep) |

### Sampling Rate
- **Per task commit:** targeted `mix test <new files>`
- **Per wave merge:** `mix verify.test` (full suite)
- **Phase gate:** `mix ci.all` green, plus the full D-11 local pre-land command list, before the landing branch is handed to the maintainer

### Wave 0 Gaps
- [ ] `test/threadline/upgrading_to_0_11_doc_contract_test.exs` — new doc-contract test pinning the guide's locked commands/markers (D-06)
- [ ] `test/threadline/upgrade_backfill_test.exs` — new real-PG backfill extraction+execution test (D-08)
- [ ] `test/threadline/upgrade_rollback_test.exs` — new real-PG rollback/orphan-catalog test (D-09) — no existing sibling to extend; build from `MigrationHarness` + `LegacyTriggerSQL` + `Ecto.Migrator.down(..., all: true)` from scratch
- [ ] Extend `test/threadline/upgrade_path_doc_contract_test.exs` and `test/threadline/version_truth_doc_contract_test.exs` expectations are ALREADY generic (Family C derives from `@version`) — no edit needed there, only the guide content itself
- [ ] Update `test/threadline/guide_graph_contract_test.exs` `@lanes.adopt` list and the `assert length(assigned) == 18` literal (→ 19)
- [ ] Extend `test/threadline/changelog_contract_test.exs` (or a new test in the same file) to pin the Security-heading content

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Out of scope — no auth surface touched |
| V3 Session Management | No | Out of scope |
| V4 Access Control | No | Out of scope |
| V5 Input Validation | Yes (narrow) | Backfill SQL's own guard clauses (`?&`, `IS NOT NULL`) are the "input validation" here — they prevent writing a malformed/partial key, verified live this session |
| V6 Cryptography | No | Out of scope |

### Known Threat Patterns for this phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Two audited tables sharing one capture function silently cross-apply redaction rules (the phase 209 issue this phase documents) | Information Disclosure | Already fixed at the code level in phase 209 (`function_owner_guard/2` raises at migrate time); this phase's job is documentation (CHANGELOG security note) + regression proof (D-08's shared-function fixture) that the documented remediation (regenerate together) actually clears the condition |
| A backfill SQL block copy-pasted with wrong schema/table/key substitution silently corrupts `table_pk` for the wrong table | Tampering (self-inflicted, adopter error) | The guide's marker-delimited, explicitly-parameterized form (placeholders in angle brackets) reduces blind copy-paste risk; the guard clauses (`table_schema =`, `table_name =`) scope every write to one named table |

## Sources

### Primary (HIGH confidence — read/verified this session)
- `lib/threadline/capture/primary_key_sql.ex` — `row_key_statements/0` (lines 29-46, quoted verbatim above)
- `lib/threadline/capture/trigger_sql.ex` — `drop_function_if_unused/2`, `function_owner_guard/2`, `create_trigger/3`
- `lib/threadline/storage_schema.ex` — `get/1`, default `"public"`, moduledoc on freeze-at-generation-time
- `lib/threadline/capture/audit_change.ex` — `AuditChange` schema fields (`table_pk`, `data_after`, `op`, `changed_fields`, `changed_from`)
- `test/support/legacy_trigger_sql.ex` — full file read; `v0_10_2_install_function/2` reproduced live and verified to match the described 0.10.2 bug shape
- `test/support/migration_harness.ex` — full file read
- `test/threadline/changelog_contract_test.exs` — full file read
- `test/threadline/upgrade_path_doc_contract_test.exs` — full file read
- `test/threadline/version_truth_doc_contract_test.exs` — full file read
- `test/threadline/guide_graph_contract_test.exs` — lanes map, hardcoded count `18`, `configured == on_disk` assertion
- `test/threadline/release_artifact_contract_test.exs` — `@banned_shapes`, `guide_extras()`, "the entire readable archive is free of planning vocabulary" test
- `mix.exs` — `:docs, :extras` list, `groups_for_extras`, `aliases/0` (`verify.release`, `verify.bump_rehearsal`, `ci.all` composition), `@version "0.10.2"`
- `.release-please-manifest.json` — confirms current version `0.10.2`
- `bin/verify-bump-rehearsal` — header comment (born-red causes, stand-in disclosure mechanics)
- `CONTRIBUTING.md` — Hex publish runbook section, backport policy, version-owner table
- `CHANGELOG.md` — full `## Unreleased — highlights` section (Breaking changes / Required action / Fixed / Added), `## [0.10.2]` entry
- `guides/upgrade-path.md` — full file read (lane detection, compatibility matrix, per-minor upgrade table, storage-schema migration expectation)
- `.planning/phases/209-collision-free-emission/209-CONTEXT.md` — full file read (the shared-capture-function issue this phase's security note must describe)
- `.planning/REQUIREMENTS.md`, `.planning/STATE.md` — scope and traceability
- Live PostgreSQL session against `threadline_test` (local, `localhost:5432`) — scratch tables/functions/triggers created, exercised, verified, and dropped this session; see backfill SQL section for exact queries and results
- `git rev-list --count HEAD..origin/main` → `0`; `git branch -a`; `gh pr list --state open` → empty — all read this session
- `~/.claude/gsd-core/workflows/pr-branch.md` — full relevant sections read (mode selection, `FORBIDDEN_RE`/`STRUCTURAL_RE`, verify step, "no push" behavior)
- Project memory `release-runbook.md` (dated 3 days before this session — flagged `[ASSUMED]`/A1 for the specific environment id)

### Secondary (MEDIUM confidence)
- `gh pr view 43 --json body` — PR body precedent for the 0.10.0 landing branch (squash title shape, "Built from N cherry-picked code commits with all .planning/ paths filtered out")
- `.planning/milestones/v1.41-phases/202-release-0-10-0/202-05-SUMMARY.md` — merge command precedent (`--match-head-commit`)

### Tertiary (LOW confidence)
- None used as load-bearing for a recommendation.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; all referenced modules read directly
- Backfill SQL correctness: HIGH — live-verified end-to-end against the actual frozen trigger SQL, including idempotence and guard-clause negative cases
- Guide/doc-contract registration mechanics: HIGH — every enforcing test file read directly, with exact line-level literals identified
- Release lane commands: HIGH for what exists in-repo (all confirmed to exist exactly as named); MEDIUM for the specific `gh api` environment id (project memory, 3 days stale, flagged as assumption)
- Security note wording/incidence: MEDIUM — mechanism fully verified from 209-CONTEXT.md, but exact adopter-facing phrasing is a discretion call flagged as an open question

**Research date:** 2026-09-26
**Valid until:** ~14 days (release-lane commands and CHANGELOG state will change the moment 0.11.0 ships; re-verify `mix.exs` `@version`, `.release-please-manifest.json`, and `git branch -a`/`gh pr list` immediately before planning execution if more than a few days elapse)
