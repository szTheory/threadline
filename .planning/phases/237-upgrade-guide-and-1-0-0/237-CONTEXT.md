# Phase 237: Upgrade Guide and 1.0.0 - Context

**Gathered:** 2026-10-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Give adopters starting on 0.11.x or 0.12.x one clear path to Threadline 1.0.0, with every breaking change and deprecation represented in the human-owned CHANGELOG, mapped to the upgrade guidance, and covered by a contract test. Rehearse the exact 1.0.0 version selection and release artifact checks before landing the milestone as one conventional feat! squash. The phase ends at the maintainer-controlled landing and publication boundary: push, merge, and the production-hex publish each require a separate explicit maintainer grant. No new product capability or operator-UI work is in scope.

</domain>

<decisions>
## Implementation Decisions

### Upgrade path and CHANGELOG coverage

- **D-01 — Keep one 1.0 upgrade guide for both supported starting lines.** A 0.11.x adopter gets a concise conditional preflight for the three 0.12.0 breaking changes (capture-option shape, telemetry actor metadata, and health-error metadata); it states the required action and links to the 0.12.0 CHANGELOG / upgrade-path details. A 0.12.x adopter skips that preflight. Then both readers follow the seven numbered 1.0 steps named in DOCS-03. Preserve the existing one-off 0.11 trigger migration as a prior-upgrade prerequisite if an adopter skipped it; do not imply that any of the 1.0 changes requires trigger regeneration.

- **D-02 — Make the seven step categories cover every actual 1.0 CHANGELOG break and deprecation.** The listed categories are facade/API use, bounded row history, Page, lookup behavior, action association, PostgreSQL floor, and deprecations. Some categories may map to multiple CHANGELOG entries; no current Unreleased breaking-change or deprecation entry may be left unmapped. The conditional 0.11 preflight separately covers the three 0.12.0 breaking entries.

- **D-03 — Use stable, hidden change IDs as the document contract.** Put machine-readable IDs in invisible HTML comments beside relevant human-owned CHANGELOG entries and guide steps. The focused ExUnit contract compares the scoped ID sets for 0.12.0 prerequisites and 1.0 changes, and fails on a missing, extra, duplicate, or unmatched ID. Keep the guide and human-owned CHANGELOG hand-written; do not introduce a manifest or generated migration prose. Give the new contract test an explicit partition weight.

### Release-please 1.0.0 rehearsal and landing

- **D-04 — Extend the existing disposable-clone rehearsal to prove the exact committed 1.0.0 candidate.** The rehearsal must validate that candidate HEAD has a conventional feat! subject, exactly one Release-As: 1.0.0 footer, and release-please-config.json sets bump-minor-pre-major to false. It must use that footer as the simulated target, assert 1.0.0 (and reject 0.13.0), then run the existing bumped-artifact contracts inside the disposable clone. Run it against the committed candidate squash before push or merge. The report must call this a local artifact rehearsal, not a live Release Please invocation; the generated Release PR/run after landing supplies the live-action evidence.

- **D-05 — Preserve the maintainer-only release boundary.** Re-check the latest-lane pins and the PostgreSQL 15 minimum lane as part of landing evidence. Push, merge, and production-hex publication remain separate operations, each requiring an explicit maintainer grant. Hex publication is one-way; do not let a green rehearsal or CI result stand in for those grants.

### the agent's Discretion

- Exact stable-ID spellings, Markdown comment syntax, and ExUnit module/file placement, provided the scoped ID sets are exact and diagnostic failures identify the missing or extra change.
- The precise prose and headings for the seven steps and the conditional 0.11 preflight, provided each required action is explicit and the guide follows the existing upgrade-guide voice.
- The isolated mechanics for producing a committed candidate squash for rehearsal, provided it does not push, merge, publish, or mutate the user's real worktree outside the approved Phase 237 files.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope, requirements, and current state
- `.planning/ROADMAP.md` § Phase 237 — the seven numbered step categories, exact release goal, and maintainer-grant boundary.
- `.planning/REQUIREMENTS.md` § DOCS-03 and REL-01–REL-03 — guide coverage and release acceptance evidence.
- `.planning/PROJECT.md` § Current Milestone and § Key Decisions — current 0.12.0 line, 1.x stability policy, and the human-owned/generated CHANGELOG split.
- `.planning/STATE.md` — current workflow position; update at close.
- `.planning/MILESTONE-GUIDE.txt` §7 and release/quality bar — the 1.0.0 rung and one-way Hex release discipline.
- `.planning/MILESTONE-ARC.md` — milestone ranking; its active-milestone header is stale at v1.44, so the current ROADMAP and REQUIREMENTS govern Phase 237 until milestone close updates the arc.
- `.planning/phases/235-stability-contract-and-adopter-guides/235-CONTEXT.md` § D-01 and D-08 — settled 1.x promises, answer-first guide voice, and reader-job orientation.
- `.planning/phases/236-support-floor-and-partition-weights/236-VERIFICATION.md` — PostgreSQL 15 minimum-lane evidence and complete weighted test inventory.

