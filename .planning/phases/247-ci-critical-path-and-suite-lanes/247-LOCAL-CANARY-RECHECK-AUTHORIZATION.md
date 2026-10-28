# Phase 247 Local Canary Recheck Authorization

**Date:** 2026-10-27 (UTC)
Decision: authorize-one-recheck-series

**Approval source:** The maintainer replied, “what do u rec? let's follow ur recs”, after the recommendation to authorize exactly one local recheck series capped at 150 seconds total, with the first invalid result stopping the series and no retry. This is the maintainer's fresh answer to the Plan 24 scope checkpoint. The consumed Plan 22 grant is not reused.

## Authorized scope

Authorize exactly one native ARM64 local recheck using the cached pinned runtime image. Preflight is capped at 45 seconds total and may use at most two metadata/version probes plus one full-runner compile smoke; each child is capped at 15 seconds. Only if preflight is valid, the series may run at most two warmups, three A/B pairs in A/B, B/A, A/B order, and two controls. Each child is capped at 15 seconds. The entire grant, including preflight, is capped at 150 seconds.

The first invalid result stops the series immediately: no retry, no replacement, and no source repair under this grant. Cleanup may use only a captured container ID after inspection confirms that its name matches this run. If identity is missing, malformed, colliding, reused, or mismatched, stop invalid; do not remove by name, and disclose any container left for operator follow-up.

This authorization covers a local diagnostic only. It does not authorize image pulls, package installation, network access, a production suite, hosted CI, push, PR, merge, a new main cohort, or edits to models, weights, thresholds, or fixtures.

## Approved executable source

- Reviewed Plan 23 repair commit: `9fae282de737701af0d2a4009632afa662bd381d`
- Candidate worktree HEAD when this record was prepared: `f5acad55b7addf911e3507bef8e33b72c163251b`
- `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py` — SHA-256 `7e4cd2f2fc125638a8b13d46e064c22beb7a43e2f6b77430b715b4d35ebce78d`
- `.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs` — SHA-256 `dc75bbe51c196b6d1540f151d51b3443191d4ec76b59826ab3ee0ebcdf2640a2`
- `test/support/partition_monitor.ex` — SHA-256 `3164124276f674842be3d4515eb94a063969a7054f7716b655d206fefbbe2aa4`

All three worktree files were byte-compared with commit `9fae282d`; all matched. Plan 25 must verify these approved hashes before creating its separate candidate-bound machine grant, reservation, preflight, or Docker child. Changed executable bytes require a new explicit scope answer. Only metadata commits may occur before that preflight.
