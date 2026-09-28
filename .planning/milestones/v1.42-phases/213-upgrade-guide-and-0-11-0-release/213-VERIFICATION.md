---
phase: 213-upgrade-guide-and-0-11-0-release
verified: 2026-09-26T00:00:00Z
status: passed
score: 3/3 must-haves verified (REL-03's release itself correctly classified maintainer-pending, not a gap)
covered_files:
  - ".planning/REQUIREMENTS.md"
  - ".planning/phases/213-upgrade-guide-and-0-11-0-release/213-01-PLAN.md"
  - ".planning/phases/213-upgrade-guide-and-0-11-0-release/213-01-SUMMARY.md"
  - ".planning/phases/213-upgrade-guide-and-0-11-0-release/213-02-PLAN.md"
  - ".planning/phases/213-upgrade-guide-and-0-11-0-release/213-02-SUMMARY.md"
  - ".planning/phases/213-upgrade-guide-and-0-11-0-release/213-03-PLAN.md"
  - ".planning/phases/213-upgrade-guide-and-0-11-0-release/213-03-SUMMARY.md"
  - ".planning/phases/213-upgrade-guide-and-0-11-0-release/213-CONTEXT.md"
  - ".planning/phases/213-upgrade-guide-and-0-11-0-release/213-PR-BODY.md"
  - ".planning/phases/213-upgrade-guide-and-0-11-0-release/213-REVIEW-FIX.md"
  - ".planning/phases/213-upgrade-guide-and-0-11-0-release/213-REVIEW.md"
  - ".planning/phases/213-upgrade-guide-and-0-11-0-release/213-VALIDATION.md"
  - "CHANGELOG.md"
  - "CONTRIBUTING.md"
  - "README.md"
  - "guides/getting-started-saas.md"
  - "guides/upgrade-path.md"
  - "guides/upgrading-to-0.11.md"
  - "mix.exs"
  - "test/support/legacy_trigger_sql.ex"
  - "test/threadline/changelog_contract_test.exs"
  - "test/threadline/guide_graph_contract_test.exs"
  - "test/threadline/public_surface_contract_test.exs"
  - "test/threadline/release_artifact_contract_test.exs"
  - "test/threadline/upgrade_backfill_test.exs"
  - "test/threadline/upgrade_path_doc_contract_test.exs"
  - "test/threadline/upgrade_rollback_test.exs"
  - "test/threadline/upgrading_to_0_11_doc_contract_test.exs"
  - "test/threadline/version_truth_doc_contract_test.exs"
covered_digest: "v1:sha256:9957b2d33a3321ddc952a08a03e7fceb6d5c22269a9199d89ef1243eac657ae8"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 213: Upgrade Guide and 0.11.0 Release Verification Report

**Phase Goal:** An adopter on 0.10.x can upgrade to 0.11.0 by following one guide, and 0.11.0 is published from a clean, green `main`
**Verified:** 2026-09-26
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria + REQUIREMENTS REL-02/REL-03)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | The upgrade guide covers regenerating triggers, adding the row-history index concurrently, opt-in backfill SQL for `{"id": null}` rows, states which pre-0.11 rows cannot be recovered, and the CHANGELOG carries a security note for shared-capture-function installs; doc-contract tests pin the regenerate/index steps | ✓ VERIFIED | `guides/upgrading-to-0.11.md` has all six marker-wrapped SQL blocks present (`threadline:backfill-sql:{start,end}`, `-composite:{start,end}`, `threadline:rollback-cleanup-sql:start`), a "What cannot be recovered" section (DELETE rows, masked/excluded key columns), and `CHANGELOG.md` has `### Security` under `## [0.11.0] - 2026-09-26` naming `shared_capture_function`, detection and fix. `mix test test/threadline/upgrading_to_0_11_doc_contract_test.exs test/threadline/changelog_contract_test.exs test/threadline/guide_graph_contract_test.exs` — all pass (rerun by verifier, not just SUMMARY claim) |
| 2 | The documented backfill SQL and upgrade steps run cleanly against a fixture seeded with 0.10.x rows, and `ecto.rollback --all` leaves no orphan capture functions and drops no foreign triggers | ✓ VERIFIED | `test/threadline/upgrade_backfill_test.exs` and `test/threadline/upgrade_rollback_test.exs` extract the guide's own SQL by literal marker and run it against real PostgreSQL fixtures (id-keyed, non-id, composite, shared-function pair, refused-type). Code review (213-REVIEW.md WR-01) caught that the shared-function fixture was built from the *current* renderer rather than a frozen 0.10.2 shape — a real fidelity gap in the proof's methodology — and it was fixed (213-REVIEW-FIX.md, commit `0fa38e63`, adding `LegacyTriggerSQL.v0_10_2_install_function_for_table/3` verbatim from `git show v0.10.2:...`). Rerun by verifier: `mix test test/threadline/upgrade_backfill_test.exs test/threadline/upgrade_rollback_test.exs` — pass (included in the 107-test run below) |
| 3 | The milestone lands on `main` as a squash with a clean conventional title, release-please proposes exactly `0.11.0` with phase-ID-free notes, `main` CI is green on the released SHA, no open PRs or stray branches remain — push/merge/publish wait for maintainer go | ✓ VERIFIED (local half) / maintainer-pending (publish half, correctly classified) | Local landing branch `land/v1.42` @ `244f580992a826b883c930b245b822a123835bc1` verified directly: `git rev-list --count origin/main..land/v1.42` = 1; `git diff --stat land/v1.42 milestone/v1.42 -- . ':!.planning'` = empty; `git diff --name-only origin/main land/v1.42 \| grep -c '^\.planning/'` = 0; commit message ID-free (grep for phase/decision/requirement ID patterns = no match); `git ls-remote --heads origin land/v1.42` = empty (never pushed). `mix ci.all` on it recorded green in 213-03-SUMMARY's "Post-review rebuild" note (not rerun per task instruction). The maintainer hand-off (213-03-SUMMARY, 10 ordered steps) consistently cites the rebuilt SHA `244f580992a826b883c930b245b822a123835bc1`, not the stale pre-review SHA. REL-03 correctly stays `[ ]`/Pending in REQUIREMENTS.md — push, PR, merge, release-please, and hex publish are maintainer-only per project rule (CLAUDE.md, PROJECT.md) |

