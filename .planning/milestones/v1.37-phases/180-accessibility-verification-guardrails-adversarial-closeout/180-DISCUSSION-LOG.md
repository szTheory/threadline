# Phase 180: Accessibility verification, guardrails & adversarial closeout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-19
**Phase:** 180-accessibility-verification-guardrails-adversarial-closeout
**Areas discussed:** Verification matrix and evidence shape, accessibility audit posture, motion audit posture, guardrails and adversarial closeout

---

## Verification Matrix And Evidence Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Layered proof model | Tier A broad automation, Tier B representative browser proof, Tier C bounded manual evidence. | ✓ |
| Full manual matrix | Attempt manual review across every state/theme/viewport combination. | |
| Automation-only | Avoid manual keyboard/screen-reader records and rely on tests. | |

**User's choice:** Auto-selected layered proof model.
**Notes:** `--auto` mode selected the recommended option. This matches Phase 178's honesty pattern and avoids pretending every theoretical cell was manually inspected.

---

## Accessibility Audit Posture

| Option | Description | Selected |
|--------|-------------|----------|
| Rendered-state APG audit | Test real opened overlays/disclosures/widgets and record bounded manual keyboard/screen-reader evidence. | ✓ |
| Source-only audit | Inspect component source without exercising rendered states. | |
| New accessibility harness | Introduce a separate audit framework or dependency. | |

**User's choice:** Auto-selected rendered-state APG audit.
**Notes:** A11Y-01 explicitly names rendered states and manual keyboard/screen-reader checks. Existing Playwright and component-contract tests should be extended before adding architecture.

---

## Motion Audit Posture

| Option | Description | Selected |
|--------|-------------|----------|
| Measurable token/compositor audit | Check computed transitions, reduced-motion collapse, origin-aware overlays, press feedback, and source bans. | ✓ |
| Visual-only review | Treat motion as subjective and review screenshots/video only. | |
| Add new animation system | Introduce a motion dependency or JS animation layer. | |

**User's choice:** Auto-selected measurable token/compositor audit.
**Notes:** This preserves the v1.37 zero-dependency invariant and Phase 177 motion rules.

---

## Guardrails And Adversarial Closeout

| Option | Description | Selected |
|--------|-------------|----------|
| Written closeout plus green guardrails | Run/extend existing guardrails and produce an adversarial review artifact with residual CI classification. | ✓ |
| Green tests only | Skip the written adversarial assessment. | |
| Broad redesign pass | Reopen visual polish and layout work. | |

**User's choice:** Auto-selected written closeout plus green guardrails.
**Notes:** This phase closes the milestone; the signoff must be auditable and should classify the known Phase 179 residual `mix ci.all` failures.

---

## Claude's Discretion

- Exact plan slicing is left to planning, with a recommended conservative split: accessibility/browser audit; APG/component semantics; motion/reduced-motion audit; guardrail/screenshot/adversarial closeout.
- Planner should decide whether the adversarial review is a standalone artifact or a section in verification, as long as it is committed and referenced.

## Deferred Ideas

- New operator capabilities, new filters, new export workflows, novice/expert mode, copy/i18n registries, broad visual redesign, and reopened coverage-page layout work are outside Phase 180 unless a verification gate proves a current blocker.
