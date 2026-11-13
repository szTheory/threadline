---
phase: 250-brand-foundation-and-first-whole-investigation
verified: 2026-11-12T23:35:05Z
status: passed
score: 76/76 must-haves verified
covered_files:
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-01-PLAN.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-01-SUMMARY.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-02-PLAN.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-02-SUMMARY.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-03-PLAN.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-03-SUMMARY.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-04-PLAN.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-04-SUMMARY.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-05-PLAN.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-05-SUMMARY.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-06-PLAN.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-06-SUMMARY.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-07-PLAN.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-07-SUMMARY.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-08-PLAN.md
  - .planning/phases/250-brand-foundation-and-first-whole-investigation/250-08-SUMMARY.md
  - README.md
  - examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts
  - examples/threadline_phoenix/e2e/support/operator-investigation-pair.test.ts
  - examples/threadline_phoenix/e2e/support/operator-investigation-pair.ts
  - examples/threadline_phoenix/e2e/support/operator-journey-inventory.json
  - examples/threadline_phoenix/e2e/support/operator-route-evidence.test.ts
  - examples/threadline_phoenix/e2e/tests/operator-brand-docs.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
  - examples/threadline_phoenix/priv/static/images/threadline-admin-favicon.svg
  - examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs
  - guides/operator-surface.md
  - lib/threadline/operator_surface/components/logo.ex
  - lib/threadline/operator_surface/components/surface_header.ex
  - lib/threadline/operator_surface/fonts.ex
  - lib/threadline/operator_surface/live/row_history_component.ex
  - lib/threadline/operator_surface/live/row_history_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/timeline_live/changes.ex
  - lib/threadline/operator_surface/live/timeline_live/helpers.ex
  - lib/threadline/operator_surface/live/transaction_live.ex
  - lib/threadline/operator_surface/style/01_tokens.css
  - lib/threadline/operator_surface/style/02_base_shell.css
  - lib/threadline/operator_surface/style/04_controls.css
  - lib/threadline/operator_surface/style/06_layout_primitives.css
  - lib/threadline/operator_surface/style/07_find_detail.css
  - lib/threadline/operator_surface/style/08_overlays_motion.css
  - lib/threadline/operator_surface/style/09_responsive.css
  - lib/threadline/operator_surface/ui/data.ex
  - mix.exs
  - release-please-config.json
  - test/fixtures/operator_surface/route-inventory.json
  - test/fixtures/operator_surface/source-surface-checklist.json
  - test/fixtures/style/operator_surface.css
  - test/threadline/brandbook_token_parity_test.exs
  - test/threadline/code_walkthrough_doc_contract_test.exs
  - test/threadline/operator_surface/data_state_mapping_wave0_test.exs
  - test/threadline/operator_surface/fonts_test.exs
  - test/threadline/operator_surface/live/row_history_live_test.exs
  - test/threadline/operator_surface/live/start_live_test.exs
  - test/threadline/operator_surface/live/timeline_live_test.exs
  - test/threadline/operator_surface/rendered_output_contract_test.exs
  - test/threadline/operator_surface/row_history_component_test.exs
  - test/threadline/operator_surface/style_byte_lock_test.exs
  - test/threadline/operator_surface/style_contract_test.exs
  - test/threadline/operator_surface/surface_header_test.exs
  - test/threadline/operator_surface/transaction_live_test.exs
  - test/threadline/operator_surface/ui_test.exs
  - test/threadline/operator_surface_doc_contract_test.exs
  - test/threadline/persona_routing_doc_contract_test.exs
  - test/threadline/readme_doc_contract_test.exs
  - test/threadline/release_artifact_contract_test.exs
covered_digest: "v4:sha256:0a3017db9ce12b81b2dc72c00bacf57b915243d3d82d7fb9819291c2fdb6ace5"
behavior_unverified: 0
overrides_applied: 0
non_authoritative_flags:
  unclassified_taxonomy_requirements: [ADM-10, ADM-11, ADM-14, ADM-16, ADM-17]
  descriptorless_prohibitions: 3
