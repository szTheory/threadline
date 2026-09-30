---
phase: 223-close-v1-43-audit-debt
verified: 2026-09-30T02:15:00Z
status: passed
score: 4/4 must-haves verified
covered_files: [".github/workflows/release.yml", ".planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md", ".planning/phases/223-close-v1-43-audit-debt/223-01-PLAN.md", ".planning/phases/223-close-v1-43-audit-debt/223-01-SUMMARY.md", ".planning/phases/223-close-v1-43-audit-debt/223-02-PLAN.md", ".planning/phases/223-close-v1-43-audit-debt/223-02-SUMMARY.md", ".planning/phases/223-close-v1-43-audit-debt/223-03-PLAN.md", ".planning/phases/223-close-v1-43-audit-debt/223-03-SUMMARY.md", ".planning/phases/223-close-v1-43-audit-debt/223-04-PLAN.md", ".planning/phases/223-close-v1-43-audit-debt/223-04-SUMMARY.md", ".planning/phases/223-close-v1-43-audit-debt/223-05-PLAN.md", ".planning/phases/223-close-v1-43-audit-debt/223-05-SUMMARY.md", ".planning/phases/223-close-v1-43-audit-debt/223-06-PLAN.md", ".planning/phases/223-close-v1-43-audit-debt/223-06-SUMMARY.md", ".planning/phases/223-close-v1-43-audit-debt/223-CONTEXT.md", ".planning/phases/223-close-v1-43-audit-debt/223-REVIEW-DISPOSITION.md", ".planning/phases/223-close-v1-43-audit-debt/223-REVIEW.md", "CONTRIBUTING.md", "bin/verify-repo-hygiene", "test/threadline/release_control_plane_contract_test.exs", "test/threadline/repo_hygiene_contract_test.exs", "test/threadline/repo_hygiene_guard_test.exs"]
covered_digest: "v2:sha256:e3f220e329983296e73fd06373dde720d9e9dc1e53471d7c78e9ecec21cefa52"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 223: Close v1.43 Audit Debt Verification Report

**Phase Goal:** The v1.43 audit's decision items are closed: the mint 1.11.0 advisory fix ships in a patch release, the release checkouts stop persisting credentials, and every phase-217 round-2 review finding has a recorded disposition.
**Verified:** 2026-09-30T02:15:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP Success Criterion) | Status | Evidence |
|---|---------|------------|----------|
| 1 | The mint 1.11.0 fix on `main` becomes releasable via a `BEGIN_COMMIT_OVERRIDE fix(deps):` line on merged PR #60, release-please opens a patch release PR, and the release runbook is followed through publish (maintainer push, merge, `production-hex` approval) | ✓ VERIFIED | `gh pr view 60 --json body` shows the byte-verbatim override block (`fix(deps): update mint to 1.11.0...` / `ci: repo hygiene, CI economy...`). `gh pr view 67` (`chore(main): release 0.11.2`) state MERGED, mergeCommit `4d7661b9`. `gh release view v0.11.2` → tagName `v0.11.2`, publishedAt `2026-09-30T01:17:31Z`. `curl https://hex.pm/api/packages/threadline/releases/0.11.2` → version `0.11.2`, live on Hex. Production-hex approval was submitted by the orchestrator under the maintainer's explicit in-session grant ("nice yeah u can publish if CI green i authorize u", recorded in 223-06-SUMMARY) — treated per this task's explicit instruction as satisfying the runbook's approval step. |
| 2 | Every target-ref `actions/checkout` in `release.yml` followed by `mix` (`publish-hex`, `smoke-published`) sets `persist-credentials: false`, and a release-control-plane contract test with a mutation control fails when any such checkout omits it (216 CR-01 closed) | ✓ VERIFIED | `git show origin/main:.github/workflows/release.yml` has 7 `persist-credentials: false` lines including the `publish-hex` (~:476) and `smoke-published` (~:644) target checkouts. `release_control_plane_contract_test.exs`'s `mutation controls (D-11)` block contains two real, non-vacuous strip controls — "strip the flag from the publish-hex target checkout" and "strip the flag from the smoke-published target checkout" — each of which mutates the live workflow text, asserts the anchor is unique, asserts the mutation changed the input, and asserts `rule_fired?(persisted_checkout_errors(mutated), "checkout-credential-free")`. Confirmed by direct read of the test file (lines ~284-334). The one WR-01 review finding concerns a *different*, separately-flagged "positive control" test (adding the flag to the allowlisted `dispatch-bootstrap` job), which is vacuous by construction — it does not touch or weaken the publish-hex/smoke-published strip controls that this success criterion actually requires; see Anti-Patterns/Advisory below. |
| 3 | `217-REVIEW-DISPOSITION.md` has no `open` row: R2-WR-04 fixed, R2-WR-01..03 and R2-IN-01..02 each fixed or deferred with a reason | ✓ VERIFIED | `.planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md` frontmatter: `open: 0`, `total: 11`. All 11 rows (`R1-*` and `R2-*`) show `disposition: fixed` with a `223-0N Task N <sha>` Source citation for each `R2-*` row. `grep -c '| open |'` on the file returns 0. |
| 4 | `mix ci.all` and `bin/verify-repo-hygiene` stay green | ✓ VERIFIED | Task-supplied evidence: `mix test` 2573 tests/0 failures; `mix ci.all` exit 0 at `3d2c555e` (no non-`.planning` changes since — confirmed via `git log` showing only `docs(223):` commits after that point). Independently re-ran in this verification: `bin/verify-repo-hygiene` → `4249 tracked text file(s) clean; 8 allowlist entries used, 0 inert`; `bin/verify-repo-hygiene --self-test` → `ok (10 cases)`. |

