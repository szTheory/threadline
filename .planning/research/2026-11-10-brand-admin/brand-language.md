# Brand and language migration findings

## Authority and evidence boundary

The maintainer’s approval date is **2026-11-10**; the brand files describe edition 1.0 as dated **November 3, 2026**. Keep those as approval and edition dates (`brand/BRAND.md:3, 661-663`, original checkout). The authoritative sources are `brand/BRAND.md`, `brand/brand.json`, `brand/tokens.json`, and `brand/assets/README.md`; these currently live in the original checkout, not this retained worktree. The brand assets were inspected, not copied.

This worktree is branch `agent-241-01` with an intentionally dirty UI pass; all work here was read-only. Cached `origin/main` is the better implementation reference (`mix.exs` version 1.1.0); it still carries the old brandbook integration. No fresh remote check, tests, or browser review was performed in this subtask.

## Recommendation

Adopt the new book for identity and customer-facing language. Rebuild the brand integration around its spool lockup, complete light theme, explicit operation colors, type hierarchy, and stable contrast-role IDs. Keep operator-specific layout and semantic tokens owned by the operator stylesheet. Keep existing public APIs, route names, config keys, telemetry, and domain schema names intact unless a separate compatibility decision approves a change.

The most direct coupling is `test/threadline/brandbook_token_parity_test.exs:5-20, 25-47, 51-81, 84-127`: it currently calls `brandbook/tokens.json` and `.css` part of the shipped UI SSOT, rejects `logo-arc`, freezes obsolete “dark-primary”/theme-toggle prose, and tries to put UI gap tokens in the brand token lane. Replace those brandbook-specific contracts. Keep the theme and gap behavior they protect where it remains real: the runtime still supports `:dark | :light | :system` (`guides/operator-surface.md:80-112`), and `--tl-gap-*` remains UI-owned in `style/01_tokens.css:156-161`.

The parity test's header describes broader color parity than its current assertions
implement. Its test bodies check the absence of the logo-only token, old prose and
three gap aliases; they do not compare the curated color values in both themes.
The replacement must test actual mapped values/roles from parsed data, not inherit
a color-parity claim from those comments (`test/threadline/brandbook_token_parity_test.exs:42-127`).

## Migration sequence

1. **Reconcile the base and dirty UI diff.** Use cached `origin/main` as the source baseline and preserve the paused UI pass. Do not treat the old v1.46 worktree’s README/package pins as current release guidance.
2. **Replace the brand authority deliberately.** Update references in README, ExDoc assets, logo component comments, `DESIGN-SYSTEM.md`, package allowlists, and contract tests. The old `brandbook/README.md:3-19, 23-28` explicitly declares its directory, token file, logo family, and old stitch-arc identity authoritative. `brandbook/brand-book.md:178-190, 248-254, 278-283` documents geometry and theme posture that the spool edition retires.
3. **Map brand roles into UI roles.** `brand/tokens.json` (original checkout) supplies brand colors, operation states and type roles; `brand/brand.json:280-426` assigns stable contrast IDs: `body`, `descriptor`, `caption`, `application-copy`, `hero`, `link`, `focus`, `artwork`. Preserve those IDs exactly and check both theme lanes. Map them to functional CSS variables; do not rename the runtime variables to match role IDs.
4. **Keep structural UI tokens separate.** New brand tokens cover color and type, while the old `brandbook/tokens.json` also contains spacing, gaps, radius, shadows, callouts and state aliases (`DESIGN-SYSTEM.md:174-176`). Keep spacing and interaction values in the operator system. Replace the old “brandbook primitives” reference with the new brand source and keep UI semantic aliases in `style/01_tokens.css`.
5. **Migrate visible identity and package contents.** Use the supplied light/dark spool lockups and mark variants. Keep the full brand guide, samples and source fonts maintainer-side. Ship only logo/favicon files actually referenced by README, ExDoc or the packaged UI; update `mix.exs` and `release_artifact_contract_test.exs` together (`origin/main:mix.exs:484-527`, `test/threadline/release_artifact_contract_test.exs:74-89`).
6. **Migrate customer-facing words.** Update README and current guides, retaining filenames, anchors and exact API literals. Retired prose in the parity test should be replaced with tests for current runtime behavior and approved brand facts, not deleted in a way that loses theme/config coverage.

The new operation tokens are distinct per operation and theme, including Redacted text and chip colors (`brand/tokens.json:261-445`, original checkout). Render the operation word every time; color supplements it. Stitch Blue `#4781E6` belongs to the logo artwork, while Thread Blue/Thread Blue Deep serve control, link and focus roles (`brand/BRAND.md:218-383`; `brand/brand.json:280-440`). Existing CSS already has several matching primitives, but operation aliases and light muted-text choices need role-by-role mapping, not blanket token equality (`lib/threadline/operator_surface/style/01_tokens.css:39-110, 187-234`). Keep the color-pair IDs as machine-readable contracts. Validate listed ratios and rendered text, controls, focus rings and artwork; the book says the listed pairs alone do not certify the whole product (`brand/BRAND.md:366-388`).

The new book names Familjen Grotesk 600 for display and headings, Geist for reading/tables, and IBM Plex Mono for identifiers/code. The current package embeds Geist and Plex as WOFF2 with their OFL texts (`lib/threadline/operator_surface/fonts.ex:4-28`, `priv/fonts/README.md:13-32`). The source asset bundle supplies font files and SIL OFL 1.1 licenses (`brand/BRAND.md:390-421, 655-659`; `brand/brand.json:896-939`; `brand/assets/README.md`, original checkout). If Admin headings adopt Familjen, package only the needed web subset/weight and its license alongside runtime fonts; the outlined SVG wordmark itself needs no font. Avoid packaging the full TTF source bundle or all brand collateral. MIT package metadata does not replace the font licenses.

