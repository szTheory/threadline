# Phase 243 matched visual review

## Evidence and comparison limits

The accepted before bundle is the immutable Phase 238 route set indexed by `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-EVIDENCE-INDEX.md`; its retained route bundle is `examples/threadline_phoenix/e2e/artifacts/operator-evidence/operator_close_routes_1791521924`. The fresh Phase 243 candidate bundle is `examples/threadline_phoenix/e2e/artifacts/operator-evidence/operator_243_routes_1791690775_31234` in this worktree. The Plan 02 candidate validator passed (`comparison=limited`, 34 shell captures, 12 route IDs); the baseline byte digest remained `c744df9cd8e999109be2ac0956028288b4f4b1eb734354d8d22d0bcf3332f4aa`. The exact output hashes for every PNG are recorded in the two immutable `manifest.json` files.

The candidate run is bound to HEAD `7f419344e6b9e31ff331a9bcec50476a2c21843d`, base `9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2`, receipt SHA-256 `40c67d9d0959c1b69ccdc32bfc9bc70ef10c78e4cbd474a1c54805cba4c2666f`, and candidate diff digest `255d3cf0d9e7df6f46768818c0a4b15bc59a1956ae354dc3f6b46e8955c1b9d7`. Run partition: `operator_243_routes_1791690775_31234`; isolated database: `threadline_phoenix_testoperator_243_routes_1791690775_31234`; mode: read-only evidence. Browser: Playwright 1.60.0 / Chromium 148.0.7778.96 on Darwin 25.6.0. Actor: seeded admin, scoped to the local synthetic demo database. Appearance: dark preference/effective theme. Viewports: 1280×900, 768×900, and 375×900 CSS pixels at DPR 1; reduced motion; browser tab zoom 1. The candidate route bundle captures all 11 named routes and the degraded timeline twin. No credentials, cookies, response bodies, or customer data were captured.

The validator correctly labels the raster comparison **limited**, not pixel-equivalent: the accepted baseline predates this candidate and records OS as `not-recorded`; the semantic fixture IDs differ (`86a439…` baseline, `4de938…` candidate); generated LiveView JavaScript differs (`7f97fe…` vs `880c3d…`) and the generated operator stylesheet differs (`b5053f…` vs `cf8ec7…`); transaction/row identifiers and timestamps therefore differ as well. The route shell and viewport families match. These data and asset differences are not treated as visual defects. The baseline bytes and all candidate/baseline per-image hashes were checked by the validator.

| Route | Matched route family and reviewed shell widths | Review disposition |
|---|---|---|
| Home | direct entry; 1280 / 768 / 375 | No new layout defect. Navigation, status summary, search entry, and cards remain legible. |
| Timeline | direct entry; 1280 / 768 / 375 | No new layout defect. Search/filter and result hierarchy reflow; degraded state has its own 1280 capture. |
| Transaction | direct entry; 1280 / 768 / 375 | No new layout defect. Transaction metadata and row-change cards remain readable. |
| Row | direct entry; 1280 / 768 / 375 | No new layout defect. Row details remain readable; drawer affordance opens the same record. |
| History drawer | direct entry; 1280 / 768 / 375 | Medium finding DR-243-01 below: title is clipped by the fixed top header at 1280; this geometry also appears in accepted baseline. |
| Actor | direct entry; 1280 / 768 / 375 | No new layout defect. Actor identity and activity list reflow. |
| Coverage | direct entry; 1280 / 768 / 375 | No new layout defect. Dense coverage data remains within the page at narrow widths. |
| Evidence | direct entry; 1280 / 768 / 375 | Inherited UI-241-02 reproduced: group footer links touch the lower card edge at narrow width. |
| Exports | direct entry; 1280 / 768 / 375 | Phase 242 screenshot gap is closed for these rendered states. Queue/result statuses and available export actions remain distinguishable; no new visual finding. |
| Redaction policy | direct entry; 1280 / 768 / 375 | Inherited UI-241-01 and UI-241-03 reproduced. |
| Retention policy | direct entry; 1280 / 768 / 375 | Phase 242 screenshot gap is closed for these rendered states. Policy summary, history, outcome and status labels remain legible; no new visual finding. |

