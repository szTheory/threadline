---
phase: 220-newest-toolchain-lane
plan: 04
subsystem: infra
tags: [ci, elixir-1.20, otp-29, postgres-18, landing, pr-60]

requires:
  - phase: 220-03
    provides: "220-SPIKE.md Outcome GREEN (run 36484105399) and spike/220-latest at 4a32cbf6"
provides:
  - "PR #60 (land/v1.43-217-218) at 4a32cbf6, carrying the voting latest row with its roster, parity and fail-closed contracts"
  - "PR #60 pull_request run 36487483472: CI required, Run test suite (latest|min|current) all success"
  - "220-SPIKE.md ## Landing section, plus a correction to plan 03's vacuous zsh tree gate"
affects: [phase-220-verification, v1.43-landing]

actuals:
  tokens: 1900
  tasks: 3
  commits: 1
plan_head_before: 975508e93ed1bb0a5a26adac7e61cd351b38397c
plan_head_after: 74fdf8c8c0b7388cc1e33705430b0f339257757d

tech-stack:
  added: []
  patterns:
    - "Tree-equality gates must word-split the path list (run under bash, or use set -- $P); zsh leaves an unquoted multi-line $P as a single non-matching pathspec, so git diff --quiet passes vacuously"

key-files:
  created:
    - .planning/phases/220-newest-toolchain-lane/220-04-SUMMARY.md
  modified:
    - .planning/phases/220-newest-toolchain-lane/220-SPIKE.md

key-decisions:
  - "GREEN branch taken: no code edits. PR #60 was fast-forwarded fcb22e00..4a32cbf6, and the voting latest lane landed with its contracts"
  - "Plan 03's tree gate claim was vacuous under zsh. A proper re-run shows 10 of 11 paths byte-equal to milestone/v1.43. mix.exs differs only in the landing branch's pre-existing release-please @version 0.11.1 bump, and the phase hunks match by patch-id"

requirements-completed: [LANE-01]

coverage:
  - id: D1
    description: "PR #60 carries the voting latest lane and its CI run on the landed SHA is green"
    requirement: LANE-01
    verification:
      - kind: integration
        ref: "gh run view 36487483472 (pull_request, headSha 4a32cbf6): CI required job 109150727021 success; Run test suite (latest) job 109147800434 success"
        status: pass
    human_judgment: false
  - id: D2
    description: "The fail-closed D-15/D-16 contracts are on the landing branch"
    requirement: LANE-01
    verification:
      - kind: unit
        ref: "mix test (4 CI contract files): 108 tests, 0 failures; voting_lane_errors/1 and postgres_image_errors/1 present in origin/land/v1.43-217-218"
        status: pass
    human_judgment: false
  - id: D3
    description: "The spike is cleaned up and the local landing ref matches origin"
    verification:
      - kind: other
        ref: "git worktree list; git branch --list spike/220-latest; git ls-remote origin refs/heads/spike/220-latest; rev-parse land == origin/land"
        status: pass
    human_judgment: false

duration: 12min
completed: 2026-09-28
status: complete
---

# Phase 220 Plan 04: Land the newest-toolchain lane (GREEN) Summary

**PR #60 was fast-forwarded to `4a32cbf6`, which carries the voting `lane: latest` row (Elixir 1.20.4 / OTP 29.1.1 / PG 18.6) and its fail-closed contracts. Its `pull_request` run 36487483472 passed all 16 jobs, including `CI required` and `Run test suite (latest)`.**

## Performance

- **Duration:** about 12 min. About 7 min of that was waiting on the CI run.
- **Started:** 2026-09-28T21:40Z
- **Completed:** 2026-09-28T21:52Z
- **Tasks:** 3. Task 2 was resolved by the maintainer's grant.
- **Files modified:** 1 (220-SPIKE.md), plus this SUMMARY

## Task 1 (tracer): GREEN landing-tree proof

The outcome line in `220-SPIKE.md` is `GREEN`, so the plan made no code edits. The push had already happened when these checks ran; see Deviations.

| Check | Result |
|-------|--------|
| `origin/land/v1.43-217-218` after fetch | `4a32cbf6ccf026ffd727d2c183d9aa356431f788` (= spike tip) |
| `merge-base --is-ancestor fcb22e00 origin/land` (fast-forward) | exit 0 |
| `merge-base --is-ancestor origin/land spike/220-latest` (plan verify) | exit 0 (the two are equal) |
| `git log fcb22e00..origin/land` | exactly `56015527 refactor(220)`, `4a32cbf6 ci(220)` |
| patch-id `17a7faa5` vs `56015527`; `77ff2392` vs `4a32cbf6` | EQUAL; EQUAL |
| Tree equality vs `milestone/v1.43`, 11 touched paths (properly word-split) | 10/11 byte-equal. `mix.exs` differs only in `@version` (land `0.11.1` from release-please, which predates the phase; milestone `0.11.0`) |
| `.planning/` paths in `fcb22e00..4a32cbf6` | 0 |
| 4 CI contract test files (parity, topology, action runtime, browser full projects) | 108 tests, 0 failures |
| `defp voting_lane_errors(` / `defp postgres_image_errors(` count (working tree and landed tree) | 2 / 2 |
| `actionlint -shellcheck=` on the landed ci.yml | clean |
| `mix format --check-formatted`; `mix verify.credo` | clean; no issues (4315 mods/funs) |
| `git status --porcelain -- .github lib test CONTRIBUTING.md README.md mix.exs` | empty |

