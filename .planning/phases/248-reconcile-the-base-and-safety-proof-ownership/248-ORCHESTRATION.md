# Phase 248 orchestration evidence

This is an execution log, not a product acceptance receipt. Phase 248 remains incomplete until its plan summaries and required verification establish its requirements.

## Reviewed planning

- Three independent focused reviews cover candidate preservation, mount authorization and current advisory/suite evidence. The approved milestone decisions were reused rather than reopened.
- The preservation-only UI contract passed all seven applicable review dimensions; rendered design changes remain in later phases. Its compiler-output consideration probe has explicit acceptance criteria.
- Four serial plans cover ADM-01–04. The independent plan review found one blocker: a classifier that exits zero for `unknown` could not enforce repeat-proof acceptance. The targeted revision captures real run status/log/time, asserts the `pass` token and verifies nine completed clean suite runs. Independent recheck passed.
- Deterministic plan structure and failure-direction checks passed. The verify-path probe returned `not_applicable` for these command forms; that is not a claim that it resolved Mix/Python targets.
- The phase edge probe retains three unclassified requirement rows as explicit assumptions alongside substantive verification. No unclassified item was silently dismissed.

## Isolation and launch

- The active GSD 1.20.0 runtime resolves `orchestrator-worktree` with a usable process descriptor. No worktree opt-out was used.
- The initial base check found no default fork reference. The supported local `worktree.set-baseref` command set `worktree.baseRef: head`; the subsequent base check returned `shouldDegrade: false`.
- GSD created the first plan's executor worktree through `worktree.create`, recorded it in a wave manifest, and verified its initial HEAD exactly matched the reviewed candidate. The worker independently observed matching physical cwd, git root, branch and HEAD before editing.
- Full workflow/role/template/path-safety embeds are supplied on stdin with the CLI's documented prompt-plus-stdin form. GSD rejects a standalone `-` prompt marker as missing prompt data; it did not launch a worker for that rejected descriptor.
- One CLI option-validation failure occurred before model execution: `--sandbox workspace-write` cannot be combined with `--approve-for-me`. The corrected invocation uses automatic approval review, which already selects the workspace sandbox. The failed attempt's record/log were retained, and the clean unchanged worktree was verified before restarting. This was not a product/test retry.
- The active worker's PID, log, actual paths, descriptor and prompt-source provenance are recorded in ephemeral launch metadata and GSD's sibling worker lifecycle record. Public artifacts must use relative worktree identities and source hashes rather than machine-local home paths.

## Verification boundaries

No product tests, dependency updates, workflow changes, hosted CI, issue mutations, version bump, merge or publication have been performed at this point. The first plan owns preservation/provenance only. Advisory and suite findings remain open until their actual remedies and proof run.

PostgreSQL accepts connections on the existing local test endpoint. That is prerequisite availability, not database or test acceptance evidence.

## Baseline plan reconciled

The worker completed and verified both artifact tasks but could not stage shared Git metadata. It returned an explicit checkpoint with no SUMMARY or commits. The orchestrator verified a tracer snapshot and committed it, restored and verified the complete inventory with all negative controls, committed the second task, and wrote/committed the summary. GSD manifest cleanup merged the exact branch and removed only the completed executor worktree. Post-merge inventory-only verification passed; the retained candidate remains unchanged.

For later executors, keep existing automatic approval review available for narrowly scoped authorized local Git operations. If that capability is unavailable or rejects the operation, preserve verified files and provide the precise commit handoff; the orchestrator can perform it without a new human permission step. Preserve per-task snapshots/verification evidence if metadata writes must be handed off. This addresses observed Git-permission friction without broadening sandbox access or disabling hooks.

The maintainer restated that automated apps/tests run in the background by default. Global instructions already contain it, and project AGENTS.md now records it for future runs. No app or browser focus was taken.

## Mount implementation awaiting targeted review fixes

The author committed the macro, explicit fixture intent and migration guidance, with successful focused auth/scope, operator-surface and documentation checks. The sandbox's automatic review handled subsequent authorized local Git operations, avoiding another manual Git handoff. No lockfile or dependency declaration changed.

A concurrent read-only callback review is recorded in `248-MOUNT-REVIEW.md`. Its reviewed router hash matches the author's final router source. It found two concrete compatibility/diagnostic gaps: accepted unary local/short captures still fail Phoenix option serialization; guarded multi-parameter fn clauses are counted as unary and miss the intended mount diagnostic. These are within the approved mount contract. The generated remote helper is an internal implementation detail, not a new adopter-facing API. The author worktree remains retained and unmerged until a targeted fix pass and recheck establish these properties. No phase or additional requirement is marked complete.

The author worker exited with a committed SUMMARY and a clean worktree. Its lifecycle record is retained separately; the fix continuation reuses the same actual GSD-created worktree only after that terminal reconciliation. No simultaneous source writers or shared-DB test suites are allowed. The fix pass owns only the router, its compile tests, a SUMMARY appendix and a separate fix report.

## Mount slice merged and bookkeeping correction

