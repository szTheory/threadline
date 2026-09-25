# Phase 201: Rendered Output - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-13
**Phase:** 201-rendered-output
**Areas discussed:** Browser metadata boundary, Stress-harness vocabulary, Already-landed cleanup, Regression-proof depth

---

## Browser Metadata Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Remove only `data-jtbd` | Smallest diff and satisfies the roadmap's explicit example grep, but leaves adjacent `EF*` and `P*` planning taxonomies in the DOM. | |
| Replace all three with neutral `data-testid` hooks | Removes roadmap codes while keeping copy-independent selectors, but creates replacement browser metadata and unnecessary coupling where semantic selectors already exist. | |
| Remove all three with behavior-first selectors | Remove `data-earned-flow`, `data-persona`, and `data-jtbd`; use roles, labels, routes, existing IDs/test IDs, and add a neutral test ID only for a proven uniqueness gap. | ✓ |

**User's choice:** Accepted the complete recommendation package.
**Notes:** RENDER-02's broad no-provenance rule controls; the roadmap's `data-jtbd` grep is a minimum probe, not a narrowing. Research emphasized idiomatic `Phoenix.LiveViewTest` helpers and Playwright's preference for user-facing locators.

---

## Stress-Harness Vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Layered maintainer vocabulary | Preserve durable testing mechanics and exact artifact identifiers while removing planning chronology, roadmap codes, and provenance metadata. | ✓ |
| Fully adopter-readable rewrite | Recast the dev/test harness as product UI, reducing jargon but weakening ledger/fixture traceability and expanding copy/visual risk. | |
| Exact internal vocabulary everywhere | Preserve every old label for direct mapping, including phase and taxonomy leakage. | |

**User's choice:** Accepted the complete recommendation package.
**Notes:** `/audit/__stress` serves maintainers and contributors. Stable story/fixture/ledger/cohort identity and testing terms remain valid; phase/milestone/decision/JTBD chronology does not. Current `brandbook/brand-book.md` supersedes older brand guidance.

---

## Already-Landed Cleanup

| Option | Description | Selected |
|--------|-------------|----------|
| Accept and guard the landed cleanup | Attribute the correct CSS and rendered-copy changes to their granular commits, retain current HEAD, close only the residual inventory, and add regression protection. | ✓ |
| Surgically revert and reapply | Restore then re-remove the vocabulary to create phase-local commits, adding inverse history and temporary release risk. | |
| Audit-only ratification | Record what landed but make no residual code or permanent guard changes, leaving RENDER-02 incomplete. | |

**User's choice:** Accepted the complete recommendation package.
**Notes:** `5752e357` owns CSS comment cleanup, `1a5fbef2` owns rendered stress copy/cohort cleanup, and the relevant blobs are byte-identical in integration commit `18fe87f5`. Revert/replay would worsen history and bisectability.

---

## Regression-Proof Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Known-offender assertions only | Fast and narrow, but cannot catch the same vocabulary at a new source location. | |
| Permanent whole-DOM and pixel baselines | Broad evidence, but freezes incidental LiveView markup and introduces environment-sensitive maintenance burden. | |
| Layered invariant and bounded structural proof | Source-derived zero-allowlist guard, representative render proof and positive control, one-time normalized structure evidence, unchanged fixture hashes, and existing responsive/browser checks. | ✓ |

**User's choice:** Accepted the complete recommendation package.
**Notes:** Static guards apply to Threadline-owned source/output, not arbitrary host audit data. MechanicalChecker remains necessary but is proven insensitive to text and width, so bounded DOM-structure and existing responsive evidence supply the complementary proof. No new screenshot baselines, Tier-A recapture, or paid critic scoring.

---

## the agent's Discretion

- Exact behavior-first selector at each test site, within the locked selector priority.
- Exact contract module and structural-signature representation.
- Exact durable replacement filenames for the remaining roadmap-named tests.
- Plan count and task grouping, while preserving the two-tier, atomic, bisectable sequence.

## Deferred Ideas

- Fully adopter-facing stress-harness UX belongs in a future UI phase only if the dev/test harness becomes a supported product surface.
- Repository-wide non-rendered historical-comment cleanup remains outside Phase 201.
- No new product, API, Plug, Ecto, database, operator workflow, theme, or IA capability was introduced.
