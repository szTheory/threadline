# Phase 52: docs-and-contract-alignment - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Align the adopter-facing docs and contract tests around the final v1.15 host
integration story now that the three underlying behavior slices are in place:

- Phase 49 locked native `Threadline.Plug` request-context overrides
- Phase 50 locked direct `Threadline.Integrations.Sigra` callback wiring
- Phase 51 locked the authenticated incident drill-down baseline

This phase is the consolidation pass. It should make the getting-started guide,
Sigra guide, incident/domain-reference docs, adoption backlog, and example
README describe one coherent copy-paste story, then lock that story with
targeted doc-contract coverage so future edits cannot drift the public
narrative silently.

It is **not** the phase for new runtime behavior, new auth/tenancy mechanics,
new adapter breadth, or a broader rework of unrelated guides.

</domain>

<decisions>
## Implementation Decisions

### Scope and narrative shape
- **D-01:** Phase 52 is docs-and-contract consolidation only. Do not introduce new library/runtime behavior unless a doc contract is impossible to make truthful without a tiny wording-only companion edit.
- **D-02:** The public host-wiring story should read in this order everywhere: `Threadline.Plug` is wired directly with `actor_fn` and `context_overrides_fn`; `actor_fn` decides identity; `context_overrides_fn` fills additive request metadata only; the incident drill-down example requires an authenticated actor; tenancy and richer authorization remain host-owned.
- **D-03:** Keep one canonical module/function vocabulary across surfaces: `Threadline.Integrations.Sigra.actor_ref_from_conn/1` and `Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1`. Do not reintroduce example-local delegate naming or alternate blessed wiring seams.

### Responsibility boundaries
- **D-04:** `actor_fn` remains the sole actor-authority path in docs as well as code. No guide or README should imply `context_overrides_fn` can replace actor identity.
- **D-05:** `context_overrides_fn` must be described narrowly as additive `request_id` / `correlation_id` metadata only. Keep proxy/IP normalization and broader host-derived shaping explicitly upstream and host-owned.
- **D-06:** Incident drill-down docs must describe the auth boundary in normalized Threadline terms first: an authenticated actor is present in audit context. Avoid teaching Sigra-private request fields as the core public contract.
- **D-07:** Every touched surface that mentions incident drill-down must repeat the same honesty line: authenticated baseline shipped, tenancy/membership/richer authorization still belong to the host app.

### Contract-test posture
- **D-08:** Prefer extending existing doc-contract tests where coverage already exists instead of creating a large new Phase 52-only test suite. Add new tests only where a critical public surface is currently unguarded.
- **D-09:** Contract tests should lock concrete public literals, section markers, or copied router snippets that define the host-integration story. Do not assert broad editorial wording that is not part of the user-facing contract.
- **D-10:** The contract suite should prove cross-doc consistency, not just single-file truth. Tests should fail if one guide keeps stale host-wiring language while another reflects the final Phase 49–51 contract.

### Phase boundary against prior work
- **D-11:** Preserve Phase 51's narrow incident-auth promise; Phase 52 may align the host-wiring narrative around it, but must not expand into full authorization policy design.
- **D-12:** Preserve Phase 50's direct Sigra path; Phase 52 may propagate it into broader adopter docs, but should not reopen adapter semantics or example runtime scope.
- **D-13:** Preserve Phase 49's additive-only override semantics; Phase 52 may repeat them across docs/tests, but should not broaden the override surface or rename the callback contract.

### Planning preference
- **D-14:** Prefer one cohesive recommendation-first docs sweep over many tiny micro-plans unless a split clearly reduces risk. The main natural seam is docs updates versus contract-test updates, with tests depending on the final literal wording.

### the agent's Discretion
- Exact sentence-level phrasing, provided the public contract and host-owned boundaries above remain intact.
- Whether one or two PLAN files are the best execution shape, provided the dependency between docs edits and drift guards is explicit.
- Which existing doc-contract files get tightened versus whether one new targeted contract test is warranted for an uncovered public surface.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and active milestone context
- `.planning/ROADMAP.md` — Phase 52 goal, dependency on Phase 51, and success criteria.
- `.planning/REQUIREMENTS.md` — `ADOPT-03` is the sole requirement for this phase.
- `.planning/PROJECT.md` — current v1.15 milestone framing and why host integration completion matters.
- `.planning/STATE.md` — current sequencing and any active worktree notes.

