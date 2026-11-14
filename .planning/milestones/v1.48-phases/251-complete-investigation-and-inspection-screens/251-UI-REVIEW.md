# Phase 251 — UI Review

**Audited:** 2026-11-13  
**Baseline:** Approved [251-UI-SPEC.md](251-UI-SPEC.md); reviewed pixel source `da665edcb8590a86a209bc10acb1a98878c65353` (current docs-only HEAD `c0b1508c3c95412e6e2922dd9549b197643343e4`; no later runtime pixel delta). Initial review source `5ef9f8bf75ee31a8c1074daf39d75ba9063dcf81`.  
**Screenshots:** No new captures by this reviewer. Inspected retained matched before/after PNGs and the final source-bound refresh listed below.  
**Interaction captures:** Not captured by this reviewer; the static PNGs do not show interaction states. The phase’s bounded mounted tests are separate evidence, not interaction screenshots.

The before/after pairs match route, viewport, theme, and fixture within each pair; capture clocks differ. The sampled viewports were 1280×900 dark and 375×900 light. No 768px tablet, zoom, native clipboard, or hosted captures were part of this audit.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | The inspected correction, empty, scope, and provenance messages are specific and preserve the contract’s distinctions. |
| 2. Visuals | 4/4 | Inspected dark and light layouts preserve hierarchy; the narrow Coverage badge shows the full selected schema. |
| 3. Color | 3/4 | Ground and panel balance is restrained; the existing global primary action still uses an accent fill. |
| 4. Typography | 4/4 | Home now uses the specified 28px heading token and 1.2 line height. |
| 5. Spacing | 4/4 | Sampled layouts use the existing spacing tokens; the narrow overflow and wrapped Close label are corrected in the after captures. |
| 6. Experience Design | 3/4 | The captured states preserve scope and recovery intent; several read-failure states lack visual captures and review flags remain open. |

**Current overall: 22/24**  
**Score history:** initial review 20/24; first bounded correction 21/24; final delta 22/24.

## Top 3 Priority Fixes at Initial Audit

1. **WARNING — Home title exceeds the phase typography contract.** `03_page_home.css:30` uses the 32px display token where Phase 251 specifies 28px. Switch to the existing heading size and line-height tokens. This finding is source-derived; no Home PNG was retained in the inspected pairs.
2. **WARNING — Primary action fill exceeds the accent rule.** `02_base_shell.css:63` fills the primary button with the accent color, visible on `inspection-after-01-1280-dark-redaction-public.png`. Keep the action prominent with the contract’s narrow accent edge treatment.
3. **WARNING — Narrow shell badge abbreviates the selected Coverage schema.** In `layout-after-01-375-light-coverage-long.png`, the global badge does not expose the full long schema at a glance. Let the shell badge wrap or otherwise make the current schema readily readable; the page’s selector and remediation text do retain the full value.

## Detailed Findings at Initial Audit

### Pillar 1: Copywriting (4/4)

- The retained Timeline capture changes from showing rows after unsupported input in `matched-before-01-375-light-timeline-unsupported.png` to a visible correction in the after capture: “These Timeline filters are not supported. Update the filters before applying them.” The message correctly describes requested filters and does not imply an unfiltered result. Source: `timeline_live.ex:334`.
- The retained transaction-context pair adds the contract’s context-loss notice before return to Timeline (`transaction_live.ex:148`). The invalid-time capture uses the explicit invalid-time message and offers “View latest snapshot” as a separate user action (`row_history_component.ex:211`); it does not label the latest snapshot as the requested time.
- Coverage’s empty state names the selected schema and says other schemas were not inspected (`coverage_live.ex:158`, `coverage_live.ex:160`). The Redaction empty state says no configured policy exists and does not claim an all-clear (`policy_redaction_live.ex:244`, `policy_redaction_live.ex:398`). Evidence labels the time as “Snapshot recorded at” and says writer/entrypoint are caller-overridable metadata, not verified identity (`evidence_live.ex:109`, `evidence_live.ex:174`).
- These strings are specific to the affected job and distinguish invalid, empty, and unavailable facts. The no-match and read-unavailable copy was reviewed in source, but corresponding Evidence and inspection error screens were not among the retained PNGs inspected.

### Pillar 2: Visuals (3/4)

