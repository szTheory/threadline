# Phase 130: Verify & Planning Hygiene — Research

**Researched:** 2026-05-28  
**Phase:** 130 — verify-planning-hygiene  
**Status:** Complete

## Research Question

What do we need to know to plan Phase 130 well — Nyquist 125 finalize, v1.27 archive restore, and SUMMARY frontmatter convention (PLAN-01)?

## Key Findings

### 1. v1.29 init deleted v1.27 phase dirs without archive move

- Commit `46332ef` (`docs: start milestone v1.29 First-Hour Parity`) removed `.planning/phases/122–127/` from the active tree.
- Parent commit `46332ef^` (`15c35d6`) still contains full phase proof chains.
- `.planning/milestones/v1.27-phases/` **does not exist yet** — v1.25 precedent uses `.planning/milestones/v1.25-phases/{slug}/`.
- Phase 125 at `46332ef^` includes: `125-01/02-PLAN.md`, `125-01/02-SUMMARY.md`, `125-RESEARCH.md`, `125-REVIEW.md`, `125-VALIDATION.md` (draft), `125-VERIFICATION.md` (passed).

### 2. Nyquist 125 requires current-tree rerun, not attestation

- `125-VALIDATION.md` at restore point: `status: draft`, `nyquist_compliant: false`, `wave_0_complete: true`.
- Phase 126 precedent (`126-VALIDATION.md`): meta-phase finalizes target VALIDATION artifacts after **fresh targeted bundle** on current tree; session-close `mix ci.all` once in final plan.
- Phase 100 verification-backfill precedent: create/update VERIFICATION on current tree; flip VALIDATION frontmatter only after green bundle.
- **Charter blocker:** `v1_23_charter_doc_contract_test.exs` locks `**Active milestone:** **v1.28 External Pilot**` but `MILESTONE-ARC.md` now shows **v1.29 First-Hour Parity**. Tier 1 bundle will fail until test (and any locked PROJECT literals) align with v1.29 active milestone truth.

### 3. Tier 1 vs Tier 2 verification bundles (CONTEXT D-130-05–D-130-09)

| Tier | Scope | Commands | When |
|------|-------|----------|------|
| Tier 1 | 125 Nyquist sign-off | `mix test test/threadline/v1_23_charter_doc_contract_test.exs` + `mix verify.doc_contract` | Before flipping `125-VALIDATION.md` frontmatter |
| Tier 2 | Phase 130 session close | `mix ci.all` (once) | Plan 02 final task; recorded in `130-VERIFICATION.md` |

Do **not** run `mix ci.all` in Plan 01 — Phase 126 D-17 pattern.

### 4. SUMMARY frontmatter gap is gap-closure phases only

- Delivery phases 122–124 at `46332ef^` already have populated `requirements-completed: [DIST-*|CFG-*|DOC-*]`.
- Gap-closure phases 125–127 have `requirements-completed: []` — intentional for delivery but ambiguous without `gap-closure: true`.
- v1.27 audit overstated: "SUMMARY frontmatter lacks requirements-completed values (uses provides/affects pattern)" — applies to 125–127, not 122–124.
- Phase 128/129 SUMMARYs demonstrate v1.29 delivery pattern with hyphenated `requirements-completed`.

### 5. GAP ID namespace (D-130-15–D-130-19)

- `GAP-{phase}-{nn}` IDs populate `requirements-completed` on gap-closure SUMMARYs only.
- They are **not** milestone REQ IDs — do not affect "11/11 requirements satisfied."
- NYQ-01 (125 Nyquist finalize) is Phase **130** scope — not GAP-126-*.
- Phase 127 GAP IDs do **not** claim DOC-03.

### 6. Path updates required in same commit as Nyquist sign-off

- `REQUIREMENTS.md` NYQ-01 checkbox still references `.planning/phases/125-authority-surface-reconciliation/125-VALIDATION.md` — must move to archive path.
- `ROADMAP.md` Phase 130 SC #1 should reference archive path after restore.

### 7. Git restore commands

```bash
# Restore 125 minimum bundle to archive (from 46332ef^)
git show 46332ef^:.planning/phases/125-authority-surface-reconciliation/125-VALIDATION.md
git show 46332ef^:.planning/phases/125-authority-surface-reconciliation/125-VERIFICATION.md
git show 46332ef^:.planning/phases/125-authority-surface-reconciliation/125-01-SUMMARY.md
git show 46332ef^:.planning/phases/125-authority-surface-reconciliation/125-02-SUMMARY.md

# Verbatim SUMMARY archive for 122–124 (do not edit REQ IDs)
for phase in 122-release-distribution-truth 123-first-hour-config 124-adopter-doc-finish; do
  git ls-tree --name-only 46332ef^ .planning/phases/$phase/ | grep SUMMARY
done
```

### 8. Recommended plan split (2 plans, 2 waves)

| Plan | Wave | Requirements | Focus |
|------|------|--------------|-------|
| 130-01 | 1 | NYQ-01 (partial — finalize + path update) | Archive restore 125; charter v1.29; Tier 1 bundle; flip 125-VALIDATION |
| 130-02 | 2 | NYQ-01 (closeout), PLAN-01 | Convention SSOT; SUMMARY archive + GAP backfill; audit errata; 130-VERIFICATION; Tier 2 ci.all |

## Validation Architecture

Phase 130 is a **meta verification-backfill** phase (planning surfaces only). No product code changes except charter doc-contract test alignment.

### Framework

- **ExUnit** via Mix aliases (`verify.doc_contract`, `ci.all`)
- **Charter proxy:** `test/threadline/v1_23_charter_doc_contract_test.exs`
- **Planning grep contracts:** acceptance criteria on restored/convention files

### Sampling strategy

- **After Plan 01 tasks touching charter test:** Run Tier 1 bundle
- **After Plan 01 finalize task:** Confirm `125-VALIDATION.md` frontmatter green
- **After Plan 02 convention/backfill:** `rg` acceptance greps on GAP IDs and convention doc
- **Before phase complete:** Single `mix ci.all` (Tier 2)

### Wave 0

Existing infrastructure covers all requirements. No new test files beyond charter assertion updates for v1.29 active milestone.

### Nyquist compliance path

1. Restore `125-VALIDATION.md` as draft from git
2. Update charter test for v1.29
3. Run Tier 1 bundle on current tree
4. Record commands in `125-VALIDATION.md` → Commands Actually Used
5. Flip `nyquist_compliant: true`, `status: finalized`
6. Update NYQ-01 paths in REQUIREMENTS + ROADMAP (same commit)
7. Plan 02: convention + SUMMARY hygiene + session-close `mix ci.all`

## Risks

| Risk | Mitigation |
|------|------------|
| Split brain if 125 recreated under active `phases/` | Restore directly to `milestones/v1.27-phases/` only |
| Attestation-only Nyquist sign-off | Mandate Tier 1 rerun before frontmatter flip |
| Double `ci.all` | Tier 1 excludes ci.all; Tier 2 runs once in Plan 02 |
| Editing 122–124 SUMMARY REQ IDs | Verbatim copy only; backfill 125–127 only |

## Canonical References Consulted

- `.planning/phases/130-verify-planning-hygiene/130-CONTEXT.md`
- `.planning/milestones/v1.22-phases/100-phase-95-verification-backfill/100-01-PLAN.md`
- Git `46332ef^` phase 125–127 artifacts
- `.planning/milestones/v1.25-phases/` archive layout
- `test/threadline/v1_23_charter_doc_contract_test.exs`
- `.planning/MILESTONE-ARC.md`, `.planning/PROJECT.md`

## RESEARCH COMPLETE
