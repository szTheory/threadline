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
  - id: R3-WR-01
    severity: warning
    disposition: fixed
    title: "Workers stopped at teardown leave non-terminal RetentionRun rows that nobody cleans up"
  - id: R3-WR-02
    severity: warning
    disposition: fixed
    title: "`ratio_of` drops empty partitions, which hides the worst possible imbalance"
  - id: R3-WR-03
    severity: warning
    disposition: fixed
    title: "`--weights` overwrites the committed lane file in the live worktree, with no protection against concurrent runs"
  - id: R3-WR-04
    severity: warning
    disposition: fixed
    title: "The min-lane weights can no longer be reproduced from any documented regeneration path"
  - id: R3-IN-01
    severity: info
    disposition: deferred
    title: "`parse_tsv` accepts TSVs that the runner's strict ingest rejects"
  - id: R3-IN-02
    severity: info
    disposition: deferred
    title: "`replay` does not check which runs it found"
  - id: R3-IN-03
    severity: info
    disposition: fixed
    title: "Dead return values"
  - id: R3-IN-04
    severity: info
    disposition: deferred
    title: "Self-test misses the logic that most needs to match the runner"
  - id: R3-IN-05
    severity: info
    disposition: fixed
    title: "The replay 'spread' leaves out partition boot time, so it is not the quantity CI-03 measures"
  - id: R3-IN-06
    severity: info
    disposition: deferred
    title: "The new test's name claims more than it asserts"
  - id: R3-IN-07
    severity: info
    disposition: deferred
    title: "The test depends on Pruner internals (private lock key and state shape)"
  - id: R4-WR-01
    severity: warning
    disposition: fixed
    title: "The stale-lock break can steal a live lock, and an ownerless lock can never be broken"
  - id: R4-WR-02
    severity: warning
    disposition: fixed
    title: "A partition with its deadline spent keeps claiming, and each claim dies at once with a false `HANG` report"
  - id: R4-WR-03
    severity: warning
    disposition: fixed
    title: "A TERM that arrives during `claim_next` still claims and starts a new BEAM after the stop"
  - id: R4-IN-01
    severity: info
    disposition: open
    title: "A non-strict `--ingest-weights --lane min` writes the current lane's file using the min lane's rule"
  - id: R4-IN-02
    severity: info
    disposition: open
    title: "The async test is duplicated as a literal, though the comment says it is shared"
  - id: R4-IN-03
    severity: info
    disposition: open
    title: "The counts table silently undercounts when one invocation's summary does not parse"
  - id: R4-IN-04
    severity: info
    disposition: open
    title: "Under the lock, `tail-queue.next` falls back to 1 on empty or garbled content"
  - id: R4-IN-05
    severity: info
    disposition: open
    title: "The self-test does not exercise the lock paths that R4-WR-01 and R4-WR-03 break"
  - id: R4-IN-06
    severity: info
    disposition: open
    title: "`min_balance.py predict --lane current` still models the greedy sets, and it inherits the caller's environment"
  - id: R4-IN-07
    severity: info
    disposition: open
    title: "`preflight` leaves claim exits and per-seq uniqueness to the run conclusion"
  - id: R4-IN-08
    severity: info
    disposition: deferred
    title: "Sibling cross-clock `as_of/4` call sites remain (known, deferred)"
