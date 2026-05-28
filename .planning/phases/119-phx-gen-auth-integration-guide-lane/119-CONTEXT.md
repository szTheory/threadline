# Phase 119: phx.gen.auth Integration Guide & Lane - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the majority Phoenix auth lane as **documentation + upgrade-path vocabulary**, not as a new library adapter or second reference app:

- `guides/integrations/phx-gen-auth.md` — copy-paste cookbook for `Threadline.Plug` and admin-gated `threadline_operator_surface/2`
- `guides/upgrade-path.md` — name and classify **`phx-gen-auth-reference`** (`reference` claim; honest boundaries vs `sigra-reference`)

**In scope:** AUTH-GUIDE-01/02/03, AUTH-LANE-01/02.

**Out of scope (later phases):** root integration tests (Phase 120), upgrade-path matrix row + four-lane doc-contract locks (Phase 120), getting-started/README/evaluator neutrality (Phase 121), `Threadline.Integrations.PhxGenAuth`, Pow/bearer lanes, example-app auth swap.

</domain>

<decisions>
## Implementation Decisions

### Adapter shape (no `Threadline.Integrations.PhxGenAuth`)
- **D-01:** **Do not** add `Threadline.Integrations.PhxGenAuth` (or any `Threadline.Integrations.*` module for phx.gen.auth). phx.gen.auth is host-generated code, not a soft-loadable Hex dep; a public adapter over-promises support and couples Threadline semver to generator churn.
- **D-02:** Teach a **host-owned template module** (conventional name `MyApp.AuditActor`) copied from the guide — same Plug seams as Sigra (`actor_fn`, `context_overrides_fn`), different packaging than `Threadline.Integrations.Sigra`.
- **D-03:** Keep `Threadline.Integrations.Sigra` as the **only** in-tree reference adapter (real optional dep + `sigra-reference` example proof). phx lane proof model = **guide + Phase 120 root tests**, not example app.

### Assign contract (`current_scope` capture, `current_user` operator bridge)
- **D-04:** **Capture layer (`actor_fn`)** standardizes on `conn.assigns[:current_scope]` → `user.id` via **map-safe** access (`with %{user: %{id: id}} <- scope` or `Map.get/2`). Logged out = `current_scope == nil` → `actor_fn` returns `nil`.
- **D-05:** **Operator layer (`authorize_fn`)** may use `assigns[:current_user]` **after** a host-owned bridge plug (pattern: `examples/threadline_phoenix` `OperatorUser` — derive operator assign from scope, do not read session in Threadline).
- **D-06:** Document **plug order** as a hard requirement: `fetch_session` → `fetch_current_scope` (generated `fetch_current_scope_for_user`) → `Threadline.Plug` on any pipeline with audited writes.
- **D-07:** **Legacy compatibility only:** one short “Phoenix 1.7 / `current_user` only” note with a 3-line fallback inside the **host** `actor_fn` template — scope-first, not dual-primary production wiring. Phase 120 secondary test may prove fallback; primary fixture is phx.gen.auth-shaped `%Scope{user: %User{}}`.

### Guide depth and structure (medium cookbook — parallel spine to sigra)
- **D-08:** Target **~70–90 lines** with the **same story arc** as `guides/integrations/sigra.md` but abbreviated shared contract prose. Section order:
  1. Intro + `phx-gen-auth-reference` lane honesty
  2. Prerequisites (host owns generator; no Threadline auth dep)
  3. Plug callback wire-up (snippets + bullets; link `guides/integration-contracts.md`)
  4. Surface and export auth stay host-owned (abbreviated split; admin `authorize_fn` example)
  5. Reference semantics (what Phase 120 will prove — numbered list, not “SPEC locked by adapter”)
  6. Optional correlation strategy (short; no Sigra-style formats table)
  7. Non-goals (AUTH-GUIDE-03)
  8. Lane and proof (guide + forthcoming root tests; not example app)
- **D-09:** **Omit** sigra-only sections: `## Install` (optional Hex dep), `## Soft-dep contract`. **Do not** duplicate sigra doc-contract Plug-string locks (~50 literals); phx guide gets a **smaller** marker set in Phase 121.
- **D-10:** HTML marker: `<!-- PHX-GEN-AUTH-03-INTEGRATION-GUIDE -->` for doc-contract tests.

