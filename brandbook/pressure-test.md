# Threadline Brand QA Guide

## Section 1 - Executive Judgment

The Threadline brand system is ready for source-controlled use across static brand artifacts, documentation concepts, README/GitHub visuals, and future marketing surfaces.

Its center is clear:

> Threadline makes system history followable.

That idea is specific to audit history and strong enough to guide product UI, documentation, landing pages, diagrams, and logo work.

The brand stays distinct when the line, history, and evidence metaphor remains disciplined. It becomes generic when it drifts into abstract node graphs, blue-purple glow, shield or lock security tropes, or vague "trust platform" copy.

Highest-leverage rule:

> Treat the brand as committed, inspectable source artifacts: tokens, SVG logo files, static examples, microcopy, and usage rules.

Protect:

- "Follow what happened."
- "Threadline makes system history followable."
- The connected-line metaphor.
- The calm, exact, low-BS voice.
- The dark infrastructure palette as the operator and product foundation.

## Section 2 - Brand DNA

Brand essence:

> Connected audit history.

Audience:

- Phoenix/Ecto backend engineers.
- Platform and SRE teams.
- Security and compliance engineers.
- Support and operations teams.
- OSS maintainers and contributors.

Emotional tone:

- calm
- precise
- grounded
- serious without intimidation

Technical promise:

> Threadline connects database changes to actor, action, request, transaction, and evidence context so teams can follow what happened.

Visual metaphor:

> A continuous line connecting discrete events into an intelligible path.

Personality traits:

- lucid
- composed
- technical
- evidence-oriented
- quietly confident

Anti-traits:

- flashy
- cute
- militaristic
- cyberpunk
- compliance-bureaucratic
- generic SaaS

This should feel like:

- a clear line through an incident
- an audit system built by people who operate software
- a practical BEAM/Phoenix tool

This should never feel like:

- a generic security vendor
- a compliance dashboard template
- a neon cyber product
- a mascot-led OSS brand

## Section 3 - Brand Readiness Scorecard

| Dimension | Score | Current strength | Risk | Governance rule |
|---|---:|---|---|---|
| Distinctiveness | 8 | The connected-history metaphor is strong and relevant. | Can collapse into generic node or line visuals. | Keep the evidence path metaphor explicit and labeled. |
| Developer credibility | 9 | Voice is plain, precise, and grounded in real APIs and workflows. | Marketing copy can overreach into compliance claims. | Keep claims tied to capture, context, health, exports, and evidence. |
| Elixir ecosystem fit | 9 | Phoenix/Ecto/Postgres positioning is clear and understated. | Looking too SaaS-like reduces OSS trust. | Prioritize README, HexDocs, examples, and code snippets over splashy collateral. |
| Visual coherence | 8 | Palette, type, and line motif align around audit history. | Repetition of lines can become decoration. | Use lines to show sequence, causality, or evidence flow. |
| Logo readiness | 7 | The line mark and wordmark are simple and usable as source assets. | The mark may benefit from human refinement for high-stakes launch work. | Use the committed source assets; review trademark and favicon legibility manually. |
| Color-system readiness | 8 | Dark product palette and light documentation roles are defined. | Static brand tokens can drift from runtime operator tokens. | Treat operator CSS as product contract and brandbook tokens as collateral/docs contract. |
| Typography readiness | 8 | Geist and IBM Plex Mono are practical and already licensed in-repo. | Optional serif styling would add unnecessary complexity. | Use sans plus mono until an actual editorial surface requires more. |
| Design-token readiness | 8 | JSON and CSS define raw and semantic roles. | Duplicate token definitions can diverge. | Keep this folder as static brand guidance, not automatic runtime coupling. |
| UI component readiness | 7 | Button, callout, code, card, badge, and terminal guidance exists. | This is not a full component library. | Add component guidance only when a real docs or marketing build requires it. |
| Docs/README usefulness | 8 | Copy blocks and README blueprint are concrete. | Public docs can become over-branded. | Use brand through clarity, logo fit, typography, and code readability. |
| Marketing usefulness | 8 | Landing architecture, hero copy, feature blurbs, and social card are ready. | Overuse of dark hero surfaces can feel heavy. | Pair dark hero moments with light docs and evidence sections. |
| Voice/microcopy usefulness | 8 | Examples cover errors, empty states, warnings, releases, and CTAs. | New CLI surfaces may require additional examples. | Add examples as public surfaces ship. |
| Accessibility | 7 | Token choices favor contrast and non-color-only states. | Each final surface still needs inspection. | Keep labels, text alternatives, focus rings, and contrast checks in QA. |
| Repo/source-control readiness | 9 | Artifacts are HTML, Markdown, JSON, CSS, and SVG only. | Future generated PNGs can bloat history. | Commit generated raster only for specific downstream needs. |
| Long-term maintainability | 8 | Folder boundaries and artifact rules are clear. | Brand and product tokens can blur. | Document source of truth and keep token lanes explicit. |

