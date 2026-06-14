# Phase 170: brand-alignment-closeout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-14
**Phase:** 170-brand-alignment-closeout
**Areas discussed:** Parity definition + enforcement, Posture note placement, Dual-mode addendum form, Audit prep scope
**Mode:** advisor (minimal_decisive; vendor_philosophy=opinionated; technical owner). Recommendations grounded in repo-internal patterns via Explore scout rather than external ecosystem research, given this is a closeout/convention phase.

---

## A — Parity definition + enforcement (BRAND-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Curated-subset parity + automated test | Brandbook mirrors brand-defining tokens; value-equality on intersection; exclusion list documented; locked by `brandbook_token_parity_test.exs` | ✓ |
| 1:1 parity with all ~49 runtime tokens | Grow brandbook to mirror the full runtime lane | |
| Manual sync, no test | Rely on pressure-test addendum + doc-contract literal only | |

**User's choice:** Curated-subset + automated parity-lock test (recommended default).
**Notes:** Runtime-only structural tokens explicitly out of brand scope, documented so the gap is intentional. Test catches drift in both directions. No literal "45" count asserted — value-equality on named tokens.

---

## B — Posture note placement (BRAND-01)

| Option | Description | Selected |
|--------|-------------|----------|
| New subsection in `brand-book.md`, literal-pinned | Near existing Dark/light strategy + color sections; doc-contract lock on keystone sentence | ✓ |
| brandbook README | Posture note in the README instead | |
| New pressure-test dimension | Encode posture as a scored dimension | |

**User's choice:** New subsection in `brand-book.md`, doc-contract pinned (recommended default).
**Notes:** Content = dark-primary; light shipped + supported via host config; runtime toggle deferred. Framing follows v1.33 "state only now it's true" lesson.

---

## C — Dual-mode addendum form (BRAND-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Extend #11 Token rigor (+#5) + mechanical assert | Narrative dimension addendum tied to a shell-runnable parity gate | ✓ |
| New scored dimension #16 | Add a standalone dual-mode dimension | |
| Pure narrative scorecard entry | Prose only, no executable check | |

**User's choice:** Extend existing #11/#5 + one mechanical-suite assertion (recommended default).
**Notes:** Avoids scorecard inflation; ties brand pressure-test to the actual UI token truth via the same parity check.

---

## D — Audit prep scope (success criterion 4)

| Option | Description | Selected |
|--------|-------------|----------|
| Author `v1.36-MILESTONE-AUDIT.md` now; readiness gated on UAT | Full audit doc + traceability green; closeout readiness pending the End-of-milestone UAT gate | ✓ |
| Prep traceability only; defer audit doc | Leave the audit doc to `/gsd-complete-milestone` | |

**User's choice:** Author the audit doc now, gate readiness on UAT (recommended default).
**Notes:** Follows v1.33/v1.20 template. Archival + version bump stay with `/gsd-complete-milestone` post-UAT.

---

## Claude's Discretion

- Exact token in/out reconciliation against live `style.ex`.
- Parity-test parser implementation; whether mechanical assert shells out or is standalone.
- Whether the posture-note literal lock is a new test file or extends an existing brand doc-contract test.

## Deferred Ideas

- THEME-TOGGLE-01 (per-operator runtime switching) — adopter-demand-gated; referenced in posture note as deferred.
- Milestone archival + version bump — `/gsd-complete-milestone`, post-UAT.
- SOCIAL-PNG-01 / HEXDOCS-BRAND-01 / LANDING-01 — out of v1.36 scope; untouched.
