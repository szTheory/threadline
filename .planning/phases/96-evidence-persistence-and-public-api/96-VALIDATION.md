---
phase: 96
slug: evidence-persistence-and-public-api
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
updated: 2026-05-25T19:50:00Z
---

# Phase 96 - Validation Strategy

> Planning-time validation contract for the evidence persistence and public API phase.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix alias verification + planning-artifact review |
| **Config file** | `mix.exs`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/phases/96-evidence-persistence-and-public-api/96-CONTEXT.md` |
| **Quick run command** | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` |
| **Full suite command** | Same as quick run — the focused bundle IS the authority per D-05 |
| **Artifact checks** | grep the Phase 96 plans and validation artifact for `PROOF-01`, `latest_`, `list_`, and the subject-focused `record_*` helper family |
| **Estimated runtime** | repo-wide verify band, with focused evidence tests available as the local repro loop |

## Sampling Rate

- After any write-path contract change in `Threadline.Evidence`: rerun the focused evidence tests first, then `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1`.
- After any read-shape change affecting history or latest helpers: rerun the focused evidence tests first, then `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1`.
- Before closing Phase 96: require `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` green on the same tree as the Phase 96 summaries.
- Before starting Phase 97 or 98 execution: re-read the plan artifacts to confirm list-vs-singular read semantics remain locked.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|--------|
| 96-V-01 | 96-01 | 1 | `PROOF-01` | `T-96-01`, `T-96-02`, `T-96-03` | Subject-focused public write helpers require explicit `repo:`, capture only mechanical defaults, and do not expose a broad generic writer. | focused integration + structural grep | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` | planned |
| 96-V-02 | 96-01 | 1 | `PROOF-01` | `T-96-02` | The full required `record_*` helper family exists for the closed evidence subject set. | artifact + focused tests | `rg -n 'record_(redaction|trigger|retention|export|support)' .planning/phases/96-evidence-persistence-and-public-api/96-01-PLAN.md test/threadline/evidence_test.exs` | planned |
| 96-V-03 | 96-02 | 2 | `PROOF-01` | `T-96-04`, `T-96-05`, `T-96-06` | History helpers stay list-shaped, overview latest-per-subject-ref helpers stay list-shaped, and singular latest helpers stay singular. | focused integration | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` | planned |
| 96-V-04 | 96-02 | 2 | `PROOF-01` | `T-96-04`, `T-96-06` | Latest helpers are projections over append-only history rather than a mutable current-state model. | focused tests + artifact review | `rg -n 'latest_|list_latest|one record or `nil`|append-only' .planning/phases/96-evidence-persistence-and-public-api/96-02-PLAN.md .planning/phases/96-evidence-persistence-and-public-api/96-RESEARCH.md` | planned |

## Requirement-to-Command Map

| Requirement | Evidence Band | Command | Why This Command Counts |
|-------------|---------------|---------|-------------------------|
| `PROOF-01` write path | Focused integration + structural grep | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` | The focused bundle is the authoritative Phase 96 proof band; it avoids carry-forward alias-drift outside Phase 96 ownership. |
| `PROOF-01` write path | Closed-set structural grep | `rg -n '^\s*def record_' lib/threadline/evidence.ex` | Asserts exactly the six closed public `record_*` helpers exist and no generic writer has been added. |
| `PROOF-01` read path | Focused integration | `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` | Confirms the read helpers preserve stable list-vs-singular return shapes. |
| `PROOF-01` read path | Artifact review | `rg -n 'list_|latest_|record_' .planning/phases/96-evidence-persistence-and-public-api/96-01-PLAN.md .planning/phases/96-evidence-persistence-and-public-api/96-02-PLAN.md .planning/phases/96-evidence-persistence-and-public-api/96-VALIDATION.md` | Locks the planned helper family and list-vs-singular semantics before execution starts. |

## Nyquist Notes

- Phase 96 is Nyquist-compliant because every execution task is mapped to the focused rerun bundle or an explicit artifact check.
- The focused `mix test test/threadline/evidence_test.exs test/threadline/governance/evidence_record_test.exs --max-failures 1` command is the authoritative Phase 96 proof surface. `mix verify.test` carries alias-drift outside Phase 96 ownership (Phase 99 owns that surface; commit `b636c17` is the most recent fix).
- Overview/latest-per-subject-ref list semantics and singular latest semantics must remain separate all the way through Phase 97 and Phase 98 consumers.

## Validation Sign-Off

- [x] Each planned task maps to a named verification surface or explicit artifact check.
- [x] The read contract distinguishes list-shaped overview helpers from singular latest helpers.
- [x] The write contract requires the full subject-focused helper family rather than one exemplar helper.
- [x] The repo's named verification entrypoint is the primary proof band.
- [x] `nyquist_compliant: true` is justified by a complete planning-time verification map, not by executed runtime proof.

**Approval:** planned on 2026-05-25 for Phase 96 execution.
