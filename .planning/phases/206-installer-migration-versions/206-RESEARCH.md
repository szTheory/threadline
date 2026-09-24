# Phase 206: Installer Migration Versions - Research

**Researched:** 2026-09-24
**Domain:** Elixir Mix generator tasks, Ecto migration versioning, ExUnit file-level regression tests, human-owned CHANGELOG
**Confidence:** HIGH (every claim below was checked against live code, deps, or a probe run this session)

## Summary

The defect reproduces at HEAD. A probe run from an empty tmp dir wrote four files with one prefix. It ran `Install.run([])` and then `Gen.Triggers.run(["--tables","posts"])` under `MIX_ENV=test ... mix run --no-start`, and got `20260924151757_threadline_{audit,semantics,governance}_schema.exs` and `20260924151757_threadline_triggers_posts.exs`. `mix ecto.migrate` would raise `migrations can't be executed, migration version 20260924151757 is duplicated`. So D-09's case 4 (install, then gen.triggers) is also a live defect, not a hypothetical one. In the test env both tasks resolve the same directory, `priv/repo/migrations`. `Threadline.Test.Repo` has `priv: nil`, and the last module segment `Repo` underscores to `repo`. No config tweak is needed to make case 4 meaningful.

Most of the work is small and local: one new `@moduledoc false` helper, two call-site rewrites, one advice-branch rewrite, four or more tests, and one CHANGELOG entry. The risks sit in gates the planner could miss:
- The **archive vocabulary scan**. `CHANGELOG.md` and all of `lib/` ship in the Hex tarball and are regex-scanned. `WR-03`, `D-01`, `Phase 206`, and `v1.41` all fail the default `mix test`.
- The **public-surface reference validator**. It rejects backticked hidden modules in CHANGELOG.
- The **Elixir `~> 1.15` floor**.
- An **empty-range pitfall** in Elixir. `0..(count - 1)` with `count = 0` iterates `[0, -1]`.

**Primary recommendation:** Add `Threadline.Mix.MigrationVersion.next(path, count)` (pure stdlib, `@moduledoc false`, file `lib/threadline/mix/migration_version.ex`). It mirrors Ecto's own filename parse (`Integer.parse` of the basename → `{int, "_" <> _}`, recursive `**/*.exs`), takes the max, and returns `count` strings from `max(now, max_existing + 1s)` stepped with `NaiveDateTime.add/3`. It falls back to integers only when the max is not a valid 14-digit datetime and exceeds now. Write all tests first and prove them RED, then fix. Keep every `lib/` comment and the CHANGELOG entry free of planning IDs.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Version assignment (N strictly increasing versions above the dir max) | Mix-time helper (`Threadline.Mix.MigrationVersion`, lib/) | — | Pure function of (dir listing, clock, count). No DB and no app runtime. Shared by both generator tasks (D-04). |
| Deciding which families to write, and the write order | Mix task `threadline.install` | — | Owns the audit → semantics → governance order and the skip-if-exists rule. |
| Trigger migration file write | Mix task `threadline.gen.triggers` | helper | Asks the helper for 1 version. Keeps its own path. |
| Storage-schema advice (fresh / partial / none) | Mix task `threadline.install` | — | Needs the per-family `{:written, f} \| :skipped` results (D-06/D-07). |
| Duplicate-version rejection | Ecto (`Ecto.Migrator`, deps) | — | Out of our control. We only produce inputs it accepts. |
| Adopter communication | `CHANGELOG.md` (human-owned) | release-please (`CHANGELOG-GENERATED.md`) | D-11/D-12. |

## User Constraints

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

All five areas were researched in parallel and settled as one consistent set.
The user asked for a one-shot recommendation.

#### Version assignment (CR-01 core)
- **D-01:** Follow the Rails `next_migration_number` pattern. Compute
  `base = max(utc_now, highest existing version in the migrations dir + 1s)`
  **once, before writing anything**. Written files get `base`, `base+1s`,
  `base+2s` in the fixed order audit → semantics → governance. A skipped
  (already-present) file takes no slot. Rails:
  `[Time.now.utc.strftime("%Y%m%d%H%M%S"), "%.14d" % (current + 1)].max`.
  Ecto's `ecto.gen.migration` and `phx.gen.auth` have no guard, because they
  only ever write one file.
- **D-02:** Do the arithmetic with `NaiveDateTime.add/3` on a datetime, never
  by adding to the integer, so every version is a valid 14-digit timestamp
  (no `...60` seconds, and correct day/year carry, e.g. `20991231235959` →
  `21000101000000`).
- **D-03:** "Existing versions" means the integer prefixes of the files in
  the migrations dir. Parse 14-digit prefixes as datetimes. If the maximum is
  not a valid datetime (a non-timestamp host scheme), fall back to integer +1
  for the base and still keep new versions strictly increasing. If the host
  has a far-future migration, Threadline's files take a far-future date too.
  That is accepted, because it is Rails' behavior and Ecto only rejects
  duplicates, not ordering.

#### Shared helper and gen.triggers scope
- **D-04:** Put the logic in one internal `@moduledoc false` module (for
  example `Threadline.Mix.MigrationVersion`; the planner names it). It
  returns N versions for a migrations path. **Both** `mix threadline.install`
  and `mix threadline.gen.triggers` call it. Delete both copies of
  `timestamp/0` + `pad/1`
  (`lib/mix/tasks/threadline.install.ex:155-161`,
  `lib/mix/tasks/threadline.gen.triggers.ex:257+`). This also covers
  `install && gen.triggers` in the same second, which is a realistic
  scripted setup because the guides present the two commands as a pair
  (`guides/production-checklist.md:14`,
  `guides/how-threadline-works.md:70,109`). ecto_sql has no public helper to
  reuse, and igniter would be a new dependency, so both are out.
- **D-05:** Do not name the hidden helper module in backticks in
  CHANGELOG.md. ExDoc autolinks backticked module names and warns (then fails
  `mix docs --warnings-as-errors`) when the target is `@moduledoc false`.
  That was the phase-200 lesson. A Mix task calling a `lib/` module is
  Dialyzer-safe. The earlier break came from calling
  `Threadline.MixProject`.

#### WR-03 fold (partial re-run advice)
- **D-06:** Fold WR-03 into this phase. `generate/4` returns
  `{:written, file} | :skipped`. The dedicated-schema "For a NEW install …
  delete, set `storage_schema: "threadline"`, re-run" advice prints **only
  when all three migrations were written in this run** (a fresh install).
  This is the same return-shape change CR-01 already forces, and it is the
  same class of bug that 202-REVIEW CR-01 fixed: advice that splits
  Threadline across two schemas.