The comparison validator covers every named route across the three widths. For example, the History drawer 1280 dark shell hash is `8d78be8104fa1aae628edc85342a151cef2c1894905ad3934b9754b50c2dae30` before and `6866347c51eaae6ae6ed3f00db447fe597441a13f31745140448ebc604cbf9b7` after. Evidence at 375 is `e5f2a5af90eedcde769a5b876a7d02c2343f1233aca9950f53a87be19d02c3f0` before and `7b132b61e7168eb86700ebd035faab2ea002f54317668ee2658df386ddab497c` after. All other route/width before and after hashes are in the manifests at the paths above.

## Findings and bounded disposition

| ID | Route/state and evidence | Impact / severity | Owner and correction or disposition | Confirmation |
|---|---|---|---|---|
| UI-241-01 | Redaction policy, direct entry. Candidate 1280 dark shell `cc8f10bb9ee3180b86a2b02d072a6d52c6482d20980a62ecf3f55ebf949aa2a3`; at 375, refresh control is directly above the posture card with no section gap. | Minor hierarchy/section-rhythm defect; low. | Fixed in `policy_redaction_live.ex` with `tl-policy__refresh` and `07_find_detail.css` with `margin-bottom: var(--tl-space-4)`; the refresh action/schema scope are unchanged. | Focused mounted test passed (14/14). Post-fix 320px candidate image `/tmp/phase243-plan04-redaction-320.png`, SHA-256 `d43dd83908cc4fecf15ec94a4af1d5235018fb2d4ce3137fbfb051df60df8eff`, rendered at source HEAD `af1a3369f3a0061707283fab18c7c2663d2b1893`; the measured posture gap is 16px. Plan 05 will capture final route images. |
| UI-241-02 | Evidence page, direct entry. Candidate 375 dark shell `7b132b61e7168eb86700ebd035faab2ea002f54317668ee2658df386ddab497c`; the “Filter to subject” / companion footer links meet the bottom card edge. | Footer actions are visually cramped and harder to distinguish at narrow width; low. | Fixed in `evidence_live.ex` with a dedicated group-footer hook; `09_responsive.css` adds tokenized separation and 40px compact targets at ≤480px, retaining link labels and scoped targets. | Focused mounted test passed (14/14). Post-fix 320px candidate image `/tmp/phase243-plan04-evidence-320.png`, SHA-256 `b49d001d5ab1980c09fd806ad29438c447e36997864a95f9865b9cf6a0cf64d6`, rendered at source HEAD `af1a3369f3a0061707283fab18c7c2663d2b1893`; both footer links are reachable, visible/in viewport, 40px high, and separated from the card edge by 8px. Plan 05 will capture final route images. |
| UI-241-03 | Redaction policy, unreadable inspection group. Source/render contract exposed heading “Could not introspect” beside the per-row label “Could not inspect”; the status enum is `:could_not_introspect`. Candidate redaction 1280 shell: `cc8f10bb9ee3180b86a2b02d072a6d52c6482d20980a62ecf3f55ebf949aa2a3`. | Copy inconsistency weakens plain-language status comprehension; low. | Fixed in `policy_redaction_live.ex` section title; `test/threadline/operator_surface/live/policy_redaction_live_test.exs` asserts the heading and enum-group meaning, while the public status enum and distinction from missing deployment remain unchanged. | Focused mounted test passed (14/14); final image confirmation follows in Plan 05. |
| DR-243-01 | History drawer, `/transactions/:id/history/:table/:record_id`, direct entry, dark, 1280×900 CSS px, DPR 1, reduced motion, tab zoom 1. Accepted baseline shell `8d78be8104fa1aae628edc85342a151cef2c1894905ad3934b9754b50c2dae30`; candidate shell `6866347c51eaae6ae6ed3f00db447fe597441a13f31745140448ebc604cbf9b7`. In both, the drawer title’s top line sits behind the fixed Threadline header; Close remains visible. | Part of the drawer context title is obscured on initial view; medium usability impact, no data loss or blocked close action. | Owner is drawer overlay positioning in `lib/threadline/operator_surface/style/08_overlays_motion.css` (outside Plan 04 file ownership). Evidence-based disposition: same clipping exists in accepted baseline, so this candidate did not introduce it. Defer code change to the overlay owner/plan rather than expand this bounded policy/Evidence fix batch. Release risk: medium visual clarity issue; no high-severity issue and no regression-based release blocker. Plan 05 should recheck the drawer after its own final capture. | Existing baseline-to-candidate geometry reviewed; no Plan 04 correction. Track as carry-forward. |

