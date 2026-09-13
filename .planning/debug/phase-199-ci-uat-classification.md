---
status: diagnosed
trigger: "Diagnose UAT gap G-199-1: recurring-value proof must be shifted left into CI integration/E2E/smoke automation so no human UAT checkpoint is required. Determine why verify-work classified 199-13 D2 as a human checkpoint despite later automation summaries, and whether CI coverage exists with stale metadata or an actual automation gap remains."
created: 2026-09-13T14:19:35Z
updated: 2026-09-13T14:24:54Z
---

## Current Focus

hypothesis: CONFIRMED — the false human checkpoint is produced by the conjunction of a historically correct but now superseded failed D2 record in halted Plan 199-13 and a per-summary classifier that has no phase-wide halted/supersession reconciliation.
test: Completed classifier differential, field-level counterfactual, focused CI/ratchet contracts, and live analyzer.
expecting: Confirmed exactly: failed verification statuses control present[]; changing overall halted status does not; current enforcement passes.
next_action: Return diagnose-only root-cause report; do not modify implementation or historical coverage metadata.

reasoning_checkpoint:
  hypothesis: "199-13 D2 causes UAT Test 1 because its two verification statuses remain fail and verify-work classifies every SUMMARY independently without considering halted status or later requirement-equivalent automated passes."
  confirming_evidence:
    - "Direct classifier output returns only 199-13 D2 in present[] with verification_not_passing; Plans 14, 20, and 21 are all_auto_covered."
    - "Changing only D2 verification statuses to pass removes present[], while changing only status: halted to status: complete leaves D2 in present[]."
    - "Current focused contracts pass 26/26 and live Dialyzer reports zero errors, skipped warnings, and unnecessary skips."
  falsification_test: "A current failing focused contract/analyzer, or classifier behavior that reconciled Plan 13 against later summaries, would disprove this explanation; neither was observed."
  fix_rationale: "A future explicit supersession/replacement join at phase aggregation would preserve Plan 13's historical truth while preventing superseded failed records from becoming human UAT."
  blind_spots: "Remote GitHub runs were not re-queried; current CI topology and prior authenticated run evidence were verified from committed contracts/artifacts, and the local analyzer was rerun."
  candidate_causes:
    - "artifact/config: 199-13-SUMMARY.md retains the historical D2 fail statuses from its designed halt"
    - "code: coverage.cjs and verify-work classify per summary/entry and lack halted or superseded coverage reconciliation"
    - "environment: actual current analyzer/CI behavior could still be red"
  and_gate: "yes — the stale historical failure alone is harmless if supersession is recognized, and the per-entry classifier alone is harmless when all entries pass; both are required to produce this false checkpoint."

bug_class: bohrbug
candidate_causes:
  - "config/artifact: 199-13-SUMMARY.md retains D2 status: fail after replacement plans completed the outcome"
  - "code: verify-work may lack a supersession/deduplication rule for later coverage records satisfying the same requirement/outcome"
and_gate: "Potentially yes: stale failed metadata must coexist with plan-local classification that does not join later passing evidence."

## Symptoms

expected: Dialyzer completes successfully with a strict, tighten-only ignore ceiling; there are no live warnings, no broad or stale suppressions, and the committed ceiling cannot increase. Recurring-value proof runs in CI integration/E2E/smoke automation with no human UAT checkpoint.
actual: verify-work classified Phase 199 plan 13 D2 as requiring a human checkpoint even though later Phase 199 summaries appear to automate strict Dialyzer completion.
errors: No runtime error reported; UAT gap G-199-1 records missing or unrecognized CI automation evidence.
reproduction: Run Test 1 in .planning/phases/199-decouple/199-UAT.md and compare its classification against Phase 199 summaries and live CI configuration.
started: Discovered during Phase 199 UAT.

## Eliminated

- hypothesis: An actual current CI integration/E2E/smoke gap leaves strict Dialyzer or the ignore ceiling unenforced.
  evidence: The dedicated verify-dialyzer job is unconditional and required by ci-required; verify-test also blocks ci-required and runs the zero-ceiling ratchet contract. Focused tests pass 26/26 and live Dialyzer reports zero errors/skips/unnecessary skips.
  timestamp: 2026-09-13T14:24:54Z

- hypothesis: Plan 199-13's overall status: halted directly routes D2 to human UAT.
  evidence: An in-memory counterfactual changing only status: halted to status: complete produced identical classifier output; coverage.cjs does not parse or consult plan status.
  timestamp: 2026-09-13T14:24:54Z

## Evidence

- timestamp: 2026-09-13T14:21:11Z
  checked: Semantic debug recall and local knowledge base.
  found: MemPalace is unavailable and .planning/debug/knowledge-base.md does not exist.
  implication: No known-pattern candidate is available; proceed from direct repository evidence.

