---
phase: 217
review: 217-REVIEW.md (round 2 re-review; round 1 is 217-REVIEW.md at b09da7dc)
titles: json
findings:
  - id: R1-CR-01
    severity: critical
    disposition: fixed
    title: "Family-6 \"Claude-encoded project dir\" regex misses a real, plausible path shape (false negative)"
  - id: R1-WR-01
    severity: warning
    disposition: fixed
    title: "Summary line's `(.planning/ absent)` label is printed unconditionally, even when `.planning/` is present"
  - id: R1-WR-02
    severity: warning
    disposition: fixed
    title: "Colon-containing filenames defeat `git grep` line parsing in both the tree scan and the matcher"
  - id: R1-WR-03
    severity: warning
    disposition: fixed
    title: "The allowlist \"never a person's home directory\" safety-net test only checks 2 of 7 pattern families"
  - id: R1-IN-01
    severity: info
    disposition: fixed
    title: "Documented \"missing git\" exit-2 case has no explicit check and reports the wrong reason"
  - id: R2-WR-01
    severity: warning
    disposition: open
    title: "`forbidden_home_literal?/1` passes ancestor-prefix literals that blanket-cover every home directory"
  - id: R2-WR-02
    severity: warning
    disposition: open
    title: "Widened family-6 regex has no left boundary and flags ordinary TitleCase kebab words"
  - id: R2-WR-03
    severity: warning
    disposition: open
    title: "A newline in a tracked filename still mis-scopes the hit, and a phantom scope can cover it"
  - id: R2-WR-04
    severity: warning
    disposition: open
    title: "CONTRIBUTING claims every Claude-encoded project path is a HIT, but Linux-encoded dirs are not detected"
  - id: R2-IN-01
    severity: info
    disposition: open
    title: "The contract test for the failure hint passes even if the hint is deleted"
  - id: R2-IN-02
    severity: info
    disposition: open
    title: "\"No file or directory is exempt from the scan\" contradicts the allowlist self-exclusion"
open: 6
total: 11
recorded: 2026-09-27T19:00:38.181Z
---

# Phase 217: Code Review Disposition

Round 1 (`R1-*`) is the original review, whose findings were all fixed by gap closure 217-06/217-07. Round 2 (`R2-*`) is the incremental re-review of those fixes; its ids restart at 01 in 217-REVIEW.md, hence the prefixes.

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| R1-CR-01 | critical | fixed | 217-06 Task 1 09817a77 |
| R1-WR-01 | warning | fixed | 217-06 Task 2 ec5cdc2c |
| R1-WR-02 | warning | fixed | 217-07 Task 2 74279a7c |
| R1-WR-03 | warning | fixed | 217-06 Task 2 ec5cdc2c |
| R1-IN-01 | info | fixed | 217-06 Task 2 ec5cdc2c |
| R2-WR-01 | warning | open | 217-REVIEW.md round 2 |
| R2-WR-02 | warning | open | 217-REVIEW.md round 2 |
| R2-WR-03 | warning | open | 217-REVIEW.md round 2 |
| R2-WR-04 | warning | open | 217-REVIEW.md round 2 |
| R2-IN-01 | info | open | 217-REVIEW.md round 2 |
| R2-IN-02 | info | open | 217-REVIEW.md round 2 |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
