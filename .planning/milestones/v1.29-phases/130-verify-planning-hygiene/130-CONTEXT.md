# Phase 130: Verify & Planning Hygiene - Context

**Gathered:** 2026-05-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Close non-blocking planning debt from v1.27 gap closure without widening product scope: finalize Nyquist sign-off on Phase 125 (`125-VALIDATION.md`), establish SUMMARY frontmatter convention (PLAN-01), and restore v1.27 planning artifacts to the milestone archive. No library API changes, no new adopter-facing features, no pilot pretense, no Hex semver bump.

Success requires green `mix verify.doc_contract` and session-close `mix ci.all` on the current tree at v1.29 closeout.

</domain>

<decisions>
## Implementation Decisions

### 125 artifact location (NYQ-01)

- **D-130-01:** Restore Phase 125 proof chain under `.planning/milestones/v1.27-phases/125-authority-surface-reconciliation/` — not a stub in active `.planning/phases/`. v1.29 init (`46332ef`) deleted v1.27 phase dirs without archiving; this phase completes the archive move v1.25 established.
- **D-130-02:** Update NYQ-01 path in `REQUIREMENTS.md` and Phase 130 success criteria in `ROADMAP.md` to the archive path in the **same commit** as the Nyquist sign-off.
- **D-130-03:** Restore from git at `46332ef^` (parent of v1.29 milestone init): at minimum `125-VALIDATION.md`, `125-VERIFICATION.md`, and both plan SUMMARYs. Do **not** recreate 125 under active `phases/` unless immediately moved — split brain with deleted 126–127.

### Nyquist 125 evidence strategy

- **D-130-04:** Verification-backfill shape (Phases 100–102 / 126 precedent): **fresh rerun on current tree** before flipping `nyquist_compliant: true`. Reject attestation-only from archived `125-VERIFICATION.md` — charter test may be red after v1.29 phases 128–129.
- **D-130-05 — Tier 1 (125 Nyquist bundle):** Record verbatim in `125-VALIDATION.md` → Commands Actually Used:
  ```bash
  mix test test/threadline/v1_23_charter_doc_contract_test.exs
  mix verify.doc_contract
  ```
- **D-130-06 — Prerequisite:** Update `test/threadline/v1_23_charter_doc_contract_test.exs` (and any PROJECT.md heading literals it locks) for **v1.29** active milestone truth before Tier 1 can pass. Small planning-surface hygiene — not reopening Phase 125 product scope. Today the test still locks `**Active milestone:** **v1.28 External Pilot**` while `MILESTONE-ARC.md` reflects v1.29.
- **D-130-07 — Tier 2 (Phase 130 session close):** Single `mix ci.all` per Phase 126 D-17 — satisfies ROADMAP SC #3 and v1.29 closeout; do **not** run `ci.all` twice.
- **D-130-08 — Frontmatter flip gate:** Set `125-VALIDATION.md` to `status: finalized`, `nyquist_compliant: true`, `wave_0_complete: true` only after Tier 1 green. Add retroactive note: "Phase 125 executed 2026-05-28; current-tree Nyquist backfill Phase 130 {date}."
- **D-130-09:** Tier 2 pointer recorded in `130-VERIFICATION.md`; optional cross-reference in 125 VALIDATION Nyquist Notes (126 session-close pattern).

### SUMMARY convention scope (PLAN-01)

- **D-130-10:** Create SSOT at `.planning/conventions/summary-frontmatter.md` documenting `requirements-completed`, `gap-closure`, GAP ID namespace, and 3-source audit rules.
- **D-130-11:** Archive v1.27 SUMMARYs to `.planning/milestones/v1.27-phases/{phase-slug}/*-SUMMARY.md` — **verbatim copy from `46332ef^` for 122–124** (already populated with DIST/CFG/DOC REQ IDs; do not edit).
- **D-130-12:** Backfill **125–127 SUMMARYs only** with GAP IDs and `gap-closure: true` (see mapping below). v1.27 audit overstated the gap — delivery phases 122–124 were already correct.
- **D-130-13:** Add audit errata paragraph to `.planning/milestones/v1.27-MILESTONE-AUDIT.md` tech_debt: delivery SUMMARYs had populated REQ IDs; ambiguity was gap-closure phases 125–127 only.
- **D-130-14:** Normalize to hyphenated **`requirements-completed`** everywhere (REQUIREMENTS PLAN-01 prose may note the alias).

