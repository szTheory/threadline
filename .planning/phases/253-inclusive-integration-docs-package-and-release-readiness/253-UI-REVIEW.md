---
phase: "253"
reviewed: "2026-11-13"
depth: "independent six-pillar visual, source and copy review"
reviewed_revision: "decaf3e6b33c799e7543e1acdabc9c2c738a7b84"
runtime_revision: "decaf3e6b33c799e7543e1acdabc9c2c738a7b84"
original_reviewed_revision: "4f35334f20fc4c8a89ac46d446b9fbb3b6b46672"
original_runtime_revision: "79e74fc4f16f125fe20b5bcb0db09bc2a047c26a"
baseline_revision: "74fe8df2b2520868d464eca93054492fc93a2cad"
status: "changes-requested; required real browser zoom proof remains blocking"
score: 19
score_max: 24
original_score: 16
original_findings: 8
open_findings: 2
delta: "changed-only source and ten current PNGs; F01 and F03 remain open"
---

# Phase 253 — UI Review

**Record structure:** the original 16/24 assessment and eight findings below are preserved. The current changed-only assessment, score and remaining findings are in **Bounded delta 1** at the end; frontmatter reflects that latest assessment.

**Audited:** 2026-11-13
**Baseline:** approved [UI-SPEC](253-UI-SPEC.md), approved brand, and retained Phase 252 appearance.
**Screenshots:** captured by the parent; all 17 supplied PNGs actually opened with `view_image` in this review. No new capture or app/browser/test launch by this reviewer.
**Interaction captures:** supplied packet contains copy-feedback, row-history drawer, ready preview, empty-token dialog/initial focus, focused forced-colors Apply, and embedded-host states. These are post-interaction appearances, not independent execution by this reviewer. The forced-status image has the limitation in F02. Real 200% tab zoom is not captured or proven.

**Verdict:** the narrow heading-family and control-container changes are supported by the viewed pixels and source. Acceptance remains blocked by missing real tab-zoom proof. The review also identifies one capture discrepancy, one current-document omission and five inherited UI quality issues. Inherited observations are not newly introduced regressions or permission to rebuild the interface. Parent disposition must reconcile them with the retained density/scope policy. This is independent automated judgment, not observed human comprehension or comprehensive accessibility conformance. Required exact-candidate CI and REL-01 remain pending separately.

## Pillar Scores

Scores describe the implementation actually rendered, including inherited issues; they are not rounded upward because the change itself is small. Scale is 0–4, with 0 reserved for absent/unassessable implementation; no pillar is absent here.

| Pillar | Score | Key finding |
|---|---|---|
| Copywriting | 3/4 | Precise retention/migration language; current asset guide omits the heading font (F07). |
| Visuals | 3/4 | Clear operation/status grouping; repeated Transaction headings compete on mobile (F05). |
| Color | 3/4 | Calm two-theme hierarchy and words/shapes; copy success reuses correlation-only Cyan (F06), and one forced-status capture is visually inconsistent (F02). |
| Typography | 3/4 | Page titles now use loaded Familjen 28/600; consequential scope prose remains 12px instead of the declared body role (F08). |
| Spacing | 2/4 | Control containment improves, but wrapped references and tall preview/dialog composition impair scanning and action discovery (F03–F04). |
| Experience Design | 2/4 | Preview-first safeguards and named states exist; required real 2× zoom remains unproven (F01). |

**Overall: 16/24**

## Top 3 Priority Fixes

1. **F01 — Complete the real browser-tab zoom acceptance boundary.** Default-zoom images and viewport reflow cannot establish the required ordinary and retention jobs at 200%. Obtain successful exact-tab `chrome.tabs.getZoom() === 2` receipts for the existing two desktop declarations through an authorized execution path. Respect the capped local diagnostic; do not renew attempts implicitly.
2. **F02 — Reconcile the forced-status image with the intended emulation.** Retain the original image and receipt. Supply one settled after-navigation forced-colors status capture with actual system-color measurements, or mark visual forced-status evidence missing. A matching media flag alone does not repair contradictory pixels.
3. **F03 — Keep the abbreviated identifier on one line within its owner.** The Retention Run column breaks an already shortened ID into four or five lines. Constrain/elide its visible code with a usable column width while retaining full copy/disclosure text and intentional table scrolling; verify the affected 1280, narrow, and 640-host states without widening the document.

