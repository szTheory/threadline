# Phase 250: Brand foundation and first whole investigation — Research

**Researched:** 2026-11-12
**Domain:** Phoenix LiveView brand migration, Admin journey, ExDoc and Hex packaging
**Confidence:** MEDIUM

<user_constraints>
## User Constraints

### Locked Decisions

## Implementation Decisions

### Brand roles and artwork
- **D-01:** Treat `brand/BRAND.md`, `brand/brand.json` and supplied assets/tokens as authority. Preserve all eight stable contrast IDs and prove both theme lanes. Keep functional CSS variables as runtime owner; no second runtime registry. Distinguish artwork Stitch Blue, links, focus, control boundaries and operations. Operation words must carry meaning independently of color.
- **D-02:** Inline the supplied paired dark/light lockup SVGs at compile time without changing geometry/colors. Respect 96px lockup and 16px mark minima; existing 132/148px header widths are sufficient. Support System media behavior and an accessible home link. Do not add an adopter asset route, CDN, logo override or CSP-requiring data image.

### Font delivery and native theme behavior
- **D-03:** Ship Familjen Grotesk variable 400–700 for headings (normally 600), Geist variable 400–700 for text/tables, and IBM Plex Mono static 400/500 for IDs. Use the supplied four WOFF2 subsets and all three OFL files. Use Threadline-private CSS family aliases because font-face declarations are global. Preserve `operator_surface_embed_fonts`, its default, false → no embedded faces, host system fallback and offline operation. No TTF payload or new dependency/API.
- **D-04:** Retain native POST, CSRF, session/cookie persistence, validated return path and existing dark/light/system values. Make each choice a native submit button applying immediately. Remove the separate Apply confirmation; retain accessible group/current/focus/keyboard behavior and server authority.

### Ordinary Acme #4521 investigation and exact meaning
- **D-05:** Extend the existing earned-flow browser owner, starting with `table=ticket_replies&correlation_id=walk-acme-4521-close` and applicable committed date predicates. Reach the actual transaction/action, inspect exact values/actor, follow its reply record history, keyboard-copy its complete ID, then return with both URL predicates and visible filters restored. Discover generated primary keys from the actual selected transaction rather than assuming a UUID or selecting the first unrelated row.
- **D-06:** Bind the story to action `ticket_replied_and_closed`, two table changes in one transaction, actor `user/<Manifest closer UUID>` as actually rendered, status open → closed, closed_at null → `2026-05-26T14:30:00Z`, public reply `Thanks — we're closing this out.`, `[REDACTED]` internal note and no secret canary. Visible event time is May 26, 2026, 2:30 PM UTC. The action's real insertion/recording time remains distinct. Do not imply actor always means user or transaction means request/action.
- **D-07:** Bind existing deferred Clipboard API double to the reached full-ID control: exact argument, keyboard activation, pending feedback before promise resolution, truthful success afterwards, retained focus and connected-state waits after navigation/LivePatch. Preserve isolated failure/manual-recovery proofs. This establishes the API/feedback contract, not native clipboard contents. No native clipboard reads/writes, permissions or foreground automation are needed.
- **D-08:** Keep Presentation/UI.Display as shared meaning owners. Redacted means replaced before persistence; left out means excluded/not recorded; null is present empty; omitted/absent snapshot-axis keys remain distinct from deliberate exclusion; unavailable means a read failed. Do not mechanically rename `(omitted)`/`(absent)` to left out or add exceptional facts to the ordinary story. Reuse existing separate renderer/state fixtures for exclusion, missing, unavailable and accepted versus completed jobs.

### Matched before/after evidence
- **D-09:** Plan the baseline before any rendered edits. Use one task-owned isolated database seeded once after Phase249, one partition/port and a selected read-only ordinary journey. Restart only the server between source versions; do not reset/reseed. Record actual target correlation, transaction/change/record IDs, persisted UTC times, read-only target-row fingerprint and run clock. A seed-source hash is not a materialized snapshot.
- **D-10:** Capture the `.threadline-ui` shell/header and content in both halves. Record source and actually served inline CSS/SVG/decoded WOFF2, browser/version, viewport/DPR, theme/effective theme/System scheme, reduced motion and UTC capture time. Measure zoom or mark it unverified; a literal zoom=1 does not measure it. Keep visible timestamp assertions separate from screenshot masking. Reuse existing evidence owners with a narrow pair sidecar; do not weaken historical fresh-partition/evidence-mode gates or build a generic runner/registry.

