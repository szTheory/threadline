# Phase 238 — UI Review

**Audited:** 2026-10-09
**Baseline:** Abstract six-pillar standards, PRODUCT.md and approved Phase 238 principles; no UI-SPEC.md. Existing Phoenix/HEEx/CSS primitives, not Tailwind/shadcn.
**Screenshots:** Captured by the accepted source-bound CLI evidence lanes; existing final captures inspected in this audit. No new captures.
**Interaction captures:** off (workflow.ui_interaction_capture is false). Separately, accepted Playwright state captures and observations below provide bounded interaction evidence; they were not produced by the optional chrome-devtools driver.

This reviews unchanged current-main product UI. Phase 238 establishes evidence and follow-up ownership; it does not implement the refinements assigned to 239–243. A product shipping blocker below does not make an honest baseline incomplete. No routine maintainer UAT, paid critic, source edits or publication is required by this review.

## Pillar Scores

| Pillar | Score | Key Finding |
| --- | --- | --- |
| 1. Copywriting | 2/4 | Home promises every change has action/context; terminology and sentence case drift |
| 2. Visuals | 2/4 | Narrow history heading/Close is visually covered by persistent shell; candidate reachability defect |
| 3. Color | 3/4 | Coherent theme/status hierarchy, but paper/ink token aliases resolve empty |
| 4. Typography | 3/4 | Readable hierarchy with excess small type variants and dense secondary evidence |
| 5. Spacing | 2/4 | Long-filter Timeline expands the document far beyond 375 CSS px |
| 6. Experience Design | 1/4 | Fresh-entry Copy does not complete on Evidence, Exports or Retention |

**Overall: 13/24**

Scores describe the bounded baseline; none implies a universal contrast, keyboard, magnification or browser pass.

## Top 3 Priority Fixes

1. **BLOCKER: Make direct-entry Copy complete reliably** — exact identifiers cannot be handed off through the advertised control on three routes — Phase 240 should bind the shared helper through a reliable mount lifecycle, test fresh direct entry/reload and navigation separately, compare actual clipboard bytes, and expose actionable failure feedback.
2. **WARNING: Contain long-filter Timeline reflow** — inputs, Apply and active-filter content run outside the narrow viewport — Phase 239 should constrain grid/flex children and native date inputs, wrap long chips while retaining the complete value, and prove document width at 375px. Phase 240 should verify the investigation journey after the shared correction.
3. **WARNING: Reflect disconnected export availability** — the queue action remains enabled while the connection banner says otherwise — Phase 242 should block pointer/keyboard activation while disconnected, communicate recovery, and verify reconnect without lost or duplicate activation. A zero-job observation does not establish completion.

## Detailed Findings

### Pillar 1: Copywriting (2/4)

- **WARNING C1 — Rendered assertion exceeds recorded evidence.** Dark narrow home and System/light home say “Every change is connected to the action, context, and story around it.” `lib/threadline/operator_surface/live/start_live.ex:172` makes this unconditional. PRODUCT.md explicitly allows missing context and coverage. Replace it with wording that makes context conditional without conflating AuditChange and AuditAction. Owner: 239. This is this auditor's source/rendered judgment, not an additional browser behavior claim.
- **WARNING C2 — Related destinations use uneven vocabulary.** Narrow home presents “Check audit readiness,” the card button “Check coverage,” and navigation “Coverage”; `start_live.ex:218` anchors the card heading. Treat this as the baseline's canonical-label candidate, not proof the concepts must all share one label. Phase 239 should establish consistent destination names while retaining task-oriented descriptions. `start_live.ex:334` also uses “Open Timeline” where the main CTA uses “Open the timeline”; normalize sentence case and purpose.
- Useful existing copy is preserved: the observed long-filter empty state explains widening the time range/clearing filters and scope; Exports distinguishes preparing, failed and unavailable, with a concrete reopen-source recovery instruction. Generic “Copy” has specific accessible labels in `ui/display.ex:183`; its main defect is behavior, scored below.

### Pillar 2: Visuals (2/4)

- **WARNING V1 — Narrow history composition covers essential header content.** The actually viewed final `route.drawer__dark-375-shell.png` shows the history introduction and Close area beneath the persistent header/navigation. `style/08_overlays_motion.css:10` starts the fixed subview at `top: 0`; the subview also has a sticky header at line 30. The baseline separately records the same candidate for `route.row`. Owner: 240. Resolve the shell/subview stacking and inset contract, then verify header/Close visibility and keyboard/pointer reachability in both row and drawer contexts. This review confirms visible overlap in the drawer capture; it does **not** claim Close was activated or unreachable.
- The observed home has an identifiable primary Timeline action, subordinate Coverage/evidence destinations and visible health warnings. Desktop Exports uses grouped headings and textual statuses rather than undifferentiated cards. These positives do not erase the narrow composition gap.
- Candidate V1 is one defect across two contexts, not two separately proven failures. Full row interaction and every icon-only control remain limited by the acceptance inventory.

