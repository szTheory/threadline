---
phase: 202-release-0-10-0
plan: 10
subsystem: infra
tags: [release, ci, release-please, doc-contract, shift-left, bash, git]

requires:
  - phase: 202-release-0-10-0
    provides: "Plan 02's `mix release.pins`, Plan 05's hand-run bump rehearsal and its three measured born-red causes, Plans 06/07/09's fixes for them"
provides:
  - "bin/verify-bump-rehearsal — a fail-closed, trace-free simulation of the next-minor release commit that runs the release gates against it"
  - "`mix verify.bump_rehearsal` — the named entrypoint"
  - "The `verify-bump-rehearsal` CI job, a member of the single required check `ci-required`"
  - "A CI topology contract assertion that makes the gate undeletable without a red test"
  - "Four more instances of the born-red hardcoded-pin defect, found and fixed"
affects: [202-05 resume, any future release plan, any PR that touches a documented install pin or a version-bearing prose line]

actuals:
  tokens: 9600
  tasks: 2
  commits: 3
  plan_head_before: 9af2fd3763f2e8e10a58a68c17a92cf65b9e5b6a

tech-stack:
  added: []
  patterns:
    - "Rehearse the release commit in a throwaway clone, not the working tree: trace-freedom by construction (clone + safe-temp-tree trap), never by edit-then-restore discipline"
    - "Simulate release-please's `extra-files` generic updater from `release-please-config.json` rather than hand-editing `mix.exs` alone — a mix.exs-only bump is born-red on its own contract"
    - "Ship the negative controls with the gate as documented environment variables, so 'this gate has teeth' stays reproducible instead of being a one-off claim in a summary"

key-files:
  created:
    - bin/verify-bump-rehearsal
    - .planning/phases/202-release-0-10-0/202-10-SUMMARY.md
  modified:
    - mix.exs
    - .github/workflows/ci.yml
    - CONTRIBUTING.md
    - test/threadline/ci_topology_contract_test.exs
    - test/threadline/adoption_pilot_doc_contract_test.exs
    - test/threadline/operator_surface_doc_contract_test.exs
    - test/threadline/getting_started_saas_doc_contract_test.exs
    - test/threadline/readme_doc_contract_test.exs

key-decisions:
  - "The rehearsal runs in a `git clone` inside a mktemp dir, not a `git worktree`. `git worktree add` writes a registration into the REAL repository's `.git/`, so a failed teardown leaves a registered worktree behind; a clone writes nothing to the source repo, which makes 'no worktree survives' true by construction rather than by cleanup."
  - "The bump is committed INSIDE the throwaway clone so `mix verify.release`'s `ensure_clean_tree!/0` is exercised end to end rather than bypassed. This is what 202-05 did by hand on a scratch branch."
  - "The extra-files trap is solved by simulating release-please's generic updater: rewrite the version on every `x-release-please-version` marked line in each file registered under `release-please-config.json` `extra-files`. Driven off the config file, so a newly registered extra-file needs no script edit."
  - "`verify-bump-rehearsal` IS a member of `ci-required`. The `environment-protection` precedent for staying out is that a contributor cannot fix a repository-configuration property; this defect class is contributor-fixable in the same pull request."
  - "The rehearsal synthesises a dated CHANGELOG heading for the unreleased next minor only when one is absent. Disclosed on stdout; it is the only fabricated input in the run."
  - "`verify.bump_rehearsal` stays out of `ci.all` — release-lane precedent set by `verify.release`, asserted by the topology contract."

patterns-established:
  - "A CI gate is wired with a contract assertion covering every direction that could weaken it: job present, alias invoked, no job-level `if:`, listed in the job-id header roster, in `ci-required`'s `needs:`, in no allowed-skips/allowed-failures list, and out of `ci.all`. Each proven by a reverted negative control."

requirements-completed: [RELEASE-02]

