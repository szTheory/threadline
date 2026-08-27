# Phase 181 Deferred Items

## 181-11: root CI residuals outside Plan 181-11 changes

- **Status:** acknowledged
- **Acknowledged at:** v1.40 milestone close, 2026-08-27

- **Command:** `mix ci.all`
- **Observed:** Root `verify.test` reported 1129 tests, 2 failures, 1 excluded; trigger coverage reported 1/1 expected tables covered; `verify.example` reported 96 tests, 7 failures; aggregate stopped with `verify.example failed (2)`.
- **Residuals:** `test/threadline/operator_surface/formless_pages_test.exs:56` fails because `coverage_live.ex` contains schema form markup; `test/threadline/v1_23_charter_doc_contract_test.exs:15` still expects older PROJECT milestone wording; example-app demo-seed/walkthrough tests still fail around old #4521/#4518 anchors, `agent2` window rows, and `org_memberships` actor attribution.
- **Why deferred:** Plan 181-11 changed closeout verification docs, local screenshot packet artifacts, and stale E2E guard assertions. It did not change `coverage_live.ex`, `PROJECT.md`, demo seed data, capture/query semantics, or the failing example-app Elixir tests.
- **Disposition:** Keep full-suite status red in verification artifacts until the owning coverage/formless contract, charter doc-contract, and demo-seed/walkthrough repairs are performed.
