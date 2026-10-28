---
phase: 247-ci-critical-path-and-suite-lanes
status: offline_repairs_complete
source_commit: 8c9f1541
observation_grant: none
---

# Offline tooling unblock

Authorization: maintainer said “okay cool so whats next follow ur recs unblock us...” after the recommendation to repair warning-free readiness, verdict verification and elapsed-time recording offline. This authorizes the repairs and local verification; it does not replace the consumed observation grants or authorize Docker/hosted runs.

## Changes

- Rename the unused Elixir argument to `_mode`; preserve the runner's A/B and control behavior.
- Derive both VALID and INVALID preflight verdicts from raw compiler output, runtime, image and owned-container evidence. Verify compile/runtime projections for both statuses. Derive INVALID series reasons from observed arms as well.
- Keep execution's clean-current-source gate. Read-only historical verification binds to the receipt's own committed producer and source, so later repairs do not invalidate an unchanged historical receipt. Bind each preflight schema version to the producer's declared version, preventing a timing-schema downgrade.
- Add preflight `/2` monotonic start/end/elapsed/limit fields and child timing. Bind start to the persistent reservation, enforce clock arithmetic, child containment and caps. Carry one absolute 45-second preflight deadline through image inspection, launch, inspection and cleanup; clamp each child to its parent and 15 seconds. Reserve cleanup time within that child budget and refuse an already exhausted deadline before launch.
- Preserve child stderr when inspection/cleanup fails; keep operation errors separately.

## Verification

Regression tests went RED before the fixes for forged INVALID reasons, fabricated compile/runtime projections, missing elapsed fields, historical read-only verification, forged child duration, reservation-clock changes, ownership failures, lost child stderr, INVALID series reasons, schema/producer mismatch and absolute-deadline handoff.

Fresh results after implementation: 37 Python tests pass; synthetic round-trip passes; old Plan 22 and Plan 25 receipt/report verification pass with INVALID unchanged. Host-only compile-smoke on Elixir 1.17.3 / OTP 27.3.4.15 exits 0 with the marker, empty stderr and no ExUnit events. All 14 historical raw JSON/report files match the pre-repair hash snapshot. No Docker, pinned-runtime semantic run, network install or hosted CI measurement was performed. Production code, CI, fixtures, weights and thresholds are unchanged.

Independent review: `247-OFFLINE-REPAIR-REVIEW.md`, clean with zero findings, including the final absolute-deadline change. WR-05/T-247-48 are fixed in source. WR-06's missing fields and cap checks are implemented for future `/2` receipts; historical Plan 25 `/1` timing remains absent. Raw clock consistency does not authenticate physical elapsed time against coherent rewriting of all observations; pinned producer output and independent review hashes are the provenance boundary.

## Remaining scope

Pinned Elixir 1.15.8/OTP 26 semantic readiness remains unobserved after this repair; the host compile is not pinned-runtime evidence. The old reserved paths remain consumed and write-once. Any fresh pinned preflight/series requires a separate bounded grant and new evidence paths. CI-02 still has four qualifying B4 successes/two failed exclusions with median_wall_s=null. CI-03 remains MISS at 1.24/1.28/1.27. Main acceptance remains 2/4; no one may infer a new measurement budget, model/weight change or landing from this offline result.
