# Phase 124: Adopter Doc Finish - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Close v1.26 audit carry-forward and operator expectation gaps so first-hour and operator docs match shipped behavior — contract-locked via doc tests. Covers DOC-01 through DOC-05 only: §6 auth-neutral exercise path, ADOPT-AUTH strict literals, `:schemas` mount for row history, evidence host-write boundary, integration-contracts four-lane vocabulary aligned with upgrade-path. Does **not** add evidence auto-population, second reference app, Pow/bearer lane, example-app `:schemas` wiring (optional follow-up), or router `@moduledoc` code changes unless planner finds zero-cost parity.

</domain>

<decisions>
## Implementation Decisions

### §6 session/cookie staging (DOC-01)

- **D-01:** **IEx-first primary exercise + sigra HTTP fully collapsed (Option C + A).** Open §6 teaches the first audited write via `iex -S mix` with host-built `%AuditContext{}` + `Threadline.Audit.transaction/3`, producing `audit_transaction_id` and `demo-corr` for §8. Reject co-equal phx-gen-auth curl (no proof app; host-specific cookie fiction) and four lane-branched §6 subsections (upgrade-path owns lane depth).
- **D-02:** **Prose structure (locked):**
  - Keep open: `### Recommended path (0.6.0+)` (`Audit.transaction/3` API snippet)
  - Add open: `### Run your first audited write in IEx` — `ActorRef.new/2`, `%AuditContext{}`, transaction callback, explicit handoff: keep `audit_transaction_id` for step 8
  - Keep open: `### HTTP requests and host auth` — plug-order boundary (401/403 vs 500 missing actor); lane table with `phx-gen-auth-reference` first; `Threadline does not require Sigra`
  - Collapse **all** cookie/curl/DevTools prose into existing `<details>` (`Runnable HTTP curl — sigra-reference example app only`) — including `_threadline_phoenix_key`, `/users/log_in`, `-b` flag, bearer disclaimer
  - Remove open prose lines 183–187 (sigra cookie staging outside `<details>`)
- **D-03:** **Dual-contract layering (Phase 123 pattern):** getting-started = neutral IEx path; `examples/threadline_phoenix/README.md` Track A = HTTP session depth SSOT for sigra-reference; phx guide = Plug/`current_scope` only (no curl).
- **D-04:** **Doc contract evolution:** Remove open-doc assertions for `_threadline_phoenix_key` / bearer disclaimer from getting-started contract; those stay in `example_phoenix_readme_contract_test.exs`. Add IEx handoff literals + `demo-corr` alignment with §8 filters. Optional HTML marker `getting-started-sigra-http-staging-fence` inside `<details>` for ordering (mirrors §5 fence pattern).
- **D-05:** **Reject** implying IEx replaces §5 Plug wiring — IEx explicitly builds the context Plug would attach on HTTP.

### ADOPT-AUTH contract literals (DOC-02)

- **D-06:** **Dedicated test** `"getting-started §5 locks auth-neutral ADOPT-AUTH literals (DOC-02)"` in `getting_started_saas_doc_contract_test.exs` — do **not** fold into the 85-assert monolith (Phase 123 one-artifact-per-REQ pattern).
- **D-07:** **Exact literals to lock (presence):**
  - `Threadline does not own auth`
  - `Choose an auth lane when you need a full cookbook:`
  - `phx-gen-auth-reference`
  - `sigra-reference`
  - `Threadline does not require Sigra; do not use \`Threadline.Integrations.Sigra\``
  - `unless you adopt the optional sigra-reference lane.`
- **D-08:** **Ordering (`:binary.match`, CFG-02 B+ style):**
  - Neutrality sentence within §5 (`## 5.` < `Threadline does not require Sigra` < `## 6.`)
  - `phx-gen-auth-reference` < `sigra-reference` (discovery order)
  - `Threadline does not require Sigra` < `getting-started-sigra-reference-fence` < Sigra actor callback
  - Optional §5-scoped tighten for lane literals (avoid §6 lane table ambiguity)
