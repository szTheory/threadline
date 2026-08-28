---
phase: 198-green-bringup
plan: 06
subsystem: infra
tags: [github-actions, hex, release, git, ci, contract-tests, flake-detection]

requires:
  - phase: 198-04
    provides: 198-TRIAGE.md (the honest red baseline this plan appends its decisions to) and the mix.exs test.reset/test.setup aliases
  - phase: 198-05
    provides: browser-full.yml and its `ci-browser-full` dedup label, which this plan's flake label must not collide with
provides:
  - The paid critic workflow deleted outright, guarded by a test over all workflow files
  - Exactly one Hex publish path (release.yml), guarded by a list-equality test
  - A production-hex GitHub Environment with a required-reviewer rule in front of the publish job
  - Flake Detection that names broken vs flaky vs unknown, time-bounded, on one deduplicated issue
  - Two verified annotated archive tags plus .planning/ARCHIVE-REGISTER.md; one worktree, one branch
affects: [198-07, 199-decouple, 202-release-0-10-0, 203-real-gates]

actuals:
  tokens: 21000
  tasks: 4
  commits: 7

tech-stack:
  added: []
  patterns:
    - "Glob-over-all-workflows contract assertions instead of hardcoded filename lists"
    - "List-equality assertions over count/refutation, so an empty glob cannot launder a false pass"
    - "Annotated archive tags + a tracked register as the branch-retirement protocol"
    - "Classifier anchored on a measured stable output marker, with an explicit unknown branch"

key-files:
  created:
    - .planning/ARCHIVE-REGISTER.md
    - .planning/audits/198-phase166-diff.md
  modified:
    - .github/workflows/release.yml
    - .github/workflows/flake-detection.yml
    - test/threadline/ci_topology_contract_test.exs
    - test/threadline/phase06_nyquist_ci_contract_test.exs
    - .planning/phases/198-green-bringup/198-TRIAGE.md
  deleted:
    - .github/workflows/ui-critic.yml
    - .github/workflows/hex-publish.yml

key-decisions:
  - "Legacy tag-triggered hex-publish.yml deleted (maintainer-confirmed 2026-08-27); release.yml is the single publish path and all five of its pre-publish gates are preserved untouched"
  - "Paid critic API key KEPT in the repository secret store (maintainer decision 2026-08-27, closed, no follow-up todo) — the consuming workflow is deleted so nothing in CI can reach it"
  - "The publish race is CONDITIONAL, not unconditional as planned: it is live only when RELEASE_PLEASE_TOKEN is configured, because GITHUB_TOKEN tag pushes do not fan out (release.yml:6,97,132)"
  - "Push-triggered ui-critic runs were capture-only by construction, so the push hazard was runner minutes, not API spend — deletion is still correct because GREEN-09 requires the input and trigger absent"
  - "phase-166 branch archived, not cherry-picked: main carries a strict superset, and the branch's one material difference (nine per-LiveView data-tl-theme attributes) is duplication main deliberately factored into ui.ex"
  - "production-hex Environment set with can_admins_bypass=false, so the human click is genuinely mandatory rather than skippable by the repo admin"

patterns-established:
  - "Resurrection guards live as tests in a file already wired into verify.release — a test, not a comment"
  - "Every guard is demonstrated red against a deliberate reintroduction before it is committed"
  - "Irreversible git operations are gated: tag created, tag object resolved, register row committed, only then delete"

requirements-completed: [GREEN-09, GREEN-10, GREEN-11]