**Score:** 4/4 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.github/workflows/release.yml` | `persist-credentials: false` on release-please/publish-hex/smoke-published checkouts | ✓ VERIFIED | 7 occurrences confirmed live on `origin/main`, including both target-ref checkouts named in SC-2 |
| `test/threadline/release_control_plane_contract_test.exs` | Per-step contract + 6 mutation controls (D-11) | ✓ VERIFIED | 5 firing controls + 1 positive control present; the 2 controls relevant to SC-2 (publish-hex, smoke-published strips) are real and non-vacuous |
| `bin/verify-repo-hygiene` | R2-WR-01/02/03/04 fixes (`literal_too_broad`, left-anchored family 6, newline pre-scan, anchored family 8) | ✓ VERIFIED | `--self-test` reports `ok (10 cases)`; live tree scan clean |
| `.planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md` | `open: 0`, all rows fixed/deferred | ✓ VERIFIED | `open: 0`, `total: 11`, 0 `| open |` rows |
| PR #60 body | `BEGIN_COMMIT_OVERRIDE` block, D-01 verbatim | ✓ VERIFIED | Confirmed via `gh pr view 60 --json body` |
| PR #67 (`chore(main): release 0.11.2`) | Merged, produced 0.11.2 | ✓ VERIFIED | `gh pr view 67` state MERGED |
| GitHub release `v0.11.2` / Hex release `0.11.2` | Live | ✓ VERIFIED | `gh release view`, `curl hex.pm` both confirm |
| PR #69 (distribution-sync) | Merged | ✓ VERIFIED | `gh pr view 69` state MERGED |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `release_control_plane_contract_test.exs` mutation controls | `.github/workflows/release.yml` live text | `release_workflow()` reads the file, `persisted_checkout_errors/1` inspects it | WIRED | Confirmed by reading the test source; mutation controls operate on the actual file's text, not a fixture copy |
| PR #60 override block | release-please parsing | release-please reads merged-PR body for `BEGIN_COMMIT_OVERRIDE` | WIRED | PR #67 (`chore(main): release 0.11.2`) exists with no `### Features` section and cites the mint commit — the override was correctly parsed |
| Release workflow `production-hex` gate | `publish-hex` job | GitHub Environments pending-deployment approval | WIRED | Release run `36654382663`: `Publish to Hex.pm`, `Smoke test the published release`, `Post-publish distribution sync` all `success` |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SUP-01 | 223-04/05/06 | `mix hex.audit` clean for root/example/bench lockfiles | ✓ SATISFIED | Already Complete as of Phase 215; re-confirmed clean by `mix ci.all` exit 0 in this phase; phase 223 introduces no new lockfile changes that would regress it |
| HYG-02 | 223-02/03 | CI fails a PR with a machine-local path via `bin/verify-repo-hygiene` | ✓ SATISFIED | Already Complete as of Phase 217; strengthened (not weakened) by 223-02's R2 fixes; guard still green |

