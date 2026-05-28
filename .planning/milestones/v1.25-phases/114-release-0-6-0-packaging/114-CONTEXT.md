# Phase 114: Release 0.6.0 Packaging - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Package the v1.22–v1.24 in-repo stack as **threadline 0.6.0**: version bump, dated CHANGELOG, ExDoc module grouping for new public APIs, `mix verify.release` green on a clean tree, and install/distribution version SSOT across README, adoption-pilot, and all install-snippet doc contracts.

This phase delivers a **publish-ready** tree. Tag push and Hex publish remain maintainer human gates per Phase 48 and `hex-publish.yml` — not phase deliverables.

Requirements: REL-01, REL-02, REL-03, REL-04.

Scope guard: `mix.exs`, `CHANGELOG.md`, ExDoc config, release verify aliases, adoption-pilot + README + install-snippet doc contracts, CONTRIBUTING runbook literals. No new library features unless release packaging exposes a doc gap. Narrative doc sync (`how-threadline-works.md`), example README friction, and semver historical prose belong in Phases 115–117.

</domain>

<decisions>
## Implementation Decisions

### Release narrative headline (D-114-01)

- **D-114-01a:** Use **hybrid adopter-outcome + packaging honesty** — not milestone rollup, not packaging-only.
- **D-114-01b:** Release-type label: **"adopter-ready release"** — parallel to 0.3.0 "drop-in production adoption", 0.4.0 "operator-surface foundation", 0.5.0 "integration-breadth".
- **D-114-01c:** Recommended opening sentence shape:

  > Threadline 0.6.0 is the adopter-ready release: it packages the in-repo stack since **0.5.0** — the Evidence plane (`Threadline.Evidence`, proof vocabulary, `/audit/evidence`), the blessed audited write path (`Threadline.Audit.transaction/3`), and operator/demo surfaces from the realistic walkthrough — so Hex evaluators and pilot hosts see the same truth already shipped across v1.22–v1.24.

- **D-114-01d:** Do **not** use internal milestone names (`v1.22`, `v1.25`) in adopter-facing opener — semver story only (Phase 117 DOC-03 alignment).
- **D-114-01e:** Avoid compliance/SIEM framing; state narrow Evidence non-goals in **Changed** bullets, not headline.
- **D-114-01f:** Rationale synthesis: PaperTrail/django-auditlog under-narrate releases; vendor docs over-narrate compliance. Threadline's 0.3.0→0.5.0 precedent + OSS DNA §3 ("Hex metadata and README agree on version story") require an outcome headline with explicit "packages since 0.5.0" clause so evaluators understand this is catch-up truth, not net-new feature invention on tag day.

### CHANGELOG structure (D-114-02)

- **D-114-02a:** **Option A — capability-area grouping** within standard Keep a Changelog categories (`Added`, `Changed`, `Deprecated`, `Breaking`). Reject milestone headers (v1.22/v1.23/v1.24) and flat-only bullet dumps.
- **D-114-02b:** Move current `[Unreleased]` content into `0.6.0` **`### Changed`** under **Public documentation and evidence-plane contract** — do not duplicate as `Added`.
- **D-114-02c:** **`### Added`** bold-lead groups (Phase 48 D-04 pattern):
  1. **Evidence plane** — `Threadline.Evidence`, `Evidence.Proof`, schema, `mix threadline.evidence.show`
  2. **Audited write path** — `Threadline.Audit.transaction/3`
  3. **Operator and evidence surfaces** — `/audit/evidence`, `evidence_authorize_fn`, viewer parity
  4. **Reference composition (sigra-reference)** — brief pointer to example app / walkthrough (detail in example README, not changelog wall)
- **D-114-02d:** **`### Deprecated`:** manual GUC + `record_action/2` recipe is legacy escape hatch; prefer `Audit.transaction/3` for new code.
- **D-114-02e:** **`### Breaking`:** explicit "none" if true for existing 0.5.x capture-only and phoenix-surface adopters who do not opt into new surfaces.
- **D-114-02f:** **`### Upgrade from 0.5.x` — detailed** (~12–15 bullets, not minimal): Dependencies (`~> 0.6`), migrations (evidence schema if using Evidence), `evidence_authorize_fn` mount seam (not inherited from `/audit` auth), write-path adoption pointer, canonical CLI (`mix threadline.evidence.show`, not `mix verify.evidence`), verification entrypoints per `guides/upgrade-path.md`. Lane matrix stays in upgrade-path guide; changelog owns release delta only.
- **D-114-02g:** Optional `(Phase N)` parentheticals inside bullets only — never section headers.