coverage:
  - id: D1
    description: "The paid critic lane is structurally untriggerable from CI: ui-critic.yml deleted outright, no workflow references the API key"
    requirement: GREEN-09
    verification:
      - kind: unit
        ref: "test/threadline/ci_topology_contract_test.exs#no workflow references the paid critic API key (GREEN-09 resurrection guard)"
        status: pass
      - kind: other
        ref: "grep -rl ANTHROPIC .github/ returns no output"
        status: pass
    human_judgment: false
  - id: D2
    description: "Exactly one Hex publish path exists and it is the gated one; the legacy tag-triggered workflow is deleted"
    requirement: GREEN-10
    verification:
      - kind: unit
        ref: "test/threadline/ci_topology_contract_test.exs#exactly one workflow invokes the Hex publish command (GREEN-10 resurrection guard)"
        status: pass
      - kind: other
        ref: "mix verify.release (exit 0; 19 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The irreversible publish step sits behind a production-hex Environment carrying a required-reviewer rule, and Hex auth is one swappable block"
    verification:
      - kind: other
        ref: "yq '.jobs[\"publish-hex\"].environment' .github/workflows/release.yml -> production-hex"
        status: pass
      - kind: other
        ref: "gh api repos/szTheory/threadline/environments/production-hex --jq '.protection_rules[].type' -> required_reviewers"
        status: pass
    human_judgment: true
    rationale: "The gate's real behaviour — a release actually pausing for a human click — can only be observed on a live release run, which requires the push (198-07) and a real 0.10.0 cut (Phase 202). The configuration is proven; the runtime pause is not."
  - id: D4
    description: "Flake Detection classifies broken vs flaky vs unknown, carries timeout-minutes, and creates-or-updates a single deduplicated issue"
    requirement: GREEN-11
    verification:
      - kind: other
        ref: "Classifier logic replayed against four real captured logs: pass(exit0,4 iters), broken(exit2,1 iter), flaky(exit2,3 iters), unknown(exit2,0 iters) — all correct"
        status: pass
      - kind: other
        ref: "yq: every job carries timeout-minutes; label ci-flake distinct from ci-browser-full; job id verify-flake unrenamed"
        status: pass
    human_judgment: true
    rationale: "The live two-dispatch dedup demonstration (two failing runs writing to ONE issue) could not be run: workflow_dispatch requires the workflow to exist on the remote default branch, and this plan is forbidden to push. The classifier is proven; the gh issue create-or-update path is unexercised. Recorded in WINDOWS.md as unrun-verify."
  - id: D5
    description: "Every piece of unmerged work is preserved under a verified annotated archive tag with a recorded recommendation, before the repository was reduced to one worktree and one branch"
    verification:
      - kind: other
        ref: "git worktree list -> 1 entry; git branch -> main only; both archive/* tags are annotated (cat-file -t = tag) and resolve to dd5b48be / 50374eb7 post-deletion"
        status: pass
      - kind: other
        ref: "Both tag messages grep-verified to carry all ten D-31 elements (SHA, base, ancestry verification, diffstat, archive date, GREEN-12, recommendation, rationale, restore, ARCHIVE-REGISTER)"
        status: pass
    human_judgment: false

duration: 4h 15m
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 06: Irreversible-Hazard Closeout Summary

**Both hazard workflows deleted outright and guarded by glob-based contract tests, the surviving Hex publish path put behind a `production-hex` required-reviewer Environment, Flake Detection taught to say "broken" instead of "flaky" using a measured output marker, and two branches retired under verified annotated archive tags before the repo was reduced to one worktree.**

## Performance

- **Duration:** ~4h 15m
- **Started:** 2026-08-27T21:45Z
- **Completed:** 2026-08-28T02:00Z
- **Tasks:** 4 (one a `blocking-human` decision checkpoint)
- **Files created/modified/deleted:** 7 modified or created, 2 deleted

## Accomplishments

- **The paid critic lane cannot be reached from CI.** `ui-critic.yml` deleted outright — no stripped skeleton, because a workflow with its `score` input removed *is* the defaulted-off state GREEN-09 rejects.
- **Exactly one Hex publish path.** `hex-publish.yml` deleted; `release.yml` survives with all five pre-publish gates provably untouched (its diff contains **zero** deleted lines).
- **A human click in front of the irreversible step.** `production-hex` GitHub Environment created with a `required_reviewers` rule and `can_admins_bypass=false`; `publish-hex` bound to it; Hex authentication consolidated into one commented block marked as the trusted-publishing swap point.
- **Both facts asserted by tests, not comments** — in `ci_topology_contract_test.exs`, already wired into `verify.release` (`mix.exs:175`), and both demonstrated red before being committed green.
- **Flake Detection tells the truth**, anchored on output I measured rather than assumed.
- **Nothing was lost.** Two annotated archive tags, a tracked register, and a committed diff artifact — all created and verified *before* any deletion.