---

# Phase 250: Brand Foundation and First Whole Investigation — Verification Report

**Phase Goal:** Support can complete the Timeline-to-transaction-to-record-history investigation and return to the original search in a coherent brand-aligned Admin.
**Verified:** 2026-11-12T23:35:05Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

The roadmap’s five success criteria and the eight plans’ 74 truth assertions were checked against current implementation and current receipts. Three plan assertions restate another plan assertion (P04.3/P04.6, P04.2/P04.7, and P07.2/P07.8); after merging those, the score is 5 roadmap truths + 71 distinct plan truths = **76/76 verified**. The plan-level rows below summarize their subcriteria without dropping them.

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Admin, docs, and package use the approved brand roles, exact supplied assets, licensed role-specific fonts, and readable offline/opt-out fallbacks. | VERIFIED | Direct token/style/font/logo/package/docs paths; all 26 planned artifacts pass the GSD substantive artifact query. Current docs build and two browser cases passed. Current-source loaded-font gate: 5 passed, 0 skipped/retried/flaky; disabled-font gate: 1 passed, 0 skipped/retried/flaky. |
| 2 | Dark, Light, and System choices remain distinct and immediately server-resolved through the existing CSRF-protected theme flow. | VERIFIED | `SurfaceHeader` native form, existing theme controller/session/cookie/safe-return contract, focused mounted tests, and current-source browser observation of stored choice versus effective device theme. Theme gate: 1 passed, 0 skipped/retried/flaky. |
| 3 | Support can search a real ticket change, inspect its actual transaction and row history, copy the full identifier, then return through UI links with the original search intact. | VERIFIED | `TimelineLive` → `Query.timeline_page` → transaction link → `TransactionLive`/`Threadline.incident_bundle` → row-history route and `Threadline.row_history`/`as_of`; the selected Playwright whole-investigation case uses the materialized database record and asserts all four original filters after UI return. Fresh strict-after gate: 1 passed, 0 skipped/retried/flaky. |
| 4 | User-facing language preserves action/change/transaction/request, actor/user, data-state, and accepted/completed distinctions without unsupported assurance claims. | VERIFIED | `Presentation`, `UI.Data`, and `UI.Display`, focused source tests, exact scenario assertions, and independent copy/security review of 36 files. The reviewed output does not claim compliance or completeness. |
| 5 | Displayed timestamps include timezone, IDs remain complete when visually shortened, and keyboard copy reports pending/success/failure truthfully. | VERIFIED | `Presentation.human_time`, full `data-tl-copy` value and copy handler/status path, focused copy/history tests, and whole-flow test that keyboard activation supplies the actual full record PK and waits for the controlled promise before “Copied.” |
| 6 | P01: the baseline and matched before/after capture bind the same task-owned database, partition, port, record identities, UTC times, fingerprint, and served source/assets. | VERIFIED | `250-PAIR-EVIDENCE.md`, capture capsules and `request.json`; before and after SHA values are bound and the actual after source is `395f0b5afcfd0bd84f39a9dbe62dc9f01045c41c`. |
| 7 | P02: eight contrast roles, semantic/control boundaries, lockup geometry, accessible home name, and exact SVG bytes are preserved in both themes. | VERIFIED | Current CSS and supplied source/packaged assets; role and byte-lock tests; paired ordinary screenshots and independent UI review. |
| 8 | P03: supplied Familjen Grotesk, Geist, and IBM Plex Mono faces use private aliases, approved weights/roles/licenses, default behavior, and disabled-font fallback. | VERIFIED | `fonts.ex`, `brand/assets/fonts/web`, package allowlist in `mix.exs`, font/style tests, and fresh loaded/disabled browser gates. |
| 9 | P04: supported native theme choices preserve selected versus effective appearance; invalid theme, unsafe return, or CSRF failure cannot report a successful preference update. | VERIFIED | Existing controller and mounted tests retain auth/session/cookie/local-return validation; selected-button and effective-CSS browser observation. The two duplicate plan assertions are merged into this truth. |
| 10 | P05: README, ExDoc, and example Admin use exact theme-paired supplied artwork and correct minimum size; package ships only the approved SVG/WOFF2/OFL bytes; public technical identifiers remain stable. | VERIFIED | README/docs hooks, exact SVG/favicon source, `mix.exs` allowlist, release artifact/doc contracts, current docs build and browser captures. |
| 11 | P06: Timeline preserves committed versus pending filters, optional query predicates, empty versus unavailable states, correct counts, long editable values, and mounted navigation to the real correlated transaction. | VERIFIED | `timeline_live.ex`, `timeline_live/filters.ex`, `timeline_live/changes.ex`, `Query.timeline_page`, focused LiveView/style tests, and source-bound pending/empty/error browser cases. |
| 12 | P07: transaction and row history preserve exact values, actor, semantic action/change/transaction distinctions, UTC event/recording times, missing/redacted/null/omitted/unavailable meanings, full IDs, and safe return context. | VERIFIED | `transaction_live.ex`, `row_history_live.ex`, `row_history_component.ex`, `Presentation`, `UI.Display`, focused ExUnit tests, and actual whole-flow assertions. The duplicate missing/redacted value statement is merged. |
| 13 | P08: current-source before/after identity, browser gates, documentation evidence, and independent review are bound to actual bytes; unresolved assumptions stay visible. | VERIFIED | `request.json`, current-source review gate, raw Playwright result JSONs, docs captures, `250-REVIEW.md`, `250-UI-REVIEW.md`, and `250-REVIEW-DISPOSITION.md`. Three descriptor-less prohibitions and five taxonomy signals remain explicitly flagged below; this pass does not resolve or certify them. |

