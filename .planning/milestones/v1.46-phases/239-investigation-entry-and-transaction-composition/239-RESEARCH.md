# Phase 239: Investigation entry and transaction composition - Research

**Researched:** 2026-10-09  
**Domain:** Phoenix LiveView/HEEx operator investigation UI, accessible responsive presentation, browser E2E evidence  
**Confidence:** HIGH for existing architecture and approved direction; MEDIUM for browser zoom automation pending an isolated proof run

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Phase Boundary

Prove one complete home → filtered Timeline → transaction investigation using the established Threadline identity and private Phoenix/HEEx primitives. Own UIS-01/02/03, UII-01/02/03 and UIA-01/02/03/04. Shared presentation and interaction rules become regression conditions for later journeys. Phase 238 is complete; its source-bound evidence is the before baseline. No new backend capability, route, public component/API, authorization model, framework or release is included.

#### Implementation Decisions

##### Entry and search
- **D-01:** Keep Home task-oriented: Timeline is the primary investigation entry, supported row/correlation lookup controls remain visible, and operational destinations remain discoverable. Refine the existing hierarchy rather than introduce a generic dashboard, command-only interface or new job. Explain context as available when recorded; remove the unconditional claim that every change has action/context.
- **D-02:** Keep Timeline's explicit Apply and current primary-filter/advanced-filter structure. Use canonical destination names and sentence case consistently. Applied-filter summaries describe the query that produced the results; field edits are unapplied until submit. A new persistent draft model is not required.
- **D-03:** The URL remains the allowlisted, committed user query, including supported time/schema/table/actor/correlation filters. Apply produces a navigable query state; reload and browser back/forward restore and execute that query. Existing cursor paging remains incremental, bound to the applied query and reset when that query changes. Do not promise restoration of loaded cursor pages or invent new paging APIs. Host authorization scope remains server-owned and enforced independently of URL filters.

##### Transaction and exact evidence
- **D-04:** Use a concise semantic transaction summary followed by distinct row-change records. Pair explicitly labeled Before/After values where space permits and stack them with their labels at narrow widths/zoom. Do not force heterogeneous evidence into one wide table or duplicate nested panels. Preserve inserts/deletes, no field evidence, null, absent, omitted and redacted distinctions.
- **D-05:** Keep transaction, action, actor and execution context distinct. A transaction groups database row changes and may link to one action; one action may relate to multiple transactions. Transaction and linked action actors must not be inferred from one another. Display only recorded, authorized context available through existing reads. Missing context is "Not recorded" where accurate; not-found does not prove never-existed versus pruned.
- **D-06:** Shortened identifiers, values and timestamps must have a visible, selectable, keyboard- and touch-reachable full-value reading path with exact timezone information. Title/hover, machine-readable datetime, noscript fallback, and Copy alone are insufficient. Choose a lightweight inline/full-value disclosure using existing primitives; preserve authorized bytes and redaction. Phase 240's Copy reliability work remains separately owned.

##### Shared presentation and interaction
- **D-07:** Keep Geist/IBM Plex Mono, existing palette and Threadline tokens/private UI primitives. Consolidate equivalent type/spacing/control roles and repair circular token aliases in their owning source. Establish measurable floors in the UI design contract from the accepted renders, not an arbitrary new palette or blanket component rewrite. Prove the shared changes through the complete investigation journey before expanding them; shared files have one owner.
- **D-08:** Fix the reproduced narrow long-filter overflow while preserving controls and complete evidence access. Verify narrow/intermediate/desktop layouts, 320 CSS-pixel reflow where applicable, short viewports, long unbroken values and actual 200% browser zoom separately. Genuine two-dimensional evidence may scroll locally; whole-page overflow or hidden primary controls is unacceptable. DPR, CSS scaling and resized viewports are not browser zoom proof.
- **D-09:** Preserve Light/Dark/System choices and session persistence across reload and LiveView navigation. Check selected preference separately from computed effective appearance, including OS changes under System; do not introduce a duplicate client-side preference source. Verify served computed styles, not only declarations or class strings.
- **D-10:** Prove visible focus, semantic control names, keyboard/touch reachability, dismissal and focus return for affected controls, including overlapping toast/menu/drawer states and repeated LiveView patches. Shared overlay behavior belongs here; complete row/drawer recovery journeys and their page-specific header fixes remain Phase 240. Frequent interactions stay immediate, reduced-motion behavior must not regress, and no decorative loading choreography is introduced.
- **D-11:** Distinguish pending, empty, failed, denied and completed states. During a changed query, never relabel prior results as the requested scope. Test delayed transitions starting with a nonempty old result set, plus errors and recovery; initial-empty loading alone is not proof. Preserve controls/icons across patches and never announce an accepted operation as completed. New export/prune completion and reconnect mutation proof remain Phase 242.

##### Authority, verification and delivery
- **D-12:** Inspect and implement only in retained `.claude/worktrees/v146-operator-preview`, based on refreshed main `9eefb75c2a45cdc93c6b3d3cac8e7850bc61d7d2`; approved Phase 238 candidate is `43c5bcfa960b1a10cb07ef997e2231e9615dca6f`. Preserve the original stale `milestone/v1.44` checkout's unrelated edits. Carry planning context deliberately and reconcile custody before evidence runs. Retain baseline bundles and the worktree across Phases 238–243; no blanket reset, branch switch, source merge into the old checkout or worktree cleanup.
- **D-13:** Preserve host authentication/authorization, tenant scope, redaction, public 1.x contracts, routes and Phoenix optionality. Use safe synthetic fixtures and existing reads. Exact-value presentation must not create an alternate data leak; no raw value hidden in DOM/copy attributes may defeat redaction.
- **D-14:** Automate verification and judgment review, with bounded rendered review → corrective batch → confirmation. Use meaningful regressions and established named checks, preserve immutable before evidence, and verify test discovery. No paid critic or routine human UAT. Record exact source/assets/fixture/browser evidence and honest limitations; actual zoom remains unverified until proved. A blocker cannot be waived by a visual-iteration limit. Preparation does not authorize push, publication or new spend.

