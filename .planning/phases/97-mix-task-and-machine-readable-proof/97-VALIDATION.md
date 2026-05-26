---
phase: 97
slug: mix-task-and-machine-readable-proof
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-26
---

# Phase 97 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 97 is primarily a CLI + serializer truthfulness slice. The main risks
> are bypassing `Threadline.Evidence`, shipping unstable JSON shape, and
> overclaiming unsupported host-owned behavior as proven evidence.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix task tests + Ecto/PostgreSQL integration tests |
| **Config file** | `mix.exs`, `config/test.exs`, `test/test_helper.exs`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` |
| **Quick run command** | `mix test test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs --max-failures 1` |
| **Full suite command** | `mix verify.test`, then `mix ci.all` for final phase evidence |
| **Estimated runtime** | ~20-60 seconds warm for targeted proof slices; longer for full named verification |

---

## Sampling Rate

- After any proof-serializer or verdict change in `97-01`: run
  `mix test test/threadline/evidence/proof_test.exs --max-failures 1`.
- After any task parsing or rendering change in `97-01`: run
  `mix test test/mix/tasks/threadline.evidence_show_test.exs --max-failures 1`.
- After any unsupported-claim semantic change in `97-02`: rerun both targeted
  files before moving to broader verification.
- Before finalizing the phase: require the targeted proof slice green, then run
  `mix verify.test`. Use `mix ci.all` if the implementation touches broader doc
  or alias contracts.
- Max feedback latency: keep targeted loops under 60 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 97-01-01 | 01 | 1 | PROOF-02 | T-97-01 / T-97-02 | The canonical Mix task stays a thin wrapper over `Threadline.Evidence`, supports overview/latest and bounded history filters, and exits `0` for valid viewer runs. | mix task + integration | `mix test test/mix/tasks/threadline.evidence_show_test.exs --max-failures 1` | ❌ Wave 0 | ⬜ pending |
| 97-01-02 | 01 | 1 | PROOF-02 | T-97-02 | Wrapped JSON keeps stable top-level keys, machine-stable enums, and records close to the evidence-row contract. | unit + integration | `mix test test/threadline/evidence/proof_test.exs --max-failures 1` | ❌ Wave 0 | ⬜ pending |
| 97-02-01 | 02 | 2 | PROOF-03 | T-97-03 | Claim assessment explicitly distinguishes `proven`, `inferred_posture`, and `unsupported` while keeping operational errors separate. | unit + integration | `mix test test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs --max-failures 1` | ❌ Wave 0 | ⬜ pending |
| 97-02-02 | 02 | 2 | PROOF-03 | T-97-01 / T-97-03 | Unsupported claims stay valid payloads and human output stays honest about Threadline-owned versus host-owned authority. | artifact review + named suite | `mix verify.test && rg -n 'proven|inferred_posture|unsupported|format_version|claim_assessment' lib/mix/tasks/threadline.evidence.show.ex lib/threadline/evidence/proof.ex test/threadline/evidence/proof_test.exs test/mix/tasks/threadline.evidence_show_test.exs` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [ ] Create `test/threadline/evidence/proof_test.exs` covering overview mode,
  history mode, wrapped JSON shape, and deterministic verdict semantics.
- [ ] Create `test/mix/tasks/threadline.evidence_show_test.exs` covering argv
  parsing, `--json`, and viewer-style exit behavior.
- [ ] Seed fixtures that exercise all six supported evidence subjects in one
  overview pass.
- [ ] Add an explicit unsupported-claim fixture proving the payload remains
  valid output instead of becoming a runtime failure.
- [ ] Ensure the implementation reuses `Threadline.Evidence` read helpers
  instead of task-local SQL.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Judge whether human-readable output stays honest about authority boundaries | PROOF-03 | The repo can lock strings and JSON keys automatically, but truthfulness about when Threadline is proving facts versus naming unsupported territory still benefits from one final human read. | Run the task in default human-readable mode against fixtures spanning proven, inferred, and unsupported cases. Confirm the output names unsupported territory explicitly and never implies host-owned guarantees. |

---

## Validation Sign-Off

- [x] All planned tasks have explicit automated verification coverage.
- [x] Sampling continuity stays below the three-task Nyquist gap.
- [x] No watch-mode or non-deterministic verification commands are required.
- [ ] `nyquist_compliant: true` will be set after execution evidence is recorded.

**Approval:** pending
