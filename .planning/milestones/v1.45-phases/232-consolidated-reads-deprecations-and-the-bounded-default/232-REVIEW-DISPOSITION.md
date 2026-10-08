---
phase: 232
review: 232-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "`next-page` in actor_live.ex sets `prev_cursor` to a value that causes duplicate re-fetch on scroll-up"
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "`RowReads.list/3`'s explicit `limit: n` path silently returns fewer rows than `n` with no truncation signal, by design"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "`row_history_scope_opts/3`'s shared `:surface` default between the bounded and deprecated-unbounded read paths"
  - id: IN-01
    severity: info
    disposition: skipped
    title: "`Investigation.row_history_page/4`'s doc caveat is not cross-linked across its `_page` siblings"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Deprecated row_history/4 documentation reverses legacy filter precedence"
open: 0
total: 5
recorded: 2026-10-07T12:56:46.326Z
---

# Phase 232: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | fixed | 232-REVIEW-FIX.md (not in the current review) |
| WR-01 | warning | fixed | 232-REVIEW-FIX.md (not in the current review) |
| WR-02 | warning | fixed | 232-REVIEW-FIX.md (not in the current review) |
| IN-01 | info | skipped | 232-REVIEW-FIX.md (not in the current review) |
| WR-03 | warning | fixed | 232-REVIEW-FIX.md (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
