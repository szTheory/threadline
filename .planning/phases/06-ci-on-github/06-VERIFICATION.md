---
status: human_needed
phase: "06"
verified_at: 2026-04-23
---

# Phase 6 verification (CI-02 / CI-03)

Automated checks below cover **CI-01** and **CI-03** on this repository revision. **CI-02** (green Actions run for the **same commit** as `origin/main` on GitHub) cannot be closed until these commits are **pushed** and Actions completes successfully — use the maintainer checklist at the bottom.

## Must-haves

| Requirement | Evidence |
|-------------|----------|
| CI-01 | `.github/workflows/ci.yml` contains job keys `verify-format`, `verify-credo`, `verify-test` and `branches: [main]` for `push` and `pull_request` — see greps in `06-01-SUMMARY.md`. |
| CI-02 | **Pending push:** local `main` is ahead of `origin/main`; after `git push origin main`, record a green run for the new HEAD using the § Maintainer checklist below. |
| CI-03 | README `**CI:**` line immediately follows the HexDocs badge row (D-05 Python check); CONTRIBUTING § CI parity documents the three job keys and `https://github.com/szTheory/threadline/actions`. |

## Automated checks

- Plan **06-01** acceptance greps — pass (`06-01-SUMMARY.md`).
- Plan **06-02** README / CONTRIBUTING greps — pass (`06-02-SUMMARY.md`).
- `MIX_ENV=test mix ci.all` — pass (78 tests, 0 failures) on executor revision.

## Human verification

1. **Push and CI-02 close-out:** `git push origin main`, wait for workflow **ci.yml**, confirm **verify-format**, **verify-credo**, and **verify-test** are green on the new `main` HEAD. Paste SHA and run URL into the maintainer sections below.

## Maintainer checklist (CI-02 proof)

The README badge alone is insufficient per `06-CONTEXT` D-11 — record a green run aligned to `origin/main` below.

### origin/main SHA

SHA: (paste output of: `git fetch origin main && git rev-parse origin/main`)

### GitHub Actions run

Workflow file: **ci.yml**. Required jobs (stable keys): **verify-format**, **verify-credo**, **verify-test**.

Paste the run ID or link after confirming all three jobs succeeded on the SHA above.

### gh audit (preferred)

```bash
gh run list --repo szTheory/threadline --workflow=ci.yml --branch=main --limit=5
gh run view RUN_ID --repo szTheory/threadline --json conclusion,headSha,url
```

Replace `RUN_ID` with the ID from the list output for the commit matching `origin/main`.

### Run URL

https://github.com/...

(Paste the Actions run URL from `gh run view` or the GitHub UI.)

## Gaps

- **CI-02 (live):** Unpushed commits — no GitHub run yet for `ebee99f` (local HEAD at verification time). Resolve by pushing and confirming green workflow.
