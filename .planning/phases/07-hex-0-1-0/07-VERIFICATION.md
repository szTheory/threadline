---
status: passed
phase: "07"
verified_at: 2026-04-23
---

# Phase 7 verification — Hex 0.1.0

## Goal (from ROADMAP)

Version, changelog, tag, and Hex publish align for `threadline` **0.1.0** (HEX-01 — HEX-04).

## Requirement traceability

| ID | Evidence |
|----|----------|
| HEX-01 | `mix.exs` line `@version "0.1.0"` — see `07-01-SUMMARY.md` Task 1–2 greps. |
| HEX-02 | `CHANGELOG.md` dated `## [0.1.0] - 2026-04-23` with release notes — `07-01-SUMMARY.md`. |
| HEX-03 | Annotated tag `v0.1.0` on release commit `7c082551b4541556a54cb817b0e6b0dbb374f51b`; `git ls-remote origin refs/tags/v0.1.0` non-empty — `07-02-SUMMARY.md`. |
| HEX-04 | `mix hex.info threadline` lists **`Releases: 0.1.0`** — `07-02-SUMMARY.md`. |

## Automated / scripted checks

- `grep -F '@version "0.1.0"' mix.exs` — pass.
- `grep -E '^## \\[0\\.1\\.0\\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$' CHANGELOG.md` — pass.
- `git cat-file -t v0.1.0` → `tag`.
- `mix hex.info threadline` output contains **`0.1.0`** in the Releases line — pass.

## Human verification

Tag creation, `git push` of `main` / `v0.1.0`, and `mix hex.publish` executed by maintainer with local credentials (not stored in-repo).

## Gaps

None identified at verification time.
