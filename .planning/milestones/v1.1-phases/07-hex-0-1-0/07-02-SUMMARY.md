---
phase: 07-hex-0-1-0
plan: "02"
subsystem: release
tags: [hex, git, tag, publish]

requires:
  - phase: "07-01"
    provides: "Release-ready tree (HEX-01, HEX-02) on commit to tag"
provides:
  - "Annotated tag v0.1.0 on release commit, pushed to origin (HEX-03)"
  - "threadline 0.1.0 published and visible on Hex (HEX-04)"

tech-stack:
  added: []
  patterns:
    - "Tag peel SHA must match origin/main at close-out when release and tip align."

key-files:
  created:
    - .planning/phases/07-hex-0-1-0/07-02-SUMMARY.md
  modified: []

key-decisions:
  - "Recorded CI-02-aligned HEAD and Hex registry proof in this summary; no secrets in repo."

requirements-completed:
  - HEX-03
  - HEX-04

duration: 20min
completed: 2026-04-23
---

# Phase 7 Plan 02: Tag, push, and publish — summary

**Release commit `7c082551b4541556a54cb817b0e6b0dbb374f51b` carries `0.1.0`; annotated `v0.1.0` is on `origin`; Hex lists `0.1.0`.**

## Performance

- **Duration:** ~20 min (maintainer Git + Hex)
- **Completed:** 2026-04-23

## Pre-flight (Task 1)

- `git status --porcelain`: clean aside from intentionally untracked local tooling paths (no edits pending for release files).
- `grep -F '@version "0.1.0"' mix.exs` — pass.
- Dated `## [0.1.0] - YYYY-MM-DD` header in `CHANGELOG.md` — pass (see `07-01-SUMMARY.md`).

**Release commit:** `7c082551b4541556a54cb817b0e6b0dbb374f51b` (`git rev-parse HEAD` at verification; matches `git rev-parse origin/main` after `git fetch origin`).

## HEX-03 — Tag and push

- **Tag type:** `git cat-file -t v0.1.0` → `tag` (annotated).
- **Tag peel:** `git rev-parse v0.1.0^{commit}` → `7c082551b4541556a54cb817b0e6b0dbb374f51b`.
- **Remote:** `git ls-remote origin refs/tags/v0.1.0` — non-empty (`refs/tags/v0.1.0` present on `https://github.com/szTheory/threadline.git`).
- **Order:** `main` and tag pushed per `07-CONTEXT` (no `--force` on refs).

## HEX-04 — Publish and registry proof

- **`mix hex.publish`:** completed in maintainer environment (credentials not recorded).
- **Registry proof:** `mix hex.info threadline` shows **`Releases: 0.1.0`** and changelog link `…/blob/v0.1.0/CHANGELOG.md` (run 2026-04-23).

## Self-check

- [x] HEAD SHA documented and matches tag peel / `origin/main` at close-out.
- [x] HEX-03 satisfied (annotated tag + on `origin`).
- [x] HEX-04 satisfied (registry lists 0.1.0).
- [x] No `HEX_API_KEY` or other secrets in this file.

## Next

- Milestone close-out: `/gsd-audit-milestone` (refresh) then `/gsd-complete-milestone v1.1` when ready.
