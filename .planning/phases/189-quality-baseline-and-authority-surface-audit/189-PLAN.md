---
phase: 189-quality-baseline-and-authority-surface-audit
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md
autonomous: true
requirements:
  - QUAL-01
  - QUAL-02
  - QUAL-03
must_haves:
  truths:
    - "Maintainers can read one weakest-first quality audit that ranks Threadline adoption, production, support, release, and maintainer risks with repo evidence."
    - "Every ranked row has score 0-4, confidence High/Medium/Low, evidence refs, practical consequence, highest-leverage fix, priority, route bucket, and owner phase."
    - "The audit visibly separates must-fix findings from good-enough, low-priority, external-owned, maintenance, backlog, future-seed, and N/A dimensions."
    - "QUAL-03 residuals are triaged without overclaiming reconnect, screenshot, external pilot, host staging, CI/example-app, Hex/dependency, or planning proof."
    - "The v1.39 narrowing section constrains only repo-backed authority-surface findings to phases 190-193."
  artifacts:
    - path: ".planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md"
      provides: "Durable Phase 189 quality audit with YAML frontmatter, ranked evidence ledger, residual table, appendix, and v1.39 narrowing."
      contains: "Ranked Evidence Ledger"
  key_links:
    - from: ".planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md"
      to: ".planning/phases/189-quality-baseline-and-authority-surface-audit/189-CONTEXT.md"
      via: "Implements locked D-189 scoring, priority, authority, and narrowing decisions."
      pattern: "D-189-(01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)"
    - from: ".planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md"
      to: ".planning/REQUIREMENTS.md"
      via: "Covers QUAL-01, QUAL-02, and QUAL-03 explicitly."
      pattern: "QUAL-(01|02|03)"
    - from: ".planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md"
      to: ".planning/ROADMAP.md"
      via: "Routes Phase 189 findings to Phase 190, 191, 192, 193, future, external, or none."
      pattern: "(190|191|192|193|future|external|none)"
---

<objective>
Create the Phase 189 audit-only plan for QUAL-01, QUAL-02, and QUAL-03.

Purpose: Produce the blunt, repo-evidence quality ranking requested by the milestone so v1.39 narrows toward the weakest current adoption, production, support, release, and maintainer trust risks.
Output: `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` only.
</objective>

<execution_context>
@/Users/jon/.codex/gsd-core/workflows/execute-plan.md
@/Users/jon/.codex/gsd-core/templates/summary.md
</execution_context>

<context>
@CLAUDE.md
@.planning/STATE.md
@.planning/ROADMAP.md
@.planning/REQUIREMENTS.md
@.planning/PROJECT.md
@.planning/MILESTONES.md
@.planning/RETROSPECTIVE.md
@.planning/milestones/v1.38-MILESTONE-AUDIT.md
@.planning/phases/189-quality-baseline-and-authority-surface-audit/189-CONTEXT.md
@.planning/phases/189-quality-baseline-and-authority-surface-audit/189-RESEARCH.md
@.planning/phases/189-quality-baseline-and-authority-surface-audit/189-PATTERNS.md
@.planning/phases/189-quality-baseline-and-authority-surface-audit/189-VALIDATION.md
@.planning/phases/189-quality-baseline-and-authority-surface-audit/189-UI-SPEC.md
@mix.exs
@.release-please-manifest.json
@release-please-config.json
@.github/workflows/ci.yml
@.github/workflows/release.yml
@.github/workflows/hex-publish.yml
@.github/workflows/flake-detection.yml
@CONTRIBUTING.md
@README.md
@CHANGELOG.md
@test/threadline/ci_topology_contract_test.exs
@test/threadline/adoption_pilot_doc_contract_test.exs
@test/threadline/release_artifact_contract_test.exs
@examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
@examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts
@examples/threadline_phoenix/e2e/playwright.config.ts
@lib/threadline/operator_surface/ui.ex
@DESIGN-SYSTEM.md
@.planning/design-system-ledger.json
</context>

