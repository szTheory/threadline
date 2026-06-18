# Phase 178: Per-page & flow stress pass (all 11 pages) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-18
**Phase:** 178-per-page-flow-stress-pass-all-11-pages
**Areas discussed:** Audit coverage strategy, Audit substrate, Shell wiring

**Process note:** Per standing preference [[gsd-research-then-recommend]], four gray areas were researched in parallel (verification strategy, footgun automation, SEED-005 mount/mutating-controls, transaction-bug root cause) before asking. Two areas (footgun guard approach, transaction centering fix) came back research-settled and were locked as recommendations without a question; three high-impact areas were put to the user.

---

## Audit coverage strategy (PAGE-01 — Tier B sampling)

| Option | Description | Selected |
|--------|-------------|----------|
| Full Tier A + ~66 high-signal Tier B | Tier A proves the full ~1,155-cell structural matrix every PR; Tier B samples 320+1440, happy+worst-path, dark+light, one each keyboard/reduced-motion/reconnect per page (~66 cells). | ✓ |
| Thicker Tier B (+768 mid-breakpoint) | Same plus error/empty at 768 (~+11 cells). | |
| Thinnest Tier B (shell-shared specs) | Tier B only happy+error per page; keyboard/reconnect/reduced-motion as shell-level shared specs. | |

**User's choice:** Full Tier A + ~66 high-signal Tier B
**Notes:** Continues the 0-human-UAT campaign; honest framing required ("A proves structure, B proves a representative real-engine sample"). 768 cell deferred (D-02, Deferred Ideas).

---

## Audit substrate (real LiveViews vs static fixtures)

| Option | Description | Selected |
|--------|-------------|----------|
| Static fixtures (hybrid for live flows) | 7-path × theme × viewport matrix via deterministic static fixtures on /audit/__stress; live flows (loading→terminal, reconnect/socket-drop) driven against real LiveViews in a small Tier B set. | ✓ |
| Static fixtures only | Everything via fixtures incl. faked reconnect; real socket-drop stays a probe. | |
| Real LiveViews for the audit | Drive actual LiveViews with seeded ugly data for the whole audit; faithful but flake/DB cost. | |

**User's choice:** Static fixtures (hybrid for live flows)
**Notes:** Closes the 177 unmounted-banner gap where a fixture can't (true socket drop) while keeping the bulk matrix deterministic.

---

## Shell wiring (SEED-005 reconnect banner mount)

| Option | Description | Selected |
|--------|-------------|----------|
| Extract a shared shell component | Pull the 11-way-duplicated `threadline-ui` + `#tl-main` wrapper into one internal component; single banner mount point. | ✓ |
| Inline banner in each of the 11 renders | Add the banner + data-tl-mutating to each LiveView render; smaller diff, wrapper stays duplicated 11×. | |

**User's choice:** Extract a shared shell component
**Notes:** Research found no shared shell exists; the wrapper is already hand-maintained 11×, so this is the moment to converge it. Larger diff accepted for the correct structural home.

---

## Claude's Discretion

- Locked from research without a user question: **footgun approach** (guard-first, layered global+per-page, all 11 automatable — D-05/06/07) and the **transaction centering fix** (`justify-self:center` on `.tl-container`, root-caused as a grid-item-centering trap — D-08/09).
- `data-tl-mutating` scope locked per research (D-12): destructive/DB-write controls now, download links get `aria-disabled`, no-op stubs skipped.
- Exact fixture/story IDs, shared-shell component API, detector module organization, Tier B centering tolerance, and any opportunistic `tl-short-content` alignment (D-14, D-09b) — Claude's discretion per 171–177 conventions.

## Deferred Ideas

- Microcopy / IA sweep of pages → Phase 179.
- Formal accessibility + motion + adversarial sign-off → Phase 180.
- Thicker Tier B sampling (768 cell, per-page keyboard/reconnect) → promote only if a regression slips Tier A.
- Real-LiveView audit of the full 7-path matrix → kept to fixtures for determinism.
