# Phase 117: Evidence Plane Doc Authority - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Evaluators find evidence-plane documentation without dead links; adopter-facing prose speaks in **Hex package semver** (`0.6.0`, `~> 0.6`, `0.5.x → 0.6.x`), not internal milestone labels (`v1.22`, `v1.25`). Requirements: DOC-01, DOC-02, DOC-03.

Scope guard (ROADMAP): `guides/` evidence cross-links, PROJECT/README adopter bands, doc-contract tests. **No new library APIs.** Optional thin `guides/evidence-plane.md` hub **only if** it reduces drift — research concluded it does not.

Includes the three narrative items explicitly deferred from Phase 115 (incident JSON prose, upgrade-path 0.5→0.6 bullet, Evolution semver contracts) as one doc-authority changeset — not a second phase.

</domain>

<decisions>
## Implementation Decisions

### D-117-01: Evidence-plane entry point (DOC-01) — no new hub file

- **D-117-01a:** **Do not create** `guides/evidence-plane.md` for Phase 117. Split-guide architecture is intentional (scope/non-goals → `how-threadline-works.md`; lanes/`/audit/evidence` → `upgrade-path.md`; proof vocabulary → `domain-reference.md`; mount/auth/CLI → `operator-surface.md`; exercises → `WALKTHROUGH.md` §5).
- **D-117-01b:** **Authoritative adopter entry** = README `## Evidence plane` compact claim strip → three outward links (already contract-locked in `readme_doc_contract_test.exs`). Pattern matches Operator Surface (README map → deep guide).
- **D-117-01c:** **Fix maintainer dead refs** — `.planning/PROJECT.md` (and any adopter-band copy still listing `guides/evidence-plane.md`) must list real paths: `how-threadline-works.md`, `upgrade-path.md`, `domain-reference.md`, `operator-surface.md`. Batch-fix stale `@guides/evidence-plane.md` in `.planning/milestones/` when touching those files; not a `verify.doc_contract` target.
- **D-117-01d:** **ExDoc** — no new `extras` page for evidence plane; **Evidence** `groups_for_modules` in `mix.exs` remains API discovery. Narrative = README + split guides.
- **D-117-01e:** **Revisit hub** only if post–v1.25 pilot feedback shows repeated “where is evidence docs?” — then TOC-only hub (&lt;80 lines, **no duplicated non-goals**), with hub-only contract asserting link targets.

**Rationale:** v1.22 shipped split seams (113-CONTEXT: investigation ≠ compliance platform). README-as-map + doc-contract gate matches OSS DNA §2 and Phase 99 bundle. Only real drift is PROJECT.md phantom path, not evaluator confusion (108-CONTEXT). Hub adds a fifth surface to keep aligned without new behavioral proof.

### D-117-02: Semver vocabulary sweep (DOC-02) — option B

- **D-117-02a:** **Adopter paths use package semver** for “when introduced” and upgrade story; **drop `v1.2x` milestone labels** from README, `getting-started-saas.md`, `how-threadline-works.md`, `upgrade-path.md` evaluator prose.
- **D-117-02b:** **Pattern for section headings:** prefer timeless H2/H3 **or** `(since 0.x.0)` — not `v1.24+`. Example renames:
  - `### Recommended path (v1.24+)` → `### Recommended path (0.6.0+)` or `### Recommended path — Audit.transaction/3`
  - `For v1.21's support-lane wording` → `For 0.5.0 support-lane wording` (lanes introduced in integration-breadth era)
  - Packaging scorecard `v1.19` → `0.5.0` or timeless “stay-in-tree” prose + CHANGELOG pointer