- **D-07:** On a partial run (some families skipped, at least one written,
  `:storage_schema` unset), print a short positive note instead of saying
  nothing. Suggested microcopy, which the planner may tighten but must keep
  the meaning of:
  ```
  Existing Threadline migrations were found, so the new migration(s) above
  target `public` to match them. Keep `:storage_schema` unset.

  Setting `storage_schema: "threadline"` now would split Threadline's tables
  across two schemas. To move to a dedicated schema, delete ALL Threadline
  migrations before the first `mix ecto.migrate`, set the key, and re-run.
  After migrating, moving schemas is deliberate migration work.
  ```
  When nothing was written, or `:storage_schema` is configured, keep today's
  behavior (no schema advice).
- **D-08:** Drop the trailing "Existing installs need no action …" paragraph
  from the fresh-install advice. Once that advice only reaches fresh
  installs, the paragraph is unreachable and contradicts the steps above it.
  Before changing any installer text, check that no guide or doc-contract
  test asserts it.

#### Regression tests
- **D-09:** File-level tests in `test/mix/tasks/threadline/install_test.exs`,
  using the existing tmp-dir harness. No database, no injected clock, no
  property test. Required cases:
  1. **Fresh install:** 3 prefixes are 14 digits, parse as valid
     `NaiveDateTime`s, are unique, and are strictly increasing in the order
     audit < semantics < governance. The failure message must quote Ecto's
     error (`migration version … is duplicated`). With 3 calls taking under
     1s there are at most 2 distinct seconds, so this is **RED on the current
     code every time**. Prove it RED before the fix, as the repo requires.
  2. **Future-dated host migration:** pre-seed
     `20991231235959_host_thing.exs` and assert every new version is greater
     than it and is a valid datetime (this exercises the carry). RED on any
     clock.
  3. **Partial re-run (WR-03 + ordering):** pre-create audit and semantics
     migrations, then run. Assert governance's version is above both, and
     `refute` the fresh-install advice (`No \`:storage_schema\` is
     configured`). Assert the D-07 note (`Keep \`:storage_schema\` unset`).
  4. **gen.triggers after install in the same run:** its version is greater
     than install's governance version. Put this in whichever test file the
     gen.triggers task already uses, or `install_test.exs` if none exists.
  - Keep `Application.delete_env(:threadline, :storage_schema)` setup where
    it applies, following the existing tests.
- **D-10:** Do not run `Ecto.Migrator` against the generated dir.
  `ensure_no_duplication!/1` and friends are `defp`
  (`deps/ecto_sql/lib/ecto/migrator.ex:660,675,708`). Only the `run` path
  checks, and it would apply DDL to the shared test DB, where Threadline
  tables already exist and there is no SQL sandbox by design.

#### Release and adopter communication
- **D-11:** Ship as a conventional `fix(install): …` commit so release-please
  cuts **0.10.2**. A `~> 0.10.0` pin picks it up. Suggested subject:
  `fix(install): give each generated migration a distinct version`.
  gen.triggers and WR-03 go in the body, or in separate `fix(...)` commits.
- **D-12:** Hand-write the CHANGELOG.md entry under the Unreleased section.
  CHANGELOG.md is human-owned; release-please writes only
  `CHANGELOG-GENERATED.md`. Follow the file's own template, in the docs voice
  (sober, direct):
  - Breaking changes: none.
  - Required action: none. An app that has already migrated is unaffected,
    including one whose files were renamed by hand, because the installer
    runs once.
  - Fixed: quote the **exact** Ecto error text so a search for it lands
    here: `(Ecto.MigrationError) migrations can't be executed, migration
    version <N> is duplicated` (verified at
    `deps/ecto_sql/lib/ecto/migrator.ex:711-712`). Say plainly that **every
    release through 0.10.1 is affected**. v0.1.0 already wrote audit and
    semantics with a shared second-resolution `timestamp()`, and 75-01
    (first released in 0.6.0) added governance. Give the workaround for earlier
    releases: rename the `_threadline_semantics_schema.exs` and then the
    `_threadline_governance_schema.exs` prefixes to later timestamps so the
    order is audit < semantics < governance, then re-run
    `mix ecto.migrate`. Mention that gen.triggers had the same class of bug
    and that the partial re-run advice was corrected (WR-03).
- **D-13:** No `mix hex.retire`. The bug is in every release, so retiring
  only 0.10.x would be a partial and dishonest claim. Retiring all of them
  would warn long-migrated apps that are fine. No new Troubleshooting guide
  section either: once 0.10.2 ships, the documented "install, then migrate"
  path is correct again, and a guide section would describe a bug that no
  longer exists and add doc-contract churn
  (`test/threadline/getting_started_saas_doc_contract_test.exs`).

### Claude's Discretion
- The helper module name and function signature, and whether install passes
  the count up front or asks for versions one by one. The only constraint is
  that versions are computed once, before any write.
- Exact wording of the D-07 note and the CHANGELOG entry, within the meaning
  and required contents locked above.
- Whether to use one commit or split into `fix(install)` and
  `fix(gen.triggers)`.

### Deferred Ideas (OUT OF SCOPE)
- Collapse the three migration families into one versioned migration
  (Oban/Carbonite style). This is a structural change to the install
  contract and would be its own phase if ever wanted.
- 205-REVIEW WR-01 (sync-job token isolation), WR-02 (sync-pins contract
  test scope) and WR-04 (bump-rehearsal negative-control drift) are release
  tooling, not the installer, so they stay out of 206.
- Detecting the storage schema from existing migration file contents was
  rejected. It breaks on hand-edited files and adds nothing when
  `:storage_schema` is unset.
</user_constraints>

> **Conflict the planner MUST resolve in favor of the archive gate:** D-12 says to "Mention ... the partial re-run advice was corrected (WR-03)". The literal token `WR-03` fails the default `mix test`. See Pitfall 1. Keep the *meaning* (the partial re-run advice was corrected) and drop the ID.

<phase_requirements>
## Phase Requirements

No formal REQ-IDs. This phase closes the v1.41 re-audit tech-debt item for CR-01 [VERIFIED: .planning/v1.41-MILESTONE-AUDIT.md:33-39, 143 — "The fix is strictly increasing versions plus a regression test on the numeric prefixes."]. The planner may use the working IDs below for traceability in plans and VALIDATION.md (tests only, never in lib/ or CHANGELOG):

