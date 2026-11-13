---
phase: "252"
reviewed: "2026-11-13"
depth: "independent six-pillar actual-pixel review"
reviewed_revision: "e79f7837e6e9817e739933c85d9579f436f42446"
runtime_revision: "7cca0a1830949c31fec4a90d2719ef1f0fcb4056"
baseline_revision: "b1888177648ef468c6d2bfc1cc1645f860fd2e4b"
source_manifest: "/private/tmp/threadline-252-final-source-scope.json"
files_reviewed: 31
files_reviewed_list:
  - AGENTS.md
  - .planning/conventions/research-verification-and-efficiency.md
  - brand/BRAND.md
  - brand/brand.json
  - brand/assets/README.md
  - .planning/phases/252-complete-operations-and-connected-catalog-review/252-UI-SPEC.md
  - .planning/phases/252-complete-operations-and-connected-catalog-review/252-CONTEXT.md
  - .planning/phases/252-complete-operations-and-connected-catalog-review/252-PAIR-EVIDENCE.md
  - .planning/phases/252-complete-operations-and-connected-catalog-review/252-01-SUMMARY.md
  - .planning/phases/252-complete-operations-and-connected-catalog-review/252-02-SUMMARY.md
  - .planning/phases/252-complete-operations-and-connected-catalog-review/252-03-SUMMARY.md
  - .planning/phases/252-complete-operations-and-connected-catalog-review/252-04-PLAN.md
  - .planning/phases/251-complete-investigation-and-inspection-screens/251-UI-REVIEW.md
  - lib/threadline/operator_surface/live/export_status_live.ex
  - lib/threadline/operator_surface/live/export_status_live/components.ex
  - lib/threadline/operator_surface/live/retention_history_live.ex
  - lib/threadline/operator_surface/live/retention_history_live/components.ex
  - lib/threadline/operator_surface/ui/overlay.ex
  - lib/threadline/operator_surface/ui/page.ex
  - lib/threadline/operator_surface/style/01_tokens.css
  - lib/threadline/operator_surface/style/02_base_shell.css
  - lib/threadline/operator_surface/style/03_page_home.css
  - lib/threadline/operator_surface/style/04_controls.css
  - lib/threadline/operator_surface/style/05_feedback.css
  - lib/threadline/operator_surface/style/06_layout_primitives.css
  - lib/threadline/operator_surface/style/08_overlays_motion.css
  - lib/threadline/operator_surface/style/09_responsive.css
  - examples/threadline_phoenix/storybook/operations/exports.story.exs
  - examples/threadline_phoenix/storybook/operations/retention.story.exs
  - examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex
  - examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts
findings: 5
status: "findings-open"
---

# Phase 252 — UI Review

**Audited:** 2026-11-13  
**Baseline:** Approved [252-UI-SPEC.md](252-UI-SPEC.md), signed-off `brand/` identity, and Phase 251’s accepted shell. The frozen source manifest was reviewed at `e79f7837e6e9817e739933c85d9579f436f42446`; the actual current runtime/pixels are bound to `7cca0a1830949c31fec4a90d2719ef1f0fcb4056`. The manifest records only a later test-predicate/planning change after the runtime revision.  
**Screenshots:** Existing selected PNGs inspected directly; this review created no captures.  
**Interaction captures:** The supplied after selection includes Retention preview and open-confirmation views, including top and initial-focus/scroll positions. The confirmation token is empty and neither action was clicked. No live error/loading/zero-preview action state, cancel/submit result, zoom, native clipboard, or hosted state was visually captured.

## Evidence boundaries

The four matched default scenes are Export and Retention at 1280×900 dark and 375×900 light. The before capsule is `before-01.json`; after is `after-03.json`, selected by `selected-after.json`. Both use Chromium 148.0.7778.96 and the same ordinary materialization: 239 AuditChanges, 147 AuditTransactions, 3 referenced AuditActions, 5 ExportJobs, and 4 RetentionRuns. The actual capture clocks differ: before is around 2026-11-13 10:24:50–51 UTC; after is around 12:49:09–12 UTC. No frozen-clock equivalence is claimed. The before capsule’s raw theme field is null due to a selector error; the retained original PNGs visibly show the intended dark/light lanes, and the after capsule asserts its theme. Four defaults pair; preview, confirmation, and catalog are ten after-only scenes with no before equivalent.

