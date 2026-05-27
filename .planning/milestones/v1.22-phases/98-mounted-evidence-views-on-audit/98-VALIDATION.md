---
phase: 98
slug: mounted-evidence-views-on-audit
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-26
updated: 2026-05-27T09:21:28Z
---

# Phase 98 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Phase 98 is now closed against the current-tree rerun bundle recorded in
> `98-VERIFICATION.md`, not against summary prose alone.
>
> **Retroactive backfill note:** Wave 0 evidence was reconstructed retroactively
> from the current tree as part of Phase 102; original Phase 98 execution did
> not produce a Nyquist-compliant artifact. The `nyquist_compliant: true` and
> `wave_0_complete: true` flags reflect post-hoc verification of pre-existing
> implementation, not in-line Wave 0 execution. The focused two-file rerun
> bundle named below is the authority, not `mix verify.test`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix LiveView tests |
| **Config file** | `mix.exs`, `config/test.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` |
| **Full suite command** | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` |
| **Estimated runtime** | ~10-30 seconds warm |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`
- **After every plan wave:** Run `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 98-01-01 | 01 | 1 | SURF-01 | T-98-01 / T-98-02 | `/audit/evidence` renders only read-only overview/history state and preserves URL-driven navigation | liveview | `mix test test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` | ✅ | ✅ green |
| 98-02-01 | 02 | 2 | SURF-02 | T-98-03 | mounted labels and fallback copy preserve `proven`, `inferred_posture`, and `unsupported` semantics without query drift | liveview | `mix test test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` | ✅ | ✅ green |
| 98-02-02 | 02 | 2 | SURF-03 | T-98-04 | host-owned evidence callback fails closed to explicit unsupported state when denied | unit + liveview | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Commands Actually Used

1. `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1`
   Result: PASS (`34 tests, 0 failures`)

---

## Wave 0 Requirements

- [x] `test/threadline/operator_surface/live/evidence_live_test.exs` — mounted proof for overview, drill-down, and unsupported-state flows
- [x] `test/threadline/operator_surface/auth_test.exs` — extend capability-boolean coverage for evidence gating
- [x] `98-VERIFICATION.md` now exists and records the authoritative current-tree rerun bundle.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual scan of evidence landing-page hierarchy against `98-UI-SPEC.md` | SURF-01, SURF-02 | Copy order and scanability are easier to confirm from rendered HTML/live page than from unit assertions alone | Mount `/audit/evidence`, verify title `What can Threadline prove right now?`, verify verdict labels, `View history`, and unsupported fallback copy render in the intended order |

---

## Phase Boundary Guard

- `98-VALIDATION.md` closes `SURF-01`, `SURF-02`, and `SURF-03` only.
- `.planning/REQUIREMENTS.md` was not reconciled here.
- `.planning/ROADMAP.md` was not reconciled here.
- `.planning/STATE.md` was not reconciled here.
- Visual hierarchy, spacing tokens, typography sizing, color palette, and scanability portions of `98-UI-SPEC.md` remain Manual-Only and are not grep-anchored in `98-VERIFICATION.md`.
- Phase 99 (already shipped contract-lock + final verification), Phase 100 (Phase 95 backfill), Phase 101 (Phase 96 backfill), and Phase 103 (authority-surface reconciliation) work remains outside this validation artifact.

---

## Validation Sign-Off

- [x] All executed tasks have explicit automated verification coverage.
- [x] Sampling continuity stayed below the three-task Nyquist gap.
- [x] The validation artifact records the exact rerun bundle used to close SURF-01, SURF-02, and SURF-03.
- [x] Feedback latency under 30s confirmed by live measurement (0.2s warm).
- [x] `nyquist_compliant: true` set in frontmatter (per D-14 retroactive-backfill posture).
- [x] Phase-boundary limits are stated explicitly so this artifact does not overclaim authority-surface reconciliation.

**Approval:** finalized on 2026-05-27 after Phase 102-01 produced 98-VERIFICATION.md and the current-tree rerun bundle passed.
