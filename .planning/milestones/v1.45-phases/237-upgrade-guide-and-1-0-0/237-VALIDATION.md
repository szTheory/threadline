---
phase: "237"
slug: "upgrade-guide-and-1-0-0"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-07"
---

# Phase 237 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on the repository's Elixir/Mix toolchain |
| **Config file** | `mix.exs`, `config/test.exs`, and `test/partition_weights.txt` |
| **Quick run command** | `mix verify.test test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/guide_graph_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/changelog_contract_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | Focused contracts: 0.6 seconds (50 tests); docs: 2 seconds. Full `mix ci.all` takes several minutes and passed in candidate and post-merge CI. |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.format` and the focused contract test(s) changed by that task.
- **After every plan wave:** Run `mix ci.all` after source, weight, and documentation changes are integrated.
- **Before `$gsd-verify-work`:** Run the committed-candidate `mix verify.bump_rehearsal`, then `mix ci.all`.
- **Max feedback latency:** 30 seconds for a focused contract; use the smallest affected test file during implementation.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 237-01-01 | 01 | 1 | DOCS-03, REL-02 | T-237-01 | Separate scoped IDs and rendered guide expose every adopter action | guide and graph contracts + ExDoc | `mix verify.test test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/guide_graph_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/changelog_contract_test.exs`; `MIX_ENV=dev mix docs --warnings-as-errors` | ✅ existing | ✅ green — 50 tests, 0 failures; ExDoc generated without warnings |
| 237-01-02 | 01 | 1 | DOCS-03 | T-237-01 | Missing, extra, duplicate, and cross-scope IDs fail; weighted test inventory stays complete | contract mutation controls | `mix verify.test test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/ci_topology_contract_test.exs` | ✅ existing | ✅ green — mutation and partition controls pass; included in 50-test run |
| 237-02-01 | 02 | 1 | REL-01 | T-237-03 | Strict candidate mode requires feat!, one 1.0.0 footer, and config false | script syntax + changelog config contract | `bash -n bin/verify-bump-rehearsal`; `mix verify.test test/threadline/changelog_contract_test.exs` | ✅ existing | ✅ green — syntax passed; plan run: 9 contract tests, 0 failures; also included in current 50-test run |
| 237-02-02 | 02 | 1 | REL-01 | T-237-03 | Candidate parser rejects missing, duplicate, malformed, and 0.13.0 footers; ordinary CI remains runnable | focused topology contract | `mix verify.test test/threadline/ci_topology_contract_test.exs test/threadline/changelog_contract_test.exs`; `mix verify.format` | ✅ existing | ✅ green — plan run: 35 tests, 0 failures; format passed; current combined run also green |
| 237-03-01 | 03 | 2 | REL-02 | T-237-05 | Exact v1.44-to-source-tip audit maps every BREAKING CHANGE footer to a human 1.0 entry and guide ID | exact git-history audit + guide contract | `git log 4ae4557ddde83d70eb1781db984cb287dfa18b1b..6227ad959d30b62f08b957ecc50b146ce4fdf62c --grep='BREAKING CHANGE' --format='%H %B'`; `mix verify.test test/threadline/upgrading_to_1_0_doc_contract_test.exs` | ✅ existing | ✅ green — 11 commits / 12 consequences reconciled in [237-VERIFICATION.md](237-VERIFICATION.md); exact-range command rerun; contract green |
| 237-03-02 | 03 | 2 | REL-01, REL-03 | T-237-05 | Candidate-bound artifact rehearsal and full CI pass; PG15/latest pins checked | local artifact rehearsal + CI | `THREADLINE_BUMP_REHEARSAL_MODE=candidate mix verify.bump_rehearsal`; `DB_HOST=localhost DB_PORT=55432 mix ci.all` | ✅ existing | ✅ green — candidate SHA `81041db9ca31c12c0114ea5a4998106c9e0aae61` passed rehearsal and local CI; exact-SHA remote CI and post-merge CI `37706469417` also passed; see [237-VERIFICATION.md](237-VERIFICATION.md) |
| 237-04-01 | 04 | 3 | REL-03 | T-237-07 | Candidate-specific grant precedes push; PR head matches granted SHA and targets main | live PR SHA inspection | `gh pr view #78` (recorded PR/head/base in [237-VERIFICATION.md](237-VERIFICATION.md)); candidate CI run `37704307895` | ✅ existing | ✅ green — PR #78 used granted SHA `81041db9ca31c12c0114ea5a4998106c9e0aae61`; exact-head PR CI passed |
| 237-04-02 | 04 | 3 | REL-03 | T-237-08 | Separate grant precedes milestone merge; required CI and live Release Please PR are observed | live PR and workflow inspection | `gh pr view #78`; `gh run list -R szTheory/threadline --workflow release.yml --limit 10` (recorded in [237-VERIFICATION.md](237-VERIFICATION.md)) | ✅ existing | ✅ green — PR #78 merged as `371ce3acfa753ea5747f9478ef1bdcfa92c226f3`; CI passed and release run `37705046334` created PR #79 |
| 237-05-01 | 05 | 4 | REL-03 | T-237-09 | Fresh Release PR merge grant produces v1.0.0 tag and successful release CI gate | live release inspection | `gh release view v1.0.0 -R szTheory/threadline --json tagName,targetCommitish,url`; release workflow `37706469316`; CI `37706469417` | ✅ existing | ✅ green — `v1.0.0` targets `f815e589c954a8e3983bc6f73b21c9e3304d6aa4`; post-merge CI and `gate-ci-green` passed |
| 237-05-02 | 05 | 4 | REL-03 | T-237-10 | Distinct production-hex grant precedes public Hex 1.0.0 evidence | Hex registry and workflow inspection | `curl -fsSL https://hex.pm/api/packages/threadline | jq -e 'any(.releases[]; .version == "1.0.0")'`; release workflow `37706469316` | ✅ existing | ✅ green — protected publish, post-publish smoke test, distribution sync, and public Hex 1.0.0 are recorded in [237-VERIFICATION.md](237-VERIFICATION.md) |

---

## Wave 0 Requirements

Complete. The guide/change-map contract, mutation controls, partition-weight row, and candidate rehearsal controls were implemented in Plans 237-01/02. Their files exist, focused tests pass, and candidate artifact rehearsal passed at the recorded candidate SHA.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Push the candidate and merge milestone PR #78 | REL-03 | Completed external actions required separate maintainer grants; authorization itself is not a software behavior test. | Grants, exact candidate/merge SHAs, green CI, and Release Please run are recorded in [237-VERIFICATION.md](237-VERIFICATION.md). |
| Merge generated Release PR #79 and approve protected `production-hex` | REL-03 | Completed external actions required separate grants and protected-environment approval. | Grant, tag/release SHA, successful `gate-ci-green`, publish job, and public Hex 1.0.0 are recorded in [237-VERIFICATION.md](237-VERIFICATION.md). |
| Merge generated distribution-sync PR #80 | Outside phase requirements | PR #80 is an open post-publish docs follow-up; it has no merge grant and is explicitly outside Phase 237 completion. | Leave it open and unmerged in this validation. Recheck its CI and obtain its own merge decision if that follow-up is taken up. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s for focused checks (50 tests in 0.6s; docs in 2s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-10-08
