# Phase 205: Release Reconciliation - Research

**Researched:** 2026-09-24
**Domain:** Git merge reconciliation (release branch into milestone branch), Elixir/Mix release gates
**Confidence:** HIGH. The whole resolution was built and gated in a throwaway tree before this document was written; see "Pre-validation".

## Summary

The 8 commits that exist only on origin are much smaller than the 17 conflicts suggest. **PR #43 (`23f0505a`) is a squash of this branch's own Phase 201/202 commits.** Every file #43 touched has a byte-identical blob somewhere in `5808f140..HEAD` [VERIFIED: blob-hash comparison of all 60+ files in `git show --name-only 23f0505a` against `git log 5808f140..HEAD -- <file>`]. Git's merge base is `5808f140`, which is older than that squash. So git sees both sides adding the same 201/202 work in slightly different shapes, and it reports conflicts in files where no real disagreement exists.

The genuinely new content on origin is:
- #44 `8c6b8c6b`: the sync-pins job, the changelog-contract fix and the rehearsal stand-ins.
- The 0.10.0 release commit `3d148435` and its doc sync #45 `53b5d71a`.
- #46 `45532778`: the installer CR-01 fix, the config-guide default, release.yml hardening, and the 0.10.1 CHANGELOG entry.
- The 0.10.1 release commit `270ac2aa` and its doc sync #48 `471ebf6e`.

#41 `86852f98` is already byte-identical on HEAD.

Redo the three-way merge per file with the #43 state (`23f0505a:<path>`) as the base instead of `5808f140`. Then 33 of the 37 files that both sides changed resolve mechanically, as either all-ours, all-theirs or a clean combination. Only **3 hunks** need a human: 1 in `lib/mix/tasks/threadline.install.ex` and 2 in `bin/verify-bump-rehearsal`. That resolved tree was built in `/tmp/p205/tree` and passed every gate I ran:
- format, credo `--strict`, `compile --warnings-as-errors`, `verify.xref_cycles`, `verify.compile_no_optional`, `verify.threadline` and Dialyzer.
- Full `mix test`: 1786 tests, 0 failures, 1 excluded.
- `release.pins --check`.
- `bin/verify-bump-rehearsal`: **0.10.1 -> 0.11.0 OK**.

That run needed **one post-merge fix**. Origin's new `test/mix/tasks/threadline/install_test.exs` fails this branch's full-default `credo --strict`: it needs an `alias Mix.Tasks.Threadline.Install`.

**Primary recommendation:** Make one real merge (`git merge --no-ff --no-commit origin/main`, no rebase). Resolve every conflicted file with the whole-file rule table below; never hand-edit only the marker hunks. Commit the merge with only the 17 conflicted paths explicitly staged. Then add one follow-up `fix` commit for the credo alias, and optionally a `docs` commit to make the rehearsal wording true. Run the full gate after that, then do the bookkeeping. Push nothing, tag nothing, publish nothing.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Merge reconciliation | VCS (git history on the milestone branch) | — | A single merge commit; no library runtime change beyond the installer. |
| Version metadata (0.10.1) | Release automation (`mix.exs` @version, `.release-please-manifest.json`, `x-release-please-version` lines) | `mix release.pins` (install pins) | Owned by release-please and the pin writer, never hand-edited (RELEASE-02). |
| Release PR pin sync | CI (`.github/workflows/release.yml` `sync-release-pr-pins`) | `bin/verify-bump-rehearsal` (PR-time simulation) | The job writes the pins; the rehearsal proves on every PR that the next bump is green. |
| Installer storage-schema advice (CR-01) | Mix task (`lib/mix/tasks/threadline.install.ex`) | — | Host-side generator; capture-layer boundary unchanged. |
| Distribution docs truth | Guides + doc-contract tests | `release.yml` post-publish sync PR | Release commit plus #45/#48 syncs. |

## Architecture Patterns

### Flow: how the merge must be done

```
origin/main (471ebf6e, v0.10.1) ─┐
                                 ├─ git merge --no-ff --no-commit origin/main   (ort, base 5808f140)
HEAD (90b58794, milestone) ──────┘            │
                                              ▼
                           17 conflicted paths + auto-merged paths
                                              │
            ┌─────────────── whole-file resolution per rule table ───────────────┐
            │ OURS (10)          │ THEIRS (4)           │ COMBINE (3, #43 base)    │
            │ git checkout       │ git checkout         │ git merge-file with      │
            │   --ours           │   --theirs           │ 23f0505a:<path> as base, │
            │                    │                      │ then 3 hand hunks        │
            └─────────────────────────────────────────────────────────────────────┘
                                              │
                   git add <17 explicit paths>  (NEVER -A / . / .planning/)
                                              │
                   git commit  -> merge commit M (parents: 90b58794, 471ebf6e)
                                              │
                   follow-up commit F1: credo alias in install_test.exs
                   (optional) F2: rehearsal/CI/CONTRIBUTING wording truth
                                              │
                   gates: format, credo, compile, xref, test, dialyzer,
                          release.pins --check, verify.bump_rehearsal (0.10.1->0.11.0),
                          verify.release in a clean clone
                                              │
                   bookkeeping (.planning docs, explicit paths only)
```

