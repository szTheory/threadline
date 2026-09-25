---
phase: 202-release-0-10-0
plan: 06
subsystem: infra
tags: [dialyzer, mix-task, release-automation, elixir]

requires:
  - phase: 202-release-0-10-0
    provides: "Plan 202-02 introduced mix release.pins and, with it, the Threadline.MixProject.project/0 call that born-red cause BR-3 names"
provides:
  - "mix dialyzer green (Total errors: 0), unblocking the Dialyzer step of mix ci.all"
  - "release.pins reads its version through Mix.Project.config/0 — a documented, Dialyzer-resolvable API — while still reading it at call time"
affects: [202-release-0-10-0, release, ci]

actuals:
  tokens: 300
  tasks: 1
  commits: 1
  plan_head_before: 465f52f2a62001e43f880882cf551e753298ef25

tech-stack:
  added: []
  patterns:
    - "Mix task internals read project metadata via Mix.Project.config/0, never by naming the mix.exs project module (mix.exs is evaluated, never compiled into ebin, so Dialyzer cannot resolve it)"

key-files:
  created: []
  modified:
    - lib/mix/tasks/release.pins.ex

key-decisions:
  - "Fixed the Dialyzer finding at its cause rather than suppressing it — .dialyzer_ignore.exs stays []"
  - "Used Mix.Project.config()[:version] instead of a module attribute so the version stays read at call time, preserving the property the comment at lines 105-107 defends"

patterns-established:
  - "Runtime version reads inside maintainer Mix tasks go through the Mix public API"

requirements-completed: [RELEASE-01]

coverage:
  - id: D1
    description: "mix dialyzer reports Total errors: 0 — the unknown_function at release.pins.ex:103 is gone"
    requirement: "RELEASE-01"
    verification:
      - kind: other
        ref: "mix dialyzer"
        status: pass
    human_judgment: false
  - id: D2
    description: "mix release.pins --check behavior is unchanged — same derived pin, same scanned/differing counts, byte-identical output"
    requirement: "RELEASE-01"
    verification:
      - kind: other
        ref: "diff of `mix release.pins --check` output captured before and after the change (empty diff)"
        status: pass
      - kind: integration
        ref: "test/threadline/version_truth_doc_contract_test.exs + test/threadline/release_artifact_contract_test.exs (23 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: ".dialyzer_ignore.exs untouched and still [] — the finding was fixed, not suppressed"
    requirement: "RELEASE-01"
    verification:
      - kind: other
        ref: "git diff --stat HEAD~1 -- .dialyzer_ignore.exs (no output)"
        status: pass
    human_judgment: false

duration: 6 min
completed: 2026-09-22
status: complete
---

# Phase 202 Plan 06: Dialyzer unknown_function in release.pins Summary

**`release.pins` now derives its version from `Mix.Project.config()[:version]` instead of `Threadline.MixProject.project()[:version]`, taking Dialyzer from 1 error to 0 without freezing the version or touching the ignore file.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-09-22T15:59:47Z
- **Completed:** 2026-09-22T16:05:55Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Closed born-red cause BR-3: `mix dialyzer` reports `Total errors: 0, Skipped: 0, Unnecessary Skips: 0` and exits 0, so the Dialyzer step of `mix ci.all` is no longer blocking.
- Kept the load-bearing property intact — the version is still read at call time, so a `mix.exs` bump can never be shadowed by a stale compiled artifact. `Mix.Project.config/0` reads the same live project config from the same source; no module attribute was introduced.
- Proved behavioral equivalence by capturing `mix release.pins --check` before and after and diffing: byte-identical.

## Task Commits

1. **Task 1: Read the version through the Mix API instead of the project module** — `90196828` (fix)

**Plan metadata:** committed with this SUMMARY (docs).

## Files Created/Modified

- `lib/mix/tasks/release.pins.ex` — `current_version/0` now calls `Mix.Project.config()[:version]`. One line changed; the comment block at 105-107 was left verbatim because it still describes the code accurately (the read is still at runtime, still not a module attribute).

## Verification Evidence

### `mix release.pins --check` — BEFORE (at 465f52f2, pre-change)

```
release.pins: mix.exs @version is 0.9.0, derived install pin is `~> 0.9.0`
release.pins: scanned 20 file(s); 0 pin site(s) differ from the derived pin
release.pins: no changes — every install pin already reads the
release.pins: derived `~> 0.9.0`.
```
Exit status: 0

### `mix release.pins --check` — AFTER (at 90196828)

```
release.pins: mix.exs @version is 0.9.0, derived install pin is `~> 0.9.0`
release.pins: scanned 20 file(s); 0 pin site(s) differ from the derived pin
release.pins: no changes — every install pin already reads the
release.pins: derived `~> 0.9.0`.
```
Exit status: 0

`diff before.txt after.txt` produced no output — byte-identical, same derived pin (`~> 0.9.0`), same 20 files scanned, same 0 differing sites.

### `mix dialyzer`

```
ignore_warnings: .dialyzer_ignore.exs
...
  warnings: [:unmatched_returns, :extra_return, :unknown]
]
Total errors: 0, Skipped: 0, Unnecessary Skips: 0
done in 0m2.55s
done (passed successfully)
```
Exit status: 0. `check_plt: false`, PLT reported up to date — this was a real finding, not a cache miss, and it is now genuinely resolved.

### Other gates

- `mix format --check-formatted lib/mix/tasks/release.pins.ex` — clean.
- `mix compile --warnings-as-errors` — exit 0.
- `mix test test/threadline/version_truth_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs` — 23 tests, 0 failures.
- `git diff --stat HEAD~1 -- .dialyzer_ignore.exs` — no output. File is still `[]`.
- `git diff --stat HEAD~1 HEAD` — `lib/mix/tasks/release.pins.ex | 2 +-`, 1 file changed, 1 insertion(+), 1 deletion(-).

## Acceptance Criteria

| Criterion | Result |
|---|---|
| `mix dialyzer` reports `Total errors: 0` | PASS |
| `.dialyzer_ignore.exs` is still `[]` | PASS |
| `mix release.pins --check` output byte-identical to pre-change run | PASS (diff empty; both quoted above) |
| Diff touches exactly one function body in one file | PASS (1 line, 0 comment changes) |
| No module attribute holding a version introduced | PASS |

## Decisions Made

- **Kept the comment at 105-107 verbatim.** The plan permitted updating it only if it became inaccurate. It says the version is "read at runtime rather than frozen into a module attribute" — still exactly true of `Mix.Project.config/0`, which resolves the live project config at call time. Editing it would have added diff noise without adding truth.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- BR-3 is closed. The Dialyzer step of `mix ci.all` is green locally.
- The other born-red causes tracked by Phase 202's gap-closure plans are unaffected by this change and remain as scoped.
- Three tree items were deliberately left uncommitted and untouched, as instructed: modified `.planning/config.json`, modified `.planning/WINDOWS.md`, and untracked `.tool-versions`.

---
*Phase: 202-release-0-10-0*
*Completed: 2026-09-22*

## Self-Check: PASSED

- `lib/mix/tasks/release.pins.ex` exists on disk.
- Commit `90196828` (task) resolves in `git log`; the plan-metadata commit is the commit carrying this SUMMARY.
- `.dialyzer_ignore.exs` unchanged and still `[]`.
- The three protected tree items (`.planning/config.json`, `.planning/WINDOWS.md`, `.tool-versions`) were left uncommitted and untouched.