### ExDoc module grouping (D-114-03)

- **D-114-03a:** **Option B — extend Core API + new Evidence group** (reject combined "Evidence & Audit" and minimal Audit-only).
- **D-114-03b:** Sidebar order: Core API → Evidence → Integration → Integrations → Operator Surface → Schemas → Mix Tasks.
- **D-114-03c:** **Core API** — add `Threadline.Audit`, `Threadline.Query`, `Threadline.Investigation`, `Threadline.ChangeDiff` alongside existing facade/semantics modules. Audit belongs on write/semantics seam; Query/Investigation close pre-existing ungrouped read-API gap.
- **D-114-03d:** **Evidence** (new group) — `Threadline.Evidence`, `Threadline.Evidence.Proof`, `Threadline.Evidence.Subject`. Matches domain-reference § Evidence proof and v1.22 bounded context.
- **D-114-03e:** **Mix Tasks** — add `Mix.Tasks.Threadline.Evidence.Show`, `Mix.Tasks.Threadline.Health.Coverage`, `Mix.Tasks.Threadline.Policy.Show` for viewer-task parity with `how-threadline-works.md`.
- **D-114-03f:** Leave Operator Surface LiveView internals ungrouped; defer governance schemas (`EvidenceRecord`, etc.) unless doc-gap review finds direct adopter hits.
- **D-114-03g:** Extend `release_artifact_contract_test.exs` to lock Audit in Core API, Evidence group membership, and Evidence.Show in Mix Tasks — prevents 0.7 regression without rewriting entire group contract.

### Version literal sweep (D-114-04)

- **D-114-04a:** **REL-04 + install-snippet closure** — not README-only minimum, not full narrative sweep (Option A Tier 3).
- **D-114-04b:** Explicit touch set (10 source files + verification):

  | File | Change |
  |------|--------|
  | `mix.exs` | `@version "0.6.0"` |
  | `CHANGELOG.md` | Cut `[0.6.0]` section; release-metadata `~> 0.6` bullet |
  | `README.md` | `{:threadline, "~> 0.6"}` |
  | `guides/adoption-pilot-backlog.md` | **0.6.0** + `~> 0.6` Distribution preflight |
  | `guides/getting-started-saas.md` | `{:threadline, "~> 0.6"}` |
  | `guides/operator-surface.md` | `{:threadline, "~> 0.6"}` |
  | `test/threadline/adoption_pilot_doc_contract_test.exs` | `~> 0.6`; refute stale `~> 0.5` |
  | `test/threadline/release_artifact_contract_test.exs` | README `~> 0.6` |
  | `test/threadline/getting_started_saas_doc_contract_test.exs` | `~> 0.6` |
  | `test/threadline/operator_surface_doc_contract_test.exs` | `~> 0.6` |