## Artifacts this phase produces

- `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md`

<schema_push_gate>
Schema push is not applicable for Phase 189. The phase scope is Elixir audit-only and the produced output set is the single Markdown artifact above. The schema scan found Ecto `storage_schema` references only as Phase 190 evidence-routing material, not Payload CMS, Prisma, Drizzle, Supabase, or TypeORM schema output. Do not add schema push, migration, source-code, or database tasks.
</schema_push_gate>

<dependency_graph>
Task 1 creates the audit artifact shell and authority inventory.
Task 2 depends on Task 1 because it populates the ranked ledger in the same artifact.
Task 3 depends on Tasks 1 and 2 because it completes residual routing, appends good-enough/N/A and v1.39 narrowing, and validates the final artifact.
All tasks are in one plan because they intentionally modify the same file.
</dependency_graph>

<source_audit>
| Source | ID | Requirement / Decision | Plan | Status | Notes |
|---|---|---|---|---|---|
| GOAL | Phase 189 | Produce the blunt repo-evidence quality ranking and use it to keep v1.39 focused on weakest adoption, production, support, and maintenance risks. | 01 | COVERED | Tasks 1-3 create and validate `189-QUALITY-AUDIT.md`. |
| REQ | QUAL-01 | Repo-evidence audit identifies weakest dimensions, confidence, consequence, and highest-leverage fixes. | 01 | COVERED | Task 2 owns the ranked ledger. |
| REQ | QUAL-02 | Separate must-fix risks from good-enough, low-priority, or N/A dimensions. | 01 | COVERED | Tasks 1 and 3 own taxonomy, appendix, and narrowing. |
| REQ | QUAL-03 | Triage SEED-005, screenshot confidence, external pilot, host staging, CI/example-app, Hex/dependency, and legacy Nyquist/planning residuals. | 01 | COVERED | Task 3 owns the residual table. |
| RESEARCH | Audit-only artifact | One Markdown artifact, no package installs, no implementation edits. | 01 | COVERED | Files modified list contains only `189-QUALITY-AUDIT.md`. |
| RESEARCH | Authority evidence map | Runtime/source proof, release/package truth, public docs, CI topology, residual history, and UI proof boundaries. | 01 | COVERED | Tasks read the named repo surfaces before scoring. |
| RESEARCH | Validation architecture | Static Markdown validation plus targeted proof only when current command evidence is cited. | 01 | COVERED | Task 3 verifies token structure and rerun/lower-confidence rule. |
| RESEARCH | Security domain | False authority, package/docs, storage-schema, UI/browser, host/external, and stale planning overclaims. | 01 | COVERED | Threat model below maps these risks to mitigations. |
| CONTEXT | D-189-01 D-189-02 D-189-03 D-189-04 D-189-05 | Artifact shape, score/confidence separation, row columns, Good Enough/N/A appendix, QUAL-03 residual table. | 01 | COVERED | Tasks 1-3 implement the artifact contract. |
| CONTEXT | D-189-06 D-189-07 D-189-08 D-189-09 D-189-10 D-189-11 D-189-12 | Authority hierarchy and proof precedence. | 01 | COVERED | Tasks 1-2 classify evidence before scoring. |
| CONTEXT | D-189-13 D-189-14 D-189-15 D-189-16 D-189-17 D-189-18 D-189-19 D-189-20 D-189-21 D-189-22 | Priority taxonomy and residual thresholds. | 01 | COVERED | Tasks 2-3 apply exact taxonomy and required residual rows. |
| CONTEXT | D-189-23 D-189-24 D-189-25 D-189-26 | v1.39 narrowing and downstream owner routing. | 01 | COVERED | Task 3 writes the narrowing section and phase-owner routing. |
| CONTEXT | D-189-27 D-189-28 D-189-29 D-189-30 D-189-31 | Verification as product surface, Threadline domain separation, boring Elixir idioms, ecosystem lessons, and Threadline microcopy. | 01 | COVERED | Tasks 1-3 enforce named proof bundles, domain-specific dimensions, and plain consequence/action language. |
| CONTEXT | Deferred Ideas | External pilot proof, host staging depth, broad screenshot promotion, reconnect UX expansion, observability, runtime redaction, compliance, WAL/CDC, public Storybook/API. | 01 | EXCLUDED | The plan records these only as residual/future/external classifications when evidence warrants; no implementation tasks are added. |
</source_audit>