coverage:
  - id: D1
    description: "`bin/verify-bump-rehearsal` simulates the 0.9.0 -> 0.10.0 release commit — mix.exs, the release manifest, the extra-files marked lines, `mix release.pins` — and runs `mix verify.doc_contract` + `mix verify.release` against it."
    requirement: "RELEASE-02"
    verification:
      - kind: other
        ref: "bash bin/verify-bump-rehearsal -> 'Bump rehearsal OK: a 0.9.0 -> 0.10.0 release commit passes mix verify.doc_contract and mix verify.release', exit 0, 66s"
        status: pass
      - kind: other
        ref: "mix verify.bump_rehearsal -> same terminal summary, exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "The extra-files trap is resolved: a clean rehearsal at the next minor passes Family B of the version-truth contract."
    verification:
      - kind: unit
        ref: "test/threadline/version_truth_doc_contract_test.exs#every x-release-please-version marked line carries @version and is wired into release-please — passes inside the rehearsal at 0.10.0"
        status: pass
      - kind: other
        ref: "THREADLINE_BUMP_REHEARSAL_INJECT_DEFECT=stale-marked-line reproduces the 202-05 failure string verbatim, proving the rewrite is load-bearing"
        status: pass
    human_judgment: false
  - id: D3
    description: "The gate is fail-closed and has teeth: three negative controls each go red and name the cause."
    verification:
      - kind: other
        ref: "FORCE_UNRUNNABLE=1 -> '=== FAIL: forced unrunnable control ===', exit 1"
        status: pass
      - kind: other
        ref: "INJECT_DEFECT=hardcoded-pin -> release_artifact_contract_test.exs:342 'expected: {:threadline, \"~> 0.9.0\"} / actual: {:threadline, \"~> 0.10.0\"}', exit 1"
        status: pass
      - kind: other
        ref: "INJECT_DEFECT=stale-marked-line -> version_truth_doc_contract_test.exs:81 marked-line failure, exit 1"
        status: pass
    human_judgment: false
  - id: D4
    description: "The real working tree is byte-identical before and after every run, and no scratch branch, worktree or temp dir survives."
    verification:
      - kind: other
        ref: "in-script identity check over git status + HEAD + branch + worktree count + git hash-object over 28 blast-radius files -> 'tree identity: MATCH' on all five runs (1 red, 2 green, 2 controls)"
        status: pass
      - kind: other
        ref: "git status --porcelain=v1 -uall unchanged; git worktree list = 1 row; git branch --list 'scratch/*' = 0; no $TMPDIR/threadline-bump-rehearsal-parent.* survives"
        status: pass
    human_judgment: false
  - id: D5
    description: "The `verify-bump-rehearsal` CI job runs `mix verify.bump_rehearsal` on every pull request and is a member of the single required check."
    verification:
      - kind: unit
        ref: "test/threadline/ci_topology_contract_test.exs#the bump-rehearsal gate is wired, required, and never skip-listed"
        status: pass
      - kind: unit
        ref: "test/threadline/ci_topology_contract_test.exs#ci-required's needs: roster matches CONTRIBUTING.md in both drift directions and stays non-vacuous"
        status: pass
    human_judgment: false
  - id: D6
    description: "The contract assertion fails if the job is removed, dropped from ci-required, skip-listed, or made conditional — proven by four reverted negative controls."
    verification:
      - kind: other
        ref: "four ci.yml mutations each produce the named assertion failure; ci.yml restored byte-identically afterwards (diff -q against a pre-control copy)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Four further instances of the born-red hardcoded-install-pin defect, found by the gate's first run and fixed."
    verification:
      - kind: unit
        ref: "mix verify.doc_contract — 134 tests, 0 failures at 0.9.0 and again inside the rehearsal at 0.10.0"
        status: pass
    human_judgment: false
  - id: D8
    description: "The job behaves correctly on a hosted GitHub Actions runner (postgres service reachable, fetch-depth 0 clone, runtime inside the 15-minute budget)."
    verification: []
    human_judgment: true
    rationale: "Never executed on GitHub Actions. Nothing in this plan may push, dispatch a workflow, or open a PR, so the job definition is verified structurally (YAML parse, topology contract, local end-to-end run of the same command) but has not run in the hosted environment. First real evidence arrives on the next pull request."