open: 11
total: 34
recorded: 2026-10-28T00:00:00Z
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
| R3-WR-01 | warning | fixed | 247-29 5b3e5ab8; both retention modules delete RetentionRun rows in an on_exit registered in setup, after the test-owned Pruner and workers stop. |
| R3-WR-02 | warning | fixed | 247-29 5b3e5ab8; ratio_of fails closed on an empty or non-positive-cost partition, with self-test cases. |
| R3-WR-03 | warning | fixed | 247-29 5b3e5ab8; placed() removed; predict and replay run the runner in a temporary copy and never write the live lane file. |
| R3-WR-04 | warning | fixed | 247-29 e9bb16ca + f27d11b9; lane_rule() and --rule in bin/ci-test-partitions (strict mismatch exits 2), self-test and contract mutant, CONTRIBUTING sentence; strict min ingest of the B4 training runs is byte-identical to the committed min weights. |
| R3-IN-01 | info | deferred | Deferred: replay inputs come from the hash-pinned fetch; the phase-local tool is not a CI gate. |
| R3-IN-02 | info | deferred | Deferred: the replay roots used in this phase are fetch outputs with pinned run ids; the phase-local tool is not a CI gate. |
| R3-IN-03 | info | fixed | 247-29 5b3e5ab8; strict_ingest_copy's inventory return and load_run's partition_wall_ms removed. |
| R3-IN-04 | info | deferred | Deferred: predict cross-checks every effective weight against the runner; the remaining table-driven cases are outside D-28. |
| R3-IN-05 | info | fixed | 247-32 b25c3c29; tools/tail_queue_replay.py adds the run's boot_ms (lower middle of the four headers) to every partition time (P3). |
| R3-IN-06 | info | deferred | Deferred: the test-name note is outside D-28; the lifetime bound comes from start_supervised! semantics. |
| R3-IN-07 | info | deferred | Deferred: the Pruner-coupling note is outside D-28; a changed state shape fails loudly. |
| R4-WR-01 | warning | fixed | Fixed in 4e91b3fb (247-REVIEW-FIX.md); regression case added to `bin/ci-test-partitions --self-test`. |
| R4-WR-02 | warning | fixed | Fixed in 8d4ff4b5 (247-REVIEW-FIX.md); regression case added to `bin/ci-test-partitions --self-test`. |
| R4-WR-03 | warning | fixed | Fixed in 100fc074 (247-REVIEW-FIX.md); regression case added to `bin/ci-test-partitions --self-test`. |
| R4-IN-01 | info | open | Round 4 incremental review (plans 29-37) in 247-REVIEW.md; open, not yet triaged. Fail-closed by construction: no path turns a skipped file green. |
| R4-IN-02 | info | open | Round 4 incremental review (plans 29-37) in 247-REVIEW.md; open, not yet triaged. Fail-closed by construction: no path turns a skipped file green. |
| R4-IN-03 | info | open | Round 4 incremental review (plans 29-37) in 247-REVIEW.md; open, not yet triaged. Fail-closed by construction: no path turns a skipped file green. |
| R4-IN-04 | info | open | Round 4 incremental review (plans 29-37) in 247-REVIEW.md; open, not yet triaged. Fail-closed by construction: no path turns a skipped file green. |
| R4-IN-05 | info | open | Round 4 incremental review (plans 29-37) in 247-REVIEW.md; open, not yet triaged. Fail-closed by construction: no path turns a skipped file green. |
| R4-IN-06 | info | open | Round 4 incremental review (plans 29-37) in 247-REVIEW.md; open, not yet triaged. Fail-closed by construction: no path turns a skipped file green. |
| R4-IN-07 | info | open | Round 4 incremental review (plans 29-37) in 247-REVIEW.md; open, not yet triaged. Fail-closed by construction: no path turns a skipped file green. |
| R4-IN-08 | info | deferred | Deferred: already logged by 247-31 in deferred-items.md (sibling cross-clock as_of call sites); none failed in B6. |

WR-01 retains its inherited deferred identity. Fixed findings remain here as history. D-26 (Plan 26) closed CR-05 by descoping (no canary ran and no canary tool changed; the terminal INVALID preflight and historical receipts are unchanged), and Plan 29 dispositioned every round 3 finding, so WR-04 is the only open finding. Plan 32 closed R3-IN-05 with the boot-inclusive tail-queue replay. The current B5 standing is unchanged by these fixes: CI-02 PASS, CI-03 MISS on the current lane, and Phase 247 at 3/4. No weight file, lane inventory or threshold changed in Plan 29.

Note: 247-REVIEW.md now holds round 3 (plans 26–28). Rows without the R3- prefix cite earlier rounds, whose report is preserved in git at 4f9f1e1c.

D-32 round landing status (Plan 37, path S, success). The R3-WR-01..04 and R3-IN-03 fixes and the row_key_read clock fix are on main at the B6 squash 11234b01 (PR #99). The squash contains these source commits, cherry-picked onto the land branch per the pick map in 247-LANDING.md: 5b3e5ab8 (R3-WR-01..03 and R3-IN-03), e9bb16ca and f27d11b9 (R3-WR-04), and 29636579 and eae71898 (the row_key_read clock). Before B6 they lived only on milestone/v1.47. Dispositions are unchanged: WR-04 is still the only open finding, and the frontmatter counts stay at open 1 and total 23.

Round 4 (2026-10-28, plans 29-37, diff vs 2f0148e0): 3 warnings and 8 info, no critical findings. All are recorded above with R4- ids, because round ids restart each round. R4-WR-01..03 are claim-path races in the tail-queue lock and signal handling of bin/ci-test-partitions (already on main at 11234b01). Each one can turn a run red for the wrong reason or misreport why it went red, but none can make a skipped file pass. B6 measured all 15 lane runs with every claim exit 0. They were fixed on 2026-10-28 by `/gsd-code-review 247 --fix` (4e91b3fb, 8d4ff4b5, 100fc074; see 247-REVIEW-FIX.md), each with a self-test case. R4-IN-08 is deferred as an already-logged item.