- The shell stays quiet while page headings, selected facts, result rows, and remediation lead. The dark captures keep the shell/panel hierarchy readable; the light mobile captures collapse navigation and stack controls without hiding the result. Status words remain visible alongside their color cues.
- **WARNING:** the long-schema Coverage capture at 375px shows an abbreviated schema in the global status badge. Full schema text remains in the page selector and long remediation command, so this is a scope-at-a-glance issue rather than a lost-data defect.
- The History Close label wrapped vertically into five lines in the before image and is one line in the after image. The corrected after capture restores a clear action without changing the surrounding history hierarchy.

### Pillar 3: Color (3/4)

- The inspected dark and light captures retain the approved ground and panel separation; accent remains a small part of the page and is concentrated on links, focus, and selected navigation.
- **WARNING:** the primary button rule sets `background: var(--tl-color-accent)` at `02_base_shell.css:63`. The solid blue “Refresh policy inspection” button is visible in the inspected Redaction image. Phase 251 reserves accent for links, focus, selected state, and the primary action edge, so this button surface is broader than the contract permits. No broad decorative blue wash was observed.

### Pillar 4: Typography (3/4)

- The inspected pages use a clear heading/body/metadata ladder and keep table and identifier values visually distinct. Shared token definitions use 12px labels, 13px dense metadata, 16px body text, and 28px headings; the medium alias resolves to the approved 600 weight.
- **WARNING:** Home’s `.tl-home__headline` uses `--tl-font-size-display` at `03_page_home.css:30`; the token is 32px, and the Phase 251 contract says not to use it in this dense Admin work. The Home lifecycle is in the phase scope, but no Home screenshot was in the inspected capture pairs, so the rendered effect is unverified.

### Pillar 5: Spacing (4/4)

- The inspected 375px long-schema after capture wraps the summary/remediation content without horizontal overflow. The shared CSS uses the existing spacing variables; the changed long-content grid uses a zero-minimum track (`08_overlays_motion.css:527`).
- The row-history Close control is now a single line in `layout-after-01-375-light-history-close.png`; the matched before image shows the five-line failure. Its visible focus ring and reachable control remain intact. The sampled controls and spacing align with the 40px text-control and 44px icon-control targets.
- This score covers the sampled 1280px and 375px views only; it does not establish tablet, zoom, or every-state spacing.

### Pillar 6: Experience Design (3/4)

- The captured invalid-time state stays invalid and does not silently show the latest snapshot. The Timeline unsupported-filter state blocks the prior broad read; the retained-context state explains the safe return; Coverage and Redaction show selected-scope and zero-policy meanings; Evidence distinguishes latest projection from append-only history and recorded time from verified identity.
- Phase evidence reports bounded mounted tests for the new Redaction and Evidence paths. However, no retained PNG in the inspected set shows Evidence no-match/read-unavailable, Redaction inspection failure, or a Coverage database-read failure. The host has no existing outage-injection route; the owning live/DB tests are the available failure proof. Do not treat the absence of those images as evidence that the UI rendered them correctly.
- Carry forward the validation statuses exactly: **six prohibition flags remain `FLAGGED-UNVERIFIED` because they are descriptor-less; four edge assumptions remain unclassified/unresolved.** Passing behavior tests and the captures do not resolve those registry states. The validation artifact also remains draft with Nyquist incomplete; this UI review is not a phase-closeout claim.

## Capture Identity and Images Inspected

Current reviewed source: `5ef9f8bf75ee31a8c1074daf39d75ba9063dcf81`. The retained capsules identify matched route/theme/viewport/fixture conditions within each pair and record actual clock differences. These are the PNGs inspected through image viewing:

- `matched-before-01-375-light-timeline-unsupported.png`, `matched-after-01-375-light-timeline-unsupported.png`
- `matched-before-01-375-light-transaction-context.png`, `matched-after-01-375-light-transaction-context.png`
- `matched-before-01-375-light-saved-selection.png`, `matched-after-01-375-light-saved-selection.png`
- `snapshot-before-01-1280-dark-standalone.png`, `snapshot-after-01-1280-dark-standalone.png`
- `snapshot-before-01-375-light-nested.png`, `snapshot-after-01-375-light-nested.png`
- `coverage-before-01-1280-dark-phase251_cov_pair.png`, `coverage-after-01-1280-dark-phase251_cov_pair.png`
- `coverage-before-01-375-light-phase251_cov_empty.png`, `coverage-after-01-375-light-phase251_cov_empty.png`
- `layout-before-01-375-light-coverage-long.png`, `layout-after-01-375-light-coverage-long.png`
- `layout-before-01-375-light-history-close.png`, `layout-after-01-375-light-history-close.png`
- `inspection-before-01-1280-dark-redaction-public.png`, `inspection-after-01-1280-dark-redaction-public.png`
- `inspection-before-01-375-light-redaction-empty.png`, `inspection-after-01-375-light-redaction-empty.png`
- `inspection-before-01-1280-dark-evidence-latest.png`, `inspection-after-01-1280-dark-evidence-latest.png`
- `inspection-before-01-375-light-evidence-history.png`, `inspection-after-01-375-light-evidence-history.png`

