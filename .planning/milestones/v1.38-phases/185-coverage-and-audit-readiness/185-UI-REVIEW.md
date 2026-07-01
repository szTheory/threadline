# Phase 185 — UI Review

**Audited:** 2026-06-29
**Baseline:** `.planning/phases/185-coverage-and-audit-readiness/185-UI-SPEC.md`
**Screenshots:** not captured (no HTTP 200 dev server at localhost:3000, 5173, or 8080; 8080 returned 301)

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 4/4 | Prior refresh, invalid-schema, and verdict next-step copy findings are fixed and contract-locked. |
| 2. Visuals | 4/4 | One selected-schema verdict is the focal unit before table triage, with retired readiness structures absent. |
| 3. Color | 4/4 | Prior Add capture and action-accent findings are fixed: capture is warning-styled and declared actions use accent treatment. |
| 4. Typography | 4/4 | Phase 185 verdict, schema controls, actions, commands, and metadata use the declared token roles and mono treatment. |
| 5. Spacing | 4/4 | Verdict, picker, responsive table, and command/copy layouts use token spacing and no-overlap guards. |
| 6. Experience Design | 4/4 | Invalid, stale, empty, expected-gap, covered, uncovered, focus, and URL-state paths are handled and tested. |

**Overall: 24/24**

**Blockers:** none found.
**Warnings:** none found.

---

## Top 3 Priority Fixes

None. This final re-audit found 0 BLOCKER and 0 WARNING defects.

Closed prior findings:

1. **Copy drift is fixed** — refresh-failure, invalid-schema, and verdict next-step copy now match the UI-SPEC and source contracts.
2. **Action color treatment is fixed** — `Add capture` uses warning tokens; `Refresh`, `Apply schema`, `Use public schema`, and `View activity` use the accent action class.
3. **Post-fix assertions are present** — LiveView, doc, style, copy, and browser-spec assertions lock the repaired source/style behavior.

---

## Detailed Findings

### Pillar 1: Copywriting (4/4)

No BLOCKER/WARNING findings.

**PASS evidence:** The prior refresh-failure copy finding is fixed. UI-SPEC requires the stale message at `185-UI-SPEC.md:91`; current source renders `Could not refresh coverage for SCHEMA; showing last known results from CHECKED_AT. Retry refresh.` at `lib/threadline/operator_surface/live/coverage_live.ex:161-165`, and `coverage_live_test.exs:287-307` verifies stale refresh keeps last-good rows, checked text, and retry copy.

**PASS evidence:** The prior invalid-schema copy finding is fixed. `CoverageSchemas.validate/2` returns `Schema SCHEMA was not found.` at `lib/threadline/health/coverage_schemas.ex:27-37`; `render_invalid_schema/1` adds `Choose a schema from the list or use public schema.` and `Use public schema` at `lib/threadline/operator_surface/live/coverage_live.ex:257-265`; tests assert the invalid rendered copy and absence of stale rows at `test/threadline/operator_surface/live/coverage_live_test.exs:338-359`.

**PASS evidence:** The prior verdict next-step drift is fixed. UI-SPEC locks `Fix rows marked Needs capture, apply the migration, run ... then refresh.` and public verifier copy at `185-UI-SPEC.md:107-108`; `verdict_next_step/2` now renders those forms at `lib/threadline/operator_surface/live/coverage_live.ex:457-472`. LiveView and doc/source contracts lock the exact phrasing at `test/threadline/operator_surface/live/coverage_live_test.exs:133-140` and `test/threadline/operator_surface/coverage_doc_contract_test.exs:130-146`.

**PASS evidence:** Primary Coverage copy avoids retired overclaims and generic Timeline framing. The copy contract refutes `capture is complete`, `complete timeline answers`, generic `Open Timeline`, and retired remediation wording at `test/threadline/operator_surface/copy_contract_test.exs:241-267`.

### Pillar 2: Visuals (4/4)

No BLOCKER/WARNING findings.

**PASS evidence:** The page order matches the contract: `UI.page_header`, optional alert/stale banner, one `.tl-coverage-verdict`, then `[data-testid="coverage-table"]` at `lib/threadline/operator_surface/live/coverage_live.ex:132-178`. The verdict-before-table ordering and retired `tl-trust-rail` / metric / remediation structures are tested at `test/threadline/operator_surface/live/coverage_live_test.exs:118-164` and `219-244`.

**PASS evidence:** The verdict is a single scannable focal unit with eyebrow, status chip, title, selected-schema metadata, counts, and one next step at `lib/threadline/operator_surface/live/coverage_live.ex:272-300`. The table remains the row comparison/action surface only, with distinct `Needs capture`, `Expected gap`, and `Covered` rows at `lib/threadline/operator_surface/live/coverage_live.ex:184-239`.

