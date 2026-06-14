# Threadline Brand Book

## Source Of Truth

Threadline makes system history followable.

Threadline is an open-source audit library for Elixir teams using Phoenix, Ecto, and PostgreSQL. It captures database changes, connects them to actions and request context, and makes the resulting history readable through timelines, diffs, exports, coverage checks, and operator workflows.

Primary tagline:

> Follow what happened.

Short positioning:

> Audit history for Phoenix, Ecto, and PostgreSQL.

Long positioning:

> Threadline gives Phoenix and Ecto teams an audit system they can actually use. It captures row-level changes at the database layer, connects them to actors, actions, and request context, and makes the result explorable through readable timelines, diffs, filtering, and operational tooling.

## Brand DNA

Brand essence:

> Connected audit history.

Audience:

- Backend engineers adopting audit capture.
- Platform and SRE teams operating production systems.
- Security and compliance engineers who need evidence without opaque vendor theater.
- Support and operations teams who need readable timelines and diffs.
- OSS contributors evaluating whether the library is serious and maintainable.

Emotional tone:

- Calm in tense moments.
- Exact without being cold.
- Useful over impressive.
- Trustworthy because it is inspectable.

Technical promise:

> If something changed, Threadline helps connect the change to the action, actor, request, transaction, and surrounding evidence.

Personality traits:

- precise
- grounded
- composed
- technically literate
- quietly confident
- generous with context

Anti-traits:

- flashy
- cute
- cyberpunk
- militarized
- compliance-bureaucratic
- generic SaaS
- fake-futurist

This should feel like:

- a clear line through a confusing incident
- an engineer-friendly audit timeline
- a map of system change that can be inspected
- a serious OSS project with practical taste

This should never feel like:

- a security vendor landing page
- a lock or shield compliance badge
- abstract nodes with no domain meaning
- consumer-app gradients
- a random SaaS dashboard template

## Messaging Framework

Use these category phrases:

- audit library
- audit platform
- audit infrastructure
- audit trail for Phoenix, Ecto, and PostgreSQL
- action-and-change history
- explainable audit timeline
- context-rich audit system

Avoid these frames:

- just a log viewer
- just a Carbonite UI
- SIEM
- event sourcing
- immutable ledger
- compliance suite
- generic observability

Core differentiators:

- Capture plus meaning: row changes linked to actions, actors, reasons, requests, jobs, and transactions.
- Explainable by default: humans can answer "what happened?" quickly.
- Operationally credible: health checks, coverage, retention, redaction, exports, and evidence.
- Native to Phoenix/Ecto/Postgres: built for the stack rather than adapted to it.
- Inspectable and composable: SQL-friendly, explicit, and host-owned where it should be.

## Voice

Threadline speaks like a calm senior engineer with strong product taste.

Prefer:

- precise over clever
- plainspoken over buzzwordy
- confident over swaggering
- thoughtful over promotional
- calm over urgent
- technical over salesy

Writing rules:

- Say what it does plainly.
- Use active voice.
- Keep sentences short.
- Make boundaries explicit.
- Distinguish actions from changes, requests from transactions, and audit history from database activity auditing.
- Do not use exclamation marks in product copy.
- Do not hide technical value behind vague words like "powerful", "seamless", "next-generation", or "robust".

Say this:

> Capture changes, connect them to context, and follow the full history.

Not this:

> Revolutionary audit intelligence for modern teams.

Say this:

> Understand the change, who initiated it, and why.

Not this:

> Enterprise-grade observability for governance workflows.

## Visual Principles

Visual center:

> A line that connects discrete points into an intelligible path.

Use:

- continuous lines
- route-like paths
- layered timelines
- restrained contour linework
- signal traces crossing system boundaries
- small points that represent actions, actors, transactions, changes, and evidence

Avoid:

- shields
- padlocks
- database cylinders as the primary logo
- checkmarks as compliance proof
- chain links
- fingerprints
- neon cyber grids
- abstract node clouds
- faceless stock office imagery

## Logo System

The identity is one drawing. The word "threadline" is set in Geist 600 and converted to pure vector paths; the adjacent `d` and `l` ascenders are cut at a shared fabric line, and a single stitch of thread — one arc whose stroke width equals the measured stem width — rises out of one stem and dives back into the other. One line connecting discrete points into an intelligible path. The stitch alone is the extractable mark and the favicon.

Every asset is pure paths: zero live text, zero font dependencies. The mark renders identically on GitHub, HexDocs, and anywhere else SVG renders.

Family roster and surface assignments:

