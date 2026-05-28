# Phase 124: Adopter Doc Finish — Research

**Researched:** 2026-05-28  
**Phase:** 124-adopter-doc-finish  
**Requirements:** DOC-01, DOC-02, DOC-03, DOC-04, DOC-05  
**Context SSOT:** `124-CONTEXT.md` (user decisions D-01–D-26)

---

<user_constraints>

## Phase Boundary

Close v1.26 audit carry-forward and operator expectation gaps so first-hour and operator docs match shipped behavior — contract-locked via doc tests. Covers DOC-01 through DOC-05 only: §6 auth-neutral exercise path, ADOPT-AUTH strict literals, `:schemas` mount for row history, evidence host-write boundary, integration-contracts four-lane vocabulary aligned with upgrade-path. Does **not** add evidence auto-population, second reference app, Pow/bearer lane, example-app `:schemas` wiring (optional follow-up), or router `@moduledoc` code changes unless planner finds zero-cost parity.

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

</user_constraints>

---

## 1. Executive summary

Phase 124 is a **docs-only + doc-contract** closeout for v1.26 audit soft gaps (INFO-2 §6 cookie prose, ADOPT-AUTH contract literals) and three expectation gaps (`:schemas`, evidence host-write, integration-contracts lane vocabulary). **Prose for §5 ADOPT-AUTH is largely on disk**; contracts and §6 structure are the main gaps.

| Wave | Plan | Delivers |
|------|------|----------|
| **Wave 1** | `124-01-PLAN` | DOC-01 §6 IEx-first + collapsed HTTP; DOC-02 dedicated ADOPT-AUTH test; monolith contract cleanup (`getting-started-saas.md` + `getting_started_saas_doc_contract_test.exs`) |
| **Wave 1** (parallel) | `124-02-PLAN` | DOC-03 `:schemas` mount + reification subsection + §9 one-liner (`operator-surface.md`, `getting-started-saas.md` §9, `operator_surface_doc_contract_test.exs`) |
| **Wave 2** | `124-03-PLAN` | DOC-04 evidence boundary across four guides + contracts; DOC-05 integration-contracts lane section + contract (`domain-reference.md`, `how-threadline-works.md`, `integration-contracts.md`, `how_threadline_works_doc_contract_test.exs`, `integration_contracts_doc_contract_test.exs`) |

**Planning takeaway:** No library code changes. Highest coupling is **124-01** (same guide + same test file for DOC-01/02). **124-03** should run after or in parallel with 124-02 only if files do not overlap — 124-03 touches `getting-started` only if DOC-04 README one-liner is chosen (D-17 discretion: link-only preferred).

---

## 2. Current state audit

### 2.1 `guides/getting-started-saas.md`

| Area | On disk today | Phase 124 delta |
|------|---------------|-----------------|
| **§5 (DOC-02 prose)** | Has `Threadline does not own auth`, lane list with `phx-gen-auth-reference` / `sigra-reference`, neutrality sentence, sigra fence | **Contract only** — prose satisfies D-07; add dedicated test + ordering |
| **§6 (DOC-01)** | `### Recommended path` present; `### Authenticate before the audited API call` (not locked `### HTTP requests and host auth`); curl in `<details>` but **open prose 183–187** repeats cookie staging; **no IEx exercise** | Add IEx subsection; rename/restructure HTTP subsection; delete 183–187; move all cookie prose into `<details>`; optional `getting-started-sigra-http-staging-fence` |
| **§6 lane table** | Uses `phx.gen.auth` / `Sigra` labels, not canonical lane IDs | Align to `phx-gen-auth-reference` first per D-02 |
| **§8** | `correlation_id: "demo-corr"` filter present | §6 IEx must set same `demo-corr` for handoff |
| **§9 (DOC-03)** | Mount block without `:schemas`; no link to reification | One sentence + link only (D-13) |

**Contract conflict (must fix in 124-01):** Monolith test `"quickstart guide locks the adopter walkthrough"` still asserts open-doc presence of `_threadline_phoenix_key` and `does not ship API bearer` (lines 67–69). That contradicts D-04 — literals belong in `example_phoenix_readme_contract_test.exs` only (already locked there at lines 128–129).