### Directly owned documentation, icons and packaging
- **D-11:** Migrate README's existing theme-paired picture to the approved lockups with width at least96px. Set ExDoc favicon to `brand/assets/icon/favicon.svg`; use paired approved lockups through existing ExDoc assets/theme hooks and verify actual theme switching/minimum size. Existing ExDoc body.dark contract permits a narrow paired-source hook; verify installed behavior before implementation. No ExDoc fork/dependency. Replace only the existing example Admin favicon bytes at `/images/threadline-admin-favicon.svg` with the supplied favicon. Preserve demo home/login `/favicon.ico`. Adopting applications still own their document heads; no new public favicon route/API.
- **D-12:** Couple those three direct SVG package entries and four WOFF2/all three licenses with exact archive/source parity proof now. Retain unrelated historical brandbook consumers until their owning migration. Favicon follows device scheme as supplied, independently of application theme. Do not ship the whole brand tree or redraw the image.
- **D-13:** Shared accessible name is `Threadline Admin home`. Apply narrow README/guide introduction wording: Threadline is an audit trail library, visible UI Threadline Admin. Preserve public modules, helpers, configuration, routes, query keys, schema, telemetry, filenames/anchors and technical guide identifiers. Broad guide/README/ExDoc/example copy reconciliation remains Phase253.

### Verification, compatibility and discretion
- **D-14:** Use existing component/presentation, mounted route, source/asset, unpacked-package and focused headless browser proof owners. Inspect first-attempt outcomes; retain unchanged proofs honestly and rerun affected boundaries after edits. Automate UAT and independent visual/copy judgment; no routine human verification. Use background managed apps/tests with real exits and no desktop focus.
- **D-15:** Preserve optional Phoenix compile/host CSS/script/font boundaries and approved public contracts. No runtime dependency, React/Fablebook adapter, login/white-label API, backend redesign, publication, external writes, version choice or renewed historical full-repeat grant. Scope approval covers necessary focused checks and bounded fixes; explicit specific stops remain intact.

### Agent discretion

The autonomous lifecycle authorizes routine implementation choices within these researched recommendations. No new public-contract or irreversible decision is open. Resolve exact private helper boundaries, test composition and plan sequencing from current source, with independent review and no reopening of accepted policy.

### Deferred Ideas

Remaining investigations belong to251; operations/catalog expansion to252; broader inclusive browser/viewport and comprehensive docs/package/release readiness to253. Other old brandbook consumers retain explicit ownership until their coupled migration. Fablebook adoption, public login/white-label APIs, backend/capture changes and external publication remain outside scope.

#### Reviewed Todos (not folded)

`.planning/todos/pending/2026-10-25-local-gate-ephemeral-postgres-wrapper.md` matched generic test/contract vocabulary, but its permanent Docker wrapper, CI image policy and runner expansion are outside this fixed UI slice. Existing task-owned PostgreSQL already supplies local isolation. Keep the todo pending separately; the relevance score does not override approved scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ADM-08 | Rendered UI colors map the approved brand roles to UI semantic tokens, including all eight stable contrast IDs in both themes; artwork, link/focus and control boundaries retain their distinct roles. | Existing dark/light/System token lanes; brand.json is parity source; test mappings and both lanes. |
| ADM-09 | Threadline-owned UI/docs use the supplied spool lockups and favicons with correct theme variants, fixed Stitch Blue artwork, supported minimum sizes and unchanged asset geometry. | Existing Logo, README, ExDoc hooks and Admin static icon; exact source/archive parity. |
| ADM-10 | The served heading/body/identifier fonts and weights follow the approved Familjen Grotesk, Geist and IBM Plex Mono roles, with required licenses, offline delivery and usable host opt-out/system fallback. | Existing compile-time embedder and token layer; supplied four WOFF2 and all three OFLs. |
| ADM-11 | Dark-default, full light and System themes remain usable, immediately selected and server-resolved through the existing native CSRF-protected theme flow. | Existing header/controller/session/cookie path and CSS theme lanes; test immediate POST and persisted behavior. |
| ADM-12 | User-facing UI/docs use Threadline Admin, audit trail library and the approved plain vocabulary while preserving public modules, options, schemas, telemetry names, URLs and query contracts. | Narrow README.md and guides/operator-surface.md introductions; keep technical names/contracts, reserve broad reconciliation for Phase253. |
| ADM-13 | The interface preserves the distinct meanings of action/change/transaction/request, actor/user, Redacted/left out/null/missing/unavailable, and accepted/completed work without unsupported assurance claims. | Presentation/UI.Display and existing fixture families; do not add exceptions to the ordinary story. |
| ADM-14 | Support can find a ticket change, inspect its transaction and exact values/actor, open record history, copy its identifier and return with the original search intact through mounted host routes. | Extend existing earned-flow to correlation/date selection, actual IDs, deferred clipboard double and restored filters. |
| ADM-16 | Before/after values remain exact and neutrally presented, with missing/redacted/left-out cases unambiguous and operation words conveying meaning independently of color. | Existing Presentation/state contracts and separate exception fixtures; ordinary story asserts exact values and operation words. |
| ADM-17 | Displayed times identify their time zone, and compact identifiers expose/copy the complete unchanged value with keyboard focus and truthful success/failure feedback. | Existing UTC rendering and clipboard doubles; assert UTC, full ID, keyboard, pending/success/failure, focus and connection. |

Descriptions are copied verbatim from .planning/REQUIREMENTS.md:25-37. [VERIFIED: .planning/REQUIREMENTS.md:25-37]
</phase_requirements>

