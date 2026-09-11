---
phase: 199-decouple
plan: "04"
subsystem: tooling
tags: [typescript, esm, filesystem-containment, atomic-write, tdd]

requires: []
provides:
  - Import-meta-anchored TypeScript authority for immutable operator evidence and generated critic output
  - Explicit fixture/output CLI root overrides with task-oriented required-JSON diagnostics
  - Canonical traversal, prefix, symlink, and root-alias rejection plus synced sibling-temp replacement
affects: [199-08, e2e-critic, playwright-capture, operator-surface-fixtures]

actuals:
  tokens: 5988
  tasks: 2
  commits: 6
plan_head_before: 7a85f032292a38b8d2dfef1cf01375752c006287

tech-stack:
  added: []
  patterns: [import.meta.url source anchor, path.relative canonical containment, synced sibling-temp replacement]

key-files:
  created:
    - examples/threadline_phoenix/e2e/support/operator-surface-paths.ts
    - examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts
  modified:
    - examples/threadline_phoenix/e2e/package.json
    - examples/threadline_phoenix/e2e/critic/run.ts

key-decisions:
  - "The ESM adapter owns frozen deterministic roots; callers may override fixture and output roots only through explicit CLI flags."
  - "Containment rejects traversal and every symlink component, canonicalizes the nearest existing parent, and compares with path.relative rather than string prefixes."
  - "Canonical TypeScript replacement uses an exclusive sibling temp, file sync, close-before-rename, and unconditional cleanup."

patterns-established:
  - "ESM repository edge: derive one repository root from the adapter's import.meta.url and export named immutable/generated locations."
  - "Safe path mutation: lexical containment -> symlink-component rejection -> existing-parent realpath -> canonical containment."
  - "Atomic write: exclusive sibling temp -> write -> fsync -> close -> rename -> unconditional cleanup."

requirements-completed: [DECOUPLE-01]

coverage:
  - id: D1
    description: "One source-anchored ESM adapter resolves stable critic evidence roots across root, nested-CWD, and copied-worktree layouts, with explicit flag precedence and actionable required-JSON failures."
    requirement: DECOUPLE-01
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts#root, nested cwd, worktree, root override, and JSON diagnostic cases"
        status: pass
      - kind: other
        ref: "npm --prefix examples/threadline_phoenix/e2e run typecheck"
        status: pass
    human_judgment: false
  - id: D2
    description: "The adapter rejects hostile path mutations and immutable/output aliases, while atomic replacement preserves original bytes and removes sibling temps on forced failure."
    requirement: DECOUPLE-01
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts#containment, separation, and atomic replacement cases"
        status: pass
      - kind: integration
        ref: "npm --prefix examples/threadline_phoenix/e2e run test:paths (7 tests, 0 failures from root and nested critic cwd)"
        status: pass
    human_judgment: false

duration: 10 min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 04: Shared TypeScript Evidence Boundary Summary

**Import-meta-anchored critic evidence roots with canonical symlink-safe containment and crash-safe atomic replacement**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-11T04:19:12Z
- **Completed:** 2026-09-11T04:29:37Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added one frozen ESM path adapter that finds the current tracked operator evidence from `import.meta.url`, remains stable under caller-CWD changes and copied worktree layouts, and accepts explicit fixture/output flags without environment lookup.
- Wired `critic/run.ts` to the adapter for golden/synthetic/scorecard reads and repository-relative artifacts, removing its independent repository-root calculation and adding D-12 missing/malformed JSON diagnostics.
- Added shared canonical containment, immutable/generated root separation, and sibling-temp atomic replacement primitives with traversal, absolute escape, prefix confusion, symlink escape, alias, success, and forced-failure controls.

## Task Commits

Each task followed RED→GREEN TDD cycles:

1. **Task 1 RED: Source-anchored path stability** - `5c38f5ac` (test)
2. **Task 1 GREEN: Import-meta evidence roots** - `a1b26b3f` (feat)
3. **Task 1 RED: Root overrides and diagnostics** - `262067f2` (test)
4. **Task 1 GREEN: Shared critic reader boundary** - `0e9a374c` (feat)
5. **Task 2 RED: Hostile paths and atomic failure** - `78f27a6f` (test)
6. **Task 2 GREEN: Canonical containment and atomic replacement** - `43e50093` (feat)

## Files Created/Modified

