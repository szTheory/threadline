---
phase: 185-coverage-and-audit-readiness
plan: 01
generated_at: 2026-06-29T20:21:22Z
status: complete_with_residual
---

# Phase 185 Verification: Coverage and Audit Readiness

## Scope

Plan 185-01 changed the operator Coverage surface to answer one selected-schema audit-readiness question before table triage. The work stayed inside existing private LiveView, style, docs, and example-browser lanes.

## Targeted Command Evidence

| Command | Result | Evidence |
| --- | --- | --- |
| `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/copy_contract_test.exs` | Expected RED before implementation | 108 tests, 12 expected failures against old multi-block Coverage surface. |
| `mix test test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/coverage/on_mount_test.exs` | PASS | 111 tests, 0 failures after implementation and after Task 3 edits. |
| `mix format --check-formatted lib/threadline/operator_surface/live/coverage_live.ex lib/threadline/operator_surface/presentation.ex lib/threadline/operator_surface/style.ex test/threadline/operator_surface/live/coverage_live_test.exs test/threadline/operator_surface/coverage_doc_contract_test.exs test/threadline/operator_surface/style_contract_test.exs test/threadline/operator_surface/copy_contract_test.exs test/threadline/operator_surface/coverage/on_mount_test.exs` | PASS | No formatting output. |
| `mix verify.format` | PASS | No formatting output. |
| `mix verify.credo` | PASS | 230 files checked, 0 issues. |
| `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-coverage-readiness.spec.ts` | PASS | 21 Playwright tests passed across chromium, desktop-chromium, and mobile-chromium. |
| `mix verify.example_browser_light tests/operator-coverage-readiness.spec.ts` | PASS | 7 Playwright tests passed in `desktop-chromium-light`. |
| `mix test test/threadline/operator_surface/formless_pages_test.exs` | PASS | 6 tests, 0 failures after updating the stale display-only guard to exclude Coverage's Phase 185 native schema selector form. |
| `mix verify.test` | NON-GREEN RESIDUAL | 1157 tests, 2 failures after the Phase 185 formless guard repair. Remaining failures are `V123CharterDocContractTest` stale v1.37 PROJECT.md posture text and `ExportsDocContractTest` Timeline export `download` attribute source-contract drift; neither touches Coverage readiness. |
| `cd examples/threadline_phoenix && mix precommit` | NON-GREEN RESIDUAL | 109 tests, 7 failures in existing demo seed/audit-history tests. Failures were missing seeded audit transactions / actor attribution rows, not Coverage UI, e2e, docs, style, schema selection, or route/auth/testid behavior. |

## Requirement Coverage

| Requirement | Evidence | Status |
| --- | --- | --- |
| COV-01 | CoverageLive tests and browser spec prove one `Selected schema readiness` region appears before `[data-testid="coverage-table"]` with schema, checked time, counts, and next action. | Covered |
| COV-02 | Source/style/copy contracts reject retired trust rail, metric tiles, page-level remediation, generic Timeline CTA, and completion overclaims. Row actions remain contextual. | Covered |
| COV-03 | LiveView tests cover native schema select, invalid schema recovery, stale refresh semantics, expected-gap behavior, public/non-public Timeline links, docs, and on_mount boundaries. Browser tests cover viewport/focus/disclosure/copy/public-link affordances. | Covered |

## Decision Coverage

| Decision Range | Verification |
| --- | --- |
| D-185-01 through D-185-07 | One verdict replaces dashboard/table-first readiness signals; table remains row triage below the verdict. |
| D-185-08 through D-185-14 | Schema-level next step plus row-level Add capture disclosures; expected gaps show `Excluded from readiness`; public links omit `table_schema`; non-public links are covered by LiveViewTest. |
| D-185-15 through D-185-22 | Native `<select id="coverage-schema" name="schema">`, URL state, `CoverageSchemas` validation, invalid recovery, stale last-good timestamp, and distinct public header badge preserved. |
| D-185-23 through D-185-28 | Targeted state lattice plus narrow Playwright proof; no broad screenshot matrix added. |
| D-185-29 through D-185-34 | Copy contracts and docs use audit-readiness language without completion overclaims or unsafe generic Timeline framing. |
| D-185-35 through D-185-39 | No new dependency, route, public API, schema object, auth boundary change, capture/query semantic change, custom select widget, or localStorage behavior. |

## Threat Evidence

| Threat | Evidence |
| --- | --- |
| T-185-01 schema tampering | Invalid schema tests assert escaped rejected values, usable picker, `Use public schema`, and no stale table rows. |
| T-185-02 stale refresh spoofing | Tests/source assert `%{previous | error: message}` and preserve last-good `last_checked_at` on refresh failure. |
| T-185-03 non-public link disclosure | LiveViewTest creates a deterministic non-public schema and asserts `table_schema=tenant_demo&table=coverage_link_target`. |
| T-185-04 unsafe command copy | Existing `Presentation.coverage_remediation/2` contracts keep copyable generator commands to safe public identifiers; browser proof checks command/copy layout only for deterministic public-safe rows. |
| T-185-05 XSS/rendering | Schema/table values render through HEEx interpolation; invalid semicolon schema probe returns an error alert without raw HTML behavior. |
| T-185-06 docs/header distinction | Operator guide documents selected-schema page readiness separately from the public-schema shell badge. |
| T-185-07 proof scope | Browser proof uses one narrow spec admitted to the existing light lane; no screenshot baseline expansion. |

## Posture Checks

- Package installs: no package dependency was added. Existing e2e runner executed its normal `npm install`/Playwright setup against the committed lockfile.
- JS ORM/schema push: none.
- Screenshot baselines: none added or modified.
- Route paths: `/audit/coverage` and `/audit/timeline` preserved; no `/coverage/:schema` route.
- Auth/feature gates: operator auth, `coverage_authorize_fn`, and feature gates preserved.
- Stable test ids: `[data-testid="coverage-table"]` preserved.

## Residual Classification

`cd examples/threadline_phoenix && mix precommit` is non-green due to existing demo seed/audit-history expectations:

- `ThreadlinePhoenixWeb.WalkthroughEvidenceTest` could not find the #4521 close transaction evidence row.
- `ThreadlinePhoenixWeb.WalkthroughHappyPathTest` could not find the #4518 delete audit row.
- `ThreadlinePhoenix.DemoContractTest` reported missing ticket close, delete, leaving-agent, and `org_memberships` actor-attribution audit rows.

These failures are outside Phase 185 Coverage UI scope. The Phase 185 targeted Mix slice and both narrow browser closeout commands passed.

The orchestrator post-merge `mix verify.test` gate initially surfaced one Phase 185-related guard failure: `FormlessPagesTest` still listed `coverage_live` as display-only. That stale guard was fixed in commit `067c0c11` by documenting Coverage as the Phase 185 native schema selector exception. Re-running `mix verify.test` left only the two inherited residuals listed above.
