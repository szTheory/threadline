# Phase 118: Pilot Prep (Optional) - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Lower friction for an external evaluator or pilot host without claiming maintainer STG attestation. Requirements: **PILOT-01**, **PILOT-02**.

**In scope:** Refresh `guides/adoption-pilot-backlog.md` verification pointers (entrypoints, not stale counts); add evaluator one-pager as `guides/evaluating-threadline.md` with README discovery; extend doc-contract tests. **No new library APIs.**

**Out of scope:** STG matrix attestation; compliance-pack / legal-hold / immutable-archive promises; new Evidence subjects; automated Hex publish; duplicating Evidence plane non-goals or upgrade-path lane tables in README.

</domain>

<decisions>
## Implementation Decisions

### D-118-01: Backlog evidence refresh (PILOT-01) — hybrid commands + contracts

- **D-118-01a:** **Remove hardcoded test counts** from `guides/adoption-pilot-backlog.md` (line 5 cites stale `136 tests`; tree is ~705 and drifts every phase). **Do not** replace with a new numeric total.
- **D-118-01b:** **Evidence pass paragraph** cites canonical **named entrypoints** only: `DB_PORT=5433 MIX_ENV=test mix ci.all` with ordered steps matching `mix.exs` — `verify.format` → `verify.credo` → compile strict → `verify.compile_no_optional` → `verify.test` → `verify.threadline` → `verify.example` → `verify.doc_contract`. Point to `CONTRIBUTING.md` for env and CI job table.
- **D-118-01c:** **Sync § In-repo parity (library CI)** (L126–134) to the same chain — today omits `verify.credo`, `verify.compile_no_optional`, `verify.example`. Prefer “see Evidence pass above” + CONTRIBUTING link if duplication risks drift.
- **D-118-01d:** **Bump maintainer evidence-pass date** to implementation date; keep PgBouncer / `verify-pgbouncer-topology` / `CI-PGBOUNCER-TOPOLOGY-CONTRACT` language unchanged (already correct).
- **D-118-01e:** **Rationale:** Ecto, Oban, Carbonite, Searchkick, Laravel Scout document **commands and prerequisites**, not ExUnit cardinality. Threadline OSS DNA §1: verification is product surface (`mix verify.*`). Stale counts violate adoption-pilot’s own STG rule (OK = reproducible pointer, not scorecard). Phase 117 pattern: doc change + contract change = one changeset.

### D-118-02: Evaluator one-pager placement (PILOT-02) — thin guide + README map

- **D-118-02a:** **Primary home:** new `guides/evaluating-threadline.md` (~80–120 lines). Matches Phase 117 split-guide architecture (Operator Surface, Evidence plane, upgrade-path) — depth off README, map on README.
- **D-118-02b:** **Do not** add a new README `##` band with full one-pager body (collides with Evidence plane / Operator Surface compact strips; README doc contracts resist wide verify matrices).
- **D-118-02c:** **Do not** expand Start here into a multi-paragraph Evaluating subsection (breaks persona routing list parity).
- **D-118-02d:** **README discovery:** Replace Start here **Evaluating** bullet — from “open HexDocs” to link `guides/evaluating-threadline.md` for in-repo proof, host boundaries, and `mix verify.*` ladder; keep HexDocs as secondary API reference. Add entry under **Documentation** list (after Getting started or before Adoption pilot backlog).
- **D-118-02e:** **ExDoc:** Add `guides/evaluating-threadline.md` to `mix.exs` `docs` extras list (same group as other adopter guides).
- **D-118-02f:** **Rationale:** Carbonite/Oban/Phoenix push depth to guides/HexDocs; Threadline already rejected `guides/evidence-plane.md` hub (117). Evaluator journey: README (10s) → evaluating guide (5 min) → getting-started / example (30–60 min).

### D-118-03: One-pager content & STG boundaries — link, don’t duplicate

**Guide sections (locked outline):**

1. **Who this is for** — technical evaluator / pilot host, not compliance procurement sign-off.
2. **What 0.6.0 packages** — reuse D-117-02g standard evaluator sentence + CHANGELOG `[0.6.0]` opener shape (Evidence plane, `Threadline.Audit.transaction/3`, operator/evidence surfaces since 0.5.0).
3. **Three layers (mental model)** — capture / semantics / exploration bullets → link `guides/how-threadline-works.md`.
4. **What maintainers prove in-repo (CI-class)** — trigger capture, semantics APIs, Evidence + proof vocabulary, `mix verify.*` / doc-contract gate, PgBouncer **transaction-mode class** via `verify-pgbouncer-topology`, reference app CI-class HTTP paths (getting-started + example tests). **No test counts as proof.**
5. **What integrators must prove (host-class)** — auth, tenancy, prod/staging topology, **your** HTTP + Oban audited paths, backups/PITR vs retention, redaction **policy review** → link `guides/production-checklist.md`, `CONTRIBUTING.md` § Host STG evidence.
6. **How to verify (evaluator ladder)** — numbered: `mix deps.get` → `mix ci.all` (full contributor gate) or targeted `mix verify.doc_contract` / `mix verify.example`; optional `examples/threadline_phoenix` Track A; cite **entrypoint names** only.
7. **Explicit non-claims** — not SIEM, not compliance platform, not legal hold, not immutable archive beyond host contract, not Threadline-owned RBAC/tenancy DSL, **not maintainer STG attestation** of third-party staging.
8. **Pilot next step** — two links to `guides/adoption-pilot-backlog.md` markers `STG-HOST-TOPOLOGY-TEMPLATE` and `STG-AUDITED-PATH-RUBRIC`; one sentence: copy templates into **your** repo; maintainers review modesty/redaction only (CONTRIBUTING).

