---
phase: 99
slug: contract-lock-docs-and-final-verification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-26
---

# Phase 99 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir/Mix |
| **Config file** | `mix.exs`, `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix verify.doc_contract` or `MIX_ENV=test mix test test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.all` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.doc_contract` for doc-only work, or the targeted evidence parity suite when test files change
- **After every plan wave:** Run `mix verify.example` plus the targeted evidence parity suite
- **Before `$gsd-verify-work`:** Run the named Phase 99 rerun bundle recorded in `99-VERIFICATION.md`
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 99-01-01 | 01 | 1 | DOC-01 | T-99-01 / T-99-02 | Public docs and example wording state the evidence-plane claim narrowly, keep host-owned seams explicit, and preserve separately gated `/audit/evidence` language | doc contract | `mix verify.doc_contract` | ✅ / ❌ W0 | ⬜ pending |
| 99-01-02 | 01 | 1 | DOC-02 | T-99-03 | Canonical non-goals explicitly reject legal hold, immutable-storage guarantees beyond the host contract, compliance packs, vendor reporting suites, and Threadline-owned RBAC/tenancy semantics | doc contract | `mix verify.doc_contract` | ✅ / ❌ W0 | ⬜ pending |
| 99-02-01 | 02 | 2 | DOC-03 | T-99-01 / T-99-02 / T-99-03 | Current-tree verification proves docs, API, CLI, mounted evidence, and example-host surfaces all tell the same bounded story | doc contract + integration | `mix verify.doc_contract && mix verify.example && MIX_ENV=test mix test test/threadline/evidence_test.exs test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs test/threadline/operator_surface/live/evidence_live_test.exs test/threadline/operator_surface/auth_test.exs --max-failures 1` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend `test/threadline/readme_doc_contract_test.exs` to lock the README evidence-plane claim strip
- [ ] Extend `test/threadline/upgrade_path_doc_contract_test.exs` to lock separately gated `/audit/evidence` wording under `phoenix-surface`
- [ ] Decide and implement the `guides/domain-reference.md` lock path: dedicated doc-contract coverage or explicit proof-test assertions
- [ ] Create `99-VERIFICATION.md` structure that records the exact rerun bundle plus any unrelated-known-failure note

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cross-read README, guides, and example README for claim ownership clarity | DOC-01, DOC-02 | The tests can lock literals, but a final human pass is still useful to catch shadow-spec duplication or misleading emphasis | Read `README.md`, `guides/upgrade-path.md`, `guides/integration-contracts.md`, `guides/operator-surface.md`, `guides/domain-reference.md`, `guides/how-threadline-works.md`, and `examples/threadline_phoenix/README.md`; confirm each source owns only its intended claim family |
| Review `99-VERIFICATION.md` for claim-shaped closeout authority | DOC-03 | The artifact must explain the rerun bundle and unrelated known failures without overclaiming | Confirm `99-VERIFICATION.md` names the exact commands, records outcomes, and treats the rerun bundle as authority instead of milestone prose |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
