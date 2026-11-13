---
phase: "253-inclusive-integration-docs-package-and-release-readiness"
plan: "02"
subsystem: "testing"
status: "pending-verification"
requirements-completed: []
requirements-partial: ["ADM-26", "ADM-28", "ADM-31", "ADM-32", "ADM-33"]
actuals: {"tasks": 2, "tokens": null}
completed: null
---

# Plan02 — Current browser entry probes; real zoom pending

Both source tasks are implemented. Existing Retention entry assertions now use Preview retention, then Review and confirm only when a dialog is intended; final Prune now remains inside the dialog. Focus, trap/return, Escape, outside click, required-field, no-write, target-size, reduced-motion and screenshot visibility assertions remain. The scope warning replaces the obsolete run-summary ordering premise, and failed outcomes require unknown count/duration wording rather than a false zero. Screenshot baselines are unchanged.

Six explicitly listed core declarations passed. The selected mobile declaration passed in both project selections at explicitly checked375×900 touch geometry; final source now uses actual taps, no-hover and cancel focus return, passing its measured follow-up. Supplemental native-theme migration covers only the three owners found by source search; native submit/pressed/Selected/CSRF/keyboard/System and persistence purposes replace retired radio/Apply semantics. Source-visible cases remain enabled. The original System strong-border/matcher failures and passing targeted retest are retained.

The actual isolated full-Chromium zoom declaration timed out before its first zoom assertion; diagnostic configurations did not resolve navigation. Exactly two final desktop zoom declarations are collected, not successfully executed. Real zoom remains blocking and is carried into the already-required final candidate CI decision; source/list/static/normal-browser results do not close it. No02 completion or requirement completion is claimed. Commits and actual failed/passing receipt names are in253-EXECUTION.md; current capture/data/source boundaries are in253-PAIR-EVIDENCE.md. No user action is needed while local package and independent reviews continue.

## Task commits

| Task | Commit | Contribution |
| --- | --- | --- |
| 1 | f965dfcb | Current preview/dialog entry and local clipboard setup |
| 2 | 2046ce13 | Current mobile/screenshot entries and outcome wording |
| 2 follow-up | b1be81ce | Current native theme probes; real zoom remains pending |