## Section 4 - Surface Stress Tests

GitHub repo header:

- Use the primary logo or simple README text header.
- Keep the short description stack-specific and technical.
- Standard badges are acceptable.

README hero section:

- Keep lightweight.
- Use copy from `brand-book.md`.
- Avoid a large raster hero.

README badges:

- Use standard badges.
- Do not custom-style every badge unless it creates real value.

Hex.pm package page:

- Use a short package description.
- Keep marketing language restrained.

HexDocs page:

- Favor docs-specific light mode and readable code blocks.
- Avoid dark marketing splash sections inside API docs.

Docs sidebar:

- Use the mark or wordmark.
- Keep active state restrained and high contrast.

Code block styling:

- Use dark snippets for marketing and README examples.
- Light code blocks are acceptable for documentation pages.

Terminal snippet:

- Use realistic commands.
- Keep snippets copyable.
- Avoid fake terminal drama.

API reference page:

- Prioritize standard ExDoc behavior.
- Brand only through tokens, logo fit, and code readability.

Landing page hero:

- Use the line path metaphor as the main visual.
- Avoid carded dashboard mockups as the hero center.

Feature section:

- Group by capture, semantics, exploration, and operations.

Comparison section:

- Compare against logs, event sourcing, SIEM, database auditing, and roll-your-own with precise caveats.

Blog post header:

- Use social card linework and a short headline.

Release announcement:

- Lead with adopter-visible changes and migration steps.

Social preview card:

- Keep SVG as source.
- Export PNG only when a platform requires it.

Favicon:

- Test at 16px and 32px.

App icon:

- Use the favicon mark in a larger dark rounded square.

Small monochrome logo:

- Use `logo-monochrome.svg`.

Dark-mode page:

- Best for product, hero, and admin surfaces.

Light-mode page:

- Best for docs, diagrams, reference, and print-like pages.

Conference slide:

- Use one big line path, one claim, and one code snippet.

Diagram or architecture illustration:

- Label domain nouns.
- Avoid decorative complexity.

Error, empty, and success states:

- Use actionable copy.
- Include non-color indicators.

Example UI component library:

- Current scope is primitives, not a full library.

Mobile landing page:

- Collapse line artwork without occluding text.

Printed sticker or small swag:

- Use monochrome mark or primary logo only.
- Keep this lower priority than README, docs, and launch-critical assets.

## Section 5 - Current Risks

Critical:

- Logo changes require human review for trademark sensitivity and small-size legibility.
- Static brand tokens and runtime operator tokens must stay in clear lanes.
- Light documentation surfaces must preserve contrast and code readability.

Important:

- README and marketing copy should remain technical and stack-specific.
- UI examples are primitives, not a complete component library.
- Accessibility checks belong to each final surface, not only this folder.
- Repo artifact rules should prevent binary sprawl.

Nice-to-have:

- Human refinement of the wordmark.
- Optional PNG exports for social platforms.
- A future ExDoc theme pass.
- A future README rollout using the sharper copy.

## Section 6 - Brand Governance Rules

Keep:

- Core idea, tagline, stack-specific positioning, palette, type choices, and voice.

Tighten only with a concrete surface:

- Logo spacing or small-size legibility.
- Color guidance when a real surface exposes a missing semantic role.
- Voice guidance when a new public surface requires examples.
- Diagram guidance when a real architecture graphic creates ambiguity.

Avoid:

- Broad "audit platform" wording that implies a full compliance product.
- Gradient use that becomes decorative ambience rather than signal linework.
- Mascots, shields, locks, chains, and stock-photo direction.
- Redundant inspiration prose that does not guide implementation.

Add only with a concrete downstream use:

- New token roles.
- Additional SVG assets.
- More microcopy examples.
- More component states.
- New export formats.

## Section 7 - Design Token Specification

Committed outputs:

- `tokens.json`: structured raw and semantic tokens.
- `tokens.css`: CSS custom properties for direct use in static pages.

Token groups:

- raw palette
- dark semantic colors
- light semantic colors
- typography
- spacing
- radius
- borders
- shadows
- focus rings
- code blocks
- callouts
- states

Defaults:

- Dark is default for product UI and high-signal marketing surfaces.
- Light is default for docs, diagrams, print, and long-form reading.
- Focus rings must remain visible on both dark and light.
- Disabled state must reduce emphasis but preserve label readability.

## Section 8 - Logo And Mark System

Use:

- Horizontal wordmark plus icon mark.
- Icon-only mark for favicon, social avatar, docs nav, and small UI.
- Monochrome mark for print and constrained contexts.
- Primary dark logo on dark landing pages, slides, and social previews.
- Primary light logo on README, GitHub, HexDocs, and light documentation surfaces.