### Operator `authorize_fn` depth
- **D-11:** Document **admin-only** `authorize_fn` with a copy-paste mount snippet (host role field, e.g. `role == "admin"` or `is_admin`).
- **D-12:** **Defer** runnable examples for `export_authorize_fn`, `evidence_authorize_fn`, `coverage_authorize_fn`, `policy_authorize_fn`, and support-scoped `{:ok, scope}` — link `guides/operator-surface.md` and `guides/integration-contracts.md`.
- **D-13:** Include **one footgun paragraph** (no second callback example): LiveView `on_mount` does not secure export HTTP routes; export uses `authorize_fn` fallback via `%{assigns: conn.assigns}` unless host sets `export_authorize_fn`.

### Upgrade-path lane timing (honest proof vocabulary)
- **D-14:** Phase 119 adds **`phx-gen-auth-reference` in prose only**: “Who this guide is for”, “How to tell which lane you are on”, vocabulary bullets (`reference`, narrower than `phoenix-surface`, not Sigra-compatible). **Do not** add a compatibility matrix row until Phase 120.
- **D-15:** Phase 119 proof wording: “Maintained composition path: `guides/integrations/phx-gen-auth.md`.” **Do not** cite `test/threadline/integrations/phx_gen_auth_integration_test.exs` or imply root CI already exercises this lane.
- **D-16:** Phase 120 ships matrix row + `upgrade_path_doc_contract` four-lane locks **in the same changeset** as root integration tests (AUTH-PROOF-01/02/03).
- **D-17:** Leave `sigra-reference` matrix row and semantics **unchanged** (AUTH-LANE-02).

### Correlation / `context_overrides_fn`
- **D-18:** **Default:** `context_overrides_fn` returns `%{}` (or omit callback). Session cookies are **not** a Threadline-prescribed correlation source.
- **D-19:** Document contract: `x-correlation-id` / `x-request-id` headers win; overrides are **additive fill-only** (Phase 49 / `Threadline.Plug` semantics).
- **D-20:** Optional **non-normative** host patterns only: propagate W3C `traceparent` trace id (or APM trace id) into `x-correlation-id` in an upstream plug; BFF sets header; business ids via `Threadline.Audit.transaction/3` — **no** `phx-session:` / `phx-user:` format table (Sigra prefixes stay in `sigra-reference` only).
- **D-21:** Remind readers: strict timeline `:correlation_id` filters require `:action` / `Audit.transaction/3` with matching correlation — plug context alone is insufficient.

### Cross-cutting architecture (coherent package)
- **D-22:** Follow observability-library norm (Sentry/OpenTelemetry/PaperTrail): **generic plug seam + host hook where identity is established** — not a generator adapter gem.
- **D-23:** Follow django-auditlog / domain reference: typed searchable actor + correlation; avoid inventing audit identity formats when headers or domain opts suffice.
- **D-24:** Recommendation-first planning for implementation details (Phase 50 D-16): planner may choose exact prose, fence names, and doc-contract literal list within these bounds without re-asking the user.

### Claude's Discretion
- Exact host template module name (`MyApp.AuditActor` vs `MyAppWeb.AuditContext`) as long as guide + tests agree.
- Whether “Reference semantics” lists 5 or 7 bullets before Phase 120 tightens wording to match tests.
- Minor cross-link placement in `upgrade-path.md` (upgrade-by-minor section vs lane detection only).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and v1.26 requirements
- `.planning/ROADMAP.md` — Phase 119 goal, success criteria, phase split 119/120/121
- `.planning/REQUIREMENTS.md` — AUTH-GUIDE-01/02/03, AUTH-LANE-01/02; out-of-scope table
- `.planning/PROJECT.md` — v1.26 milestone; host-owned auth boundary
- `.planning/STATE.md` — current position and next steps
- `.planning/threads/2026-05-27-diminishing-returns-assessment.md` — reach-gap rationale

### Prior integration decisions (Sigra lane — do not contradict)
- `.planning/research/sigra-integration-context.md` — Tier 1 vs Tier 2 adapter rationale; phx.gen.auth = Tier 1 cookbook
- `.planning/milestones/v1.15-phases/50-direct-sigra-host-wiring/50-CONTEXT.md` — direct callback wiring, tolerant request edge
- `.planning/milestones/v1.15-phases/49-native-plug-context-overrides/49-CONTEXT.md` — additive overrides only

