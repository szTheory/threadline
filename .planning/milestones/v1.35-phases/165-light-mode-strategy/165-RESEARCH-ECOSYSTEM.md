# Phase 165 — Lane A: Ecosystem Theming Research

**Researched:** 2026-06-12
**Question:** What is idiomatic for an Elixir/Phoenix LIBRARY that mounts an admin UI surface (LiveView) into a host app, when adding dark+light theme support — with dark remaining the default/primary?
**Confidence:** HIGH (every ecosystem claim verified against primary source code or official docs; URLs cited per finding)

---

## 1. How existing Elixir admin surfaces handle theming

### Phoenix LiveDashboard — no theming at all

LiveDashboard is light-only. Dark mode is an open feature request ([issue #343](https://github.com/phoenixframework/phoenix_live_dashboard/issues/343), opened by maintainer mcrumm, labeled "design related," no PR, no owner). The maintainer's own proposal is telling for library idiom: he suggested a **boolean config option (`dark_mode`)** that conditionally loads a different CSS file — i.e., even the core-team instinct for a mountable surface is *host compile-time config, not a runtime toggle*. `[VERIFIED: github.com/phoenixframework/phoenix_live_dashboard/issues/343]`

Architecture note: LiveDashboard (like Oban Web) **owns its entire page** — it mounts with its own root layout, so it controls `<html>`. Threadline does not (see §2). Its `alias: false, as: false` router hygiene is already mirrored by Threadline's router macro.

### Oban Web — light/dark/system three-way, localStorage, owns its root layout

Oban Web (open source since v2.11, [github.com/oban-bg/oban_web](https://github.com/oban-bg/oban_web)) is the most complete reference. Verified from source:

- **Selection:** a `ThemeComponent` LiveComponent renders a dropdown with exactly `~w(light dark system)` plus a keyboard shortcut that cycles them ([lib/oban/web/live/theme_component.ex](https://github.com/oban-bg/oban_web/blob/main/lib/oban/web/live/theme_component.ex)).
- **Mechanism:** a `Themer` JS hook toggles a `.dark` class on `document.documentElement`; Tailwind `dark:` variants do the rest. `system` (and the no-preference default) resolves via `matchMedia("(prefers-color-scheme: dark)")` with a live `change` listener, so the UI follows OS theme changes in real time ([assets/js/hooks/themer.js](https://github.com/oban-bg/oban_web/blob/main/assets/js/hooks/themer.js)).
- **Persistence:** `localStorage` under key `oban:theme` ([assets/js/lib/settings.js](https://github.com/oban-bg/oban_web/blob/main/assets/js/lib/settings.js)). No cookie, no host session.
- **FOUC avoidance:** an inline `<script nonce={@csp_nonces.script}>` in **its own** `root.html.heex` reads localStorage and applies the class *before* first paint — with the comment "Apply sidebar width before page renders to prevent flash" on the sibling setting ([lib/oban/web/components/layouts/root.html.heex](https://github.com/oban-bg/oban_web/blob/main/lib/oban/web/components/layouts/root.html.heex)).

**Critical caveat:** Oban Web can do all of this *only because it owns `<html>` and the root layout*. The whole pattern (documentElement class + head inline script) is unavailable to a surface rendered inside the host's root layout. `[VERIFIED: oban_web source]`

### Backpex — configurable daisyUI themes, dual persistence: localStorage + session cookie (SSR-correct)

Backpex is the only Elixir admin library that solved theming for a surface living inside the **host's** layout, and its answer is instructive ([github.com/naymspace/backpex](https://github.com/naymspace/backpex)):

- `Backpex.HTML.Layout.theme_selector/1` renders radio inputs per theme (`{"Light", "light"}, {"Dark", "dark"}, ...`) — daisyUI `data-theme` values ([lib/backpex/html/layout.ex](https://github.com/naymspace/backpex/blob/develop/lib/backpex/html/layout.ex), [hexdocs installation guide](https://hexdocs.pm/backpex/installation.html)).
- The JS hook writes the choice to localStorage **and POSTs it to a library-provided cookie endpoint** (`Router.cookie_path`), storing it in the Plug session ([assets/js/hooks/_theme_selector.js](https://github.com/naymspace/backpex/blob/develop/assets/js/hooks/_theme_selector.js)).
- `Backpex.ThemeSelectorPlug` reads `session["backpex"]["theme"]` and assigns `:theme`, so the host layout renders `data-theme={@theme}` **server-side on the dead render** — first paint is already correct, no FOUC, no head script needed ([lib/backpex/plugs/theme_selector.ex](https://github.com/naymspace/backpex/blob/develop/lib/backpex/plugs/theme_selector.ex)).

The localStorage half exists only to repaint *before* the next server round-trip; the session half is what makes SSR correct. `[VERIFIED: backpex source]`

### Kaffy — no theming

Kaffy has no built-in theme support; customization is via "Extensions" that inject arbitrary CSS/JS ([github.com/aesmail/kaffy](https://github.com/aesmail/kaffy); community write-up: [Custom Kaffy Styling](http://blog.andyglassman.com/2023/06/custom-kaffy-styling.html)). Not a pattern source. `[CITED]`

### Phoenix 1.7 / 1.8 generator posture

- **Phoenix 1.7:** no dark mode out of the box; Tailwind `dark:` variants are unconfigured and the community rolls its own ([elixirforum thread](https://elixirforum.com/t/how-to-add-dark-mode-for-phoenix-1-7/54356), [btihen.dev manual toggle](https://btihen.dev/posts/elixir/phoenix_1_7_11_liveview_1_0_0_manual_dark_toggle/), [btihen.dev theme post](https://btihen.dev/posts/elixir/phoenix_1_7_14_theme_light_dark/)).
- **Phoenix 1.8:** "All phx.new apps now ship with light and dark themes out of the box, with a toggle built into the layout" ([release blog](https://www.phoenixframework.org/blog/phoenix-1-8-released)). Verified implementation from installer templates ([phoenixframework/phoenix installer/templates](https://github.com/phoenixframework/phoenix/tree/main/installer/templates)):
  - daisyUI theme blocks in `app.css`: light is `default: true`, dark is `prefersdark: true`, each carries `color-scheme: "light"|"dark"`.
  - Theme is a **`data-theme` attribute on `<html>`**, plus `data-theme-source="user"|"system"` to distinguish explicit choice from OS-following.
  - Tailwind dark variant is attribute-keyed: `@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));`
  - Persistence: `localStorage` key `phx:theme`; "system" = key removed.
  - FOUC: an **inline `<script>` in the `<head>` of `root.html.heex`** sets `data-theme` from localStorage/`matchMedia` before paint, listens to `storage` (cross-tab sync) and `prefers-color-scheme` changes, and handles a `phx:set-theme` window event dispatched by the `theme_toggle` component via `JS.dispatch` — so toggling needs no LiveView round-trip.

So the 2026 Phoenix-core idiom is: **`data-theme` attribute, three-way system/light/dark, localStorage, head inline script** — all predicated on owning `<html>`. `[VERIFIED: phoenix installer templates]`

**Pattern summary:**

| Surface | Themes | Selector | Mechanism | Persistence | Owns `<html>`? |
|---|---|---|---|---|---|
| LiveDashboard | light only | — (proposed: boolean config) | — | — | yes |
| Oban Web | light/dark/system | in-UI dropdown + shortcut | `.dark` class on `<html>` | localStorage `oban:theme` | yes |
| Backpex | host-defined daisyUI list | in-UI radio dropdown | `data-theme` on `<html>` (host renders it) | localStorage + **session cookie → SSR** | **no — host does** |
| Phoenix 1.8 apps | light/dark/system | in-layout toggle | `data-theme` on `<html>` | localStorage `phx:theme` | yes (it's the app) |
| Kaffy | none | — | — | — | yes |

## 2. CSS-custom-property theming for embedded UIs that cannot own `<html>`

Threadline's situation: the operator surface LiveViews `use Phoenix.LiveView` with no layout override, so they render inside the **host's** root layout — Threadline never touches `<html>`/`<body>`/`<head>`. All styling already lives in one `<style>` block scoped under `.threadline-ui`, where every color is a `--tl-*` custom property and `color-scheme: dark` is set on the scope root (`lib/threadline/operator_surface/style.ex`, line 176). `[VERIFIED: repo]`

This is exactly the architecture the platform supports for scoped theming:

- **`color-scheme` works on non-root elements and is inherited.** MDN shows it applied per-element (`header { color-scheme: only light }` / `footer { color-scheme: only dark }`); within that subtree it switches form controls, scrollbars, spellcheck underlines, and CSS system colors ([MDN: color-scheme](https://developer.mozilla.org/en-US/docs/Web/CSS/color-scheme)). So a light Threadline theme must flip `.threadline-ui { color-scheme: light }` along with the tokens, and native `<select>`/scrollbars inside the surface follow correctly even though the host page may be the opposite scheme. `[CITED: MDN]`
- **Theme switching = re-declaring the token block under a scoped selector.** The three mechanisms, all scoped (no `:root` needed):
  1. **Media query (system-following):** `@media (prefers-color-scheme: light) { .threadline-ui { --tl-color-bg: ...; } }` — pure CSS, zero JS, but no override and no way to keep dark-primary for users whose OS is light.
  2. **Attribute/class switch:** `.threadline-ui[data-tl-theme="light"] { --tl-... }` — explicit, server-renderable on the wrapper Threadline *does* own. This is the scoped analogue of Phoenix 1.8's `data-theme` on `<html>`.
  3. **Combination (system-with-override):** dark tokens as the bare `.threadline-ui` default; light block applied for `[data-tl-theme="light"]`; and the media-query light block gated to `[data-tl-theme="system"]` only. Explicit beats system; absence of the attribute means dark. This mirrors Phoenix 1.8's `data-theme` + `data-theme-source` semantics without JS.
- **`light-dark()`** is the newer alternative (single declaration, two values, driven by `color-scheme: light dark`) ([MDN: color-scheme](https://developer.mozilla.org/en-US/docs/Web/CSS/color-scheme)). It would work scoped, but it inverts control — the *scheme* decides, so "dark even when the OS is light" requires `color-scheme: only dark`, and per-token pairs would rewrite all ~100 `--tl-*` declarations into coupled two-value form. The token-block-swap pattern keeps the Phase-144 frozen dark block byte-stable and adds light as a separate, brandbook-`tokens.json`-driven lane. Prefer block swap. `[CITED: MDN; VERIFIED: style.ex structure]`

Note the v1.31 contract tests literally ban the strings `prefers-color-scheme` and `theme-toggle` in `style.ex` (`test/threadline/operator_surface/style_contract_test.exs` lines 12, 86, 121, 168, 196, 826–828) — any mechanism choice requires the deliberate freeze amendment that lane C documents. `[VERIFIED: repo]`

## 3. Selection + persistence options for a LIBRARY surface

Evaluated for Threadline specifically: host owns auth/session; the lib's culture is zero npm dependencies and embedded vanilla JS that is opt-out for CSP-strict hosts (`config :threadline, operator_surface_embed_scripts: false` precedent in `script.ex`; same shape in `fonts.ex`). `[VERIFIED: repo]`

| Option | How | Pros | Cons |
|---|---|---|---|
| **Host compile-time config** (router macro option) | `theme: :dark \| :light \| :system` beside `authorize_fn`; flows through `live_session` opts into mount; rendered as `data-tl-theme` on `.threadline-ui` | Zero JS; zero FOUC (attribute is in the dead render); zero persistence problem; matches LiveDashboard maintainers' own instinct (§1); matches every existing Threadline option's grammar; existing adopters unaffected | No per-operator choice; changing theme = config change + redeploy |
| **Pure system-following** (`prefers-color-scheme` only) | Media-query token block, no attribute | Zero JS, zero config, "free" | Surrenders dark-primary: OS-light operators never see the brand surface; no override; an audit operator can't pin a theme per tool. No surveyed library ships system-only with no override |
| **Runtime toggle, localStorage** (Oban Web / Phoenix 1.8 style) | JS hook + localStorage + head inline script | Familiar; cross-tab sync | **Structurally wrong for an embedded surface**: the FOUC-prevention script must run in `<head>` before CSS paint, and Threadline does not own `<head>`. Dead render can't see localStorage → guaranteed dark→light flash on every full page load. Requires shipping/registering JS in the host bundle (against zero-JS culture) and breaks under `embed_scripts: false` |
| **Runtime toggle, cookie → session/plug** (Backpex style) | Library POST endpoint sets cookie; a plug (Threadline already emits `SessionPlug` and sibling controller scopes from the macro) reads it; theme renders server-side | SSR-correct: no FOUC ever; can be implemented **zero-JS** as a plain HTML form that POSTs and redirects back; per-operator choice | More moving parts (endpoint + plug + cookie naming + CSRF); a UI affordance (toggle) the brand currently bans; only worth it if adopters actually demand per-operator switching |
| **Host session** | Host writes a theme key into its own session | none over cookie option | Invasive: requires host code cooperation; couples Threadline to host session shape — violates "host owns auth/session, lib treats it as opaque" |

The ecosystem split is clean: surfaces that **own** `<html>` use localStorage + head script (Oban Web, Phoenix 1.8); the one surface that **doesn't** (Backpex) uses a server-visible cookie/session precisely so the dead render is correct. `[VERIFIED: sources in §1]`

## 4. FOUC avoidance in LiveView SSR contexts

LiveView serves a complete **dead render** (plain HTML over HTTP) before JS connects; the connected render replaces it without re-running the root layout. Consequences, verified against the three shipping implementations:

- Anything known **server-side at dead-render time** (compile-time config, session, cookie) produces a correct first paint with no script at all. Backpex's `ThemeSelectorPlug` exists for exactly this ([source](https://github.com/naymspace/backpex/blob/develop/lib/backpex/plugs/theme_selector.ex)).
- Anything stored **client-side only** (localStorage) requires a synchronous inline `<script>` in `<head>` before the stylesheet paints — Phoenix 1.8's root layout script and Oban Web's nonce'd root-layout script are both this, and both live in layouts those projects own ([phoenix installer root.html.heex.eex](https://github.com/phoenixframework/phoenix/blob/main/installer/templates/phx_web/components/layouts/root.html.heex.eex), [oban_web root.html.heex](https://github.com/oban-bg/oban_web/blob/main/lib/oban/web/components/layouts/root.html.heex)). Backpex's hook comment is explicit that even calling its `setStoredTheme()` "as soon as possible" from the host's `app.js` only *minimizes* flashes ([hook source](https://github.com/naymspace/backpex/blob/develop/assets/js/hooks/_theme_selector.js)).
- A library that renders only inside `<body>` could at best inline a script adjacent to its own wrapper — later than `<head>`, still flash-prone on slow CSS, and dead under CSP-strict hosts. **For an embedded surface, the only flash-free designs are server-rendered theme state or pure-CSS media queries.** `[VERIFIED: cited sources]`

## 5. API shape beside Threadline's existing mount opts

The real option grammar in `lib/threadline/operator_surface/router.ex` (read in full): `authorize_fn:`, `actor_fn:`, `adopter_acknowledges_unauthenticated:`, `exports:` (boolean, default `true`), `scope_query_fn:`, `export_authorize_fn:`, `coverage_authorize_fn:`, `policy_authorize_fn:`, `evidence_authorize_fn:`. Pattern: **flat keyword opts, snake_case, secure/conservative defaults, additive and backward-compatible; the whole `opts` list is passed into `live_session` `on_mount` tuples and plugs, so a new key reaches every LiveView mount with no new plumbing.** `[VERIFIED: repo]`

The matching shape:

```elixir
threadline_operator_surface "/audit",
  authorize_fn: &MyApp.Audit.authorize/1,
  theme: :system            # :dark (default) | :light | :system
```

- `:dark` default → existing adopters and the Phase-144 dark token freeze see zero behavioral change; dark stays brand-primary.
- Atom values, validated at compile time in the macro (raise `CompileError` on bad value — same fail-fast posture as the auth guard).
- Value travels via the existing `unquote(opts)` channel into `on_mount`, lands as a `@theme` assign, and is emitted as `data-tl-theme={@theme}` on the `.threadline-ui` wrapper.
- Naming precedent: Backpex calls its concept `themes`/`theme`; Phoenix 1.8 uses `data-theme`; LiveDashboard's proposal was `dark_mode: true` — a boolean is too narrow once `:system` exists. `theme:` (singular atom) is the right arity for a curated two-lane design system, vs Backpex's open list which exists because daisyUI ships dozens of themes.

---

## What this means for Threadline (Lane A posture — stated decisively)

**Mechanism.** Keep the single-scope `--tl-*` token architecture and theme by token-block swap on the wrapper Threadline owns. The bare `.threadline-ui` block stays the frozen dark lane (unchanged, brand-primary). Add one light token block under `.threadline-ui[data-tl-theme="light"]` (values from the brandbook `tokens.json` light lane) and duplicate it inside `@media (prefers-color-scheme: light)` gated to `.threadline-ui[data-tl-theme="system"]`. Flip `color-scheme: light` in the same selectors so native controls and scrollbars follow within the surface (MDN-verified scoped behavior). No `light-dark()`, no Tailwind variant machinery, no JS.

**API.** A single `theme: :dark | :light | :system` option on `threadline_operator_surface/2`, default `:dark`, validated in the macro, delivered through the existing opts channel and rendered server-side as `data-tl-theme` on `.threadline-ui`. This is the LiveDashboard maintainers' own instinct (config option), expressed in the modern Phoenix 1.8 vocabulary (`data-theme`-style attribute, light/dark/system triad), scoped the only way an embedded surface can be.

**Persistence.** None in the first cut — the host's router config *is* the persistence, which is zero-JS, zero-FOUC (theme is in the dead render), CSP-proof, and consistent with every other Threadline mount decision living in the router. **No in-UI toggle and no localStorage, ever, for this surface**: localStorage theming structurally requires a `<head>` script Threadline cannot inject, and would flash on every dead render. If per-operator switching is later demanded, the committed upgrade path is the Backpex model adapted to existing Threadline machinery — a sibling POST endpoint (precedent: the exports controller scope the macro already emits) sets a library-owned `tl_theme` cookie, a plug (precedent: `SessionPlug`/`ExportAuthPlug`) reads it into the mount, and the toggle is a plain HTML form, keeping it zero-JS and SSR-correct. Rejected: system-only (surrenders dark-primary), host-session storage (couples to host auth, which Threadline treats as opaque).

This posture requires amending the v1.31 contract bans on `prefers-color-scheme` (needed for `:system`) — lane C documents the freeze-amendment procedure; the `theme-toggle` ban can stand.

---

## Sources

### Primary (HIGH confidence — source code read directly)
- https://github.com/oban-bg/oban_web — `assets/js/hooks/themer.js`, `assets/js/lib/settings.js`, `lib/oban/web/live/theme_component.ex`, `lib/oban/web/components/layouts/root.html.heex`
- https://github.com/naymspace/backpex — `lib/backpex/html/layout.ex`, `assets/js/hooks/_theme_selector.js`, `lib/backpex/plugs/theme_selector.ex`
- https://github.com/phoenixframework/phoenix — `installer/templates/phx_web/components/layouts/root.html.heex.eex`, `installer/templates/phx_web/components/layouts.ex.eex`, `installer/templates/phx_assets/app.css.eex`
- https://github.com/phoenixframework/phoenix_live_dashboard/issues/343
- Threadline repo: `lib/threadline/operator_surface/router.ex`, `style.ex`, `script.ex`, `fonts.ex`, `live/*.ex`, `test/threadline/operator_surface/style_contract_test.exs`

### Secondary (MEDIUM–HIGH)
- https://developer.mozilla.org/en-US/docs/Web/CSS/color-scheme
- https://www.phoenixframework.org/blog/phoenix-1-8-released
- https://hexdocs.pm/backpex/installation.html
- https://github.com/aesmail/kaffy

### Tertiary (community posture evidence)
- https://elixirforum.com/t/how-to-add-dark-mode-for-phoenix-1-7/54356
- https://btihen.dev/posts/elixir/phoenix_1_7_14_theme_light_dark/
- https://btihen.dev/posts/elixir/phoenix_1_7_11_liveview_1_0_0_manual_dark_toggle/
- http://blog.andyglassman.com/2023/06/custom-kaffy-styling.html