## Detailed Findings — severity order

### F01 — BLOCKER: required real 200% browser-tab zoom has no successful result

- **Pillar:** Experience Design. **Scope:** Phase 253 acceptance gap, not a demonstrated product failure at zoom.
- **Owner/reference:** `examples/threadline_phoenix/e2e/tests/operator-zoom-proof.spec.ts:15` and `:161`; `253-UI-SPEC.md:120` onward; [sampling](253-SAMPLING.md).
- **Route/state/trigger:** the ordinary investigation and `/audit/policy/retention` preview/dialog jobs after setting the exact owned tab to zoom factor 2.
- **Evidence/consequence:** every supplied manifest says factor 1 and explicitly disclaims real-zoom proof. The isolated full-Chromium attempt stopped before its zoom assertion. Neither a 375px screenshot nor the 640px host slot establishes browser zoom or its interaction effects. This leaves a mandatory acceptance condition unverified.
- **Remedy:** retain the failed attempt and current stop; execute the existing real-tab helper only through the next authorized, bounded path, with exact URL/tab identity and control/focus/overflow observations. Keep this blocker open until actual success. No request for human UAT follows.

### F02 — WARNING: forced-status PNG does not visually establish its named forced-colors state

- **Pillar:** Color/evidence. **Scope:** new Phase 253 capture discrepancy; no conclusion that production forced-colors support is broken.
- **Owner/reference:** `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts:1497`–`:1532`; supplied `threadline-253-pairs-after-01/captures.json`, checkpoint `after-only-forced-status`.
- **Route/state/trigger:** `/audit/policy/retention`, Failed status after navigation with forced-colors requested.
- **Evidence/consequence:** the actually viewed PNG retains Graphite surfaces, brand-colored status dots and blue links; the forced-focus PNG visibly uses system black/white/yellow/cyan. Status metadata reports `forcedColors: true` but `colorScheme: dark`, whereas forced-focus reports `light dark`. The status full-page capture also positions the sticky shell across the page middle. This is insufficient visual evidence for the named emulated state. The existing executable test observes a visible word and nontransparent border, but does not record the status media match or compare its color to a system-color sentinel after navigation.
- **Remedy:** preserve this original evidence; reapply/settle emulation after navigation and bind the resulting image to the status's actual media match and computed system colors. Otherwise classify this checkpoint as visually unproven. Full-page sticky composition is a capture limitation, not by itself a live-shell defect.

### F03 — WARNING: middle-elided identifiers still wrap into multiple lines

- **Pillars:** Spacing and Typography. **Scope:** inherited; present in both before and after images.
- **Owner/reference:** `lib/threadline/operator_surface/live/retention_history_live/components.ex:76`; `lib/threadline/operator_surface/ui/display.ex:183`; `lib/threadline/operator_surface/style/06_layout_primitives.css:624` and `:638`.
- **Route/state/trigger:** populated `/audit/policy/retention` at 1280×900 Dark; also abbreviated actor/row references in the after-only 640px host Timeline.
- **Evidence/consequence:** `retention_run/…` is middle-shortened but then broken across four or five lines in the desktop Run column. The 640-host Timeline similarly splits shortened references. `.tl-secondary-ref` and `.tl-ref` permit `overflow-wrap: anywhere`; full-value recovery exists, so this is not data loss, but it contradicts the explicit no-wrapping abbreviated-ID contract and makes comparison slow.
- **Remedy:** constrain the abbreviated code and preserve a single line; use a suitable minimum Run column or bounded table scroll, and retain the exact full-value copy/disclosure. Do not prevent arbitrary genuine field values from wrapping globally.

### F04 — WARNING: preview spacing hides the next actions below the initial view

- **Pillar:** Spacing. **Scope:** inherited; present before and after.
- **Owner/reference:** `lib/threadline/operator_surface/live/retention_history_live/components.ex:120`; `lib/threadline/operator_surface/live/retention_history_live.ex:438`; `lib/threadline/operator_surface/style/06_layout_primitives.css:5`; `lib/threadline/operator_surface/style/08_overlays_motion.css:179`.
- **Route/state/trigger:** ready preview at 375×900 Light; open empty-token confirmation at 1280×900 Dark.
- **Evidence/consequence:** the mobile preview card occupies approximately y402–1030; the primary next step begins near y1047. In the desktop dialog the input sits against the lower visible edge and neither cancellation nor final-submit action is visible initially. The shared grid card combines its gap with raw paragraph/definition-list margins, producing large inter-paragraph gaps. The modal is internally scrollable (`overflow: auto`), so the screenshot does not prove unreachable actions; the issue is discovery and unnecessary scrolling in a high-risk flow.
- **Remedy:** give this existing preview component explicit child margins and spacing tokens; keep all scope/estimate caveats. Keep cancellation and confirmation controls readily discoverable, using the existing scroll owner or a local action footer if needed. Preserve focus visibility, Escape, trap and return behavior. No broad card or modal redesign is recommended.

