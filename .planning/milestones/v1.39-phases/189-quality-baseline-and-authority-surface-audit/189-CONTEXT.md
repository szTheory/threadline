# Phase 189: Quality Baseline and Authority-Surface Audit - Context

**Gathered:** 2026-07-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 189 produces the blunt, repo-evidence quality baseline for v1.39. It ranks Threadline's weakest adoption, production, support, release, and maintenance trust risks; separates must-fix issues from good-enough, low-priority, external-owned, or N/A dimensions; and uses that audit to narrow phases 190-193.

This phase owns the audit shape, authority-surface rules, residual/seed triage thresholds, and routing rules that downstream research/planning should apply. It may create a durable planning artifact such as `189-QUALITY-AUDIT.md`, inspect current repo evidence, and recommend phase owners for findings.

This phase does not implement storage-schema fixes, rewrite release/docs surfaces, optimize CI/CD, add operator product/UI scope, create a public component API, run a synthetic external pilot, add compliance-platform features, add runtime destructive redaction, or introduce WAL/CDC/backend expansion. Those are either later v1.39 phase-owned work, future seeds, or out of scope.

</domain>

<decisions>
## Implementation Decisions

### Audit Scoring Shape

- **D-189-01:** Phase 189 should produce one ranked Markdown audit artifact with YAML frontmatter and a weakest-first evidence ledger. The artifact should be built for downstream action, not as a generic consulting memo.
- **D-189-02:** Use score `0-4`, with confidence kept separate:
  - `0` = unknown, unproven, or broken trust boundary
  - `1` = must-fix adoption, operations, release, or maintainer risk
  - `2` = workable with material residual
  - `3` = good enough for current claims
  - `4` = strong/proven
- **D-189-03:** Every scored row must include: quality dimension, evidence refs, confidence (`High` / `Medium` / `Low`), practical consequence, highest-leverage fix, priority, route bucket, and owner phase (`190`, `191`, `192`, `193`, `future`, `external`, or `none`).
- **D-189-04:** Include a visible good-enough/N/A appendix. Do not manufacture fake concerns to make every checklist item look equally important.
- **D-189-05:** Include a QUAL-03 residual table covering at minimum SEED-005/reconnect, screenshot-regression confidence, external pilot boundaries, host staging ownership, known CI/example-app residuals, Hex/dependency notes, and legacy Nyquist/planning residuals.

### Authority Surface Hierarchy

- **D-189-06:** Use an evidence-first, scope-aware hierarchy. Planning defines what must be audited, but current-tree proof decides what is true.
- **D-189-07:** For runtime/source behavior claims, executable proof wins: source code, focused tests, named `mix verify.*` / `mix ci.*` bundles, current CI job behavior, and clean-tree verification evidence outrank prose and stale planning metadata.
- **D-189-08:** For release/version/package claims, `mix.exs`, `.release-please-manifest.json`, CHANGELOG/release metadata, Hex package truth, Release Please wiring, and doc-contract-guarded public docs must be reconciled. If these disagree, classify it as Phase 191 drift rather than choosing the convenient file.
- **D-189-09:** For public adopter guidance, README/guides/HexDocs are the surface users see, but they do not override current-tree proof when known stale. They define what must be repaired or honestly narrowed.
- **D-189-10:** For gate readiness, GitHub Actions required checks, stable CI job ids, `mix ci.all`, and branch-protection docs decide merge/release posture only after residual ownership is explicit.
- **D-189-11:** For scope and priority, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, milestone audits, and retrospectives decide intent, invariants, residual history, and owner phase. They are not shipped truth by themselves.
- **D-189-12:** Prefer named rerun bundles and `VERIFICATION.md`/`VALIDATION.md` evidence over audit prose when closing requirements. This carries forward the v1.22/v1.38 lesson that proof-chain completeness beats authored verdicts.

### Residual And Seed Triage Thresholds

