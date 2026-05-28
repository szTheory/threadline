# Phase 126: Nyquist Validation Sign-off (122–124) - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 126 closes Nyquist validation drift on the three v1.27 delivery phases (122, 123, 124). Feature work is **done** — each target phase has `*-VERIFICATION.md` with `status: passed` and full requirement traceability. What remains is **proof-chain bookkeeping**: finalize each target's `*-VALIDATION.md` to honest current-tree state and flip `nyquist_compliant: true`.

Phase 126 does **NOT**:
- Redesign or re-ship DIST/CFG/DOC requirements
- Recreate `*-VERIFICATION.md` (already passed)
- Generate new feature tests unless gap analysis finds genuine MISSING coverage
- Sign off Phase 125 (out of roadmap scope for 126)
- Touch milestone authority surfaces (`PROJECT.md`, `STATE.md`, `MILESTONE-ARC.md`, `ROADMAP.md` shipped posture) — those were Phase 125
- Implement example app `:schemas` wiring (Phase 127)

Structural parallel: v1.22 Phases 100–102 (verification backfill), but **narrower** — VERIFICATION artifacts already exist; this phase is the VALIDATION finalization half only.

Three plans, three waves — one target phase per plan:
- **126-01** → Phase 122 (release distribution truth)
- **126-02** → Phase 123 (first-hour config)
- **126-03** → Phase 124 (adopter doc finish)

</domain>

<decisions>
## Implementation Decisions

### Scope boundary (VALIDATION refresh depth)

- **D-01:** Use **hybrid refresh** — not frontmatter-only, not full re-litigation. Anchor on existing `122/123/124-VERIFICATION.md` as authoritative closure evidence; rerun named verify bundles on **today's tree**; update each `*-VALIDATION.md` to reflect honest current-tree state.
- **D-02:** Per-task map rows flip from `⬜ pending` → `✅ green` (automated) or `✅ attested` (manual) where VERIFICATION + rerun evidence supports closure. Fix stale Wave 0 / `File Exists` cells (e.g. 122 `release_distribution_doc_contract_test.exs` now exists).
- **D-03:** Each finalized VALIDATION.md gains:
  - `## Commands Actually Used` (verbatim commands + exit codes/counts)
  - `**Retroactive backfill note:**` citing `{NN}-VERIFICATION.md` as superseding authority
  - Checked sign-off checklist items
  - Frontmatter: `status: finalized`, `nyquist_compliant: true`, `wave_0_complete: true`, `updated: <ISO date>`
- **D-04:** Reject frontmatter-only flip — OSS DNA forbids merge-theater `nyquist_compliant: true` without superseding rerun evidence (`prompts/threadline-elixir-oss-dna.md` §1).

### Execution shape

- **D-05:** **One Phase 126, three sequential plans** (126-01 → 126-02 → 126-03). Each plan = finalize-only slice for one target phase. Mirrors v1.22 backfill atomicity without mixing DIST/CFG/DOC domains in one commit.
- **D-06:** Each plan follows the same task shape:
  1. Gap audit — cross-ref VALIDATION per-task map ↔ VERIFICATION evidence ↔ runnable tests (expect mostly COVERED)
  2. Rerun gate commands (see D-10 through D-12)
  3. Finalize target `*-VALIDATION.md` per D-02/D-03
  4. Wave verify — record results in plan SUMMARY
- **D-07:** Do **not** use a unified batch plan updating all three VALIDATION files in one wave — wrong granularity for Nyquist proof chains in an audit platform; ROADMAP success criteria enumerate three distinct sign-offs.
- **D-08:** `/gsd-validate-phase {122|123|124}` workflow may be invoked per target during execution, but GSD tracking lives in Phase 126 plans/SUMMARYs for milestone audit trail.

### Manual-only verifications disposition

- **D-09:** **Attested manual-complete** — keep Manual-Only rows where CI cannot prove external facts; mark complete with evidence pointer, do not relabel as automated.
- **D-10 (Phase 122 — DIST-01 hex publish):**
  - Keep Manual-Only rows for hex.pm publish and maintainer attestation
  - Flip per-task rows `122-02-01`, `122-03-01` to `✅ attested`
  - Evidence pointer: `122-VERIFICATION.md` (tag `v0.6.0`, workflow run `26583473336`, hex.info excerpt); adoption-pilot OK row
  - Evidence tier: **`inferred_posture`** (maintainer-attested external registry fact, corroborated by release-event automation — not re-proved every PR)
  - **Do not** add per-PR hex.pm polling (Phase 122 D-04)
  - **Claude's discretion:** optional no-network doc-contract proxy asserting `122-VERIFICATION.md` structure (contains `v0.6.0`, workflow reference) — not required for sign-off