duration: 78min
completed: 2026-09-22
status: complete
---

# Phase 202 Plan 10: Bump Rehearsal Gate Summary

**`bin/verify-bump-rehearsal` simulates the next-minor release commit inside a throwaway clone — including release-please's `extra-files` rewrite — and runs `mix verify.doc_contract` + `mix verify.release` against it; wired into CI as a member of the single required check, and it found four more born-red causes on its first run.**

## Performance

- **Duration:** ~78 min
- **Tasks:** 2 of 2
- **Files modified:** 9 (1 created, 8 modified)
- **Commits:** 3 + this SUMMARY

## Accomplishments

- A fail-closed, trace-free rehearsal of the 0.9.0 -> 0.10.0 release commit, runnable as `mix verify.bump_rehearsal` in 66 seconds.
- The extra-files trap resolved by simulating release-please's generic updater off `release-please-config.json`, not a hardcoded list.
- Three shipped negative controls that keep "this gate has teeth" reproducible.
- The `verify-bump-rehearsal` CI job, in `ci-required`, in no allowed-skips list, pinned by a contract assertion proven with four reverted negative controls.
- **Four more copies** of the born-red hardcoded-pin defect 202-09 fixed once, found by the gate's first run and fixed the same way.

## Task Commits

1. **Deviation fix (found by Task 1's first run): four more hardcoded install pins** — `67081fc3` (fix)
2. **Task 1: `bin/verify-bump-rehearsal` + `mix verify.bump_rehearsal`** — `7c7310f7` (feat)
3. **Task 2: the `verify-bump-rehearsal` CI job + topology contract** — `10c1c6ee` (feat)

---

# How the extra-files trap was solved

`release-please-config.json` registers two files under `packages["."]["extra-files"]`:
`guides/adoption-pilot-backlog.md` and `guides/evaluating-threadline.md`. Each carries one
line annotated `<!-- x-release-please-version -->` whose prose states the current version
(`Distribution preflight below reflects the **0.9.0** tree`). release-please's `generic`
updater rewrites the version **on that line** in the same commit that bumps `mix.exs`.
`mix release.pins` deliberately does not own those lines — the ownership separation is
enforced by Family B-inverse of the version-truth contract — so a mix.exs-only bump leaves
them stale and Family B fails.

The script's `apply_extra_files_rewrite` reads the path list out of the config with `jq` and,
for each registered file, replaces the current version with the next one **only on lines
matching `x-release-please-version`**:

```bash
CUR="$CURRENT" NXT="$NEXT" perl -pi -e \
  's/\Q$ENV{CUR}\E/$ENV{NXT}/g if m{x-release-please-version}' "$CLONE/$path"
```

Three properties make this a faithful simulation rather than a patch over the symptom:

1. **Driven off the config, not a list in the script.** A newly registered extra-file is
   picked up with no script edit — the same reason `mix release.pins` uses a glob rather
   than an allowlist.
2. **Blast radius matches the updater's.** Surrounding prose and markup stay byte-identical;
   only the version on the marked line moves. A marked line in a file that is *not*
   registered is deliberately left alone, so Family B's second assertion (marked file must be
   wired into `extra-files`) still fires as a real defect.
3. **It fails closed if the marker disappears.** Zero registered extra-files, a registered
   path that does not exist, or zero marked lines across all of them each produce a named
   FAIL. The marker vanishing is exactly the drift Family B exists to catch, so the rehearsal
   must not silently proceed without it.

**Proof it is load-bearing** — `THREADLINE_BUMP_REHEARSAL_INJECT_DEFECT=stale-marked-line`
skips the rewrite and reproduces the 202-05 failure verbatim:

```
1) test every x-release-please-version marked line carries @version and is wired into release-please
   (Threadline.VersionTruthDocContractTest)
   test/threadline/version_truth_doc_contract_test.exs:81
   guides/adoption-pilot-backlog.md has an x-release-please-version marked line that does not
   contain the current @version 0.10.0. release-please replaces the version on the marked line;
   if the prose does not match @version today, the current-version claim is already stale.
   Update the number to 0.10.0.
```