- **D-117-02c:** **`guides/domain-reference.md` API-era headers** (`v1.10+`, `v1.11+`, `Phase 13` section titles) — **allowlist, do not mass-scrub** in Phase 117. Fix only flow-shaped prose (incident JSON subsection). Optional later pass maps `v1.10+` → `since 0.2.0` with contract updates — out of scope unless planner has bandwidth.
- **D-117-02d:** **Add `guides/upgrade-path.md` bullet** under `## Upgrade by Threadline minor`:

  > `0.5.x → 0.6.x`: Evidence plane (`Threadline.Evidence`, `mix threadline.evidence.show`, `/audit/evidence`), recommended audited write path (`Threadline.Audit.transaction/3`); see `CHANGELOG.md` `[0.6.0]` for deprecated manual GUC + `record_action/2` recipe.

- **D-117-02e:** **CHANGELOG** — keep `[0.6.0]` opener semver-only (D-114-01d); keep `(Phase N)` parentheticals inside historical bullets (D-114-02g); do not milestone-scrub archived sections.
- **D-117-02f:** **Maintainer mapping** — optional one-line table in `CONTRIBUTING.md` or `.planning/` only (`v1.24 → 0.6.0`, etc.) for archaeology; never in README opener or getting-started first screenful.
- **D-117-02g:** **Standard evaluator sentence** (use in upgrade-path intro or PROJECT adopter band if touched):

  > Threadline **0.6.0** packages Evidence, `Audit.transaction/3`, and aligned operator surfaces that landed in-repo after **0.5.0**; upgrade steps are semver-scoped in `CHANGELOG.md` and `guides/upgrade-path.md`.

**Rationale:** Phase 114 locked `~> 0.6` install literals; leaving `v1.24+` in getting-started undoes adopter-ready story. Ecto/Phoenix/Oban/Carbonite pattern: semver in CHANGELOG + upgrade guides; timeless reference guides. Aligns D-114-01d into guide body, not just release opener.

### D-117-03: Deferred Phase 115 narrative prose — in scope (narrow)

- **D-117-03a:** **`guides/domain-reference.md` incident JSON (COMP-EXAMPLE-INCIDENT-JSON)** — surgical fix to numbered step 1 only: semantics via **`Threadline.Audit.transaction/3` with `:action`** (links `audit_transactions.action_id`), not standalone `record_action/2` as the HTTP write-path face. Preserve steps 2–3, anchor id, test name, auth notes.
- **D-117-03b:** **Do not** rewrite full `domain-reference` AuditAction/telemetry sections — `record_action/2` remains correct as **primitive** documentation.
- **D-117-03c:** **`guides/how-threadline-works.md` Evolution** — prose bullet already present from Phase 115; add **doc-contract** locks only (see D-117-04).
- **D-117-03d:** **Out of scope:** `integration-contracts.md` escape-hatch fenced subsection; example/Job moduledoc alignment (116 territory); how-threadline-works structural rewrite (115 complete).

**Rationale:** Phase 115 discovery order ends at domain-reference; stale L274 contradicts NARR-02/03. Smallest fix (~15 lines) closes authority-without-accuracy risk. Carbonite/django-auditlog pattern: update **end-to-end flow** sections when blessed API changes, not every primitive mention.

### D-117-04: Doc-contract enforcement (DOC-03) — minimal-plus

Extend existing modules; **wire** `exploration_routing_doc_contract_test.exs` into `mix.exs` `verify.doc_contract` alias (currently orphaned).

| Test | File | Assert intent |
|------|------|----------------|
| Evolution semver chronology | `how_threadline_works_doc_contract_test.exs` | `## Evolution so far`; `` `0.5.0` `` and `` `0.6.0` ``; `` `0.6.0` packaged the Evidence plane `` + `Threadline.Audit.transaction/3`; scoped ordering `0.5.0` before `0.6.0` in Evolution section |
| 0.5→0.6 upgrade bullet | `upgrade_path_doc_contract_test.exs` | Under `## Upgrade by Threadline minor`: stable literals `0.5`, `0.6`, `Audit.transaction/3` or `Evidence` (planner picks one canonical phrase) |
| No dead evidence-plane hub link | `readme_doc_contract_test.exs` + loop | `refute "guides/evidence-plane.md"` in README, getting-started, how-threadline-works, upgrade-path, adoption-pilot-backlog |
| Semver-not-milestone (evaluator band) | new test in `how_threadline_works` or `semver_adopter_doc_contract_test.exs` | `refute ~r/v1\.2[0-9]/` in README, how-threadline-works, getting-started, upgrade-path — **exclude** domain-reference allowlist |
| Incident JSON blessed path | `exploration_routing_doc_contract_test.exs` | After `COMP-EXAMPLE-INCIDENT-JSON`: `Threadline.Audit.transaction/3` in scoped `binary.match` |
| Evidence CLI / README strip | `evidence_cli_doc_contract_test.exs`, existing readme tests | **No change** — already locked |

