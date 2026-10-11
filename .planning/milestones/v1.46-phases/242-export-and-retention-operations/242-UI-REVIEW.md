# Phase 242 — UI Review

**Audited:** 2026-10-10 (final implementation)  
**Baseline:** Approved `242-UI-SPEC.md` and inherited Phase 239–241 operator UI contract  
**Screenshots:** Not captured — prior desktop, mobile, and tablet Playwright CLI attempts failed; rendered layout remains unverified  
**Interaction captures:** off (workflow.ui_interaction_capture is false)

---

## Final Follow-up Disposition

| Prior finding | Status | Evidence |
|---------------|--------|----------|
| Pre-confirmation prune launchers used danger styling | Closed | Launchers use neutral `tl-button--secondary`; danger styling remains on modal submit ([retention_history_live.ex](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/live/retention_history_live.ex:250), line 440). |
| Timeline export CTA and retention aggregate label diverged from contract | Closed | CTA reads `Export changes` ([filters.ex](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/live/timeline_live/filters.ex:428)); metric reads `Rows deleted in recent runs` ([retention_history_live.ex](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/live/retention_history_live.ex:325)). |
| Empty confirmation was not blocked and authorization loss looked like mismatch | Closed | Input is required and mismatch stays inline; `:unauthorized` has separate access feedback ([retention_history_live.ex](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/live/retention_history_live.ex:134), lines 144–151, 415–434). |
| Scrim fallback bypassed theme token | Closed | Modal and drawer scrims use `var(--tl-color-backdrop)` ([08_overlays_motion.css](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/style/08_overlays_motion.css:153)). |
| 12px journey-step label was counted as a Phase 242 typography issue | Removed | `.tl-journey-step__label` occurs only in CSS and a test fixture; no production markup uses it. |
| `.tl-param` had 3px vertical padding | Closed | It now uses `padding: var(--tl-space-1) var(--tl-space-2)`; the `No filters` state uses this style ([07_find_detail.css](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/style/07_find_detail.css:344), [components.ex](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/live/export_status_live/components.ex:100)). |

---

## Pillar Scores

| Pillar | Score | Evidence |
|--------|-------|----------|
| 1. Copywriting | 4/4 | Exact export CTA, scoped recent-run count, distinct mismatch and authorization feedback, and contract empty-state copy. |
| 2. Visuals | 3/4 | Neutral pre-confirmation action and clear summary/history structure; rendered hierarchy is unverified without captures. |
| 3. Color | 3/4 | Theme-aware backdrop token and semantic status colors; rendered 60/30/10 balance is unverified. |
| 4. Typography | 4/4 | Used job metadata and modal roles use approved semantic label/body/title tokens; the flagged unused selector is not rendered. |
| 5. Spacing | 4/4 | Phase-used chip, overlays, and layout use the approved 4px-root spacing tokens; wide table scrolling is locally contained. |
| 6. Experience Design | 4/4 | Durable export/retention states, native confirmation, server authorization, reconnect gating, and mounted browser coverage are present. |

**Overall: 22/24**

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

The Timeline CTA matches the design contract at [filters.ex](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/live/timeline_live/filters.ex:428). Queue acceptance remains distinct from completion. Retention identifies the recent-run aggregate at [retention_history_live.ex](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/live/retention_history_live.ex:325), and authorization denial has its own safe message at line 141. Required empty-state copy remains present.

### Pillar 2: Visuals (3/4)

The retention launcher is neutral until confirmation; the modal submit carries the danger treatment. Export jobs separate status, available download, and source-return action; retention places a summary beside newest-first run history. Final proportions and wrapping remain unverified because screenshots were not captured. This is an evidence limitation, not a code defect.

### Pillar 3: Color (3/4)

The scrim uses the Light/Dark/System-aware `--tl-color-backdrop` token. Status and destructive actions use semantic color tokens with labels. The rendered 60/30/10 balance remains unverified without screenshots; no code-level color defect was found. Registry audit does not apply: `components.json` is absent and the UI spec lists no external registry.

### Pillar 4: Typography (4/4)

Used Phase 242 metadata uses the 14px label role and body content uses the body role; export job metadata rules are in [07_find_detail.css](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/style/07_find_detail.css:324). The previously flagged `.tl-journey-step__label` has no production markup use.

### Pillar 5: Spacing (4/4)

The `No filters` chip now uses 4px and 8px spacing tokens ([07_find_detail.css](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/style/07_find_detail.css:344), rendered by [components.ex](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/live/export_status_live/components.ex:100)). Changed overlay spacing uses named tokens, compact controls retain 40px targets, and the 720px retention table is contained by its local horizontal-scroll wrapper.

### Pillar 6: Experience Design (4/4)

Export and retention expose distinct loading, empty, error, populated, and partial/failure states. Confirmation requires the policy name and provides inline mismatch feedback; authorization denial is distinct ([retention_history_live.ex](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/live/retention_history_live.ex:134)). Reconnect mutation controls wait for fresh persisted state ([script.ex](/Users/jon/projects/threadline/.claude/worktrees/v146-phase241-orchestrator/lib/threadline/operator_surface/script.ex:57)).

## Final Verification Evidence

- `mix ci.all` passed on the final implementation: **root 3,125 tests / 0 failures; example 132 tests / 0 failures; browser 414 passed / 66 intentional skips**.
- No screenshots were captured during this review. Earlier desktop, mobile, and tablet CLI attempts failed; rendered layout, responsive wrapping, and actual 200% zoom remain unverified. This is the only remaining evidence limitation, not a code finding.

## Files Audited

- Phase 242 UI spec, context, plans 01–03, and summaries 01–03
- Timeline, export status/components, and retention LiveViews
- Operator mutation script and overlay component
- Stylesheets: `01_tokens.css`, `04_controls.css`, `06_layout_primitives.css`, `07_find_detail.css`, `08_overlays_motion.css`
- `operator-route-states.spec.ts` and `retention_history_live_test.exs`
