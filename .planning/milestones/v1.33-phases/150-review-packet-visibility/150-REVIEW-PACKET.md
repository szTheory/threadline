# Phase 150 Review Packet: Brandbook Visibility

## Open These First

- HTML brandbook: `brandbook/index.html`
- Source brand guide: `brandbook/brand-book.md`
- Pressure test: `brandbook/pressure-test.md`
- Tokens: `brandbook/tokens.json`, `brandbook/tokens.css`

## Logo And Asset Inventory

| Asset | Role | Review note |
|---|---|---|
| `brandbook/logo-primary.svg` | Primary lockup for dark/high-signal surfaces | Good on dark surfaces; too pale on white backgrounds if used directly. |
| `brandbook/logo-primary-light.svg` | Primary lockup for README/GitHub/light docs | Added in Phase 150 after the focused preview exposed the light-background issue. |
| `brandbook/logo-mark.svg` | Icon-only line mark | Good conceptual fit; keep for compact docs/nav/avatar contexts. |
| `brandbook/logo-monochrome.svg` | One-color lockup | Works well in the README header specimen and constrained print/light contexts. |
| `brandbook/favicon.svg` | Favicon/app mark | Clear at large preview size; still worth human review at actual browser tab size. |
| `brandbook/social-card.svg` | Social preview source | Suitable as source SVG; export PNG only when a platform needs it. |
| `brandbook/examples/readme-header.svg` | README/GitHub specimen | Strongest deciding-surface artifact; restrained and credible. |
| `brandbook/examples/*.svg` | Palette, typography, components, docs, landing, terminal specimens | Useful implementation guidance without fake product UI. |

## Fresh Screenshot Evidence

Screenshots are intentionally temporary and not committed:

- Desktop brandbook: `/tmp/threadline-v133-brandbook-desktop.png`
- Mobile brandbook: `/tmp/threadline-v133-brandbook-mobile.png`
- Primary dark logo opened on white: `/tmp/threadline-v133-logo-primary.png`
- Primary light logo opened on white: `/tmp/threadline-v133-logo-primary-light.png`
- Favicon preview: `/tmp/threadline-v133-favicon.png`
- README header specimen: `/tmp/threadline-v133-readme-header.png`
- Updated brandbook logo section: `/tmp/threadline-v133-brandbook-logos-section.png`

## Observations

- The HTML brandbook opens directly from disk and reads as a practical reference, not just a decorative poster.
- Desktop first viewport is coherent: dark infrastructure, signal-line metaphor, restrained typography, clear sidebar navigation.
- Mobile first viewport is readable, though it leaves more vertical air before the hero than a public marketing page should.
- The README header specimen is the strongest public-surface proof: white background, restrained logo use, direct technical headline, standard badge posture.
- The dark primary logo should not be used on white README/GitHub backgrounds; Phase 150 added `logo-primary-light.svg` and updated usage guidance to fix that without redesigning the mark.

## Human Review Prompt

Review `brandbook/index.html`, `brandbook/logo-primary-light.svg`, `brandbook/logo-monochrome.svg`, `brandbook/favicon.svg`, `brandbook/social-card.svg`, and `brandbook/examples/readme-header.svg`.

Decision needed in Phase 151:

1. Approve current direction with the light-logo fix.
2. Request targeted revisions.
3. Ask for alternate logo/visual concepts.
4. Defer public rollout.
