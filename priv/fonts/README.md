# Operator surface brand fonts

Latin-subset `woff2` webfonts embedded by the Threadline operator surface
(`lib/threadline/operator_surface/fonts.ex`) as compile-time `@font-face`
data-URIs, scoped to `.threadline-ui`. They are a progressive enhancement over
the token fallback chains (Inter / system-ui, JetBrains Mono / ui-monospace) and
can be disabled with:

```elixir
config :threadline, operator_surface_embed_fonts: false
```

## Contents

| File | Family | Weight | License |
|------|--------|--------|---------|
| `geist-400.woff2` | Geist | 400 | SIL OFL 1.1 |
| `geist-500.woff2` | Geist | 500 | SIL OFL 1.1 |
| `geist-600.woff2` | Geist | 600 | SIL OFL 1.1 |
| `ibm-plex-mono-400.woff2` | IBM Plex Mono | 400 | SIL OFL 1.1 |
| `ibm-plex-mono-500.woff2` | IBM Plex Mono | 500 | SIL OFL 1.1 |

## Provenance & licensing

- **Geist** © The Geist Project Authors — https://github.com/vercel/geist-font
- **IBM Plex Mono** © IBM Corp. (Reserved Font Name "Plex") — https://github.com/IBM/plex

Both are licensed under the SIL Open Font License, Version 1.1. Full license
texts are redistributed alongside the fonts as `OFL-Geist.txt` and
`OFL-IBMPlexMono.txt`. The `woff2` files are the `latin` subsets distributed by
the Fontsource project (https://fontsource.org); regenerate by re-downloading
`latin-<weight>-normal.woff2` for each family from the Fontsource CDN.
