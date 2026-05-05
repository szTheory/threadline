# Phase 49: native-plug-context-overrides - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Make additive request-context wiring a first-class `Threadline.Plug` capability instead of an example-only composition pattern. This phase formalizes a native `:context_overrides_fn` callback with deterministic validation, preserves existing `actor_fn` behavior for hosts that do not use the new hook, and turns the direct host-wiring path into the stable public contract that later phases build on.

</domain>

<decisions>
## Implementation Decisions

### Public API shape
- **D-01:** `Threadline.Plug` should expose `:context_overrides_fn` as a generic host-level callback, not as a Sigra-specific or correlation-only escape hatch.
- **D-02:** The top-line host-wiring story is two direct callbacks on `Threadline.Plug`: `actor_fn` for identity and `context_overrides_fn` for additive request metadata.
- **D-03:** Actor ownership stays with `actor_fn`. `:context_overrides_fn` must not become a second actor-authority path.

### Allowed override surface
- **D-04:** Narrow the override allowlist to additive request metadata only: `:request_id` and `:correlation_id`.
- **D-05:** Remove `:actor_ref` from the override allowlist. Allowing actor replacement through `:context_overrides_fn` creates ambiguous provenance, weakens the `actor_fn` contract, and is too easy to misuse in misordered pipelines.
- **D-06:** Remove `:remote_ip` from the override allowlist. Proxy-aware IP normalization is a host concern and should happen upstream before `Threadline.Plug`; the library should keep `remote_ip` derived from `conn.remote_ip`.

### Precedence model
- **D-07:** Transport-derived values are authoritative. `request_id` and `correlation_id` should come from the normal conn/header extraction path first.
- **D-08:** `:context_overrides_fn` may supplement `:request_id` or `:correlation_id` only when the derived base value is `nil`; it must not replace an explicit inbound header or already-derived value.
- **D-09:** Keep the existing least-surprise rule already implied by Sigra integration: when `x-correlation-id` is present, it wins and override callbacks should return `%{}` for that field.

### Validation contract
- **D-10:** Validation inside `Threadline.Plug` should stay narrow and deterministic: the callback must return a map and the keys must be a subset of the allowed override keys.
- **D-11:** Unknown keys must raise `ArgumentError` immediately. Non-map returns must also raise `ArgumentError` immediately. Invalid shapes should fail loudly, not be ignored.
- **D-12:** Do not add deep coercion or Ecto-style casting inside `Threadline.Plug`. Hosts should normalize values before returning them from the callback. This keeps the public contract small and avoids turning the hook into a mini validation framework.
- **D-13:** `nil` values in the returned override map are non-destructive and do not delete or clobber derived values.

### Docs and adopter framing
- **D-14:** Teach this feature as a generic `Threadline.Plug` host-wiring capability first, with `Threadline.Integrations.Sigra` as the canonical worked example.
- **D-15:** Do not frame the feature as "the correlation hook." That is too narrow for the public surface and creates future naming pressure once `request_id` and other additive request metadata matter.
- **D-16:** Keep actor identity primary in the narrative. `context_overrides_fn` is additive enrichment, not a peer replacement for actor extraction.
- **D-17:** Documentation must make placement, precedence, and failure behavior explicit: where the plug belongs, which values win, what raises, and what stays host-owned.

### Developer experience and ecosystem posture
- **D-18:** Favor explicit, narrow options over broad escape hatches. This matches Plug/Phoenix conventions and protects the library from surprising behavior becoming a permanent public contract.
- **D-19:** Preserve unchanged behavior for hosts that only use `actor_fn` or do not pass `:context_overrides_fn` at all.
- **D-20:** Recommendation-first synthesis is preferred for low- and medium-impact planning choices in this project. Escalate interactively only for choices that materially affect public API stability, security model, naming, or milestone scope.

### the agent's Discretion
- Exact wording of the moduledoc and guide prose, provided it preserves the contract above.
- Whether to phrase the docs as "additive request metadata" or "additive request-derived audit context," provided the meaning stays narrow and explicit.
- Exact test organization and helper naming, provided precedence and failure behavior are fully locked.

</decisions>

<specifics>
## Specific Ideas

