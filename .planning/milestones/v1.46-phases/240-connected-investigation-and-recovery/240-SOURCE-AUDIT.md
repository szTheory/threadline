# Phase 240 Source Coverage Audit

**Phase:** 240 — Connected investigation and recovery  
**Disposition:** All mandatory source items are covered; no unplanned item or phase split remains.  
**Sources:** ROADMAP Phase 240 goal and success criteria; the five Phase 240 REQUIREMENTS entries; 240-RESEARCH.md; 240-CONTEXT.md decisions D-01–D-10.

SOURCE | ID | Feature / requirement | Plan | Status | Notes
---|---|---|---|---|---
GOAL | — | Follow related evidence and resume/share investigations without losing scope or trust in controls. | 01–04 | COVERED | Row-history continuity/recovery, pivots and committed searches, copy reliability, immediate/reduced-motion behavior.
REQ | UII-04 | Direct and transaction-drawer row history/as-of preserve the originating investigation context. | 01 | COVERED | Tasks 01-01–03.
REQ | UII-05 | Existing actor and correlation pivots reach related activity and preserve investigation context. | 02 | COVERED | Task 02-01.
REQ | UII-06 | Save, resume, and share supported searches with coherent names and accurate supported state. | 02 | COVERED | Tasks 02-02–03.
REQ | UIA-06 | Copy supported values on fresh entry and after LiveView patches, with truthful failures and no duplicate event handling. | 03 | COVERED | Tasks 03-01–02.
REQ | UIA-07 | Purposeful interruptible motion; frequent actions immediate; honor reduced motion. | 04 | COVERED | Tasks 04-01–02.
RESEARCH | — | Existing LiveView routes, FilterParams allowlist/canonicalizer, host auth/scope seams, and local return construction. | 01–02 | COVERED | Planner resolves the origin question to origin=timeline plus supported committed fields; no route/API/auth-policy/client-framework/backend capability additions.
RESEARCH | — | Preserve as-of and transaction identity; parent outage blocks child reads; direct outages remain retryable and distinct from evidence states. | 01 | COVERED | Existing scoped read seam; programmer errors remain visible.
RESEARCH | — | Keep actor/correlation concepts distinct; use supported pivots and preserve current scope. | 02 | COVERED | No inferred actor ownership or incident identity.
RESEARCH | — | Existing ActorRef-owned SavedView persists committed canonical filters; share a definition-only local URL, recipient recomputes and reauthorizes. | 02 | COVERED | Current SavedView schema is sufficient; explicit database-impact block says no migration/schema change.
RESEARCH | — | One guarded delegated clipboard handler; user-initiated writes; confirm only resolved API/confirmed fallback; accessible recovery, focus and cleanup. | 03 | COVERED | Existing display primitive remains the authorized-copy boundary.
RESEARCH | — | Redacted/absent/omitted/non-copyable values never become copy affordances or unauthorized DOM/status values. | 01, 03 | COVERED | D-08 tested in render and browser coverage.
RESEARCH | — | Frequent interactions and changing evidence remain immediate; only existing tokenized reduced-motion-compatible drawer behavior when modality is safely known. | 01–04 | COVERED | D-09 browser proofs: as-of 01-01, pivot/search apply/filter/page 02-03, copy 03-02, evidence rows and keyboard/Escape 04-01/02; D-10 uses safe existing modality or immediate default.
RESEARCH | — | Reuse ExUnit/LiveViewTest and Playwright; no package additions; preserve optional Phoenix boundary; final CI uses PostgreSQL 15+. | 01–04 | COVERED | Every task has automated verification; phase gate documented. Planning did not run tests.
RESEARCH | — | ASVS L1 V4/V5/V7/V8 controls and STRIDE mitigation with blocking threshold high. | 01–04 | COVERED | Each plan has a threat model; high/critical items are mitigated.
CONTEXT | D-01 | Explicit safe return; bounded origin and supported committed filters; retain transaction ID and as-of. | 01 | COVERED | Tasks 01-01–02.
CONTEXT | D-02 | URL params untrusted; existing allowlist only; exclude scope/tenant/cursors; reauthorize every route. | 01–02 | COVERED | Tasks 01-01–02, 02-01, 02-03.
CONTEXT | D-03 | Parent unavailable suppresses child reads; direct failure retryable; preserve absent/pruned/never-captured distinctions. | 01 | COVERED | Tasks 01-02–03.
CONTEXT | D-04 | Use supported actor/correlation pivots and keep domain concepts distinct. | 02 | COVERED | Task 02-01.
CONTEXT | D-05 | Actor-owned saved search; save/restore committed canonical supported query, not drafts. | 02 | COVERED | Task 02-02.
CONTEXT | D-06 | Copy canonical applied-query definition, with recipient recomputation and authorization. | 02–03 | COVERED | Task 02-03 builds; Plan 03 verifies clipboard integration.
CONTEXT | D-07 | One delegated handler; start writes from user action; factual success and actionable failure. | 03 | COVERED | Tasks 03-01–02.
CONTEXT | D-08 | No copy control or value leak for redacted/non-copyable evidence; preserve focus and cleanup. | 01, 03 | COVERED | Plans 01 and 03.
CONTEXT | D-09 | Immediate frequent actions; no animated evidence-value changes or row stagger. | 01–04 | COVERED | Tasks 01-01, 02-03, 03-02, 04-01–02 prove as-of, pivots/search apply/filter/page, copy, evidence rows, keyboard, and Escape.
CONTEXT | D-10 | Brief interruptible tokenized drawer motion only with safe existing modality; otherwise immediate; honor reduced motion. | 04 | COVERED | Task 04-02.

