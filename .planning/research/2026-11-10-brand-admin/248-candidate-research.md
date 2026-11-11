# Phase 248 — retained UI candidate reconciliation research

**Researched:** 2026-11-10  
**Scope:** ADM-01 disposition inventory only  
**Confidence:** HIGH for observed worktree and current-main differences; recommendations are phase-boundary guidance.

## Recommendation

Keep the active v1.48 planning checkout based on current main as the implementation candidate. Do not transplant UI changes during Phase 248: ADM-01 requires a disposition for each retained edit, while Phase 248 separately owns mount safety and current advisory/affected-suite proof. Record this matrix in one Phase 248 candidate-baseline artifact, preserve the prior worktree untouched, and replay only edits later assigned to their owning phase after rechecking the final route/job and accessibility contract. [VERIFIED: `.planning/ROADMAP.md:54-61`]

The requirement is:

<!-- DATA_R8K4M2Q7_START -->
> - [ ] **ADM-01**: Maintainers can work from a current-main isolated candidate with a port/replace/defer disposition for every retained UI edit, preserving the old checkout and brand-source provenance.
<!-- DATA_R8K4M2Q7_END -->

[VERIFIED: `.planning/REQUIREMENTS.md:12`]

The phase mapping that informs dispositions is:

<!-- DATA_C3V9L1T6_START -->
> 1. 248: reconcile the current-main candidate and safety/proof ownership (ADM-01–04).
> 2. 249: map jobs/scenarios and approved brand contract (ADM-05–07).
> 3. 250: brand foundation and first whole investigation (ADM-08–14, ADM-16–17).
> 4. 251: complete investigation and inspection screens (ADM-15, ADM-18–22).
> 6. 253: inclusive integration, current docs/package and release readiness (ADM-26–34).
<!-- DATA_C3V9L1T6_END -->

[VERIFIED: `.planning/research/v1.48-SUMMARY.md:7-13`]

Interpretation: `DEFER` preserves the candidate intent for its owning phase without porting its current patch. `REPLACE` preserves only the intent and requires a fresh implementation/test against the later approved contract. No row is recommended for `PORT` in Phase 248.

## Source identity and preservation evidence

- Preserved candidate identity: repo-relative worktree `.claude/worktrees/v146-phase241-orchestrator`, branch `agent-241-01`, HEAD `0f9347f207d9395565faa4a3b0280804c4c14e1b`; its 31 retained product/UI/docs/test files are dirty in the worktree. The dated research inventory independently identifies this branch and HEAD as the retained candidate. [VERIFIED: `.planning/research/2026-11-10-brand-admin/README.md:90-92`; `git status` at candidate HEAD]
- Current-main baseline identity: `origin/main` was `d35b9422`; the active planning checkout is `agent-v148-admin` at `f9759932`, based on that main commit with planning initialization. [VERIFIED: `git rev-parse` / `git log`]
- The candidate’s 31-file unstaged patch fingerprint is SHA-256 `7bb1328b375ed9c9b656d22785e089831122b002b6892554e8ce476d2b7c9074`, computed from the binary diff against candidate HEAD. Each row below records its Git blob object ID from the dirty candidate bytes. [VERIFIED: `git diff --binary` and `git hash-object`]
- Separate dirty files are excluded from this 31-row UI inventory: five `.planning/` paths, `AGENTS.md`, `CLAUDE.md`, and untracked planning/research/seed/dependency material. Keep those changes in their owning checkout; do not merge them as product edits. The current checkout’s brand/Admin guidance is authoritative for future work. [VERIFIED: candidate `git status`; `AGENTS.md:118-148`]
- Approved brand source is present in the current checkout and the original checkout with matching Git blob IDs: `brand/BRAND.md` `deccfab0b0c003390dd959f60821fa4d8bac0cec`; `brand/brand.json` `647f43d817a726894a8f26bd73e74e1add670080`; `brand/assets/README.md` `c24dac3d1a206b49b29224a5cea8d1136b51dd93`. Those files are absent from the preserved candidate worktree, so use the imported current source and retain the old checkout as-is. [VERIFIED: `f9759932:<path>` blobs, original-checkout `git hash-object`, and candidate filesystem check]
- Approved source contract from `brand/BRAND.md:5`:

