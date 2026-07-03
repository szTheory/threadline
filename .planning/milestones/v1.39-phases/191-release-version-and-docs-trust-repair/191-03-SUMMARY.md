---
phase: 191-release-version-and-docs-trust-repair
plan: 03
subsystem: docs-version-truth
tags: [adopt-01, version-truth, install-pins, release-please, doc-contract]
requires:
  - "191-01 upgrade-path.md 0.8.x -> 0.9.x current-minor coverage (Family C proof)"
  - "191-02 verify.doc_contract alias (persona_routing appended; version_truth appended after)"
provides:
  - "All seven public install pins reconciled to three-segment ~> 0.9.0"
  - "evaluating-threadline.md current-version SSOT corrected to 0.9.0 + release-please auto-bump wiring"
  - "Central version_truth_doc_contract_test deriving pin/version/coverage from @version (drift-proof)"
affects:
  - "release-please-config.json extra-files (evaluating-threadline.md now auto-bumped)"
  - "priv/ci/hex_evaluator lock (fetches threadline 0.9.0 from hex.pm)"
tech-stack:
  added: []
  patterns:
    - "Derive-from-@version doc-contract guard (never hardcode the version)"
    - "x-release-please-version marker + extra-files pairing enforced by identity (Family B)"
    - "Three-segment .0 pin keeps patch releases green by construction"
key-files:
  created:
    - test/threadline/version_truth_doc_contract_test.exs
  modified:
    - README.md
    - guides/getting-started-saas.md
    - guides/operator-surface.md
    - guides/evaluating-threadline.md
    - guides/adoption-evidence-playbook.md
    - guides/adoption-pilot-backlog.md
    - priv/ci/hex_evaluator/mix.exs
    - priv/ci/hex_evaluator/mix.lock
    - release-please-config.json
    - mix.exs
    - test/threadline/adoption_pilot_doc_contract_test.exs
    - test/threadline/getting_started_saas_doc_contract_test.exs
    - test/threadline/operator_surface_doc_contract_test.exs
    - test/threadline/release_artifact_contract_test.exs
decisions:
  - "Reframed evaluating-threadline.md line-9 heading off the bare version (Open Question 1, executor's call) for truth; historical 0.6.0 lines preserved verbatim"
  - "Left the pre-existing v1_23_charter_doc_contract_test.exs failure as logged — milestone-charter truth is outside this plan's declared install-pin/SSOT/version_truth task scope"
metrics:
  duration: ~22m
  completed: 2026-07-02
status: complete
---

# Phase 191 Plan 03: Release Version & Docs Trust Repair (ADOPT-01) Summary

Reconciled every public install/version reference to the current `0.9.0` package truth and made the reconciliation drift-proof: seven `~> 0.6` install pins flipped to three-segment `~> 0.9.0` (co-committed with four guard tests so no CI/release state reddens), the false "0.6.0 is the SSOT" claim in `evaluating-threadline.md` corrected to `0.9.0` and wired for release-please auto-bump, and a new central `version_truth_doc_contract_test.exs` that derives the expected pin, current-version prose, and upgrade coverage from `mix.exs` `@version` so none of it can re-drift silently.

## What was built

### Task 1 — Atomic pin-flip across all seven references + four guards (commit `9a26d588`)
- Flipped all seven install pins from stale two-segment `~> 0.6` to three-segment `{:threadline, "~> 0.9.0"}` (D-191-02): README quick-start fence, `getting-started-saas.md`, `operator-surface.md`, `evaluating-threadline.md:38` (prose), `adoption-evidence-playbook.md` (prose), `adoption-pilot-backlog.md:14` (table cell), and `priv/ci/hex_evaluator/mix.exs` (real dep).
- Regenerated `priv/ci/hex_evaluator/mix.lock` via `MIX_ENV=test mix deps.update threadline` — now fetches `threadline 0.9.0` from hex.pm (transitively bumped `plug 1.19.2 -> 1.20.2` as the natural resolution).
- Reframed the `getting-started-saas.md` "Recommended path" heading off the bare `(0.6.0+)` label (D-191-03).
- Updated the four guard tests to assert `~> 0.9.0` and keep their sibling refutes valid: `adoption_pilot` (assert new pin + added `~> 0.6` refute + renamed test), `getting_started_saas` (assert new pin, kept `~> 0.5` refute), `operator_surface` (assert new pin, `~> 0.5`/`~> 0.3.0` refutes intact), `release_artifact` README pin assertion. `release_artifact` runs only under `verify.release`, updated here so the next release does not born-red.
- Verification: the four-test `mix test` set passed (34 tests, 0 failures).

