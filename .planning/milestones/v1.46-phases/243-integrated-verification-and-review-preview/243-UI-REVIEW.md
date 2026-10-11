# Phase 243 — UI Review

**Audited:** 2026-10-11  
**Baseline:** Approved Phase 243 UI-SPEC.md, evaluated at candidate `2f7560e97778d914a7639cbae308bb66fb7c528f`  
**Screenshots:** Captured — existing receipt-bound candidate bundle at `examples/threadline_phoenix/e2e/artifacts/operator-evidence/operator_243_routes_1791737568230_fix` (34 full-shell captures: eleven routes plus degraded Timeline at 1280/768/375px; dark theme). No new captures were made.  
**Interaction captures:** off (workflow.ui_interaction_capture=false)

The review stays within the UI-SPEC's bounded scope. The Evidence footer and Redaction posture spacing/copy corrections are visually present. DR-243-01 remains an explicit medium carry-forward; this review does not broaden the correction batch. Full-shell comparison is limited (647 recorded differences across asset identity, render conditions, fixture/state and environment metadata), so this report does not claim pixel equivalence. Exact-candidate CI provides interaction evidence for 31 named Chromium journeys, including keyboard, responsive, reduced-motion and desktop 200% tab-zoom coverage.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Required “Could not inspect” wording is present, but the zero-row group reads awkwardly beside “All configured tables introspected.” |
| 2. Visuals | 3/4 | Evidence and Redaction hierarchy is clear; the History drawer title remains partly obscured by the fixed header (DR-243-01). |
| 3. Color | 3/4 | Dark candidate captures use semantic surface/accent/status roles; Light/System coverage is supplemental and not bound to this exact candidate. |
| 4. Typography | 2/4 | The shared token set includes 12/13/15/32px sizes beyond the four sizes allowed for phase-scoped UI; small metadata is visibly dense. |
| 5. Spacing | 3/4 | Scoped 16px policy gap and 8px Evidence footer separation are evidenced; broader spacing remains tokenized but extends beyond the contract's listed scale values. |
| 6. Experience Design | 3/4 | Exact-candidate journeys cover core states and interaction paths; this audit used static captures and receipt evidence because interaction capture was off. |

**Overall: 17/24**

## Top 3 Priority Fixes

1. **DR-243-01: History drawer title is partly hidden under the fixed header** — weakens orientation in a row-history investigation — retain the medium carry-forward and correct overlay positioning in a separately approved scope.
2. **Typography exceeds the Phase 243 four-size contract** — compact metadata and identifiers are harder to scan — constrain phase-scoped route text to 14/16/20/24px roles or document a deliberate exception in the design contract.
3. **Redaction empty category wording is semantically correct but awkward** — “Could not inspect (0)” followed by “All configured tables introspected” makes the empty category look like an error — use an empty-category label that preserves the public status enum and exact required heading contract, or clarify the section label.

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING —** The required unreadable-state label is implemented as `Could not inspect` and the public enum stays `:could_not_introspect` (`lib/threadline/operator_surface/live/policy_redaction_live.ex:21,450`). The captured Redaction route shows the section heading “Could not inspect (0)” while its empty copy says “All configured tables introspected.” (`:453-454`). This is logically a zero-row category, but the adjacent phrases make the state momentarily sound contradictory. Clarify the empty-category sentence without changing the public status or scope.
- **PASS with limitation —** Route-specific actions remain descriptive (“Refresh policy inspection”, “Filter to subject”, “Review evidence”, etc.); the reviewed scoped components do not introduce generic Submit/OK labels. UI-SPEC requires preservation of the existing route copy and truthful operation states.

### Pillar 2: Visuals (3/4)

- **WARNING — DR-243-01 (medium carry-forward):** The 1280px drawer capture shows the “Row history” title's top line behind the fixed header while the Close control remains visible. The same geometry exists in the accepted Phase 238 baseline. This is a visible orientation defect, though it does not block closing or using the drawer. Keep it as the explicit carry-forward; overlay positioning owns a future correction (`243-VISUAL-REVIEW.md`, drawer capture SHA-256 `f64e1c27164c6b9e57d584d51468c164998bcc9bb628eda53742260452cb146d`).
- **PASS —** Candidate bundle includes all eleven route shells at 1280/768/375px plus degraded Timeline. The Evidence subject card remains the focal point and footer actions read as secondary; Redaction's refresh controls precede a visually distinct posture card. The bundle confirms the targeted changes without asserting pixel equivalence.
- **Limitation —** Screenshots are dark-only. The approved contract also covers Light and System themes, for which the cited focused checks were run on an earlier source HEAD, not as exact-candidate full-shell captures.