### the agent's Discretion
- Exact copy, token-role consolidation, local layout breakpoints and full-value disclosure mechanics within the approved identity and accessibility contract.
- Plan granularity, fixtures, meaningful failure controls and the smallest reliable browser-zoom proof mechanism. Treat a tool limitation as a proof gap, not a claim that emulation is equivalent.
- Native semantics, lifecycle-safe implementation and test placement; prefer current patterns and no new dependency. Keep advanced filters available without adding mandatory UI state solely to indicate a draft.

### Deferred Ideas (OUT OF SCOPE)
- Phase 240: connected row/actor/correlation/saved-search recovery, page-specific row/drawer overlap, fresh-entry and patched Copy/failure reliability, purposeful motion refinements.
- Phase 241: coverage/evidence/redaction inspection; Phase 242: exports/retention/reconnect mutation journeys; Phase 243: integrated candidate/release recommendation.
- New cursor-history restoration, composite-key routes, bounded row-history APIs, backend capabilities, rebrand/framework/dependency changes, public UI APIs, paid judging and publication.
</user_constraints>

<phase_requirements>
## Phase Requirements

Requirement text below is copied verbatim from `.planning/REQUIREMENTS.md:17-25,40-43`; all ten Phase 239 IDs are included in `.planning/ROADMAP.md:78-82`.

| ID | Description | Research Support |
|----|-------------|------------------|
| UIS-01 | Operators can read page hierarchy, labels and evidence comfortably through a consistent shared typography, spacing and control system, including dense and long-content states. | Consolidate current shared token/control roles and test rendered hierarchy on Home, Timeline, and Transaction. |
| UIS-02 | Operators encounter the same canonical domain terms for the same concepts across navigation, headings, controls, validation and feedback. | Keep a single route/copy vocabulary across the journey; existing product domain terms distinguish transactions, changes, actions, actors, and context. |
| UIS-03 | Operators can access complete identifiers, field values and exact timestamps with timezone information wherever shortened presentation is used. | Existing helpers shorten values and retain attributes for convenience; use a visible/selectable keyboard/touch disclosure for authorized full values and exact-zone timestamps. |
| UII-01 | Operators can start an investigation from the home page through clear, visible entry points for the supported lookup and search jobs. | Retain the task-oriented Home with Timeline as primary investigation entry and existing row/correlation lookups visible. |
| UII-02 | Operators can filter and page the timeline without losing the active query or scope, including reload and browser back/forward navigation. | Existing `push_patch`/`handle_params` query boundary, filter allowlist, and incremental cursor support the URL-backed applied-query model; add tests for nonempty-old-scope pending and browser history. |
| UII-03 | Operators can inspect a transaction's changes and before/after values while distinguishing its action, actor and execution context. | Existing investigation bundle returns transaction/action/change data; use semantic summary + per-change records and independently sourced actor/context fields. |
| UIA-01 | Operators can complete the supported jobs at narrow, intermediate and desktop widths and actual 200% browser zoom without losing controls or evidence to accidental page overflow. | Fix the baseline 375 CSS-pixel 1924px document overflow; test responsive widths independently from real browser tab zoom. |
| UIA-02 | Operators can select Light, Dark or System and see the chosen preference and effective appearance remain correct across reloads and LiveView navigation. | Reuse the session-backed preference; assert both saved choice and actual computed colors under explicit themes and OS preference changes. |
| UIA-03 | Operators can use controls and overlays by keyboard and touch, with visible focus, predictable dismissal and focus return, including overlapping toast/menu/drawer states. | Existing shared overlay primitives are the ownership point; browser interaction sequences must exercise patching and overlap, not only HEEx assertions. |
| UIA-04 | Operators can distinguish pending, empty, failed, denied and completed states without stale data being labeled as the newly requested scope or an accepted operation being reported as completed. | Preserve existing data state distinctions; add delayed query with nonempty prior result, failure, denied, recovery and status-region lifecycle checks. |
</phase_requirements>

## Summary

**Recommendation:** Implement this as one vertical Home → URL-backed Timeline → Transaction journey with shared presentation/interaction rules owned once, using existing Phoenix/LiveView/HEEx modules and the example app's Playwright suite. Preserve explicit Apply and current cursor behavior; display applied scope with the results that produced it; compose transaction metadata as a definition list and row changes as individual responsive records. Avoid adding dependencies, routes, endpoints, public components or client-side theme state. [VERIFIED: approved `.planning/phases/239-investigation-entry-and-transaction-composition/239-CONTEXT.md:7-41`; in-repo paths and behavior corroborated by three Phase 239 advisor reports]

