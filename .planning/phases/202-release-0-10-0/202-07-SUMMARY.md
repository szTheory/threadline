---
phase: 202-release-0-10-0
plan: 07
subsystem: docs
tags: [exdoc, changelog, release-gate, autolink]

requires:
  - phase: 202-03
    provides: the 0.10.0 changelog entry whose module inventory triggers the autolink warnings
provides:
  - "Measured warning inventory for `mix docs --warnings-as-errors` (60 lines, three distinct classes)"
  - "Validated fix mechanisms for each class, proven to exit 0"
affects: [202-09, release-0.10.0]

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified: []

key-decisions: []

requirements-completed: []

duration: in-progress
completed:
status: halted
---

# Phase 202 Plan 07: ExDoc warning gate Summary

**IN PROGRESS — Task 1 research complete, awaiting maintainer decision. Task 2 not started.**

## Task 1 — measured warning inventory

`mix docs --warnings-as-errors` at `98692abf`: **exit 1, exactly 60 `warning:` lines**, in
**three** distinct classes (the plan anticipated two).

| # | Class | Lines | Source | Authored by |
|---|-------|-------|--------|-------------|
| 1 | `references module "X" but it is hidden` — 25 distinct `Threadline.*` modules × 2 formats (html + epub) | 50 | `CHANGELOG.md:97–115` (the 0.10.0 inventory) | Plan 202-03 (`291d061a`) |
| 2 | `references callback "c:put/2" but it is undefined` — 3 sites × 2 formats | 6 | `CHANGELOG.md:56`, `CHANGELOG.md:123`, `guides/upgrade-path.md:112` | Plan 202-03 (`291d061a`, `c35cb0dc`) |
| 3a | `references module "mix release.pins" but it is hidden` × 2 formats | 2 | `CONTRIBUTING.md:661` | Phase 202 (`43c64458`) |
| 3b | `references file "bin/verify-environment-protection" but it does not exist` × 2 formats | 2 | `CONTRIBUTING.md:649` | Phase 202 (`d4eddcbf`) |

### Corrections to the plan's stated measurements

1. **25 modules, not 26.** The 0.10.0 inventory names 25 modules, and the entry's own prose at
   `CHANGELOG.md:62` says "25 implementation modules". The plan's figure of 26 (and Task 2's
   acceptance criterion "All 26 modules are still named") is wrong and must be corrected to 25
   before Task 2 runs, or Task 2's gate is unsatisfiable. The 26th module-shaped warning is
   `mix release.pins`, which comes from `CONTRIBUTING.md`, not the changelog.
2. **The `c:put/2` references are NOT pre-existing.** `git blame` puts all three on Phase 202
   commits from 2026-09-22 (`291d061a`, `c35cb0dc`). Both `CHANGELOG.md` references sit *inside*
   the 0.10.0 entry (which spans lines 29–125), not in older entries.
3. **`c:put/2` warns "undefined", not "hidden".** `Threadline.Storage` is public and does define
   `@callback put(content(), options())` at `lib/threadline/storage.ex:53`. The reference fails
   only because an unqualified `c:put/2` inside an extras file has no module context.
4. **A third warning class the plan did not anticipate:** `bin/verify-environment-protection`.
   The file *does* exist in the repo; the markdown link at `CONTRIBUTING.md:649` is repo-relative
   and `bin/` is not published into the doc output. Neither Option A nor Option B addresses it.

## Task 1 — decision pending

Awaiting the maintainer's choice on the module inventory (Option A vs Option B). The brief,
including the validated experiment results, is in the handback report. Nothing in `mix.exs`,
`CHANGELOG.md`, `CONTRIBUTING.md`, or `guides/upgrade-path.md` has been changed by this plan;
all four files are byte-identical to `98692abf`.

## Deviations from Plan

None yet — Task 1 is a checkpoint and was not auto-decided.

## Next Phase Readiness

Blocked on the Task 1 `gate="blocking-human"` decision. Task 2 must not start until the choice
is recorded above.

---
*Phase: 202-release-0-10-0*
*Status: awaiting human decision*