Catalog PNGs are static PhoenixStorybook projections, not live route, authorization, query, download, persistence, or mutation proof. The five current catalog smoke outcomes reported by the phase were reused from the earlier unchanged static owners; the current after-only catalog captures are visual evidence, not proof of those behaviors. The two mounted Retention mutation cases, Export route tests, and root/example tests are separate behavioral evidence described in [252-03-SUMMARY.md](252-03-SUMMARY.md). They do not convert uncaptured states into pixel evidence. Storybook smoke reported no horizontal overflow at 320, 375, and 768px; no PNG was captured at 320 or 768px.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|------:|-------------|
| 1. Copywriting | 2/4 | A failed run with no recorded deletion count says that 0 rows were deleted; live preview-loading copy also differs from the contract. |
| 2. Visuals | 2/4 | The mobile sticky shell overlays the destructive dialog title/intro; Retention sections also meet without breathing room. |
| 3. Color | 4/4 | The inspected dark/light route pixels use the approved grounds, surfaces, text, restrained accent, status, and destructive colors. |
| 4. Typography | 4/4 | The actual route screens follow the 12/13/16/28px hierarchy and regular/semibold weights; IDs and timestamps remain visually distinct. |
| 5. Spacing | 2/4 | Retention’s scope, action, preview, and history blocks touch at their edges instead of using the declared section rhythm. |
| 6. Experience Design | 2/4 | The modal opens with a focused confirmation field and mounted flows have separate behavior proof, but mobile shell chrome hides the dialog’s context. |

**Overall: 16/24**

Scores use the requested 0–4 review scale. A score of 0 means no supportable evidence; every pillar here has evidence, including the passing color and type observations.

## Top 3 Priority Fixes

1. **WARNING — Required correctness fix: preserve unknown outcomes.** `components.ex:141-144` turns a missing persisted count into `0`; `fixtures.ex:386-390` gives a pending-only partial story the ordinary fixture’s completed timestamp. The actual failed row contradicts its “No deletion count recorded” cell by saying “0 rows were deleted”; the static partial fixture also needs a “No completed run yet” value. Keep missing count/time distinct from recorded zero/completion in both render data and summary copy.
2. **WARNING — Required UI fix: put the confirmation above sticky shell chrome.** The 375×900 light top/focused dialog PNGs show the mobile topbar/navigation covering the dialog title and introductory copy. Put the modal/scrim above the sticky shell, or suspend shell chrome while the modal is open, then check both dialog positions.
3. **WARNING — Small contract-copy fix: use the specified live loading announcement.** `retention_history_live/components.ex:117` announces “Generating retention preview…” while the approved interaction contract specifies “Previewing retention estimates…”. Keep `role="status"` and align the text.

**Polish (nonblocking):** Add 16–24px vertical spacing between Retention’s scope, preview action/content, and history groups. The current edges touch in both paired viewport screenshots; use existing spacing tokens and do not add a token.

## Detailed Findings

### Pillar 1: Copywriting (2/4)

- **WARNING — Required correctness fix.** `lib/threadline/operator_surface/live/retention_history_live/components.ex:140-148` sets `deleted = run.deleted_count || 0`, then includes that number in the failed-run sentence. The visible failed row in `after-03-1280-dark-retention.png` gives contradictory facts: “No deletion count recorded” and “0 rows were deleted before the failure.” A missing count is not evidence of zero. Preserve `nil` in the failure summary and use unknown/unrecorded wording for that branch; retain numeric grammar only for recorded counts. This affects the shared LiveView and static history renderer.
- **WARNING — Contract wording.** `components.ex:117` uses a valid status role but the phrase “Generating retention preview…” rather than the specified “Previewing retention estimates…”. This loading state has source and static-projection evidence only; no live loading-state PNG was supplied.
- **WARNING — Static partial fixture summary is false.** `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex:305-315,386-390` creates a pending-only partial run, then borrows `ordinary.completed_at` as “Latest completed run” whenever `runs != []`. Derive this summary from a run whose persisted status is completed and render “No completed run yet” for the pending-only scenario. This is source-derived; the selected partial catalog viewport does not show its run-history summary.
- The matched Export view names the job groups and actions clearly, exposes status words with color, and distinguishes “Not completed”/“No expiration” from populated values. Its ordinary screen is visually readable at both matched widths. The Static Export story adds a clear “static example” qualification to its error projection.

