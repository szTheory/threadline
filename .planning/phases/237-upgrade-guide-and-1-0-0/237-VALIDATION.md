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
| 237-01-01 | 01 | 1 | DOCS-03 | — | Change mapping fails closed on missing, extra, duplicate, or unmatched IDs | contract | `mix test test/threadline/upgrading_to_1_0_doc_contract_test.exs test/threadline/guide_graph_contract_test.exs` | ❌ W0 | ⬜ pending |
| 237-01-02 | 01 | 1 | REL-01 | T-237-01 | Candidate parser rejects missing, duplicate, or non-1.0.0 footer and never treats rehearsal as publication authority | script contract + rehearsal | `mix test test/threadline/ci_topology_contract_test.exs` then `mix verify.bump_rehearsal` on committed candidate HEAD | ❌ W0 | ⬜ pending |
| 237-02-01 | 02 | 1 | REL-02 | — | Human-owned CHANGELOG is checked against the explicit milestone commit range | changelog audit + contract | `git log --grep="BREAKING CHANGE" --format=%B <milestone-range>` and `mix test test/threadline/upgrading_to_1_0_doc_contract_test.exs` | ❌ W0 | ⬜ pending |
| 237-02-02 | 02 | 1 | REL-03 | T-237-02 | Local checks remain separate from push, merge, and protected Hex publish grants | release workflow contract + CI | `mix ci.all` | ✅ existing | ⬜ pending |

---

## Wave 0 Requirements

- [ ] `test/threadline/upgrading_to_1_0_doc_contract_test.exs` — cover conditional 0.11 preflight and exact separately scoped ID equality for 0.12 prerequisites and 1.0 changes.
- [ ] `test/partition_weights.txt` — include an explicit measured/valid weight for the new contract file.
- [ ] Rehearsal contract coverage — test candidate subject/footer/config validation, exact 1.0.0 target, rejection of 0.13.0, and accurate local-artifact-rehearsal wording.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Push the one-squash candidate, merge after required CI, and publish through protected `production-hex` | REL-03 | These are separate external actions and each requires an explicit maintainer grant; local tests cannot authorize them. | After a separate grant for each operation, confirm the single `feat!:` squash and `Release-As: 1.0.0` footer, required CI including PostgreSQL 15 and latest-lane pin checks, the live Release Please result, and the published Hex version. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for focused checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