| ID | Description | Research Support |
|----|-------------|------------------|
| T-CR01 | Install writes 3 unique, strictly increasing, valid 14-digit versions above any existing version | Helper design, Pattern 1, test cases 1-2 |
| T-GEN | gen.triggers uses the same helper, and its version is above install's in the same run | Pattern 3, test case 4 |
| T-WR03 | Fresh-install advice only when all 3 are written. Partial run gives the positive `public` note. The D-08 paragraph is removed | Pattern 2, test case 3 |
| T-DOC | CHANGELOG Unreleased entry per D-12, passing the vocabulary and reference gates | CHANGELOG section, Pitfalls 1-2 |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Use the named verify entrypoints (`mix verify.format`, `mix verify.credo`, `mix verify.test`, `mix ci.all`) in plans and docs.
- Honest default tests: do not exclude the new tests from `mix test`.
- Doc contract tests keep README, guides, and the example README aligned. Changing installer output text needs a grep of guides and tests first (done below: nothing asserts the D-08 paragraph).
- Capture stays trigger-backed through host-owned Ecto migrations. This phase keeps that contract, and the three-family structure is unchanged.
- Domain language: AuditTransaction/AuditChange, and so on. Not directly exercised here.
- GSD: `state.begin-phase` in gsd-core v1.14.0 needs flags (`--phase 206 --name "..." --plans N`). Hand-check STATE.md and ROADMAP.md afterwards. **Never `git add .planning/` wholesale** (user memory). Stage explicit paths only.
- Memory: `.tool-versions` must pin erlang and elixir (it is untracked in the working tree; leave it alone). The `ci.all` Dialyzer red usually means a PLT cache miss (`mix dialyzer --plt`).

## Live Code Facts (verified this session)

### `lib/mix/tasks/threadline.install.ex` (162 lines) [VERIFIED: Read, lines 1-162]

- `run/1` is at :22-57. It calls `Mix.Task.run("app.config", [])`, `path = migrations_path()`, `File.mkdir_p!(path)`, then three `generate(...)` calls with these verbatim suffixes and labels:
  - `"_threadline_audit_schema.exs"`, `"Threadline audit schema migration"`, `&Threadline.Capture.Migration.migration_content/0`
  - `"_threadline_semantics_schema.exs"`, `"Threadline semantics schema migration"`, `&Threadline.Semantics.Migration.migration_content/0`
  - `"_threadline_governance_schema.exs"`, `"Threadline governance schema migration"`, `&Threadline.Governance.Migration.migration_content/0`
  - then `|> Enum.reject(&is_nil/1)`. If `written != []` it prints `"Run \`mix ecto.migrate\` to apply the migration(s)."`, then calls `recommend_dedicated_storage_schema(written)`.
- `generate/4` is at :59-69. It returns `nil` on skip (and prints `"#{label} already exists — skipping."`), or the file path after `create_file(file, content_fun.())`. The path is `Path.join(path, "#{timestamp()}#{suffix}")` at :65. This is the defect line.
- The comment at :71-79 says "When nothing was written (an existing install), the advice is withheld". That comment is exactly WR-03's false premise, so rewrite it.
- `recommend_dedicated_storage_schema([])` at :80 returns `:ok`. The `/1` clause at :82-113 is gated on `is_nil(Application.get_env(:threadline, :storage_schema))`. The heredoc text is at :86-111. The D-08 paragraph is at :109-110, verbatim: `Existing installs need no action: \`public\` is the default precisely so an` / `upgrade keeps reading the tables it already has.`
- `migrations_path/0` is at :115-131. It resolves the first `:ecto_repos` entry, falls back to `"priv/repo/migrations"`, and rescues to the same. `repo_migrations_path/1` is at :134-145 (`priv/<underscored last module segment>/migrations` or `<priv>/migrations`).
- `existing_migration?/2` is at :147-153. It uses `File.ls!` and `String.ends_with?(&1, suffix)`, and rescues to `false`. It is not recursive.
- `timestamp/0` is at :155-158 and `pad/1` at :160-161. Delete both.
- There is no caller of `generate/4`, `timestamp/0`, or the advice function outside this file. All of them are `defp`. The only consumers of the return shape are `run/1` and `recommend_dedicated_storage_schema/1`.

### `lib/mix/tasks/threadline.gen.triggers.ex` (264 lines) [VERIFIED: Read, lines 1-264]

- The write path is at :129-138. `path = "priv/repo/migrations"` is **hard-coded** (:130), then `File.mkdir_p!(path)`, then `file = Path.join(path, "#{timestamp()}_threadline_triggers_#{table_suffix}.exs")` (:134), then `create_file(file, migration_content(table_specs))`, then `"Run \`mix ecto.migrate\` to install the triggers."`.
- `--dry-run` (:120-128) writes nothing. The helper must only be called on the write branch.
- `timestamp/0` is at :257-260 and `pad/1` at :262-263. Delete both.
- The doc-contract anchor `StorageSchema.threadline_table?` (:90) is pinned by `test/threadline/code_walkthrough_doc_contract_test.exs:12-14`. Do not touch it.
- **Path divergence (observation, out of scope):** install resolves the repo's migrations dir, while gen.triggers hard-codes `priv/repo/migrations`. They agree for any repo whose last module segment is `Repo` with no `:priv` override, including `Threadline.Test.Repo` (probe-confirmed). They disagree for, say, `MyApp.PrimaryRepo` or a custom `:priv`. The helper takes a path, so gen.triggers keeps passing `"priv/repo/migrations"`. Do not widen scope. Record it as a deferred note if the planner wants a trail.

### Tests [VERIFIED: Read test/mix/tasks/threadline/install_test.exs:1-124]