### F05 — WARNING: duplicate mobile Transaction headings compete with the evidence

- **Pillar:** Visuals. **Scope:** inherited, unchanged composition.
- **Owner/reference:** `lib/threadline/operator_surface/live/transaction_live.ex:268` and `:278`; `lib/threadline/operator_surface/ui/page.ex:216`.
- **Route/state/trigger:** ordinary transaction detail at 375×900 Light.
- **Evidence/consequence:** the screen displays a 28px “Transaction” heading, then another large “Transaction 0bac2d25-10d” over two lines. Both announce the same context, consume substantial phone space and push the first change well below the initial viewport. The heading-family correction itself does not cause this duplication.
- **Remedy:** keep one clear page title and show the shortened transaction identity as supporting metadata or a compact detail label in this route. Preserve its exact full ID, copy, breadcrumbs and semantic heading order; avoid a blanket h1/h2 restyle.

### F06 — WARNING: Signal Cyan also means copy success

- **Pillar:** Color. **Scope:** inherited.
- **Owner/reference:** `lib/threadline/operator_surface/style/08_overlays_motion.css:380` and `:402`; `lib/threadline/operator_surface/style/01_tokens.css:91`.
- **Route/state/trigger:** ordinary Timeline after successful controlled actor-reference copy.
- **Evidence/consequence:** the viewed Timeline makes both the copied actor button and “Copied.” Cyan. The approved Phase 253 color contract reserves Signal Cyan for correlation IDs; this introduces a second meaning. Visible success words prevent a color-only accessibility failure, and the screen does not have accent-area overuse.
- **Remedy:** render generic copy success with the reading/neutral role or an explicitly approved success role; preserve the visible status text and double-success gating. Do not recolor correlation IDs or alter the clipboard boundary.

### F07 — WARNING: current asset documentation omits Familjen Grotesk

- **Pillar:** Copywriting. **Scope:** current document within the Phase 253 documentation refresh; inherited line remains stale.
- **Owner/reference:** `guides/operator-surface.md:471`; compare `guides/upgrade-path.md:185`, `priv/fonts/README.md:8` and current font source.
- **Route/state/trigger:** adopter reads Assets and Content-Security-Policy while assessing embedded fonts or opting out.
- **Evidence/consequence:** the bullet says only Geist and IBM Plex Mono are embedded. Current source and pixels include Familjen Grotesk for page headlines. This does not break CSP behavior, but the canonical asset inventory is incomplete precisely where the refresh promises approved font provenance.
- **Remedy:** name all three approved families and link the current brand asset owner. Preserve opt-out/fallback guidance, OFL history, stable anchors and technical API names; no font/package change is needed.

### F08 — WARNING: high-risk scope explanation uses label-sized text

- **Pillar:** Typography. **Scope:** inherited; not introduced by the new page-title rule.
- **Owner/reference:** `lib/threadline/operator_surface/live/retention_history_live.ex:360`; `lib/threadline/operator_surface/style/06_layout_primitives.css:60`; `lib/threadline/operator_surface/style/01_tokens.css:22`.
- **Route/state/trigger:** populated Retention history before preview, both themes, especially the 375px view.
- **Evidence/consequence:** the multi-sentence global-store/destructive-scope explanation is a paragraph with `.tl-card__body`, which resolves to the 12px label token. The contract assigns body prose 16px; this important explanation has the visual treatment of low-priority metadata. The modal repeats it in readable body text, so the disclosure is not absent.
- **Remedy:** apply the existing body size/line-height locally to this scope explanation, or explicitly reconcile its dense-role exception in the contract. Retain the approved 400/600 weights and unchanged compact preview title; do not churn all headings or dense tables.

## Pillar evidence and limits

### Copywriting (3/4)

