# Phase 168: accessibility-verification - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 168-accessibility-verification
**Areas discussed:** e2e light re-run mechanism, Failure-fix autonomy, Disabled-text strictness

---

## Gray-area selection

The phase is heavily locked by `168-UI-SPEC.md` (token pairs, thresholds,
alpha-aware compositing all fixed). Presented three delegated appetite/mechanism
choices + a "SPEC is enough" escape hatch.

| Option | Description | Selected |
|--------|-------------|----------|
| e2e light re-run mechanism | Dedicated `:light` route vs Playwright `colorScheme` emulation | ✓ |
| Failure-fix autonomy | Carry 167 D-04/D-05 vs pause-on-every-failure | ✓ |
| Disabled-text strictness | Strict 4.5:1 + bounded fallback vs accept WCAG exemption | ✓ |
| None — SPEC is enough | Skip discussion, carry SPEC + 167 verbatim | ✓ |

**User's choice:** Selected all three areas AND "None — SPEC is enough." Read as
"no strong independent opinions; give me the recommendation, SPEC as backbone."
Resolved by recommending the best answer per area and confirming in one pass.

---

## e2e light-lane re-run mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Playwright `colorScheme: 'light'` | Emulate `:system` light branch; zero example-app footprint; reuses spec verbatim; keeps app theme demo in Phase 169 | ✓ |
| Dedicated `:light` test route | SPEC's first-listed option; most deterministic, tests explicit `[data-tl-theme=light]`; adds an example-app route, overlaps Phase 169 | |

**User's choice:** Playwright `colorScheme: 'light'` (→ CONTEXT D-01).
**Notes:** Selects the SPEC's second (emulation) option as lowest-friction;
proves the `:system` light render path that is otherwise only source-asserted.

---

## Failure-fix autonomy

| Option | Description | Selected |
|--------|-------------|----------|
| Carry 167 D-04/D-05 | Autonomous bounded alpha/value tune of existing tokens at lane root; new hue/primitive FLAGS + halts | ✓ |
| Pause on every failure | Stop and ask on any failing pair, even an in-lane alpha tune | |

**User's choice:** Carry 167 D-04/D-05 (→ CONTEXT D-02/D-03).
**Notes:** Consistent with Phase 167 precedent; the `LIGHT-REVIEW.md` item-A
pattern (uniform lane-root alpha, never per-component) is the fix template.

---

## Disabled-text (`muted-soft`) strictness

| Option | Description | Selected |
|--------|-------------|----------|
| Strict, bounded fallback | Assert 4.5:1; downgrade ONLY disabled-token rows to documented WCAG 1.4.3 exemption if a tune can't reach it | ✓ |
| Accept WCAG exemption upfront | Treat disabled-text rows as exempt from the start | |

**User's choice:** Strict, bounded fallback (→ CONTEXT D-04).
**Notes:** Matches the SPEC default and Threadline's "disabled stays legible by
default" posture.

---

## Claude's Discretion

- Parser placement (extend `color_tokens/1` vs sibling parser).
- Exact form/organization of the new contract assertions and the light-mirror
  token-pair table within `style_contract_test.exs`.
- Lowest-friction wiring of the Playwright `colorScheme` re-run (new spec project/
  config vs parameterized existing spec).

## Deferred Ideas

- `__light__` screenshot baseline + example-app `theme: :system` demo + adopter docs — Phase 169.
- Brandbook `tokens.json`/`tokens.css` 45-token parity — Phase 170.
- Three keyword-matched Phase-167 seeds reviewed, none folded (out of a11y scope):
  coverage card de-clutter (C), theme picker / `THEME-TOGGLE-01` (D), transaction
  desktop left-push layout bug (E).
