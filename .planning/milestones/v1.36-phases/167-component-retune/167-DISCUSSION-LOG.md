# Phase 167: component-retune - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-13
**Phase:** 167-component-retune
**Areas discussed:** Proof mechanism, Review sequencing, Override appetite, FLAG handling
**Mode:** advisor (calibration tier `minimal_decisive`; technical owner — no plain-language reframe)

---

## Proof mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Both (test + checklist) | Extend `style_contract_test.exs` to assert authored overrides + absence of stray per-component tint-rider light selectors; committed `LIGHT-REVIEW.md` for the 9 families + data-viz judgment. | ✓ |
| Checklist only | One markdown review doc; no new source-contract assertions; tint-rider invariant unguarded in CI. | |

**User's choice:** Both (test + checklist)
**Notes:** Source-contract test is the CI guard for the TOKEN-02 "out of contract unless proven" invariant; the checklist satisfies the UI-SPEC's "human-gateable judgment, not just a passing test" requirement for data-viz. Screenshots (Phase 169) are the later visual backstop, not a substitute.

---

## Review sequencing

| Option | Description | Selected |
|--------|-------------|----------|
| Review-first | Eyeball the current 166 recolor in dark/light/system, produce the fail-list, then author overrides only for proven failures. | ✓ |
| Author-then-review | Author the 3 likely overrides per spec reasoning, review the result at the end. | |

**User's choice:** Review-first
**Notes:** Matches the STATE human gate ("eyeball before retune effort is spent") and the UI-SPEC confirm-first default. Planner must structure the live review as an explicit early gate whose output drives the override tasks.

---

## Override appetite

| Option | Description | Selected |
|--------|-------------|----------|
| Confirm-strict | Author an additive override only for families the review proves fail. Minimal additive surface; composes with review-first. | ✓ |
| Proactive | Pre-author all 3 flagged high-risk overrides (#1 glass / #5 scrim / #8 signal-line) up front. | |

**User's choice:** Confirm-strict
**Notes:** Honors UI-SPEC default disposition + Hard Constraint 1. The flagged trio gets explicit review attention but is not pre-authored.

---

## FLAG handling mid-execution

| Option | Description | Selected |
|--------|-------------|----------|
| Bounded alpha auto, pause on new primitive | Planner pre-authorizes bounded alpha tuning of existing tokens (spec: "still additive"); only a genuinely new hue/primitive pauses for user. | ✓ |
| Pause on every FLAG | Any value not literally in the 45-token lane stops execution for a user decision. | |

**User's choice:** Bounded alpha auto, pause on new primitive
**Notes:** The UI-SPEC's own language ("FLAG token-alpha bump (still additive)") anticipates alpha tuning; reserving the pause for true new primitives keeps the decisive flow.

---

## Claude's Discretion

- Exact name/location of the review-checklist artifact (must live in phase dir, record dispositions explicitly).
- Exact form of the new `style_contract_test.exs` assertions (must prove authored-override presence + tint-rider no-stray-selector invariant).
- Internal organization of additive override blocks within `style.ex`.

## Deferred Ideas

- Screenshot `__light__` baseline lane — Phase 169.
- AA contrast mirror + focus-visible/interaction-state a11y audit — Phase 168.
- Brandbook `tokens.json` / `tokens.css` 45-token parity — Phase 170.
- Example-app `theme: :system` demo + adopter docs — Phase 169.