The viewed Retention preview distinguishes sequential estimates, global worker-store scope and actual removals. Run history distinguishes missing counts, Queued, Failed and recorded completed values. Export failure gives a concrete source-search recovery action. Source has the exact Preview retention → Review and confirm → Prune now sequence, exact-policy requirement, cancellation, adjacent preview error and no-count error language. F07 is the remaining current-document inconsistency.

Changed README, example, module/package descriptions, integration/architecture/evaluation guides, migration and Unreleased notes preserve technical `OperatorSurface`, `threadline_operator_surface/2`, authorization/config/route names and incoming explicit anchors. The upgrade explains usable unary authorization, the literal intentional-public acknowledgement, transient preview versus checkpoints, mismatch refusal and host-owned recovery; `Pruner.trigger/0` remains unchanged. Current brand/fonts are clearly separated from superseded unshipped `brandbook/` and `priv/fonts/` history. Unreleased wording and checkout-versus-publication distinctions do not claim a release, CI acceptance or adopter understanding. Source/document inspection establishes these prose judgments, not execution of every example.

### Visuals (3/4)

Operation words, tables and actor/change content form a readable hierarchy in the ordinary Timeline; Retention preview and modal are distinct, and Exports separates Ready/Preparing/Needs attention/Unavailable. Both themed lockups are legible. Focus rings are visible on Close, the confirmation input and forced-colors Apply. F05 is a specific mobile hierarchy defect. Off-viewport content in full-page captures does not prove a live scrim/position bug.

### Color (3/4)

Viewed dark grounds/panels and light grounds/cards follow the intended dominant/secondary/accent hierarchy; no new palette was added by the three CSS edits. Repeated links, selection and controls use accent for their actual roles rather than decorative backgrounds. The contract describes role proportions, so this review does not invent exact 60/30/10 pixel measurements or treat a raw count of repeated links as overuse. Insert/Update/Delete/Redacted and all export/run outcomes have words; forced-focus retains words, outlines and control shapes. F06 violates the narrower Cyan role, and F02 limits status-state visual evidence. No comprehensive contrast audit is claimed from images or palette definitions alone.

### Typography (3/4)

All six changed checkpoints record a loaded Familjen 28px/600/33.6px page headline. The compact preview remains Geist 16px/600; monospace IDs/code remain distinguishable. The wide Timeline before record omitted computed headline family and is only an unchanged preservation reference. The changed CSS owners use token-backed 12/13/16/28 roles (one explicit mobile input 16px); their strong and medium weight aliases both resolve to 600, regular to 400. The unused 32px display token is not evidence of a rendered fifth size. F08 is the paragraph-role mismatch; F03 also harms identifier legibility.

### Spacing (2/4)

The three changed CSS owners retain existing space-token uses: 4/8/12/16/20/24/40px, within the approved dense exceptions. The only new layout behavior is a named inline-size control container and one-column tracks at available width ≤480px. Supplied 640-host measurements report host and surface width/clientWidth/scrollWidth all 640, document 1280, separately from the 320px checks. The 640 image visually confirms contained controls and visible Apply focus; the results retain bounded internal scrolling, which is expressly allowed. F03–F04 are substantial scanning/action-discovery problems even though the outer root does not overflow.

### Experience Design (2/4)

Source and supplied proof describe pending/loading/error/empty/stale/unavailable states, disabled submission, exact typed confirmation and final-only destructive intent. Drawer/modal composition provides named dialogs, initial focus, trapping, Escape/cancel and focus return. Supplied touch proof is separately measured at 375×900 with touch/no-hover; desktop375 PNGs are not touch evidence. Theme and reduced-motion results are selected boundary receipts; no native clipboard result is inferred from the controlled copy success. This reviewer did not run those cases, test authorization, delete data or download an export. F01 remains a real required gap; successful static rendering cannot close it.

## Coverage reconciliation — all 28 UI criteria

This table accounts for every authored row, without treating a criterion or existing inventory entry as a passed execution. **P** = viewed pixels for named populated state only; **S** = source inspected; **R** = supplied acceptance/receipt contribution, not rerun here; **L** = explicit limit. Original source/route/journey inventories remain authoritative.