- `logo-primary.svg`: the primary lockup for dark surfaces. Fog `#D7DEEA` glyphs, Stitch Blue `#4781E6` arc. Product, slides, social.
- `logo-primary-light.svg`: the designed light rendition — Ink `#0F1728` glyphs from the light token lane, not a recolor of the dark asset; Stitch Blue arc. README, GitHub, HexDocs, light docs.
- `logo-wordmark.svg`: the wordmark alone with intact ascenders and no arc; currentColor for inline adaptive use. Running text and constrained headers.
- `logo-monochrome.svg`: the one-color master — exactly one paint value (currentColor), arc included. Print, engraving, single-color surfaces.
- `logo-mark.svg`: the extractable stitch at a 64px canvas — blue arc, currentColor stems and fabric; the fabric line paints last so the thread disappears behind it at the crossings. Avatars, docs sidebars, small UI.
- `favicon.svg`: designed at a 16px canvas — one stitch through the fabric line, two strokes, no container chip. An internal `prefers-color-scheme` style flips its ink between Ink and Fog with the browser chrome. Browser tabs.
- `logo-primary-subtitle.svg`: the only lockup carrying the tagline, as outlined IBM Plex Mono 500 caps justified to the wordmark's ink edges. Large deliberate surfaces only.
- `social-card.svg`: the 1280x640 link preview. Its dark canvas is the single sanctioned full-bleed background in the family.

In prose the tagline is sentence case — "Follow what happened." The capitalized rendition exists only inside `logo-primary-subtitle.svg` and `social-card.svg`.

Do not add a mascot. Do not create a complex abstract symbol. The stitch is the mark.

Clearspace:

- Lockups: keep clear space equal to half the wordmark's cap height on every side — 31% of the rendered height for the primary (a 32px-tall render keeps 10px clear).
- Mark and favicon: keep one quarter of the rendered size clear on every side (a 16px favicon context keeps 4px clear).
- Do not place the mark directly inside dense copy or against busy imagery.

Minimum sizes (wordmark legibility governs; the arc stroke renders at 11% of the lockup height and survives far smaller):

- `logo-primary.svg`, `logo-primary-light.svg`, `logo-monochrome.svg`, `logo-wordmark.svg`: 120px wide on screen (≈26px tall). Below 120px, switch to the mark.
- `logo-primary-subtitle.svg`: 180px wide (≈48px tall), where the tagline caps hold ≈7px. Below that, use the primary.
- `logo-mark.svg`: 16px square minimum; prefer 24px or larger.
- `favicon.svg`: designed at 16px and never rendered smaller.

Small-size thresholds (testable numbers for the favicon, the mark, and any future small cut):

- Stroke weight at a 16px canvas: at least 1.5px target; 1.0px absolute floor.
- Gaps and counters: at least 1.0px at 16px; at least 1.5px around modifier elements.
- At most 4 distinct strokes or elements at 16px; the silhouette must identify first.
- Design at 16px; never shrink larger art down. `favicon.svg` is the 16px artifact.

Dark/light strategy:

- Every light-surface rendition is designed, never recolored from dark.
- The stitch arc keeps Stitch Blue `#4781E6` on both surfaces: 5.0:1 against Threadline Black, 3.78:1 on white — above the 3:1 graphics floor.
- On GitHub, serve both primaries with the `<picture>` element so each reader gets the asset designed for their theme:

```html
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="brandbook/logo-primary.svg">
  <img alt="Threadline" src="brandbook/logo-primary-light.svg" width="420">
</picture>
```

Usage:

- Use `logo-primary.svg` on dark landing pages, slides, and social previews.
- Use `logo-primary-light.svg` on README, GitHub, HexDocs, and light documentation surfaces.
- Use the mark for favicon, avatar, docs sidebar, and small UI contexts.
- Use monochrome for stickers, print, and single-color contexts.

Misuse (each of these is rendered as a visual "don't" in `index.html`):

- Do not place the mark inside a container chip, plate, or badge. The stitch sits directly on the surface; the fabric line is its own ground.
- Do not set the mark beside the name in plain type. The wordmark and stitch are one drawing — use `logo-primary.svg`.
- Do not attach the tagline to the primary, and do not run the subtitle lockup below 180px wide. The tagline lives in `logo-primary-subtitle.svg` alone.
- Do not make the mark depend on gradients or glows. It must survive flat one-color reproduction; `logo-monochrome.svg` is the proof.
- Do not stretch, squash, or rotate. The lockup aspect is fixed at 4.56:1.
- Do not recolor. Glyphs are Fog on dark or Ink on light; the arc is Stitch Blue `#4781E6` — or the entire mark is one color via the monochrome master.
- Do not rotate the mark, replace the line with a chain, rope, or cable, or put the mark inside a shield.
- Do not use gradients as soft blobs behind the logo.

### UI theming posture