- **D-189-13:** Use this trust-boundary taxonomy: `Blocker`, `Must fix before publish`, `Prove before claim`, `External-owned`, `Maintenance note`, `Backlog cleanup`, `Future seed`, `Good enough`, and `N/A`.
- **D-189-14:** `Blocker` is reserved for current false public claims, required release/branch-protection gates that are red from current code, broken storage/capture/query/auth correctness, security-sensitive footguns, or proof gaps that make an active requirement impossible to close honestly.
- **D-189-15:** `Must fix before publish` applies when a defect may not block Phase 189 planning but would make a new Hex release, README promise, upgrade story, or v1.39 closeout misleading.
- **D-189-16:** `Prove before claim` applies to screenshot stability, broad visual regression, real assistive-technology certification, external staging/pilot claims, and any other area where existing proof is narrower than the tempting claim.
- **D-189-17:** `External-owned` applies to host staging and real adopter pilot evidence unless there is named integrator-controlled evidence. Threadline may provide templates/rubrics, not pretend to operate third-party staging.
- **D-189-18:** `Maintenance note` applies to Hex auth-session warnings, dependency advisory output, and tool-environment notes unless they affect shipped code, package installability, or a required release gate.
- **D-189-19:** `Backlog cleanup` applies to legacy planning/Nyquist/frontmatter residuals unless active v1.39 traceability depends on them.
- **D-189-20:** SEED-005/reconnect should not be treated as unimplemented by default. It becomes must-fix only if current real socket-drop proof fails, disconnected/mutating affordances are unsafe, or the quality audit proves the current banner behavior is a trust-impacting operator failure mode.
- **D-189-21:** Screenshot regression confidence should remain `Prove before claim` unless the intended local runner/bootstrap passes. Do not make a broad screenshot stability claim from a local-only or failed-bootstrap command.
- **D-189-22:** Broad CI/example-app residuals block only when they are required release gates or current-code regressions. If targeted phase proof is green and the residual is inherited/out of scope, keep it visible without relabeling it green.

### v1.39 Narrowing Rule

- **D-189-23:** Use the authority-surface gate as the Phase 189 narrowing rule: a finding may constrain phases 190-193 only if it is backed by repo evidence and affects a current adoption, production, support, release, or maintainer authority surface already promised by v1.39.
- **D-189-24:** Route findings as:
  - `Must-fix now` if a current public claim, release gate, storage-schema contract, CI trust claim, or security/correctness invariant is false and cannot be honestly narrowed.
  - `Phase-owned` if it maps cleanly to SCHEMA in Phase 190, ADOPT in Phase 191, CI in Phase 192, or CLOSE in Phase 193.
  - `Future seed` if it is real but scope-expanding, such as external pilot depth, richer observability, UI regression hardening, or reconnect UX beyond current proof.
  - `N/A` / `Good enough` if the dimension is out of category, already proven for current claims, or intentionally unclaimed.
- **D-189-25:** Do not let Phase 189 broaden v1.39 into another UI/product/compliance milestone. Its job is to focus the remaining work, not maximize the number of findings.
- **D-189-26:** Phase 193 should use the Phase 189 ledger as its closeout input: verify what was fixed, preserve what was deferred, and recommend CI/CD depth, external adopter proof, observability, or hold.

### Ecosystem And Product Lessons To Apply

- **D-189-27:** Treat verification as a product surface. Named `mix verify.*` / `mix ci.*` entrypoints, doc contracts, release checks, and example-app proof are part of Threadline's adopter UX.
- **D-189-28:** Preserve Threadline's core audit-domain separation: capture, semantics, and exploration/operations are distinct. Do not collapse database activity auditing, audit history, operator evidence, and compliance guarantees into one vague quality bucket.
- **D-189-29:** Favor boring, explicit Elixir/Phoenix library idioms: optional dependencies stay optional, public claims are doc-contract guarded, current source/test proof beats stale prose, and host-owned seams stay host-owned.
- **D-189-30:** Learn from audit libraries across ecosystems: copy explicit actor/context metadata, queryable storage, migration/upgrade honesty, disable/maintenance paths, and human-readable history; avoid callback-only missed writes, opaque YAML/binary blobs, fragile process/thread/connection-local context, record-local history that disappears on delete, and association magic that grows beyond its support contract.
- **D-189-31:** Use Threadline brand/microcopy guidance for the audit artifact: say what failed, why it matters, and the next action in plain language. Avoid vague terms like "enterprise-grade", "robust", "next-generation", or generic severity theater.

### Claude's Discretion

