# Phase 115: Narrative Doc Sync - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Align adopter-facing narrative docs so **`Threadline.Audit.transaction/3`** is the recommended audited write path — centered in `guides/how-threadline-works.md`, consistent with README and `guides/getting-started-saas.md` cross-links, and locked by doc-contract tests (NARR-01, NARR-02, NARR-03).

Scope guard (ROADMAP): `guides/how-threadline-works.md`, README/getting-started cross-links, doc-contract tests. **No example app code changes** unless a snippet must match. No `integration-contracts.md` escape-hatch rewrite, no `domain-reference.md` incident prose, no `upgrade-path.md` semver section (Phase 117).

Requirements: NARR-01, NARR-02, NARR-03.

</domain>

<decisions>
## Implementation Decisions

### D-115-01: Blessed-path prominence in how-threadline-works (Gray Area 1)

- **D-115-01a:** **Surgical retarget, not full rewrite** — edit formula, flow steps, one code block, JTBD Job 2 sentence, and Public API write-side (~30–40 lines). **Do not** restructure Architecture layers, JTBD Jobs 1/3/4, Diminishing Returns, or Natural next work.
- **D-115-01b:** Pattern = **Carbonite / django-auditlog doc discipline**: one blessed write face in the first screenful; primitives and escape hatches later via cross-link (matches Ecto `Multi` first, Oban `insert` first, PaperTrail macro-first).
- **D-115-01c:** **First executable write example** in how-threadline-works must be `Threadline.Audit.transaction/3` (shape aligned with getting-started §6 / example app — Plug context + `:action`, not standalone `record_action/2`).
- **D-115-01d:** Flow reorder: Plug/context → **`Audit.transaction/3` wraps domain writes** → triggers capture → optional `:action` links semantics for correlation filters. Remove standalone flow step that teaches `record_action/2` without domain writes.
- **D-115-01e:** JTBD Job 2: replace “get fancy, call `record_action`” with wrap-in-`Audit.transaction/3` with `:action` when intent/correlation matter.

**Rationale:** README + getting-started already teach the helper; how-threadline-works is the outlier. Full rewrite risks duplicating getting-started and churning valuable JTBD content. Surgical edits fix the discovery-order contradiction with least surprise.

### D-115-02: Legacy `record_action/2` framing (Gray Area 2)

- **D-115-02a:** **Option B — visible building block + A-lite link-out** (not escape-hatch-only, not dual fenced legacy recipe). Phase 112 B-lite precedent: no second manual-recipe fenced block in narrative guides.
- **D-115-02b:** **Deprecate the hand-rolled recipe, not the API** — CHANGELOG 0.6.0 deprecates manual GUC + `record_action/2` + `action_id` linkage recipe; `Threadline.record_action/2` remains a public semantics primitive.
- **D-115-02c:** **Keep domain vocabulary in formula** — retain `app intent` language tied to semantic `AuditAction` / `record_action/2`, with one composition clause: normal adoption reaches intent through **`Audit.transaction/3` with `:action`**, which invokes `record_action/2` and links `audit_transactions.action_id`.
- **D-115-02d:** **Capture-only is first-class** — document omitting `:action` / `capture_only: true` as valid; strict `:correlation_id` filters not matching those rows is expected, not a bug.
- **D-115-02e:** **Correlation story must survive recentering** — one sentence: request headers populate `AuditContext` at the edge; **queryable** correlation requires an `audit_actions` row linked via `action_id` in the same DB transaction (`Audit.transaction/3` with `:action`).
- **D-115-02f:** Public API write-side order: **`Audit.transaction/3` (recommended)** → `Threadline.Plug` → `Threadline.Job` (mention if space) → `record_action/2` (semantic primitive; prefer helper for new code). Link manual recipe to `integration-contracts.md` § Audited write path — **do not add** a new escape-hatch section in Phase 115 (out of scope).