### Gap-closure REQ mapping (125–127)

- **D-130-15:** Introduce **`GAP-{phase}-{nn}`** namespace for post-shipment gap-closure work. GAP IDs populate `requirements-completed`; they are **not** milestone REQ IDs and never increment "11/11 requirements satisfied."
- **D-130-16:** Add `gap-closure: true` to every gap-closure SUMMARY frontmatter. Distinguishes intentional empty-from-delivery from 107-style partial-plan `[]` within feature phases.
- **D-130-17 — GAP ID map (SSOT — copy into convention doc + v1.27 archive integration table):**

  | Phase / Plan | GAP IDs | Closes |
  |--------------|---------|--------|
  | 125-01 | GAP-125-01, GAP-125-02, GAP-125-03 | Charter doc contract; STATE.md; MILESTONE-ARC.md |
  | 125-02 | GAP-125-04 | ROADMAP closeout + green verify bundle |
  | 126-01 | GAP-126-01 | 122-VALIDATION Nyquist sign-off |
  | 126-02 | GAP-126-02 | 123-VALIDATION Nyquist sign-off |
  | 126-03 | GAP-126-03 | 124-VALIDATION Nyquist sign-off |
  | 127-01 | GAP-127-01, GAP-127-03 | Example `:schemas` mount; row-history reification proof (D-14) |
  | 127-02 | GAP-127-02 | getting-started §9 mount parity |

- **D-130-18:** Phase 127 GAP IDs do **not** claim `DOC-03` — docs satisfied in Phase 124; 127 closes **runnable demonstration** gap only (per v1.27-REQUIREMENTS integration table).
- **D-130-19:** NYQ-01 (125 Nyquist finalize) is Phase **130** scope, not GAP-126-* — do not conflate.

### Phase scope boundary

- **D-130-20 — In scope:** v1.27 archive restore (125 full + SUMMARY archive); charter test v1.29 alignment; 125-VALIDATION finalize; convention doc; 125–127 SUMMARY backfill; v1.27 audit errata; REQUIREMENTS NYQ-01/PLAN-01 checkboxes; 130-VERIFICATION.md; session-close `mix ci.all`.
- **D-130-21 — Out of scope:** Reopening v1.27 milestone; full PLAN/RESEARCH restore for 122–127; inventing DIST/CFG/DOC REQ IDs for gap-closure; product/library changes; v1.28 pilot; Hex bump.

### Claude's Discretion

- Exact convention doc section headings and examples
- One vs two plan split (130-01 Nyquist + archive, 130-02 convention + SUMMARY backfill — or combined)
- Exact charter literal strings after v1.29 closeout posture
- Whether to restore 126–127 VALIDATION.md to archive for reference (recommended but not blocking NYQ-01)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements and assessment
- `.planning/REQUIREMENTS.md` — NYQ-01, PLAN-01
- `.planning/ROADMAP.md` — Phase 130 success criteria
- `.planning/threads/2026-05-28-milestone-next-step-post-v1.27.md` — Nyquist 125 + SUMMARY frontmatter tech debt
- `.planning/milestones/v1.27-MILESTONE-AUDIT.md` — partial Nyquist (125 draft); SUMMARY frontmatter finding (errata in this phase)
- `.planning/milestones/v1.27-REQUIREMENTS.md` § Post-shipment gap closure — GAP ID semantic anchor

### Nyquist / verification-backfill precedents
- `.planning/milestones/v1.22-phases/100-phase-95-verification-backfill/` — verification-backfill phase shape
- `.planning/milestones/v1.22-phases/103-authority-surface-reconciliation-and-milestone-re-audit/103-02-SUMMARY.md` — VALIDATION finalize + named bundle
- Git commit `46332ef^` — last tree with v1.27 phase dirs before v1.29 init deletion
- Git commit `229d908` — Phase 125 execution + VERIFICATION passed