### Shipped guides and contracts (templates + SSOT)
- `guides/integrations/sigra.md` — structural and honesty template for integration guide
- `guides/upgrade-path.md` — `supported` / `reference` / `unclaimed`; matrix proof rules
- `guides/integration-contracts.md` — `Threadline.Plug` and `authorize_fn` contract SSOT
- `guides/operator-surface.md` — mount, export/evidence/coverage callbacks (defer depth here)
- `guides/getting-started-saas.md` — §5 neutrality target for Phase 121 (do not rewrite in 119)

### Code patterns (read, do not duplicate as new public API in 119)
- `lib/threadline/plug.ex` — `actor_fn`, `context_overrides_fn`, header precedence
- `lib/threadline/integrations/sigra.ex` — `current_scope` read pattern (map-safe); Sigra-only correlation
- `examples/threadline_phoenix/lib/threadline_phoenix_web/user_auth.ex` — `fetch_current_scope` assign
- `examples/threadline_phoenix/lib/threadline_phoenix_web/operator_user.ex` — scope → `current_user` bridge for operator

### Product / OSS DNA
- `prompts/audit-lib-domain-model-reference.md` — capture vs semantics; host-owned actor
- `prompts/threadline-elixir-oss-dna.md` — doc contracts, auth-agnostic library, golden path
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — middleware `set_actor`, SQL-native correlation
- `prompts/prior-art/from-sigra/Building the gold-standard Elixir:Phoenix authentication library.md` — phx.gen.auth as generator not library; Scope pattern

### Verification touchpoints (Phase 120+, reference in planning)
- `test/threadline/upgrade_path_doc_contract_test.exs` — three-lane locks today; four-lane in 120
- `test/threadline/integrations/sigra_doc_contract_test.exs` — do not mirror full surface in phx guide

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Threadline.Plug` + `Threadline.Semantics.ActorRef.new/2` — unchanged public seam; guide snippets call these directly from host modules.
- `Threadline.Integrations.Sigra` — reads `current_scope`; proves phx-shaped assigns work at the assign key; **not** the phx lane’s copy-paste target.

### Established Patterns
- **Sigra = optional Hex adapter module**; **phx.gen.auth = host template module** — parallel lanes, asymmetric packaging.
- **Two assigns by design:** `current_scope` for capture, optional `current_user` for operator authorization after host bridge.
- **Fail loud:** missing actor when plug runs before auth (Phase 116 lesson) — guide must show pipeline order.

### Integration Points
- New file: `guides/integrations/phx-gen-auth.md`
- Edits: `guides/upgrade-path.md` (lane prose only in 119)
- No `lib/threadline/**` changes required for 119 unless planner adds doc-contract helper tests with zero behavior change.

</code_context>

<specifics>
## Specific Ideas

- Mental model for adopters: **“I use stock phx.gen.auth → read `phx-gen-auth.md`, not Sigra.”**
- Copy-paste golden path: `MyApp.AuditActor` in router — mirrors Sigra one-liner ergonomics without implying Hex support.
- Honesty line matching sigra guide: reference claim, not every generated layout or role field.
- Ecosystem lesson applied: Rails Audited `whodunnit`, Sentry `set_user_context` — host implements identity once; Threadline consumes via `actor_fn`.
- Footgun explicitly avoided: prescribing `phx-session:` correlation formats (Sigra lock-in pattern stays Sigra-only).

</specifics>

<deferred>
## Deferred Ideas

- **`Threadline.Integrations.PhxGenAuth`** — rejected for 119; revisit only if sustained demand for a tested optional helper (unlikely; conflicts with host-owned generator story).
- **Pow / bearer / API-token reference lanes** — REQUIREMENTS v2; session lane first.
- **Upgrade-path matrix row** — Phase 120 (with tests).
- **README / evaluating-threadline / getting-started §5 neutrality** — Phase 121.
- **Full operator callback matrix in phx guide** — stays in `operator-surface.md`.
- **Parsing `traceparent` inside `Threadline.Plug`** — host upstream plug; out of scope.

</deferred>

---

*Phase: 119-phx-gen-auth-integration-guide-lane*
*Context gathered: 2026-05-27*
