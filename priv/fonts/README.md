# Historical operator surface brand fonts

Superseded, unshipped historical source. These files are preserved with their
original provenance and licenses; they are not the current Admin font source.
The approved identity is [brand/BRAND.md](../../brand/BRAND.md), and current
font assets and licenses are described in [brand/assets/README.md](../../brand/assets/README.md#fonts).

`lib/threadline/operator_surface/fonts.ex` embeds the approved Familjen Grotesk,
Geist and IBM Plex Mono webfonts from `brand/assets/fonts/web/` as compile-time
`@font-face` data-URIs. The scoped stylesheet keeps its fallback stacks, and
font embedding can still be disabled with:

```elixir
config :threadline, operator_surface_embed_fonts: false
```

The following inventory and download provenance describe only this historical
directory. Do not use them to regenerate the current brand assets.

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