### Per-file resolution rules (conflicted files: 17)

All 17 were derived by the method the task specified: compare `origin/main:<f>`, `HEAD:<f>` and each side's history, then re-merge with `git merge-file` using `23f0505a:<f>` as the base.

**Group A: take OURS (`git checkout --ours -- <f>`), 10 files.** Origin's final blob for each file is byte-identical to a blob in HEAD's history. So origin has nothing HEAD lacks, and HEAD evolved further in 201/203/204. [VERIFIED: blob-hash match]

| File | Origin's blob equals HEAD's blob at | HEAD commits after that point (intent that must survive) |
|------|-------------------------------------|----------------------------------------------------------|
| `.github/workflows/ci.yml` | `10c1c6ee` (202-10) | 71f414d5 (203-02 xref step), 2483ffdf (204-02 removed the doc-contract step and alias), 2f906d27 (204-02 derived rehearsal list). Keeps the 14-job `ci-required`. |
| `CONTRIBUTING.md` | `10c1c6ee` | 39ca9f3d (203-02 xref docs), 7a563e93 (204-02 truth pass) |
| `lib/threadline/operator_surface/live/timeline_live.ex` | `3d7a0c63` (201-04) | 7c81654f (203-01 FilterParams rename), the 203-03/06/08 credo work, the 204-05/06/08 splits |
| `test/threadline/adoption_pilot_doc_contract_test.exs` | `67081fc3` (202-10) | 4c920206, 7a563e93 |
| `test/threadline/community_health_render_contract_test.exs` | `1d4fca34` | 0232df37 |
| `test/threadline/getting_started_saas_doc_contract_test.exs` | `67081fc3` | 5f7ab174 |
| `test/threadline/operator_surface/rendered_output_contract_test.exs` | `3a4fb330` (201-05) | 64a82c81, 29612279, efbac2cd, fe3dfc5e, 47e43e32, 634936f0 (the 201 byte-lock and render contracts plus 204 templates) |
| `test/threadline/operator_surface_doc_contract_test.exs` | `67081fc3` | 363e0c7f |
| `test/threadline/readme_doc_contract_test.exs` | `67081fc3` | 0111d1a3 |
| `test/threadline/release_artifact_contract_test.exs` | `07f46ed9` (202-09) | 94cb0cbd, e09a4ecc, e1fcabc9, the 204-03/04/08/09/10/12/15/16 commits |

**Group B: take THEIRS (`git checkout --theirs -- <f>`), 4 files.** HEAD's blob is byte-identical to the #43 (`23f0505a`) blob, and HEAD never changed these files after 202. Origin's later commits are the only delta. [VERIFIED: blob-hash match]