With the rewrite in place, Family B passes at 0.10.0. **The trap is resolved, not excluded.**

## The one disclosed fabrication: the CHANGELOG stand-in

`bin/verify-release-shape` requires a dated `## [<version>]` heading. For an *unreleased*
next minor that section does not exist — in this repo CHANGELOG.md is human-owned (Plan
202-03) and release-please owns CHANGELOG-GENERATED.md. The rehearsal therefore synthesises
`## [<next>] - <today>` **if and only if** no heading for the next minor exists, and prints
that it did so. It stands in for work that provably happens in the real release commit, and
it is the only fabricated input in the run. Today it is a no-op: CHANGELOG.md already carries
`## [0.10.0] - 2026-09-22`, and the script reports `CHANGELOG.md already carries a heading
for 0.10.0 — nothing synthesised`.

---

# Trace-freedom: structural, and verified

The real tree is **never mutated**. Every edit happens inside a `git clone --no-local` into a
`mktemp -d`, registered with `bin/safe-temp-tree` and torn down by a `trap` on `EXIT INT
TERM` — the shape `bin/verify-clean-checkout` established. A clone rather than a
`git worktree` is deliberate: `git worktree add` writes a registration into the **real**
repository's `.git/`, so a failed teardown leaves a registered worktree behind. A clone
writes nothing into the source repository at all.

The bump is committed *inside* the clone (`git -c user.name=... commit --all`), because
`mix verify.release` starts with `ensure_clean_tree!/0` and an uncommitted bump would abort
the gate before its step list ran. The clone is detached and thrown away, so that commit
reaches nothing.

**Identity check (in-script, every run).** `capture_identity` is taken before and after and
compared; a difference is a FAIL even when the gates passed. It covers
`git status --porcelain=v1 -uall`, HEAD, branch, the worktree count, and a
`git hash-object` per file over the 28-file blast radius (mix.exs, both changelogs, the
release-please config and manifest, README, all 20 guides, the two contract tests the
rehearsal could touch, and ci.yml). Output on every one of the five runs in this session:

```
==> verifying the real working tree is byte-identical
    tree identity: MATCH (28 files checksummed, plus status/HEAD/branch/worktree count)
    no scratch branch and no linked worktree survived
```

**Independent confirmation after the final run:**

```
$ git status --porcelain=v1 -uall
 M .planning/WINDOWS.md
 M .planning/config.json
?? .tool-versions

$ git worktree list
/Users/jon/projects/threadline  10c1c6ee [fix/branch-protection-actions-capability]

$ git branch --list 'scratch/*'        # (no output)
$ ls -d $TMPDIR/threadline-bump-rehearsal-parent.*
no temp parents survive

$ grep -c '~> 0.9.0' README.md ; grep '@version' mix.exs | head -1
1
  @version "0.9.0"
```

The three protected pre-existing items — `M .planning/config.json`, `M .planning/WINDOWS.md`,
`?? .tool-versions` — end exactly as they began, modified-and-uncommitted and untracked
respectively, and were never staged, committed, moved or restored.

*(`.tool-versions` is deliberately untracked, so the clone does not inherit it and an
asdf-managed shell would resolve a different Elixir inside `/tmp`. The script copies it
across when present. In CI the file is absent and `erlef/setup-beam` has already pinned the
toolchain, so this is a no-op there.)*

---

# The negative controls

## Control 1 — the unrunnable path (fail-closed)

```
$ THREADLINE_BUMP_REHEARSAL_FORCE_UNRUNNABLE=1 bash bin/verify-bump-rehearsal
==> rehearsing the next minor: 0.9.0 -> 0.10.0
==> cloning HEAD (67081fc3...) into a throwaway tree

=== FAIL: forced unrunnable control ===
  THREADLINE_BUMP_REHEARSAL_FORCE_UNRUNNABLE=1 is set.
  This is the exercise of the unrunnable path: a rehearsal that cannot run is a
  failure, never a silent pass.
EXIT=1
```