Downstream agents may choose the exact audit artifact filename, row ordering, grouping names, and whether to include a short executive summary before the ledger. They should preserve the locked scoring rubric, authority hierarchy, triage taxonomy, routing rule, and no-scope-creep boundary above.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Authority

- `.planning/ROADMAP.md` — Phase 189 goal, success criteria, and v1.39 phase sequence.
- `.planning/REQUIREMENTS.md` — `QUAL-01`, `QUAL-02`, `QUAL-03`, v1.39 invariants, future requirements, and out-of-scope constraints.
- `.planning/PROJECT.md` — current v1.39 posture, shipped capability summary, decision log, and engineering baseline.
- `.planning/STATE.md` — current phase state, residual decisions, v1.39 decisions, and recent closeout classifications.
- `.planning/milestones/v1.38-MILESTONE-AUDIT.md` — immediate residual baseline and proof-limit precedent from the shipped v1.38 milestone.
- `.planning/MILESTONES.md` — shipped milestone summaries and known residual posture visible to project readers.
- `.planning/RETROSPECTIVE.md` — authority-surface, named rerun bundle, doc-contract, closeout-gate, and residual-classification lessons.

### Repo Authority And Verification Surfaces

- `mix.exs` — current package version, optional dependencies, `mix verify.*` aliases, `mix ci.all`, `verify.release`, `verify.example`, `verify.example_browser`, and release/docs package config.
- `.release-please-manifest.json` — current Release Please version truth.
- `release-please-config.json` — Release Please Elixir config and adoption-pilot extra-file version wiring.
- `.github/workflows/ci.yml` — stable CI job ids, required proof lanes, PgBouncer topology lane, docs/package/release-shape jobs, and current CI topology.
- `.github/workflows/release.yml` — canonical Hex publish workflow if release posture is assessed.
- `.github/workflows/hex-publish.yml` — legacy tag-only fallback that should not be confused with canonical release truth.
- `.github/workflows/flake-detection.yml` — opt-in/nightly flake proof lane.
- `CONTRIBUTING.md` — contributor gate, CI parity, host STG ownership, branch protection, and release runbook.
- `test/threadline/ci_topology_contract_test.exs` — CI topology, `ci.all`, support-lane proof, and STG marker contracts.
- `test/threadline/adoption_pilot_doc_contract_test.exs` — adoption-pilot version SSOT and Release Please extra-file guard.
- `test/threadline/release_artifact_contract_test.exs` — release package/docs/README/CONTRIBUTING contracts.
- `test/threadline/*doc_contract_test.exs` — public docs truth contracts that should be grouped by claim area during the audit.

### Residual And UI Proof Surfaces

- `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` — local-only screenshot-regression guard and platform-sensitive proof boundary.
- `examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts` — SEED-005 real socket-drop proof and reconnect/disconnected behavior context.
- `examples/threadline_phoenix/e2e/playwright.config.ts` — browser project matrix and screenshot/test configuration.
- `lib/threadline/operator_surface/ui.ex` — reconnect/offline banner and private operator UI shell behavior.
- `DESIGN-SYSTEM.md` — current private operator design-system projection and proof boundaries.
- `.planning/design-system-ledger.json` — stress/screenshot ownership and allowlist boundary.

### Product, Domain, And Prompt Corpus

