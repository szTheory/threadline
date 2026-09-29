# Phase 223 Coverage

No external API integration: the phase hardens release.yml checkouts, the repo-hygiene guard and their contract tests. It releases 0.11.2 through the existing release pipeline. GitHub and hex.pm are touched only by existing CLI and workflow calls; nothing is integrated into the product.

Read-only commands used in verification: `gh pr view`, `gh pr list`, `gh run list`, `gh api` GETs on `actions/runs/<id>/jobs`, `contents/<path>?ref=<sha>` and `pending_deployments`, `gh release view`, and a GET of `https://hex.pm/api/packages/threadline/releases/<version>`.