**Do not:** assert `.planning/PROJECT.md` in `verify.doc_contract`; full-paragraph snapshots; blanket `refute Phase N` in domain-reference; duplicate evidence CLI tests.

**If hub ever added later:** separate `evidence_plane_hub_doc_contract_test.exs` with cross-link asserts; relax `refute` for paths that legitimately link hub.

### Cross-cutting principles (locked)

- **Three-layer + evidence seam:** Docs partition by proof obligation (scope / lanes / vocabulary / operations) — matches product strategy hybrid model and v1.22 narrow plane thesis.
- **OSS DNA §2 + §3:** Doc change + contract change = one changeset; `mix verify.doc_contract` is evaluator gate; version story matches `mix.exs` `@version`.
- **Least surprise:** Any version-looking string in adopter paths = Hex semver or dependency floor (`phoenix ~> 1.7`), never unpublishable `v1.xx`.
- **Footguns avoided:** duplicate non-goals in hub; README CLI strings; lane table in README; compliance-platform narrative; primitive-first incident walkthrough; planning files in doc_contract.

### Claude's Discretion

- Exact semver strings in domain-reference API-era headings if a low-risk rename falls out of incident-json edit.
- Whether semver refute test lives in new file vs `how_threadline_works_doc_contract_test.exs`.
- CONTRIBUTING maintainer `v1.xx → 0.x` table (optional).
- Wording within D-117-02d upgrade bullet and D-117-03a incident step (must satisfy contracts).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 117 goal, success criteria, scope guard
- `.planning/REQUIREMENTS.md` — DOC-01, DOC-02, DOC-03
- `.planning/threads/2026-05-27-milestone-next-step-v1.25-assessment.md` — evidence-plane dead link, dual semver vocabulary

### Prior phase context (handoffs)
- `.planning/phases/114-release-0-6-0-packaging/114-CONTEXT.md` — D-114-01d semver openers; D-114-04d what not to touch in 114
- `.planning/phases/115-narrative-doc-sync/115-CONTEXT.md` — deferred incident JSON, upgrade-path bullet, evolution contracts; discovery order

### Evidence plane authority (split guides — no hub)
- `README.md` — `## Evidence plane` (DOC-01 adopter entry)
- `guides/how-threadline-works.md` — non-goals, Evolution semver prose
- `guides/upgrade-path.md` — lanes, `/audit/evidence`, minor upgrades
- `guides/domain-reference.md` — proof vocabulary, incident JSON subsection
- `guides/operator-surface.md` — mount, `evidence_authorize_fn`, CLI
- `examples/threadline_phoenix/WALKTHROUGH.md` — §5 evidence exercises

### Doc-contract tests (extend / wire)
- `test/threadline/readme_doc_contract_test.exs`
- `test/threadline/how_threadline_works_doc_contract_test.exs`
- `test/threadline/upgrade_path_doc_contract_test.exs`
- `test/threadline/exploration_routing_doc_contract_test.exs` — **add to verify.doc_contract alias**
- `test/threadline/evidence_cli_doc_contract_test.exs`
- `mix.exs` — `verify.doc_contract` alias list

### Product / OSS DNA
- `prompts/threadline-elixir-oss-dna.md` §2 Docs and contracts, §3 Releases and Hex
- `prompts/audit-lib-domain-model-reference.md` — capture vs semantics; AuditTransaction ≠ request
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — layered doc ladder (Carbonite Multi first); JSONB/SQL-native; avoid compliance blur
- `.planning/research/v1.22-policy-evidence-plane.md` — narrow evidence plane, not compliance platform