<tasks>

<task type="auto">
  <name>Task 1: Create the audit artifact contract and evidence inventory</name>
  <files>.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md</files>
  <read_first>
    CLAUDE.md
    .planning/ROADMAP.md
    .planning/REQUIREMENTS.md
    .planning/STATE.md
    .planning/PROJECT.md
    .planning/milestones/v1.38-MILESTONE-AUDIT.md
    .planning/phases/189-quality-baseline-and-authority-surface-audit/189-CONTEXT.md
    .planning/phases/189-quality-baseline-and-authority-surface-audit/189-RESEARCH.md
    .planning/phases/189-quality-baseline-and-authority-surface-audit/189-PATTERNS.md
    .planning/phases/189-quality-baseline-and-authority-surface-audit/189-VALIDATION.md
    .planning/phases/189-quality-baseline-and-authority-surface-audit/189-UI-SPEC.md
    .planning/milestones/v1.38-phases/181-baseline-audit-and-guard-repair/181-BASELINE-AUDIT.md
  </read_first>
  <action>Create `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` with YAML frontmatter containing `phase: 189`, `artifact: quality-audit`, `audited: 2026-07-01`, `requirements: [QUAL-01, QUAL-02, QUAL-03]`, `status: draft`, and a `source_precedence` list for runtime/source proof, release/package truth, public docs, CI/gates, and planning/residual history. Add a title, one scope sentence stating this is an audit and routing artifact only, a score rubric for D-189-01 D-189-02 D-189-03, the exact priority taxonomy from D-189-13, and an evidence inventory grouped by current source/tests, release/package/docs, CI/gates, residual/UI proof, external/host proof, and planning history. Follow the mapped analog `.planning/milestones/v1.38-phases/181-baseline-audit-and-guard-repair/181-BASELINE-AUDIT.md` for frontmatter shape, scope/no-scope-creep language, evidence taxonomy setup, residual table style, and later-phase ownership pattern. Do not add implementation TODOs or rows that claim final scores before evidence is inspected.</action>
  <verify>
    <automated>bash -lc 'set -euo pipefail
f=.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md
test -f "$f"
for p in "artifact: quality-audit" "QUAL-01" "QUAL-02" "QUAL-03" "source_precedence" "runtime/source proof" "release/package truth" "public docs" "CI/gates" "planning/residual history" "Ranked Evidence Ledger" "Score" "Confidence" "0" "1" "2" "3" "4" "High" "Medium" "Low"; do rg -q -F "$p" "$f"; done
for p in "Blocker" "Must fix before publish" "Prove before claim" "External-owned" "Maintenance note" "Backlog cleanup" "Future seed" "Good enough" "N/A"; do rg -q -F "$p" "$f"; done
'</automated>
  </verify>
  <acceptance_criteria>
    - The artifact exists at `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md`.
    - YAML frontmatter names QUAL-01, QUAL-02, QUAL-03 and source precedence.
    - The artifact includes the exact score meanings for `0`, `1`, `2`, `3`, and `4`; confidence is named separately as `High`, `Medium`, or `Low`.
    - The artifact includes all exact priority labels: `Blocker`, `Must fix before publish`, `Prove before claim`, `External-owned`, `Maintenance note`, `Backlog cleanup`, `Future seed`, `Good enough`, and `N/A`.
    - The artifact says Phase 189 does not edit source code, README/guides, CI workflows, schemas, UI, screenshot baselines, release automation, or package metadata.
  </acceptance_criteria>
  <done>The audit artifact has a complete contract shell and evidence inventory that implements D-189-01 through D-189-13 without making unsupported final claims.</done>
