# Phase 239: Investigation entry and transaction composition — Pattern Map

**Mapped:** 2026-10-09  
**Source basis:** retained `.claude/worktrees/v146-operator-preview`, candidate base `43c5bcfa960b1a10cb07ef997e2231e9615dca6f`; source observations only from this worktree.  
**Files analyzed:** 18 anticipated existing owners plus 2 likely new proof helpers  
**Analogs found:** 18 / 20; the real browser-zoom proof mechanism has no existing project analog.

Phase inputs do not lock a new product source file list. The table names current owners and likely additions inferred from 239-RESEARCH Wave 0 gaps. Keep helper/test names adjustable in planning. Every named existing source analog was checked with `git ls-files` in this worktree; no runtime mirror paths are used. Existing local planning edits were present and are outside this artifact's ownership.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/threadline/operator_surface/live/start_live.ex` | controller / LiveView | request-response | same file; Home composition at lines 116-159 | exact |
| `lib/threadline/operator_surface/live/timeline_live.ex` | controller / LiveView | request-response, streaming | same file; URL parsing and stream lifecycle | exact |
| `lib/threadline/operator_surface/live/timeline_live/filters.ex` | component | request-response | same file; native form + Apply/drawer | exact |
| `lib/threadline/operator_surface/live/transaction_live.ex` | controller / LiveView | request-response, streaming | same file; transaction header and change records | exact |
| `lib/threadline/operator_surface/ui/{page,form,display,overlay,data}.ex` | component / shared UI primitives | transform, request-response | current private components | exact |
| `lib/threadline/operator_surface/style/01_tokens.css` | config / style tokens | transform | same file; token catalog | exact |
| `lib/threadline/operator_surface/style/{03_page_home,04_controls,06_layout_primitives,07_find_detail,08_overlays_motion,09_responsive}.css` | style / layout | transform | respective current owner stylesheet | exact |
| `test/threadline/operator_surface/live/start_live_test.exs` | test | request-response | same file | exact |
| `test/threadline/operator_surface/live/timeline_live_test.exs` | test | request-response, streaming | same file | exact |
| `test/threadline/operator_surface/transaction_live_test.exs` | test | request-response, streaming | same file | exact |
| `test/threadline/operator_surface/{presentation_test,ui_test,style_contract_test}.exs` | test | transform | same files | exact |
| `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts` | test / browser | request-response | same file; full responsive journey | exact |
| `examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts` | test / browser | event-driven | same file; keyboard/theme/overlay seams | exact |
| `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts` | test / browser | event-driven | same file; delayed LiveView query | exact |
| `examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts` | utility / evidence | transform, file I/O | same file; candidate-bound browser manifest | exact |
| `examples/threadline_phoenix/e2e/tests/operator-transaction-zoom.spec.ts` (likely new) | test / browser | request-response, event-driven | investigation-flow spec for journey; no zoom analog | partial |
| `examples/threadline_phoenix/e2e/support/operator-zoom-extension/` (likely new, local test helper) | utility / browser harness | request-response | no tracked project analog | none |

`examples/threadline_phoenix/e2e/run-e2e.sh`, evidence-manifest plumbing, and candidate identity guards are maintenance only if necessary: Phase 238 handoff requires forward custody from its receipt and immutable bundles. Reuse the strict existing guard patterns; do not weaken the Phase 238 baseline mode. No route, backend read, public API, auth model, or dependency is indicated.

## Pattern Assignments

### Home and Timeline query owners

**Analogs:** `lib/threadline/operator_surface/live/start_live.ex`, `live/timeline_live.ex`, and `live/timeline_live/filters.ex`.

Home keeps route content composed under `UI.Page.shell`, with shared header/task components and visible direct lookup controls (start_live.ex:125-160). The current lede at 168-174 overstates action/context availability; align it with the approved truthful copy while retaining the task hierarchy. Do not move server lookup/auth logic into the presentation layer.

