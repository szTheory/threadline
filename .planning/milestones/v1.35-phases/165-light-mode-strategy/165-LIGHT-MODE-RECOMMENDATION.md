# 165-LIGHT-MODE-RECOMMENDATION.md — Threadline Light Mode Strategy

- **Phase:** 165-light-mode-strategy (milestone v1.35)
- **Inputs:** `165-RESEARCH-ECOSYSTEM.md` (lane A), `165-RESEARCH-LESSONS.md` (lane B), `165-RESEARCH-SURFACE.md` (lane C)
- **Status:** Recommendation — awaiting user decision (approve → seed v1.36 / adjust / defer)
- **Date:** 2026-06-12

This is one recommendation, not a menu. Alternatives appear only as "rejected because" notes.

---

## The recommendation in one paragraph

Ship light mode as **milestone v1.36 "Operator Surface Light Mode"**: a host-configured `theme: :dark | :light | :system` option on `threadline_operator_surface/2`, default `:dark`, implemented as a pure-CSS second token lane under `.threadline-ui[data-tl-theme="light"]` (and a media-gated `system` variant) — zero JavaScript, zero FOUC by construction, CSP-proof. Dark remains the brand-primary identity and the literal default; `:system` becomes the *documented recommendation* for teams whose operators work in daylight. No runtime toggle in v1 (the host config IS the persistence), with a committed cookie-based upgrade path if per-operator switching is ever demanded. The light lane is **designed, never recolored**: 19 of 45 tokens seed from the brand book's already-retuned light lane; the remaining 26 (status tints, glass surfaces, shadows, focus ring, accent tints) get explicit design work, with the shared status-tint system as the single biggest decision. The dark-only freeze (decision [136-01]) is amended deliberately: this checkpoint's approval is the unfreeze decision, executed source-first in v1.36 with the style contract tests amended in the same wave.

## Why this and not nothing

- Every successful dark-default devtool (Grafana, Linear, VS Code) ships light mode; the ones that deferred (Stripe dashboard, Avo) bred third-party recolor hacks and multi-year retrofits (Avo: open request since 2022, now paid-tier-gated). [Lane B]
- The counter-lesson is equally firm: an **undesigned** light mode is a liability — a Grafana org patched the source to *remove* light theme because dark-tuned content looked bad in it. Hence "designed, never recolored" is a hard rule, and data-viz-adjacent surfaces (coverage, timeline, diffs) get explicit retune attention. [Lane B]
- Reading-performance evidence favors offering light for daytime/dense-text use (strongest for small text and the ~30–50% of users with astigmatism); the precise "dark mode causes daytime eye strain" claim is softer, but the product conclusion is the same and matches NN/g guidance: dark identity, light option, user choice. [Lane B]
- Threadline is architecturally ready: every color in the operator surface flows through the `--tl-*` token block on one scope, with exactly one stray hardcoded rgba (style.ex:489). Light mode is a token-lane addition plus targeted retuning — not a rewrite. [Lane C]

## Mechanism (lane A, verified against peers)

