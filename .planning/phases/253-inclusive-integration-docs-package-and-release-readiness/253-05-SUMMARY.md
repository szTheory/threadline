---
phase: 253-inclusive-integration-docs-package-and-release-readiness
plan: "05"
subsystem: docs
tags: [admin, archive, retention, auth, fixture-reuse]
requires:
  - phase: 252
    provides: "Accepted preview/refusal and unchanged worker entrypoint"
provides: ["Current package/module/Admin guide language and operation recovery", "One fresh actual package fixture for unchanged archive assertions"]
affects: ["253-08", "253-09", "253-10"]
tech-stack:
  added: []
  patterns: ["Share an immutable fresh archive within one ExUnit module invocation; no cross-run cache"]
key-files:
  created: []
  modified: [mix.exs, lib/threadline.ex, guides/operator-surface.md, test/threadline/operator_surface_doc_contract_test.exs, test/threadline/release_artifact_contract_test.exs]
requirements-completed: [ADM-29, ADM-30, ADM-33]
requirements-partial: []
actuals:
  tokens: null
  tasks: 1
status: complete
completed: 2026-11-13
coverage:
  - id: current-mount-package-prose
    description: "Current Admin identity, explicit auth, actual native theme controls and Retention preview/outcome/recovery boundaries"
    verification:
      - kind: integration
        ref: "test/threadline/operator_surface_doc_contract_test.exs"
        status: pass
    human_judgment: false
  - id: actual-package-preservation
    description: "Fresh inspected archive preserves exact ten approved assets, exclusions and unchanged ownership/mutation controls"
    verification:
      - kind: integration
        ref: "test/threadline/release_artifact_contract_test.exs"
        status: pass
    human_judgment: false
---

# Plan05 — Current Admin and truthful operation guidance

**Final contribution:** independent goal verification passes5/5 roadmap truths and9/9 requirements with current required CI green. This plan contribution is complete at the named evidence boundaries. Historical pending checkpoints below preserve original failures and provenance; [final verification](253-VERIFICATION.md) and [CI results](253-CI-RESULTS.md) control the current result. REL-01 remains separate and no release/merge authority is inferred.

Package metadata uses the approved audit-trail-library description. The main module explains trigger capture on registered tables with context supplied by the host. The Admin guide preserves its old operator-surface fragment, supported mount/auth/HTTP export contracts and technical names. It now describes the actual immediate native theme buttons and the ready-preview → review → typed-confirmation flow, global configured worker-store scope, sequential/transient estimates, recorded outcome/checkpoint meanings and target-mismatch recovery. Pruner.trigger/0 retains its existing behavior; no target-inspection API was invented.

The ExDoc technical Operator Surface module group remains unchanged because the existing public-surface contract pins it; guide/product prose uses Threadline Admin. Version1.1.0, extras, dependencies, ten-asset allowlist and asset bytes are unchanged. Optional-host and final rendered-doc/package gates remain later work.

## Verification and measured duplicate work

The existing8-case guide owner first failed on the intended stale compatibility/introduction contract. After source updates and formatting, both selected guide/archive owners passed29 tests in19.8 suite seconds (21.634 managed wall seconds). The archive helper was rebuilding the same source for eight syntactic call sites, including independently named dynamic source-owner cases. All consume immutable maps and mutate only copied maps in negative controls.

A normal ExUnit setup_all now builds one fresh archive per module invocation and supplies it explicitly to those same assertions. There is no persistent/cross-run cache, added dependency, concurrency, assertion removal or skipped case. The identical selected invocation passed29 tests in2.9 suite seconds (4.319 managed wall seconds), retaining exact asset bytes, populated-archive premises and mutation controls. Pure metadata-only selections in this module also prepare that archive; the fixture is intentionally fresh each invocation. CI end-to-end savings are unmeasured. Comparison receipt: threadline-253-archive-fixture-comparison.json.

Source commits: f38932d3 (current prose) and 46d3242ab4d97e93364e241b19b314e66f778db0 (fixture reuse). Receipts: threadline-253-docs-mount-red-01, docs-mount-format-01, docs-mount-archive-01/02 and archive-fixture-format-01/02. The actual unpacked archive is inspected by existing owners, not inferred from package configuration alone.

ADM-29/30 and recurring verification efficiency receive partial contributions; complete docs/package/CI acceptance remains pending. No release, version or external authority is inferred. Continue253-06 in the same supported checkout.

## Self-Check: PASSED

Five planned owners committed; current29-test pass and actual before/after timing are retained with their limits. Independent source/copy/security review remains253-10.
