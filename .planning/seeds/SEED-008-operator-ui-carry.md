---
id: SEED-008
status: dormant
planted: 2026-10-25
planted_during: v1.47 Phase 246
scope: small
related: SEED-005
register: .planning/phases/246-debt-closeout-and-critic-retirement/246-DEBT-REGISTER.md
reopen_when: >-
  the maintainer brings UI feedback, or the 1.0.0 UI work opens
  (operator-UI design work is parked until 1.0.0)
---

# SEED-008: Operator-UI carry (parked with the UI)

## Why

Operator-UI design work is parked until 1.0.0. Several real but non-blocking UI findings
from v1.46 and the v1.41 browser bring-up therefore have no milestone to land in. Phase 246
(DEBT-01) routes them here so that "parked with the UI" names a real place. Without this
seed they would be waived without a reason or lost. Each item below is a `routed` row in
`246-DEBT-REGISTER.md`.

## Scope

- **DR-243-01 (medium visual-clarity risk).** At the reviewed desktop width the History
  drawer title sits partly under the fixed header. Close stays visible, and the accepted
  baseline has the same geometry (`.planning/milestones/v1.46-MILESTONE-AUDIT.md:121`).
- **Typography.** Dense views use type sizes outside the approved four-size Phase 243
  contract. The final v1.46 UI review scored 17/24 (`v1.46-MILESTONE-AUDIT.md:122`).
- **Redaction copy.** The empty-category labels in
  `lib/threadline/operator_surface/live/policy_redaction_live.ex:450-454` read awkwardly
  next to the zero-row heading.
- **The 8 screenshot-regression baselines.** The failures are
  `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts:108/:115/:136/:145`
  (dense Timeline, row-history drawer, Exports, Retention), each on desktop-chromium and
  mobile-chromium. WINDOWS rows 14-17 and 62 record them. The baselines were last written in
  180-04 and have been proven pre-existing. Until the UI work reopens, a healthy browser
  lane has exactly these 8 failures. Regenerate the baselines only as part of that UI work.
- **Degraded timeline twin.** Untangle the degraded timeline twin from v1.46 evidence
  custody. This is follow-up work for when the UI reopens (246-CONTEXT deferred ideas).

## Done-when

Each item is fixed or explicitly re-dispositioned inside the reopened UI work, and the
8-failure browser baseline is replaced by regenerated, reviewed screenshots.
