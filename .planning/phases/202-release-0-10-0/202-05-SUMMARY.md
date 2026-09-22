---
phase: 202-release-0-10-0
plan: 05
subsystem: infra
tags: [release, hex, dialyzer, exdoc, doc-contract, release-please, ci]

requires:
  - phase: 202-release-0-10-0
    provides: "Plan 01's storage-schema flip, Plan 02's `mix release.pins`, Plan 03's human-owned changelog and 0.9.x -> 0.10.x upgrade row, Plan 04's publish-gate wiring, Plan 06's Dialyzer fix, Plan 07's ExDoc fix, Plan 08's critic-trust scratch-dir fix, Plan 09's derived install pin, Plan 10's bin/verify-bump-rehearsal"
provides:
  - "A measured local dress rehearsal of the 0.10.0 bump, run end to end rather than in per-plan fragments — RED on 2026-09-22 run 1, GREEN on run 2 after 202-06/07/08/09/10 landed"
  - "Three born-red causes measured at HEAD on run 1 that RELEASE-BLOCKERS.md did not list, each with the exact failing command and assertion — all three re-measured CLOSED on run 2"
  - "The proven mechanism for the CriticTrustTest intermittent that 202-01/02/03 left closed-as-unresolved — fixed by 202-08, no recurrence on run 2"
  - "A NEW finding on run 2: `verify.doc_contract` is a silent no-op inside `mix ci.all` (Mix does not re-run an already-run task), which the plan's own `<verify>` fails_when clause names as a failure"
  - "First exercise of bin/verify-release-shape against a real 0.10.0 heading, and first exercise of bin/verify-bump-rehearsal end to end"
affects: [202-05 Task 2 push checkpoint, 202-05 Task 3 publish checkpoint, any follow-up plan that fixes the ci.all doc_contract no-op]

actuals:
  tokens: 9400
  tasks: 1
  commits: 1
  plan_head_before: bf575949ffc27a88d0fc24b88a40042364300cc1

tech-stack:
  added: []
  patterns:
    - "Dress-rehearse a release in a throwaway `git clone` under mktemp (bin/verify-bump-rehearsal), not on a scratch branch in the real repo — trace-free by construction instead of by discipline"
    - "When a protected/dirty file blocks a clean-tree gate, run the gate's steps individually and disclose it, rather than moving the file out of the way"

key-files:
  created:
    - .planning/phases/202-release-0-10-0/202-05-SUMMARY.md
  modified: []

key-decisions:
  - "RUN 1 (halt): the plan held at Task 1. Both named gate entrypoints were RED at the current version. Nothing was fixed inside the publish plan."
  - "RUN 2 (re-run): every gate the plan names is GREEN. The plan is READY for its Task 2 blocking-human checkpoint, and is NOT complete — Tasks 2, 3 and 4 belong to the maintainer."
  - "The clean-tree precondition was NOT worked around on run 2. `mix verify.release` was run as an alias to record its refusal, then its four steps were run individually. The three pre-existing dirty tree items were never touched."

patterns-established:
  - "Rehearse the whole bump in one piece: per-plan fragment rehearsals each passed in isolation while the composition was red. bin/verify-bump-rehearsal (202-10) makes that composition routine."

requirements-completed: []