**Rationale:** Threadline’s three-layer model (capture / semantics / exploration) requires naming both capture and semantics. Hiding `record_action/2` collapses “DB truth ≠ app intent.” Showing the deprecated recipe trains the foot-gun v1.24 removed.

### D-115-03: Cross-doc discovery contract (Gray Area 3 / NARR-02)

- **D-115-03a:** **Doc ownership matrix:**

  | Doc | Owns |
  |-----|------|
  | README | Map + persona routing; version quick start; one-line blessed-path pointers |
  | how-threadline-works | Mental model, formula, flow, JTBD, non-goals |
  | getting-started-saas | First-hour procedure; §6 canonical runnable snippet |
  | domain-reference | API routing tables (Phase 117 follow-on for stale incident prose) |

- **D-115-03b:** **Canonical discovery paths from Hex:**

  1. Hex.pm / HexDocs README — map only
  2. **Architecture evaluation** → `how-threadline-works.md` → `domain-reference.md`
  3. **First-hour adoption** → `getting-started-saas.md` (skim how-threadline-works if model unclear)
  4. Both paths **converge** on: audited writes → `Threadline.Audit.transaction/3` → details in getting-started §6

- **D-115-03c:** **Fix README “What you get → Semantics” bullet** — lead with `Threadline.Audit.transaction/3` (recommended audited write path); name `record_action/2` as the semantic primitive the helper wraps. Primary low-cost NARR-02 fix for Hex evaluators who stop at README.
- **D-115-03d:** **Keep README opening API laundry list** (L10) enumerating both `Audit.transaction/3` and `record_action/2` — satisfies existing `readme_doc_contract_test` completeness pattern (Ecto/Oban: README maps, guides teach).
- **D-115-03e:** **Optional** one sentence after README opening paragraph: “New Phoenix integrations should use `Threadline.Audit.transaction/3`; see getting-started §6.” Lock via doc-contract if added.
- **D-115-03f:** **Start here** — tighten cross-links so both paths name the shared write-path literal; keep `how-threadline-works` listed for “understanding” and `getting-started-saas` for “adopting.”
- **D-115-03g:** **getting-started intro** — reciprocal sentence: this guide and how-threadline-works both treat `Audit.transaction/3` as recommended; §6 proves it.
- **D-115-03h:** **how-threadline-works “Where to go next”** — add numbered discovery order (README → this guide → getting-started §6 → domain-reference → integration-contracts).

**Rationale:** NARR-02 failure mode today is conflicting hierarchy, not missing links. Oban/Phoenix pattern: README never duplicates full tutorial; mental-model guide must agree with procedure guide on the blessed path.

### D-115-04: Doc-contract literals + evolution prose (Gray Area 4 / NARR-03)

- **D-115-04a:** **Extend existing** `test/threadline/how_threadline_works_doc_contract_test.exs` with a **second test** (do not create a separate NARR file) — repo pattern: multiple tests per guide module.
- **D-115-04b:** **SSOT phrase in how-threadline-works:** `recommended audited write path` (harmonize with README; getting-started may keep `recommended write path` variant — both acceptable cross-doc).
- **D-115-04c:** **Minimum NARR-03 locks:**

  ```elixir
  assert String.contains?(doc, "Threadline.Audit.transaction/3")
  assert String.contains?(doc, "recommended audited write path")
  ```

- **D-115-04d:** **Recommended comprehensive locks (same test):** scoped `### Write-side` subsection — `Audit.transaction/3` appears **before** `record_action/2`; assert link to `getting-started-saas.md` and `§6`. **Retain** existing `record_action/2` positive asserts in structural test (domain vocabulary, not write-path face).
- **D-115-04e:** **Optional cross-doc test** — new assertions in `readme_doc_contract_test.exs` or small `narrative_discovery_doc_contract_test.exs`: all three NARR docs contain `Threadline.Audit.transaction/3`. Do not remove `record_action/2` from readme contract.
- **D-115-04f:** **Evolution so far — prose only in Phase 115:** add bullet while editing guide:

  > `- \`0.6.0\` packaged the Evidence plane and \`Threadline.Audit.transaction/3\` as the recommended audited write path.`

  **Do not** add Evolution semver asserts to Phase 115 contract scope — Phase 117 locks semver chronology + upgrade-path minor bullet (DOC-02).
