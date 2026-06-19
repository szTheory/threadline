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

## 179-04 Out-of-Scope Verification Failures

- **Found during:** Final `mix ci.all` verification for 179-04 after Timeline copy and browser assertions passed.
- **Scope decision:** Out of scope for 179-04. Remaining failures are in milestone charter documentation, prior evidence-surface example copy, and example demo seed/walkthrough data, not in Timeline copy, filter handling, URL-backed disclosure, or Timeline e2e assertions owned by this plan.
- **Observed failures:**
  - `test/threadline/v1_23_charter_doc_contract_test.exs:15` expects older `PROJECT.md` milestone wording (`has now opened milestone...`).
  - `examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs:75` expects prior evidence unsupported copy (`Evidence view unavailable.`).
  - `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs:47` cannot find the expected hero close transaction.
  - `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_happy_path_test.exs:215` cannot find the expected hard-delete timestamp.
  - `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` has five seed/audit-row failures around expected close transactions, delete incidents, leaving-agent window counts, and `org_memberships` actor attribution.
- **Plan-owned verification that passed:** Timeline/pager ExUnit suite, full operator accessibility Playwright suite, and carried copy/live sweep.

## 179-05 Out-of-Scope Verification Failures

- **Found during:** Final `mix ci.all` verification for 179-05 after governance copy, plan-owned browser assertions, root copy/live contracts, and copy-caused example assertions passed.
- **Scope decision:** Out of scope for 179-05. Remaining failures are in milestone charter documentation and example demo seed/audit-row data, not in Evidence, Export, Redaction, or Retention governance copy, handoff URLs, permission distinctions, or destructive-retention copy owned by this plan.
- **Observed failures:**
  - `test/threadline/v1_23_charter_doc_contract_test.exs:15` expects older `PROJECT.md` milestone wording (`has now opened milestone...`).
  - `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs:47` cannot find the expected hero close transaction.
  - `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_happy_path_test.exs:215` cannot find the expected hard-delete timestamp.
  - `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` has five seed/audit-row failures around expected close transactions, delete incidents, leaving-agent window counts, and `org_memberships` actor attribution.
- **Plan-owned verification that passed:** Governance LiveView ExUnit suite, `operator-prove-mobile.spec.ts`, `operator-earned-flows.spec.ts`, root copy/live/doc-contract sweep, and copy-caused example assertion updates.

## 179-06 Out-of-Scope Verification Failures

- **Found during:** Final `mix ci.all` verification for 179-06 after stress fixture, ledger, browser stress route, and ledger screenshot assertions passed.
- **Scope decision:** Out of scope for 179-06. Remaining failures are in milestone charter documentation and example demo seed/audit-row data, not in stress fixture copy, stress route rendering, story/ledger parity, or browser stress assertions owned by this plan.
- **Observed failures:**
  - Root suite: `test/threadline/v1_23_charter_doc_contract_test.exs:15` expects older `PROJECT.md` milestone wording (`has now opened milestone...`). Root run reported `1114 tests, 1 failure (1 excluded)`.
  - Example suite: `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs:47` cannot find the expected hero close transaction.
  - Example suite: `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_happy_path_test.exs:215` cannot find the expected hard-delete timestamp.
  - Example suite: `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` has five seed/audit-row failures around expected close transactions, delete incidents, leaving-agent window counts, and `org_memberships` actor attribution. Example run reported `95 tests, 7 failures`.
- **Plan-owned verification that passed:** Copy/stress/ledger ExUnit slice and `operator-stress.spec.ts` across Chromium, desktop Chromium, and mobile Chromium, including the Phase 179 copy-state evidence assertions and the existing ledger screenshot baselines.
