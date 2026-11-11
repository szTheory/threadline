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
