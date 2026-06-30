---
phase: 187-accessibility-motion-docs-and-adversarial-closeout
artifact: adversarial-review
created: 2026-06-30T16:00:22Z
status: passed-with-classified-residuals
requirements:
  - CLOSE-01
evidence:
  - .planning/phases/187-accessibility-motion-docs-and-adversarial-closeout/187-VERIFICATION.md
---

# Phase 187 Adversarial Review

## Verdict

No Phase 187-owned blocker remains. The closeout passes with classified residuals:

- Targeted source/doc proof passed: 131 tests, 0 failures.
- Targeted accessibility/motion browser proof passed: 51 Playwright tests, 0 failures.
- Stress route and ledger guard passed with expected skips: 42 passed, 9 skipped.
- Standalone local screenshot regression command failed before screenshot comparison because login setup timed out on all 10 desktop/mobile cells.
- `mix ci.all` is non-green in inherited example-app demo-seed/walkthrough/evidence checks.

This review does not convert non-green commands into green claims. It accepts Phase 187 closeout because CLOSE-01 requires current verification evidence, guard status, residual ownership, and adversarial review, all of which are now recorded.

## Four-Lens Review

| Lens | Adversarial question | Result | Evidence |
|------|----------------------|--------|----------|
| operator under incident pressure | Can an operator still move through investigation, readiness, export, and retention workflows without misleading states, route churn, or screenshot-only assurance? | Pass with screenshot residual. Targeted keyboard/focus/browser proof passed, but the standalone screenshot command did not prove visual stability in this run. | `187-VERIFICATION.md` commands #2, #3, #4. |
| keyboard/assistive-technology user | Are focus paths, custom widgets, names, non-color state, and reduced-motion behavior proven without overclaiming screen-reader certification? | Pass with bounded AT caveat. Automated source/browser proof passed; real AT UAT was not run. | `187-VERIFICATION.md` A11Y-01, A11Y-02, MOTION-01 rows and Proof Limits. |
| OSS maintainer | Can a maintainer audit the claim from exact commands, commits, and files without guessing or accepting assertion-only closure? | Pass with broad-CI residual. Exact commands, outcomes, commits, and residual ownership are recorded; `mix ci.all` remains non-green and is not hidden. | `187-VERIFICATION.md` Command Ledger and Residual Classification. |
| host-app DX/security | Did closeout preserve host-owned auth/export gates, optional dependency boundaries, CSP posture, route stability, private components, and production exclusions? | Pass. Plan 187-03 created planning artifacts only and did not touch runtime host boundaries. DOC-01 contracts passed. | `187-VERIFICATION.md` Source Boundary Confirmation and command #1. |

## D-187-23 Risk Review

| Risk Category | Finding | Status | Follow-through |
|---------------|---------|--------|----------------|
| route stability | No Phase 187-03 source edits changed routes. Plan 187-01/02 evidence stayed in docs/tests; `187-VERIFICATION.md` confirms no route path changes. | Pass | Keep route/test-id changes out of closeout artifacts. |
| auth/export | DOC-01 contracts and prior Phase 186 verification preserve direct export route authorization and host-owned auth gates. No LiveView-only security claim was added. | Pass | Continue treating controller/auth-plug checks as the export authority. |
| CSP | Runtime theme picker docs and contracts pin native POST/CSRF behavior with no JavaScript and no `localStorage`; no inline handler was introduced. | Pass | Keep CSP docs source-bound. |
| optional dependency | No package was added, removed, or upgraded. PhoenixStorybook remains example-app dev/test tooling, not a root dependency or production route. | Pass | Defer dependency advisory remediation to a dedicated dependency/security plan. |
| docs truth | Plan 187-01 repaired the runtime theme picker and operator-boundary docs; command #1 passed the doc/source contract slice. | Pass | Keep docs tied to source-reading contracts. |
| focus trap | `operator-accessibility.spec.ts` passed row-history drawer, retention modal, stress dialog/drawer, Escape, close, and focus-return paths. | Pass with automation-only caveat | Real AT UAT remains unrun. |
| obscured focus | The accessibility browser lane passed non-obscured focus checks across the targeted workflows. | Pass | Keep geometry-based focus assertions in the browser lane. |
| color-only | The accessibility browser lane passed status/verdict chip text-label and non-color shape proof; component/style source contracts passed. | Pass | Continue requiring text/shape/icon/copy beyond color. |
| reduced-motion | `operator-motion.spec.ts` and `style_contract_test.exs` passed, proving tokenized default motion and reduced-motion collapse in the existing lane. | Pass | Do not add decorative motion or `transition: all`. |
| screenshot | `mix verify.operator_stress` passed ledger/stress status, but the standalone screenshot regression command failed 10/10 before comparison at login setup. No baseline mismatch was accepted. | Residual, non-green | Repair/rerun screenshot command bootstrap before claiming local screenshot stability; do not update baselines or masks from this run. |
| overclaim | `187-VERIFICATION.md` explicitly states automated proof limits and does not claim real screen-reader certification or green broad CI. | Pass | Keep AT certification language out unless real AT UAT is run and recorded. |