The main planning risks are proof and ownership: genuine 200% tab zoom remains unverified; Phase 238's immutable evidence runner expects the original Phase 238 commit chain and context hashes; the shared CSS/overlay/token work needs one owner; and result-scope tests must begin with a nonempty old result. Phase 238 stays the before baseline. Build a separate Phase 239 candidate/evidence identity that references and verifies the immutable Phase 238 receipt rather than editing that receipt or weakening its preflight. [VERIFIED: `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-HANDOFF.md`; `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-ISOLATION-RECEIPT.json`; `.planning/phases/239-investigation-entry-and-transaction-composition/239-ADVISOR-INTERACTION.md`; `.planning/phases/239-investigation-entry-and-transaction-composition/239-ADVISOR-ENTRY.md`]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Home investigation entry and lookup navigation | Frontend Server (LiveView) | Browser / Client | Home route and links are server-rendered HEEx; browser handles ordinary navigation. Keep existing route and host mount. [VERIFIED: `239-ADVISOR-ENTRY.md`; source refs `lib/threadline/operator_surface/live/start_live.ex:139-304`] |
| Committed Timeline query, authorization scope, and cursor reads | API / Backend (existing LiveView read boundary) | Browser / Client (URL/history) | `handle_params` validates the allowlisted query and calls existing read path; tenant scope is supplied from server auth assigns and is not URL state. [VERIFIED: `239-ADVISOR-ENTRY.md`; `lib/threadline/operator_surface/live/timeline_live.ex:83-178,226-233,349-426`; `lib/threadline/query/filter_params.ex:16-97`] |
| Transaction/change composition and full-value disclosure | Frontend Server (HEEx) | Browser / Client | Existing incident bundle supplies authorized reads; server renders transaction/action/change distinctions, native disclosure gives a no-script visible read path. [VERIFIED: `239-ADVISOR-EVIDENCE.md`; `lib/threadline/investigation.ex:174-209`; `lib/threadline/operator_surface/live/transaction_live.ex:163-285`] |
| Shared tokens, responsive reflow, focus, overlays, theme | Browser / Client (CSS/native controls) | Frontend Server (LiveView session) | Shared CSS and private UI primitives own common behaviors; session preference remains authoritative and system mode uses CSS media preference. [VERIFIED: `239-ADVISOR-INTERACTION.md`; `lib/threadline/operator_surface/style/01_tokens.css`, `lib/threadline/operator_surface/ui/overlay.ex`, `lib/threadline/operator_surface/auth.ex:84-92,238-240`] |
| Browser zoom, keyboard/theme/state proof | Browser / Client (Playwright Chromium) | — | Browser APIs and a minimally privileged local extension can set tab zoom; Playwright drives real rendered route behavior. [CITED: Chrome `tabs` API; Playwright Chrome extensions docs] |

## Project Constraints (from AGENTS.md)

- Preserve the three-layer boundary: capture owns durable row mutation capture; semantics owns application action meaning; exploration/operations owns timelines, diffs, filters, as-of, exports and operator UX. Do not conflate AuditTransaction with requests/actions or AuditAction with AuditChange. [VERIFIED: `AGENTS.md:8-20`]
- Use the canonical domain terms exactly: AuditTransaction, AuditChange, AuditAction, AuditContext, ActorRef, Correlation. [VERIFIED: `AGENTS.md:22-31`]
- Preserve trigger-backed capture through generated PostgreSQL triggers installed by host-owned Ecto migrations. No Phase 239 backend/capture changes are needed. [VERIFIED: `AGENTS.md:50-56`]
- Keep named verification entrypoints as the canonical commands. Full-suite hygiene requires Bash 5 in this checkout; do not call the suite flake-free because the Phase 238 handoff records PostgreSQL planner sensitivity. [VERIFIED: `AGENTS.md:33-48`; `238-HANDOFF.md`; `238-INTEGRATION-NOTES.md`]
- Keep the Phase 238 current-main worktree and evidence; do not operate on the stale original checkout, change branches, reset, clean the worktree, or mutate old baselines. [VERIFIED: `239-CONTEXT.md:33-36`; `238-HANDOFF.md`]
- Keep host authentication/authorization, tenant scope, redaction, public 1.x contracts, routes and Phoenix optionality unchanged. No hidden raw values in the DOM or copy attributes. [VERIFIED: `239-CONTEXT.md:33-36`]
- Automate verification and bounded review; no routine human UAT, paid critic, push, publication or new spend. [VERIFIED: `AGENTS.md:60-68`; `239-CONTEXT.md:33-41`]

## Standard Stack

### Core (already installed; add no packages)

| Library/tool | Current version observed | Purpose | Why standard |
|---------|-------------------------|---------|--------------|
| Elixir / OTP / Mix | Elixir 1.17.3 / OTP 27 / Mix 1.17.3 in current shell | Existing LiveView UI, tests, named verification aliases | Repository uses Mix and already has its Phoenix/LiveView operator surface. This is observed local runtime; use the phase's established project runtime for verification. [VERIFIED: `elixir --version` and `mix --version` run in retained worktree] |
| Phoenix | 1.8.13 locked | HTTP/router and host integration | Current application dependency, no route/API change planned. [VERIFIED: `mix.lock:32`] |
| Phoenix LiveView | 1.2.11 locked | Stateful server-rendered navigation, query params, patch lifecycle | Existing Timeline and operator pages already use `handle_params`, streams and `push_patch`. [VERIFIED: `mix.lock:34`; `239-ADVISOR-ENTRY.md`] |
| Phoenix HTML | 4.3.0 locked | HEEx templates, native semantics and forms | Current app template primitives. [VERIFIED: `mix.lock:33`] |
| `@playwright/test` | 1.60.0 installed and locked | Real route, layout, keyboard, state and zoom-browser checks | Existing example E2E project; no new dependency required. [VERIFIED: `examples/threadline_phoenix/e2e/package-lock.json:491-492`; `npm ls --depth=0`] |
| Node.js | 22.14.0 per `.tool-versions` and current shell | Existing browser runner | Already configured for E2E and CI. [VERIFIED: `.tool-versions:1`; `node --version`] |

### Supporting