</task>

<task type="auto">
  <name>Task 2: Populate the ranked evidence ledger weakest-first</name>
  <files>.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md</files>
  <read_first>
    .planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md
    .planning/phases/189-quality-baseline-and-authority-surface-audit/189-CONTEXT.md
    .planning/phases/189-quality-baseline-and-authority-surface-audit/189-RESEARCH.md
    .planning/phases/189-quality-baseline-and-authority-surface-audit/189-PATTERNS.md
    mix.exs
    .release-please-manifest.json
    release-please-config.json
    README.md
    CHANGELOG.md
    CONTRIBUTING.md
    .github/workflows/ci.yml
    .github/workflows/release.yml
    .github/workflows/hex-publish.yml
    .github/workflows/flake-detection.yml
    test/threadline/ci_topology_contract_test.exs
    test/threadline/adoption_pilot_doc_contract_test.exs
    test/threadline/release_artifact_contract_test.exs
    examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
    examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts
    lib/threadline/operator_surface/ui.ex
    DESIGN-SYSTEM.md
  </read_first>
  <action>Fill `## Ranked Evidence Ledger` as one Markdown table sorted weakest/highest-risk first. Use exactly these columns: `Rank`, `Quality dimension`, `Score`, `Confidence`, `Evidence refs`, `Practical consequence`, `Highest-leverage fix`, `Priority`, `Route bucket`, and `Owner phase`. Include repo-backed dimensions for storage-schema confidence routed to Phase 190, release/version/docs trust routed to Phase 191, CI/CD measurement and gate trust routed to Phase 192, closeout traceability routed to Phase 193 when applicable, and evidence-boundary dimensions for reconnect, screenshots, external pilot, host staging, Hex/dependency, and legacy planning residuals. For D-189-06 through D-189-12, runtime/source claims must cite source/tests or named Mix proof; release/package claims must reconcile `mix.exs`, `.release-please-manifest.json`, Release Please config, CHANGELOG, docs, and doc contracts; CI claims must cite job ids or `mix ci.*`; planning prose may define scope but not prove shipped behavior. For D-189-14 through D-189-22, assign only one locked priority label per row. For D-189-27 through D-189-31, keep dimensions domain-specific and use plain consequence/action language for adopter, operator, maintainer, release owner, or host integrator.</action>
  <verify>
    <automated>bash -lc 'set -euo pipefail
f=.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md
for p in "Ranked Evidence Ledger" "Rank" "Quality dimension" "Score" "Confidence" "Evidence refs" "Practical consequence" "Highest-leverage fix" "Priority" "Route bucket" "Owner phase"; do rg -q -F "$p" "$f"; done
for p in "190" "191" "192" "193" "storage_schema" "Release Please" "ci.all" "screenshot" "SEED-005" "host staging" "external pilot"; do rg -q -F "$p" "$f"; done
awk -F"|" "/^\\| [0-9]+ \\|/ { rows++; if (NF < 11) exit 1; if (\$4 !~ / [0-4] /) exit 1; if (\$5 !~ / (High|Medium|Low) /) exit 1 } END { exit rows > 0 ? 0 : 1 }" "$f"
'</automated>
  </verify>
  <acceptance_criteria>
    - The ledger is sorted by weakest/highest-risk first, not by subsystem convenience.
    - Every ledger row has all ten required columns and a numeric Score of `0`, `1`, `2`, `3`, or `4`.
    - Confidence values are only `High`, `Medium`, or `Low`; confidence is not encoded in the Score.
    - Every evidence ref is a file path, command, CI job id, package truth ref, or explicit static repo evidence note.
    - Any row relying on fresh command output records the exact command run in the row or lowers confidence instead of implying current proof.
    - No row routes work into phases 190-193 unless the evidence affects a current adoption, production, support, release, or maintainer authority surface already promised by v1.39.
  </acceptance_criteria>
  <done>The Ranked Evidence Ledger satisfies QUAL-01 and QUAL-02, implements D-189-06 through D-189-24, and narrows later-phase work from evidence rather than broad opinion.</done>
