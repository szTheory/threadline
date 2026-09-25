# Phase 198 — External API Coverage Declaration

No external API integration: this phase changes only CI workflow configuration, a
static source-sweep test, and planning records — the only API touched is GitHub's
own REST API, read-only via the `gh` CLI (`gh run view`, `gh pr checks`,
`bin/verify-branch-protection`) as a measurement instrument for CI state, not as a
product integration surface, so there is no request/response contract, no client
code, and no error-taxonomy matrix for this phase to specify.

_Detector: `api-coverage.cjs --json` returned `detected: true` on a single signal —
the string "local shell → GitHub API (`gh`)" inside an existing plan's threat model.
That signal is the measurement tooling described above, not an integration._
