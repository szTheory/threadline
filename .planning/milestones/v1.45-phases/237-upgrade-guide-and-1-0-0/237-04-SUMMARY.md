---
phase: 237-upgrade-guide-and-1-0-0
plan: 04
subsystem: release
tags: [release-please, candidate, ci, hex]
requires:
  - phase: 237-upgrade-guide-and-1-0-0
    provides: Verified 1.0.0 candidate and local release rehearsal
provides:
  - Candidate-specific push and green PR CI evidence
  - One-squash 1.0 API-contract landing on main under conditional grant
  - Live Release Please 1.0.0 PR and workflow evidence
affects: [release, changelog, hex]
tech-stack:
  added: []
  patterns: [candidate-SHA grants, PR-head CI gate, separately granted squash merge]
key-files:
  created:
    - .planning/phases/237-upgrade-guide-and-1-0-0/237-04-SUMMARY.md
  modified:
    - .planning/phases/237-upgrade-guide-and-1-0-0/237-VERIFICATION.md
    - .planning/STATE.md
    - .planning/ROADMAP.md
external-results:
  candidate_sha: 81041db9ca31c12c0114ea5a4998106c9e0aae61
  candidate_ci: https://github.com/szTheory/threadline/actions/runs/37704307895
  merged_pr: https://github.com/szTheory/threadline/pull/78
  main_sha: 371ce3acfa753ea5747f9478ef1bdcfa92c226f3
  release_workflow: https://github.com/szTheory/threadline/actions/runs/37705046334
  release_pr: https://github.com/szTheory/threadline/pull/79
---

# Plan 237-04 Summary

The revised candidate was pushed only after the maintainer's scoped SHA-specific grant. GitHub kept PR #77 pinned to the old head after the branch force-push and refused reopening it with HTTP 422, so the maintainer authorized a replacement PR. PR #78 opened on the exact candidate SHA and passed its PR-triggered CI run, including the `CI required` aggregate, minimum PostgreSQL 15 lane, pinned latest lane, package evaluator, Dialyzer, capture evidence, and browser E2E.

After the maintainer conditionally authorized a squash merge if PR #78's own CI passed, it was merged as one commit: `371ce3acfa753ea5747f9478ef1bdcfa92c226f3`, subject `feat!: land Threadline 1.0 API contract`, with exactly one `Release-As: 1.0.0` footer. Canonical `main` still matched the candidate's recorded parent immediately before merge.

Release Please workflow `37705046334` then completed successfully, synchronized the release install pins, and opened PR #79 titled `chore(main): release 1.0.0`. Its current head is `5132b55f13025594a0385ef54819ffeee9ff1c14`; PR-triggered CI run `37705157832` is in progress. The Release workflow's `Publish to Hex.pm` job was skipped on the milestone merge, as expected before the generated Release PR is merged.

## Remaining gated work

Plan 237-05 owns the generated Release PR merge and protected production-Hex publication. PR #79's exact current head passed required CI and its release diff was reviewed; merging it still needs a distinct explicit maintainer grant. Protected production-Hex publication needs another grant. No release PR merge, tag, or package publication occurred in this plan.

## Self-check

- PR #78 is merged, and its main commit has the required conventional breaking subject and a single target-version footer.
- PR #79 is open with the generated 1.0.0 manifest, changelog, and synchronized package pins; exact-head required CI passed in run 37705157832.
- `.planning/STATE.md`, `.planning/ROADMAP.md`, and `237-VERIFICATION.md` record the observed SHAs and live run/PR URLs.