## Task Commits

1. **Task 1: Branch and worktree triage** — `7e2da68c` (docs). The destructive half of this task (worktree removal, branch deletion) produces no commit; see the ordering note below.
2. **Task 2: One-way decision gate** — `c456955f` (docs)
3. **Task 3: Delete both hazard workflows + guards** — `82b0b050` (chore, ui-critic), `8fcbbbe4` (feat, hex-publish + tests + Environment), `8b1aa2cc` (fix, Rule 1 auto-fix)
4. **Task 4: Flake Detection classification** — `d1b3bc81` (feat)

Housekeeping: `bd8931be` (chore) committed pre-existing orchestrator STATE.md bookkeeping so `mix verify.release` — which requires a clean tree via `ensure_clean_tree!` (`mix.exs:304`) — could run against the exact tree being validated.

## Files Created/Modified

- `.planning/audits/198-phase166-diff.md` — **new, 868 lines.** Live state, ancestry verification, per-file analysis of the branch against main, the verbatim 687-line code diff, and a `## Recommendation` answering both D-33 questions.
- `.planning/ARCHIVE-REGISTER.md` — **new.** Six columns, one row per archived ref, plus a Durability section stating the single-copy exposure until 198-07.
- `.planning/phases/198-green-bringup/198-TRIAGE.md` — `## Publish-path and secret-store decisions` appended.
- `.github/workflows/release.yml` — `environment: production-hex` on `publish-hex`; auth consolidated into a marked swap-point block. **Zero deleted lines.**
- `.github/workflows/flake-detection.yml` — classification, `timeout-minutes`, artifact upload, create-or-update issue.
- `test/threadline/ci_topology_contract_test.exs` — two resurrection guards.
- `test/threadline/phase06_nyquist_ci_contract_test.exs` — hardcoded workflow list replaced by a glob (Rule 1 fix).
- **Deleted:** `.github/workflows/ui-critic.yml`, `.github/workflows/hex-publish.yml`.

## Guard teeth — all four outcomes

The plan required both new guards be demonstrated failing against a deliberate reintroduction before commit. All four were observed:

| # | Guard | State induced | Result |
|---|---|---|---|
| 1 | Paid-key guard | Scratch `__scratch-teeth.yml` containing the key name (untracked, never staged) | **RED**, naming `.github/workflows/__scratch-teeth.yml` |
| 2 | Paid-key guard | Scratch removed | **GREEN** |
| 3 | Single-publish-path guard | `hex-publish.yml` still present (a real second publisher, not a synthetic one) | **RED**: `found: [".github/workflows/hex-publish.yml", ".github/workflows/release.yml"]` |
| 4 | Single-publish-path guard | `hex-publish.yml` deleted | **GREEN** (12 tests, 0 failures) |

The second guard asserts **list equality** against `[".github/workflows/release.yml"]` — not a count and not a bare refutation — so neither a publisher moving to the wrong workflow nor an empty glob can launder a false pass.

## Flake Detection: the measured output shape

RESEARCH A5 flagged the `--repeat-until-failure` format as unverified. It was measured before the parser was written, using a scratch probe test driven by a counter file:

| Case | exit code | `Running ExUnit with seed:` headers |
|---|---|---|
| All green, `--repeat-until-failure 3` | 0 | **4** |
| Fail on run 1 | 2 | 1 |
| Fail on run 3 | 2 | 3 |

**A real finding worth carrying forward: `--repeat-until-failure N` runs N+1 times** — the initial run plus N repeats. So `mix verify.flake` (`--repeat-until-failure 50`) is **51** suite runs, not 50. The classifier counts the `Running ExUnit with seed:` header, which is a stable per-run ExUnit banner, rather than regex-matching failure wording.