</task>

<task type="auto">
  <name>Task 3: Complete residuals, Good Enough/N/A appendix, narrowing, and validation</name>
  <files>.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md</files>
  <read_first>
    .planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md
    .planning/phases/189-quality-baseline-and-authority-surface-audit/189-VALIDATION.md
    .planning/phases/189-quality-baseline-and-authority-surface-audit/189-UI-SPEC.md
    .planning/milestones/v1.38-MILESTONE-AUDIT.md
    .planning/MILESTONES.md
    .planning/RETROSPECTIVE.md
    CONTRIBUTING.md
    examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts
    examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts
    lib/threadline/operator_surface/ui.ex
  </read_first>
  <action>Add `## QUAL-03 Residuals` with rows for `SEED-005/reconnect`, `screenshot-regression confidence`, `external pilot boundaries`, `host staging ownership`, `known CI/example-app residuals`, `Hex/dependency notes`, and `legacy Nyquist/planning residuals`. Each residual row must include current evidence, classification, owner, why it matters, and trigger to reopen. Add `## Good Enough / N/A Appendix` so proven or intentionally unclaimed surfaces are visible. Add `## v1.39 Narrowing` that lists findings routed to `190`, `191`, `192`, `193`, `future`, `external`, and `none`, with a one-line reason per route. Apply D-189-20 by not calling SEED-005 missing unless current reconnect proof fails or mutating affordances are unsafe. Apply D-189-21 by keeping broad screenshot stability as `Prove before claim` unless the intended local runner/bootstrap passed and the claim is narrowed to that runner. Apply D-189-25 and D-189-26 by using the ledger as downstream input without adding UI/product/compliance/source expansion. Run static validation; if any ledger or residual row cites fresh command evidence, rerun the exact command named in that row or reduce the row confidence.</action>
  <verify>
    <automated>bash -lc 'set -euo pipefail
f=.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md
git diff --check
test -f "$f"
for p in "QUAL-03 Residuals" "SEED-005/reconnect" "screenshot-regression confidence" "external pilot boundaries" "host staging ownership" "known CI/example-app residuals" "Hex/dependency notes" "legacy Nyquist/planning residuals" "Good Enough / N/A Appendix" "v1.39 Narrowing" "190" "191" "192" "193" "future" "external" "none"; do rg -q -F "$p" "$f"; done
allowed=.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md
git status --short --untracked-files=all -- . | awk -v a="$allowed" "{ p=substr(\$0,4); if (p != a) { print; bad=1 } } END { exit bad ? 1 : 0 }"
'</automated>
  </verify>
  <acceptance_criteria>
    - `## QUAL-03 Residuals` covers all seven required residuals exactly: SEED-005/reconnect, screenshot-regression confidence, external pilot boundaries, host staging ownership, known CI/example-app residuals, Hex/dependency notes, and legacy Nyquist/planning residuals.
    - `## Good Enough / N/A Appendix` is visible and contains rows rather than burying good-enough or not-applicable dimensions in prose.
    - `## v1.39 Narrowing` lists route outcomes for `190`, `191`, `192`, `193`, `future`, `external`, and `none`.
    - The artifact contains no planned edits to source code, README/guides, CI workflows, schemas, UI, screenshots, release automation, or package metadata.
    - `git status --short --untracked-files=all -- .` shows only `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` after execution.
  </acceptance_criteria>
  <done>QUAL-03 is covered, good-enough/N/A dimensions are visible, v1.39 is narrowed to evidence-backed authority-surface work, and validation proves the phase remained audit-only.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|---|---|