- Bare `.threadline-ui` = dark (today's CSS, byte-stable for existing adopters).
- `.threadline-ui[data-tl-theme="light"]` = the light token lane; `color-scheme: light` flips scoped native controls/scrollbars (MDN-verified to work on a non-root container).
- `.threadline-ui[data-tl-theme="system"]` = light lane wrapped in `@media (prefers-color-scheme: light)`.
- The attribute is rendered **server-side** on the LiveView root elements from the router option — first paint is correct on the dead render. No `<head>` script (a mounted library cannot inject one), no localStorage (FOUC on every dead render + dies under `embed_scripts: false` CSP hosts — the Oban Web pattern only works because Oban Web owns its layout; Backpex, our only true peer, went server-side for exactly this reason).
- Phoenix 1.8's `data-theme` vocabulary and light/dark/system triad is the ecosystem-canonical shape; we use the `tl-`-prefixed attribute to stay collision-free inside host layouts.

## Host API

```elixir
threadline_operator_surface "/audit",
  authorize_fn: &MyApp.authorize_audit/1,
  theme: :system   # :dark (default) | :light | :system
```

- Compile-validated like the existing options; invalid values raise at compile time with the allowed triad named.
- Default `:dark` — zero behavior change for every existing adopter (principle of least surprise for a library; the converged "system-sync default" pattern from lane B applies to products that own their UI — for a mounted library, the *host* makes that call).
- Docs recommend `:system` for teams whose operators work in bright environments; the adoption guide carries the one-line rationale.
- LiveDashboard's own maintainers converged on config-not-toggle for mountable surfaces (issue #343). The v1.31 `theme-toggle` contract ban **stands**.

## Token architecture (lane C numbers)

- 45 color-bearing tokens need light values. 19 seed directly from `brandbook/tokens.json` `semantic.light` (already correctly contrast-retuned: accent `#4F8CFF→#1557C0` 6.65:1 on white, signal darkened, etc.).
- 26 need design: **status tints (15 — the one big decision: light-mode tints become tinted backgrounds with darkened text, the industry-standard inversion of dark-mode's glow-on-dark)**, glass surfaces (3), shadows (3), focus ring/border (2 — current `#7FA9FF` fails on white at 2.33:1), accent tints (3). Plus the one stray rgba at style.ex:489.
- Two brand-lane values fail AA for body text on white (`text-soft` 3.93:1, light `signal` 3.97:1) and get corrected as part of the lane — brand book tokens.json is extended to full 45-token parity in the same milestone so the brand SSOT and the UI contract stay aligned.
- ~45 of 74 `.tl-*` component families retheme for free; ~20 ride entirely on the status-tint decision; ~9 need individual work (glass chrome ×4, drawer scrim+shadow, focus glow, home-card effects, line-489 inset).

## Freeze amendment (the honest part)

Decision [136-01] ("dark-only: no light mode, no system mode, no theme toggle") is enforced by seven test assertions in `style_contract_test.exs` (bans on `prefers-color-scheme` / `color-scheme: light` at lines 8-14, 86-87, 121-122, 168-169, 196-197) plus the Phase 144 anti-pattern list. Procedure, per the v1.31 source-first convention:

1. **This checkpoint's approval = the superseding decision**, recorded in STATE.md ("[165-01] supersedes [136-01]: dark remains default; light/system supported via host config; theme-toggle ban stands").
2. v1.36's opening wave amends `style.ex` and `style_contract_test.exs` **in the same wave** (the contract stays source-first): the seven refutes become theme-aware assertions; the AA contrast test gains a light mirror (its `color_tokens/1` helper needs alpha-tint parsing — known, sized).
3. The `theme-toggle` ban is retained verbatim. Runtime per-operator switching stays out until real adopter demand; the committed upgrade path is the Backpex-style cookie + plug through the macro's existing plug machinery (zero-JS HTML form), explicitly NOT localStorage.

## v1.36 phase breakdown (sized from lane C)

| Phase | Scope | Size |
|---|---|---|
| 1. Unfreeze + token lane + mechanism | Superseding decision; light lane for all 45 tokens (19 seeded, 26 designed — status-tint system decided here); `data-tl-theme` attr on the 10 LiveView roots; router `theme:` option; contract tests amended same-wave | M–L (design-heavy) |
| 2. Component retune | The ~9 individual-work families + verification pass over the ~20 tint-riders; data-viz-adjacent surfaces (coverage/timeline/diff) get explicit light review — the Grafana lesson | L (largest) |
| 3. Accessibility verification | AA mirror test (alpha-aware), focus-visible audit per mode, keyboard states | S–M |
| 4. Screenshots + example app + docs | `__light__` baseline lane (local-only — visual guard is CI-skipped per cf0e8e2, so no CI cost), example app demos `theme: :system`, adoption guide + operator-surface guide updates | S–M |
| 5. Brand alignment + closeout | tokens.json 45-token parity, brand book "UI theming posture" note (dark-primary, light supported), pressure-test addendum, milestone audit | S |

## What the brand book says meanwhile (now, in v1.35)

Nothing changes now. The brand book already documents dual-mode for brand/docs surfaces (light logo, `<picture>` snippet, light token lane). The "UI theming posture" statement is added in v1.36 phase 5, once it's true — the brand book states settled truth, not intent (v1.33 lesson).

## Rejected alternatives (brief)

- **localStorage/head-script theming** — library can't inject `<head>`; FOUC every dead render; dies under CSP. [Lane A]
- **Runtime toggle in v1** — persistence machinery + UI for a preference the host can express in one line of config; `theme-toggle` ban stands; upgrade path documented instead. [Lanes A+B]
- **Light or `:system` as the literal default** — changes existing adopters' surface without their choosing and dilutes the dark-first brand; `:system` is the documented recommendation, not the default. [Lanes A+B]
- **Do nothing** — the Avo/Stripe retrofit evidence and the reading-performance literature both say this gets more expensive with time; and Threadline's seam makes it unusually cheap now. [Lanes B+C]

---
*Decision pending: approve (seed v1.36) / adjust / defer — recorded verbatim in 165-01-SUMMARY.md.*