- timestamp: 2026-09-13T14:21:11Z
  checked: Required Phase 199 summaries and 199-UAT.md.
  found: 199-UAT Test 1 is the only item without source:auto/coverage_id; it matches 199-13 D2, whose two verification refs remain status:fail, while 199-20 D2/D3, 199-14 D1-D3, and 199-21 D1/D4 are all non-human automated passes covering zero ignores, strict analyzer success, blocking CI, and planning-free aggregate execution.
  implication: The reported human checkpoint is inconsistent with current implementation evidence and is likely generated from stale/superseded Plan 13 metadata rather than a missing Dialyzer CI path.

- timestamp: 2026-09-13T14:21:43Z
  checked: gsd-core verify-work workflow and bin/lib/coverage.cjs classifier.
  found: verify-work invokes uat.classify-coverage once per SUMMARY and concatenates every present[] result into human checkpoints. coverage.cjs classifies an entry solely from that entry's human_judgment and verification statuses; it has no phase-wide requirement join, description deduplication, plan status check, replacement-plan link, or supersession field.
  implication: A stale failed D2 in the halted Plan 13 summary deterministically remains a human checkpoint even when later summaries independently auto-pass the same requirement and outcome.

- timestamp: 2026-09-13T14:22:22Z
  checked: Current mix.exs, .github/workflows/ci.yml, Dialyzer contract tests, planning-independent verifier, tracked ignore file, and worktree status.
  found: mix ci.all invokes MIX_ENV=dev mix verify.dialyzer exactly once; CI has an unconditional verify-dialyzer job and ci-required needs it; verify-test runs the full ExUnit suite containing the zero-ceiling ignore contract and also blocks ci-required. The tracked .dialyzer_ignore.exs is exactly []. Existing unrelated untracked files were left untouched.
  implication: The strict analyzer and tighten-only zero-ignore ceiling both have recurring blocking CI enforcement; the remaining discrepancy is metadata/classification, not absent CI automation.

- timestamp: 2026-09-13T14:22:22Z
  checked: Spectrum-based fault localization eligibility.
  found: No failing application test with per-test coverage exists for this artifact-classification defect; the directly reproducible classifier output is the appropriate localization signal.
  implication: SBFL skipped; deterministic differential classification across summaries is more probative.

- timestamp: 2026-09-13T14:22:46Z
  checked: Deterministic uat.classify-coverage output for summaries 199-13, 199-14, 199-20, and 199-21.
  found: 199-13 D2 alone is returned in present[] with reason verification_not_passing. Plans 14, 20, and 21 return all_auto_covered:true with every Dialyzer/CI/ratchet item in auto_passed[].
  implication: The exact UAT Test 1 selection is reproduced from stale Plan 13 coverage metadata, while all replacement-plan metadata already says the implemented result is automated.

- timestamp: 2026-09-13T14:24:26Z
  checked: Focused CI topology and ignore-ratchet tests plus current strict analyzer.
  found: The two focused ExUnit files pass 26 tests with 0 failures. MIX_ENV=dev mix dialyzer --no-check passes with Total errors: 0, Skipped: 0, Unnecessary Skips: 0.
  implication: Current repository behavior satisfies the reported truth and is mechanically enforced; an actual analyzer/ratchet implementation gap is falsified.

- timestamp: 2026-09-13T14:24:54Z
  checked: In-memory field-level counterfactual classifications of 199-13-SUMMARY.md.
  found: Original yields auto_passed:[D1], present:[D2]. Changing only both verification status:fail values to pass yields auto_passed:[D1,D2], present:[]. Changing only overall status:halted to complete leaves the original D2 present result unchanged.
  implication: The two D2 status fields are the immediate routing input, and absence of halted/supersession reconciliation is the classifier-side contributing cause.

- timestamp: 2026-09-13T14:23:22Z
  checked: Focused current CI topology and Dialyzer ignore contract suite.
  found: 26 tests passed with zero failures, including mutation controls for CI topology, zero ceiling, broad/stale/unknown/uncommented/over-ceiling filters, and strict full optional-app configuration.
  implication: The current recurring contracts are green and enforce both halves of the UAT truth; an actual CI-integration gap is not supported.

## Resolution

root_cause: "199-13-SUMMARY.md preserves a historically correct D2 failure from its designed halt; verify-work feeds every SUMMARY independently to coverage.cjs, whose auto-pass decision looks only at the current entry's verification statuses and has no phase-wide halted/superseded/replacement join. The stale fail record therefore becomes UAT Test 1 even though Plans 199-20, 199-14, and 199-21 and the current blocking CI topology now automate and pass the same strict-Dialyzer/zero-ceiling outcome. This is a coverage-metadata aggregation defect, not a remaining CI integration/E2E gap."
fix: Not applied; diagnose-only mode.
verification: "Classifier reproduction: 199-13 D2 present[verification_not_passing], later summaries all_auto_covered. Counterfactual: changing only D2 statuses removes the checkpoint; changing halted status does not. Runtime: focused contracts 26 tests/0 failures; MIX_ENV=dev mix dialyzer --no-check reports Total errors: 0, Skipped: 0, Unnecessary Skips: 0."
files_changed: []
