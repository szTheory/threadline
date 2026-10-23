---
phase: 238
review: 238-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "Caller-selected manifest can bypass source, asset and output validation"
  - id: CR-02
    severity: critical
    disposition: fixed
    title: "New empty-array expansions abort the runner on macOS system Bash"
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "Route aggregation makes individually selected captures fail teardown"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "New runner contract depends on an Apple Silicon Homebrew installation"
open: 0
total: 4
recorded: 2026-10-09T05:03:12.899Z
---

# Phase 238: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | fixed | 238-REVIEW-FIX.md |
| CR-02 | critical | fixed | 238-REVIEW-FIX.md |
| WR-01 | warning | fixed | 238-REVIEW-FIX.md |
| WR-02 | warning | fixed | 238-REVIEW-FIX.md |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
