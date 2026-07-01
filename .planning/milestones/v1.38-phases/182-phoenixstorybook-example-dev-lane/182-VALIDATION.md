---
phase: 182
slug: phoenixstorybook-example-dev-lane
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-26
audited_at: 2026-06-27T09:53:15-04:00
---

# Phase 182 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Elixir 1.19.5; Phoenix.LiveViewTest; Playwright Test 1.60.0 |
| **Config file** | `mix.exs`, `examples/threadline_phoenix/mix.exs`, `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix verify.compile_no_optional && mix test test/threadline/operator_surface/storybook_boundary_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs && cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_route_test.exs test/threadline_phoenix_web/storybook_stories_test.exs` |
| **Full suite command** | `mix ci.all` plus `cd examples/threadline_phoenix && mix precommit` when example-app files change |
| **Estimated runtime** | Targeted source/route slice: under 90 seconds; full suite depends on example-app and E2E setup |

---

## Sampling Rate

- **After every task commit:** Run `mix verify.compile_no_optional` plus the targeted ExUnit file for the touched Storybook boundary, route, story, or docs contract.
- **After every plan wave:** Run `mix verify.example` and the relevant Storybook/stress browser smoke when rendered behavior changed.
- **Before `/gsd:verify-work`:** Run `mix ci.all`, the bounded Storybook Playwright smoke, and `cd examples/threadline_phoenix && mix precommit` if example app files changed.
- **Max feedback latency:** Keep task-level feedback under 90 seconds where possible; move slower browser evidence to wave or phase gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 182-01-T1 | 182-01 | 1 | STORY-01, STORY-03 | T-182-01, T-182-03 | PhoenixStorybook terms stay out of root package/source surfaces and docs keep Storybook separate from `/audit/__stress`. | source/docs contract | `mix test test/threadline/operator_surface/storybook_boundary_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs` | yes | COVERED |
| 182-01-T2 | 182-01 | 1 | STORY-01, STORY-02 | T-182-01, T-182-02 | Example route/story contracts require dev/test route presence, production absence, wrapper, category spine, themes, and fixture provenance. | route/story contract | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_route_test.exs test/threadline_phoenix_web/storybook_stories_test.exs` | yes | COVERED |
| 182-01-T3 | 182-01 | 1 | STORY-02, STORY-03 | T-182-02 | Bounded browser smoke is discoverable and scoped to representative Storybook documentation, not `/audit/__stress` flows. | browser smoke scaffold | `cd examples/threadline_phoenix/e2e && npx playwright test --list tests/operator-storybook.spec.ts` | yes | COVERED |
| 182-02-T1 | 182-02 | 2 | STORY-01 | T-182-02, T-182-SC | `phoenix_storybook` is example-app dev/test-only and root optional-dependency compile remains green. | package/source contract | `mix verify.compile_no_optional && mix test test/threadline/operator_surface/storybook_boundary_test.exs` | yes | COVERED |
| 182-02-T2 | 182-02 | 2 | STORY-01 | T-182-04, T-182-05 | `/dev/storybook` and assets are mounted only behind example `dev_routes`, outside `/audit`, and absent from production config. | route contract | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_route_test.exs` | yes | COVERED |
| 182-03-T1 | 182-03 | 3 | STORY-02 | T-182-07, T-182-08 | Storybook wrapper uses real Threadline CSS/theme scope and fixture helpers use static samples plus explicit allowlists. | story source contract | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_stories_test.exs` | yes | COVERED |
| 182-03-T2 | 182-03 | 3 | STORY-02 | T-182-07, T-182-09 | Foundations, Primitives, Forms, and States stories cover the UI-SPEC minimum or source-backed rationale. | story source contract | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_stories_test.exs` | yes | COVERED |
| 182-04-T1 | 182-04 | 4 | STORY-02 | T-182-10, T-182-11 | Overlays and Data Display stories cover supported components with inert destructive examples and representative ugly data. | story source contract | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_stories_test.exs` | yes | COVERED |
| 182-04-T2 | 182-04 | 4 | STORY-02, STORY-03 | T-182-12 | Groups and Patterns stories remain curated, allowlisted component documentation and do not generate from the stress ledger. | story/stress contract | `mix test test/threadline/operator_surface/stress_fixtures_test.exs test/threadline/operator_surface/stress_ledger_test.exs` | yes | COVERED |
| 182-04-T3 | 182-04 | 4 | STORY-02, STORY-03 | T-182-10, T-182-11, T-182-12 | Browser smoke renders the index and representative category stories with assets, themes, and no horizontal overflow; stress verifier remains separate. | browser smoke | `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-storybook.spec.ts && mix verify.operator_stress` | yes | COVERED |
| 182-05-T1 | 182-05 | 5 | STORY-01, STORY-03 | T-182-13 | README and operator guide document Storybook as maintainer-only example tooling and avoid adopter install guidance. | docs contract | `mix test test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs` | yes | COVERED |
| 182-05-T2 | 182-05 | 5 | STORY-01, STORY-02, STORY-03 | T-182-14, T-182-15 | Verification closeout records exact targeted pass evidence and classifies inherited broad-suite residuals. | evidence contract | `test -s .planning/phases/182-phoenixstorybook-example-dev-lane/182-VERIFICATION.md && rg -n "STORY-01|STORY-02|STORY-03|D-182-01|D-182-26" .planning/phases/182-phoenixstorybook-example-dev-lane/182-VERIFICATION.md` | yes | COVERED |
| 182-GATE | 182-05 | final | STORY-01, STORY-02, STORY-03 | T-182-01..15, T-182-SC | Phase closes when targeted Storybook/package/route/story/browser/stress/docs evidence is green and inherited full-suite residuals are classified. | full suite + evidence | `mix ci.all` and `cd examples/threadline_phoenix && mix precommit` | yes | PARTIAL - classified residuals |

---

## Automated Coverage Audit

- [x] `test/threadline/operator_surface/storybook_boundary_test.exs` - root absence and source/dependency contract for STORY-01.
- [x] `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_route_test.exs` - dev/test route and production absence for STORY-01.
- [x] `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs` - Storybook backend/category/wrapper/taxonomy/fixture/UI-SPEC contracts for STORY-02.
- [x] `examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts` - bounded browser smoke for STORY-02 and STORY-03.
- [x] `test/threadline/example_phoenix_readme_contract_test.exs` and `test/threadline/operator_surface_doc_contract_test.exs` - docs posture for STORY-03.
- [x] `mix verify.operator_stress` - `/audit/__stress` remains the authenticated operator-flow stress harness.

Audit result: no missing automated verification was found during the 2026-06-27 Nyquist audit. The only non-green gate is the broad suite closure row already classified in `182-VERIFICATION.md` as inherited residuals outside Phase 182 Storybook/docs scope.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Story taxonomy review | STORY-02 | Automated tests can prove category files and smoke renders, but maintainers must confirm the selected categories document the most useful private component states without becoming a full page-flow matrix. | Review the Storybook sidebar and notes for Foundations, Primitives, Forms, States, Overlays, Data Display, Groups, and the small Patterns branch. Confirm stories are component documentation, not `/audit/__stress` replacements. |
| Ugly-data representativeness | STORY-02 | Tests can assert sampled ugly data exists, but the final data mix needs human judgement against the design-system ratchet and Phase 181 findings. | Confirm stories include representative long IDs, long strings, non-ASCII, null fields, mixed severity, permission denied, stale/reconnecting, pagination boundary, timezone boundary, disabled, error, and empty/zero states where relevant. |
| Documentation posture | STORY-03 | Source assertions catch banned wording, but final docs need maintainer/adopter tone review. | Review `examples/threadline_phoenix/README.md` and touched operator docs. Confirm adopters are not told to install PhoenixStorybook, and that Storybook-vs-stress scope is explicit. |

---

## Validation Audit 2026-06-27

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Audited commands run during validate-phase:

- `mix verify.compile_no_optional` - PASS.
- `mix test test/threadline/operator_surface/storybook_boundary_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs` - PASS; 24 tests, 0 failures.
- `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_route_test.exs test/threadline_phoenix_web/storybook_stories_test.exs` - PASS; 13 tests, 0 failures.
- `./examples/threadline_phoenix/e2e/run-e2e.sh tests/operator-storybook.spec.ts` - PASS; 39 Playwright tests passed.
- `mix verify.operator_stress` - PASS; 42 passed, 9 configured skips.

## Validation Sign-Off

- [x] All tasks have automated verify commands or explicit manual-only rationale.
- [x] Sampling continuity: no three consecutive implementation tasks landed without targeted source, route, docs, or rendered evidence.
- [x] Wave 0 covered all missing Storybook-specific contract files.
- [x] No watch-mode flags are used in verification commands.
- [x] Task feedback latency stays under 90 seconds where possible for source contracts; browser evidence is isolated to wave/phase gates.
- [x] `mix ci.all` residual failures are classified in `182-VERIFICATION.md` with evidence they are inherited and unrelated.
- [x] `nyquist_compliant: true` remains set in frontmatter.

**Approval:** verified 2026-06-27
