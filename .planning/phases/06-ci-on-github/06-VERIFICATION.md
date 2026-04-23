---
status: passed
phase: "06"
verified_at: 2026-04-23
---

# Phase 6 verification (CI-02 / CI-03)

Automated checks below cover **CI-01** and **CI-03** on this repository revision. **CI-02** (green Actions run for the **same commit** as `origin/main` on GitHub) was closed in **Phase 8** with the maintainer evidence recorded below.

## Must-haves

| Requirement | Evidence |
|-------------|----------|
| CI-01 | `.github/workflows/ci.yml` contains job keys `verify-format`, `verify-credo`, `verify-test` and `branches: [main]` for `push` and `pull_request` — see greps in `06-01-SUMMARY.md`. |
| CI-02 | Green **ci.yml** workflow run on `origin/main` HEAD — SHA and run URL below match `gh run view` audit. |
| CI-03 | README `**CI:**` line immediately follows the HexDocs badge row (D-05 Python check); CONTRIBUTING § CI parity documents the three job keys and `https://github.com/szTheory/threadline/actions`. |

## Automated checks

- Plan **06-01** acceptance greps — pass (`06-01-SUMMARY.md`).
- Plan **06-02** README / CONTRIBUTING greps — pass (`06-02-SUMMARY.md`).
- `MIX_ENV=test mix ci.all` — pass on maintainer machine and on GitHub Actions for documented SHA.

## Human verification

1. **Push and CI-02 close-out:** Completed in Phase 8 — `main` pushed; workflow **ci.yml** green on `origin/main` HEAD; SHA and run URL recorded in maintainer sections below.

## Maintainer checklist (CI-02 proof)

The README badge alone is insufficient per `06-CONTEXT` D-11 — record a green run aligned to `origin/main` below.

### origin/main SHA

SHA: `7c082551b4541556a54cb817b0e6b0dbb374f51b`  
(output of: `git fetch origin && git rev-parse origin/main` on 2026-04-23)

### GitHub Actions run

Workflow file: **ci.yml**. Required jobs (stable keys): **verify-format**, **verify-credo**, **verify-test**.

Run ID **24847404664** — all three jobs **success** for the SHA above.

### gh audit (preferred)

```bash
gh run list --repo szTheory/threadline --workflow=ci.yml --branch=main --limit=5
gh run view RUN_ID --repo szTheory/threadline --json conclusion,headSha,url
```

Replace `RUN_ID` with **24847404664** for the green run recorded below (or the latest run whose `headSha` matches `git rev-parse origin/main`).

`gh run view 24847404664 --repo szTheory/threadline --json conclusion,headSha,url` → `conclusion`: `success`, `headSha`: matches the SHA documented above for current `origin/main`.

### Run URL

https://github.com/szTheory/threadline/actions/runs/24847404664

*If `origin/main` has advanced past the SHA above, list recent workflow runs and use the latest `success` run whose `headSha` matches `git rev-parse origin/main`.*

## Gaps

- **CI-02 (live):** Resolved — green run **24847404664** on SHA `7c082551b4541556a54cb817b0e6b0dbb374f51b` (post–Phase 8 tip; includes release hygiene commits through `fix(ci): avoid pipefail SIGPIPE…`).
