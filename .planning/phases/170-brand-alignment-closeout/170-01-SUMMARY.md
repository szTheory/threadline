---
phase: 170-brand-alignment-closeout
plan: 01
subsystem: brandbook
tags: [brand, tokens, parity, doc-contract, theming]
requires:
  - "lib/threadline/operator_surface/style.ex (source of truth, frozen)"
provides:
  - "Curated brandbook<->style.ex token parity (18 tokens, dark + light)"
  - "Automated parity test failing CI on drift in either direction"
  - "brand-book.md UI theming posture (settled truth)"
  - "pressure-test.md dimension #11 dual-mode addendum + mechanical parity gate"
affects:
  - "brandbook/tokens.json"
  - "brandbook/tokens.css"
  - "brandbook/brand-book.md"
  - "brandbook/pressure-test.md"
  - "test/threadline/brandbook_token_parity_test.exs"
tech-stack:
  added: []
  patterns:
    - "doc-contract literal-lock (File.read! + String.contains?, async: true)"
    - "regex parse of --tl-color-* declarations over style.ex raw source"
    - "Jason.decode! over tokens.json semantic blocks"
key-files:
  created:
    - "test/threadline/brandbook_token_parity_test.exs"
  modified:
    - "brandbook/tokens.json"
    - "brandbook/tokens.css"
    - "brandbook/brand-book.md"
    - "brandbook/pressure-test.md"
decisions:
  - "D-01: full parity = curated-subset parity (name + value equal in both modes)"
  - "D-02: runtime-only + brand-exclusive gap documented via excluded_from_brand_scope"
  - "Bumped pressure-test dimension #11 from 8/10 to 9/10 (drift now automated); total 128->129"
requirements: [BRAND-01, BRAND-02]
metrics:
  duration: ~18m
  completed: 2026-06-14
  tasks: 3
  files: 5
---

# Phase 170 Plan 01: Brand Token Parity + Theming Posture Summary

Brandbook token SSOT reconciled to the shipped `style.ex` operator-surface lane and
locked with an automated parity test that fails CI on drift in either direction; brand
book gains the settled-truth UI-theming-posture note and the pressure-test gains the
dual-mode addendum + mechanical parity gate.

## What Shipped

- **Token reconciliation (`tokens.json` + `tokens.css`):** renamed the four curated
  semantic tokens to `style.ex` conventions (`text-muted`→`muted`, `text-soft`→`muted-soft`,
  `accent-text`→`on-accent`, `error-text`→`danger`) in both dark and light blocks; fixed
  `warning-text` to `style.ex` truth (dark `#FFD166`→`#F6C86B`, light `#7A5400`→`#8A5512`).
  Repointed the two now-dangling `state` block `var()` references in `tokens.json`
  (`state.error`, `state.muted`). Added an `excluded_from_brand_scope` block documenting
  the brand-exclusive `logo-arc` and the runtime-only structural tokens so the gap reads
  as intentional, not drift.
- **UI theming posture (`brand-book.md`):** new `### UI theming posture` subsection between
  the Dark/light strategy block and `## Color System`. States dark-primary; light shipped
  and supported via host `theme: :system | :light | :dark`; runtime toggle deferred to
  `THEME-TOGGLE-01` (localStorage permanently rejected); framed as the v1.33 settled-truth
  lesson now that light shipped in v1.36. All four required literals appear verbatim.
- **Pressure-test addendum (`pressure-test.md`):** dimension #11 "Dual-mode addendum (v1.36)"
  paragraph cross-referencing dimension #5; mechanical-suite parity gate line
  (`mix test test/threadline/brandbook_token_parity_test.exs   # must exit 0`); #11 score
  bumped 8→9 with the "drift now automated" justification; scorecard total and
  "Reading the total" line updated 128→129. No new dimension #16 (15 scored dimensions held).
- **Keystone parity test:** `Threadline.BrandbookTokenParityTest`, `async: true`, no
  token-count assertion. Parses the `style.ex` dark base block and the
  `[data-tl-theme="light"]` block (anchored before the `@media` system block — Pitfall 3),
  decodes `tokens.json` with Jason. Seven test blocks: dark intersection equality, light
  intersection equality, brand-exclusive refute against style.ex, runtime-only refute
  against the brandbook semantic blocks, tokens.css↔tokens.json consistency, brand-book
  posture lock, pressure-test addendum lock.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Reconcile tokens.json + tokens.css to style.ex truth | `bfc25e9` | brandbook/tokens.json, brandbook/tokens.css |
| 2 | UI theming posture note + pressure-test dual-mode addendum | `353480b` | brandbook/brand-book.md, brandbook/pressure-test.md |
| 3 | Keystone parity test (+ doc-contract locks) | `7dc0d28` | test/threadline/brandbook_token_parity_test.exs |

## Verification

- `mix test test/threadline/brandbook_token_parity_test.exs` → 7 tests, 0 failures.
- `mix format --check-formatted` passes for the new test file.
- `mix compile --warnings-as-errors` → exit 0 (clean).
- `node -e "JSON.parse(...tokens.json)"` → valid; `#F6C86B` present in both token files.
- No dangling `var(--tl-color-{error-text|text-muted|text-soft|accent-text})` in tokens.json.
- `style.ex` never staged in any of the three commits (source of truth frozen).
- The uncommitted nav-overhaul lane (style.ex + ~29 files) was never staged or edited.

## Deviations from Plan

### Auto-fixed Issues

None requiring a fix. One discretionary item exercised:

**1. [Discretionary] Bumped pressure-test dimension #11 score 8→9**
- The plan offered this as optional ("if bumped, update both the scorecard row and the
  score line in the #11 body, and adjust the scorecard total accordingly").
- Applied because the former known debt (hand-duplicated JSON/CSS, drift prevented by
  review) is now closed by the parity test (drift caught automatically). Updated the
  scorecard row, the #11 body score line, the scorecard total (128→129), and the
  "Reading the total" line (128→129).

### Scope Note

- The milestone audit doc (`v1.36-MILESTONE-AUDIT.md`, D-09) and the `REQUIREMENTS.md`
  traceability update (D-10) are NOT in this plan's `files_modified` — they belong to
  plan 170-02. This plan executed exactly the three tasks in `170-01-PLAN.md`.
- `mix ci.all` was not run as a per-task gate because the uncommitted nav-overhaul lane
  carries 3 pre-existing, out-of-scope test failures (standing caution in STATE.md). The
  plan's per-task verification (`mix test ...brandbook_token_parity_test.exs`) is green.

## Known Stubs

None.

## Self-Check: PASSED

- `test/threadline/brandbook_token_parity_test.exs` — FOUND
- Commit `bfc25e9` — FOUND
- Commit `353480b` — FOUND
- Commit `7dc0d28` — FOUND
