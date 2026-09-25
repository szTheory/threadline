---
phase: 205-release-reconciliation
verified: 2026-09-24T13:55:00Z
status: passed
score: 14/14 must-haves verified
covered_files:
  - ".github/workflows/release.yml"
  - ".planning/REQUIREMENTS.md"
  - ".planning/phases/202-release-0-10-0/202-VERIFICATION.md"
  - ".planning/phases/202-release-0-10-0/deferred-items.md"
  - ".planning/phases/205-release-reconciliation/205-01-PLAN.md"
  - ".planning/phases/205-release-reconciliation/205-01-SUMMARY.md"
  - ".planning/phases/205-release-reconciliation/205-02-PLAN.md"
  - ".planning/phases/205-release-reconciliation/205-02-SUMMARY.md"
  - ".release-please-manifest.json"
  - "CHANGELOG-GENERATED.md"
  - "CHANGELOG.md"
  - "CONTRIBUTING.md"
  - "README.md"
  - "bin/verify-bump-rehearsal"
  - "guides/adoption-evidence-playbook.md"
  - "guides/adoption-pilot-backlog.md"
  - "guides/configuration-and-commands.md"
  - "guides/evaluating-threadline.md"
  - "guides/getting-started-saas.md"
  - "guides/operator-surface.md"
  - "lib/mix/tasks/threadline.install.ex"
  - "mix.exs"
  - "test/mix/tasks/threadline/install_test.exs"
  - "test/threadline/changelog_contract_test.exs"
  - "test/threadline/release_control_plane_contract_test.exs"
  - "test/threadline/storage_schema_test.exs"
covered_digest: "v1:sha256:38ca5a86eb2a0ccef8989991a0b605e0116af1fea3461958198b1c10a9bed773"
behavior_unverified: 0
overrides_applied: 0
advisory:
  - finding: "205-REVIEW CR-01: `mix threadline.install` writes all three migrations with the same one-second `timestamp()`, so `mix ecto.migrate` on a fresh install raises `migration version ... is duplicated`."
    category: other
    reason: "Real adopter-facing defect, but not introduced by and not in scope of 205. The same per-file `timestamp()` pattern is at v0.9.0 (install.ex:32/42/52), at pre-merge ca99ff7c (:36/46/56) and on origin/main 471ebf6e (which shipped v0.10.1). 205's install.ex differs from origin/main only by the 204-07 `repo_migrations_path/1` flatten. It does not make any release gate or the next release PR red (install_test.exs only counts files). To resolve: a follow-up fix(...) plan with the review's strictly-increasing-version fix plus a regression test on the numeric prefixes; it should be tracked (seed/todo) before v1.41 close, since it is releasable and adopter-visible."
    evidence_status: "reviewer reproduction only; not re-run here (would write into a scratch app dir)"
  - finding: "205-REVIEW WR-02: the new sync-pins contract test is weaker than its messages. `PUSH_TOKEN` is asserted as bound once (not bound in the push step), `mix release.pins --check` can match a comment, and job `permissions: contents: write` and both jobs' `if:` trigger guards are not pinned."
    category: other
    reason: "The test is not vacuous: `job_block!/2` raises on the pre-merge release.yml (0 occurrences of `sync-release-pr-pins` at ca99ff7c), and at HEAD the release.yml is byte-identical to origin/main, so the wiring itself is correct today. The gap is regression-guard strength only. To resolve: tighten the assertions as WR-02 proposes."
    evidence_status: "none provided (no offending workflow exists at HEAD)"
  - finding: "205-REVIEW WR-04: the rehearsal's `hardcoded-pin` negative control injects `~> $CURRENT` (now `~> 0.10.1`), which is wrong at the current version rather than modelling the green-now/red-after-bump class."
    category: other
    reason: "Affects the negative control only; the positive rehearsal (0.10.1 -> 0.11.0) was re-run here and passed. To resolve: inject `~> ${CURRENT%.*}.0`."
    evidence_status: "none provided"
  - finding: "205-REVIEW WR-01/WR-03 and IN-01..IN-04 (release.yml token isolation vs dependency compile code; installer advice on partial re-runs; always() on cancelled runs; double CI dispatch; rehearsal `commit --all` vs sync job's explicit staging; hand-rolled migrations path)."
    category: security
    reason: "All carried in byte-identical from origin/main (#46) or pre-existing; none is introduced by the 205 merge and none breaks the release flow's wholeness on the branch. Track with the 202 open items (WR-04/06/07) for a later hardening phase."
    evidence_status: "none provided"
  - finding: "Protected-path fingerprint: `.planning/config.json` no longer matches `.git/gsd-205-protected.sha256` (recorded 09:00:35). The only delta vs HEAD's tracked copy is `workflow._auto_chain_active: true -> false`; file mtime 09:18:40, 33 s after 205-02-SUMMARY.md was written."
    category: other
    reason: "No 205 commit touches config.json (checked every commit ca99ff7c..HEAD). The change is the ephemeral auto-chain flag that `workflows/execute-phase.md:173` clears via `config-set workflow._auto_chain_active false`, i.e. the orchestrator workflow, not the executor. `.planning/WINDOWS.md` and `.tool-versions` still match their recorded SHA-256. Orchestrator should confirm it made this write."
    evidence_status: "attribution by timestamp and workflow source; not proven"