## UI-SPEC Consideration Traceability

All 26 resolved considerations are mapped to plan must-haves and automated verification:

| Criterion | Plan | Verification task |
|---|---|---|
| UI-240-TIMELINE / empty | 02 | 02-03 |
| UI-240-TIMELINE / loading | 02 | 02-03 |
| UI-240-TIMELINE / error | 02 | 02-03 |
| UI-240-TIMELINE / populated | 02 | 02-03 |
| UI-240-TIMELINE / partial | 02 | 02-03 |
| UI-240-TIMELINE / overflow | 02 | 02-03 |
| UI-240-TIMELINE / zero-one-many | 02 | 02-01, 02-03 |
| UI-240-SAVED-SEARCH / empty | 02 | 02-02 |
| UI-240-SAVED-SEARCH / loading | 02 | 02-02 |
| UI-240-SAVED-SEARCH / error | 02 | 02-02 |
| UI-240-SAVED-SEARCH / populated | 02 | 02-02 |
| UI-240-SAVED-SEARCH / partial | 02 | 02-02 |
| UI-240-SAVED-SEARCH / overflow | 02 | 02-02, 02-03 |
| UI-240-SAVED-SEARCH / zero-one-many | 02 | 02-02 |
| UI-240-ROW-HISTORY / empty | 01 | 01-03 |
| UI-240-ROW-HISTORY / loading | 01 | 01-01, 01-03 |
| UI-240-ROW-HISTORY / error | 01 | 01-02, 01-03 |
| UI-240-ROW-HISTORY / populated | 01 | 01-01, 01-02 |
| UI-240-ROW-HISTORY / partial | 01 | 01-03 |
| UI-240-ROW-HISTORY / overflow | 01 | 01-03 |
| UI-240-ROW-HISTORY / zero-one-many | 01 | 01-03 |
| UI-240-ROW-HISTORY / long-text | 01, 03 | 01-03, 03-01 |
| UI-240-COPY / loading | 03 | 03-01, 03-02 |
| UI-240-COPY / error | 03 | 03-01, 03-02 |
| UI-240-COPY / overflow | 03 | 03-01, 03-02 |
| UI-240-COPY / long-text | 03 | 03-01, 03-02 |

## D-09 Executable Immediacy Coverage

| Frequent action | Plan/task | Observable browser proof |
|---|---|---|
| As-of change | 01-01 | Selected timestamp and route update; evidence rows show no animation/delay. |
| Actor/correlation pivot | 02-03 | Expected supported-filter URL and result scope appear without animation/delay. |
| Saved-search apply | 02-03 | Canonical committed query and matching applied state appear without animation/delay. |
| Filter change | 02-03 | Applied URL/query state updates without animation/delay. |
| Pagination | 02-03 | Expected page/cursor result state appears without animation/delay. |
| Copy | 03-02 | Clipboard call is observed synchronously from activation; feedback waits for the controlled browser result. |
| Keyboard activation and Escape | 04-02 | Dialog/route state and focus update immediately; no keyboard-origin transition or fixed sleep. |

Assertions use Playwright URL/locator expectations, deterministic clipboard stubs, and computed animation/transition state. They use no arbitrary elapsed-time thresholds or fixed sleeps.

## Scope and precheck dispositions

- Deferred Ideas remain outside the plans.
- No database change is indicated; existing SavedView storage is sufficient.
- API integration detector: the pre-plan scope returned detected=false; after plan drafting, the deterministic scan flagged generic API language around browser clipboard use. Phase 240 adds no remote service or third-party SDK, so COVERAGE.md records the reasoned no-external-integration disposition. Assumption-delta: no alternatives. Schema drift: none. Codebase drift: skipped because STRUCTURE.md is absent (nonblocking). UI-plan gate passed with the approved spec.
- Security enforcement is active at ASVS Level 1 with blocking threshold high. Each plan includes a STRIDE threat model; no high/critical threat is left unmitigated.
- No test was run in the planning turn.