| Category | Investigation (8) | Retention (8) | Exports (8) | Shell (4) |
|---|---|---|---|---|
| Empty | S/R: no-match vs unavailable; no empty-state PNG viewed | S/R: no runs vs preview error; empty-token dialog P | S/R: no jobs; no empty-job PNG | No authored row |
| Loading | S/R: pending query; not independently driven | S/R: preview loading/disabled; no loading PNG | S/R: persisted Running/Queued P does not prove refresh lifecycle | S/R: selected reconnect/theme; not independently driven |
| Error | S/R: correction/unavailable; no error PNG | S/R: adjacent preview/read error; Failed history P is a recorded outcome | P/S: failure recovery; download failure lifecycle remains R | S/R: unsupported/unavailable behavior; no failure PNG |
| Populated | P: committed query, transaction and history | P: history, ready preview and blank dialog | P: five jobs and completed-only Download affordance | No authored row |
| Partial | P/S: Redacted and raw snapshot fields; no arbitrary missing-data census | P/S: missing count distinct from zero; queued/failed meanings | P/S: incomplete timestamps/status availability distinct | No authored row |
| Overflow | P/R: actual640 host, separate320 result; F03; real2× L | P/R:375 preview and dialog scroll;320/640 R; F04; real2× L | P/R:1280 jobs, selected narrow results R; no narrow-export PNG | P/R: native narrow navigation, outer640 geometry; no every-route product |
| Zero-one-many | S/R: one transaction/two changes P; zero not freshly pictured | P/S: four runs and estimates225/133; genuine-zero/disabled cases R | P/S: group counts1/2/1/1; zero group R | No authored row |
| Long text | P/S: full-value recovery; F03; arbitrary stress R | P/S: failed prose/global caveats; F03–F04; stress R | P/S: source filter/title/status recovery; stress R | P/R: narrow navigation wrapping; arbitrary host names not pictured |

Eight investigation + eight retention + eight export + four shell rows = 28. No media surface was introduced. Static Storybook width checks establish their selected composition only; no catalog image stands in for a mounted job.

## Coverage reconciliation — all 16 surfaced edge rows

| Requirement/category | Review relevance and limit |
|---|---|
| ADM-26/empty | Blank confirmation is P/S; no-write/auth result belongs to separate server/DB proof, not this image. |
| ADM-26/encoding | Exact-policy source/selected backend contribution R; no normalization/lookalike acceptance inferred from pixels. |
| ADM-27/unclassified | Preserve unresolved engine assumption; actual container contribution assessed above, actual zoom separately BLOCKER F01. |
| ADM-28/unclassified | Preserve unresolved engine assumption; selected theme/touch/motion R, forced-focus P, forced-status L/F02. |
| ADM-29/unclassified | Preserve unresolved engine assumption; actual current prose independently reviewed, F07 remains. |
| ADM-30/unclassified | Preserve unresolved engine assumption; package bytes/optional integration are the separate package review, not image proof. |
| ADM-31/adjacency | Distinct IDs/states preserved; equal metadata or Timeline digest does not merge claims. |
| ADM-31/empty | Three after-only states remain after-only; no new image substitutes for a missing before. |
| ADM-31/ordering | Six changed pairs and the seventh preservation reference remain in named order with exact before directories. |
| ADM-32/adjacency | Existing generic source/semantic journey rows retain separate boundaries; this table creates no second product inventory. |
| ADM-32/empty | Missing actual zoom and disputed status pixels stay missing/limited; zero-selected or listed-only cases are not passes. |
| ADM-32/ordering | Failed and superseded receipts remain historical; parent owns final acceptance reconciliation. |
| ADM-33/unclassified | Preserve unresolved engine assumption; local receipts do not establish required exact-candidate CI. |
| ADM-34/adjacency | Local readiness, required CI, publication and REL-01 remain separate. |
| ADM-34/empty | No remote result is supplied as acceptance; pending stays pending. |
| ADM-34/ordering | Review → dispositions/records/fingerprint → genuine external authority → natural release obligation; no automatic release claim. |

The five unclassified rows and 18 descriptorless prohibitions retain their unresolved/flagged-unverified engine status. This review does not invent enforcement descriptors or human approval. Those annotations do not erase F01 or turn a real missing acceptance proof green.

## Evidence actually examined

All image names below were individually opened with `view_image`; the private capture directories are named without committed machine-local links. The manifests retain their image digests, real clocks, routes, exact state, browser148.0.7778.96/Playwright1.60.0, DPR1, served CSS/JS/font identities and parent/surface geometry.