**Score:** 76/76 must-have truths verified (0 present-but-behavior-unverified).

### Non-authoritative flags retained

Five requirement-edge taxonomy signals remain unresolved assumptions: ADM-10, ADM-11, ADM-14, ADM-16, and ADM-17. They are not inferred as missing runtime behavior: the corresponding substantive requirements are verified above and in the requirements table. Plan 08 also carries three descriptor-less prohibitions as unresolved/non-authoritative flags. They are retained as flags, not claimed as accepted, tested prohibitions or human attestations. This report does not silently mark those flags resolved.

## Required Artifacts

| Artifact group | Status | Evidence |
|---|---|---|
| 26 artifacts declared across Plans 01–08 | VERIFIED | `gsd_run query verify.artifacts` returned all passed; no missing, stub, or substantive-pattern failure. |
| Timeline, transaction, and row-history implementation | VERIFIED | `lib/threadline/operator_surface/live/{timeline_live.ex,timeline_live/changes.ex,timeline_live/helpers.ex,transaction_live.ex,row_history_live.ex,row_history_component.ex}` contain functional LiveView routes, DB calls, state rendering, and return links. |
| Shared semantics and design system | VERIFIED | `presentation.ex`, `ui/data.ex`, `ui/display.ex`, `fonts.ex`, `components/{logo,surface_header}.ex`, and the changed token/layout/control CSS are used by mounted Admin components. |
| Browser evidence and proof contracts | VERIFIED | Example Playwright whole-flow, route-state, and docs cases plus pair/evidence validators use actual current source and persisted rows. Test-only `writeFileSync` calls construct negative validator fixtures; they do not supply the product’s rendered values. |
| Docs and package output | VERIFIED | README, operator guide, docs/archive contracts, exact asset allowlist, generated docs build, and captured themed docs cases. |

## Key Link Verification

The generic GSD key-link scanner did not resolve the 17 plan links because Phoenix macros, compile-time asset embedding, and indirect helper calls do not match its literal patterns. I traced the source links manually; no orphaned artifact or disconnected route was found.