### Task 2 — Correct the false SSOT claim + release-please wiring (commit `0b4975e2`)
- Changed only the line-11 current claim in `evaluating-threadline.md` from the false `0.6.0` SSOT number to `0.9.0` and appended the `<!-- x-release-please-version -->` inline marker on that same line (mirrors `adoption-pilot-backlog.md:7`).
- Reframed the line-9 heading to `## What the current Threadline release packages` (version-neutral).
- Preserved the protected historical `0.6.0 packages Evidence ... after 0.5.0` line verbatim (guarded by `evaluating_threadline_doc_contract_test`).
- Registered `guides/evaluating-threadline.md` (prose-claim file only) in `release-please-config.json` `extra-files` (D-191-07); no pin-bearing file added (D-191-05).
- Verification: `evaluating_threadline` + `adoption_pilot` tests passed (13 tests, 0 failures).

### Task 3 — Central version_truth_doc_contract_test + registration (commit `d24ca5ef`)
- Created `test/threadline/version_truth_doc_contract_test.exs` (`Threadline.VersionTruthDocContractTest`, `async: true`), deriving everything from `@version Threadline.MixProject.project()[:version]`:
  - **Family A** — globs `README.md` + `guides/**/*.md`, asserts every `{:threadline, "~> x.y.z"}` capture equals the derived `~> #{major}.#{minor}.0` (`~> 0.9.0`); guards against a vacuous empty scan.
  - **Family B** — every line carrying `x-release-please-version` must contain `@version` AND its file must be listed in `release-please-config.json` `extra-files` (born-red-proof by identity). Today: `adoption-pilot-backlog.md` + `evaluating-threadline.md`, both `0.9.0` and registered.
  - **Family C** — asserts `upgrade-path.md` documents the current-minor coverage `0.8.x -> 0.9.x` (accepts ASCII `->` or U+2192 arrow), derived from `@version`.
- Registered the test in the `verify.doc_contract` alias (D-191-08) so it runs under `mix ci.all`.
- Verification: `version_truth` passes 3/3 under `--warnings-as-errors`; full `mix verify.doc_contract` runs 117 tests with only the pre-existing `v1_23_charter` failure (see Deferred Issues).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed unused `@expected_pin` module attribute**
- **Found during:** Task 3 (first `version_truth` run)
- **Issue:** An intermediate `@expected_pin` attribute was set but never used; the project compiles doc-contract tests under `--warnings-as-errors` (via `ci.all`), so the warning would fail CI.
- **Fix:** Deleted the unused attribute, keeping only `@expected_pin_version`.
- **Files modified:** test/threadline/version_truth_doc_contract_test.exs
- **Commit:** d24ca5ef

### Natural resolution side effect (not a deviation)

- Regenerating the hex_evaluator lock for `threadline 0.9.0` also bumped its transitive `plug` dep `1.19.2 -> 1.20.2`. This is the honest output of `mix deps.update threadline` (T-191-SC: the only fetched package is Threadline's own already-published 0.9.0; no new third-party package introduced), so no legitimacy checkpoint was required.

## Deferred Issues

- **`v1_23_charter_doc_contract_test.exs` failure — left as logged (out of declared task scope).** The milestone-charter test asserts `PROJECT.md` contains the v1.38 milestone strings, but `PROJECT.md` is correctly on v1.39. This plan's declared task scope (frontmatter `files_modified` + Tasks 1-3) is install-pin / SSOT-prose / upgrade-coverage reconciliation; it does not include `PROJECT.md` or the charter test, and the `version_truth` guard covers a distinct axis (pins, current-version prose markers, upgrade coverage — not the milestone-charter literal). Per the SCOPE BOUNDARY rule and the execution instruction, it stays deferred to a plan that owns `PROJECT.md` / charter-test milestone truth. Appended a 191-03 note to `deferred-items.md` closing the loop.

## Verification

- `mix test` (six pin/prose/coverage guards: version_truth, adoption_pilot, getting_started_saas, operator_surface, evaluating_threadline, release_artifact) — 44 tests, 0 failures.
- `mix verify.doc_contract` — 117 tests, 1 failure (pre-existing `v1_23_charter`, out of scope; both new tests version_truth + persona_routing pass).
- Not run (require Postgres + network / clean-tree, deferred to CI): `mix verify.hex_evaluator`, `mix verify.release`, full `mix ci.all`. The hex_evaluator lock is regenerated to 0.9.0 so the Hex lane is green by construction; `release_artifact:88` (verify.release) asserts the new README pin.

## Self-Check: PASSED

- test/threadline/version_truth_doc_contract_test.exs — FOUND
- Commit 9a26d588 (Task 1) — FOUND
- Commit 0b4975e2 (Task 2) — FOUND
- Commit d24ca5ef (Task 3) — FOUND