## Control 2 — reintroduce BR-5, the hardcoded pin (reverts Plan 202-09)

`THREADLINE_BUMP_REHEARSAL_INJECT_DEFECT=hardcoded-pin` replaces
`Mix.Tasks.Release.Pins.target_pin_version()` with the literal `0.9.0` **in the clone only**:

```
==> GATE: mix verify.release at 0.10.0
Release shape OK for version 0.10.0

  1) test README carries only the release-scoped installer and routing literals
     (Threadline.ReleaseArtifactContractTest)
     test/threadline/release_artifact_contract_test.exs:342
     README.md does not carry the install pin derived from mix.exs @version.
       expected: {:threadline, "~> 0.9.0"}
       actual:   {:threadline, "~> 0.10.0"}
     `mix release.pins` owns every documented pin — run it rather than editing the pin by hand.

36 tests, 1 failure
** (Mix) verify.release failed while running mix test test/threadline/release_artifact_contract_test.exs test/threadline/ci_topology_contract_test.exs (2)

==> verifying the real working tree is byte-identical
    tree identity: MATCH (28 files checksummed, plus status/HEAD/branch/worktree count)
    no scratch branch and no linked worktree survived

Bump rehearsal FAIL: 0.9.0 -> 0.10.0 would release RED.
The failing gate was: mix verify.release at 0.10.0
```

This is BR-5 as 202-05 measured it, reproduced from a standing control rather than a hand
edit — **the gate names the cause, and the real tree is still untouched**.

## Control 3 — the extra-files trap

Quoted in full above. Reproduces the 202-05 Family B failure string verbatim.

## Controls 4–7 — the CI contract assertion (Task 2)

Each mutation applied to `.github/workflows/ci.yml`, the topology test run, then
`git checkout --` to revert. `ci.yml` was `diff -q`-confirmed byte-identical to a pre-control
copy afterwards.

