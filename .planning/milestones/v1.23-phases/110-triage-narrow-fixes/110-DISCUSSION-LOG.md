# Phase 110: Triage + Narrow Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 110-triage-narrow-fixes
**Areas discussed:** All six gray areas (user requested full discuss + subagent research; auto-resolved to coherent recommendations)

---

## Fix ordering & re-walk gate

| Option | Description | Selected |
|--------|-------------|----------|
| A: Fix 0001 only → full re-walk | Minimal scope; WR confirmed on re-walk | Partial (Wave 1) |
| B: Batch 0001 + WR fixes → re-walk | Fastest green walk | |
| C: Partial re-walk from §2 | Resume without §1 re-proof | |
| D: Multi-pass (a) loop | Fix each (a) then re-walk | |
| **Synthesized: Three-wave playbook** | Wave 1: 0001 only. Wave 2: WR via confirmed pre-registration. Wave 3: validation re-walk. | ✓ |

**User's choice:** Delegated to research synthesis — three-wave playbook (D-110-01)
**Notes:** Reconciles minimal §1 gate honesty with not wasting re-walk on known broken CLI prose. K8s/SIEM/Stripe analogues cited in subagent research.

---

## Pre-registered findings (WR-001 / WR-002)

| Option | Description | Selected |
|--------|-------------|----------|
| A: Proactive fix, no finding files | Silent doc edits | |
| B: Confirmed pre-registration | File 0002/0003 with 108-REVIEW + spot-check | ✓ |
| C: Wait for full re-walk only | Pure empirical purity | |
| D: Hybrid split | WR-002 now, WR-001 later | |

**User's choice:** Option B — file 0002 (WR-002, c), 0003 (WR-001, c) in Wave 2 after 0001
**Notes:** WR-001 fix aligns prose to `demo_last_tuesday`→`demo_epoch`; WR-002 matches WALK-04-01 flag style. Classification (c) despite wrong-answer symptom — fix surface is docs + contract tests only.

---

## (b) papercut budget line

| Option | Description | Selected |
|--------|-------------|----------|
| Single commit threshold | Too granular | |
| **Single GSD plan file** | ≤3 tasks, ≤5 files, examples/guides/planning only | ✓ |
| Time-boxed / LOC-only | Subjective / incomplete | |
| Generous batch all infos | Scope creep vector | |

**User's choice:** Moderate interpretation — one plan file with explicit gates (D-110-03)
**Notes:** IN-001 fix in Phase 110; IN-002/003/004 routed separately. 30-second triage checklist mirrors findings README classifier.

---

## `lib/` touch bar

| Option | Description | Selected |
|--------|-------------|----------|
| Ultra-strict | Never lib/ for example bugs | |
| **Moderate + layer-first gate** | lib/ only for (a) with lib/ stack trace | ✓ |
| Pragmatic | Fix root cause anywhere | |

**User's choice:** Moderate — 0001 stays examples-only; zero lib/ commits expected for current inventory (D-110-04)
**Notes:** Carbonite/OTel/Rails engine analogue — host owns landing/auth; library owns capture/semantics/exploration.

---

## Post-fix verification scope

| Option | Description | Selected |
|--------|-------------|----------|
| Full §0–§5 only | Highest cost | L3 when needed |
| Targeted WALK-01-04→§5 | Efficient RUN unblock | ✓ L2 minimum |
| Automated smoke only | FIX-01 only, not RUN | L0/L1 per wave |
| Second observe-only 109 | Wrong mode post-fix | Rejected |

**User's choice:** Verification ladder L0→L1→L2 (required) → L3 (if bootstrap drift); 110-SUMMARY records RUN matrix (D-110-05)

---

## Seed deferral authoring

| Option | Description | Selected |
|--------|-------------|----------|
| Prose-only | No machine fields | |
| **Minimal YAML + fixed sections** | TEMPLATE + README index | ✓ |
| Full GSD plant-seed shape | Overkill for triage | |

**User's choice:** Option B — `.planning/v1.24-seeds/TEMPLATE.md`, independent SEED-001… numbering, DEFER-01 floor + optional Breadcrumbs for model-touching (d) gaps (D-110-06)

---

## Claude's Discretion

- Plan split if IN-001 bundling exceeds task budget
- Optional `(b) budget rubric` in findings README
- Verification script vs inline commands in 110-VERIFICATION.md

## Deferred Ideas

- Full containerized walk — v1.24 seed
- Generous papercut sweep — rejected
- Second observe-only Phase 109 — rejected
- Pre-fix WR before 0001 — rejected