### 2.2 `guides/operator-surface.md` (DOC-03, DOC-04 touch)

| Area | On disk today | Phase 124 delta |
|------|---------------|-----------------|
| **1-Minute Mount** | `threadline_operator_surface` with `repo:` only — **no `:schemas`** | Add canonical map + one-sentence `table_name` keys (D-10) |
| **Row History** (`### Row History / As-of Sub-view`) | Describes route `/audit/rows/:table/:pk`; mentions `scope_query_fn`; **no `:schemas`**, no failure UX | New `#### Row history reification (:schemas)` (D-11–D-12) |
| **`/audit/evidence`** | Gates via `evidence_authorize_fn`; "viewer" framing partial | One sentence: viewer only, host writes via `Threadline.Evidence` (D-17) |

**Code truth:** Actual slide-over route is `live("/transactions/:id/history/:table/:record_id", ...)` in `lib/threadline/operator_surface/router.ex:106` — doc must document shorthand vs drill-down path (D-11).

### 2.3 `guides/domain-reference.md` (DOC-04)

| Area | On disk today | Phase 124 delta |
|------|---------------|-----------------|
| **Evidence** | Jumps from `## Export` to `## Evidence proof contract` (line 75) — **no write boundary** | Insert `## Evidence write boundary (host-written)` + `<!-- EVIDENCE-HOST-WRITE-BOUNDARY -->` before proof contract (D-15) |
| **Retention §** | Describes `threadline_retention_runs` purge semantics | Use as contrast anchor in boundary section (retention ops ≠ evidence attestations) |

### 2.4 `guides/how-threadline-works.md` (DOC-04)

Lines 31–33 still say **"Threadline may persist evidence"** — contradicts shipped host-write API. Contract file has no evidence host-write assertions today; add mirror test per D-19.

### 2.5 `guides/integration-contracts.md` (DOC-04 + DOC-05)

| Area | On disk today | Phase 124 delta |
|------|---------------|-----------------|
| **Intro** | Four seam bullets (lines 7–13); **no lane section** | Insert `## Adoption lanes and integration seams` after line ~16 (D-20) |
| **Plug §** | "Capture-only adopters can stop here" — good seed for D-21 touch-up | Add explicit `` `capture-only` `` lane label |
| **Evidence (151–154)** | "Threadline may persist evidence" | Host-owned writes paragraph (D-17) |
| **Integrations §** | Sigra model — no `sigra-reference` lane ID in heading prose | Minimal lane ID touch-up (D-21) |

**Lane SSOT:** `guides/upgrade-path.md` matrix + `upgrade_path_doc_contract_test.exs` already lock four lanes. **Drift (optional D-23):** "How to tell which lane" subsection order is `capture-only` → `phoenix-surface` → `sigra-reference` → `phx-gen-auth-reference` (lines 19–25), not canonical `phx-gen-auth-reference` before `sigra-reference`.

### 2.6 Doc contract tests (extend only — no new files required)

| File | In `mix verify.doc_contract`? | Gap |
|------|------------------------------|-----|
| `getting_started_saas_doc_contract_test.exs` | Yes | Remove open sigra HTTP asserts; add DOC-02 dedicated test; add DOC-01 IEx/`demo-corr` asserts |
| `operator_surface_doc_contract_test.exs` | Yes | No `:schemas` or reification heading locks |
| `how_threadline_works_doc_contract_test.exs` | Yes | No host-write / boundary marker |
| `integration_contracts_doc_contract_test.exs` | Yes | No four-lane section test; has `capture-only` in audited-write test only |
| `example_phoenix_readme_contract_test.exs` | Yes | **Retain** sigra HTTP SSOT — do not weaken |

---

## 3. Code truth anchors

### 3.1 `:schemas` — `lib/threadline/operator_surface/auth.ex`

```elixir
schemas = Keyword.get(opts, :schemas, %{})
# ...
|> Phoenix.Component.assign(:threadline_schemas, schemas)
```

