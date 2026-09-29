---
phase: 215-supply-chain-gate
plan: 01
subsystem: infra
tags: [hex, mix, dependencies, security-advisory, mint, lazy_html, ecto, decimal, postgrex, plug]

requires:
  - phase: 214-baseline-measurement
    provides: measured pre-fix advisory baseline in PROJECT.md and check-project-baseline.sh
provides:
  - root mix.lock with mint 1.10.1 and lazy_html 0.1.13 (advisory-free)
  - bench/mix.lock with ecto/ecto_sql/decimal/postgrex/plug bumped as one group (advisory-free)
  - CHANGELOG.md Unreleased Security entry for the mint advisory
affects: [215-02, 215-03, 215-04]

actuals:
  tokens: 4100
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "package-group dependency bump (ecto+ecto_sql+decimal+postgrex+plug together) to clear a transitively-constrained advisory, instead of bumping the flagged package alone"

key-files:
  created:
    - .planning/phases/215-supply-chain-gate/deferred-items.md
  modified:
    - mix.lock
    - bench/mix.lock
    - CHANGELOG.md

key-decisions:
  - "Bumped mint and lazy_html via mix deps.unlock <pkg> + mix deps.get (not mix deps.update <pkg>), because mix deps.update also touched hpax as an uninstructed transitive bump; deps.unlock+deps.get produced a lockfile diff limited to exactly the two target entries"
  - "Bench advisory required bumping ecto/ecto_sql/decimal/postgrex/plug as one group, not decimal alone -- ecto 3.13.5's own package metadata pins decimal to ~> 2.0, which stalls decimal at the still-vulnerable 2.4.1; ecto 3.14.2 relaxes that internal constraint enough for the resolver to land on decimal 3.1.1"
  - "Recorded bench's pre-existing ExUnitProperties compile failure in deferred-items.md rather than chasing it -- reproduces identically before and after the bench lockfile bump, and no CI job or bench code path exercises it"

requirements-completed: [SUP-01]

coverage:
  - id: D1
    description: "Root mix.lock is hex.audit-clean via a lock-only mint 1.10.1 + lazy_html 0.1.13 bump, proven on both test lanes, in one releasable fix(deps): commit with a CHANGELOG.md Security entry"
    requirement: "SUP-01"
    verification:
      - kind: other
        ref: "mix hex.audit (root) -- No retired or security advisory packages found"
        status: pass
      - kind: unit
        ref: "test/threadline/changelog_contract_test.exs"
        status: pass
      - kind: other
        ref: "bin/verify-release-shape"
        status: pass
      - kind: integration
        ref: "mix test (root) -- 2207 tests, 0 failures"
        status: pass
      - kind: e2e
        ref: "CI=true mix verify.example_browser --project=desktop-chromium --project=mobile-chromium -- 318 passed, 26 skipped, 0 failed"
        status: pass
    human_judgment: false
  - id: D2
    description: "bench/mix.lock is hex.audit-clean after bumping ecto/ecto_sql/decimal/postgrex/plug as one group, with zero mix.exs constraint edits anywhere, and the Phase 214 baseline checker still passes"
    requirement: "SUP-01"
    verification:
      - kind: other
        ref: "mix hex.audit (root, bench, examples/threadline_phoenix) -- all three: No retired or security advisory packages found"
        status: pass
      - kind: other
        ref: "git diff --quiet 36ab6e71 -- bench/mix.exs examples/threadline_phoenix/mix.exs examples/threadline_phoenix/mix.lock, and root defp deps block diff empty"
        status: pass
      - kind: other
        ref: ".planning/phases/214-baseline-measurement/tools/check-project-baseline.sh -- exit 0, no MISSING: lines; bad-streak fixture correctly rejected"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-09-26
status: complete
---

# Phase 215 Plan 01: Supply Chain Gate — Advisory Cleanup Summary

**Cleared every known `mix hex.audit` advisory across root, bench, and the example app with lockfile-only bumps (mint, lazy_html, and a five-package ecto/ecto_sql/decimal/postgrex/plug group), both test lanes green, in two local commits.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-09-26T20:53:40Z (per STATE.md; plan executed same session)
- **Completed:** 2026-09-26
- **Tasks:** 2 completed
- **Files modified:** 4 (mix.lock, bench/mix.lock, CHANGELOG.md, deferred-items.md created)