| From | To | Via | Status | Details |
|---|---|---|---|---|
| Brand token roles | Admin CSS and rendered states | `Style` assembly and light/dark/System selectors | WIRED | All eight approved roles map to functional variables; contrast checks distinguish operation, artwork, links, focus, and controls. |
| Supplied SVG/font sources | Admin, docs, and package | Compile-time logo/font embedding, docs hooks, and `mix.exs` files | WIRED | Exact source bytes are asserted; serving and archive gates bind the four WOFF2 faces and supplied lockups. |
| Theme controls | Existing server preference flow | Native supported-value form, CSRF, controller validation, session/cookie and safe local return | WIRED | Browser observes selected preference separately from effective theme. |
| Search/filter state | Timeline results and transaction destination | HEEx events, URL parameter parsing, `Query.timeline_page`, `Changes`, and mounted host routes | WIRED | The real correlation identifies the persisted transaction; original query values survive UI return. |
| Transaction destination | Action and captured changes | `TransactionLive` and `Threadline.incident_bundle` | WIRED | Data is queried and rendered with actual actor, times, and exact change values. |
| Row-history destination | Record revisions and as-of state | Route identity separated from safe return context; `Threadline.row_history`/`as_of` | WIRED | Path identity remains the table/record key; Timeline and transaction origins return through their UI links. |
| Full-ID copy control | Clipboard state and user feedback | Shared copy script, complete DOM value, keyboard activation and promise-driven status | WIRED | Test proves exact actual ID, pending feedback, completion feedback, and no false success. |

## Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| Timeline rows | committed filter/page result | `Query.timeline_page` over the configured audit repository | Yes; the scenario’s transaction is read from the seeded test database | FLOWING |
| Transaction detail | action, transaction, changes | `Threadline.incident_bundle` | Yes; actual persisted action and two changes are asserted by the browser case | FLOWING |
| Record history | versions and as-of snapshot | `Threadline.row_history` and `Threadline.as_of` | Yes; actual prior/current reply snapshots are asserted | FLOWING |
| Copy value | full record primary key | rendered row-history record data | Yes; browser test compares the Clipboard API argument with the real full PK | FLOWING |
| Brand faces and artwork | embedded bytes | approved local `brand/assets` files and package assets | Yes; byte locks plus served/archive evidence bind the bytes | FLOWING |

## Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Current review identity matches the accepted review bytes | `env PATH="<node22-bin>:$PATH" python3 /private/tmp/threadline-250-08-check-review.py review` | Exit 0; `matched=true`, `reviewIdentityMatched=true`. This checker verifies identity, not reviewer judgment. | PASS |
| Whole investigation after-change behavior | Current-source strict-after Playwright receipt bound by `request.json` | One named case passed on first attempt, zero skipped/retried/flaky; four original filters and the actual full copy argument are asserted after UI navigation. | PASS |
| Default brand font delivery | Bound current-source browser report | 5 passed; 0 skipped/retried/flaky. | PASS |
| Font opt-out/system fallback | Bound current-source browser report | 1 passed; 0 skipped/retried/flaky. | PASS |
| Theme choice versus effective appearance | Bound current-source browser report | 1 passed; 0 skipped/retried/flaky. | PASS |
| Generated docs | Current docs build, two browser cases, retained screenshots | Build and both cases passed; paired light/dark logo sizing and theme behavior observed. | PASS |

These are selected phase gates, not a full canonical or browser matrix. Existing scoped receipts also include 436 root test cases, 69 example cases, 32 Node cases, and focused 33/76/21/28-owner checks; those counts are not treated as a full-suite guarantee. No new suite or broad repeat was run for this verification.

## Probe Execution

No runnable phase-declared `probe-*.sh` acceptance probe was found. The planning-time UI consideration probe is recorded in `250-PROBE-RECORD.md` (38 applicable considerations resolved); it is not a product behavior probe. Five unresolved taxonomy signals remain visible above rather than being presented as a pass.

## Requirements Coverage

