---
phase: 221
review: 221-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "A verify-test `matrix.exclude` drops a lane, and no contract notices (name-static, roster, voting lanes)"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "A second workflow can post `CI required` through an expression-valued `name:` (gate-name uniqueness bypass)"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Gate mutation controls share `rule=gate-step` / `rule=gate-name`, so the SHA-pin and own-name/strategy sub-rules are untested"
  - id: WR-04
    severity: warning
    disposition: fixed
    title: "`evaluator_doc_errors/1` is line-local, so any hard-wrapped hex.pm claim passes"
  - id: WR-05
    severity: warning
    disposition: fixed
    title: "ci.yml comment says the browser job's name is \"byte-identical to its pre-split value\", but 221 renamed it"
  - id: WR-06
    severity: warning
    disposition: fixed
    title: "`Dependency audit (all lockfiles)` is pinned as the truthful name, but the job audits only the three Mix lockfiles"
  - id: IN-01
    severity: info
    disposition: fixed
    title: "The `name-verb` rule is a three-word denylist, and two pinned names lead with verbs"
  - id: IN-02
    severity: info
    disposition: fixed
    title: "`required_gate_errors/1` silently skips sibling workflows that do not parse"
  - id: IN-03
    severity: info
    disposition: fixed
    title: "`rule=order-reader` has no mutation control"
  - id: IN-04
    severity: info
    disposition: fixed
    title: "`parsed_job_order/1` and `parsed_job_keywords/1` duplicate the keyword-mode read"
  - id: IN-05
    severity: info
    disposition: fixed
    title: "`time-to-red.py job_id/1` applies the lane-suffix fallback to every name, not just matrix names"
  - id: IN-06
    severity: info
    disposition: fixed
    title: "`time-to-red.py` era-boundary metadata: stale comment, and a RENAME_SHA on a deleted branch"
  - id: IN-07
    severity: info
    disposition: fixed
    title: "`reorder-ci-jobs.py prove` never checks the resulting order, and assumes `jobs:` is the last top-level key"
open: 0
total: 13
recorded: 2026-09-29T15:47:25.967Z
---

# Phase 221: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | 221-REVIEW-FIX.md |
| WR-02 | warning | fixed | 221-REVIEW-FIX.md |
| WR-03 | warning | fixed | 221-REVIEW-FIX.md |
| WR-04 | warning | fixed | 221-REVIEW-FIX.md |
| WR-05 | warning | fixed | 221-REVIEW-FIX.md |
| WR-06 | warning | fixed | 221-REVIEW-FIX.md |
| IN-01 | info | fixed | 221-REVIEW-FIX.md |
| IN-02 | info | fixed | 221-REVIEW-FIX.md |
| IN-03 | info | fixed | 221-REVIEW-FIX.md |
| IN-04 | info | fixed | 221-REVIEW-FIX.md |
| IN-05 | info | fixed | 221-REVIEW-FIX.md |
| IN-06 | info | fixed | 221-REVIEW-FIX.md |
| IN-07 | info | fixed | 221-REVIEW-FIX.md |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
