# Requirements: Threadline

**Milestone:** v1.46 — Operator UI Refinement
**Defined:** 2026-10-08
**Status:** Approved by the maintainer on 2026-10-08; UIB-01/02 and UIV-01/02 are complete. Phase 243 is in progress with Plans 01–06 approved and Plan 05 next.
**Core Value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1.46 Requirements

### Baseline and acceptance

- [x] **UIB-01**: Maintainers can open a reproducible, safely seeded preview of the current-main UI, with source and served-asset identity recorded for captures of all eleven operator routes.
- [x] **UIB-02**: Maintainers can trace every route, shared primitive, unique control and material state to a ranked finding or explicit coverage disposition before implementation starts.

### Shared presentation and language

- [x] **UIS-01**: Operators can read page hierarchy, labels and evidence comfortably through a consistent shared typography, spacing and control system, including dense and long-content states.
- [x] **UIS-02**: Operators encounter the same canonical domain terms for the same concepts across navigation, headings, controls, validation and feedback.
- [x] **UIS-03**: Operators can access complete identifiers, field values and exact timestamps with timezone information wherever shortened presentation is used.

### Investigation journeys

- [x] **UII-01**: Operators can start an investigation from the home page through clear, visible entry points for the supported lookup and search jobs.
- [x] **UII-02**: Operators can filter and page the timeline without losing the active query or scope, including reload and browser back/forward navigation.
- [x] **UII-03**: Operators can inspect a transaction's changes and before/after values while distinguishing its action, actor and execution context.
- [x] **UII-04**: Operators can inspect supported row history and as-of evidence through both direct entry and the transaction drawer without losing the originating investigation context.
- [x] **UII-05**: Operators can follow existing actor and correlation pivots to related activity and return with the investigation context intact.
- [x] **UII-06**: Operators can save, resume and share supported searches with coherent names and accurate restoration of the supported search state.

### Operations journeys

- [x] **UIO-01**: Authorized operators can complete the existing export journey from its source search through queued/running/failed/completed states to a usable download and return to that search.
- [x] **UIO-02**: Operators can identify capture coverage gaps in the correct schema and find the corresponding host-migration remediation without mistaking unknown status for healthy coverage.
- [x] **UIO-03**: Operators can inspect evidence and subject proof history with explicit distinctions among host-recorded evidence, unavailable data and limited completeness.
- [x] **UIO-04**: Operators can compare configured redaction policy with deployed trigger policy and understand discrepancies without exposing redacted values.
- [x] **UIO-05**: Authorized operators can inspect retention runs and complete the existing confirmed prune action with accurate scope, outcome and failure feedback.

### Responsive and interaction behavior

- [x] **UIA-01**: Operators can complete the supported jobs at narrow, intermediate and desktop widths and actual 200% browser zoom without losing controls or evidence to accidental page overflow.
- [x] **UIA-02**: Operators can select Light, Dark or System and see the chosen preference and effective appearance remain correct across reloads and LiveView navigation.
- [x] **UIA-03**: Operators can use controls and overlays by keyboard and touch, with visible focus, predictable dismissal and focus return, including overlapping toast/menu/drawer states.
- [x] **UIA-04**: Operators can distinguish pending, empty, failed, denied and completed states without stale data being labeled as the newly requested scope or an accepted operation being reported as completed.
- [x] **UIA-05**: Operators receive accurate disconnected/reconnecting feedback, and unavailable mutations cannot be activated by either keyboard or pointer or duplicated during recovery.
- [x] **UIA-06**: Operators can copy supported values on fresh direct entry and after repeated LiveView patches, with truthful clipboard failure feedback and no duplicate event handling.
- [x] **UIA-07**: Operators receive purposeful, interruptible motion for meaningful state changes, while frequent actions remain immediate and reduced-motion preferences are respected.

### Verification and delivery readiness

- [x] **UIV-01**: Maintainers can run automated checks for the supported journeys and material failure cases and verify that the intended regression tests are discovered and executed by required CI.
- [x] **UIV-02**: Maintainers can compare trustworthy before/after rendered evidence and a bounded agent visual review, with normal verification leaving baselines unchanged and concrete findings fixed or explicitly dispositioned.
- [x] **UIV-03**: Maintainers can review the finished UI in a reproducible preview tied to the delivery candidate, accompanied by the verified coverage, remaining limitations and release-ready recommendation.

## Acceptance interpretation

These requirements refine existing jobs; they do not assert that absent backend
features already exist or authorize inventing them. The current-main baseline
confirms the supported controls and states before implementation. Every requirement
will have one owning phase; shared requirements remain regression conditions for
later journey work. Cross-cutting accessibility/state work belongs in each affected
slice, rather than being postponed to the final review.

- Equal engineer/operator priority and code-first are settled product decisions.
  Use `PRODUCT.md`, the Brand Book, Impeccable and Kowalski guidance within existing
  Phoenix/HEEx patterns. Choose measurable visual floors from fresh renders in the
  initial design contract; do not invent a new palette or blanket component rewrite.
- Preserve server authorization, tenant scoping, host ownership, redaction, routes,
  public 1.x APIs, optional Phoenix dependencies, and capture/semantics/exploration
  boundaries throughout all journeys. UI affordances never replace server checks.