## Threat-Oriented Findings

### Finding 1: Screenshot proof could be overstated

- **Evidence:** Standalone `operator-screenshot-regression.spec.ts` desktop/mobile command failed all 10 cells in login setup before screenshot comparison.
- **Risk:** Future readers could mistake stress guard PASS for full screenshot-regression PASS.
- **Classification:** Non-blocking residual for CLOSE-01, because the residual is explicitly recorded and no visual/baseline claim is made.
- **Required follow-through:** Do not update baselines, broaden projects, weaken masks, or skip cells. Repair or bootstrap the standalone command before accepting screenshot stability.

### Finding 2: Broad CI could be overstated

- **Evidence:** `mix ci.all` root checks passed, but example-app verification failed 109 tests / 9 failures in demo-seed, walkthrough, and evidence paths.
- **Risk:** A closeout summary could imply release-wide green status.
- **Classification:** Non-blocking residual for this proof-only plan; broad CI remains non-green.
- **Required follow-through:** Keep broad CI residuals assigned to demo-seed/walkthrough/evidence ownership.

### Finding 3: Accessibility automation could be mistaken for AT certification

- **Evidence:** `operator-accessibility.spec.ts` passed role/name/focus/accessibility-tree checks, but no NVDA, VoiceOver, JAWS, Narrator, TalkBack, or human AT UAT was run.
- **Risk:** Overclaiming accessibility in adopter-facing docs.
- **Classification:** Proof limit, not a blocker.
- **Required follow-through:** Keep "automated proof" wording; do not claim screen-reader certification.

### Finding 4: Dependency advisory output is visible but out of scope

- **Evidence:** Browser/stress/example commands printed existing advisory output for unchanged packages while continuing.
- **Risk:** A proof-only closeout could accidentally bury dependency-security debt.
- **Classification:** Inherited dependency-maintenance/security residual, outside Phase 187 package-change prohibitions.
- **Required follow-through:** Use a dedicated dependency/security plan; do not install or upgrade packages in Phase 187.

## Blockers And Residuals

| Type | Item | Status |
|------|------|--------|
| Blocker | Phase 187-owned runtime/source/docs blocker | None found. |
| Residual | Standalone local screenshot regression command failed before screenshot comparison. | Recorded in `187-VERIFICATION.md`; not accepted as visual proof. |
| Residual | `mix ci.all` example-app demo-seed/walkthrough/evidence failures. | Recorded in `187-VERIFICATION.md`; broad CI not green. |
| Proof limit | Real assistive-technology UAT not run. | Explicitly bounded; no certification claim. |

## Scope Guard

The adversarial review found no evidence that Plan 187-03 changed schema, packages, route paths, stable `data-testid`s, auth/export/capture/query semantics, public component API posture, Tailwind/shadcn posture, production Storybook/stress route posture, screenshot baselines, masks, or Playwright project matrices.

## Follow-Through

- Treat `187-VERIFICATION.md` as the Phase 187 evidence ledger.
- Keep `operator-accessibility.spec.ts` and `operator-motion.spec.ts` as the rendered A11Y/MOTION proof lanes.
- Keep `operator-screenshot-regression.spec.ts` local/platform-sensitive and non-green until the standalone command is repaired/rerun successfully.
- Keep `mix ci.all` status non-green until demo-seed/walkthrough/evidence residuals are fixed in their own scope.
- Do not mark real screen-reader certification complete unless real AT UAT is performed and recorded.

---

Reviewed: 2026-06-30T16:00:22Z