Option is read on `on_mount` from `threadline_operator_surface/2` opts (D-12: UI copy says "auth plug" for historical grep parity).

### 3.2 Row history error — `row_history_component.ex:40`

Exact string (parameterized table name):

`Table '#{assigns.table}' is not mapped to an Ecto schema. Configure :schemas in the auth plug.`

Doc must use representative `Table 'X'` or match pattern for contract grep.

### 3.3 Evidence host write — `lib/threadline/evidence.ex`

Six public `record_*` entrypoints (closed subjects):

- `record_redaction_policy/3`
- `record_trigger_coverage/3`
- `record_retention_run/3`
- `record_retention_policy/3`
- `record_export_delivery/3`
- `record_support_scope_posture/3`

No `Threadline.Retention` / `Threadline.Health` / export modules call these — supports negative claim in D-16. `threadline_retention_runs` is separate governance metadata (`lib/threadline/governance/retention_run.ex`).

### 3.4 Dual-contract SSOT (unchanged ownership)

- **Sigra HTTP depth:** `examples/threadline_phoenix/README.md` + `example_phoenix_readme_contract_test.exs`
- **phx.gen.auth Plug recipe:** `guides/integrations/phx-gen-auth.md` + `phx_gen_auth_doc_contract_test.exs`
- **Four-lane matrix:** `guides/upgrade-path.md` + `upgrade_path_doc_contract_test.exs` + `readme_doc_contract_test.exs`

---

## 4. Phase 123 patterns to reuse

| Pattern | Phase 123 example | Phase 124 application |
|---------|-------------------|----------------------|
| **Dual-contract** | getting-started brief + checklist depth | getting-started IEx + example README HTTP |
| **One artifact per REQ** | `"getting-started documents threadline ecto_repos..."` separate from monolith | `"getting-started §5 locks auth-neutral ADOPT-AUTH literals (DOC-02)"` separate test (D-06) |
| **`:binary.match` ordering** | literal before `## 7`, before sigra fence | §5 neutrality before `## 6`; lane ID order; optional §6 IEx before HTTP subsection |
| **HTML fence markers** | `getting-started-sigra-reference-fence` | `getting-started-sigra-http-staging-fence` inside §6 `<details>` (D-04) |
| **Collapsed `<details>`** | §5 Sigra optional block | §6 all cookie/curl prose inside `<details>` only (D-02) |
| **Dedicated checklist contract file** | `production_checklist_doc_contract_test.exs` | No new files needed — extend four existing contract modules |
| **Verification cite** | `mix verify.doc_contract` in PLAN | Same — wave closeout runs full alias |

---

## 5. Implementation approach by requirement

### DOC-01 — §6 IEx-first

**Insert after `### Recommended path`:** `### Run your first audited write in IEx` with:

- `iex -S mix` preamble
- `ActorRef.new(:user, "you@example.com")` (exact attrs per D-01 discretion)
- `%Threadline.Semantics.AuditContext{actor_ref: ..., correlation_id: "demo-corr", ...}`
- `Threadline.Audit.transaction/3` returning `audit_transaction_id` for §8
- Explicit note: builds context Plug would attach on HTTP (D-05)

**Replace `### Authenticate before...` with `### HTTP requests and host auth`:** plug-order table; lane IDs not display names.

**Delete lines 183–187** (cookie staging outside details).

**Contract additions:** assert IEx subsection title; `demo-corr` in §6 before §8; **refute** open `_threadline_phoenix_key` in monolith; assert sigra literals only after optional fence marker if marker added.

### DOC-02 — ADOPT-AUTH contract

Prose already contains D-07 literals in §5 (verified grep). **New test only:**

```elixir
test "getting-started §5 locks auth-neutral ADOPT-AUTH literals (DOC-02)" do
  doc = read_rel!(@guide_path)
  # presence asserts for each literal
  # :binary.match ordering per D-08
end
```

Scope assertions between `## 5.` and `## 6.` for lane literals to avoid §6 table ambiguity (D-08 optional tighten).

