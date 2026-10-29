---
phase: 244-release-flow
plan: 10
subsystem: release-flow
tags: [gate, ci-all, gap-closure, review-disposition]
status: complete
requires: [244-08, 244-09]
provides:
  - "green CI=true mix ci.all evidence on the combined 244-08 + 244-09 tree (postgres:16)"
  - "final dispositions for all 10 244-REVIEW findings (4 fixed, 6 deferred, 0 open)"
affects: [244-VERIFICATION re-verification]
tech-stack:
  added: []
  patterns: ["ephemeral postgres:16 gate container (244-07 recipe), torn down by trap"]
key-files:
  created: [.planning/phases/244-release-flow/244-10-SUMMARY.md]
  modified:
    - .planning/phases/244-release-flow/244-REVIEW-DISPOSITION.md
    - .planning/phases/244-release-flow/deferred-items.md
decisions:
  - "244-REVIEW WR-02, WR-05, IN-01..IN-04 deferred with recorded rationale; CR-01, WR-01, WR-03, WR-04 fixed by 244-09"
metrics:
  duration: "about 25 min (gate itself 10m11s)"
  completed: 2026-10-25
actuals:
  tokens: 4500
  tasks: 2
  commits: 1
plan_head_before: 135d244adac46679338b5afc100e51bf555863e4
plan_head_after: 804f948214865093f800b4c12cd8b46f7277b285
---

# Phase 244 Plan 10: Combined gap-closure gate and review bookkeeping Summary

`CI=true mix ci.all` exits 0 on a throwaway postgres:16 container over the combined 244-08 (REL-04 lock hygiene) and 244-09 (CR-01 lazy retry wrapper) tree. All ten 244-REVIEW findings now carry a final disposition: 4 fixed, 6 deferred, 0 open.

## Task 1 (tracer): full gate on an ephemeral postgres:16

The gate script lives at `<scratch>/244-10/gate.sh` and follows the 244-07 recipe:
`docker run -d --rm --pull never -p 127.0.0.1::5432`, labels `dev.threadline.kind=gate-db` and `owner-pid`, readiness via `pg_isready -h 127.0.0.1` with a 60s deadline, and trap teardown on EXIT/INT/TERM. It exports `DB_HOST=127.0.0.1`, `DB_PORT=<docker-assigned>` (65034) and `CI=true`, then runs `mix ci.all | tee` and exits with the `mix ci.all` status. Start 16:16:51Z, end 16:27:02Z.

Server proof (captured from the live container; see Deviations):
`PostgreSQL 16.14 (Debian 16.14-1.pgdg13+1) on aarch64-unknown-linux-gnu ... 64-bit|5432|Etc/UTC|en_US.utf8`

Decisive lines from `<scratch>/244-10/gate-244-gaps.log.clean`:

- credo: `5781 mods/funs, found no issues.`
- format: `verify.format` (`format --check-formatted`) is the first ci.all step and prints nothing when it passes. Covered by the overall exit 0.
- deps audit + lock hygiene: `verify-deps-audit: 3 lockfile(s) audit clean (Hex 2.6.0)`. `bin/verify-deps-audit` runs `bin/verify-lock-hygiene` for each resolved `mix.lock`, and the log has no `lock hygiene exited` or `contains whitespace or a quote` line.
- repo hygiene: `verify-repo-hygiene: 4912 tracked text file(s) clean; 8 allowlist entries used, 0 inert`
- ExUnit library: `32 properties, 3278 tests, 0 failures, 3 excluded`
- ExUnit example app: `132 tests, 0 failures`
- Dialyzer: `Total errors: 0, Skipped: 0, Unnecessary Skips: 0` / `done (passed successfully)`; dialyzer slice `17 tests, 0 failures, 16 excluded`
- Playwright: `1 flaky` / `64 skipped` / `417 passed (5.8m)`, 0 failed
- final: `ci.all exit=0` (script `GATE_STATUS=0`)

The plan's automated verify passed (exit 0). Teardown: `docker ps -aq --filter label=dev.threadline.kind=gate-db` is empty. The PLT was warm, so no Dialyzer rebuild was needed. The partition-timing check did not complain. No tracked file changed during the run.

The tracer feedback gate re-ran `<verify>` and it passed. Task 1 touches no tracked file, so it has no commit of its own.

## Task 2: repo hygiene and final dispositions (`804f9482`)

- `bin/verify-repo-hygiene` reported the same clean line before and after the edits. The deferred `244-RESEARCH.md:129` item is marked `Resolved: fixed at e89efba5`, and its original text is kept.
- 244-REVIEW-DISPOSITION.md: CR-01 fixed (`23ef7071` + `f91ec4c2`); WR-01, WR-03, WR-04 fixed (`3c08524b`); WR-02, WR-05, IN-01, IN-02, IN-03, IN-04 deferred with the plan's rationales. `open: 0`, `total: 10`, `updated:` added. Counts: open 0, fixed 4, deferred 6. 244-REVIEW.md was not edited.

## Deviations from Plan

**1. [Rule 1 - Bug] Server-proof query used a setting PG16 removed**
- **Found during:** Task 1
- **Issue:** my gate script also selected `current_setting('lc_collate')`, which PG16 no longer has, so the in-log proof line printed `ERROR: unrecognized configuration parameter "lc_collate"` to stderr. The proof query sits outside the `mix ci.all` status and did not affect the gate.
- **Fix:** captured the proof from the running container with `pg_database.datcollate` in place of the removed setting (`<scratch>/244-10/server-proof.txt`). The scratch script is not committed.

**2. Playwright flake (observation, not a fix):** `[mobile-chromium] operator-timeline-investigation-flow.spec.ts:814 › Timeline reduced-motion browser proof › keeps Timeline rows static with reduced motion` failed once and passed on retry. The plan defines red as a `failed` count above 0, and here failed is 0. The test is outside 244's scope. It is recorded here for flake tracking.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: .planning/phases/244-release-flow/244-REVIEW-DISPOSITION.md (open 0, fixed 4, deferred 6)
- FOUND: .planning/phases/244-release-flow/deferred-items.md (Resolved line)
- FOUND: commit 804f9482
- Gate container: none remaining