- **D-09:** **Do not duplicate** README four-lane matrix (DOC-05), phx guide plug literals (`phx_gen_auth_doc_contract_test.exs`), or evaluator neutrality (`evaluating_threadline_doc_contract_test.exs`).

### `:schemas` mount documentation (DOC-03)

- **D-10:** **Canonical mount block** in `guides/operator-surface.md` §1-Minute Mount — add `schemas: %{"posts" => MyApp.Post, "users" => MyApp.Accounts.User}` with one sentence: keys are PostgreSQL `table_name` values from capture; required for row-history/as-of reification in transaction drill-down.
- **D-11:** **New subsection** `#### Row history reification (:schemas)` under Row History screen — SSOT for: purpose (table string → Ecto module for `history/3` + `as_of/4`); string keys preferred; atom keys optional; pair with `scope_query_fn` `%{surface: :row_history}`; API/IEx parity (schema module passed directly off-mount); route shorthand `/audit/rows/:table/:pk` vs actual `/audit/transactions/:id/history/:table/:record_id` slide-over; **two host prerequisites** for support-scoped row history: (1) `scope_query_fn`, (2) `:schemas`.
- **D-12:** **Failure UX (exact copy):** `Table 'X' is not mapped to an Ecto schema. Configure :schemas in the auth plug.` — error panel in slide-over; auth unaffected; fix = add map entry + redeploy. Note error text says "auth plug" for grep parity with UI; option lives on `threadline_operator_surface/2`.
- **D-13:** **getting-started §9:** one sentence + link to operator-surface reification subsection — no full map duplicate.
- **D-14:** **Doc contract:** assert `:schemas` in canonical mount + reification subsection heading in `operator_surface_doc_contract_test.exs` (extend existing file). Example app `:schemas` + router `@moduledoc` = **deferred** unless zero-scope creep in same PR.

### Evidence host-write expectation (DOC-04)

- **D-15:** **Canonical SSOT:** new `## Evidence write boundary (host-written)` in `guides/domain-reference.md` **immediately before** `## Evidence proof contract` — marker `EVIDENCE-HOST-WRITE-BOUNDARY`.
- **D-16:** **Claim shape (locked):**
  - Positive: host apps write via `Threadline.Evidence` `record_*` for six closed subjects; read surfaces (`Proof`, `mix threadline.evidence.show`, `/audit/evidence`) interpret rows already written
  - Negative: `Threadline.Retention`, `Threadline.Health`, export paths do **not** auto-create evidence rows
  - Precision: distinguish `threadline_retention_runs` (auto ops metadata for operator UI) from `threadline_evidence_records` (host attestations) — retention history ≠ evidence plane
  - Empty evidence view = no host attestation yet, not missing background job
- **D-17:** **Mental model fix:** rewrite `how-threadline-works.md` evidence paragraph (lines 31–33) from "Threadline may persist evidence" → host-written attestations + link to domain-reference anchor. One paragraph in `integration-contracts.md` evidence boundary (lines 151–154): writes are host-owned too. One sentence at `/audit/evidence` in `operator-surface.md`: viewer only.
- **D-18:** **Do not** create `guides/evidence-plane.md` hub (phantom hub refuted by semver contract). **Do not** over-promise compliance/SOC2 pipeline — align with v1.22 non-goals.
- **D-19:** **Doc contract:** extend `how_threadline_works_doc_contract_test.exs` + assert `EVIDENCE-HOST-WRITE-BOUNDARY` markers and `does not auto-populate` (or equivalent) in domain-reference scoped to evidence section.

### Integration-contracts four-lane vocabulary (DOC-05)