- `examples/threadline_phoenix/e2e/support/operator-surface-paths.ts` - Frozen deterministic roots, flag parsing, required-JSON diagnostics, canonical containment, root separation, and atomic writer.
- `examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts` - Root/nested/worktree, override, diagnostics, hostile-path, alias, and atomic-write controls.
- `examples/threadline_phoenix/e2e/package.json` - Grounded `test:paths`, `typecheck`, and `critic:check` scripts.
- `examples/threadline_phoenix/e2e/critic/run.ts` - Real critic reader wired to shared roots and required-JSON diagnostics.

## Decisions Made

- Kept the adapter repository-edge-only and source-anchored; no runtime service locator or ambient environment contract was introduced.
- Made `--output-root` name the generated critic-score root directly while `--fixture-root` names the root containing ledger, scorecards, golden, and refute evidence. Plan 199-08 can flip the deterministic fixture default atomically.
- Rejected every symlink component below a trusted root, not only symlinks that currently resolve outside it, so alternate aliases cannot bypass path identity checks.
- Exposed a narrow `beforeRename` failure seam on the atomic writer so the original-byte and cleanup guarantees have an executable falsifier.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Canonicalized macOS temporary-worktree expectations**

- **Found during:** Task 1 and Task 2 GREEN verification
- **Issue:** macOS resolves `/var` temporary paths through `/private/var`, so lexical expected paths disagreed with the deliberately canonical adapter result.
- **Fix:** Compared successful worktree and nested-target results against `realpath`-canonical roots.
- **Files modified:** `examples/threadline_phoenix/e2e/support/operator-surface-paths.test.ts`
- **Verification:** Root and nested-CWD path suites each pass 7 tests with zero failures.
- **Committed in:** `a1b26b3f`, `43e50093`

---

**Total deviations:** 1 auto-fixed bug.
**Impact on plan:** The correction makes the portability test reflect the intended canonical-path security contract; scope and production behavior remain unchanged.

## Issues Encountered

- An extra smoke probe initially invoked plain Node against the TypeScript source and failed with `ERR_UNKNOWN_FILE_EXTENSION`; rerunning the same probe through the project's installed `tsx` runtime passed. The planned tests and typecheck were unaffected.

## TDD Gate Compliance

- **Task 1 RED cycle 1:** `RED_EVIDENCE_OK` — the named root/nested/worktree assertion failed because the adapter did not exist.
- **Task 1 GREEN cycle 1:** Path stability passed before `a1b26b3f`.
- **Task 1 RED cycle 2:** `RED_EVIDENCE_OK` — the named required-JSON diagnostic assertion failed because the reader was absent.
- **Task 1 GREEN cycle 2:** Three path/override/diagnostic tests and typechecking passed before `0e9a374c`; the tracer feedback rerun also passed 3/3.
- **Task 2 RED:** `RED_EVIDENCE_OK` — the named containment assertion failed while the four security/atomic primitives were absent.
- **Task 2 GREEN:** Seven tests and typechecking passed before `43e50093`; no separate refactor commit was needed.
- **Commit order:** `test → feat → test → feat → test → feat`.

## Verification

- `npm --prefix examples/threadline_phoenix/e2e run test:paths` — **PASS**, 7 tests, 0 failures.
- From `examples/threadline_phoenix/e2e/critic`, `npm --prefix .. run test:paths` — **PASS**, 7 tests, 0 failures.
- `npm --prefix examples/threadline_phoenix/e2e run typecheck` — **PASS**.
- Source scan for `const repoRoot`, `fileURLToPath(import.meta.url)`, and `process.cwd()` in `critic/run.ts` — **PASS**, no independent root authority remains.
- Frozen-default smoke through installed `tsx` — **PASS**, fixture and generated roots resolve to the current tracked corpus.
- `git diff --check` over all four plan files — **PASS**.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

- Ready for Plan 199-08 to move the tracked corpus and flip this adapter's deterministic fixture default without changing consumers' path/containment contract.
- No blocker remains in the TypeScript evidence boundary; subsequent critic/capture consumers can import these exact primitives instead of duplicating roots or writers.

## Self-Check: PASSED

- All four implementation/test files and this summary exist on disk.
- All six measured plan commits are present after the persisted plan-head ledger.
- Both coverage deliverables classify as fully automated with passing evidence and no schema errors.
- Three RED records validated as `RED_EVIDENCE_OK`; final root/nested path suites and TypeScript typechecking pass.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
