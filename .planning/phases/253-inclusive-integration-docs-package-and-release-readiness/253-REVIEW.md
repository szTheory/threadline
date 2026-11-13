---
phase: 253-inclusive-integration-docs-package-and-release-readiness
reviewed: 2026-11-13T20:32:26Z
reviewed_revision: 4f35334f20fc4c8a89ac46d446b9fbb3b6b46672
baseline_revision: 74fe8df2b2520868d464eca93054492fc93a2cad
depth: standard
review_type: automated-review
files_reviewed: 53
files_reviewed_list:
  - CHANGELOG.md
  - DESIGN-SYSTEM.md
  - README.md
  - brandbook/README.md
  - brandbook/brand-book.md
  - brandbook/pressure-test.md
  - examples/threadline_phoenix/README.md
  - examples/threadline_phoenix/e2e/run-e2e.sh
  - examples/threadline_phoenix/e2e/support/operator-evidence-manifest.test.ts
  - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-173-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-prove-mobile.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-shell-home.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-storybook.spec.ts
  - examples/threadline_phoenix/e2e/tests/operator-zoom-proof.spec.ts
  - guides/evaluating-threadline.md
  - guides/how-threadline-works.md
  - guides/integration-contracts.md
  - guides/operator-surface.md
  - guides/upgrade-path.md
  - lib/threadline.ex
  - lib/threadline/operator_surface/live/policy_redaction_live.ex
  - lib/threadline/operator_surface/live/row_history_live.ex
  - lib/threadline/operator_surface/live/timeline_live.ex
  - lib/threadline/operator_surface/live/timeline_live/helpers.ex
  - lib/threadline/operator_surface/style/03_page_home.css
  - lib/threadline/operator_surface/style/04_controls.css
  - lib/threadline/operator_surface/style/09_responsive.css
  - mix.exs
  - priv/fonts/README.md
  - test/partition_weights.txt
  - test/partition_weights_latest.txt
  - test/partition_weights_min.txt
  - test/threadline/brandbook_token_parity_test.exs
  - test/threadline/code_walkthrough_doc_contract_test.exs
  - test/threadline/evaluating_threadline_doc_contract_test.exs
  - test/threadline/example_phoenix_readme_contract_test.exs
  - test/threadline/how_threadline_works_doc_contract_test.exs
  - test/threadline/integration_contracts_doc_contract_test.exs
  - test/threadline/operator_surface/live/evidence_live_test.exs
  - test/threadline/operator_surface/live/retention_history_live_test.exs
  - test/threadline/operator_surface/style_contract_test.exs
  - test/threadline/operator_surface/transaction_live_test.exs
  - test/threadline/operator_surface_doc_contract_test.exs
  - test/threadline/persona_routing_doc_contract_test.exs
  - test/threadline/readme_doc_contract_test.exs
  - test/threadline/release_artifact_contract_test.exs
  - test/threadline/upgrade_path_doc_contract_test.exs
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
  necessity: 0
status: findings
---

# Phase 253: Independent Code Review

**Verdict:** Findings. The new embedded-layout remedy leaves an intermediate-width overflow defect, and the authorization migration text needs two corrections. Source readiness is not accepted by this report.

**Review:** automated-review; source, documentation and test reliability. No human judgment or adopter-comprehension claim.

## Summary

At initial intake, all 53 manifest file SHA-256 values matched the actual checkout bytes. The review inspected the complete scoped diff, the affected surrounding implementation and test predicates, and relevant actual owners across runner startup, worker targeting, layout, authorization, fonts, package archives and documentation. No scoped path is Git-ignored; no project `.codexignore` or project-local skill directory exists. Root/example AGENTS guidance, the research/verification convention, necessity rubric, phase context, plan objectives/actions and relevant summaries were consulted.

The final report-existence/scope/hash check detected a concurrent change to `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts`; the other 52 scoped hashes still matched. This original review binds the frozen revision and original test bytes, not that unreviewed delta. No reviewer source edits occurred. Preserve this initial verdict and request a bounded changed-source review after the source owner finishes its correction.