## Summary

No new runtime package or framework is needed. Keep work in the existing Phoenix LiveView/HEEx token and component stack, example app's Storybook/Playwright boundary, current ExDoc hooks and Hex artifact contracts. Approved brand/ files are identity authority; unrelated brandbook/ consumers retain their ownership until coupled migration. [VERIFIED: AGENTS.md:133-163; mix.exs:512-529; test/threadline/release_artifact_contract_test.exs:76-90]

**Primary recommendation:** Plan a baseline-first implementation. Prepare exact #4521 selection without rendered production changes, capture the current version on the already-seeded task database, then update tokens/logo/fonts/theme and directly owned docs/icons/package paths. Repeat the same read-only journey on the same materialized rows. Compare IDs, persisted times, target-row fingerprint, served assets, and shell/content captures. The standard E2E runner resets demo data and cannot run the pair. [VERIFIED: .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md D-09; examples/threadline_phoenix/e2e/run-e2e.sh:416-433; examples/threadline_phoenix/e2e/playwright.config.ts:1-4]

A material source constraint needs a named proof: installed ExDoc 0.40.1 emits one logo image and caps it at 48px. Existing head/body hooks and body.dark behavior support the approved pair, but the current head hook must override the size and generated docs must prove theme switching plus at least 96px rendered width. [VERIFIED: deps/ex_doc/lib/ex_doc/formatter/html/templates/sidebar_template.eex:11-14; deps/ex_doc/formatters/html/dist/html-elixir-YJO4MOOW.css:1; deps/ex_doc/formatters/html/dist/html-YU4BZFVS.js:1; mix.exs:512-529,659-754] [CITED: https://ex-doc.hexdocs.pm/0.40.1/ExDoc.html]

## Architectural Responsibility Map

| Capability | Primary tier | Secondary tier | Rationale |
|---|---|---|---|
| Brand semantic tokens/theme appearance | Browser / Client | Frontend Server | Existing scoped CSS owns roles and dark/light/System lanes; server mount/controller keeps theme choice authoritative. [VERIFIED: lib/threadline/operator_surface/style/01_tokens.css:1-284; lib/threadline/operator_surface/controllers/theme_controller.ex:1-20] |
| Theme submit and persistence | API / Backend | Browser / Client | Existing Phoenix CSRF POST, theme allowlist, session/cookie and validated return path own behavior. [VERIFIED: lib/threadline/operator_surface/components/surface_header.ex:99-117; lib/threadline/operator_surface/controllers/theme_controller.ex:1-20] |
| Logo, fonts and Admin favicon | Browser / Client | Frontend Server | Shared compile-time SVG/font delivery plus one existing example static asset; no adopter route. [VERIFIED: lib/threadline/operator_surface/components/logo.ex:1-28; lib/threadline/operator_surface/fonts.ex:1-65; examples/threadline_phoenix/lib/threadline_phoenix_web/components/layouts/app.html.heex:1-15] |
| Ordinary investigation | Frontend Server | Database / Storage | Existing mounted Timeline/transaction/history routes and browser journey read seeded action/change rows. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts:1-175; examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex:63-90] |
| README, ExDoc and archive identity | CDN / Static | Frontend Server | Mix docs/package configuration owns generated output and what ships; the Hex archive is the boundary. [VERIFIED: mix.exs:512-529; test/threadline/release_artifact_contract_test.exs:76-90] |
| Before/after evidence | Browser / Client | Database / Storage | Existing capture owner plus read-only target fingerprint; direct base URL avoids reset runner. [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts:1-4; examples/threadline_phoenix/e2e/run-e2e.sh:416-433] |

## Project Constraints (from AGENTS.md)

- Preserve capture/semantics/exploration separation and domain terms; brand work must not redefine transaction, action, request or actor meaning. [VERIFIED: AGENTS.md:9-28]
- Use approved brand/; inspect the parity test; retain unrelated old references until their coupled owner migrates components, docs and tests. [VERIFIED: AGENTS.md:133-141]
- Phoenix LiveView/HEEx and PhoenixStorybook remain the stack. No React, speculative Fablebook adapter, white-label or login API. [VERIFIED: AGENTS.md:143-163]
- Preserve host-owned trigger migrations, optional Phoenix compile/host CSS/script/font boundaries and public contracts. [VERIFIED: AGENTS.md:78-86; .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md D-15]
- Use normal fixtures separately from stress fixtures; validate an ordinary whole-task path with shared components and matched behavior/accessibility proof. [VERIFIED: AGENTS.md:143-155]
- Prefer named mix verify/ci entrypoints, honest default tests and doc contract tests. [VERIFIED: AGENTS.md:49-76]
- Use managed background sessions with real exit status; no routine desktop focus. Honor attempt/window limits and stop/handoff requirements. [VERIFIED: AGENTS.md:56-68]
- Keep committed links repository-relative; omit machine-local research packet paths. [VERIFIED: AGENTS.md:88-91]
- Zero human verification is default: executable checks and independent agent review for judgment calls. [VERIFIED: .planning/PROJECT.md:834-840]