### DOC-03 — `:schemas`

**Mount block update** (admin recipe ~lines 46–50 and support recipe ~76–80): add `schemas: %{"posts" => MyApp.Post, ...}`.

**New subsection** under `### Row History / As-of Sub-view` (~line 172).

**getting-started §9:** e.g. "Row-history slide-overs need `:schemas` on the mount — see [Row history reification](operator-surface.md#...)."

**Contract:** new test or extend existing — assert `schemas:` in mount snippet and `#### Row history reification (:schemas)` heading; assert failure message substring `Configure :schemas in the auth plug`.

### DOC-04 — Evidence host-write

**domain-reference:** New section ~15–25 lines with marker comment; six `record_*` names; negative list (Retention, Health, export); `threadline_retention_runs` vs `threadline_evidence_records` distinction.

**how-threadline-works:** Replace lines 31–33; link to `domain-reference.md#evidence-write-boundary-host-written` (slug from heading).

**integration-contracts:** Replace 151–154 "may persist" with host-write framing.

**operator-surface:** One sentence under `/audit/evidence` block (~127–131).

**Contracts:**

- `how_threadline_works_doc_contract_test.exs`: refute `Threadline may persist evidence`; assert host-written framing + link to domain-reference
- `domain-reference`: scoped test via section slice between `EVIDENCE-HOST-WRITE-BOUNDARY` and `## Evidence proof contract` for `does not auto-populate` (or equivalent locked phrase)

### DOC-05 — Four-lane vocabulary

**New section** after intro (before `## Request path`):

```markdown
## Adoption lanes and integration seams

Adopters self-identify on one of four lanes (canonical order):

1. `capture-only` — ...
2. `phoenix-surface` — ...
3. `phx-gen-auth-reference` — ...
4. `sigra-reference` — ...

Lane matrix, claim types, and proof anchors: [`guides/upgrade-path.md`](upgrade-path.md).
```

**D-21 inline:** one sentence each in Plug / Integrations / operator-surface sections.

**New contract test:**

- Heading present
- `:binary.match` indices for four lane strings in canonical order
- `guides/upgrade-path.md` link
- `refute String.contains?(guide, "| Lane | Claim type |")`

---

## 6. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| Monolith test removal breaks CI before prose moves sigra literals | Edit doc + test in same commit; run `example_phoenix_readme_contract_test.exs` |
| §6 IEx snippet uses wrong module names | Copy from `examples/threadline_phoenix` blog transaction or domain-reference ActorRef patterns |
| `:schemas` doc says "auth plug" but option is on mount macro | D-12 explicitly allows UI copy parity; document option on `threadline_operator_surface/2` in same subsection |
| Evidence boundary overclaims auto-write from retention UI | D-16 precision on `threadline_retention_runs` vs evidence records |
| integration-contracts matrix duplicate | D-22 refute table header; link-only to upgrade-path |
| Phantom `guides/evidence-plane.md` | D-18; `semver_adopter_doc_contract_test.exs` already refutes across adopter band |

---

## 7. Validation Architecture (Nyquist)

| Requirement | Automated layer | Human layer |
|-------------|-----------------|-------------|
| **DOC-01** | getting-started contract: IEx subsection, `demo-corr` handoff, refute open cookie literals; optional fence ordering | Spot-read §6 — phx adopters see no cookie names in open prose |
| **DOC-02** | Dedicated `"getting-started §5 locks auth-neutral ADOPT-AUTH literals (DOC-02)"` test with `:binary.match` | — |
| **DOC-03** | `operator_surface_doc_contract_test.exs` mount `:schemas` + reification heading + error copy | Optional: mount example app later (deferred) |
| **DOC-04** | `how_threadline_works` + domain-reference scoped asserts; refute old "may persist" in mental model guide | Read boundary section for compliance tone (v1.22 non-goals) |
| **DOC-05** | New integration-contracts test: four lanes order + upgrade-path link + refute matrix | — |

**Nyquist:** Fully machine-verifiable — no maintainer attestation. Wave 0 not required.

