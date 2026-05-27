---
phase: 105-help-desk-domain-expansion-in-reference-app
plan: 01
subsystem: database
tags: [ecto, phoenix, help-desk, binary_id, migrations]

requires: []
provides:
  - Five help-desk tables with binary_id PKs and FK graph
  - Ecto schemas under ThreadlinePhoenix.HelpDesk
affects: [105-02, 105-03]

tech-stack:
  added: []
  patterns:
    - "binary_id primary keys for org-scoped help-desk domain"
    - "programmatic FK assignment — no mass-assignment of organization_id from params"

key-files:
  created:
    - examples/threadline_phoenix/priv/repo/migrations/20260527154352_create_help_desk_tables.exs
    - examples/threadline_phoenix/lib/threadline_phoenix/help_desk/organization.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/help_desk/org_membership.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/help_desk/agent.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/help_desk/ticket.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/help_desk/ticket_reply.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex
  modified: []

key-decisions:
  - "ticket assignee FK uses on_delete nilify_all"
  - "HelpDesk context module is schema stub until Plan 02"

patterns-established:
  - "HelpDesk namespace mirrors Blog/Post layout with binary_id throughout"

requirements-completed: [DEMO-01]

duration: 8min
completed: 2026-05-27
---

# Phase 105 Plan 01: Help-Desk Schemas Summary

**Shipped five-table help-desk domain with binary_id keys, per-org ticket numbers, and internal_note_body column — migratable and compiling in the example app.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-27T15:43:52Z
- **Completed:** 2026-05-27T15:52:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Single migration creates organizations, org_memberships, agents, tickets, ticket_replies
- Unique indexes on org slug, org+user membership, org+user agent, org+ticket number
- Five Ecto schemas with associations and security-conscious changesets

## Task Commits

1. **Task 1: Migration — five help-desk tables** - `33a54f6` (feat)
2. **Task 2: Ecto schemas — HelpDesk namespace** - `c9a690d` (feat)

## Files Created/Modified

- `examples/threadline_phoenix/priv/repo/migrations/20260527154352_create_help_desk_tables.exs` - DDL for all five tables
- `examples/threadline_phoenix/lib/threadline_phoenix/help_desk/*.ex` - Schema modules
- `examples/threadline_phoenix/lib/threadline_phoenix/help_desk.ex` - Namespace stub for Plan 02

## Self-Check: PASSED

- `mix ecto.migrate` and table column probes succeed in example app
- `mix compile --warnings-as-errors` exits 0
- `git log --oneline --grep=105-01` shows 2 task commits

## Deviations from Plan

None — plan executed as written.

## Issues Encountered

None

## Next Phase Readiness

Plan 02 can wire capture, `:ticket_replied_and_closed`, trigger_capture redaction, and generated triggers on these tables.