**PASS evidence:** Browser-proof specs were updated to assert the selected-schema region and Coverage readability rather than old page-level structures: `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts:119-152`, `operator-responsive-mobile-first.spec.ts:438-445`, and `operator-features.spec.ts:122-137`.

### Pillar 3: Color (4/4)

No BLOCKER/WARNING findings.

**PASS evidence:** The prior `Add capture` styling finding is fixed. UI-SPEC reserves warning/danger status cues for needs-capture affordances at `185-UI-SPEC.md:76-80`; `.tl-row-action__summary` now uses warning border/background/text tokens at `lib/threadline/operator_surface/style.ex:2944-2983`, and the style contract locks this at `test/threadline/operator_surface/style_contract_test.exs:654-660`.

**PASS evidence:** The prior declared-action accent finding is fixed. UI-SPEC reserves accent for `Refresh`, `Apply schema`, `Use public schema`, covered-row `View activity`, links, and focus at `185-UI-SPEC.md:67-70`. Current markup uses `tl-button--quiet-primary` for those actions at `lib/threadline/operator_surface/live/coverage_live.ex:145-154`, `230-233`, `262-264`, and `317`; `.tl-button--quiet-primary` uses info/accent tokens and accent hover treatment at `lib/threadline/operator_surface/style.ex:1578-1592`; contracts lock the class and token treatment at `test/threadline/operator_surface/coverage_doc_contract_test.exs:130-146` and `test/threadline/operator_surface/style_contract_test.exs:662-666`.

**PASS evidence:** Status color is paired with non-color copy cues. Not-ready, ready/tracked-ready, and empty verdict stripes use danger/success/warning tokens at `lib/threadline/operator_surface/style.ex:3792-3815`, while chips and row labels render `Needs capture`, `Expected gap`, `Excluded from readiness`, and `Covered` at `lib/threadline/operator_surface/live/coverage_live.ex:184-232`.

### Pillar 4: Typography (4/4)

No BLOCKER/WARNING findings.

**PASS evidence:** Phase 185-specific typography follows the declared scale in `185-UI-SPEC.md:48-57`: page header uses heading/label tokens at `lib/threadline/operator_surface/style.ex:944-958`, schema controls use label styling at `style.ex:969-984`, verdict title/counts use the 24px title/display role at `style.ex:3830-3874`, and the next-step sentence uses body sizing at `style.ex:3876-3881`.

**PASS evidence:** Commands, schema/table references, and machine values retain mono and wrapping treatment. Remediation commands use `var(--tl-font-mono)`, label size, and `overflow-wrap: anywhere` at `lib/threadline/operator_surface/style.ex:2902-2915`; Coverage table code uses mono and wrapping at `style.ex:2653-2658` and is constrained for Coverage rows at `style.ex:3888-3892`.

**PASS evidence:** The source contracts explicitly lock the Phase 185 verdict typography at `test/threadline/operator_surface/style_contract_test.exs:624-645` and the global readable typography tokens at `style_contract_test.exs:954-990`.

### Pillar 5: Spacing (4/4)

No BLOCKER/WARNING findings.

**PASS evidence:** Phase 185 layout uses existing token spacing from the UI-SPEC scale (`185-UI-SPEC.md:30-45`): page actions and schema picker use `--tl-space-2` gaps at `lib/threadline/operator_surface/style.ex:961-984`, the verdict uses tokenized gap/margin/padding at `style.ex:3792-3801`, count cards use tokenized gaps/padding at `style.ex:3845-3860`, and row action/command-copy layouts use tokenized gaps and containment at `style.ex:2928-3003`.

**PASS evidence:** The responsive contract is covered in code and tests. Responsive table rows stack into labelled cards at `lib/threadline/operator_surface/style.ex:3972-4008`; command/copy controls use `grid-template-columns: minmax(0, 1fr) auto` at `style.ex:2996-3003`; Playwright checks 320/375/768/1024/1440 viewport containment, root overflow, and command/copy non-overlap at `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts:23-44`, `91-110`, and `119-152`.

**PASS evidence:** No source evidence of Phase 185 arbitrary spacing drift was found in the changed Coverage selectors. Existing global intermediate tokens `12px`, `20px`, and `40px` are permitted by `185-UI-SPEC.md:44`.

### Pillar 6: Experience Design (4/4)

No BLOCKER/WARNING findings.