The classification logic was then replayed verbatim against four real captured logs plus an empty one: `pass`, `broken`, `flaky`, `unknown`, `unknown` — all correct, including the zero-header case that a naive parser would have mislabelled flaky.

`timeout-minutes: 120` is sized from a measured full-suite run of **72.9s** × 51 ≈ 62 minutes plus headroom. The file records the caveat honestly: no green 51-run pass has ever been observed, because the suite is not green yet, so this bound should be tightened to an observed p95 later.

## Decisions Made

Beyond the two checkpoint answers (recorded in `198-TRIAGE.md`), three findings corrected the plan's framing:

1. **The publish race is conditional.** The plan asserted the legacy path "wins the race by construction." `release.yml:6` states that tag pushes made with `GITHUB_TOKEN` do not fan out, and release-please runs with `secrets.RELEASE_PLEASE_TOKEN || secrets.GITHUB_TOKEN` (`:97`, `:132`). So the race is live **only when the fine-grained PAT is configured**. This strengthens rather than weakens the case for deletion: a publish path whose safety depends on which token happens to be configured, with nothing asserting that configuration, is one secret away from firing.

2. **The push hazard was runner minutes, not API spend.** The plan's stated urgency was that ~600 commits would "fire the parked paid lane." Read against the file, `ui-critic.yml:103-107` makes **push-triggered runs always capture-only** — paid scoring required `workflow_dispatch` with `score=true`. 61 of the 630 commits ahead of origin do match the path filter, so the push would have fired the workflow, but it would have cost a Postgres + Playwright capture run, not billing. Deletion remains correct on GREEN-09's own terms (the input and trigger must be *absent*), and the ordering constraint was honoured regardless — but the stated reason was overstated and is corrected here rather than repeated.

3. **The two branches sit on opposite sides of the GREEN-12 adjacency edge.** `gsd/phase-166-…` is not an ancestor of main (real unmerged work; the tag genuinely preserves something). `backup/pre-release-cleanup-2026-05-08` is a strict ancestor with an empty diff — deleting it could not have lost anything. Both were tagged per D-31, but the backup tag's message states plainly that it is **provenance, not preservation**, so a future reader does not mistake it for rescued work.

`can_admins_bypass` was set to `false` on the Environment. The API defaults it to `true`, which would have let the maintainer — an admin — skip the very click D-27 exists to require.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Hardcoded workflow-file list broken by this plan's deletions**
- **Found during:** Task 4 (a full-suite run taken to measure iteration duration)
- **Issue:** `phase06_nyquist_ci_contract_test.exs:131` held a hardcoded `@workflow_files` list naming `hex-publish.yml`. Deleting that file made the CI-02 `:latest` guard die with `File.Error: could not read file … hex-publish.yml`. Directly caused by this task's deletions, so squarely in scope.
- **Fix:** Replaced the literal list with a `Path.wildcard` glob over `.github/workflows/*.{yml,yaml}` plus a non-empty guard. This also closed a silent coverage gap: the literal list **never included `browser-full.yml`**, so the `:latest` guard was not actually checking every workflow it claimed to. A hardcoded filename list rots in both directions — red when a file goes away, under-asserting when one appears.
- **Files modified:** `test/threadline/phase06_nyquist_ci_contract_test.exs`
- **Verification:** `mix test test/threadline/phase06_nyquist_ci_contract_test.exs` — the `:latest` failure is gone; `mix verify.release` exits 0.
- **Committed in:** `8b1aa2cc`

---

**Total deviations:** 1 auto-fixed (1 bug).
**Impact on plan:** Necessary for correctness — the plan's own deletions broke an existing contract test. No scope creep; the fix stayed inside the assertion the deletions broke and made it non-rotting rather than merely re-listing filenames.

### Ordering note (Task 1 acceptance criterion)

One acceptance criterion asked that the artifact commit be "an ancestor of the commit deleting the branches." **Branch deletion and worktree removal produce no commit**, so no such commit exists. The ordering property was satisfied and evidenced differently: the artifact and register were committed as `7e2da68c` at 17:49:31, both tags were re-resolved with `git cat-file -p` immediately before the destructive step, and only then were the worktree and branches removed. Reflog carries the sequence. Stating this rather than silently marking the criterion met.

