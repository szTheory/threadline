# Phase 200 — UI Review

**Audited:** 2026-09-12
**Baseline:** Abstract 6-pillar standards (no UI-SPEC.md)
**Screenshots:** Captured from generated `doc/index.html` at 1440×900, 768×1024, and 375×812. A service on port 8080 was also detected but identified as the unrelated Traefik dashboard and excluded from scoring.

---

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 2/4 | The intent-led routing is clear, but the landing repeats setup/operator guidance and opens with dense compatibility and API prose. |
| 2. Visuals | 2/4 | Native ExDoc provides a clear hierarchy, but the intended theme-aware logo is absent from the generated landing and the mobile table collapses into a cramped scan. |
| 3. Color | 3/4 | The restrained neutral/purple ExDoc palette is coherent, but the brand color system is barely expressed and dark mode was not evidenced by the captured default state. |
| 4. Typography | 2/4 | Desktop headings are legible, while the 375 px capture renders body, table, code, and footer text at an impractically small apparent size. |
| 5. Spacing | 2/4 | Desktop rhythm is consistent, but the long single-column landing has weak section chunking and the narrow layout compresses content instead of creating usable breathing room. |
| 6. Experience Design | 2/4 | Search, grouped navigation, focus styling, overflow handling, and diagram fallback exist, but the unreadable narrow landing and missing brand asset materially impair orientation. |

**Overall: 13/24**

---

## Top 3 Priority Fixes

1. **Repair the narrow-layout reading experience** — at 375 px the route table, paragraphs, code sample, and footer are visually reduced to tiny text, undermining the primary documentation task — add a generated-doc mobile contract and an ExDoc-compatible responsive override that preserves a minimum readable body size, turns the three-column intent table into stacked lane cards/rows, and keeps code horizontally scrollable.
2. **Make the theme-aware logo actually render in generated ExDoc** — the README declares both logo sources and the files exist under `doc/brandbook`, but `doc/index.html` contains neither the `<picture>` nor logo image, so the intended visual identity disappears — use ExDoc-supported image markup/asset references and assert the generated HTML contains the light/dark logo targets before release.
3. **Reduce and sequence the README landing** — compatibility detail, API inventory, evidence-plane limitations, setup routing, and a second operator mount procedure compete before readers reach the guide index — keep a concise value proposition, four intent routes, and one primary adoption CTA above the fold; move exhaustive API/support/operator detail to the canonical guides already linked.

---

## Detailed Findings

### Pillar 1: Copywriting (2/4)

- **WARNING:** `README.md:13-21` front-loads a long version matrix, CI implementation detail, the fragment “Auditing for Phoenix.”, and nine API references before the reader reaches the intent chooser. Replace this with one outcome-led sentence and move compatibility mechanics to the configuration or support reference.
- **WARNING:** `README.md:62-124` reintroduces substantial operator setup and a full router snippet after the README already routes adopters to canonical guides at `README.md:27-36`. This weakens the single-owner model and makes the landing materially longer than necessary even if the prose-contract tests permit the repetition.
- **WARNING:** Labels such as “Evidence plane,” “support-lane posture,” and “claim assessment” (`README.md:38-53`) are accurate but specialist-first. Define the user outcome before the internal vocabulary or move this section to the Evaluate lane.
- Positive evidence: the four verbs in `README.md:27-32` are specific, task-oriented, and paired with descriptive destinations; no generic Submit/Click Here/OK/Cancel/Save CTA pattern was found in the public documentation corpus.

### Pillar 2: Visuals (2/4)

- **WARNING:** The generated `doc/index.html` does not contain `logo-primary`, `<picture>`, or the declared image markup even though `README.md:1-4`, `mix.exs:387-391`, and the copied files under `doc/brandbook/` intend a theme-aware logo. Desktop, tablet, and mobile screenshots therefore open with a plain text `Threadline` H1 rather than the specified brand asset.
- **WARNING:** The “Start here” table (`README.md:27-32`) is a strong desktop focal component, but at 375 px its three columns become narrow strips with word-by-word wrapping. Convert it to a single-column intent list below the mobile breakpoint.
- **WARNING:** The landing is a nearly uninterrupted text column from compatibility through operator setup. Native H2 styling distinguishes sections, but there is no visual summary or progressive disclosure around the longest operator block (`README.md:76-124`).
- Positive evidence: desktop and tablet captures show a clear H1/H2 hierarchy, restrained link styling, visible search, and a predictable content rail.

