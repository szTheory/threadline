# Phase 104: Reference-Walkthrough Charter & Override Decision - Context

**Gathered:** 2026-05-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 104 records — in two specific planning files — the deliberate v1.22 → v1.23 framing override and locks v1.23-scoped non-goals so the next milestone-arc reread does not re-litigate the decision. The phase touches `.planning/PROJECT.md` and `.planning/MILESTONE-ARC.md` only. No code, no docs (`guides/`), no example-app edits, no test changes.

The phase delivers a single coherent doc-edit set across two files in one commit (D-01 below). After Phase 104 lands, a maintainer reopening the planning surface in six months can identify in <2 minutes (a) that v1.23 is the synthetic-first-adopter milestone, (b) why the v1.22 "real-adopter-first" rule was set aside, and (c) what would re-engage it.

</domain>

<decisions>
## Implementation Decisions

### Re-engagement trigger precision

- **D-01: "Sustained real-adopter signal" definition — three concrete shapes + explicit drive-by carve-out + soft-signal routing.** The override re-engages on the *first sustained* signal, defined as any of:
  - (a) a GitHub issue or discussion describing a live integration attempt against a real (not toy) application,
  - (b) a maintainer-confirmed pilot host running Threadline against their own production-shaped workload (even pre-production), or
  - (c) a procurement, security-review, or evaluation conversation citing Threadline by name.

  A single drive-by question, typo report, star burst, or "looks cool" comment does NOT qualify. Soft signals are routed to `.planning/v1.24-seeds/` as observational evidence rather than triggering re-engagement.

  **Why this shape:** Matches in-house Key Decision voice (v1.17 "after hundreds of adopters", v1.18 "once real adopters report row-cap pain"). Three concrete shapes give single-maintainer evaluability (<30 seconds at milestone-arc reread). Drive-by routing prevents the override from quietly going permanent *and* prevents noise-triggered rule-thrash. Same `.planning/v1.24-seeds/` routing vocabulary as Phase 110's (d)-design-gap rule — consistent across the milestone.

### PROJECT.md Key Decisions row structure

- **D-02: Single dense row, re-engagement clause bolded as the last sentence of the Rationale cell.** Matches the existing v1.17 / v1.18 / v1.21 / v1.22 row pattern exactly. Status cell uses `— Active (recorded Phase 104, v1.23, 2026-05-27)` — open-ended re-evaluation, not `✓ Shipped`. Row sits immediately below the v1.22 closeout rows in `## Key Decisions`.

  **Exact row text (paste verbatim into PROJECT.md):**

  ```
  | v1.23 deliberately overrides v1.22's "real-adopter feedback first" closeout rule and ships a synthetic-first-adopter walkthrough instead | No real adopter exists at v1.22 close, and the alternative is shipping nothing — a maintainer walking the reference app on a clean clone is the strongest available signal until external pressure arrives. Override scoped to v1.23 only and does not extend evidence subjects, Threadline-owned RBAC/tenancy DSLs, or `lib/` auth code. **Re-engages the v1.22 rule on first sustained real-adopter signal** (live-integration issue, maintainer-confirmed pilot host, or named procurement/security-review/evaluation conversation); drive-by interest routes to `.planning/v1.24-seeds/` rather than re-engaging the rule. | — Active (recorded Phase 104, v1.23, 2026-05-27) |
  ```

  **Why this shape:** Tyree–Akerman / mature-ADR pattern folds revisit-triggers inline in the decision body rather than splitting them into a separate field. Bolded `**Re-engages…**` clause makes the trigger operative (eye lands on it) without fragmenting the record. Density matches v1.17 / v1.18 rows — the right band; shorter would lose context, longer would bury the trigger.

### v1.23 non-goals home in PROJECT.md

- **D-03: New `**v1.23 non-goals:**` subsection inside the `## Current Milestone: v1.23 Realistic-Demo Walkthrough` block.** Placed immediately after the `**Key context:**` block, before `**Current State:**`. Bullet list (matches surrounding `**Target features:**` / `**Key context:**` bullet style). Mirrors Threadline house-style precedent: v1.6 / v1.7 / v1.8 / v1.9 / v1.10 shipped-milestone blocks all end with `**Non-goals (unchanged):**` prose.

  **Exact bullet content:**

  ```markdown
  **v1.23 non-goals:**

  - No new `Threadline.Evidence` subjects beyond the six shipped in v1.22 — walkthrough exercises shipped subjects only; new-subject pressure routes to v1.24 seeds, not in-milestone scope creep.
  - No Threadline-owned RBAC / tenancy DSLs and no `lib/` auth or domain-model code — the host-owned auth/tenancy boundary that has held since v1.15 is not relitigated; all auth and help-desk domain work lives in `examples/threadline_phoenix/`.
  - No rebrand of `examples/threadline_phoenix/` from "reference app" to "demo product" — seed data + clickable UI enables the walkthrough; it does not reposition the artifact. Sigra integration is not extended unless real signup/login surfaces a contract gap (handled via sub-phase 106b escape valve).
  ```

  **Why this shape:** Top-level `## Out of Scope` (line 287) stays untouched — it is the durable cross-milestone home (SIEM, full event sourcing, pgAudit replacement). Release-scoped non-goals belong attached to the milestone block. Promotion of durable items (e.g., RBAC/tenancy boundary, durable since v1.15) into the top-level list at v1.23 archive time is `/gsd-complete-milestone`'s job, not Phase 104's. REQUIREMENTS.md already carries the canonical traceable Out of Scope table.