- Preferred mental model: `Threadline.Plug` derives the baseline audit context from the conn, then accepts a small additive metadata hook for cases where the host can supply request-derived values the plug cannot infer on its own.
- Recommended docs sentence: `actor_fn` determines who acted; `context_overrides_fn` can fill in additive request metadata such as `request_id` or `correlation_id` when the base conn extraction has no value.
- If a host needs proxy-aware IP handling, it should normalize `conn.remote_ip` earlier in the pipeline rather than using this hook.
- The direct Sigra path remains the best concrete example, but the public surface should read cleanly even for hosts that have never heard of Sigra.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/ROADMAP.md` — Phase 49 goal, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` — `PLUG-01` and `PLUG-02` define the required host contract and deterministic validation behavior.
- `.planning/STATE.md` — current milestone sequencing and the explicit note that Phase 49 is the next planning target.

### Prior decisions that constrain this phase
- `.planning/milestones/v1.14-phases/44-sigra-integration-adapter/44-CONTEXT.md` — phase 44 established the earlier two-step Sigra workaround and forward-pointed this native hook as the cleaner future path.
- `.planning/milestones/v1.14-phases/47-saas-adopter-onramp/47-CONTEXT.md` — docs and quickstart positioning for direct host wiring.
- `.planning/milestones/v1.14-phases/48-threadline-0.3.0-release/48-CONTEXT.md` — release-era documentation layering and recommendation-first workflow preference already noted there.

### Code surfaces to inspect and likely change
- `lib/threadline/plug.ex` — current `Threadline.Plug` contract and in-flight `:context_overrides_fn` implementation.
- `lib/threadline/semantics/audit_context.ex` — current `AuditContext` fields; do not expand the struct in this phase.
- `lib/threadline/integrations/sigra.ex` — canonical example of a host adapter that should compose with the native hook.
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — example app’s direct host-wiring pipeline.
- `test/threadline/plug_test.exs` — must lock precedence, unknown-key failure, non-map failure, and non-destructive nil behavior.
- `test/threadline/integrations/sigra_test.exs` — must lock the Sigra composition path and the "header wins" behavior.

### External ecosystem references
- `https://hexdocs.pm/plug/Plug.RequestId.html` — least-surprise precedent: existing request header wins; the plug fills when absent.
- `https://hexdocs.pm/phoenix/plug.html` — explicit Plug/Phoenix wiring patterns.
- `https://hexdocs.pm/sentry/setup-with-plug-and-phoenix.html` — small, explicit integration callbacks and context handling in a Plug/Phoenix library.
- `https://www.rubydoc.info/gems/paper_trail/PaperTrail%2FRequest.whodunnit%3D` — actor identity kept distinct from request metadata in a mature audit library.
- `https://www.rubydoc.info/gems/paper_trail/11.0.0/PaperTrail%2FRequest.controller_info` — additive request metadata should stay separate from actor semantics.
- `https://django-auditlog.readthedocs.io/en/latest/usage.html` — request metadata and actor concerns are handled through distinct, explicit integration points.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Plug` already has the basic callback plumbing and deterministic key/result-shape failure path; the planning work should tighten the allowed surface and precedence behavior rather than inventing a new mechanism.
- `Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1` already models the desired behavior for `correlation_id`: return `%{}` when the explicit header is present and only synthesize when absent.
- The example router already demonstrates the direct callback pattern, so the phase should converge the contract around that path instead of reintroducing helper pre-plugs.

### Established Patterns
- Plug/Phoenix favors narrow, explicit options over broad catch-all hooks. The final API should keep that posture.
- Threadline already treats documentation contracts and deterministic failure behavior as first-class public API concerns.
- Prior milestones consistently prefer explicit host-owned boundaries over maintainer magic. This phase should continue that philosophy.

### Integration Points
- `lib/threadline/plug.ex` is the primary implementation point for the narrowed allowlist and precedence semantics.
- `test/threadline/plug_test.exs` is the primary place to codify the final callback contract.
- `lib/threadline/integrations/sigra.ex` and `test/threadline/integrations/sigra_test.exs` are the canonical example path that should stay aligned with the narrowed contract.
- Guides and example app docs in later phases should present this as the stable native host-wiring path.

</code_context>

<deferred>
## Deferred Ideas

- A separate future option for host-controlled IP normalization, if real adopter pressure appears. Do not smuggle this into `:context_overrides_fn` now.
- Any broader generic metadata surface beyond `:request_id` and `:correlation_id`, unless a future phase establishes a concrete need with clear provenance rules.
- Any second actor override path or escape hatch through `:context_overrides_fn`.
- Any deeper coercion, casting, or schema-like validation layer inside `Threadline.Plug`.

</deferred>

---

*Phase: 49-native-plug-context-overrides*
*Context gathered: 2026-05-05*
