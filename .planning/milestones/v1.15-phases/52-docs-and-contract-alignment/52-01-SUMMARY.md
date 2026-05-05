---
phase: 52-docs-and-contract-alignment
plan: 52-01
subsystem: docs
tags: [docs, sigra, quickstart, incident, readme]
provides:
  - adopter-facing guides and the example README aligned on the canonical direct host-wiring story
  - incident-facing docs that keep the shipped authenticated baseline explicit while leaving tenancy and richer authorization host-owned
affects: [ADOPT-03]
requirements-completed: [ADOPT-03]
tech-stack:
  added: []
  patterns: [docs as contract, canonical callback naming, host-owned authz boundary]
key-files:
  created: []
  modified:
    - guides/getting-started-saas.md
    - guides/integrations/sigra.md
    - guides/domain-reference.md
    - guides/incident-playbook.md
    - guides/adoption-pilot-backlog.md
    - examples/threadline_phoenix/README.md
key-decisions:
  - direct Sigra callback names stay identical across every copy-paste entry point
  - incident drill-down docs describe the shipped authenticated baseline without implying Threadline owns tenancy or richer authorization
duration: 18min
completed: 2026-05-05
---

# Plan 52-01 summary

Aligned the quickstart, Sigra guide, incident/reference docs, adoption backlog, and Phoenix example README around one truthful v1.15 host-integration story: `Threadline.Plug` wired directly with the canonical Sigra callbacks, additive-only request metadata overrides, and an authenticated incident drill-down baseline with host-owned tenancy and authorization boundaries.

## Task commits

1. **Task 1: Align the canonical host-wiring docs with the direct callback contract** - `598798d` (docs)
2. **Task 2: Align the incident/reference docs and adoption evidence with the same host-owned boundary story** - `c7a5252` (docs)

## Files changed

- `guides/getting-started-saas.md` - renamed the wiring step around `Threadline.Plug`, added the additive-only override contract, and normalized the incident baseline wording.
- `guides/integrations/sigra.md` - established the direct callback snippet and the additive-only override semantics as the canonical vocabulary.
- `examples/threadline_phoenix/README.md` - replaced the old delegate-seam story with the shipped direct callback pair and explicit incident auth boundary.
- `guides/domain-reference.md` - kept `COMP-EXAMPLE-INCIDENT-JSON` while updating the incident JSON contract to the authenticated baseline.
- `guides/incident-playbook.md` - reframed the playbook around the shipped public API surface and the minimum host auth shape.
- `guides/adoption-pilot-backlog.md` - upgraded the incident drill-down row to the shipped CI-backed auth baseline while keeping richer authorization host-owned.

## Decisions made

- Reused the router/controller truth already present in the example app instead of inventing new public callback seams or incident terminology.
- Kept the docs sweep narrow and literal-focused so the follow-on contract tests could lock specific user-facing claims instead of snapshotting prose.

## Deviations from plan

None - the plan landed directly on the existing dirty worktree without needing extra runtime or authorization scope.

## Self-check

PASSED — `rg -n "Threadline\\.Integrations\\.Sigra\\.actor_ref_from_conn/1|Threadline\\.Integrations\\.Sigra\\.audit_context_overrides_from_conn/1|actor-authority|authenticated actor|tenancy|authorization" guides/getting-started-saas.md guides/integrations/sigra.md examples/threadline_phoenix/README.md` and `rg -n "COMP-EXAMPLE-INCIDENT-JSON|authenticated actor|tenancy|authorization|Host teams still own tenancy and richer authorization review" guides/domain-reference.md guides/incident-playbook.md guides/adoption-pilot-backlog.md`
