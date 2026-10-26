# 244 REL-02 Evidence: observed release-PR refresh

Status: pending — bound to the first natural release cycle after this phase lands; no throwaway release (maintainer rule)

Recorded: 2026-10-25, by plan 244-07 (agent-run, read-only `gh`).
Closed by: the milestone close audit (v1.47) or the next phase's verifier. Whoever closes it re-runs the commands in section 3 once the trigger condition in section 2 holds, then rewrites the `Status:` line to `observed — release run <id>, CI run <id>, head <sha>`.

## 1. Claim under test

Phase 244 success criterion 2 (REL-02): when a non-releasable merge leaves an open release PR behind main (release-please reports it unchanged), the release workflow rebases it with a CI-triggering token, and fresh CI runs with no human action.

The contract half is proven in 244-01 (release.yml carries `always-update`, the sync job keys on `prs_created`, and the push uses the CI-triggering token). This file covers the observed-run half.

## 2. Trigger condition

All three must hold, in this order:

1. Phase 244 has landed on `main` (the `always-update` release-please config is live).
2. A release PR is open on `release-please--branches--main` (a releasable `feat:`/`fix:`/`perf:`/`deps:` change has landed after 244).
3. A non-releasable merge (`ci:`, `docs:`, `test:` or `chore:`) lands on `main` while that release PR is still open.

No throwaway release, `fix:` commit, push, merge, branch delete or workflow dispatch is made to produce this condition. It arises from normal work only.

## 3. Read-only commands

Run from the repository root with an authenticated `gh`. None of these mutate anything. Do not wrap them in retry or wait loops.

```bash
# a. The open release PR and its current head
gh pr list --head release-please--branches--main --state open --json number,headRefOid,updatedAt

# b. Recent release.yml runs on main; pick the run whose headSha is the non-releasable merge
gh run list --workflow release.yml --branch main --limit 10 --json databaseId,headSha,event,conclusion,createdAt

# c. That run must not report the release PR as unchanged (expect 0)
gh run view <release-run-id> --log | grep -c 'remained the same'

# d. Job conclusions for that run (expect `Sync install pins on Release PR` = success, not skipped)
gh run view <release-run-id> --json jobs --jq '.jobs[] | {name, conclusion}'

# e. pull_request CI runs on the release branch; one must be on the PR's new head SHA
gh run list --workflow ci.yml --branch release-please--branches--main --event pull_request --limit 5 --json databaseId,headSha,conclusion,createdAt
```

## 4. Pass conditions

REL-02 is observed when, for the release.yml run triggered by the non-releasable merge:

- command c prints `0`: no `remained the same` line for the release PR;
- command d shows `Sync install pins on Release PR` with conclusion `success` (it ran, it was not skipped);
- the release PR's `headRefOid` (command a, re-run after the merge) differs from its head before the merge;
- command e lists a `pull_request` ci.yml run whose `headSha` equals that new head;
- nobody acted by hand between the merge and that CI run (no manual dispatch, no manual push to the release branch). `Bootstrap CI on Release PR` dispatches only when `RELEASE_PLEASE_TOKEN` is absent, so with the PAT configured its dispatch step must not have fired either.

## 5. Concurrency note

ci.yml cancels in-progress runs per concurrency group. The release-please force-push and the pin-sync push can each produce a head, so the first CI run on an intermediate head may show `cancelled`. Only the run on the PR's final head counts (244-RESEARCH.md Pitfall 5). A cancelled run on an earlier head is not a failure.

## 6. Fallback if `prs_created` is false on a refresh (assumption A1)

The sync job is gated on `needs.release-please.outputs.prs_created == 'true'`. 244-RESEARCH.md assumes release-please sets `prs_created` when `always-update` force-pushes an existing PR. If the observed run shows the PR head changed but the sync job `skipped`, A1 is false. The fix is a follow-up phase item: key the sync job on an open-release-PR check (for example a step that runs command a and outputs whether a PR exists) instead of `prs_created`. Do not patch it inside the observation.

## 7. Status

Status: pending — bound to the first natural release cycle after this phase lands; no throwaway release (maintainer rule)

Snapshot taken 2026-10-25 while recording this file (phase 244 not yet landed on `main`):

- Command a returned `[]`: no release PR is open on `release-please--branches--main`.
- Command b returned 10 release.yml runs, all `event: push`, all `conclusion: success`. The newest is run 40139774747 (head 23178fb0, 2026-10-24T22:43Z), then 40107416573 (head 07610840, 2026-10-24T15:32Z) and 40056037558 (head c846ddce, 2026-10-24T02:53Z). None of them runs the phase 244 release.yml, so none can serve as the observation.

The trigger condition (section 2) is therefore not met. That is the expected outcome for this plan, not a failure.

## 8. Maintainer-owned items

- **Q2: `RELEASE_PLEASE_TOKEN` expiry.** The secret is a fine-grained PAT. `gh secret list` shows it was last updated 2026-05-28T15:14:58Z. Fine-grained PATs usually carry an expiry date, and agents cannot read it. An expired PAT fails loudly at the release-please step (see the ECON-03 comment above the `Bootstrap CI on Release PR` job in release.yml), so `prs_created` comes back false and the risk is a visible red run, not a silently stale release PR. Action: check the expiry date in the GitHub token settings, record it here, and rotate the PAT before it lapses.