| Existing tool | Version | Purpose | When to use |
|---------|---------|---------|-------------|
| ExUnit + LiveView test helpers | Project dependency versions locked in `mix.lock` | Fast server-rendered contracts for labels, states, query params and evidence distinctions | Add assertions to existing tests; use browser tests for layout, actual focus, theme computed styles and patch lifecycle. [VERIFIED: `239-CONTEXT.md:87-90`; existing tests listed in advisor reports] |
| Chromium via Playwright | Playwright package is 1.60.0; browser binary is locally available through `/opt/homebrew/bin/chromium` (system) | Browser behavior and rendered proof | Use the project's configured Playwright Chromium; use a separate isolated context/profile for zoom proof. [VERIFIED: shell `command -v chromium`; `npm ls`] |

**Installation:** None. Do not add dependencies; current route, UI, CSS, ExUnit and Playwright infrastructure is present. [VERIFIED: approved `239-CONTEXT.md:38-41`; existing package manifests]

## Architecture Patterns

### Recommended Project Structure

Keep the current module ownership: `live/start_live.ex`, `live/timeline_live.ex` and `live/transaction_live.ex` own route-specific content; `live/timeline_live/filters.ex` owns query controls; `ui/{page,form,overlay,data,display}.ex` own shared private primitives; `style/01_tokens.css` through `09_responsive.css` own theme, layout and breakpoints; current ExUnit and E2E files hold regressions. Do not add a second UI state system or new public component. [VERIFIED: `239-CONTEXT.md:74-90`; `239-ADVISOR-INTERACTION.md`]

### Pattern 1: URL is the committed query; form edits remain draft until Apply

Use the current primary/advanced filter form and explicit Apply. Treat `handle_params` as the single parser/execution boundary for initial navigation, `push_patch`, reload, and back/forward. Keep results and their displayed scope associated with the query that produced them; when a new query is pending, retain the old scope label with old rows or clear rows until matching results arrive. Reset incremental cursor on query change. Never serialize host tenant/authorization scope into the URL. [VERIFIED: `239-ADVISOR-ENTRY.md`; `lib/threadline/operator_surface/live/timeline_live.ex:83-178,226-233,349-426`; `lib/threadline/query/filter_params.ex:16-97`]

```elixir
# Follow existing Timeline flow; do not build a new query mechanism.
# Current source anchors: live/timeline_live.ex:83-178 and :349-426.
# Use current locked filter allowlist and existing server-owned scope.
```

### Pattern 2: Semantic transaction header + discrete change records

Render transaction metadata in the existing detail-header/definition-list pattern. Keep transaction actor separate from linked action actor; display only recorded transaction source/meta and action request/job/correlation fields. Follow with one streamed record per captured change. Render labeled Before/After values side-by-side only when they reflow cleanly, otherwise stack them. Preserve operation-specific insert/delete behavior and null/absent/omitted/redacted/no-field-evidence distinctions. [VERIFIED: `239-ADVISOR-EVIDENCE.md`; `lib/threadline/operator_surface/live/transaction_live.ex:163-285,326-369`; `lib/threadline/investigation.ex:174-209`]

### Pattern 3: Visible exact-value disclosure independent of JavaScript Copy

For abbreviated IDs, values, and exact timestamps, give the user an ordinary focusable/touch-operable disclosure whose expanded content is selectable text. A native disclosure is a fit where it preserves accessible summary/details semantics. The complete value must come from the already authorized/redacted presentation value; do not put unredacted data into title, data, aria, or copy attributes. Copy is separately owned in Phase 240. Exact timestamps should show ISO time plus timezone visibly; machine `datetime` alone is insufficient. [VERIFIED: `239-ADVISOR-EVIDENCE.md`; W3C Keyboard/Reflow references below]

### Pattern 4: Theme and overlays stay in their current owners

Keep the existing session-backed Light/Dark/System setting. Verify the stored selected value separately from the resolved effective appearance, including OS preference change under System. Make shared token fixes in token source and shared focus/dismissal/focus-return/stacking fixes in overlay primitives. Prove computed CSS and real keyboard sequences across repeated LiveView patches; source-string class tests alone are insufficient. [VERIFIED: `239-ADVISOR-INTERACTION.md`; `lib/threadline/operator_surface/auth.ex:84-92,238-240`; `lib/threadline/operator_surface/ui/overlay.ex:60-247`]

### Pattern 5: Evidence custody with a forward candidate receipt

Phase 238's `run-e2e.sh` evidence preflight reads `.planning/phases/238.../238-ISOLATION-RECEIPT.json`, validates copied-context hashes, base ancestry and exact first-parent task commit list, then records `base_sha` and current `candidate_head`. That exact-chain guard will reject Phase 239 task commits if reused unchanged. Preserve the Phase 238 receipt and accepted bundle byte-for-byte. Plan a separate Phase 239 evidence receipt/preflight extension that (a) records a hash of the immutable Phase 238 receipt and accepted baseline identity, (b) verifies the original base/candidate and context hashes, (c) records the approved forward Phase 239 commit sequence/current source and assets, (d) keeps fresh unique test DB/output and existing loopback/ownership guards, and (e) records fixture/browser/served-asset digests. Add negative controls for mutated parent receipt, wrong ancestry, changed planning context, reused DB/partition, missing or unapproved output. Do not add a generic bypass or widen accepted ancestry. [VERIFIED: `examples/threadline_phoenix/e2e/run-e2e.sh:96-157`; `238-ISOLATION-RECEIPT.json`; `238-HANDOFF.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Query parsing/history | A parallel client query state or custom history API | Existing `push_patch` + `handle_params` + `filter_params` allowlist | Preserves established URL restoration and server scope handling. [VERIFIED: advisor ENTRY; source refs above] |
| Theme state | A second localStorage/client theme preference | Existing session-backed theme controller/auth assignment and CSS system mode | Avoids preference divergence across reload and LiveView navigation. [VERIFIED: advisor INTERACTION; source refs above] |
| Full exact value retrieval | New data endpoint or raw-value DOM/copy escape hatch | Existing bundle and redacted `Presentation` result + visible disclosure | Avoids widening authorization/redaction boundary. [VERIFIED: advisor EVIDENCE; D-13] |
| Browser zoom | `setViewportSize`, DPR/device emulation, CSS `zoom`, or CDP page-scale factors as proof of browser zoom | Real Chromium tab zoom through Chrome's extension `chrome.tabs.setZoom`, then assert `chrome.tabs.getZoom` and page reflow | Chrome's API sets a tab zoom factor; Playwright officially supports loading extensions only on a persistent Chromium context. This is a viable supported proof mechanism, but must be prototyped in an isolated browser because no zoom pass has yet been run. [CITED: Chrome `tabs` API; Playwright Chrome extensions docs] |
| Accessible short-value tooltip | `title`, hidden machine metadata, or Copy-only interaction | Visible exact text disclosure; Copy remains convenience | Those attributes/button do not make a stable selectable reading path. [VERIFIED: D-06; advisor EVIDENCE; W3C Keyboard] |
| New transaction read logic | New route/query/schema/API | Existing `incident_bundle` result | Required records are already available from current reads. [VERIFIED: `239-ADVISOR-EVIDENCE.md`; `lib/threadline/investigation.ex:174-209`] |