### Pillar 3: Color (3/4)

- **WARNING K1 — Token aliases are invalid despite resolving surface colors.** `style/01_tokens.css:44` and `:46` self-reference paper/ink; repeated theme declarations also self-reference them. Final dark and System/light theme observations report empty computed `--tl-color-paper` and `--tl-color-ink`, while background/text resolve. Owner: 239. Replace circular aliases with authoritative values or valid one-way aliases and assert computed values per preference/effective theme. This is confirmed token debt, **not** a demonstrated text-contrast failure.
- Inspected renders use neutral backgrounds/raised surfaces as the majority area, blue for navigation/actions, and green/red/amber for semantic status. The desktop unavailable export still says Completed for historical job status while separately saying Export expired; both labels are visible. No blanket color-only status failure was found in this sample.
- Source scan finds 40 accent-token references across style rules. This counts rules, not 40 unique visible elements; no arbitrary overuse deduction follows. No exact pixel-area 60/30/10 ratio or exhaustive contrast measurement was performed. Hardcoded palette literals are concentrated in the owning token file and should not be treated as component-level violations merely because they exist.

### Pillar 4: Typography (3/4)

- **WARNING T1 — Small-type vocabulary is more complex than the abstract standard.** `style/01_tokens.css:17`–`:25` declares nine size tokens, eight distinct numeric sizes (12, 13, 14, 15, 16, 20, 24, 32px); `sm` and `dense` duplicate 13px. Three weights are declared at lines 30–32 (400/500/600). All nine size token names appear in CSS use. Label size alone appears in 58 declarations, and xs in 10. Owner: 239. Consolidate adjacent small-text roles where their job is identical rather than indiscriminately reducing all useful heading levels.
- Visually, desktop Exports places requested-by identifiers, filter keys and timestamps in a dense secondary tier; home and drawer headings remain discernible. This is a minor reading/density concern for support users, not evidence that 13/14px automatically violates accessibility. Verify exact-value access and magnification before accepting further compaction. Owners: 239 shared type, 240/242 journey checks.
- Actual browser-chrome 200% zoom remains unverified; viewport resizing cannot establish enlarged-type readability.

### Pillar 5: Spacing (2/4)

- **WARNING S1 — Narrow long-value layout does not contain intrinsic widths.** The actually viewed final dark `state.timeline.empty-long-shell.png` clips date fields, the Apply control and the correlation chip. Its observation records `cssWidth: 375`, `scrollWidth: 1924`, a 232-character value and `fullValueRetained: true`. This is whole-document overflow, not an intentionally contained evidence scroller. Owner: 239 shared layout; 240 investigation acceptance. Audit filter grid/input sizing and chip wrapping together; preserve exact values. Source anchors: `live/timeline_live/filters.ex` and `style/04_controls.css:358`/`:382`. Existing `min-width: 0` declarations elsewhere do not prove this chain is constrained.
- **WARNING S2 — Local exceptions complicate the spacing scale.** Tokens use a 4px-derived scale at `style/01_tokens.css:5`–`:13`; most inspected padding/gaps consume it. `style/07_find_detail.css:331` uses `padding: 3px ...`, and overlay control rules include a fixed `min-width: 120px` at `08_overlays_motion.css:568`. These are source review candidates for deliberate optical/control exceptions, not additional reproduced overflow. Phase 239 should document or normalize justified exceptions.
- Narrow home spacing is orderly in the accepted render; drawer overlap belongs primarily to V1 and should not be counted as a second independent spacing defect.

### Pillar 6: Experience Design (1/4)

