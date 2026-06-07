# Threadline Brandbook

This directory contains the repo-ready Threadline brand system. It is intentionally self-contained and source-control friendly: HTML, Markdown, JSON, CSS, and SVG only.

Open `index.html` directly in a browser to review the visual brandbook. The Markdown files are the durable source text:

- `brand-book.md` is the source-of-truth brand guide.
- `pressure-test.md` is the brand QA and readiness guide.
- `tokens.json` and `tokens.css` are implementation tokens for docs, marketing, and static examples.
- `logo-*.svg`, `favicon.svg`, `social-card.svg`, and `examples/*.svg` are editable vector assets. Use `logo-primary.svg` on dark surfaces and `logo-primary-light.svg` on README/GitHub/light documentation surfaces.

## Maintenance Rules

- Keep brand artifacts in this directory unless production code explicitly needs them.
- Prefer SVG, CSS, JSON, and Markdown over binary exports.
- Do not commit generated PNGs unless a specific downstream surface needs them.
- Do not duplicate font binaries here. Threadline already documents the Geist and IBM Plex Mono webfont files under `priv/fonts/`.
- Treat `lib/threadline/operator_surface/style.ex` as the current product UI contract. Use this directory for source brand guidance and static collateral, not runtime CSS changes.

## Best Current Defaults

- Positioning: "Audit history for Phoenix, Ecto, and PostgreSQL."
- Tagline: "Follow what happened."
- Logo system: horizontal wordmark plus simple continuous-line mark, with separate dark-surface and light-surface primary lockups.
- Visual metaphor: a connected evidence path, not a generic node graph.
- Palette: dark infrastructure neutrals with Thread Blue and Signal Cyan used as functional signals.
- Voice: calm senior engineer, exact about what Threadline does and does not do.
