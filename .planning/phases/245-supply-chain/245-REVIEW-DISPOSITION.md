---
phase: 245
review: 245-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "A renamed Hex dependency (`hex:` option) is mis-tiered as non-blocking (latent fail-open)"
  - id: WR-02
    severity: warning
    disposition: open
    title: "The live-tree closure contract re-implements the parser, so the bash parser that decides blocking is never run against real `deps.tree` output offline"
  - id: WR-03
    severity: warning
    disposition: open
    title: "The D-29 doc contract \"class set CONTRIBUTING names equals RANK_NAMES\" only checks a subset"
  - id: IN-01
    severity: info
    disposition: open
    title: "Tab-IFS `read` collapses an empty id field and shifts the message into `id`"
  - id: IN-02
    severity: info
    disposition: open
    title: "CONTRIBUTING says a failing `deps.tree` is blocking \"in all three directories\""
  - id: IN-03
    severity: info
    disposition: open
    title: "The `verify-action-pins` repo check accepts `.` and `..` as the repo segment"
  - id: IN-04
    severity: info
    disposition: open
    title: "An annotated tag that points at another tag reports a misleading MISMATCH"
  - id: IN-05
    severity: info
    disposition: open
    title: "The NODE-FILE rule does not cover composite actions"
  - id: IN-06
    severity: info
    disposition: open
    title: "The \"flags a quoted ref\" runtime control no longer tests Node 20 detection for quoted refs"
  - id: IN-07
    severity: info
    disposition: open
    title: "Report truncation can split a multibyte character or an open code fence"
open: 10
total: 10
recorded: 2026-10-25T20:47:26.848Z
---

# Phase 245: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |
| IN-06 | info | open | - |
| IN-07 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