- **BLOCKER E1 — Advertised exact-copy task fails on fresh route entry.** Accepted `state.copy.evidence`, `.exports` and `.retention` observations in both theme lanes show no exact clipboard completion and no delegated handler; dark Evidence records `handlerBound: false`, `clipboardMatches: false`, `copiedFeedback: false`. Timeline is a separate exact-copy positive control. Source anchors: `script.ex:38`–`:65`, `ui/display.ex:178`–`:187`, `live/evidence_live.ex:123`, `live/export_status_live.ex:292`, `live/retention_history_live.ex:293`. Owner: 240, overriding provisional observation metadata. Fix before shipping the refined operator UI; presence of the button/helper is insufficient.
- **WARNING E2 — Disconnected export action communicates availability incorrectly.** Real pointer and keyboard offline observations find enabled queue activation (no disabled/aria-disabled/mutation marker, pointer events active). `live/export_status_live.ex:269` has the queue event with no connection-driven disabled state in the inspected button. Owner: 242. Reconnect samples add no new/duplicate jobs; this finding is about affordance and recovery truth, not a claimed duplicate or completed export. Timeline's distinct export activation remains limited.
- **WARNING E3 — Copy failure recovery is silent in source.** `script.ex:64`–`:65` flashes only success; failed Clipboard API plus failed fallback has no error instruction/native-selection recovery feedback. This is code-derived debt. Actual denial/unavailable Clipboard API behavior was not reproduced. Owner: 240 shared Copy; 243 proof.
- State coverage has genuine bounded positives: outbound LiveView query held/released for pending then empty; seeded failed/preparing/completed/expired export groups; real invalid-context alert; real host HTTP 403 for a read-only export GET; retention confirmation focus, Escape and focus return without prune; emulated Chromium touch navigation; reduced-motion media and one home animation. These are narrower than all-state acceptance. Owner 241 covers evidence/coverage/redaction; 242 export/retention/reconnect; 243 final integrated proof.

## Evidence and Limitations

Accepted evidence root: `examples/threadline_phoenix/e2e/artifacts/operator-evidence/` in the retained worktree. Only these final bundles support this review:

- `operator_close_routes_1791520842`
- `operator_close_dark_1791520998`
- `operator_close_light_1791521025`

Actually viewed here: route bundle dark home 375, drawer 375, Exports 1280; dark state bundle Timeline empty-long shell; light state bundle initial System/effective-light home shell. The eleven-route inventory and remaining state coverage are supported by the accepted index/observations, not a claim this auditor personally opened every PNG. Hash/source/served-asset custody is recorded in 238-EVIDENCE-INDEX.md; earlier bundles and provisional owner metadata are historical.

Authenticated preview proof on 4109 already passes; this audit's bounded HTTP detection also returned 200. No anonymous `/` screenshot substitutes for the operator shell. Raw PNG storage was verified ignored with `git check-ignore` before image inspection; no captures were created, so the new-capture gitignore gate was not needed and no additional storage files were written.

Actual browser-chrome 200% zoom is **unverified**: Computer Use was not approved to use Google Chrome for Testing. Clipboard denial/unavailability is **unverified**: the attempted denial still reported prompt/copied feedback; unbound controls did not attempt clipboard access. No Safari/Firefox or physical-device proof, complete keyboard inventory, all-animation pass, live prune submission, newly completed export worker or download-body acceptance is claimed. The 355-item baseline preserves limited declarations; they do not become passes through this score. Registry audit skipped: no components.json/shadcn initialization or third-party UI-SPEC registry contract.

Recommendation count: 3 priority fixes and 7 additional recommendations (C1, C2, V1, K1, T1, S2, E3). Findings may share owners and implementations; pillar scores are not an issue-count formula.

## Files Audited

- AGENTS.md, PRODUCT.md, .impeccable/config.json; configured audit instructions in `/tmp/threadline-238-ui-skills.txt`; Impeccable Operate/audit guidance.
- Phase 238 CONTEXT, all three PLAN/SUMMARY files, BASELINE-FINDINGS and EVIDENCE-INDEX.
- `lib/threadline/operator_surface/style/01_tokens.css`, `02_base_shell.css`, `03_page_home.css`, `04_controls.css`, `05_feedback.css`, `06_layout_primitives.css`, `07_find_detail.css`, `08_overlays_motion.css`, `09_responsive.css` (focused token/rule scans).
- `lib/threadline/operator_surface/script.ex`, `ui/display.ex`, `live/start_live.ex`, `live/export_status_live.ex`, `live/evidence_live.ex`, `live/retention_history_live.ex`, `live/timeline_live.ex`, `live/timeline_live/filters.ex` (focused relevant source).
- The five final PNGs named above; final theme, Copy and narrow Timeline observations, with remaining bounded state receipts summarized by the accepted index.

## Closeout custody note

This audit viewed the accepted captures at `2a1887e9`. Later repair `a2b4f350` changes test/runner aggregation and verification only; all product render source, served asset bytes and synthetic fixture identity are unchanged. The final three bounded browser lanes repeat 12/11/11 passes. Latest pointers are in `238-EVIDENCE-INDEX.md`; this report retains exact files actually viewed and does not claim they were re-viewed.
