---
phase: 205-release-reconciliation
plan: 01
subsystem: release
status: complete
tags: [git-merge, release-please, release-pins, installer, contract-test]
requires: [origin/main 471ebf6e (v0.10.0, v0.10.1)]
provides: [v0.10.1 ancestry on the milestone branch, sync-pins contract test, 0.10.1 -> 0.11.0 rehearsal]
affects: [205-02 bookkeeping, v1.41 re-audit]
tech-stack:
  added: []
  patterns: [whole-file conflict resolution per rule table, RED proof by swapping in the pre-merge workflow]
key-files:
  created:
    - test/mix/tasks/threadline/install_test.exs (from origin #46, then credo alias)
    - .planning/phases/205-release-reconciliation/deferred-items.md
  modified:
    - .github/workflows/release.yml
    - .release-please-manifest.json
    - CHANGELOG-GENERATED.md
    - CHANGELOG.md
    - CONTRIBUTING.md
    - README.md
    - bin/verify-bump-rehearsal
    - guides/adoption-evidence-playbook.md
    - guides/adoption-pilot-backlog.md
    - guides/configuration-and-commands.md
    - guides/evaluating-threadline.md
    - guides/getting-started-saas.md
    - guides/operator-surface.md
    - lib/mix/tasks/threadline.install.ex
    - mix.exs
    - test/threadline/changelog_contract_test.exs
    - test/threadline/storage_schema_test.exs
    - test/threadline/release_control_plane_contract_test.exs
decisions:
  - "205-01: origin/main (v0.10.1) merged into the milestone branch as ONE merge commit 0d8ced0c; 17 conflicts resolved whole-file (10 ours, 4 theirs, 3 combined), no marker-only edits"
  - "205-01: sync-release-pr-pins wiring is now pinned by a contract test in release_control_plane_contract_test.exs, proven RED against the pre-merge release.yml"
  - "205-01: verify.threadline is run under MIX_ENV=test (as ci.yml does); the dev env configures no :ecto_repos"
requirements-completed: [RELEASE-02, RELEASE-05]
metrics:
  duration: 11min
  started: 2026-09-24T13:00:35Z
  completed: 2026-09-24T13:11:27Z
estimate:
  tokens: 120000
  tasks: 3
actuals:
  tokens: 15953
  tasks: 3
  commits: 12
plan_head_before: ca99ff7c4b30d41ec1752bd86d6bdbe7cc721df3
---

# Phase 205 Plan 01: Release Reconciliation Merge Summary

origin/main at 471ebf6e (the v0.10.0 and v0.10.1 releases, #44/#45/#46/#48) is now merged into `fix/branch-protection-actions-capability` as one real merge commit. The 17 conflicts were resolved as whole files per the 205-RESEARCH rule table: #46's CR-01 installer fix carries 204-07's flatten, the rehearsal keeps #44's stand-ins alongside 204-02's derived gate, and `@version` is 0.10.1. On the committed HEAD every release gate is green, including the 0.10.1 -> 0.11.0 bump rehearsal and `verify.release` in a clean clone.

## Commits

| Role | SHA | Subject |
|------|-----|---------|
| Pre-merge HEAD ($PRE) | `ca99ff7c4b30d41ec1752bd86d6bdbe7cc721df3` | docs(205): create phase plan — 2 plans, checker passed |
| Merge (parents ca99ff7c, 471ebf6e) | `0d8ced0cc0af86d30fed6d973543305318e541b6` | chore(205-01): merge origin/main (v0.10.1) into the milestone branch |
| Follow-up A | `849707e2` | test(205-01): alias the install task in the merged installer test for credo --strict |
| Follow-up B | `8f846b74` | test(205-01): pin the sync-release-pr-pins job and the bootstrap gate in release.yml |
| Follow-up C | `486a1392` | docs(205-01): name the changelog contract in the bump-rehearsal CI row |

`commits: 12` is `git rev-list --count ca99ff7c..HEAD`, measured from the ledger. It counts the 8 origin-only commits the merge brings in, plus the merge commit and the 3 follow-ups. The first-parent count, which is what this plan authored, is 4.

## Task 1: merge (tracer)

- Preconditions (0) and (a)-(f) all held. Toplevel and branch were correct, origin/main was 471ebf6e, nothing outside `.planning/` had changed since 90b58794, and the merge-base was 5808f140. `merge-tree` listed exactly the expected 17 paths (`diff` clean). The dirty-tree rule held, and both tags were present.
- Group A (ours, 10): every blob equals `$PRE:<path>`. Group B (theirs, 4): every blob equals `origin/main:<path>`.
- `mix.exs` blob `6404f91a…`, matching the reference exactly.
- `lib/mix/tasks/threadline.install.ex` blob `16a90922…`, matching the reference exactly. `recommend_dedicated_storage_schema` occurs 3 times, with 0 zero-arity calls, 1 `repo_migrations_path/1` plus its comment, and 0 `existing_{capture,semantics,governance}_migration?`.
- `bin/verify-bump-rehearsal` blob `52214671…`. The reference is `506baf66…`; the difference is the discretionary OK-message and header-comment wording. The gate chain is exact: derived doc contracts, then the changelog contract, then `mix verify.release || true`. `bash -n` passes and the file is executable.
- The merge changes exactly the 17 planned paths relative to $PRE. release.yml is `064e7ee9`, the manifest `30b6d45a`, CHANGELOG-GENERATED `b47569b5`, the changelog contract `4a4ca794` and install_test `2c7ca706`. `git grep verify\.doc_contract` (excluding .planning and the CHANGELOGs) is empty.
- Tracer verification: ancestry was OK (1 merge commit, parents correct, v0.10.0 and v0.10.1 both ancestors, `HEAD..origin/main` = 0). `compile --force --warnings-as-errors` gave 0 warnings, and the release quick run gave **121 tests, 0 failures**.

## Task 2: follow-ups

- **A:** install_test.exs blob `e105efeb…`, matching the research candidate exactly. credo went from rc=2 ("Nested modules could be aliased…") to "found no issues".
- **B, RED evidence:** I ran the new test against the pre-merge release.yml (`git show $PRE:.github/workflows/release.yml`):
  ```
  1) test the release PR pin-sync job exists, is scoped, and gates the CI bootstrap (Threadline.ReleaseControlPlaneContractTest)
     could not find a "  sync-release-pr-pins:" job in .github/workflows/release.yml
  7 tests, 1 failure, 6 excluded
  ```
  Restored with `git checkout HEAD -- .github/workflows/release.yml`. `git diff --quiet` was clean and the HEAD blob is still `064e7ee9`. GREEN on the merged file: 1 test, 0 failures.
- **C:** changed only the description cell of the CONTRIBUTING `verify-bump-rehearsal` row. The parity and topology contracts still pass: 43 tests, 0 failures across all four files.

## Task 3: gate table (committed HEAD 486a1392)

| # | Gate | Exit | Key output |
|---|------|------|-----------|
| 1 | `mix format --check-formatted` | 0 | clean |
| 2 | `MIX_ENV=test mix verify.credo` | 0 | 3475 mods/funs, found no issues |
| 3 | `mix compile --force --warnings-as-errors` | 0 | Generated threadline app, no warnings |
| 4 | `mix verify.xref_cycles` | 0 | No cycles found |
| 5 | `mix verify.compile_no_optional` | 0 | compiled 126 files |
| 6 | `MIX_ENV=test DB_PORT=5433 mix verify.threadline` | 0 | summary: 1/1 expected tables covered (0 violated). See the deviation note about env. |
| 7 | `MIX_ENV=dev mix verify.dialyzer` | 0 | Total errors: 0, Skipped: 0, Unnecessary Skips: 0 (PLT reused, no rebuild) |
| 8 | `DB_PORT=5433 mix test` | 0 | **1787 tests, 0 failures, 1 excluded**. The first run had 1 environmental failure (D-205-01) and the re-run was clean. |
| 9 | `MIX_ENV=dev mix release.pins --check` | 0 | scanned 20 files; 0 pin sites differ; derived `~> 0.10.0` |
| 10 | `DB_PORT=5433 mix verify.example` | 0 | 117 tests, 0 failures |
| 11 | `DB_PORT=5433 mix verify.bump_rehearsal` | 0 | `==> rehearsing the next minor: 0.10.1 -> 0.11.0`. Gates: 265/0, 7/0, 38/0; tree identity MATCH. `Bump rehearsal OK: a 0.10.1 -> 0.11.0 release commit passes every doc-contract test` |
| 12 | `verify.release` in a clean clone `/Users/jon/.claude/jobs/77cf1bdd/tmp/p205-release` | 0 | clone HEAD `486a1392580da13fcbd02a027b1235c9b46307c9` = real HEAD; 38 tests, 0 failures; Building threadline 0.10.1 |
| 13 | Browser-lane delta | 0 | `git diff --name-only $PRE HEAD -- lib/threadline examples test/fixtures priv` prints nothing, and `grep -rnE 'vsn\|:version\]' lib/threadline/operator_surface` prints nothing. The lane is carried (baseline 326/8/16) and was not run. |
| 14 | No-publish and protected paths | 0 | origin/main still 471ebf6e; tags 56 = recorded 56; `shasum -c` OK ×3; no dirty tracked path outside .planning/ and no intersection with origin's paths; `git diff $PRE HEAD -- .planning` empty before this SUMMARY |

## Deviations from Plan

1. **[Rule 3, invocation env] Gate 6 was run under `MIX_ENV=test`.** Plain `mix verify.threadline` in dev exits 1 with "set :ecto_repos in config — no Ecto repository is configured". ci.yml runs it inside the test job (MIX_ENV=test), where it passes 1/1. No file changed. The merge touches no config, so the outcome would be the same on $PRE.
2. **[Rule 3, environment] Full suite needed one re-run.** On the first run, `CleanCheckoutContractTest:276` collided with a stale `$TMPDIR/threadline-clean-verifier-test-13` left by an earlier crashed run (08:34, before this plan). That file alone passed 9/0 and the full re-run passed 1787/0. Logged as D-205-01 in `deferred-items.md`. It is not added to `.planning/WINDOWS.md` because that file is protected.
3. **Before committing the merge, I ran an extra compile of the staged resolution.** This was a safety check that wrote nothing to tracked files. It gave 0 warnings.
4. **Rehearsal blob differs from the reference** (`52214671` vs `506baf66`) only in the discretionary wording, which the plan allows.

## Known Stubs

None.

## Threat Flags

None. #46's release.yml hardening was taken byte-exact (T-205-01) and is now pinned by Follow-up B.

## Self-Check: PASSED

- Merge commit 0d8ced0c and follow-ups 849707e2, 8f846b74 and 486a1392 exist on HEAD's first-parent chain.
- Files exist: lib/mix/tasks/threadline.install.ex, bin/verify-bump-rehearsal, test/mix/tasks/threadline/install_test.exs, test/threadline/release_control_plane_contract_test.exs, deferred-items.md.
