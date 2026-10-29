# Plan 247-22 local validation scope decision

Decision: authorize-one-local-series
Date: 2026-10-27T15:29:56+00:00
Source: explicit maintainer answer `1` to the presented two-option checkpoint; option 1 was `authorize-one-local-series`.

Authorize one fresh native ARM64 local Docker/ExUnit semantic validation series, using the already cached image and committed producer, runner and formatter. Scope: one metadata/runtime preflight, at most two warmups, three alternating A/B pairs in A/B, B/A, A/B order and two controls, 15 seconds per child and 150 seconds total. Early terminal INVALID stop; no retries, no replacement samples, no pull/install/network. A preflight-invalid result ends the grant without an observed child. A persistent reservation consumes the series before launch and survives interruption.

This grant does not authorize hosted CI runs or spend, push/PR/merge/publication, a new main cohort, model/weight/threshold edits, fixture changes or phase closure. Historical receipts stay unchanged. CI-01 and CI-04 remain verified; CI-02 remains INCOMPLETE; CI-03 remains MISS; Phase 247 remains 2/4 regardless of the local result.
