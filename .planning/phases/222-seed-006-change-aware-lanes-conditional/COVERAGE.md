# Phase 222 Coverage

No external API integration: phase only reads GitHub PR/run metadata via the gh CLI for a planning measurement; no product integration.

Read-only commands used: `gh pr list`, `gh api pulls/<n>/files`, `gh run list`, `gh api actions/runs/<id>/jobs`.