Both mount review findings were fixed in the retained executor worktree with real Phoenix route/lifecycle regressions. Focused auth/scope, the complete affected operator-surface suite and formatting passed after both fixes. Independent recheck recorded a clean verdict; the merged router and test file hashes exactly match that reviewed source. GSD manifest cleanup merged the branch and removed only this completed executor worktree. Its advisory scope warning names only the additional `248-MOUNT-FIXES.md` review artifact, not an unexpected product change.

An absolute local link entered the reviewer's rechecked Markdown. The parent's privacy check caught it, but the surrounding orchestration sequence failed to branch on the nonzero tool result and proceeded to commit and merge. No remote write occurred. The link was forward-corrected to a relative sibling link, whitespace was normalized, and all phase artifacts were checked again for machine-local home paths. Preserve the repository's forward-scrub policy rather than rewriting history.

Dependent mutations must stop on a nonzero exec result, missing/active completion or an unsuccessful structured payload. Printing a tool result does not propagate its failure. The corrected orchestration explicitly checks exit status before commit/merge/bookkeeping and checks GSD payload flags; this is an execution guard, not a new user confirmation step.

## Publication boundary for the corrected report link

The current planning tree is scrubbed, but the accidental local-link revision exists in unpublished orchestration history. Keep that history local. Before any authorized push, prepare a clean landing branch through the repository's PR workflow so this new local-link revision is not published. Do not infer permission to push this orchestration branch or accept that exposure. No published history is rewritten and no external risk acceptance is needed to continue local development.

## Compatible advisory slice integrated

Plan 248-03's actual GSD worktree fork/cwd matched the recorded current candidate. Mix generated only six changed package tuples: Ecto in three locks, Phoenix.HTML in root/example, and Bandit in example. The direct Ecto update exposed its transitive dependency status; targeted Mix unlock/get resolved it without declaration changes, invented checksums or collateral drift. Final all-lock audit output reported zero findings and existing tier-policy contracts passed. Patched package metadata was reviewed against the existing floor; current-toolchain compilation is distinct from an unperformed minimum-runtime run. See [248-ADVISORY-PROOF.md](248-ADVISORY-PROOF.md).

The parent reconciliation stopped before cleanup when `git diff --check` found an extra blank line. A documentation-only correction also fixed the reported total from five to six tuples; lock hashes and tested code were unchanged. Scope, committed summary, artifact privacy, exact fixed versions and lock identities then passed. GSD manifest cleanup merged and removed only the completed worktree, with no scope warnings. The preserved candidate inventory and negative controls passed again on the merged candidate.

On merged source `61180e33c3b533565d16669657f68712782a0580`, the parent dependency fetch, strict compile and focused audit contracts all exited zero; lock hashes stayed identical. Fetch took 2.11s, compile 25.53s and focused contracts 69.72s. These are the post-merge integration checks, not the full canonical suite reserved for Plan 248-04. Wave schema/UI gates did not block; codebase drift was explicitly skipped because no STRUCTURE.md exists. The scheduled dependency-health receipt and issue #61 remain pending; no hosted run, issue mutation or publication occurred.

For subsequent dispatches, preserve full role/workflow guarantees while omitting an unconfigured duplicate role fallback payload. Supply the configured model/effort explicitly through the isolated CLI descriptor; the static baked-agent warning does not override those actual arguments. Reuse passing source-bound evidence after documentation-only edits rather than rerunning expensive checks solely for close-out timestamps. Plan 248-04's exact single repeat and single canonical run remain binding.

## Plan248-04 active verification gap

The isolated executor reproduced the two known missing-Playwright failures after a separately retained no-Mix-dependencies bootstrap failure. The new parsed-job setup regression went red on the original workflow; the pinned Node/npm repair passed it, then the same seed passed both real discovery checks after locked npm installation. Existing action-pin, workflow-parity, classifier and property-scale contracts passed. Independent source review found no defect in the frozen workflow/setup change.

The first local repeat invocation exited before ExUnit because the plan command omitted the existing job's `MIX_ENV=test`. The author treated that as not consuming an actual suite run and launched a corrected invocation before consuming the parent's recorded stop. The corrected run reached only its first suite iteration (376s), reported six failures and classified `broken`; it is not a nine-run receipt. Retain both invocations without retroactive acceptance. The no-further-entire-repeat stop is now explicit in the plan, continuation state and author handoff. The local command is corrected to pin MIX_ENV, but that edit grants no new run/window.

Observed failures include stale walkthrough anchors/counts, a dependency-health child timeout, denied temporary Git-worktree creation, npm cache permissions and a release-artifact contract that does not account for the approved imported brand tree. The canonical invocation stopped at formatting before later gates. These remain actual gaps until diagnosed and bounded affected proof establishes their repair; do not suppress tests, broadly relax timeouts or label environment errors passing. The walkthrough test is added to the plan's accounted files for the independently confirmed narrow correction. The parent continues safe in-scope work; no phase or additional plan is marked complete and no user acknowledgment is needed merely to preserve the stop.

Future bounded-run dispatches must preflight the required environment/prerequisites and formatting, count every invocation, and consume current stop/handoff state before a retry. An asynchronous final-review handoff alone is insufficient to enforce an immediate run limit; the executor must check it before launch/retry as well. This lesson adds no new routine approval gate.