## Standard Stack

No install or dependency update is needed. Versions below are repository pins, not latest-registry claims. [VERIFIED: .tool-versions:1-3; mix.lock:15,32,34; examples/threadline_phoenix/mix.lock:36,39,41; examples/threadline_phoenix/e2e/package-lock.json:456-464]

| Existing stack | Locked version | Phase use |
|---|---:|---|
| Elixir / Erlang OTP | 1.17.3-otp-27 / 27.3.4.15 | Root Mix and compile-time UI. [VERIFIED: .tool-versions:2-3] |
| Phoenix / LiveView (root) | 1.8.13 / 1.2.11 | Optional host integration boundary. [VERIFIED: mix.lock:32,34] |
| Phoenix / LiveView / PhoenixStorybook (example) | 1.8.13 / 1.1.33 / 1.2.0 | Mounted demo flow and stories. [VERIFIED: examples/threadline_phoenix/mix.lock:36,39,41] |
| ExDoc | 0.40.1 | Existing docs/assets and hooks. [VERIFIED: mix.lock:15; mix.exs:512-529] |
| Node / npm | 22.14.0 / 10.9.2 | Existing browser-test tools; no dependency change. [VERIFIED: .tool-versions:1; local probe] |
| Playwright Test | 1.60.0 | Existing earned-flow and route-state specs. [VERIFIED: examples/threadline_phoenix/e2e/package-lock.json:456-464] |