- The module is `Mix.Tasks.Threadline.InstallTest`, with `use ExUnit.Case, async: false`. `@suffixes` lists the three suffixes above.
- `setup` saves `Mix.shell()` and `Application.fetch_env(:threadline, :storage_schema)`, sets `Mix.shell(Mix.Shell.Process)`, and makes `tmp = Path.join(System.tmp_dir!(), "threadline-install-#{System.unique_integer([:positive])}")`. `on_exit` restores both and runs `File.rm_rf!(tmp)`.
- Helpers: `run_install(tmp)` does `File.cd!(tmp, fn -> Install.run([]) end)` and then `drain_shell([])`. `drain_shell/1` collects `{:mix_shell, :info, [msg]}` and joins them with `"\n"`. `generated(tmp)` does `Path.wildcard(tmp/**/*.exs)` filtered to `@suffixes`.
- There are 4 existing tests. Test 1 asserts `"Delete the migration files this run just generated"`, `~s(config :threadline, storage_schema: "threadline")`, and that `"creating"` comes before `"No \`:storage_schema\` is configured"`. Test 3 (re-run) asserts `"already exists — skipping"` and refutes `"No \`:storage_schema\` is configured"` and `"Run \`mix ecto.migrate\`"`. **All 4 stay green after the fix** (none depends on the D-08 paragraph or on prefix values).
- **No test file invokes `Mix.Tasks.Threadline.Gen.Triggers.run/1`.** `grep` of `test/` finds it only in the public_surface visibility list and in doc-contract string checks. Per D-09, case 4 goes in `install_test.exs`. `generated/1` filters by `@suffixes`, so case 4 needs its own wildcard for `*_threadline_triggers_*.exs` (or a helper `prefixes(tmp)` over all `*.exs`).
- The test migrations dir resolves to `<tmp>/priv/repo/migrations` [VERIFIED: probe output `* creating priv/repo/migrations/20260924151757_threadline_audit_schema.exs`]. Seed files for cases 2 and 3 must go there. Case 2 must `File.mkdir_p!` it first.
- The existing file runs in 0.06s (`4 tests, 0 failures`, `DB_PORT=5433`) [VERIFIED: run this session]. `test/test_helper.exs` starts `Threadline.Test.Repo` and runs migrations, so even this DB-free file needs Postgres up (DB_PORT=5433).

### Ecto facts [VERIFIED: Read deps/ecto_sql/lib/ecto/migrator.ex, ecto_sql 3.14.0 per mix.lock]

- File discovery (:660-673): `Path.join([directory, "**", "*.{ex,exs}"]) |> Path.wildcard()`. It is **recursive**.
- Version parse (:675-678): `case Integer.parse(Path.rootname(base)) do {integer, "_" <> name} -> ...`. `.ex` files are warned about and dropped.
- Check (:456): `ensure_no_duplication!(pending)`. Only **pending** migrations are checked.
- Error (:708-712), verbatim: `"migrations can't be executed, migration version #{version} is duplicated"`. It also checks duplicate names (`"migration name #{name} is duplicated"`). The three families have distinct names, so this does not apply.
- `deps/ecto_sql/lib/mix/tasks/ecto.gen.migration.ex:106-109` has the same `timestamp/pad` as our two copies, and `:72` shows `file = Path.join(path, "#{timestamp()}_#{base_name}")`.

### Elixir / NaiveDateTime facts [VERIFIED: probe, Elixir 1.17.3 via `mix run` and `elixir`]

- `NaiveDateTime.new(2099,12,31,23,59,59) |> NaiveDateTime.add(1, :second) |> Calendar.strftime("%Y%m%d%H%M%S")` gives `"21000101000000"`.
- `NaiveDateTime.new(2026,2,30,0,0,0)` gives `{:error, :invalid_date}`, and `NaiveDateTime.new(2026,1,1,23,59,60)` gives `{:error, :invalid_time}`. This is the valid-datetime check.
- `NaiveDateTime.from_iso8601("2099-12-31T23:59:59")` gives `{:ok, ~N[2099-12-31 23:59:59]}` (an alternative parse route).
- Prototype of the full algorithm, run this session:
  - empty dir gives `["20260924151812","20260924151813","20260924151814"]`
  - `20991231235959_host_thing.exs` gives `["21000101000000","21000101000001","21000101000002"]`
  - `7_legacy.exs` (a small integer scheme) gives now-based versions
  - `99999999999999_bad.exs` (14 digits, not a valid date, above now) gives `["100000000000000","100000000000001","100000000000002"]` (integer fallback, still strictly increasing)