**PASS evidence:** Schema selection uses the required native control. The form is `phx-submit="select-schema"` with `<select id="coverage-schema" name="schema">` at `lib/threadline/operator_surface/live/coverage_live.ex:308-318`; URL patching is handled at `coverage_live.ex:74-84`; tests verify the native select and `/audit/coverage?schema=public` patch at `test/threadline/operator_surface/live/coverage_live_test.exs:369-383`.

**PASS evidence:** Invalid schema handling preserves task safety. Invalid URLs keep the rejected schema in visible context, disable refresh, render `role="alert"`, keep the picker usable, provide `Use public schema`, and avoid stale table rows at `lib/threadline/operator_surface/live/coverage_live.ex:139-159` and `257-265`; tests cover uppercase, nonexistent, and injection-probe paths at `test/threadline/operator_surface/live/coverage_live_test.exs:338-367`.

**PASS evidence:** Stale refresh, expected gaps, row remediation, and contextual Timeline links are handled. Refresh failure preserves same-schema last-good data at `lib/threadline/operator_surface/live/coverage_live.ex:345-376`; expected-gap rows omit `Add capture` at `coverage_live.ex:211-220`; non-public row links include `table_schema` at `coverage_live.ex:493-499` and `test/threadline/operator_surface/live/coverage_live_test.exs:402-436`.

**PASS evidence:** Focus and browser interaction coverage exists. Focus rings cover buttons, inputs, selects, links, and summaries at `lib/threadline/operator_surface/style.ex:368-374`; disabled/in-flight button states are styled at `style.ex:1548-1570`; Playwright covers keyboard focus, disclosure operation, copy separation, and public Timeline link scope at `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts:46-78`, `156-187`, and `190-207`. The spec is admitted to the light/system lane at `examples/threadline_phoenix/e2e/playwright.config.ts:23-31`.

---

## Prior Finding Re-Check

| Prior Finding | Status | Evidence |
|---------------|--------|----------|
| Refresh-failure copy | Fixed | `coverage_live.ex:161-165`; `coverage_live_test.exs:287-307` |
| Invalid-schema copy | Fixed | `coverage_schemas.ex:27-37`; `coverage_live.ex:257-265`; `coverage_live_test.exs:338-359` |
| `Add capture` warning styling | Fixed | `style.ex:2944-2983`; `style_contract_test.exs:654-660` |
| Verdict next-step copy | Fixed | `coverage_live.ex:457-472`; `coverage_doc_contract_test.exs:130-146` |
| Declared action accent treatment | Fixed | `coverage_live.ex:145-154`, `230-233`, `262-264`, `317`; `style.ex:1578-1592`; `style_contract_test.exs:662-666` |
| Post-fix source/style assertions | Fixed | `coverage_live_test.exs:133-140`, `166-182`; `coverage_doc_contract_test.exs:130-146`; `style_contract_test.exs:654-666` |

---

## Verification Performed

- `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/health_test.exs` — PASS, 122 tests, 0 failures.
- `npm test -- --list tests/operator-coverage-readiness.spec.ts` from `examples/threadline_phoenix/e2e` — PASS, 21 tests discovered.

---

## Files Audited

- `.planning/phases/185-coverage-and-audit-readiness/185-01-SUMMARY.md`
- `.planning/phases/185-coverage-and-audit-readiness/185-01-PLAN.md`
- `.planning/phases/185-coverage-and-audit-readiness/185-UI-SPEC.md`
- `.planning/phases/185-coverage-and-audit-readiness/185-CONTEXT.md`
- `.planning/phases/185-coverage-and-audit-readiness/185-VERIFICATION.md`
- `.planning/phases/185-coverage-and-audit-readiness/185-REVIEW.md`
- `.planning/phases/185-coverage-and-audit-readiness/185-UI-REVIEW.md`
- `lib/threadline/operator_surface/live/coverage_live.ex`
- `lib/threadline/operator_surface/style.ex`
- `lib/threadline/operator_surface/presentation.ex`
- `lib/threadline/health/coverage_schemas.ex`
- `lib/mix/tasks/threadline.health.coverage.ex`
- `lib/mix/tasks/threadline.verify_coverage.ex`
- `test/threadline/operator_surface/live/coverage_live_test.exs`
- `test/threadline/operator_surface/style_contract_test.exs`
- `test/threadline/operator_surface/copy_contract_test.exs`
- `test/threadline/operator_surface/coverage_doc_contract_test.exs`
- `test/threadline/operator_surface/formless_pages_test.exs`
- `test/threadline/health_test.exs`
- `examples/threadline_phoenix/e2e/playwright.config.ts`
- `examples/threadline_phoenix/e2e/tests/operator-coverage-readiness.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-features.spec.ts`
- `guides/operator-surface.md`
- `guides/production-checklist.md`