### Pillar 2: Visuals (2/4)

- **WARNING — Required UI fix.** `after-03-375-light-retention-confirmation-top.png` shows the sticky mobile brand bar and Audit navigation painted over the modal heading and opening copy. The actual stack order explains it: the topbar is z-index 60 and shell navigation 59 (`style/02_base_shell.css:117-120,215-220`), while the modal container is z-index 50 (`style/08_overlays_motion.css:155-160`; tokens at `style/01_tokens.css:128-133`). The user can reach the focused input and actions, but the confirmation context is partly hidden. Stack the dialog and scrim above shell chrome or suppress sticky chrome while it is open; keep the title and first description lines unobstructed in both top and initial-focus views.
- **Polish.** In `after-03-1280-dark-retention.png` and `after-03-375-light-retention.png`, the scope card touches the Preview retention control; the after-only preview screen shows the preview card touching its action row and the first history metric. There is no visible separation between these related blocks. Source children are adjacent at `retention_history_live.ex:358-373`; `.tl-page__actions` only defines its internal button gap (`style/03_page_home.css:285-290`). Wrap the page sections/actions in an existing stack with the declared spacing rhythm.
- The ordinary Export layout has a clear primary content column, grouped jobs, readable action hierarchy, and consistent shell. The Retention preview is visually legible but the mobile dialog overlap and crowded page transitions keep this pillar below contract.

### Pillar 3: Color (4/4)

- The matched dark route images use Threadline Black as the ground with Graphite/raised panels and Fog text; the light images use Paper with light cards and Ink text. These match the phase contract and approved brand tokens (`style/01_tokens.css:42-83,192-214`).
- Blue is restrained to selected navigation, links, focus, and the logo thread. Success/failure status words remain visible beside their semantic colors; destructive red appears on failure/destructive affordances. No accent-dominant panel, logo misuse, or theme inversion was observed in the inspected route pixels.

### Pillar 4: Typography (4/4)

- The sampled route hierarchy uses 28px headings, 16px body/control copy, 13px dense metadata/IDs, and 12px labels with 400/600 interface weights (`style/01_tokens.css:15-39`; page, card, and table rules in `style/03_page_home.css` and `style/06_layout_primitives.css`). The operations views do not use the 32px display token.
- IDs use monospace and middle elision remains paired with Copy/Show full controls. Timestamps and metric counts use tabular numerals. The mobile page and preview copy wrap without an observed clipped text line. This is limited to the inspected 375×900 and 1280×900 screens, not every long-text fixture.

### Pillar 5: Spacing (2/4)

- **WARNING — Polish.** The Retention route’s scope panel, Preview control, preview panel/action row, and history metrics have zero inter-group gap in the supplied after pixels. The source places these nodes consecutively (`retention_history_live.ex:358-373`) and the action wrapper’s `gap` only spaces buttons (`style/03_page_home.css:285-290`). Add a wrapper using existing 16/24px or 32px section tokens, consistent with `252-UI-SPEC.md:54-68`. Keep the dense table’s declared 12/20/40px exceptions.
- Export job cards, table rows, modal internals, and the two matched route page margins otherwise use the existing scale. No arbitrary pixel/rem spacing was found in the reviewed operations markup. The visual score is driven by the page-level Retention joins, not the shared token set.

### Pillar 6: Experience Design (2/4)

