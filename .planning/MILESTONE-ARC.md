# Milestone Arc: Threadline

**Updated:** 2026-10-07 (v1.45 closeout passed; 1.0.0 released)
**Active milestone:** none. v1.45 1.0 API Contract (phases 231-237) is complete; 1.0.0 and distribution-docs PR #80 are shipped.
**Posture:** 1.0.0 marks completion of the current base-library ladder. Re-derive the project baseline before selecting more work; operator UI is eligible for consideration, not precommitted.

For the lasting intent, persona lenses, selection loop, quality/CI/release bar, and near/mid/long horizons, see `.planning/MILESTONE-GUIDE.txt`. This file is the concise live ranking. Where the guide and current evidence disagree, go by current state and evidence.

## Strategic thesis

The 2026-05-29 claim of "~92–95% done, default hold" measured the **adopter-facing docs and first-hour path**. It never measured whether capture behaves correctly on real table shapes. A re-derived baseline on 2026-09-25 found gaps that matter to any adopter:

- trigger SQL hardcodes the PK column `id` (`trigger_sql.ex:183-409`), so tables keyed any other way silently store `{"id": null}`
- per-table function names collide across Postgres schemas (redaction bypass)
- long table names raise a misleading error
- no property tests
- deferred dependency advisories and no audit gate
- nightly flake runs burn ~4,300 runner-min/month with no signal
- ~100 public functions without `@spec`

These are quality defects, not new scope. Under the guide §5 they justify milestones without adopter signal. New product scope still needs signal.

## Ladder to 1.0.0 (complete; original estimate was 6–9 weeks)

Actual at v1.45 close (2026-10-07, America/New_York): 1.0.0 shipped to Hex.pm; the milestone took five calendar days, with 7 phases, 47 plans, and 116 planned tasks. The milestone audit passed with disclosed review debt and no blockers. This finished the ladder ahead of the prior mid-to-late October estimate.

Re-estimate, 2026-09-30: two rungs remain. v1.42 took about 1 day and v1.43 took 4 days (10 phases). v1.44 and v1.45 carry more product-code work, so we budget about 1–2 weeks each. That puts 1.0.0 around mid-to-late October 2026, and mid-November is now the conservative upper bound.

| Rank | Version | Theme | Release | Status |
|------|---------|-------|---------|--------|
| 1 | v1.42 | Capture Correctness for Real Table Shapes | 0.11.0 | shipped 2026-09-26 |
| 2 | v1.43 | Supply Chain, CI Economy and Repo Hygiene | 0.11.1, 0.11.2 | shipped 2026-09-30 |
| 3 | v1.44 | Behavioral Depth: Properties, Twins, Telemetry | 0.12.0 | shipped 2026-10-02 |
| 4 | v1.45 | 1.0 API Contract | 1.0.0 | shipped; closeout passed 2026-10-07 |

Scope per rung: `.planning/MILESTONE-GUIDE.txt` §7 (canonical; don't duplicate it here).

After 1.0.0: operator UI is eligible for evaluation from maintainer UI/UX feedback; it is not the next milestone by default, and the paid critic stays parked unless un-parked. No next milestone is selected yet.

Signal-gated long horizon:
- GDPR erasure of captured rows
- per-table retention
- partitioned tables and RLS
- multiple repos
- external pilot (v1.28)
- compliance packs

## Activation rules

- At `/gsd-new-milestone`, re-derive the baseline and recommend the next evidence-backed outcome (guide §6). The 1.0.0 ladder is complete; do not infer a next milestone from the old rung order.
- At each close, mark the rung shipped, re-estimate the 1.0.0 date, and refresh this table and guide §7.
- **Do not** open compliance-pack / legal-hold / immutable-archive milestones without procurement pressure.
- **Do not** open Pow/bearer auth lane or second reference app without explicit demand.
- **Do not** make operator-UI design the next milestone by default; first re-derive the baseline and confirm the maintainer feedback that would justify it.

## History (condensed)

| Range | Theme |
|-------|-------|
| v1.0–v1.29 | Capture, semantics, exploration, integrations, distribution, first-hour parity (Hex 0.6.0) |
| v1.30–v1.34 | Adoption evidence automation, brand review, local Docker admin UI DX |
| v1.35–v1.40 | Brand identity, light mode, operator design system, page-by-page UI polish, quality baseline + storage schema (0.9.0), automated UI critic (parked) |
| v1.41 | Green, Clean, and Honest: real gates, 0.10.0–0.10.2 |
| v1.42 | Capture Correctness for Real Table Shapes: PK-agnostic, collision-free capture (0.11.0) |
| v1.43 | Supply Chain, CI Economy and Repo Hygiene: audit gate, toolchain pin, PII guard, measured CI cuts (0.11.1, 0.11.2) |

Full per-milestone record: `.planning/MILESTONES.md`. The superseded "hold" arc (2026-06-07) is in git history.
