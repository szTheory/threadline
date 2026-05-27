---
phase: 96
slug: evidence-persistence-and-public-api
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
updated: 2026-05-27T07:37:28Z
---

# Phase 96 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.
> Phase 96 is now closed against the current-tree rerun bundle recorded in
> `96-VERIFICATION.md`, not against summary prose alone.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + ripgrep structural and artifact greps |
| **Config file** | `lib/threadline/evidence.ex`, `lib/threadline/evidence/subject.ex`, `lib/threadline/governance/evidence_record.ex`, `test/threadline/evidence_test.exs`, `test/threadline/governance/evidence_record_test.exs` |
| **Quick run command** | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` |
| **Full suite command** | Same as quick run — the focused bundle IS the authority per D-05 |
| **Artifact checks** | grep the Phase 96 verification artifact for `PROOF-01`, `Result: PASS`, the subject-focused `record_*` helper family, and the negative-assertion structural grep result |
| **Estimated runtime** | ~10–30 seconds warm |

---

## Sampling Rate

- After any write-path contract change in `Threadline.Evidence`: rerun the focused evidence tests first, then `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1`.
- After any read-shape change affecting history or latest helpers: rerun the focused evidence tests first, then `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1`.
- Before closing Phase 96: require `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` green on the same tree as the Phase 96 summaries.
- Keep milestone authority-surface reconciliation separate; this validation artifact closes Phase 96 only.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 101-01-01 | 01 | 1 | PROOF-01 | T-101-01, T-101-02, T-101-03 | The current tree still exposes exactly six subject-focused write helpers with no generic public writer, mechanical-only defaults, and explicit semantic fields. | focused integration + structural grep | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1 && rg -n '^\s*def record_' lib/threadline/evidence.ex` | ✅ | ✅ green |
| 101-01-02 | 01 | 1 | PROOF-01 | T-101-04 | Read helpers preserve list-vs-singular shape discipline and reject unknown filter keys loudly. | focused integration | `mix test test/threadline/evidence_test.exs --max-failures 1` | ✅ | ✅ green |
| 101-01-03 | 01 | 1 | PROOF-01 | T-101-05 | `Threadline.Evidence` does not depend on Plug, Phoenix, the process dictionary, ETS, or Logger metadata. | structural grep (negative assertion) | `rg -n '^\s*(import\|alias\|require\|use)\s+(Plug\|Phoenix)\.\|Process\.(put\|get)\(\|Logger\.metadata\(\|:ets\.' lib/threadline/evidence.ex` (expected empty) | ✅ | ✅ green |
| 101-02-01 | 02 | 2 | PROOF-01 | T-101-06 | `96-VALIDATION.md` records the executed rerun bundle, the structural-grep proof, and the closed-set proof — all referenced from `96-VERIFICATION.md`. | artifact review | `rg -n '^phase: 96\|^nyquist_compliant: true\|^wave_0_complete: true\|PROOF-01\|## Commands Actually Used\|evidence_test\.exs\|evidence_record_test\.exs' .planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Commands Actually Used

1. `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1`
   Result: PASS (`12 tests, 0 failures`)
2. `rg -n '^\s*(import|alias|require|use)\s+(Plug|Phoenix)\.|Process\.(put|get)\(|Logger\.metadata\(|:ets\.' lib/threadline/evidence.ex`
   Result: PASS (no matches — negative assertion)
3. `rg -n '^\s*def record_' lib/threadline/evidence.ex`
   Result: PASS (exactly six matches — `record_redaction_policy`, `record_trigger_coverage`, `record_retention_run`, `record_retention_policy`, `record_export_delivery`, `record_support_scope_posture`)

---

## Wave 0 Requirements

- [x] `test/threadline/evidence_test.exs` and `test/threadline/governance/evidence_record_test.exs` prove the Phase 96 create and read contract against the current tree.
- [x] `lib/threadline/evidence/subject.ex` enforces the closed supported-subject inventory one-to-one with the six public `record_*` helpers.
- [x] `Threadline.Evidence` does not depend on Plug, Phoenix, the process dictionary, ETS, or Logger metadata — proven by the tightened structural grep returning no matches.
- [x] `96-VERIFICATION.md` now exists and records the authoritative current-tree rerun bundle with four numbered bands and a PROOF-01 requirement-closure row.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Distinguish Phase 96 closure from milestone-authority closure | PROOF-01 | The phase boundary is a planning-truth judgment, not just a test result. | Confirm `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md` remain unreconciled here and are still reserved for Phase 103 follow-up. |
| Review append-only semantics as an architectural claim | PROOF-01 | The targeted test proves insert behavior, but human review still confirms the chosen model is append-only by design. | Read `96-VERIFICATION.md`, `lib/threadline/governance/evidence_record.ex`, and the checked-in migration; confirm the posture is represented by new inserts rather than updates. |

---

## Phase Boundary Guard

- `96-VALIDATION.md` closes `PROOF-01` only.
- `.planning/REQUIREMENTS.md` was not reconciled here.
- `.planning/ROADMAP.md` was not reconciled here.
- `.planning/STATE.md` was not reconciled here.
- Phase 97, Phase 98, and milestone closeout work remain outside this validation artifact.

---

## Validation Sign-Off

- [x] All executed tasks have explicit automated verification coverage.
- [x] Sampling continuity stayed below the three-task Nyquist gap.
- [x] The validation artifact records the exact rerun bundle used to close `PROOF-01`.
- [x] `nyquist_compliant: true` set in frontmatter.
- [x] Phase-boundary limits are stated explicitly so this artifact does not overclaim authority-surface reconciliation.

**Approval:** finalized on 2026-05-27 after Phase 101-01 produced `96-VERIFICATION.md` and the focused-bundle rerun passed.
