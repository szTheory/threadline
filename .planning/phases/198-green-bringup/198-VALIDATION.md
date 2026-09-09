---
phase: 198
slug: green-bringup
status: validated
nyquist_compliant: false
wave_0_complete: true
created: 2026-08-27
validated: 2026-09-08
---

# Phase 198 — Validation Strategy

Phase 198 is validated but not Nyquist-compliant. Eleven requirements have current
automated behavioral or contract proof. `GREEN-07` remains PARTIAL because its literal
`origin/main` ancestry clause is false: at the latest audit `origin/main..HEAD` contained 275
commits. No test, documentation edit, or local commit can make that remote-state clause
true.

## Test Infrastructure

| Layer | Framework / runner | Primary command | Role |
|---|---|---|---|
| Library and contract tests | ExUnit, `test/test_helper.exs` | `mix test <files>` | Behavioral, source-contract, evidence-contract, and script-fixture proof |
| Example application | ExUnit in `examples/threadline_phoenix` | `MIX_ENV=test mix test <files>` | Demo/reset/walkthrough integration proof |
| Browser | Playwright, `examples/threadline_phoenix/e2e/playwright.config.ts` | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium` | Browser behavior and capture lanes |
| Workflow contracts | shell + YAML (`bash`, `yq`, `jq`) | commands embedded in PLAN verify blocks | Job bounds, gate topology, artifacts, and repository invariants |
| Live GitHub state | `gh` + committed attestations | `bash bin/verify-branch-protection` | Required-context emission and ruleset observation |

The local asdf shim required explicit audit-only environment selection because the
untracked `.tool-versions` names only Node: `ASDF_ELIXIR_VERSION=1.19.5-otp-28
ASDF_ERLANG_VERSION=28.4.1`. The file was not edited.

## Requirement Coverage

| Requirement | Classification | Behavioral proof | Current result |
|---|---|---|---|
| GREEN-01 | COVERED | `phase198_nyquist_contract_test.exs` rejects missing/vacuous logs and missing staleness/job evidence | green |
| GREEN-02 | COVERED | same test parses the Credo JSON, reconciles 377 issues to the report, and proves full-default > baseline | green |
| GREEN-03 | COVERED | same test requires insensitive text variants plus failing token positive control and source-backed finding | green |
| GREEN-04 | COVERED | current ExUnit contracts plus committed CI attestations; stale-schema, storage-prefix, demo, and walkthrough tests remain named below | green |
| GREEN-05 | COVERED | `ui_form_policy_contract_test.exs` derives the complete LiveView roster and fails on undeclared/formless drift | green |
| GREEN-06 | COVERED | `phase198_nyquist_contract_test.exs` derives every job and timeout bound and requires the CI-only Playwright failure cap | green |
| GREEN-07 | PARTIAL | credential, topology, browser, attestation, and lifecycle contracts are green; literal remote ancestry is false | **manual-only blocker** |
| GREEN-08 | COVERED | `ci_topology_contract_test.exs`, `branch_protection_comparison_contract_test.exs`, and live verifier | green |
| GREEN-09 | COVERED | workflow-wide paid-key resurrection guard in `ci_topology_contract_test.exs` | green |
| GREEN-10 | COVERED | exact-one-publisher behavioral source contract in `ci_topology_contract_test.exs` | green |
| GREEN-11 | COVERED | six-row classifier behavior table plus workflow reachability/wiring contracts | green |
| GREEN-12 | COVERED | archive-register rows resolve to annotated local tags; remote archive tags observed | green |

## Complete Per-Task / Requirement Map

Every executed task is listed. A row may share one named command where the plan's tasks
exercise the same behavior. `manual` means the plan intentionally used a human decision
or live observation; it is not silently converted to machine coverage.

| Task IDs | Requirements | Verification owner | Status |
|---|---|---|---|
| 01-T1 | GREEN-01 | `phase198_nyquist_contract_test.exs` | green |
| 01-T2 | GREEN-02 | `phase198_nyquist_contract_test.exs` | green |
| 01-T3 | GREEN-03 | `phase198_nyquist_contract_test.exs` | green |
| 02-T1, 02-T2 | GREEN-07 | credential artifacts + scanners | green component / requirement partial |
| 02-T3 | GREEN-07 | `phase198_decision_attestation_test.exs`; recorded blocking-human authorization | green component / requirement partial |
| 03-T1, 03-T2 | GREEN-08 | `ci_topology_contract_test.exs`; `bin/verify-branch-protection` | green |
| 03-T3 | GREEN-07 | min-lane rehearsal artifact | green component / requirement partial |
| 04-T1, 04-T2 | GREEN-04 | `mix test.reset`; `zero_skips_contract_test.exs` | green |
| 04-T3 | GREEN-05 | `operator_surface/ui_form_policy_contract_test.exs` | green |
| 05-T1, 05-T3 | GREEN-06 | Playwright config + derived workflow-bound contract | green |
| 05-T2, 05-T4 | GREEN-07 | `ci_coverage_doc_contract_test.exs`; CI cache contract | green component / requirement partial |
| 06-T1 | GREEN-12 | `phase198_nyquist_contract_test.exs` + remote tag query | green |
| 06-T2 | GREEN-10 | recorded blocking-human publish decision + attestation test | green |
| 06-T3 | GREEN-09, GREEN-10 | `ci_topology_contract_test.exs` | green |
| 06-T4 | GREEN-11 | `flake_classifier_contract_test.exs` | green |
| 07-T1 | GREEN-07, GREEN-12 | recorded blocking-human authorization | green components / GREEN-07 partial |
| 07-T2 | GREEN-08 | `branch_protection_comparison_contract_test.exs`; live verifier | green |
| 07-T3 | GREEN-07, GREEN-12 | remote ancestry/tag observation | GREEN-12 green; GREEN-07 partial |
| 08-T1, 08-T2 | GREEN-04 | transaction LiveView + storage-prefix contracts | green |
| 09-T1, 09-T2 | GREEN-07 | warnings-as-errors/no-optional compile + `optional_deps_contract_test.exs` | green component / requirement partial |
| 10-T1, 10-T2, 10-T3 | GREEN-07 | mechanical, bundle-shape, and example-browser lanes | green components / requirement partial |
| 11-T1, 11-T2, 11-T3 | GREEN-11 | `flake_classifier_contract_test.exs` | green |
| 12-T1, 12-T2, 12-T3 | GREEN-04 | targeted directories + full ExUnit suite | green |
| 13-T1, 13-T2, 13-T3 | GREEN-01..GREEN-12 | full gate and measured closeout; later rounds supersede remote observations | GREEN-07 partial; others green |
| 14-T1, 14-T2, 14-T3 | GREEN-04 | PgBouncer integration + storage call-site contracts | green |
| 15-T1, 15-T2, 15-T3 | GREEN-04 | stress-router, zero-skip, topology, and prefix contracts | green |
| 16-T1, 16-T3 | GREEN-04 | byte-stability diagnosis + `mix verify.capture` | green |
| 16-T2 | GREEN-04 | recorded human remedy decision; not reclassified | manual, satisfied |
| 17-T1, 17-T3 | GREEN-04 | browser diagnosis artifact + real Playwright specs | green |
| 17-T2 | GREEN-04 | recorded human remedy decision; not reclassified | manual, satisfied |
| 18-T1, 18-T2 | GREEN-07 | local preflight + measured GitHub run | green components / requirement partial |
| 18-T3 | GREEN-07 | human measurement interpretation | manual; requirement partial |
| 19-T1, 19-T2, 19-T3 | GREEN-04 | YAML schema prep, storage sweep, full-suite record | green |
| 20-T1, 20-T3 | GREEN-07 | aggregate-decision artifact + append-only decision record | green components / requirement partial |
| 20-T2 | GREEN-07 | blocking-human aggregate membership decision | manual; requirement partial |
| 21-T1, 21-T2 | GREEN-07, GREEN-08 | YAML/docs/ruleset parity contracts | GREEN-08 green; GREEN-07 partial |
| 22-T1, 22-T2, 22-T3 | GREEN-04, GREEN-07 | measured round-3 run and requirement-state record | GREEN-04 green; GREEN-07 partial |
| 23-T1, 23-T2, 23-T3 | GREEN-04 | seed diagnosis artifact + demo contract | green |
| 24-T1, 24-T2 | GREEN-04 | demo contract and measured lane | green |
| 25-T1, 25-T2 | GREEN-04 | walkthrough happy/evidence integration tests | green |
| 26-T1, 26-T2, 26-T3 | GREEN-07 | full Playwright attribution + browser specs | green components / requirement partial |
| 27-T1, 27-T2, 27-T3 | GREEN-07 | phase UAT Playwright specs + reconciliation artifact | green components / requirement partial |
| 28-T1, 28-T3 | GREEN-07 | post-merge attribution + browser specs | green components / requirement partial |
| 28-T2 | GREEN-07 | recorded baseline-regeneration decision | manual; requirement partial |
| 29-T1, 29-T2, 29-T3 | GREEN-04, GREEN-07 | measured round-4 record | GREEN-04 green; GREEN-07 partial |
| 30-T1, 30-T2 | GREEN-04 | demo reset, contract, walkthrough, and evidence tests | green |
| 31-T1, 31-T2, 31-T3 | GREEN-07 | named Playwright regression specs | green components / requirement partial |
| 32-T1, 32-T2 | GREEN-04 | walkthrough evidence + demo contract | green |
| 33-T1, 33-T2, 33-T3 | GREEN-07 | Phase 177/135 Playwright behavior | green components / requirement partial |
| 34-T1 | GREEN-07 | recorded export-copy blocking-human decision | manual; component satisfied |
| 34-T2, 34-T3 | GREEN-07 | presentation/copy contracts + named Playwright specs | green components / requirement partial |
| 35-T1, 35-T2 | GREEN-04 | demo retention contracts + walkthrough suites | green |
| 36-T1, 36-T2 | GREEN-04, GREEN-07 | review-ledger ID equality + append-only deferral guard | GREEN-04 green; GREEN-07 partial |
| 37-T1, 37-T3 | GREEN-04, GREEN-07 | round-5 prediction + measured run | GREEN-04 green; GREEN-07 partial |
| 37-T2 | GREEN-07 | human push/PR checkpoint | manual; requirement partial |
| 38-T1, 38-T2, 38-T3 | GREEN-04 | demo/reset/advisory-lock/walkthrough behavioral tests | green |
| 39-T1 | GREEN-07 | blocking-human terminal disposition | manual; requirement partial |
| 39-T2, 39-T3 | GREEN-07, GREEN-08 | decision attestation + live-state record | GREEN-08 green; GREEN-07 partial |
| 40-T1, 40-T2, 40-T3 | GREEN-01..GREEN-12 | round-6 prediction/run/requirement reconciliation | GREEN-07 partial; others green |
| 41-T1, 41-T2 | GREEN-07, GREEN-08 | run `33354216172` attestation + atomic-lifecycle proof | GREEN-08 green; GREEN-07 partial |
| 42-T1, 42-T2 | GREEN-07, GREEN-08 | ruleset double-read + exact-SHA main selector | GREEN-08 green; GREEN-07 partial |

## Manual-Only / Escalated

| Behavior | Requirement | Why automation cannot close it | Required action |
|---|---|---|---|
| `origin/main` contains every local commit and its exact-head CI run is successful within budget | GREEN-07 | Live audit proved `origin/main..HEAD = 237`; a local test can observe but cannot merge or push. The phase explicitly forbids remote/ruleset mutation in Plans 41–42. | Maintainer-authorized merge/push, then re-run `git rev-list --count origin/main..HEAD`, select the newest exact-SHA `ci.yml` main push run, and require `CI required == success` within 20 minutes. |

No `human_judgment: true` entry was converted merely by changing metadata. Recorded
decisions count as automated coverage only where `phase198_decision_attestation_test.exs`
has a named passing reference and the SUMMARY already records `human_judgment: false`.
Local measurement evidence is not described as environment-stable; only committed CI
attestations support CI-environment claims.

## Audit Execution

| Check | Result |
|---|---|
| New Phase 198 Nyquist contract | 5 tests, 0 failures |
| Targeted Phase 198 contract set | 65 tests, 0 failures |
| Missing run-attestation regression | initially failed for run `33354216172`; fixture recorded; rerun green |
| Workflow job bounds | `ci.yml` 13/13, `release.yml` 7/7, `browser-full.yml` 1/1 |
| Branch-protection verifier | exact context `[CI required]`, emitted once on `origin/main` head |
| Archive durability | two annotated local tags resolve; remote archive refs non-empty |
| GREEN-07 ancestry | `origin/main..HEAD = 237`, `HEAD..origin/main = 0` — unmet |

The ancestry row above records the initial validation audit. A fresh post-Plan-47 audit
is recorded below so the historical count is not silently rewritten.

## Validation Audit 2026-09-08

| Metric | Count |
|---|---:|
| Requirements audited | 12 |
| COVERED | 11 |
| PARTIAL | 1 |
| Genuine validation gaps found | 7 |
| Gaps resolved with tests/fixture | 6 |
| Escalated live-state gap | 1 |

## Validation Audit 2026-09-09 (post-Plan-47)

| Metric | Result |
|---|---|
| Gap audited | GREEN-07 literal `origin/main` ancestry and exact-main CI |
| Focused behavioral command | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/threadline/main_ci_observer_contract_test.exs test/threadline/phase198_zero_human_uat_contract_test.exs` |
| Focused behavioral result | 4 tests, 0 failures |
| Live remote main | `a97f527e375f4c1909236b7dbdd5fa3fd9b7d2f2` |
| Local HEAD | `ab4895261b0f37e4de322b1280926bd0a22c92c5` |
| Fresh ancestry result | `origin/main..HEAD = 275`; `HEAD..origin/main = 0`; `HEAD` is not an ancestor of live `origin/main` |
| Exact-main observer | state `failure`; run `33138291361`; 14 jobs; exactly one byte-exact `CI required`, conclusion `failure` |
| Resolution | ESCALATED — remote-state/manual-only blocker; no local test can satisfy the false ancestry predicate |

The focused tests prove that the observer rejects stale-run substitution and requires a
non-empty job set with exactly one successful aggregate before returning success. They
do not, and cannot, turn branch or local-only evidence into proof that live
`origin/main` contains `HEAD`.

## Validation Sign-Off

- [x] All 42 PLANs and 42 SUMMARYs mapped through their tasks and requirements.
- [x] Every automated test claimed green was executed in this audit.
- [x] New tests are behavioral and contain non-vacuity/positive-control assertions.
- [x] No implementation file was modified.
- [x] Manual decisions and environment-specific evidence retain their proof boundaries.
- [x] `status: validated` set.
- [ ] `nyquist_compliant: true` — blocked exclusively by GREEN-07's false remote ancestry clause.

**Approval:** validated partial — 11/12 requirements covered; GREEN-07 escalated to the
maintainer without weakening its literal success criteria.