- **D-20:** **Compact lane section (Phase 122 D-09 pattern):** new `## Adoption lanes and integration seams` in `guides/integration-contracts.md` **after intro seam list (line ~16), before Request path** — enumerate four lane IDs in **canonical order** with one-line seam map each; cross-link `guides/upgrade-path.md` for matrix/claim types/proof/lifecycle. **Reject** full matrix duplicate.
- **D-21:** **Minimal inline touch-ups:** Plug section → "`capture-only` lane, stop after this section"; Integrations → "`sigra-reference` lane"; operator-surface → required for `phoenix-surface` + reference lanes.
- **D-22:** **Doc contract:** new test `"integration-contracts guide locks four-lane vocabulary and upgrade-path cross-link"` — section heading present; four lane IDs in canonical order via `:binary.match` indices; `guides/upgrade-path.md` cross-link; **refute** matrix table header `| Lane | Claim type |` in integration-contracts. Matrix rows stay locked only in `upgrade_path_doc_contract_test.exs`.
- **D-23:** **Optional hygiene (Claude discretion):** harmonize upgrade-path "How to tell which lane" prose order to canonical four-lane order if drift found — out of DOC-05 strict scope unless trivial.

### Cross-cutting architecture (coherent package)

- **D-24:** **SSOT map:** upgrade-path = lane matrix + proof; integration-contracts = seams + lane names; domain-reference = evidence write boundary; operator-surface = mount completeness (`:schemas`); getting-started = linear first-hour (IEx write, neutral §5/§6, defer HTTP depth).
- **D-25:** **Ecosystem alignment:** Oban/ExAudit install = configure then verify in IEx (not authenticated HTTP in library quickstart); ExAudit/django-simple-history = model/schema registration for reification (Threadline `:schemas` at mount); CloudTrail vs Config = auto ops facts vs host-chosen attestations (evidence plane); OSS DNA §2 = one verify artifact per REQ, links over duplicated tables.
- **D-26:** **Principle of least surprise:** phx-gen-auth adopters never see Sigra cookie names in open walkthrough; operator adopters learn `:schemas` before hitting row-history error panel; evaluators learn evidence is opt-in attestation, not auto-compliance population.

### Claude's Discretion

- Exact IEx snippet field names / sample Post attrs (within D-01 intent)
- Anchor slug for operator-surface reification link from getting-started §9
- Whether DOC-04 README gets one-liner or link-only (compact strip constraints)
- Exact wording polish within locked claim shapes
- `router.ex` `@moduledoc` `:schemas` option list if bundled without scope creep

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope & requirements
- `.planning/ROADMAP.md` — Phase 124 goal, success criteria, DOC-01–DOC-05
- `.planning/REQUIREMENTS.md` — DOC-01 through DOC-05 acceptance text
- `.planning/threads/2026-05-28-milestone-next-step-post-v1.26.md` — v1.26 carry-forward evidence table
- `.planning/milestones/v1.26-MILESTONE-AUDIT.md` — tech debt §6 cookie + ADOPT-AUTH soft gap
- `.planning/phases/122-release-distribution-truth/122-CONTEXT.md` — D-09 CHANGELOG minimal four-lane pattern
- `.planning/phases/123-first-hour-config/123-CONTEXT.md` — dual-contract + one-artifact-per-REQ (deferred items → 124)

### OSS DNA & product strategy
- `prompts/threadline-elixir-oss-dna.md` — §2 doc contracts, §4 golden path, links over duplicate tables
- `prompts/audit-lib-domain-model-reference.md` — Evidence entity, host-owned boundaries
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — ExAudit onboarding, operator layer from day one
- `CLAUDE.md` — `mix verify.doc_contract`, `mix ci.all`

### Primary edit targets (docs)
- `guides/getting-started-saas.md` — DOC-01 §6, DOC-02 §5 (already neutral), DOC-03 §9 one-liner
- `guides/operator-surface.md` — DOC-03 `:schemas` mount + reification subsection
- `guides/domain-reference.md` — DOC-04 evidence write boundary (before proof contract)
- `guides/how-threadline-works.md` — DOC-04 mental model fix
- `guides/integration-contracts.md` — DOC-04 write paragraph + DOC-05 lane section

