---
phase: 56
plan: "56-01"
title: Canonical investigation docs alignment
date: 2026-05-05
files_changed:
  - README.md
  - guides/domain-reference.md
  - guides/getting-started-saas.md
  - guides/incident-playbook.md
  - guides/production-checklist.md
  - examples/threadline_phoenix/README.md
commits:
  - 9440fe2 docs(56-01): align investigation routing map
  - 5fa53ad docs(56-01): converge bundled incident guides
verification:
  - command: rg -n "incident_bundle/2|timeline_page/2|which public API first\\?|authenticated actor|host-owned|tenancy|policy" README.md guides/domain-reference.md guides/getting-started-saas.md guides/incident-playbook.md guides/production-checklist.md examples/threadline_phoenix/README.md
    result: passed - all touched docs expose the canonical routing hierarchy, bundled incident path, and host-owned boundary language
  - command: mix test test/threadline/readme_doc_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1
    result: passed - 29 tests, 0 failures
  - command: mix test test/threadline/investigation_test.exs --max-failures 1
    result: passed - 11 tests, 0 failures
  - command: mix verify.test
    result: passed - 269 tests, 0 failures (1 excluded)
---

# Phase 56 Plan 56-01 Summary

Aligned the public investigation docs on one canonical story: eager `Threadline.timeline/2` for smaller slices, `Threadline.timeline_page/2` for stable large windows, packaged helpers for common support questions, and `Threadline.incident_bundle/2` as the default single-transaction drill-down path.

## What Changed

- Added a compact investigation routing map to `README.md` without turning the root README into a second domain guide.
- Reworked `guides/domain-reference.md` so the "which public API first?" table and `COMP-EXAMPLE-INCIDENT-JSON` section now teach `Threadline.incident_bundle/2` as the default transaction incident path.
- Updated the SaaS quickstart, incident playbook, production checklist, and Phoenix example README so they all point to the same bundled incident story while preserving the authenticated baseline and host-owned tenancy/policy boundary.
- Kept `Threadline.audit_changes_for_transaction/2`, `Threadline.transaction_context/2`, and `Threadline.change_diff/2` visible as advanced composition building blocks instead of removing or obscuring them.

## Verification

- `rg -n "incident_bundle/2|timeline_page/2|which public API first\\?|authenticated actor|host-owned|tenancy|policy" README.md guides/domain-reference.md guides/getting-started-saas.md guides/incident-playbook.md guides/production-checklist.md examples/threadline_phoenix/README.md`
  - Passed: expected routing, auth-boundary, and bundle wording found across all touched docs
- `mix test test/threadline/readme_doc_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/incident_playbook_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1`
  - Passed: `29 tests, 0 failures`
- `mix test test/threadline/investigation_test.exs --max-failures 1`
  - Passed: `11 tests, 0 failures`
- `mix verify.test`
  - Passed: `269 tests, 0 failures (1 excluded)`

## Deviations

None. The plan executed as written.
