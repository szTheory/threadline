---
phase: 204-structure
plan: 01
subsystem: testing
tags: [exunit, contract-test, css, byte-lock, source-size, ast, credo-adjacent]

requires:
  - phase: 203-real-gates
    provides: contract-gate skeleton (credo_config_contract_test register/ceiling/self-test pattern, sha pin precedent)
provides:
  - CSS byte lock (golden file + @golden_sha256 + @rendered_sha256) for Threadline.OperatorSurface.Style.css/1
  - lib size/function-length/banner/heex gate with exact exception maps seeded at measured values
  - Threadline.Test.SourceFamily.files!/1 and read!/1 for repointing source-text pins after extraction
affects: [204-02, 204-03, 204-04, 204-05, 204-06, 204-07, 204-08, 204-09, 204-10, 204-11, 204-12, 204-13, 204-14, 204-15]

actuals:
  tokens: 38865
  tasks: 3
  commits: 3
plan_head_before: 0c37cedc72088cafc38612b0aa34fbceeb4f0074

tech-stack:
  added: []
  patterns:
    - "Golden file + dual sha256 pin, prefix-strip comparison (never toggles app env), bounded diff report"
    - "Exact-pin exception maps that fail both when grown and when stale"
    - "Per-clause AST function length (max per name/arity, never summed)"

key-files:
  created:
    - test/threadline/operator_surface/style_byte_lock_test.exs
    - test/fixtures/style/operator_surface.css
    - test/fixtures/style/README.md
    - test/threadline/source_size_contract_test.exs
    - test/support/source_family.ex
    - test/threadline/source_family_test.exs
  modified: []

key-decisions:
  - "The regeneration one-liner lives only in test/fixtures/style/README.md; the lock test quotes it from there at failure time (and a test asserts it is present), so the test file holds no write call"
  - "Exception reasons are validated: non-empty and free of planning vocabulary (Phase N / STRUCT-N / D-NN)"
  - "migration_content/0 is seeded with the generic splitting reason as the plan specified; whether it becomes a named exception or is split is left to the plan that owns it"

patterns-established:
  - "Later plans edit @file_exceptions / @function_exceptions / @banner_exceptions in the same commit as each extraction that changes a measured value"
  - "SourceFamily.read!/1 is for presence/absence pins; order-bearing resources (the stylesheet cascade) need their own ordered reader"

requirements-completed: [STRUCT-01, STRUCT-03, STRUCT-04]