The operator surface is dark-primary: Threadline Black is the canonical brand background and the shipped default. Light mode is fully shipped and supported as of v1.36 — it is enabled via host configuration (`theme: :system | :light | :dark`) with no extra packages, no JavaScript, and no flash of unstyled content. The `:system` value follows the operator's OS color-scheme preference via scoped CSS.

Per-operator runtime theme toggling is deferred to real adopter demand (`THEME-TOGGLE-01`); localStorage remains permanently rejected (FOUC on dead render, CSP-incompatible). The documented upgrade path to cookie-based toggling stands if demand emerges.

State this only because it is true now: the v1.33 lesson held that dark-primary was settled truth while light-supported claims waited until light actually shipped. With v1.36 it has shipped, so this posture is now settled, not aspirational.

## Color System

Color philosophy:

> Night infrastructure with luminous signal lines.

Core dark colors:

- Threadline Black `#0B1020`: primary dark background.
- Graphite `#141B2D`: dark surface.
- Slate Line `#23304A`: borders, dividers, rails.
- Fog `#D7DEEA`: primary text on dark.

Core light colors:

- Paper `#F7F9FC`: docs, diagrams, print-like backgrounds.
- Mist `#E7ECF4`: light fills and subtle bands.
- Ink `#0F1728`: primary text on light.

Signature accents:

- Thread Blue `#4F8CFF`: primary links, active states, primary CTA, selected path.
- Stitch Blue `#4781E6`: the logo arc's ink on every surface, dark and light. Tokens: `--tl-color-stitch-blue` (raw) and `--tl-color-logo-arc` (semantic, both lanes).
- Signal Cyan `#4EDFD1`: correlation, live trace, connected flow, positive movement.
- Iris `#8A7CFF`: sparing depth accent, charts, premium moments.
- Ember `#FF8A5B`: warm contrast for emphasis and diff attention, not default warning text.

Two blues, two jobs: Stitch Blue belongs to the mark and Thread Blue belongs to the interface. The stitch arc is `#4781E6` everywhere the logo appears (5.0:1 against Threadline Black, 3.78:1 on white — above the 3:1 graphics floor), while `#4F8CFF` carries links, focus, and selection in product UI. The operator-surface token values are unchanged; the stitch blue is an additive token. Neither blue substitutes for the other, in either direction.

Semantic colors:

- Success: `#3FD08F`, with dark-surface text `#5AE0A2`.
- Info: Thread Blue, with dark-surface text `#9AB9FF`.
- Warning: `#F3B94C`, with dark-surface text `#F6C86B`.
- Error: `#F06A6A`, with dark-surface text `#FF8585`.

Rules:

- Use dark neutrals for product UI and high-signal marketing moments.
- Use light surfaces for docs, diagrams, reference content, and print-like material.
- Use color as signal, not decoration.
- Do not rely on color alone for operation type, severity, or state.
- Use gradients only as thin line treatments. Never use large gradient blobs.

## Typography

Primary sans:

- Geist.
- Fallback: Inter, system-ui, sans-serif.

Monospace:

- IBM Plex Mono.
- Fallback: JetBrains Mono, ui-monospace, SFMono-Regular, Menlo, monospace.

License assumption:

- The repo already includes Geist and IBM Plex Mono under SIL OFL 1.1 in `priv/fonts/`.
- Do not embed new proprietary fonts.
- Do not commit duplicate font binaries into this brandbook.

Type roles:

- Hero and display: Geist Medium or Semibold.
- Section headings: Geist Semibold.
- Body: Geist Regular.
- UI labels: Geist Medium or IBM Plex Mono when the label is metadata.
- Code, IDs, table names, request IDs, and diffs: IBM Plex Mono.

Rules:

- Keep letter spacing at `0` for normal text.
- Uppercase metadata labels may use `0.12em` tracking.
- Do not use mono for long prose.
- Do not add an editorial serif until a real marketing page needs it.

## Layout And Components

Layout principles:

- Strong grid.
- Calm spacing.
- Dense where useful, never cluttered.
- Clear hierarchy between action, context, raw changes, and evidence.
- Thin dividers and rails.
- Rounded corners capped at 8px for most UI components.

Component guidance:

- Buttons: 6px radius, clear primary/secondary/disabled states.
- Cards: use only for individual repeated items, not page sections inside cards.
- Alerts: include icon or label plus text; never color alone.
- Code blocks: dark by default for marketing and README snippets; light is acceptable in docs pages.
- Badges: short, semantic, and mono only when representing machine-readable state.
- Tabs: use for view switching, not navigation hierarchy.
- Tables: prioritize dense but readable rows, stable alignment, and clear overflow behavior.

Expected component examples:

- buttons
- cards
- callouts
- badges
- code blocks
- terminal snippets
- docs sidebar
- feature grid
- comparison table
- install snippet
- architecture diagram
- empty, error, warning, success states

## Imagery And Diagrams

Best imagery:

- line maps
- timelines with depth
- contour or cross-section linework
- architecture flows
- macro linework inspired by stitching or signal traces

Diagram style:

- Use lines, points, labels, and layered rails.
- Use domain nouns: request, action, transaction, change, evidence, export.
- Keep arrows sparse.
- Prefer actual flow over decorative complexity.

Do not use:

- stock people
- courtroom imagery
- locks
- shields
- police tape
- random server racks
- unlabelled node graphs

## UX Microcopy

Error messages:

- State what failed.
- State why if known.
- State the next action.
- Avoid blame.

Example:

> Could not verify trigger coverage for `ticket_replies`. Threadline could not introspect the deployed trigger SQL. Rerun `mix threadline.gen.triggers --tables ticket_replies`, migrate, then check coverage again.

Empty states:

> No audit changes match these filters. Clear the table filter or widen the time range.

Success states:

> Export queued. Threadline will keep the filtered timeline and evidence bundle together.

Warning states:

> Redaction drift detected. The configured redaction policy does not match the deployed trigger. Regenerate triggers, then rely on this field.

Release notes:

- Lead with the adopter-visible change.
- Name public APIs and migration steps.
- Separate support claims from implementation details.
- Do not oversell.

## Ready-To-Use Copy

One-line description:

> Audit history for Phoenix, Ecto, and PostgreSQL.

140-character description:

> Threadline captures database changes, connects them to actions and context, and turns audit history into readable timelines.

GitHub repo description:

> Open-source audit history for Phoenix, Ecto, and PostgreSQL.

Hex.pm package description:

> Trigger-backed audit capture, semantic actions, timelines, exports, and operator workflows for Phoenix/Ecto applications.

README opening:

> Threadline is an open-source audit library for Elixir teams using Phoenix, Ecto, and PostgreSQL. It captures row-level changes, connects them to actors, actions, and request context, and makes the resulting history readable through timelines, diffs, exports, and operator tooling.

Landing page headline:

> Follow what happened.

Landing page subheadline:

> Capture database changes, connect them to actors and request context, and explore the full audit timeline inside your Phoenix app.

Primary CTA:

> Read the docs

Secondary CTA:

> View on GitHub

Feature blurbs:

- Capture: PostgreSQL triggers record row-level changes where writes actually happen.
- Semantics: Actions connect low-level changes to actor, intent, request, job, and transaction context.
- Operations: Coverage checks, redaction posture, retention, exports, and evidence make the audit layer maintainable.

Why this exists:

- Raw row changes are not enough when a team needs to explain an incident.
- Audit history should be inspectable without becoming a black box.
- Phoenix teams should not need a separate event system just to follow changes.

## Landing Page Blueprint

Use this order:

1. Hero: "Follow what happened." Short stack-specific subhead and install/docs CTA.
2. Problem: teams have logs and row changes, but not a followable history.
3. Solution: capture plus semantic context plus operator exploration.
4. Install snippet: dependency, config, install, migrate.
5. Minimal example: `Threadline.Audit.transaction/3`, timeline query, export.
6. Core benefits: capture, semantics, exploration, operations.
7. How it works: request/action/transaction/change/evidence flow.
8. Use cases: support investigation, incident review, compliance support, redaction verification, exports.
9. Why not just: logs, event sourcing, SIEM, database auditing.
10. Documentation CTA, GitHub CTA, contribution CTA.
11. Footer: Hex.pm, HexDocs, GitHub, license.

## README And Docs Blueprint

Use this order:

1. Opening promise.
2. Installation.
3. Quickstart.
4. Minimal example.
5. Concepts: capture, semantics, exploration, operations.
6. API overview.
7. Operator surface.
8. Common recipes.
9. Troubleshooting.
10. Design rationale and non-goals.
11. Contribution.
12. License.

## Repo Artifact Rules

Commit:

- Markdown brand guide and audit.
- Token JSON and CSS.
- Editable SVG logos and examples.
- Static HTML brandbook.

Generate only on demand:

- PNG social card exports.
- PDF snapshots.
- Raster screenshots for launch posts.

Do not commit:

- Duplicate font binaries.
- Figma exports as the only source of truth.
- Large PNG/JPEG moodboards.
- Decorative generated images with no implementation value.

Manual review required:

- Trademark-sensitive logo changes.
- Claims about compliance readiness.
- New imagery sources.
- Public launch copy.

## Final Quality Gate

Before using the brand system publicly:

- Can a designer build from this?
- Can an engineer implement from this?
- Can a maintainer keep it consistent?
- Can a contributor understand it?
- Can it support marketing without becoming cheesy?
- Can it survive dark mode, light docs pages, small icons, and social previews?
- Does it feel specific to Threadline?
- Does it resist unnecessary redesign pressure?
