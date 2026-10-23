# Phase 239 multi-source coverage audit

Planning audit only; no implementation or runtime test is claimed. Source is the retained worktree at accepted Phase 238 HEAD `43c5bcfa960b1a10cb07ef997e2231e9615dca6f`. All rows below are covered by an executable plan; deferred Phase 240–243 work is excluded as approved.

| Source | ID | Required outcome or constraint | Plan | Status |
| --- | --- | --- | --- | --- |
| GOAL | Phase 239 | Start, narrow and inspect an investigation with readable consistent composition | 01,03,04,05,06,07 | COVERED |
| REQ | UIS-01 | Shared hierarchy/type/spacing/controls, dense and long states | 02,05,06,07 | COVERED |
| REQ | UIS-02 | Canonical terms across UI and feedback | 01,03,04,07 | COVERED |
| REQ | UIS-03 | Complete IDs, values and timezone access | 02,03,05,07 | COVERED |
| REQ | UII-01 | Visible supported Home entry jobs | 01,05,07 | COVERED |
| REQ | UII-02 | Apply, paging, reload/back/forward query/scope | 01,04,05,07 | COVERED |
| REQ | UII-03 | Transaction/change/evidence with distinct semantics | 01,03,05,07 | COVERED |
| REQ | UIA-01 | Responsive and actual browser 200% zoom | 02,03,05,07 | COVERED |
| REQ | UIA-02 | Light/Dark/System preference and effective appearance | 06,07 | COVERED |
| REQ | UIA-03 | Keyboard/touch focus, overlay overlap and return | 06,07 | COVERED |
| REQ | UIA-04 | Pending/empty/error/denied/completed truth | 01,03,04,07 | COVERED |
| CONTEXT | D-01 | Task-oriented Home with visible jobs, truthful context | 01,05 | COVERED |
| CONTEXT | D-02 | Explicit Apply, primary/advanced, active vs draft summary | 01,04 | COVERED |
| CONTEXT | D-03 | URL allowlist/history/cursor, host-owned scope | 01,04 | COVERED |
| CONTEXT | D-04 | Semantic transaction plus discrete changes and responsive Before/After | 03,05 | COVERED |
| CONTEXT | D-05 | Transaction/action/actor/context cardinality and missing meaning | 01,03 | COVERED |
| CONTEXT | D-06 | Visible selectable exact disclosure with timezone, preserve redaction | 03,05 | COVERED |
| CONTEXT | D-07 | Existing identity/private primitives, role consolidation/token repair | 01,05 | COVERED |
| CONTEXT | D-08 | 232-character overflow, widths, short viewport, real zoom | 02,05 | COVERED |
| CONTEXT | D-09 | Session theme choice vs OS-effective computed style | 06 | COVERED |
| CONTEXT | D-10 | Focus/names/touch/overlay patch/reduced motion | 06 | COVERED |
| CONTEXT | D-11 | Distinct states, populated A→held B/error/denial/recovery | 03,04 | COVERED |
| CONTEXT | D-12 | Retained worktree, accepted 238 source, forward custody | 01,07 | COVERED |
| CONTEXT | D-13 | Preserve auth/scope/redaction/public boundary, synthetic fixtures | 01,03,04,07 | COVERED |
| CONTEXT | D-14 | Automated judgment/review, immutable before, test discovery, honest zoom | 02,07 | COVERED |
| RESEARCH | URL pattern | Existing push_patch/handle_params/FilterParams, no client query store | 01,04 | COVERED |
| RESEARCH | Bundle pattern | Existing incident_bundle, no new data route or schema | 03 | COVERED |
| RESEARCH | Exact-value pattern | Presentation sanctioned values, native disclosure, JS-on canary | 03 | COVERED |
| RESEARCH | Shared owners | Token/CSS owner serialized, Overlay private owner, no duplicate theme store | 05,06 | COVERED |
| RESEARCH | State pitfall | Nonempty old A truly held before B; failure/denial/recovery | 04 | COVERED |
| RESEARCH | Zoom pitfall | Isolated bundled Chromium persistent context, MV3 set/getZoom 2.0; no surrogate | 02,05,07 | COVERED |
| RESEARCH | Evidence pitfall | New 239 receipt hashes immutable 238 custody and exact forward commits; retain DB/loopback/output/source/asset guards and negatives | 07 | COVERED |
| RESEARCH | Test architecture | Existing ExUnit/browser seams, named projects, partition weights, Bash 5 ci.all and real discovery | 01–07 | COVERED |
| RESEARCH | Security domain | Host-owned authorization, authorized/redacted values, synthetic loopback evidence | 01,03,04,07 | COVERED |
| UI-SPEC | UC-239-01–35 | Every explicit UI consideration is a PLAN must-have truth; per-ID task/wave map in 239-VALIDATION.md | 01–07 | COVERED |
| EDGE | resolved 5 | UIS-01 empty/encoding; UIA-03 adjacency/empty/ordering are explicit truths | 03,05,06 | COVERED |
| EDGE | unresolved 8 | One per UIS-02, UIS-03, UII-01/02/03, UIA-01/02/04 is flagged in `must_haves.assumptions` | 01,03,04,05,06 | FLAGGED, NOT DISMISSED |
| PROHIBITION | bespoke 10 | Values/transparency/safety recall retained as descriptor-less `must_haves.prohibitions` | 01–07 | FLAGGED, NOT GREEN |

Excluded by approved context: Phase 240 connected row/actor/correlation/saved-search and Copy reliability; Phase 241 coverage/evidence/redaction inspection; Phase 242 operations/reconnect mutation; Phase 243 integrated release; new cursor history, composite routes, backend capability, public API, package/framework/rebrand, paid judging and publication. Research's OWASP authorization/redaction canon concerns appear in actionable STRIDE threats instead of bespoke prohibition rows. The deterministic API coverage detector returned `detected:false` for this phase's plan scope; no external API capability matrix or schema push is applicable. The assumption-delta detector returned `chosen`; Plan 01/06 record `no-change` with session preference as the primary noun and OS-effective appearance derived.
