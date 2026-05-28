---
phase: 127-example-app-schemas-demonstration
plan: "01"
subsystem: operator-surface
tags: [schemas, row-history, doc-contract, phoenix-example]

requires: []
provides:
  - Runnable :schemas mount on example app operator surface
  - Org-scoped :row_history query clause
  - getting-started §9 and README mount parity with router SSOT
affects: [127-02]

tech-stack:
  added: []
  patterns:
    - "Help-desk tables only in schemas map (tickets, ticket_replies)"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
    - guides/getting-started-saas.md
    - examples/threadline_phoenix/README.md

key-decisions:
  - "Limit schemas map to walkthrough help-desk tables only (D-14)"

patterns-established:
  - "Router operator-surface-mount block is SSOT for doc snippet extraction"

requirements-completed: []

duration: 5min
completed: 2026-05-28
---

# Phase 127 Plan 01: Schemas mount wiring

**Example app operator mount now maps help-desk tables for row-history reification; docs match router SSOT.**

## Performance

- **Duration:** 5 min
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Added `schemas:` map (`tickets`, `ticket_replies`) to `threadline_operator_surface/2` mount
- Extended `scope_operator_query/3` org filter to include `:row_history`
- Synced getting-started §9 and example README mount fences to router doc markers

## Self-Check: PASSED

- `rg -q 'schemas: %' examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex`
- `cd examples/threadline_phoenix && mix compile --warnings-as-errors`
- `mix test test/threadline/getting_started_saas_doc_contract_test.exs`
- `mix test test/threadline/example_phoenix_readme_contract_test.exs`
- `mix verify.doc_contract`
