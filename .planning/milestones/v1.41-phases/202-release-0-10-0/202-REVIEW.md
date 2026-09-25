---
phase: 202-release-0-10-0
reviewed: 2026-09-22T23:30:00Z
depth: standard
files_reviewed: 31
files_reviewed_list:
  - .github/workflows/ci.yml
  - .github/workflows/environment-protection.yml
  - .github/workflows/release.yml
  - .gitignore
  - CHANGELOG-GENERATED.md
  - CHANGELOG.md
  - CONTRIBUTING.md
  - bin/verify-bump-rehearsal
  - bin/verify-environment-protection
  - bin/with-rehearsal-registry
  - guides/getting-started-saas.md
  - guides/upgrade-path.md
  - lib/mix/tasks/release.pins.ex
  - lib/mix/tasks/threadline.install.ex
  - lib/threadline/storage_schema.ex
  - mix.exs
  - priv/ci/hex_evaluator/mix.exs
  - priv/ci/hex_evaluator/test/hex_evaluator/legacy_public_schema_test.exs
  - release-please-config.json
  - test/threadline/adoption_pilot_doc_contract_test.exs
  - test/threadline/changelog_contract_test.exs
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/getting_started_saas_doc_contract_test.exs
  - test/threadline/operator_surface/critic_trust_test.exs
  - test/threadline/operator_surface_doc_contract_test.exs
  - test/threadline/readme_doc_contract_test.exs
  - test/threadline/release_artifact_contract_test.exs
  - test/threadline/release_control_plane_contract_test.exs
  - test/threadline/storage_schema_test.exs
  - test/threadline/version_truth_doc_contract_test.exs
findings:
  critical: 1
  warning: 7
  info: 7
  total: 15
status: issues_found
---

# Phase 202: Code Review Report

**Reviewed:** 2026-09-22T23:30:00Z
**Depth:** standard
**Files Reviewed:** 31 (read from the detached origin/main checkout at `53b5d71a`; diff base `86852f98`)
**Status:** issues_found

## Summary