### MILESTONE-ARC.md scope of edits

- **D-04: Targeted-fix sweep — status-field freshness + v1.23 row + strategic-thesis sentence — in one commit.** ADR-discipline carve-out: status-field updates are doc-hygiene (any author touching the file should sweep), not archive-narrative restructuring (which remains `/gsd-complete-milestone`'s job). The file is currently stale (`Updated: 2026-05-25`, `Active milestone: v1.22`) because the v1.22 archive sweep demonstrably missed these fields. Phase 104 corrects them in the same commit that adds the v1.23 row; alternative (Option A, minimal) leaves the file actively lying ("Active milestone: v1.22" right above a v1.23 row), which fails the <2-min cold-read criterion.

  **Exact edits required:**

  1. Line 3: `**Updated:** 2026-05-25` → `**Updated:** 2026-05-27`
  2. Line 4: `**Active milestone:** v1.22 — Policy / Evidence Plane` → `**Active milestone:** v1.23 — Realistic-Demo Walkthrough`
  3. Line 5: `**Next ranked candidate:** TBD after v1.22 closeout` → `**Next ranked candidate:** TBD after v1.23 closeout`
  4. Line 9 (Strategic thesis paragraph) — append a sentence noting the v1.22 → v1.23 override per CHARTER-02. Suggested append: *"v1.23 deliberately overrides v1.22's 'real-adopter-first' closeout rule because no real adopter has surfaced yet and the alternative is shipping nothing; the override re-engages on the first sustained real-adopter signal (see PROJECT.md Key Decisions)."*
  5. Option-record row 6 (Policy / compliance depth): `**Active (v1.22)**` → `**Shipped (v1.22)**`; tighten the "Why" cell to past-tense framing.
  6. Arc-order v1.22 row: status `**active**` → `**shipped**`.
  7. **New arc-order row for v1.23:** `| v1.23 | **active** | Realistic-Demo Walkthrough | Synthetic-first-adopter override of v1.22's real-adopter-first rule — no real adopter exists and the alternative is shipping nothing. | Walkthrough-surfaced design gaps as v1.24 seeds; first concrete fix-vs-defer rule in practice; durable boundary against scope creep tested under synthetic pressure. | No new Evidence subjects, no Threadline-owned RBAC/tenancy DSLs, no `lib/` auth or domain code, no "demo product" rebrand, no Sigra integration extension absent contract gap. Re-engages v1.22 rule on first sustained real-adopter signal. |`

  **NOT touched:** Option-record table's narrative re-ordering / new-rank insertion. That is archive-narrative work and stays with `/gsd-complete-milestone`.

### Boundary discipline note (preserves D-02 / D-16)

- **D-05: Record a one-line precedent rule in `104-SUMMARY.md` (written during execution) explaining why the MILESTONE-ARC.md sweep is not a D-02 violation.** The rule: *"Closeout-gate and first-milestone-phase work may correct demonstrably-stale status fields in archive-owned docs, but never restructure narrative sections or option/rank ordering — that remains `/gsd-complete-milestone`'s job."* This is a retrospective input for the next `/gsd-complete-milestone` checklist (so a future archive pass catches status fields).

### Claude's Discretion

- Whether to use Plan A (one plan, one commit) or Plan B (multiple atomic plans within one commit batch) is the planner's call. User specified "Lock all five as recommended" — implying single-commit framing for the doc-edit atom.
- Exact past-tense rewording of MILESTONE-ARC.md option-record row 6 "Why" cell is left to planner — must convey "v1.22 shipped" without restating v1.22 facts already captured in PROJECT.md.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Planning surface (the artifacts being edited)

- `.planning/PROJECT.md` — Source of truth for project identity, Current Milestone block, top-level Out of Scope, and `## Key Decisions` table (line 322). Phase 104 inserts a new row in Key Decisions (below line 350) and a new `**v1.23 non-goals:**` subsection in the Current Milestone block (around line 30, after `**Key context:**`).
- `.planning/MILESTONE-ARC.md` — Standing strategic-direction doc. Phase 104 sweeps the header (lines 3-5), updates strategic-thesis paragraph (line 9), flips the v1.22 status in both the option-record table and arc-order table, and adds a v1.23 arc-order row. Narrative restructuring is NOT in scope.
- `.planning/ROADMAP.md` — Source-of-truth for the framing override paragraph (line 12) and the Phase 104 success criteria. Cite verbatim where helpful; phrasing of the re-engagement trigger in `D-01` is tightened from ROADMAP's looser language.
- `.planning/REQUIREMENTS.md` — Source-of-truth for CHARTER-01 / CHARTER-02 / CHARTER-03 wording and the v1.23 Out of Scope table (already canonical). Do not duplicate REQUIREMENTS.md content into PROJECT.md; cross-reference where needed.

### In-house precedent for the row / non-goals shape

- `.planning/PROJECT.md` § Key Decisions, v1.17 row (operator-surface in-tree decision) — density and voice baseline for D-02.
- `.planning/PROJECT.md` § Key Decisions, v1.18 exports row — re-engagement-clause-inline-in-Rationale precedent ("Revisit in v1.20 once real adopters report row-cap pain on real incidents") — direct precedent for D-02.
- `.planning/PROJECT.md` § Key Decisions, v1.19 row — `— Active (opened 2026-05-07)` status-cell shape; precedent for D-02's `— Active (recorded Phase 104, v1.23, 2026-05-27)`.
- `.planning/PROJECT.md` § "Last milestone shipped: v1.6 / v1.7 / v1.8 / v1.9 / v1.10" blocks — `**Non-goals (unchanged):**` prose precedent for D-03.

### Domain reference (read once for cohesion, not edited)

- `prompts/audit-lib-domain-model-reference.md` — entity definitions and bounded contexts; Phase 104 does not touch domain code but the non-goals language ("no Threadline-owned RBAC / tenancy DSLs") is grounded here.
- `prompts/THREADLINE-GSD-IDEA.md` — project vision and constraints; informs strategic-thesis sentence in D-04.
- `prompts/threadline-elixir-oss-dna.md` — OSS quality bar and house style for milestone-block non-goals.

### Phase 105+ dependency (informational — do not edit in Phase 104)

- `.planning/ROADMAP.md` § Phase 105-110 — Phase 104's non-goals must not contradict the per-phase scope guards specified for Phases 105-110. Specifically: "`lib/` is read-only" for Phases 105-109, and the Sigra-extension carve-out via sub-phase 106b. Phase 104 documentation must mirror this carve-out exactly.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- None — Phase 104 is `.planning/`-only documentation work. No code is read, written, or referenced.

### Established Patterns

- **Decision-row density and voice** — v1.17 and v1.18 rows in `## Key Decisions` set the precedent for dense single rows with bolded operative clauses. Match this voice (terse, evidence-citing, comparator-driven) rather than inventing a new tone.
- **`— Active (recorded Phase N, vN.NN, date)`** status-cell shape — v1.19 row precedent. Open-ended status for decisions that are not yet "shipped" in a verification sense.
- **`**Non-goals (unchanged):**`** prose pattern in shipped-milestone blocks — v1.6 through v1.10 precedent. House style for milestone-scoped non-goals.

### Integration Points

- This phase produces ONLY doc edits. The downstream "integration" is that Phase 105's plan-phase will read the locked non-goals from PROJECT.md and use them as a scope guard. No code or test integration.

</code_context>

<specifics>
## Specific Ideas

**User-provided context (verbatim, 2026-05-27):**

> "i'd like to have like a realistic app of course it's just a demo app but realistic use cases, that uses threadline and it has fixtures/seeds realistic screens etc and u can look at the threadline UI for it all etc to get a good idea of how the admin UI works and that also kind of puts it through its paces the realistic main jtbd kind of get exercises in adoption scenario as well i dont have time to do a real saas using this yet and we have no real users so i want to get it as far along as we can with realistic-ish adoption."

This is the framing that makes the v1.22 → v1.23 override coherent: the maintainer is acting as a synthetic-but-realistic first adopter against a synthetic-but-realistic help-desk app. The Phase 104 charter language must honor this framing — "synthetic-first-adopter" (not "speculative widening") is the load-bearing phrase that distinguishes v1.23 from the rule it overrides.

**User decision:** "Lock all five as recommended" (D-01 through D-05).

</specifics>

<deferred>
## Deferred Ideas

- **Refine "sustained real-adopter signal" further at v1.24 charter time.** D-01's qualitative + carve-out shape is correct for v1.23. If the boundary is ever tested (e.g., a borderline pilot host appears mid-milestone), the v1.24 charter should refine — but Phase 104 does not pre-resolve this.
- **Promote durable v1.23 non-goals to top-level `## Out of Scope` at v1.23 archive time.** The RBAC/tenancy boundary has held since v1.15 and is effectively cross-milestone; the "demo product" non-rebrand is v1.23-scoped. `/gsd-complete-milestone` at v1.23 close should audit which non-goals promote and which retire.
- **Add a "MILESTONE-ARC.md status-field freshness check" to the `/gsd-complete-milestone` checklist.** Phase 104 surfaced that v1.22's archive demonstrably missed these fields. Future archive runs should sweep them automatically. (This is a `/gsd-complete-milestone` improvement, not Phase 104 work.)

</deferred>

---

*Phase: 104-reference-walkthrough-charter-override-decision*
*Context gathered: 2026-05-27*
