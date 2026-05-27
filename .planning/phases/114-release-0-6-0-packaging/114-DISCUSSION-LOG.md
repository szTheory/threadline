# Phase 114: Release 0.6.0 Packaging - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-27
**Phase:** 114-Release 0.6.0 Packaging
**Areas discussed:** Release narrative headline, CHANGELOG structure, ExDoc module grouping, Version literal sweep breadth, Publish-ready vs Hex publish
**Mode:** Research-backed synthesis (--all equivalent; user requested one-shot recommendations)

---

## Release narrative headline

| Option | Description | Selected |
|--------|-------------|----------|
| A) Stack catch-up / evaluator truth | "Packages v1.22–v1.24 so Hex evaluators aren't stuck on 0.5.0" | Partial (second clause) |
| B) Capability headline | Lead with Evidence plane + Audit.transaction/3 | Partial (primary content) |
| C) Milestone rollup | v1.25 adopter-ready with internal milestone names | |
| **Hybrid B+A (recommended)** | Adopter-outcome headline + explicit "packages since 0.5.0" | ✓ |

**User's choice:** Hybrid B+A — "adopter-ready release" label with capability surfaces named and packaging honesty clause.
**Notes:** Rejected C (violates semver-not-milestone adopter prose). Rejected A-alone (Phase 48 D-03 packaging-only anti-pattern). Ecosystem: Oban/Phoenix use thematic headlines; Carbonite/PaperTrail under-narrate. Threadline 0.3.0→0.5.0 precedent is strongest signal.

---

## CHANGELOG structure since 0.5.0

| Option | Description | Selected |
|--------|-------------|----------|
| A) By capability area | Evidence / Audited write path / Operator surfaces | ✓ |
| B) By internal milestone | v1.22 / v1.23 / v1.24 sections | |
| C) Flat Added/Changed only | No grouping | |

**Upgrade subsection:**

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal | deps bump + pointer to upgrade-path | |
| **Detailed** | migrations, auth seams, CLI, verification (~12–15 bullets) | ✓ |
| None | changelog narrative only | |

**User's choice:** Option A structure + detailed upgrade subsection.
**Notes:** Fold `[Unreleased]` into Changed. Include Deprecated (manual recipe) and Breaking (explicit none). Keep a Changelog categories. Phase 48 D-04 proof-surface grouping precedent.

---

## ExDoc module grouping

| Option | Description | Selected |
|--------|-------------|----------|
| A) New "Evidence & Audit" group | Combined bucket | |
| **B) Extend Core API + Evidence group** | Audit in Core API; Evidence namespace separate | ✓ |
| C) Minimal — Audit in Core API only | Evidence stays ungrouped | |

**User's choice:** Option B extended — also backfill Query, Investigation, ChangeDiff into Core API; add Evidence.Show, Health.Coverage, Policy.Show to Mix Tasks.
**Notes:** Matches domain layers (write path vs proof plane). Ecto/Phoenix use ungrouped core; Threadline chose journey-based groups in Phase 48. REL-02 requires Evidence-related public API grouped sensibly.

---

## Version literal sweep breadth

| Option | Description | Selected |
|--------|-------------|----------|
| A) Full adopter-facing sweep | includes how-threadline-works, upgrade-path | |
| **B expanded) REL-04 + install-snippet closure** | 10 files: mix.exs, CHANGELOG, README, 3 guides, 4 doc-contract tests | ✓ |
| C) SSOT-only | mix.exs + derive in tests | |

**User's choice:** Option B expanded (10 source files).
**Notes:** Full A over-scopes into Phase 115/117 narrative. Bare REL-04 minimum fails existing doc-contract topology (getting-started, operator-surface, release_artifact tests). Example app uses path dep — no bump.

---

## Publish-ready vs actual Hex publish

| Option | Description | Selected |
|--------|-------------|----------|
| A) Publish-ready only | verify.release green; manual tag/publish | Partial |
| B) Tag + Hex publish in phase | registry live is deliverable | |
| **C) Publish-ready + CONTRIBUTING refresh** | A plus fix stale v0.3.0 runbook literals | ✓ |

**User's choice:** Option C.
**Notes:** Phase 48 D-09 excludes mix hex.publish from verify.release. hex-publish.yml already tag-triggered. CONTRIBUTING stale v0.3.0 locked by release_artifact_contract_test — refresh is packaging SSOT. Post-phase maintainer gate documented.

---

## Claude's Discretion

- Exact headline wording within approved shape
- Dynamic vs hardcoded `~> 0.6` in doc-contract tests
- Governance schema ExDoc placement after doc build review
- adoption-pilot Hex row Done/Pending status

## Deferred Ideas

- how-threadline-works 0.6.0 historical bullet → Phase 115/117
- upgrade-path 0.5→0.6 minor bullet → Phase 117
- Example README fixes → Phase 116
- Pilot prep counts / evaluator one-pager → Phase 118
- Automated Hex publish in GSD phase scope → rejected