- All eleven routes in `UI-MILESTONE-PREFLIGHT.md` are in scope. Theme submission
  and export/download endpoints are journey seams. Storybook/stress routes are
  verification surfaces. Use real supported states; justify N/A combinations.
- Verify reflow at 320 CSS px where applicable and magnification at actual 200%
  browser zoom as separate evidence. Legitimately two-dimensional diffs/tables may
  scroll locally with full data access; the page and primary controls must remain
  usable. Include long unbroken values and short/intermediate viewports.
- Accessibility includes semantic names/relationships, usable contrast, visible
  focus, readable validation, keyboard/touch reachability and reduced motion.
  Required browser coverage is the actual configured engine; do not claim broader
  browser or physical-device validation without evidence.
- A lossless copy/access path must not bypass redaction or authorization. Preserve
  absent/unknown/redacted/pruned distinctions. ActorRef is not synonymous with user;
  an AuditAction, AuditTransaction and AuditChange remain different concepts.
- Baseline and final evidence record source SHA and relevant diff, asset identity,
  fixture scenario, route/state, role/scope, theme/preference, viewport/browser and
  motion/clock settings as applicable. Include full-shell evidence, not only
  `#tl-main`. Capture writes are explicit and separate from normal verification.
- Use existing named `mix verify.*` and `mix ci.all` checks; retain stable job IDs.
  Add lasting tests for meaningful failure classes, with local one-shot evidence
  for checks that do not justify recurring CI cost. No screenshot-count target,
  Cartesian state matrix, paid critic or retired pixel machinery by default.
- Bound visual iteration per coherent slice: batch review, corrective batch and
  confirmation. An unresolved defect needs reproduction, severity and disposition;
  no unresolved correctness, security, accessibility or journey blocker may be
  called complete. Taste feedback may follow; the maintainer is not the UAT runner.
- Preserve unrelated local edits. Implementation starts from current main via the
  configured isolation workflow with planning/product context carried over. Local
  preparation and a release-ready recommendation are authorized; a later push or
  package publication follows the applicable delivery authorization.

## Future Requirements

No new backend capabilities are committed or automatically queued by this milestone.
Known scalar-only row routing and unbounded row-history reads retain their existing
limits. A reproduced incident or adopter need can justify a separately scoped
composite-key route or bounded-history change. Later maintainer taste feedback may
produce a small followup; a second redesign milestone is not presumed necessary.

## Out of Scope

| Feature | Reason |
| --- | --- |
| Rebrand, framework migration or cross-project UI package | Refine the established identity and implementation; these do not follow from the approved operator jobs |
| New public component API or mandatory Phoenix dependency | Preserve package boundaries and capture-only adopters |
| New capture/semantics APIs, row-key routing or pagination capabilities | Separate backend scope and 1.x decisions; not incidental UI cleanup |
| Compliance guarantees, new retention/redaction powers or host evidence auto-population | UI must report existing semantics honestly |
| New paid model judging, image-generation spend or hosted services | Keep verification bounded; the paid critic remains parked |
| CI topology redesign or unrelated dependency maintenance | Preserve existing regression lanes; require separate evidence for broader changes |
| Automatic package publication from this approval | Delivery readiness is included; a publish action needs its own applicable authorization |

## Traceability

Approved roadmap maps each requirement to one owning phase, starting at Phase 238. Cross-cutting requirements remain regression conditions for later affected journeys. Completed Phase 237 and the v1.45 archive stay closed.

| Requirement | Phase | Status |
| --- | --- | --- |
| UIB-01 | Phase 238 | Complete |
| UIB-02 | Phase 238 | Complete |
| UIS-01 | Phase 239 | Complete |
| UIS-02 | Phase 239 | Complete |
| UIS-03 | Phase 239 | Complete |
| UII-01 | Phase 239 | Complete |
| UII-02 | Phase 239 | Complete |
| UII-03 | Phase 239 | Complete |
| UII-04 | Phase 240 | Complete |
| UII-05 | Phase 240 | Complete |
| UII-06 | Phase 240 | Complete |
| UIO-01 | Phase 242 | Complete |
| UIO-02 | Phase 241 | Complete |
| UIO-03 | Phase 241 | Complete |
| UIO-04 | Phase 241 | Complete |
| UIO-05 | Phase 242 | Complete |
| UIA-01 | Phase 239 | Complete |
| UIA-02 | Phase 239 | Complete |
| UIA-03 | Phase 239 | Complete |
| UIA-04 | Phase 239 | Complete |
| UIA-05 | Phase 242 | Complete |
| UIA-06 | Phase 240 | Complete |
| UIA-07 | Phase 240 | Complete |
| UIV-01 | Phase 243 | Complete |
| UIV-02 | Phase 243 | Complete |
| UIV-03 | Phase 243 | Complete |

**Coverage:** 26/26 approved requirements mapped once in the approved roadmap; 17 complete.

---
*Requirements defined: 2026-10-08*
*Last updated: 2026-10-10 to reconcile verified Phase 239 and Phase 240 requirements*
