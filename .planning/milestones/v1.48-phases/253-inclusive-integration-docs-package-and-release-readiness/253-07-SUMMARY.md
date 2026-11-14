---
phase: 253-inclusive-integration-docs-package-and-release-readiness
plan: "07"
subsystem: docs
tags: [architecture, integration, evaluation, evidence-limits]
requires:
  - phase: 252
    provides: "Accepted current operation and host boundaries"
provides: ["Current three-layer/Admin integration narrative", "Local versus CI/publication/adopter evidence limits with preserved release history"]
affects: ["253-08", "253-09", "253-10"]
tech-stack:
  added: []
  patterns: ["Apply the accepted architecture rather than reopen design", "Keep historical release context distinct from current capability claims"]
key-files:
  created: []
  modified: [guides/how-threadline-works.md, guides/integration-contracts.md, guides/evaluating-threadline.md, test/threadline/how_threadline_works_doc_contract_test.exs, test/threadline/integration_contracts_doc_contract_test.exs, test/threadline/code_walkthrough_doc_contract_test.exs, test/threadline/evaluating_threadline_doc_contract_test.exs]
requirements-completed: [ADM-29]
requirements-partial: []
actuals:
  tokens: null
  tasks: 2
status: complete
completed: 2026-11-13
coverage:
  - id: architecture-and-host-seams
    description: "Accepted capture/semantics/operations ownership, current Admin discovery and existing host callback/API boundaries"
    verification:
      - kind: unit
        ref: "how_threadline_works_doc_contract_test.exs, integration_contracts_doc_contract_test.exs, code_walkthrough_doc_contract_test.exs"
        status: pass
    human_judgment: false
  - id: truthful-evaluation
    description: "Current checkout version, historical releases, local package/CI/publication and adopter evidence remain distinct"
    verification:
      - kind: unit
        ref: "evaluating_threadline_doc_contract_test.exs and version_truth_doc_contract_test.exs"
        status: pass
    human_judgment: false
---

# Plan07 — Current architecture and truthful evaluation

**Final contribution:** independent goal verification passes5/5 roadmap truths and9/9 requirements with current required CI green. This plan contribution is complete at the named evidence boundaries. Historical pending checkpoints below preserve original failures and provenance; [final verification](253-VERIFICATION.md) and [CI results](253-CI-RESULTS.md) control the current result. REL-01 remains separate and no release/merge authority is inferred.

The architecture guide now states the already accepted three separate layers, keeps actions distinct from changes/transactions and identifies optional Threadline Admin. Its four accessible Mermaid diagrams and source/API ownership contracts remain. Current evidence-plane/posture wording becomes plain operational language; technical module/config/route names and chapter anchors remain. Integration prose preserves usable authorization, scope, pipeline-only caveats and HTTP export fallback. The code-walkthrough guide itself required no adjustment; its existing README-section delimiter contract now uses the current heading instead of reading an accidentally oversized slice.

The evaluator distinguishes the checkout version from published Hex state, labels0.6.0/0.5.0 prose as historical release context without erasing it, and names Threadline Admin. Local archive/evaluator checks contribute to readiness; required CI for the actual candidate and publication remain separate. Selected synthetic cases, catalog images and test counts do not establish deployment authority or adopter understanding. The version marker and release automation remain intact; no version change occurred.

Task1 commit:677d942a; three owners passed20 cases after the intended5 stale-copy failures. Task2 commit:85a0c21d5ac9f5dabb12e3a908f8130e940ef93b; evaluator plus the existing version-truth owner passed11 cases after the intended1-of7 identity failure. Formatting and source-bound Markdown/test digests are retained. Receipts: docs-integration-red-01/format-01/01 and docs-evaluator-red-01/format-01/01. No rendered-doc, hosted-CI, publication or real-adopter claim follows from these source contracts.

Seven planned owners changed in two bounded tasks. ADM-29 receives a partial contribution. Continue253-08 in the same context; independent copy/source review remains253-10.

## Self-Check: PASSED

Both task source commits and current20/11-test proof are retained; public contracts and release history remain explicit.
