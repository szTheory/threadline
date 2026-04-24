# Phase 34: v1.10 audit hygiene — Context

**Gathered:** 2026-04-24  
**Source:** `.planning/v1.10-MILESTONE-AUDIT.md` (`gaps.integration`, `gaps.flows`)

## Goal

Close **INT-DOC-01** and **FLOW-TEST-01** without changing capture or exploration semantics. **XPLO-01**–**XPLO-03** remain satisfied as shipped.

## Deliverables

1. **INT-DOC-01** — `Threadline.timeline/2` root `@doc` documents the same total order as `Threadline.Query` (`captured_at`, then `id`, descending).
2. **FLOW-TEST-01** — One CI test loads changes via `Threadline.audit_changes_for_transaction/2` and runs `Threadline.change_diff/2` on each row (JSON-encodable maps).
3. **`ChangeDiff` / capture alignment** — `primary_map/2` accepts DB-native lowercase `op` (`insert` / `update` / `delete` from `lower(TG_OP)`), emitting uppercase in the primary wire map so listing → diff works on real trigger rows.

## Out of scope

Planning-metadata `tech_debt` items from the audit (SUMMARY frontmatter, `PROJECT.md` drift, validation template rows) unless explicitly reopened.