- **D-114-04c:** Derive exact semver from `MixProject.project()[:version]` in adoption-pilot test; optionally derive major constraint `~> #{major}` to reduce next minor churn (Claude's discretion).
- **D-114-04d:** **Do not touch** in Phase 114: `guides/how-threadline-works.md` (115/117), `guides/upgrade-path.md` minor-history prose (117 unless breaking note required), `examples/threadline_phoenix/mix.exs` (path dep — no Hex version), example README (116), `.planning/**`, immutable `## [0.5.0]` CHANGELOG history.
- **D-114-04e:** Footgun avoided: partial sweep leaves copy-paste install paths on `~> 0.5` while Hex ships 0.6.0 — doc-contract topology already enforces four install surfaces; updating only REL-04-named files leaves CI red.

### Publish boundary (D-114-05)

- **D-114-05a:** **Option C — publish-ready + CONTRIBUTING refresh** — consistent with Phase 48 D-06–D-11.
- **D-114-05b:** Phase deliverable: `mix verify.release` green from clean tree (isolated worktree acceptable if main workspace dirty — Phase 48 precedent).
- **D-114-05c:** **Out of phase scope:** creating/pushing `v0.6.0` tag, running `mix hex.publish`, asserting hex.pm live state in phase verification.
- **D-114-05d:** Refresh CONTRIBUTING maintainer runbook from stale **`v0.3.0`** → **`v0.6.0`** (tag examples, checklist title, step 5); update `release_artifact_contract_test.exs` CONTRIBUTING literal accordingly — packaging SSOT, not optional polish.
- **D-114-05e:** Post-phase maintainer gate (document in verification, not REL-03): after merge + green `main` → `mix verify.release` → tag `v0.6.0` → push → watch `hex-publish.yml` → confirm `mix hex.info threadline`.
- **D-114-05f:** `mix verify.release` scope unchanged (D-08/D-09): clean tree, `bin/verify-release-shape`, release artifact + CI topology contracts, `mix docs`, `mix hex.build` — no Postgres, no full suite, no `hex.publish`.

### Cross-cutting architecture principles

- **Version SSOT:** `mix.exs` `@version` drives doc-contract tests; install constraint `~> 0.6` locked in all four install-snippet surfaces + README (OSS DNA §3).
- **Three-layer release model:** local pre-flight (`verify.release`) → contributor CI (`ci.all` on main) → registry publish (tag-triggered workflow, human gate).
- **Honest upgrade contract:** CHANGELOG upgrade block is the 0.x migration truth; guides provide depth — ExAudit/PaperTrail footgun of opaque upgrade paths avoided.
- **Domain-aligned doc IA:** write path (Audit) in Core API; proof plane (Evidence) separate; operator viewers in Mix Tasks — matches capture/semantics/exploration layers from domain model reference.

### Claude's Discretion

- Exact headline wording within D-114-01c shape.
- Whether to derive `~> MAJOR` dynamically in doc-contract tests vs hardcode `~> 0.6`.
- Exact CHANGELOG bullet count per capability group (keep scannable, not ingredient dump).
- Whether to add governance schemas to ExDoc Schemas group after doc build review.
- Hex row "Done" vs "Pending" in adoption-pilot Distribution preflight (human publish truth).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` — Phase 114 goal, success criteria, scope guard
- `.planning/REQUIREMENTS.md` — REL-01 through REL-04
- `.planning/threads/2026-05-27-milestone-next-step-v1.25-assessment.md` — Hex 0.5.0 lag rationale; v1.25 wedge

### Prior release phase precedent
- `.planning/milestones/v1.14-phases/48-threadline-0.3.0-release/48-CONTEXT.md` — D-01–D-11 release narrative, verify.release scope, changelog organization, three-layer publish model
- `.planning/milestones/v1.24-phases/113-adopter-truth-doc-sync/113-CONTEXT.md` — D-113-03 version SSOT pattern; doc-contract derive from MixProject

### OSS DNA and product strategy
- `prompts/threadline-elixir-oss-dna.md` — §3 Releases and Hex (version SSOT, named verify entrypoints, doc contracts)
- `prompts/audit-lib-domain-model-reference.md` — capture/semantics/exploration layers; Evidence bounded context
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — release narrative lessons; ExAudit opaque-storage footguns; action vs row-change distinction
- `prompts/THREADLINE-GSD-IDEA.md` — correct-by-default; honest reference; non-goals

### Release surfaces to modify
- `mix.exs` — `@version`, `docs/0` groups_for_modules, `verify.release` alias
- `CHANGELOG.md` — `[0.6.0]` section; fold `[Unreleased]`
- `README.md` — install snippet
- `guides/adoption-pilot-backlog.md` — Distribution preflight
- `guides/getting-started-saas.md`, `guides/operator-surface.md` — install snippets
- `CONTRIBUTING.md` — maintainer runbook (stale v0.3.0 literals)
- `bin/verify-release-shape` — version ↔ CHANGELOG date alignment
- `.github/workflows/hex-publish.yml` — tag-triggered publish (unchanged)

### Contract tests
- `test/threadline/release_artifact_contract_test.exs` — package files, ExDoc extras, README/CONTRIBUTING literals, module groups
- `test/threadline/adoption_pilot_doc_contract_test.exs` — adoption-pilot version SSOT
- `test/threadline/getting_started_saas_doc_contract_test.exs` — getting-started install snippet
- `test/threadline/operator_surface_doc_contract_test.exs` — operator-surface install snippet
- `test/threadline/ci_topology_contract_test.exs` — `ci.all` excludes `verify.release`

### House style references
- `CHANGELOG.md` — `## [0.5.0]`, `## [0.4.0]`, `## [0.3.0]` opening-paragraph patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `bin/verify-release-shape` — validates `@version` ↔ dated CHANGELOG; first step in `verify.release`
- `mix verify.release` — clean tree + shape + release contracts + docs + hex.build (Phase 48 composition)
- `release_artifact_contract_test.exs` — locks Integrations/Operator Surface/Integration groups; extend for Audit/Evidence
- `adoption_pilot_doc_contract_test.exs` — `@version` derive pattern from Phase 113

### Established Patterns
- CHANGELOG opener: `Threadline X.Y.Z is the <release-type>: <proof surfaces>.`
- Doc-contract tests: `File.read!` + literal asserts + refute stale versions
- `ci.all` intentionally excludes `verify.release` (maintainer pre-flight, not PR gate duplication)
- ExDoc: adoption-journey module groups (not Ecto-style ungrouped core)

### Integration Points
- `mix verify.doc_contract` alias list — must stay green after install-snippet updates
- `hex-publish.yml` — tag `v0.6.0` must match `@version "0.6.0"` when maintainer publishes
- ExDoc extras unchanged; module grouping is primary REL-02 surface

</code_context>

<specifics>
## Specific Ideas

### Recommended CHANGELOG opener (final wording — adapt in implementation)

```markdown
Threadline 0.6.0 is the adopter-ready release: it packages the in-repo stack since 0.5.0 — the Evidence plane (`Threadline.Evidence`, proof vocabulary, `/audit/evidence`), the blessed audited write path (`Threadline.Audit.transaction/3`), and operator/demo surfaces from the realistic walkthrough — so Hex evaluators and pilot hosts see the same truth already shipped across v1.22–v1.24.
```

### Recommended ExDoc `groups_for_modules` delta

```elixir
"Core API": [
  Threadline,
  Threadline.Audit,           # NEW
  Threadline.ChangeDiff,      # NEW (ungrouped gap)
  Threadline.Export,
  Threadline.Investigation,   # NEW (ungrouped gap)
  Threadline.Query,           # NEW (ungrouped gap)
  Threadline.Retention,
  Threadline.Retention.Policy,
  Threadline.Semantics.ActorRef,
  Threadline.Semantics.AuditContext
],
Evidence: [                    # NEW GROUP
  Threadline.Evidence,
  Threadline.Evidence.Proof,
  Threadline.Evidence.Subject
],
"Mix Tasks": [
  # ... existing 8 tasks ...
  Mix.Tasks.Threadline.Evidence.Show,    # NEW
  Mix.Tasks.Threadline.Health.Coverage,  # NEW
  Mix.Tasks.Threadline.Policy.Show       # NEW
]
```

### Post-phase maintainer checklist (not phase verification)

```bash
git status --porcelain   # must be empty
mix verify.release
mix ci.all               # if not already green on main
git tag -a v0.6.0 -m "Release v0.6.0"
git push origin v0.6.0
mix hex.info threadline  # confirm 0.6.0 after workflow completes
```

</specifics>

<deferred>
## Deferred Ideas

- **`guides/how-threadline-works.md` semver historical bullet for 0.6.0** — Phase 115/117 (NARR + DOC)
- **`guides/upgrade-path.md` 0.5.x → 0.6.x minor bullet** — Phase 117 unless REL-01 breaking notes require it in 114
- **Example README / first-hour friction** — Phase 116
- **adoption-pilot test-count refresh + evaluator one-pager** — Phase 118
- **Standalone `guides/upgrading-to-0.6.md`** — only if CHANGELOG upgrade block becomes unwieldy (Phase 48 deferred pattern)
- **Governance schema ExDoc grouping** — defer unless doc build review flags gap
- **Actual Hex publish as automated phase step** — rejected; human gate per Phase 48 D-09

</deferred>

---

*Phase: 114-release-0-6-0-packaging*
*Context gathered: 2026-05-27*
