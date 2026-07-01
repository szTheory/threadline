# Phase 189: Quality Baseline and Authority-Surface Audit - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-01
**Phase:** 189-quality-baseline-and-authority-surface-audit
**Areas discussed:** Audit scoring shape, Authority surface hierarchy, Residual and seed triage thresholds, v1.39 narrowing rule

---

## Audit Scoring Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Ranked Evidence Ledger + Residual Triage | Weakest-first ledger with score, confidence, consequence, highest-leverage fix, owner phase, residual table, and good-enough/N/A appendix. | ✓ |
| OpenSSF-style 0-10 scorecard | Familiar OSS/security scorecard shape, but too generic and security-skewed for Threadline's schema/docs/DX trust problem. | |
| Must-fix risk register | Actionable owner/priority table, but collapses the quality baseline into a backlog and hides strengths/N/A decisions. | |
| Narrative senior review memo | Readable and good for leadership tradeoffs, but weaker for downstream planning traceability. | |
| Automated CI/OSS health report | Reproducible and CI-friendly, but misses adoption trust, operator UX, schema truth, and residual classification. | |

**User's choice:** User asked for subagent-backed research and one coherent recommendation set so they would not need to choose manually.
**Notes:** Advisor recommendation selected the ranked evidence ledger with score `0-4`, separate confidence, and explicit residual/N/A treatment.

---

## Authority Surface Hierarchy

| Option | Description | Selected |
|--------|-------------|----------|
| Evidence-first, scope-aware hierarchy | Current clean-tree executable proof or named rerun bundle decides behavior; release metadata decides version truth; public docs define adopter-facing drift; CI decides gate readiness; planning defines scope and residual history. | ✓ |
| Public/release surface first | Adopter-centric and exposes drift quickly, but unsafe when docs are known stale. | |
| CI-gate first | Simple merge/release policy, but broad red residuals can swamp scoped truth and environment failures can mislead. | |
| Planning/audit-ledger first | Preserves milestone intent and history, but is not executable proof and can create phantom closure. | |

**User's choice:** User requested a researched recommendation rather than a manual menu selection.
**Notes:** Retry advisor completed after a transient disconnect. Recommendation selected evidence-first hierarchy and specifically identified current `0.9.0` vs older `~> 0.6` public-doc drift as Phase 191 work.

---

## Residual and Seed Triage Thresholds

| Option | Description | Selected |
|--------|-------------|----------|
| Trust-boundary taxonomy | `Blocker`, `Must fix before publish`, `Prove before claim`, `External-owned`, `Maintenance note`, `Backlog cleanup`, plus future/good-enough/N/A routing. | ✓ |
| SRE-style reliability budget | Useful once real trend/pilot data exists, but synthetic without current adopter telemetry. | |
| OSS issue-label taxonomy | Familiar maintainer flow, but weaker as a release decision model. | |
| Strict all-red-is-release-blocking gate | Maximal caution, but overblocks v1.39 and turns local-only/inherited residuals into scope creep. | |

**User's choice:** User asked for a one-shot recommendation.
**Notes:** Recommendation classifies screenshots as `Prove before claim`, host staging as `External-owned`, SEED-005 as future unless current reconnect proof fails or unsafe disconnected behavior exists, and broad CI/example-app residuals as blockers only when required release gates or current-code regressions are involved.

---

## v1.39 Narrowing Rule

| Option | Description | Selected |
|--------|-------------|----------|
| Authority-surface gate | Findings constrain phases 190-193 only when repo-backed and tied to current adoption, production, support, release, or maintainer authority surfaces. | ✓ |
| Must-fix-only release gate | Smallest scope, but too narrow for QUAL-01/02 and may miss slow-burn trust drift. | |
| Scorecard + seed backlog | Captures broad learning, but risks consulting theater unless owner/routing rules are enforced. | |
| Full cross-repo quality audit | Finds more unknowns, but conflicts with consolidation scope and likely expands product/UI/compliance work. | |

**User's choice:** User asked for the recommendation that best serves the project vision.
**Notes:** Recommendation routes findings to `Must-fix now`, `Phase-owned`, `Future seed`, or `N/A` / `Good enough`; it explicitly prevents Phase 189 from widening v1.39 into a new product/UI/compliance milestone.

---

## Claude's Discretion

- Exact artifact filename and row grouping for the future quality audit are left to the planner/executor.
- Downstream agents may decide whether the audit artifact starts with a short executive summary before the ranked ledger.
- The locked pieces are the scoring rubric, authority hierarchy, residual taxonomy, and narrowing rule.

## Deferred Ideas

- External pilot proof, host staging depth, screenshot-lane promotion, reconnect/offline UX expansion, richer observability, runtime destructive redaction, compliance packs, WAL/CDC backend, public Storybook, and public component API stay outside Phase 189 unless future requirements explicitly select them.