## Issues Encountered

- **`mix verify.release` requires a clean tree** (`ensure_clean_tree!`, `mix.exs:304`), which collided with pre-existing uncommitted orchestrator STATE.md bookkeeping. Resolved by committing that bookkeeping on its own (`bd8931be`) rather than stashing — `git stash` is prohibited, and in any case the point of the check is that the validated artifact matches the taggable tree.
- **Full-suite failure count moved 80 → 81** between 198-04's measurement and this plan. Reconciled exactly: +1 was the `:latest` File.Error I introduced and fixed. The residual failures are the 79 deferred test-side prefix defects plus the pre-existing `CONTRIBUTING.md` List 1 drift.

## Known gaps (not papered over)

1. **The Flake Detection dedup path is unrun.** The plan asked for two manual dispatches observing two runs writing to one issue. `workflow_dispatch` requires the workflow to exist on the remote default branch, and this plan is forbidden to push — so **no run ids and no issue number exist to record.** The classifier is proven against real logs; the `gh issue` create-or-update path is not exercised. Filed in `.planning/WINDOWS.md` as `unrun-verify`; it becomes dischargeable immediately after 198-07's push.
2. **`CONTRIBUTING.md` List 1 drift** (`only-in-jobs=["verify-capture", "verify-mechanical"]`) leaves `phase06_nyquist_ci_contract_test.exs` with one failure. Pre-existing, explicitly deferred and **unowned** in `198-TRIAGE.md`. Out of this plan's scope and not auto-fixed to make a number look better. It still needs an owner.
3. **The archive tags are single-copy.** They exist only on this laptop until 198-07 pushes them (D-32). Recorded in the register's Durability section.
4. **The `production-hex` gate is proven as configuration, not as behaviour.** A release actually pausing for approval can only be observed on a live run.

## Requirements

`GREEN-09`, `GREEN-10`, `GREEN-11` marked complete. **`GREEN-12` deliberately left open** — Plan 198-07 also declares it (the archive-tag push), and the shared-ID gate correctly blocks it until that plan finishes. The worktree/branch half is done; the durability half is not.

## User Setup Required

None. The one item that would have required a maintainer action outside these files — revoking the paid API key from the secret store — was answered **keep** as an explicit dated decision and is closed. No follow-up todo was created.

## Next Phase Readiness

Ready for **198-07** (the push plan), whose preconditions this plan establishes:

- Both push-blocking workflow hazards are gone; `ui-critic.yml` is deleted, satisfying D-34 step 2's ordering requirement that it precede the push.
- One gated publish path, verified green (`mix verify.release` exits 0).
- One worktree, one branch, two verified archive tags awaiting their push.

**Still gating 198-07:** D-34 step 4 (the credential audit and Class-A rotation) and step 5 (secret scanning + push protection). Nothing in this plan reached a remote. The abort branch — keep both publish paths if `release.yml` cannot be shown green — was armed and **not** taken.

## Self-Check: PASSED

- `.planning/ARCHIVE-REGISTER.md` — FOUND
- `.planning/audits/198-phase166-diff.md` — FOUND
- `.github/workflows/ui-critic.yml` — correctly ABSENT
- `.github/workflows/hex-publish.yml` — correctly ABSENT
- Commits `7e2da68c`, `c456955f`, `82b0b050`, `8fcbbbe4`, `8b1aa2cc`, `bd8931be`, `d1b3bc81` — all FOUND in `git log`
- Plan `<verification>` block re-run: `grep -rl ANTHROPIC .github/` empty; `grep -rl 'hex.publish' .github/workflows/` → `release.yml` only; `mix test test/threadline/ci_topology_contract_test.exs` → 12 tests, 0 failures; `mix verify.release` → exit 0; `git worktree list | wc -l` → 1; no non-main branch; both `archive/*` tags resolve and carry the full message; register has the six columns

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
