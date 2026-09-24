# Phase 206: Installer Migration Versions - Context

**Gathered:** 2026-09-24
**Status:** Ready for planning

<domain>
## Phase Boundary

`mix threadline.install` writes its three migrations (audit → semantics →
governance) with unique, strictly increasing Ecto versions. Every version is
greater than any migration already in the host's migrations directory, so a
fresh adopter's `mix ecto.migrate` succeeds. Regression tests on the numeric
prefixes lock this in. Source: 205-REVIEW CR-01, v1.41 re-audit tech debt.

The fix covers the whole defect class. That means the byte-identical
`timestamp/0` in `mix threadline.gen.triggers`, plus the WR-03 advice defect
in the same `generate/4` return value that CR-01's fix rewrites. No new
capability. The three-migration-family structure stays as it is.

</domain>

<decisions>
## Implementation Decisions

All five areas were researched in parallel and settled as one consistent set.
The user asked for a one-shot recommendation.

### Version assignment (CR-01 core)
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

### Shared helper and gen.triggers scope
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

### WR-03 fold (partial re-run advice)
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

### Regression tests
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

### Release and adopter communication
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Defect source
- `.planning/phases/205-release-reconciliation/205-REVIEW.md`: CR-01 (the
  defect, reproduction, and suggested fix) and WR-03 (partial re-run
  advice).
- `.planning/v1.41-MILESTONE-AUDIT.md`: the re-audit entry that opened this
  phase (CR-01 tech debt).

### Code under change
- `lib/mix/tasks/threadline.install.ex`: `run/1` :23-57, `generate/4`
  :60-69, advice :80-113, `timestamp/0` :155-161.
- `lib/mix/tasks/threadline.gen.triggers.ex`: file write :134,
  `timestamp/0` :257+.
- `test/mix/tasks/threadline/install_test.exs`: the existing tmp-dir +
  `Mix.Shell.Process` harness. Today it only asserts `length(files) == 3`.

### Ecosystem precedent
- `deps/ecto_sql/lib/ecto/migrator.ex:456,708-712`:
  `ensure_no_duplication!` and the exact error string.
- `deps/ecto_sql/lib/mix/tasks/ecto.gen.migration.ex:72,106-109`: the bare
  second-resolution timestamp, with no version-collision guard.
- `deps/phoenix/lib/mix/tasks/phx.gen.auth.ex:1032-1035`: the same pattern,
  safe only because it writes one file.
- Rails `ActiveRecord::Migration#next_migration_number`
  (https://github.com/rails/rails/blob/main/activerecord/lib/active_record/migration.rb):
  the max(now, current+1) pattern adopted in D-01.

### Release and docs
- `CHANGELOG.md`: human-owned; add the entry under Unreleased.
- `release-please-config.json`: `changelog-path: CHANGELOG-GENERATED.md`.
- `guides/getting-started-saas.md`: the documented "install, then migrate"
  path. It is not edited; it becomes correct again after the fix.
- `guides/configuration-and-commands.md:32`: storage_schema documentation.
  Check that it stays consistent with the D-07/D-08 microcopy.
- `test/threadline/public_surface_contract_test.exs:236-249`: accepts
  `@moduledoc false` modules (for the D-04 helper).
- `prompts/threadline-elixir-oss-dna.md`: engineering habits (named verify
  entrypoints, honest tests, RED-first contract tests).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `existing_migration?/2` in install already does `File.ls!` on the
  migrations dir. The same listing gives the existing version prefixes, so
  no extra scan is needed.
- `migrations_path/0` / `repo_migrations_path/1` (install :115-145) resolve
  the host repo's migrations dir. gen.triggers resolves its own path; the
  helper takes a path and does not re-resolve one.
- The install_test helpers `run_install/1`, `drain_shell/1` and
  `generated/1` extend directly to the new cases.

### Established Patterns
- New contract and regression tests are proven non-vacuous by going RED
  against the pre-fix code before the fix lands.
- Internal helpers are `@moduledoc false`, and hidden modules are never
  backticked in CHANGELOG (ExDoc autolink warning).
- The install test is `async: false` because it touches cwd and global app
  env.

### Integration Points
- `run/1` → `generate/4` → `create_file/2` (Mix.Generator). The
  `{:written, f} | :skipped` return feeds both the "Run `mix ecto.migrate`"
  line and the advice branch.
- The example app's migrations (`...080636_audit` / `...080637_semantics`)
  only avoided the bug because they happened to be one second apart. They
  stay as they are.

</code_context>

<specifics>
## Specific Ideas

- Model the fix on Rails' `next_migration_number`. Oban and Carbonite avoid
  the problem with a single versioned migration. That is a noted lesson
  (the library should own version ordering, not the wall clock), and it is
  out of scope.
- The CHANGELOG entry must be findable by searching the literal Ecto error
  string.

</specifics>

<deferred>
## Deferred Ideas

- Collapse the three migration families into one versioned migration
  (Oban/Carbonite style). This is a structural change to the install
  contract and would be its own phase if ever wanted.
- 205-REVIEW WR-01 (sync-job token isolation), WR-02 (sync-pins contract
  test scope) and WR-04 (bump-rehearsal negative-control drift) are release
  tooling, not the installer, so they stay out of 206.
- Detecting the storage schema from existing migration file contents was
  rejected. It breaks on hand-edited files and adds nothing when
  `:storage_schema` is unset.

</deferred>

---

*Phase: 206-installer-migration-versions*
*Context gathered: 2026-09-24*
