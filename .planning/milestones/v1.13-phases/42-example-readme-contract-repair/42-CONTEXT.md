# Phase 42: Example README Contract Repair - Context

**Gathered:** 2026-04-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Repair the Phoenix example docs surface so `examples/threadline_phoenix/README.md` and the `examples/` index match the runnable reference app, historical reconstruction walkthrough, and runbook literals. The root README contract was handled in Phase 41 and stays out of scope here.

</domain>

<decisions>
## Implementation Decisions

### Example README contract
- **D-01:** Keep `examples/threadline_phoenix/README.md` as the canonical runnable walkthrough for the Phoenix reference app.
- **D-02:** Preserve the install, run, test, and migration literals that let a reader follow the example without guessing command names.
- **D-03:** Keep the historical reconstruction walkthrough explicit, including `ThreadlinePhoenix.Post`, `as_of/4`, `cast: true`, `:deleted_record`, and `:before_audit_horizon`.

### Example index contract
- **D-04:** Keep `examples/README.md` as the stable index entry point that points readers at `examples/threadline_phoenix/README.md`.

### Doc-contract coverage
- **D-05:** Extend or retain `test/threadline/readme_doc_contract_test.exs` assertions so the example README literals and `examples/README.md` index drift fail CI immediately.

### Agent discretion
- Exact prose for the example README headings and the order of the walkthrough sections.
- Whether any text in `examples/README.md` needs adjustment beyond preserving the nested README link and the canonical example-path wording.

</decisions>

<specifics>
## Specific Ideas

- The example README already has the right structure: prerequisites, regeneration contract, installation, runtime commands, audited HTTP path, time-travel walkthrough, correlation notes, jobs, and adoption links.
- The existing test file already checks the example README surface, so this phase should tighten that coverage only where the docs move.
- Phase 41 intentionally left this slice open so the example README can be repaired independently.

</specifics>

<canonical_refs>
## Canonical References

### Core phase context
- `.planning/ROADMAP.md` - v1.13 milestone placement.
- `.planning/REQUIREMENTS.md` - DOC-02 and DOC-03 requirements.
- `.planning/STATE.md` - current project state and phase sequencing.

### Example docs surface
- `examples/threadline_phoenix/README.md` - canonical Phoenix example walkthrough.
- `examples/README.md` - index entry that points at the nested example README.
- `test/threadline/readme_doc_contract_test.exs` - contract assertions for example README and index literals.

### Related docs already linked from the example README
- `guides/domain-reference.md` - incident JSON and time-travel reference anchors.
- `guides/production-checklist.md` - production adoption link target.
- `guides/adoption-pilot-backlog.md` - rollout/backlog link target.

</canonical_refs>

<deferred>
## Deferred Ideas

- Any root `README.md` edits, which belong to Phase 41.
- Broader example-app code changes outside the docs and doc-contract test surface.

</deferred>

---

*Phase: 42-example-readme-contract-repair*
*Context gathered: 2026-04-26*