### Existing adopter documents and contracts
- `guides/upgrading-to-0.11.md` — procedural template, trigger-regeneration procedure, and voice.
- `guides/upgrade-path.md` — existing 0.11.x → 0.12.x actions and source-checked support policy.
- `guides/stability.md` — 1.x compatibility and deprecation promises.
- `CHANGELOG.md` — human-owned release notes; current Unreleased breaks/deprecations and the three 0.12.0 breaking changes.
- `CHANGELOG-GENERATED.md` — release-please-owned notes; not the adopter-facing human source.
- `test/threadline/changelog_contract_test.exs` and `test/threadline/upgrading_to_0_11_doc_contract_test.exs` — existing changelog/guide contract patterns.
- `test/threadline/guide_graph_contract_test.exs` and `test/threadline/release_distribution_doc_contract_test.exs` — guide registration and distribution boundary contracts.
- `test/partition_weights.txt` — required inventory for the new contract test.

### Release configuration and verification
- `release-please-config.json` and `.release-please-manifest.json` — current release-please ownership and package version.
- `bin/verify-bump-rehearsal` and `mix.exs` — current named rehearsal entrypoint; the helper currently derives the next minor (0.12.0 → 0.13.0), so it does not yet prove the required 1.0.0 target or the landing footer.
- `.github/workflows/release.yml` and `.github/workflows/ci.yml` — live release action, publish boundary, required CI lanes, and latest-pin checks.
- `CONTRIBUTING.md` § Ongoing releases — explicit maintainer grants and release-please operating procedure.

### Product and OSS intent
- `AGENTS.md` — architecture boundaries, zero-human-verification default, and research-first rule.
- `prompts/audit-lib-domain-model-reference.md` — domain vocabulary and bounded contexts.
- `prompts/THREADLINE-GSD-IDEA.md` — project vision and non-goals.
- `prompts/threadline-elixir-oss-dna.md` — named verification gates, doc contracts, and release integrity.
- `prompts/Threadline Brand Book.txt` — current voice: precise, composed, clear, and calm.
- `prompts/prior-art/SOURCE-CANONICAL.md` — canonical prior-art map.
- `prompts/prior-art/oss-deep-research/elixir-oss-lib-ci-cd-best-practices-deep-research.md` — Elixir library release and CI practice.
- `https://github.com/googleapis/release-please#how-do-i-change-the-version-number` — Release-As commit-body behavior and squash guidance.
- `https://ex-doc.hexdocs.pm/ExDoc.html` — ExDoc guide extras behavior.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `guides/upgrade-path.md` already explains all three 0.11.x → 0.12.x required actions, so the new guide can summarize them conditionally and link to the canonical details.
- `test/threadline/changelog_contract_test.exs` already protects the human/generated changelog ownership boundary and release-note ordering.
- `test/threadline/upgrading_to_0_11_doc_contract_test.exs` demonstrates file-based ExUnit checks for ordered migration steps, locked facts, and banned planning vocabulary.
- `bin/verify-bump-rehearsal` already creates a disposable clone, simulates release artifacts, runs contracts, and proves the real tree stayed unchanged.
- The release workflow already gates publication on the production-hex required-reviewer environment.

### Established Patterns
- Keep adopter prose human-owned in CHANGELOG.md; release-please writes CHANGELOG-GENERATED.md.
- Prefer small source-aligned ExUnit contracts with specific failure messages; partition every new test file.
- Use named mix verify.* / mix ci.* entrypoints and keep release-only rehearsal separate from mix ci.all.
- Use answer-first headings and concise, task-oriented prose; do not repeat long installation procedures already documented elsewhere.

### Integration Points
- Register guides/upgrading-to-1.0.md in ExDoc extras and the existing guide graph.
- The guide contract must compare its change IDs against the relevant CHANGELOG sections, including deprecations and the 0.11-only 0.12.0 preflight.
- The changed release-please flag must be reflected in changelog-contract expectations; keep the 1.0.0 rehearsal bound to the candidate HEAD and its footer.
- Preserve the CI min lane at PostgreSQL 15 and re-check latest-lane pins before landing.

</code_context>

<specifics>
## Specific Ideas

Use one guide with a version-gated 0.11.x preflight, followed by exactly the seven numbered 1.0 steps already enumerated in DOCS-03. It should say plainly that 1.0 requires no trigger regeneration, while linking back to the prior 0.11 trigger procedure only for adopters who never completed it. The source-level contract should prove total coverage without exposing planning vocabulary in published docs.

The release rehearsal must be run on the committed candidate squash before external release actions. Its success proves the simulated 1.0.0 artifact tree passes local gates; it does not prove a live Release Please action occurred. The milestone ARC currently says v1.44 is active, but current phase truth is v1.45 in ROADMAP/REQUIREMENTS; refresh the ARC at milestone close.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the Phase 237 scope.

</deferred>

---

*Phase: 237-Upgrade Guide and 1.0.0*
*Context gathered: 2026-10-07*

