# Phase 179 Deferred Items

## 179-01 Out-of-Scope Verification Failures

- **Found during:** Final `mix ci.all` verification for 179-01.
- **Scope decision:** Out of scope for 179-01. The failures are in root/project doc-contract and example demo seed/audit-row tests, not in the shell/Home copy files touched by this plan.
- **Observed failures:**
  - `test/threadline/v1_23_charter_doc_contract_test.exs:15` expects older `PROJECT.md` milestone wording (`has now opened milestone...`).
  - `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs:47` cannot find the expected hero close transaction.
  - `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` has four seed/audit-row failures around expected `#4521` close transactions and `org_memberships` actor attribution.
- **Plan-owned verification that passed:** Targeted Phase 179 ExUnit contracts and `operator-home-nav-mobile.spec.ts`.

## 179-03 Out-of-Scope Verification Failures

- **Found during:** Final `mix ci.all` verification for 179-03 after plan-caused stale coverage and transaction-copy assertions were fixed.
- **Scope decision:** Out of scope for 179-03. Remaining failures are in milestone charter documentation, prior evidence-surface example copy, and example demo seed/walkthrough data, not in actor, transaction, row-history, or coverage implementation paths owned by this plan.
- **Observed failures:**
  - `test/threadline/v1_23_charter_doc_contract_test.exs:15` expects older `PROJECT.md` milestone wording (`has now opened milestone...`).
  - `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs:75` expects prior evidence unsupported copy (`Evidence view unavailable.`).
  - `examples/threadline_phoenix/test/mix/tasks/threadline_evidence_show_example_test.exs:20` timed out during demo seed setup.
  - `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_happy_path_test.exs:215` could not find the expected hard-delete timestamp.
  - `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs:47` cannot find the expected hero close transaction.
  - `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` has four seed/audit-row failures around expected close transactions, delete incidents, and `org_memberships` actor attribution.
- **Plan-owned verification that passed:** Plan-local investigation/readiness ExUnit suite, carried copy/live sweep, coverage doc contract, and targeted example transaction-copy assertions.