**Key insight:** This phase is mostly about truthful presentation and lifecycle proof over data already returned by current reads. The expensive failure modes are scope relabeling while a request is delayed, hidden raw data bypassing redaction, and evidence whose source/asset identity can no longer be reproduced. [VERIFIED: Phase 239 context and advisor reports; Phase 238 handoff]

## Common Pitfalls

### Pitfall 1: Treating browser emulation as real browser zoom

**What goes wrong:** A test at a narrow viewport, higher DPR, `page.setViewportSize`, CSS transform/zoom, or mobile pinch simulation is reported as actual 200% browser zoom.  
**Why it happens:** Those mechanisms alter viewport/pixel scale, not the browser tab's page zoom setting.  
**How to avoid:** Use an isolated headed Playwright Chromium persistent context with a minimal local extension that invokes `chrome.tabs.setZoom(tabId, 2)`; read back `chrome.tabs.getZoom(tabId) === 2`, capture extension/browser version and zoom plus resulting CSS viewport, then test Home → Timeline → transaction controls and local evidence scroll. Prefer packaged Playwright Chromium because Playwright says current Google Chrome/Edge removed the flags needed to sideload extensions; do not attach to or manipulate the previously denied Chrome-for-Testing CUA surface. If the isolated extension path cannot be authorized/run, report a proof gap.  
**Warning signs:** Test output only records viewport/DPR; the browser zoom readback is absent; primary controls or exact evidence are clipped at 200%. [CITED: Chrome `tabs` API; Playwright extensions docs; Phase 238 handoff]

### Pitfall 2: Showing stale rows under the new Timeline filters

**What goes wrong:** During a delayed changed query, old rows appear under the newly edited or applied filter label.  
**Why it happens:** A test starts with no old results and therefore never tests identity of existing rows against the new requested scope.  
**How to avoid:** Seed a nonempty query A, apply query B, hold B's response. Assert A remains visibly attributed to A or is cleared; pending B remains distinct, then assert B results/scope match after success. Exercise failed B and a recovery query. Preserve icons and controls across the LiveView patch. [VERIFIED: `239-ADVISOR-INTERACTION.md`; D-02/D-11]

### Pitfall 3: Full-value UI silently defeats redaction or requires JavaScript

**What goes wrong:** Full bytes exist only in title/aria/data/copy attributes; the JS-on path is shortened while Copy is unavailable; or the disclosure reads a raw source value instead of the sanitized bundle value.  
**Why it happens:** Existing `UI.Display.ref/1` uses shortened rendering plus title/data-copy convenience and gates Copy on the script setting.  
**How to avoid:** Test the expanded, selectable exact value with JavaScript enabled and no Copy action. Inspect DOM attributes and the serialized page for synthetic raw secret canaries when the rendered result is redacted; ensure the only representation is the redaction marker. Keep null, omitted, absent, redacted, no-field-evidence, zero-change, denied and not-found semantics distinct. Do not make not-found say “pruned” or “never existed.” [VERIFIED: `239-ADVISOR-EVIDENCE.md`; `lib/threadline/operator_surface/ui/display.ex:154-181`; `presentation.ex:400-420,448-464`; `transaction_live.ex:97-155`]

### Pitfall 4: Multiple owners editing shared CSS/overlay contracts

**What goes wrong:** Token, type, spacing, focus, theme or overlay fixes conflict or get duplicated at route level.  
**Why it happens:** The selected journey crosses three pages and common private primitives.  
**How to avoid:** Give shared CSS/token/overlay work one owner; route owners consume it. Verify computed colors and no whole-document overflow at narrow, intermediate, desktop, 320 CSS px where applicable, short viewport, long unbroken strings and actual 200% zoom. Keep genuine two-axis evidence in local scrollers. [VERIFIED: D-07/D-08/D-10; `239-ADVISOR-INTERACTION.md`]

### Pitfall 5: Capturing new evidence by altering Phase 238's custody anchors

**What goes wrong:** Baseline evidence is rewritten or preflight guards are bypassed to make a Phase 239 source candidate pass.  
**Why it happens:** The existing runner intentionally pins the exact Phase 238 commit set and copied planning-context hashes.  
**How to avoid:** Keep the old runner in baseline mode immutable; introduce a distinct candidate receipt/phase mode with explicit parent receipt hash and forward commits, retaining all existing fail-closed ownership, loopback, fresh DB, and unique-output checks. Test both positive identity and adversarial negatives. [VERIFIED: `run-e2e.sh:96-157`; `238-ISOLATION-RECEIPT.json`; `238-INTEGRATION-NOTES.md`]