- **D-11 (Phase 123 — CFG-01 ExDoc anchor):**
  - Close manual row as **proven via deterministic proxy** — heading `### Configure Threadline` + cross-link `getting-started-saas.md#configure-threadline` are contract-locked in doc-contract tests; ExDoc slug is deterministic from locked heading
  - Remove ExDoc manual row or strike through with note: "Closed — proven via doc-contract proxy"
  - Evidence tier: **`proven`** (deterministic derivation over owned artifacts)
  - **Do not** require `mix docs` HTML grep in PR CI for Nyquist sign-off
- **D-12 (Phase 124 — prose spot-reads):**
  - Keep manual-only rows for §6 IEx readability and evidence boundary compliance tone
  - Mark `✅ attested` citing `124-VERIFICATION.md` requirement traceability (DOC-01–05 all ✅)

### Green gate before sign-off

- **D-13:** **Tiered gate policy** — per-phase targeted commands + `mix verify.doc_contract` per phase; **one** `mix ci.all` at Phase 126 session close (after all three signed). Reject targeted-only sign-off; reject triple `ci.all`.
- **D-14 (Phase 122 sign-off commands):**
  ```
  mix test test/threadline/release_distribution_doc_contract_test.exs
  grep -q phx-gen-auth-reference CHANGELOG.md
  mix test test/threadline/adoption_pilot_doc_contract_test.exs
  mix test test/threadline/evaluating_threadline_doc_contract_test.exs
  mix verify.doc_contract
  mix hex.info threadline   # manual attestation corroboration only
  ```
- **D-15 (Phase 123 sign-off commands):**
  ```
  mix test test/threadline/getting_started_saas_doc_contract_test.exs
  mix test test/threadline/production_checklist_doc_contract_test.exs
  mix verify.doc_contract
  ```
- **D-16 (Phase 124 sign-off commands):**
  ```
  mix test test/threadline/getting_started_saas_doc_contract_test.exs
  mix test test/threadline/operator_surface_doc_contract_test.exs
  mix test test/threadline/how_threadline_works_doc_contract_test.exs
  mix test test/threadline/integration_contracts_doc_contract_test.exs
  mix verify.doc_contract
  ```
- **D-17 (Phase 126 session close — once, after 126-03):**
  ```
  mix ci.all
  ```
- **D-18:** Phase 125 green is **not** sufficient without rerun — re-run gates on current tree before flipping frontmatter. Record timestamp + exit codes in each VALIDATION's `## Commands Actually Used`.
- **D-19:** Named verify entrypoints cited verbatim in artifacts — no ad-hoc test lists without also naming the alias (`mix verify.doc_contract`, `mix ci.all`).

### Phase 126 scope guardrails

- **D-20:** Touch only target phase directories (`122-*`, `123-*`, `124-*` VALIDATION.md) plus Phase 126 own artifacts (`126-*`). No edits to `lib/`, `test/`, `guides/`, `examples/` unless gap analysis finds genuine MISSING automated coverage (unlikely given passed VERIFICATION).
- **D-21:** Do not pre-close milestone — defer `v1.27-MILESTONE-AUDIT.md` Nyquist table refresh and `/gsd-complete-milestone v1.27` until Phase 127 completes (ROADMAP: 126–127 before complete-milestone).
- **D-22:** If gap analysis finds MISSING (not just stale bookkeeping), escalate only the smallest literal repair — do not widen into feature work or alias-topology fixes outside 122–124 ownership.

### Claude's Discretion