## Accomplishments
- Root `mix.lock`: `mint` 1.10.0 -> 1.10.1 (response-smuggling advisory EEF-CVE-2026-82672 / GHSA-rj5m-69wp-cxq9, reached only via optional `req` -> `finch` -> `mint`) and `lazy_html` 0.1.12 -> 0.1.13 (test-only mutation-XSS advisory), lock-only, `mix.exs` untouched.
- `bench/mix.lock`: `ecto`/`ecto_sql`/`decimal`/`postgrex`/`plug` bumped together (decimal 2.3.0 -> 3.1.1, ecto 3.13.5 -> 3.14.2, ecto_sql 3.13.5 -> 3.14.0, plug 1.19.1 -> 1.20.3, postgrex 0.22.0 -> 0.22.4), clearing 8 advisories (3 HIGH) with zero `bench/mix.exs` edits.
- `CHANGELOG.md` `## Unreleased — highlights` now carries a `### Breaking changes` (None) and `### Security` section naming the mint fix and telling `req`-dependent adopters to run `mix deps.update mint`.
- Both test lanes proven green on the root bump: `mix test` (2207 tests, 0 failures) and the ci.all-form browser lane (318 passed, 26 skipped, 0 failed).
- All three lockfiles (root, bench, `examples/threadline_phoenix`) confirmed `hex.audit`-clean in one verification run.
- Phase 214's `check-project-baseline.sh` still exits 0 — the measured pre-fix advisory baseline in PROJECT.md stays a true historical statement, untouched.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — root lock bump (mint 1.10.1, lazy_html 0.1.13) with CHANGELOG line, proven on both test lanes, in one fix(deps) commit** - `78211c89` (fix)
2. **Task 2: Bench lock refresh as one package group; all three lockfiles audit clean; Phase 214 baseline check still green** - `416b251a` (chore)

_No plan-metadata commit yet — this SUMMARY commit follows._

## Files Created/Modified
- `mix.lock` - mint and lazy_html bumped to advisory-free patch versions
- `bench/mix.lock` - ecto/ecto_sql/decimal/postgrex/plug bumped as one group to clear postgrex/plug/decimal advisories
- `CHANGELOG.md` - Unreleased Security entry for the mint advisory, Breaking changes (None) section added
- `.planning/phases/215-supply-chain-gate/deferred-items.md` - records bench's pre-existing (unrelated) ExUnitProperties compile failure

## Decisions Made
- Used `mix deps.unlock <pkg> && mix deps.get` instead of `mix deps.update <pkg>` for the root bump: the first attempt with `deps.update mint lazy_html` also bumped `hpax` (an uninstructed transitive dependency of `mint`), failing the plan's "only mint/lazy_html changed" check. Reverting and retrying with `deps.unlock` + `deps.get` produced a lockfile diff limited to exactly the two target entries.
- Bench's advisory could not be cleared by bumping `decimal` alone — `ecto` 3.13.5's own package metadata constrains `decimal` to `~> 2.0`, which resolves to the still-vulnerable 2.4.1. Bumping `ecto`/`ecto_sql` together with `decimal`/`postgrex`/`plug` let the resolver land on `decimal` 3.1.1 (a major bump), clearing the advisory with no `bench/mix.exs` edit — matches the RESEARCH.md-documented pitfall exactly.
- Recorded (not chased) bench's pre-existing `ExUnitProperties`/`Threadline.Test.NamingGenerators` compile failure — reproduced identically before and after the dependency bump, confirming it is unrelated. No CI job runs `cd bench` or `verify.bench`, and no bench-owned code (only vendored `deps/`) references `Decimal`, so nothing depends on bench compiling standalone.

## Deviations from Plan

None - plan executed exactly as written. The mint/lazy_html retry (deps.unlock instead of deps.update) was explicitly anticipated by the plan's own action step ("If other entries changed, run `git checkout -- mix.lock` and retry with `mix deps.unlock mint lazy_html`...") and followed that instruction verbatim, so this is not a deviation.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The tree is now `hex.audit`-clean across all three lockfiles with zero dependency-constraint edits, both test lanes green — this is the precondition plan 215-02's `verify-deps-audit` CI gate needs before it can be made required.
- `.planning/phases/215-supply-chain-gate/deferred-items.md` carries one open, non-blocking item (bench's pre-existing compile failure) for future reference; it does not block plan 02/03/04.
- No blockers for 215-02 (the audit gate + alias), 215-03 (ignore_advisories contract test), or 215-04 (weekly deps-health issue).

---
*Phase: 215-supply-chain-gate*
*Completed: 2026-09-26*

## Self-Check: PASSED

All key files (mix.lock, bench/mix.lock, CHANGELOG.md, deferred-items.md, this SUMMARY.md) verified present on disk. Both task commits (78211c89, 416b251a) verified present in git log. All plan-level acceptance criteria and verification blocks re-run and passing (see Coverage above).