### Pillar 3: Color (3/4)

- **WARNING:** The rendered landing uses almost entirely white/near-black surfaces with ExDoc purple links. This is coherent and readable, but the absent logo means the Threadline brand palette has no meaningful visual anchor beyond generic documentation chrome.
- **WARNING:** Dark-theme variables and a theme-sensitive Mermaid path exist (`mix.exs:524-526`, `mix.exs:545-557`), but the captured page remained in the default light state. Dark-mode contrast and logo switching therefore remain unverified visual claims in this audit.
- Positive evidence: the built ExDoc stylesheet centralizes semantic light/dark variables and uses accent color primarily for links/search rather than flooding decorative elements; no phase-owned hardcoded application color sprawl was introduced.

### Pillar 4: Typography (2/4)

- **WARNING:** At 375×812 the full-page capture shows body copy, table content, inline code, and footer links at an apparent size that is difficult to read without zooming. The base stylesheet declares `--text-xs`, `--text-sm`, `--text-md`, `--text-lg`, and `--text-xl`, plus multiple fixed and relative sizes; the result lacks a robust minimum readable scale on this page.
- **WARNING:** The very large `Threadline` H1 followed by a second `Threadline` heading (`README.md:6` plus the ExDoc page title/module heading) creates redundant hierarchy rather than useful differentiation.
- Positive evidence: desktop heading weights, monospace code, paragraph leading, and list styles are internally consistent and use bundled ExDoc fonts.

### Pillar 5: Spacing (2/4)

- **WARNING:** The desktop content rail is consistent but very long; sections from `README.md:38-124` have similar paragraph density and vertical cadence, so important transitions do not gain enough separation or summary treatment.
- **WARNING:** On mobile, 20 px content gutters are present in the native stylesheet, yet the table and long inline identifiers consume the available measure and force severe wrapping. Spacing is technically consistent but not functionally sufficient for the content shape.
- **WARNING:** The collapsed “All guides” block (`README.md:133-178`) leaves navigation hidden at the bottom of a long page. A short, visible set of lane links would provide a more useful terminal rhythm without expanding the complete index.
- Positive evidence: code blocks use contained surfaces and the custom Mermaid container applies `max-width: 100%` and `overflow-x: auto` (`mix.exs:511-522`).

### Pillar 6: Experience Design (2/4)

- **WARNING:** The mobile rendering degrades the core task of choosing and reading a guide. This is not merely cosmetic: users must zoom or decode narrow table columns to navigate the four primary intents.
- **WARNING:** The intended brand image is silently omitted from generated HTML rather than falling back to an equivalent rendered mark. Add an artifact-level assertion against `doc/index.html`, not only checks that source assets are packaged.
- **WARNING:** Mermaid depends on a third-party CDN (`mix.exs:535-539`). The script uses SRI, strict Mermaid security, and falls back to visible source on render failure (`mix.exs:553-595`), which is safe, but offline/CSP-restricted readers receive raw diagrams rather than an equally usable visual.
- **WARNING:** The complete guide directory is placed in a collapsed disclosure at the page end (`README.md:133-178`). Search and sidebar navigation help, but first-time readers cannot see breadth without opening an easily missed control.
- Positive evidence: native ExDoc supplies search and responsive navigation; the injected Mermaid wrapper handles horizontal overflow; the script re-renders on theme changes; ExDoc styles include focus-visible treatment and reduced-motion handling. No destructive UI flow exists in this phase, and registry safety was skipped because `components.json` is absent.

---

## Files Audited

- `README.md`
- `mix.exs`
- `doc/index.html`
- `doc/dist/html-elixir-YJO4MOOW.css`
- `doc/brandbook/logo-primary.svg`
- `doc/brandbook/logo-primary-light.svg`
- `guides/getting-started-saas.md`
- `guides/operator-surface.md`
- `guides/how-threadline-works.md`
- `guides/configuration-and-commands.md`
- `CONTRIBUTING.md`
- `lib/threadline/operator_surface/style.ex`
- `lib/threadline/operator_surface/ui.ex`
- All Phase 200 execution plans, summaries, and `200-CONTEXT.md`
- Screenshots in `.planning/ui-reviews/200-docs-20260912-224642/`
