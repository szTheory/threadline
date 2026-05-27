---
phase: 102
slug: phase-98-verification-backfill
status: finalized
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-27
updated: 2026-05-27T10:20:47.000Z
---

# Phase 102 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.x) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` |
| **Full suite command** | Same as Quick — focused two-file rerun bundle (per CONTEXT.md D-08; intentionally narrower than `mix verify.test`, see CONTEXT.md D-10) |
| **Estimated runtime** | ~1 second (research observed 34 tests / 0 failures in 0.2s) |

---

## Sampling Rate

- **After every task commit:** Run the focused two-file rerun bundle.
- **After every plan wave:** Same bundle (Phase 102 is documentation-only on existing-and-passing tests; no need to widen).
- **Before `/gsd:verify-work`:** Bundle must be green (34 tests, 0 failures) AND structural grep proofs from `102-RESEARCH.md` §5 must still match the current tree.
- **Max feedback latency:** ~1 second.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 102-01-01 | 01 | 1 | SURF-01 / SURF-02 / SURF-03 | — | Current-tree fingerprint (mount, parity, fail-closed gate) matches CONTEXT.md citations D-05/D-06/D-07/D-12 | structural + behavioral | `mix test test/threadline/operator_surface/auth_test.exs test/threadline/operator_surface/live/evidence_live_test.exs --max-failures 1` AND the six structural greps from `102-RESEARCH.md` §5 | ✅ | ⬜ pending |
| 102-01-02 | 01 | 1 | SURF-02 / SURF-03 | — | Smallest literal-truth repair on `98-VALIDATION.md` per D-16/D-18 (Quick/Full run swap to focused bundle; no test or source changes) | artifact | `git diff --stat .planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md` shows only the literal-truth swap | ✅ | ⬜ pending |
| 102-02-01 | 02 | 2 | SURF-01 | — | `98-VERIFICATION.md` Band 1 cites read-only mount + no-mutation-handlers structural proof, plus LiveView test authority | artifact | `rg -n 'SURF-01' .planning/phases/98-mounted-evidence-views-on-audit/98-VERIFICATION.md` returns ≥1 match in Band 1 AND closure table | ✅ Wave 2 | ⬜ pending |
| 102-02-02 | 02 | 2 | SURF-02 | — | `98-VERIFICATION.md` Band 2 cites shared-presenter alias (Proof.present_record) + locked copy literals (D-12, including the proof.ex:10 `@semantic_statuses` source confirmed in research §2.2) + LiveView test authority | artifact | `rg -n 'SURF-02\|Proof.present_record\|@semantic_statuses' .planning/phases/98-mounted-evidence-views-on-audit/98-VERIFICATION.md` returns matches in Band 2 AND closure table | ✅ Wave 2 | ⬜ pending |
| 102-02-03 | 02 | 2 | SURF-03 | — | `98-VERIFICATION.md` Band 3 cites negative grep for Threadline-owned RBAC PAIRED with positive-control grep for `evidence_authorize_fn`, plus fail-closed default citation | artifact | `rg -n 'SURF-03\|evidence_authorize_fn' .planning/phases/98-mounted-evidence-views-on-audit/98-VERIFICATION.md` returns matches in Band 3 AND closure table | ✅ Wave 2 | ⬜ pending |
| 102-02-04 | 02 | 2 | SURF-01 / SURF-02 / SURF-03 | — | `98-VALIDATION.md` finalized: frontmatter flipped to `status: final` / `nyquist_compliant: true` / `wave_0_complete: true`; `## Commands Actually Used` section added (per D-15); retroactive-backfill note added (per D-14); Quick/Full run swap landed (per D-18); milestone-authority surfaces NOT touched (per D-19) | artifact | `grep -E '^(status\|nyquist_compliant\|wave_0_complete):' .planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md` shows the flipped values AND `rg -n '## Commands Actually Used\|retroactively' .planning/phases/98-mounted-evidence-views-on-audit/98-VALIDATION.md` returns ≥1 match AND `git status .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md` shows no changes | ✅ Wave 2 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* Phase 98 already shipped `test/threadline/operator_surface/auth_test.exs` and `test/threadline/operator_surface/live/evidence_live_test.exs` with 34 passing tests on the current tree (`HEAD 1db8e8e` confirmed by research §6). Phase 102 is verification-backfill: no new test stubs, no new fixtures, no framework changes (per CONTEXT.md D-16 smallest-literal-truth posture).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual hierarchy of focal-block sequence in `98-UI-SPEC.md` | SURF-02 | Not code-anchorable — visual rhythm and scanability are perception-bound (per CONTEXT.md D-11; precedent set by `98-VALIDATION.md` original draft and `84-VERIFICATION.md` Band 2 scope) | Operator opens `/audit/evidence` in dev, eyeballs the focal-block sequence against `98-UI-SPEC.md` mockup. Phase 102 does NOT attempt to grep visual claims. |
| Spacing tokens (4/8/16/24/32/48px) in `98-UI-SPEC.md` | SURF-02 | Manual-Only per `98-VALIDATION.md` original; design-token adherence is render-bound, not source-grep-bound | Operator inspects rendered LiveView via browser devtools against `98-UI-SPEC.md` spacing scale. |
| Typography sizing & color palette adherence | SURF-02 | Manual-Only per `98-VALIDATION.md` original | Operator inspects rendered LiveView via browser devtools against `98-UI-SPEC.md` typography/color rules. |
| Scanability of evidence rows | SURF-02 | Perception-bound | Operator skim-reads the rendered surface and confirms verdict status is glanceable. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none — existing infrastructure suffices)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter
- [ ] Retroactive-backfill honesty note (per CONTEXT.md D-14) recorded once Phase 102 ships and this artifact is finalized: "Phase 102 is verification-backfill on already-passing Phase 98 tests; no Wave 0 execution occurred in the original sense — this validation contract documents the focused two-file rerun bundle that proves the SURF-01/02/03 surfaces remain intact on the current tree."

**Approval:** pending
