---
phase: 244-release-flow
plan: 02
subsystem: release
tags: [release-please, changelog, rehearsal, docs, bash, perl]
status: complete

requires:
  - "244-01: bin/date-release-changelog and the sync-job dating step"
provides:
  - "bin/verify-bump-rehearsal runs the production bin/date-release-changelog after the CHANGELOG-GENERATED.md simulation"
  - "CONTRIBUTING.md Ongoing releases: landing-PR prose, sync-job dating, loud placeholder-only failure, always-update regeneration"
  - "CHANGELOG.md header and release.yml sync-job comment name the release workflow as the renamer"
affects: [244-07, release-flow]

actuals:
  tokens: 2600
  tasks: 2
  commits: 2
plan_head_before: e89efba5732101e97e474f0377a3a795987995e3
plan_head_after: 8da12920dc82c7a226d705508b950df5a7ec177b

tech-stack:
  added: []
  patterns:
    - "rehearsal stands in only for human prose; the dating is the production script, called in release order"
    - "same placeholder-only test as bin/date-release-changelog (perl -CSD, em dash as \\x{2014})"

key-files:
  created: []
  modified:
    - bin/verify-bump-rehearsal
    - CONTRIBUTING.md
    - CHANGELOG.md
    - .github/workflows/release.yml

decisions:
  - "Rehearsal seeds stand-in prose only when no [NEXT] heading exists AND the Unreleased block is placeholder-only; real prose is left alone and dated as-is"
  - "Seed regex tolerates an empty block as well as the standing placeholder, so the seed cannot silently no-op"

metrics:
  duration: "~15 min"
  completed: 2026-10-25
---

# Phase 244 Plan 02: Rehearsal parity and release-flow docs Summary

`mix verify.bump_rehearsal` now dates CHANGELOG.md the way the release branch does. It runs the real `bin/date-release-changelog` after release-please's CHANGELOG-GENERATED.md entry is simulated, so it no longer makes up a dated heading. The contributor docs now say who dates the changelog and how a stale Release PR gets refreshed.

## What changed

- **bin/verify-bump-rehearsal**
  - Step A (in the old stand-in's place): if there is no `## [NEXT]` heading and the `## Unreleased — highlights` block is placeholder-only, it seeds disclosed stand-in prose (highlights line, `### Breaking changes` None, `### Added` bullet) and prints the `(rehearsal-only ...)` line. If real prose is already there, it seeds nothing and says so.
  - Step B (after the CHANGELOG-GENERATED.md simulation): runs `"$ROOT/bin/date-release-changelog" --root "$CLONE"`, fails with `fail "changelog"` on a non-zero exit, then keeps the `^## \[NEXT\] - ` self-check.
  - The header comment ("THE TWO STAND-INS") now describes this flow and says the dating is not simulated.
- **CONTRIBUTING.md "Ongoing releases" step 1**: three new sub-bullets.
  - The landing PR carries the prose plus the upgrade-path row.
  - `sync-release-pr-pins` dates the block. The date is the UTC day of the last regeneration, which can come before the merge day.
  - A placeholder-only block makes the job fail loudly.
  - A non-releasable merge regenerates the open Release PR (`always-update`, RELEASE_PLEASE_TOKEN PAT), with no hand rebase and no branch delete.
- **CHANGELOG.md header comment**: one added sentence saying the release workflow, not release-please, renames the Unreleased block. "release-please has no write access to it" is unchanged, and so is the standing block.
- **.github/workflows/release.yml**: comment-only. The sync job header now covers the CHANGELOG dating and why it must re-run on every regeneration (the force-push drops the earlier dating commit).

## Verification

- `bash -n bin/verify-bump-rehearsal` passes. The date-release-changelog call comes after the generated-changelog simulation line.
- `mix test test/threadline/date_release_changelog_test.exs`: 21 tests, 0 failures.
- The six doc/release contract files (changelog, version_truth_doc, upgrading_to_1_0_doc, guides/upgrade_path, release_distribution_doc, release_control_plane): 52 tests, 0 failures.
- Wave gate: `mix verify.bump_rehearsal` from a plain `git clone --no-local` under `<scratch>/` at 8da12920 exited 0. Its output included `seeding stand-in release prose ...` and `date-release-changelog: dated [1.2.0] - 2026-10-25`. It reported "Bump rehearsal OK" and "tree identity: MATCH".
- `mix verify.format` and `mix verify.credo` (no issues) are clean, and `bin/verify-repo-hygiene` is clean.
- Acceptance greps:
  - `bin/date-release-changelog` appears 8 times in the rehearsal (baseline 0), and the old stand-in step line appears 0 times.
  - In CONTRIBUTING.md, `sync-release-pr-pins` appears 2 times (baseline 0) and `always-update` once.
  - The standing CHANGELOG heading appears once, and so does the no-write-access sentence.
  - Every changed line in release.yml is a comment.

## Deviations from Plan

None. The plan was executed as written. One small hardening, within Task 1's scope: the seed regex matches an empty Unreleased block as well as the placeholder line, so the seed's self-check cannot fail for a reason the rehearsal invented.

## Known Stubs

None. The rehearsal stand-in prose is disclosed and rehearsal-only by design (D-1).

## Requirements

REL-01 and REL-02 are **not** marked complete. The orchestrator holds them pending until plan 244-07's live proof.

## Self-Check: PASSED

- FOUND: bin/verify-bump-rehearsal, CONTRIBUTING.md, CHANGELOG.md, .github/workflows/release.yml
- FOUND: d4a94d46, 8da12920 (ancestors of HEAD)