### SUMMARY / traceability precedents
- `.planning/milestones/v1.11-phases/36-planning-matrix-hygiene/36-CONTEXT.md` — SUMMARY backfill + Nyquist hygiene
- `.planning/phases/128-readme-phx-gen-auth-mount-parity/128-01-SUMMARY.md` — delivery `requirements-completed` pattern
- `.planning/phases/129-walkthrough-truth/129-01-SUMMARY.md` — v1.29 delivery traceability pattern
- `.planning/milestones/v1.23-phases/104-reference-walkthrough-charter-override-decision/104-VERIFICATION.md` — REQUIREMENTS checkbox lag vs SUMMARY authority

### Project DNA and verification entrypoints
- `prompts/threadline-elixir-oss-dna.md` — three-source traceability; Nyquist deferred debt policy; named `mix verify.*` entrypoints
- `prompts/THREADLINE-GSD-IDEA.md` — correct-by-default; verification as product surface
- `CLAUDE.md` — verify entrypoints; doc contract tests
- `.planning/RETROSPECTIVE.md` — trust named bundle not audit prose; verification-backfill phase shape; archive on milestone complete

### Machine-checkable planning surfaces
- `test/threadline/v1_23_charter_doc_contract_test.exs` — charter proxy (update for v1.29 in this phase)
- `mix.exs` — `verify.doc_contract`, `ci.all` alias definitions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `v1_23_charter_doc_contract_test.exs` — machine-checkable planning authority proxy; extend for v1.29 milestone arc
- Phase 126 VALIDATION pattern (git `46332ef^`) — Tier 1 targeted bundle + session-close `ci.all`
- Phase 128/129 SUMMARY frontmatter — delivery-phase `requirements-completed` examples for convention doc

### Established Patterns
- **Verification-backfill:** Rerun named bundle on current tree → flip VALIDATION frontmatter → record commands (Phases 100–102, 126)
- **Milestone archive:** Shipped phase proof under `.planning/milestones/v{X}-phases/` (v1.25 precedent)
- **Three-source audit:** REQUIREMENTS ↔ SUMMARY `requirements-completed` ↔ VERIFICATION.md
- **Gap vs delivery IDs:** DIST/CFG/DOC/WALK for adopter reqs; GAP-* for post-shipment gap-closure only

### Integration Points
- NYQ-01 path update in `.planning/REQUIREMENTS.md` traceability table
- v1.27 audit tech_debt errata in `.planning/milestones/v1.27-MILESTONE-AUDIT.md`
- Optional `MILESTONES.md` v1.27 tech-debt note when 125 Nyquist closed

</code_context>

<specifics>
## Specific Ideas

### Ecosystem lessons applied
- **Oban/Phoenix/Ecto release hygiene:** CI green on current SHA, not archived run logs — Tier 1 rerun mandatory.
- **Accrue phase 36:** Surgical SUMMARY backfill where field was wrong; don't full-restore entire milestone trees unnecessarily.
- **Sigra phase 50:** Never merge-theater `nyquist_compliant: true` — owner, date, pointer, trigger to reopen.
- **v1.29 init footgun:** Deleting `phases/122–127` without `milestones/v1.27-phases/` move — this phase completes the archive Accrue/Scrypath DNA expects at milestone close.

### Coherent execution package
1. Restore 125 + SUMMARY archive under `milestones/v1.27-phases/`
2. Charter test v1.29 alignment → Tier 1 bundle → finalize 125-VALIDATION
3. Convention doc + GAP ID backfill for 125–127 SUMMARYs + audit errata
4. Single session-close `mix ci.all` → 130-VERIFICATION → REQUIREMENTS checkboxes

</specifics>

<deferred>
## Deferred Ideas

- Full PLAN/RESEARCH/VALIDATION restore for phases 122–124 and 126–127 to archive — optional reference only; not blocking NYQ-01/PLAN-01
- Re-audit entire v1.27 milestone — errata sufficient; v1.27 already passed
- gsd-audit-milestone tooling changes for GAP ID parsing — convention doc is sufficient for Phase 130; tooling can follow
- PROJECT.md duplicate milestone blocks cleanup — noted in v1.27 audit; separate doc-truth pass
- v1.28 external pilot — signal-gated; out of scope

### Reviewed from Phase 128/129
- Nyquist 125 + SUMMARY frontmatter — **now in scope** (this phase)

</deferred>

---

*Phase: 130-verify-planning-hygiene*
*Context gathered: 2026-05-28*
