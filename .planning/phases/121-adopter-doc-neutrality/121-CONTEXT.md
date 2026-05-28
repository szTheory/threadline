# Phase 121: Adopter Doc Neutrality - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Make first-hour and evaluator discovery docs **auth-neutral by default** while keeping both reference lanes honest and discoverable:

- **ADOPT-AUTH-01:** `guides/getting-started-saas.md` §5 — auth-agnostic Plug wiring first; Sigra as optional `sigra-reference` lane
- **ADOPT-AUTH-02:** `README.md` + `guides/evaluating-threadline.md` — four named lanes; link `phx-gen-auth.md` and `sigra.md` as peer reference integrations (neither required)
- **ADOPT-AUTH-03:** Doc-contract tests lock phx guide markers, neutrality strings, and discovery links (~12–18 literals in new phx contract; targeted README/evaluator/getting-started edits)

**In scope:** Doc copy + doc-contract tests + `mix.exs` `verify.doc_contract` registration for new phx contract.

**Out of scope:** Replacing Sigra in `examples/threadline_phoenix`; `Threadline.Integrations.PhxGenAuth`; Pow/bearer lanes; duplicating upgrade-path matrix row locks (Phase 120).

</domain>

<decisions>
## Implementation Decisions

### Cross-cutting architecture (coherent package)

- **D-121-01:** **Three-tier doc model** (observability-library norm: Sentry / OpenTelemetry / PaperTrail / django-auditlog):
  1. **Universal contract** — `Threadline.Plug` + host `actor_fn` / `context_overrides_fn` (integration-contracts SSOT)
  2. **Reference lanes** — linked cookbooks (`phx-gen-auth-reference`, `sigra-reference`)
  3. **Runnable proof** — example app / root tests, visually subordinate, never the hero fence
- **D-121-02:** Threadline **does not own auth**; docs must never imply Sigra or phx.gen.auth is required for capture. Example app remains `sigra-reference` proof only.
- **D-121-03:** **Matrix table body stays only in `upgrade-path.md`.** README/evaluator name four lanes + link guides; do not copy full compatibility table into README.

### 1. Getting-started §5 primary snippet (Option D + A)

- **D-121-04:** **Two-tier §5.** Opening: host establishes identity on `conn`, then `Threadline.Plug` with host callbacks.
- **D-121-05:** **Primary code fence (canonical)** matches `guides/integration-contracts.md`:

  ```elixir
  plug Threadline.Plug,
    actor_fn: &MyApp.Audit.actor_ref_from_conn/1,
    context_overrides_fn: &MyApp.Audit.audit_context_overrides_from_conn/1
  ```

  (Host module name is host-owned; phx guide uses `MyApp.AuditActor` — one sentence: same callbacks, rename freely within your app.)
- **D-121-06:** **Keep** existing §5 contract literals: plug order after auth; `actor_fn` sole authority; additive overrides; `ArgumentError` on bad overrides.
- **D-121-07:** **Lane pointers** (short bullets, not duplicate cookbooks):
  - `phx-gen-auth-reference` → `guides/integrations/phx-gen-auth.md`
  - `sigra-reference` (optional) → `guides/integrations/sigra.md`
  - Lane matrix → `guides/upgrade-path.md`
- **D-121-08:** **Optional labeled subsection** under §5: `<!-- getting-started-sigra-reference-fence -->` (or stable `###` heading) containing Sigra callbacks synced from example router anchor `router-pipeline-actor-fn`. Summary line must say **sigra-reference example app only**.
- **D-121-09:** **Remove** opening prose “The Phoenix example keeps… Sigra callbacks directly” as the default narrative. **Refute** `Threadline.Integrations.Sigra` in §5 body before the optional subsection.

**Rejected:** Option C (Sigra-first fence + disclaimer) — fails ADOPT-AUTH-01; Option B alone (phx fence as universal quickstart) — overfits one reference lane.

### 2. §6 authenticate + example coupling (Option B)

- **D-121-10:** **Generic contract first** in §6 `Authenticate before the audited API call`:
  - Identity on `conn` before `Threadline.Plug` on audited pipelines
  - Prefer `401`/`403` at host auth boundary; `500` / `missing actor` = semantics rejected after capture (keep existing teaching)
  - Small **lane table**: phx guide | Sigra guide | upgrade-path
- **D-121-11:** **Runnable curl** moves to collapsed `<details>` (or equivalent) titled visibly: **Runnable curl — sigra-reference example app only** (`examples/threadline_phoenix`). Keep minimal curl inside; **link** example README anchor as SSOT for cookie staging (limit drift with Phase 116 runbook).
- **D-121-12:** **§6 opening** must not read as “every adopter uses Sigra login.” Evaluator path: expand details block; adopter on phx lane: follows lane table to phx guide without copying `_threadline_phoenix_key`.

