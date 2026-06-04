# Phase 140 Discussion Log

**Phase:** 140 — Earned New Flows
**Date:** 2026-06-04
**Mode:** `--auto` from transition after Phase 139 completion

## Auto-Selected Gray Areas

1. **Flow inventory**
   - Selected: ship exactly four flows: record-first lookup, closed export loop, correlation paste/deep-link, first-class row-history entry.
   - Rationale: roadmap and `POLISH-FLOWS` name these as earned flows; Phase 139 explicitly deferred them.

2. **Home ownership**
   - Selected: Home owns record-first lookup and correlation paste entry controls.
   - Rationale: Phase 139 established Home as the orientation hub; adding these controls elsewhere first would fragment the IA.

3. **Record-first shape**
   - Selected: cordoned schema/table + record-id lookup that leads to row history, not a raw filter builder.
   - Rationale: the support-operator JTBD is plain-language lookup, not audit-query construction.

4. **Export loop shape**
   - Selected: carry existing filtered Timeline/Evidence context into Exports.
   - Rationale: the reviewer JTBD is "take this proof/search with me"; a new export builder is broader than the earned loop.

5. **Correlation shape**
   - Selected: paste/deep-link `correlation_id` from Home and reuse existing Timeline correlation semantics.
   - Rationale: Threadline already has strict correlation filtering; Phase 140 should expose it, not invent a second model.

6. **Row-history shape**
   - Selected: make row history first-class using existing route/component/query constraints.
   - Rationale: the capability exists but is buried behind a transaction row; Phase 140 improves discoverability while preserving authorization.

7. **Non-goals**
   - Selected: defer motion, broad responsive work, screenshot-diff infrastructure, advanced query building, bulk export lifecycle redesign, and speculative additional flows.
   - Rationale: those are later roadmap phases or unearned scope.

## Open Questions For Research/Planning

- Which existing route shape best supports first-class row-history without duplicating `TransactionLive` history behavior?
- Does the current export surface already accept enough query context to pre-populate filtered exports, or does it need a small parameter adapter?
- Which seeded example records/correlation ids provide the most stable browser UAT path for all four flows?
- How should feature flags gate Home controls when Coverage/Evidence/Exports/Policy sections are disabled?
- What scope-query contexts are required to preserve scoped operator behavior for row-history and export carry-forward?

---
*Discussion captured: 2026-06-04*