## Validation Architecture

Nyquist validation is enabled in `.planning/config.json`. Reuse existing focused test files and browser specs, then confirm CI discovers them. Do not add a test file without updating the partition-weight ownership if required by the repository. [VERIFIED: `.planning/config.json`; `test/partition_weights.txt`; `.github/workflows/ci.yml:710-716`]

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit / Phoenix LiveView tests; Playwright Test 1.60.0 |
| Config file | `examples/threadline_phoenix/e2e/playwright.config.ts` |
| Quick run command | `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/transaction_live_test.exs test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/ui_test.exs test/threadline/operator_surface/style_contract_test.exs` (split by changed concern for a <30-second target) |
| Browser command | `mix verify.example_browser --project=desktop-chromium --project=mobile-chromium <spec>` using `examples/threadline_phoenix/e2e/run-e2e.sh` and local seeded example host |
| Light/system command | `mix verify.example_browser_light <spec>` |
| Full required suite | `mix ci.all` under Bash 5. This is a later gate; prior phase found random-seed PostgreSQL planner sensitivity, so preserve seed/log and report failures honestly. |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Existing seam |
|--------|----------|-----------|-------------------|--------------|
| UIS-01 | Shared hierarchy/readability and dense/long content | Browser + contract | `mix verify.example_browser --project=desktop-chromium operator-timeline-investigation-flow.spec.ts`; `mix test test/threadline/operator_surface/style_contract_test.exs` | Shared style contracts + rendered route flow |
| UIS-02 | Canonical nouns in nav, headings, controls, errors and feedback | ExUnit + browser | `mix test test/threadline/operator_surface/live/start_live_test.exs test/threadline/operator_surface/live/timeline_live_test.exs test/threadline/operator_surface/transaction_live_test.exs` | Existing journey assertions; add copy contract where mismatch occurs |
| UIS-03 | Readable full ID/value/time-zone access when abbreviated | ExUnit + JS-on browser | `mix test test/threadline/operator_surface/presentation_test.exs test/threadline/operator_surface/transaction_live_test.exs`; focused browser transaction flow | Current presentation/transaction tests; browser to prove visible/selectable disclosure and no hidden raw redacted value |
| UII-01 | Visible supported lookup/search entry points on Home | ExUnit + browser | `mix test test/threadline/operator_surface/live/start_live_test.exs`; focused `operator-shell-home.spec.ts` | Existing Home controls and E2E home flow |
| UII-02 | Apply, cursor reset, URL reload/back/forward, scope retained | LiveView + browser | `mix test test/threadline/operator_surface/live/timeline_live_test.exs`; `mix verify.example_browser --project=desktop-chromium operator-timeline-investigation-flow.spec.ts` | Existing URL/history coverage; add held delayed query with nonempty prior result and errors/recovery |
| UII-03 | Transaction/change/before-after with distinct actor/action/context | LiveView + browser | `mix test test/threadline/operator_surface/transaction_live_test.exs`; browser transaction flow | Existing zero-change, update/insert/null/redaction and tenant-scope tests; assert actor independence and recorded context |
| UIA-01 | No accidental overflow/reachability at narrow/intermediate/desktop/200% zoom | Browser | route flow at 320/375/768/1280 and actual tab zoom 2.0 | Existing responsive contracts; add real zoom fixture/spec and record zoom readback |
| UIA-02 | Light/Dark/System selected preference and effective appearance through reload/navigation | LiveView + browser | `mix test test/threadline/operator_surface/live/start_live_test.exs`; `mix verify.example_browser_light operator-accessibility.spec.ts` and dark browser spec | Existing preference persistence tests; add computed style/system OS change after navigation |
| UIA-03 | Focus, names, keyboard/touch, dismissal/return and overlay overlap after patches | Browser | `mix verify.example_browser --project=desktop-chromium operator-accessibility.spec.ts`; targeted `operator-component-contracts.spec.ts` | Current accessibility and UI helper test seams; explicitly sequence toast/menu/drawer + repeated patch |
| UIA-04 | Pending/empty/error/denied/completed states and honest requested/result scope | LiveView + delayed browser | `mix test test/threadline/operator_surface/live/timeline_live_test.exs`; `mix verify.example_browser --project=desktop-chromium operator-route-states.spec.ts` | Existing route-state delayed test starts empty; add nonempty-old-scope, failure and recovery cases |

### Sampling Rate

- **Per task commit:** focused affected ExUnit file(s), then E2E spec for browser-observable changes.
- **Per wave merge:** `mix verify.example_browser` for selected journey plus `mix verify.example_browser_light` if theme behavior changed.
- **Phase gate:** `mix ci.all` under Bash 5; verify the test file is included in `mix verify.test_partitioned` and named browser job. Preserve and report the Phase 238 PostgreSQL planner-sensitive suite behavior. [VERIFIED: `AGENTS.md`; `238-HANDOFF.md`; `.github/workflows/ci.yml:710-716,952-1077`]

### Wave 0 Gaps

- [ ] Add meaningful regressions for delayed query B when query A has nonempty rows; include error and recovery, and assert scope/results remain correctly paired.
- [ ] Add JS-enabled full-value disclosure tests, including redacted synthetic secret canary absent from DOM attributes/copy data and exact timezone text.
- [ ] Add actual 200% tab zoom proof path and receipt: minimal local extension using official `chrome.tabs.setZoom`, readback with `getZoom`, reflow/control checks; prototype against isolated Playwright Chromium before selecting it as final.
- [ ] Add theme effective-style assertions under System plus OS change and LiveView navigation; add overlay overlap/focus-return sequence after repeated patch.
- [ ] Extend the evidence runner's custody format with forward candidate identity and negative controls while preserving the Phase 238 receipt and baseline hashes.
- [ ] Confirm newly added ExUnit files, if any, are assigned in `test/partition_weights.txt`; verify required CI Playwright projects execute the targeted spec.