### Ecosystem precedent (doc shape)
- `.planning/phases/115-narrative-doc-sync/115-CONTEXT.md` — Carbonite/PaperTrail/django-auditlog blessed-path-first pattern
- `.planning/milestones/v1.24-phases/113-adopter-truth-doc-sync/113-CONTEXT.md` — evidence = audit-of-audit tier, same as coverage/policy

</canonical_refs>

<code_context>
## Existing Code Insights

### Already aligned (preserve)
- README `## Evidence plane` — outward links to how-threadline-works, upgrade-path, domain-reference; refutes CLI and lane table (`readme_doc_contract_test.exs`)
- `evidence_cli_doc_contract_test.exs` — canonical `mix threadline.evidence.show` in domain-reference, operator-surface, WALKTHROUGH
- NARR locks — `Audit.transaction/3`, recommended audited write path in how-threadline-works + getting-started
- ExDoc **Evidence** module group — API discovery without narrative hub

### Drift to fix
- `.planning/PROJECT.md` line ~33 — phantom `guides/evidence-plane.md`
- `domain-reference.md` L274 — `record_action/2`-only incident step 1
- `upgrade-path.md` — missing `0.5.x → 0.6.x` minor bullet
- `getting-started-saas.md` — `v1.24+` heading; `upgrade-path.md` — `v1.21` / `v1.19` milestone prose
- `exploration_routing_doc_contract_test.exs` — not in `mix.exs` `verify.doc_contract` alias

### Reusable patterns
- Phase 115 `:binary.match` section scoping for contract tests
- Phase 114 version SSOT + install-snippet contracts
- README-as-map + Operator Surface pointer pattern

</code_context>

<specifics>
## Specific Ideas

### Ecosystem — do emulate
- **Carbonite / django-auditlog:** one blessed path in first screenful; primitives and escape hatches later via cross-link (Phase 115 precedent).
- **Ecto / Phoenix / Oban:** semver in CHANGELOG + upgrade guide; topic guides are task-shaped, not umbrella indexes.
- **CloudTrail / GitHub audit log:** tiered access; investigation APIs separate from compliance marketing — Threadline non-goals list stays in how-threadline-works.
- **Stripe-style honesty:** frozen fixtures, task-oriented samples; no false STG/compliance attestation in adopter paths.

### Ecosystem — avoid
- **ExAudit:** process-local context + opaque storage — Threadline keeps SQL-native story visible.
- **Audited (Rails):** YAML serialization upgrade pain — stay JSONB/SQL-native in narrative.
- **Logidze:** connection-local metadata + row bloat — audit tables separate (already in architecture).
- **Compliance hub doc** that implies legal hold / immutable storage guarantees Threadline explicitly rejects.

### Unified doc topology (evaluator mental model)

```
README (map)
├── Evidence plane strip → how-threadline-works | upgrade-path | domain-reference
├── Start here → blessed write path → getting-started §6
└── Operator / lanes → operator-surface | upgrade-path

ExDoc modules: Evidence group = API
CHANGELOG + upgrade-path = semver history
```

</specifics>

<deferred>
## Deferred Ideas

### Out of Phase 117 scope
- **`guides/evidence-plane.md` thin hub** — only on sustained adopter feedback (D-117-01e).
- **Full domain-reference `v1.10+` → semver heading scrub** — allowlist pass; optional follow-on.
- **`integration-contracts.md` escape-hatch fenced manual recipe** — later doc phase (115 defer).
- **adoption-pilot-backlog milestone label cleanup** — Phase 118 PILOT-01 unless folded for evaluator band.
- **Example Job moduledoc `record_action` example** — future hygiene.

### Reviewed todos
- None matched phase 117 via `gsd-sdk query todo.match-phase`.

</deferred>

---

*Phase: 117-evidence-plane-doc-authority*
*Context gathered: 2026-05-27*