<!-- DATA_H5N2Q8R4_START -->
> Every operation, status and masked value is a word first and a color second.
<!-- DATA_H5N2Q8R4_END -->

[VERIFIED: `brand/BRAND.md:5`]

The asset guide's theme-specific logo and font-license rules are at `brand/assets/README.md:45`; current `AGENTS.md:120-126` names `brand/` as authoritative and requires old references to remain until migration completes. [VERIFIED: cited source lines]

The logo color reference used by the Phase 250 recommendation is:

<!-- DATA_P4N7K2C8_START -->
> **Stitch Blue** #4781E6, the thread in the logo
<!-- DATA_P4N7K2C8_END -->

[VERIFIED: `brand/BRAND.md:13`]

## Current-main path conflicts

Comparing candidate base `0f9347f2` to current main `d35b9422` over these 31 paths shows four path overlaps. The later main hunks do not collide with the candidate’s functional hunks, but must survive any selective replay:

| Path | Later current-main change | Replay instruction |
|---|---|---|
| `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` | Adds waits for drawer initial focus and modal dismissal/focus restoration. | Preserve those focus assertions; merge only candidate theme/coverage selectors. |
| `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` | Adds exact modal opener lookup and modal hidden/focus-restored assertions. | Preserve those assertions; merge only candidate Refresh locators. |
| `guides/operator-surface.md` | Updates the package dependency example from `~> 1.0.0` to `~> 1.1.0`. | Keep the current `1.1.0` example while later rewriting the theme/schema guidance. |
| `test/threadline/operator_surface/style_contract_test.exs` | Adds `@moduletag :repo_contract`. | Keep the module tag while replacing stale style assertions in its owning phase. |

[VERIFIED: `git diff 0f9347f2 d35b9422 -- <the 31 listed paths>`; the complete differing-path set is these four.]

The current source contains the package example:

<!-- DATA_B6J1S4P9_START -->
> `{:threadline, "~> 1.1.0"}`
<!-- DATA_B6J1S4P9_END -->

[VERIFIED: `guides/operator-surface.md:38`]

The current style contract test contains:

<!-- DATA_M3W8Q2L7_START -->
> `@moduletag :repo_contract`
<!-- DATA_M3W8Q2L7_END -->

[VERIFIED: `test/threadline/operator_surface/style_contract_test.exs:4`]

## Retained-edit disposition matrix

`Hash` is the Git blob ID of that file’s candidate worktree bytes. “No upstream delta” means that path is unchanged between candidate base `0f9347f2` and current main `d35b9422`. The path comparison verified all 31 rows; only the four overlaps listed above differ upstream. [VERIFIED: `git diff 0f9347f2 d35b9422` restricted to the 31 matrix paths]

