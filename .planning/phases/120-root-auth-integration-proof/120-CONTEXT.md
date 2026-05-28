# Phase 120: Root Auth Integration Proof - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove the Phase 119 `phx-gen-auth-reference` cookbook in CI — without mutating `examples/threadline_phoenix` or adding a public `Threadline.Integrations.PhxGenAuth` adapter:

- `test/threadline/integrations/phx_gen_auth_integration_test.exs` — AUTH-PROOF-01/02
- `guides/upgrade-path.md` — fourth compatibility-matrix row (`phx-gen-auth-reference`, `reference`)
- `test/threadline/upgrade_path_doc_contract_test.exs` — four-lane locks + retire “forthcoming” wording
- Guide fixes: `phx-gen-auth.md` and `upgrade-path.md` cite the real test path; **fix `authorize_fn` to 1-arity** (guide currently shows invalid 2-arity vs runtime)

**In scope:** AUTH-PROOF-01, AUTH-PROOF-02, AUTH-PROOF-03; matrix row (119-CONTEXT D-16); `refute` on “forthcoming” in upgrade-path + phx guide.

**Out of scope:** `phx_gen_auth_doc_contract_test.exs` (Phase 121 / ADOPT-AUTH-03); getting-started/README neutrality (Phase 121); legacy `current_user`-only capture CI (guide note only); `Threadline.Integrations.PhxGenAuth` in `lib/`.

</domain>

<decisions>
## Implementation Decisions

### 1. Proof depth — hybrid B + one minimal C
- **D-120-01:** Structure like `sigra_test.exs`: **host-shaped module functions first**, not anonymous inline fns.
- **D-120-02:** Test-local module `Threadline.Integrations.PhxGenAuthReference.AuditActor` in the integration test file — mirrors guide `MyApp.AuditActor` (rename comment at top). **No** new `lib/threadline/integrations/phx_gen_auth.ex`.
- **D-120-03:** **Exactly one** `Threadline.Plug.call/2` smoke: guide router opts (`actor_fn` + `context_overrides_fn` returning `%{}`) + `current_scope` + optional `x-request-id` header. Proves copy-paste pipeline wiring without duplicating `plug_test.exs`.
- **D-120-04:** Do **not** re-prove Plug merge rules (header precedence, unknown override keys, remote_ip) in the phx file — `test/threadline/plug_test.exs` remains SSOT.

### 2. Fixture shape — nested maps + small support module
- **D-120-05:** Use **nested plain maps** (`%{user: %{id: "u-42"}}`, `%{role: "admin"}`) via `test/support/phx_gen_auth_fixtures.ex` — same literals as the guide; no example-app `Accounts.Scope` structs.
- **D-120-06:** Assign with `Plug.Conn.assign/3` + `Plug.Test` only — no DB, no generated auth stack in root suite.
- **D-120-07:** **Optional single test:** assign a local `defstruct` with identical keys to document struct/map parity for D-07 shape — not the default fixture dialect.
- **D-120-08:** Use **string** user ids in fixtures (`to_string/1` path in guide).

### 3. Reference semantics coverage — prove 1–3 only; cite 4–6
- **D-120-09:** Behavioral tests cover guide **Reference semantics** items **1–3** only:
  1. Scope `user.id` → `:user` actor (`actor_fn`)
  2. Logged-out scope → `nil` actor
  3. Admin `authorize_fn` allow/deny
- **D-120-10:** Items **4–6** (header wins, additive overrides, unknown-key raise) — **cite** `test/threadline/plug_test.exs` in a module comment; **no** duplicate asserts in phx integration file.
- **D-120-11:** Target **~8–12 tests** total across three describes: `guide AuditActor actor_fn`, `guide authorize_fn admin gate`, `Threadline.Plug composition` (single smoke).

### 4. Legacy `current_user` capture fallback — guide only, no CI
- **D-120-12:** Keep Phoenix 1.7 `current_user`-only fallback as the **short guide paragraph** (119-CONTEXT D-07). **Do not** add a secondary `describe` in Phase 120.
- **D-120-13:** Rationale: AUTH-PROOF-01 targets 1.8+ `current_scope`; observability-library norm (Sentry/OTel) documents escape hatches without per-assign CI matrices; avoids guide↔test drift for brownfield-only paths.