**Rejected:** Option A (delegate all curl to example README only) — breaks self-contained first-hour doc for `mix verify.example` Track A; Option C (§6 unchanged) — contradicts neutral §5.

### 3. README & evaluator discovery (Option A refined)

- **D-121-13:** **Four named lanes** in README Start here: `capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, `sigra-reference` → link `guides/upgrade-path.md`. Update `readme_doc_contract_test` three-lane literal.
- **D-121-14:** **Replace** isolated “Using Sigra” Start-here bullet with one grouped bullet:

  **Phoenix auth (reference lanes, pick one):** link phx-gen-auth.md · link sigra.md — neither required; see upgrade-path for claim types.

- **D-121-15:** **Documentation** section: insert `guides/integrations/phx-gen-auth.md` before or beside Sigra link; optional parenthetical “reference lane” on Sigra line.
- **D-121-16:** **`evaluating-threadline.md`:** extend lane paragraph with phx guide link, `` `phx-gen-auth-reference` ``, neutrality sentence (host proves auth in staging; maintainers prove phx via root integration tests, sigra via `mix verify.example`). Label Track A / example path as **sigra-reference** where it names the example app.
- **D-121-17:** **Do not** call phx.gen.auth the “default Phoenix path” or imply `reference` = `supported`. Order: supported lanes first, then reference auth integrations **phx then sigra** (matches upgrade-path matrix row order).

**Rejected:** Option B (phx-first as default product path) — oversells `reference` lane; Option C (lanes only in upgrade-path) — fails ADOPT-AUTH-02 / NARR discovery discipline.

### 4. Doc-contract strategy (Option A + C necessity)

- **D-121-18:** **New** `test/threadline/integrations/phx_gen_auth_doc_contract_test.exs` (~12–18 asserts): marker, section order, host-owned literals, proof paths, refutes (`Sigra`, `forthcoming`, 2-arity authorize). Mirror `sigra_doc_contract_test.exs` ownership, not scale (~55).
- **D-121-19:** **Add** new test file to `mix.exs` `verify.doc_contract` alias (120 explicitly deferred; ADOPT-AUTH-03 is the gate).
- **D-121-20:** **`getting_started_saas_doc_contract_test.exs`:** **Remove** blanket `assert String.contains?(doc, router_block())`. **Add** neutrality asserts: `guides/integrations/phx-gen-auth.md`, refute Sigra-primary §5; **scope** Sigra router excerpt assert to optional subsection marker only (if fence retained).
- **D-121-21:** **Extend** `readme_doc_contract_test.exs` + `evaluating_threadline_doc_contract_test.exs` for four-lane string, phx guide path, neutrality substring. **Do not** duplicate matrix row asserts (stay in `upgrade_path_doc_contract_test.exs`).
- **D-121-22:** **Leave** `upgrade_path_doc_contract_test.exs` phx/matrix asserts from Phase 120 unchanged.

### 5. “Next reads” and upgrade-path intro consistency

- **D-121-23:** Add `guides/integrations/phx-gen-auth.md` to getting-started **Next reads** (today Sigra-only among integration guides).
- **D-121-24:** Fix `guides/upgrade-path.md` “Who this guide is for” intro if it still lists three structural lanes without phx — align intro with four-lane body (small copy, same PR).

### Ecosystem lessons applied (locked rationale, not re-litigated)

| Source | Take | Threadline application |
|--------|------|------------------------|
| Sentry / OTel / AppSignal | Generic plug/middleware seam; framework chapters separate | §5 generic plug; lanes in integration guides |
| django-auditlog / PaperTrail | Host sets actor before write | §6 contract + plug order |
| Audited / opaque blobs | Avoid YAML/opaque audit payloads | Keep SQL-native story; no vendor in hero snippet |
| Stripe/Twilio quickstarts | Proof env labeled, not production default | `<details>` sigra-reference block |
| Sigra Tier 1 vs Tier 2 (`.planning/research/sigra-integration-context.md`) | Recipe not mandatory adapter | Optional Sigra subsection; phx = host template |
| OSS DNA | Doc contracts, honest lanes, README as map | Four-lane README; `verify.doc_contract` registration |

### Claude's Discretion

- Exact HTML comment vs `###` heading for Sigra optional fence marker (must be stable for doc contract).
- Whether `<details>` vs `### Runnable curl (sigra-reference example app only)` if Hex/docs rendering is a concern.
- Minor prose in lane table cells; exact refute strings for §5 Sigra-primary narrative.
- `mount_block()` / `blog_block()` fixture asserts — keep if still valid after §5 rewrite; neutralize later if mount embeds Sigra-only assigns beyond operator bridge.
- Follow-up (not 121): add `sigra_doc_contract_test.exs` to `verify.doc_contract` for parity.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 121 goal, ADOPT-AUTH-01/02/03
- `.planning/REQUIREMENTS.md` — Adopter doc neutrality requirements
- `.planning/phases/119-phx-gen-auth-integration-guide-lane/119-CONTEXT.md` — phx guide shape, marker, no PhxGenAuth adapter
- `.planning/phases/120-root-auth-integration-proof/120-CONTEXT.md` — defer phx doc contract to 121; upgrade-path four-lane in 120
- `.planning/STATE.md` — current position