| # | Repo-relative path | Verified candidate edit (blob hash) | Current-main status | Recommendation and proof owner |
|---:|---|---|---|---|
| 1 | `examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts` | Reads theme preference from the selected button state. `2527627c489c46bd7060c5af68e555bde11fd83e` | No upstream delta. | **DEFER — Phase 250.** Bind evidence capture to whichever accessible theme control Phase 250 adopts; the recorder must observe the persisted preference. |
| 2 | `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` | Changes theme interaction/selectors, coverage/redaction Refresh names, and schema-control assertions. `26e163c715f5acdde942d394325020ed0fb11ef7` | Later modal focus assertions; preserve them. | **DEFER — Phases 250/251.** Split theme proof from inspection-screen proof; keep current-main modal focus waits. |
| 3 | `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts` | Adds schema accessible name/description, immediate-selection URL/history/reload checks, and forced-colors behavior. `3aa76cc818a333f0cc29e69c73ada2b173550e10` | No upstream delta. | **DEFER — Phase 251.** Reconfirm the selection and refresh contract after Phase 249 maps this job and state transition. |
| 4 | `examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts` | Updates coverage/redaction refresh selectors. `61f5391da9361922752d148373d3d7ae8f2f0052` | Later modal focus assertions; preserve them. | **DEFER — Phase 251.** Change selectors with the inspection controls; retain current-main modal focus proof. |
| 5 | `examples/threadline_phoenix/e2e/tests/operator-phase-175-uat.spec.ts` | Recasts historical theme UAT as a JavaScript-disabled theme/filter persistence flow. `23fb4b49638e8726e970c2b0dddce16b746a9e34` | No upstream delta. | **REPLACE — Phase 250.** Keep the no-JavaScript and query-preservation acceptance intent, but place it under the current theme contract instead of extending a Phase 175 UAT file. |
| 6 | `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | Updates theme controls and inspection refresh selectors. `75363e0635d27ff2c9accdf82ce019ae6d5e3ea5` | No upstream delta. | **DEFER — Phases 250/251.** Split assertions by theme versus screen ownership after the route/state inventory. |
| 7 | `examples/threadline_phoenix/e2e/tests/operator-shell-home.spec.ts` | Expects theme choices as buttons with selected state. `696b4e7cffd107bde3e4f13c4143800eae962788` | No upstream delta. | **DEFER — Phase 250.** Derive control-role and selected-state assertions from the final accessible theme interaction. |
| 8 | `examples/threadline_phoenix/e2e/tests/operator-zoom-proof.spec.ts` | Updates theme and Refresh control locators for zoom observations. `24a5c2f852ee834688fa6a4f824e986b788f8a13` | No upstream delta. | **DEFER — Phase 253.** Rebind observations after final markup and include them in the integrated responsive/zoom acceptance. |
| 9 | `guides/operator-surface.md` | Rewrites theme selection and schema-selection guidance. `36c4cf9c33db8910a753082e29102cf0140301c0` | Package example was advanced to `~> 1.1.0`; preserve. | **REPLACE — Phase 253.** Reconcile docs once user-facing vocabulary and behavior are final; keep the current package version example. |
| 10 | `lib/threadline/operator_surface/components/icon.ex` | Adds a chevron icon for a custom schema select. `ec52748712cdd93f6d286fa4e481b70c8003dec6` | No upstream delta. | **DEFER — Phase 251.** Add only if the mapped inspection design still needs a custom caret; native select behavior remains the baseline. |
| 11 | `lib/threadline/operator_surface/components/surface_header.ex` | Replaces theme radios plus Apply with three immediate-submit theme buttons. `854a573a27cbb29ff0bb3ce6a7f93886c2bf16ee` | No upstream delta. | **DEFER — Phase 250.** Reassess radio/group semantics, keyboard model, CSRF, host mount authorization, and no-JavaScript behavior before carrying the markup. |
| 12 | `lib/threadline/operator_surface/live/coverage_live.ex` | Makes schema selection immediate; adds hint, custom select wrapper and shortened Refresh control. `e9ef55062a5c2ee792b6e4c106188b611e2f0812` | No upstream delta. | **REPLACE — Phase 251.** Implement from the Phase 249 route/state map; explicitly preserve URL restoration, invalid schema, and unavailable-versus-empty meanings. |
| 13 | `lib/threadline/operator_surface/live/evidence_live.ex` | Adds latest-mode explanatory lede and groups scope-card content. `b710ff1717ffbd6f14bd1f8e3b6eab1ff886963a` | No upstream delta. | **REPLACE — Phase 251.** Re-evaluate the extra prose against the approved plain-language job and avoid tests that lock incidental layout. |
| 14 | `lib/threadline/operator_surface/live/policy_redaction_live.ex` | Moves schema control into the header, makes selection immediate, and groups policy content. `6966ee83aaaacd49ab3c35fd27cea5d73111bd7b` | No upstream delta. | **REPLACE — Phase 251.** Rebuild from the mapped Redaction inspection job; preserve policy scope and distinguish missing, left out, redacted, and unavailable data. |
| 15 | `lib/threadline/operator_surface/live/start_live.ex` | Removes home-card kicker labels. `c34299d1c91391d2016bce9a24886f07fb848fc8` | No upstream delta. | **REPLACE — Phase 251.** Design the home hierarchy from mapped jobs; do not transplant label removal without checking what orientation those labels provide. |
| 16 | `lib/threadline/operator_surface/live/timeline_live/filters.ex` | Removes the status styling class from the matching-changes fact. `e7730e0f764771daf9033139fe88fbb6fb0e7c9c` | No upstream delta. | **REPLACE — Phase 251.** Reassess the fact’s meaning and neutral presentation in the investigation screen; retain explicit status wording where applicable. |
| 17 | `lib/threadline/operator_surface/style/02_base_shell.css` | Styles the compact button theme picker and selected state. `bc8a8c5408b2b4018078d4a9ae39c1654486593f` | No upstream delta. | **DEFER — Phase 250.** Style only after control semantics are chosen; map interaction colors to approved theme roles, not the logo thread color quoted above. |
| 18 | `lib/threadline/operator_surface/style/03_page_home.css` | Adds schema-control layout and removes home kicker styles. `a69ff43b3c0fbb115f311e598e5b44d3f0b62543` | No upstream delta. | **REPLACE — Phase 251.** Keep only the needed layout intent after route and screen mapping; avoid carrying both schema and home changes as an opaque CSS bundle. |
| 19 | `lib/threadline/operator_surface/style/06_layout_primitives.css` | Adds bottom margin to every direct page child card. `3b7c851f6d5c2add15d700c5e0e66f1a330f4291` | No upstream delta. | **REPLACE — Phase 251.** If spacing evidence justifies it, scope spacing to the owning component instead of changing all direct page cards. |
| 20 | `lib/threadline/operator_surface/style/07_find_detail.css` | Adds shared section-body/footer spacing for Evidence and Redaction. `eb9ab6e5d474b07c6589bb735a62e02e8948f15e` | No upstream delta. | **DEFER — Phase 251.** Validate the shared pattern against both screens and real Storybook wrapper ancestry before keeping it. |
| 21 | `lib/threadline/operator_surface/style/08_overlays_motion.css` | Resets margin on key/value values. `98a1a35139de5dad46e86408c0bb87850685e71f` | No upstream delta. | **DEFER — Phase 251.** Retest exact-value layouts at affected screens; keep only if it corrects an observed browser layout defect. |
| 22 | `lib/threadline/operator_surface/style/09_responsive.css` | Changes summary-grid and coverage-table column sizing. `0e27cf79d7602e0f6f6f21c7d340148bcc97b37f` | No upstream delta. | **DEFER — Phase 251; prove in 253.** Recheck the final component in its actual container at supported narrow widths and relevant zoom. |
| 23 | `test/fixtures/style/operator_surface.css` | Mirrors candidate theme, schema, section and responsive CSS. `49b5c008e3119dee5352bffb00247569aa08b22a` | No upstream delta. | **DEFER — same phase as accepted styles.** Regenerate or sync only with the production stylesheet change so the fixture cannot become an independent design authority. |
| 24 | `test/threadline/operator_surface/coverage_doc_contract_test.exs` | Changes the source contract from Apply schema wording to Database schema wording. `adb4086ad1b14462c3c001ee0c68b637675e3726` | No upstream delta. | **DEFER — Phase 251.** Update with final screen copy and keep the test focused on adopter-visible documentation alignment. |
| 25 | `test/threadline/operator_surface/live/coverage_live_test.exs` | Expects immediate schema selection and shorter Refresh wording. `8fa33b143e9e578012a1c3e3765bb6bdf5b4114d` | No upstream delta. | **DEFER — Phase 251.** Keep URL patch and unavailable-state coverage; align form events with the accepted interaction. |
| 26 | `test/threadline/operator_surface/live/evidence_live_test.exs` | Requires new lede text and a section-body class. `f7569b12d15cb8bcd3775112a13ea662ca9e08e9` | No upstream delta. | **REPLACE — Phase 251.** Test the Evidence job and truthful states rather than exact optional prose or wrapper classes. |
| 27 | `test/threadline/operator_surface/live/policy_redaction_live_test.exs` | Expects immediate schema change, Database schema text and shorter Refresh wording. `2692af96e6d04a737010280fe17efdd368b73253` | No upstream delta. | **DEFER — Phase 251.** Preserve behavioral checks for policy scope and failure states; update expected controls with the accepted design. |
| 28 | `test/threadline/operator_surface/live/start_live_test.exs` | Expects the selected theme submit button through `aria-pressed`. `32c28ef42e15df4f4dad91be8aa66284836ab6f2` | No upstream delta. | **DEFER — Phase 250.** Assert the final theme preference, server response and host-safe behavior rather than a provisional markup shape alone. |
| 29 | `test/threadline/operator_surface/style_contract_test.exs` | Replaces checked-radio/kicker/table assertions with candidate button and layout assertions. `8b69ce50ceea495d223953b83461a81792e06ccc` | Current main adds `@moduletag :repo_contract`; preserve. | **REPLACE — Phases 250/251.** Rewrite contract assertions against approved styles and retain the current-main module tag. |
| 30 | `test/threadline/operator_surface/surface_header_csp_test.exs` | Adds native submit, theme field and no-Apply source checks. `2abcfbc4f857456611b749a9cc33fc33344e6aa8` | No upstream delta. | **DEFER — Phase 250.** Keep CSRF/CSP and no-JavaScript guarantees, but prove the real authorized mount/post path as well as markup. |
| 31 | `test/threadline/operator_surface/surface_header_test.exs` | Replaces radio markup checks with immediate theme-button and selected-state checks. `643981c0f9c5da67a8bf2ad467e05522be2b4d41` | No upstream delta. | **DEFER — Phase 250.** Verify the final accessible single-choice interaction and theme persistence before locking markup expectations. |

## Minimal Phase 248 baseline artifact and owners

Create one artifact, `248-CANDIDATE-BASELINE.md`, containing: current-main base commit and isolated candidate identity; preserved candidate branch/HEAD and confirmation it remains untouched; approved brand-source repo-relative paths plus the three blob IDs above; the 31-row disposition matrix; four upstream path-overlap notes; and a proof ledger with owner, command/evidence path, source revision, result, and unresolved blocker. This is sufficient for ADM-01 without duplicating route inventory or brand mapping that belongs to Phase 249. [RECOMMENDATION; ADM-01 verified at `.planning/REQUIREMENTS.md:12`, phase success criterion at `.planning/ROADMAP.md:58`]

**Proof owners:** Phase 248 orchestrator owns candidate identity, source preservation, and disposition completeness. The owning implementation phase owns any later replay and its behavior test: Phase 250 for theme/shell rows; Phase 251 for home, Timeline, Coverage, Evidence, and Redaction rows; Phase 253 for integrated zoom/responsive/browser evidence and final docs reconciliation. Final acceptance remains with the phase assigned by the roadmap, not with this research note. [RECOMMENDATION grounded in `.planning/research/v1.48-SUMMARY.md:7-15`]

**Work performed:** read-only inventory and source comparison. No candidate files were edited; no tests or browser checks were run; no commits were created.
