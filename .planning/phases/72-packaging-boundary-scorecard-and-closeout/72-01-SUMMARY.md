---
phase: 72
plan: "72-01"
subsystem: packaging
tags:
  - pkg-01
  - pkg-02
  - docs
  - release-surface
provides:
  - PKG-01 scorecard definition in the upgrade path guide
  - PKG-02 stay-in-tree closeout decision across README and guides
affects:
  - guides/upgrade-path.md
  - README.md
metrics:
  completed_at: 2026-05-08T14:18:00Z
---

# Plan 72-01 Summary

## What shipped

- Added a new `## Packaging Boundary Scorecard` section to [guides/upgrade-path.md](/Users/jon/projects/threadline/guides/upgrade-path.md).
- Recorded the v1.19 closeout decision as "stay in-tree for now" for the optional operator surface.
- Added a forward-compatibility guarantee that any future split will preserve the public `threadline_operator_surface/2` router integration API.

## Key outcomes

- The package-boundary discussion now uses objective triggers instead of taste or package aesthetics.
- The scorecard names the three explicit extraction pressures: Version Matrix Pressure, Release Cadence Divergence, and Adopter Glue Burden.
- README and upgrade-path wording now align on the current decision: optional surface, optional deps, still in-tree.

## Verification

- `rg -n "Packaging Boundary Scorecard|stay in-tree for now|Version Matrix Pressure|Release Cadence Divergence|Adopter Glue Burden|threadline_operator_surface/2" guides/upgrade-path.md`
- `rg -n "stays in-tree for now|guides/upgrade-path.md" README.md`
