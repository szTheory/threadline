# Phase 153: Verification + Closeout - Pattern Map

**Mapped:** 2026-06-06
**Files analyzed:** 18 brandbook inputs, 8 planning/status targets
**Analogs found:** 8 / 8 target classes

## Extracted Target Files

Phase 153 is a verification-only closeout slice. `brandbook/` files are read-only verification inputs unless a concrete blocker is found. The expected writes are planning evidence, closeout summaries, and traceability/status updates.

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/153-verification-closeout/153-PLAN.md` | plan artifact | batch/control | `.planning/milestones/v1.32-phases/149-verification-review-closeout/149-PLAN.md` | exact |
| `.planning/phases/153-verification-closeout/153-VERIFICATION.md` | verification artifact | batch/file-I/O/browser evidence | `.planning/milestones/v1.32-phases/149-verification-review-closeout/149-VERIFICATION.md` plus `.planning/phases/152-targeted-revisions/152-VERIFICATION.md` | exact |
| `.planning/phases/153-verification-closeout/153-SUMMARY.md` | closeout summary | transform | `.planning/milestones/v1.32-phases/149-verification-review-closeout/149-SUMMARY.md` plus `.planning/phases/152-targeted-revisions/152-SUMMARY.md` | exact |
| `.planning/REQUIREMENTS.md` | milestone ledger | transform | current `.planning/REQUIREMENTS.md` v1.33 rows | exact |
| `.planning/ROADMAP.md` | roadmap/status ledger | transform | current `.planning/ROADMAP.md` Phase 153 row and checklist | exact |
| `.planning/STATE.md` | session/status ledger | transform | current `.planning/STATE.md` Phase 153 focus block | exact |
| `.planning/PROJECT.md` | project rollup | transform | current `.planning/PROJECT.md` milestone state and active requirements | role-match |
| `.planning/milestones/v1.33-MILESTONE-AUDIT.md` or equivalent closeout record | milestone audit | batch/rollup | `.planning/milestones/v1.32-MILESTONE-AUDIT.md` | role-match |

Workflow-contingent archive outputs may also be created if the closeout invokes milestone archive behavior: `.planning/milestones/v1.33-ROADMAP.md`, `.planning/milestones/v1.33-REQUIREMENTS.md`, and archived `v1.33-phases/` contents. Use the v1.32 archive shape as the analog, but do not fabricate archive files if the active workflow only needs `153-VERIFICATION.md` plus summary/status updates.

## Read-Only Verification Inputs

| Input | Role | Data Flow | Verification Use |
|---|---|---|---|
| `brandbook/tokens.json` | structured token source | file-I/O | `jq empty`, file inventory, size baseline |
| `brandbook/index.html` | direct-open browser surface | browser/file-I/O | `xmllint --html`, `agent-browser open`, desktop/mobile screenshots, text snapshot if desired |
| `brandbook/*.svg`, `brandbook/examples/*.svg` | vector asset set | file-I/O | `xmllint --noout`, file inventory, binary exclusion |
| `brandbook/README.md`, `brandbook/brand-book.md`, `brandbook/pressure-test.md`, `brandbook/tokens.css` | source guidance and static tokens | file-I/O | file inventory, historical-frame scan, artifact-boundary proof |
| `/tmp/threadline-v133-brandbook-phase153-*.png` | temporary screenshot evidence | browser output | cite paths in verification; do not commit |

## Data Flow

```
brandbook/tokens.json
brandbook/index.html
brandbook/*.svg and brandbook/examples/*.svg
brandbook/*.md and brandbook/tokens.css
        |
        v
jq / xmllint / rg / file / wc / agent-browser
        |
        +--> /tmp/threadline-v133-brandbook-phase153-desktop.png
        +--> /tmp/threadline-v133-brandbook-phase153-mobile.png
        |
        v
153-VERIFICATION.md
        |
        +--> 153-SUMMARY.md requirements-completed: [BRAND-QA-02]
        +--> REQUIREMENTS.md / ROADMAP.md / STATE.md / PROJECT.md status updates
        +--> optional v1.33 milestone audit/archive artifacts
```

## Pattern Assignments

### `.planning/phases/153-verification-closeout/153-PLAN.md` (plan artifact, batch/control)

**Analog:** `.planning/milestones/v1.32-phases/149-verification-review-closeout/149-PLAN.md`

Use the compact verification plan shape from Phase 149:

- goal sentence,
- requirements list,
- short task list,
- verification section.

Reference pattern: `149-PLAN.md` records "Verify the brand system, update traceability, and close the milestone honestly" and then keeps tasks to running checks, updating requirement status, writing audit/summary artifacts, and preserving no-bloat boundaries.

Apply to Phase 153 with one wave/task group: run the current-tree checks from `153-RESEARCH.md`, write `153-VERIFICATION.md`, then update closeout/status only if checks pass. The existing validation file already defines the task map: `.planning/phases/153-verification-closeout/153-VALIDATION.md:14-37`.

### `.planning/phases/153-verification-closeout/153-VERIFICATION.md` (verification artifact, batch/file-I/O/browser evidence)

**Primary analogs:**

- `.planning/milestones/v1.32-phases/149-verification-review-closeout/149-VERIFICATION.md:1-29`
- `.planning/phases/152-targeted-revisions/152-VERIFICATION.md:11-25`

Use Phase 149's frontmatter and evidence table shape:

```yaml
---
phase: 153-verification-closeout
verified: 2026-06-06
status: passed
requirements: [BRAND-QA-02]
---
```

Then record a "Fresh Command Evidence" table. Phase 153 should refresh, not copy, the Phase 152 evidence. Required command patterns are already enumerated in `.planning/phases/153-verification-closeout/153-RESEARCH.md:61-72`:

- `jq empty brandbook/tokens.json && echo tokens-json-ok`
- `find brandbook -name '*.svg' -print0 | xargs -0 xmllint --noout && echo svg-xml-ok`
- `xmllint --html --noout brandbook/index.html; printf 'xmllint-html-exit=%s\n' $?`
- historical-frame scan from `153-RESEARCH.md:66`
- binary exclusion and file-type inventory from `153-RESEARCH.md:67-68`
- file size with current baseline `95512 total` from `153-RESEARCH.md:69`
- local browser open and `/tmp` screenshots from `153-RESEARCH.md:70-72`

Keep the prior `xmllint --html` warning convention: Phase 150 and Phase 152 both treat exit code 0 as the meaningful signal despite old-parser HTML5 tag warnings (`150-VERIFICATION.md:13`, `152-VERIFICATION.md:17`).

Closeout language must be evidence-gated:

- Mark `BRAND-QA-02` satisfied only after parse, render, screenshot, file-boundary, file-size, and copy-regression checks pass (`153-RESEARCH.md:74-78`).
- State what v1.33 approves now: reviewed brandbook direction, `logo-primary-light.svg` role for light repo/docs surfaces, and Phase 152 targeted copy cleanup.
- Preserve deferred rollout items: root README rollout, HexDocs brand treatment, landing page, social-card PNG export, and legal/trademark review.

### `.planning/phases/153-verification-closeout/153-SUMMARY.md` (closeout summary, transform)

**Analogs:**

- `.planning/milestones/v1.32-phases/149-verification-review-closeout/149-SUMMARY.md:1-24`
- `.planning/phases/152-targeted-revisions/152-SUMMARY.md:1-17`
- `.planning/conventions/summary-frontmatter.md:9-24`

Use hyphenated `requirements-completed`, not underscored metadata:

```yaml
---
phase: 153-verification-closeout
status: complete
completed: 2026-06-06
requirements-completed:
  - BRAND-QA-02
---
```

Body shape:

- one sentence saying Phase 153 reran final verification after Phase 152 targeted revisions,
- "Delivered" bullets for JSON/SVG/HTML parse evidence, direct-open browser screenshots, historical-frame scan, file inventory/size, and no binary bloat,
- "Outcome" paragraph stating v1.33 direction approval and deferred public rollout/legal items.

Do not claim README, HexDocs, landing page, social PNG export, or legal review completion.

### `.planning/REQUIREMENTS.md` (milestone ledger, transform)

**Analog:** exact current v1.33 ledger at `.planning/REQUIREMENTS.md:18-22` and traceability table at `.planning/REQUIREMENTS.md:41-50`.

If and only if `153-VERIFICATION.md` passes, update:

- `BRAND-QA-02` checkbox from `[ ]` to `[x]` and replace "Pending Phase 153" with Phase 153 completion wording.
- Traceability table row from `Pending` to `Complete`.
- Last-updated footer from Phase 152 wording to Phase 153 closeout wording.

Preserve the future requirements and out-of-scope table at `.planning/REQUIREMENTS.md:23-39`; those deferred items are part of the closeout boundary.

### `.planning/ROADMAP.md` (roadmap/status ledger, transform)

**Analog:** exact current Phase 153 roadmap entries:

- phase table row at `.planning/ROADMAP.md:24-29`
- execution checklist at `.planning/ROADMAP.md:31-35`
- Phase 153 success criteria at `.planning/ROADMAP.md:69-79`

If verification passes, update Phase 153 from `Pending` to `Complete`, check the execution item, and update top status from active/pending to complete/archive-ready according to the workflow. Keep the non-goals at `.planning/ROADMAP.md:10-16` unchanged.

### `.planning/STATE.md` (session/status ledger, transform)

**Analog:** current active focus block at `.planning/STATE.md:25-30`, pending todo at `.planning/STATE.md:60-63`, and decisions at `.planning/STATE.md:109-112`.

After successful verification:

- update `last_activity` and current position from "verification plan pending" to verification/closeout complete,
- remove or replace the pending todo to plan Phase 153,
- add a decision/roadmap note that v1.33 verification passed with static brandbook evidence only,
- keep the Phase 153 boundary decision at `.planning/STATE.md:112`: no runtime UI, registry, component library, build pipeline, or committed raster export batch.

### `.planning/PROJECT.md` (project rollup, transform)

**Analog:** current milestone block at `.planning/PROJECT.md:11-23` and active requirements at `.planning/PROJECT.md:432-439`.

This file is a rollup, not the authoritative verification record. If workflow status updates touch it:

- update current state from "milestone-level verification pending" to v1.33 verified/closed,
- mark `BRAND-QA-02` complete in the active requirement list,
- avoid expanding "Next milestone goals" into public rollout work unless a new milestone is explicitly opened.

Note: `.planning/REQUIREMENTS.md` is cleaner for v1.33 truth than the active requirement checklist in `PROJECT.md`, which still has some stale unchecked rows for already-completed Phase 150 items. Do not use stale `PROJECT.md` checkboxes as a reason to reopen Phase 150 scope.

### `.planning/milestones/v1.33-MILESTONE-AUDIT.md` or equivalent closeout record (milestone audit, batch/rollup)

**Analog:** `.planning/milestones/v1.32-MILESTONE-AUDIT.md`

If the closeout workflow requires a milestone audit, use the v1.32 structure:

- frontmatter: `milestone`, `name`, `audited`, `status`, `requirements`, `phases`,
- `## Verdict`,
- `## Requirement Audit`,
- `## Integration Audit`,
- `## Risks Accepted`,
- `## Closeout Readiness`.

For v1.33, the requirement audit should cover the six v1.33 requirements and cite Phase 150-153 artifacts. Integration audit should explicitly say the brandbook direction is approved for later rollout decisions, not that README/HexDocs/landing/legal work is done.

## Source Reference Patterns

### Artifact boundary and token separation

Use `brandbook/README.md` as the source boundary:

- `brandbook/README.md:3-10` defines the repo-ready artifact set as HTML, Markdown, JSON, CSS, and SVG and names the light logo role.
- `brandbook/README.md:14-18` says to prefer text/SVG artifacts, avoid generated PNGs unless needed, avoid duplicate fonts, and treat `lib/threadline/operator_surface/style.ex` as the runtime UI contract.

This supports `D-08` and `D-09`: do not mutate `brandbook/` visuals without a blocker and do not bridge static brandbook tokens into runtime operator-surface tokens.

### Direct-open static page

Use `brandbook/index.html` as the browser evidence surface:

- `brandbook/index.html:1-10` is a static HTML document with local favicon and `tokens.css`.
- `brandbook/index.html:221-252` shows local rail/logo/hero links and the `Threadline Brandbook` first viewport content.
- `brandbook/index.html:350-362` verifies dark/light logo roles in rendered asset cards.
- `brandbook/index.html:432-456` records the source artifact plan, including HTML, Markdown, JSON, CSS, SVG, and examples.
- `brandbook/index.html:475-477` states "Source assets only. No external dependencies. No binary bloat."

### Current brand truth and copy-regression scan

Phase 152's scan pattern is the closest copy-regression analog: `.planning/phases/152-targeted-revisions/152-VERIFICATION.md:18`. Expected matches can include CSS selector text such as `::before`; classify those separately instead of failing the run automatically.

Useful source truth lines:

- `brandbook/brand-book.md:5-19` owns the core positioning and tagline.
- `brandbook/brand-book.md:176-204` owns logo-system roles.
- `brandbook/pressure-test.md:86-104` owns the readiness scorecard and token-lane warning.
- `brandbook/pressure-test.md:177-180` preserves "export PNG only when a platform requires it."

## Non-Targets

Do not create or modify these in Phase 153 unless verification reveals a concrete blocker and the planner explicitly scopes the fix:

- `brandbook/` visuals, layout, logo concepts, or copy beyond blocker repair.
- `README.md`, HexDocs/ExDoc configuration, landing pages, social-card PNG exports.
- `lib/threadline/operator_surface/style.ex` or any runtime Phoenix/operator-surface code.
- npm/Vite/React/shadcn/Tailwind/browser-build tooling.
- legal/trademark artifacts.

## Implementation Notes For Planner

- Treat `153-UI-SPEC.md` as an approved guardrail, not a request to build UI. Its surface contract aligns with static direct-open brandbook verification.
- Use `find ... -print0 | xargs -0 ...` for SVG/file checks to avoid zsh unmatched-glob behavior.
- Record exact command output in `153-VERIFICATION.md`; prior evidence is only a template.
- If a check fails, stop at failed verification and do not mark `BRAND-QA-02` complete.