- The **package floor is `elixir: "~> 1.15"`** [VERIFIED: mix.exs:41]. Everything above (`NaiveDateTime.new/6`, `add/3`, `truncate/2`, `utc_now/0`, `Calendar.strftime/2`, `..//` step ranges) predates 1.15 [ASSUMED from API history; low risk, and CI's older-Elixir lanes will catch it].

## Standard Stack

No new dependencies. Stdlib only (`NaiveDateTime`, `Calendar`, `Path`, `File`, `Integer`) plus the existing `Mix.Generator.create_file/2`.

| Tool | Version | Purpose |
|------|---------|---------|
| Elixir | 1.17.3-otp-27 (local), floor `~> 1.15` | runtime |
| ecto_sql | 3.14.0 [VERIFIED: mix.lock] | defines the version rules we must satisfy |
| ExUnit | bundled | tests |

## Package Legitimacy Audit

Not applicable. This phase installs no external packages (igniter was explicitly rejected in D-04).

## Architecture Patterns

### System Architecture Diagram

```
mix threadline.install
  │
  ├─ app.config ─► migrations_path() ─► path (e.g. priv/repo/migrations)
  │
  ├─ classify families in fixed order [audit, semantics, governance]
  │     existing_migration?(path, suffix) ── yes ─► :skipped (print "already exists — skipping")
  │                                        └ no ──► to_write
  │
  ├─ MigrationVersion.next(path, length(to_write))      ◄── ONE call, before any write
  │     list **/*.exs → Integer.parse prefixes → max M
  │     M valid 14-digit datetime? ─ yes ─► base = max(now, M+1s)  (NaiveDateTime.add)
  │                                └ no ──► M+1 > now_int ? integer M+1.. : now-based
  │     → [v1, v2, ...] strictly increasing strings
  │
  ├─ zip to_write with versions (in order) → create_file → {:written, file}
  │
  └─ advice(results, storage_schema):
        storage_schema set  ────────────────► none
        nothing written  ───────────────────► none
        all 3 written  ─────────────────────► fresh-install advice (no D-08 paragraph)
        some written, some skipped  ────────► positive "keep `public`" note (D-07)

mix threadline.gen.triggers --tables ...
  └─ (write branch only) MigrationVersion.next("priv/repo/migrations", 1) → one file
```

### Recommended file layout

```
lib/threadline/mix/migration_version.ex          # NEW  Threadline.Mix.MigrationVersion (@moduledoc false)
lib/mix/tasks/threadline.install.ex              # EDIT run/1, generate, advice; delete timestamp/pad
lib/mix/tasks/threadline.gen.triggers.ex         # EDIT :134 write path; delete timestamp/pad
test/mix/tasks/threadline/install_test.exs       # EDIT +4 cases (RED first)
CHANGELOG.md                                     # EDIT Unreleased section
```

Naming: no `lib/` module outside `Mix.Tasks.*` refers to Mix today. The helper is mix-time only but uses no Mix API, so `Threadline.Mix.MigrationVersion` (the CONTEXT example) is fine. **Do not** name it `Mix.Tasks.Threadline.*`. `test/threadline/public_surface_contract_test.exs:393-407` discovers every `Mix.Tasks.*` defmodule as a task and exact-partitions tasks (:456-470), so a helper in that namespace would land in the task classification [VERIFIED: Read :393-407, :456-470].

### Pattern 1: Version helper (reference implementation, prototype-proven)

```elixir
# Source: prototype run this session (/tmp/p206/proto.exs); Ecto parse rule from
# deps/ecto_sql/lib/ecto/migrator.ex:660-678; Rails next_migration_number (D-01).
defmodule Threadline.Mix.MigrationVersion do
  @moduledoc false

  @format "%Y%m%d%H%M%S"

  @doc false
  @spec next(Path.t(), non_neg_integer(), NaiveDateTime.t()) :: [String.t()]
  def next(path, count, now \\ NaiveDateTime.utc_now())
  def next(_path, 0, _now), do: []

  def next(path, count, now) when is_integer(count) and count > 0 do
    now = NaiveDateTime.truncate(now, :second)

    case path |> existing_versions() |> Enum.max(fn -> nil end) do
      nil -> from_datetime(now, count)
      max -> from_existing(max, now, count)
    end
  end

  defp from_existing(max, now, count) do
    case to_datetime(max) do
      {:ok, dt} -> dt |> NaiveDateTime.add(1, :second) |> later(now) |> from_datetime(count)
      :error ->
        if max + 1 > to_integer(now),
          do: Enum.map(0..(count - 1)//1, &Integer.to_string(max + 1 + &1)),
          else: from_datetime(now, count)
    end
  end

  defp from_datetime(base, count),
    do: Enum.map(0..(count - 1)//1, &(base |> NaiveDateTime.add(&1, :second) |> Calendar.strftime(@format)))

  # Mirrors Ecto.Migrator's discovery: recursive, integer prefix followed by "_".
  defp existing_versions(path) do
    [path, "**", "*.exs"]
    |> Path.join()
    |> Path.wildcard()
    |> Enum.flat_map(fn file ->
      case Integer.parse(Path.basename(file, ".exs")) do
        {n, "_" <> _} -> [n]
        _ -> []
      end
    end)
  end

  defp to_datetime(n) do
    with <<y::binary-4, mo::binary-2, d::binary-2, h::binary-2, mi::binary-2, s::binary-2>> <-
           Integer.to_string(n),
         {:ok, dt} <- NaiveDateTime.new(i(y), i(mo), i(d), i(h), i(mi), i(s)) do
      {:ok, dt}
    else
      _ -> :error
    end
  end

  defp i(bin), do: String.to_integer(bin)
  defp later(a, b), do: if(NaiveDateTime.compare(a, b) == :lt, do: b, else: a)
  defp to_integer(dt), do: dt |> Calendar.strftime(@format) |> String.to_integer()
end
```

Notes:
- The `<<...binary-4...>>` match only succeeds for exactly 14 bytes, so it acts as the "14-digit" check. `Integer.parse` can yield a negative number for a `-` prefix, and `Integer.to_string` of that won't match. That is fine.
- The optional `now` argument is only a seam, for an *optional* extra unit test of the D-03 fallback. D-09 requires no injected clock in the four required cases, and they call the tasks, not the helper.
- Credo defaults (nesting ≤ 2, cyclomatic ≤ 9, line ≤ 120) are satisfied by this shape. `.credo.exs` is "deltas over Credo's embedded defaults" [VERIFIED: .credo.exs:1], and `Readability.ModuleDoc` is on (:74). `@moduledoc false` satisfies it.

### Pattern 2: install `run/1` with versions computed once, before any write

```elixir
@families [
  {"_threadline_audit_schema.exs", "Threadline audit schema migration",
   &Threadline.Capture.Migration.migration_content/0},
  {"_threadline_semantics_schema.exs", "Threadline semantics schema migration",
   &Threadline.Semantics.Migration.migration_content/0},
  {"_threadline_governance_schema.exs", "Threadline governance schema migration",
   &Threadline.Governance.Migration.migration_content/0}
]
# NOTE: captured remote funs (&M.f/0) are allowed in module attributes; if the
# planner prefers, keep the list inline in run/1 as today.

def run(_args) do
  Mix.Task.run("app.config", [])
  path = migrations_path()
  File.mkdir_p!(path)

  pending = Enum.reject(@families, fn {suffix, _, _} -> existing_migration?(path, suffix) end)
  versions = MigrationVersion.next(path, length(pending))   # once, before any write

  {results, []} =
    Enum.map_reduce(@families, versions, fn {suffix, label, fun} = family, vs ->
      if family in pending do
        [v | rest] = vs
        {generate(path, v <> suffix, fun), rest}          # -> {:written, file}
      else
        Mix.shell().info("#{label} already exists — skipping.")
        {:skipped, vs}
      end
    end)

  written = for {:written, file} <- results, do: file
  if written != [], do: Mix.shell().info("Run `mix ecto.migrate` to apply the migration(s).")
  recommend_storage_schema(results, written)
end
```

Advice dispatch (D-06/D-07/D-08):
- `storage_schema` configured, or `written == []`: `:ok` (today's behavior).
- `Enum.all?(results, &match?({:written, _}, &1))`: the fresh-install heredoc (lines :86-107 as today), **minus** :109-110.
- otherwise (partial): the D-07 note. It must contain the literal `Keep \`:storage_schema\` unset` (test case 3 asserts it) and must **not** contain `No \`:storage_schema\` is configured`.
- Rewrite the :71-79 comment so it describes the three branches. No planning IDs (Pitfall 1).

Keep the skip message and creation lines in family order. The existing test 1 checks that `"creating"` comes before the advice.

### Pattern 3: gen.triggers

Replace :134 with:
```elixir
[version] = MigrationVersion.next(path, 1)
file = Path.join(path, "#{version}_threadline_triggers_#{table_suffix}.exs")
```
This goes after `File.mkdir_p!(path)`, on the non-dry-run branch only.

### Anti-Patterns to Avoid
- **Integer arithmetic on the version** (`String.to_integer(ts) + 1`): gives `...60` seconds and a broken carry (D-02).
- **Calling the helper per family**: a re-listing between writes would *happen* to work, but it violates "computed once, before any write" (D-01) and makes ordering depend on write timing.
- **A non-recursive listing for the max**: Ecto scans `**`. A host with subdirectories in migrations would be under-counted. (`existing_migration?/2` may stay non-recursive. It only answers "is this family present".)
- **Running `Ecto.Migrator` in tests** (D-10).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Date carry / leap validity | manual y/m/d arithmetic or `pad/1` | `NaiveDateTime.new/6` + `add/3` + `Calendar.strftime/2` | Calendar-correct. Rejects Feb 30 and second 60 (probe-verified) |
| "What counts as a migration version" | own regex | Ecto's exact rule: `Integer.parse(rootname)` then `{int, "_" <> _}` | Same set Ecto will compare, so no false negatives |
| Version collision guard | igniter / ecto internals | the small helper | D-04: ecto_sql has no public helper, and igniter is a new dependency |

## Common Pitfalls

### Pitfall 1: Planning vocabulary in packaged files fails the DEFAULT `mix test`
**What goes wrong:** `test/threadline/release_artifact_contract_test.exs` builds the Hex archive and scans every readable file, including `CHANGELOG.md` and all of `lib/`, against these banned shapes [VERIFIED: Read :7-14]:
```
{:phase_prose, ~r/\bPhase\s+\d+(?:\.\d+)?\b/i},
{:phase_identifier, ~r/\bphase[_-]?\d+(?:[_-][a-z0-9_]+)?\b/i},
{:decision_id, ~r/\bD-\d{2,}\b/},
{:requirement_id,
 ~r/\b(?:ADOPT|COMP|CRITIC|DATA|GREEN|GROUP|MECH|NAV|PROOF|SURFACE|WR)-\d{2,}\b/},
{:milestone_literal, ~r/\bv1\.(?:3[4-9]|4[01])\b/}
```
`package files:` includes `lib` and `CHANGELOG.md` [VERIFIED: mix.exs:432-433].
**How to avoid:** In CHANGELOG, write "the installer's advice on a partial re-run was corrected", never `WR-03`. In lib/ comments, cite no `D-0x`, `WR-03`, `Phase 206`, or `v1.41`. `CR-01` is not in the regex, but avoid it too, because it means nothing to an adopter. Tests are not packaged, so test comments may cite review IDs, though durable wording is better.
**Warning signs:** `archive_vocabulary` / `source_module_vocabulary` failures naming the file and line.

### Pitfall 2: Backticked hidden module in CHANGELOG
**What goes wrong:** The CHANGELOG is a reference subject (`public_doc_refs_changelog: ["CHANGELOG.md"]`, [VERIFIED: public_surface_contract_test.exs:91]). Unknown or hidden module references fail the test, and ExDoc warns under `mix docs --warnings-as-errors` (D-05).
**How to avoid:** Name only the tasks (`mix threadline.install`, `mix threadline.gen.triggers`, both public), or describe the helper in words.

### Pitfall 3: Empty range when nothing is to be written
**What goes wrong:** `0..(count - 1)` with `count = 0` is `0..-1`, which Elixir iterates as `[0, -1]` (an implicit decreasing range). A full re-run would then compute two versions for zero files. In the zip form it crashes with `{results, []}` mismatch or leaks.
**How to avoid:** Give a `count = 0` clause returning `[]` and use explicit step `0..(count - 1)//1`.

### Pitfall 4: Case 4 is not deterministically RED unless it asserts across all four
**What goes wrong:** On the old code, if the second boundary falls between governance and triggers, `triggers > governance` holds by luck, and the pre-fix proof would pass.
**How to avoid:** Case 4 asserts that the **four** prefixes (3 install + 1 triggers) are unique and strictly increasing in write order. Four calls in under 1s span at most 2 distinct seconds, so a duplicate is guaranteed on the old code. Likewise case 3 pre-seeds audit and semantics with far-future valid prefixes (e.g. `20991231235958_threadline_audit_schema.exs`, `20991231235959_threadline_semantics_schema.exs`), so "governance > both" is RED on any clock. The advice refute/assert is RED on its own anyway.

### Pitfall 5: Partial-run seeding must match `existing_migration?` and Ecto parsing
Seeded files need the exact suffixes (`_threadline_audit_schema.exs`, and so on) in `<tmp>/priv/repo/migrations/`. File content can be a trivial string. Nothing compiles it.

### Pitfall 6: Global state in tests
Case 4 calls `Mix.Tasks.Threadline.Gen.Triggers.run(["--tables", "posts"])` inside `File.cd!(tmp, ...)`. It re-runs `app.config` (memoized by Mix, harmless) and reads `:trigger_capture` config. The probe ran it cleanly in the test env. Keep `async: false`. The create message for triggers also lands in the `Mix.Shell.Process` mailbox, so drain it.

### Pitfall 7: `mix docs --warnings-as-errors` runs only in `verify.release` and a clean clone
`verify.release` calls `ensure_clean_tree!()` [VERIFIED: mix.exs:229-236]. The real tree has a modified `.planning/` and an untracked `.tool-versions`, so run `MIX_ENV=dev mix docs --warnings-as-errors` directly as the docs gate. Phase 205 used a clean clone for full `verify.release`.

## Code Examples

### Regression test skeleton (cases 1–4)

```elixir
# test/mix/tasks/threadline/install_test.exs additions
@migrations "priv/repo/migrations"

defp prefixes(tmp, suffixes) do
  for suffix <- suffixes do
    [file] = Path.wildcard(Path.join([tmp, @migrations, "*" <> suffix]))
    file |> Path.basename() |> String.split("_", parts: 2) |> hd()
  end
end

defp assert_valid_increasing!(versions) do
  for v <- versions do
    assert byte_size(v) == 14 and v =~ ~r/^\d{14}$/, "version #{v} is not 14 digits"
    <<y::binary-4, mo::binary-2, d::binary-2, h::binary-2, mi::binary-2, s::binary-2>> = v
    assert {:ok, _} = NaiveDateTime.new(String.to_integer(y), String.to_integer(mo),
             String.to_integer(d), String.to_integer(h), String.to_integer(mi), String.to_integer(s))
  end

  dupes = versions -- Enum.uniq(versions)
  assert dupes == [],
         "`mix ecto.migrate` would raise (Ecto.MigrationError) migrations can't be executed, " <>
           "migration version #{List.first(dupes)} is duplicated — got #{inspect(versions)}"

  assert versions == Enum.sort(versions), "versions are not strictly increasing in write order: #{inspect(versions)}"
end
```
- Case 1: `Application.delete_env(:threadline, :storage_schema)`, then `run_install(tmp)`, then `assert_valid_increasing!(prefixes(tmp, @suffixes))`.
- Case 2: `File.mkdir_p!(Path.join(tmp, @migrations))`, write `20991231235959_host_thing.exs`, run, and assert every prefix `> "20991231235959"` (string compare is safe at equal length, but compare integers for clarity) plus `assert_valid_increasing!`.
- Case 3: seed audit and semantics with far-future prefixes, delete_env, and run. Assert governance > both. `refute output =~ "No \`:storage_schema\` is configured"`, `assert output =~ "Keep \`:storage_schema\` unset"`, `assert output =~ "already exists — skipping"`.
- Case 4: `run_install(tmp)`, then `File.cd!(tmp, fn -> Mix.Tasks.Threadline.Gen.Triggers.run(["--tables", "posts"]) end)` and `drain_shell([])`. Collect `prefixes(tmp, @suffixes) ++ [triggers_prefix]` and `assert_valid_increasing!`.

### Probe for manual end-to-end smoke (pre/post fix)
```bash
rm -rf /tmp/p206probe && mkdir -p /tmp/p206probe
MIX_ENV=test DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix run --no-start -e '
Application.delete_env(:threadline, :storage_schema)
File.cd!("/tmp/p206probe", fn ->
  Mix.Tasks.Threadline.Install.run([])
  Mix.Tasks.Threadline.Gen.Triggers.run(["--tables", "posts"])
end)
IO.inspect(Path.wildcard("/tmp/p206probe/**/*.exs"))'
```
Pre-fix output (this session): all four files at `20260924151757_*`. Post-fix: four distinct consecutive seconds.

## CHANGELOG.md facts [VERIFIED: Read CHANGELOG.md:1-130, changelog_contract_test.exs:1-196]

- The standing heading is verbatim `## Unreleased — highlights`, followed by a paragraph, then the placeholder line `_Nothing yet for the next release._`. Replace the placeholder with the entry. Keep the heading and its explanatory paragraph? The 0.10.1 precedent shows the dated heading replaces the whole block at release. Recommendation: keep the heading, replace the placeholder with lead prose and subsections.
- The template, from `[0.10.1]`: a lead prose paragraph, `### Breaking changes`, `None.`, `### Required action`, then `### Fixed` with bullets.
- The contract only checks the **newest dated** entry (`## [x.y.z] - YYYY-MM-DD`). The Unreleased block is not checked today, but it becomes the newest dated entry at release. So write it contract-shaped now: prose before the first `###`, Breaking/Required action **above** `### Fixed`, and no `* ... ([abcdef0](.../commit/...))` generated bullets.
- `@bracketed_unreleased_regex ~r/^\#{1,6}\s*\[\s*unreleased\s*\]/mi`: never write `## [Unreleased]`.
- Required content (D-12): the exact Ecto string (`(Ecto.MigrationError) migrations can't be executed, migration version <N> is duplicated`), "every release through 0.10.1", the rename workaround (semantics, then governance, to later timestamps; order audit < semantics < governance; re-run `mix ecto.migrate`), and a gen.triggers mention plus a partial-re-run advice mention (without the `WR-03` token).
- Doc-contract grep for installer output strings [VERIFIED: grep guides/ README.md test/ lib/ CHANGELOG.md]:
  - `Existing installs need no action` appears only in the installer (:109), `guides/upgrade-path.md:125`, and `CHANGELOG.md:107` (0.10.0 history). No test asserts the installer's copy. `getting_started_saas_doc_contract_test.exs:221` asserts the guide phrase `existing installs need no action on upgrade`, which is guide text and unaffected. **D-08 removal is safe.**
  - `No \`:storage_schema\` is configured` and `Delete the migration files this run just generated` are asserted only in `install_test.exs`.
  - `guides/configuration-and-commands.md:32`, verbatim: "`\"public\"`, your host's default schema, so an existing install keeps reading the tables it already has. A new install can opt into a dedicated schema such as `\"threadline\"`; set it before `mix threadline.install`, because the generated migrations freeze the choice." This is consistent with the D-07 note.
- Side observation (out of scope; do not fix here without a decision): `guides/production-checklist.md:14` says "(default `threadline`, explicit `public` for the historical footprint)". That is stale versus the `"public"` default since 0.10.0. Consider a seed or todo.

## Public surface / dialyzer / xref

- A hidden module passes the visibility tests. `visible_modules` keeps only `:visible`/`:undocumented` (:614-619), and `@moduledoc false` is `:hidden`. The helper need not be in any `groups_for_modules` group or `@hidden_modules` list [VERIFIED: public_surface_contract_test.exs:614-640].
- Dialyzer: `plt_add_apps` includes `:mix` [VERIFIED: mix.exs:54-55]. The helper uses no Mix API anyway. Flags are `[:unmatched_returns, :extra_return]`, so give an accurate `@spec` (`[String.t()]`). `create_file/2`'s boolean return is already ignored today without warnings.
- xref: the task calls the helper at runtime only (no macro or compile-time use), so there is no compile-connected edge. `verify.xref_cycles` is unaffected. `verify.compile_no_optional` is unaffected (stdlib only).

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Per-file `:calendar.universal_time()` second-resolution stamp (ecto.gen.migration, phx.gen.auth, our 2 tasks) | Rails `next_migration_number`: `max(now, current+1)` computed once | Multi-file generators need it. Single-file generators get away without it |
| Multiple migration families | Oban/Carbonite single versioned migration | Deferred (structural) |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | All APIs used (`NaiveDateTime.new/6`, `add/3`, `truncate/2`, `Calendar.strftime/2`, `first..last//step`) exist in Elixir 1.15 | Live Code Facts / Pattern 1 | Low. Would surface as a compile error on the 1.15 CI lane |
| A2 | Placing the helper under `Threadline.Mix.*` rather than `Mix.Threadline.*` is the better namespace choice | Recommended layout | Cosmetic. Either passes every contract test |

## Open Questions

1. **Keep or drop the Unreleased heading's explanatory paragraph when adding the entry?**
   - Known: the heading must stay unbracketed, and the dated heading replaces it at release.
   - Recommendation: keep the heading and paragraph, and replace only `_Nothing yet for the next release._` with the entry (lead prose plus subsections). The release step retitles it.
2. **gen.triggers path divergence** (hard-coded `priv/repo/migrations` versus repo-resolved). This is out of scope under D-04's "helper takes a path". Recommend a deferred note only.
3. **Stale `production-checklist.md:14` default text.** Out of scope. Recommend a seed.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang/Elixir via asdf | everything | ✓ | 27.3 / 1.17.3-otp-27 (use `ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27`) | — |
| PostgreSQL on :5433 | test_helper starts the repo even for the install tests | ✓ (install_test ran green this session) | — | — |
| Dialyzer PLT | `mix verify.dialyzer` | ✓ `.dialyzer/dialyxir_erlang-27.3_elixir-1.17.3_deps-dev.plt` present | — | `mix dialyzer --plt` on a cache miss |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17.3) |
| Config file | `test/test_helper.exs` (only `pgbouncer_topology` is excluded by default) |
| Quick run command | `DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/mix/tasks/threadline/install_test.exs` (~0.1s of test time) |
| Contract batch | `DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test test/mix/tasks/threadline/install_test.exs test/threadline/changelog_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/public_surface_contract_test.exs test/threadline/code_walkthrough_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs` |
| Full suite command | `DB_PORT=5433 ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix test` (205 baseline: 1787 tests, 0 failures, 1 excluded. A lone `CriticTrustTest` / critic.measure failure is a known flake, so re-run it once) |

### Phase Requirements → Test Map
| ID | Behavior | Type | Automated Command | File Exists? |
|----|----------|------|-------------------|-------------|
| T-CR01 | Fresh install: 3 prefixes 14-digit, valid, unique, audit<semantics<governance | unit (file-level) | quick run, case 1 | ✅ file / ❌ case (Wave 0, RED first) |
| T-CR01 | Future-dated host migration `20991231235959` → all new > it, valid (carry to `21000101000000`) | unit | quick run, case 2 | ❌ case |
| T-WR03 | Partial re-run: governance > seeded pair, no fresh advice, D-07 note present | unit | quick run, case 3 | ❌ case |
| T-GEN | install + gen.triggers in the same run: 4 prefixes unique and increasing | unit | quick run, case 4 | ❌ case |
| T-WR03 | Existing 4 tests still green (fresh advice names files; configured = no advice; full re-run = no advice) | unit | quick run | ✅ |
| T-DOC | CHANGELOG entry shape and vocabulary | contract | contract batch (changelog, release_artifact, public_surface) | ✅ |
| (opt) | Helper D-03 non-timestamp fallback (`99999999999999_x.exs` → `100000000000000…`) | unit | new `test/threadline/mix/migration_version_test.exs` | ❌ optional |

### Sampling Rate
- **Per task commit:** quick run, plus `mix format --check-formatted` and `mix credo --strict <changed files>`.
- **Per wave merge:** contract batch, plus `mix compile --force --warnings-as-errors` and `mix verify.xref_cycles`.
- **Phase gate:** full suite, `mix verify.format`, `mix verify.credo`, `MIX_ENV=dev mix verify.dialyzer`, `MIX_ENV=dev mix docs --warnings-as-errors`, and the manual probe (four distinct prefixes). `mix ci.all` is the canonical superset if time allows (it includes the browser lane, which has 8 known pre-existing screenshot failures per user memory).

### Wave 0 Gaps
- [ ] The four new cases in `test/mix/tasks/threadline/install_test.exs`, written and **run RED against the unmodified code** (record the failure output in the SUMMARY). Expected RED: case 1 duplicate prefix; case 2 prefixes < 2099; case 3 governance < seeded plus missing D-07 note plus present fresh advice; case 4 duplicate.
- No framework install is needed.

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2/V3/V4 | no | — |
| V5 Input Validation | minimal | Filenames are derived from fixed suffixes plus a computed numeric version. `--tables` is already validated in gen.triggers. Existing filenames are only parsed with `Integer.parse`, never evaluated |
| V6 Cryptography | no | — |
| V12 Files | yes (low) | Writes only under the resolved migrations dir via `Mix.Generator.create_file/2`. There are no new paths |

Threat: **Tampering / DoS of the adopter's migrate** (the defect itself: duplicate versions block `ecto.migrate`). The mitigation is this phase. There is no new attack surface.

## Sources

### Primary (HIGH confidence)
- `lib/mix/tasks/threadline.install.ex:1-162`, `lib/mix/tasks/threadline.gen.triggers.ex:1-264`, `test/mix/tasks/threadline/install_test.exs:1-124`: Read this session.
- `deps/ecto_sql/lib/ecto/migrator.ex:450-458, 655-712`; `deps/ecto_sql/lib/mix/tasks/ecto.gen.migration.ex:68-76, 104-110`: Read this session.
- `test/threadline/release_artifact_contract_test.exs:1-40, 245-320, 455-480`; `test/threadline/changelog_contract_test.exs:1-196`; `test/threadline/public_surface_contract_test.exs:1-300, 393-470, 590-660`; `test/threadline/code_walkthrough_doc_contract_test.exs:1-60`; `mix.exs:41, 50-70, 123-205, 229-236, 424-450`; `CHANGELOG.md:1-130`: Read this session.
- Probes: the CR-01 reproduction (4 files at one prefix), the NaiveDateTime carry and invalid-date behavior, and the full algorithm prototype, all on Elixir 1.17.3.

### Secondary
- `.planning/phases/205-release-reconciliation/205-REVIEW.md` CR-01/WR-03; `.planning/v1.41-MILESTONE-AUDIT.md:33-39,143`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH. No new dependencies. Stdlib behavior probed.
- Architecture: HIGH. Every call site and consumer was read. The prototype was run.
- Pitfalls: HIGH. The vocabulary and reference gates were read from source. The RED determinism was argued, and the defect was reproduced.

**Research date:** 2026-09-24
**Valid until:** 2026-10-24 (stable. Invalidated if install.ex, gen.triggers.ex, or the archive vocabulary test changes)
