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

- Calm under pressure.
- Exact without being cold.
- Useful before impressive.
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

> Understand what changed, who initiated it, and why.

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

Recommended system:

- Primary dark: horizontal wordmark with a continuous-line mark for dark infrastructure surfaces.
- Primary light: horizontal wordmark with a continuous-line mark for README, GitHub, HexDocs, and light documentation surfaces.
- Secondary: icon-only line mark.
- Monochrome: one-color version for small print, engraving, and constrained surfaces.
- Favicon: compact mark inside a dark rounded square.

Do not add a mascot. Do not create a complex abstract symbol. The concept is strong enough as a line-based mark.

Minimum size:

- Primary logo: 160px wide on screen.
- Mark: 24px square on screen.
- Favicon: 16px square minimum, but prefer 32px or larger.

Clearspace:

- Keep at least one mark diameter around the logo.
- Do not place the mark directly inside dense copy or against busy imagery.

Usage:

- Use `logo-primary.svg` on dark landing pages, slides, and social previews.
- Use `logo-primary-light.svg` on README, GitHub, HexDocs, and light documentation surfaces.
- Use the mark for favicon, avatar, docs sidebar, and small UI contexts.
- Use monochrome for stickers, print, and single-color contexts.

Misuse:

- Do not rotate the mark.
- Do not replace the line with a chain, rope, or cable.
- Do not put the mark inside a shield.
- Do not add glow unless the surface already uses the dark signal-line system.
- Do not use gradients as soft blobs behind the logo.

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
- Signal Cyan `#4EDFD1`: correlation, live trace, connected flow, positive movement.
- Iris `#8A7CFF`: sparing depth accent, charts, premium moments.
- Ember `#FF8A5B`: warm contrast for emphasis and diff attention, not default warning text.

Semantic colors:

- Success: `#3FD08F`, with dark-surface text `#5AE0A2`.
- Info: Thread Blue, with dark-surface text `#9AB9FF`.
- Warning: `#F3B94C`, with dark-surface text `#FFD166`.
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
- Dense where needed, never cluttered.
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

> Redaction drift detected. The configured redaction policy does not match the deployed trigger. Regenerate triggers before relying on this field.

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

Generate only when needed:

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
- Does it avoid unnecessary brand churn?