## Security Domain

Host authentication and tenant authorization are server-owned. URL filters express operator-requested search only; they must never replace the host scope. Exact-value disclosure uses the already authorized/redacted bundle fields only; never embed a raw source value in an alternate attribute or client-only path. Use synthetic fixtures and keep evidence loopback/database isolation guards. [VERIFIED: `239-CONTEXT.md:18-36`; `239-ADVISOR-ENTRY.md`; `239-ADVISOR-EVIDENCE.md`; `run-e2e.sh:75-157`]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Encoding and Sanitization | yes | Keep HEEx escaping; render only the redacted presentation value in expanded exact text. |
| V2 Validation and Business Logic | yes | Keep the existing `filter_params` allowlist and validation boundary; URL filters do not authorize access. |
| V3 Web Frontend Security | yes | Ensure exact-value disclosure adds no raw value in hidden DOM, attributes or client-only state. |
| V6 Authentication | preserved | Host authentication and mount are unchanged; no new auth flow. |
| V7 Session Management | preserved | Keep existing server/session theme preference; do not add client-side preference storage. |
| V8 Authorization | yes | Server-owned tenant/scope checks remain authoritative for every query/detail read. |
| V11 Cryptography | no new cryptography | No crypto operation or package is in scope. |
| V14 Data Protection | yes | Preserve redaction and distinguish redacted, absent, omitted, null and unavailable evidence. |

Category names follow the current OWASP ASVS 5 taxonomy; this is a scoped category map, not a claim of full ASVS certification. [CITED: OWASP ASVS 5.0 taxonomy]

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tenant scope inferred from URL filter or client state | Elevation of privilege | Keep scope server-owned; retain out-of-scope transaction tests. |
| Full raw value leaks through title/data/aria/copy attributes | Information disclosure | Render only authorized/redacted view values; inspect DOM with a synthetic secret canary. |
| Captured evidence targets reused/unowned DB or browser source | Tampering | Keep fresh partition, loopback-only host, DB existence/ownership, unique output, receipt/hash/ancestry checks. |
| Stale previous result presented under a new scope | Information disclosure / repudiation | Keep displayed query identity tied to rows; test a nonempty old query with a held second request. |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Emulate zoom with viewport or device pixel ratio | Set actual tab zoom through Chrome extension `chrome.tabs.setZoom`; verify with `getZoom` | Chrome tabs API documents current zoom methods; Playwright documents extension loading in persistent Chromium context | Provides a supported path for real browser tab zoom when the isolated headed proof is run. [CITED: Chrome `tabs` API; Playwright Chrome extensions docs] |
| Prove detail values via tooltip/machine attributes/Copy | Visible selectable exact text with an operable disclosure; Copy remains separate convenience | Approved Phase 239 D-06 | Makes value readable with JavaScript enabled and avoids relying on clipboard success. [VERIFIED: `239-CONTEXT.md:21-24`; advisor EVIDENCE] |
| Treat applied filter fields and currently edited form fields as one scope | Keep edits draft until explicit Apply; query URL and active summary name the rows they produced | Approved Phase 239 D-02/D-03 | Avoids accidental query execution and false scope descriptions. [VERIFIED: `239-CONTEXT.md:16-19`] |

**Deprecated/outdated for this phase:** viewport resize, DPR adjustment, CSS scaling/zoom, or Playwright device emulation as substitutes for genuine browser zoom; using title/copy-only content as exact-value reading access. [VERIFIED: approved D-06/D-08; CITED: Chrome and Playwright docs]

## Code Examples

The following is an implementation sketch, not evidence that the extension method has been run. It uses Playwright's documented persistent Chromium context and Chrome's documented tab zoom API; Phase 239 must still prove it in an isolated browser and record actual rendered state. [CITED: Playwright Chrome extensions guide; Chrome `tabs` API]

```ts
// In the extension service worker, after querying the tab under test:
const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
if (tab?.id == null) throw new Error("No active test tab");
await chrome.tabs.setZoom(tab.id, 2);
const zoomFactor = await chrome.tabs.getZoom(tab.id);

// In the Playwright test, read back zoomFactor from the extension worker and assert 2.
// Then assert required controls/evidence are reachable and document width has no overflow.
```

For LiveView behavior, stay with the in-repo URL patch and `handle_params` flow rather than copying a new pattern: `lib/threadline/operator_surface/live/timeline_live.ex:83-178,349-426`, paired with `test/threadline/operator_surface/live/timeline_live_test.exs` and `examples/threadline_phoenix/e2e/tests/operator-timeline-investigation-flow.spec.ts`. [VERIFIED: cited source files were inspected in the retained worktree and the Phase 239 advisor report]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A minimal local Manifest V3 extension can be loaded in the project's Playwright Chromium headed persistent context and `tabs.setZoom` can be measured without interaction with the previously denied Chrome-for-Testing CUA surface. | Don't Hand-Roll / Pitfall 1 / Wave 0 | If isolated automation is prohibited or not operational, actual zoom acceptance remains open; do not substitute emulation. |
| A2 | The current local Elixir 1.17.3 / OTP 27 shell is adequate for focused implementation checks; project toolchain or CI may use a different supported version. | Standard Stack | A runtime mismatch may cause unrelated compile/test failures. Confirm against planned execution environment before claiming green. |

## Open Questions

