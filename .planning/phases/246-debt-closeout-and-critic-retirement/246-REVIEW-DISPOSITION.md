---
phase: 246
review: 246-REVIEW.md
review_r2: 246-REVIEW-R2.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "Browser-full coverage is misdescribed: the lane renders 6 curated routes at 1280 only, not \"every inventoried route at three viewports\""
  - id: WR-02
    severity: warning
    disposition: open
    title: "The CONTRIBUTING restore pointer names `archive/ui-critic-loop`, which does not exist, and no check verifies it"
  - id: WR-03
    severity: warning
    disposition: open
    title: "The claims about what \"still catches\" the two removed jobs are not pinned; the dominance checks were deleted with nothing to replace them"
  - id: WR-04
    severity: warning
    disposition: open
    title: "The ledger still declares `ratchet_rule` and `ratchet.resets`, but the only test that enforced them was deleted"
  - id: WR-05
    severity: warning
    disposition: open
    title: "The output-root separation guard shrank from four immutable roots to the ledger file alone"
  - id: IN-01
    severity: info
    disposition: open
    title: "Stale \"Tier A\" wording in stress fixtures, including a summary the stress lab displays"
  - id: IN-02
    severity: info
    disposition: fixed
    title: "Browser-full's job name still says \"(all projects)\""
  - id: IN-03
    severity: info
    disposition: open
    title: "The retired-critic guide leak guard checks only two needles"
  - id: IN-04
    severity: info
    disposition: open
    title: "The reference-manifest path-set control now tests only one direction"
  - id: IN-05
    severity: info
    disposition: open
    title: "Leftover e2e dev dependency after `typescript` and `typecheck` were removed"
  - id: R2-WR-01
    severity: warning
    disposition: open
    title: "The derived phrase says \"6 curated operator routes\", but `ROUTES` holds 5 routes plus a degraded twin, and the contract enforces the overcount"
  - id: R2-WR-02
    severity: warning
    disposition: open
    title: "The false-claim denylist misses WR-01's third misstatement and trivial paraphrases; the positive phrase is matched anywhere in the file"
  - id: R2-IN-01
    severity: info
    disposition: open
    title: "The inventory widths in the prose are hand-written, not derived"
  - id: R2-IN-02
    severity: info
    disposition: open
    title: "Missing negative controls for two of the four wording checks"
  - id: R2-IN-03
    severity: info
    disposition: open
    title: "The \"non-vacuous\" test is partly redundant"
  - id: R2-IN-04
    severity: info
    disposition: open
    title: "The `REQUIRED_IDS` pin checks that `UI-HOME-SHOT-101` is present, not that it is routed to SEED-008"
open: 14
total: 16
recorded: 2026-10-26T01:30:58.000Z
---

# Phase 246: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | f57237d6 |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| WR-04 | warning | open | - |
| WR-05 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | fixed | f57237d6 |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |
| R2-WR-01 | warning | open | - |
| R2-WR-02 | warning | open | - |
| R2-IN-01 | info | open | - |
| R2-IN-02 | info | open | - |
| R2-IN-03 | info | open | - |
| R2-IN-04 | info | open | - |

Round 1 ids (WR-01..05, IN-01..05) come from 246-REVIEW.md. Round 2 (246-REVIEW-R2.md, scoped to the 246-08/246-09 gap-closure diff d8b8422f..70bead26) restarts its ids, so its rows carry an R2- prefix. Hand-merged; the gsd-core disposition step was not run.