coverage:
  - id: D1
    description: "Rendered operator CSS pinned byte for byte by a golden file plus golden and full-render sha256 pins, in verify.test"
    requirement: STRUCT-01
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/style_byte_lock_test.exs (9 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "lib file-length, function-length, separator-banner, and heex/embed_templates gate seeded green at measured values"
    requirement: STRUCT-03
    verification:
      - kind: unit
        ref: "test/threadline/source_size_contract_test.exs (14 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Banner register enforcing STRUCT-04 (exact per-file counts, drains to %{})"
    requirement: STRUCT-04
    verification:
      - kind: unit
        ref: "test/threadline/source_size_contract_test.exs#separator banners"
        status: pass
    human_judgment: false
  - id: D4
    description: "Threadline.Test.SourceFamily reader for split-module pins"
    verification:
      - kind: unit
        ref: "test/threadline/source_family_test.exs (5 tests)"
        status: pass
    human_judgment: false

duration: 8min
completed: 2026-09-23
status: complete
---

# Phase 204 Plan 01: Byte lock and size gate Summary

**The rendered operator CSS is now pinned to a committed 119,508-byte golden file plus two sha256 pins, and a new AST-based gate pins every oversized lib file, function, and separator banner at its exact measured value. Both land before any refactor in the phase.**

## Performance

- **Duration:** about 8 min
- **Started:** 2026-09-23T16:53:42Z
- **Completed:** 2026-09-23T17:01:07Z
- **Tasks:** 3/3
- **Files created:** 6 (no `lib/` or `mix.exs` change)
- **Plan base:** `0c37cedc72088cafc38612b0aa34fbceeb4f0074` (stored in `$(git rev-parse --git-dir)/gsd-204-01-base`)

## Measured values (committed)

| Pin | Bytes | sha256 |
|---|---:|---|
| Full render, fonts included (`@rendered_sha256`) | 212,633 | `b10d6a2c9a7d8abc99642f332cea9611ea7dab8f8a4ea8b212fac582ecaea5b1` |
| Style-owned suffix = golden file (`@golden_sha256`) | 119,508 | `c7baf51ecd9b4465675ea12a67218974157616ea8e8937e71aa166ca8154ab4b` |

Both values match research exactly. The golden file starts with `<style>\n  .threadline-ui {` and ends with `}\n</style>`, with no trailing newline.

## Seeded exception maps (measured by the gate on the untouched tree)

**`@file_exceptions`** (limit 800 lines):

| File | Lines | Reason |
|---|---:|---|
| lib/threadline/operator_surface/style.ex | 4509 | oversized; being split into cohesive modules |
| lib/threadline/operator_surface/ui.ex | 1686 | same |
| lib/threadline/operator_surface/live/timeline_live.ex | 1399 | same |
| lib/threadline/operator_surface/live/stress_live.ex | 1398 | same |
| lib/threadline/operator_surface/stress_fixtures.ex | 980 | declarative fixture data tables; excluded from the Hex package (mix.exs exclude_patterns) |
| lib/threadline/operator_surface/mechanical_checker.ex | 948 | oversized; being split into cohesive modules |
| lib/threadline/query.ex | 895 | same |

**`@function_exceptions`** (limit 120 lines per clause; every reason is "oversized; being split into cohesive modules"):

| Function | Max clause |
|---|---:|
| style.ex `css/1` | 4492 |
| live/stress_live.ex `render/1` | 540 |
| live/export_status_live.ex `render/1` | 254 |
| live/timeline_live.ex `timeline_filter_drawer/1` | 202 |
| live/start_live.ex `render/1` | 190 |
| live/retention_history_live.ex `render/1` | 186 |
| live/transaction_live.ex `render/1` | 183 |
| live/timeline_live.ex `render/1` | 165 |
| live/actor_live.ex `render/1` | 149 |
| governance/migration.ex `migration_content/0` | 138 |
| live/coverage_live.ex `render/1` | 135 |
| live/timeline_live.ex `timeline_command/1` | 130 |

**`@banner_exceptions`** (42 banner lines in 7 files): mechanical_checker.ex 10, live/timeline_live.ex 10, controllers/export_controller.ex 9, live/start_live.ex 6, semantics/actor_ref.ex 3, live/coverage_live.ex 3, query.ex 1.

## Accomplishments

- `Threadline.OperatorSurface.StyleByteLockTest` (9 tests, `async: true`, guarded on `Phoenix.LiveView`). It asserts fonts are embedded, the golden file is present and non-empty, the golden hash, prefix plus golden equals the full render byte for byte (so the fonts/style join is checked), the full-render hash, and that two renders are identical. It also has a diff-reporter self-test (bounded under 2,000 bytes for 200 KB inputs), a README one-liner presence check, and the planning-directory self-refute. A probe that perturbed one golden byte produced the expected bounded message: line 5, byte offset 123, and the new sha. The golden was then restored and re-hashed to `c7baf51e…`.
- `Threadline.SourceSizeContractTest` (14 tests). Its pure validators return `:ok | {:error, msg}` and cover four rules: file length, per-clause function length, the banner register (comment text only, via `Code.string_to_quoted_with_comments/2`), and the `.heex`/`embed_templates` ban. Exact pins fail in both directions ("grew: split it" and "stale: lower or delete"). Other failures: a pin naming a key the scan never measured, a pin at or under the limit, a non-positive count, a reason carrying planning vocabulary, and an empty scan set ("pass vacuously"). Planted-violation self-tests cover every direction, including an 801-line file, a 121-line def, three clauses totalling 150 lines with a max of 60 (passes), a guarded head measured as `f/1`, a banner in a string literal that is ignored, a `.heex` path, and an `embed_templates` call.
- `Threadline.Test.SourceFamily` (`files!/1`, `read!/1`). It returns the parent followed by every sibling-directory `.ex` and `.css` file in sorted order. It tolerates a deleted parent and raises `ArgumentError` naming the path. A code comment documents that the order is alphabetical, not semantic.
- Full suite: **1747 tests, 0 failures, 1 excluded** (pgbouncer_topology). `mix verify.format` exit 0, `mix credo --strict` found no issues, and `MIX_ENV=test mix verify.compile_no_optional` exit 0 with no warnings.

## Task Commits

1. **Task 1: CSS byte lock (tracer)**: `ef458852` (test)
2. **Task 2: size, function, banner, and heex gate**: `a10cece3` (test)
3. **Task 3: source-family reader**: `3118fc79` (test)

## Files Created/Modified

- `test/threadline/operator_surface/style_byte_lock_test.exs`: the byte lock
- `test/fixtures/style/operator_surface.css`: the golden style-owned render suffix
- `test/fixtures/style/README.md`: provenance plus the bump procedure, which owns the regeneration one-liner
- `test/threadline/source_size_contract_test.exs`: the size/banner/heex gate
- `test/support/source_family.ex`: the source-family reader
- `test/threadline/source_family_test.exs`: reader unit tests over temp-dir fixtures

## Decisions Made

- The regeneration one-liner lives only in the README. The lock test reads it from there when it builds a failure message, and a dedicated test asserts the line is present. This keeps the test free of any file-write text, so the `grep -c File.write` acceptance criterion is 0, and it avoids two copies of the command drifting apart.
- Exception reasons are validated inside the gate: each must be non-empty and free of `Phase N`, `STRUCT-N`, and `D-NN`. This enforces the plan's "adopter-neutral reason" prohibition in code.
- `migration_content/0` got the generic splitting reason, as the plan's step (5) says. Research's alternative, a named exception for a single heredoc template, is left to the plan that owns that function.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Acceptance grep `File.write` was 1 because the embedded regeneration command contained it**
- **Found during:** Task 1
- **Issue:** The first draft embedded the README one-liner, which includes `File.write!`, as a module attribute. The plan requires `grep -c 'File.write'` to print 0.
- **Fix:** Removed the attribute. The failure message now quotes the one-liner from the README at runtime, and a new test asserts the README keeps it. Also aliased `Phoenix.HTML.Safe` to satisfy credo's AliasUsage.
- **Files modified:** test/threadline/operator_surface/style_byte_lock_test.exs
- **Verification:** 9 tests pass, the grep prints 0, credo is clean
- **Committed in:** ef458852

**2. [Rule 3 - Blocking] The TDD RED-evidence checker cannot parse ExUnit output**
- **Found during:** Task 3 (`tdd="true"`)
- **Issue:** `gsd-tools check tdd-red-evidence` parses node:test/TAP summaries only, so it returned `INVALID_RED (invalid_record)` for any ExUnit record.
- **Fix:** Ran RED manually against a stub module whose `files!/1` returned `[]` and `read!/1` returned `""`. Result: `5 tests, 4 failures`, and all four behavior tests failed on their own assertions (no compile or load error). Then implemented GREEN (`5 tests, 0 failures`). The plan and D-00 mandate one `test(204-01)` commit per task, so RED and GREEN were committed together in `3118fc79` rather than as separate test/feat commits.
- **Files modified:** none beyond the task's files
- **Committed in:** 3118fc79

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking tooling mismatch)
**Impact on plan:** None on scope. Both changes kept the plan's acceptance criteria and commit-type rule intact.

## Issues Encountered

None.

## Known Stubs

None.

## User Setup Required

None.

## Next Phase Readiness

- Ready for 204-02 and later plans. Every refactor commit must keep `style_byte_lock_test.exs` green without re-pinning. It must also edit the size gate's exception maps in the same commit whenever a measured value changes; the gate fails on stale pins.
- The style.ex pivot (D-04) must move the `style.ex` file and `css/1` exceptions to the new `.css` file in the same commit.

## Self-Check: PASSED

- All 6 created files exist on disk.
- Commits `ef458852`, `a10cece3`, and `3118fc79` exist, and `git rev-list --count 0c37cedc..HEAD` = 3 before this SUMMARY commit.
- `git diff --stat 0c37cedc HEAD -- lib/ mix.exs` is empty.

---
*Phase: 204-structure*
*Completed: 2026-09-23*
