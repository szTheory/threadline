---
phase: 247
review: 247-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: deferred
    title: "Playwright list parsing is ambiguous when a title contains the separator (pre-existing; WARNING)"
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "Signed monotonic timestamps make the canary reject valid event records — FIXED"
  - id: CR-02
    severity: critical
    disposition: fixed
    title: "Registration trace events can be lost when the collector is terminated — FIXED"
  - id: CR-03
    severity: critical
    disposition: fixed
    title: "Replay hashes cache artifacts but does not verify them against expected digests — FIXED WITH EVIDENCE LIMIT"
  - id: CR-04
    severity: critical
    disposition: fixed
    title: "Registration events are timestamped during the post-suite drain — FIXED"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "Parser exceptions overwrite the child's captured stderr — FIXED"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Canary verification does not validate its historical producer hash — FIXED"
  - id: IN-01
    severity: info
    disposition: fixed
    title: "Trace-only invocation reports an unused mode variable — FIXED"
  - id: CR-05
    severity: critical
    disposition: closed-by-descoping
    title: "Pinned ARM64 canary semantic result — CLOSED BY DESCOPING (D-26)"
  - id: WR-04
    severity: warning
    disposition: open
    title: "Plan 22 preflight and arm receipts lack historical owned-container identity"
  - id: WR-05
    severity: warning
    disposition: fixed
    title: "INVALID preflight verification accepts an unsubstantiated reason and compile result"
  - id: WR-06
    severity: warning
    disposition: fixed
    title: "Recheck preflight receipts cannot establish the elapsed-time cap"
open: 1
total: 12
recorded: 2026-10-27T17:33:15Z
---

# Phase 247: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | deferred | Same inherited separator ambiguity; prior deferral reaffirmed; current journey inventory unaffected. |
| CR-01 | critical | fixed | Independent re-review in 247-REVIEW.md; 94c1733f |
| CR-02 | critical | fixed | Independent re-review in 247-REVIEW.md; f5f06c48 + e66cad9a |
| CR-03 | critical | fixed | Independent re-review in 247-REVIEW.md; 301369ce; B3/B4 upstream-authenticity limit retained |
| CR-04 | critical | fixed | Independent re-review in 247-REVIEW.md; e66cad9a |
| WR-02 | warning | fixed | Independent re-review in 247-REVIEW.md; 94c1733f |
| WR-03 | warning | fixed | Independent re-review in 247-REVIEW.md; 94c1733f |
| IN-01 | info | fixed | Independent re-review in 247-REVIEW.md; e66cad9a |
| CR-05 | critical | closed-by-descoping | D-26 (maintainer, 2026-10-27) drops the diagnostic canary from phase acceptance; the consumed grant is not renewed; the historical INVALID receipts stay unchanged. |
| WR-04 | warning | open | Plan 22's immutable preflight/arm evidence retains the historical identity gap. Plan 25's sole child has a matching owned name/CID and successful CID-only cleanup; this does not rewrite the historical record. |
| WR-05 | warning | fixed | 8c9f1541; raw-derived VALID/INVALID reasons, compiler/runtime projections and ownership evidence; 37 tests and clean independent offline review. |
| WR-06 | warning | fixed | 8c9f1541; new /2 start/end/elapsed/limit, reserved start binding and absolute shared deadlines; legacy Plan 25 timing remains absent, with authenticated-time provenance limits disclosed. |

WR-01 retains its inherited deferred identity. Fixed findings remain here as history. The current incremental review counts after offline repairs are 1 critical, 2 warnings (including deferred WR-01), and 0 info. The terminal INVALID preflight, historical receipts, and main acceptance states are unchanged. CI-02 remains INCOMPLETE, CI-03 remains MISS, and Phase 247 remains 2/4.
D-26 (Plan 26) later closed CR-05 by descoping, so WR-04 is the only open finding; no canary ran and no canary tool changed.