Phase 242’s prior review had no screenshots. The current matched capture now provides full-shell views for Exports and Retention at 1280/768/375. Queue/completion, failed/expired export and retention outcome/status information remain distinct and readable in the rendered states. Earlier Phase 242 mounted and browser state tests cover confirmation, authorization denial, partial outcomes, and reconnect gating; this visual capture does not claim a fresh interactive replay of every operation state.

## Additional condition evidence and limits

The full-shell evidence-bound route capture above is dark-only at 1280/768/375; its manifest records `browserZoom: unverified` for those screenshots. Separate post-fix focused checks exercised source HEAD `af1a3369f3a0061707283fab18c7c2663d2b1893`:

| Condition | Command / run partition | Result and evidence |
|---|---|---|
| Affected routes at 320 CSS px | `MIX_TEST_PARTITION=operator_243_vp_320_20261011c mix verify.example_browser --project=desktop-chromium plan243-04-viewport-probe.spec.ts` | 1 Playwright probe and 21 setup/unit checks passed. Evidence footer links measured 40px tall, reachable, unobscured/in viewport, 8px from the card edge; document width 320. Redaction document width 320; posture gap 16px. Candidate-only screenshots and hashes are listed in UI-241-01/02; the temporary probe was removed after capture. |
| Light/System theme lane | `MIX_TEST_PARTITION=operator_243_light_20261011 mix verify.example_browser_light --project=desktop-chromium-light operator-accessibility.spec.ts` | 18 Playwright tests and 21 setup/unit checks passed. Includes responsive checks at 320/768/1280 in Light, Dark, and System, plus the System theme-following journey. |
| Real desktop tab zoom 2× | `THREADLINE_ZOOM_ACCEPT=1 MIX_TEST_PARTITION=operator_243_zoom_20261011 mix verify.example_browser --project=desktop-chromium operator-zoom-proof.spec.ts` | 2 Playwright tests and 21 setup/unit checks passed in Chrome for Testing 148.0.7778.96 / Playwright 1.60.0. `setAndReadTabZoom` observed factor 2, CSS viewport 640×450 from a 1280×900 tab, DPR 2, document width/client width 640, zero horizontal overflow, and visible/reachable focused controls across Home, Timeline, Transaction, Row, Drawer, Actor, Coverage, Evidence, Redaction, Exports, reconnect, Retention, and confirmation states. |

The 320px captures are targeted candidate probes, not matched baseline pairs; their image hashes and measurements establish current post-fix rendering only. The focused light and zoom commands do not produce candidate-receipt-bound full-shell manifests. Plan 05 remains responsible for fresh evidence-bound final route captures after all source changes. Phase 238’s accepted evidence does not claim browser-chrome 200% zoom, and the Plan 241 mobile zoom path remains explicitly unsupported.

No accepted baseline image or manifest was edited. Generated capture bundles remain local/ignored; only this compact hash and finding ledger is intended for commit.

## Final corrected-candidate confirmation (Plan 05)

The final capture was generated from candidate HEAD `86db9f2d31304fd2239e455146e8f8318ad23fd3`, candidate diff digest `22d70d26c2b84c4e28e0409c65e7f94c7ee67c4fe078d7febed33a1f8b6509f4`, and receipt SHA-256 `a466c6b73db571e09c584366ccaf154c75e34ba66a92800e641e06c621ac9010`. The receipt binds 81 relevant source paths, including current staged, unstaged and untracked source bytes. The fresh route bundle is `examples/threadline_phoenix/e2e/artifacts/operator-evidence/operator_243_routes_1791717407_28440`; it contains 34 full-shell PNGs for all eleven named routes and the degraded Timeline state. The route-capture project passed 12 tests with one expected skip for the legacy reference-writing test in read-only evidence mode.