- `prompts/audit-lib-domain-model-reference.md` — Threadline audit platform domain model, canonical nouns, capture/semantics/exploration split, and product principles.
- `prompts/threadline-elixir-oss-dna.md` — project-specific OSS verification, docs/contracts, release, example-app, security, and milestone hygiene patterns.
- `prompts/Audit logging for Elixir:Phoenix:Ecto- product strategy and ecosystem lessons.md` — cross-ecosystem audit-library lessons and footguns.
- `prompts/prior-art/oss-deep-research/elixir-opensource-libs-best-practices-deep-research.md` — Hex/ExDoc/dependency/optional-dependency/library-DX guidance.
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — GitHub Actions, Release Please, Hex, ExDoc, caching, matrix, and release automation guidance.
- `prompts/prior-art/oss-deep-research/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` — Elixir/Phoenix/Ecto operational and architecture footguns.
- `prompts/prior-art/oss-deep-research/ecto-best-practices-deep-research.md` — Ecto prefix, transactions, constraints, query, and schema behavior guidance.
- `prompts/prior-art/oss-deep-research/phoenix-live-view-best-practices-deep-research.md` — LiveView/state/UI proof and operator-surface architecture guidance when UI-adjacent findings are considered.
- `brandbook/index.html` — current brand voice, microcopy, motif, and "plain language over vague value prop" guidance.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `mix verify.*` aliases in `mix.exs` provide named proof bundles that the audit can cite instead of inventing new command vocabulary.
- `mix ci.all` already chains format, credo, warnings-as-errors compile, no-optional-deps compile, tests, trigger coverage, example app, doc contracts, and browser proof.
- `.github/workflows/ci.yml` already exposes stable job ids and separate lanes for format, credo, no-optional compile, tests/example/doc contracts, Hex evaluator, browser E2E, PgBouncer topology, ExDoc, Hex tarball, and release shape.
- Existing doc-contract tests are the right reusable mechanism for Phase 191 drift repair; Phase 189 should classify drift, not edit docs.
- `.planning/milestones/v1.38-MILESTONE-AUDIT.md` is the immediate residual seed list for the audit.
- `operator-screenshot-regression.spec.ts` already documents the local-only screenshot boundary.
- `operator-phase-178-uat.spec.ts` and `UI.shell/1` provide current reconnect proof context for SEED-005 triage.

### Established Patterns

- Threadline uses named verification bundles as authority over prose when claims are about current behavior.
- Public docs are treated as part of the library product and are guarded by doc contracts where possible.
- Release/version truth is automated through Release Please, `mix.exs`, CHANGELOG, Hex publishing workflows, and post-publish distribution sync.
- Host staging and external pilot evidence are explicitly integrator-owned unless there is named external evidence.
- Operator UI claims are bounded by source contracts, focused browser tests, local-only screenshot rules, and explicit residual classification.
- Planning artifacts preserve intent, scope, and residual ownership but must not be mistaken for executable proof.

### Integration Points

- Phase 190 should consume Phase 189 findings routed to `SCHEMA-*` and verify custom `storage_schema` behavior with executable tests.
- Phase 191 should consume version/docs/release drift rows and repair public adopter surfaces plus doc contracts.
- Phase 192 should consume CI/CD measurement and efficiency rows, baseline before changing cache/setup/topology, and avoid clever broad matrices before measurement.
- Phase 193 should consume the ranked ledger and residual table to close traceability and recommend the next milestone or hold.

</code_context>

<specifics>
## Specific Ideas

- User requested subagent-backed research across all four gray areas, with pros/cons/tradeoffs, ecosystem idioms, lessons from successful libraries/apps, DX/user-friendliness, architecture/DevOps/SRE lenses, and UI/UX/design-system/persona lenses where applicable.
- Four advisor researchers were used:
  - Audit scoring shape: recommended ranked evidence ledger plus residual triage.
  - Authority surface hierarchy: recommended evidence-first, scope-aware hierarchy.
  - Residual and seed triage thresholds: recommended trust-boundary taxonomy.
  - v1.39 narrowing rule: recommended authority-surface gate.
- The recommendations are intentionally coherent: score rows expose risk, authority hierarchy decides truth, triage taxonomy decides residual language, and the narrowing rule decides which later phase owns action.
- The audit artifact should be useful to maintainers under time pressure: one clear table, direct evidence links, plain consequence language, and one next action per row.

</specifics>

<deferred>
## Deferred Ideas

- External pilot proof remains signal-gated and external-owned unless a named adopter/integrator provides evidence.
- Host staging depth remains integrator-owned; Threadline owns templates/rubrics and modest in-repo pointers only.
- Broad screenshot-stability promotion remains deferred unless Phase 189/193 classifies UI regression confidence as a top trust risk and a future UI-REG phase is explicitly selected.
- Reconnect/offline UX beyond current proof remains a future seed unless the audit finds current operator behavior trust-breaking.
- Richer production observability remains a future seed unless the quality ranking makes production debuggability a top v1.40 recommendation.
- Runtime destructive redaction, compliance packs, legal hold, immutable archive guarantees, WAL/CDC backend, public Storybook, and public component API remain out of scope.
- No todo artifacts matched Phase 189, so none were folded or reviewed.

</deferred>

---

*Phase: 189-quality-baseline-and-authority-surface-audit*
*Context gathered: 2026-07-01*
