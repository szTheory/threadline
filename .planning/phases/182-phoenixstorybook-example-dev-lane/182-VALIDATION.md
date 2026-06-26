---
phase: 182
slug: phoenixstorybook-example-dev-lane
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-26
---

# Phase 182 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Elixir 1.19.5; Phoenix.LiveViewTest; Playwright Test 1.60.0 |
| **Config file** | `mix.exs`, `examples/threadline_phoenix/mix.exs`, `examples/threadline_phoenix/e2e/playwright.config.ts` |
| **Quick run command** | `mix verify.compile_no_optional && cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_route_test.exs` |
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
| 182-W0-01 | TBD | 0 | STORY-01 | T-182-01 | PhoenixStorybook dependency and router code stay out of root `threadline` and production host surface | source contract | `mix test test/threadline/operator_surface/storybook_boundary_test.exs && mix verify.compile_no_optional` | W0 missing | pending |
| 182-W0-02 | TBD | 0 | STORY-01 | T-182-01 | `/dev/storybook` route and assets exist only when the example app enables dev/test routes and are absent in production config | route contract | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_route_test.exs` | W0 missing | pending |
| 182-W0-03 | TBD | 0 | STORY-02 | T-182-02 | Storybook backend discovers curated categories and renders through the Threadline wrapper with `data-tl-theme` lanes | component/render contract | `cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix_web/storybook_stories_test.exs` | W0 missing | pending |
| 182-W0-04 | TBD | 0 | STORY-02, STORY-03 | T-182-02 | Bounded browser smoke proves Storybook index and representative stories render with assets, themes, ugly data, and no `/audit/__stress` replacement behavior | browser smoke | `cd examples/threadline_phoenix/e2e && npm test -- operator-storybook.spec.ts` | W0 missing | pending |
| 182-W0-05 | TBD | 0 | STORY-03 | T-182-03 | Docs preserve Storybook as maintainer component documentation and `/audit/__stress` as authenticated operator-flow stress testing | docs/source contract | `mix test test/threadline/example_phoenix_readme_contract_test.exs test/threadline/operator_surface/stress_router_test.exs` | existing tests need assertions | pending |
| 182-GATE | TBD | final | STORY-01, STORY-02, STORY-03 | T-182-01..03 | Phase closes only when root optional-dependency hygiene, example-app Storybook behavior, bounded browser smoke, and docs contracts all pass | full suite + evidence | `mix ci.all` and `cd examples/threadline_phoenix && mix precommit` | full suite commands exist | pending |

---

## Wave 0 Requirements

- [ ] `test/threadline/operator_surface/storybook_boundary_test.exs` - root absence and source/dependency contract for STORY-01.
- [ ] `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_route_test.exs` - dev/test route and production absence for STORY-01.
- [ ] `examples/threadline_phoenix/test/threadline_phoenix_web/storybook_stories_test.exs` - Storybook backend/category/wrapper smoke for STORY-02.
- [ ] `examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts` - bounded browser smoke for STORY-02 and STORY-03.
- [ ] Additional assertions in `test/threadline/example_phoenix_readme_contract_test.exs` and, if needed, operator docs contract tests for STORY-03.

Existing infrastructure covers Mix, ExUnit, Phoenix.LiveViewTest, and Playwright. Wave 0 creates the missing Storybook-specific contract files before implementation relies on them.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Story taxonomy review | STORY-02 | Automated tests can prove category files and smoke renders, but maintainers must confirm the selected categories document the most useful private component states without becoming a full page-flow matrix. | Review the Storybook sidebar and notes for Foundations, Primitives, Forms, States, Overlays, Data Display, Groups, and the small Patterns branch. Confirm stories are component documentation, not `/audit/__stress` replacements. |
| Ugly-data representativeness | STORY-02 | Tests can assert sampled ugly data exists, but the final data mix needs human judgement against the design-system ratchet and Phase 181 findings. | Confirm stories include representative long IDs, long strings, non-ASCII, null fields, mixed severity, permission denied, stale/reconnecting, pagination boundary, timezone boundary, disabled, error, and empty/zero states where relevant. |
| Documentation posture | STORY-03 | Source assertions catch banned wording, but final docs need maintainer/adopter tone review. | Review `examples/threadline_phoenix/README.md` and touched operator docs. Confirm adopters are not told to install PhoenixStorybook, and that Storybook-vs-stress scope is explicit. |

---

## Validation Sign-Off

- [ ] All tasks have automated verify commands or explicit manual-only rationale.
- [ ] Sampling continuity: no three consecutive implementation tasks can land without targeted source, route, docs, or rendered evidence.
- [ ] Wave 0 covers all missing Storybook-specific contract files.
- [ ] No watch-mode flags are used in verification commands.
- [ ] Task feedback latency stays under 90 seconds where possible.
- [ ] `mix ci.all` is green, or all residual failures are classified in `182-VERIFICATION.md` with evidence they are inherited and unrelated.
- [ ] `nyquist_compliant: true` remains set in frontmatter.

**Approval:** pending