- The source and plan receipts cover loading/empty/error/loaded states, accessible status/error semantics, cancellation, server-held preview authority, no-replay on disconnect/reconnect, and deliberate confirmation. The supplied dialog pixels show the initial focus ring on the required text field; they do not show a cancel, invalid-token, or successful submit state because neither modal action was clicked.
- **WARNING — Required UI fix.** The mobile sticky shell covers the dialog title/intro in the top view. This hides why the operator is being asked to type the policy name while the dialog remains active. Correct the layer order and inspect the actual confirmation views after the change.
- Live errors, disabled cleanup, valid zero preview, preview denial/restart, browser zoom, native clipboard, and real host permissions are not visually established by these PNGs. Static story states and owning tests remain separate evidence. No human UAT or live host claim is made.

## 30 UI-SPEC Criteria Review

`Source/static proof` means the relevant renderer or fixture is present and bounded tests are reported by the phase. It does not mean a static projection proves a live query, host permission, write, or lifecycle. `Pixel` identifies an inspected screenshot or says when no relevant live-route screenshot was supplied.

| Surface / criterion | Assessment and evidence boundary |
|---|---|
| U1 Export — empty | **Partial:** `export_status_live.ex:220-230` has the contracted heading/body/Timeline action. Empty copy is visible in the after static catalog sample; no live empty-route capture. |
| U1 Export — loading | **Partial:** live `role="status"` loading is in `export_status_live.ex:205-206`; the catalog shows a static pending projection, not a live read. |
| U1 Export — error | **Partial:** live safe error and Refresh action are at `export_status_live.ex:208-217`; the catalog error projection is visible, but no live failed-read PNG. |
| U1 Export — populated | **Pass in sampled state:** paired route PNGs show five actual seeded jobs, grouped by readiness, with status words, timestamps, source return, and completed-only download. |
| U1 Export — partial | **Partial:** paired route shows “Not completed” and “No expiration” for incomplete jobs; static/source states cover other missing metadata, not all pixels. |
| U1 Export — overflow | **Pass in sampled widths:** both matched route images report zero horizontal overflow. Catalog smoke additionally covered 320/375/768px; only 375 and 1280 have reviewed PNGs. |
| U1 Export — zero/one/many | **Partial:** actual view has one ready job, two preparing jobs, and five total; empty/zero/many alternatives are static fixtures, not live route captures. |
| U1 Export — long text | **Partial:** mobile view elides a long actor reference and shows Copy/Show full controls. The expanded full-value state and longest fixture are not pictured. |
| U2 Retention — empty | **Partial:** live empty-state copy and always-available Preview action are in `retention_history_live.ex:369-394`; the empty route itself is not pictured. |
| U2 Retention — loading | **Partial / copy deviation:** status semantics are present at `components.ex:117`, but the live phrase does not match the contract. Only the static pending projection was pictured. |
| U2 Retention — error | **Partial:** live no-count `role="alert"` recovery copy is at `components.ex:117-119`; static error/denied projections are pictured, not a live target/read failure. |
| U2 Retention — partial | **Partial:** component distinguishes cleanup-disabled from zero at `components.ex:123-129`; partial fixture is static. No live disabled-cleanup preview PNG. |
| U2 Retention — overflow | **Pass in sampled state:** live preview is legible at 375 and 1280 with zero reported horizontal overflow; 320/768 evidence is Storybook smoke only. |
| U2 Retention — long text | **Partial:** confirmation wraps and scrolls in the mobile view, with input/actions reachable in the focused state. No long identifier/timestamp scenario is pictured. |
| U3 History — empty | **Partial:** `retention_history_live.ex:389-394` distinguishes no runs from preview; only the static empty projection exists in catalog pixels. |
| U3 History — loading | **Partial:** the LiveView has a separate run-history loading branch at `retention_history_live.ex:375-378`; no live pending-history pixel. |
| U3 History — error | **Partial:** live safe recovery copy and Refresh action are at `retention_history_live.ex:378-388`; no live history-read error screenshot. |
| U3 History — populated | **Pass in sampled state:** matched route images show recorded completed, failed, and queued runs, exact recorded values, timestamps, statuses, and Review evidence actions. |
| U3 History — partial | **Fail:** the failed run has no recorded count, but its visible outcome says 0 rows were deleted (`components.ex:140-148`; actual failed row in `after-03-1280-dark-retention.png`). Separately, the static pending-only partial fixture borrows a completed timestamp (`fixtures.ex:305-315,386-390`); this latter finding is source-only in the supplied viewport. |
| U3 History — overflow | **Pass in sampled state:** no horizontal overflow at 375/1280; catalog width smoke covered 320/375/768. Scroll/reachability for every row is not established by viewport PNGs. |
| U3 History — zero/one/many | **Partial:** ordinary history has four records and count summaries; zero/many fixtures exist, but live zero/many states are not captured. |
| U3 History — long text | **Partial:** visible mobile run ID wraps/elides with Copy/Show full affordances; the longest fixture and expanded state are source/static evidence only. |
| U4 Catalog — empty | **Partial:** static story emits empty projections; a portion is visible in `after-03-1280-dark-catalog-exports.png`, not a live route state. |
| U4 Catalog — loading | **Partial:** the static pending label is visible in both catalog samples; it correctly says no new read completed. |
| U4 Catalog — error | **Partial:** static error projections are visible in the Export and Retention samples; the copy discloses the projection and does not establish a live failure. |
| U4 Catalog — populated | **Partial:** stories reuse production read-only renderers with deterministic assigns. Current viewport captures show only portions of these long static pages; no SQL/query result is implied. |
| U4 Catalog — partial | **Fail in source projection:** the visible partial preview is a static example. Its pending-only history also borrows the ordinary completed timestamp (`fixtures.ex:305-315,386-390`); the run-history summary is below the supplied viewport and was not visually observed. |
| U4 Catalog — overflow | **Pass for reported smoke:** the phase reports no horizontal overflow across story smoke at 320/375/768. Current images show 375 and 1280 only. |
| U4 Catalog — zero/one/many | **Partial:** separate static zero/many fixtures and story rendering exist; the selected catalog viewport does not show each case in full. |
| U4 Catalog — long text | **Partial:** the fixture/story supplies long references; the selected catalog images do not show the full long-text sample. |