The images are retained outside the repository at `/private/tmp/private251evidence/`. This audit did not run a dev server, create captures, or perform browser/clipboard/zoom/hosted checks. The no-match/read-failure screens and Home are source/test-derived only. Phase 251 UI-SPEC marks shadcn uninitialized and specifies repository-owned Phoenix components, so there is no third-party registry audit to run.

## Files Audited

- `.planning/phases/251-complete-investigation-and-inspection-screens/251-UI-SPEC.md`
- `.planning/phases/251-complete-investigation-and-inspection-screens/251-CONTEXT.md`
- `.planning/phases/251-complete-investigation-and-inspection-screens/251-PAIR-EVIDENCE.md`
- `.planning/phases/251-complete-investigation-and-inspection-screens/251-02-BOUNDARY-CONTINUATION.md`
- `.planning/phases/251-complete-investigation-and-inspection-screens/251-03-BOUNDARY-CONTINUATION.md`
- `.planning/phases/251-complete-investigation-and-inspection-screens/251-04-BOUNDARY-CONTINUATION.md`
- `lib/threadline/operator_surface/live/timeline_live.ex`
- `lib/threadline/operator_surface/live/transaction_live.ex`
- `lib/threadline/operator_surface/live/row_history_component.ex`
- `lib/threadline/operator_surface/live/coverage_live.ex`
- `lib/threadline/operator_surface/live/policy_redaction_live.ex`
- `lib/threadline/operator_surface/live/evidence_live.ex`
- `lib/threadline/operator_surface/components/surface_header.ex`
- `lib/threadline/operator_surface/style/01_tokens.css`
- `lib/threadline/operator_surface/style/02_base_shell.css`
- `lib/threadline/operator_surface/style/03_page_home.css`
- `lib/threadline/operator_surface/style/04_controls.css`
- `lib/threadline/operator_surface/style/08_overlays_motion.css`

## Bounded Correction — 2026-11-13

This note preserves the initial audit above while correcting two evidence attributions:

- **Pillar 2:** Reinspection of `layout-after-01-375-light-coverage-long.png` shows the complete badge text `phase251_cov_pairedlong01: 2 not audited`; the page also retains the full selected schema and scope title. Withdraw the badge-truncation finding. Update Visuals from 3/4 to 4/4 and the current overall score from 20/24 to **21/24**. The narrow after capture shows no badge clipping or content overflow.
- **Pillar 3:** `02_base_shell.css:63` is the hidden skip link, not the primary button. The visible fill comes from the existing shared primary-control rule at `04_controls.css:576` and is used by “Refresh policy inspection” in the retained Redaction capture. Keep the color-contract observation as a **nonblocking WARNING deferred to Phase 253 shared-palette work**; it is not a Phase 251 blocker or a Phase 251-owned shared-style fix. No change to the finding’s observed appearance is claimed.

The initial Top 3 is historical triage: its Coverage badge item is withdrawn, and its primary-button item is reclassified as a Phase 253 follow-up. The Phase 251-owned typography finding remains the in-scope correction. No source code, runtime, or tests were changed for this correction.

## Final Bounded UI Delta — source `da665edcb8590a86a209bc10acb1a98878c65353`

This final delta supplements the initial audit and bounded correction above. It uses the frozen source manifest and retained before/after captures; no new browser operation or test run was performed by this reviewer.

### Current Pillar Scores