Spike tip landed: **`4a32cbf6ccf026ffd727d2c183d9aa356431f788`**. No code edits (GREEN).

I did not re-run `mix verify.test` or `mix ci.all` locally. The landed code tree was proven green on CI twice: by spike run 36484105399 and by PR run 36487483472. Plan 02 had already run `mix ci.all` on the same code.

## Task 2: grant (resolved)

The maintainer granted this in their own messages: "yes i grant both of those go for it no problemo", then "i allow u to do that for me plz". The orchestrator performed the grant's remote writes on 2026-09-28:
1. It fetched `land/v1.43-217-218`, whose head was `fcb22e00`, and confirmed the fast-forward.
2. It ran `git push origin spike/220-latest:land/v1.43-217-218`, which moved the branch `fcb22e00..4a32cbf6`.
3. It ran `git push origin --delete spike/220-latest`.

This executor made no remote writes.

## Task 3: PR #60 run and cleanup

- **Run 36487483472.** The event was `pull_request`, headSha `4a32cbf6ccf026ffd727d2c183d9aa356431f788` (= landed SHA). It was created 21:38:47Z and completed 21:47:14Z with conclusion **success**, and all 16 jobs passed.
  - `CI required`: success (job 109150727021)
  - `Run test suite (latest)`: success (job 109147800434). It printed `Result: 2513 passed (9 properties, 2504 tests), 3 excluded` and had a cold cache miss.
  - `Run test suite (min)`: success (job 109147800262)
  - `Run test suite (current)`: success (job 109147800283)
  - `gh pr view 60` rollup: `4a32cbf6… Run test suite (min)=SUCCESS Run test suite (current)=SUCCESS Run test suite (latest)=SUCCESS CI required=SUCCESS`
- **Cost:** 53 billed runner-minutes (44.4 unrounded); the latest lane billed 6. This was a cold run.
- **Cleanup:**
  - `git worktree remove /tmp/threadline-spike-220`
  - `git branch -D spike/220-latest` (was 4a32cbf6)
  - `git fetch origin land/v1.43-217-218:land/v1.43-217-218` (`fcb22e00..4a32cbf6`; local = origin)
  - removed `/private/tmp/threadline-220-latest-build` and `/private/tmp/threadline-220-spike`
  - `git ls-remote` confirms the remote spike branch is gone
- **Landing record:** `220-SPIKE.md` `## Landing`, commit `74fdf8c8` (`git show --name-only` lists only 220-SPIKE.md). `bin/verify-repo-hygiene` was clean and the username grep found nothing.

## Task Commits

1. **Task 1: GREEN landing-tree proof.** No commit (no code edits on GREEN).
2. **Task 2: grant.** No commit.
3. **Task 3: landing record.** `74fdf8c8` (docs)

## Deviations from Plan

**1. [Ordering] The landing push came before Task 1's local re-check.**
- The auto-mode classifier blocked the delegated push. The orchestrator then ran the push and the remote branch deletion itself, under the maintainer's explicit authorization, before this executor ran.
- Task 1's checks ran afterwards against `origin/land/v1.43-217-218` = `4a32cbf6`, and all of them passed. Had any failed, the fix would have been a follow-up commit rather than an unpushed hold.

**2. [Rule 1 - Bug] Plan 03's tree-equality gate was vacuous.**
- **Found during:** Task 1.
- **Issue:** `git diff --quiet milestone/v1.43 <tip> -- $P`, run under zsh with an unquoted multi-line `$P`, does not word-split. That makes the pathspec one non-matching path, so the check exits 0 whatever the trees contain. My first re-check hit the same trap before I caught it.
- **Fix:** I re-ran the check under `bash -c` with `set -- $P`. 10 of 11 paths are equal. `mix.exs` differs only by the landing branch's pre-existing `@version 0.11.1`, and the phase commits match their originals by `patch-id`. Nothing unintended landed.
- **Files modified:** 220-SPIKE.md (the correction note in `## Landing`).
- **Committed in:** `74fdf8c8`.

**3. [Scope] Step 4's remote spike deletion was done by the orchestrator, not the executor.**
- This follows the same reason as deviation 1. I verified it with `git ls-remote`.

## Issues Encountered

None blocking. Run 36487483472 was green on the first attempt.

## Next Phase Readiness

- PR #60 now carries phases 217, 218 and 220 code, and it is green on `4a32cbf6`.
- The scrubbed `docs(planning)` sync of the planning tree onto the land branch still follows phase verification, as it did for 219.
- The warm per-run cost of the latest lane is still unmeasured. The first warm runs on main after merge will show it.
- The landing branch carries release-please's `@version 0.11.1` while `milestone/v1.43` has `0.11.0`. This is expected, and it is the reason `mix.exs` is not byte-equal.

## Self-Check: PASSED

- FOUND: .planning/phases/220-newest-toolchain-lane/220-SPIKE.md with `## Landing`
- FOUND commit: 74fdf8c8
- FOUND remote: origin/land/v1.43-217-218 = 4a32cbf6; spike branch absent locally and remotely