---

# Phase 205: Release Reconciliation Verification Report

**Phase Goal:** The milestone branch contains every commit Phase 202 shipped on `origin/main` (tag `v0.10.0`, and v0.10.1, is an ancestor of HEAD), with 203/204's changes preserved through the merge, so the release flow (release-please → sync-release-pr-pins → verify.release → single publish) is whole on the branch and the next release PR would be green by construction.
**Verified:** 2026-09-24T13:55:00Z at HEAD `a5dfdd34` (working tree differs only in `.planning/WINDOWS.md`, `.planning/config.json`, untracked `.tool-versions` and `.gitkeep`)
**Status:** passed
**Re-verification:** No. This is the initial verification.

## Goal Achievement

### Observable Truths

ROADMAP Phase 205 has no separate success-criteria list, so the goal sentence plus the two plans' `must_haves` are the contract.

| # | Truth | Status | Evidence (measured independently here) |
|---|-------|--------|----------------------------------------|
| 1 | One merge commit with parents PRE and origin/main 471ebf6e; v0.10.0 and v0.10.1 ancestors; `HEAD..origin/main` = 0 | ✓ VERIFIED | `git cat-file -p 0d8ced0c`: parents `ca99ff7c…` and `471ebf6e…`. `merge-base --is-ancestor` v0.10.1 and v0.10.0 both rc=0. `rev-list --count HEAD..origin/main` = 0. `rev-list --merges --first-parent ca99ff7c..HEAD` = 1. All 8 origin commits (86852f98 … 471ebf6e) keep their original SHAs, so nothing was rebased or cherry-picked. |
| 2 | Conflicts resolved whole-file per the rule table (10 ours, 4 theirs, 3 combined) | ✓ VERIFIED | I recomputed the merge with `git merge-tree --write-tree ca99ff7c origin/main`. It gives exactly 17 conflicted paths, and every non-conflicted path in 0d8ced0c equals git's auto-merge tree. For each conflicted path I compared blobs against #43 (`23f0505a`). In every "ours" file, theirs equals #43. In every "theirs" file, ours equals #43. So each whole-file choice drops nothing either side added. mix.exs blob `6404f91a` matches the plan exactly. install.ex blob `16a90922` matches, and every non-comment line #46 added since #43 is present. Every non-comment line origin added to the rehearsal is present, except the old OK-message `printf` that named the retired `verify.doc_contract`. |
| 3 | The merge changes exactly the 17 planned paths; no `lib/threadline/**` or `.planning/**` change | ✓ VERIFIED | `git diff --name-only ca99ff7c 0d8ced0c` lists exactly the 17 paths. `git diff --name-only ca99ff7c HEAD -- lib/threadline test/fixtures examples priv` is empty. |
| 4 | Version metadata is 0.10.1 and automation-owned | ✓ VERIFIED | mix.exs:4 `@version "0.10.1"`. Manifest `".": "0.10.1"`. `MIX_ENV=dev mix release.pins --check`: rc=0, 20 files, 0 differ, derived `~> 0.10.0`. |
| 5 | Release flow whole: sync-release-pr-pins job wired, bootstrap gated on it, pinned by a contract test proven RED pre-merge | ✓ VERIFIED | HEAD release.yml is byte-identical to origin/main. It has the job with `needs: release-please`, `persist-credentials: false`, `mix release.pins` and `--check`, `PUSH_TOKEN` only in the push step env, and concurrency group `sync-release-pr-pins`. `bootstrap-release-pr-ci` has `needs: [release-please, sync-release-pr-pins]` and `if: always() && …`. Test L#122 ran (`--trace`, 7 tests, 0 failures). It is RED by construction on the pre-merge file (`git show ca99ff7c:.github/workflows/release.yml \| grep -c sync-release-pr-pins` = 0, so `job_block!` raises). The test's precision gaps are logged as advisory (WR-02). |
| 6 | Installer carries #46's CR-01 fix and not the zero-arity advice | ✓ VERIFIED | `grep -c recommend_dedicated_storage_schema` = 3. No `recommend_dedicated_storage_schema()` call. |
| 7 | Retired `verify.doc_contract` did not return | ✓ VERIFIED | The `git grep` (excluding .planning and the CHANGELOGs) prints nothing (rc=1). |
| 8 | Phase gates green on committed HEAD | ✓ VERIFIED | Re-run here: `mix format --check-formatted` rc=0. `MIX_ENV=test mix verify.credo` found no issues (3475 mods/funs). `compile --warnings-as-errors` rc=0. Full `DB_PORT=5433 mix test` at a5dfdd34: **1787 tests, 0 failures, 1 excluded** (rc=0, one run). `mix verify.bump_rehearsal` rc=0: `0.10.1 -> 0.11.0`, 265/0, 7/0, 38/0, tree identity MATCH, `Bump rehearsal OK`. `mix verify.release` in a fresh `git clone --no-local` at `/Users/jon/.claude/jobs/77cf1bdd/tmp/v205-verify` (HEAD a5dfdd34) rc=0: 38 tests, 0 failures, `Building threadline 0.10.1`. Not re-run: xref_cycles, compile_no_optional, verify.threadline, dialyzer, verify.example. These rest on the 205-01 gate table, and the tree has changed no non-.planning file since 486a1392. |
| 9 | Rendered output unchanged; byte-lock/render contracts pass with no repin | ✓ VERIFIED | No lib/threadline, test/fixtures, examples or priv diff vs PRE. `rendered_output_contract_test.exs` passes in the focused run (121/0) and in the full suite. |
| 10 | 202-VERIFICATION carries a dated append-only Phase 205 addendum; frontmatter and the 53b5d71a NOTE are untouched | ✓ VERIFIED | Heading at :207. numstat vs ca99ff7c is 21 added, 0 removed. NOTE still at :29. Its values match what I measured (the full-suite and clean-clone evidence was at 486a1392, and I reproduced both at a5dfdd34). |
| 11 | REQUIREMENTS RELEASE-02/05 rows read `Phase 202, Phase 205 \| Complete`; checkboxes stay `[x]`; no other row changes | ✓ VERIFIED | Lines 182 and 185. `[x]` at 69 and 72. The diff touches only those 2 rows plus one footer line. |
| 12 | 202 review disposition recorded append-only; 202-REVIEW.md and the audit are unchanged | ✓ VERIFIED | The deferred-items.md section lists 5 resolved (CR-01, WR-01/02/03/05), 3 open (WR-04/06/07) and IN-01..07 as open (info). numstat is 37 added, 0 removed. 202-REVIEW.md and v1.41-MILESTONE-AUDIT.md have no diff vs ca99ff7c. |
| 13 | STATE/ROADMAP show 205 complete at 2/2; progress block 8/8/148/148/100 | ✓ VERIFIED | STATE.md:7 `status: completed`, :14-18 `8/8/148/148/100`. ROADMAP:75 `[x]`, :894/:898 `[x]`, :935 `2/2 \| Complete \| 2026-09-24`. |
| 14 | Bookkeeping commits stage only named files; WINDOWS.md and config.json keep their pre-phase hashes | ✓ VERIFIED (with advisory) | No 205 commit touches WINDOWS.md, config.json or .tool-versions (checked `git show --name-only` for all 9 first-parent commits). WINDOWS.md and .tool-versions match the recorded SHA-256. config.json's working copy changed later (`_auto_chain_active` → false at 09:18:40, after 205-02 finished). The source is the execute-phase workflow, not a phase commit (see advisory). |

