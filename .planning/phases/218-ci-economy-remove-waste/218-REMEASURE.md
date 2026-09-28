# Phase 218: CI Re-measurement After the Economy Cuts (ECON-07)

This record measures what CI costs after ECON-01 through ECON-06 landed, and states each change against the phase 214 baseline (BASE-01, `.planning/phases/214-baseline-measurement/214-BASELINE.md`).

## 0. Method

- Approach (D-11): cited dispatch runs of the pushed code, plus cadence arithmetic. No weekly or nightly scheduled sample is waited for.
- Tools: the phase 214 collector, summarizer and citation checker, copied into this phase's `tools/` directory so that post-change runs never land in the phase 214 evidence. The copies differ from the originals only in their self-path strings and in the checker's phase-number exemption, which accepts phases 214 through 218.
- Raw data: this phase's own `raw/ci/manifest.json` and `raw/ci/runs/`, written by `bash .planning/phases/218-ci-economy-remove-waste/tools/collect-ci-runs.sh`.
- Baseline: every delta quotes the 214-BASELINE figure and the run IDs behind it.
- Citation rule: every per-run figure cites a run ID or the backticked command that printed it, checked by `python3 .planning/phases/218-ci-economy-remove-waste/tools/check-citations.py`.
- Projections: every monthly figure is `measured run × cadence`, is labeled [inference], and cites the measured run it multiplies.

## 1. Samples

Pending: filled after the post-landing runs.

## 2. Runner-minutes per ci.yml run

Pending: filled after the post-landing runs.

## 3. Wall clock and critical path

Pending: filled after the post-landing runs.

## 4. Per-job attribution

Pending: filled after the post-landing runs.

## 5. Flake Detection

Pending: filled after the post-landing runs.

## 6. Browser-full

Pending: filled after the post-landing runs.

## 7. Tracking issues and release PR

Pending: filled after the post-landing runs.

## 8. Live Dialyzer in verify-dialyzer

Pending: filled after the post-landing runs.

## 9. Summary of deltas

Pending: filled after the post-landing runs.