**Must-have sentences (doc-contract lock candidates):**

- D-117-02g evaluator sentence (semver, 0.5.0 → 0.6.0, CHANGELOG + upgrade-path pointers).
- CI-class vs host-class labeling where readers could confuse `verify-pgbouncer-topology` / `mix verify.threadline` with **your** HTTP or job paths (from adoption-pilot normative rules).
- STG-01 boundary: host-owned staging depth when bar exceeds library CI harness.
- Integrator attestation: `CONTRIBUTING.md` — maintainers do not operate your staging stack.
- Doc truth gate: `mix verify.doc_contract` included in `mix ci.all`.
- If ExampleCloud or fiction cited: maintainer-walked / CI-scoped / not third-party endorsement (`ADOPT-EXAMPLE-DISCLAIMER` shape).

**Must-not:**

- Full STG rubric table bodies duplicated in evaluating guide or README.
- “Compliance-ready,” “immutable audit trail,” or maintainer STG certification language.
- Internal milestone labels (`v1.2x`) in evaluator prose (DOC-02 carry-forward).
- Lifting ExampleCloud matrix rows as Threadline-certified staging.

**Cross-ecosystem alignment:** Carbonite/django-auditlog split — library proves capture substrate + APIs in CI; host proves actor middleware, topology, job paths, compliance **policy**. Threadline’s CI-class / host-class vocabulary is stronger than peers — keep it prominent.

### D-118-04: Doc-contract enforcement — minimal-plus, two modules

- **D-118-04a:** **Extend** `test/threadline/adoption_pilot_doc_contract_test.exs` (PILOT-01):
  - `refute` stale `136 tests` and generic `~r/\(\d+ tests/` patterns.
  - `assert` `mix ci.all`, `mix verify.doc_contract`, and core verify steps in evidence pass / in-repo parity sections.
  - `assert` `CONTRIBUTING.md` pointer in evidence pass.
  - Keep existing version SSOT + upgrade-path link tests.
- **D-118-04b:** **New** `test/threadline/evaluating_threadline_doc_contract_test.exs` (PILOT-02):
  - Guide exists; contains D-117-02g sentence (or stable literals: `0.6.0`, `Audit.transaction/3`, `0.5.0`).
  - Contains verify ladder literals: `mix ci.all`, `mix verify.doc_contract`, `mix verify.example`.
  - Contains `host-owned` (or equivalent) and STG template marker strings / links to adoption-pilot-backlog.
  - `refute` maintainer STG attestation phrasing (`~r/maintainer.*STG.*(attest|certif)/i` scoped to guide).
  - Links outward to `how-threadline-works.md`, `upgrade-path.md`, `production-checklist.md` (planner picks minimum set).
- **D-118-04c:** **Extend** `test/threadline/readme_doc_contract_test.exs`:
  - `assert` README links `guides/evaluating-threadline.md`.
  - `assert` Start here or Documentation band references evaluating guide (not HexDocs-only Evaluating path).
- **D-118-04d:** **Wire** new test file into `mix.exs` `verify.doc_contract` alias list (117 lesson: alias drift breaks gates).
- **D-118-04e:** **Do not:** lock numeric test totals; snapshot full paragraphs; duplicate `ci.all` **ordering** asserts (owned by `ci_topology_contract_test.exs`); add `.planning/` to `verify.doc_contract`.
- **D-118-04f:** **Reframe PILOT-01 success criterion for planners:** “verification **entrypoints** match `mix.exs` / CONTRIBUTING” — not numeric totals.

### Cross-cutting principles (locked)

- **Verification is product surface** — evaluators memorize `mix verify.*`, not test counts (OSS DNA §1).
- **README-as-map** — evaluating guide composes Evidence plane / upgrade-path links instead of duplicating them (Phase 117).
- **Honest boundaries** — CI-class proof ≠ host STG sign-off; fictional ExampleCloud stays in adoption-pilot with disclaimer.
- **Least surprise evaluator flow:** clone → `mix ci.all` → optional example Track A → copy STG templates in **your** repo — not “maintainer certified my staging.”
- **Principle of least surprise / DX:** copy-paste commands from CONTRIBUTING; one canonical local gate; lane clarity via upgrade-path cross-links.

