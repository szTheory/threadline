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
    disposition: open
    title: "`RowReads.list/3`'s explicit `limit: n` path silently returns fewer than `n` rows with no truncation signal, by design — but this is easy to misread as a bug fix target"
  - id: WR-02
    severity: warning
    disposition: open
    title: "`Threadline.Query.row_history_scope_opts/3`'s `:surface` default of `:row_history` is shared between the bounded (`row_history/3`) and unbounded-legacy (`history/3`, deprecated `row_history/4`) read paths"
  - id: IN-01
    severity: info
    disposition: open
    title: "`Threadline.Investigation.row_history_page/4`'s doc references the retired `cursor: nil` first-page convention without flagging that it diverges from every other paged read in the same module"
open: 3
total: 4
recorded: 2026-10-03T21:50:00.551Z
---

# Phase 232: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | fixed | 232-REVIEW-FIX.md |
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| IN-01 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
