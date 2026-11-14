# Phase 250: Brand foundation and first whole investigation - Context

**Gathered:** 2026-11-12
**Status:** Ready for planning

<domain>
## Phase Boundary

A support person completes Timeline → transaction → record history → return to the original search in brand-aligned Threadline Admin. Own ADM-08–14 and ADM-16–17, including the directly owned UI/docs lockups and favicons. Phoenix LiveView/HEEx and PhoenixStorybook remain the approved stack. Phase249 fixtures/map and Phase248 fail-closed mount are prerequisites already complete. No SPEC exists.
</domain>

<decisions>
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
</decisions>

<canonical_refs>
## Canonical References

Downstream agents must read relevant sections of these repository-relative sources before planning/implementation.
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/conventions/research-verification-and-efficiency.md`
- `brand/BRAND.md`
- `brand/brand.json`
- `brand/assets/README.md`
- `.planning/research/2026-11-10-brand-admin/README.md`
- `.planning/research/2026-11-10-brand-admin/brand-language.md`
- `.planning/research/2026-11-10-brand-admin/storybook-journeys.md`
- `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-CONTEXT.md`
- `.planning/phases/249-map-jobs-scenarios-and-the-brand-contract/249-VERIFICATION.md`
- `prompts/audit-lib-domain-model-reference.md`
- `prompts/threadline-elixir-oss-dna.md`
- `lib/threadline/operator_surface/components/surface_header.ex`
- `lib/threadline/operator_surface/fonts.ex`
- `lib/threadline/operator_surface/style/01_tokens.css`
- `lib/threadline/operator_surface/presentation.ex`
- `examples/threadline_phoenix/e2e/tests/operator-earned-flows.spec.ts`
- `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts`
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex`
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex`
- `test/threadline/brandbook_token_parity_test.exs`
- `mix.exs`
- `README.md`
- `guides/operator-surface.md`
</canonical_refs>

<code_context>
## Existing Code Insights

- Fonts embeds old Geist/Plex faces with external-resource/data-URI boundaries and an existing opt-out. Replace supplied face data/descriptors and preserve that boundary.
- SurfaceHeader owns Logo.compact, home name, theme form and navigation. Tokens live in the existing dark/light/System CSS lanes. Preserve host scoping.
- Existing earned-flow helpers discover a table's first row; narrow the selected ordinary story by correlation. Existing route-state tests already provide deferred Clipboard doubles, connection waits and truthful failure/focus proof.
- Existing Presentation and UI.Display own UTC/reference/value semantics. Reuse exact null/redacted/missing and unavailable tests; do not invent semantic synonyms.
- README picture, Mix docs/package configuration, example conditional head/static favicon and real unpacked-Hex contracts are existing owned seams. Update together.
- Standard E2E runner resets each invocation; it cannot create matched same-materialization captures. Select the existing Playwright flow against the prepared E2E_BASE_URL without loosening that runner's gates.
</code_context>

<specifics>
## Specific Ideas

Reuse Phase249's ordinary Acme #4521 adoption fixture and approved brand source. Research covered product, accessibility, Elixir/Phoenix integration, host/security compatibility, packaging, evidence identity and adversarial failure modes. The direct favicon/docs closure supersedes a blanket proposal to defer every ExDoc/icon change to Phase253.
</specifics>

<deferred>
## Deferred Ideas

Remaining investigations belong to251; operations/catalog expansion to252; broader inclusive browser/viewport and comprehensive docs/package/release readiness to253. Other old brandbook consumers retain explicit ownership until coupled migration. Fablebook adoption, public login/white-label APIs, backend/capture changes and external publication remain outside scope.

### Reviewed Todos (not folded)

`.planning/todos/pending/2026-10-25-local-gate-ephemeral-postgres-wrapper.md` matched generic test/contract vocabulary, but its permanent Docker wrapper, CI image policy and runner expansion are outside this fixed UI slice. Existing task-owned PostgreSQL already supplies local isolation. Keep the todo pending separately; the relevance score does not override approved scope.
</deferred>

*Phase: 250-brand-foundation-and-first-whole-investigation*
*Context gathered: 2026-11-12; single-pass autonomous discussion, research recommendations selected by agent.*
