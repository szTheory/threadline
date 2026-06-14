# Roadmap: Threadline

## Milestones

- ✅ **v1.36 Operator Surface Light Mode** — Phases 166-170 (shipped 2026-06-14). Archive: `.planning/milestones/v1.36-ROADMAP.md`
- ✅ **v1.35 Unified Logo & Brand Book v2** — Phases 159-165 (shipped 2026-06-12). Archive: `.planning/milestones/v1.35-ROADMAP.md`
- ✅ **v1.34 Local Docker Admin UI DX** — Phases 154-158 (shipped 2026-06-07). Archive: `.planning/milestones/v1.34-ROADMAP.md`
- ✅ **v1.33 Brand Review + Direction Selection** — Phases 150-153 (shipped 2026-06-06). Archive: `.planning/milestones/v1.33-ROADMAP.md`
- ✅ **v1.32 Brand System Foundation** — Phases 145-149 (shipped 2026-06-05). Archive: `.planning/milestones/v1.32-ROADMAP.md`

_Between milestones — define the next with `/gsd:new-milestone`._

## Phases

<details>
<summary>✅ v1.36 Operator Surface Light Mode (Phases 166-170) — SHIPPED 2026-06-14</summary>

`theme: :dark | :light | :system` host config rendered server-side as `data-tl-theme` over a pure-CSS 45-token light lane (no JS/FOUC, CSP-proof). Dark stays the default and the brand; `:system` is the documented daytime-use recommendation. 15/15 requirements; audit passed.

- [x] Phase 166: unfreeze-token-lane-mechanism (1/1 plans) — completed 2026-06-13 — 45-token light lane, `data-tl-theme` mechanism, compile-validated `theme:` option, source-first contract amendment
- [x] Phase 167: component-retune (2/2 plans) — completed 2026-06-14 — ~9 dark-effect families + data-viz surfaces explicitly retuned for light (the Grafana lesson)
- [x] Phase 168: accessibility-verification (2/2 plans) — completed 2026-06-14 — light/system AA contrast mirror (alpha-aware parser) + per-mode focus/interaction contracts
- [x] Phase 169: screenshots-example-docs (2/2 plans) — completed 2026-06-14 — `__light__` screenshot lane, example app `theme: :system`, `theme:` docs under doc-contract
- [x] Phase 170: brand-alignment-closeout (2/2 plans) — completed 2026-06-14 — tokens.json/css 45-token parity, dual-mode pressure-test, milestone audit

**Deferred at close:** end-of-milestone human UAT (`169`/`170-HUMAN-UAT.md`), `170-VERIFICATION.md` (human-needed), and 3 operator-surface todos — see STATE.md Deferred Items.

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|---|---|---:|---|---|
| 166. unfreeze-token-lane-mechanism | v1.36 | 1/1 | Complete | 2026-06-13 |
| 167. component-retune | v1.36 | 2/2 | Complete | 2026-06-14 |
| 168. accessibility-verification | v1.36 | 2/2 | Complete | 2026-06-14 |
| 169. screenshots-example-docs | v1.36 | 2/2 | Complete | 2026-06-14 |
| 170. brand-alignment-closeout | v1.36 | 2/2 | Complete | 2026-06-14 |

## Prior Milestones

- ✅ **v1.35 Unified Logo & Brand Book v2** — Phases 159-165 (shipped 2026-06-12). Archive: `.planning/milestones/v1.35-ROADMAP.md`
- ✅ **v1.34 Local Docker Admin UI DX** — Phases 154-158 (shipped 2026-06-07). Archive: `.planning/milestones/v1.34-ROADMAP.md`
- ✅ **v1.33 Brand Review + Direction Selection** — Phases 150-153 (shipped 2026-06-06). Archive: `.planning/milestones/v1.33-ROADMAP.md`
- ✅ **v1.32 Brand System Foundation** — Phases 145-149 (shipped 2026-06-05). Archive: `.planning/milestones/v1.32-ROADMAP.md`
