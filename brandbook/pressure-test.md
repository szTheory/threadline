# Threadline Brand Book Pressure Test

## Section 1 - Executive Judgment

The current brand book is strategically strong and execution-incomplete.

It has a clear center: Threadline makes system history followable. That idea is specific to audit history and strong enough to guide product UI, documentation, landing pages, diagrams, and logo work.

It is distinct enough if the team keeps the line/history/evidence metaphor disciplined. It will become generic if it drifts into abstract node graphs, blue-purple glow, shield/lock security tropes, or vague "trust platform" copy.

It was under-specified for implementation. The original book had strong positioning, voice, color direction, and typography direction, but lacked semantic tokens, component guidance, logo artifacts, light-surface rules, concrete copy blocks, and repo artifact boundaries.

Highest-leverage improvement:

> Convert the brand from inspirational prose into committed, inspectable source artifacts: tokens, SVG logo files, static examples, microcopy, and usage rules.

Do not change:

- "Follow what happened."
- "Threadline makes system history followable."
- The connected-line metaphor.
- The calm, exact, low-BS voice.
- The dark infrastructure palette as the operator/product foundation.

## Section 2 - Brand DNA Extraction

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

Design principles:

- Use lines as structure, not decoration.
- Show sequence and causality.
- Keep UI dense but legible.
- Use accents as state and signal.
- Prefer inspectable vectors over raster mood.

Voice principles:

- Say what it does.
- Name boundaries.
- Prefer concrete technical nouns.
- Avoid hype adjectives.
- Make error and warning states actionable.

This should feel like:

- a clear line through an incident
- an audit system built by people who operate software
- a practical BEAM/Phoenix tool

This should never feel like:

- a generic security vendor
- a compliance dashboard template
- a neon cyber product
- a mascot-led OSS brand

## Section 3 - Pressure-Test Scorecard

| Dimension | Score | Why | Risk | Recommended fix |
|---|---:|---|---|---|
| Distinctiveness | 8 | The connected-history metaphor is strong and relevant. | Can collapse into generic node/line visuals. | Keep the evidence path metaphor explicit and labeled. |
| Developer credibility | 9 | Voice is plain, precise, and grounded in real APIs and workflows. | Marketing copy could overreach into compliance claims. | Keep claims tied to capture, context, health, exports, and evidence. |
| Elixir ecosystem fit | 9 | Phoenix/Ecto/Postgres positioning is clear and understated. | Looking too SaaS-like would reduce OSS trust. | Prioritize README, HexDocs, examples, and code snippets over splashy collateral. |
| Visual coherence | 7 | Palette, type, and line motif align well. | Original book lacked concrete execution examples. | Use SVG examples and token files as constraints. |
| Logo readiness | 7 | Direction is good: line mark plus wordmark. | The mark is intentionally simple and may need human refinement before high-stakes public launch. | Use v1 source assets; review trademark and favicon legibility manually. |
| Color-system readiness | 8 | Dark product palette is strong and already reflected in operator UI. | Light docs/marketing states were incomplete. | Use light semantic tokens for docs and print-like surfaces. |
| Typography readiness | 8 | Geist and IBM Plex Mono are practical and already licensed in-repo. | Optional serif would create churn. | Defer serif until an actual editorial surface needs it. |
| Design-token readiness | 8 | JSON and CSS define raw and semantic roles. | Runtime operator tokens may drift from static brand tokens. | Treat operator CSS as product contract and brandbook tokens as collateral/docs contract. |
| UI component readiness | 7 | Button, callout, code, card, badge, terminal guidance exists. | Not a full component library. | Add only when a real docs/marketing build needs more. |
| Docs/README usefulness | 8 | Copy blocks and README blueprint are concrete. | README should not change in this milestone. | Use copy selectively in a later docs rollout. |
| Marketing usefulness | 8 | Landing architecture, hero copy, feature blurbs, and social card are ready. | Overuse of dark hero could feel heavy. | Pair dark hero with light docs and evidence sections. |
| Voice/microcopy usefulness | 8 | Examples cover errors, empty states, warnings, releases, and CTAs. | More CLI examples may be needed later. | Add examples only as new CLI surfaces ship. |
| Accessibility | 7 | Token choices favor high contrast and non-color-only states. | SVG and HTML still need visual inspection per surface. | Keep labels, text alternatives, focus rings, and contrast checks in QA. |
| Repo/source-control readiness | 9 | Artifacts are HTML/Markdown/JSON/CSS/SVG only. | Future generated PNGs could bloat history. | Commit generated raster only for specific downstream needs. |
| Long-term maintainability | 8 | Folder boundaries and artifact rules are clear. | Duplicate tokens could drift. | Document source of truth and avoid automatic runtime coupling. |

## Section 4 - Stress Tests

GitHub repo header:

- Enough guidance: yes.
- Needs: use primary logo or simple README text header, short description, badges, and direct technical promise.

README hero section:

- Enough guidance: yes.
- Needs: keep lightweight. Avoid large raster hero. Use copy from `brand-book.md`.

README badges:

- Enough guidance: yes.
- Needs: standard badges are acceptable. Do not custom-style every badge unless there is real value.

Hex.pm package page:

- Enough guidance: mostly.
- Needs: short package description and no marketing excess.

HexDocs page:

- Enough guidance: mostly.
- Needs: docs-specific light mode and code block styles; avoid dark marketing splash inside API docs.

Docs sidebar:

- Enough guidance: yes.
- Needs: mark/wordmark, restrained active state, high contrast.

Code block styling:

- Enough guidance: yes.
- Needs: dark default for marketing, light acceptable for docs.

