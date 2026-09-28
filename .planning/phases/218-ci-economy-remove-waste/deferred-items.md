# Phase 218 deferred items

## From 218-04

- **CONTRIBUTING.md `## Branch protection (maintainers)` still lists six per-job checks under "require these checks on `main`".** Plan 218-04 removed only the `verify-docs` and `verify-hex-package` lines and added the sentence saying the only required status check is `CI required`. The surviving list (format, credo, the two test lanes, pgbouncer topology, release shape) now reads as contradicting that sentence: live protection and `.github/rulesets/main.json` require only `CI required`. Rewriting the list is out of 218-04's scope. It is a doc-truth fix for a later plan (candidate: Phase 221, which owns CI names and legibility).
