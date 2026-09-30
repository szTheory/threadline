---
phase: 220
review: 220-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "A voting lane can be made vacuous with a step `if:` or `|| true`, and `voting_lane_errors/1` does not notice"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "`postgres_image_errors/1` misses registry-prefixed, untagged, digest-pinned and expression-suffixed images"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "A ci.yml job whose id contains an underscore escapes `needs:` coverage"
  - id: WR-04
    severity: warning
    disposition: fixed
    title: "CONTRIBUTING branch-protection list now names three verify-test contexts, but the ruleset requires exactly one"
  - id: IN-01
    severity: info
    disposition: fixed
    title: "The `continue-on-error` and `allowed-failures` regexes miss quoted keys and flow mappings"
  - id: IN-02
    severity: info
    disposition: fixed
    title: "The D-17 assertion on the job's check name is satisfied only by a YAML comment"
  - id: IN-03
    severity: info
    disposition: fixed
    title: "The comment above `verify_test_matrix_errors/3` still describes two rows"
open: 0
total: 7
recorded: 2026-09-28T23:39:31.126Z
---

# Phase 220: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | 220-REVIEW-FIX.md |
| WR-02 | warning | fixed | 220-REVIEW-FIX.md |
| WR-03 | warning | fixed | 220-REVIEW-FIX.md |
| WR-04 | warning | fixed | 220-REVIEW-FIX.md |
| IN-01 | info | fixed | 220-REVIEW-FIX.md |
| IN-02 | info | fixed | 220-REVIEW-FIX.md |
| IN-03 | info | fixed | 220-REVIEW-FIX.md |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
