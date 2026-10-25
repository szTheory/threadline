# Phase 244 deferred items

## From 244-01

- `bin/verify-repo-hygiene` reports two HITs in `.planning/phases/244-release-flow/244-RESEARCH.md:129`
  (a home-relative Mix archives path spelled out in prose). The file predates 244-01 (committed at
  cefab76b by the planner) and is outside this plan's scope, so it was not edited. Rewrite the path as a
  placeholder shape (for example `<home>/.mix/archives`) before running `mix ci.all` locally; the guard
  scans tracked `.planning/` files.