coverage:
  - id: D1
    description: "`mix ci.all` runs green at the current version (0.9.0)."
    requirement: "RELEASE-01"
    verification:
      - kind: other
        ref: "ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix ci.all — exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every `mix ci.all` member actually ran — the plan's fails_when treats a skipped member as a failure."
    verification:
      - kind: other
        ref: "MIX_ENV=test mix do verify.doc_contract, verify.doc_contract — one `Running ExUnit` line for two invocations"
        status: fail
    human_judgment: true
    rationale: "`verify.doc_contract` is short-circuited by Mix inside `ci.all` because `verify.test` already ran the `test` task. Its 134 tests DO execute inside verify.test's 1693, so no coverage is lost locally — but a member of the aggregate provably does not run. Whether that is a blocker or a cleanup is a maintainer call."
  - id: D3
    description: "The four steps of `mix verify.release` each pass at the current version."
    requirement: "RELEASE-01"
    verification:
      - kind: other
        ref: "bin/verify-release-shape (exit 0); release_artifact+ci_topology 37 tests 0 failures; MIX_ENV=dev mix docs --warnings-as-errors exit 0, 0 warnings; mix hex.build exit 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "The five contract test files named in the plan's `<verify>` pass at the current version."
    verification:
      - kind: unit
        ref: "mix test version_truth + release_artifact + upgrade_path + release_control_plane + changelog — 49 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D5
    description: "A simulated 0.9.0 -> 0.10.0 release commit passes mix verify.doc_contract and mix verify.release, leaving no trace."
    verification:
      - kind: other
        ref: "bash bin/verify-bump-rehearsal — 'Bump rehearsal OK', exit 0, 'tree identity: MATCH (28 files checksummed)'"
        status: pass
    human_judgment: false
  - id: D6
    description: "bin/verify-release-shape passes against a REAL (not synthesised) 0.10.0 changelog heading."
    verification:
      - kind: other
        ref: "rehearsal log: 'CHANGELOG.md already carries a heading for 0.10.0 — nothing synthesised' then 'Release shape OK for version 0.10.0'"
        status: pass
    human_judgment: false
  - id: D7
    description: "The re-run left no trace: branch, HEAD and working tree returned to their pre-task values."
    verification:
      - kind: other
        ref: "diff of git status --porcelain / git branch --show-current / git rev-parse HEAD against pre-task captures — STATUS MATCH, BRANCH MATCH, HEAD MATCH; 0 scratch branches, 0 linked worktrees, 0 tarballs"
        status: pass
    human_judgment: false
  - id: D8
    description: "The release PR will be green by construction on its first CI run."
    verification: []
    human_judgment: true
    rationale: "Every gate that can be measured locally is green, and the bump rehearsal proves the bumped state green too. But three things have never executed on GitHub Actions under a hosted token: the x-release-please-version regeneration by the real release-please updater (the rehearsal SIMULATES it), .github/workflows/environment-protection.yml, and the new verify-bump-rehearsal CI job. A local green is strong evidence, not proof."
  - id: D9
    description: "The release is ready to publish."
    verification: []
    human_judgment: true
    rationale: "Tasks 2, 3 and 4 are gate=\"blocking-human\" and are the maintainer's alone. Nothing was pushed, merged, dispatched or published. RELEASE-01 is NOT complete."

duration: 47min
completed: 2026-09-22
status: halted
---

# Phase 202 Plan 05: Publish 0.10.0 Summary

**Task 1 of 4 complete, re-run GREEN. Every gate this plan names now passes at the current version and under a simulated 0.10.0 bump. The plan is READY for its Task 2 blocking-human checkpoint and is NOT complete — Tasks 2, 3 and 4 are the maintainer's. One new finding: `verify.doc_contract` is a silent no-op inside `mix ci.all`.**

## Status

| Task | Type | Status |
|---|---|---|
| 1. Dress-rehearse the release locally against a simulated bump | auto | **Complete — run 1 RED, run 2 GREEN** |
| 2. Confirm pushing the branch and dispatching CI | checkpoint:decision, `gate="blocking-human"` | **Not started — pending human** |
| 3. Confirm the merge and the publish | checkpoint:decision, `gate="blocking-human"` | **Not started — pending human** |
| 4. Verify what actually landed | checkpoint:human-verify | **Not started — pending human** |

`status: halted` is retained deliberately. The **reason** for the halt has changed — from "three red gates" to "awaiting a blocking-human checkpoint" — but the plan is not complete and must not be read as complete. RELEASE-01 and RELEASE-05 are NOT marked complete.

Nothing was pushed, merged, dispatched or published. No GitHub API write was made. No branch was created. No repository or environment setting was changed.

---

# PART A — RUN 2 (re-run, 2026-09-22, HEAD `bf575949`)

The three red gates recorded in Part B were fixed on this branch by Plans 202-06, 202-07 and 202-09; the CriticTrustTest intermittent was fixed by 202-08; and 202-10 shipped `bin/verify-bump-rehearsal`, which automates most of Task 1's hand work. This section re-measures all of it.

## A1. `mix ci.all` at the current version (0.9.0) — **GREEN, exit 0**

`ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix ci.all` → `CI_ALL_EXIT=0`.

| ci.all member | Evidence in the log | Result |
|---|---|---|
| `verify.format` | no output, no failure | pass |
| `verify.credo` | `3168 mods/funs, found no issues.` | pass |
| `compile --warnings-as-errors` | `Compiling 1 file (.ex)` / `Generated threadline app` | pass |
| `verify.compile_no_optional` | no failure | pass |
| `verify.test` | `1693 tests, 0 failures, 1 excluded` | pass |
| `verify.threadline` | `summary: 1/1 expected tables covered (0 violated)` | pass |
| `verify.example` | `117 tests, 0 failures` | pass |
| `verify.doc_contract` | **no ExUnit output at all** | **DID NOT RUN — see A2** |
| `verify.dialyzer` (MIX_ENV=dev) | `Total errors: 0, Skipped: 0, Unnecessary Skips: 0` / `done (passed successfully)` | pass — **BR-3 closed** |
| `verify.critic_trust` | ran inside verify.test; no failure | pass |
| `verify.mechanical` | TAP `# tests 21 / # pass 21 / # fail 0` | pass |
| `verify.example_browser` (desktop+mobile chromium) | `26 skipped / 318 passed (4.3m)` | pass |

