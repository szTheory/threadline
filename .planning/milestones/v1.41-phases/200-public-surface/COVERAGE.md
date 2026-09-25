# Phase 200 — External API Coverage Declaration

No external API integration: this phase changes only published documentation
(`@moduledoc`/`@doc` prose and module visibility), ExDoc configuration in
`mix.exs`, guide and README cross-links, and the `.github/` contributor
directory. No HTTP client, SDK dependency, request/response contract, or
error-taxonomy surface is introduced, so there is nothing for a coverage matrix
to enumerate.

_Detector: `api-coverage.verify-pre` returned `detected: true` on a single
`(surface)`/`api` signal. That signal is the ExDoc **group name** `Core API`
(D-11's six-group module grouping, see `200-CONTEXT.md`) — a documentation
navigation heading, not a service integration. The one other "API" mention in
the phase, `200-14-SUMMARY.md`'s "the GitHub API both resolved to …", describes
`gh` used read-only as a measurement instrument for CI state, the same carve-out
recorded in `.planning/phases/198-green-bringup/COVERAGE.md`._
