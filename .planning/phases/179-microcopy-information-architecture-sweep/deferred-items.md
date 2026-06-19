# Phase 179 Deferred Items

## 179-01 Out-of-Scope Verification Failures

- **Found during:** Final `mix ci.all` verification for 179-01.
- **Scope decision:** Out of scope for 179-01. The failures are in root/project doc-contract and example demo seed/audit-row tests, not in the shell/Home copy files touched by this plan.
- **Observed failures:**
  - `test/threadline/v1_23_charter_doc_contract_test.exs:15` expects older `PROJECT.md` milestone wording (`has now opened milestone...`).
  - `examples/threadline_phoenix/test/threadline_phoenix_web/walkthrough_evidence_test.exs:47` cannot find the expected hero close transaction.
  - `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` has four seed/audit-row failures around expected `#4521` close transactions and `org_memberships` actor attribution.
- **Plan-owned verification that passed:** Targeted Phase 179 ExUnit contracts and `operator-home-nav-mobile.spec.ts`.