Do not use:

- A mascot.
- A complex abstract symbol.
- Shields, locks, chains, or database cylinders as the mark.
- Rotation, distortion, or glow that breaks monochrome recognition.

Expected assets:

- `logo-primary.svg`
- `logo-primary-light.svg`
- `logo-mark.svg`
- `logo-monochrome.svg`
- `favicon.svg`
- `social-card.svg`

Usage rules:

- Keep clearspace around the mark.
- Do not rotate or distort.
- Do not rely on gradient for meaning.
- Keep the mark recognizable in monochrome.

## Section 9 - Visual Examples And Screenshot Guidance

Use examples that help implementation:

| Example | Purpose | Path | Export |
|---|---|---|---|
| Palette | Token inspection | `examples/palette.svg` | SVG source; PNG only for docs site if required |
| Typography | Type roles | `examples/typography.svg` | SVG |
| Components | Primitive UI states | `examples/components.svg` | SVG |
| README header | README visual direction | `examples/readme-header.svg` | SVG |
| Landing hero | Marketing hero direction | `examples/landing-hero.svg` | SVG |
| Docs page | Docs layout direction | `examples/docs-page.svg` | SVG |
| Terminal | Command screenshot style | `examples/terminal.svg` | SVG |

Do not create fake product screenshots unless they represent real Threadline behavior.

## Section 10 - Brand Voice And Microcopy

Voice principles:

- calm
- exact
- technical
- useful
- low ego

Vocabulary to use:

- action
- change
- transaction
- context
- actor
- subject
- correlation
- timeline
- diff
- snapshot
- coverage
- retention
- redaction
- export
- evidence

Vocabulary to avoid unless technically necessary:

- provenance
- governance
- event fabric
- chain of custody
- immutable ledger
- cyber defense
- forensic-grade
- next-generation
- seamless

Examples are maintained in `brand-book.md`.

## Section 11 - Landing Page And Docs Blueprint

Landing page:

- Hero
- Problem
- Solution
- Install snippet
- Minimal example
- Core benefits
- How it works
- Use cases
- Comparison
- Documentation CTA
- GitHub CTA
- Contribution CTA
- Footer

README/docs:

- Opening promise
- Installation
- Quickstart
- Example
- Concepts
- API overview
- Recipes
- Troubleshooting
- Design rationale
- Contribution
- License

## Section 12 - Repo-Ready Artifact Rules

Commit:

- HTML, Markdown, JSON, CSS, SVG.

Generate only on demand:

- PNG social-card export.
- PDF snapshot.
- Raster screenshots for launch posts.

Do not commit:

- duplicated fonts
- large binary moodboards
- generated image batches
- vendor-locked design files as the only source

Suggested checks:

- JSON parse check for `tokens.json`.
- XML parse check for SVG and HTML.
- File size check for `brandbook/`.
- Optional contrast script if this becomes a CI surface.

## Section 13 - Prioritized Action Plan

Do now:

- Keep `brandbook/` source artifacts committed and inspectable.
- Review favicon at 16px and 32px.
- Use `logo-primary-light.svg` for README, GitHub, and light documentation contexts.
- Use `logo-primary.svg` on dark and high-signal surfaces.
- Use `brand-book.md` for future README and landing-page copy.

Do next:

- Apply the sharper README intro in a separate docs pass.
- Export social-card PNG only when a platform requires it.
- Consider an ExDoc theme pass after docs information architecture is stable.

Defer:

- Human wordmark refinement.
- Serif editorial accent.
- Printed swag.
- Full component library.

Do not do:

- Add a mascot.
- Add shield or lock security imagery.
- Commit large raster moodboards.
- Rebuild the operator UI solely for brand maintenance.
- Make compliance claims without human or legal review.

## Section 14 - Final Quality Gate

Could a designer build from this?

- Yes. Concept, tokens, examples, layout rules, and logo usage are concrete.

Could an engineer implement from this?

- Yes. Tokens are JSON/CSS and assets are SVG.

Could a maintainer keep it consistent?

- Yes, if runtime operator tokens and brandbook tokens stay in their lanes.

Could a contributor understand it?

- Yes. The folder has a README, source docs, and no hidden design-tool dependency.

Could it support marketing without becoming cheesy?

- Yes, as long as the brand keeps technical proof ahead of vibe.

Could it survive dark mode, small sizes, docs pages, and social previews?

- Mostly yes. Favicon and mark still require manual small-size review.

Does it feel specific to Threadline?

- Yes. The connected audit-history idea belongs to this library.

Does it resist unnecessary redesign pressure?

- Yes. The system has a clear center, source artifacts, and practical governance rules.
