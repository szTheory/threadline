---
phase: 121-adopter-doc-neutrality
plan: 01
subsystem: docs
tags: [phoenix, auth, getting-started, doc-contract, sigra, phx-gen-auth]

requires:
  - phase: 119-phx-gen-auth-guide
    provides: phx-gen-auth integration guide and lane vocabulary
provides:
  - Auth-neutral getting-started §5 hero plug fence with host-owned MyApp.Audit callbacks
  - Optional sigra-reference subsection scoped by HTML fence marker
  - Generic §6 auth-before-plug contract with collapsed sigra-reference curl
  - Four-lane upgrade-path Who section and phx-gen-auth Next reads link
  - Doc-contract locks for neutrality and scoped Sigra router excerpt
affects: [121-02, evaluating-threadline, adoption-pilot-backlog]

tech-stack:
  added: []
  patterns:
    - "Two-tier doc opening: host auth contract first, optional reference lanes second"
    - "HTML details block for sigra-reference-only runnable curl"

key-files:
  created: []
  modified:
    - guides/getting-started-saas.md
    - guides/upgrade-path.md
    - test/threadline/getting_started_saas_doc_contract_test.exs

key-decisions:
  - "Used HTML details/summary for sigra-reference curl (hexdocs-friendly collapse)"
  - "Sigra router excerpt retained only after getting-started-sigra-reference-fence marker"

patterns-established:
  - "Doc contract splits generic plug asserts (main test) from Sigra router assert (scoped test)"

requirements-completed: [ADOPT-AUTH-01]

duration: 5min
completed: 2026-05-28
---

# Phase 121 Plan 01: Getting-Started Auth Neutrality Summary

**Getting-started §5/§6 rewritten so host-owned Threadline.Plug wiring is the default path, with Sigra and phx.gen.auth as peer optional reference lanes locked by doc-contract tests.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-28T11:22:00Z
- **Completed:** 2026-05-28T11:27:32Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- §5 opens with generic `MyApp.Audit` plug fence and lane pointer bullets; Sigra router excerpt moved to optional subsection behind `getting-started-sigra-reference-fence` marker
- §6 teaches auth-before-plug contract with lane table; runnable curl collapsed in `<details>` labeled sigra-reference example app only; example README linked as cookie SSOT
- `upgrade-path.md` Who section lists all four lanes in one bullet; Next reads adds phx-gen-auth guide
- Doc contract test asserts neutrality literals and scopes `router_block/0` to optional subsection only

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite §5 for generic plug + lane pointers** - `e4a4ba3` (docs)
2. **Task 2: Neutralize §6 authenticate + Next reads + upgrade-path intro** - `c988a1b` (docs)
3. **Task 3: Update getting_started doc contract for neutrality** - `c06fccd` (test)

**Plan metadata:** pending (docs: complete plan)

## Files Created/Modified

- `guides/getting-started-saas.md` - Auth-neutral §5/§6, lane pointers, optional Sigra fence, collapsed curl
- `guides/upgrade-path.md` - Four-lane Who-this-guide-is-for bullet list
- `test/threadline/getting_started_saas_doc_contract_test.exs` - Neutrality asserts and scoped sigra-reference fence test

## Decisions Made

- Used HTML `<details>`/`<summary>` for the sigra-reference curl block rather than a heading-only collapse — keeps hexdocs readable while de-emphasizing Sigra-specific steps
- Kept explicit "do not use Threadline.Integrations.Sigra" sentence before optional subsection per plan threat model T-121-01

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 121-02 can proceed on evaluator/adoption-pilot neutrality (ADOPT-AUTH-02/03)
- `mix test test/threadline/getting_started_saas_doc_contract_test.exs` green (4 tests, 0 failures)

## Self-Check: PASSED

- `grep -F 'actor_fn: &MyApp.Audit.actor_ref_from_conn/1' guides/getting-started-saas.md` — PASS
- `grep -F 'sigra-reference example app only' guides/getting-started-saas.md` — PASS
- `mix test test/threadline/getting_started_saas_doc_contract_test.exs` — PASS (4 tests, 0 failures)
- `grep 'assert String.contains?(doc, router_block())'` in main test body — absent (scoped test only) — PASS

---
*Phase: 121-adopter-doc-neutrality*
*Completed: 2026-05-28*
