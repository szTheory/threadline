---
phase: "237"
slug: "upgrade-guide-and-1-0-0"
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Quick run command** | `mix test test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/guide_graph_contract_test.exs test/threadline/ci_topology_contract_test.exs` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | Focused contract tests target <30 seconds; measure during execution. `mix ci.all` is a full local CI run and may take several minutes. |

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
| 237-01-01 | 01 | 1 | DOCS-03, REL-02 | T-237-01 | Separate scoped IDs and rendered guide expose every adopter action | guide and graph contracts + ExDoc | `mix verify.test test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/guide_graph_contract_test.exs` | ❌ W0 | ⬜ pending |
| 237-01-02 | 01 | 1 | DOCS-03 | T-237-01 | Missing, extra, duplicate, and cross-scope IDs fail; weighted test inventory stays complete | contract mutation controls | `mix verify.test test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/ci_topology_contract_test.exs` | ❌ W0 | ⬜ pending |
| 237-02-01 | 02 | 1 | REL-01 | T-237-03 | Strict candidate mode requires feat!, one 1.0.0 footer, and config false | script syntax + changelog config contract | `mix verify.test test/threadline/changelog_contract_test.exs` | ✅ existing | ⬜ pending |
| 237-02-02 | 02 | 1 | REL-01 | T-237-03 | Candidate parser rejects missing, duplicate, malformed, and 0.13.0 footers; ordinary CI remains runnable | focused topology contract | `mix verify.test test/threadline/ci_topology_contract_test.exs test/threadline/changelog_contract_test.exs` | ✅ existing | ⬜ pending |
| 237-03-01 | 03 | 2 | REL-02 | T-237-05 | Both milestone range SHAs and every BREAKING CHANGE footer are recorded against the human 1.0 entry | exact git-history audit + guide contract | `git log v1.44..HEAD --grep='BREAKING CHANGE' --format='%H %B'` and `mix verify.test test/threadline/upgrading_to_1_0_doc_contract_test.exs` | ✅ existing | ⬜ pending |
| 237-03-02 | 03 | 2 | REL-01, REL-03 | T-237-05 | One committed candidate SHA passes strict 1.0.0 clone gates, then full local CI; PG15/latest pins checked | local artifact rehearsal + CI | `THREADLINE_BUMP_REHEARSAL_MODE=candidate mix verify.bump_rehearsal` then `DB_HOST=localhost DB_PORT=55432 mix ci.all` | ✅ existing | ⬜ pending |
| 237-04-01 | 04 | 3 | REL-03 | T-237-07 | A candidate-specific grant precedes push and milestone PR creation | live PR SHA inspection | `gh pr view -R szTheory/threadline --json number,url,headRefOid,baseRefName,state` | ✅ existing | ⬜ pending |
| 237-04-02 | 04 | 3 | REL-03 | T-237-08 | A separate grant precedes milestone merge; required CI and live Release Please PR are observed | live PR and workflow inspection | `gh pr view -R szTheory/threadline --json number,mergedAt,mergeCommit,statusCheckRollup` | ✅ existing | ⬜ pending |
| 237-05-01 | 05 | 4 | REL-03 | T-237-09 | A fresh Release PR merge grant produces the live v1.0.0 tag and protected pending publish chain | live release inspection | `gh release view v1.0.0 -R szTheory/threadline --json tagName,targetCommitish,url` | ✅ existing | ⬜ pending |
| 237-05-02 | 05 | 4 | REL-03 | T-237-10 | A distinct production-hex grant precedes public Hex 1.0.0 evidence | Hex registry and workflow inspection | `curl -fsSL https://hex.pm/api/packages/threadline | jq -e 'any(.releases[]; .version == "1.0.0")'` | ✅ existing | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `test/threadline/upgrading_to_1_0_doc_contract_test.exs` — cover conditional 0.11 preflight and exact separately scoped ID equality for 0.12 prerequisites and 1.0 changes.
- [ ] `test/partition_weights.txt` — include an explicit measured/valid weight for the new contract file.
- [ ] Rehearsal contract coverage — test candidate subject/footer/config validation, exact 1.0.0 target, rejection of 0.13.0, and accurate local-artifact-rehearsal wording.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Push the candidate, merge the milestone, merge the generated Release PR, and approve protected `production-hex` | REL-03 | These are separate external actions and each requires an explicit maintainer grant; local tests cannot authorize them. | Bind each grant to its current SHA/PR/run, confirm required CI including PostgreSQL 15 and latest-lane pins, the live Release Please tag, the successful protected publish job, and public Hex 1.0.0. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for focused checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