### Product / research
- `prompts/threadline-elixir-oss-dna.md` — doc contracts, README as map, auth-agnostic boundary
- `prompts/audit-lib-domain-model-reference.md` — ActorRef, host-owned auth
- `.planning/research/sigra-integration-context.md` — Tier 1 cookbook vs Tier 2 adapter; Sigra optional
- `prompts/prior-art/from-sigra/` — actor/session semantics (inform wording, not Sigra requirement)

### Shipped guides and contracts (edit targets)
- `guides/getting-started-saas.md` — §5, §6, Next reads
- `guides/integration-contracts.md` — §5 primary fence SSOT (`MyApp.Audit`)
- `guides/integrations/phx-gen-auth.md` — phx contract target
- `guides/integrations/sigra.md` — optional lane; router anchor for optional fence
- `guides/upgrade-path.md` — four-lane matrix SSOT
- `README.md`, `guides/evaluating-threadline.md` — discovery (ADOPT-AUTH-02)

### Test templates
- `test/threadline/integrations/sigra_doc_contract_test.exs` — structure reference, not scale
- `test/threadline/getting_started_saas_doc_contract_test.exs` — remove `router_block()` SSOT on whole guide
- `test/threadline/readme_doc_contract_test.exs`, `test/threadline/evaluating_threadline_doc_contract_test.exs`
- `test/threadline/upgrade_path_doc_contract_test.exs` — read only; do not duplicate matrix locks
- `mix.exs` — `verify.doc_contract` alias list

### Example app (reference only; do not mutate auth stack)
- `examples/threadline_phoenix/README.md` — §6 curl SSOT
- `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex` — `router-pipeline-actor-fn` anchor

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `GettingStartedFixtures` — optional Sigra fence via `router-pipeline-actor-fn` tag scoped to subsection only
- `upgrade_path_doc_contract_test.exs` — fourth lane already locked (120)
- `phx_gen_auth_integration_test.exs` — proof path for phx contract asserts

### Established Patterns
- Per-integration doc contract file under `test/threadline/integrations/`
- `integration-contracts.md` uses `MyApp.Audit`; phx guide uses `MyApp.AuditActor` — document rename freedom in §5
- Example app = `sigra-reference` runnable proof; phx = guide + root tests

### Integration Points
- Edit: `guides/getting-started-saas.md`, `README.md`, `guides/evaluating-threadline.md`, `guides/upgrade-path.md` (intro only)
- New: `test/threadline/integrations/phx_gen_auth_doc_contract_test.exs`
- Edit: getting_started / readme / evaluating doc contract tests; `mix.exs` alias

</code_context>

<specifics>
## Specific Ideas

- Mental model for adopters at 2am: **“I wire two callbacks after my auth plugs, then pick a lane doc.”**
- Cognitive order: **contract → lane choice → runnable reference** — not reference implementation → disclaimer.
- Evaluators: four lanes visible in README without opening upgrade-path; example app still discoverable under sigra-reference label.
- Do not duplicate phx cookbook into getting-started; link depth lives in `phx-gen-auth.md`.

</specifics>

<deferred>
## Deferred Ideas

- Add `sigra_doc_contract_test.exs` to `mix.exs` `verify.doc_contract` (parity with new phx contract)
- Neutralize `mount_block()` if still Sigra-coupled after §5 rewrite
- Harmonize `MyApp.Audit` vs `MyApp.AuditActor` naming across all guides (cosmetic; out of scope unless drift causes confusion)
- Pow / bearer reference lanes — REQUIREMENTS v2
- Swap Sigra out of example app — explicitly out of scope v1.26

</deferred>

---

*Phase: 121-adopter-doc-neutrality*
*Context gathered: 2026-05-27*