**Score:** 14/14 truths verified (0 present, behavior-unverified)

### Goal clause: "203/204's changes preserved through the merge"

This goes beyond the plan truths. For every file the branch changed since the merge-base `5808f140`, either HEAD equals PRE (all auto-merged and Group A paths), or the file is one of the 7 Group B or combined files. For those 7, the branch-side "change" is the #43 content that origin itself later evolved: ours equals `23f0505a`. The only lines that exist in PRE and not in HEAD are:

- `changelog_contract_test.exs`: the old "generated changelog carries no release entry" test. #44 deliberately replaced it.
- `CHANGELOG-GENERATED.md`: the old heading.

Both are origin's intended corrections, not 203/204 work. The 203/204 gates (credo, format, the full suite with its render/byte-lock and doc contracts) pass at HEAD.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mix/tasks/threadline.install.ex` | #46 plus the 204-07 flatten | ✓ VERIFIED | blob 16a90922. The diff vs origin is only `repo_migrations_path/1`. |
| `bin/verify-bump-rehearsal` | #44 stand-ins plus 204-02 derived gate | ✓ VERIFIED | blob 52214671. It runs 0.10.1 → 0.11.0 green. |
| `mix.exs` | PRE plus `@version "0.10.1"` | ✓ VERIFIED | blob 6404f91a. The 1-line diff vs PRE. |
| `.github/workflows/release.yml` | origin's sync job | ✓ VERIFIED | Byte-identical to origin/main. |
| `test/threadline/release_control_plane_contract_test.exs` | sync-pins contract | ✓ VERIFIED | Runs in the default suite (not excluded). |
| `test/mix/tasks/threadline/install_test.exs` | #46 tests plus credo alias | ✓ VERIFIED | Passes; credo clean. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| mix.exs `@version` | bump rehearsal | CURRENT/NEXT derivation | ✓ WIRED | The rehearsal printed `0.10.1 -> 0.11.0` (closes audit F2). |
| release-please job | sync-release-pr-pins | bootstrap-release-pr-ci | ✓ WIRED | `needs:` chain and `always()` are present in release.yml. |
| `Install.run/1` | `recommend_dedicated_storage_schema/1` | post-generation written list | ✓ WIRED | 3 occurrences, called after generation. install_test passes. |
| contract test | `verify.test` / `ci.all` | default `mix test` | ✓ WIRED | Seen in the full-suite run (1787/0). |