Compare run 1: `Halting VM with exit status 2` from a CriticTrustTest failure plus `Total errors: 1` in Dialyzer. Both are gone. The critic-trust lane, mechanical lane and browser lane — which run 1 never reached — all ran and all passed.

**The CriticTrustTest intermittent did not recur.** `2ef3be68 fix(202-08): make critic trust scratch dirs unique across mix test runs` replaced the colliding `"#{name}-#{System.unique_integer([:positive])}"` with a name carrying the OS pid and a monotonic timestamp (observed in this run's log as `root-overlap-8944-1790097369748522000-30410`). The mechanism proven in Part B is closed at its cause.

## A2. NEW FINDING — `verify.doc_contract` never runs inside `mix ci.all`

The plan's `<verify>` fails_when for `mix ci.all` says: *"a skipped step is also a failure here — every member must actually run."* One member does not.

`mix.exs` defines `"verify.test": ["test"]` and `"verify.doc_contract": ["test <21 files>"]`, and there is **no `Mix.Task.reenable` anywhere in mix.exs**. Mix runs a task at most once per VM invocation, so inside the single `ci.all` invocation the second `test` call is discarded.

Measured, not inferred:

```
$ MIX_ENV=test mix do verify.doc_contract, verify.doc_contract
Running ExUnit with seed: 240161, max_cases: 36     <- exactly ONE ExUnit run
Finished in 0.3 seconds (0.1s async, 0.2s sync)
134 tests, 0 failures
PROBE_EXIT=0
```

Two invocations, one run. The same shape holds for `verify.test` followed by `verify.doc_contract` in `ci.all` — and the CI log confirms it: only two ExUnit summary lines exist in the whole 753-line `ci.all` log (`1693 tests` for `verify.test`, `117 tests` for `verify.example`, which is a separate `bash -lc` shell-out and therefore unaffected).

**Severity, stated honestly.** No coverage is lost locally: `mix test` with no file arguments runs the entire `test/` tree, which contains all 21 doc-contract files, so those 134 tests DID execute inside the 1693. The defect is that a named, load-bearing member of the aggregate entrypoint is silently inert — exactly the "honest default tests" and "named entrypoints" property CLAUDE.md says this project cares about. In CI the risk is different and larger: `.github/workflows/ci.yml` runs `verify-test` and the doc contracts as **separate jobs**, so CI is unaffected; it is the *local* `ci.all` contract that is weaker than it reads. A maintainer should decide whether this is a blocker for the release or a follow-up cleanup. **It was not fixed here** — a repair inside the publish plan is an unreviewed change riding an irreversible release, the same rule applied in run 1.

Run 1 did not catch this because `ci.all` died at Dialyzer before the question could be asked.

## A3. `mix verify.release` at the current version — **GREEN (run as four individual steps)**

The alias was run first, to record its refusal verbatim rather than route around it:

```
$ mix verify.release
** (Mix) verify.release requires a clean working tree so the validated artifact matches the taggable tree
ALIAS_EXIT=1
```

`ensure_clean_tree!/0` (`mix.exs:398`) runs `git diff --quiet HEAD --`, which the two pre-existing tracked modifications (` M .planning/config.json`, ` M .planning/WINDOWS.md`) fail. **Unlike run 1, no file was moved, replaced or restored to satisfy this.** The four steps were instead run individually, exactly as `verify_release/1` lists them:

| # | Step | Result |
|---|---|---|
| 1 | `bin/verify-release-shape` | `Release shape OK for version 0.9.0`, exit 0 |
| 2 | `mix test test/threadline/release_artifact_contract_test.exs test/threadline/ci_topology_contract_test.exs` | `37 tests, 0 failures`, exit 0 |
| 3 | `MIX_ENV=dev mix docs --warnings-as-errors` | exit 0, **0 warning lines** — **BR-4 closed** |
| 4 | `mix hex.build` | exit 0, `Saved to threadline-0.9.0.tar`, checksum `6149ce8d…` |

Compare run 1, where step 3 produced 58 warning lines from 29 distinct warnings and aborted the alias. The generated tarball (gitignored, `/threadline-*.tar`) was deleted afterwards; `doc/` is gitignored (`/doc/`).

**Caveat on the alias.** What is proven is that all four *steps* pass. What is NOT proven locally is the alias itself end to end, because its first act is the clean-tree assertion and this tree carries three protected pre-existing items. In CI the tree is clean and the alias runs whole. The rehearsal in A5 **does** run the whole alias (inside its throwaway clone, where the tree is clean), so the alias is exercised end to end there — at 0.10.0.

## A4. The five contract test files — **GREEN, 49 tests, 0 failures**

```
$ mix test test/threadline/version_truth_doc_contract_test.exs \
           test/threadline/release_artifact_contract_test.exs \
           test/threadline/upgrade_path_doc_contract_test.exs \
           test/threadline/release_control_plane_contract_test.exs \
           test/threadline/changelog_contract_test.exs
49 tests, 0 failures
FIVE_EXIT=0
```

Run 1 measured `49 tests, 2 failures` here. Both are closed: Failure B (`release_artifact_contract_test.exs:345` hardcoding `~> 0.9.0`) by 202-09, and Failure A (the stale `x-release-please-version` marked line) by 202-10's extra-files simulation — though Failure A only manifested under a bump, and is addressed in A5.

## A5. `bin/verify-bump-rehearsal` — **GREEN, exit 0**

Terminal summary, verbatim:

```
Bump rehearsal OK: a 0.9.0 -> 0.10.0 release commit passes mix verify.doc_contract and
mix verify.release, and the real working tree is byte-identical.
REHEARSAL_EXIT=0
```

Tree-identity line, verbatim:

```
    tree identity: MATCH (28 files checksummed, plus status/HEAD/branch/worktree count)
    no scratch branch and no linked worktree survived
```

The pins task inside the rehearsal, reproducing run 1's hand result exactly:

```
release.pins: mix.exs @version is 0.10.0, derived install pin is `~> 0.10.0`
  README.md: `~> 0.9.0` -> `~> 0.10.0`
  guides/adoption-evidence-playbook.md: `~> 0.9.0` -> `~> 0.10.0`
  guides/adoption-pilot-backlog.md: `~> 0.9.0` -> `~> 0.10.0`
  guides/evaluating-threadline.md: `~> 0.9.0` -> `~> 0.10.0`
  guides/getting-started-saas.md: `~> 0.9.0` -> `~> 0.10.0`
  guides/operator-surface.md: `~> 0.9.0` -> `~> 0.10.0`
release.pins: scanned 20 file(s); 6 pin site(s) differ from the derived pin
release.pins: rewrote 6 file(s).
```

**Six pin sites. Resulting pin string `~> 0.10.0`.** The acceptance criterion is met. The rehearsal additionally proves idempotence (`mix release.pins --check` → `0 pin site(s) differ`), which run 1 did not check.

The simulated release commit is exactly 8 files — `mix.exs`, `.release-please-manifest.json`, the 6 pin files (two of which carry a second changed line, the `x-release-please-version` marked line):

```
 .release-please-manifest.json        | 2 +-
 README.md                            | 2 +-
 guides/adoption-evidence-playbook.md | 2 +-
 guides/adoption-pilot-backlog.md     | 4 ++--
 guides/evaluating-threadline.md      | 4 ++--
 guides/getting-started-saas.md       | 2 +-
 guides/operator-surface.md           | 2 +-
 mix.exs                              | 2 +-
 8 files changed, 10 insertions(+), 10 deletions(-)
```

**No documentation file was hand-edited.** Gate results inside the bumped clone: `mix verify.doc_contract at 0.10.0` → `134 tests, 0 failures`; `mix verify.release at 0.10.0` → `Release shape OK for version 0.10.0`, `37 tests, 0 failures`, docs generated with `--warnings-as-errors` and no warnings, `mix hex.build` → `Saved to threadline-0.10.0.tar`, checksum `64b49cb5…`.

### What the script covers, and what it does not

**Covers** (so the hand rehearsal was not duplicated — it would have been the same work):

- Deriving the next minor from `mix.exs` and applying it to `mix.exs` and `.release-please-manifest.json`.
- Simulating release-please's `extra-files` generic updater, driven off `release-please-config.json` rather than a hardcoded list (`guides/adoption-pilot-backlog.md: 1 marked line(s) -> 0.10.0`, `guides/evaluating-threadline.md: 1 marked line(s) -> 0.10.0`).
- Running `mix release.pins`, then `mix release.pins --check` for idempotence.
- Committing the bump inside the clone so `mix verify.release`'s clean-tree gate is *exercised* rather than tripped.
- Running `mix verify.doc_contract` and the whole `mix verify.release` alias at 0.10.0 — including `bin/verify-release-shape`, the release_artifact + ci_topology contracts, ExDoc `--warnings-as-errors`, and `mix hex.build`.
- Proving trace-freedom by checksumming a 28-file blast radius plus status/HEAD/branch/worktree count, and asserting zero surviving scratch branches and worktrees.
- Two standing negative controls (`INJECT_DEFECT=hardcoded-pin`, `INJECT_DEFECT=stale-marked-line`) and a forced-unrunnable control. **These were not exercised in this run** — the script was run with no controls set, as CI runs it.

**Does NOT cover:**

1. **`mix ci.all` at 0.10.0.** The rehearsal runs the release lane only — no credo, no full suite, no Dialyzer, no browser lane at the bumped version. Those were run at 0.9.0 (A1), and none of them is version-sensitive in a way the bump would move, but that is an argument, not a measurement.
2. **Two of the plan's five contract files at 0.10.0** — `release_control_plane_contract_test.exs` and `changelog_contract_test.exs` are in neither `verify.doc_contract`'s 21-file list nor `verify.release`'s 2-file list. Inspected rather than run under the bump: `release_control_plane_contract_test.exs` contains no version literal at all, and `changelog_contract_test.exs`'s only `0.10.0` occurrences are in a comment and inside one assertion's *failure message* string. Neither is bump-sensitive. Both pass at 0.9.0 (A4). **Flagged as an inspected, not measured, gap.**
3. **The real release-please run.** The extra-files rewrite is a *simulation* of the generic updater. See "Known open items" below.
4. **The negative controls**, as noted above.

## A6. `bin/verify-release-shape` against a 0.10.0 heading — REAL, not synthesised

The rehearsal reports, verbatim:

```
==> CHANGELOG.md already carries a heading for 0.10.0 — nothing synthesised
```

`CHANGELOG.md:29` reads `## [0.10.0] - 2026-09-22`, written by hand in Plan 03, and today is 2026-09-22. The 202-10 caveat (that the script would synthesise a dated stand-in heading when one is absent) was therefore **a no-op in this run**. The subsequent `Release shape OK for version 0.10.0` was produced against the real, human-written heading. Independently, `bin/verify-release-shape` at the current version prints `Release shape OK for version 0.9.0`, exit 0.

## A7. Known open items — status only, none attempted

| Item | Status |
|---|---|
| `x-release-please-version` marked lines only truly update when the real PR regenerates | **STILL OPEN.** `bin/verify-bump-rehearsal` SIMULATES the generic updater by reading `release-please-config.json` → `packages["."]["extra-files"]` and rewriting the version on any line carrying the marker. It rewrote 1 marked line in each of `guides/adoption-pilot-backlog.md` and `guides/evaluating-threadline.md`. **Simulation is not proof.** The script's own header says as much. Only a regenerated release PR closes this. |
| Post-publish smoke job | **STILL OPEN.** Observable only in a real release run. It is Task 4's check 3, which requires reading the evaluator's dependency-resolution line rather than the job's status. |
| `.github/workflows/environment-protection.yml` and the new `verify-bump-rehearsal` CI job have never run under a hosted GITHUB_TOKEN | **STILL OPEN, and measured.** This branch has **no upstream** and **102 unpushed commits** (`git log --oneline origin/main..HEAD \| wc -l` → 102; `git rev-parse --abbrev-ref @{u}` → `fatal: ambiguous argument '@{u}'`). Neither workflow has ever executed on GitHub Actions. `verify-bump-rehearsal` is wired at `.github/workflows/ci.yml:862` and is a dependency of the `ci-required` aggregate (`ci.yml:941`) — i.e. it is a **required** check that has never produced a single run. |

## A8. Tree identity — before/after proof

| | Pre-task | Post-task |
|---|---|---|
| `git branch --show-current` | `fix/branch-protection-actions-capability` | `fix/branch-protection-actions-capability` |
| `git rev-parse HEAD` | `bf575949ffc27a88d0fc24b88a40042364300cc1` | `bf575949ffc27a88d0fc24b88a40042364300cc1` |
| `git status --porcelain` | ` M .planning/WINDOWS.md`<br>` M .planning/config.json`<br>`?? .tool-versions` | ` M .planning/WINDOWS.md`<br>` M .planning/config.json`<br>`?? .tool-versions` |
| scratch/rehearsal branches | 0 | 0 |
| linked worktrees | 0 | 0 |
| `threadline-*.tar` in repo root | 0 | 0 |

`diff` against the pre-task captures reports `STATUS MATCH`, `BRANCH MATCH`, `HEAD MATCH`. The three protected tree items end the task exactly as they began — `.planning/config.json` and `.planning/WINDOWS.md` still carry their uncommitted modifications (`git diff --stat` → 24 and 2 changed lines respectively), and `.tool-versions` is still untracked. **None of the three was moved, replaced, restored, committed or otherwise touched at any point in run 2.** No scratch branch was created; no git hook was bypassed; no `--no-verify` was used.

## A9. Where the plan / brief disagreed with what was observed

Recorded per the standing instruction to treat the plan as fallible.

1. **The plan's `<action>` says "the four contract test files"; its `<verify>` lists five.** Carried from run 1, still true. All five were run.
2. **The plan's `<verify>` for `mix ci.all` demands that every member actually run — and one does not.** See A2. Strictly read, `mix ci.all` therefore does not satisfy its own fails_when clause despite exiting 0. This is reported, not resolved.
3. **The brief said the three red gates were fixed by 202-06, 202-07 and 202-09.** Confirmed — and there is a fourth fix the brief did not mention: `2ef3be68 fix(202-08): make critic trust scratch dirs unique across mix test runs` closed the CriticTrustTest intermittent that caused run 1's suite failure. Run 1's `mix ci.all` was red for *two* reasons, and the brief attributed only one (Dialyzer) to a named plan.
4. **The brief said `mix verify.release` cannot run as an alias because of the dirty `.planning/` files.** Confirmed verbatim, and the four steps were run individually as instructed.
5. **The brief listed two dirty `.planning/` files plus `.tool-versions`; run 1's SUMMARY recorded only `.planning/config.json` plus `.tool-versions`.** `.planning/WINDOWS.md` became dirty between the two runs. Both were left untouched.

## A10. Verdict

**Every gate this plan names is green.** The plan is ready for its **Task 2 blocking-human checkpoint** and is **not** complete. Task 2 requires the maintainer's explicit, first-person confirmation of the push and its scope; it cannot be inferred from this result and was not attempted.

Before that confirmation the maintainer should weigh two things this run surfaced:

- **A2** — `verify.doc_contract` is inert inside `ci.all`. Fix first, or accept and file it.
- **A7** — three things have never executed on GitHub Actions, one of them a *required* check. The first dispatched CI run will be the first time `verify-bump-rehearsal` and `environment-protection.yml` ever execute under a hosted token. "Green by construction on the first CI run" is well-supported locally but is not established for those three.

---

# PART B — RUN 1 (original, 2026-09-22, HEAD `9fe19b57`) — retained as the record of why the plan halted

_Everything below is the first execution's findings, kept verbatim. All three born-red causes it names have since been closed; the re-measurements are in Part A._

## B1. Both gate entrypoints at the current version (0.9.0)

### `mix ci.all` — **RED**

`ASDF_ERLANG_VERSION=27.3 ASDF_ELIXIR_VERSION=1.17.3-otp-27 mix ci.all` → `Halting VM with exit status 2`. Two independent failures inside one run.

**(a) Test suite: `1692 tests, 1 failure, 1 excluded`**

```
  1) test critic.measure rejects bidirectional canonical overlap without prefix confusion
     (Threadline.OperatorSurface.CriticTrustTest)
     test/threadline/operator_surface/critic_trust_test.exs:838
     ** (File.LinkError) could not create symlink from
     "/Users/jon/projects/threadline/_build/critic-trust-path-tests/root-overlap-132290" to
     ".../root-overlap-132290/output-alias": file already exists
```

**(b) Dialyzer: `Total errors: 1`**

```
lib/mix/tasks/release.pins.ex:103:unknown_function
Function Threadline.MixProject.project/0 does not exist.
```

Steps that passed before the failures: `verify.format`, `verify.credo` (3164 mods/funs, no issues), `compile --warnings-as-errors`, `verify.compile_no_optional`, `verify.example` (117 tests, 0 failures), `verify.threadline` (coverage canary 1/1), `verify.doc_contract`. The critic-trust, mechanical and browser lanes never ran — Dialyzer halted the alias first.

_Run 2 note: `verify.doc_contract` was listed as passing here, which A2 now shows to be an artifact — it never ran in either run._

### `mix verify.release` — **RED**

Exit 1.

```
Release shape OK for version 0.9.0          <- bin/verify-release-shape: PASS
36 tests, 0 failures                        <- release_artifact + ci_topology contracts: PASS
...
Documents have been generated, but generation for html, epub formats failed due to
warnings while using the --warnings-as-errors option
** (Mix) verify.release failed while running MIX_ENV=dev mix docs --warnings-as-errors (1)
```

## B2. The run-1 rehearsal (simulated 0.10.0 bump on a scratch branch)

Scratch branch `scratch/202-05-rehearsal`, created from `fix/branch-protection-actions-capability` at `9fe19b5`. `@version` and `.release-please-manifest.json` set to `0.10.0`; `mix release.pins` run; nothing else hand-edited. Committed locally as `826dff61` so the clean-tree gate could run, then the branch was deleted.

The pins task rewrote **6 pin sites** to `~> 0.10.0` — the same six reproduced in A5. `git diff --stat` listed exactly 8 files; no documentation file was hand-edited.

`CHANGELOG.md:29` already read `## [0.10.0] - 2026-09-22`, so no changelog edit was required, and `bin/verify-release-shape` was exercised at 0.10.0 for the first time: `Release shape OK for version 0.10.0`, exit 0.

**The two RELEASE-BLOCKERS causes — both CLOSED** under the bump:

```
* test every threadline install pin across README + guides equals the derived ~> 0.10.0 (5.9ms) [L#58]
* test upgrade-path.md documents the current-minor coverage 0.9.x -> 0.10.x (0.3ms) [L#143]
```

**The five contract files — `49 tests, 2 failures`:**

*Failure A — rehearsal artifact.* `guides/adoption-pilot-backlog.md has an x-release-please-version marked line that does not contain the current @version 0.10.0.` Expected: the run-1 rehearsal did not simulate release-please's `extra-files` generic updater. **202-10's `bin/verify-bump-rehearsal` now does simulate it, and A5 shows it passing.**

*Failure B — REAL, and not in RELEASE-BLOCKERS.md.*

```
2) test README carries only the release-scoped installer and routing literals
   (Threadline.ReleaseArtifactContractTest)
   test/threadline/release_artifact_contract_test.exs:342
   code: assert String.contains?(readme, "{:threadline, \"~> 0.9.0\"}")
```

## B3. Three born-red causes NOT in RELEASE-BLOCKERS.md — all since CLOSED

**BR-3 — Dialyzer: `Threadline.MixProject.project/0 does not exist`.** `lib/mix/tasks/release.pins.ex:103` called `Threadline.MixProject.project()[:version]`; `Threadline.MixProject` lives in `mix.exs`, which is never compiled into `_build/dev/lib/threadline/ebin`, so Dialyzer reported `unknown_function`. `.dialyzer_ignore.exs` was `[]`. Reproduced on both the pinned toolchain and the `.tool-versions` default — not a PLT-cache miss. **→ Closed by 202-06; re-measured `Total errors: 0` in A1.**

**BR-4 — `mix docs --warnings-as-errors`: 29 distinct warnings.** 58 warning lines (html + epub) from 29 distinct warnings, sourced from `CHANGELOG.md` (27), `CONTRIBUTING.md` (1) and `guides/upgrade-path.md` (1). Two shapes: `documentation references module "X" but it is hidden` (26 modules made `@moduledoc false` by Phase 200 and named by Plan 03's changelog entry), and `documentation references callback "c:put/2" but it is undefined` (`Threadline.Storage`). **→ Closed by 202-07; re-measured 0 warnings in A3.**

**BR-5 — `ReleaseArtifactContractTest` hardcodes `~> 0.9.0`** (`test/threadline/release_artifact_contract_test.exs:345`). **→ Closed by 202-09, which derived it from `Mix.Tasks.Release.Pins.target_pin_version()`; 202-10 then found and fixed four more copies of the same defect in other doc-contract tests. Re-measured `49 tests, 0 failures` in A4.**

## B4. The CriticTrustTest intermittent — mechanism proven in run 1, fixed since

`deferred-items.md` closed this as "NOT REPRODUCIBLE. Mechanism unproven." and explicitly rejected the leftover-scratch-tree hypothesis. That rejection was wrong:

- `critic_trust_test.exs:1142` built the scratch path as `"#{name}-#{System.unique_integer([:positive])}"`. `System.unique_integer/1` is unique **within one BEAM instance**; every `mix test` starts a fresh VM, so the counter restarts from a low value on every run.
- `_build/critic-trust-path-tests/` was never cleaned (542 directories, oldest `Sep 13 17:12`).
- The colliding directory `root-overlap-132290` had mtime **Sep 22 09:50** — an earlier run the same day — and already contained `output-alias`. The 11:33 run regenerated the same integer for the same label and `File.ln_s!` raised.
- A second directory, `interrupted-measure-132290`, showed the same integer reused for a different label in the same run — confirming the counter range, not a race.

**→ Closed by `2ef3be68 fix(202-08): make critic trust scratch dirs unique across mix test runs`.** Run 2's full suite (1693 tests) passed with no recurrence, and the scratch names now carry pid + monotonic time.

## B5. Run-1 precondition deviation (disclosed)

The task's `<precondition>` requires a clean working tree. In run 1, ` M .planning/config.json` was copied to the session scratchpad, replaced with its `HEAD` content for the duration of the gate runs, and restored byte-for-byte afterwards (md5 `f4113e1e7acba95a98ff3c43a03197c7` before and after).

**Run 2 did not repeat this**, per an explicit instruction not to move, replace or restore protected files. The alias's refusal was recorded instead and its four steps run individually (A3).

Run 1 also committed the scratch rehearsal bump with `git -c core.hooksPath=/dev/null` on the throwaway branch. **Run 2 created no branch and bypassed no hook**; `bin/verify-bump-rehearsal` commits inside a throwaway `git clone` under `mktemp -d`, which never reaches this repository.

---

## Files Created/Modified

- `.planning/phases/202-release-0-10-0/202-05-SUMMARY.md` — this file. **No source file was modified in either run.**

## Decisions Made

- **Run 1: hold at Task 1**, per the plan's own instruction ("If anything in the rehearsal is red, stop the plan here and report"). Three gates were red.
- **Run 2: Task 1 passes; hold at Task 2.** Task 2 is `gate="blocking-human"`. It is never auto-approved and was not attempted.
- **Fix nothing, in either run.** A2's `ci.all` no-op is reported, not repaired, for the same reason BR-3/4/5 were reported and not repaired: an unreviewed change riding an irreversible release.
- **Do not work around the clean-tree precondition in run 2.** Record the refusal; run the steps individually.

## Deviations from Plan

**1. [Observation] `mix ci.all` exits 0 but does not satisfy its own fails_when** — see A2. A named member (`verify.doc_contract`) is short-circuited by Mix. Measured with a two-invocation probe. Not fixed.

**2. [Observation] The plan's `<action>` says "the four contract test files"; its `<verify>` lists five.** All five were run in both runs.

**3. [Observation] `mix verify.release` could not be run as an alias in run 2** because of three pre-existing dirty/untracked tree items that the brief designates protected. Its four steps were run individually and all four pass. The alias itself is exercised end to end, at 0.10.0, inside `bin/verify-bump-rehearsal`'s clean clone.

**4. [Observation] Two of the plan's five contract files were not run under the bump** — `release_control_plane_contract_test.exs` and `changelog_contract_test.exs` are outside both `verify.doc_contract`'s and `verify.release`'s file lists. Both were inspected and found free of bump-sensitive version literals, and both pass at 0.9.0. Inspected, not measured.

**5. [Run 1, superseded] The clean-tree precondition was worked around** by temporarily restoring `.planning/config.json` to HEAD content. Not repeated in run 2.

## Issues Encountered

Run 1: three red gates and one reproduced intermittent, all documented above. None were fixed in that run; all four have since been fixed by Plans 202-06 through 202-10.

Run 2: one new finding (A2, the `ci.all` doc_contract no-op). Not fixed.

## Next Phase Readiness

**Ready for the Task 2 checkpoint. NOT ready to publish, and not complete.**

Task 2, Task 3 and Task 4 are `gate="blocking-human"` and are the maintainer's alone. Task 2 requires an explicit first-person confirmation of the push and its scope — the plan states that a relayed or inferred approval is not sufficient.

Two items the maintainer should decide on before that confirmation: the `ci.all` doc_contract no-op (A2), and the fact that three CI surfaces — the real release-please regeneration, `environment-protection.yml`, and the required `verify-bump-rehearsal` job — have never executed on GitHub Actions (A7).

---
*Phase: 202-release-0-10-0*
*Task 1 of 4 complete — re-run GREEN — plan HOLDS at the Task 2 human checkpoint*
*Run 1 recorded: 2026-09-22 (HEAD 9fe19b57) · Run 2 recorded: 2026-09-22 (HEAD bf575949)*

## Self-Check: PASSED

- `.planning/phases/202-release-0-10-0/202-05-SUMMARY.md` — FOUND on disk.
- Commit `8055d4fd` — FOUND in `git log`.
- `git rev-list --count bf575949..HEAD` → 1 (matches `commits: 1`).
- Working tree carries only the three pre-existing protected items.
