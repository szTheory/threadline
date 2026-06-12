# Threadline Brandbook

This directory contains the repo-ready Threadline brand system. It is intentionally self-contained and source-control friendly: HTML, Markdown, JSON, CSS, and SVG only.

Open `index.html` directly in a browser to review the visual brandbook. The Markdown files are the durable source text:

- `brand-book.md` is the source-of-truth brand guide.
- `pressure-test.md` is the brand QA and readiness guide.
- `tokens.json` and `tokens.css` are implementation tokens for docs, marketing, and static examples.
- The logo family is eight pure-path SVGs (no live text, no font dependencies): `logo-primary.svg` (dark surfaces), `logo-primary-light.svg` (README/GitHub/light docs), `logo-wordmark.svg` (wordmark only, currentColor), `logo-monochrome.svg` (one paint value), `logo-mark.svg` (the extractable stitch), `favicon.svg` (designed at 16px, no container chip), `logo-primary-subtitle.svg` (the only tagline lockup), and `social-card.svg` (1280x640 link preview).
- `examples/readme-header.svg` and `examples/docs-page.svg` are the application specimens.

## Maintenance Rules

- Keep brand artifacts in this directory unless production code explicitly needs them.
- Prefer SVG, CSS, JSON, and Markdown over binary exports.
- Do not commit generated PNGs unless a specific downstream surface needs them.
- Do not duplicate font binaries here. Threadline already documents the Geist and IBM Plex Mono webfont files under `priv/fonts/`.
- Treat `lib/threadline/operator_surface/style.ex` as the current product UI contract. Use this directory for source brand guidance and static collateral, not runtime CSS changes.

## Best Current Defaults

- Positioning: "Audit history for Phoenix, Ecto, and PostgreSQL."
- Tagline: "Follow what happened."
- Logo system: an integrated typemark — the wordmark in Geist 600 outlines with the `d`/`l` ascenders cut at a fabric line and joined by a single stitch arc. The stitch alone is the mark and the favicon. Separate, individually designed dark-surface and light-surface primaries.
- Visual metaphor: a connected evidence path, not a generic node graph.
- Palette: dark infrastructure neutrals with Thread Blue and Signal Cyan used as functional signals; Stitch Blue `#4781E6` is reserved for the logo arc.
- Voice: calm senior engineer, exact about what Threadline does and does not do.