### Prior phase decisions that constrain this phase
- `.planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md` — final host-wiring callback boundaries and additive-only override semantics.
- `.planning/milestones/v1.15-phases/50-direct-sigra-host-wiring/50-CONTEXT.md` — direct Sigra callback vocabulary and the removal of app-local delegate framing.
- `.planning/milestones/v1.15-phases/51-authenticated-incident-drill-down/51-CONTEXT.md` — authenticated incident baseline and host-owned authz/tenancy boundary.
- `.planning/milestones/v1.15-phases/51-authenticated-incident-drill-down/51-PATTERNS.md` — exact file/test analogs for the incident-facing doc surfaces already touched in Phase 51.

### Primary docs likely to be aligned
- `guides/getting-started-saas.md` — onboarding guide that already covers direct callback wiring and the incident baseline.
- `guides/integrations/sigra.md` — authoritative adapter guide for the direct callback contract.
- `guides/domain-reference.md` — public reference surface containing the incident JSON contract marker.
- `guides/incident-playbook.md` — operator-facing incident narrative.
- `guides/adoption-pilot-backlog.md` — evidence framing that should reflect the authenticated baseline honestly.
- `examples/threadline_phoenix/README.md` — runnable example README that must match the shipped router wiring and incident security boundary.

### Existing contract tests and adjacent proof surfaces
- `test/threadline/integrations/sigra_doc_contract_test.exs` — direct Sigra wiring and callback wording drift guard.
- `test/threadline/getting_started_saas_doc_contract_test.exs` — quickstart contract guard.
- `test/threadline/exploration_routing_doc_contract_test.exs` — domain-reference incident block drift guard.
- `test/threadline/incident_playbook_doc_contract_test.exs` — incident playbook boundary guard.
- `test/threadline/stg_doc_contract_test.exs` — adoption backlog evidence-row guard.
- `test/threadline/example_phoenix_readme_contract_test.exs` — example README drift guard for direct wiring and incident wording.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — source of truth for the direct callback snippet the docs should reflect.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/audit_transaction_controller.ex` — source of truth for the shipped authenticated drill-down baseline wording and behavior boundary.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The repo already has targeted doc-contract tests for nearly every surface Phase 52 cares about; most work should be tightening and unifying those, not inventing a new framework.
- `guides/getting-started-saas.md`, `guides/integrations/sigra.md`, and `examples/threadline_phoenix/README.md` already contain the direct callback names, so Phase 52 should converge wording rather than introduce a new example path.
- `guides/domain-reference.md`, `guides/incident-playbook.md`, `guides/adoption-pilot-backlog.md`, and related tests already carry the authenticated incident baseline, which gives the phase an existing wording/test spine to reuse.

### Established Patterns
- Threadline doc-contract tests use small, explicit `String.contains?` assertions and marker checks rather than snapshot-style whole-file comparisons.
- Public docs in this repo prefer explicit host-owned boundaries over library-owned magic; the final alignment pass should continue that posture.
- Recent v1.15 plans split naturally into runtime behavior first, then docs/tests. Phase 52 should treat docs wording as the producer step and contract tests as the dependent lock step.

### Integration Points
- The most likely edit cluster is `guides/`, `examples/threadline_phoenix/README.md`, and the existing `test/threadline/*doc_contract*_test.exs` files.
- The main consistency seam is the wording shared across direct host wiring and incident drill-down docs. If one surface differs, the plan should force it back to the canonical story.
- Dirty worktree changes are already present in the touched docs/tests, so execution plans must explicitly instruct the executor to work with current edits rather than resetting them.

</code_context>

<specifics>
## Specific Ideas

- A clean execution shape is likely two plans:
  1. unify the adopter-facing docs around one host-wiring + incident boundary story
  2. tighten/extend the existing doc-contract tests so that story cannot drift
- Success should be measurable by a shared set of literals appearing across the relevant docs: the direct Sigra callback names, additive-only override wording, and the authenticated-baseline/host-owned-authorization boundary.
- If a new test is needed at all, it should be a narrow gap-filler for an uncovered public surface, not a broad new umbrella suite.
- The example README and getting-started guide are the highest-risk drift surfaces because they are the most copy-pasteable adopter entry points; the plan should treat them as first-class must-haves.

</specifics>

<deferred>
## Deferred Ideas

- Additional auth adapters beyond Sigra.
- Full tenancy or authorization walkthroughs in the example app.
- Any new runtime host-wiring API beyond the Phase 49 callback contract.
- Broader docs cleanup unrelated to the v1.15 host integration story.

</deferred>

---

*Phase: 52-docs-and-contract-alignment*
*Context gathered: 2026-05-05*
