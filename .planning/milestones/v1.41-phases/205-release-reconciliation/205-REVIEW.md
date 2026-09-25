---
phase: 205-release-reconciliation
reviewed: 2026-09-24T13:30:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - lib/mix/tasks/threadline.install.ex
  - mix.exs
  - bin/verify-bump-rehearsal
  - test/threadline/release_control_plane_contract_test.exs
  - test/mix/tasks/threadline/install_test.exs
  - .github/workflows/release.yml
findings:
  critical: 1
  warning: 4
  info: 4
  total: 9
status: issues_found
---

# Phase 205: Code Review Report

**Reviewed:** 2026-09-24T13:30:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Scope: the 205 merge (`0d8ced0c`) and its follow-ups (`849707e2`, `8f846b74`), diffed against `ca99ff7c`.

**The merge resolution itself is correct.**
- `lib/mix/tasks/threadline.install.ex` differs from `origin/main` (#46) only by the 204-07 `repo_migrations_path/1` flatten.
- The pre-generation `recommend_dedicated_storage_schema()` call and the `/0` function are gone. `recommend_dedicated_storage_schema` appears exactly 3 times: the post-generation call at :56 and the two `/1` clauses at :80 and :82. **202-REVIEW CR-01 has not come back.**
- `mix.exs` differs from the pre-merge HEAD only in `@version "0.10.1"`.
- `release.yml` has #46's `sync-release-pr-pins` job and hardening byte-for-byte.
- The rehearsal's gate chain matches the rule table.

The defects are in the code the merge carried in and in the new test:
1. **Blocker (CR-01).** The installer writes all three migrations with the same Ecto version, so a fresh `mix threadline.install && mix ecto.migrate` fails. I reproduced this. The bug predates the merge, but #46's `generate/4` refactor kept it and #46's tests do not catch it.
2. **Token isolation (WR-01).** The sync job's "token supplied to the push step alone" can be bypassed by the dependency code the job compiles.
3. **Contract test (WR-02).** The new test is not vacuous, since it went RED against the pre-merge file. But it does not pin the permission scoping its title claims, and several of its messages claim more than it checks.
4. **Rehearsal control (WR-04).** One negative control in the rehearsal has drifted since the version moved to a patch release.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: All three generated migrations share one version, so `mix ecto.migrate` refuses to run on a fresh install

**File:** `lib/mix/tasks/threadline.install.ex:30-50, 60-68, 155-158`

**Issue:**
- Each `generate/4` call computes `timestamp()` on its own, at one-second resolution. All three calls run in the same second on any normal machine, so the files get the same version prefix.
- I reproduced it against the merged HEAD: `MIX_ENV=test mix run --no-start -e 'File.cd!("/tmp/tlx", fn -> Mix.Tasks.Threadline.Install.run([]) end)'` wrote:
  ```
  priv/repo/migrations/20260924132031_threadline_audit_schema.exs
  priv/repo/migrations/20260924132031_threadline_semantics_schema.exs
  priv/repo/migrations/20260924132031_threadline_governance_schema.exs
  ```
- `Ecto.Migrator.run/4` calls `ensure_no_duplication!(pending)` (`deps/ecto_sql/lib/ecto/migrator.ex:456, 708-712`), which raises `Ecto.MigrationError: migrations can't be executed, migration version 20260924132031 is duplicated`.
- So the documented path in `guides/getting-started-saas.md:87` (install, then migrate) fails on a fresh install. So does the "delete and re-run" advice that #46 added, because re-running regenerates three files that again share one timestamp.
- Even if the versions were unique, the order between semantics/governance and capture would depend only on the version, so it must be strictly increasing.
- The bug predates 205. The example app shows it was only ever dodged by luck: `20260424080636_threadline_audit_schema.exs` and `...080637_threadline_semantics_schema.exs` fall one second apart. #46's refactor into `generate/4` kept it.
- `install_test.exs` only counts files (`assert length(files) == 3`), so it cannot see it.

**Fix:** derive one base timestamp and give each file a strictly increasing version. Also make sure the base is above any existing migration version, so a fast re-run cannot collide with files it did not write.
```elixir
def run(_args) do
  Mix.Task.run("app.config", [])
  path = migrations_path()
  File.mkdir_p!(path)
  base = :calendar.universal_time() |> NaiveDateTime.from_erl!()

  written =
    [
      {"_threadline_audit_schema.exs", "Threadline audit schema migration",
       &Threadline.Capture.Migration.migration_content/0},
      {"_threadline_semantics_schema.exs", "Threadline semantics schema migration",
       &Threadline.Semantics.Migration.migration_content/0},
      {"_threadline_governance_schema.exs", "Threadline governance schema migration",
       &Threadline.Governance.Migration.migration_content/0}
    ]
    |> Enum.with_index()
    |> Enum.map(fn {{suffix, label, fun}, i} ->
      generate(path, suffix, label, fun, NaiveDateTime.add(base, i, :second))
    end)
    |> Enum.reject(&is_nil/1)
  ...
end

defp timestamp(%NaiveDateTime{} = t),
  do: Calendar.strftime(t, "%Y%m%d%H%M%S")
```
Add a regression test to `install_test.exs`: take the numeric prefixes of `generated(tmp)`, then assert they are pairwise distinct and that audit < semantics < governance.

## Warnings

### WR-01: The sync job's "token supplied to the push step alone" can be bypassed by the dependency code it compiles

**File:** `.github/workflows/release.yml:127-169`

**Issue:**
- The job's stated threat model (lines 127-130, and 202-REVIEW WR-01) is that compile-time code in a dependency must not be able to reach the push credential. `persist-credentials: false` plus a step-scoped `PUSH_TOKEN` closes only the `.git/config` vector.
- Arbitrary code in a dependency runs during `mix deps.get` and `mix release.pins` (lines 141-148). That code can still reach the token in later steps in three ways:
  (a) Write `.git/hooks/pre-commit` or `.git/hooks/pre-push` into the checkout. Lines 167-168 run `git commit` and `git push` with `PUSH_TOKEN` in the environment, and those hooks run with it.
  (b) Append to `$GITHUB_ENV` or `$GITHUB_PATH`, for example to put a `git` wrapper ahead on PATH or to set `BASH_ENV`. Both files are honoured by every later step, including the push step.
  (c) Leave a background process running. The Actions runner does not kill orphans between steps. The token sits in `git push`'s argv, in the URL on line 168, so such a process can read it from `/proc/*/cmdline`.
- The mitigation is real but narrower than the comment and the contract-test message claim. The token here is the `RELEASE_PLEASE_TOKEN` PAT whenever one is configured, which reaches beyond this job's `contents: write`.

**Fix:** split the job so that no job both compiles third-party code and holds a push credential.
- Job 1 (`permissions: contents: read`, no secrets) runs `mix release.pins` and `--check`, then uploads `git diff --binary` as an artifact.
- Job 2 (`needs:` job 1; no `mix`, no setup-beam) checks out with `persist-credentials: false`, runs `git apply` on the artifact, and pushes.

At a minimum, harden the push step:
```bash
git -c core.hooksPath=/dev/null commit --no-verify -m "..."
git -c core.hooksPath=/dev/null \
    -c http.https://github.com/.extraheader="AUTHORIZATION: basic $(printf 'x-access-token:%s' "$PUSH_TOKEN" | base64 -w0)" \
    push --no-verify "https://github.com/${GITHUB_REPOSITORY}.git" HEAD:release-please--branches--main
```
Also update the comment at lines 127-130 so it states the residual `$GITHUB_ENV`/`$GITHUB_PATH` exposure honestly.

### WR-02: The new contract test says "is scoped" but pins no permissions, no trigger guard, and no token location

**File:** `test/threadline/release_control_plane_contract_test.exs:122-159`

**Issue:** The test does fail if the job is absent (proven RED against the pre-merge file), so it is not vacuous. But a future edit or merge can undo most of the #46 hardening it cites while every assertion stays green:
- **Job permissions.** Nothing asserts the job-level `permissions:\n      contents: write` block (release.yml:124-125). Deleting it makes the job inherit the workflow-level `contents`, `pull-requests` and `issues: write` (release.yml:34-37). The test title's "is scoped" is not checked at all.
- **Token location.** `length(Regex.scan(~r/^\s+PUSH_TOKEN:/m, sync)) == 1` accepts a single job-level `env:` binding, which exposes the token to the dependency compile steps. The failure message ("in the push step's env ... to the push step alone") claims something the regex does not check. The test also does not reject other `${{ secrets.` references in the block, such as a `token:` on the checkout step.
- **Checkout scope.** `persist-credentials: false` is matched anywhere in the block, not on the `actions/checkout` step.
- **Comment matches.** `sync =~ "mix release.pins --check"` is satisfied by a comment line.
- **Trigger guards.** Neither job's `if:` guard (`github.event_name == 'push' && needs.release-please.outputs.prs_created == 'true'`) is pinned. A bootstrap reduced to `if: always()` passes, and it would then dispatch CI on every push to main and on `workflow_dispatch`.

**Fix:**
```elixir
assert sync =~ ~r/^    permissions:\n      contents: write\n    steps:/m, "... must be scoped to contents: write"
refute sync =~ ~r/^    env:/m, "no job-level env: the token must not reach the compile steps"
[_, push_step] = String.split(sync, "- name: Commit and push the pins", parts: 2)
assert push_step =~ ~r/^\s+PUSH_TOKEN: \$\{\{ secrets\./m
assert length(Regex.scan(~r/\$\{\{\s*secrets\./, sync)) == 1
assert sync =~ ~r/^\s+run: mix release\.pins --check$/m
guard = "github.event_name == 'push' && needs.release-please.outputs.prs_created == 'true'"
assert sync =~ "    if: #{guard}\n"
assert bootstrap =~ "    if: always() && #{guard}\n"
```

### WR-03: "Nothing written" is used as a stand-in for "existing install", so partial re-runs give advice that splits schemas

**File:** `lib/mix/tasks/threadline.install.ex:52-56, 71-82`

**Issue:**
- The comment at :78-79 says that when nothing was written, which it treats as an existing install, the advice is withheld. The code only withholds it when *all three* migrations already exist.
- A pre-75-01 install on `public` has audit and semantics but no governance migration. Re-running the task writes only the governance migration, so `written == [governance]`.
- The task then prints the full "For a NEW install ... 1. Delete the migration files this run just generated ... 2. set `storage_schema: "threadline"` ... 3. Re-run" advice.
- An operator who follows it gets governance tables in `threadline` while capture and semantics stay in `public`. Their config then points every read path at a schema that does not hold the capture tables.
- This is the same class of error CR-01 in 202-REVIEW fixed. The trailing "Existing installs need no action" paragraph contradicts the numbered steps just above it instead of preventing this.

**Fix:** withhold (or change) the advice whenever *any* Threadline migration was skipped:
```elixir
results = [generate(...), generate(...), generate(...)]   # {:written, file} | :skipped
written = for {:written, f} <- results, do: f
fresh_install? = Enum.all?(results, &match?({:written, _}, &1))
if fresh_install?, do: recommend_dedicated_storage_schema(written)
```
Add an `install_test.exs` case: pre-create a `*_threadline_audit_schema.exs`, run the task, and `refute output =~ "No \`:storage_schema\` is configured"`.

### WR-04: The `hardcoded-pin` negative control no longer models the defect class at a patch version

**File:** `bin/verify-bump-rehearsal:380-384`

**Issue:**
- The control is meant to re-inject the 202-09 defect: a literal pin that is green at the current version and red only after the bump.
- It injects `"~> $CURRENT"`. When the control was written, CURRENT was `0.9.0`, and `~> 0.9.0` equalled the derived pin.
- CURRENT is now `0.10.1`. `Mix.Tasks.Release.Pins.target_pin_version/0` (`lib/mix/tasks/release.pins.ex:119-122`) derives `0.10.0`, so the injected `~> 0.10.1` is already wrong at the current version.
- The control still goes red, but for a different reason (a pin that was never right), not the "green now, red after the bump" class it exists to prove. It will keep drifting on every patch release.

**Fix:**
```bash
CUR_PIN="${CURRENT%.*}.0"
CUR_PIN="$CUR_PIN" perl -pi -e \
  's/~s\(\{:threadline, "~> #\{Mix\.Tasks\.Release\.Pins\.target_pin_version\(\)\}"\}\)/"{:threadline, \\"~> $ENV{CUR_PIN}\\"}"/' \
  "$CONTRACT"
grep -qF "~> $CUR_PIN" "$CONTRACT" || fail ...
```

## Info

### IN-01: `always()` on the bootstrap also fires on cancelled runs

**File:** `.github/workflows/release.yml:180`

**Issue:** `sync-release-pr-pins` uses `cancel-in-progress: true` (line 121). When a newer push cancels it, the superseded run's bootstrap still dispatches CI against an intermediate branch head. A run the user cancels by hand also still dispatches.

**Fix:** use `!cancelled() && github.event_name == 'push' && ...`. This still covers the failed-sync case that WR-03 of 202-REVIEW wanted.

### IN-02: With the PAT configured, the release PR gets two CI runs per sync

**File:** `.github/workflows/release.yml:150-152, 185-188`

**Issue:** The comment says the PAT push is what triggers CI. The bootstrap then also runs `gh workflow run ci.yml` unconditionally, so every PAT-backed sync produces a `push`-triggered run and a `workflow_dispatch` run on the same head.

**Fix:** have the sync job output `pushed=true|false` and whether a PAT was used, and skip the dispatch when a PAT push already triggered CI. Or document the duplication as intended.

### IN-03: The rehearsal commits `--all`, but the real sync job stages only `README.md guides/`

**File:** `bin/verify-bump-rehearsal:411-415` vs `.github/workflows/release.yml:160`

**Issue:** The two currently agree only because `release.pins` scans exactly `README.md` and `guides/**/*.md` (`lib/mix/tasks/release.pins.ex:100`). If the pin writer ever covers another file, the real job would silently leave that change unstaged and the release PR would be born red. The rehearsal would stay green, because its `git commit --all` picks the file up.

**Fix:** in the rehearsal, stage the pin-writer output the way the workflow does (`git add -- README.md guides/` plus the explicit stand-in and release-please paths). Alternatively, derive both from one list that `mix release.pins` exposes.

### IN-04: `repo_migrations_path/1` hand-rolls Ecto's migrations-path resolution

**File:** `lib/mix/tasks/threadline.install.ex:133-145`

**Issue:** This copies Ecto's `:priv` default (`priv/<underscored repo name>`). It ignores the repo's `:otp_app` (umbrella children) and any future change in Ecto. The blanket `rescue _ ->` at :129-130 also hides a misconfigured repo by silently writing to `priv/repo/migrations`.

**Fix:** consider `Ecto.Migrator.migrations_path(repo) |> Path.relative_to_cwd()`. Replace the silent fallback with a `Mix.shell().error` that names the path chosen.

---

_Reviewed: 2026-09-24T13:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
