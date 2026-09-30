---
phase: 222
review: 222-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "check-citations.py's widened phase-number exemption can mask a real uncited figure equal to 220/221/222"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "`since-214` window header truncates the sub-day lower bound to a whole day, making the printed range look one day wider than it is"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Dead/redundant check in `run_out_contains` — the exact-line match can never change the outcome"
  - id: IN-01
    severity: info
    disposition: fixed
    title: "`verify-phase.sh`'s per-window determinism loop and citation self-tests are the only automated coverage for the new `--last N` and `at-214`/`since-214` windows; no test exercises a boundary PR merged in the same second as the `at-214` cutoff"
open: 0
total: 4
recorded: 2026-09-29T20:04:06.421Z
---

# Phase 222: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | 222-REVIEW-FIX.md |
| WR-02 | warning | fixed | 222-REVIEW-FIX.md |
| WR-03 | warning | fixed | 222-REVIEW-FIX.md |
| IN-01 | info | fixed | 222-REVIEW-FIX.md |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
