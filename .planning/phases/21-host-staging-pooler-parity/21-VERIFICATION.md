---
phase: 21
status: passed
verified: 2026-04-24
---

# Phase 21 verification

## Must-haves (STG-01 — STG-03)

| Requirement | Evidence |
|-------------|----------|
| **STG-01** Fixed-field topology scaffold in-repo | `guides/adoption-pilot-backlog.md` → `## STG host topology template (STG-01)`, marker `STG-HOST-TOPOLOGY-TEMPLATE`, table with `Chain (app to pooler to postgres)`, `Matches prod`, partial rationale paragraph. |
| **STG-02** HTTP + job path matrix | Same file → `## STG audited write paths (STG-02)`, `STG-AUDITED-PATH-RUBRIC`, columns include `Kind (HTTP \| job)`, `Status (OK \| Issue \| N/A \| Not run)`, `Evidence / pointer`. |
| **STG-03** Honest OK / pointer pairing | Rubric prose + normative bullets forbid vague N/A and require reproducible pointers for OK. |
| Discoverability | `CONTRIBUTING.md` `## Host STG evidence (integrators)`; `guides/production-checklist.md` intro links to backlog and `STG-AUDITED-PATH-RUBRIC`. |
| Doc contracts | `test/threadline/ci_topology_contract_test.exs` (STG markers + CI contract); `test/threadline/stg_doc_contract_test.exs` (CONTRIBUTING, checklist, backlog regression). |

## Automated checks run

- `DB_PORT=5433 MIX_ENV=test mix test test/threadline/ci_topology_contract_test.exs`
- `DB_PORT=5433 MIX_ENV=test mix test test/threadline/stg_doc_contract_test.exs`
- `DB_PORT=5433 MIX_ENV=test mix ci.all` — **passed**

## Plans

- [x] 21-01 — SUMMARY present; backlog + topology test updates.
- [x] 21-02 — SUMMARY present; CONTRIBUTING, production-checklist, `stg_doc_contract_test.exs`, full gate.

## human_verification

None required for this phase (documentation and static contracts only).