Timeline's `handle_params/3` establishes paths, canonicalizes the default window, applies `FilterParams` allowlisting, and loads the query (timeline_live.ex:83-115). `load_filtered_page/2` resets the cursor, executes scoped query/count reads, then resets the stream and assigns the applied filter summary (133-178). The form uses native `UI.Form.field` controls and explicit `phx-submit="apply"`; advanced filters open the shared drawer (filters.ex:40-110). Apply uses `push_patch`; keep URL query as committed user state and leave host scope in server assigns (timeline_live.ex:226-233).

**Tests to extend:** `start_live_test.exs:170-203` asserts hierarchy/order and current copy; `timeline_live_test.exs:403-426,533-538,649-719` covers canonical submission, no auto-apply, single patch, and restoration. Existing coverage establishes query history behavior, not stale nonempty-result behavior. The browser route-state analog at `operator-route-states.spec.ts:94-124` holds a query but starts with no old rows; extend with query A populated, delayed query B, error, and recovery while asserting result identity. Existing scope tests in timeline_live_test.exs:1598 onward protect server-side scope.

### Transaction evidence and exact-value access

**Analogs:** `lib/threadline/operator_surface/live/transaction_live.ex`, `ui/display.ex`, and `presentation.ex`.

`mount/3` reads the existing authorized `incident_bundle` with scope and `scope_query_fn`, then streams changes (transaction_live.ex:20-38). `handle_params/3` handles the history patch without another transaction API (41-73). `transaction_header/1` uses `UI.Page.page_header` and `detail_header` metadata slots to keep transaction ID, actor, optional action, correlation, and captured time independently labeled (163-207). `change_list/1` renders each AuditChange as a separate stream record and preserves missing field evidence; per-field Before/After tokens retain null/redacted distinctions (215-280). Keep the existing data boundary and ordering; never infer the transaction actor from its linked action.

`UI.Display.ref/1` obtains per-kind display metadata from Presentation and currently gives a shortened code/title/data-copy plus JS-gated Copy control, with full text only when the script is disabled (display.ex:154-188). This is a useful formatting seam, not a sufficient D-06 implementation: add visible native disclosure content for abbreviated authorized values and exact timestamps, including timezone, without placing raw hidden bytes in attributes. Reuse `Presentation.change_value_token/2` and `Presentation.ref/2` so redaction/absent/omitted/null meanings remain canonical.

**Tests to extend:** `transaction_live_test.exs:90-174` for not-found/empty states; 327-413 for before/after, null, redacted and no-field-evidence; 415-525 for full identifier/correlation values and definition-list metadata; 527-577 for long values. `presentation_test.exs:164-244` covers truncation and timestamp kinds. Add JS-on rendered assertions that disclosure text is selectable/readable and exact time includes timezone; include a synthetic redacted secret canary assertion that it is absent from DOM attributes. Existing tests that expect data-copy metadata describe Phase 240 convenience behavior and should be adjusted only as needed without expanding that phase's copy reliability scope.

### Shared theme, focus, overlays, and CSS

**Analogs:** `ui/overlay.ex` and the owned CSS layers. Overlay drawers/modal use `phx-mounted`/`phx-remove`, Phoenix `JS` transitions, focus push/first-focus/pop, Escape and click-away (overlay.ex:96-165). Keep lifecycle hooks and server-rendered native controls; test overlapping toast/menu/drawer and repeated patches in the existing browser accessibility spec before changing shared behavior. Theme selection remains session-backed; `start_live_test.exs:597-637` exercises selected theme persistence. `style_contract_test.exs:7-27,43-60` checks dark/light/system token selectors and shell contracts. Browser verification must inspect effective computed colors and chosen preference separately.

