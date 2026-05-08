---
phase: 72
plan: "72-02"
subsystem: packaging
tags:
  - pkg-02
  - docs
  - package-contract
provides:
  - PKG-02 module-group contract alignment inside ExDoc metadata
affects:
  - mix.exs
  - test/threadline/release_artifact_contract_test.exs
  - test/threadline/upgrade_path_doc_contract_test.exs
  - test/threadline/readme_doc_contract_test.exs
metrics:
  completed_at: 2026-05-08T14:25:00Z
---

# Plan 72-02 Summary

## What shipped

- Renamed the ExDoc module group in [mix.exs](/Users/jon/projects/threadline/mix.exs) from `Operator Surface` to `Operator Surface (Optional In-Tree)`.
- Extended the focused contract coverage in [test/threadline/release_artifact_contract_test.exs](/Users/jon/projects/threadline/test/threadline/release_artifact_contract_test.exs), [test/threadline/upgrade_path_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/upgrade_path_doc_contract_test.exs), and [test/threadline/readme_doc_contract_test.exs](/Users/jon/projects/threadline/test/threadline/readme_doc_contract_test.exs).

## Key outcomes

- The package contract now says explicitly, inside ExDoc grouping, that the operator surface remains part of the core package while staying optional.
- The closeout decision is no longer just prose in guides; focused tests now lock the scorecard section, the stay-in-tree wording, and the optional in-tree ExDoc grouping.
- Phase 72 leaves the public operator-surface entrypoint unchanged while tightening the package-boundary messaging around it.

## Verification

- `rg -n "Operator Surface \\(Optional In-Tree\\)" mix.exs test/threadline/release_artifact_contract_test.exs`
- `mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/readme_doc_contract_test.exs --max-failures 1`