### 5. `authorize_fn` posture — conn mirror via ExportAuthPlug; fix guide arity
- **D-120-14:** Prove AUTH-PROOF-02 with **1-arity** guide callback on `%{assigns: %{current_user: %{role: "admin"}}}` — drive through `Threadline.OperatorSurface.ExportAuthPlug` (grant = not halted; deny = halted 403). Matches export HTTP footgun in guide § Surface.
- **D-120-15:** **Fix** `guides/integrations/phx-gen-auth.md` mount snippet: remove erroneous second `_` parameter on `authorize_fn` clauses (runtime calls **1-arity** only: `authorize_fn.(mirror)` / `authorize_fn.(socket)`).
- **D-120-16:** Do **not** mount `threadline_operator_surface` or LiveView `on_mount` in Phase 120 — `operator_surface/auth_test.exs` and `export_auth_plug_test.exs` own machinery; phx file proves **host snippet + conn boundary** only.
- **D-120-17:** Operator tests already use `current_user` on socket; phx lane adds **admin role gate** from cookbook — complementary, not duplicate.

### 6. Matrix row + doc-contract literals
- **D-120-18:** Insert matrix row **after** `phoenix-surface`, **before** `sigra-reference`:

  `| phx-gen-auth-reference | reference | Host-generated session auth (mix phx.gen.auth or equivalent) + phoenix-surface optional deps | Root mix.lock Phoenix/LV/HTML/PubSub versions (no Sigra) | guides/integrations/phx-gen-auth.md, test/threadline/integrations/phx_gen_auth_integration_test.exs, mix verify.test, verify-test |`

- **D-120-19:** Extend `upgrade_path_doc_contract_test.exs` only (**~12–16** new asserts): fourth lane detection string, matrix row prefix, proof anchors, `refute` “forthcoming” in both guides. **Do not** add `phx_gen_auth_doc_contract_test.exs` in 120 (deferred to 121 per 119-CONTEXT D-09).
- **D-120-20:** Leave `sigra-reference` matrix row literals **unchanged** (AUTH-LANE-02).
- **D-120-21:** Replace “forthcoming” / “Phase 120” proof deferral in `guides/upgrade-path.md` § lane detection and `guides/integrations/phx-gen-auth.md` § Lane and proof with the real test path — same changeset as tests (D-16).
- **D-120-22:** Phx row must **not** claim `mix verify.example`, `examples/threadline_phoenix/*`, or `verify-compile-no-optional`.