CSS ownership is specific: `01_tokens.css` owns duplicated semantic roles and self-referential paper/ink aliases; `03_page_home.css` owns Home hierarchy; `04_controls.css` owns form/control geometry; `06_layout_primitives.css` owns shared grids/stacks; `07_find_detail.css` owns filter/evidence/change layout; `08_overlays_motion.css` owns overlay stacking/focus visuals/motion; `09_responsive.css` owns responsive breakpoints. Keep the source order and token system, constrain min-width through ancestors, and allow only genuine evidence regions to scroll locally. `style_contract_test.exs` is a source contract; browser assertions in `operator-timeline-investigation-flow.spec.ts` (320/375/768/1024/1440 viewports and overflow/focus checks) are the rendered seam.

### Browser journey, evidence, and zoom proof

**Analogs:** `operator-timeline-investigation-flow.spec.ts`, `operator-accessibility.spec.ts`, `operator-route-states.spec.ts`, and `support/operator-browser-evidence.ts`.

The journey spec has reusable login, labelled controls, overflow measurement, focus visibility, URL recovery, and end-to-end navigation assertions. Preserve Playwright role/label locators and separate viewport checks from browser zoom. `operator-browser-evidence.ts:75-110` verifies connected LiveView, served CSS hash, computed theme/token values, viewport/DPR, source-bound asset records, and unique contained screenshots; it explicitly writes `browserZoom: "unverified"` and `zoom: 1`. Extend its manifest only with measured proof, keeping baseline bundles immutable and recording the actual zoom readback.

No tracked helper currently proves tab zoom. The RESEARCH candidate is a minimal local extension with `chrome.tabs.setZoom(tabId, 2)` / `getZoom`, run in an isolated headed persistent Playwright Chromium context; if prototyping shows this unsupported or unsafe, record the proof gap. Do not substitute DPR, viewport resize, CSS zoom, or page-scale emulation. New browser harness ownership should be separate from the journey UI spec except for invoking the journey checks, so normal E2E infrastructure remains stable.

## Shared Patterns

### URL and authorization scope

**Sources:** `timeline_live.ex:83-178,226-233`; `lib/threadline/query/filter_params.ex:16-97`. `handle_params` parses the allowlisted user query and runs reads using server-owned scope. Preserve cursor reset on query change and keep the result summary tied to the query that produced its rows.

### Authorized evidence and state semantics

**Sources:** `transaction_live.ex:20-38,163-280`; `lib/threadline/operator_surface/presentation.ex:1-34,47-115,395-464`; `lib/threadline/operator_surface/ui/data.ex:191-249`. Reuse current sanitized result values and distinguish not found, denied, empty, null, absent, omitted, redacted, and no field evidence.

### Theme and overlay lifecycle

**Sources:** `ui/overlay.ex:96-165`; `test/.../live/start_live_test.exs:597-637`; `test/.../style_contract_test.exs:7-60`. Keep session preference and effective OS theme separate. Use Phoenix JS focus stack and dismissal lifecycle; prove computed styles and real focus return after patches.

### Evidence custody

**Sources:** `examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts:75-110`, `operator-surface-paths.ts`, and Phase 238 `238-HANDOFF.md`. Keep source/served asset identity, safe unique output paths, fresh isolated browser/database execution, and the immutable baseline receipt. New Phase 239 evidence must explicitly chain to the old receipt rather than mutate it.

## No Analog Found

| File/capability | Role | Data Flow | Reason |
|---|---|---|---|
| Real Chromium browser-tab 200% zoom helper/extension | utility / browser harness | request-response | No tracked helper proves browser-chrome zoom; research identifies Chrome tab zoom API as a candidate, not as an implemented proof. |
| Delayed query from populated A to pending/failing B with matching result identity | browser test case | event-driven | Existing delayed route-state test starts with empty results; current tests do not prove nonempty stale-scope safety. Extend the existing test/spec rather than invent another query mechanism. |

## Metadata

**Analog search scope:** `lib/threadline/operator_surface/{live,ui,style}`, `lib/threadline/query`, `test/threadline/operator_surface`, `examples/threadline_phoenix/e2e/{tests,support}`.  
**Tracked-source check:** all named existing analogs confirmed by `git ls-files`; new zoom harness is explicitly labeled new.  
**Pattern extraction date:** 2026-10-09