| Actual directory | PNGs viewed | Scope |
|---|---|---|
| `threadline-253-pairs-before-03` | `ordinary-timeline.png`, `ordinary-transaction.png` |1280 Dark unchanged reference;375 Light transaction baseline |
| `threadline-253-pairs-before-04` | `ordinary-row-history.png`, `retention-history.png`, `retention-preview.png`, `retention-dialog.png`, `exports-statuses.png` | Remaining five baselines:1280 Dark history/dialog,375 Light preview,1280 Light exports |
| `threadline-253-pairs-after-01` | `ordinary-timeline.png`, `ordinary-transaction.png`, `ordinary-row-history.png`, `retention-history.png`, `retention-preview.png`, `retention-dialog.png`, `exports-statuses.png` | Corresponding seven after appearances; six changed title pairs plus one unchanged preservation reference |
| `threadline-253-pairs-after-01` | `after-only-forced-focus.png`, `after-only-forced-status.png`, `after-only-host-640.png` | New-only states; F02 limits forced-status pixels; actual640 host inside1280 viewport |

The actual before runtime is `9887dc2e6001604b7575f935ffeb12423a7c3e2b`, with zero supplied visible-source differences from accepted252; it is not falsely named the accepted historical SHA. The after runtime is recorded above. Preview-generation clocks differ; no frozen-time or pixel-perfect temporal claim is made. The supplied comparison manifest preserves six typography comparisons, not seven. All 53 frozen source-file hashes were checked against this checkout and matched. Post-lint equivalence proves unchanged HEEx blocks in three renderers and unchanged three CSS files for pixel reuse only; changed handler/schema/filter behavior is not established by those bytes.

No screenshots were generated by this reviewer, so no capture directory or screenshot-gitignore mutation was needed or authorized. Supplied images reside outside the repository. No localhost detection, live-browser invocation, native clipboard operation, source change, commit, test or DB action was performed by this reviewer. Existing snapshot-guard PNGs are historical unchanged references, not a fresh snapshot-guard pass.

## Files Audited

- `AGENTS.md`; research/verification convention; current `brand/BRAND.md`, full `brand/brand.json`, `brand/assets/README.md`.
- Full `253-UI-SPEC.md` including Registry Safety; `253-CONTEXT.md`, `253-PAIR-EVIDENCE.md`, `253-SAMPLING.md`, `253-PROBE-RECORD.md`; relevant Plan10, summaries03/06/07/08, acceptance/validation boundaries.
- Changed copy in `README.md`, `CHANGELOG.md`, `DESIGN-SYSTEM.md`, `examples/threadline_phoenix/README.md`, `guides/operator-surface.md`, `guides/upgrade-path.md`, `guides/evaluating-threadline.md`, `guides/how-threadline-works.md`, `guides/integration-contracts.md`, `lib/threadline.ex`, `mix.exs`, `brandbook/README.md`, `priv/fonts/README.md`.
- Current composition and relevant CSS in `live/transaction_live.ex`, `live/row_history_live.ex`, `live/retention_history_live.ex`, `live/retention_history_live/components.ex`, `ui/page.ex`, `ui/display.ex`, `style/01_tokens.css`, `03_page_home.css`, `04_controls.css`, `06_layout_primitives.css`, `07_find_detail.css`, `08_overlays_motion.css`, `09_responsive.css` under `lib/threadline/operator_surface/`.
- Relevant changed accessibility/responsive/motion/zoom browser-owner sections; frozen source manifest, three capture manifests, capture comparison and post-lint render-equivalence record. Source inspection is bounded to this review's concerns; checking all53 hashes is not claiming a full security audit of all53 files.

Registry audit is inapplicable: `components.json` is absent and the full UI contract explicitly declares no shadcn/third-party registries. No registry command or dependency install was run.

## Original review and delta ownership

This is the original independent report at the frozen revision. Findings F01–F08 remain recorded for parent disposition and a bounded same-reviewer delta. No anticipated fix, recapture, passing package receipt or remote proposal closes a finding here. Priority fixes:3. Other recommendations:5. Parent owns source changes, acceptance disposition and next authorized execution; no maintainer acknowledgment is required merely to preserve the current stop.

## Bounded delta 1 — source and pixel corrections

