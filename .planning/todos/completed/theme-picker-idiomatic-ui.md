---
created: 2026-06-13T00:00:00Z
title: Dark/light/system theme picker with idiomatic UI controls (THEME-TOGGLE-01 demand signal)
area: operator-surface
resolves_phase: 175
origin: Phase 167 light-mode review (user request)
related_requirement: THEME-TOGGLE-01
related_decision: [165-01]
files:
  - .planning/REQUIREMENTS.md
  - lib/threadline/operator_surface/router.ex
  - lib/threadline/operator_surface/auth.ex
  - lib/threadline/operator_surface/style.ex
---

## Problem

During the Phase 167 light-mode review the operator explicitly asked for an in-product
**dark / light / system theme picker** using idiomatic UI controls, rather than the v1
host-config-only lever (the router `:theme` opt set once per mount).

This is the **demand signal** that `THEME-TOGGLE-01` (REQUIREMENTS.md:44) was gated on
("only on real adopter demand"). Decision `[165-01]` currently retains the `theme-toggle`
ban for v1.36 (no runtime toggle, no localStorage); the contract test enforces the ban
(`refute theme-toggle`).

## Solution (when promoted)

Build a per-operator runtime theme switch as a **Backpex-style cookie + plug, zero-JS form**
(the upgrade path already documented for THEME-TOGGLE-01) — not localStorage:
- A `prefers-color-scheme`-aware `:system` default plus explicit `:light` / `:dark` choices.
- Idiomatic control (segmented control / select) placed in the operator chrome.
- Server reads the cookie in a plug and sets `@threadline_theme` per request (today it's a
  static per-mount assign from the router opt in `auth.ex`).
- Lift the `theme-toggle` ban in the style contract test as part of the same change, and
  record a decision superseding `[165-01]`.

**Not in Phase 167** (light-mode value/treatment work only). Promote to its own phase/slice
when scheduled.