| Planning artifacts -> quality audit | Roadmap, requirements, state, and prior audits define scope and residual history but do not prove shipped behavior. |
| Repo proof -> audit classification | Source, tests, Mix aliases, CI job ids, release files, package metadata, docs, and browser specs are interpreted into scores and priorities. |
| Public authority surfaces -> downstream phases | README, Hex/package truth, ExDoc/guides, release automation, CI gates, and host/external evidence become owner-phase routes. |
| External/host evidence -> Threadline claims | Host staging and real pilot evidence are not controlled by this repo unless named integrator proof exists. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|---|---|---|---|---|
| T-189-01 | Repudiation | Ranked Evidence Ledger | mitigate | Require evidence refs and confidence on every row; planning prose cannot close runtime/source, release/package, CI, or external claims by itself. |
| T-189-02 | Tampering | Storage-schema proof classification | mitigate | Route storage-schema uncertainty to Phase 190 unless custom non-default schema behavior is proven from current source/tests or named commands; do not edit schema files in Phase 189. |
| T-189-03 | Repudiation | Release/package/docs claims | mitigate | Reconcile `mix.exs`, `.release-please-manifest.json`, Release Please config, CHANGELOG, Hex/package truth refs, public docs, and doc-contract tests before scoring release trust. |
| T-189-04 | Information Disclosure / Repudiation | UI/browser proof and host/external evidence | mitigate | Classify screenshots as `Prove before claim` when proof is local-only or failed; classify host staging and real pilot proof as `External-owned` without named integrator evidence. |
| T-189-05 | Denial of Service | v1.39 scope control | mitigate | Use the authority-surface gate from D-189-23 through D-189-25 so audit findings constrain only repo-backed adoption, production, support, release, or maintainer risks. |
| T-189-06 | Spoofing | Stale planning-prose closure | mitigate | Prefer named rerun bundles, `VERIFICATION.md`, `VALIDATION.md`, source/tests, and CI job ids over authored verdicts when closing claims. |
| T-189-SC | Tampering | npm/pip/cargo installs and schema push | mitigate | No package installs and no schema push are planned; Phase 189 produces only `189-QUALITY-AUDIT.md`. |
</threat_model>

<verification>
Overall phase checks:

1. `test -f .planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md`
2. `bash -lc 'set -euo pipefail; f=.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md; for p in "Ranked Evidence Ledger" "Rank" "Quality dimension" "Score" "Confidence" "Evidence refs" "Practical consequence" "Highest-leverage fix" "Priority" "Route bucket" "Owner phase" "QUAL-03 Residuals" "Good Enough / N/A Appendix" "v1.39 Narrowing"; do rg -q -F "$p" "$f"; done'`
3. `bash -lc 'set -euo pipefail; f=.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md; for p in "Blocker" "Must fix before publish" "Prove before claim" "External-owned" "Maintenance note" "Backlog cleanup" "Future seed" "Good enough" "N/A" "SEED-005/reconnect" "screenshot-regression confidence" "external pilot boundaries" "host staging ownership" "known CI/example-app residuals" "Hex/dependency notes" "legacy Nyquist/planning residuals"; do rg -q -F "$p" "$f"; done'`
4. `git diff --check`
5. `bash -lc 'set -euo pipefail; allowed=.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md; git status --short --untracked-files=all -- . | awk -v a="$allowed" "{ p=substr(\$0,4); if (p != a) { print; bad=1 } } END { exit bad ? 1 : 0 }"'`
6. If the audit cites fresh command evidence, rerun the exact command named in that row or lower confidence for that row.
</verification>

<success_criteria>
- The audit artifact ranks quality dimensions weakest-first with evidence, confidence, consequence, highest-leverage fix, priority, route bucket, and owner phase.
- Good-enough, low-priority, external-owned, maintenance, backlog, future-seed, and N/A dimensions are explicit.
- QUAL-03 residuals cover SEED-005/reconnect, screenshot-regression confidence, external pilot boundaries, host staging ownership, known CI/example-app residuals, Hex/dependency notes, and legacy Nyquist/planning residuals.
- Findings only constrain phases 190-193 when repo evidence affects a current v1.39 adoption, production, support, release, or maintainer authority surface.
- Phase 189 modifies only `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md`.
</success_criteria>

<output>
Create `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-SUMMARY.md` when done.
</output>
