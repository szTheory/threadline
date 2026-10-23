# Phase 240 UI Review — Connected investigation and recovery

**Audit mode:** Code and automated-test evidence. No Threadline preview was running: ports 3000 and 5173 were unavailable, and port 8080 served Traefik Proxy. No screenshots were captured. This review was completed inline because this session does not permit subagent dispatch.

| Pillar | Score | Evidence |
|---|---:|---|
| 1. Copywriting | 4/4 | Saved-search, row-history, shared-URL, delete-confirmation, and clipboard outcomes use the approved domain language and actionable recovery copy. |
| 2. Visuals | 3/4 | Saved searches and clipboard feedback use explicit, wrapping layouts; no rendered screenshots were available to verify their final composition. |
| 3. Color | 3/4 | New states use semantic theme tokens and distinguish success/error with text and color; the rendered 60/30/10 area balance could not be measured. |
| 4. Typography | 3/4 | New labels and summaries use existing type roles and preserve complete values; actual rendered hierarchy could not be inspected. |
| 5. Spacing | 3/4 | The new saved-search grid and copy status use the existing spacing scale; 320px and zoom behavior was not visually captured in a running host. |
| 6. Experience Design | 4/4 | Route recovery, saved-search ownership, clipboard outcomes, keyboard/focus behavior, reduced motion, and LiveView patches have automated browser coverage. |

**Overall: 20/24**

No product-flow blocker was identified from the source and CI evidence. Scores of 3 reflect the missing rendered inspection, not a confirmed visual defect.

## Pillar findings

### Pillar 1: Copywriting (4/4)

- **PASS:** The saved-search empty state follows the approved “No saved searches” heading and explains that applied Timeline filters can be saved.
- **PASS:** Row-history errors distinguish unavailable history from empty or denied results and expose retry/return guidance.
- **PASS:** Clipboard feedback says “Copied” only after a confirmed browser write and gives manual-selection recovery after failure. It does not echo the copied value.
- **PASS:** Delete confirmation names the saved search and the consequence; shared-search copy explains that the receiving host recomputes results and access.

### Pillar 2: Visuals (3/4)

- **PASS evidence:** Saved searches use a responsive grid with a flexible content column and a separate delete control. Long names and summaries wrap locally. Clipboard status is in document flow, so it does not cover the source value or nearby focus targets.
- **WARNING — rendered composition unverified:** No Threadline page was available for screenshot inspection. The CSS structure is coherent, but this review cannot confirm the final balance or clipping in the host-rendered application.

### Pillar 3: Color (3/4)

- **PASS evidence:** Copy success and failure use the existing semantic signal and danger tokens. Other new controls inherit existing surface, text, and focus tokens rather than adding a phase-specific color palette.
- **WARNING — area balance unmeasured:** The UI-SPEC defines an approximate 60/30/10 visual-area split. Source-level token usage cannot establish rendered proportions; the Threadline host preview was unavailable.

### Pillar 4: Typography (3/4)

- **PASS evidence:** Saved-search summaries and clipboard messages use existing caption/label roles, and the layout wraps long evidence instead of shrinking values to fit.
- **WARNING — rendered hierarchy unverified:** No screenshot was available to check whether primary instructions, evidence values, and labels retain the intended size and contrast hierarchy in the complete host shell.

### Pillar 5: Spacing (3/4)

- **PASS evidence:** Saved-search controls use existing `--tl-space-*` tokens and minimum-width-safe grid columns. Clipboard feedback reserves a full row with a tokenized top gap. Browser coverage checks mobile layout and 200% zoom for key flows.
- **WARNING — viewport edge not captured:** This audit did not inspect a live 320px viewport or host-level 200% zoom rendering. Existing automated coverage reduces risk but cannot substitute for the missing rendered preview at the narrowest boundary.

### Pillar 6: Experience Design (4/4)

- **PASS:** Browser tests cover direct entry and transaction-origin row history, retained as-of state, safe return, Escape dismissal, and focus restoration.
- **PASS:** Saved-search tests cover actor ownership, canonical applied filters, deletion confirmation, and operation failure states.
- **PASS:** Clipboard tests exercise successful and failed writes, fresh entry, and repeated LiveView patches. Feedback is based on the actual API/fallback outcome.
- **PASS:** Motion tests keep evidence changes and investigation rows immediate, preserve reduced-motion behavior, and exercise keyboard entry and dismissal.

## Priority follow-ups

1. Capture the Timeline, saved-search, transaction, and row-history surfaces from a Threadline-enabled host at 375px, 768px, and 1440px; inspect the saved-search and clipboard states against the UI-SPEC before the milestone’s final preview.
2. Measure the rendered color-area balance and verify text/focus contrast in both dark and light/System themes. Keep the current score at 3 until this is supported by rendered evidence.
3. Add or run a host-preview check at 320px and 200% zoom for saved-search actions, long names, clipboard status, and row-history return/focus controls.

## Evidence reviewed

- `.planning/phases/240-connected-investigation-and-recovery/240-UI-SPEC.md`
- Phase 240 plans and summaries 01–04
- `lib/threadline/operator_surface/live/timeline_live.ex` and its `filters`, `helpers`, and `changes` modules
- `lib/threadline/operator_surface/live/row_history_live.ex`, `row_history_component.ex`, and `transaction_live.ex`
- `lib/threadline/operator_surface/script.ex`, `ui/display.ex`, `ui/overlay.ex`, and Phase 240 control/overlay/responsive CSS
- `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts`, `operator-earned-flows.spec.ts`, `operator-motion.spec.ts`, and `operator-route-states.spec.ts`
- Final Phase 240 `mix ci.all` result recorded in the plan summaries: pass; root ExUnit 3100 tests, Phoenix example 132 tests, Dialyzer 0 errors, Playwright 385 passed / 71 skipped.