| # | Mutation | Assertion that fired |
|---|---|---|
| 4 | job block deleted | `verify-bump-rehearsal is gone from .github/workflows/ci.yml. It is the only check that observes the release-commit state…` |
| 5 | dropped from `ci-required`'s `needs:` | `verify-bump-rehearsal is not in ci-required's needs:. Outside the single required check it is advisory…` — **two** tests failed here; the pre-existing D-42 roster contract catches it independently |
| 6 | added to `allowed-skips:` | `verify-bump-rehearsal appears in an allowed-skips or allowed-failures list. That launders a red release rehearsal into a green merge gate (D-09).` |
| 7 | job-level `if:` added | `verify-bump-rehearsal acquired a job-level 'if:'. A conditionally skipped member of ci-required needs an allowed-skips entry to keep the aggregate green…` |

---

# Required-check membership: the decision and its reasoning

**Decision: `verify-bump-rehearsal` IS in `ci-required`'s `needs:`.**

The precedent for staying out is `.github/workflows/environment-protection.yml`, and the
reason it stays out is specific: it asserts a property of **repository configuration** — a
live required-reviewer rule on the `production-hex` environment. A contributor cannot fix
that from a pull request, so blocking their merge on it would punish them for something
outside their diff.

This gate is the opposite. Every cause it detects — a stale documented install pin, a stale
`x-release-please-version` prose line, a contract assertion that hardcodes the current
version — is **introduced by a diff and fixable in that same diff, by the same person**. That
is precisely the distinction the plan named, and it is the distinction that decides this.

The argument against is runtime and coupling every PR to the release toolchain. Measured:
**66 seconds wall locally** for the entire run (throwaway clone, `deps.get`, `release.pins`,
`verify.doc_contract`, `verify.release` including ExDoc and `hex.build`). The job budget is
15 minutes — roughly 4x headroom for a slower 2-core hosted runner without hiding a hang. It
runs in parallel with thirteen other jobs and is nowhere near the critical path, which is
`verify-example-browser`. The coupling objection is real but inverted: the release toolchain
is *already* coupled to every PR — that is why four plans of work accumulated on top of
three latent born-red causes. What was missing was the signal, not the coupling.

The decisive argument, though, is what a non-required red actually does. An advisory red on a
check nobody must satisfy is exactly how a born-red cause reaches the publish gate anyway —
it gets noticed, deferred, and forgotten. That is the outcome this job exists to remove.

**The job appears in no `allowed-skips` or `allowed-failures` list.** Both remain absent from
the workflow entirely; `grep -nE 'allowed-skips|allowed-failures' .github/workflows/ci.yml`
returns only the three explanatory comment lines that were already there.

---

# Deviations from Plan

### 1. [Rule 1 — Bug] Four more copies of the born-red hardcoded-pin defect

- **Found during:** Task 1, the gate's **first** run.
- **Issue:** Plan 202-09 fixed one instance of "a contract test hardcodes `~> 0.9.0`, which
  `mix release.pins` rewrites at the bump". There are four more, and all four are green at
  0.9.0 and red at 0.10.0 — the exact defect class this plan exists to catch:
  - `test/threadline/adoption_pilot_doc_contract_test.exs:13` (and its test name)
  - `test/threadline/operator_surface_doc_contract_test.exs:58`
  - `test/threadline/getting_started_saas_doc_contract_test.exs:33`
  - `test/threadline/readme_doc_contract_test.exs:239`
- **Fix:** all four now consult `Mix.Tasks.Release.Pins.target_pin_version()`, the same
  derivation 202-09 applied. The stale-floor `refute` assertions (`~> 0.6`, `~> 0.5`, …) are
  untouched — those are literals on purpose.
- **Verification:** `mix verify.doc_contract` — 134 tests, 0 failures, both at 0.9.0 and
  inside the rehearsal at 0.10.0.
- **Committed in:** `67081fc3`, deliberately a separate commit from the gate so the
  fix is reviewable on its own.
- **Why this is a deviation and not scope creep:** Task 2's `<precondition>` requires Task 1's
  script to pass locally. It could not, for a real and fixable reason the gate itself named.
  The alternatives were to fix them or to halt; fixing is what the gate demands of any PR
  author who trips it.

### 2. [Rule 3 — Blocking] `mix.exs` comment rewritten to durable vocabulary

- **Found during:** Task 2.
- **Issue:** the `verify.bump_rehearsal` alias comment said "the born-red defect class Phase
  202 found", and `mix.exs` is a **packaged** file. `ReleaseArtifactContractTest`'s
  planning-vocabulary guard failed on `mix.exs:134: phase_prose`.
- **Fix:** rewritten as durable domain rationale with no phase reference. `bin/` is not in
  `package[:files]`, so the script's own phase references are correctly out of scope.
- **Verification:** `mix test test/threadline/release_artifact_contract_test.exs` — 0 failures.
- **Committed in:** `10c1c6ee`.

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking). **Impact:** the first is the gate
doing its job before it was even wired up; the second is the repo's own vocabulary contract
doing its job. No scope creep.

---

# Where the plan was wrong, reported rather than bent

**The plan's framing of the three born-red causes is not accurate for two of them.** The brief
states all three "were green at the current version and only observable under a simulated
version bump". 202-05's own measurements contradict that:

| Cause | Green at 0.9.0? | Actually invisible because… |
|---|---|---|
| BR-3 Dialyzer `unknown_function` | **No** — `MIX_ENV=dev mix verify.dialyzer` exited 2 at 0.9.0 | it was red at the current version; CI's `verify-dialyzer` job would have caught it on the next PR |
| BR-4 ExDoc, 29 warnings | **No** — `mix docs --warnings-as-errors` failed at 0.9.0 | CI's `verify-docs` job runs `mix docs` **without** `--warnings-as-errors`, so the gate configuration hid it, not the version |
| BR-5 hardcoded pin | **Yes** | genuinely bump-only — the only pure instance |

So the defect class this gate is uniquely positioned to catch is BR-5's, and the four new
instances found in Task 1 are more of the same. BR-4's class is caught too, incidentally,
because the rehearsal runs the full `mix verify.release` (which *does* use
`--warnings-as-errors`) rather than CI's weaker `verify-docs`. **BR-3's class is not caught by
this gate at all** — the rehearsal runs no Dialyzer, and adding one would cost a PLT build.
`verify-dialyzer` already covers it on every PR, so this is a gap in the plan's claim, not in
the pipeline.

The `must_haves` backstop truth ("would have caught all three of the born-red causes")
therefore holds for **two of three**: BR-5 by direct proof (Control 2), BR-4 by construction
(the rehearsal runs the entrypoint that caught it), BR-3 **not** by this gate.

**One `<verify>` clause is stricter than the rule it cites.** Task 2's verify says
`git diff HEAD~1 -- .github/workflows/ci.yml` fails when "the job-id contract header block
differs from its previous content". Adding a job necessarily adds its id to that roster — the
header is a list of the stable keys that exist, and a new job absent from it would make the
header wrong. The `<action>`'s actual rule ("Do not rename or remove any existing job id") is
satisfied exactly: the diff is `+ verify-bump-rehearsal` inserted before `ci-required`, with
zero removals and zero renames. The existing header contract test
(`~r/^# Job id contract[^\n]*\n#[^\n]*verify-dialyzer/m`) still passes, and a new assertion
now pins `verify-bump-rehearsal` into the roster too. Flagged rather than silently ignored.