## Registry Safety

Not applicable: the approved UI-SPEC declares `shadcn_initialized: false`, no third-party registry, and manual Phoenix components.

## Files Audited

Repository guidance/design: `AGENTS.md`; `.planning/conventions/research-verification-and-efficiency.md`; `brand/BRAND.md`; `brand/brand.json`; `brand/assets/README.md`; Phase 252 `UI-SPEC`, `CONTEXT`, `PAIR-EVIDENCE`, summaries 01–03, and plan 04; prior `251-UI-REVIEW.md`.

Implementation/presentation: `lib/threadline/operator_surface/live/export_status_live.ex`; `lib/threadline/operator_surface/live/export_status_live/components.ex`; `lib/threadline/operator_surface/live/retention_history_live.ex`; `lib/threadline/operator_surface/live/retention_history_live/components.ex`; `lib/threadline/operator_surface/ui/overlay.ex`; `lib/threadline/operator_surface/ui/page.ex`; `lib/threadline/operator_surface/style/{01_tokens,02_base_shell,03_page_home,04_controls,05_feedback,06_layout_primitives,08_overlays_motion,09_responsive}.css`; `examples/threadline_phoenix/storybook/operations/{exports,retention}.story.exs`; `examples/threadline_phoenix/lib/threadline_phoenix_web/storybook/fixtures.ex`; `examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts`.

Images viewed directly from `/private/tmp/private252evidence/`: four before/after paired defaults; `after-03-1280-dark-retention-preview.png`; `after-03-375-light-retention-preview.png`; desktop and mobile Retention confirmation plus confirmation-top variants; desktop/mobile dark catalog Export and Retention samples. These paths are private run artifacts; the repository keeps only this evidence-bound review.