The candidate review validator passed and kept the comparison **limited**. It confirmed the immutable baseline byte digest remains `c744df9cd8e999109be2ac0956028288b4f4b1eb734354d8d22d0bcf3332f4aa`. Its 782 differences are evidence/environment differences rather than pixel-equivalence claims: the baseline does not record OS while this run records Darwin 25.6.0; the semantic fixture IDs differ (`86a439…` baseline and `4de938…` candidate); the generated operator stylesheet differs (`b5053f…` baseline and `eaa666…` candidate); generated JavaScript differs; and seeded route/state identifiers differ. The validator checked candidate served/local assets and output hashes and found all required shell outputs. These differences remain visible as limits in the report at `<capture bundle>/candidate-review.json`.

| Finding | Final confirmation and disposition |
|---|---|
| UI-241-01 | Final dark 375px Redaction shell: `route.redaction__dark-375-shell.png`, SHA-256 `0cf8dd30508db4efd4ca2440f8cf9421708244866e109dd2d782bb6bf60d7454`. The refresh action is separated from the posture card; the prior 320px focused run measured the gap at 16px. Fixed and confirmed. |
| UI-241-02 | Final dark 375px Evidence shell: `route.evidence__dark-375-shell.png`, SHA-256 `9e3dda307cd116ee3f4e6bc19511708a6902ea9bafdcda77b93f064445ca26d0`. Both group-footer links are visible with separation from the card edge; the prior 320px focused run measured 40px targets and an 8px card-edge gap. Fixed and confirmed. |
| UI-241-03 | Final dark 375px Redaction shell above renders the heading `Could not inspect (0)`. The mounted test preserves the public `:could_not_introspect` status. Fixed and confirmed. |
| DR-243-01 | Final dark 1280px drawer shell: `route.drawer__dark-1280-shell.png`, SHA-256 `e2e2baa5f8a1fe2fc9b9225f1a6b063d74daa7156956802de21b82e1e9a7a5c0`. The title remains partly behind the fixed header while Close is visible and reachable. The accepted Phase 238 observation records the same clipping; comparison is limited by route/state and environment differences. Carry forward as a medium visual-clarity risk owned by overlay positioning, with no new regression or blocked close action established. |

No additional visual findings were added from the final dark route shells. The prior light/System and actual 2× tab-zoom checks were run on the earlier Plan 04 candidate; this Plan 05 route bundle is dark-only and makes no fresh theme or zoom claim. The unrelated full-suite formatting failure is recorded in the Plan 05 execution summary, not treated as visual evidence.

## Guarded local preview (Plan 05)

Final preview receipt: `.planning/phases/243-integrated-verification-and-review-preview/243-PREVIEW-RECEIPT.json` (SHA-256 `0ac17d191359451e9faefd9888cfea8a692dc2b5eb9fe49a8812bb2a503adfdb`). The process-bound receipt reports candidate HEAD and diff digest above, `http://127.0.0.1:4121`, listener PID `41448`, partition `operator_243pf_1791717692_41076`, database `threadline_phoenix_testoperator_243pf_1791717692_41076`, eleven authenticated routes, unauthenticated login redirect, connected LiveView, and matching local/served JavaScript and CSS hashes. Read-only checks confirmed the exact listener is `beam.smp`, cwd is this worktree's `examples/threadline_phoenix`, and PostgreSQL reports that database connected from `127.0.0.1`. The preview is intentionally left running.

Guarded stop command for this exact receipt:

```sh
THREADLINE_E2E_PREVIEW_STATE="${TMPDIR}/threadline-e2e-preview-operator_243pf_1791717692_41076.json" MIX_TEST_PARTITION=operator_243pf_1791717692_41076 THREADLINE_E2E_STOP_PREVIEW=1 bash examples/threadline_phoenix/e2e/run-e2e.sh --stop-preview
```

Guarded reopen command template using a new partition and a free loopback port:

```sh
THREADLINE_E2E_PORT=4122 THREADLINE_E2E_EVIDENCE=1 THREADLINE_E2E_PREVIEW=1 THREADLINE_E2E_CANDIDATE_RECEIPT=.planning/phases/243-integrated-verification-and-review-preview/243-CANDIDATE-RECEIPT.json MIX_TEST_PARTITION=operator_243pf_reopen_20261011 mix verify.example_browser --preview
```

The runner refuses a busy requested port, reused database, stale candidate receipt, non-loopback address or unowned listener. If a later documentation commit advances candidate HEAD, refresh and revalidate the candidate receipt and recapture before using the reopen command; do not treat this receipt as proof for a later HEAD.