### Data-Flow Trace (Level 4)

N/A. This phase is a VCS merge plus release/CI configuration and renders no dynamic data.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Pins agree with @version | `MIX_ENV=dev mix release.pins --check` | 0 of 20 differ | ✓ PASS |
| Next minor release commit would be green | `DB_PORT=5433 mix verify.bump_rehearsal` | `Bump rehearsal OK` 0.10.1 -> 0.11.0 | ✓ PASS |
| Release shape in a clean clone | `mix verify.release` in a fresh `--no-local` clone | rc=0, 38/0, builds 0.10.1 | ✓ PASS |
| Release/changelog/version/public-surface contracts | focused `mix test` on 13 files | 121/0 and 42/0 | ✓ PASS |
| Full suite | `DB_PORT=5433 mix test` (once) | 1787 tests, 0 failures, 1 excluded | ✓ PASS |
| Lint and compile | format, `verify.credo`, `compile --warnings-as-errors` | all rc=0 | ✓ PASS |

### Probe Execution

Step 7c is not applicable. The phase declares no `probe-*.sh`, and gates were run directly as above.

### Prohibitions (judgment-tier, resolved by evidence)

| Prohibition | Disposition | Evidence |
|-------------|-------------|----------|
| One `--no-ff` merge; no rebase, cherry-pick, `-X` or reset | verified | 1 first-parent merge. PRE and the origin SHAs are unchanged. Conflicted files are exactly ours, theirs or the planned blob (no per-hunk `-X` mix). |
| Whole-file conflict resolution | verified | Blob classification against #43 (truth 2). |
| Explicit-path staging only | verified | Every 205 commit's file list equals the planned set. There is no `.planning/` in 205-01's code commits. |
| Protected paths untouched | verified for commits; config.json working copy flagged | See advisory. |
| No `--no-verify` / `core.hooksPath` override | verified (moot) | `.git/hooks` has only `*.sample`. `core.hooksPath` is the default hooks dir. |
| Nothing pushed, tagged or published | verified | The local origin/main ref is still 471ebf6e. Tags 56 = recorded 56. |
| No repin of byte-locks or baselines | verified | No diff under lib/threadline, test/fixtures, examples or priv. |
| `verify.release` only in a fresh clone | verified | The real tree's tracked files are clean outside .planning. |
| Audit and 202-REVIEW not edited | verified | No diff vs ca99ff7c. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| RELEASE-02 | 205-01, 205-02 | Every version-bearing line is managed by release automation | ✓ SATISFIED (on the branch) | @version and manifest are 0.10.1. `release.pins --check` is clean. The sync job is present and pinned. The rehearsal is green. |
| RELEASE-05 | 205-01, 205-02 | Release-shape and distribution-sync checks pass | ✓ SATISFIED (on the branch) | Clean-clone `verify.release` rc=0. The release_artifact/control-plane contracts pass. |