1. **Can actual tab zoom be driven by the isolated Playwright Chromium extension under the available environment policy?**
   - What we know: Chrome officially exposes `tabs.setZoom/getZoom`; Playwright officially documents loading extensions through a persistent Chromium context, and this host has Playwright 1.60.0 plus a Chromium binary. [CITED: Chrome/Playwright official docs; VERIFIED: local npm and command checks]
   - What's unclear: The method has not been exercised; Phase 238's CUA access to Chrome-for-Testing was denied. [VERIFIED: `238-HANDOFF.md`]
   - Recommendation: Prototype only in a newly launched isolated Playwright context, use the bundled Chromium extension path, record the zoom API readback and browser identity, and stop if that path is denied. Do not attach to the denied browser or count CSS/DPR/viewport emulation as proof.

2. **How should Phase 239 candidate evidence extend Phase 238 custody?**
   - What we know: Existing runner hard-pins Phase 238 receipt, context hashes, base ancestry and exact first-parent commit list, so later commits are rejected. Phase 238 receipt/bundles must remain immutable. [VERIFIED: `run-e2e.sh:96-157`; `238-HANDOFF.md`]
   - What's unclear: The final Phase 239 candidate commit list and context-reconciliation hashes do not yet exist.
   - Recommendation: Add a distinct, fail-closed Phase 239 receipt that chains to the Phase 238 receipt by hash and accepted evidence digest, and records only the explicit Phase 239 forward candidate sequence. Preserve all fresh database, loopback, output, and source/asset checks; test negative cases.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix/OTP | Compile and ExUnit | yes | Elixir 1.17.3, Mix 1.17.3, OTP 27 | Use project's verified CI/runtime if local mismatch causes unrelated failures. |
| Node/npm | Playwright browser tests | yes | Node 22.14.0, npm 11.1.0 | None needed. |
| Playwright Test | Browser E2E | yes | `@playwright/test` 1.60.0 installed | Existing package lock; no install/change needed. |
| Chromium | Browser routes and zoom proof | yes | `/opt/homebrew/bin/chromium` found; Playwright browser bundle should be preferred for extension loading | If extension API is unavailable in isolated browser, report zoom proof blocked; don't use viewport/DPR as substitute. |
| PostgreSQL/psql | LiveView/E2E tests and seeded preview | available dependency in project; no readiness probe run in this research | — | Existing project test/preview setup; verify database readiness before execution. |
| Chrome extension loading | Real 200% zoom method | documentation supports it; not run | `tabs.setZoom` API; extension path unprototyped | Keep UI proof gap open; no claim of pass. |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-CONTEXT.md` — approved constraints and ten requirement IDs.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-ADVISOR-ENTRY.md` — current Home/Timeline patterns, URL query model, tests and LiveView refs.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-ADVISOR-EVIDENCE.md` — transaction/action cardinality, evidence composition, redaction and exact-value gap.
- `.planning/phases/239-investigation-entry-and-transaction-composition/239-ADVISOR-INTERACTION.md` — shared presentation/theme/focus/state ownership and known proof gaps.
- `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-HANDOFF.md`, `238-INTEGRATION-NOTES.md`, `238-ISOLATION-RECEIPT.json` — accepted baseline, source custody, command behavior and test limitations.
- `mix.lock`, `examples/threadline_phoenix/e2e/package-lock.json`, installed npm dependency listing — locked and installed stack versions.
- [Chrome Extensions `tabs` API](https://developer.chrome.com/docs/extensions/reference/api/tabs) — tab `getZoom`, `setZoom` and `setZoomSettings` APIs.
- [Playwright Chrome extensions guide](https://playwright.dev/docs/chrome-extensions) — extension testing requires persistent Chromium context; current Chrome/Edge side-load flags are removed; bundled Chromium is the documented route.
- [Playwright page API](https://playwright.dev/docs/api/class-page) — page viewport operations for distinguishing viewport resize from tab zoom.
- [OWASP ASVS 5 taxonomy](https://cornucopia.owasp.org/taxonomy/asvs-5.0) — current category identifiers used in the scoped security mapping.
- [W3C WCAG 2.2 Understanding Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html), [Resize Text](https://www.w3.org/WAI/WCAG22/Understanding/resize-text.html), and [Keyboard](https://www.w3.org/WAI/WCAG22/Understanding/keyboard) — reflow, enlarged text and keyboard operation guidance.
- [Phoenix LiveView reference](https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html) and [Phoenix Component `async_result`](https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html) — existing navigation, lifecycle and async state references (prior advisor checked current official docs).

### Project source references
- `AGENTS.md`, `PRODUCT.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/config.json`.
- `lib/threadline/operator_surface/live/{start_live,timeline_live,transaction_live}.ex`, `live/timeline_live/filters.ex`, `lib/threadline/query/filter_params.ex`.
- `lib/threadline/operator_surface/{presentation.ex,ui/display.ex,ui/overlay.ex,auth.ex,controllers/theme_controller.ex,style/01_tokens.css,style/04_controls.css,style/09_responsive.css}`.
- `test/threadline/operator_surface/live/{start_live_test,timeline_live_test}.exs`, `test/threadline/operator_surface/{transaction_live_test,presentation_test,ui_test,style_contract_test}.exs`.
- `examples/threadline_phoenix/e2e/{playwright.config.ts,run-e2e.sh,package.json,package-lock.json}` and existing `operator-timeline-investigation-flow.spec.ts`, `operator-accessibility.spec.ts`, `operator-route-states.spec.ts`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — current project lockfiles and installed browser dependencies were inspected; no new dependency recommended.
- Architecture: HIGH — approved context, advisor findings and current source anchors agree.
- Pitfalls: HIGH for query truth, redaction, ownership and baseline custody; MEDIUM for browser zoom until the isolated extension proof is actually run.

**Research date:** 2026-10-09  
**Valid until:** 2026-11-08 for stable project patterns; re-check Playwright/Chrome docs and installed browser behavior before executing zoom proof.