---

# Files Created/Modified

- `bin/verify-bump-rehearsal` — the rehearsal (420 lines, over half of it the rationale a
  future editor needs so as not to reintroduce the trap).
- `mix.exs` — `verify.bump_rehearsal` alias, `preferred_cli_env` entry, `verify_bump_rehearsal/1`.
- `.github/workflows/ci.yml` — the `verify-bump-rehearsal` job, appended to the job-id roster
  and to `ci-required`'s `needs:`.
- `CONTRIBUTING.md` — the `ci-required` needs roster and the stable-job-key table (the
  roster contract test reads both).
- `test/threadline/ci_topology_contract_test.exs` — the undeletability assertion.
- `test/threadline/{adoption_pilot,operator_surface,getting_started_saas,readme}_doc_contract_test.exs`
  — the four derived install pins.

## Known Stubs

None.

## Issues Encountered

None beyond the two deviations above.

## Next Phase Readiness

- **RELEASE-01 is NOT complete.** 0.10.0 is not published. Nothing in this plan pushed,
  tagged, dispatched a workflow, or called a mutating GitHub API verb.
- 202-05's human-gated push/merge/publish remains the outstanding work, and it now has one
  more piece of evidence in its favour: `mix verify.bump_rehearsal` passes at 0.10.0, which is
  the strongest pre-publish signal this repository has ever had.
- The `verify-bump-rehearsal` job has never run on GitHub Actions (D8, human judgment). First
  real evidence arrives on the next pull request.
- 0.11.0 inherits the gate: any PR that hardcodes a version-bearing literal now goes red at
  the PR, not at the publish gate.

---
*Phase: 202-release-0-10-0*
*Completed: 2026-09-22*

## Self-Check: PASSED

- `bin/verify-bump-rehearsal` — FOUND
- `.planning/phases/202-release-0-10-0/202-10-SUMMARY.md` — FOUND
- `67081fc3`, `7c7310f7`, `10c1c6ee` — all FOUND in `git log`
- `bash bin/verify-bump-rehearsal` → exit 0, terminal summary OK
- `mix verify.bump_rehearsal` → exit 0
- `git status --porcelain` → the three pre-existing items only
- `git branch --list 'scratch/*'` → empty; `git worktree list` → 1 row
- `grep -nE 'allowed-skips|allowed-failures' .github/workflows/ci.yml` → 0 occurrences of the new job id
- `mix test test/threadline/ci_topology_contract_test.exs` → 18 tests, 0 failures
- `mix verify.doc_contract` → 134 tests, 0 failures
- `mix verify.format`, `mix verify.credo --strict` → clean