- Whether to add optional `122-VERIFICATION.md` structure proxy test (D-10)
- Exact wording of retroactive backfill notes and Validation Audit sections
- Optional 126-04 plan for `126-VERIFICATION.md` + milestone audit Nyquist table refresh (not required by ROADMAP success criteria)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` § Phase 126 — goal, depends-on, success criteria
- `.planning/REQUIREMENTS.md` § Post-shipment gap closure — Phase 126 maps to Nyquist debt on 122–124
- `.planning/milestones/v1.27-MILESTONE-AUDIT.md` — current Nyquist partial status, per-phase tech debt items

### Target phase closure evidence (authoritative)
- `.planning/phases/122-release-distribution-truth/122-VERIFICATION.md` — DIST-01/02/03 passed
- `.planning/phases/123-first-hour-config/123-VERIFICATION.md` — CFG-01/02/03 passed
- `.planning/phases/124-adopter-doc-finish/124-VERIFICATION.md` — DOC-01–05 passed
- `.planning/phases/122-release-distribution-truth/122-VALIDATION.md` — draft to finalize
- `.planning/phases/123-first-hour-config/123-VALIDATION.md` — draft to finalize
- `.planning/phases/124-adopter-doc-finish/124-VALIDATION.md` — draft to finalize

### Backfill pattern precedents
- `.planning/milestones/v1.22-phases/101-phase-96-verification-backfill/101-CONTEXT.md` — verification backfill shape
- `.planning/milestones/v1.22-phases/102-phase-98-verification-backfill/102-VALIDATION.md` — retroactive note + Commands Actually Used pattern
- `.planning/milestones/v1.22-phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-VALIDATION.md` — finalized Nyquist artifact shape
- `.planning/RETROSPECTIVE.md` § v1.22 — verification backfill phase shape lesson

### OSS DNA and verify conventions
- `prompts/threadline-elixir-oss-dna.md` — named verify entrypoints, Nyquist debt policy, three-source traceability
- `prompts/audit-lib-domain-model-reference.md` — proven/inferred/unsupported vocabulary for attestation tiers
- `CLAUDE.md` — `mix verify.*` / `mix ci.all` canonical entrypoints

### Nyquist workflow
- `$HOME/.cursor/get-shit-done/workflows/validate-phase.md` — `/gsd-validate-phase` process (gap audit, VALIDATION finalize)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- All doc-contract test files referenced in 122–124 VALIDATION maps exist on current tree
- `mix verify.doc_contract` alias covers all 17 contract files (~97 tests)
- `mix ci.all` chains format → credo → compile → test → threadline → example → doc_contract
- Phase 125 greened both aliases on reconciled authority surfaces

### Established Patterns
- v1.22 backfill phases (100–102): two-plan shape per target (re-verify → finalize); Phase 126 skips re-verify plans because VERIFICATION already passed
- Phase 103 closeout: named proof bundle as authority, `## Commands Actually Used` with exit codes
- Phase 122 D-04: registry publish = release-event automation + maintainer attestation, not PR polling

### Integration Points
- Phase 126 depends on Phase 125 complete (authority surfaces reconciled)
- Phase 127 (`:schemas` example wiring) runs after or parallel with 126; both block `/gsd-complete-milestone v1.27`
- REQUIREMENTS.md line 92 traces Nyquist debt explicitly to Phase 126

</code_context>

<specifics>
## Specific Ideas

- "Named bundle, not prose" — Phase 103 precedent: rerun evidence beats summary frontmatter
- "Honest defaults" — manual-only rows stay visible for 122 hex publish; auditors see where CI stops
- Three-tier proof vocabulary applies to attestations: 122 = inferred_posture, 123 ExDoc = proven via proxy
- Ecosystem lesson (Ecto/Phoenix/Oban/Hex): verification is runnable and named; CHANGELOG/version gates are CI contracts, not maintainer memory
- Footgun to avoid: v1.27 audit showed targeted 43-test band green while full `mix verify.doc_contract` failed — always include doc_contract alias at sign-off

</specifics>

<deferred>
## Deferred Ideas

- Phase 125 Nyquist sign-off — separate phase, not in 126 scope
- Example app `:schemas` wiring — Phase 127
- Milestone complete + archive — after Phase 127
- Optional `122-VERIFICATION.md` structure proxy test — Claude's discretion, not blocking
- `v1.27-MILESTONE-AUDIT.md` Nyquist table refresh — optional 126-04 or defer to milestone closeout
- Per-PR hex.pm API polling — explicitly rejected (Phase 122 D-04)
- `mix docs` HTML anchor CI — rejected for PR path; heading+link proxy sufficient

</deferred>

---

*Phase: 126-nyquist-validation-signoff-122-124*
*Context gathered: 2026-05-28*
