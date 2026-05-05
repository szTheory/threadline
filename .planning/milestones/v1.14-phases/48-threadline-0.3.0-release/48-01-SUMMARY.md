---
phase: 48-threadline-0.3.0-release
plan: 01
subsystem: release
tags:
  - release
  - docs
  - exdoc
  - mix
  - hex
key_files:
  created:
    - .planning/phases/48-threadline-0.3.0-release/48-01-SUMMARY.md
    - test/threadline/release_artifact_contract_test.exs
  modified:
    - mix.exs
    - README.md
    - CHANGELOG.md
    - CONTRIBUTING.md
    - guides/performance.md
    - test/threadline/readme_doc_contract_test.exs
    - test/threadline/ci_topology_contract_test.exs
metrics:
  tasks_completed: 3
  tasks_total: 3
  completed_at: "2026-05-05T00:00:00Z"
---

# Phase 48 Plan 01 Summary

Phase 48 now packages the v1.14 adopter slice as a `0.3.0` release surface: Mix versioning and ExDoc grouping are aligned, the README and changelog tell the adopter-first story, a dedicated release contract guards package/docs drift, and `mix verify.release` exists as a clean-tree-gated maintainer pre-flight.

## Verification

- `mix test test/threadline/readme_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/performance_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs`
- `mix help | grep -F "mix verify.release"`
- `mix verify.release` currently stops at the intended clean-tree gate because the repository already contains unrelated tracked and untracked changes outside Phase 48.

## Deviations from Plan

- The plan’s stated file list did not include `guides/performance.md`, but that guide still contained placeholder throughput values. This execute pass replaced them with the benchmark numbers already produced in Phase 45 so the release narrative and published performance guide refer to the same evidence.
- Formal phase completion updates in shared planning state were not applied during this pass because the workspace is already dirty across multiple earlier-phase and unrelated files, and `verify.release` correctly requires a clean taggable tree before the release can be declared fully green.

## Outcome

- `REL-01` is covered by the `0.3.0` version bump, dated changelog section, README installer update, and adopter-first routing.
- `REL-02` is covered by the ExDoc `Integrations` grouping split, the maintainer publish runbook wording, and `test/threadline/release_artifact_contract_test.exs`.
- `REL-03` is covered by the function-backed `mix verify.release` alias and its contributor-CI exclusion guard in `test/threadline/ci_topology_contract_test.exs`.
- The remaining blocker to a fully green release pass is repository cleanliness, not missing Phase 48 implementation work.