Orphans: REQUIREMENTS.md maps only RELEASE-02 and RELEASE-05 to Phase 205, and both are claimed by both plans. Audit F1 also listed RELEASE-01/03. Those are satisfied by the published 0.10.0 and are not claimed by 205, which is consistent with the roadmap's scope.

### Anti-Patterns Found

No TBD, FIXME or XXX markers were introduced by 205's commits. The review findings are carried as advisory (frontmatter). None is introduced by the merge's resolution choices, and none breaks the release flow or makes the next release PR red.

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| lib/mix/tasks/threadline.install.ex | 65, 155 | per-file `timestamp()` → duplicate migration versions | ⚠️ Warning (pre-existing since v0.9.0; out of scope) | A fresh install's `ecto.migrate` can fail. This is adopter-facing, so track a fix before v1.41 close. |
| test/threadline/release_control_plane_contract_test.exs | 122-159 | assertions weaker than their messages | ℹ️ Info | Regression-guard strength only. |
| bin/verify-bump-rehearsal | ~380 | negative-control drift at patch versions | ℹ️ Info | Affects the control only. |

### Human Verification Required

None required for the phase goal. The orchestrator should confirm it made the `.planning/config.json` `_auto_chain_active` write (advisory).

### Gaps Summary

None. The goal holds on the branch:
- v0.10.0 and v0.10.1 are ancestors of HEAD, and HEAD is 0 behind origin/main.
- The merge is lossless for both sides (proven by blob classification against #43).
- The release flow's sync-pins stage is present, wired and pinned.
- The next-minor rehearsal and clean-clone `verify.release` are green at HEAD, and the full suite is 1787/0.

The most important non-blocking finding is 205-REVIEW CR-01, the duplicate installer migration timestamps. It predates this phase (v0.9.0) and is unchanged by it, but it is a real adopter-facing bug that should get its own tracked fix.

---

_Verified: 2026-09-24T13:55:00Z_
_Verifier: Claude (gsd-verifier)_
