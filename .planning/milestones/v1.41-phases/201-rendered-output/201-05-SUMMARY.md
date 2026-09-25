---
phase: 201-rendered-output
plan: 05
subsystem: operator-surface
tags: [exunit, rendered-output, evidence, immutability, playwright, release-gate]
requires:
  - phase: 201-rendered-output
    plan: 01
    provides: seven-node structural receipts, sealed pre-edit evidence, and the positive-controlled provenance scanner
  - phase: 201-rendered-output
    plan: 04
    provides: provenance-free Row History and Timeline plus the exact seven-node live zero-provenance guard
provides:
  - durable history-preserved identities for the two residual root contract tests
  - non-vacuous owned-source, representative-render, and CSS provenance guards with positive controls
  - one-to-one immutable reference-corpus verification with an explicit zero-entry exception registry
  - sealed final Phase 201 evidence and a deterministic Phase 202 clean handoff
affects: [201, 202, rendered-output, operator-surface, release-gate]
actuals:
  tasks: 3
  commits: 3
tech-stack:
  added: []
  patterns:
    - path-set equality verified before byte-hash equality
    - explicit zero-entry exception registry as the expected successful result
    - exact non-regression gate pinned to a measured failure set
key-files:
  created:
    - test/threadline/critic_iteration_runbook_doc_contract_test.exs
    - test/threadline/ci_workflow_parity_contract_test.exs
  modified:
    - test/threadline/operator_surface/rendered_output_contract_test.exs
    - .planning/audits/201-rendered-output-evidence.md
    - .planning/phases/201-rendered-output/201-05-PLAN.md
    - .planning/WINDOWS.md
    - mix.exs
key-decisions:
  - "The visual gate is amended from `fully green browser lane` to an exact non-regression contract, because the original clause was unsatisfiable without the baseline regeneration the same plan prohibits."
  - "The eight screenshot failures were proven pre-existing by measurement, not argument: the same eight fail with Phase 201's five LiveView modules reverted to fecfe684."
  - "No baseline, fixture, scorecard, capture, or snapshot was regenerated; the ten baseline PNG hashes are sealed in the evidence file."
  - "The Dialyzer lane failure was diagnosed as a gitignored local PLT cache miss caused by an OTP 27.3.4.15 to 27.3 shift, not a product defect, and fixed by rebuilding the PLT."
patterns-established:
  - "When a gate cannot pass as literally written, pin the measured reality as an exact set (named failures, immutable hashes, required passes) rather than waiving the gate or regenerating evidence to satisfy it."
requirements-completed: [RENDER-01, RENDER-02, RENDER-03, RENDER-04, RENDER-05, RENDER-06]
---

# Plan 201-05 Summary

Sealed the residual cleanup with durable test identities, one-to-one immutable
evidence, and the full deterministic release gate.

## What shipped

**Tasks 1-2 (landed earlier in the plan's execution).** Both residual root
contract tests were renamed with `git mv`, preserving blame:
`forward_only_gate_doc_contract_test.exs` to
`critic_iteration_runbook_doc_contract_test.exs` (module
`Threadline.CriticIterationRunbookDocContractTest`, with the exact `mix.exs`
`verify.doc_contract` consumer updated atomically), and
`phase06_nyquist_ci_contract_test.exs` to `ci_workflow_parity_contract_test.exs`
(module `Threadline.CIWorkflowParityContractTest`, left to ordinary ExUnit
convention discovery). No phase-number chronology remains in either identity.

**Task 3.** Completed the deterministic rendered-output contract: owned-source,
representative-render, and CSS provenance lanes that assert non-empty
inventories before accepting a zero-offender result, each with a seeded positive
control; one-to-one reference-corpus verification that fails on added, removed,
duplicated, or renamed paths *before* comparing byte hashes across the 427
manifest entries; and an exception registry validated on exact stable node IDs
and numeric before/after/delta measurements, never display-text substrings.
The registry holds zero entries, which is the expected successful result.

## Gate results

`mix ci.all` exits 0: root 1660 tests / 0 failures, example 116 / 0, Dialyzer
0 errors. Targeted contracts 9/0, fixture and mechanical checker 33/0,
`verify.mechanical` 28/0. All three accepted landed-blob attribution diffs
(`5752e357`, `1a5fbef2`, `18fe87f5` to HEAD) exit 0 — the copy and CSS blobs
were proven, never replayed.

The browser lane is 82 passed / 8 failed. Every behavior, accessibility,
responsive, and overflow case passes. Full detail, including the ten sealed
baseline hashes, is in `.planning/audits/201-rendered-output-evidence.md`.

## Deviations

**1. Visual gate amended to an exact non-regression contract** (WINDOWS entry
62, maintainer-ratified in-session). The plan's original clause demanded a fully
green browser lane. That is unsatisfiable without regenerating the eight stale
baselines the same plan explicitly prohibits regenerating. The eight failures
were proven pre-existing by direct measurement: Phase 201's five LiveView
modules were reverted to `fecfe684`, the screenshot spec re-run, and the
identical eight cases failed with the same two Home cases passing. Phase 201's
entire production delta is 21 deleted `data-earned-flow` / `data-persona` /
`data-jtbd` attribute lines and nothing else, which cannot alter raster output.
The gate now fails on anything other than exactly that eight-failure set, Home
passing on both projects, unchanged baseline hashes, and all 82 other cases
green. Nothing was regenerated and nothing was waived.

**2. Browser lane invocation corrected.** The plan's verbatim command ran
`playwright test` directly, which starts no application server — every
`page.goto` fails in roughly 50ms on an invalid relative URL, producing 45
spurious failures that look like a catastrophic regression. The lane must be
driven through `mix verify.example_browser` / `run-e2e.sh`, which boots the app
on 127.0.0.1:4002 first. The clause was corrected in place.

**3. Dialyzer PLT rebuilt.** `mix ci.all` initially failed at the Dialyzer lane
with `Could not read PLT file .dialyzer/dialyxir_erlang-27.3_elixir-1.17.3_deps-dev.plt`.
This was a local cache miss, not a product defect: `verify.dialyzer` runs
`dialyzer --no-check`, which will not build a missing PLT, and the on-disk PLTs
were built under OTP 27.3.4.15 while the pinned `ASDF_ERLANG_VERSION=27.3`
resolves to the separately installed OTP 27.3. PLTs are gitignored, so the
rebuild changed nothing tracked. This is the concrete form of the "intervening
Erlang version" symptom seen during the previous session.

## Phase 202 handoff

The six clean preconditions are enumerated at the end of
`.planning/audits/201-rendered-output-evidence.md`. In short: `ci.all` green,
zero planning provenance in rendered output under a fail-closed guard, seven
canonical nodes structurally identical pre/post, the reference corpus
byte-identical across all 427 entries, zero exception entries, and the browser
lane's only failures being the eight measured, registered, pre-existing
screenshot comparisons.