| Pillar | Current score | Delta evidence |
|--------|--------------:|---------------|
| 1. Copywriting | 4/4 | Redaction now states how many deployed tables have no configured policy, separately from configured drift and matches. |
| 2. Visuals | 4/4 | The actual Home after captures preserve the page hierarchy at both widths; the Coverage badge is fully visible in the earlier after capture. |
| 3. Color | 3/4 | The shared primary button still uses an accent fill; retain this as the nonblocking Phase 253 palette follow-up recorded above. |
| 4. Typography | 4/4 | Home changes from 32px to the existing 28px heading token with its 1.2 line-height at desktop and mobile. |
| 5. Spacing | 4/4 | The Home after captures remain within the viewport; the existing narrow-history and Coverage layout fixes remain present. |
| 6. Experience Design | 3/4 | The zero-config/deployed Redaction distinction is now represented separately in source and refreshed captures; unavailable-state visual limits and the recorded review statuses remain. |

**Current overall: 22/24**

### Delta Findings and Disposition

- **RESOLVED — Home title size.** The scoped CSS diff changes only `.tl-home__headline` from the 32px display token to the 28px heading token and corresponding heading line-height token. In the retained matched PNGs, the title is visibly smaller at 1280×900 dark and 375×900 light while preserving hierarchy. The after capsule reports no horizontal overflow. The after render and source both match the contract.
- **RESOLVED — Redaction zero-config/deployed classification.** Current `policy_redaction_live.ex` derives comparison rows/counts from configured table keys and reports deployed-but-unconfigured tables separately. The refreshed 1280px dark Redaction capture shows four such public-schema tables alongside one configured drift and one configured match; the 375px light view keeps those counts readable. The `threadline` empty-policy capture still says “No configured policy to compare” in each empty section. Retained evidence records the exact real-trigger regression and configured-empty positive case, plus the affected coupled three-case batch, as first-attempt passes with retries disabled. This closes the earlier source-review blocker for the inspected boundary; no checks were rerun by this reviewer.
- **DEFERRED, NONBLOCKING — shared primary accent fill.** The earlier correction remains: the visible primary fill is the shared rule at `04_controls.css:576`, not `02_base_shell.css:63`. It is a current UI-SPEC color mismatch but an existing global treatment owned by Phase 253 shared-palette work, not a Phase 251 blocker.
- **WITHDRAWN — narrow Coverage badge truncation.** The actual `layout-after-01-375-light-coverage-long.png` displays the full `phase251_cov_pairedlong01: 2 not audited` badge. No Visuals deduction remains for this item.

No visual PNG in the inspected refreshed set depicts Evidence no-match/read-unavailable or a database-read outage. The owning source and bounded live/DB tests are separate evidence; this review does not claim those error states were visually captured. Preserve the registry statuses: **six descriptorless prohibition flags remain `FLAGGED-UNVERIFIED`; four edge assumptions remain unclassified/unresolved.** This UI delta does not resolve them.

### Additional Actual PNGs Inspected

- `/private/tmp/private251evidence/home-type-before-01-1280-dark-home.png`
- `/private/tmp/private251evidence/home-type-after-01-1280-dark-home.png`
- `/private/tmp/private251evidence/home-type-before-01-375-light-home.png`
- `/private/tmp/private251evidence/home-type-after-01-375-light-home.png`
- `/private/tmp/private251evidence/inspection-after-review-01-1280-dark-redaction-public.png`
- `/private/tmp/private251evidence/inspection-after-review-01-1280-dark-redaction-empty.png`
- `/private/tmp/private251evidence/inspection-after-review-01-1280-dark-evidence-latest.png`
- `/private/tmp/private251evidence/inspection-after-review-01-1280-dark-evidence-history.png`
- `/private/tmp/private251evidence/inspection-after-review-01-375-light-redaction-public.png`
- `/private/tmp/private251evidence/inspection-after-review-01-375-light-redaction-empty.png`
- `/private/tmp/private251evidence/inspection-after-review-01-375-light-evidence-latest.png`
- `/private/tmp/private251evidence/inspection-after-review-01-375-light-evidence-history.png`

The Home pair records source `5ef9f8bf75ee31a8c1074daf39d75ba9063dcf81` before and `da665edcb8590a86a209bc10acb1a98878c65353` after. The refreshed Redaction/Evidence after capsule is bound to `da665edcb8590a86a209bc10acb1a98878c65353` and uses the same scenes as the earlier inspection pair. These pixels support the Home typography and current Redaction presentation findings; they do not extend the audit to tablet, zoom, native clipboard, hosted execution, or unpictured failure states.