**Per-plan commands:**

```bash
# 124-01
mix test test/threadline/getting_started_saas_doc_contract_test.exs
mix test test/threadline/example_phoenix_readme_contract_test.exs

# 124-02
mix test test/threadline/operator_surface_doc_contract_test.exs

# 124-03
mix test test/threadline/how_threadline_works_doc_contract_test.exs
mix test test/threadline/integration_contracts_doc_contract_test.exs

# Wave closeout
mix verify.doc_contract
mix ci.all
```

`mix verify.doc_contract` runs 16 contract files (see `mix.exs` alias ~line 80–81); Phase 124 extends four, does not add alias entries unless a new file is created (not required per CONTEXT).

---

<phase_requirements>

| ID | Acceptance (REQUIREMENTS.md) | Research finding | Primary artifacts | Contract artifact |
|----|------------------------------|------------------|-------------------|-----------------|
| **DOC-01** | §6 auth-neutral; Sigra curl not only path | **Gap:** no IEx path; open cookie prose 183–187; monolith still requires open sigra literals | `guides/getting-started-saas.md` §6 | Extend `getting_started_saas_doc_contract_test.exs` (IEx + remove open sigra asserts) |
| **DOC-02** | Strict ADOPT-AUTH literals in doc contract | **Gap:** prose on disk; **no dedicated test** (v1.26 audit soft) | `guides/getting-started-saas.md` §5 (verify only) | New test `"getting-started §5 locks auth-neutral ADOPT-AUTH literals (DOC-02)"` |
| **DOC-03** | operator-surface documents `:schemas` for row history | **Gap:** mount lacks `:schemas`; no reification subsection; §9 silent | `guides/operator-surface.md`, §9 one-liner | `operator_surface_doc_contract_test.exs` |
| **DOC-04** | Evidence host-written; no auto-populate from ops | **Gap:** wrong mental model in how-threadline-works + integration-contracts; no domain boundary | `domain-reference.md`, `how-threadline-works.md`, `integration-contracts.md`, `operator-surface.md` | `how_threadline_works_doc_contract_test.exs` + domain-reference scoped asserts |
| **DOC-05** | integration-contracts four-lane vocabulary matches upgrade-path | **Gap:** no lane section; inline `capture-only` only | `integration-contracts.md` | New test in `integration_contracts_doc_contract_test.exs` |

</phase_requirements>

---

## RESEARCH COMPLETE

**Confidence:** High — docs-only phase with locked CONTEXT, verified code anchors, and clear v1.26 audit traceability.

**Key findings:**

1. **§5 ADOPT-AUTH prose is done; contracts are not** — Phase 124 DOC-02 is primarily a new dedicated test + ordering, not a rewrite of §5.
2. **§6 is the largest prose change** — IEx-first exercise, delete open cookie lines 183–187, and **remove** monolith open assertions for sigra HTTP (dual-contract to example README).
3. **`:schemas` is implemented in code but undocumented** — operator-surface mount and row-history error message are ready-made doc anchors.
4. **Evidence "may persist" copy is stale** in two guides — contradicts six `Threadline.Evidence.record_*` APIs; domain-reference needs SSOT boundary section before proof contract.
5. **integration-contracts lacks lane enumeration** — upgrade-path already SSOT; Phase 122 CHANGELOG pattern applies (compact list + link, refute matrix duplicate).

**Recommended plan wave structure:**

- **124-01** (Wave 1): DOC-01 + DOC-02 — `getting-started-saas.md` + `getting_started_saas_doc_contract_test.exs`
- **124-02** (Wave 1, parallel): DOC-03 — `operator-surface.md` + §9 sentence + `operator_surface_doc_contract_test.exs`
- **124-03** (Wave 2): DOC-04 + DOC-05 — three/four guides + `how_threadline_works_doc_contract_test.exs` + `integration_contracts_doc_contract_test.exs` (+ optional domain-reference asserts in how test or new scoped test in same file)

**Next step:** `/gsd-plan-phase 124`