## Vocabulary and compatibility map

| Use in product language | Preserve in code, schema, or precise technical docs | Compatibility note |
| --- | --- | --- |
| **Audit trail library**; call the thing operators read **history** | Hex app `:threadline`; package and module names | Retire “audit platform”, “audit log”, “evidence plane” as broad product positioning (`brand/BRAND.md:99-111, 474-495, 633-638`; `README.md:13-19, 34-52`). Avoid overstating claims that the library has not established. |
| **Record** for a database row; **change** for one insert/update/delete | `AuditChange`, capture columns, SQL use of “row” | Do not rename schemas or change semantics to satisfy prose (`brand/BRAND.md:478-495`; `prompts/audit-lib-domain-model-reference.md:49-92`). |
| **Transaction** for the database transaction grouping changes; **action** for the app-level event | `AuditTransaction`, `AuditAction`, `AuditContext`, `ActorRef`, `Correlation`; `intent` keys/metadata | Keep action, change, transaction, request and actor distinct. Do not mechanically replace public `intent` with `action` or rename serialized fields (`AGENTS.md:11-25`; domain model `:61-92, 331-357`). |
| **Actor** in operator prose | `ActorRef`, actor resolver callbacks and persisted fields | Actor can be a job, service, system or anonymous identity, not only a user (`brand/BRAND.md:478-495`; domain model `:82-92, 454-500`). |
| **Audited table** / **not audited** | `Threadline.Health.trigger_coverage/1`, `mix threadline.verify_coverage`, `covered`/`uncovered`, telemetry and coverage routes | Use approved words in UI labels. Preserve machine-facing “coverage” identifiers and operational vocabulary (`guides/domain-reference.md:243-255`; `guides/operator-surface.md:339-343`). |
| **Redacted** only when a value was replaced before storage; a field left out is **not recorded** | Redaction policy/config/API names and any documented mask/exclude mechanisms | Keep replacement, exclusion, view-time hiding, and missing data distinct. Never present an excluded or unavailable value as `[REDACTED]` (`brand/BRAND.md:340-346, 478-495`; `guides/redaction.md:18-19`). |
| **Host app**; **Threadline Admin** as the visible UI name | `Threadline.OperatorSurface`, `threadline_operator_surface/2`, `/audit` routes, `operator_surface_*` config and telemetry | Use the new name for UI prose. The operator-surface mount, options, routes and support contract are explicitly public/stable (`guides/upgrade-path.md:184-190`; `guides/operator-surface.md:25, 43-78`). Keep filenames and identifiers during this language migration. |

Qualify marketing claims with the implementation boundary: capture applies to tables with installed triggers; history begins when capture is enabled; actor/context can be absent; retention and redaction can limit reconstructable values. The brand’s illustrations and broad boilerplate do not establish those capabilities (`brand/BRAND.md:35-55, 73-91, 566-578`; domain model `:104-155, 304-330`).

## Scoped product decisions

- **White-label:** the identity guide allows a host to replace the top-bar lockup, but explicitly says the product has no logo setting yet (`brand/BRAND.md:135-151, 574-578, 691-701`). The private logo component is hard-coded and operator components are not a public component API (`lib/threadline/operator_surface/components/logo.ex:1-20`; `guides/operator-surface.md:25`). Defer a new branding option. Until one exists, use Threadline’s own identity and do not claim a host can currently replace it.
- **Sign-in:** document that the host app owns authentication, session and sign-in. The existing mount accepts host-owned authorization/actor callbacks and uses the host’s browser pipeline (`guides/operator-surface.md:43-72, 161-185, 218-231`). Do not add an auth provider or promise built-in SSO/basic login; describe SSO only as something a host may supply.
- **Ember:** the new token set omits it. Retire the old `--tl-color-ember` brand primitive (`style/01_tokens.css:51`) after checking internal stress examples; current observed usages are in the stress/refutation examples. Use operation-specific colors only for operation words, and neutral before/after values unless a separate semantic role is specified.
- **Avatar:** no opaque square icon is supplied, and the brand calls it an unresolved need (`brand/BRAND.md:618-620, 691-700`). Defer an avatar asset. Use the mark only at supported sizes and keep it on a transparent background.
- **Theme:** preserve dark default, full light mode and system behavior, plus the existing runtime theme picker/config/API. Replace obsolete “dark-primary” posture prose with the concrete supported theme behavior. Retiring the old `THEME-TOGGLE-01` assertion must not remove the shipped toggle or its docs/tests.

## Related decisions and overlooked angles

Coordinate this with the queued host-authorization/Safe-by-default foundation and the approved UI/journey scope before selecting a milestone. Preserve the API compatibility contract. Also check the release package’s README/ExDoc logo URLs, favicon rendering, font opt-out/CSP guidance, all eight contrast roles in both themes, status words in accessible output, time zones, and history gaps caused by trigger start, retention, excluded fields or absent actor context. The new book’s tagline sits beside the lockup, never inside it (`brand/BRAND.md:93-97, 204-216`).

The first source to replace is the brand-specific contract in `test/threadline/brandbook_token_parity_test.exs`; retain the separate design-system and public-API contracts. No implementation or asset migration is performed by this report.