| Requirement | Source plan | Description | Status | Evidence |
|---|---|---|---|---|
| ADM-08 | 02, 04 | Approved UI role colors, eight stable contrast IDs in both themes, and distinct artwork/link/focus/control roles | SATISFIED | Token CSS, role mapping, contrast contract tests, paired theme evidence. |
| ADM-09 | 02, 03, 05, 08 | Supplied lockups/favicons, theme variants, geometry, supported sizes, licenses, package/docs delivery | SATISFIED | Exact source byte locks, archive allowlist, docs and browser captures. |
| ADM-10 | 03, 08 | Approved served font families/weights, licenses, offline delivery, opt-out and system fallback | SATISFIED | `fonts.ex`, approved WOFF2/OFL files, focused tests, loaded and disabled-font browser gates. |
| ADM-11 | 04, 08 | Dark-default, Light and System themes through the existing CSRF-protected native flow | SATISFIED | Existing controller/session contract, mounted tests, observed current-source browser gate. |
| ADM-12 | 02, 05, 06 | Approved plain product language while preserving public identifiers and query/API contracts | SATISFIED | README/docs and UI copy contracts; unchanged public modules/routes/query fields inspected. |
| ADM-13 | 06, 07, 08 | Distinct action/change/transaction/request, actor/user, data-state and accepted/completed meanings; no unsupported assurance | SATISFIED | Shared presentation/data display code and focused tests; actual ordinary scenario reviewed. |
| ADM-14 | 01, 06, 07, 08 | Complete support journey from Timeline change through transaction/history/copy and return to original search | SATISFIED | Actual seeded DB whole-investigation Playwright case and current-source receipt. |
| ADM-16 | 02, 06, 07, 08 | Exact neutral before/after values and clear missing/redacted/left-out cases; operation meaning does not depend on color | SATISFIED | Change rendering, shared semantic display, exact values and eight-role tests. |
| ADM-17 | 01, 03, 04, 07, 08 | Time zones, complete compact IDs, keyboard copy and truthful success/failure feedback | SATISFIED | UTC presentation, full-ID DOM argument and promise-gated browser proof, focused tests. |

All nine requirements mapped to Phase 250 in `REQUIREMENTS.md` are accounted for. No Phase 250 requirement is orphaned; ADM-15/18/19 are assigned to Phase 251, not Phase 250.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | None in the reviewed runtime source. The source scan found no unreferenced TBD/FIXME/XXX markers, placeholder implementation, or empty return used for rendered output. | — | No blocker. Test fixture writes are confined to validator negative-control setup. |

## Human Verification Required

None. The independent UI review covers the ordinary journey and generated docs in desktop/mobile-sized captures. Its limits are retained explicitly; no visual proof is claimed for uncaptured error/empty pixels, native clipboard permissions, or actual tab-zoom extension behavior.

## Review Limits and Remaining Notes

- Independent source/copy/security review: 36 files, clean, zero open findings within its bounded scope.
- Independent UI review: 22/24. The remaining observations are nonblocking: a generic `Retry` action sits beside transaction-specific context, and empty/error layout pixels were not part of the matched screenshot set. `250-REVIEW-DISPOSITION.md` retains both for Phase 253; the missing screenshot is not treated as missing runtime handling.
- Current source, review, and after-capture identity was confirmed by the read-only review checker and bound in `/private/tmp/threadline-250-investigation-pair/review/request.json`. The identity check does not substitute for the independent reviewers’ judgment.
- Native clipboard permission behavior, zoom-extension behavior, the broad browser/canonical matrix, and live REL-01 remain outside this phase. These limits are not converted into routine human acceptance work.

## Gaps Summary

No roadmap or plan must-have is missing, stubbed, or disconnected. The selected current-source gates and direct source/data-flow traces establish the Phase 250 goal. Later-phase UI refinements and non-authoritative flags remain explicit above and do not negate the verified support journey or claim broader assurance.

---

_Verified: 2026-11-12T23:35:05Z_  
_Verifier: gsd-verifier_