Exact checked-in version text: “nodejs 22.14.0”, “erlang 27.3.4.15”, “elixir 1.17.3-otp-27”; “"ex_doc": {:hex, :ex_doc, "0.40.1"”, “"phoenix": {:hex, :phoenix, "1.8.13"”, root “"phoenix_live_view": {:hex, :phoenix_live_view, "1.2.11"”, example “"phoenix_live_view": {:hex, :phoenix_live_view, "1.1.33"”, “"phoenix_storybook": {:hex, :phoenix_storybook, "1.2.0"”, and Playwright “"version": "1.60.0"”. [VERIFIED: .tool-versions:1-3; mix.lock:15,32,34; examples/threadline_phoenix/mix.lock:36,39,41; examples/threadline_phoenix/e2e/package-lock.json:456-464]

**Installation:** none. Package Legitimacy Audit is inapplicable because no package is added.

Current GSD position is Phase 250 planning after Phases 248 and 249 complete. Keep Phase 248's fail-closed mount/startup gate intact. STATE says the historical repeat grant was consumed; Phase 250's focused local checks remain within this phase's scope and do not renew that grant. [VERIFIED: .planning/STATE.md:1-45]

## Architecture Patterns

### System flow

~~~mermaid
flowchart LR
  S[Support person] --> M[Authenticated mounted Admin]
  M --> T[Timeline with date/table/correlation filters]
  T --> A[Actual transaction/action]
  A --> R[Reply record history]
  R --> C[Full identifier control]
  C -->|deferred API double| F[Truthful pending/success or failure]
  R -->|close| T
  T -->|validated return| M
  DB[(same seeded database)] --> T
  DB --> A
  DB --> R
  Brand[Approved brand source] --> CSS[Existing token/theme CSS]
  Brand --> ASSET[Compile-time SVG and private font faces]
  CSS --> M
  ASSET --> M
  Docs[README, ExDoc, package allowlist] --> OUT[Generated docs and Hex archive]
  M --> PAIR[Matched baseline/after proof]
  DB --> PAIR
~~~

### Component responsibilities

| Owner | Current seam | Plan action |
|---|---|---|
| Tokens | lib/threadline/operator_surface/style/01_tokens.css; test/threadline/brandbook_token_parity_test.exs | Replace old authority with brand/brand.json; verify all eight pairs in dark/light against functional variables. |
| Logo/header/theme | lib/threadline/operator_surface/components/logo.ex; lib/threadline/operator_surface/components/surface_header.ex; lib/threadline/operator_surface/controllers/theme_controller.ex | Inline supplied paired SVGs at compile time; preserve accessible name, immediate native submit and session/cookie/return contracts. |
| Fonts | lib/threadline/operator_surface/fonts.ex; token CSS | Embed supplied WOFF2 with private aliases; preserve opt-out/default/false, fallback and offline use. |
| Semantics | lib/threadline/operator_surface/presentation.ex and UI.Display | Reuse date/value/reference renderer and distinct state fixtures. |
| Example icon | examples/threadline_phoenix/priv/static/images/threadline-admin-favicon.svg; examples/threadline_phoenix/lib/threadline_phoenix_web/components/layouts/app.html.heex; examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs | Replace only bytes at existing URL; keep demo home/login icon; compare served bytes and MIME. |
| Journey/copy | examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts; examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts | Add correlation/date selection and exact journey checks; reuse deferred double/failure focus proof. |
| Docs/package | README, guides/operator-surface.md introduction, mix.exs and existing contracts | Narrow copy change; ExDoc identity through hooks; exact asset allowlist and archive byte parity. |
| Pair evidence | examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts and current evidence owner | Capture shell/header and content; narrow sidecar with source/served asset identity, conditions and read-only row fingerprint. |

The exact direct package scope is three SVGs: brand/assets/logo/threadline-lockup-dark.svg, brand/assets/logo/threadline-lockup-light.svg and brand/assets/icon/favicon.svg; four WOFF2 files under brand/assets/fonts/web/: FamiljenGrotesk-normal-400-700.woff2, Geist-normal-400-700.woff2, IBMPlexMono-normal-400.woff2 and IBMPlexMono-normal-500.woff2; plus OFL-FamiljenGrotesk.txt, OFL-Geist.txt and OFL-IBMPlexMono.txt under brand/assets/fonts/. Compare this exact set and source bytes with the unpacked Hex archive. Do not include the rest of brand/. [VERIFIED: brand/assets/README.md:7-15,24-45; brand/assets/fonts/web/fonts.css:1-4; repository asset inventory read this session; mix.exs:493; test/threadline/release_artifact_contract_test.exs:282-330]

### Pattern 1: One approved token source

Keep runtime CSS custom properties as owner and test them against approved JSON in both theme lanes. Exact stable IDs read from source: "body", "descriptor", "caption", "application-copy", "hero", "link", "focus", "artwork". [VERIFIED: brand/brand.json:280-424] Link, focus, control boundary and operation meanings remain distinct. [VERIFIED: .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md D-01]

### Pattern 2: Compile-time local assets

Use the supplied paired SVGs and exact descriptors below, but generate Threadline-private aliases in the embedder because font-face names are global. Keep all three OFLs and existing false opt-out; no TTF, CDN or public asset route. [VERIFIED: brand/assets/fonts/web/fonts.css:1-4; brand/assets/README.md:37-45; lib/threadline/operator_surface/fonts.ex:1-65]

~~~css
@font-face{font-family:'Familjen Grotesk';font-style:normal;font-weight:400 700;font-display:swap;src:url('FamiljenGrotesk-normal-400-700.woff2') format('woff2')}
@font-face{font-family:'Geist';font-style:normal;font-weight:400 700;font-display:swap;src:url('Geist-normal-400-700.woff2') format('woff2')}
@font-face{font-family:'IBM Plex Mono';font-style:normal;font-weight:400;font-display:swap;src:url('IBMPlexMono-normal-400.woff2') format('woff2')}
@font-face{font-family:'IBM Plex Mono';font-style:normal;font-weight:500;font-display:swap;src:url('IBMPlexMono-normal-500.woff2') format('woff2')}
~~~

### Pattern 3: Native immediate theme submit

Preserve theme allowlist values exactly as "light", "dark" and "system"; submit each choice natively and immediately. Keep server validation, CSRF, session/cookie persistence and validated return path. [VERIFIED: lib/threadline/operator_surface/controllers/theme_controller.ex:9-20; .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md D-04]

### Pattern 4: Same-materialization evidence

Capture baseline before rendered production edits. Record target correlation, actual transaction/change/record IDs, persisted UTC times, read-only target-row fingerprint and capture clock. After edits restart only app; keep DB/partition/port, with no recreate/migrate/reset/reseed. Recapture the same journey and shell/content; record actually served CSS/SVG/decoded WOFF2, browser/version, viewport/DPR, theme/effective system scheme, reduced motion, measured zoom or unverified, and UTC. Preserve existing evidence gates; screenshots do not prove timestamp semantics. [VERIFIED: .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md D-09–D-10]

### Pattern 5: ExDoc paired source using installed hooks

Official ExDoc 0.40.1 docs support logo/favicon/assets and HTML hooks. The installed sidebar emits one image; its CSS is exactly .sidebar .sidebar-projectImage img{display:block;max-width:48px;max-height:48px}. [CITED: https://ex-doc.hexdocs.pm/0.40.1/ExDoc.html] [VERIFIED: deps/ex_doc/lib/ex_doc/formatter/html/templates/sidebar_template.eex:11-14; deps/ex_doc/formatters/html/dist/html-elixir-YJO4MOOW.css:1]

Use the existing head hook for a narrow size override and body hook to synchronize the logo source with ExDoc's actual theme class. The installed bundle contains rr="dark" and document.body.classList.toggle(rr,t). Build docs and prove both variants plus displayed width ≥96px; no fork or dependency. [VERIFIED: deps/ex_doc/formatters/html/dist/html-YU4BZFVS.js:1; mix.exs:659-754] [CITED: https://ex-doc.hexdocs.pm/0.40.1/ExDoc.html]

## Don't Hand-Roll

| Problem | Avoid | Existing owner |
|---|---|---|
| Runtime colors | Duplicate token registry | Scoped CSS variables + JSON parity test |
| Consumer assets | New public route, CDN, data image or logo API | Compile-time supplied SVGs and current static Admin icon |
| Fonts | TTF payload, CDN, global host override | Existing embedder, supplied WOFF2, private aliases and OFLs |
| Theme state | JS/localStorage or new endpoint | Native CSRF POST/controller/session/cookie |
| Story selection | UUID assumptions or first row | Correlation/date filtered mounted transaction; discover actual record ID |
| Paired evidence | Generic registry/runner or reset path | Existing evidence owner plus narrow sidecar/direct base URL |
| ExDoc pair | Formatter fork or new docs tool | Existing hooks and generated-site proof |

## Common Pitfalls

1. **Baseline after rendered edit:** invalidates comparison. Make baseline the first task; test-only selection preparation is acceptable if rendered production sources stay unchanged. [VERIFIED: .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md D-09–D-10]
2. **Standard E2E runner between halves:** it runs Ecto setup and demo reset; use direct Playwright with E2E_BASE_URL, restarting only server. [VERIFIED: examples/threadline_phoenix/e2e/run-e2e.sh:416-433; examples/threadline_phoenix/e2e/playwright.config.ts:1-4]
3. **Selecting first row by table only:** current helper can choose unrelated data; filter exact correlation/date and assert target action before resolving IDs. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts:41-75; .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md D-05]
4. **Collapsing event/insertion times or meanings:** preserve action/event distinctions, actor/user, transaction/request and absent/left-out/null/redacted/unavailable/accepted/completed semantics. [VERIFIED: examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex:62-74; examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex:63-90; AGENTS.md:9-28; .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md D-06–D-08]
5. **Ignoring ExDoc 48px cap:** approved 96px logo fails without head-hook override; prove in generated docs and verify theme from installed JS. [VERIFIED: deps/ex_doc/formatters/html/dist/html-elixir-YJO4MOOW.css:1; deps/ex_doc/formatters/html/dist/html-YU4BZFVS.js:1; mix.exs:659-754]
6. **Global font collision/ignored opt-out:** use private aliases, inspect served bytes, preserve licenses, false behavior and system fallback. [VERIFIED: lib/threadline/operator_surface/fonts.ex:1-65; brand/assets/fonts/web/fonts.css:1-4; brand/assets/README.md:37-45]
7. **Overstating clipboard proof:** deferred test double covers API argument/feedback, not native clipboard contents or permissions. [VERIFIED: examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts:208-300; .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md D-07]
8. **Broad old-doc cleanup:** only update direct README/guide/ExDoc/icon/package scope; preserve other references for their owners. [VERIFIED: .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md D-11–D-13]

## Code Examples

Exact contrast IDs: "body", "descriptor", "caption", "application-copy", "hero", "link", "focus", "artwork". [VERIFIED: brand/brand.json:280-424]

Exact face descriptors are shown in Pattern 2 from brand/assets/fonts/web/fonts.css:1-4.

ExDoc installed theme evidence is rr="dark" and document.body.classList.toggle(rr,t). [VERIFIED: deps/ex_doc/formatters/html/dist/html-YU4BZFVS.js:1]

## State of the Art

| Earlier assumption | Verified current state | Impact |
|---|---|---|
| ExDoc paired logo/theme behavior should be deferred or guessed. | Pinned ExDoc 0.40.1 exposes hooks; body.dark is installed behavior; default logo max is 48px. | Existing closure is feasible with narrow override and generated output proof. [VERIFIED: deps/ex_doc/formatters/html/dist/html-YU4BZFVS.js:1; deps/ex_doc/formatters/html/dist/html-elixir-YJO4MOOW.css:1; mix.exs:659-754] [CITED: https://ex-doc.hexdocs.pm/0.40.1/ExDoc.html] |
| One logo screenshot is enough for before/after. | Context requires shell plus content and same persisted rows/IDs/times/assets/conditions. | Capture baseline first and preserve materialized DB. [VERIFIED: .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md D-09–D-10] |
| ASVS v4 headings can be used without version. | OWASP lists ASVS 5.0.0 as current stable (published 2025-05-30); IDs may change. | Use version-pinned current category names. [CITED: https://asvs.owasp.org/; https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.json] |

## Assumptions Log

No decision relies solely on training knowledge. Generated ExDoc sizing/theme behavior remains an execution proof, not a policy assumption.

## Open Questions

No public contract, policy, dependency or scope decision remains open. Assign a generated-ExDoc proof: paired image switches with installed body theme and renders at least 96px after the hook override. No user checkpoint is needed; focused local verification is authorized. [VERIFIED: .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md D-11, D-14–D-15; deps/ex_doc/formatters/html/dist/html-elixir-YJO4MOOW.css:1; deps/ex_doc/formatters/html/dist/html-YU4BZFVS.js:1]

## Environment Availability

| Dependency | Available | Version / note | Fallback |
|---|---:|---|---|
| Elixir / Erlang | ✓ | Elixir 1.17.3-otp-27, Erlang 27.3.4.15; local matches pins. [VERIFIED: .tool-versions:2-3; local probe] | None |
| Node / npm | ✓ | 22.14.0 / 10.9.2. [VERIFIED: .tool-versions:1; local probe] | None |
| PostgreSQL | ✓ | Task-owned 15.17 on loopback 60025 per handoff; not used/probed during research. [VERIFIED: task handoff] | Do not use shared services or reset runner |
| Playwright | Partial | Package lock pins 1.60.0; browser was not launched/version-checked. [VERIFIED: examples/threadline_phoenix/e2e/package-lock.json:456-464] | Use existing browser-managed environment; no dependency install |

No missing dependency was identified. No app, browser, database service or test was run during research.

## Validation Architecture

Nyquist validation is enabled in .planning/config.json:53-54.

### Test framework

| Property | Value |
|---|---|
| Framework | ExUnit root/example; Playwright Test for browser flows. [VERIFIED: AGENTS.md:39-53; examples/threadline_phoenix/e2e/package.json] |
| Config | Root/example mix.exs and examples/threadline_phoenix/e2e/playwright.config.ts. |
| Focused command | Existing specific ExUnit owners, then direct Playwright against prepared E2E_BASE_URL. |
| Full command | mix ci.all, only if the bounded plan gate calls for it. [VERIFIED: AGENTS.md:49-53] |

### Requirements → test map

| Req | Behavior | Owner and automation |
|---|---|---|
| ADM-08 | All pairs map to CSS variables in dark/light; semantic roles remain distinct. | test/threadline/brandbook_token_parity_test.exs, test/threadline/operator_surface/style_byte_lock_test.exs, mounted accessibility checks. |
| ADM-09 | Variants, geometry/minima and README/ExDoc/Admin favicon match source. | README/ExDoc/archive contracts, examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs and generated-doc browser proof. |
| ADM-10 | Served fonts/weights, licenses, offline and opt-out/fallback. | Font/style contracts and archive parity; inspect decoded served bytes in sidecar. |
| ADM-11 | Dark/light/system native CSRF choice applies and persists immediately. | Header/controller tests and mounted browser tests including System build. |
| ADM-12 | Approved copy changes while public names remain. | README/guide contracts and independent copy review. |
| ADM-13 | Semantic distinctions remain truthful. | Presentation/UI.Display fixtures and ordinary-flow assertions. |
| ADM-14 | Filtered selection → actual transaction/action → history → full ID → restored filters. | Extend examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts; direct Playwright on same DB. |
| ADM-16 | Exact neutral values, distinct exception semantics and operation words. | Presentation/state contracts and focused journey assertions. |
| ADM-17 | UTC, full ID, keyboard, truthful pending/success/failure and focus. | Existing route-state double and earned-flow; visible time assertions separate from screenshot masks. |

### Suggested focused commands

Execution guidance only; none was run:

~~~sh
mix test test/threadline/brandbook_token_parity_test.exs test/threadline/operator_surface/style_byte_lock_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/code_walkthrough_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs

cd examples/threadline_phoenix
mix test test/threadline_phoenix_web/operator_surface_test.exs
~~~

Use mix verify.format and MIX_ENV=dev mix docs --warnings-as-errors for relevant format/docs gates. [VERIFIED: AGENTS.md:30-53; mix.exs:337]

For the pair invoke the focused Playwright spec directly with E2E_BASE_URL from its e2e directory. Do not use examples/threadline_phoenix/e2e/run-e2e.sh; it resets demo data. [VERIFIED: examples/threadline_phoenix/e2e/playwright.config.ts:1-4; examples/threadline_phoenix/e2e/run-e2e.sh:416-433]

Against the prepared app, the focused invocation is: from examples/threadline_phoenix/e2e, run E2E_BASE_URL="$THREADLINE_PHASE250_APP_URL" ./node_modules/.bin/playwright test tests/operator-earned-flows.spec.ts --project=desktop-chromium. THREADLINE_PHASE250_APP_URL must name the separately preflighted HTTP application listener, never the owned PostgreSQL listener on60025. Select only the ordinary read-only case using a precise test filter, not unrelated cases in the spec. Use examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts as the same read-only journey in both halves; do not invoke a runner that resets server-side demo data.

### Sampling rate and Wave 0 gaps

- Per task: focused component, ExUnit or docs contract.
- Per phase: affected root/example owners, generated docs and one focused whole journey.
- Baseline first and before rendered edits; no reset/reseed before after-run.
- No Wave 0 framework/dependency; update existing owners and add only necessary assertions plus narrow pair sidecar.

## Security Domain

OWASP identifies ASVS 5.0.0 as stable, published 2025-05-30; pin category names to this version. [CITED: https://asvs.owasp.org/; https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.json]

### Applicable ASVS 5.0.0 categories

| Category | Applies | Phase control |
|---|---:|---|
| V1 Encoding and Sanitization | Yes | Preserve HEEx contextual escaping; use only supplied trusted compile-time SVG and safe text output. |
| V2 Validation and Business Logic | Yes | Preserve theme validation and safe local return-path validation. |
| V3 Web Frontend Security | Yes | Preserve native CSRF POST, accessible controls and focus; no client-only theme persistence. |
| V7 Session Management | Yes | Keep session/cookie behavior; no token redesign. |
| V8 Authorization | Yes | Preserve existing Admin authentication/authorization on mounted routes and history access. |
| V13 Configuration | Yes | Keep local assets/package allowlist, font opt-out and no new CDN/route. |

This is a phase-scoped control map, not an ASVS compliance claim. [CITED: OWASP ASVS 5.0.0 requirements JSON linked above]

### Threat patterns

| Pattern | STRIDE | Mitigation |
|---|---|---|
| Cross-site theme submission | Spoofing / Tampering | Preserve CSRF-protected POST and server validation. |
| Unsafe return target | Spoofing / Elevation | Preserve validated local return-path behavior. |
| Unauthenticated direct history route | Elevation | Keep Admin auth checks while extending the flow. |
| SVG/copy markup injection | Tampering / Elevation | Use repository SVGs and escaped text; no user-controlled HTML/data URL. |
| Remote asset dependency | Denial of service / Tampering | Keep fonts/logos local and offline; no CDN. |

Preservation checks only, no new security feature. [VERIFIED: AGENTS.md:78-86; .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md D-02–D-04, D-15]

## Sources

### Primary in-repository sources read this session
- .planning/phases/250-brand-foundation-and-first-whole-investigation/250-CONTEXT.md — accepted scope and D-01–D-15.
- .planning/REQUIREMENTS.md:25-37; .planning/STATE.md:1-45 — requirements and current handoff.
- AGENTS.md:9-28,49-91,133-163; .planning/PROJECT.md:834-840 — domain, workflow, path and verification rules.
- brand/BRAND.md, brand/brand.json:280-424, brand/tokens.json:656-684, brand/assets/README.md, brand/assets/fonts/web/fonts.css:1-4 — brand, token, font and asset sources.
- lib/threadline/operator_surface/style/01_tokens.css:1-284; lib/threadline/operator_surface/components/surface_header.ex:1-117; lib/threadline/operator_surface/controllers/theme_controller.ex:1-20; lib/threadline/operator_surface/fonts.ex:1-65; lib/threadline/operator_surface/presentation.ex — runtime owners.
- examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex:62-74; examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex:63-90; examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts:1-175; examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts:208-300 — fixture, route and clipboard owners.
- mix.exs:493,512-529,659-754; README.md; test/threadline/readme_doc_contract_test.exs; test/threadline/code_walkthrough_doc_contract_test.exs; test/threadline/release_artifact_contract_test.exs:76-90,282-330; examples/threadline_phoenix/test/threadline_phoenix_web/operator_surface_test.exs:22-26 — docs, package and icon contracts.
- examples/threadline_phoenix/e2e/run-e2e.sh:416-433; examples/threadline_phoenix/e2e/playwright.config.ts:1-4; examples/threadline_phoenix/e2e/package-lock.json:456-464 — reset behavior and pinned tools.
- .planning/conventions/research-verification-and-efficiency.md; .planning/config.json:53-54 — research/efficiency and validation settings.

### Official documentation
- [ExDoc 0.40.1](https://ex-doc.hexdocs.pm/0.40.1/ExDoc.html) — logo, favicon, assets and HTML hooks.
- [OWASP ASVS overview](https://asvs.owasp.org/) — stable version and versioned references.
- [OWASP ASVS 5.0.0 requirements](https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.json) — current category names.

## Metadata

**Confidence breakdown:** Standard stack HIGH (locked versions); architecture HIGH (current seams opened); pitfalls MEDIUM (source behavior verified, paired browser/generated-doc proof remains).
**Research date:** 2026-11-12
**Valid until:** 2026-12-12 for local seams; recheck if ExDoc lock changes.

## Whole-flow link repair: accepted recommendation applied before final proof

The accepted before route records a real legacy gap. Current [Timeline row links](../../../../lib/threadline/operator_surface/live/timeline_live/changes.ex) receive filter context but omit it from transaction hrefs; [TransactionLive](../../../../lib/threadline/operator_surface/live/transaction_live.ex) returns with only correlation or a bare Timeline path. [RowHistoryLive](../../../../lib/threadline/operator_surface/live/row_history_live.ex) canonicalizes merged params, so its path table can also mask a different Timeline table predicate. The existing [Timeline route helper](../../../../lib/threadline/operator_surface/live/timeline_live/helpers.ex) owns safe single-key/schema-aware history links. The coherent remedy uses these existing owners, existing origin/filter keys, URI-query separation and the current filter validator. Preserve the explicit unfiltered marker added in Plan06, direct-entry defaults and server-owned authorization. Plan07 now owns the source repair and focused link/mounted regressions; Plan08 observes the actual full UI journey. This reuses the earlier navigation research and narrows ownership; it does not reopen the accepted brand or authorize new routes/APIs.