**Reviewed:** 2026-11-13. **Source/runtime:** `decaf3e6b33c799e7543e1acdabc9c2c738a7b84`. **Delta baseline:** original reviewed source `4f35334f20fc4c8a89ac46d446b9fbb3b6b46672`, with its original after-capture appearance retained above. This is a changed-only assessment, not a new full audit or re-execution of the 28 UI/16 edge matrix. Original findings, evidence and 16/24 score remain historical rather than being rewritten as successful.

### Current score: 19/24

| Pillar | Original | Current | Changed-only basis |
|---|---|---|---|
| Copywriting |3|4|All three embedded families and current asset link now appear in the canonical CSP inventory; changed migration wording distinguishes static compile-time checks from opaque runtime refusal. No new copy defect found in this delta. |
| Visuals |3|4|The secondary Transaction identifier is now a compact 16px supporting heading, preserving its identity and page heading. Status/task hierarchy remains intact in the viewed replacements; the table allocation defect is scored under Spacing/Typography. |
| Color |3|4|Copy-success text/button/pulse use neutral reading/border roles. Fresh forced-status pixels visibly use system Canvas/CanvasText with status words and outlined shapes, consistent with the strengthened receipt. No new color defect found in this delta. |
| Typography |3|3|The risk scope paragraph now uses 16px body/line-body and page/compact headings retain approved roles. F03 still prevents the intended single-line middle-elided reference from remaining fully readable at mobile width. |
| Spacing |2|2|Preview child margins and dialog action discovery improve, and the additional900px host check passes; F03's nowrap-only remedy creates a substantial desktop Outcome-column squeeze and mobile clipped suffix. |
| Experience Design |2|2|Selected host/media/font proof is stronger, but required actual real200% tab zoom remains missing. Defaultzoom1 still cannot establish F01. |

### Finding disposition

| Finding | Current assessment | Evidence and practical limit |
|---|---|---|
| F01 | **OPEN — BLOCKER** | All ten new captures remain defaultzoom1. No successful exact-tab factor2 receipt was supplied. Existing capped local diagnostics and required-CI boundary remain; no waiver or new attempt is inferred. |
| F02 | **RESOLVED for supplied forced-status state** | Actually viewed fresh `after-only-forced-status.png`: white system canvas, black text/borders, visible Failed/Queued/Completed words and outlined shapes, top shell in its intended capture position. The owning test now reapplies/settles media after navigation and asserts status media match plus computed Canvas/CanvasText; its attached image is separate actual proof. Original contradictory PNG and failed collectors stay retained and insufficient. |
| F03 | **PARTIALLY FIXED — OPEN WARNING** | Desktop Run IDs now stay on one line, but the new allocation leaves Outcome about80px wide and breaks the Failed explanation into roughly17 lines. At375px the already middle-shortened Run code is hard-clipped at the right edge, hiding its suffix; full copy/disclosure remains, so no data loss is claimed. Original640-host Timeline actor/row wrapping remains inherited and unchanged. See targeted remedy below. |
| F04 | **RESOLVED for unnecessary preview spacing and desktop dialog actions** | Child paragraph/list margins are zero; the existing token gap separates estimates and caveats. The1280×900 dialog now visibly contains input focus, Keep audit data and Prune now. The375px ready card is more compact, but its actions still need ordinary vertical scrolling because the formerly12px scope prose is now readable16px. Required scope/caveat content is preserved; this review does not impose an invented above-the-fold guarantee or call that necessary scroll a defect. |
| F05 | **RESOLVED** | Actually viewed375px transaction: page title remains28px; supporting “Transaction 0bac2d25-10d” is one compact16px line rather than a competing two-line headline. Full metadata, breadcrumb and copy affordance remain. |
| F06 | **RESOLVED** | Actually viewed copy-success Timeline uses neutral Copied/button styling. Source also changes pulse origin to the neutral strong border. Controlled-copy appearance does not establish native clipboard behavior. |
| F07 | **RESOLVED** | `guides/operator-surface.md:471` now names Familjen Grotesk, Geist and IBM Plex Mono and links approved assets; existing history/opt-out/CSP boundaries remain. |
| F08 | **RESOLVED** | `03_page_home.css:430` applies16px body and line-body locally to retention-scope prose. Both new themed retention images visibly show the larger disclosure; no global heading/table restyle occurred. |

### F03 delta — remedy needs column allocation as well as nowrap