**Score:** 3/3 truths verified (truth 3's release-publish half is maintainer-pending by design, not a gap)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `guides/upgrading-to-0.11.md` | 12-section upgrade guide with marker-wrapped SQL | ✓ VERIFIED | All 12 `##` headings present; all 6 markers present exactly once; registered in `mix.exs` ExDoc extras + Adopt regex |
| `test/threadline/upgrading_to_0_11_doc_contract_test.exs` | Pins headings, commands, markers, D-04 facts, vocabulary hygiene | ✓ VERIFIED | Exists, passes |
| `test/threadline/upgrade_backfill_test.exs` | Real-PG proof of guide's own SQL | ✓ VERIFIED | Exists, passes, fixed post-review to use frozen 0.10.2 fixture |
| `test/threadline/upgrade_rollback_test.exs` | Real-PG rollback-all catalog proof | ✓ VERIFIED | Exists, passes, fixed post-review to use frozen 0.10.2 fixture |
| `CHANGELOG.md` `### Security` | Security note under `[0.11.0]` | ✓ VERIFIED | Present, dated entry `## [0.11.0] - 2026-09-26` at line 29, `### Security` at line 40 |
| `guides/upgrade-path.md` | `0.10.x → 0.11.x` entry | ✓ VERIFIED | Present, linked to new guide |
| `land/v1.42` (local branch) | One ID-free squash commit, tree-equal to milestone outside `.planning/`, never pushed | ✓ VERIFIED | All checks reproduced directly by verifier (see Truth 3 evidence) |
| `.planning/phases/213-.../213-PR-BODY.md` | PR body for maintainer's `gh pr create --body-file` | ✓ VERIFIED | Exists, ID-free, ends with Claude Code attribution |

### Key Link Verification

| From | To | Via | Status |
|------|----|----|--------|
| `mix.exs` | `guides/upgrading-to-0.11.md` | docs extras + Adopt regex | ✓ WIRED (`grep -c` confirms both entries) |
| `guides/upgrade-path.md` | `guides/upgrading-to-0.11.md` | `0.10.x → 0.11.x` bullet link | ✓ WIRED |
| `test/threadline/upgrade_backfill_test.exs` | `guides/upgrading-to-0.11.md` | marker-based `File.read!` + `String.split` extraction (no hand-duplicated SQL) | ✓ WIRED — proof genuinely exercises the shipped guide text, not a copy |
| `213-03-SUMMARY.md` hand-off | `land/v1.42` @ `244f5809` | SHA cited in every push/PR/merge step | ✓ WIRED — verified the SHA in the hand-off matches the actual rebuilt branch head, not the stale pre-review SHA |

### Behavioral Spot-Checks / Rerun Tests (by verifier, not SUMMARY claims)

| Command | Result | Status |
|---------|--------|--------|
| `mix test test/threadline/upgrading_to_0_11_doc_contract_test.exs test/threadline/upgrade_backfill_test.exs test/threadline/upgrade_rollback_test.exs test/threadline/changelog_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/version_truth_doc_contract_test.exs test/threadline/guide_graph_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/public_surface_contract_test.exs` | `107 tests, 0 failures` | ✓ PASS |
| `mix release.pins --check` | `0 pin site(s) differ from the derived pin` | ✓ PASS |
| `MIX_ENV=dev mix docs --warnings-as-errors` | html/markdown/epub generated, no warnings | ✓ PASS |
| `git rev-list --count origin/main..land/v1.42` | `1` | ✓ PASS |
| `git diff --stat land/v1.42 milestone/v1.42 -- . ':!.planning'` | empty | ✓ PASS |
| `git diff --name-only origin/main land/v1.42 \| grep -c '^\.planning/'` | `0` | ✓ PASS |
| ID-pattern grep on `land/v1.42` commit message | no match (exit 1) | ✓ PASS |
| `git ls-remote --heads origin land/v1.42` | empty (never pushed) | ✓ PASS |

`mix ci.all` and the browser lane were NOT rerun by the verifier, per explicit task instruction — that result is accepted as already recorded green in 213-03-SUMMARY's "Post-review rebuild" section (rebuilt SHA `244f5809`, exit 0, 130+2207 tests/0 failures, Dialyzer 0 errors, browser 317 passed + 1 flaky/26 skipped/0 failed).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| REL-02 | 213-01, 213-02 | Upgrade guide with regenerate/index/backfill/unrecoverable-rows/security-note, doc-contract pinned | ✓ SATISFIED | REQUIREMENTS.md marked `[x]` Complete; verified directly above |
| REL-03 | 213-03 | 0.11.0 released via release-please from squash-landed PR, `main` CI green, no stray branches/PRs | classified maintainer-pending, correctly so | Local preparation (landing branch, gates, hand-off) complete and verified; the publish action itself is explicitly maintainer-only per CLAUDE.md/PROJECT.md "Zero human verification by default... Hand the maintainer only secrets, spend, push/publish, and scope decisions." REQUIREMENTS.md correctly shows `[ ]` Pending, not silently marked done |

No orphaned requirements found for Phase 213 (only REL-02/REL-03 map to it).

### Anti-Patterns Found

None found in the reviewed phase files. Grep for `TBD|FIXME|XXX` in shipped guide/CHANGELOG files returned nothing. The phase's own code review (213-REVIEW.md) found 0 critical, 2 warning (WR-01, WR-02), 2 info issues — both warnings were fixed (213-REVIEW-FIX.md, commits `0fa38e63` and `d538f708`) and reverified by rerunning the affected test files; the 2 info items are optional prose-clarity suggestions, correctly left as non-blocking.

### Human Verification Required

None. All must-haves are verified programmatically or correctly classified as maintainer-pending (a scope/push/publish decision, not a verification gap, per project's zero-human-verification-by-default rule).

### Gaps Summary

No gaps. REL-02 is fully verified with real-PG proof (methodology gap caught and fixed during code review, not a hidden defect). REL-03's release-publish action is legitimately deferred to the maintainer; the local preparation for it (landing branch, gate table, ordered hand-off with the correct rebuilt SHA) is complete and independently verified.

---

_Verified: 2026-09-26_
_Verifier: Claude (gsd-verifier)_

## Release record (post-verification, 2026-09-26)

| Step | Evidence |
|------|----------|
| Landing PR | #52 squash-merged at head `7b3dfe63` → `b0668e6d` (`feat!: capture every primary-key shape, read it back exactly, and detect broken capture (#52)`). First CI round red on `upgrade_rollback_test.exs` (unqualified capture-function ref masked locally by a stale `public.threadline_capture_changes()`); fixed in `e87add68`, reproduced and verified locally, then 16/16 checks green. |
| Release PR | #53 `chore(main): release 0.11.0` — no planning IDs in diff, 16/16 green, merged → `8312290d` |
| Publish | Release run `36257162356`: CI verified on release SHA, `production-hex` (env id 20753768806) approved by the maintainer, Publish to Hex.pm + smoke-from-hex.pm + distribution sync all success; `mix hex.info threadline` → `~> 0.11.0` |
| Distribution sync | #54 merged → `5e78b2f0` |
| main CI | All workflows (CI, Browser full project set, Release, Branch/Environment Protection, Community Health) success on both `8312290d` and `5e78b2f0`; 0 open PRs |
| Stray branches | Deleted with maintainer go (2026-09-26): remote `land/v1.42`, `release/sync-0.10.2-36085532676`, `release/sync-0.11.0-36257162356`, `release-please--branches--main`; local `land/v1.41`, `land/v1.42`; origin now has only `main` |