The remaining real 200% tab-zoom result, exact-candidate required CI and REL-01 are pending evidence gates, separately from the source defects below. They have not been converted into source vulnerabilities or marked passed from default-zoom screenshots, declarations, local test counts or package receipts.

## Narrative Findings (AI reviewer)

### Critical Issues

### CR-01: BLOCKER — Timeline still overflows intermediate host-container widths

**Severity:** BLOCKER

**File:** `lib/threadline/operator_surface/style/09_responsive.css:562-568`

**Related owners:** `lib/threadline/operator_surface/style/09_responsive.css:190-194,231-235,267-274,313-324`; `lib/threadline/operator_surface/style/04_controls.css:148-155`; `examples/threadline_phoenix/e2e/tests/operator-responsive-mobile-first.spec.ts:685-686`.

**Trigger:** Mount Timeline in a 900px host slot while the browser viewport remains at least 1280px, using the same ordinary host wrapper as the new containment test.

**Issue and consequence:** The new container override activates only at 480px or below. Above that, the viewport-based desktop rule still gives the primary filter grid four explicit minimum tracks of 178 + 178 + 180 + 240px, plus three 12px gaps: at least 812px. At a 900px host width, the existing shell can allocate its 232px rail and 16px gutter, leaving 652px for the page. After 32px page padding and 26px toolbar padding/borders, the named container is approximately 594px wide. It is too wide to match the new override and far too narrow for the 812px grid. The controls therefore escape the intended host surface and produce horizontal overflow. The new test covers only the 640px host and the 320px viewport, so its passing endpoints do not detect this interval. This is a static layout lower-bound finding; no new browser observation is claimed.

**Fix:** Base the four-column enhancement on the named container actually having enough width, or extend the narrow-container fallback through the full minimum-track requirement (at least 812px, with an appropriate rounding allowance). Preserve overflow visibility and existing control predicates. Add an intermediate host width such as 900px at viewport 1280px to the existing containment case and run that affected check. Also retain the 640px and 320px cases so a wider fix does not regress the proven endpoints.

### Warnings

### WR-01: WARNING — The documented public acknowledgement is invalid Elixir syntax

**Severity:** WARNING

**File:** `guides/upgrade-path.md:162`

**Related owner:** `test/threadline/upgrade_path_doc_contract_test.exs:240`.

**Trigger:** An adopter copies the documented acknowledgement into the mount's options while following the new upgrade instructions.

**Issue and consequence:** The guide renders `:adopter_acknowledges_unauthenticated: true`, combining the atom prefix with keyword-entry syntax. That is not the supported Elixir keyword entry and cannot be pasted into the router options. The new document contract explicitly requires this malformed spelling, so a prose check preserves the defect instead of rejecting it. The changelog already uses the correct spelling.

**Fix:** Use `adopter_acknowledges_unauthenticated: true` in the guide and its contract. If naming only the atom, use `:adopter_acknowledges_unauthenticated` separately from the literal value. Keep the intentionally-public-only warning and exact literal-`true` requirement.

### WR-02: WARNING — Migration prose overstates compile-time authorization validation

**Severity:** WARNING

**File:** `guides/upgrade-path.md:160-161`

**Related owners:** `CHANGELOG.md:31-32`; `lib/threadline/operator_surface/router.ex:149-174,265-280`; `test/threadline/operator_surface/router_test.exs:358-394`; `lib/threadline/operator_surface/auth.ex:90-153`.

**Trigger:** A host supplies an opaque option such as a module attribute whose value is nil or a function of the wrong arity, then relies on the new statement that unusable authorization is rejected during compilation.

**Issue and consequence:** The router deliberately checks recognizable literal function forms without evaluating opaque expressions. Its catch-all accepts ASTs that are not known literal non-functions, and the source comment explicitly assigns dynamic expressions to runtime fail-closed handling. The existing test also preserves opaque-expression compilation without callback invocation. Therefore a successful compile does not establish that every supplied authorization value is usable; an unusable opaque value reaches the runtime callback guard and the Admin mount is denied. The new guide and changelog describe all unusable/invalid authorization as compile-time rejection, giving adopters the wrong verification and troubleshooting boundary.