No orphaned requirements: ROADMAP declares "Requirements: none new" for Phase 223, and REQUIREMENTS.md maps no additional IDs to phase 223.

### Anti-Patterns / Advisory Findings (from 223-REVIEW.md)

223's own code review found 0 critical / 5 warning / 1 info, all recorded `open` in `223-REVIEW-DISPOSITION.md`. Per this task's explicit scoping instruction, these are reported as advisory (safety-net/test-quality gaps in the phase's own verification tooling, not gaps in the shipped behavior) and do not falsify any success criterion, with SC-2 specifically re-checked below.

| Finding | Severity | Disposition | Falsifies an SC? |
|---------|----------|-------------|-------------------|
| WR-01: vacuous "positive control" (adding the flag to `dispatch-bootstrap`'s checkout stays green) | warning | open | No — this is a distinct test from the publish-hex/smoke-published *strip* controls SC-2 requires. Verified directly: those two strip controls are real and fire `checkout-credential-free` on mutation (see Truth #2 above). |
| WR-02: `mix_invocation?/1` has gaps for some shell wrapper idioms (`timeout`, `sudo`, `nohup`, case-branch `)`) | warning | open | No — none of these wrappers exist in the live `dispatch-bootstrap`/`distribution-sync` jobs today; this is a coverage gap in future-regression protection, not a present gap in SC-2's stated behavior |
| WR-03: `allowlisted-job-runs-no-mix` can't see into the externally-invoked `bin/post-publish-distribution-sync` script | warning | open | No — the script is confirmed mix-free today (shells to `python3` only); this is a blind spot in the safety net, not a violation of SC-2 |
| WR-04: `literal_too_broad` guard-test coverage misses 3 of 9 documented roots | warning | open | No — affects test coverage for a phase-217 concern, not any Phase-223 SC directly |
| WR-05: `newline_status` capture ignores a `git ls-files` pipeline failure | warning | open | No — narrow fail-open edge case unrelated to the four SCs |
| IN-01: D-18/D-06 CONTRIBUTING wording changes have no contract test | info | open | No — explicitly out of scope per 223-CONTEXT D-06/D-18 |

These are legitimate follow-up items for a future phase but are correctly out of scope for Phase 223 closure per the phase's own review-disposition and this verification's task scope.

## Human Verification Required

None. All four success criteria are independently confirmed against live GitHub/Hex.pm state and the local codebase; no behavior-dependent truth lacks test/live evidence.

## Gaps Summary

None. All four ROADMAP success criteria for Phase 223 are verified true:

1. The mint 1.11.0 fix is live as threadline 0.11.2 on both GitHub and Hex.pm, published through the maintainer-authorized runbook sequence.
2. `release.yml`'s `publish-hex` and `smoke-published` target-ref checkouts both set `persist-credentials: false`, backed by real (non-vacuous) mutation controls in the contract test that fire when either flag is stripped.
3. `217-REVIEW-DISPOSITION.md` has 0 open rows across all 11 findings.
4. `mix ci.all` and `bin/verify-repo-hygiene` are both green, confirmed both by task-supplied evidence at commit `3d2c555e` and by this verification's independent re-run of `bin/verify-repo-hygiene`.

Phase 223's own code review found 5 warning / 1 info findings, all left `open` in `223-REVIEW-DISPOSITION.md`. These concern gaps in the safety net's own test coverage (future-regression protection) rather than gaps in what was shipped, and none falsifies a success criterion — including WR-01, which was specifically checked against SC-2 and found to concern an unrelated, separately-vacuous test.

---

_Verified: 2026-09-30T02:15:00Z_
_Verifier: Claude (gsd-verifier)_
