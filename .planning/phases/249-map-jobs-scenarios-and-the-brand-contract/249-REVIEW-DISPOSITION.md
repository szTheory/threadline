---
phase: 249
review: 249-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "Scenario class changes bypass class-specific validation"
  - id: WR-02
    severity: warning
    disposition: open
    title: "Reference identity checks miss blank and duplicate brand-role IDs"
  - id: WR-03
    severity: warning
    disposition: open
    title: "Focused contract test reads planning files that normal cleanup moves"
open: 3
total: 3
recorded: 2026-11-12T05:50:48.410Z
---

# Phase 249: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
