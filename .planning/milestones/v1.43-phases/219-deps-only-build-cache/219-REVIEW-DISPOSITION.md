---
phase: 219
review: 219-REVIEW.md (round 1)
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "The contract validates only the first `_build` restore and first save window; a later restore with `restore-keys`, or a save after the first-party compile, passes"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "A step-level `MIX_ENV` override inside a cached block passes the contract"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "The poisoned-cache runbook's durable fix turns the contract red, and the runbook does not say so"
  - id: IN-01
    severity: info
    disposition: fixed
    title: "The CHANGELOG Unreleased entry now contradicts itself about the scope of the security fix"
  - id: IN-02
    severity: info
    disposition: fixed
    title: "`remeasure-219.py critical-path` crashes on a run with no successful voting job"
  - id: IN-03
    severity: info
    disposition: fixed
    title: "The `verify-test` save and compile guards accept a form with no lane guard, which would break the min lane"
  - id: IN-04
    severity: info
    disposition: fixed
    title: "The root removal step interpolates `${{ }}` directly into `run:`, unlike the example step"
---

# Phase 219 — Review disposition

All seven findings are fixed. `219-REVIEW-FIX.md` lists them: commits de860adc, f49ac4c2, c4d966a0, f54a5570, 344678b6, 58d78d3b and fbd5a461 on milestone/v1.43. WR-01 and WR-02 were fixed test-first: new mutation controls failed on the old contract and pass on the tightened one.

## Landing

- Six of the fixes were cherry-picked onto `land/v1.43-217-218` (PR #60), and CI run 36465241600 passed with every job green.
- IN-01 was not cherry-picked. It merges two `mint` bullets that exist only on milestone/v1.43's undated Unreleased section. On the land branch, the 1.10.1 advisory already shipped in the dated 0.11.1 section, and the Unreleased entry correctly names only the three advisories that 1.11.0 clears.

## Local gate note

- On milestone/v1.43 after the fixes, `mix ci.all` passed every step up to `verify.test`, which ran 2503 tests with 0 failures.
- It then stopped at `verify.example` with `FATAL 53300 too_many_connections`. That was environmental: another project's live test run held 78 of the 100 local Postgres connections. A retry of the remaining steps hit the same limit.
- The CI run on the same code, 36465241600, covers those steps: `verify.example`, Dialyzer, the browser lane and every other job.
- The fixer saw one unidentified failure on its first `mix verify.test` run and did not capture which test failed. The next three full runs, including the `ci.all` run above, had 0 failures.