### Claude's Discretion

- Exact evaluating-guide section headings and line count within 80–120 target.
- Whether to add optional 3-column “where evidence lives” stub table (Environment | Class | Pointer) without filled host rows.
- CONTRIBUTING L29 mention of `verify.example` in `ci.all` prose (small DX win, optional same changeset).
- `ci_topology_contract_test` partial `verify.doc_contract` file list hygiene — separate commit unless alias list changes anyway.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` — Phase 118 goal, scope guard, success criteria
- `.planning/REQUIREMENTS.md` — PILOT-01, PILOT-02
- `.planning/phases/117-evidence-plane-doc-authority/117-CONTEXT.md` — README-as-map, split guides, D-117-02g evaluator sentence, doc-contract minimal-plus pattern

### Docs to edit
- `guides/adoption-pilot-backlog.md` — PILOT-01 evidence pass + in-repo parity
- `guides/evaluating-threadline.md` — **new** PILOT-02 one-pager (primary)
- `README.md` — Start here Evaluating bullet + Documentation list
- `mix.exs` — ExDoc extras + `verify.doc_contract` alias list
- `CONTRIBUTING.md` — Host STG evidence § (integrator attestation language)

### Product & OSS DNA
- `prompts/threadline-elixir-oss-dna.md` — verify entrypoints, doc contracts, golden path guide
- `prompts/audit-lib-domain-model-reference.md` — three layers, bounded contexts
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — capture vs action vs compliance; operator experience; peer footguns

### Peer patterns (research only — do not copy scope)
- Carbonite README — trigger capture + host metadata in same txn
- django-auditlog — middleware/`set_actor` host wiring honesty
- Ecto/Oban CONTRIBUTING — named gates, no test counts in adopter docs

### Existing contracts (extend, don’t duplicate)
- `test/threadline/adoption_pilot_doc_contract_test.exs`
- `test/threadline/readme_doc_contract_test.exs`
- `test/threadline/ci_topology_contract_test.exs` — `ci.all` order (do not re-assert in adoption_pilot)
- `test/threadline/stg_doc_contract_test.exs` — STG markers in adoption-pilot-backlog
- `test/threadline/semver_adopter_doc_contract_test.exs` — milestone label refutes

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MixProject.project()[:version]` — semver SSOT in adoption_pilot_doc_contract_test (reuse in evaluating guide contracts).
- `CiTopologyContractTest` — already locks `ci.all` composition, `verify.example`, PgBouncer job ids.
- `readme_doc_contract_test.exs` — README map contracts; extend for evaluating-guide link.
- `guides/adoption-pilot-backlog.md` — STG templates, CI-class vs host-class language, ExampleCloud disclaimer pattern.

### Established Patterns
- Phase 117: no new hub file; README strip → split guides; `refute guides/evidence-plane.md` in adopter paths.
- Doc change + contract change = one changeset; close with `mix verify.doc_contract`.
- Evaluator semver vocabulary: package version only in adopter paths (117).

### Integration Points
- `mix.exs` aliases `ci.all` and `verify.doc_contract` — prose must match L88–96 / L80–81.
- README Start here L18–19 — replace Evaluating bullet target.
- ExDoc extras list — add evaluating guide alongside adoption-pilot-backlog.

</code_context>

<specifics>
## Specific Ideas

- Evaluator journey mermaid (optional in guide): clone → `mix ci.all` → example Track A → STG templates in host repo — not maintainer STG attestation.
- Standard evaluator sentence from 117 is the 0.6.0 packaging anchor — do not invent alternate milestone framing.
- adoption-pilot Hex row may stay **Pending** until tag publish — evaluating guide says in-repo `@version` SSOT without implying maintainer ran evaluator’s staging.
- Searchkick/Laravel Scout lesson: adoption docs compress to **commands + prerequisites**, not library test cardinality.

</specifics>

<deferred>
## Deferred Ideas

- **README `## Evaluating Threadline 0.6.0` full band** — rejected; use thin guide + map link (README bloat / Evidence plane collision).
- **Hardcoded test counts anywhere in adopter paths** — rejected; rot every phase.
- **Duplicate STG rubric tables in evaluating guide** — link to adoption-pilot-backlog only.
- **CONTRIBUTING verify.example prose** — optional same phase, not blocking.
- **ci_topology verify.doc_contract file list completeness** — separate hygiene unless touching mix.exs anyway.

None — discussion stayed within phase scope beyond explicit deferrals above.

</deferred>

---

*Phase: 118-pilot-prep-optional*
*Context gathered: 2026-05-27*