### Doc contracts (extend)
- `test/threadline/getting_started_saas_doc_contract_test.exs` — DOC-01 IEx + DOC-02 ADOPT-AUTH test
- `test/threadline/operator_surface_doc_contract_test.exs` — DOC-03 `:schemas`
- `test/threadline/how_threadline_works_doc_contract_test.exs` — DOC-04 host-write mirror
- `test/threadline/integration_contracts_doc_contract_test.exs` — DOC-05 four-lane vocabulary

### Code truth (behavior anchors)
- `lib/threadline/operator_surface/auth.ex` — `:schemas` assign
- `lib/threadline/operator_surface/live/row_history_component.ex` — unmapped table error
- `lib/threadline/evidence.ex` — host-only write path
- `examples/threadline_phoenix/README.md` — sigra HTTP staging SSOT (unchanged ownership)

### Lane SSOT (read, do not duplicate matrix)
- `guides/upgrade-path.md` — four-lane matrix, claim types, proof anchors
- `test/threadline/upgrade_path_doc_contract_test.exs` — matrix locks
- `test/threadline/readme_doc_contract_test.exs` — README four-lane discovery

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `getting_started_saas_doc_contract_test.exs` — `:binary.match` ordering pattern (CFG-02, sigra fence)
- `operator_surface_doc_contract_test.exs` — mount literal locks (extend for `:schemas`)
- `integration_contracts_doc_contract_test.exs` — seam architecture locks (extend for lanes)
- `example_phoenix_readme_contract_test.exs` — sigra HTTP literals (retain as SSOT when removed from getting-started open assertions)
- `GettingStartedFixtures` — blog_block, mount_block helpers for contract tests

### Established Patterns
- Dual-contract: brief getting-started + depth in checklist/example README (Phase 123)
- HTML fence markers for optional-lane scoping (`getting-started-sigra-reference-fence`)
- Collapsed `<details>` for optional reference paths (§5 Sigra, §6 curl target)
- One verify artifact per REQ ID (Phase 123 D-16/D-20)
- Four-lane enumeration + upgrade-path link, no matrix duplicate (Phase 122 D-09)

### Integration Points
- §6 IEx `demo-corr` must align with §8 `correlation_id: "demo-corr"` filter
- Row history support claims in upgrade-path require both `scope_query_fn` and `:schemas` (doc clarification, not claim weakening)
- Evidence empty state on `/audit/evidence` reads correctly only after host-write boundary doc

</code_context>

<specifics>
## Specific Ideas

- **v1.26 audit closeout:** This phase hardens soft gaps flagged at milestone close — content on disk, contracts missing.
- **IEx-first §6:** Same shape as Oban `iex -S mix` + config check — library quickstarts verify API before HTTP auth staging.
- **Evidence framing:** "Config-style attestations the host chooses to record" (AWS Config analogue), not CloudTrail-style auto-ingestion.
- **`:schemas`:** Closest to django-simple-history admin registration — host declares which domain tables are reifiable in UI; capture already knows table names from triggers.
- **No user decision required:** Research-backed unified package; planner executes doc + contract edits per decisions above.

</specifics>

<deferred>
## Deferred Ideas

- Example app `:schemas` for help-desk tables (WALKTHROUGH row-history steps) — valuable but optional; not DOC-03 strict scope
- `router.ex` `@moduledoc` `:schemas` option — code/doc parity nice-to-have
- upgrade-path "How to tell which lane" detection prose order harmonization — trivial if touched
- Evidence auto-population from retention/health/export — explicit REQUIREMENTS out-of-scope; needs adopter signal
- Full multi-repo / dynamic-repo advanced guide — future if signal

</deferred>

---

*Phase: 124-adopter-doc-finish*
*Context gathered: 2026-05-28*
