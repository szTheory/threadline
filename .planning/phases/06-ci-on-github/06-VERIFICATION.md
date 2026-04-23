---
status: pending
phase: "06"
verified_at: null
---

# Phase 6 verification (CI-02 / CI-03)

Maintainer checklist for **CI-02** (Actions proof) and **CI-03** (discovery). The README badge alone is insufficient per `06-CONTEXT` D-11 — record a green run aligned to `origin/main` below.

## origin/main SHA

SHA: (paste output of: git fetch origin main && git rev-parse origin/main)

## GitHub Actions run

Workflow file: **ci.yml**. Required jobs (stable keys): **verify-format**, **verify-credo**, **verify-test**.

Paste the run ID or link after confirming all three jobs succeeded on the SHA above.

## gh audit (preferred)

```bash
gh run list --repo szTheory/threadline --workflow=ci.yml --branch=main --limit=5
gh run view RUN_ID --repo szTheory/threadline --json conclusion,headSha,url
```

Replace `RUN_ID` with the ID from the list output for the commit matching `origin/main`.

## Run URL

https://github.com/...

(Paste the Actions run URL from `gh run view` or the GitHub UI.)
