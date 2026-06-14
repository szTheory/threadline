---
phase: 169-screenshots-example-docs
plan: 02
subsystem: docs / operator-surface
tags: [docs, doc-contract, theme, light-mode, operator-surface]
requires:
  - "theme: option (router.ex compile-validated :dark|:light|:system, default :dark) — already shipped (Phase 166)"
  - "light/system token lanes in style.ex — already shipped (Phases 166-167)"
provides:
  - "guides/operator-surface.md Theme subsection documenting theme: :dark|:light|:system + D-04 daytime recommendation"
  - "README.md additive theme: :system daytime pointer (mount snippet unchanged)"
  - "theme_doc_contract_test.exs literal-pin lock for the documented theme triad + daytime recommendation"
affects:
  - guides/operator-surface.md
  - README.md
  - test/threadline/operator_surface/theme_doc_contract_test.exs
tech-stack:
  added: []
  patterns:
    - "Doc-contract literal-pin (File.read! + String.contains?, async: true) mirroring timeline_browse_doc_contract_test.exs"
    - "Additive doc lock (D-05) — new test guards the new Theme subsection; existing snippet contracts untouched"
key-files:
  created:
    - test/threadline/operator_surface/theme_doc_contract_test.exs
  modified:
    - guides/operator-surface.md
    - README.md
decisions:
  - "D-05 honored: theme: kept OUT of the canonical mount snippet (dark-default stays clean); documented in a dedicated Theme subsection with a separate :system example block"
  - "Light framed strictly as readability/accessibility (bright rooms, dense audit text, astigmatism prevalence) — NO medical eye-strain claim (165 lesson)"
  - "Daytime-use recommendation reflowed onto one contiguous line so the precedent fragment matches the doc-contract literal pin (doc and lock agree)"
metrics:
  duration: ~10m
  completed: 2026-06-14
  tasks: 2
  files: 3
---

# Phase 169 Plan 02: Theme Option Docs + Doc-Contract Lock Summary

Documented the operator-surface `theme: :dark|:light|:system` option truthfully in the guide and README, and locked the documented triad + the D-04 daytime-use recommendation with a new additive literal-pin doc-contract test — the canonical dark-default mount snippet and all four existing snippet/mount-block contracts stay untouched and green.

## What Was Built

### Task 1 — Theme subsection in guide + README pointer (commit e00a5cd)
- Added a `### Theme` subsection to `guides/operator-surface.md` (near the 1-Minute Mount / options area, right after the `schemas:` note). It documents:
  - `:dark` (default) — brand-primary; omit `theme:` to get it.
  - `:light` — forces the light lane regardless of OS.
  - `:system` — auto-follows OS preference via scoped CSS only (`@media (prefers-color-scheme: light)` keyed on `data-tl-theme`), correct on first paint/dead render, no JS, no `localStorage`, no runtime toggle, no FOUC.
  - The settled precedent one-liner: "Dark stays the default and the brand; `:system` is the documented daytime-use recommendation," framed as a readability/accessibility choice (bright rooms, dense audit text, astigmatism prevalence) — never a medical eye-strain claim.
  - A separate `theme: :system` mount example block (the canonical dark-default snippet stays clean per D-05).
- Added ONE additive sentence to `README.md` near the operator-console paragraph pointing daytime/bright-environment teams to `theme: :system` and the guide's Theme subsection. The root README `threadline_operator_surface` mount block is byte-identical (the pointer sits outside it).

### Task 2 — Literal-pin doc-contract test (commit 04f3663)
- Created `test/threadline/operator_surface/theme_doc_contract_test.exs` (`use ExUnit.Case, async: true`, `@guide_path "guides/operator-surface.md"` constant), mirroring the `timeline_browse_doc_contract_test.exs` analog. Five tests, each asserting a single literal against the guide via `File.read! + String.contains?` with a named failure message: `theme:`, `:dark`, `:light`, `:system`, and the `daytime-use recommendation` precedent fragment.
- No `capture_io`, Mix-task, or runtime assertions — pure read-and-pin.

## Verification

Targeted 5-file run (the new test + the 4 existing contracts that guard their own files), all green — 40 tests, 0 failures:

```
mix test test/threadline/operator_surface/theme_doc_contract_test.exs \
         test/threadline/readme_doc_contract_test.exs \
         test/threadline/getting_started_saas_doc_contract_test.exs \
         test/threadline/example_phoenix_readme_contract_test.exs \
         test/threadline/example_phoenix_schemas_mount_contract_test.exs
# 40 tests, 0 failures
```

- `readme_doc_contract_test.exs` passed UNCHANGED — its `readme_mount_block/0` normalized lock confirms the additive `:system` pointer did not perturb the root README mount snippet (byte-identical).
- The 3 existing snippet contracts (getting_started_saas / example_phoenix_readme / example_phoenix_schemas_mount) passed UNCHANGED for the files they guard.
- `git diff --name-only` confirmed none of those 4 existing test files were modified.
- `mix format --check-formatted test/threadline/operator_surface/theme_doc_contract_test.exs` → clean.
- grep confirmed the guide carries `theme:` (3), `:dark` (2), `:light` (2), `:system` (4), `daytime` (1), and `eye strain` (0); README carries `:system` (2).
- The full suite was NOT run (it carries 3 unrelated pre-existing nav-overhaul failures outside this plan's scope).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Daytime-recommendation line break broke the doc-contract literal pin**
- **Found during:** Task 2 (RED/first test run)
- **Issue:** The Task 1 guide prose wrapped "documented daytime-use" / "recommendation" across a newline, so `String.contains?(src, "daytime-use recommendation")` failed (the literal was split by `\n`).
- **Fix:** Reflowed the sentence so "daytime-use recommendation" is contiguous on one line, making the doc and its lock agree. The fix touched the already-committed guide file and was folded into the Task 2 commit (same plan, declared file).
- **Files modified:** guides/operator-surface.md
- **Commit:** 04f3663

## Scope Discipline

- Staged ONLY the three declared files by explicit path; never `git add -A`/`-a`/`.`.
- No file under `lib/`, no example-app router, no nav-overhaul file, and no existing doc-contract test was touched.
- STATE.md and ROADMAP.md intentionally NOT modified (orchestrator owns those after the wave).

## Known Stubs

None.

## Self-Check: PASSED
- FOUND: guides/operator-surface.md (Theme subsection present)
- FOUND: README.md (:system pointer present)
- FOUND: test/threadline/operator_surface/theme_doc_contract_test.exs
- FOUND commit e00a5cd (Task 1)
- FOUND commit 04f3663 (Task 2)