### Cross-cutting architecture (coherent package)
- **D-120-23:** Three-layer test split (ecosystem lesson + in-repo precedent): **plug_test** = mechanism; **operator_surface/** = authorize interpreter; **integrations/phx_gen_auth** = lane cookbook contract.
- **D-120-24:** Follow django-auditlog / PaperTrail / Sentry pattern: **identity at host hook** (`actor_fn`), **authorization at host gate** (`authorize_fn`) — Threadline does not own either.
- **D-120-25:** Adopter DX: integration test file is **living cookbook proof** — copy `PhxGenAuthReference.AuditActor` → `MyApp.AuditActor`; upgrade-path matrix cites file path for procurement/CI honesty.
- **D-120-26:** Planner discretion: exact test names, helper module naming, whether Plug smoke also asserts `x-correlation-id` — within D-120-11 budget.

### Claude's Discretion
- Exact count of nil/absent-scope branches (missing key vs `nil` scope vs `user: nil`).
- Whether Plug smoke includes correlation header or only request-id.
- Minor matrix cell wording if it matches existing three-row column style.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 120 goal, success criteria, depends on 119
- `.planning/REQUIREMENTS.md` — AUTH-PROOF-01/02/03
- `.planning/phases/119-phx-gen-auth-integration-guide-lane/119-CONTEXT.md` — lane architecture, D-16 matrix+tests same changeset, no PhxGenAuth adapter
- `.planning/STATE.md` — current position

### Product / ecosystem research
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — separate capture vs identity; queryable metadata; avoid opaque blobs
- `prompts/audit-lib-domain-model-reference.md` — ActorRef, host-owned auth boundary
- `prompts/threadline-elixir-oss-dna.md` — doc contracts, auth-agnostic library, golden path
- `.planning/research/sigra-integration-context.md` — Tier 1 cookbook vs Tier 2 adapter; `actor_fn` as canonical seam

### Shipped guides and contracts
- `guides/integrations/phx-gen-auth.md` — snippets under test; fix authorize_fn arity in 120
- `guides/upgrade-path.md` — fourth matrix row; retire forthcoming wording
- `guides/integration-contracts.md` — Plug and authorize_fn SSOT
- `guides/operator-surface.md` — deferred operator callback depth

### Test templates (read, extend — do not duplicate wholesale)
- `test/threadline/integrations/sigra_test.exs` — lane integration structure (B + minimal C)
- `test/threadline/plug_test.exs` — semantics 4–6 SSOT
- `test/threadline/upgrade_path_doc_contract_test.exs` — three-lane locks to extend
- `test/threadline/operator_surface/export_auth_plug_test.exs` — mirror + halt semantics for AUTH-PROOF-02 driver
- `test/threadline/operator_surface/auth_test.exs` — on_mount matrix (link only)

### Code seams
- `lib/threadline/plug.ex` — actor_fn, context_overrides_fn
- `lib/threadline/operator_surface/export_auth_plug.ex` — 1-arity authorize via mirror
- `examples/threadline_phoenix/lib/threadline_phoenix_web/operator_user.ex` — scope → current_user bridge (reference only; not mutated in 120)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Plug.Test` + `assign(:current_scope, …)` — zero-host integration harness
- `ExportAuthPlug` — proves guide `authorize_fn` on conn assigns without LiveView boot
- `sigra_test.exs` describe layout — copy structure, not Sigra correlation tables

### Established Patterns
- **Asymmetric lanes:** Sigra = optional adapter + example; phx = host template + root tests only
- **Map-safe assigns:** bracket access on `conn.assigns[:current_scope]`; pattern match on map shape
- **Fail loud on plug order:** documented in guide; not testable without full router — comment only

### Integration Points
- New: `test/threadline/integrations/phx_gen_auth_integration_test.exs`
- New: `test/support/phx_gen_auth_fixtures.ex`
- Edit: `guides/upgrade-path.md` (matrix row + lane detection proof strings)
- Edit: `guides/integrations/phx-gen-auth.md` (proof path + authorize_fn arity)
- Edit: `test/threadline/upgrade_path_doc_contract_test.exs` (four-lane)

</code_context>

<specifics>
## Specific Ideas

- Mental model: **“Sigra lane has `sigra_test.exs`; phx lane has `phx_gen_auth_integration_test.exs`”** — symmetric honesty, asymmetric packaging.
- JaVers/PaperTrail lesson: prove **human-copyable recipes**, not every framework version matrix.
- Footgun explicitly avoided: second `plug_test.exs` in integration lane; prescribing `phx-session:` correlation formats; 2-arity authorize_fn in docs.
- ExportAuthPlug choice honors guide footgun: **HTTP export** uses conn assigns, not LiveView `on_mount`.

</specifics>

<deferred>
## Deferred Ideas

- **`phx_gen_auth_doc_contract_test.exs`** — Phase 121 (ADOPT-AUTH-03); ~12–18 literals, not sigra-scale (~55)
- **Legacy `current_user` capture CI describe** — guide-only unless adopter reports blocked migration
- **Full operator mount / router compile test in phx file** — doc-contract / example territory
- **Pow / bearer reference lanes** — REQUIREMENTS v2
- **Parsing traceparent inside Threadline.Plug** — host upstream plug (119 deferred)

</deferred>

---

*Phase: 120-root-auth-integration-proof*
*Context gathered: 2026-05-28*