### Pillar 3: Color (3/4)

- **PASS with limitation —** The shared palette is expressed through semantic custom properties for page background, surface, text, accent, focus, borders, and status (`lib/threadline/operator_surface/style/01_tokens.css:54-75,187-204`). In the reviewed dark captures, blue accent is concentrated on meaningful links/actions and selection; status badges retain text labels alongside color. No new palette or third-party component library appears in the phase contract.
- **WARNING —** The receipt-bound route bundle shows only Dark mode. Light/System theme checks are recorded as supplemental at earlier source HEAD `af1a3369f3a0061707283fab18c7c2663d2b1893` (`243-VISUAL-REVIEW.md`, “Supplemental rendering checks and limits”). Exact-candidate theme parity therefore remains less directly evidenced than dark-theme hierarchy.

### Pillar 4: Typography (2/4)

- **WARNING —** UI-SPEC lists four phase-scoped sizes (14/16/20/24px) and two weights (400/600). The shared token catalog exposes 12, 13, 14, 15, 16, 20, 24, and 32px (`style/01_tokens.css:17-25`), and the reviewed evidence screens render compact metadata and references at a visibly smaller scale than body text. This is established system styling, but it misses the new contract's explicit four-size limit and reduces scanning comfort on dense Evidence and drawer views.
- **PASS —** Geist/Inter/system and IBM Plex Mono stacks are preserved (`style/01_tokens.css:15-16`); titles, labels, body text, and identifiers use distinct semantic roles. No copy is clipped in the Evidence or Redaction 375px captures.

### Pillar 5: Spacing (3/4)

- **PASS —** The candidate Redaction capture places the posture card below the refresh action with the intended visual separation. The receipt-bound visual ledger records the focused 320px probe at the earlier UI source HEAD as a measured 16px gap. Evidence footer CSS uses the 8px spacing token for both separation from the card content and inter-link gap, with a 40px minimum hit area at widths up to 480px (`style/09_responsive.css:110-121`); the 320px check recorded 40px targets and an 8px card-edge gap.
- **WARNING —** The contract's named scale is 4/8/16/24/32/48/64px, while the token catalog also includes 12/20/40px (`style/01_tokens.css:5-13`). Those values may be legitimate existing system tokens, but the contract does not explain their use in phase-scoped components. No arbitrary-pixel spacing was identified in the reviewed scoped CSS.

### Pillar 6: Experience Design (3/4)

- **PASS —** The exact-candidate evidence index reports 31 required identities discovered and passed once without retry across desktop/mobile Chromium, including error/empty distinctions, keyboard operation, responsive routes, reduced motion and a real desktop 200% tab-zoom check. Redaction retains the unreadable/missing distinction; Evidence footer links remain reachable; the visual contract also preserves host authorization and server-side operation truth.
- **WARNING —** `workflow.ui_interaction_capture=false`, so this audit did not produce a fresh post-interaction capture or inspect a live focus/hover state. Interaction claims above rely on the exact-SHA CI receipt and existing route evidence, not a new manual browser session. Safari, Firefox, physical-device text scaling and mobile extension zoom are outside the evidence.
- **PASS with carry-forward —** Overlay Close remains reachable in the drawer capture despite the obscured title. DR-243-01 is the only outstanding interaction-adjacent visual issue recorded for the scoped correction batch.

## Registry Safety

UI-SPEC reports no shadcn or third-party registry components; the application uses its private Phoenix/HEEx UI system. Registry audit not applicable.

## Files Audited

- `.planning/phases/243-integrated-verification-and-review-preview/243-UI-SPEC.md`
- `.planning/phases/243-integrated-verification-and-review-preview/243-VISUAL-REVIEW.md`
- `.planning/phases/243-integrated-verification-and-review-preview/243-EVIDENCE-INDEX.md`
- All six `243-*-PLAN.md` and all six `243-*-SUMMARY.md` files
- `lib/threadline/operator_surface/live/policy_redaction_live.ex`
- `lib/threadline/operator_surface/live/evidence_live.ex`
- `lib/threadline/operator_surface/live/transaction_live.ex` and `row_history_component.ex`
- `lib/threadline/operator_surface/style/01_tokens.css`, `09_responsive.css`, and route-scoped style files
- `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json`
- `examples/threadline_phoenix/e2e/artifacts/operator-evidence/operator_243_routes_1791737568230_fix` (34 full-shell screenshots, capture manifests, candidate review)