- **D-115-04g:** **Housekeeping (Claude's discretion):** wire `test/threadline/audit_doc_contract_test.exs` into `mix verify.doc_contract` alias if not already — closes v1.24 gate drift noted in research.

**Rationale:** Doc-contract sweet spot: positive locks on blessed path + write-side ordering, not full-paragraph snapshots. NARR-03 is write-path truth; semver authority is Phase 117.

### Cross-cutting architecture principles

- **Three-layer narrative:** Capture (triggers + Plug/Job) → Semantics (`Audit.transaction/3` face, `record_action/2` primitive) → Exploration (timeline/export/operator — already correct in guide).
- **Principle of least surprise:** First guide tier an adopter reads after README must not contradict getting-started §6.
- **OSS DNA §2:** Doc change + contract change land as one logical changeset; named `mix verify.doc_contract` entrypoint.
- **Product strategy (prompts):** Hybrid audit platform — row capture + action/context layer + operator tooling; docs must not blur capture and semantics (ExAudit process-local context footgun) or teach primitive-first like pre-helper Threadline recipes.

### Claude's Discretion

- Exact prose wording within the shapes above (headline sentences, JTBD tone).
- Whether to add README optional blessed-path sentence + contract lock (D-115-03e).
- Whether cross-doc NARR-02 test lives in readme contract vs new file (D-115-04e).
- `section_after` / `:binary.match` helper style for write-side scoping in contract test.
- Harmonizing getting-started “recommended write path” → “recommended audited write path” for phrase unity (optional, not required if both phrases locked separately).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 115 goal, success criteria, scope guard
- `.planning/REQUIREMENTS.md` — NARR-01, NARR-02, NARR-03
- `.planning/phases/114-release-0-6-0-packaging/114-CONTEXT.md` — deferred how-threadline-works; deprecated recipe vs API; D-114-04d out-of-scope list

### Narrative SSOT guides (edit targets)
- `guides/how-threadline-works.md` — primary edit surface (NARR-01)
- `guides/getting-started-saas.md` — §6 canonical snippet; intro cross-links (NARR-02)
- `README.md` — Start here, What you get → Semantics (NARR-02)

### Seam contracts (link targets, not rewrite scope)
- `guides/integration-contracts.md` § Audited write path via `Threadline.Audit` — forbidden callback ops; manual recipe pointer
- `guides/domain-reference.md` — API routing (stale incident prose → Phase 117)

### Doc-contract tests (extend)
- `test/threadline/how_threadline_works_doc_contract_test.exs` — NARR-03 primary
- `test/threadline/readme_doc_contract_test.exs` — optional NARR-02 cross-doc
- `test/threadline/getting_started_saas_doc_contract_test.exs` — already locks helper; reference pattern
- `test/threadline/audit_doc_contract_test.exs` — getting-started write-path locks; consider verify.doc_contract gate
- `mix.exs` — `verify.doc_contract` alias topology

### Product / OSS DNA
- `prompts/threadline-elixir-oss-dna.md` §2 Docs and contracts — doc-contract tests, README ↔ guides alignment
- `prompts/audit-lib-domain-model-reference.md` — AuditTransaction ≠ request; capture vs semantics bounded contexts
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — row-change vs user-action auditing; Carbonite/PaperTrail/django-auditlog doc patterns

### Prior phase precedent
- `.planning/milestones/v1.24-phases/113-adopter-truth-doc-sync/113-CONTEXT.md` — version SSOT doc-contract pattern (if present)
- Phase 112 decision (referenced in 114): B-lite link-out, no second fenced legacy block in narrative guides

</canonical_refs>

<code_context>
## Existing Code Insights

### Current drift (must fix)
- `guides/how-threadline-works.md` — formula, flow step 5, code sample, Public API write-side, JTBD Job 2 center `record_action/2`; no `Audit.transaction/3`.
- `README.md` L44 — Semantics bullet names only `record_action/2`.
- `how_threadline_works_doc_contract_test.exs` — locks `record_action/2`, not `Audit.transaction/3`.

### Already aligned (preserve)
- `README.md` — Start here, Quick Start step 4, opening API list include `Audit.transaction/3`.
- `guides/getting-started-saas.md` §6 — full recommended-path snippet + fixture-backed contract.
- `guides/integration-contracts.md` — `Audit.transaction/3` as audited write path; callback must not call `record_action/2`.
- `CHANGELOG.md` 0.6.0 — deprecated manual recipe; `Audit.transaction/3` in Added.

### Reusable patterns
- `GettingStartedFixtures` — canonical snippet shape for transaction helper example.
- `exploration_routing_doc_contract_test.exs` — `:binary.match` section scoping pattern for contract tests.
- `getting_started_saas_doc_contract_test.exs` — `refute "Legacy manual recipe"` negative guard pattern.

### Integration points
- `mix verify.doc_contract` — gate for all doc-contract tests; must stay green after edits.
- Example app README already uses `Audit.transaction/3` — narrative sync does not require example changes (Phase 116).

</code_context>

<specifics>
## Specific Ideas

### Ecosystem patterns to emulate
- **Carbonite:** “Easiest way (Multi)” before “Without Ecto.Multi” — layered doc ladder, one direction.
- **django-auditlog:** “Automatically logging changes” before “Manually logging changes.”
- **Ecto:** Repository/changeset happy path in guides; escape hatches labeled advanced.
- **Oban:** README maps; installation guide owns procedure; moduledoc holds exhaustive API.

### Ecosystem footguns to avoid
- **PaperTrail Elixir:** wrapper-only happy path — misses writes if devs use raw Repo (Threadline triggers avoid this; don’t imply semantics alone is enough).
- **ExAudit:** process-local context + opaque storage — Threadline docs must keep SQL-native capture story visible.
- **Audited (Rails):** YAML serialization upgrade pain — Threadline stays JSONB/SQL-native in narrative.
- **Logidze:** connection-local metadata + row bloat — Threadline keeps audit tables separate (already in Architecture layers §1).

### Unified formula shape (locked prose intent)

```markdown
- `DB truth` = trigger-captured `AuditTransaction` + `AuditChange`
- `app intent` = semantic `AuditAction` records — normally via `Threadline.Audit.transaction/3`
  with `:action` (implemented by `Threadline.record_action/2` inside the helper)
- `operator tooling` = timelines, exports, optional `/audit` surface
```

### Code example shape (how-threadline-works flow block)

Minimal `Audit.transaction/3` after Plug — match getting-started semantics (audit_context, `:action`, domain callback return map), not standalone `record_action/2`.

</specifics>

<deferred>
## Deferred Ideas

### Out of Phase 115 scope (ROADMAP / research consensus)
- **`integration-contracts.md` escape-hatch subsection** with full manual GUC recipe fenced block — link to existing § Audited write path only; dedicated escape-hatch prose can follow in a later doc phase.
- **`domain-reference.md` incident JSON prose** still citing `record_action/2` alone — Phase 117 DOC authority.
- **`guides/upgrade-path.md` 0.5→0.6 minor semver bullet** — Phase 117 DOC-02.
- **Evolution semver doc-contract locks** — Phase 117 alongside semver vocabulary sweep.
- **Example app README / Job moduledoc snippet alignment** — Phase 116; example already uses helper in README body.
- **`lib/threadline/job.ex` moduledoc** standalone `record_action` example — note for future; not Phase 115.

### Reviewed todos
- None matched phase 115 via `gsd-sdk query todo.match-phase`.

</deferred>

---

*Phase: 115-narrative-doc-sync*
*Context gathered: 2026-05-27*
