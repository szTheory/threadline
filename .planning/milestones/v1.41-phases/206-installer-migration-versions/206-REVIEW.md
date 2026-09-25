---
phase: 206-installer-migration-versions
reviewed: 2026-09-24T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - lib/threadline/mix/migration_version.ex
  - lib/mix/tasks/threadline.install.ex
  - lib/mix/tasks/threadline.gen.triggers.ex
  - test/mix/tasks/threadline/install_test.exs
  - test/threadline/mix/migration_version_test.exs
  - CHANGELOG.md
findings:
  critical: 0
  warning: 1
  info: 4
  total: 5
status: issues_found
---

# Phase 206: Code Review Report

**Reviewed:** 2026-09-24
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

I reviewed the phase diff `00022f15..HEAD` for the six files in scope. For
CHANGELOG.md I reviewed only the new Unreleased entry. I checked the code
against the locked decisions D-01 to D-13 in 206-CONTEXT.md.

The core fix is correct:

- `Threadline.Mix.MigrationVersion.next/3` computes `max(now, max_existing + 1s)` once, before any file is written (D-01).
- It steps with `NaiveDateTime.add/3`, so carries are handled (D-02).
- It falls back to plain integers when the maximum is not a valid timestamp (D-03).
- It finds existing migrations the same way Ecto does. I checked this against `deps/ecto_sql/lib/ecto/migrator.ex:660-700`: Ecto uses `Path.wildcard("**/*.{ex,exs}")` and `Integer.parse` of the root name followed by `"_"`. Ecto drops `.ex` files, so looking only at `.exs` gives the same result.
- Install and gen.triggers both call the helper, and both copies of `timestamp/0` are gone (D-04).
- CHANGELOG.md does not put the hidden module's name in backticks (D-05).
- The advice logic in `recommend_storage_schema/1` has the three required branches (fresh, partial, none), and the D-08 paragraph was removed.

I traced the edge cases:

- An empty directory, `count = 0`, a non-timestamp maximum both above and below now, a year rollover, and a timestamp maximum in year 9999. The year-9999 case gives a 15-digit `100000101000000`, which is still unique and in order.
- The `{results, []}` match in `run/1` cannot fail, because `length(pending)` versions are handed to exactly the `pending` families.
- Comparing families that hold `&Mod.fun/0` captures with `family in pending` is safe, because captures of external functions compare equal.

The targeted suite passes: `mix test test/threadline/mix/migration_version_test.exs test/mix/tasks/threadline/install_test.exs` gives 17 tests and 0 failures.

I found no blockers. There is one warning: the adopter workaround in the CHANGELOG does not cover the gen.triggers case that the same entry says was affected. The info items are minor inconsistencies.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: The CHANGELOG workaround misses a gen.triggers migration that shares a version

**File:** `CHANGELOG.md:40-44` (Unreleased, "Required action")

**Issue:** The workaround tells a user on an earlier release to rename only the
`_threadline_semantics_schema.exs` and `_threadline_governance_schema.exs`
prefixes. The same entry (lines 55-57) says `mix threadline.gen.triggers` had
the same bug, and the guides present `install` followed by `gen.triggers` as a
pair. That makes the following sequence realistic when the two commands run in
one scripted second on 0.10.1 or earlier:

- `audit = X`
- `semantics = X`
- `governance = X`
- `threadline_triggers_* = X`

A user who follows the workaround renames semantics and governance, re-runs
`mix ecto.migrate`, and still gets
`migration version X is duplicated`, because audit and the triggers migration
still share `X`. The steps also never mention where the triggers migration has
to sort. It must come after the audit migration, because it depends on the
`threadline_capture_changes()` function that the audit migration creates. A
user who applies the renames literally has no guidance about that file. The
CHANGELOG exists to be found by searching the exact error text, so an
incomplete recovery recipe matters here.

**Fix:** Make the recipe cover every file that shares the duplicated version.
For example:

```markdown
If you are on an earlier release and `mix ecto.migrate` failed with the error
below, rename the numeric prefixes of the Threadline migrations that share the
duplicated version so that every prefix is distinct and the order is audit,
then semantics, then governance, then any `_threadline_triggers_*.exs`
migration. Then re-run `mix ecto.migrate`.
```

## Info

### IN-01: Install checks only the top level for existing migrations, but versions are scanned recursively

**File:** `lib/mix/tasks/threadline.install.ex:175-181` compared with `lib/threadline/mix/migration_version.ex:60-70`

**Issue:**

- `existing_migration?/2` uses `File.ls!`, so it only looks at the top level of the directory.
- `MigrationVersion.existing_versions/1`, like Ecto, also looks in subdirectories.

Suppose a host has moved `..._threadline_audit_schema.exs` into a
subdirectory. Install treats that migration as missing and writes a second
`ThreadlineAuditSchema` migration. The new file gets a distinct version, but
the migration name is duplicated. This behavior predates the phase. It is
worth noting because the new helper's comment says it mirrors Ecto, and the
check that sits next to it does not.

**Fix:** Use the same recursive wildcard in `existing_migration?/2`, for
example `Path.wildcard(Path.join([path, "**", "*" <> suffix])) != []`.

### IN-02: gen.triggers writes to a hard-coded path, so the install-then-triggers guarantee only holds for the default repo layout

**File:** `lib/mix/tasks/threadline.gen.triggers.ex:131-136`

**Issue:** The new comment says running gen.triggers "right after `mix
threadline.install` cannot repeat a version". That only holds when both tasks
use the same directory:

- gen.triggers always uses `"priv/repo/migrations"`.
- Install resolves the repo's `:priv` setting or the repo module name (`install.ex:143-173`).

For a host whose repo is named something like `MyApp.PrimaryRepo`, or that has
a custom `priv:` setting, the two tasks write to different directories. There
is no collision in that case, but the comment overstates what is guaranteed.
The path mismatch predates the phase.

**Fix:** Qualify the comment ("when both write to the same migrations
directory"). Alternatively, have gen.triggers resolve the path the same way
install does, possibly as a follow-up.

### IN-03: The CHANGELOG says every install shared a timestamp

**File:** `CHANGELOG.md:29-31`

**Issue:** "The installer has written the audit and semantics migrations with
a shared one-second timestamp since 0.1.0" reads as if every install produced
a duplicate. In fact the duplicate only happened when the writes fell in the
same second. The example app's migrations are one second apart
(`...080636` and `...080637`). An upgrader whose install worked may find this
wording confusing.

**Fix:** "...has computed each migration's version from the current second
since 0.1.0, so the audit and semantics migrations could share a version..."

### IN-04: The partial re-run test has a redundant assertion and does not check the version format

**File:** `test/mix/tasks/threadline/install_test.exs:209-210`

**Issue:** `governance > 20_991_231_235_958` follows from the next line,
`> 20_991_231_235_959`. Meanwhile, the governance version is not checked to be
a valid 14-digit timestamp (it should be `"21000101000000"`), which the other
version tests do check.

**Fix:** Replace both lines with:

```elixir
assert governance == "21000101000000"
assert_valid_increasing!([governance])
```

---

_Reviewed: 2026-09-24_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