Phase 202 shipped threadline 0.10.0. It flipped the `storage_schema` default to `public`, split the changelog into a human-owned file and a bot-owned file, added the `mix release.pins` pin writer, the `bin/verify-bump-rehearsal` gate, the local rehearsal registry for the hex evaluator, the post-publish smoke job, the environment-protection check, and (in PR #44) the `sync-release-pr-pins` job.

The release plumbing mostly holds up. The bump rehearsal really is trace-free by construction (a `--no-local` clone under mktemp, removed through `safe-temp-tree`), and its gates fail closed. The pin writer and the version-truth contract agree. The only failure I found in the sync job's push path is a spurious red run; I found no data-loss path there.

The most serious defect is in adopter-facing code, not in the release lane. The new `mix threadline.install` hint tells a new adopter to "re-run `mix threadline.install`" after setting `storage_schema`. The same run has already generated migrations frozen to `public`, and a re-run skips every existing migration. An adopter who follows the instruction gets the split-brain install this phase set out to prevent. Second, `guides/configuration-and-commands.md` still documents the old `"threadline"` default. That page shipped in the 0.10.0 package and on HexDocs.

The release-lane warnings are about hardening:
- **Sync job:** it exposes the PAT to dependency compile code, has no concurrency control, and a failure in it suppresses the CI bootstrap.
- **Rehearsal registry:** it can pick a stale tarball.
- **Test gap:** one legacy-schema test is vacuous about the failure it claims to catch.

Because 0.10.0 is already published, all findings are follow-up work.

## Critical Issues

### CR-01: `mix threadline.install` tells new adopters to "re-run" after setting `storage_schema`, but the run has already frozen migrations into `public` and a re-run skips them

**File:** `lib/mix/tasks/threadline.install.ex:26`, `:71-91` (with `:30-58`, `:117-123`)
**Issue:** `recommend_dedicated_storage_schema/0` prints the hint and then **returns**. `run/1` goes on to generate all three migrations in the same invocation. `Threadline.Capture.Migration.migration_content/0` (`lib/threadline/capture/migration.ex:11`) freezes `StorageSchema.get()`, which is now `"public"`, into the file. The hint then says:

> Add that to `config/config.exs` and re-run `mix threadline.install` if you want it.

On a re-run, `existing_capture_migration?/1` (and the semantics and governance equivalents) match the files the first run just wrote. The task prints "already exists — skipping" and generates nothing. The adopter ends up with:
- `config :threadline, storage_schema: "threadline"` set, so every read path is prefixed with `"threadline".`
- migrations and triggers that create and write to `public`.

That is the exact split brain `legacy_public_schema_test.exs` and the CHANGELOG describe. At best the read paths raise `relation "threadline.audit_changes" does not exist`. At worst the migrations are hand-edited, which is partial and worse. The tool's own printed remediation produces a broken install. The "moving afterwards is deliberate migration work" sentence in the same message contradicts the "re-run" advice.
**Fix:** Stop before generating anything when no schema is configured, or make the remediation match what the task actually does. For example:
```elixir
def run(args) do
  Mix.Task.run("app.config", [])
  {opts, _, _} = OptionParser.parse(args, strict: [accept_public_schema: :boolean])

  if is_nil(Application.get_env(:threadline, :storage_schema)) and
       not Keyword.get(opts, :accept_public_schema, false) do
    Mix.shell().info(recommendation_text())

    unless Mix.shell().yes?("Generate Threadline migrations into the `public` schema?") do
      Mix.raise("Set `config :threadline, storage_schema: ...` and re-run mix threadline.install.")
    end
  end
  ...
```
At minimum, reword the hint to: "delete the generated `*_threadline_*_schema.exs` files, set the key, then re-run". Add a test that asserts the hint's advice actually produces migrations for the configured schema.

## Warnings

### WR-01: `sync-release-pr-pins` compiles every dependency while the release PAT is on disk, and inherits broad workflow permissions

**File:** `.github/workflows/release.yml:120-137` (workflow permissions at `:34-37`)
**Issue:** `actions/checkout@v5` runs with `token: RELEASE_PLEASE_TOKEN || GITHUB_TOKEN` and the default `persist-credentials: true`. That writes the PAT into `.git/config` as an http extraheader. The job then runs `mix deps.get` and `mix release.pins`, and the latter compiles the project and every dev-env dependency. Any code in any compiled dependency, such as `mix.exs` of a dep or compile-time macros, can read that PAT. The PAT is more powerful than `GITHUB_TOKEN`: it triggers workflows, and depending on its scope it can push to other branches. The job also declares no `permissions:`, so its `GITHUB_TOKEN` inherits `contents: write`, `pull-requests: write` and `issues: write`. Before PR #44, no job ran dependency code with the PAT present.
**Fix:** Do not persist credentials during checkout. Provide the token only in the final push step:
```yaml
  sync-release-pr-pins:
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v5
        with:
          ref: release-please--branches--main
          persist-credentials: false
      ...
      - name: Commit and push the pins to the release branch
        env:
          PUSH_TOKEN: ${{ secrets.RELEASE_PLEASE_TOKEN || secrets.GITHUB_TOKEN }}
        run: |
          ...
          git push "https://x-access-token:${PUSH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" \
            HEAD:release-please--branches--main
```
With the `GITHUB_TOKEN` fallback, the job needs `contents: write`. Grant it at job level instead of inheriting the workflow-wide set.

### WR-02: `sync-release-pr-pins` has no concurrency group, so back-to-back pushes to `main` produce spurious red release runs

**File:** `.github/workflows/release.yml:110-152` (see the note at `:39-41`)
**Issue:** The workflow deliberately has no workflow-level concurrency, and the new job adds none. With two quick pushes to `main`, run N can check out release branch head B1 while run N+1's release-please force-pushes B2. Run N's `git push origin HEAD:release-please--branches--main` (line 152, not forced) is then rejected as non-fast-forward. The job goes red and, through WR-03, suppresses the CI bootstrap. Nothing is lost, because run N+1 re-syncs, but the release lane shows a failure that is not one.
**Fix:**
```yaml
  sync-release-pr-pins:
    concurrency:
      group: release-pr-pin-sync
      cancel-in-progress: true
```
Optionally, `git fetch origin release-please--branches--main` and exit 0 when the remote head no longer equals the checked-out SHA, because a newer run owns the sync.

### WR-03: A failed pin sync now silently suppresses the CI bootstrap on the release PR

**File:** `.github/workflows/release.yml:154-168`
**Issue:** `bootstrap-release-pr-ci` now `needs: [release-please, sync-release-pr-pins]`, with no `always()` in its `if:`. When the sync job fails (WR-02, a `mix deps.get` hiccup, or the `--check` step), the bootstrap is **skipped**. On the `GITHUB_TOKEN` fallback path, where no PAT is configured, the dispatch is the only thing that runs CI on the release PR. The PR then shows no checks at all rather than red ones. The documented fallback degrades from "red release PR" to "release PR that never gets a CI run".
**Fix:**
```yaml
    if: >-
      always() &&
      github.event_name == 'push' &&
      needs.release-please.outputs.prs_created == 'true' &&
      needs.release-please.result == 'success'
```
This still orders the dispatch after the sync, but a failed sync then produces a red CI run on the stale pins instead of none.

### WR-04: `bin/with-rehearsal-registry` can package a stale gitignored tarball and prove the wrong artifact

**File:** `bin/with-rehearsal-registry:116-123`
**Issue:** After `mix hex.build`, the script picks the tarball with `ls -1 threadline-*.tar | head -n 1`. `/threadline-*.tar` is gitignored (`.gitignore:8`), and `mix verify.release` (`mix hex.build`) leaves one in the repo root on every run, so stale tarballs pile up locally. `ls` sorts them lexically. Take a maintainer who ran `mix verify.release` at 0.10.0 and has bumped to 0.11.0. `threadline-0.10.0.tar` sorts before `threadline-0.11.0.tar`, so the **stale** tarball is moved into the registry and served. The evaluator (`">= 0.0.0"`) resolves it and goes green against an old build. That is the "keeps re-proving the last release" failure this script exists to remove (header lines 7-11). CI is unaffected because its checkouts are clean, but the local `mix verify.hex_evaluator` becomes vacuous.
**Fix:** Build to a deterministic path derived from `@version`:
```bash
VERSION="$(sed -n 's/^[[:space:]]*@version "\([^"]*\)".*/\1/p' mix.exs | head -1)"
[[ -n "$VERSION" ]] || { echo "cannot read @version" >&2; exit 1; }
mix hex.build --output "$PUBLIC_DIR/tarballs/threadline-${VERSION}.tar"
```

### WR-05: `guides/configuration-and-commands.md` still documents `"threadline"` as the default, and it shipped in 0.10.0

**File:** `guides/configuration-and-commands.md:32` (not in the changed-file list; the phase's `storage_schema.ex` flip made it wrong)
**Issue:** The configuration reference row for `storage_schema` says the default is `"threadline"`, and "Use `"public"` only as an explicit host choice". The published tree (`3d148435`) carries this line, and `guides/` is in `package[:files]`. So the 0.10.0 tarball and HexDocs contradict `Threadline.StorageSchema` (`@default "public"`), the CHANGELOG, getting-started and upgrade-path. A new adopter reading the canonical reference will think they get schema isolation by default. They get `public`. `readme_doc_contract_test.exs` only asserts that this page contains `config :threadline, storage_schema:`, so no contract caught it.
**Fix:** Change the default cell to `"public"` (the host's default schema). Mark a dedicated schema such as `"threadline"` as the recommended opt-in for new installs. Add a doc-contract assertion, for example `refute reference =~ ~r/\| `"threadline"`\. Use `"public"` only/`, plus a positive check for the `"public"` default.

### WR-06: The legacy-schema "reads back" test does not exercise Threadline's read path, so it cannot catch the split brain it claims to catch

**File:** `priv/ci/hex_evaluator/test/hex_evaluator/legacy_public_schema_test.exs:94-114`
**Issue:** The test queries `from(ac in AuditChange, ...)` through `Repo.aggregate/2` and `Repo.one!/1` with no prefix. `Threadline.Capture.AuditChange` declares no `@schema_prefix` (`lib/threadline/capture/audit_change.ex:46`). The query therefore always resolves through the connection's `search_path` (`public`), whatever `Threadline.StorageSchema.get/1` returns. The failure message says "If the read came back empty, Threadline.Capture.AuditChange is resolving against a different schema than the triggers write to". That cannot happen here, because the storage schema is never consulted. Threadline's real read paths apply the prefix through `Threadline.Query.storage_opts/2` and `StorageSchema.repo_opts/1`. Only the separate `get([]) == "public"` test (line 48) protects the default. This test adds no coverage while claiming to be the end-to-end proof.
**Fix:** Read through the path adopters actually use:
```elixir
assert Repo.aggregate(query, :count, Threadline.StorageSchema.repo_opts()) >= 1
```
Better still, call a public façade such as a `Threadline` history or timeline function with no `storage_schema` option, so a default regression breaks the read the way an adopter would see it.

### WR-07: The environment-protection check does not verify the property the publish-gate mitigation depends on, which is that `HEX_API_KEY` is only reachable through `production-hex`

**File:** `bin/verify-environment-protection:63-175`; claim at `.github/workflows/release.yml:439-443`
**Issue:** `release.yml` justifies the long-lived key as "reachable only after the `production-hex` required-reviewer approval". That holds only if `HEX_API_KEY` is an **environment** secret of `production-hex` and not a repository secret. A repository secret is readable by any workflow job on any branch a write-collaborator pushes, and the reviewer gate does not apply to it. The script checks that a reviewer rule exists (half a) and that the publish job names the environment (half b). It never checks where the secret lives. I cannot tell from source which scope is configured. The point is that the check CONTRIBUTING.md describes as "the live half of that claim" does not measure the claim. A reviewer rule plus a repository-scoped key would pass this check with the gate bypassable.
**Fix:** Add a half (c). Assert that `gh api repos/$REPO/environments/production-hex/secrets --jq '.secrets[].name'` contains `HEX_API_KEY` and that `gh api repos/$REPO/actions/secrets --jq '.secrets[].name'` does not. Both calls need a token with secrets-metadata read, so follow the script's existing fail-closed and explicit opt-out pattern. Otherwise, narrow the wording in `release.yml` and CONTRIBUTING.md to what is actually verified.

## Info

### IN-01: The rehearsal's signal trap can exit 0 on INT/TERM, and a pre-trap failure leaks the temp parent

**File:** `bin/verify-bump-rehearsal:192-221`
**Issue:** `trap cleanup EXIT INT TERM` reuses the EXIT handler for signals. `cleanup` exits with `$?`, which is 0 if the signal lands between commands. So a Ctrl-C can return success without printing "OK". Separately, the `fail` calls at lines 196-198 (`mkdir "$CLONE"` failing, or `safe_temp_tree_register` refusing) run before the trap is installed, which leaves `$TRUSTED_PARENT` behind under `$TMPDIR`. The real working tree is unaffected in both cases.
**Fix:** Use separate handlers, `trap 'cleanup_and_exit 130' INT; trap 'cleanup_and_exit 143' TERM`, and install a parent-only `rmdir` trap immediately after `mktemp -d`.

### IN-02: The rehearsal checks HEAD, not the working tree, and does not warn when the tree is dirty

**File:** `bin/verify-bump-rehearsal:223-232`
**Issue:** Locally, uncommitted edits are silently excluded (the clone is of `HEAD`), so "Bump rehearsal OK" can describe a tree other than the one on disk. CI is unaffected.
**Fix:** If `git status --porcelain --untracked-files=no` is non-empty, print a notice naming the SHA actually rehearsed.

### IN-03: Unknown `THREADLINE_BUMP_REHEARSAL_INJECT_DEFECT` values are silently ignored

**File:** `bin/verify-bump-rehearsal:252`, `:308`, `:372`
**Issue:** A typo such as `hardcoded_pin` runs a normal rehearsal and prints OK. The operator then concludes the gate has no teeth.
**Fix:** `case "$INJECT" in none|hardcoded-pin|stale-marked-line) ;; *) fail "unknown control" ...; esac`.

### IN-04: CHANGELOG-GENERATED.md keeps a now-false placeholder, and its header claims hand edits are overwritten

**File:** `CHANGELOG-GENERATED.md:135-157`
**Issue:** After release-please's first write, the demoted `## Generated release notes` block still ends with "_No generated release notes yet. release-please writes the first entry here at 0.10.0._", which is false now that the 0.10.0 entry sits above it. The comment also says "any hand edit is overwritten on the next run". release-please only prepends, so hand edits persist, and the stale line will stay forever unless someone edits it by hand.
**Fix:** Delete the placeholder line once. Reword the claim to "release-please prepends entries; do not hand-edit".

### IN-05: The version-marker ownership guards only recognise same-line markers

**File:** `test/threadline/version_truth_doc_contract_test.exs:110-139`; `bin/verify-bump-rehearsal:290-296`
**Issue:** Family B-inverse refutes `x-release-please-version` only on the pin line itself. The rehearsal's updater simulation also rewrites only same-line markers. release-please's generic updater also honours `x-release-please-start-version` … `x-release-please-end` blocks, so a pin inside such a block would be bot-owned without either guard noticing. No such block exists today.
**Fix:** Make the contract refute `x-release-please-start-` anywhere in README and `guides/`. Alternatively, teach both the contract and the simulation about block markers.

### IN-06: The rehearsal registry's port probe cannot tell its own server from a foreign listener

**File:** `bin/with-rehearsal-registry:133-153`
**Issue:** The default port 4173 is also Vite's `preview` default. If it is already taken, `inets:start/2` returns `{error, eaddrinuse}`, but the `erl -noshell` VM keeps running. The `gen_tcp:connect` probe then succeeds against the other process, and the failure surfaces later as an opaque Hex fetch error. The run still fails, so this is a diagnosability problem, not a false pass.
**Fix:** Make the server `halt(1)` unless `inets:start` returns `{ok, _}`, and probe with an HTTP GET for `/names` rather than a bare TCP connect.

### IN-07: CHANGELOG "Breaking changes: None" sits next to a raised dependency floor and a narrowed callback

**File:** `CHANGELOG.md` 0.10.0 entry (`### Breaking changes`, `### Required action`); `guides/upgrade-path.md` 0.9.x → 0.10.x row
**Issue:** The entry decides "not breaking" by the absence of breaking-change commit footers. It then lists an `:ex_aws` floor raised from `~> 2.4` to `~> 2.7`, which it calls "not additive" itself, a dependency swap from `:hackney` to `:req`, and a narrowed `c:Threadline.Storage.put/2` type. For affected adopters, those can fail dependency resolution or Dialyzer. The "Required action" section is there, but "None" plus a commit-footer rationale understates the risk for S3 adopters.
**Fix:** Say "None for hosts that do not export to S3 or implement `Threadline.Storage`". Drop the footer-based rationale.

---

_Reviewed: 2026-09-22T23:30:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