| File | Origin delta being taken |
|------|--------------------------|
| `CHANGELOG-GENERATED.md` (add/add) | Release-please's dated 0.10.0 and 0.10.1 entries (`3d148435`, `270ac2aa`) |
| `CHANGELOG.md` | The human-written `## [0.10.1] - 2026-09-22` entry (#46) |
| `test/threadline/changelog_contract_test.exs` (add/add) | #44: the "holds no pre-0.10.0 entry" invariant replaces the refute of any dated entry |
| `test/threadline/storage_schema_test.exs` | #46: a test tying `guides/configuration-and-commands.md`'s default to `StorageSchema.get([])` |

**Group C: combine, 3 files.** Use `git merge-file -p <HEAD blob> <23f0505a blob> <origin blob>`.

| File | Result with the #43 base | Resolution |
|------|--------------------------|------------|
| `mix.exs` | **Clean.** Equals `HEAD:mix.exs` with `@version "0.9.0"` changed to `"0.10.1"`. | Take HEAD's file and set the version to 0.10.1. This **drops** origin's resurrected `"verify.doc_contract"` alias block. It **keeps** HEAD's `~r{^lib/threadline/operator_surface/live/stress_live(\.ex$|/)}` and `mechanical_checker(\.ex$|/)` package excludes (204-09 and 204-04; origin still has the `\.ex$`-only forms). It also keeps `verify.xref_cycles`, the ci.all composition and `critic_trust/`. [VERIFIED: `diff HEAD:mix.exs merged` = the one @version line] |
| `lib/mix/tasks/threadline.install.ex` | 1 conflict hunk | **Take origin's (#46) file and re-apply HEAD's 204-07 flatten (`d00dd4f6`).** Replace the inline `priv = case repo.config()[:priv] ...; Path.join(priv, "migrations")` in `migrations_path/0` with `repo_migrations_path(repo)`. Add `defp repo_migrations_path/1` (HEAD's body, verbatim, with its `# Called inside migrations_path/0, so its rescue still covers a raising repo.` comment) directly above `defp existing_migration?(path, suffix)`. Keep #46's `generate/4`, `existing_migration?/2` and `recommend_dedicated_storage_schema/1`. Drop `existing_capture_migration?/1`, `existing_semantics_migration?/1` and `existing_governance_migration?/1`. Reference blob: `16a90922e809cc4b5c2638436d29ff10c1071668`. |
| `bin/verify-bump-rehearsal` | 2 conflict hunks, plus 1 stale comment that merges cleanly | Keep all of #44's additions: the two-stand-ins header, the richer CHANGELOG stand-in (`### Breaking changes` / `### Added`), the upgrade-path stand-in and the release-please CHANGELOG-GENERATED simulation. Keep HEAD's `derived_doc_contract_tests` (204-02). The gate chain becomes `run_gate "doc-contract tests (derived by filename) at $NEXT" derived_doc_contract_tests && run_gate "changelog contract at $NEXT" mix test test/threadline/changelog_contract_test.exs && run_gate "mix verify.release at $NEXT" mix verify.release \|\| true`. Rewrite the final OK message to name all three gates. **Also rewrite header line ~66**: "The real assertion is untouched: `mix verify.doc_contract` still enforces it..." names the retired alias. Change it to e.g. "`mix test` (verify.test) still enforces it". Reference blob: `506baf66147a76e554cb98631b3b3e6a7e93297c`. The wording is at the executor's discretion; the gate chain is not. |

**Why the rehearsal needs the combination and cannot take one side:**
- Taking origin brings back `mix verify.doc_contract`. That alias no longer exists on HEAD (204-02), so the rehearsal dies with "task could not be found" and exits red.
- Taking HEAD drops #44's upgrade-path stand-in. At 0.10.1 -> 0.11.0, Family C of `version_truth_doc_contract_test.exs` needs `0.10.x -> 0.11.x` coverage that no human has written yet, so the rehearsal fails. It also drops the CHANGELOG-GENERATED simulation, which is exactly the born-red cause #44 fixed. [VERIFIED: #44 commit message and diff; candidate rehearsal log below]

### Auto-merged files (no markers): all semantically correct

Git's auto-merge result for **every** non-conflicted file is byte-identical to the #43-base re-merge [VERIFIED: blob compare, ort tree `7c4094e1` vs `git merge-file` output]:
- `release.yml`: origin's sync-pins job plus #46 hardening, combined with HEAD's post-publish PR body, which no longer cites the retired alias.
- `guides/adoption-pilot-backlog.md`, `guides/evaluating-threadline.md`: now 0.10.1 and `~> 0.10.0`.
- `guides/configuration-and-commands.md`: `"public"` default.
- `guides/getting-started-saas.md`.
- The seven `operator_surface/live/*.ex` files other than `timeline_live.ex`: their origin changes are 201's, and HEAD already has them.
- The 201/203 test files.
- The origin-only files: `README.md`, `guides/adoption-evidence-playbook.md`, `guides/operator-surface.md`, `.release-please-manifest.json` (`".": "0.10.1"`) and the new `test/mix/tasks/threadline/install_test.exs`.

No auto-merged file needs a manual touch.

**Semantically risky, but the rule table handles it.** If the executor resolves only the marker hunks in `install.ex`, the file ends up duplicated **outside** the markers. Git's result keeps HEAD's pre-generation `recommend_dedicated_storage_schema()` call at the top of `run/1` and HEAD's old `recommend_dedicated_storage_schema/0` function. It keeps them *alongside* #46's new `/1` function and its post-generation call [VERIFIED: `git show 7c4094e1:lib/mix/tasks/threadline.install.ex` lines 26 and 116-137]. That compiles, because the two arities are distinct, but it prints the old CR-01 advice again. This is the reason for the rule "replace whole files; never hand-edit only marker hunks".

### Net effect vs HEAD (what the merge actually changes)

Exactly 17 tracked files differ from HEAD after the merge, and 18 once the follow-up credo fix touches `install_test.exs`:
- `.github/workflows/release.yml`, `.release-please-manifest.json`
- `CHANGELOG-GENERATED.md`, `CHANGELOG.md`, `README.md`
- `bin/verify-bump-rehearsal`
- 6 guides (`adoption-evidence-playbook`, `adoption-pilot-backlog`, `configuration-and-commands`, `evaluating-threadline`, `getting-started-saas`, `operator-surface`)
- `lib/mix/tasks/threadline.install.ex`, `mix.exs`
- `test/mix/tasks/threadline/install_test.exs` (new), `test/threadline/changelog_contract_test.exs`, `test/threadline/storage_schema_test.exs`

[VERIFIED: `diff -rq` of the candidate tree against the working tree]

**No `lib/threadline/**` runtime file changes.** No `.planning/` file changes either; origin's only `.planning` file, SEED-006, is already byte-identical on HEAD.

### Anti-Patterns to Avoid
- **Rebasing or cherry-picking origin commits:** this breaks the "tag v0.10.1 is an ancestor" goal and the no-history-rewrite invariant. `--ours`/`--theirs` also swap meaning under rebase.
- **`git merge -X ours` / `-X theirs`:** these apply per hunk, not per file. They would silently mix sides in `install.ex`, `bin/verify-bump-rehearsal` and `mix.exs`.
- **`git add -A` / `git add .` / `git commit -a`:** this would stage the modified `.planning/WINDOWS.md` and `.planning/config.json`, plus untracked `.tool-versions` and critic files. Stage only the 17 conflicted paths; the auto-merged paths are already staged by `git merge`.
- **Evil-merge content:** keep the credo alias fix out of the merge commit. Make it a separate `fix` commit so `git log -p` shows the adaptation.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Re-deriving install pins after the version bump | Hand-editing `~> 0.10.0` into README/guides | Origin's already-synced files plus `mix release.pins --check` | RELEASE-02: pins are written only by `mix release.pins`; the check reports 0 differing sites on the candidate. |
| Choosing a better merge base | Manual line-by-line diffing | `git merge-file -p ours base theirs` with `base = git show 23f0505a:<path>` | Deterministic, and it reproduces the rule table. |
| Proving the resolution | Eyeballing | Compare blob hashes with `git rev-parse :<path>` (index) or `HEAD:<path>` against the table below | Byte-exact. |

### Reference blob hashes (candidate tree, merge state before the credo fix)

| Path | Expected blob |
|------|---------------|
| `.github/workflows/release.yml` | `064e7ee98a2f062e1041d6cb8c40b75a2b8374bd` |
| `.release-please-manifest.json` | `30b6d45ad63f1643640935f530bb71e316f5bafb` (= origin) |
| `CHANGELOG-GENERATED.md` | `b47569b5e64c68a932ac0a2d607d797b49c767a0` (= origin) |
| `CHANGELOG.md` | `f9948a72a05ebf64de106081a4e2f76c89ddaceb` (= origin) |
| `README.md` | `4fa8e04b7ca3afd73122343b45f77149ca991e1b` (= origin) |
| `guides/adoption-evidence-playbook.md` | `9b18d657014b9ad47b7fee98048886a557a6ddb3` |
| `guides/adoption-pilot-backlog.md` | `92bc7bdb8b8b8a89b9fa273de3d6acf17fb2b287` |
| `guides/configuration-and-commands.md` | `7af74a6d6a1b653554efd839be5c399de4de99d2` |
| `guides/evaluating-threadline.md` | `85413127a2159e6d928e83382a6cb367ede13a88` |
| `guides/getting-started-saas.md` | `ee679bd725499b2b0c84cc8f15a209e927b4dc26` (= origin) |
| `guides/operator-surface.md` | `9c1ceb1f3f6393d411045c3d9dbe39ee041a0bc5` |
| `mix.exs` | `6404f91ae5e0e999ac713db839cea32f708835f0` |
| `test/threadline/changelog_contract_test.exs` | `4a4ca794556148699b7d6d16b05a3c63d5a30edb` (= origin) |
| `test/threadline/storage_schema_test.exs` | `de6da3e057c31990874d8c905d0970631373aab9` (= origin) |
| `test/mix/tasks/threadline/install_test.exs` | merge commit: `2c7ca7061cd90e43c84cbc664205cb094c86c877` (= origin); after the credo fix: `e105efeb57fa516e62e92d3608e58d83043e1a03` |
| `lib/mix/tasks/threadline.install.ex` | `16a90922e809cc4b5c2638436d29ff10c1071668` (reference; placement-dependent) |
| `bin/verify-bump-rehearsal` | `506baf66147a76e554cb98631b3b3e6a7e93297c` (reference; comment wording may differ) |
| Group A files | must equal `HEAD:<path>` of `90b58794` |

## Code Examples

### Scripted resolution (executor runs in the MAIN working tree, not a worktree)

```bash
# Preconditions (abort if false)
test "$(git rev-parse HEAD)" = 90b58794b0a89f3d6f90075ac073cb6c044f61d0
test "$(git rev-parse origin/main)" = 471ebf6e67365e2ad16a1b8dbac991e5da1ec3b4   # re-check; if origin moved, STOP and re-research
git merge --no-ff --no-commit origin/main   # exits 1 with 17 conflicts; that is expected

# Group A: ours
git checkout --ours -- .github/workflows/ci.yml CONTRIBUTING.md \
  lib/threadline/operator_surface/live/timeline_live.ex \
  test/threadline/adoption_pilot_doc_contract_test.exs \
  test/threadline/community_health_render_contract_test.exs \
  test/threadline/getting_started_saas_doc_contract_test.exs \
  test/threadline/operator_surface/rendered_output_contract_test.exs \
  test/threadline/operator_surface_doc_contract_test.exs \
  test/threadline/readme_doc_contract_test.exs \
  test/threadline/release_artifact_contract_test.exs
# Group B: theirs
git checkout --theirs -- CHANGELOG-GENERATED.md CHANGELOG.md \
  test/threadline/changelog_contract_test.exs test/threadline/storage_schema_test.exs
# Group C: mix.exs = HEAD + version
git show HEAD:mix.exs | sed 's/^  @version "0.9.0"$/  @version "0.10.1"/' > mix.exs
# Group C: re-merge with the #43 base, then hand-resolve the remaining hunks
for f in bin/verify-bump-rehearsal lib/mix/tasks/threadline.install.ex; do
  git show HEAD:$f > /tmp/ours; git show 23f0505a:$f > /tmp/base; git show origin/main:$f > /tmp/theirs
  git merge-file -p /tmp/ours /tmp/base /tmp/theirs > $f || true   # leaves 2 + 1 hunks
done
chmod +x bin/verify-bump-rehearsal
# ...hand-resolve per the rule table, then:
! grep -rn '^<<<<<<<\|^>>>>>>>' -- bin/verify-bump-rehearsal lib/mix/tasks/threadline.install.ex mix.exs
bash -n bin/verify-bump-rehearsal
git add -- <exactly the 17 conflicted paths>
git status --porcelain | grep -v '^M  \|^A  ' # only .planning/WINDOWS.md, .planning/config.json, ?? .tool-versions, ?? .planning/phases/205-… may remain unstaged
git commit -F <msgfile>     # plain git commit; do not use gsd commit tooling for a merge
```

Recommended merge message subject: `chore(205): merge origin/main (v0.10.1) into the milestone branch`. `chore` is non-releasable [CITED: release-please-config.json `changelog-sections` hides chore]. The body lists the rule groups and ends with the Co-Authored-By trailer.

### Follow-up fix commit (required: credo `--strict` is red without it)

```elixir
# test/mix/tasks/threadline/install_test.exs
  use ExUnit.Case, async: false

  alias Mix.Tasks.Threadline.Install
...
    File.cd!(tmp, fn -> Install.run([]) end)
```
Credo finding, verbatim: `[D] ↘ Nested modules could be aliased at the top of the invoking module. test/mix/tasks/threadline/install_test.exs:37:25` (rc=2) [VERIFIED: `mix credo --strict` on the candidate]. After the fix: `found no issues`.

### Optional truth commit (planner's discretion)
The ci.yml `verify-bump-rehearsal` job comment (around HEAD ci.yml:862-874) and CONTRIBUTING.md:510 describe the rehearsal as "doc-contract tests ... + `mix verify.release`". After the merge the rehearsal also runs the changelog contract. Adding it keeps 204-02's "every statement true" standard. Parity contracts passed on the candidate without this change, so re-run `ci_workflow_parity_contract_test.exs` and `ci_topology_contract_test.exs` if it is made.

## Common Pitfalls

### Pitfall 1: Marker-only resolution of `install.ex` brings back CR-01
**What goes wrong:** An old pre-generation advice call and function survive outside the conflict markers.
**How to avoid:** Resolve the whole file per Group C. Verify with `grep -c 'recommend_dedicated_storage_schema' lib/mix/tasks/threadline.install.ex`, which should give 3: one call and two clauses of the `/1` function. There must be no `recommend_dedicated_storage_schema()` with zero arguments.

### Pitfall 2: The retired alias comes back
**What goes wrong:** Taking origin's `mix.exs` or rehearsal hunks re-adds `"verify.doc_contract"`.
**Detection:** `ci_all_dedup_contract_test.exs` rejects the alias in `mix.exs`, `ci_topology_contract_test.exs` rejects it in `ci.yml`, and `public_surface_contract_test.exs` checks the retired-alias register. **No test scans `bin/`**, so check it manually: `git grep -n 'verify\.doc_contract' -- ':!.planning' ':!CHANGELOG.md'` must return nothing. The two historical CHANGELOG mentions at old-entry lines are allowed.

### Pitfall 3: The bump rehearsal validates the committed HEAD, not the index
`bin/verify-bump-rehearsal` runs `git clone --no-local "$ROOT"` and then checks out `$(git rev-parse HEAD)` [VERIFIED: bin/verify-bump-rehearsal lines ~205-212]. An uncommitted resolution is invisible to it, so run it only **after** the merge commit and the fix commit exist. A dirty `.planning/` tree does not affect it: it compares identity before and after.

### Pitfall 4: `mix verify.release` refuses the real working tree
`ensure_clean_tree!/0` runs `git diff --quiet HEAD --` [VERIFIED: mix.exs:396-406]. The tracked `.planning/WINDOWS.md` and `.planning/config.json` are modified and must not be touched, so `verify.release` fails in place. Run it in a fresh clean clone instead:
```bash
D=$(mktemp -d) && git clone --quiet --no-local "$PWD" "$D/t" && cp .tool-versions "$D/t/" && (cd "$D/t" && mix deps.get && DB_PORT=5433 mix verify.release)
```
Alternatively, accept the rehearsal's `verify.release at 0.11.0` together with `bin/verify-release-shape` and the release-artifact contract run at 0.10.1.

### Pitfall 5: Staging `.planning/`
Memory rule: never `git add .planning/`. Origin changes nothing under `.planning/` that HEAD lacks, so the merge commit needs no `.planning` path. Bookkeeping commits must name explicit files.

### Pitfall 6: Worktree isolation
A worktree has no `deps/`, `_build` or `.dialyzer`, so the Elixir suite cannot run there. The merge must also land on this branch's HEAD in the main tree. Dispatch the executor with isolation `none`, and re-record the `.gsd/dispatch-isolation-sentinel.json` sentinel as `none` (memory rule).

### Pitfall 7: Executors route around preconditions
The dispatch prompt must explicitly forbid:
- rebase, reset, force operations, push, tagging and `hex.publish`;
- `git add -A`, `git add .` and `git commit -a`;
- editing `.planning/WINDOWS.md`, `.planning/config.json` and `.tool-versions`.
If the preconditions fail (HEAD or origin/main SHA differs, or the conflict count is not 17), the executor must halt.

### Pitfall 8: Dialyzer shows red from a PLT cache miss
If `verify.dialyzer` fails for a PLT reason, rebuild with `MIX_ENV=dev mix dialyzer --plt` (memory rule). On the candidate it passed with `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`, reusing `.dialyzer/*deps-dev.plt`.

### Pitfall 9: origin/main moves again
The maintainer shipped 0.10.1 after the audit. Re-check `git rev-parse origin/main` against `471ebf6e` at execution time; the executor may not fetch. If it has moved, the rule table must be re-derived: the "is origin's blob in HEAD history" test and the #43-base re-merge.

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | None. No database or datastore keys change; the merge is source-only. | none |
| Live service config | `origin/release-please--branches--main` exists (head `2f5248b9`, the 0.10.0 release-PR pin-sync commit). Release PR behavior lives on GitHub. | **None.** This phase must not push. The branch is untouched and only matters when this milestone reaches main. |
| OS-registered state | None. | none |
| Secrets/env vars | `RELEASE_PLEASE_TOKEN` and `GITHUB_TOKEN` are referenced by the merged `release.yml` sync job. Names are unchanged; #46 only scopes their use. | none (code only) |
| Build artifacts | `_build/{dev,test}` recompile install.ex and mix.exs automatically. `.dialyzer` PLT is reused. `_build/critic-trust-path-tests` scratch dirs are unaffected. The Hex tarball is only built inside the clones. | none; normal recompile |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| git (merge-tree --write-tree, merge-file) | Resolution | ✓ | 2.41.0 | — |
| Elixir / Erlang (asdf `.tool-versions`) | All gates | ✓ | elixir 1.17.3-otp-27 / erlang 27.3.4.15 | — |
| PostgreSQL test DB | `mix test`, rehearsal | ✓ | localhost:5433 accepting | — |
| Dialyzer PLT | `verify.dialyzer` | ✓ | `.dialyzer/dialyxir_erlang-27.3.4.15_elixir-1.17.3_deps-dev.plt` | `mix dialyzer --plt` |
| jq, perl, realpath | bump rehearsal tool guard | ✓ (the rehearsal ran) | — | — |
| Node + Playwright | browser lane (optional) | not probed this session | — | carry, using the delta argument below |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.17.3) plus shell gates |
| Config file | `test/test_helper.exs` (excludes `pgbouncer_topology`) |
| Quick run command | `DB_PORT=5433 mix test test/mix/tasks/threadline/install_test.exs test/threadline/changelog_contract_test.exs test/threadline/storage_schema_test.exs test/threadline/version_truth_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/release_control_plane_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/ci_all_dedup_contract_test.exs test/threadline/public_surface_contract_test.exs` |
| Full suite command | `DB_PORT=5433 mix test` (candidate: **1786 tests, 0 failures, 1 excluded**, 139.7s) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RELEASE-02 | v0.10.1 (and so v0.10.0) is an ancestor of HEAD, with no commits missing from origin | git | `git merge-base --is-ancestor v0.10.1 HEAD && git merge-base --is-ancestor v0.10.0 HEAD && test "$(git rev-list --count HEAD..origin/main)" = 0` | n/a |
| RELEASE-02 | Every version line reads 0.10.1 / `~> 0.10.0`, managed by automation | contract + task | `MIX_ENV=dev mix release.pins --check` (candidate: "0 pin site(s) differ ... derived `~> 0.10.0`"); `version_truth_doc_contract_test.exs` | ✅ |
| RELEASE-02 | Release flow is whole: the sync-pins job exists and bootstrap waits on it | structural (**no contract test pins this job**; see Open Q1) | `grep -n 'sync-release-pr-pins:' .github/workflows/release.yml && grep -n 'needs: \[release-please, sync-release-pr-pins\]' .github/workflows/release.yml` | ❌ grep-level only |
| RELEASE-02 | The next release PR is green by construction | rehearsal | `DB_PORT=5433 mix verify.bump_rehearsal` (candidate: "rehearsing the next minor: 0.10.1 -> 0.11.0" ... "Bump rehearsal OK"; 265 + 7 + 38 tests, 0 failures) | ✅ |
| RELEASE-05 | Changelog contract accepts release-please's dated entries (>= 0.10.0) | contract | `mix test test/threadline/changelog_contract_test.exs` | ✅ |
| RELEASE-05 | Distribution docs synced to 0.10.1 (#45/#48) | doc contract | `mix test test/threadline/release_distribution_doc_contract_test.exs test/threadline/adoption_pilot_doc_contract_test.exs test/threadline/evaluating_threadline_doc_contract_test.exs` | ✅ |
| RELEASE-05 | Release shape and tarball | release | `mix verify.release` in a clean clone (Pitfall 4) | ✅ |
| (CR-01) | The installer's advice is correct | unit | `mix test test/mix/tasks/threadline/install_test.exs` | ✅ (arrives with the merge) |
| 203/204 preserved | Gates stay green | ci | `mix verify.format`, `MIX_ENV=test mix verify.credo`, `mix compile --warnings-as-errors`, `mix verify.xref_cycles`, `mix verify.compile_no_optional`, `mix verify.threadline`, `MIX_ENV=dev mix verify.dialyzer`, `mix verify.example` | ✅ |

### Sampling Rate
- **After the merge commit:** compile, format, credo (credo is expected red until the fix commit).
- **After the fix commit:** the full list above, plus `mix verify.example`. Run the bump rehearsal last among the fast gates.
- **Phase gate:** `mix ci.all` components individually. The browser lane is optional, argued from the delta below.

**Browser lane.** The merge changes no `lib/threadline/**` file, no CSS and no example-app file. The only library-side changes are the `mix threadline.install` task and the `@version` literal, and the operator surface renders no version string (`grep vsn|:version] lib/threadline/operator_surface` is empty). By the 199-precedent delta argument the Playwright lane may be **carried**. If the planner runs it anyway, use `CI=true mix verify.example_browser --project=desktop-chromium --project=mobile-chromium`, never raw Playwright. The healthy result is **326 passed / 8 failed / 16 skipped**, with exactly the 8 known screenshot failures. A 9th failure is a regression.

### Wave 0 Gaps
- None required. Optionally add a release.yml contract assertion for the sync-pins job (Open Q1).

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2/V3/V4 | no | — |
| V5 Input Validation | no new surface | — |
| V14 Configuration (CI secrets) | yes | #46's `release.yml` hardening arrives with the merge: `persist-credentials: false`, a token passed only to the push step via `PUSH_TOKEN`, `permissions: contents: write`, and a concurrency group. Preserve it as-is. |

| Pattern | STRIDE | Mitigation |
|---------|--------|------------|
| Dependency compile code reads a persisted PAT (202-REVIEW WR-01) | Information disclosure | Closed by #46 (merged as-is) |
| Accidental publish or tag push from a local branch | Tampering / repudiation | This phase never pushes, tags or publishes; tags stay local (memory rule) |

## Post-merge bookkeeping (for the final plan)

1. **202-VERIFICATION.md:** add an addendum after the frontmatter note ("shipped code was verified at origin/main 53b5d71a ... NOT the local planning branch"). It should record: merge commit SHA, `v0.10.1` ancestry proof, rehearsal 0.10.1 -> 0.11.0 OK, full-suite count. Do not rewrite the original evidence.
2. **REQUIREMENTS.md:** RELEASE-02 and RELEASE-05 are already `[x]` (lines 69, 72). Update the traceability rows (182, 185) to "Complete, on origin/main (202) and on the milestone branch (205, merge `<sha>`)", or add a 205 row.
3. **v1.41-MILESTONE-AUDIT.md:** do not edit the audit. Re-audit after 205 (`/gsd-audit-milestone`). F1 and F2 are closed by the facts above: the rehearsal now measures 0.10.1 -> 0.11.0 because `CURRENT` comes from mix.exs `@version` and `NEXT` = next minor `.0` [VERIFIED: bin/verify-bump-rehearsal:156-164].
4. **202-REVIEW.md:**
   - **Closed by #46** (commit message and diff): CR-01 (via the "at minimum" fix: advice after generation, names the files, delete-then-re-run, withheld when nothing was written, 4 tests), WR-01 (token scoping), WR-02 (concurrency group), WR-03 (`always()` bootstrap) and WR-05 (config guide default plus test).
   - **Still open:** WR-04 (stale rehearsal tarball), WR-06 (vacuous legacy-schema read-back test) and WR-07 (env-protection property).
   - Record this in 205's SUMMARY or `deferred-items.md`; the review file stays historical.
5. **STATE.md / ROADMAP.md:** mark 205 complete, and hand-check the progress block (state.* handlers miscompute it). `state.begin-phase` needs flags with gsd-core v1.14.0.
6. The GATE-01..05 SUMMARY frontmatter gap is an audit bookkeeping item outside 205's requirement IDs. Optional.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | origin/main is still `471ebf6e` at execution time (no fetch was done in this session) | Pitfall 9 | The rule table is stale; the executor must halt and re-derive it |
| A2 | Dialyzer's 1.9s pass on the candidate was a full analysis of the recompiled beams and not a stale cache | Validation | Low; the executor re-runs it in the real tree |
| A3 | The browser lane is unaffected (delta argument) | Validation | Low; there is no rendered-code delta |
| A4 | The merge commit type `chore` is the right choice so it never feeds release notes | Code Examples | Low; only matters when the branch reaches main |

## Open Questions

1. **Should 205 add a contract test pinning `sync-release-pr-pins` in release.yml?**
   - What we know: no test in `test/` references the job. If a future resolution dropped it, nothing would fail. The audit's broken flow was exactly this absence.
   - Recommendation: add a small assertion in `release_control_plane_contract_test.exs` or `ci_topology_contract_test.exs`. It should require the job, `needs: release-please`, `mix release.pins`, and bootstrap's `needs: [release-please, sync-release-pr-pins]` with `always()`. This is cheap and directly serves RELEASE-02 ("green by construction"). Planner's call; not required to close F1.
2. **Should 203/204's adopter-visible changes get an "Unreleased — highlights" CHANGELOG line?** They are the `@moduledoc false` module renames and the Hex package exclude changes. This is out of 205 scope; flag it for the milestone close or next release plan.

## Sources

### Primary (HIGH confidence)
- Local git object store: `git merge-tree --write-tree HEAD origin/main` (tree `7c4094e1…`), `git show`/`git log`/`git merge-file` on the base `5808f140`, `23f0505a`, HEAD `90b58794` and origin `471ebf6e`.
- Commit messages and diffs of `8c6b8c6b` (#44), `45532778` (#46), `3d148435`, `270ac2aa`, `53b5d71a`, `471ebf6e`.
- Candidate tree `/tmp/p205/tree` (throwaway local repo commit `5d32c7fd`). Gates run there: `mix format --check-formatted` rc=0; `mix credo --strict` (rc=2 before the fix, clean after); `MIX_ENV=test mix compile --warnings-as-errors`; `verify.xref_cycles` ("No cycles found"); `verify.compile_no_optional` rc=0; `verify.threadline` (1/1 covered); `MIX_ENV=dev mix verify.dialyzer` (0 errors); `DB_PORT=5433 mix test` (1786/0/1; 12 initial failures were all git-HEAD-dependent tests, caused by the scratch repo having no commit, and passed 12/0 after committing it); `mix release.pins --check`; `bin/verify-bump-rehearsal` (rc=0, "0.10.1 -> 0.11.0", tree identity MATCH). Log: `/tmp/p205/rehearsal.log`.
- Files read: `.planning/v1.41-MILESTONE-AUDIT.md`, `REQUIREMENTS.md`, `STATE.md`, `ROADMAP.md` §205, `202-VERIFICATION.md`, `202-REVIEW.md`, `mix.exs`, `bin/verify-bump-rehearsal`, `test/threadline/ci_all_dedup_contract_test.exs`, `public_surface_contract_test.exs`, `ci_topology_contract_test.exs`, `priv/ci/hex_evaluator/mix.exs`.

## Metadata

**Confidence breakdown:**
- Resolution rules: HIGH. Blob-exact derivation, reproduced by `git merge-file`, and the whole resolved tree gated green.
- Gate list and expected results: HIGH. Measured on the candidate.
- Pitfalls: HIGH. Each was observed (install.ex duplication, credo rc=2, `ensure_clean_tree!`, clone-of-HEAD).

**Research date:** 2026-09-24
**Valid until:** origin/main moves past `471ebf6e` or HEAD moves past `90b58794`, whichever comes first.