**Fix:** Narrow both statements to the actual contract: missing authorization and statically recognizable invalid literal forms are rejected at compile time; opaque expressions are checked fail-closed at runtime. Keep the requirement to supply a usable unary callback and keep pipeline-only mounts rejected. Adjust the prose contract to preserve that distinction; no router expansion or callback evaluation is needed.

## Inspected Boundaries and Limits

- **Runner/worker:** The generated final launch remains after migrate/reset, uses no-start application boot with endpoint serving enabled, delays fixture Export cleanup through existing private options, starts the actual Pruner under the library supervisor, and validates its PID/Repo/schema/sleep and row-invariance marker before Playwright. The actual Pruner init/scheduling/target owner and Export cleanup init were traced. Fixture housekeeping overrides are not default-cleanup proof.
- **Browser/test intent:** Changes migrate obsolete modal entries to preview/review while retaining the final submit, blank-token, focus/trap/return, cancellation and reduced-motion predicates. Mobile now has real touch input. Local clipboard-double installation is explicitly conditional; the code does not label it native clipboard evidence. Zoom assertions still require the actual extension-reported factor 2; their missing execution result remains unproven.
- **True negative controls:** Missing/mismatched readiness markers prevent the fake runner's browser invocation. Preview-stop tests now exercise the CLI delegation/actual exit seam; the separate existing receipt owner still checks process/source/port/database mismatches without signalling. The seam is not represented as real-process ownership proof. Brand palette/control mutation tests and populated archive/map mutation premises remain present.
- **Layout/fonts:** The changed font rule selects the existing private heading token. The rendered-font case compares the embedded font bytes with the approved asset and checks the loaded face, computed family/size/weight; existing opt-out/fallback/CSP ownership remains. Container sizing does not contain the sibling fixed filter drawer. CR-01 identifies the uncovered sizing interval.
- **Optional/package boundaries:** Version, dependency declarations, ten-asset package allowlist and public technical names remain unchanged. Storybook remains at the example/dev/test boundary. Archive `setup_all` builds one fresh immutable map per module invocation, retains populated-map assertions, performs mutations on copied maps and retains its module-lifetime `on_exit` cleanup; it introduces no cross-run archive cache.
- **Mechanical Elixir edits:** Case/with rewrites, saved-view helper extraction, schema predicate flattening and aliases preserve the existing branches and permissions in the scoped diff.
- **Partition weights:** The sole added font owner is explicitly an uncalibrated local admission estimate in each weight file. Existing weights are unchanged; this review makes no CI-lane calibration or performance claim.

## Evidence and Pending Gates

This independent review launched no tests, browser, application or external action and changed no source. Supplied release/example/evaluator wrapper receipts have successful exits; the archive inspection binds the frozen revision and records 178 entries with the preserved archive digest. Their recorded outcomes remain bounded prior evidence, not fresh reviewer reruns or proof of every unchanged boundary.

The newly available [package readiness record](253-PACKAGE-READINESS.md) and [draft CI proposal](253-CI-PROPOSAL.md) were read. They correctly keep local package results, real 200% zoom, hosted exact-candidate CI and the original live REL-01 clause distinct. They are review-time planning records outside the frozen 53-file source manifest; later record updates require their normal owner reconciliation.

The parent owns dispositions, source fixes, affected proof and any same-reviewer delta. For CR-01, actual intermediate-width browser proof is the useful next check after the fix. For WR-01/02, correct the existing docs/contracts and run their affected owner checks. Required real zoom and exact-candidate CI remain pending independently; no push, release, foreground, clipboard or residual-risk authority is inferred.

_No structural pre-pass or external-reviewer evidence was supplied. Necessity was assessed under the loaded rubric; no provable necessity finding was identified._