**Changed owner:** `lib/threadline/operator_surface/style/03_page_home.css:436` adds only `white-space: nowrap` to Retention reference code, whose inherited shared owner also sets `max-width:100%` and `overflow:hidden`.

**Route/state/trigger:** `/audit/policy/retention`, populated history at1280×900 Dark and ready-preview history at375×900 Light. The Failed row is actual ordinary fixture data, not stress content. The new forced-status image repeats the same layout problem in system colors, supporting that this is geometry rather than palette.

**Observed consequence:** the desktop Outcome column previously held a readable multi-word sentence over about6 lines; it now holds roughly1–3 words per line across about17 lines. The Run column absorbs about300px to satisfy nowrap, and failure recovery becomes much harder to scan. Mobile code is one line but ends in a hard cut rather than exposing the preserved suffix of its middle-elided value. Outer `scrollWidth` remaining equal to `clientWidth` does not establish readable columns or intact reference shortening.

**Least disruptive next fix:** keep nowrap but allocate a readable Outcome minimum/track within the existing bounded table-scroll owner on desktop. At the stacked mobile breakpoint, fit a genuinely shorter middle-elided reference or give its exact code a local accessible horizontal-scroll owner; do not silently clip its identifying suffix. Preserve full copy/disclosure and avoid a global nowrap rule or document overflow. Refresh only the affected desktop/mobile Retention pixels/column geometry. The inherited640-host Timeline reference issue stays explicitly limited unless its existing owner is deliberately included; it is not newly fixed by a Retention-only selector.

### Intermediate-host correction assessed

The control-container breakpoint changes480→812px in `09_responsive.css:563`, matching the documented four-track minima plus gaps. The existing host test now selects900 and640 parents at1280 viewport plus a separate320 viewport for Timeline and Retention. Supplied targeted browser results contain exactly the three host/font/forced-color declarations, all passed with retry0,0skips,0unexpected and0flaky; duration is2.900s. The retained initial900-host failure1089>901 is separate RED evidence, not deleted by the subsequent success. The new640-host PNG still shows contained controls and visible Apply focus; its internal results scrolling and original reference wrapping remain separate from the fixed outer-control containment.

### Delta evidence actually examined

- All eight source hashes in private `threadline-253-review-delta-01.json` were checked against this checkout and matched. Read the actual8-file diff, including both browser owners, the three CSS owners, both guide changes and upgraded guide-contract predicate. The migration correction removes invalid keyword presentation and narrows the compile-time claim; no public API name changes.
- **Actually opened all ten PNGs** in `threadline-253-pairs-after-review-01`: `ordinary-timeline.png`, `ordinary-transaction.png`, `ordinary-row-history.png`, `retention-history.png`, `retention-preview.png`, `retention-dialog.png`, `exports-statuses.png`, `after-only-forced-focus.png`, `after-only-forced-status.png`, `after-only-host-640.png`. Corresponding original after01 PNGs remain the prior viewed comparison states. Source/runtime for the replacements is the exact current revision above; images are new evidence, not relabeled old captures.
- Read the replacement manifest's route/state/viewport/theme/focus/container records. Normal repeated comparisons retain1280Dark/375Light/1280Light scope; three inclusive conditions remain after-only. The forced-status correction intentionally changes effective palette and settles navigation, so it repairs evidence rather than constituting a paired brand-color improvement. Real clocks differ; no frozen or pixel-perfect temporal claim.
- Read actual targeted browser results and strengthened status source: forced-colors must match at the status itself; computed status foreground/background must equal measured system CanvasText/Canvas, with a visible border/word. Passing is confined to those declared conditions, not blanket accessibility.
- Before/after-review-fix materialization records both bind the exact current revision and report no differences in all named rows across the same five audit/action/export/retention tables. This supports unchanged capture fixture identity only; it does not establish valid deletion or default cleanup.
- No new browser/app/test/DB/native-clipboard operation by this reviewer. No source changes beyond this report. No fresh snapshot-guard pass, native clipboard observation, human understanding, required exact-candidate CI or REL-01 completion is inferred.

**Current outcome:** six original warnings resolve within their assessed scope; F03 remains partial and F01 remains blocking. Two open findings, with one required-proof blocker and one layout warning; no new independent finding ID is invented for F03's directly resulting tradeoff. Parent owns the next targeted remedy and acceptance/CI disposition. The original28UI/16edge limits remain; F02's status-pixel limit is the one specifically superseded here.