Terminal snippet:

- Enough guidance: yes.
- Needs: copyable, realistic commands, no fake terminal drama.

API reference page:

- Enough guidance: partial.
- Needs: prioritize standard ExDoc behavior; brand only through tokens, logo, and code readability.

Landing page hero:

- Enough guidance: yes.
- Needs: use the line path metaphor as the main visual, not a carded dashboard mock.

Feature section:

- Enough guidance: yes.
- Needs: group by capture, semantics, exploration, operations.

Comparison section:

- Enough guidance: partial.
- Needs: compare against logs, event sourcing, SIEM, database auditing, and roll-your-own with precise caveats.

Blog post header:

- Enough guidance: yes.
- Needs: use social card linework and short headline.

Release announcement:

- Enough guidance: yes.
- Needs: lead with adopter-visible changes and migration steps.

Social preview card:

- Enough guidance: yes.
- Needs: export PNG only when required by the platform.

Favicon:

- Enough guidance: yes.
- Needs: test at 16px and 32px.

App icon:

- Enough guidance: yes.
- Needs: use favicon mark in larger dark rounded square.

Small monochrome logo:

- Enough guidance: yes.
- Needs: use `logo-monochrome.svg`.

Dark-mode page:

- Enough guidance: yes.
- Needs: product/hero/admin surfaces.

Light-mode page:

- Enough guidance: now yes.
- Needs: docs, diagrams, reference, print-like pages.

Conference slide:

- Enough guidance: yes.
- Needs: one big line path, one claim, one code snippet.

Diagram or architecture illustration:

- Enough guidance: yes.
- Needs: label domain nouns, avoid decorative complexity.

Error/empty/success states:

- Enough guidance: yes.
- Needs: actionable copy and non-color indicators.

Example UI component library:

- Enough guidance: partial.
- Needs: current scope is primitives, not a full library.

Mobile landing page:

- Enough guidance: yes.
- Needs: line artwork must collapse without occluding text.

Printed sticker or small swag:

- Enough guidance: optional.
- Needs: use monochrome mark or primary logo only. Do not make this a priority before docs/README/landing assets.

## Section 5 - Gaps And Risks

Critical:

- Logo had direction but no committed source assets.
- Original tokens were mostly raw colors, not complete semantic roles.
- Light docs/marketing surfaces were under-specified.

Important:

- Marketing and README copy needed ready-to-use blocks.
- UI components needed practical examples.
- Accessibility guidance needed specific state and contrast expectations.
- Repo artifact rules needed to prevent binary sprawl.

Nice-to-have:

- Human refinement of the wordmark.
- Optional PNG exports for social platforms.
- A future ExDoc theme pass.
- A future README refresh using the sharper copy.

## Section 6 - Recommended Brand Book Upgrades

Keep:

- Core idea, tagline, stack-specific positioning, palette, type choices, and voice.

Tighten:

- Logo direction into a wordmark/mark system.
- Color guidance into raw and semantic tokens.
- Voice guidance into surface-specific examples.
- Imagery guidance into diagram and screenshot rules.

Rework:

- Any broad "audit platform" wording that implies a full compliance product.
- Any gradient use that becomes decorative ambience rather than signal linework.

Add:

- Token files.
- SVG assets.
- HTML visual brandbook.
- Microcopy examples.
- Landing/docs blueprints.
- Repo artifact rules.
- QA checklist.

Remove:

- Redundant inspiration prose if it does not guide implementation.
- Any future mascot, shield, lock, or stock-photo direction.

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

Recommendation:

- Use a horizontal wordmark plus icon mark.
- Use icon-only for favicon, social avatar, docs nav, and small UI.
- Use monochrome for print and constrained contexts.
- Do not create a mascot.
- Do not use a complex abstract symbol.

Expected assets:

- `logo-primary.svg`
- `logo-mark.svg`
- `logo-monochrome.svg`
- `favicon.svg`
- `social-card.svg`

Usage rules:

- Keep clearspace around the mark.
- Do not rotate or distort.
- Do not add shields, locks, chains, or databases.
- Do not rely on gradient for meaning; the mark must remain recognizable in monochrome.

## Section 9 - Visual Examples And Screenshot Guidance

Create only examples that help implementation:

| Example | Purpose | Path | Export |
|---|---|---|---|
| Palette | Token inspection | `examples/palette.svg` | SVG source; PNG only for docs site if needed |
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

## Section 12 - Repo-Ready Artifact Plan

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

- Commit `brandbook/` source artifacts.
- Review favicon at 16px and 32px.
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
- Add shield/lock security imagery.
- Commit large raster moodboards.
- Rebuild the operator UI solely for brand churn.
- Make compliance claims without human/legal review.

## Section 14 - Final Quality Gate

Could a designer build from this?

- Yes, if the token and SVG artifacts pass Phase 147.

Could an engineer implement from this?

- Yes, if Phase 148 produces direct-open static HTML and source assets.

Could a maintainer keep it consistent?

- Yes, if runtime operator tokens and brandbook tokens stay in their lanes.

Could a contributor understand it?

- Yes, if the folder has README/source docs and no hidden design-tool dependency.

Could it support marketing without becoming cheesy?

- Yes, as long as the brand keeps technical proof ahead of vibe.

Could it survive dark mode, small sizes, docs pages, and social previews?

- Mostly yes. Favicon and mark need manual small-size review.

Does it feel specific to Threadline?

- Yes. The connected audit-history idea belongs to this library.

Does it avoid unnecessary brand thrash?

- Yes. It preserves the original strategy and adds implementation artifacts.
